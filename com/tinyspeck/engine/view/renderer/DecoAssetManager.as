package com.tinyspeck.engine.view.renderer
{
import com.tinyspeck.core.beacon.StageBeacon;
import com.tinyspeck.debug.Benchmark;
import com.tinyspeck.debug.BootError;
import com.tinyspeck.debug.Console;
import com.tinyspeck.engine.animatedbitmap.BitmapAtlas;
import com.tinyspeck.engine.control.TSFrontController;
import com.tinyspeck.engine.control.engine.DataLoaderController;
import com.tinyspeck.engine.data.location.Deco;
import com.tinyspeck.engine.data.location.Location;
import com.tinyspeck.engine.loader.LoaderItem;
import com.tinyspeck.engine.model.TSModelLocator;
import com.tinyspeck.engine.ns.client;

import flash.display.MovieClip;
import flash.system.ApplicationDomain;
import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.utils.describeType;

import org.osflash.signals.Signal;

/**
 * The DAM is an object store for deco assets. It coordinates loading what needs
 * to be loaded for a given location, collects and doles out the assets to the
 * LocationRenderer.
 * -----------------------------------------------------------------------------
 * The flow is loadLocationSWFs() is called, which clears caches, and triggers
 * the downloading of all necessary SWFs (they may already be in memory) using
 * DecoAssetSWFLoader.
 * 
 * Then the DecoByteLoader is told to load all necessary deco templates
 * (canonical copies of a deco that can be used as a blitting source) and
 * instances (clones of decos that you can do anything you like with, especially
 * animated decos since animations cannot be blitted [efficiently]). When it's
 * done, it calls reportAllDecoInstancesReady().
 * 
 * Then we dispose of any unused deco templates (those used in the previous
 * location that aren't also used in this location) and send out the 'location'
 * event which causes location loading to continue.
 * 
 * Eventually, reportLocationBuilt() is called and loading is complete.
 * -----------------------------------------------------------------------------
 * SWFs and their Loaders are disposed as soon as the SWFs are parsed.
 * 
 * Source ByteArrays are kept for the entire gaming session since they take up
 * little space (on the order of megabytes per deco SWF) and are loaded
 * on-demand (to create instances and templates).
 * 
 * The previous location's instances are flushed before every location load.
 * 
 * Unused templates are flushed AFTER all decos are loaded (since templates from
 * the last location may be used in the current location). They aren't stored
 * forever because they take up more space than their source ByteArrays and can
 * be regenerated very quickly.
 */
public final class DecoAssetManager {
	
	/** BitmapAtlases for animated decos (class:String -> BitmapAtlas) */
	public static const bitmapAtlasesDisposed:Signal = new Signal();
	private static const decoClassNameToBitmapAtlas:Object = {};
	
	/** All active SWFs (name:String -> DecoAssetSWF) */
	private static const swfNameToDecoAssetSWF:Object = {};
	
	/** All active SWFs (not all may be fully loaded) */
	private static const decoAssetSWFs:Vector.<DecoAssetSWF> = new Vector.<DecoAssetSWF>();
	
	/** Raw deco ByteArrays (class:String -> ByteArray) */
	// these are never flushed in a game session
	private static const decoClassNameToByteArray:Object = {};
	
	/** A hash of Objects that give h and w for each string class name in allA */
	// these are never flushed in a game session
	private static const decoClassNameToDimensions:Object = {};
	
	/** (class:String -> DecoAssetSWF) */
	// these are never flushed in a game session
	CONFIG::locodeco private static const decoClassNameToDecoAssetSWF:Object = {};
	
	/** Template decos (class:String -> MovieClip) (SWF_bitmap_renderer) */
	private static const decoClassNameToMovieClip:Object = {};
	
	/** Deco instances (deco:Deco -> MovieClip) (default/locodeco renderer) */
	private static const decoInstanceToMovieClip:Dictionary = new Dictionary();
	
	/** Group name to a hash of class names (group:String -> Dictionary) */
	private static const groupToClassNameDict:Object = {};
	
	/** A hash of templates that are _in use_ in the current location (class:String -> Boolean */
	private static var templatesInUse:Object;
	
	/** True when we've loaded all necessary decos */
	private static var allDecoAssetsLoaded:Boolean;
	
	/** True when while we're loading a location's assets */
	private static var currentlyLoading:Boolean;
	
	/** Reference to the currently loaded location */
	private static var currentLocation:Location;
	
	/** A cached list of class names available in the current location */
	private static var _activeClassNames:Vector.<String>;
	
	/** A cached list of group names available in the current location */
	private static var _activeGroupNames:Vector.<String>;
	
	public static function init():void {
		CONFIG::debugging {
			StageBeacon.setInterval(logStatus, 10000, false);
		}
	}
	
	/** Reloads all decos for current location */ 
	public static function reloadLocationSWFs():void {
		var location:Location = currentLocation;
		currentLocation = null;
		loadLocationSWFs(location);
	}
	
	/** Load all the decos needed for a location */
	public static function loadLocationSWFs(location:Location):void {
		if (currentlyLoading || (currentLocation == location)) return;
		currentlyLoading = true;
		currentLocation = location;
		
		// display our loading progress
		TSFrontController.instance.startLoadingLocationProgress('loading...');
		
		// clear out caches
		disposeInstances();
		templatesInUse = {};
		_activeClassNames = null;
		_activeGroupNames = null;
		
		var daSWF:DecoAssetSWF;
		var name:String;
		
		// mark all existing SWFs as not in-use
		for each (daSWF in decoAssetSWFs) daSWF.inUse = false;
		
		// dispose all BitmapAtlases
		for  (var sprite_class:Object in decoClassNameToBitmapAtlas) {
			var bitmapAtlas:BitmapAtlas = decoClassNameToBitmapAtlas[sprite_class];
			bitmapAtlas.sheetBMD.dispose();
		}
		clearHash(decoClassNameToBitmapAtlas);
		bitmapAtlasesDisposed.dispatch();

		if (!TSModelLocator.instance.flashVarModel.multiswf_cache) flushSWFCache();
		
		// load what needs to be loaded
		for (var i:* in location.client::swf_files) {
			name = location.client::swf_files[int(i)];
			
			// skip if it's already loaded, or being loaded
			daSWF = swfNameToDecoAssetSWF[name];
			if (daSWF) {
				daSWF.inUse = true;
				Benchmark.addCheck('DAM.loadLocationSWFs already loaded '+name+' '+location.client::swf_files_versioned[int(i)]);
			} else {
				loadDecoSWF(name, location.client::swf_files_versioned[int(i)]);
			}
		}
		
		CONFIG::debugging {
			logStatus();
		}
		
		maybeAllSWFsAreLoaded();
	}
	
	/** Called by DecoAssetSWFLoader when there's progress */
	public static function reportLoadingProgress(loaderItem:LoaderItem):void {
		TSFrontController.instance.updateLoadingLocationProgress(swfProgress);
	}
	
	/** Called by DecoAssetSWFLoader when the SWF is loaded */
	public static function reportLoadingComplete(loaderItem:LoaderItem):void {
		// just in case there was no progress report for 100%
		TSFrontController.instance.updateLoadingLocationProgress(swfProgress);
		
		var daSWF:DecoAssetSWF = swfNameToDecoAssetSWF[loaderItem.label];
		
		// assert that we're tracking a SWF that completed
		if (!daSWF) throw new Error();
		
		// grab all the ByteArrays from this SWF
		unpackDecoAssetSWF(daSWF);
		// unloadAndStop() all SWFs now that we've copied the ByteArrays
		// (do it on the next frame, just to be sure we're done with it)
		StageBeacon.waitForNextFrame(daSWF.disposeLoader);
		// we're done!
		daSWF.loaded = true;
		
		maybeAllSWFsAreLoaded();
		
		CONFIG::debugging {
			logStatus();
		}
	}
	
	/** Called by DecoAssetSWFLoader when a SWF failed to load after retrying */
	public static function reportLoadingError(loaderItem:LoaderItem):void {
		CONFIG::debugging {
			logStatus();
		}
		BootError.handleError('Could not load location SWF after three attempts', new Error('loaderItem: ' + loaderItem.deets), ['loader'], false);
	}
	
	/** Tells us that this class is in use and should not be disposed */
	public static function reportTemplateInUse(sprite_class:String):void {
		templatesInUse[sprite_class] = true;
	}
	
	/** Tells us that DecoByteLoader has finished loading everything */
	public static function reportAllDecoInstancesReady():void {
		allDecoAssetsLoaded = true;
		
		Benchmark.addCheck('DAM.reportAllDecoInstancesReady: ' + currentLocation.label + ' (' + currentLocation.tsid + ')');
		
		CONFIG::debugging {
			logStatus();
		}
		
		if (TSModelLocator.instance.flashVarModel.dispose_unused_templates) {
			disposeUnusedTemplates();
		}
		
		TSFrontController.instance.locationAssetsAreReady();
	}
	
	public static function reportLocationBuilt():void {
		CONFIG::locodeco {
			if (TSModelLocator.instance.flashVarModel.edit_loc) {
				// prevent the editor from popping up on subsequent location changes
				TSModelLocator.instance.flashVarModel.edit_loc = false;
				TSFrontController.instance.startEditMode();
			}
		}
	}
	
	/** Are all the decos needed ready to go? */
	public static function isLocationReady():Boolean {
		return (areAllSWFsLoaded() && allDecoAssetsLoaded && !currentlyLoading);
	}
	
	public static function addBitmapAtlas(sprite_class:String, bitmapAtlas:BitmapAtlas):void {
		decoClassNameToBitmapAtlas[sprite_class] = bitmapAtlas;
	}
	
	public static function getBitmapAtlas(sprite_class:String):BitmapAtlas {
		return decoClassNameToBitmapAtlas[sprite_class];
	}
	
	public static function addInstance(deco:Deco, mc:MovieClip):void {
		decoInstanceToMovieClip[deco] = mc;
	}
	
	/** Returns an individually rendered MovieClip */
	public static function getInstance(deco:Deco):MovieClip {
		return decoInstanceToMovieClip[deco];
	}
	
	public static function addTemplate(sprite_class:String, mc:MovieClip):void {
		decoClassNameToMovieClip[sprite_class] = mc;
	}
	
	/** Returns a template MovieClip of the given class */
	public static function getTemplate(sprite_class:String):MovieClip {
		return decoClassNameToMovieClip[sprite_class];
	}
	
	public static function addDimensions(sprite_class:String, w:int, h:int):void {
		if (!(sprite_class in decoClassNameToDimensions)) {
			decoClassNameToDimensions[sprite_class] = {
				width:  w,
				height: h
			};
		}
	}
	
	/** Returns an Object with 'width' and 'height' properties */
	public static function getDimensions(sprite_class:String):Object {
		return decoClassNameToDimensions[sprite_class];
	}
	
	/** Returns an Object with 'width' and 'height' properties */
	CONFIG::locodeco public static function getAssetSWFName(sprite_class:String):Object {
		const daSWF:DecoAssetSWF = decoClassNameToDecoAssetSWF[sprite_class];
		return (daSWF ? daSWF.name : 'unknown');
	}
	
	/** Adds the raw ByteArray for the given class */
	public static function addByteArray(sprite_class:String, byteArray:ByteArray):void {
		// the first ByteArray added for a given class wins
		if (sprite_class in decoClassNameToByteArray) {
			; // satisfy compiler
			CONFIG::debugging {
				Console.warn('DAM.addByteArray(): multiple SWFs define the same sprite class: ' + sprite_class);
			}
		} else {
			decoClassNameToByteArray[sprite_class] = byteArray;
		}
	}
	
	/** Returns the raw ByteArray of the given class */
	public static function getByteArray(sprite_class:String):ByteArray {
		return decoClassNameToByteArray[sprite_class];
	}
	
	/** Returns whether we can build this sprite class or not */
	public static function isAssetAvailable(sprite_class:String):Boolean {
		return (sprite_class in decoClassNameToByteArray);
	}
	
	/** Returns a list of deco class names available in this location */
	public static function getActiveClassNames():Vector.<String> {
		// build on demand
		// _activeClassNames is set to null each location load
		if (!_activeClassNames) {
			_activeClassNames = new Vector.<String>();
			for each (var daSWF:DecoAssetSWF in decoAssetSWFs) {
				if (daSWF.inUse) {
					for each (var className:String in daSWF.classes) {
						// yes this lookup is slow, and will fail 99.9% of the
						// time, but it's only done once per location, and
						// returning a Vector is better than Dictionary
						if (_activeClassNames.indexOf(className) == -1) {
							_activeClassNames.push(className);
						}
					}
				}
			}
			_activeClassNames.fixed = true;
		}
		return _activeClassNames;
	}
	
	/** Returns a list of deco group names available in this location */
	public static function getActiveGroups():Vector.<String> {
		// build on demand
		// _activeGroupNames is set to null each location load
		if (!_activeGroupNames) {
			_activeGroupNames = new Vector.<String>();
			for each (var daSWF:DecoAssetSWF in decoAssetSWFs) {
				if (daSWF.inUse) {
					for each (var groupName:String in daSWF.groups) {
						// yes this lookup is slow, and will fail 99.9% of the
						// time, but it's only done once per location, and
						// returning a Vector is better than Dictionary
						if (_activeGroupNames.indexOf(groupName) == -1) {
							_activeGroupNames.push(groupName);
						}
					}
				}
			}
			_activeGroupNames.fixed = true;
		}
		return _activeGroupNames;
	}
	
	/** Returns whether the class is found in the given group */
	public static function isInGroup(className:String, groupName:String):Boolean {
		return ((groupName in groupToClassNameDict) && (className in groupToClassNameDict[groupName]));
	}
	
	/**
	 * Loads a one-off MovieClip of a deco and returns it to the completion
	 * function. Be SURE you call loaderInfo.loader.unloadAndStop() on the asset
	 * when you are finished using it.
	 */
	public static function loadIndividualDeco(className:String, onComplete:Function):Boolean {
		if (isAssetAvailable(className)) {
			DecoByteLoader.loadDecoIndividual(className, onComplete);
			return true;
		}
		return false;
	}
	
	/** Start loading a swf */
	private static function loadDecoSWF(name:String, url:String):void {
		CONFIG::debugging {
			Console.log(79, 'loadDecoSWF: ' + name + '[' + url + ']');
		}
		
		// assert there isn't an existing swf tracked by this name
		var daSWF:DecoAssetSWF = swfNameToDecoAssetSWF[name];
		if (daSWF) throw new Error();
		
		// build/track a new SWF representation
		daSWF = new DecoAssetSWF();
		swfNameToDecoAssetSWF[name] = daSWF;
		decoAssetSWFs.push(daSWF);
		daSWF.name  = name;
		daSWF.url   = url;
		daSWF.inUse = true;
		
		// load it
		daSWF.loaderItem = DecoAssetSWFLoader.load(daSWF);
	}
	
	private static function unpackDecoAssetSWF(daSWF:DecoAssetSWF):void {
		const loaderItem:LoaderItem = daSWF.loaderItem;
		const applicationDomain:ApplicationDomain = loaderItem.loader_info.applicationDomain;
		const typeDesc:XML = describeType(loaderItem.content);
		const packageName:String = typeDesc.@name;
		const classes:XMLList = typeDesc..variable.(@type=="Class");
		
		// load groups and their mappings
		daSWF.groups = new Vector.<String>();
		const groups:Object = loaderItem.content['groups'];
		for (var groupName:String in groups) {
			var group:Object = groups[groupName];
			if (!(groupName in daSWF.groups)) daSWF.groups.push(groupName);
			// init if necessary
			if (!(groupName in groupToClassNameDict)) {
				groupToClassNameDict[groupName] = {};
			}
			// populate the group
			for each (var className:String in group) {
				groupToClassNameDict[groupName][className] = true;
			}
		}
		daSWF.groups.fixed = true;
		
		// grab all the class bytearrays
		const allDecoClassNames:Array = loaderItem.content['A'];
		daSWF.classes = new Vector.<String>(allDecoClassNames.length, true);
		
		var i:int = 0;
		var byteClass:Class;
		var byteArray:ByteArray;
		var fullDefinitionName:String;
		for each (var xml:XML in classes) {
			className = xml.@name;
			fullDefinitionName = packageName + "_" + className + "_dataClass";
			
			// mark that this SWF contained this class
			daSWF.classes[i++] = className;
			// but skip adding ByteArrays for classes we've already loaded (e.g. from another SWF)
			if (isAssetAvailable(className)) continue;
			
			CONFIG::locodeco {
				decoClassNameToDecoAssetSWF[className] = daSWF;
			}
			
			byteClass = applicationDomain.getDefinition(fullDefinitionName) as Class;
			byteArray = (new byteClass() as ByteArray);
			
			addByteArray(className, byteArray);
		}
	}
	
	public static function toString():String {
		var str:String = 'DecoAssetManager(currentlyLoading:' + currentlyLoading + ', instancesReady:' + allDecoAssetsLoaded + ')';
		for each (var daSWF:DecoAssetSWF in decoAssetSWFs) str += '\n\t' + daSWF.toString();
		return str;
	}
	
	/** Returns progress of swf loading */
	private static function get swfProgress():Number {
		var count:Number = 0;
		var progress:Number = 0;
		for each (var daSWF:DecoAssetSWF in decoAssetSWFs) {
			if (daSWF.inUse) {
				count++;
				progress += (daSWF.loaderItem ? daSWF.loaderItem.progress : 1);
			}
		}
		return (count ? (progress / count) : 0);
	}
	
	/** Finish location loading work if we're done downloading SWFs */
	private static function maybeAllSWFsAreLoaded():void {
		if (areAllSWFsLoaded()) {
			TSFrontController.instance.updateLoadingLocationProgress(1);
			
			// be sure this comes before DecoByteLoader.loadLocationDecos
			// (it may not have anything to load and will synchronously
			//  call reportAllDecoInstancesReady)
			// (maybe not an issue anymore since I put it on timeout, but w/e)
			currentlyLoading = false;
			
			// kick off on next frame since this could be a long-running process
			StageBeacon.waitForNextFrame(DecoByteLoader.loadLocationDecos);
		}
	}
	
	private static function disposeInstances():void {
		clearHash(decoInstanceToMovieClip);
		allDecoAssetsLoaded = false;
	}
	
	/** Remove all templates that aren't referenced in this location */
	// I originally wanted to unload ALL templates once the loc was built,
	// but items like ladders may do their blitting after it's built
	private static function disposeUnusedTemplates():void {
		for (var tsid:String in decoClassNameToMovieClip) {
			// wipe it out if we're not using it
			if (!(tsid in templatesInUse)) {
				decoClassNameToMovieClip[tsid] = null;
				// safe to do this in a for..in loop (but not a for each..in)
				delete decoClassNameToMovieClip[tsid];
			}
		}
	}
	
	/** Wipe out our entire SWF cache */
	private static function flushSWFCache():void {
		Benchmark.addCheck('DAM.flushSWFCache');
		Benchmark.addCheck(toString());
		
		clearHash(decoInstanceToMovieClip);
		clearHash(decoClassNameToMovieClip);
		clearHash(groupToClassNameDict);
		clearHash(decoClassNameToByteArray);
		clearHash(decoClassNameToDimensions);
		clearHash(swfNameToDecoAssetSWF);

		for each (var daSWF:DecoAssetSWF in decoAssetSWFs) daSWF.dispose();
		decoAssetSWFs.length = 0;
	}
	
	CONFIG::debugging private static function logStatus(force:Boolean = true):void {
		if (force || currentlyLoading) trace(toString());
	}
	
	/** Are the needed SWFs loaded */
	private static function areAllSWFsLoaded():Boolean {
		for each (var daSWF:DecoAssetSWF in decoAssetSWFs) {
			if (daSWF.inUse && !daSWF.loaded) return false;
		}
		return true;
	}
	
	private static function clearHash(hash:Object):void {
		for (var obj:Object in hash) {
			hash[obj] = null;
			// safe to do this in a for..in loop (but not a for each..in)
			delete hash[obj];
		}
	}
}
}
