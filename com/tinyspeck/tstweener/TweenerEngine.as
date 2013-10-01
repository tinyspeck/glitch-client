package com.tinyspeck.tstweener {
	import caurina.transitions.Tweener;
	
	final public class TweenerEngine implements ITSTweenEngine {
		public function addTween(target:Object, params:Object):Boolean {
			return Tweener.addTween(target, params);
		}
		
		public function removeTweens(target:Object, ...args):Boolean {
			return Tweener.removeTweens.apply(Tweener, [target].concat(args));
		}
		
		public function removeAllTweens():Boolean {
			return Tweener.removeAllTweens();
		}
		
		public function pauseTweens(target:Object, ...args):Boolean {
			return Tweener.pauseTweens.apply(Tweener, [target].concat(args));
		}
		
		public function resumeTweens(target:Object, ...args):Boolean {
			return Tweener.resumeTweens.apply(Tweener, [target].concat(args));
		}
		
		public function isTweening(target:Object):Boolean {
			return Tweener.isTweening(target);
		}
		
		public function getTweenCount(target:Object):Number {
			return Tweener.getTweenCount(target);
		}
		
		public function getActiveTweenCount():Number {
			return Tweener.getActiveTweenCount();
		}
		
		public function registerSpecialProperty(p_name:String, p_getFunction:Function, p_setFunction:Function, p_parameters:Array=null, p_preProcessFunction:Function=null):void {
			Tweener.registerSpecialProperty(p_name, p_getFunction, p_setFunction, p_parameters, p_preProcessFunction);
		}
	}
}
