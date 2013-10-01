package com.tinyspeck.engine.view.gameoverlay
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.util.TFUtil;
	
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.utils.getTimer;

	public class TimerBar extends Sprite
	{
		private const HEIGHT:int = 21;
		private const BAR_MARGIN:int = 2;
		
		private const BAR_COLOR:uint = 0xc5db88;
		private const FADE_TIME:Number = .2;
		
		private var _width:int = 125; //just a default width
		
		private var _totalTime:int;
		private var _totalTicks:int;
		
		private var _labelString:String;
		private var _label:TextField;
		
		private var _bar:Shape;
		private var _barWidth:int = _width-(BAR_MARGIN*2);
		
		private var _startTime:int;
		private var _currentTime:int;
		private var _tickTime:int;
		
		private var _started:Boolean = false;
		private var manual:Boolean = false;
		private var _bg_alpha:Number = .8;
		public var show_perc_in_label:Boolean = false;
				
		public function TimerBar(){
			alpha = 1;
			_createBar();
		}
	
		public function start(totalMS:int, label:String = "", ticks:int = 1, manual:Boolean = false):void {
			//make sure we haven't started already
			if(_started) {
				CONFIG::debugging {
					Console.error("This timer bar has started already. Use end() first before trying to start it again.");
				}
				return;
			}
			
			this.manual = manual;
			
			//looks like we are ready to rock
			_totalTime = totalMS;
			_totalTicks = ticks;
			_labelString = label;
			
			//create the elements
			_createBackground();
			if(_label == null) _createLabel(_labelString);
			
			if(TSTweener.isTweening(this)) TSTweener.removeTweens(this);
			
			TSTweener.addTween(this, {alpha:1, time:FADE_TIME});
			
			//make sure the bar gets reset to where it's supposed to go
			_bar.x = BAR_MARGIN;
			_updateBar();
			
			if (!manual) {
				//see how long a tick is
				_tickTime = _totalTime / _totalTicks;
				
				TSTweener.addTween(_bar, {x:100 + BAR_MARGIN, time:_totalTime/1000, transition:"linear", 
					onStart:_onStart, onUpdate:_updateBar, onComplete:end});
			} else {
				_started = true;
			}
		}
		
		/**
		 * Ends the timer bar. Can be called before it's finished and it will clean itself up 
		 */		
		public function end(fade:Boolean = true):void {
			if (!_started) return;

			//hold the phone and kill everything
			if(TSTweener.isTweening(_bar)) TSTweener.removeTweens(_bar);
			
			if(fade) TSTweener.addTween(this, {alpha:0, time:FADE_TIME});
			
			_started = false;
		}
		
		/**
		 * Gets the current label in plain text 
		 * @return String of the current label
		 */		
		public function get label():String {
			return _label.text;
		}
		
		/**
		 * Set the current label 
		 * @param text:String
		 */		
		public function set label(text:String):void {
			if(_label == null){
				//no label?! GASP, let's make one!
				_createLabel(text);
				return;
			}
			_label.htmlText = '<p class="timer_bar">'+text+'</p>';
		}
		
		/**
		 * How many ticks will this timer have before it's finished
		 * eg. 10 second timer may have 5 ticks (each tick is 2 seconds) 
		 * @param count:int
		 */		
		public function set ticks(count:int):void {
			_totalTicks = count;
		}
		
		public function manualUpdate(perc:Number, fade_out_when_full:Boolean = true):void {
			if (!_started) return;
			_bar.x = (100 + BAR_MARGIN)*perc
			_updateBar();
			if (perc == 1) end(fade_out_when_full);
		}
		
		override public function set width(value:Number):void {
			//redraw the bar
			_barWidth = value - BAR_MARGIN*2;
			
			const current_perc:Number = _bar.width / (_width - BAR_MARGIN*2);

			var g:Graphics = _bar.graphics;
			g.clear();
			g.beginFill(BAR_COLOR);
			g.drawRoundRect(0, 0, _barWidth * current_perc, HEIGHT-(BAR_MARGIN*2), 8);
			g.endFill();
			
			//redraw the background
			_width = value;
			_createBackground();
		}
		
		override public function get width():Number {
			return _width;
		}
		
		public function set bg_alpha(value:Number):void {
			_bg_alpha = value
			_createBackground();
		}
		
		private function _createBackground():void {
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0xffffff, _bg_alpha);
			g.drawRoundRect(0, 0, _width, HEIGHT, 8);
			g.endFill();
		}
		
		private function _createLabel(text:String):void {
			//this will create a default looking timerbar
			_label = new TextField();
			TFUtil.prepTF(_label, false);
			
			label = text;
			
			_label.height = _label.textHeight+4;
			_label.y = Math.round((HEIGHT-_label.height)/2);
			_label.x = 4;
			addChild(_label);
		}
		
		private function _createBar():void {
			//this will make the moving progress bar
			_bar = new Shape();
			_bar.y = BAR_MARGIN;
			_bar.x = BAR_MARGIN;
			addChild(_bar);
		}
		
		private function _updateBar():void {
			var percent:int = Math.min(100, Math.max(0, _bar.x - BAR_MARGIN));
			var barWidth:int = _barWidth * (percent/100);
			var g:Graphics = _bar.graphics;
			g.clear();
			g.beginFill(BAR_COLOR);
			g.drawRoundRect(0, 0, barWidth, HEIGHT-(BAR_MARGIN*2), 8);
			g.endFill();
			
			//make sure the bar gets reset to where it's supposed to go
			_bar.x = BAR_MARGIN;
			
			if (_totalTicks == 0){ // this is the case when mtrying a recipe
				if (show_perc_in_label && percent) {
					label = _labelString+' '+percent+'%';
				} else {
					label = _labelString;
				}
			} else if (_totalTicks > 1){
				_calculateTick();
			} else {
				//we must only be making 1, no need to calculate anything
				label = _labelString + " 1 of 1";
			}
		}
		
		private function _calculateTick():void {
			if (manual) return;
			_currentTime = getTimer();
			var elapsedTime:int = _currentTime - _startTime;
			var currentTick:int = elapsedTime / _tickTime + 1;
			
			if(currentTick <= _totalTicks){
				label = _labelString + " " + currentTick + " of " + _totalTicks;
			}else{
				//the very last split second of the tween will show the current as 1 higher
				//since the count doesn't start at 0
				label = "";
			}
		}
		
		private function _onStart():void {
			_started = true;
			_startTime = getTimer();
		}
	}
}