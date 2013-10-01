package com.tinyspeck.engine.data.house
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.util.MathUtil;
	
	import flash.utils.Dictionary;

	public class CultivationsChoice extends AbstractTSDataEntity
	{
		/*
		"proto_jellisac_mound"		: {
		"class_id"		: "proto_jellisac_mound",
		"label"			: "Young Jellisac Mound",
		"imagination_cost"	: 0,
		"min_level"		: 6
		}*/
		
		client var item:Item;
		client var will_fit:Boolean;
		client var need_imagination:int; // this will be the amount of imagination the user needs
		client var need_level:int; // this will get set to 0 if the user has a high enough level, and if not, be the same as min_level
		
		//public var can_place:Boolean = true; //no longer here cause we'ze done testin'
		public var tsid:String;
		public var class_id:String;
		public var label:String;
		public var imagination_cost:int;
		public var min_level:int;
		public var can_place:Boolean;
		public var placement_warning:String;
		
		public function CultivationsChoice(tsid:String){
			super(tsid);
			this.tsid = tsid;
		}
		
		public static function fromAnonymous(object:Object, tsid:String):CultivationsChoice {
			const choice:CultivationsChoice = new CultivationsChoice(tsid);
			return updateFromAnonymous(object, choice);
		}
		
		public static function updateFromAnonymous(object:Object, choice:CultivationsChoice):CultivationsChoice {
			var j:String;
			
			for(j in object){
				if(j in choice){
					choice[j] = object[j];
				}
				else {
					resolveError(choice, object, j);
				}
			}
			choice.client::item = TSModelLocator.instance.worldModel.getItemByTsid(choice.class_id);
			/*
			// for testing!
			choice.min_level*= 2;
			choice.imagination_cost = MathUtil.randomInt(0, 20);
			*/
			return choice;
		}
	}
}