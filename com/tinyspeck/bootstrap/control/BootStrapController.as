package com.tinyspeck.bootstrap.control {
	CONFIG const focus_debug:Boolean = false;

	import com.flexamphetamine.BuildDecayChronograph;
	import com.tinyspeck.bootstrap.BootUtil;
	import com.tinyspeck.bootstrap.LateralLoader;
	import com.tinyspeck.bootstrap.Version;
	import com.tinyspeck.bootstrap.model.BootStrapModel;
	import com.tinyspeck.bridge.ClickToFocus;
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.bridge.IMainEngineController;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.control.IController;
	import com.tinyspeck.core.data.AvatarAnimationDefinitions;
	import com.tinyspeck.core.memory.IDisposable;
	import com.tinyspeck.debug.API;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.NewxpLogger;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.loader.SmartLoader;
	import com.tinyspeck.engine.loader.SmartURLLoader;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.sound.SoundManager;
	import com.tinyspeck.engine.util.DisplayDebug;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.URLUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TextEvent;
	import flash.external.ExternalInterface;
	import flash.net.ObjectEncoding;
	import flash.net.Socket;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.text.AntiAliasType;
	import flash.text.Font;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	
	CONFIG::embed_engine_in_bootstrap { import com.tinyspeck.engine.control.MainEngineController; }
	
	public class BootStrapController implements IController, IDisposable {
		/* singleton boilerplate */
		public static const instance:BootStrapController = new BootStrapController();
		
		[Embed(source="../../../../assets/VAGRoundedBold.ttf", fontName="BootTipEmbed", mimeType="application/x-font-truetype", unicodeRange="U+0020-U+007E")]
		public static const BootTipEmbed:Class;

		private static const bootstrapCSS:String =
			/* GLOBAL */
			"a:link  { color:#00a8d2; }" +
			"a:hover { color:#d79035; }" +
			/* LateralLoader */
			".copy { font-size:16px; color:#636363; font-family:sans-serif; }" +
			".linkie { font-size:16px; color:#006f86; font-family:sans-serif; text-decoration:underline; }" +
			".linkie_button { font-size:28px; color:#ffffff; font-family:sans-serif; font-weight:bold }" +
			".progress { font-size:12px; color:#C7CACC; font-family:sans-serif; }" +
			/* BootStrapController */
			".version { font-size:10px; color:#C7CACC; font-family:sans-serif; }" +
			".bootstrap_tip { font-size:18px; color:#FFEE5D; text-align:center; font-family:BootTipEmbed; }" +
			".bootstrap_tip_text { font-size:18px; color:#FFFFFF; text-align:center; font-family:BootTipEmbed; }";
		
		public static const bootstrapStyleSheet:StyleSheet = new StyleSheet();
		{ // static init
			bootstrapStyleSheet.parseCSS(bootstrapCSS);
		}
		
		// be SURE that anchor tags don't reference glitch.com (relative links are good)
		private static const tips:Vector.<String> = new <String>[
			//'Find Street Projects in progress by scouting for greyed-out streets on the map.',
			'Need Crops pronto? Gather <a href="/items/guano/">Guano</a>! It\'s a great fertilizer. Head to the Caverns, where the plops drop!',
			'Check your daily Quoin limit by clicking on the Game Time clock (top-right, in the menu bar).',
			'Looking for someone? Try searching for them on the Friends page!',
			'Did you know you can access your Inventory by pressing "B"? (For bags, of course!)',
			'Try pressing the "C" key to look around your location a little. Learn the Eyeballery skill to be able to see even more!',
			'A few moments of Meditation will help when you\'re running low on Energy or Mood.',
			'Tri-curious? Chat with more than one person at a time by clicking player names and then "Invite to Party".',
			'Need Flour? Squeeze a Chicken for Grain, and a <a href="/items/knife-and-board/">Knife and Board</a> will do the rest!',
			'Need some Seed? Let Piggies do the deed: feed them some crops, then examine the plops!',
			'Amplify that Meditation sensation with delicious <a href="/items/bubble-tea/">Bubble Tea</a>!',
			'Exploring is a snap with a Map at your fingertips. It\'s easy, just press "M".',
			'If life gives you Cherries, make Lemon, er, Juice! See your local Kitchen Tools Vendor for a <a href="/items/fruit-changing-machine/">Fruit Changing Machine</a> today!',
			'Looking for that hard-to-find item?<br/>Try the <a href="/auctions/">Auctions</a>!',
			//'Ready for a place to call your own? See what\'s available in the <a href="/realty/">Realty Listings</a>!',
			'Going postal? You need to add other players to your friend list before you can send them mail!',
			'Try digging with friends and you\'ll BOTH reap the harvest.',
			'Scraping Barnacles with a friend or two is double plus good!',
			'Too much clicking? You can use the keyboard for almost everything. Try pressing the TAB key to toggle between chats, or between chat and the game.',
			'To easily access your Quest Log, press "L"',
			'Your player menu contains a bunch of useful things. Pressing "Z" will show them to you!',
			'To open your imagination menu, just press "X". Imagine that!',
			'The map in the game has easy search for locations. Choosing "set as destination" will give you GPS-like directions to wherever you want to go.',
			'Eye spy with my little "i".... information about anything in the game. Press "i" for info mode!'
		];
		
		[Embed(source="../../../../assets/loading_bg.swf", mimeType="application/x-shockwave-flash")]
		private const LOADING_BG:Class;
		
		[Embed(source="../../../../assets/glitch_logo.swf", mimeType="application/x-shockwave-flash")]
		private const GlitchLogo:Class;
		
		[Embed(source="../../../../assets/new_client_loading_logo.jpg", mimeType="image/jpeg")]
		private const GlitchLogoBM:Class;
		
		private static const logoWidth:Number = 480;
		private static const logoHeight:Number = 230;
		private static const globeHeight:Number = 488;
		public static const AUDIO_FADE_TIME:Number = 1.5;
		
		private var bg:DisplayObject = new LOADING_BG();
		public var logo:DisplayObject = new GlitchLogo();
		private var logo_new:DisplayObject = new GlitchLogoBM();
		public var loadingViewHolder:Sprite = new Sprite();
		private var globeHolder:Sprite = new Sprite();
		
		private var globometer:ProgressMovieClip;
		private var globometerLoader:SmartLoader;
		
		private const progress_holder:Sprite = new Sprite();
		private const progress_tf:TextField = new TextField();
		
		private const version_holder:Sprite = new Sprite();
		
		private const msg_holder:Sprite = new Sprite();
		private const msg_tf:TextField = new TextField();
		private const msg_bg:Sprite = new Sprite();
		
		private var msg_is_tip:Boolean;
		
		private var buildometer:BuildDecayChronograph;
		
		private var loading_steps:int = 4; // connection test, engine, load assets, load avatar
		private var steps_alotted_for_big_loads:int = 40;// for engine and assets, we'll use this many steps each
		private var step:int;
		
		private var connectionTestSocket:Socket;
		private var socketDataReported:Boolean;
		
		private var engine_load_start_ms:int;
		private var engineLoader:SmartLoader;
		private var engine_reported_load_progress:Boolean;
		
		private var assets_load_start_ms:int;
		private var assetsLoader:SmartLoader;
		
		private var avatar_load_start_ms:int;
		private var avatarLoader:SmartLoader;
		
		private var cssLoader:SmartURLLoader;
		
		private var fvm:FlashVarModel;
		private var bsm:BootStrapModel;
		private var mainEngineController:IMainEngineController;
		private var avatar_mc:MovieClip;
		private var load_start:int;
		private var general_load_start_ms:int;
		private var log_loading_percs:Boolean;
		
		private var lateral_loader:LateralLoader;
		
		private var socketConnectionAttempts:int = 0;
		
		private var disposed:Boolean;
		
		CONFIG::localhost private var localPHPLoader:SmartURLLoader;
		
		public function BootStrapController() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		public function init(flashVarModel:FlashVarModel):void {
			Font.registerFont(BootTipEmbed);
			
			log_loading_percs = EnvironmentUtil.getUrlArgValue('SWF_log_loading_percs') == '1';
			load_start = getTimer();
			fvm = flashVarModel;
			
			// setup tweening
			if (flashVarModel.use_tweenmax) {
				TSTweener.useEngine(TSTweener.TWEENMAX);
			} else {
				TSTweener.useEngine(TSTweener.TWEENER);
			}
			
			initProgress();
			
			if (fvm.new_loading_screen) {
				lateral_loader = new LateralLoader(logo_new, progress_holder);
			}
			
			bsm = BootStrapModel.instance;
			
			StageBeacon.stage.addChildAt(StageBeacon.game_parent, 0);
			StageBeacon.game_parent.contextMenu = BootStrap.menu;
			
			// init loading screen
			StageBeacon.game_parent.addChild(loadingViewHolder);
			logo.cacheAsBitmap = true;
			
			loadingViewHolder.addChild(version_holder);
			initBuildNumber();
			
			if (!fvm.new_loading_screen) {
				loadingViewHolder.addChild(progress_holder);
			}
			
			if (fvm.show_click_to_focus) {
				StageBeacon.stage.addChild(new ClickToFocus());
			}
			
			CONFIG::debugging {
				LocalStorage.instance.trackAllData();
			}
			
			if (fvm.show_buildtime) {
				buildometer = new BuildDecayChronograph(5*60, 'bootstrap');
				buildometer.name = 'buildometer';
				StageBeacon.stage.addChild(buildometer);
			}
			
			Benchmark.init(fvm.pc_tsid);
			if (fvm.show_benchmark) {
				Benchmark.display(true);
			}

			// we want to do this as soon as we can after getting flashvars, not sure if this is the right place
			BootUtil.setUpAPIAndConsole(fvm);
			NewxpLogger.setFVM(fvm);
			
			NewxpLogger.log('boot_swf_loaded');
			
			Benchmark.addCheck('Parsed flash vars');
			
			// listen for js callbacks about focus and blur
			// until JS_interface is loaded in the MainEngineController
			ExternalInterface.addCallback('incoming_AS', onIncomingAs);
			
			StageBeacon.resize_sig.add(resize);
			resize();
		}
		
		public function run():void {
			NewxpLogger.log('boot_swf_running');
			loadHTTPPolicyFile();
		}
		
		private var current_progress:Number = 0;
		private function set display_progress(val:Number):void {
			current_progress = val;
			if (fvm.new_loading_screen) {
				lateral_loader.progress = current_progress;
			}

			if (globometer) {
				globometer.progress = current_progress;
			}
		}
		
		private function loadHTTPPolicyFile():void {
			try {
				Security.loadPolicyFile('http://www.glitch.com/crossdomain.xml');
				Benchmark.addCheck('HTTP crossdomain loaded');
			} catch (e:Error) {
				Benchmark.addCheck('HTTP crossdomain error');
				BootError.handleError('http crossdomain error', e, ['bootstrap', 'crossdomain'], true, false);
			}
				
			ensureWeHaveConnectionData();
		}
		
		private function ensureWeHaveConnectionData():void {
			// let's see if we have the necessary data to connect to a GS;
			// if not, let's call out and see if we can retrieve it
			
			const local_pc:String = fvm.local_pc;
			const login_host:String = fvm.login_host;
			const token:String = fvm.token;
			const api_token:String = fvm.api_token;
			
			Benchmark.addCheck('Checking connection');
			
			if (local_pc) {
				; // satisfy compiler
				CONFIG::localhost {
					// If we're here it's because SWF_local_pc was passed in from the url,
					// which means we need to make an http request to find out which GS we should
					// connect to, and what token we should use to login. Probably because
					// we are loading the client outside of the normal website context, which
					// normally provides host:port and token
					localPHPLoader = new SmartURLLoader('local.php');
					// these are automatically removed on complete or error:
					localPHPLoader.complete_sig.add(onLocalPHPComplete);
					localPHPLoader.error_sig.add(onLocalPHPError);
					
					var cb:String = String(new Date().getTime());
					var url:String = fvm.root_url+'local.php?p='+local_pc+'&cb='+cb;
					
					CONFIG::debugging {
						Console.log(66, url);
					}
					localPHPLoader.load(new URLRequest(url));
				}
				
			} else if (login_host && token) {
				// We're here because login_host was passed in to the client, as per normal
				// when the client is run in the normal website context
				const login_host_parts:Array = login_host.split(':');
				bsm.host = login_host_parts[0];
				bsm.low_port = login_host_parts[1];
				bsm.token = token;
				bsm.api_token = api_token;
				
				weHaveConnectionData();
			} else {
				CONFIG::debugging {
					Console.error('Something is wrong');
					Console.warn('local_pc:'+local_pc);
					Console.warn('login_host:'+login_host);
					Console.warn('token:'+token);
				}
				apologizeAndGiveUp('find the game server',
					'\nlocal_pc: '+local_pc+
					'\nlogin_host: '+login_host+
					'\ntoken: '+token);
			}
		}
		
		CONFIG::localhost private function onLocalPHPComplete(loader:SmartURLLoader):void {
			XML.ignoreWhitespace = true;
			try {
				var rsp:XML = new XML(localPHPLoader.data);
			} catch(err:Error) {
				BootError.addErrorMsg('# malformed rsp from local.php: --> '+localPHPLoader.data, null, ['bootstrap', 'localhost']);
				CONFIG::debugging {
					Console.error('malformed rsp from local.php: '+localPHPLoader.data);
				}
				return;
			}
			
			CONFIG::debugging {
				Console.log(66, '\n'+
					'got token:'+rsp.token.text()+'\n'+
					'got host:'+rsp.host.text()+'\n'+
					'got api_token:'+rsp.api_token.text()
				);
			}
			
			const login_host:String = rsp.host.text();
			bsm.token = rsp.token.text();
			bsm.api_token = rsp.api_token.text();
			fvm.api_token = bsm.api_token;
			fvm.pc_sheet_url = rsp.sheet_url.text();
			
			API.setAPIUrl(fvm.api_url, fvm.api_token);
			
			const login_host_parts:Array = login_host.split(':');
			if (login_host_parts.length == 2) {
				bsm.host = login_host_parts[0];
				bsm.low_port = login_host_parts[1];
				weHaveConnectionData();
			} else {
				BootError.addErrorMsg('# Did not get good values from local.php: --> '+rsp, null, ['bootstrap', 'localhost']);
				CONFIG::debugging {
					Console.error('Did not get good values from local.php: '+rsp);
				}
				//var url:String = ExternalInterface.call('window.location.href.toString');
				//navigateToURL(new URLRequest(url), '_self');
			}
			
			Benchmark.addCheck('LOCALPHP: Connected');
		}
		
		CONFIG::localhost private function onLocalPHPError(loader:SmartURLLoader):void {
			Benchmark.addCheck('LOCALPHP: XML ERROR');
			CONFIG::debugging {
				Console.dir(loader.eventLog);
			}
			CONFIG::god {
				if (loader.eventLog.indexOf('Security sandbox violation') > -1) {
					navigateToURL(new URLRequest(
						'http://auth.tinyspeck.com/login/?fail=old&ref='+encodeURIComponent(ExternalInterface.call('window.location.href.toString'))
					), '_self');
					return;
				}
			}

			BootError.addErrorMsg('XML Error', null, ['bootstrap', 'localhost']);
		}
		
		private var total_sheets_to_load:int;
		private function weHaveConnectionData():void {
			Benchmark.addCheck('We have connection data '+bsm.host+':'+bsm.port);
			
			var big_loads:int = 2; // engine and assets
			
			extraQ = fvm.extra_loads_urls.concat();
			
			big_loads+= extraQ.length; // extra swf loads
			
			steps_alotted_for_big_loads = parseInt(EnvironmentUtil.getUrlArgValue('SWF_big_steps')) || steps_alotted_for_big_loads;
			
			loading_steps+= steps_alotted_for_big_loads*big_loads;
			
			if (EnvironmentUtil.getUrlArgValue('SWF_load_ava_sheets_pngs') != '0') {
				total_sheets_to_load = AvatarAnimationDefinitions.sheetsA.length;
				if (fvm.pc_sheet_url) {
					total_sheets_to_load += AvatarAnimationDefinitions.sheetsA.length;
				}
				loading_steps += total_sheets_to_load;
			}
			
			
			CONFIG::debugging {
				const txt:String = 'CONFIG::debugging='+(CONFIG::debugging);
				const url:String = ExternalInterface.call('window.location.href.toString');
				Console.info('GO GO GO '+txt+' ============ '+ url);
				Console.info('steps_alotted_for_big_loads:'+steps_alotted_for_big_loads);
				Console.info('loading_steps:'+loading_steps);
			}
				
			if (!fvm.new_loading_screen) {
				loadingViewHolder.addChild(bg);
				loadingViewHolder.addChild(globeHolder);
				loadingViewHolder.addChild(logo);
				loadingViewHolder.addChild(msg_holder);
			}
			
			loadingViewHolder.addChild(version_holder);

			if (fvm.new_loading_screen) {
				loadingViewHolder.addChildAt(lateral_loader, 1);
				NewxpLogger.log('loadingbar_showing');
			} else {
				loadingViewHolder.addChild(progress_holder);
			}
			
			// kick everything off
			testConnection();
			
			resize();
		}
		
		private function initBuildNumber():void {
			const version_tf:TextField = new TextField()
			version_tf.selectable = false;
			version_tf.styleSheet = bootstrapStyleSheet;
			version_tf.autoSize = TextFieldAutoSize.LEFT;
			version_tf.antiAliasType = AntiAliasType.ADVANCED;
			version_tf.mouseWheelEnabled = false;
			version_tf.mouseEnabled = false;
			version_tf.wordWrap = false;
			version_tf.multiline = false;
			version_tf.htmlText = '<span class="version">build ' + Version.revision + '</span>';
			version_holder.addChild(version_tf);
		}
		
		private function initProgress():void {
			progress_tf.selectable = false;
			progress_tf.styleSheet = bootstrapStyleSheet;
			progress_tf.autoSize = TextFieldAutoSize.LEFT;
			progress_tf.antiAliasType = AntiAliasType.ADVANCED;
			progress_tf.mouseWheelEnabled = false;
			progress_tf.mouseEnabled = false;
			progress_tf.wordWrap = false;
			progress_tf.multiline = false;
			progress_holder.addChild(progress_tf);
		}
		
		private function initTips():void {
			msg_bg.filters = StaticFilters.loadingTip_GlowA;
			msg_bg.alpha = 92/100;
			msg_holder.addChild(msg_bg);
			
			msg_tf.embedFonts = true;
			msg_tf.selectable = false;
			msg_tf.styleSheet = bootstrapStyleSheet;
			msg_tf.autoSize = TextFieldAutoSize.LEFT;
			msg_tf.antiAliasType = AntiAliasType.ADVANCED;
			msg_tf.mouseWheelEnabled = false;
			msg_tf.wordWrap = true;
			msg_tf.multiline = true;
			
			msg_tf.addEventListener(TextEvent.LINK, handleMsgLink);
			
			msg_tf.filters = StaticFilters.loadingTip_DropShadowA;
			msg_tf.width = 370;
			msg_holder.addChild(msg_tf);
			msg_holder.alpha = 0;
		}
		
		private function handleMsgLink(event:TextEvent):void {
			switch (event.text){
				case 'reload':
					URLUtil.reload();
					break;
			}
		}
		
		private function showTip(tip:String, prefix:String=''):void {
			msg_is_tip = true;
			showText(
				'<a target="_blank">' +
				(prefix?'<span class="bootstrap_tip">'+prefix+': </span>':'') +
				'<span class="bootstrap_tip_text">' + tip + '</span>' +
				'</a>'
			);
		}
		
		private function showWarn(txt:String):void {
			NewxpLogger.log('load_warning', txt)
			if (!msg_is_tip) {
				msg_is_tip = false;
				showText(
					'<span class="bootstrap_tip_text">' + txt + '</span>'
				);
			}
		}
		
		private function showError(txt:String):void {
			showText(
				'<span class="bootstrap_tip_text">' + txt + '</span>', 0x941100
			);
		}
		
		private function showInfo(tip:String, prefix:String=''):void {
			msg_is_tip = false;
			showText(
				'<a target="_blank">' +
					(prefix && prefix.length ? '<span class="bootstrap_tip">'+prefix+' </span>' : '') +
					'<span class="bootstrap_tip_text">' + tip + '</span>' +
				'</a>',
				0x941100
			);
		}
		
		private function showText(html:String, fillColor:uint=0x283742):void {
			if (!msg_tf.parent) initTips();

			msg_tf.htmlText = html;
			
			const msg_padd:int = 15;
			
			// base bg on tip_tf size
			msg_bg.graphics.clear();
			msg_bg.graphics.beginFill(fillColor);
			msg_bg.graphics.drawRoundRect(0, 0, int(msg_tf.width + msg_padd*2), int(msg_tf.height + msg_padd*2), 16);
			msg_bg.graphics.endFill();
			
			// center tip_tf
			msg_tf.x = msg_padd;
			msg_tf.y = Math.round((msg_bg.height - msg_tf.height) / 2);
			
			msg_holder.cacheAsBitmap = true;
			
			if (!msg_holder.alpha) {
				TSTweener.addTween(msg_holder, {alpha:1, time:0.4});
			}
			
			resize();
		}
		
		private function loadGlobometer():void {
			updateProgress('loading loadometer...');
			
			var url:String = fvm.load_progress_swf_url;
			
			NewxpLogger.log('globometer_loading', url);
			Benchmark.addCheck('Globometer loading '+url);
			
			general_load_start_ms = getTimer();
			globometerLoader = new SmartLoader('globometer');
			// these are automatically removed on complete or error:
			globometerLoader.complete_sig.add(onGlobometerComplete);
			globometerLoader.error_sig.add(onGlobometerError);
			globometerLoader.progress_sig.add(onGlobometerProgress);
			
			globometerLoader.load(new URLRequest(url), new LoaderContext(true));

			CONFIG::debugging {
				Console.log(66, url);
			}
		}
		
		private function onGlobometerProgress(loader:SmartLoader):void {
			var percentLoaded:Number = loader.bytesLoaded/loader.bytesTotal;
			updateProgress('loading loadometer... ', percentLoaded);
		}
		
		private function onGlobometerError(loader:SmartLoader):void {
			Benchmark.addCheck(loader);
			NewxpLogger.log('globometer_loading_failed');
			
			CONFIG::debugging {
				Console.warn('Failed to load globometer graphic from ' + globometerLoader.contentLoaderInfo.url);
			}
			globometerLoader.unloadAndStop();
			
			if (fvm.new_loading_screen) {
				loadSounds();
			} else {
				loadTips();
			}
		}
		
		private function onGlobometerComplete(loader:SmartLoader):void {
			NewxpLogger.log('globometer_loaded');
			benchCheckLoad('Globometer loaded', globometerLoader.contentLoaderInfo, general_load_start_ms);

			if (fvm.new_loading_screen) {
				const loadingbar:Class = globometerLoader.contentLoaderInfo.applicationDomain.getDefinition('loadingbar') as Class;
				// var stoppable_frames:Array = [0,20,40,60,80,100,120,140,160,180,200];
				// var stoppable_frames:Array = [0,10,22,36,52,70,100,132,160,180,200];
				// var stoppable_frames:Array = [0,30,60,95,125,150,170,185,195,200];
				//var stoppable_frames:Array = [0,10,20,30,40,50,60,70,80,90,100,110,120,130,140,150,160,170,180,190,200];
				 var stoppable_frames:Array = [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,110,115,120,125,130,135,140,145,150,155,160,165,170,175,180,185,190,195,200];
				
				globometer = new ProgressMovieClip(false, new loadingbar(), stoppable_frames, 10);
				// start it at 1/_loading_steps perc, so there is movement even though the first step
				// (connection test) has no measurable progress. Also, set min_step to .5,
				// for slower movement at beginning, then do globometer.resetMinStep() at the next step
				globometer.begin();
				step++;
				globometer.progress = 0;
				CONFIG::debugging {
					if (log_loading_percs) {
						Console.info(step+'/'+loading_steps+' '+current_progress);
					}

				}
				lateral_loader.addLoadingbar(globometer);
				
				globometer.addEventListener(Event.COMPLETE, globometerAnimationCompleteHandler);
				resize();
				
				loadSounds();
			} else {
				const Globometer:Class = globometerLoader.contentLoaderInfo.applicationDomain.getDefinition('Globometer') as Class;
				
				globometer = new ProgressMovieClip(fvm.run_globometer_backwards, new Globometer(), [0,18,38,60,72,96,118,144,162,184,200], 20);
				// start it at 1/_loading_steps perc, so there is movement even though the first step
				// (connection test) has no measurable progress. Also, set min_step to .5,
				// for slower movement at beginning, then do globometer.resetMinStep() at the next step
				globometer.begin();
				step++;
				globometer.progress = 0;
				CONFIG::debugging {
					if (log_loading_percs) {
						Console.info(step+'/'+loading_steps+' '+current_progress);
					}
				}
				globeHolder.addChild(globometer);
				globometer.addEventListener(Event.COMPLETE, globometerAnimationCompleteHandler);
				resize();
				
				// we'll do this later
				//globometerLoader.unload();
				
				loadTips();
			}
		}
		
		private function onKeyDown(event:KeyboardEvent):void {
			if(event.keyCode == Keyboard.ESCAPE && SoundManager.instance.getSoundObject('OPENING_SCREEN_MUSIC')){
				if (fvm.new_loading_screen) {
					lateral_loader.turnMusicOff();
				} else {
					SoundManager.instance.stopSound('OPENING_SCREEN_MUSIC', AUDIO_FADE_TIME);
				}
				StageBeacon.key_down_sig.remove(onKeyDown);
			}
		}
		
		private function testConnection():void {
			var port:int = bsm.port;
			
			// test breaking it
			if (EnvironmentUtil.getUrlArgValue('SWF_fake_bad_low_port') == '1') {
				if (port < 1000) port+= 111;
			}
			
			// test breaking it
			if (EnvironmentUtil.getUrlArgValue('SWF_fake_bad_high_port') == '1') {
				if (port > 1000) port+= 111;
			}
			
			if (EnvironmentUtil.getUrlArgValue('SWF_fake_bad_ports') == '1') {
				port+= 111;
			}
			
			socketConnectionAttempts++;
			Benchmark.addCheck('Socket connection '+bsm.host+':'+port+' test #' + socketConnectionAttempts);
			CONFIG::debugging {
				Console.info('Socket connection '+bsm.host+':'+port+' test #' + socketConnectionAttempts);
			}
			
			updateProgress('connecting to game server...');
			
			// we may try multiple times
			if (connectionTestSocket) {
				removeSocketListeners();
				connectionTestSocket = null;
			}
			
			connectionTestSocket = new Socket();
			connectionTestSocket.objectEncoding = ObjectEncoding.AMF3;
			connectionTestSocket.addEventListener(Event.CONNECT, onSocketConnect);
			connectionTestSocket.addEventListener(IOErrorEvent.IO_ERROR, onSocketError);
			connectionTestSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSocketError);
			connectionTestSocket.addEventListener(Event.CLOSE, onSocketClose);
			connectionTestSocket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
			
			// wait less time the second attempt
			connectionTestSocket.timeout = ((socketConnectionAttempts > 1) ? 5000 : 10000);
			
			// preload the socket policy file
			try {
				Security.loadPolicyFile('xmlsocket://' + bsm.host + ':843');
				Benchmark.addCheck('socket policy loaded');
			} catch (e:Error) {
				Benchmark.addCheck('socket policy error');
				BootError.handleError('socket policy error', e, ['bootstrap', 'socket', 'crossdomain'], true, false);
			}
			
			connectionTestSocket.connect(bsm.host, port);
		}
		
		private function removeSocketListeners():void {
			if (connectionTestSocket) {
				connectionTestSocket.removeEventListener(Event.CONNECT, onSocketConnect);
				connectionTestSocket.removeEventListener(IOErrorEvent.IO_ERROR, onSocketError);
				connectionTestSocket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSocketError);
				connectionTestSocket.removeEventListener(Event.CLOSE, onSocketClose);
				connectionTestSocket.removeEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
			}
		}
		
		protected function onSocketData(event:ProgressEvent):void {
			if (!socketDataReported) {
				Benchmark.addCheck('We have socket data: ' + event);
				socketDataReported = true;
			}
		}
		
		protected function onSocketClose(event:Event):void {
			removeSocketListeners();
		}
		
		private function onSocketConnect(event:Event):void {
			Benchmark.addCheck('Socket connected to '+bsm.host+':'+bsm.port);
			NewxpLogger.log('boot_swf_has_socket');
			CONFIG::debugging {
				Console.info('Socket connected to '+bsm.host+':'+bsm.port);
			}
			
			connectionTestSocket.close();
			removeSocketListeners();
			
			loadGlobometer();
		}
		
		private function onSocketError(event:ErrorEvent):void {
			showWarn('Hmmm, we\'re having trouble reaching the<br>game server. <span class="bootstrap_tip">Trying again...</span>');
			
			Benchmark.addCheck('Socket connection bsm.using_default_port:'+bsm.using_default_port+' failed: '+event);

			CONFIG::debugging {
				Console.error('Socket connection bsm.using_default_port:'+bsm.using_default_port+' failed: '+event);
			}
			
			if (socketConnectionAttempts < 2) {
				// try again
				socketDataReported = false;
				testConnection();
			} else if (bsm.using_default_port) {
				// try the fallback port twice before giving up
				bsm.switchToFallBackPort();
				Benchmark.addCheck('Trying the fallback port: ' + bsm.port);
				socketConnectionAttempts = 0;
				socketDataReported = false;
				testConnection();
			} else {
				apologizeAndGiveUp('reach the game server', event.toString(), (EnvironmentUtil.getUrlArgValue('SWF_fake_bad_ports') != '1'));
			}
		}
		
		private function loadTips():void {
			if (!fvm.no_boot_message) {
				if (fvm.boot_message) {
					showInfo(fvm.boot_message, fvm.boot_message_prefix);
				} else {
					showTip(tips[MathUtil.randomInt(0, tips.length-1)], fvm.boot_message_prefix || 'Tip');
				}
			}
			
			loadSounds();
		}
		
		private function loadSounds():void {
			if(SoundManager.instance.sfx_volume && !CONFIG::perf){
				const opening_screen_url:String = fvm.get('sound_OPENING_SCREEN') || 'http://c2.glitch.bz/sounds/2012-03/1331738581-Opening_Screen_Chimes_1.1.mp3';
				SoundManager.instance.addExternalSound(opening_screen_url, 'OPENING_SCREEN', false);
				SoundManager.instance.playSound('OPENING_SCREEN', SoundManager.instance.sfx_volume);
			}
			
			//have to use the sound manager instead of sound master since master relies on things that are loaded in later on
			if(SoundManager.instance.music_volume && !CONFIG::perf){
				const opening_music_url:String = fvm.get('sound_OPENING_SCREEN_MUSIC') || 'http://c2.glitch.bz/sounds/2012-03/1331738603-Opening_Screen_Music_1.1.mp3';
				SoundManager.instance.addExternalSound(opening_music_url, 'OPENING_SCREEN_MUSIC', true);
				SoundManager.instance.playSound('OPENING_SCREEN_MUSIC', SoundManager.instance.music_volume);
				
				//listen for the esc button to fade out the intro music
				StageBeacon.key_down_sig.add(onKeyDown);
			}
			
			if(SoundManager.instance.sfx_volume && !CONFIG::perf){
				const first_street_url:String = fvm.get('sound_FIRST_STREET_LOADING') || 'http://c2.glitch.bz/sounds/2012-03/1331167039-00._Street_Loading_1.2.mp3';
				SoundManager.instance.addExternalSound(first_street_url, 'FIRST_STREET_LOADING', false);
			}
			
			loadCSS();
		}
		
		private function loadCSS():void {
			NewxpLogger.log('css_loading');
			//once we are done loading the assets, let's load the global stylesheet
			cssLoader = new SmartURLLoader('CSS');
			// these are automatically removed on complete or error:
			cssLoader.complete_sig.add(onCSSComplete);
			cssLoader.error_sig.add(onCSSError);
			
			updateProgress('loading css...');
			
			Benchmark.addCheck('CSS Loading '+fvm.css_file);
			cssLoader.load(new URLRequest(fvm.css_file));
		}
		
		private function onCSSError(loader:SmartURLLoader):void {
			Benchmark.addCheck('CSS failed');
			apologizeAndGiveUp('cascade the style sheets');
			CONFIG::debugging {
				Console.error('Client CSS failed to load');
			}
		}
		
		private function onCSSComplete(loader:SmartURLLoader):void {
			Benchmark.addCheck('CSS Loaded');
			NewxpLogger.log('css_loaded');
			
			CSSManager.instance.init(cssLoader.data);
			StaticFilters.updateFromCSS();
			
			loadAssets();
		}
		
		private var assets_reported_load_progress:Boolean;
		private function loadAssets():void {
			NewxpLogger.log('asset_swf_loading');
			assets_reported_load_progress = false;

			var url:String = fvm.assetsUrl;
			var loaderContext:LoaderContext = new LoaderContext(false,new ApplicationDomain(ApplicationDomain.currentDomain), null);
			
			assetsLoader = new SmartLoader('assets');
			// these are automatically removed on complete or error:
			assetsLoader.complete_sig.add(onAssetsLoadComplete);
			assetsLoader.error_sig.add(onAssetsSmartLoaderError);
			assetsLoader.progress_sig.add(assetsloadProgress);
			
			updateProgress('loading assets...');
			
			assets_load_start_ms = getTimer();
			assetsLoader.load(new URLRequest(url), loaderContext);

			CONFIG::debugging {
				Console.log(66, 'loading '+url);
			}
		}

		private function onAssetsSmartLoaderError(loader:SmartLoader):void {
			apologizeAndGiveUp('load the engine assets');
			CONFIG::debugging {
				Console.error("Assets load Error");
				Console.info(loader.eventLog);
			}
		}
		
		private function assetsloadProgress(loader:SmartLoader):void {
			var percentLoaded:Number = loader.bytesLoaded/loader.bytesTotal;
			
			if (!assets_reported_load_progress && loader.bytesLoaded) {
				Benchmark.addCheck('assetsloadProgress: '+StringUtil.formatNumber((loader.bytesLoaded/loader.bytesTotal*100), 2)+'%');
				assets_reported_load_progress = true;
			}
			
			var fake_step:int = step+(percentLoaded*steps_alotted_for_big_loads);
			this.display_progress = (fake_step/loading_steps) + (percentLoaded/loading_steps);
			updateProgress('loading assets... ', percentLoaded);

			CONFIG::debugging {
				if (log_loading_percs) {
					Console.info(fake_step+'/'+loading_steps+' steps_alotted_for_big_loads:'+steps_alotted_for_big_loads+' ('+percentLoaded+')');
				}
			}
		}
		
		// we want the globometer loading animation done, and the engine load done before proceeding
		private function onAssetsLoadComplete(loader:SmartLoader):void {
			NewxpLogger.log('asset_swf_loaded');
			benchCheckLoad('Assets loaded', assetsLoader.contentLoaderInfo, assets_load_start_ms);
			
			step+= steps_alotted_for_big_loads;
			
			CONFIG::debugging {
				Console.log(66, 'loaded '+fvm.assetsUrl);
			}
			AssetManager.instance.init(assetsLoader.content);
			
			assetsLoader.unload();
			
			loadAvatarThings();
		}
		
		private var ava_sheets_pngs_loaded_cnt:int = 0;
		private function loadAvatarThings():void {
			updateProgress('loading avatar assets ('+(ava_sheets_pngs_loaded_cnt+1)+' of ' +total_sheets_to_load+')...');
			NewxpLogger.log('avatars_loading');
			
			if (EnvironmentUtil.getUrlArgValue('SWF_load_ava_sheets_pngs') != '0') {
				if (!fvm.placeholder_sheet_url) {
					CONFIG::debugging {
						Console.error('NO placeholder_sheet_url');
					}
					return;
				}
				
				var A:Array = AvatarAnimationDefinitions.sheetsA;
				var url:String;
				for (var i:int; i<A.length; i++) {
					url = fvm.placeholder_sheet_url+'_'+A[int(i)]+'.png';
					AssetManager.instance.loadBitmapFromWeb(url, onWWWimgBitmapLoaded, 'loadAvatarThings()');
					
					if (fvm.pc_sheet_url) {
						url = fvm.pc_sheet_url+'_'+A[int(i)]+'.png';
						AssetManager.instance.loadBitmapFromWeb(url, onWWWimgBitmapLoaded, 'loadAvatarThings()');
					}
				}
				
			} else {
				loadAvatar();
			}
		}
		
		private function onWWWimgBitmapLoaded(filename:String, bm:Bitmap):void {
			var fail_str:String;
			if (!bm) {
				fail_str = 'unable to load '+filename;
				if (filename.indexOf(fvm.placeholder_sheet_url) != -1) {
					// a wireframe bm could not be loaded, we cannot proceed
					apologizeAndGiveUp('load avatar assets', fail_str);
					return;
				} else {
					// a user bm could not be loaded, but let's allow things to continue
					// and we'll use the wireframe ava placeholder
					//Benchmark.addCheck('unable to load '+filename);
					BootError.handleError(fail_str, new Error(fail_str), ['bootstrap', 'loader'], true, false);
				}
			} else if (bm.width == 1 && bm.height == 1) {
				// no idea of the cause of this. proxy server or firewall fucking up the image load?
				fail_str = 'bad_avatar_dimensions; we loaded '+filename+' but it is 1x1?';
				apologizeAndGiveUp('load avatar assets', fail_str);
				return;
			}
			
			ava_sheets_pngs_loaded_cnt++;
			
			step++;
			var percentLoaded:Number = ava_sheets_pngs_loaded_cnt/total_sheets_to_load;
			this.display_progress = (step/loading_steps) + (percentLoaded/loading_steps);
			updateProgress('loading avatar assets ('+(ava_sheets_pngs_loaded_cnt+1)+' of ' +total_sheets_to_load+')... ', percentLoaded);
			CONFIG::debugging {
				if (log_loading_percs) {
					Console.info(step+'/'+loading_steps+' '+current_progress+' ('+percentLoaded+')');
				}
			}
			
			if (ava_sheets_pngs_loaded_cnt == total_sheets_to_load) {
				loadAvatar();
			}
		}
		
		//----------------------------------------------------------------------------------------
		
		
		private function loadAvatar():void {
			updateProgress('loading dinosaur butts...');
			
			step++;
			Benchmark.addCheck('Avatar loading '+fvm.avatar_url);
			
			BootUtil.ava_app_domain = new ApplicationDomain(ApplicationDomain.currentDomain);
			var loaderContext:LoaderContext = new LoaderContext(false, BootUtil.ava_app_domain, null);
			
			avatarLoader = new SmartLoader('avatar');
			// these are automatically removed on complete or error:
			avatarLoader.complete_sig.add(onAvatarLoadComplete);
			avatarLoader.error_sig.add(onAvatarError);
			avatarLoader.progress_sig.add(avatarloadProgress);
			
			avatar_load_start_ms = getTimer();
			avatarLoader.load(new URLRequest(fvm.avatar_url), loaderContext);

			CONFIG::debugging {
				Console.log(66, 'loading '+fvm.avatar_url);
			}
		}
		
		private function onAvatarError(loader:SmartLoader):void {
			apologizeAndGiveUp('dress your avatar');
			Benchmark.addCheck(loader);
			CONFIG::debugging {
				Console.error("Avatar load Error");
				Console.info(loader);
			}
		}
		
		private function avatarloadProgress(loader:SmartLoader):void {
			// second step
			const percentLoaded:Number = loader.bytesLoaded/loader.bytesTotal;
			
			this.display_progress = (step/loading_steps) + (percentLoaded/loading_steps);
			updateProgress('loading dinosaur butts... ', percentLoaded);
			CONFIG::debugging {
				if (log_loading_percs) {
					Console.info(step+'/'+loading_steps+' '+current_progress+' ('+percentLoaded+')');
				}
			}
		}
		
		private function onAvatarLoadComplete(loader:SmartLoader):void {
			benchCheckLoad('Avatar loaded', avatarLoader.contentLoaderInfo, avatar_load_start_ms);
			
			CONFIG::debugging {
				Console.log(66, 'loaded '+fvm.avatar_url);
			}
			avatar_mc = avatarLoader.content as MovieClip;
			avatarLoader.unload();
			
			step++;
			NewxpLogger.log('avatars_loaded');
			loadExtraThings();
		}
		
		//----------------------------------------------------------------------------------------
		
		private var extraQ:Array = [];
		private function loadExtraThings():void {
			if (!extraQ.length) {
				loadEngine();
			} else {
				loadExtra();
			}
		}
		
		private function loadExtra():void {
			var url:String = extraQ.pop();
			var sl:SmartLoader = new SmartLoader('extra_loads_'+extra_loaded_cnt);
			// these are automatically removed on complete or error:
			sl.complete_sig.add(onExtraComplete);
			sl.error_sig.add(onExtraError);
			sl.progress_sig.add(onExtraProgress);
			NewxpLogger.log('extra_swf_loading', url);
			updateProgress('loading miscellany ('+(extra_loaded_cnt+1)+' of ' +fvm.extra_loads_urls.length+')... ');

			sl.load(new URLRequest(url));
		}
		
		private function onExtraError(loader:SmartLoader):void {
			apologizeAndGiveUp('load all the necessary assets');
			Benchmark.addCheck(loader);
			CONFIG::debugging {
				Console.error("Extra load Error");
				Console.info(loader);
			}
		}
		
		private function onExtraProgress(loader:SmartLoader):void {
			var percentLoaded:Number = loader.bytesLoaded/loader.bytesTotal;
			var fake_step:int = step+(percentLoaded*steps_alotted_for_big_loads);
			this.display_progress = (fake_step/loading_steps) + (percentLoaded/loading_steps);
		
			updateProgress('loading miscellany ('+(extra_loaded_cnt+1)+' of ' +fvm.extra_loads_urls.length+')... ', percentLoaded);
			CONFIG::debugging {
				if (log_loading_percs) {
					Console.info(step+' '+fake_step+'/'+loading_steps+' '+current_progress+' ('+percentLoaded+')');
				}
			}
		}

		private var extra_loaded_cnt:int;
		private function onExtraComplete(loader:SmartLoader):void {
			NewxpLogger.log('extra_swf_loaded', loader.start_url+' '+StringUtil.formatNumber(loader.bytesLoaded/1024, 2)+'kb');
			
			extra_loaded_cnt++;
			step+= steps_alotted_for_big_loads;
			
			CONFIG::debugging {
				if (log_loading_percs) {
					Console.info(step+'/'+loading_steps+' '+current_progress);
				}
			}
			
			
			if (extraQ.length) {
				loadExtra();
			} else {
				loadEngine();
			}
		}
		
		//----------------------------------------------------------------------------------------

		private function loadEngine():void {
			updateProgress('loading engine...');
			NewxpLogger.log('engine_loading');
			
			if (CONFIG::embed_engine_in_bootstrap) {
				mainEngineController = new MainEngineController();
				done();
				return;
			}
			engine_reported_load_progress = false;
			
			var url:String = fvm.engineUrl;
			var loaderContext:LoaderContext = new LoaderContext(false, new ApplicationDomain(ApplicationDomain.currentDomain), null);
			
			engineLoader = new SmartLoader('engine');
			// these are automatically removed on complete or error:
			engineLoader.complete_sig.add(onEngineComplete);
			engineLoader.error_sig.add(onEngineError);
			engineLoader.progress_sig.add(onEngineProgress);
			
			engine_load_start_ms = getTimer();
			engineLoader.load(new URLRequest(url), loaderContext);

			CONFIG::debugging {
				Console.log(66, 'loading '+url);
			}
		}
		
		private function onEngineError(loader:SmartLoader):void {
			apologizeAndGiveUp('load the game engine');
			Benchmark.addCheck(loader);
			CONFIG::debugging {
				Console.error("Engine load Error");
				Console.info(loader);
			}
		}
		
		private function onEngineProgress(loader:SmartLoader):void {
			var percentLoaded:Number = loader.bytesLoaded/loader.bytesTotal;
			
			if (!engine_reported_load_progress && loader.bytesLoaded) {
				Benchmark.addCheck('engineloadProgress: '+StringUtil.formatNumber((loader.bytesLoaded/loader.bytesTotal*100), 2)+'%');
				engine_reported_load_progress = true;
			}
			
			// we set loading_steps to more than their actually are to make sure there is plenty of time for engine loading, which is actually the
			// heaviest load; so now, in this last step we must fake climbing up all the rest of the steps
			//var step:int = 4+(percentLoaded*(loading_steps-4));
			
			var fake_step:int = step+(percentLoaded*(loading_steps-step));
			
			this.display_progress = (fake_step/loading_steps) + (percentLoaded/loading_steps);
			updateProgress('loading engine... ', percentLoaded);
			CONFIG::debugging {
				if (log_loading_percs) {
					Console.info(step+' '+fake_step+'/'+loading_steps+' '+current_progress+' ('+percentLoaded+')');
				}
			}
		}
		
		// we want the globometer loading animation done, and the engine load done before proceeding
		private function onEngineComplete(loader:SmartLoader):void {
			benchCheckLoad('Engine loaded', engineLoader.contentLoaderInfo, engine_load_start_ms);
			NewxpLogger.log('engine_loaded');
			
			// update Buildometer to track Engine.swf
			if (fvm.show_buildtime) {
				const buildometer:BuildDecayChronograph = (StageBeacon.stage.getChildByName('buildometer') as BuildDecayChronograph);
				buildometer.label = "engine";
				buildometer.swfBytes = engineLoader.contentLoaderInfo.bytes;
			}
			
			CONFIG::debugging {
				Console.log(66, 'loaded '+fvm.engineUrl);
			}
			
			mainEngineController = (engineLoader.content['mainEngineController'] as IMainEngineController);
			
			engineLoader.unload();
			
			if (fvm.new_loading_screen) {
				updateProgress('complete!');
			} else {
				updateProgress('finishing up...');
			}
			
			this.display_progress = 1;
			
			CONFIG::debugging {
				if (log_loading_percs) {
					Console.info(current_progress);
				}
			}
			if (fvm.new_loading_screen) {
				done();
			} else {
				if (!globometer || globometer.complete) done();
			}
		}
		
		// we want the progrometer loading animation done, and the engine load done before proceeding
		private function globometerAnimationCompleteHandler(e:Event):void {
			Benchmark.addCheck('Globometer animation complete');
			globometer.removeEventListener(Event.COMPLETE, globometerAnimationCompleteHandler);
			
			// with new_loading_screen, we call done as soon as engine is loaded
			if (!fvm.new_loading_screen) {
				if (mainEngineController) done();
			}
		}
		
		private function done():void {
			//we can only show the load time from when the bootloader gave access to the flash vars, it'll be different than Scribe
			Benchmark.addCheck('Client loaded');
			NewxpLogger.log('boot_swf_has_loaded_everything');
			Benchmark.addCheck('OLD Client loaded secs: '+((getTimer()-load_start)/1000));
			Benchmark.addSectionTime(Benchmark.SECTION_BOOT);
			CONFIG::debugging {
				Console.scribe('\n\tClient loaded secs: '+((getTimer()-load_start)/1000));
			}
			
			mainEngineController.setFlashVarModel(fvm);
			mainEngineController.setPrefsModel(bsm.prefsModel);
			mainEngineController.setAvatar(avatar_mc);
			
			if (fvm.new_loading_screen) {
				lateral_loader.showStartButton();
				var run_immediately:Boolean = false;
				if (run_immediately) {
					lateral_loader.start_clicked_sig.add(mainEngineController.connect);
					mainEngineController.run();
				} else {
					lateral_loader.start_clicked_sig.add(mainEngineController.runAndConnect);
				}
				
				NewxpLogger.log('loadingbar_showing_start_button','After '+(Math.round((getTimer()-load_start)/1000))+' secs since boot swf was loaded');
			} else {
				mainEngineController.runAndConnect();
			}
			
			// the JS callback will be removed when JS_interface.init() runs
			// setting it to null will just cause RTEs, even though docs say it's okay
			//ExternalInterface.addCallback('incoming_AS', null);

			// remove loaded content and loaders
			cssLoader = null;
			engineLoader = null;
			assetsLoader = null;
			CONFIG::localhost {
				localPHPLoader = null;
			}
			//
			connectionTestSocket = null;
		}
		
		private function onIncomingAs(msg:Object):Boolean {
			if (msg) {
				if (msg.meth == 'window_blur') {
					if (fvm.better_focus_handling) {
						// window_blur is not guaranteed to cause Flash to lose
						// focus, as Chrome sends a window_blur event when Flash
						// *receives* focus (presumably because of its plugin
						// isolation system);
						// we will get an Event.DEACTIVATE instead
						// (except in Safari on OS X when you click Safari UI;
						//  it will, however, send it when you change tabs/apps)
						//StageBeacon.flash_has_focus = false;
					} else {
						CONFIG::debugging {
							Console.info('boot b');
						}
						StageBeacon.flash_has_focus = false;
					}
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('unrecognized meth '+(msg.meth || '')+' in onIncomingAs');
					}
				}
			}
			return true;
		}
		
		private function benchCheckLoad(title:String, contentLoaderInfo:LoaderInfo, ts:int):void {
			Benchmark.addCheck(title+' '+contentLoaderInfo.url+' '+StringUtil.formatNumber(contentLoaderInfo.bytesLoaded/1024, 2)+'kb in '+((getTimer()-ts)/1000).toFixed(2)+' secs');
		}
		
		private function resize():void {
			const stageWidth:Number  = StageBeacon.stage.stageWidth;
			const stageHeight:Number = StageBeacon.stage.stageHeight;
			
			// bottom left
			if (buildometer) {
				buildometer.x = 3;
				buildometer.y = stageHeight - buildometer.height - 3;
			}
			
			const scale:Number = (stageHeight / 768);
			
			if (fvm.new_loading_screen) {
				
				lateral_loader.y = 0;
				lateral_loader.x = Math.round(stageWidth / 2);
				
				lateral_loader.resize();
				
			} else {
				// position the bottom of the logo just above the trees
				logo.y = Math.max(0, (stageHeight - logoHeight - Math.round(globeHeight * scale)));
				
				// center just above the trees
				logo.x = Math.round((stageWidth - logoWidth) / 2);
				
				if (globometer) {
					globometer.scaleX = scale;
					globometer.scaleY = scale;
					
					// bottom middle
					// it has a bottom middle registration point
					globometer.x = Math.round(stageWidth / 2);
					globometer.y = stageHeight;
				}
				bg.y = 0;
				
				// top middle
				progress_holder.x = (StageBeacon.stage.stageWidth  - progress_holder.width)/2;
				progress_holder.y = 0;
			}

			bg.x = 0;
			bg.width = stageWidth;
			bg.height = stageHeight;
			
			msg_holder.x = (stageWidth  - msg_holder.width) / 2;
			if (msg_is_tip) {
				msg_holder.y = (stageHeight - msg_holder.height - (40 * scale));
			} else {
				msg_holder.y = logo.y+logo.height+40;
			}
			
			// bottom right
			version_holder.x = (stageWidth  - version_holder.width);
			version_holder.y = (stageHeight - version_holder.height);
		}
		
		public function dispose():void {
			if (disposed) return;
			disposed = true;
			
			StageBeacon.game_parent.removeChild(loadingViewHolder);
			StageBeacon.resize_sig.remove(resize);
			StageBeacon.key_down_sig.remove(onKeyDown);
 			
			bg = null;
			logo = null;
			logo_new = null;
			loadingViewHolder = null;
			bootstrapStyleSheet.clear();
			
			if (globometer) {
				if (globometer.parent) globometer.parent.removeChild(globometer);
				globometer.removeEventListener(Event.COMPLETE, globometerAnimationCompleteHandler);
				globometer.dispose();
				globometer = null;
			}
			
			if (globometerLoader) {
				globometerLoader.unloadAndStop();
				globometerLoader = null;
			}
		}
		
		private var given_up:Boolean;
		private function apologizeAndGiveUp(verbTheNoun:String, event:String='', report:Boolean=true):void {
			if (given_up) return;
			given_up = true;
			NewxpLogger.log('fail', 'unable to ' + verbTheNoun);
			const str:String = '<span class="bootstrap_tip">Well, I\'m sorry, but we\'re unable to ' + verbTheNoun + '.</span> ' +
				'This might be our fault, or it may be a network problem. ' +
				'This incident has been logged, and you can try <a href="event:reload">reloading</a> if you like :(<br><br>' + 
				"If it keeps happening try this:<br><a href='http://www.glitch.com/help/test' target='test_connection'>http://www.glitch.com/help/test</a>";
			if (report) BootError.handleError('unable to ' + verbTheNoun + ':\n'+event, new Error('unable to ' + verbTheNoun), ['bootstrap', 'loader'], true, false);
			if (globometer) TSTweener.addTween(globometer, {alpha:0, time:3});
			showError(str);
		}
		
		private function updateProgress(msg:String, percent:Number = NaN):void {
			var css_class:String;
			if (fvm.new_loading_screen) {
				css_class = 'progress';
				if (msg) msg += ' '+ int(current_progress * 100)+'%';
			} else {
				css_class = 'version';
				msg += (!isNaN(percent) ? int(percent * 100) + '%' : '');
			}
			progress_tf.htmlText = '<span class="'+css_class+'">' + msg + '</span>';
			if (isNaN(percent)) {
				Benchmark.addCheck(msg);
			}
			
			if (fvm.new_loading_screen) {
				lateral_loader.jiggerProgress(/*isNaN(percent)?0:percent*/percent);
			} else {
				// top middle
				progress_holder.x = (StageBeacon.stage.stageWidth  - progress_holder.width)/2;
				progress_holder.y = 0;
			}
		}
	}
}

