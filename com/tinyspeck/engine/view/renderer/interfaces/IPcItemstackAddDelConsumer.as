package com.tinyspeck.engine.view.renderer.interfaces
{
	public interface IPcItemstackAddDelConsumer
	{
		function onPcItemstackAdds(tsids:Array):void;
		function onPcItemstackDels(tsids:Array):void;
	}
}