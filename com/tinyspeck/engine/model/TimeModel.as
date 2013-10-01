package com.tinyspeck.engine.model
{
	import com.tinyspeck.engine.model.signals.AbstractPropertyProvider;
	import com.tinyspeck.engine.vo.GameTimeVO;
	
	public class TimeModel extends AbstractPropertyProvider
	{
		/** http://alpha.glitch.com/calendar/ CHANGE_FLAG **/
		public static const DAY_NAMES:Array = ['Hairday', 'Moonday','Twoday','Weddingday','Theday','Fryday','Standday','Fabday'];
		public static const MONTH_NAMES:Array = ['Primuary','Spork','Bruise','Candy','Fever','Junuary','Septa','Remember','Doom','Widdershins','Eleventy', 'Recurse'];
		public static const MONTH_LENGTHS:Array = [29,3,53,17,73,19,13,37,5,47,11,1];
		
		public var gameTime:GameTimeVO;
		
		public function TimeModel() {
			this.gameTime = new GameTimeVO();
		}
	}
}