import com.tinyspeck.debug.Console;
import com.tinyspeck.engine.util.EnvironmentUtil;
import com.tinyspeck.tstweener.TSTweener;

import flash.display.BlendMode;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.Event;
import flash.utils.getTimer;

class ProgressMovieClip extends Sprite {
	private var mc:MovieClip;
	private var stoppable_frames:Array;
	private var last_allowed_frame_index:int;
	private var shrink_back_frame:int;
	private var perc:Number;
	private var _complete:Boolean;
	private var tweener_breath_transition:String = 'easeInOutSine';
	private var tweener_fps_forward:Number = 20;
	private var tweener_fps_back:Number = 10;
	private var frames_to_go_back:Number = 20;
	private var go_back_to_stoppable_frame:Boolean = true;
	private var breath:Boolean = true;
	private var backwards:Boolean = false;
	private var slow_fps:Number = 20;
	
	public function ProgressMovieClip(backwards:Boolean, mc:MovieClip, stoppable_frames:Array, tweener_fps_forward:int) {
		this.backwards = backwards
		this.mc = mc;
		this.stoppable_frames = stoppable_frames;
		this.tweener_fps_forward = tweener_fps_forward;
		
		tweener_breath_transition = EnvironmentUtil.getUrlArgValue('SWF_load_anim_transition') || tweener_breath_transition;
		tweener_fps_forward = (EnvironmentUtil.getUrlArgValue('SWF_load_anim_fps_forward')) ? (parseInt(EnvironmentUtil.getUrlArgValue('SWF_load_anim_fps_forward'))) : tweener_fps_forward;
		tweener_fps_back = (EnvironmentUtil.getUrlArgValue('SWF_load_anim_fps_back')) ? (parseInt(EnvironmentUtil.getUrlArgValue('SWF_load_anim_fps_back'))) : tweener_fps_back;
		frames_to_go_back = (EnvironmentUtil.getUrlArgValue('SWF_load_anim_frames_back')) ? (parseInt(EnvironmentUtil.getUrlArgValue('SWF_load_anim_frames_back'))) : frames_to_go_back;
		slow_fps = (EnvironmentUtil.getUrlArgValue('SWF_load_slow_fps')) ? (parseInt(EnvironmentUtil.getUrlArgValue('SWF_load_slow_fps'))) : slow_fps;
		breath = EnvironmentUtil.getUrlArgValue('SWF_load_anim_breath') != '0';
		go_back_to_stoppable_frame = EnvironmentUtil.getUrlArgValue('SWF_load_anim_gbtsf') != '0';
		
		
		if (backwards) {
			this.stoppable_frames.reverse();
			var back:int = this.tweener_fps_back;
			this.tweener_fps_back = this.tweener_fps_forward;
			this.tweener_fps_forward = back;
		}
		
		CONFIG::debugging {
			Console.info('tweener_breath_transition:'+this.tweener_breath_transition);
			Console.info('tweener_fps_forward:'+this.tweener_fps_forward);
			Console.info('tweener_fps_back:'+this.tweener_fps_back);
			Console.info('frames_to_go_back:'+this.frames_to_go_back);
			Console.info('go_back_to_stoppable_frame:'+this.go_back_to_stoppable_frame);
			Console.info('mc.totalFrames:'+mc.totalFrames);
			Console.info('breath:'+this.breath);
			Console.info('slow_fps:'+this.slow_fps);
		}
		
		last_allowed_frame_index = 2;
		shrink_back_frame = calcFrameToGoBackTo();

		blendMode = BlendMode.LAYER;
		addChild(mc);
		mc.gotoAndStop(backwards?200:0);
	}
	
