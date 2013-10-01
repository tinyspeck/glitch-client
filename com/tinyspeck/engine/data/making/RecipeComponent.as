package com.tinyspeck.engine.data.making
{
	public class RecipeComponent
	{
		public var item_class:String;
		public var count:Number;
		public var consumable:Boolean;
		
		public function RecipeComponent(item_class:String, count:Number, consumable:Boolean){
			this.item_class = item_class;
			this.count = count;
			this.consumable = consumable;
		}
	}
}