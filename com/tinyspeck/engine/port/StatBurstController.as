package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	
	import flash.geom.Point;

	public class StatBurstController
	{
		/* singleton boilerplate */
		public static const instance:StatBurstController = new StatBurstController();
		
		public var paused:Boolean = false;
		private const bursts:Vector.<StatBurst> = new Vector.<StatBurst>();
		
		private var change_subscribers:Vector.<IStatBurstChange> = new Vector.<IStatBurstChange>();
		
		public function StatBurstController() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function onMoodChange(val:Number):void {
			const loc:Location = TSModelLocator.instance.worldModel.location;
			if(loc && !loc.no_mood){
				const pt:Point = YouDisplayManager.instance.getMoodGaugeCenterPt();
				burst(StatBurst.MOOD, pt, val);
			}
		}
		
		public function onEnergyChange(val:Number):void {
			const loc:Location = TSModelLocator.instance.worldModel.location;
			if(loc && !loc.no_energy){
				const pt:Point = YouDisplayManager.instance.getEnergyGaugeCenterPt();
				burst(StatBurst.ENERGY, pt, val);
			}
		}
		
		public function onCurrantsChange(val:Number):void {
			const loc:Location = TSModelLocator.instance.worldModel.location;
			if(loc && loc.show_pack){
				const pt:Point = YouDisplayManager.instance.getCurrantsCenterPt();
				burst(StatBurst.CURRANTS, pt, val);
			}
		}
		
		public function onXPChange(val:Number, force_show:Boolean = false):void {
			const loc:Location = TSModelLocator.instance.worldModel.location;
			const pt:Point = YouDisplayManager.instance.getImaginationCenterPt();
			//only delay this if we are not showing the iMG menu
			if(loc && loc.no_imagination){
				StageBeacon.setTimeout(burst, 250, StatBurst.XP, pt, val);
			}
			else {
				//just show it
				burst(StatBurst.XP, pt, val);
			}		
		}
		
		private function burst(type:String, pt:Point, val:Number):void {
			if (paused) return;
			
			//find one in the pool that doesn't have a parent, otherwise make a new one
			var i:int;
			const total:int = bursts.length;
			var stat_burst:StatBurst;
			
			for(i; i < total; i++){
				if(!bursts[int(i)].parent){
					//found one without a parent, let's use it
					stat_burst = bursts[int(i)];
					break;
				}
			}
			
			//make a new one
			if(!stat_burst){
				stat_burst = new StatBurst();
				bursts.push(stat_burst);
			}
			
			//set the type
			stat_burst.type = type;
			
			/*
			if (stat_burst.running) {
				stat_burst.end();
			}
			*/
			
			stat_burst.x = pt.x;
			stat_burst.y = pt.y;
			
			if(change_subscribers.length == 0){
				stat_burst.go(val);
			}
			else {
				notifySubscribers(stat_burst, val);
			}
		}
		
		public function isChangeSubscriber(subscriber:IStatBurstChange):Boolean {
			const index:int = change_subscribers.indexOf(subscriber);
			
			return (index > -1) ? true : false;
		}
		
		public function registerChangeSubscriber(subscriber:IStatBurstChange):void {
			if(!isChangeSubscriber(subscriber)){
				change_subscribers.push(subscriber);
			}
		}
		
		public function unRegisterChangeSubscriber(subscriber:IStatBurstChange):void {
			const index:int = change_subscribers.indexOf(subscriber);
			
			if(index > -1){
				change_subscribers.splice(index, 1);
			}
		}
		
		private function notifySubscribers(stat_burst:StatBurst, value:int):void {
			var i:int = 0;
			const total:uint = change_subscribers.length;
			
			for(i; i < total; i++){
				change_subscribers[int(i)].onStatBurstChange(stat_burst, value);
			}
		}
	}
}