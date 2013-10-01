package com.tinyspeck.engine.data.client
{
	public class ScreenViewQueueVO
	{
		public var arg:Object;
		public var func:Function;
		public var requires_client_focus:Boolean;
		
		public function ScreenViewQueueVO(func:Function, arg:Object, requires_client_focus:Boolean)
		{
			this.func = func;
			this.arg = arg;
			this.requires_client_focus = requires_client_focus;
		}
	}
}