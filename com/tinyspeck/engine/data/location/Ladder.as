package com.tinyspeck.engine.data.location {
	
	import com.tinyspeck.engine.ns.client;
	
	import flash.geom.Rectangle;

	public class Ladder extends Surface {
		client var physRect:Rectangle;
		
		public function Ladder(hashName:String) {
			super(hashName);
		}
		
		override public function AMF():Object {
			return super.AMF();
		}
		
		public static function parseMultiple(object:Object):Vector.<Ladder> {
			var ladders:Vector.<Ladder> = new Vector.<Ladder>();
			for(var j:String in object){
				ladders.push(fromAnonymous(object[j],j));
			}
			return ladders;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Ladder {
			var ladder:Ladder = new Ladder(hashName);
			for(var j:String in object){
				if(j in ladder){
					if(j == "tiling"){
						ladder.tiling = Tiling.fromAnonymous(object[j],j);
					}else{
						ladder[j] = object[j];
					}
				}else{
					resolveError(ladder,object,j);
				}
			}
			return ladder;
		}
	}
}