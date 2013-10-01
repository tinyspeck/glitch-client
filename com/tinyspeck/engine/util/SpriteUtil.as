package com.tinyspeck.engine.util
{
	
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.spritesheet.ISpriteSheetView;
	import com.tinyspeck.engine.spritesheet.SSViewSprite;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class SpriteUtil
	{
		public static const REGISTRATION_TOP_LEFT:String = 'top_left';
		public static const REGISTRATION_CENTER:String = 'center';

		CONFIG::debugging private static const mouse_events:Array = [
			MouseEvent.CLICK,
			MouseEvent.DOUBLE_CLICK,
			MouseEvent.MOUSE_DOWN,
			MouseEvent.MOUSE_MOVE,
			MouseEvent.MOUSE_OUT,
			MouseEvent.MOUSE_OVER,
			MouseEvent.MOUSE_UP,
			MouseEvent.MOUSE_WHEEL,
			MouseEvent.ROLL_OUT,
			MouseEvent.ROLL_OVER
		];
		
		/**
		 * This will clean and nullify children in the sprite so that they are marked for GC 
		 * @param sp - anything that has children you want to nullify
		 * @param start_index - where to start nulling the children
		 */		
		public static function clean(sp:Sprite, and_dispose:Boolean=true, start_index:int=0, func_with_child_param:Function=null):void {
			var child:DisplayObject;
			var g:Graphics = sp.graphics;
			CONFIG::debugging var str:String;
			g.clear();
			
			while(sp.numChildren > start_index){
				child = sp.getChildAt(start_index);
				
				if(func_with_child_param != null) func_with_child_param(child);
				
				// pass and_dispose as false if you do not want to dispose of children
				if (and_dispose) {
					if (child is ISpriteSheetView) {
						ISpriteSheetView(child).ss.removeViewSprite(child as SSViewSprite);
						CONFIG::debugging {
							if (Console.priOK('499')) {
								Console.info(
									'SpriteUtil.clean is ss.removeViewSpriteing a "'+StringUtil.getShortClassName(child)+'" at '+StringUtil.getCallerCodeLocation()
								);
							}
						}
					} else if (child is DisposableSprite) {
						CONFIG::debugging {
							if (Console.priOK('499')) {
								Console.info(
									'SpriteUtil.clean is disposing a "'+StringUtil.getShortClassName(child)+'" at '+StringUtil.getCallerCodeLocation()
								);
							}
						}
						DisposableSprite(child).dispose();
					}
				}
				
				CONFIG::debugging {
					str = '';
					for (var i:int;i<mouse_events.length;i++) {
						if (child.hasEventListener(mouse_events[i])) str+= ' '+mouse_events[i];
					}
					
					if (str) Console.warn(StringUtil.DOPath(child)+' has listeners:'+str);
				}
				
				// check it is still a parent, because some of the above funcs can remove it from it's parent
				if (child.parent == sp) sp.removeChild(child);
				child = null;
			}
		}
		
		/**
		 * Will shift the DO by half it's width/height if set to center 
		 * @param DO
		 * @param registration_point
		 */		
		public static function setRegistrationPoint(DO:DisplayObject, registration_point:String = SpriteUtil.REGISTRATION_CENTER):void {
			if(registration_point == REGISTRATION_CENTER){
				DO.x = int(-DO.width/2);
				DO.y = int(-DO.height/2);
			}
			else {
				DO.x = DO.y = 0;
			}
		}
		
		/**
		 * Show a 1px border on the object 
		 * @param sp
		 * @param color
		 * NOTE: this does NOT add to the outside, it's a 1px INNER border
		 */		
		public static function drawBorder(sp:Sprite, color:uint = 0xffcc00):void {
			var a:Number = .7;
			var w:Number = sp.width;
			var h:Number = sp.height;
			var g:Graphics = sp.graphics;
			g.clear();
			g.beginFill(color, a); //top
			g.drawRect(0, 0, w, 1);
			g.beginFill(color, a); //bottom
			g.drawRect(0, h-1, w, 1);
			g.beginFill(color, a); //left
			g.drawRect(0, 0, 1, h);
			g.beginFill(color, a); //right
			g.drawRect(w-1, 0, 1, h);
		}
	
		private static var re_pa_pt:Point = new Point();
		public static function reParentAtSameStagePosition(DO:DisplayObject, new_parent:DisplayObjectContainer):void {
			re_pa_pt.x = DO.x;
			re_pa_pt.y = DO.y;
			
			if (DO.parent) {
				re_pa_pt = new_parent.globalToLocal(DO.parent.localToGlobal(re_pa_pt));
			}
			
			DO.x = re_pa_pt.x;
			DO.y = re_pa_pt.y;
			
			new_parent.addChild(DO);
		}
		
		/**
		 * Returns the point in ancestor's coordinate space of the origin in
		 * child's coordinate space. I.e. The x/y of the child if it were a
		 * direct child of ancestor.
		 *
		 * Not fast, don't call it a lot (or cache the resulting 'm'). 
		 */
		public static function findCoordsOfChildInAncestor(child:DisplayObject, ancestor:DisplayObjectContainer):Point {
			CONFIG::debugging {
				if (!ancestor.contains(child)) {
					Console.error(ancestor+' does not contain '+child);
					return null;
				}
			}
			
			const m:Matrix = child.transform.matrix.clone();
			var p:DisplayObjectContainer = child.parent;
			while (p && p != ancestor) {
				m.concat(p.transform.matrix);
				p = p.parent;
			}
			
			return m.transformPoint(new Point(0, 0));
		}
		
		// return true if DOC == DO or if DOC is a parent (or parent.parent etc) od DO
		public static function isSelfOrDOCaParentOfDO(DOC:DisplayObject, DO:DisplayObject):Boolean {
			if (!DO) return false;
			if (!DO.parent) return false;
			if (!DOC) return false;
			if (!(DOC is DisplayObjectContainer)) return false;
			
			var DOC_CAST_AS_DOC:DisplayObjectContainer = DOC as DisplayObjectContainer;
			if (DOC_CAST_AS_DOC == DO) return true;
			
			var p:DisplayObjectContainer = DO.parent;
			while (p) {
				if (p == DOC_CAST_AS_DOC) return true;
				p = p.parent;
			}
			
			return false;
		}
		
		// used this to see if a DO has been flipped via the Flash IDE
		public static function isDOFlippedHorizontally(DO:DisplayObject):Boolean {
			return DO.transform.matrix.a / DO.scaleX == -1;
		}
		
		public static function findParentByClass(element:DisplayObject, clazz:Class):DisplayObjectContainer {
			if (!element) return null;
			if (element is clazz) return element as DisplayObjectContainer;
			var p:DisplayObjectContainer = element.parent;
			while (p) {
				if (p is clazz) return p;
				p = p.parent;
			}
			return null;
		}	
		
		/**
		 * Returns the exact bounds of non-transparent pixels of a DisplayObject
		 * (optionally in a given coordinate space).
		 */
		public static function getVisibleBounds(object:DisplayObject, targetCoordinateSpace:DisplayObject=null):Rectangle {
			try {
				const bounds:Rectangle = object.getBounds(null);
				const bmd:BitmapData = new BitmapData(bounds.width, bounds.height, true, 0x00000000);
				
				// find the top-left so we can correctly place this on a bitmap
				const m:Matrix = new Matrix(1, 0, 0, 1, -bounds.x, -bounds.y);
				bmd.draw(object, m);
				
				const colorBounds:Rectangle = bmd.getColorBoundsRect(0xFFFFFFFF, 0x000000, false);
				bmd.dispose();
			} catch (e:*) {
				// BitmapData likes to fail sometimes, just being cautious...
				return null;
			}
			
			// to account for any other transformations, find the TL and BR
			// in the target coordinate space and build a new rect from that
			if (targetCoordinateSpace) {
				var tl:Point = object.localToGlobal(bounds.topLeft);
				tl = targetCoordinateSpace.globalToLocal(tl);
				
				var br:Point = object.localToGlobal(new Point(bounds.x + colorBounds.width, bounds.y + colorBounds.height));
				br = targetCoordinateSpace.globalToLocal(br);
				
				colorBounds.offsetPoint(tl);
				colorBounds.width  = ((tl.x < br.x) ? (br.x - tl.x) : (tl.x - br.x));
				colorBounds.height = ((tl.y < br.y) ? (br.y - tl.y) : (tl.y - br.y));
			}
			
			return colorBounds;
		}
	}
}