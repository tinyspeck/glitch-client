package com.tinyspeck.tstweener {
	public interface ITSTweenEngine {
		function addTween(target:Object, params:Object):Boolean;
		function removeTweens(target:Object, ...args):Boolean;
		function removeAllTweens():Boolean;
		function pauseTweens(target:Object, ...args):Boolean;
		function resumeTweens(target:Object, ...args):Boolean;
		function isTweening(target:Object):Boolean;
		function getTweenCount(target:Object):Number;
		function getActiveTweenCount():Number;
		function registerSpecialProperty(p_name:String, p_getFunction:Function, p_setFunction:Function, p_parameters:Array = null, p_preProcessFunction:Function = null):void;
	}
}