	public function begin(ms:int = 0, p_min_step:Number = -1):void {
		mc.gotoAndStop(backwards?200:0);
		_complete = false;
		perc = 0;
		if (breath) {
			animateForwards();
		}
	}
	
	public function dispose():void {
		TSTweener.removeTweens(this);
	}
	
	/*public function startSlowly():void {
		var to_frame:int = mc.totalFrames/4;
		var diff:int = Math.abs(to_frame-frame);
		var time:Number = diff/slow_fps;
		CONFIG::debugging {
			Console.priinfo(428, 'going to frame:'+to_frame+' from frame:'+frame+' in:'+time+'s, FPS:'+(diff/time));
		}
		TSTweener.addTween(this, {frame:to_frame, transition:'linear', time:time, onComplete:checkSlowProgress});
	}
	
	public function checkSlowProgress():void {
		var perc_anim:Number = frame/mc.totalFrames;
		
		if (perc_anim == 1) {
			_complete = true;
			dispatchEvent(new Event(Event.COMPLETE));
			return;
		}
		
		if (perc_anim > perc) {
			slow_fps-= 2;
			slow_fps = Math.max(6, slow_fps);
		} else {
			slow_fps+= 5;
		}
		
		var to_frame:int = frame+(slow_fps);
		var diff:int = Math.abs(to_frame-frame);
		var time:Number = diff/slow_fps;
		CONFIG::debugging {
			Console.priinfo(428, 'going to frame:'+to_frame+' from frame:'+frame+' in:'+time+'s, FPS:'+(diff/time)+' perc_anim:'+perc_anim+' perc:'+perc);
		}
		TSTweener.addTween(this, {frame:to_frame, transition:'linear', time:time, onComplete:checkSlowProgress});
		
	}*/
	
