package com.tinyspeck.engine.view.ui.glitchr.filters
{
	 /** Maps filter TSIDs to GlitchrFilter instances. */ 
	public class GlitchrFilterMap {
		
		public static const instance:GlitchrFilterMap = new GlitchrFilterMap();
		private var filtersByTSID:Object;
		
		public function GlitchrFilterMap() {
			if (instance) {
				throw new Error("Singleton, use '.instance' instead.");
			}
			filtersByTSID = {};
			mapDefaultFilters();
		}
		
		private function mapDefaultFilters():void {
			mapFilter(new AncientFilter());
			mapFilter(new BerylFilter());
			mapFilter(new BlackWhiteFilter());
			mapFilter(new BoostFilter());
			mapFilter(new DitherFilter());
			mapFilter(new FireFlyFilter());
			mapFilter(new HistoricFilter());
			mapFilter(new HolgaFilter());
			mapFilter(new MemphisFilter());
			mapFilter(new NeonFilter());
			mapFilter(new OutlineFilter());
			mapFilter(new PiggyFilter());
			mapFilter(new ShiftFilter());
			mapFilter(new VintageFilter());
		}
		
		public function mapFilter(filter:GlitchrFilter):void {
			filtersByTSID[filter.tsid] = filter;
		}
		
		public function getFilterByTSID(tsid:String):GlitchrFilter {
			var filter:GlitchrFilter = filtersByTSID[tsid] as GlitchrFilter;
			if (!filter) {
				throw new Error("A Glitchr filter with tsid: " + tsid + " has not been mapped or does not exist.");
			}
			
			return filter;
		}
	}
}