package com.tinyspeck.engine.view.ui.imagination
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.view.ui.Cloud;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;

	public class ImgMenuUpgrade extends ImgMenuElement
	{		
		public function ImgMenuUpgrade(){}
		
		private var card_holder:Sprite = new Sprite();
		
		override protected function buildBase():void {
			super.buildBase();
			
			//set the title
			setTitle('Upgrades');
			
			//set that cloud
			setCloudByType(Cloud.TYPE_UPGRADES);
			
			//set sound
			sound_id = 'CLOUD3';
			
			//temp solution with a static icon
			const icon_DO:DisplayObject = new AssetManager.instance.assets.upgrade_icon();
			card_holder.addChild(icon_DO);
			card_holder.x = int(cloud.width/2 - card_holder.width/2);
			card_holder.y = int(title_tf.y + title_tf.height);
			holder.addChild(card_holder);
		}
		
		override public function show():Boolean {
			if(!is_built) buildBase();
			if(!super.show()) return false;
			
			return true;
		}
		
		override public function hide():void {
			super.hide();
			ImaginationHandUI.instance.hide();
		}
	}
}