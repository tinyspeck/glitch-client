package com.tinyspeck.engine.view.ui.decorate
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.house.HouseExpandCosts;
	import com.tinyspeck.engine.data.house.HouseExpandReq;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.HouseExpandDialog;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;

	public class HouseExpandReqUI extends Sprite
	{
		private static const ICON_WH:uint = 55;
		
		private var icon_holder:Sprite = new Sprite();
		private var status_holder:Sprite = new Sprite();
		private var checkmark:DisplayObject;
		
		private var count_tf:TextField = new TextField();
		private var name_tf:TextField = new TextField();
		private var status_tf:TextField = new TextField();
		
		private var current_req:HouseExpandReq;
		private var current_item:Item;
		private var rect:Rectangle;
		
		private var status_bg_color:uint;
		
		private var is_built:Boolean;
		private var _has_material:Boolean;
		
		public function HouseExpandReqUI(){}
		
		private function buildBase():void {
			addChild(icon_holder);
			
			TFUtil.prepTF(count_tf, false);
			count_tf.filters = StaticFilters.white3px_GlowA;
			count_tf.htmlText = '<p class="house_expand_req_count">99x</p>';
			count_tf.y = int(ICON_WH - count_tf.height/2 - 7);
			addChild(count_tf);
			
			TFUtil.prepTF(name_tf, false);
			name_tf.htmlText = '<p class="house_expand_req_name">placeholder</p>';
			name_tf.y = int(count_tf.y + count_tf.height - 8);
			addChild(name_tf);
			
			TFUtil.prepTF(status_tf, false);
			status_tf.y = -2;
			status_holder.addChild(status_tf);
			addChild(status_holder);
			
			//mouse
			useHandCursor = buttonMode = true;
			mouseChildren = false;
			addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			
			//checkmark
			checkmark = new AssetManager.instance.assets.expand_check();
			status_holder.addChild(checkmark);
			
			//color
			status_bg_color = CSSManager.instance.getUintColorValueFromStyle('house_expand_req_need', 'backgroundColor', 0x8a3535);
			
			is_built = true;
		}
		
		public function show(req:HouseExpandReq, type:String):void {
			if(!is_built) buildBase();
			current_req = req;
			
			//show the count
			count_tf.htmlText = '<p class="house_expand_req_count">'+req.count+'x</p>';
			count_tf.x = int(ICON_WH/2 - count_tf.width/2);
			
			//show the name
			current_item = TSModelLocator.instance.worldModel.getItemByTsid(current_req.class_tsid);
			name_tf.htmlText = '<p class="house_expand_req_name">'+(current_item ? current_item.label : current_req.class_tsid)+'</p>';
			name_tf.x = int(ICON_WH/2 - name_tf.width/2);
			
			//place the icon
			showIcon();
			
			//show the status
			status_holder.visible = true;
			status_holder.y = int(name_tf.y + name_tf.height + 2);
			showStatus();
			
			//we need to shift stuff?
			jigger();
			
			//clickable?
			mouseEnabled = current_item != null;
		}
		
		private function showIcon():void {
			SpriteUtil.clean(icon_holder);
			
			//if we don't have a real item, show the broken sign
			const iiv:ItemIconView = new ItemIconView(current_item ? current_item.tsid : 'broken_sign', ICON_WH);
			icon_holder.addChild(iiv);
		}
		
		private function showStatus():void {
			var need_num:int = current_req.count;
			var status_txt:String = '<p class="house_expand_req_status">';
			
			//do we gots the goods?
			if(current_item){
				const pc:PC = TSModelLocator.instance.worldModel.pc;
				const has_how_many:int = pc.hasHowManyItems(current_item.tsid);
				need_num -= has_how_many;
			}
			
			//we need to show the checkmark?
			checkmark.visible = need_num <= 0;
			
			if(need_num > 0){
				status_txt += '<span class="house_expand_req_need">Need <b>'+need_num+'</b> more</span>';
			}
			else {
				status_txt += 'Got ’em';
			}
			
			status_txt += '</p>';
			status_tf.htmlText = status_txt;
			status_tf.x = need_num > 0 ? 2 : checkmark.width;
			
			const g:Graphics = status_holder.graphics;
			g.clear();
			if(need_num > 0){
				g.beginFill(status_bg_color);
				g.drawRoundRect(0, 0, int(status_tf.width + status_tf.x*2), 15, 6);
			}
			
			status_holder.x = int(ICON_WH/2 - status_holder.width/2);
			
			//have enough?
			_has_material = need_num <= 0;
		}
		
		private function jigger():void {
			//I feel like there is a smarter way to do this, but for the life of me I can't remember
			var i:int;
			var total:int = numChildren;
			
			rect = getBounds(this);
			
			for(i; i < total; i++){
				getChildAt(i).x -= rect.x;
			}
		}
		
		private function onClick(event:MouseEvent):void {
			if(!current_item) return;
			
			//open the item info dialog
			TSFrontController.instance.showItemInfo(current_item.tsid);
		}
		
		public function dispose():void {
			//axe the listener
			removeEventListener(MouseEvent.CLICK, onClick);
		}
		
		public function get has_material():Boolean { return _has_material; }
	}
}