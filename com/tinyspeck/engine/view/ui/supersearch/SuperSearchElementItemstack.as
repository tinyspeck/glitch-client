package com.tinyspeck.engine.view.ui.supersearch
{
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	
	import flash.display.Graphics;
	import flash.filters.GlowFilter;

	public class SuperSearchElementItemstack extends SuperSearchElement
	{
		protected static const DEFAULT_IMAGE_WH:uint = 40;
		protected static const ICON_BUFFER:uint = 3;
		
		private var icon:ItemIconView;
		
		public function SuperSearchElementItemstack(show_images:Boolean, image_wh:uint = SuperSearchElementItemstack.DEFAULT_IMAGE_WH, draw_bg_on_image:Boolean = false){
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
		
		public function show(w:int, itemstack:Itemstack, sub_label:String = '', str_to_highlight:String = ''):void {
			if(!itemstack) return;
			
			_w = w;
			current_name = itemstack.label;
			current_value = itemstack.tsid;
			current_sub_label = sub_label;
			current_highlight = str_to_highlight;
			
			draw();
			visible = true;
		}
		
		override protected function setImage():void {
			if(image_holder.name == current_value) return;
			
			while(image_holder.numChildren) image_holder.removeChildAt(0);
			
			if(current_value){
				const itemstack:Itemstack = TSModelLocator.instance.worldModel.getItemstackByTsid(current_value);
				if(!itemstack) return;
				
				image_holder.name = current_value;
				icon = new ItemIconView(itemstack.class_tsid, IMG_WH - ICON_BUFFER*2);
				icon.x = icon.y = ICON_BUFFER;
				image_holder.addChild(icon);
				image_holder.y = int(_h/2 - image_holder.height/2);
			}
		}
	}
}