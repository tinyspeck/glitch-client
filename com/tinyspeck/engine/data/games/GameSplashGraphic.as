package com.tinyspeck.engine.data.games
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class GameSplashGraphic extends AbstractTSDataEntity
	{
		public var url:String;
		public var text:String;
		public var text_delta_x:int;
		public var text_delta_y:int;
		public var scale:Number = 1;
		public var frame_label:String;
		
		public function GameSplashGraphic(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, tsid:String):GameSplashGraphic {
			var graphic:GameSplashGraphic = new GameSplashGraphic(tsid);
			
			return updateFromAnonymous(object, graphic);
		}
		
		public static function updateFromAnonymous(object:Object, graphic:GameSplashGraphic):GameSplashGraphic {
			var j:String;
			
			for(j in object){
				if(j in graphic){	
					graphic[j] = object[j];
				}
				else{
					resolveError(graphic,object,j);
				}
			}
			
			return graphic;
		}
	}
}