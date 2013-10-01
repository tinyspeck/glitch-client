package com.tinyspeck.engine.control {
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.furniture.FurnUpgrade;
	import com.tinyspeck.engine.data.itemstack.ItemstackState;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.DecorateModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingFurnitureUpgradePurchaseVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.pack.FurnitureBagUI;
	import com.tinyspeck.engine.port.IFurnUpgradeUI;
	import com.tinyspeck.engine.view.itemstack.FurnitureBagItemstackView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackMCView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	
	import flash.events.EventDispatcher;
	
	public class FurnUpgradeController extends EventDispatcher {
		
		private var model:TSModelLocator;
		private var dm:DecorateModel;
		private var ui:IFurnUpgradeUI;
		private var actual_liv:LocationItemstackView; // the actual lis in the location
		private var actual_fbiv:FurnitureBagItemstackView; // the actual lis in furn bag
		
		// we keep these just so we can broadcast update event when they have have actually changed
		private var current_credits:int;
		private var current_imagination:int;
		
		public var display_limcv:LocationItemstackMCView; // this is what we use for display in this dialog
		
		public function FurnUpgradeController() {
		}
		
		public function init(ui:IFurnUpgradeUI):void {
			this.ui = ui;
			model = TSModelLocator.instance;
			dm = model.decorateModel;
		}
		
		public function start(ss_state_override:String='iconic'):Boolean {
			if (!ui) {
				CONFIG::debugging {
					Console.error('no ui?');
				}
				return false;
			}
			
			TSFrontController.instance.changeLocationItemstackVisibility(dm.upgrade_itemstack.tsid, false);
			
			display_limcv = new LocationItemstackMCView(dm.upgrade_itemstack.tsid);
			display_limcv.ss_state_override = ss_state_override;
			display_limcv.worth_rendering = true;
			display_limcv.disableGSMoveUpdates();
			actual_liv = null;
			actual_fbiv = null;
			
			actual_liv = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(dm.upgrade_itemstack.tsid);
			if (!actual_liv) {
				actual_fbiv = FurnitureBagUI.instance.getItemstackViewByTsid(dm.upgrade_itemstack.tsid);
			}
			
			if (!actual_liv && !actual_fbiv) {
				CONFIG::debugging {
					Console.warn('NO actual_liv || actual_fbiv');
				}
				return false;
			}
			
			if (actual_liv) {
				actual_liv.disableGSMoveUpdates();
				actual_liv.configuring = true;
			} else if (actual_fbiv) {
				
			}
			
			//reset the liv
			display_limcv.x = 0;
			display_limcv.y = 0;
			
			//save the current data
			dm.was_furn_config = dm.upgrade_itemstack.itemstack_state.furn_config.clone();
			dm.user_facing_right = dm.was_furn_config.facing_right;
			dm.was_upgrade_id = dm.upgrade_itemstack.furn_upgrade_id; // '0' means not upgraded
			
			for (var i:int;i<dm.upgradesV.length;i++) {
				if (dm.upgradesV[i].id == dm.was_upgrade_id) {
					dm.chosen_upgrade = dm.upgradesV[i];
					CONFIG::debugging {
						Console.info('chose_upgrade: '+dm.was_upgrade_id)
					}
					break;
				}
			}
			
			if (model.worldModel.pc && model.worldModel.pc.stats) {
				//current_credits = model.worldModel.pc.stats.credits;
				//current_imagination = model.worldModel.pc.stats.imagination;
				onStatsChanged(model.worldModel.pc.stats);
			}
			
			//listen to credit changes
			model.worldModel.registerCBProp(onStatsChanged, "pc", "stats");
			
			return true;
		}
		
		private function onStatsChanged(pc_stats:PCStats):void {
			if(pc_stats.credits == current_credits && pc_stats.imagination == current_imagination) return;
			current_credits = pc_stats.credits;
			current_imagination = pc_stats.imagination;
			
			dispatchEvent(new TSEvent(TSEvent.STAT_CHANGE_HAPPENED, null));
		}
		
		
		public function clean():void {
			model.worldModel.unRegisterCBProp(onStatsChanged, "pc", "stats");
			if (display_limcv) {
				if (display_limcv.parent) display_limcv.parent.removeChild(display_limcv);
				display_limcv.dispose();
				display_limcv = null;
			}
			
			if (actual_liv) {
				actual_liv.enableGSMoveUpdates();
				actual_liv = null;
			}
			
			if (actual_fbiv) {
				actual_fbiv = null;
			}
			
			dm.chosen_upgrade = null;
		}
		
		private function sendToServer():void {
			var config_to_send:Object = dm.chosen_upgrade.furniture.config;
			
			// SPECIAL CASE FOR DOORS!! WHERE THE CONFIG IS NOT ASSET SPECIFIC AND NEEDS BE MAINTAINED WHEN CHANGING ASSET
			if (dm.upgrade_itemstack.class_tsid == 'furniture_door') {
				config_to_send = dm.was_furn_config.config;
			}
			
			TSFrontController.instance.genericSend(
				new NetOutgoingFurnitureUpgradePurchaseVO(
					dm.upgrade_itemstack.tsid,
					dm.chosen_upgrade.id,
					config_to_send,
					dm.user_facing_right
				),
				function(rm:NetResponseMessageVO):void {
					saving = false;
					if (actual_fbiv) {
						///actual_fbiv.changeHandler();
						model.worldModel.pc_itemstack_updates = [actual_fbiv.tsid];
					}
					ui.onSave(true);
				},
				function(rm:NetResponseMessageVO):void {
					saving = false;
					cancel();
					ui.onSave(false);
					
					//y u break?
					if('error' in rm.payload && 'msg' in rm.payload.error){
						model.activityModel.activity_message = Activity.createFromCurrentPlayer(rm.payload.error.msg);
					}
				}
			);
		}
		
		public function setChosenUpgrade(upgrade:FurnUpgrade):void {
			if(!dm.upgrade_itemstack || !display_limcv){
				//missing some important shit!
				CONFIG::debugging {
					Console.warn('Missing dm.furn_stack: '+dm.upgrade_itemstack+' or liv: '+display_limcv);
				}
				return;
			}
			
			dm.chosen_upgrade = upgrade;
			/*
			CONFIG::debugging {
				Console.info(dm.chosen_upgrade);
			}
			*/
			var iss:ItemstackState = dm.upgrade_itemstack.itemstack_state;
			
			iss.setFurnConfig(dm.chosen_upgrade.furniture.clone());
			
			iss.furn_config.facing_right = dm.user_facing_right;
			display_limcv.changeHandler(true);
			
			model.worldModel.loc_itemstack_updates = [dm.upgrade_itemstack.tsid];
		}
		
		private var saving:Boolean;
		
		public function get is_saving():Boolean { return saving; }
		
		public function save():void {
			// just cancel if we're not changing anything
			if (!dm.chosen_upgrade || dm.was_upgrade_id == dm.chosen_upgrade.id) {
				cancel();
				ui.onSave(false);
				return;
			}
			
			if (actual_liv) {
				actual_liv.configuring = false;
			}
			
			saving = true;
			sendToServer();
		}
		
		public function cancel():void {
			if (saving) return;
			if(dm.upgrade_itemstack && dm.upgrade_itemstack.itemstack_state) {
				var iss:ItemstackState = dm.upgrade_itemstack.itemstack_state;
				iss.setFurnConfig(dm.was_furn_config);
			}
			
			if (actual_liv) {
				actual_liv.configuring = false;
				model.worldModel.loc_itemstack_updates = [actual_liv.tsid];
			}
			if (actual_fbiv) {
				model.worldModel.pc_itemstack_updates = [actual_fbiv.tsid];
			}
			
			clean();
		}
	}
}