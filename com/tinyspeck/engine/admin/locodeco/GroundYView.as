package com.tinyspeck.engine.admin.locodeco {
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import locodeco.LocoDecoGlobals;
	import locodeco.models.LocationModel;
	
	public class GroundYView extends Sprite {
		/* singleton boilerplate */
		public static const instance:GroundYView = new GroundYView();
		
		private var _location:LocationModel;
		private var _layoutModel:LayoutModel;
		private var _gameRenderer:LocationRenderer;
		
		public function GroundYView() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_location = LocoDecoGlobals.instance.location;
			_layoutModel = TSModelLocator.instance.layoutModel;
			_gameRenderer = TSFrontController.instance.getMainView().gameRenderer;
			
			visible = false;
			useHandCursor = true;
			buttonMode = true;
			addEventListener(MouseEvent.MOUSE_MOVE, refresh);
			addEventListener(MouseEvent.CLICK, click);
		}
		
		public function click(event:MouseEvent):void {
			_location.groundY = _gameRenderer.getMouseYinMiddleground();
		}
		
		public function refresh(event:MouseEvent = null):void {
			// draw the background
			graphics.clear();
			graphics.beginFill(0, 0.3);
			graphics.drawRect(0, 0, _layoutModel.loc_vp_w, _layoutModel.loc_vp_h);
			graphics.endFill();
			
			if (visible) {
				// draw the current ground-y
				const gY:int = globalToLocal(_gameRenderer.localToGlobal(new Point(0, _location.groundY))).y;
				graphics.lineStyle(2, 0x00FF00);
				graphics.moveTo(0, gY);
				graphics.lineTo(_layoutModel.loc_vp_w, gY);
				
				if (event) {
					// draw the proposed ground-y
					graphics.lineStyle(2, 0xFF0000, 0.5);
					graphics.moveTo(0, event.localY);
					graphics.lineTo(_layoutModel.loc_vp_w, event.localY);
				}
			}
		}
	}
}