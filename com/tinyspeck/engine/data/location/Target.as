package com.tinyspeck.engine.data.location {

	public class Target extends AbstractPositionableLocationEntity {
		public var sources:Vector.<TargetSource>;
		
		public function Target(hashName:String) {
			super(hashName);
		}
		
		override public function AMF():Object {
			var ob:Object = super.AMF();
			
			if (sources) {
				ob.sources = {};
				for (var i:int=sources.length-1; i>-1; i--) {
					ob.sources[sources[int(i)].hashName] = sources[int(i)].AMF();
				}
			}
			
			return ob;
		}
		
		public static function parseMultiple(object:Object):Vector.<Target> {
			var targets:Vector.<Target> = new Vector.<Target>();
			for(var j:String in object){
				targets.push(fromAnonymous(object[j],j));
			}
			return targets;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Target {
			var target:Target = new Target(hashName);
			for(var j:String in object){
				if(j in target){
					if(j == "sources"){
						target.sources = TargetSource.parseMultiple(object[j]);
					}else{
						target[j] = object[j];
					}
				}else{
					resolveError(target,object,j);
				}
			}
			return target;
		}
	}
}