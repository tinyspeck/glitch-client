package com.tinyspeck.engine.view.renderer
{
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.control.engine.AnnouncementController;
	import com.tinyspeck.engine.data.location.Layer;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.port.StoreEmbed;
	import com.tinyspeck.engine.port.TSSprite;
	import com.tinyspeck.engine.util.DrawUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.itemstack.AbstractItemstackView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	
	import org.osflash.signals.Signal;
	
	public class LocationView {
		
		private const _clicked:Signal = new Signal(DisplayObject);
		private const _mouseDown_sig:Signal = new Signal(AbstractItemstackView);
		private const _mouseOver_sig:Signal = new Signal(AbstractItemstackView);
		private const _layerRenderers:Vector.<LayerRenderer> = new Vector.<LayerRenderer>();
		
		private var model:TSModelLocator;
		private var flashVarModel:FlashVarModel;
		private var worldModel:WorldModel;
		
		/** @private */
		internal var _middleGroundRenderer:MiddleGroundRenderer;
		
		public function LocationView() {
			model = TSModelLocator.instance;
			flashVarModel = model.flashVarModel;
			worldModel = model.worldModel;
		}	
				
		public function dispose():void {
			middleGroundRenderer = null;
			_clicked.removeAll();
			
			if (StoreEmbed.instance.parent){
				StoreEmbed.instance.end();
			}
			
			// one hopes this does not fuck everthing up!
			AnnouncementController.instance.cancelAllOverlaysWeCan();
			
			var lr:LayerRenderer;
			for(var i:int = 0; i < _layerRenderers.length; i++){
				lr = LayerRenderer(_layerRenderers[int(i)]);
				lr.dispose();
				lr.parent.removeChild(lr);
			}
			_layerRenderers.length = 0;
		}
		
		CONFIG::locodeco public function updateFilters(disableHighlighting:Boolean = false):void {
			for each(var lr:LayerRenderer in _layerRenderers) {
				lr.updateFilters(disableHighlighting);
			}
		}
		
		public function get layerRenderers():Vector.<LayerRenderer> { return _layerRenderers; }
		public function set middleGroundRenderer(value:MiddleGroundRenderer):void {
			
			if (_middleGroundRenderer) {
				_middleGroundRenderer.removeEventListener(MouseEvent.CLICK, onMouseClicked);
			}
			
			_middleGroundRenderer = MiddleGroundRenderer(value);
			
			if (_middleGroundRenderer) {
				_middleGroundRenderer.doubleClickEnabled = true;
				_middleGroundRenderer.addEventListener(MouseEvent.CLICK, onMouseClicked);
			}
		}
		
		private function onMouseClicked(e:MouseEvent):void {
			var targetDO:DisplayObject = SpriteUtil.findParentByClass((e.target as DisplayObject), TSSprite) as TSSprite;
			var lis_view:LocationItemstackView;
			
			// if this click is on a lis_view use the smart alpha testing routine to get the most likely one 
			if (targetDO is LocationItemstackView) {
				lis_view = TSFrontController.instance.getMainView().gameRenderer.getMostLikelyItemstackUnderCursor();
			}
			
			if (lis_view) {
				_clicked.dispatch(lis_view as DisplayObject);
			} else {
				// above did not find a lis_view, so let's proceed as normal
				_clicked.dispatch(targetDO);
			}
		}
		
		public function get middleGroundRenderer():MiddleGroundRenderer { return _middleGroundRenderer; }
		
		public function fastUpdateGradient():void {
			if (flashVarModel.no_render_decos) return;
			const alr:LayerRenderer = LayerRenderer(_layerRenderers[0]);
			const layer:Layer = alr.layerData;
			DrawUtil.drawBGForLoc(worldModel.location, alr.graphics, layer.w, layer.h);
		}
		
		public function getLayerRendererByTsid(tsid:String):LayerRenderer {
			for each (var layerRenderer:LayerRenderer in _layerRenderers) {
				if (tsid == layerRenderer.tsid) return layerRenderer;
			}
			return null;
		}

		public function get clicked():Signal { return _clicked; }
		public function get mouseDown_sig():Signal { return _mouseDown_sig; }
		public function get mouseOver_sig():Signal { return _mouseOver_sig; }
	}
}