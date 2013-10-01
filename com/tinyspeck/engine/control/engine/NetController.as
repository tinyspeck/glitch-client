package com.tinyspeck.engine.control.engine {
	CONFIG const counts_debug:Boolean = false;
	
	import com.tinyspeck.bootstrap.Version;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.memory.IDisposable;
	import com.tinyspeck.debug.API;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.LoginTool;
	import com.tinyspeck.debug.NewxpLogger;
	import com.tinyspeck.debug.PerfLogger;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.data.giant.GiantFavor;
	import com.tinyspeck.engine.data.group.Group;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.loading.LoadingInfo;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.making.Recipe;
	import com.tinyspeck.engine.data.map.MapPathInfo;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCBuff;
	import com.tinyspeck.engine.data.pc.PCFamiliar;
	import com.tinyspeck.engine.data.pc.PCHomeInfo;
	import com.tinyspeck.engine.data.pc.PCParty;
	import com.tinyspeck.engine.data.prompt.Prompt;
	import com.tinyspeck.engine.data.quest.Quest;
	import com.tinyspeck.engine.data.rook.RookedStatus;
	import com.tinyspeck.engine.model.MoveModel;
	import com.tinyspeck.engine.model.StateModel;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.net.INetResponder;
	import com.tinyspeck.engine.net.MessageTypes;
	import com.tinyspeck.engine.net.NetDelegateSocket;
	import com.tinyspeck.engine.net.NetIncomingMessageVO;
	import com.tinyspeck.engine.net.NetOutgoingDoorMoveEndVO;
	import com.tinyspeck.engine.net.NetOutgoingDoorMoveStartVO;
	import com.tinyspeck.engine.net.NetOutgoingFollowMoveEndVO;
	import com.tinyspeck.engine.net.NetOutgoingLoginEndVO;
	import com.tinyspeck.engine.net.NetOutgoingLoginStartVO;
	import com.tinyspeck.engine.net.NetOutgoingLogoutVO;
	import com.tinyspeck.engine.net.NetOutgoingMessageVO;
	import com.tinyspeck.engine.net.NetOutgoingMoveVecVO;
	import com.tinyspeck.engine.net.NetOutgoingMoveXYVO;
	import com.tinyspeck.engine.net.NetOutgoingReloginEndVO;
	import com.tinyspeck.engine.net.NetOutgoingReloginStartVO;
	import com.tinyspeck.engine.net.NetOutgoingSignpostMoveEndVO;
	import com.tinyspeck.engine.net.NetOutgoingSignpostMoveStartVO;
	import com.tinyspeck.engine.net.NetOutgoingTeleportMoveEndVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.net.NetServerMessage;
	import com.tinyspeck.engine.net.ServerActionTypes;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.physics.avatar.AvatarPhysicsObject;
	import com.tinyspeck.engine.physics.avatar.PhysicsSetting;
	import com.tinyspeck.engine.port.ACLDialog;
	import com.tinyspeck.engine.port.ACLManager;
	import com.tinyspeck.engine.port.JS_interface;
	import com.tinyspeck.engine.port.MakingDialog;
	import com.tinyspeck.engine.port.MakingManager;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.ContainersUtil;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.ObjectUtil;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.URLUtil;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.gameoverlay.CameraMan;
	import com.tinyspeck.engine.view.gameoverlay.CameraManView;
	import com.tinyspeck.engine.view.gameoverlay.DisconnectedScreenView;
	import com.tinyspeck.engine.view.gameoverlay.StreetUpgradeView;
	import com.tinyspeck.engine.view.geo.DoorView;
	import com.tinyspeck.engine.view.ui.chat.ChatArea;
	
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	CONFIG::counts_debug { import com.tinyspeck.engine.model.Counts; }
	CONFIG::god { import com.tinyspeck.engine.admin.AdminDialog; }
	CONFIG::locodeco { import com.tinyspeck.engine.admin.locodeco.LocoDecoSWFBridge; }
	
	public class NetController extends AbstractController implements IDisposable, INetResponder
	{
		private const rspSuccessHandlerDict:Dictionary = new Dictionary(true);
		private const rspFailureHandlerDict:Dictionary = new Dictionary(true);
		private const moxy:NetOutgoingMoveXYVO = new NetOutgoingMoveXYVO(0,0,'0');
		private const movec:NetOutgoingMoveVecVO = new NetOutgoingMoveVecVO();
		private var loc_event_no_props:int;
		
		private var _netDelegate:NetDelegateSocket;
		public function get netDelegate():NetDelegateSocket {
			return _netDelegate;
		}
		
		private var world:WorldModel;
		
		private var moveXYtimer:Timer;
		
		private var pc_As:Object;
		private var loc_As:Object;
		
		private var loc_itemstack_updates:Array = [];
		private var loc_itemstack_adds:Array = [];
		private var loc_itemstack_dels:Array = [];
		private var pc_itemstack_updates:Array = [];
		private var pc_itemstack_adds:Array = [];
		private var pc_itemstack_dels:Array = [];
		
		private var is_first_move:Boolean = true;
		
		internal var remembered_login_start_im:NetIncomingMessageVO;
		
		private var nc_msg_handler:NCMsgHandler;
		
		public function NetController() {
			super();
			
			world = model.worldModel;
			
			nc_msg_handler = new NCMsgHandler(this, model);
			
			_netDelegate = new NetDelegateSocket(this, model);
			
			moveXYtimer = new Timer(100);
			moveXYtimer.addEventListener(TimerEvent.TIMER, onMoveXYtimer);
			CONFIG::god {
				if (model.flashVarModel.use_vec) {
					var tim:Timer = new Timer(1000)
					tim.addEventListener(TimerEvent.TIMER, logMoveVecMsgRates);
					tim.start();
				}
			}
		}
		
		public function genericSend(nomVO:NetOutgoingMessageVO, successHandler:Function = null, failureHandler:Function = null):void {
			if (MessageTypes.isMoveRelatedMessageType(nomVO.type)) {
				Benchmark.addCheck('sending: '+nomVO.type);
			}
			nomVO.needs_msg_id = true;
			_netDelegate.addRequest(nomVO);
			bindResponseIdToHandlers(nomVO.msg_id, successHandler, failureHandler);
			_netDelegate.sendRequests();
		}
		
		// this is for testing only
		public function sendAnonMsg(msg:Object):void {
			_netDelegate.addAnonRequest(msg);
			_netDelegate.sendRequests();
		}
		
		private function bindResponseIdToHandlers(id:String, successHandler:Function = null, failureHandler:Function = null):void {
			if (successHandler != null) rspSuccessHandlerDict[id] = successHandler;
			if (failureHandler != null) rspFailureHandlerDict[id] = failureHandler;
		}
		
		public function connect():void {
			if (!LoginTool.reportStep(6, 'nc_connect')) return;
			Benchmark.addCheck('NC.connect');
			// _netDelegate will callback to connectHandler
			_netDelegate.connect(model.moveModel.host, model.moveModel.port, model.moveModel.token);
		}
		
		private function disconnect(msg:String, disconnect_delay_ms:int=0, view_delay_secs:Number=1):void {
			Benchmark.addCheck('NC.disconnect msg: '+msg);
			
			model.netModel.disconnected_msg = msg;
			DisconnectedScreenView.instance.show(msg, view_delay_secs);
			
			model.netModel.client_disconnected = true;
			
			// _netDelegate will callback to disconnectHandler
			StageBeacon.setTimeout(_netDelegate.disconnect, disconnect_delay_ms);
		}
		
		public function startSendingPCPos():void {	
			if (!moveXYtimer.running) moveXYtimer.start();
		}
		
		public function stopSendingPCPos():void {
			moveXYtimer.stop();
		}
		
		private function onMoveXYtimer(e:TimerEvent):void {
			maybeSendMoveXY();
		}
		
		public function maybeSendMoveXY():void {
			var pc:PC = world.pc;
			if (!pc || pc.following_pc_tsid) return;
			
			// does this fix all the stuck in ground problems??
			if (model.moveModel.moving) return;
			
			var sm:StateModel = model.stateModel;
			
			// if you change this logic, you'd better sure as shit check and make sure we don't end up sending
			// move_xy msgs when we don't have to
			if (!sm.report_a_jump && (pc.s == moxy.s) && (Math.round(pc.x) == moxy.x) && (Math.round(pc.y) == moxy.y) && !model.flashVarModel.report_rendering) {
				return;
			}
			
			//Console.info(pc.x+' '+pc.y);
			
			sendMoveXY(pc.x, pc.y, pc.s, sm.report_a_jump);
			sm.report_a_jump = false;
		}
		
		private function sendMoveXY(x:Number, y:Number, s:String, is_jump:Boolean):void {
			//Console.trackValue('NC pc.s', s)
			moxy.x = Math.round(x);
			moxy.y = Math.round(y);
			moxy.s = s;
			moxy.is_jump = (is_jump) ? true : null;
			
			CONFIG::god {
				if (model.flashVarModel.report_rendering) {
					var sm:StateModel = model.stateModel;
					moxy.fps = Math.floor(sm.fps.averageValue);
					CONFIG::debugging {
						Console.trackValue(' moxy.fps', moxy.fps);
					}
					moxy.render = ObjectUtil.copyOb(sm.renderA) as Array;
					sm.renderA.length = 0;
					
					moxy.script = ObjectUtil.copyOb(sm.scriptA) as Array;
					sm.scriptA.length = 0;
				}
			}
			
			_netDelegate.addRequest(moxy);
			_netDelegate.sendRequests();
			CONFIG::debugging {
				Console.trackValue('AVA NC moxy', 'x:'+x+' y:'+y+' s:'+s);
			}
			
			// we shoud do this some other way
			TSFrontController.instance.updatePCLoggingData();
		}
		
		public function maybeSendMoveVec(apo:AvatarPhysicsObject,s:String):void {
			var do_send:Boolean;
			if (movec.s != s) {
				do_send = true;
			}
			if (movec.vx != apo.vx) {
				do_send = true;
			}
			var corrected_vy:Number = (apo.vy == -.01) ? 0 : apo.vy;
			if (movec.vy != corrected_vy) {
				do_send = true;
			}
			
			if (do_send) {
				sendMoveVec(s, apo.vx, corrected_vy);
			}
		}
		
		private function sendMoveVec(s:String, vx:Number, vy:Number):void {
			//Console.trackValue('NC pc.s', s)
			movec.s = s;
			movec.vx = vx;
			movec.vy = vy;

			CONFIG::debugging {
				Console.trackPhysicsValue('NC sent', 'vx:'+movec.vx+' vy:'+movec.vy);
			}
			
			_netDelegate.addRequest(movec);
			_netDelegate.sendRequests();
			CONFIG::debugging {
				Console.trackValue('AVA NC movec', 's:'+s);
			}
			
			// we shoud do this some other way
			//TSFrontController.instance.updatePCLoggingData();
		}
		
		private function sendLoginStart(nomVO:NetOutgoingLoginStartVO):void {
			genericSend(nomVO, loginSuccessHandler, loginFailureHandler);
			// response handled by dealWithMessageType (for updating model) AND the methods bound above 
		}
		
		private function sendReloginStart(nomVO:NetOutgoingReloginStartVO):void {
			genericSend(nomVO, reloginSuccessHandler, reloginFailureHandler);
			// response handled by dealWithMessageType (for updating model) AND the methods bound above
		}
		
		public function sendLogout():void {
			if (!model.netModel.connected) return;
			var nomVO:NetOutgoingLogoutVO = new NetOutgoingLogoutVO();
			genericSend(nomVO);
			if (!model.netModel.disconnected_msg) disconnect('WAIT! You were just about to win the game!', 100, 0);
		}
		
		public function onFatalError(msg:String):void {
			var nomVO:NetOutgoingLogoutVO = new NetOutgoingLogoutVO();
			genericSend(nomVO);
			disconnect(msg, 100, 0);
		}
		
		private function loginSuccessHandler(rm:NetResponseMessageVO):void {
			//Login has succeeded, and we can expect a location.
			model.netModel.loggedIn = true;
			_netDelegate['sendPing']();
		}
		private function reloginSuccessHandler(rm:NetResponseMessageVO):void {
			//Login has succeeded, and we can expect a location.
			model.netModel.loggedIn = true;
			_netDelegate['sendPing']();
		}
		
		private function loginFailureHandler(rm:NetResponseMessageVO):void {
			//We have failed to login.
			model.netModel.loggedIn = false;
		}
		
		private function reloginFailureHandler(rm:NetResponseMessageVO):void {
			//We have failed to relogin.
			model.netModel.loggedIn = false;
		}
		
		private function setHostPortAndToken(hostport:String, token:String):void {
			CONFIG::debugging {
				Console.info('new connection values: '+hostport+' '+token);
			}
			
			if (hostport && token) {
				var login_host_parts:Array = hostport.split(':');
				if (login_host_parts.length == 2 && token.length) {
					model.moveModel.host = login_host_parts[0];
					model.moveModel.low_port = login_host_parts[1];
					model.moveModel.token = token;
					return;
				}
			}
			
			CONFIG::debugging {
				Console.error('bad hostport:'+hostport+' or token:'+token)
			}
		}
		
		public function actuallyStartLocationMove(relogin:Boolean, move_type:String, from_tsid:String = '', to_tsid:String = '', signpost_index:String = '', hostport:String = '', token:String = '', delay_loading_screen_ms:int = 0):void {
			if (model.moveModel.moving && !relogin) {
				Benchmark.addCheck('NC.actuallyStartLocationMove: Tried to start a new move, but already moving.');
				CONFIG::debugging {
					Console.error('can\'t start a new move, because already moving.');
				}
				return;
			}
			
			// log it correctly! if it is a relogin of a user initiated move, it is not really a move start, so ignore
			switch (move_type) {
				case MoveModel.LOGIN_MOVE:
				case MoveModel.DOOR_MOVE:
				case MoveModel.SIGNPOST_MOVE:
					if (!relogin) {
						Benchmark.startSection(Benchmark.SECTION_MOVE_STARTING);
					}
					break;
				case MoveModel.TELEPORT_MOVE:
				case MoveModel.FOLLOW_MOVE:
				case MoveModel.RELOGIN_MOVE:
					Benchmark.startSection(Benchmark.SECTION_MOVE_STARTING);
					break;
				default:
					Benchmark.addCheck('SOMETHING IS FUCKED WITH THIS move_type:'+move_type);
			}
			
			Benchmark.addCheck('NC.actuallyStartLocationMove '+
				' relogin:'+relogin+
				' move_type:'+move_type+
				' from_tsid:'+from_tsid+
				' to_tsid:'+to_tsid+
				' signpost_index:'+signpost_index+
				' hostport:'+hostport+
				' token:'+token+
				' delay_loading_screen_ms:'+delay_loading_screen_ms);
			
			model.moveModel.move_type = move_type;
			model.moveModel.move_failed = false;
			model.moveModel.relogin = relogin;
			model.moveModel.from_tsid = from_tsid;
			model.moveModel.to_tsid = to_tsid;
			model.moveModel.signpost_index = signpost_index;
			//model.moveModel.hostport = hostport;
			//model.moveModel.token = token;
			model.moveModel.moving = true;
			model.moveModel.delay_loading_screen_ms = delay_loading_screen_ms;
			
			if (model.moveModel.relogin) {
				setHostPortAndToken(hostport, token);
				
			} else {
				
				switch (model.moveModel.move_type) {
					case MoveModel.LOGIN_MOVE:
						if (!LoginTool.reportStep(9, 'nc_starting_move')) return;
						TSFrontController.instance.startLoginTracking();
						const loginStartMessage:NetOutgoingLoginStartVO = new NetOutgoingLoginStartVO();
						CONFIG::perf {
							if (model.flashVarModel.run_automated_tests) {
								loginStartMessage.perf_testing = true;
							}
						}
						sendLoginStart(loginStartMessage);
						break;
					
					case MoveModel.DOOR_MOVE:	
						showMovingOverlay();
						
						genericSend(
							new NetOutgoingDoorMoveStartVO(model.moveModel.from_tsid)
						);
						
						//play a sound
						var doorView:DoorView = TSFrontController.instance.getMainView().gameRenderer.getDoorViewByTsid(model.moveModel.from_tsid);
						if(doorView && !doorView.door.is_locked){
							SoundMaster.instance.playSound('DOOR_OPEN');
						}
						break;
					
					case MoveModel.SIGNPOST_MOVE:
						showMovingOverlay();
						
						genericSend(
							new NetOutgoingSignpostMoveStartVO(model.moveModel.from_tsid, model.moveModel.signpost_index)
						);
						break;
					
					case MoveModel.TELEPORT_MOVE:
						// these are started by the server, so we do not need to do anything else
						break;
					
					case MoveModel.FOLLOW_MOVE:
						// there are started by the server, so we do not need to do anything else
						break;
					
					default:
						CONFIG::debugging {
							Console.error("unhandled model.moveModel.move_type:"+model.moveModel.move_type);
						}
						break;
				}	
			}
		}
		
		public function showMovingOverlay():void {
			var dest_name:String = '';
			if (model.moveModel.to_tsid && world.locations[model.moveModel.to_tsid]) {
				var dest_loc:Location = world.locations[model.moveModel.to_tsid];
				dest_name = ' to '+dest_loc.label;
			}
			
			model.activityModel.announcements = Announcement.parseMultiple([{
				type: "vp_overlay",
				dismissible: false,
				locking: true,
				click_to_advance: false,
				text: ['<p align="center"><span class="nuxp_big">Moving'+dest_name+'...</span></p>'],
				x: '50%',
				y: '50%',
				delay_ms: 1000,
				width: Math.max(model.layoutModel.min_vp_w-100, model.layoutModel.loc_vp_w-200),
				uid: 'moving_client_msg',
				bubble_god: true
			}]);
		}
		
		public function sendEndMoveMsg():void {
			Benchmark.addCheck('NC.endMoving type:'+model.moveModel.move_type+
							   ' from:'+model.moveModel.from_tsid+
							   ' to:'+model.moveModel.to_tsid+
							   ' relogin:'+model.moveModel.relogin);
			
			if (model.moveModel.relogin) {
				genericSend(
					new NetOutgoingReloginEndVO(model.moveModel.move_type)
				);
			} else {
				
				switch (model.moveModel.move_type) {
					case MoveModel.LOGIN_MOVE:
						genericSend(new NetOutgoingLoginEndVO());
						break;
					
					case MoveModel.DOOR_MOVE:
						genericSend(
							new NetOutgoingDoorMoveEndVO(model.moveModel.from_tsid)
						);
						break;
					
					case MoveModel.SIGNPOST_MOVE:
						genericSend(
							new NetOutgoingSignpostMoveEndVO(model.moveModel.from_tsid, model.moveModel.signpost_index)
						);
						break;
					
					case MoveModel.TELEPORT_MOVE:
						genericSend(
							new NetOutgoingTeleportMoveEndVO(model.moveModel.from_tsid, model.moveModel.to_tsid)
						);
						break;
					
					case MoveModel.FOLLOW_MOVE:
						genericSend(
							new NetOutgoingFollowMoveEndVO(model.moveModel.from_tsid, model.moveModel.to_tsid)
						);
						break;
					
					default:
						CONFIG::debugging {
							Console.error('unhandled moveModel.move_type:'+model.moveModel.move_type)
						}
						break;
				}
			}
		}
		
		public function resumeRelogin():void
		{
			if (model.moveModel.relogin) {
				const reloginStartMessage:NetOutgoingReloginStartVO = new NetOutgoingReloginStartVO(model.moveModel.move_type);
				CONFIG::perf {
					if (model.flashVarModel.run_automated_tests) {
						reloginStartMessage.perf_testing = true;
					}
				}
				sendReloginStart(reloginStartMessage);
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.error('WTF');
				}
			}
		}
		
		/*private function setReconnectToken(token:String):void {
			model.netModel.reconnectToken = token;
		}*/
		
		/**
		 * All callbacks expected from the _netDelegate
		 */
		public function connectHandler():void {
			Benchmark.addCheck('NC.connectHandler');
			CONFIG::debugging {
				Console.info('connectHandler');
			}
			model.netModel.disconnected_msg = '';
			DisconnectedScreenView.instance.hide();
			model.netModel.connected = true;
			if (model.moveModel.relogin) {
				resumeRelogin();
			} else {
				if (model.netModel.reconnecting_after_unexpected_disconnect) {
					model.activityModel.god_message = 'You were temporarily disconnected from the game server. Reconnecting...';
					
					// we must relogin!
					const hostport:String = model.moveModel.host + ':' + model.moveModel.low_port;
					TSFrontController.instance.startLocationMove(true, MoveModel.RELOGIN_MOVE, '','','', hostport, model.moveModel.token);
					resumeRelogin();
				} else {
					if (!LoginTool.reportStep(7, 'nc_connected')) return;
					Benchmark.addSectionTime(Benchmark.SECTION_ENGINE_STARTING);
					TSFrontController.instance.startLocationMove(false, MoveModel.LOGIN_MOVE);
				}
			}
			
			// reset to false
			model.netModel.reconnecting_after_unexpected_disconnect = false;
			
			StageBeacon.setTimeout(TSFrontController.instance.checkSentMessagesAfterReconnection, 5000);
		}
		
		public function disconnectHandler():void {
			Benchmark.addCheck('NC.disconnectHandler should_reconnect:'+model.netModel.should_reconnect);

			if (model.netModel.should_reload) {
				// token expired
				TSFrontController.instance.maybeReload(
					"The connection to the game server timed out",
					"The connection to the game server timed out, and I am having trouble staying connected",
					true
				);
				return;
			} else if (!model.netModel.disconnected_msg && (getTimer() - model.netModel.last_activity) > 3.5*60*1000) {
				// if the timeout has been longer than 3.5 minutes, reload the client
				TSFrontController.instance.maybeReload(
					"It's been a while since I spoke to the game server",
					"It's been a while since I spoke to the game server; I am having trouble staying connected",
					true
				);
				return;
			}
			
			model.netModel.connected = false;
			model.netModel.loggedIn = false;
			
			if (model.netModel.should_reconnect) {
				model.netModel.should_reconnect = false; // no reconnects now until we successfully login again
				CONFIG::debugging {
					Console.info('trying to reconnect');
				}
				model.netModel.reconnecting_after_unexpected_disconnect = true;
				// needs a few ms, or else it fails, I guess because disconnect is not fully finished yet?
				StageBeacon.waitForNextFrame(connect);
			} else {
				// this is a fail safe, in case we were disconnected without notice.
				if (model.netModel.client_disconnected) {
					if (!model.netModel.disconnected_msg) {
						model.netModel.disconnected_msg = 'OMG reload!<br>(how is this even possible?)';
					}
					DisconnectedScreenView.instance.show(model.netModel.disconnected_msg, 0);
				} else {
					// This could be because the server disconnected without a SERVER_MESSAGE with action:close and a msg,
					// or because the connection was broken somehow else
					if (!model.netModel.disconnected_msg) {
						BootError.addErrorMsg('Unexpected disconnect', null, ['net']);
						model.netModel.disconnected_msg = 'OMG reload!<br>(unexpected disconnect)';
					}
					DisconnectedScreenView.instance.show(model.netModel.disconnected_msg, 0);
				}
				
				PerfLogger.stopLogging();
			}
			
			model.netModel.client_disconnected = false;
		}
		
		// special handler for evts of type server_message
		public function netServerMessageHandler(sm:NetServerMessage):void {
			switch(sm.action){
				case ServerActionTypes.TOKEN:
					// store this to be used for any reconnects (PREPARE_TO_RECONNECT or a *_move_start msg with hostport and token can and should overwrite these values) 
					model.moveModel.token = sm.msg;
					break;
				case ServerActionTypes.PREPARE_TO_RECONNECT:
					// we now expect to soon get a CLOSE:CONNECT_TO_ANOTHER_SERVER msg, and we'll want to use these value to reconnect
					setHostPortAndToken(sm.payload.hostport, sm.payload.token);
					
					TSFrontController.instance.rollingRestartStarting();
					
					break;
				case ServerActionTypes.CLOSE:
					
					// by default if we're sent a CLOSE msg, do not reconnect
					model.netModel.should_reconnect = false;
					
					if (sm.msg == "LOGGED_IN_FROM_OTHER_CLIENT") {
						disconnect('You logged in elsewhere!');
					} else if (sm.msg == "API_LOGOUT_CALL") {
						disconnect('Looks like you are logging in elsewhere.');
					} else if (sm.msg == "Invalid sessionID A instead of B") {
						disconnect('Looks like the server is restarting. MSG was: '+sm.msg);
					} else if (sm.msg == "TIMEOUT") {
						disconnect('Connection timed out!');
						
						if (model.moveModel.moving) {
							model.netModel.should_reload = true;
							disconnectHandler();
						} else {
							API.getToken(function(success:Boolean, rsp:Object):void {
								if (success) {
									setHostPortAndToken(rsp.host, rsp.token);
									// this is problematic if we are in the middle of a move!!
									model.netModel.should_reconnect = true;
									disconnectHandler();
								} else {
									model.netModel.should_reload = true;
									disconnectHandler();
								}
							});
						}
						
					} else if (sm.msg == "CONNECT_TO_ANOTHER_SERVER") {
						if (model.netModel.should_reload_at_next_location_move) {
							reloadClient();
							return;
						}
						
						model.netModel.should_reconnect = true;

						CONFIG::debugging {
							if (model.moveModel.relogin) {
								Console.info('reconnect now, part of a move');
							} else {
								Console.info('not part of a move');
							}
						}
						
						disconnect('Reconnecting...', 0, 3);
						
					} else if (sm.msg == "NEED_TO_RECONNECT") {
						model.netModel.should_reconnect = true;
						disconnect('Need to reconnect...');
					} else if (sm.msg == "SERVER_SHUTDOWN") {
						TSFrontController.instance.initiateShutDownSequence(60);
						disconnect('Server restarted', 60000, 60);
					} else if (sm.msg && (sm.msg.toUpperCase().indexOf("TOKEN EXPIRED") > -1 || sm.msg.toUpperCase().indexOf("INVALID TOKEN") > -1)) {
						var str:String = sm.msg+
							'\n\nNETCONTROLLER ADDING BENCHMARK DETAILS:\n\n'+Benchmark.getShortLog()+
							'\n\nNETCONTROLLER ADDING DECO LOADING DETAILS:\n\n'+model.stateModel.getDecoCountReport()+
							'\n\nNETCONTROLLER ADDING MSGS:\n----------------------------------------------------\n\n'+BootError.buildMsgsString();
						
						CONFIG::counts_debug {
							str += '\n\nNETCONTROLLER ADDING COUNTS:\n\n'+Counts.report();
						}
						
						if (model.moveModel.move_type == MoveModel.LOGIN_MOVE) {
							TSFrontController.instance.maybeReload(
								'I have not successfully logged on',
								'I still have not successfully logged on',
								true
							);
							return;
						} else {
							str = 'Trying to reconnect after: '+str
							API.getToken(function(success:Boolean, rsp:Object):void {
								if (success) {
									setHostPortAndToken(rsp.host, rsp.token);
									model.netModel.should_reconnect = true;
									disconnectHandler();
								} else {
									disconnect(sm.msg.toUpperCase());
								}
							});
						}
						API.reportError(str, '', true, '', '', ['reconnect']);
						disconnect('Invalid token error! I will try to reconnect you!');
					} else {
						disconnect('OMG reload! (unrecognized msg:'+sm.msg+')');
						BootError.addErrorMsg(sm.msg, null, ['net']);
					}
					break;
				default:
					CONFIG::debugging {
						Console.warn("couldn't handle netServerMessage action "+sm.action);
					}
					break;
			}
		}
		
		// a function only to be used during initial login
		public function getTokenAndConnect():void {
			if (!LoginTool.reportStep(4, 'nc_getting_token')) return;
			
			var url:String = EnvironmentUtil.getURLAndQSArgs().url;
			
			// in these cases, we do not want to call getToken, because that the results would
			// be for the player logged into the website, which would prohibit us from logging 
			// in as local_pc
			if (model.flashVarModel.local_pc || (url && (url.indexOf('jdev') != -1 || url.indexOf('jstaging') != -1))) {
				if (!LoginTool.reportStep(5, 'nc_has_token')) return; // there are two possible step 5s, depending on environment
				connect();
				return;
			}
			
			API.getToken(onGotTokenFromAPI);
		}
		
		// a function only to be used during initial login
		private function onGotTokenFromAPI(success:Boolean, rsp:Object):void {
			if (!LoginTool.reportStep(5, 'nc_got_token')) return; // there are two possible step 5s, depending on environment
			if (success) {
				setHostPortAndToken(rsp.host, rsp.token);
			} else {
				BootError.addErrorMsg('unable to retrieve token', null, ['net']);
			}
			connect();
		}
		
		// handler for all evt messages from the server
		public function eventMessageHandler(im:NetIncomingMessageVO):void {
			// first, we call any handlers listening for all messages of this type
			try {
				dealWithMessageType(im);
			} catch (err:Error) {
				BootError.handleError('dealWithMessageType failed '+im.type+' '+StringUtil.getJsonStr(im.payload)+'', err, ['net'], !CONFIG::god);
			}
			
			// post process
			try {
				postProcessMessage(im);
			} catch (err:Error) {
				BootError.handleError('postProcessMessage im failed '+im.type+' '+StringUtil.getJsonStr(im.payload)+'', err, ['net'], !CONFIG::god);
			}
		}
		
		// handler for all rsp messages from the server
		public function responseMessageHandler(rm:NetResponseMessageVO):void {
			// first, we call any handlers listening for all messages of this type	
			try {
				dealWithMessageType(rm);
			} catch (err:Error) {
				BootError.handleError('dealWithMessageType failed '+rm.type+' '+StringUtil.getJsonStr(rm.payload)+'', err, ['net'], !CONFIG::god);
			}
			
			// now hand the rsp off to anyone handling it specifically
			if (rm.success){
				if (rspSuccessHandlerDict[rm.msg_id]){
					try {
						rspSuccessHandlerDict[rm.msg_id](rm);
					} catch (err:Error) {
						BootError.handleError('rspSuccessHandlerDict failed '+rm.type+' '+StringUtil.getJsonStr(rm.payload)+'', err, ['net'], !CONFIG::god);
					}
				}
			} else {
				if (rspFailureHandlerDict[rm.msg_id]){
					try {
						rspFailureHandlerDict[rm.msg_id](rm);
					} catch (err:Error) {
						BootError.handleError('rspFailureHandlerDict failed '+rm.type+' '+StringUtil.getJsonStr(rm.payload)+'', err, ['net'], !CONFIG::god);
					}
				}
			}
			
			delete rspSuccessHandlerDict[rm.msg_id];
			delete rspFailureHandlerDict[rm.msg_id];
			
			// post process
			try {
				postProcessMessage(rm);
			} catch (err:Error) {
				BootError.handleError('postProcessMessage failed '+rm.type+' '+StringUtil.getJsonStr(rm.payload)+'', err, ['net'], !CONFIG::god);
			}
		}
		
		internal function handlePOLInfo(info:Object, is_change:Boolean = false):void {
			//if they had a pol before, and now they don't, see if they will still have keys
			if(world.pc.pol_tsid && !info){
				ACLManager.instance.key_count = Math.max(0, ACLManager.instance.key_count-1);
			}
			else if(info && info.street_tsid){
				if(is_change && !ACLManager.instance.key_count){
					//they just got this place and didn't have any keys, so we show a nice welcome message
					ACLDialog.instance.startWithMessage(true);
				}
				
				//increase the key count for owning a house
				ACLManager.instance.key_count++;
			}
			
			if (info && info.street_tsid){
				Location.fromAnonymousLocationStub(info);
				world.pc.pol_tsid = info.street_tsid;
			} else {
				world.pc.pol_tsid = '';
			}
		}
		
		internal function handleHomeInfo(info:Object, is_change:Boolean = false):void {
			//if they had a home before, and now they don't, see if they will still have keys
			if(world.pc.home_info && !info){
				ACLManager.instance.key_count = Math.max(0, ACLManager.instance.key_count-1);
			}
			else if(info){
				if(is_change && !ACLManager.instance.key_count){
					//they just got this place and didn't have any keys, so we show a nice welcome message
					ACLDialog.instance.startWithMessage(true);
				}
				
				//increase the key count for owning a house
				if(!world.pc.pol_tsid){
					ACLManager.instance.key_count++;
				}
			}
			
			//add each location key to the world
			world.pc.home_info = info ? PCHomeInfo.fromAnonymous(info) : null;
			/*
			if(info){
				var k:String;
				for(k in info){
					Location.fromAnonymousLocationStub(info[k]);
					if('is_interior' in info[k] && info[k].is_interior === true){
						//THIS WILL SUPPORT LEGACY CALLS TO pol_tsid
						world.pc.pol_tsid = k;
					}
				}
				
				world.pc.home_info = info;
			}
			*/
		}
		
		CONFIG::god internal var move_vec_count_hash:Object = {}
		CONFIG::god private function logMoveVecMsgRates(e:TimerEvent=null):void {
			for (var tsid:String in move_vec_count_hash) {
				CONFIG::debugging {
					Console.trackPhysicsValue('NC vec '+tsid, move_vec_count_hash[tsid]);
				}					
				move_vec_count_hash[tsid] = 0;
			}
		}
		
		// called by both responseMessageHandler and eventMessageHandler
		private function dealWithMessageType(im:NetIncomingMessageVO):void {
			var nrm:NetResponseMessageVO = ((im is NetResponseMessageVO) ? NetResponseMessageVO(im) : null);
			
			if (MessageTypes.isMoveRelatedMessageType(im.type)) {
				if (nrm) {
					Benchmark.addCheck('acting on: '+im.type+' after '+(nrm.request ? (nrm.time_recv-nrm.request.time_sent) : 'nrm.request null ')+'ms');
				} else {
					Benchmark.addCheck('acting on: '+im.type);
				}
			}
			
			// make sure we have a handler for it
			if (!(im.type in nc_msg_handler.type_to_func)) {
				CONFIG::debugging {
					Console.warn("unhandled netmessage type:"+im.type);
				}
				return;
			}

			var func:Function = nc_msg_handler.type_to_func[im.type] as Function;
			
			// if set to null that means we dont need to do anything;
			if (func == null) return;
			
			func(im);
		}
		
		internal function updatePCCameraCapabilities(ob:Object):void {
			if (!ob) return;
			var pc:PC = world.pc;
			if ('can_snap' in ob) pc.cam_can_snap = ob.can_snap || false;
			if ('range' in ob) pc.cam_range = Math.abs(ob.range);
			if (!pc.cam_can_snap && ob.disabled_reason) {
				CameraManView.instance.cam_disabled_reason = ob.disabled_reason;
			}
			if ('skills_msg' in ob) {
				CameraManView.instance.cam_skills_msg = ob.skills_msg;
			}
		}
		
		// called by both responseMessageHandler and eventMessageHandler
		// RH : What is this supposed to do ? 
		// EC: certain types of data can be attached to many different message. this handles them.
		internal function postProcessMessage(im:NetIncomingMessageVO):void {
			if (im.payload.changes) {
				try {
					changesHandler(im.payload.changes);
				} catch (err:Error) {
					BootError.handleError('changesHandler failed '+im.type+' '+StringUtil.getJsonStr(im.payload)+'', err, ['net'], !CONFIG::god);
				}
				im.payload.changes = null;
				delete im.payload.changes;
			}
			if (im.payload.announcements) {
				model.activityModel.announcements = Announcement.parseMultiple(im.payload.announcements); // fires trigger when set
				im.payload.announcements = null;
				delete im.payload.announcements;
			}
		}
		
		// handles changes section of messages
		internal function changesHandler(changes:Object):void {
			const pc:PC = world.pc;
			const loc:Location = world.location;
			
			var k:String;
			var itemstack:Itemstack;
			var itemstack_data:Object;
			var pc_data:Object;
			
			if (!pc) {
				CONFIG::debugging {
					Console.warn('no pc yet! can\'t do anything with the changes');
				}
				return;
			}
			
			// for now we are just going to fire a single noice that stats have changes, and not individual ones for each stat
			if ('stat_values' in changes) {
				var c:int = 0;
				var stat:String;
				
				for (stat in changes.stat_values) {
					// fix that naming problem!
					if (stat == 'ti') stat = 'tii';
					
					if (pc.stats.hasOwnProperty(stat)) {
						if (stat == 'xp') {
							if (pc.stats[stat].total != changes.stat_values[stat]) {
								c++;
								pc.stats[stat].total = changes.stat_values[stat];
							}
						} else if (stat == 'currants' || stat == 'imagination' || stat == 'credits') {
							if (pc.stats[stat] != changes.stat_values[stat]) {
								c++;
								pc.stats[stat] = changes.stat_values[stat];
							}
						} else if (pc.stats[stat].value != changes.stat_values[stat]) {
							if (pc.stats[stat] != changes.stat_values[stat]) {
								c++;
								pc.stats[stat].value = changes.stat_values[stat];
							}
						}
					}else if(pc.stats.favor_points.getFavorByName(stat)){
						//the stat_value from the server is based on the current daily donated amount, not your grand total
						const favor:GiantFavor = pc.stats.favor_points.getFavorByName(stat);
						if (favor.cur_daily_favor != changes.stat_values[stat]) {
							c++;
							favor.cur_daily_favor = changes.stat_values[stat];
						}
					} else {
						CONFIG::debugging {
							;
							Console.warn('changes.stat_values child "'+stat+'" has no analog on the pc; perhaps it was missing from the pc.stats object in the login rsp');
						}
					}
				}
				
				if (c>0) world.triggerCBProp(false,false,"pc","stats");
				//Console.info(c+' changes')
			}



			//Console.info('changesHandler'+('itemstack_values' in changes))
			if ('itemstack_values' in changes) {
				// we need this further down; getting it here before we go over changes.itemstack_values.location because I am not sure if it needs to be b4 that or not
				pc_As = null;
				if ('pc' in changes.itemstack_values) {
					pc_As = ContainersUtil.getItemstackTsidAsGroupedByContainer(pc.itemstack_tsid_list, world.itemstacks);
				}
				
				// FIRST DO ALL DELETES
				
				// handle DELETED items in location
				if ('location' in changes.itemstack_values && loc && changes.location_tsid == loc.tsid) {
					loc_As = ContainersUtil.getItemstackTsidAsGroupedByContainer(loc.itemstack_tsid_list, world.itemstacks);
					loc_itemstack_updates.length = 0;
					loc_itemstack_adds.length = 0;
					loc_itemstack_dels.length = 0;
					
					//changes.itemstack_values.location has changed/deleted/new itemstacks for the location
					for (k in changes.itemstack_values.location) {
						itemstack_data = changes.itemstack_values.location[k];
						itemstack = world.getItemstackByTsid(k);
						
						var deleted:Boolean = itemstack_data.count === 0;
						
						// this detects when a stack has been moved from location into a bag in location
						// I am not 100% sure we shoudl handle this the same as when itemstack_data.count === 0
						// but it seems to work for now
						deleted = deleted || (itemstack_data.path_tsid && itemstack && itemstack_data.path_tsid != itemstack.path_tsid)
						
						// delete it, amd make sure all of its contained items are removed from the location too
						if (deleted) {
							// removes all descendants of the container from loc.itemstack_tsid_list
							if (loc_As[k]) {
								removeTsidsFromHash(k, loc_As, loc.itemstack_tsid_list);
							}

							if (!itemstack) {
								CONFIG::debugging {
									Console.error(k + ' not exists');
								}
								continue;
							}
							
							if (k in loc.itemstack_tsid_list) {
								delete loc.itemstack_tsid_list[k];
							} else if (k == itemstack.path_tsid) { // it is not in a cabinet or trophy case, so this has to be an error
								if (k != itemstack_data.path_tsid) {
									// THIS IS A SPECIAL CASE BECAUSE IT SEEMS I GET DUPLICATE MESSAGES
									// WHEN MOVING AN ITEM FROM AN IN-LOCATION CABINET TO PACK, AND IN 
									// THAT CASE THE DELETE CHANGES HAS A PATH_TSID THAT INDICATES ITS
									// OLD PATH IN THE CABINET (BUT THE ITEMSTACK HAS ALREADY BEEN MOVE
									// SO IT HAS A PATH IN THE PACK
									; //cry more compiler
									CONFIG::debugging {
										Console.warn('DUPE DELETE MESSAGE?');
									}
								} else {
									BootError.handleError(k + ' not exists in location, but a delete changes was sent for it', new Error('Unknown itemstack'), ['net'], !CONFIG::debugging);
								}
								continue;
								
							} else {
								CONFIG::debugging {
									if (itemstack && itemstack.item.is_furniture || itemstack.item.is_special_furniture) {
										// nothing to worry about. we optimistically move furniture when dragging it about, so it would likely have already been removed
									} else {
										Console.warn(k + ' not exists in location???');
									}
								}
							}
							
							if (k in world.itemstacks) {
								//don't do this! we need a reference to even deleted itemstacks
								//delete world.getItemstackByTsid(k);
							}
							
							Benchmark.addCheck('LOC STACK DEL: '+k);
							loc_itemstack_dels.push(k);
						}
					}
					
					if (loc_itemstack_dels.length) {
						//Console.warn('loc_itemstack_dels '+loc_itemstack_dels)
						world.loc_itemstack_dels = loc_itemstack_dels; // calls a trigger when set
					}
				}
				
				// handle DELETED items in pack
				if ('pc' in changes.itemstack_values) {
					// handle items in pc pack
					pc_itemstack_updates.length = 0;
					pc_itemstack_adds.length = 0;
					pc_itemstack_dels.length = 0;
					
					//changes.itemstack_values.pc has changed/deleted/new itemstacks for the pc
					for (k in changes.itemstack_values.pc) {
						itemstack_data = changes.itemstack_values.pc[k];
						// delete it if it has a count of 0
						if (itemstack_data.count === 0) {
							// removes all descendants of the container from pc.itemstack_tsid_list
							if (pc_As && pc_As[k]) {
								removeTsidsFromHash(k, pc_As, pc.itemstack_tsid_list);
							}
							
							if (k in pc.itemstack_tsid_list) {
								delete pc.itemstack_tsid_list[k];
							} else {
								// TOO MANY FALSE POSITIVES HERE. REENABLE ERROR REPORTING WHEN WE GET ALL THE PRiVATE BAG TSIDS http://bugs.tinyspeck.com/3909
								// BootError.handleError(k + ' not exists in pack, but a delete changes was sent for it', new Error('Unknown itemstack'), !CONFIG::debugging);
								continue;
							}
							
							if (k in world.itemstacks) {
								//don't do this! we need a reference to even deleted itemstacks
								//delete world.getItemstackByTsid(k);
							}
							
							if (!world.getItemstackByTsid(k)) {
								CONFIG::debugging {
									Console.warn(k + ' not exists');
								}
								continue;
							}
							
							Benchmark.addCheck('PC STACK DEL: '+k);
							pc_itemstack_dels.push(k);
						}
					}
					
					if (pc_itemstack_dels.length) {
						//Console.warn('pc_itemstack_dels '+pc_itemstack_dels)
						world.pc_itemstack_dels = pc_itemstack_dels; // calls a trigger when set
					}
					
				}
				
				// NOW DO ALL ADDS/UPDATES
				
				// handle added/changed items in location
				if ('location' in changes.itemstack_values && loc && changes.location_tsid == loc.tsid) {
					
					//changes.itemstack_values.location has changed/deleted/new itemstacks for the location
					for (k in changes.itemstack_values.location) {
						itemstack_data = changes.itemstack_values.location[k];
						
						if (itemstack_data.count === 0) {
							// deletes are done above
						} else {
							if (k in world.itemstacks) {
								if (k in world.pc.itemstack_tsid_list) {
									
									// We used to error out here, like this...
									/*
									BootError.handleError(k + ' is in pack ('+world.getItemstackByTsid(k).path_tsid+'), but a changes was sent for it in location?', new Error('Bad Changes'), ['net'], !CONFIG::debugging);
									continue;
									*/
									
									// ... but now we just remove the fucker for the pc list and add it to location.
									// to repro when this happens, see http://bugs.tinyspeck.com/8078
									// AFAICT it is only an issue wih nested moving boxes, and I'm not taking the time right now
									// to work through the messaging and changes handling to see WTF, because this "works"
									delete world.pc.itemstack_tsid_list[k];
									CONFIG::debugging {
										Console.warn(k + ' is in pack ('+world.getItemstackByTsid(k).path_tsid+'), but a changes was sent for it in location?');
									}
									
								}
								itemstack = Itemstack.updateFromAnonymous(itemstack_data, world.getItemstackByTsid(k));
							} else {
								if (!Item.confirmValidClass(itemstack_data.class_tsid, k)) {
									continue;
								}
								itemstack = Itemstack.fromAnonymous(itemstack_data, k);
							}
							
							world.itemstacks[k] = itemstack;
							
							if (!(k in loc.itemstack_tsid_list)) {
								Benchmark.addCheck('LOC STACK ADD: '+k+' '+itemstack.class_tsid);
								loc_itemstack_adds.push(k);
								loc.itemstack_tsid_list[k] = k;
							} else {
								//Benchmark.addCheck('LOC STACK UPD: '+k+' '+itemstack.class_tsid);
								loc_itemstack_updates.push(k);
							}
						}
					}
					
					if (loc_itemstack_updates.length) {
						//Console.warn('loc_itemstack_updates '+loc_itemstack_updates)
						world.loc_itemstack_updates = loc_itemstack_updates; // calls a trigger when set
					}
					if (loc_itemstack_adds.length) {
						//Console.warn('loc_itemstack_adds '+loc_itemstack_adds)
						world.loc_itemstack_adds = loc_itemstack_adds; // calls a trigger when set
					}
				}
				
				// handle added/changed items in pack
				if ('pc' in changes.itemstack_values) {
					
					//changes.itemstack_values.pc has changed/deleted/new itemstacks for the pc
					for (k in changes.itemstack_values.pc) {
						itemstack_data = changes.itemstack_values.pc[k];

						if (itemstack_data.count === 0) {
							// deletes are done above
						} else {
							if (k in world.itemstacks) {
								if (k in world.location.itemstack_tsid_list) {
									BootError.handleError(k + ' is in location, but a changes was sent for it in pack?', new Error('Bad Changes'), ['net'], !CONFIG::debugging);
									continue;
								}
								itemstack = Itemstack.updateFromAnonymous(itemstack_data, world.getItemstackByTsid(k));
							} else {
								if (!Item.confirmValidClass(itemstack_data.class_tsid, k)) {
									continue;
								}
								itemstack = Itemstack.fromAnonymous(itemstack_data, k);
							}
							
							if (!world.items[itemstack.class_tsid]) {
								CONFIG::debugging {
									Console.error(k+' has unknown itemstack.class_tsid:'+itemstack.class_tsid);
								}
								continue;
							}
							
							if (pc.isContainerPrivate(itemstack.container_tsid)) {
								// this might be ok, special cased because we don't actually keep a stack in world.itemstacks for these special bags
								
								if (itemstack.container_tsid == pc.trophy_storage_tsid) {
									// this is ok
								} else if (itemstack.container_tsid == pc.escrow_tsid) {
									// this is ok
								} else if (itemstack.container_tsid == pc.auction_storage_tsid) {
									// this is ok
								} else {
									CONFIG::debugging {
										Console.warn('ignoring item in '+itemstack.container_tsid+' because it is private');
									}
									continue;
								}
							} else if (itemstack.container_tsid && PackDisplayManager.instance.isContainerTsidPrivate(itemstack.container_tsid)) {
								// this is ok, special cased because we don't actually keep a stack in world.itemstacks for private trophy storage
								
								// SHOULD CONTINUE HERE? OR DOES IT NOT REALLY MATTER?
							} else if (itemstack.container_tsid && itemstack.container_tsid == pc.furniture_bag_tsid) {
								// this is ok, special cased because we don't actually keep a stack in world.itemstacks for furniture bag
								
							} else if (itemstack.container_tsid && !world.itemstacks[itemstack.container_tsid] && !changes.itemstack_values.pc[itemstack.container_tsid]) {
								CONFIG::debugging {
									Console.error(k+' in unknown container '+itemstack.container_tsid);
								}
								continue;
							}
							
							world.itemstacks[k] = itemstack;
							
							if (!(k in pc.itemstack_tsid_list)) {
								Benchmark.addCheck('PC STACK ADD: '+k+' '+itemstack.class_tsid);
								pc_itemstack_adds.push(k);
								pc.itemstack_tsid_list[k] = k;
							} else {
								//Benchmark.addCheck('PC STACK UPD: '+k+' '+itemstack.class_tsid);
								pc_itemstack_updates.push(k);
							}
						}
					}
					
					if (pc_itemstack_updates.length) {
						//Console.warn('pc_itemstack_updates '+pc_itemstack_updates)
						world.pc_itemstack_updates = pc_itemstack_updates; // calls a trigger when set
					}
					
					if (pc_itemstack_adds.length) {
						//Console.warn('pc_itemstack_adds '+pc_itemstack_adds)
						world.pc_itemstack_adds = pc_itemstack_adds; // calls a trigger when set
					}
				}
			}
			
			CONFIG::debugging {
				logTsidLists();
			}
		}

		CONFIG::debugging internal function logTsidLists():void {
			if (Console.priOK('59')) {
				var str:String = '';
				var k:String;
				for (k in world.pc.itemstack_tsid_list) str+=k+' ';
				Console.info('pc itemstack_tsid_list: '+str);
				str = '';
				for (k in world.location.itemstack_tsid_list) str+=k+' ';
				Console.info('loc itemstack_tsid_list: '+str);
			}
		}
		
		private function removeTsidsFromHash(key:String, As:Object, hash:Dictionary):void {
			var tsids:Array = As[key];
			var i:int;
			
			for (i=0;i<tsids.length;i++) {
				if (tsids[int(i)] in hash) delete hash[tsids[int(i)]];
				if (As[tsids[int(i)]]) removeTsidsFromHash(tsids[int(i)], As, hash);
			}
		}
		
		/** set model.netModel.reload_message first */
		// we handle all msgs of *_start
		internal function reloadClient():void {
			model.netModel.disconnected_msg = 'RELOADING...<br>' + model.netModel.reload_message;
			DisconnectedScreenView.instance.show(model.netModel.disconnected_msg, .1);
			StageBeacon.setTimeout(URLUtil.reload, 3000);
		}
		
		// we handle all msgs of *_start
		internal function locationMoveStartHandler(im:NetIncomingMessageVO, proceed_after_animation:Boolean = false):void {
			if (!LoginTool.reportStep(14, 'nc_move_start_1')) return;
			Benchmark.addCheck('NC.locationMoveStartHandler before parsing: '+im.type);
			var payload:Object = im.payload;
			
			AnnouncementController.instance.cancelOverlay('moving_client_msg');
			
			if (model.netModel.should_reload_at_next_location_move && im.type != MessageTypes.LOGIN_START) {
				if (payload.hostport && payload.token) {
					// we wait for CONNECT_TO_ANOTHER_SERVER gs message
					return;
				} else {
					if (!payload.in_location) {
						reloadClient();
						return;
					}
				}
			}

			CONFIG::debugging {
				Console.info('incoming '+im.type);
			}
			
			CONFIG::god {
				// if the location was saved but wasn't resnapped and we're
				// doing a GS teleport, then we need to issue a warning
				if (model.stateModel.loc_saved_but_not_snapped && (im.type == MessageTypes.TELEPORT_MOVE_START)) {
					// reset this now, so we don't ask in TSFrontController
					//
					// the problem is that we cannot delay a GS-issued teleport
					// because the GS disconnects us from the game server
					// and expects us to connect to the new GS immediately
					model.stateModel.loc_saved_but_not_snapped = false;
					// so this is the best we can do:
					TSFrontController.instance.growl('*** YOU FORGOT TO RESNAP THE LAST LOCATION YOU WERE AT ***');
				}
			}
			
			//set the loading info in the move model -- might be too early, needs some testing
			if(im.payload && im.payload.loading_info){
				//if there are any PCs in the leaderboard, let's handle them!
				if(im.payload.loading_info.upgrade_details && im.payload.loading_info.upgrade_details.leaderboard){
					handlePCsInOrderedHash(im.payload.loading_info.upgrade_details.leaderboard);
				}
				
				model.moveModel.loading_info = LoadingInfo.fromAnonymous(im.payload.loading_info, im.type);
				delete im.payload.loading_info;
			}
			
			if (model.moveModel.moving) {
				// these two types of moved are started by the GS, so if we're already moving, we need to ignore them
				// (an error; the GS should know to not send this message)
				if (im.type == MessageTypes.TELEPORT_MOVE_START || im.type == MessageTypes.FOLLOW_MOVE_START) {
					CONFIG::debugging {
						model.activityModel.growl_message = 'DEBUG: ignoring this '+im.type+' because we\'re already moving';
					}
					BootError.handleError("ignoring "+im.type+" because we're already moving", new Error(), ['net'], true, false);
					return;
				}
			}
			
			var delay_loading_screen_ms:int = 0;
			
			//do we have some loading music?
			if (payload.loading_music) {
				if (model.moveModel.loading_music) {
					SoundMaster.instance.stopSound(model.moveModel.loading_music, 1);
				}
				model.moveModel.loading_music = payload.loading_music;
				SoundMaster.instance.playSound(payload.loading_music, 99999, .5, true);
				delete payload.loading_music;
			}
			
			// show door animation, but only if it is a successful move
			if (im.type == MessageTypes.DOOR_MOVE_START && (NetResponseMessageVO(im).success)) {
				if (proceed_after_animation) {
					Benchmark.addCheck('NC.locationMoveStartHandler: door move was unlocked, now proceeding');
					
					//play a sound
					SoundMaster.instance.playSound('DOOR_OPEN');
				} else {
					if (TSFrontController.instance.showDoorUnlocked(model.moveModel.from_tsid, payload.in_location)) { // last arg says if to relock it, since we are staying in the same location
						// don't bother with this delay if moving to another GS (because that requires an immediate relogin dance at this point)
						if (!(payload.hostport && payload.token)) {
							Benchmark.addCheck('NC.locationMoveStartHandler: door needs unlocking, setTimeout so we can see the animation');
							StageBeacon.setTimeout(function():void {
								Benchmark.addCheck('NC.locationMoveStartHandler: door unlock animation was shown, now recall self');
								locationMoveStartHandler(im, true);
							}, 1000);
							
							return;
							
						//instead, delay the loading screen
						} else {
							delay_loading_screen_ms = 2000;
							Benchmark.addCheck('NC.locationMoveStartHandler: door needs unlocking, setting delay_loading_screen_ms:'+delay_loading_screen_ms+' so we can see the animation');
						}
						
					} else {
						Benchmark.addCheck('NC.locationMoveStartHandler: door was NOT unlocked, proceeding normally');
					}
				}
			}
			
			const world:WorldModel = world;
			world.prev_location = world.location;
			model.moveModel.move_was_in_location = false; // not really, but we'll trip it to true if we have to
			
			try {
				TSFrontController.instance.cancelAllAvatarPaths('NC.locationMoveEndHandler');
				world.pc.apo.triggerResetVelocity = true;
			} catch(err:Error) {
				CONFIG::debugging {
					Console.warn('world.pc.avatarPhysicsObject.triggerResetVelocity = true FAILED')
				}
			}
			
			if (payload.in_location) {
				
				model.moveModel.move_was_in_location = true;
				//move the player someplace else in the same zone
				world.pc = PC.updateFromAnonymous(payload.pc, world.pc);
				maybeSendMoveXY();
				Benchmark.addCheck('NC.locationMoveStartHandler: '+im.type+' move was in_location:true');
				moveHasEnded('in_location');
				return;
				
			} else if (payload.location){
				var loc_tsid:String = payload.location.tsid;
				
				// since we have a location, we know we do not need to do any relogging on
				switch (im.type) {
					case MessageTypes.DOOR_MOVE_START:
						// started by the client, so we do not need to do anything
						/*CONFIG::debugging {
							Console.info (model.moveModel.from_tsid+' is from_tsid')
						}*/
						break;
					
					case MessageTypes.SIGNPOST_MOVE_START:
						// started by the client, so we do not need to do anything
						break;
					
					case MessageTypes.LOGIN_START:
						// started by the client, so we do not need to do anything
						break;
					
					case MessageTypes.RELOGIN_START:
						// hrmm. do we need to do anything?
						if (payload.buddies){
							handleBuddies(payload.buddies);
							delete payload.buddies;
						} else {
							; // satisfy compiler
							CONFIG::debugging {
								Console.error('relogin_start with no buddies');
							}
						}
						break;
					
					case MessageTypes.TELEPORT_MOVE_START:
						TSFrontController.instance.startLocationMove(
							false,
							MoveModel.TELEPORT_MOVE,
							world.pc.location.tsid,
							loc_tsid
						);
						
						//check if this is because of an upgrade
						if(payload.change_type && payload.change_type == 'upgrade'){
							StreetUpgradeView.instance.show(payload);
						}
						break;
					
					case MessageTypes.FOLLOW_MOVE_START:
						TSFrontController.instance.startLocationMove(
							false,
							MoveModel.FOLLOW_MOVE,
							world.pc.location.tsid,
							loc_tsid
						);
						break;
					
					default:
						CONFIG::debugging {
							Console.warn("unhandled message type:"+im.type);
						}
						break;
				}
				
				// check for rooked_status
				
				if (!payload.location.rooked_status) {
					CONFIG::debugging {
						Console.error('A LOCATION W/OUT A rooked_status');
					}
					payload.location.rooked_status = {
						rooked: false,
						epicentre: false
					}
				}
				
				model.rookModel.rooked_status = RookedStatus.fromAnonymous(payload.location.rooked_status, loc_tsid); // calls a trigger when set
				delete payload.location.rooked_status
				
				var setting:Object;
				var existing_setting:PhysicsSetting;
				
				// handle anything in location.temp 
				if (payload.location.temp) {
					if (payload.location.temp.physics_configs) {
						
						// get all the settings the GS sent
						for (var setting_name:String in payload.location.temp.physics_configs) {
							setting = payload.location.temp.physics_configs[setting_name];
							
							// let's make sure that the physics ob for the location has everything necessary
							if (setting_name == 'normal') {
								if (payload.location.physics) {
									for (var kk:String in setting) {
										if (!(kk in payload.location.physics)) {
											CONFIG::debugging {
												Console.error('loc physics lacked:'+kk+', set now to:'+setting[kk]+' from normal config');
											}
											payload.location.physics[kk] = setting[kk];
										}
									}
								}
							}
							
							existing_setting = model.physicsModel.settables.getSettingByName(setting_name);
							if (existing_setting) {
								PhysicsSetting.updateFromAnonymous(setting, existing_setting);
							} else {
								model.physicsModel.settables.addSetting(PhysicsSetting.fromAnonymous(setting, setting_name));
							}
						}
						
						payload.location.temp.physics_configs = null;
						delete payload.location.temp.physics_configs;
					}
					
					payload.location.temp = null;
					delete payload.location.temp;
				}
				
				// store this now b4 we delete!
				world.physics_obs[loc_tsid] = payload.location.physics;
				
				// set up physics per this location
				if (payload.location.physics) {
					// add the physics to the physics model
					setting = payload.location.physics;
					existing_setting = model.physicsModel.settables.getSettingByName(loc_tsid);
					if (existing_setting) {
						PhysicsSetting.updateFromAnonymous(setting, existing_setting);
					} else {
						model.physicsModel.settables.addSetting(PhysicsSetting.fromAnonymous(setting, loc_tsid));
					}
					
					payload.location.physics = null;
					
				} else {
					// see if we have a normal setting to use, and clone it for the loc if we do
					var normal:PhysicsSetting = model.physicsModel.settables.getSettingByName('normal');
					if (normal) {
						var clone:PhysicsSetting = normal.clone();
						clone.name = loc_tsid;
						model.physicsModel.settables.addSetting(clone);
					} else {
						BootError.addErrorMsg('CANNOT PROCEED WITHOUT PHYSICS', null, ['net']);
						disconnect('Missing physics!');
						return;
					}
				}
				
				if ('physics' in payload.location) delete payload.location.physics;
				
				// always overwrite anything existing for now
				world.location = world.locations[loc_tsid] = Location.fromAnonymous(payload.location, loc_tsid);
				delete payload.location;
				
				CONFIG::locodeco {
					// revert editing state of LD
					world.location_undoA.length = 0;
					model.stateModel.editing_unsaved = false;
				}
				
				if (!LoginTool.reportStep(15, 'nc_move_start_2')) return;
				TSFrontController.instance.locationHasChanged();
				model.moveModel.to_tsid = world.location.tsid;
				
				// note that we set moving = true in actuallyStartLocationMove (because it is used by various
				// parts of the code to keep things fomr happening while we move) but only triggered here
				// in locationMoveStartHandler, because that is when we want all the function registered
				// for this prop to fire. Note that if a move turns out to be in location, we never fire
				// TSFrontController.instance.moveHasStarted or TSFrontController.instance.moveHasEnded
				TSFrontController.instance.moveHasStarted();
				if (world.location.home_type) {
					NewxpLogger.log('move_starting_home_'+world.location.home_type, world.location.newxp_log_string);
				} else if (world.location.instance_template_tsid && model.stateModel.newxp_location_keys[world.location.instance_template_tsid]) {
					NewxpLogger.log('move_starting_'+model.stateModel.newxp_location_keys[world.location.instance_template_tsid], world.location.newxp_log_string);
				} else {
					NewxpLogger.log('move_starting', world.location.newxp_log_string);
				}

			
			} else if (payload.hostport && payload.token){ // this is possible with signpost, door, teleport, follow moves
				
				CONFIG::god {
					model.activityModel.growl_message = 'ADMIN: This move requires a new GS: '+payload.hostport;
					model.activityModel.activity_message = Activity.fromAnonymous({txt: 'ADMIN: This move requires a new GS: '+payload.hostport});
				}
				Benchmark.addCheck('move requires a new GS: '+payload.hostport);
				
				var dest:Object;
				if (payload.destination && payload.destination.street_tsid) {
					dest = payload.destination;
					Location.fromAnonymousLocationStub(dest);
				}
				
				// we must relogin to a new GS to do this move
				
				switch (im.type) {
					case MessageTypes.TELEPORT_MOVE_START:
						TSFrontController.instance.startLocationMove(
							true,
							MoveModel.TELEPORT_MOVE,
							world.pc.location.tsid,
							(dest && dest.street_tsid) ? dest.street_tsid : '', // where to get the to_tsid value from??
							'',
							payload.hostport,
							payload.token
						);
						
						//check if this is because of an upgrade
						if(payload.change_type && payload.change_type == 'upgrade'){
							StreetUpgradeView.instance.show(payload);
						}
						break;
					
					case MessageTypes.FOLLOW_MOVE_START:
						TSFrontController.instance.startLocationMove(
							true,
							MoveModel.FOLLOW_MOVE,
							world.pc.location.tsid,
							(dest && dest.street_tsid) ? dest.street_tsid : '', // where to get the to_tsid value from??
							'',
							payload.hostport,
							payload.token
						);
						break;
					
					case MessageTypes.SIGNPOST_MOVE_START:
						TSFrontController.instance.startLocationMove(
							true,
							MoveModel.SIGNPOST_MOVE,
							model.moveModel.from_tsid,
							model.moveModel.to_tsid,
							model.moveModel.signpost_index,
							payload.hostport,
							payload.token
						);
						break;
					
					case MessageTypes.DOOR_MOVE_START:
						TSFrontController.instance.startLocationMove(
							true,
							MoveModel.DOOR_MOVE,
							model.moveModel.from_tsid,
							model.moveModel.to_tsid,
							'',
							payload.hostport,
							payload.token,
							delay_loading_screen_ms
						);
						break;
					
					default:
						CONFIG::debugging {
							Console.warn("unhandled message type with hostport + token:"+im.type);
						}
						break;
				}
				
				// this used to be before the call to TSFrontController.instance.startLocationMove, now it is after (because otherwise moving was still false). 
				TSFrontController.instance.moveHasStarted();
				
				NewxpLogger.log('relogin_starting', im.type+' '+model.moveModel.to_tsid+' '+payload.hostport);
				
			} else {
				var rm:NetResponseMessageVO;
				if (im.type == MessageTypes.DOOR_MOVE_START || im.type == MessageTypes.SIGNPOST_MOVE_START) {
					rm = NetResponseMessageVO(im);
					if (!rm.success) {
						CONFIG::debugging {
							Console.info(im.type+' FAIL');
						}
						
						// I AM NOT SURE THIS IS GOOD ENOUGH! I probably need to not actually call
						// startLocationMove() until we get the response to the move_start, but since I'm now
						// calling it when we're sending the move_start, I need to catch this case and bail on the move here.
						
						model.moveModel.move_failed = true;
						Benchmark.addCheck('NC.locationMoveStartHandler: '+im.type+' got a FAIL rsp');
						moveHasEnded('move_failed');
						return;
					}
				}

				CONFIG::debugging {
					Console.error('*_start with no location and no hostport+token');
				}
			}
		}
		
		internal function moveHasEnded(kind:String):void {
			
			model.moveModel.moving = false;
			
			// Note that if a move turns out to be in location, we never fire
			// TSFrontController.instance.moveHasStarted or TSFrontController.instance.moveHasended
			if (model.moveModel.move_was_in_location) {
				TSFrontController.instance.getOffLadder();
				
				// because we do not call TSFrontController.instance.moveHasStarted in this case,
				// we must do the following otherwise when a locked door teleports you within the location,
				// the "moving to" overlay stops while you are still "moving" per the move model,
				// because we pause things to play the door animations nd so TSMainviw does not start up avatar as needed
				if (model.stateModel.focused_component is TSMainView) {
					TSFrontController.instance.startAvatar('NC.moveHasEnded 1');
				} else if (!model.stateModel.focused_component.stops_avatar_on_focus) {
					TSFrontController.instance.startAvatar('NC.moveHasEnded 2');
					TSFrontController.instance.stopAvatarKeyControl('NC TSMainView not focused');
				}
				
				// this causes no panning at all when moving between locations
				//CameraMan.instance.resetCameraCenterAverages();
				
				CameraMan.instance.letCameraSnapBackFast();
				
			} else {
				TSFrontController.instance.moveHasEnded();
			}
			
			Benchmark.addSectionTime(Benchmark.SECTION_MOVE_STARTING);
			Benchmark.startSection(Benchmark.SECTION_MOVE_OVER);
			Benchmark.addCheck('moveHasEnded kind:'+kind)
			/*
			CONFIG::debugging {
				var loc:Location = world.location;
				var txt:String = '';
				var total_decos:int;
				for (var i:int=0;i<loc.layers.length;i++) {
					txt+='\nlayer '+loc.layers[i].name+' decos:'+loc.layers[i].decos.length;
					total_decos+= loc.layers[i].decos.length;
				}
				txt = 'ADMIN DECO REPORT:\n'+loc.label+'\ntsid: '+loc.tsid+'\ntotal decos:'+total_decos+txt;
				model.activityModel.activity_message = Activity.fromAnonymous({txt:txt});
			}
			*/	
			CONFIG::locodeco {
				// important to call this here, since moving is now false (and complete)
				LocoDecoSWFBridge.instance.loadCurrentLocationModel();
				if (model.flashVarModel.edit_loc) {
					// prevent the editor from popping up on subsequent location changes
					model.flashVarModel.edit_loc = false;
					TSFrontController.instance.startEditMode();
				}
			}
			
			var ambient_wait_ms:int = 1000;
			if (is_first_move){
				is_first_move = false;
				ambient_wait_ms = 3000;
				RightSideManager.instance.right_view.rejoin();
				
				NewxpLogger.log('login_done');
				
				// only report loading times for non admin builds
				if (com.tinyspeck.bootstrap.Version.revision != 'incremental' && !CONFIG::god && !CONFIG::locodeco) {
					JS_interface.instance.call_JS({
						meth: 'login_done',
						params: null
					})
				}
			} else {
				//if this was a door was not in the same location as the door was opened, play the close sound
				if(model.moveModel.move_was_in_location && kind != 'move_failed' && model.moveModel.move_type == MoveModel.DOOR_MOVE){
					StageBeacon.setTimeout(SoundMaster.instance.playSound, 600, 'DOOR_CLOSE');
				}
			}
			
			// do the ambient stuff
			if (world.location.no_ambient_music){
				SoundMaster.instance.ambientStop();
			} else {
				if (world.ambient_hub_map[world.location.mapInfo.hub_id]) {
					SoundMaster.instance.changeAmbientSet(world.ambient_hub_map[world.location.mapInfo.hub_id], ambient_wait_ms);
				} else {
					SoundMaster.instance.changeAmbientSet('default', ambient_wait_ms);
				}
			}
		}
		
		// we handle all msgs of type login_start with this
		public function doLoginStartHandlerAfterLoading():void {
			if (!LoginTool.reportStep(12, 'nc_handling_login_start_1')) return;
			Benchmark.addCheck('NC doLoginStartHandlerAfterLoading');
			loginStartHandler(remembered_login_start_im);
			remembered_login_start_im = null;
		}
		
		private var attribute_logger:Object;
		private var info_logger:Object;
		private var subclasses_logger:Object;
		private var routing_logger:Object;
		
		// we handle all msgs of type login_start with this
		private function loginStartHandler(im:NetIncomingMessageVO):void {
			if (!LoginTool.reportStep(13, 'nc_handling_login_start_2')) return;
			Benchmark.addCheck('NC.loginStartHandler');
			
			var payload:Object = im.payload;
			var world:WorldModel = world;
			var i:int;
			var k:String;
			var m:String;
			var pc:Object;
			var itemstacks:Object;
			
			//set the loading info in the move model -- might be too early, needs some testing
			if(payload && payload.loading_info){
				
				//if there are any PCs in the leaderboard, let's handle them!
				if(payload.loading_info.upgrade_details && payload.loading_info.upgrade_details.leaderboard){
					handlePCsInOrderedHash(payload.loading_info.upgrade_details.leaderboard);
				}
				
				model.moveModel.loading_info = LoadingInfo.fromAnonymous(payload.loading_info, im.type);
				delete payload.loading_info;
			}
			
			if (payload.skill_urls) {
				world.skill_urls = payload.skill_urls;
				delete payload.skill_urls;
			}
			
			if (payload.prefs) {
				model.prefsModel.updateFromAnonymous(payload.prefs);
				delete payload.prefs;
			}
			
			var key:String
			if (payload.overlay_urls) {
				model.stateModel.overlay_urls = payload.overlay_urls;
				model.stateModel.overlay_keys = {};
				delete payload.overlay_urls;
				
				for (key in model.stateModel.overlay_urls) {
					model.stateModel.overlay_keys[model.stateModel.overlay_urls[key]] = key;
				}
			}
			
			if (payload.hi_emote_data) {
				var hi_emote_data:Object = payload.hi_emote_data;
				
				if (hi_emote_data.hi_emote_variants) {
					world.hi_emote_variants = hi_emote_data.hi_emote_variants;
				}
				
				if (hi_emote_data.hi_emote_variants_color_map) {
					world.hi_emote_variants_color_map = hi_emote_data.hi_emote_variants_color_map;
				}
				
				if (hi_emote_data.hi_emote_variants_name_map) {
					world.hi_emote_variants_name_map = hi_emote_data.hi_emote_variants_name_map;
				}
				
				if (hi_emote_data.yesterdays_variant_winner) {
					world.yesterdays_hi_emote_variant_winner = hi_emote_data.yesterdays_variant_winner;
				}
				
				if (hi_emote_data.yesterdays_variant_winner_count) {
					world.yesterdays_hi_emote_variant_winner_count = hi_emote_data.yesterdays_variant_winner_count;
				}
				
				if (hi_emote_data.hi_emote_leaderboard) {
					world.hi_emote_leaderboard = hi_emote_data.hi_emote_leaderboard; // fires a signal when set
				}
				
				if (hi_emote_data.yesterdays_top_infector_pc) {
					world.upsertPc(hi_emote_data.yesterdays_top_infector_pc);
				}

				if (hi_emote_data.yesterdays_top_infector_tsid) {
					world.yesterdays_hi_emote_top_infector_tsid = hi_emote_data.yesterdays_top_infector_tsid;
				}
				
				if (hi_emote_data.yesterdays_top_infector_count) {
					world.yesterdays_hi_emote_top_infector_count = hi_emote_data.yesterdays_top_infector_count;
				}
				
				if (hi_emote_data.yesterdays_top_infector_variant) {
					world.yesterdays_hi_emote_top_infector_variant = hi_emote_data.yesterdays_top_infector_variant;
				}
				
				

				CONFIG::debugging {
					Console.dir(payload.hi_emote_data);
				}
				
				delete payload.hi_emote_data;
			}
			
			
			
			if (payload.newxp_locations) {
				model.stateModel.newxp_location_tsids = payload.newxp_locations;
				model.stateModel.newxp_location_keys = {};
				delete payload.newxp_locations;
				
				for (key in model.stateModel.newxp_location_tsids) {
					model.stateModel.newxp_location_keys[model.stateModel.newxp_location_tsids[key]] = key;
				}
			}
			
			if (payload.sounds_file) {
				model.flashVarModel.sounds_file = payload.sounds_file;
				delete payload.sounds_file;
			}
			SoundMaster.instance.init();
				
			if (payload.items){
				CONFIG::god {
					var b:ByteArray = new ByteArray();
					b.writeObject(payload.items);
					Console.info(" payload.items byte length: " + b.length);
				}
				
				if (!payload.default_item_values) {
					CONFIG::debugging {
						Console.error('NO DEFAULT VALUES?');
					}
					return;
				} else {
					;
					CONFIG::debugging {
						Console.info('default_item_values:');
						Console.dir(payload.default_item_values);
					}
				}
				
				function doItem(k:String):void {
					if (world.items[k]) {
						return;	
					}
					
					var item_ob:Object = payload.items[k];
					
					// a little report to see how many non default values are being sent
					CONFIG::god {
						for (var att:String in item_ob) {
							var val:* = item_ob[att];
							if (!(val is int || val is Number || val is Boolean)) continue;
							if (!attribute_logger) attribute_logger = {};
							var att_ob:Object = attribute_logger[att];
							if (!att_ob) att_ob = attribute_logger[att] = {};
							if (!(val in att_ob)) att_ob[val] = 0;
							att_ob[val]++;
						}
					}
					
					// go over and set the default values for each incoming object before we fromAnonymous it
					if (payload.default_item_values) {
						var log_class:String = 'appleeeeeee';
						for (var def:String in payload.default_item_values) {
							if ((def in item_ob)) {
								;
								CONFIG::god {
									if (k == log_class) {
										Console.info(k+' used specified value for '+def+':'+item_ob[def])
									}
								}
							} else {
								item_ob[def] = payload.default_item_values[def];
								CONFIG::god {
									if (k == log_class) {
										Console.warn(k+' set default value '+def+':'+item_ob[def])
									}
								}
								
							}
						}
					}
					
					// now each in coming object has default values set
					var item:Item = world.items[k] = Item.fromAnonymous(item_ob, k);
					
					CONFIG::god {
						if (false && item.has_info != item.has_infopage) {
							if (!info_logger) info_logger = {};
							info_logger[item.tsid] = 'has_info:'+item.has_info+' has_infopage:'+item.has_infopage;
						}
						
						if (item.subclasses) {
							if (!subclasses_logger) subclasses_logger = {};
							subclasses_logger[item.tsid] = item.subclasses;
						}
						
						if (item.is_routable) {
							if (!routing_logger) routing_logger = {};
							routing_logger[item.tsid] = item.subclasses || item.proxy_item || item.tsid;
						}
					}
				}
				
				// we want to do this first, to make sure that the subclasses for street spririts are extended from street_spirit_groddle
				// because street_spirit_groddle has the proper iconic state for get info dialogs
				if (payload.items['street_spirit_groddle']) {
					doItem('street_spirit_groddle');
					delete payload.items['street_spirit_groddle'];
				}
				
				for (k in payload.items) {
					doItem(k);
				}
				
				CONFIG::god {
					Console.info('attribute_logger');
					Console.dir(attribute_logger);
					if (info_logger) {
						Console.info('info_logger');
						Console.dir(info_logger);
					}
					if (routing_logger) {
						Console.info('routing_logger');
						Console.dir(routing_logger);
					}
					if (subclasses_logger) {
						Console.info('subclasses_logger');
						Console.dir(subclasses_logger);
					}
				}
				
				delete payload.items;
				delete payload.default_item_values;
			} else {
				BootError.handleError('login_start with no items', new Error('Bad login_start'), ['net'], false);
				return; // fatal
			}
			
			if (payload.invoking) {
				world.invoking = payload.invoking;
				delete payload.invoking;
			} else {
				//BootError.handleError('login_start with no invoking', new Error('Bad login_start'), false);
				//return; // fatal
			}
			
			if (payload.userdeco) {
				world.userdeco = payload.userdeco;
				delete payload.userdeco;
			} else {
				//BootError.handleError('login_start with no userdeco', new Error('Bad login_start'), false);
				//return; // fatal
			}
			
			if (payload.pc){
				world.pc = PC.fromAnonymous(payload.pc, payload.pc.tsid, true);
				world.pc.apo.is_self = true;
				CONFIG::debugging {
					Console.setPcLabel(world.pc.label);
				}
				world.pc.online = true;
				world.pcs[world.pc.tsid] = world.pc;
				
				if (payload.pc.itemstacks){
					itemstacks = payload.pc.itemstacks;
					for (k in itemstacks) {
						if (!world.items[itemstacks[k].class_tsid]) {
							CONFIG::debugging {
								Console.error(k+' ('+itemstacks[k].label+') has unknown class:'+itemstacks[k].class_tsid);
							}
							continue;
						}
						
						if (world.getItemstackByTsid(k)) {
							world.itemstacks[k] = Itemstack.updateFromAnonymous(itemstacks[k], world.getItemstackByTsid(k));
						} else {
							if (!Item.confirmValidClass(itemstacks[k].class_tsid, k)) {
								continue;
							}
							world.itemstacks[k] = Itemstack.fromAnonymous(itemstacks[k], k);
						}
						world.pc.itemstack_tsid_list[k] = k;
					}
					delete payload.pc.itemstacks;
				}
				
				
				delete payload.pc;
			} else {
				BootError.handleError('login_start with no pc', new Error('Bad login_start'), ['net'], false);
				return; // fatal
			}
			
			if (payload.location){
				locationMoveStartHandler(im);
			} else {
				BootError.handleError('login_start with no location', new Error('Bad login_start'), ['net'], false);
				return; // fatal
			}
			
			if (payload.familiar) {
				world.pc.familiar = PCFamiliar.fromAnonymous(payload.familiar);
				delete payload.familiar;
			} else {
				CONFIG::debugging {
					Console.error('missing familiar section on login_start');
				}
				world.pc.familiar = new PCFamiliar();
			}
			CONFIG::debugging {
				Console.trackValue('PC fam msgs', world.pc.familiar.messages);
			}
			
			if (payload.groups) {
				for (k in payload.groups) {
					payload.groups[k].is_member = true;
					world.groups[k] = Group.fromAnonymous(payload.groups[k], k);
				}
				delete payload.groups;
			}
			
			//add the global chat channel to the list of groups			
			if(payload.global_chat_group){
				RightSideManager.instance.global_chat_tsid = payload.global_chat_group;
				
				delete payload.global_chat_group;
			}
			
			//add the live help channel to the list of groups
			if(payload.live_help_group){
				RightSideManager.instance.live_help_tsid = payload.live_help_group;
				
				delete payload.live_help_group;
			}
			
			//add the updates to the list of groups
			const updates_group:Group = new Group(ChatArea.NAME_UPDATE_FEED);
			updates_group.tsid = ChatArea.NAME_UPDATE_FEED;
			updates_group.label = 'Updates';
			world.groups[ChatArea.NAME_UPDATE_FEED] = updates_group;
			
			//add the trade channel to the list of groups
			if(payload.trade_chat_group){
				RightSideManager.instance.trade_chat_tsid = payload.trade_chat_group;
				
				delete payload.trade_chat_group;
			}
			
			if ((!payload.prompts || payload.prompts.length == 0) && model.flashVarModel.fake_prompts) {
				payload.prompts = [{
					uid: 'aa',
					timeout: 400,
					txt: 'We don\'t think you should be burdened with managing messages you don\'t want to receive.',
					icon_buttons: true,
					timeout_value: 'DID TIMEOUT',
					choices: [{
						value: 'yes',
						label: 'Yes'
					}, {
						value: 'no',
						label: 'No'
					}]
				}, {
					uid: 'bb',
					timeout: 400,
					txt: 'Gary is a wanker, innit?',
					icon_buttons: false,
				//	is_modal: true,
					escape_value:'fucj',
					choices: [{
						value: 'yes',
						label: 'Yes'
					}, {
						value: 'no',
						label: 'No'
					}]
				}, {
					uid: 'cc',
					timeout: 300,
					txt: 'Gene knocked on your door, can he enter your house?',
					icon_buttons: true,
					timeout_value: 'DID TIMEOUT',
					choices: [{
						value: 'yes',
						label: 'Yes'
					}, {
						value: 'no',
						label: 'No'
					}]
				}]
			}
			
			if (payload.prompts) {
				for (i=0;i<payload.prompts.length;i++) {
					model.activityModel.addPrompt(Prompt.fromAnonymous(payload.prompts[int(i)]));
				}
				delete payload.prompts;
			}
			
			if (payload.camera_abilities) {
				updatePCCameraCapabilities(payload.camera_abilities);
				delete payload.camera_abilities;
			}
			
			if (payload.buffs){
				var buff:PCBuff;
				var buff_tsidA:Array = [];
				for (k in payload.buffs) {
					//set the remaining duration to be the total duration
					if(!('remaining_duration' in payload.buffs[k]) && 'duration' in payload.buffs[k]) {
						payload.buffs[k].remaining_duration = Math.floor(payload.buffs[k].duration);
					}
					
					if (k in world.pc.buffs) {
						buff = world.pc.buffs[k] = PCBuff.updateFromAnonymous(payload.buffs[k], world.pc.buffs[k]);
					} else {
						buff = world.pc.buffs[k] = PCBuff.fromAnonymous(payload.buffs[k], k);
					}
					buff_tsidA.push(k);
				}
				world.buff_adds = buff_tsidA;
				delete payload.buffs;
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.error('missing buffs section on login_start');
				}
			}
			
			if (payload.path_info && payload.path_info.path){
				model.stateModel.current_path = MapPathInfo.fromAnonymous(payload.path_info);
				
				if (payload.path_info.path is Array && payload.path_info.path.length > 1) {
					if (payload.path_info.destination) {
						Location.fromAnonymousLocationStub(payload.path_info.destination);
					}
					
					model.stateModel.loc_pathA = payload.path_info.path;
				} 
			}
			
			if('acl_key_count' in payload) {
				//do they have any keys to other locations?
				ACLManager.instance.key_count += payload.acl_key_count;
				delete payload.acl_key_count;
			}
			
			if ('pol_info' in payload) {
				handlePOLInfo(payload.pol_info);
				delete payload.pol_info;
			}
			
			if ('home_info' in payload){
				handleHomeInfo(payload.home_info);
				delete payload.home_info;
			}
				
			if (payload.buddies){
				handleBuddies(payload.buddies);
				delete payload.buddies;
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.error('login_start with no buddies');
				}
			}
			
			// this needs to be after we set worldModel.pc and world.pc.familiar , because Quest.fromAnonymous requires it 
			if (payload.quests){
				world.quests = Quest.parseMultiple(payload.quests); // calls a trigger when set
				delete payload.quests;
			}
			
			if (payload.party){
				handleBeingInAParty(payload.party);
				delete payload.party;
			}
			
			if(payload.ambient_library){
				SoundMaster.instance.ambient_library = payload.ambient_library;
				delete payload.ambient_library;
			}
			
			if(payload.ambient_hub_map){
				world.ambient_hub_map = payload.ambient_hub_map;
				delete payload.ambient_hub_map;
			}
			
			if(payload.ignoring){
				handleIgnoredPCs(payload.ignoring, true);
				delete payload.ignoring;
			}
			
			if(payload.ignored_by){
				// I guess we are supposed to do somethign with this?
				delete payload.ignored_by;
			}
			
			if (payload.recipes){
				world.recipes = Recipe.parseMultiple(payload.recipes);
				delete payload.recipes;
			}
	
			CONFIG::debugging {
				for(var j:String in payload){
					Console.warn("Not parsing yet: "+ j +' '+ payload[j]);
				}
				logTsidLists();
			}
			
			CONFIG::god {
				if (im.type == MessageTypes.LOGIN_START) {
					if (LocalStorage.instance.getUserData(LocalStorage.IS_OPEN_ADMIN_DIALOG)) {
						AdminDialog.instance.start();
					}
				}
			}
			
			if (world.pc.y == 0 && world.pc.x == 0) {
				BootError.handleError('Player at 0,0', new Error('Bad coords in login_start'), ['net'], true);
			}
			
			Benchmark.addCheck('NC.loginStartHandler finished');
			Benchmark.addSectionTime(Benchmark.SECTION_MOVE_STARTING);
		}
		
		private function handleBuddies(buddies:Object):void {
			var buddy_group:Object;
			var pc:PC;
			var k:String;
			var m:String;
			
			for (k in buddies) {
				buddy_group = buddies[k];
				// TODO: add buddy buddy_groups
				if (buddy_group.pcs) {
					for (m in buddy_group.pcs) {
						world.upsertPc(buddy_group.pcs[m]);
						
						//toss this buddy in the model
						world.pc.buddy_tsid_list[m] = m;
					}
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.error('buddy_group with no pcs');
					}
				}
			}
		}
		
		internal function handleBeingInAParty(party:Object):void {
			if (world.party) {
				CONFIG::debugging {
					Console.error('CANT JOIN PARTY, ALREADY IN PARTY');
				}
				return;
			}
			
			// get all members in the model and updated
			if (party.members) {
				for (var k:String in party.members) {
					party.members[k].tsid = k;
					world.upsertPc(party.members[k]);
				}
			}
			
			world.party = PCParty.fromAnonymous(party, world.pc.tsid);// calls a trigger when set
		}
		
		internal function handlePCsInOrderedHash(payload:Object):void {
			if (!payload) return;
			var count:int;
			
			while(payload[count] && payload[count].pc){
				world.upsertPc(payload[count].pc);
				count++;
			}
		}

		internal function handleRecipesFromMake(recipes:Object, is_knowns:Boolean):void {
			//update the world if we got a new recipe
			var k:String;
			var recipe:Recipe;
			var id:String;
			var is_recipe:Boolean;
			var needs_resort:Boolean;
			
			for(k in recipes){
				if(is_knowns){
					id = k;
					is_recipe = true;
				}
				else if(k.indexOf('recipe_') >= 0){
					id = k.substr(7);
					is_recipe = true;
				}
				//if using the data from "effects" it also contains the rewards
				else {
					is_recipe = false;
				}
				
				if(is_recipe){
					recipe = world.getRecipeById(id);
					if(!recipe){
						recipe = Recipe.fromAnonymous(recipes[k], id);
					}
					else {
						//update the world
						var index:int = world.recipes.indexOf(recipe);
						world.recipes.splice(index, 1);
						recipe = Recipe.updateFromAnonymous(recipes[k], recipe);
					}
					
					//do we need to add it to our current knowns?
					if(recipe.tool == MakingManager.instance.making_info.item_class && !MakingManager.instance.isRecipeInKnowns(recipe.id)){
						MakingManager.instance.making_info.knowns.push(recipe);
						needs_resort = true;
					}
					
					//put it in the world
					world.recipes.push(recipe);
				}
			}
			
			//sort the knowns alpha styles
			if(needs_resort) SortTools.vectorSortOn( MakingManager.instance.making_info.knowns, ['name'], [Array.CASEINSENSITIVE]);
			
			//refresh it
			MakingDialog.instance.onPackChange();
		}
		
		private function handleIgnoredPCs(pcs:Object, is_ignored:Boolean):void {
			//this will batch set the ignored flag in the pc's object
			var j:String;
			var pc:PC;
			
			for(j in pcs){
				if(pcs[j] && 'tsid' in pcs[j]){
					world.upsertPc(pcs[j]);
					pc = world.getPCByTsid(pcs[j].tsid);
					pc.ignored = is_ignored;
				}
			}
		}
		
		CONFIG::god public function testUnexpectedDisconnect():void {
			_netDelegate.disconnect();
		}
		
		/**
		 * TODO : Clean up nicely here. Lo prio.
		 */
		public function dispose():void {
			_netDelegate.disconnect();
		}
	}
}