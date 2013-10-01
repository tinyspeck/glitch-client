package com.tinyspeck.engine.port
{
	public interface IStatBurstChange
	{
		function onStatBurstChange(stat_burst:StatBurst, value:int):void;
	}
}