package com.tinyspeck.engine.view.ui.chrome
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.ImgMenuView;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class ImaginationButton extends Sprite
	{
		private static const COUNT_PADD:uint = 3;
		private static const QUEST_PADD:uint = 5;
		
		private var bt:Button;
		private var clouds:DisplayObject;
		private var bt_DO:DisplayObject;
		
		private var count_bg_holder:Sprite = new Sprite();
		private var count_bg_mask:Sprite = new Sprite();
		private var count_holder:Sprite = new Sprite();
		private var quest_mask:Sprite = new Sprite();
		
		private var count_tf:TextField = new TextField();
		private var quest_tf:TextField = new TextField();
		
		private var count_color:uint = 0xb21f00;
		private var quest_count:uint;
		
		private var has_loaded:Boolean;
		
		public function ImaginationButton(){
			bt_DO = new AssetManager.instance.assets.imagination_button();
			
			clouds = new AssetManager.instance.assets.imagination_button_clouds();
			clouds.y = bt_DO.height - clouds.height + 2;
			addChild(clouds);
			
			bt = new Button({
				name: 'bt',
				draw_alpha: 0,
				graphic: bt_DO,
				graphic_hover: new AssetManager.instance.assets.imagination_button_hover(),
				graphic_disabled: new AssetManager.instance.assets.imagination_button_down(),
				use_hand_cursor_always: true,
				w: bt_DO.width,
				h: bt_DO.height
			});
			bt.x = clouds.width + 4;
			bt.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
			addChild(bt);
			
			//handle the counter
			count_color = CSSManager.instance.getUintColorValueFromStyle('imagination_button', 'backgroundColor', count_color);
			TFUtil.prepTF(count_tf, false);
			count_tf.y = -1;
			//count_tf.border = true;
			count_holder.addChild(count_tf);
			count_holder.y = 1;
			bt.addChild(count_holder);
			count_bg_holder.mask = count_bg_mask;
			count_holder.addChild(count_bg_holder);
			count_bg_mask.rotation = 25;
			count_holder.addChild(count_bg_mask);
			
			//quest added
			TFUtil.prepTF(quest_tf, false);
			quest_tf.htmlText = '<p class="imagination_button_quest">New Quest Added!</p>';
			quest_tf.y = int(bt_DO.height/2 - quest_tf.height/2 + 2);
			quest_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			quest_tf.mask = quest_mask;
			addChild(quest_tf);
			
			var g:Graphics = quest_mask.graphics;
			g.beginFill(0);
			g.drawRect(0, 0, 1, int(quest_tf.height + QUEST_PADD*2));
			quest_mask.y = quest_tf.y - QUEST_PADD;
			addChild(quest_mask);
			
			//listen for when it's opened/closed
			ImgMenuView.instance.addEventListener(TSEvent.STARTED, onMenuChange, false, 0, true);
			ImgMenuView.instance.addEventListener(TSEvent.CLOSE, onMenuChange, false, 0, true);
		}
		
		public function updateCount(value:Number):void {
			if(!bt_DO){
				StageBeacon.setTimeout(updateCount, 100, value);
				return;
			}
			
			count_holder.visible = value > 0 && !bt.disabled;
			
			if(value > 0){
				drawCount(quest_count);
				quest_tf.x = int(width + 12);
				quest_mask.x = quest_tf.x - QUEST_PADD;
			}
			
			if(value > quest_count){
				//animate the change
				if(has_loaded){
					if(value == 1){
						//we want to tween this from nothing
						count_holder.scaleX = count_holder.scaleY = .01;
					}
					TSTweener.addTween(count_holder, {scaleX:1.5, scaleY:1.5, time:.3, onComplete:onZoomComplete});
					
					//play the sound and show the notice
					TSTweener.addTween(quest_mask, {
						width:int(quest_tf.width + QUEST_PADD*2), 
						time:.5, 
						delay:.3, 
						onStart:SoundMaster.instance.playSound, 
						onStartParams:['QUEST_ADDED']
					});
					TSTweener.addTween(quest_mask, {width:1, time:.5, delay:3.3, onComplete:onTweenComplete});
					
					YouDisplayManager.instance.hideImaginationAmount(true);
				}
			}
			
			quest_count = value;
			if(parent) has_loaded = true;
		}
		
		private function drawCount(value:int, reset_mask:Boolean = true):void {
			count_tf.htmlText = '<p class="imagination_button">'+value+'</p>';
			
			const draw_w:Number = count_tf.width + COUNT_PADD*2 + .5;
			const draw_h:int = int(count_tf.height);
			var g:Graphics = count_holder.graphics;
			g.clear();
			g.beginFill(count_color);
			g.drawRoundRect(0, 0, draw_w, draw_h, draw_h);
			
			count_holder.x = bt_DO.width - draw_w + 3;
			
			g = count_bg_holder.graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRoundRect(0, 0, draw_w, draw_h, draw_h);
			
			//mask
			const mask_padd:uint = 8;
			g = count_bg_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRect(-mask_padd, -mask_padd, draw_w, draw_h+mask_padd*2);
			
			if(reset_mask) count_bg_mask.x = draw_w + mask_padd*2;
			
			//flash TFs are some whisky dick shit
			count_tf.x = COUNT_PADD;
			if(value >= 10 && value < 20){
				count_tf.x -= 1;
			}
		}
		
		private function onZoomComplete():void {
			//it's zoomed up, animate the swipe
			const ani_time:Number = .7;
			TSTweener.addTween(count_bg_mask, {x:count_bg_mask.width/2, time:ani_time/2, transition:'linear', onComplete:onSwipeComplete});
			TSTweener.addTween(count_bg_mask, {x:-count_bg_mask.width/2, time:ani_time/2, delay:ani_time/2, transition:'linear'});
			
			TSTweener.addTween(count_holder, {scaleX:1, scaleY:1, time:.3, delay:ani_time+1});
		}
		
		private function onSwipeComplete():void {
			//set the count to the proper amount
			drawCount(quest_count, false);
		}
		
		private function onButtonClick(event:TSEvent):void {
			//if not disabled, open the menu
			if(!bt.disabled && ImgMenuView.instance.show()){
				bt.disabled = true;
			}
			else if(bt.disabled){
				ImgMenuView.instance.hide();
			}
		}
		
		private function onMenuChange(event:TSEvent):void {
			//menu was opened/closed
			bt.disabled = event.type == TSEvent.STARTED;
			count_holder.visible = !bt.disabled && quest_count > 0;
		}
		
		private function onTweenComplete():void {
			YouDisplayManager.instance.hideImaginationAmount(false);
		}	
		
		public function get disabled():Boolean {
			if(bt) return bt.disabled;
			return true;
		}
		
		override public function get width():Number {
			if(!bt) return 0;
			return bt.x + (count_bg_holder.width ? count_holder.x + count_bg_holder.width : bt.width);
		}
	}
}