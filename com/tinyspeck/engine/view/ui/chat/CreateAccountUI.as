package com.tinyspeck.engine.view.ui.chat
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.RightSideView;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;
	
	public class CreateAccountUI extends Sprite
	{
		private static const HEIGHT:uint = 87;
		
		private var tf:TextField = new TextField();
		
		private var bt:Button;
		
		private var is_built:Boolean;
		
		public function CreateAccountUI(){}
		
		private function buildBase():void {
			//draw the BG
			const draw_w:int = RightSideView.MIN_WIDTH_CLOSED;
			const bt_padd:uint = 26;
			
			var g:Graphics = graphics;
			g.beginFill(CSSManager.instance.getUintColorValueFromStyle('create_account', 'backgroundColor', 0xd6dee1));
			g.drawRoundRect(0, 0, draw_w, HEIGHT, 12);
			
			TFUtil.prepTF(tf);
			tf.width = draw_w;
			tf.htmlText = '<p class="create_account">Save your progress...</p>';
			tf.y = 8;
			addChild(tf);
			
			bt = new Button({
				name: 'create',
				label: 'Create an Account',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_CREATE_ACCOUNT,
				w: draw_w - bt_padd*2,
				label_size: CSSManager.instance.getNumberValueFromStyle('button_create_account_label', 'fontSize', 20)
			});
			bt.addEventListener(TSEvent.CHANGED, TSFrontController.instance.openCreateAccountPage, false, 0, true);
			bt.x = bt_padd;
			bt.y = int(tf.y + tf.height);
			addChild(bt);
			
			is_built = true;
		}
		
		public function show():void {
			if(!is_built) buildBase();
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
		}
	}
}