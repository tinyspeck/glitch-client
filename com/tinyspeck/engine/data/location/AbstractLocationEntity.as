package com.tinyspeck.engine.data.location {
	import com.tinyspeck.core.memory.IDisposable;
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	
	public class AbstractLocationEntity extends AbstractTSDataEntity implements IDisposable {
		public var tsid:String;
		
		/** A friendly name for locodeco */
		public var name:String;
		
		public function AbstractLocationEntity(hashName:String) {
			super(hashName);
			tsid = hashName;
			// set a default name in case one isn't specified later
			name = hashName;
		}
		
		override public function AMF():Object {
			return super.AMF();
		}
	}
}