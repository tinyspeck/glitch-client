package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.house.Cultivations;
	import com.tinyspeck.engine.data.house.HouseExpand;
	import com.tinyspeck.engine.data.house.HouseStyles;
	import com.tinyspeck.engine.data.item.Verb;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.net.NetOutgoingCultivationStartVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesExpandCostsVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesExpandWallVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesExpandYardVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesStyleChoicesVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesStyleSwitchVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesUnexpandWallVO;
	import com.tinyspeck.engine.net.NetOutgoingItemstackVerbMenuVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	
	import flash.utils.getTimer;

	public class HouseManager
	{
		/* singleton boilerplate */
		public static const instance:HouseManager = new HouseManager();
		
		private var chasis_itemstack:Itemstack;
		private var chasis_array:Array;
		
		private var last_expand_parse:uint;
		
		private var _house_expand:HouseExpand;
		private var _house_styles:HouseStyles;
		private var _cultivations:Cultivations;
		
		public function HouseManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function parseExpandInfo(payload:Object):void {
			_house_expand = HouseExpand.fromAnonymous(payload);
			last_expand_parse = getTimer();
		}
		
		public function requestExpandCostsFromServer():void {
			//go ask the server what's what.
			_house_expand = null;
			TSFrontController.instance.genericSend(new NetOutgoingHousesExpandCostsVO(), onRequestReply, onRequestReply);
		}
		
		private function onRequestReply(nrm:NetResponseMessageVO):void {
			if(nrm.success){
				//looks good, go update stuff
				parseExpandInfo(nrm.payload);
				HouseExpandDialog.instance.update();
				HouseExpandYardDialog.instance.update();
			}
			else if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('request for the data failed!');
				}
			}
		}
		
		public function sendWallExpand():void {
			TSFrontController.instance.genericSend(new NetOutgoingHousesExpandWallVO(), onExpandReply, onExpandReply);
		}
		
		public function sendYardExpand(side:String):void {
			TSFrontController.instance.genericSend(new NetOutgoingHousesExpandYardVO(side), onExpandReply, onExpandReply);
		}
		
		public function sendWallUnexpand():void {
			TSFrontController.instance.genericSend(new NetOutgoingHousesUnexpandWallVO(), onExpandReply, onExpandReply);
		}		
		
		private function onExpandReply(nrm:NetResponseMessageVO):void {
			if(nrm.success){
				//close the dialog
				//HouseExpandDialog.instance.end(true);
			}
			else if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				
				//update the dialog
				HouseExpandDialog.instance.update();
				
				CONFIG::debugging {
					Console.warn('expand wall error!');
				}
			}
		}
		
		public function startCultivation():void {
			TSFrontController.instance.genericSend(new NetOutgoingCultivationStartVO(), onCultStart, onCultStart);
		}
		
		private function onCultStart(nrm:NetResponseMessageVO):void {
			if (nrm.success) {
				_cultivations = Cultivations.fromAnonymous(nrm.payload);
				if (!cultivations.choices || !cultivations.choices.length) {
					SoundMaster.instance.playSound('CLICK_FAILURE');
				} else {
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					TSFrontController.instance.startCultMode();
				}
			} else {
				SoundMaster.instance.playSound('CLICK_FAILURE');
			}
		}
		
		public function openChassisChanger(item_class:String):void {
			const world:WorldModel = TSModelLocator.instance.worldModel;
			chasis_array = world.getLocationItemstacksAByItemClass(item_class);
			if (!chasis_array.length) {
				CONFIG::debugging {
					Console.warn('no '+item_class);
				}
				return;
			}
			
			chasis_itemstack = world.getItemstackByTsid(chasis_array[0].tsid);
			
			var chassis_liv:LocationItemstackView = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(chasis_itemstack.tsid);
			if (!chassis_liv) {
				CONFIG::debugging {
					Console.warn('no chassis view');
				}
				return;
			}
			
			//send it off to the server
			TSFrontController.instance.genericSend(new NetOutgoingItemstackVerbMenuVO(chasis_itemstack.tsid), onOpenChassis, onOpenChassis);
		}
		
		private function onOpenChassis(nrm:NetResponseMessageVO):void {
			if(nrm.success){
				var verb:Verb = chasis_itemstack.item.verbs['upgrade']; // conditional_verbs got updated in netcontroller by this msg rsp
				if (!verb || !verb.enabled) {
					verb = chasis_itemstack.item.verbs['change_style'];
				}
				
				if (!verb || !verb.enabled) {
					verb = chasis_itemstack.item.verbs['customize'];
				}
				
				if (verb && verb.enabled) { // we have the the Verb now
					TSFrontController.instance.doVerb(chasis_array[0].tsid, verb.tsid);
					//TSFrontController.instance.moveAvatarToLIVandSendVerb(chassis_liv, verb.tsid);
					
					//close the dialog
					HouseSignDialog.instance.end(true);
				}
				else {
					CONFIG::debugging {
						Console.warn('Did the verb change again? We tried "upgrade", "change_style" and "customize"');
					}
				}
			}
			else if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				
				CONFIG::debugging {
					Console.warn('Open chassis error!');
				}
			}
		}
		
		public function requestStyleChoicesFromServer():void {
			TSFrontController.instance.genericSend(new NetOutgoingHousesStyleChoicesVO(), onStyleReply, onStyleReply);
		}
		
		public function parseStyleInfo(payload:Object):void {
			_house_styles = HouseStyles.fromAnonymous(payload);
			last_expand_parse = getTimer();
		}
		
		private function onStyleReply(nrm:NetResponseMessageVO):void {
			if(nrm.success){
				//looks good, go update stuff
				parseStyleInfo(nrm.payload);
				HouseStylesDialog.instance.update();
			}
			else if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('request for the style data failed!');
				}
			}
		}
		
		public function sendStyleChange(tsid:String):void {
			TSFrontController.instance.genericSend(new NetOutgoingHousesStyleSwitchVO(tsid), onStyleChangeReply, onStyleChangeReply);
		}
		
		private function onStyleChangeReply(nrm:NetResponseMessageVO):void {
			if(nrm.success){
				//close the dialog
				//HouseStylesDialog.instance.end(true);
			}
			else if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				
				//update the dialog
				HouseStylesDialog.instance.update();
				
				CONFIG::debugging {
					Console.warn('expand wall error!');
				}
			}
		}
		
		private function showError(txt:String):void {
			TSModelLocator.instance.activityModel.activity_message = Activity.createFromCurrentPlayer(txt);
		}
		
		public function get house_expand():HouseExpand { return _house_expand; }
		public function get house_styles():HouseStyles { return _house_styles; }
		public function get cultivations():Cultivations { return _cultivations; }
	}
}