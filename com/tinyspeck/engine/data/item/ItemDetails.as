package com.tinyspeck.engine.data.item
{
	import com.tinyspeck.engine.data.location.Location;

	public class ItemDetails extends AbstractItemEntity
	{
		/****************************************************************
		 * NOTE: Commented out public vars ARE part of the API returns
		 * 		 but to save space and not cache repeated data they
		 *       are ommited.
		 ****************************************************************/
		public var item_id:int;
		public var item_class:String;
		//public var iconic_url:String;
		public var info:String;
		public var max_stack:int;
		public var base_cost:int;
		public var tool_wear:int;
		//public var required_skill:String;
		public var warnings:Vector.<String> = new Vector.<String>();
		public var tips:Vector.<String> = new Vector.<String>();
		//public var has_infopage:Boolean;
		public var grow_time:int;
		public var item_url_part:String;
		public var name_single:String;
		public var name_plural:String;
		public var info_url:String;
		public var is_sdbable:Boolean;
		
		public function ItemDetails(hashName:String){
			super(hashName);
		}
		
		public static function parseMultiple(object:Object):Vector.<ItemDetails> {
			var V:Vector.<ItemDetails> = new Vector.<ItemDetails>();
			
			for(var j:String in object){
				V.push(fromAnonymous(object[j],j));
			}
			
			return V;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):ItemDetails {
			var item_details:ItemDetails = new ItemDetails(hashName);
			var val:*;
			var j:String;
			var count:int;
			
			for(j in object){
				val = object[j];
				if(j == 'warnings' && val){
					count = 0;
					while(val && val[count]){
						item_details.warnings.push(val[count]);
						count++;
					}
				}
				else if(j == 'tips' && val){
					count = 0;
					while(val && val[count]){
						item_details.tips.push(val[count]);
						count++;
					}
				}
				else if(j in item_details){
					item_details[j] = val;
				}
				else if(j != 'iconic_url' && j != 'required_skill' && j != 'has_infopage'){
					resolveError(item_details,object,j);
				}
			}
			
			return item_details;
		}
		
		public static function updateFromAnonymous(object:Object, item_details:ItemDetails):ItemDetails {
			item_details = fromAnonymous(object, item_details.hashName);
			
			return item_details;
		}
	}
}