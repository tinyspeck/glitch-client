package com.tinyspeck.engine.data.client
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class ActionRequest extends AbstractTSDataEntity
	{
		public var txt:String = '';
		public var player_tsid:String;
		public var event_type:String;
		public var event_tsid:String;
		public var got:int;
		public var need:int;
		public var uid:String;
		public var timeout_secs:uint;
		public var has_accepted:Boolean;
		
		public function ActionRequest(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object):ActionRequest {
			var request:ActionRequest = new ActionRequest('action_request');
			var val:*;
			var j:String;
			
			for(j in object){
				val = object[j];
				if(j == 'pc' && val){
					//set the tsid
					request.player_tsid = val['tsid'];
				}
				else if(j in request){
					request[j] = val;
				}
				else{
					resolveError(request,object,j);
				}
			}
			
			return request;
		}
		
		public static function updateFromAnonymous(object:Object, request:ActionRequest):ActionRequest {
			request = fromAnonymous(object);
			
			return request;
		}
	}
}