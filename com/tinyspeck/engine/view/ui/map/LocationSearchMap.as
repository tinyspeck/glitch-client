package com.tinyspeck.engine.view.ui.map
{
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.view.gameoverlay.maps.HubMapDialog;
	import com.tinyspeck.engine.view.ui.supersearch.SuperSearch;
	import com.tinyspeck.engine.view.ui.supersearch.SuperSearchElementLocation;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.KeyboardEvent;

	public class LocationSearchMap extends SuperSearch
	{	
		private static const RESULTS_WIDTH:uint = 235;
		private static const INPUT_WIDTH:uint = 134;
		private static const INPUT_HEIGHT:uint = 24;
		private static const MAG_OFFSET:uint = 7;
		
		public function LocationSearchMap(){
			init(TYPE_LOCATIONS, 8);
			show();
		}
		
		override protected function buildBase():void {
			super.buildBase();
			
			//width isn't dynamic for this bad boy
			_w = RESULTS_WIDTH;
			
			const mag_glass:DisplayObject = new AssetManager.instance.assets.search_mag_glass();
			mag_glass.x = MAG_OFFSET;
			mag_glass.y = int(INPUT_HEIGHT/2 - mag_glass.height/2);
			input_content.addChild(mag_glass);
			
			input_tf.x = mag_glass.x + mag_glass.width + 2;
			
			//set some colors
			setAppearanceFromCSS('super_search_location');
			no_result_element.setAppearanceFromCSS('super_search_location_no_result');
			
			//place the result holder so that it's centered with the input
			result_holder.x = int(INPUT_WIDTH/2 - RESULTS_WIDTH/2);
			
			//tweak the filters
			input_holder.filters = [border_glow];
			result_holder.filters = StaticFilters.black2px90Degrees_DropShadowA;
			filters = null;
			
			//when they make a section we're going to hide it and open the map to the right place
			addEventListener(TSEvent.CHANGED, onElementSelect, false, 0, true);
		}
		
		override protected function draw():void {
			super.draw();
			
			input_tf.width = int(INPUT_WIDTH - input_tf.x - INPUT_PADD);
			input_tf.y = int(INPUT_HEIGHT/2 - input_tf.height/2);
			
			//input
			var g:Graphics = input_content.graphics;
			g.clear();
			g.beginFill(bg_color_input, bg_color_input_alpha);
			g.drawRect(0, 0, input_tf.width + INPUT_PADD*3, INPUT_HEIGHT);
			
			g = input_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRoundRect(0, 0, input_tf.width + INPUT_PADD*3, INPUT_HEIGHT, INPUT_HEIGHT);
		}
		
		private function onElementSelect(event:TSEvent):void {			
			const element:SuperSearchElementLocation = event.data as SuperSearchElementLocation;
						
			if(element){
				//tell the hub map to go where it needs to
				const is_street:Boolean = element.value != element.hub_tsid;
				HubMapDialog.instance.goToHubFromClick(element.hub_tsid, is_street ? element.value : '', '', is_street);
			}
			
			//reset the search
			show();
			blurInput();
		}
		
		override protected function onEscape(event:KeyboardEvent = null):void {
			super.onEscape(event);
			
			//reset the search
			show();
		}
		
		override public function get width():Number {
			return INPUT_WIDTH;
		}
		
		override public function get height():Number {
			return INPUT_HEIGHT;
		}
		
		public function set holder_offset(value:Number):void {
			_h = value;
			draw();
		}
	}
}