package com.tinyspeck.debug
{
	import com.adobe.serialization.json.JSON;
	import com.tinyspeck.bootstrap.Version;
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.loader.SmartThreader;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.URLUtil;
	import com.tinyspeck.engine.view.IMainView;
	
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.events.TimerEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.text.AntiAliasType;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	import flash.utils.getTimer;

	final public class BootError
	{		
		private static const WIDTH:int = 320;
		private static const PADDING:int = 10;
	
		public static var fvm:FlashVarModel;
		public static var mainView:IMainView;
		public static var is_bug_open:Boolean;
		public static var confirmCallback:Function;
		public static var most_recent_gs:String;
		
		/**
		 * When non-null, an Error object is passed to the given function call
		 * whenever an error occurs that BootError handles
		 */
		CONFIG::perf public static var handleErrorCallback:Function;
		
		private static var onTopTimer:Timer;
		private static var holder:Sprite;
		private static var text_tf:TextField;
		private static var actions_tf:TextField;
		private static var label_tf:TextField;
		private static var input_tf:TextField;
		private static var send_tf:TextField;
		private static var send_sp:Sprite;
		private static var extra_tf:TextField;
		private static var style:StyleSheet;
		private static var errorsA:Array;
		private static var user_initiated:Boolean;
		private static var last_returned_error_id:String = '';
		private static var last_err_str:String;
		private static var ping:uint;
		
		public function BootError() {
			CONFIG::debugging {
				throw new Error('To do anything, just call the static function "addError"');
			}
		}
		
		/**
		 * Call this from an error handler if you want to display it to the user or log it.
		 * error:* may be either an Error or ErrorEvent
		 */
		public static function handleError(desc:*, errorOrErrorEvent:*, keywords:Array=null, no_display:Boolean = false, include_image:Boolean = true):void {
			if (fvm.no_bug) {
				return;
			}
			
			
			// might be null!
			const errorEvent:ErrorEvent = (errorOrErrorEvent as ErrorEvent);
			
			// might be null
			var error:Error = (errorOrErrorEvent as Error);
			if (!error && errorEvent) {
				// convert an ErrorEvent to Error
				error = new Error(errorEvent.toString(), errorEvent.errorID);
			}
			
			Benchmark.addCheck("BootError.handleError: error:" + (error ? error.getStackTrace() : error));
			
			CONFIG::perf {
				if (handleErrorCallback != null) {
					handleErrorCallback(error);
					return;
				}
			}
			
			primePerformanceGraph();

			if (desc && desc is String && desc.length > 20000) {
				desc = String(desc).substr(0, 20000)+' TRUNCATED';
			}
			
			var disp_str:String = desc+'\n\n';
			var log_str:String = '\nI STOPPED SHOWING THE DESC TWICE IN THE REPORTS!!! :)\n';
			
			var st_str:String = (error) ? StringUtil.getShorterStackTrace(error) : '';
			if (!st_str && error) {
				// fuck! getShorterStackTrace does not always do the right thing
				st_str = error.getStackTrace();
			}
			
			if (st_str) {
				log_str+= st_str;
				disp_str+= st_str;
			} else {
				log_str+= error || 'null Error passed to handleError';
				disp_str+= error || 'null Error passed to handleError';
			}

			log('handleError log_str: '+log_str);
			
			// if this is the same as the last one, don't send it!
			if (error && last_err_str == error.toString()) {
				return;
			}
			
			if (no_display) {
				disp_str+= '\n\nSILENT ERROR, ADDING SESSION DETAILS:\n\n'+session_details;
				disp_str+= '\n\nSILENT ERROR, ADDING BENCHMARK DETAILS:\n\n'+Benchmark.getShortLog();
				if (net_msgsA && net_msgsA.length) {
					disp_str+= '\n\nSILENT ERROR, ADDING MSGS:\n----------------------------------------------------\n\n'+buildMsgsString();
				}

				// report it now but don't remember error_id
				reportError(disp_str, 'NOT REPORTED BY USER', no_display, (error ? String(error.errorID) : ''), (error ? error.getStackTrace() : ''), keywords, true, include_image);
			} else {
				addErrorMsg(disp_str, error, keywords); // this will call API.reportError
			}
			
			if (error) last_err_str = error.toString();
		}
		
		// there are "uncaught" exceptions that find their way here
		public static function handleGlobalErrors(e:UncaughtErrorEvent):void {
			// suppress the flash error dialog
			e.preventDefault();
			handleError(e, e.error, ['uncaught']);
		}
		
		private static var was_x:int;
		public static function hide():void {
			if (!holder) return;
			was_x = holder.x;
			holder.x = -1000;
		}
		
		public static function show():void {
			if (!holder) return;
			holder.x  = was_x;
		}
		
		private static function log(...anything):void {
			Benchmark.addCheck('BootError.log '+anything.toString());
			CONFIG::debugging {
				//Console.scribe(anything.toString());
			}
		}
		
		public static var msgs_at_user_bug_click:String = '';
		// called by user, currently only by clicking on bug icon
		public static function openBugReportUI(defaultText:String = ''):void {
			primePerformanceGraph();
			
			user_initiated = true;
			is_bug_open = true;
			
			// build this now, so we get the most recent messages at the time they clicked in the report
			msgs_at_user_bug_click = buildMsgsString();
			
			Benchmark.addCheck('BootError.openBugReportUI called, user clicked bug icon');
			addErrorMsg('USER REPORTED ERROR', null, ['user']); // this string is important to how the API processes the report DO NOT CHANGE
			
			input_tf.text = defaultText;
		}
		
		public static function closeBugReportUI():void {
			user_initiated = false;
			is_bug_open = false;
			
			Benchmark.addCheck('BootError.closeBugReportUI called, user clicked bug icon');
			last_err_str = '';
			
			if(StageBeacon.stage.contains(holder)) StageBeacon.stage.removeChild(holder);
			
			onTopTimer.stop();
		}
		
		private static function reportError(str:String, user_str:String = '', is_silent:Boolean=true, error_id:String='', stack_trace:String='', keywords:Array=null, no_remember_id:Boolean = false, include_image:Boolean = true):void {
			if (fvm && fvm.disable_bug_reporting) return;
			
			if (str && str.length > 65500) str = String(str).substr(0, 65500)+' TRUNCATED';
			API.reportError(str, user_str, is_silent, error_id, stack_trace, keywords, function(success:Boolean, ret_error_id:String, ret_case_id:String):void {
				if (success && !last_returned_error_id) { // checking for error_id makes sure that explainError is called (and that we save screen shot) ONLY for the first error (not any other that happen while this is open)
					if (!no_remember_id && holder && holder.parent) {
						last_returned_error_id = ret_error_id;
					}
					
					if (include_image) {
						// give stats a few moments to update
						StageBeacon.setTimeout(function():void {
							try {
								API.attachErrorImageToError(ret_error_id, mainView, function(ok:Boolean, txt:String = ''):void {
									CONFIG::debugging {
										Console.warn(ok+' '+txt);
									}
								});
							} catch(err:Error) {}
							
							if (ret_case_id && confirmCallback != null) {
								confirmCallback(true, ret_case_id);
							}
							
						}, 1000);
					}
				}
			});
		}
		
		public static function buildMsgsString():String {
			if (!net_msgsA || net_msgsA.length == 0) return '';
			
			var all_txt:String = '\n\n';
			
			var tempA:Array = [];
			var msg:Object;
			var i:int;
			
			for (i=net_msgsA.length-1;i>-1;i--) {
				msg = net_msgsA[int(i)];
				tempA.push(StringUtil.getJsonStr(msg));
			}
			
			all_txt = tempA.join(',\n\n');
			
			return all_txt;

		}
		
		public static var focus_details:String = 'UNKNOWN';
		public static var camera_details:String = 'UNKNOWN';
		public static var scroll_details:String = 'UNKNOWN';
		public static var net_msgsA:Array;
		public static function addErrorMsg(anything:Object, error:Error=null, keywords:Array=null):void {
			primePerformanceGraph();
			// report it now and remember error_id, if it was triggered by code only
			if (!user_initiated) {
				var rep_txt:String = anything.toString();
				if (!holder || !holder.parent) {
					rep_txt+= '\n\nON FIRST ERROR, ADDING SESSION DETAILS:\n\n'+session_details;
					rep_txt+= '\n\nON FIRST ERROR, ADDING BENCHMARK DETAILS:\n\n'+Benchmark.getShortLog();
					if (net_msgsA && net_msgsA.length) {
						rep_txt+= '\n\nON FIRST ERROR, ADDING MSGS:\n----------------------------------------------------\n\n'+buildMsgsString();
					}
				}
				reportError(rep_txt, 'NOT REPORTED BY USER', false, (error ? String(error.errorID) : ''), (error ? error.getStackTrace() : ''), keywords);
			}
			
			if (!text_tf) _createTextBlock();
			if (!holder) _createHolder();
			
			var header:String = '';
			var input_label:String = '';
			var actions:String = '<a href="event:close">Close</a>';
			
			if (user_initiated) {
				if (fvm && (fvm.player_open_cases && !fvm.is_stub_account)) {
					header = '<h1>If this is an update to an existing help case you have open, please <a href="event:update">go here</a> to update it instead of using this form!</h1>';
				} else {
					header = '<h1>Thanks for reporting a bug!</h1>';
				}
				input_label = '<p>Please describe the problem you are having:';
				input_tf.height = 100;
			} else {
				var chars:int = (CONFIG::god) ? 1000 : 200;
				header = "<h1>Uh Oh! An Error Did Occur...</h1>\n<p class=\"gray\">"+anything.toString().substr(0,chars)+(anything.toString().length>chars?' ...':'')+"</p>";
				if (fvm && fvm.disable_bug_reporting) {
					input_label = "<p>Sorry about that, truly! Unfortunately, you can't report this bug to us because you're using an unsupported web browser or Flash Player (" + Capabilities.version + ").</p>";
					input_tf.height = 0;
				} else {
					input_label = '<p>What were you doing when this happened? (optional)</p>';
					input_tf.height = 50;
				}
				actions = '<a href="event:copy">Copy to Clipboard</a> | <a href="event:reload">Reload page</a> | '+actions;
			}
			
			actions_tf.htmlText = '<p>'+actions+'</p>';
			
			text_tf.htmlText = header;
			text_tf.height = Math.min(text_tf.textHeight+4, 350);
			
			label_tf.width = WIDTH;
			label_tf.htmlText = input_label;
			label_tf.height = label_tf.textHeight;
			
			label_tf.y = text_tf.y + text_tf.height+10;
			input_tf.y = label_tf.y + label_tf.height;
			send_sp.y = input_tf.y + input_tf.height+5;
			send_sp.x = WIDTH-send_sp.width+PADDING;
			
			var do_focus:Boolean = false;
			if (!holder.parent) {
				input_tf.text = '';
				do_focus = true;
			}
			
			actions_tf.y = input_tf.y + input_tf.height+7;
			
			errorsA.push(anything);
			
			extra_tf.visible = false;
			extra_tf.height = 0;
			extra_tf.width = WIDTH;
			if (!Capabilities.isDebugger) {
				extra_tf.htmlText = '<p><b>Please consider <a href="http://www.glitch.com/help/faq/#q27">installing</a> a debugger version</b> of the Flash plugin, which provides us with a lot more detail about your problem!</p>';
				extra_tf.height = extra_tf.textHeight;
				extra_tf.visible = true;
			}
			extra_tf.y = actions_tf.y+actions_tf.height+PADDING;
			
			//throw it on stage
			StageBeacon.stage.addChild(holder);
			
			if (do_focus) StageBeacon.waitForNextFrame(setFocusToInputTF);
			
			// let's keep it on top
			onTopTimer.start();
			holder.graphics.clear();
			holder.graphics.beginFill(0xe3e3e3);
			holder.graphics.drawRoundRect(0, 0, WIDTH + PADDING*2, extra_tf.y+extra_tf.height+PADDING, 8);
			holder.graphics.endFill();
			
			holder.x = Math.round((StageBeacon.stage.stageWidth-holder.width)/2);
			holder.y = 150;
			
			ExternalInterface.call('TS.client.AS_interface.incoming_JS', {
				meth: 'error_ui_opened',
				params: null
			});
		}
		
		private static function _createTextBlock():void {
			//create the stylesheet
			_createStyleSheet();
			
			//create the error array
			errorsA = new Array();
			
			//setup the main text block
			text_tf = new TextField();
			text_tf.styleSheet = style;
			text_tf.width = WIDTH;
			text_tf.x = PADDING;
			text_tf.y = PADDING;
			text_tf.antiAliasType = AntiAliasType.ADVANCED;
			text_tf.htmlText = '';
			text_tf.multiline = true;
			text_tf.wordWrap = true;
			text_tf.addEventListener(TextEvent.LINK, _onLinkClick, false, 0, true);
			
			//allow a reload or copying to the clipboard
			actions_tf = new TextField();
			actions_tf.selectable = true;
			actions_tf.styleSheet = style;
			actions_tf.x = PADDING;
			actions_tf.autoSize = TextFieldAutoSize.LEFT;
			actions_tf.antiAliasType = AntiAliasType.ADVANCED;
			actions_tf.addEventListener(TextEvent.LINK, _onLinkClick, false, 0, true);
			
			extra_tf = new TextField();
			extra_tf.styleSheet = style;
			extra_tf.x = PADDING;
			extra_tf.autoSize = TextFieldAutoSize.LEFT;
			extra_tf.antiAliasType = AntiAliasType.ADVANCED;
			extra_tf.multiline = true;
			extra_tf.wordWrap = true;
			
			var newFormat:TextFormat = new TextFormat();
			newFormat.color = 0x191919;
			newFormat.size = 14;
			newFormat.bold = false;
			newFormat.font = 'Arial';
			newFormat.leftMargin = newFormat.rightMargin = 4;
			newFormat.kerning = true;
			
			send_sp = new Sprite();
			send_sp.buttonMode = true;
			send_sp.useHandCursor = true;
			send_sp.mouseChildren = false;
			
			send_sp.addEventListener(MouseEvent.CLICK, function():void {
				if (!last_returned_error_id) { // then we've not reported this, so
					addErrorMsg('ON SUBMIT, ADDING SESSION DETAILS:\n\n'+session_details);
					addErrorMsg('ON SUBMIT, ADDING BENCHMARK DETAILS:\n\n'+Benchmark.getShortLog());
					if (msgs_at_user_bug_click) {
						addErrorMsg('ON SUBMIT, ADDING MSGS:\n----------------------------------------------------\n\n'+msgs_at_user_bug_click);
					}
					reportError(errorsA.join('\n\n**************************************\n\n'), input_tf.text, false, '', '', ['user']);
				} else {
					API.explainError(last_returned_error_id, input_tf.text);
					if (confirmCallback != null) {
						confirmCallback(true);
					}
				}
				close();
			});
			
			send_tf = new TextField();
			send_tf.styleSheet = style;
			send_tf.antiAliasType = AntiAliasType.ADVANCED;
			send_tf.autoSize = TextFieldAutoSize.LEFT;
			send_tf.multiline = false;
			send_tf.wordWrap = false;
			send_tf.border = true;
			send_tf.background = true;
			send_sp.addChild(send_tf);
			
			send_tf.text = '<p>Send</p>';
			
			label_tf = new TextField();
			label_tf.styleSheet = style;
			label_tf.x = PADDING;
			label_tf.antiAliasType = AntiAliasType.ADVANCED;
			label_tf.autoSize = TextFieldAutoSize.LEFT;
			label_tf.multiline = true;
			label_tf.wordWrap = true;
			
			input_tf = new TextField();
			input_tf.antiAliasType = AntiAliasType.ADVANCED;
			input_tf.type = TextFieldType.INPUT;
			input_tf.selectable = true;
			input_tf.multiline = false;
			input_tf.wordWrap = true;
			input_tf.backgroundColor = 0xffffff;
			input_tf.background = true;
			input_tf.border = true;
			input_tf.borderColor = 0x000000;
			input_tf.name = '_input_tf';
			input_tf.height = 50;
			input_tf.width = WIDTH;
			input_tf.x = PADDING;
			
			input_tf.defaultTextFormat = newFormat;
		}
		
		private static function _createHolder():void {
			holder = new Sprite();
			holder.addChild(text_tf);
			holder.addChild(actions_tf);
			if (!fvm || !fvm.disable_bug_reporting) {
				holder.addChild(input_tf);
				holder.addChild(send_sp);
			}
			holder.addChild(label_tf);
			holder.addChild(extra_tf);
			
			onTopTimer = new Timer(2000);
			onTopTimer.addEventListener(TimerEvent.TIMER, _keepHolderOnTop);
		}
		
		private static function _keepHolderOnTop(e:Event=null):void {
			if (holder.parent) holder.parent.addChild(holder);
		}
		
		private static function _createStyleSheet():void {
			style = new StyleSheet();
			style.parseCSS('p { font-size:12px; font-family:"Arial"; }'+
							'.gray { font-size:12px; font-family:"Arial"; color:#999999}'+
							'h1 { font-size:22px; font-weight:bold; font-family:"Arial"; }'+
							'a:link { text-decoration:none; color:#55aae5; }'+
							'a:hover { text-decoration:underline; }');
		}
		
		private static function _onLinkClick(event:TextEvent):void {
			switch(event.text){
				case 'update':
					navigateToURL(new URLRequest('/help/cases/'), '_blank');
					close();
					break;
				case 'copy':
					//copy it to the clipboard and rewrite the text to say it was done
					toClipboard();
					break;
				case 'reload':
					URLUtil.reload();
					break;
				case 'close':
					close();
					break;
			}
		}
		
		private static function close():void {
			user_initiated = false;
			errorsA.length = 0;
			last_returned_error_id = '';
			last_err_str = '';
			is_bug_open = false;
			if (holder.parent) holder.parent.removeChild(holder);
			onTopTimer.stop();
		}
		
		private static function toClipboard():void {
			// this puts all logged errors in the clipboard, not just the current one
			
			//this is here because Flash can't handle the \r\n stuff
			var str:String = "";
			for(var i:int = 0; i < errorsA.length; i++){
				str += errorsA[int(i)] + "\r\r";
			}
			
			System.setClipboard(str);
			
			actions_tf.htmlText = '<p>Text Copied | '+
								   '<a href="event:reload">Reload page</a> | <a href="event:close">Close</a></p>';
		}
		
		private static function setFocusToInputTF():void {
			input_tf.setSelection(0,0); //why no work?
			StageBeacon.stage.focus = input_tf;
		}
		
		private static function get session_details():String {
			return (
				spacify('CURRENT GS:   ') + most_recent_gs + '\n' +
				spacify('CLIENT IP:    ') + fvm.client_ip + '\n' +
				spacify('BOOTSTRAP:    ') + Version.revision + '\n' +
				spacify('ENGINE:       ') + (mainView ? mainView.engineVersion : 'n/a') + '\n' +
				spacify('GOD:          ') + (CONFIG::god) + '\n' +
				spacify('URL:          ') + ExternalInterface.call('window.location.href.toString') + '\n' +
				spacify('TIME:         ') + StringUtil.msToHumanReadableTime(getTimer()) + '\n' +
				spacify('PING:         ') + ping + '\n' +
				spacify('FOCUS:        ') + focus_details + '\n' +
				spacify('CAMERA:       ') + camera_details + '\n' +
				spacify('KEYS DOWN:    ') + KeyBeacon.instance.getKeysDownReport() + '\n' +
				spacify('SCROLL:       ') + scroll_details + '\n' +
				spacify('RENDERER:     ') + (mainView ? mainView.currentRendererForBootError : 'n/a') + '\n' +
				spacify('PERFORMANCE:  ') + ((mainView && mainView.performanceGraph) ? mainView.performanceGraph.toString() : 'n/a') + '\n' +
				spacify('CAPABILITIES: ') + Capabilities.serverString + '\n' +
				spacify('ASSETS:       ') + (mainView ? mainView.assetDetailsForBootError : 'n/a') + '\n' +
				spacify('TWEEN ENGINE: ') + (fvm.use_tweenmax ? 'TweenMax' : 'Tweener') + '\n' +
				spacify('NEWBIE:       ') + 'has_not_done_intro:'+fvm.has_not_done_intro + ' is_stub_account:'+fvm.is_stub_account + '\n' +
				spacify('ASSETLOADING: ') + (mainView ? mainView.assetLoadingReport : SmartThreader.load_report)
			);
		}
		
		private static function primePerformanceGraph():void {
			if (mainView) mainView.primePerformanceGraph();
		}
		
		private static function spacify(str:String):String {
			return str.replace(/ /g, '&nbsp;');
		}
		
		public static function reportPing(ms:Number):void {
			ping = ms;
		}
	}
}