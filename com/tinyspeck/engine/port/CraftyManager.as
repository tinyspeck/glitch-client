package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.craftybot.CraftyJob;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingCraftybotAddVO;
	import com.tinyspeck.engine.net.NetOutgoingCraftybotCostVO;
	import com.tinyspeck.engine.net.NetOutgoingCraftybotLockVO;
	import com.tinyspeck.engine.net.NetOutgoingCraftybotPauseVO;
	import com.tinyspeck.engine.net.NetOutgoingCraftybotRefuelVO;
	import com.tinyspeck.engine.net.NetOutgoingCraftybotRemoveVO;
	import com.tinyspeck.engine.net.NetOutgoingCraftybotUpdateVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;

	public class CraftyManager
	{
		/* singleton boilerplate */
		public static const instance:CraftyManager = new CraftyManager();
		
		public var jobs:Vector.<CraftyJob> = new Vector.<CraftyJob>();
		public var job_cost_req:CraftyJob; //used when price checking
		
		public var jobs_max:uint;
		public var crystal_count:uint;
		public var crystal_max:uint;
		public var fuel_count:uint;
		public var fuel_max:uint;
		public var can_refuel:Boolean;
		
		private var cdVO:ConfirmationDialogVO;
		
		private var lock_class:String;
		private var pause_class:String;
		private var remove_class:String;
		private var remove_count:uint;
		private var job_count:uint;
		
		private var current_lock:Boolean;
		private var current_pause:Boolean;
		
		public function CraftyManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function update(payload:Object):void {
			//there was a change in the craftybot's queue, let's update it
			if('jobs' in payload){
				job_count = 0;
				jobs.length = 0;
				
				while(payload.jobs[job_count] && 'item_class' in payload.jobs[job_count]){
					jobs.push(CraftyJob.fromAnonymous(payload.jobs[job_count], payload.jobs[job_count].item_class));
					job_count++;
				}
			}
			
			//injection sensation
			//jobs[0].status.is_active = true;
			
			//set some more stuff
			if('jobs_max' in payload) jobs_max = payload.jobs_max;
			if('crystal_count' in payload) crystal_count = payload.crystal_count;
			if('crystal_max' in payload) crystal_max = payload.crystal_max;
			if('fuel_count' in payload) fuel_count = payload.fuel_count;
			if('fuel_max' in payload) fuel_max = payload.fuel_max;
			if('can_refuel' in payload) can_refuel = payload.can_refuel === true;
			
			if(CraftyDialog.instance.parent){
				CraftyDialog.instance.update();
			}
		}
		
		public function refreshJobs():void {
			//go ask the server for the latest and greatest
			TSFrontController.instance.genericSend(new NetOutgoingCraftybotUpdateVO());
		}
		
		public function addJob(item_class:String, count:uint):void {
			//add a new job to the bot's queue
			TSFrontController.instance.genericSend(new NetOutgoingCraftybotAddVO(item_class, count), onAdd, onAdd);
		}
		
		private function onAdd(nrm:NetResponseMessageVO):void {
			//update the dialog
			CraftyDialog.instance.addStatus(nrm.success);
			
			if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('onAdd error!');
				}
			}
		}
		
		public function removeJob(item_class:String, count:uint):void {
			//remove some/all of a job
			const job:CraftyJob = getJobByItem(item_class);
			if(!job) return;
			
			remove_class = item_class;
			remove_count = count;
			
			if(!cdVO){
				cdVO = new ConfirmationDialogVO();
				cdVO.title = 'Are you sure?';
				cdVO.choices = [
					{value:true, label:'Yes, go ahead!'},
					{value:false, label:'Nevermind'}
				];
				cdVO.callback = onRemoveConfirm;
				cdVO.escape_value = false;
			}
			
			//if this job is active and they are taking more than what is done we need to warn them
			if(job.status.is_active && count > job.done){
				cdVO.txt = 'Your Craftybot is still working on this job and if you remove it now it will drop what ' +
							'it\'s doing and lose any ingredients that may be in processing. This ok with you?';
				
				TSFrontController.instance.confirm(cdVO);
			}
			else if(job.total == count && !job.status.is_complete){
				cdVO.txt = 'You sure you want to remove this job?';
				
				TSFrontController.instance.confirm(cdVO);
			}
			else {
				onRemoveConfirm(true);
			}
		}
		
		private function onRemoveConfirm(value:Boolean):void {
			if(value){
				TSFrontController.instance.genericSend(new NetOutgoingCraftybotRemoveVO(remove_class, remove_count), onRemove, onRemove);
			}
			else {
				//refresh the dialog
				CraftyDialog.instance.update();
			}
		}
		
		private function onRemove(nrm:NetResponseMessageVO):void {
			//if the job was cleaned out, we can be optimistic about removing it before the update
			if(nrm.success){
				const job:CraftyJob = getJobByItem(remove_class);
				if(job && remove_count == job.total){
					jobs.splice(jobs.indexOf(job), 1);
				}
			}
			
			//update the dialog
			CraftyDialog.instance.removeStatus(nrm.success);
			
			if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('onRemove error!');
				}
			}
		}
		
		public function costCheck(item_class:String, count:uint):void {
			//go ask the server how much this is going to take to make
			TSFrontController.instance.genericSend(new NetOutgoingCraftybotCostVO(item_class, count), onCost, onCost);
		}
		
		private function onCost(nrm:NetResponseMessageVO):void {
			//parse the job
			job_cost_req = 'item_class' in nrm.payload ? CraftyJob.fromAnonymous(nrm.payload, nrm.payload.item_class) : null;
			
			//update the dialog
			CraftyDialog.instance.costStatus(nrm.success);
			
			if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('onCost error!');
				}
			}
		}
		
		public function lockJob(is_lock:Boolean, item_class:String):void {
			//tell the server we are locking this job so we can change the quantity
			current_lock = is_lock;
			lock_class = item_class;
			TSFrontController.instance.genericSend(new NetOutgoingCraftybotLockVO(is_lock, item_class), onLock, onLock);
		}
		
		private function onLock(nrm:NetResponseMessageVO):void {
			//inject the job with the update if it was good
			if(nrm.success){
				const job:CraftyJob = getJobByItem(lock_class);
				if(job){
					job.status.is_locked = current_lock;
				}
			}
			
			//update the dialog
			CraftyDialog.instance.lockStatus(nrm.success, current_lock);
			
			if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('onLock error!');
				}
			}
		}
		
		public function pauseJob(is_pause:Boolean, item_class:String):void {
			//we want to pause/resume this job
			current_pause = is_pause;
			pause_class = item_class;
			TSFrontController.instance.genericSend(new NetOutgoingCraftybotPauseVO(is_pause, item_class), onPause, onPause);
		}
		
		private function onPause(nrm:NetResponseMessageVO):void {
			//inject the job with the update if it was good
			if(nrm.success){
				const job:CraftyJob = getJobByItem(pause_class);
				if(job){
					job.status.is_paused = current_pause;
				}
			}
			
			//update the dialog
			CraftyDialog.instance.pauseStatus(nrm.success, current_pause);
			
			if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('onPause error!');
				}
			}
		}
		
		public function refuel():void {
			//off to the server
			TSFrontController.instance.genericSend(new NetOutgoingCraftybotRefuelVO(), onRefuel, onRefuel);
		}
		
		private function onRefuel(nrm:NetResponseMessageVO):void {
			//update the dialog
			CraftyDialog.instance.refuelStatus(nrm.success);
			
			if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('onRefuel error!');
				}
			}
		}
		
		public function getJobByItem(item_class:String):CraftyJob {
			if(!item_class || !jobs) return null;
			const total:int = jobs.length;
			var i:int;
			var job:CraftyJob;
			
			for(i; i < total; i++){
				job = jobs[int(i)];
				if(job.item_class == item_class) return job;
			}
			
			return null;
		}
		
		private function showError(txt:String):void {
			TSModelLocator.instance.activityModel.activity_message = Activity.createFromCurrentPlayer(txt);
		}
		
		public function get jobs_count():uint {
			const total:uint = jobs ? jobs.length : 0;
			var count:uint;
			var i:int;
			
			for(i; i < total; i++){
				count += jobs[int(i)].total;
			}
			
			return count;
		}
	}
}