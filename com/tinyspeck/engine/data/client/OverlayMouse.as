package com.tinyspeck.engine.data.client
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class OverlayMouse extends AbstractTSDataEntity
	{
		public static const TYPE_CHANGE_TOWER:String = 'change_tower';
		public var is_clickable:Boolean;
		public var allow_multiple_clicks:Boolean;
		public var dismiss_on_click:Boolean;
		public var click_payload:Object;
		public var click_client_action:Object;
		public var click_verb:String;
		public var txt:String;
		public var txt_delta_y:int;
		
		public function OverlayMouse(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object):OverlayMouse {
			var om:OverlayMouse = new OverlayMouse('overlay_mouse');
			var j:String;
			
			for(j in object){
				if(j in om){
					om[j] = object[j];
				}
				else{
					resolveError(om,object,j);
				}
			}
			
			return om;
		}
	}
}