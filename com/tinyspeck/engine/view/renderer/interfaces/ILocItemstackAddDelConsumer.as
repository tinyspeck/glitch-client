package com.tinyspeck.engine.view.renderer.interfaces
{
	public interface ILocItemstackAddDelConsumer
	{
		function onLocItemstackAdds(tsids:Array):void;
		function onLocItemstackDels(tsids:Array):void;
	}
}