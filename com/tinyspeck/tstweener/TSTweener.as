package com.tinyspeck.tstweener
{
	/**
	 * Abstraction layer that allows swapping of tweening engines.
	 * The API was made to mimic Tweener
	 */
	public class TSTweener {
		public static const TWEENER:ITSTweenEngine = new TweenerEngine();
		public static const TWEENMAX:ITSTweenEngine = new TweenMaxEngine();
		
		private static var currentEngine:ITSTweenEngine;
	
		public static function useEngine(engine:ITSTweenEngine):void {
			currentEngine = engine;
		}
	
		public static function addTween(target:Object, params:Object):Boolean {
			// make sure an undefined transition always defaults to easeOutQuart
			if (params.transition == null || params.transition == "") {
				params["transition"] = "easeoutquart";
			}
			return currentEngine.addTween(target, params);
		}
		
		public static function removeTweens(target:Object, ...args):Boolean {
			return currentEngine.removeTweens.apply(currentEngine, [target].concat(args));
		}
		
		public static function removeAllTweens():Boolean {
			return currentEngine.removeAllTweens();
		}
		
		public static function pauseTweens(target:Object, ...args):Boolean {
			return currentEngine.pauseTweens.apply(currentEngine, [target].concat(args));
		}
		
		public static function resumeTweens(target:Object, ...args):Boolean {
			return currentEngine.resumeTweens.apply(currentEngine, [target].concat(args));
		}
		
		public static function isTweening(target:Object):Boolean {
			return currentEngine.isTweening(target);
		}
		
		public static function getTweenCount(target:Object):Number {
			return currentEngine.getTweenCount(target);
		}

		public static function getActiveTweenCount():Number {
			return currentEngine.getActiveTweenCount();
		}
		
		/**
		 * We should move away from using this, as it is a slow and redundant.
		 * This function can be avoided by proper use of onUpdate or onComplete.
		 * See SoundManager.fadeSound for an example.
		 */
		//public static function registerSpecialProperty(p_name:String, p_getFunction:Function, p_setFunction:Function, p_parameters:Array = null, p_preProcessFunction:Function = null): void {
		//	return currentEngine.registerSpecialProperty(p_name, p_getFunction, p_setFunction, p_parameters, p_preProcessFunction);
		//}
	}
}
