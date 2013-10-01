package com.tinyspeck.engine.data.location {
	import com.tinyspeck.engine.model.TSModelLocator;

	public class Deco extends AbstractPositionableLocationEntity {
		public var sprite_class:String;
		public var z:int;
		public var h:int;
		public var w:int;
		public var r:int;
		
		public var h_flip:Boolean;
		public var v_flip:Boolean; // not in use but seems to be sent in some locations
		
		public var is_home:Boolean;
		public var room:String; // home wallpaper decos have this, used to group decos in a room together.
		public var wp_key:String; // home wallpaper decos have this
		public var ceiling_key:String; // home ceiling decos have this
		public var floor_key:String; // home floor decos have this
		public var sign_txt:String;
		public var sign_css_class:String = 'default_deco_sign';
		
		/** True if it should be standalone at runtime */
		public var standalone:Boolean;
		
		/** True if it should be animated at runtime */
		public var animated:Boolean;
		
		/** decos that are used in tiling/doors/ are simple, and do not have a bunch of props in the geo */
		public var is_simple:Boolean;
		
		public function Deco(hashName:String) {
			super(hashName);
		}
		
		public function get should_be_rendered_standalone():Boolean {
			return standalone || animated || sign_txt || (is_home && TSModelLocator.instance.flashVarModel.is_home_standalone);
		}
		
		override public function AMF():Object {
			var ob:Object = super.AMF();
			
			ob.name = name;
			ob.sprite_class = sprite_class;
			ob.h = h;
			ob.w = w;
			if (animated) ob.animated = animated;
			if (standalone) ob.standalone = standalone;
			if (h_flip) ob.h_flip = h_flip;
			if (v_flip) ob.v_flip = v_flip;
			
			if (is_simple) {
				delete ob['x'];
				delete ob['y'];
			} else {
				ob.z = z;
				if (r) ob.r = r;
			}
			
			if (sign_txt) {
				ob.sign_txt = sign_txt;
				ob.sign_css_class = sign_css_class;
			}
			
			if (is_home) ob.is_home = is_home;
			if (wp_key) ob.wp_key = wp_key;
			if (ceiling_key) ob.ceiling_key = ceiling_key;
			if (floor_key) ob.floor_key = floor_key;
			if (room) ob.room = room;
			
			return ob;
		}
		
		public static function parseMultiple(object:Object):Vector.<Deco> {
			var decos:Vector.<Deco> = new Vector.<Deco>();
			for (var j:String in object) {
				decos.push(fromAnonymous(object[j],j));
			}
			return decos;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Deco {
			const deco:Deco = new Deco(hashName);
			deco.updateFromAnonymous(object);
			return deco;
		}
		
		public function updateFromAnonymous(object:Object):void {
			for (var j:String in object) {
				if (j in this) {
					this[j] = object[j];
				} else if (j == 'floor_left' || j == 'ceiling_idx' || j == 'floor_idx') {
					// don't warn on these! (but call resolveError so they get added to unexpected
					resolveError(this, object, j, true);
				} else {
					resolveError(this, object, j);
				}
			}
		}
	}
}