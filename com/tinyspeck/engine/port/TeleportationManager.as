package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCBuff;
	import com.tinyspeck.engine.data.pc.PCTeleportation;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingTeleportationGoVO;
	import com.tinyspeck.engine.net.NetOutgoingTeleportationMapVO;
	import com.tinyspeck.engine.net.NetOutgoingTeleportationSetVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.util.StringUtil;

	public class TeleportationManager
	{
		/* singleton boilerplate */
		public static const instance:TeleportationManager = new TeleportationManager();
		
		private static const teleport_choices:Array = new Array();
		private static const cdVO:ConfirmationDialogVO = new ConfirmationDialogVO(null, '', teleport_choices);
		
		private const TELEPORTATION_DEBUFF:String = 'teleportation_cooldown';
		
		private var last_teleport_id:uint;
		private var last_location_tsid:String;
		
		public function TeleportationManager() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function update(payload:Object):void {
			if(payload.error){ //should never have this...
				showError(payload.error.msg);
				CONFIG::debugging {
					Console.warn('Error updating teleportation spot');
				}
				return;
			}
			
			updateCooldown();
			
			//update the pc and refresh the UI
			if(payload.status) payload = payload.status;
			pc.teleportation = PCTeleportation.fromAnonymous(payload, pc.tsid);
			TeleportationDialog.instance.onTeleportationChange();
		}
		
		public function clientSet(teleport_id:uint = 1):void {
			last_teleport_id = teleport_id;
			TSFrontController.instance.genericSend(new NetOutgoingTeleportationSetVO(teleport_id), set, set);
		}
		
		private function set(nrm:NetResponseMessageVO):void {
			if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('Error setting teleportation spot');
				}
				return;
			}
			
			updateCooldown();
			
			//update the pc and refresh the UI
			if(nrm.payload.status) nrm.payload = nrm.payload.status;
			pc.teleportation = PCTeleportation.fromAnonymous(nrm.payload, pc.tsid);
			TeleportationDialog.instance.onTeleportationChange();
			TeleportationDialog.instance.onLocationSet();
			
			//throw a growl in for good measure
			if(pc.teleportation.targets && pc.teleportation.targets.length){
				showSuccess('Teleportation location set to '+pc.teleportation.targets[last_teleport_id-1].label);
			}
		}
		
		public function clientGo(teleport_id:uint = 1):void {
			TSFrontController.instance.genericSend(new NetOutgoingTeleportationGoVO(teleport_id), go, go);
		}
		
		private function go(nrm:NetResponseMessageVO):void {
			//update things no matter what
			updateCooldown();
			
			if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('Error teleporting');
				}
				return;
			}
			
			//close the familiar dialog since we are moving!
			TSFrontController.instance.endFamiliarDialog();
		}
		
		public function clientMap(location_tsid:String, is_token:Boolean):void {
			TSFrontController.instance.genericSend(new NetOutgoingTeleportationMapVO(location_tsid, is_token), onMap, onMap);
		}
		
		private function onMap(nrm:NetResponseMessageVO):void {
			//update things no matter what
			updateCooldown();
			
			if(nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('Error teleporting via map');
				}
				return;
			}
			
			//close the familiar dialog since we are moving!
			TSFrontController.instance.endFamiliarDialog();
		}
		
		public function showTeleportConfirmationDialog(location_tsid:String):void {
			const teleportation:PCTeleportation = pc ? pc.teleportation : null;
			
			last_location_tsid = location_tsid;
			
			//reset the choices
			teleport_choices.length = 0;
			
			var txt:String;
			
			if(teleportation && teleportation.skill_level){
				const location:Location = TSModelLocator.instance.worldModel.getLocationByTsid(location_tsid);
				
				//setup the text
				txt = 'Looking to teleport '+(location ? 'to <b>'+location.label+'</b>' : 'someplace')+'?';
				
				//enough energy and skill?
				if(teleportation.skill_level >= 4){
					teleport_choices.push({
						value: 'energy', 
						label: 'Use '+teleportation.energy_cost+' energy',
						disabled_reason: (pc && pc.stats && pc.stats.energy.value < teleportation.energy_cost
										  ? 'You only have '+pc.stats.energy.value+ 'energy'
										  : null)
					});
				}
				else {
					teleport_choices.push({
						value: 'energy', 
						label: 'Use energy',
						disabled_reason: 'You need Teleportation IV to use energy!'
					});
				}
				
				//do they have any tokens?
				if(teleportation.tokens_remaining){
					teleport_choices.push({
						value: 'token', 
						label: 'Use a token ('+StringUtil.formatNumberWithCommas(teleportation.tokens_remaining)+' remaining)',
						disabled_reason: (teleportation.map_tokens_used == teleportation.map_tokens_max 
							? 'You have used up your allowed teleportation tokens for this game day ('+teleportation.map_tokens_max+')'
							: null)
					});
				}
				else {
					teleport_choices.push({
						value: 'token', 
						label: 'Use a token',
						disabled_reason: 'You are out of teleportation tokens!'
					});
				}
				
				
				//cancel
				teleport_choices.push({label: 'Cancel'});
			}
			else {
				//something effed up someplace, but let's not leave them hanging
				txt = 'Oh no! You can\'t teleport right now.';
				teleport_choices.push({label: 'OK'});
			}
						
			cdVO.title = 'Please Confirm!'
			cdVO.callback = onTeleportChoice;
			cdVO.escape_value = '';
			cdVO.txt = txt;
			TSFrontController.instance.confirm(cdVO);
		}
		
		private function onTeleportChoice(value:String):void {
			//do they want to use energy, token or nothing
			if(value){
				clientMap(last_location_tsid, value == 'token');
			}
		}
		
		private function showSuccess(txt:String):void {
			TSModelLocator.instance.activityModel.growl_message = (txt);
			TSModelLocator.instance.activityModel.activity_message = Activity.createFromCurrentPlayer(txt);
		}
		
		private function showError(txt:String):void {
			TSModelLocator.instance.activityModel.activity_message = Activity.createFromCurrentPlayer(txt);
			
			teleport_choices.length = 0;
			teleport_choices.push({value: true, label: 'OK'});
			
			cdVO.title = 'There was a problem!'
			cdVO.txt = txt;
			cdVO.escape_value = false;
			cdVO.callback = null;
			TSFrontController.instance.confirm(cdVO);
		}
		
		private function updateCooldown():void {
			//set the cooldown amount and start the timer
			var cooldown:PCBuff = pc.buffs[TELEPORTATION_DEBUFF];
			
			if(cooldown && cooldown.remaining_duration > 0){
				TeleportationDialog.instance.cooldown_left = cooldown.remaining_duration;
			}
			else {
				TeleportationDialog.instance.cooldown_left = 0;
			}
		}
		
		private function get pc():PC {
			return TSModelLocator.instance.worldModel.pc;
		}
	}
}