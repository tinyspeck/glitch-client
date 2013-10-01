package com.tinyspeck.engine.util {
	import flash.display.MovieClip;
	import flash.display.Scene;
	
	public class MCUtil {
		
		public static function recursiveGotoAndPlay(mc:MovieClip, frame:Object):void {
			mc.gotoAndPlay(frame);
			var child:MovieClip;
			for (var i:int = mc.numChildren-1; i != -1; --i) {
				child = (mc.getChildAt(i) as MovieClip);
				if (child) {
					recursiveGotoAndPlay(child, frame);
				}
			}
		}
		
		public static function recursiveGotoAndStop(mc:MovieClip, frame:Object):void {
			mc.gotoAndStop(frame);
			var child:MovieClip;
			for (var i:int = mc.numChildren-1; i != -1; --i) {
				child = (mc.getChildAt(i) as MovieClip);
				if (child) {
					recursiveGotoAndStop(child, frame);
				}
			}
		}
		
		public static function recursiveGotoAndPlayChildrenOnly(mc:MovieClip, frame:Object):void {
			//mc.gotoAndPlay(frame);
			var child:MovieClip;
			for (var i:int = mc.numChildren-1; i != -1; --i) {
				child = (mc.getChildAt(i) as MovieClip);
				if (child) {
					recursiveGotoAndPlay(child, frame);
				}
			}
		}
		
		public static function recursiveGotoAndStopChildrenOnly(mc:MovieClip, frame:Object):void {
			//mc.gotoAndStop(frame);
			var child:MovieClip;
			for (var i:int = mc.numChildren-1; i != -1; --i) {
				child = (mc.getChildAt(i) as MovieClip);
				if (child) {
					recursiveGotoAndStop(child, frame);
				}
			}
		}
		
		public static function recursivePlay(mc:MovieClip):void {
			mc.play();
			var child:MovieClip;
			for (var i:int = mc.numChildren-1; i != -1; --i) {
				child = (mc.getChildAt(i) as MovieClip);
				if (child) {
					recursivePlay(child);
				}
			}
		}
		
		public static function recursiveStop(mc:MovieClip):void {
			mc.stop();
			var child:MovieClip;
			for (var i:int = mc.numChildren-1; i != -1; --i) {
				child = (mc.getChildAt(i) as MovieClip);
				if (child) {
					recursiveStop(child);
				}
			}
		}
		
		public static function getSceneByName(mc:MovieClip, scene_name:String):Scene {
			if (!scene_name) return null;
			
			if (mc && mc.scenes) {
				for (var i:int=0;i<mc.scenes.length;i++) {
					var scene:Scene = mc.scenes[int(i)];
					if (scene_name == scene.name) return scene;
				}
			}
			
			return null;
		}
		
		public static function playScene(mc:MovieClip, scene_name:String):void {
			var scene:Scene = MCUtil.getSceneByName(mc, scene_name);
			if (scene && scene.numFrames > 1) { // requires for a stop() or gotoAndPlay('scene name here', 1) to be added to the last frame
				mc.gotoAndPlay(1, scene_name);
			} else {
				mc.gotoAndStop(1, scene_name);
			}
		}
		
		public static function getHighestCountSceneName(mc:MovieClip, default_scene_name:String):String {
			var highest_scene_num:int = -1;
			var highest_scene:Scene = null;
			
			var scene_num:Number;
			for each (var scene:Scene in mc.scenes) {
				scene_num = parseInt(scene.name);
				if (!isNaN(scene_num) && (scene_num as int) > highest_scene_num) {
					highest_scene_num = (scene_num as int);
					highest_scene = scene;
				}
			}
			
			return (highest_scene ? highest_scene.name : default_scene_name);
		}
	}
}