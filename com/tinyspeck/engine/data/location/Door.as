package com.tinyspeck.engine.data.location {
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.ns.client;
	
	import flash.geom.Rectangle;
	
	public class Door extends AbstractPositionableLocationEntity {
		client var physRect:Rectangle;
		client var hide_unless_highlighting:Boolean;
		
		public var connect:LocationConnection;
		public var h:Number;
		public var w:Number;
		public var r:Number = 0;
		public var h_flip:Boolean;
		public var deco:Deco;
		public var for_sale:Boolean = false;
		public var is_locked:Boolean;// = true;
		public var key_id:int;// = '9';
		public var owner_tsid:String;
		public var owner_label:String;
		public var house_number:String;
		public var requires_level:int;
		public var itemstack_tsid:String;
		
		public function Door(hashName:String) {
			super(hashName);
		}
		
		override public function AMF():Object {
			var ob:Object = super.AMF();
			
			if (connect) ob.connect = connect.AMF();
			ob.h = h;
			ob.w = w;
			if (r) ob.r = r;
			if (deco) ob.deco = deco.AMF();
			if (h_flip) ob.h_flip = h_flip;
			ob.for_sale = for_sale;
			ob.is_locked = is_locked;
			ob.key_id = key_id;
			ob.owner_tsid = owner_tsid;
			ob.owner_label = owner_label;
			ob.house_number = house_number;
			ob.requires_level = requires_level;
			ob.itemstack_tsid = itemstack_tsid;
			
			return ob;
		}
		
		public static function parseMultiple(object:Object):Vector.<Door> {
			var doors:Vector.<Door> = new Vector.<Door>();
			for(var j:String in object){
				doors.push(fromAnonymous(object[j],j));
			}
			return doors;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Door {
			return Door.updateFromAnonymous(object, new Door(hashName));
		}
		
		public static function updateFromAnonymous(object:Object, door:Door):Door {
			for(var j:String in object){
				if(j in door){
					if(j == "connect"){
						door.connect = LocationConnection.fromAnonymous(object[j],j);
					}else if(j == "deco"){
						door.deco = Deco.fromAnonymous(object[j], j);
						door.deco.is_simple = true;
					}else{
						door[j] = object[j];
					}
				}else{
					if (j == 'id') {
						// not sure what this is for, legacy I thing
					}else if(j == "chassis_tsid"){
						door.itemstack_tsid = object[j];
					} else {
						resolveError(door,object,j);
					}
				}
			}
			
			if (!door.itemstack_tsid && object.item_tsid) {
				door.itemstack_tsid = object.item_tsid;
			}
			
			// TEMP TEMP TEMP TEMP
			/*
			if (door.hashName == 'floor_1_up') {
				door.itemstack_tsid = 'IPF1L7933LR2GGJ';
				door.deco = null;
				CONFIG::debugging {
					Console.dir(object);
				}
			}

			if (door.hashName == 'floor_1_down') {
				door.itemstack_tsid = 'IPF1L8N63LR22PV';
				door.deco = null;
				CONFIG::debugging {
					Console.dir(object);
				}
			}
			*/
			
			if (isNaN(door.w)) door.w = 150;
			if (isNaN(door.h)) door.h = 200;
			
			return door;
		}
	}
}