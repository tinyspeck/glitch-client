package com.tinyspeck.engine.spritesheet {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.data.AvatarAnimationDefinitions;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.LoginTool;
	import com.tinyspeck.debug.Tim;
	import com.tinyspeck.engine.data.pc.AvatarConfig;
	import com.tinyspeck.engine.loader.AvatarConfigRecord;
	import com.tinyspeck.engine.loader.AvatarResourceManager;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.loadedswfs.AvatarSwf;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import org.osflash.signals.Signal;
	
	CONFIG::perf { import com.tinyspeck.engine.model.TSModelLocator; }
	
	public class AvatarSSManager {
		// gets w/h set when mc is loaded
		public static const ss_options:SSGenOptions = new SSGenOptions(
			SSGenOptions.TYPE_MULTIPLE_BITMAPS,
			0,
			0
		);
		
		public static const bm_load_fail_sig:Signal = new Signal();
		
		public static var ava_swf:AvatarSwf;
		public static var anims:Array;
		public static var use_default_ava:Boolean = false;
		public static var use_default_ava_except_for_player:Boolean;
		public static var default_ss:SSAbstractSheet;
		
		private static const ORIGIN:Point = new Point();
		
		/** String to SSAbstractSheet */
		private static const png_sheet_bmd_key_map:Object = {};
		private static const lazy_frame_map:Dictionary = new Dictionary(true);
		private static const default_hash:String = 'default';
		
		/** Initialized in init() to the largest dimensions an avatar frame can be */
		private static var reusable_avatar_frame_bmd:BitmapData;
		
		private static var ssCollection:SSCollection = new SSCollection();
		private static var required_anims:Array;
		private static var doneFunc:Function;
		private static var dont_initialize_head:Boolean = false; // only relevant with lazy snapping
		private static var dont_gotoandstop:Boolean = false; // only relevant with lazy snapping
		private static var _lazy_ss:Boolean = true;
		private static var _load_ava_sheets_pngs:Boolean = false;
		private static var default_ac:AvatarConfig;
		private static var placeholder_sheet_url:String;
		private static var clone_standin_bmds:Boolean = false;
		private static var remove_empty_pixels:Boolean = true;
		
		public static function init(placeholder_sheet_url:String, load_ava_sheets_pngs:Boolean=false):void {
			required_anims = [];
			
			AvatarSSManager.placeholder_sheet_url = placeholder_sheet_url;
			ss_options.double_measure = true;
			ss_options.scale = (EnvironmentUtil.getUrlArgValue('SWF_ava_scale')) ? (parseFloat(EnvironmentUtil.getUrlArgValue('SWF_ava_scale'))) : 1; //1.06;
			ss_options.transparent = (EnvironmentUtil.getUrlArgValue('SWF_ss_opaque') != '1');
			
			// don't link TSML into ASSMan, hence EnvUtil:
			use_default_ava = EnvironmentUtil.getUrlArgValue('SWF_use_default_ava') == '1';
			use_default_ava_except_for_player = EnvironmentUtil.getUrlArgValue('SWF_use_default_ava_except_for_player') == '1';
			CONFIG::perf {
				// perf overrides this value via code not via querystring
				use_default_ava = TSModelLocator.instance.flashVarModel.use_default_ava;
				use_default_ava_except_for_player = TSModelLocator.instance.flashVarModel.use_default_ava_except_for_player;
			}
			if (use_default_ava_except_for_player) use_default_ava = true;
			_lazy_ss = (EnvironmentUtil.getUrlArgValue('SWF_lazy_ss') != '0') ? true : false;
			dont_initialize_head = (EnvironmentUtil.getUrlArgValue('SWF_dont_initialize_head') == '1');
			dont_gotoandstop = (EnvironmentUtil.getUrlArgValue('SWF_dont_gotoandstop') == '1');
			clone_standin_bmds = EnvironmentUtil.getUrlArgValue('SWF_clone_standin_bmds') == '1';
			remove_empty_pixels = EnvironmentUtil.getUrlArgValue('SWF_remove_empty_pixels') != '0';
			_load_ava_sheets_pngs = load_ava_sheets_pngs;
			
			if (load_ava_sheets_pngs) {
				//use_default_ava = true;
			} else {
				default_ac = AvatarConfig.fromAnonymous({placeholder:true, pc_tsid:default_hash});
			}
			
			AvatarAnimationDefinitions.init(ss_options.scale);
			reusable_avatar_frame_bmd = new BitmapData(AvatarAnimationDefinitions.frame_w, AvatarAnimationDefinitions.frame_h);
		}
		
		public static function run(p_mc:MovieClip, doneFunc:Function):void {
			if (!LoginTool.reportStep(2, 'ava_ss_man_run')) return;
			
			Benchmark.addCheck('AvatarSSManager.run');
			
			AvatarSSManager.doneFunc = doneFunc;
			
			if (p_mc) {
				setMc(p_mc);
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.error('no mc??');
				}
			}
		}
		
		CONFIG::god public static function memReport():String {
			var str:String = '\nAvatarSSManager memReport\n+--------------------------------------------------\n';
			
			for (var k:Object in lazy_frame_map) {
				str+= 'frame '+SSFrame(lazy_frame_map[k])._name+' has_temp_bmd:'+SSFrame(lazy_frame_map[k].bmd).has_bmd+' has_temp_bmd:'+SSFrame(lazy_frame_map[k].bmd).has_temp_bmd+'\n';
			}
			
			for (k in png_sheet_bmd_key_map) {
				str+= 'bmd_key '+k+' has_temp_bmd:'+SSMultiBitmapSheet(png_sheet_bmd_key_map[k].ss).name+'\n';
			}
			
			str += ssCollection.memReport();
			return str;
		}
		
		public static function get lazy_ss():Boolean {
			return _lazy_ss;
		}
		
		public static function get load_ava_sheets_pngs():Boolean {
			return _load_ava_sheets_pngs;
		}
		
		private static function setMc(p_mc:MovieClip):void {
			Benchmark.addCheck('AvatarSSManager.setMc');
			
			AvatarSSManager.ava_swf = new AvatarSwf(p_mc, false);
			
			// this is the size of the avatar mc on the stage of the swf, unscaled. I am not sure how to measure it, so I have hardcoded it
			ss_options.movieWidth = 55;
			ss_options.movieHeight = 118;
			
			anims = AvatarAnimationDefinitions.getSheetedAnimsA();
			
			createDefaultSS();
		}
		
		private static function createDefaultSS():void {
			var start_ts:int = getTimer();
			
			if (load_ava_sheets_pngs) {
				default_ss = makeSSForAvaHash(default_hash, true);
			} else {
				var acr:AvatarConfigRecord = AvatarResourceManager.instance.getAvatarConfigRecord(default_ac, ava_swf);
				default_ss = makeSSForAvaConfig(default_ac, true);
			}
			
			Benchmark.addCheck('took '+StringUtil.formatNumber((getTimer()-start_ts)/1000, 4)+'secs to create default SS');
			
			StageBeacon.waitForNextFrame(callDonefunc);
		}
		
		private static function callDonefunc():void {
			if (doneFunc != null) doneFunc();
		}
		
		public static var times:int = 1;
		public static function onEnterFrame(ms_elapsed:int):void {
			for (var i:int=0; i<times; i++) {
				ssCollection.update();
			}
		}
		
		public static function removeSSViewforDefaultSS(ss_view:SSViewSprite):void {
			removeSSViewforAva(default_ac, default_hash, ss_view);
		}
		
		public static function removeSSViewforAva(ac:AvatarConfig, hash:String, ss_view:SSViewSprite):void {
			
			if (!ss_view) return;
			
			var ss:SSMultiBitmapSheet = ss_view.ss as SSMultiBitmapSheet;
			
			if (load_ava_sheets_pngs) {
				removeSSViewforAvaHash(hash, ss_view);
			} else {
				removeSSViewforAvaConfig(ac, ss_view);
			}
			
			ssCollection.cleanup();
			
			if (hash && ss && ss.ss_views.length == 0) {
				// let's remove all the possible sheets from png_sheet_bmd_key_map
				// which will cause loadFromQ to ignore the item in the load Q
				for each(var sheet:String in AvatarAnimationDefinitions.sheetsA) {
					var bmd_key:String = getSheetPngUrl(hash, sheet);
					if (png_sheet_bmd_key_map[bmd_key]) {
						png_sheet_bmd_key_map[bmd_key] = null;
						delete png_sheet_bmd_key_map[bmd_key];
					} 
				}
			}
			
			//System.gc();
		}
		
		private static function removeSSViewforAvaHash(hash:String, ss_view:SSViewSprite):void {
			var spriteSheet:SSAbstractSheet = ssCollection.getSpriteSheet(hash);
			
			if (!spriteSheet) {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('failed to find spritesheet! '+hash);
				}
				return;
			}
			
			var did_it:Boolean = spriteSheet.removeViewSprite(ss_view);
			CONFIG::debugging {
				if (!did_it) Console.error('removeViewSprite FAILED for hash: '+hash);
			}
		}
		
		private static function removeSSViewforAvaConfig(ac:AvatarConfig, ss_view:SSViewSprite):void {
			var key:String = getKeyForAvaConfig(ac);
			var spriteSheet:SSAbstractSheet = ssCollection.getSpriteSheet(key);
			
			if (!spriteSheet) {
				CONFIG::debugging {
					Console.warn('failed to find spritesheet! '+key);
				}
				return;
			}
			
			var did_it:Boolean = spriteSheet.removeViewSprite(ss_view);
			CONFIG::debugging {
				if (!did_it) Console.error('removeViewSprite FAILED for key: '+key);
			}
		}
		
		public static function playSSViewSequenceForAva(ac:AvatarConfig, hash:String, ss_view:SSViewSprite, action:Function, anim_sequenceA:Array, callBack:Function=null):void {
			if (load_ava_sheets_pngs) {
				playSSViewSequenceForAvaHash(hash, ss_view, action, anim_sequenceA, callBack);
			} else {
				playSSViewSequenceForAvaConfig(ac, ss_view, action, anim_sequenceA, callBack);
			}
		}
		
		private static function playSSViewSequenceForAvaHash(hash:String, ss_view:SSViewSprite, action:Function, anim_sequenceA:Array, callBack:Function=null):void {
			var ss:SSMultiBitmapSheet = ss_view.ss 	as SSMultiBitmapSheet;
			var useA:Array = [];
			
			// make sure we only act on ones we know about
			for (var i:int=0;i<anim_sequenceA.length;i++) {
				if (anims.indexOf(anim_sequenceA[int(i)]) > -1) useA.push(anim_sequenceA[int(i)]);
			}
			
			// make sure they are recorded ahead of time
			for (i=0;i<useA.length;i++) {
				if (!ss.getFrameCollectionByName(useA[int(i)])) {
					recordAnim(useA[int(i)], ss, null, hash);
				}
			}
			
			if (useA.length == 0) {
				CONFIG::debugging {
					Console.warn('no useable anims in '+anim_sequenceA.join(', '));
				}
				return;
			}
			
			action(anim_sequenceA, callBack);
		}
		
		private static function playSSViewSequenceForAvaConfig(ac:AvatarConfig, ss_view:SSViewSprite, action:Function, anim_sequenceA:Array, callBack:Function=null):void {
			var ss:SSMultiBitmapSheet = ss_view.ss 	as SSMultiBitmapSheet;
			var useA:Array = [];
			
			// make sure we only act on ones we know about
			for (var i:int=0;i<anim_sequenceA.length;i++) {
				if (anims.indexOf(anim_sequenceA[int(i)]) > -1) useA.push(anim_sequenceA[int(i)]);
			}
			
			// make sure they are recorded ahead of time
			for (i=0;i<useA.length;i++) {
				if (!ss.getFrameCollectionByName(useA[int(i)])) {
					recordAnim(useA[int(i)], ss, ac);
				}
			}
			
			if (useA.length == 0) {
				CONFIG::debugging {
					Console.warn('no useable anims in '+anim_sequenceA.join(', '));
				}
				return;
			}
			
			action(anim_sequenceA, callBack);
		}
		
		private static function setUpAvatarWithConfig(ac:AvatarConfig):void {
			if (ac.placeholder) {
				ac.acr.ava_swf.initializeHead(default_ac);
				ac.acr.ava_swf.showPlaceholderSkin();
			} else {
				ac.acr.ava_swf.initializeHead(ac);
				ac.acr.ava_swf.hidePlaceholderSkin();
			}
			Tim.stamp(222, 'initializeHead');
		}
		
		private static function playSSViewForAvaConfig(ac:AvatarConfig, ss_view:SSViewSprite, action:Function, frame:Object, anim:String):void {
			if (anims.indexOf(anim) == -1) return;
			var ss:SSMultiBitmapSheet = ss_view.ss as SSMultiBitmapSheet;
			
			if (!ss.getFrameCollectionByName(anim)) {
				recordAnim(anim, ss, ac);
			}
			
			action(frame, anim);
		}
		
		private static function playSSViewForAvaHash(hash:String, ss_view:SSViewSprite, action:Function, frame:Object, anim:String):void {
			if (anims.indexOf(anim) == -1) return;
			var ss:SSMultiBitmapSheet = ss_view.ss as SSMultiBitmapSheet;
			
			// we do this in too places so the stack traces give us more hints: action(frame, anim);
			
			if (!ss.getFrameCollectionByName(anim)) {
				recordAnim(anim, ss, null, hash);
				action(frame, anim);
			} else {
				action(frame, anim);
			}
		}
		
		public static function playSSViewForAva(ac:AvatarConfig, hash:String, ss_view:SSViewSprite, action:Function, frame:Object, anim:String):void {
			if (anims.indexOf(anim) == -1) return;
			
			if (load_ava_sheets_pngs) {
				playSSViewForAvaHash(hash, ss_view, action, frame, anim);
			} else {
				playSSViewForAvaConfig(ac, ss_view, action, frame, anim);
			}
		}
		
		private static function getKeyForAvaConfig(ac:AvatarConfig):String {
			var key:String = String(AvatarSSManager.ss_options.scale)+':'+String(AvatarSSManager.ss_options.scale)+'-'
			
			if (false) {
				key+= ac.pc_tsid;
			} else {
				key+= ac.sig;
			}
			
			CONFIG::debugging {
				Console.log(113, 'key for this ac: '+key);
			}
			return key;
		}
		
		private static function getSSForAvaConfig(ac:AvatarConfig, callback:Function=null, make_all:Boolean=false):SSAbstractSheet {
			if (!ava_swf) {
				CONFIG::debugging {
					Console.warn('no avatar mc set');
				}
				return null;
			}
			
			var acr:AvatarConfigRecord = AvatarResourceManager.instance.getAvatarConfigRecord(ac, null);
			if (!acr.ready) {
				if (callback != null) acr.addCallback(callback);
				return default_ss;
			}
			
			var key:String = getKeyForAvaConfig(ac);
			return ssCollection.getSpriteSheet(key) || makeSSForAvaConfig(ac, make_all);
		}
		
		private static function getSSForAvaHash(hash:String, callback:Function=null, make_all:Boolean=false):SSAbstractSheet {
			// this is the case if they have no sheets (should never be the case once we launch the new sprite sheets)
			if (!hash) {
				CONFIG::debugging {
					Console.error('WTF HO HASH');
				}
				return null;
			}
			
			return ssCollection.getSpriteSheet(hash) || makeSSForAvaHash(hash, make_all);
		}
		
		public static function getSSForAva(ac:AvatarConfig, hash:String, callback:Function=null, make_all:Boolean=false):SSAbstractSheet {
			if (use_default_ava) {
				if (use_default_ava_except_for_player && ac && ac.client::isPlayersAvatar) {
					// skip, use the player's spritesheet
				} else {
					return default_ss;
				}
			}
			
			if (load_ava_sheets_pngs) {
				return getSSForAvaHash(hash, callback, make_all);
			} else {
				return getSSForAvaConfig(ac, callback, make_all);
			}
		}
		
		private static var next_xy:Point = new Point(0, 0);
		private static function lazySnap(ss:SSAbstractSheet, frame:SSFrame):Boolean {
			var ob:Object = lazy_frame_map[frame];
			if (!ob) {
				CONFIG::debugging {
					Console.warn('no ob?');
				}
				return false;
			}

			if (!frame) {
				CONFIG::debugging {
					Console.warn(ob.anim+' '+ob.fn+' no frame?');
				}
				return false;
			}
			
			Tim.stamp(222, 'start Avatar lazySnap '+ob.anim);
			
			var this_ava_swf:AvatarSwf = ob.ac.acr.ava_swf;
			
			if (!frame.has_bmd) {
				
				if (ss.source_swf_fn_to_frame_map[ob.fn] && SSFrame(ss.source_swf_fn_to_frame_map[ob.fn]).has_bmd) {
					ss.copyFrame(frame, ss.source_swf_fn_to_frame_map[ob.fn]);
					Tim.stamp(222, 'copyFrame '+ob.anim);
				} else {
					if (!dont_initialize_head) {
						setUpAvatarWithConfig(ob.ac);
						Tim.stamp(222, 'setUpAvatarWithConfig '+ob.anim);
					}
					
					if (!dont_gotoandstop) {
						this_ava_swf.playFrameSeq([ob.fn]);
						Tim.stamp(222, 'gotoFrameNumAndStop '+ob.anim);
					}
					
					ss.setActiveFrameCollection(ob.anim);
					Tim.stamp(222, 'setActiveFrameCollection '+ob.anim);
					ss.startRecord();
					//this_ava_swf.do_correct_hair = (AvatarAnimationDefinitions.emotion_animsA.indexOf(ob.anim) > -1);
					
					ss.lazySnapFrame(this_ava_swf, frame, ss_options);
					ss.source_swf_fn_to_frame_map[ob.fn] = frame; // make sure the one in the map is the one with the bmd!
					Tim.stamp(222, 'lazySnapFrame '+ob.anim);
					ss.stopRecord();
				}
			}
			
			Tim.stamp(222, 'stop '+ob.anim);
			Tim.report(222, 'Avatar lazySnap '+ob.ac.pc_tsid+' '+ob.anim+' (frame #'+ob.fn+') (pixels:'+(frame.originalBounds.width*frame.originalBounds.height)+') '+frame.originalBounds, true);
			
			lazy_frame_map[frame] = null;
			delete lazy_frame_map[frame];
			
			return true;
		}
		
		
		private static var is_loading_sheet_png:Boolean = false;
		private static const sheet_pngQ:Array = [];
		CONFIG::debugging private static var q_max:int;
		private static function loadFromSheetPngQ():void {
			if (!sheet_pngQ.length) return;
			
			// comment out this line to let AssetManager's q handle the qing
			if (is_loading_sheet_png) return;
			
			CONFIG::debugging {
				if (sheet_pngQ.length > q_max) {
					q_max = sheet_pngQ.length;
					Console.trackValue('ASSM q max', q_max);
				}
			}
			
			var bmd_key:String = sheet_pngQ.shift();
			
			CONFIG::debugging {
				Console.trackValue('ASSM q', sheet_pngQ.length);
			}
			
			if (png_sheet_bmd_key_map[bmd_key]) {
				is_loading_sheet_png = true;
				AssetManager.instance.loadBitmapFromWeb(bmd_key, aSheetPngHasLoaded, 'loadFromSheetPngQ()');
			} else {
				// load the next one
				loadFromSheetPngQ();
			}
			
		}
		
		CONFIG::perf public static function pngsQueuedForLoading():int {
			return sheet_pngQ.length;
		}
		
		public static function getSheetPngUrl(hash:String, sheet:String):String {
			if (!hash) return '';
			var cb:String = '';
			if (hash == default_hash) {
				if (placeholder_sheet_url) {
					hash = placeholder_sheet_url;
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.error('NO placeholder_sheet_url');
					}
				}
			} else {
				//cb = '?cb='+AvatarSSManager.cb;
			}
			return hash+'_'+sheet+'.png'+cb;
		}
		
		private static function aSheetPngHasLoaded(bmd_key:String, bm:Bitmap):void {
			//Console.info('loaded '+bmd_key);
			//Console.dir(png_sheet_bmd_key_map[bmd_key]);
			
			if (!bm) {
				// failed to load bm, so don't try to recordAnim again, which should leave things as wireframe avatar
				CONFIG::debugging {
					Console.log(113, 'no bm for '+bmd_key);
				}
				bm_load_fail_sig.dispatch();
			} else if (png_sheet_bmd_key_map[bmd_key]) {
				
				var ss:SSMultiBitmapSheet = png_sheet_bmd_key_map[bmd_key].ss;
				ss.sheetHasLoaded(bmd_key);
				var sheet:String = png_sheet_bmd_key_map[bmd_key].sheet;
				var hash:String = png_sheet_bmd_key_map[bmd_key].hash;
				
				var animA:Array = AvatarAnimationDefinitions.getAnimsForSheet(sheet);
				var anim:String;
				var ss_view:ISpriteSheetView;
				//Console.info(AssetManager.instance.getLoadedBitmapData(bmd_key));
				
				anim_loop: for each (anim in animA) {
					CONFIG::debugging {
						Console.log(113, 'recreating '+anim+' for '+hash);
					}
					recordAnim(anim, ss, null, hash);
				}
				
			}
			
			// we can't do this synchronously because it will fuck the callback loop that called this callback
			StageBeacon.waitForNextFrame(AssetManager.instance.removeLoadedBitmapData, bmd_key);
			png_sheet_bmd_key_map[bmd_key] = null;
			delete png_sheet_bmd_key_map[bmd_key];
			is_loading_sheet_png = false;
			StageBeacon.waitForNextFrame(loadFromSheetPngQ);
		}
		
		private static function recordAnim(anim:String, ss:SSMultiBitmapSheet, ac:AvatarConfig = null, hash:String = ''):void {
			CONFIG::debugging {
				var start_ts:int = getTimer();
				Console.log(113, 'start '+anim);
			}
			
			var name_prefix:String = (ac) ? ac.pc_tsid : hash;
			var fns:Array = [];
			var frame:SSFrame;
			var frame_to_copy:SSFrame;
			var ss_to_copy_from:SSMultiBitmapSheet;
			var log_rect_size:int;
			var log_rect_str:String = '';
			var sheet:String;
			var bmd_key:String;
			var rect:Rectangle;
			var bmd:BitmapData;
			var rerecording:Boolean = true;
			
			var copied_bmd:BitmapData;
			var bmd_to_copy:BitmapData;
			var copy_pt:Point = new Point();
			var from_where:String = '';
			
			var fc:SSFrameCollection = ss.getFrameCollectionByName(anim);
			if (!fc) {
				rerecording = false;
				fc = ss.createNewFrameCollection(anim);
			}
			
			ss.setActiveFrameCollection(anim);
			ss.startRecord();
			
			if (!_lazy_ss && !load_ava_sheets_pngs) setUpAvatarWithConfig(ac);
			
			var framesA:Array = AvatarAnimationDefinitions.getFramesForAnim(anim);
			var sheet_bmd:BitmapData;
			var frame_name:String;
			var fn:int; // the number of the frame on the timeline
			var fi:int; // the index of the frame number in framesA
			var f_w:int;
			var f_h:int;
			Tim.stamp(222, 'start Avatar recordAnim '+anim+' '+framesA);
			//if (ac && ac.acr && ac.acr.ava_swf) ac.acr.ava_swf.do_correct_hair = (AvatarAnimationDefinitions.emotion_animsA.indexOf(anim) > -1);
			for (fi=0;fi<framesA.length;fi++) {
				fn = framesA[fi];
				ss_to_copy_from = null;
				frame_to_copy = ss.source_swf_fn_to_frame_map[fn];
				fns.push(fn);
				frame_name = name_prefix+':'+anim+':'+fi+':'+fn;
				bmd = null;
				
				if (rerecording) {
					frame = fc.getFrameByName(frame_name);
					
					if (!frame) {
						CONFIG::debugging {
							Console.error('something is fucked');
						}
						return;
					}
					
					if (!frame.has_temp_bmd) {
						Tim.stamp(222, 'DOING NOTHING #'+fns.length+' fi:'+fi+' fn:'+fn);
						continue;
					}
					
					fc.using_avatar_placeholder = false;
					
					delete ss.source_swf_fn_to_frame_map[fn]; // get rid of this as it may be from the default set
				} else {
					if (load_ava_sheets_pngs) {
						frame = ss.recordFrame(null, frame_name, ss_options);
					} else {
						if (!ac) {
							CONFIG::debugging {
								Console.error('something is fucked, no ac');
							}
							return
						}
						if (!ac.acr) {
							CONFIG::debugging {
								Console.error('something is fucked, no ac.acr');
							}
							return
						}
						if (!ac.acr.ava_swf) {
							CONFIG::debugging {
								Console.error('something is fucked, no ac.acr.ava_swf');
							}
							return
						}
						frame = ss.recordFrame(ac.acr.ava_swf, frame_name, ss_options);
					}	
				}
				
				if (frame_to_copy && frame_to_copy.has_bmd && !frame_to_copy.has_temp_bmd) {
					// we have a frame to copy and do not need to do anything else
					ss.copyFrame(frame, frame_to_copy);
					Tim.stamp(222, 'copyFrame #'+fns.length+' fi:'+fi+' fn:'+fn);
					
				} else if (load_ava_sheets_pngs) { // create frame data from a loaded png
					sheet = AvatarAnimationDefinitions.getSheetForSwfFrameNum(fn);
					bmd_key = getSheetPngUrl(hash, sheet);
					sheet_bmd = AssetManager.instance.getLoadedBitmapData(bmd_key);
					
					if (!sheet_bmd) {
						
						// we do not have it loaded yet, use default instead
						
						if (hash == default_hash) {
							CONFIG::debugging {
								Console.error('something is fucked');
							}
							ss.stopRecord();
							return;
						}
						if (ss.hasLoadedBaseSheet() && AvatarAnimationDefinitions.getStandInFrameForAnim(anim) > 0) {
							from_where = 'basesheet';
							ss_to_copy_from = ss;
							frame_to_copy = ss.source_swf_fn_to_frame_map[AvatarAnimationDefinitions.getStandInFrameForAnim(anim)]; // 801 is idle0
						} else {
							from_where = 'placeholder';
							fc.using_avatar_placeholder = true;
							ss_to_copy_from = default_ss as SSMultiBitmapSheet;
							frame_to_copy = default_ss.source_swf_fn_to_frame_map[fn];
						}
						
						if (!frame_to_copy || !frame_to_copy.has_bmd) {
							CONFIG::debugging {
								Console.error('something is fucked');
							}
							return;
						}
						
						if (hash) {
							if (!png_sheet_bmd_key_map[bmd_key]) {
								//Console.info('now load '+bmd_key);
								png_sheet_bmd_key_map[bmd_key] = {
									ss: ss,
									sheet: sheet,
									hash: hash
								}
								if (AssetManager.instance.isBMLoading(bmd_key)) {
									// this'll get aSheetPngHasLoaded in the callbackA for when it loads
									AssetManager.instance.loadBitmapFromWeb(bmd_key, aSheetPngHasLoaded, 'recordAnim()');
								} else {
									sheet_pngQ.push(bmd_key);
									loadFromSheetPngQ();
								}
							}
						}
						
						ss.copyFrame(frame, frame_to_copy);
						
						bmd_to_copy = SSMultiBitmapSheet(ss_to_copy_from).bmds[frame_to_copy.bmd_index];
						
						if (clone_standin_bmds) {
							// let's copy pixels instead of clone()
							copied_bmd = new BitmapData(bmd_to_copy.width, bmd_to_copy.height);
							copied_bmd.copyPixels(bmd_to_copy, bmd_to_copy.rect, copy_pt);
							// we used to clone(), but maybe the above is a hair faster?
							//copied_bmd = bmd_to_copy.clone();
						} else {
							copied_bmd = bmd_to_copy;
						}
						
						frame._bmd_index = ss.bmds.push(copied_bmd)-1;
						frame.has_temp_bmd = true;
						Tim.stamp(222, 'copyFrame from '+from_where+' #'+fns.length+' fi:'+fi+' fn:'+fn);
						
					} else {
						
						ss.sheetHasLoaded(bmd_key); // we do this here too, just in case the sheet was loaded out of bounds
						f_w = sheet_bmd.width  / AvatarAnimationDefinitions.getColsForSheet(sheet);
						f_h = sheet_bmd.height / AvatarAnimationDefinitions.getRowsForSheet(sheet);
						rect = AvatarAnimationDefinitions.getRectangleForSwfFrameNum(fn, f_w, f_h);
						
						// first get the fill frame
						
						var err_desc:String;
						if (remove_empty_pixels) {
							// blit to a reusable BMD so we can getColorBoundsRect
							reusable_avatar_frame_bmd.fillRect(reusable_avatar_frame_bmd.rect, 0);
							reusable_avatar_frame_bmd.copyPixels(sheet_bmd, rect, ORIGIN);
							
							// find the non transparent bounds and ensmallen the rect
							var bounds:Rectangle = reusable_avatar_frame_bmd.getColorBoundsRect(0xFFFFFFFF, 0x000000, false);
							rect.x += bounds.x
							rect.y += bounds.y;
							
							// account for the possibility that there is nothing in this frame by using the default f_w/f_h if width/height are zero
							rect.width  = bounds.width  || f_w;
							rect.height = bounds.height || f_h;
							
							// now reget the pixels with only the necessary pixels
							try {
								bmd = new BitmapData(rect.width, rect.height);
								bmd.copyPixels(sheet_bmd, rect, ORIGIN);
							} catch (err:Error) {
								err_desc = 'error_making_bmd '+
									' sheet:'+sheet+
									' rect:'+rect+
									' bmd_key:'+bmd_key+
									' sheet_bmd.width:'+sheet_bmd.width+
									' sheet_bmd.height:'+sheet_bmd.height+
									' f_w:'+f_w+
									' f_h:'+f_h;
								BootError.handleError(err_desc, err, ['spritesheet']);
							}
							
							// fix the originalBounds rect
							rect.x = -Math.round((f_w - (ss_options.scale*ss_options.movieWidth)) * 0.5);
							rect.y = -Math.round((f_h - (ss_options.scale*ss_options.movieHeight)) + AvatarAnimationDefinitions.frame_offset_y);
							rect.x += bounds.x;
							rect.y += bounds.y;
							rect.width  = bounds.width;
							rect.height = bounds.height;
							frame.originalBounds = rect;
						} else {
							// keep all extra transparent space in the frame
							// since we don't use this code anymore, I removed the excessive try catch crap
							bmd = new BitmapData(f_w, f_h);
							bmd.copyPixels(sheet_bmd, rect, ORIGIN);
							rect.x = -Math.round((f_w - (ss_options.scale*ss_options.movieWidth)) * 0.5);
							rect.y = -Math.round((f_h - (ss_options.scale*ss_options.movieHeight)) + AvatarAnimationDefinitions.frame_offset_y);
							frame.originalBounds = rect;
						}
						
						Tim.stamp(222, 'copyPixels #'+fns.length+' fi:'+fi+' fn:'+fn);
						
						if (rerecording) {
							if (clone_standin_bmds) {
								ss.bmds[frame._bmd_index].dispose();
							} else {
								// we 're acutally reusing the bmd, so do not dispose() it! it is being borrowed from either the placeholder avatar or another animation of this avatar
							}
							ss.bmds[frame._bmd_index] = bmd;
							
							// TODO, check all views of this viewSprite and update them with the new shit
							
						} else {
							frame._bmd_index = ss.bmds.push(bmd)-1;
						}
						
						frame.has_bmd = true;
						frame.has_temp_bmd = false;
					}
					
				} else if (!_lazy_ss) {
					ac.acr.ava_swf.playFrameSeq([fn]);
					ss.snapFrame(ac.acr.ava_swf, frame, ss_options);
					Tim.stamp(222, 'snapFrame #'+fns.length+' fi:'+fi+' fn:'+fn);
					
				} else {
					lazy_frame_map[frame] = {
						anim:anim, 
						fi:fi, 
						fn:fn, 
						ac:ac
					}
				}
				
				// remember this so we can reuse it!
				//if (!ss.source_swf_fn_to_frame_map[fn]) {
				ss.source_swf_fn_to_frame_map[fn] = frame;
				//}
				
				if (frame.has_bmd) {
					log_rect_size+= (frame.originalBounds.height*frame.originalBounds.width);
					Tim.stamp(222, 'recordFrame #'+fns.length+' fi:'+fi+' fn:'+fn+' rect:'+frame.originalBounds+' '+(frame.originalBounds.height*frame.originalBounds.width)+'px');
				} else {
					Tim.stamp(222, 'recordFrame #'+fns.length+' fi:'+fi+' fn:'+fn);
				}
				
			}
			
			if (rerecording) {
				for (var p:int;p<ss.ss_views.length;p++) {
					if (ss.ss_views[p].frame_coll_name == fc.name) {
						//Console.info('rerender!');
						ss.updateViewSprite(ss.ss_views[p] as SSViewSprite);
					} 
				}
			}
			
			if (log_rect_size) {
				log_rect_str = ' (pixels:'+log_rect_size+')';
			}
			
			Tim.report(222, 'Avatar recordAnim '+name_prefix+' '+anim+' (frames:'+fns.length+')'+log_rect_str, true);
			
			ss.stopRecord();
			CONFIG::debugging {
				Console.log(113, 'recorded '+anim+' in '+StringUtil.formatNumber((getTimer()-start_ts)/1000, 4)+'secs fns:'+fns.join(', '));
				// this will always just report the last time for the given anim, regardless of the ac it was created for (ss._name gives the unique key if you want to track it per ac)
				Console.trackValue('Z ASSM '+anim, StringUtil.formatNumber((getTimer()-start_ts), 2)+ 'ms');
			}
		}
		
		private static function makeSSForAvaHash(hash:String, make_all:Boolean):SSAbstractSheet {
			var do_not_clean:Boolean = false;
			var animA:Array = required_anims;
			
			if (hash == default_hash) {
				do_not_clean = true;
				animA = anims;
			}
			
			if (make_all) animA = anims;
			
			CONFIG::debugging {
				Console.log(113, 'creating '+hash);
			}
			
			var ss:SSMultiBitmapSheet = ssCollection.createNewSpriteSheet(hash, ss_options, null, do_not_clean) as SSMultiBitmapSheet;
			
			var anim:String;
			var framesA:Array;
			var fn:int;
			var pt:Point = new Point();
			var sheet:String;
			var rect:Rectangle;
			var bm:Bitmap;
			var bmd:BitmapData;
			var bmd_key:String;
			
			var new_x:int = 0;
			var new_y:int = 0;
			
			for each (anim in animA) {
				CONFIG::debugging {
					Console.log(113, 'creating animA '+anim);
				}
				recordAnim(anim, ss, null, hash);
			}
			
			for each(sheet in AvatarAnimationDefinitions.sheetsA) {
				bmd_key = getSheetPngUrl(hash, sheet);
				AssetManager.instance.removeLoadedBitmapData(bmd_key);
				//Console.info('removed '+bmd_key+' in makeSSForAvaHash');
			}
			
			//TSFrontController.instance.addUnderCursor(mc);
			
			return ss;
			
		}
		
		private static function makeSSForAvaConfig(ac:AvatarConfig, make_all:Boolean):SSAbstractSheet {
			var key:String = getKeyForAvaConfig(ac);
			//Console.dir(ac)
			
			var do_not_clean:Boolean = false;
			var animA:Array = required_anims;
			
			if (ac.pc_tsid == default_hash) {
				do_not_clean = true;
				animA = anims;
			}
			
			if (make_all) animA = anims;
			
			animA = anims;
			
			CONFIG::debugging {
				Console.log(113, 'creating '+key);
			}
			
			var ss:SSMultiBitmapSheet = ssCollection.createNewSpriteSheet(key, ss_options, lazySnap, do_not_clean) as SSMultiBitmapSheet;
			
			var anim:String;
			
			for each (anim in animA) {
				CONFIG::debugging {
					Console.log(113, 'creating animA '+anim);
				}
				recordAnim(anim, ss, ac);
			}
			
			return ss;
		}
		
		public static function makeSheetBitmap(ss:SSMultiBitmapSheet, sheet:String):BitmapData {
			var framesA:Array = AvatarAnimationDefinitions.getFramesForSheet(sheet);
			
			var offset_y:int = AvatarAnimationDefinitions.frame_offset_y;
			var f_w:int = AvatarAnimationDefinitions.frame_w;
			var f_h:int = AvatarAnimationDefinitions.frame_h;
			var movie_w:int = Math.round(ss_options.movieWidth*ss_options.scale);
			var movie_h:int = Math.round(ss_options.movieHeight*ss_options.scale);
			var cols:int = AvatarAnimationDefinitions.getColsForSheet(sheet);
			var rows:int =  Math.ceil(framesA.length/cols);
			var full_bmd:BitmapData;
			
			var frame:SSFrame;
			var bmd:BitmapData;
			var rect:Rectangle = new Rectangle(0, 0, 0, 0);
			var pt:Point = new Point(0, 0);
			var row:int;
			var col:int;
			var fn:int; // the number of the frame on the timeline
			var i:int;
			
			if (true) {
				
				// this recalcs f_w_adj && f_h_adj and thus eliminates a lot of white space, but still leaves
				// things positioned so that we can extract it with proper registration for each frame
				
				var this_w:int;
				var this_h:int;
				var left_x:int;
				var right_x:int;
				var top_y:int;
				var f_w_adj:int = 0; // we'll adjust to be only as big as the biggest frame in this sheet
				var f_h_adj:int = 0; // we'll adjust to be only as big as the biggest frame in this sheet
				
				// find max size
				for (i=0;i<framesA.length;i++) {
					fn = framesA[int(i)];
					frame = ss.source_swf_fn_to_frame_map[fn];
					
					if (frame.bmd_index == -1 && lazy_frame_map[frame]) {
						lazySnap(ss, frame);
					}
					
					if (frame.bmd_index == -1) {
						CONFIG::debugging {
							Console.warn(fn+' has no bmd');
						}
						return null;
					}
					
					bmd = ss.bmds[frame.bmd_index];
					
					rect.width = bmd.width;
					rect.height = bmd.height;
					left_x = (Math.round(f_w-movie_w)/2)+frame.originalBounds.x;
					top_y = (f_h-movie_h+offset_y)+frame.originalBounds.y;
					
					right_x = left_x+rect.width;
					
					this_w = Math.max(f_w-(left_x*2), f_w-((f_w-right_x)*2));
					this_h = f_h-(top_y);
					
					if (this_w > f_w_adj) f_w_adj = this_w;
					if (this_h > f_h_adj) f_h_adj = this_h;
					
					//Console.info('left_x:'+left_x+' this_w:'+this_w+' f_w_adj:'+f_w_adj+' f_h_adj:'+f_h_adj)
				}
				
				f_w = Math.min(f_w_adj, f_w);
				f_h = Math.min(f_h_adj, f_h);
			}
			
			var bm_w:int = Math.min(f_w*framesA.length, f_w*cols);
			var bm_h:int = f_h*rows;
			
			CONFIG::debugging {
				Console.warn(sheet+' '+bm_w+'X'+bm_h);
			}
			
			// create the output bmd
			full_bmd = new BitmapData(bm_w, bm_h, true, 0xffffff);
			
			for (i=0;i<framesA.length;i++) {
				col = (i % cols);
				row = Math.floor(i / cols);
				fn = framesA[int(i)];
				frame = ss.source_swf_fn_to_frame_map[fn];
				bmd = ss.bmds[frame.bmd_index];
				
				rect.width = bmd.width;
				rect.height = bmd.height;
				pt.x = (f_w*col)+(Math.round(f_w-movie_w)/2)+frame.originalBounds.x;
				pt.y = (f_h*row)+(f_h-movie_h+offset_y)+frame.originalBounds.y;
				
				if (EnvironmentUtil.getUrlArgValue('SWF_ss_opaque') == '1') {
					full_bmd.fillRect(new Rectangle((f_w*col), (f_h*row), f_w, f_h), ColorUtil.getRandomColor());
				}
				
				full_bmd.copyPixels(bmd, rect, pt);
				
				//Console.warn(sheet+' '+fn+' '+(f_w_a*col)+':'+(f_h_a*row));
			}
			
			return full_bmd;
		}
	}
}