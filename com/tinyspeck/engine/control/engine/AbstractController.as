package com.tinyspeck.engine.control.engine
{
	import com.tinyspeck.core.control.IController;
	import com.tinyspeck.engine.model.TSModelLocator;
	
	public class AbstractController implements IController
	{
		public var model:TSModelLocator;
		
		public function AbstractController() {
			model = TSModelLocator.instance;
		}
		
		public function run():void {
			//
		}
	}
}