package com.tinyspeck.engine.data.chat
{
	public class InputHistory
	{
		public static const MAX_ELEMENTS:uint = 300;
		
		public var tsid:String;
		public var history_index:int;
		public var elements:Vector.<String> = new Vector.<String>();
		
		public function InputHistory(tsid:String){
			this.tsid = tsid;
		}
	}
}