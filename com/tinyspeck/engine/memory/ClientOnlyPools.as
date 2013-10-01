package com.tinyspeck.engine.memory
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.view.renderer.DecoRenderer;
	
	import de.polygonal.core.ObjectPool;
	
	/**
	 * Objects taken from a pool are automatically reset to defaults. 
	 * 
	 * IMPORTANT!!!
	 * Pools objects which reference the model, and is only to be used in the Client (e.g. not Vanity)
	 */
	public class ClientOnlyPools
	{
		private static const pools:Array = [];
		
		public static var DecoRendererPool:ObjectPool;
		
		public function ClientOnlyPools() {
			//
		}
		
		public static function init():void {
			// keep one DecoRenderer (only one is ever used at a time in testing)
			// grows because RTEs are occurring that prevent the pooled object from being returned
			// we'll just have to track if this pool gets too large...
			DecoRendererPool = new ObjectPool(true);
			DecoRendererPool.allocate(DecoRenderer, 1, NaN, resetDecoRenderer);
			pools.push(DecoRendererPool);
			
			CONFIG::debugging {
				StageBeacon.setInterval(reportPoolSizes, 15000);
			}
		}
		
		CONFIG::debugging private static function reportPoolSizes():void {
			Console.log(6, memReport());
		}
		
		/* CONFIG::god */ public static function memReport():String {
			var pool:ObjectPool;
			var str:String = '\nClientOnlyPools memReport\n+--------------------------------------------------\n';
			
			str+= 'Active ClientOnlyPools:\n';
			pools.sortOn('size', Array.DESCENDING | Array.NUMERIC);
			for each (pool in pools) {
				if (pool.usedCount) {
					str+= pool.toString()+'\n'
				}
			}				
			
			return str;
		}

		private static function resetDecoRenderer(obj:DecoRenderer):void {
			obj.reset();
		}
	}
}
