package com.tinyspeck.engine.data.pc
{
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.util.SortTools;

	public class AvatarLook extends AbstractPCEntity
	{
		public var outfit_id:String;
		public var is_current:Boolean;
		public var last_worn:uint;
		public var worn_count:uint;
		public var total_time:uint;
		public var singles_base:String;
		public var sheets_base:String;
		
		public function AvatarLook(outfit_id:String){
			super(outfit_id);
			this.outfit_id = outfit_id;
		}
		
		public static function parseMultiple(object:Object):Vector.<AvatarLook> {
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			if(!pc) return null;
			
			//create the vector if it's not there yet
			if(!pc.previous_looks) pc.previous_looks = new Vector.<AvatarLook>();
			
			var k:String;
			var look:AvatarLook;
			/*
			for(k in object){
				look = pc.getLookById(k);
				if(look){
					look = updateFromAnonymous(object[k], look);
				}
				else {
					look = fromAnonymous(object[k], k);
					pc.previous_looks.push(look);
				}
			}
			*/
			
			//do this for now until the client manages the outfits better
			pc.previous_looks.length = 0;
			for(k in object){
				look = fromAnonymous(object[k], k);
				pc.previous_looks.push(look);
			}
			
			//sort them by last_worn
			SortTools.vectorSortOn(pc.previous_looks, ['last_worn'], [Array.NUMERIC | Array.DESCENDING]);
			
			return pc.previous_looks;
		}
		
		public static function fromAnonymous(object:Object, outfit_id:String):AvatarLook {
			const look:AvatarLook = new AvatarLook(outfit_id);
			return updateFromAnonymous(object, look);
		}
		
		public static function updateFromAnonymous(object:Object, look:AvatarLook):AvatarLook {
			var k:String;
			
			//reset it's current value
			look.is_current = false;
			
			for(k in object){
				if(k in look){
					look[k] = object[k];
				}
				else {
					resolveError(look, object, k);
				}
			}
			
			return look;
		}
	}
}