package com.tinyspeck.engine.port
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.house.ConfigOption;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.net.NetOutgoingItemstackSetUserConfigVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.DrawUtil;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.ObjectUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackMCView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.ConfiggerUI;
	
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;

	public class ItemstackConfigDialog extends BigDialog implements IFocusableComponent {
		/* singleton boilerplate */
		public static const instance:ItemstackConfigDialog = new ItemstackConfigDialog();
		
		private var wm:WorldModel;
		
		private var body_sp:Sprite;
		private var foot_sp:Sprite;
		private var save_bt:Button;
		private var lightbox_back:Shape = new Shape();
		private var display_limcv:LocationItemstackMCView; // this is what we use for display in the SCH
		private var liv:LocationItemstackView;
		private var configger_ui:ConfiggerUI;
		
		private var was_scale:Number;
		private var was_y_cam_offset:int;
		private var was_config:Object;
		private var changed_config:Object;
		private var has_config_changed:Boolean;
		private var saving:Boolean;
		private var itemstack_pt:Point = new Point(0,0);
		private var config_options:Vector.<ConfigOption> = new Vector.<ConfigOption>();
		private var itemstack:Itemstack;
		
		public function ItemstackConfigDialog() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			wm = model.worldModel;
			_body_border_c = 0xffffff;
			_close_bt_padd_right = 9;
			_close_bt_padd_top = 9;
			_w = 250;
			_draggable = true;
			_construct();
		}
		
		public function startWithItemstack(itemstack_tsid:String):void {
			this.itemstack = model.worldModel.getItemstackByTsid(itemstack_tsid);
			liv = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(itemstack_tsid);
			start();
		}
		
		override public function start():void {
			if (!itemstack) return;
			if (!liv) return;
			if (parent) return;
			if (!canStart(true)) return;
			
			if (!body_sp) {
				body_sp = new Sprite();
				var g:Graphics = body_sp.graphics;
				g.beginFill(0,0);
				g.drawRect(0,0,20,20);
				
				configger_ui = new ConfiggerUI(_w-5, true);
				configger_ui.y = 1;
				configger_ui.change_config_sig.add(changeConfigOptions);
				configger_ui.randomize_sig.add(showRandomConfig);
				body_sp.addChild(configger_ui);
				
				g = lightbox_back.graphics;
				g.clear();
				DrawUtil.drawHighlightBlocker(g, 1000);
				
				foot_sp = new Sprite();
				save_bt = new Button({
					name: 'save',
					label: 'Save',
					size: Button.SIZE_DEFAULT,
					type: Button.TYPE_MINOR,
					w: 100
				});
				save_bt.addEventListener(MouseEvent.CLICK, onSaveButtonClick);
				save_bt.x = Math.round((_w/2) - (save_bt.width/2));
				save_bt.y = 9;
				foot_sp.addChild(save_bt);
				
				g = foot_sp.graphics;
				g.beginFill(0,0);
				g.drawRect(0,0,10,(save_bt.y*2)+2+save_bt.h);
			}
			
			_setGraphicContents(null/*new AssetManager.instance.assets.help_icon_large()*/);
			_setTitle(/*itemstack.label+' */'Customizer');
			_setSubtitle('');
			_setBodyContents(body_sp);
			_setFootContents(foot_sp);
			
			if (!setConfigChoices()) {
				return;
			}
			
			liv.disableGSMoveUpdates();
			liv.y-= 800; // just get it out of the viewport
			
			// remember what is was so we can discard changes!
			was_config = ObjectUtil.copyOb(itemstack.itemstack_state.config_for_swf) || {};
			changed_config = ObjectUtil.copyOb(was_config);
			has_config_changed = false;
			
			super.start();
			
			was_scale = model.layoutModel.loc_vp_scale;
			was_y_cam_offset = model.worldModel.pc.apo.setting.y_cam_offset;
			centerUpgradeStackInWindow();
			
			TSTweener.removeTweens(lightbox_back);
			lightbox_back.x = itemstack.x;
			lightbox_back.y = itemstack.y-(itemstack.client::physHeight/2);
			lightbox_back.alpha = 0;
			TSFrontController.instance.getMainView().gameRenderer.placeOverlayInSCH(
				lightbox_back,
				'icd'
			);
			TSTweener.addTween(lightbox_back, {alpha:.75, time:.6});
			
			
			// on top!
			
			display_limcv = new LocationItemstackMCView(itemstack.tsid);
			display_limcv.ss_state_override = '1';
			display_limcv.worth_rendering = true;
			display_limcv.disableGSMoveUpdates();
			
			display_limcv.x = itemstack.x;
			display_limcv.y = itemstack.y;
			TSFrontController.instance.getMainView().gameRenderer.placeOverlayInSCH(
				display_limcv,
				'icd'
			);
			
			save_bt.disabled = false;
		
			// move avatar to side of item
			TSFrontController.instance.startMovingAvatarOnGSPath(new Point(itemstack.x-100, 0), 'right');

		}
		
		private function showRandomConfig():void {
			var random_i:int;
			var option:ConfigOption;
			var option_names:Array = [];
			var option_values:Array = [];
			
			// choose some random options
			for(var i:int=0; i<config_options.length; i++){
				option = config_options[int(i)];
				if (!option.choices || !option.choices.length) continue;
				random_i = MathUtil.randomInt(0, option.choices.length-1);
				option_names.push(option.id);
				option_values.push(option.choices[random_i]);
			}
			
			changeConfigOptions(option_names, option_values);
			setConfigChoices();
		}
		
		private function setConfigChoices():Boolean {
			if (!ConfigOption.populateConfigChoicesForItemstack(itemstack, config_options, itemstack.itemstack_state.config)) {
				return false;
			}
			
			configger_ui.startWithConfigs(config_options, true, false, false);
			refresh();
			return true;
		}
		
		override public function refresh():void {
			configger_ui.refresh();
			super.refresh();
		}
		
		private function changeConfigOptions(option_names:Array, option_values:Array):void {
			has_config_changed = true;
			
			var option_name:String;
			var option_value:String;
			
			for (var i:int=0;i<option_names.length;i++) {
				if (i > option_values.length-1) break;
				option_name = option_names[i];
				option_value = option_values[i];
				changed_config[option_name] = option_value;
			}
			
			changeConfigOnLocalItemstack(changed_config);
		}
		
		private function changeConfigOnLocalItemstack(c:Object):void {
			var config:Object = itemstack.itemstack_state.config || {};
			for (var k:String in c) {
				config[k] = c[k];
			}
			
			itemstack.itemstack_state.config = config;
			itemstack.itemstack_state.is_config_dirty = true;
			wm.loc_itemstack_updates = [itemstack.tsid]; // calls a trigger when set
			
			display_limcv.changeHandler(true);
		}
		
		private function centerUpgradeStackInWindow():void {
			
			TSFrontController.instance.setViewportScale(1, .5, false, true);
			
			var y_offset:int = (-itemstack.client::physHeight/2);
			var new_x:int = itemstack.x;
			var new_y:int = itemstack.y+y_offset;
			
			model.worldModel.pc.apo.setting.y_cam_offset = 0;
			itemstack_pt.x = new_x;
			itemstack_pt.y = new_y;
			TSFrontController.instance.setCameraCenter(null, null, itemstack_pt, 0, true);
		}
		
		override protected function _place():void {
			if (!model.flashVarModel.new_furn_up) {
				super._place();
				return;
			}
			
			// center this vertically in the viewport
			dest_y = Math.round((model.layoutModel.loc_vp_h-_h)/2) + model.layoutModel.header_h;
			
			// place this just to the right of the item
			var offset:int = Math.min((model.layoutModel.loc_vp_w/2), (model.worldModel.location.r-itemstack.x));
			// this gets us as far to the left as we need to be (no more than halway acrooss the vp)
			dest_x = model.layoutModel.gutter_w + model.layoutModel.loc_vp_w - offset;
			// this moves it over to the right to allows space for the stack and button
			dest_x += Math.max((itemstack.client::physWidth/2) + 50, 100);
			
			if (!transitioning) {
				x = dest_x;
				y = dest_y;
			}
		}
		
		private function saveOrClose():void {
			if (saving) {
				return;
			}
			
			if (!has_config_changed) {
				super.closeFromUserInput();
				return;
			}
			
			saving = true;
			save_bt.disabled = true;
			TSFrontController.instance.genericSend(
				new NetOutgoingItemstackSetUserConfigVO(
					itemstack.tsid,
					changed_config
				),
				onSave,
				onSave
			);
		}
		
		private function onSave(rm:NetResponseMessageVO):void {
			saving = false;
			
			if (rm.success) {
				TSFrontController.instance.showCheckmark(itemstack.x, itemstack.y);
				end(true);
			} else {
				if (rm.payload.msg) {
					model.activityModel.growl_message = 'Saving failed: '+rm.payload.msg;
				} else if (rm.payload.error && rm.payload.error.msg) {
					model.activityModel.growl_message = 'Saving failed: '+rm.payload.error.msg;
				} else {
					model.activityModel.growl_message = 'Saving failed';
				}
				closeAndDiscard();
			}
		}
		
		override protected function enterKeyHandler(e:KeyboardEvent):void {
			saveOrClose();
		}
		
		private function onSaveButtonClick(e:MouseEvent):void {
			saveOrClose();
		}
		
		override protected function closeFromUserInput(e:Event=null):void {
			if (saving) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			if (has_config_changed) {
				closeAndDiscard();
				return;
			}
			
			super.closeFromUserInput(e);
		}
		
		private function closeAndDiscard():void {
			if (has_config_changed) {
				changeConfigOnLocalItemstack(was_config);
			}
			
			//fuc.cancel();
			end(true);
		}
		
		override public function end(release:Boolean):void {
			if (saving) {
				return;
			}
			
			if (liv) {
				liv.x = itemstack.x;
				liv.y = itemstack.y;
				liv.enableGSMoveUpdates();
				liv.changeHandler(true);
				liv = null;
			}
			
			if (display_limcv) {
				if (display_limcv.parent) display_limcv.parent.removeChild(display_limcv);
				display_limcv.dispose();
				display_limcv = null;
			}
			
			itemstack = null;
			
			super.end(release);
			
			if (lightbox_back.parent) lightbox_back.parent.removeChild(lightbox_back);
			
			//if (in_loc_ui_holder.parent) in_loc_ui_holder.parent.removeChild(in_loc_ui_holder);
			
			TSFrontController.instance.setViewportScale(was_scale, .5, false, true);
			model.worldModel.pc.apo.setting.y_cam_offset = was_y_cam_offset;
			TSFrontController.instance.resetCameraCenter();
		}
	}
}