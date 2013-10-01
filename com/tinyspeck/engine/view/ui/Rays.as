package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;

	public class Rays extends Sprite
	{
		public static const SCENE_THIN_FAST:String = 'thinFast';
		public static const SCENE_THIN_SLOW:String = 'thinSlow';
		public static const SCENE_THICK_FAST:String = 'thickFast';
		public static const SCENE_THICK_SLOW:String = 'thickSlow';
		public static const SCENE_COMBINED_SLOW:String = 'combinedSlow';
		public static const SCENE_SMALL_THIN_FAST:String = 'smallThinFast';
		
		public static const SCALE_DEFAULT:Number = 1.5;
		
		private var rays_asset:MovieClip;
		
		private var _is_loaded:Boolean;
		private var _scene_name:String;
		private var _scale:Number;
		
		public function Rays(scene_name:String = Rays.SCENE_COMBINED_SLOW, scale:Number = Rays.SCALE_DEFAULT){			
			//set the scene/scale
			_scene_name = scene_name;
			_scale = scale;
			
			//load the rays!
			const rays_loader:MovieClip = new AssetManager.instance.assets.level_up_rays();
			rays_loader.addEventListener(Event.COMPLETE, onLoaded, false, 0, true);
		}
		
		private function onLoaded(event:Event):void {
			rays_asset = Loader(event.target.getChildAt(0)).content as MovieClip;
			
			if(!rays_asset){
				CONFIG::debugging {
					Console.warn('SOMETHING WRONG WITH THE RAYS!');
				}
				return;
			}
			
			//set the scale
			setScale(_scale);
			
			//goto the scene if we have one
			gotoScene(_scene_name);
			
			//attach it
			addChild(rays_asset);
			
			//it's loaded now
			_is_loaded = true;
			
			//if anyone was listening, let's let them know!
			dispatchEvent(new TSEvent(TSEvent.COMPLETE, this));
		}
		
		public function gotoScene(scene_name:String = Rays.SCENE_COMBINED_SLOW):void {
			if(rays_asset && scene_name) rays_asset.gotoAndPlay(1, scene_name);
			_scene_name = scene_name;
		}
		
		public function setScale(scale:Number = Rays.SCALE_DEFAULT):void {
			if(rays_asset && !isNaN(scale)) rays_asset.scaleX = rays_asset.scaleY = scale;
			_scale = scale;
		}
		
		public function get is_loaded():Boolean { return _is_loaded; }
	}
}