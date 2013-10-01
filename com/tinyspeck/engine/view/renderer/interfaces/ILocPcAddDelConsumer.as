package com.tinyspeck.engine.view.renderer.interfaces
{
	public interface ILocPcAddDelConsumer
	{
		function onLocPcAdds(tsids:Array):void;
		function onLocPcDels(tsids:Array):void;
	}
}