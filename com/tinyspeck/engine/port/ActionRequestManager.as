package com.tinyspeck.engine.port
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ActionRequest;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingActionRequestBroadcastVO;
	import com.tinyspeck.engine.net.NetOutgoingActionRequestCancelVO;
	import com.tinyspeck.engine.net.NetOutgoingActionRequestReplyVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;

	public class ActionRequestManager
	{
		/* singleton boilerplate */
		public static const instance:ActionRequestManager = new ActionRequestManager();
		
		private const RESPONDED:Array = [];
		
		private var current_uid:String;
		
		public function ActionRequestManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function create(player_tsid:String, event_type:String, event_tsid:String, txt:String, callback_function:Function = null, got:int = 0, need:int = 0):void {
			TSFrontController.instance.genericSend(
				new NetOutgoingActionRequestBroadcastVO(player_tsid, event_type, event_tsid, txt, got, need), 
				callback_function != null ? callback_function : onCreate, callback_function != null ? callback_function : onCreate
			);
			TSFrontController.instance.goNotAFK();
		}
		
		private function onCreate(nrm:NetResponseMessageVO):void {
			if('error' in nrm.payload && 'msg' in nrm.payload.error){
				showError(nrm.payload.error.msg);
			}
		}
		
		public function reply(request:ActionRequest, callback_function:Function = null):void {
			TSFrontController.instance.genericSend(
				new NetOutgoingActionRequestReplyVO(request.player_tsid, request.event_type, request.event_tsid), 
				callback_function != null ? callback_function : onReply, callback_function != null ? callback_function : onReply
			);
			TSFrontController.instance.goNotAFK();
			current_uid = callback_function != null ? null : request.uid;
		}
		
		private function onReply(nrm:NetResponseMessageVO):void {
			if('error' in nrm.payload && 'msg' in nrm.payload.error){
				showError(nrm.payload.error.msg);
				return;
			}
			
			//add it to the responded array
			addRequestUid(current_uid);
		}
		
		public function cancel(request:ActionRequest, callback_function:Function = null):void {
			TSFrontController.instance.genericSend(
				new NetOutgoingActionRequestCancelVO(request.event_type, request.event_tsid), 
				callback_function != null ? callback_function : onCancel, callback_function != null ? callback_function : onCancel
			);
			TSFrontController.instance.goNotAFK();
			current_uid = callback_function != null ? null : request.uid;
		}
		
		private function onCancel(nrm:NetResponseMessageVO):void {
			if('error' in nrm.payload && 'msg' in nrm.payload.error){
				showError(nrm.payload.error.msg);
				return;
			}
			
			//remove it from the responded array
			removeRequestUid(current_uid);
		}
		
		private function showError(txt:String):void {
			TSModelLocator.instance.activityModel.growl_message = txt;
			TSModelLocator.instance.activityModel.activity_message = Activity.fromAnonymous({txt: txt});
		}
		
		/**
		 * If using other callbacks than the ones that are built in for replying
		 * make sure when it gets the success it adds the uid
		 * @param uid
		 */		
		public function addRequestUid(uid:String):void {
			if(uid && RESPONDED.indexOf(uid) == -1){
				RESPONDED.push(uid);
			}
			current_uid = null;
		}
		
		/**
		 * If using other callbacks than the ones that are built in for canceling
		 * make sure when it gets the success it removes the uid
		 * @param uid
		 */
		public function removeRequestUid(uid:String):void {
			const index:int = uid ? RESPONDED.indexOf(uid) : -1;
			if(index != -1){
				RESPONDED.splice(index, 1);
			}
			current_uid = null;
		}
		
		public function hasRespondedToRequestUid(uid:String):Boolean {
			return RESPONDED.indexOf(uid) != -1;
		}
	}
}