package com.tinyspeck.engine.view.ui.mail
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.FurnitureConfig;
	import com.tinyspeck.engine.data.mail.MailMessage;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.MailManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class MailInboxElementUI extends TSSpriteWithModel implements ITipProvider
	{		
		private static const ICON_WH:uint = 28;
		private static const HEIGHT:uint = 53;
		private static const PADD:uint = 10;
		private static const MESSAGE_MAX_CHARS:uint = 35;
		private static const READ_RADIUS:uint = 5;
		
		private static var hover_border_color:int = -1;
		private static var hover_color:int = -1;
		private static var border_color:int = -1;
		private static var bg_color:int = -1;
		
		private var sender_tf:TextField = new TextField();
		private var time_tf:TextField = new TextField();
		private var item_count_tf:TextField;
		
		private var item_attached:Sprite;
		private var currants_attached:Sprite;
		private var hover:Sprite = new Sprite();
		private var read_holder:Sprite = new Sprite();
		private var read_indicator:Sprite = new Sprite();
		private var trash_icon:Sprite = new Sprite();
		private var replied_icon:Sprite = new Sprite();
				
		private var item:Item;
		
		private var _message_id:String;
		
		public function MailInboxElementUI(w:int){
			_w = w;
			
			buttonMode = useHandCursor = true;
			
			//sender
			TFUtil.prepTF(sender_tf);
			sender_tf.x = MailInboxHeaderUI.SENDER_X;
			sender_tf.width = MailInboxHeaderUI.ATTACHED_X - MailInboxHeaderUI.SENDER_X;
			sender_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			sender_tf.mouseEnabled = false;
			addChild(sender_tf);
			
			//time
			TFUtil.prepTF(time_tf);
			time_tf.width = _w - MailInboxHeaderUI.RECEIVED_X - 20;
			time_tf.x = _w - time_tf.width - 30;
			time_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			time_tf.mouseEnabled = false;
			addChild(time_tf);
			
			//colors
			if(hover_border_color == -1){
				hover_border_color = CSSManager.instance.getUintColorValueFromStyle('mail_inbox_hover', 'borderColor', 0xcecece);
				hover_color = CSSManager.instance.getUintColorValueFromStyle('mail_inbox_hover', 'backgroundColor', 0xdfdfdf);
				border_color = CSSManager.instance.getUintColorValueFromStyle('mail_inbox_element', 'borderColor', 0xdbdbdb);
				bg_color = CSSManager.instance.getUintColorValueFromStyle('mail_inbox_element', 'backgroundColor', 0xececec);
			}
			
			//read indicator
			var g:Graphics = read_holder.graphics;
			g.beginFill(0,0);
			g.drawRect(0, 0, MailInboxHeaderUI.SENDER_X, HEIGHT);
			addChild(read_holder);
			
			//reply indicator
			var replied:DisplayObject = new AssetManager.instance.assets.mail_replied();
			if(replied){
				replied_icon.addChild(replied);
				replied_icon.x = MailInboxHeaderUI.READ_X - READ_RADIUS;
				replied_icon.y = int(HEIGHT/2-replied.height/2);
			}
			
			read_holder.addChild(replied_icon);
			
			var trash:DisplayObject = new AssetManager.instance.assets.mail_trash();
			if(trash){
				trash_icon.addChild(trash);
				trash_icon.x = MailInboxHeaderUI.READ_X - trash.width - READ_RADIUS*2;
				trash_icon.y = int(HEIGHT/2-trash.height/2);
			}
			
			trash_icon.visible = false;
			read_holder.addChild(trash_icon);
			
			read_holder.addEventListener(MouseEvent.ROLL_OVER, onReadOver, false, 0, true);
			read_holder.addEventListener(MouseEvent.ROLL_OUT, onReadOut, false, 0, true);
			
			//hover
			hover.alpha = 0;
			addChildAt(hover, 0);
			
			//listeners
			addEventListener(MouseEvent.ROLL_OVER, onRollOver, false, 0, true);
			addEventListener(MouseEvent.ROLL_OUT, onRollOut, false, 0, true);
			addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
		}
		
		public function show(message:MailMessage, is_first:Boolean = false):void {
			_message_id = message.message_id;
						
			//set the sender
			const pc:PC = message.sender_tsid ? model.worldModel.getPCByTsid(message.sender_tsid) : null;
			var sender_txt:String = pc ? pc.label : 'G.I.G.P.D.S.';
			
			//set the message
			var message_txt:String = message.text 
									? StringUtil.truncate(StringUtil.replaceNewLineWithSomething(StringUtil.stripHTML(message.text)), MESSAGE_MAX_CHARS) 
									: '&lt;no message&gt;';
			if(!message.is_read) message_txt = '<b>'+message_txt+'</b>';
			message_txt = '<span class="mail_inbox_text">'+message_txt+'</span>';
			
			const vag_ok:Boolean = StringUtil.VagCanRender(sender_txt);
			if(!vag_ok){
				sender_txt = '<font face="Arial">'+sender_txt+'</font>';
				message_txt = '<font face="Arial">'+message_txt+'</font>';
			}
			
			sender_tf.embedFonts = vag_ok;
			sender_tf.htmlText = '<p class="mail_inbox_sender">'+sender_txt+'<br>'+message_txt+'</p>';
			sender_tf.y = int((HEIGHT-sender_tf.height)/2) + 1;
			
			//check for attachments
			trash_icon.name = 'Delete message';
			if(message.item){
				item = model.worldModel.getItemByTsid(message.item.class_tsid);
				buildItem(message.item.class_tsid, message.item.count, message.item.config, message.item.is_broken);
				item_attached.visible = true;
				if(item){
					item_attached.name = message.item.count+' '+(message.item.count != 1 ? item.label_plural : item.label);
				}
				trash_icon.name = 'You still have attachments!';
			}
			else if(item_attached){
				item_attached.visible = false;
			}
			
			//check for currants
			if(message.currants){
				buildCurrants();
				currants_attached.visible = true;
				currants_attached.name = StringUtil.formatNumberWithCommas(message.currants)+' '+(message.currants != 1 ? 'Currants' : 'Currant');
				trash_icon.name = 'You still have attachments!';
			}
			else if(currants_attached){
				currants_attached.visible = false;
			}
			
			//set the X for the attachments when they are both showing
			if(currants_attached && item_attached && currants_attached.visible && item_attached.visible){
				currants_attached.x = int(MailInboxHeaderUI.ATTACHED_X - currants_attached.width - 2);
				item_attached.x = int(MailInboxHeaderUI.ATTACHED_X + 2);
			}
			
			//set the received time
			time_tf.visible = false;
			if(message.received){
				time_tf.htmlText = '<p class="mail_inbox_time">'+StringUtil.getTimeFromUnixTimestamp(message.received, false, false)+'</p>';
				time_tf.y = int(HEIGHT/2 - time_tf.height/2);
				time_tf.visible = true;
			}
			
			//draw
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(bg_color);
			g.drawRect(0, 0, _w, HEIGHT);
			g.beginFill(border_color);
			if(!is_first) g.drawRect(0, 0, _w, 1);
			g.drawRect(0, HEIGHT-1, _w, 1);
			
			//hover
			g = hover.graphics;
			g.clear();
			g.beginFill(hover_color);
			g.drawRect(0, 0, _w, HEIGHT);
			g.beginFill(hover_border_color);
			if(!is_first) g.drawRect(0, 0, _w, 1);
			g.drawRect(0, HEIGHT-1, _w, 1);
			
			//have they replied?
			replied_icon.visible = message.replied > 0;
			if(message.replied){
				replied_icon.name = 'You replied on '+StringUtil.getTimeFromUnixTimestamp(message.replied, false, false);
			}
			
			visible = true;
			
			if(item_attached) TipDisplayManager.instance.registerTipTrigger(item_attached);
			if(currants_attached) TipDisplayManager.instance.registerTipTrigger(currants_attached);
			TipDisplayManager.instance.registerTipTrigger(trash_icon);
			TipDisplayManager.instance.registerTipTrigger(replied_icon);
		}
		
		public function hide():void {
			visible = false;
			
			if(item_attached) TipDisplayManager.instance.unRegisterTipTrigger(item_attached);
			if(currants_attached) TipDisplayManager.instance.unRegisterTipTrigger(currants_attached);
			TipDisplayManager.instance.unRegisterTipTrigger(trash_icon);
			TipDisplayManager.instance.unRegisterTipTrigger(replied_icon);
		}
		
		private function buildCurrants():void {
			if(!currants_attached){
				currants_attached = new Sprite();
				var currants_icon:DisplayObject = new AssetManager.instance.assets.mail_currants();
				if(currants_icon){
					currants_attached.addChild(currants_icon);
					currants_attached.y = int((HEIGHT-currants_icon.height)/2);
				}		
				
				currants_attached.x = int(MailInboxHeaderUI.ATTACHED_X - currants_attached.width/2);
				addChild(currants_attached);
			}
		}
		
		private function buildItem(class_tsid:String, count:int, config:Object, is_broken:Boolean):void {
			if(!item_attached){
				item_attached = new Sprite();
				item_count_tf = new TextField();
				TFUtil.prepTF(item_count_tf);
				item_count_tf.width = ICON_WH;
				item_count_tf.mouseEnabled = false;
				item_attached.addChild(item_count_tf);
				addChild(item_attached);
			} 
			SpriteUtil.clean(item_attached, true, 1);

			var furn_config:FurnitureConfig = (config && config.furniture) ? FurnitureConfig.fromAnonymous(config.furniture, '') : null;
			var icon_state:String = (is_broken) ? 'broken_iconic' : 'iconic';
			var iiv:ItemIconView = new ItemIconView(class_tsid, ICON_WH, {state:icon_state, config:furn_config});
			
			if(iiv) item_attached.addChild(iiv);
			
			item_count_tf.y = count > 1 ? ICON_WH - 2: 0;
			item_count_tf.visible = count > 1;
			item_count_tf.htmlText = '<p class="mail_inbox_item_count">'+count+'</p>';
			
			item_attached.x = int(MailInboxHeaderUI.ATTACHED_X - item_attached.width/2);
			item_attached.y = int((HEIGHT-item_attached.height)/2);
		}
		
		private function onRollOver(event:MouseEvent):void {
			TSTweener.addTween(hover, {alpha:1, time:.1, transition:'linear'});
			if(parent) parent.setChildIndex(this, parent.numChildren-1);
		}
		
		private function onRollOut(event:MouseEvent):void {
			TSTweener.addTween(hover, {alpha:0, time:.2, transition:'linear'});
		}
		
		private function onClick(event:MouseEvent):void {						
			if(event.target == read_indicator || event.target == read_holder) {
				onReadClick(event);
			}
			else if(event.target == trash_icon) {
				if(!has_attachments){
					onRollOut(event);
					onReadOut(event);
					onDeleteClick(event);
				}
			}
			//send the message ID to whoever is listening
			else {
				onRollOut(event);
				onReadOut(event);
				dispatchEvent(new TSEvent(TSEvent.CHANGED, message_id));
			}
		}
		
		private function onReadOver(event:MouseEvent):void {
			trash_icon.visible = true;
			trash_icon.alpha = 0;
			TSTweener.addTween(trash_icon, {alpha:1, time:.1, transition:'linear'});
		}
		
		private function onReadOut(event:MouseEvent):void {
			TSTweener.addTween(trash_icon, {alpha:0, time:.1, transition:'linear', 
				onComplete:function():void { 
					trash_icon.visible = false;
				}
			});
		}
		
		private function onReadClick(event:MouseEvent):void {
			MailManager.instance.read([message_id], read_indicator.name.indexOf('un-read') != -1);
		}
		
		private function onDeleteClick(event:MouseEvent):void {			
			//confirm before deleting
			TSFrontController.instance.confirm(
				new ConfirmationDialogVO(
					onDeleteConfirm,
					'Are you sure you want to delete this message?',
					[
						{value: false, label: 'Never mind'},
						{value: true, label: 'Yes, I\'d like to delete it'}
					],
					false
				)
			);
		}
		
		private function onDeleteConfirm(value:*):void {
			if(value === true){
				MailManager.instance.remove([message_id]);
			}
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target) return null;
			
			return {
				txt: tip_target.name,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER	
			}
		}
		
		public function get message_id():String { return _message_id; }
		public function get has_attachments():Boolean {
			if(currants_attached && currants_attached.visible) return true;
			if(item_attached && item_attached.visible) return true;
			return false;
		}
	}
}