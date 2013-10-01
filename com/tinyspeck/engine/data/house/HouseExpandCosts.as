package com.tinyspeck.engine.data.house
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class HouseExpandCosts extends AbstractTSDataEntity
	{
		public static const TYPE_WALL:String = 'wall';
		public static const TYPE_FLOOR:String = 'floor';
		public static const TYPE_YARD:String = 'yard';
		public static const TYPE_UNEXPAND:String = 'unexpand';
		
		public var count:int;
		public var count_left:int;
		public var count_right:int;
		public var items:Vector.<HouseExpandReq> = new Vector.<HouseExpandReq>();
		public var work:Vector.<HouseExpandReq> = new Vector.<HouseExpandReq>();
		public var img_cost:int;
		public var locked:Boolean;
		public var door_placement:Object
		
		public function HouseExpandCosts(type:String){
			super(type);
		}
		
		public static function fromAnonymous(object:Object, type:String):HouseExpandCosts {
			const expand:HouseExpandCosts = new HouseExpandCosts(type);
			return updateFromAnonymous(object, expand);
		}
		
		public static function updateFromAnonymous(object:Object, expand:HouseExpandCosts):HouseExpandCosts {
			var j:String;

			for(j in object){
				if(j == 'items'){
					expand.items = HouseExpandReq.parseMultiple(object[j]);
				}
				else if(j == 'work'){
					expand.work = HouseExpandReq.parseMultiple(object[j]);
				}
				else if(j in expand){
					expand[j] = object[j];
				}
				else {
					resolveError(expand, object, j);
				}
			}
			
			return expand;
		}
	}
}