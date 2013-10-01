package com.tinyspeck.engine.data.location {

	public class TargetSource extends AbstractLocationEntity {
		public var street_tsid:String;
		public var mote_id:String;
		public var hub_id:String;
		public var source_key:String;
		
		public function TargetSource(hashName:String) {
			super(hashName);
		}
		
		override public function AMF():Object {
			var ob:Object = super.AMF();
			
			ob.street_tsid = street_tsid;
			ob.mote_id = mote_id;
			ob.hub_id = hub_id;
			ob.source_key = source_key;
			
			return ob;
		}
		
		public static function parseMultiple(object:Object):Vector.<TargetSource> {
			var sources:Vector.<TargetSource> = new Vector.<TargetSource>();
			for(var j:String in object){
				sources.push(fromAnonymous(object[j],j));
			}
			return sources;
		}
		
		public static function fromAnonymous(object:Object,hashName:String):TargetSource {
			var targetSource:TargetSource = new TargetSource(hashName);
			for(var j:String in object){
				if(j in targetSource){
					targetSource[j] = object[j];
				}else{
					resolveError(targetSource,object,j);
				}
			}
			return targetSource;
		}
	}
}