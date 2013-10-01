package com.tinyspeck.engine.pack
{
	import com.tinyspeck.engine.data.decorate.Swatch;

	public class WallSwatchBagUI extends SwatchBagUI
	{
		/* singleton boilerplate */
		public static const instance:WallSwatchBagUI = new WallSwatchBagUI();
		
		public function WallSwatchBagUI(){
			//set the type
			super(Swatch.TYPE_WALLPAPER);
			
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}		
		}
	}
}