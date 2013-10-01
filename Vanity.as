package {
	import caurina.transitions.Tweener;
	
	import com.adobe.serialization.json.JSON;
	import com.tinyspeck.bootstrap.BootUtil;
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.data.AvatarSwfParticulars;
	import com.tinyspeck.core.data.FlashVarData;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.pc.AvatarConfig;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.loader.AvatarConfigRecord;
	import com.tinyspeck.engine.loader.AvatarResourceManager;
	import com.tinyspeck.engine.loader.SmartLoader;
	import com.tinyspeck.engine.loader.SmartURLLoader;
	import com.tinyspeck.engine.memory.EnginePools;
	import com.tinyspeck.engine.model.TSEngineConstants;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.spritesheet.AvatarSSManager;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.ObjectUtil;
	import com.tinyspeck.engine.util.PNGUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.loadedswfs.AvatarSwf;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	import com.tinyspeck.vanity.ColorsVanityTabPane;
	import com.tinyspeck.vanity.DimsPane;
	import com.tinyspeck.vanity.FeaturesVanityTabPane;
	import com.tinyspeck.vanity.HatVanityDialog;
	import com.tinyspeck.vanity.LeavingVanityDialog;
	import com.tinyspeck.vanity.LoadingVanityDialog;
	import com.tinyspeck.vanity.SavingVanityDialog;
	import com.tinyspeck.vanity.SubscribeFreePromptVanityDialog;
	import com.tinyspeck.vanity.SubscribePayPromptVanityDialog;
	import com.tinyspeck.vanity.SubscribedVanityDialog;
	import com.tinyspeck.vanity.VanityMirror;
	import com.tinyspeck.vanity.VanityModel;
	
	import flash.display.Bitmap;
	import flash.display.BlendMode;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.text.TextField;
	
	public class Vanity extends Sprite {
		
		private var standalone:Boolean;
		private var new_skin_coloring:Boolean;
		
		private var www_pngs_str:String;

		private var cssLoader:SmartURLLoader;
		private var avaConfigLoader:SmartURLLoader;
		private var optionsLoader:SmartURLLoader;
		private var subscribeLoader:SmartURLLoader;
		private var saveWardrobeLoader:SmartURLLoader;
		private var saveFaceLoader:SmartURLLoader;
		private var ava_loader:SmartLoader;
		
		private var ava_swf:AvatarSwf;
		private var current_ac:AvatarConfig;
		
		private var load_steps:int;
		private var current_load_step:int;
		
		private var w:int;
		private var h:int;
		
		private var vanity_mirror:VanityMirror;
		private var features_pane:FeaturesVanityTabPane;
		private var colors_pane:ColorsVanityTabPane;
		private var dims_pane:DimsPane;
		
		private var blocker_sp:Sprite = new Sprite();
		
		private var loading_sp:Sprite = new Sprite();
		private var loading_dialog:LoadingVanityDialog;
		//private var loading_pb:ProgressBar = new ProgressBar(200, 20);
		
		private var content_sp:Sprite = new Sprite();
		
		private var saving_sp:Sprite = new Sprite();
		private var saving_dialog:SavingVanityDialog;
		
		private var subbed_sp:Sprite = new Sprite();
		private var subbed_dialog:SubscribedVanityDialog;
		
		private var sub_free_sp:Sprite = new Sprite();
		private var sub_free_dialog:SubscribeFreePromptVanityDialog;
		
		private var sub_pay_sp:Sprite = new Sprite();
		private var sub_pay_dialog:SubscribePayPromptVanityDialog;
		
		private var leaving_sp:Sprite = new Sprite();
		private var leaving_dialog:LeavingVanityDialog;
		
		private var hat_sp:Sprite = new Sprite();
		private var hat_dialog:HatVanityDialog;
		
		private var bt_that_trigger_sub:Sprite;
		private var logo_sp:Sprite = new Sprite();
		private var home_tf:TextField = new TextField();
		
		public function Vanity() {
			// disable yellow tabbing rectangle
			stage.stageFocusRect = false;
			
			init();
		}
		
		private function handleGlobalErrors(e:UncaughtErrorEvent):void {
			if (e.error) {
				if (e.error.getStackTrace) {
					;
					CONFIG::debugging {
						Console.error(e.error.getStackTrace());
					}
				} else {
					;
					CONFIG::debugging {
						Console.error(e.error);
					}
				}
			} else {
				;
				CONFIG::debugging {
					Console.error(e);
				}
			}
		}
		
		private function init():void {
			this.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, handleGlobalErrors);
			const fvm:FlashVarModel = new FlashVarModel(FlashVarData.createFlashVarData(this));
			StageBeacon.init(stage, fvm);
			EnginePools.init();
			
			AvatarSSManager.init('');
			
			logo_sp.useHandCursor = logo_sp.buttonMode = true;
			logo_sp.visible = false;
			logo_sp.addEventListener(MouseEvent.CLICK, onLogoClick, false, 0, true);
			stage.addChild(logo_sp);
			
			TFUtil.prepTF(home_tf, false);
			home_tf.embedFonts = false;
			home_tf.htmlText = '<span class="vanity_nav"><a href="event:wardrobe" class="vanity_nav_link"> Wardrobe</a>&nbsp;&nbsp;|&nbsp;&nbsp;<a href="event:home" class="vanity_nav_link">Return to Site</a></span>';
			home_tf.addEventListener(TextEvent.LINK, onTextLinkClick, false, 0, true);
			logo_sp.addChild(home_tf);
			
			content_sp.visible = false;
			content_sp.blendMode = BlendMode.LAYER;
			addChild(content_sp);
			
			blocker_sp.visible = false;
			blocker_sp.alpha = 0;
			addChild(blocker_sp);
			
			addChild(loading_sp);
			
			saving_sp.visible = false;
			addChild(saving_sp);
			
			subbed_sp.visible = false;
			addChild(subbed_sp);
			
			sub_free_sp.visible = false;
			addChild(sub_free_sp);
			
			sub_pay_sp.visible = false;
			addChild(sub_pay_sp);
			
			leaving_sp.visible = false;
			addChild(leaving_sp);
			
			hat_sp.visible = false;
			addChild(hat_sp);
			
			var fvd:FlashVarData = FlashVarData.createFlashVarData(this);
			standalone = fvd.getFlashvar('standalone') == 'true';
			new_skin_coloring = fvd.getFlashvar('new_skin_coloring') == 'true';
			www_pngs_str = fvd.getFlashvar('www_pngs');
			
			if (standalone) {
				stage.align = StageAlign.TOP_LEFT;
				stage.scaleMode = StageScaleMode.NO_SCALE;
				stage.frameRate = TSEngineConstants.TARGET_FRAMERATE;
				var base_w:int = 960;
				var base_h:int = 600;
				go(base_w, base_h, new FlashVarModel(fvd));
				
				function onStageResize():void {
					var widthScale:Number = stage.stageWidth / base_w; // base_w is the original width of the swf, you should replace it with your width
					scaleX = scaleY = widthScale;
					logo_sp.scaleX = logo_sp.scaleY = widthScale;
				}
				
				StageBeacon.resize_sig.add(onStageResize);
				onStageResize();
			}
		}
		
		// called from here if running as standalone
		// called from client if loaded as module
		public function go(w:int, h:int, fvm:FlashVarModel, mc:MovieClip = null):void {
			this.w = w;
			this.h = h;
			
			AvatarResourceManager.avatar_url = fvm.avatar_url;
			VanityModel.fvm = fvm;
			VanityModel.ava_settings = fvm.ava_settings;
			//Console.dir(fvm.ava_settings);
			
			drawBlocker(blocker_sp.graphics);
			
			//loading_sp.addChild(loading_pb);
			//loading_pb.x = Math.round((w-loading_pb.w)/2);
			//loading_pb.y = Math.round((h-loading_pb.h)/2);
			
			load_steps = 4;
			
			if (www_pngs_str) {
				VanityModel.imgs_to_loadH = (www_pngs_str) ? com.adobe.serialization.json.JSON.decode(www_pngs_str) : [];
				CONFIG::debugging {
					Console.dir(VanityModel.imgs_to_loadH);
				}
			}
			
			for (var k:String in VanityModel.imgs_to_loadH) {
				load_steps++
			}

			if (standalone) {
				load_steps+= 2;
				TSTweener.useEngine(TSTweener.TWEENER);
				// we have to set up stuff ourselves
				BootUtil.setUpAPIAndConsole(fvm);
				PNGUtil.setAPIUrl(fvm.api_url, fvm.api_token);
				addChild(TipDisplayManager.instance);
			} else {
				// we should expect all the relevant data etc to be sent to us
				setMc(mc);
			}
			
			loadBASE64bitmaps();
		}
		
		private var BASE64_loaded:int;
		private function loadBASE64bitmaps():void {
			for each (var bm:Object in VanityModel.base64_bitmaps_to_load_for_preloaderA) {
				AssetManager.instance.loadBitmapFromBASE64(bm.key, bm.str, onBASE64bitmapLoaded);
			}
		}
		
		private function onBASE64bitmapLoaded(key:String, bm:Bitmap):void {
			BASE64_loaded++;
			if (BASE64_loaded == VanityModel.base64_bitmaps_to_load_for_preloaderA.length) {
				doneLoadingBASE64bitmaps();
			}
		}
		
		private function doneLoadingBASE64bitmaps():void {
			if (standalone) {
				loadCSS();
			} else {
				showLoadingDialog();
				loadAvaConfig();
			}
		}
		
		private function setMc(mc:MovieClip):void {
			ava_swf = new AvatarSwf(mc, new_skin_coloring);
		}
		
		private function showProgess(step:int, secs:Number=2):void {
			current_load_step = step;
			//Console.info('perc:'+(current_load_step/load_steps)+' secs:'+secs)
			if (loading_dialog) loading_dialog.pb.updateWithAnimation(secs, current_load_step/load_steps);
		}
		
		private function loadCSS():void {
			showProgess(current_load_step+1, 1);
			cssLoader = new SmartURLLoader('css');
			// these are automatically removed on complete or error:
			cssLoader.complete_sig.add(onCSSLoadComplete);
			//cssLoader.error_sig.add(function():void{});
			
			cssLoader.load(new URLRequest(VanityModel.fvm.css_file));
		}
		
		private function onCSSLoadComplete(loader:SmartURLLoader):void {
			CSSManager.instance.init(loader.data);
			VanityModel.updateFromCSS();
			StaticFilters.updateFromCSS();
			
			content_sp.x = Math.round((w-VanityModel.ui_w)/2);
			
			var bm:Bitmap = AssetManager.instance.getLoadedBitmap('vanity_logo_str');
			if (bm) {
				logo_sp.addChild(bm);
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('We should have this fucker loaded, damnit.');
				}
			}
			logo_sp.x = content_sp.x;
			logo_sp.y = (VanityModel.logo_y);
			
			home_tf.x = VanityModel.ui_w-home_tf.width;
			home_tf.y = Math.round((bm.height-home_tf.height)/2);

			// only called here if is standalone, I believe, since otherwise we already have the css
			showLoadingDialog();
			
			loadAvatar();
		}
		
		private function showLoadingDialog():void {
			loading_dialog = new LoadingVanityDialog();
			loading_dialog.x = Math.round((w-loading_dialog.width)/2);
			loading_dialog.y = Math.round((h-loading_dialog.height)/2);
			loading_sp.addChild(loading_dialog);
		}
		
		private function areChanges():Boolean {
			if (AvatarConfig.fromAnonymous(VanityModel.ava_config).sig != AvatarConfig.fromAnonymous(VanityModel.ava_config_saved).sig) return true;
			return false;
		}
		
		private function onTextLinkClick(event:TextEvent):void {
			if (areChanges()) {
				showLeavingOverlay(false);
				return;
			}
			
			if (event.text == 'wardrobe') {
				exit('/wardrobe/');
			} else if (event.text == 'home') {
				exit('/');
			}
		}
		
		private function onLogoClick(event:Event):void {
			if (event.target is TextField) return; // the tf is handled by onTextLinkClick
			
			if (areChanges()) {
				showLeavingOverlay(false);
				return;
			}
			
			exit();
		}
		
		private function exit(url:String = '/'):void {
			CONFIG::debugging {
				Console.info('exit to '+url);
			}
			navigateToURL(new URLRequest(url), '_self');
		}
		
		private function loadAvatar():void {
			showProgess(current_load_step+1, 2);
			
			ava_loader = new SmartLoader('avatar');
			// these are automatically removed on complete or error:
			ava_loader.complete_sig.add(onAvatarLoadComplete);
			//ava_loader.error_sig.add(function():void{});
			
			var loaderContext:LoaderContext = new LoaderContext(false,new ApplicationDomain(ApplicationDomain.currentDomain), null);
			ava_loader.load(new URLRequest(VanityModel.fvm.avatar_url), loaderContext);
			/*CONFIG::debugging {
				Console.log(66, VanityModel.fvm.avatar_url);
			}*/
		}
		
		private function onAvatarLoadComplete(loader:SmartLoader):void {
			setMc(ava_loader.content as MovieClip);
			loadAvaConfig();
		}
		
		private function loadAvaConfig():void {
			showProgess(current_load_step+1, 1);
			
			if (!ava_swf) {
				CONFIG::debugging {
					Console.error('loadAvaConfig called, but we have no ava_swf');
				}
				return;
			}

			avaConfigLoader = new SmartURLLoader('avaConfig');
			// these are automatically removed on complete or error:
			avaConfigLoader.complete_sig.add(onConfigLoadComplete);
			CONFIG::debugging {
				avaConfigLoader.error_sig.add(
					function (loader:SmartURLLoader):void {
						Console.error('failed to load '+url);
					}
				);
			}
			
			var url:String = VanityModel.fvm.api_url+'simple/avatar.getDetails?ctoken='+VanityModel.fvm.api_token+'&cb='+String(new Date().getTime());
			CONFIG::debugging {
				Console.log(66, url);
			}
			avaConfigLoader.load(new URLRequest(url));
		}
		
		private function onConfigLoadComplete(loader:SmartURLLoader):void {
			var json_str:String = loader.data;
			var rsp:Object = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {};
			
			if (!rsp || !rsp.ok) {
				CONFIG::debugging {
					Console.warn('error loading item info');
				}
				return;
			}
			
			// the one with the db ids
			VanityModel.base_hash = rsp.base_hash;
			VanityModel.base_hash_saved = ObjectUtil.copyOb(VanityModel.base_hash);
			
			// the ava_config
			VanityModel.ava_config = rsp.hash;
			VanityModel.ava_config_saved = ObjectUtil.copyOb(VanityModel.ava_config);
			
			CONFIG::debugging {
				Console.dir(rsp);
			}
			
			loadOptions();
		}
		
		private function loadOptions():void {
			showProgess(current_load_step+1, 1);
			
			if (!ava_swf) {
				CONFIG::debugging {
					Console.error('loadOptions called, but we have no ava_swf');
				}
				return;
			}
			
			optionsLoader = new SmartURLLoader('options');
			// these are automatically removed on complete or error:
			optionsLoader.complete_sig.add(onOptionsLoadComplete);
			
			CONFIG::debugging {
				optionsLoader.error_sig.add(
					function(loader:SmartURLLoader):void {
						Console.error('failed to load '+url);
					}
				);
			}
			
			var url:String = VanityModel.fvm.api_url+'simple/faces.getCatalog?ctoken='+VanityModel.fvm.api_token+'&cb='+String(new Date().getTime());
			CONFIG::debugging {
				Console.log(66, url);
			}
			optionsLoader.load(new URLRequest(url));
		}
		
		private function onOptionsLoadComplete(loader:SmartURLLoader):void {
			var json_str:String = loader.data;
			var rsp:Object = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {};
			
			if (!rsp || !rsp.ok) {
				CONFIG::debugging {
					Console.warn('error loading item info');
				}
				return;
			}
			
			VanityModel.color_options = rsp.colors;
			for (var ctype:String in VanityModel.color_options) {
				for (var id:String in VanityModel.color_options[ctype]) {
					var color:Object = VanityModel.color_options[ctype][id];
					var HSV:Object = ColorUtil.rgb2hsv(ColorUtil.colorStrToNum(color.color));
					color.h = HSV.h;
					color.s = HSV.s;
					color.v = HSV.v;
				}
			}
			
			VanityModel.feature_options = rsp.features;
			
			// add in 0 ('none') options for the non-required features
			for (var type:String in VanityModel.features_required_map) {
				if (VanityModel.features_required_map[type] === false) {
					if (!VanityModel.feature_options[type]['0']) {
						VanityModel.feature_options[type]['0'] = {
							package_url: '',
							article_class_name: 'none'
						}
					}
				} 
			}
			
			CONFIG::debugging {
				Console.dir(rsp);
			}
			
			loadFaceSwfs();
		}
		
		private function loadFaceSwfs():void {
			// let's make options_ava_config a "fake" config record! so we can load all the swfs we need through the arm:AvatarResourceManager
			// and have aca's ready for arm.getArticlePartMC(aca, part_class_name) to display the options
			var collection:Object;
			var option:Object;
			for (var type:String in VanityModel.features_name_map) {
				collection = VanityModel.feature_options[type];
				for (var id:String in collection) {
					option = collection[id];
					VanityModel.options_ava_config.articles[type+id] = {
						article_class_name: option.article_class_name,
						package_swf_url: option.package_url
					}
				}
			}
			
			CONFIG::debugging {
				Console.dir(VanityModel.options_ava_config);
			}
			
			var ac:AvatarConfig = AvatarConfig.fromAnonymous(VanityModel.options_ava_config);
			var acr:AvatarConfigRecord = AvatarResourceManager.instance.getAvatarConfigRecord(ac, ava_swf);
			
			if (!acr.ready) {
				load_steps+=5;
				showProgess(current_load_step+5, 3);
				acr.addCallback(function(ac:AvatarConfig):void {
					onFaceSwfsLoaded();
				});
			} else {
				onFaceSwfsLoaded();
			}
		}
		
		private function onFaceSwfsLoaded():void {
			showProgess(current_load_step+1, 2);
			var c:int;
			for (var k:String in VanityModel.imgs_to_loadH) {
				var url:String = VanityModel.imgs_to_loadH[k];
				if (!url) continue;
				c++
				if (url.indexOf('/img/') == 0) {
					//url = url.replace('/img/', '');
				}
				AssetManager.instance.loadBitmapFromWeb(url, onWWWimgBitmapLoaded, 'onFaceSwfsLoaded()');
			}
			if (!c) {
				//doneLoading();
			}
		}
		
		private function onWWWimgBitmapLoaded(filename:String, bm:Bitmap):void {
			showProgess(current_load_step+1, .5);
			if (current_load_step == load_steps-1) {
				doneLoading();
			}
		}
		
		private function doneLoading():void {
			
			vanity_mirror = new VanityMirror(ava_swf, doReset, doSave, doAnimation);
			vanity_mirror.x = Math.round((VanityModel.ui_w-VanityModel.mirror_column_w)/2);
			vanity_mirror.y = VanityModel.mirror_y;
			content_sp.addChild(vanity_mirror);
			vanity_mirror.init();
			
			features_pane = new FeaturesVanityTabPane(onFeatureChange, showSubOverlay);
			features_pane.hatHideCallBack = function(hide:Boolean):void {
				if (hide) {
					hideHat();
				} else {
					showHat();
				}
				initializeHead();
			}
			features_pane.hatRemoveCallBack = function():void {
				removeHat();
				initializeHead();
			}
			features_pane.y = VanityModel.tab_panel_y;
			content_sp.addChild(features_pane);
			
			colors_pane = new ColorsVanityTabPane(onColorChange, showSubOverlay);
			colors_pane.x = VanityModel.ui_w - VanityModel.features_tab_panel_w;
			colors_pane.y = VanityModel.tab_panel_y;
			content_sp.addChild(colors_pane);
			
			dims_pane = new DimsPane(onDimChange);
			dims_pane.x = Math.round((VanityModel.ui_w-VanityModel.dimensions_panel_w)/2);
			dims_pane.y = VanityModel.tab_panel_y+VanityModel.tab_panel_h+VanityModel.panel_margin;
			content_sp.addChild(dims_pane);
			
			features_pane.addEventListener(TSEvent.CHANGED, onFeaturesTabChanged);
			colors_pane.addEventListener(TSEvent.CHANGED, onColorsTabChanged);
			
			////------
			
			saving_dialog = new SavingVanityDialog();
			saving_dialog.x = Math.round((w-saving_dialog.width)/2);
			saving_dialog.y = Math.round((h-saving_dialog.height)/2);
			saving_sp.addChild(saving_dialog);
			
			////------
			
			subbed_dialog = new SubscribedVanityDialog();
			subbed_dialog.ok_bt.addEventListener(MouseEvent.CLICK, onSubOkBtClick, false, 0, true);
			subbed_dialog.x = Math.round((w-subbed_dialog.width)/2);
			subbed_dialog.y = Math.round((h-subbed_dialog.height)/2);
			subbed_sp.addChild(subbed_dialog);
			
			////------
			
			sub_free_dialog = new SubscribeFreePromptVanityDialog();
			sub_free_dialog.sub_bt.addEventListener(MouseEvent.CLICK, onFreeSubBtClick, false, 0, true);
			sub_free_dialog.no_bt.addEventListener(MouseEvent.CLICK, onFreeSubNoBtClick, false, 0, true);
			sub_free_dialog.x = Math.round((w-sub_free_dialog.width)/2);
			sub_free_dialog.y = Math.round((h-sub_free_dialog.height)/2);
			sub_free_sp.addChild(sub_free_dialog);
			
			////------
			
			sub_pay_dialog = new SubscribePayPromptVanityDialog();
			sub_pay_dialog.sub_bt.addEventListener(MouseEvent.CLICK, onPaySubBtClick, false, 0, true);
			sub_pay_dialog.no_bt.addEventListener(MouseEvent.CLICK, onPaySubNoBtClick, false, 0, true);
			sub_pay_dialog.x = Math.round((w-sub_pay_dialog.width)/2);
			sub_pay_dialog.y = Math.round((h-sub_pay_dialog.height)/2);
			sub_pay_sp.addChild(sub_pay_dialog);
			
			////------
			
			leaving_dialog = new LeavingVanityDialog();
			leaving_dialog.home_bt.addEventListener(MouseEvent.CLICK, onLeavingHomeBtClick, false, 0, true);
			leaving_dialog.wardrobe_bt.addEventListener(MouseEvent.CLICK, onLeavingWardrobeBtClick, false, 0, true);
			leaving_dialog.stay_bt.addEventListener(MouseEvent.CLICK, onLeavingStayBtClick, false, 0, true);
			leaving_dialog.x = Math.round((w-leaving_dialog.width)/2);
			leaving_dialog.y = Math.round((h-leaving_dialog.height)/2);
			leaving_sp.addChild(leaving_dialog);
			
			////------
			
			hat_dialog = new HatVanityDialog();
			hat_dialog.remove_bt.addEventListener(MouseEvent.CLICK, onHatRemoveBtClick, false, 0, true);
			hat_dialog.hide_bt.addEventListener(MouseEvent.CLICK, onHatHideBtClick, false, 0, true);
			hat_dialog.x = Math.round((w-hat_dialog.width)/2);
			hat_dialog.y = Math.round((h-hat_dialog.height)/2);
			hat_sp.addChild(hat_dialog);
			
			////-------

			showProgess(load_steps, 3);
			initializeHead();
			//ava_swf.gotoFrameNumAndStop(VanityModel.ava_frame);
			doAnimation('idle3');
		}
		
		private function drawBlocker(g:Graphics):void {
			g.lineStyle(0, 0, 0);
			g.beginFill(0xffffff, .8);
			g.drawRect(0, 0, w, h);
		}
		
		////------
		
		private function onLeavingHomeBtClick(event:Event):void {
			//hideLeavingOverlay();
			leaving_sp.visible = false; // leave the blocker
			exit();
		}
		
		private function onLeavingWardrobeBtClick(event:Event):void {
			//hideLeavingOverlay();
			leaving_sp.visible = false; // leave the blocker
			exit('/wardrobe/');
		}
		
		private function onLeavingStayBtClick(event:Event):void {
			hideLeavingOverlay();
		}
		
		private function showBlocker():void {
			//if (blocker_sp.visible) return;
			blocker_sp.visible = true;
			//blocker_sp.alpha = 0;
			Tweener.removeTweens(blocker_sp);
			Tweener.addTween(blocker_sp, {alpha:1, time:VanityModel.fade_secs});
		}
		
		private function hideBlocker():void {
			Tweener.removeTweens(blocker_sp);
			Tweener.addTween(blocker_sp, {_autoAlpha:0, time:VanityModel.fade_secs});
		}
		
		private function showLeavingOverlay(saved:Boolean):void {
			if (saved) {
				leaving_dialog.makeForSaved();
			} else {
				leaving_dialog.makeForUnsaved()
			}
			leaving_sp.visible = true;
			showBlocker();
		}
		
		private function hideLeavingOverlay():void {
			leaving_sp.visible = false;
			hideBlocker();
		}
		
		private function onHatHideBtClick(event:Event):void {
			features_pane.showHatControls();
			hideHat();
			hideHatOverlay();
		}
		
		private function onHatRemoveBtClick(event:Event):void {
			removeHat();
			hideHatOverlay();
		}
		
		private function showHatOverlay():void {
			hat_sp.visible = true;
			showBlocker();
		}
		
		private function hideHatOverlay():void {
			initializeHead();
			hat_sp.visible = false;
			hideBlocker();
		}
		
		////------
		
		private function showSubscribeDoneOverlay():void {
			subbed_sp.visible = true;
			showBlocker();
		}
		
		private function onSubOkBtClick(event:Event):void {
			subbed_dialog.visible = false;
			hideBlocker();
		}
		
		////------
		
		private function onFreeSubBtClick(event:Event):void {
			hideSubOverlay();
			doSubscribe();
		}
		
		private function onFreeSubNoBtClick(event:Event):void {
			hideSubOverlay();
		}
		
		private function onPaySubBtClick(event:Event):void {
			// redirect
			exit(VanityModel.sub_url);
		}
		
		private function onPaySubNoBtClick(event:Event):void {
			hideSubOverlay();
		}
		
		
		private function doSubscribe():void {
			//Console.warn('saving...');
			saving_sp.visible = true;
			showBlocker();
			saving_dialog.setTxt('Subscribing...');
			saving_dialog.pb.update(0);
			
			sub_free_dialog.sub_bt.removeEventListener(MouseEvent.CLICK, onFreeSubBtClick);
			
			subscribeLoader = new SmartURLLoader('subscribe');
			// these are automatically removed on complete or error:
			subscribeLoader.complete_sig.add(onTrialSubscriptionLoadComplete);
			CONFIG::debugging {
				subscribeLoader.error_sig.add(
					function(loader:SmartURLLoader):void {
						Console.error('failed to load '+url);
					}
				);
			}
			
			var url:String = VanityModel.fvm.api_url+'simple/users.trialSubscription?ctoken='+VanityModel.fvm.api_token+'&cb='+String(new Date().getTime());
			CONFIG::debugging {
				Console.log(66, url);
			}
			subscribeLoader.load(new URLRequest(url));
		}
		
		private function showSubOverlay(bt:Sprite):void {
			bt_that_trigger_sub = bt;
			if (VanityModel.fvm.player_had_free_sub) {
				sub_pay_sp.visible = true;
				showBlocker();
			} else {
				sub_free_sp.visible = true;
				showBlocker();
			}
		}
		
		private function hideSubOverlay():void {
			// just in case, re sub
			sub_free_dialog.sub_bt.addEventListener(MouseEvent.CLICK, onFreeSubBtClick, false, 0, true);
			sub_free_sp.visible = false;
			
			// just in case, re sub
			sub_free_dialog.sub_bt.addEventListener(MouseEvent.CLICK, onPaySubBtClick, false, 0, true);
			sub_pay_sp.visible = false;
			hideBlocker();
		}
		
		////------
		
		private function onTrialSubscriptionLoadComplete(loader:SmartURLLoader):void {
			var json_str:String = loader.data;
			var rsp:Object = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {};
			
			if (!rsp || (!rsp.ok && rsp.error != 'previous_subscriber')) {
				CONFIG::debugging {
					Console.warn('error calling api');
				}
				return;
			}
			
			saving_dialog.pb.addEventListener(TSEvent.COMPLETE, onSavingSubscribePBComplete);
			saving_dialog.pb.updateWithAnimation(1, 1);
			
			CONFIG::debugging {
				Console.dir(rsp);
			}
			
			VanityModel.fvm.player_is_subscriber = true;
			
			colors_pane.onPlayerSubscribed(bt_that_trigger_sub);
			features_pane.onPlayerSubscribed(bt_that_trigger_sub);
		}
		
		private function onFeaturesTabChanged(e:TSEvent):void {
			//Console.warn('feat tab is '+e.data);
			if (e.data == 'hair') {
				colors_pane.activateTab('hair');
			}
		}
		
		private function onColorsTabChanged(e:TSEvent):void {
			//Console.warn('color tab is '+e.data);
		}
		
		private function initializeHead():void {
			var ac:AvatarConfig = AvatarConfig.fromAnonymous(VanityModel.ava_config);
			var acr:AvatarConfigRecord = AvatarResourceManager.instance.getAvatarConfigRecord(ac, ava_swf);
			current_ac = ac;

			//ava_swf.gotoFrameNumAndStop(VanityModel.ava_frame);
			ava_swf.initializeHead(ac);
			//ava_swf.gotoFrameNumAndStop(VanityModel.ava_frame);
			
			if (!acr.ready) {
				acr.addCallback(function(ac:AvatarConfig):void {
					if (current_ac.sig == ac.sig) {
						ava_swf.initializeHead(ac);
						avaReadyCallback();
					} else {
						; // satisfy compiler
						CONFIG::debugging {
							Console.priwarn(89, ac.sig+' IS NOT '+current_ac.sig);
						}
					}
				});
			} else {
				avaReadyCallback();
			}
		}
		
		
		private function avaReadyCallback():void {
			if (content_sp.visible) return;
			content_sp.alpha = 0;
			content_sp.visible = true;
			logo_sp.visible = true;
			Tweener.addTween(content_sp, {alpha:1, time:VanityModel.fade_secs});
			Tweener.addTween(loading_sp, {_autoAlpha:0, time:VanityModel.fade_secs});
			loading_dialog.clean();
		}
		
		private function doReset():void {
			VanityModel.ava_config = ObjectUtil.copyOb(VanityModel.ava_config_saved);
			VanityModel.base_hash = ObjectUtil.copyOb(VanityModel.base_hash_saved);
			features_pane.unCheckHatCb();
			updateAllUI();
		}
		
		private function updateAllUI():void {
			initializeHead();
			dims_pane.updateFromAvaConfig();
			features_pane.updateFromAvaConfig();
			colors_pane.updateFromAvaConfig();
		}
		
		private function doAnimation(anim:String):void {
			//Console.warn('anim:'+anim);
			ava_swf.playAnimation(anim, function():void {
				ava_swf.playFrameSeq([VanityModel.ava_frame]);
			});
		}
		
		private function doSave():void {
			//Console.warn('saving...');
			saving_sp.visible = true;
			showBlocker();
			saving_dialog.setTxt('Saving...');
			saving_dialog.pb.update(0);
			
			if (hat_removed) {
				saveWardrobe();
			} else {
				saveFace();
			}
		}
		
		private function saveWardrobe():void {
			
			saving_dialog.pb.updateWithAnimation(1, .4);
			
			saveWardrobeLoader = new SmartURLLoader('wardrobe');
			
			var url:String = VanityModel.fvm.api_url+'simple/wardrobe.setClothes';
			var request:URLRequest = new URLRequest(url);
			var variables:URLVariables = new URLVariables();
			variables.ctoken = VanityModel.fvm.api_token;
			
			for (var k:String in VanityModel.base_hash) {
				variables[k] = VanityModel.base_hash[k];
			}
			
			// get all the dims from the ava_config
			for (k in VanityModel.dims_name_map) {
				//Console.info('setting '+k+' to '+VanityModel.ava_config[k])
				variables[k] = VanityModel.ava_config[k];
			}
			
			CONFIG::debugging {
				Console.dir(variables);
			}
			
			request.data = variables;
			request.method = URLRequestMethod.POST;
			
			// these are automatically removed on complete or error:
			saveWardrobeLoader.complete_sig.add(onSavedWardrobe);
			
			CONFIG::debugging {
				saveWardrobeLoader.error_sig.add(
					function(loader:SmartURLLoader):void {
						Console.warn('failed to load '+url);
					}
				);
			}
			
			CONFIG::debugging {
				Console.log(66, url)
			}
			saveWardrobeLoader.load(request);
		}
		
		private function onSavedWardrobe(loader:SmartURLLoader):void {
			saveFace();
		}
		
		private function saveFace():void {
			
			saving_dialog.pb.updateWithAnimation(1, (hat_removed) ? .4 : .8);
			
			saveFaceLoader = new SmartURLLoader('face');
			
			var url:String = VanityModel.fvm.api_url+'simple/faces.setFace';
			var request:URLRequest = new URLRequest(url);
			var variables:URLVariables = new URLVariables();
			variables.ctoken = VanityModel.fvm.api_token;
			
			for (var k:String in VanityModel.base_hash) {
				variables[k] = VanityModel.base_hash[k];
			}
			
			// get all the dims from the ava_config
			for (k in VanityModel.dims_name_map) {
				//Console.info('setting '+k+' to '+VanityModel.ava_config[k])
				variables[k] = VanityModel.ava_config[k];
			}
			
			CONFIG::debugging {
				Console.dir(variables);
			}
			
			request.data = variables;
			request.method = URLRequestMethod.POST;
			
			// these are automatically removed on complete or error:
			saveFaceLoader.complete_sig.add(onSavedFace);
			
			CONFIG::debugging {
				saveFaceLoader.error_sig.add(
					function(loader:SmartURLLoader):void {
						Console.warn('failed to load '+url);
					}
				);
			}
			
			CONFIG::debugging {
				Console.log(66, url)
			}
			saveFaceLoader.load(request);
		}
		
		private function onSavedFace(loader:SmartURLLoader):void {
			var json_str:String = loader.data;
			var rsp:Object;
			try {
				rsp = (json_str) ? com.adobe.serialization.json.JSON.decode(json_str) : {};
			} catch (e:Error) {
				//if (callback is Function) callback(false);
			}
			if (!rsp || !rsp.ok) {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('error sending to api:'+json_str);
				}
				//if (callback is Function) callback(false, null);
			} else {
				//Console.warn('saved');
				CONFIG::debugging {
					Console.dir(rsp);
				}

				// the one with the db ids
				VanityModel.base_hash = rsp.base_hash;
				VanityModel.base_hash_saved = ObjectUtil.copyOb(VanityModel.base_hash);
				
				// the ava_config
				VanityModel.ava_config = rsp.hash;
				VanityModel.ava_config_saved = ObjectUtil.copyOb(VanityModel.ava_config);
				
				// if they hide the hat before, do it again now to make sure
				if (hat_hidden) {
					hideHat();
				}
				
				// makes sure the UI all shows what was actually saved
				updateAllUI();
			}
			
			doneSaving();
		}
		
		private function onSavingSubscribePBComplete(e:TSEvent):void {
			saving_sp.visible = false;
			saving_dialog.pb.removeEventListener(TSEvent.COMPLETE, onSavingSubscribePBComplete);
			
			showSubscribeDoneOverlay();
		}
		
		private function onSavingPBComplete(e:TSEvent):void {
			saving_sp.visible = false;
			saving_dialog.pb.removeEventListener(TSEvent.COMPLETE, onSavingPBComplete);
			
			showLeavingOverlay(true);
		}
		
		private function doneSaving():void {
			saving_dialog.pb.addEventListener(TSEvent.COMPLETE, onSavingPBComplete);
			saving_dialog.pb.updateWithAnimation(.5, 1);
			initializeHead();// we need to do this again because the png saving can have put a hat back on if the hat was only hidden
		}
		
		private function onDimChange(setting_name:String, value:Number):void {
			//Console.warn(setting_name+' set to id '+ value);
			VanityModel.ava_config[setting_name] = value;
			initializeHead();
		}
		
		private function onColorChange(type:String, id:int):void {
			//Console.warn(type+' color set to id '+ id);
			var option:Object = VanityModel.color_options[type][id];
			
			// set config
			VanityModel.ava_config[type+'_tint_color'] = option.color;
			VanityModel.ava_config[type+'_colors'] = option.colors;
			
			// set base_hash
			VanityModel.base_hash[type+'_color'] = id;
			
			// update buttons
			features_pane.updateColoredParts(type);
			
			// rerender
			initializeHead();
		}
		
		private var hat_hidden:Boolean;
		private var hat_removed:Boolean;
		private var had_hat_ob:Object;
		private function removeHat():void {
			features_pane.hideHatControls();
			hideHat();
			VanityModel.base_hash['hat'] = 0;
			hat_removed = true;
		}
		
		private function hideHat():void {
			if (!had_hat_ob) had_hat_ob = ObjectUtil.copyOb(VanityModel.ava_config.articles.hat);
			VanityModel.ava_config.articles.hat.article_class_name = 'none';
			hat_hidden = true;
		}
		
		private function showHat():void {
			if (!had_hat_ob) {
				CONFIG::debugging {
					Console.warn('wtf no had_hat_ob');
				}
				return;
			}
			VanityModel.ava_config.articles.hat = ObjectUtil.copyOb(had_hat_ob);
			hat_hidden = false;
		}
		
		private function applyArticleIdToAvaConfig(type:String, id:int, config:Object):void {
			var option:Object = VanityModel.feature_options[type][id];
			
			// set config
			config.articles[type] = {
				article_class_name: option.article_class_name,
				package_swf_url: option.package_url
			}
		}
		
		private function onFeatureChange(type:String, id:int):void {
			//Console.warn(type+' feature set to id '+ id);
			
			applyArticleIdToAvaConfig(type, id, VanityModel.ava_config);
			
			// set base_hash
			VanityModel.base_hash[type] = id;
			
			if (type == 'hair' ) {
				if (had_hat_ob) showHat();
				if (AvatarSwfParticulars.hatCanBeWornWithHair(VanityModel.ava_config.articles.hat, VanityModel.ava_config.articles.hair)) {
					// do nothing
					
				} else {
					removeHat();
				}
			}
			
			
			// rerender
			initializeHead();
		}
	}
}