package com.tinyspeck.engine.view.ui
{
import com.tinyspeck.core.beacon.StageBeacon;
import com.tinyspeck.debug.Console;
import com.tinyspeck.engine.control.TSFrontController;
import com.tinyspeck.engine.data.client.ActionRequest;
import com.tinyspeck.engine.data.client.Activity;
import com.tinyspeck.engine.model.TSModelLocator;
import com.tinyspeck.engine.net.NetOutgoingGetPathToLocationVO;
import com.tinyspeck.engine.net.NetOutgoingLocalChatVO;
import com.tinyspeck.engine.net.NetResponseMessageVO;
import com.tinyspeck.engine.port.ActionRequestManager;
import com.tinyspeck.engine.port.MakingDialog;
import com.tinyspeck.engine.port.PlayerInfoDialog;
import com.tinyspeck.engine.port.QuestsDialog;
import com.tinyspeck.engine.port.RightSideManager;
import com.tinyspeck.engine.port.TeleportationManager;
import com.tinyspeck.engine.port.TradeManager;
import com.tinyspeck.engine.view.gameoverlay.ImgMenuView;
import com.tinyspeck.engine.view.gameoverlay.maps.HubMapDialog;
import com.tinyspeck.engine.view.gameoverlay.maps.MiniMapView;

import flash.events.TextEvent;
import flash.net.URLRequest;
import flash.net.navigateToURL;
import flash.text.TextField;

/**
 * Use this if you need a TextField and will listen for TextEvent.LINK.
 * Sadly required due to bugs in Flex/LocoDeco which cause the links to not work
 * if selectable is false. So this class always sets it to true in dev builds.
 * 
 * Once LD loads, all TSLTFs will become selectable permanently.
 */
public final class TSLinkedTextField extends TextField
{
	CONFIG::locodeco private static var locodecoLoaded:Boolean;
	CONFIG::locodeco private var crappyFlag:Boolean;
	
	public static const LINK_ITEM:String = 'item';
	public static const LINK_SKILL:String = 'skill';
	public static const LINK_PC:String = 'pc';
	public static const LINK_PC_EXTERNAL:String = 'pc_external';
	public static const LINK_QUEST_ACCEPT:String = 'quest_accept';
	public static const LINK_QUEST_HIGHLIGHT:String = 'quest_highlight';
	public static const LINK_GAME_ACCEPT:String = 'game_accept';
	public static const LINK_EXTERNAL:String = 'external';
	public static const LINK_RECIPE:String = 'recipe'; //open making dialog with a specific recipe id
	public static const LINK_LOCATION:String = 'location';
	public static const LINK_LOCATION_PATH:String = 'location_path';
	public static const LINK_PLAYER_INFO:String = 'player_info';
	public static const LINK_TOKEN_PURCHASE:String = 'token_purchase';
	public static const LINK_GROUP:String = 'group'; //open the group page on the website
	public static const LINK_CHAT:String = 'chat'; //open a new chat window
	public static const LINK_TELEPORT:String = 'teleport'; //teleport someplace
	public static const LINK_TRADE:String = 'trade'; //open a trade window with someone
	public static const LINK_CREDIT_PURCHASE:String = 'credit_purchase';
	public static const LINK_SUBSCRIBE:String = 'subscribe';
	public static const LINK_GLITCHR_PHOTO_URL:String = 'glitchr';
	public static const LINK_ADD_TOWER_FLOOR:String = 'link_add_tower_floor';
	public static const LINK_BACK_TO_WORLD:String = 'link_back_to_world';
	public static const LINK_UPGRADE:String = 'upgrade';
	
	private var tsid_chunks:Array;
	
	public function TSLinkedTextField() {
		super();
		addEventListener(TextEvent.LINK, globalLinkHandler, false, 0, true);
		CONFIG::locodeco {
			if (!locodecoLoaded) TSModelLocator.instance.stateModel.registerCBProp(editingChangeHandler, 'editing');
		}
	}
	
	private function globalLinkHandler(e:TextEvent):void {
		var A:Array = e.text.split('|');
		var which:String = A.shift(); // now A no longer contains the which
		var first_value:String = A.length ? A[0] : '';
		var model:TSModelLocator = TSModelLocator.instance;
		
		CONFIG::debugging {
			Console.info(e.text);
		}
		
		// we need this so the tf does not take focus!
		StageBeacon.stage.focus = StageBeacon.stage;
		
		switch(which){
			case LINK_ITEM:
				if(model.worldModel.getItemByTsid(first_value)) {
					TSFrontController.instance.showItemInfo(first_value);
				}
				break;
			
			case LINK_SKILL:
				if(first_value){
					TSFrontController.instance.showSkillInfo(first_value);
				}
				else {
					//open the skill picker
					ImgMenuView.instance.cloud_to_open = Cloud.TYPE_SKILLS;
					ImgMenuView.instance.show();
				}
				break;
			
			case LINK_PC:
				TSFrontController.instance.startPcMenuFromList(first_value);
				break;
			
			case LINK_GAME_ACCEPT:
			case LINK_QUEST_ACCEPT:
				tsid_chunks = first_value.split('#');
				if(tsid_chunks.length < 2){
					CONFIG::debugging {
						Console.warn('tsid param needs to be at least 2 in length');
					}
					break;
				}
				
				//tell the server we are replying
				ActionRequestManager.instance.reply(
					ActionRequest.fromAnonymous({
						player_tsid:name, 
						event_type:which, 
						event_tsid:tsid_chunks[0], 
						uid:tsid_chunks[1]
					})
				);
				
				ActionRequestManager.instance.addRequestUid(tsid_chunks[1]);
				break;
			
			case LINK_EXTERNAL:
				var target:String = (A.length > 1 && A[1]) ? A[1] : '_blank';
				navigateToURL(new URLRequest(first_value), target);
				break;
			
			case LINK_RECIPE:
				MakingDialog.instance.startWithRecipeId(first_value);
				break;
			
			case LINK_LOCATION:
				tsid_chunks = first_value.split('#');
				//for this one, we put the hub tsid and location in the "tsid" chunk
				//eg. location|hub_id#location_tsid
				if(tsid_chunks.length == 2){
					//axe the spaces in the event someone effed up the quest link
					tsid_chunks[0] = String(tsid_chunks[0]).split(' ').join('');
					tsid_chunks[1] = String(tsid_chunks[1]).split(' ').join('');
					HubMapDialog.instance.start();
					HubMapDialog.instance.goToHubFromClick(tsid_chunks[0], tsid_chunks[1], '', true);
				}
					//we were just passed a hub_id, so don't flash the street
				else if(tsid_chunks.length == 1){
					if(tsid_chunks[0] == 'map'){
						//just open the map
						HubMapDialog.instance.start();
					}
					else {
						HubMapDialog.instance.start();
						HubMapDialog.instance.goToHubFromClick(tsid_chunks[0]);
					}
				}
				break;
			
			case LINK_LOCATION_PATH:
				//make sure that they are allowed to get a path
				if(MiniMapView.instance.visible){
					TSFrontController.instance.genericSend(new NetOutgoingGetPathToLocationVO(first_value), onLocationPath, onLocationPath);
				}
				else {
					showError('Your mini map must be visible in order to set a destination');
				}
				break;
			
			case LINK_PLAYER_INFO:
				PlayerInfoDialog.instance.startWithTsid(first_value);
				break;
			
			case LINK_TOKEN_PURCHASE:
				TSFrontController.instance.openTokensPage();
				break;
			
			case LINK_GROUP:
				TSFrontController.instance.openGroupsPage(null, first_value);
				break;
			
			case LINK_CHAT:
				RightSideManager.instance.chatStart(first_value, true);
				break;
			
			case LINK_TELEPORT:
				TeleportationManager.instance.showTeleportConfirmationDialog(first_value);
				break;
			
			case LINK_TRADE:				
				//off to the server you go!
				if(TradeManager.instance.parseTradeLink(first_value)){
					//tell the server we are replying
					ActionRequestManager.instance.reply(
						ActionRequest.fromAnonymous({
							player_tsid:name, 
							event_type:which, 
							event_tsid:first_value
						})
					);
				}
				break;
			
			case LINK_CREDIT_PURCHASE:
				TSFrontController.instance.openCreditsPage();
				break;
			
			case LINK_ADD_TOWER_FLOOR:
				TSFrontController.instance.startTowerFloorExpansion();
				break;
			
			case LINK_SUBSCRIBE:
				TSFrontController.instance.openSubscribePage();
				break;
			
			case LINK_GLITCHR_PHOTO_URL:
				TSFrontController.instance.openSnapPage(null, first_value);
				break;
			
			case LINK_PC_EXTERNAL:
				TSFrontController.instance.openProfilePage(null, first_value);
				break;
			
			case LINK_QUEST_HIGHLIGHT:
				//only open/highlight if it's not already open
				if(!QuestsDialog.instance.parent){
					QuestsDialog.instance.startAndHighlightQuest(first_value);
				}
				break;
			
			case LINK_BACK_TO_WORLD:
				//try to /leave
				TSFrontController.instance.sendLocalChat(new NetOutgoingLocalChatVO('/leave'));
				break;
			
			case LINK_UPGRADE:
				//open the skill picker
				ImgMenuView.instance.cloud_to_open = Cloud.TYPE_UPGRADES;
				ImgMenuView.instance.show();
				break;
			
			default:
				CONFIG::debugging {
				Console.warn('Link type unknown: '+which);
			}
				break;
		}
	}
	
	private function onLocationPath(nrm:NetResponseMessageVO):void {
		if(nrm.payload.error){
			showError(nrm.payload.error.msg);
			return;
		}
		
		//looks good, go ahead and open the map
		//HubMapDialog.instance.start();
	}
	
	private function showError(txt:String):void {
		var model:TSModelLocator = TSModelLocator.instance;
		
		if(model){
			model.activityModel.activity_message = Activity.fromAnonymous({txt: 'Uh oh: '+txt});
			model.activityModel.growl_message = 'Uh oh: '+txt;
		}
	}
	
	CONFIG::locodeco override public function set selectable(val:Boolean):void {
		// links don't work when flex is loaded and selectable = false
		super.selectable = (locodecoLoaded ? true : val);
	}
	
	CONFIG::locodeco private function editingChangeHandler(editing:Boolean):void {
		if (editing && !crappyFlag) {
			crappyFlag = true;
			selectable = true;
			locodecoLoaded = true;
			//TODO this is buggy, so disabling and using a crappy flag
			//TSModelLocator.instance.stateModel.unRegisterCBProp(editingChangeHandler, 'editing');
		}
	}
}
}