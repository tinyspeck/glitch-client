package com.tinyspeck.engine.view.renderer.commands {
	import com.tinyspeck.core.control.ICommand;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.location.MiddleGroundLayer;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.view.renderer.ILayerRenderer;
	import com.tinyspeck.engine.view.renderer.ILocationView;
	import com.tinyspeck.engine.view.renderer.MiddleGroundRenderer;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import starling.core.RenderSupport;
	import starling.core.Starling;
	
	public class DrawLocationViewToBMDCmd implements ICommand {
		
		private const MIN_CONTEXT_VIEW_DIM:uint = 32;
		private static const viewRect:Rectangle = new Rectangle();
		private const support:RenderSupport = new RenderSupport();
		
		private var targetBMD:BitmapData;
		private var contextSizeLimitBMD:BitmapData;
		private var canvasScale:Number;
		private var useIntermediateBMD:Boolean = false;
		
		private var locationView:ILocationView;
		private var fitToMiddleGround:Boolean;
		private var worldModel:WorldModel;

		
		public function DrawLocationViewToBMDCmd(targetBMD:BitmapData, locationView:ILocationView, fitToMiddleGround:Boolean = false) {
			this.targetBMD = targetBMD;
			this.locationView = locationView;
			this.fitToMiddleGround = fitToMiddleGround;
			
			worldModel = TSModelLocator.instance.worldModel;
		}
		
		public function execute():void {
			RenderSupport.clear();
			
			var prevX:Number = Starling.current.viewPort.x;
			var prevY:Number = Starling.current.viewPort.y;
			var prevWidth:Number= Starling.current.viewPort.width;
			var prevHeight:Number = Starling.current.viewPort.height;

			
			var canvas:BitmapData = setupContextCorrectCanvas();
			viewRect.setTo(0, 0, canvas.width, canvas.height);
			Starling.current.viewPort = viewRect;
			
			if (fitToMiddleGround ) {
				resizeLayersToMiddleGround()
				support.setOrthographicProjection(worldModel.location.mg.w, worldModel.location.mg.h);
			} else {
				support.setOrthographicProjection(Starling.current.stage.stageWidth, Starling.current.stage.stageHeight);
			}
			
			drawToBitmapData(canvas);
			resetLayerScales();
			
			// restore the viewport
			viewRect.setTo(prevX, prevY, prevWidth, prevHeight);
			Starling.current.viewPort = viewRect;
		}
		
		/** If the target BMD's dimensions are smaller than 32, we need to draw to a larger intermediate */
		private function setupContextCorrectCanvas():BitmapData {
 
			if (targetBMD.width < MIN_CONTEXT_VIEW_DIM || targetBMD.height < MIN_CONTEXT_VIEW_DIM) {
				canvasScale = (targetBMD.width < targetBMD.height) ? MIN_CONTEXT_VIEW_DIM / targetBMD.width : MIN_CONTEXT_VIEW_DIM / targetBMD.height;
				useIntermediateBMD = true;
				return new BitmapData(targetBMD.width * canvasScale, targetBMD.height * canvasScale, true, 0);
			} 
			
			useIntermediateBMD = false;
			return targetBMD;
		}
		
		private function drawToBitmapData(canvas:BitmapData):void {
			Starling.current.stage.render(support, 1.0);
			support.finishQuadBatch();
			
			Starling.context.drawToBitmapData(canvas);
			
			// use intermediate bimtap if necessary
			if (useIntermediateBMD) {
				var canvasBitmap:Bitmap = new Bitmap(canvas);
				var scaleMat:Matrix = new Matrix();
				scaleMat.scale(1/canvasScale, 1/canvasScale);
				targetBMD.draw(canvasBitmap, scaleMat);
				useIntermediateBMD = false;
				canvas.dispose();
			}
		}
		
		private function resizeLayersToMiddleGround():void {
			var mg:MiddleGroundLayer = worldModel.location.mg;
			var location:Location = worldModel.location;
			
			for each (var layerRenderer:ILayerRenderer in locationView.layerRenderers) {
				if (layerRenderer is MiddleGroundRenderer) {
					layerRenderer.x = -location.l;
					layerRenderer.y = -location.t;
				} else {
					layerRenderer.x = 0;
					layerRenderer.y = 0;
					layerRenderer.scaleX = (mg.w/location.getLayerById(layerRenderer.name).w);
					layerRenderer.scaleY = (mg.h/location.getLayerById(layerRenderer.name).h);
				}
			}
		}
		
		private function resetLayerScales():void {
			for each (var layerRenderer:ILayerRenderer in locationView.layerRenderers) {
				layerRenderer.scaleX = layerRenderer.scaleY = 1;
			}
		}
	}
}