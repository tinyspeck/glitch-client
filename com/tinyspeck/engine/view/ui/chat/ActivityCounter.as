package com.tinyspeck.engine.view.ui.chat
{
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;

	public class ActivityCounter extends Sprite
	{
		protected var holder:Sprite = new Sprite();
		
		protected var tf:TextField = new TextField();
		
		protected var current_count:int;
		
		public function ActivityCounter(){
			mouseChildren = false;
			
			construct();
			
			//hide until we increment
			visible = false;
		}
		
		protected function construct():void {
			var g:Graphics = holder.graphics;
			g.beginFill(CSSManager.instance.getUintColorValueFromStyle('activity_counter', 'backgroundColor', 0xb1b7ba));
			g.drawRoundRect(0, 0, 21, 14, 12);
			addChild(holder);
			
			TFUtil.prepTF(tf);
			tf.multiline = false;
			tf.filters = StaticFilters.black1px270Degrees_DropShadowA;
			tf.width = holder.width - 2;
			tf.y = -2;
			holder.addChild(tf);
		}
		
		public function increment():void {
			current_count++;
			updateCount();
			visible = true;
		}
		
		public function clear(event:Event = null):void {
			current_count = 0;
			visible = false;
		}
		
		protected function updateCount():void {
			tf.htmlText = '<p class="activity_counter">'+count+'</p>';
		}
		
		public function get count():String {
			return current_count <= 99 ? current_count.toString() : '∞';
		}
	}
}