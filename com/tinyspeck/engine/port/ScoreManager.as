package com.tinyspeck.engine.port
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.games.Game;
	import com.tinyspeck.engine.data.games.GameSplashScreen;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.view.gameoverlay.GameSplashScreenView;
	import com.tinyspeck.engine.view.ui.scoreboards.ScoreBoard;
	import com.tinyspeck.engine.view.ui.scoreboards.ScoreGameOfCrowns;
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public class ScoreManager
	{
		/* singleton boilerplate */
		public static const instance:ScoreManager = new ScoreManager();
		
		private var model:TSModelLocator;
		private var score_boards:Vector.<ScoreBoard> = new Vector.<ScoreBoard>();
		private var _current_game:Game;
		private var _current_splash:GameSplashScreen;
		
		private var retry_timer:Timer = new Timer(500);
		
		public function ScoreManager() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			//listen to the timer
			retry_timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
		}
		
		public function start(payload:Object):void {
			if(!model) model = TSModelLocator.instance;
			
			//let's hide the pack and show the scoreboard
			var board:ScoreBoard = getBoardByType(payload.tsid);
			_current_game = Game.fromAnonymous(payload, payload.tsid);
			
			if(!board){
				switch(_current_game.tsid){
					case Game.GAME_OF_CROWNS:
						board = new ScoreGameOfCrowns();
						score_boards.push(board);
						break;
				}
			}
			
			if(!board){
				CONFIG::debugging {
					Console.warn('Could not create a new score board with the type: '+_current_game.tsid);
				}
				return;
			}
			
			//start up the score board
			board.start(_current_game);
			board.y = model.layoutModel.loc_vp_h - board.height - 20;
			TSFrontController.instance.getMainView().main_container.addChildAt(board, 0);
			TSTweener.addTween(board, {y:model.layoutModel.loc_vp_h , time:.5});
			
			//hide the pack
			PackDisplayManager.instance.changeVisibility(false, 'ScoreManager');
		}
		
		public function update(payload:Object):void {
			//update the scoreboard with the new data
			var board:ScoreBoard = getBoardByType(payload.tsid);
			
			if(!board){
				CONFIG::debugging {
					Console.warn('Could not find the score board with the type: '+payload.tsid);
				}
				
				//make a new one then!
				start(payload);
				return;
			}
			
			//update
			_current_game = Game.updateFromAnonymous(payload, _current_game);
			board.update(_current_game);
		}
		
		public function splash_screen(payload:Object):void {			
			_current_splash = GameSplashScreen.fromAnonymous(payload, payload.tsid);
			GameSplashScreenView.instance.splash_screen = _current_splash;
			
			//this needs to show up no matter what, ie. not in the queue
			retry_timer.reset();
			retry_timer.start();
			onTimerTick();
		}
		
		public function end(type:String):void {
			if(!model) model = TSModelLocator.instance;
			
			//clean up and show the pack again
			var board:ScoreBoard = getBoardByType(type);
			
			if(!board){
				CONFIG::debugging {
					Console.warn('Could not find the score board with the type: '+type);
				}
				PackDisplayManager.instance.changeVisibility(true, 'ScoreManager');
				return;
			}
			
			//animate the scoreboard away and bring the pack back
			board.end();
			if(board.parent){
				TSTweener.addTween(board, {y:model.layoutModel.loc_vp_h - board.height - 20, time:.5, 
					onComplete:function():void {
						if(board.parent) board.parent.removeChild(board);
					}
				});
			}
			
			//pack
			PackDisplayManager.instance.changeVisibility(true, 'ScoreManager');
		}
		
		public function refresh():void {
			//make sure the boards are in the right place
			var i:int;
			var total:int = score_boards.length;
			
			for(i; i < total; i++){
				if(score_boards[int(i)].parent) {
					score_boards[int(i)].refresh();
					score_boards[int(i)].y = model.layoutModel.loc_vp_h;
				}
			}
		}
		
		private function getBoardByType(type:String):ScoreBoard {
			var i:int;
			var total:int = score_boards.length;
			
			for(i; i < total; i++){
				if(score_boards[int(i)].type == type) return score_boards[int(i)];
			}
			
			return null;
		}
		
		private function onTimerTick(event:TimerEvent = null):void {
			//try to show it again
			if(_current_splash){
				if(GameSplashScreenView.instance.show()){
					retry_timer.stop();
				}
			}
			else {
				retry_timer.stop();
			}
		}
		
		public function get current_splash_screen():GameSplashScreen { return _current_splash; }
		public function get current_game():Game { return _current_game; }
	}
}