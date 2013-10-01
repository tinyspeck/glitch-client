package com.tinyspeck.engine.control.engine
{
	import com.tinyspeck.core.control.IController;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.loader.SmartLoader;
	
	import flash.net.URLRequest;
	
	public class DataLoaderController extends AbstractController implements IController {
		
		private var breakA:Array;
		
		/**For itemstack **/
		public function loadItemstackSWF(item_class:String, url:String, callBackSuccess:Function = null, callBackFailure:Function = null):SmartLoader {
			var item:Item = model.worldModel.getItemByTsid(item_class);
			
			if (model.flashVarModel.break_item_assets && !breakA) {
				breakA = model.flashVarModel.break_item_assets.split(',');
			}
			
			if (model.flashVarModel.break_item_asset_loading || (breakA && breakA.indexOf(item.tsid) > -1)) {
				url+= 'BREAK'
			}
			
			var sl:SmartLoader = new SmartLoader(item_class);
			if (callBackSuccess != null) sl.complete_sig.add(callBackSuccess);
			if (callBackFailure != null) sl.error_sig.add(callBackFailure);
			
			CONFIG::debugging {
				Console.log(66, url);
			}
			
			sl.load(new URLRequest(url), null);
			
			return sl;
		}
	}
}