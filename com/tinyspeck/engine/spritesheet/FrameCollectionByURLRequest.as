package com.tinyspeck.engine.spritesheet {
	import com.tinyspeck.engine.data.item.Item;
	
	public class FrameCollectionByURLRequest {
		
		public var key:String;
		public var config_sig:String;
		public var swf_data:SWFData;
		public var url:String;
		public var item:Item;
		public var ss:SSAbstractSheet;
		public var frame_num:int;
		public var anim_cmd:SSAnimationCommand;
		public var at_wh:int;
		public var scale_to_stage:Boolean;
		public var ssCollection:SSCollection;
		public var view_and_state_ob:Object;
		public var action:Function;
		public var ss_view:ISpriteSheetView;
		public var was_name:String;
		public var onCompleteHandler:Function;
		
		public var usedAlias:Boolean = false;
		public var ssFrameCollection:SSFrameCollection;
		
		//url, item, ss, frame_num, anim_cmd, at_wh, scale_to_stage, ssCollection, view_and_state_ob
		public function FrameCollectionByURLRequest(key:String, config_sig:String, swf_data:SWFData, url:String, item:Item, ss:SSAbstractSheet, frame_num:int, anim_cmd:SSAnimationCommand, at_wh:int,
			scale_to_stage:Boolean, ssCollection:SSCollection, view_and_state_ob:Object, action:Function, ss_view:ISpriteSheetView, 
			was_name:String, onCompleteHandler:Function) {
			
			this.key = key;
			this.config_sig = config_sig;
			this.swf_data = swf_data; 
			this.url = url;
			this.item = item;
			this.ss = ss;
			this.frame_num = frame_num;
			this.anim_cmd = anim_cmd;
			this.at_wh = at_wh;
			this.scale_to_stage = scale_to_stage;
			this.ssCollection = ssCollection;
			this.view_and_state_ob = view_and_state_ob;
			this.action = action;
			this.ss_view = ss_view;
			this.onCompleteHandler = onCompleteHandler;
		}
	}
}