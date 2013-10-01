package com.tinyspeck.engine.view.ui.chrome
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.view.ui.supersearch.SuperSearch;
	import com.tinyspeck.engine.view.ui.supersearch.SuperSearchElementItem;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.KeyboardEvent;

	public class ItemSearch extends SuperSearch
	{
		private static const WIDTH:uint = 330;
		private static const HEIGHT:uint = 40;
		private static const PADD:uint = 8;
		private static const CURVE_RADIUS:Number = 8;
		private static const MAG_OFFSET:uint = 11;
		private static const TAGS_TO_EXCLUDE:Array = [];
		
		public function ItemSearch(){
			//since this is JUST for items, let's init it now!
			show_images = false;
			init(TYPE_ITEMS, 5, 'Use TAB key for quick search');
			item_tags_to_exclude = TAGS_TO_EXCLUDE;
			_is_in_encyc = true;
		}
		
		override protected function buildBase():void {
			super.buildBase();
			
			//move things around
			input_holder.x = input_holder.y = PADD;
			result_holder.x = PADD;
			result_holder.y = PADD*2;
			
			//draw the holder
			var g:Graphics = graphics;
			g.beginFill(model.layoutModel.bg_color);
			g.drawRoundRect(0, 0, WIDTH + PADD*2, HEIGHT + PADD*2, CURVE_RADIUS*2);
			g.endFill();
			
			//left curve
			g.beginFill(model.layoutModel.bg_color);
			g.moveTo(-CURVE_RADIUS, 0);
			g.lineTo(PADD+1, 0); //+1 just makes sure there isn't any gaps from the curve below
			g.lineTo(PADD+1, CURVE_RADIUS);
			g.lineTo(0, CURVE_RADIUS);
			g.curveTo(0,0, -CURVE_RADIUS, 0);
			g.endFill();
			
			//right curve
			const start_x:int = WIDTH + PADD*2;
			g.beginFill(model.layoutModel.bg_color);
			g.moveTo(start_x+CURVE_RADIUS, 0);
			g.lineTo(start_x-PADD-1, 0);
			g.lineTo(start_x-PADD-1, CURVE_RADIUS);
			g.lineTo(start_x, CURVE_RADIUS);
			g.curveTo(start_x,0, start_x+CURVE_RADIUS, 0);
			g.endFill();
			
			//handle the mag glass
			const mag_glass:DisplayObject = new AssetManager.instance.assets.mag_glass_item_search();
			mag_glass.x = MAG_OFFSET;
			mag_glass.y = int(HEIGHT/2 - mag_glass.height/2 + 1);
			input_content.addChild(mag_glass);
			
			input_tf.x = mag_glass.x + mag_glass.width + 8;
			
			//get the styles
			setAppearanceFromCSS('item_search');
			bg_color = model.layoutModel.bg_color;
			border_color = CSSManager.instance.getUintColorValueFromStyle('item_search', 'glowColor', 0xc6d5da);
			
			//tweak the filters
			const dropA:Array = StaticFilters.copyFilterArrayFromObject({alpha:.1, distance:4}, StaticFilters.black3px90DegreesInner_DropShadowA);
			input_holder.filters = dropA.concat(border_glow);
			result_holder.filters = StaticFilters.copyFilterArrayFromObject({alpha:.3, blurY:2}, StaticFilters.black2px90Degrees_DropShadowA);
			filters = null;
			
			//width isn't dynamic for this bad boy
			_w = WIDTH;
			_h = HEIGHT;
		}
		
		override public function show(and_focus:Boolean = false, input_txt:String = ''):void {
			super.show(and_focus, input_txt);
			
			//when they make a section we're going to hide it and open the context menu
			addEventListener(TSEvent.CHANGED, onElementSelect, false, 0, true);
		}
		
		override protected function draw():void {
			super.draw();
			
			//gotta do the width cause of the mag glass
			input_tf.width = int(WIDTH - input_tf.x - INPUT_PADD);
			
			//input
			var g:Graphics = input_content.graphics;
			g.clear();
			g.beginFill(has_focus ? bg_color_input : bg_color_input_blur, bg_color_input_alpha);
			g.drawRect(0, 0, WIDTH, HEIGHT);
			
			g = input_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRoundRect(0, 0, WIDTH, HEIGHT, CURVE_RADIUS*2);
		}
		
		override protected function onEscape(event:KeyboardEvent=null):void {
			//if they press esc at any point, we want to close the whole thing
			//TSFrontController.instance.stopInfoMode();
			
			// instead, let's just blur the input
			TSFrontController.instance.releaseFocus(this, 'ItemSearch.onEscape()');
		}
		
		private function onElementSelect(event:TSEvent):void {		
			const element:SuperSearchElementItem = event.data as SuperSearchElementItem;
			
			if(element){
				//show the info window
				TSFrontController.instance.showItemInfo(element.value);
				
				//hide the toolbar
				TSFrontController.instance.stopInfoMode();
			}
		}
		
		public function hideResults():void {
			result_content.visible = false;
		}
		
		/********************************************************
		 * IFocusableComponent stuff
		 *******************************************************/
		
		override public function blur():void {
			super.blur();
			TSFrontController.instance.changeTipsVisibility(true, 'SuperSearch');
			
			// if mouse not over results, hide results
			if (result_content && result_content.visible) {
				if (StageBeacon.stage.getObjectsUnderPoint(StageBeacon.stage_mouse_pt).indexOf(result_content) == -1) {
					hideResults();
				}
			}

			draw();
		}
		
		override public function focus():void {
			super.focus();
			TSFrontController.instance.changeTipsVisibility(false, 'SuperSearch');
			draw();
		}
	}
}