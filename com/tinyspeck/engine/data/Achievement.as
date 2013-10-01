package com.tinyspeck.engine.data
{
	import flash.utils.Dictionary;

	public class Achievement extends AbstractTSDataEntity
	{
		public var tsid:String;
		public var name:String;
		public var icon_urls:Dictionary;
		
		public function Achievement(hashName:String){
			super(hashName);
			tsid = hashName;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Achievement {
			var achievement:Achievement = new Achievement(hashName);
			var val:*;
			var j:String;
			var k:String;
			
			for(j in object){
				val = object[j];
				if(j == 'id' && val){
					//just re-set the tsid
					achievement.tsid = val;
				}
				else if(j == 'icon_urls' && val){
					achievement.icon_urls = new Dictionary();
					for(k in val){
						achievement.icon_urls[k] = val[k];
					}
				}
				else if(j in achievement){
					achievement[j] = val;
				}
				else{
					resolveError(achievement,object,j);
				}
			}
			
			return achievement;
		}
		
		public static function updateFromAnonymous(object:Object, achievement:Achievement):Achievement {
			achievement = fromAnonymous(object, achievement.hashName);
			
			return achievement;
		}
	}
}