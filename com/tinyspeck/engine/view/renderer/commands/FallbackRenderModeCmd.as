package com.tinyspeck.engine.view.renderer.commands
{
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.core.control.ICommand;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.engine.model.StateModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.gameoverlay.GrowlView;
	import com.tinyspeck.engine.view.renderer.RenderMode;
	
	CONFIG::perf { import com.tinyspeck.engine.perf.PerfTestManager; }

	/**
	 * Sets StateModel's render_mode to safer mode.
	 * Called when a location fails to build.
	 * Example: Failure to build location using bitmap_renderer.
	 */
	public class FallbackRenderModeCmd implements ICommand {
			
		private var flashVarModel:FlashVarModel;
		private var stateModel:StateModel;
		private var forceRenderMode:RenderMode;
	
		public function FallbackRenderModeCmd(forceRenderMode:RenderMode = null) {
			stateModel = TSModelLocator.instance.stateModel;
			flashVarModel = TSModelLocator.instance.flashVarModel;
			
			this.forceRenderMode = forceRenderMode;
		}
		
		public function execute():void {
			var newRenderMode:RenderMode = getNextRenderMode();
			
			Benchmark.addCheck("FALLING BACK TO RENDER MODE: " + newRenderMode.name);
			
			CONFIG::god {
				GrowlView.instance.addNormalNotification("FALLING BACK TO RENDER MODE: " + newRenderMode.name);
			}
			
			CONFIG::perf {
				if (TSModelLocator.instance.flashVarModel.run_automated_tests) {
					PerfTestManager.fail("Fell back to render mode " + newRenderMode.name);
				}
			}
			
			LocationCommands.changeRenderMode(newRenderMode);
		}
		
		private function getNextRenderMode():RenderMode {
			if (forceRenderMode) {
				return forceRenderMode;
			}
			
			switch (stateModel.render_mode) {
				case RenderMode.BITMAP:
					return RenderMode.VECTOR;
				default:
					throw new Error("RenderMode can not fall back from: " + stateModel.render_mode.name);
			}
		}
	}
}