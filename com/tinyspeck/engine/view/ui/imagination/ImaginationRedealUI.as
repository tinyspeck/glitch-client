package com.tinyspeck.engine.view.ui.imagination
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class ImaginationRedealUI extends Sprite
	{
		private static const BG_W:uint = 130;
		private static const BG_H:uint = 30;
		private static const DISABLED_ALPHA:Number = .6;
		
		private var bg:Sprite = new Sprite();
		
		private var redeal_icon:DisplayObject;
		private var no_redeal_icon:DisplayObject;
		
		private var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
		
		private var redeal_tf:TextField = new TextField();
		private var per_day_tf:TextField = new TextField();
		
		private var is_built:Boolean;
		private var _enabled:Boolean;
		
		public function ImaginationRedealUI(){}
		
		private function buildBase():void {		
			//bg
			var g:Graphics = bg.graphics;
			g.beginFill(0, .9);
			g.drawRoundRect(0, 0, BG_W, BG_H, BG_H);
			addChild(bg);
			bg.mouseChildren = false;
			bg.buttonMode = bg.useHandCursor = true;
			bg.addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			
			//icons
			redeal_icon = new AssetManager.instance.assets.redeal();
			redeal_icon.x = 9;
			redeal_icon.y = int(BG_H/2 - redeal_icon.height/2);
			bg.addChild(redeal_icon);
			
			no_redeal_icon = new AssetManager.instance.assets.redeal_no(); //naming is funky, but wanted them together in the assets directory
			no_redeal_icon.x = redeal_icon.x;
			no_redeal_icon.y = redeal_icon.y + 1;
			bg.addChild(no_redeal_icon);
			
			//tfs
			TFUtil.prepTF(redeal_tf, false);
			redeal_tf.htmlText = '<p class="imagination_redeal">Re-deal cards</p>';
			redeal_tf.x = int(redeal_icon.x + redeal_icon.width + 6);
			redeal_tf.y = int(BG_H/2 - redeal_tf.height/2 + 1);
			bg.addChild(redeal_tf);
			
			TFUtil.prepTF(per_day_tf, false);
			per_day_tf.y = BG_H;
			per_day_tf.filters = StaticFilters.black1px90Degrees_DropShadowA;
			addChild(per_day_tf);
			
			//confirm
			cdVO.title = 'Re-deal?';
			cdVO.choices = [
				{value: false, label:'Nevermind'},
				{value: true, label:'Yes, re-deal!'}
			];
			cdVO.escape_value = false;
			cdVO.callback = onConfirm;
			
			is_built = true;
		}
		
		public function get enabled():Boolean { return _enabled; }
		public function set enabled(value:Boolean):void {
			if(!is_built) buildBase();
			_enabled = value;
			
			//set the cost
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			if(pc && pc.stats){				
				redeal_tf.alpha = value ? 1 : DISABLED_ALPHA;
				
				//set the confirm text
				//this will be replaced with the proper dialog later
				cdVO.txt = 'Are you sure you want to re-deal?';
				
				//did they redeal?
				per_day_tf.htmlText = '<p class="imagination_redeal_per_day">'+
									  (!pc.stats.imagination_shuffled_today ? 'You can re-deal once a day' : 'You\'ve already re-dealt today')+
									  '</p>';
				per_day_tf.alpha = value ? 1 : DISABLED_ALPHA;
				
				//which icon do we show?
				redeal_icon.visible = !pc.stats.imagination_shuffled_today;
				redeal_icon.alpha = value ? 1 : DISABLED_ALPHA;
				no_redeal_icon.visible = pc.stats.imagination_shuffled_today;
				
				bg.x = int(per_day_tf.width/2 - BG_W/2);
			}
		}
		
		private function onClick(event:MouseEvent):void {
			//let whoever know that we clicked this
			SoundMaster.instance.playSound(enabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(enabled) {
				TSFrontController.instance.confirm(cdVO);
				enabled = false;
			}
		}
		
		private function onConfirm(value:Boolean):void {
			//if yes, go ahead and dispatch the change
			if(value){
				dispatchEvent(new TSEvent(TSEvent.CHANGED));
			}
			else {
				enabled = true;
			}
		}
	}
}