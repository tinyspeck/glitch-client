package com.tinyspeck.engine.util
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;

	public class SWFUtil
	{
		public static function introspectDisplayObject(displayObject:DisplayObject):void
		{
			CONFIG::debugging {
				trace("Showing data for "+displayObject);
			}
			recurseDisplayObject(displayObject,0);
		}
		
		public static function recurseDisplayObject(displayObject:DisplayObject, depth:int, total:int = 0):int
		{
			var spaces:String = " ";
			var j:int = depth;
			while(j--){
				spaces += " ";
			}
			spaces +=">";
			if(displayObject is DisplayObjectContainer){
				var displayObjectContainer:DisplayObjectContainer = displayObject as DisplayObjectContainer;
				var l:int = displayObjectContainer.numChildren;
				if(displayObjectContainer is MovieClip){
					var mc:MovieClip = displayObjectContainer as MovieClip;
					mc.cacheAsBitmap = true;
					//mc.gotoAndStop(1);
				}
				for(var i:int=0; i<l; i++){
					CONFIG::debugging {
						trace(spaces+displayObjectContainer.getChildAt(i));
					}
					total = recurseDisplayObject(displayObjectContainer.getChildAt(i),depth+1,total++);
				}
			}else{
				; // satisfy compiler
				CONFIG::debugging {
					trace(spaces,displayObject);
				}
			}
			return total;
		}
	}
}