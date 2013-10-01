package com.tinyspeck.engine.view.ui.supersearch
{
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.making.Recipe;
	import com.tinyspeck.engine.data.making.RecipeComponent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	
	import flash.display.Graphics;
	import flash.filters.GlowFilter;

	public class SuperSearchElementRecipe extends SuperSearchElement
	{
		protected static const DEFAULT_IMAGE_WH:uint = 40;
		protected static const ICON_BUFFER:uint = 3;
		protected static const MAX_CHARS_INGREDIENTS:uint = 40;
		
		private var icon:ItemIconView;
		
		public function SuperSearchElementRecipe(show_images:Boolean, image_wh:uint = SuperSearchElementRecipe.DEFAULT_IMAGE_WH, draw_bg_on_image:Boolean = false){
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
		
		public function show(w:int, recipe:Recipe, str_to_highlight:String = ''):void {
			if(!recipe) return;
			
			_w = w;
			current_name = recipe.name;
			current_value = recipe.outputs.length ? recipe.outputs[0].item_class : null;
			current_sub_label = StringUtil.truncate(getInputText(recipe.inputs), MAX_CHARS_INGREDIENTS);
			current_highlight = str_to_highlight;
			
			draw();
			visible = true;
		}
		
		private function getInputText(inputs:Vector.<RecipeComponent>):String {
			if(!inputs || !inputs.length) return '';
			
			const total:uint = inputs.length;
			var txt:String = '';
			var i:int;
			var component:RecipeComponent;
			var item:Item;
			
			for(i; i < total; i++){
				component = inputs[int(i)];
				item = TSModelLocator.instance.worldModel.getItemByTsid(component.item_class);
				txt += component.count+' '+(component.count != 1 ? item.label_plural : item.label);
				
				if(i < total-1) txt += ', ';
			}
			
			return txt;
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