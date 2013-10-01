package com.tinyspeck.engine.control
{
	import com.quietless.bitmap.BitmapSnapshot;
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.debug.API;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.LoginTool;
	import com.tinyspeck.debug.NewxpLogger;
	import com.tinyspeck.debug.PerfLogger;
	import com.tinyspeck.engine.api.APICall;
	import com.tinyspeck.engine.control.engine.AnnouncementController;
	import com.tinyspeck.engine.control.mapping.ControllerMap;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.data.client.ScreenViewQueueVO;
	import com.tinyspeck.engine.data.garden.GardenPlot;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.item.Verb;
	import com.tinyspeck.engine.data.item.VerbKeyTrigger;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.Door;
	import com.tinyspeck.engine.data.location.Ladder;
	import com.tinyspeck.engine.data.location.Layer;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.location.LocationConnection;
	import com.tinyspeck.engine.data.location.SignPost;
	import com.tinyspeck.engine.data.map.Street;
	import com.tinyspeck.engine.data.pc.AvatarConfig;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCBuff;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.loader.AvatarConfigRecord;
	import com.tinyspeck.engine.loader.AvatarResourceManager;
	import com.tinyspeck.engine.loader.SmartLoader;
	import com.tinyspeck.engine.model.InteractionMenuModel;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.MoveModel;
	import com.tinyspeck.engine.model.PhysicsModel;
	import com.tinyspeck.engine.model.StateModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingAFKVO;
	import com.tinyspeck.engine.net.NetOutgoingClearLocationPathVO;
	import com.tinyspeck.engine.net.NetOutgoingCultivationModeEndedVO;
	import com.tinyspeck.engine.net.NetOutgoingEditLocationVO;
	import com.tinyspeck.engine.net.NetOutgoingEmoteVO;
	import com.tinyspeck.engine.net.NetOutgoingFollowEndVO;
	import com.tinyspeck.engine.net.NetOutgoingFollowStartVO;
	import com.tinyspeck.engine.net.NetOutgoingGardenActionVO;
	import com.tinyspeck.engine.net.NetOutgoingGetItemAsset;
	import com.tinyspeck.engine.net.NetOutgoingGetItemPlacement;
	import com.tinyspeck.engine.net.NetOutgoingHousesExpandTowerVO;
	import com.tinyspeck.engine.net.NetOutgoingItemstackVerbMenuVO;
	import com.tinyspeck.engine.net.NetOutgoingItemstackVerbVO;
	import com.tinyspeck.engine.net.NetOutgoingLocalChatVO;
	import com.tinyspeck.engine.net.NetOutgoingLocationLockReleaseVO;
	import com.tinyspeck.engine.net.NetOutgoingLocationLockRequestVO;
	import com.tinyspeck.engine.net.NetOutgoingMessageVO;
	import com.tinyspeck.engine.net.NetOutgoingNoEnergyModeVO;
	import com.tinyspeck.engine.net.NetOutgoingPartySpaceJoinVO;
	import com.tinyspeck.engine.net.NetOutgoingPcMenu;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.net.NetServerMessage;
	import com.tinyspeck.engine.net.ServerActionTypes;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.physics.avatar.AvatarPhysicsObject;
	import com.tinyspeck.engine.physics.avatar.PhysicsSetting;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CabinetDialog;
	import com.tinyspeck.engine.port.CabinetManager;
	import com.tinyspeck.engine.port.ChassisManager;
	import com.tinyspeck.engine.port.ConfirmationDialog;
	import com.tinyspeck.engine.port.ConversationManager;
	import com.tinyspeck.engine.port.CultManager;
	import com.tinyspeck.engine.port.Cursor;
	import com.tinyspeck.engine.port.Emotes;
	import com.tinyspeck.engine.port.FamiliarDialog;
	import com.tinyspeck.engine.port.FurnUpgradeDialog;
	import com.tinyspeck.engine.port.GardenManager;
	import com.tinyspeck.engine.port.GetInfoDialog;
	import com.tinyspeck.engine.port.HouseExpandDialog;
	import com.tinyspeck.engine.port.IDisposableSpriteChangeHandler;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.port.IRenderListener;
	import com.tinyspeck.engine.port.InfoManager;
	import com.tinyspeck.engine.port.InputDialog;
	import com.tinyspeck.engine.port.ItemstackConfigDialog;
	import com.tinyspeck.engine.port.JS_interface;
	import com.tinyspeck.engine.port.LocationSelectorDialog;
	import com.tinyspeck.engine.port.MakingDialog;
	import com.tinyspeck.engine.port.QuestManager;
	import com.tinyspeck.engine.port.QuestsDialog;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.port.SendIMToDevDialog;
	import com.tinyspeck.engine.port.StatBurstController;
	import com.tinyspeck.engine.port.TSSprite;
	import com.tinyspeck.engine.port.TimedGrowls;
	import com.tinyspeck.engine.port.TradeManager;
	import com.tinyspeck.engine.port.TrophyCaseDialog;
	import com.tinyspeck.engine.port.TrophyCaseManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.spritesheet.AvatarSSManager;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.GetInfoVO;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.ObjectUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.URLUtil;
	import com.tinyspeck.engine.view.AvatarView;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.LoginProgressView;
	import com.tinyspeck.engine.view.PCView;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.gameoverlay.BuffViewManager;
	import com.tinyspeck.engine.view.gameoverlay.CameraMan;
	import com.tinyspeck.engine.view.gameoverlay.ChoicesDialog;
	import com.tinyspeck.engine.view.gameoverlay.DisconnectedScreenView;
	import com.tinyspeck.engine.view.gameoverlay.GrowlView;
	import com.tinyspeck.engine.view.gameoverlay.ImgMenuView;
	import com.tinyspeck.engine.view.gameoverlay.LoadingLocationView;
	import com.tinyspeck.engine.view.gameoverlay.LocationCheckListView;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.gameoverlay.maps.HubMapDialog;
	import com.tinyspeck.engine.view.gameoverlay.maps.MiniMapView;
	import com.tinyspeck.engine.view.geo.DoorView;
	import com.tinyspeck.engine.view.geo.LadderView;
	import com.tinyspeck.engine.view.geo.SignpostView;
	import com.tinyspeck.engine.view.itemstack.AbstractItemstackView;
	import com.tinyspeck.engine.view.itemstack.FurnitureBagItemstackView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.itemstack.PackItemstackView;
	import com.tinyspeck.engine.view.renderer.DecoRenderer;
	import com.tinyspeck.engine.view.renderer.LargeBitmap;
	import com.tinyspeck.engine.view.renderer.LayerRenderer;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.renderer.commands.LocationCommands;
	import com.tinyspeck.engine.view.renderer.util.AvatarAnimationState;
	import com.tinyspeck.engine.view.ui.ChassisToolbarUI;
	import com.tinyspeck.engine.view.ui.CultToolbarUI;
	import com.tinyspeck.engine.view.ui.InteractionMenu;
	import com.tinyspeck.engine.view.ui.chat.InputField;
	import com.tinyspeck.engine.view.ui.decorate.DecorateToolbarUI;
	import com.tinyspeck.engine.view.ui.garden.GardenView;
	import com.tinyspeck.engine.view.ui.glitchr.GlitchrSavedDialog;
	import com.tinyspeck.engine.view.ui.glitchr.GlitchrSnapshotView;
	import com.tinyspeck.engine.vo.ServerTimeVO;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.System;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import org.osflash.signals.Signal;
	
	CONFIG::debugging { import flash.utils.getQualifiedClassName; }
	CONFIG::god { import com.tinyspeck.engine.admin.HandOfGod; }
	CONFIG::god { import com.tinyspeck.engine.view.gameoverlay.ViewportScaleSliderView; }
	CONFIG::locodeco { import com.tinyspeck.engine.admin.locodeco.LocoDecoSideBar; }
	CONFIG::locodeco { import com.tinyspeck.engine.admin.locodeco.LocoDecoSWFBridge; }
	
	CONFIG const LOC_VP_RECT_COLLISION_SCALE_FOR_SNAPPING:int = 100;
	CONFIG const PRE_SNAP_DELAY:int = 5000;
	
	/**
	 * The TSFrontController acts as a front for the controllers towards the view.
	 * We move away from using a global event dispatcher, and use this instead. 
	 **/
	public class TSFrontController {
		/** Sends true when going afk, false when going not afk */
		public const afk_sig:Signal = new Signal(Boolean);
		
		public static const instance:TSFrontController = new TSFrontController();
		
		//vectors for holding subscribers
		private const moveListenersV:Vector.<IMoveListener> = new Vector.<IMoveListener>();
		private const refreshListenersV:Vector.<IRefreshListener> = new Vector.<IRefreshListener>();
		private const renderListenersV:Vector.<IRenderListener> = new Vector.<IRenderListener>();
		
		private static var model:TSModelLocator;
		
		private var controllerMap:ControllerMap;
		private var api_call:APICall = new APICall();
		private var api_callback:Function;
		
		private var lastMinimapResnap:Number = getTimer();
		private var resnapInterval:uint = 0;
		
		public function TSFrontController() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function setControllerMap(controllerMap:ControllerMap):void {
			this.controllerMap = controllerMap;
			init();
		}
		
		private function init():void {
			model = TSModelLocator.instance;
			if (controllerMap.interactionMenuController) {
				controllerMap.interactionMenuController.init(model);
				InteractionMenu.instance.setController(controllerMap.interactionMenuController);
			}
			
			// tell the class what method to call back to when disposed
			DisposableSprite.onDispose = removeDisposableSprite;
			
			//handle API loads
			api_call.addEventListener(TSEvent.COMPLETE, onAPIComplete, false, 0, true);
			AvatarSSManager.bm_load_fail_sig.add(onAvatarBmLoadFail);
		}
		
		private function onAvatarBmLoadFail():void {
			// alert once
			quickConfirm('We were unable to load some avatar assets, sadly. The problem has been logged, and you needn\'t report any weirdness you might see as a result. Thanks and sorry!', 'Crap!');
			AvatarSSManager.bm_load_fail_sig.remove(onAvatarBmLoadFail);
		}
		
		public function showItemInfo(item_class:String, itemstack_tsid:String=null):void {
			var giVO:GetInfoVO = new GetInfoVO(GetInfoVO.TYPE_ITEM);
			giVO.item_class = item_class;
			giVO.itemstack_tsid = itemstack_tsid;
			model.stateModel.addToGetInfoHistory(giVO);
			GetInfoDialog.instance.showInfo(giVO);
		}
		
		public function showSkillInfo(skill_class:String):void {
			var giVO:GetInfoVO = new GetInfoVO(GetInfoVO.TYPE_SKILL);
			giVO.skill_class = skill_class;
			model.stateModel.addToGetInfoHistory(giVO);
			GetInfoDialog.instance.showInfo(giVO);
		}
		
		public function growl(txt:String):void {
			model.activityModel.growl_message = txt;
		}
		
		public function cleanUpBuffUpdates():void {
			model.worldModel.buff_updates.length = 0;
		}
		
		public function cleanUpBuffAdds():void {
			model.worldModel.buff_adds.length = 0;
		}
		
		public function cleanUpBuffDels():void {
			model.worldModel.buff_dels.length = 0;
		}
		
		public function cleanUpPcUpdates():void {
			var tsids:Array = model.worldModel.loc_pc_updates;
			var pc:PC;
			for (var i:int=0;i<tsids.length;i++) {
				pc = model.worldModel.getPCByTsid(tsids[int(i)]);
				if (!pc) {
					continue;
				}
				pc.last_game_flag_sig = pc.game_flag_sig;
			}
			model.worldModel.loc_pc_updates.length = 0;
		}
		
		public function cleanUpPcAdds():void {
			model.worldModel.loc_pc_adds.length = 0;
		}
		
		public function cleanUpPcDels():void {
			model.worldModel.loc_pc_dels.length = 0;
		}
		
		public function cleanUpLocItemstackUpdates():void {
			model.worldModel.loc_itemstack_updates.length = 0;
		}
		
		public function cleanUpLocItemstackAdds():void {
			model.worldModel.loc_itemstack_adds.length = 0;
		}
		
		public function cleanUpLocItemstackDels():void {
			model.worldModel.loc_itemstack_dels.length = 0;
		}
		
		public function cleanUpPcItemstackUpdates():void {
			model.worldModel.pc_itemstack_updates.length = 0;
		}
		
		public function cleanUpPcItemstackAdds():void {
			model.worldModel.pc_itemstack_adds.length = 0;
		}
		
		public function cleanUpPcItemstackDels():void {
			model.worldModel.pc_itemstack_dels.length = 0;
		}
		
		public function simulateGSRequestingAReconnect():void {
			var sm:NetServerMessage = new NetServerMessage();
			sm.action = ServerActionTypes.CLOSE;
			sm.msg = 'CONNECT_TO_ANOTHER_SERVER';
			controllerMap.netController.netServerMessageHandler(sm);
		}
		
		public function getSocketReadReport():String {
			return controllerMap.netController.netDelegate.socketReport();
		}
		
		public function simulateIncomingMsg(obj:Object, logit:Boolean=false):void {
			controllerMap.netController.netDelegate.parseIncomingMessage(obj, logit);
		}
		
		public function fakeMovingAStackFromPlayerToLocation(itemstack:Itemstack, x:int, y:int):void {
			var fake_msg:Object = {
				"type": "location_event",
				"changes": {
					"location_tsid": model.worldModel.location.tsid,
					"itemstack_values": {
						"location": {},
						"pc": {}
					}
				}
			}
			fake_msg.changes.itemstack_values.location[itemstack.tsid] = {
				"x": x,
				"y": y,
				"count": 1,
				"path_tsid": itemstack.tsid
			}
			fake_msg.changes.itemstack_values.pc[itemstack.tsid] = {
				"path_tsid": itemstack.path_tsid,
				"count": 0,
				"class_tsid": "DELETED"
			}
			simulateIncomingMsg(fake_msg);
		}
		
		public function fakeMovingAStackFromLocationToPlayer(itemstack:Itemstack, path_tsid:String, x:int, y:int):void {
			var fake_msg:Object = {
				"type": "location_event",
				"changes": {
				"location_tsid": model.worldModel.location.tsid,
					"itemstack_values": {
						"location": {},
						"pc": {}
					}
				}
			}
			fake_msg.changes.itemstack_values.location[itemstack.tsid] = {
				"path_tsid": itemstack.tsid,
				"count": 0,
				"class_tsid": "DELETED"
			}
			fake_msg.changes.itemstack_values.pc[itemstack.tsid] = {
				"path_tsid": path_tsid,
				"count": 1,
				"x": x,
				"y": y
			}
			simulateIncomingMsg(fake_msg);
		}
		
		public function sendAnonMsg(msg:Object):void {
			controllerMap.netController.sendAnonMsg(msg);
		}
		
		CONFIG::god public function testUnexpectedDisconnect():void {
			controllerMap.netController.testUnexpectedDisconnect();
		}
		
		public function sendLocalChat(vo:NetOutgoingLocalChatVO = null, callBackSuccess:Function = null, callBackFailure:Function = null):void {
			// if we are in local chat and not manually invoking afk status, wake us up
			if (vo.txt != Emotes.AFK) goNotAFK();
			controllerMap.netController.genericSend(vo,callBackSuccess,callBackFailure);
		}
		
		public function sendItemstackVerb(vo:NetOutgoingItemstackVerbVO = null, callBackSuccess:Function = null, callBackFailure:Function = null, confirmed:Boolean=false):void {
			var itemstack:Itemstack = Itemstack(model.worldModel.getItemstackByTsid(vo.itemstack_tsid));
			if (itemstack) {
				
				NewxpLogger.log('verb_'+vo.verb, itemstack.tsid+' '+itemstack.class_tsid);
			
				// CONFIRM WITH USER WHEN GIVING FURNITURE
				if (!confirmed && (itemstack.item.is_furniture || itemstack.item.is_special_furniture) && itemstack.furn_upgrade_id != '0' && vo.verb == 'give') {
					confirmFurnitureGive(function(value:*):void {
						if (value == true) {
							sendItemstackVerb(vo, callBackSuccess, callBackFailure, true)
						}
					});
					return;
				}
				
				itemstack.waiting_on_verb = true;
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('no itemstack for '+vo.itemstack_tsid);
				}
			}
			//Console.warn('waiting: '+vo.itemstack_tsid);
			
			vo.check_for_proximity = model.flashVarModel.check_for_proximity;
			
			controllerMap.netController.genericSend(vo, function(rm:NetResponseMessageVO):void {
				//Console.warn('NOT waiting: '+NetOutgoingItemstackVerbVO(rm.request).itemstack_tsid);
				var itemstack:Itemstack = Itemstack(model.worldModel.getItemstackByTsid(NetOutgoingItemstackVerbVO(rm.request).itemstack_tsid));
				if (itemstack) itemstack.waiting_on_verb = false;
				if (callBackSuccess is Function && callBackSuccess != itemstackVerbHandler) callBackSuccess(rm);
				itemstackVerbHandler(rm);
			}, function(rm:NetResponseMessageVO):void {
				//Console.warn('NOT waiting: '+NetOutgoingItemstackVerbVO(rm.request).itemstack_tsid);
				var itemstack:Itemstack = Itemstack(model.worldModel.getItemstackByTsid(NetOutgoingItemstackVerbVO(rm.request).itemstack_tsid));
				if (itemstack) itemstack.waiting_on_verb = false;
				if (callBackFailure is Function && callBackFailure != itemstackVerbHandler) callBackFailure(rm);
				itemstackVerbHandler(rm);
			});
		}
		
		public function moveCloserForVerbOrAction(noVO:Object, action:String, error:Object):void {
			// the error message will tell us how close we have to be
			try {
				model.physicsModel.required_verb_proximity = error.msg.split(':')[1];
			} catch (err:Error) {
				CONFIG::debugging {
					Console.error('Could not retrieve required_verb_proximity from: '+error.msg)
				}
			}			

			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(noVO.itemstack_tsid);
			var liv:LocationItemstackView = getMainView().gameRenderer.getItemstackViewByTsid(noVO.itemstack_tsid);
			if (liv) {
				showMoveCloserNotice('Moving you in order to "'+action+'"', 'get_closer');
				moveAvatarToLIVandDoVerbOrAction(liv, noVO, false);
			} else {
				CONFIG::debugging {
					Console.info('no liv');
				}
			}
		}
		
		public function quickConfirm(txt:String, title:String=null, callback:Function=null):void {
			const cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
			cdVO.callback = callback
			cdVO.title = title || 'Alert';
			cdVO.txt = txt;
			cdVO.choices = [
				{value: true,  label: "OK!"}
			];
			cdVO.escape_value = true;
			confirm(cdVO);
		}
		
		public function confirmFurnitureGive(callback:Function):void {
			const cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
			cdVO.callback = callback
			cdVO.title = 'Give this piece of furniture?';
			cdVO.txt = "This furniture item has been upgraded. The upgrade is part of the furniture: if you give it someone else, the new owner will have the item and its upgrade and you won't. Is that ok?";
			cdVO.choices = [
				{value: true,  label: "Yes!"},
				{value: false, label: "No!"}
			];
			cdVO.escape_value = false;
			confirm(cdVO);
		}
		
		public function confirmFurnitureTrade(callback:Function):void {
			const cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
			cdVO.callback = callback
			cdVO.title = 'Trade this piece of furniture?';
			cdVO.txt = "This furniture item has been upgraded. The upgrade is part of the furniture: if you trade it, the new owner will have the item and its upgrade and you won't. Is that ok?";
			cdVO.choices = [
				{value: true,  label: "Yes!"},
				{value: false, label: "No!"}
			];
			cdVO.escape_value = false;
			confirm(cdVO);
		}
		
		private function itemstackVerbHandler(rm:NetResponseMessageVO):void {
			//Console.warn('itemstackVerbHandler')
			var noivVO:NetOutgoingItemstackVerbVO = rm.request as NetOutgoingItemstackVerbVO;
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(noivVO.itemstack_tsid);
			CONFIG::debugging {
				if (!itemstack) Console.warn('no stack');
			}
			
			if (itemstack && itemstack.item && itemstack.item.verbs) {
				var verb:Verb = itemstack.item.verbs[noivVO.verb];
				// arguably, we should get the verb def back in the rersponse message
				if (!verb) {
					// it is possible we won't have these yet, and that is not an error condition
					if (noivVO.verb != 'drop' && noivVO.verb != 'pickup' && noivVO.verb != 'give') {
						; // satisfy compiler
						CONFIG::debugging {
							Console.error('verb '+noivVO.verb+' not found on item '+itemstack.item.tsid)
						}
						return;
					}
				}	
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('don\'t know what to do (no item or no verbs) with the choices for verb '+noivVO.verb);
				}
				return;
			}	
			
			if (rm.success) {
				if (rm.payload.choices && rm.payload.choices.length && verb) {
					
					var iv:AbstractItemstackView = getMainView().gameRenderer.getItemstackViewByTsid(itemstack.tsid) as AbstractItemstackView;
					if (!iv) iv = getMainView().pdm.getItemstackViewByTsid(itemstack.tsid) as AbstractItemstackView;
					if (!iv) return;
					
					if (verb.requires_target_item) {
						controllerMap.interactionMenuController.startVerbTargetMenuWithVerbAndChoices(itemstack, verb, rm.payload.choices);
					} else {
						; // satisfy compiler
						CONFIG::debugging {
							Console.warn('don\'t know what to do (verb does not requires_target_item) with the choices for verb '+noivVO.verb);
						}
					}
				}
				//Console.warn('you did it');
			} else {
				if (rm.payload && rm.payload.error && rm.payload.error.code == '101') {
					// move the player closer, then resubmit
					moveCloserForVerbOrAction(noivVO, (verb) ? verb.label : noivVO.verb, rm.payload.error);
					return;
				}
				
				//SoundMaster.instance.playSound('CLICK_FAILURE');
				//{"msg_id":"3","success":false,"error":{"code":0,"msg":"item stack is too far away"},"type":"itemstack_verb"}
				var txt:String = '<b>Well that didn\'t work!</b>';
				
				if (rm.payload && rm.payload.error && rm.payload.error.hasOwnProperty('code')) {
					//txt+= ' Error: ('+rm.payload.error.code+')';
					if (rm.payload.error.hasOwnProperty('msg')) txt+= ' '+rm.payload.error.msg
					
					CONFIG::god {
						growl('A/D: Error #'+rm.payload.error.code);
					}
				} else {
					txt+= 'Reasons unknown.';
				}
				growl(txt);
			}
		}
		
		public function checkSentMessagesAfterReconnection():void {
			CONFIG::god {
				var str:String = '';
				var nom:NetOutgoingMessageVO;
				for (var k:Object in model.netModel.sentMessages) {
					nom =  model.netModel.sentMessages[k];
					
					// ignore some messages
					if (nom.type.indexOf('login_start') != -1) continue;
					if (nom.type.indexOf('login_end') != -1) continue;
					if (nom.type.indexOf('move_start') != -1) continue;
					if (nom.type.indexOf('move_end') != -1) continue;
					
					str += nom.type+':'+nom.msg_id+' has no rsp, '+(getTimer()-nom.time_sent)+'ms after sent\r';
				}
				
				if (str) {
					str = 'ADMIN: After a reconnect, these messages are still waiting for a response:\r'+str;
					growl(str);
				}
			}
		}
		
		public function rollingRestartStarting():void {
		}
		
		public function doVerbOrActionAfterPath(itemstack_tsid:String, verb_or_action:Object):void {
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(itemstack_tsid);
			if (!itemstack) {
				CONFIG::debugging {
					Console.error('wtf');
				}
				return;
			}
			
			if (verb_or_action is String) {
				doVerb(itemstack_tsid, verb_or_action as String);
				return;
			}
			
			var x_dist:Number = Math.abs(itemstack.x - model.worldModel.pc.x);
			var y_dist:Number = Math.abs(itemstack.y - model.worldModel.pc.y);
			var dist:Number = Math.sqrt((x_dist*x_dist)+(y_dist*y_dist));
			CONFIG::debugging {
				Console.info('dist:'+dist+' > required_verb_proximity:'+model.physicsModel.required_verb_proximity+' x_dist:'+x_dist+' pc.x:'+model.worldModel.pc.x);
			}

			if (verb_or_action is NetOutgoingItemstackVerbVO || verb_or_action is NetOutgoingGardenActionVO) {
				
				if (dist <= model.physicsModel.required_verb_proximity) {
					// make sure the GS knows our position!!
					controllerMap.netController.maybeSendMoveXY();
					
					if (verb_or_action is NetOutgoingItemstackVerbVO) {
						sendItemstackVerb(
							verb_or_action as NetOutgoingItemstackVerbVO
						);
						
					} else if (verb_or_action is NetOutgoingGardenActionVO) {
						GardenManager.instance.sendActionMsg(
							verb_or_action as NetOutgoingGardenActionVO
						);
					}
				} else {
					showMoveCloserNotice('Could not get close enough :(', 'get_closer_failed', 3000);
				}
				
				return;
			} else if (verb_or_action is Function) {
				if (dist <= model.physicsModel.required_verb_proximity) {
					// make sure the GS knows our position!!
					controllerMap.netController.maybeSendMoveXY();
					verb_or_action();
				} else {
					model.activityModel.god_message = 'Could not get close enough :(';
				}
				
				return;
			}

			; // satisfy compiler
			CONFIG::debugging {
				Console.error('verb is what??? '+getQualifiedClassName(verb_or_action));
			}
		}
		
		public function showMoveCloserNotice(txt:String, uid:String, duration:int=0):void {
			growl(txt);
			return;
			model.activityModel.announcements = Announcement.parseMultiple([{
				type: "vp_overlay",
				dismissible: false,
				locking: false,
				click_to_advance: false,
				text: ['<p align="center"><span class="nuxp_vog_small">'+txt+'</span></p>'],
				x: '50%',
				y: 60,
				delay_ms: 0,
				duration: duration,
				width: 500,
				uid: uid,
				bubble_god: true
			}]);
		}
		
		public function doVerb(itemstack_tsid:String, verb_tsid:String):void {
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(itemstack_tsid);
			if (!itemstack) {
				return;
			}
			
			var verb:Verb = itemstack.item.getVerbByTsid(verb_tsid);
			if (verb && verb.is_client) {
				doClientVerb(itemstack.tsid, verb);
				return;
			}
			
			sendItemstackVerb(
				new NetOutgoingItemstackVerbVO(itemstack.tsid, verb_tsid, 1)
			);
		}
		
		public function doClientVerb(itemstack_tsid:String, verb:Verb):void {
			
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(itemstack_tsid);
			
			switch (verb.tsid) {
				case Item.CLIENT_INFO:
					showItemInfo(itemstack.info_class, itemstack_tsid);
					break;
				
				case Item.CLIENT_OPEN:
				case Item.CLIENT_CLOSE:
					togglePackContainer(itemstack_tsid);
					break;
				
				case Item.CLIENT_DESTROY:
					CONFIG::god {
						sendLocalChat(
							new NetOutgoingLocalChatVO('/kill stack '+itemstack_tsid)
						);
					};
					break;
				
				case Item.CLIENT_COPY_TSID:
					CONFIG::god {
						System.setClipboard(itemstack_tsid);
					};
					break;
				
				case Item.CLIENT_COPY_CLASS:
					CONFIG::god {
						System.setClipboard(itemstack.class_tsid);
					};
					break;
				
				case Item.CLIENT_EDIT_PROPS:
					CONFIG::god {
						JS_interface.instance.call_JS({
							meth: 'open_window',
							params: {
								name: 'prop_editor',
								url: model.flashVarModel.root_url+'god/item_instance.php?tsid='+itemstack_tsid
							}
						});
					};
					break;
				
				case Item.CLIENT_EDIT_ITEM:
					CONFIG::god {
						navigateToURL(new URLRequest(model.flashVarModel.root_url+'god/item.php?class='+itemstack.class_tsid), URLUtil.getTarget(itemstack.class_tsid));
					};
					break;
			}
		}
		
		public function sendLogoutAtWindowClose():void {
			RightSideManager.instance.saveOpenChats();
			LocalStorage.instance.flushIt(0, 'sendLogoutAtWindowClose');
			model.netModel.should_reconnect = false;
			controllerMap.netController.sendLogout();
			NewxpLogger.log('window_unload');
		}
		
		public function initTimeController():void {
			controllerMap.timeController.init();
		}
		
		public function startTimeController(vo:ServerTimeVO = null, callBackSuccess:Function = null, callBackFailure:Function = null):void {
			controllerMap.timeController.start(vo.time);
		}
		
		public function loadItemstackSWF(item_class:String, url:String, callBackSuccess:Function = null, callBackFailure:Function = null):SmartLoader {
			return controllerMap.dataLoaderController.loadItemstackSWF(item_class, url, callBackSuccess, callBackFailure);
		}
		
		public function sendFollowStart(vo:NetOutgoingFollowStartVO, callBackSuccess:Function = null, callBackFailure:Function = null):void {
			instance.controllerMap.netController.genericSend(vo, callBackSuccess, callBackFailure);
			model.worldModel.pc.following_pc_tsid = vo.pc_tsid;
		}
		
		public function sendFollowEnd(vo:NetOutgoingFollowEndVO):void {
			instance.controllerMap.netController.genericSend(vo);
			model.worldModel.pc.following_pc_tsid = '';
		}
		
		public function genericSend(nomVO:NetOutgoingMessageVO, successHandler:Function = null, failureHandler:Function = null):void {
			instance.controllerMap.netController.genericSend(nomVO, successHandler, failureHandler);
		}
		
		public function maybeSendMoveVec(apo:AvatarPhysicsObject,s:String):void {
			controllerMap.netController.maybeSendMoveVec(apo, s);
		}
		
		private var login_unacceptable_tim:uint;
		public function startLoginTracking():void {
			login_unacceptable_tim = StageBeacon.setTimeout(afterUnacceptableSecondsWaitingForLoginStart, 20000);
		}
		
		public function endLoginProgressDisplay():void {
			if (!LoginTool.reportStep(11, 'tsfc_ending_login_screen')) return;
			Benchmark.addCheck('TSFC.endLoginProgressDisplay');
			StageBeacon.clearTimeout(login_unacceptable_tim);

			TSTweener.removeTweens(LoginProgressView.instance);
			TSTweener.addTween(LoginProgressView.instance, {alpha:0, time:1, onComplete:function():void {
				if (LoginProgressView.instance.parent) {
					LoginProgressView.instance.parent.removeChild(LoginProgressView.instance);
				}
				RightSideManager.instance.right_view.visible = true;
				controllerMap.netController.doLoginStartHandlerAfterLoading();
			}});
		}
		
		public function startLocationMove(relogin:Boolean, move_type:String, from_tsid:String = '', to_tsid:String = '', signpost_index:String = '', hostport:String = '', token:String = '', delay_loading_screen_ms:int = 0):void {			
			if (!LoginTool.reportStep(8, 'tsfc_starting_move')) return;

			CONFIG::god {
				if (hostport && EnvironmentUtil.getURLAndQSArgs().args['fake_error'] == 1) {
					growl('ADMIN: sending fake thing');
					genericSend(
						new NetOutgoingPcMenu('fake', 'thing'), function():void {
							growl('ADMIN: received faked thing rsp');
						}, function():void {
							growl('ADMIN: received faked thing rsp');
						}
					);
				}
			}
			
			CONFIG::god {
				if (model.stateModel.loc_saved_but_not_snapped) {
					// reset this now, so we don't ask again
					model.stateModel.loc_saved_but_not_snapped = false;
					const cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
					cdVO.callback = function(value:*):void {
						if (value == true) {
							// resnap first
							saveLocationLoadingImg(false, function():void {
								startLocationMove(relogin, move_type, from_tsid, to_tsid, signpost_index, hostport, token, delay_loading_screen_ms);
							});
						} else {
							// move on little doggy
							startLocationMove(relogin, move_type, from_tsid, to_tsid, signpost_index, hostport, token, delay_loading_screen_ms);
						}
					}
					cdVO.title = 'Resnap?'
					cdVO.txt = "Sir/Madam, may I resnap this location before you go? (Monsieur/Madame, puis-je prendre un instantané avant de partir?)";
					cdVO.choices = [
						{value: true,  label: "Thanks, Jeevesy, old boy. (Oui, merci, Jeeves.)"},
						{value: false, label: "I'm late! (Je suis en retard!)"}
					];
					cdVO.escape_value = false;
					confirm(cdVO);
					return;
				}
			}
			
			instance.controllerMap.netController.actuallyStartLocationMove(relogin,move_type,from_tsid,to_tsid,signpost_index,hostport,token,delay_loading_screen_ms);
		}
	
		public function sendEndMoveMsg():void {
			instance.controllerMap.netController.sendEndMoveMsg();
		}
		
		private function doneLoadingUsersAvatarAssets():void {
			Benchmark.addCheck('TSFC.doneLoadingUsersAvatarAssets');
			addPackStacks();
		}
		
		private function addPackStacks():void {
			Benchmark.startSection(Benchmark.SECTION_ADDING_PACK_STACKS);
			var pdm:PackDisplayManager = controllerMap.viewController.tsMainView.pdm;
			pdm.addPISViews();
			controllerMap.viewController.tsMainView.refreshViews();
			// pdm will call doneLoadingPack(); when it is all loaded, which will then do whatever other pre loading we want, and
			// eventually endMoving(); will get called!
		}
		
		public function brushFox(fox_tsid:String, brush_tsid:String):void {
			var pt:Point = getMainView().gameRenderer.getMouseXYinMiddleground();
			var swf_url:String = model.stateModel.overlay_urls['fox_brush'];
			model.activityModel.announcements = Announcement.parseMultiple([{
				type: 'location_overlay',
				item_class: 'fox_brush',
				state: (brush_tsid) ? 'hit' : 'miss', // if a brush tsid was passed, we hit
				x: pt.x,
				y: pt.y,
				duration: 3000,
				at_top:true,
				uid: 'fox_brushing'
			}]);
			
			// make sure there was a fox at all before doing this!
			if (fox_tsid) {
				//myles: 	eric, maybe just submit the verb without target_itemstack_tsid if you miss?
				var noivVO:NetOutgoingItemstackVerbVO = new NetOutgoingItemstackVerbVO(fox_tsid, 'brush', 1, brush_tsid);
				noivVO.target_item_class_count = 1;
				noivVO.drop_x = pt.x;
				noivVO.drop_y = pt.y;
				sendItemstackVerb(noivVO);
			}
		}
		
		public function doneLoadingPack():void {
			Benchmark.addCheck('TSFC.doneLoadingPack');
			getMainView().pdm.visible = true;
			sendEndMoveMsg();
		}
		
		private var missing_asset_item_to_call_back_map:Dictionary = new Dictionary();
		public function getItemMissingAsset(item_class:String, callback:Function):void {
			var map:Dictionary = missing_asset_item_to_call_back_map;
			var item:Item = model.worldModel.getItemByTsid(item_class);
			
			if (item.has_fetched_missing_asset) {
				callback();
			} else if (item.is_fetching_missing_asset) {
				map[item_class].push(callback);
			} else {
				map[item_class] = [callback];
				item.is_fetching_missing_asset = true;
				genericSend(new NetOutgoingGetItemAsset(item_class), onNetOutgoingGetItemAssetStrVO);
			}
		}
		
		private function onNetOutgoingGetItemAssetStrVO(rm:NetResponseMessageVO):void {
			// NetController will have updated the model
			var map:Dictionary = missing_asset_item_to_call_back_map;
			var item:Item = model.worldModel.getItemByTsid(rm.payload.item_class);
			var A:Array = map[item.tsid];
			var callback:Function;
			var i:int;
			if (A) {
				for (i=0;i<A.length;i++) {
					if (!(A[i] is Function)) continue; 
					callback = A[i] as Function;
					callback();
				}
				
				A.length = 0;
			}
			delete map[item.tsid]
		}
		
		private var missing_placement_item_to_call_back_map:Dictionary = new Dictionary();
		public function getItemPlacement(item_class:String, callback:Function):void {
			var map:Dictionary = missing_placement_item_to_call_back_map;
			var item:Item = model.worldModel.getItemByTsid(item_class);
			
			if (item.has_fetched_missing_asset || item.has_fetched_placement) {
				callback();
			} else if (item.is_fetching_missing_asset) {
				missing_asset_item_to_call_back_map[item_class].push(callback);
			} else if (item.is_fetching_placement) {
				map[item_class].push(callback);
			} else {
				map[item_class] = [callback];
				item.is_fetching_placement = true;
				genericSend(new NetOutgoingGetItemPlacement(item_class), onNetOutgoingGetItemPlacementStrVO);
			}
		}
		
		private function onNetOutgoingGetItemPlacementStrVO(rm:NetResponseMessageVO):void {
			// NetController will have updated the model
			var map:Dictionary = missing_placement_item_to_call_back_map;
			var item:Item = model.worldModel.getItemByTsid(rm.payload.item_class);
			var A:Array = map[item.tsid];
			var callback:Function;
			var i:int;
			if (A) {
				for (i=0;i<A.length;i++) {
					if (!(A[i] is Function)) continue; 
					callback = A[i] as Function;
					callback();
				}
				
				A.length = 0;
			}
			delete map[item.tsid]
		}
		
		public function preloadYourAva():void {
			// if we are doing the default normal using sheets for avatars thing, this function does nothing!
			if (AvatarSSManager.load_ava_sheets_pngs) {
				doneLoadingUsersAvatarAssets();
				return;
			}
			
			// now load the user's avatar assets
			var acr:AvatarConfigRecord = AvatarResourceManager.instance.getAvatarConfigRecord(model.worldModel.pc.ac, (model.worldModel.pc.ac.acr)?model.worldModel.pc.ac.acr.ava_swf:null);
			if (!acr.ready) {
				startLoadingLocationProgress('almost done...');
				
				// O0O baby this is kind of hacked up to provide loading progress from the initial avatar asset loading
				
				var reset_next_time:Boolean = false;
				var resets:int = 0;
				var progressFunc:Function = function(perc:Number):void {
					if (reset_next_time) {
						resets++;
						var rly:Array = [];
						var rly_str:String = '';
						for (var i:int=0;i<resets;i++) /*if (i%2==0)*/ rly.push('really');
						if (rly.length) rly_str = rly.join(', ')+' ';
						startLoadingLocationProgress(rly_str+'almost done...');
						reset_next_time = false;
					}
					
					updateLoadingLocationProgress(perc);
					
					if (perc == 1) reset_next_time = true;
				}
				
				AvatarResourceManager.instance.addLoadingListener(progressFunc);
				
				acr.addCallback(function(ac:AvatarConfig):void {
					AvatarResourceManager.instance.removeLoadingListener(progressFunc);
					doneLoadingUsersAvatarAssets();
				});
			} else {
				doneLoadingUsersAvatarAssets();
			}
			
		}
		
		//These view functions really shouldn't be here as an implementation.
		//Can we all of these types of hacks here, so they can be correctly implemented later ?
		
		// called when the component is going away, should give focus to previous focused componenet
		private var menu_click_lockers:int = 0;
		public function releaseFocus(comp:IFocusableComponent, deets:String=''):void {
			CONFIG::debugging {
				Console.log(99, 'RELEASE focus for: '+ObjectUtil.getClassName(comp));
			}
			
			if (comp is ConfirmationDialog) {
				menu_click_lockers--;
				//Console.warn('ConfirmationDialog downs menu_click_lockers:'+menu_click_lockers);
			} else if (comp is AnnouncementController) {
				menu_click_lockers--;
				//Console.warn('AnnouncementController downs menu_click_lockers:'+menu_click_lockers);
			} else if (comp is ChassisManager) {
				menu_click_lockers--;
				//Console.warn('ChassisManager downs menu_click_lockers:'+menu_click_lockers);
			} else if (comp is FurnUpgradeDialog) {
				menu_click_lockers--;
				//Console.warn('FurnUpgradeDialog downs menu_click_lockers:'+menu_click_lockers);
			} else if (comp is ChoicesDialog) {
				if (model.stateModel.fam_dialog_conv_is_active) {
					menu_click_lockers--;
					//Console.warn('ChoicesDialog downs menu_click_lockers:'+menu_click_lockers);
				}
			} 
			
			CONFIG::debugging {
				Console.trackValue('TSFC menu_click_lockers', menu_click_lockers);
			}
			
			// reallow clicks on pack
			if (menu_click_lockers < 1) {
				menu_click_lockers = 0;
				model.stateModel.menus_prohibited = false;
			}
			
			if (model.stateModel.focused_component != comp) {
				// This can happen, and in this case we should not change focus, but just
				// remove this comp altogether from history
				model.stateModel.expungeFromFocusHistory(comp);
				comp.blur();
				return;
			}
			
			if (!model.stateModel.prev_focused_component) {
				CONFIG::debugging {
					Console.error('releaseFocus called but there is no previously focused componenet to give focus to');
				}
				return;
			}
			
			if (model.stateModel.prev_focused_component == comp) {
				CONFIG::debugging {
					Console.error('releaseFocus called but this is the prev focused component!');
				}
				return;
			}
			
			// first get the prev comp
			var prev_focused_component:IFocusableComponent = model.stateModel.prev_focused_component;
			model.stateModel.about_to_be_focused_component = prev_focused_component;
			
			// now remove this comp altogether from history
			model.stateModel.expungeFromFocusHistory(comp);
			comp.blur();
			
			// now focus the prev comp
			var deets_str:String = ObjectUtil.getClassName(comp)+' released focus';
			if (deets) {
				deets_str+= ' ('+deets+')';
			}
			requestFocus(prev_focused_component, deets_str);
		}
		
		// called when a comp wants to not steal focus from current focused comp, but still wants to be in focus history
		public function putInFocusStack(comp:IFocusableComponent):Boolean {
			CONFIG::debugging {
				Console.log(99, 'IN FOCUS STACK for: '+ObjectUtil.getClassName(comp));
			}
			
			if (!model.stateModel.isCompRegisteredAsFocusableComponent(comp)) {
				CONFIG::debugging {
					Console.error(ObjectUtil.getClassName(comp) + ' has not registered with stateModel. call stateModel.registerFocusableComponent() in init function');
				}
				return false;
			}
			
			if (model.stateModel.focused_component is TSMainView) {
				CONFIG::debugging {
					Console.error('TSMainView is focused component, so you can not putInFocusStack');
				}
				return false;
			}
			
			if (model.stateModel.isCompInFocusHistory(comp)) {
				return true;
			}
			
			if (model.stateModel.addToFocusHistory(comp)) {
				return true;
			}

			return false;
		}
		
		// called when a comp wants to takes focus
		public function requestFocus(comp:IFocusableComponent, details_ob:Object=null):Boolean {
			CONFIG::debugging {
				Console.log(99, 'FOCUS for: '+ObjectUtil.getClassName(comp));
			}
			
			var err_str:String;
			
			if (!model.stateModel.isCompRegisteredAsFocusableComponent(comp)) {
				err_str = ObjectUtil.getClassName(comp) + ' has not registered with stateModel. call stateModel.registerFocusableComponent() in init function';
				Benchmark.addCheck(err_str);
				CONFIG::debugging {
					Console.error(err_str);
				}
				return false;
			}
			
			if (model.stateModel.focused_component && model.stateModel.focused_component.demandsFocus()) {
				err_str = 'requestFocus called, focused_component.demandsFocus() == true';
				Benchmark.addCheck(err_str);
				CONFIG::debugging {
					Console.error(err_str);
				}
				return false;
			}
			
			//hide the tooltip if it's up
			//[SY] I couldn't see any problems with this, but I didn't have a lot of time to test it out
			//TipDisplayManager.instance.goAway();
			
			model.stateModel.about_to_be_focused_component = comp;
			
			var was_focused_comp:IFocusableComponent = model.stateModel.focused_component;
			if (model.stateModel.focused_component && was_focused_comp != comp) {
				model.stateModel.focused_component.blur();
			}
			
			if (!model.stateModel.isCompInFocusHistory(comp)) {
				// when these get focus, allow no clicks on pack
				if (comp is ConfirmationDialog) {
					menu_click_lockers++;
					//Console.warn('ConfirmationDialog ups menu_click_lockers:'+menu_click_lockers);
				} else if (comp is ChassisManager) {
					menu_click_lockers++;
					//Console.warn('ChassisManager ups menu_click_lockers:'+menu_click_lockers);
				} else if (comp is FurnUpgradeDialog) {
					menu_click_lockers++;
					//Console.warn('FurnUpgradeDialog ups menu_click_lockers:'+menu_click_lockers);
				} else if (comp is AnnouncementController) {
					menu_click_lockers++;
					//Console.warn('AnnouncementController ups menu_click_lockers:'+menu_click_lockers);
				} else if (comp is ChoicesDialog) {
					if (model.stateModel.fam_dialog_conv_is_active) {
						menu_click_lockers++;
						//Console.warn('ChoicesDialog up menu_click_lockers:'+menu_click_lockers);
					}
				}
			}
			
			model.stateModel.focused_component = comp;
			
			CONFIG::debugging {
				Console.trackValue('TSFC menu_click_lockers', menu_click_lockers);
			}
			
			if (menu_click_lockers > 0) {
				model.stateModel.menus_prohibited = true;
			}
			
			comp.focus();
			
			// now tell them all about it
			
			for (var i:int;i<model.stateModel.foc_compsV.length;i++) {
				model.stateModel.foc_compsV[int(i)].focusChanged(comp, was_focused_comp);
			}
			
			
			var details_str:String = '';
			if (details_ob) {
				if (typeof details_ob == 'object') {
					try {
						details_str = '[';
						for (var k:String in details_ob) {
							if (details_str != '[') details_str+= ', ';
							details_str+='"'+k+'":'+details_ob[k]
						}
						details_str+= ']';
					} catch (err:Error) {
						
					}
				}
				
				if (!details_str) {
					details_str = details_ob.toString();
				} 
			}
			if (!details_str) details_str = 'not specified';
			details_str = ' - DETAILS: '+details_str
			
			BootError.focus_details = ObjectUtil.getClassName(comp)+details_str;
			Benchmark.addCheck('FOCUS CHANGED TO: '+BootError.focus_details);
			
			return true;
		}
		
		// has no start analog, because we just use startAvatar in all cases to restart
		public function stopAvatarKeyControl(deets:String):void {
			if (!instance.controllerMap.avatarController.is_started) return;
			instance.controllerMap.avatarController.stop(deets);
			instance.controllerMap.physicsController.stopCheckingForInteractionSprites();
			getMainView().gameRenderer.locationView.middleGroundRenderer.unglowAllInteractionSprites();
		}
		
		private function maybeStartAvatarKeyControl(deets:String):void {
			if (instance.controllerMap.avatarController.is_started) return;
			var bail:Boolean;
			
			CONFIG::debugging var bailReason:String = '';
			
			if (!(model.stateModel.focused_component is TSMainView)) {
				bail = true;
				CONFIG::debugging {
					bailReason+= '!(model.stateModel.focused_component is TSMainView) ';
				}
			}
			if (model.worldModel.pc.hit) {
				bail = true;
				CONFIG::debugging {
					bailReason+= 'model.worldModel.pc.hit='+model.worldModel.pc.hit;
				}
			}
			if (model.stateModel.avatar_gs_path_pt) {
				bail = true;
				CONFIG::debugging {
					bailReason+= 'model.stateModel.avatar_gs_path_pt='+model.stateModel.avatar_gs_path_pt;
				}
			}
			if (model.moveModel.moving) {
				bail = true;
				CONFIG::debugging {
					bailReason+= 'model.moveModel.moving='+model.moveModel.moving;
				}
			}
			
			if (bail) {
				CONFIG::debugging {
					Benchmark.addCheck('NOT CALLING AC.start for '+deets + ' bcz: '+bailReason)
				}
				return;
			}
			
			instance.controllerMap.physicsController.start(); // important, for gs path ending, emotion/hit animation ending
			instance.controllerMap.avatarController.start(deets);
		}
		
		public function startAvatar(deets:String):void {
			instance.controllerMap.netController.startSendingPCPos();
			instance.controllerMap.physicsController.start();
			maybeStartAvatarKeyControl(deets);
			AvatarAnimationState.paused = false;
		}
		
		public function startTowerFloorExpansion():void {
			HouseExpandDialog.instance.end(true);
			genericSend(new NetOutgoingHousesExpandTowerVO());
		}
		
		public function startPhyicsOnOtherPcs():void {
			instance.controllerMap.physicsController.addOtherPCAPOs();
		}
		
		CONFIG::god private var rescale_livs_timer:uint;
		CONFIG::god public function applyPhysicsSettingsFromAdminPanel(setting:PhysicsSetting):void {
			CONFIG::debugging {
				if (model.flashVarModel.benchmark_physics_adjustments) {
					Benchmark.addCheck('TSFC.applyPhysicsSettingsFromAdminPanel:\n' +
						setting.toString());
				}
			}
			
			// we do NOT want to do this, because it will fuck up the reset buttons
			//model.worldModel.location.physics_setting = setting.clone();
			
			// im not in love with this, but it seems to work ok. Why does it not fuck up the rest buttons as above notes it should?
			instance.controllerMap.physicsController.setPcPhysics(model.worldModel.pc, setting.clone(), model.physicsModel.pc_adjustments);
			
			model.worldModel.location.physics_setting.item_scale = setting.item_scale;
			//model.worldModel.location.physics_setting.y_cam_offset = setting.y_cam_offset;
				
			if (rescale_livs_timer) {
				StageBeacon.clearTimeout(rescale_livs_timer);
			}
			
			rescale_livs_timer = StageBeacon.setTimeout(getMainView().gameRenderer.bruteForceReloadLIVs, 100);
		}
		
		public function setOtherPCPhysics(pc_tsid:String, adjustments:Object):void {
			var pc:PC = model.worldModel.getPCByTsid(pc_tsid);
			if (!pc || pc == model.worldModel.pc) {
				return;
			}

			// fresh every time (but why is this nec? setPcPhysics() is about to do the same thing)
			pc.apo.base_setting = model.worldModel.location.physics_setting.clone();
			pc.apo.setting = model.worldModel.location.physics_setting.clone();
			
			instance.controllerMap.physicsController.setPcPhysics(pc, model.physicsModel.settables.getSettingByName(pc.apo.setting.name).clone(), adjustments);
		}
		
		public function stopAvatar(deets:String, and_send_movexy:Boolean=false):void {
			instance.controllerMap.netController.stopSendingPCPos();
			instance.controllerMap.physicsController.stop();
			instance.controllerMap.avatarController.stop(deets);
			AvatarAnimationState.paused = true;
			
			if (and_send_movexy) {
				// this makes sure that other clients get the paused indicator
				if(getMainView().gameRenderer && getMainView().gameRenderer.getAvatarView()){
					getMainView().gameRenderer.getAvatarView().updateModel();
				}
				controllerMap.netController.maybeSendMoveXY();
			}
		}
		
		public function onFatalError(msg:String):void {
			model.netModel.should_reconnect = false;
			controllerMap.netController.onFatalError(msg);
		}
		
		/**
		 * Takes an Object of the following format: {
		 *   walls: {...},
		 *   platform_lines: {...},
		 *   doors: {...}
		 * }
		 */
		public function addGeo(geo:Object):void {
			controllerMap.physicsController.addGeo(geo);
		}
		
		/**
		 * Takes an Object of the following format: {
		 *   walls: {...},
		 *   platform_lines: {...}
		 * }
		 */
		public function updateGeo(geo:Object):void {
			controllerMap.physicsController.updateGeo(geo);
		}
		
		/**
		 * Takes an Object of the following format: {
		 *   walls: [tsid, ...],
		 *   platform_lines: [tsid, ...]
		 * }
		 */
		public function removeGeo(geo:Object):void {
			controllerMap.physicsController.removeGeo(geo);
		}
		
		/**
		 * Takes an Object of the following format:
		 * 
		 * layers: {
		 *   middleground: {
		 *     tsid: {
		 *       x: -226,
		 *       y: 15,
		 *       z: 1,
		 *       w: 111,
		 *       h: 184,
		 *       sprite_class: "fire1",
		 *       name: "fire1_1311661932850",
		 *       animated: true
		 *     }
		 *   }
		 * }
		 */
		public function addDeco(layers:Object):void {
			controllerMap.viewController.addDeco(layers);
		}
		
		/**
		 * Takes an Object of the following format:
		 * 
		 * layers: {
		 *   middleground: {
		 *     tsid: {
		 *        x: 123,
		 *        y: 456
		 *     }
		 *   }
		 * }
		 */
		public function updateDeco(layers:Object):void {
			controllerMap.viewController.updateDeco(layers);
		}
		
		/**
		 * Takes an Object of the following format:
		 * 
		 * layers: {
		 *   middleground: [tsid, ...],
		 *   ...
		 * }
		 */
		public function removeDeco(layers:Object):void {
			controllerMap.viewController.removeDeco(layers);
		}
		
		CONFIG::god public function saveLocationLoadingImg(go:Boolean=false, callback:Function=null):void {
			/*
			/simple/god.streets.setLoadingImage [Admin Only]
			Sets a loading image for the street. Should be 840x160
			
			* tsid - TSID of street.
			* image - PNG file.
			*/
			if (go) {
				growl('ADMIN: snapping, say cheese!');
				CONFIG::god {
					model.stateModel.loc_saved_but_not_snapped = false;
				}
				var bmd:BitmapData = getMainView().gameRenderer.getSnapshot(CameraMan.SNAPSHOT_TYPE_LOADING, 840, 160).bitmapData;
				api_call.loadingImage(bmd, callback);
			} else {
				growl('ADMIN: prepare to save loading img... stand still!');
				// the viewport culls itemstacks that aren't visible; so make it 
				// big enough to include the whole location and wait a few
				// seconds to be sure that rendering has caught up
				model.layoutModel.loc_vp_rect_collision_scale = CONFIG::LOC_VP_RECT_COLLISION_SCALE_FOR_SNAPPING;
				StageBeacon.setTimeout(saveLocationLoadingImg, CONFIG::PRE_SNAP_DELAY, true, callback);
			}
		}
		
		/** This one will save a full screenshot of the location with everything in it */
		public function saveLocationImgFullSizeWithEverything():void {
			saveLocationImgFullSize(true);
		}
		
		public function saveLocationImgFullSize(includeEverything:Boolean=false, go:Boolean=false):void {
			/*
			/simple/god.streets.setLoadingImage [Admin Only]
			Sets a loading image for the street. Should be 840x160
			
			* tsid - TSID of street.
			* image - PNG file.
			*/
			if (go) {
				var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
				cdVO.callback =	function(value:*):void {
					if (value == 'yes') {
						growl("" + (includeEverything ? 'taking snap with everything' : 'taking snap WITHOUT everything') + " -- say cheese!");
						var bmd:BitmapData = getMainView().gameRenderer.getSnapshot(CameraMan.SNAPSHOT_TYPE_FULL, model.worldModel.location.mg.w, 0, false, includeEverything, includeEverything).bitmapData;
						var bss:BitmapSnapshot = new BitmapSnapshot(null, model.worldModel.location.label+'.png', 0, 0, bmd);
						bss.saveToDesktop();
					}
					model.layoutModel.loc_vp_rect_collision_scale = model.flashVarModel.vp_rect_collision_scale; // sets it back to what it was
				}
				cdVO.txt = 'Save "'+model.worldModel.location.label+'.png" to your desktop?';
				cdVO.choices = [
					{value: 'no', label: 'No'},
					{value: 'yes', label: 'Yes please'}
				];
				cdVO.escape_value = 'no';
				confirm(cdVO);
			} else {
				growl('starting to save full size snap... stand still!');
				// the viewport culls itemstacks that aren't visible; so make it 
				// big enough to include the whole location and wait a few
				// seconds to be sure that rendering has caught up
				model.layoutModel.loc_vp_rect_collision_scale = CONFIG::LOC_VP_RECT_COLLISION_SCALE_FOR_SNAPPING;
				StageBeacon.setTimeout(saveLocationImgFullSize, CONFIG::PRE_SNAP_DELAY, includeEverything, true);
			}
		}
		
		// this is ONLY called from APICall after saveLocationLoadingImg response is handled
		public function saveLocationImg(callback:Function=null):void {
			/*
			* tsid - TSID of street.
			* image - PNG file.
			*/

			growl('ADMIN: starting to save normal img... stand still!');
			var bmd:BitmapData = getMainView().gameRenderer.getSnapshot(CameraMan.SNAPSHOT_TYPE_NORMAL, 960).bitmapData;
			// return the value from whence it came
			model.layoutModel.loc_vp_rect_collision_scale = model.flashVarModel.vp_rect_collision_scale;
			api_call.locationImage(bmd, callback);
		}

		private var save_home_img_timer:uint;
		public function saveHomeImg():void {
			if (!model.worldModel.pc.home_info.playerIsAtHome()) return;
			/*
			* tsid - TSID of street.
			* image - PNG file.
			*/
			
			var st:int = getTimer();
			try {
				var bmd:BitmapData = getMainView().gameRenderer.getSnapshot(CameraMan.SNAPSHOT_TYPE_NORMAL, model.worldModel.location.mg.w).bitmapData;
			} catch(err:Error) {
				CONFIG::god {
					growl('ADMIN: saving home img failed '+err);
				}
				
				return;
			}
			
			CONFIG::god {
				growl('ADMIN: saving home img (getSnapshot took '+(getTimer()-st)+'ms)');
			}
			// return the value from whence it came
			model.layoutModel.loc_vp_rect_collision_scale = model.flashVarModel.vp_rect_collision_scale;
			
			/*
			var bm:Bitmap = new Bitmap(bmd.clone());
			StageBeacon.stage.addChild(bm);
			//*/
			
			if (save_home_img_timer) StageBeacon.clearTimeout(save_home_img_timer);
			save_home_img_timer = StageBeacon.setTimeout(api_call.homeImage, 3000, bmd);
		}
		
		public function unBlockFamiliarConvos():void {
			if (model.stateModel.fam_dialog_can_go) return; // might have alreayd been flipped to true by clicking on tell me more button or sending a familiar talk_to
			model.stateModel.fam_dialog_can_go = true;
			//Console.warn('fam_dialog_can_go '+model.stateModel.fam_dialog_can_go)
			// if there is something in the Q, go!
			if (!model.stateModel.fam_dialog_conv_is_active) {
				if (model.stateModel.fam_dialog_conv_payload_q.length) {
					startFamiliarConversationWithPayload(model.stateModel.fam_dialog_conv_payload_q.shift());
				} else {
					if (model.worldModel.pc && model.worldModel.pc.familiar && model.worldModel.pc.familiar.messages) {
						maybeTalkToFamiliar();
					}
				}
			}
		}
		
		public function runAvatarController():void {
			instance.controllerMap.avatarController.run();
		}
		
		private var camera_center_tim:uint;
		public function setCameraCenter(pc_tsid:String, itemstack_tsid:String, pt:Point=null, duration_ms:int=0, no_matter_what:Boolean=false, px_sec:int=0):void {
			var sm:StateModel = model.stateModel;
			resetCameraCenter();
			if (px_sec) {
				CameraMan.instance.imposeHardDistLimitByPxPerSecond(px_sec);
			}
			
			if (pc_tsid) {
				if (model.worldModel.location.pc_tsid_list[pc_tsid]) {
					var pc:PC = model.worldModel.getPCByTsid(pc_tsid);
					var pcv:PCView = getMainView().gameRenderer.getPcViewByTsid(pc_tsid);
					if (pcv && (pcv.worth_rendering || no_matter_what)) {
						sm.camera_center_pc_tsid = pc_tsid;
						pt = new Point(pc.x, pc.y);
					}
				}
			} else if (itemstack_tsid) {
				if (model.worldModel.location.itemstack_tsid_list[itemstack_tsid]) {
					var liv:LocationItemstackView = getMainView().gameRenderer.getItemstackViewByTsid(itemstack_tsid);
					if (liv && (liv.worth_rendering || no_matter_what)) {
						sm.camera_center_itemstack_tsid = itemstack_tsid;
						pt = new Point(liv.itemstack.x, liv.itemstack.y);
					}
				}
			} else if (pt) {
				sm.camera_center_pt = pt;
			}
			
			if (pt && duration_ms && (sm.camera_center_itemstack_tsid || sm.camera_center_pc_tsid || sm.camera_center_pt)) {
				// TODO, calc home much time it will take for the camera to get there and add it into the duration_ms
				var dist_limit:int = CameraMan.instance.calcDistLimit();
				var extra_ms_for_cam_moving:int = 0;
				var dist:int = 0;
				if (dist_limit) {
					dist = Math.abs(Point.distance(CameraMan.instance.center_pt, pt));
					if (dist) {
						extra_ms_for_cam_moving = (dist/dist_limit)*(1000/StageBeacon.stage.frameRate);
						CONFIG::debugging {
							Console.info('camera dist:'+dist+'px dist_limit:'+dist_limit+'px extra_ms_for_cam_moving:'+extra_ms_for_cam_moving+'ms');
						}
					}
				}
				camera_center_tim = StageBeacon.setTimeout(function():void {
					var was_camera_hard_dist_limit:int = sm.camera_hard_dist_limit;
					resetCameraCenter();
					// This make it so the camera snap back to your avatar happens at the same rate as the movement
					// to the thing it was centered on. I think it is safe to just leave it after the snapback, as any other
					// camera centering will reset it
					sm.camera_hard_dist_limit = was_camera_hard_dist_limit;
				}, duration_ms+extra_ms_for_cam_moving);
			}
			
			setCameraDeets();
		}
		
		public function setCameraDeets():void {
			var sm:StateModel = model.stateModel;
			BootError.camera_details = 
				'pc_tsid:'+(sm.camera_center_pc_tsid || '' )+
				' itemstack_tsid:'+(sm.camera_center_itemstack_tsid || '' )+
				' pt:'+(sm.camera_center_pt || '' )+
				' center_str:'+(CameraMan.instance.center_str || '' )+
				' calcDistLimit:'+(CameraMan.instance.calcDistLimit())
		}
		
		public function resetCameraCenter():void {
			var sm:StateModel = model.stateModel;
			//TSTweener.removeTweens(sm.camera_center_pt);
			sm.camera_hard_dist_limit = 0;
			if (camera_center_tim) StageBeacon.clearTimeout(camera_center_tim);
			sm.camera_center_itemstack_tsid = '';
			sm.camera_center_pc_tsid = '';
			sm.camera_center_pt = null;
			
			setCameraDeets();
		}
		
		public function resetCameraOffset():void {
			model.stateModel.camera_offset_x = 0;
			model.stateModel.camera_offset_from_edge = false;
			setCameraOffset();
		}
		
		public function setCameraOffset():void {
			var offset_x:int = model.stateModel.camera_offset_x;
			if (offset_x) {
				if (model.stateModel.camera_offset_from_edge) {
					if (offset_x > 0) {
						model.stateModel.use_camera_offset_x = (model.layoutModel.loc_vp_w/2)-offset_x;
					} else {
						model.stateModel.use_camera_offset_x = -(model.layoutModel.loc_vp_w/2)-offset_x;
					}
				} else {
					model.stateModel.use_camera_offset_x = offset_x;
				}
			} else {
				model.stateModel.use_camera_offset_x = 0;
			}
		}
		
		public function startMovingAvatarOnGSPath(pt:Point, face:String = ''):void {
			if (model.worldModel.pc.apo.onLadder) {
				CONFIG::debugging {
					Console.error('could not start gs path because you\'re on a ladder')
				}
				return;
			}
			
			//first, we end any existing path:
			model.stateModel.avatar_gs_path_pt = null;
			model.stateModel.avatar_gs_path_end_face = null;
			instance.controllerMap.avatarController.endPath();
			
			// now start a new path
			model.stateModel.avatar_gs_path_pt = pt;
			model.stateModel.avatar_gs_path_end_face = face;
			CONFIG::god {
				// stick in a dot to show where the GS is moving the avatar
				model.activityModel.dots_to_draw = {clear:true, coords:[[pt.x, pt.y]]};
			}
			stopAvatarKeyControl('TSFC.startMovingAvatarOnGSPath');
			instance.controllerMap.avatarController.beginPath(pt);
		}
		
		public function onAvatarPathEnded(deets:String):void {
			cancelAvatarPath(deets)
		}
		
		private function cancelAvatarPath(deets:String):void {
			if (model.stateModel.avatar_gs_path_pt) {
				
				// stop the fucker outright, but only if on a gs path
				model.worldModel.pc.apo.triggerResetVelocityX = true;
				
				//Console.info('model.stateModel.avatar_gs_path_end_face:'+model.stateModel.avatar_gs_path_end_face);
				if (model.stateModel.avatar_gs_path_end_face == 'right') {
					//Console.info('facing right');
					getMainView().gameRenderer.getAvatarView().faceRight();
					StageBeacon.setTimeout(function():void {
						//Console.warn('model.stateModel.focused_component is TSMainView:'+(model.stateModel.focused_component is TSMainView))
						if (!(model.stateModel.focused_component is TSMainView)) getMainView().gameRenderer.getAvatarView().faceRight();
					}, 100);
				} else if (model.stateModel.avatar_gs_path_end_face == 'left') {
					//Console.info('facing left');
					getMainView().gameRenderer.getAvatarView().faceLeft();
					StageBeacon.setTimeout(function():void {
						//Console.warn('model.stateModel.focused_component is TSMainView:'+(model.stateModel.focused_component is TSMainView))
						if (!(model.stateModel.focused_component is TSMainView)) getMainView().gameRenderer.getAvatarView().faceLeft();
					}, 100);
				}
				
				model.stateModel.avatar_gs_path_pt = null;
				model.stateModel.avatar_gs_path_end_face = null;
				maybeStartAvatarKeyControl('TSFC.cancelAvatarPath via '+deets);
			}
		}
		
		public function stopAndFaceAvatar(face:String):void {
			// stop the fucker outright
			model.worldModel.pc.apo.triggerResetVelocityX = true;
			if (face == 'right') {
				StageBeacon.setTimeout(getMainView().gameRenderer.getAvatarView().faceRight, 60)
			} else if (face == 'left') {
				StageBeacon.setTimeout(getMainView().gameRenderer.getAvatarView().faceLeft, 60)
			}
		}
		
		public function faceAvatarIfNotMoving(face:String):void {
			if (Math.abs(model.worldModel.pc.apo.vx) > .1) return;
			if (face == 'right') {
				getMainView().gameRenderer.getAvatarView().faceRight();
				//StageBeacon.waitForNextFrame((function():void {
				//	if (!(model.stateModel.focused_component is TSMainView)) getMainView().gameRenderer.getAvatarView().faceRight();
				//});
			} else if (face == 'left') {
				getMainView().gameRenderer.getAvatarView().faceLeft();
				//StageBeacon.waitForNextFrame((function():void {
				//	if (!(model.stateModel.focused_component is TSMainView)) getMainView().gameRenderer.getAvatarView().faceLeft();
				//});
			}
		}
		
		public function refreshLocationPath():void {
			startLocationPath(model.stateModel.loc_pathA.concat());
		}
		
		public function endLocationPath():void {
			genericSend(new NetOutgoingClearLocationPathVO());
		}
		
		public function startLocationPath(A:Array):void {
			//Console.warn('startLocationPath '+A)
			if (!A) return;
			if (A.length < 2) return;
			clearLocationPath();
			
			model.stateModel.loc_pathA = A;
			//Console.warn('startLocationPath WE ARE GO '+model.stateModel.loc_pathA)
			
			var next_loc_tsid:String;
			var loc:Location = model.worldModel.location;
			var curr_loc_index:int = A.indexOf(loc.tsid);
			var signpost:SignPost;
			var door:Door;
			
			//maybe we've hit the showStreet
			//[SY] this was added for newxp, but god knows what else this may break...
			//Maybe hide it behind the loc.no_imagination tag if it bungs things up
			if(curr_loc_index == -1 && loc.mapInfo && loc.mapInfo.showStreet){
				curr_loc_index = A.indexOf(loc.mapInfo.showStreet);
			}
			
			if (curr_loc_index > -1) { // we are on the path
				model.stateModel.loc_path_active = true;
				
				if (curr_loc_index == A.length-1) { // we are at destination
					model.stateModel.loc_path_at_dest = true;
					
				} else { // we are not yet at destination					
					next_loc_tsid = A[curr_loc_index+1];
					model.stateModel.loc_path_next_loc_tsid = next_loc_tsid;
					signpost = loc.getSignpostThatLinksToLocTsid(next_loc_tsid);
					if (signpost) {
						model.stateModel.loc_path_signpost = signpost;
					} else {
						door = loc.getDoorThatLinksToLocTsid(next_loc_tsid);
						
						if (door) {
							model.stateModel.loc_path_door = door;
						} else {
							CONFIG::debugging {
								Console.error('could not find signpost or door that links to '+next_loc_tsid);
							}
						}
					}
				}
			} else {
				
				/*
				it would probably be good if here we iterated over all the items in loc_pathA from the end to see
				if any of them are linked to from a signpost in this location, and set 
				model.stateModel.loc_path_signpost
				and
				model.stateModel.loc_path_active
				so we can can continu on path
				*/
				var loc_tsid:String;
				for (var i:int=A.length-1;i>-1;i--) {
					loc_tsid = A[int(i)];
					signpost = model.worldModel.location.getSignpostThatLinksToLocTsid(loc_tsid)
					if (signpost) {
						model.stateModel.loc_path_signpost = signpost;
						model.stateModel.loc_path_next_loc_tsid = loc_tsid;
						model.stateModel.loc_path_active = true;
						break;
					}
					
					door = loc.getDoorThatLinksToLocTsid(loc_tsid);
					if (door) {
						model.stateModel.loc_path_door = door;
						model.stateModel.loc_path_next_loc_tsid = loc_tsid;
						model.stateModel.loc_path_active = true;
						break;
					}
				}
			}
			
			CONFIG::debugging {
				//Console.warn('dblchk '+model.stateModel.loc_pathA)
				Console.trackValue(' LP loc_pathA', model.stateModel.loc_pathA);
				Console.trackValue(' LP loc_path_signpost', model.stateModel.loc_path_signpost);
				Console.trackValue(' LP loc_path_door', model.stateModel.loc_path_door);
				Console.trackValue(' LP loc_path_at_dest', model.stateModel.loc_path_at_dest);
				Console.trackValue(' LP loc_path_active', model.stateModel.loc_path_active);
				Console.trackValue(' LP loc_path_next_loc_tsid', model.stateModel.loc_path_next_loc_tsid);
			}
			
			HubMapDialog.instance.onLocationPathStarted();
			MiniMapView.instance.refreshLocPath();
		}
		
		public function clearLocationPath():void {
			//Console.warn('clearLocationPath');
			model.stateModel.loc_pathA.length = 0;
			model.stateModel.loc_path_at_dest = false;
			model.stateModel.loc_path_active = false;
			model.stateModel.loc_path_signpost = null;
			model.stateModel.loc_path_door = null;
			model.stateModel.loc_path_next_loc_tsid = '';
			
			CONFIG::debugging {
				Console.trackValue(' LP loc_pathA', model.stateModel.loc_pathA);
				Console.trackValue(' LP loc_path_signpost', model.stateModel.loc_path_signpost);
				Console.trackValue(' LP loc_path_door', model.stateModel.loc_path_door);
				Console.trackValue(' LP loc_path_at_dest', model.stateModel.loc_path_at_dest);
				Console.trackValue(' LP loc_path_active', model.stateModel.loc_path_active);
				Console.trackValue(' LP loc_path_next_loc_tsid', model.stateModel.loc_path_next_loc_tsid);
			}
			
			HubMapDialog.instance.onLocationPathEnded();
			MiniMapView.instance.refreshLocPath();
			RightSideManager.instance.updateYouOnMap();
		}
		
		//That * can't be right.
		public function startUserInitiatedPath(destination:*):void {
			if (model.stateModel.avatar_gs_path_pt) return;
			instance.controllerMap.avatarController.beginPath(destination, null, true, 0, KeyBeacon.instance.pressed(Keyboard.CONTROL));
			if (EnvironmentUtil.is_mac) {
				KeyBeacon.instance.reset('MAC TSFC.startUserInitiatedPath', [Keyboard.CONTROL]);
			}
		}
		
		public function cancelAllAvatarPaths(deets:String):void {
			instance.controllerMap.avatarController.endPath();
			cancelAvatarPath(deets);
		}
		
		public function moveAvatarToLIVandDoVerbOrAction(liv:LocationItemstackView, verb_or_action:Object, requires_intersection:Boolean=true):void {
			if (model.stateModel.avatar_gs_path_pt) return;
			var pm:PhysicsModel = model.physicsModel;
			
			// 30 is about half of ava size
			var offset:int = Math.min((liv.itemstack.client::physWidth/2)+30, pm.required_verb_proximity-pm.path_end_allowance);
			CONFIG::debugging {
				Console.info(requires_intersection+' offset:'+offset+' '+((liv.itemstack.client::physWidth/2)+30)+' '+(pm.required_verb_proximity-pm.path_end_allowance));
			}
			instance.controllerMap.avatarController.beginPath(
				liv,
				verb_or_action,
				requires_intersection,
				offset
			);
		}
		
		public function getOnLadder(ladder:Ladder):void {
			instance.controllerMap.avatarController.getOnLadder(ladder);
		}
		
		public function getOffLadder():void {
			instance.controllerMap.avatarController.getOffLadder();
		}
		
		public function getMainView():TSMainView {
			if (!controllerMap || !controllerMap.viewController) {
				//Console.error('wtf');
				return null;
			}
			return controllerMap.viewController.tsMainView;
		}
		
		public function addUnderCursor(DO:DisplayObject):void {
			StageBeacon.stage.addChild(DO);
			StageBeacon.stage.addChild(Cursor.instance);
		}
		
		public function togglePackContainer(tsid:String):void {
			var pdm:PackDisplayManager = controllerMap.viewController.tsMainView.pdm;
			if (pdm) pdm.toggleContainer(tsid);
		}
		
		public function translateLocationBagSlotToGlobal(slot:int, path:String):Point {
			var chunks:Array = path.split('/');
			var lis_view:LocationItemstackView = getMainView().gameRenderer.getItemstackViewByTsid(chunks[0]);
			
			if(TrophyCaseDialog.instance.visible){
				return TrophyCaseDialog.instance.translateSlotCenterToGlobal(slot, path);
			}
			else if(CabinetDialog.instance.visible){
				return CabinetDialog.instance.translateSlotCenterToGlobal(slot);
			}
			else if(lis_view){
				return lis_view.localToGlobal(new Point(0, -lis_view.height/2));
			}
			else {
				return new Point(0,0);
			}
		}
		
		public function isStorageUIOpen():Boolean {
			if(TrophyCaseDialog.instance.visible){
				return true;
			}
			else if(CabinetDialog.instance.visible){
				return true;
			}

			return false;
		}
		
		public function confirm(cdVO:ConfirmationDialogVO):Boolean {
			if (!ConfirmationDialog.instance.startWithVO(cdVO)) {
				// TODO QUEUE!
				return false;
			}
			
			return true;
		}
		
		public function translatePackSlotToGlobal(slot:int, path:String):Point {
			var pdm:PackDisplayManager = controllerMap.viewController.tsMainView.pdm;
			if (pdm) return pdm.translateSlotCenterToGlobal(slot, path);
			return null;
		}
		
		public function startPcMenuFromList(pc_tsid:String):void {
			if(pc_tsid == model.worldModel.pc.tsid) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			controllerMap.interactionMenuController.startPCMenu(pc_tsid, InteractionMenuModel.TYPE_LIST_PC_VERB_MENU, true);
		}
		
		public function startLocationMenuFromHubMap(street:Street, hub_tsid:String):void {
			controllerMap.interactionMenuController.startLocationMenu(street, hub_tsid, true);
		}
		
		public function startGardenPlotMenu(garden_tsid:String, plot:GardenPlot, available_actions:Array):void {
			controllerMap.interactionMenuController.startGardenPlotMenu(garden_tsid, plot, available_actions, true);
		}
		
		public function startGroupMenu(group_tsid:String, is_active:Boolean):void {
			controllerMap.interactionMenuController.startGroupMenu(group_tsid, is_active, true);
		}
		
		public function startIM(pc_tsid:String):void {
			//if they are an admin, and the player is not, show something
			var pc:PC = model.worldModel.getPCByTsid(pc_tsid);
			if(pc && pc.is_admin && !model.worldModel.pc.is_admin){
				SendIMToDevDialog.instance.pc_tsid = pc_tsid;
				SendIMToDevDialog.instance.start();
				return;
			}
			
			RightSideManager.instance.chatStart(pc_tsid, true);
		}
		
		private var already_checking_familiar:Boolean = false;
		public function maybeTalkToFamiliar():void {
			// only proceed if there are new messages and a conv is not active
			if (already_checking_familiar) return;
			if (!model.worldModel.pc.familiar.messages) return;
			if (model.stateModel.fam_dialog_open && model.stateModel.fam_dialog_conv_is_active) return;
			
			already_checking_familiar = true;
			
			// a hacky way to ensure that even if no rsp to the talk_to verb comes back, we son't get locked into already_checking_familiar until a client reload
			StageBeacon.setTimeout(function():void {
				if (!already_checking_familiar) return;
				CONFIG::god {
					growl('ADMIN: tell eric that a rsp to familiar talk_to verb did not arrive within 10 secs');
				}
				already_checking_familiar = false;
				maybeTalkToFamiliar();
			}, 10000);
			// end hacky
			
			sendItemstackVerb(
				new NetOutgoingItemstackVerbVO(model.worldModel.pc.familiar.tsid, 'talk_to', 1), function():void {
					already_checking_familiar = false;
				}, function():void {
					already_checking_familiar = false;
				}
			);
			
		}
		
		private var fam_dialog_skill_interv:int;
		public function startFamiliarSkillMessageWithPayload(payload:Object):void {
			model.stateModel.fam_dialog_skill_payload_q.push(payload);
		
			if (!YouDisplayManager.instance.visible) { // show when fam becomes visible 
				StageBeacon.clearInterval(fam_dialog_skill_interv);
				fam_dialog_skill_interv = StageBeacon.setInterval(function():void {
					if (model.stateModel.fam_dialog_skill_payload_q.length) {
						StageBeacon.clearInterval(fam_dialog_skill_interv);
						startFamiliarSkillMessageWithPayload(model.stateModel.fam_dialog_skill_payload_q.shift());
					}
				}, 2000);
				return;
			}
			
			// go ahead and open it right away if it is not open or it is showing the default menu
			if (!model.stateModel.fam_dialog_open) {
				startFamiliarDialog(FamiliarDialog.SKILL_LEARNED); // not opened, do the anim
			} else if (FamiliarDialog.instance.current_panel_name == FamiliarDialog.DEFAULT) {
				FamiliarDialog.instance.startWithPanel(FamiliarDialog.SKILL_LEARNED); // open, switch panels
			} else {
				// do nothing, we'll check the fam_dialog_conv_payload_queue later when we go to close the fam dialog
			}
		}
		
		public function endCameraManUserMode():void {
			CameraMan.instance.endUserMode();
		}
		
		public function maybeStartCameraManUserMode(why:String):Boolean {
			var loc:Location = model.worldModel.location;
			if (!loc) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return false;
			}
			
			if (loc.no_camera_mode) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return false;
			}
				
			CameraMan.instance.startUserMode(why);
			return true;
		}
		
		public function startFamiliarConversationWithPayload(payload:Object, force:Boolean = false):Boolean {
			if(!payload){
				CONFIG::debugging {
					Console.error('startFamiliarConversationWithPayload WITHOUT A PAYLOAD');
				}
				return false;
			}
			
			var sm:StateModel = model.stateModel;
			var fc:IFocusableComponent = sm.focused_component;
			
			// when called by clicking, force
			if (force) sm.fam_dialog_can_go = true;

			// this is a special case that allows the fam to show a convo even if the location has no_familiar:true
			if (ConversationManager.instance.isGreeterConv(payload.conv_type)) {
				sm.showing_greeter_conv = true;
				changeTeleportDialogVisibility();
			}
			
			var bail:Boolean;
			CONFIG::debugging var bailReason:String = '';
			
			if (!sm.fam_dialog_can_go) {
				bail = true;
				CONFIG::debugging {
					bailReason+= ' sm.fam_dialog_can_go='+sm.fam_dialog_can_go;
				}
			}
			
			CONFIG::locodeco {
				if (sm.editing) {
					bail = true;
					CONFIG::debugging {
						bailReason+= ' sm.editing='+sm.editing;
					}
				}
			}
			
			if (sm.fam_dialog_open) {
				bail = true;
				CONFIG::debugging {
					bailReason+= ' sm.fam_dialog_open='+sm.fam_dialog_open;
				}
			}
			
			if (fc is LocationSelectorDialog) {
				bail = true;
				CONFIG::debugging {
					bailReason+= '(fc is LocationSelectorDialog) ';
				}
			}
			
			if (sm.screen_view_open) {
				bail = true;
				CONFIG::debugging {
					bailReason+= ' sm.screen_view_open='+sm.screen_view_open;
				}
			}
			
			if (sm.in_camera_control_mode) {
				bail = true;
				CONFIG::debugging {
					bailReason+= ' sm.in_camera_control_mode='+sm.in_camera_control_mode;
				}
			}
			
			if (model.moveModel.moving) {
				bail = true;
				CONFIG::debugging {
					bailReason+= ' is_moving';
				}
			}
			
			if (!force) {
				// on 3/18/2011 we expanded the meaning of model.worldModel.location.no_starting_quests to mean
				// also no auto quest offering from the familiar (you can still click the "tell me more" button though)
				if (payload.conv_type && payload.conv_type == ConversationManager.TYPE_QUEST_OFFER) {
					if (model.worldModel.location.no_starting_quests) {
						bail = true;
						CONFIG::debugging {
							bailReason+= ' model.worldModel.location.no_starting_quests=true and payload.conv_type == ConversationManager.TYPE_QUEST_OFFER';
						}
					}
				}
				
				// don't allow fam convs when your are not focused in chat or controlling your avatar
				if (!(fc is TSMainView) && (!(fc is InputField) || !InputField(fc).is_for_chat)) {
					bail = true;
					CONFIG::debugging {
						bailReason+= ' !(fc is TSMainView) && (!(fc is InputField) || !InputField(fc).is_for_chat))';
					}
				}
				
				if (ChoicesDialog.instance.visible) {
					bail = true;
					CONFIG::debugging {
						bailReason+= ' ChoicesDialog.instance.visible=true';
					}
				}
			} 
			
			// if we have any reason to bail, do so, and q the payload if we can
			if (bail) {
				if (payload.conv_type != ConversationManager.TYPE_QUEST_OFFER) { // we do not q quest_offers
					sm.fam_dialog_conv_payload_q.push(payload);
					CONFIG::debugging {
						//Console.info('ADDING TO Q - bailing on startFamiliarConversationWithPayload b/c'+bailReason);
					}
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.info('bailing on startFamiliarConversationWithPayload b/c'+bailReason);
					}
				}
				
				//start the timer if it's not already started
				if(!sm.familiar_retry_timer.hasEventListener(TimerEvent.TIMER)){
					sm.familiar_retry_timer.addEventListener(TimerEvent.TIMER, tryFamiliarConversation, false, 0, true);
				}
				
				if(!sm.familiar_retry_timer.running) {
					/*CONFIG::debugging {
						Console.info('familiar_retry_timer.start');
					}*/
					sm.familiar_retry_timer.start();
				}
				
				return false;
			}
			
			sm.fam_dialog_conv_is_active = true; // must do this here, or during the fam diag opening animation maybeTalkToFamiliar might be called again
			
			var started:Boolean = startFamiliarDialog(FamiliarDialog.CONVERSATION, function():void {
				ConversationManager.instance.presentFamiliarChoices(payload);
			});
			
			// if we display it we want the button to be disabled, so set the conv active
			if (started && payload.conv_type == ConversationManager.TYPE_QUEST_OFFER && payload.quest_id) {
				// this will fire events to update the offer button in the quest dialog
				QuestManager.instance.setQuestConversationActive(payload.quest_id, true);
			}
			
			return true;
		}
		
		// this grows the familiar and animates open the dialog. thus, it can only be called when the dialog is not already open.
		// if you want to change the content of an already open fam dialog, use FamiliarDialog.instance.startWithPanel
		private function startFamiliarDialog(panel_name:String, doneFunc:Function = null):Boolean {
			if (model.stateModel.fam_dialog_open || model.stateModel.editing || model.moveModel.moving) {
				return false;
			}
			
			/* it seems like this is a bad idea, since it will make your quest log go away when you get told about new quest offers automatically
			if (QuestsDialog.instance.parent) {
				QuestsDialog.instance.end(true);
			}
			*/
			
			FamiliarDialog.instance.startWithPanel(panel_name);
			if (doneFunc != null) doneFunc();
			
			model.stateModel.fam_dialog_open = true;
			changeTeleportDialogVisibility();
			
			return true;
		}
		
		public function endFamiliarConversation(conv_type:String, quest_id:String):void {
			if (conv_type == ConversationManager.TYPE_QUEST_OFFER && quest_id) {
				// this will fire events to update the offer button in the quest dialog
				QuestManager.instance.setQuestConversationActive(quest_id, false);
			}
			if (!model.stateModel.fam_dialog_open) return;
			
			
			// check for the case where we're showing a greeter conv even though the location is set to have no familoar
			if (ConversationManager.instance.isGreeterConv(conv_type) && !model.worldModel.location.show_familiar) {
				// let's just close this now and not do any of the fancies
				doEndFamiliarDialog(function():void{
					model.stateModel.showing_greeter_conv = false;
					StageBeacon.setTimeout(function():void {
						changeTeleportDialogVisibility();
					}, 600);
				});
				return;
			}
			
			// this is wrong I think! because not all ended conversations were started because of the familiar.messages count. hrmm
			//model.worldModel.pc.familiar.messages--; // the only place this gets decremented
			endFamiliarDialog();
		}
		
		public function endFamiliarDialog(doneFunc:Function = null):void {
			if (!model.stateModel.fam_dialog_open) return;
			/*
			//if there happens to be a convo waiting, let's handle this
			if(FamiliarDialog.instance.current_panel_name == FamiliarDialog.SKILL_LEARNED && model.worldModel.pc.familiar.messages > 0){
				//TEMP FIX FOR SKILL WINDOW NOT BEING ABLE TO BE CLOSED WHEN A QUEST IS CUED UP
				//TODO Allow a convo to follow up afterwards... Where are these convos stored?
				model.stateModel.fam_dialog_open = false;
				model.stateModel.fam_dialog_conv_is_active = false;
				model.worldModel.pc.familiar.messages = 0;
				
				doEndFamiliarDialog(doneFunc);
				
				return;
			}
			*/
			// if a convo is active we have to send the choicesDialog away properly
			if (model.stateModel.fam_dialog_conv_is_active) {
				ChoicesDialog.instance.goAway();
			}
			
			// check and see if there is anything qd up for the dialog before closing it

			// I'm not happy about these setTimeouts, but otherwise the bug with the ChoicesDialog textField height comes up.
			// plus, this make it a little nicer in terms of flow
			if (model.stateModel.fam_dialog_conv_payload_q.length) {
				StageBeacon.setTimeout(tryFamiliarConversation, 2000);
				doEndFamiliarDialog(doneFunc);
				
			} else if (model.worldModel.pc.familiar.messages > 0) {				
				StageBeacon.setTimeout(maybeTalkToFamiliar, 2000);
				doEndFamiliarDialog(doneFunc);
				
			} else if (model.stateModel.fam_dialog_skill_payload_q.length) {
				FamiliarDialog.instance.startWithPanel(FamiliarDialog.SKILL_LEARNED);
				
			} else {
				doEndFamiliarDialog(doneFunc);
			}
		}
		
		private function doEndFamiliarDialog(doneFunc:Function = null):void {
			model.stateModel.fam_dialog_open = false;
			changeTeleportDialogVisibility();
			if (model.stateModel.screen_view_q.length) {
				StageBeacon.setTimeout(tryShowScreenViewFromQ, 2000);
			}
			FamiliarDialog.instance.end(true);
			if (doneFunc != null) doneFunc();
		}
		
		private function tryFamiliarConversation(event:TimerEvent=null):void {
			//if there are things in the queue, try and do em
			/*CONFIG::debugging {
				Console.info('tryFamiliarConversation '+model.stateModel.fam_dialog_conv_payload_q.length);
			}*/
			if(model.stateModel.fam_dialog_conv_payload_q.length > 0){
				if(startFamiliarConversationWithPayload(model.stateModel.fam_dialog_conv_payload_q.shift())){
					//we are golden! kill the timer and let this thing do what it needs to do
					model.stateModel.familiar_retry_timer.stop();
					/*CONFIG::debugging {
						Console.info('familiar_retry_timer.stop doing');
					}*/
				}
			}
			//nothing there, stop the timer
			else {
				model.stateModel.familiar_retry_timer.stop();
				/*CONFIG::debugging {
					Console.info('familiar_retry_timer.stop nothing');
				}*/
			}
		}
		
		public function afterUnacceptableSecondsWaitingForLoginStart():void {
			Benchmark.addCheck('TSFC.afterUnacceptableSecondsWaitingForLoginStart');
			if (EnvironmentUtil.getUrlArgValue('SWF_fake_no_login') != '1') {
				BootError.handleError('Extremely slow login_start rsp:\n'+getSocketReadReport(), new Error('Extremely slow login_start rsp'), ['bootstrap','socket'], true);
			}
		}
		
		public function afterAFewSecondsWaitingForLoginStart():void {
			Benchmark.addCheck('TSFC.afterAFewSecondsWaitingForLoginStart');
		}
		
		CONFIG::locodeco private function loadLocationAMF(amf:Object):void {
			// only update vars that locodeco touched and rebuild
			const location:Location = model.worldModel.location;
			Location.updateFromAnonymous(amf, location);
			
			// rebuild the location
			LocationCommands.rebuildLocation();
			resnapMiniMap();
			
			// start editing again
			LocoDecoSWFBridge.instance.loadCurrentLocationModel();
		}
		
		CONFIG::locodeco public function revertLocoDecoChanges():void {
			if (model.stateModel.editing_unsaved) {
				var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
				cdVO.callback =	function(value:*):void {
					if (value == 'yes') {
						loadLocationAMF(UndoPoint(model.worldModel.location_undoA[0]).amf);
						model.worldModel.location_undoA.length = 0;
						model.stateModel.editing_unsaved = false;
						pushUndo(LocoDecoSWFBridge.UNDO_REVERT);
						growl('Location reverted to last save');
					}
				}
				cdVO.txt = 'Throw away all your work?';
				cdVO.choices = [
					{value: 'yes', label: 'Yes, with certainty.'},
					{value: 'no', label: 'Nay'}
				];
				cdVO.escape_value = 'no';
				confirm(cdVO);
			} else {
				growl('Nothing to revert!');
			}
		}
		
		/** Push an undo onto the stack and tell LD a change was (will be) made */
		CONFIG::locodeco public function pushUndo(type:String):void {
			const undoStack:Array = model.worldModel.location_undoA;
			
			// serialize everything
			const amf:Object = model.worldModel.location.AMF();
			const undo:UndoPoint = new UndoPoint();
			undo.amf = amf;
			undo.type = type;
			undoStack.push(undo);
			
			model.stateModel.editing_unsaved = (undoStack.length > 1);
		}
		
		/** Pop an undo from the stack and (maybe) load it into the game */
		CONFIG::locodeco public function popUndo(loadUndo:Boolean):void {
			const undo:UndoPoint = UndoPoint(model.worldModel.location_undoA.pop());
			if (undo) {
				if (model.worldModel.location_undoA.length == 1) model.stateModel.editing_unsaved = false;
				if (loadUndo) {
					// compare current AMF to previous AMF
					const amf:Object = model.worldModel.location.AMF();
					if (ObjectUtil.makeSignatureForHash(undo.amf) != ObjectUtil.makeSignatureForHash(amf)) {
						loadLocationAMF(undo.amf);
					}
				}
			}
		}
		
		CONFIG::locodeco public function saveLocoDecoChanges():void {
			if (model.stateModel.editing_unsaved) {
				model.stateModel.editing_saving_changes = true;
				
				resnapMiniMap();
				
				// heal everything before saving
				instance.controllerMap.physicsController.healGeometry();
				
				const amf:Object = model.worldModel.location.AMF();
				const physics:Object = model.worldModel.physics_obs[model.worldModel.location.tsid];
				
				saveLocation(amf, physics, function(success:Boolean):void {
					model.stateModel.editing_saving_changes = false;
					if (success) {
						model.worldModel.location_undoA.length = 0;
						model.stateModel.editing_unsaved = false;
						pushUndo(LocoDecoSWFBridge.UNDO_REVERT);
					} else {
						// model.stateModel.editing_unsaved = true; // implied, I think, but will leave the state alone just in case
					}
				});
			} else {
				growl('Nothing to save!');
			}
		}
		
		CONFIG::god public function saveLocation(amf:Object, physics:Object, callBack:Function):void {
			locodecoGrowl("Saving Location... please wait!");
			
			if (model.flashVarModel.only_mg) {
				locodecoGrowl('LOCATION COULD NOT BE SAVED BECAUSE model.flashVarModel.only_mg=' + model.flashVarModel.only_mg);
				callBack(false);
				return;
			}
			
			amf.physics = physics;
			
			genericSend(
				new NetOutgoingLocationLockRequestVO(),
				
				// called if we get a lock
				function(rm:NetResponseMessageVO):void {
					
					// we got a lock
					growl('LOCK RECEIVED');
					
					//now send the edit_location msg;
					genericSend(
						new NetOutgoingEditLocationVO(amf),
						
						// called if the save is successful
						function(rm:NetResponseMessageVO):void {
							// the save was succeful
							locodecoGrowl("Location saved!\n(don't forget to resnap!)");
							model.stateModel.loc_saved_but_not_snapped = true;
							callBack(true);
						},
						
						// called if the save fails
						function(rm:NetResponseMessageVO):void {
							var err_msg:String = 'UNKNOWN ERROR';
							if (rm.payload.error) {
								err_msg = 'ERROR: code:'+rm.payload.error.code+' msg:'+rm.payload.error.msg
							}
							locodecoGrowl('LOCATION COULD NOT BE SAVED: ' + err_msg);
							if (model.stateModel.editing) growl('NOT RELEASING LOCK (BECAUSE YOU ARE EDITING THE LOCATION)');
							
							callBack(false);
						}
					);
					
					if (model.stateModel.editing) {
						//growl('NOT RELEASING LOCK (BECAUSE YOU ARE EDITING THE LOCATION)');
					} else {
						// release the lock
						genericSend(
							new NetOutgoingLocationLockReleaseVO(),
							function(rm:NetResponseMessageVO):void {
								growl('LOCK RELEASED');
							},
							function(rm:NetResponseMessageVO):void {
								locodecoGrowl('COULD NOT RELEASE LOCK!');
							}
						);
						callBack(false);
					}
					
				},
				
				// called if we could not get a lock
				function(rm:NetResponseMessageVO):void {
					locodecoGrowl('COULD NOT GET LOCK');
					callBack(false);
				}
			);
		}
		
		CONFIG::god private function locodecoGrowl(str:String):void {
			AnnouncementController.instance.cancelOverlay('location_saved_msg');
			model.activityModel.announcements = Announcement.parseMultiple([{
				type: "vp_overlay",
				dismissible: false,
				locking: false,
				click_to_advance: false,
				text: ['<p align="center"><span class="nuxp_big">' + str + '</span></p>'],
				x: '50%',
				y: '50%',
				duration: 1500,
				width: Math.max(model.layoutModel.min_vp_w-100, model.layoutModel.loc_vp_w-200),
				uid: 'location_saved_msg',
				bubble_god: true,
				allow_in_locodeco: true
			}]);
		}
		
		CONFIG::god public function openGeoForLocation(event:TSEvent = null):void {
			const url:String = model.flashVarModel.root_url+'god/world_street.php?tsid='+model.worldModel.pc.location.tsid;
			navigateToURL(new URLRequest(url), URLUtil.getTarget('loc'));
		}
		
		CONFIG::god public function openItemsForLocation(event:TSEvent = null):void {
			const url:String = model.flashVarModel.root_url+'god/world_street_items.php?tsid='+model.worldModel.pc.location.tsid;
			navigateToURL(new URLRequest(url), URLUtil.getTarget('loc'));
		}
		
		CONFIG::god public function showPlatformLinesEtc(event:TSEvent = null):void {
			getMainView().gameRenderer.locationView.middleGroundRenderer.showPlatformLinesEtc();
			getMainView().gameRenderer.locationView.middleGroundRenderer.showBoxes();
			getMainView().gameRenderer.locationView.middleGroundRenderer.showTargets();
			getMainView().gameRenderer.locationView.middleGroundRenderer.showCTBoxes();
		}
		
		CONFIG::god public function hidePlatformLinesEtc(event:TSEvent = null):void {
			getMainView().gameRenderer.locationView.middleGroundRenderer.hidePlatformLinesEtc();
			getMainView().gameRenderer.locationView.middleGroundRenderer.hideBoxes();
			getMainView().gameRenderer.locationView.middleGroundRenderer.hideTargets();
			getMainView().gameRenderer.locationView.middleGroundRenderer.hideCTBoxes();
		}
		
		public function reportConfirm(success:Boolean, case_id:String=''):void {
			var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
			cdVO.escape_value = false;
			
			if (success) {
				cdVO.title = 'Reported!';
				cdVO.txt = 'Thanks for taking the time to make this report.';
				if (case_id && !model.flashVarModel.is_stub_account) {
					cdVO.txt+= ' This case will be listed at '
						+'<b>'+model.flashVarModel.root_url+'help/</b> if you want to update it at any time. Would you like to open '
						+'the help case page now?';
					cdVO.choices = [
						{value: true, label: 'Yes please'},
						{value: false, label: 'No thanks'},
					];
				} else {
					cdVO.choices = [
						{value: false, label: 'OK'},
					];
				}
				
				cdVO.callback =	function(value:*):void {
					if (value == true) {
						openHelpCasePage(null, case_id);
					}
				}
			} else {
				cdVO.title = 'Report Failed!'
				cdVO.txt = 'We\'re looking into the problem.';
				cdVO.choices = [
					{value: true, label: 'OK'}
				];
			}
			
			confirm(cdVO);
		}
		
		private function reportAbuse(report:String, pc_tsid:String=''):void {
			var title:String = 'USER REPORTED ABUSE'; // this string is important to how the API processes the report DO NOT CHANGE
			var pc:PC = model.worldModel.getPCByTsid(pc_tsid);
			var logs:String = '';
			if (pc_tsid) title+= ' INVOLVING '+pc_tsid;
			if (pc) {
				title+= ' ('+pc.label+')';
				logs+= '\n\nALL CHATS THAT HAVE "'+pc.label+'" in them:'+RightSideManager.instance.getContentsOfAllChatsThatReferenceStr(pc.label);
			} else {
				logs+= '\n\nALL CHATS:'+RightSideManager.instance.getContentsOfAllChatsThatReferenceStr();
			}
			
			API.reportAbuse(title+logs, title+': '+report, pc_tsid, function(success:Boolean, ret_error_id:String, ret_case_id:String):void {
				if (success) {
					var id_was_visible:Boolean;
					if (InputDialog.instance.visible) {
						id_was_visible = true;
						InputDialog.instance.visible = false;
					}
					
					API.attachErrorImageToError(ret_error_id, getMainView(), function(ok:Boolean, txt:String = ''):void {
						CONFIG::debugging {
							Console.warn(ok+' '+txt);
						}
					});
					if (id_was_visible) {
						InputDialog.instance.visible = true;
					}
				}
				reportConfirm(success, ret_case_id);
			});
		}
		
		public function joinPartySpace(tsid:String=''):void {
			genericSend(new NetOutgoingPartySpaceJoinVO(), null, function(rm:NetResponseMessageVO):void {
				var txt:String = 'Joining the party space failed';
				if (rm.payload.error && rm.payload.error.msg) {
					txt+= ': '+rm.payload.error.msg;
				} else {
					txt+= '.';
				}
				growl(txt);
			});
		}
		
		public function startReportAbuseFromChat(tsid:String=''):void {
			if (model.worldModel.getPCByTsid(tsid)) {
				startReportAbuseDialog(tsid);
			} else {
				startReportAbuseDialog();
			}
		}
		
		public function startReportAbuseDialog(pc_tsid:String=''):void {
			var payload:Object = {
				title:'Report Abuse',
				subtitle:'Let us know about any unacceptable behavior you see in the game.',
				input_text_size: 'small',
				input_focus: true,
				input_rows:18,
				cancel_label: 'cancel', // default = 'Cancel'
				submit_label: 'report', // default = 'Submit'
				input_label: 'Your report:', // default = ''
				pc_tsid: pc_tsid,
				handler: function(payload:Object, report:String):void {
					reportAbuse(report, (payload) ? payload.pc_tsid : '');
				}
			};
			
			var pc:PC = model.worldModel.getPCByTsid(pc_tsid);
			
			if (pc) {
				payload.input_description = 'You are reporting abuse from <b>'+pc.label+'</b>. Please provide as much detail as you can.';
			} else {
				payload.input_description = 'If you are reporting abuse for a specific individual, please first close this window and ' +
					'if possible click on their name in a chat or on their avatar and choose "Report / Block" from the ' +
					'menu. Otherwise, enter your report below with as much detail as you can.';
			}
			
			InputDialog.instance.startWithPayload(payload);
		}
		
		public function startCabinetDialog(payload:Object):void {
			if (CabinetManager.instance.start(payload)) {
				disableDropToFloor();
			}
		}
		
		public function cabinetDialogEnded():void {
			enableDropToFloor();
		}
		
		public function startItemstackConfig(payload:Object):void {
			if (!payload.itemstack_tsid) return;
			
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(payload.itemstack_tsid);
			if (!itemstack) return;
			
			var liv:LocationItemstackView = getMainView().gameRenderer.getItemstackViewByTsid(itemstack.tsid);
			if (!liv) return;
			
			ItemstackConfigDialog.instance.startWithItemstack(itemstack.tsid);
		}
		
		public function startFurnitureUpgrade(payload:Object):void {
			if (HandOfDecorator.instance.startFurnitureUpgrade(payload)) {
				disableDropToFloor();
			}
		}
		
		public function furnitureUpgradeEnded():void {
			enableDropToFloor();
		}
		
		public function startTrophyDialog(payload:Object):void {
			if (TrophyCaseManager.instance.start(payload)) {
				disableDropToFloor();
			}
		}
		
		public function trophyDialogEnded():void {
			enableDropToFloor();
		}
		
		public function startTradeDialog(payload:Object):void {
			if (TradeManager.instance.start(payload)) {
				disableDropToFloor();
			}
		}
		
		public function tradeDialogEnded():void {
			enableDropToFloor();
		}
		
		public function enableDropToFloor():void {
			//don't let dragging items fall off dialogs (or don't allow dragging at all in the main view)
			controllerMap.viewController.tsMainView.gameRenderer.accepting_drags = true;
			CONFIG::debugging {
				Console.trackValue('TSFC gameRenderer.accepting_drags', controllerMap.viewController.tsMainView.gameRenderer.accepting_drags);
			}
		}
		
		public function disableDropToFloor():void {
			//don't let dragging items fall off dialogs (or don't allow dragging at all in the main view)
			controllerMap.viewController.tsMainView.gameRenderer.accepting_drags = false;
			CONFIG::debugging {
				Console.trackValue('TSFC gameRenderer.accepting_drags', controllerMap.viewController.tsMainView.gameRenderer.accepting_drags);
			}
		}
		
		public function startLoadingLocationProgress(txt:String = ''):void {
			/*CONFIG::debugging {
				Console.log(945, 'startLoadingLocation from '+StringUtil.getCallerCodeLocation());
			}*/
			//start the bar on the loading screen
			LoadingLocationView.instance.resetProgress(txt);
		}
		
		public function updateLoadingLocationProgress(perc:Number):void {
			//update the bar on the loading screen
			/*Console.warn(perc);
			
			if (perc==1) {
				Console.error(perc)
			}*/
			LoadingLocationView.instance.updateProgress(perc);
		}
		
		public function initiateShutDownSequence(secs:int):void {
			if(!model.worldModel || !model.worldModel.pc) return;
			
			//send them some reminders every once and a while
			var messages:Array = new Array(
				"Have you finished up yet?!",
				"We are shutting things down here folks...",
				"Things will be going away in "+TimedGrowls.CURRENT_SECONDS+" seconds!",
				"Oh wow, you're still here?! Get a move on lil' doggy!",
				"Shutting down in "+TimedGrowls.CURRENT_SECONDS+" seconds!"
			);
			
			if (CONFIG::god) {
				SoundMaster.instance.testSound('GOODNIGHT_GRODDLE',true);
				//SoundMaster.instance.playSound('trumpet', 9);
				model.activityModel.god_message = 'The world is going away in '+secs+' seconds.';
				messages.push(
					"Pack it up! Shutting down in "+TimedGrowls.CURRENT_SECONDS+" seconds!",
					"Man Goat says 'Baaaaaaad God'"
				);
			} else {
				SoundMaster.instance.testSound('GOODNIGHT_GRODDLE',true);
				//SoundMaster.instance.playSound('trumpet', 1);
				model.activityModel.god_message = 'Server shutdown in '+secs+' seconds!';
			}
			
			messages.push('*poof*');
			
			//show a player buff that reminds them the server is shutting down
			model.worldModel.pc.buffs['server_shutdown'] = PCBuff.fromAnonymous({
				duration: secs,
				is_timer: true,
				name: "Shutdown",
				ticks: null,
				tsid: 'server_shutdown',
				item_class: 'npc_crab'
			}, 'server_shutdown');
			model.worldModel.buff_adds = ['server_shutdown'];
			
			//send them some reminders every once and a while
			var timedGrowls:TimedGrowls = new TimedGrowls(messages,	secs);
			timedGrowls.start();
			
			//dismiss the buff when we are done with it
			StageBeacon.setTimeout(function():void {
				model.worldModel.buff_dels = ['server_shutdown'];
			}, secs*1000);
		}
		
		public function showDoorUnlocked(door_tsid:String, relock:Boolean):Boolean {
			var doorView:DoorView = controllerMap.viewController.tsMainView.gameRenderer.getDoorViewByTsid(door_tsid);
			if (!doorView) return false;
			var did_it:Boolean = doorView.unlock();
			
			if (did_it && relock) {
				StageBeacon.setTimeout(doorView.relock, 2000)
			}
			
			return did_it;
		}
		
		// we shoudl really be doing with with lockers, so it can be done by more than one part of the code safely
		public function disableLocationInteractions():void {
			model.stateModel.location_interactions_disabled = true;
			var game_renderer:LocationRenderer = getMainView().gameRenderer;
			game_renderer.locationView.middleGroundRenderer.unglowAllInteractionSprites();
			game_renderer.disableItemstackBubbles();
			
			game_renderer.locationView.middleGroundRenderer.mouseEnabled = false;
			game_renderer.locationView.middleGroundRenderer.mouseChildren = false;
		}
		
		public function enableLocationInteractions():void {
			model.stateModel.location_interactions_disabled = false;
			var game_renderer:LocationRenderer = getMainView().gameRenderer;
			game_renderer.enableItemstackBubbles();
			
			
			game_renderer.locationView.middleGroundRenderer.mouseEnabled = true;
			game_renderer.locationView.middleGroundRenderer.mouseChildren = true;
		}
		
		public function changeAvatarVisibility():void {
			const tsmv:TSMainView = getMainView();
			if (tsmv && tsmv.gameRenderer) {
				const avatarView:AvatarView = getMainView().gameRenderer.getAvatarView();
				if (avatarView) avatarView.showHide();
			}
		}
		
		public function changeDecoSignText(deco_id:String, txt:String, css_class:String):void {
			if (!getMainView()) return;
			if (!getMainView().gameRenderer) return;
			
			var deco_renderer:DecoRenderer = getMainView().gameRenderer.getDecoRendererByTsid(deco_id);
			if (!deco_renderer) deco_renderer = getMainView().gameRenderer.getDecoRendererByName(deco_id);
			if (!deco_renderer) return;
			
			if (css_class) deco_renderer.deco.sign_css_class = css_class;
			deco_renderer.deco.sign_txt = txt;
			deco_renderer.syncRendererWithModel();
		}
		
		public function changeDecoVisibility(deco_id:String, visible:Boolean, fade_ms:Number):void {
			if (!getMainView()) return;
			if (!getMainView().gameRenderer) return;
			
			var deco_renderer:DecoRenderer = getMainView().gameRenderer.getDecoRendererByTsid(deco_id);
			if (!deco_renderer) deco_renderer = getMainView().gameRenderer.getDecoRendererByName(deco_id);
			if (!deco_renderer) return;
			
			fade_ms = (isNaN(fade_ms)) ? .4 : fade_ms/1000;
			
			if (visible) { // show it!
				if (!deco_renderer.visible) {
					TSTweener.addTween(deco_renderer, {_autoAlpha:1, time:fade_ms});
				}
			} else if (!visible) { // hide it!
				if (deco_renderer.visible) {
					TSTweener.addTween(deco_renderer, {_autoAlpha:0, time:fade_ms});
				}
			}
			
		}
		
		public function changeHubMapVisibility():void {
			if (model.moveModel.moving || !model.worldModel.location.show_hubmap) {
				HubMapDialog.instance.visible = false;
			} else {
				HubMapDialog.instance.visible = true;
			}
			
			// for the mag glass
			MiniMapView.instance.refresh();
		}
		
		public function changePackVisibility():void {
			PackDisplayManager.instance.reassesVisibility();
		}
		
		public function changeMiniMapVisibility():void {
			CONFIG::perf {
				if (model.flashVarModel.run_automated_tests) {
					MiniMapView.instance.hide();
					return;
				}
			}
			
			if (MiniMapView.instance.visible) {
				MiniMapView.instance.hide();
				BuffViewManager.instance.refresh();
				CONFIG::god {
					ViewportScaleSliderView.instance.hide();
				}
			}
			
			if (model.stateModel.editing || 
				(!model.stateModel.chassis_mode 
					&& model.worldModel.location.show_map 
					&& !model.moveModel.moving 
					&& !ImgMenuView.instance.parent 
					&& !model.stateModel.decorator_mode
					&& !model.stateModel.screen_view_open
				)) {
				MiniMapView.instance.show();
				MiniMapView.instance.refresh();
				BuffViewManager.instance.refresh();
				CONFIG::god {
					ViewportScaleSliderView.instance.show();
					ViewportScaleSliderView.instance.refresh();
				}
			}
		}
		
		public function changePCStatsVisibility():void {
			CONFIG::perf {
				// hide it all
				if (model.flashVarModel.run_automated_tests) {
					YouDisplayManager.instance.visible = false;
					BuffViewManager.instance.visible = false;
					StatBurstController.instance.paused = true;
					GrowlView.instance.visible = false;
					return;
				}
			}
			
			if (YouDisplayManager.instance.visible) {
				if (!model.worldModel.location.show_stats || 
					model.stateModel.editing || 
					model.stateModel.hand_of_god || 
					model.moveModel.moving || 
					model.stateModel.decorator_mode || 
					model.stateModel.chassis_mode || 
					model.stateModel.info_mode || 
					model.stateModel.cult_mode) {
					
					YouDisplayManager.instance.visible = false;
					BuffViewManager.instance.visible = false;
					StatBurstController.instance.paused = true;
				}
			} else {
				if (model.worldModel.location.show_stats && 
					!model.stateModel.editing && 
					!model.stateModel.hand_of_god && 
					!model.moveModel.moving && 
					!model.stateModel.decorator_mode && 
					!model.stateModel.chassis_mode && 
					!model.stateModel.info_mode && 
					!model.stateModel.cult_mode) {
					YouDisplayManager.instance.visible = true;
					BuffViewManager.instance.visible = true;
					StatBurstController.instance.paused = false;
				}
			}
		}
		
		public function changeTeleportDialogVisibility():void {
			YouDisplayManager.instance.changeTeleportDialogVisibility();
		}
		
		public function showLocationCheckListView():void {
			GrowlView.instance.visible = false;
			LocationCheckListView.instance.visible = true;
		}
		
		public function hideLocationCheckListView():void {
			GrowlView.instance.visible = true;
			if (LocationCheckListView.instance.visible) {
				LocationCheckListView.instance.visible = false;
				LocationCheckListView.instance.clearListItems();
			}
		}
		
		public function changeStatusBubbleVisibility():void {
			CONFIG::perf {
				if (model.flashVarModel.run_automated_tests) {
					model.stateModel.tend_verb_status_bubbles_disabled = true;
					return;
				}
			}
			
			model.stateModel.tend_verb_status_bubbles_disabled = 
				!model.worldModel.location.show_status_bubbles ||
				model.stateModel.editing || 
				model.stateModel.hand_of_god || 
				model.stateModel.cult_mode;
		}
		
		public function refreshDoorInAllViews(door:Door):void {
			var doorView:DoorView = getMainView().gameRenderer.getDoorViewByTsid(door.tsid);
			if (!doorView) return;
			getMainView().gameRenderer.dirtyDoorViews.push(doorView);
			controllerMap.physicsController.onDoorModified(door);
		}
		
		public function refreshSignPostInAllViews(signpost:SignPost):void {
			var signpostView:SignpostView = getMainView().gameRenderer.getSignpostViewByTsid(signpost.tsid);
			if (!signpostView) return;
			getMainView().gameRenderer.dirtySignpostViews.push(signpostView);
			MiniMapView.instance.maybeAddSignpost(signpost);
			HubMapDialog.instance.changeSignpostVisibility(signpost);
		}
		
		private var tip_lockers:Object = {};
		public function changeTipsVisibility(enable:Boolean, locker_str:String):void {
			if (!locker_str) return;
			if (enable) {
				delete tip_lockers[locker_str];
				var c:int = 0;
				for (var k:String in tip_lockers) c++;
				if (c==0) TipDisplayManager.instance.resume();
			} else {
				tip_lockers[locker_str] = true;
				TipDisplayManager.instance.pause();
			}
		}
		
		public function changeLocationItemstackVisibility(tsid:String, visible:Boolean):void {
			if (!getMainView()) return;
			if (!getMainView().gameRenderer) return;
			
			var liv:LocationItemstackView = getMainView().gameRenderer.getItemstackViewByTsid(tsid);
			if (liv) liv.visible = visible;
		}
		
		public var emotion_tim:uint;
		public function setEmotionTimeout():void {
			if (emotion_tim) StageBeacon.clearTimeout(emotion_tim);
			emotion_tim = StageBeacon.setTimeout(clearPCEmotion, 3000);
		}
		
		private function clearPCEmotion():void {
			emotion_tim = 0;
			model.worldModel.pc.emotion = '';
		}
		
		public function playSurprisedAnimation():void {
			if (model.worldModel.pc.emotion == PC.SURPRISE) return;
			model.worldModel.pc.emotion = PC.SURPRISE;
			setEmotionTimeout();
		}
		
		public function playEmotionAnimation(em:String):void {
			if (em == PC.HAPPY) {
				playHappyAnimation();
				return;
			}
			if (em == PC.ANGRY) {
				playAngryAnimation();
				return;
			}
			if (em == PC.SURPRISE) {
				playSurprisedAnimation();
				return;
			}
			CONFIG::debugging {
				Console.error('unknwon emotion:'+em)
			}
		}
		
		public function playHappyAnimation():void {
			if (model.worldModel.pc.emotion == PC.HAPPY) return;
			model.worldModel.pc.emotion = PC.HAPPY;
			setEmotionTimeout();
		}
		
		public function playAngryAnimation():void {
			if (model.worldModel.pc.emotion == PC.ANGRY) return;
			model.worldModel.pc.emotion = PC.ANGRY;
			setEmotionTimeout();
		}
		
		private var do_tim:uint;
		public function playDoAnimation(ms:int = 0):void {
			model.worldModel.pc.doing = true;
			if (do_tim) StageBeacon.clearTimeout(do_tim);
			if (ms > 0) do_tim = StageBeacon.setTimeout(stopDoAnimation, ms);
		}
		
		public function stopDoAnimation():void {
			model.worldModel.pc.doing = false;
			if (do_tim) StageBeacon.clearTimeout(do_tim);
		}
		
		CONFIG::god public function toggleInteractWithAll():void {
			model.flashVarModel.interact_with_all = !model.flashVarModel.interact_with_all;
			if (model.flashVarModel.interact_with_all) {
				model.activityModel.growl_message = 'All items should now glow';
			} else {
				model.activityModel.growl_message = 'Items now glow only if they should, like the normal client';
			}
			
			// so that mousenabled gets set correctly
			var A:Array = [];
			for (var k:String in model.worldModel.location.itemstack_tsid_list) A.push(k);
			getMainView().gameRenderer.onLocItemstackUpdates(A);
		}
					
		public function toggleAFK():void {
			if (model.worldModel.pc.afk) {
				goNotAFK();
			} else {
				goAFK();
			}
		}
		
		public function goAFK():void {
			if (model.moveModel.moving) return;
			if (!model.worldModel.pc || model.worldModel.pc.afk) return;
			
			// do not allow the going of afk when there is no imagination menu, dude
			if (model.worldModel.location && model.worldModel.location.no_imagination) return;
			
			afk_sig.dispatch(true);
			
			model.worldModel.pc.afk = true;
			growl('You\'ve gone AFK');
			genericSend(new NetOutgoingAFKVO(true));
		}

		/** Resets the AFK timer and returns us from AFK if we're AFK */
		public function goNotAFK():void {
			// comes before the AFK check to tell the avatarController
			// to reset the AFK timer
			afk_sig.dispatch(false);
			
			if (!model.worldModel.pc || !model.worldModel.pc.afk) return;
			
			model.worldModel.pc.afk = false;
			growl('You\'ve returned from AFK');
			genericSend(new NetOutgoingAFKVO(false));
		}
		
		private var mood_emote_tim:int;
		private var mood_emote_do_another:Boolean;
		public function doEmote(emote:String):void {
			if (emote == Emotes.EMOTE_TYPE_HI) {
				if (mood_emote_tim) {
					mood_emote_do_another = false; // make this true if we want to q up another if you press 5 while already doing a hi
				} else {
					genericSend(new NetOutgoingEmoteVO(emote));
					mood_emote_tim = StageBeacon.setTimeout(function():void {
						mood_emote_tim = 0;
						if (mood_emote_do_another) doEmote(emote);
						mood_emote_do_another = false;
					}, 2000);
				}
			}
		}
		
		/** convenience function to add listeners for zoom */
		public function startListeningToZoomKeys(func:Function):void {
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMBER_0, func);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMPAD_0, func);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.MINUS, func);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.MINUS, func);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMPAD_SUBTRACT, func);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.NUMPAD_SUBTRACT, func);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.EQUAL, func);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.EQUAL, func);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMPAD_ADD, func);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.NUMPAD_ADD, func);
		}
		
		/** convenience function to remove listeners for zoom */
		public function stopListeningToZoomKeys(func:Function):void {
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMBER_0, func);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMPAD_0, func);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.MINUS, func);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.MINUS, func);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMPAD_SUBTRACT, func);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.NUMPAD_SUBTRACT, func);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.EQUAL, func);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.EQUAL, func);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMPAD_ADD, func);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.NUMPAD_ADD, func);
		}
		
		/** Central zoom handler referenced in a lot of places */
		public function zoomKeyHandler(e:KeyboardEvent):void {
			if (model.stateModel.focus_is_in_input) return;
			if (!model.worldModel.location.allow_zoom) return;
			
			if ((e.keyCode == Keyboard.NUMBER_0) || (e.keyCode == Keyboard.NUMPAD_0)) {
				resetViewportScale(model.flashVarModel.auto_zoom_ms, true);
			} else {
				const zoomIn:Boolean = ((e.keyCode == Keyboard.EQUAL) || (e.keyCode == Keyboard.NUMPAD_ADD));
				var scale:Number = MathUtil.clamp(
					model.flashVarModel.min_zoom,
					model.flashVarModel.max_zoom,
					(model.layoutModel.loc_vp_scale + (zoomIn ? 1 : -1) * model.flashVarModel.zoom_step));
				setViewportScale(scale, 0, true);
			}
			
			CONFIG::god {
				ViewportScaleSliderView.instance.refresh();
			}
		}
		
		public function setViewportScale(scale:Number, time:Number, playSingleClick:Boolean = false, playMultiClick:Boolean = false, obeyLocationZoomLimits:Boolean = true):Number {
			if (obeyLocationZoomLimits) {
				var neg:Boolean = scale < 0;
				// clamp to allowed range
				scale = MathUtil.clamp(model.layoutModel.min_loc_vp_scale, model.layoutModel.max_loc_vp_scale, Math.abs(scale));
				if (neg) scale*= -1;
			}
			
			// round scale to an even hundredth decimal place,
			// fewer visual artifacts that way...
			scale = Math.round(scale * 100);
			scale += (scale % 2);
			scale /= 100;
			
			if (model.layoutModel.loc_vp_scale == scale) return scale;
			
			if (playSingleClick) SoundMaster.instance.playSound('TOGGLE_VIEWPORT_SCALE_ONE_CLICK');
			if (playMultiClick) SoundMaster.instance.playSound('TOGGLE_VIEWPORT_SCALE_THREE_CLICKS');
			
			const mainView:TSMainView = getMainView();
			const previousCacheAsBitmap:Boolean = mainView.gameRenderer.cacheAsBitmap;
			TSTweener.removeTweens(model.layoutModel, 'loc_vp_scale');
			TSTweener.addTween(model.layoutModel, {loc_vp_scale:scale, transition:'easeoutquad', time:time,
				onStart:function():void {
					// bitmap caching off
					mainView.gameRenderer.cacheAsBitmap = false;
				},
				onUpdate: mainView.refreshViews,
				onComplete:function():void {
					// bitmap caching on
					mainView.gameRenderer.cacheAsBitmap = previousCacheAsBitmap;
				}
			});
			
			return scale;
		}
		
		public function resetViewportScale(time:Number, playSound:Boolean = false):void {
			setViewportScale(model.flashVarModel.vp_scale, time, false, playSound);
		}
		
		public function setViewportOrientation(orientation:String):void {
			model.layoutModel.loc_vp_orientation = orientation;
			getMainView().refreshViews();
		}
		
		public function resetViewportOrientation():void {
			setViewportOrientation(LayoutModel.ORIENTATION_DEFAULT);
		}
		
		private var hit_tim:uint;
		public function playHitAnimation(hit:String, ms:int = 0):void {
			model.worldModel.pc.hit = hit;
			
			stopAvatarKeyControl('TSFC.playHitAnimation');
			
			// stop the fucker outright
			model.worldModel.pc.apo.triggerResetVelocityX = true;
			
			if (hit_tim) StageBeacon.clearTimeout(hit_tim);
			if (ms > 0) hit_tim = StageBeacon.setTimeout(stopHitAnimation, ms);
		}
		
		public function stopHitAnimation():void {
			model.worldModel.pc.hit = '';
			maybeStartAvatarKeyControl('TSFC.stopHitAnimation');
		}
		
		public function togglePackDisplayManagerFocus():void {
			if (!PackDisplayManager.instance.hasFocus()) {
				requestFocus(PackDisplayManager.instance);
			} else {
				releaseFocus(PackDisplayManager.instance);
			}
		}
		
		public function toggleQuestsDialog():void {
			if (QuestsDialog.instance.parent) {
				QuestsDialog.instance.end(true);
			} else {
				QuestsDialog.instance.start();
			}
		}
		
		public function toggleTeleportDialog():void {
			if (model.stateModel.fam_dialog_open) {
				if (FamiliarDialog.instance.current_panel_name != FamiliarDialog.CONVERSATION) {
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					endFamiliarDialog();
				} else {
					SoundMaster.instance.playSound('CLICK_FAILURE');
				}
			} else {
				if (model.stateModel.editing || model.moveModel.moving) {
					SoundMaster.instance.playSound('CLICK_FAILURE');
				} else {
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					startFamiliarDialog(FamiliarDialog.DEFAULT);
				}
			}
		}
		
		public function togglePlayerMenu():void {
			YouDisplayManager.instance.togglePlayerMenu();
		}
		
		public function screenViewClosed():void {
			model.stateModel.screen_view_open = false;
			CONFIG::debugging {
				Console.trackValue('TSFC screen_view_open', model.stateModel.screen_view_open);
			}
			
			StageBeacon.setTimeout(tryShowScreenViewFromQ, 500);
		}
		
		public function addToScreenViewQ(vo:ScreenViewQueueVO):void {
			model.stateModel.screen_view_q.push(vo);
			CONFIG::debugging {
				Console.trackValue('TSFC screen_view_q', model.stateModel.screen_view_q.length);
			}
			
			//listen to a timer that will keep trying to open the screen views if show() returns false
			if(!model.stateModel.screen_view_retry_timer.hasEventListener(TimerEvent.TIMER)){
				model.stateModel.screen_view_retry_timer.addEventListener(TimerEvent.TIMER, tryShowScreenViewFromQ, false, 0, true);
			}
			
			tryShowScreenViewFromQ();
		}
		
		private function tryShowScreenViewFromQ(event:TimerEvent = null):void {
			var bail:String = '';
			var vo:ScreenViewQueueVO = (model.stateModel.screen_view_q.length) ? model.stateModel.screen_view_q[0] : null;
			
			if (model.stateModel.editing) {
				bail = 'tryShowScreenViewFromQ bailing because editing';
			} else if (model.stateModel.hand_of_god) {
				bail = 'tryShowScreenViewFromQ bailing because hand_of_god';
			} else if (model.stateModel.chassis_mode) {
				bail = 'tryShowScreenViewFromQ bailing because chassis_mode';
			} else if (model.stateModel.info_mode) {
				bail = 'tryShowScreenViewFromQ bailing because info_mode';
			} else if (model.stateModel.cult_mode) {
				bail = 'tryShowScreenViewFromQ bailing because cult_mode';
			} else if (model.stateModel.decorator_mode) {
				bail = 'tryShowScreenViewFromQ bailing because decorator_mode';
			} else if (!StageBeacon.flash_has_focus && vo && vo.requires_client_focus) {
				bail = 'tryShowScreenViewFromQ bailing because !StageBeacon.flash_has_focus';
			} else if (model.stateModel.isCompInFocusHistory(CameraMan.instance)) {
				bail = 'tryShowScreenViewFromQ bailing because model.stateModel.isCompInFocusHistory(CameraMan.instance):'+model.stateModel.isCompInFocusHistory(CameraMan.instance);
			} else if (model.stateModel.isCompInFocusHistory(Cursor.instance)) {
				bail = 'tryShowScreenViewFromQ bailing because model.stateModel.isCompInFocusHistory(Cursor.instance):'+model.stateModel.isCompInFocusHistory(Cursor.instance);
			} else if (model.stateModel.isCompInFocusHistory(GlitchrSnapshotView.instance)) {
				bail = 'tryShowScreenViewFromQ bailing because model.stateModel.isCompInFocusHistory(GlitchrSnapshotView.instance):'+model.stateModel.isCompInFocusHistory(GlitchrSnapshotView.instance);
			} else if (model.stateModel.isCompInFocusHistory(GlitchrSavedDialog.instance)) {
				bail = 'tryShowScreenViewFromQ bailing because model.stateModel.isCompInFocusHistory(GlitchrSavedDialog.instance):'+model.stateModel.isCompInFocusHistory(GlitchrSavedDialog.instance);
			} else if (model.stateModel.isCompInFocusHistory(InteractionMenu.instance)) {
				bail = 'tryShowScreenViewFromQ bailing because model.stateModel.isCompInFocusHistory(InteractionMenu.instance):'+model.stateModel.isCompInFocusHistory(InteractionMenu.instance);
			} else if (model.stateModel.isCompInFocusHistory(GetInfoDialog.instance)) {
				bail = 'tryShowScreenViewFromQ bailing because model.stateModel.isCompInFocusHistory(GetInfoDialog.instance):'+model.stateModel.isCompInFocusHistory(GetInfoDialog.instance);
			} else if (model.stateModel.isCompInFocusHistory(ChoicesDialog.instance)) {
				bail = 'tryShowScreenViewFromQ bailing because model.stateModel.isCompInFocusHistory(ChoicesDialog.instance):'+model.stateModel.isCompInFocusHistory(ChoicesDialog.instance);
			} else if (model.stateModel.screen_view_open) {
				bail = 'tryShowScreenViewFromQ bailing because model.stateModel.screen_view_open:'+model.stateModel.screen_view_open;
			} else if (ImgMenuView.instance.parent) {
				bail = 'tryShowScreenViewFromQ bailing because ImgMenuView.instance.parent';
			} else if (model.stateModel.fam_dialog_open) {
				bail = 'tryShowScreenViewFromQ bailing because model.stateModel.fam_dialog_open:'+model.stateModel.fam_dialog_open;
			} else if (model.moveModel.moving) {
				bail = 'tryShowScreenViewFromQ bailing because moving';
			}  else if (model.stateModel.in_camera_control_mode) {
				bail = 'tryShowScreenViewFromQ bailing because model.stateModel.in_camera_control_mode=true';
			}
			
			CONFIG::perf {
				if (model.flashVarModel.run_automated_tests) {
					bail = 'tryShowScreenViewFromQ bailing because do_performance_tests';
				}
			}
			
			if(bail && model.stateModel.screen_view_q.length){
				//we need to start a timer so that when it doesn't bail, it'll show as soon as it can
				//Console.info('bailing on tryShowScreenViewFromQ b/c: '+bail);
								
				if(!model.stateModel.screen_view_retry_timer.running) model.stateModel.screen_view_retry_timer.start();
			}
			//if we don't need to bail, start flushing out the queue
			else if (model.stateModel.screen_view_q.length) {
				//actually remove the first screen in the queue
				vo = model.stateModel.screen_view_q.shift();
				if (vo.func(vo.arg)) {
					model.stateModel.screen_view_open = true;
					model.stateModel.screen_view_retry_timer.stop();
					CONFIG::debugging {
						Console.trackValue('TSFC screen_view_open', model.stateModel.screen_view_open);
					}
				} else {
					//put it back in first and wait for it to try again
					model.stateModel.screen_view_q.unshift(vo);
					if(!model.stateModel.screen_view_retry_timer.running) {
						model.stateModel.screen_view_retry_timer.start();
					}
				}
			} 
			//if we've made it down here there is nothing to show, so make sure to stop the timer
			else {
				model.stateModel.screen_view_retry_timer.stop();
			}
			
			//toggle the mini map
			changeMiniMapVisibility();
			
			CONFIG::debugging {
				Console.trackValue('TSFC screen_view_q', model.stateModel.screen_view_q.length);
			}
		}
		
		public function toggleHubMapDialog():void {
			if (HubMapDialog.instance.parent) {
				HubMapDialog.instance.end(true);
			} else {
				HubMapDialog.instance.start();
			}
		}
		
		 public function clearSingleInteractionSP():void {
			if (model.stateModel.single_interaction_sp) {
				model.stateModel.single_interaction_sp = null;
				CONFIG::debugging {
					Console.trackValue('TSFC single_interaction_sp', 'null');
				}
				YouDisplayManager.instance.updateKeyCmdsTf();
			}
		}
		
		public function setSingleInteractionSP(interaction_sp:TSSprite):void {
			if (!interaction_sp) return;
			if (model.stateModel.single_interaction_sp == interaction_sp) return;
			
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(interaction_sp.tsid);
			if (!itemstack) return;
			var item:Item = itemstack.item;
			
			var triggers_dic:Dictionary;
			var verbKeyGetter:Function;
			
			if (interaction_sp is LocationItemstackView) {
				if (!item.hasLocVerbKeyTriggers()) return;
				triggers_dic = item.loc_verb_key_triggers;
				verbKeyGetter = item.getLocVerbKeyTriggerByKeyCode;
			} else if (interaction_sp is PackItemstackView) {
				if (!item.hasPackVerbKeyTriggers()) return;
				triggers_dic = item.pack_verb_key_triggers;
				verbKeyGetter = item.getPackVerbKeyTriggerByKeyCode;
			} else {
				return;
			}
			
			var str:String = '';
			var vkt:VerbKeyTrigger;
			var verb:Verb;
			for (var key_code:String in triggers_dic) {
				vkt = verbKeyGetter(parseInt(key_code));
				verb = item.getVerbByTsid(vkt.verb_tsid);
				if (!itemstack.slots && (vkt.verb_tsid == Item.CLIENT_CLOSE || vkt.verb_tsid == Item.CLIENT_OPEN)) continue;
				
				if (str) str+= ', ';
				str+= '<b>'+vkt.key_str+'</b> -> '+((verb)?verb.label:vkt.verb_tsid);
			}
			
			if (str) {
				model.stateModel.single_interaction_sp = interaction_sp;
				CONFIG::debugging {
					Console.trackValue('TSFC single_interaction_sp', ObjectUtil.getClassName(model.stateModel.single_interaction_sp));
				}
				YouDisplayManager.instance.updateKeyCmdsTf('ADMIN KEYS: '+ item.label+': '+str);
			} else {
				clearSingleInteractionSP();
			}
		}
		
		public function triggerJump():void {
			controllerMap.avatarController.onSpaceKey();
		}
		
		public function applyKeyCodeToSingleInteractionSP(key_code:int):void {
			if (!model.flashVarModel.do_single_interaction_sp_keys) return;

			var single_interaction_sp:TSSprite = model.stateModel.single_interaction_sp;
			if (single_interaction_sp) {
				var item:Item = model.worldModel.getItemByItemstackId(single_interaction_sp.tsid);
				if (!item) return;
				var verb_tsid:String;
				if (model.stateModel.focused_component is TSMainView) {
					verb_tsid = item.getLocVerbTsidByKeyCode(key_code);
				} else if (model.stateModel.focused_component is PackDisplayManager) {
					verb_tsid = item.getPackVerbTsidByKeyCode(key_code);
				} else {
					return;
				}
				if (!verb_tsid) return;
				var itemstack:Itemstack = model.worldModel.getItemstackByTsid(single_interaction_sp.tsid);
				if (!itemstack) return;
				var verb:Verb = item.getVerbByTsid(verb_tsid); // we /might/ have it.
				
				if (!itemstack.slots && verb && verb.is_client && (verb.tsid == Item.CLIENT_CLOSE || verb.tsid == Item.CLIENT_OPEN)) {
					return;
				}
				
				growl('ADMIN: atemmmmmmmpting verb --> ' + item.tsid + '+' + verb_tsid);
				
				// not being optimistic anymore, calling everytime
				if (false && verb && verb.enabled) { 
					startItemstackMenuWithVerb(itemstack, verb, false);
				} else {
					genericSend(
						new NetOutgoingItemstackVerbMenuVO(itemstack.tsid),
						function(rm:NetResponseMessageVO):void {
							var verb:Verb = item.verbs[verb_tsid]; // conditional_verbs got updated in netcontroller by this msg rsp
							if (rm.success && verb && verb.enabled) { // we have the the Verb now
								if (single_interaction_sp && itemstack && single_interaction_sp.tsid == itemstack.tsid) { // single_interaction_sp has not changed
									startItemstackMenuWithVerb(itemstack, verb, false);
								}
							}
						},
						null
					);
					
				}
			}
		}
		
		public function startLocationDisambiguator(V:Vector.<TSSprite>):void {
			controllerMap.interactionMenuController.startLocationDisambiguator(V, InteractionMenuModel.TYPE_LOC_DISAMBIGUATOR);
		}
		
		public function startPcGiveMenuWithItemstack(pc_tsid:String, itemstack:Itemstack, by_click:Boolean = false):void {
			controllerMap.interactionMenuController.startPcGiveMenuWithItemstack(pc_tsid, itemstack, by_click);
		}
		
		public function startItemstackMenuWithVerb(itemstack:Itemstack, verb:Verb, by_click:Boolean = false):void {
			controllerMap.interactionMenuController.startItemstackMenuWithVerb(itemstack, verb, by_click)
		}
		
		public function startItemstackMenuWithVerbAndTargetItem(itemstack:Itemstack, verb:Verb, target_item:Item, target_itemstack:Itemstack, by_click:Boolean = false):void {
			controllerMap.interactionMenuController.startItemstackMenuWithVerbAndTargetItem(itemstack, verb, target_item, target_itemstack, by_click)
		}
		
		public function startItemstackMenu(itemstack_tsid:String, menu_type:String = '', by_click:Boolean = false):void {
			//default to the pack if nothing is passed in
			if(!menu_type) menu_type = InteractionMenuModel.TYPE_PACK_IST_VERB_MENU;
			controllerMap.interactionMenuController.startItemstackMenu(itemstack_tsid, menu_type, by_click);
		}
		
		public function startInteractionWith(interaction_sprite:DisplayObject, by_click:Boolean = false):void {
			if (!interaction_sprite) return;
			
			var IMC:InteractionMenuController = controllerMap.interactionMenuController;
			
			if (interaction_sprite is SignpostView) {
				const signpost_view:SignpostView = interaction_sprite as SignpostView;
				var signpost:SignPost = signpost_view.signpost;
				if (signpost.client::quarter_info){
					//open the multi-location chooser
					LocationSelectorDialog.instance.startWithSignpost(signpost);
				} else if(!signpost_view.edit_clicked){
					//standard signpost action, when the edit button hasn't been clicked
					signpost_view.tryFocus();
				}
				return;
			}
				
			if (interaction_sprite is DoorView) {
				const connect:LocationConnection = DoorView(interaction_sprite).door.connect;
				if (!connect) {
					growl('door lacks a connect object');
					return;
				}
				startLocationMove(false, MoveModel.DOOR_MOVE, DoorView(interaction_sprite).tsid, connect.street_tsid);
				return;
			}

			if (interaction_sprite is LadderView) {
				use namespace client;
				var lv:LadderView = LadderView(interaction_sprite);
				var ladder:Ladder = model.worldModel.location.mg.getLadderById(lv.tsid);
				if (ladder){
					getOnLadder(ladder);
				}
				return;
			}

			if (interaction_sprite is FurnitureBagItemstackView) {
				const fbiv:FurnitureBagItemstackView = interaction_sprite as FurnitureBagItemstackView;
				if (model.stateModel.info_mode) {
					CONFIG::god {
						if (KeyBeacon.instance.pressed(Keyboard.K)) {
							doVerb(fbiv.tsid, Item.CLIENT_DESTROY);
							return;
						}
					}
					
					if (fbiv.item.verbs[Item.CLIENT_INFO]) {
						doClientVerb(fbiv.tsid, fbiv.item.verbs[Item.CLIENT_INFO]);
					}
				} else {
					IMC.startItemstackMenu(
						fbiv.tsid, InteractionMenuModel.TYPE_PACK_IST_VERB_MENU, by_click
					);
				}
				return;
			}

			if (interaction_sprite is PackItemstackView) {
				const view_tsid:String = PackItemstackView(interaction_sprite).tsid;
				const itemstack:Itemstack = model.worldModel.getItemstackByTsid(view_tsid);
				
				if (model.stateModel.info_mode) {
					CONFIG::god {
						if (KeyBeacon.instance.pressed(Keyboard.K)) {
							doVerb(view_tsid, Item.CLIENT_DESTROY);
							return;
						}
					}
					if (itemstack.item.verbs[Item.CLIENT_INFO]) {
						doClientVerb(view_tsid, itemstack.item.verbs[Item.CLIENT_INFO]);
					}
				} else if(itemstack.slots){
					//if we clicked a container, toggle that sucker
					PackDisplayManager.instance.toggleContainer(view_tsid);
				}
				else {
					//regular item, do the normal thang
					IMC.startItemstackMenu(
						view_tsid, InteractionMenuModel.TYPE_PACK_IST_VERB_MENU, by_click
					);
				}
				return;
			}

			if (interaction_sprite is LocationItemstackView) {
				const liv:LocationItemstackView = interaction_sprite as LocationItemstackView;
				
				if (model.stateModel.info_mode) {
					CONFIG::god {
						if (KeyBeacon.instance.pressed(Keyboard.K)) {
							doVerb(liv.tsid, Item.CLIENT_DESTROY);
							return;
						}
					}
					if (liv.item.verbs[Item.CLIENT_INFO]) {
						doClientVerb(liv.tsid, liv.item.verbs[Item.CLIENT_INFO]);
					}
					return;
				}
				
				// hmm, acting like player is there with that true as last arg; not sure if this is the best way
				var pc_is_there:Boolean = true;
				if (tryAOneClickActionOnALIS(LocationItemstackView(interaction_sprite), by_click, pc_is_there)) {
					return;
				}
				IMC.startItemstackMenu(
					liv.tsid, InteractionMenuModel.TYPE_LOC_IST_VERB_MENU, by_click
				);
				return;
			}

			if (interaction_sprite is PCView && !model.worldModel.location.no_pc_interactions) {
				IMC.startPCMenu(
					PCView(interaction_sprite).tsid, InteractionMenuModel.TYPE_LOC_PC_VERB_MENU, by_click
				);
				return;
			}
		}
		
		public function tryAOneClickActionOnALIS(lis_view:LocationItemstackView, by_click:Boolean, act_like_pc_is_there:Boolean):Boolean {
			
			CONFIG::god {
				if (KeyBeacon.instance.pressed(Keyboard.P)) {
					// P click open edit props page
					doVerb(lis_view.tsid, Item.CLIENT_EDIT_PROPS);
					return true;
				}
			}
			
			CONFIG::god {
				if (KeyBeacon.instance.pressed(Keyboard.K)) {
					// K click destroys the itemstack
					doVerb(lis_view.tsid, Item.CLIENT_DESTROY);
					return true;
				}
			}
			
			if (lis_view.x > model.worldModel.pc.x) {
				getMainView().gameRenderer.getAvatarView().faceRight()
			} else if (lis_view.x < model.worldModel.pc.x) {
				getMainView().gameRenderer.getAvatarView().faceLeft()
			}
			
			//check for a garden
			if (lis_view.garden_view){
				if (lis_view.garden_view.is_owner && !by_click) {
					GardenManager.instance.startEditing(lis_view.tsid);
				}
				
				return true;
			}
			
			if (!model.stateModel.decorator_mode) {
				if (lis_view.item.oneclick_verb && (act_like_pc_is_there || lis_view.item.oneclick_verb.from_anywhere)) {
					genericSend(
						new NetOutgoingItemstackVerbMenuVO(lis_view.itemstack.tsid),
						function(rm:NetResponseMessageVO):void {
							var verb:Verb = lis_view.item.verbs[lis_view.item.oneclick_verb.tsid]; // conditional_verbs got updated in netcontroller by this msg rsp
							var target_item:Item = (verb && verb.target_item_class) ? model.worldModel.getItemByTsid(verb.target_item_class) : null;

							// we have the the Verb now
							if (rm.success && verb && verb.enabled) {
								if (target_item) {
									// the verb supplied a target item!
									controllerMap.interactionMenuController.startItemstackMenuWithVerbAndTargetItem(lis_view.itemstack, verb, target_item, null, by_click);
								} else {
									sendItemstackVerb(
										new NetOutgoingItemstackVerbVO(lis_view.itemstack.tsid, verb.tsid, 1)
									);
								}
							} else {
								if (model.stateModel.open_menu_when_one_click_is_disabled) {
									controllerMap.interactionMenuController.startItemstackMenu(
										lis_view.tsid, InteractionMenuModel.TYPE_LOC_IST_VERB_MENU, by_click
									);
								} else {
									// NOTE, THIS IS OBSOLETE, AS SDBS NO LONGER HAVE A ONECLICK VERB
									// special case this until we have dynamic oneclick verbs on stacks
									if (lis_view.item.tsid == 'bag_furniture_sdb') {
										verb = lis_view.item.verbs['deposit'];
										if (verb && verb.enabled) {
											sendItemstackVerb(
												new NetOutgoingItemstackVerbVO(lis_view.itemstack.tsid, verb.tsid, 1)
											);
										}
									}
								}
							}
						},
						null
					);
					return true;
				}
			}
			
			if (by_click && lis_view.item.oneclick_pickup_verb && !KeyBeacon.instance.pressed(Keyboard.SHIFT) ) {
				genericSend(
					new NetOutgoingItemstackVerbMenuVO(lis_view.itemstack.tsid),
					function(rm:NetResponseMessageVO):void {
						var verb:Verb = lis_view.item.verbs[lis_view.item.oneclick_pickup_verb.tsid]; // conditional_verbs got updated in netcontroller by this msg rsp
						
						// we have the the Verb now
						if (rm.success && verb && verb.enabled) {
							sendItemstackVerb(
								new NetOutgoingItemstackVerbVO(lis_view.itemstack.tsid, verb.tsid, lis_view.itemstack.count)
							);
						} else {
							controllerMap.interactionMenuController.startItemstackMenu(
								lis_view.tsid, InteractionMenuModel.TYPE_LOC_IST_VERB_MENU, by_click
							);
						}
					},
					null
				);
				return true;
			}
			
			return false;
		}
		
		public function registerMoveListener(listener:IMoveListener):Boolean {
			if (moveListenersV.indexOf(listener) == -1) {
				moveListenersV.push(listener);
				return true;
			}
			return false;
		}
		
		/** Removes specified listener if it has been added */
		public function removeMoveListener(listener:IMoveListener):Boolean {
			var listenerIndex:int = moveListenersV.indexOf(listener);
			if (listenerIndex == -1) {
				return false;
			}
			
			moveListenersV.splice(listenerIndex, 1);
			return true;
		}
		
		public function registerRenderListener(listener:IRenderListener):Boolean {
			if (renderListenersV.indexOf(listener) == -1) {
				renderListenersV.push(listener);
				return true;
			}
			return false;
		}
		
		/** Removes specified listener if it has been added */
		public function removeRenderListener(listener:IRenderListener):Boolean {
			var listenerIndex:int = renderListenersV.indexOf(listener);
			if (listenerIndex == -1) {
				return false;
			}
			
			renderListenersV.splice(listenerIndex, 1);
			return true;
		}
		
		public function locationHasChanged():void {
			CONFIG::debugging {
				Console.priinfo(945, 'calling moveLocationHasChanged on '+moveListenersV.length+' from '+StringUtil.getCallerCodeLocation());
			}
			for (var i:int=0;i<moveListenersV.length;i++) {
				moveListenersV[i].moveLocationHasChanged();
			}
		}
		
		public function locationAssetsAreReady():void {
			CONFIG::debugging {
				Console.priinfo(945, 'calling moveLocationAssetsAreReady on '+moveListenersV.length+' from '+StringUtil.getCallerCodeLocation());
			}
			for (var i:int=0;i<moveListenersV.length;i++) {
				moveListenersV[i].moveLocationAssetsAreReady();
			}
		}
		
		public function moveHasStarted():void {
			CONFIG::debugging {
				Console.priinfo(945, 'calling moveMoveStarted on '+moveListenersV.length+' from '+StringUtil.getCallerCodeLocation());
			}
			for (var i:int=0;i<moveListenersV.length;i++) {
				moveListenersV[i].moveMoveStarted();
			}
		}
		
		public function moveHasEnded():void {
			CONFIG::debugging {
				Console.priinfo(945, 'calling moveMoveEnded on '+moveListenersV.length+' from '+StringUtil.getCallerCodeLocation());
			}
			for (var i:int=0;i<moveListenersV.length;i++) {
				moveListenersV[i].moveMoveEnded();
			}
		}
		
		public function renderHasStarted():void {
			PerfLogger.stopLogging();
			
			CONFIG::debugging {
				Console.priinfo(945, 'calling renderingHasStarted on '+renderListenersV.length+' from '+StringUtil.getCallerCodeLocation());
			}
			for (var i:int=0;i<renderListenersV.length;i++) {
				renderListenersV[i].renderHasStarted();
			}
		}
		
		public function renderHasEnded():void {
			CONFIG::debugging {
				Console.priinfo(945, 'calling renderingHasEnded on '+renderListenersV.length+' from '+StringUtil.getCallerCodeLocation());
			}
			for (var i:int=0;i<renderListenersV.length;i++) {
				renderListenersV[i].renderHasEnded();
			}
			
			PerfLogger.startLogging();
		}
		
		/**
		 * Start the Refresh listener stuff. Whenever TSMainView calls it's refresh method, it'll 
		 * fire dispatchRefreshListeners to dispatch any of the subscribers
		 */		
		public function registerRefreshListener(listener:IRefreshListener):Boolean {
			if (refreshListenersV.indexOf(listener) == -1) {
				refreshListenersV.push(listener);
				return true;
			}
			return false;
		}
		
		public function unRegisterRefreshListener(listener:IRefreshListener):Boolean {
			const index:int = refreshListenersV.indexOf(listener);
			if (index != -1) {
				refreshListenersV.splice(index, 1);
				return true;
			}
			return false;
		}
		
		public function dispatchRefreshListeners():void {
			CONFIG::debugging {
				Console.priinfo(945, 'Dispatching '+refreshListenersV.length+' refresh listeners');
			}
			
			var i:int;
			for (i; i < refreshListenersV.length; i++) {
				refreshListenersV[int(i)].refresh();
			}
		}
		
		public function registerDisposableSpriteChangeSubscriber(subscriber:IDisposableSpriteChangeHandler, sp:DisposableSprite):void {
			if (controllerMap.viewController) controllerMap.viewController.registerDisposableSpriteChangeSubscriber(subscriber, sp);
		}
		
		public function unregisterDisposableSpriteChangeSubscriber(subscriber:IDisposableSpriteChangeHandler, sp:DisposableSprite = null):void {
			if (controllerMap.viewController) controllerMap.viewController.unregisterDisposableSpriteChangeSubscriber(subscriber, sp);
		}
		
		public function removeDisposableSprite(sp:DisposableSprite):void {
			if (controllerMap.viewController) controllerMap.viewController.removeDisposableSprite(sp);
		}
		
		public function isRegisteredWithDisposableSprite(subscriber:IDisposableSpriteChangeHandler, sp:DisposableSprite):Boolean {
			if (!controllerMap.viewController) return false;
			return controllerMap.viewController.isRegisteredWithDisposableSprite(subscriber, sp);
		}
		
		public function startDecoratorMode(event:Event = null):void {
			setDecoratorMode(true);
		}
		
		public function stopDecoratorMode(event:Event = null):void {
			setDecoratorMode(false);
		}
		
		private function setDecoratorMode(enable:Boolean):void {
			if (model.stateModel.editing || (model.stateModel.decorator_mode == enable)) {
				// already enabled
				return;
			} else if (!enable || model.stateModel.can_decorate) {
				// we're good!
			} else {
				CONFIG::god {
					growl('THIS IS NOT YOUR POL!!');
				}
				return;
			};
			
			var onceDoneFunc:Function = function():void {
				if (!enable) {
					HandOfDecorator.instance.end();
				}
				model.stateModel.decorator_mode = enable;
				getMainView().gameRenderer.showHideItemstacks(); // for hiding doors
				changePCStatsVisibility();
				changeTeleportDialogVisibility();
				changeMiniMapVisibility();
				
				genericSend(new NetOutgoingNoEnergyModeVO(enable));
			}
			
			if (enable) {
				CONFIG::god {
					stopHandOfGodMode();
				}
				endCameraManUserMode();
				stopCultMode();
				MakingDialog.instance.cancelIfNeeded()
					
				if (!HandOfDecorator.instance.start()) {
					growl('Decorator mode cannot start');
					return;
				}
				onceDoneFunc();
			} else {
				//hide the decorate toolbar
				YouDisplayManager.instance.hideDecorateToolbar();
				
				//when disabling we delay it so we can fade out the toolbar
				StageBeacon.setTimeout(onceDoneFunc, DecorateToolbarUI.FADE_OUT_MS + 100);
			}
		}
		
		public function startChassisMode():void {
			setChassisMode(true);
		}
		
		public function stopChassisMode(event:Event = null):void {
			setChassisMode(false);
		}
		
		private function setChassisMode(enable:Boolean):void {
			if (model.stateModel.editing || (model.stateModel.chassis_mode == enable)) {
				// already enabled
				return;
			}
			
			var onceDoneFunc:Function = function():void {
				if (!enable) {
					ChassisManager.instance.end();
				}
				model.stateModel.chassis_mode = enable;
				changePCStatsVisibility();
				changeTeleportDialogVisibility();
				changeMiniMapVisibility();
				
				genericSend(new NetOutgoingNoEnergyModeVO(enable));
			}
			
			if (enable) {
				CONFIG::god {
					stopHandOfGodMode();
				}
				endCameraManUserMode();
				MakingDialog.instance.cancelIfNeeded()
				
				if (!ChassisManager.instance.start()) {
					growl('Chassis mode cannot start');
					return;
				}
				onceDoneFunc();
			} else {
				//hide the decorate toolbar
				YouDisplayManager.instance.hideChassisToolbar();
				
				//when disabling we delay it so we can fade out the toolbar
				StageBeacon.setTimeout(onceDoneFunc, ChassisToolbarUI.FADE_OUT_MS + 100);
			}
		}

		public function startCultMode():void {
			setCultMode(true);
		}
		
		public function stopCultMode(event:Event = null):void {
			setCultMode(false);
		}
		
		private function setCultMode(enable:Boolean):void {
			if (model.stateModel.editing || (model.stateModel.cult_mode == enable)) {
				// already enabled
				return;
			}
			
			var onceDoneFunc:Function = function():void {
				if (!enable) {
					CultManager.instance.end();
					genericSend(new NetOutgoingCultivationModeEndedVO());
				}
				model.stateModel.cult_mode = enable;
				changePCStatsVisibility();
				changeTeleportDialogVisibility();
				changeStatusBubbleVisibility();
				if (model.stateModel.cult_mode) {
					endFamiliarDialog();
				}
				
				if (model.stateModel.isClassInFocusHistory(GardenView)) {
					GardenManager.instance.stopEditing();
				}
				
				genericSend(new NetOutgoingNoEnergyModeVO(enable));
			}
			
			if (enable) {
				CONFIG::god {
					stopHandOfGodMode();
				}
				endCameraManUserMode();
				stopDecoratorMode();
				MakingDialog.instance.cancelIfNeeded()
				
				if (!CultManager.instance.start()) {
					growl('Cult mode cannot start');
					return;
				}
				onceDoneFunc();
			} else {
				//hide the toolbar
				YouDisplayManager.instance.hideCultToolbar();
				
				//when disabling we delay it so we can fade out the toolbar
				StageBeacon.setTimeout(onceDoneFunc, CultToolbarUI.FADE_OUT_MS + 100);
			}
		}
		
		public function startInfoMode():void {
			setInfoMode(true);
		}
		
		public function stopInfoMode(event:Event = null):void {
			setInfoMode(false);
		}
		
		private function setInfoMode(enable:Boolean):void {
			if (model.stateModel.editing || (model.stateModel.info_mode == enable)) {
				// already enabled
				return;
			}
			
			if (enable) {
				CONFIG::god {
					stopHandOfGodMode();
				}
				
				model.stateModel.info_mode = enable;
				if (!InfoManager.instance.start()) {
					model.stateModel.info_mode = false;
					growl('Info mode cannot start');
					return;
				}
			} else {
				//hide the toolbar
				YouDisplayManager.instance.hideInfoToolbar();
			}
			
			//run things
			if (!enable) {
				InfoManager.instance.end();
			}
			model.stateModel.info_mode = enable;
			changePCStatsVisibility();
			changeTeleportDialogVisibility();
			if (model.stateModel.info_mode) {
				endFamiliarDialog();
			}
		}
		
		CONFIG::god public function startHandOfGodMode(event:Event = null):void {
			setHandOfGodMode(true);
		}
		
		CONFIG::god public function stopHandOfGodMode(check_for_item_scale_changes:Boolean=true):void {
			if (!model.stateModel.hand_of_god) return;
			if (!check_for_item_scale_changes || !HandOfGod.instance.promptForItemScaleChanged()) {
				setHandOfGodMode(false);
			}
		}
		
		CONFIG::god private function setHandOfGodMode(enable:Boolean):void {
			if (model.stateModel.editing || (model.stateModel.hand_of_god == enable)) return;
			
			if (enable) {
				stopDecoratorMode();
				stopChassisMode();
				stopCultMode();
				endCameraManUserMode();
				if (!HandOfGod.instance.start()) {
					growl('Hand of God cannot take start');
					return;
				}
			} else {
				HandOfGod.instance.end();
			}
			
			growl((enable ? 'Starting' : 'Stopping') + ' hand of god mode');
			model.stateModel.hand_of_god = enable;
			
			//mainView.handOfGodChangedHandler handles the hiding and showing of UI bits
		}
		
		CONFIG::locodeco public function startEditMode(event:Event = null):void {
			if (model.stateModel.render_mode.usesBitmaps) {
				growl('Editing not allowed when the bitmap renderer is used!');
			} else {
				setEditMode(true);
			}
		}
		
		CONFIG::locodeco public function stopEditMode(event:Event = null):void {
			setEditMode(false);
		}
		
		CONFIG::locodeco public function setEditMode(enabled:Boolean):void {
			if (model.stateModel.hand_of_god || model.stateModel.editing_requesting_lock || (model.stateModel.editing == enabled)) return;
			
			// if location isn't loaded yet, queue this request
			const location:Location = model.worldModel.location;
			if (!(location && location.isFullyLoaded)) {
				const t:Timer = new Timer(100, 1);
				t.addEventListener(TimerEvent.TIMER, (enabled ? startEditMode : stopEditMode));
				t.start();
				return;
			}
			
			if (enabled) {
				growl('Starting editing mode');
				getLocationLockForEditing();
			} else {
				growl('Stopping editing mode');
				// reload physics (platforms may have changed)
				instance.controllerMap.physicsController.setUpGeoPhysicsForLocation();
				releaseLocationLockAfterEditing();
			}
			StageBeacon.stage.focus = StageBeacon.stage;
		}
		
		CONFIG::locodeco public function getLocationLockForEditing():void {
			model.stateModel.editing_requesting_lock = true;
			genericSend(
				new NetOutgoingLocationLockRequestVO(),
				function(rm:NetResponseMessageVO):void {
					growl('EDITING LOCK RECEIVED');
					model.stateModel.editing_requesting_lock = false;
					model.stateModel.editing = true;
				},
				function(rm:NetResponseMessageVO):void {
					growl('COULD NOT GET EDITING LOCK');
					model.stateModel.editing_requesting_lock = false;
				}
			);
		}
		
		CONFIG::locodeco public function releaseLocationLockAfterEditing():void {
			genericSend(
				new NetOutgoingLocationLockReleaseVO(),
				function(rm:NetResponseMessageVO):void {
					growl('EDITING LOCK RELEASED');
					model.stateModel.editing = false;
					tryShowScreenViewFromQ();
				},
				function(rm:NetResponseMessageVO):void {
					growl('COULD NOT RELEASE EDITING LOCK');
					model.stateModel.editing = true;
				}
			);
		}
		
		public function getCurrentGameTimeInUnixTimestamp():int {
			return controllerMap.timeController.getCurrentGameTimeInUnixTimestamp();
		}
		
		public function getGameTimeFromUnixTimestamp(timestamp:int):String {
			return controllerMap.timeController.getGameTimeFromUnixTimestamp(timestamp);
		}
		
		public function forceUpdateGameTimeVO():void {
			controllerMap.timeController.forceUpdateGameTimeVO();
		}
		
		public function openSkillsPage(event:Event = null):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'skills') ? 'skills' : 'skills_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'profiles/me/skills/'), URLUtil.getTarget(target));
		}
		
		public function openProfilePage(event:Event = null, tsid:String = 'me'):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'profile') ? 'profile' : 'profile_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'profiles/'+tsid+'/'), URLUtil.getTarget(target));
		}
		
		public function openHelpCasePage(event:Event = null, id:String=''):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'help') ? 'help' : 'help_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'help/'+(id ? 'cases/'+id+'/' : '')), URLUtil.getTarget(target));
		}
		
		public function openVanityPage(event:Event = null):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'vanity') ? 'vanity' : 'vanity_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'vanity/'), URLUtil.getTarget(target));
		}
		
		public function openWardrobePage(event:Event = null):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'wardrobe') ? 'wardrobe' : 'wardrobe_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'wardrobe/'), URLUtil.getTarget(target));
		}
		
		public function openFriendsPage(event:Event = null):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'friends') ? 'friends' : 'friends_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'friends/add/'), URLUtil.getTarget(target));
		}
		
		public function openGroupsPage(event:Event = null, group_tsid:String = ''):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'groups') ? 'groups' : 'groups_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'groups/'+(group_tsid ? group_tsid+'/' : '')), URLUtil.getTarget(target));
		}
		
		public function openForumsPage(event:Event = null):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'forums') ? 'forums' : 'forums_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'forum/'), URLUtil.getTarget(target));
		}
		
		public function openAuctionsPage(event:Event = null, item_url_part:String = '', player_tsid:String = ''):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'auctions') ? 'auctions' : 'auctions_too';
			var extra:String = '';
			if(item_url_part){
				extra += 'item-'+item_url_part+'/';
			}
			else if(player_tsid){
				extra += player_tsid+'/';
			}
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'auctions/'+extra), URLUtil.getTarget(target));
		}
		
		public function openSettingsPage(event:Event = null):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'settings') ? 'settings' : 'settings_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'account/'), URLUtil.getTarget(target));
		}
		
		public function openRealtyPage(event:Event = null):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var url:String = model.flashVarModel.root_url+'realty/'+(model.worldModel.pc.pol_tsid ? model.worldModel.pc.pol_tsid+'/' : '');
			var target:String = (ExternalInterface.call('window.name.toString') != 'realty') ? 'realty' : 'realty_too';
			navigateToURL(new URLRequest(url), URLUtil.getTarget(target));
		}
		
		public function openSignOutPage(event:Event = null):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'exit/'), '_self');
		}
		
		public function openCalendarPage(event:Event = null):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'calendar') ? 'calendar' : 'calendar_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'calendar/'), URLUtil.getTarget(target));
		}
		
		public function openTokensPage(event:Event = null):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'tokens') ? 'tokens' : 'tokens_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'tokens/'), URLUtil.getTarget(target));
		}
		
		public function openProfileTokensPage(event:Event = null):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'profile') ? 'profile' : 'profile_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'account/tokens/'), URLUtil.getTarget(target));
		}
		
		public function openStatusPage(event:Event = null, tsid:String = '', status_id:String = ''):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'status') ? 'status' : 'status_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'status/'+tsid+'/'+status_id+'/'), URLUtil.getTarget(target));
		}
		
		public function openCreditsPage(event:Event = null):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'credits') ? 'credits' : 'credits_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'credits/'), URLUtil.getTarget(target));
		}
		
		public function openSubscribePage(event:Event = null):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'subscribe') ? 'subscribe' : 'subscribe_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'subscribe/'), URLUtil.getTarget(target));
		}
		
		public function openEncyclopediaPage(event:Event = null):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'en') ? 'encyclopedia' : 'encyclopedia_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'encyclopedia/'), URLUtil.getTarget(target));
		}
		
		public function openSnapPage(event:Event = null, snap_url:String = ''):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			//strip the first slash if it's there
			if(snap_url.indexOf('/') == 0) snap_url = snap_url.substr(1);
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'snaps') ? 'snaps' : 'snaps_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+snap_url), URLUtil.getTarget(target));
		}
		
		public function openGiantPage(event:Event = null, giant_tsid:String = ''):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'giants') ? 'giants' : 'giants_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'giants/#'+giant_tsid), URLUtil.getTarget(target));
		}
		
		public function openCreateAccountPage(event:Event = null):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'create_account') ? 'create_account' : 'create_account_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'quickstart/register/'), URLUtil.getTarget(target));
		}
		
		public function openMailArchivePage(event:Event = null):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			
			var target:String = (ExternalInterface.call('window.name.toString') != 'mail_archive') ? 'mail_archive' : 'mail_archive_too';
			navigateToURL(new URLRequest(model.flashVarModel.root_url+'mail/archive/'), URLUtil.getTarget(target));
		}
		
		/** Calls are batched and processed once per second */
		public function resnapMiniMap(force:Boolean=false):void {
			const loc:Location = model.worldModel.location;
			
			// if there's no map, don't bother queueing resnaps at all
			if (loc && (loc.show_map == false) && !CONFIG::locodeco) return;

			// if we are not ready to snap, queue it for later
			const queueResnap:Boolean = !loc
				// batch up resnap requests so we only do it once per second
				|| ((getTimer() - lastMinimapResnap) < 1000)
				// not while the mouse is down
				|| StageBeacon.mouseIsDown
				// not while we're moving or re-rendering
				|| model.moveModel.moving
				|| model.moveModel.rebuilding_location
				// not while we're showing the loading view (e.g. re-rendering or loading deco selector)
				|| LoadingLocationView.instance.visible;
			
			if (!force && queueResnap) {
				// queue this up again for later
				if (resnapInterval == 0) {
					resnapInterval = StageBeacon.setInterval(resnapMiniMap, 100);
				}
				return;
			}
			
			if (resnapInterval > 0) {
				StageBeacon.clearInterval(resnapInterval);
				resnapInterval = 0;
			}
			
			lastMinimapResnap = getTimer();
			
			const bWidth:int = MiniMapView.MAX_ALLOWABLE_MAP_WIDTH;
			const bHeight:int = loc.client::h*(bWidth / loc.client::w);
			const loc_bm:Bitmap = getMainView().gameRenderer.getSnapshot(CameraMan.SNAPSHOT_TYPE_NORMAL, bWidth, bHeight);
			MiniMapView.instance.addGraphic(loc_bm);
		}
		
		public function updateWorldSkill(skill_tsid:String, callback:Function = null):void {
			api_callback = callback;
			api_call.skillsInfo(skill_tsid);
			//api_call.trace_output = true;
		}
		
		private function onAPIComplete(event:TSEvent):void {
			//any actions you may want to handle when api_call fires a TSEvent.COMPLETE
			if(api_callback != null) api_callback();
			api_callback = null;
		}
		
		public function updatePCLoggingData():void {
			var pc:PC = model.worldModel.pc;
			API.pc_location_str = 't='+pc.location.tsid+'&x='+pc.x+'&y='+pc.y;
		}
		
		public function triggerPhysicsViewportQuery():void {
			controllerMap.physicsController.doViewportQuery();
		}
		
		public function saveLocationAssets(do_i:int=-1, do_m:int=0):void {
			var layer:Layer;
			var layer_renderer:LayerRenderer;
			var temp_bm:Bitmap;
			var bm:Bitmap;
			var l_bm:LargeBitmap;
			var next_y:int;
			var next_x:int;
			var i:int;
			var m:int;
			for (i=0;i<model.worldModel.location.layers.length;i++) {
				layer = model.worldModel.location.layers[i];
				CONFIG::debugging {
					Console.info(layer.tsid);
				}
				layer_renderer = getMainView().gameRenderer.locationView.getLayerRendererByTsid(layer.tsid);
				if (!layer_renderer) continue;
				
				l_bm = layer_renderer.largeBitmap;
				if (!l_bm) continue;
				
				next_x = 0;
				
				for (m=0;m<l_bm.bitmaps.length;m++) {
					bm = l_bm.bitmaps[m];
					if (!bm) continue; 
					var name:String = model.worldModel.location.tsid+'-'+i+'-'+layer.tsid+'-'+m+'_x'+bm.x+'_y'+bm.y+'_w'+bm.width+'_h'+bm.height+'_lw'+layer.w+'_lh'+layer.h+'.png';
					CONFIG::debugging {
						Console.warn(name);
					}
					
					if (do_i == i && do_m == m) {
						var bss:BitmapSnapshot = new BitmapSnapshot(null, name, 0, 0, bm.bitmapData);
						bss.saveToDesktop();
					}/*
					
					temp_bm = new Bitmap(bm.bitmapData);
					temp_bm.scaleX = temp_bm.scaleY = .1;
					StageBeacon.stage.addChild(temp_bm);
					
					temp_bm.x = next_x;
					temp_bm.y = next_y;
					
					next_x+= temp_bm.width+300;*/
				}
				
				//next_y+= temp_bm.height+10;
			}
		}
		
		public function reload(msg:String, becauseOfError:Boolean = false, delay:int = 5000):void {
			model.netModel.disconnected_msg = msg;
			DisconnectedScreenView.instance.show(model.netModel.disconnected_msg, 0);
			StageBeacon.setTimeout(URLUtil.reload, delay, becauseOfError);
		}

		/**
		 * Checks *whether* we should ask the user before reloading, and prompts
		 * the user with the failureMsg if we've already auto-reloaded recently,
		 * and otherwise the successMsg if we're gonna reload automatically.
		 * 
		 * If failureMsg is null, we'll reuse the successMsg.
		 */
		public function maybeReload(successMsg:String, failureMsg:String = null, suggest_help_test:Boolean=false):void {
			if (!failureMsg) failureMsg = successMsg;
			if (model.flashVarModel.auto_reloaded_after_error) {
				const cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
				cdVO.callback = function(value:*):void {
					if (value) {
						BootError.handleError('RELOADING: ' + failureMsg, null, ['reload'], true, false);
						reload("Reloading...", false); // <-- I switched this to false, so that the next error after they choose to reload will cause an auto reload
					}
				}
				cdVO.title = 'Reload the game?'
				cdVO.txt = failureMsg + "<br>" + "Would you like me to reload and try to reconnect again?";
				if (suggest_help_test) {
					cdVO.txt+= "<br>(if it keeps happening try this: <a href='http://www.glitch.com/help/test' target='test_connection'>http://www.glitch.com/help/test</a>)"
				}
					
				cdVO.choices = [
					{value: true,  label: "Yes"},
					{value: false, label: "No"}
				];
				cdVO.escape_value = false;
				confirm(cdVO);
			} else {
				BootError.handleError('RELOADING: ' + successMsg, null, ['reload'], true, false);
				reload(successMsg + "<br>The game will automatically reload in a few seconds. (Sorry!)", true);
			}
		}
		
		CONFIG::god public function showPerformanceGraph():void {
			getMainView().performanceGraphVisible = true;
		}
		
		CONFIG::god public function hidePerformanceGraph():void {
			getMainView().performanceGraphVisible = false;
		}
		
		
		private var checkmark:MovieClip;
		private var checkmark_holder:Sprite = new Sprite();
		public function showCheckmark(x:int, y:int):void {
			if (!checkmark) {
				checkmark = new AssetManager.instance.assets.checkmark();
			}
			checkmark_holder.addChild(checkmark);
			checkmark.x = -checkmark.width/2;
			checkmark.y = -checkmark.height;
			checkmark_holder.x = x;
			checkmark_holder.y = y;
			
			checkmark_holder.scaleX = checkmark_holder.scaleY = 1;
			TSTweener.addTween(checkmark_holder, {scaleX:3, scaleY:3, time:.3, delay:.2});
			TSTweener.addTween(checkmark_holder, {scaleX:0, scaleY:0, time:.3, delay:.7, onComplete:function():void { 
				if (checkmark_holder.parent) checkmark_holder.parent.removeChild(checkmark_holder);
			}});
			getMainView().gameRenderer.placeOverlayInSCH(checkmark_holder, 'TSFC');
		}
	}
}

class UndoPoint {
	public var type:String;
	public var amf:Object;
}
