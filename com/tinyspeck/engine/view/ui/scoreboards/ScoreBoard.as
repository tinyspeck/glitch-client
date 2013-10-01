package com.tinyspeck.engine.view.ui.scoreboards
{
	import com.tinyspeck.engine.data.games.Game;
	import com.tinyspeck.engine.data.games.GamePlayer;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public class ScoreBoard extends Sprite
	{
		protected var timer:Timer = new Timer(1000);
		protected var current_players:Vector.<GamePlayer> = new Vector.<GamePlayer>();
		
		protected var current_time:int;
		
		private var _type:String;
		
		public function ScoreBoard(type:String){
			_type = type;
			
			timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
		}
		
		public function start(game:Game):void {
			//update the scores
			update(game);
		}
		
		public function update(game:Game):void {
			//update the scores
			current_players = game.players;
			
			//this game have a time limit?
			if(game.timer){
				current_time = game.timer;
								
				if(!timer.running){
					timer.reset();
					timer.start();
					onTimerTick();
				}
			}
			
			//is the game over?
			if(game.is_game_over){
				end();
			}
			
			refresh();
		}
		
		public function end():void {
			timer.stop();
		}
		
		public function refresh():void {
			const layout:LayoutModel = TSModelLocator.instance.layoutModel;
			
			//debug stuff
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0, .5);
			g.drawRect(0, 0, layout.loc_vp_w, 132);
		}
		
		protected function onTimerTick(event:TimerEvent = null):void {
			current_time--;
			
			if(current_time <= 0){
				timer.stop();
			}
		}
		
		public function get type():String { return _type; }
	}
}