package com.tinyspeck.vanity {
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.pc.AvatarConfig;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.loader.AvatarResourceManager;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.TabbedPane;
	import com.tinyspeck.engine.view.ui.TabbedPaneContent;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	public class AbstractVanityTabPane extends Sprite {
		
		private var tpane:TabbedPane;
		private var changeCallBack:Function;
		private var clickSubscriberThingCallBack:Function;
		
		protected var tpane_w:int;
		protected var bt_wh:int;
		protected var bt_mg:int;
		protected var pane_padd:int;
		protected var paging_sp_height:int;
		protected var per_page:int;
		protected var cols:int;
		protected var rows:int;
		protected var types:Object;
		protected var options:Object;
		protected var type_base_hash_suffix:String = '';
		protected var tab_sortA:Array = [];
		protected var sub_buttonsA:Array = [];
		
		public function AbstractVanityTabPane(changeCallBack:Function, clickSubscriberThingCallBack:Function) {
			super();
			this.changeCallBack = changeCallBack;
			this.clickSubscriberThingCallBack = clickSubscriberThingCallBack;
		}
			
		protected function init():void {
			tpane = new TabbedPane(
				tpane_w,
				VanityModel.tab_panel_h,
				0,
				VanityModel.tab_h,
				VanityModel.panel_line_c,
				VanityModel.panel_bg_c,
				1,
				VanityModel.panel_corner_radius
			);
			
			tpane.addEventListener(TSEvent.CHANGED, onTabPaneChanged);
			makeTabbedPaneContent();
			activateTab(tab_sortA[0]);
			addChild(tpane);
		}
		
		public function activateTab(id:String):void {
			tpane.activateTab(id);
		}
		
		private function onTabPaneChanged(e:TSEvent):void {
			dispatchEvent(new TSEvent(TSEvent.CHANGED, e.data));
		}
		
		protected function makeButton(type:String, id:String, option:Object):AbstractVanityButton {
			var bt:AbstractVanityButton;
			return bt;
		}
		
		private function buttonWasClicked(bt:AbstractVanityButton):void {
			if (!bt || bt.name.indexOf(':') == -1) {
				CONFIG::debugging {
					Console.warn('wtf did you click on?');
				}
				return;
			}
			if (sub_buttonsA.indexOf(bt) > -1) {
				clickSubscriberThingCallBack(bt);
				return;
			}
			var A:Array = bt.name.split(':');
			var type:String = A[0];
			var id:String = A[1];
			changeCallBack(type, id);
			highlightCorrectButtons();
		}
		
		private function tabContentClickHandler(e:Event):void {
			if (e.target is AbstractVanityButton) {
				buttonWasClicked(e.target as AbstractVanityButton);
			}
		}
		
		protected function getSortedObjects(options:Object):Array {
			var A:Array = [];
			for (var id:String in options) {
				var option:Object = options[id];
				A.push({
					id:id,
					is_subscriber: option.is_subscriber ? 1 : 0,
					order: option.order ? option.order : -1
				});
			}
			A.sortOn(['is_subscriber', 'order'], [Array.NUMERIC, Array.NUMERIC]);
			
			return A;
		}
		
		private function makeTabbedPaneContent():void {
			
			var arm:AvatarResourceManager = AvatarResourceManager.instance;
			var ac:AvatarConfig = AvatarConfig.fromAnonymous(VanityModel.options_ava_config);
			
			var option:Object;
			var content:TabbedPaneContent;
			var part_mc:MovieClip;
			var id:String
			var page_cnt:int;
			var col:int;
			var row:int;
			var button_sortA:Array;
			var section_i:int;
			var doing_subsciber_options:Boolean;
			
			for (var i:int;i<tab_sortA.length;i++) {
				var type:String = tab_sortA[int(i)];
				if (!types[type]) {
					CONFIG::debugging {
						Console.warn('bad type in tab_sortA:'+type);
					}
					continue;
				}
				content = new TabbedPaneContent();
				var tf:TextField = new TextField();
				TFUtil.prepTF(tf, false);
				tf.embedFonts = false;
				tf.visible = false;
				tf.mouseEnabled = false;
				tf.htmlText = '<p class="subscriber_header">subscriber-only</p>';
				tf.x = Math.round((tpane_w-tf.width)/2);
				content.addChild(tf);
				content.addEventListener(MouseEvent.CLICK, tabContentClickHandler);
				tpane.addTab(type, types[type], content);

				// let's do some sorting
				button_sortA = getSortedObjects(options[type]);
				
				page_cnt = Math.ceil(button_sortA.length/per_page);
				
				var tf_margin:int = 4;
				section_i = 0;
				doing_subsciber_options = false;
				for (var m:int=0;m<button_sortA.length;m++) {
					id = button_sortA[m].id;
					option = options[type][id];
					
					if (button_sortA[m].is_subscriber && !doing_subsciber_options) {
						section_i = 0;
						doing_subsciber_options = true;
						tf.y = (tf_margin)+((bt) ? bt.y+bt_wh : 0);
						tf.visible = true;
					}
					
					col = (section_i % cols);
					row = Math.floor(section_i / cols);
					
					var bt:AbstractVanityButton = makeButton(type, id, option);
					bt.x = pane_padd+(col*(bt_wh+bt_mg));
					
					if (doing_subsciber_options) {
						bt.y = tf.y+tf.height+tf_margin+(row*(bt_wh+bt_mg));
					} else {
						bt.y = pane_padd+row*((bt_wh+bt_mg));
					}
					
					if (VanityModel.base_hash[type+type_base_hash_suffix] == id) {
						//Console.info('"'+id+'" "'+VanityModel.base_hash[type+type_base_hash_suffix]+'"');
						bt.selected = true;
					}
					
					fillButton(type, id, bt, arm, ac);
					
					if (option.is_new) {
						bt.showNew();
					}

					if (option.is_hidden) {
						bt.showHidden();
					}
					
					if (option.is_subscriber && !VanityModel.fvm.player_is_subscriber) {
						//bt.disabled = true;
						sub_buttonsA.push(bt);
					}
					content.getPage(0).addChild(bt);
					
					section_i++;
				}
			}
			
			//Console.dir(VanityModel.base_hash);
		}
		
		protected function fillButton(type:String, id:String, bt:AbstractVanityButton, arm:AvatarResourceManager, ac:AvatarConfig):void {
			// extenders delight
		}
		
		private function highlightCorrectButtons():void {
			var content:TabbedPaneContent;
			var bt:AbstractVanityButton;
			for (var type:String in types) {
				content = tpane.getTabContentById(type);
				for (var i:int=0;i<content.getPage(0).numChildren;i++) {
					bt = content.getPage(0).getChildAt(i) as AbstractVanityButton;
					//Console.info(getQualifiedClassName(bt)+' "'+bt.name+'" "'+type+':'+VanityModel.base_hash[type+type_base_hash_suffix]+'"')
					if (bt.name == type+':'+VanityModel.base_hash[type+type_base_hash_suffix]) {
						bt.selected = true;
					} else {
						bt.selected = false;
					}
				}
			}
			//Console.dir(VanityModel.base_hash);
		}
		
		public function updateFromAvaConfig():void {
			highlightCorrectButtons();
		}
		
		public function onPlayerSubscribed(clicked_bt:Sprite):void {
			while (sub_buttonsA.length) {
				var bt:AbstractVanityButton = sub_buttonsA.pop();
				//bt.disabled = false;
				if (clicked_bt == bt) buttonWasClicked(bt);
			}
		}
	}
}