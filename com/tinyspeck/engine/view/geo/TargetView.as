package com.tinyspeck.engine.view.geo
{
	import com.tinyspeck.engine.data.location.AbstractPositionableLocationEntity;
	import com.tinyspeck.engine.data.location.Target;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.view.renderer.IAbstractDecoRenderer;
	
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	
	CONFIG const RADIUS:Number = 10;
	CONFIG const CENTER_X:Number = 0;
	CONFIG const CENTER_Y:Number = -10;
	CONFIG const THICKNESS:Number = 2;
	
	public class TargetView extends TSSpriteWithModel implements IAbstractDecoRenderer
	{
		private var target:Target;
		
		public function TargetView(target:Target) {
			super(target.tsid);
			this.target = target;
			blendMode = BlendMode.INVERT;
			syncRendererWithModel();
		}
		
		/** from IDecoRendererContainer */
		CONFIG::locodeco private var _highlight:Boolean;
		CONFIG::locodeco public function get highlight():Boolean { return _highlight; }
		CONFIG::locodeco public function set highlight(value:Boolean):void { _highlight = value; }
		
		/** from IDecoRendererContainer */
		public function syncRendererWithModel():void {
			x = target.x;
			y = target.y;
			draw();
		}
		
		/** from IDecoRendererContainer */
		public function getModel():AbstractPositionableLocationEntity {
			return target;
		}
		
		/** from IDecoRendererContainer */
		public function getRenderer():DisplayObject {
			return this;
		}
		
		private function draw():void {
			const g:Graphics = graphics;
			
			g.clear();
			
			// make it easily clickable with a fill
			g.beginFill(0, 0);
			g.lineStyle(CONFIG::THICKNESS);
			
			// draw circle
			g.drawCircle(CONFIG::CENTER_X, CONFIG::CENTER_Y, CONFIG::RADIUS);
			
			// draw cross
			g.moveTo(CONFIG::CENTER_X, 0);
			g.lineTo(CONFIG::CENTER_X, -2*CONFIG::RADIUS);
			g.moveTo(-CONFIG::RADIUS, CONFIG::CENTER_Y);
			g.lineTo(CONFIG::RADIUS, CONFIG::CENTER_Y);
		}
	}
}
