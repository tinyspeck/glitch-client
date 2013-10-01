package com.tinyspeck.engine.view.ui.chrome
{
	import com.tinyspeck.engine.model.TSEngineConstants;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class PlayerStatsUI extends Sprite
	{
		private static const WIDTH:uint = 93;
		private static const LINE_Y:int = 45;
		
		private var level_label_tf:TextField = new TextField();
		private var level_tf:TextField = new TextField();
		private var iMG_tf:TextField = new TextField();
		private var iMG_i_tf:TextField = new TextField();
		private var iMG_next_tf:TextField = new TextField();
		private var mood_label_tf:TextField = new TextField();
		private var mood_tf:TextField = new TextField();
		private var energy_label_tf:TextField = new TextField();
		private var energy_tf:TextField = new TextField();
		private var currants_label_tf:TextField = new TextField();
		private var currants_tf:TextField = new TextField();
		
		private var current_energy:Number;
		private var current_energy_max:Number;
		private var current_mood:Number;
		private var current_mood_max:Number;
		
		public function PlayerStatsUI(){
			//level
			TFUtil.prepTF(level_label_tf, false);
			level_label_tf.htmlText = '<p class="player_stats">Level:</p>';
			level_label_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			level_label_tf.x = 2;
			addChild(level_label_tf);
			
			TFUtil.prepTF(level_tf, false);
			level_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			level_tf.y = int(level_label_tf.y + level_label_tf.height - 8);
			addChild(level_tf);
			
			//iMG
			TFUtil.prepTF(iMG_i_tf, false);
			iMG_i_tf.htmlText = '<p class="player_stats"><span class="player_stats_iMG"><span class="player_stats_i">i</span></span></p>';
			iMG_i_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			iMG_i_tf.x = int(WIDTH - iMG_i_tf.width + 4);
			iMG_i_tf.y = 10;
			addChild(iMG_i_tf);
			
			TFUtil.prepTF(iMG_tf, false);
			iMG_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			iMG_tf.autoSize = TextFieldAutoSize.RIGHT;
			iMG_tf.x = iMG_i_tf.x - 1;
			iMG_tf.y = iMG_i_tf.y;
			addChild(iMG_tf);
			
			imagination_next = 9999; //to set Y stuff
			
			TFUtil.prepTF(iMG_next_tf, false);
			iMG_next_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			iMG_next_tf.autoSize = TextFieldAutoSize.RIGHT;
			iMG_next_tf.x = WIDTH;
			iMG_next_tf.y = int(iMG_tf.y + iMG_tf.height - 4);
			addChild(iMG_next_tf);
			
			//mood
			TFUtil.prepTF(mood_label_tf, false);
			mood_label_tf.htmlText = '<p class="player_stats">Mood:</p>';
			mood_label_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			mood_label_tf.y = LINE_Y + 5;
			addChild(mood_label_tf);
			
			TFUtil.prepTF(mood_tf, false);
			mood_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			mood_tf.autoSize = TextFieldAutoSize.RIGHT;
			mood_tf.x = WIDTH;
			mood_tf.y = mood_label_tf.y - 1;
			addChild(mood_tf);
			
			//energy
			TFUtil.prepTF(energy_label_tf, false);
			energy_label_tf.htmlText = '<p class="player_stats">Energy:</p>';
			energy_label_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			energy_label_tf.y = int(mood_label_tf.y + mood_label_tf.height - 2);
			addChild(energy_label_tf);
			
			TFUtil.prepTF(energy_tf, false);
			energy_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			energy_tf.autoSize = TextFieldAutoSize.RIGHT;
			energy_tf.x = WIDTH;
			energy_tf.y = energy_label_tf.y - 1;
			addChild(energy_tf);
			
			//draw the divider lines
			var g:Graphics = graphics;
			g.beginFill(0xc7d4d8);
			g.drawRect(0, LINE_Y, WIDTH + 4, 1);
			g.beginFill(0xeef2f3);
			g.drawRect(0, LINE_Y+1, WIDTH + 4, 1);
			
			//one for the currants too
			const currants_y:int = int(energy_label_tf.y + energy_label_tf.height + 4);
			g.beginFill(0xc7d4d8);
			g.drawRect(0, currants_y, WIDTH + 4, 1);
			g.beginFill(0xeef2f3);
			g.drawRect(0, currants_y+1, WIDTH + 4, 1);
			
			TFUtil.prepTF(currants_label_tf, false);
			currants_label_tf.htmlText = '<p class="player_stats">Currants:</p>';
			currants_label_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			currants_label_tf.y = currants_y + 8;
			addChild(currants_label_tf);
			
			TFUtil.prepTF(currants_tf, false);
			currants_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			addChild(currants_tf);
		}
		
		public function set energy(value:Number):void {
			current_energy = value;
			setEnergyText();
		}
		
		public function set energy_max(value:Number):void {
			current_energy_max = value;
			setEnergyText();
		}
		
		private function setEnergyText():void {
			energy_tf.htmlText = '<p class="player_stats"><span class="player_stats_current">'+current_energy+'</span>/'+current_energy_max+'</p>';
		}
		
		public function set mood(value:Number):void {
			current_mood = value;
			setMoodText();
		}
		
		public function set mood_max(value:Number):void {
			current_mood_max = value;
			setMoodText();
		}
		
		private function setMoodText():void {
			mood_tf.htmlText = '<p class="player_stats"><span class="player_stats_current">'+current_mood+'</span>/'+current_mood_max+'</p>';
		}
		
		public function set imagination_next(value:Number):void {
			iMG_tf.htmlText = '<p class="player_stats"><span class="player_stats_iMG">'+StringUtil.formatNumberWithCommas(value)+'</span></p>';
		}
		
		public function set level(value:Number):void {
			level_tf.htmlText = '<p class="player_stats"><span class="player_stats_level">'+value+'</span></p>';
			level_tf.x = int(level_label_tf.x + (level_label_tf.width/2 - level_tf.width/2 - 2));
			
			//set the 'til next level text
			const iMG_visible:Boolean = value < TSEngineConstants.MAX_LEVEL;
			iMG_tf.visible = iMG_visible;
			iMG_i_tf.visible = iMG_visible;
			iMG_next_tf.visible = iMG_visible;
			iMG_next_tf.htmlText = '<p class="player_stats">’til level '+(value+1)+'</p>';
		}
		
		public function set currants(value:Number):void {
			currants_tf.scaleX = currants_tf.scaleY = 1;
			currants_tf.htmlText = '<p class="player_stats"><span class="player_stats_current">'+StringUtil.formatNumberWithCommas(value)+'</span></p>';
			
			//if we have too damn many, scale it down
			const max_w:int = WIDTH - currants_label_tf.width;
			if(currants_tf.width > max_w){
				currants_tf.scaleX = currants_tf.scaleY = max_w/currants_tf.width;
			}
			
			//place it
			currants_tf.x = int(WIDTH - currants_tf.width + 4);
			currants_tf.y = int(currants_label_tf.y + (currants_label_tf.height/2 - currants_tf.height/2));
		}
	}
}