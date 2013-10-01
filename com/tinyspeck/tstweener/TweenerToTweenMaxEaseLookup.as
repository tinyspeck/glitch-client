package com.tinyspeck.tstweener {
	 
	import com.greensock.easing.Back;
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Circ;
	import com.greensock.easing.Cubic;
	import com.greensock.easing.Elastic;
	import com.greensock.easing.Expo;
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	import com.greensock.easing.Quart;
	import com.greensock.easing.Quint;
	import com.greensock.easing.Sine;

	/**
	 * Copied from Greensock's EaseLookup Class.  Added a few lookups which
	 * facilitate converting Tweener easing functions to TweenMax functions.
	 */
	public class TweenerToTweenMaxEaseLookup {
		
		private static var _lookup:Object;
		
		{ // static init
			buildLookup();
		}
		
		public static function find(name:String):Function {
			var func:Function = _lookup[name.toLowerCase()];
			CONFIG::debugging {
				if (func == null) throw new Error("Transition " + name + " not found.");
			}
			return func;
		}
		
		private static function buildLookup():void {
			_lookup = {};
			
			addInOut(Back, ["back"]);
			addInOut(Bounce, ["bounce"]);
			addInOut(Circ, ["circ", "circular"]);
			addInOut(Cubic, ["cubic"]);
			addInOut(Elastic, ["elastic"]);
			addInOut(Expo, ["expo", "exponential"]);
			addInOut(Linear, ["linear"]);
			addInOut(Quad, ["quad", "quadratic"]);
			addInOut(Quart, ["quart","quartic"]);
			addInOut(Quint, ["quint", "quintic", "strong"]);
			addInOut(Sine, ["sine"]);
			
			_lookup["linear.easenone"] = _lookup["lineareasenone"] = _lookup["linear"] = Linear.easeNone;
		}
		
		private static function addInOut(easeClass:Class, names:Array):void {
			var name:String;
			var i:int = names.length;
			while (i-- > 0) {
				name = names[i].toLowerCase();
				_lookup[name + ".easein"] = _lookup[name + "easein"] = _lookup["easein" + name] = easeClass.easeIn;
				_lookup[name + ".easeout"] = _lookup[name + "easeout"] = _lookup["easeout" + name] = easeClass.easeOut;
				_lookup[name + ".easeinout"] = _lookup[name + "easeinout"] = _lookup["easeinout" + name]= easeClass.easeInOut;
			}
		}
	}
}