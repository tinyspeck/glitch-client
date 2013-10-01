package com.tinyspeck.engine.data.games
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class GameSplashButtons extends AbstractTSDataEntity
	{
		public var is_vertical:Boolean;
		public var padding:int;
		public var delta_x:int;
		public var delta_y:int;
		public var values:Vector.<GameSplashButtonValue> = new Vector.<GameSplashButtonValue>();
		
		public function GameSplashButtons(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, tsid:String):GameSplashButtons {
			var buttons:GameSplashButtons = new GameSplashButtons(tsid);
			
			return updateFromAnonymous(object, buttons);
		}
		
		public static function updateFromAnonymous(object:Object, buttons:GameSplashButtons):GameSplashButtons {
			var j:String;
			var count:int;
			
			for(j in object){
				if(j == 'values'){
					count = 0;
					while(object[j] && object[j][count]){
						buttons.values.push(GameSplashButtonValue.fromAnonymous(object[j][count]));
						count++;
					}
				}
				else if(j in buttons){	
					buttons[j] = object[j];
				}
				else{
					resolveError(buttons,object,j);
				}
			}
			
			return buttons;
		}
	}
}