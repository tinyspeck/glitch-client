package com.tinyspeck.engine.view.ui.quest
{
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Toast;
	
	import flash.display.Graphics;
	import flash.events.TimerEvent;
	
	public class QuestToast extends Toast
	{
		private static const HEIGHT:uint = 40;
		private static const TEXT_PADD:uint = 20;
		
		public var show_bt:Button;
		
		public function QuestToast(w:int){
			super(w, Toast.TYPE_WARNING, '', Toast.DIRECTION_DOWN);
			h = HEIGHT;
			animation_time = 0;
		}
		
		override protected function construct():void {
			super.construct();
			
			//take out the icons
			SpriteUtil.clean(icon_holder);
			SpriteUtil.clean(close_holder);
			
			show_bt = new Button({
				name: 'show',
				label: 'Show me one',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			show_bt.y = int(HEIGHT/2 - show_bt.height/2);
			show_bt.addEventListener(TSEvent.CHANGED, onShowClick, false, 0, true);
			holder.addChild(show_bt);
		}
		
		override protected function draw(reset_position:Boolean = true):void {
			super.draw(reset_position);
			
			//make the toast rectangle
			var g:Graphics = holder.graphics;
			g.clear();
			g.beginFill(background_color, background_alpha);
			g.drawRect(0, 0, _w, h);
			
			msg_tf.x = TEXT_PADD;
			if(show_bt) show_bt.x = int(msg_tf.x + msg_tf.width + 10);
		}
		
		private function onShowClick(event:TSEvent):void {
			if(show_bt.disabled) return;
			show_bt.disabled = true;
			dispatchEvent(new TSEvent(TSEvent.STARTED));
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
		}
		
		override protected function onTimerTick(event:TimerEvent):void {
			//this toast doesn't go away, so just stop the timer
			hide_timer.stop();
		}
	}
}