package com.tinyspeck.engine.view.ui.furniture
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.data.furniture.FurnUpgrade;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.DecorateModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.util.SpriteUtil;
	
	import flash.display.Graphics;
	import flash.display.Sprite;

	public class FurnUpgradeChooserUI extends Sprite {
				
		private static const BUTTON_PADD:int = 11;
		private var cols:uint = 2;
		
		private var padder:Sprite = new Sprite();
		
		// maintain a count of how many of the displayed upgrades cost credits
		public var require_credits_count:int;
		
		private var buttons:Vector.<FurnUpgradeButton> = new Vector.<FurnUpgradeButton>();
		
		public function FurnUpgradeChooserUI() {			
			//create the padder to put at the bottom so the scroller gives a nice little gap
			var g:Graphics = padder.graphics;
			g.beginFill(0,0);
			g.drawRect(0, 0, 1, BUTTON_PADD);
			addChild(padder);
		}
		
		public function start(cols:uint, icon_wh:int, icon_padd:int):void {
			var dm:DecorateModel = TSModelLocator.instance.decorateModel;
			this.cols = cols;
			clean();
			
			require_credits_count = 0;
			
			var col:int;
			var row:int;
			var i:int;
			var total:int = buttons.length;
			var fub:FurnUpgradeButton;
			var fupgrade:FurnUpgrade;
			
			//reset the pool
			for(i = 0; i < total; i++){
				buttons[int(i)].hide();
			}
			
			//place them
			total = dm.upgradesV.length;
			for (i = 0; i < total; i++) {
				fupgrade = dm.upgradesV[int(i)];
				if (fupgrade.credits) {
					require_credits_count++;
				}
				
				col = (i % cols);
				row = Math.floor(i / cols);
				
				if(buttons.length > i){
					fub = buttons[int(i)];
					fub.is_clicked = false;
				}
				else {
					fub = new FurnUpgradeButton(icon_wh, icon_padd);
					fub.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
					buttons.push(fub);
				}
				
				fub.x = Math.round(col*(fub.width+BUTTON_PADD));
				fub.y = Math.round(row*(fub.height+BUTTON_PADD));
				
				// if it is the current one!
				if (fupgrade.id == dm.upgrade_itemstack.furn_upgrade_id) {
					fub.is_clicked = true;
				}
				
				// just a wee delay to make loading smoother, especially when the furn is large
				StageBeacon.setTimeout(fub.show, 100*(i+1), dm.upgrade_itemstack.class_tsid, fupgrade, fub.is_clicked);
				
				// admin only ones will be filtered out in FurnUpgrade.parseMultiple for normals,
				// but for admins make the iiv transparent
				fub.iiv_holder.alpha = (fupgrade.is_visible) ? 1 : .3;
				addChild(fub);
			}
			
			//move the padder
			if(fub){
				padder.y = int(fub.y + fub.height);
			}
		}
		
		private function onButtonClick(event:TSEvent):void {
			const clicked_fub:FurnUpgradeButton = event.data as FurnUpgradeButton;
			
			//send off the upgrade info
			dispatchEvent(new TSEvent(TSEvent.CHANGED, clicked_fub.furn_upgrade));
	
			//reset all the buttons except the one that was clicked
			var i:int;
			var total:int = buttons.length;
			var fub:FurnUpgradeButton;
			
			for(i; i < total; i++){
				fub = buttons[int(i)];
				if(fub.parent && fub != clicked_fub){
					fub.is_clicked = false;
				}
			}
		}
		
		public function clean():void {
			SpriteUtil.clean(this, true, 1); //1 allows the padder to stick around
			padder.y = 0;
		}
		
		public function get w():int {
			return width;
		}
		
		public function get h():int {
			return height;
		}
		
	}
}