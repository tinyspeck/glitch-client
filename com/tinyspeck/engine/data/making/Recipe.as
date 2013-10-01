package com.tinyspeck.engine.data.making
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.util.SortTools;

	public class Recipe extends AbstractTSDataEntity
	{
		public static const LEARNT_CANT_MAKE:uint = 0;
		public static const LEARNT_CAN_MAKE:uint = 1;
		public static const LEARNT_ACQUIRED_BY_OTHER_MEANS:uint = 2; //quest, achievement, etc.
		public static const LEARNT_UNRELEASED:uint = 3; //should never be sent to the client anyways
		
		public var name:String = '';
		public var id:String;
		public var skill:String;
		public var skills:Array;
		public var tool:String;
		public var tool_verb:String;
		public var tool_wear:int; //how much wear goes on the tool per make
		public var learnt:uint;
		public var discoverable:Boolean;
		public var wait_ms:int;
		public var task_limit:int;
		public var energy_cost:int;
		public var xp_reward:int;
		public var inputs:Vector.<RecipeComponent> = new Vector.<RecipeComponent>();
		public var outputs:Vector.<RecipeComponent> = new Vector.<RecipeComponent>();
		public var achievements:Array;
		public var disabled:Boolean;
		public var disabled_reason:String;
		
		public function Recipe(hashName:String){
			super(hashName);
			id = hashName;
		}
		
		public static function parseMultiple(object:Object):Vector.<Recipe> {
			const V:Vector.<Recipe> = new Vector.<Recipe>();
			var j:String;
			
			for(j in object){
				if (!object[j]) {
					CONFIG::debugging {
						Console.warn('WTF null object for recipe:'+j);
					}
					continue;
				} 
				V.push(fromAnonymous(object[j],j));
			}
			
			return V;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Recipe {
			var recipe:Recipe = new Recipe(hashName);
			var val:*;
			var j:String;
			var count:int;
			
			for(j in object){
				val = object[j];
				if(j == 'inputs'){
					count = 0;
					while(val && val[count]){
						recipe.inputs.push(new RecipeComponent(val[count][0], val[count][1], val[count][2]));
						count++;
					}
				}
				else if(j == 'outputs'){
					count = 0;
					while(val && val[count]){
						recipe.outputs.push(new RecipeComponent(val[count][0], val[count][1], val[count][2]));
						count++;
					}
				}
				else if(j in recipe){
					recipe[j] = val;
				}
				else{
					resolveError(recipe,object,j);
				}
			}
			
			//sort the inputs
			SortTools.vectorSortOn(recipe.inputs, ['item_class'], [Array.CASEINSENSITIVE]);
			
			return recipe;
		}
		
		public static function updateFromAnonymous(object:Object, recipe:Recipe):Recipe {
			recipe = fromAnonymous(object, recipe.hashName);
			
			return recipe;
		}
		
		public function isInput(item_class:String):Boolean {
			//loop through the inputs to see if we get a match
			var i:int;
			const total:int = inputs.length;
			
			for(i; i < total; i++){
				if(inputs[i].item_class == item_class) return true;
			}
			
			return false;
		}
		
		public function getComponentByItemTsid(item_class:String):RecipeComponent {
			//loop through the inputs to see if we get a match
			var i:int;
			const total:int = inputs.length;
			
			for(i; i < total; i++){
				if(inputs[i].item_class == item_class) return inputs[i];
			}
			
			return null;
		}
		
		public function get can_make():Boolean {
			return learnt == LEARNT_CAN_MAKE || learnt == LEARNT_ACQUIRED_BY_OTHER_MEANS;
		}
	}
}