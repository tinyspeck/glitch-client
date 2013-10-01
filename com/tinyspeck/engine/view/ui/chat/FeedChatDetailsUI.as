package com.tinyspeck.engine.view.ui.chat
{
	import com.tinyspeck.engine.data.chat.FeedItem;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.FeedManager;
	import com.tinyspeck.engine.util.TFUtil;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.text.TextField;

	public class FeedChatDetailsUI extends Sprite
	{
		private static const REPLY_TEXT_PADDING:uint = 7;
		private static const REPLY_POINTY_WIDTH:uint = 6; //reply bubble pointy thing
		
		private var elements:Vector.<FeedChatElement> = new Vector.<FeedChatElement>();
		private var current_feed_item:FeedItem;
		
		private var in_reply_holder:Sprite = new Sprite();
		private var reply_count_holder:Sprite = new Sprite();
		
		private var in_reply_tf:TextField = new TextField();
		private var reply_count_tf:TextField = new TextField();
		
		private var reply_bg_color:uint = 0xffffff;
		private var reply_border_color:uint = 0xcccccc;
		private var pool_id:int;
		private var _w:int;
		private var _current_feed_item_id:String;
		
		public function FeedChatDetailsUI(w:int){
			_w = w;
			
			//get the bubble colors from the CSS
			reply_bg_color = CSSManager.instance.getUintColorValueFromStyle('feed_details_reply', 'backgroundColor', reply_bg_color);
			reply_border_color = CSSManager.instance.getUintColorValueFromStyle('feed_details_reply', 'borderColor', reply_border_color);
			
			//prep the TFs for the reply holder things	
			TFUtil.prepTF(in_reply_tf, false);
			in_reply_tf.embedFonts = false;
			in_reply_tf.htmlText = '<p class="feed_details_reply">in reply to</p>';
			in_reply_tf.x = REPLY_TEXT_PADDING;
			in_reply_tf.y = REPLY_POINTY_WIDTH - 1;
			in_reply_holder.addChild(in_reply_tf);
			in_reply_holder.mouseEnabled = in_reply_holder.mouseChildren = false;
			buildReplyHolder(0); //builds the in reply holder
			
			TFUtil.prepTF(reply_count_tf, false);
			reply_count_tf.embedFonts = false;
			reply_count_tf.x = REPLY_TEXT_PADDING;
			reply_count_tf.y = -1;
			reply_count_holder.addChild(reply_count_tf);
			reply_count_holder.mouseEnabled = reply_count_holder.mouseChildren = false;
			
			//add the filters to the holders
			const glow:GlowFilter = new GlowFilter();
			glow.color = reply_border_color;
			glow.blurX = glow.blurY = 2;
			glow.alpha = 1;
			glow.strength = 3;
			
			in_reply_holder.filters = [glow];
			reply_count_holder.filters = [glow];
			
			hide();
		}
		
		public function show(feed_item:FeedItem):void {
			visible = true;
			scaleX = scaleY = 1;
			_current_feed_item_id = feed_item.id;
			current_feed_item = feed_item;
						
			var i:int;
			var total:int = elements.length;
			var element:FeedChatElement;
			var next_y:int;
			var show_in_reply_to:Boolean;
			var show_reply_count:Boolean;
			
			//reset the pool
			for(i = 0; i < total; i++){
				element = elements[int(i)];
				if(contains(element)) removeChild(element);
				pool_id = 0;
			}
			
			//reset the reply bubble thingies
			if(contains(in_reply_holder)) removeChild(in_reply_holder);
			if(contains(reply_count_holder)) removeChild(reply_count_holder);
			
			//build out the display
			if(feed_item.type == FeedItem.TYPE_STATUS_REPLY && feed_item.full_in_reply_to){
				element = showElement(feed_item.full_in_reply_to, false, true, feed_item.full_in_reply_to.type == FeedItem.TYPE_STATUS_REPLY);
				
				next_y += element.height;
				
				//place the "in reply to" bubble thing
				in_reply_holder.x = int(_w/2 - in_reply_holder.width/2);
				in_reply_holder.y = int(next_y - in_reply_holder.height/2 - REPLY_POINTY_WIDTH + 1); //1 is for the border
				show_in_reply_to = true;
			}
			
			//the one we clicked on
			element = showElement(feed_item, feed_item.full_in_reply_to != null, feed_item.full_replies != null);
			element.y = next_y;
			
			next_y += element.height;
			
			//show any replies
			if(feed_item.full_replies){
				total = feed_item.full_replies.length;
				if(total) {
					show_reply_count = true;
					buildReplyHolder(total);
					reply_count_holder.x = int(_w/2 - reply_count_holder.width/2);
					reply_count_holder.y = int(next_y - (reply_count_holder.height - REPLY_POINTY_WIDTH)/2 - 1); //1 is for the border
				}
				
				for(i = 0; i < total; i++){
					element = showElement(feed_item.full_replies[int(i)], i == 0);
					element.y = next_y;
					
					next_y += element.height;
				}
			}
			
			//after it's done, place the in reply to / reply count on top of things
			if(show_in_reply_to) addChild(in_reply_holder);
			if(show_reply_count) addChild(reply_count_holder);
		}
		
		public function hide():void {
			visible = false;
			scaleX = scaleY = .001;
			_current_feed_item_id = null;
			current_feed_item = null;
		}
		
		private function showElement(feed_item:FeedItem, extra_head_padd:Boolean = false, extra_foot_padd:Boolean = false, show_reply_name:Boolean = false):FeedChatElement {
			var element:FeedChatElement;
			
			if(elements.length > pool_id){
				element = elements[int(pool_id)];
			}
			else {
				element = new FeedChatElement(feed_item.id, _w, true);
				element.addEventListener(TSEvent.CHANGED, onReplyClick, false, 0, true);
				element.addEventListener(TSEvent.ACTIVITY_HAPPENED, onElementClick, false, 0, true);
				elements.push(element);
			}
			
			element.show_full_avatar = feed_item.id == current_feed_item_id;
			element.extra_head_padd = extra_head_padd;
			element.extra_foot_padd = extra_foot_padd;
			element.show(feed_item, show_reply_name);
			addChild(element);
			
			//increment so we don't snatch the one we just made
			pool_id++;
			
			return element;
		}
		
		private function buildReplyHolder(reply_count:int):void {
			var tf:TextField = reply_count_tf;
			var holder:Sprite = reply_count_holder;
			
			//place the reply count in there
			if(reply_count > 0){
				tf.htmlText = '<p class="feed_details_reply">'+reply_count+' '+(reply_count != 1 ? 'replies' : 'reply')+'</p>'
			}
			//must be the in reply to
			else {
				tf = in_reply_tf;
				holder = in_reply_holder;
			}
			
			const point_start_x:Number = tf.x + tf.width/2;
			const g:Graphics = holder.graphics;
			
			g.clear();
			g.beginFill(reply_bg_color);
			
			//box
			g.drawRoundRect(0, (holder == reply_count_holder ? 0 : REPLY_POINTY_WIDTH), tf.width + REPLY_TEXT_PADDING*2, tf.height, 4);
			
			//pointy thing
			g.moveTo(point_start_x - REPLY_POINTY_WIDTH/2, (holder == reply_count_holder ? tf.height : REPLY_POINTY_WIDTH));
			g.lineTo(point_start_x + .5, (holder == reply_count_holder ? tf.height + REPLY_POINTY_WIDTH : 0));
			g.lineTo(point_start_x + REPLY_POINTY_WIDTH, (holder == reply_count_holder ? tf.height : REPLY_POINTY_WIDTH));
			g.lineTo(point_start_x - REPLY_POINTY_WIDTH/2, (holder == reply_count_holder ? tf.height : REPLY_POINTY_WIDTH));
		}
		
		private function onReplyClick(event:TSEvent):void {
			dispatchEvent(new TSEvent(TSEvent.CHANGED, event.data));
		}
		
		private function onElementClick(event:TSEvent):void {
			//see if we know about this one or if we need to go ask the API for it
			current_feed_item = FeedManager.instance.getFeedItem(event.data as String);
			
			if(!current_feed_item || (current_feed_item_id != event.data)){
				hide();
				FeedManager.instance.getDetails(event.data as String);
			}
			else if(current_feed_item && current_feed_item.full_in_reply_to && current_feed_item_id != event.data){
				hide();
				FeedManager.instance.getDetails(current_feed_item.full_in_reply_to.id);
			}
			else {
				onReplyClick(event);
			}
		}
		
		public function get current_feed_item_id():String { return _current_feed_item_id; }
	}
}