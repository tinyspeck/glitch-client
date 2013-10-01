package com.tinyspeck.engine.view.ui.scoreboards
{
	import com.tinyspeck.engine.data.games.Game;

	public class ScoreGameOfCrowns extends ScoreBoard
	{
		private static const PADD:uint = 10;
		
		private var players:Vector.<PlayerGameOfCrowns> = new Vector.<PlayerGameOfCrowns>();
		
		public function ScoreGameOfCrowns(){
			super(Game.GAME_OF_CROWNS);
		}
		
		override public function start(game:Game):void {
			//reset the player UIs
			var i:int;
			var total:int = players.length;
			var player:PlayerGameOfCrowns;
			
			for(i; i < total; i++){
				player = players[int(i)];
				player.x = 0;
				player.name = '$$$NUFFIN$$$';
				player.visible = false;
			}
			
			super.start(game);
		}
		
		override public function update(game:Game):void {
			super.update(game);
			
			//TODO compare current with new and animate them to the new positions
			
			//look for the players
			var i:int;
			var total:int = game.players.length;
			var player:PlayerGameOfCrowns;
			var next_x:int = PADD;
			
			for(i; i < total; i++){
				if(players.length > i){
					player = players[int(i)];
				}
				else {
					player = new PlayerGameOfCrowns();
					player.y = PADD;
					players.push(player);
					addChild(player);
				}
				
				//update with the new data
				player.update(game.players[int(i)]);
				player.x = next_x;
				
				next_x += player.width + 10;
			}
		}
	}
}