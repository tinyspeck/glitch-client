package com.tinyspeck.engine.port
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.party.PartySpace;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingPartySpaceResponseVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;

	public class PartySpaceManager
	{
		/* singleton boilerplate */
		public static const instance:PartySpaceManager = new PartySpaceManager();
		
		private var _current_party:PartySpace;
		
		public function PartySpaceManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function start(payload:Object):void {
			_current_party = PartySpace.fromAnonymous(payload);
			PartySpaceDialog.instance.start();
		}
		
		public function respond(spend_energy:Boolean, spend_token:Boolean):void {
			TSFrontController.instance.genericSend(new NetOutgoingPartySpaceResponseVO(spend_energy, spend_token), onRespond, onRespond);
		}
		
		private function onRespond(nrm:NetResponseMessageVO):void {
			if(nrm.success){
				PartySpaceDialog.instance.end(true);
			}
			else if('error' in nrm.payload){
				TSModelLocator.instance.activityModel.activity_message = Activity.createFromCurrentPlayer(nrm.payload.error.msg);
			}
		}
		
		public function get current_party():PartySpace { return _current_party; }
	}
}