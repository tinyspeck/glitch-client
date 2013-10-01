package com.tinyspeck.engine.view.ui.imagination
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.view.ui.Cloud;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;

	public class ImgMenuYourLooks extends ImgMenuElement
	{	
		private var avatar_holder:Sprite = new Sprite();
		
		public function ImgMenuYourLooks(){}
		
		override protected function buildBase():void {
			super.buildBase();
			
			//set the title
			setTitle('<span class="imagination_menu_title_small">Your looks</span>');
			
			//set that cloud
			setCloudByType(Cloud.TYPE_YOUR_LOOKS);
			cloud.y += 5; //little visual nudge
			cloud_hover.y += 5;
			
			//set sound
			sound_id = 'CLOUD4';
			
			//avatar holder
			avatar_holder.y = 15;
			holder.addChild(avatar_holder);
		}
		
		override public function show():Boolean {
			if(!is_built) buildBase();
			if(!super.show()) return false;
			
			//show the player's current avatar
			const pc:PC = TSModelLocator.instance.worldModel && TSModelLocator.instance.worldModel ? TSModelLocator.instance.worldModel.pc : null;
			if(pc && pc.singles_url && pc.singles_url != avatar_holder.name){
				while(avatar_holder.numChildren) avatar_holder.removeChildAt(0);
				avatar_holder.name = pc.singles_url;
				AssetManager.instance.loadBitmapFromWeb(pc.singles_url+'_50.png', onAvatarLoad, 'Avatar Look UI');
			}
			
			return true;
		}
		
		override public function hide():void {
			super.hide();
			ImaginationYourLooksUI.instance.hide();
		}
		
		private function onAvatarLoad(filename:String, bm:Bitmap):void {
			while(avatar_holder.numChildren) avatar_holder.removeChildAt(0);
			if(bm){
				bm.scaleX = -1;
				bm.x = bm.width;
				avatar_holder.addChild(bm);
				avatar_holder.x = int(bm.width/2 - cloud.width/2 - 5);
			}
			else {
				CONFIG::debugging {
					Console.warn('no bitmap?:'+bm+' filename: '+filename+' holder name: '+avatar_holder.name);
				}
			}
		}
	}
}