package com.tinyspeck.engine.view.geo
{
	import com.tinyspeck.engine.data.location.AbstractPositionableLocationEntity;
	import com.tinyspeck.engine.data.location.Box;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.view.renderer.IAbstractDecoRenderer;
	
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	
	public class BoxView extends TSSpriteWithModel implements IAbstractDecoRenderer {
		private const box_sp:Sprite = new Sprite();
		private var _box:Box;
		
		public function BoxView(box:Box):void {
			super(box.tsid);
			this._box = box;
			addChild(box_sp);
			blendMode = BlendMode.INVERT;
			syncRendererWithModel();
		}
		
		/** from IDecoRendererContainer */
		CONFIG::locodeco private var _highlight:Boolean;
		CONFIG::locodeco public function get highlight():Boolean { return _highlight; }
		CONFIG::locodeco public function set highlight(value:Boolean):void { _highlight = value; }
		
		/** from IDecoRendererContainer */
		public function syncRendererWithModel():void {
			x = _box.x;
			y = _box.y;
			
			box_sp.x = -(_box.w/2);
			box_sp.y = -_box.h;
			
			box_sp.graphics.clear();
			box_sp.graphics.beginFill(0x000000, 0.2);
			box_sp.graphics.drawRect(0, 0, _box.w, _box.h);
		}
		
		/** from IDecoRendererContainer */
		public function getModel():AbstractPositionableLocationEntity {
			return _box;
		}
		
		/** from IDecoRendererContainer */
		public function getRenderer():DisplayObject {
			return this;
		}
	}
}
