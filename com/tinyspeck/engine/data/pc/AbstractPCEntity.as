package com.tinyspeck.engine.data.pc
{
	import com.tinyspeck.core.memory.IDisposable;
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	
	public class AbstractPCEntity extends AbstractTSDataEntity implements IDisposable
	{
		public function AbstractPCEntity(hashName:String)
		{
			super(hashName);
		}		
	}
}