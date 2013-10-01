package com.tinyspeck.engine.view.ui.leaderboard
{
	import com.tinyspeck.engine.data.leaderboard.LeaderboardEntry;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	
	import flash.text.TextField;

	public class LeaderboardElementUI extends TSSpriteWithModel
	{
		private var pc:PC;
		
		private var player_tf:TSLinkedTextField = new TSLinkedTextField();
		private var position_tf:TextField = new TextField();
		
		private var _contribution_tf:TextField = new TextField();
						
		public function LeaderboardElementUI(){
			TFUtil.prepTF(player_tf, false);
			player_tf.x = 35;
			addChild(player_tf);
			
			TFUtil.prepTF(position_tf);
			position_tf.width = 30;
			addChild(position_tf);
			
			TFUtil.prepTF(contribution_tf, false);
			addChild(contribution_tf);
		}
		
		public function show(entry:LeaderboardEntry, contribution_x:int, my_position:int):void {
			if(!entry) return;
			
			//player
			pc = model.worldModel.getPCByTsid(entry.pc_tsid);
			player_tf.htmlText = '<p class="leaderboard_name">'+(entry.position != my_position 
								? '<a href="event:'+TSLinkedTextField.LINK_PC+'|'+pc.tsid+'">'+pc.label+'</a>'
								: '<span class="leaderboard_me">'+pc.label+'</span>')+'</p>';
			
			//position
			position_tf.htmlText = '<p class="leaderboard_position">'+entry.position+'</p>';
			
			//contribution
			contribution_tf.htmlText = '<p class="leaderboard_contribution">'+(entry.position != my_position 
									? entry.contributions+'%' 
									: '<span class="leaderboard_me">'+entry.contributions+'%</span>')+'</p>';
			contribution_tf.x = int(contribution_x - contribution_tf.width/2);
		}
		
		public function get contribution_tf():TextField { return _contribution_tf; }
	}
}