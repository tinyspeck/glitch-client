package com.tinyspeck.engine.view.ui
{
	import com.bit101.components.Slider;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	
	public class TSSlider extends Slider
	{
		public static const HORIZONTAL:String = Slider.HORIZONTAL;
		public static const VERTICAL:String = Slider.VERTICAL;
		
		private var _handle_color:uint = 0xffffff;
		private var _handle_outline_color:uint = 0x055c73;
		private var _handle_radius_modifier:Number = .8; //allows the handle to be larger than the track
		private var _back_color:uint = 0xdcdedf;
		private var _fill_level_color_from:uint = 0x95bc09;
		private var _fill_level_color_to:uint = 0x95bc09;
		private var _fill_level_alpha:Number = 1;
		
		private var bg_matrix:Matrix = new Matrix();
		
		protected var level:Sprite;
		protected var level_mask:Sprite;
		
		public function TSSlider(orientation:String=TSSlider.HORIZONTAL, parent:DisplayObjectContainer=null, xpos:Number=0, ypos:Number=0, defaultHandler:Function=null)
		{
			super(orientation, parent, xpos, ypos, defaultHandler);
			_back.buttonMode = true;
			_back.useHandCursor = true;
		}
		
		override protected function drawBack():void
		{
			_back.graphics.clear();
			_back.graphics.beginFill(_back_color);
			_back.graphics.drawRoundRect(0, 0, _width, _height, 6);
			_back.graphics.endFill();
			
			if(_backClick){
				_back.addEventListener(MouseEvent.MOUSE_DOWN, onBackClick);
			}else{
				_back.removeEventListener(MouseEvent.MOUSE_DOWN, onBackClick);
			}
		}
		
		
		override protected function drawHandle():void {
			_handle.graphics.clear();
			_handle.graphics.beginFill(_handle_color);
			
			if(_orientation == HORIZONTAL){
				_handle.graphics.drawCircle(_height/2, _height/2, _height/2+_handle_radius_modifier); //the .8 throws off flashes rounding and makes a pretty circle
			}else{
				_handle.graphics.drawCircle(_width/2, _width/2, _width/2+_handle_radius_modifier);
			}
			_handle.graphics.endFill();
			_handle.filters = [new GlowFilter(_handle_outline_color, 1, 1.5, 1.5, 4, 2), new DropShadowFilter(1, 90, 0, .3, 1, 1)];
			
			positionHandle();
			
			//draw the level color that flows below the handle
			drawLevel();
		}
		
		override protected function addChildren():void
		{
			super.addChildren();

			_back.filters = [getTrackDropShadow()];

			_handle.filters = [];
			
			//handle the level/juice stuff
			level = new Sprite();
			level.mouseEnabled = false;
			addChildAt(level, getChildIndex(_handle));
			
			level_mask = new Sprite();
			level.mask = level_mask;
			addChildAt(level_mask, getChildIndex(_handle));
		}
		
		override protected function onBackClick(event:MouseEvent):void {
			super.onBackClick(event);
			adjustLevel();
		}
		
		override protected function onDrag(event:MouseEvent):void {
			super.onDrag(event);
			adjustLevel();
		}
		
		override protected function onSlide(event:MouseEvent):void {
			super.onSlide(event);
			adjustLevel();
		}
		
		protected function drawLevel():void {
			//draw the level below the handle and mask it
			adjustLevel();
			level.filters = [getTrackDropShadow()];
			
			var g:Graphics = level_mask.graphics;
			g.clear();
			g.beginFill(0xffcc00);
			g.drawRoundRect(0, 0, _width, _height, 6);
		}
		
		private function adjustLevel():void {
			var g:Graphics = level.graphics;
			g.clear();
			if (_fill_level_color_from == _fill_level_color_to) {
				g.beginFill(_fill_level_color_from, _fill_level_alpha);
			} else {
				bg_matrix.createGradientBox(_width, _height, 0);
				g.beginGradientFill(GradientType.LINEAR, [_fill_level_color_from, _fill_level_color_to], [1,1], [0,255], bg_matrix);
			}
			if(_orientation == HORIZONTAL){
				g.drawRoundRect(0, 0, _handle.x + _handle.width/2, _height, 6);
			}else{
				g.drawRoundRect(_handle.x, _handle.y, _width, _height, 6);
			}
			g.endFill();
		}
		
		private function getTrackDropShadow():DropShadowFilter {
			return new DropShadowFilter(2, 45, 0, .15, 1, 1, 1, 1, true);
		}
		
		override public function set value(v:Number):void {
			super.value = v;
			adjustLevel();
		}
		
		//simple getters/setters for handling the colors from the default
		public function set handleRadiusModifier(radius:Number):void { _handle_radius_modifier = radius; }
		public function get handleRadiusModifier():Number { return _handle_radius_modifier; }
		
		public function set handleColor(color:uint):void { _handle_color = color; }
		public function get handleColor():uint { return _handle_color; }
		
		public function set handleOutlineColor(color:uint):void { _handle_outline_color = color; }
		public function get handleOutlineColor():uint { return _handle_outline_color; }
		
		public function set backColor(color:uint):void { _back_color = color; }
		public function get backColor():uint { return _back_color; }
		
		public function set fillLevelColorFrom(color:uint):void { _fill_level_color_from = color; }
		public function get fillLevelColorFrom():uint { return _fill_level_color_from; }
		
		public function set fillLevelColorTo(color:uint):void { _fill_level_color_to = color; }
		public function get fillLevelColorTo():uint { return _fill_level_color_to; }
		
		public function set fillLevelAlpha(value:Number):void { _fill_level_alpha = value; }
		public function get fillLevelAlpha():Number { return _fill_level_alpha; }
	}
}