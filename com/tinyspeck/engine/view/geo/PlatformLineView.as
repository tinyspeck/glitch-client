package com.tinyspeck.engine.view.geo
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.data.location.AbstractPositionableLocationEntity;
	import com.tinyspeck.engine.data.location.PlatformLine;
	import com.tinyspeck.engine.data.location.PlatformLinePoint;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.renderer.IAbstractDecoRenderer;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.Event;
	
	public class PlatformLineView extends TSSpriteWithModel implements ITipProvider, IAbstractDecoRenderer
	{
		private static const BLACK:uint    = 0x000000;
		private static const DK_GRAY:uint  = 0x222222;
		private static const LT_GRAY:uint  = 0x797979;
		private static const WHITE:uint    = 0xFFFFFF;
		private static const RED:uint      = 0xCC0000;
		private static const GREEN:uint    = 0x00CC00;
		private static const DK_GREEN:uint = 0x008800;
		
		private static const UPDATE_CHECKERS:BitmapData = new BitmapData(10, 1, false, WHITE);
		{ // static init
			UPDATE_CHECKERS.setPixel(0, 0, LT_GRAY);
			UPDATE_CHECKERS.setPixel(1, 0, LT_GRAY);
			UPDATE_CHECKERS.setPixel(2, 0, LT_GRAY);
			UPDATE_CHECKERS.setPixel(3, 0, LT_GRAY);
			UPDATE_CHECKERS.setPixel(4, 0, LT_GRAY);
		}
		
		private static const BAD_CHECKERS:BitmapData = new BitmapData(10, 1, false, WHITE);
		{ // static init
			BAD_CHECKERS.setPixel(0, 0, DK_GRAY);
			BAD_CHECKERS.setPixel(1, 0, DK_GRAY);
			BAD_CHECKERS.setPixel(2, 0, DK_GRAY);
			BAD_CHECKERS.setPixel(3, 0, DK_GRAY);
			BAD_CHECKERS.setPixel(4, 0, DK_GRAY);
		}
		
		private static const GOOD_CHECKERS:BitmapData = new BitmapData(10, 1, false, WHITE);
		{ // static init
			GOOD_CHECKERS.setPixel(0, 0, DK_GREEN);
			GOOD_CHECKERS.setPixel(1, 0, DK_GREEN);
			GOOD_CHECKERS.setPixel(2, 0, DK_GREEN);
			GOOD_CHECKERS.setPixel(3, 0, DK_GREEN);
			GOOD_CHECKERS.setPixel(4, 0, DK_GREEN);
		}
		
		public var platformLine:PlatformLine;
		
		public function PlatformLineView(platformLine:PlatformLine) {
			super(platformLine.tsid);
			this.platformLine = platformLine;
			syncRendererWithModel();
			CONFIG::debugging {
				addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
				addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage, false, 0, true);
			}
		}
		
		private function onAddedToStage(event:Event):void {
			TipDisplayManager.instance.registerTipTrigger(this);
		}
		
		private function onRemovedFromStage(event:Event):void {
			TipDisplayManager.instance.unRegisterTipTrigger(this);
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			var txt:String = 'DEBUG: '+tsid;
			if (platformLine.client::geo_was_updated) txt += ' (MODIFIED)';
			txt+= '<br>item:'+platformLine.platform_item_perm+' (';
			
			if (platformLine.item_solid_from_bottom && platformLine.item_solid_from_top) {
				txt+= 'solid from both sides'
			} else if (platformLine.item_solid_from_bottom) {
				txt+= 'solid from bottom only'
			} else if (platformLine.item_solid_from_top) {
				txt+= 'solid from top only'
			} else {
				txt+= 'not solid at all'
			}
			
			txt+= ')<br>pc:'+platformLine.platform_pc_perm+' (';
			
			if (platformLine.pc_solid_from_bottom && platformLine.pc_solid_from_top) {
				txt+= 'solid from both sides'
			} else if (platformLine.pc_solid_from_bottom) {
				txt+= 'solid from bottom only'
			} else if (platformLine.pc_solid_from_top) {
				txt+= 'solid from top only'
			} else {
				txt+= 'not solid at all'
			}
			txt+= ')';
			
			if (platformLine.is_for_placement) {
				txt+= '<br>FOR PLACEMENT (invoking:' + platformLine.placement_invoking_set + ', userdeco:' + platformLine.placement_userdeco_set + ')';
			}
			
			return {
				txt: txt,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER,
				placement: {
					x: StageBeacon.stage.mouseX,
					y: StageBeacon.stage.mouseY
				}
			}
		}
		
		/** from IDecoRendererContainer */
		CONFIG::locodeco private var _highlight:Boolean;
		CONFIG::locodeco public function get highlight():Boolean { return _highlight; }
		CONFIG::locodeco public function set highlight(value:Boolean):void { _highlight = value; }
		
		/** from IDecoRendererContainer */
		public function syncRendererWithModel():void {
			// choose which side is the left
			var start:PlatformLinePoint;
			var end:PlatformLinePoint;
			if (platformLine.start.x < platformLine.end.x) {
				start = platformLine.start;
				end = platformLine.end;
			} else {
				start = platformLine.end;
				end = platformLine.start;
			}
			
			const g:Graphics = graphics;
			g.clear();
			
			//// draw border if we've been updated at runtime
			//if (platformLine.geo_was_updated && !CONFIG::locodeco) {
			//	// border line should be larger than the rest of the drawn line
			//	const thickness:int = 6 +
			//		(((platformLine.pc_solid_from_top == platformLine.item_solid_from_top) &&
			//		  (platformLine.pc_solid_from_bottom == platformLine.item_solid_from_bottom))
			//			? 2 : 4);
			//	g.lineStyle(thickness);
			//	g.lineBitmapStyle(UPDATE_CHECKERS);
			//	g.moveTo((start.x + 5), platformLine.yIntersection((start.x + 5)));
			//	g.lineTo((end.x - 5), platformLine.yIntersection((end.x - 5)));
			//}
			
			// draw the placement plane
			if (platformLine.is_for_placement && (platformLine.placement_plane_height !== 0)) {
				g.lineStyle(1, ((platformLine.placement_invoking_set || platformLine.placement_userdeco_set) ? DK_GREEN : DK_GRAY), 0.4, true);
				g.beginFill(((platformLine.placement_invoking_set || platformLine.placement_userdeco_set) ? DK_GREEN : DK_GRAY), 0.2);
				g.moveTo(start.x, start.y);
				g.lineTo(start.x, (start.y - platformLine.placement_plane_height));
				g.lineTo(end.x, (end.y - platformLine.placement_plane_height));
				g.lineTo(end.x, end.y);
				g.endFill();
			}
			
			if (platformLine.pc_solid_from_top == platformLine.item_solid_from_top) {
				// draw single pc/tiem perm line
				g.lineStyle(2, (platformLine.pc_solid_from_top) ? RED : GREEN, 1);
				g.moveTo(start.x, start.y-2);
				g.lineTo(end.x, end.y-2);
			} else {
				// draw top pc perm
				g.lineStyle(2, (platformLine.pc_solid_from_top) ? RED : GREEN, 1);
				g.moveTo(start.x, start.y-4);
				g.lineTo(end.x, end.y-4);
				
				// draw top item perm
				g.lineStyle(2, (platformLine.item_solid_from_top) ? RED : GREEN, 1);
				g.moveTo(start.x, start.y-2);
				g.lineTo(end.x, end.y-2);
			}
			
			if (platformLine.pc_solid_from_bottom == platformLine.item_solid_from_bottom) {
				// draw single pc/tiem perm line
				g.lineStyle(2, (platformLine.pc_solid_from_bottom) ? RED : GREEN, 1);
				g.moveTo(start.x, start.y+2);
				g.lineTo(end.x, end.y+2);
			} else {
				// draw bottom item perm
				g.lineStyle(2, (platformLine.item_solid_from_bottom) ? RED : GREEN, 1);
				g.moveTo(start.x, start.y+2);
				g.lineTo(end.x, end.y+2);
				
				// draw bottom pc perm
				g.lineStyle(2, (platformLine.pc_solid_from_bottom) ? RED : GREEN, 1);
				g.moveTo(start.x, start.y+4);
				g.lineTo(end.x, end.y+4);
			}
			
			if (platformLine.is_for_placement) {
				g.lineStyle(2);
				if (platformLine.placement_invoking_set || platformLine.placement_userdeco_set) {
					// draw a checkered dark line through it all
					g.lineBitmapStyle(GOOD_CHECKERS);
				} else {
					// draw a checkered dark line through it all
					g.lineBitmapStyle(BAD_CHECKERS);
				}
				g.moveTo(start.x, start.y);
				g.lineTo(end.x, end.y);
			} else {
				// draw a light line through it all
				g.lineStyle(2, WHITE, 1);
				g.moveTo(start.x, start.y);
				g.lineTo(end.x, end.y);
			}
			
			// draw end points
			g.lineStyle(2, BLACK, 1);
			g.moveTo(start.x, start.y-6);
			g.lineTo(start.x, start.y+6);
			g.moveTo(end.x, end.y-6);
			g.lineTo(end.x, end.y+6);
			
			// create a larger invisible surface for click detection in locodeco
			g.lineStyle(15, 0, 0);
			g.moveTo(start.x, start.y);
			g.lineTo(end.x, end.y);
		}
		
		/** from IDecoRendererContainer */
		public function getModel():AbstractPositionableLocationEntity {
			return platformLine;
		}
		
		/** from IDecoRendererContainer */
		public function getRenderer():DisplayObject {
			return this;
		}
	}
}
