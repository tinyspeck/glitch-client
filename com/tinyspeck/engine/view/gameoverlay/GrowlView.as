package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.AbstractTSView;
	import com.tinyspeck.engine.view.ui.GrowlQueue;
	
	final public class GrowlView extends AbstractTSView {
		/* singleton boilerplate */
		public static const instance:GrowlView = new GrowlView();
		
		private const growl_queue:GrowlQueue = new GrowlQueue();
		private var model:TSModelLocator;
		
		public function GrowlView():void {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			model = TSModelLocator.instance;
			
			// growls are being moved into global chat
			model.activityModel.registerCBProp(addNormalNotification, "growl_message");
			model.activityModel.registerCBProp(addGodNotification, "god_message");
			
			//set the position
			x = 10;
			y = 30;
		}
		
		public function addGodNotification(txt:String):void {
			if (!txt) return;
			
			//add it to the queue
			growl_queue.show('GOD says: '+txt);
		}
		
		public function addNormalNotification(txt:String):void {
			if (!txt) return;
			
			//add it to the queue
			growl_queue.show(txt);
		}
	}
}
