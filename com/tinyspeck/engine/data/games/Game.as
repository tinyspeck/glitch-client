package com.tinyspeck.engine.data.games
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class Game extends AbstractTSDataEntity
	{
		public static const GAME_OF_CROWNS:String = 'it_game'; //old name on the GS
		
		public var tsid:String;
		public var title:String;
		public var timer:int;
		public var is_game_over:Boolean;
		public var players:Vector.<GamePlayer> = new Vector.<GamePlayer>();
		
		public function Game(tsid:String){
			this.tsid = tsid;
			super(tsid);
		}
		
		public static function fromAnonymous(object:Object, tsid:String):Game {
			var game:Game = new Game(tsid);
			
			return updateFromAnonymous(object, game);
		}
		
		public static function updateFromAnonymous(object:Object, game:Game):Game {
			var j:String;
			
			for(j in object){
				if(j == 'players'){
					game.players = GamePlayer.parseMultiple(object[j]);
				}
				else if(j in game){	
					game[j] = object[j];
				}
				else{
					resolveError(game,object,j);
				}
			}
			
			return game;
		}
	}
}