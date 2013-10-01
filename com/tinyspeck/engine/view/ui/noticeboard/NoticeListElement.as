package com.tinyspeck.engine.view.ui.noticeboard
{
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.NoticeBoardManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Sprite;
	
	public class NoticeListElement extends TSSpriteWithModel
	{
		public static const PIN_COLORS:Array = new Array('red', 'green', 'blue', 'yellow');
		
		private static const PADD:uint = 5;
		private static const TEXT_X:uint = 27;
		
		private static var paper_bg:Bitmap;
		
		private var pin_holder:Sprite = new Sprite();
		
		private var take_bt:Button;
		private var read_bt:Button;
		private var body_tf:TSLinkedTextField = new TSLinkedTextField();
		private var author_tf:TSLinkedTextField = new TSLinkedTextField();
		
		public function NoticeListElement(w:int){
			_w = w;
			
			read_bt = new Button({
				name: 'read',
				label: 'Read',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			read_bt.x = _w - read_bt.width - PADD*2;
			read_bt.addEventListener(TSEvent.CHANGED, onReadClick, false, 0, true);
			addChild(read_bt);
			
			take_bt = new Button({
				name: 'take',
				label: 'Take',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			take_bt.x = read_bt.x - take_bt.width - 5;
			take_bt.addEventListener(TSEvent.CHANGED, onTakeClick, false, 0, true);
			addChild(take_bt);
			
			TFUtil.prepTF(body_tf);
			body_tf.embedFonts = false;
			body_tf.width = take_bt.x - 15 - TEXT_X;
			body_tf.x = TEXT_X;
			body_tf.y = PADD;
			body_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			//body_tf.border = true;
			addChild(body_tf);
			
			TFUtil.prepTF(author_tf, false);
			author_tf.embedFonts = false;
			//author_tf.border = true;
			author_tf.x = TEXT_X;
			author_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			addChild(author_tf);
			
			if(!paper_bg){
				paper_bg = new AssetManager.instance.assets.paper_texture();
			}
			
			//pin holder
			pin_holder.x = 3;
			pin_holder.y = 2;
			addChild(pin_holder);
		}
		
		private function draw():void {
			author_tf.y = author_tf.text != '' ? int(body_tf.y + body_tf.height) : 0;
			
			var g:Graphics = graphics;
			g.clear();
			g.beginBitmapFill(paper_bg.bitmapData);
			g.drawRect(0, 0, _w, int(height + PADD*2));
			
			//position the buttons
			read_bt.y = int(height/2 - read_bt.height/2) - 1;
			take_bt.y = int(height/2 - take_bt.height/2) - 1;
		}
		
		private function onReadClick(event:TSEvent):void {
			if(read_bt.disabled) return;
			NoticeBoardManager.instance.read(tsid);
		}
		
		private function onTakeClick(event:TSEvent):void {
			if(take_bt.disabled) return;
			NoticeBoardManager.instance.take(tsid);
		}
		
		public function set body(value:String):void {
			body_tf.htmlText = '<p class="notice_element">'+value+'</p>';
			
			draw();
		}
		
		public function set author(value:String):void {			
			author_tf.htmlText = '<p class="notice_element_author">'+value+'</p>';
			
			draw();
		}
		
		public function set can_take(value:Boolean):void {
			take_bt.visible = value;
		}
		
		public function set can_read(value:Boolean):void {
			read_bt.disabled = !value;
			read_bt.tip = !value ? {txt:'It\'s blank :('} : null;
		}
		
		public function set pin_color(color:String):void {
			if(PIN_COLORS.indexOf(color) == -1) return;
			
			if(pin_holder.name != color){
				SpriteUtil.clean(pin_holder);
				pin_holder.addChild(new AssetManager.instance.assets['pushpin_sm_'+color]());
				pin_holder.name = color;
			}
		}
	}
}