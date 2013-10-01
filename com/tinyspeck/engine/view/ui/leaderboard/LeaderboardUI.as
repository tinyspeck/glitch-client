package com.tinyspeck.engine.view.ui.leaderboard
{
	import com.tinyspeck.engine.data.leaderboard.Leaderboard;
	import com.tinyspeck.engine.data.leaderboard.LeaderboardEntry;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.TFUtil;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class LeaderboardUI extends TSSpriteWithModel
	{
		private const MAX_POSITIONS:uint = 10; //we add 1 manually at the bottom of the 10 if you fall below top 10
		private const GAP:uint = 34;
		private const CONTRIBUTIONS_LEFT_HEADER_X:int = 185;
		
		private var leaderboard:Leaderboard;
		private var elements:Vector.<LeaderboardElementUI> = new Vector.<LeaderboardElementUI>();
		
		private var title_tf:TextField = new TextField();
		private var contributions_left:TextField = new TextField();
		private var contributions_right:TextField = new TextField();
		
		public function LeaderboardUI(w:int){
			var i:int;
			var line:Sprite;
			var next_y:int;
			var g:Graphics;
			
			_w = w;
			
			//put on the headers
			TFUtil.prepTF(title_tf, false);
			title_tf.htmlText = '<p class="leaderboard_title">Leaderboard</p>';
			addChild(title_tf);
			
			next_y += title_tf.height;
			
			TFUtil.prepTF(contributions_left, false);
			contributions_left.htmlText = '<p class="leaderboard_contribution_header">Contributions</p>';
			contributions_left.x = CONTRIBUTIONS_LEFT_HEADER_X;
			contributions_left.y = int(title_tf.y + title_tf.height - contributions_left.height) - 4;
			addChild(contributions_left);
			
			TFUtil.prepTF(contributions_right, false);
			contributions_right.htmlText = '<p class="leaderboard_contribution_header">Contributions</p>';
			contributions_right.x = int(_w - 8 - contributions_right.width);
			contributions_right.y = int(title_tf.y + title_tf.height - contributions_left.height) - 4;
			addChild(contributions_right);
			
			//place the lines
			for(i = 0; i <= MAX_POSITIONS/2; i++){
				line = new Sprite();
				line.y = next_y;
				
				g = line.graphics;
				g.beginFill(0xd0d3d3);
				g.drawRect(0, 0, _w, 1);
				g.beginFill(0xffffff);
				g.drawRect(0, 1, _w, 1);
				
				next_y += GAP;
				
				addChild(line);
			}
		}
		
		public function show(leaderboard:Leaderboard):void {
			if(!leaderboard) return;
			
			this.leaderboard = leaderboard;
			
			var i:int;
			var total:uint = leaderboard.entries.length;
			var entry:LeaderboardEntry;
			var next_x:int;
			var top_y:int = int(title_tf.height) + 9;
			var next_y:int = top_y;
			var my_position:int = (leaderboard.my_entry ? leaderboard.my_entry.position : 0);
			var show_my_entry:Boolean;
			var element:LeaderboardElementUI;
			
			//show the left if we need to
			contributions_left.visible = total > MAX_POSITIONS/2;
			
			//hide the current elements
			for(i = 0; i < elements.length; i++){
				element = elements[int(i)];
				element.y = 0;
				element.visible = false;
			}
			
			for(i = 0; i < total; i++){
				entry = !show_my_entry ? leaderboard.entries[int(i)] : leaderboard.my_entry;
				
				//reuse
				if(elements.length > i){
					element = elements[int(i)];
				}
				//new one
				else {
					element = new LeaderboardElementUI();
					elements.push(element);
					addChild(element);
				}
				
				element.visible = true;
				element.show(
					entry, 
					total > MAX_POSITIONS/2
					? int(contributions_left.x + contributions_left.width/2)
					: int(contributions_right.x + contributions_right.width/2),
					my_position
				);
				
				//time to wrap?
				if(i == MAX_POSITIONS/2){
					next_x = int(contributions_right.x + contributions_right.width/2 - (element.contribution_tf.x + element.contribution_tf.width/2)) + 2; //+2 to make it pretty
					next_y = top_y;
				}
				
				element.x = next_x;
				element.y = next_y;
				
				next_y += GAP;
			}
			
			//let's see if we are even on the board
			if(!show_my_entry && my_position > total){
				entry = leaderboard.my_entry;
				show_my_entry = true;
				
				//reuse
				if(elements.length > i){
					element = elements[int(i)];
				}
				//new one
				else {
					element = new LeaderboardElementUI();
					elements.push(element);
					addChild(element);
				}
				
				element.visible = true;
				element.show(
					entry, 
					total > MAX_POSITIONS/2
					? int(contributions_left.x + contributions_left.width/2)
					: int(contributions_right.x + contributions_right.width/2),
					my_position
				);
				
				element.x = next_x;
				element.y = next_y;
			}
		}
	}
}