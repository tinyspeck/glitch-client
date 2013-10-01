package com.tinyspeck.engine.view.ui.craftybot
{
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.making.Recipe;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.CraftyDialog;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class CraftyToolElementUI extends Sprite
	{
		private static const HEIGHT:uint = 55;
		private static const ICON_WH:uint = 35;
		private static const PADD:uint = 10;
		
		private var bg_holder:Sprite = new Sprite();
		private var icon_holder:Sprite = new Sprite();
		
		private var name_tf:TextField = new TextField();
		private var count_tf:TextField = new TextField();
		
		private var icon_view:ItemIconView;
		
		private var current_tool:String;
		
		private var w:int;
		
		private var is_built:Boolean;
		
		public function CraftyToolElementUI(w:int){
			this.w = w;
		}
		
		private function buildBase():void {						
			icon_holder.x = PADD;
			icon_holder.y = int(HEIGHT/2 - ICON_WH/2);
			bg_holder.addChild(icon_holder);
			
			TFUtil.prepTF(name_tf);
			name_tf.x = icon_holder.x + ICON_WH + PADD;
			name_tf.y = PADD-3;
			name_tf.width = w - PADD*2 - name_tf.x - 15; //extra is for the scroller
			bg_holder.addChild(name_tf);
			
			TFUtil.prepTF(count_tf);
			count_tf.width = name_tf.width;
			count_tf.x = name_tf.x;
			bg_holder.addChild(count_tf);
			
			addChild(bg_holder);
			
			bg_holder.mouseChildren = false;
			bg_holder.useHandCursor = bg_holder.buttonMode = true;
			bg_holder.addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			
			is_built = true;
		}
		
		public function show(item_class:String):void {
			if(!is_built) buildBase();
			current_tool = item_class;
			
			//draw bg
			var g:Graphics = bg_holder.graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRect(0, 0, w, HEIGHT);
			g.endFill();
			g.beginFill(0xcccccc);
			g.drawRect(0, HEIGHT-1, w, 1);
			
			//place the icon there
			if(icon_holder.name != item_class) {
				SpriteUtil.clean(icon_holder);
				icon_view = new ItemIconView(item_class, ICON_WH);
				icon_holder.addChild(icon_view);
				
				icon_holder.name = item_class;
			}
			
			//do the text stuff
			const item:Item = TSModelLocator.instance.worldModel.getItemByTsid(item_class);
			var name_txt:String = '<p class="crafty_job">';
			if(item){
				name_txt += item.label;
			}
			else {
				name_txt += 'Unknown';
			}
			
			name_txt += '</p>';
			name_tf.htmlText = name_txt;
			
			//setup the recipes holder
			setRecipes();
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
		}
		
		private function setRecipes():void {
			const recipes:Vector.<Recipe> = TSModelLocator.instance.worldModel.getRecipesByTool(current_tool);
			const total:uint = recipes.length;
			
			//set the count
			count_tf.htmlText = '<p class="crafty_tool_element_recipes">('+total+(total != 1 ? ' Recipes' : ' Recipe')+')</p>';
			count_tf.y = int(name_tf.y + name_tf.height - 2);
		}
		
		private function onClick(event:MouseEvent):void {
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			//show the recipes
			CraftyDialog.instance.showRecipes(current_tool);
		}
	}
}