package com.tinyspeck.engine.model
{
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.data.prompt.Prompt;
	import com.tinyspeck.engine.model.signals.AbstractPropertyProvider;
	
	public class ActivityModel extends AbstractPropertyProvider
	{
		protected var _party_activity_message:String;
		protected var _activity_message:Activity;
		protected var _growl_message:String;
		protected var _god_message:String;
		protected var _dots_to_draw:Object;
		protected var _poly_to_draw:Object;
		public var net_msgs:Array = [];
		public var net_msgs_short:Array = [];
		public var net_msgs_short_max:int = 500; // only keep this many recent messages
		public var net_msgs_max:int = 1000; // only keep this many in RAM, then send to local storage
		public var prompts:Array = [];
		public var prompt_del:String;
		protected var _announcements:Vector.<Announcement>;
		
		public function ActivityModel()
		{
			super();
			BootError.net_msgsA = net_msgs_short;
		}
		
		public function addPrompt(prompt:Prompt):void {
			prompts.push(prompt);
			triggerCBPropDirect("prompts");
		}
		
		public function removePrompt(uid:String):void {
			for (var i:int;i<prompts.length;i++) {
				if (prompts[int(i)].uid == uid) {
					prompts.splice(i, 1);
					prompt_del = uid;
					triggerCBPropDirect("prompt_del");
					return;
				}
			}
			
		}
		
		public function getPromptByUid(uid:String):Prompt {
			for (var i:int;i<prompts.length;i++) {
				if (prompts[int(i)].uid == uid) return prompts[int(i)];
			}
			
			return null;
		}
		
		public function set activity_message(activity:Activity):void {
			if (!activity.txt) return;
			_activity_message = activity;
			triggerCBPropDirect("activity_message");
		}
		
		public function get activity_message():Activity {
			return _activity_message;
		}
		
		public function set party_activity_message(txt:String):void {
			_party_activity_message = txt;
			triggerCBPropDirect("party_activity_message");
		}
		
		public function get party_activity_message():String {
			return _party_activity_message;
		}
		
		public function set growl_message(txt:String):void {
			if (!txt) return;
			_growl_message = txt;
			triggerCBPropDirect("growl_message");
		}
		
		public function get growl_message():String {
			return _growl_message;
		}
		
		public function set god_message(txt:String):void {
			if (!txt) return;
			_god_message = txt;
			triggerCBPropDirect("god_message");
		}
		
		public function get god_message():String {
			return _god_message;
		}
		
		public function set announcements(announcements:Vector.<Announcement>):void {
			_announcements = announcements;
			triggerCBPropDirect("announcements");
		}
		
		public function get announcements():Vector.<Announcement> {
			return _announcements;
		}
		
		public function set dots_to_draw(ob:Object):void {
			_dots_to_draw = ob;
			triggerCBPropDirect("dots_to_draw");
		}
		
		public function get dots_to_draw():Object {
			return _dots_to_draw;
		}
		
		public function set poly_to_draw(ob:Object):void {
			_poly_to_draw = ob;
			triggerCBPropDirect("poly_to_draw");
		}
		
		public function get poly_to_draw():Object {
			return _poly_to_draw;
		}
	}
}
