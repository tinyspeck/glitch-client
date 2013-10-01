package com.tinyspeck.engine.view.geo {
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.data.location.Wall;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.Event;
	
	public class WallView extends SurfaceView implements ITipProvider {
		private static const BLACK:uint    = 0x000000;
		private static const LT_GRAY:uint  = 0x797979;
		private static const WHITE:uint    = 0xFFFFFF;
		private static const RED:uint      = 0xCC0000;
		private static const GREEN:uint    = 0x00CC00;
		
		private static const UPDATE_CHECKERS:BitmapData = new BitmapData(1, 10, false, WHITE);
		{ // static init
			UPDATE_CHECKERS.setPixel(0, 0, LT_GRAY);
			UPDATE_CHECKERS.setPixel(0, 1, LT_GRAY);
			UPDATE_CHECKERS.setPixel(0, 2, LT_GRAY);
			UPDATE_CHECKERS.setPixel(0, 3, LT_GRAY);
			UPDATE_CHECKERS.setPixel(0, 4, LT_GRAY);
		}
		
		public var wall:Wall;
		
		public function WallView(wall:Wall, loc_tsid:String):void {
			super(wall, loc_tsid);
			this.wall = wall;
			_orient = 'vert';
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
			if (wall.client::geo_was_updated) txt += ' (MODIFIED)';
			txt+= '<br>item:'+wall.item_perm+' (';
			
			if (wall.item_solid_from_left && wall.item_solid_from_right) {
				txt+= 'solid from both sides'
			} else if (wall.item_solid_from_left) {
				txt+= 'solid from left only'
			} else if (wall.item_solid_from_right) {
				txt+= 'solid from right only'
			} else {
				txt+= 'not solid at all'
			}
			
			txt+= ')<br>pc:'+wall.pc_perm+' (';
			
			if (wall.pc_solid_from_left && wall.pc_solid_from_right) {
				txt+= 'solid from both sides'
			} else if (wall.pc_solid_from_left) {
				txt+= 'solid from left only'
			} else if (wall.pc_solid_from_right) {
				txt+= 'solid from right only'
			} else {
				txt+= 'not solid at all'
			}
			txt+= ')';
			
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
		override public function syncRendererWithModel():void {
			super.syncRendererWithModel();
			
			var g:Graphics = _graphics.graphics;
			g.clear();
			
			//// draw border if we've been updated at runtime
			//if (wall.geo_was_updated && !CONFIG::locodeco) {
			//	const thickness:int = 6 +
			//		(((wall.pc_solid_from_left == wall.item_solid_from_left) &&
			//		  (wall.pc_solid_from_right == wall.item_solid_from_right))
			//			? 4 : 8);
			//	g.lineStyle(thickness);
			//	g.lineBitmapStyle(UPDATE_CHECKERS);
			//	g.moveTo(0, 6);
			//	g.lineTo(0, (wall.h - 6));
			//}
			
			if (wall.pc_solid_from_left == wall.item_solid_from_left) {
				// draw single left perm line
				g.lineStyle(2, (wall.pc_solid_from_left) ? RED : GREEN, 1);
				g.moveTo(-2, 0);
				g.lineTo(-2, wall.h);
			} else {
				// draw left pc perm
				g.lineStyle(2, (wall.pc_solid_from_left) ? RED : GREEN, 1);
				g.moveTo(-4, 0);
				g.lineTo(-4, wall.h);
				
				// draw left item perm
				g.lineStyle(2, (wall.item_solid_from_left) ? RED : GREEN, 1);
				g.moveTo(-2, 0);
				g.lineTo(-2, wall.h);
			}
			
			if (wall.pc_solid_from_right == wall.item_solid_from_right) {
				// draw single right perm
				g.lineStyle(2, (wall.pc_solid_from_right) ? RED : GREEN, 1);
				g.moveTo(2, 0);
				g.lineTo(2, wall.h);
			} else {
				// draw right item perm
				g.lineStyle(2, (wall.item_solid_from_right) ? RED : GREEN, 1);
				g.moveTo(2, 0);
				g.lineTo(2, wall.h);
				
				// draw right pc perm
				g.lineStyle(2, (wall.pc_solid_from_right) ? RED : GREEN, 1);
				g.moveTo(4, 0);
				g.lineTo(4, wall.h);
			}
			
			// draw a light line through it all
			g.lineStyle(2, WHITE, 1);
			g.moveTo(0, 0);
			g.lineTo(0, wall.h);
			
			// draw end points
			g.lineStyle(2, BLACK, 1);
			g.moveTo(-4, 0);
			g.lineTo(4, 0);
			g.moveTo(-4, wall.h);
			g.lineTo(4, wall.h);
			
			// create a larger surface for click detection in locodeco
			g.lineStyle(15, 0, 0);
			g.moveTo(0, 0);
			g.lineTo(0, wall.h);
		}
	}
}
