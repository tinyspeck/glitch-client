package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;

	public class Cloud extends Sprite
	{
		public static const TYPE_BACK_TO_WORLD:String = 'cloud_back_to_world';
		public static const TYPE_HOME:String = 'cloud_home';
		public static const TYPE_KEYS:String = 'cloud_keys';
		public static const TYPE_QUESTS:String = 'cloud_quests';
		public static const TYPE_SKILLS:String = 'cloud_skills';
		public static const TYPE_SKILLS_LARGE:String = 'cloud_skills_large';
		public static const TYPE_UPGRADES:String = 'cloud_upgrades';
		public static const TYPE_YOUR_LOOKS:String = 'cloud_your_looks';
		
		private static var clouds_mc:MovieClip;
		private static var loading_clouds:Boolean;
		
		private var _type:String
		
		public function Cloud(type:String = Cloud.TYPE_SKILLS, apply_glow:Boolean = true){
			if(!clouds_mc && !loading_clouds){
				const cloud_loader:MovieClip = new AssetManager.instance.assets.imagination_clouds();
				cloud_loader.addEventListener(Event.COMPLETE, onAssetLoaded, false, 0, true);
				loading_clouds = true;
			}
			
			if(apply_glow) filters = StaticFilters.cloud_glowA;
			
			this.type = type;
		}
		
		protected function onAssetLoaded(event:Event):void {
			//set our clouds mc
			const clouds_loader:Loader = MovieClip(event.currentTarget).getChildAt(0) as Loader;
			clouds_mc = clouds_loader.content as MovieClip;
			loading_clouds = false;
		}
		
		public function get type():String { return _type; }
		public function set type(value:String):void {
			_type = value;
			SpriteUtil.clean(this);
			
			//load the cloud
			if(!is_loaded){
				//no clouds?! try again fast!
				StageBeacon.setTimeout(function():void { type = _type; }, 300);
				return;
			}
			
			//if this is "your looks" we hijack the old keys one
			if(type == TYPE_YOUR_LOOKS){
				value = TYPE_KEYS;
			}
			
			const cloud_mc:MovieClip = clouds_mc.getAssetByName(value) as MovieClip;
			if(cloud_mc){
				addChild(cloud_mc);
			}
		}
		
		public function get is_loaded():Boolean {
			return clouds_mc != null;
		}
	}
}