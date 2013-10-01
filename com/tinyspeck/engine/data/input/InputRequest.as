package com.tinyspeck.engine.data.input
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class InputRequest extends AbstractTSDataEntity
	{
		public var input_label:String;
		public var input_value:String = '';
		public var itemstack_tsid:String = '';
		public var uid:String;
		public var title:String;
		public var input_restrict:String;
		public var input_description:String = '';
		public var is_currants:Boolean;
		public var check_user_name:Boolean;
		
		public var input_min_chars:int;
		public var input_max_chars:int;
		
		public var cancelable:Boolean;
		public var input_focus:Boolean;
		public var follow:Boolean; // this not used for anything! will cause noise to remove it, unless we move it from the JS messaging
		public var submit_function:Function; //these are client-side and used to reuse the InputTalkBubble
		public var close_function:Function;
		
		public function InputRequest(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):InputRequest {
			var input_request:InputRequest = new InputRequest(hashName);
			var val:*;
			var j:String;
			
			for(j in object){
				val = object[j];
				if(j in input_request){
					input_request[j] = val;
				}
				else{
					resolveError(input_request,object,j);
				}
			}
			
			// if we're checking for valid name, then we must require at least one character
			if (input_request.check_user_name && !input_request.input_min_chars) {
				input_request.input_min_chars = 1;
			}
			
			return input_request;
		}
		
		public static function updateFromAnonymous(object:Object, input_request:InputRequest):InputRequest {
			input_request = fromAnonymous(object, input_request.hashName);
			
			return input_request;
		}
	}
}