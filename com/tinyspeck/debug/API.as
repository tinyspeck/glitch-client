package com.tinyspeck.debug {
	import com.adobe.serialization.json.JSON;
	import com.quietless.bitmap.BitmapSnapshot;
	import com.tinyspeck.bootstrap.Version;
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.Version;
	import com.tinyspeck.engine.loader.SmartURLLoader;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.IMainView;
	
	import flash.display.BitmapData;
	import flash.display.Stage;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;

	public class API {
		
		/** To aid in preventing accidental GC of anonymous loaders */
		private static const runningLoaders:Dictionary = new Dictionary(false);
		
		private static var fvm:FlashVarModel
		private static var api_url:String;
		private static var api_token:String;
		private static var pc_tsid:String = '';
		private static var session_id:String = '';
		
		private static function trackLoader(loader:SmartURLLoader):void {
			runningLoaders[loader] = true;
			//trace('# tracking', loader.name);
		}
		
		private static function forgetLoader(loader:SmartURLLoader):void {
			delete runningLoaders[loader];
			//trace('# forgetting', loader.name);
			//for (var k:* in runningLoaders) {
			//	trace('\t# running', k.name);
			//}
		}
		
		public static function setAPIUrl(url:String, token:String):void {
			API.api_url = url;
			API.api_token = token;
		}
		
		public static function setSessionId(session_id:String):void {
			API.session_id = session_id;
		}
		
		public static function setPcTsid(pc_tsid:String):void {
			API.pc_tsid = pc_tsid;
		}
		
		public static function setFVM(fvm:FlashVarModel):void {
			API.fvm = fvm;
		}
		
		public static function scribe(txt:String):void {
			return;
			
			if (!api_url) return;
			
			const apiLoader:SmartURLLoader = new SmartURLLoader('client.log');
			trackLoader(apiLoader);

			var url:String = api_url+'simple/client.log';
			var request:URLRequest = new URLRequest(url);
			var variables:URLVariables = new URLVariables();
			variables.ctoken = api_token;
			variables.message = txt;
			request.data = variables;
			request.method = URLRequestMethod.POST;
			
			apiLoader.complete_sig.add(
				function onScribeComplete(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					var json_str:String = loader.data;
					var rsp:Object;
					try {
						rsp = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {};
					} catch (e:Error) {
						//
					}
					if (!rsp || !rsp.ok) {
						; // satisfy compiler
						CONFIG::debugging {
							trace('error sending to scribe:'+json_str);
						}
					}
				}
			);
			
			apiLoader.error_sig.add(
				function onScribeError(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					CONFIG::debugging {
						trace('failed to load '+url);
					}
				}
			);
			
			urlLoad(apiLoader, request);
		}
		
		private static function urlLoad(apiLoader:SmartURLLoader, req:URLRequest, no_log:Boolean=false):void {
			CONFIG::debugging {
				var url:String = req.url.replace(/\&/g, ' \&');
				if (!no_log) Console.priinfo(2, '\r'+url+'\r'+StringUtil.getCallerCodeLocation());
			}
			
			apiLoader.load(req);
		}
		
		public static function getToken(callback:Function = null):void {
			if (!api_url) return;
			
			const apiLoader:SmartURLLoader = new SmartURLLoader('client.getToken');
			trackLoader(apiLoader);
			
			const url:String = api_url+'simple/client.getToken';
			const request:URLRequest = new URLRequest(url);
			const variables:URLVariables = new URLVariables();
			variables.ctoken = api_token;
			//variables.player_tsid = pc_tsid;
			
			request.data = variables;
			request.method = URLRequestMethod.POST;
			
			apiLoader.complete_sig.add(
				function onTokenComplete(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					var json_str:String = loader.data;
					var rsp:Object;
					try {
						rsp = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {};
					} catch (e:Error) {
						if (callback is Function) callback(false, rsp);
					}
					if (!rsp || !rsp.ok) {
						CONFIG::debugging {
							trace('error sending to api:'+json_str);
						}
						if (callback is Function) callback(false, rsp);
					} else {
						if (callback is Function) callback(true, rsp);
					}
				}
			);
			
			apiLoader.error_sig.add(
				function onTokenError(loader:SmartURLLoader):void {
					forgetLoader(loader);
					CONFIG::debugging {
						trace('failed to load '+url);
					}
					if (callback is Function) callback(false, null);
				}
			);
			
			Benchmark.addCheck('GETTING A TOKEN:'+url);
			urlLoad(apiLoader, request);
		}
		
		public static function findNearestItem(routing_class:String, callback:Function = null):void {
			if (!api_url) return;
			
			const apiLoader:SmartURLLoader = new SmartURLLoader('items.findNearest');
			trackLoader(apiLoader);
			
			const url:String = api_url+'simple/items.findNearest?item_class_tsid='+routing_class;
			const request:URLRequest = new URLRequest(url);
			const variables:URLVariables = new URLVariables();
			variables.ctoken = api_token;
			request.data = variables;
			request.method = URLRequestMethod.POST;
			
			apiLoader.complete_sig.add(
				function onFindNearestComplete(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					var json_str:String = loader.data;
					var rsp:Object;
					try {
						rsp = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {};
					} catch (e:Error) {
						if (callback is Function) callback(false, rsp);
					}
					
					if (rsp) rsp.routing_class = routing_class;
					
					if (!rsp || !rsp.ok) {
						if (callback is Function) callback(false, rsp);
					} else {
						if (callback is Function) callback(true, rsp);
					}
				}
			);
			
			apiLoader.error_sig.add(
				function onFindNearestError(loader:SmartURLLoader):void {
					forgetLoader(loader);
					CONFIG::debugging {
						trace('failed to load '+url);
					}
					if (callback is Function) callback(false, null);
				}
			);
			
			urlLoad(apiLoader, request);
		}
		
		CONFIG::god public static function changeItemScale(item_classes:String, scales:String, callback:Function = null):void {
			if (!api_url) return;
			
			const apiLoader:SmartURLLoader = new SmartURLLoader('god.items.changeScale');
			trackLoader(apiLoader);
			
			const url:String = api_url+'simple/god.items.changeScale';
			const request:URLRequest = new URLRequest(url);
			const variables:URLVariables = new URLVariables();
			variables.ctoken = api_token;
			variables.item_classes = item_classes;
			variables.scales = scales;
			
			request.data = variables;
			request.method = URLRequestMethod.POST;
			
			apiLoader.complete_sig.add(
				function onTokenComplete(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					var json_str:String = loader.data;
					var rsp:Object;
					try {
						rsp = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {};
					} catch (e:Error) {
						if (callback is Function) callback(false, rsp);
					}
					if (!rsp || !rsp.ok) {
						CONFIG::debugging {
							trace('error sending to api:'+json_str);
						}
						if (callback is Function) callback(false, rsp);
					} else {
						if (callback is Function) callback(true, rsp);
					}
				}
			);
			
			apiLoader.error_sig.add(
				function onTokenError(loader:SmartURLLoader):void {
					forgetLoader(loader);
					CONFIG::debugging {
						trace('failed to load '+url);
					}
					if (callback is Function) callback(false, null);
				}
			);
			
			urlLoad(apiLoader, request);
		}
		
		//http://api.dev.glitch.com/explore/#!client.updateHelpCase
		public static function updateHelpCase(case_id:String, msg:String):void {
			CONFIG::debugging {
				Console.warn('api_url '+api_url);
			}
			
			if (!case_id) {
				CONFIG::debugging {
					Console.warn('no case_id '+case_id);
				}
				return;
			}
			
			if (!api_url) return;
			
			const apiLoader:SmartURLLoader = new SmartURLLoader('client.updateHelpCase');
			trackLoader(apiLoader);
			
			var url:String = api_url+'simple/client.updateHelpCase';
			var request:URLRequest = new URLRequest(url);
			var variables:URLVariables = new URLVariables();
			variables.ctoken = api_token;
			variables.message = msg;
			variables.case_id = case_id;
			
			request.data = variables;
			request.method = URLRequestMethod.POST;
			
			apiLoader.complete_sig.add(
				function onUpdateHelpCaseComplete(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					var json_str:String = loader.data;
					var rsp:Object;
					try {
						rsp = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {};
					} catch (e:Error) {}
					if (!rsp || !rsp.ok) {
						; // satisfy compiler
						CONFIG::debugging {
							trace('error sending to api:'+json_str);
						}
					}
				}
			);
			
			apiLoader.error_sig.add(
				function onUpdateHelpCaseError(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					CONFIG::debugging {
						trace('failed to load '+url);
					}
				}
			);
			
			urlLoad(apiLoader, request);
		}
		
		/**
		 * loc_x and loc_y are the coordinates of the center of the viewport.
		 * 
		 * Stuff is an Object of the following template:
		 * { players: [
		 *   { 'tsid' : 'TSID',
		 *     'x'    : 123,
		 *     'y'    : -123 
		 *   }, ...
		 *   ],
		 *   items: [
		 *   { 'tsid'       : 'IMF176R7BBH2A26',
		 *     'class_tsid' : 'npc_piggy',
		 *     'label'      : 'Clive The Pig',
		 *     'x'          : 312,
		 *     'y'          : -1024
		 *   }, ...
		 *   ],
		 * }
		 */
		public static function saveCameraSnap(bss:BitmapSnapshot, location_tsid:String, loc_x:int, loc_y:int, stuff:Object, caption:String, filterTSID:String = "", callback:Function = null):void {
			bss.saveOnServerMultiPart(
				'img',
				{
					caption: caption,
					filter: filterTSID,
					location_tsid: location_tsid,
					ctoken: api_token,
					location_x: loc_x,
					location_y: loc_y,
					stuff: StringUtil.getJsonStr(stuff)
				},
				api_url+'simple/snaps.upload',
				null,
				function(ok:Boolean, txt:String = ''):void {
					var json_str:String = txt;
					var rsp:Object = {ok:false /*error in error format here*/};
					ok = false;
					try {
						rsp = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {ok:false /*error in error format here*/};
					} catch (e:Error) {}
					if (!rsp || !rsp.ok) {
						; // satisfy compiler
						CONFIG::debugging {
							Console.warn('failed snaps.upload:'+json_str);
						}
					} else {
						ok = true;
					}
					
					if (callback is Function) callback(ok, rsp);
				}
			);
		}
		
		public static function saveNewAvatar(ob:Object, callback:Function = null):void {
			if (!api_url) return;
			
			const apiLoader:SmartURLLoader = new SmartURLLoader('avatar.setInitial');
			trackLoader(apiLoader);
			
			const url:String = api_url+'simple/avatar.setInitial';
			const request:URLRequest = new URLRequest(url);
			const variables:URLVariables = new URLVariables();
			variables.ctoken = api_token;

			for (var k:String in ob) {
				variables[k] = ob[k];
			}
			
			request.data = variables;
			request.method = URLRequestMethod.POST;
			
			apiLoader.complete_sig.add(
				function onTokenComplete(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					var json_str:String = loader.data;
					var rsp:Object;
					try {
						rsp = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {};
					} catch (e:Error) {
						if (callback is Function) callback(false, rsp);
					}
					
					if (!rsp || !rsp.ok) {
						if (callback is Function) callback(false, rsp);
					} else {
						if (callback is Function) callback(true, rsp);
					}
				}
			);
			
			apiLoader.error_sig.add(
				function onTokenError(loader:SmartURLLoader):void {
					forgetLoader(loader);
					CONFIG::debugging {
						Console.warn('failed to load '+url);
					}
					if (callback is Function) callback(false, null);
				}
			);
			
			urlLoad(apiLoader, request);
		}
		
		public static function checkPlayerName(name:String, callback:Function = null):void {
			if (!api_url) return;
			
			const apiLoader:SmartURLLoader = new SmartURLLoader('quickstart.checkName');
			trackLoader(apiLoader);
			
			const url:String = api_url+'simple/quickstart.checkName';
			const request:URLRequest = new URLRequest(url);
			const variables:URLVariables = new URLVariables();
			variables.ctoken = api_token;
			variables.name = name;
			
			request.data = variables;
			request.method = URLRequestMethod.POST;
			
			apiLoader.complete_sig.add(
				function onTokenComplete(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					var json_str:String = loader.data;
					var rsp:Object;
					try {
						rsp = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {};
					} catch (e:Error) {
						if (callback is Function) callback(false, rsp);
					}
					
					if (!rsp || !rsp.ok) {
						if (callback is Function) callback(false, rsp);
					} else {
						if (callback is Function) callback(true, rsp);
					}
				}
			);
			
			apiLoader.error_sig.add(
				function onTokenError(loader:SmartURLLoader):void {
					forgetLoader(loader);
					CONFIG::debugging {
						Console.warn('failed to load '+url);
					}
					if (callback is Function) callback(false, null);
				}
			);
			
			urlLoad(apiLoader, request, true);
		}
		
		public static function setPlayerName(name:String, callback:Function = null):void {
			if (!api_url) return;
			
			const apiLoader:SmartURLLoader = new SmartURLLoader('quickstart.setName');
			trackLoader(apiLoader);
			
			const url:String = api_url+'simple/quickstart.setName';
			const request:URLRequest = new URLRequest(url);
			const variables:URLVariables = new URLVariables();
			variables.ctoken = api_token;
			variables.name = name;
			
			request.data = variables;
			request.method = URLRequestMethod.POST;
			
			apiLoader.complete_sig.add(
				function onTokenComplete(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					var json_str:String = loader.data;
					var rsp:Object;
					try {
						rsp = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {};
					} catch (e:Error) {
						if (callback is Function) callback(false, rsp);
					}
					
					if (!rsp || !rsp.ok) {
						if (callback is Function) callback(false, rsp);
					} else {
						if (callback is Function) callback(true, rsp);
					}
				}
			);
			
			apiLoader.error_sig.add(
				function onTokenError(loader:SmartURLLoader):void {
					forgetLoader(loader);
					CONFIG::debugging {
						Console.warn('failed to load '+url);
					}
					if (callback is Function) callback(false, null);
				}
			);
			
			urlLoad(apiLoader, request, true);
		}
		
		/** http://developer.dev.glitch.com/api/explore/#!snaps.publish */
		public static function postPhotoStatus(snap_id:String, text:String, callback:Function = null):void {
			if (!api_url) return;
			
			const apiLoader:SmartURLLoader = new SmartURLLoader('client.postPhotoStatus');
			trackLoader(apiLoader);
			
			const url:String = api_url+'simple/snaps.publish';
			const request:URLRequest = new URLRequest(url);
			const variables:URLVariables = new URLVariables();
			variables.ctoken = api_token;
			variables.snap_id = snap_id;
			variables.text = text;
			
			request.data = variables;
			request.method = URLRequestMethod.POST;
			
			apiLoader.complete_sig.add(
				function onTokenComplete(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					var json_str:String = loader.data;
					var rsp:Object;
					try {
						rsp = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {};
					} catch (e:Error) {
						if (callback is Function) callback(false, rsp);
					}
					
					if (!rsp || !rsp.ok) {
						CONFIG::debugging {
							Console.warn('failed snaps.publish:'+json_str);
						}
						if (callback is Function) callback(false, rsp);
					} else {
						if (callback is Function) callback(true, rsp);
					}
				}
			);
			
			apiLoader.error_sig.add(
				function onTokenError(loader:SmartURLLoader):void {
					forgetLoader(loader);
					CONFIG::debugging {
						Console.warn('failed to load '+url);
					}
					if (callback is Function) callback(false, null);
				}
			);
			
			urlLoad(apiLoader, request);
		}
		
		public static function attachErrorImageToError(error_id:*, mainView:IMainView, callbacker:Function = null):void {
			const stage:Stage = StageBeacon.stage;
			
			var bmd:BitmapData = new BitmapData(stage.stageWidth, stage.stageHeight, false);
			
			// we don't want the error message onscreen
			BootError.hide();
			
			// we want the stats display on stage
			var last_stats_viz:Boolean;
			if (mainView) {
				last_stats_viz = mainView.performanceGraphVisible;
				mainView.performanceGraphVisible = true;
			}
			
			bmd.draw(stage);
			BootError.show();
			if (mainView) mainView.performanceGraphVisible = last_stats_viz;
			
			var img:BitmapSnapshot = new BitmapSnapshot(null, 'screenshot.png', 0, 0, bmd);
			img.saveOnServerMultiPart(
				'screen',
				{
					ctoken: api_token,
					error_id: error_id
				},
				api_url+'simple/client.attachErrorImage',
				null,
				function(ok:Boolean, txt:String = ''):void {
					if (callbacker is Function) callbacker(ok, txt);
				}
			);
		}
		
		public static function explainError(error_id:String, user_txt:String):void {
			/* http://api.dev.glitch.com/#client.explainError
			
			/simple/client.explainError [Admin Only]
			Add user-entered details to an already-reported error.
			
			* error_id - The ID returned by client.error.
			* user_error - Explanation text entered by the user.
			*/
			CONFIG::debugging {
				Console.warn('api_url '+api_url);
			}
			
			if (!api_url) return;
			
			const apiLoader:SmartURLLoader = new SmartURLLoader('client.explainError');
			trackLoader(apiLoader);
			
			var url:String = api_url+'simple/client.explainError';
			var request:URLRequest = new URLRequest(url);
			var variables:URLVariables = new URLVariables();
			variables.ctoken = api_token;
			variables.user_error = user_txt;
			variables.error_id = error_id;
			
			request.data = variables;
			request.method = URLRequestMethod.POST;
			
			apiLoader.complete_sig.add(
				function onExplainErrorComplete(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					var json_str:String = loader.data;
					var rsp:Object;
					try {
						rsp = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {};
					} catch (e:Error) {}
					if (!rsp || !rsp.ok) {
						; // satisfy compiler
						CONFIG::debugging {
							trace('error sending to api:'+json_str);
						}
					}
				}
			);
			
			apiLoader.error_sig.add(
				function onExplainErrorError(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					CONFIG::debugging {
						trace('failed to load '+url);
					}
				}
			);
			
			urlLoad(apiLoader, request);
		}
		
		// this gets updated when the player moves
		public static var pc_location_str:String = '';
		
		public static function reportError(txt:String, user_txt:String='', is_silent:Boolean=true, error_id:String='', stack_trace:String='', keywords:Array=null, callback:Function=null):void {
			/* http://api.dev.glitch.com/#client.error
			*   player_tsid - TSID of player.
			* flash_error - Error message and trace from flash.
			* user_error - Explanation text entered by the user.
			* fv - Flash version string.
			*/
			CONFIG::debugging {
				Console.warn('api_url '+api_url);
			}
			
			if (!api_url) return;
			
			const apiLoader:SmartURLLoader = new SmartURLLoader('client.error');
			trackLoader(apiLoader);
			
			var url:String = api_url+'simple/client.error';
			var request:URLRequest = new URLRequest(url);
			var variables:URLVariables = new URLVariables();
			variables.ctoken = api_token;
			variables.player_tsid = pc_tsid;
			variables.is_silent = (is_silent ? 1 : 0);
			
			variables.keywords = keywords ? keywords.join(',') : '';
			
			variables.error_id = error_id;
			variables.stack_trace = stack_trace;
			variables.is_abuse = 0;
			variables.abuser_tsid = '';
			variables.flash_error = txt;
			variables.user_error = user_txt;
			variables.fv = Capabilities.version+((Capabilities.isDebugger)?' DEBUG':'');
			variables.is_debug = (Capabilities.isDebugger ? 1 : 0);
			variables.location = pc_location_str;
			variables.bootstrap_version = com.tinyspeck.bootstrap.Version.revision;
			variables.engine_version = com.tinyspeck.engine.Version.revision;
			
			request.data = variables;
			request.method = URLRequestMethod.POST;
			
			apiLoader.complete_sig.add(
				function onErrorComplete(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					var json_str:String = loader.data;
					var rsp:Object;
					try {
						rsp = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {};
					} catch (e:Error) {
						if (callback is Function) callback(false, null, null);
					}
					if (!rsp || !rsp.ok) {
						CONFIG::debugging {
							trace('error sending to api:'+json_str);
						}
						if (callback is Function) callback(false, null, null);
					} else {
						if (rsp.error_id) {
							NewxpLogger.log('error_reported', rsp.error_id);
						}
						if (callback is Function) callback(true, rsp.error_id, rsp.case_id);
					}
				}
			);
			
			apiLoader.error_sig.add(
				function(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					CONFIG::debugging {
						trace('failed to load '+url);
					}
				}
			);
			
			urlLoad(apiLoader, request);
		}
		
		public static function reportAbuse(txt:String, user_txt:String, abuser_tsid:String, callback:Function=null):void {
			/* http://api.dev.glitch.com/#client.error
			*   player_tsid - TSID of player.
			*   flash_error - Error message and trace from flash.
			*   user_error - Explanation text entered by the user.
			*   fv - Flash version string.
			*/
			CONFIG::debugging {
				Console.warn('api_url '+api_url);
			}
			
			if (!api_url) return;
			
			const apiLoader:SmartURLLoader = new SmartURLLoader('client.error');
			trackLoader(apiLoader);
			
			var url:String = api_url+'simple/client.error';
			var request:URLRequest = new URLRequest(url);
			var variables:URLVariables = new URLVariables();
			variables.ctoken = api_token;
			variables.player_tsid = pc_tsid;
			variables.is_silent = 0;
			variables.is_abuse = 1;
			variables.abuser_tsid = abuser_tsid || '';
			variables.flash_error = txt;
			variables.user_error = user_txt;
			variables.fv = Capabilities.version+((Capabilities.isDebugger)?' DEBUG':'');
			variables.is_debug = (Capabilities.isDebugger ? 1 : 0);
			variables.location = pc_location_str;
			
			request.data = variables;
			request.method = URLRequestMethod.POST;
			
			apiLoader.complete_sig.add(
				function onErrorComplete(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					var json_str:String = loader.data;
					var rsp:Object;
					try {
						rsp = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {};
					} catch (e:Error) {
						if (callback is Function) callback(false, null, null);
					}
					if (!rsp || !rsp.ok) {
						CONFIG::debugging {
							trace('error sending to api:'+json_str);
						}
						if (callback is Function) callback(false, null, null);
					} else {
						if (callback is Function) callback(true, rsp.error_id, rsp.case_id);
					}
				}
			);
			
			apiLoader.error_sig.add(
				function(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					CONFIG::debugging {
						trace('failed to load '+url);
					}
				}
			);
			
			urlLoad(apiLoader, request);
		}
		
		public static function logNewxp(marker:String, data:String, client_order:uint, x:int, y:int):void {
			CONFIG::debugging {
				Console.warn('api_url '+api_url);
			}
			
			if (!api_url) return;
			
			const apiLoader:SmartURLLoader = new SmartURLLoader('client.logNewxp', true);
			trackLoader(apiLoader);
			
			var url:String = api_url+'simple/client.logNewxp';
			var request:URLRequest = new URLRequest(url);
			var variables:URLVariables = new URLVariables();
			variables.ctoken = api_token;
			variables.player_tsid = pc_tsid;
			variables.marker = marker;
			if (data) variables.data = data;
			variables.session = session_id;
			variables.client_order = client_order;
			variables.x = x;
			variables.y = y;
			
			request.data = variables;
			request.method = URLRequestMethod.POST;
			
			apiLoader.complete_sig.add(
				function onErrorComplete(loader:SmartURLLoader):void {
					forgetLoader(loader);
				}
			);
			
			apiLoader.error_sig.add(
				function(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					CONFIG::debugging {
						trace('failed to load '+url);
					}
				}
			);
			
			urlLoad(apiLoader, request);
		}
		
		public static function logPerformance(
			fps:Number, fps_std_dev:Number, physics_fps:Number, mem:Number, bps:Number, retries:int, flash_has_focus:Boolean,
			io_errors:int, l500_errors:int, long_loads:int, no_content_errors:int, bucket:String, log_normal_too:Boolean):void
		{
			if (!api_url) return;
			
			bucket = bucket || ''; //make sure it is a string;
			
			const apiLoader:SmartURLLoader = new SmartURLLoader('client.performance');
			trackLoader(apiLoader);

			var url:String = api_url+'simple/client.performance';
			var request:URLRequest = new URLRequest(url);
			var variables:URLVariables = new URLVariables();
			variables.ctoken = api_token;
			variables.player_tsid = pc_tsid;
			// round to two decimal places
			variables.fps = (int(fps * 100) / 100);
			// round to two decimal places
			variables.fps_std_dev = (int(fps_std_dev * 100) / 100);
			// round to two decimal places
			variables.physics_fps = (int(physics_fps * 100) / 100);
			// round to two decimal places
			variables.bps = (int(bps * 100) / 100);
			variables.mem = mem;
			variables.retries = retries;
			variables.flash_has_focus = (flash_has_focus) ? 1 : 0;
			variables.io_errors = io_errors;
			variables.l500_errors = l500_errors;
			variables.long_loads = long_loads;
			variables.no_content_errors = no_content_errors;
			variables.bucket = bucket.toLowerCase();
			variables.log_normal_too = (log_normal_too) ? 1 : 0
			
			request.data = variables;
			request.method = URLRequestMethod.POST;
			
			CONFIG::debugging {
				Console.pridir(267, variables);
			}
			
			apiLoader.complete_sig.add(
				function onPerfLogComplete(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					CONFIG::debugging {
						var json_str:String = loader.data;
						var rsp:Object;
						if (json_str) {
							try {
								rsp = com.adobe.serialization.json.JSON.decode(json_str);
							} catch (e:Error) {
								//
							}
							if (!rsp || !rsp.ok) {
								trace('error logging performance:' + json_str);
							}
						}
					}
				}
			);
			
			apiLoader.error_sig.add(
				function onPerfLogError(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					CONFIG::debugging {
						trace('error logging performance');
					}
				}
			);
			
			urlLoad(apiLoader, request, true);
		}
		
		/** http://developer.dev.glitch.com/api/explore/#!client.perf.start */
		CONFIG::perf public static function perfStart(
			player_tsid:String,
			trial_name:String,
			os:String,
			flash_version:String,
			flash_major_version:int,
			flash_minor_version:int,
			gpuAvailable:Boolean,
			gpuDriverInfo:String,
			callback:Function):void
		{
			if (!api_url) return;
			
			const apiLoader:SmartURLLoader = new SmartURLLoader('client.perf.start');
			trackLoader(apiLoader);
			
			const url:String = api_url+'simple/client.perf.start';
			const request:URLRequest = new URLRequest(url);
			const variables:URLVariables = new URLVariables();
			variables.ctoken = api_token;
			variables.player_tsid = player_tsid;
			variables.trial_name = trial_name;
			variables.os = os;
			variables.flash_version = flash_version;
			variables.flash_major_version = flash_major_version;
			variables.flash_minor_version = flash_minor_version;
			variables.gpu_available = (gpuAvailable ? 1 : 0);
			variables.gpu_driver_info = gpuDriverInfo;
			
			request.data = variables;
			request.method = URLRequestMethod.POST;

			apiLoader.complete_sig.add(
				function onComplete(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					var json_str:String = loader.data;
					var rsp:Object;
					try {
						rsp = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {};
					} catch (e:Error) {
						if (callback is Function) callback(false, rsp);
					}
					if (!rsp || !rsp.ok) {
						CONFIG::debugging {
							trace('error sending to api:'+json_str);
						}
						if (callback is Function) callback(false, rsp);
					} else {
						if (callback is Function) callback(true, rsp);
					}
				}
			);
			
			apiLoader.error_sig.add(
				function onError(loader:SmartURLLoader):void {
					forgetLoader(loader);
					CONFIG::debugging {
						trace('failed to load '+url);
					}
					if (callback is Function) callback(false, null);
				}
			);
			
			urlLoad(apiLoader, request);
		}
		
		/** http://developer.dev.glitch.com/api/explore/#!client.perf.store */
		CONFIG::perf public static function perfStore(
			session_id:String,
			player_tsid:String,
			loc_tsid:String,
			renderer:String,
			fake_friends:Number,
			segment_stage_width:Number,
			segment_stage_height:Number,
			segment_vp_width:Number,
			segment_vp_height:Number,
			segment_name:String,
			segment_time:Number,
			segment_frames:Number,
			segment_avg_fps:Number,
			segment_avg_mem:Number,
			segment_mem_delta:Number,
			callback:Function):void
		{
			if (!api_url) return;
			
			const apiLoader:SmartURLLoader = new SmartURLLoader('client.perf.store');
			trackLoader(apiLoader);
	
			var url:String = api_url+'simple/client.perf.store';
			var request:URLRequest = new URLRequest(url);
			var variables:URLVariables = new URLVariables();
			variables.ctoken = api_token;
			variables.session_id = session_id;
			variables.player_tsid = player_tsid;
			variables.loc_tsid = loc_tsid;
			variables.renderer = renderer;
			variables.fake_friends = fake_friends;
			variables.segment_stage_width = segment_stage_width;
			variables.segment_stage_height = segment_stage_height;
			variables.segment_vp_width = segment_vp_width;
			variables.segment_vp_height = segment_vp_height;
			variables.segment_name = segment_name;
			variables.segment_time = segment_time;
			variables.segment_frames = segment_frames;
			variables.segment_avg_fps = segment_avg_fps;
			variables.segment_avg_mem = segment_avg_mem;
			variables.segment_mem_delta = segment_mem_delta;
				
			request.data = variables;
			request.method = URLRequestMethod.POST;
			
			CONFIG::debugging {
				Console.pridir(267, variables);
			}
			
			apiLoader.complete_sig.add(
				function onComplete(loader:SmartURLLoader):void {
					forgetLoader(loader);
					
					var json_str:String = loader.data;
					var rsp:Object;
					try {
						rsp = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {};
					} catch (e:Error) {
						if (callback is Function) callback(false, rsp);
					}
					if (!rsp || !rsp.ok) {
						CONFIG::debugging {
							trace('error sending to api:'+json_str);
						}
						if (callback is Function) callback(false, rsp);
					} else {
						if (callback is Function) callback(true, rsp);
					}
				}
			);
			
			apiLoader.error_sig.add(
				function onError(loader:SmartURLLoader):void {
					forgetLoader(loader);
					CONFIG::debugging {
						trace('failed to load '+url);
					}
					if (callback is Function) callback(false, null);
				}
			);
			
			urlLoad(apiLoader, request);
		}
	}
}
