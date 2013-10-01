package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.storage.TrophyCase;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	
	import flash.events.EventDispatcher;

	
	/*
	{
	type:"trophy_start",
	itemstack_tsid:"I9sdhkj", // the tsid of the case that was opened
	display_rows:int,
	display_cols:int,
	rows:int, // rows/cols is for the amount of total trophies you have
	cols:int, // according to [http://files.tinyspeck.com/uploads/dburka/2010-07-01/trophy-open-dimensions-fixed.png current spec] this will most likely be 7
	itemstacks:{
	... // a hash of itemstacks the cabinet contains, looks just like an itemstack hash in location start
	}
	}
	*/
	
	public class TrophyCaseManager extends EventDispatcher
	{
		private var _trophy_cases:Vector.<TrophyCase> = new Vector.<TrophyCase>();
		private var model:TSModelLocator;
		private var main_view:TSMainView;
		
		/* singleton boilerplate */
		public static const instance:TrophyCaseManager = new TrophyCaseManager();
		
		public function TrophyCaseManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			model = TSModelLocator.instance;
			main_view = TSFrontController.instance.getMainView();
		}
		
		public function start(payload:Object):Boolean {						
			if(payload.itemstack_tsid){
				var trophy_case:TrophyCase = TrophyCase.getTrophyCaseByTsid(payload.itemstack_tsid);
				var anonTrophyCase:TrophyCase = TrophyCase.fromAnonymous(payload, payload.itemstack_tsid);
				
				if(trophy_case != null){
					//update
					var index:int = trophy_cases.indexOf(trophy_case);
					trophy_cases.splice(index, 1);
					trophy_cases[index] = anonTrophyCase;
				}else{
					trophy_cases.push(anonTrophyCase);
				}
				
				TrophyCaseDialog.instance.start(anonTrophyCase);
				return true;
			}
			
			CONFIG::debugging {
				Console.warn('trophyCaseStartHandler did not get the itemstack_tsid');
			}
			return false;
		}
		
		public function end(payload:Object):void {
			if(payload.itemstack_tsid){
				var trophy_case:TrophyCase = TrophyCase.getTrophyCaseByTsid(payload.itemstack_tsid);
				var index:int = trophy_cases.indexOf(trophy_case);
				trophy_cases.splice(index, 1);
				
				TrophyCaseDialog.instance.end();
			}else{
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('trophyCaseEndHandler did not get the itemstack_tsid');
				}
			}
		}
		
		// this takes the list of stack tsids that have changed, looks to see if the stack has a parent that is a trophy case
		// and then refreshes the cases trophy views
		public function updateTrophiesOnCase(tsids:Array):void {
			
			var i:int;
			var tsid:String;
			var itemstack:Itemstack;
			var case_itemstack:Itemstack;
			var lis_view:LocationItemstackView;

			for (i = 0; i < tsids.length; i++) {
				tsid = tsids[int(i)];
				itemstack = model.worldModel.getItemstackByTsid(tsid);
				case_itemstack = model.worldModel.getItemstackByTsid(itemstack.container_tsid);
				if(!case_itemstack) continue;
				
				if (case_itemstack.class_tsid.indexOf('trophycase') > -1){
					 lis_view = main_view.gameRenderer.getItemstackViewByTsid(case_itemstack.tsid);
					 if (lis_view){
						 lis_view.placeTrophies();
					 } else {
						 ; // satisfy compiler
						 CONFIG::debugging {
							 Console.warn('Could not get Location Itemstack View for '+case_itemstack.tsid);
						 }
					 }
				}
			}
		}
		
		public function isTsidInTrophyCases(tsids:Array):Boolean {
			var i:int;
			var total:int = trophy_cases.length;
			var trophy_case:TrophyCase;
			var chunks:Array = [];
			
			//only get the bag tsids outta the tsids
			for(i = 0; i < tsids.length; i++){
				chunks.push(String(tsids[int(i)]).split('/')[0]);
			}
			
			//loop through the cases to see if the private or public back are a hit on the chunks
			for(i = 0; i < total; i++){
				trophy_case = trophy_cases[int(i)];
				
				if(chunks.indexOf(trophy_case.private_tsid) > -1 || chunks.indexOf(trophy_case.itemstack_tsid) > -1){
					return true;
				}
			}
			
			return false;
		}
		
		public function get trophy_cases():Vector.<TrophyCase> {
			return _trophy_cases;
		}
	}
}