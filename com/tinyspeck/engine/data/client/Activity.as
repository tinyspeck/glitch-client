package com.tinyspeck.engine.data.client
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;

	public class Activity extends AbstractTSDataEntity
	{
		public var txt:String;
		public var pc_tsid:String;
		public var auto_prepend:Boolean;
		public var no_growl:Boolean;
		public var growl_only:Boolean;
		
		public function Activity(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object):Activity {
			var activity:Activity = new Activity('activity');
			var val:*;
			var j:String;
			
			for(j in object){
				val = object[j];
				if(j == 'pc' && val){
					//set the tsid
					activity.pc_tsid = val['tsid'];
				}
				else if(j in activity){
					activity[j] = val;
				}
				else if(j != 'changes' && j != 'announcements'){ // shut up logs (this happens because we pass the whole im.payload to this func, and any im.payload can have changed or announcements on it)
					resolveError(activity,object,j);
				}
			}
			
			return activity;
		}
		
		public static function updateFromAnonymous(object:Object, activity:Activity):Activity {
			activity = fromAnonymous(object);
			
			return activity;
		}
		
		/**
		 * Allows the worldModel.pc to have an activity just by getting the string 
		 * @param txt
		 * @return 
		 */		
		public static function createFromCurrentPlayer(txt:String):Activity {
			var pc:PC = TSModelLocator.instance.worldModel.pc;
			var activity:Activity = new Activity('default');
			activity.txt = txt;
			
			if(pc) activity.pc_tsid = pc.tsid;
			
			return activity;
		}
	}
}