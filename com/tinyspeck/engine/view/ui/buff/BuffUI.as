package com.tinyspeck.engine.view.ui.buff
{
	import com.tinyspeck.engine.data.pc.PCBuff;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.DrawUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.Timer;

	public class BuffUI extends Sprite implements ITipProvider
	{
		public static const RADIUS:Number = 13;
		
		private static const BAR_THICKNESS:Number = 3.5;
		private static const ANIMATION_TIME:Number = .3;
		private static const DIM_ALPHA:Number = .6;
		private static const DELAY_BEFORE_SHOW:Number = 1;
		
		private static var bg_color:uint;
		private static var bg_alpha:Number;
		private static var fill_color:uint;
		private static var fill_alpha:Number;
		private static var fill_color_debuff:uint;
		private static var fill_alpha_debuff:Number;
		
		private var name_tf:TextField = new TextField();
		
		private var name_holder:Sprite = new Sprite();
		private var name_mask:Sprite = new Sprite();
		private var icon_holder:Sprite = new Sprite();
		private var bar_bg:Sprite = new Sprite();
		private var bar_juice:Sprite = new Sprite();
		
		private var debuff_icon:DisplayObject;
		private var item_icon:ItemIconView;
		private var tick_timer:Timer = new Timer(1000);
		
		private var tip_pt:Point = new Point();
		private var bar_pt:Point = new Point();
		
		private var current_buff:PCBuff;
		
		private var is_built:Boolean;
		private var is_hiding:Boolean;
		
		public function BuffUI(){}
		
		private function buildBase():void {
			if(isNaN(bg_alpha)){
				const cssm:CSSManager = CSSManager.instance;
				bg_color = cssm.getUintColorValueFromStyle('buff', 'backgroundColor', 0);
				bg_alpha = cssm.getNumberValueFromStyle('buff', 'backgroundAlpha', .4);
				fill_color = cssm.getUintColorValueFromStyle('buff', 'fillColor', 0xffffff);
				fill_alpha = cssm.getNumberValueFromStyle('buff', 'fillAlpha', 1);
				fill_color_debuff = cssm.getUintColorValueFromStyle('buff_debuff', 'fillColor', 0xb73d40);
				fill_alpha_debuff = cssm.getNumberValueFromStyle('buff_debuff', 'fillAlpha', 1);
			}
			
			//name
			TFUtil.prepTF(name_tf, false);
			name_tf.x = 4;
			name_holder.addChild(name_tf);
			name_holder.x = RADIUS + 4;
			name_holder.mask = name_mask;
			name_holder.mouseChildren = false;
			name_holder.addEventListener(MouseEvent.ROLL_OVER, onBarMouse, false, 0, true);
			name_holder.addEventListener(MouseEvent.ROLL_OUT, onBarMouse, false, 0, true);
			addChild(name_holder);
			addChild(name_mask);
			
			//bar
			bar_bg.addChild(icon_holder);
			bar_bg.mouseChildren = false;
			bar_bg.addEventListener(MouseEvent.ROLL_OVER, onBarMouse, false, 0, true);
			bar_bg.addEventListener(MouseEvent.ROLL_OUT, onBarMouse, false, 0, true);
			bar_bg.addChild(bar_juice);
			addChild(bar_bg);
			
			//timer
			tick_timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
			
			is_built = true;
		}
		
		public function show(buff:PCBuff):void {
			if(!is_built) buildBase();
			current_buff = buff;
			name = buff.tsid;
			
			//reset
			is_hiding = false;
			tick_timer.reset();
			
			//set the icon
			setIcon();
			
			//set the name
			setName();
			
			if(current_buff.is_timer && current_buff.remaining_duration > 0){
				//start the timer and call the first draw
				tick_timer.start();
				onTimerTick();
			}
			else {
				//just draw it straight away
				draw();
			}
			
			//tween it in pretty
			bar_bg.scaleX = bar_bg.scaleY = .01;
			bar_bg.alpha = 0;
			TSTweener.removeTweens(bar_bg);
			TSTweener.addTween(bar_bg, {scaleX:1, scaleY:1, alpha:1, time:ANIMATION_TIME, delay:DELAY_BEFORE_SHOW, onUpdate:onTweenUpdate});
			
			TipDisplayManager.instance.registerTipTrigger(!TSModelLocator.instance.flashVarModel.keep_buff_names ? bar_bg : this);
		}
		
		public function hide():void {
			//fade out and vanish
			TSTweener.removeTweens([bar_bg, name_mask]);
			TSTweener.addTween(bar_bg, {scaleX:.01, scaleY:.01, alpha:0, time:ANIMATION_TIME, onUpdate:onTweenUpdate, onComplete:onHideComplete});
			TSTweener.addTween(name_mask, {x:0, time:ANIMATION_TIME});
			
			TipDisplayManager.instance.unRegisterTipTrigger(!TSModelLocator.instance.flashVarModel.keep_buff_names ? bar_bg : this);
			is_hiding = true;
			tick_timer.stop();
		}
		
		public function refresh():void {
			//reset the tick timer to re-sync
			if(current_buff.is_timer && current_buff.remaining_duration > 0){
				tick_timer.reset();
				if(!tick_timer.running) tick_timer.start();
				onTimerTick();
			}
		}
		
		private function setIcon():void {
			SpriteUtil.clean(icon_holder);
			
			if(current_buff.item_class){
				item_icon = new ItemIconView(current_buff.item_class, RADIUS*2 - 4 - BAR_THICKNESS*2);
				icon_holder.addChild(item_icon);
			}
			else if(current_buff.is_debuff){
				//toss the debuff icon in there if we need to
				if(!debuff_icon) {
					debuff_icon = new AssetManager.instance.assets.buff_bang_white();
					debuff_icon.y = -1; //visual tweak
				}
				icon_holder.addChild(debuff_icon);
			}
			icon_holder.x = -icon_holder.width/2;
			icon_holder.y = -icon_holder.height/2;
		}
		
		private function setName():void {
			name_tf.htmlText = '<p class="buff">'+current_buff.name+'</p>';
			
			var g:Graphics = name_holder.graphics;
			g.clear();
			g.beginFill(bg_color, bg_alpha);
			g.drawRoundRect(0, 0, name_tf.width + name_tf.x*2, name_tf.height + 2, 6);
			name_holder.y = -int(name_holder.height/2);
			name_holder.alpha = 1;
			
			//set the mask up to animate
			g = name_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRect(0, 0, 1, name_holder.height);
			name_mask.width = 0;
			name_mask.x = -RADIUS;
			name_mask.y = name_holder.y;
			
			const keep_buff_names:Boolean = TSModelLocator.instance.flashVarModel.keep_buff_names;
			TSTweener.removeTweens(name_mask);
			TSTweener.addTween(name_mask, {x:name_holder.x, time:ANIMATION_TIME, delay:DELAY_BEFORE_SHOW});
			TSTweener.addTween(name_mask, {width:name_holder.width, time:ANIMATION_TIME, delay:DELAY_BEFORE_SHOW+ANIMATION_TIME, onUpdate:onTweenUpdate});
			TSTweener.addTween(name_mask, 
				{
					width:!keep_buff_names ? 1 : name_holder.width,
					time:ANIMATION_TIME, 
					delay:DELAY_BEFORE_SHOW+ANIMATION_TIME*2 + 4, 
					onUpdate:onTweenUpdate, 
					onComplete:onTweenComplete,
					onCompleteParams:[!keep_buff_names]
				}
			);
		}
		
		private function draw():void {
			const draw_color:uint = !current_buff.is_debuff ? fill_color : fill_color_debuff;
			const draw_alpha:Number = !current_buff.is_debuff ? fill_alpha : fill_alpha_debuff;
			
			bar_juice.visible = current_buff.is_timer && current_buff.remaining_duration > 0;
			
			var g:Graphics = bar_bg.graphics;
			g.clear();
			
			if(tick_timer.running){
				g.beginFill(bg_color, bg_alpha);
				DrawUtil.drawRing(g, RADIUS-BAR_THICKNESS, RADIUS);
				
				//draw a transparent circle for mouse stuff
				g.beginFill(0,0);
				g.drawCircle(0, 0, RADIUS-BAR_THICKNESS);
				
				//draw the ring
				const perc:Number = Math.max(0, current_buff.remaining_duration / current_buff.duration);
				
				g = bar_juice.graphics;
				g.clear();
				g.beginFill(draw_color, draw_alpha);
				DrawUtil.drawRing(g, RADIUS-BAR_THICKNESS, RADIUS, -90, perc);
			}
			else {
				//no timer, just fill the background like it's supposed to be
				g.beginFill(draw_color, draw_alpha);
				g.drawCircle(0, 0, RADIUS);
			}
		}
		
		private function onTweenUpdate():void {
			//this is the magic. We let anyone who is listening know we are changing
			dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
		}
		
		private function onTweenComplete(clear_mask:Boolean = true):void {
			//clears out the mask
			if(clear_mask){
				const g:Graphics = name_mask.graphics;
				g.clear();
			}
			else {
				//fade down the name a bit
				TSTweener.addTween(name_holder, {alpha:DIM_ALPHA, time:ANIMATION_TIME, transition:'linear'});
			}
			
			//fade it down to the alpha it's supposed to be at
			TSTweener.addTween(bar_bg, {alpha:DIM_ALPHA, time:ANIMATION_TIME, transition:'linear'});
			dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
		}
		
		private function onHideComplete():void {
			if(parent) parent.removeChild(this);
			onTweenUpdate();
			is_hiding = false;
		}
		
		private function onBarMouse(event:MouseEvent):void {
			if(is_hiding) return;
			
			const is_over:Boolean = event.type == MouseEvent.ROLL_OVER;
			
			TSTweener.removeTweens(bar_bg, name_holder);
			TSTweener.addTween([bar_bg, name_holder], {alpha:is_over? 1 : DIM_ALPHA, time:.2, transition:'linear'});
		}
		
		private function onTimerTick(event:TimerEvent = null):void {
			//decrease the buff's remaining duration by 1
			current_buff.remaining_duration -= 1;
			if(current_buff.remaining_duration <= 0){
				//stop the timer
				tick_timer.stop();
				current_buff.remaining_duration = 0;
			}
			draw();
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target) return null;
			
			var txt:String = '<p class="buff_name_tip">' + current_buff.name + '</p>';
			if(current_buff.desc && current_buff.desc != '') txt += '<p class="buff_description_tip">' + current_buff.desc + '</p>';
			if(current_buff.is_timer && current_buff.remaining_duration > 0) {
				txt += '<p class="buff_timer_tip">' +
					'(' + StringUtil.formatTime(current_buff.remaining_duration) + ' / ' + StringUtil.formatTime(current_buff.duration) + ')' +
					'</p>';
			}
			
			tip_pt = bar_bg.localToGlobal(bar_pt);
			tip_pt.y += RADIUS + 10;
			
			return {
				txt: txt,
				placement: tip_pt,
				pointer: WindowBorder.POINTER_TOP_CENTER
			};
		}
		
		override public function get width():Number {
			//because we are doing masking stuff, we need to send back the width that we see
			return RADIUS + (name_mask.width ? name_mask.x + name_mask.width : RADIUS);
		}
	}
}