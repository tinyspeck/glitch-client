package com.tinyspeck.engine.model {
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.item.Verb;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.signals.AbstractPropertyProvider;
	
	public class InteractionMenuModel extends AbstractPropertyProvider {
		public static const TYPE_LOC_DISAMBIGUATOR:String = 'TYPE_LOC_DISAMBIGUATOR';
		
		public static const TYPE_HUBMAP_STREET_MENU:String = 'TYPE_HUBMAP_STREET_MENU';
		public static const TYPE_LIST_PC_VERB_MENU:String = 'TYPE_LIST_PC_VERB_MENU';
		public static const TYPE_LIST_GROUP_VERB_MENU:String = 'TYPE_LIST_GROUP_VERB_MENU';
		public static const TYPE_LOC_PC_VERB_MENU:String = 'TYPE_LOC_PC_VERB_MENU';
		public static const TYPE_PC_VERB_TARGET_ITEMSTACK:String = 'TYPE_PC_VERB_TARGET_ITEMSTACK';
		public static const TYPE_PC_VERB_TARGET_ITEMSTACK_COUNT:String = 'TYPE_PC_VERB_TARGET_ITEMSTACK_COUNT';
		public static const TYPE_GARDEN_VERB_MENU:String = 'TYPE_GARDEN_VERB_MENU';
		
		public static const TYPE_LOC_IST_VERB_MENU:String = 'TYPE_LOC_IST_VERB_MENU';
		public static const TYPE_PACK_IST_VERB_MENU:String = 'TYPE_PACK_IST_VERB_MENU';
		public static const TYPE_IST_VERB_COUNT:String = 'TYPE_IST_VERB_COUNT';
		public static const TYPE_IST_VERB_TARGET_ITEMSTACK:String = 'TYPE_IST_VERB_TARGET_ITEMSTACK';
		public static const TYPE_IST_VERB_TARGET_ITEM:String = 'TYPE_IST_VERB_TARGET_ITEM';
		public static const TYPE_IST_VERB_TARGET_ITEM_COUNT:String = 'TYPE_IST_VERB_TARGET_ITEM_COUNT';
		public static const TYPE_IST_VERB_TARGET_PC:String = 'TYPE_IST_VERB_TARGET_PC';
		public static const TYPE_GARDEN_PLANT_SEED:String = 'TYPE_GARDEN_PLANT_SEED';
		
		public static const VERB_SPECIAL_PC_INFO:String = 'VERB_SPECIAL_PC_INFO';
		public static const VERB_SPECIAL_LOCATION_INFO:String = 'VERB_SPECIAL_LOCATION_INFO';
		
		public var active_tsid:String;
		public var type:String;
		public var chosen_verb:Verb;
		public var chosen_target_itemstack:Itemstack;
		public var chosen_target_item:Item;
		public var chosen_target_pc:PC;
		public var by_click:Boolean;
		public var choices:Array = [];
		public var default_to_one:Boolean;
		
		public var pcmenu:Object;
		
		public function InteractionMenuModel() {
			super();
		}
		
		public function reset():void {
			active_tsid = '';
			type = '';
			chosen_verb = null;
			chosen_target_itemstack = null;
			chosen_target_item = null;
			chosen_target_pc = null;
			by_click = false
			choices.length = 0;
			default_to_one = TSModelLocator.instance.prefsModel.int_menu_default_to_one;
		}
	}
}