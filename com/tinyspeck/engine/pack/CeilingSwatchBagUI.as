package com.tinyspeck.engine.pack
{
	import com.tinyspeck.engine.data.decorate.Swatch;

	public class CeilingSwatchBagUI extends SwatchBagUI
	{
		/* singleton boilerplate */
		public static const instance:CeilingSwatchBagUI = new CeilingSwatchBagUI();
		
		public function CeilingSwatchBagUI(){
			//set the type
			super(Swatch.TYPE_CEILING);
			
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}			
		}
	}
}