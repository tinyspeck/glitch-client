package com.tinyspeck.engine.event
{
	import org.osflash.signals.ISignal;

	public interface IMouseEventSignalRelay
	{
		function get mouseClicked():ISignal;
	}
}