	private function adjustSlowly():void {
		var perc_anim:Number = frame/mc.totalFrames;
		
		if (perc_anim == 1) {
			if (perc == 1 && !_complete) {
				_complete = true;
				dispatchEvent(new Event(Event.COMPLETE));
			}
			return;
		}
		
		var to_frame:int = Math.min(mc.totalFrames, frame+10);
		if (perc > perc_anim) {
			slow_fps+= 4;
		} else {
			slow_fps-= 2;
			slow_fps = Math.max(6, slow_fps);
		}
		
		var diff:int = Math.abs(to_frame-frame);
		var time:Number = diff/slow_fps;
		CONFIG::debugging {
			Console.priinfo(428, 'going to frame:'+to_frame+' from frame:'+frame+' in:'+time+'s, FPS:'+(diff/time)+' perc_anim:'+perc_anim+' perc:'+perc);
		}
		TSTweener.removeTweens(this);
		TSTweener.addTween(this, {frame:to_frame, transition:'linear', time:time, onComplete:adjustSlowly});
	}
	
	private function animateForwards():void {
		var to_frame:int = stoppable_frames[last_allowed_frame_index];
		var diff:int = Math.abs(to_frame-frame);
		var fps:int = tweener_fps_forward;

		// increase FPS if we're moving a lot of frames, and this is not the first animation forward
		if (diff > 40 && last_allowed_frame_index > 2) {
			fps = tweener_fps_forward*(diff/40);
		}
		
		var time:Number = diff/fps;
		CONFIG::debugging {
			Console.priinfo(428, 'going to frame:'+to_frame+' from frame:'+frame+' in:'+time+'s, FPS:'+(diff/time));
		}
		TSTweener.removeTweens(this);
		TSTweener.addTween(this, {frame:stoppable_frames[last_allowed_frame_index], transition:tweener_breath_transition, time:time, onComplete:onLastAllowedFrame});
	}
	
