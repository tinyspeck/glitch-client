package com.tinyspeck.engine.view.ui.chat
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.utils.Timer;

	public class ContactListActivityCounter extends ActivityCounter
	{
		private static const THROB_TIME:Number = .3; //how fast to animate the throb
		
		private var holder_throb:Sprite = new Sprite();
		
		private var tf_throb:TextField = new TextField();
		
		private var throb_timer:Timer = new Timer(5000);
		
		public function ContactListActivityCounter(){
			super();

			useHandCursor = buttonMode = true;
			
			//build it
			construct();
		}
		
		override protected function construct():void {
			super.construct();
			
			const radius:Number = 8.5;
			
			var g:Graphics = holder.graphics;
			g.clear();
			g.beginFill(CSSManager.instance.getUintColorValueFromStyle('contact_list_counter', 'backgroundColor', 0xc71700));
			g.drawCircle(radius, radius, radius);
			
			g = holder_throb.graphics;
			g.beginFill(CSSManager.instance.getUintColorValueFromStyle('contact_list_counter_throb', 'backgroundColor', 0xffffff));
			g.drawCircle(radius, radius, radius);
			holder_throb.alpha = 0;
			addChild(holder_throb);
			
			filters = StaticFilters.white1px_GlowA;
			
			//throb tf
			TFUtil.prepTF(tf_throb);
			tf_throb.multiline = false;
			holder_throb.addChild(tf_throb);
			
			tf.filters = null;
			tf.width = tf_throb.width = holder.width;
			tf.x = tf_throb.x = -2.5;
			tf.y = tf_throb.y = 0;
			
			//throb every 5 secs as long as this is visible
			throb_timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
		}
		
		override public function increment():void {
			super.increment();
			if(!throb_timer.running) throb_timer.start();
		}
		
		override public function clear(event:Event = null):void {
			super.clear(event);
			throb_timer.stop();
		}
		
		override protected function updateCount():void {
			tf.htmlText = '<p class="contact_list_counter">'+count+'</p>';
			tf_throb.htmlText = '<p class="contact_list_counter"><span class="contact_list_counter_throb">'+count+'</span></p>';
		}
		
		private function onTimerTick(event:TimerEvent):void {
			if(!visible){
				throb_timer.stop();
				return;
			}
			
			//do a quick throb
			TSTweener.removeTweens(holder_throb);
			TSTweener.addTween(holder_throb, {alpha:1, time:THROB_TIME, transition:'linear'});
			TSTweener.addTween(holder_throb, {alpha:0, time:THROB_TIME, delay:THROB_TIME, transition:'linear'});
		}
	}
}