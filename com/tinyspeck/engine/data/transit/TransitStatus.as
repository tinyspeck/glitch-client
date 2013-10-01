package com.tinyspeck.engine.data.transit
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class TransitStatus extends AbstractTSDataEntity
	{
		public var tsid:String;
		public var current_tsid:String;
		public var next_tsid:String;
		public var line_tsid:String;
		public var time_to_destination:int;
		public var is_moving:Boolean;
		
		public function TransitStatus(tsid:String){
			super(tsid);
			this.tsid = tsid;
		}
		
		public static function fromAnonymous(object:Object, tsid:String):TransitStatus {
			var status:TransitStatus = new TransitStatus(tsid);
			var j:String;
			
			for(j in object){
				if(j in status){	
					status[j] = object[j];
				}
				else{
					resolveError(status,object,j);
				}
			}
			
			return status;
		}
	}
}