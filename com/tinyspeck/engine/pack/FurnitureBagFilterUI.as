package com.tinyspeck.engine.pack
{
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.ui.Button;

	public class FurnitureBagFilterUI extends BagFilterUI
	{
		public function FurnitureBagFilterUI(){}
		
		override protected function setButtonLabel(category:String):void {
			//get the proper label
			const bt:Button = button_holder.getChildByName(category) as Button;
			const category_info:Object = TSModelLocator.instance.decorateModel.getFurniturePaneById(category);
			if(!bt || !category) return;
			
			bt.label = bt.value+' '+(bt.value != 1 ? category_info.label_plural : category_info.label);
			
			//draw and stuff
			super.setButtonLook(bt);
		}		
	}
}