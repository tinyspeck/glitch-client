package com.tinyspeck.engine.view.ui.decorate
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.location.Deco;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.renderer.DecoAssetManager;
	
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	
	public class SwatchTarget extends Sprite {
		
		private var deco:Deco;
		private var center_offset:int;
		public var center:Sprite;
		
		public function SwatchTarget(deco:Deco, center_offset:int=0) {
			this.deco = deco;
			this.center_offset = center_offset;
			construct();
		}
		
		private function construct():void {
			x = deco.x;
			y = deco.y;
			scaleX = deco.h_flip ? -1 : 1;
			visible = false;
			
			var draw_alpha:Number = .4;
			var g:Graphics
			
			if (center_offset) {
				center = new Sprite();
				addChild(center);
				
				g = center.graphics;
				g.lineStyle(0, 0, 0);
				g.beginFill(0x000000, (false && TSModelLocator.instance.flashVarModel.debug_decorator_mode) ? draw_alpha: 0);
				g.drawRect(-(deco.w-(center_offset*2))/2, -(deco.h-center_offset), deco.w-(center_offset*2), deco.h-(center_offset*2));
			}
			
			var good:Boolean = DecoAssetManager.loadIndividualDeco(deco.sprite_class, function(mc:MovieClip, class_name:String, swfWidth:Number, swfHeight:Number):void {
				addChild(mc);
				mc.loaderInfo.loader.unloadAndStop();
				mc.x = -Math.round(swfWidth/2);
				mc.y = -swfHeight;
			});
			
			if (!good) {
				; // FU
				CONFIG::debugging {
					Console.error('WTF no deco for '+deco.tsid);
				}
			}
		}
		
	}
}