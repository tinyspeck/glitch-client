package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.SDBItemInfo;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingHousesVisitVO;
	import com.tinyspeck.engine.port.CurrencyInput;
	import com.tinyspeck.engine.port.GetInfoDialog;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class ItemSaleUI extends Sprite
	{
		private static const HEIGHT:uint = 60;
		private static const PADD:uint = 12;
		
		private var cost_tf:TextField = new TextField();
		private var name_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var text_holder:Sprite = new Sprite();
		
		private var teleport_bt:Button;
		private var current_info:SDBItemInfo;
		
		private var w:int;
		
		private var is_built:Boolean;
		
		public function ItemSaleUI(w:int){
			this.w = w;
		}
		
		private function buildBase():void {
			teleport_bt = new Button({
				name: 'teleport',
				label: 'Visit Home Street',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			teleport_bt.x = int(w - teleport_bt.width - PADD*2);
			teleport_bt.y = int(HEIGHT/2 - teleport_bt.height/2 - 1);
			teleport_bt.addEventListener(TSEvent.CHANGED, onTeleportClick, false, 0, true);
			addChild(teleport_bt);
			
			TFUtil.prepTF(cost_tf);
			cost_tf.x = PADD;
			cost_tf.width = teleport_bt.x - cost_tf.x - 10;
			text_holder.addChild(cost_tf);
			
			TFUtil.prepTF(name_tf);
			name_tf.x = cost_tf.x;
			name_tf.width = cost_tf.width;
			name_tf.cacheAsBitmap = true;
			text_holder.addChild(name_tf);
			
			addChild(text_holder);
			
			is_built = true;
		}
		
		public function show(item_info:SDBItemInfo, show_bg:Boolean, is_last:Boolean = false):void {
			if(!item_info) return;
			if(!is_built) buildBase();
			current_info = item_info;
			teleport_bt.disabled = TSModelLocator.instance.worldModel.location.tsid == current_info.external_street_tsid;
			teleport_bt.tip = teleport_bt.disabled ? {txt:'You are already here!', pointer:WindowBorder.POINTER_BOTTOM_CENTER} : null;
			
			//set the cost
			var cost_txt:String = '<p class="item_sale">';
			cost_txt += '<b>'+item_info.qty+'</b> available for ';
			cost_txt += '<b>'+StringUtil.formatNumberWithCommas(item_info.price_per_unit)+CurrencyInput.CURRANCY_SYMBOL+'</b>';
			if(item_info.qty > 1) cost_txt += ' each';
			cost_txt += '</p>';
			cost_tf.htmlText = cost_txt;
			
			//set the player
			const name_class:String = TSModelLocator.instance.worldModel.getBuddyByTsid(current_info.owner_tsid) ? 'item_sale_friend' : 'item_sale_normal';
			const vag_ok:Boolean = StringUtil.VagCanRender(item_info.owner_label);
			name_tf.embedFonts = vag_ok;
			var name_txt:String = '<p class="item_sale_name">';
			if(!vag_ok) name_txt += '<font face="Arial">';
			name_txt += 'at <a class="'+name_class+'" href="event:'+TSLinkedTextField.LINK_PLAYER_INFO+'|'+item_info.owner_tsid+'">';
			name_txt +=	StringUtil.nameApostrophe(item_info.owner_label);
			name_txt += '</a> Tower';
			if(!vag_ok) name_txt += '</font>';
			name_txt += '</p>';
			name_tf.htmlText = name_txt;
			name_tf.y = int(cost_tf.y + cost_tf.height - 3);
			
			text_holder.y = int(HEIGHT/2 - text_holder.height/2);
			
			//draw the BG
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0xf7f7f7, show_bg ? 1 : 0);
			g.drawRect(0, 0, w, HEIGHT);
			
			//draw the border
			if(!is_last){
				g.beginFill(0xd2d2d2);
				g.drawRect(0, HEIGHT-1, w, 1);
			}
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
		}
		
		private function onTeleportClick(event:TSEvent):void {
			if(teleport_bt.disabled) return;
			teleport_bt.disabled = true;
			
			//go to the home street
			GetInfoDialog.instance.end(true);
			TSFrontController.instance.genericSend(new NetOutgoingHousesVisitVO(current_info.owner_tsid));
		}
	}
}