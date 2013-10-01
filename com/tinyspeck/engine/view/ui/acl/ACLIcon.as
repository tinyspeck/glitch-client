package com.tinyspeck.engine.view.ui.acl
{
	import com.tinyspeck.engine.port.AssetManager;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;

	public class ACLIcon extends Sprite
	{
		private static const WIDTH:uint = 50; //each icon is 50x50. if the spritesheet ever changes, this will need to change
		private static const HEIGHT:uint = 50;
		private static const MAX_KEYS:uint = 4; //how many icons we have keys for
		
		private var masker:Sprite = new Sprite();
		
		private var icons:DisplayObject;
		
		private var _key_count:int;
		
		public function ACLIcon(key_count:uint = 0, show_stroke:Boolean = true){
			var g:Graphics = masker.graphics;
			g.beginFill(0);
			g.drawRect(0, 0, WIDTH, HEIGHT);
			addChild(masker);
			
			mask = masker;
			
			//add on the icons
			icons = new AssetManager.instance.assets[(show_stroke ? 'acl_icons' : 'acl_icons_no_stroke')];
			addChild(icons);
			
			//if there was a count set, go do it!
			if(key_count) this.key_count = key_count;
		}
		
		public function get key_count():int { return _key_count; }
		public function set key_count(value:int):void {
			_key_count = value;
			
			icons.visible = value > 0;
			
			//don't go over the max keys we have icons for
			value = Math.min(value, MAX_KEYS);
			
			if(value){
				//move it to where it needs to go
				icons.x = -((value - 1) * WIDTH);
			}
		}
		
		//make sure we only return the width of 1 icon instead of the whole sheet
		override public function get width():Number {
			return WIDTH;
		}
		
		override public function get height():Number {
			return HEIGHT;
		}
	}
}