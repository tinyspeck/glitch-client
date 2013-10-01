package com.tinyspeck.engine.model
{
	public class TSEngineConstants
	{
		/** Not necessarily the current framerate, just what the physics and animations are built for */
		public static const TARGET_FRAMERATE:int = 30;
		/** Physics should run as often as possible, but Flash timers don't run faster than 60fps */
		public static const TARGET_PHYSICS_FRAMERATE:int = 60;
		
		public static const SWF_DIR:String = "swf/";
		public static const ITEM_DIR:String = "swf/item/";
		
		//These have moved to the LayoutModel and are set via CSS under main_layout
//		public static const MAX_LOCATION_VIEWPORT_WIDTH:int = 1000;
//		public static const MIN_LOCATION_VIEWPORT_WIDTH:int = 500; // was 480
//		public static const MAX_LOCATION_VIEWPORT_HEIGHT:int = 700;
//		public static const MIN_LOCATION_VIEWPORT_HEIGHT:int = 400; // was 310
		public static const MIN_PACK_HEIGHT:int = 132;
		public static const MAX_LEVEL:int = 60;
		
		public static const pri_map:Object = {
			'2' : 'log sckt msgs (no x,y)',
			'9' : 'log x,y sckt msgs',
			'5' : 'log key up/down',
			'11' : 'log location_event/location_item_moves msgs',
			'13' : 'log item_state/status msgs',
			'1333' : 'log itemstack_state msgs',
			'12' : 'log ping msgs',
			'66' : 'log urls',
			'76' : 'log asset animation stuff',
			'83' : 'log sounds',
			'35' : 'log choices/menus/dialogs',
			'99' : 'log focus/blur things',
			'1' : 'log flashvar getting',
			'111' : 'log sprite shit sheet',
			'44' : 'log avatar path stuff',
			'79' : 'log data loading things (decos and deco swfs)',
			'48' : 'log threadLoader',
			'4' : 'log JS_interface things',
			'6' : 'log engine pool stuff',
			'7' : 'bounds stuff'
		};
		
		public static const bool_arg_map:Object = {
			'SWF_show_tree_str' : 'show json as msgs arrive',
			'SWF_jetpack' : 'jetpack on',
			'SWF_no_geo_collision': 'dont collide w/geo',
			'SWF_no_pc_collision': 'dont collide w/pcs',
			'SWF_no_item_collision': 'dont collide w/items',
			'SWF_firebug': 'log to firebug',
			'SWF_scribe': 'log to scribe'
		};
	}
}