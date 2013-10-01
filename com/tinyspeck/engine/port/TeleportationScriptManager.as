package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.TeleportationScript;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingTeleportationScriptCreateVO;
	import com.tinyspeck.engine.net.NetOutgoingTeleportationScriptImbueVO;
	import com.tinyspeck.engine.net.NetOutgoingTeleportationScriptUseVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;

	public class TeleportationScriptManager
	{
		/* singleton boilerplate */
		public static const instance:TeleportationScriptManager = new TeleportationScriptManager();
		
		private var _current_script:TeleportationScript;
		
		public function TeleportationScriptManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function viewScript(payload:Object):void {
			_current_script = TeleportationScript.fromAnonymous(payload, payload.itemstack_tsid);
			
			TeleportationScriptDialog.instance.start();
		}
		
		public function createScript(is_imbued:Boolean, body:String = ''):void {
			if(current_script && current_script.itemstack_tsid){
				TSFrontController.instance.genericSend(
					new NetOutgoingTeleportationScriptCreateVO(current_script.itemstack_tsid, is_imbued, body),
					onCreate, 
					onCreate
				);
			}
			else {
				CONFIG::debugging {
					Console.warn('There is no current_script. WTF?!');
				}
			}
		}
		
		private function onCreate(nrm:NetResponseMessageVO):void {
			//if it was great success close the dialog
			if(nrm.success){
				TeleportationScriptDialog.instance.end(true);
				showSuccess('You created a Teleportation Script!');
			}
			else if(nrm.payload.error && nrm.payload.error.msg){
				showError(nrm.payload.error.msg);
				TeleportationScriptDialog.instance.createFail();
			}
		}
		
		public function useScript(use_token:Boolean):void {
			if(current_script && current_script.itemstack_tsid){
				TSFrontController.instance.genericSend(
					new NetOutgoingTeleportationScriptUseVO(current_script.itemstack_tsid, use_token),	onUse, onUse
				);
			}
			else {
				CONFIG::debugging {
					Console.warn('There is no current_script. WTF?!');
				}
			}
		}
		
		private function onUse(nrm:NetResponseMessageVO):void {
			//if it was great success close the dialog
			if(nrm.success){
				TeleportationScriptDialog.instance.end(true);
			}
			else if(nrm.payload.error && nrm.payload.error.msg){
				showError(nrm.payload.error.msg);
				TeleportationScriptDialog.instance.useFail();
			}
		}
		
		public function imbueScript():void {
			if(current_script && current_script.itemstack_tsid){
				TSFrontController.instance.genericSend(
					new NetOutgoingTeleportationScriptImbueVO(current_script.itemstack_tsid), onImbue, onImbue
				);
			}
			else {
				CONFIG::debugging {
					Console.warn('There is no current_script. WTF?!');
				}
			}
		}
		
		private function onImbue(nrm:NetResponseMessageVO):void {
			//if it was great success slap a token on the dialog
			if(nrm.success){
				_current_script.is_imbued = true;
				TeleportationScriptDialog.instance.imbueSuccess();
			}
			else if(nrm.payload.error && nrm.payload.error.msg){
				showError(nrm.payload.error.msg);
				TeleportationScriptDialog.instance.imbueFail();
			}
		}
		
		private function showSuccess(txt:String):void {
			TSModelLocator.instance.activityModel.growl_message = (txt);
			TSModelLocator.instance.activityModel.activity_message = Activity.createFromCurrentPlayer(txt);
		}
		
		private function showError(txt:String):void {
			TSModelLocator.instance.activityModel.activity_message = Activity.createFromCurrentPlayer(txt);
			
			var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
			cdVO.title = 'There was a problem!'
			cdVO.txt = txt;
			cdVO.choices = [
				{value: true, label: 'OK'}
			];
			cdVO.escape_value = false;
			TSFrontController.instance.confirm(cdVO);
		}
		
		public function get current_script():TeleportationScript { return _current_script; }
	}
}