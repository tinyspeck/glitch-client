package com.tinyspeck.debug {
	import com.tinyspeck.core.beacon.StageBeacon;

	public class PhysicsValueTracker extends ValueTracker {
		
		/* singleton boilerplate */
		public static const instance:PhysicsValueTracker = new PhysicsValueTracker();
		
		public function PhysicsValueTracker(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			CONFIG::debugging {
				trackSelfFunc = Console.trackPhysicsValue;
			}
			
			CONFIG::god {
				StageBeacon.setInterval(updateLogIfDirty, 100);
			}
		}
	}
}