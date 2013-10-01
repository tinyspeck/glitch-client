package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.Achievement;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.loader.SmartLoader;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;

	public class AchievementIcon extends Sprite
	{
		/******* IF SKILL ICONS CHANGE IN DIMENSION THIS NEEDS TO BE CHANGED ********
		 * Nov. 12, 2010 default skill icons w/h - www/img/skills/
		 ****************************************************************************/
		public static const TYPE_SWF:String = 'swf';
		public static const TYPE_PNG:String = 'png';
		public static const SIZE_180:uint = 180;
		public static const SIZE_60:uint = 60;
		public static const SIZE_40:uint = 40;
		
		private var loaderContext:LoaderContext = new LoaderContext(true);
		private var loader:SmartLoader;
		private var type:String;
		private var size:uint;
		private var tsid:String;
		private var url:String;
		
		public function AchievementIcon(tsid:String, size:uint = AchievementIcon.SIZE_40, type:String = AchievementIcon.TYPE_PNG){
			mouseChildren = false;
			
			if(!tsid){
				CONFIG::debugging {
					Console.warn('NO TSID PASSED TO ACHIEVEMENT ICON');
				}
				return;
			}
			//build the image directory
			var achievement:Achievement = TSModelLocator.instance.worldModel.getAchievementByTsid(tsid);
			CONFIG::debugging {
				if(!achievement){
					Console.warn('Could not find the achievement "'+tsid+'" in the world. Showing default icon.');
				}
			}
			
			//if we are doing a PNG let's be smart about which one we go fetch to resize
			var load_size:String = type;
			if(type == AchievementIcon.TYPE_PNG){
				if(size <= AchievementIcon.SIZE_40){
					load_size = AchievementIcon.SIZE_40.toString();
				}
				else if(size <= AchievementIcon.SIZE_60){
					load_size = AchievementIcon.SIZE_60.toString();
				}
				else if(size <= AchievementIcon.SIZE_180){
					load_size = AchievementIcon.SIZE_180.toString();
				}
				else {
					//use the SWF
					type = AchievementIcon.TYPE_SWF;
					load_size = AchievementIcon.TYPE_SWF;
				}
			}
			
			if(achievement && achievement.icon_urls && achievement.icon_urls[load_size]){
				url = achievement.icon_urls[load_size];
				loader = new SmartLoader('AchievementIcon');
				// these are automatically removed on complete or error:
				loader.complete_sig.add(onSmartLoaderComplete);
				loader.error_sig.add(onSmartLoaderError);

				loader.load(new URLRequest(url), loaderContext);
							
				CONFIG::debugging {
					Console.log(66, url);
				}
			}
			//load the default
			else {
				url = null;
				var badge_default:MovieClip = new AssetManager.instance.assets.achievement_badge();
				badge_default.addEventListener(Event.COMPLETE, onAssetComplete, false, 0, true);
			}
			
			//while it loads, give this sprite the proper w/h incase we need it
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0,0);
			g.drawRect(0, 0, size, size);
			
			//set the name to the tsid
			name = tsid;
			
			//set the size
			this.size = size;
			this.tsid = tsid;
			this.type = type;
		}
		
		private function onSmartLoaderError(loader:SmartLoader):void {
			CONFIG::debugging {
				Console.warn('Failed to load skill graphic from ' + url);
			}
			BootError.addErrorMsg('# Failed to load skill graphic from --> ' + url, null, ['loader']);
			loader.unload();
		}
		
		private function onAssetComplete(event:Event):void {
			const icon:DisplayObject = Loader(event.target.getChildAt(0)).content as MovieClip;
			if(icon){
				//set the width and height of the icon
				icon.width = icon.height = size;
				addChild(icon);
				
				dispatchEvent(new TSEvent(TSEvent.COMPLETE, this));
				
				graphics.clear();
			}
			else {
				CONFIG::debugging {
					Console.warn('OH JESUS, WHY DID THIS NOT LOAD?!');
				}
			}
		}
		
		private function onSmartLoaderComplete(loader:SmartLoader):void {
			const icon:DisplayObject = loader.content;
			if(icon){
				//set the width and height of the icon
				icon.width = icon.height = size;
				addChild(icon);
				
				dispatchEvent(new TSEvent(TSEvent.COMPLETE, this));
				
				graphics.clear();
			}
			else {
				CONFIG::debugging {
					Console.warn('OH JESUS, WHY DID THIS NOT LOAD?!');
				}
			}
		}
	}
}