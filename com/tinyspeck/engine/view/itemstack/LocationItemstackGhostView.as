/**
 * used by HOD
*/

package com.tinyspeck.engine.view.itemstack {
	import com.tinyspeck.engine.data.itemstack.Itemstack;

	public class LocationItemstackGhostView extends LocationItemstackView {
		public function LocationItemstackGhostView(tsid:String) {
			super(tsid);
			
			// since this is shown in location, use location states
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(tsid);
			if (itemstack.itemstack_state.state_str == 'iconic') {
				ss_state_override = itemstack.count.toString();
			} else if (itemstack.itemstack_state.state_str == 'broken_iconic') {
				ss_state_override = 'broken';
			}
		}
		
		/*override protected function doSpecialConfigStuff():void {
			// do not do this
		}*/
	}
}