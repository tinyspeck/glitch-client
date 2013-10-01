package com.tinyspeck.engine.control {
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.garden.Garden;
	import com.tinyspeck.engine.data.garden.GardenAction;
	import com.tinyspeck.engine.data.garden.GardenPlot;
	import com.tinyspeck.engine.data.group.Group;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.item.Verb;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.Hub;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.map.Street;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.InteractionMenuModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.MessageTypes;
	import com.tinyspeck.engine.net.NetOutgoingAdminTeleportVO;
	import com.tinyspeck.engine.net.NetOutgoingBuddyAddVO;
	import com.tinyspeck.engine.net.NetOutgoingBuddyRemoveVO;
	import com.tinyspeck.engine.net.NetOutgoingFollowEndVO;
	import com.tinyspeck.engine.net.NetOutgoingFollowStartVO;
	import com.tinyspeck.engine.net.NetOutgoingGetPathToLocationVO;
	import com.tinyspeck.engine.net.NetOutgoingHousesVisitVO;
	import com.tinyspeck.engine.net.NetOutgoingItemstackMenuUpVO;
	import com.tinyspeck.engine.net.NetOutgoingItemstackVerbCancelVO;
	import com.tinyspeck.engine.net.NetOutgoingItemstackVerbMenuVO;
	import com.tinyspeck.engine.net.NetOutgoingItemstackVerbVO;
	import com.tinyspeck.engine.net.NetOutgoingPartyInviteVO;
	import com.tinyspeck.engine.net.NetOutgoingPcMenu;
	import com.tinyspeck.engine.net.NetOutgoingPcVerbMenuVO;
	import com.tinyspeck.engine.net.NetOutgoingTeleportationMapVO;
	import com.tinyspeck.engine.net.NetOutgoingTradeStartVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.port.GardenManager;
	import com.tinyspeck.engine.port.PlayerInfoDialog;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.port.ShrineManager;
	import com.tinyspeck.engine.port.TSSprite;
	import com.tinyspeck.engine.port.TeleportationDialog;
	import com.tinyspeck.engine.port.TradeManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.URLUtil;
	import com.tinyspeck.engine.view.gameoverlay.maps.HubMapDialog;
	import com.tinyspeck.engine.view.ui.InteractionMenu;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.chat.ChatArea;
	import com.tinyspeck.engine.view.ui.garden.GardenView;
	
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.getQualifiedClassName;

	public class InteractionMenuController {
		private var model:TSModelLocator;
		private var imm:InteractionMenuModel;
		
		public function init(model:TSModelLocator):void {
			this.model = model;
			imm = model.interactionMenuModel;
		}
		
		public function startLocationDisambiguator(V:Vector.<TSSprite>, type:String):void {
			if (!V.length) return;
			
			// make a copy, so we don't fuck with the original when we sort or weed
			const newA:Array = [];
			for each (var e:* in V) newA.push(e);
			
			newA.sortOn(['disambugate_sort_on'], [Array.NUMERIC]);
			
			/* THE values for disambugate_sort_on should be these:
			1. Street spirit   ITEM  NPC		10
			2. NPC Vendor      ITEM  NPC		20
			3. Shrine          ITEM  NPC		30
			4. Trant           ITEM  TRANT	    40
			5. Patch           ITEM  		    50
			6. NPC Animal      ITEM  NPC		60
			7. Ladder		  LADDER		    70
			8. Signpost        SIGN			    80
			9. Door            DOOR			    90
			10. Item on ground  ITEM			100
			11. Other player    PC			    110
			
			The relevant clasess override TSSprite's get disambugate_sort_on() and return the above values
			*/
			
			newA.push('x');
			
			imm.reset();
			imm.type = type;
			imm.choices = newA;
			
			InteractionMenu.instance.present('Choose the thing you want to interact with:');
		}
		
		public function handleDisambiguatorChoice(choice_i:int = -1, by_click:Boolean = false):void {
			if (imm.type != InteractionMenuModel.TYPE_LOC_DISAMBIGUATOR) {
				CONFIG::debugging {
					Console.warn('we are ignoring this because imm.interaction_menu_type is '+imm.type);
				}
				endInteractionMenu();
				return;
			};
			
			if (choice_i > -1) {
				var choice_value:* = imm.choices[choice_i];
				endInteractionMenu();
				if (choice_value is String) {
					endInteractionMenu();
					CONFIG::debugging {
						if (choice_value != 'x') Console.warn('wtf choice_value:'+choice_value)
					}
				} else {
					// should we here check it is a valid thing to pass to startInteractionWith()??
					TSFrontController.instance.startInteractionWith(choice_value);
				}
				
			} else {
				endInteractionMenu();
			}
		}
		
		public function startLocationMenu(street:Street, hub_tsid:String, by_click:Boolean = false):void {
			const pc:PC = model.worldModel.pc;
			
			imm.reset();
			imm.active_tsid = street.tsid;
			imm.type = InteractionMenuModel.TYPE_HUBMAP_STREET_MENU;
			imm.by_click = by_click;
			
			//inject it
			street.hub_id = hub_tsid;
			
			var destination_choice:Object = {
				value: 'make_location_path',
				label: 'Set as Destination',
				tooltip: 'Get a guided path to this location',
				disabled_reason: 'This is your current location!',
				disabled: (street.tsid == model.worldModel.location.tsid)
			}
			
			if (model.worldModel.location.no_pathing_out) {
				destination_choice.disabled_reason = 'You can\'t set a desination from here';
				destination_choice.disabled = true;
			} else if (street.not_a_destination) {
				destination_choice.disabled_reason = 'This location does not allow navigation';
				destination_choice.disabled = true;
			} else if (pc && !pc.is_dead && hub_tsid == Hub.HELL_TSID) {
				destination_choice.disabled_reason = 'You must be dead to go here';
				destination_choice.disabled = true;
			}
			
			imm.choices = [
				{
					value: street,
					label: 'Create Link for Chat',
					tooltip: 'Insert a link to this location in chat',
					disabled_reason: 'This location does not allow navigation',
					disabled: street.not_a_destination
				},
				/*
				{
					value: 'path_link',
					street_name: street.name,
					label: 'Create a path link',
					tooltip: 'Insert a path link to this location in chat',
					disabled_reason: 'This location does not allow navigation',
					disabled: street.not_a_destination
				},
				*/
				destination_choice
			];
			
			//check if they have any map teleportation action left
			
			
			/** DEBUGGING
			 pc.teleportation.tokens_remaining = 0;
			 pc.teleportation.map_free_used = 1;
			 pc.teleportation.map_free_max = 10;
			 pc.teleportation.skill_level = 5;
			 pc.stats.energy.value = 1000;
			 TeleportationDialog.instance.cooldown_left = 0;
			 
			 // http://wiki.tinyspeck.com/wiki/TeleportHereVerb
			 
			 //**/
						
			if (pc && pc.teleportation && (pc.teleportation.skill_level >= 4 || (pc.teleportation.skill_level > 0 && pc.teleportation.tokens_remaining > 0))) {
				use namespace client;
				var is_confirm:Boolean;
				var is_disabled:Boolean;
				var disabled_reason:String;
				var tool_tip:String;

				if (street.tsid == model.worldModel.location.tsid) { // not allowed here
					is_disabled = true;
					disabled_reason = 'This is your current location!';
					
				} else if (street.not_a_destination) { // not allowed here
					is_disabled = true;
					disabled_reason = 'This location does not allow teleportation';
					
				} else if (TeleportationDialog.instance.cooldown_left > 0){ // cooldown!
					is_disabled = true;
					disabled_reason = 'Teleportation cooldown active. No teleporting!';
					
				} else if ('pooped' in pc.buffs && !pc.buffs['pooped'].client::removed){ // they pooped?
					is_disabled = true;
					disabled_reason = 'You are too pooped to teleport now';
					
				} else if (!pc.is_dead && hub_tsid == Hub.HELL_TSID){ // they trying to go straight to hell?
					is_disabled = true;
					disabled_reason = 'You must be dead to go here';
					
				} else if (!street.visited && street.tsid != 'LHFIV4V8J6J2I7U'){ // have never been here before (TSID is for the teleportation_rescue_pig quest)
					is_disabled = true;
					disabled_reason = 'You need to visit this location first!';
					
				} else if (pc.teleportation.skill_level >= 4) { // haz skillz
					if (pc.teleportation.map_free_used < pc.teleportation.map_free_max) { // has skill teleports left
						if (pc.stats && pc.stats.energy.value >= pc.teleportation.energy_cost) { // has energy
							/* make more simple from bug #3955, leaving here for a little to see if it has to go back
							tool_tip = 'Travel here instantly. '+pc.teleportation.map_free_used+'/'+pc.teleportation.map_free_max+' map teleports used today. '+
									   'Costs '+pc.teleportation.energy_cost+' energy.';
							*/
							tool_tip = 'Teleport here instantly with a token or energy.';
							is_confirm = true;
						} else { // not enough energy
							if (pc.teleportation.tokens_remaining) {// has tokens
								tool_tip = 'You do not have enough energy to teleport ('+pc.teleportation.energy_cost+' required). Use a token instead?';
								is_confirm = true;
								
							} else { // not enough energy, no tokens
								is_disabled = true;
								disabled_reason = 'You do not have enough energy to teleport ('+pc.teleportation.energy_cost+' required).';
								
							}
						}
					} else if (pc.teleportation.tokens_remaining) { // no skill teleports left, but have tokens
						tool_tip = 'You are out of map teleports for today. Use a token instead?';
						is_confirm = true;
						
					} else { // no skill teleports left, no tokens
						is_disabled = true;
						disabled_reason = 'You are out of map teleports for today.';
						
					}
				} else { // does not have skills, must have tokens to even get here
					if (pc.teleportation.tokens_remaining) {
						tool_tip = 'Travel here instantly. Uses one teleportation token.';
						is_confirm = true;
					} else {
						is_disabled = true;
						disabled_reason = 'You are out of teleportation tokens.';
					}
					
				}
				
				imm.choices.unshift({
					value: 'map_teleport_to',
					label: 'Teleport Here',
					tooltip: tool_tip,
					is_confirm: is_confirm,
					disabled_reason: disabled_reason,
					disabled: is_disabled
				});
			}
			
			//handle the teleportation for gods
			CONFIG::god {
				imm.choices.push({
					value: 'teleport_to',
					label: 'A:Teleport here',
					tooltip: 'As an Admin, you have the unique opportunity to teleport here.',
					disabled_reason: 'This is your current location!',
					disabled: (street.tsid == model.worldModel.location.tsid)
				})
			}
			
			//see if we should should show the info button
			if(!street.not_a_destination && !street.no_info){
				imm.choices.unshift(
					{
						value: InteractionMenuModel.VERB_SPECIAL_LOCATION_INFO,
						label: 'Get information.',
						disabled: false
					}
				);
			}
			
			InteractionMenu.instance.present(street.name || 'Unknown street name', imm.by_click);
		}
		
		public function handleLocationMenuChoice(choice_i:int = -1, by_click:Boolean = false):void {
			
			if (!imm.active_tsid) {
				CONFIG::debugging {
					Console.warn('we are ignoring this because imm.interaction_menu_tsid is empty');
				}
				endInteractionMenu();
				return;
			};
						
			if (choice_i > -1) {
				CONFIG::debugging {
					Console.warn(imm.choices[choice_i].value);
				}
				var choice_value:* = imm.choices[choice_i];
				var chat_area:ChatArea;
				var txt:String = '';
				
				if (choice_value.value == InteractionMenuModel.VERB_SPECIAL_LOCATION_INFO) {
					// TODO, get a betetr URL!
					navigateToURL(new URLRequest(model.flashVarModel.root_url+'locations/'+imm.active_tsid+'/'), URLUtil.getTarget('locationinfo'));
				} else if (choice_value.value == 'teleport_to') {
					if (HubMapDialog.instance.parent) {
						HubMapDialog.instance.end(true);
					}
					CONFIG::god {
						TSFrontController.instance.genericSend(new NetOutgoingAdminTeleportVO(imm.active_tsid));
					}
				} else if (choice_value.value == 'map_teleport_to') {
					//see if we are using a token
					if(choice_value.is_confirm === true){
						var pc:PC = model.worldModel.pc;
						var location:Location = model.worldModel.getLocationByTsid(imm.active_tsid);
						var free_left:int;
						var options:Array = [];
						var disabled_reason:String = '';
						var skill_level:int;
						
						if(pc && pc.teleportation && location){
							free_left = pc.teleportation.map_free_max - pc.teleportation.map_free_used;
							skill_level = pc.teleportation.skill_level;
							
							//text block for the dialog
							if(skill_level >= 4){
								txt += 'You have '+free_left+' map '+(free_left != 1 ? 'teleports' : 'teleport')+' left today. ' +
								  	  (free_left > 0 ? 'Using one will cost '+pc.teleportation.energy_cost+' energy (you have '+pc.stats.energy.value+' right now). ' : '') + 
									  '<font size="2"><br><br></font>';
							}
							
							txt += pc.teleportation.tokens_remaining 
								? 'You can '+(skill_level >= 4 ? 'also ' : '')+'spend a token to teleport to this location: you have used '+
								  pc.teleportation.map_tokens_used+'/'+pc.teleportation.map_tokens_max+
								  ' teleportation tokens today and have a total of '+
								  StringUtil.formatNumberWithCommas(pc.teleportation.tokens_remaining)+' '+
								  (pc.teleportation.tokens_remaining != 1 ? 'tokens' : 'token')+'.'
								: 'You could '+(skill_level >= 4 ? 'also ' : '')+'use a <b><a href="event:'+TSLinkedTextField.LINK_TOKEN_PURCHASE+'|token">' +
								  'teleportation token</a></b>, but you don\'t have any right now.';
							
							//can they use energy?							
							if(pc.teleportation.skill_level >= 4){
								if(free_left < 1){
									disabled_reason = 'You are out of map teleports for today';
								}
								else if (pc.stats.energy.value < pc.teleportation.energy_cost){
									disabled_reason = 'You do not have enough energy to teleport ('+pc.teleportation.energy_cost+' required)';
								}
								
								options.push({value: 'energy', label: 'Spend '+pc.teleportation.energy_cost+' energy to teleport', disabled_reason: disabled_reason});
							}
							
							//can they use a token?
							disabled_reason = '';
							
							if(pc.teleportation.tokens_remaining < 1){
								disabled_reason = 'You are out of teleportation tokens';
							}
							else if(pc.teleportation.map_tokens_used >= pc.teleportation.map_tokens_max){
								disabled_reason = 'You are out of map teleports for today';
							}
							
							options.push({value: 'token', label: 'Use a token', disabled_reason: disabled_reason});
							
							//make sure we have a button to cancel
							options.push({value: false, label: 'Never mind'});
							
							TSFrontController.instance.confirm(
								new ConfirmationDialogVO(
									function(value:*):void {
										if(value !== false) {
											TSFrontController.instance.genericSend(
												new NetOutgoingTeleportationMapVO(location.tsid, value == 'token'), 
												onMapTeleport, 
												onMapTeleport
											);
										}
									},
									txt,
									options,
									false
								)
							);
						}
						//that's not good and should never happen, but we should let them teleport!
						else {
							TSFrontController.instance.genericSend(new NetOutgoingTeleportationMapVO(imm.active_tsid, false), onMapTeleport, onMapTeleport);
						}
					}
					//don't need to confirm, just go
					else {
						TSFrontController.instance.genericSend(new NetOutgoingTeleportationMapVO(imm.active_tsid, false), onMapTeleport, onMapTeleport);
					}
				} else if (choice_value.value == 'make_location_path') {
					
					TSFrontController.instance.genericSend(new NetOutgoingGetPathToLocationVO(imm.active_tsid),
						function(rm:NetResponseMessageVO):void {
							if (!rm.payload.path_info || !rm.payload.path_info.path || rm.payload.path_info.path.length < 2) {
								if(CONFIG::god) {
									//show some more data for the gods
									model.activityModel.growl_message = 'ADMIN ERROR: path did not contain two elements.';
								}
								HubMapDialog.instance.showError('Hmm. This path is only 1 street?! So odd.');
								return;
							}
						},
						function(rm:NetResponseMessageVO):void {
							/*
							/// TESTING SHIT
							
							rm.payload.path_info.path = [];
							if (model.stateModel.loc_pathA.length == 0) {
							rm.payload.path_info.path.push(model.worldModel.location.tsid);
								for (var k:String in model.worldModel.locations) if (k!=model.worldModel.location.tsid) rm.payload.path_info.path.push(k);
								TSFrontController.instance.startLocationPath(rm.payload.path_info.path);
							}
							
							return;
							/// END TESTING SHIT
							*/
							
							HubMapDialog.instance.showError('Hmm. For some reason, I can\'t tell you how to get there from here.');
							
							//show some more data for the gods
							if(CONFIG::god) {
								txt = 'ADMIN: Creating path failed';
								if (rm.payload.error && rm.payload.error.msg) {
									txt+= ': '+rm.payload.error.msg;
								} else {
									txt+= '.';
								}
								model.activityModel.growl_message = txt;
							}
						}
					);
				} else if (choice_value.value == 'path_link'){
					//this is to make a path to the current selected street
					chat_area = RightSideManager.instance.right_view.getChatToFocus();
					chat_area.input_field.setLinkText('Path to '+choice_value.street_name, TSLinkedTextField.LINK_LOCATION_PATH+'|'+imm.active_tsid);
					chat_area.input_field.focusOnInput();
				} else if (choice_value.value is Street && Street(choice_value.value).tsid){
					//we must want to link to this location in chat
					var street:Street = choice_value.value as Street;
					var hub:Hub = model.worldModel.getHubByTsid(street.hub_id);
					
					chat_area = RightSideManager.instance.right_view.getChatToFocus();
					chat_area.input_field.setLinkText(street.name+' in '+hub.label, TSLinkedTextField.LINK_LOCATION+'|'+hub.tsid+'#'+street.tsid);
					chat_area.input_field.focusOnInput();
				}
			}
			
			endInteractionMenu();
		}
		
		public function startPCMenu(pc_tsid:String, type:String, by_click:Boolean = false):void {
			if (model.stateModel.menus_prohibited) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			imm.reset();
			imm.active_tsid = pc_tsid;
			imm.type = type;
			imm.by_click = by_click;
			
			// get the verbs
			TSFrontController.instance.genericSend(
				new NetOutgoingPcVerbMenuVO(pc_tsid),
				pcVerbMenuHandler,
				pcVerbMenuHandler
			);
			
			InteractionMenu.instance.placehold(by_click);
		}
		
		private function pcVerbMenuHandler(rm:NetResponseMessageVO):void {
			if (!imm.active_tsid) {
				CONFIG::debugging {
					Console.warn('we are ignoring this because imm.interaction_menu_tsid is empty');
				}
				return;
			}
			
			if (imm.active_tsid != NetOutgoingPcVerbMenuVO(rm.request).pc_tsid) {
				CONFIG::debugging {
					Console.warn('we are ignoring this because imm.interaction_menu_tsid is different');
				}
				return;
			}
			
			imm.pcmenu = rm.payload.pcmenu;
			
			const pc:PC = model.worldModel.getPCByTsid(imm.active_tsid);
			imm.choices.length = 0;

			/////////////////////////////////////////////////////////////////////////////////////////
			
			var A:Array = imm.choices;
			var you:PC = model.worldModel.pc;
			
			
			// SORTING RULES ARE HERE: http://bugs.tinyspeck.com/3146
			
			if (rm.payload.is_blocked) {
				// nothing
			} else {
				if (pc) {
					
					if (pc.online) {
						var give:Object = {
							label: 'Give Something',
							value: 'give',
							tooltip: 'Choose an item from your pack to give to this person...',
							sort_on: 300
						};
						
						if (you.location.tsid != pc.location.tsid) {
							give.disabled = true;
							give.disabled_reason = 'You must be in the same location!';
						} else if (you.isPackEmpty()) {
							give.disabled = true;
							give.disabled_reason = 'You must have something in your pack to give!';
						} else {
							A.push(give);
						}
						
						var trade:Object = {
							label: 'Offer to Trade',
							value: MessageTypes.TRADE_START,
							disabled: (you.location.tsid != pc.location.tsid),
							disabled_reason: 'You must be in the same location!',
							tooltip: 'Open a trade dialog and offer to make a trade...',
							sort_on: 200
						}
						
						if (you.location.tsid == pc.location.tsid) A.push(trade);
						
						/*
						A.push({
						label: 'View Auctions',
						value: 'view_auctions',
						tooltip: 'View active auctions from this person.'
						});
						*/
						
						A.push({
							label: 'IM',
							value: 'im',
							tooltip: 'Chat with this person directly.',
							sort_on: 9999
						});
						
						A.push({
							label: 'Open Profile Page ...',
							value: 'profile_page',
							tooltip: 'View more information about this person.',
							sort_on: -10
						});
						
						var invite:Object = {
							label: 'Invite to Party',
							value: 'party_invite',
							tooltip: 'Invite this person to a multi-person private chat.',
							sort_on: 101
						};
						if (model.worldModel.party && model.worldModel.getPartyMemberByTsid(pc.tsid)) {
							invite.disabled = true;
							invite.disabled_reason = pc.label+' is already in your party.';
						}
						A.push(invite);
						
						if (pc.tsid == you.following_pc_tsid) {
							A.push({
								label: 'Stop following',
								value: 'follow_end',
								tooltip: 'Stop following this person.',
								sort_on: 900
							});
						} else {
							var follow:Object = {
								label: 'Follow',
								value: 'follow_start',
								tooltip: 'Start following this person.',
								sort_on: 900
							};
							
							if (you.location.tsid != pc.location.tsid) {
								follow.disabled = true;
								follow.disabled_reason = 'You must be in the same location!';
							} else if (you.following_pc_tsid && you.following_pc_tsid != '' && you.following_pc_tsid != null) {
								follow.disabled = true;
								follow.disabled_reason = 'You are already following '+model.worldModel.getPCByTsid(you.following_pc_tsid).label;
							} else {
								A.push(follow);
							}
							
						}
					}
					
				}
				
				if (pc && pc.can_contact && !model.worldModel.location.no_home_street_visiting){
					A.push({
						label: 'Visit Home Street',
						value: 'home_street',
						tooltip: 'Go to the outside of this person\'s house.',
						sort_on: 100
					});
				}
			}
			
			var c:Object;
			if (imm.pcmenu) {
				for (var k:String in imm.pcmenu) {
					c = imm.pcmenu[k];
					c.value = k;
					c.disabled = Boolean(c.disabled); // make sure we have a true boolean value here, FormElememnt depends on it
					c.conditional_verb = true;
					c.sort_on = (c.label.toLowerCase().indexOf('block') > -1) ? 1 : 100;
					A.push(c);
				}
			}
			
			// make sure they all have these props, which we'll sort on
			for (var i:int;i<A.length;i++) {
				if (!A[int(i)].conditional_verb) A[int(i)].conditional_verb = false;
				if (!A[int(i)].god_verb) A[int(i)].god_verb = false;
				if (!A[int(i)].sort_on) A[int(i)].sort_on = 100;
			}
			
			A.sortOn(['god_verb', 'sort_on', 'conditional_verb', 'label'], [Array.NUMERIC | Array.DESCENDING, Array.NUMERIC, Array.NUMERIC | Array.DESCENDING, Array.CASEINSENSITIVE]);
			//A.reverse();
			
			A.unshift({
				label: 'info',
				value: InteractionMenuModel.VERB_SPECIAL_PC_INFO,
				tooltip: 'Get information.'
			});
			
			const title:String = pc ? pc.label : 'Player';
			InteractionMenu.instance.present(title, imm.by_click);
		}
		
		public function startGroupMenu(group_tsid:String, is_active:Boolean, by_click:Boolean = false):void {			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
						
			imm.reset();
			imm.active_tsid = group_tsid;
			imm.type = InteractionMenuModel.TYPE_LIST_GROUP_VERB_MENU;
			imm.by_click = by_click;
			imm.choices = [
				{
					value: 'view',
					label: 'View group page',
					tooltip: 'Opens in a new window'
				}
			];
			
			//open the chat only if we need to
			if(!is_active){
				imm.choices.push(
					{
						value: 'open',
						label: 'Open group chat',
						tooltip: 'Start chat with this group'
					}
				);
			}
			
			const group:Group = model.worldModel.getGroupByTsid(group_tsid);
			const title:String = group ? group.label : 'Group';
			InteractionMenu.instance.present(title, by_click);
		}
		
		public function handleGroupVerbChoice(choice_i:int = -1, by_click:Boolean = false):void {
			if(choice_i >= 0){
				const choice_value:Object = imm.choices[choice_i];
				if(choice_value.value == 'open'){
					RightSideManager.instance.groupStart(imm.active_tsid);
				}
				else if(choice_value.value == 'view'){
					TSFrontController.instance.openGroupsPage(null, imm.active_tsid);
				}
			}
			
			endInteractionMenu();
		}
		
		public function startItemstackMenu(itemstack_tsid:String, type:String, by_click:Boolean = false):void {
			imm.reset();
			imm.active_tsid = itemstack_tsid;
			imm.type = type;
			imm.by_click = by_click;
			
			// get the verbs
			TSFrontController.instance.genericSend(
				new NetOutgoingItemstackVerbMenuVO(itemstack_tsid, true),
				itemstackVerbMenuHandler,
				itemstackVerbMenuHandler
			);
			
			InteractionMenu.instance.placehold(by_click);
		}
		
		public function sortArrayOfItemstacks(A:Array):void {
			A.sortOn(['label'], [Array.CASEINSENSITIVE]);
		}
		
		public function sortArrayOfItems(A:Array):void {
			A.sortOn(['label'], [Array.CASEINSENSITIVE]);
		}
		
		public function handlePCVerbChoice(choice_i:int = -1, by_click:Boolean = false):void {
			if (!imm.active_tsid) {
				CONFIG::debugging {
					Console.warn('we are ignoring this because imm.interaction_menu_tsid is empty');
				}
				endInteractionMenu();
				return;
			};
			
			var pc_tsid:String = imm.active_tsid;
			var cdVO:ConfirmationDialogVO;
			
			if (choice_i > -1) {
				var noivVO:NetOutgoingItemstackVerbVO
				var choice_value:* = imm.choices[choice_i];
				var emote_marker:String = 'emote::';

				if (choice_value.value == InteractionMenuModel.VERB_SPECIAL_PC_INFO) {
					//open the player info dialog
					PlayerInfoDialog.instance.startWithTsid(pc_tsid);

				} else if (choice_value.value == 'give') {
					
					// present TYPE_PC_VERB_TARGET_ITEMSTACK so you can choose from stacks in your pack
					
					imm.by_click = false;
					imm.type = InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK;
					imm.choices.length = 0;
					
					var A:Array = model.worldModel.getPcItemstacksInPackTsidA();
					var choice_itemstack:Itemstack;
					for (var i:int;i<A.length;i++) {
						choice_itemstack = model.worldModel.getItemstackByTsid(A[int(i)]);
						if (!choice_itemstack) continue;
						imm.choices.push(choice_itemstack);
					}
					
					sortArrayOfItemstacks(imm.choices);
					
					imm.choices.push('x');
					
					const pc:PC = model.worldModel.getPCByTsid(pc_tsid);
					const title:String = 'Give '+(pc ? pc.label : 'them')+ ' what?';
					InteractionMenu.instance.present(title);
					return;
					
				} else if (choice_value.value == 'buddy_add') {
					TSFrontController.instance.genericSend(
						new NetOutgoingBuddyAddVO(pc_tsid, 'group1')
					);
					
				} else if (choice_value.value == 'party_invite') {
					TSFrontController.instance.genericSend(
						new NetOutgoingPartyInviteVO(pc_tsid)
					);
					
				} else if (choice_value.value == 'buddy_remove') {
					cdVO = new ConfirmationDialogVO();
					cdVO.callback =	function(value:*):void {
						if (value === true) {
							TSFrontController.instance.genericSend(
								new NetOutgoingBuddyRemoveVO(pc_tsid, 'group1')
							);
						}
					}
					cdVO.txt = 'Are you sure you want to remove this person?'
					cdVO.choices = [
						{value: false, label: 'Never mind'},
						{value: true, label: 'Yes, go ahead and remove them'}
					];
					cdVO.escape_value = false;
					TSFrontController.instance.confirm(cdVO);
					
				} else if (choice_value.value == 'follow_start') {
					TSFrontController.instance.sendFollowStart(
						new NetOutgoingFollowStartVO(pc_tsid)
					);
					
				} else if (choice_value.value == 'follow_end') {
					TSFrontController.instance.sendFollowEnd(
						new NetOutgoingFollowEndVO()
					);
					
				} else if (choice_value.value == 'im') {
					TSFrontController.instance.startIM(pc_tsid);
					
				} else if (choice_value.value == MessageTypes.TRADE_START) {
					TradeManager.instance.player_tsid = pc_tsid;
					TSFrontController.instance.genericSend(new NetOutgoingTradeStartVO(pc_tsid));
					
				} else if (choice_value.value == 'view_auctions') {
					TSFrontController.instance.openAuctionsPage(null, '', pc_tsid);
					
				} else if (choice_value.value == 'home_street') {
					TSFrontController.instance.genericSend(new NetOutgoingHousesVisitVO(pc_tsid));
					
				} else if (choice_value.value == 'profile_page') {
					TSFrontController.instance.openProfilePage(null, pc_tsid);
					
				} else if (choice_value.value.indexOf(emote_marker) == 0) {
					var emoteA:Array = choice_value.value.split('::');
					if (emoteA.length == 3) { 
						var emote_item_tsid:String = emoteA[1];
						var emote_verb:String = emoteA[2];
						
						noivVO = new NetOutgoingItemstackVerbVO(emote_item_tsid, emote_verb, 1);
						noivVO.object_pc_tsid = pc_tsid;
						TSFrontController.instance.sendItemstackVerb(noivVO);
					}
					
				} else {
					if (imm.pcmenu) {
						if (choice_value.value in imm.pcmenu) {
							if (choice_value.requires_confirmation) {
								
								cdVO = new ConfirmationDialogVO();
								var val:* = choice_value.value;
								cdVO.escape_value = false;
								
								cdVO.txt = 'Are you sure you want to ';
								if (choice_value.tooltip) {
									cdVO.txt+= StringUtil.unCapitalizeFirstLetter(choice_value.tooltip)
								} else {
									cdVO.txt+= 'do that';
								}
								cdVO.txt+= '?';
								
								cdVO.callback =	function(value:*):void {
									if (value === 'block') {
										TSFrontController.instance.genericSend(new NetOutgoingPcMenu(pc_tsid, val));
									} else if (value === 'report') {
										TSFrontController.instance.startReportAbuseDialog(pc_tsid);
									}
								}
								
								// report abuse additions
								if (choice_value.value == 'buddy_ignore') {
									cdVO.txt+= ' (You\'ll be given the option of reporting abuse from this player if you do.)';
									cdVO.choices = [
										{value: 'nothing', label: 'Never mind'},
										{value: 'report', label: 'No, just report abuse'},
										{value: 'block', label: 'Yes, I\'m sure'}
									];
									
								} else {
									cdVO.choices = [
										{value: 'nothing', label: 'Never mind'},
										{value: 'block', label: 'Yes, I\'m sure'}
									];
								}
								
								TSFrontController.instance.confirm(cdVO);
							} else {
								TSFrontController.instance.genericSend(new NetOutgoingPcMenu(pc_tsid, choice_value.value));
							}
						}
					}
					//Console.warn('you did this to a pc: '+choice_value.value);
				}
				
			}
			
			endInteractionMenu();
		}
		
		public function startItemstackMenuWithVerb(itemstack:Itemstack, verb:Verb, by_click:Boolean = false):void {
			
			if (!imm.type) {
				sendMenuUp(itemstack.tsid);
			}
			
			imm.reset();
			imm.active_tsid = itemstack.tsid;
			imm.type = InteractionMenuModel.TYPE_IST_VERB_COUNT;
			imm.chosen_verb = verb;
			
			var title:String = '';
			var max_count:int = itemstack.count;
			if (verb.is_client) {
				
				CONFIG::god {
					if (verb.tsid == Item.CLIENT_DESTROY) {
						var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
						cdVO.callback =	function(value:*):void {
							if (value === true) {
								TSFrontController.instance.doClientVerb(itemstack.tsid, verb);
							}
						}
						cdVO.txt = 'Mart thinks this is not a necessary confirmation screen, but do you really want to destroy the <b>'+model.worldModel.getItemByItemstackId(itemstack.tsid).label+'</b>?'
						cdVO.choices = [
							{value: true, label: 'WANT DELETE IT'},
							{value: false, label: 'I am not Mart.'}
						];
						cdVO.escape_value = false;
						
						TSFrontController.instance.confirm(cdVO);
					} else {
						TSFrontController.instance.doClientVerb(itemstack.tsid, verb);
					}
				}
				
				if (!CONFIG::god) TSFrontController.instance.doClientVerb(itemstack.tsid, verb);
				
				TSFrontController.instance.genericSend(
					new NetOutgoingItemstackVerbCancelVO(imm.active_tsid)
				);
				
				endInteractionMenu();
				return;
				
			} else if (verb.requires_target_pc) {
				
				if (!model.worldModel.areYouAloneInLocation()) { 
					imm.active_tsid = itemstack.tsid;
					imm.by_click = false;
					imm.type = InteractionMenuModel.TYPE_IST_VERB_TARGET_PC;
					imm.chosen_verb = verb;
					imm.choices.length = 0;
					
					var choice_pc:PC;
					for (var key:String in model.worldModel.location.pc_tsid_list) {
						if (key == model.worldModel.pc.tsid) continue;
						choice_pc = model.worldModel.getPCByTsid(key);
						if (!choice_pc) continue;
						imm.choices.push(choice_pc);
					}
					
					imm.choices.push('x');
					
					title = '('+StringUtil.capitalizeWords(verb.label)+')' + ' to who?';
					InteractionMenu.instance.present(title);
					return;
				}
				
			} else {
				
				var target_item:Item = (verb.target_item_class) ? model.worldModel.getItemByTsid(verb.target_item_class) : null;
				if (target_item) {
					// the verb supplied a target item!
					startItemstackMenuWithVerbAndTargetItem(itemstack, verb, target_item, null, by_click);
					return;
				}
				
				if (max_count == 1 || verb.is_single || verb.is_all) { // no need to present a count chooser
					
					var send_count:int = (verb.is_all) ? max_count : 1;
					var noivVO:NetOutgoingItemstackVerbVO = new NetOutgoingItemstackVerbVO(itemstack.tsid, verb.tsid, send_count);
					TSFrontController.instance.sendItemstackVerb(noivVO);
					
				} else { // present a count chooser
					
					imm.type = InteractionMenuModel.TYPE_IST_VERB_COUNT;
					imm.default_to_one = imm.default_to_one || verb.default_to_one;
					imm.choices = getCountChoices(max_count, by_click);
					
					var item:Item = model.worldModel.getItemByItemstackId(itemstack.tsid);
					title = StringUtil.capitalizeWords(verb.label)+' how many '+item.label_plural+'?';
					InteractionMenu.instance.present(title, by_click);
					return;
					
				}
				
			}
			
			endInteractionMenu();
			
		}
		
		public function handleItemstackVerbMenuChoice(choice_i:int = -1, by_click:Boolean = false):void {
			if (!imm.active_tsid) {
				CONFIG::debugging {
					Console.warn('we are ignoring this because imm.interaction_menu_tsid is empty');
				}
				endInteractionMenu();
				return;
			};
			
			if (choice_i > -1) {
				
				var choice_value:* = imm.choices[choice_i];
				var item:Item = model.worldModel.getItemByItemstackId(imm.active_tsid);
				var itemstack:Itemstack = model.worldModel.getItemstackByTsid(imm.active_tsid);
				var verb:Verb;
				
				if (choice_value is Verb) {
					
					// HANDLE NORMAL VERBS -----------------------------------------
					
					verb = choice_value;
					
					startItemstackMenuWithVerb(itemstack, verb, by_click);
					
				} else {
					// NOT A VERB WTF -----------------------------------------
					CONFIG::debugging {
						Console.warn('wtf '+choice_value);
					}
					
					endInteractionMenu();
				}
				
			} else {
				TSFrontController.instance.genericSend(
					new NetOutgoingItemstackVerbCancelVO(imm.active_tsid)
				);
				
				endInteractionMenu();
			}
		}
		
		
		public function handlePCVerbTargetItemstackCountChoice(choice_i:int = -1, by_click:Boolean = false):void {
			
			if (!imm.active_tsid) {
				CONFIG::debugging {
					Console.warn('we are ignoring this because imm.interaction_menu_tsid is empty');
				}
				endInteractionMenu();
				return;
			};
			
			if (choice_i > -1) {
				var send_count:int = getCountValueFromChoice(imm.choices[choice_i]);
				
				if (send_count > 0) {
					var noivVO:NetOutgoingItemstackVerbVO = new NetOutgoingItemstackVerbVO(imm.chosen_target_itemstack.tsid, 'give', send_count);
					noivVO.object_pc_tsid = imm.active_tsid;
					
					if ((imm.chosen_target_itemstack.item.is_furniture || imm.chosen_target_itemstack.item.is_special_furniture) && imm.chosen_target_itemstack.furn_upgrade_id != '0')  {
						TSFrontController.instance.confirmFurnitureGive(function(value:*):void {
							if (value == true) {
								TSFrontController.instance.sendItemstackVerb(noivVO);
							}
						});
					} else {
						TSFrontController.instance.sendItemstackVerb(noivVO);
					}
					
				}
			}
			
			endInteractionMenu();
		}
		
		public function startVerbTargetMenuWithVerbAndChoices(itemstack:Itemstack, verb:Verb, choices:Array):void {
			
			if (!imm.type) {
				sendMenuUp(itemstack.tsid);
			}
			
			imm.reset();
			imm.active_tsid = itemstack.tsid;
			imm.chosen_verb = verb;
			var i:int;
			
			if (verb.choices_are_stacks) {
				imm.type = InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEMSTACK;
				
				var choice_stack:Itemstack;
				for (i=0;i<choices.length;i++) {
					choice_stack = model.worldModel.getItemstackByTsid(choices[int(i)]);
					if (!choice_stack) continue;
					imm.choices.push(choice_stack);
				}
				
				sortArrayOfItemstacks(imm.choices);
			} else {
				imm.type = InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM;
				
				var choice_item:Item;
				for (i=0;i<choices.length;i++) {
					choice_item = model.worldModel.getItemByTsid(choices[int(i)]);
					if (!choice_item) continue;
					
					// confirm we have some
					var inv_count:int = model.worldModel.pc.hasHowManyItems(choice_item.tsid);
					if (!verb.include_target_items_from_location) {
						if (!inv_count) continue;
					} else {
						var loc_count:int = model.worldModel.location.hasHowManyItems(choice_item.tsid);
						if (!inv_count && !loc_count) continue;
					}
					
					imm.choices.push(choice_item);
				}
				
				sortArrayOfItems(imm.choices);
			}
			
			imm.choices.push('x');
			
			var title:String = '('+StringUtil.capitalizeWords(verb.label)+')' + ' what?';
			InteractionMenu.instance.present(title);
		}
		
		public function startPcGiveMenuWithItemstack(pc_tsid:String, itemstack:Itemstack, by_click:Boolean = false):void {
			
			const pc:PC = model.worldModel.getPCByTsid(pc_tsid);
			var item:Item = model.worldModel.getItemByItemstackId(itemstack.tsid);
			var max_count:int = itemstack.count;
			
			if (max_count == 1) { // no need to present a count chooser
				
				var noivVO:NetOutgoingItemstackVerbVO = new NetOutgoingItemstackVerbVO(itemstack.tsid, 'give', 1);
				noivVO.object_pc_tsid = pc.tsid;
				TSFrontController.instance.sendItemstackVerb(noivVO);
				endInteractionMenu();
				
			} else { // present a count chooser
				
				// because this method can be called from outside the menu flow, let's make sure we set all of these
				imm.reset();
				imm.active_tsid = pc_tsid;
				imm.by_click = by_click;
				imm.chosen_target_itemstack = itemstack;
				imm.type = InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK_COUNT;
				imm.choices = getCountChoices(max_count, by_click);
				
				const title:String = 'Give how many '+item.label_plural+' to '+pc.label+'?';
				InteractionMenu.instance.present(title, by_click);
				
			}
		}
		
		public function handlePCVerbTargetItemstackChoice(choice_i:int = -1, by_click:Boolean = false):void {
			if (!imm.active_tsid) {
				CONFIG::debugging {
					Console.warn('we are ignoring this because imm.interaction_menu_tsid is empty');
				}
				endInteractionMenu();
				return;
			};
			
			if (choice_i > -1) {
				
				var choice_value:* = imm.choices[choice_i];
				var pc:PC = model.worldModel.getPCByTsid(imm.active_tsid);
				
				if (choice_value is String) {
					endInteractionMenu();
					if (choice_value == 'x') {
						
					} else {
						; // satisfy compiler
						CONFIG::debugging {
							Console.warn('wtf choice_value:'+choice_value)
						}
					}
					
				} else if (choice_value is Itemstack)  {
					
					startPcGiveMenuWithItemstack(pc.tsid, choice_value, by_click);
					return;
					
				}
				
			}
			
			endInteractionMenu();
		}
		
		public function handleItemstackVerbTargetItemChoice(choice_i:int = -1, by_click:Boolean = false):void {
			if (!imm.active_tsid) {
				CONFIG::debugging {
					Console.warn('we are ignoring this because imm.interaction_menu_tsid is empty');
				}
				endInteractionMenu();
				return;
			};
			
			var choice_value:* = imm.choices[choice_i];
			
			if (choice_i > -1) {
				if (choice_value is String) {
					endInteractionMenu();
					CONFIG::debugging {
						if (choice_value != 'x') Console.warn('wtf choice_value:'+choice_value)
					}
					
				} else if (choice_value is Item)  {					
					var chosen_verb:Verb = imm.chosen_verb;
					var target_item:Item = choice_value;
					
					if (target_item) {
						var itemstack:Itemstack = model.worldModel.getItemstackByTsid(imm.active_tsid);
						startItemstackMenuWithVerbAndTargetItem(itemstack, chosen_verb, target_item, null, by_click);
						return;
					}

				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('wtf choice_value is :'+getQualifiedClassName(choice_value));
					}
				}
			}
			
			TSFrontController.instance.genericSend(
				new NetOutgoingItemstackVerbCancelVO(imm.active_tsid)
			);
			
			endInteractionMenu();
		}
		
		public function handleItemstackVerbTargetItemStackChoice(choice_i:int = -1, by_click:Boolean = false):void {
			if (!imm.active_tsid) {
				CONFIG::debugging {
					Console.warn('we are ignoring this because imm.interaction_menu_tsid is empty');
				}
				endInteractionMenu();
				return;
			};
			
			var choice_value:* = imm.choices[choice_i];
			
			if (choice_i > -1) {
				if (choice_value is String) {
					endInteractionMenu();
					CONFIG::debugging {
						if (choice_value != 'x') Console.warn('wtf choice_value:'+choice_value)
					}
					
				} else if (choice_value is Itemstack)  {					
					var chosen_verb:Verb = imm.chosen_verb;
					var target_itemstack:Itemstack = choice_value;
					var target_item:Item = model.worldModel.getItemByTsid(target_itemstack.class_tsid);
					
					if (target_itemstack) {
						var itemstack:Itemstack = model.worldModel.getItemstackByTsid(imm.active_tsid);
						startItemstackMenuWithVerbAndTargetItem(itemstack, chosen_verb, target_item, target_itemstack, by_click);
						return;
					}
					
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('wtf choice_value is :'+getQualifiedClassName(choice_value));
					}
				}
			}
			
			TSFrontController.instance.genericSend(
				new NetOutgoingItemstackVerbCancelVO(imm.active_tsid)
			);
			
			endInteractionMenu();
		}
		
		private var noimu:NetOutgoingItemstackMenuUpVO = new NetOutgoingItemstackMenuUpVO();
		private function sendMenuUp(itemstack_tsid:String):void {
			noimu.itemstack_tsid = itemstack_tsid;
			TSFrontController.instance.genericSend(noimu);
			
			//model.worldModel.registerCBProp(function statusChangeHandler(status:*):void {
			//	Console.warn(status == null)
			//}, "itemstacks", itemstack_tsid, "is_selectable");
			//model.worldModel.unRegisterCBProp(statusChangeHandler, "itemstacks", tsid, "status");
		}
		
		public function startItemstackMenuWithVerbAndTargetItem(itemstack:Itemstack, verb:Verb, target_item:Item, target_itemstack:Itemstack, by_click:Boolean = false):void {
			CONFIG::debugging {
				Console.info('!!!!!!!!!!!!!!!!!!!!!!'+by_click);
			}
			if (!imm.type) {
				sendMenuUp(itemstack.tsid);
			} 
			
			imm.reset();
			imm.active_tsid = itemstack.tsid;
			imm.chosen_verb = verb;
			
			// HMM IN THE CASE OF verb.choices_are_stacks=true, I think the below will break.
			// in that case I think we need to find the number in the stack, not the total number of that class as in pc.hasHowManyItems()
			
			var max_count:int;
			
			if (verb.target_item_class_max_count > -1) {
				max_count = verb.target_item_class_max_count;
			} else {
				if (target_itemstack && model.worldModel.location.itemstack_tsid_list[target_itemstack.tsid]) {
					// it must be a location stack!
					max_count = target_itemstack.count;
				} else {
					if (target_itemstack && verb.limit_target_count_to_stack_count) {
						max_count = target_itemstack.count;
					} else {
						max_count = model.worldModel.pc.hasHowManyItems(target_item.tsid);
						if (verb.include_target_items_from_location) {
							max_count+= model.worldModel.location.hasHowManyItems(target_item.tsid);
						}
						
						if (verb.limit_target_count_to_stackmax) {
							max_count = Math.min(max_count, target_item.stackmax);
						}
					}
				}
			}
			
			var do_special_shrine_dialog:Boolean = verb.tsid == 'donate_to' && itemstack.item.is_shrine && !model.rookModel.rooked_status.rooked;
			
			// if it needs a target count and you have more than one, present TYPE_IST_VERB_TARGET_ITEM_COUNT
			// we assume for tyhe sake of sdbs that if the verb provided the target_item_class, then we shoud
			// prompt with qp even if there is only 1, (same for if limit_target_count_to_stackmax or limit_target_count_to_stack_count)
			
			//if ((verb.requires_target_item_count && max_count>1 || verb.target_item_class) || verb.limit_target_count_to_stack_count || verb.limit_target_count_to_stackmax) {
			if (verb.requires_target_item_count && (do_special_shrine_dialog || max_count>1 || verb.target_item_class || verb.limit_target_count_to_stack_count || verb.limit_target_count_to_stackmax)) {
				imm.chosen_target_item = target_item;
				imm.chosen_target_itemstack = target_itemstack;
				imm.type = InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM_COUNT;
				imm.default_to_one = imm.default_to_one || verb.default_to_one_for_target;
				imm.choices = getCountChoices(max_count, by_click);
				
				if (do_special_shrine_dialog) {
					//set the donate verb so when we fire this back to the server it's all good
					ShrineManager.instance.donate_verb = verb.tsid;
					
					//go ask the server for the details
					ShrineManager.instance.favorRequest(itemstack.tsid, target_item.tsid, true);
					
					endInteractionMenu();
					
				} else {
					var title:String = StringUtil.capitalizeWords(verb.label)+' how many '+target_item.label_plural+'?';
					InteractionMenu.instance.present(title, by_click);
				}
				
				return
			}
			
			// go ahead and submit the verb
			
			var noivVO:NetOutgoingItemstackVerbVO = new NetOutgoingItemstackVerbVO(itemstack.tsid, verb.tsid, 1);
			noivVO.target_item_class = target_item.tsid;
			if (target_itemstack) {
				noivVO.target_itemstack_tsid = target_itemstack.tsid;
			}
			noivVO.target_item_class_count = 1;
			TSFrontController.instance.sendItemstackVerb(noivVO);
			
			endInteractionMenu();
			
		}
		
		public function handleItemstackVerbTargetPCChoice(choice_i:int = -1, by_click:Boolean = false):void {
			if (!imm.active_tsid) {
				CONFIG::debugging {
					Console.warn('we are ignoring this because imm.interaction_menu_tsid is empty');
				}
				endInteractionMenu();
				return;
			};
			
			var choice_value:* = imm.choices[choice_i];
			
			if (choice_i > -1) {
				if (choice_value is String) {
					endInteractionMenu();
					CONFIG::debugging {
						if (choice_value != 'x') Console.warn('wtf choice_value:'+choice_value)
					}
				} else if (choice_value is PC)  {
					
					var chosen_verb:Verb = imm.chosen_verb;
					var target_pc:PC = choice_value;
					
					if (target_pc) {
						var itemstack:Itemstack = model.worldModel.getItemstackByTsid(imm.active_tsid);
						var item:Item = model.worldModel.getItemByItemstackId(imm.active_tsid);
						var max_count:int = model.worldModel.pc.hasHowManyItems(itemstack.class_tsid);
						
						// this is hacky! I need a way to know id the verb should let the player choose all in their pack, or all in their stack!
						if (chosen_verb.tsid == 'give') {
							max_count = itemstack.count;
						}
						
						// if it needs a target count and you have more than one, present TYPE_IST_VERB_COUNT
						
						if (max_count>1 && !chosen_verb.is_single && !chosen_verb.is_all) {
							imm.chosen_target_pc = target_pc;
							imm.type = InteractionMenuModel.TYPE_IST_VERB_COUNT;
							imm.choices = getCountChoices(max_count, by_click);
							
							var title:String = StringUtil.capitalizeWords(chosen_verb.label)+' how many '+item.label_plural+' to '+target_pc.label+'?';
							InteractionMenu.instance.present(title, by_click);
							return
						}
						
						// go ahead and submit the verb
						
						var send_count:int = (chosen_verb.is_all) ? max_count : 1;
						var noivVO:NetOutgoingItemstackVerbVO = new NetOutgoingItemstackVerbVO(itemstack.tsid, chosen_verb.tsid, 1);
						noivVO.object_pc_tsid = target_pc.tsid;
						noivVO.count = send_count;
						TSFrontController.instance.sendItemstackVerb(noivVO);
						
						endInteractionMenu();
						return;
					}
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('wtf choice_value is :'+getQualifiedClassName(choice_value));
					}
				}
			}
			
			TSFrontController.instance.genericSend(
				new NetOutgoingItemstackVerbCancelVO(imm.active_tsid)
			);
			
			endInteractionMenu();
		}
		
		public function handleItemstackVerbTargetItemCountChoice(choice_i:int = -1, by_click:Boolean = false):void {
			if (!imm.active_tsid) {
				CONFIG::debugging {
					Console.warn('we are ignoring this because imm.interaction_menu_tsid is empty');
				}
				endInteractionMenu();
				return;
			};
			
			if (choice_i > -1) {
				
				var itemstack:Itemstack = model.worldModel.getItemstackByTsid(imm.active_tsid);
				var verb:Verb = imm.chosen_verb;
				var send_target_item_count:int = getCountValueFromChoice(imm.choices[choice_i]);
				
				if (send_target_item_count > 0) {
					
					var noivVO:NetOutgoingItemstackVerbVO = new NetOutgoingItemstackVerbVO(itemstack.tsid, verb.tsid, 1);
					noivVO.target_item_class = imm.chosen_target_item.tsid;
					if (imm.chosen_target_itemstack) {
						noivVO.target_itemstack_tsid = imm.chosen_target_itemstack.tsid;
					}
					noivVO.target_item_class_count = send_target_item_count;
					TSFrontController.instance.sendItemstackVerb(noivVO);
					
					endInteractionMenu();
					return;
				}
				
			}
			
			TSFrontController.instance.genericSend(
				new NetOutgoingItemstackVerbCancelVO(imm.active_tsid)
			);
			
			endInteractionMenu();
		}
		
		public function handleItemstackVerbCountChoice(choice_i:int = -1, by_click:Boolean = false):void {
			if (!imm.active_tsid) {
				CONFIG::debugging {
					Console.warn('we are ignoring this because imm.interaction_menu_tsid is empty');
				}
				endInteractionMenu();
				return;
			};
			
			if (choice_i > -1) {
				var itemstack:Itemstack = model.worldModel.getItemstackByTsid(imm.active_tsid);
				var chosen_verb:Verb = imm.chosen_verb;
				var send_count:int = getCountValueFromChoice(imm.choices[choice_i]);
				
				if (send_count > 0) {
					var noivVO:NetOutgoingItemstackVerbVO = new NetOutgoingItemstackVerbVO(itemstack.tsid, chosen_verb.tsid, send_count);
					
					// if this is called after choosing a pc object of the verb, include object_pc_tsid
					if (imm.chosen_target_pc) {
						noivVO.object_pc_tsid = imm.chosen_target_pc.tsid;
					}
					
					TSFrontController.instance.sendItemstackVerb(noivVO);
					
					endInteractionMenu();
					return;
				}
			}
			
			TSFrontController.instance.genericSend(
				new NetOutgoingItemstackVerbCancelVO(imm.active_tsid)
			);
			
			endInteractionMenu();
		}
		
		// to handle the values created in getCountChoices
		private function getCountValueFromChoice(choice:Object):int {
			if (typeof choice == 'object') {
				// it must be special
				return int(choice.value);
			} else {
				// assume it is a number
				return int(choice);
			}
		}
		
		public function startGardenPlotMenu(garden_tsid:String, plot:GardenPlot, actions:Array, by_click:Boolean = false):void {
			imm.reset();
			imm.active_tsid = garden_tsid;
			imm.type = InteractionMenuModel.TYPE_GARDEN_PLANT_SEED;
			imm.by_click = by_click;
			
			//make sure we know what plot we are dealing with
			GardenManager.instance.current_plot_id = plot.plot_id;
						
			//let's see if we have any seeds to plant
			var garden:Garden = model.worldModel.getGardenByTsid(garden_tsid);
			var have_seeds:Array = model.worldModel.pc.hasItemsFromList(
				model.worldModel.getItemTsidsByTags(garden && garden.type != Garden.TYPE_DEFAULT ? garden.type+'_seed' : 'seed')
			);
			var i:int;
			var choice_item:Item;
			
			if(have_seeds.length){				
				for(i; i < have_seeds.length; i++){
					choice_item = model.worldModel.getItemByTsid(have_seeds[int(i)]);
					if (!choice_item) continue;
					imm.choices.push(choice_item);
				}
				
				sortArrayOfItems(imm.choices);
				
				imm.choices.push('x');
				
				InteractionMenu.instance.present('What would you like to plant?');
			}
			
			return;
			//old full menu
			imm.reset();
			imm.active_tsid = garden_tsid;
			imm.type = InteractionMenuModel.TYPE_GARDEN_VERB_MENU;
			imm.by_click = by_click;
			imm.choices = [
				{
					value: GardenAction.WATER,
					label: 'Water',
					tooltip: 'Water makes things grow',
					disabled_reason: 'Enough water already!',
					disabled: (actions.indexOf(GardenAction.WATER) != -1 ? false : true),
					plot_id: plot.plot_id
				},
				{
					value: GardenAction.PLANT,
					label: 'Plant Seeds',
					tooltip: 'Plant some seeds here',
					disabled_reason: 'This plot isn\'t clean!',
					disabled: (actions.indexOf(GardenAction.PLANT) != -1 ? false : true),
					plot_id: plot.plot_id
				},
				{
					value: GardenAction.PICK,
					label: 'Harvest',
					tooltip: 'Snach up those goodies!',
					disabled_reason: 'Nothing to harvest!',
					disabled: (actions.indexOf(GardenAction.PICK) != -1 ? false : true),
					plot_id: plot.plot_id
				},
				{
					value: GardenAction.HOE,
					label: 'Clean',
					tooltip: 'Prepare the plot for seeds',
					disabled_reason: 'The plot isn\'t dirty!',
					disabled: (actions.indexOf(GardenAction.HOE) != -1 ? false : true),
					plot_id: plot.plot_id
				}
			];
			
			InteractionMenu.instance.present(plot.label || 'Unknown plot ', imm.by_click);
		}
		
		public function handleGardenMenuChoice(choice_i:int = -1, by_click:Boolean = false):void {
			if (!imm.active_tsid) {
				CONFIG::debugging {
					Console.warn('we are ignoring this because imm.interaction_menu_tsid is empty');
				}
				endInteractionMenu();
				return;
			};
			
			if (choice_i > -1) {
				//since you can only do 1 thing with gardens, just start editing it!
				var garden_view:GardenView = GardenManager.instance.getGardenView(imm.active_tsid);
				if(garden_view && garden_view.is_owner){
					GardenManager.instance.startEditing(imm.active_tsid);
				}
			}
			
			endInteractionMenu();
		}
		
		public function handleGardenPlantSeedChoice(choice_i:int = -1, by_click:Boolean = false):void {
			if (!imm.active_tsid) {
				CONFIG::debugging {
					Console.warn('we are ignoring this because imm.interaction_menu_tsid is empty');
				}
				endInteractionMenu();
				return;
			};
			
			if (choice_i > -1) {
				var choice_value:* = imm.choices[choice_i];
				
				if(choice_value != 'x'){
					//we have a seed to plant!
					GardenManager.instance.sendAction(imm.active_tsid, GardenManager.instance.current_plot_id, GardenAction.PLANT, Item(choice_value).tsid);
				}
			}
			
			endInteractionMenu();
		}
		
		
		// PRIVATE ------------------------------------------------------------------------------------------------------------------------
		// --------------------------------------------------------------------------------------------------------------------------------
		
		private function endInteractionMenu():void {
			imm.reset();
			InteractionMenu.instance.close();
		}
		
		private function itemstackVerbMenuHandler(rm:NetResponseMessageVO):void {
			if (!imm.active_tsid) {
				CONFIG::debugging {
					Console.warn('we are ignoring this because imm.interaction_menu_tsid is empty');
				}
				return;
			}
			
			if (imm.active_tsid != NetOutgoingItemstackVerbMenuVO(rm.request).itemstack_tsid) {
				CONFIG::debugging {
					Console.warn('we are ignoring this because imm.interaction_menu_tsid is different');
				}
				return;
			}
			
			if (!rm.success) {
				var err_str:String = 'error in itemstack_verb_menu rsp for '+NetOutgoingItemstackVerbMenuVO(rm.request).itemstack_tsid+': ' + 
					((rm.payload.error && rm.payload.error.msg) ? rm.payload.error.msg : 'unknown error');
				CONFIG::debugging {
					Console.error(err_str);
				}
				if (rm.payload.error && 'code' in rm.payload.error && rm.payload.error.code === 0) {
					// could not find stack, like after masing buttonin hell and you get tp ed out but one last itemstack_verb_menu gets out first
				} else {
					BootError.handleError(err_str, new Error('Itemstack Not Found'), null, true);
				}
				endInteractionMenu();
				return;
			}
			
			var item:Item = model.worldModel.getItemByItemstackId(imm.active_tsid);
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(imm.active_tsid);
			
			imm.choices.length = 0;
			var A:Array = imm.choices;
			
			var verb:Verb;
			for (var key:String in item.verbs) {
				verb = item.verbs[key];
				if (verb.requires_target_pc) {
					if (model.worldModel.areYouAloneInLocation()) continue;
				}
				if (verb.is_client) {
					if (verb.tsid == Item.CLIENT_OPEN || verb.tsid == Item.CLIENT_CLOSE) {
						if (!itemstack.slots) continue; // not a container
						if (itemstack.item.is_furniture) continue; // not a real bag!
						if (imm.type != InteractionMenuModel.TYPE_PACK_IST_VERB_MENU) continue; // not a pack menu
						if (PackDisplayManager.instance.opened_container_tsid == itemstack.tsid) { // it is open
							if (verb.tsid == Item.CLIENT_CLOSE) A.push(verb);
						} else {
							if (verb.tsid == Item.CLIENT_OPEN) A.push(verb);
						}
					} else {
						A.push(verb);
					}
				} else if (verb.sort_on >= 50 || verb.sort_on == 0 || CONFIG::god) { // 0 is info verb
					A.push(verb);
				}
			}
			
			A.sortOn(['is_admin', 'enabled', 'sort_on', 'label'], [Array.NUMERIC | Array.DESCENDING, Array.NUMERIC,  Array.NUMERIC, Array.CASEINSENSITIVE]);
			
			var title:String = (itemstack.count == 1) ? itemstack.label : itemstack.count+' '+item.label_plural;
			InteractionMenu.instance.present(title, imm.by_click);
		}
		
		// utility -----------------------------------------------------------------------------------------
		//------------------------------------------------------------------------------------------------------
		private function getCountChoices(max_count:int, by_click:Boolean):Array {
			var countA:Array = [];
			
			// TODO make this a classed object
			var qp_choice:Object = {
				type:'input',
				value:Math.round(max_count/2),
				max_value:max_count,
				show_go_option: by_click && model.flashVarModel.go_in_qp_in_im
			};
			
			if (max_count <= 5) {
				for (var n:int=0;n<max_count-1;n++) countA.push(n+1);
			} else {
				if (model.flashVarModel.qp_in_im && !model.prefsModel.int_menu_more_quantity_buttons) {
					countA = [1, qp_choice];
				} else {
					if (max_count <= 10) {
						countA = [1, 2, 3, 5];
					} else if (max_count <= 20) {
						countA = [1, 3, 5, 10];
					} else if (max_count <= 30) {
						countA = [1, 5, 10, 20];
					} else {
						countA = [1, 10, 20, 30];
					}
				}
				
				if (model.flashVarModel.qp_in_im && model.prefsModel.int_menu_more_quantity_buttons) {
					countA.splice(1, 0, qp_choice);
				}
			}
			
			if (imm.default_to_one) {
				countA.splice(1, 0, max_count); // all second
			} else {
				countA.unshift(max_count); // all at front
			}
			
			countA.push(0); // "none" at end
			
			return countA;
		}

		private function onMapTeleport(nrm:NetResponseMessageVO):void {
			if(nrm.payload.error){
				model.activityModel.activity_message = Activity.createFromCurrentPlayer(nrm.payload.error.msg);
				return;
			}
			
			//close the hub map and giv'r
			if(HubMapDialog.instance.parent) HubMapDialog.instance.end(true);
		}
	}
}
