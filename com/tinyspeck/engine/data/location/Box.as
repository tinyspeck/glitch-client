package com.tinyspeck.engine.data.location
{
	public class Box extends AbstractPositionableLocationEntity
	{
		public var w:Number;
		public var h:Number;
		public var id:String; // what the fuck is this? it is being sent by GS
		// eric ^ id is what the box thingy does, or something. ask Myles ;-)
		
		public function Box(hashName:String) {
			super(hashName);
		}
		
		override public function AMF():Object {
			var ob:Object = super.AMF();
			
			ob.h = h;
			ob.w = w;
			ob.id = id;
			
			return ob;
		}
		
		public static function parseMultiple(object:Object):Vector.<Box> {
			var boxes:Vector.<Box> = new Vector.<Box>();
			for(var j:String in object){
				boxes.push(fromAnonymous(object[j],j));
			}
			return boxes;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Box {
			var box:Box = new Box(hashName);
			for(var j:String in object){
				if(j in box){	
					box[j] = object[j];
				}else{
					resolveError(box,object,j);
				}
			}
			return box;
		}
	}
}