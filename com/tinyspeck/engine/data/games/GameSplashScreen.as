package com.tinyspeck.engine.data.games
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class GameSplashScreen extends AbstractTSDataEntity
	{
		public var tsid:String;
		public var graphic:GameSplashGraphic;
		public var text:String;
		public var text_delta_x:int;
		public var text_delta_y:int;
		public var buttons:GameSplashButtons;
		public var show_rays:Boolean;
		public var sound:String;
		
		public function GameSplashScreen(game_tsid:String){
			super(game_tsid);
			tsid = game_tsid;
		}
		
		public static function fromAnonymous(object:Object, tsid:String):GameSplashScreen {
			var splash:GameSplashScreen = new GameSplashScreen(tsid);
			
			return updateFromAnonymous(object, splash);
		}
		
		public static function updateFromAnonymous(object:Object, splash:GameSplashScreen):GameSplashScreen {
			var j:String;
			
			for(j in object){
				if(j == 'buttons'){
					splash.buttons = GameSplashButtons.fromAnonymous(object[j], splash.tsid);
				}
				else if(j == 'graphic'){
					splash.graphic = GameSplashGraphic.fromAnonymous(object[j], splash.tsid);
				}
				else if(j in splash){	
					splash[j] = object[j];
				}
				else{
					resolveError(splash,object,j);
				}
			}
			
			return splash;
		}
	}
}