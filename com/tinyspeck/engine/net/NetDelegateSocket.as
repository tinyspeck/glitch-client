package com.tinyspeck.engine.net
{
	import com.adobe.serialization.json.JSON;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.memory.DisposableEventDispatcher;
	import com.tinyspeck.core.memory.DisposableSocket;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.control.engine.AnnouncementController;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.util.ObjectUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.vo.ServerTimeVO;
	
	import flash.errors.EOFError;
	import flash.errors.IOError;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.ObjectEncoding;
	import flash.system.Security;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;
	
	CONFIG::debugging { import com.tinyspeck.engine.model.Counts; }

	public class NetDelegateSocket extends DisposableEventDispatcher implements INetDelegate
	{
		private const messageQueue:Vector.<Object> = new Vector.<Object>();
		private const sendObject:Object = new Object();
		
		private const netSocket:DisposableSocket = new DisposableSocket();
		/** NaN when waiting for a value, otherwise represents a read value */
		private var expectedMessageSize:Number = NaN;
		
		private var pingTimer:Timer;
		private var pingObject:Object;
		private var pingSentTime:int;
		private var host:String;
		private var port:int;
		private var token:String;
		
		private var model:TSModelLocator;
		private var responder:INetResponder;
		
		private var total_rsp_ms:int     = 0;
		private var longest_rsp_ms:int   = 0;
		private var shortest_rsp_ms:int  = 0;
		private var connection_tries:int = 0;
		private var ping_tries:int       = 0;
		
		public function NetDelegateSocket(responder:INetResponder, model:TSModelLocator) {
			super(null);
			this.model = model;
			this.responder = responder;
			
			netSocket.objectEncoding = ObjectEncoding.AMF3;
			netSocket.timeout = 10000;
			
			LocalStorage.instance.removeLogStorage();
			
			Benchmark.addOutstandingMsgsCallback(getOutstandingMessages);
		}
		
		private function getOutstandingMessages():String {
			var str:String = '';
			if (!sentMessages) return str;
			
			var nom:NetOutgoingMessageVO;
			for (var k:Object in sentMessages) {
				nom = sentMessages[k];
				str += nom.type+' msg_id:'+nom.msg_id+' has no rsp, '+((getTimer()-nom.time_sent)/1000).toFixed(2)+' secs after sent\r';
			}
			
			if (!str) str = 'NONE';
			return str;
		}
		
		public function connect(host:String,port:int,token:String):void {
			connection_tries++;
			CONFIG::debugging {
				Console.info('connecting to host:'+host+' port:'+port+' token:'+token);
			}
			BootError.most_recent_gs = host+':'+port;
			Benchmark.addCheck('connecting to host:'+host+' port:'+port+' token:'+token);
			netSocket.addEventListener(Event.CONNECT, onSocketConnect);
			netSocket.addEventListener(Event.CLOSE, onSocketClose, false, 1);
			netSocket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
			netSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSocketError);
			netSocket.addEventListener(IOErrorEvent.IO_ERROR, onSocketError);
			
			// preload the socket policy file
			try {
				Security.loadPolicyFile('xmlsocket://' + host + ':843');
				Benchmark.addCheck('socket policy loaded');
			} catch (e:Error) {
				Benchmark.addCheck('socket policy error');
				BootError.handleError('socket policy error', e, ['bootstrap'], true, false);
			}
			
			this.token = token;
			this.host = host;
			this.port = port;
			netSocket.connect(host, port);
		}
		
		private function tryToConnectAgain():void {
			connect(host, port, token);
		}
		
		private function onSocketError(event:ErrorEvent):void {
			CONFIG::debugging {
				Console.error("Socket Error");
				Console.info(event);
			}
			
			if (!pingTimer) {
				setUpPingTimer();
			}
			
			if (connection_tries >= 3) {
				pingTimer.stop();
				
				CONFIG::debugging {
					Console.info('giving up after '+connection_tries+' tries.');
				}
				
				// get rid of the Moving to... dialog first, in case it's up
				AnnouncementController.instance.cancelOverlay('moving_client_msg');
				
				TSFrontController.instance.maybeReload(
					'I\'m unable to connect to the game server. I tried '+connection_tries+' times',
					'I\'m still unable to connect to the game server. I tried '+connection_tries+' more times',
					true
				);
			} else {
				CONFIG::debugging {
					Console.info('trying to connect again');
				}
				
				pingTimer.reset();
				
				try {
					netSocket.close();
				} catch (ioe:IOError) {
					// s'okay
				}
				
				StageBeacon.setTimeout(function():void {
					pingTimer.start();
					tryToConnectAgain();
				}, 1000);
			}
		}
		
		public function disconnect():void {
			CONFIG::debugging {
				Console.info('disconnecting now, currently connected:'+netSocket.connected);
			}
			if (netSocket.connected){
				netSocket.close();
				closeErUp();
			}
		}
		
		private function onSocketConnect(event:Event):void {
			CONFIG::debugging {
				Console.info('connected!');
			}
			connection_tries = 0;
			ping_tries = 0;
			responder.connectHandler();
			
			if (!pingTimer) {
				setUpPingTimer();
			}
			
			if (!handled_first_ping) {
				// now we init TimManager and send the first ping, so we can extract the time
				// from the message and set relative time. see handlePingMessage also.
				TSFrontController.instance.initTimeController();
				sendPing();
			}
		}
		
		private function setUpPingTimer():void {
			if (pingTimer) return;
			
			pingObject = {type:MessageTypes.PING, tsid:model.flashVarModel.pc_tsid};
			pingTimer = new Timer(10000, 0);
			pingTimer.addEventListener(TimerEvent.TIMER, onPingTimer);
			pingTimer.start();
		}
		
		private function onPingTimer(event:TimerEvent):void {
			sendPing();
		}
		
		public function sendPing():void {
			if (model.netModel.loggedIn) {
				++ping_tries;
				if (ping_tries == 1) {
					pingSentTime = getTimer();
					sendAnonymousObjectRequest(pingObject);
				} else if (ping_tries == 2) {
					Benchmark.addCheck('still waiting for ping...');
					pingSentTime = getTimer();
					sendAnonymousObjectRequest(pingObject);
					//tryToConnectAgain();
				} else if (ping_tries == 3) {
					Benchmark.addCheck('ping failed, connection very over');
					//disconnect();
					// get rid of the Moving to... dialog first, in case it's up
					AnnouncementController.instance.cancelOverlay('moving_client_msg');
					TSFrontController.instance.maybeReload(
						'I haven\'t heard from the game server for a long while',
						'I\'m still having having trouble hearing from the game server',
						true
					);
				} else {
					// we're done here
				}
			}
		}
		
		// If you close your laptop, then reopen it much later, this is the event that fires.
		// It seems to get fired AFTER a disconnect, when your network connection is reestablished, not when it breaks
		private function onSocketClose(event:Event):void {
			closeErUp();
		}
		
		private function closeErUp():void {
			//Console.info('closed')
			netSocket.removeAllEventListeners(); // do this first, because responder.disconnectHandler might try to reconnect us!
			responder.disconnectHandler();
		}
		
		private function onSocketData(event:ProgressEvent):void {
			//Stats.reportPing(getTimer() - model.netModel.last_activity);
			model.netModel.last_activity = getTimer();
			while (checkIncomingData()) {}
		}
		
		public function socketReport():String {
			return 'Socket[connected:' + netSocket.connected + ', ' +
				'expectedMessageSize:' + expectedMessageSize + 'b, ' +
				'bytesAvailable:' + (netSocket.connected ? netSocket.bytesAvailable : 0) + 'b, ' +
				'last_rcvd_message: [' + StringUtil.getJsonStr(model.netModel.last_rcvd_message) + '], ' +
				'last_sent_message: [' + StringUtil.getJsonStr(model.netModel.last_sent_message) + ']]';
		}
		
		/** Returns whether there is more incoming data available */
		private function checkIncomingData():Boolean {
			if (!netSocket.connected) return false;
			
			// if we have not received the header yet
			if (isNaN(expectedMessageSize)) {
				// not enough data for the header
				if (netSocket.bytesAvailable < 4) return false;
				
				// read the header
				try {
					expectedMessageSize = netSocket.readInt();
				} catch (eof:EOFError) {
					reportSocketError('netSocket.readInt() threw EOFError');
					return false;
				} catch (ioe:IOError) {
					reportSocketError('netSocket.readInt() threw IOError');
					return false;
				} catch (e:Error) {
					reportSocketError('netSocket.readInt() threw an Error(' + e + ')');
					return false;
				}
				
				// if a header of zero length, pass
				if (expectedMessageSize == 0) {
					// this shouldn't happen
					reportSocketError('netSocket.readInt() returned a header of zero bytes');
					// reset header length as next four bytes should be a header
					expectedMessageSize = NaN;
					return false;
				}
			}
			
			if (isNaN(expectedMessageSize) || netSocket.bytesAvailable < expectedMessageSize) return false;
			var this_bytes_avail:uint = netSocket.bytesAvailable
			
			// read the Object
			const ob:Object = getIncomingMessage();
			
			// reset header length as next four bytes should be a header
			expectedMessageSize = NaN;
			
			if (ob && ob.type=='login_start') {
				CONFIG::god {
					Console.info('login_start bytes '+this_bytes_avail);
				}
				Benchmark.addCheck('login_start bytes '+this_bytes_avail);
			}
			
			//TODO PERF remove one day when we're satisfied that we solved the socket readObject problems
			model.netModel.last_rcvd_message = ObjectUtil.copyOb(ob);;
			// parse the Object
			if (ob) parseIncomingMessage(ob);
			
			// parseIncomingMessage() might result in the closing of the socket
			return (netSocket.connected && (netSocket.bytesAvailable > 0));
		}
		
		/** Returns an Object or null if an error occurred (already logged) */
		private function getIncomingMessage():Object {
			var ob:Object = null;
			try {
				ob = netSocket.readObject();
				if (ob == null) {
					reportSocketError('netSocket.readObject() returned null');
					return null;
				}
			} catch (eof:EOFError) {
				throw new Error();
				reportSocketError('netSocket.readObject() threw EOFError');
				return null;
			} catch (ioe:IOError) {
				reportSocketError('netSocket.readObject() threw IOError');
				return null;
			} catch (e:Error) {
				reportSocketError('netSocket.readObject() threw an Error(' + e + ')');
				return null;
			}
			
			const className:String = getQualifiedClassName(ob);
			if (className == "Object") {
				return ob;
			}
			
			if (className == null) {
				reportSocketError('getQualifiedClassName() returned null given "' + ob + '"');
				return null;
			}
			
			var inferredType:String = "Unknown";
			if (ob is String) {
				inferredType = "String";
			} else if (ob is Number) {
				inferredType = "Number";
			} else if (ob is Boolean) {
				inferredType = "Boolean";
			} else if (ob is XML) {
				inferredType = "XML";
				ob = (ob as XML).toXMLString();
			}
			
			CONFIG::debugging {
				Console.error('getQualifiedClassName() returned "' + className + '" which we inferred to be "' + inferredType + '" given "' + ob + '"');
			}
			reportSocketError('getQualifiedClassName() returned "' + className + '" which we inferred to be "' + inferredType + '" given "' + ob + '"');
			return null;
		}
		
		private function reportSocketError(problem:String):void {
			BootError.handleError(socketReport(), new Error(problem), ['socket'], true, false);
		}
		
		public function parseIncomingMessage(ob:Object, logit:Boolean=false):Boolean {
			//If there is no type, there would be something wrong with the message in general.
			if(ob && ob.type && ob.type is String){
				const t:String = ob.type as String;
				
				if (t != MessageTypes.PING && ((t != MessageTypes.PC_MOVE_XY && t != MessageTypes.PC_MOVE_VEC) || ob.changes || ob.announcements)) {
					
					var copy:Object;
					
					CONFIG::debugging {
						// make a copy
						copy = ObjectUtil.copyOb(ob);
						if (copy.items) copy.items = 'DELETED FROM LOG';
						copy.ts = StringUtil.getColonDateInGMT(new Date());
						
						model.activityModel.net_msgs.push(copy);
						if (model.activityModel.net_msgs.length > model.activityModel.net_msgs_max) {
							LocalStorage.instance.appendLogData(model.activityModel.net_msgs);
							model.activityModel.net_msgs.length = 0;
						}
					}
					
					// for move messages, just add a fake short message to net_msgs_short
					if (MessageTypes.isMoveRelatedMessageType(t)) {
						copy = {
							ts: StringUtil.getColonDateInGMT(new Date()),
							type: t,
							content: 'DELETED FROM LOG',
							success: ob.success
						}
						if (ob.msg_id) copy.msg_id = ob.msg_id;
						
						//TODO PERF
						// I think performance is fine here doing a JSON.encode on such a small object only one move messages,
						// but future enhancement could be to just manually build a string here.
						Benchmark.addCheck('recv: '+StringUtil.getJsonStr(copy));
					}
					
					if (!copy) { // if CONFIG::debugging==true or if it is a move message we'll already have a copy
						// make a copy
						copy = ObjectUtil.copyOb(ob);
						if (copy.items) copy.items = 'DELETED FROM LOG';
						copy.ts = StringUtil.getColonDateInGMT(new Date());
					}
					
					if (t == MessageTypes.SERVER_MESSAGE) {
						//TODO PERF
						// I think performance is fine here doing a JSON.encode on such a small object only one move messages,
						// but future enhancement could be to just manually build a string here.
						Benchmark.addCheck('recv: '+StringUtil.getJsonStr(copy));
					}
					
					model.activityModel.net_msgs_short.push(copy);
					if (model.activityModel.net_msgs_short.length > model.activityModel.net_msgs_short_max) {
						model.activityModel.net_msgs_short.shift();
					}
				}
				
				CONFIG::debugging {
					
					var pri:int = 2;
					if (model.flashVarModel.priority.indexOf('202') != -1) {
						pri = (ob.msg_id) ? 202 : 0;
					} 
					if (!ob.hasOwnProperty('changes') || !ob.changes.hasOwnProperty('itemstack_values') || !ob.changes.itemstack_values.hasOwnProperty('pc')) {
						switch (t) {
							case 'move_xy':
							case 'pc_move_xy':
							case 'move_vec':
							case 'pc_move_vec':
							case 'time_passes':
								pri = 9;
								break;
							case 'overlay_cancel':
							case 'overlay_state':
							case 'overlay_scale':
								if (model.flashVarModel.priority == '2') {
									pri = 2;
								} else {
									pri = 898;
								}
								break;
							case 'item_state':
								pri = 13;
								break;
							case 'itemstack_status':
								pri = 1333;
								break;
							case 'location_event':
							case 'location_item_moves':
								pri = 11;
								break;
							case MessageTypes.PING:
								pri = 12;
								break;
						}
					}
					if (pri || logit) {
						if (logit) {
							pri = 0;
							Console.warn(pri);
						}
						Console.pridir(pri, ob, model.flashVarModel.show_tree_str);
					}
				} // CONFIG::debugging
				
				//Figure out if this is a server message.	
				if(t == MessageTypes.SERVER_MESSAGE){
					parseServerMessage(ob);
					return true;
				} else if(t == MessageTypes.PING){
					handlePingMessage(ob);
					return true;
				}
				
				//Figure out if this is a response message.
				if("msg_id" in ob){
					//Console.info('handling '+ob.msg_id+' '+t);
					parseResponseMessage(ob);
					return true;
				} else {
					parseEventMessage(ob);
					return true;
				}
			}
			
			return false;
		}
		
		private function parseServerMessage(obj:Object):void {
			var nsm:NetServerMessage = new NetServerMessage();//TODO : Move to pool
			nsm.action = obj.action;
			delete obj.action;
			nsm.type = obj.type;
			delete obj.type;
			nsm.msg = obj.msg;
			delete obj.msg;
			
			CONFIG::debugging {
				trackMsgCounts(nsm.type+':'+nsm.action, 'EVT');
			}
			
			nsm.payload = obj;
			responder.netServerMessageHandler(nsm);
		}
		
		private function parseResponseMessage(obj:Object):void {
			var nrm:NetResponseMessageVO = new NetResponseMessageVO();//TODO : Move to pool
			nrm.msg_id = obj.msg_id;
			delete obj.msg_id;
			nrm.success = obj.success;
			
			delete obj.success;
			nrm.type = obj.type;
			delete obj.type;
			
			CONFIG::debugging {
				trackMsgCounts(nrm.type, 'RSP');
			}
			
			if (nrm.msg_id) {
				if (sentMessages[nrm.msg_id]) {
					nrm.request = sentMessages[nrm.msg_id];
					delete sentMessages[nrm.msg_id];
					nrm.time_recv = getTimer();
					
					var rsp_ms:int = (nrm.time_recv-nrm.request.time_sent);
					if (rsp_ms > 1000) {
						Benchmark.addCheck(nrm.type+':'+(nrm.time_recv-nrm.request.time_sent));
						CONFIG::debugging {
							Console.warn(nrm.type+' took '+(nrm.time_recv-nrm.request.time_sent)+'ms');
						}
					}
					
					CONFIG::debugging {
						StageBeacon.clearTimeout(nrm.request.sent_timeout);
						nrm.request.sent_timeout = 0;
						
						if (rsp_ms > longest_rsp_ms) {
							longest_rsp_ms = rsp_ms;
							Console.trackValue('NDS longest_rsp_ms', longest_rsp_ms);
							Console.trackValue('NDS longest_rsp_ms msg', nrm.type);
						}
						if (shortest_rsp_ms == 0 || rsp_ms < shortest_rsp_ms) {
							shortest_rsp_ms = rsp_ms;
							Console.trackValue('NDS shortest_rsp_ms', shortest_rsp_ms);
							Console.trackValue('NDS shortest_rsp_ms msg', nrm.type);
						}
						total_rsp_ms+= rsp_ms;
						Console.trackValue('NDS avg rsp ms', total_rsp_ms/Counts.net_msg_rsp_count);
					}
					
					//Console.info('deleting sentMessages item for '+nrm.msg_id);
				} else {
					Benchmark.addCheck('sentMessages lacks a request for this response:'+nrm.msg_id+' '+nrm.type);
					; // satisfy compiler
					CONFIG::debugging {
						Console.error('sentMessages lacks a request for this response:'+nrm.msg_id+' '+nrm.type);
						Console.dir(nrm);
					}
				}
			} else {
				CONFIG::debugging {
					var txt:String = nrm.type+' rsp is without a msg_id, which probably means the msg was sent to the server without a msg_id. This is bad. Fix it!';
					Console.warn(txt);
					model.activityModel.growl_message = 'ADMIN: '+txt
				}
			}
			
			nrm.payload = obj;
			responder.responseMessageHandler(nrm);
		}
		
		private function parseEventMessage(obj:Object):void {
			var nim:NetIncomingMessageVO = new NetIncomingMessageVO();
			
			nim.type = obj.type;
			delete obj.type;
			nim.payload = obj;
	
			CONFIG::debugging {
				trackMsgCounts(nim.type, 'EVT');
			}
			
			responder.eventMessageHandler(nim);
		}
		
		private var handled_first_ping:Boolean = false;
		private function handlePingMessage(obj:Object):void {
			Benchmark.addCheck('ping received');
			
			ping_tries = 0;
			pingTimer.reset();
			pingTimer.start();
			
			CONFIG::debugging {
				trackMsgCounts(obj.type, 'RSP');
			}
			
			BootError.reportPing(getTimer() - pingSentTime);
			
			// hacky, I know! but this allows TimeManager to set time relative to server time +-
			if (!handled_first_ping){
				TSFrontController.instance.startTimeController(new ServerTimeVO(obj.ts));
				handled_first_ping = true;
			}
		}
		
		private var keyArray:Array = new Array();
		private function messageToAnonymousObject(msg:NetOutgoingMessageVO, object:Object):Object {
			var log:Boolean = false; // && (msg is NetOutgoingMoveXYVO);
			
			//object.w = 'ff';
			
			//Clear the incoming object since we are most likely to reuse 1 all the time.
			//Clearing, with many messages will be cheaper then reinstanciating anon objects all the time.
			CONFIG::debugging {
				if (log) Console.dir(object)
			}
			
			keyArray.length = 0;
			for(var key:String in object){
				//if (log) Console.info('deleting:'+key)
				//object[key] = null; // for some fucking reason, this also ruins the loop. do it all in the other loop
				//delete object[key]; // this ruins the loop, duh. instead remember the keys and then delete in another loop:
				keyArray.push(key);
			}
			
			for (var m:int=0;m<keyArray.length;m++) {
				CONFIG::debugging {
					if (log) Console.info('deleting and nulling '+keyArray[m]);
				}
				object[keyArray[m]] = null;
				delete object[keyArray[m]];
			}
			
			CONFIG::debugging {
				if (log) Console.dir(object);
			}
			
			var variables:XMLList = describeType(msg)..variable;
			var l:int = variables.length();
			for(var i:int; i < l; i++){
				var varName:String = variables[int(i)].@name;
				CONFIG::debugging {
					if (log) Console.info('varName '+varName+' '+msg[varName]);
				}
				
				// surely there is a better to do this than have these properties enumerated over in the loop and manually removed:
				if (varName == 'needs_msg_id') continue;
				if (varName == 'payload') continue;
				if (varName == 'sent_timeout') continue;
				if (varName == 'time_sent') continue;
				if (varName == 'fps' && msg[varName] == 0) continue;
				
				//if (varName == 'msg_id') object.msg_id2 = msg[varName];
				
				// bail if there is no value
				if (msg[varName] === undefined) continue;
				if (msg[varName] === null) continue;
				if (msg[varName] === '') continue;
				
				object[varName] = msg[varName];
			}
			
			CONFIG::debugging {
				if (log) Console.dir(object);
			}
			
			return object;
		}
		
		private function get sentMessages():Dictionary {
			return model.netModel.sentMessages;
		}
		
		// this is for testing only
		public function addAnonRequest(msg:Object):void {
			messageQueue[int(messageQueue.length)] = msg;
		}
		
		private var session_stamp:String = getTimer().toString();
		public function addRequest(msg:NetOutgoingMessageVO):int {
			if(netSocket.connected){
				var msg_id:int;
				if(msg == null || msg.type == null){
					return -1;
				}
				
				if(msg.type == MessageTypes.LOGIN_START || msg.type == MessageTypes.RELOGIN_START){
					msg.token = token;
					msg.session_stamp = session_stamp;
				}
				
				if(msg.needs_msg_id){
					msg_id = ++NetMessageVO.MESSAGE_ID_COUNTER;
					msg.msg_id = msg_id.toString();//If this message is expected to have a response, get a global 'uid'.

					//Console.info('adding sentMessages item for '+msg.msg_id);
					sentMessages[msg.msg_id] = msg;
					CONFIG::debugging {
						if (msg.sent_timeout) {
							Console.error('reusing a '+msg.type+' NetOutgoingMessageVO before the response to the last time it was sent has returned!');
						} else {
							var secs:Number = 20;
							msg.sent_timeout = StageBeacon.setTimeout(function():void {
								Console.warn(msg.type+':'+msg.msg_id+' NetOutgoingMessageVO has not received a response in seconds:'+secs);
							}, secs*1000);
						}
					}
				}
				
				msg.time_sent = getTimer();
				
				try {
					messageQueue[int(messageQueue.length)] = messageToAnonymousObject(msg,sendObject);
					if(msg.needs_msg_id && msg.msg_id){
						return msg_id;
					}else{
						return 0;
					}
				}catch(e:IOError){
					return -1;
				}
			}
			return -1;
		}
		
		public function sendRequests():void {
			while (messageQueue.length){
				sendAnonymousObjectRequest(messageQueue.pop());
			}
		}
		
		CONFIG::debugging private function trackMsgCounts(type:String, kind:String):void {
			var dic:Object;
			
			switch (kind) {
				case 'REQ':
					dic = Counts.net_msg_req_counts;
					Console.trackValue('NDS total reqs', Counts.net_msg_req_count+=1);
					break;
				case 'RSP':
					dic = Counts.net_msg_rsp_counts;
					Console.trackValue('NDS total rsps', Counts.net_msg_rsp_count+=1);
					break;
				case 'EVT':
					dic = Counts.net_msg_evt_counts;
					Console.trackValue('NDS total evts', Counts.net_msg_evt_count+=1);
					break;
				default:
					return;
			}
			
			if (!dic[type]) dic[type] = 0;
			dic[type]++;
			Console.trackValue('NDS msg '+kind+' '+type, dic[type]);
		}
		
		private function sendAnonymousObjectRequest(ob:Object):Boolean {
			if(netSocket.connected){
				if(ob == null || ob.type == null){
					CONFIG::debugging {
						Console.error('no ob or no ob.type')
					}
					return false;
				}
				
				CONFIG::debugging {
					var pri:int = 2;
					if (model.flashVarModel.priority.indexOf('202') != -1) {
						pri = 202;
					} 
					pri = (ob.type == 'move_xy' || ob.type == 'move_vec') ? 9 : pri;
					pri = (ob.type == MessageTypes.PING) ? 12 : pri;
					pri = (ob.type == 'item_state' || ob.type == 'itemstack_status') ? 13 : pri;
					Console.pridir(pri, ob, model.flashVarModel.show_tree_str);
				}
				
				// make a copy and log it
				if (ob.type != MessageTypes.PING) {
					var copy:Object = ObjectUtil.copyOb(ob);
					copy.ts = StringUtil.getColonDateInGMT(new Date());
					CONFIG::debugging {
						model.activityModel.net_msgs.push(copy);
					}
					
					if (ob.type != MessageTypes.MOVE_XY) {
						model.activityModel.net_msgs_short.push(copy);
						if (model.activityModel.net_msgs_short.length > model.activityModel.net_msgs_short_max) {
							model.activityModel.net_msgs_short.shift();
						}
						if (MessageTypes.isMoveRelatedMessageType(ob.type)) {
							Benchmark.addCheck('sent: '+StringUtil.getJsonStr(copy));
						}
					}
				}
				
				try {
					if (ob.type != MessageTypes.PING) {
						//TODO PERF remove one day when we're satisfied that we solved the socket readObject problems
						model.netModel.last_sent_message = ObjectUtil.copyOb(ob);
					}
					
					netSocket.writeObject(ob);
					netSocket.flush();

					CONFIG::debugging {
						trackMsgCounts(ob.type, 'REQ');
					}
					if (ob.type == MessageTypes.PING) {
						Benchmark.addCheck('ping sent');
						if (pingTimer) {
							pingTimer.reset();
							pingTimer.start();
						} 
					}
					
					return true;
				}catch(e:IOError){
					CONFIG::debugging {
						Console.error('IOError')
					}
					return false;
				}
			}
			
			return false;
		}
		
		override public function dispose():void {
			netSocket.dispose();
			
			pingTimer.stop();
			pingTimer.reset();
			pingTimer.removeEventListener(TimerEvent.TIMER, onPingTimer);
			pingTimer = null;
		}
	}
}