package com.tinyspeck.engine.view.gameoverlay
{
	import com.tinyspeck.debug.NewxpLogger;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.pc.ImaginationCard;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingImaginationPurchaseVO;
	import com.tinyspeck.engine.net.NetOutgoingImaginationShuffleVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.ui.imagination.ImaginationHandUI;

	public class ImaginationManager
	{
		/* singleton boilerplate */
		public static const instance:ImaginationManager = new ImaginationManager();
		
		public var is_confirming:Boolean;
		
		private var upgrade_card:ImaginationCard;
		
		public function ImaginationManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function updateHand():void {
			//if the view is open see which cards are gone and handle that
			if(!upgrade_card) ImaginationHandUI.instance.updateHand();
		}
		
		public function buyUpgrade(upgrade_card:ImaginationCard):void {
			//send it off to the server			
			this.upgrade_card = upgrade_card;
			NewxpLogger.log('buying_img_upg_'+upgrade_card.class_tsid);
			TSFrontController.instance.genericSend(new NetOutgoingImaginationPurchaseVO(upgrade_card.id), onBuyUpgrade, onBuyUpgrade);
		}
		
		private function onBuyUpgrade(nrm:NetResponseMessageVO):void {
			if(nrm.success){
				if (upgrade_card) NewxpLogger.log('bought_img_upg_'+upgrade_card.class_tsid);
				//do that fancy thing where it shows the fullscreen purchase
				ImaginationHandUI.instance.showPurchase(upgrade_card);
				upgrade_card = null;
			}
			else if(nrm.payload.error){
				if (upgrade_card) NewxpLogger.log('failed_to_buy_img_upg_'+upgrade_card.class_tsid, StringUtil.getJsonStr(nrm.payload));
				showError(nrm.payload.error.msg);
				ImaginationHandUI.instance.show(); //resets the hand
			}
		}
		
		public function redeal():void {
			//go ask the server for a new hand
			TSFrontController.instance.genericSend(new NetOutgoingImaginationShuffleVO(), onRedeal, onRedeal);
		}
		
		private function onRedeal(nrm:NetResponseMessageVO):void {
			if(nrm.success){
				//we made the redeal happen. Set the PC to have had this happen for the day
				const pc:PC = TSModelLocator.instance.worldModel.pc;
				if(pc && pc.stats) {
					pc.stats.imagination_shuffled_today = true;
					ImaginationHandUI.instance.updateHand();
				}
			}
			else if(nrm.payload.error){
				showError(nrm.payload.error.msg);
			}
		}
		
		private function showError(txt:String):void {
			TSModelLocator.instance.activityModel.activity_message = Activity.createFromCurrentPlayer(txt);
		}
	}
}