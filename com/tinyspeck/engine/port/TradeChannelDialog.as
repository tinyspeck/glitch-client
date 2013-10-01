package com.tinyspeck.engine.port
{
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.chat.ChatArea;

	public class TradeChannelDialog extends BigDialog
	{
		/* singleton boilerplate */
		public static const instance:TradeChannelDialog = new TradeChannelDialog();
		
		private var body_tf:TSLinkedTextField = new TSLinkedTextField();
		private var ok_bt:Button;
		
		private var is_built:Boolean;
		
		public function TradeChannelDialog(){
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
			//body_tf.y = _base_padd;
			body_tf.htmlText = getBodyText();
			_scroller.body.addChild(body_tf);
			
			//ok button
			ok_bt = new Button({
				name: 'ok',
				label: 'Got it! I am here for trading',
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
			
			_setTitle('Hello! This is the Trade Channel!');
			
			super.start();
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
			return '<p class="live_help_body">This channel is for trading chat only. Other conversations should happen elsewhere!<br><br>'+
				   'Buyers come first; sellers: no spamming. Still, be funny & creative.</p>';
		}
		
		private function onOkClick(event:TSEvent):void {
			//if they are hitting ok, close it up and join the channel
			end(true);
			RightSideManager.instance.groupStart(ChatArea.NAME_TRADE, true);
		}
	}
}