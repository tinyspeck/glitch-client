package com.tinyspeck.engine.view.ui.making
{
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class MakingErrorUI extends Sprite
	{
		private var try_bt:Button;
		
		private var all_holder:Sprite = new Sprite();
		
		private var tf:TextField = new TextField();
		
		public function MakingErrorUI(){
			TFUtil.prepTF(tf);
			all_holder.addChild(tf);
			
			try_bt = new Button({
				name: 'try',
				label: 'Try again?',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			try_bt.addEventListener(TSEvent.CHANGED, onTryClick, false, 0, true);
			all_holder.addChild(try_bt);
			
			addChild(all_holder);
		}
		
		public function show(msg:String, w:int, h:int):void {
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0, 0);
			g.drawRect(0, 0, w, h);
			
			tf.htmlText = '<p class="making_error_body">'+msg+'</p>';
			tf.width = w;
			
			try_bt.x = int(w/2 - try_bt.width/2);
			try_bt.y = int(tf.height + 15);
			
			all_holder.x = int(w/2 - all_holder.width/2);
			all_holder.y = int(h/2 - all_holder.height/2);
		}
		
		private function onTryClick(event:TSEvent):void {
			dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
		}
	}
}