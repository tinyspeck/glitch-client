package com.tinyspeck.engine.view.ui.glitchr.filters.commands
{
	import com.tinyspeck.core.control.ICommand;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.view.ui.glitchr.filters.GlitchrFilter;
	import com.tinyspeck.engine.view.ui.glitchr.filters.GlitchrFilterMap;
	
	public class UpdateFiltersForPCCMD implements ICommand {
		
		private var anonymousFilters:Array;
		private var pc:PC;
		
		public function UpdateFiltersForPCCMD(pc:PC, anonymousFilters:Array) {
			this.pc = pc;
			this.anonymousFilters = anonymousFilters;
		}
		
		public function execute():void {
			// create a new filters vector
			var filters:Vector.<GlitchrFilter> = new Vector.<GlitchrFilter>();
			for (var i:uint = 0; i < anonymousFilters.length; i++) {
				var filter:GlitchrFilter = GlitchrFilterMap.instance.getFilterByTSID(anonymousFilters[i].tsid);
				filter.name = anonymousFilters[i].label;
				if (anonymousFilters[i].is_enabled) filters.push(filter);
			}
			
			// assign it to the PC
			pc.cam_filters = filters;
		}
	}
}