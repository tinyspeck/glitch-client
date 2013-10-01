package com.tinyspeck.engine.view.ui.glitchr.filters {
	import com.tinyspeck.engine.util.TFUtil;
	
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.display.Sprite;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.filters.ShaderFilter;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	
	public class VintageFilter extends GlitchrFilter {
		
		public function VintageFilter() {
			super("vintage_filter");
			_defaultAlpha = 0.8;
		}
		
		override protected function init():void {
			
			
			// dark inner glow
			var innerGlow:GlowFilter = new GlowFilter(0, 0.7, 180, 180, 1.5, BitmapFilterQuality.HIGH, true);
			
			//noise
			var noiseShader:Shader = new Shader(new GlitchrShaders.NoiseShader() as ByteArray);
			noiseShader.data.alpha.value = [0.07];
			noiseShader.data.srcSize.value = [900, 600];
			var noiseFilter:ShaderFilter = new ShaderFilter(noiseShader);
			
			// sepia shader
			var historicShader:Shader = new Shader(new GlitchrShaders.HistoricShader() as ByteArray);
			historicShader.data.crossfade.value = [2];
			var historicFilter:ShaderFilter = new ShaderFilter(historicShader);
			
			_components.push(innerGlow);
			_components.push(noiseFilter);
			_components.push(historicFilter);
			
			setupOverlays();
		}
		
		private function setupOverlays():void {
			addWash();
			addBorder();
		}
		
		private function addWash():void {
			var washSprite:Sprite = new Sprite();
			washSprite.graphics.beginFill(0xffffff, 0.25);
			washSprite.graphics.drawCircle(2, 6, 2.5);
			washSprite.graphics.endFill();
			
			var washBMD:BitmapData = new BitmapData(8, 8, true, 0);
			washBMD.draw(washSprite);
			var washOverlay:FilterOverlay = new FilterOverlay(washBMD, "auto", true);
			
			_overlays.push(washOverlay);
		}
		
		private function addBorder():void {
			var borderSprite:Sprite = new Sprite();
			borderSprite.graphics.beginFill(0);
			borderSprite.graphics.drawRect(0, 0, 300, 250);
			borderSprite.graphics.drawRect(15, 15, 280, 230);
			borderSprite.graphics.endFill();
			
			var borderOverlayBMD:BitmapData = new BitmapData(300, 250, true, 0);
			borderOverlayBMD.draw(borderSprite);
			var borderOverlay:FilterOverlay = new FilterOverlay(borderOverlayBMD);
			borderOverlay.lockAlpha = true;
			
			// add border text
			var borderTF:TextField = new TextField();
			TFUtil.prepTF(borderTF, false);
			borderTF.htmlText = '<p class="glitchr_filters_sepia">52                     GLITCH SNP 6005                          53</p>';
			var scaleMat:Matrix = new Matrix();
			scaleMat.scale(0.9, 0.8);
			borderOverlayBMD.draw(borderTF, scaleMat);
			
			_overlays.push(borderOverlay);
		}		
	}
}