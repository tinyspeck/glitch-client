package com.tinyspeck.engine.admin.locodeco {
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.renderer.DecoAssetManager;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	internal class DecoHolder extends Sprite implements ITipProvider {
		private var _mc:MovieClip;
		private var _className:String;
		private var _w:int;
		private var _h:int;
		private var _tip:Object;
		
		public function DecoHolder() {
			buttonMode = true;
			useHandCursor = true;
		}
		
		public static function reset(dh:DecoHolder):void {
			dh.hide();
			while (dh.numChildren) dh.removeChildAt(0);
			dh._mc = null;
		}
		
		public function show():void {
			addEventListener(MouseEvent.ROLL_OVER, decoRollOver);
			addEventListener(MouseEvent.ROLL_OUT, decoRollOut);
			addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
			addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			
			TipDisplayManager.instance.registerTipTrigger(this);
			
			visible = true;
		}
		
		public function hide():void {
			removeEventListener(MouseEvent.ROLL_OVER, decoRollOver);
			removeEventListener(MouseEvent.ROLL_OUT, decoRollOut);
			removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
			removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			
			TipDisplayManager.instance.unRegisterTipTrigger(this);
			
			visible = false;
		}
		
		public function init(mc:MovieClip, className:String, w:int, h:int):void {
			while (numChildren) removeChildAt(0);
			
			_className = className;
			_tip = { txt: (className + ' (' + DecoAssetManager.getAssetSWFName(className)) + ')' };
			_mc = mc;
			_mc.enabled = false;
			addChild(_mc);
			
			_w = w;
			_h = h;
			
			// give us something to mouse over and center MC in dominant dimension
			graphics.clear();
			graphics.beginFill(0, 0);
			graphics.lineStyle(0, 0xFFFFFF, 10/255, true);
			if (_w > _h) {
				graphics.drawRect(0, 0, _w, _w);
				_mc.y = (_w - _h)/2;
			} else {
				graphics.drawRect(0, 0, _h, _h);
				_mc.x = (_h - _w)/2;
			}
		}
		
		public function get w():int {
			return _w;
		}
		
		public function get h():int {
			return _h;
		}
	
		public function get className():String {
			return _className;
		}
	
		public function get mc():MovieClip {
			return _mc;
		}
		
		public function set sideLength(length:Number):void {
			width = length;
			height = length;
		}
		
		private function decoRollOver(e:Event):void {
			mc.filters = StaticFilters.ldSelection_GlowA;
		}
		
		private function decoRollOut(e:Event):void {
			mc.filters = null;
		}
		
		private function mouseDownHandler(e:MouseEvent):void {
			DecoSelectorDialog.instance.onDecoHolderMouseDown(this, e);
		}
		
		private function mouseUpHandler(e:MouseEvent):void {
			DecoSelectorDialog.instance.onDecoHolderMouseUp(this, e);
		}
		
		public function getTip(tip_target:DisplayObject=null):Object {
			return _tip;
		}
	}
}
