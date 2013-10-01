package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.acl.ACL;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingACLKeyChangeVO;
	import com.tinyspeck.engine.net.NetOutgoingACLKeyInfoVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesVisitVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	
	import flash.events.EventDispatcher;

	public class ACLManager extends EventDispatcher
	{
		/* singleton boilerplate */
		public static const instance:ACLManager = new ACLManager();
		
		private var is_grant:Boolean;
		
		private var _acl:ACL;
		private var _key_count:int;
		
		public function ACLManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function parseKeyInfo(payload:Object):void {
			if(!payload) return;
						
			_acl = ACL.fromAnonymous(payload);
			
			//if this is our first key ever!
			if(acl.keys_received.length && !key_count){
				ACLDialog.instance.startWithMessage(false);
			}
			
			//let's see if we need to change the amount of keys in the keyring UI
			var new_key_count:int = acl.keys_received.length;
			const pc:PC = TSModelLocator.instance && TSModelLocator.instance.worldModel ? TSModelLocator.instance.worldModel.pc : null;
			if(pc){
				const pc_home_tsid:String = !pc.pol_tsid && pc.home_info ? pc.home_info.interior_tsid : pc.pol_tsid;
				if(pc_home_tsid) new_key_count++;
			}
			
			//sort the received keys by newest to oldest
			SortTools.vectorSortOn(acl.keys_received, ['received'], [Array.DESCENDING]);
			
			//sort the given keys by newest to oldest
			SortTools.vectorSortOn(acl.keys_given, ['received'], [Array.DESCENDING]);
			
			//we want to alert listeners whenever we reparse the key info, even if the key count is the same
			if(key_count == new_key_count){
				dispatchEvent(new TSEvent(TSEvent.CHANGED));
			}
			
			//set the new key count
			key_count = new_key_count;
		}
		
		public function requestKeyInfo(force:Boolean = false):void {
			//go ask the server for the latest and greatest key info
			TSFrontController.instance.genericSend(new NetOutgoingACLKeyInfoVO(), onRequestKeyInfo, onRequestKeyInfo);
		}
		
		private function onRequestKeyInfo(nrm:NetResponseMessageVO):void {
			if(nrm.success){
				parseKeyInfo(nrm.payload);
			}
			else if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('error getting ACL key info');
				}
			}
		}
		
		public function changeAccess(pc_tsid:String, is_grant:Boolean):void {
			//when we are granting/revoking access we tell the server
			this.is_grant = is_grant;
			TSFrontController.instance.genericSend(new NetOutgoingACLKeyChangeVO(pc_tsid, is_grant), onChangeAccess, onChangeAccess);
		}
		
		private function onChangeAccess(nrm:NetResponseMessageVO):void {
			if(nrm.success){
				//if we are granting, show the grant success
				if(is_grant){
					ACLDialog.instance.sendSuccess();
				}
				else {
					//took the key away, let's ask the server for an updated list
					requestKeyInfo(true);
				}
			}
			else if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('error changing ACL key access');
				}
			}
		}
		
		public function visitPlayer(player_tsid:String):void {
			//tell the server we wanna do this
			TSFrontController.instance.genericSend(new NetOutgoingHousesVisitVO(player_tsid), onVisitReply, onVisitReply);
		}
		
		private function onVisitReply(nrm:NetResponseMessageVO):void {
			if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('error changing ACL key access');
				}
			}
		}
		
		private function showError(txt:String):void {
			TSModelLocator.instance.activityModel.activity_message = Activity.createFromCurrentPlayer(txt);
		}
		
		public function get acl():ACL { return _acl; }
		
		public function get key_count():int { return _key_count; }
		public function set key_count(value:int):void {
			if(value == _key_count) return;
			
			_key_count = value;
			
			//let whoever is listening know!
			dispatchEvent(new TSEvent(TSEvent.CHANGED));
			
			//if we are at 0 keys and the dialog is still open, end it
			if(!key_count && ACLDialog.instance.parent) ACLDialog.instance.end(true);
		}
	}
}