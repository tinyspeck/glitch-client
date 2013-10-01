package com.tinyspeck.engine.view.renderer
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.memory.DisposableEventDispatcher;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.Center;
	import com.tinyspeck.engine.data.location.Deco;
	import com.tinyspeck.engine.data.location.Ladder;
	import com.tinyspeck.engine.data.location.Layer;
	import com.tinyspeck.engine.data.location.MiddleGroundLayer;
	import com.tinyspeck.engine.data.location.Tiling;
	import com.tinyspeck.engine.loader.SmartByteLoader;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	
	import de.polygonal.core.ObjectPool;
	
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;

	public final class DecoByteLoader extends DisposableEventDispatcher
	{
		public static const READYING_TEXT:String = 'preparing...';
		
		/** Reusable LoaderContext, though the AppDomain is reset each time */
		private static const LOADER_CONTEXT:LoaderContext = new LoaderContext(false);
		
		/**
		 * Technically we do not reuse the SmartLoaders in the pool (we return
		 * new SmartLoaders when we're done borrowing) -- we use it to
		 * efficiently track resources.
		 */
		private static const SmartLoaderPool:ObjectPool = new ObjectPool(false);
		
		private static var loadingMap:Dictionary;
		private static var loaderDecoClassesMap:Dictionary; // tied to actual usage
		private static var loaderDecoInstanceMap:Dictionary; // tied to actual usage
		private static var loaderDecoIndividualMap:Dictionary; // ad hoc loading
		private static var model:TSModelLocator;
		
		/** Just the class_names that are in use in this Location */
		private static const decoClassNamesToBeLoaded:Object = {};
		private static var decoClassNamesToBeLoadedCnt:int;
		private static var decoClassNamesLoadedCnt:int;
		
		/** Contains each individual Deco in use in this Location */
		private static const decoInstancesToBeLoaded:Vector.<Deco> = new Vector.<Deco>();
		private static var decoInstancesLoadedCnt:int;
		
		/** An array of objects with class_name and callback function props */
		private static const decoIndividualToBeLoaded:Vector.<IndividualDeco> = new Vector.<IndividualDeco>();
		private static var decoInstancesToBeLoaded_count:int;
		
		private static var decos_unpack_start:int;
		private static var decos_unpack_length:int;
		
		public static function init():void {
			const threads:int = (parseInt(EnvironmentUtil.getUrlArgValue('SWF_thread_cnt'))
				? parseInt(EnvironmentUtil.getUrlArgValue('SWF_thread_cnt'))
				: 10);
			
			Benchmark.addCheck('DecoByteLoader threads: ' + threads);

			model = TSModelLocator.instance;
			loaderDecoClassesMap = new Dictionary();
			loaderDecoInstanceMap = new Dictionary();
			loaderDecoIndividualMap = new Dictionary();
			loadingMap = new Dictionary();
			
			SmartLoaderPool.allocate(SmartByteLoader, threads, NaN, null, 'DecoByteLoader');
		}
		
		private static function aggregateDecoInstancesToBeLoaded():void {
			CONFIG::debugging {
				Console.log(79, 'aggregating!');
			}
			Benchmark.startSection(Benchmark.SECTION_DECOS_LOADING);
			Benchmark.addCheck('DBL.aggregateDecoInstancesToBeLoaded');
			
			const bitmap_renderer:Boolean = model.stateModel.render_mode.usesBitmaps;
			
			decoClassNamesLoadedCnt = 0;
			decoClassNamesToBeLoadedCnt = 0;
			
			decoInstancesLoadedCnt = 0;
			
			var layers:Vector.<Layer> = model.worldModel.location.layers;
			var layer:Layer;
			var deco:Deco;
			var ll:int = layers.length;
			var dl:int;
			for(var i:int = 0; i<ll; i++){
				layer = layers[int(i)];
				
				if (!layer.decos) continue;
				
				dl = layer.decos.length;
				for(var j:int = 0; j<dl; j++){
					deco = layer.decos[int(j)];
					if (deco) {
						if (bitmap_renderer) {
							loadClassByDeco(deco);
						} else {
							loadInstance(deco);
						}
					}
				}
				if(layer.tsid == "middleground"){
					var tiling:Tiling;
					var center:Center;
					var mg:MiddleGroundLayer = layer as MiddleGroundLayer;
					var k:int = 0;
					var l:int = 0;
					for(k = 0; k<mg.doors.length; k++){
						deco = mg.doors[int(k)].deco;
						if (deco) {
							// DoorView doesn't currently use template decos
							loadInstance(deco);
							//if (bitmap_renderer) {
							//	loadClass(deco.sprite_class);
							//} else {
							//	loadInstance(deco);
							//}
						}
					}
					for(k=0; k<mg.signposts.length; k++){
						deco = mg.signposts[int(k)].deco;
						if (deco) {
							// SignpostView doesn't currently use template decos
							loadInstance(deco);
							//if (bitmap_renderer) {
							//	loadClass(deco.sprite_class);
							//} else {
							//	loadInstance(deco);
							//}
						}
					}
					for(k=0; k<mg.ladders.length; k++){
						var ladder:Ladder = mg.ladders[int(k)];
						if(ladder.tiling){
							tiling = ladder.tiling;
							if(tiling.cap_0) loadClassByDeco(tiling.cap_0);
							if(tiling.cap_1) loadClassByDeco(tiling.cap_1);
							if(tiling.centers){
								for(l = 0; l<tiling.centers.length; l++){
									center = tiling.centers[int(l)];
									if (center) loadClassByDeco(center);
								}
							}
						}
					}
				}
			}
			
			CONFIG::locodeco {
				// for locodeco, be sure we have loaded all template decos
				// * needed for dynamically changing decos on e.g. ladders/doors
				// * so we'll have dimensions for every deco
				// * so we can populate the DecoSelectorDialog quicky
				const classes:Vector.<String> = DecoAssetManager.getActiveClassNames();
				for each (var sprite_class:String in classes) {
					loadClass(sprite_class);
				}
			}
		}
		
		private static function loadClassByDeco(deco:Deco):void {
			loadClass(deco.sprite_class);
		}
		
		private static function loadClass(sprite_class:String):void {
			// tell DAM that we're using this template for this location
			// so it doesn't get unloaded (as unused ones are)
			DecoAssetManager.reportTemplateInUse(sprite_class);
			// if we're already loading it...
			if (sprite_class in decoClassNamesToBeLoaded) return;
			// if we already loaded it...
			if (DecoAssetManager.getTemplate(sprite_class)) return;
			// if the deco is missing from the SWF...
			if (!DecoAssetManager.isAssetAvailable(sprite_class)) return;
			// otherwise we can load it!
			decoClassNamesToBeLoaded[sprite_class] = true;
			decoClassNamesToBeLoadedCnt++;
		}
		
		private static function loadInstance(deco:Deco):void {
			// skip if the deco is missing from the SWF
			if (DecoAssetManager.isAssetAvailable(deco.sprite_class)) {
				decoInstancesToBeLoaded.push(deco);
			}
		}
		
		private static function allDecoInstancesLoaded():void {
			decos_unpack_length = (getTimer() - decos_unpack_start);
			Benchmark.addCheck('DBL.allDecoInstancesLoaded: decos unpack secs: '+(decos_unpack_length/1000));
			
			TSFrontController.instance.updateLoadingLocationProgress(1);
			
			StageBeacon.waitForNextFrame(DecoAssetManager.reportAllDecoInstancesReady);
		}
		
		public static function loadLocationDecos():void {
			Benchmark.addCheck('DBL.loadLocationDecos');

			decos_unpack_start = getTimer();
			
			TSFrontController.instance.startLoadingLocationProgress(READYING_TEXT);
			
			CONFIG::debugging {
				Console.log(79, 'loading!');
			}
			
			aggregateDecoInstancesToBeLoaded();
			
			Benchmark.addCheck('DBL.loadLocationDecos loading '+decoClassNamesToBeLoadedCnt+' deco classes for this location');
			decoInstancesToBeLoaded_count = decoClassNamesToBeLoadedCnt;
			
			Benchmark.addCheck('DBL.loadLocationDecos loading '+decoInstancesToBeLoaded.length+' deco instances for this location');
			decoInstancesToBeLoaded_count += decoInstancesToBeLoaded.length;

			// everything is already loaded!
			if (decoInstancesToBeLoaded_count == 0) {
				allDecoInstancesLoaded();
			} else {
				loadDecoInstanceInSeries();
			}
		}
		
		public static function loadDecoIndividual(class_name:String, complete_func:Function):void {
			if (DecoAssetManager.isAssetAvailable(class_name)) {
				decoIndividualToBeLoaded.push(new IndividualDeco(class_name, complete_func));
				loadDecoIndividualInSeries();
			}
		}
		
		private static function loadDecoInstanceInSeries():void {
			//Console.log(79, 'freeLoaders.length:'+freeLoaders.length+' decoInstancesToBeLoaded.length:'+decoInstancesToBeLoaded.length)
			var deco:Deco;
			var loader:SmartByteLoader;
			var bytes:ByteArray;
			var sprite_class:String;
			
			while(SmartLoaderPool.unusedCount) {
				if (decoClassNamesToBeLoadedCnt) {
					// grab the next class to load
					for (sprite_class in decoClassNamesToBeLoaded) break;
					decoClassNamesToBeLoaded[sprite_class] = null;
					delete decoClassNamesToBeLoaded[sprite_class];
					decoClassNamesToBeLoadedCnt--;
					
					// load it
					//trace('loading...', sprite_class);
					bytes = DecoAssetManager.getByteArray(sprite_class);
					loader = SmartLoaderPool.borrowObject();
					loaderDecoClassesMap[loader] = sprite_class;
					addToLoadingMap(loader, 'classes '+sprite_class, 'classes');
					startWithLoader(loader, bytes);
					//Console.log(79, 'LOADING '+deco.tsid+' ('+bytes.length+'b) loading:'+loading+' loaded:'+loaded+' decoInstancesToBeLoaded.length:'+decoInstancesToBeLoaded.length+' freeLoaders.length:'+freeLoaders.length+' threads:'+threads)
				} else if (decoInstancesToBeLoaded.length) {
					deco = decoInstancesToBeLoaded.shift();
					if (deco) {
						//trace('loading individual...', deco.sprite_class);
						bytes = DecoAssetManager.getByteArray(deco.sprite_class);
						loader = SmartLoaderPool.borrowObject();
						loaderDecoInstanceMap[loader] = deco;
						addToLoadingMap(loader, 'instances '+deco.tsid, 'instances');
						startWithLoader(loader, bytes);
						//Console.log(79, 'LOADING '+deco.tsid+' ('+bytes.length+'b) loading:'+loading+' loaded:'+loaded+' decoInstancesToBeLoaded.length:'+decoInstancesToBeLoaded.length+' freeLoaders.length:'+freeLoaders.length+' threads:'+threads)
					}
				} else {
					// nothing else to do
					break;
				}
			}
		}
		
		private static function loadDecoIndividualInSeries():void {
			var bytes:ByteArray;
			var class_name:String;
			var loader:SmartByteLoader;
			var deco:IndividualDeco;
			while (SmartLoaderPool.unusedCount && decoIndividualToBeLoaded.length){
				if(decoIndividualToBeLoaded.length){
					deco = decoIndividualToBeLoaded.shift();
					class_name = deco.class_name;
					bytes = DecoAssetManager.getByteArray(class_name);
					loader = SmartLoaderPool.borrowObject();
					loaderDecoIndividualMap[loader] = deco;
					addToLoadingMap(loader, 'individual '+class_name, 'individual');
					//Console.log(79, 'LOADING '+class_name+' ('+bytes.length+'b) loading:'+loading+' loaded:'+loaded+' decoIndividualToBeLoaded.length:'+decoIndividualToBeLoaded.length+' freeLoaders.length:'+freeLoaders.length+' threads:'+threads)
					startWithLoader(loader, bytes);
				}
			}
		}
		
		private static function addToLoadingMap(loader:SmartByteLoader, str:String, which:String):void {
			loadingMap[loader] = {str:str, which:which};
			
			CONFIG::debugging {
				var counts:Object = model.stateModel.deco_loader_counts;
				Console.trackValue('DBL '+str, 0);
				Console.trackValue('DBL decos to be loaded (total)', counts.total_to++);
			
				switch (which) {
					case 'classes':
						Console.trackValue('DBL decos to be loaded ('+which+')', counts.classes_to++);
                        break;
					case 'individual':
						Console.trackValue('DBL decos to be loaded ('+which+')', counts.individual_to++);
						break;
					case 'instances':
						Console.trackValue('DBL decos to be loaded ('+which+')', counts.instances_to++);
						break;
					default:
						break;
				}
			}
			//Console.info('GO '+loadingMap[loader]);
		}
		
		private static function removeFromLoadingMap(loader:SmartByteLoader):void {
			CONFIG::debugging {
				var counts:Object = model.stateModel.deco_loader_counts;
				Console.trackValue('DBL decos loaded (total)', counts.total_done++);
			}
			
			if (loader in loadingMap) {
				//Console.info('DONE '+loadingMap[loader]);
				var which:String = loadingMap[loader].which;
				loadingMap[loader] = null;
				delete loadingMap[loader];
				
				switch (which) {
					case 'classes':
					case 'instances':
						CONFIG::debugging {
							Console.trackValue('DBL classes loaded ('+which+')', counts.classes_done++);
							Console.trackValue('DBL decos loaded ('+which+')', counts.instances_done++);
						}
						TSFrontController.instance.updateLoadingLocationProgress((decoClassNamesLoadedCnt+decoInstancesLoadedCnt)/decoInstancesToBeLoaded_count);
						break;
					case 'individual':
						CONFIG::debugging {
							Console.trackValue('DBL individuals loaded ('+which+')', counts.individual_done++);
						}
						break;
					default:
						break;
				}
			}
		}
		
		CONFIG::debugging private static function onLoadError(loader:SmartByteLoader):void {
			Console.error('WTF '+loader.eventLog);
		}
		
		CONFIG::debugging private static function onLoadProgress(loader:SmartByteLoader):void {
			var loaderInfo:LoaderInfo = loader.contentLoaderInfo;
			var ob:Object = loadingMap[loaderInfo.loader];
			if (ob) { 
				var percentLoaded:Number = loader.bytesLoaded/loader.bytesTotal;
				Console.trackValue('DBL '+ob.str, percentLoaded);
			}
		}
		
		private static function startWithLoader(loader:SmartByteLoader, bytes:ByteArray):void {
			//Console.info('startWithLoader');
			
			// these are automatically removed on complete or error:
			loader.complete_sig.add(onLoadComplete);
			CONFIG::debugging {
				loader.error_sig.add(onLoadError);
				loader.progress_sig.add(onLoadProgress);
			}
			
			// must put these in their own app domain, as they may have naming collisions
			// (house decos have digit_0, digit_1, etc.)
			LOADER_CONTEXT.applicationDomain = new ApplicationDomain();
			loader.load(bytes, LOADER_CONTEXT);
			//Console.info('startWithLoader'+loading);
		}
		
		private static function finishWithLoader(loader:SmartByteLoader):void {
			//Console.info('finishWithLoader');
			
			//try {loader.close();} catch(err:Error){/*Console.warn(err)*/};
			// animated decos break if you unloadAndStop()
			loader.unload();
			// we'll unloadAndStop() in DecoRenderer.dispose()
			
			SmartLoaderPool.returnObject(new SmartByteLoader('DecoByteLoader'));
		}
		
		private static function onLoadComplete(loader:SmartByteLoader):void {
			const loaderInfo:LoaderInfo = loader.contentLoaderInfo;
			const mc:MovieClip = (loader.content as MovieClip);
			
			CONFIG::debugging {
				Console.removeTrackedValue('DBL '+loadingMap[loader].str);
			}
			
			if (loader in loaderDecoIndividualMap) {
				//Console.log(79, 'A LOAD IS COMPLETE loading:'+loading+' loaded:'+loaded+' event:'+event+' decoIndividualToBeLoaded.length:'+decoIndividualToBeLoaded.length+' freeLoaders.length:'+freeLoaders.length+' threads:'+threads)
				
				const ind_ob:Object = loaderDecoIndividualMap[loader];
				loaderDecoIndividualMap[loader] = null;
				delete loaderDecoIndividualMap[loader];
				
				DecoAssetManager.addDimensions(ind_ob.class_name, loaderInfo.width, loaderInfo.height);
				if (ind_ob.complete_func) ind_ob.complete_func(mc, ind_ob.class_name, loaderInfo.width, loaderInfo.height);
				
				finishWithLoader(loader);
				removeFromLoadingMap(loader);
			} else if (loader in loaderDecoClassesMap) {
				//Console.log(79, 'A LOAD IS COMPLETE loading:'+loading+' loaded:'+loaded+' event:'+event+' decoInstancesToBeLoaded.length:'+decoInstancesToBeLoaded.length+' freeLoaders.length:'+freeLoaders.length+' threads:'+threads)
				
				decoClassNamesLoadedCnt++;
				const sprite_class:String = loaderDecoClassesMap[loader];
				loaderDecoClassesMap[loader] = null;
				delete loaderDecoClassesMap[loader];
				
				DecoAssetManager.addDimensions(sprite_class, loaderInfo.width, loaderInfo.height);
				DecoAssetManager.addTemplate(sprite_class, mc);
				
				finishWithLoader(loader);
				removeFromLoadingMap(loader);
				
				if ((decoClassNamesLoadedCnt + decoInstancesLoadedCnt) == decoInstancesToBeLoaded_count) {
					allDecoInstancesLoaded();
				}
			} else if (loader in loaderDecoInstanceMap) {
				//Console.log(79, 'A LOAD IS COMPLETE loading:'+loading+' loaded:'+loaded+' event:'+event+' decoInstancesToBeLoaded.length:'+decoInstancesToBeLoaded.length+' freeLoaders.length:'+freeLoaders.length+' threads:'+threads)
				
				decoInstancesLoadedCnt++;
				const deco:Deco = loaderDecoInstanceMap[loader];
				loaderDecoInstanceMap[loader] = null;
				delete loaderDecoInstanceMap[loader];
				
				DecoAssetManager.addDimensions(deco.sprite_class, loaderInfo.width, loaderInfo.height);
				DecoAssetManager.addInstance(deco, mc);

				finishWithLoader(loader);
				removeFromLoadingMap(loader);
				
				if ((decoClassNamesLoadedCnt + decoInstancesLoadedCnt) == decoInstancesToBeLoaded_count) {
					allDecoInstancesLoaded();
				}
			} else {
				// just to make sure
				finishWithLoader(loader);
				removeFromLoadingMap(loader);
			}
			
			// a loader is free, load another
			StageBeacon.waitForNextFrame(loadAnotherLoader);
		}
		
		private static function loadAnotherLoader():void {
			loadDecoIndividualInSeries();
			loadDecoInstanceInSeries();
		}
	}
}
