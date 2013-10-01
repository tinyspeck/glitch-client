package com.tinyspeck.engine.pack
{
	import com.tinyspeck.engine.data.decorate.Swatch;

	public class FloorSwatchBagUI extends SwatchBagUI
	{
		/* singleton boilerplate */
		public static const instance:FloorSwatchBagUI = new FloorSwatchBagUI();
		
		public function FloorSwatchBagUI(){
			//set the type
			super(Swatch.TYPE_FLOOR);
			
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}			
		}
	}
}