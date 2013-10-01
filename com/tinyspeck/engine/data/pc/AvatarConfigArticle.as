package com.tinyspeck.engine.data.pc {
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	
	public class AvatarConfigArticle extends AbstractTSDataEntity {
		
		public var type:String;
		public var article_class_name:String;
		public var package_swf_url:String;
		public var colors:Object;
		public var delta_x:int;
		public var delta_y:int;
		
		public function AvatarConfigArticle(hashName:String) {
			super(hashName);
			this.type = hashName;
		}
		
		override public function AMF():Object {
			var ob:Object = super.AMF();
			
			ob.type = type;
			ob.article_class_name = article_class_name;
			ob.package_swf_url = package_swf_url;
			if (colors) {
				ob.colors = {};
				for (var k:String in colors) {
					ob.colors[k] = colors[k].AMF();
				}
			}
			
			return ob;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):AvatarConfigArticle {
			var aca:AvatarConfigArticle = new AvatarConfigArticle(hashName);

			for(var j:String in object){
				var val:* = object[j];
				if(j in aca){
					if (j == 'colors') {
						aca.colors = AvatarConfigColor.parseMultiple(val);
					} else {
						aca[j] = val;
					}
				}else{
					resolveError(aca,object,j);
				}
			}
			
			if (!aca.colors) aca.colors = {};
			return aca;
		}
		
		public static function parseMultiple(object:Object):Object {
			var D:Object = {};
			for (var k:String in object) {
				D[k] = AvatarConfigArticle.fromAnonymous(object[k], k);
			}
			return D;
		}
		
	}
}