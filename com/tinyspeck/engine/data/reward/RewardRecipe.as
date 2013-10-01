package com.tinyspeck.engine.data.reward
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class RewardRecipe extends AbstractTSDataEntity
	{				
		public var class_tsid:String;
		public var label:String;
		public var recipe_id:int;
		
		public function RewardRecipe(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):RewardRecipe {
			var recipe:RewardRecipe = new RewardRecipe(hashName);
			var val:*;
			
			for(var i:String in object){
				val = object[i];
				if(i in recipe){
					recipe[i] = val;
				}
				else{
					resolveError(recipe,object,i);
				}
			}
			
			return recipe;
		}
		
		public static function updateFromAnonymous(object:Object, recipe:RewardRecipe):RewardRecipe {
			recipe = fromAnonymous(object, recipe.hashName);
			
			return recipe;
		}
	}
}