package com.tinyspeck.engine.port
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.FurnUpgradeController;
	import com.tinyspeck.engine.control.HandOfDecorator;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.furniture.FurnUpgrade;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.DecorateModel;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.DrawUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.furniture.FurnUpgradeChooserUI;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	public class FurnUpgradeDialog extends BigDialog implements IFurnUpgradeUI {
		/* singleton boilerplate */
		public static const instance:FurnUpgradeDialog = new FurnUpgradeDialog();
		
		private static const PREVIEW_WH:uint = 250;
		private static const PREVIEW_PADD:uint = 10;
		private static const PREVIEW_BOTTOM:uint = 55;
		private static const ICON_WH:uint = 120;
		private static const ICON_PADD:uint = 20;
		
		private var lightbulb_off:DisplayObject = new AssetManager.instance.assets.lightbulb_off();
		private var lightbulb_on:DisplayObject = new AssetManager.instance.assets.lightbulb_on();
		
		private var lightbox_back:Shape = new Shape();
		private var in_loc_ui_holder:Sprite = new Sprite();
		private var light_switch:Sprite = new Sprite();
		private var left_holder:Sprite = new Sprite();
		private var preview_holder:Sprite = new Sprite();
		private var credits_holder:Sprite = new Sprite();
		private var liv_holder:Sprite = new Sprite();
		private var zoom_holder:Sprite = new Sprite();
		
		private var light_switch_tf:TextField = new TextField();
		private var preview_tf:TextField = new TextField();
		private var you_have_tf:TextField = new TextField();
		private var credits_tf:TextField = new TextField();
		private var get_more_tf:TextField = new TextField();
		private var zoom_tf:TextField = new TextField();
		
		private var chooser_ui:FurnUpgradeChooserUI = new FurnUpgradeChooserUI();
		private var save_bt:Button;
		
		private var current_scroll_y:int;
		
		private var is_built:Boolean;
		private var is_zoomed:Boolean;
		private var is_facing_right:Boolean;
		private var fuc:FurnUpgradeController;
		private var dm:DecorateModel;
		
		private var lights_on:Boolean;
		private var _loc_mode:Boolean;
		public function get loc_mode():Boolean {return _loc_mode}
		private var was_y_cam_offset:int;
		private var was_scale:Number;
		private var itemstack_pt:Point = new Point(0,0);
		private var fuc_rect:Rectangle;
		
		public function FurnUpgradeDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			dm = model.decorateModel;
			_close_bt_padd_top = 12;
			_base_padd = 20;
			_head_min_h = 53;
			_body_min_h = 404;
			_draggable = true;
			_construct();
			_scroller.scrolltrack_always = true;
		}
		
		
		private var credits_offset_y:int = 8;
		private function buildBase():void {
			//preview stuff
			var g:Graphics = preview_holder.graphics;
			g.beginFill(0xffffff);
			g.drawRoundRect(0, 0, PREVIEW_WH, PREVIEW_WH, 10);
			preview_holder.x = _base_padd;
			preview_holder.y = 9;
			preview_holder.filters = StaticFilters.black2px90Degrees_FurnDropShadowA;
			
			TFUtil.prepTF(preview_tf);
			preview_tf.x = preview_holder.x + PREVIEW_PADD;
			preview_tf.y = preview_holder.y + PREVIEW_PADD - 2;
			preview_tf.filters = StaticFilters.white3px_GlowA;
			
			//zoom stuff
			const mag_glass:DisplayObject = new AssetManager.instance.assets.furn_zoom();
			zoom_holder.addChild(mag_glass);
			
			TFUtil.prepTF(zoom_tf, false);
			zoom_tf.x = int(mag_glass.width);
			zoom_tf.filters = StaticFilters.white3px_GlowA;
			zoom_holder.addChild(zoom_tf);
			
			zoom_holder.mouseChildren = false;
			zoom_holder.useHandCursor = zoom_holder.buttonMode = true;
			zoom_holder.addEventListener(MouseEvent.CLICK, onZoomClick, false, 0, true);
			
			//the chooser
			chooser_ui.y = preview_holder.y;
			chooser_ui.addEventListener(TSEvent.CHANGED, onUpgradeButtonClick, false, 0, true);
			
			//purchase button 
			save_bt = new Button({
				name: 'save',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR,
				w: 212
			});
			save_bt.addEventListener(TSEvent.CHANGED, onSaveClick, false, 0, true);
			
			//credits stuff
			credits_holder.mouseChildren = false;
			credits_holder.useHandCursor = credits_holder.buttonMode = true;
			credits_holder.addEventListener(MouseEvent.CLICK, TSFrontController.instance.openCreditsPage, false, 0, true);
			left_holder.addChild(credits_holder);
			
			TFUtil.prepTF(you_have_tf, false);
			you_have_tf.htmlText = '<p class="furn_upgrade_credits">You have</p>';
			you_have_tf.y = credits_offset_y;
			credits_holder.addChild(you_have_tf);
			
			const credits_icon:DisplayObject = new AssetManager.instance.assets.furn_credits_large();
			credits_icon.x = int(you_have_tf.width + 1);
			credits_icon.y = -2+credits_offset_y;
			credits_holder.addChild(credits_icon);
			
			TFUtil.prepTF(credits_tf, false);
			credits_tf.x = int(credits_icon.x + credits_icon.width - 1);
			credits_tf.y = credits_offset_y;
			credits_holder.addChild(credits_tf);
			
			TFUtil.prepTF(get_more_tf, false);
			get_more_tf.htmlText = '<p class="furn_upgrade_credits_more">Get some more!</p>';
			get_more_tf.y = int(credits_icon.y + credits_icon.height);
			credits_holder.addChild(get_more_tf);
			
			//set the title
			_setTitle('Choose a new style');
			
			//place the preview stuff last
			liv_holder.mouseEnabled = liv_holder.mouseChildren = false; //disables the liv's tooltip
			left_holder.addChild(preview_holder);
			left_holder.addChild(liv_holder);
			left_holder.addChild(preview_tf);
			left_holder.addChild(zoom_holder);
			
			const switch_w:uint = 117;
			const switch_h:uint = 26;
			TFUtil.prepTF(light_switch_tf);
			light_switch_tf.mouseEnabled = false;
			light_switch_tf.filters = StaticFilters.black1px90Degrees_DropShadowA;
			light_switch_tf.htmlText = '<p class="furn_upgrade_light_switch">Hit the lights</p>';
			light_switch_tf.x = int(switch_w/2 - light_switch_tf.width/2 + 7);
			light_switch_tf.y = int(switch_h/2 - light_switch_tf.height/2 + 2);

			light_switch.useHandCursor = light_switch.buttonMode = true;
			light_switch.addEventListener(MouseEvent.CLICK, toggleLights, false, 0, true);
			lightbulb_off.x = lightbulb_on.x = 4;
			lightbulb_off.y = lightbulb_on.y = 2;
			light_switch.addChild(lightbulb_off);
			light_switch.addChild(lightbulb_on);
			light_switch.addChild(light_switch_tf);
			light_switch.x = -int(light_switch.width/2)
			light_switch.y = save_bt.h+8;
			light_switch.graphics.beginFill(0, .4);
			light_switch.graphics.drawRoundRect(0, 0, switch_w, switch_h, 8);
			in_loc_ui_holder.addChild(light_switch);
			
			is_built = true;
		}
		
		private function toggleLights(e:MouseEvent=null):void {
			lights_on = !lights_on;
			
			TSTweener.removeTweens(lightbox_back);
			
			if (lights_on) {
				lightbulb_off.visible = true;
				lightbulb_on.visible = false;
				TSTweener.addTween(lightbox_back, {alpha:0, time:.6});
			} else {
				lightbulb_off.visible = false;
				lightbulb_on.visible = true;
				TSTweener.addTween(lightbox_back, {alpha:.75, time:.6});
			}
		}
		
		private function tryToSave():void {
			if(save_bt.disabled) return;
			save_bt.disabled = true;
			fuc.save();
		}
		
		private function onSaveClick(event:TSEvent):void {
			tryToSave();
		}
		
		override protected function enterKeyHandler(e:KeyboardEvent):void {
			tryToSave();
		}
		
		public function onSave(changed:Boolean):void {
			if (changed) {
				HandOfDecorator.instance.onHomeDecoChangeMsgSuccess();
			}
			
			// we must do this here! else the end will call fuc.cancel and visially undo the save!
			dm.upgrade_itemstack = null;
			
			end(true);
		}
		
		override public function end(release:Boolean):void {
			//if we are still saving, don't allow the dialog to be closed, becuase after that
			//shit hits the fan if they are trying to work with that furniture again
			if(fuc.is_saving){
				SoundMaster.instance.playSound('CLICK_FAILURE');
				model.activityModel.activity_message = Activity.createFromCurrentPlayer('We\'re still saving your changes, hang on a sec!');
				model.activityModel.growl_message = 'We\'re still saving your changes, hang on a sec!';
				return;
			}
			
			// we must do it in case this dialog is closed via code, and not closeFromUserInput
			fuc.cancel();
			
			clean();
			TSFrontController.instance.furnitureUpgradeEnded();
			dm.upgrade_itemstack = null;
			super.end(release);
			
			if (lightbox_back.parent) lightbox_back.parent.removeChild(lightbox_back);
			
			if (_loc_mode) {
				
				if (in_loc_ui_holder.parent) in_loc_ui_holder.parent.removeChild(in_loc_ui_holder);
				
				TSFrontController.instance.setViewportScale(was_scale, .5, false, true);
				if (model.stateModel.decorator_mode) {
					// I think we can just leave the camera centered on the upgraded stack
				} else {
					model.worldModel.pc.apo.setting.y_cam_offset = was_y_cam_offset;
					TSFrontController.instance.resetCameraCenter();
				}
			}
			
			_loc_mode = false;
		}
		
		override protected function closeFromUserInput(e:Event=null):void {
			if (_close_bt.disabled) return;
			
			if (!save_bt.disabled && !_loc_mode) {
				//confirm dialog
				var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
				cdVO.title = 'Save Your Changes?';
				cdVO.txt = "You\'re cancelling, but I am thinking maybe you meant to save your changes first?";
				var costs_txt:String = '';
				if (dm.chosen_upgrade.credits) {
					costs_txt = ' (costs '+dm.chosen_upgrade.credits+' '+(dm.chosen_upgrade.credits != 1 ? 'credits' : 'credit')+')';
				}
				cdVO.choices = [
					{value: true, label: 'Yes, Save!'+costs_txt},
					{value: false, label: 'No, Discard'}
				];
				cdVO.escape_value = false;
				cdVO.callback =	function(value:*):void {
					if (value === true && !save_bt.disabled) {
						fuc.save();
					} else {
						closeAfterSaveConfirmation();
					}
				};
				TSFrontController.instance.confirm(cdVO);
				return;
			}
			
			fuc.cancel();
			super.closeFromUserInput(e);
		}
		
		private function closeAfterSaveConfirmation():void {
			if (_close_bt.disabled) return;
			fuc.cancel();
			super.closeFromUserInput();
		}
		
		override public function start():void {
			if (!fuc) {
				fuc = new FurnUpgradeController();
				fuc.init(this);
			}
			
			//make sure our last stuff was canceled
			if(parent){
				fuc.cancel();
				end(true);
			}
			else if (fuc.display_limcv) { // just to be sure
				clean();
			}
			
			if(!canStart(true)) return;
			if (!dm.upgrade_itemstack || !dm.upgradesV) return;
			
			_loc_mode = model.flashVarModel.new_furn_up && (dm.upgrade_itemstack.tsid in model.worldModel.location.itemstack_tsid_list);

			
			if (!fuc.start(_loc_mode?'1':'iconic')) {
				return;
			}
			
			
			fuc.addEventListener(TSEvent.STAT_CHANGE_HAPPENED, onStatsChanged);
			
			if(!is_built) buildBase();
			
			liv_holder.addChild(fuc.display_limcv);
			is_facing_right = dm.upgrade_itemstack.itemstack_state.furn_config.facing_right === true;
			
			//reset the zoom
			is_zoomed = false;
			current_scroll_y = 0;
			preview_holder.width = PREVIEW_WH;
			preview_holder.height = PREVIEW_WH;
			updateZoomText();
			
			if (fuc.display_limcv.is_loaded) {
				onIconLoad();
			} else {
				fuc.display_limcv.loadCompleted_sig.add(onIconLoad);
			}
			
			//load the chooser
			chooser_ui.start(2, ICON_WH, ICON_PADD);
			
			// hide credits info if there are none that cost credits, as is the case when a player is in newxp
			credits_holder.visible = chooser_ui.require_credits_count > 1;
			
			_scroller.body.addChild(chooser_ui);
			_scroller.refreshAfterBodySizeChange(true);
			
			//reset the button
			setButtonToDefault();
			
			updateCredits();
			
			super.start();
			
			was_scale = model.layoutModel.loc_vp_scale;
			was_y_cam_offset = model.worldModel.pc.apo.setting.y_cam_offset;
			centerUpgradeStackInWindow();
		}
		
		private function centerUpgradeStackInWindow():void {
			if (!_loc_mode) return;
			
			TSFrontController.instance.setViewportScale(1, .5, false, true);
			
			// we want the center of the stack in loaction to be in center of viewport, but the bottom not to extend
			// below the bottom-100 of the viewport, to leave room for the button ui
			var y_offset:int = Math.min((dm.upgrade_itemstack.client::physHeight/2), (model.layoutModel.loc_vp_h/2)-100);
			
			if (dm.HANGING_ITEM_TSIDS.indexOf(dm.upgrade_itemstack.class_tsid) == -1) {
				y_offset*= -1;
			}
			
			var new_x:int = dm.upgrade_itemstack.x;
			var new_y:int = dm.upgrade_itemstack.y+y_offset;
			
			if (model.stateModel.decorator_mode) {
				model.stateModel.camera_control_pt.x = new_x;
				model.stateModel.camera_control_pt.y = new_y;
			} else {
				model.worldModel.pc.apo.setting.y_cam_offset = 0;
				itemstack_pt.x = new_x;
				itemstack_pt.y = new_y;
				TSFrontController.instance.setCameraCenter(null, null, itemstack_pt, 0, true);
			}
		}
		
		override protected function _place():void {
			if (!model.flashVarModel.new_furn_up) {
				super._place();
				return;
			}
			
			// center this vertically in the viewport
			dest_y = Math.round((model.layoutModel.loc_vp_h-_h)/2) + model.layoutModel.header_h;
			
			if (_loc_mode) {
				// place this just to the right of the item
				var offset:int = Math.min((model.layoutModel.loc_vp_w/2), (model.worldModel.location.r-dm.upgrade_itemstack.x));
				// this gets us as far to the left as we need to be (no more than halway acrooss the vp)
				dest_x = model.layoutModel.gutter_w + model.layoutModel.loc_vp_w - offset;
				// this moves it over to the right to allows space for the stack and button
				dest_x += Math.max((dm.upgrade_itemstack.client::physWidth/2) + 50, (save_bt.w/2)+20);
			} else {
				// center this horizontally in the viewport
				dest_x = Math.round((model.layoutModel.loc_vp_w-_w)/2) + model.layoutModel.gutter_w;
				dest_x = Math.max(dest_x, 0);
				dest_y = Math.max(dest_y, 0);
			}
			
			if (!transitioning) {
				x = dest_x;
				y = dest_y;
			}
		}
		
		private function setButtonToDefault():void {
			save_bt.disabled = true;
			save_bt.label = 'Choose a style from the right';
		}
		
		private function onIconLoad(lis:LocationItemstackView=null):void {
			if (!fuc.display_limcv) return;
			fuc.display_limcv.loadCompleted_sig.remove(onIconLoad);
			// here goes the magic for placing this thing correctly
			
			// only do this but if we're not in _loc_mode, where we display the display_limcv in the SCH
			if (!_loc_mode) {
				
				fuc_rect = fuc.display_limcv.getBounds(fuc.display_limcv);
				CONFIG::debugging {
					Console.info(fuc_rect);
				}			
				
				//if the icon is too big, let's scale it down
				const max_wh:int = PREVIEW_WH - PREVIEW_PADD*2;
				var liv_scale:Number = 1;
				
				if(fuc_rect.width > max_wh || fuc_rect.height > max_wh){
					liv_scale = max_wh / Math.max(fuc_rect.width, fuc_rect.height);
				}
				
				//set scale and position (making sure it is always facing right in this dialog by reversing scale back)
				fuc.display_limcv.scaleX = liv_scale * (is_facing_right ? 1 : -1);
				fuc.display_limcv.scaleY = liv_scale;
				fuc.display_limcv.x = -fuc_rect.x * liv_scale;
				fuc.display_limcv.y = -fuc_rect.y * liv_scale;
			}
			
			//zoom text will be handled here as well
			updateZoomText();
			
			//set the name
			preview_tf.htmlText = '<p class="furn_upgrade_preview">'+(dm.chosen_upgrade ? dm.chosen_upgrade.label : dm.upgrade_itemstack.label)+'</p>';
		}
		
		private function onZoomClick(event:MouseEvent = null):void {
			//zoom it in/out
			var end_w:int = PREVIEW_WH;
			var end_h:int = PREVIEW_WH;
			
			if(!is_zoomed){
				end_w = _w - preview_holder.x - _base_padd - 15;
				end_h = _body_min_h - preview_holder.y - 12;
				current_scroll_y = _scroller.scroll_y;
			}
			else {
				//if we are zooming out, bring back the chooser
				_scroller.body.addChild(chooser_ui);
				_scroller.scrollYToTop(current_scroll_y);
				_scroller.refreshAfterBodySizeChange();
			}
			
			//animate
			TSTweener.addTween(preview_holder, {width:end_w, height:end_h, time:.5, onUpdate:onZoomUpdate, onComplete:onZoomComplete});
			
			is_zoomed = !is_zoomed;
			
			//set the zoom text
			updateZoomText();
		}
		
		private function onZoomUpdate():void {
			preview_tf.width = preview_holder.width - PREVIEW_PADD*2;
			
			zoom_holder.x = int(preview_holder.x + preview_holder.width/2 - zoom_holder.width/2);
			zoom_holder.y = int(preview_holder.y + preview_holder.height - zoom_holder.height - 4);
			
			//scale liv_holder while it zooms
			const preview_scale:Number = preview_holder.height / PREVIEW_WH;
			liv_holder.scaleX = liv_holder.scaleY = preview_scale;
			
			//can this sit at the bottom or does it need to be centered vertically
			//const y_pos:int = Math.max(preview_holder.height - liv_holder.height - (PREVIEW_BOTTOM*preview_scale), preview_holder.height/2 - liv_holder.height/2);
			const y_pos:int = preview_holder.height/2 - liv_holder.height/2;
			const x_pos:int = preview_holder.width/2 - liv_holder.width/2;
			liv_holder.y = int(preview_holder.y + y_pos);
			liv_holder.x = int(preview_holder.x + x_pos);
		}
		
		private function onZoomComplete():void {
			if(is_zoomed){
				//hide the chooser
				if(chooser_ui.parent) chooser_ui.parent.removeChild(chooser_ui);
			}
			else {
				//add it to the scroller
				_scroller.body.addChild(chooser_ui);
				_scroller.scrollYToTop(current_scroll_y);
			}
			_scroller.refreshAfterBodySizeChange();
		}
		
		private function onUpgradeButtonClick(event:TSEvent):void {
			if(fuc.is_saving) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			var upgrade:FurnUpgrade = event.data as FurnUpgrade;
			fuc.setChosenUpgrade(upgrade);
			
			if (fuc.display_limcv.is_loaded) {
				onIconLoad();
			} else {
				fuc.display_limcv.loadCompleted_sig.add(onIconLoad);
			}
			
			//change the button label
			if (dm.was_upgrade_id == dm.chosen_upgrade.id) {
				setButtonToDefault();
			} else {
				save_bt.disabled = false;
				if(dm.chosen_upgrade.is_owned){
					save_bt.label = 'Change style';
				}
				else if(dm.chosen_upgrade.credits){
					save_bt.label = 'Change style for '+dm.chosen_upgrade.credits+' '+(dm.chosen_upgrade.credits != 1 ? 'credits' : 'credit');
				}
				else {
					save_bt.label = 'Change style for FREE!';
				}
			}
			
			//make sure we have the credits for this purchase
			updateCredits();
			
			// jigger in a sec, after we are sure the thing is refreshed
			StageBeacon.waitForNextFrame(_jigger);
		}
		
		private function onStatsChanged(e:TSEvent):void {
			updateCredits();
		}
		
		private function updateCredits():void {
			const pc:PC = model.worldModel.pc;
			//update the text
			var you_have_txt:String = 'You have';
			var credits_txt:String = StringUtil.formatNumberWithCommas(pc.stats.credits)+(pc.stats.credits != 1 ? ' credits' : ' credit');
			const enough_credits:Boolean = dm.chosen_upgrade && dm.chosen_upgrade.credits <= pc.stats.credits;
			const ok_sub:Boolean = dm.chosen_upgrade && dm.chosen_upgrade.subscriber_only ? model.worldModel.pc.stats.is_subscriber : true;
			const enough_imagination:Boolean = dm.chosen_upgrade && dm.chosen_upgrade.imagination > 0 ? pc.stats.imagination >= dm.chosen_upgrade.imagination : true;
			
			//check to make sure we have enough credits
			if(dm.chosen_upgrade && !enough_credits && !dm.chosen_upgrade.is_owned){
				you_have_txt = '<span class="furn_upgrade_credits_low">'+you_have_txt+'</span>';
				credits_txt = '<span class="furn_upgrade_credits_low">'+credits_txt+'</span>';
			}
			
			you_have_tf.htmlText = '<p class="furn_upgrade_credits">'+you_have_txt+'</p>';
			credits_tf.htmlText = '<p class="furn_upgrade_credits">'+credits_txt+'</p>';
			credits_holder.graphics.clear();
			credits_holder.graphics.lineStyle(0, 0, 0);
			credits_holder.graphics.beginFill(0, 0);
			credits_holder.graphics.drawRect(0, 0, credits_holder.width, credits_holder.height+credits_offset_y+2);
			get_more_tf.x = int((credits_tf.x + credits_tf.width)/2 - get_more_tf.width/2);
			_jigger();
			
			//set the save state
			var tip_txt:String;
			save_bt.disabled = !dm.chosen_upgrade || !enough_credits || !ok_sub || dm.was_upgrade_id == dm.chosen_upgrade.id || !enough_imagination || fuc.is_saving;
			
			if(save_bt.disabled){
				if(!ok_sub){
					tip_txt = 'You need to be a subscriber';
				}
				else if(!enough_credits){
					tip_txt = 'You need more credits';
				}
				else if(!enough_imagination){
					tip_txt = 'You need more imagination';
				}
			}
			
			//if the button is disabled and we own this thing, let's re-enable it
			if(save_bt.disabled && dm.chosen_upgrade.is_owned && dm.was_upgrade_id != dm.chosen_upgrade.id){
				save_bt.disabled = false;
				tip_txt = null;
			}
			
			save_bt.tip = tip_txt ? {txt:tip_txt, pointer:WindowBorder.POINTER_BOTTOM_CENTER} : null;
		}
		
		private function updateZoomText():void {
			zoom_tf.htmlText = '<p class="furn_upgrade_zoom">'+(!is_zoomed ? 'Zoom In' : 'Zoom Out')+'</p>';
			onZoomUpdate();
		}
		
		private function clean():void {
			if (fuc.display_limcv) {
				fuc.display_limcv.loadCompleted_sig.remove(onIconLoad);
			}
			fuc.clean();
		}
		
		override protected function _jigger():void {
			super._jigger();
			
			_w = 572
			
			if (_loc_mode) {
				_w = _w - PREVIEW_WH - PREVIEW_PADD - _base_padd;
				
				// slim
				if (left_holder.parent) left_holder.parent.removeChild(left_holder);
				if (!credits_holder.parent || credits_holder.parent != _foot_sp) {
					_setFootContents(credits_holder);
				}
				
				chooser_ui.x = 11;
				
				credits_holder.x = Math.round((_w/2) - (credits_holder.width/2));
				credits_holder.y = 0;
				
				
				lightbox_back.x = dm.upgrade_itemstack.x;
				
				var g:Graphics = lightbox_back.graphics;
				if (!lightbox_back.parent) {
					g.clear();
					DrawUtil.drawHighlightBlocker(g, 1000)
					lightbox_back.alpha = 0;
					lights_on = true;
					toggleLights();
					
					TSFrontController.instance.getMainView().gameRenderer.placeOverlayInSCH(
						lightbox_back,
						'fud'
					);
				}
				
				fuc.display_limcv.x = dm.upgrade_itemstack.x;
				fuc.display_limcv.y = dm.upgrade_itemstack.y;
				
				TSFrontController.instance.getMainView().gameRenderer.placeOverlayInSCH(
					fuc.display_limcv,
					'fud'
				);
				
				in_loc_ui_holder.addChild(save_bt);
				in_loc_ui_holder.x = dm.upgrade_itemstack.x;

				if (dm.HANGING_ITEM_TSIDS.indexOf(dm.upgrade_itemstack.class_tsid) > -1) {
					if (model.worldModel.pc.home_info.interior_tsid == model.worldModel.location.tsid) {
						// home
						in_loc_ui_holder.y = dm.upgrade_itemstack.y - (in_loc_ui_holder.height + 10);
					} else {
						// tower has no attic space. We could check to see if the light is near the top of location
						// and only do this in that case, but for now, we'll do it for all hanging things
						in_loc_ui_holder.y = dm.upgrade_itemstack.y + 160;
					}
					lightbox_back.y = dm.upgrade_itemstack.y+(dm.upgrade_itemstack.client::physHeight/2);
				} else {
					if (model.worldModel.location.b-(dm.upgrade_itemstack.y + 30) > in_loc_ui_holder.height) {
						in_loc_ui_holder.y = dm.upgrade_itemstack.y + 30;
					} else {
						in_loc_ui_holder.y = dm.upgrade_itemstack.y - (in_loc_ui_holder.height + 10 + dm.upgrade_itemstack.client::physHeight);
						var min:int = model.worldModel.location.b-(model.layoutModel.loc_vp_h-25);
						if (in_loc_ui_holder.y < min) {
							in_loc_ui_holder.y = min
						}
					}
					lightbox_back.y = dm.upgrade_itemstack.y-(dm.upgrade_itemstack.client::physHeight/2);
				}
				
				
				save_bt.x = -int(save_bt.width/2);
				save_bt.y = 0;
				
				TSFrontController.instance.getMainView().gameRenderer.placeOverlayInSCH(
					in_loc_ui_holder,
					'fud'
				);
				
			} else {
				
				// add it back to the dialog!
				left_holder.addChildAt(save_bt, 0);

				save_bt.x = int(preview_holder.x + (PREVIEW_WH/2 - save_bt.width/2));
				save_bt.y = int(preview_holder.y + PREVIEW_WH + 30);
				
				//liv_holder.addChild(fuc.display_limcv);
				// fat
				if (!left_holder.parent) _body_sp.addChild(left_holder);
				if (!credits_holder.parent || credits_holder.parent != left_holder) {
					_setFootContents(null);
					left_holder.addChildAt(credits_holder, 0);
				}
				
				chooser_ui.x = preview_holder.x + PREVIEW_WH + _base_padd - 6;
				
				credits_holder.x = Math.round(preview_holder.x + (PREVIEW_WH/2 - credits_holder.width/2));
				credits_holder.y = Math.round(save_bt.y + save_bt.height + 14)-credits_offset_y;
			}
			
			
			_body_h = _body_min_h;
			_foot_sp.y = _head_h + _body_h;
			_h = _head_h + _body_h + _foot_h;
			
			_scroller.w = _w-(_border_w*2);
			_scroller.h = _body_h - _divider_h*2;
			
			_draw();
		}
	}
}