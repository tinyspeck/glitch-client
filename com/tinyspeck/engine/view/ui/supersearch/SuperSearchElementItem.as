package com.tinyspeck.engine.view.ui.supersearch
{
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	
	import flash.display.Graphics;
	import flash.filters.GlowFilter;

	public class SuperSearchElementItem extends SuperSearchElement
	{
		protected static const DEFAULT_IMAGE_WH:uint = 40;
		protected static const ICON_BUFFER:uint = 3;
		
		private var icon:ItemIconView;
		
		public function SuperSearchElementItem(show_images:Boolean, image_wh:uint = SuperSearchElementItem.DEFAULT_IMAGE_WH, draw_bg_on_image:Boolean = false){
			super(show_images);
			
			IMG_WH = image_wh;
			
			//draw the image holder if we are showing images
			if(show_images){
				image_bg_color = CSSManager.instance.getUintColorValueFromStyle('super_search_item', 'backgroundColor', 0xffffff);
				image_border_color = CSSManager.instance.getUintColorValueFromStyle('super_search_item', 'borderColor', 0x878787);
				
				const g:Graphics = image_holder.graphics;
				g.beginFill(image_bg_color, draw_bg_on_image ? 1 : 0);
				g.drawRoundRect(0, 0, IMG_WH, IMG_WH, 6);
				
				if(draw_bg_on_image){
					const outter_glow:GlowFilter = new GlowFilter();
					outter_glow.color = image_border_color;
					outter_glow.alpha = 1;
					outter_glow.blurX = outter_glow.blurY = 2;
					outter_glow.strength = 10;
					
					image_holder.filters = [outter_glow];
				}
			}
		}
		
		public function show(w:int, item:Item, sub_label:String = '', str_to_highlight:String = ''):void {
			if(!item) return;
			
			_w = w;
			current_name = item.label;
			current_value = item.tsid;
			current_sub_label = sub_label;
			current_highlight = str_to_highlight;
			
			draw();
			visible = true;
		}
		
		override protected function setImage():void {
			if(image_holder.name == current_name) return;
			
			while(image_holder.numChildren) image_holder.removeChildAt(0);
			
			if(current_value){
				image_holder.name = current_name;
				icon = new ItemIconView(current_value, IMG_WH - ICON_BUFFER*2);
				icon.x = icon.y = ICON_BUFFER;
				image_holder.addChild(icon);
				image_holder.y = int(_h/2 - image_holder.height/2);
			}
		}
	}
}