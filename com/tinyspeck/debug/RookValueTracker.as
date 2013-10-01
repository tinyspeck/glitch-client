package com.tinyspeck.debug {
	import com.tinyspeck.core.beacon.StageBeacon;

	public class RookValueTracker extends ValueTracker {
		
		/* singleton boilerplate */
		public static const instance:RookValueTracker = new RookValueTracker();
		
		public function RookValueTracker(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			CONFIG::debugging {
				trackSelfFunc = Console.trackRookValue;
			}
			
			CONFIG::god {
				StageBeacon.setInterval(updateLogIfDirty, 100);
			}
		} 
	}
}