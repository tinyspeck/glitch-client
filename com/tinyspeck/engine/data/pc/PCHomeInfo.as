package com.tinyspeck.engine.data.pc
{
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.model.TSModelLocator;
	
	import flash.utils.Dictionary;

	public class PCHomeInfo extends AbstractPCEntity
	{
		public var interior_tsid:String;
		public var exterior_tsid:String;
		public var all_locations:Dictionary = new Dictionary();
		
		public function PCHomeInfo(){
			super('home_info');
		}
		
		public static function fromAnonymous(object:Object):PCHomeInfo {
			var home_info:PCHomeInfo = new PCHomeInfo();
			var j:String;
			
			for(j in object){
				//add it to the world
				home_info.all_locations[j] = Location.fromAnonymousLocationStub(object[j]);
				
				//set the interior / exterior tsids
				if('is_interior' in object[j] && object[j].is_interior === true){
					home_info.interior_tsid = j;
				}
				else if('is_exterior' in object[j] && object[j].is_exterior === true){
					home_info.exterior_tsid = j;
				}
			}
			
			return home_info;
		}
		
		public function isTsidInHome(tsid:String):Boolean {
			if (all_locations[tsid]) return true;
			return false;
		}
		
		public function playerIsAtHome():Boolean {
			return isTsidInHome(TSModelLocator.instance.worldModel.location.tsid);
		}
	}
}