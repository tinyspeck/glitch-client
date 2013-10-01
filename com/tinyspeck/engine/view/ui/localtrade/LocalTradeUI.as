package com.tinyspeck.engine.view.ui.localtrade
{
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.TradeManager;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.text.TextField;

	public class LocalTradeUI extends TSSpriteWithModel
	{
		protected static const MAX_TITLE_CHARS:uint = 25;
		protected static const HEADER_H:uint = 32;
		protected static const CHOICE_PADD:uint = 15;
		protected static const PADD:uint = 10;
		protected static const TOGGLE_PADD:uint = 4;
		
		protected var bg_color:uint = 0xffffff;
		protected var border_color:uint = 0x333e43;
		protected var border_width:int = -1;
		protected var body_bg_color:uint = 0xececec;
		protected var body_border_color:uint = 0xd2d2d2;
		protected var body_border_width:int = -1;
		protected var body_h:int;
		
		protected var choice_buy_bt:Button;
		protected var choice_sell_bt:Button;
		protected var buy_sell_ui:LocalTradeBuySellUI = new LocalTradeBuySellUI();
		
		protected var holder_glow:GlowFilter;
		protected var holder_drop:DropShadowFilter;
		
		protected var holder:Sprite = new Sprite();
		protected var body_holder:Sprite = new Sprite();
		protected var close_holder:Sprite = new Sprite();
		protected var choice_holder:Sprite = new Sprite();
		protected var toggle_holder:Sprite = new Sprite();
		
		protected var title_tf:TextField = new TextField();
		protected var want_buy_tf:TextField = new TextField();
		protected var want_sell_tf:TextField = new TextField();
		
		public function LocalTradeUI(){
			//setup the CSS
			const cssm:CSSManager = CSSManager.instance;
			bg_color = cssm.getUintColorValueFromStyle('local_trade', 'backgroundColor', bg_color);
			border_color = cssm.getUintColorValueFromStyle('local_trade', 'borderColor', border_color);
			border_width = cssm.getNumberValueFromStyle('local_trade', 'borderWidth', border_width);
			body_bg_color = cssm.getUintColorValueFromStyle('local_trade_body', 'backgroundColor', body_bg_color);
			body_border_color = cssm.getUintColorValueFromStyle('local_trade_body', 'borderColor', body_border_color);
			body_border_width = cssm.getNumberValueFromStyle('local_trade_body', 'borderWidth', body_border_width);
			
			//filters
			holder_glow = new GlowFilter();
			holder_glow.color = border_color;
			holder_glow.alpha = 1;
			holder_glow.strength = 3;
			holder_glow.blurX = holder_glow.blurY = border_width+1; //to get it to show 1px, the blur needs to be 2
			
			holder_drop = new DropShadowFilter();
			holder_drop.angle = 90;
			holder_drop.alpha = .15;
			holder_drop.distance = 2;
			holder_drop.blurX = 2;
			holder_drop.blurY = 2;
			
			holder.filters = [holder_glow, holder_drop];
			addChild(holder);
			
			const icon:DisplayObject = new AssetManager.instance.assets.trade_icon_small();
			icon.x = 5;
			icon.y = int(HEADER_H/2 - icon.height/2 + border_width);
			holder.addChild(icon);
			
			TFUtil.prepTF(title_tf, false);
			title = 'placeholder';
			title_tf.x = icon.x + icon.width + 5;
			title_tf.y = int(HEADER_H/2 - title_tf.height/2 + border_width);
			holder.addChild(title_tf);
			
			//body
			body_holder.y = HEADER_H;
			holder.addChild(body_holder);
			
			//close
			close_holder.addChild(new AssetManager.instance.assets.chat_close());
			close_holder.y = int(HEADER_H/2 - close_holder.height/2 + border_width);
			close_holder.useHandCursor = close_holder.buttonMode = true;
			close_holder.addEventListener(MouseEvent.CLICK, onCloseClick, false, 0, true);
			holder.addChild(close_holder);
			
			//toggle
			const arrow:DisplayObject = new AssetManager.instance.assets.back_arrow();
			SpriteUtil.setRegistrationPoint(arrow);
			toggle_holder.addChild(arrow);
			toggle_holder.useHandCursor = toggle_holder.buttonMode = true;
			toggle_holder.addEventListener(MouseEvent.CLICK, onToggleClick, false, 0, true);
			holder.addChild(toggle_holder);
			
			var g:Graphics = toggle_holder.graphics;
			g.beginFill(0,0);
			g.drawRect(arrow.x-TOGGLE_PADD, arrow.y-TOGGLE_PADD, arrow.width+TOGGLE_PADD*2, arrow.height+TOGGLE_PADD*2);
			
			//choices			
			TFUtil.prepTF(want_buy_tf, false);
			want_buy_tf.htmlText = '<p class="local_trade_want">I want to</p>';
			want_buy_tf.y = CHOICE_PADD - 2;
			choice_holder.addChild(want_buy_tf);
			
			TFUtil.prepTF(want_sell_tf, false);
			want_sell_tf.htmlText = '<p class="local_trade_want">I want to</p>';
			want_sell_tf.y = want_buy_tf.y;
			choice_holder.addChild(want_sell_tf);
			
			choice_buy_bt = new Button({
				name: 'choice_buy',
				label: 'Buy something',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			choice_buy_bt.y = int(want_buy_tf.y + want_buy_tf.height + 2);
			choice_buy_bt.addEventListener(TSEvent.CHANGED, onBuyClick, false, 0, true);
			choice_holder.addChild(choice_buy_bt);
			
			choice_sell_bt = new Button({
				name: 'choice_sell',
				label: 'Sell something',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			choice_sell_bt.y = choice_buy_bt.y;
			choice_sell_bt.addEventListener(TSEvent.CHANGED, onSellClick, false, 0, true);
			choice_holder.addChild(choice_sell_bt);
			
			body_holder.addChild(choice_holder);
			
			//buy/sell
			buy_sell_ui.x = PADD;
			buy_sell_ui.y = PADD - 4;
			buy_sell_ui.addEventListener(TSEvent.CHANGED, draw, false, 0, true);
			buy_sell_ui.addEventListener(TSEvent.ACTIVITY_HAPPENED, onBuySellAnnounce, false, 0, true);
			buy_sell_ui.addEventListener(TSEvent.CLOSE, onBuyClose, false, 0, true);
			body_holder.addChild(buy_sell_ui);
			
			hide();
		}
		
		public function show():void {
			title = 'Make a trade offer';
			body_holder.visible = true;
			close_holder.visible = true;
			choice_holder.visible = true;
			toggle_holder.visible = false;
			buy_sell_ui.hide();
			
			visible = true;
			
			jigger();
			
			//listen to action requests that are of the "trade" type
			RightSideManager.instance.addEventListener(TSEvent.ACTION_REQUEST_CANCEL, hide, false, 0, true);
		}
		
		public function edit():void {
			if(!visible) return;
			
			//open it if it's not already open
			choice_holder.visible = false;
			toggle_holder.visible = true;
			if(toggle_holder.scaleY == -1) onToggleClick();
		}
		
		public function hide(event:TSEvent = null):void {			
			if(event && event.data != TSLinkedTextField.LINK_TRADE) {
				//this wasn't a trade cancel, bail out
				return;
			}
			
			visible = false;
			RightSideManager.instance.removeEventListener(TSEvent.ACTION_REQUEST_CANCEL, hide);
			dispatchEvent(new TSEvent(TSEvent.CHANGED));
		}
		
		protected function draw(event:Event = null):void {
			var g:Graphics;
			
			//choices
			g = choice_holder.graphics;
			g.clear();
			g.beginFill(body_border_color);
			g.drawRect(int(_w/2), 0, body_border_width, int(choice_holder.height + CHOICE_PADD*2));
			
			body_h = choice_holder.visible ? int(choice_holder.height) : int(buy_sell_ui.height);
			if(buy_sell_ui.visible) body_h += CHOICE_PADD;
			
			//body
			g = body_holder.graphics;
			g.clear();
			g.beginFill(body_bg_color);
			g.drawRoundRectComplex(0, 0, _w, body_h, 0, 0, 3, 3);
			g.beginFill(body_border_color);
			g.drawRect(0, 0, _w, body_border_width);
			
			//handle the background
			g = holder.graphics;
			g.clear();
			g.beginFill(bg_color);
			g.drawRoundRect(0, 0, _w, HEADER_H + body_h, 6);
			
			jigger();
		}
		
		protected function jigger():void {
			//close button
			close_holder.x = int(_w - close_holder.width - 10);
			
			//toggle button
			toggle_holder.x = int(close_holder.x + toggle_holder.width/2 - TOGGLE_PADD);
			
			//choices
			want_buy_tf.x = int(_w/2 + (_w/4 - want_buy_tf.width/2));
			choice_buy_bt.w = int(_w/2 - CHOICE_PADD*2);
			choice_buy_bt.x = int(_w/2 + CHOICE_PADD);
			want_sell_tf.x = int(_w/4 - want_sell_tf.width/2);
			choice_sell_bt.w = int(_w/2 - CHOICE_PADD*2);
			choice_sell_bt.x = CHOICE_PADD;
			
			dispatchEvent(new TSEvent(TSEvent.CHANGED));
		}
		
		protected function onBuyClick(event:TSEvent = null):void {
			//show the buy UI
			choice_holder.visible = false;
			buy_sell_ui.show(_w - PADD*2, true);
		}
		
		protected function onSellClick(event:TSEvent = null):void {
			//show the sell UI
			choice_holder.visible = false;
			buy_sell_ui.show(_w - PADD*2, false);
		}
		
		protected function onBuySellAnnounce(event:TSEvent):void {			
			//fire off the request to the server to start buying/selling this stuff
			if(buy_sell_ui.item_tsid) {
				TradeManager.instance.localAnnounce(
					buy_sell_ui.is_buy, 
					buy_sell_ui.is_buy ? buy_sell_ui.item_tsid : buy_sell_ui.itemstack_tsid, 
					buy_sell_ui.count, 
					buy_sell_ui.currants,
					onAnnounceResponse
				);
			}
		}
		
		protected function onBuyClose(event:TSEvent):void {
			//same as clicking on the X
			onCloseClick();
		}
		
		protected function onAnnounceResponse(nrm:NetResponseMessageVO):void {
			//set the title and hide the UI
			buy_sell_ui.announceResult(nrm.success);
			if(!nrm.success) return;
			
			const item:Item = buy_sell_ui.item_tsid ? model.worldModel.getItemByTsid(buy_sell_ui.item_tsid) : null;
			if(item){
				title = (buy_sell_ui.is_buy ? 'Buying ' : 'Selling ')+(buy_sell_ui.count != 1 ? item.label_plural : StringUtil.aOrAn(item.label)+' '+item.label);
				
				//hide the body and close button and show the edit arrow
				close_holder.visible = false;
				toggle_holder.visible = true;
				toggle_holder.scaleY = 1;
				onToggleClick();
				
				//how much we are willing to pay
				TradeManager.instance.currants = buy_sell_ui.is_buy ? buy_sell_ui.currants : 0;
				
				//set the item and count so they are ready for when someone accepts our trade
				if(!buy_sell_ui.is_buy){
					TradeManager.instance.item_tsid = buy_sell_ui.item_tsid;
					TradeManager.instance.item_count = buy_sell_ui.count;
					TradeManager.instance.itemstack_tsid = buy_sell_ui.itemstack_tsid;
				}
			}
		}
		
		protected function onCloseClick(event:MouseEvent = null):void {			
			//tell the server to cancel the request
			hide();
			TradeManager.instance.localUpdate(true);
		}
		
		protected function onToggleClick(event:MouseEvent = null):void {
			const t_scale:int = toggle_holder.scaleY == -1 ? 1 : -1;
			const is_open:Boolean = t_scale == 1;
			toggle_holder.scaleY = t_scale;
			toggle_holder.y = int(HEADER_H/2 - (is_open ? 1 : 0));
			body_holder.visible = is_open;
			
			if(is_open){
				//edit the details
				buy_sell_ui.edit();
				title = 'Edit your trade details';
			}
			else {
				//hide the ui
				buy_sell_ui.hide();
				
				//show the proper title
				const item:Item = buy_sell_ui.item_tsid ? model.worldModel.getItemByTsid(buy_sell_ui.item_tsid) : null;
				if(item) title = (buy_sell_ui.is_buy ? 'Buying ' : 'Selling ')+(buy_sell_ui.count != 1 ? item.label_plural : StringUtil.aOrAn(item.label)+' '+item.label);
			}
		}
		
		public function set title(value:String):void {
			title_tf.htmlText = '<p class="local_trade_title">'+StringUtil.truncate(value, MAX_TITLE_CHARS)+'</p>';
		}
		
		public function set w(value:int):void { _w = value; }
		
		override public function get height():Number {
			return HEADER_H + body_h;
		}
	}
}