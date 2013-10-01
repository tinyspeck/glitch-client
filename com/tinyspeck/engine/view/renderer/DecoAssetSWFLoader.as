package com.tinyspeck.engine.view.renderer
{
import com.tinyspeck.core.beacon.StageBeacon;
import com.tinyspeck.debug.Benchmark;
import com.tinyspeck.debug.Console;
import com.tinyspeck.debug.PerfLogger;
import com.tinyspeck.engine.loader.LoaderItem;
import com.tinyspeck.engine.loader.ThreadLoader;

import flash.utils.getTimer;

public final class DecoAssetSWFLoader
{
	public static var data_thread_loader:ThreadLoader = new ThreadLoader('data_thread_loader', 1);
	public static function load(decoAssetSWF:DecoAssetSWF):LoaderItem {
		const loaderItem:LoaderItem = new LoaderItem(decoAssetSWF.name, decoAssetSWF.url, null, onComplete, onError, onProgress);
		
		Benchmark.addCheck('DecoAssetSWFLoader loading: ' + loaderItem.deets);
		CONFIG::debugging {
			Console.log(66, loaderItem.urlRequest.url);
		}

		// start loading
		loaderItem.loadAttempts = 1;
		loaderItem.load_start_ms = getTimer();
		data_thread_loader.addLoaderItem(loaderItem);
		
		return loaderItem;
	}
	
	private static function onError(loaderItem:LoaderItem):void {
		Benchmark.addCheck('DecoAssetSWFLoader error: ' + loaderItem.deets + ' in ' + loaderItem.loadAttempts + ' load attempt(s)');
		if (loaderItem.loadAttempts < 3) {
			loaderItem.loadAttempts++;
			PerfLogger.addRetry(loaderItem.urlRequest.url);

			// browser cache may be bad
			loaderItem.cacheBust();

			StageBeacon.setTimeout(data_thread_loader.addLoaderItem, 2000, loaderItem);
		} else {
			DecoAssetManager.reportLoadingError(loaderItem);
		}
	}
	
	private static function onProgress(loaderItem:LoaderItem):void {
		DecoAssetManager.reportLoadingProgress(loaderItem);
	}
	
	private static function onComplete(loaderItem:LoaderItem):void {
		Benchmark.addCheck('DecoAssetSWFLoader complete: ' + loaderItem.deets + ' in ' + loaderItem.loadAttempts + ' load attempt(s)');
		
		CONFIG::debugging {
			Console.log(79, 'DecoAssetSWFLoader.onComplete '+loaderItem.loader_info.url);
		}
		
		DecoAssetManager.reportLoadingComplete(loaderItem);
	}
}
}
