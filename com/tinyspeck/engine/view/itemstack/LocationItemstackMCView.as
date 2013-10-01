/**
 * instantiate this one if you want it to use_mc no matter what!
*/

package com.tinyspeck.engine.view.itemstack {
	public class LocationItemstackMCView extends LocationItemstackView {
		public function LocationItemstackMCView(tsid:String) {
			use_mc = true;
			super(tsid);
		}
		
		override protected function doSpecialConfigStuff():void {
			// do not do this
		}
	}
}