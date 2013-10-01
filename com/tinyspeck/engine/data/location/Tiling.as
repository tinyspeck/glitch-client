package com.tinyspeck.engine.data.location {

	public class Tiling extends AbstractLocationEntity {
		public var cap_0:Cap;
		public var center_pattern:String;
		public var centers:Vector.<Center>;
		public var cap_1:Cap;
		
		public function Tiling(hashName:String) {
			super(hashName);
		}
		
		override public function AMF():Object {
			var i:int;
			var ob:Object = super.AMF();
			
			if (cap_0) ob.cap_0 = cap_0.AMF();
			if (cap_1) ob.cap_1 = cap_1.AMF();
			if (center_pattern) ob.center_pattern = center_pattern;

			if (centers) {
				ob.centers = {};
				for (i=centers.length-1; i>-1; i--) {
					ob.centers[centers[int(i)].hashName] = centers[int(i)].AMF();
				}
			}
			
			return ob;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Tiling {
			var tiling:Tiling = new Tiling(hashName);
			for(var j:String in object){
				if(j in tiling){
					if(j == "cap_0"){
						tiling.cap_0 = Cap.fromAnonymous(object[j],j);
						tiling.cap_0.is_simple = true;
					}else if(j == "cap_1"){
						tiling.cap_1 = Cap.fromAnonymous(object[j],j);
						tiling.cap_1.is_simple = true;
					}else if(j == "centers"){
						tiling.centers = Center.parseMultiple(object[j]);
						if (tiling.centers) {
							for (var m:int=tiling.centers.length-1; m>-1; m--) {
								tiling.centers[m].is_simple = true
							}
						}
					}else{
						tiling[j] = object[j];
					}
				}else{
					resolveError(tiling,object,j);
				}
			}
			return tiling;
		}
	}
}