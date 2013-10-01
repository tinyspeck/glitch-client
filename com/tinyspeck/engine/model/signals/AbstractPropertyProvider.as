package com.tinyspeck.engine.model.signals
{
	public class AbstractPropertyProvider implements IPropertyProvider
	{
		// we don't ever return these to the pool, so don't borrow from it
		//mainPVL = EnginePools.PropertyProviderLinkPool.borrowObject();
		private const mainPVL:PropertyProviderLink = new PropertyProviderLink();
		
		public function AbstractPropertyProvider()
		{
			mainPVL.initWith("this", this, null);
		}
		
		public function registerCBProp(callBack:Function, ... properties):void
		{
			mainPVL.registerCBProp(callBack, properties);
		}
		
		public function unRegisterCBProp(callBack:Function, ... properties):void
		{
			mainPVL.unRegisterCBProp(callBack, properties);
		}
				
		public function triggerCBProp(triggerChildProperties:Boolean = false, triggerParentProperties:Boolean = false, ... properties):void
		{
			mainPVL.triggerCBProp(triggerChildProperties, triggerParentProperties, properties);
		}
		
		public function triggerCBPropDirect(... properties):void
		{
			mainPVL.triggerCBProp(false, false, properties);
		}
	}
}