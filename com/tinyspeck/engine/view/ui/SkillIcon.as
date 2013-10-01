package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.utils.Dictionary;

	public class SkillIcon extends Sprite
	{
		/******* IF SKILL ICONS CHANGE IN DIMENSION THIS NEEDS TO BE CHANGED ********
		 * Nov. 12, 2010 default skill icons w/h - www/img/skills/
		 ****************************************************************************/
		public static const SIZE_DEFAULT:uint = 44;
		public static const SIZE_100:uint = 100;
		public static const SIZE_460:uint = 460;
		
		private var size:uint;
		private var tsid:String;
		
		public function SkillIcon(tsid:String, size:uint = SkillIcon.SIZE_DEFAULT){
			if(!tsid){
				CONFIG::debugging {
					Console.warn('NO TSID PASSED TO SKILL ICON');
				}
				return;
			}
			
			//set the name to the tsid
			name = tsid;
			
			//set the size
			this.size = size;
			this.tsid = tsid;
			
			//while it loads, give this sprite the proper w/h incase we need it
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0,0);
			g.drawRect(0, 0, size, size);
			
			
			AssetManager.instance.loadBitmapFromWeb(makeIconUrl(tsid, size), bmLoaded, 'SkillIcon');
		}
		
		public static function makeIconUrl(tsid:String, size:uint):String {
			var skill_urls:Object = TSModelLocator.instance.worldModel.skill_urls;
			var img_key:String = 'icon_'+size;
			var url:String;
			
			//set the img_key
			if(size <= SIZE_DEFAULT){
				img_key = 'icon_'+SIZE_DEFAULT;
			}
			else if(size <= SIZE_100){
				img_key = 'icon_'+SIZE_100;
			}
			else {
				img_key = 'icon_'+SIZE_460;
			}
			
			if (skill_urls[tsid] && skill_urls[tsid][img_key]) {
				url = skill_urls[tsid][img_key];
			} else {
				url = TSModelLocator.instance.flashVarModel.root_url+'img/skills/'+tsid+'.png';
			}
			return url;
		}
		
		private function bmLoaded(filename:String, bm:Bitmap):void {
			if (!bm) {
				//load the none icon as a last ditch effort
				if (tsid != 'none'){
					tsid = 'none';
					var url:String = TSModelLocator.instance.flashVarModel.root_url+'img/skills/none.png';
					AssetManager.instance.loadBitmapFromWeb(url, bmLoaded, 'SkillIcon loading the none');
				}
				return;
			}
			bm.smoothing = true;
			bm.width = bm.height = size;
			addChild(bm);
			graphics.clear();
		}

	}
}