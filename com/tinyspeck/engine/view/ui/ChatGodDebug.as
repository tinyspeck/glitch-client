package com.tinyspeck.engine.view.ui
{
	import com.adobe.serialization.json.JSON;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.FakeFriends;
	import com.tinyspeck.engine.api.APICall;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.control.engine.AnnouncementController;
	import com.tinyspeck.engine.data.client.ActionRequest;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.data.client.DebugMessages;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.data.client.ScreenViewQueueVO;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.loading.LoadingInfo;
	import com.tinyspeck.engine.data.location.Deco;
	import com.tinyspeck.engine.data.location.Layer;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.location.PlatformLine;
	import com.tinyspeck.engine.data.location.Wall;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCBuff;
	import com.tinyspeck.engine.data.prompt.Prompt;
	import com.tinyspeck.engine.data.rook.RookDamage;
	import com.tinyspeck.engine.data.rook.RookHeadAnimationState;
	import com.tinyspeck.engine.data.rook.RookStun;
	import com.tinyspeck.engine.data.rook.RookedStatus;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.memory.ClientOnlyPools;
	import com.tinyspeck.engine.memory.EnginePools;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.net.MessageTypes;
	import com.tinyspeck.engine.net.NetOutgoingActionRequestBroadcastVO;
	import com.tinyspeck.engine.net.NetOutgoingFurniturePickupVO;
	import com.tinyspeck.engine.net.NetOutgoingItemstackCreateVO;
	import com.tinyspeck.engine.net.NetOutgoingLocalChatVO;
	import com.tinyspeck.engine.net.NetOutgoingPerfTeleportVO;
	import com.tinyspeck.engine.net.NetOutgoingSetPrefsVO;
	import com.tinyspeck.engine.net.NetOutgoingSkillsCanLearnVO;
	import com.tinyspeck.engine.pack.FurnitureBagUI;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.port.ACLDialog;
	import com.tinyspeck.engine.port.ActionIndicatorView;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CabinetManager;
	import com.tinyspeck.engine.port.ChassisManager;
	import com.tinyspeck.engine.port.ConversationManager;
	import com.tinyspeck.engine.port.CraftyDialog;
	import com.tinyspeck.engine.port.DateTimeDialog;
	import com.tinyspeck.engine.port.EmblemManager;
	import com.tinyspeck.engine.port.GardenManager;
	import com.tinyspeck.engine.port.HouseManager;
	import com.tinyspeck.engine.port.InputDialog;
	import com.tinyspeck.engine.port.InputTalkBubble;
	import com.tinyspeck.engine.port.JobActionIndicatorView;
	import com.tinyspeck.engine.port.JobDialog;
	import com.tinyspeck.engine.port.JobManager;
	import com.tinyspeck.engine.port.MailManager;
	import com.tinyspeck.engine.port.NewAvaConfigDialog;
	import com.tinyspeck.engine.port.NoteManager;
	import com.tinyspeck.engine.port.PartySpaceManager;
	import com.tinyspeck.engine.port.QuestManager;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.port.RookManager;
	import com.tinyspeck.engine.port.ScoreManager;
	import com.tinyspeck.engine.port.TrophyCaseManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.spritesheet.AvatarSSManager;
	import com.tinyspeck.engine.spritesheet.ItemSSManager;
	import com.tinyspeck.engine.util.DisplayDebug;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.URLUtil;
	import com.tinyspeck.engine.view.PCView;
	import com.tinyspeck.engine.view.gameoverlay.AchievementView;
	import com.tinyspeck.engine.view.gameoverlay.CameraMan;
	import com.tinyspeck.engine.view.gameoverlay.ChoicesDialog;
	import com.tinyspeck.engine.view.gameoverlay.CollectionCompleteView;
	import com.tinyspeck.engine.view.gameoverlay.DisconnectedScreenView;
	import com.tinyspeck.engine.view.gameoverlay.GiantView;
	import com.tinyspeck.engine.view.gameoverlay.ImgMenuView;
	import com.tinyspeck.engine.view.gameoverlay.LevelUpView;
	import com.tinyspeck.engine.view.gameoverlay.LoadingLocationView;
	import com.tinyspeck.engine.view.gameoverlay.LocationCanvasView;
	import com.tinyspeck.engine.view.gameoverlay.NewDayView;
	import com.tinyspeck.engine.view.gameoverlay.SnapTravelView;
	import com.tinyspeck.engine.view.gameoverlay.StreetUpgradeView;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.gameoverlay.UICalloutView;
	import com.tinyspeck.engine.view.gameoverlay.maps.HubMapDialog;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.renderer.MiddleGroundRenderer;
	import com.tinyspeck.engine.view.renderer.RenderMode;
	import com.tinyspeck.engine.view.renderer.commands.LocationCommands;
	import com.tinyspeck.engine.view.ui.avatar.Lantern;
	import com.tinyspeck.engine.view.ui.chat.ChatArea;
	import com.tinyspeck.engine.view.ui.glitchr.GlitchrSavedDialog;
	import com.tinyspeck.engine.view.ui.imagination.ImaginationYourLooksUI;
	import com.tinyspeck.engine.view.ui.map.MapChatArea;
	import com.tinyspeck.engine.view.ui.quest.QuestTracker;
	
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.System;
	import flash.utils.Timer;
	import flash.utils.getDefinitionByName;
	import flash.utils.getTimer;

	public class ChatGodDebug
	{	
		private var model:TSModelLocator;
		
		/* singleton boilerplate */
		public static const instance:ChatGodDebug = new ChatGodDebug();
		
		public function ChatGodDebug() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			model = TSModelLocator.instance;
		}
		
		private var chat_stress_id:uint = 0;
		private var crazycam_interv:uint = 0;
		private var xsdsdsdsd_interv:uint;
		
		public function parse(txt:String, chat_name:String):Boolean {
			const words:Array = txt.split(' ');
			
			var did_anything:Boolean = false;
			var payload:Object;
			var pc:PC = model.worldModel.pc;
			var loc:Location = model.worldModel.location;
			var item_class:String;
			var item:Item;
			var i:int;
			var reposition:Boolean  = words.indexOf('reposition') > -1;
			var scale_to_stage:Boolean  = words.indexOf('scale_to_stage') > -1;
			var uid:String = 'uid'+String(new Date().getTime());
			var fake_msg:Object;
			var buff:PCBuff;
			var plat:PlatformLine;
			var wall:Wall;
			var decoAndLayer:Object;
			var layer:Layer;
			var deco:Deco;
			var layers:Object;
			var tsid:String;
			var ms:int;
			
			if (txt.indexOf('/zoom') == 0){
				try {
					if ((words.length > 1) && StringUtil.trim(words[1]).length) {
						var time:Number = MathUtil.clamp(0.1, 3.0, ((words.length == 3) ? words[2] : model.flashVarModel.auto_zoom_ms));
						time = isNaN(time) ? 1 : time;
						if (!loc.allow_zoom) {
							// pass
						} else if (words[1] == 'reset') {
							TSFrontController.instance.resetViewportScale(time, true);
						} else {
							// clamp to allowed range
							var zoom:Number = MathUtil.clamp(0.1, 2.0, words[1]);
							CONFIG::god {
								// gods don't get clamped
								zoom = Number(words[1]);
							}
							zoom = isNaN(zoom) ? 1 : zoom;
							// the last argument says to not clamp the scale when a god
							TSFrontController.instance.setViewportScale(zoom, time, false, true, (!CONFIG::god));
						}
					} else {
						TSFrontController.instance.resetViewportScale(model.flashVarModel.auto_zoom_ms, true);
					}
				} catch (e:Error) {
					TSFrontController.instance.resetViewportScale(model.flashVarModel.auto_zoom_ms, true);
				}
				return true;
			}
			else if (txt.indexOf('/xsdsdsdsd') == 0) {
				ms = words.length > 1 ? words[1] : 1000;
				ms = ms || 1000;
				if (xsdsdsdsd_interv) {
					StageBeacon.clearInterval(xsdsdsdsd_interv);
					xsdsdsdsd_interv = 0;
					model.activityModel.growl_message = 'xsdsdsdsd_interv cleared '+xsdsdsdsd_interv;
				} else {
					xsdsdsdsd_interv = StageBeacon.setInterval(function():void {
						if(ImgMenuView.instance.parent){
							ImgMenuView.instance.hide();
						}
						else {
							ImgMenuView.instance.show();
						}
					}, ms);
					model.activityModel.growl_message = 'xsdsdsdsd_interv set ('+ms+'ms) '+xsdsdsdsd_interv;
				}
				return true;
			}
			
			if (CONFIG::debugging || CONFIG::god) {
				if (txt == '/err' || txt == '/error') {
					/*
					Console.warn(StringUtil.getCurrentCodeLocation());
					Console.warn(StringUtil.getCallerCodeLocation());
					try {
						var sp:Sprite;
						sp.height = 0;
					} catch(err:Error) {
						Console.info(err.getStackTrace());
						Console.info(StringUtil.getShorterStackTrace(err));
						Console.info(new Error().getStackTrace());
						Console.info(StringUtil.getShorterStackTrace(new Error()));
					}
					*/
					StageBeacon.setTimeout(function():void {
						//Console.warn(StringUtil.getCurrentCodeLocation());
						//Console.warn(StringUtil.getCallerCodeLocation());
						//try {
							var sp:Sprite;
							sp.height = 0;
						//} catch(err:Error) {
						//	Console.info(err.getStackTrace());
						//	Console.info(StringUtil.getShorterStackTrace(err));
						//	Console.info(new Error().getStackTrace());
						//	Console.info(StringUtil.getShorterStackTrace(new Error()));
						//}
					}, 3000);
					
					//BootError.handleError('SSAbstractSheet', new Error("Already recording"), !CONFIG::god);
					//BootError.handleError('SSAbstractSheetasdasdasd', new Error("Alreadyasdasdasd recording"), !CONFIG::god);
					
					did_anything = true;
				} 
			}

			if(/(?:\x{0}+\x20*\b)*\x62\x20*\x65\x20*\x74\x20*\x61/gi.test(txt)) {
				TSModelLocator.instance.stateModel.i_see_dead_pixels = true;
			}

			CONFIG::god {
				if (txt.indexOf('/saveloc') == 0){
					var do_i:int = (words.length>1) ? words[1]: 0;
					var do_m:int = (words.length>2) ? words[2]: 0;
					TSFrontController.instance.saveLocationAssets(do_i, do_m);
					did_anything = true;
				} else if (txt.indexOf('/orientation') == 0){
					var orientation:String;
					if (words.length > 1) {
						orientation = StringUtil.trim(words[1]).toLowerCase();
					}
					switch (orientation) {
						default:
							orientation = LayoutModel.ORIENTATION_DEFAULT;
							// fall through to below
						case LayoutModel.ORIENTATION_DEFAULT:
						case LayoutModel.ORIENTATION_HFLIP:
						case LayoutModel.ORIENTATION_VFLIP:
						case LayoutModel.ORIENTATION_XFLIP:
							TSFrontController.instance.setViewportOrientation(orientation);
							did_anything = true;
							break;
					}
				} else if (txt.indexOf('/throttle_swf ') == 0) {
					if (words.length == 2) {
						model.flashVarModel.throttle_delay = int(words[1]) * 1000;
						model.activityModel.growl_message = 'throttle delay set to ' + model.flashVarModel.throttle_delay + ' milliseconds';
						did_anything = true;
					}
				} else if (txt.indexOf('/fps ') == 0) {
					if (words.length == 2) {
						model.flashVarModel.fps = int(words[1]);
						StageBeacon.stage.frameRate = int(words[1]);
						model.activityModel.growl_message = 'fps set to ' + StageBeacon.stage.frameRate;
						did_anything = true;
					}
				} else if (txt.indexOf('/random_house') == 0) {
					ms = (words.length>2 && int(words[2])) ? Math.max(100, int(words[2])) : 0;
					ChassisManager.instance.showRandomHouse(words.length>1 && words[1] == 'true', ms);
					did_anything = true;
				} else if (txt.indexOf('/preload ') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.PRELOAD_SWF,
						url: words[1]
					});
					did_anything = true;
				} else if (txt.indexOf('/memreport') == 0) {
					
					var which_rep:int = 0;
					
					if (words.length > 1 && parseInt(words[1])) which_rep = parseInt(words[1]);
					
					var mem_str:String = '';
					
					if (which_rep == 0 || which_rep == 1) mem_str+= AssetManager.instance.memReport();
					if (which_rep == 0 || which_rep == 2) mem_str+= AvatarSSManager.memReport();
					if (which_rep == 0 || which_rep == 3) mem_str+= ItemSSManager.memReport();
					if (which_rep == 0 || which_rep == 4) mem_str+= DisposableSprite.memReport();
					if (which_rep == 0 || which_rep == 5) mem_str+= EnginePools.memReport();
					if (which_rep == 0 || which_rep == 6) mem_str+= ClientOnlyPools.memReport();
					
					if (mem_str) {
						System.setClipboard(mem_str);
						activityTextHandler('ADMIN: The report has been put in your clipboard');
						CONFIG::debugging {
							Console.info(mem_str);
						}
					} else {
						activityTextHandler('ADMIN: BAD ARG');
					}
					
					did_anything = true;
				} else if (txt.indexOf('/menu ') == 0) {
					model.activityModel.growl_message = txt;
					lis_view = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(words[1]);
					if (lis_view) {
						model.activityModel.growl_message = lis_view.worth_rendering+'!';
						TSFrontController.instance.startInteractionWith(lis_view);
					} else {
						model.activityModel.growl_message = words[1]+' not found';
					}
					
					did_anything = true;
				} else if (txt == '/fast_update_hi_counts') {
					model.flashVarModel.fast_update_hi_counts = !model.flashVarModel.fast_update_hi_counts;
					if (model.flashVarModel.fast_update_hi_counts) {
						model.worldModel.hi_emote_leaderboard_sig.dispatch(model.worldModel.hi_emote_leaderboard);
						activityTextHandler('leaderboad updating fast now');
					} else {
						activityTextHandler('leaderboad updating normally now');
					}
					did_anything = true;
				} else if (txt == '/bubbletoggle') {
					model.stateModel.no_itemstack_bubbles = !model.stateModel.no_itemstack_bubbles;
					model.activityModel.growl_message = 'model.stateModel.no_itemstack_bubbles set to '+model.stateModel.no_itemstack_bubbles;
					
					did_anything = true;
				} else if (txt.indexOf('/link') == 0) {
					
					// example: http://dev.glitch.com/jumpp.php?t=LM410CL52JQA0&x=1964&y=-857&f=1&SWF_which=DEV
					var link_txt:String = model.flashVarModel.root_url
						+'jump.php'
						+'?t='+loc.tsid
						+'&x='+pc.x
						+'&y='+pc.y;
					
					if(words[0] == '/linkf'){
						link_txt += '&'+EnvironmentUtil.getURLAndQSArgs().qs+'&f=1';
						addLine('force jump linker provider');
					}
					
					if(words.length > 1){
						switch(words[1]){
							case 'template':
								link_txt += '&no_instance_spawn=1';
								break;
							case 'instance':
								link_txt += '&instance_me=1';
								break;
						}
					}
					
					activityTextHandler('<a href="event:'+TSLinkedTextField.LINK_EXTERNAL+'|'+link_txt+'">'+link_txt+'</a>');
					activityTextHandler('The link has been placed in your clipboard');
					
					System.setClipboard(link_txt);
					did_anything = true;
				} 
				else if (txt.indexOf('/snap') == 0) {
					TSFrontController.instance.saveLocationLoadingImg();
					did_anything = true;
					
				}
				else if (txt.indexOf('/fallback_renderer') == 0) {
					var renderMode:RenderMode;
					if (words.length > 1) {
						renderMode = RenderMode.getRenderModeByName(words[1]);
					}
					LocationCommands.fallBackRenderMode(renderMode);
					did_anything = true;
					
				}
				else if (txt.indexOf('/bad_s_for_trant') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						"__SOURCE__":"MOVE0",
						"changes":{
							"itemstack_values":{
								"location":{
									"IPF1OB95D6033US":{
										"y":-116,
										"not_selectable":false,
										"s":1,
										"x":-354,
										"z":4294967295
									}
								}
							},
							"location_tsid":"LPF6HF44SLS2NNU"
						},
						"type":"location_item_moves"
					});
					did_anything = true;
				} 
				else if (txt.indexOf('/dont_move_for_item_menu') == 0) {
					model.flashVarModel.dont_move_for_item_menu = !model.flashVarModel.dont_move_for_item_menu;
					activityTextHandler('dont_move_for_item_menu is now:'+model.flashVarModel.dont_move_for_item_menu);
					did_anything = true;
				} 
				else if (txt.indexOf('/recon') == 0) {
					TSFrontController.instance.simulateGSRequestingAReconnect();
					did_anything = true;
				} 
				else if (txt.indexOf('/speedcam') == 0) {
					if (model.worldModel.pc.cam_speed_multiplier == 1) {
						model.worldModel.pc.cam_speed_multiplier = 5;
					} else {
						model.worldModel.pc.cam_speed_multiplier = 1;
					}
					did_anything = true;
				} 
				else if (txt.indexOf('/setprefs') == 0) {
					model.prefsModel.int_menu_default_to_one = !model.prefsModel.int_menu_default_to_one;
					TSFrontController.instance.genericSend(new NetOutgoingSetPrefsVO(model.prefsModel.getAnonymous()));
					did_anything = true;
				} 
				else if (txt.indexOf('/reverse') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.AVATAR_ORIENTATION,
						reversed: model.worldModel.pc.reversed ? false : true
					});
					did_anything = true;
				} 
				else if (txt.indexOf('/fake_force_reload') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.FORCE_RELOAD,
						at_next_move: (words.length > 1 && words[1] == 'at_next_move') ? true : false,
						msg: (words.length > 2) ? words.slice(2).join(' ') : ''
						
					});
					did_anything = true;
				} 
				else if (txt.indexOf('/cam_vx_x_adj') == 0) {
					if (words.length > 1) {
						CameraMan.instance.cam_vx_x_adj = (Number(words[1]));
					} else {
						CameraMan.instance.cam_vx_x_adj = 0;
					}
					did_anything = true;
				} 
				else if (txt.indexOf('/start_stress ') == 0) {
					if(words.length > 2) {
						var host:String = words[1];
						var port:String = words[2];
						//var url:String = 'http://dev.glitch.com/god/tests_run.php?test=stress_client&port=10601&host=sbench3';
						var url:String = 'http://dev.glitch.com/god/tests_run.php?test=stress_client&port='+port+'&host='+host;
						navigateToURL(new URLRequest(url), URLUtil.getTarget('stress_test'));
					}
					did_anything = true;
				} 
				else if (txt.indexOf('/move') == 0) {
					
					if (model.stateModel.avatar_gs_path_pt) {
						TSFrontController.instance.cancelAllAvatarPaths('/move');
					} else {
						var dest_x:int = pc.x;
						var face:String ='right';
						if (words.length > 1) {
							dest_x+= int(words[1]);
							// face him in the opposite direction, to test
							if (dest_x > pc.x) {
								face = 'left';
							} else if (dest_x < pc.x) {
								face = 'right';
							}
							
						}
						
						StageBeacon.setTimeout(function():void{
							TSFrontController.instance.startMovingAvatarOnGSPath(new Point(dest_x, pc.y), face);
						}, 3000);
					}
					
					did_anything = true;
				} 
				else if (txt.indexOf('/hit') == 0) {
					var hit_anim:String = 'hit1';
					if (txt == '/hit2') hit_anim = txt;
					
					StageBeacon.waitForNextFrame(TSFrontController.instance.playHitAnimation, hit_anim, 4000);
					
					did_anything = true;
				} 
				else if (txt.indexOf('/familiar_push') == 0 && words.length > 1) {
					TSFrontController.instance.sendLocalChat(new NetOutgoingLocalChatVO('/familiar_push'));
					TSFrontController.instance.sendLocalChat(new NetOutgoingLocalChatVO('/familiar_push'));
					did_anything = true;
				}  
				else if (txt == '/clear_dots'){
					model.worldModel.pc.path = [];
					model.activityModel.dots_to_draw = {clear:true};
					did_anything = true;
				}
				else if (txt == '/clear') {
					clear(chat_name);
					did_anything = true;
				} 
				else if (txt.indexOf('/ver') == 0) {
					var ver_txt:String = EnvironmentUtil.getFlashVersion();
					did_anything = true;
				} /*
				else if (txt.indexOf('/ui ') == 0) {
					if (words.length > 1) {
						StageBeacon.setTimeout(function():void {
							TSFrontController.instance.changeAvatarVisibility(words[1] == '1');
							TSFrontController.instance.changeMiniMapVisibility(words[1] == '1');
							TSFrontController.instance.changePCStatsVisibility(words[1] == '1');
							TSFrontController.instance.changeFamiliarVisibility(words[1] == '1');
							TSFrontController.instance.changeStatusBubbleVisibility(words[1] == '1');
						}, 000);
					}
					did_anything = true;
				} */
				else if (txt.indexOf('/shut') == 0) {
					TSFrontController.instance.initiateShutDownSequence(60);
					DisconnectedScreenView.instance.show('test', 60)
					did_anything = true;
				} 
				else if (txt.indexOf('/goaway') == 0) {
					StageBeacon.setTimeout(function():void {
						navigateToURL(new URLRequest('/'), '_self');
					}, 5000);
				} 
				else if (txt.indexOf('/fake_disconnect') == 0) {
					TSFrontController.instance.testUnexpectedDisconnect();
					did_anything = true;
				} 
				else if (txt.indexOf('/triple_jump_mult ') == 0) {
					if (words.length > 1) {
						var multiplier:Number = parseFloat(words[1]);
						if (!isNaN(multiplier)) {
							model.physicsModel.triple_jump_multiplier_overide = multiplier;
							activityTextHandler('ADMIN: triple_jump_multiplier_overide set to:'+multiplier);
						}
					}
					did_anything = true;
				} 
				else if (txt.indexOf('/wall_jump_mult_x ') == 0) {
					if (words.length > 1) {
						multiplier = parseFloat(words[1]);
						if (!isNaN(multiplier)) {
							model.physicsModel.wall_jump_multiplier_x = multiplier;
							activityTextHandler('ADMIN: wall_jump_multiplier_x set to:'+multiplier+' default is .4');
						}
					}
					did_anything = true;
				} 
				else if (txt.indexOf('/wall_jump_mult_y ') == 0) {
					if (words.length > 1) {
						multiplier = parseFloat(words[1]);
						if (!isNaN(multiplier)) {
							model.physicsModel.wall_jump_multiplier_y = multiplier;
							activityTextHandler('ADMIN: wall_jump_multiplier_y set to:'+multiplier+' default is 1.1');
						}
					}
					did_anything = true;
				} 
				else if (txt.indexOf('/cam ') == 0) {
					if (words.length > 1) {
						model.stateModel.camera_offset_x = int(words[1]);
						model.stateModel.camera_offset_from_edge = false;
						TSFrontController.instance.setCameraOffset();
					}
					did_anything = true;
				} 
				else if (txt.indexOf('/cam2 ') == 0) {
					if (words.length > 1) {
						model.stateModel.camera_offset_x = int(words[1]);
						model.stateModel.camera_offset_from_edge = true;
						TSFrontController.instance.setCameraOffset();
					}
					did_anything = true;
				}
				else if (txt.indexOf('/camabil') == 0) {
					var cam_msg:Object = {
						type: MessageTypes.CAMERA_ABILITIES_CHANGE,
						abilities: {}
					}
						
					if (words.length > 1) {
						cam_msg.abilities.range = Math.abs(parseInt(words[1]));
					}
					if (words.length > 2) {
						cam_msg.abilities.can_snap = words[2] == 't';
					}
					if (words.length > 3) {
						if (words[3]) cam_msg.abilities.disabled_reason = words[3];
					}
					
					TSFrontController.instance.simulateIncomingMsg(cam_msg);
					did_anything = true;
				}
				else if (txt == '/cult') {
					HouseManager.instance.startCultivation();
					did_anything = true;
				}
				else if (txt.indexOf('/interact_with_all') == 0) {
					TSFrontController.instance.toggleInteractWithAll();
					did_anything = true;
				}
				else if (txt.indexOf('/cammode') == 0) {
					TSFrontController.instance.maybeStartCameraManUserMode(txt);
					did_anything = true;
				}
				else if (txt.indexOf('/camcrazy') == 0) {
					if (crazycam_interv) {
						StageBeacon.clearInterval(crazycam_interv);
						crazycam_interv = 0;
						TSFrontController.instance.resetCameraOffset();
					} else {
						crazycam_interv = StageBeacon.setInterval(function():void {
							model.stateModel.camera_offset_x = MathUtil.randomInt(-400, 400);
							TSFrontController.instance.setCameraOffset();
						}, 400);
					}
					
					did_anything = true;
				}
				else if (txt.indexOf('/testlink ') == 0) {
					if (words.length > 1) {
						addLine('<a href="event:get_info-_-_-'+words[1]+'" class="">'+words[1]+'</a>');
					}
					did_anything = true;
				}
				else if (txt.indexOf('/cbot') == 0) {
					var annc_uid:String = 'cbot_tool';
					var annc_uid2:String = 'cbot_backer';
					var display_item_class:String = 'blender';
					var display_item:Item;
					var state:String = 'iconic';
					var bot_tsid:String = 'IMF17V6UDSP2NCV';
					
					if (words.length > 1 && words[1]){
						display_item_class = words[1];
					}
					
					display_item = model.worldModel.items[display_item_class];
					
					if (display_item) {
						if (display_item.hasTags('tool')) {
							state = 'tool_animation';
						}
					} else {
						AnnouncementController.instance.cancelOverlay(annc_uid);
						AnnouncementController.instance.cancelOverlay(annc_uid2);
						fake_msg = {
							"changes":{
								"itemstack_values":{
									"location":{
										"cbot": {
											"count": 0
										}
									}
								},
								"location_tsid":model.worldModel.location.tsid
							},
							"type":"location_event"
						}
						
						TSFrontController.instance.simulateIncomingMsg(fake_msg, true);
						return true;
					}
					
					if (!TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(bot_tsid)) {
						fake_msg = {
							"changes":{
								"itemstack_values":{
									"location":{
									}
								},
								"location_tsid":model.worldModel.location.tsid
							},
							"type":"location_event"
						};
							
						fake_msg.changes.itemstack_values.location[bot_tsid] = {
							"path_tsid":bot_tsid,
							"count":1,
							"class_tsid":"npc_crafty_bot",
							"version":"1305759676",
							"x": model.worldModel.pc.x+100,
							"y": model.worldModel.pc.y,
							"s": "crafting_with_back"
						}
						
						TSFrontController.instance.simulateIncomingMsg(fake_msg, true);
					}
					
					AnnouncementController.instance.cancelOverlay(annc_uid);
					AnnouncementController.instance.cancelOverlay(annc_uid2);
					
					if (!TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(bot_tsid)) {
						return true;
					}
					
					fake_msg = {
						"changes":{
							"itemstack_values":{
								"location":{
								}
							},
							"location_tsid":model.worldModel.location.tsid
						},
						"type":"location_event"
					}
					
					fake_msg.changes.itemstack_values.location[bot_tsid] = {
						"path_tsid":bot_tsid,
						"count":1,
						"class_tsid":"npc_crafty_bot",
						"version":"1305759676",
						"s": "crafting_with_back"/*,
						x: model.worldModel.pc.x+200*/
					}
					TSFrontController.instance.simulateIncomingMsg(fake_msg, true);
					
					StageBeacon.setTimeout(function():void {
						fake_msg = {
							"changes":{
								"itemstack_values":{
									"location":{
									}
								},
								"location_tsid":model.worldModel.location.tsid
							},
							"type":"location_event",
							"announcements":[{
								type: 'itemstack_overlay',
								itemstack_tsid: bot_tsid,
								item_class: 'npc_crafty_bot',
								state: 'crafting_back',
								under_itemstack: true,
								place_at_bottom: true,
								dont_keep_in_bounds:true,
								delta_y: -8,
								follow:true,
								uid: annc_uid2,
								fade_out_sec:0,
								fade_in_sec:0,
								duration: 5300
							},{
								type: 'itemstack_overlay',
								itemstack_tsid: bot_tsid,
								delta_x: 0,
								delta_y: -35,
								width:40,
								item_class: display_item_class,
								state: state,
								under_itemstack: true,
								place_at_bottom: true,
								dont_keep_in_bounds:true,
								uid: annc_uid,
								follow:true,
								center_view:true,
								fade_out_sec:0,
								duration: 5300
							}]
						}
						
						fake_msg.changes.itemstack_values.location[bot_tsid] = {
							"path_tsid":bot_tsid,
							"count":1,
							"class_tsid":"npc_crafty_bot",
							"version":"1305759676",
							"s": "crafting"/*,
							x: model.worldModel.pc.x+200*/
						}
						
						TSFrontController.instance.simulateIncomingMsg(fake_msg, true);
					}, 200);
					
					did_anything = true;
					
				}
				else if (txt.indexOf('/fake_friends_cancel') == 0) {
					FakeFriends.instance.cancel();
					did_anything = true;
					
				}
				else if (txt.indexOf('/fake_friends') == 0) {
					if (words.length>1 && int(words[1])) {
						FakeFriends.instance.insertFakesIntoLocation(int(words[1]));
					} else {
						FakeFriends.instance.insertFakesIntoLocation(int.MAX_VALUE);
					}
					did_anything = true;
					
				}
				else if (txt.indexOf('/nuxp_local') == 0) {
					TSFrontController.instance.startMovingAvatarOnGSPath(new Point(pc.x, pc.y), 'left');
					
					model.stateModel.camera_offset_x = -150;
					model.stateModel.camera_offset_from_edge = true;
					TSFrontController.instance.setCameraOffset();
					
					model.activityModel.announcements = Announcement.parseMultiple([
						{
							type: "vp_overlay",
							item_class: "apple",
							duration: 0,
							uid: 'nuxp_familiar_graphic',
							locking: true,
							state: 'iconic',
							size: '33%',
							x: '50%',
							y: '19%'
						},
						{
							type: "vp_overlay",
							duration: 0,
							width: 450,
							x: '50%',
							y: '50%',
							delay_ms: 400,
							click_to_advance: true,
							click_to_advance_bottom: true,
							click_to_advance_bottom_text: 'Click anywhere you fucking want...',
							background_color: 0,
							background_alpha: .3,
							at_bottom: true,
							fade_in_sec: 1,
							fade_out_sec: .7,
							text_fade_delay_sec: .5,
							text_fade_sec: .5,
							text: [
								'<p align="center"><span class="nuxp_big">Well hello!</span><br><br>'+
								'<span class="nuxp_medium">(Click to advance.)</span></p>',
								'<p align="center"><span class="nuxp_big">Welcome to the game!</span><br><br>'+
								'<span class="nuxp_medium">I hope you like reading.</span></p>'
							],
							done_anncs: [
								{
									type: "pc_overlay",
									duration: 0,
									width: 100,
									height: 100,
									bubble:true,
									uid: 'nuxp_px_text_1',
									pc_tsid: pc.tsid, // the itemstack to target
									delta_x: 0, //delta_x/y indicates position of overlay swf center relative to the bottom center of the itemstack
									delta_y: -114,
									text: [
										'<span class="simple_panel">I\'m saying something in reponse to you</span>'
									]
								},
								{
									type: "vp_overlay",
									duration: 0,
									width: 450,
									x: '50%',
									y: '50%',
									click_to_advance: true,
									delay_ms: 1500,
									text: [
										'<p align="center"><span class="nuxp_big">And I in response to you!</span></p>'
									],
									done_cancel_uids: ['nuxp_px_text_1'],
									
									done_anncs: [
										{
											type: "vp_overlay",
											duration: 0,
											width: 450,
											x: '50%',
											y: '50%',
											click_to_advance: true,
											text: [
												'<p align="center"><span class="nuxp_big">And another thing...</span></p>',
												'<p align="center"><span class="nuxp_big">This will end when you click here.</span></p>'
											],
											done_cancel_uids: ['nuxp_familiar_graphic']
										}
									]
								}
							]
						}
					]);
					did_anything = true;
				} 
				else if (txt.indexOf('/annc12') == 0) {
					
					var annc1:Object = {
						type: 'itemstack_overlay',
						swf_url: 'http://c2.glitch.bz/overlays%2F2011-06-28%2F1309296327_8026.swf',
						duration: 3000,
						itemstack_tsid: 'IMF1K6K9BKN2NE0',
						width: "100%",
						height: "100%",
						delta_y:-153,
						text: ['<span class="nuxp_vog_smaller">+1s</span>'],
						tf_delta_x: 0,
						tf_delta_y: 22,
						delta_x: 0,
						place_at_bottom:true,
						animate_to_buffs:true,
						uid:'annc1',
						locking:true,
						and_burst:true,
						and_burst_value:1,
						and_burst_text:'seconds'
					};
					
					var annc2:Object = {
						type: 'itemstack_overlay',
						swf_url: 'http://c2.glitch.bz/overlays%2F2011-06-28%2F1309296325_5753.swf',
						duration: 3000,
						itemstack_tsid: 'IMF1K6K9BKN2NE0',
						width: "100%",
						height: "100%",
						delta_y:-153,
						text: ['<span class="nuxp_vog_smaller">+2s</span>'],
						tf_delta_x: 0,
						tf_delta_y: 22,
						delta_x: 0,
						place_at_bottom:true,
						animate_to_buffs:true,
						uid:'annc2',
						locking:true,
						and_burst:true,
						and_burst_value:2,
						and_burst_text:'seconds'
							
					};
					
					var annc3:Object = {
						type: 'itemstack_overlay',
						swf_url: 'http://c2.glitch.bz/overlays%2F2011-06-28%2F1309296324_8864.swf',
						duration: 3000,
						itemstack_tsid: 'IMF1K6K9BKN2NE0',
						width: "100%",
						height: "100%",
						delta_y:-153,
						text: ['<span class="nuxp_vog_smaller">+3s</span>'],
						tf_delta_x: 0,
						tf_delta_y: 22,
						delta_x: 0,
						place_at_bottom:true,
						animate_to_buffs:true,
						uid:'annc3',
						locking:true,
						and_burst:true,
						and_burst_value:3,
						and_burst_text:'seconds'
							
					};
					
					var annc4:Object = {
						type: 'itemstack_overlay',
						swf_url: 'http://c2.glitch.bz/overlays%2F2011-06-28%2F1309296322_1908.swf',
						duration: 3000,
						itemstack_tsid: 'IMF1K6K9BKN2NE0',
						width: "100%",
						height: "100%",
						delta_y:-153,
						text: ['<span class="nuxp_vog_smaller">+4s</span>'],
						tf_delta_x: 0,
						tf_delta_y: 22,
						delta_x: 0,
						place_at_bottom:true,
						animate_to_buffs:true,
						uid:'annc4',
						locking:true,
						and_burst:true,
						and_burst_value:4,
						and_burst_text:'seconds'
							
					};
					
					var annc5:Object = {
						uid: 'new_player_burnabee_part3',
						type: "vp_overlay",
						duration: 0,
						locking: true,
						width: 300,
						x: '50%',
						top_y: '25%',
						delay_ms: 0,
						click_to_advance: true,
						bubble_familiar: true,
						text: [
							'<p><span class="nuxp_medium">Click the name of your current location at the bottom of the map for more context.</span></p>'
						]
					}
					
					var annc6:Object = {
						uid: 'new_player_burnabee_part3',
						type: "vp_overlay",
						duration: 0,
						locking: true,
						width: 300,
						x: '50%',
						top_y: '25%',
						delay_ms: 0,
						click_to_advance: false,
						click_to_advance_hubmap_triggered: true, // let's an opening of the hubmap count as a click to advance
						bubble_familiar: true,
						text: [
							'<p><span class="nuxp_medium">Click the name of your current location at the bottom of the map for more context.</span></p>'
						],
						done_cancel_uids: ['nuxp_familiar_graphic'],
						done_anncs: [{
							uid: 'new_player_burnabee_part3.1',
							type: "vp_overlay",
							duration: 0,
							locking: false,
							width: 500,
							x: '50%',
							top_y: '-1000', // HIDE IT! We want it only to listen for the hub map closing and send the done_payload
							delay_ms: 0,
							click_to_advance: false,
							click_to_advance_hubmap_closed_triggered: true, // let's a CLOSING of the hubmap count as a click to advance
							bubble_familiar: true,
							text: [
								'<p><span class="nuxp_medium">THIS IS HIDDEN</span></p>'
							],
							done_payload: {
								overlay_script_name: 'new_player_burnabee_part3' 
							}
						}]
					}
					
					annc1.done_anncs = [annc2];
					annc2.done_anncs = [annc3];
					annc3.done_anncs = [annc4];
					// don't do this if you have pri=2, because the console.dir on the annc will be a stack overflow!
					//annc2.done_anncs = [annc1];
					
					
					model.activityModel.announcements = Announcement.parseMultiple([annc1]);
					did_anything = true;
				}
				else if (txt.indexOf('/annc18') == 0) {
					
					var other:Boolean = words.length > 1 && words[1] == 'other';
					
					TSFrontController.instance.simulateIncomingMsg({
						type: 'location_event',
						announcements: [
							{
								type:Announcement.QUOIN_GOT,
								pc_tsid: pc.tsid+(other?'2':''),
								x: pc.x,
								y: pc.y-(other?200:60),
								stat:'iMG',
								delta: 22,
								quoin_shards: [{
									type:Announcement.QUOIN_GOT,
									pc_tsid: pc.tsid+'1',
									x: pc.x+MathUtil.randomInt(50,200),
									y: pc.y-200+MathUtil.randomInt(-200,200),
									stat:'iMG',
									delta: 15
								},{
									type:Announcement.QUOIN_GOT,
									pc_tsid: pc.tsid+(other?'':'2'),
									x: other?pc.x:pc.x+MathUtil.randomInt(-200,-50),
									y: other?pc.y-60:pc.y-200+MathUtil.randomInt(-200,200),
									stat:'iMG',
									delta: 14
								},{
									type:Announcement.QUOIN_GOT,
									pc_tsid: pc.tsid+'3',
									x: pc.x+MathUtil.randomInt(50,200),
									y: pc.y-200+MathUtil.randomInt(-200,200),
									stat:'iMG',
									delta: 15
								}]
							}
						]
					});
					did_anything = true;
				}
				else if (txt.indexOf('/annc17') == 0) {
					model.activityModel.announcements = Announcement.parseMultiple([
						{
							"type":"vp_overlay",
							"mouse":{
								"dismiss_on_click":true,
								"click_payload":{
									"location_callback":"overlayDismissed"
								},
								"is_clickable":true,
								"allow_multiple_clicks":false
								
							},
							"swf_url":"http://c2.glitch.bz/overlays/2012-06-21/1340320743_9660.swf",
							locking: true
						}
					]);
					did_anything = true;
				}
				else if (txt.indexOf('/annc16') == 0) {
					model.activityModel.announcements = Announcement.parseMultiple([
						{
							over_pack:true,
							at_bottom:true,
							type:'vp_overlay',
							swf_url:'http://c2.glitch.bz/overlays%2F2012-06-13%2F1339631015_7345.swf',
							uid:'whatevs',
							scale_to_stage:true
						}
					]);
					did_anything = true;
				}
				else if (txt.indexOf('/annc15') == 0) {
					model.activityModel.announcements = Announcement.parseMultiple([
						{
							"count":1,
							"orig_x":TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid("IMF1B0EVPHR278C").x,
							"orig_y":TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid("IMF1B0EVPHR278C").y,
							"type":Announcement.FLOOR_TO_BAG,
							"dest_path":"BMF19QK98GR2L1Q/asdadsad",
							"item_class":"banana"
						}
					]);
					did_anything = true;
				}
				else if (txt.indexOf('/annc14') == 0) {
					uid = 'aalkjhasdlhajld';
					var uid2:String = uid+'w2';
					TSFrontController.instance.simulateIncomingMsg({type:MessageTypes.OVERLAY_CANCEL, uid:uid});
					TSFrontController.instance.simulateIncomingMsg({type:MessageTypes.OVERLAY_CANCEL, uid:uid2});
					
					ob = {
						type: 'vp_overlay',
						swf_url:'http://c2.glitch.bz/overlays%2F2012-01-04%2F1325719696_1311.swf',
						state: {text:'yoyo'},
						uid: uid,
						scale_to_stage: true,
						opacity: .2,
						duration: 10000 //this is just here so that it finishes at some point
					}
					
					if (words.length > 1) {
						ob.corner = words[1];
					}
					
					if (words.length > 2) {
						ob.corner_offset_x = words[2];
						ob.corner_offset_y = words[2];
					}
					
					model.activityModel.announcements = Announcement.parseMultiple([ob]);
					
					StageBeacon.setTimeout(TSFrontController.instance.simulateIncomingMsg, 4000, {
						type:MessageTypes.OVERLAY_OPACITY, 
						opacity:1, 
						opacity_ms:300,
						opacity_end:.7,
						opacity_end_delay_ms:300,
						uid:uid
					});
					StageBeacon.setTimeout(TSFrontController.instance.simulateIncomingMsg, 3000, {type:MessageTypes.OVERLAY_STATE, state:{text:'5566'}, uid:uid});
					
					ob = {
						type: 'vp_overlay',
						item_class:'street_spirit_groddle',
						state: 'idle_cry',
						config: {base: 'base_L1dirt', bottom: 'bottom_L1Branches', eyes: 'eyes_L1eyes3', skull: 'skull_L1dirt', top: 'top_L1LeafSprout'},
						uid: uid2,
						scale_to_stage: true,
						use_drop_shadow: true,
						duration: 10000 //this is just here so that it finishes at some point
					}
					
					if (words.length > 1) {
						ob.corner = words[1];
					}
					
					if (words.length > 2) {
						ob.corner_offset_x = words[2];
						ob.corner_offset_y = words[2];
					}
					
					if (words.length > 3) {
						ob.size = words[3];
						delete ob.scale_to_stage;
					}
					
					model.activityModel.announcements = Announcement.parseMultiple([ob]);
					
					did_anything = true;
				}
				else if (txt.indexOf('/annc13') == 0) {
					uid = 'mountain_thing';
					model.activityModel.announcements = Announcement.parseMultiple([{
						type: "location_overlay",
						swf_url: "http://c2.glitch.bz/overlays/2010-07-27/1280244515_2080.swf",
						uid: uid,
						height: 100,
						x: 250,
						y: 0
					}]);
					
					did_anything = true;
				} 
				else if (txt.indexOf('/annc11') == 0) {
					if (LocationCanvasView.instance.annc) {
						AnnouncementController.instance.cancelOverlay(LocationCanvasView.instance.annc.uid);
					} else {
						model.activityModel.announcements = Announcement.parseMultiple([
							{
								type: 'vp_canvas',
								uid: 'whatev',
								canvas: {
									color: '#cc0000',
									steps: [
										{alpha:.8, secs:1},
										{alpha:.5, secs:.2},
										{alpha:.8, secs:.2},
										{alpha:0, secs:.5}
									],
									loop: true,
									loop_details: {
										from: 1,
										to: 2,
										reps: 10
									}
								}
							}

						]);
					}
					did_anything = true;
					
				} 
				else if (txt.indexOf('/annc10') == 0) {
					model.activityModel.announcements = Announcement.parseMultiple([
						{
							type: 'vp_overlay',
							item_class: "plank",
							state: "emote_animation",
							duration: 10000,
							size: "225%",
							msg: pc.label+' splanked you!'
						}
					]);
					did_anything = true;
				} 
				else if (txt.indexOf('/annc9') == 0) {
					item_class = (words.length > 1 && model.worldModel.items[words[1]]) ? words[1] : 'apple'
					model.activityModel.announcements = Announcement.parseMultiple([
						{
							type: "pc_overlay",
							duration: 10000,
							dismissible: false,
							locking: false,
							pc_tsid: pc.tsid,
							delta_x: 0,
							delta_y: -230,
							width: "150",
							height: "150",
							item_class: item_class,
							uid: uid,
							state: 'iconic',
							scale_to_stage: scale_to_stage
						}
					]);
					StageBeacon.setTimeout(function():void {
						AnnouncementController.instance.setOverlayState(
							{
								uid: uid,
								state: 'iconic',
								reposition: reposition
							}
						);
					}, 2000);
					StageBeacon.setTimeout(function():void {
						AnnouncementController.instance.setOverlayState(
							{
								uid: uid,
								state: '3',
								reposition: reposition
							}
						);
					}, 3000);
					StageBeacon.setTimeout(function():void {
						AnnouncementController.instance.setOverlayState(
							{
								uid: uid,
								state: '4',
								reposition: reposition
							}
						);
					}, 4000);
					StageBeacon.setTimeout(function():void {
						AnnouncementController.instance.setOverlayState(
							{
								uid: uid,
								state: '5',
								reposition: reposition
							}
						);
					}, 5000);
					did_anything = true;
				} 
				else if (txt.indexOf('/annc8') == 0) {
					model.activityModel.announcements = Announcement.parseMultiple([
						{
							type: "pc_overlay",
							duration: 10000,
							dismissible: false,
							locking: false,
							pc_tsid: pc.tsid,
							delta_x: 0,
							delta_y: -230,
							width: "150",
							height: "150",
							item_class: 'firefly_jar',
							uid: uid,
							state: 'closed',
							scale_to_stage: scale_to_stage,
							config: {
								num_flies:0
							}
						}
					]);
					StageBeacon.setTimeout(function():void {
						AnnouncementController.instance.setOverlayState(
							{
								uid: uid,
								state: 'opening',
								reposition: reposition,
								config: {
									num_flies:1
								}
							}
						);
					}, 2000);
					StageBeacon.setTimeout(function():void {
						AnnouncementController.instance.setOverlayState(
							{
								uid: uid,
								state: 'open',
								reposition: reposition,
								config: {
									num_flies:2
								}
							}
						);
					}, 3000);
					StageBeacon.setTimeout(function():void {
						AnnouncementController.instance.setOverlayState(
							{
								uid: uid,
								state: 'closing',
								reposition: reposition,
								config: {
									num_flies:3
								}
							}
						);
					}, 4000);
					StageBeacon.setTimeout(function():void {
						AnnouncementController.instance.setOverlayState(
							{
								uid: uid,
								state: 'closed',
								reposition: reposition,
								config: {
									num_flies:4
								}
							}
						);
					}, 5000);
					did_anything = true;
				} 
				else if (txt.indexOf('/annc4') == 0) {
					var AA:Array = ['iconic_plain','iconic_moon','iconic_kiss','iconic_moon_kiss','1_plain','1_moon','1_kiss','1_moon_kiss','moon','hug','kiss']
					StageBeacon.setInterval(function():void {
						model.activityModel.announcements = Announcement.parseMultiple([
							{
								type: "pc_overlay",
								item_class: "emotional_bear",
								duration: 1000,
								state: AA[MathUtil.randomInt(AA.length-2, AA.length-1)],
								width:100,
								height:100,
								pc_tsid: pc.tsid, // the itemstack to target
								delta_x: 0, //delta_x/y indicates position of overlay swf center relative to the bottom center of the itemstack
								delta_y: -120,
								animate_to_top: true
							}
						]);
					}, 2000);
					
					did_anything = true;
				} 
				else if (txt.indexOf('/annc1') == 0) {
					
					model.activityModel.announcements = Announcement.parseMultiple([
						{
							type: "pc_overlay",
							item_class: "apple",
							duration: 10000,
							state: "1",
							dismissible: false,
							dismiss_payload: {
								test:1234
							},
							width: 200,
							height:200,
							bubble:true,
							locking: false,
							pc_tsid: pc.tsid, // the itemstack to target
							delta_x: 0, //delta_x/y indicates position of overlay swf center relative to the bottom center of the itemstack
							delta_y: -114,
							click_to_advance: true,
							text: ['<span class="simple_panel">indicates position of overlay swf center relative to the bottom </span>']
						},{
							type: "pc_overlay",
							item_classs: "apple",
							duration: 10000,
							state: "1",
							dismissible: false,
							dismiss_payload: {
								test:1234
							},
							width: 200,
							height:200,
							bubble:true,
							locking: false,
							pc_tsid: pc.tsid, // the itemstack to target
							delta_x: -300, //delta_x/y indicates position of overlay swf center relative to the bottom center of the itemstack
							delta_y: -114,
							click_to_advance: true,
							text: ['<span class="simple_panel">indicates position of overlay swf center relative to the bottom </span>']
						},{
							type: "pc_overlay",
							item_class: "apple",
							duration: 10000,
							state: "1",
							dismissible: false,
							dismiss_payload: {
								test:1234
							},
							width: 200,
							height:200,
							bubble:true,
							locking: false,
							pc_tsid: pc.tsid, // the itemstack to target
							delta_x: 300, //delta_x/y indicates position of overlay swf center relative to the bottom center of the itemstack
							delta_y: -114,
							text: ['<span class="simple_panel">indicates position of overlay swf center relative to the bottom </span>']
						}
					]);
					did_anything = true;
				} 
				else if (txt.indexOf('/annc2') == 0) {
					
					model.activityModel.announcements = Announcement.parseMultiple([
						{
							"dismiss_payload":{
								"skill_package":"gardening_harvest"
							},
							"locking":true,
							"delta_x":-10,
							"duration":2000,
							"delta_y":20,
							"itemstack_tsid":"IHH101E2OJA1R1A",
							"type":"itemstack_overlay",
							"swf_url":"http://c2.glitch.bz/overlays/2010-07-27/1280244434_3270.swf",
							"__OBJECT_TSID__":"P001",
							"dismissible":true
						} /*,{
						type: "vp_overlay",
						dismissible: false,
						bubble_god:true,
						locking: true,
						click_to_advance: true,
						top_y:1,
						x:'50%',
						width:500,
						text: [
						'<p align="center"><span class="nuxp_vog">ygHELLO THERE.</span></p>',
						'<span class="nuxp_vog">ygHELLO THERE.</span>',
						'<p align="center"><span class="nuxp_vog">ygHELLO THERE. HELLO THERRE. HELLO. HELLO THERRE. HELLO THERE.</span></p>',
						'<p align="center"><span class="nuxp_vog">gHyELLLLLO THERE. HELLO THERRE. HELLO THERE. THERE. HELLO THERE. HELLO THERE. HELLO THERE. HELLO THERE. HELLO THERE. HELLO THERE.</span></p>',
						'<p align="center"><span class="nuxp_medium">ygHELLO THERE.</span></p>',
						'<p align="center"><span class="nuxp_medium">ygHELLO THERE. HELLO THERRE. HELLO. HELLO THERRE. HELLO THERE.</span></p>',
						'<p align="center"><span class="nuxp_medium">ygHELLLLLO THERE. HELLO THERRE. HELLO THERE. THERE. HELLO THERE. HELLO THERE. HELLO THERE. HELLO THERE. HELLO THERE. HELLO THERE.HELLLLLO THERE. HELLO THERRE. HELLO THERE. THERE. HELLO THERE. HELLO THERE. HELLO THERE. HELLO THERE. HELLO THERE. HELLO THERE.</span></p>'
						]
						},{
						type: "pc_overlay",
						duration: 10000,
						state: "1",
						locking: true,
						pc_tsid: pc.tsid, // the itemstack to target
						delta_x: 0, //delta_x/y indicates position of overlay swf center relative to the bottom center of the itemstack
						delta_y: -114,
						item_class: 'apple'
						},
						{
						type: "pc_overlay",
						duration: 10000,
						state: "1",
						dismissible: false,
						dismiss_payload: {
						test:1234
						},
						bubble:true,
						locking: false,
						pc_tsid: pc.tsid, // the itemstack to target
						delta_x: -300, //delta_x/y indicates position of overlay swf center relative to the bottom center of the itemstack
						delta_y: -114,
						click_to_advance: true,
						text: [
						'<span class="simple_panel">no width/height, Ted Danson .</span>',
						'<span class="simple_panel">no width/height, last</span>'
						]
						},
						{
						type: "pc_overlay",
						item_class: "apple",
						duration: 10000,
						state: "1",
						dismissible: false,
						dismiss_payload: {
						test:1234
						},
						bubble:true,
						locking: false,
						pc_tsid: pc.tsid, // the itemstack to target
						delta_x: 300, //delta_x/y indicates position of overlay swf center relative to the bottom center of the itemstack
						delta_y: -114,
						click_to_advance: true,
						text: [
						'<span class="simple_panel">no width/height, Ted Danson said the "fish" enjoyed by millions of Britons in their fish and chips could be "spiny dogfish", a rare species of shark</span>',
						'<span class="simple_panel">no width/height, last</span>'
						]
						}*/
					]);
					did_anything = true;
				} 
				else if (txt.indexOf('/annc6') == 0) {
					StageBeacon.setTimeout(function():void {
						model.activityModel.announcements = Announcement.parseMultiple([
							{
								type: "pc_overlay",
								duration: 7500,
								dismissible: false,
								locking: true,
								pc_tsid: pc.tsid,
								delta_x: 0,
								delta_y: 30,
								width: "250",
								height: "300",
								swf_url: 'http://c2.glitch.bz/overlays%2F2010-07-27%2F1280244221_2438.swf'
							}
						]);
					}, 3000);
					did_anything = true;
				} 
				else if (txt.indexOf('/annc7') == 0) {
					model.activityModel.announcements = Announcement.parseMultiple([
						{
							type: 'pc_overlay',
							item_class: "fertilidust",
							duration: 8000,
							state: 'tool_animation',
							pc_tsid: pc.tsid,
							locking: false,
							dismissible: false,
							delta_x: -75,
							delta_y: -120,
							width: 80,
							height: 80
						},
						{
							type: 'pc_overlay',
							item_class: "fertilidust_lite",
							duration: 8000,
							state: 'tool_animation',
							pc_tsid: pc.tsid,
							locking: false,
							dismissible: false,
							delta_x: 75,
							delta_y: -120,
							width: 80,
							height: 80
						}/*,
						{
							type: "pc_overlay",
							duration: 7500,
							dismissible: false,
							locking: false,
							pc_tsid: pc.tsid,
							delta_x: -100,
							delta_y: 0,
							item_class: "fertilidust",
							state: 'tool_animation',
							width:300,
							height:300
						},
						{
							type: "pc_overlay",
							duration: 7500,
							dismissible: false,
							locking: false,
							pc_tsid: pc.tsid,
							delta_x: 100,
							delta_y: 0,
							item_class: "fertilidust_lite",
							state: 'tool_animation',
							width:300,
							height:300
						}*/
					]);
					did_anything = true;
				} 
				else if (txt.indexOf('/annc5') == 0) {
					model.activityModel.announcements = Announcement.parseMultiple([
						{
							type: "familiar_to_pack",
							dest_path: "",
							dest_slot: "3",
							count: 2,
							item_class: "apple"
						}
					]);
					
					StageBeacon.setTimeout(function():void {
						model.activityModel.announcements = Announcement.parseMultiple([
							{
								type: "familiar_to_floor",
								dest_x: pc.x,
								dest_y: pc.y,
								count: 3,
								item_class: "apple"
							}
						]);
					}, 2000);
					did_anything = true;
				} 
				else if (txt.indexOf('/annc3') == 0) {
					
					model.activityModel.announcements = Announcement.parseMultiple([
						/*{
						type: "vp_overlay",
						item_classs: "apple",
						swf_url: "http://c2.glitch.com/overlays/2010-05-26/1274910288_8423.swf",
						duration: 0,
						dismissible: false,
						locking: false,
						click_to_advance: true,
						text: [
						'<span class="achievement_description">Ted Danson said the "fish" enjoyed by millions of Britons in their fish and chips could be "spiny dogfish", a rare species of shark</span>',
						'<span class="achievement_description">srsly</span>'
						],
						x: '50%',
						y: '0%'
						},*/
						{
							type: "vp_overlay",
							item_class: "apple",
							duration: 0,
							y: '1',
							width: 200,
							height:200
							
						},
						{
							type: "vp_overlay",
							item_class: "apple",
							duration: 0,
							x: '0%',
							top_y: 1,
							width: 200,
							height:200
							
						},
						{
							type: "vp_overlay",
							item_class: "apple",
							duration: 0,
							text: [
								'<span class="achievement_description">Ted Danson said the "fish" enjoyed by millions of Britons in their fish and chips could be "spiny dogfish", a rare species of shark</span>',
								'<span class="achievement_description">srsly</span>'
							],
							x: '100%',
							y: '1',
							width: 200,
							height:200
							
						},
						{
							type: "vp_overlay",
							click_to_advance: true,
							bubble_familiar: true,
							iitem_class: "apple",
							duration: 0,
							text: [
								'<span class="achievement_description">Ted Danson said the "fish" enjoyed by millions of Britons in their fish and chips could be "spiny dogfish", a rare species of shark</span>',
								'<span class="achievement_description">srsly</span>'
							],
							x: '50%',
							top_y: 300,
							width: 200,
							height:200
							
						},
						{
							type: "vp_overlay",
							click_to_advance: true,
							bubble_god: true,
							item_class: "apple",
							duration: 0,
							text: [
								'<span class="achievement_description">Ted Danson said the "fish" enjoyed by millions of Britons in their fish and chips could be "spiny dogfish", a rare species of shark</span>',
								'<span class="achievement_description">srsly</span>'
							],
							x: '75%',
							top_y: 300,
							width: 200,
							height:200
							
						}
					]);
					did_anything = true;
				} 
				else if (txt.indexOf('/echo_annc ') == 0) { // assures us words.length > 1
					/*
					/echo_annc test text:['cat drink', 'dog eat'], ob:{t:2, g:'yt'}
					
					
					/echo_annc pc_overlay {"swf_key":"overlay_sparkle_powder_flv","duration":6000,"delay_ms":0,"size":"150%"}
					/echo_annc pc_overlay {"swf_key":"overlay_sparkle_powder","duration":6000,"delay_ms":0,"size":"150%"}
					/echo_annc pc_overlay {"duration":"5000","swf_key":"trading","bubble":true}
					/echo_annc pc_overlay {"duration":5000,"delta_x":0,"delta_y":-110,"bubble":true,"width":40,"height":40,"swf_key":"trading"}
					/echo_annc pc_overlay {"duration":5000,"delta_x":0,"delta_y":-110,"bubble":true,"width":40,"height":40,"swf_url":"http://localhost:81/ts/swf/trading.swf"}
					{"width":80,"delta_y":-110,"state":"tool_animation","height":80,"type":"pc_overlay","bubble":true,"duration":5000,"item_class":"blender","delta_x":0}} 
					*/
					
					
					var annc:Object = {
						type: words[1]
					}
					
					if (annc.type == 'pc_overlay' && words.length > 2 && words[2] == 'tool_animations') {
						var toolA:Array = [];
						for (var kk:String in model.worldModel.items) {
							if (model.worldModel.getItemByTsid(kk).tags.indexOf('tool') > -1) {
								toolA.push(model.worldModel.getItemByTsid(kk).tsid);
							}
						}
						toolA.sort();
						
						var size:int = (words.length > 3) ? words[3] : 40;
						
						var ta_annc:Object = {
							"width":size,
							"delta_y":-110,
								"delta_x":0,
								"state":"tool_animation",
								"height":size,
								"type":"pc_overlay",
								"bubble":true,
								"duration":20000,
								"item_class":"",
								"delta_x":0
						}
						
						for (var ii:int=0; ii<toolA.length; ii++) {
							ta_annc.item_class = toolA[ii];
							ta_annc.delta_x = ii*ta_annc.width-((toolA.length/2)*ta_annc.width);
							ta_annc.delta_y = (ii%2 == 0) ? -110 : -110-(ta_annc.width*2.5);
							TSFrontController.instance.sendAnonMsg({
								type: 'echo_annc',
								annc: ta_annc
							});
						}
						
					} else {
						
						if (words.length > 2) {
							var json:String = '';
							if (words[2].indexOf('{') == 0) { // it looks like it is json, use it
								json = words[2];
							} else {
								// not doing anything real smart here yet/
								// we coudl splt into pairs on " ", strip all commas,split each of those with ":", add quotes areound them,
								// and then add the "{}", but we'll see if it is needed
								
								json = '{'+txt.substr(txt.indexOf(words[2]))+'}';
							}
							
							// if there are no "s replace all 's with "s
							if (json.indexOf('"') == -1) json = json.replace(/\'/g, '"');
							try {
								CONFIG::debugging {
									Console.warn(json);
								}
								var ob:Object = com.adobe.serialization.json.JSON.decode(json);
								for (var k:String in ob) {
									annc[k] = ob[k];
								}
							} catch (err:Error) {
								CONFIG::debugging {
									Console.error('could not decode '+json+' as JSON');
								}
							}
						}
						CONFIG::debugging {
							Console.dir(annc);
						}
						TSFrontController.instance.sendAnonMsg({
							type: 'echo_annc',
							annc: annc
						});
					}
					did_anything = true;
				} 
				else if (txt == '/annc') {
					
					/*	StageBeacon.setTimeout(function():void {
					TSFrontController.instance.startMovingAvatarOnGSPath(new Point(pc.x+800, pc.y));
					model.stateModel.camera_offset_x = 300;
					}, 100)*/
					
					model.activityModel.announcements = Announcement.parseMultiple([/*{
						type: "location_overlay",
						item_class: "apple",
						duration: 8000,
						state: "4",
						dismissible: false,
						dismiss_payload: {
						test:1234
						},
						bubble:true,
						locking: true,
						x: pc.x,
						y: pc.y
						},{
						type: "pc_overlay",
						item_class: "apple",
						duration: 6000,
						state: "-4",
						dismissible: true,
						dismiss_payload: {
						test:1234
						},
						bubble:true,
						locking: true,
						pc_tsid: pc.tsid, // the itemstack to target
						delta_x: 0, //delta_x/y indicates position of overlay swf center relative to the bottom center of the itemstack
						delta_y: -114,
						
						},*/{
							type: "pc_overlay",
							item_class: "apple",
							duration: 10000,
							state: "1",
							dismissible: false,
							dismiss_payload: {
								test:1234
							},
							width: 200,
							height:200,
							bubble:true,
							locking: false,
							pc_tsid: pc.tsid, // the itemstack to target
							delta_x: 0, //delta_x/y indicates position of overlay swf center relative to the bottom center of the itemstack
							delta_y: -114,
							click_to_advance: true,
							text: ['<span class="simple_panel">indicates position of overlay swf center relative to the bottom </span>']
						},{
							type: "pc_overlay",
							item_classs: "apple",
							duration: 10000,
							state: "1",
							dismissible: false,
							dismiss_payload: {
								test:1234
							},
							width: 200,
							height:200,
							bubble:true,
							locking: false,
							pc_tsid: pc.tsid, // the itemstack to target
							delta_x: -300, //delta_x/y indicates position of overlay swf center relative to the bottom center of the itemstack
							delta_y: -114,
							click_to_advance: true,
							text: ['<span class="simple_panel">indicates position of overlay swf center relative to the bottom </span>']
						},{
							type: "pc_overlay",
							item_class: "apple",
							duration: 10000,
							state: "1",
							dismissible: false,
							dismiss_payload: {
								test:1234
							},
							width: 200,
							height:200,
							bubble:true,
							locking: false,
							pc_tsid: pc.tsid, // the itemstack to target
							delta_x: 300, //delta_x/y indicates position of overlay swf center relative to the bottom center of the itemstack
							delta_y: -114,
							tdext: ['<span class="simple_panel">indicates position of overlay swf center relative to the bottom </span>']
						},/*,{
						type: "pc_overlay",
						item_class: "pick",
						duration: 18000,
						state: "tool_animation",
						dismissible: false,
						height: 300,
						width: 100,
						uid: "tttt",
						dismiss_payload: {
						test:1234
						},
						bubble:true,
						locking: false,
						pc_tsid: pc.tsid, // the itemstack to target
						delta_x: -110, //delta_x/y indicates position of overlay swf center relative to the bottom center of the itemstack
						delta_y: -214
						},{
						type: "pc_overlay",
						item_class: "pick",
						duration: 18000,
						state: "-tool_animation",
						dismissible: true,
						dismiss_payload: {
						test:1234
						},
						height: 40,
						width: 40,
						uid: "mmmm",
						bubble:true,
						locking: false,
						pc_tsid: pc.tsid, // the itemstack to target
						delta_x: -220, //delta_x/y indicates position of overlay swf center relative to the bottom center of the itemstack
						delta_y: -114
						},*/{
							type: "vp_overlay",
							item_classs: "apple",
							swf_url: "http://c2.glitch.com/overlays/2010-05-26/1274910288_8423.swf",
							duration: 5000,
							dismissible: false,
							locking: false,
							click_to_advance: true,
							text: ['<span class="achievement_description">Ted Danson said the "fish" enjoyed by millions of Britons in their fish and chips could be "spiny dogfish", a rare species of shark</span>'],
							x: 0,
							y: 0
						}/*,{
						type: "vp_overlay",
						item_classs: "apple",
						swf_url: "http://c2.glitch.com/overlays/2010-05-26/1274910288_8423.swf",
						duration: 5000,
						dismissible: false,
						locking: false,
						text: ['<span class="achievement_description">Ted Danson said the "fish" enjoyed by millions of Britons in their fish and chips could be "spiny dogfish", a rare species of shark</span>']
						},{
						type: "window_overlay",
						item_class: "apple",
						duration: 5000,
						state: "6",
						dismissible: false,
						locking: true,
						size: 40,
						x: '0',
						y: '0'
						},{
						type: "window_overlay",
						swf_url: "http://c2.glitch.com/overlays/2010-05-17/1274150330_9026.swf",
						state: {
						scene:'apple'
						},
						duration: 12000,
						size: "100%",
						msg: "thingie",
						locking: false
						},{
						type: 'play_music',
						mp3_url: 'http://www.glish.com/best_option/mp3/you-called-me.mp3'
						},{
						type: "window_overlay",
						swf_url: "http://c2.glitch.com/overlays/2010-05-13/1273776320_8307.swf",
						item_class: 'trant_egg',
						state: {
						m:9,
						h:9,
						f_cap:10,
						f_num:10
						},
						duration: 6000,
						size: "100%",
						msg: "Myles Bot splanked you!"
					}*/])
					
					StageBeacon.setTimeout(function():void {
						//AnnouncementController.instance.cancelOverlay('tttt');
					}, 5000);
					StageBeacon.setTimeout(function():void {
						//AnnouncementController.instance.cancelOverlay('tttt');
					}, 6000);
					StageBeacon.setTimeout(function():void {
						//AnnouncementController.instance.cancelOverlay('mmmm');
					}, 7000);
					did_anything = true;
				} 
				else if (txt == '/mg') {
					var mgr:MiddleGroundRenderer = TSFrontController.instance.getMainView().gameRenderer.locationView.middleGroundRenderer;
					if (mgr is MiddleGroundRenderer) {
						System.setClipboard(DisplayDebug.LogCoords(MiddleGroundRenderer(mgr), 1));
					} else {
						
					}
					
					did_anything = true;
				} 
				else if (txt == '/dd') {
					System.setClipboard(DisplayDebug.LogCoords(StageBeacon.stage, 2));
					
					did_anything = true;
				} 
				else if (txt == '/phantom') {
					System.setClipboard(DisplayDebug.LogCoords(TSFrontController.instance.getMainView().gameRenderer, 2));
					activityTextHandler('ADMIN: The debug data has been put in your clipboard, pastebin it now!');
					
					did_anything = true;
				} 
				else if (txt.indexOf('/input_cancel') == 0) {
					InputDialog.instance.cancelUID('UID0001');
					did_anything = true;
				} 
				else if (txt.indexOf('/name2') == 0) {
					InputTalkBubble.instance.start({
						"input_focus":true,
						"title":"Rename Yourself!",
						"follow":true,
						"cancelable":true,
						"check_user_name":true,
						"input_label":"Choose a character name.",
						"input_max_chars":19,
						"itemstack_tsid":words.length>1?words[1]:"BPF11CTIPE133FL",
						"uid":"namesadsad"
					});
					did_anything = true;
				}
				else if (txt.indexOf('/name') == 0) {
					InputTalkBubble.instance.start({
						"input_focus":true,
						"title":"Rename Yourself!",
						"cancelable":false,
						"follow":true,
						"check_user_name":true,
						"input_label":"Choose a character name.",
						"input_max_chars":19,
						"itemstack_tsid":words.length>1?words[1]:"BPF11CTIPE133FL",
						"uid":"namesadsad"
					});
					did_anything = true;
				}
				else if (txt.indexOf('/input') == 0) {
					InputDialog.instance.startWithPayload({
						title:'hi',
						subtitle:'bye',
						input_value: 'fck:' // default = ''
					});
					InputDialog.instance.startWithPayload({
						// required
						title: 'Wish',
						uid: 'UID0001', // sent back in response message of type input_response, like:
						/*
						{
						type: 'input_response',
						uid: 'UID0001',
						value: 'Whatever they entered'
						}
						*/
						//optional
						input_focus: true,
						input_rows:10,
						subtitle: '(But don\'t tell anybody.)', // default = ''
						cancel_label: 'cancel', // default = 'Cancel'
						submit_label: 'submit', // default = 'Submit'
						input_label: 'Your wish:', // default = ''
						input_description: 'Please enter the thing you would like most out of life', // default = ''
						cancelable: false // default = true (if false, cancel button is not shown, and no X in top right, and no esc key)
						
					});
					/*InputDialog.instance.startWithPayload({
						// required
						title: 'label & desc',
						uid: 'UID0001', // sent back in response message of type input_response, like:
						//optional
						input_label: 'Your wish:', // default = ''
						input_description: 'Please enter the thing you would like most out of life', // default = ''
						cancelable: false, // default = true (if false, cancel button is not shown, and no X in top right, and no esc key)
						itemstack_tsid: 'dddd'
						
					});
					InputDialog.instance.startWithPayload({
						// required
						title: 'sub and label',
						uid: 'UID0001', // sent back in response message of type input_response, like:
						//optional
						subtitle: '(But don\'t tell anybody.)', // default = ''
						input_label: 'Your wish:', // default = ''
						cancelable: false // default = true (if false, cancel button is not shown, and no X in top right, and no esc key)
						
					});
					InputDialog.instance.startWithPayload({
						// required
						title: 'sub and desc',
						uid: 'UID0001', // sent back in response message of type input_response, like:
						//optional
						subtitle: '(But don\'t tell anybody.)', // default = ''
						input_description: 'Please enter the thing you would like most out of life', // default = ''
						cancelable: false // default = true (if false, cancel button is not shown, and no X in top right, and no esc key)
						
					});
					InputDialog.instance.startWithPayload({
						// required
						title: 'cancelable',
						uid: 'UID0001', // sent back in response message of type input_response, like:
						//optional
						cancelable: true // default = true (if false, cancel button is not shown, and no X in top right, and no esc key)
						
					});*/
					did_anything = true;
				} 
				else if (txt.indexOf('/check') == 0) {
					
					if (words.length == 1) {
						TSFrontController.instance.simulateIncomingMsg({
							type: MessageTypes.LOC_CHECKMARK,
							txt: 'hi2! '+getTimer()
						});
					} else if(words[1] == 'annc') {
						TSFrontController.instance.simulateIncomingMsg({
							type: 'location_event',
							announcements: [{
								type: "vp_overlay",
								bubble_god: true,
								duration: 0,
								text: [
									'<span class="achievement_description">Ted Danson said the "fish" enjoyed by millions of Britons in their fish and chips could be "spiny dogfish", a rare species of shark</span>',
									'<span class="achievement_description">srsly</span>'
								],
								x: '75%',
								top_y: 300,
								width: 200,
								height:200,
								uid: 'check_test'
							}]
						});
						
						StageBeacon.setTimeout(function():void {
							TSFrontController.instance.simulateIncomingMsg({
								type: MessageTypes.LOC_CHECKMARK,
								txt: 'hi! '+getTimer(),
								annc_uid: 'check_test'
							});
						}, 1000);
						
						StageBeacon.setTimeout(function():void {
							AnnouncementController.instance.cancelOverlay('check_test');
						}, 4000);
					} else if (words[1] == 'deco' && words.length > 2) {
						TSFrontController.instance.simulateIncomingMsg({
							type: MessageTypes.LOC_CHECKMARK,
							txt: 'hi2! '+getTimer(),
							deco_name: words[2]
						});
						TSFrontController.instance.simulateIncomingMsg({
							type: MessageTypes.DECO_VISIBILITY,
							visible: false,
							deco_name: words[2],
							fade_ms: 2000
						});
						StageBeacon.setTimeout(function():void {
							TSFrontController.instance.simulateIncomingMsg({
								type: MessageTypes.DECO_VISIBILITY,
								visible: true,
								deco_name: words[2],
								fade_ms: 5000
							});
						}, 2000);
					}
					did_anything = true;
				} 
				else if (txt.indexOf('/debug_choices') == 0) {
					CONFIG::debugging {
						Console.info('ChoicesDialog.instance.parent:'+ChoicesDialog.instance.parent);
						if (ChoicesDialog.instance.parent) {
							Console.info('ChoicesDialog.instance.parent.visible:'+ChoicesDialog.instance.parent.visible)
							Console.info('ChoicesDialog.instance.parent.parent:'+ChoicesDialog.instance.parent.parent)
						}
					}
					DisplayDebug.LogCoords(ChoicesDialog.instance, 4);
					DisplayDebug.LogParents(ChoicesDialog.instance.parent);
					did_anything = true;
				}
				else if (txt.indexOf('/missile') == 0) {
					ob = null;
					
					if (words.length>1 && words[1] == 'butler') {
						var bulterA:Array = model.worldModel.getLocationItemstacksAByItemClass('bag_butler');
						if (!bulterA.length) {
							CONFIG::debugging {
								Console.warn('no butler');
							}
						} else {
							ob = {
								emote: "hi",
								accelerate: true,
								emote_shards: [{
									mood_granted:5,
									pc_tsid: pc.tsid
								}],
								itemstack_tsid: bulterA[0].tsid,
								type: "emote",
								variant: "cubes",
								delta_y: 0
							}
						}
					} else {
						ob = {
							emote: "hi",
							accelerate: true,
							emote_shards: [{
								mood_granted:5,
								pc_tsid: pc.tsid
							}],
							pc_tsid: pc.tsid,
							type: "emote",
							variant: "cubes",
							delta_y: -134
						}
					}
					
					if (ob) model.activityModel.announcements = Announcement.parseMultiple([ob]);
					did_anything = true;
				}
				else if (txt.indexOf('/pack_visible') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						pack: !model.worldModel.location.show_pack
					});
					did_anything = true;
				} 
				else if (txt.indexOf('/account_required_features_visible') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						account_required_features: model.worldModel.location.no_account_required_features
					});
					did_anything = true;
				} 
				else if (txt.indexOf('/stats_visible') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						stats: !model.worldModel.location.show_stats
					});
					did_anything = true;
				} 
				else if (txt.indexOf('/hubmap_visible') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						hubmap: !model.worldModel.location.show_hubmap
					});
					did_anything = true;
				}
				else if (txt.indexOf('/stats_visible') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						stats: !model.worldModel.location.show_stats
					});
					did_anything = true;
				}
				else if (txt.indexOf('/minimap_visible') == 0 || txt == '/minimap_visible') {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						map: !model.worldModel.location.show_map
					});
					did_anything = true;
				}
				else if (txt.indexOf('/resnap_minimap') == 0) {
					TSFrontController.instance.resnapMiniMap(words.length > 1 ? Boolean(words[2]) : false);
					did_anything = true;
				}
				else if (txt.indexOf('/avatar_visible') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						avatar: !model.worldModel.location.show_avatar
					});
					did_anything = true;
				}
				else if (txt.indexOf('/avatar_config') == 0) {
					if (!NewAvaConfigDialog.instance.parent) {
						NewAvaConfigDialog.instance.start();
					}
					did_anything = true;
				}
				else if (txt.indexOf('/tips_visible') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						tips: TipDisplayManager.instance.paused
					});
					did_anything = true;
				}
				else if (txt.indexOf('/furniture_bag_visible') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						furniture_bag: loc.no_furniture_bag
					});
					did_anything = true;
				}
				else if (txt.indexOf('/swatches_button_visible') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						swatches_button: loc.no_swatches_button
					});
					did_anything = true;
				}
				else if (txt.indexOf('/expand_buttons_visible') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						expand_buttons: loc.no_expand_buttons
					});
					did_anything = true;
				}
				else if (txt.indexOf('/mood_visible') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						mood: loc.no_mood
					});
					did_anything = true;
				}
				else if (txt.indexOf('/energy_visible') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						energy: loc.no_energy
					});
					did_anything = true;
				}
				else if (txt.indexOf('/imagination_visible') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						imagination: loc.no_imagination
					});
					did_anything = true;
				}
				else if (txt.indexOf('/decorate_button_visible') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						decorate_button: loc.no_decorate_button
					});
					did_anything = true;
				}
				else if (txt.indexOf('/cultivate_button_visible') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						cultivate_button: loc.no_cultivate_button
					});
					did_anything = true;
				}
				else if (txt.indexOf('/current_location_visible') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						current_location: loc.no_current_location
					});
					did_anything = true;
				}
				else if (txt.indexOf('/currants_visible') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						currants: loc.no_currants
					});
					did_anything = true;
				}
				else if (txt.indexOf('/search_visible') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						inventory_search: loc.no_inventory_search
					});
					did_anything = true;
				}
				else if (txt.indexOf('/account_required_features_visible') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.UI_VISIBLE,
						account_required_features: loc.no_account_required_features
					});
					did_anything = true;
				}
				else if (txt.indexOf('/pack_animate') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.ANIMATE_PACK_SLOTS,
						is_showing: words.length > 1 ? (words[i] as Boolean) : true
					});
					did_anything = true;
				}
				else if (txt.indexOf('/sign_txt') == 0) {
					if (words.length > 1) {
						TSFrontController.instance.simulateIncomingMsg({
							type: MessageTypes.DECO_SIGN_TXT,
							txt: words.length>2 ? words.concat().splice(2).join(' ') : 'unspecified text!',
							deco_name: words[1]
						});
					}
					did_anything = true;
				} 
				else if (txt.indexOf('/getinfo ') == 0) {
					if (words.length > 1) {
						TSFrontController.instance.simulateIncomingMsg({
							type: MessageTypes.GET_ITEM_INFO,
							class_tsid: words[1],
							is_new: true,
							callback_msg_when_closed: 'rumple',
							xp: 20
						});
					}
					did_anything = true;
				} 
				else if (txt.indexOf('/game_splash_screen') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						"tsid":"race",
						"show_rays":true,
						"buttons":{
							"delta_x":0,
							"is_vertical":false,
							"delta_y":20,
							"values": {
								"0":{
									"label":"Leave the Game",
									"w":150,
									"click_payload":{
										"pc_callback":"games_leave_instance_overlay",
										"does_close":true,
										"choice":"leave"
									},
									"type":"minor",
									"size":"default"
								}
							},
							"padding":10
						},
						"type":"game_splash_screen",
						"graphic":{
							"scale":1,
							"url":"http://c2.glitch.bz/overlays/2011-10-20/1319138424_6879.swf",
							"frame_label":"you_winner"
						}
					});
					did_anything = true;
				} 
				else if (txt.indexOf('/howl') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						"type":"location_event",
						"announcements":[
							{
								"text":["<span class=\"simple_panel\">I'm with you in Rockland\n     where fifty more shocks will never return your\n     soul to its body again from its pilgrimage to a\n     cross in the void</span>"],
								"delta_x":10,
								"duration":8000,
								"follow":false,
								"bubble_talk":true,
								"itemstack_tsid":"IMF18Q3GTJG2626",
								"type":"itemstack_overlay",
								"height":"100",
								"dismissible":false,
								"uid":"IMF1383UH0H2B6E_bubble",
								"delta_y":0,
								"width":"300"
							}
						]
					});
				} 
				else if (txt.indexOf('/achv') == 0) {
					payload = {
						type: 'achievement_complete',
						tsid: '1star_cuisinartist',
						name: '1-Starp Cuisinartistp',
						desc: 'Whipped up 11 meals with an Awesome Pot',
						status_text: 'Now you\'re cooking! You just earned the title 1-Star Cuisinartist.',
						swf_url:'http://c2.glitch.bz/achievements/2011-09-10/re_peater_1315686006.swf',
						is_shareworthy: words.length > 2 ? words[2] : true,
						rewards: { mood: 30, energy: 40, imagination: 50 }
					}
						
					if (words.length > 1 && words[1] == 'q') {
						TSFrontController.instance.addToScreenViewQ(new ScreenViewQueueVO(
							AchievementView.instance.show,
							payload,
							true
						));
						
						if (txt.indexOf('/achv-and-level') == 0) {
							TSFrontController.instance.addToScreenViewQ(new ScreenViewQueueVO(
								LevelUpView.instance.show,
								{stats: {level: 111}},
								true
							));
						}
						
					} else {
						CONFIG::debugging {
							Console.info(AchievementView.instance.show(payload));
						}
						if (txt.indexOf('/achv-and-level') == 0) {
							LevelUpView.instance.show({stats: {level: 111}});
						}
					}

					did_anything = true;
				} 
				else if (txt.indexOf('/level ') == 0) {
					if (words.length > 1) {
						TSFrontController.instance.addToScreenViewQ(new ScreenViewQueueVO(
							LevelUpView.instance.show,
							{
								stats: {
									level: int(words[1])
								},
								rewards: {
									mood: 10,
									energy: 30,
									currants: 100,
									favor: {
										0: {
											giant: 'all',
											points: 10
										}
									}
								}
							},
							true
						));
					}
					did_anything = true;
				}
				else if (txt.indexOf('/collection') == 0) {
					// EC: note that this does not seem to be the same thing as snt by the GS
					// SY: tweaked it slightly to better resemble. Myles is sending desc for each trophy_items which will be ignored
					payload = {        
						name		: "Musicblock DG Collector",
						status_text : "You collected all five DG music blocks. Now you can rock out with your block out. Well, not really.",
						trophy		: {
							label		: "DG Music Trophy", 
							desc		: "The DG Music Trophy",
							class_tsid	: "trophy_music_d_green"
						},
						rewards		: {
							xp			: 300, 
							energy		: 20, 
							mood		: 10, 
							currants	: 1337
						},
						trophy_items	: {
							"0"	: {
								class_tsid	: "musicblock_d_green_01",
								label		: "Musicblock DG-1",
								sound		: "http:\/\/c2.glitch.bz\/sounds\/2010-06\/1276800091-D_green_1_Front_Porch.mp3"
							},
							"1"	: {
								class_tsid	: "musicblock_d_green_02",
								label		: "Musicblock DG-2",
								sound		: "http:\/\/c2.glitch.bz\/sounds\/2010-06\/1276800103-D_green_2_Travelin_Banjer.mp3"
							},
							"2"	: {
								class_tsid	: "musicblock_d_green_03",
								label		: "Musicblock DG-3",
								sound		: "http:\/\/c2.glitch.bz\/sounds\/2010-06\/1276800120-D_green_3_Kiss_Me_Quickly__corrected_.mp3"
							},
							"3"	: {
								class_tsid	: "musicblock_d_green_04",
								label		: "Musicblock DG-4",
								sound		: "http:\/\/c2.glitch.bz\/sounds\/2010-06\/1276800135-D_green_4_Think_About_It.mp3"
							},
							"4"	: {
								class_tsid	: "musicblock_d_green_05",
								label		: "Musicblock DG-5",
								sound		: "http:\/\/c2.glitch.bz\/sounds\/2010-06\/1276800150-D_green_5_How_the_West_Was_Won.mp3"
							}
						}
					};
					
					if (words.length > 1 && words[1] == 'q') {
						TSFrontController.instance.addToScreenViewQ(new ScreenViewQueueVO(
							CollectionCompleteView.instance.show,
							payload,
							true
						));
					} else {
						CollectionCompleteView.instance.show(payload);
					}
					did_anything = true;
				}
				else if (txt == '/skill after conv') {
					
					TSFrontController.instance.sendLocalChat(new NetOutgoingLocalChatVO('/familiar_push'));
					TSFrontController.instance.sendLocalChat(new NetOutgoingLocalChatVO('/familiar_push'));
					
					// a timeout to make sure /familiar_push takes effect before startFamiliarSkillMessageWithPayload
					StageBeacon.setTimeout(function():void {
						TSFrontController.instance.startFamiliarSkillMessageWithPayload({
							"desc":"This improvement in your Gardening skill allows you to harvest twice as fast as before with no reduction in efficacy while simultaneously rewarding you with XP for both the harvest and pet actions.",
							"tsid":"gardening_2",
							"name":"Gardening II"
						});
					}, 5000);
					did_anything = true;
				} 
				else if (txt == '/skill') {
					TSFrontController.instance.startFamiliarSkillMessageWithPayload({
						"desc":"This improvement in your Gardening skill allows you to harvest twice as fast as before with no reduction in efficacy while simultaneously rewarding you with XP for both the harvest and pet actions.",
						"tsid":"gardening_2",
						"name":"Gardening II"
					});
					did_anything = true;
				} 
				else if (txt.indexOf('/msgs ') == 0) {
					if (words.length > 1) {
						var which:String = 'all';
						if (words.length > 2) {
							which = words[2];
						}
						
						var net_msgs:Array = LocalStorage.instance.getLogData() || [];
						CONFIG::debugging {
							Console.info('LocalStorage.NET_MSGS: '+net_msgs.length);
						}
						net_msgs = net_msgs.concat(model.activityModel.net_msgs);
						CONFIG::debugging {
							Console.info('total net_msgs: '+net_msgs.length);
						}
						
						var how_many:int = Math.min(net_msgs.length, parseInt(words[1]));
						CONFIG::debugging {
							Console.info('Getting last '+how_many+' of '+net_msgs.length+' messages...');
						}
						var all_txt:String = '\n\n';
						
						var tempA:Array = [];
						var msg:Object;
						
						for (i=net_msgs.length-1;i>-1;i--) {
							msg = net_msgs[int(i)];
							
							if (which == 'all' || ['location_item_moves','location_event','item_state','itemstack_status','pc_move_xy','move_xy'].indexOf(msg.type) == -1) {
								tempA.unshift(StringUtil.getJsonStr(msg));
							}
							if (tempA.length >= how_many) {
								break;
							}
						}
						
						all_txt = tempA.join(',\n\n');
						
						System.setClipboard(all_txt);
						activityTextHandler('ADMIN: The messages have been put in your clipboard (and no longer output to console)');
						//Console.log(0, all_txt);
					}
					did_anything = true;
				}
				else if (txt.indexOf('/growl') == 0) {
					var growlTxt:String = "The quick brown fox jumps over the lazy dog.";
					var repeat:int = 1;
					if (words.length > 1) {
						if (MathUtil.isNumeric(words[1])) {
							repeat = parseInt(words[1]);
						} else {
							growlTxt = txt.substr(7);
						}
					}
					if ((repeat > 1) && (words.length > 2)) {
						growlTxt = txt.substr(txt.indexOf(' ', 7));
					}
					for (i=1; i <= repeat; i++) {
						model.activityModel.growl_message = (((i > 1) ? '(' + i + ') ' : '') + growlTxt);
					}
					did_anything = true;
				} 
				else if (txt.indexOf('/cabinet') == 0) {
					
					CabinetManager.instance.start({
						itemstack_tsid:'BHH167VGN8C1PRO',
						cols: 3,
						rows: 6,
						itemstacks: {
							is002: {
								class_tsid: 'i001',
								label: 'Apple',
								count: 1
							},
							is003: {
								class_tsid: 'i005',
								label: 'Banana',
								count: 3
							}
						}
					});
					did_anything = true;
				} 
				else if (txt.indexOf('/trophy') == 0) {
					
					TrophyCaseManager.instance.start({
						itemstack_tsid:'BHH15J7BL4A10UU',
						display_rows:1,
						display_cols:5,
						display_itemstacks: ({}),
						private_tsid:'BHH15J7BL4A10UU',
						private_rows: 2,
						private_cols: 7,
						private_itemstacks: ({})
					});
					did_anything = true;
				}
				else if (txt.indexOf('/startdo') == 0) {
					ms = (words.length > 1) ? int(words[1]) : 0;
					TSFrontController.instance.playDoAnimation(ms);
					did_anything = true;
				}
				else if (txt == '/stopdo') {
					TSFrontController.instance.stopDoAnimation();
					did_anything = true;
				}
				else if (txt == '/rook') {
					
					var rooked_status:Object;
					if (model.rookModel.rooked_status.rooked) {
						rooked_status = {
							rooked: false
						}
					} else {
						//start of the attack
						model.rookModel.rook_incident_is_running = false;
						rooked_status = {
							rooked: true,
							phase: RookedStatus.PHASE_BUILD_UP,
								epicentre: true,
								angry_state: ''
						}
					}
					model.rookModel.rooked_status = RookedStatus.fromAnonymous(rooked_status, loc.tsid); // calls a trigger when set
					CONFIG::debugging {
						Console.dir(model.rookModel.rooked_status)
					}
					
					did_anything = true;
				}
				else if (txt == '/rookmsg') {
					model.activityModel.announcements = Announcement.parseMultiple(model.rookModel.preview_warning_anncsA);
					did_anything = true;
				}
				else if (txt.indexOf('/rooka ') == 0 || txt.indexOf('/rookattack ') == 0) {
					if (words.length > 1) {
						model.rookModel.rav_in_use_max = int(words[1]) || 1;
					}
					RookManager.instance.startAttackTEST();
					did_anything = true;
				}
				else if (txt.indexOf('/rookhead') == 0) {
					if (words.length > 1 && (words[1] in RookHeadAnimationState)) {
						RookManager.instance.animateRookHead(words[1]);
					} else {
						TSFrontController.instance.growl('you need to specify a valid state like "/rookhead STUNNED"');
					}
					did_anything = true;
				}
				else if (txt == '/rookfs') {
					RookManager.instance.startFlySideSeqTEST();
					did_anything = true;
				}
				else if (txt == '/rookff') {
					RookManager.instance.startFlyFowardTEST();
					did_anything = true;
				}
				else if (txt == '/rookbeat') {
					RookManager.instance.startWingBeatTEST();
					did_anything = true;
				}
				else if (txt.indexOf('/rookprogress ') == 0) {
					if (model.rookModel.rooked_status) {
						
						if (RookIncidentProgressView.instance.visible) {
							model.rookModel.rooked_status.strength = model.rookModel.max_strength*Number(words[1]);
							RookIncidentProgressView.instance.update();
						
						} else {
							model.rookModel.rooked_status.strength = model.rookModel.max_strength;
							model.rookModel.rook_incident_started_while_i_was_in_this_loc = true;
							RookIncidentProgressView.instance.start();
							
						}
					}
					
					did_anything = true;
				}
				else if (txt.indexOf('/rooktxt ') == 0) {
					if (words.length > 2) {
						RookIncidentProgressView.instance.setTopAndBottomText(words[1], words[2], '');
					}
					
					did_anything = true;
					
				}
				else if (txt.indexOf('/rookup ') == 0) {
					if(model.rookModel.rooked_status.rooked){
						model.rookModel.rooked_status.strength = model.rookModel.max_strength*Number(words[1])
						RookIncidentProgressView.instance.update();
						
					}
					
					did_anything = true;
				}
				else if (txt.indexOf('/rookdown ') == 0) {
					if(model.rookModel.rooked_status.rooked){
						
						model.rookModel.rooked_status.strength = model.rookModel.max_strength*Number(words[1]);
						model.rookModel.rooked_status.countdown = {
							top_txt: 'Hugs completed',
							bottom_txt: 'Damage',
							values: [10,30,60,100,200,500,10000]
						}
						RookIncidentProgressView.instance.update();
						
					}
						
					did_anything = true;
				}
				else if (txt.indexOf('/rook_angry') == 0) {
					//someone stunned the rook in build up phase
					model.rookModel.rooked_status = RookedStatus.fromAnonymous(
						{
							rooked: true,
							phase: RookedStatus.PHASE_ANGRY,
							epicentre: true,
							max_stun: 1000,
							angry_state: 'angry3',
							timer: 65
						}, 
						model.worldModel.location.tsid
					);
					
					did_anything = true;
				}
				else if (txt.indexOf('/rook_stunned') == 0) {
					//rook is stunned now and gets a strength progress bar
					model.rookModel.rooked_status = RookedStatus.fromAnonymous(
						{
							rooked: true,
							phase: RookedStatus.PHASE_STUNNED,
							epicentre: true,
							max_health: 1000,
							angry_state: '',
							timer: 30
						}, 
						model.worldModel.location.tsid
					);
					
					did_anything = true;
				}
				else if (txt.indexOf('/bad_convo') == 0) {
					TSFrontController.instance.simulateIncomingMsg({"uid":"1314140349", "type":"conversation","itemstack_tsid":"I-FAMILIAR"});
					did_anything = true;
				}
				else if (txt.indexOf('/rook_text ') == 0) {
					if (words.length > 1) {
						TSFrontController.instance.simulateIncomingMsg({
							type: 'rook_text',
							txt: words.slice(1).join(' ')
						});
					}
					did_anything = true;
				}
				else if (txt.indexOf('/rook_stun') == 0) {
					//check to make sure he's angry first
					if(model.rookModel.rooked_status.phase != RookedStatus.PHASE_ANGRY){
						model.rookModel.rooked_status = RookedStatus.fromAnonymous(
							{
								rooked: true,
								phase: RookedStatus.PHASE_ANGRY,
								epicentre: true,
								max_stun: 1000,
								angry_state: '',
								timer: 65
							}, 
							model.worldModel.location.tsid
						);
					}
					
					//increase the stun bar
					model.rookModel.rook_stun = RookStun.fromAnonymous(
						{
							successful: true,
							damage: words.length > 1 ? words[1] : 100,
							txt: 'Mumbly Joe and 4 others led an attack against the rook, stunning it for '+(words.length > 1 ? words[1] : 100)+' points.',
							stunned: words.length > 2 ? words[2] : false
						}
					);
					RookManager.instance.stun();
					
					did_anything = true;
				}
				else if (txt.indexOf('/rook_damage') == 0) {
					//decrease the strength
					model.rookModel.rook_damage = RookDamage.fromAnonymous(
						{
							damage: words.length > 1 ? words[1] : 100,
							txt: 'Mumbly Joe and 4 others led an attack against the rook, damaging it for '+(words.length > 1 ? words[1] : 100)+' points.',
							defeated: words.length > 2 ? words[2] : false
						}
					);
					
					RookManager.instance.damage();
					
					did_anything = true;
				}
				else if (txt.indexOf('/crowns_text_replay') == 0) {
					
					if (txt == 'crowns_text_replay_bad') {
						replayMessages(DebugMessages.getCrownTextReplayMessagesBAD(model));
					} else {
						replayMessages(DebugMessages.getCrownTextReplayMessages(model));
					}
					
					
					did_anything = true;
				}
				else if (txt.indexOf('/crowns_replay') == 0) {
					
					replayMessages(DebugMessages.getCrownReplayMessages(model));
					
					did_anything = true;
				}
				else if (txt.indexOf('/rook_test') == 0) {
					StageBeacon.setTimeout(TSFrontController.instance.simulateIncomingMsg, 1000, {
						"type":"location_rooked_status",
						"ts":"2011:7:29 16:48:39",
						"status":{
							"stun":0,
							"health":1000,
							"epicentre":true,
							"max_health":1000,
							"max_stun":1000,
							"rooked":true,
							"phase":"build_up"
						},
						"location_tsid":pc.location.tsid
					});
					
					StageBeacon.setTimeout(TSFrontController.instance.simulateIncomingMsg, 4000, {
						"type":"location_rooked_status",
						"ts":"2011:7:29 16:48:39",
						"status":{
							"stun":1000,
							"health":1000,
							"epicentre":true,
							"max_health":1000,
							"max_stun":1000,
							"rooked":true,
							"phase":"stunned"
						},
						"location_tsid":pc.location.tsid
					});
					StageBeacon.setTimeout(TSFrontController.instance.simulateIncomingMsg, 4000+1, {
						"type":"rook_stun",
						"successful":true,
						"ts":"2011:7:29 16:48:39",
						"txt":"ChrisW and 7 others led an attack against the Rook, stunning it for 1000 points.",
						"damage":1000,
						"stunned":true
					});
					StageBeacon.setTimeout(TSFrontController.instance.simulateIncomingMsg, 4000+10000, {
						"type":"location_rooked_status",
						"ts":"2011:7:29 16:49:15",
						"status":{
							"stun":1000,
							"health":500,
							"epicentre":true,
							"max_health":1000,
							"max_stun":1000,
							"rooked":true,
							"phase":"stunned"
						},
						"location_tsid":pc.location.tsid
					});
					StageBeacon.setTimeout(TSFrontController.instance.simulateIncomingMsg, 4000+10001, {
						"type":"rook_damage",
						"ts":"2011:7:29 16:49:15",
						"defeated":false,
						"txt":"Follow McTest attacked the Rook for 500 damage.",
						"damage":500
					});
					StageBeacon.setTimeout(TSFrontController.instance.simulateIncomingMsg, 4000+20000, {
						"type":"location_rooked_status",
						"ts":"2011:7:29 16:49:31",
						"status":{
							"stun":1000,
							"health":0,
							"epicentre":true,
							"max_health":1000,
							"max_stun":1000,
							"rooked":true,
							"phase":"stunned"
						},
						"location_tsid":pc.location.tsid
					});
					StageBeacon.setTimeout(TSFrontController.instance.simulateIncomingMsg, 4000+20000+1, {
						"type":"rook_damage",
						"ts":"2011:7:29 16:49:31",
						"defeated":true,
						"txt":"Follow McTest attacked the Rook for 500 damage.",
						"damage":500
					});
					StageBeacon.setTimeout(TSFrontController.instance.simulateIncomingMsg, 4000+33000, {
						"type":"location_rooked_status",
						"ts":"2011:7:29 16:49:42",
						"status":{
							"rooked":false
						},
						"location_tsid":pc.location.tsid
					});
				
					
					did_anything = true;
				}
				else if (txt.indexOf('/shrine_power_up') == 0) {
					
					var shrine:Itemstack;
					
					if (words.length > 1) {
						shrine = model.worldModel.itemstacks[words[1]];// you will of course have to change this to a shrine in your location to test it
					}
					
					if (shrine) {
						
						
						TSFrontController.instance.simulateIncomingMsg({
							type: 'move_avatar',
							x: shrine.x-115, // this should the y coord of the shrine
							y: shrine.y, // this should the y coord of the shrine-115 (more or less)
							face: 'right',
							announcements: [{
								type: 'location_overlay',
								swf_url:'http://c2.glitch.bz/overlays%2F2011-07-21%2F1311270765_9996.swf',
								state: 'charge',
								uid: 'shrine_power_up',
								y: shrine.y,
								x: shrine.x-40,
								under_decos:true,
								locking:true,
								delay_ms:1000
							}]
						});

						StageBeacon.setTimeout(
							TSFrontController.instance.simulateIncomingMsg, 4000, {
								type: 'overlay_state',
								uid: 'shrine_power_up',
								state: 'end'
							}
						)
						StageBeacon.setTimeout(
							TSFrontController.instance.simulateIncomingMsg, 6000, {
								type: 'overlay_cancel',
								uid: 'shrine_power_up'
							}
						)
					}
					did_anything = true;
				}
				else if (txt.indexOf('/rook_laser') == 0) {
					//show the orb
					model.activityModel.announcements = 
						Announcement.parseMultiple(
							[{
								type: 'pc_overlay',
								swf_url:'http://c2.glitch.bz/overlays%2F2011-07-22%2F1311348799_7372.swf',
								uid: 'ghfghjfg',
								pc_tsid: pc.tsid,
								dont_keep_in_bounds: true,
								duration: 13000
							}]
						);
					
					did_anything = true;
				}
				else if (txt.indexOf('/rook_orb') == 0) {
					//show the orb
					model.activityModel.announcements = 
						Announcement.parseMultiple(
						[{
							type: 'pc_overlay',
							swf_url:'http://c2.glitch.bz/overlays%2F2011-07-26%2F1311711260_1617.swf',
							state: words.length > 1 ? words[1] : 'orb1',
							uid: 'aksjdhfladjsh',
							pc_tsid: pc.tsid,
							delta_y: -113,
							duration: 15000, //this is just here so that it finishes at some point
							mouse: {
								is_clickable: true,
								click_payload: { test:'dummy' },
								dismiss_on_click: false,
								txt: "Holy fuck! The Rook is about to get stunned!",
								txt_delta_y: -200
							}
						},{
							"delta_y":-125,
							"uid":"orb_count_P001",
							pc_tsid: pc.tsid,
							"type":"pc_overlay",
							"text":["<p align=\"right\"><span class=\"overlay_counter\">0</span></p>"],
							"duration":15000
						},{
							"swf_url":"http://c2.glitch.bz/overlays/2011-07-25/1311630945_9794.swf",
							pc_tsid: pc.tsid,
							"at_bottom":true,
							"type":"pc_overlay",
							"uid":"orb_contribute_P001",
							"duration":15000
						}]
					);
					
					did_anything = true;
				}
				else if (txt.indexOf('/decorate') == 0) {
					if (model.stateModel.decorator_mode) {
						TSFrontController.instance.stopDecoratorMode();
					} else {
						TSFrontController.instance.startDecoratorMode();
						/*
						if (words.length > 1 && words[1] == 'fakeplats') {
							// let's add some fake platforms to the location for tables!
							for (tsid in loc.itemstack_tsid_list) {
								item = model.worldModel.getItemByItemstackId(tsid);
								if (item.tsid == 'furniture_table') {
									itemstack = model.worldModel.getItemstackByTsid(tsid);
									
									var plV:Vector.<PlatformLine> = model.worldModel.location.mg.getPlatformLinesBySource(tsid);
									if (!plV) {
										var platform_lines:Object = {};
										platform_lines['blah1'] = {
											platform_pc_perm: -1,
											platform_item_perm: -1,
											source: tsid,
											start: {x:itemstack.x-100, y:itemstack.y},
											end: {x:itemstack.x, y:itemstack.y-2}
										}
										platform_lines['blah2'] = {
											platform_pc_perm: -1,
											platform_item_perm: -1,
											source: tsid,
											start: {x:itemstack.x, y:itemstack.y-2},
											end: {x:itemstack.x+100, y:itemstack.y}
										}
										TSFrontController.instance.addGeo({
											platform_lines: platform_lines
										});
									}
									
								}
							}
						}
						*/
					}
					
					did_anything = true;
				}
				else if (txt.indexOf('/trade') == 0) {	
					//fake a trade request
					const label:String = '5 Apples';
					const value:String = 'apple#5';
					var str:String = 'wants to buy <b>'+label+'</b>.';
					str += '&nbsp;&nbsp;&nbsp;<a href="event:'+TSLinkedTextField.LINK_TRADE+'|'+value+'">Accept!</a>';
					const client_link:String = RightSideManager.instance.createClientLink(str, label, TSLinkedTextField.LINK_ITEM+'|apple|'+label);
					
					TSFrontController.instance.genericSend(new NetOutgoingActionRequestBroadcastVO(model.worldModel.pc.tsid, TSLinkedTextField.LINK_TRADE, value, client_link));
					did_anything = true;
				}
				else if (txt.indexOf('/diss') == 0) {
					model.activityModel.announcements = Announcement.parseMultiple([
						{
							type: "pc_overlay",
							item_class: "apple",
							duration: 30000,
							state: "-4",
							dismissible: true,
							dismiss_payload: {
								test:1234
							},
							bubble:false,
							locking: false,
							pc_tsid: pc.tsid, // the itemstack to target
							delta_x: 0, //delta_x/y indicates position of overlay swf center relative to the bottom center of the itemstack
							delta_y: -114
							
						}
					]);
					did_anything = true;
				} 
				else if (txt.indexOf('/newxp') == 0){
					TSFrontController.instance.sendLocalChat(new NetOutgoingLocalChatVO(txt));
					did_anything = true;
				} 
				else if (txt.indexOf('/item ') == 0) {
					if (words.length > 1) {
						item_class = words[1];
						var x:int = (words.length > 2) ? words[2] : pc.x;
						var y:int = (words.length > 3) ? words[3] : pc.y;
						
						TSFrontController.instance.genericSend(new NetOutgoingItemstackCreateVO(item_class, x, y));
					}
					did_anything = true;
				}
				else if (txt.indexOf('/sleep ') == 0) {
					model.flashVarModel.sleep_ms = int(words[1]);
					model.activityModel.growl_message = 'sleep_ms set to ' + model.flashVarModel.sleep_ms;
					did_anything = true;
				}
				else if (txt.indexOf('/tween_camera') == 0) {
					if (words.length>1) {
						model.flashVarModel.tween_camera = true;
						model.flashVarModel.tween_camera_time = parseFloat(words[1]) || 0;
					} else {
						model.flashVarModel.tween_camera = !model.flashVarModel.tween_camera;
					}
					model.activityModel.growl_message = 'tween_camera:' + model.flashVarModel.tween_camera+' tween_camera_time:' + model.flashVarModel.tween_camera_time;
					did_anything = true;
				}
				else if (txt.indexOf('/ava_anim_time') == 0) {
					if (words.length>1) {
						model.flashVarModel.ava_anim_time = parseFloat(words[1]) || 0;
					}
					model.activityModel.growl_message = 'ava_anim_time:' + model.flashVarModel.ava_anim_time;
					did_anything = true;
				}
				else if (txt.indexOf('/canceloverlays') == 0) {
					AnnouncementController.instance.cancelAllOverlaysWeCan();
					did_anything = true;
				}
				else if (txt.indexOf('/ev ') == 0) {
					// ev TS
					// do "/ev com.tinyspeck.engine.model.TSModelLocator instance worldModel location tsid"
					
					var segments:Array = words.concat();
					/*if (segments[0].indexOf('.') != -1) {
						segments = segments[0].split('.');
					}*/
					var ref:Object;
					
					try {
						ref = getDefinitionByName(segments[1]) as Object;
					} catch(err:Error) {};
					
					var failed:Boolean;
					if (!ref) {
						activityTextHandler(segments[1]+' is not a class');
					} else {
						for (var r:int=2;r<segments.length;r++) {
							if (!StringUtil.trim(segments[r])) break; 
							activityTextHandler(r+' looking for '+segments[r]);
							if (segments[r] in ref) {
								ref = ref[segments[r]];
							} else {
								failed = true;
								activityTextHandler(segments[r]+' is not a member of '+segments[r-1]);
								break;
							}
						}
						
						if (!failed) {
							activityTextHandler('result: '+String(ref));
						}
						
					}

					did_anything = true;
				}
				else if (txt.indexOf('/path') == 0) {
					if (pc.path) {
						var path_txt:String = StringUtil.getJsonStr(pc.path);
						System.setClipboard(path_txt);
						activityTextHandler(path_txt);
						activityTextHandler('The path has been placed in your clipboard');
					}
					did_anything = true;
				}
				else if (txt.indexOf('/job') == 0) {
					JobManager.instance.status({
						job_id: 'job_myles_test',
						spirit_id: 'IHH179TOLRF1K75',
						title: '* Job Title',
						desc: '* Job Description',
						info: {
							accepted: true,
							complete: false,
							desc: 'Job Description',
							failed: false,
							finished: false,
							offered_time: 1283880459,
							perc: .687,
							reqs: {
								r1: {
									completed: false,
									desc: 'Collect 500 Planks',
									got_num: 0,
									is_count: true,
									item_class: 'plank',
									need_num: 500
								},
								r2: {
									completed: false,
									desc: 'Collect 100 Cheeries',
									got_num: 10,
									is_count: true,
									item_class: 'cherry',
									need_num: 100
								},
								r3: {
									completed: false,
									desc: 'Collect 300 Oranges',
									got_num: 30,
									is_count: true,
									item_class: 'orange',
									need_num: 300
								},
								r4: {
									completed: true,
									desc: 'Collect 250 Apples',
									got_num: 250,
									is_count: true,
									item_class: 'apple',
									need_num: 250
								},
								r5: {
									completed: false,
									desc: 'Collect 50 Blenders',
									got_num: 0,
									is_count: true,
									item_class: 'blender',
									need_num: 50
								},
								r6: {
									completed: false,
									desc: 'Collect 50,000 Currants',
									got_num: 0,
									is_count: true,
									item_class: 'money_bag',
									need_num: 50000
								},
								r7: {
									completed: false,
									desc: 'Complete 10 units with Pick',
									got_num: 0,
									is_count: true,
									is_work: true,
									item_class: 'pick',
									need_num: 10
								},
								r8: {
									completed: false,
									desc: 'Collect 20 Tomatoes',
									got_num: 0,
									is_count: true,
									is_work: false,
									item_class: 'tomato',
									need_num: 100
								}
							},
							rewards: {
								currants: 1000,
								energy: 100,	
								favor: {
									0: {
										giant: 'all', //use 'all' if the points go to all giants
										points: 100
									}
								},
								mood: 100,
								xp: 50
							},
							performance_rewards: {
								currants: 1000,
								energy: 100
							},
							performance_cutoff: 5,
							performance_percent: 0,
							/*
							options: {
								0: {
									name: 'Option A',
									perc: .75, //how many votes has this option received for the current job (to 3 decimal places)
									desc: 'Make this street a flowery wonderland of great beauty. All will be astonished by what '+
										  'you’ve created. The giants most of all. I bet we can even squeeze in four lines of text.'
								},
								1: {
									name: 'Option B',
									perc: .25, //how many votes has this option received for the current job (to 3 decimal places)
									desc: 'I describe this option and what it gives me!'
								}
							},
							*/
							startable: false,
							started: true,
							title: 'Effin\' Amazing Rad Job'
						}
					});
					did_anything = true;
				}
				else if (txt.indexOf('/camera_center') == 0) {
					tsid = (words.length == 1) ? '' : words[1];
					
					ob = {
						type: MessageTypes.CAMERA_CENTER,
						pc_tsid: (tsid.indexOf('P') == 0) ? tsid : '',
						itemstack_tsid: (tsid.indexOf('I') == 0) ? tsid : '',
						duration_ms: (words.length == 3) ? int(words[2]) : 0,
						px_sec:MathUtil.randomInt(2000, 2000),
						force: true
					}
					if (!ob.pc_tsid && !ob.itemstack_tsid) {
						if (tsid == 'tl') {
							ob.pt = {x:loc.l, y:loc.t};
						} else if (tsid == 'random') {
							ob.pt = {x:MathUtil.randomInt(loc.l, loc.r), y:MathUtil.randomInt(loc.t, loc.b)};
						} else {
							ob.pt = {x:pc.x, y:pc.y};
						}
					}
					
					TSFrontController.instance.simulateIncomingMsg(ob);
					did_anything = true;
				}
				else if (txt.indexOf('/camera_recenter') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.CAMERA_CENTER,
						px_sec:900
					});
					did_anything = true;
				}
				else if (txt.indexOf('/track_px_sec') == 0) {
					if (track_int) {
						StageBeacon.clearInterval(track_int);
						track_int = 0;
						track_pt = null;
					} else {
						track_int = StageBeacon.setInterval(function():void {
							var pt:Point = new Point(pc.x, pc.y);
							CONFIG::debugging {
								if (track_pt) {
									Console.info('dist last sec '+Point.distance(track_pt, pt));
								}
							}
							track_pt = pt;
						}, 1000);
					}
				}
				else if (txt.indexOf('/phys ') == 0) {
					if (words.length == 2) {
						try {
							CONFIG::debugging {
								Console.warn(words[1]);
							}
							var adjustments:Object = com.adobe.serialization.json.JSON.decode(words[1]);
							model.physicsModel.pc_adjustments = adjustments; // calls a trigger when set
						} catch (err:Error) {
							model.physicsModel.pc_adjustments = null;
							CONFIG::debugging {
								Console.warn('could not decode '+words[1]+' as JSON');
							}
						}
					}
					did_anything = true;
				}
				else if (txt.indexOf('/vignette') == 0) {
					var masked_container:Sprite = TSFrontController.instance.getMainView().masked_container;
					if(!masked_container.getChildByName('vignette')){
						var colors:Array = [0x333333, 0x333333, 0x000000];
						var alphas:Array = [0, .1, .7];
						var matrix:Matrix = new Matrix();
						matrix.createGradientBox(
							model.layoutModel.loc_vp_w, 
							model.layoutModel.loc_vp_w, 
							Math.PI/2, 
							0, 
							(model.layoutModel.loc_vp_h - model.layoutModel.loc_vp_w)/2
						);
						
						var vig:Sprite = new Sprite();
						vig.name = 'vignette';
						var g:Graphics = vig.graphics;
						g.beginGradientFill(GradientType.RADIAL, colors, alphas, [185, 200, 255], matrix);
						g.drawRect(0, 0, model.layoutModel.loc_vp_w, model.layoutModel.loc_vp_w);
						
						TSFrontController.instance.getMainView().masked_container.addChild(vig);
					}
					else {
						masked_container.removeChild(masked_container.getChildByName('vignette'));
					}

					did_anything = true;
				}
				else if (txt.indexOf('/so_test') == 0) {
					LocalStorage.instance.flushIt(10000*1024*1024, 'penis');
					did_anything = true;
				}
				else if (txt.indexOf('/lantern') == 0) {					
					if(!Lantern.instance.parent){
						Lantern.instance.show(true, words.length > 1 ? words[1] : Lantern.DEFAULT_RADIUS);
					}
					else {
						Lantern.instance.hide();
					}
					
					did_anything = true;
				}
				else if (txt.indexOf('/mouse_lantern') == 0) {
					if(!Lantern.instance.parent){
						Lantern.instance.show(false, words.length > 1 ? words[1] : Lantern.DEFAULT_RADIUS);
					}
					else {
						Lantern.instance.hide();
					}
					
					did_anything = true;
				}
				else if (txt.indexOf('/perf_teleport ') == 0) {
					TSFrontController.instance.genericSend(new NetOutgoingPerfTeleportVO(words[1]));
					did_anything = true;
				}
				else if (txt.indexOf('/itemdef ') == 0) {
					CONFIG::debugging {
						item = model.worldModel.getItemByTsid(words[1]);
						if (item) {
							Console.dir(item.amf);
						} else {
							Console.warn(words[1]+'?????');
						}
					}
					
					did_anything = true;
				}
				else if (txt.indexOf('/sts') == 0) {
					
					for (k in model.worldModel.itemstacks) {
						item = model.worldModel.getItemByItemstackId(k);
						if (item.tsid == 'street_spirit_groddle') {
							var lis_view:LocationItemstackView = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(k);
							if (lis_view) {
								Itemstack.updateFromAnonymous({s:{loop:true, sequence:['open', 'close']}}, model.worldModel.getItemstackByTsid(k));
								lis_view.changeHandler();
							}
						}
					}

					did_anything = true;
				}
				else if (txt.indexOf('/color_group') == 0){
					if (words.length > 1) {
						TSFrontController.instance.simulateIncomingMsg({
							type: 'pc_game_flag_change',
							pc: {
								show_color_dot:true,
								color_group: words[1],
								text: (words.length > 2) ? words[2] : '',
								tsid: pc.tsid,
								location: {
									tsid: pc.location.tsid
								}
							}
						});
					} else {
						TSFrontController.instance.simulateIncomingMsg({
							type: 'pc_game_flag_change',
							pc: {
								show_color_dot:false,
								color_group: '',
								tsid: pc.tsid,
								text: '',
								location: {
									tsid: pc.location.tsid
								}
							}
						});
					}
					
					did_anything = true;
				}
				else if (txt == '/quest'){
					if(JobDialog.instance.spirit_id){
						var qb:JobActionIndicatorView = new JobActionIndicatorView(JobDialog.instance.spirit_id);
						qb.msg = 'New job';
					}
					did_anything = true;
				}
				else if (txt.indexOf('/ai ') == 0){
					if(words.length > 1){
						lis_view = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(words[1]);
						if (lis_view) {
							var aiv:ActionIndicatorView = lis_view.getActionIndicator();
							aiv.percent = (words.length > 2) ? parseFloat(words[2]) || 0 : 0;
							aiv.msg = (words.length > 3) ? words[3] : '';
							aiv.alt_msg = (words.length > 4) ? words[4] : '';
						}
					}
					did_anything = true;
				}
				else if (txt.indexOf('/client_new_day') == 0){
					TSFrontController.instance.addToScreenViewQ(new ScreenViewQueueVO(
						NewDayView.instance.show,
						{
							stats_yesterday: {
								xp: 3000,
								energy: 1234,
								imagination: 2400
							},
							stats_today: {
								xp: 300,
								mood: 40,
								energy: 390
							},
							new_level: 5,
							complete_quests: {
								0: {
									name: 'Giv\'r till you Shiver',
									tsid: 'mining_mine_in_time_period'
								},
								1: {
									name: 'Beam You Up',
									tsid: 'teleportation_teleport_between_zones'
								}
							},
							complete_collections: {
								0: {
									name: 'Music Block XS',
									tsid: 'trophy_music_x_shiny'
								},
								1: {
									name: 'Fruit Trophy',
									tsid: 'trophy_fruit'
								}
							},
							new_skills: {
								0: {
									name: 'Teleportation',
									tsid: 'teleportation_1'
								},
								1: {
									name: 'Better Learning IV',
									tsid: 'betterlearning_4'
								}
							},
							new_badges: {
								0: {
									name: 'Blendmaster',
									tsid: 'blendmaster'
								},
								1: {
									name: 'First Emblem of Alph',
									tsid: 'first_alph_emblem',
									icon_urls: {
										180: "http://c2.glitch.bz/achievements/2011-04-26/first_alph_emblem_1303852122_180.png",
										60: "http://c2.glitch.bz/achievements/2011-04-26/first_alph_emblem_1303852122_60.png",
										swf: "http://c2.glitch.bz/achievements/2011-04-26/first_alph_emblem_1303852122.swf"
									}
								}
							}
						},
						true
					));
					
					did_anything = true;
				}
				else if (txt.indexOf('/ui_call ') == 0){
					if(words.length > 1){
						if(words[1] == 'cancel'){
							UICalloutView.instance.hide();
						}
						else {
							/*
							TSFrontController.instance.addToScreenViewQ(new ScreenViewQueueVO(
								UICalloutView.instance.show,
								{
									section: words[1],
									swf_url: 'http://c2.glitch.bz/overlays/2010-07-27/1280244336_4267.swf',
									display_time: 5000
								})
							);
							*/
							UICalloutView.instance.show(
								{
									section: words[1],
									slot_id: words.length > 2 ? words[2] : 0,
									//swf_url: 'http://c2.glitch.bz/overlays/2010-07-27/1280244336_4267.swf',
									display_time: 0
								});
						}
					}
					did_anything = true;
				}
				else if (txt.indexOf('/loc_screen') == 0){
					var load_obj:Object = {
						to_tsid: 'LH823848203',
						first_visit: false,
						xp: 20,
						last_visit_mins: 15,
						visit_count: 14,
						street_name: 'Random Tree Place',
						hub_name: 'Groddle Forest',
						loading_img: {
							url: model.flashVarModel.root_url+'img/TEST-sample-groddle-loading-street.jpg',
							w: 840,
							h: 160
						},
						street_details: {
							active_project: true,
							features: { 
								0: 'A street spirit named <b>Johnny McSwifty</b> selling <b>Cooking Goods</b>.',
								1: 'A shrine dedicated to <b>Lem</b>.',
								2: 'Plus <b>3 Piggies</b>, <b>2 Butterflies</b>, <b>2 Cherry Trees</b>, <b>2 Patches</b>, a <b>Bubble Tree</b>, and <b>24 Houses (2 for sale)</b>'
							}
						},
						upgrade_details: { 
							upgrade_since_last_visit: false, 
							mins: 15,
							leaderboard	: {
								0	: {
									position		: 1,
									pc	        	: { 
														label: pc.label, 
														tsid: pc.tsid
													  },
									contributions	: 100
								},
								me    : {
									position		: 12,
									contributions	: 0.5
								}
							}
						}
					}
					if(!model.moveModel.loading_info || words.length > 1){
						model.moveModel.loading_info = LoadingInfo.fromAnonymous(load_obj, 'TEST');
					}
					if(!LoadingLocationView.instance.visible){
						LoadingLocationView.instance.fadeIn();
					}
					else{
						LoadingLocationView.instance.fadeOut();
					}
					
					TSFrontController.instance.updateLoadingLocationProgress(.8);
					
					did_anything = true;
				}
				else if (txt.indexOf('/street_upgrade') == 0){
					TSFrontController.instance.addToScreenViewQ(
						new ScreenViewQueueVO(StreetUpgradeView.instance.show,
							{},
							true
						)
					);
					
					did_anything = true;
				}
				else if (txt.indexOf('/note') == 0){
					NoteManager.instance.start(
						{
							title: "Scott's test note",
							body: "Hey look at me I'm the content of this note! And\n\n some more more\n text blah\n\n\n blah sfg\n\n sdfg sdf fdg  sdfggdsfsdfjlhk\n\n\n\n jhklsdfg jhsdfg\n\n ljksdfg hsdlfkjgh sdlfkjg hjklsdf gkhjsdf hjk",
							disabled_reason: "",
							start_in_edit_mode: false,
							itemstack_tsid: "I2384923234"
						}
					);
					
					did_anything = true;
				}
				else if (txt.indexOf('/date_time') == 0){
					DateTimeDialog.instance.start();
					
					did_anything = true;
				}
				else if (txt.indexOf('/bubble_with_slugs') == 0){
					model.activityModel.announcements = Announcement.parseMultiple([{
						type: "pc_overlay",
						duration: 2000,
						delay_ms: 0,
						locking: true,
						width: 100,
						height: 100,
						bubble_talk: true,
						pc_tsid: model.worldModel.pc.tsid,
						delta_x: 0,
						rewards: {
							energy: -10
						},
						delta_y: -114,
							text: [
								'<span class="simple_panel">Ow. Crushers suck!</span>'
							]
					}]);
					did_anything = true;
				}
				else if (txt.indexOf('/request_scott') == 0){
					RightSideManager.instance.actionRequest(ActionRequest.fromAnonymous({
						"need":2,
						"txt":'is looking for a challenger for <b>Game of Crowns</b>.',
						"got":0,
						"uid":'PM416KGKTEL94_game_accept_it_game',
						"pc":{
							"tsid":'PM416KGKTEL94',
							"label":'Myles?',
							"is_guide":false,
							"is_admin":true
						},
						"timeout_secs":0,
						"event_type":'game_accept',
						"event_tsid":'it_game'
					}));
					
					/*
					RightSideManager.instance.chatUpdate(
						ChatArea.NAME_LOCAL, 
						'PHH10B0VNN51QCD',
						'is betting 6 <a href="event:item|sammich">Sammaches</a> that they can win in a race! <a href="event:quest_accept|tsid">Accept the challenge?</a>', 
						ChatElement.TYPE_REQUEST
					);
					*/
					
					did_anything = true;
				}
				else if (txt.indexOf('/request') == 0){
					TSFrontController.instance.genericSend(
						new NetOutgoingActionRequestBroadcastVO(
							model.worldModel.pc.tsid, 
							'trade', 
							model.worldModel.pc.tsid, 
							'I need some shit!'
						)
					);
					
					did_anything = true;
				}
				else if (txt.indexOf('/chat_remote_stress') == 0){					
					if(chat_stress_id){
						StageBeacon.clearInterval(chat_stress_id);
						chat_stress_id = 0;
					}
					else {
						chat_stress_id = StageBeacon.setInterval(
							function():void {
								RightSideManager.instance.sendToServer(ChatArea.NAME_LOCAL, 'BLASTING REMOTE LOCAL');
								RightSideManager.instance.sendToServer(ChatArea.NAME_GLOBAL, 'BLASTING REMOTE GLOBAL');
							},
						500);
					}
					
					did_anything = true;
				}
				else if (txt.indexOf('/chat_local_stress') == 0){					
					if(chat_stress_id){
						StageBeacon.clearInterval(chat_stress_id);
						chat_stress_id = 0;
					}
					else {
						chat_stress_id = StageBeacon.setInterval(
							function():void {
								RightSideManager.instance.chatUpdate(ChatArea.NAME_LOCAL, model.worldModel.pc.tsid, 'BLASTING LOCAL LOCAL');
								RightSideManager.instance.chatUpdate(ChatArea.NAME_GLOBAL, model.worldModel.pc.tsid, 'BLASTING LOCAL GLOBAL');
							},
						10);
					}
					
					did_anything = true;
				}
				else if (txt.indexOf('/garden_update ') == 0){					
					GardenManager.instance.sendAction(words[1], words[2], words[3], (words.length > 4 ? words[4] : ''));
					
					did_anything = true;
				}
				else if (txt.indexOf('/chats_with') == 0){
					CONFIG::debugging {
						Console.warn(RightSideManager.instance.getContentsOfAllChatsThatReferenceStr(words.length > 1 ? words[1] : 'asdsad'));
					}
					did_anything = true;
				}
				else if (txt.indexOf('/copy') == 0){					
					RightSideManager.instance.chatCopy(chat_name);
					
					did_anything = true;
				}
				else if (txt.indexOf('/greeter') == 0){		
					
					var kind:String = 'coming';
					
					if (words.length > 1) {
						if (words[1] == 'arrived') kind = words[1];
						if (words[1] == 'present') kind = words[1];
					}
					
					
					if (kind == 'coming') {
						payload = {
							"conversation":{
								"title": "<span class=\"choices_quest_title\">Welcome!</span>",
								"itemstack_tsid": model.worldModel.pc.familiar.tsid,
								"conv_type": "greeter_coming",
								"txt":"Hi "+model.worldModel.pc.label+". There are helpful players in Glitch called \"greeters\" who can help you get familiar with your surroundings. <split butt_txt=\"Yeah?\" /> Our greeters have been notified of your arrival, and should be arriving shortly to help you. Feel free to ask questions, or just say hello.",
								"choices":{
									"1":{
										"value":false,
										"txt":"Ok, thanks"
									}
								}
							}
						}
					} else if (kind == 'arrived') {
						payload = {
							"conversation":{
								"title": "<span class=\"choices_quest_title\">You greeter has arrived!</span>",
								"itemstack_tsid": model.worldModel.pc.familiar.tsid,
									"greeter_ava_url": "http://c2.glitch.bz/avatars/2011-03-24/089b6908c18aa5221b140d33557c4d4e_1301008724",
									"conv_type": "greeter_arrived",
									"txt":"A greeter has arrived to welcome you, and lend a hand if you need it. Here's what your greeter looks like.",
									"choices":{
										"1":{
											"value":false,
											"txt":"Ok, thanks"
										}
									}
							}
						}
						
					} else if (kind == 'present') {
						payload = {
							"conversation":{
								"title": "<span class=\"choices_quest_title\">Welcome!</span>",
								"itemstack_tsid": model.worldModel.pc.familiar.tsid,
									"greeter_ava_url": "http://c2.glitch.bz/avatars/2011-03-24/089b6908c18aa5221b140d33557c4d4e_1301008724",
									"conv_type": "greeter_present",
									"txt":"Hi "+model.worldModel.pc.label+". There's a greeter here to welcome you and help you get familiar with your surroundings. <split butt_txt=\"Yeah?\" /> This is what your greeter looks like.  Feel free to ask questions, or just say hello.",
									"choices":{
										"1":{
											"value":false,
											"txt":"Ok, thanks"
										}
									}
							}
						}
						
					}
					
					if (payload) ConversationManager.instance.start(payload.conversation);
					
					did_anything = true;
				}
				else if (txt.indexOf('/god_msg') == 0){					
					RightSideManager.instance.chatUpdate(ChatArea.NAME_LOCAL, WorldModel.GOD, 'I am a god message. You should listen to me!');
					
					did_anything = true;
				}
				else if (txt.indexOf('/active_contacts') == 0){					
					//this only works when the buddies are active in WorldModel getBuddiesTsids()
					for(i = 0; i < 10; i++){
						RightSideManager.instance.chatStart('P'+i, true);
					}
					
					did_anything = true;
				}
				else if (txt.indexOf('/crab_reward') == 0){
					payload = {
						itemstack_tsid: "IHH102546A32LVG",
						txt: "I farted, have some rewards, and a bunch of other shit that wraps the line.",
						choices: {
							1: {
								txt: "I'll do it!",
								value: "yes"
							},
							2: {
								txt: "No!",
								value: "no"
							},
							3: {
								txt: "Maybe?",
								value: "maybe"
							},
							4: {
								txt: "This is fan-fucking-tastic!",
								value: "good"
							},
							5: {
								txt: "I know!",
								value: "poop"
							}
						},
						rewards: {
							//currants: 1000,
							//energy: 100,	
							favor: {
								0: {
									giant: 'all', //use 'all' if the points go to all giants
									points: 100
								}
							},
							items: {
								0: {
									class_tsid: 'apple',
									label: 'Apple',
									count: 1
								}
							},
							//mood: 100,
							xp: 50
						}	
					}
					//choices dialog thinks I'm hitting enter on the choice, so a delay	
					StageBeacon.setTimeout(ConversationManager.instance.start, 500, payload);
					StageBeacon.setTimeout(function():void {
						var lis_view:LocationItemstackView = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(payload.itemstack_tsid);
						if (lis_view) TSFrontController.instance.startMovingAvatarOnGSPath(new Point(lis_view.x, lis_view.y), 'right');
					}, 501);
					did_anything = true;
				}
				else if (txt.indexOf('/sound ') == 0){					
					//play a sound from the sound library "/sound music|fx SOUND_NAME (LOOP_COUNT)"
					//list: http://dev.glitch.com/god/sounds.php
					if (words.length > 2) {
						SoundMaster.instance.testSound(words[2], words[1] == 'music', words.length > 3 ? words[3] : 0);
						
						did_anything = true;
					}
				}
				else if (txt.indexOf('/buff_test') == 0){
					buff = model.worldModel.pc.buffs['hog_tie'] = PCBuff.fromAnonymous({
						"is_debuff":false,
						"ticks":1,
						"name":"Hog-Tied Escape Alert",
						"duration":0,
						"item_class":"hogtied_piggy",
						"is_timer":true,
						"tsid":"hog_tie",
						"desc":"Place that piggy soon or it'll escape"
					}, "hog_tie");
					model.worldModel.buff_adds = ['hog_tie'];
					
					did_anything = true;
				}
				else if (txt.indexOf('/buzzed') == 0){
					buff = model.worldModel.pc.buffs['buff_fake_buzzed'] = PCBuff.fromAnonymous({
						"is_debuff":false,
						"ticks":1,
						"name":"Pretending to be buzzed",
						"duration":40,
						"item_class":"beer",
						"is_timer":true,
						"tsid":"buff_fake_buzzed",
						"desc":"Not actually buzzed, but you look really convincing"
					}, "buff_fake_buzzed");
					model.worldModel.buff_adds = ['buff_fake_buzzed'];
					StageBeacon.setTimeout(function():void {
						model.worldModel.buff_dels = ['buff_fake_buzzed'];
					}, 40000);
					did_anything = true;
				}
				else if (txt.indexOf('/xray') == 0){
					buff = model.worldModel.pc.buffs['buff_xray'] = PCBuff.fromAnonymous({
						"is_debuff":false,
						"ticks":1,
						"name":"X-ray Vision",
						"duration":10,
						"is_timer":true,
						"tsid":"buff_xray",
						"desc":"You're able to see more than meets the eye"
					}, "buff_xray");
					
					AvatarSSManager.use_default_ava = true;
					var pc_view:PCView;
					for each (var otherPC:PC in model.worldModel.pcs) {
						if (otherPC != pc) {
							pc_view = TSFrontController.instance.getMainView().gameRenderer.getPcViewByTsid(otherPC.tsid);
							if (pc_view) pc_view.reloadSSWithNewSheet();
						}
					}
					
					model.worldModel.buff_adds = ['buff_xray'];
					StageBeacon.setTimeout(function():void {
						model.worldModel.buff_dels = ['buff_xray'];
						AvatarSSManager.use_default_ava = false;
						var pc_view:PCView;
						for each (otherPC in model.worldModel.pcs) {
							if (otherPC != pc) {
								pc_view = TSFrontController.instance.getMainView().gameRenderer.getPcViewByTsid(otherPC.tsid);
								if (pc_view) pc_view.reloadSSWithNewSheet();
							}
						}
					}, 10000);
					did_anything = true;
				}
				else if (txt.indexOf('/urquake') == 0){
					model.stateModel.urquake = true;
					StageBeacon.setTimeout(function():void {
						model.stateModel.urquake = false;
					}, MathUtil.randomInt(1000, 4000));
					did_anything = true;
				}
				else if (txt.indexOf('/chat_filler') == 0){
					var filler:String = "Writing rubbish on the internet amuses me a lot. There is often a limit of 1000 characters per post so every story " +
						"(including punctuation, spaces, introduction, proposal, argument and punch line) has to be within a small paragraph." +
						"Sometimes I just write nonsense and other times I write something rather insensitive to evoke angry responses." +
						"When I was just fourteen, I was given the task of drowning kittens by my girlfriend's mother. I filled a large laundry sink " +
						"with room temperature water and held the eight kittens under. As each kitten died and sank to the bottom, it turned and rested " +
						"'snuggled' to the previous. I put them in a garbage bag and was carrying it out when the bag moved and I heard a meow. I opened " +
						"the bag and found one kitten had survived. So I drowned it again. And that is an exact one thousand.";
					
					var timer:Timer = new Timer(10, ChatArea.MAX_ELEMENTS);
					timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
					timer.start();
					
					function onTimerTick(event:TimerEvent):void {
						RightSideManager.instance.chatUpdate(ChatArea.NAME_LOCAL, model.worldModel.pc.tsid, timer.currentCount +'###'+filler);
						RightSideManager.instance.chatUpdate(ChatArea.NAME_GLOBAL, model.worldModel.pc.tsid, timer.currentCount +'###'+filler);
						RightSideManager.instance.chatUpdate(ChatArea.NAME_HELP, model.worldModel.pc.tsid, timer.currentCount +'###'+filler);
					}
					
					did_anything = true;
				}
				else if (txt.indexOf('/mail_test') == 0){
					var convo:Object = {	
						txt:'Package for you, brah.',
						no_escape:true,
						choices: {
							1: {
								txt:'Thanks!',
								value:'thx'
							}
						},
						itemstack_tsid:'IHH101BCDN224TN'
					};
						
					StageBeacon.setTimeout(ConversationManager.instance.start, 1000, convo);
					
					did_anything = true;
				}
				else if(txt.indexOf('/map_open') == 0){
					if(words.length > 1){
						HubMapDialog.instance.startWithTransitTsid(words[1]);
					}
					else {
						HubMapDialog.instance.start();
					}
					
					did_anything = true;
				}
				else if (txt.indexOf('/mail_debug') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type:"mail_check",
						message_count:2,
						itemstack_tsid:"IHH12TF7FI32CUR",
						base_cost:2.0,
						messages: [
							{
								message_id:0,
								item: {class_tsid:"glitchmas_cracker",count:1},
								currants:0,
								text:"Good news! The Glitchmas Yeti awoke from hibernation and sent us a box of these. We’re not sure what they are — though from the description on the packaging it seems to be some kind of explosive …<split butt_txt=\"Wot?\" />Yeah, we thought we should do the safe thing and get them out of the office as soon as possible. So we passed them on to you!<split butt_txt=\"Hmm. Thanks.\" />You might want to find a friend to pull it with, though. Who knows? Maybe there’s something inside. We’re too scared to look. Happy Glitchmas! — Tiny Speck",
								received:1325614169,
								replied:0,
								is_expedited:true,
								is_read:false
							},
							{
								message_id:1,
								currants:0,
								text:"Message 1",
								received:1325614178,
								replied:0,
								is_read:false
							}
						]
					});
					
					did_anything = true;
				}
				
				else if(txt.indexOf('/mail_check') == 0){
					MailManager.instance.parseMessages({
						message_count: 377,
						itemstack_tsid: "IHH10K7CMD32V33",  //tsid of the mailbox
						messages: [
							{ 
								message_id: "42",
								item: {
									class_tsid: "apple",
									count: 10
								},
								currants: 50,
								sender: {
									tsid: "P123124232",
									label: "John Smith"
								},
								text: "I'm an optional message!", 
								received: 123345456,  //timestamp of when the message was sent/received
								is_read: false  //has the message been read yet?
							},
							{ 
								message_id: "43",
								item: {
									class_tsid: "orange",
									count: 10
								},
								currants: 50000,
								sender: {
									tsid: "P123124232",
									label: "John Smith"
								},
								text: "I'm an optional message!", 
								received: 1233454567,  //timestamp of when the message was sent/received
								is_read: true  //has the message been read yet?
							}
						]
					});
					
					did_anything = true;
				}
				else if(txt.indexOf('/skills_can_learn') == 0){
					TSFrontController.instance.genericSend(new NetOutgoingSkillsCanLearnVO());
					
					did_anything = true;
				}
				else if (txt.indexOf('/fake_conversation') == 0) {
					fake_msg = {
						"is_phase":false,
						"type":"conversation",
						"performance_txt":"",
						"performance_rewards":{
							
						},
						"participation_txt":"You contributed 100% of the work we needed. Good job!",
						"job_location":"LHH11G4F1E61MOA",
						"txt":"Yay! The first phase — Phase 1 — of the project <b>Myles' Test Multi-Phase Job</b> has been completed!",
						"winning_option":{
							"perc":1,
							"desc":"This is option A.",
							"tsid":"LHH203N8TU515GP",
							"name":"Option A",
							"image":"http://c2.glitch.bz/street_upgrades/2010-10/1288412006-5176.png"
						},
						"show_teleport":false,
						"rewards":{

						},
						"uid":"1307996079",
						"job_complete_convo":true,
						"itemstack_tsid":"I-FAMILIAR",
						"class_id":"job_myles_test2",
						"job_id":"17",
						"choices":{
							"1":{
								"value":"job-complete",
								"txt":"OK"
							}
						}
					};
					
					if (txt.indexOf('/fake_conversation_rwds') == 0) {
						fake_msg.rewards = {
							"xp":10,
							"mood":10,
							"energy":10
						}
					}
					
					TSFrontController.instance.simulateIncomingMsg(fake_msg);
					did_anything = true;
				}
				else if (txt.indexOf('/fake_rainbows') == 0) {
					var allowed_temsA:Array = ['npc_piggy', 'npc_chicken', 'npc_butterfly', 'trant_egg', 'trant_spice', 'trant_bean', 'trant_bubble', 'trant_fruit', 'trant_gas'];
					var iii:int;
					for (k in model.worldModel.location.itemstack_tsid_list) {
						var itemstack:Itemstack = model.worldModel.getItemstackByTsid(k);
						
						if (allowed_temsA.indexOf(itemstack.class_tsid) == -1) continue;

						fake_msg = {
							"itemstack_tsid":k,
							"type":"itemstack_bubble",
							"msg":"YAY! Like, totally revived from my gnarly rooking, thanks to <b>Silly Hats Only</b>.",
							"offset_x":0,
							"ts":"2011:6:29 18:2:15",
							"offset_y":22,
							"duration":10500,
							"announcements":[
								{
									"itemstack_tsid":k,
									"dont_keep_in_bounds":true,
									"swf_url":"http://c2.glitch.bz/overlays/2011-06-28/1309293232_6596.swf",
									"type":"itemstack_overlay",
									"duration":4000,
									"height":400,
									"delta_x":0,
									"width":400,
									"delta_y":0,
									follow:true,
									allow_bubble:true
								}/*,
								{
									"is_exclusive":true,
									"sound":"RAINBOW_FULLYREVIVED",
									"type":"play_sound"
								}*/
							]
						};/*{
						type: "itemstack_bubble",
						msg: msg,
						itemstack_tsid: this.tsid,
						duration: duration // in milliseconds!
						};*/
						
						StageBeacon.setTimeout(TSFrontController.instance.simulateIncomingMsg, (iii++)*50, fake_msg);
					}
					
					
					did_anything = true;
				}
				else if (txt.indexOf('/fake_bubble') == 0) {
					fake_msg = {
						"itemstack_tsid":"IMF10D7QBL52N6T",
						"type":"itemstack_bubble",
						"msg":"YAY! Like, totally revived from my gnarly rooking, thanks to <b>Silly Hats Only</b>.",
						"offset_x":0,
						"ts":"2011:6:29 18:2:15",
						"offset_y":22,
						"duration":3500,
						"announcements":[
							{
								"itemstack_tsid":"IMF10D7QBL52N6T",
								"dont_keep_in_bounds":true,
								"swf_url":"http://c2.glitch.bz/overlays/2011-06-28/1309293232_6596.swf",
								"type":"itemstack_overlay",
								"duration":4000,
								"height":400,
								"delta_x":0,
								"width":400,
								"delta_y":0,
								follow:true,
								allow_bubble:true
							},
							{
								"is_exclusive":true,
								"sound":"RAINBOW_FULLYREVIVED",
								"type":"play_sound"
							}
						]
					};
					
					fake_msg = {
						"offset_x":50,
						"msg":"test",
						"duration":4000,
						"type":"itemstack_bubble",
						"itemstack_tsid":"IMF1C2C8J4R2FU3",
						"offset_y":-200
					}
					
					TSFrontController.instance.simulateIncomingMsg(fake_msg);
					did_anything = true;
				}
				else if (txt.indexOf('/fake_changes') == 0) {
					fake_msg = {
						"changes":{
							"itemstack_values":{
								"pc":{
									"ICREG82NLC12RNN":{
										"path_tsid":"ICREG82NLC12RNN",
										"count":11,
										"class_tsid":"seed_tomato",
										"slot":16,
										"version":"1305759676",
										"label":"Tomato Seed"
									}
								}
							},
							"location_tsid":model.worldModel.location.tsid
						},
						"type":"location_event"
					};
						
					TSFrontController.instance.simulateIncomingMsg(fake_msg);
					did_anything = true;
				}
				else if (txt.indexOf('/bad_changes') == 0) {
					
					// APPEARS ON THE GROUND
					var bad_msgsA:Array = [{
						"itemstack_tsid":"IHV17KV1RE42C1H",
						"changes":{
							"itemstack_values":{
								"location":{
									"IHV17KV1RE42C1H":{
										"count":1,
										"path_tsid":"IHV17KV1RE42C1H",
										"label":"Machine Stand",
										"x":model.worldModel.pc.x,
										"s":"stand2Hold",
										"y":model.worldModel.pc.y,
											"class_tsid":"machine_stand",
											"version":"1307742249"
									}
								},
								"pc":{
									"IHV17JV1RE42BBL":{
										"count":1,
										"slot":1,
										"path_tsid":"IHV17JV1RE42BBL",
										"label":"Blockmaker Chassis",
										"class_tsid":"blockmaker_chassis",
										"version":"1307742249"
									}
								}
							},
							"location_tsid":model.worldModel.location.tsid
						},
						"announcements":[
							{
								"count":1,
								"dest_slot":1,
								"orig_path":"IHVRBK7JCL32DFF",
								"type":"floor_to_pack",
								"orig_x":model.worldModel.pc.x,
								"dest_path":"IHV17JV1RE42BBL",
								"item_class":"blockmaker_chassis",
								"orig_y":model.worldModel.pc.y
							}
						],
						"s":"stand2Hold",
						"type":"item_state"
					},
					
					
					// CHANGES STATE
					{
						"itemstack_tsid":"IHV17KV1RE42C1H",
						"announcements":[
							{
								"is_exclusive":false,
								"sound":"STAND1",
								"type":"play_sound"
							}
						],
						"changes":{
							"itemstack_values":{
								"location":{
									"IHV17KV1RE42C1H":{
										"count":1,
										"path_tsid":"IHV17KV1RE42C1H",
										"label":"Machine Stand",
										"x":model.worldModel.pc.x,
										"s":"start",
										"y":model.worldModel.pc.y,
											"class_tsid":"machine_stand",
											"version":"1307742249"
									}
								}
							},
							"location_tsid":model.worldModel.location.tsid
						},
						"s":"start",
						"type":"item_state"
					},
					
					
					// REMOVED FROM GROUND AND PLACED IN BAG IN PACK
					{
						"itemstack_tsid":"IHV17KV1RE42C1H",
						"announcements":[
							{
								"count":1,
								"dest_slot":0,
								"orig_path":"IHV17KV1RE42C1H",
								"type":"floor_to_pack",
								"orig_x":model.worldModel.pc.x,
								"dest_path":"IHV17KV1RE42C1H",
								"item_class":"machine_stand",
								"orig_y":model.worldModel.pc.y
							},
							{
								"type":"energy_stat",
								"delta":-5
							}
						],
						"changes":{
							"itemstack_values":{
								"location":{
									"IHV17KV1RE42C1H":{
										"count":0,
										"class_tsid":"DELETED"
									}
								},
								"pc":{
									"IHV17KV1RE42C1H":{
										"count":1,
										"path_tsid":"IHV17KV1RE42C1H",
										"label":"Machine Stand",
										"s":"iconic",
										"slot":0,
										"class_tsid":"machine_stand",
										"version":"1307742249"
									}
								}
							},
							"stat_values":{
								"energy":1023
							},
							"location_tsid":model.worldModel.location.tsid
						},
						"s":"iconic",
						"type":"item_state"
					},
					
					
					// REMOVED FROM GROUND AGAIN?
					{
						"__SOURCE__":"processMessage_loc",
						"changes":{
							"itemstack_values":{
								"location":{
									"IHV17KV1RE42C1H":{
										"count":0,
										"class_tsid":"DELETED"
									}
								}
							},
							"location_tsid":model.worldModel.location.tsid
						},
						"type":"location_event"
					},
					
					
					// NOW IT IS ON THE GROUND??? BUT NOT DELETED FROM PACK
					{
						"__SOURCE__":"AdminCall_$#@_MAIN_OR_ADMIN_@#$_admin_get_stats",
						"changes":{
							"itemstack_values":{
								"location":{
									"IHV17KV1RE42C1H":{
										"count":1,
										"path_tsid":"IHV17KV1RE42C1H",
										"label":"Machine Stand",
										"x":model.worldModel.pc.x,
										"s":"stand2Hold",
										"y":model.worldModel.pc.y,
											"class_tsid":"machine_stand",
											"version":"1307742249"
									}
								}
							},
							"location_tsid":model.worldModel.location.tsid
						},
						"type":"location_event"
					},
					
					
					// NO IDEA WHAT THIS IS FOR NOTHING HAS CHANGED
					{
						"__SOURCE__":"RPCCall_exec_#executeMethodForOnlinePlayers",
						"changes":{
							"itemstack_values":{
								"location":{
									"IHV17KV1RE42C1H":{
										"count":1,
										"path_tsid":"IHV17KV1RE42C1H",
										"label":"Machine Stand",
										"x":model.worldModel.pc.x,
										"s":"stand2Hold",
										"y":model.worldModel.pc.y,
											"class_tsid":"machine_stand",
											"version":"1307742249"
									}
								}
							},
							"location_tsid":model.worldModel.location.tsid
						},
						"type":"location_event"
					}];
					
					for (i=0;i<bad_msgsA.length;i++) {
						StageBeacon.setTimeout(
							TSFrontController.instance.simulateIncomingMsg, (i+1)*1000, bad_msgsA[i]
						)
					}
					did_anything = true;
					
				}
				else if (txt.indexOf('/ambient') == 0) {
					SoundMaster.instance.is_ambient_playing ? SoundMaster.instance.ambientStop() : SoundMaster.instance.ambientPlay();
					
					did_anything = true;
				}
				else if (txt.indexOf('/stop_sound ') == 0){
					if(words.length > 1){
						SoundMaster.instance.stopSound(words[1]);
						
						did_anything = true;
					}
				}
				else if (txt.indexOf('/stop_music') == 0){
					SoundMaster.instance.stopAllMusic(words.length > 1 ? words[1] : 0);
					
					did_anything = true;
				}
				else if (txt.indexOf('/m4a') == 0){
					SoundMaster.instance.playSound('http://c2.glitch.bz/sounds/2011-06/1309210477-emerge.m4a', 1, 0, true);
						
					did_anything = true;
				}
				else if (txt.indexOf('/pack_toggle') == 0){
					PackDisplayManager.instance.changeVisibility(!PackDisplayManager.instance.is_viz, 'CGD');
						
					did_anything = true;
				}
				else if (txt.indexOf('/score_start') == 0){
					ScoreManager.instance.start({
						tsid:"it_game",
						title:"Game of Crowns",
						timer: 300,
						players: {
							0: {
								label: "Endoplasmic",
								tsid: "P12344556",
								score: 0
							},
							1: {
								label: "Playdoh",
								tsid: "P2384233",
								score: 0
							}
						}
					});
						
					did_anything = true;
				}
				else if (txt.indexOf('/score_update') == 0){
					ScoreManager.instance.update({
						tsid:"it_game",
						timer: 200,
						players: {
							0: {
								label: "Playdoh",
								tsid: "P2384233",
								score: 8,
								is_active: true
							},
							1: {
								label: "Endoplasmic",
								tsid: "P12344556",
								score: 3
							}
						}
					});
						
					did_anything = true;
				}
				else if (txt.indexOf('/score_end') == 0){
					ScoreManager.instance.end("it_game");
						
					did_anything = true;
				}
				else if (txt.indexOf('/tone_matrix') == 0){
					/*
					if(words.length > 2){
						if(words[2] == 'stop'){
							var child:DisplayObject;
							
							for(i = 0; i < TSFrontController.instance.getMainView().numChildren; i++){
								child = TSFrontController.instance.getMainView().getChildAt(i);
								if(child is ToneMatrix){
									TSFrontController.instance.getMainView().removeChild(child);
								}
							}
							
							if(SiONDriver.mutex && SiONDriver.mutex.isPlaying){
								SiONDriver.mutex.stop();
							}
						}
					}
					else {
						var tm:ToneMatrix = ToneMatrix.instance;
						tm.start((words.length > 1 && words[1] == 'sion' ? true : false));
						//tm.showSpectrum = true;
						TSFrontController.instance.getMainView().addView(tm);
					}
						
					did_anything = true;
					*/
				}
				else if (txt.indexOf('/splash_screen') == 0){
					if(words.length == 1){
						ScoreManager.instance.splash_screen({
							tsid:'it_game',
							graphic: {
								url: 'http://c2.glitch.bz/overlays%2F2011-09-07%2F1315416405_6381.swf',
								//text: 'Scott is the winner!',  //format is "game_splash_TSID_graphic"
								text_delta_x: 0,  //how much you want to offset the text. It is defaulted to centered left/right AND top/bottom
								text_delta_y: 0,
								scale: .70
							},
							show_rays:false, //if you want the white animated rays behind the logo
							text:'<font size="24">Hold the crown for <font size="35">60</font> seconds to win</font><br>'+
								  '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Tag the player with the crown to steal it<br>'+
								  '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• The crown can\'t be stolen when locked<br>'+
								  '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;• Only time below the "play line" counts',
							text_delta_x: 0,
							text_delta_y: 10,	  
							buttons: {
								is_vertical: false, //this is optional, it will default to having the buttons built and centered horizontally
								padding: 10, //space between buttons
								delta_x: 0,
								delta_y: 15,
								values: { //ordered list of buttons
									0:{
										label:"Let's GO!",
										click_payload: {},
										size: 'default', //used from the client.css file (ie. .button_default)
										type: 'brown' //used from the client.css file (ie. .button_minor_label)
									},
									1:{
										label:"I want to leave",
										click_payload: { does_close:true },
										size: 'default', //used from the client.css file (ie. .button_default)
										type: 'brown' //used from the client.css file (ie. .button_minor_label)
									}
								}
							}
						});
					}
					else {
						ScoreManager.instance.splash_screen({
							tsid:'it_game',
							graphic: {
								url: 'http://c2.glitch.bz/overlays%2F2011-09-08%2F1315512400_6033.swf',
								text: words[1] == 'me' ? '' : 'Some Long Name',  //format is "game_splash_TSID_graphic"
								text_delta_x: 0,  //how much you want to offset the text. It is defaulted to centered left/right AND top/bottom
								text_delta_y: 12,
								scale: 1,
								frame_label: words[1] == 'me' ? 'you_winner' : 'other_winner'
							},
							show_rays:true, //if you want the white animated rays behind the logo
							text:'',
							text_delta_x: 0,
							text_delta_y: 10,	  
							buttons: {
								is_vertical: false, //this is optional, it will default to having the buttons built and centered horizontally
								padding: 10, //space between buttons
								delta_x: 0,
								delta_y: 15,
								values: { //ordered list of buttons
									0:{
										label:"Again! Again!",
										click_payload: {},
										size: 'default', //used from the client.css file (ie. .button_default)
										type: 'brown' //used from the client.css file (ie. .button_minor_label)
									},
									1:{
										label:"I suck balls, bye.",
										click_payload: { does_close:true },
										size: 'default', //used from the client.css file (ie. .button_default)
										type: 'brown' //used from the client.css file (ie. .button_minor_label)
									}
								}
							}
						});
					}
					
					did_anything = true;
				}
				else if (txt.indexOf('/emblem_start') == 0){
					EmblemManager.instance.start({
						giant_class: 'ti',
						speed_up: 148345,
						is_primary: true,
						is_secondary: false
					});
					
					did_anything = true;
				}
				else if (txt.indexOf('/party_space') == 0){
					PartySpaceManager.instance.start({
						location_name:"Double Rainbow",
						img_url:"http://c1.glitch.bz/img/party/double_rainbow_67649.jpg",  //The image of the party space
						desc:"This party space is awesome and you'll blow your mind everywhere",
						energy_cost:100,  //how much energy it takes to teleport to the party
						pcs: [
							{
								label:"Endoplasmic",
								tsid:"P2345643"
							},
							{
								label:"Dr. Myles",
								tsid:"P098765678"
							},
							{
								label:"Scott Blarg",
								tsid:"PHH10B0VNN51QCD"
							}
						] //players that are in the party space already
					});
					
					did_anything = true;
				}
				else if (txt.indexOf('/harvest_progress') == 0){
					model.activityModel.announcements = Announcement.parseMultiple([
						{
							"locking":true,
							"delay_ms":120,
							"uid":'PHH103QATO319CT-'+(words.length > 2 ? words[2] : 'gardening_harvest'),
							"place_at_bottom":true,
							"local_uid":'3_annc_PHH103QATO319CT-'+(words.length > 2 ? words[2] : 'gardening_harvest'),
							"dismiss_payload":{
								"skill_package":(words.length > 2 ? words[2] : 'gardening_harvest'),
								"item_tsids":(words.length > 1 ? words[1] : 'IMF1118D56H2NQD')
							},
							"word_progress":{
								//"gradient_top":'#e900ec',
								//"gradient_bottom":'#7a007b',
								"type":(words.length > 2 ? words[2] : 'harvest')
							},
							"itemstack_tsid":(words.length > 1 ? words[1] : 'IMF1118D56H2NQD'),
							"duration":8000,
							"delta_y":-160,
							"dismissible":true,
							"type":'itemstack_overlay',
							//"swf_url":'http://c2.glitch.bz/overlays/2010-07-27/1280244434_3270.swf',
							"delta_x":0
						}
					]);
					
					did_anything = true;
				}
				else if (txt.indexOf('/npc_chat') == 0){
					RightSideManager.instance.chatUpdate(ChatArea.NAME_LOCAL, 'IMF101RS25I22U1', 'New project in a few minutes bitches!');
					
					did_anything = true;
				}
				else if (txt.indexOf('/convo_test') == 0){
					fake_msg = {
						"choices":{
							"1":{
								"value":'bye',
								"txt":'Thanks!'
							}
						},
						"offset_x":0,
						"txt":'Got your mail, brah.',
						"itemstack_tsid":'IHFHJ4N2CM53H6V',
						"offset_y":30
					}
					ConversationManager.instance.start(fake_msg);
					did_anything = true;
				}	
				else if (txt.indexOf('/door_add') == 0){
					did_anything = true;
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.DOOR_ADD,
						doors: {
							"door_1_sdkjhads":{
								"is_locked":false,
								"key_id":0,
								"connect":{
									"y":0,
									"swf_file_versioned":loc.swf_file_versioned,
									"street_tsid":loc.tsid,
									"hub_id":loc.mapInfo.hub_id,
									"mote_id":loc.mapInfo.mote_id,
									"label":"Fakety fake fake",
									"x":0,
									"img_file_versioned":null
								},
								"y":pc.y,
								"requires_level":0,
								"x":pc.x
							}
						}
					}, true);
				}	
				else if (txt.indexOf('/trap_door') == 0){
					// drop the floor our from under you
					plat = PlatformLine.getClosestUnder(model.worldModel.location.mg.platform_lines, model.worldModel.pc.x, model.worldModel.pc.y);
					if (plat) {
						tsid = plat.tsid;
						
						const plat_updates:Object = {'platform_lines': {}};
						
						//// geo_update method
						//const original_plat_pc_perm:* = plat.platform_pc_perm;
						//plat_updates.platform_lines[tsid] = {
						//	'platform_pc_perm': 0
						//};
						//TSFrontController.instance.updateGeo(plat_updates);
						//StageBeacon.setTimeout(function():void {
						//	plat_updates.platform_lines[tsid].platform_pc_perm = original_plat_pc_perm;
						//	TSFrontController.instance.updateGeo(plat_updates);
						//}, 1000);
						
						// geo_remove/geo_add method
						const original_plat_amf:Object = plat.AMF();
						plat_updates.platform_lines = [tsid];
						TSFrontController.instance.removeGeo(plat_updates);
						StageBeacon.setTimeout(function():void {
							plat_updates.platform_lines = {};
							plat_updates.platform_lines[tsid] = original_plat_amf;
							TSFrontController.instance.addGeo(plat_updates);
						}, 1000);
					}
					did_anything = true;
				}
				else if (txt.indexOf('/punch_wall') == 0){
					// punch out closest wall to you for a few seconds
					const closestWall:Object = Wall.getClosestToXY(model.worldModel.location.mg.walls, model.worldModel.pc.x, model.worldModel.pc.y);
					if (closestWall) {
						wall = Wall(closestWall.wall);
						tsid = wall.tsid;
						
						const wall_updates:Object = {'walls': {}};
						
						//// geo_update method
						//const original_wall_pc_perm:* = wall.pc_perm;
						//wall_updates.walls[tsid] = {
						//	'pc_perm': 0
						//};
						//TSFrontController.instance.updateGeo(wall_updates);
						//StageBeacon.setTimeout(function():void {
						//	wall_updates.walls[tsid].pc_perm = original_wall_pc_perm;
						//	TSFrontController.instance.updateGeo(wall_updates);
						//}, 3000);
						
						// geo_remove/geo_add method
						const original_wall_amf:Object = wall.AMF();
						wall_updates.walls = [tsid];
						TSFrontController.instance.removeGeo(wall_updates);
						StageBeacon.setTimeout(function():void {
							wall_updates.walls = {};
							wall_updates.walls[tsid] = original_wall_amf;
							TSFrontController.instance.addGeo(wall_updates);
						}, 3000);
					}
					did_anything = true;
				}
				else if (txt.indexOf('/remove_plats_above') == 0){
					// remove all plats above us
					const closestPlats:Object = PlatformLine.getPlatsAboveY(model.worldModel.location.mg.platform_lines, model.worldModel.pc.y, false);
					const geo_remove:Object = {'platform_lines': []};
					for each (plat in closestPlats) {
						(geo_remove.platform_lines as Array).push(plat.tsid);
					}
					TSFrontController.instance.removeGeo(geo_remove);
					did_anything = true;
				}
				else if (txt.indexOf('/remove_plats_below') == 0){
					// remove all plats above us
					const closestPlats2:Object = PlatformLine.getPlatsBelowY(model.worldModel.location.mg.platform_lines, model.worldModel.pc.y, false);
					const geo_remove2:Object = {'platform_lines': []};
					for each (plat in closestPlats2) {
						(geo_remove2.platform_lines as Array).push(plat.tsid);
					}
					TSFrontController.instance.removeGeo(geo_remove2);
					did_anything = true;
				}
				else if (txt.indexOf('/quest_req') == 0){
					QuestManager.instance.questRequirementHandler({
						"req_id":'r328',
						"status":{
							"need_num":5,
							"desc":'Teleport five times',
							"got_num":1,
							"item_class":'quest_req_icon_teleport',
							"completed":false,
							"is_count":true
						},
						"mission_accomplished":false,
						"quest_id":'teleportation_teleport_in_time_period'
					});
					QuestManager.instance.questRequirementHandler({
						"req_id":'r140',
						"status":{
							"need_num":1,
							"got_num":1,
							"desc":'Make a Cosma-politan',
							"item_class":'cosmapolitan',
							"completed":true,
							"is_count":true
						},
						"mission_accomplished":false,
						"quest_id":'cocktailcrafting_make_level2_recipes'
					});
					QuestManager.instance.questRequirementHandler({
						"req_id":'r104',
						"status":{
							"need_num":11,
							"desc":'Collect 11 Chunks of Sparkly',
							"got_num":7,
							"item_class":'sparkly',
							"completed":false,
							"is_count":true
						},
						"mission_accomplished":false,
						"quest_id":'mining_mine_rocks'
					});
					did_anything = true;
				}
				else if (txt.indexOf('/rebuild_location') == 0){
					LocationCommands.rebuildLocation();
					did_anything = true;
				}
				else if (txt.indexOf('/rebuild_layer ') == 0){
					if (words.length > 1) {
						tsid = String(words[1]);
						layer = loc.getLayerById(tsid);
						if (layer) {
							LocationCommands.rebuildLayersQuickly(new <Layer>[layer], TSFrontController.instance.getMainView().gameRenderer);
							did_anything = true;
						}
					}
				}
				else if (txt.indexOf('/update_deco_class ') == 0){
					if (words.length > 2) {
						tsid = String(words[1]);
						const newClass:String = String(words[2]);
						layers = {layers:{}};
						decoAndLayer = loc.getDecoAndLayerByDecoId(tsid);
						if (decoAndLayer) {
							layer = Layer(decoAndLayer.layer);
							deco = Deco(decoAndLayer.deco);
							layers.layers[layer.tsid] = {};
							layers.layers[layer.tsid][deco.tsid] = {sprite_class: newClass};
							TSFrontController.instance.updateDeco(layers);
							did_anything = true;
						}
					}
				}
				else if (txt.indexOf('/remove_decos ') == 0){
					if (words.length > 1) {
						const tsids:Array = String(words[1]).split(',');
						layers = {layers:{}};
						for each (tsid in tsids) {
							decoAndLayer = loc.getDecoAndLayerByDecoId(tsid);
							if (decoAndLayer) {
								layer = Layer(decoAndLayer.layer);
								deco = Deco(decoAndLayer.deco);
								if (layers.layers[layer.tsid]) {
									(layers.layers[layer.tsid] as Array).push(deco.tsid);
								} else {
									layers.layers[layer.tsid] = [deco.tsid];
								}
								did_anything = true;
							}
						}
						TSFrontController.instance.removeDeco(layers);
					}
				}
				else if (txt.indexOf('/chat_end ') == 0){
					RightSideManager.instance.chatEnd(words[1]);
					did_anything = true;
				}
				else if (txt.indexOf('/glitchr_dialog') == 0){
					GlitchrSavedDialog.instance.start();
					did_anything = true;
				}
				else if (txt.indexOf('/prompt') == 0){
					model.activityModel.addPrompt(
						Prompt.fromAnonymous({
							uid:'junk_from_debug',
							txt:'This is <a href="event:item|apple">clickable</a> ya?',
							timeout: 10,
							icon_buttons: true,
							timeout_value: 'No',
							choices: [{
								value: 'yes',
								label: 'Yes'
							}, {
								value: 'no',
								label: 'No'
							}]
						})
					);
					did_anything = true;
				}
				else if (txt.indexOf('/pack_wide') == 0){
					model.layoutModel.pack_is_wide = !model.layoutModel.pack_is_wide;
					TSFrontController.instance.getMainView().refreshViews();
					did_anything = true;
				}
				else if (txt.indexOf('/skill_cloud') == 0){
					ImgMenuView.instance.cloud_to_open = Cloud.TYPE_SKILLS;
					ImgMenuView.instance.show();
					did_anything = true;
				}				
				else if (txt.indexOf('/acl') == 0){
					//just for testing until the cloud comes back
					if(!ACLDialog.instance.parent) ACLDialog.instance.start();
					did_anything = true;
				}
				else if (txt.indexOf('/stack_furn_bag') == 0){
					model.flashVarModel.stack_furn_bag = !model.flashVarModel.stack_furn_bag;
					FurnitureBagUI.instance.refresh();
					
					did_anything = true;
				}
				else if (txt.indexOf('/garden_shit') == 0){				
					model.activityModel.announcements = Announcement.parseMultiple([{
						type: "itemstack_overlay",
						duration: 2000,
						delay_ms: 0,
						locking: true,
						itemstack_tsid:'IPF16VTPR8S21AF',
						state:'tool_animation',
						item_class:'watering_can',
						plot_id: 2,
						delta_x: 0,
						delta_y: -20
					}]);
					
					StageBeacon.setTimeout(function():void {
						TSFrontController.instance.simulateIncomingMsg({
							type:'itemstack_bubble',
							itemstack_tsid:'IPF16VTPR8S21AF',
							rewards: {
								energy: -2
							},
							msg:'Wetted.',
							duration:3500
						});
					}, 2000);
					did_anything = true;
				}
				else if (txt.indexOf('/crazynomore') == 0){
					removeAllFakeStacksInLocation();
					did_anything = true;
				}
				else if (txt.indexOf('/crazy') == 0){
					for (item_class in model.worldModel.items) {
						item = model.worldModel.items[item_class];
						if (item.stackmax > 1) {
							fakeAddingAStackToLocation(item_class, 'FAKE_'+item_class+(new Date().getTime()), model.worldModel.pc.x, model.worldModel.pc.y, item.stackmax);
							//TSFrontController.instance.genericSend(new NetOutgoingItemstackCreateVO(item_class, pc.x, pc.y, null, item.stackmax));
						}
					}
					did_anything = true;
				}
				else if (txt.indexOf('/map_center') == 0){
					//draw the you star on the map chat center or the other way that no nav system uses
					MapChatArea.center_star = !MapChatArea.center_star;
					did_anything = true;
				}
				else if (txt.indexOf('/img_menu') == 0){
					//simulate the server opening the iMG menu
					if(!ImgMenuView.instance.parent){
						ImgMenuView.instance.cloud_to_open = 'cloud_'+(words.length > 1 ? words[1] : 'upgrades');
						ImgMenuView.instance.hide_close = true;
						ImgMenuView.instance.show();
					}
					else {
						//close it up
						ImgMenuView.instance.hide();
					}
					
					did_anything = true;
				}
				else if (txt.indexOf('/furniture_pickup ') == 0){
					
					TSFrontController.instance.genericSend(
						new NetOutgoingFurniturePickupVO(words[1])
					);
					
					did_anything = true;
				}
				else if (txt.indexOf('/your_looks') == 0){
					if(!ImaginationYourLooksUI.instance.parent){
						ImgMenuView.instance.cloud_to_open = Cloud.TYPE_YOUR_LOOKS;
						ImgMenuView.instance.show();
					}
					
					did_anything = true;
				}
				else if (txt.indexOf('/audio_test') == 0){
					model.activityModel.announcements = Announcement.parseMultiple([{
						type: "play_music",
						mp3_url: "http://c2.glitch.bz/sounds/2011-10/1317492313-B_brown_2_short.mp3",
						loop_count: 999
					}]);
					
					did_anything = true;
				}
				else if (txt == '/getinforeport'){
					if (getinforeport) {
						System.setClipboard(getinforeport);
						activityTextHandler('ADMIN: The report has been put in your clipboard');
						getinforeport = null;
					} else {
						var report_str:String = 'tsid,has_info,proxy_item,info_url,has_infopage\n';
						var reportA:Array = [];
						var item_tsidsA:Array = [];
						for (tsid in model.worldModel.items) {
							//if (reportA.length > 2) break; 
							item_tsidsA.push(tsid);
							reportA.push(model.worldModel.items[tsid]);
						}
						activityTextHandler('ADMIN: loading info for '+item_tsidsA.length+' items');
						
						var api_call:APICall = new APICall();
						
						api_call.addEventListener(TSEvent.COMPLETE, function(event:TSEvent):void {
							reportA.sortOn(['has_info', 'tsid'], [Array.NUMERIC, Array.CASEINSENSITIVE]);
							for (i=0;i<reportA.length;i++) {
								item = reportA[i];
								report_str+= 
								item.tsid+','+
								item.has_info+','+
								(item.proxy_item || '')+','+
								(item.details?item.details.info_url || '':'')+','+
								(item.has_infopage)+
								'\n';
							}
							getinforeport = report_str;
							activityTextHandler('ADMIN: report generated, do /getinforeport again to get it in your clipboard');
						}, false, 0, true);
						
						api_call.addEventListener(TSEvent.ERROR, function(event:TSEvent):void {
							activityTextHandler('ADMIN: FAILED TO LOAD INFO!!!!!!');
						}, false, 0, true);
						
						
						api_call.itemsInfo(item_tsidsA);
					}
					
					did_anything = true;
				}
				else if (txt.indexOf('/card_thing') == 0){
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.IMAGINATION_PURCHASE_SCREEN,
						card: {
							config: {
								art:'quoinmood',
								icon:'upgrade',
								bg:'yellow',
								pattern:'upgrade',
								suit:'upgrade'
							},
							id:0,
							class_tsid:'quoin_multiplier',
							name:'Add 0.1 To Your Quoin Multiplier',
							cost:'200',
							desc:'Penis'
						}
					});
					
					did_anything = true;
				}
				else if (txt == '/dlist'){
					DisplayDebug.LogCoords(RightSideManager.instance.right_view, 10000, true);
					did_anything = true;
				}
				else if (txt.indexOf('/giant') == 0) {
					payload = {
						start_with_tip: true,
						tsid: words.length > 1 ? words[1] : 'alph',
						giant_of: 'Creation',
						personality: 'Playful, Inconsistent, Unreliable',
						desc: 'Alph is the giant responsible for creating “things”. And also “stuff”. ' +
							'Approaching everything with the question “What IF?”, Alph is never happier than when the answer ' +
							'results in a complex wadjamacallit or a satisfyingly big boom.',
						followers: 'Alphas',
						flv_url: words.length > 2 ? words[2] : 'http://files.tinyspeck.com/uploads/kristel/2012-08-27/Alph_432x240.flv',
						sound: 'GONG_GIANTS',
						tip_body: 'You can spend favor to speed up the learning of <a href="event:'+TSLinkedTextField.LINK_SKILL+'">Skills</a>'
					}
					
					TSFrontController.instance.addToScreenViewQ(new ScreenViewQueueVO(
						GiantView.instance.show,
						payload,
						true
					));
					
					did_anything = true;
				}
				else if (txt.indexOf('/s_travel') == 0) {
					payload = {
						text: 'In Soviet Long Fucking Hub Name, picture takes you!'
					}
					
					TSFrontController.instance.addToScreenViewQ(new ScreenViewQueueVO(
						SnapTravelView.instance.show,
						payload,
						true
					));
					
					did_anything = true;
				}
				else if (txt.indexOf('/s_scale') == 0) {
					SnapTravelView.instance.scale_to_viewport = !SnapTravelView.instance.scale_to_viewport;
					SnapTravelView.instance.refresh();
					
					did_anything = true;
				}
				else if (txt.indexOf('/feat_complete') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						choices: {
							1: {
								txt: "OK",
								value: "feat-complete"
							}
						},
						feat_id: "meditation_of_groddlocritus",
						itemstack_tsid: "I-FAMILIAR",
						job_complete_convo: true,
						rewards: {
							currants: 0,
							energy: 0,
							imagination: 37043,
							mood: 370433
						},
						title: "Feat Completed!",
						txt: "The ancient Feat \"The Meditation of Groddlocritus\" has been matched by you contemporary Glitches, working together. Your participation in the re-creation of this Feat has earned you a little reward:",
						type: "conversation",
						uid: "1346956478"
					});
					
					did_anything = true;
				}
				else if (txt.indexOf('/buff2') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						"type":"buff_start",
						"is_debuff":false,
						"ticks":0,
						"name":"Pretending to be buzzed",
						"duration":10.2,
						"item_class":"beer",
						"is_timer":true,
						"tsid":"buff_fake_buzzed",
						"desc":"Not actually buzzed, but you look really convincing"
					});
					
					did_anything = true;
				}
				else if (txt.indexOf('/create_account') == 0) {
					model.flashVarModel.is_stub_account = pc.needs_account = !pc.needs_account;
					RightSideManager.instance.right_view.createAccountShowHide(pc.needs_account);
					
					did_anything = true;
				}
				else if (txt.indexOf('/auto_snap') == 0) {
					TSFrontController.instance.simulateIncomingMsg({
						type: "snap_auto",
						uid: "1346956478"
					});
					
					did_anything = true;
				}
				else if (txt.indexOf('/questtrack') == 0) {
					if(!QuestTracker.instance.parent){
						QuestTracker.instance.show();
					}
					else {
						QuestTracker.instance.hide();
					}
					
					did_anything = true;
				}
				else if (txt.indexOf('/crafty_start') == 0) {
					CraftyDialog.instance.start();
					
					TSFrontController.instance.simulateIncomingMsg({
						"type"		: "craftybot_update",
						"jobs"		: [
							{
								"item_class"		: "apple",
								"done"			: 0,
								"total"			: 19,
								"craftable_count"	: 3,
								"status"		: {
									"is_complete"	: false,
									"is_active"	: false,
									"is_missing"	: false,
									"is_paused"	: false,
									"is_locked"	: false,
									"is_halted"	: false,
									"txt"		: "Pending"
								},
								"components"		: [
									{
										"item_classes"		: [
											"cherry"
										],
										"tool_class"		: "",
										"counts"		: [
											9
										],
										"counts_missing"	: [
											47
										],
										"type"			: "fetch",
										"status"		: "missing",
										"can_start"		: true,
										"status_txt"		: "You are missing some Cherries"
									},
									{
										"item_classes"		: [
											"fruit_changing_machine"
										],
										"tool_class"		: "",
										"counts"		: [
											1
										],
										"counts_missing"	: [
											0
										],
										"type"			: "fetch",
										"status"		: "pending",
										"can_start"		: true,
										"status_txt"		: ""
									},
									{
										"item_classes"		: [
											"apple"
										],
										"tool_class"		: "fruit_changing_machine",
										"counts"		: [
											3
										],
										"counts_missing"	: [
											0
										],
										"type"			: "craft",
										"status"		: "pending",
										"can_start"		: true,
										"status_txt"		: ""
									}
								]
							}],
						"jobs_max"	: 20,
						"crystal_count"	: "2",
						"crystal_max"	: "5",
						"fuel_count"	: 37,
						"fuel_max"	: "100",
						"can_refuel"	: true
					});
					
					did_anything = true;
				}
			}
			
			return did_anything;
		}
		
		CONFIG::god private var fake_stacks:Object = {};
		CONFIG::god private function removeAllFakeStacksInLocation():void {
			var fake_msg:Object = {
				"type": "location_event",
				"changes": {
					"location_tsid": model.worldModel.location.tsid,
						"itemstack_values": {
							"location": {}
						}
				}
			}
			for (var fake_tsid:String in fake_stacks) {
				fake_msg.changes.itemstack_values.location[fake_tsid] = {
					"count": 0,
					"path_tsid": fake_tsid,
					"class_tsid": "DELETED"
				}
			}
			TSFrontController.instance.simulateIncomingMsg(fake_msg);
			fake_stacks = {}
		}
		
		CONFIG::god private function fakeAddingAStackToLocation(item_class:String, fake_tsid:String, x:int, y:int, count:int=1):void {
			
			if (fake_stacks[fake_tsid]) {
				return;
			}
			
			fake_stacks[fake_tsid] = true;
			var fake_msg:Object = {
				"type": "location_event",
				"changes": {
					"location_tsid": model.worldModel.location.tsid,
						"itemstack_values": {
							"location": {}
						}
				}
			}
			fake_msg.changes.itemstack_values.location[fake_tsid] = {
				"x": x,
				"y": y,
				"count": count,
				"path_tsid": fake_tsid,
				"class_tsid": item_class
			}
			TSFrontController.instance.simulateIncomingMsg(fake_msg);
		}
		
		// this only calcs a time based on the time portion of the stamp created by StringUtil.getColonDateInGMT
		// and does not take into account the date. Which means if you are going to compare results from this function
		// with one another you must bedealing with all stamps from the same day! The returned value is just the number
		// of milliseconds in the give day.
		private function getTimeFromStamp(stamp:String):int {
			var time:String = stamp.split(' ')[1];
			var timeA:Array = time.split(':');
			var ms:int;
			if (timeA.length>0) ms+= int(timeA[0]*60*60*1000);
			if (timeA.length>1) ms+= int(timeA[1]*60*1000);
			if (timeA.length>2) ms+= int(timeA[2]*1000);
			if (timeA.length>3) ms+= int(timeA[3]);
			return ms;
		}
		
		private function replayMessages(A:Array):void {
			var start_time:int;
			var msg:Object;
			var time:int;
			var delay:int;
			for (var i:int=0;i<A.length;i++) {
				msg = A[i];
				if (!msg) {
					continue;
				}
				if (!msg.ts) {
					continue;
				}
				
				time = getTimeFromStamp(msg.ts);
				if (i==0) {
					start_time = time;
				}
				
				delay = 1000+time-start_time;
				//Console.info('replaying '+msg.type+' in '+delay+'ms ('+msg.ts+' '+time+' '+delay+')');
				delete msg.ts; // less noisy logs
				
				StageBeacon.setTimeout(TSFrontController.instance.simulateIncomingMsg, delay, msg);
			}
		}
		
		private function addLine(txt:String):void {
			RightSideManager.instance.chatUpdate(ChatArea.NAME_LOCAL, model.worldModel.pc.tsid, txt);
		}
		
		private function activityTextHandler(txt:String):void {
			var activity:Activity = new Activity('debug');
			activity.pc_tsid = model.worldModel.pc.tsid;
			activity.txt = txt;
			
			model.activityModel.activity_message = activity;
		}
		
		private function clear(chat_name:String = ''):void {
			if(!chat_name) chat_name = ChatArea.NAME_LOCAL;
			RightSideManager.instance.chatClear(chat_name);
		}
		
		private var track_int:uint;
		private var track_pt:Point;
		private var getinforeport:String;
	}
}
