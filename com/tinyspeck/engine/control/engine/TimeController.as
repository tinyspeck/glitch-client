package com.tinyspeck.engine.control.engine
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.control.IController;
	import com.tinyspeck.engine.model.TimeModel;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.vo.GameTimeVO;
	
	public class TimeController extends AbstractController implements IController
	{
		private static const SPEED_MULTIPLIER:Number = 6; //how much faster are game days vs. real days
		private static const GAME_EPOCH:Number = 7431372000 / SPEED_MULTIPLIER;
		private static const YEAR_SECS:Number = 26611200 / SPEED_MULTIPLIER;
		private static const DAY_SECS:Number = 86400 / SPEED_MULTIPLIER;
		private static const HOUR_SECS:Number = 3600 / SPEED_MULTIPLIER;
		private static const MIN_SECS:Number = 60 / SPEED_MULTIPLIER;
		
		private var _diff_ts:Number = 0; // seconds!
				
		public function TimeController() {
			//
		}
		
		override public function run():void	{
			//
		}
		
		public function init():void {
			//
		}
		
		// takes the GS time stamp and calcs offset, and starts timers
		public function start(ts:int):void {
			var now_ts:Number = new Date().getTime();
			_diff_ts = Math.round(now_ts/1000)-int(ts); // how many seconds are our local timestamps off from the server's
			_announceGameTime();
			StageBeacon.setInterval(_announceGameTime, Math.max(500, int((MIN_SECS/60) * 10000))); // every game second, don't update any faster than .5 real seconds
		}

		/** The GameTimeVO model isn't updated in realtime; this forces an update synchronously */
		public function forceUpdateGameTimeVO():void {
			get_dametime_parts_for_header(model.timeModel.gameTime);
		}
		
		private function _announceGameTime():void {
			get_dametime_parts_for_header(model.timeModel.gameTime);
			model.timeModel.triggerCBProp(true,false,"gameTime");
		}
		
		public function getGameTime(timestamp:int = 0):String {
			return format_gametime(timestamp_to_gametime(_calculateCorrectedTS(timestamp)));
		}
		
		public function getGameTimeFromUnixTimestamp(timestamp:int):String {
			return format_gametime(timestamp_to_gametime(timestamp));
		}
		
		public function getCurrentGameTimeInUnixTimestamp():int {
			return _calculateCorrectedTS();
		}
		
		// this takes a local timestamp and corrects it based on the differences in timestamps we calculated in start, to get +- exactly the GS game time
		private function _calculateCorrectedTS(ts:Number = 0):Number {
			ts = ts || new Date().getTime();
			return Math.round(ts/1000)-_diff_ts;
		}
		
		// FROM CAL
		private function timestamp_to_gametime(ts:int):Array {
			
			//
			// how many real seconds have elapsed since game epoch?
			//
			var sec:int = ts - GAME_EPOCH;
			//
			// there are 4435200 real seconds in a game year
			// there are 14400 real seconds in a game day
			// there are 600 real seconds in a game hour
			// there are 10 real seconds in a game minute
			//
			var y:int = Math.floor(sec / YEAR_SECS);
			sec -= y * YEAR_SECS;
			var d:int = Math.floor(sec / DAY_SECS);
			sec -= d * DAY_SECS;
			var h:int = Math.floor(sec / HOUR_SECS);
			sec -= h * HOUR_SECS;
			var i:int = Math.floor(sec / MIN_SECS);
			sec -= i * MIN_SECS;
			//
			// turn the 0-based day number into a day & month
			//
			var md:Array = calendar__day_to_md(d);
			var dm:int = md[1]; // day of month
			var m:int = md[0];
			
			//make sure that the minutes never go over 60
			i = i % 60;
			
			return [y,m,dm,h,i,d]; // d is day of year //TODO : spawning an anonymous array. Not necessary.
		}
		
		// FROM CAL
		private function calendar__day_to_md(id:int):Array
		{
			var months:Array = TimeModel.MONTH_LENGTHS;
			var cd:int = 0;
			for (var i:int=0; i<months.length; i++){
				cd += months[int(i)];
				if (cd > id){
					var m:int = i+1;
					var d:int = id+1 - (cd - months[int(i)]);
					return [m,d];
				}
			}
			return [0,0];
		}
		
		// FROM CAL
		private function format_gametime(gt:Array):String {
			var day_with_suffix:String = StringUtil.addSuffix(gt[2]);
						
			var dm:String = day_with_suffix+' of '+TimeModel.MONTH_NAMES[gt[1]-1]+', Year '+gt[0];
			if (gt[1]==12) dm = TimeModel.MONTH_NAMES[gt[1]-1];
			
			var i:String = ""+gt[4];
			if (i.length == 1) i = "0"+i;
			
			var t:String = gt[3]+':'+i+'am';
			if (gt[3] == 0) t = '12:'+i+'am';
			if (gt[3] == 12) t = '12:'+i+'pm';
			if (gt[3] > 12) t = (gt[3]-12)+':'+i+'pm';
			if (gt[3] == 0 && gt[4] == 0) t = 'midnight';
			if (gt[3] == 12 && gt[4] == 0) t = 'noon';
			
			return t+', '+dm;
		}
		
		// ADAPTED FROM CAL
		private function get_dametime_parts_for_header(target:GameTimeVO):void
		{
			var gt:Array = timestamp_to_gametime(_calculateCorrectedTS())
				
			// cal:
			// however, it should be simple to calculate days since epoch
			// day of year + (days in year * year)
			// and day of year is calced already, before it's turned into day + month
			
			var year:int = gt[0];
			var day_of_year:int = gt[5];
			var days_since_epoch:int = day_of_year + (307 * year);
			var day_of_week:int = days_since_epoch % 8;
			var day_with_suffix:String = StringUtil.addSuffix(gt[2]);
			
			target.string = format_gametime(gt);
			target.year = year;
			target.month_day = gt[2];
			target.month_day_with_suffix = day_with_suffix;
						
			target.month = TimeModel.MONTH_NAMES[gt[1]-1];
			target.week_day = TimeModel.DAY_NAMES[day_of_week];
			
			var i:String = ""+gt[4];
			if (i.length == 1) i = "0"+i;
			
			var t:String = gt[3]+':'+i;
			if (gt[3] == 0) t = '12:'+i;
			if (gt[3] == 12) t = '12:'+i;
			if (gt[3] > 12) t = (gt[3]-12)+':'+i;
			
			target.time = t;
			target.ampm = (gt[3] < 12) ? 'AM' : 'PM';
			
			//how much game/real time until the next new day
			var new_day:int = 86400; //a day total
			new_day -= (int(gt[3]) * 3600); //hours
			new_day -= (int(gt[4]) * 60); //mins
			
			var game_time:String = StringUtil.formatTime(new_day, false);
			target.game_time_until_new_day = game_time != '' ? game_time : 'Less than a minute';
			
			var real_time:String = StringUtil.formatTime(new_day/SPEED_MULTIPLIER, false);
			target.real_time_until_new_day = real_time != '' ? real_time : 'Less than a minute';
			
			target.string_long = target.time+' '+target.ampm.toLowerCase()+
				', '+target.week_day+
				' '+target.month_day_with_suffix+
				' of '+target.month+
				', year '+target.year;
			
			//Moonday, the 5th of Spork
			target.string_day_month = target.week_day+', the '+target.month_day_with_suffix+' of '+target.month;
		}
	}
}