package com.tinyspeck.tstweener
{
	import com.greensock.TweenMax;
	import com.greensock.plugins.TweenPlugin;
	import com.tinyspeck.tstweener.plugins._AutoAlphaPlugin;
	import com.tinyspeck.tstweener.plugins._BezierPlugin;

	final public class TweenMaxEngine implements ITSTweenEngine
	{
		public function TweenMaxEngine() {
			TweenPlugin.activate([_AutoAlphaPlugin, _BezierPlugin]);
		}
		
		public function addTween(target:Object, params:Object):Boolean {
			const time:Number = params['time'] || 0;
			delete params['time'];
			
			if (params['transition']) {
				params['ease'] = TweenerToTweenMaxEaseLookup.find(params['transition']);
				delete params['transition'];
			}
			
			if (target is Array) {
				TweenMax.allTo((target as Array), time, params);
			} else {
				TweenMax.to(target, time, params);
			}
			return true;
		}
		
		public function removeTweens(target:Object, ...args):Boolean {
			if (target is Array) {
				for each(var tObject:Object in target) {
					removeTweens.apply(null, [tObject].concat(args));
					//removeTweens(tObject, args);
				}
				return true;
			}
	
			var vars:Object;
			if (args.length) {
				vars = {};
				for each(var key:String in args) {
					vars[key] = true;
				}
			}
			TweenMax.killTweensOf(target, false, vars);
			return true;
		}
		
		public function removeAllTweens():Boolean {
			TweenMax.killAll();
			return true;
		}
		
		public function pauseTweens(target:Object, ...args):Boolean {
			// NOTE: TweenMax has no ability to fetch tweens for specific properties, args is ignored.
			// Only 1 call from GrowlQueue, and I don't think it acheives anything (target that is passed is not what is being tweened)
			var tweens:Array = TweenMax.getTweensOf(target);
			for each (var tween:TweenMax in tweens) tween.pause();
			
			return true;
		}
		
		public function resumeTweens(target:Object, ...args):Boolean {
			// NOTE: TweenMax has no ability to fetch tweens for specific properties, args is ignored.
			// Only 1 call from GrowlQueue, and I don't think it acheives anything (target that is passed is not what is being tweened)
			var tweens:Array = TweenMax.getTweensOf(target);
			for each (var tween:TweenMax in tweens) tween.resume();
			
			return true;
		}
		
		public function isTweening(target:Object):Boolean {
			return TweenMax.isTweening(target);
		}
		
		public function getTweenCount(target:Object):Number {
			return TweenMax.getTweensOf(target).length;
		}

		public function getActiveTweenCount():Number {
			return TweenMax.getAllTweensCount();
		}
		
		public function registerSpecialProperty(p_name:String, p_getFunction:Function, p_setFunction:Function, p_parameters:Array=null, p_preProcessFunction:Function=null):void {
			// TweenMax doesn't have ability to register special properties
			throw new Error();
		}
	}
}