	private function animateBackwards():void {
		var to_frame:int = shrink_back_frame;
		var diff:int = Math.abs(to_frame-frame);
		var time:Number = diff/tweener_fps_back;
		CONFIG::debugging {
			Console.priinfo(428, 'going to frame:'+to_frame+' from frame:'+frame+' in:'+time+'s, FPS:'+(diff/time));
		}
		TSTweener.removeTweens(this);
		TSTweener.addTween(this, {frame:to_frame, transition:tweener_breath_transition, time:time, onComplete:animateForwards});
	}
	
	private function onLastAllowedFrame():void {
		if ((backwards && frame == 1) || ((!backwards && frame == mc.totalFrames)) && !_complete) {
			CONFIG::debugging {
				Console.priinfo(428, frame);
			}
			_complete = true;
			dispatchEvent(new Event(Event.COMPLETE));
			return;
		}
		
		if ((shrink_back_frame > frame && !backwards) || (shrink_back_frame < frame && backwards)) {
			animateForwards();
		} else {
			animateBackwards();
		}
	}
	
	public function set progress(val:Number):void {
		perc = Math.min(1, Math.max(0, val));
		if (breath) {
			var lsf:int = Math.max(last_allowed_frame_index, Math.floor(perc*(stoppable_frames.length-1)));
			if (lsf != last_allowed_frame_index/* || perc == 1*/) {
				if (perc == 1.0) tweener_fps_forward*= 2;
				last_allowed_frame_index = lsf;
				shrink_back_frame = calcFrameToGoBackTo();
				CONFIG::debugging {
					Console.priinfo(428, perc+' last_allowed_frame_index:'+lsf+' shrink_back_frame:'+shrink_back_frame);
				}
			}
		} else {
			adjustSlowly();
		}
	}
	
	private function calcFrameToGoBackTo():int {
		if (go_back_to_stoppable_frame) return Math.max(1, stoppable_frames[last_allowed_frame_index-1]);
		return Math.max(1, stoppable_frames[last_allowed_frame_index]-frames_to_go_back);
	}
	
	public function set frame(val:Number):void {
		mc.gotoAndStop(Math.round(val));
	}
	
	public function get frame():Number {
		return mc.currentFrame;
	}
	
	private function get progress():Number {
		return perc;
	}
	
	public function get complete():Boolean {
		return _complete;
	}
}
