package com.tinyspeck.engine.spritesheet {
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.item.Item;
	
	import flash.display.MovieClip;
	import flash.utils.Dictionary;
	
	public class SWFData {
		////////// LOADING /////////////////////////////////////////////////////
		/** True when the SWF was downloaded */
		internal var loaded:Boolean;
		internal var load_failed:Boolean;
		
		/** True when sheets are available (or were attempted and are null) */
		internal var sheeted:Boolean;
		
		/** These callbacks are run when sheeted=true and sheets are ready */
		internal const sheetedCallbacks:Vector.<Function> = new Vector.<Function>();
	
		/** Stores callbacks requested in getFreshMCForItemSWFByUrl */
		internal const freshSWFCallbackMap:Dictionary = new Dictionary();
		
		private var _url:String;
		private var _item:Item;
		////////////////////////////////////////////////////////////////////////
		
		////////// CACHED MC DATA SET UPON LOAD ////////////////////////////////
		public var mc:MovieClip;
		
		public var mc_w:int;
		public var mc_h:int;
		
		public var is_trant:Boolean;
		public var is_timeline_animated:Boolean;
		
		/** Caches return value of MCUtil.getHighestCountSceneName on the MC */
		public var highest_count_scene_name:String;
		
		/** Caches return value of getSeedForItemSWFByUrl */
		internal var seed:Number;
		////////////////////////////////////////////////////////////////////////
		
		private const reusable_mc_pool:Vector.<MovieClip> = new Vector.<MovieClip>();
		
		public function SWFData(item:Item, url:String){
			_item = item;
			_url = url;
		}
		
		public function get url():String {
			return _url;
		}

		public function get item():Item {
			return _item;
		}

		public function addReusableMC(mc:MovieClip):void {
			reusable_mc_pool.push(mc);
			
			// make sure we reset some shit!
			mc.filters = null;
			mc.x = mc.y = 0;
			mc.scaleX = mc.scaleY = 1;
			
			CONFIG::debugging {
				Console.priinfo(937, 'SWFData for '+item.tsid+' '+url+' has '+reusable_mc_pool.length+' in pool');
			}
		}
		
		public function getReusableMC():MovieClip {
			if (!reusable_mc_pool.length) return null;
			CONFIG::debugging {
				Console.priinfo(937, 'SWFData '+item.tsid+' '+url+' pulling from '+reusable_mc_pool.length+' in pool');
			}
			return reusable_mc_pool.pop();
		}
	}
}
