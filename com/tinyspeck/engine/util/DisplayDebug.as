package com.tinyspeck.engine.util
{
	import com.tinyspeck.debug.Console;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.geom.Rectangle;
	import flash.text.TextLineMetrics;
	import flash.utils.getQualifiedClassName;

	public class DisplayDebug
	{
		private static var first:DisplayObject;
		
		CONFIG::debugging public static function logLineMetrics(metrics:TextLineMetrics):void {
			Console.info(
				'\n'+
				'ascent:' + metrics.ascent+'\n'+
            	'descent:' + metrics.descent+'\n'+
            	'leading:' + metrics.leading+'\n'+
            	'width:' + metrics.width+'\n'+
            	'height:' + metrics.height+'\n'+
            	'x:' + metrics.x
			)
		}
		
		public static function traceDisplayList(root:DisplayObject):void
		{
			first = root;
			traverseChild(root,0);
		}
		
		private static function traverseChild(displayObject:DisplayObject,depth:int):void
		{
			var p:DisplayObject;
			var debugString:String = displayObject.name +" "+displayObject;
			if(displayObject != first){
				p = displayObject.parent;
				while(p && p != first){
					debugString = p+">"+debugString;
					p = p.parent;
				}
			}
			CONFIG::debugging {
				trace(debugString,displayObject.cacheAsBitmap,displayObject.scrollRect);
			}
			displayObject.cacheAsBitmap = false;
			if(displayObject is DisplayObjectContainer)
			{
				var displayObjectContainer:DisplayObjectContainer = displayObject as DisplayObjectContainer;
				var numChildren:int = displayObjectContainer.numChildren;
				for(var i:int = 0; i<numChildren; i++){
					traverseChild(displayObjectContainer.getChildAt(i),depth+1);
				}
			}
		}
		
		public static function LogParents(DO:DisplayObject):void {
			var txt:String = '['+getQualifiedClassName(DO)+'] '+DO.name+'\n';
			while (DO.parent) {
				txt+= '['+getQualifiedClassName(DO.parent)+'] '+DO.parent.name+'\n';
				DO = DO.parent;
			}
			CONFIG::debugging {
				Console.info('LogParents:\n'+txt);
			}
		}
		
		public static function removeMasks(DO:DisplayObject, max_level:int=1000):String {
			function deepRemoveMask(obj:DisplayObject, max_level:int=10, level:int=0):String {
				var tabs:String = "";
				var str:String = '';
				for (var i:int = 0; i < level; i++, tabs += "-"){};
				if (!obj ) {
					str = tabs+'NO OBJ?\n';
				} else {
					var classname:String = getQualifiedClassName(obj);
					if (classname.indexOf('::') > -1) classname = classname.split('::')[1];
					
					if (obj.mask) {
						str = tabs+'x:'+obj.x+' y:'+obj.y+' scaleX:'+obj.scaleX+' scaleY:'+obj.scaleY+' w:'+obj.width+' h:'+obj.height+' sr:'+obj.scrollRect+' cacheAsBitmap:'+obj.cacheAsBitmap+' name:'+obj.name+' '+classname+' mask:'+obj.mask+'\n'

						obj.mask = null;
					}
					if (level < max_level && obj.hasOwnProperty('numChildren')) {
						for (var k:int;k<DisplayObjectContainer(obj).numChildren;k++) {
							str+= deepRemoveMask(DisplayObjectContainer(obj).getChildAt(k), max_level, level+1);
						}
					}
				}
				
				return str;
			}
			if (!DO) {
				CONFIG::debugging {
					Console.info('null DO');
				}
				return 'null DO';
			}
			CONFIG::debugging {
				Console.info('\n'+deepRemoveMask(DO, max_level));
			}
			
			return deepRemoveMask(DO, max_level);
		}
		
		public static function LogCoords(DO:DisplayObject, max_level:int=1000, simple:Boolean=false):String {
			function deepTrace(obj:DisplayObject, max_level:int=10, level:int=0):String {
				var tabs:String = "";
				var str:String;
				for (var i:int = 0; i < level; i++, tabs += "-"){};
				if (!obj ) {
					str = tabs+'NO OBJ?\n';
				} else {
					var classname:String = getQualifiedClassName(obj);
					if (classname.indexOf('::') > -1) classname = classname.split('::')[1];
					if (simple) {
						var b:Rectangle = obj.getBounds(DO);
						str = tabs+(!obj.visible?'HIDDEN ':'')+'name:'+obj.name+' '+classname+(obj.mask?' MASKED':'')+' getBounds:'+b+' x:'+obj.x+' y:'+obj.y+'\n'
					} else {
						str = tabs+'x:'+obj.x
							+' y:'+obj.y
							+' blendMode:'+obj.blendMode
							+' alpha:'+obj.alpha
							+' vis:'+obj.visible
							+' scaleX:'+obj.scaleX
							+' scaleY:'+obj.scaleY
							+' w:'+obj.width
							+' h:'+obj.height
							+' sr:'+obj.scrollRect
							+' cacheAsBitmap:'+obj.cacheAsBitmap
							+((obj is DisplayObjectContainer)?' mouseEnabled:'+DisplayObjectContainer(obj).mouseEnabled : '')
							+((obj is DisplayObjectContainer)?' mouseChildren:'+DisplayObjectContainer(obj).mouseChildren : '')
							+' name:'+obj.name
							+' '+classname
							+' mask:'+obj.mask+'\n'
					}
					if (level < max_level && obj.hasOwnProperty('numChildren')) {
						for (var k:int;k<DisplayObjectContainer(obj).numChildren;k++) {
							str+= deepTrace(DisplayObjectContainer(obj).getChildAt(k), max_level, level+1);
						}
					}
				}
				
				return str;
			}
			if (!DO) {
				CONFIG::debugging {
					Console.info('null DO');
				}
				return 'null DO';
			}
			CONFIG::debugging {
				Console.info('\n'+deepTrace(DO, max_level));
			}
			
			return deepTrace(DO, max_level);
		}
		
		public static function drawRects(DO:DisplayObject, max_level:int=1000):void {
			
			function deepTrace(obj:DisplayObject, max_level:int=10, level:int=0):void {
				if (obj) {
					var b:Rectangle = obj.getBounds(DO);
					g.drawRect(b.x, b.y, b.width, b.height);
					if (level < max_level && obj.hasOwnProperty('numChildren')) {
						for (var k:int;k<DisplayObjectContainer(obj).numChildren;k++) {
							deepTrace(DisplayObjectContainer(obj).getChildAt(k), max_level, level+1);
						}
					}
				}
				
				return;
			}
			
			if (!DO) {
				return;
			}

			var g:Graphics;
			if (!DO.hasOwnProperty('graphics')) {
				return;
			}
			
			g = DO['graphics'];
			g.clear();
			g.lineStyle(0, 0xcc0000, 1);
			
			deepTrace(DO, max_level);
			return
		}
		
		
	}
}