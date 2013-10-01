package com.tinyspeck.engine.view.gameoverlay
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.BevelFilter;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class DismissableBar extends Sprite
	{
		private var bg_color:uint = 0xaab8bf;
		private var bar_bg_color:uint = 0x8f9ea5;
		private var bar_color:uint = 0x95bc09;
		private var pointy_size:int = 14;
		
		private var shadow:DropShadowFilter = new DropShadowFilter();
		private var glow:GlowFilter = new GlowFilter();
		private var bevel:BevelFilter = new BevelFilter();
		
		private var dismisser_bg:Sprite = new Sprite();
		private var dismisser_bar:Shape = new Shape();
		private var dismisser_bar_bg:Shape = new Shape();
		private var dismisser_bar_glow:Shape = new Shape();
		
		private var dismisser_w:int = 146;
		private var dismisser_h:int = 30;
		private var dismisser_bar_pad:int = 6;
		private var dismisser_bar_w:int;
		
		private var limit:int;
		private var current_round:int;
		private var animation_speed:Number;
		
		private var count_tf:TextField = new TextField();
		
		private var close_button:Sprite = new Sprite();
		private var dismiss_x:DisplayObject;
		
		private var cast_shadow:Boolean;
		private var _show_point:Boolean;
		private var _is_flipped:Boolean;
		
		private var _close_function:Function;
		private var _cycle_function:Function;
		
		/**
		 * Will spawn a dismissable bar. Setting the closeFunction parameter is REQUIRED for this to work. 
		 * @param showPointyBottom
		 * @param castShadowOnBar
		 */
		public function DismissableBar(show_point:Boolean = true, castShadowOnBar:Boolean = true){
			_show_point = show_point;
			cast_shadow = castShadowOnBar;
			_init();
		}
		
		private function _init():void {
			//get the colors etc from CSS
			var css:CSSManager = CSSManager.instance;
			bg_color = css.getUintColorValueFromStyle('dismissable_bar', 'backgroundColor', bg_color);
			bar_bg_color = css.getUintColorValueFromStyle('dismissable_bar', 'barBackgroundColor', bar_bg_color);
			bar_color = css.getUintColorValueFromStyle('dismissable_bar', 'barColor', bar_color);
			pointy_size = css.getNumberValueFromStyle('dismissable_bar', 'pointySize', pointy_size);
			
			//add the elements to the main sprite
			addChild(dismisser_bg);
			dismisser_bg.addChild(dismisser_bar_bg);
			dismisser_bg.addChild(dismisser_bar);
			dismisser_bg.addChild(dismisser_bar_glow);
			
			//build background
			buildBackground();
			dismisser_bg.filters = [bevel, shadow];
			
			//close button
			dismiss_x = new AssetManager.instance.assets.close_x_making_slot();
			close_button.addChild(dismiss_x);
			close_button.y = Math.round((dismisser_h-dismiss_x.height)/2);
			close_button.x = Math.round(dismisser_w - dismiss_x.width - dismisser_bar_pad) + 1; //icon asset is slightly off
			close_button.buttonMode = close_button.useHandCursor = true;
			dismisser_bg.addChild(close_button);
			
			dismisser_bar_w = close_button.x - dismisser_bar_pad*2;
			
			//build out the progress bar portion (true will cast a shadow on progress bar)
			buildProgress();
			
			//count tf
			count_tf.mouseEnabled = false;
			count_tf.autoSize = TextFieldAutoSize.LEFT;
			count_tf.styleSheet = CSSManager.instance.styleSheet;
			count_tf.antiAliasType = AntiAliasType.ADVANCED;
			count_tf.embedFonts = true;
			count_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			count_tf.htmlText = '<p class="dismissable_bar_count">1</p>';
			count_tf.x = dismisser_bar_pad + 3;
			count_tf.y = dismisser_bar_pad + int((dismisser_h-dismisser_bar_pad)/2 - count_tf.height/2) - 2;
			dismisser_bg.addChild(count_tf);
			
			close_button.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				// the timeout gets us out of weird problems that arise from dismiss removing the thing from the display list in a click action
				// (because other things are inspecting the click and walking the DO tree, like _tryActOnClickedElement)
				StageBeacon.waitForNextFrame(_close_function);
				StageBeacon.stage.focus = StageBeacon.stage;
			});
		}
		
		/**
		 * Starts the bar. 
		 * @param totalMS
		 * @param limit - how many times the bar should be able to go over and over
		 */		
		public function start(totalMS:int, limit:int = 1):void {
			if(_close_function == null){
				CONFIG::debugging {
					Console.error("No close function defined on DismissableBar. Set with .closeFunction");
				}
				return;
			}
			
			this.limit = limit;
			current_round = 1;
			animation_speed = (totalMS/1000)/limit;
			
			dismisser_bar.width = 0;
			TSTweener.removeTweens(dismisser_bar);
			
			if(limit > 1){
				nextRound();
			}
			else {
				count_tf.htmlText = '';
				TSTweener.addTween(dismisser_bar, {width:dismisser_bar_w, time:animation_speed, transition:'linear'});
			}
		}
		
		private function nextRound():void {
			if(current_round <= limit){
				dismisser_bar.width = 0;
				
				count_tf.htmlText = '<p class="dismissable_bar_count">'+current_round+'</p>';
				TSTweener.addTween(dismisser_bar, {width:dismisser_bar_w, time:animation_speed, transition:'linear', onComplete:nextRound});
				
				if(_cycle_function != null && current_round > 1) _cycle_function();
			}
			
			current_round++;
		}
		
		private function buildBackground():void {
			//main background
			var g:Graphics = dismisser_bg.graphics;
			g.clear();
			g.beginFill(bg_color);
			g.drawRoundRect(0, 0, dismisser_w, dismisser_h, 8);
			g.endFill();
			
			shadow.angle = 90;
			shadow.alpha = .5;
			shadow.color = 0x000000;
			shadow.distance = 2;
			shadow.blurX = 0;
			shadow.blurY = 0;
			
			bevel.blurX = 1;
			bevel.blurY = 1;
			bevel.angle = 90;
			bevel.distance = 1;
			bevel.highlightColor = 0xFFFFFF;
			bevel.highlightAlpha = .25;
			bevel.shadowAlpha = 0;
			
			if(_show_point){
				//small point above/below the bar
				g.beginFill(bg_color);
				if(!_is_flipped){
					g.moveTo(dismisser_w/2 - pointy_size/2, dismisser_h);
					g.lineTo(dismisser_w/2, dismisser_h + pointy_size/2);
					g.lineTo(dismisser_w/2 + pointy_size/2, dismisser_h);
					dismisser_bg.y = 0;
				}
				else {
					g.moveTo(dismisser_w/2 - pointy_size/2, 0);
					g.lineTo(dismisser_w/2, -pointy_size/2);
					g.lineTo(dismisser_w/2 + pointy_size/2, 0);
					dismisser_bg.y = pointy_size/2;
				}
				g.endFill();
			}
		}
		
		private function buildProgress():void {
			//position the bar elements
			dismisser_bar_bg.x = dismisser_bar_pad;
			dismisser_bar_bg.y = dismisser_bar_pad;
			
			dismisser_bar.x = dismisser_bar_pad;
			dismisser_bar.y = dismisser_bar_pad;
			
			dismisser_bar_glow.x = dismisser_bar_pad;
			dismisser_bar_glow.y = dismisser_bar_pad;
			
			//progress glow
			var g:Graphics = dismisser_bar_glow.graphics;
			g.beginFill(bar_bg_color);
			g.drawRoundRect(0, 0, dismisser_bar_w, dismisser_h-(dismisser_bar_pad*2), 4);
			g.endFill();
			
			glow.blurX = 2;
			glow.blurY = 2;
			glow.color = 0x666666;
			glow.knockout = true;
			
			dismisser_bar_glow.filters = [glow];
			
			//progress background
			g = dismisser_bar_bg.graphics;
			g.beginFill(bar_bg_color);
			g.drawRoundRect(0, 0, dismisser_bar_w, dismisser_h-(dismisser_bar_pad*2), 3);
			g.endFill();
			
			shadow.alpha = 1;
			shadow.distance = 2;
			shadow.angle = 90;
			shadow.blurX = 0;
			shadow.blurY = 0;
			shadow.color = 0x7d8990;
			shadow.inner = true;
			
			dismisser_bar_bg.filters = [shadow];
			
			//progress bar
			g = dismisser_bar.graphics;
			g.beginFill(bar_color);
			g.drawRect(0, 0, dismisser_bar_w, dismisser_h-(dismisser_bar_pad*2));
			g.endFill();
			
			//if the progress bar needs to have a shadow
			if(cast_shadow){
				shadow.alpha = .25;
				dismisser_bar.filters = [shadow];
			}
		}
		
		/**
		 * Required for dismissable bar to be able to dismiss itself in the event someone pressed the X 
		 * @param func
		 */		
		public function set closeFunction(func:Function):void { _close_function = func; }
		
		/**
		 * OPTIONAL: if the bar has a limit > 1 it will fire this if set
		 * @param func
		 */		
		public function set cycleFunction(func:Function):void { _cycle_function = func; }
		
		/**
		 * Useful when you want the point to show up on the top instead of the bottom
		 * @param value
		 */		
		public function set is_flipped(value:Boolean):void { 
			_is_flipped = value;
			buildBackground();
		}
		
		public function setDimentions(w:int, h:int):void {
			dismisser_w = w;
			dismisser_h = h;
			
			close_button.x = Math.round(dismisser_w - dismiss_x.width - dismisser_bar_pad) + 1; //icon asset is slightly off
			dismisser_bar_w = close_button.x - dismisser_bar_pad*2;
			
			buildBackground();
			buildProgress();
		}
	}
}