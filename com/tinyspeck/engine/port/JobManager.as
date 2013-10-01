package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.job.JobBucket;
	import com.tinyspeck.engine.data.job.JobGroup;
	import com.tinyspeck.engine.data.job.JobInfo;
	import com.tinyspeck.engine.data.leaderboard.Leaderboard;
	import com.tinyspeck.engine.data.requirement.Requirement;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.MessageTypes;
	import com.tinyspeck.engine.net.NetOutgoingJobApplyWorkVO;
	import com.tinyspeck.engine.net.NetOutgoingJobClaimVO;
	import com.tinyspeck.engine.net.NetOutgoingJobContributeCurrantsVO;
	import com.tinyspeck.engine.net.NetOutgoingJobContributeItemVO;
	import com.tinyspeck.engine.net.NetOutgoingJobContributeWorkVO;
	import com.tinyspeck.engine.net.NetOutgoingJobCreateNameVO;
	import com.tinyspeck.engine.net.NetOutgoingJobLeaderboardVO;
	import com.tinyspeck.engine.net.NetOutgoingJobStatusVO;
	import com.tinyspeck.engine.net.NetOutgoingJobStopWorkVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	
	import flash.events.MouseEvent;
	import flash.utils.getTimer;
	
	public class JobManager
	{
		/* singleton boilerplate */
		public static const instance:JobManager = new JobManager();
		
		private var _job_info:JobInfo;
		private var status_job_info:JobInfo;
		private var indicator:JobActionIndicatorView;
		private var indicators:Vector.<JobActionIndicatorView> = new Vector.<JobActionIndicatorView>();
		private var lis_view:LocationItemstackView;
		
		private var last_job_status_time:int = 0;
		private var job_info_time:uint;
		
		public function JobManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function status(payload:Object):void {			
			if(payload.error){
				showError(payload.error.msg);
				CONFIG::debugging {
					Console.warn('job status error!');
				}
				return;
			}
			
			//multi-job-per-street support
			status_job_info = JobInfo.fromAnonymous(payload.info, payload.job_id);
			
			indicator = getIndicator(payload.spirit_id);
							
			//if we found an indicator but it doesn't have a parent or is disposed, make sure that it's removed and nulled
			if(indicator && (!indicator.parent || indicator.disposed)){
				indicators.splice(indicators.indexOf(indicator), 1);
				indicator = null;
			}
			
			//create it
			if(!indicator && payload.spirit_id){
				lis_view = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(payload.spirit_id);
				
				if(!lis_view) {
					// this is bad, and we should just ignore the message.
					
					CONFIG::debugging {
						Console.error('no stack for this job?');
					}
					
					indicator = null;
					status_job_info = null;
					
					return;
				}
				
				indicator = new JobActionIndicatorView(payload.spirit_id);
				indicator.addEventListener(MouseEvent.CLICK, jaivClickHandler, false, 0, true);
				StageBeacon.stage.focus = StageBeacon.stage;
				
				//add it to our lovely collection
				indicators.push(indicator);
				
				lis_view.addActionIndicator(indicator);
			}
			
			//if there is an indicator, go ahead and update it
			if(indicator){
				//make sure it has the right job id
				indicator.job_id = payload.job_id;
				
				//are we between phases?
				if(!status_job_info.is_available && status_job_info.phases.length > 0){
					indicator.current_available_time = status_job_info.time_until_available; //starts a timer within the indicator
					indicator.percent = 0;
					indicator.alt_msg = '';
				}
				//any work done? if so let's see if we've done any of it.
				else if(status_job_info.perc > 0){
					indicator.stopTimer();
					
					indicator.msg = '<span class="quest_bubble_phase_time">'+(status_job_info.perc*100).toFixed(1)+'%</span>'+
						'<br><span class="quest_bubble_complete">'+
						(status_job_info.phases.length > 1 ? 'of phase '+(status_job_info.getCurrentPhaseIndex()+1)+' ' : '')+
						'complete</span>';
					indicator.alt_msg = status_job_info.has_contributed ? 
						'Project available' : 
						'Project available'; //just in case we need to have different msgs
					indicator.percent = status_job_info.perc;
				}
				else {
					indicator.stopTimer();
					
					indicator.msg = 'Project available';
					indicator.percent = 0;
					indicator.alt_msg = '';
				}
				
				//remove the bubble if the job is complete
				if(status_job_info.complete && status_job_info.phases[status_job_info.phases.length-1].is_complete){
					lis_view = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(payload.spirit_id);
					if (lis_view) {
						lis_view.removeActionIndicator(indicator); // this removes it
					} 
					else {
						; // satisfy compiler
						CONFIG::debugging {
							Console.error('no stack for this job?');
						}
					}
				}
			}
			else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('No JAIV when running a status: '+payload.spirit_id);
				}
			}
			
			//handle the dialog opening
			if(!payload.is_update) {
				_job_info = status_job_info;
									
				//if the dialog was already open and the spirit ids don't match up, end it first
				if(JobDialog.instance.visible && JobDialog.instance.spirit_id == payload.spirit_id){
					JobDialog.instance.update(_job_info);
					return;
				}
				
				//if it's already open, end it first
				if(JobDialog.instance.visible){
					JobDialog.instance.end(true);
				}
				
				//setup the dialog
				JobDialog.instance.spirit_id = payload.spirit_id;
				JobDialog.instance.job_id = payload.job_id;
				JobDialog.instance.start();
				
			}
			else if(JobDialog.instance.visible && payload.spirit_id == spirit_id){
				_job_info = status_job_info;
				JobDialog.instance.update(_job_info);
			}
		}
		
		private function jaivClickHandler(event:MouseEvent = null):void {
			var cur_indicator:JobActionIndicatorView;
			if(event) cur_indicator = event.currentTarget as JobActionIndicatorView;
			if(cur_indicator && cur_indicator.current_available_time == 0){
				requestJobInfo(cur_indicator.name, cur_indicator.job_id);
			}
		}
				
		public function maybeRequestJobInfo(proceed:Boolean = false, force:Boolean = false):void {
			if(spirit_id){					
				if (job_info_time) {
					StageBeacon.clearTimeout(job_info_time);
					job_info_time = 0;
				}
				
				if(force){
					requestJobInfo();
					return;
				}
				
				if (!proceed) { // let's do this in 1 second
					job_info_time = StageBeacon.setTimeout(maybeRequestJobInfo, 1000, true);
					return;
				}
				
				if (last_job_status_time != 0 && getTimer() - last_job_status_time < 3000) {
					CONFIG::debugging {
						Console.warn('not getting sending a talk_to because we got one this many ms ago:'+ (getTimer() - last_job_status_time))
					}
					return;
				}
				
				requestJobInfo();
			}
			else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('No stack ID!');
				}
			}
		}
		
		private function requestJobInfo(tsid:String = null, id:String = null):void {
			if(tsid && id){
				TSFrontController.instance.genericSend(
					new NetOutgoingJobStatusVO(tsid, id)
					// no handlers because netcontroller does the magic for incoming job_status messages, wheter evts or rsps
				);
			}
			else if(spirit_id){
				TSFrontController.instance.genericSend(
					new NetOutgoingJobStatusVO(
						spirit_id,
						job_id
					)
					// no handlers because netcontroller does the magic for incoming job_status messages, wheter evts or rsps
				);
			}
			else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('No stack ID!');
				}
			}
		}
		
		private function contributeItem(nrm:NetResponseMessageVO):void {
			if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('job item error!');
				}
			}
		}
		
		CONFIG::god private function applyWork(nrm:NetResponseMessageVO):void {			
			if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('job work apply error!');
				}
				return;
			}
			
			//tell the dialog what to work with
			//JobDialog.instance.setWork(nrm.payload.work);
		}
		
		private function contributeWork(nrm:NetResponseMessageVO):void {			
			if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('job work error!');
				}
				return;
			}
			
			//tell the dialog what to work with
			JobDialog.instance.setWork(nrm.payload.work);
		}
		
		private function contributeCurrants(nrm:NetResponseMessageVO):void {
			if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('job currants error!');
				}
			}
		}
		
		public function requirementState(payload:Object):void {
			if(payload.error){
				showError(payload.error.msg);
				CONFIG::debugging {
					Console.warn('requirement state error!');
				}
				return;
			}
			
			//player has changed something in the requirements, update the UI!
			if(payload.status){
				JobDialog.instance.updateRequirement(payload.class_id, payload.contribute_count, payload.is_work);
			}
			else {
				; // satisfy compiler
				CONFIG::debugging {
					//ruh roh
					Console.warn('requirement update is missing the status or class_id');
				}
			}
		}
		
		private function stopWork(nrm:NetResponseMessageVO):void {
			if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('stop work from client error!');
				}
				return;
			}
			
			JobDialog.instance.stopWork();
		}
		
		public function stopWorkFromClient(tool_class_tsid:String):void {
			TSFrontController.instance.genericSend(
				new NetOutgoingJobStopWorkVO(
					spirit_id,
					job_id,
					tool_class_tsid //it's ok if this is null, the server just wants to know we are stopping
				),
				stopWork,
				stopWork
			);
		}
		
		public function stopWorkFromServer(payload:Object):void {
			if(payload.error){
				showError(payload.error.msg);
				CONFIG::debugging {
					Console.warn('stop work from server error!');
				}
				return;
			}
			
			JobDialog.instance.stopWork();
		}
		
		public function getLeaderboard():void {
			TSFrontController.instance.genericSend(
				new NetOutgoingJobLeaderboardVO(
					spirit_id,
					job_id
				), 
				showLeaderboard, 
				showLeaderboard
			);
		}
		
		private function showLeaderboard(nrm:NetResponseMessageVO):void {
			if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('leaderboard error!');
				}
				return;
			}
			
			if(nrm.payload.leaderboard){
				var leaderboard:Leaderboard = Leaderboard.fromAnonymous(nrm.payload.leaderboard, job_id);
				JobDialog.instance.showLeaderboard(leaderboard);
			}
			else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('The payload was missing leaderboard data');
				}
			}
		}
		
		public function sendMessageToServer(type:String, class_tsid:String, amount:int, option:int, req_id:String):void {
			//items
			if(type == MessageTypes.JOB_CONTRIBUTE_ITEM){
				TSFrontController.instance.genericSend(
					new NetOutgoingJobContributeItemVO(
						spirit_id, 
						job_id, 
						class_tsid, 
						amount, 
						option,
						req_id
					), 
					contributeItem, 
					contributeItem
				);
			}
			//work contribute
			else if(type == MessageTypes.JOB_CONTRIBUTE_WORK){
				TSFrontController.instance.genericSend(
					new NetOutgoingJobContributeWorkVO(
						spirit_id, 
						job_id, 
						class_tsid, 
						amount, 
						option,
						req_id
					), 
					contributeWork, 
					contributeWork
				);
			}
			//work apply
			else if(type == MessageTypes.JOB_APPLY_WORK){
				; // shut up warnings
				CONFIG::god {
					TSFrontController.instance.genericSend(
						new NetOutgoingJobApplyWorkVO(
							spirit_id, 
							job_id, 
							class_tsid, 
							amount, 
							option
						), 
						applyWork, 
						applyWork
					);
				}
			}
			//currants
			else {
				TSFrontController.instance.genericSend(
					new NetOutgoingJobContributeCurrantsVO(
						spirit_id, 
						job_id,
						amount, 
						option,
						req_id
					), 
					contributeCurrants, 
					contributeCurrants
				);
			}			
		}
		
		public function claim(group_tsid:String = ''):void {
			TSFrontController.instance.genericSend(
				new NetOutgoingJobClaimVO(spirit_id, job_id, group_tsid), 
				onClaim, 
				onClaim
			);
		}
		
		private function onClaim(nrm:NetResponseMessageVO):void {
			//update the dialog
			if(job_info.type == JobInfo.TYPE_GROUP_HALL){
				//if this is a group hall we go right to the goods
				JobDialog.instance.customNameStatus(nrm.success);
			}
			else {
				JobDialog.instance.claimStatus(nrm.success);
			}

			//update the status if it's there
			if(nrm.payload.status){
				status(nrm.payload.status);
			}
			
			//show an error
			if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('claim error!');
				}
				return;
			}
		}
		
		public function createCustomName(name:String):void {
			TSFrontController.instance.genericSend(
				new NetOutgoingJobCreateNameVO(spirit_id, job_id, name), 
				onCustomName, 
				onCustomName
			);
		}
		
		private function onCustomName(nrm:NetResponseMessageVO):void {
			//update the dialog
			JobDialog.instance.customNameStatus(nrm.success);
			
			//update the status if it's there
			if(nrm.payload.status){
				status(nrm.payload.status);
			}
			
			//show an error
			if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('custom name error!');
				}
				return;
			}
		}
		
		private function showError(txt:String):void {
			TSModelLocator.instance.activityModel.growl_message = txt;
		}
		
		public function getIndicator(itemstack_tsid:String):JobActionIndicatorView {
			var i:int;
			var total:int = indicators.length;
			
			for(i; i < total; i++){
				if(indicators[i].name == itemstack_tsid && indicators[i].parent) return indicators[i];
			}
			
			return null;
		}
		
		private function indicatorsNeedTimer():Boolean {
			var i:int;
			var total:int = indicators.length;
			
			for(i; i < total; i++){
				if(indicators[i].current_available_time > 0) return true;
			}
			
			return false;
		}
		
		public function getReqById(id:String):Requirement {
			var i:int;
			var j:int;
			var k:int;
			var bucket:JobBucket;
			var group:JobGroup;
			var total:int = job_info.buckets.length;
			
			for(i; i < total; i++){
				bucket = job_info.buckets[int(i)];
				for(j = 0; j < bucket.groups.length; j++){
					group = bucket.groups[int(j)];
					for(k = 0; k < group.reqs.length; k++){ 
						if(group.reqs[int(k)].hashName == id) return group.reqs[int(k)];
					}
				}
			}
			
			return null;
		}
		
		private function get spirit_id():String { return JobDialog.instance.spirit_id; }
		private function get job_id():String { return JobDialog.instance.job_id; }
		
		public function get job_info():JobInfo { return _job_info; }
	}
}