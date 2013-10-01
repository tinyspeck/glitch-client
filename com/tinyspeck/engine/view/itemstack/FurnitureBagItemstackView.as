package com.tinyspeck.engine.view.itemstack {
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.itemstack.FurnitureConfig;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.spritesheet.SSAbstractSheet;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;

	
	public class FurnitureBagItemstackView extends AbstractItemstackView implements ITipProvider {
		
		private var count_represented:int;
		
		private var wh:int;
		private var padd:int = 10;
		
		private var spinner:DisplayObject;
		private var count_tf:TextField = new TextField();
		private var ups_count_holder:Sprite;
		private var soulbound_icon:Sprite;
		
		public function FurnitureBagItemstackView(tsid:String, wh:int):void {
			super(tsid);
			this.wh = wh;
			_animateXY_duration = .35;
			_construct();
			buttonMode = true;
			useHandCursor = true;
		}
		
		override protected function _construct():void {
			animate(false);
			
			// we're not set up for this here. (no resizing is done after a new sceene is set, at the least, probably other problems woudl need to be workd though too)
			//use_mc = CSSManager.instance.getBooleanValueFromStyle('use_mc', itemstack.class_tsid);
			
			graphics.beginFill(0xffffff, 1);
			graphics.drawRoundRect(0, 0, wh, wh, 8);
			
			spinner = new AssetManager.instance.assets.spinner();
			spinner.x = int(wh/2 - spinner.width/2);
			spinner.y = int(wh/2 - spinner.height/2);
			addChild(spinner);
			
			super._construct();
			
			var fm:TextFormat = new TextFormat();
			fm.color = 0x676767;
			fm.size = 10;
			fm.font = 'Arial';
			fm.bold = true;
			
			count_tf = makeTF(fm);
			count_tf.width = 0;
			addChild(count_tf);
			count_tf.visible = false;
			
			ups_count_holder = new Sprite();
			addChild(ups_count_holder);
			
			if (_itemstack.is_soulbound_to_me) {
				var soulbound_icon_w:int = 9;
				soulbound_icon = new Sprite();
				addChild(soulbound_icon);
				var g:Graphics = soulbound_icon.graphics;
				g.beginFill(0xffffff);
				g.drawCircle(soulbound_icon_w/2, soulbound_icon_w/2, soulbound_icon_w/2);
				g.endFill();
				g.beginFill(0xd9acab);
				g.drawCircle((soulbound_icon_w-2)/2, (soulbound_icon_w-2)/2, (soulbound_icon_w-2)/2);
				g.endFill();

				soulbound_icon.visible = true;
				
				soulbound_icon.x = 2;
				soulbound_icon.y = 2;
			}
			
			//changeHandler();
		}
		
		private function makeTF(fm:TextFormat):TextField {
			var tf:TextField = new TextField();
			
			tf.defaultTextFormat = fm;
			tf.selectable = false;
			tf.antiAliasType = flash.text.AntiAliasType.ADVANCED;
			tf.thickness = -200;
			tf.sharpness = 400;
			tf.filters = StaticFilters.disconnectScreen_GlowA;
			tf.multiline = false;
			tf.wordWrap = false;
			
			return tf;
		}
		
		override protected function animate(force:Boolean = false, at_wh:int = 0):void {
			
			// ALWAYS, NO MATTER WHAT IS PASSED, USE THIS:
			at_wh = wh-padd;
			
			var furn_config:FurnitureConfig = _itemstack.itemstack_state.furn_config;
			if (furn_config) {
				if (furn_config.facing_right) {
					_faceRight();
				} else {
					_faceLeft();
				}
			}
			
			doSpecialConfigStuff();
			
			super.animate(force, at_wh);
		}
		
		override protected function setupSpecialFrontContainer():void {
			super.setupSpecialFrontContainer();
			positionSpecialBackContainer();
		}
		
		private function positionSpecialFrontContainer():void {
			if (!special_front_holder) return;
			special_front_holder.x = (wh/2);
			special_front_holder.y = wh;
		}
		
		override protected function setupSpecialBackContainer():void {
			super.setupSpecialBackContainer();
			positionSpecialBackContainer();
		}
		
		private function positionSpecialBackContainer():void {
			if (!special_back_holder) return;
			special_back_holder.x = (wh/2);
			special_back_holder.y = wh;
			var view_do:DisplayObject;
			if (ss_view) {
				view_do = ss_view as DisplayObject;
				//special_back_holder.y-= ((wh-padd)-view_do.height)/2
				//Console.info(special_back_holder.y +' '+ view_do.y)
				//special_back_holder.y = view_do.y+view_do.height;
			}
		}
		
		override protected function onLoad(ss:SSAbstractSheet, url:String):void {
			super.onLoad(ss, url);
			if (url != used_swf_url) return;
			if(spinner && spinner.parent){
				spinner.parent.removeChild(spinner);
				spinner = null;
			}
		}
		
		public function setDisplayCount(c:int):void {
			if (count_represented == c) return;
			count_represented = c;
			
			if (count_represented<2) {
				count_tf.visible = false;
				return;
			}

			count_tf.visible = true;
			count_tf.text = String(count_represented);
			count_tf.width = count_tf.textWidth+4;
			count_tf.height = count_tf.textHeight+4;
			
			count_tf.x = wh-count_tf.width-2;
			count_tf.y = wh-count_tf.height;
		}
		
		private var upgrades_count_displayed:int;
		public function updateUpgradeCount():void {
			var furn_config:FurnitureConfig = _itemstack.itemstack_state.furn_config;
			if (furn_config && furn_config.upgrade_ids && furn_config.upgrade_ids.length) {
				if (upgrades_count_displayed != furn_config.upgrade_ids.length) {
					SpriteUtil.clean(ups_count_holder);
					
					var ups_count:int = furn_config.upgrade_ids.length;
					var arrow:DisplayObject;
					var next_x:int;
					for (var i:int=0;i<furn_config.upgrade_ids.length;i++) {
						arrow = new AssetManager.instance.assets['upgrade_arrow']();
						ups_count_holder.addChild(arrow);
						arrow.x = next_x;
						next_x+= arrow.width-1;
					}
				}
				
				ups_count_holder.visible = true;
				ups_count_holder.x = wh-(ups_count_holder.width+2);
				ups_count_holder.y = wh-(ups_count_holder.height+2);
			} else {
				ups_count_holder.visible = false;
			}
		}
		
		private function _faceRight():void {
			view_holder.scaleX = 1;
			view_holder.x = 0;
		}
		
		private function _faceLeft():void {
			view_holder.scaleX = -1;
			view_holder.x = wh;
		}
		
		public function get slot():int {
			return _itemstack.slot;
		}
		
		override protected function _addedToStageHandler(e:Event):void {
			super._addedToStageHandler(e);
			
			TipDisplayManager.instance.registerTipTrigger(this);
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			var tsid_str:String = '';
			CONFIG::god {
				tsid_str = '<p class="pack_itemstack_desc_tip">'+tsid+' '+_itemstack.furn_stacking_sig+'</p>';
			}
			
			
			if (_itemstack.tooltip_label) {
				return {
					txt: '<p class="pack_itemstack_name_tip">'+_itemstack.tooltip_label+'</p>'+tsid_str,
					offset_y: -7,
					pointer: WindowBorder.POINTER_BOTTOM_CENTER
				}
			}
			
			var souldbound_tip:String = '';
			if (_itemstack.is_soulbound_to_me) {
				souldbound_tip = '<p class="pack_itemstack_desc_tip">Cannot be sold, traded, or given away.</p>';
			}
			var upgrades_tip:String = '';
			var furn_config:FurnitureConfig = _itemstack.itemstack_state.furn_config;
			if (furn_config && furn_config.upgrade_ids) {
				var has:String = (count_represented > 1) ? 'Each has ' : 'Has ';
				upgrades_tip = '<p class="pack_itemstack_desc_tip">'+has+
					(furn_config.upgrade_ids.length)+' '+
					((furn_config.upgrade_ids.length == 1) ? 'upgrade' : 'upgrades')+
				'.</p>';
			}
			return {
				txt: '<p class="pack_itemstack_name_tip">'+
					  		((count_represented>1) ? count_represented+'&nbsp;'+_item.label_plural : _itemstack.getLabel())+
					  '</p>'+
					  souldbound_tip+
					  upgrades_tip+
					  tsid_str,
				offset_y: -7,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
		
		/*override protected function onLoadDone():void {
			if (disposed) return;
			// arguably this is not as fault tolerant as it shoudl be.
			// it is meant to be called when loading is done for theis view,
			// but I;m worried if loading fails that this will not be called at all
			PackDisplayManager.instance.onPISViewLoaded();
		}*/
		
		override protected function _positionViewDO():void {
			/*
			if (reloaded_once) {
				CONFIG::debugging {
					Console.error('_positionViewDO');
				}	
			}
			*/
			var view_do:DisplayObject;
			if (use_mc) {
				view_do = _mc as DisplayObject;
			} else {
				view_do = ss_view as DisplayObject;
			}

			var scale_it:Boolean = true;
			
			if (!view_do) {
				if (!placeholder.parent) view_holder.addChild(placeholder);
				view_do = placeholder;
				scale_it = false;
			} else if (placeholder.parent) {
				placeholder.parent.removeChild(placeholder);
			}
			
			// hmmm, of course we should do this, right? else view_do.width below will reflect any previous scale applied, and measurement will be off
			view_do.scaleX = view_do.scaleY = 1;

			if (scale_it) {
				if (view_do.width > view_do.height) {
					view_do.scaleX = view_do.scaleY = (wh-padd)/view_do.width;
				} else {
					view_do.scaleX = view_do.scaleY = (wh-padd)/view_do.height;
				}
			}
			
			var rect:Rectangle = view_do.getBounds(view_holder);
			view_do.x = Math.round(-rect.x+(wh-view_do.width)/2);
			view_do.y = Math.round(-rect.y+(wh-view_do.height)/2);
			
			view_do.visible = true;
			positionSpecialFrontContainer();
			positionSpecialBackContainer();
		}
		
		override protected function _draw():void {
			var h:int = wh;
			var w:int = wh;
			graphics.clear();
			graphics.beginFill(0xCC0000, 0);
			graphics.drawRect(0, 0, w, h);
			graphics.beginFill(0xffff33);
			graphics.drawCircle(w/2, h/2, w/2);
			
			if (_item.tsid == 'apple') {
				graphics.beginFill(0xCC0000);
				graphics.drawCircle(w/2, h/2, (w/2)-2);
			} else if (_item.tsid == 'orange') {
				graphics.beginFill(0xFF6633);
				graphics.drawCircle(w/2, h/2, (w/2)-2);
			} else if (_item.tsid == 'coin') {
				graphics.beginFill(0xCC9933);
				graphics.drawCircle(w/2, h/2, (w/2)-2);
			}
			
		}
		
		public function changeHandler():void {
			updateUpgradeCount();
			
			if (reloadIfNeeded()) {
				return;
			}
			
			// this may cause troubles; watch for itemstacks that move from the location to the pack that have a state already set.
			// we may have to null out itemstack.s when moving it to the pack if this causes problems.
			animate(false); // this does
		}
		
	}
}