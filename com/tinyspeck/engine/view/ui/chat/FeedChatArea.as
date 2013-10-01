package com.tinyspeck.engine.view.ui.chat
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.chat.FeedItem;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.FeedManager;
	import com.tinyspeck.engine.port.RightSideView;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;

	public final class FeedChatArea extends ChatArea
	{	
		private var reply_ui:FeedReplyUI;
		private var details_ui:FeedChatDetailsUI;
		private var back_bt:Button;
		private var refresh_bt:Button;
		
		private var reply_holder:Sprite = new Sprite();
		private var reply_mask:Sprite = new Sprite();
		private var no_updates_holder:Sprite;
		
		private var no_updates_tf:TextField;
		
		private var spinner:MovieClip;
		
		private var element_width:int = -1;
		private var scroller_y_snapshot:int;
		
		private var populated_input_text:String = '';
		private var _reply_id:String;
		
		private var scroller_at_max:Boolean;
		private var _show_loader:Boolean;
		
		public function FeedChatArea(unique_id:String){
			super(unique_id);
			
			//add the reply holder
			reply_holder.addChild(reply_mask);
			reply_holder.x = -RightSideView.CHAT_PADD;
			addChild(reply_holder);
			
			//load a spinner
			const spinner_loader:MovieClip = new AssetManager.instance.assets.spinner();
			spinner_loader.addEventListener(Event.COMPLETE, onSpinnerLoad, false, 0, true);
			
			//we need to enable the use_children flag on the scroller because of our masked heads
			scroller.use_children_for_body_h = true;
			
			//add the element and details holders
			element_holder.x = -SCROLL_X_OFFSET;
			
			//build the back button
			const arrow_holder:Sprite = new Sprite();
			const arrow_hover_holder:Sprite = new Sprite();
			const arrow:DisplayObject = new AssetManager.instance.assets.back_arrow();
			const arrow_hover:DisplayObject = new AssetManager.instance.assets.back_arrow_hover();
			SpriteUtil.setRegistrationPoint(arrow);
			SpriteUtil.setRegistrationPoint(arrow_hover);
			arrow_holder.addChild(arrow);
			arrow_holder.rotation = -90;
			arrow_hover_holder.addChild(arrow_hover);
			arrow_hover_holder.rotation = -90;
			back_bt = new Button({
				name: 'back',
				graphic:arrow_holder,
				graphic_hover:arrow_hover_holder,
				graphic_padd_w: 8,
				graphic_padd_t: 11,
				w: 20,
				y: -8,
				draw_alpha: 0
			});
			back_bt.addEventListener(TSEvent.CHANGED, onBackClick, false, 0, true);
			back_bt.visible = false;
			addChild(back_bt);
			
			//build the refresh button
			const refresh_DO:DisplayObject = new AssetManager.instance.assets.chat_refresh();
			refresh_bt = new Button({
				name: 'refresh',
				graphic: refresh_DO,
				w: 20,
				h: refresh_DO.height,
				y: -3,
				draw_alpha: 0
			});
			refresh_bt.addEventListener(TSEvent.CHANGED, onRefreshClick, false, 0, true);
			refresh_bt.visible = false;
			addChild(refresh_bt);
			
			//pre-populate the text input
			input_field.text = populated_input_text;
		}
		
		private function buildNoUpdates():void {
			//the player doesn't have any updates yet, so show them a little message
			no_updates_holder = new Sprite();
			
			no_updates_tf = new TextField();
			TFUtil.prepTF(no_updates_tf);
			no_updates_tf.embedFonts = false;
			no_updates_tf.width = element_width;
			no_updates_holder.addChild(no_updates_tf);
			
			var no_updates_txt:String = '<p class="feed_chat"><span class="feed_chat_no_updates">This is the Updates Pane</span>';
			no_updates_txt += '<br><br>This is a live feed of you and your friends\' <b>status updates</b> and <b>snaps</b>!';
			no_updates_txt += '<br><br>There\'s nothing to show you yet... but once you or your friends start posting, you\'ll see it here!';
			no_updates_txt += '</p>';
			no_updates_tf.htmlText = no_updates_txt;
		}
		
		public function clearFeed():void {
			SpriteUtil.clean(element_holder);
		}
		
		override public function addElement(pc_tsid:String, txt:String, chat_element_type:String='', chat_element_name:String='', element_alpha:Number=1, unix_created_ts:uint=0):void {
			CONFIG::debugging {
				throw new Error('You must use addFeedItem for FeedChatAreas!!!');
			}
		}
		
		public function addFeedItem(feed_item:FeedItem):void {
			//refresh the details if this item is the one we are viewing
			if(details_ui && details_ui.visible && details_ui.current_feed_item_id == feed_item.id) {
				//update
				details_ui.show(feed_item);
				scroller.scrollDownToBottom();
			}
			
			//we need to use our special feed type chat elements
			var element:FeedChatElement = element_holder.getChildByName(feed_item.id) as FeedChatElement;
			
			if(!element){
				//get the last feed timestamp
				const last_saved_timestamp:uint = LocalStorage.instance.getUserData(LocalStorage.LAST_UPDATE_FEED_TIMESTAMP);
				
				//create the element
				element = new FeedChatElement(feed_item.id, element_width);
				element.addEventListener(TSEvent.CHANGED, onElementReply, false, 0, true);
				element.addEventListener(TSEvent.ACTIVITY_HAPPENED, onElementClick, false, 0, true);
				element.y = element_holder.height;
				element_holder.addChild(element);
				
				//update the counter if we aren't in focus
				if(!hasFocus() && feed_item.when > last_saved_timestamp) counter.increment();
			}
			
			//we might have to truncate some old ones
			maybeTruncate();
		}
		
		public function refreshElements():void {
			if(!element_holder.visible) return;
			
			//if you want to make sure the position of the elements are good, do that here
			var i:int;
			var total:int = element_holder.numChildren;
			var element:FeedChatElement;
			var next_y:int;
			var item:FeedItem;
			
			for(i; i < total; i++){
				element = element_holder.getChildAt(i) as FeedChatElement;
				element.y = next_y;
				item = FeedManager.instance.getFeedItem(element.name, false);
				if(item) element.show(item);
				
				next_y += element.height + ELEMENT_PADD;
			}
			
			if(total == 0){
				//no updates, let's show them the message about them
				if(!no_updates_holder) buildNoUpdates();
				if(!no_updates_holder.parent){
					scroller.body.addChild(no_updates_holder);
				}
			}
			else if(no_updates_holder && no_updates_holder.parent){
				//don't need to show it anymore!
				no_updates_holder.parent.removeChild(no_updates_holder);
			}
			
			scroller.refreshAfterBodySizeChange();
		}
		
		public function showDetails(feed_item:FeedItem):void {
			if(details_ui) details_ui.show(feed_item);
			_reply_id = feed_item.id;
			scroller.scrollUpToTop();
			replyClose();
			
			//populate the input
			if(input_field.text == '' || input_field.text == populated_input_text){
				var who:String = model.worldModel.pc.tsid != feed_item.who_tsid ? StringUtil.nameApostrophe(feed_item.who_name) : 'your';
				populated_input_text = 'Reply to '+who+' update...';
				
				//don't populate it if it has focus
				if(!input_field.hasFocus()) input_field.text = populated_input_text;
			}
		}
		
		override protected function draw():void {
			super.draw();
			
			//if we have the reply ui visible, handle the resize properly
			reply_holder.y = input_field.y;
			
			scroller.h = int(_h - scroller.y - input_field.height - SCROLL_GAP_TOP + (reply_ui ? reply_ui.y : 0) - SCROLL_GAP_BOTTOM);
			
			//set the refresh button
			refresh_bt.x = int(close_bt.x - refresh_bt.width - 4);
		}
		
		private function onElementReply(event:TSEvent):void {			
			//go fetch the feed item for this id
			const feed_item:FeedItem = FeedManager.instance.getFeedItem(event.data as String);
			
			if(feed_item){
				_reply_id = feed_item.id;
				
				if(!reply_ui){
					reply_ui = new FeedReplyUI(scroller.w - SCROLL_BAR_W + RightSideView.CHAT_PADD*2 + 3);
					reply_ui.mask = reply_mask;
					reply_ui.addEventListener(TSEvent.CLOSE, onReplyClose, false, 0, true);
					reply_holder.addChild(reply_ui);
				}
				reply_ui.show(feed_item);
				reply_ui.y = 0;
				
				const reply_h:int = reply_ui.height;
				
				//get the mask in there
				var g:Graphics = reply_mask.graphics;
				g.clear();
				g.beginFill(0);
				g.drawRect(0, -reply_h, reply_ui.width, reply_h);
				
				//animate it
				TSTweener.removeTweens(reply_ui);
				TSTweener.addTween(reply_ui, {y:-reply_h, time:.2, onUpdate:draw});
				
				//focus the input
				input_field.focusOnInput();
			}
			else {
				//this should never happen since you *just* clicked the damn thing
				CONFIG::debugging {
					Console.warn('Could not find the element with ID: '+event.data);
				}
			}
		}
		
		public function replyClose():void {
			//public facing shortcut method that makes more sense
			onReplyClose();
		}
		
		private function onReplyClose(event:TSEvent = null):void {
			if(details_ui && details_ui.scaleX == 1){
				//just hide the UI, don't clear the ID
			}
			else {
				//clear the ID
				_reply_id = null;
			}
			
			//hide the ui
			if(reply_ui){
				TSTweener.removeTweens(reply_ui);
				TSTweener.addTween(reply_ui, {y:0, time:.2, onUpdate:draw, onComplete:reply_ui.hide});
			}			
		}
		
		private function onElementClick(event:TSEvent):void {
			const feed_item:FeedItem = FeedManager.instance.getFeedItem(event.data);
			if(!feed_item) return;
			
			//save the current scroller location
			scroller_y_snapshot = scroller.scroll_y;
			scroller_at_max = scroller.scroll_y == scroller.max_scroll_y;
			
			//show the deets
			showDetails(feed_item);
			
			//animate the feed out of the way to show the full thread view
			TSTweener.addTween(element_holder, {x:-element_width, time:.3, 
				onComplete:function():void {
					element_holder.scaleX = element_holder.scaleY = .001;
					element_holder.visible = false;
				}
			});
			TSTweener.addTween(details_ui, {x:-SCROLL_X_OFFSET, time:.3, onComplete:scroller.refreshAfterBodySizeChange, onCompleteParams:[true]});
			
			//shove the title over and show the back button
			title_tf.x = back_bt.width;
			back_bt.visible = true;
			
			//disable the close button
			close_bt.disabled = true;
			close_bt.alpha = .3;
			close_bt.filters = [ColorUtil.getGreyScaleFilter()];
			
			draw();
		}
		
		private function onBackClick(event:TSEvent):void {
			TSTweener.removeTweens([element_holder, details_ui]);
			TSTweener.addTween(element_holder, {x:-SCROLL_X_OFFSET, time:.3, onComplete:onBackComplete});
			TSTweener.addTween(details_ui, {x:element_width - SCROLL_X_OFFSET + SCROLL_BAR_W, time:.3, onComplete:details_ui.hide});
			
			//reset the scale and make it visible again
			element_holder.scaleX = element_holder.scaleY = 1;
			element_holder.visible = true;
			
			//refresh the elements
			refreshElements();
			
			//put the title back and hide the back button
			title_tf.x = 0;
			back_bt.visible = false;
			
			//when clicking back we are always going to kill the reply ID
			_reply_id = null;
			
			//close up the reply thingie
			onReplyClose();
			
			//empty out the text field
			if(input_field.text == '' || input_field.text == populated_input_text) {
				populated_input_text = '';
				input_field.text = populated_input_text;
			}
			
			//re-enable the close button
			close_bt.disabled = false;
			close_bt.alpha = 1;
			close_bt.filters = null;
			
			draw();
		}
		
		private function onBackComplete():void {
			//put the scroller back
			if(!scroller_at_max){
				scroller.scrollYToTop(scroller_y_snapshot);
			}
			else {
				scroller.scrollDownToBottom();
			}
			
			//refresh the feed
			FeedManager.instance.refreshFeed(name);
		}
		
		private function onSpinnerLoad(event:Event):void {
			const spinner_holder:MovieClip = Loader(event.target.getChildAt(0)).content as MovieClip;
			
			if(spinner_holder && spinner_holder.numChildren && spinner_holder.getChildAt(0) is MovieClip){
				spinner = spinner_holder.getChildAt(0) as MovieClip;
				spinner.scaleX = spinner.scaleY = .7;
				spinner.x = _w - 43;
				spinner.y = -12;
				spinner.visible = show_loader;
				addChild(spinner);
			}
		}
		
		private function onRefreshClick(event:TSEvent):void {
			//refresh the feed, and if it returns false, play the farty failure sound
			if(!FeedManager.instance.refreshFeed(name)){
				SoundMaster.instance.playSound('CLICK_FAILURE');
			}
		}
		
		override protected function onInputFocus(event:TSEvent):void {
			//check if the text in there is the same as our pre-populated text
			if(input_field.text == populated_input_text){
				input_field.text = '';
			}
			
			super.onInputFocus(event);
		}
		
		override protected function onInputBlur(event:TSEvent):void {
			//if the input is empty populate it
			if(input_field.text == '' && populated_input_text){
				input_field.text = populated_input_text;
			}
			
			super.onInputBlur(event);
		}
		
		override public function setWidthHeight(w:int, h:int):void {
			super.setWidthHeight(w, h);
			if(element_width == -1){
				//set the width for everyone to share
				element_width = scroller.w - SCROLL_BAR_W - SCROLL_X_OFFSET;
				
				//setup the details
				details_ui = new FeedChatDetailsUI(element_width);
				details_ui.x = element_width - SCROLL_X_OFFSET + SCROLL_BAR_W;
				details_ui.addEventListener(TSEvent.CHANGED, onElementReply, false, 0, true);
				scroller.body.addChild(details_ui);
			}
		}
		
		public function get show_loader():Boolean { return _show_loader; }
		public function set show_loader(value:Boolean):void {
			if(spinner){
				spinner.visible = value;
				if(value){
					spinner.play();
				}
				else {
					spinner.stop();
				}
			}
			
			_show_loader = value;
			
			if(refresh_bt) refresh_bt.visible = !value;
		}
		
		public function get reply_id():String { return _reply_id; }
		
		override public function dispose():void {
			//any junk left over?
			if(back_bt) back_bt.removeEventListener(TSEvent.CHANGED, onBackClick);
			if(refresh_bt) refresh_bt.removeEventListener(TSEvent.CHANGED, onRefreshClick);
			if(spinner && spinner.parent){
				spinner.parent.removeChild(spinner);
				spinner = null;
			} 
			
			super.dispose();
		}
		
		/* We don't have a chat dropdown, but if we did, use this here
		override public function copyElements():void {	
		System.setClipboard(getElements());
		model.activityModel.activity_message = Activity.createFromCurrentPlayer('Updates copied to clipboard');
		}
		*/
	}
}