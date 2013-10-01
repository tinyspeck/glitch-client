package com.tinyspeck.engine.view.ui.craftybot
{
	import com.tinyspeck.engine.data.making.Recipe;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.util.SortTools;
	
	import flash.display.Graphics;
	import flash.display.Sprite;

	public class CraftyRecipesUI extends Sprite
	{
		private static const SEARCH_H:uint = 30;
		private static const PADD:uint = 7;
		
		private var search_holder:Sprite = new Sprite();
		
		private var elements:Vector.<CraftyRecipeElementUI> = new Vector.<CraftyRecipeElementUI>();
		private var recipe_search:CraftyRecipeSearch;
		
		private var w:int;
		
		private var is_built:Boolean;
		
		public function CraftyRecipesUI(w:int){
			this.w = w;
		}
		
		private function buildBase():void {
			//draw the BG
			var g:Graphics = search_holder.graphics;
			g.beginFill(0xebebeb);
			g.drawRect(0, 0, w, SEARCH_H);
			addChild(search_holder);
			
			const search_padd:uint = 7;
			recipe_search = new CraftyRecipeSearch();
			recipe_search.width = w - search_padd*2 - 15;
			recipe_search.x = search_padd;
			recipe_search.y = int(SEARCH_H/2 - recipe_search.height/2);
			search_holder.addChild(recipe_search);
			
			is_built = true;
		}
		
		public function show(tool_class:String):void {
			//display the tools and recipe counts
			if(!is_built) buildBase();
			
			//show the search
			recipe_search.show();
			
			//sort the recipes by tool
			const recipes:Vector.<Recipe> = TSModelLocator.instance.worldModel.getRecipesByTool(tool_class);
			var total:int = elements.length;
			var last_tool:String;
			var i:uint;
			var recipe:Recipe;
			var element:CraftyRecipeElementUI;
			
			SortTools.vectorSortOn(recipes, ['name'], [Array.CASEINSENSITIVE]);
			
			//reset pool
			for(i = 0; i < total; i++){
				elements[int(i)].hide();
			}			
			
			total = recipes.length;
			for(i = 0; i < total; i++){
				recipe = recipes[int(i)];
				
				//toss it on there
				element = getElementFromPool();
				element.show(recipe.outputs[0].item_class);
				addChildAt(element, 0);
			}
			
			refresh();
		}
		
		public function refresh():void {
			if(!is_built) return;
			
			const total:uint = elements.length;
			var i:int;
			var element:CraftyRecipeElementUI;
			var next_y:int = search_holder.y + SEARCH_H + 3;
			
			for(i; i < total; i++){
				element = elements[int(i)];
				if(element.parent){
					element.y = next_y;
					next_y += element.height + PADD;
				}
			}
			
			//little padding
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0,0);
			g.drawRect(0, next_y-PADD, 1, PADD);
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
			if(!is_built) return;
			
			//hide the search
			recipe_search.hide();
		}
		
		private function getElementFromPool():CraftyRecipeElementUI {
			const total:uint = elements.length;
			var i:int;
			var element:CraftyRecipeElementUI;
			
			for(i; i < total; i++){
				element = elements[int(i)];
				if(!element.parent) return element;
			}
			
			element = new CraftyRecipeElementUI(w - PADD*2 - 15);
			element.x = PADD;
			elements.push(element);
			
			return element;
		}
	}
}