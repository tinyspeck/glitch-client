package com.tinyspeck.engine.spritesheet {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.ItemstackState;
	import com.tinyspeck.engine.loader.SmartLoader;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.MCUtil;
	import com.tinyspeck.engine.util.ObjectUtil;
	import com.tinyspeck.engine.util.SWFReader;
	import com.tinyspeck.engine.vo.ItemstackLoadVO;
	
	import de.polygonal.core.ObjectPool;
	
	import flash.display.MovieClip;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	/**
	 * Asynchronously loads SWFs for Items, generates spritesheets for them,
	 * and returns those sheets via callback. All functions are guaranteed to
	 * do their callbacks asynchronously at a later time, never synchronously.
	 */
	public class ItemSSManager {
		public static const DEFAULT_SCENE_NAME:String = '1';
		
		/** Contains TSIDs that should be processed before all others */
		private static const HIGH_PRIORITY:Vector.<String> = new <String>['pet_rock', 'street_spirit', 'rook_head'];
		
		private static const urlToSWFData:Dictionary = new Dictionary();
		private static const ssCollection:SSCollection = new SSCollection();
		private static const view_and_state_ob:Object = {};
		private static const sl_to_vo_map:Dictionary = new Dictionary();
		
		///////////// loading pipeline /////////////////////////////////////////
		/** SWFDatas being loaded; a new SWFData starts here */
		private static const loadingSWFs:Vector.<SWFData> = new Vector.<SWFData>();
		/** SWFDatas loaded and waiting to get their sheets generated */
		private static const loadedSWFs:Vector.<SWFData> = new Vector.<SWFData>();
		/** SWFDatas with their sheets generated waiting to do callbacks; after this, SWFDatas only persist in urlToSWFData */
		private static const sheetedSWFs:Vector.<SWFData> = new Vector.<SWFData>();
		/** Misc callbacks to run on the next frame */
		private static const delayedCallbacks:Vector.<SSCallback> = new Vector.<SSCallback>();
		////////////////////////////////////////////////////////////////////////
		
		// grows dynamically since we use a variable amount
		private static const CallbackPool:ObjectPool = new ObjectPool(true);
		{ // static init
			CallbackPool.allocate(SSCallback, 100, 100, resetSSCallback);
		}
		
		CONFIG::god public static function memReport():String {
			var str:String = '\nItemSSManager memReport\n+--------------------------------------------------\n';
			str += ssCollection.memReport();
			return str;
		}
		
		public static function onEnterFrame(ms_elapsed:int):void {
			ssCollection.update();
			
			//CONFIG::debugging {
			//	if (delayedCallbacks.length || loadingSWFs.length || loadedSWFs.length || sheetedSWFs.length) {
			//		trace(toString());
			//	}
			//}
			
			
			CONFIG::debugging {
				Console.trackValue('ISSM.delayedCallbacks', delayedCallbacks.length);
				Console.trackValue('ISSM.loadingSWFs', loadingSWFs.length);
				Console.trackValue('ISSM.loadedSWFs', loadedSWFs.length);
				Console.trackValue('ISSM.sheetedSWFs', sheetedSWFs.length);
			}
			
			const timeAvailable:int = TSModelLocator.instance.flashVarModel.async_timeslice_ms;
			const startTime:int = getTimer();
			
			while (doNextDelayedCallback()) {
				if ((getTimer() - startTime) > timeAvailable) return;
			}
			
			while (doNextHighestPriorityCallback()) {
				if ((getTimer() - startTime) > timeAvailable) return;
			}
			
			while (generateNextHighestPrioritySS()) {
				if ((getTimer() - startTime) > timeAvailable) return;
			}
		}
		
		public static function toString():String {
			return "ItemSSManager:[\n" +
				"\tcallbacks: " + delayedCallbacks.length  + ",\n" +
				"\t  loading: " + loadingSWFs.length       + ",\n" +
				"\t   loaded: " + loadedSWFs.length        + ",\n" +
				"\t  sheeted: " + sheetedSWFs.length       + "\n"  +
				"]";
		}
		
		public static function getSWFDataByUrl(url:String):SWFData {
			return urlToSWFData[url];
		}
		
		/** For trants */
		public static function getSeedForItemSWFByUrl(url:String, item:Item):Number {
			var swf_data:SWFData = getSWFDataByUrl(url);
			
			if (!swf_data || !swf_data.mc) {
				CONFIG::debugging {
					Console.error('something has gone horribly awry')
				}
				return 0;
			}
			
			if (!swf_data.seed) {
				var seed:String = '';
				for (var i:int=item.tsid.length-1;i>0;i--) {
					seed+= String(item.tsid.charCodeAt(i)).substr(0, 1);
					if (seed.length > 8) break;
				}
				swf_data.seed = parseFloat('.'+seed);
			}
			return swf_data.seed;
		}
		
		/** This confirms we have an object as the state for a trant (some bad messaging from the GS sometimes sends an int for the s) */
		public static function checkStateForTrantIsOk(used_swf_url:String, itemstack_state:ItemstackState):Boolean {
			var swf_data:SWFData = ItemSSManager.getSWFDataByUrl(used_swf_url);
			if (swf_data.is_trant) {
				if (itemstack_state.type == ItemstackState.TYPE_DEFAULT) {
					CONFIG::debugging {
						Console.warn('WTF it looks like a state for a trant is not an object? itemstack_state.value:'+itemstack_state.value);
					}
					return false;
				}
			}
			return true;
		}
		
		/** Builds a key which is used for identifying a SSFrameCollection */
		private static function buildFrameCollectionKey(url:String, item:Item, anim_cmd:SSAnimationCommand, at_wh:int, scale_to_stage:Boolean, config_sig:String):String {
			var key:String = "";
			
			if (anim_cmd.state_args) {
				anim_cmd.state_args.seed = ItemSSManager.getSeedForItemSWFByUrl(url, item);
				key += ObjectUtil.makeSignatureForHash(anim_cmd.state_args);
			} else {
				key = anim_cmd.state_str;
			}
			key += ':' + at_wh + ':' + String(scale_to_stage) + ':' + String(anim_cmd.scale);
			key = item.tsid + ':' + config_sig + key;
			
			return key;
		}		
		
		/** Plays an animation for an SSView. If a frame collection does not exist for the desired animation, 
		 * it will be created and the animation will be played once creation is complete */
		public static function playSSViewForItemSWFByUrl(url:String, item:Item, ss_view:ISpriteSheetView, frame_num:int, anim_cmd:SSAnimationCommand, action:Function=null, at_wh:int=0, scale_to_stage:Boolean=false):void {
			if (!anim_cmd) {
				CONFIG::debugging {
					Console.error(item.tsid+' with null/empty state_ob');
				}
				return;
			}
			
			// get the name of the current frame collection
			var was_name:String = (ss_view.frame_coll_name ? ss_view.frame_coll_name : null);
			
			var ss:SSAbstractSheet = ss_view.ss;
			
			// if there is no animation command, log it and return null
			if (!anim_cmd) {
				CONFIG::debugging {
					Console.error("Specified SSAnimationCommand was null.  Item.tsid : " + item.tsid + " (null/empty state_ob).");
				}
				return;
			}
			
			// make sure the specified url points to valid swf data.
			var swf_data:SWFData = ItemSSManager.getSWFDataByUrl(url);
			if (!swf_data || !swf_data.mc) {
				CONFIG::debugging {
					Console.error("URL does not refer to valid SWFData : " + url + ".")
				}
				return;
			}
			
			// assumption in this logic is that only is_timeline_animated item swfs need config as part of unique identifer for frameCollections
			// which might not always be true!
			var config_sig:String = (anim_cmd.config && swf_data.is_timeline_animated) ? ObjectUtil.makeSignatureForHash(anim_cmd.config) : "";
			
			// this is the key for the frame collections
			var key:String = buildFrameCollectionKey(url, item, anim_cmd, at_wh, scale_to_stage, config_sig); 
			
			// try to get an existing collection
			var ssfc:SSFrameCollection = ss.getFrameCollectionByName(key);
			if (!ssfc) ssfc = ss.getFrameCollectionByAlias(key);
			
			var fcByURLRequest:FrameCollectionByURLRequest = new FrameCollectionByURLRequest(key, config_sig, swf_data, url, item, ss, frame_num, anim_cmd, at_wh, scale_to_stage, ssCollection, 
				view_and_state_ob, action, ss_view, was_name, onFrameCollectionRequestComplete);
			
			// if we still don't have the frame collection, create it.
			if (!ssfc) {
				ItemFrameCollectionRecorder.instance.getFrameCollectionForItemSWFByUrl(fcByURLRequest);
				return;
			}
			
			// if we already have a frame collection, play it
			fcByURLRequest.ssFrameCollection = ssfc;
			onFrameCollectionRequestComplete(fcByURLRequest);
		}
		
		/** Handles playing an animatin for an SSView once its FrameCollection has been created */
		private static function onFrameCollectionRequestComplete(fcByURLRequest:FrameCollectionByURLRequest):void {
			
			var ss:SSAbstractSheet = fcByURLRequest.ss;
			var anim_cmd:SSAnimationCommand = fcByURLRequest.anim_cmd;
			var ssfc:SSFrameCollection = fcByURLRequest.ssFrameCollection;
			var action:Function = fcByURLRequest.action;
			var ss_view:ISpriteSheetView = fcByURLRequest.ss_view;
			var frame_num:int = fcByURLRequest.frame_num;
			var item:Item = fcByURLRequest.item;
			var was_name:String = fcByURLRequest.was_name;
			var key:String = fcByURLRequest.key;
			
			CONFIG::debugging {
				Console.log(111, ss.name+' anim_cmd.state_str:'+anim_cmd.state_str+' anim_cmd.state_ob:'+anim_cmd.state_ob+' typeof anim_cmd.state_ob:'+(typeof anim_cmd.state_ob));
			}
			
			// log the action that was taken.
			CONFIG::debugging {
				if (ssfc) {
					Console.log(111, 'default_action for '+item.tsid+' (ssfc:'+ssfc.name+') key:'+key+': '+ssfc.default_action)
				} else {
					Console.warn(item.tsid+' has no frameCollection for key:'+key);
				}
			}
			
			if (action == null) {
				if (ssfc) {
					action = ss_view[ssfc.default_action];
				} else {
					action = ss_view.gotoAndStop;
				}	
			}
			
			if (ssfc) action(frame_num, ssfc.name);
			
			// if it is furniture, discard the previous frame collection, which will dispose its bitmapdata
			if ((item.is_furniture || item.is_special_furniture) && was_name && was_name != ss_view.frame_coll_name) {
				ss_view.ss.removeFrameCollection(was_name);
			}
		}
		
		public static function getViewAndState(state_str:String, reusable_ob:Object):void {
			var play_anim_str:String = '';
			var view_str:String = '';
			
			if (state_str) {
				play_anim_str = state_str;
				if (play_anim_str.indexOf('-rooked') > -1) {
					view_str = 'rooked'
					play_anim_str = play_anim_str.replace('-rooked', '');
				}
				if (play_anim_str.indexOf('-top') > -1) {
					view_str = 'top'
					play_anim_str = play_anim_str.replace('-top', '');
				}
				if (play_anim_str.indexOf('-side') > -1) {
					view_str = 'side'
					play_anim_str = play_anim_str.replace('-side', '');
				}
				if (play_anim_str.indexOf('-angle1') > -1) {
					view_str = 'angle1'
					play_anim_str = play_anim_str.replace('-angle1', '');
				}
				if (play_anim_str.indexOf('-angle2') > -1) {
					view_str = 'angle2'
					play_anim_str = play_anim_str.replace('-angle2', '');
				}
			}
			
			reusable_ob.view_str = view_str;
			reusable_ob.play_anim_str = play_anim_str;
		}
		
		public static function removeSSViewforItemSWFByUrl(url:String, item:Item, ss_view:ISpriteSheetView):void {
			const spriteSheet:SSAbstractSheet = ssCollection.getSpriteSheet(url);
			if (!spriteSheet) {
				CONFIG::debugging {
					Console.warn('spriteSheet for '+item.tsid+' '+url+' no exist');
				}
				return;
			}
			if (ss_view is SSViewBitmap) {
				spriteSheet.removeViewBitmap(ss_view as SSViewBitmap);
			} else if (ss_view is SSViewSprite) {
				spriteSheet.removeViewSprite(ss_view as SSViewSprite);
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.error('ss_view is not a SSViewBitmap or a SSViewSprite')
				}
			}
			
			ssCollection.cleanup();
		}
		
		public static function getFreshMCForItemSWFByUrl(url:String, item:Item, callBack:Function):void {
			const swf_data:SWFData = getSWFDataByUrl(url);
			
			// if we've already loaded for this tsid
			if (swf_data && swf_data.loaded) {
				CONFIG::debugging {
					Console.log(111, 'have loaded swf_data '+item.tsid+' '+url);
				}
				
				const mc:MovieClip = swf_data.getReusableMC();
				if (mc) {
					// we must make sure it is tracking frames, because stopTrackFrames may have been called on it by the previous class using it
					if ('trackFrames' in mc) mc.trackFrames();
					StageBeacon.waitForNextFrame(callBack, mc, url);
				} else {
					const vo:ItemstackLoadVO = new ItemstackLoadVO(url, item);
					swf_data.freshSWFCallbackMap[vo] = callBack;
					
					sl_to_vo_map[TSFrontController.instance.loadItemstackSWF(item.tsid, url, freshSWFLoadHandler, freshSWFLoadErrorHandler)] = vo;
				}
			} else {
				// first time a ss for this tsid has been requested
				; // satisfy compiler
				CONFIG::god {
					// TODO: WHY THIS ERROR? WHY NOT ALLOW IT? NEED TO TEST AND SEE -- I think because we use the swf_data to know how to treat the mc, so
					// to fix I think we could have this method do the same things as getSSForItem (seetting up the swf_data) and have _freshSWFLoadHandler do
					// the same things as _SWFLoadHandler (measuring, updating the swf_data)
					throw new Error("Can't retrieve a fresh item swf until is has been loaded once, dude.");
				}
			}
		}
		
		private static function freshSWFLoadErrorHandler(sl:SmartLoader):void {
			var vo:ItemstackLoadVO = sl_to_vo_map[sl];
			var tsid:String = vo.item.tsid;
			var url:String = vo.swf_url;
			var swf_data:SWFData = getSWFDataByUrl(url);
			
			if (!swf_data) {
				CONFIG::debugging {
					Console.error('no swf_data for '+tsid+' '+url);
				}
				return;
			}
			
			if (!TSModelLocator.instance.flashVarModel.break_item_asset_loading) {
				BootError.handleError('freshSWFLoadErrorHandler called for '+tsid+' '+url, new Error((sl.totalRetries+1)+" load attempts failed"), ['spritesheet','loader'], true, false);
			}
			
			delete sl_to_vo_map[sl];
		}
		
		private static function freshSWFLoadHandler(sl:SmartLoader):void {
			var vo:ItemstackLoadVO = sl_to_vo_map[sl];
			var tsid:String = vo.item.tsid;
			var url:String = vo.swf_url;
			var swf_data:SWFData = getSWFDataByUrl(url);
			
			if (!swf_data) {
				CONFIG::debugging {
					Console.error('no swf_data for '+tsid+' '+url);
				}
				return;
			}
			
			if (sl.content) {
				var mc:MovieClip = sl.content as MovieClip;
				CONFIG::debugging {
					if (Console.priOK('112') || Console.priOK('153')) if (mc.hasOwnProperty('setConsole')) mc.setConsole(Console);
				}
				if (mc.hasOwnProperty('itemRun')) mc.itemRun();
				swf_data.freshSWFCallbackMap[vo](mc, url);
				swf_data.freshSWFCallbackMap[vo] = null;
				delete swf_data.freshSWFCallbackMap[vo];
			} else {
				BootError.handleError('freshSWFLoadHandler called for '+tsid+' '+url, new Error("loaderItem.content is null"), ['spritesheet','loader']);
			}
		}
		
		/** Synchronously returns a spritesheet IF one is already available for the given URL, else null */
		public static function getSSByUrl(url:String):SSAbstractSheet {
			const swf_data:SWFData = getSWFDataByUrl(url);
			// we've already seen a request for this tsid
			if (swf_data) {
				if (swf_data.sheeted) {
					// sheets are available
					return ssCollection.getSpriteSheet(url);
				}
			}
			return null;
		}
		
		/** Asynchronous. Callback is optional and of signature: function(ss:SSAbstractSheet):void {} */
		public static function getSSForItemSWFByUrl(url:String, item:Item, callback:Function = null):void {
			var swf_data:SWFData = getSWFDataByUrl(url);
			
			if (swf_data) { // we've already seen a request for this tsid
				CONFIG::debugging {
					Console.log(111, 'have swf_data '+item.tsid+' '+url);
				}
				
				if (swf_data.sheeted) {
					// sheets are available
					CONFIG::debugging {
						Console.log(111, 'already sheeted '+item.tsid+' '+url);
					}
					if (callback != null) {
						delayCallback(callback, ssCollection.getSpriteSheet(url), url);
					}
				} else {
					// sheets are not yet available
					CONFIG::debugging {
						if (swf_data.loaded) {
							// we've already finished loading the swf for this tsid
							Console.log(111, 'already loaded '+item.tsid+' '+url);
						} else if (swf_data.load_failed) {
							// the load failed at some point
							Console.log(111, 'load failed '+item.tsid+' '+url);
						} else {
							// a load for this swf is in progress
							Console.log(111, 'load in progress '+item.tsid+' '+url);
						}
					}
					
					if (callback != null) {
						if (swf_data.load_failed) {
							delayCallback(callback, null, url);
						} else {
							// store the requested callback
							swf_data.sheetedCallbacks.push(callback);
						}
					}
				}
				
			} else { // first time a ss for this tsid has been requested
				CONFIG::debugging {
					Console.log(111, 'no swf_data '+item.tsid+' '+url);
				}
				
				// create a swf_data
				swf_data = new SWFData(item, url);
				urlToSWFData[url] = swf_data;
				loadingSWFs.push(swf_data);
				
				// store the requested callback
				if (callback != null) {
					swf_data.sheetedCallbacks.push(callback);
				}
				
				const vo:ItemstackLoadVO = new ItemstackLoadVO(url, item);
				
				sl_to_vo_map[TSFrontController.instance.loadItemstackSWF(item.tsid, url, SWFLoadHandler, SWFLoadErrorHandler)] = vo;
				
			}
		}
		
		private static function SWFLoadErrorHandler(sl:SmartLoader):void {
			const vo:ItemstackLoadVO = sl_to_vo_map[sl];
			const tsid:String = vo.item.tsid;
			const url:String = vo.swf_url;
			const swf_data:SWFData = getSWFDataByUrl(url);
			
			if (!swf_data) {
				CONFIG::debugging {
					Console.error('no swf_data for '+tsid+' '+url);
				}
				return;
			}
			
			swf_data.load_failed = true;
			loadingSWFs.splice(loadingSWFs.indexOf(swf_data), 1);
			// putting it in the sheetedSWFs list will cause
			// doNextHighestPriorityCallbacks() to send nulls for the sheets
			// on the next frame
			sheetedSWFs.push(swf_data);
			if (!TSModelLocator.instance.flashVarModel.break_item_asset_loading) {
				BootError.handleError('SWFLoadErrorHandler called for '+tsid+' '+url, new Error((sl.totalRetries+1)+" load attempts failed"), ['spritesheet','loader'], true, false);
			}
			
			delete sl_to_vo_map[sl];
		}
		
		private static function SWFLoadHandler(sl:SmartLoader):void {
			const vo:ItemstackLoadVO = sl_to_vo_map[sl];
			const swf_data:SWFData = getSWFDataByUrl(vo.swf_url);
			
			if (!swf_data) {
				CONFIG::debugging {
					Console.error('no swf_data for '+vo.item.tsid+' '+vo.swf_url);
				}
				return;
			}
			
			const mc:MovieClip = sl.content as MovieClip;
			if (mc) {
				swf_data.loaded = true;
				
				var r:SWFReader = new SWFReader(sl.contentLoaderInfo.bytes);
				
				swf_data.mc = mc;
				swf_data.mc_w = Math.round(r.dimensions.width);
				swf_data.mc_h = Math.round(r.dimensions.height);
				swf_data.highest_count_scene_name = MCUtil.getHighestCountSceneName(swf_data.mc, DEFAULT_SCENE_NAME);
				swf_data.is_trant = (mc.hasOwnProperty('setState'));
				swf_data.is_timeline_animated = (mc.hasOwnProperty('animations') && mc.hasOwnProperty('animatee') && mc.animations && mc.animations.length > 0);
				
				// queue up this SWF for sheeting
				loadingSWFs.splice(loadingSWFs.indexOf(swf_data), 1);
				loadedSWFs.push(swf_data);
				loadedSWFs.sort(sortSWFDataByLoadPriority);
			} else {
				swf_data.load_failed = true;
				loadingSWFs.splice(loadingSWFs.indexOf(swf_data), 1);
				// putting it in the sheetedSWFs list will cause
				// doNextHighestPriorityCallbacks() to send nulls for the sheets
				// on the next frame
				sheetedSWFs.push(swf_data);
				BootError.handleError('SWFLoadHandler called for '+vo.item.tsid+' '+vo.swf_url, new Error("loaderItem.content is null"), ['spritesheet','loader']);
			}
			
			delete sl_to_vo_map[sl];
		}
		
		/** Returns true if work was done */
		private static function generateNextHighestPrioritySS():Boolean {
			if (loadedSWFs.length) {
				// grab the next swf and generate its sheets
				const swf_data:SWFData = loadedSWFs.shift();
				makeSSForUrl(swf_data.url, swf_data.item);
				return true;
			}
			return false;
		}
		
		/** Returns true if work was done */
		private static function doNextDelayedCallback():Boolean {
			if (delayedCallbacks.length) {
				const thunk:SSCallback = delayedCallbacks.shift();
				thunk.run();
				CallbackPool.returnObject(thunk);
				return true;
			}
			return false;
		}
		
		/** Returns true if work was done */
		private static function doNextHighestPriorityCallback():Boolean {
			if (sheetedSWFs.length) {
				// grab the next swf with generated sheets
				const swf_data:SWFData = sheetedSWFs[0];
				if (swf_data.sheetedCallbacks.length) {
					const callback:Function = swf_data.sheetedCallbacks.shift();
					const sheet:SSAbstractSheet = ssCollection.getSpriteSheet(swf_data.url);
					if (callback != null) callback(sheet, swf_data.url);
				}
				
				// when there are no more callbacks for this SWFData
				if (swf_data.sheetedCallbacks.length == 0) {
					// remove it so we can work on another
					sheetedSWFs.shift();
				}
				
				return true;
			}
			return false;
		}
		
		private static function sortSWFDataByLoadPriority(a:SWFData, b:SWFData):int {
			if (HIGH_PRIORITY.indexOf(a.item.tsid) != -1) {
				if (HIGH_PRIORITY.indexOf(b.item.tsid) != -1) {
					// equal priority
					return 0;
				} else {
					// left has higher priority
					return 1;
				}
			} else if (HIGH_PRIORITY.indexOf(b.item.tsid) != -1) {
				// right has higher priority
				return -1;
			} else {
				// equal priority
				return 0;
			}
		}
		
		private static function delayCallback(callback:Function, sheet:SSAbstractSheet, url:String):void {
			const thunk:SSCallback = CallbackPool.borrowObject();
			thunk.callback = callback;
			thunk.sheet = sheet;
			thunk.url = url;
			delayedCallbacks.push(thunk);
		}
		
		private static function get max_load_attempts_allowed():int {
			if (TSModelLocator.instance.flashVarModel.break_item_asset_loading) return 1;
			return 3;
		}
		
		public static var double_measure:Boolean = false;
		private static function makeSSForUrl(url:String, item:Item):void {
			const swf_data:SWFData = getSWFDataByUrl(url);
			
			if (!swf_data) {
				CONFIG::debugging {
					Console.error('no swf_data for '+item.tsid+' '+url);
				}
				// sheeting failed, queue it for callbacks
				// (SSCollection.getSpriteSheet() will return null)
				swf_data.sheeted = true;
				sheetedSWFs.push(swf_data);
				return;
			}
			
			const mc:MovieClip = swf_data.mc;
			if (!mc) {
				CONFIG::debugging {
					Console.warn('no mc for '+item.tsid+' '+url);
				}
				// sheeting failed, queue it for callbacks
				// (SSCollection.getSpriteSheet() will return null)
				swf_data.sheeted = true;
				sheetedSWFs.push(swf_data);
				return;
			}
			
			// set up options
			const ss_options:SSGenOptions = new SSGenOptions(
				SSGenOptions.TYPE_MULTIPLE_BITMAPS,
				swf_data.mc_w,
				swf_data.mc_h
			);

			ss_options.double_measure = double_measure;
			//ss_options.double_measure = true;
			if (swf_data.mc.hasOwnProperty('frame_padd')) {
				ss_options.frame_padd = swf_data.mc.frame_padd;
			}
			ss_options.transparent = (EnvironmentUtil.getUrlArgValue('SWF_ss_opaque') != '1');
			
			CONFIG::debugging {
				Console.log(111, 'creating '+item.tsid+' '+url);
			}
			
			// build the sheet
			ssCollection.createNewSpriteSheet(url, ss_options, null, false);
			
			// sheeting succeeded, queue it for callbacks
			// (SSCollection.getSpriteSheet() will grab the sheet later)
			swf_data.sheeted = true;
			sheetedSWFs.push(swf_data);
			sheetedSWFs.sort(sortSWFDataByLoadPriority);
		}
		
		private static function resetSSCallback(ssc:SSCallback):void {
			ssc.reset();
		}
	}
}
