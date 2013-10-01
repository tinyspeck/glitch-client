package com.tinyspeck.engine.view.ui.imagination
{
	import com.tinyspeck.engine.data.location.Hub;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Cloud;
	import com.tinyspeck.engine.view.util.StaticFilters;
	

	public class ImgMenuHome extends ImgMenuElement
	{	
		private var go_bt:Button;
		
		private var _is_home:Boolean;
		
		public function ImgMenuHome(){}
		
		override protected function buildBase():void {
			super.buildBase();
			
			//set the title
			setTitle('Go home');
			
			//set that cloud
			setCloudByType(Cloud.TYPE_HOME);
			
			//set sound
			sound_id = 'CLOUD6';
			
			//go button
			go_bt = new Button({
				name: 'go',
				label: 'Go',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR,
				w: 50,
				h: 34
			});
			go_bt.filters = StaticFilters.copyFilterArrayFromObject({color:0, blurX:10, blurY:10, alpha:.2}, StaticFilters.white4px40AlphaGlowA);
			//holder.addChild(go_bt);
		}
		
		override public function show():Boolean {
			if(!is_built) buildBase();
			if(!super.show()) return false;
			
			//if we aren't on our home street, load that image, otherwise load the image of where we go back to the world
			const world:WorldModel = TSModelLocator.instance.worldModel;
			var location:Location = world.location;
			_is_home = world.pc.home_info.isTsidInHome(location.tsid);
			
			setTitle(is_home ? 'Back to world' : 'Go home');
			
			go_bt.x = int(cloud.width/2 - go_bt.width/2);
			go_bt.y = int(cloud.y + cloud.height - go_bt.height/2);
			
			//handle previous location if we are home
			location = is_home ? world.getLocationByTsid(world.pc.previous_location_tsid) : world.getLocationByTsid(world.pc.home_info.exterior_tsid);
			
			//show a tooltip if we can leave home
			tip_txt = location && enabled && is_home ? location.label : null;
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
		
		public function get is_home():Boolean { return _is_home; }
	}
}