package com.tinyspeck.engine.view.ui.chat
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class ChatElement extends TSSpriteWithModel
	{
		public static const TYPE_CHAT:String = 'chat';
		public static const TYPE_ACTIVITY:String = 'activity';
		public static const TYPE_REQUEST:String = 'request';
		public static const TYPE_GOD_MSG:String = 'god_msg';
		public static const TYPE_PERF_MSG:String = 'perf_msg';
		public static const TYPE_FEED_REPLY:String = 'feed_reply';
		public static const TYPE_TIMESTAMP:String = 'timestamp';  //used for placing after all the history has loaded in
		public static const TYPE_MOVE:String = 'move';  //used when moving from different locations
		public static const TYPE_QUEST:String = 'quest';
		
		protected static const ACTIVITY_X_OFFSET:int = 3;
		protected static const ACTIVITY_Y_OFFSET:int = 1;
		protected static const ACTIVITY_PADD:uint = 6;
		protected static const ACTIVITY_STICK_WIDTH:uint = 3;
		protected static const TIMESTAMP_BORDER_WIDTH_OFFSET:uint = 15; //how far to bring in the bottom border
		
		protected static const REQUEST_PADD:uint = 6;
		protected static const REQUEST_X_OFFSET:int = 3;
		protected static const REQUEST_Y_OFFSET:int = 2;
		
		protected static const ALERT_ANIMATION_TIME:Number = .2;
		protected static const ALERT_FLASH_COUNT:uint = 3;
		
		protected static const STAFF_SLUG_ALPHA:Number = .6;
		
		protected static var chat_leading:int = -1;
		
		protected var tf:TSLinkedTextField;
		protected var bg:Sprite;
		protected var time_tf:TextField;
		protected var special_slug:DisplayObject;
		
		protected var created:Date;
		protected var now:Date;
				
		protected var _type:String;
		protected var _text:String;
		protected var _enabled:Boolean = true;
		protected var _pc_tsid:String;
		protected var _unix_created_ts:uint;
		protected var _chat_tsid:String;
		
		public function ChatElement() {
			//if we haven't set the leading yet, we should do that
			if(chat_leading == -1){
				chat_leading = CSSManager.instance.getNumberValueFromStyle('chat_element_chat', 'leading', 2)*2 + 2;
			}
		}
		
		public function init(chat_tsid:String, w:int, pc_tsid:String, txt:String, type:String = ChatElement.TYPE_CHAT, unix_created_ts:uint = 0):void {
			tf = new TSLinkedTextField();
			_chat_tsid = chat_tsid;
			_type = type;
			_w = w;
			_text = txt;
			_pc_tsid = pc_tsid;
			
			created = new Date();
			_unix_created_ts = unix_created_ts > 0 ? unix_created_ts : created.getTime()/1000;
						
			TFUtil.prepTF(tf);
			tf.autoSize = TextFieldAutoSize.NONE;
			tf.embedFonts = false;
			tf.selectable = true;
			tf.width = w;
			tf.height = 5; //just something
			tf.name = pc_tsid; //how we reference who the chat is from
			addChild(tf);
			
			//populate the TF then do the different looks
			tf.htmlText = _text;
			//tf.border = true;
			
			if(type == TYPE_CHAT){
				buildChat();
			}
			else if(type == TYPE_ACTIVITY){
				buildActivity();
			}
			else if(type == TYPE_REQUEST || type == TYPE_GOD_MSG || type == TYPE_QUEST || type == TYPE_PERF_MSG){
				buildRequest();
			}
			else if(type == TYPE_TIMESTAMP){
				buildTimestamp();
			}
			else if(type == TYPE_MOVE){
				_text = '<i>'+_text+'</i>';
				tf.htmlText = _text;
				buildMove();
			}
			else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('Type not known: '+type);
				}
			}
		}
		
		public function getsSlug():Boolean {
			var pc:PC = model.worldModel.getPCByTsid(_pc_tsid);
			if (!pc) return false;
			
			//checking for chat_element_chat is legacy, but it was bugging me (scott)
			if (_text.indexOf('<p class="chat_element_chat">'+RightSideManager.SPECIAL_SLUG_GAP) == 0) return true;
			
			// guides only get a slug in help chat
			if (_chat_tsid && _chat_tsid == ChatArea.NAME_HELP) {
				return pc.is_admin || pc.is_guide;
			}
			return pc.is_admin;
		}
		
		private function buildChat():void {
			//check if they are an admin
			var pc:PC = model.worldModel.getPCByTsid(_pc_tsid);
			
			//if(pc && (pc.is_admin || _text.indexOf('<p class="chat_element_chat">'+RightSideManager.SPECIAL_SLUG_GAP) == 0)){
			if (getsSlug()) {
				if (pc.is_guide) {
					special_slug = new AssetManager.instance.assets.guide_slug();
				} else {
					special_slug = new AssetManager.instance.assets.staff_slug();
				}
				
				//if we have the staff slug, move the text over
				if(special_slug){
					special_slug.x = 2;
					addChild(special_slug);
					
					//legacy support so text doesn't go below the button, but leading will be effed up
					if(_text.indexOf(RightSideManager.SPECIAL_SLUG_GAP) == -1){
						tf.htmlText = RightSideManager.SPECIAL_SLUG_GAP + _text;
						tf.height = 5;
					}
				}
			}
			else if(special_slug && contains(special_slug)){
				removeChild(special_slug);
				special_slug = null;
			}
			
			draw();
		}
		
		private function buildActivity():void {
			//nudge the tf over
			tf.x = ACTIVITY_X_OFFSET + ACTIVITY_PADD;
			tf.width = w - ACTIVITY_X_OFFSET - ACTIVITY_PADD;
			
			bg = new Sprite();
			addChildAt(bg, 0);
			
			draw();
		}
		
		private function buildRequest():void {
			tf.x = REQUEST_X_OFFSET + REQUEST_PADD/2;
			tf.width = w - REQUEST_PADD - REQUEST_PADD/2 - REQUEST_X_OFFSET;
			
			bg = new Sprite();
			bg.filters = StaticFilters.black1px90Degrees_DropShadowA;
			addChildAt(bg, 0);
			
			draw();
		}
		
		private function buildTimestamp():void {			
			bg = new Sprite();
			addChildAt(bg, 0);
			
			//show_time calls draw
			show_time = true;
		}
		
		private function buildMove():void {			
			bg = new Sprite();
			addChildAt(bg, 0);
			
			draw();
		}
		
		protected function draw():void {
			var color:uint;
			var top_padd:int = time_tf ? time_tf.height : 0;
			
			//get the graphics if we have the background
			if(bg){
				var g:Graphics = bg.graphics;
				g.clear();
			}
			
			//leading makes things shit the fucking bed when it comes to text height
			tf.height = tf.textHeight + chat_leading;
			
			//if this is an action request, draw the background
			if(type == TYPE_REQUEST || _type == TYPE_GOD_MSG || type == TYPE_QUEST || type == TYPE_PERF_MSG){
				tf.y = REQUEST_PADD/2 + REQUEST_Y_OFFSET + top_padd;
				
				color = enabled 
						? CSSManager.instance.getUintColorValueFromStyle('chat_element_request', 'backgroundColor', 0xE0EDCC) 
						: CSSManager.instance.getUintColorValueFromStyle('chat_element_request', 'backgroundColorDisabled', 0xDDDDDD);
				
				switch (type) {
					case TYPE_GOD_MSG:
						//god messages look the same, but get a different bg color
						color = CSSManager.instance.getUintColorValueFromStyle('chat_element_god_msg', 'backgroundColor', 0xedd5cc);
						break;
					case TYPE_PERF_MSG:
						//perf messages look the same, but get a different bg color
						color = CSSManager.instance.getUintColorValueFromStyle('chat_element_perf_msg', 'backgroundColor', 0xff0000);
						break;
					case TYPE_QUEST:
						//quest elements
						color = CSSManager.instance.getUintColorValueFromStyle('chat_element_quest', 'backgroundColor', 0xe6ecee);
						break;
				}
				
				g.beginFill(color);
				g.drawRoundRect(REQUEST_X_OFFSET, REQUEST_Y_OFFSET + top_padd, w + REQUEST_PADD, int(tf.height) + REQUEST_PADD, 8);
				g.endFill();
				g.drawRect(REQUEST_X_OFFSET, REQUEST_Y_OFFSET + int(tf.height) + REQUEST_PADD + top_padd, 1, 5); //invis gives a nice break between
			}
			else if(type == TYPE_ACTIVITY){
				tf.y = -ACTIVITY_Y_OFFSET + top_padd;
				
				color = getActivityColor();
				g.beginFill(color, .5);
				g.drawRect(ACTIVITY_X_OFFSET, ACTIVITY_Y_OFFSET + top_padd, ACTIVITY_STICK_WIDTH, int(tf.height) - ACTIVITY_Y_OFFSET*3 - 2);
//				g.endFill();
//				g.beginFill(0,0);
//				g.drawRect(ACTIVITY_X_OFFSET, int(tf.height) - ACTIVITY_Y_OFFSET*3 + top_padd, ACTIVITY_STICK_WIDTH, 3); //invis gives a nice break between
			}
			else if(type == TYPE_CHAT){
				tf.y = top_padd;
				if(special_slug){
					tf.y -= 1;
					special_slug.y = top_padd + 1;
					special_slug.alpha = STAFF_SLUG_ALPHA;
				}
			}
			else if(type == TYPE_TIMESTAMP && time_tf){
				color = CSSManager.instance.getUintColorValueFromStyle('chat_element_time', 'borderColorBottom', 0xbebebe);
				g.beginFill(color);
				g.drawRect(ACTIVITY_X_OFFSET + TIMESTAMP_BORDER_WIDTH_OFFSET, int(time_tf.height), _w - TIMESTAMP_BORDER_WIDTH_OFFSET*2, 1);
				g.endFill();
				
				//add some padding below the line
				g.beginFill(0,0);
				g.drawRect(0, int(time_tf.height + 1), _w, 5);
			}
			else if(type == TYPE_MOVE){
				tf.y = top_padd;
				
				color = CSSManager.instance.getUintColorValueFromStyle('chat_element_time', 'borderColorBottom', 0xbebebe);
				g.beginFill(color);
				g.drawRect(ACTIVITY_X_OFFSET, 0, _w - ACTIVITY_X_OFFSET*2, 1);
			}
		}
		
		protected function getActivityColor():uint {
			var color:uint = CSSManager.instance.getUintColorValueFromStyle('chat_element_activity', 'color', 0x7aa2a4);
			
			if(pc_tsid != WorldModel.NO_ONE){
				//get the color from the class already in the text
				color = CSSManager.instance.getUintColorValueFromStyle(
					tf.htmlText.match(/chat_element_others_[0-9]*/g).toString(), 
					'color', 
					RightSideManager.instance.getPCColorUint(pc_tsid)
				);
			}

			return color;
		}
		
		public function alert():void {
			TSTweener.removeTweens(this);
			
			var i:int;
			for(i; i < ALERT_FLASH_COUNT; i++){
				TSTweener.addTween(this, {alpha:0, time:ALERT_ANIMATION_TIME, delay:ALERT_ANIMATION_TIME*(i*2), transition:'linear'});
				TSTweener.addTween(this, {alpha:1, time:ALERT_ANIMATION_TIME, delay:ALERT_ANIMATION_TIME*(i*2+1), transition:'linear'});
			}
			
			//we also want to update the time since this is a repeat
			created = new Date();
			_unix_created_ts = created.getTime()/1000;
		}
		
		public function set htmlText(value:String):void {
			tf.htmlText = value;
			tf.height = 5;
			_text = value;
			
			//just in case this was an admin
			if(_type == TYPE_CHAT){
				buildChat();
			}
			else {
				draw();
			}
		}
		
		public function get type():String { return _type; }
		public function get text():String { return _text; }
		public function get pc_tsid():String { return _pc_tsid; }
		public function get raw_text():String { return tf.text; }
		public function get unix_timestamp():uint { return _unix_created_ts; }
		public function get simple_timestamp():String { 
			created.setTime(_unix_created_ts*1000);
			return StringUtil.getTimeFromDate(created);
		}
		
		public function set show_time(value:Boolean):void {
			if(value){
				//build it if not built
				if(!time_tf){
					time_tf = new TextField();
					TFUtil.prepTF(time_tf);
					time_tf.embedFonts = false;
					addChild(time_tf);
				}
				
				//get now to see if we need to show the month/day or not
				now = new Date();
				created.setTime(_unix_created_ts*1000);
								
				time_tf.width = _w;
				time_tf.htmlText = '<p class="chat_element_time">'+
								   StringUtil.getTimeFromUnixTimestamp(unix_timestamp, false, (created.date == now.date && created.month == now.month && type != TYPE_TIMESTAMP))+
								   '</p>';
			}
			else if(time_tf){
				if(contains(time_tf)) removeChild(time_tf);
				time_tf = null;
			}
			
			draw();
		}
		
		public function get enabled():Boolean { return _enabled; }
		public function set enabled(value:Boolean):void {
			_enabled = value;
			tf.alpha = value ? 1 : .6;
			alpha = value ? 1 : .6;
			
			draw();
			
			//if this is disabled kill it after some time
			var self:ChatElement = this;
			if(!value && !TSTweener.isTweening(this)){
				TSTweener.addTween(self, {alpha:0, time:1, delay:10, transition:'linear',
					onComplete:function():void {
						dispatchEvent(new TSEvent(TSEvent.COMPLETE, self));
					}
				});
				tf.mouseEnabled = false;
			}
		
		}
		
		public function set w(value:int):void {
			_w = value;
			draw();
		}
		
		override public function dispose():void {
			super.dispose();
		}
	}
}