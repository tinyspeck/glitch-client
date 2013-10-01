package com.tinyspeck.engine.view.ui.chat
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.chat.FeedItem;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.text.TextFieldAutoSize;

	public final class FeedChatElement extends ChatElement
	{
		private static const HEAD_RADIUS:int = 14;
		private static const HEAD_PADD:uint = 5;
		private static const HEAD_SCALE:Number = .8;
		private static const EXTRA_HEAD_PADD:int = 8;
		private static const EXTRA_FOOT_PADD:int = 8;
		private static const THUMB_W:uint = 120;
		private static const THUMB_H:uint = 80;
		
		private var reply_bt:Button;
		private var current_item:FeedItem;
		
		private var name_tf:TSLinkedTextField = new TSLinkedTextField();
		private var date_tf:TSLinkedTextField = new TSLinkedTextField();
		private var replies_tf:TSLinkedTextField = new TSLinkedTextField();
		private var photo_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var head_holder:Sprite = new Sprite();
		private var head_mask:Sprite = new Sprite();
		private var photo_holder:Sprite = new Sprite();
		private var photo_mask:Sprite = new Sprite();
		private var photo_link_holder:Sprite = new Sprite();
		
		private var _is_details:Boolean;
		private var _show_full_avatar:Boolean;
		private var _extra_head_padd:Boolean;
		private var _extra_foot_padd:Boolean;
		private var showing_photo:Boolean;
		private var thumb_loading:Boolean;
		
		public function FeedChatElement(id:String, w:int, is_details:Boolean = false){
			name = id || 'REMOVE_ME';
			_w = w;
			this.is_details = is_details;
			
			//build out the reply button
			var reply_icon:DisplayObject = new AssetManager.instance.assets.feed_reply();
			reply_bt = new Button({
				name: 'reply',
				graphic: reply_icon,
				draw_alpha: 0,
				w: reply_icon.width,
				h: reply_icon.height
			});
			addChild(reply_bt);
			reply_bt.alpha = 0; //alpha so that the width prop includes button, .visible omits it
			reply_bt.x = _w - reply_bt.width - 17;
			
			addEventListener(MouseEvent.ROLL_OVER, onRollOver, false, 0, true);
			addEventListener(MouseEvent.ROLL_OUT, onRollOut, false, 0, true);
			addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			
			var g:Graphics = head_mask.graphics;
			g.beginFill(0,0);
			g.drawCircle(HEAD_RADIUS, HEAD_RADIUS, HEAD_RADIUS);
			addChild(head_mask);
			
			addChild(head_holder);
			
			//filter for the head holder
			head_holder.filters = StaticFilters.black3pxInner_GlowA;
			
			const x_offset:int = HEAD_RADIUS*2 + 7;
			
			//tfs
			TFUtil.prepTF(name_tf);
			name_tf.wordWrap = false; //so we can force a width later if it's too large
			name_tf.embedFonts = false;
			name_tf.x = x_offset;
			addChild(name_tf);
			
			tf = new TSLinkedTextField();
			TFUtil.prepTF(tf);
			tf.autoSize = TextFieldAutoSize.NONE;
			tf.embedFonts = false;
			tf.x = x_offset;
			tf.width = reply_bt.x + reply_bt.width - tf.x;
			addChild(tf);
			
			TFUtil.prepTF(date_tf, false);
			date_tf.embedFonts = false;
			date_tf.x = x_offset;
			addChild(date_tf);
			
			TFUtil.prepTF(replies_tf, false);
			replies_tf.embedFonts = false;
			addChild(replies_tf);
			
			//place the photo holder
			photo_holder.x = x_offset + 2;
			photo_holder.useHandCursor = photo_holder.buttonMode = true;
			photo_holder.mask = photo_mask;
			photo_mask.x = photo_holder.x;
			
			//photo text
			TFUtil.prepTF(photo_tf, false);
			photo_tf.embedFonts = false;
			photo_tf.htmlText = '<p class="feed_chat"><a class="feed_chat_photo" href="#">Uploaded a snapshot</a></p>';
			photo_link_holder.addChild(photo_tf);
			
			const camera_icon:DisplayObject = new AssetManager.instance.assets.camera_icon_small();
			camera_icon.x = int(photo_tf.width + 3);
			camera_icon.y = 3;
			photo_link_holder.addChild(camera_icon);
			photo_link_holder.x = x_offset;
			photo_link_holder.useHandCursor = photo_link_holder.buttonMode = true;
			photo_link_holder.mouseChildren = false;
			g = photo_link_holder.graphics;
			g.beginFill(0,0);
			g.drawRect(0, 0, photo_link_holder.width, photo_link_holder.height);
			
			//add the bg in there for our hover action
			const bg_drop:DropShadowFilter = new DropShadowFilter();
			bg_drop.blurX = 0;
			bg_drop.blurY = 14;
			bg_drop.inner = true;
			bg_drop.alpha = .12;
			bg_drop.distance = 0;
			
			bg = new Sprite();
			bg.filters = [bg_drop];
			bg.alpha = 0;
			addChildAt(bg, 0);
		}
		
		public function show(feed_item:FeedItem, show_reply_name:Boolean = true):void {			
			if(!feed_item || name == 'REMOVE_ME') {
				if(parent) parent.removeChild(this);
				CONFIG::debugging {
					Console.warn('There was a problem with this feed element. It has been removed!');
				}
				return;
			}
			
			current_item = feed_item;
			name = feed_item.id;
			_type = feed_item.type == FeedItem.TYPE_STATUS_REPLY ? TYPE_FEED_REPLY : TYPE_CHAT;
			_pc_tsid = feed_item.who_tsid;
			_unix_created_ts = feed_item.when;
			now = new Date();
			created = new Date();
			created.setTime(_unix_created_ts*1000);
			if(!current_item.photo_id) showing_photo = false;
			
			//if we are showing the avatar, axe the mask for now
			head_holder.mask = !show_full_avatar ? head_mask : null;
			
			const pc:PC = model.worldModel.getPCByTsid(_pc_tsid);
			
			if (pc) {
				//load the headshot
				if(head_holder.name != pc.tsid){
					SpriteUtil.clean(head_holder);
				}
				
				if (pc.singles_url){
					head_holder.name = pc.tsid;
					AssetManager.instance.loadBitmapFromWeb(pc.singles_url+'_50.png', onHeadshotLoad, 'updates panel');
				} else {
					CONFIG::debugging {
						Console.warn(pc.tsid+' does not have a singles_url');
					}
				}
			} else {
				CONFIG::debugging {
					Console.error(' no pc?');
				}
			}
			
			//setup the player name
			var player_names:String = '<p class="feed_chat">';
				player_names += (show_full_avatar ? '<span class="feed_chat_featured_name">' : '')+getPlayerName(feed_item.who_tsid, feed_item.who_name);
				player_names += (show_reply_name && feed_item.in_reply_to ? '&nbsp;to&nbsp;'+getPlayerName(feed_item.in_reply_to.who_tsid, feed_item.in_reply_to.who_name, feed_item.who_tsid) : '');
				player_names += (show_full_avatar ? '</span>' : '');
				player_names += '</p>';
				
			name_tf.htmlText = player_names;
			
			//we have a photo to show?
			if(feed_item.photo_id){
				SpriteUtil.clean(photo_holder);
				
				thumb_loading = true;
				AssetManager.instance.loadBitmapFromWeb(feed_item.thumb_url, onThumbLoad, 'Feed thumbnail');
				
				addChild(photo_holder);
				addChild(photo_mask);
				addChild(photo_link_holder);
				
				//draw a placeholder
				const g:Graphics = photo_holder.graphics;
				g.beginFill(0, .07);
				g.drawRect(0, 0, THUMB_W, THUMB_H);
			}
			else if(photo_link_holder.parent){
				photo_link_holder.parent.removeChild(photo_link_holder);
				if(photo_holder.parent) photo_holder.parent.removeChild(photo_holder);
				if(photo_mask.parent) photo_mask.parent.removeChild(photo_mask);
			}
			
			//setup the body
			var txt:String = StringUtil.encodeHTMLUnsafeChars(feed_item.txt);
			txt = StringUtil.linkify(txt, 'chat_element_url');
			
			//if we are parsing a special type of link sent from the client, handle that
			txt = RightSideManager.instance.parseClientLink(txt);
			
			tf.htmlText = '<p class="feed_chat">'+(show_full_avatar ? '<span class="feed_chat_featured_body">' : '')+txt+(show_full_avatar ? '</span>' : '')+'</p>';
			
			//the date
			//date_tf.htmlText = '<p class="feed_chat"><a href="event:" class="feed_chat_date">'+StringUtil.getMonthFromDate(created)+'. '+created.getDate()+'</a></p>';
			date_tf.htmlText = '<p class="feed_chat"><a href="event:" class="feed_chat_date">'+ StringUtil.getTimeFromUnixTimestamp(unix_timestamp, false, (created.date == now.date && created.month == now.month))+'</a></p>';
			
			//replies
			replies_tf.text = '';
			if(feed_item.replies){
				replies_tf.htmlText = '<p class="feed_chat"><a href="event:" class="feed_chat_replies">Replies ('+StringUtil.formatNumberWithCommas(feed_item.replies)+')</a></p>';
			}
			
			draw();
			
			//get the hit area setup
			onRollOut();
		}
		
		override protected function draw():void {
			const max_name_w:int = reply_bt.x - 3 - name_tf.x;
			var g:Graphics;
			
			//move the head holder if need be
			head_holder.y = HEAD_PADD + (extra_head_padd ? EXTRA_HEAD_PADD : 0);
			head_mask.y = head_holder.y;
			reply_bt.y = head_holder.y;
			
			//handle TF heights
			var next_y:int = HEAD_PADD - 2 + (extra_head_padd ? EXTRA_HEAD_PADD : 0);
			name_tf.y = next_y;
			if(name_tf.width > max_name_w){
				name_tf.autoSize = TextFieldAutoSize.NONE;
				name_tf.width = max_name_w;
				name_tf.height = name_tf.textHeight + chat_leading;
			}
			next_y += name_tf.height - (name_tf.width > max_name_w ? 6 : 4);
			
			//a photo maybe
			if(current_item.photo_id){
				photo_holder.y = next_y + 4;
				photo_mask.y = photo_holder.y;
				photo_link_holder.y = next_y + 2 + (!showing_photo ? 0 : THUMB_H + 4);
				
				//handle displaying the photo
				if(showing_photo && !photo_holder.parent){
					addChild(photo_holder);
					addChild(photo_mask);
				}
				else if(!showing_photo && photo_holder.parent){
					removeChild(photo_holder);
					removeChild(photo_mask);
				}
				
				//draw the mask
				g = photo_mask.graphics;
				g.clear();
				g.beginFill(0,0);
				g.drawRoundRect(0, 0, THUMB_W, photo_link_holder.y - next_y - (!showing_photo ? 2 : 6), 10);
				
				//reset next_y for animation purposes
				next_y = photo_link_holder.y + photo_link_holder.height - 1;
			}
			
			//body
			tf.y = next_y;
			tf.height = tf.textHeight + chat_leading;
			next_y += tf.height - 4;			
			
			//move date/replies
			date_tf.y = next_y;
			replies_tf.x = reply_bt.x + reply_bt.width - replies_tf.width;
			replies_tf.y = date_tf.y;
			replies_tf.visible = !show_full_avatar;
			
			//draw the bg box and bottom line
			g = graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRect(0, 0, _w, height);
			g.endFill();
			g.beginFill(0xd6d6d6);
			g.drawRect(0, height-1, _w, 1);
			
			//draw the head circle
			g = head_holder.graphics;
			g.clear();
			if(!show_full_avatar){
				g.beginFill(0xe9f0f0);
				g.drawCircle(HEAD_RADIUS, HEAD_RADIUS, HEAD_RADIUS);
			}
			
			//draw the bg for hovering
			g = bg.graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRect(0, 0, _w, height-1);
		}
		
		private function onRollOver(event:MouseEvent = null):void {
			const is_photo:Boolean = current_item && current_item.photo_id != null;
			
			bg.alpha = 1;
			reply_bt.alpha = !is_photo ? 1 : 0;
			reply_bt.disabled = !is_photo ? false : true;
			useHandCursor = buttonMode = !is_photo;
		}
		
		private function onRollOut(event:MouseEvent = null):void {
			bg.alpha = 0;
			reply_bt.alpha = 0;
		}
		
		private function onClick(event:MouseEvent):void {
			const is_photo:Boolean = current_item.photo_id != null;
			
			switch(event.target){
				case reply_bt:
					if(!reply_bt.disabled && !is_photo){
						dispatchEvent(new TSEvent(TSEvent.CHANGED, name));
					}
					break;
				case date_tf:
					//open perma link
					if(!is_photo){
						const chunks:Array = name.split('-');
						const id:String = chunks.length > 1 ? chunks[1] : chunks[0];
						TSFrontController.instance.openStatusPage(null, pc_tsid, id);
					}
					else {
						//open the snap page
						TSFrontController.instance.openSnapPage(null, current_item.url);
					}
					break;
				case name_tf:
					//nuffin
					break;
				case photo_holder:
					//open the snap page
					TSFrontController.instance.openSnapPage(null, current_item.url);
					break;
				case photo_link_holder:
					//toggle the snap showing
					//we can't animate this because the client cries redrawing all the updates to accomodate the height changes
					if(!photo_holder.numChildren && !thumb_loading){
						//try loading this again
						thumb_loading = true;
						AssetManager.instance.loadBitmapFromWeb(current_item.thumb_url, onThumbLoad, 'Feed thumbnail');
					}
					showing_photo = !showing_photo;
					draw();
					const chat_area:FeedChatArea = RightSideManager.instance.right_view.getChatArea(ChatArea.NAME_UPDATE_FEED) as FeedChatArea;
					if(chat_area) chat_area.refreshElements();
					break;
				default:
					if(!is_photo){
						//we don't allow deep links for photos until the server passes comments into the main feed
						dispatchEvent(new TSEvent(TSEvent.ACTIVITY_HAPPENED, name));
					}
					break;
			}
		}
		
		private function onHeadshotLoad(filename:String, bm:Bitmap):void {
			if(bm){
				bm.scaleX = -HEAD_SCALE;
				bm.scaleY = HEAD_SCALE;
				bm.x = bm.width - 10;
				bm.smoothing = true;
				bm.y = -8;
				head_holder.addChild(bm);
			}
			else {
				CONFIG::debugging {
					Console.warn('Could not load the avatar headshot!');
				}
			}
		}
		
		private function onThumbLoad(filename:String, bm:Bitmap):void {
			//add it to the photo holder
			SpriteUtil.clean(photo_holder);
			
			if(bm){
				photo_holder.addChild(bm);
				draw();
			}
			else {
				CONFIG::debugging {
					Console.warn('Could not load the snap!', current_item ? current_item.thumb_url : 'current_item is null?!');
				}
				
				//draw a placeholder
				const g:Graphics = photo_holder.graphics;
				g.beginFill(0, .07);
				g.drawRect(0, 0, THUMB_W, THUMB_H);
			}
			
			thumb_loading = false;
		}
		
		private function getPlayerName(tsid:String, label:String, parent_tsid:String = null):String {
			var player_name:String;
			
			if(model.worldModel.pc.tsid != tsid){
				player_name = '<a href="event:'+TSLinkedTextField.LINK_PC+'|'+tsid+'" class="'+RightSideManager.instance.getPCCSSClass(tsid)+'">'+
				StringUtil.encodeHTMLUnsafeChars(label)+
				'</a>';
			}
			else {
				var your_label:String = parent_tsid ? 'you' : 'You';
				if(parent_tsid && parent_tsid == model.worldModel.pc.tsid) your_label = 'yourself';
				player_name = '<font color="'+RightSideManager.instance.getPCColorHex(tsid)+'">'+your_label+'</font>';
			}
			
			return '<b>'+player_name+'</b>';
		}
		
		override public function dispose():void {
			SpriteUtil.clean(head_holder);
			SpriteUtil.clean(photo_holder);
			showing_photo = false;
			super.dispose();
		}
		
		override public function get height():Number {
			return Math.max(HEAD_PADD*2 + HEAD_RADIUS*2, date_tf.y + date_tf.height + 4 + (extra_foot_padd ? EXTRA_FOOT_PADD : 0));
		}
		
		public function get is_details():Boolean { return _is_details; }
		public function set is_details(value:Boolean):void {
			_is_details = value;
		}
		
		public function get show_full_avatar():Boolean { return _show_full_avatar; }
		public function set show_full_avatar(value:Boolean):void {
			_show_full_avatar = value;
		}
		
		public function get extra_head_padd():Boolean { return _extra_head_padd; }
		public function set extra_head_padd(value:Boolean):void {
			_extra_head_padd = value;
		}
		
		public function get extra_foot_padd():Boolean { return _extra_foot_padd; }
		public function set extra_foot_padd(value:Boolean):void {
			_extra_foot_padd = value;
		}
	}
}