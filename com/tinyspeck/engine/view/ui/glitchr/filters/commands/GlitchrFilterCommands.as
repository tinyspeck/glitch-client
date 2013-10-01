package com.tinyspeck.engine.view.ui.glitchr.filters.commands {
	import com.tinyspeck.engine.data.pc.PC;

	public class GlitchrFilterCommands {
		
		public static function updateFiltersForPC(pc:PC, anonymousFitlers:Array):void {
			new UpdateFiltersForPCCMD(pc, anonymousFitlers).execute();
		}
	}
}