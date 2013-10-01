package com.tinyspeck.engine.view.ui.imagination
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.ACLDialog;
	import com.tinyspeck.engine.port.ACLManager;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.FamiliarDialog;
	import com.tinyspeck.engine.view.ui.Cloud;
	import com.tinyspeck.engine.view.ui.acl.ACLIcon;
	
	import flash.display.DisplayObject;

	public class ImgMenuTeleport extends ImgMenuElement
	{	
		private var teleport_icon:DisplayObject;
		
		public function ImgMenuTeleport(){}
		
		override protected function buildBase():void {
			super.buildBase();
			
			//set the title
			setTitle('<span class="imagination_menu_title_small">Teleport</span>');
			
			//set that cloud
			setCloudByType(Cloud.TYPE_KEYS);
			
			//set sound
			sound_id = 'CLOUD5';
			
			//icon
			teleport_icon = new AssetManager.instance.assets.familiar_dialog_teleport();
			teleport_icon.x = int(cloud.width/2 - teleport_icon.width/2);
			teleport_icon.y = int(title_tf.y + title_tf.height + 8);
			holder.addChild(teleport_icon);
		}
		
		override public function show():Boolean {
			if(!is_built) buildBase();
			if(!super.show()) return false;
			
			return true;
		}
		
		override public function hide():void {
			super.hide();
			
			//close the dialog
			if(TSModelLocator.instance.stateModel.fam_dialog_open) TSFrontController.instance.toggleTeleportDialog();
		}
	}
}