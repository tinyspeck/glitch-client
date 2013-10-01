package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.chat.ChatArea;
	
	import flash.events.TextEvent;

	public class SendIMToDevDialog extends BigDialog
	{
		/* singleton boilerplate */
		public static const instance:SendIMToDevDialog = new SendIMToDevDialog();
		
		private var body_tf:TSLinkedTextField = new TSLinkedTextField();
		private var ok_bt:Button;
		
		private var is_built:Boolean;
		
		private var _pc_tsid:String;
		
		public function SendIMToDevDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_body_border_c = 0xffffff;
			_body_fill_c = 0xffffff;
			_close_bt_padd_right = 10;
			_close_bt_padd_top = 10;
			_base_padd = 20;
			_head_min_h = 50;
			_body_min_h = 100;
			_foot_min_h = 59;
			_w = 410;
			//_draggable = true;
			_construct();
		}
		
		private function buildBase():void {
			//body text
			TFUtil.prepTF(body_tf);
			body_tf.embedFonts = false;
			body_tf.width = _w - _base_padd*2;
			body_tf.x = _base_padd;
			body_tf.htmlText = getBodyText();
			body_tf.addEventListener(TextEvent.LINK, onLinkClick, false, 0, true);
			_scroller.body.addChild(body_tf);
			
			//ok button
			ok_bt = new Button({
				name: 'ok',
				label: 'Ok',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_DEFAULT
			});
			//ok_bt.y = int(_foot_min_h/2 - ok_bt.height/2) - 2;
			ok_bt.addEventListener(TSEvent.CHANGED, onOkClick, false, 0, true);
			_foot_sp.addChild(ok_bt);
			_foot_sp.visible = true;
			
			is_built = true;
		}
		
		override public function start():void {
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			if(!pc_tsid){
				CONFIG::debugging {
					Console.warn('Missing pc_tsid, set this before calling start()');
				}
				return;
			}
			
			_setTitle('IM a Dev!');
			
			super.start();
		}
		
		override public function end(release:Boolean):void {
			super.end(release);
			pc_tsid = null;
		}
		
		override protected function _jigger():void {
			super._jigger();
			
			ok_bt.x = int(_w/2 - ok_bt.width/2);
			
			_body_h = Math.max(body_tf.height + _base_padd, _body_min_h);
			_foot_sp.y = _head_h + _body_h;
			_h = _head_h + _body_h + _foot_h;
			
			_draw();
		}
		
		private function getBodyText():String {
			return '<p class="live_help_body">You are about to IM a developer.<br><br>If you\'re asking for help with a particular game feature or a bug you\'re ' +
				'experiencing, please use the Live Help channel instead.<br><br>It\'s not that we don\'t love you —we do!— but using ' +
				'<b><a href="event:'+TSLinkedTextField.LINK_CHAT+'|'+ChatArea.NAME_HELP+'">Live Help</a></b> or ' +
				'<b><a href="event:help">filing a ticket</a></b> are the best ways to get help and report bugs.</p>';
		}
		
		private function onOkClick(event:TSEvent):void {
			//if they are hitting ok, close it up and start the IM
			RightSideManager.instance.chatStart(pc_tsid, true);
			end(true);
		}
		
		private function onLinkClick(event:TextEvent):void {
			switch(event.text){
				case 'help':
					TSFrontController.instance.openHelpCasePage();
					break;
			}
			
			end(true);
		}
		
		public function set pc_tsid(value:String):void { _pc_tsid = value; }
		public function get pc_tsid():String { return _pc_tsid; }
	}
}