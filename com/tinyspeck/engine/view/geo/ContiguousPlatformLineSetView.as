package com.tinyspeck.engine.view.geo {
	
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.data.location.ContiguousPlatformLineSet;
	import com.tinyspeck.engine.data.location.PlatformLine;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.geom.Range;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	public class ContiguousPlatformLineSetView extends TSSpriteWithModel implements ITipProvider{
		// 8px is a good spacer between indicators at the time I wrote it
		private static const INDICATOR_PADDING:int = 8;
		private static const FADE_IN:Object  = {alpha:1, transition:'linear', time:0.3};
		//private static const FADE_OUT:Object = {alpha:0, transition:'linear', time:0.6};
		
		public var cpls:ContiguousPlatformLineSet;
		private var dot:Shape = new Shape();
		
		public function ContiguousPlatformLineSetView(cpls:ContiguousPlatformLineSet) {
			super('cplsv');
			this.cpls = cpls;
			CONFIG::debugging {
				addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
				addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage, false, 0, true);
			}
			
			addChild(dot);
			dot.graphics.lineStyle(0,0,.3);
			dot.graphics.beginFill(0xffffff);
			dot.graphics.drawCircle(0, 0, 4);
			dot.visible = false
		}
		
		private function onAddedToStage(event:Event):void {
			TipDisplayManager.instance.registerTipTrigger(this);
			
			if (model.flashVarModel.placement_plat_anim) {
				alpha = 0;
				TSTweener.removeTweens(this);
				TSTweener.addTween(this, FADE_IN);
			}
		}
		
		private function onRemovedFromStage(event:Event):void {
			TipDisplayManager.instance.unRegisterTipTrigger(this);
			
			//TODO would be nice to make this work
			//if (model.flashVarModel.placement_plat_anim) {
			//	alpha = 1;
			//	TSTweener.removeTweens(this);
			//	TSTweener.addTween(this, FADE_OUT);
			//}
		}
		
		// only to be called when model.flashVarModel.debug_invoke==true
		public function showDot(dot_x:int, dot_y:int):void {
			dot.x = dot_x;
			dot.y = dot_y;
			dot.visible = true;
		}
		
		// only to be called when model.flashVarModel.debug_invoke==true
		public function hideDot():void {
			dot.visible = false;
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			return {
				txt: ('DEBUG: ' + tsid),
				pointer: WindowBorder.POINTER_BOTTOM_CENTER,
				placement: {
					x: StageBeacon.stage.mouseX,
					y: StageBeacon.stage.mouseY
				}
			}
		}
		
		public function draw(less:int=0):void {
			const animate:Boolean = model.flashVarModel.placement_plat_anim && !model.stateModel.decorator_mode && !model.flashVarModel.debug_decorator_mode;
			if (animate) { 
				while (numChildren) removeChildAt(0);
			}
			
			const assets:* = AssetManager.instance.assets;
			const g:Graphics = graphics;
			g.clear();
			g.lineStyle(4, 0, 1);
			
			var i:int;
			var m:int;
			var pl:PlatformLine;
			var range:Range;
			var range_draw_start_x:int;
			var range_draw_end_x:int;
			
			CONFIG::god {
				if (model.flashVarModel.debug_cult)  {
					// first draw black for the full length of the pls
					for (i=0; i<cpls.platform_lines.length; i++) {
						pl = cpls.platform_lines[i];
						
						g.lineStyle(4, 0, 1);
						g.moveTo(pl.start.x, pl.start.y);
						g.lineTo(pl.end.x, pl.end.y);
					}
				}
			}
			
			// be smart about overlapping overlays: start the next animation no
			// further to the left than the furthest right point of the last
			// animation plus the padding
			var nextIndicatorHolderMinimumX:int = int.MIN_VALUE;
			
			// now draw white for the extent of the valid ranges
			// This is what we will want to show to users
			for (i=0; i<cpls.platform_lines.length; i++) {
				pl = cpls.platform_lines[i];

				for (m=0;m<cpls.valid_ranges.length;m++) {
					range = cpls.valid_ranges[m].clone();
					range.x1+= less;
					range.x2-= less;
					
					// does this range start in this pl's x range
					if (range.x1>=pl.start.x && range.x1<=pl.end.x) {
						range_draw_start_x = range.x1;
						range_draw_end_x = Math.min(pl.end.x, range.x2);
					}
					// does this range end in this pl's x range
					else if (range.x2>=pl.start.x && range.x2<=pl.end.x) {
						range_draw_start_x = Math.max(pl.start.x, range.x1);
						range_draw_end_x = range.x2;
					}
					// does this range cover this whole pl
					else if (range.x1<=pl.start.x && range.x2>=pl.end.x) {
						range_draw_start_x = pl.start.x
						range_draw_end_x = pl.end.x;
					}
					// this pl and this range do not overlap
					else {
						continue;
					}
					
					if (animate) {
						// here, instead of the white line below, tile in the animated placement plat markers
						// (We'll draw the white lines also if debug_invoke=1)
						
						// place all indicator movieclips together in a single
						// Sprite and rotate it alone
						var indicatorHolder:Sprite = new Sprite();
						addChild(indicatorHolder);
						indicatorHolder.x = Math.max(nextIndicatorHolderMinimumX, range_draw_start_x);
						indicatorHolder.y = (pl.yIntersection(indicatorHolder.x));
						indicatorHolder.rotation = (MathUtil.RAD_TO_DEG * Math.atan2((pl.end.y - pl.start.y), (pl.end.x - pl.start.x)));
						
						var indicator:DisplayObject;
						var alternate:Boolean = false;
						var nextX:int = 0;
						var indicatorHolderWidth:Number = (range_draw_end_x - indicatorHolder.x);
						do {
							indicator = new (alternate ? assets.invoking_placeable_indicator_a : assets.invoking_placeable_indicator_b)();
							CONFIG::god {
								if (model.flashVarModel.debug_placement_plat_anim) {
									indicatorHolder.graphics.beginFill(0xFFFFFF, 0.1);
									indicatorHolder.graphics.drawRect(nextX, 0, indicator.width, -indicator.height);
									indicatorHolder.graphics.endFill();
								}
							}
							
							//TODO if we really need a complete event to get dimensions then we should hardcode the values instead
							//indicator.addEventListener(Event.COMPLETE, function():void {
							//	indicator.removeEventListener(Event.COMPLETE, arguments.callee);
							//});
							
							// position the indicator in the top right quadrant
							indicator.x = nextX;
							indicator.y = -(indicator.height);
							indicatorHolder.addChild(indicator);
							
							alternate = !alternate;
							nextX += (indicator.width + INDICATOR_PADDING);

							//TODO be smarter about the right edge going beyond the range:
							// adjust the padding so that everything fits perfectly even
							// if it's inconsistently spaced across segments?
							// EC: SEE last_indicator_mask BELOW FOR A SOLUTION MAYBE NOT AS OPTIMAL BUT THAT WORKS NOW
							
							if (nextX > indicatorHolderWidth) {
								// wherein we mask the last indicator so that it does not extend past the end of the last range

								var last_indicator_mask:Shape = new Shape();
								last_indicator_mask.graphics.lineStyle(0, 0, 0);
								last_indicator_mask.graphics.beginFill(0, .5);
								last_indicator_mask.graphics.drawRect(
									0,
									-indicator.height,
									indicatorHolder.width-((indicatorHolder.x+indicatorHolder.width)-range.x2),
									indicator.height
								);
								indicatorHolder.addChild(last_indicator_mask);
								indicator.mask = last_indicator_mask;
							}
							
						} while (nextX < indicatorHolderWidth);
						
						CONFIG::god {
							if (model.flashVarModel.debug_placement_plat_anim) {
								// fill the background of the holder
								var r:Rectangle = indicatorHolder.getRect(indicatorHolder);
								indicatorHolder.graphics.beginFill(0xFFFFFF, 0.15);
								indicatorHolder.graphics.drawRect(0, 0, r.width, -r.height);
								indicatorHolder.graphics.endFill();
								
								// draw a bounding box of the holder in parent
								r = indicatorHolder.getRect(this);
								g.lineStyle(1, 0xFFFFFF, 0.5);
								g.drawRect(r.x, r.y, r.width, r.height);
								getRect(this)
							}
						}

						// ensure there's no overlap in the next indicatorHolder
						nextIndicatorHolderMinimumX = indicatorHolder.x + nextX;
					}
					
					CONFIG::god {
						// draw the white lines
						if (!animate || model.flashVarModel.debug_cult) {
							g.lineStyle(2, 0xffffff, 1);
							g.moveTo(range_draw_start_x, pl.yIntersection(range_draw_start_x));
							g.lineTo(range_draw_end_x, pl.yIntersection(range_draw_end_x));
						}
					}
				}
			}
			
			CONFIG::god {
				if (model.flashVarModel.debug_cult)  {
					// now draw yellow for the occupied ranges
					for (i=0;i<cpls.platform_lines.length;i++) {
						pl = cpls.platform_lines[i];
						
						for (m=0;m<cpls.occupied_ranges.length;m++) {
							range = cpls.occupied_ranges[m];
							
							// does this range start in this pl's x range
							if (range.x1>=pl.start.x && range.x1<=pl.end.x) {
								range_draw_start_x = range.x1;
								range_draw_end_x = Math.min(pl.end.x, range.x2);
							}
								// does this range end in this pl's x range
							else if (range.x2>=pl.start.x && range.x2<=pl.end.x) {
								range_draw_start_x = Math.max(pl.start.x, range.x1);
								range_draw_end_x = range.x2;
							}
								// does this range cover this whole pl
							else if (range.x1<=pl.start.x && range.x2>=pl.end.x) {
								range_draw_start_x = pl.start.x
								range_draw_end_x = pl.end.x;
							}
								// this pl and this range do not overlap
							else {
								continue;
							}
							
							g.lineStyle(2, 0xfff000, 1);
							g.moveTo(range_draw_start_x, pl.yIntersection(range_draw_start_x)-3);
							g.lineTo(range_draw_end_x, pl.yIntersection(range_draw_end_x)-3);
						}
					}
				}
			}
		}
	}
}
