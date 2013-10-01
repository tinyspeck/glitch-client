package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.engine.port.SignpostDialog;
	import com.tinyspeck.engine.view.ui.supersearch.SuperSearch;
	import com.tinyspeck.engine.view.util.StaticFilters;

	public class SignpostSearch extends SuperSearch
	{
		public static const HEIGHT:uint = 46;
		
		private static const WIDTH:uint = 195;
		private static const PADD:uint = 7;
		
		public function SignpostSearch(){
			show_images = false;
			init(TYPE_BUDDIES, 2, SignpostDialog.DEFAULT_TXT);
		}
		
		override protected function buildBase():void {
			super.buildBase();
			
			//set the look
			setAppearanceFromCSS('signpost_search');
			filters = null;
			result_holder.filters = [border_glow];
			input_tf.filters = StaticFilters.black1px90Degrees_DropShadowA;
			
			//width isn't dynamic for this bad boy
			_w = WIDTH;
			_h = HEIGHT;
		}
		
		override public function set direction(value:String):void {
			super.direction = value;
			
			//we don't want a gap at all at the top
			if(value == DIRECTION_DOWN){
				result_scroller.y = 0;
			}
		}
	}
}