package com.tinyspeck.engine.view.ui.chat
{
	import com.tinyspeck.engine.data.chat.FeedItem;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.RightSideView;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class FeedReplyUI extends Sprite
	{
		private var title_tf:TextField = new TextField();
		private var body_tf:TextField = new TextField();
		
		private var close_holder:Sprite = new Sprite();
		
		private var _w:int;
		private var _current_id:String;
		
		public function FeedReplyUI(w:int){
			_w = w;
			
			close_holder.addChild(new AssetManager.instance.assets.feed_reply_close());
			close_holder.x = RightSideView.CHAT_PADD;
			close_holder.y = 6;
			close_holder.useHandCursor = close_holder.buttonMode = true;
			close_holder.addEventListener(MouseEvent.CLICK, onCloseClick, false, 0, true);
			addChild(close_holder);
			
			TFUtil.prepTF(title_tf, false);
			title_tf.embedFonts = false;
			title_tf.x = close_holder.x + close_holder.width + 2;
			title_tf.y = close_holder.y - 3;
			addChild(title_tf);
			
			TFUtil.prepTF(body_tf);
			body_tf.embedFonts = false;
			body_tf.x = RightSideView.CHAT_PADD;
			body_tf.width = _w - RightSideView.CHAT_PADD*2;
			addChild(body_tf);
		}
		
		public function show(feed_item:FeedItem):void {
			if(!feed_item) return;
			
			_current_id = feed_item.id;
			
			//are we replying to ourself?
			var who:String = feed_item.who_tsid != TSModelLocator.instance.worldModel.pc.tsid ? feed_item.who_name : 'yourself' ;
			
			visible = true;
			title_tf.htmlText = '<p class="feed_reply_title">Reply to <b>'+who+'</b></p>';
			body_tf.htmlText = '<p class="feed_reply_body">"'+StringUtil.encodeHTMLUnsafeChars(StringUtil.truncate(feed_item.txt, 100, true))+'"</p>';
			body_tf.y = title_tf.height + 2;
			
			//draw the bg
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRect(0, 0, _w, int(body_tf.y + body_tf.height + 5));
			g.endFill();
			
			g.beginFill(0xe6e6e6);
			g.drawRect(0, 0, _w, 1);
		}
		
		public function hide():void {
			visible = false;
			_current_id = null;
		}
		
		private function onCloseClick(event:MouseEvent):void {
			dispatchEvent(new TSEvent(TSEvent.CLOSE));
		}
		
		public function get current_id():String { return _current_id; }
	}
}