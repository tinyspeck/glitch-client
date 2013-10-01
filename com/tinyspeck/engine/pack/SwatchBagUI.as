package com.tinyspeck.engine.pack
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.HandOfDecorator;
	import com.tinyspeck.engine.data.decorate.Swatch;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.DecorateModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.decorate.SwatchElementUI;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class SwatchBagUI extends BagUI
	{
		protected static const STYLE_HEADER_H:uint = 17;
		protected static const MIN_HEADER_W:uint = 105;
		protected static const MAX_YOUR_STYLES:uint = 5; //how many of the ones you own to show
		
		protected var swatch_elements:Vector.<SwatchElementUI> = new Vector.<SwatchElementUI>();
		
		protected var owned_styles_tf:TextField = new TextField();
		protected var more_styles_tf:TextField = new TextField();
		
		protected var owned_styles_holder:Sprite = new Sprite();
		protected var more_styles_holder:Sprite = new Sprite();
		protected var owned_arrow:Sprite = new Sprite();
		protected var more_arrow:Sprite = new Sprite();
		
		protected var text_dropA:Array;
		
		protected var type:String;
		
		public function SwatchBagUI(type:String){
			this.type = type;
			super();
		}
		
		override protected function buildBase():void {
			//set the filter
			text_dropA = StaticFilters.copyFilterArrayFromObject({alpha:.2}, StaticFilters.black1px90Degrees_DropShadowA);
			
			//style TFs
			TFUtil.prepTF(owned_styles_tf, false);
			owned_styles_tf.y = -1;
			owned_styles_tf.htmlText = '<p class="chassis_picker_header">Styles you own</p>';
			owned_styles_tf.filters = text_dropA;
			owned_styles_holder.addChild(owned_styles_tf);
			
			const owned_arrow_DO:DisplayObject = new AssetManager.instance.assets.white_arrow();
			SpriteUtil.setRegistrationPoint(owned_arrow_DO);
			owned_arrow_DO.rotation = 180;
			owned_arrow.y = STYLE_HEADER_H;
			owned_arrow.filters = text_dropA;
			owned_arrow.addChild(owned_arrow_DO);
			
			TFUtil.prepTF(more_styles_tf, false);
			more_styles_tf.y = -1;
			more_styles_tf.htmlText = '<p class="chassis_picker_header">Try more styles</p>';
			more_styles_tf.filters = text_dropA;
			more_styles_holder.addChild(more_styles_tf);
			
			const more_arrow_DO:DisplayObject = new AssetManager.instance.assets.white_arrow();
			SpriteUtil.setRegistrationPoint(more_arrow_DO);
			more_arrow.y = int(STYLE_HEADER_H/2);
			more_arrow.filters = text_dropA;
			more_arrow.addChild(more_arrow_DO);
			
			super.buildBase();
		}
		
		override protected function buildPanes():void {
			const dm:DecorateModel = TSModelLocator.instance.decorateModel;
			
			//sort them by category so we know how many panes to make
			var swatches:Vector.<Swatch>;
			switch(type){
				default:
				case Swatch.TYPE_WALLPAPER:
					swatches = dm.wallpapers.concat();
					break;
				case Swatch.TYPE_FLOOR:
					swatches = dm.floors.concat();
					break;
				case Swatch.TYPE_CEILING:
					swatches = dm.ceilings.concat();
					break;
			}
			SortTools.vectorSortOn(swatches, ['category'], [Array.CASEINSENSITIVE]);
			
			var id:String = CATEGORY_ALL;
			var pane_sp:Sprite = new Sprite();
			var i:int;
			var swatch:Swatch;
			
			//add in the all pane
			pane_sp.name = id;
			content_panes[id] = pane_sp;
			
			for(i; i < swatches.length; i++) {
				swatch = swatches[int(i)];
				
				//no need to do admin only ones if they are not one
				if(swatch.admin_only && !CONFIG::god) continue;
				
				if(swatch.category != id){
					id = swatch.category;
					if(!id) id = CATEGORY_OTHER;
					
					pane_sp = new Sprite();
					pane_sp.name = id;
					content_panes[id] = pane_sp;
				}
				
				//add them where they need to go				
				bag_filter.addItem(CATEGORY_ALL);
				bag_filter.addItem(id);
			}
		}
		
		override public function activatePane(id:String):void {
			const pane_sp:Sprite = getPaneById(id);
			if (!pane_sp) return;
			//if (pane_sp == current_pane_sp) return;
			
			showSwatches(id);
			
			super.activatePane(id);
		}
		
		public function rebuildSwatches():void {
			if(!is_built) return;
			
			//just refreshes what is already there
			showSwatches(current_pane_sp ? current_pane_sp.name : CATEGORY_ALL);
		}
		
		private function showSwatches(id:String):void {
			const pane_sp:Sprite = getPaneById(id);
			const dm:DecorateModel = TSModelLocator.instance.decorateModel;
			const bt_y:int = STYLE_HEADER_H + BUTTON_PADD;
			var i:int;
			var total:int = swatch_elements.length;
			var element:SwatchElementUI;
			var pool_id:int;
			var swatch:Swatch;
			var next_x:int;
			var owned_w:int;
			var more_w:int;
			var draw_w:int;
			var pager_x_offset:int;
			var holder:Sprite = owned_styles_holder;
			var g:Graphics;
			
			//reset pool
			resetPool();
			SpriteUtil.clean(owned_styles_holder, false, 1); //don't axe the TF
			SpriteUtil.clean(more_styles_holder, false, 1);
			
			//make sure we don't have anything showing
			SpriteUtil.clean(pane_sp, false);
			
			//remove the more styles until we need it
			if(more_styles_holder.parent) more_styles_holder.parent.removeChild(more_styles_holder);
			if(owned_styles_holder.parent) owned_styles_holder.parent.removeChild(owned_styles_holder);
			
			//position
			var swatches:Vector.<Swatch>;
			
			switch(type){
				default:
				case Swatch.TYPE_WALLPAPER:
					swatches = dm.wallpapers.concat();
					break;
				case Swatch.TYPE_FLOOR:
					swatches = dm.floors.concat();
					break;
				case Swatch.TYPE_CEILING:
					swatches = dm.ceilings.concat();
					break;
			}
			
			//sort to show the ones we own on top
			SortTools.vectorSortOn(swatches, 
				['is_owned', 'date_purchased', 'is_new', 'is_subscriber', 'cost_credits', 'tsid'], 
				[Array.DESCENDING, Array.NUMERIC, Array.DESCENDING, Array.NUMERIC, Array.NUMERIC, Array.CASEINSENSITIVE]);
			
			total = swatches.length;
			for(i = 0; i < total; i++){
				swatch = swatches[int(i)];
				if(swatch.swatch){
					//see if this is in the right category
					if(id == CATEGORY_OTHER) id = null; //swatches have a null category need to be shown too!
					if(id != CATEGORY_ALL && swatch.category != id) continue;
					
					//get an element
					if(pool_id < swatch_elements.length){
						element = swatch_elements[pool_id];
						element.type = type;
					}
					else {
						element = new SwatchElementUI(type);
						element.addEventListener(TSEvent.CHANGED, onSwatchClick, false, 0, true);
						element.addEventListener(TSEvent.DRAG_STARTED, onSwatchDragged, false, 0, true);
						swatch_elements.push(element);
					}
					pool_id++;
					
					//show it!
					element.show(swatch);
					
					//add the width so we know what to draw
					if(swatch.is_owned) {
						owned_w += element.width + BUTTON_PADD;
					}
					else {
						more_w += element.width + BUTTON_PADD;
					}
					
					//stuff the player doesn't have, set it up
					if(swatch.is_owned && !owned_styles_holder.parent){
						pane_sp.addChild(owned_styles_holder);
					}
					
					if(!swatch.is_owned && !more_styles_holder.parent){
						next_x = 0;
						owned_w = owned_styles_holder.parent ? Math.max(owned_w, MIN_HEADER_W) : 0;
						
						//draw the divider
						g = pane_sp.graphics;
						g.clear();
						if(owned_w > 0){
							g.beginFill(0xb0bcbf);
							g.drawRect(owned_styles_holder.x + owned_w, -BUTTON_PADD, 1, HOLDER_H + BUTTON_PADD);
						}
						
						more_styles_holder.x = owned_w > 0 ? owned_w + BUTTON_PADD + 1 : 0; //1 is for the divider
						holder = more_styles_holder;
						pane_sp.addChild(more_styles_holder);
						
						//how many swatches were before this? if more than MAX_YOUR_STYLES then we need to shift the pager over
						if(pool_id-1 >= MAX_YOUR_STYLES){
							pager_x_offset = ((pool_id-1) - MAX_YOUR_STYLES) * (element.width + BUTTON_PADD);
						}
					}
					
					/*CONFIG::debugging {
					Console.info(swatch.tsid+' '+swatch.swatch+' '+next_x+' element.width:'+element.width)
					}*/
					
					//add it to the holder
					element.x = next_x;
					element.y = bt_y;
					next_x += element.width + BUTTON_PADD;
					holder.addChild(element);
				}
				else {
					CONFIG::debugging {
						Console.warn('NO SWATCH FOR '+swatch.tsid);
					}
				}
			}
			
			//draw the owned bar
			const owned_children:int = owned_styles_holder.numChildren;
			if(owned_children > 1){
				owned_w = Math.max(owned_w, MIN_HEADER_W);
				draw_w = owned_w - BUTTON_PADD;
				g = owned_styles_holder.graphics;
				g.beginFill(0xaabbc0);
				g.drawRoundRect(0, 0, draw_w, STYLE_HEADER_H, 6);
				
				//place the tf where it needs to go
				if(owned_children > 3){
					owned_styles_tf.x = int(draw_w - owned_styles_tf.width - 4);
					owned_arrow.x = int(owned_styles_tf.x);
					owned_styles_holder.addChild(owned_arrow);
				}
				else {
					//center our element
					if(owned_children == 2){
						element = owned_styles_holder.getChildAt(1) as SwatchElementUI;
						element.x = int(draw_w/2 - element.width/2);
					}
					owned_styles_tf.x = int(draw_w/2 - owned_styles_tf.width/2);
				}
			}
			
			//draw in the more styles bar
			const more_children:int = more_styles_holder.numChildren;
			if(more_children > 1){
				more_w = Math.max(more_w, MIN_HEADER_W);
				draw_w = more_w - BUTTON_PADD;
				g = more_styles_holder.graphics;
				g.beginFill(0xaabbc0);
				g.drawRoundRect(0, 0, draw_w, STYLE_HEADER_H, 6);
				
				//place the tf where it needs to go
				if(more_children > 3){
					more_styles_tf.x = 4;
					more_arrow.x = int(more_styles_tf.x + more_styles_tf.width + more_arrow.width + 1);
					more_styles_holder.addChild(more_arrow);
				}
				else {
					//center our element
					if(more_children == 2){
						element = more_styles_holder.getChildAt(1) as SwatchElementUI;
						element.x = int(draw_w/2 - element.width/2);
					}
					more_styles_tf.x = int(draw_w/2 - more_styles_tf.width/2);
				}
			}
			
			//make sure the scroller has good element size data
			if(!scroll_pager.element_width && element){
				scroll_pager.element_width = element.width + BUTTON_PADD;
			}
			
			//offset the scroller
			scroll_pager.gotoPage(1);
			scroll_pager.x_offset = pager_x_offset;
		}
		
		private function resetPool():void {
			const total:int = swatch_elements.length;
			var i:int;
			
			for(i = 0; i < total; i++){
				swatch_elements[int(i)].hide();
			}
		}
		
		private function onSwatchDragged(event:TSEvent):void {
			startStamping(event, false);
		}
		
		private function onSwatchClick(event:TSEvent):void {
			startStamping(event, true);
		}
		
		private function startStamping(event:TSEvent, by_click:Boolean):void {
			
			const clicked_element:SwatchElementUI = event.data as SwatchElementUI;
			
			var swatch:Swatch;
			
			switch(clicked_element.type){
				default:
				case Swatch.TYPE_WALLPAPER:
					swatch = model.decorateModel.getWallpaperSwatchByTsid(clicked_element.swatch.tsid);
					break;
				case Swatch.TYPE_FLOOR:
					swatch = model.decorateModel.getFloorSwatchByTsid(clicked_element.swatch.tsid);
					break;
				case Swatch.TYPE_CEILING:
					swatch = model.decorateModel.getCeilingSwatchByTsid(clicked_element.swatch.tsid);
					break;
			}
			
			if (!swatch) {
				CONFIG::debugging {
					Console.error(clicked_element.swatch.tsid+' NOT EXISTS');
				}
				return;
			}
			
			if (HandOfDecorator.instance.promptForSaveIfPreviewingSwatch(false)) {
				return;
			}
			
			switch(clicked_element.type){
				default:
				case Swatch.TYPE_WALLPAPER:
					HandOfDecorator.instance.startStampingWall(swatch, by_click);
					break;
				case Swatch.TYPE_FLOOR:
					HandOfDecorator.instance.startStampingFloor(swatch, by_click);
					break;
				case Swatch.TYPE_CEILING:
					HandOfDecorator.instance.startStampingCeiling(swatch, by_click);
					break;
			}
		}
	}
}