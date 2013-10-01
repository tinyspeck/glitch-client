package com.tinyspeck.engine.physics.util
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.location.MiddleGroundLayer;
	import com.tinyspeck.engine.data.location.PlatformLine;
	import com.tinyspeck.engine.data.location.PlatformLinePoint;
	import com.tinyspeck.engine.data.location.Wall;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.physics.colliders.ColliderLine;
	import com.tinyspeck.engine.physics.colliders.colliderLineFromPlatformLine;
	import com.tinyspeck.engine.util.geom.Line;
	import com.tinyspeck.engine.util.geom.LineClip;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class LocationPhysicsHealer
	{
		public static var SNAP_DISTANCE:int = 30;
		
		public static function init():void {
			SNAP_DISTANCE = TSModelLocator.instance.flashVarModel.snap_distance;
		}
		
		/**
		 * Brings platform lines within location bounds ONLY;
		 * returns true if changes were made.
		 */
		public static function fixupPlatformLines(location:Location, locodeco:Boolean=false):Boolean {
			const locRect:Rectangle = new Rectangle(location.l,location.t,location.r-location.l,location.b-location.t);
			
			var line:Line;
			var tempPlatLine:PlatformLinePoint;
			var platLine:PlatformLine;
			var somethingChanged:Boolean;
			
			for each (platLine in location.mg.platform_lines) {
				// If needed, flip the line so it's always left to right
				if(platLine.start.x > platLine.end.x) {
					somethingChanged = true;
					tempPlatLine = platLine.start;
					platLine.start = platLine.end;
					platLine.end = tempPlatLine;
				}
				
				if (!locodeco) continue;
				
				// Check if the line needs to be clipped to the location boundaries 
				if(!locRect.contains(platLine.start.x, platLine.start.y) || !locRect.contains(platLine.end.x, platLine.end.y)){
					line = new Line(platLine.start.x, platLine.start.y, platLine.end.x, platLine.end.y);
					line.clip(locRect);
					
					//TODO: reject zero-length lines. If LineClip is fixed, lines outside the rect will be zero-length.
					
					// LineClip will snap the line to the exact pixel boundaries of the rect
					// but Flash's contains() method considers some edges out of bounds;
					// so bring in the edges by one pixel towards the origin
					if ((line.x1 == locRect.left) || (line.x1 == locRect.right)) {
						somethingChanged = true;
						platLine.start.x = line.x1 + ((line.x1 < 0) ? 1 : -1);
					}
					if ((line.y1 == locRect.top) || (line.y1 == locRect.bottom)) {
						somethingChanged = true;
						platLine.start.y = line.y1 + ((line.y1 < 0) ? 1 : -1);
					}
					if ((line.x2 == locRect.left) || (line.x2 == locRect.right)) {
						somethingChanged = true;
						platLine.end.x = line.x2 + ((line.x2 < 0) ? 1 : -1);
					}
					if ((line.y2 == locRect.top)  || (line.y2 == locRect.bottom)) {
						somethingChanged = true;
						platLine.end.y = line.y2 + ((line.y2 < 0) ? 1 : -1);
					}
				}
			}
		
			return somethingChanged;
		}
		
		/**
		 * Snaps the given Point (Object containing 'x' and 'y' properties
		 * to any other platline point and wall endpoints
		 * within SNAP_DISTANCE.
		 * 
		 * Returns the snapped point or the original.
		 */
		public static function snapPointToPlatformLinesAndWalls(point:Object, is_for_placement:Boolean, platlines:Vector.<PlatformLine>, walls:Vector.<Wall>, snap_distance:int=0):Object {
			if (!snap_distance) snap_distance = SNAP_DISTANCE;
			
			const vTest:Point = new Point();
			const vOther:Point = new Point();
			var vRes:Point;
			
			var wall:Wall;
			var otherPlatformLine:PlatformLine;
			
			var i:int;
			for(i=walls.length-1; i>=0; --i){
				wall = walls[int(i)];
				
				// Pt->Top test
				vTest.x = point.x;
				vTest.y = point.y;
				vOther.x = wall.x;
				vOther.y = wall.y;
				vRes = vTest.subtract(vOther);
				if((vRes.length != 0) && (vRes.length < snap_distance)) {
					return new Point(wall.x, wall.y);
				}
				
				// Pt->Start test
				vTest.x = point.x;
				vTest.y = point.y;
				vOther.x = wall.x;
				vOther.y = wall.y+wall.h;
				vRes = vTest.subtract(vOther);
				if((vRes.length != 0) && (vRes.length < snap_distance)) {
					return new Point(wall.x, wall.y+wall.h);
				}
				
				// Pt->Anywhere on wall test
				vTest.x = point.x;
				vTest.y = point.y;
				vOther.x = wall.x;
				vOther.y = point.y;
				vRes = vTest.subtract(vOther);
				if((vRes.length != 0) && (vRes.length < snap_distance)) {
					// make sure it's actually ON the wall
					if ((vOther.y > wall.y) && (vOther.y < (wall.y + wall.h))) {
						return new Point(wall.x, point.y);
					}
				}
			}
			
			//Compare it against other platform lines, snap to them, if needed.
			for(i=platlines.length-1; i>=0; --i){
				otherPlatformLine = platlines[int(i)];
				
				// placement plats should not snap to normal plats (but should snap to walls)
				if (otherPlatformLine.is_for_placement != is_for_placement) continue;
				
				// Pt->End test
				vTest.x = point.x;
				vTest.y = point.y;
				vOther.x = otherPlatformLine.end.x;
				vOther.y = otherPlatformLine.end.y;
				vRes = vTest.subtract(vOther);
				if((vRes.length != 0) && (vRes.length < snap_distance)) {
					return new Point(otherPlatformLine.end.x, otherPlatformLine.end.y);
				}
				
				// Pt->Start test
				vTest.x = point.x;
				vTest.y = point.y;
				vOther.x = otherPlatformLine.start.x;
				vOther.y = otherPlatformLine.start.y;
				vRes = vTest.subtract(vOther);
				if((vRes.length != 0) && (vRes.length < snap_distance)) {
					return new Point(otherPlatformLine.start.x, otherPlatformLine.start.y);
				}
			}
			return point;
		}
		
		/** This generates a set of physics lines for the location */
		public static function generatePhysicsLines(location:Location):void {
			if(location.mg){
				var i:int;
				var length:int;
				var wall:Wall;
				var platformLines:Vector.<PlatformLine>;
				var platformLine:PlatformLine;
				var walls:Vector.<Wall>;
				var colliderLine:ColliderLine;
				const mg:MiddleGroundLayer = location.mg;
				const colliderLines:Vector.<ColliderLine> = new Vector.<ColliderLine>();
				mg.client::colliderLines = colliderLines;
				
				//Create walls and floors for entire location.
				const top_allowance:int = TSModelLocator.instance.physicsModel.location_top_allowance;
				
				//Left Wall
				colliderLine = new ColliderLine(location.l+1,location.t+1-top_allowance,location.l+1,location.b-1,10);
				colliderLine.pc_solid_from_right = true;
				colliderLines.push(colliderLine);
				
				//Right wall
				colliderLine = new ColliderLine(location.r-1,location.t+1-top_allowance,location.r-1,location.b-1,10);
				colliderLine.pc_solid_from_right = true;
				colliderLines.push(colliderLine);
				
				//Bottom
				colliderLine = new ColliderLine(location.l+1,location.b-1,location.r-1,location.b-1,10);
				colliderLine.pc_solid_from_top = true;
				colliderLines.push(colliderLine);
				
				//Top
				colliderLine = new ColliderLine(location.l+1,location.t+1-top_allowance,location.r-1,location.t+1-top_allowance,10);
				colliderLine.pc_solid_from_bottom = true;
				colliderLines.push(colliderLine);
				
				walls = mg.walls;
				length = walls.length;
				//Loop through walls, create collider lines for them
				
				const breathing_allowance:int = TSModelLocator.instance.physicsModel.location_breathing_allowance;
				
				var use_wall_y1:int;
				var use_wall_y2:int;
				for(i=0; i<length; i++){
					wall = walls[int(i)];
					
					// if the wall is close to top of location, let's assume that means the players are
					// not meant to be able to go over it and extend the collider location upward the max allowed
					if (wall.y-location.t <= 10) {
						// breathing_allowance is the amount we expand the mainNode rect in the quadtree, to allow for go things to be slightly out of bounds
						// we can't make the colliderline go more out of the location than breathing_allowance/2
						use_wall_y1 = location.t-(breathing_allowance/2);
						//Console.warn('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! '+wall.y+' -> '+use_wall_y1);
					} else {
						use_wall_y1 = wall.y;
					}
					
					// make sure we stay within the allowed breathing room
					use_wall_y1 = Math.max(use_wall_y1, location.t-(breathing_allowance/2));
					use_wall_y2 = Math.min(wall.y + wall.h, location.b+(breathing_allowance/2));
					//Console.info(wall.tsid+' y:'+wall.y+' use_wall_y1:'+use_wall_y1+' h:'+wall.h+' t:'+location.t+' ba:'+breathing_allowance);
					
					colliderLine = new ColliderLine(wall.x, use_wall_y1, wall.x, use_wall_y2, 3);
					// throw out walls with no height
					if (!colliderLine.lengthSquared) continue;
					colliderLine.item_solid_from_left = wall.item_solid_from_left;
					colliderLine.item_solid_from_right = wall.item_solid_from_right;
					colliderLine.pc_solid_from_left = wall.pc_solid_from_left;
					colliderLine.pc_solid_from_right = wall.pc_solid_from_right;
					colliderLines.push(colliderLine);
				}
				
				if (mg.platform_lines) {
					platformLines = mg.platform_lines;
					length = platformLines.length;
					for(i=0; i<length; i++){
						platformLine = platformLines[int(i)];
						colliderLine = colliderLineFromPlatformLine(platformLine, 3);
						// throw out plats with no length
						if (!colliderLine.lengthSquared) continue;
						colliderLines.push(colliderLine);
					}
				}
			}
		}
	}
}