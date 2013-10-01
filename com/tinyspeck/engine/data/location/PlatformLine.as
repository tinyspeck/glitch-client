package com.tinyspeck.engine.data.location {
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.physics.colliders.ColliderLine;
	import com.tinyspeck.engine.physics.colliders.colliderLineFromPlatformLine;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	/**
	 * PlatformLines don't have x and y, really, but LocoDeco needs this class
	 * to extend AbstractPositionableLocationEntity which has an x and y.
	 * 
	 * For the purposes of LD, x and y getters and setters represent the
	 * start point of the line segment.
	 */
	public class PlatformLine extends AbstractPositionableLocationEntity 
	{
		public var start:PlatformLinePoint;
		public var end:PlatformLinePoint;
		
		public var platform_pc_perm:*; // must be able to be an int or null
		public var platform_item_perm:*; // must be able to be an int or null

		// geo_update may change some of the properties of this line
		client var geo_was_updated:Boolean;
		
		// the following only set when for placement
		public var is_for_placement:Boolean;
		public var placement_invoking_set:String;
		public var placement_userdeco_set:String;
		public var placement_plane_height:int;
		public var source:String;
		
		public function PlatformLine(hashName:String) {
			super(hashName);
		}
		
		override public function AMF():Object {
			var ob:Object = super.AMF();
			
			// remove these props since LocoDeco only uses them on PL temporally
			delete ob['x'];
			delete ob['y'];
			
			ob.start = {
				x: start.x,
				y: start.y
			};
			ob.end = {
				x: end.x,
				y: end.y
			};
			ob.platform_item_perm = [-1,0,1].indexOf(platform_item_perm) > -1 ? platform_item_perm : null;
			ob.platform_pc_perm = [-1,0,1].indexOf(platform_pc_perm) > -1 ? platform_pc_perm : null;
			
			if (is_for_placement && (placement_invoking_set || placement_userdeco_set)) {
				ob.is_for_placement = true;
				if (placement_invoking_set) ob.placement_invoking_set = placement_invoking_set;
				if (placement_userdeco_set) ob.placement_userdeco_set = placement_userdeco_set;
				ob.placement_plane_height = placement_plane_height;
			}
			
			if (source) ob.source = source;
			
			return ob;
		}
		
		public static function parseMultiple(object:Object):Vector.<PlatformLine> {
			const platformLineObjects:Vector.<PlatformLine> = new Vector.<PlatformLine>();
			for(var j:String in object) {
				platformLineObjects.push(fromAnonymous(object[j],j));
			}
			return platformLineObjects
		}
		
		public static function fromAnonymous(object:Object, hashName:String):PlatformLine {
			const pl:PlatformLine = new PlatformLine(hashName);
			pl.updateFromAnonymous(object);
			return pl;
		}
		
		public function updateFromAnonymous(object:Object):void {
			for (var j:String in object) {
				if (j in this) {
					if (j == "start") {
						start = PlatformLinePoint.fromAnonymous(object[j],j);
					} else if(j == "end") {
						end = PlatformLinePoint.fromAnonymous(object[j],j);
					} else {
						this[j] = object[j];
					}
				} else if (j == 'is_home' || j == 'new_start') {
					// don't warn on these! (but call resolveError so they get added to unexpected
					resolveError(this, object, j, true);
				} else {
					resolveError(this, object, j);
				}
			}
		}
		
		/** Returns all plats above the given y (optionally inclusive of y) */
		public static function getPlatsAboveY(platform_linesV:Vector.<PlatformLine>, y:Number, inclusive:Boolean=false):Vector.<PlatformLine> {
			if (inclusive) {
				return platform_linesV.filter(function(platformLine:PlatformLine, i:int, v:Vector.<PlatformLine>):Boolean {
					return ((platformLine.start.y <= y) && (platformLine.end.y <= y));
				});
			} else {
				return platform_linesV.filter(function(platformLine:PlatformLine, i:int, v:Vector.<PlatformLine>):Boolean {
					return ((platformLine.start.y < y) && (platformLine.end.y < y));
				});
			}
		}
		
		/** Returns all plats that items can rest on, including ones that are placement plats that can hold the item */
		public static function getPlatsSolidFromTopForSpecialFurniture(platform_linesV:Vector.<PlatformLine>, item_class:String=''):Vector.<PlatformLine> {
			return platform_linesV.filter(function(platformLine:PlatformLine, i:int, v:Vector.<PlatformLine>):Boolean {
				return platformLine.item_solid_from_top || (item_class && platformLine.canHoldItemsClass(item_class));
			});
		}
		
		/** Returns all plats that items can rest on */
		public static function getPlatsSolidFromTopForItems(platform_linesV:Vector.<PlatformLine>):Vector.<PlatformLine> {
			return platform_linesV.filter(function(platformLine:PlatformLine, i:int, v:Vector.<PlatformLine>):Boolean {
				return platformLine.item_solid_from_top;
			});
		}
		
		/** Returns all plats that items can rest on THAT ARE! PART OF A FURNITURE PIECE */
		public static function getFurnPlatsPlatsSolidFromTopForItems(platform_linesV:Vector.<PlatformLine>):Vector.<PlatformLine> {
			return platform_linesV.filter(function(platformLine:PlatformLine, i:int, v:Vector.<PlatformLine>):Boolean {
				return platformLine.item_solid_from_top && platformLine.source;
			});
		}
		
		/** Returns all plats that items can rest on THAT ARE NOT PART OF A FURNITURE PIECE */
		public static function getNOTFurnPlatsSolidFromTopForItems(platform_linesV:Vector.<PlatformLine>):Vector.<PlatformLine> {
			return platform_linesV.filter(function(platformLine:PlatformLine, i:int, v:Vector.<PlatformLine>):Boolean {
				return platformLine.item_solid_from_top && !platformLine.source;
			});
		}
		
		/** Returns all plats below the given y (optionally inclusive of y) */
		public static function getPlatsBelowY(platform_linesV:Vector.<PlatformLine>, y:Number, inclusive:Boolean=false):Vector.<PlatformLine> {
			if (inclusive) {
				return platform_linesV.filter(function(platformLine:PlatformLine, i:int, v:Vector.<PlatformLine>):Boolean {
					return ((platformLine.start.y >= y) && (platformLine.end.y >= y));
				});
			} else {
				return platform_linesV.filter(function(platformLine:PlatformLine, i:int, v:Vector.<PlatformLine>):Boolean {
					return ((platformLine.start.y > y) && (platformLine.end.y > y));
				});
			}
		}
		
		/** Returns all placement plats that can hold the given item class */
		public static function getPlacementPlatsForItemClass(platform_linesV:Vector.<PlatformLine>, item_class:String=''):Vector.<PlatformLine> {
			return platform_linesV.filter(function(platformLine:PlatformLine, i:int, v:Vector.<PlatformLine>):Boolean {
				return (platformLine.is_for_placement && platformLine.canHoldItemsClass(item_class));
			});
		}
		
		/**
		 * Takes coordinates in location/middleground-space. Returns an Object
		 * of {pl:PlatformLine, x:Number, y:Number} or null.
		 * 
		 * The pl is the closest platform line above/below the point, or the
		 * closest platform line's endpoint to the given point (if search_wide==true).
		 * 
		 * @y_tolerance is the max y distance we allow when looking above/below.
		 * @search_wide is whether we should search for plats that are not directly underneath the x.
		 */
		public static function getClosestUnder(platform_linesV:Vector.<PlatformLine>, x:Number, y:Number, y_tolerance:int=100, search_wide:Boolean=false):PlatformLine {
			var ob:Object = getClosestToXYObject(platform_linesV, x, y, false, y_tolerance, search_wide);
			if (ob && ob.pl) return ob.pl;
			return null;
		}
		
		public static function getClosestToXYObject(platform_linesV:Vector.<PlatformLine>, x:Number, y:Number, any_distance:Boolean=false, y_tolerance:int=100, search_wide:Boolean=false):Object {
			var closestPL:PlatformLine;
			var closestX:Number;
			var closestY:Number;
			var closestDistance:Number = Number.MAX_VALUE;
			
			var distance:Number;
			var xDistance:Number;
			var yDistance:Number;
			var dist:Number;
			var yIntersection:Number;
			var pl:PlatformLine;
			
			// search vertically first
			for each (pl in platform_linesV) {
				// find point of intersection on the platform line
				yIntersection = pl.yIntersection(x);
				if (!isNaN(yIntersection)) {
					// determine distance
					yDistance = Math.abs(y - yIntersection);
					
					// decide what's closest
					if (yDistance < closestDistance && (any_distance || yDistance <= y_tolerance)) {
						closestDistance = yDistance;
						closestPL = pl;
						closestX = x;
						closestY = yIntersection;
					}
				}
			}
			
			// search horizontally
			if (search_wide) {
				// reset
				closestDistance = Number.MAX_VALUE;
				
				pt1.x = x;
				pt1.y = y;
				
				for each (pl in platform_linesV) {
					pt2.x = x;
					// find point of intersection on the platform line
					pt2 = pl.yIntersectionTolerant(pt2); // return the pt with the y changed
					// determine distance
					dist = Math.abs(Point.distance(pt1, pt2));
					
					// decide what's closest
					if (dist < closestDistance) {
						closestDistance = dist;
						closestPL = pl;
						closestX = pt2.x;
						closestY = pt2.y;
					}
				}
			}
			
			if (!closestPL) return null;
			
			return {
				pl:closestPL,
				x:closestX,
				y:closestY
			}
		}
		
		private static var pt1:Point = new Point();
		private static var pt2:Point = new Point();
		
		/**
		 * Takes a list of itemstacks and returns a list of itemstacks that fall
		 * within tolerance pixels of the line, or null. tolerance is only for y, not x
		 * 
		 * Returns either Vector.<Itemstack> or Vector.<LocationItemstackView>.
		 */
		private function getClosestItemstacksWorker(tsids_to_search:Dictionary, use_views:Boolean, tolerance:int, not_furniture:Boolean=true):* {
			const wm:WorldModel = TSModelLocator.instance.worldModel;
			
			var itemstack:Itemstack;
			var lis_view:LocationItemstackView;
			var closestItemstacks:*;
			
			const left:PlatformLinePoint   = ((start.x < end.x) ? start : end);
			const right:PlatformLinePoint  = ((start.x < end.x) ? end   : start);
			const top:PlatformLinePoint    = ((start.y < end.y) ? start : end);
			const bottom:PlatformLinePoint = ((start.y < end.y) ? end   : start);
			
			var x_to_test:int;
			var y_to_test:int;
			for (var tsid:String in tsids_to_search) {
				// does the item pass muster
				itemstack = wm.getItemstackByTsid(tsid);
				if (!itemstack) continue;
				if (not_furniture && itemstack.item.is_furniture) {
					//Console.warn('no '+item.tsid);
					continue;
				}
				
				if (use_views) {
					lis_view = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(itemstack.tsid);
					if (!lis_view) continue;
					x_to_test = lis_view.x;
					y_to_test = lis_view.y;
				} else {
					x_to_test = itemstack.x;
					y_to_test = itemstack.y;
				}
				
				// find the closest distance from the itemstack to the line
				// and compare against the tolerance
				const colliderLine:ColliderLine = colliderLineFromPlatformLine(this, tolerance);
				if (!colliderLine.touches(x_to_test, y_to_test)) {
					continue;
				}
				
				// lazy init since there's a good chance we won't return anything
				
				// it's good
				if (use_views) {
					if (!closestItemstacks) closestItemstacks = new Vector.<LocationItemstackView>();
					closestItemstacks.push(lis_view);
				} else {
					if (!closestItemstacks) closestItemstacks = new Vector.<Itemstack>();
					closestItemstacks.push(itemstack);
				}
			}

			return closestItemstacks;
		}
		
		public function getClosestItemstackViews(tolerance:int, not_furniture:Boolean=true):Vector.<LocationItemstackView> {
			return getClosestItemstacksWorker(
				TSModelLocator.instance.worldModel.location.itemstack_tsid_list,
				true,
				tolerance,
				not_furniture
			) as Vector.<LocationItemstackView>;
		}
		
		public function getClosestItemstacks(tolerance:int, not_furniture:Boolean=true):Vector.<Itemstack> {
			return getClosestItemstacksWorker(
				TSModelLocator.instance.worldModel.location.itemstack_tsid_list,
				false,
				tolerance,
				not_furniture
			) as Vector.<Itemstack>;
		}
		
		public function canHoldItemsClass(item_class:String=''):Boolean {
			var wm:WorldModel = TSModelLocator.instance.worldModel;
			if (placement_invoking_set && wm.invoking && wm.invoking.sets && wm.invoking.sets[placement_invoking_set]) {
				if (wm.invoking.sets[placement_invoking_set][item_class]) return true;
			}
			if (placement_userdeco_set && wm.userdeco && wm.userdeco.sets && wm.userdeco.sets[placement_userdeco_set]) {
				if (wm.userdeco.sets[placement_userdeco_set].indexOf(item_class) != -1) return true;
			}
			return false;
		}
		
		public function get pc_solid_from_top():Boolean {
			return !(platform_pc_perm == 1 || platform_pc_perm == 0);
		}
		
		public function get pc_solid_from_bottom():Boolean {
			return !(platform_pc_perm == -1 || platform_pc_perm == 0);
		}
		
		public function get item_solid_from_top():Boolean {
			return !(platform_item_perm == 1 || platform_item_perm == 0);
		}
		
		public function get item_solid_from_bottom():Boolean {
			return !(platform_item_perm == -1 || platform_item_perm == 0);
		}
		
		/** Cache this, it's not stored */
		public function get slope():Number {
			return (end.y - start.y) / (end.x - start.x);
		}
		
		/** Returns the closest Y intersection on the line given an X, or NaN */
		public function yIntersection(x:Number):Number {
			// is the plat above/below the given x
			if ((start.x <= x) && (x <= end.x)) {
				if (start.y == end.y) { // flat line
					return start.y;
				} else {
					const m:Number = slope;
					return ((m * x) + (start.y - (m * start.x)));
				}
			}
			return NaN;
		}
		
		/** Returns the past point with the y changed to be the y under the x, or the closest y to the x */
		public function yIntersectionTolerant(pt:Point):Point {
			if (pt.x>end.x) pt.x = end.x;
			if (pt.x<start.x) pt.x = start.x;
			
			if (start.y == end.y) { // flat line
				pt.y = start.y;
			} else {
				const m:Number = slope;
				pt.y = ((m * pt.x) + (start.y - (m * start.x)));
			}
			
			return pt;
		}
		
		/** Returns the start of the line */
		override public function get x():int {
			return start.x;
		}
		
		/** Returns the start of the line */
		override public function get y():int {
			return start.y;
		}
	}
}