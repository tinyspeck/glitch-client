package com.tinyspeck.engine.data.games
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class GameSplashButtonValue extends AbstractTSDataEntity
	{
		public var label:String;
		public var click_payload:Object;
		public var w:int;
		public var h:int;
		public var size:String;
		public var type:String;
		
		public function GameSplashButtonValue(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object):GameSplashButtonValue {
			var value:GameSplashButtonValue = new GameSplashButtonValue('splash_button');
			
			return updateFromAnonymous(object, value);
		}
		
		public static function updateFromAnonymous(object:Object, value:GameSplashButtonValue):GameSplashButtonValue {
			var j:String;
			
			for(j in object){
				if(j in value){	
					value[j] = object[j];
				}
				else{
					resolveError(value,object,j);
				}
			}
			
			return value;
		}
	}
}