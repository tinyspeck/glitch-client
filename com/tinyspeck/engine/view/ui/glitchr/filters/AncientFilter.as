package com.tinyspeck.engine.view.ui.glitchr.filters {
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.display.Sprite;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.filters.ShaderFilter;
	import flash.utils.ByteArray;
	
	public class AncientFilter extends GlitchrFilter {
		
		public function AncientFilter() {
			super("ancient_filter");
		}
		
		override protected function init():void {
			
			var curvesShader:Shader = new Shader(new GlitchrShaders.CurvesShader() as ByteArray);
			curvesShader.data.saturation.value = [0.0];
			curvesShader.data.redLow.value = [0, 23];
			curvesShader.data.redHigh.value = [207, 255];
			curvesShader.data.greenLow.value = [0, 0];
			curvesShader.data.greenHigh.value = [222, 255];
			curvesShader.data.blueLow.value = [41, 0];
			curvesShader.data.blueHigh.value = [255, 255];
			var curvesFilter:ShaderFilter = new ShaderFilter(curvesShader);
			
			//noise
			var noiseShader:Shader = new Shader(new GlitchrShaders.NoiseShader() as ByteArray);
			noiseShader.data.alpha.value = [0.1];
			noiseShader.data.srcSize.value = [900, 600];
			var noiseFilter:ShaderFilter = new ShaderFilter(noiseShader);
			
			// white inner glow
			var innerGlow:GlowFilter = new GlowFilter(0xffffff, 0.6, 128, 128, 1, BitmapFilterQuality.HIGH, true);
			
			_components.push(curvesFilter);
			_components.push(noiseFilter);
			_components.push(innerGlow);
			
			createOverlays();
		}
		
		private function createOverlays():void {
			addWash();
			createBorderOverlay();
		}
		
		private function createBorderOverlay():void {
			
			var decayBorder:Sprite = new Sprite();
			var borderWidth:Number = 800;
			var borderHeight:Number = 550;
			
			drawBorder(decayBorder, 0, 0, true, false, borderWidth, borderHeight);
			drawBorder(decayBorder, 0, borderHeight, true, false, borderWidth, borderHeight);
			drawBorder(decayBorder, 0, 0, false, true, borderWidth, borderHeight);
			drawBorder(decayBorder, borderWidth, 0, false, true, borderWidth, borderHeight);
			
			var decayBorderBMD:BitmapData = new BitmapData(borderWidth, borderHeight, true, 0);
			decayBorderBMD.draw(decayBorder);
			var decayOverlay:FilterOverlay = new FilterOverlay(decayBorderBMD);
			decayOverlay.lockAlpha = true;
			
			_overlays.push(decayOverlay);
		}
		
		private function drawBorder(targetSprite:Sprite, startingX:Number = 0, 
									startingY:Number = 0, incrementX:Boolean = true, incrementY:Boolean = false, spriteWidth:Number = 400, spriteHeight:Number = 500):void {
			var maxRadius:Number = 8;
			var maxVariation:Number = 6;
			var curX:Number = startingX;
			var curY:Number = startingY;
			
			var i:uint = 0;
			while (curX <= spriteWidth && curY <= spriteHeight) {
				var radius:Number = maxRadius - Math.random() * maxVariation;
				targetSprite.graphics.beginFill(0xffffff, 1);
				targetSprite.graphics.drawCircle(curX, curY, radius);
				targetSprite.graphics.endFill();
				if (incrementX) curX += radius/2;
				if (incrementY) curY += radius/2;
			}			
		}
		
		private function addWash():void {
			var washSprite:Sprite = new Sprite();
			washSprite.graphics.beginFill(0xffffff, 0.25);
			washSprite.graphics.drawCircle(2, 6, 3);
			washSprite.graphics.endFill();
			
			var washBMD:BitmapData = new BitmapData(8, 8, true, 0);
			washBMD.draw(washSprite);
			var washOverlay:FilterOverlay = new FilterOverlay(washBMD, "auto", true);
			
			_overlays.push(washOverlay);
		}		
	}
}