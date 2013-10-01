package com.tinyspeck.engine.view.ui.craftybot
{
	import com.tinyspeck.engine.data.making.Recipe;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.util.SortTools;
	
	import flash.display.Graphics;
	import flash.display.Sprite;

	public class CraftyToolsUI extends Sprite
	{
		private static const SEARCH_H:uint = 30;
		
		private var search_holder:Sprite = new Sprite();
		
		private var elements:Vector.<CraftyToolElementUI> = new Vector.<CraftyToolElementUI>();
		private var recipe_search:CraftyRecipeSearch;
		
		private var w:int;
		
		private var is_built:Boolean;
		
		public function CraftyToolsUI(w:int){
			this.w = w;
		}
		
		private function buildBase():void {
			
			//draw the BG/border
			var g:Graphics = search_holder.graphics;
			g.beginFill(0xebebeb);
			g.drawRect(0, 0, w, SEARCH_H);
			g.endFill();
			g.beginFill(0xcccccc);
			g.drawRect(0, SEARCH_H-1, w, 1);
			addChild(search_holder);
			
			const search_padd:uint = 8;
			recipe_search = new CraftyRecipeSearch();
			recipe_search.width = w - search_padd*2 - 15;
			recipe_search.x = search_padd;
			recipe_search.y = int(SEARCH_H/2 - recipe_search.height/2);
			search_holder.addChild(recipe_search);
			
			is_built = true;
		}
		
		public function show():void {
			//display the tools and recipe counts
			if(!is_built) buildBase();
			
			//show the search
			recipe_search.show();
			
			//sort the recipes by tool
			const recipes:Vector.<Recipe> = TSModelLocator.instance.worldModel.recipes;
			var total:int = elements.length;
			var last_tool:String;
			var i:uint;
			var recipe:Recipe;
			var element:CraftyToolElementUI;
			
			SortTools.vectorSortOn(recipes, ['tool'], [Array.CASEINSENSITIVE]);
			
			//reset pool
			for(i = 0; i < total; i++){
				elements[int(i)].hide();
			}			
			
			total = recipes.length;
			for(i = 0; i < total; i++){
				recipe = recipes[int(i)];
				if(recipe.can_make && recipe.tool != last_tool){
					if(last_tool && TSModelLocator.instance.worldModel.getRecipesByTool(last_tool).length){
						//toss it on there
						element = getElementFromPool();
						element.show(last_tool);
						addChildAt(element, 0);
					}
					last_tool = recipe.tool;
				}
			}
			
			//last one, toss it on there
			if(last_tool && TSModelLocator.instance.worldModel.getRecipesByTool(last_tool).length){
				element = getElementFromPool();
				element.show(last_tool);
				addChildAt(element, 0);
			}
			
			refresh();
		}
		
		public function refresh():void {
			if(!is_built) return;
			
			const total:uint = elements.length;
			var i:int;
			var element:CraftyToolElementUI;
			var next_y:int = search_holder.y + SEARCH_H;
			
			for(i; i < total; i++){
				element = elements[int(i)];
				if(element.parent){
					element.y = next_y;
					next_y += element.height;
				}
			}
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
			if(!is_built) return;
			
			//hide the search
			recipe_search.hide();
		}
		
		private function getElementFromPool():CraftyToolElementUI {
			const total:uint = elements.length;
			var i:int;
			var element:CraftyToolElementUI;
			
			for(i; i < total; i++){
				element = elements[int(i)];
				if(!element.parent) return element;
			}
			
			element = new CraftyToolElementUI(w);
			elements.push(element);
			
			return element;
		}
	}
}