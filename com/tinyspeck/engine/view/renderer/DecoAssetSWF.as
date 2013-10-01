package com.tinyspeck.engine.view.renderer
{
import com.tinyspeck.engine.loader.LoaderItem;
import com.tinyspeck.engine.util.StringUtil;

internal final class DecoAssetSWF
{
	/** name of the SWF (e.g. groddle1.swf) */
	public var name:String;
	
	/** url of the SWF (e.g. groddle1/12345.swf) */
	public var url:String;
	
	/** the loader that does the hard work, may be null if it's been disposed */
	public var loaderItem:LoaderItem;

	/** True when the SWF is fully loaded */
 	public var loaded:Boolean = false;
	
	/** True when the SWF is currently in-use */
	public var inUse:Boolean = false;
	
	/** all the class names this SWF provides */
	public var classes:Vector.<String>;
	
	/** all the group names this SWF provides */
	public var groups:Vector.<String>;
	
	public function disposeLoader():void {
		// we're just disposing of the loader, and we're never going to dispose
		// the entire DecoAssetSWF (except when SWF_multiswf_cache=0), so don't
		// clean these up:
		//inUse   = false;
		//loaded  = false;
		//classes = null;
		//groups  = null;
		
		if (loaderItem) {
			loaderItem.dispose(true, true);
			loaderItem = null;
		}
	}

	/** Used only when SWF_multiswf_cache=0 */
	public function dispose():void {
		inUse   = false;
		loaded  = false;
		classes = null;
		groups  = null;
		disposeLoader();
	}
	
	public function toString():String {
		return StringUtil.padString(("(" + (loaded ? 100 : (loaderItem ? Math.round(loaderItem.progress*100) : 0)) + "%)"), 3 + 4, true)
			+ (inUse ? String.fromCharCode(0x2713) : "-") + ' ' + name + ' [' + url + ']' ;
	}
}
}
