package com.tinyspeck.engine.view.ui.imagination
{
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.ACLDialog;
	import com.tinyspeck.engine.port.ACLManager;
	import com.tinyspeck.engine.view.ui.Cloud;
	import com.tinyspeck.engine.view.ui.acl.ACLIcon;

	public class ImgMenuKeys extends ImgMenuElement
	{	
		private var acl_icon:ACLIcon = new ACLIcon(1, false);
		
		public function ImgMenuKeys(){}
		
		override protected function buildBase():void {
			super.buildBase();
			
			//set the title
			setTitle('<span class="imagination_menu_title_small">Keys</span>');
			
			//set that cloud
			setCloudByType(Cloud.TYPE_KEYS);
			cloud.y += 5; //little visual nudge
			cloud_hover.y += 5;
			
			//set sound
			sound_id = 'CLOUD4';
			
			//keys
			acl_icon.x = int(cloud.width/2 - acl_icon.width/2 + 2);
			acl_icon.y = int(cloud.y - 10);
			holder.addChild(acl_icon);
		}
		
		override public function show():Boolean {
			if(!is_built) buildBase();
			if(!super.show()) return false;
			
			//show how many keys we have
			onKeysChange();
			
			//listen to the manager
			ACLManager.instance.addEventListener(TSEvent.CHANGED, onKeysChange, false, 0, true);
			
			return true;
		}
		
		override public function hide():void {
			super.hide();
			
			//no more listen
			ACLManager.instance.removeEventListener(TSEvent.CHANGED, onKeysChange);
			
			//close the dialog
			//if(ACLDialog.instance.parent) ACLDialog.instance.end(true);
		}
		
		private function onKeysChange(event:TSEvent = null):void {
			acl_icon.key_count = ACLManager.instance.key_count;
		}
	}
}