package com.tinyspeck.engine.data.client
{
	import flash.display.DisplayObject;

	public class ConfirmationDialogVO
	{
		public var title:String = 'Please Confirm!';
		public var txt:String;
		public var item_class:String = 'pet_rock';
		public var icon_state:String;
		public var callback:Function;
		public var choices:Array;
		public var escape_value:*;
		public var max_w:int; //override the width of the modal dialog
		public var graphic:DisplayObject; //will override the item_class if set
		
		public function ConfirmationDialogVO(callback:Function = null, txt:String = '', choices:Array = null, escape_value:* = null)
		{
			this.callback = callback;
			this.txt = txt;
			this.choices = choices;
			this.escape_value = escape_value;
		}
	}
}