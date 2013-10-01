package com.tinyspeck.engine.data.location {
	import com.tinyspeck.engine.ns.client;
	
	import flash.geom.Rectangle;
	
	public class Wall extends Surface {
		client var physRect:Rectangle;
		
		public var pc_perm:* = null; // must be able to be n int or null
		public var item_perm:* = null; // must be able to be n int or null
		public var source:String;

		// geo_update may change some of the properties of this wall
		client var geo_was_updated:Boolean;
		
		public function Wall(hashName:String) {
			super(hashName);
		}
		
		override public function AMF():Object {
			var ob:Object = super.AMF();
			ob.item_perm = [-1,0,1].indexOf(item_perm) > -1 ? item_perm : null;
			ob.pc_perm = [-1,0,1].indexOf(pc_perm) > -1 ? pc_perm : null;
			return ob;
		}
		
		public function get pc_solid_from_left():Boolean {
			return !(pc_perm == 1 || pc_perm == 0);
		}
		
		public function get pc_solid_from_right():Boolean {
			return !(pc_perm == -1 || pc_perm == 0);
		}
		
		public function get item_solid_from_left():Boolean {
			return !(item_perm == 1 || item_perm == 0);
		}
		
		public function get item_solid_from_right():Boolean {
			return !(item_perm == -1 || item_perm == 0);
		}
		
		public static function parseMultiple(object:Object):Vector.<Wall> {
			var walls:Vector.<Wall> = new Vector.<Wall>();
			for(var j:String in object){
				walls.push(fromAnonymous(object[j],j));
			}
			return walls;
		}
		
		public static function fromAnonymous(object:Object,hashName:String):Wall {
			const wall:Wall = new Wall(hashName);
			wall.updateFromAnonymous(object);
			return wall;
		}

		public function updateFromAnonymous(object:Object):void {
			if ('pl_tsid' in object) delete object.pl_tsid;
			for (var j:String in object) {
				if (j in this) {
					if (j == "tiling") {
						tiling = Tiling.fromAnonymous(object[j],j);
					} else {
						this[j] = object[j];
					}
				} else if (j == 'is_home') {
					// don't warn on these! (but call resolveError so they get added to unexpected
					resolveError(this, object, j, true);
				} else {
					resolveError(this, object,j);
				}
			}
		}
		
		/**
		 * Takes coordinates in location/middleground-space. Returns an Object
		 * of {wall:PlatformLine, x:Number, y:Number} or null.
		 * 
		 * The wall is the closest wall or wall endpoint to you, within 100px
		 * (if !any_distance).
		 */
		public static function getClosestToXY(wallsV:Vector.<Wall>, x:Number, y:Number, any_distance:Boolean=false):Object {
			var closestWall:Wall;
			var closestX:Number;
			var closestY:Number;
			var closestDistance:Number = Number.MAX_VALUE;
			
			var distance:Number;
			var xDistance:Number;
			var yDistance:Number;
			var yIntersection:Number;
			var wall:Wall;
			
			var tolerance:int = 100; // the max ydistance we allow when not find_any
			
			// search horizontally
			var xPrime:Number;
			var yPrime:Number;
			
			for each (wall in wallsV) {
				// determine if given point is on the line
				if ((y <= wall.y) && (y >= wall.y + wall.h)) {
					// our y falls on the line, determine horizontal distance
					xPrime = wall.x;
					yPrime = y;
					distance = Math.abs(x - xPrime);
					if ((any_distance || (distance <= tolerance)) && (distance < closestDistance)) {
						closestDistance = distance;
						closestWall = wall;
						closestX = xPrime;
						closestY = yPrime;
					}
				} else {
					// find the closest start/end point of a pl
					xPrime = wall.x;
					
					// determine if we have closest start distance
					yPrime = wall.y;
					distance = Math.sqrt((x - xPrime)*(x - xPrime) + (y - yPrime)*(y - yPrime));
					if ((any_distance || (distance <= tolerance)) && (distance < closestDistance)) {
						closestDistance = distance;
						closestWall = wall;
						closestX = xPrime;
						closestY = yPrime;
					}
					
					// determine if we have closest end distance
					yPrime = wall.y + wall.h;
					distance = Math.sqrt((x - xPrime)*(x - xPrime) + (y - yPrime)*(y - yPrime));
					if ((any_distance || (distance <= tolerance)) && (distance < closestDistance)) {
						closestDistance = distance;
						closestWall = wall;
						closestX = xPrime;
						closestY = yPrime;
					}
				}
			}
			
			if (!closestWall) return null;
			
			return {
				wall:closestWall,
				x:closestX,
				y:closestY
			}
		}
	}
}