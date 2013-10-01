package com.tinyspeck.engine.view
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.FurnUpgradeController;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.furniture.FurnUpgrade;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.DecorateModel;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.ChassisManager;
	import com.tinyspeck.engine.port.IFurnUpgradeUI;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.spritesheet.ItemSSManager;
	import com.tinyspeck.engine.spritesheet.SWFData;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.ConfiggerUI;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.TSScrollPager;
	import com.tinyspeck.engine.view.ui.decorate.ChassisUpgradeButton;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;

	public class ChassisPickerUI extends Sprite implements IFurnUpgradeUI {
		private static const SAVE_PADD:uint = 70; //L+R padding for save button
		private static const ICON_WH:uint = 90;
		private static const ICON_PADD:uint = 15;
		private static const PAGER_H:uint = 122;
		private static const PAGER_PADD:uint = 8;
		private static const STYLE_HEADER_H:uint = 17;
		
		public var fuc:FurnUpgradeController;
		public var save_bt:Button;
		
		private var save_bt_credits:DisplayObject;
		private var credits_holder:Sprite = new Sprite();
		private var info_holder:Sprite = new Sprite(); //holds all the stuff on the left side, name, credits, etc.
		private var chooser_holder:Sprite = new Sprite();
		private var owned_styles_holder:Sprite = new Sprite();
		private var more_styles_holder:Sprite = new Sprite();
		private var subscriber_holder:Sprite = new Sprite();
		
		private var dm:DecorateModel;
		private var scroll_pager:TSScrollPager;
		private var buttons:Vector.<ChassisUpgradeButton> = new Vector.<ChassisUpgradeButton>();
		public var tower_name_ui:TowerNameUI;
		
		private var grey_filterA:Array;
		
		private var you_have_tf:TextField = new TextField();
		private var credits_tf:TextField = new TextField();
		private var get_more_tf:TextField = new TextField();
		private var name_tf:TextField = new TextField();
		private var owned_styles_tf:TextField = new TextField();
		private var more_styles_tf:TextField = new TextField();
		private var subscriber_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var is_facing_right:Boolean;
		private var enough_imagination:Boolean;
		private var enough_credits:Boolean;
		private var is_subscriber:Boolean;
		private var is_first_load:Boolean = true;
		private var _showing_name_ui:Boolean;
		
		public function get showing_name_ui():Boolean {
			return _showing_name_ui;
		}
		
		private var picker_start_tim:uint;
		
		private var width_of_config_ui:int;
		
		public function ChassisPickerUI() {}

		public function init(fuc:FurnUpgradeController):void {
			this.fuc = fuc;
			fuc.init(this);
			dm = TSModelLocator.instance.decorateModel;
			fuc.addEventListener(TSEvent.STAT_CHANGE_HAPPENED, onStatsChanged);
			
			width_of_config_ui = ChassisManager.WIDTH_OF_CONFIG_UI;
			
			//style chooser
			chooser_holder.x = 7;
			owned_styles_holder.y = more_styles_holder.y = 5;
			chooser_holder.addChild(owned_styles_holder);
			scroll_pager = new TSScrollPager(PAGER_H);
			scroll_pager.x = width_of_config_ui + PAGER_PADD;
			scroll_pager.y = PAGER_PADD;
			scroll_pager.setContent(chooser_holder);
			addChild(scroll_pager);
			
			//style TFs
			TFUtil.prepTF(owned_styles_tf, false);
			owned_styles_tf.x = 2;
			owned_styles_tf.y = -1;
			owned_styles_tf.htmlText = '<p class="chassis_picker_header">Styles you own</p>';
			owned_styles_tf.filters = StaticFilters.copyFilterArrayFromObject({alpha:.2}, StaticFilters.black1px90Degrees_DropShadowA);
			owned_styles_holder.addChild(owned_styles_tf);
			
			TFUtil.prepTF(more_styles_tf, false);
			more_styles_tf.x = 2;
			more_styles_tf.y = -1;
			more_styles_tf.htmlText = '<p class="chassis_picker_header">Try more styles</p>';
			more_styles_tf.filters = StaticFilters.copyFilterArrayFromObject({alpha:.2}, StaticFilters.black1px90Degrees_DropShadowA);
			more_styles_holder.addChild(more_styles_tf);
			
			//purchase button 
			save_bt = new Button({
				name: 'save',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR,
				w: width_of_config_ui - SAVE_PADD
			});
			save_bt.x = int(width_of_config_ui/2 - save_bt.width/2);
			save_bt.y = 45;
			save_bt.addEventListener(TSEvent.CHANGED, onSaveClick, false, 0, true);
			
			save_bt_credits = new AssetManager.instance.assets.furn_credits_small();
			save_bt_credits.y = int(save_bt.height/2 - save_bt_credits.height/2 + 1);
			save_bt.addChild(save_bt_credits);
			
			//credits
			credits_holder.mouseChildren = false;
			credits_holder.useHandCursor = credits_holder.buttonMode = true;
			credits_holder.addEventListener(MouseEvent.CLICK, TSFrontController.instance.openCreditsPage, false, 0, true);
			credits_holder.y = int(save_bt.y + save_bt.height + 8);
			info_holder.addChild(credits_holder);
			
			TFUtil.prepTF(you_have_tf, false);
			you_have_tf.htmlText = '<p class="furn_upgrade_credits">You have</p>';
			credits_holder.addChild(you_have_tf);
			
			const credits_icon:DisplayObject = new AssetManager.instance.assets.furn_credits_large();
			credits_icon.x = int(you_have_tf.width + 1);
			credits_icon.y = -2;
			credits_holder.addChild(credits_icon);
			
			TFUtil.prepTF(credits_tf, false);
			credits_tf.x = int(credits_icon.x + credits_icon.width - 1);
			credits_holder.addChild(credits_tf);
			
			TFUtil.prepTF(get_more_tf, false);
			get_more_tf.htmlText = '<p class="furn_upgrade_credits_more">Get some more!</p>';
			get_more_tf.y = int(credits_icon.y + credits_icon.height);
			credits_holder.addChild(get_more_tf);
			
			info_holder.addChild(save_bt);
			
			//name and options
			TFUtil.prepTF(name_tf);
			name_tf.width = width_of_config_ui;
			name_tf.y = 7;
			info_holder.addChild(name_tf);
			
			//subscriber
			var subscriber_txt:String = '<p class="chassis_picker"><span class="chassis_picker_options">';
			subscriber_txt += 'You must be a <a href="event:'+TSLinkedTextField.LINK_SUBSCRIBE+'"><b>subscriber</b></a><br>before you can save this style!';
			subscriber_txt += '</span></p>';
			TFUtil.prepTF(subscriber_tf);
			subscriber_tf.htmlText = subscriber_txt;
			subscriber_tf.width = width_of_config_ui;
			subscriber_holder.addChild(subscriber_tf);
			subscriber_holder.y = credits_holder.y;
			info_holder.addChild(subscriber_holder);
			
			//draw
			var g:Graphics = info_holder.graphics;
			g.beginFill(0xdfe6ec);
			g.drawRoundRectComplex(0, 0, width_of_config_ui, PAGER_H + PAGER_PADD - 1, 0, 0, ConfiggerUI.CORNER_RAD, ConfiggerUI.CORNER_RAD);
			info_holder.filters = StaticFilters.copyFilterArrayFromObject({color:0xa2bcb9}, StaticFilters.black_GlowA);
			addChild(info_holder);
			
			//tower name
			tower_name_ui = new TowerNameUI();
			tower_name_ui.x = width_of_config_ui + PAGER_PADD;
			tower_name_ui.y = PAGER_PADD;
			addChild(tower_name_ui);
			
			//filter
			grey_filterA = [ColorUtil.getGreyScaleFilter()];
		}
		
		// IFurnUpgradeUI function, will be called by fuc:FurnUpgradeController
		public function onSave(changed:Boolean):void {
			ChassisManager.instance.onChassisSaved();
		}
		
		public function start():Boolean {
			//make sure our last stuff was canceled
			if (fuc.display_limcv) { // just to be sure
				clean();
			}
			
			if (!fuc.start()) {
				return false;
			}
			
			is_facing_right = dm.upgrade_itemstack.itemstack_state.furn_config.facing_right === true;
			
			//wait a second before loading our options if this is the first time
			picker_start_tim = StageBeacon.setTimeout(setChassisOptions, is_first_load ? 1000 : 0);
			
			//set the name
			setName(dm.chosen_upgrade);
			
			// we're not displaying this right now, but am leaving all code in for now
			//addChild(fuc.display_limcv);
			
			if (fuc.display_limcv.is_loaded) {
				onIconLoad();
			} else {
				fuc.display_limcv.addEventListener(TSEvent.COMPLETE, onIconLoad, false, 0, true);
			}

			TSTweener.removeTweens(this);
			alpha = 0;
			TSTweener.addTween(this, {_autoAlpha:1, time:.5, transition:'linear'});
			
			//reset the content
			scroll_pager.refresh(true);
			scroll_pager.visible = true;
			
			//hide the contents until they are loaded
			chooser_holder.visible = false;
			/*
			//we naming a tower?
			if (dont_show_choices) {
				tower_name_ui.show(this); //add the current tower's name when you have it
			} else {
				tower_name_ui.hide();
			}
			*/
			updateCredits();
			return true;
		}
		
		public function showNameUI(and_focus:Boolean=false):void {
			_showing_name_ui = true;
			tower_name_ui.show(this, and_focus); //add the current tower's name when you have it
			refresh();
		}
		
		public function hideNameUI():void {
			_showing_name_ui = false;
			tower_name_ui.hide();
			refresh();
		}
		
		public function refresh():void {
			//called from ChassisManager
			const lm:LayoutModel = TSModelLocator.instance.layoutModel;
			scroll_pager.width = (lm.pack_is_wide ? lm.overall_w : lm.loc_vp_w) - scroll_pager.x;
			
			if(tower_name_ui.visible) {
				//this is basically to allow the chat area to extend if it needs to
				lm.pack_is_wide = tower_name_ui.x + tower_name_ui.width > lm.loc_vp_w;
				RightSideManager.instance.right_view.refresh();
			}
		}
		
		private function onIconLoad(e:TSEvent=null):void {
			if (!fuc.display_limcv) return;
			fuc.display_limcv.removeEventListener(TSEvent.COMPLETE, onIconLoad);
			// here goes the magic for placing this thing correctly
			
			//if the icon is too big, let's scale it down
			const max_wh:int = 80;
			var liv_scale:Number = 1;
			
			var rect:Rectangle = fuc.display_limcv.getBounds(fuc.display_limcv);
			
			if (rect.width > max_wh || rect.height > max_wh) {
				liv_scale = max_wh / Math.max(rect.width, rect.height);
			}
			
			//set scale and position (making sure it is always facing right in this dialog by reversing scale back)
			fuc.display_limcv.scaleX = liv_scale * (is_facing_right ? 1 : -1);
			fuc.display_limcv.scaleY = liv_scale;
			fuc.display_limcv.x = chooser_holder.x/2;((chooser_holder.x/2)+(rect.width/2))+((-rect.x/2) * liv_scale);
			fuc.display_limcv.y = (-rect.y * liv_scale);
			CONFIG::debugging {
				Console.info(rect)
			}			
		}
		
		// ChassisManager will call this
		public function setSaveButtonToDefault():void {
			save_bt.disabled = true;
			save_bt.label = 'Save changes';
		}

		// ChassisManager will call this too
		public function setButtonToCorrectState():void {
			save_bt_credits.visible = false;
			if (dm.has_chassis_changed) {
				//do disabled status first so we can apply the filter to the icon
				save_bt.disabled = (!dm.chosen_upgrade 
					|| dm.was_upgrade_id == dm.chosen_upgrade.id 
					|| !enough_imagination 
					|| !enough_credits 
					|| (dm.chosen_upgrade.subscriber_only && !is_subscriber))
					&& (dm.chosen_upgrade && !dm.chosen_upgrade.is_owned);
				
				if (dm.chosen_upgrade.credits && !dm.chosen_upgrade.is_owned) {
					save_bt.label = 'Save for     '+StringUtil.formatNumberWithCommas(dm.chosen_upgrade.credits);
					
					//place the icon where it needs to go
					save_bt_credits.visible = true;
					save_bt_credits.x = int(save_bt.label_tf.x + 61); //accounts for the "Save for" and a little padding
					save_bt_credits.filters = save_bt.disabled ? grey_filterA : null;
				} else {
					save_bt.label = 'Save changes';
				}
			} else if (dm.has_config_changed) {
				save_bt.label = 'Save changes';
				save_bt.disabled = false;
			} else if (dm.has_name_changed) {
				save_bt.label = 'Save changes';
				save_bt.disabled = false;
			} else {
				setSaveButtonToDefault();
			}
		}
		
		private function onStatsChanged(e:TSEvent):void {
			updateCredits();
		}
		
		private function updateCredits():void {
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			//update the text
			var you_have_txt:String = 'You have';
			var credits_txt:String = StringUtil.formatNumberWithCommas(pc.stats.credits)+(pc.stats.credits != 1 ? ' credits' : ' credit');
			enough_credits = dm.chosen_upgrade && dm.chosen_upgrade.credits <= pc.stats.credits;
			is_subscriber = dm.chosen_upgrade && dm.chosen_upgrade.subscriber_only ? pc.stats.is_subscriber : true;
			enough_imagination = dm.chosen_upgrade && dm.chosen_upgrade.imagination > 0 ? pc.stats.imagination >= dm.chosen_upgrade.imagination : true;
			
			//check to make sure we have enough credits
			if(dm.chosen_upgrade && !dm.chosen_upgrade.is_owned && !enough_credits){
				you_have_txt = '<span class="furn_upgrade_credits_low">'+you_have_txt+'</span>';
				credits_txt = '<span class="furn_upgrade_credits_low">'+credits_txt+'</span>';
			}

			you_have_tf.htmlText = '<p class="furn_upgrade_credits">'+you_have_txt+'</p>';
			credits_tf.htmlText = '<p class="furn_upgrade_credits">'+credits_txt+'</p>';
			
			get_more_tf.x = int((credits_tf.x + credits_tf.width)/2 - get_more_tf.width/2);
			credits_holder.x = int(width_of_config_ui/2 - credits_holder.width/2);
			
			//if this is a subscriber only thing and we aren't a subscriber, hide the credit stuff and show the subscriber message
			subscriber_holder.visible = dm.chosen_upgrade.subscriber_only && !is_subscriber;
			credits_holder.visible = !subscriber_holder.visible;
			
			setButtonToCorrectState();
		}
		
		public function setChosenUpgrade(upgrade:FurnUpgrade):void {
			fuc.setChosenUpgrade(upgrade);
			
			if (fuc.display_limcv.is_loaded) {
				onIconLoad();
			} else {
				fuc.display_limcv.addEventListener(TSEvent.COMPLETE, onIconLoad, false, 0, true);
			}
			
			if (dm.was_upgrade_id == dm.chosen_upgrade.id) {
				dm.has_chassis_changed = false;
			} else {
				dm.has_chassis_changed = true;
			}
			
			//reset the other buttons
			var i:int;
			var total:int = buttons.length;
			var button:ChassisUpgradeButton;
			
			for(i; i < total; i++){
				button = buttons[int(i)];
				button.is_clicked = button.furn_upgrade == upgrade;
			}
			
			ChassisManager.instance.onChassisChange();
			
			setName(upgrade);
			
			//make sure we have the credits for this purchase
			updateCredits();
		}
		
		private function onUpgradeButtonClick(event:TSEvent):void {
			const cub:ChassisUpgradeButton = event.data as ChassisUpgradeButton;
			const upgrade:FurnUpgrade = cub.furn_upgrade;
			setChosenUpgrade(upgrade);
		}
		
		private function setName(upgrade:FurnUpgrade):void {
			// dm.upgrade_itemstack.swf_url
			const swf_data:SWFData = ItemSSManager.getSWFDataByUrl(dm.upgrade_itemstack.swf_url);
			var excludeA:Array;
			if (swf_data && swf_data.mc && swf_data.mc.hasOwnProperty('user_config_exclusions') && swf_data.mc.user_config_exclusions && swf_data.mc.user_config_exclusions is Array) {
				excludeA = swf_data.mc.user_config_exclusions.concat();
			}
			
			//figure out how many things we can change (TODO make this a strong typed object!!!!)
			var k:String;
			var count:int;
			var name_txt:String = '<p class="chassis_picker">';
			if(upgrade && upgrade.furniture && upgrade.furniture.config){
				for(k in upgrade.furniture.config){
					if (excludeA && excludeA.indexOf(k) > -1) continue;
					count++;
				}
			}
			name_txt += upgrade ? upgrade.label : '';
			name_txt += '<br><span class="chassis_picker_options">';
			name_txt += count + ' customizable '+(count != 1 ? 'sections' : 'section');
			name_txt += '</span>';
			name_txt += '</p>';
			name_tf.htmlText = name_txt;
		}
		
		private function setChassisOptions():void {
			//what do we have that's ours/free and what can we buy?
			const bt_padd:uint = 5;
			var i:int;
			var total:int = dm.upgradesV.length;
			var cub:ChassisUpgradeButton;
			var next_x:int;
			var holder_sp:Sprite = owned_styles_holder;
			var g:Graphics;
			
			resetButtonPool();
			SpriteUtil.clean(owned_styles_holder, true, 1); //so we don't axe the TF
			SpriteUtil.clean(more_styles_holder, true, 1);
			
			//remove the more styles until we need it
			if(more_styles_holder.parent) more_styles_holder.parent.removeChild(more_styles_holder);
			
			for (i = 0; i < total; i++) {				
				if(buttons.length > i){
					cub = buttons[int(i)];
					cub.is_clicked = false;
				}
				else {
					cub = new ChassisUpgradeButton(ICON_WH, ICON_PADD);
					cub.addEventListener(TSEvent.CHANGED, onUpgradeButtonClick, false, 0, true);
					buttons.push(cub);
				}
				
				//have we hit the first house you don't own?
				if(!dm.upgradesV[int(i)].is_owned && more_styles_holder.numChildren == 1){
					next_x = 0;
					holder_sp = more_styles_holder;
					
					//owned styles header bar
					const owned_w:int = i*ICON_WH + (i > 0 ? ((i-1)*bt_padd) : 0);
					g = owned_styles_holder.graphics;
					g.clear();
					if(owned_styles_holder.numChildren){
						g.beginFill(0xaabbc0);
						g.drawRoundRect(0, 0, owned_w, STYLE_HEADER_H, 6);
					}
					
					//draw the divider
					g = chooser_holder.graphics;
					g.clear();
					g.beginFill(0xb0bcbf);
					g.drawRect(owned_styles_holder.x + owned_w + bt_padd, 0, 1, PAGER_H);
					
					//add it to the chooser
					more_styles_holder.x = owned_w + bt_padd*2 + 1; //1 is for the divider
					chooser_holder.addChild(more_styles_holder);
				}
				
				cub.x = next_x;
				cub.y = STYLE_HEADER_H + bt_padd;
				next_x += cub.width + bt_padd;
				
				// if it is the current one!
				if (dm.upgradesV[int(i)].id == dm.upgrade_itemstack.furn_upgrade_id) {
					cub.is_clicked = true;
				}
				
				// just a wee delay to make loading smoother, especially when the furn is large
				StageBeacon.setTimeout(cub.show, 100*(i+1), dm.upgrade_itemstack.class_tsid, dm.upgradesV[int(i)], cub.is_clicked);
				
				// admin only ones will be filtered out in FurnUpgrade.parseMultiple for normals,
				// but for admins make the iiv transparent
				cub.iiv_holder.alpha = (dm.upgradesV[i].is_visible) ? 1 : .3;
				holder_sp.addChild(cub);
			}
			
			//draw in the more styles bar
			g = more_styles_holder.graphics;
			g.clear();
			if(more_styles_holder.numChildren){
				g.beginFill(0xaabbc0);
				g.drawRoundRect(0, 0, more_styles_holder.width, STYLE_HEADER_H, 6);
			}
			
			//show the stuff
			if (_showing_name_ui) {
				chooser_holder.visible = scroll_pager.visible = false;
			} else {
				chooser_holder.visible = scroll_pager.visible = true;
			}
			
			//set the element width
			if(!scroll_pager.element_width && cub){
				scroll_pager.element_width = cub.width + bt_padd;
			}
			
			//refresh the scroller
			scroll_pager.refresh();
			
			//no longer the first load
			is_first_load = false;
		}
		
		private function onSaveClick(event:TSEvent):void {
			if(save_bt.disabled) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			ChassisManager.instance.save();
		}
		
		private function resetButtonPool():void {
			//reset the pool
			var i:int;
			var total:int = buttons.length;
			
			for(i; i < total; i++){
				buttons[int(i)].hide();
			}
		}
		
		private function clean():void {
			if (fuc.display_limcv) {
				fuc.display_limcv.removeEventListener(TSEvent.COMPLETE, onIconLoad);
			}
			fuc.clean();
			resetButtonPool();
		}
		
		public function end():void {
			StageBeacon.clearTimeout(picker_start_tim);
			clean();
			
			TSTweener.removeTweens(this);
			TSTweener.addTween(this, {_autoAlpha:0, time:.5, transition:'linear'});
		}
	}
}