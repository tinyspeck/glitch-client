package com.tinyspeck.engine.data.location {
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.util.geom.Range;
	
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	
	public class ContiguousPlatformLineSet
	{
		public var platform_lines:Vector.<PlatformLine> = new Vector.<PlatformLine>();
		public var valid_ranges:Vector.<Range> = new Vector.<Range>();
		public var occupied_ranges:Vector.<Range> = new Vector.<Range>();
		
		public function ContiguousPlatformLineSet() {
			
		}
		
		/** Returns the start of the line */
		public function get start():PlatformLinePoint {
			if (!platform_lines.length) return null;
			return platform_lines[0].start;
		}
		
		/** Returns the start of the line */
		public function get end():PlatformLinePoint {
			if (!platform_lines.length) return null;
			return platform_lines[platform_lines.length-1].end;
		}
		
		/** Returns the start of the first line */
		public function get x():int {
			if (!start) return NaN;
			return start.x;
		}
		
		/** Returns the start of the first line */
		public function get y():int {
			if (!start) return NaN;
			return start.y;
		}
		
		/** Returns the closest Y intersection on the set of lines given an X, or NaN */
		public function yIntersection(x:Number):Number {
			var pl:PlatformLine = getPLForX(x);
			if (pl) return pl.yIntersection(x);
			return NaN;
		}
		
		/** Returns a line that contains the x */
		public function getPLForX(x:int):PlatformLine {
			for each (var pl:PlatformLine in platform_lines) {
				if (pl.start.x <= x && pl.end.x >= x) return pl;
			}
			return null;
		}
		
		public function getValidRangeForX(x:int, w:int):Range {
			//w = 0;
			var half_w:int = (w) ? w/2 : 0;
			var range:Range;
			for (var i:int=0;i<valid_ranges.length;i++) {
				range = valid_ranges[i];
				if (x>=range.x1+half_w && x<=range.x2-half_w) return range;
			}
			return null;
		}
		
		public function calculateRanges(invoking_item_class:String='', ignore_itemstack_tsidsA:Array=null):void {
			occupied_ranges.length = 0;
			valid_ranges.length = 0;
			
			var wm:WorldModel = TSModelLocator.instance.worldModel;
			var invoking_item:Item = invoking_item_class ? wm.getItemByTsid(invoking_item_class) : null;
			var exisiting_thing:Object;
			var existing_range:Range;
			var occupied_range:Range;
			var needed_w:int;
			var other_invoker_item:Item;
			var i:int;
			var pl_rect:Rectangle = new Rectangle();
			var existing_rect:Rectangle = new Rectangle();
			var existing_thingsA:Array = []; // to be filled with itemstacks and signposts
			var pl:PlatformLine;
			var itemstack:Itemstack;
			var interesects:Boolean;
			var valid_range:Range;
			var tsid:String;
			var signpost_w:int = (wm.invoking.blockers && wm.invoking.blockers.signpost && wm.invoking.blockers.signpost.width) ? wm.invoking.blockers.signpost.width : 0;
			var full_range:Range;
			
			// let's calculate some ranges
			
			// calc the full range
			/*
			full_range = new Range(
				platform_lines[0].start.x,
				platform_lines[platform_lines.length-1].end.x
			);
			*/
			
			// we used to use the raw dims of the plats, even if they were outside of bouncs of the loc rect.
			// Now, we limit things to loc.l/loc.r
			full_range = new Range(
				Math.max(wm.location.l, platform_lines[0].start.x),
				Math.min(wm.location.r, platform_lines[platform_lines.length-1].end.x)
			)
			
			// Yeah but what about the occupied space in that range?
			if (invoking_item) {
				
				// get an array of all stacks and signposts in location that can take up space when placing proto items
				if (signpost_w) {
					for (i=0;i<wm.location.mg.signposts.length;i++) {
						existing_thingsA.push(wm.location.mg.signposts[int(i)]);
					}
				}
				
				for (tsid in wm.location.itemstack_tsid_list) {
					itemstack = wm.getItemstackByTsid(tsid);
					if (itemstack && (itemstack.placement_w) && (!ignore_itemstack_tsidsA || ignore_itemstack_tsidsA.indexOf(itemstack.tsid) == -1)) { // means it is either a proto item or a result item
						exisiting_thing = wm.getItemstackByTsid(tsid);
						existing_thingsA.push(exisiting_thing);
					}
				}
				
				// sort these so we are dealing them from left to right;
				existing_thingsA.sortOn(['x'], [Array.NUMERIC]);
				
				for (i=0;i<existing_thingsA.length;i++) {
					exisiting_thing = existing_thingsA[i];
					
					if (exisiting_thing is SignPost) {
						needed_w = signpost_w;
					} else if (exisiting_thing is Itemstack)  {
						needed_w = exisiting_thing.placement_w;
						//Console.info(exisiting_thing.class_tsid+' '+needed_w);
					} else {
						CONFIG::debugging {
							Console.warn('unknown exisiting_thing:'+exisiting_thing)
						}
						continue;
					}
					
					// check and make sure this is close to a platform
					
					interesects = false;
					existing_rect.x = exisiting_thing.x-(needed_w/2);
					existing_rect.y = exisiting_thing.y-5;
					existing_rect.right = exisiting_thing.x+(needed_w/2);
					existing_rect.bottom = exisiting_thing.y+5;
					for each (pl in platform_lines) {
						pl_rect.x = pl.start.x;
						pl_rect.y = pl.start.y-50;
						pl_rect.right = pl.end.x;
						pl_rect.bottom = pl.end.y+20;
						if (existing_rect.intersects(pl_rect)) {
							interesects = true;
							break;
						}
					}
					
					if (!interesects) {
						continue;
					}
					
					/*CONFIG::debugging {
						Console.warn(exisiting_thing.class_tsid+' '+exisiting_thing.tsid+' '+exisiting_thing.x);
					}*/
					
					existing_range = new Range(
						exisiting_thing.x-(needed_w/2),
						exisiting_thing.x+(needed_w/2)
					);
					
					/*CONFIG::debugging {
						Console.info(existing_range);
					}*/
					
					if (occupied_range) { // then we have a previous one, and we should see if this itemstack should just extend it
						if (existing_range.x1 <= occupied_range.x2) { // is the left side of this new range within the previous range?
							occupied_range.x2 = existing_range.x2;
							continue;
						}
					}
					
					occupied_range = existing_range;
					occupied_ranges.push(occupied_range);
				}
				
				/*CONFIG::debugging {
					Console.dir(occupied_ranges);
				}*/
			}
			
			if (!occupied_ranges.length) { // no occupied_ranges, use full_range
				if (!invoking_item || (full_range.x2-full_range.x1) >= invoking_item.placement_w) {
					valid_ranges.push(full_range);
				}
				
			} else {// there are some occupied_ranges
				
				// first, let's see if there is a valid range to the left of the first occupied range
				occupied_range = occupied_ranges[0];
				if (full_range.x1 < occupied_range.x1) {
					//     ------------------------- full range
					//       --------                occupied_range 1
					//                   --------    occupied_range 2
					//     --        ----        --- VALID RANGES WE WANT
					valid_range = new Range(
						full_range.x1,
						occupied_range.x1
					);
					
					if ((valid_range.x2-valid_range.x1) >= invoking_item.placement_w) {
						valid_ranges.push(valid_range);
					}
				} else {
					//     ------------------------- full range
					//   --------                    occupied_range 1
					//                   --------    occupied_range 2
					//           --------        --- VALID RANGES WE WANT
				}
				
				// now go over all the occupied_ranges and add valid ranges as we can
				for (i=0;i<occupied_ranges.length;i++) {
					occupied_range = occupied_ranges[i];
					
					if (occupied_range.x2 < full_range.x2) {
						valid_range = new Range(
							occupied_range.x2,
							full_range.x2 // make it as long as full range, to be adjusted below if there is a next occupied_range
						);
						
						if (i+1 < occupied_ranges.length) {
							valid_range.x2 = occupied_ranges[i+1].x1;
						}	
						
						if ((valid_range.x2-valid_range.x1) >= invoking_item.placement_w) {
							valid_ranges.push(valid_range);
						}
					}
				}
			}
		}
		
		private static function findNextLine(from_pl:PlatformLine, plsV:Vector.<PlatformLine>, item_class:String=''):PlatformLine {
			for each (var pl:PlatformLine in plsV) {
				//if (from_pl.end.x == pl.start.x && from_pl.end.y == pl.start.y) {
				if (from_pl.end.equals(pl.start)) {
					if (!item_class || pl.canHoldItemsClass(item_class)) {
						return pl;
					}
				}
			}
			return null;
		}
		
		private static function findPrevLine(from_pl:PlatformLine, plsV:Vector.<PlatformLine>, item_class:String=''):PlatformLine {
			for each (var pl:PlatformLine in plsV) {
				//if (from_pl.start.x == pl.end.x && from_pl.start.y == pl.end.y) {
				if (from_pl.start.equals(pl.end)) {
					if (!item_class || pl.canHoldItemsClass(item_class)) {
						return pl;
					}
				}
			}
			return null;
		}
		
		private static function buildCPLSFromPL(pl:PlatformLine, plsV:Vector.<PlatformLine>, invoking_item_class:String='', ignore_itemstack_tsidsA:Array=null):ContiguousPlatformLineSet {
			if (invoking_item_class && !pl.canHoldItemsClass(invoking_item_class)) {
				CONFIG::debugging {
					Console.error('You can\'t build a contiguous set from a pl that cannot even hold that item class');
				}
				return null;
			}
			
			var cpls:ContiguousPlatformLineSet = new ContiguousPlatformLineSet();
			
			// FIRST let's build the platform_lines Vector
			
			var from_pl:PlatformLine;
			cpls.platform_lines.push(pl);
			
			from_pl = pl;
			while (from_pl) {
				from_pl = findNextLine(from_pl, plsV, invoking_item_class);
				
				// make sure it is not already in the V, to protect from endless loops
				if (from_pl && cpls.platform_lines.indexOf(from_pl) != -1) {
					/*CONFIG::debugging {
						Console.info(from_pl.tsid+' bad next line');
						Console.dir(cpls.platform_lines);
					}*/
					from_pl = null;
				}
				
				if (from_pl) {
					cpls.platform_lines.push(from_pl);
				}
			}
			
			from_pl = pl;
			while (from_pl) {
				from_pl = findPrevLine(from_pl, plsV, invoking_item_class);
				
				// make sure it is not already in the V, to protect from endless loops
				if (from_pl && cpls.platform_lines.indexOf(from_pl) != -1) {
					/*CONFIG::debugging {
						Console.info(from_pl.tsid+' bad prev line');
						Console.dir(cpls.platform_lines);
					}*/
					from_pl = null;
				}
				
				if (from_pl) {
					cpls.platform_lines.unshift(from_pl);
				}
			}
			
			cpls.calculateRanges(invoking_item_class, ignore_itemstack_tsidsA);
			return cpls;
		}
		
		public static function getPLtoCPLSDictionary(plsV:Vector.<PlatformLine>, item_class:String='', ignore_itemstack_tsidsA:Array=null):Dictionary {
			var contig_map:Dictionary = new Dictionary(true);
			var cpls:ContiguousPlatformLineSet;
			var obj:Object;
			for each (var pl:PlatformLine in plsV) {
				if (contig_map[pl]) continue; // we've already got a cpls for this pl
				
				if (!item_class || pl.canHoldItemsClass(item_class)) {
					cpls = buildCPLSFromPL(pl, plsV, item_class, ignore_itemstack_tsidsA);
					
					// now add a mpaping from each of the pls to this cpls
					for each (obj in cpls.platform_lines) {
						contig_map[obj] = cpls;
					}
				}
			}
			
			return contig_map;
		}
		
		public static function getCPLSVector(plsV:Vector.<PlatformLine>, item_class:String=''):Vector.<ContiguousPlatformLineSet> {
			var cplsV:Vector.<ContiguousPlatformLineSet> = new Vector.<ContiguousPlatformLineSet>();
			var contig_map:Dictionary = new Dictionary(true);
			var cpls:ContiguousPlatformLineSet;
			var obj:Object;
			for each (var pl:PlatformLine in plsV) {
				if (contig_map[pl]) continue; // we've already got a cpls for this pl
				
				if (!item_class || pl.canHoldItemsClass(item_class)) {
					cpls = buildCPLSFromPL(pl, plsV, item_class);
					cplsV.push(cpls);
					
					// now add a mpaping from each of the pls to this cpls
					for each (obj in cpls.platform_lines) {
						contig_map[obj] = cpls;
					}
				}
			}
			contig_map = null;
			return cplsV;
		}
	}
}
