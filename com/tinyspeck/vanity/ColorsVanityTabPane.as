package com.tinyspeck.vanity {
	import com.tinyspeck.engine.data.pc.AvatarConfig;
	import com.tinyspeck.engine.loader.AvatarResourceManager;
	import com.tinyspeck.engine.util.ColorUtil;
	
	public class ColorsVanityTabPane extends AbstractVanityTabPane {
		
		public function ColorsVanityTabPane(changeCallBack:Function, clickSubscriberThingCallBack:Function) {
			super(changeCallBack, clickSubscriberThingCallBack);
			
			tpane_w = VanityModel.colors_tab_panel_w;
			types = VanityModel.colors_name_map;
			options = VanityModel.color_options;
			
			bt_wh = VanityModel.colors_bt_wh;
			bt_mg = VanityModel.colors_bt_mg;
			pane_padd = VanityModel.colors_pane_padd;
			paging_sp_height = VanityModel.colors_paging_sp_height;
			
			per_page = VanityModel.colors_pane_per_page;
			cols = VanityModel.colors_pane_cols;
			rows = VanityModel.colors_pane_rows;
			
			tab_sortA = VanityModel.color_tabs_sortA;
			
			type_base_hash_suffix = '_color';
			
			init();
		}
		
		override protected function getSortedObjects(options:Object):Array {
			var A:Array = [];
			for (var id:String in options) {
				var option:Object = options[id];
				A.push({
					id: id,
					h: option.h,
					s: option.s,
					v: option.v,
					is_subscriber: option.is_subscriber ? 1 : 0,
					order: option.order ? option.order : -1
				});
			}
			if (CONFIG::god && false) {
				A.sortOn(['is_subscriber', 'h', 's', 'v'], [Array.NUMERIC, Array.NUMERIC, Array.NUMERIC, Array.NUMERIC]);
			} else {
				A.sortOn(['is_subscriber', 'order'], [Array.NUMERIC, Array.NUMERIC]);
			} 
			
			return A;
		}
		
		override protected function makeButton(type:String, id:String, option:Object):AbstractVanityButton {
			var n:String = type+':'+id;
			var bt:ColorVanityButton = new ColorVanityButton(option.name || option.color);
			bt.name = n;
			bt.selected = false;
			return bt;
		}
		
		override protected function fillButton(type:String, id:String, bt:AbstractVanityButton, arm:AvatarResourceManager, ac:AvatarConfig):void {
			
			bt.color = ColorUtil.colorStrToNum(options[type][id].color);
			/*
			var shape:Shape = new Shape();
			var g:Graphics = shape.graphics;
			g.lineStyle(0, 0, 0);
			g.beginFill(ColorUtil.colorStrToNum(options[type][id].color), 0);
			g.drawRoundRect(0, 0, bt_wh, bt_wh, 6);
			bt.addChild(shape);*/
		}
		
	}
}