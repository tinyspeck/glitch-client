package com.tinyspeck.engine.view.ui.scoreboards
{
	import com.tinyspeck.engine.data.games.GamePlayer;
	import com.tinyspeck.engine.util.TFUtil;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class PlayerGameOfCrowns extends Sprite
	{
		private static const WH:uint = 100;
		
		private var score_tf:TextField = new TextField();
		private var label_tf:TextField = new TextField();
		
		private var _score:int;
		private var _is_active:Boolean;
		
		public function PlayerGameOfCrowns(){		
			TFUtil.prepTF(score_tf);
			score_tf.width = WH;
			score = 0;
			addChild(score_tf);
			
			TFUtil.prepTF(label_tf);
			label_tf.width = WH;
			label_tf.y = int(score_tf.y + score_tf.height + 3);
			addChild(label_tf);
			
			//show something for now
			is_active = false;
		}
		
		public function update(player:GamePlayer):void {			
			//score
			if(_score != player.score){
				score = player.score;
			}
			
			//name
			if(name != player.tsid){
				label = player.label;
				name = player.tsid;
			}
			
			//see if we are active or not
			if(_is_active != player.is_active){
				is_active = player.is_active;
			}
			
			//make sure we can see it
			if(!visible) visible = true;
		}
		
		public function set score(value:int):void {
			score_tf.htmlText = '<p class="score_crowns_score">'+value+'</p>';
			_score = value;
		}
		
		public function set label(value:String):void {
			label_tf.htmlText = '<p class="score_crowns_name">'+value+'</p>';
		}	
		
		public function set is_active(value:Boolean):void {
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(value ? 0x999999 : 0, .2);
			g.drawRect(0, 0, WH, WH);
			
			_is_active = value;
		}
	}
}