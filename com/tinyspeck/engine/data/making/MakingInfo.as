package com.tinyspeck.engine.data.making
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.util.SortTools;

	public class MakingInfo extends AbstractTSDataEntity
	{
		public var can_discover:Boolean;
		public var specify_quantities:Boolean;
		public var no_modal:Boolean;
		public var item_class:String;
		public var item_tsid:String;
		public var verb:String;
		public var slots:int;
		public var fuel_remaining:int;
		public var knowns:Vector.<Recipe> = new Vector.<Recipe>();
		public var unknowns:Vector.<int> = new Vector.<int>();
		
		public function MakingInfo(hasnName:String){
			super(hasnName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):MakingInfo {
			var info:MakingInfo = new MakingInfo(hashName);
			var val:*;
			var j:String;
			var k:String;
			var recipe:Recipe;
			
			for(j in object){
				val = object[j];
				if(j == 'knowns'){
					for(k in val){
						info.knowns.push(Recipe.fromAnonymous(val[k], k));
					}
				}
				else if(j == 'unknowns'){
					for(k in val){
						info.unknowns.push(k);
					}
				}
				else if(j in info){
					info[j] = val;
				}
				else{
					resolveError(info,object,j);
				}
			}
			
			//sort the knowns alpha styles
			SortTools.vectorSortOn(info.knowns, ['name'], [Array.CASEINSENSITIVE]);
			
			return info;
		}
		
		public static function updateFromAnonymous(object:Object, info:MakingInfo):MakingInfo {
			info = fromAnonymous(object, info.hashName);
			
			return info;
		}
	}
}