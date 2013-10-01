package  {
	
	import caurina.transitions.Tweener;
	
	import com.adobe.serialization.json.JSON;
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.data.AvatarAnimationDefinitions;
	import com.tinyspeck.core.data.FlashVarData;
	import com.tinyspeck.debug.API;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.pc.AvatarConfig;
	import com.tinyspeck.engine.loader.AvatarConfigRecord;
	import com.tinyspeck.engine.loader.AvatarResourceManager;
	import com.tinyspeck.engine.spritesheet.AvatarSSManager;
	import com.tinyspeck.engine.spritesheet.SSAbstractSheet;
	import com.tinyspeck.engine.spritesheet.SSMultiBitmapSheet;
	import com.tinyspeck.engine.spritesheet.SSViewSprite;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.PNGUtil;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.system.fscommand;
	import flash.utils.getTimer;
	
	[SWF(width='900', height='900', backgroundColor='#c3c3c3', frameRate='120')]
	public class AvatarSheetMaker extends MovieClip {
		Security.allowDomain("*");
		
		[Embed(source="../../TSEngineAssets/src/assets/swfs/spinner.swf")] private var Spinner:Class;
		
		private var holder:Sprite = new Sprite();
		private var ava_config:Object = {};
		private var flashvars:Object;
		private var spinner:MovieClip;
		private var avatar_url:String;
		private var ss_view:SSViewSprite;
		private var ss:SSAbstractSheet;
		private var build_synch:Boolean;
		
		private var sheets_to_make:Array = [];
		private var doing_default:Boolean;
		private var ss_save_singles:Boolean;
		private var ss_post_args:Object;
		private var ss_singles_post_url:String;
		private var ss_sheets_post_url:String;
		
		public function AvatarSheetMaker() { 
			// disable yellow tabbing rectangle
			stage.stageFocusRect = false;
			stage.showDefaultContextMenu = false;
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			init();
		}

		private function init():void {
			flashvars = LoaderInfo(root.loaderInfo).parameters;
			command = flashvars.command;
			
			const fvm:FlashVarModel = new FlashVarModel(FlashVarData.createFlashVarData(this));
			StageBeacon.init(stage, fvm);
			CONFIG::debugging {
				Console.setOutput(Console.FIREBUG, false);
			}

			this.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, handleGlobalErrors);
			
			if (command) {
				CONFIG::debugging {
					Console.setOutput(Console.TRACE, true);
					Console.setPri(flashvars.pri || '0');
				}
				
				// how many frames to play per swf frame
				AvatarSSManager.times = parseInt(flashvars.pri) || 10;
			} else {
				CONFIG::debugging {
					Console.setOutput(Console.FIREBUG, true);
					Console.setOutput(Console.TRACE, true);
					Console.setPri(EnvironmentUtil.getUrlArgValue('pri') || '0');
				}
				
				// how many frames to play per swf frame
				AvatarSSManager.times = EnvironmentUtil.getUrlArgValue('SWF_ss_times') ? parseInt(EnvironmentUtil.getUrlArgValue('SWF_ss_times')) : 10;
			}
			
			spinner = new Spinner();
			
			AvatarSSManager.init('');
			
			avatar_url = flashvars.avatar_url;
			AvatarResourceManager.avatar_url = avatar_url;
			
			//Console.dir(flashvars);
			//Console.info(flashvars.ava_config_json);
			
			if (flashvars.use_fake_config) flashvars.ava_config_json = '{"ver":"01.01.11","articles":{"hat":{"package_swf_url":"","article_class_name":"none"},"coat":{"package_swf_url":"","article_class_name":"none"},"shirt":{"package_swf_url":"","article_class_name":"none"},"pants":{"package_swf_url":"","article_class_name":"none"},"dress":{"article_class_name":"post_it_note_dress","colors":{"color_1":{"tintColor":"EEFF00","brightness":"0","saturation":"0","contrast":"2","tintAmount":"33","alpha":"100"},"color_2":{"tintColor":"FFCFFC","brightness":"0","saturation":"0","contrast":"0","tintAmount":"100","alpha":"100"},"color_3":{"tintColor":"D4E0FF","brightness":"0","saturation":"0","contrast":"0","tintAmount":"100","alpha":"100"},"color_4":{"tintColor":"FFD391","brightness":"0","saturation":"0","contrast":"0","tintAmount":"100","alpha":"100"},"color_5":{"tintColor":"FFDBA6","brightness":"0","saturation":"0","contrast":"0","tintAmount":"100","alpha":"100"}},"package_swf_url":"http:\/\/c2.glitch.bz\/avatar\/base\/1300924061.swf"},"skirt":{"package_swf_url":"","article_class_name":"none"},"shoes":{"article_class_name":"mountain_stripe_sneakers","colors":{"color_1":{"tintColor":"00FF00","brightness":"8","saturation":"0","contrast":"43","tintAmount":"0","alpha":100},"color_2":{"tintColor":"FF3300","brightness":"0","saturation":"0","contrast":"28","tintAmount":"95","alpha":100},"color_3":{"tintColor":"FF3612","brightness":"0","saturation":"0","contrast":"0","tintAmount":"100","alpha":100},"color_4":{"tintColor":"00C4FF","brightness":"0","saturation":"0","contrast":"0","tintAmount":"100","alpha":100}},"package_swf_url":"http:\/\/c2.glitch.bz\/avatar\/base\/1300924061.swf"},"eyes":{"article_class_name":"eyes_20101109C","package_swf_url":"http:\/\/c2.glitch.bz\/avatar\/base_face\/1300398037.swf"},"ears":{"article_class_name":"ears_0002","package_swf_url":"http:\/\/c2.glitch.bz\/avatar\/starter_face\/1300398078.swf"},"nose":{"article_class_name":"nose_0010","package_swf_url":"http:\/\/c2.glitch.bz\/avatar\/starter_face\/1300398078.swf"},"mouth":{"article_class_name":"mouth_01","package_swf_url":"http:\/\/c2.glitch.bz\/avatar\/base_face\/1300398037.swf"},"hair":{"article_class_name":"hair_20101116G","package_swf_url":"http:\/\/c2.glitch.bz\/avatar\/base_face\/1300398037.swf"}},"eye_scale":0.958,"eye_height":-1.64,"eye_dist":-1.5266666666667,"ears_scale":0.656,"ears_height":1,"nose_scale":1.45,"nose_height":-1.2666666666667,"mouth_scale":0.95533333333333,"mouth_height":1.64,"hair_tint_color":"ffc750","hair_colors":{"color_1":{"tintColor":"FFB554","tintAmount":"100","brightness":"-54","saturation":"-24","contrast":"-4","alpha":"100"},"color_10":{"tintColor":"FAC446","tintAmount":"32","brightness":"-100","saturation":"100","contrast":"74","alpha":"88"}},"skin_tint_color":"3A6351","skin_colors":{"color_1":{"tintColor":"3A6351","tintAmount":"100","brightness":"0","saturation":"0","contrast":"0","alpha":"100"},"color_2":{"tintColor":"FFFFFF","tintAmount":"0","brightness":"0","saturation":"0","contrast":"0","alpha":"100"},"color_10":{"tintColor":"FFFFFF","tintAmount":"0","brightness":"0","saturation":"0","contrast":"0","alpha":"100"}}}';
			
			if (flashvars.ava_config_json) {
				ava_config = com.adobe.serialization.json.JSON.decode(flashvars.ava_config_json);
				//Console.info('ava_config: '+typeof ava_config);
				//Console.dir(ava_config);
				if (typeof ava_config != 'object' || !ava_config) ava_config = {};
			}
			
			doing_default = (ava_config.placeholder);
			
			API.setPcTsid('AvatarSheetMaker');
			API.setAPIUrl(flashvars.api_url, flashvars.api_token);
			PNGUtil.setAPIUrl(flashvars.api_url, flashvars.api_token);
			
			hideSpinner();
			
			holder.name = 'holder';
			holder.x = stage.stageWidth/2;
			holder.y = 0;
			addChild(holder);

			CONFIG::debugging {
				Console.info('animations available: '+AvatarAnimationDefinitions.getSheetedAnimsA());
			}
			
			if (!command) {
				ExternalInterface.addCallback('setFPS', setFPS);
				ExternalInterface.addCallback('saveBase', saveBase);
				ExternalInterface.addCallback('saveAllSheets', saveAllSheets);
				ExternalInterface.addCallback('saveAllSingles', saveAllSingles);
			}
			
			addChild(spinner);

			; // satisfy compiler
			CONFIG::debugging {
				Console.info('loading '+avatar_url);
			}
			loadAvatar(avatar_url, function(ava_loader:Loader):void {
				CONFIG::debugging {
					Console.info('loaded '+avatar_url);
				}
				AvatarSSManager.run(MovieClip(ava_loader.content), afterSSAvaLoad);
				
				if (flashvars.avatar_ready_callback_name) {
					ExternalInterface.call(flashvars.avatar_ready_callback_name);
				}
				
				if (command) {
					doCommand();
				}
			});
		}
		
		private var command:String;
		private function doCommand():void {
			
			if (!flashvars.ava_config_json) {
				die('no ava_config_json in flashvars');
				return;
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.info('flashvars.ava_config_json: '+flashvars.ava_config_json);
				}
			}
			
			if (command == 'save_all_singles' || command == 'save_all_pngs') {
				var post_args_singles:Object;
				if (!flashvars.post_args_singles) {
					die('no post_args_singles in flashvars');
					return;
				}
				
				try {
					post_args_singles = com.adobe.serialization.json.JSON.decode(flashvars.post_args_singles);
				} catch(err:Error) {
					die('invalid post_args_singles, could not decode: '+err);
					return;
				}
				
				if (typeof post_args_singles != 'object') {
					die('invalid post_args_singles: '+flashvars.post_args_singles);
					return;
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.info('flashvars.post_args_singles: '+flashvars.post_args_singles);
					}
				}
				
			}
			
			if (command == 'save_all_sheets' || command == 'save_all_pngs') {
				var post_args_sheets:Object;
				if (!flashvars.post_args_sheets) {
					die('no post_args_sheets in flashvars');
					return;
				}
				
				try {
					post_args_sheets = com.adobe.serialization.json.JSON.decode(flashvars.post_args_sheets);
				} catch(err:Error) {
					die('invalid post_args_sheets, could not decode: '+err);
					return;
				}
				
				if (typeof post_args_sheets != 'object') {
					die('invalid post_args_sheets: '+flashvars.post_args_sheets);
					return;
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.info('flashvars.post_args_sheets: '+flashvars.post_args_sheets);
					}
				}
				
			}
			
			CONFIG::debugging {
				Console.info('flashvars.post_url: '+flashvars.post_url);
				Console.info('flashvars.command: '+command);
			}
			
			if (command == 'save_all_sheets') {
				
				saveAllSheets(flashvars.ava_config_json, flashvars.post_url, post_args_sheets);
				
			} else if (command == 'save_all_singles') {
				
				saveAllSingles(flashvars.ava_config_json, flashvars.post_url, post_args_singles);
				
			} else if (command == 'save_all_pngs') {
				
				saveAllSheets(flashvars.ava_config_json, flashvars.post_url, post_args_sheets);
				
				afterSavingSheetsWhenSavingAllPngs = function():void {
					saveAllSingles(flashvars.ava_config_json, flashvars.post_url, post_args_singles);
				}
				
			} else {
				
				die('unknown command: '+command);
				return;
				
			}
		}
		
		private var afterSavingSheetsWhenSavingAllPngs:Function;
		
		private function die(log:String):void {
			; // satisfy compiler
			CONFIG::debugging {
				Console.info('DIE: '+log);
			}
			fscommand('quit');
		}
		
		private function handleGlobalErrors(e:UncaughtErrorEvent):void {
			if (e.error) {
				if (e.error.getStackTrace) {
					CONFIG::debugging {
						Console.error(e.error.getStackTrace());
					}
				} else {
					CONFIG::debugging {
						Console.error(e.error);
					}
				}
			} else {
				CONFIG::debugging {
					Console.error(e);
				}
			}
			
			try {
				BootError.handleGlobalErrors(e);
			} catch (err:Error) {
				CONFIG::debugging {
					Console.error('error calling BootError.handleGlobalErrors: '+err);
				}
			}
			
			if (command) fscommand('quit');
			
			StageBeacon.setTimeout(function():void {
				if (flashvars.rte_callback_name) {
					ExternalInterface.call(flashvars.rte_callback_name);
				}
			}, 5000)
		}
		
		// functions to be called by JS
		//////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		private function setFPS(i:int):void {
			stage.frameRate = Math.max(0, Math.min(24, i));
			CONFIG::debugging {
				Console.info('stage.frameRate:'+stage.frameRate)
			}
		}
		
		private function saveAllSingles(new_ava_config_json:*, singles_post_url:String='', post_args:Object=null):void {
			PNGUtil.cleanBms();
			ss_save_singles = true;
			ss_post_args = post_args;
			ss_singles_post_url = singles_post_url;

			CONFIG::debugging {
				Console.info('new_ava_config_json:'+new_ava_config_json);
				Console.info('ss_singles_post_url:'+ss_singles_post_url);
				Console.dir(post_args);
			}
			
			if (!setAvaConfig(new_ava_config_json)) {
				CONFIG::debugging {
					Console.error('count not set state with '+new_ava_config_json);
				}
				ss_save_singles = false;
				return;
			}
		}
		
		private function saveBase(new_ava_config_json:*, sheets_post_url:String='', post_args:Object=null):void {
			savePngSheets(['base'], new_ava_config_json, sheets_post_url, post_args);
		}
		
		private function saveAllSheets(new_ava_config_json:*, sheets_post_url:String='', post_args:Object=null):void {
			savePngSheets(AvatarAnimationDefinitions.sheetsA.concat(), new_ava_config_json, sheets_post_url, post_args);
		}
		
		private var save_sheets_start:int;
		private function savePngSheets(sheetsA:Array, new_ava_config_json:*, sheets_post_url:String='', post_args:Object=null):void {
			PNGUtil.cleanBms();
			save_sheets_start = getTimer();
			sheets_to_make = sheetsA;
			ss_post_args = post_args;
			ss_sheets_post_url = sheets_post_url;

			CONFIG::debugging {
				Console.info('new_ava_config_json:'+new_ava_config_json);
				Console.info('ss_sheets_post_url:'+ss_sheets_post_url);
				Console.dir(post_args);
			}
			
			if (!setAvaConfig(new_ava_config_json)) {
				CONFIG::debugging {
					Console.error('count not set state with '+new_ava_config_json);
				}
				sheets_to_make.length = 0;
				return;
			}
		}
		
		// functions for when done saving
		//////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		private function saveSheetsCallback(ok:Boolean, txt:String = ''):void {
			CONFIG::debugging {
				Console.info((getTimer()-save_sheets_start)+'ms elapsed: saved sheets');
			}
			
			if (command) {
				if (command == 'save_all_sheets') {
					CONFIG::debugging {
						if (ok) {
							Console.info('go go go');
						} else {
							Console.error('no no no '+txt);
						}
					}
					die('done saving sheets');
					return;
				} else {
					CONFIG::debugging {
						Console.info('done saving sheets, now saving singles');
					}
					afterSavingSheetsWhenSavingAllPngs();
					return;
				}
			}
			
			var rsp_json:Object;
			try {
				rsp_json = com.adobe.serialization.json.JSON.decode(txt);
			} catch(err:Error) {
				rsp_json = {};
			}
			if (flashvars.save_sheets_callback_name) {
				ExternalInterface.call(flashvars.save_sheets_callback_name, ok, rsp_json);
			}
		}
		
		private function saveSinglesCallback(ok:Boolean, txt:String = ''):void {
			if (command) {
				// no matter what the command, after this we are done
				CONFIG::debugging {
					if (ok) { 
						Console.info('go go go');
					} else {
						Console.error('no no no '+txt);
					}
				}
				die('done saving singles');
				return;
			}
			
			var rsp_json:Object;
			try {
				rsp_json = com.adobe.serialization.json.JSON.decode(txt);
			} catch(err:Error) {
				rsp_json = {};
			}
			if (flashvars.save_singles_callback_name) {
				ExternalInterface.call(flashvars.save_singles_callback_name, ok, rsp_json);
			}
		}
		
		// OTHER
		//////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		private function afterSSAvaLoad():void {
			StageBeacon.enter_frame_sig.add(AvatarSSManager.onEnterFrame);
			makeSS();
		}
		
		private function makeSS():void {
			//Console.info('makeSS '+current_ac);
			
			if (!current_ac && EnvironmentUtil.getUrlArgValue('SWF_induce_err') != '1') return; // this can happen when it is the default avatar, which happens onload; let's just ignore it
			
			ss = AvatarSSManager.getSSForAva(current_ac, '');
			
			if (ss == AvatarSSManager.default_ss && !doing_default) {
				ss = null;
				return;
			} 
			
			setUpSS();
		}
		
		private function setUpSS():void {
			var was_ss_view:SSViewSprite = ss_view;
			
			ss_view = ss.getViewSprite();
			ss_view.y = stage.stageHeight-160;
			
			Tweener.addTween(was_ss_view, {alpha:0, transition:'linear', time:.6, onComplete:function():void {
				if (was_ss_view.parent) was_ss_view.parent.removeChild(was_ss_view);
			}});
			
			onSSReady();
			
			var anims:Array = ['idle0'];
			
			if (!build_synch) {
				if (sheets_to_make.length) {
					anims = [];
					for (var i:int=0;i<sheets_to_make.length;i++) {
						anims = anims.concat(AvatarAnimationDefinitions.getAnimsForSheet(sheets_to_make[int(i)]));
					}
				}
			}
			
			holder.addChild(ss_view);

			CONFIG::debugging {
				Console.info('playing '+anims);
			}
			
			AvatarSSManager.playSSViewSequenceForAva(current_ac, '', ss_view, ss_view.gotoAndPlaySequence, anims, onSSSequenceDone);
			
			// just go ahead and save!
			if (build_synch) {
				StageBeacon.waitForNextFrame(saveSheets);
			}
		}
		
		private function onSSReady():void {
			if (flashvars.avatar_ss_ready_callback_name) {
				ExternalInterface.call(flashvars.avatar_ss_ready_callback_name);
			}
			
			//Console.info('onSSReady');
		}
		
		private function onSSSequenceDone(finished:Boolean):void {
			CONFIG::debugging {
				Console.info('done sequence');
			}
			if (finished && !build_synch) saveSheets();
		}
		
		private function saveSheets():void {
			if (sheets_to_make.length) {
				CONFIG::debugging {
					Console.info('saveSheets');
					Console.info((getTimer()-save_sheets_start)+'ms elapsed: built frames');
				}
				
				var bmdsH:Object = {};
				var sheet_bmd:BitmapData;
				
				// remove the last bms we showed
				clearSheetBms();
				
				for (var i:int=0;i<sheets_to_make.length;i++) {
					sheet_bmd = makeSheetBitmap(sheets_to_make[int(i)]);
					if (sheet_bmd) {
						ss_view.visible = false;
						bmdsH['image_'+sheets_to_make[int(i)]] = sheet_bmd;
					} else {
						CONFIG::debugging {
							Console.warn('no sheet_bmd');
						}
						return;
					}
				}

				; // satisfy compiler
				CONFIG::debugging {
					Console.info((getTimer()-save_sheets_start)+'ms elapsed: built sheets');
				}
				PNGUtil.savePngSheets(bmdsH, ss_post_args, ss_sheets_post_url, saveSheetsCallback);
				
				sheets_to_make.length = 0;
			}
		}
		
		private function hideSpinner():void {
			spinner.visible = false;
			spinner.x = -100;
			spinner.y = -100;
		}
		
		private function showSpinner():void {
			spinner.visible = true;
			spinner.x = Math.round((stage.stageWidth-spinner.width)/2);
			spinner.y = Math.round((stage.stageHeight-spinner.height)/2);
		}
		
		private function loadAvatar(url:String, completeFunc:Function):void {
			var ava_loader:Loader = new Loader();
			var loaderContext:LoaderContext = new LoaderContext(false,new ApplicationDomain(ApplicationDomain.currentDomain), null);
			ava_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void{completeFunc(ava_loader)});
			ava_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function():void{});
			ava_loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, function():void{});
			
			ava_loader.load(new URLRequest(url), loaderContext);
			if (CONFIG::debugging) {
				Console.log(66, url);
			}
		}
		
		private function setAvaConfig(new_ava_config_json:*):Boolean {
			if (new_ava_config_json is String) {
				try {
					ava_config = com.adobe.serialization.json.JSON.decode(new_ava_config_json);
				} catch(err:Error) {
					return false;
				}
			} else {
				ava_config = new_ava_config_json;
			}
			
			if (!ava_config) ava_config = {};

			doing_default = (ava_config.placeholder);
			
			if (typeof ava_config == 'object') {
				//Console.dir(ava_config);
				initializeHead();
				return true;
			}
			
			return false;
		}
		
		private var current_ac:AvatarConfig;
		private function initializeHead():void {
			if (current_ac && ss_view) {
				AvatarSSManager.removeSSViewforAva(current_ac, '', ss_view);
				ss_view.stop();
				if (ss_view.parent) ss_view.parent.removeChild(ss_view);
				clearSheetBms();
				ss_view = null;
			}
			
			current_ac = AvatarConfig.fromAnonymous(ava_config);
			var acr:AvatarConfigRecord = AvatarResourceManager.instance.getAvatarConfigRecord(current_ac, AvatarSSManager.ava_swf);

			CONFIG::debugging {
				Console.info('initializeHead acr.ready:'+acr.ready);
			}
			if (!acr.ready) {
				showSpinner();
				spinner.alpha = 0;
				Tweener.removeTweens(spinner);
				Tweener.addTween(spinner, {alpha:1, time:.6, delay:.3});
				//Console.warn('ac is not ready, can't snap yet');
				
				acr.addCallback(function(ac:AvatarConfig):void {
					if (current_ac.sig == ac.sig) {
						acrReadyCallback();
					} else {
						; // satisfy compiler
						CONFIG::debugging {
							Console.priwarn(89, ac.sig+' IS NOT '+current_ac.sig);
						}
					}
				});
			} else {
				acrReadyCallback();
			}
		}
		
		private function boolFromFlashvar(name:String):Boolean {
			return (flashvars.hasOwnProperty(name) && (flashvars[name] == true || flashvars[name].toString().toLowerCase() == 'true'));
		}
		
		private var ss_timer:int;
		private function acrReadyCallback():void {
			hideSpinner();
			CONFIG::debugging {
				Console.info('acrReadyCallback ss_save_singles:'+ss_save_singles);
			}
			
			CONFIG::debugging {
				if (sheets_to_make.length) Console.info((getTimer()-save_sheets_start)+'ms elapsed: avatar assets readied');
			}
			
			if (ss_timer) {
				StageBeacon.clearTimeout(ss_timer);
			}
			
			if (ss_save_singles) {
				PNGUtil.saveSinglesFromAvatarMc(ss_post_args, ss_singles_post_url, AvatarSSManager.ava_swf, current_ac, saveSinglesCallback);
				ss_save_singles = false;
			}
			
			// timeout can be immediate if we're doing lazy SS generation
			// ss_timer = StageBeacon.setTimeout(makeSS, (!build_synch) ? 0 : 100);
			
			makeSS();
		} 
		
		private var sheet_bmsA:Array = [];
		private function makeSheetBitmap(sheet:String):BitmapData {
			
			var sheet_bmd:BitmapData = AvatarSSManager.makeSheetBitmap(SSMultiBitmapSheet(ss), sheet);
			if (sheet_bmd) { 
				// add the bm to the stage
				var sheet_bm:Bitmap = new Bitmap(sheet_bmd);
				sheet_bm.smoothing = true;
				sheet_bm.width = Math.min(sheet_bm.width, stage.stageWidth);
				sheet_bm.scaleY = sheet_bm.scaleX;
				sheet_bm.x = 0;
				if (sheet_bmsA.length) {
					sheet_bm.y = sheet_bmsA[sheet_bmsA.length-1].y+sheet_bmsA[sheet_bmsA.length-1].height;
				}
				
				addChild(sheet_bm);
				sheet_bmsA.push(sheet_bm);
			}
			
			return sheet_bmd;
		}
		
		private function clearSheetBms():void {
			var sheet_bm:Bitmap;
			for (var i:int=0;i<sheet_bmsA.length;i++) {
				sheet_bm = sheet_bmsA[int(i)];
				if (sheet_bm && sheet_bm.parent) sheet_bm.parent.removeChild(sheet_bm);
			}
			sheet_bmsA.length = 0;
		}
	}
}