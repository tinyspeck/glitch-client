package com.tinyspeck.engine.model
{
	import com.tinyspeck.engine.data.decorate.Swatch;
	import com.tinyspeck.engine.data.furniture.FurnUpgrade;
	import com.tinyspeck.engine.data.house.ConfigOption;
	import com.tinyspeck.engine.data.itemstack.FurnitureConfig;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.model.signals.AbstractPropertyProvider;
	import com.tinyspeck.engine.pack.BagUI;

	public class DecorateModel extends AbstractPropertyProvider
	{
		public const HANGING_ITEM_TSIDS:Array = ['furniture_ceilinglamp', 'furniture_ceilingdeco'];
		public var upgrade_itemstack:Itemstack;
		public var was_config:Object;
		public var has_name_changed:Boolean;
		public var has_config_changed:Boolean;
		public var has_chassis_changed:Boolean;
		public var chosen_upgrade:FurnUpgrade;
		public var was_furn_config:FurnitureConfig;
		public var user_facing_right:Boolean;
		public var was_upgrade_id:String;
		public var was_name:String;
		
		public var chassis_config_options:Vector.<ConfigOption> = new Vector.<ConfigOption>();
		
		public const upgradesV:Vector.<FurnUpgrade> = new Vector.<FurnUpgrade>();
		public const wallpapers:Vector.<Swatch> = new Vector.<Swatch>();
		public const floors:Vector.<Swatch> = new Vector.<Swatch>();
		public const ceilings:Vector.<Swatch> = new Vector.<Swatch>();
		
		// TODO: get this data from the GS
		public const furniture_panesA:Array = [
			{id:BagUI.CATEGORY_ALL, label:'furniture item:', label_plural:'furniture items:', items:[]},
			{id:'seating', label:'seating', label_plural:'seating', items:['furniture_bench', 'furniture_loveseat', 'furniture_sofa', 'furniture_stool', 'furniture_chair', 'furniture_armchair']},
			{id:'beds', label:'bed', label_plural:'beds', items:['furniture_bed']},
			{id:'fireplaces', label:'fireplace', label_plural:'fireplaces', items:['furniture_fireplace']},
			{id:'tables', label:'table', label_plural:'tables', items:['furniture_sidetable', 'furniture_coffeetable', 'furniture_table', 'furniture_desk', 'furniture_counter']},
			{id:'shelves', label:'shelf', label_plural:'shelves', items:['furniture_shelf', 'furniture_bookcase']},
			{id:'storage', label:'storage', label_plural:'storage', items:[], item_prefixes:['bag_furniture_']},
			{id:'lights', label:'light', label_plural:'lights', items:['furniture_tablelamp', 'furniture_walllamp', 'furniture_floorlamp', 'furniture_ceilinglamp']},
			{id:'rugs', label:'rug', label_plural:'rugs', items:['furniture_rug']},
			{id:'windows', label:'window', label_plural:'windows', items:['furniture_window']},
			{id:'doors', label:'door', label_plural:'doors', items:['furniture_door']},
			{id:'decorations', label:'decoration', label_plural:'decorations', items:['furniture_walldeco', 'furniture_tabledeco', 'furniture_roomdeco', 'furniture_ceilingdeco']},
			{id:'trophies', label:'trophy', label_plural:'trophies', items:[], item_prefixes:['trophy_']}
		];
		
		public function DecorateModel(){}
				
		public function getSwatchByTypeAndTsid(tsid:String, type:String):Swatch {
			var V:Vector.<Swatch>;
			
			switch(type){
				default:
				case Swatch.TYPE_WALLPAPER:
					V = wallpapers;
					break;
				case Swatch.TYPE_FLOOR:
					V = floors;
					break;
				case Swatch.TYPE_CEILING:
					V = ceilings;
					break;
			}
			
			//find it!
			var i:int;
			var total:int = V.length;
			var swatch:Swatch;
			
			for(i; i < total; i++){
				swatch = V[int(i)];
				if(swatch.tsid == tsid) return swatch;
			}
			
			return null;
		}
		
		public function getWallpaperSwatchByTsid(tsid:String):Swatch {
			//shortcut method
			return getSwatchByTypeAndTsid(tsid, Swatch.TYPE_WALLPAPER);
		}
		
		public function getFloorSwatchByTsid(tsid:String):Swatch {
			//shortcut method
			return getSwatchByTypeAndTsid(tsid, Swatch.TYPE_FLOOR);
		}
		
		public function getCeilingSwatchByTsid(tsid:String):Swatch {
			//shortcut method
			return getSwatchByTypeAndTsid(tsid, Swatch.TYPE_CEILING);
		}
		
		public function getFurniturePaneById(id:String):Object {
			var i:int;
			var total:int = furniture_panesA.length;
			var ob:Object;
			
			for(i; i < total; i++){
				ob = furniture_panesA[int(i)];
				if(ob.id == id) return ob;
			}
			
			return null;
		}
	}
}