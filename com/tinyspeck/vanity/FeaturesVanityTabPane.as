package com.tinyspeck.vanity {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.pc.AvatarConfig;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.loader.AvatarResourceManager;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.MCUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.loadedswfs.AvatarSwf;
	import com.tinyspeck.engine.view.ui.Checkbox;
	
	import flash.display.BlendMode;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.TextEvent;
	import flash.text.TextField;
	
	public class FeaturesVanityTabPane extends AbstractVanityTabPane {
		
		private var colored_parts:Object = {
			hair: [],
			ears: []
		};
		
		private var hat_sp:Sprite = new Sprite();
		private var hat_hide_cb:Checkbox;
		private var hat_remove_tf:TextField = new TextField();
		public var hatHideCallBack:Function;
		public var hatRemoveCallBack:Function;
		
		public function FeaturesVanityTabPane(changeCallBack:Function, clickSubscriberThingCallBack:Function) {
			super(changeCallBack, clickSubscriberThingCallBack);
			
			tpane_w = VanityModel.features_tab_panel_w;
			types = VanityModel.features_name_map;
			options = VanityModel.feature_options;
			
			bt_wh = VanityModel.features_bt_wh;
			bt_mg = VanityModel.features_bt_mg;
			pane_padd = VanityModel.features_pane_padd;
			paging_sp_height = VanityModel.features_paging_sp_height;
			
			per_page = VanityModel.features_pane_per_page;
			cols = VanityModel.features_pane_cols;
			rows = VanityModel.features_pane_rows;
			
			tab_sortA = VanityModel.feature_tabs_sortA;
			
			init();
		}
		
		override protected function makeButton(type:String, id:String, option:Object):AbstractVanityButton {
			var n:String = type+':'+id;
			var bt:FeatureVanityButton = new FeatureVanityButton(option.article_class_name);
			bt.name = n;
			bt.selected = false;
			return bt;
		}
		
		override protected function init():void {
			super.init();
			
			hat_sp.visible = false;
			hat_sp.alpha = 0;
			hat_sp.graphics.lineStyle(0, 0, 0);
			hat_sp.graphics.beginFill(0, 0);
			hat_sp.graphics.drawRect(0, 0, 200, 40);
			
			hat_sp.y = VanityModel.tab_panel_h-40;
			addChild(hat_sp);
			
			hat_hide_cb = new Checkbox({
				graphic: AssetManager.instance.getLoadedBitmap(VanityModel.imgs_to_loadH['vanity_cb_unchecked.png']),
				graphic_checked: AssetManager.instance.getLoadedBitmap(VanityModel.imgs_to_loadH['vanity_cb_checked.png']),
				x: 10,
				y: 12,
				w:18,
				h:18,
				checked: true,
				label: 'Hide hat for now',
				name: 'hat_hide_cb'
			})
			hat_sp.addChild(hat_hide_cb);
				
			hat_hide_cb.addEventListener(TSEvent.CHANGED, function():void {
				if (hatHideCallBack != null) hatHideCallBack(hat_hide_cb.checked)
			});
			
			TFUtil.prepTF(hat_remove_tf, false);
			
			hat_remove_tf.x = hat_hide_cb.x+hat_hide_cb.width+6;
			hat_remove_tf.y = hat_hide_cb.y;
			hat_remove_tf.embedFonts = false;
			hat_remove_tf.htmlText = '<a href="event:remove_hat" class="vanity_remove_hat">Remove hat</a>';
			hat_remove_tf.addEventListener(TextEvent.LINK, onTextLinkClick, false, 0, true);
			hat_sp.addChild(hat_remove_tf);
		}
		
		private function onTextLinkClick(event:TextEvent):void {
			if (event.text == 'remove_hat') {
				if (hatRemoveCallBack != null) hatRemoveCallBack();
			}
		}
		
		public function unCheckHatCb():void {
			hat_hide_cb.checked = false;
		}
		
		public function hideHatControls():void {
			TSTweener.addTween(hat_sp, {_autoAlpha:0, time:2});
		}
		
		public function showHatControls():void {
			hat_hide_cb.checked = true;
			hat_sp.visible = true;
			if (hat_sp.alpha != 1) {
				TSTweener.addTween(hat_sp, {alpha:1, time:2});
			}
		}
		
		public function updateColoredParts(type:String):void {
			if (type == 'skin') type = 'ears'; // because the type is the type of color that was set, which will be hair or skin 
			if (!colored_parts[type]) return;
			var color_part_mc:MovieClip;
			var actual_ac:AvatarConfig = AvatarConfig.fromAnonymous(VanityModel.ava_config); // this is the config the user currently has (the ac passed is the faked one for the options);
			var c:int = (type == 'hair') ? VanityModel.sample_hair_c : actual_ac.skin_tint_color;
			
			for (var i:int;i<colored_parts[type].length;i++) {
				color_part_mc = colored_parts[type][int(i)];
				color_part_mc.transform.colorTransform = ColorUtil.getColorTransform(c);
			}
		}
		
		override protected function fillButton(type:String, id:String, bt:AbstractVanityButton, arm:AvatarResourceManager, ac:AvatarConfig):void {
			var class_name:String = VanityModel.features_class_map[type];
			var part_mc:MovieClip = arm.getArticlePartMC(ac.getArticleByType(type+id), class_name);
			var color_part_mc:MovieClip;
			var sp:Sprite;
			var actual_ac:AvatarConfig; // this is the config the user currently has (the ac passed is the faked one for the options);
			var c:int;
			var blend:String;
			
			if (id == '0') {
				var none_tf:TextField = new TextField();
				TFUtil.prepTF(none_tf, false);
				none_tf.embedFonts = false;
				none_tf.htmlText = '<p class="button_none">none</p>';
				bt.addDO(none_tf, false, false);
			} else {
				
				// some hairs do not use SIDEHAIR, so try SIDEHAIRCLOSE
				if (!part_mc) {
					if (type == 'hair') {
						class_name = AvatarSwf.SIDEHAIRCLOSE;
						part_mc = arm.getArticlePartMC(ac.getArticleByType(type+id), class_name);
					}
				}
				
				if (part_mc) {
					//part_mc.stop();
					MCUtil.recursiveStop(part_mc);
					sp = new Sprite();
					sp.addChild(part_mc);
					if (type == 'hair' || type == 'ears') {
						actual_ac = AvatarConfig.fromAnonymous(VanityModel.ava_config);
						c = (type == 'hair') ? VanityModel.sample_hair_c : actual_ac.skin_tint_color;
						blend = (type == 'hair') ? BlendMode.OVERLAY : BlendMode.HARDLIGHT;
						
						color_part_mc = arm.getArticlePartMC(ac.getArticleByType(type+id), class_name);
						
						//color_part_mc.stop();
						MCUtil.recursiveStop(color_part_mc);
						color_part_mc.blendMode = blend;
						color_part_mc.transform.colorTransform = ColorUtil.getColorTransform(c);
						sp.addChild(color_part_mc);
						
						colored_parts[type].push(color_part_mc);
					}
					
					// handling hair differently because they vary in size by a lot, and there are masks on some of them that throw off measuring like a mofo
					if (type == 'hair') {
						sp.scaleX = sp.scaleY = .40;
						sp.x = Math.round(bt_wh/2);
						if (class_name == AvatarSwf.SIDEHAIRCLOSE) {
							// this needs to be positioned lower, because of different reg point, I think
							sp.y = Math.round(bt_wh/2)+7;
						} else {
							sp.y = Math.round(bt_wh/2)+1;
						}
						bt.addDO(sp, false, true, false);
					} else {
						bt.addDO(sp);
					}
					
					//Console.warn(sp.scaleX+' '+type+' '+id)
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn(type+id+' failed');
					}
				}
			}
		}
		
	}
}