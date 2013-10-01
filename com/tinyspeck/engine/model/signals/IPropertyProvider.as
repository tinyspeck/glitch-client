package com.tinyspeck.engine.model.signals
{
	public interface IPropertyProvider
	{
		function registerCBProp(callBack:Function, ... properties):void;
		function unRegisterCBProp(callBack:Function, ... properties):void;
		function triggerCBProp(triggerChildProperties:Boolean = false, triggerParentProperties:Boolean = false, ... properties):void;
		function triggerCBPropDirect(... properties):void;
	}
}