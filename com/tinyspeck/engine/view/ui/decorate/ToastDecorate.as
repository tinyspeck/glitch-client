package com.tinyspeck.engine.view.ui.decorate
{
	import com.tinyspeck.engine.control.HandOfDecorator;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.decorate.Swatch;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.SubscriberOnlyDialog;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.Toast;
	
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.text.TextField;

	public class ToastDecorate extends Toast
	{
		private static const WIDTH:uint = 420; //lol smoke weed everyday
		private static const HEIGHT:uint = 70;
		private static const TEXT_PADD:uint = 12;
		
		private var buy_bt:Button;
		
		private var you_have_tf:TextField = new TextField();
		private var credits_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var credits_icon:DisplayObject;
		
		private var _swatch:Swatch;
		
		public function ToastDecorate(){
			super(WIDTH, TYPE_WARNING);
			h = HEIGHT;
			alpha = .99; //fix for the redraw bug?
		}
		
		override protected function construct():void {
			super.construct();
			
			SpriteUtil.clean(icon_holder);
			
			//handle the custom close button
			SpriteUtil.clean(close_holder);
			close_holder.addChild(new AssetManager.instance.assets.close_decorate_toast());
			close_holder.visible = false;
			addChild(close_holder);
			
			//buy button
			buy_bt = new Button({
				name: 'buy',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			buy_bt.y = int(HEIGHT/2 - buy_bt.height/2);
			buy_bt.addEventListener(TSEvent.CHANGED, onBuyClick, false, 0, true);
			holder.addChild(buy_bt);
			
			//get the size
			msg_tf.htmlText = '<p class="toast_decorate">placeholder</p>';
			
			//credits
			TFUtil.prepTF(you_have_tf, false);
			you_have_tf.htmlText = '<p class="toast_decorate"><span class="toast_decorate_credits">You have</span></p>';
			you_have_tf.x = TEXT_PADD;
			you_have_tf.y = int(TEXT_PADD + msg_tf.height - 5);
			holder.addChild(you_have_tf);
			
			credits_icon = new AssetManager.instance.assets.furn_credits_small();
			credits_icon.x = int(you_have_tf.x + you_have_tf.width + 2);
			credits_icon.y = you_have_tf.y + 3;
			holder.addChild(credits_icon);
			
			TFUtil.prepTF(credits_tf, false);
			credits_tf.x = int(credits_icon.x + credits_icon.width);
			credits_tf.y = you_have_tf.y;
			holder.addChild(credits_tf);
			
		}
		
		override public function show(msg:String='', open_time:Number = Toast.DEFAULT_OPEN_TIME):void {
			super.show(msg, open_time);
			
			//we want to listen to stats while this is open in the event they change the subscription status
			TSModelLocator.instance.worldModel.registerCBProp(onStatsChanged, "pc", "stats");
		}
		
		override protected function onCloseClick(event:MouseEvent):void {
			// we may want to not do the prompt thing here when the click on the (x), but for now...
			/*if (promptForSave(false)) {
				return;
			}*/
			
			cancel();
			super.onCloseClick(event);
		}
		
		
		private function cancel():void {
			HandOfDecorator.instance.onToastCancelClick();
			TSModelLocator.instance.worldModel.unRegisterCBProp(onStatsChanged, "pc", "stats");
			hide(0);
		}
		
		private function closeAfterSaveConfirmation():void {
			cancel();
		}
		
		public function promptForSave(and_stop_deco_mode:Boolean):Boolean {
			if (buy_bt.disabled || !swatch) {
				return false;
			}
			/*
			var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
			cdVO.title = 'Save Your Changes?';
			cdVO.txt = 'You are previewing '+swatch.type+'! Did you want to save?';
			cdVO.choices = [
				{value: true, label: 'Yes, Save!'},
				{value: false, label: 'No, Discard'}
			];
			cdVO.escape_value = false;
			cdVO.callback =	function(value:*):void {
				if (value === true && !buy_bt.disabled) {
					HandOfDecorator.instance.onToastBuyClick(and_stop_deco_mode);
				} else {
					closeAfterSaveConfirmation();
					if (and_stop_deco_mode) {
						TSFrontController.instance.stopDecoratorMode();
					}
				}
			};
			TSFrontController.instance.confirm(cdVO);
			*/
			
			//closeAfterSaveConfirmation();
			if (and_stop_deco_mode) {
				TSFrontController.instance.stopDecoratorMode();
			}
			
			return true;
		}
		
		private function onStatsChanged(pc_stats:PCStats):void {
			//make sure things are up to date
			draw(false);
		}
		
		override protected function draw(reset_position:Boolean = true):void {
			super.draw(reset_position);
			
			close_holder.x = int(_w + 8);
			close_holder.y = int(h/2 - close_holder.height/2 + holder.y + 2);
			
			if(!swatch) return;
			
			//show the cost etc
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			const pc_credits:int = pc && pc.stats ? pc.stats.credits : 0;
			var bt_label:String = 'Buy for '+StringUtil.formatNumberWithCommas(swatch.cost_credits)+' '+(swatch.cost_credits != 1 ? 'credits' : 'credit');
			buy_bt.value = null;
			if(!swatch.cost_credits){
				bt_label = 'Use it!';
			}
			else if(swatch.is_subscriber && !pc.stats.is_subscriber){
				bt_label = 'Subscriber only';
				buy_bt.value = 'needs_subscriber';
			}
			else if(pc_credits < swatch.cost_credits){
				bt_label = 'Get more credits';
				buy_bt.value = 'needs_credits';
			}
			
			buy_bt.label = bt_label;
			buy_bt.x = _w - buy_bt.width - 8 - (swatch.cost_credits ? 0 : 8);
			
			//set the message (TODO, get the real name!)
			msg_tf.x = TEXT_PADD;
			msg_tf.y = TEXT_PADD - 3 + (swatch.cost_credits ? 0 : 12);
			msg_tf.htmlText = '<p class="toast_decorate">Previewing “'+swatch.label+'”</p>';
			
			var credits_txt:String = '<span class="toast_decorate_credits">'+StringUtil.formatNumberWithCommas(pc_credits)+' '+(pc_credits != 1 ? 'credits' : 'credit')+'</span>';
			var get_credits_txt:String = 'Get more!';
			
			if(pc_credits < swatch.cost_credits){
				//not enough, show it as red
				get_credits_txt = '<span class="toast_decorate_error">';
				get_credits_txt += 'You need '+StringUtil.formatNumberWithCommas(swatch.cost_credits - pc_credits)+' more!';
				get_credits_txt += '</span>';
			}
			credits_tf.htmlText = '<p class="toast_decorate">'+credits_txt+'&nbsp;&nbsp;&nbsp;<a href="event:'+TSLinkedTextField.LINK_CREDIT_PURCHASE+'">'+get_credits_txt+'</a></p>';
			
			//can we see the stuff related to credits?
			credits_tf.visible = you_have_tf.visible = credits_icon.visible = swatch.cost_credits > 0;
		}
		
		override protected function onAnimate():void {
			super.onAnimate();
			
			//make sure the close button animates too
			close_holder.y = int(h/2 - close_holder.height/2 + holder.y + 2);
			close_holder.visible = close_holder.y < -close_holder.height;
			
			//fixes flash being odd and redrawing this up in the mask
			//alpha = (holder.y/holder.height)+1;
		}
		
		override protected function onTimerTick(event:TimerEvent):void {
			//this toast doesn't go away, so just stop the timer
			hide_timer.stop();
		}
		
		private function onBuyClick(event:TSEvent):void {
			if(buy_bt.disabled) return;
			if(buy_bt.value == 'needs_credits'){
				//open the credits page
				TSFrontController.instance.openCreditsPage();
			}
			else if(buy_bt.value == 'needs_subscriber'){
				//open the subscription dialog
				SubscriberOnlyDialog.instance.start();
			}
			else {
				//go ahead and buy it
				HandOfDecorator.instance.onToastBuyClick(false);
			}
		}
		
		public function get swatch():Swatch { return _swatch; }
		public function set swatch(value:Swatch):void {
			_swatch = value;
			draw();
		}
	}
}