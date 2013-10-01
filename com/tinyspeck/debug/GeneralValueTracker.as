package com.tinyspeck.debug
{
	import com.tinyspeck.core.beacon.StageBeacon;

	public class GeneralValueTracker extends ValueTracker
	{
		/* singleton boilerplate */
		public static const instance:GeneralValueTracker = new GeneralValueTracker();
		
		public function GeneralValueTracker(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			CONFIG::debugging {
				trackSelfFunc = Console.trackValue;
			}
			
			CONFIG::god {
				StageBeacon.setInterval(updateLogIfDirty, 100);
			}
		}
	}
}