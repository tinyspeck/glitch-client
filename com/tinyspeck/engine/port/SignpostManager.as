package com.tinyspeck.engine.port
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingHousesAddNeighborVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesRemoveNeighborVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;

	public class SignpostManager
	{
		/* singleton boilerplate */
		public static const instance:SignpostManager = new SignpostManager();
		
		public function SignpostManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function addNeighbor(sign_id:int, pc_tsid:String):void {
			//fire it off to the server
			TSFrontController.instance.genericSend(new NetOutgoingHousesAddNeighborVO(sign_id, pc_tsid), onServerReply, onServerReply);
		}
		
		public function removeNeighbor(sign_id:int):void {
			//off you go
			TSFrontController.instance.genericSend(new NetOutgoingHousesRemoveNeighborVO(sign_id), onServerReply, onServerReply);
		}
		
		private function onServerReply(nrm:NetResponseMessageVO):void {
			//let the dialog know
			SignpostDialog.instance.update(nrm.success);
			
			if(!nrm.success && 'error' in nrm.payload){
				showError(nrm.payload.error.msg);
			}
		}
		
		private function showError(txt:String):void {
			TSModelLocator.instance.activityModel.activity_message = Activity.createFromCurrentPlayer(txt);
		}
	}
}