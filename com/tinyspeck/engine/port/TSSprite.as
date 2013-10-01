package com.tinyspeck.engine.port {
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.view.AbstractTSView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	public class TSSprite extends AbstractTSView {
		protected var _animateXY_duration:Number = .2;
		protected var _w:int;
		protected var _h:int;
		protected var _glowing:Boolean = false;
		protected var hit_target_alpha:Number = 0;
		protected var no_animate_xy:Boolean;
		
		private var _tsid:String;
			
		public function TSSprite(tsid:String = null):void {
			super();
			//cacheAsBitmap = true;
			this._tsid = tsid;
			name = tsid || name;
			addEventListener(Event.ADDED_TO_STAGE, _addedToStageHandler, false, 0, true);
			no_animate_xy = EnvironmentUtil.getUrlArgValue('SWF_no_animate_xy') == '1';
			hit_target_alpha = parseFloat(EnvironmentUtil.getUrlArgValue('SWF_hit_target_alpha')) || 0;
		}
		
		protected function _construct():void {
			
		}
		
		protected function _deconstruct():void {
			//_animateXY_tween = null;
			var removeChildren:Function = function(obj:*):void {
				for (var i:int=obj.numChildren-1; i>-1; i--) {
					var child:* = obj.getChildAt(i);
					if (child.hasOwnProperty('destroy')) {
						child.destroy();
					} else if (child.hasOwnProperty('numChildren')) {
						try {
							removeChildren(child);
						} catch(err:Error) {}
					}
					obj.removeChild(child);
				}
				
			}
			removeEventListener(Event.COMPLETE, _addedToStageHandler);
			removeChildren(this);
		}
		
		protected function _addedToStageHandler(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, _addedToStageHandler);
			_draw();
		}
		
		public function glow():void {
			if (!_glowing) { 
				_glowing = true;
				interaction_target.filters = StaticFilters.tsSprite_GlowA;
			}
		}
		
		public function unglow(force:Boolean=false):void {
			if (_glowing) { 
				_glowing = false;
				interaction_target.filters = null;
			}
		}
		
		protected function _draw():void {
			
		}
		
		/*
		public function setXY(coords:Object):void {
			if (coords.x == x && coords.y == y) return;
			if (coords.x == x && (coords.y == null || coords.y == undefined)) return;
			if (coords.y == y && (coords.x == null || coords.x == undefined)) return;
			
			if (coords.x != null) x = coords.x;
			if (coords.y != null) y = coords.y;
		}*/
		
		public function get disambugate_sort_on():int {
			return 0;
		}
		
		public function get interaction_target():DisplayObject {
			return DisplayObject(this);
		}
		
		public function interactionTargetIsVisible():Boolean {
			return interaction_target.visible;
		}
		
		public function get interactionBounds():Rectangle {
			return interaction_target.getBounds(this);
		}
		
		public function get hit_target():DisplayObject {
			return interaction_target;
		}
		
		public function testHitTargetAgainstNativeDO(nativeDO:DisplayObject):Boolean {
			return hit_target.hitTestObject(nativeDO);
		}
		
		public function get h():int {
			return height;
		}
		
		public function get w():int {
			return width;
		}
		
		public function get r():Number {
			return rotation;
		}
		
		public function get x_rnd():Number {
			return x;
		}
		
		public function get y_rnd():Number {
			return y;
		}
		
		public function set x_rnd(xn:Number):void {
			x = Math.round(xn);
		}
		
		public function set y_rnd(yn:Number):void {
			y = Math.round(yn);
		}
		
		public function get glowing():Boolean {
			return _glowing;
		}
		
		override public function dispose():void {
			
			super.dispose();
			_deconstruct();
		}

		public function get tsid():String { return _tsid; }
		public function set tsid(value:String):void { _tsid = value; }

	}
}