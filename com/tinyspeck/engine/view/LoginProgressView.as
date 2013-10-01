package com.tinyspeck.engine.view {
	import com.quasimondo.geom.ColorMatrix;
	import com.tinyspeck.bootstrap.control.BootStrapController;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.BlendMode;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	
	public class LoginProgressView extends Sprite {
		/* singleton boilerplate */
		public static const instance:LoginProgressView = new LoginProgressView();
		
		private var login_spinner:MovieClip;

		public function LoginProgressView() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			init();
		}
		
		private function init():void {
			
			blendMode = BlendMode.LAYER;
			
			visible = false;
			login_spinner = new AssetManager.instance.assets.spinner();
			login_spinner.addEventListener(Event.COMPLETE, function(e:Event):void {
				login_spinner = (Loader(e.target.getChildAt(0)).content as MovieClip);
				login_spinner.x = Math.round(width/2);
				login_spinner.y = Math.round((height-login_spinner.height)/2);
				scaleX = scaleY = 1.2;
				
				
				addChild(login_spinner);
				
				customize();
				
				refresh();
			});
		}
		
		private function customize():void {
			if (TSModelLocator.instance.flashVarModel.new_loading_screen) {
				var g:Graphics = this.graphics;
				g.beginFill(0x737373, 1);
				g.drawRoundRect(login_spinner.x-11, login_spinner.y-11, login_spinner.width+22, login_spinner.height+22, 12);
				g.beginFill(0xffffff, 1);
				g.drawRoundRect(login_spinner.x-10, login_spinner.y-10, login_spinner.width+20, login_spinner.height+20, 12);
			} else {
				var cm:ColorMatrix = new com.quasimondo.geom.ColorMatrix();
				cm.adjustContrast(1);
				cm.adjustBrightness(100);
				cm.colorize(0xFFFFFF);
				login_spinner.filters = [cm.filter];
			}
		}
		
		public function end():void {
			//
		}
		
		public function start():void {
			visible = true;
			alpha = 0;
			TSTweener.addTween(this, {alpha:1, time:3});
			CONFIG::debugging {
				Console.warn('LPV.start');
			}
		}
		
		public function refresh():void {
			if (!parent) return;
			x = Math.round((stage.stageWidth-width)/2)+10; // the 10 makes it cover the tagline better
			y = 100;
			
			if (BootStrapController.instance.loadingViewHolder) {
				if (TSModelLocator.instance.flashVarModel.new_loading_screen) {
					y = 360;
				} else {
					y = BootStrapController.instance.logo.y + 262; // places it under the tagline
				}
			}
		}
	}
}