package com.tinyspeck.engine.port
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.Emblem;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingEmblemSpendVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;

	public class EmblemManager
	{
		/* singleton boilerplate */
		public static const instance:EmblemManager = new EmblemManager();
		
		private var _current_emblem:Emblem;
		
		public function EmblemManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function start(payload:Object):void {
			_current_emblem = Emblem.fromAnonymous(payload);
			EmblemSpendDialog.instance.start();
		}
		
		public function spend():void {
			if(current_emblem){
				TSFrontController.instance.genericSend(
					new NetOutgoingEmblemSpendVO(current_emblem.itemstack_tsid),
					onSpend, 
					onSpend
				);
			}
		}
		
		private function onSpend(nrm:NetResponseMessageVO):void {
			//since we are closing the dialog when they say "yes" we only care if there is an error to dump out to the activity pane
			if(!nrm.success && nrm.payload.error){
				TSModelLocator.instance.activityModel.activity_message = nrm.payload.error.msg;
			}
		}
		
		public function get current_emblem():Emblem { return _current_emblem; }
	}
}