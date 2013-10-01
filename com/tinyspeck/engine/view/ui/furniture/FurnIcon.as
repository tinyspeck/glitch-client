package com.tinyspeck.engine.view.ui.furniture
{
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.engine.data.furniture.FurnUpgrade;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;

	public class FurnIcon extends DisposableSprite implements ITipProvider {		
		public var iiv:ItemIconView;
		private var current_upgrade:FurnUpgrade;
		private var wh:int;
		private var padd:uint;
		private var facing_left:Boolean;
		private var subscriber_icon:DisplayObject;
		
		public function FurnIcon(wh:int, padd:int) {
			this.wh = wh;
			this.padd = padd;
			
			var g:Graphics = graphics;
			g.beginFill(0xdbdbdb);
			g.drawRoundRect(0, 0, wh, wh, 10);
			g.endFill();
			g.beginFill(0xffffff);
			g.drawRoundRect(1, 1, wh-2, wh-2, 10);
		}
		
		public function show(item_class:String, upgrade:FurnUpgrade):void {
			current_upgrade = upgrade;
			
			//item
			iiv = new ItemIconView(item_class, wh - padd*2, {config:upgrade.furniture, state:'iconic'}, 'center'/*, false, true*/);
			iiv.scaleX = (facing_left) ? -1 : 1; // ChassisUpgradeButton, which extends this class, has facing_left = true, to face the homes in their default orientation
			addChild(iiv);
			iiv.x = int(wh/2);
			iiv.y = int(wh/2); //gives a little padding to the text at the bottom
			
			if (upgrade.subscriber_only) {
				subscriber_icon = new AssetManager.instance.assets.furn_subscriber();
				subscriber_icon.scaleX = subscriber_icon.scaleY = .5;
				addChild(subscriber_icon);
				subscriber_icon.x = wh-(subscriber_icon.width+5);
				subscriber_icon.y = wh-(subscriber_icon.height+5);
			}
			
			//tooltip party
			TipDisplayManager.instance.registerTipTrigger(this);
		}
		
		override public function dispose():void {
			TipDisplayManager.instance.unRegisterTipTrigger(this);
			super.dispose();
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target || !current_upgrade) return null;
			
			//what is the name of this thing?!
			return {
				txt: current_upgrade.label,
				pointer: WindowBorder.POINTER_TOP_CENTER
			}
		}
	}
}