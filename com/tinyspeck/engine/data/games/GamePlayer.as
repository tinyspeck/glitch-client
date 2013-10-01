package com.tinyspeck.engine.data.games
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class GamePlayer extends AbstractTSDataEntity
	{
		public var tsid:String;
		public var label:String;
		public var score:int;
		public var is_active:Boolean;
		
		public function GamePlayer(tsid:String){
			super(tsid);
		}
		
		public static function parseMultiple(players:Object):Vector.<GamePlayer> {
			var V:Vector.<GamePlayer> = new Vector.<GamePlayer>;
			var i:int;
			
			while(players[int(i)]){
				V.push(fromAnonymous(players[int(i)], players[int(i)].tsid));
				i++;
			}

			return V;
		}
		
		public static function fromAnonymous(object:Object, tsid:String):GamePlayer {
			var player:GamePlayer = new GamePlayer(tsid);
			
			return updateFromAnonymous(object, player);
		}
		
		public static function updateFromAnonymous(object:Object, player:GamePlayer):GamePlayer {
			var j:String;
			
			for(j in object){
				if(j in player){	
					player[j] = object[j];
				}
				else{
					resolveError(player,object,j);
				}
			}
			
			return player;
		}
	}
}