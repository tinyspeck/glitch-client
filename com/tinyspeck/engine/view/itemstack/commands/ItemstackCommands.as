package com.tinyspeck.engine.view.itemstack.commands {
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.spritesheet.SSAbstractSheet;
	import com.tinyspeck.engine.view.itemstack.ISpecialConfigDisplayer;
	
	public class ItemstackCommands {
		
		private static const handleSpecialConfigsCmd:HandleSpecialConfigsCmd = new HandleSpecialConfigsCmd();
		
		public static function handleSpecialConfigs(displayer:ISpecialConfigDisplayer, itemstack:Itemstack, ss:SSAbstractSheet, used_swf_url:String):void {
			handleSpecialConfigsCmd.displayer = displayer;
			handleSpecialConfigsCmd.itemstack = itemstack;
			handleSpecialConfigsCmd.ss = ss;
			handleSpecialConfigsCmd.used_swf_url = used_swf_url;
			
			handleSpecialConfigsCmd.execute();
		}
		
	}
}