package com.tinyspeck.engine.data.map
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class Street extends AbstractTSDataEntity
	{
		public var x1:int;
		public var x2:int;
		public var y1:int;
		public var y2:int;
		public var type:String;
		public var name:String;
		public var tsid:String;
		public var store:String; //store name
		public var shrine:String; //shrine name
		public var has_subway:Boolean; //has a subway station
		public var not_a_destination:Boolean;
		public var invisible_to_outsiders:Boolean;
		public var scaled_distance:Number;
		public var rotation:Number;
		public var visited:Boolean;
		public var dirty:Boolean; //if a street becomes dirty, then we are flagging this to remove from the mapdata hash
		public var no_info:Boolean;
		
		//hub stuff (to draw the circle button things)
		public var x:int;
		public var y:int;
		public var arrow:int;
		public var hub:String;
		public var mote:String;
		public var mote_id:String;
		public var hub_id:String;
		public var color:String;
		public var label:int; //label rotation
		
		public function Street(hashName:String){
			super(hashName);
			tsid = hashName;
		}
		
		public static function fromAnonymous(object:Object, tsid:String):Street {
			var street:Street = new Street(tsid);
			
			return updateFromAnonymous(object, street);
		}
		
		public static function updateFromAnonymous(object:Object, street:Street):Street {
			var j:String;
			
			for(j in object){
				if(j == 'shrine' && object.shrine == 'ti'){
					street.shrine = 'tii';
				}
				else if(j in street){	
					street[j] = object[j];
				}
				else{
					resolveError(street,object,j);
				}
			}
			return street;
		}
	}
}