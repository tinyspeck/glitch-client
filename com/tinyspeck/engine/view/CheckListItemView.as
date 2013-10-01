package com.tinyspeck.engine.view {
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.TFUtil;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	public class CheckListItemView extends TSSpriteWithModel {
		
		private var txt:String;
		private var tf:TextField = new TextField();
		private var checkmark_mc:MovieClip;

		public function get checkmarkDO():DisplayObject {
			return checkmark_mc as DisplayObject;
		}
		
		public function CheckListItemView(txt:String, tsid:String=null) {
			super(tsid);
			this.txt = txt;
			init();
		}
		
		private function init():void {
			TFUtil.prepTF(tf, false);
			tf.htmlText = '<p class="hub_map_hub_button_go">'+txt+'</p>';
			addChild(tf);
			
			checkmark_mc = new AssetManager.instance.assets['greencheck'];
			addChild(checkmark_mc);
			tf.x = checkmark_mc.width+5;
			tf.y = Math.round((checkmark_mc.height-tf.height)/2);
			
			var g:Graphics = graphics;
			g.lineStyle(0, 0, 0);
			g.beginFill(0, 0);
			g.drawRect(0, 0, width, height);
		}
	}
	
}