
package com.tinyspeck.engine.data.pc {
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.loader.AvatarConfigRecord;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.ObjectUtil;
	
	public class AvatarConfig extends AbstractTSDataEntity {
		public static var settings:Object;
		
		public var ver:String;
		public var pc_tsid:String;
		public var nose_scale:Number;
		public var nose_height:Number;
		public var eye_scale:Number;
		public var eye_dist:Number;
		public var eye_height:Number;
		public var mouth_scale:Number;
		public var mouth_height:Number;
		public var ears_scale:Number;
		public var ears_height:Number;
		public var skin_tint_color:int = -1;
		public var hair_tint_color:int = -1;
		public var article_typesA:Array = [];
		private var articles:Object;
		public var skin_colors:Object;
		public var hair_colors:Object;
		public var placeholder:Boolean;
		public var acr:AvatarConfigRecord;
		
		/** True when this represents the avatar of the player */
		client var isPlayersAvatar:Boolean;
		
		public function AvatarConfig(hashName:String, isPlayersAvatar:Boolean = false) {
			super(hashName);
			this.client::isPlayersAvatar = isPlayersAvatar;
		}
		
		public function get sig():String {
			return ObjectUtil.makeSignatureForHash(AMF());
		}
		
		override public function AMF():Object {
			var ob:Object = super.AMF();
			// NO pc_tsid
			// NO acr
			ob.nose_scale = nose_scale;
			ob.nose_height = nose_height;
			ob.eye_scale = eye_scale;
			ob.eye_dist = eye_dist;
			ob.eye_height = eye_height;
			ob.mouth_scale = mouth_scale;
			ob.mouth_height = mouth_height;
			ob.ears_scale = ears_scale;
			ob.ears_height = ears_height;
			ob.skin_tint_color = ColorUtil.colorNumToStr(skin_tint_color);
			ob.hair_tint_color = ColorUtil.colorNumToStr(hair_tint_color);
			var k:String;
			if (skin_colors) {
				ob.skin_colors = {};
				for (k in skin_colors) {
					ob.skin_colors[k] = skin_colors[k].AMF();
				}
			}
			if (hair_colors) {
				ob.hair_colors = {};
				for (k in hair_colors) {
					ob.hair_colors[k] = hair_colors[k].AMF();
				}
			}
			if (articles) {
				ob.articles = {};
				for (k in articles) {
					ob.articles[k] = articles[k].AMF();
				}
			}
			
			return ob;
		}
		
		public function getArticleByType(type:String):AvatarConfigArticle {
			return articles[type] as AvatarConfigArticle;
		}
		
		public static function fromAnonymous(object:Object, isPlayersAvatar:Boolean = false):AvatarConfig {
			var ac:AvatarConfig = new AvatarConfig('config', isPlayersAvatar);
			
			for(var j:String in object){
				var val:* = object[j];
				
				if (j == 'articles') { // because articles is private this must happen outside of the "if(j in ac)" test, because that fails for all but public props
					ac[j] = AvatarConfigArticle.parseMultiple(val);
					for (var k:String in ac.articles) {
						ac.article_typesA.push(k);
					}
				} else if(j in ac){
					if (j == 'skin_tint_color' || j == 'hair_tint_color') {
						ac[j] = ColorUtil.colorStrToNum(val);
					} else if (j == 'skin_colors') {
						ac.skin_colors = AvatarConfigColor.parseMultiple(val);
					} else if (j == 'hair_colors') {
						ac.hair_colors = AvatarConfigColor.parseMultiple(val);
					} else {
						ac[j] = val;
					}
				}else{
					resolveError(ac,object,j);
				}
			}
			
			if (!ac.articles) ac.articles = {};
			
			if (settings && typeof settings == 'object') {
				for (j in settings) {
					if (!(j in ac)) continue;
					if (typeof settings[j] != 'object') continue;
					if (!('def' in settings[j])) continue;
					if (isNaN(settings[j].def)) continue;
					if (ac[j] is Number && isNaN(ac[j])) {
						ac[j] = settings[j].def;
					//	Console.warn(j+' '+(j in ac)+' '+ac[j]);
					}
				}
			}
			
			return ac;
		}
		
	}
}