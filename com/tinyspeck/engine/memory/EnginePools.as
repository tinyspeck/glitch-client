package com.tinyspeck.engine.memory
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.memory.EventListenerVO;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.model.signals.PropertyProviderLink;
	import com.tinyspeck.engine.spritesheet.SSAnimationCommand;
	import com.tinyspeck.engine.util.TFUtil;
	
	import de.polygonal.core.ObjectPool;
	
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	/**
	 * Objects taken from a pool are automatically reset to defaults. 
	 *
	 * Pools only objects that do not require references to the model,
	 * so it can be used in non-client apps like the Vanity. 
	 */
	public class EnginePools
	{
		private static const pools:Array = [];

		public static var SSAnimationCommandPool:ObjectPool;
		public static var PropertyProviderLinkPool:ObjectPool;
		public static var PointPool:ObjectPool;
		public static var MatrixPool:ObjectPool;
		public static var TextFieldPool:ObjectPool;
		public static var RectanglePool:ObjectPool;
		public static var EventListenerVOPool:ObjectPool;
		
		public function EnginePools() {
			//
		}
		
		public static function init():void {
			// grows dynamically since we use a variable amount
			PropertyProviderLinkPool = new ObjectPool(true);
			PropertyProviderLinkPool.allocate(PropertyProviderLink, 150, 50, PropertyProviderLink.resetInstance);
			pools.push(PropertyProviderLinkPool);
			
			// so far only DecoRenderers use this pool, so it's conservatively small
			// (and never more than one is used when SWF_bitmap_renderer=1)
			TextFieldPool = new ObjectPool(true);
			TextFieldPool.allocate(TextField, 5, 5, TFUtil.resetTF);
			pools.push(TextFieldPool);
			
			// grows dynamically since we use a variable amount
			EventListenerVOPool = new ObjectPool(true);
			EventListenerVOPool.allocate(EventListenerVO, 10000, 1000, EventListenerVO.resetInstance);
			pools.push(EventListenerVOPool);
			
			// keep two SSACs (only two are ever used at a time in testing)
			// grows because RTEs are occurring that prevent the pooled object from being returned
			// we'll just have to track if this pool gets too large...
			SSAnimationCommandPool = new ObjectPool(true);
			SSAnimationCommandPool.allocate(SSAnimationCommand, 2, NaN, SSAnimationCommand.resetInstance);
			pools.push(SSAnimationCommandPool);
			
			// keep six Points (only six is ever used at a time in testing)
			// grows because RTEs are occurring that prevent the pooled object from being returned
			// we'll just have to track if this pool gets too large...
			PointPool = new ObjectPool(true);
			PointPool.allocate(Point, 6, NaN, resetPoint);
			pools.push(PointPool);
			
			// keep three Matrixes (only three are currently used at a time in testing)
			// grows because RTEs are occurring that prevent the pooled object from being returned
			// we'll just have to track if this pool gets too large...
			MatrixPool = new ObjectPool(true);
			MatrixPool.allocate(Matrix, 3, NaN, resetMatrix);
			pools.push(MatrixPool);
			
			// keep two Rectangles (only two are ever used at a time in testing)
			// grows because RTEs are occurring that prevent the pooled object from being returned
			// we'll just have to track if this pool gets too large...
			RectanglePool = new ObjectPool(true);
			RectanglePool.allocate(Rectangle, 2, NaN, resetRectangle);
			pools.push(RectanglePool);
			
			CONFIG::debugging {
				StageBeacon.setInterval(reportPoolSizes, 15000);
			}
		}
		
		CONFIG::debugging private static function reportPoolSizes():void {
			Console.log(6, memReport());
		}
		
		/* CONFIG::god */ public static function memReport():String {
			var pool:ObjectPool;
			var str:String = '\nEnginePools memReport\n+--------------------------------------------------\n';
			
			str+= 'Active EnginePools:\n';
			pools.sortOn('size', Array.DESCENDING | Array.NUMERIC);
			for each (pool in pools) {
				if (pool.usedCount) {
					str+= pool.toString()+'\n'
				}
			}				
			
			return str;
		}
		
		private static function resetPoint(obj:Point):void {
			obj.x = 0;
			obj.y = 0;
		}
		
		private static function resetMatrix(obj:Matrix):void {
			obj.identity();
		}
		
		private static function resetRectangle(obj:Rectangle):void {
			obj.setEmpty();
		}
	}
}
