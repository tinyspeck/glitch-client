package com.tinyspeck.engine.view
{
	import net.hires.debug.Stats;

	public interface IMainView
	{
		function primePerformanceGraph():void;
		function get performanceGraph():Stats;
		function get assetDetailsForBootError():String;
		function get currentRendererForBootError():String;
		function get engineVersion():String;
		function set performanceGraphVisible(viz:Boolean):void;
		function get performanceGraphVisible():Boolean;
		function get assetLoadingReport():String;
	}
}