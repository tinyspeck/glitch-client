package com.tinyspeck.engine.view.ui.craftybot
{
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CraftyDialog;
	import com.tinyspeck.engine.view.ui.supersearch.SuperSearch;
	import com.tinyspeck.engine.view.ui.supersearch.SuperSearchElementRecipe;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.FocusEvent;
	
	public class CraftyRecipeSearch extends SuperSearch
	{
		private static const INPUT_HEIGHT:uint = 21;
		
		public function CraftyRecipeSearch(){
			show_images = true;
			init(TYPE_RECIPES);
			
			height = INPUT_HEIGHT + 5;
		}
		
		override protected function buildBase():void {
			super.buildBase();
			
			const mag_glass:DisplayObject = new AssetManager.instance.assets.search_mag_glass();
			mag_glass.x = 5;
			mag_glass.y = int(INPUT_HEIGHT/2 - mag_glass.height/2 + 1);
			input_content.addChild(mag_glass);
			
			input_tf.x = mag_glass.x + mag_glass.width + 2;
			
			border_color = 0xcbcbcb;
			border_glow.color = border_color;
			filters = [border_glow];
			
			addEventListener(TSEvent.CHANGED, onSelect, false, 0, true);
			addEventListener(TSEvent.ACTIVITY_HAPPENED, redraw, false, 0, true);
		}
		
		override protected function draw():void {
			super.draw();
			
			input_tf.width = int(width - input_tf.x - INPUT_PADD);
			input_tf.y = int(INPUT_HEIGHT/2 - input_tf.height/2);
			
			//input
			var g:Graphics = input_content.graphics;
			g.clear();
			g.beginFill(bg_color_input, bg_color_input_alpha);
			g.drawRect(0, 0, input_tf.width + INPUT_PADD*3+1, INPUT_HEIGHT);
			
			const top_radius:Number = result_content.visible ? _corner_rad : 11;
			const bottom_radius:Number = result_content.visible ? 0 : 11;
			g = input_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRoundRectComplex(0, 0, input_tf.width + INPUT_PADD*3+1, INPUT_HEIGHT, top_radius, top_radius, bottom_radius, bottom_radius);
		}
		
		private function redraw(event:Event = null):void {
			//shortcut method to call draw
			draw();
		}
		
		private function onSelect(event:TSEvent):void {
			const element:SuperSearchElementRecipe = event.data as SuperSearchElementRecipe;
			
			if(element){
				CraftyDialog.instance.showDetails(element.value);
			}
			
			//reset the search
			show();
		}
		
		override protected function onInputFocus(event:FocusEvent = null):void {
			super.onInputFocus(event);
			draw();
		}
		
		override protected function onInputBlur(event:FocusEvent):void {
			super.onInputBlur(event);
			draw();
		}
		
		override public function get height():Number {
			return INPUT_HEIGHT;
		}
	}
}