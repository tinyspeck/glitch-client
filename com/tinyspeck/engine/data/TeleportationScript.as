package com.tinyspeck.engine.data
{
	public class TeleportationScript extends AbstractTSDataEntity
	{
		public var title:String;
		public var body:String;
		public var start_in_edit_mode:Boolean;
		public var itemstack_tsid:String;
		public var owner_label:String;
		public var owner_tsid:String;
		public var is_imbued:Boolean;
		public var updated:uint;
		public var destination:String;
		public var max_chars:uint;
		
		public function TeleportationScript(hashName:String){
			super(hashName);
			itemstack_tsid = hashName;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):TeleportationScript {
			var script:TeleportationScript = new TeleportationScript(hashName);
			var val:*;
			var j:String;
			
			for(j in object){
				val = object[j];
				if(j == 'pc' && val){
					//just sent the label and tsid
					script.owner_label = val['label'];
					script.owner_tsid = val['tsid'];
				}
				else if(j in script){
					script[j] = val;
				}
				else{
					resolveError(script,object,j);
				}
			}
			
			return script;
		}
		
		public static function updateFromAnonymous(object:Object, script:TeleportationScript):TeleportationScript {
			script = fromAnonymous(object, script.hashName);
			
			return script;
		}
	}
}