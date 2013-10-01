package com.tinyspeck.engine.port {
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;

	public class DecoratorDisclaimerDialog extends BigDialog {
		
		/* singleton boilerplate */
		public static const instance:DecoratorDisclaimerDialog = new DecoratorDisclaimerDialog();
		
		private var body_tf:TSLinkedTextField = new TSLinkedTextField();
		private var ok_bt:Button;
		private var is_built:Boolean;
		
		public function DecoratorDisclaimerDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_body_border_c = 0xffffff;
			_body_fill_c = 0xffffff;
			_close_bt_padd_right = 10;
			_close_bt_padd_top = 10;
			_base_padd = 25;
			_head_min_h = 65;
			_body_min_h = 100;
			_foot_min_h = 59;
			_w = 640;
			_draggable = true;
			_construct();
		}
		
		private function buildBase():void {
			//body text
			TFUtil.prepTF(body_tf);
			body_tf.width = _w - _base_padd*2;
			body_tf.x = _base_padd;
			body_tf.htmlText = getBodyText();
			_scroller.body.addChild(body_tf);
			
			//ok button
			ok_bt = new Button({
				name: 'ok',
				label: 'Duly Noted',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_DEFAULT
			});
			ok_bt.addEventListener(TSEvent.CHANGED, onOkClick, false, 0, true);
			_foot_sp.addChild(ok_bt);
			_foot_sp.visible = true;
			
			is_built = true;
		}
		
		override public function start():void {
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			
			_setTitle('<span class="decorator_disclaimer_h1">Welcome to Your New Test House!</span>');
			
			super.start();
		}
		
		override protected function _jigger():void {
			super._jigger();
			ok_bt.x = int(_w - ok_bt.width - _base_padd);
			_title_tf.y = _base_padd - 10;
			_body_h = Math.max(body_tf.height + _base_padd, _body_min_h);
			_foot_sp.y = _head_h + _body_h;
			_h = _head_h + _body_h + _foot_h;
			_draw();
		}
		
		private function getBodyText():String {
			return '<p class="decorator_disclaimer_body"><span class="decorator_disclaimer_h2">This place is just for testing. Your customizations will eventually be reset.</span><br>' +
				'On the other hand, you won’t lose any items you place here (they’ll be kept safe).<br></p>' +
				
				'<p class="decorator_disclaimer_body"><span class="decorator_disclaimer_h2">You have been given some furniture.</span><br>' +
				'In the next release, you’ll be able to craft your own furniture items (and buy/sell/trade and give them). For now, however, ' +
				'we’re just giving you a limited number. You know, for testing!<br></p>' +
				
				'<p class="decorator_disclaimer_body"><span class="decorator_disclaimer_h2">While testing, everything is free.</span><br>' +
				'Some upgrades, which will later cost credits or be locked to subscribers, are available for free right now. The prices shown ' +
				'will not be charged (and are still subject to change).<br></p>' +/*
				
				'<p class="decorator_disclaimer_body"><span class="decorator_disclaimer_h2">You can’t expand your testing house or cultivate your yard.</span><br>' +
				'This release is about the basics of decoration and furniture. The housing system has other components in development, but they will not be ' +
				'available until later releases.<br></p>' +*/
				
				'<p class="decorator_disclaimer_body">Read more and give us some feedback <a href="event:'+TSLinkedTextField.LINK_EXTERNAL+'|http://www.glitch.com/forum/general/19087/|forum_decorator">in the forums</a>!</p>';
		}
		
		override public function end(release:Boolean):void {
			model.stateModel.seen_deco_disclaimer_dialog_this_session = true;
			LocalStorage.instance.setUserData('seen_deco_test_discalimer', true);
			super.end(release);
		}
		
		private function onOkClick(event:TSEvent):void {
			end(true);
		}
	}
}