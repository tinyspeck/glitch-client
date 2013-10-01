package com.tinyspeck.engine.view.ui.imagination
{
	import com.tinyspeck.engine.data.location.Hub;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.view.ui.Cloud;
	

	public class ImgMenuBackToWorld extends ImgMenuElement
	{		
		public function ImgMenuBackToWorld(){}
		
		override protected function buildBase():void {
			super.buildBase();
			
			// make it a little smaller than usual
			spinner.scaleX = spinner.scaleY = 0.5;
			spinner.alpha = 0.5;
			
			//set the title
			setTitle('<span class="imagination_menu_title_small">Back to world</span>');
			
			//set that cloud
			setCloudByType(Cloud.TYPE_BACK_TO_WORLD);
			
			//set sound
			sound_id = 'CLOUD7';
		}
		
		override public function show():Boolean {
			if(!is_built) buildBase();
			if(!super.show()) return false;
			
			//if we aren't on our home street, load that image, otherwise load the image of where we go back to the world
			const world:WorldModel = TSModelLocator.instance.worldModel;
			var location:Location = world.location;
			const is_home:Boolean = world.pc.home_info.isTsidInHome(location.tsid);
			
			setTitle('<span class="imagination_menu_title_small">'+(is_home ? 'Go home' : 'Back to world')+'</span>');
			
			//if we are in our house or not in POLland, disable this
			enabled = !is_home && location.is_pol;
			
			//get the previous location
			//if we are in POL land previous location should be that, otherwise it should just be where we are now
			if(location.is_pol){
				location = is_home ? world.getLocationByTsid(world.pc.home_info.exterior_tsid) : world.getLocationByTsid(world.pc.previous_location_tsid);
			}
			
			tip_txt = location && enabled && !is_home ? location.label : null;
			if(tip_txt && !location.is_pol){
				//get the hub name and add it to the tooltip
				const hub:Hub = world.getHubByTsid(location.hub_id);
				if(hub) tip_txt += ', '+hub.label;
			}
			drawTip();
			
			if(location && location.mapInfo && location.mapInfo.image_full){
				setImageInMask(location.mapInfo.image_full.url);
			}
			
			return true;
		}
	}
}