package com.tinyspeck.engine.view.ui.localtrade
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CurrencyInput;
	import com.tinyspeck.engine.port.Cursor;
	import com.tinyspeck.engine.port.QuantityPicker;
	import com.tinyspeck.engine.port.TradeManager;
	import com.tinyspeck.engine.util.DragVO;
	import com.tinyspeck.engine.util.IDragTarget;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.making.MakingSlot;
	import com.tinyspeck.engine.view.ui.making.MakingSlotEmpty;
	import com.tinyspeck.engine.view.ui.supersearch.SuperSearch;
	import com.tinyspeck.engine.view.ui.supersearch.SuperSearchElementItem;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class LocalTradeBuySellUI extends Sprite implements IDragTarget
	{
		private static const IMG_HOLDER_WH:uint = 65;
		private static const MAX_CHARS:uint = 18; //would be awesome if this paid attention to width
		private static const TOP_PADD:uint = 5;
		
		private var super_search:SuperSearch = new SuperSearch();
		private var icon:ItemIconView;
		private var qp:QuantityPicker;
		private var announce_bt:Button;
		private var end_bt:Button;
		private var currants_input:CurrencyInput = new CurrencyInput();
		private var sell_slot:MakingSlotEmpty = new MakingSlotEmpty();
		private var dragVO:DragVO = DragVO.vo;
		
		private var search_holder:Sprite = new Sprite();
		private var result_holder:Sprite = new Sprite();
		private var image_holder:Sprite = new Sprite();
		private var sell_holder:Sprite = new Sprite();
		private var cancel_holder:Sprite = new Sprite();
		
		private var title_tf:TextField = new TextField();
		private var quantity_tf:TextField = new TextField();
		
		private var current_item_tsid:String;
		private var current_itemstack_tsid:String;
		private var current_quantity:int;
		private var snap_currants:int;
		private var snap_quantity:int;
		
		private var is_built:Boolean;
		
		private var _is_buy:Boolean;
		private var _w:int;
		
		public function LocalTradeBuySellUI(){}
		
		private function buildBase():void {			
			TFUtil.prepTF(title_tf);
			title_tf.y = TOP_PADD - 2;
			title = 'placeholder';
			addChild(title_tf);
			
			//init the super search
			super_search.init(SuperSearch.TYPE_ITEMS, 3, '...something. Type it here!');
			super_search.y = int(TOP_PADD + 25);
			super_search.show_images = true;
			super_search.item_tags_to_exclude = TradeManager.TRADE_TAGS_TO_EXCLUDE;
			super_search.addEventListener(TSEvent.CHANGED, onSearchChange, false, 0, true);
			
			addChild(search_holder);
			
			//results stuff
			var g:Graphics = image_holder.graphics;
			g.beginFill(0xffffff);
			g.drawRoundRect(0, 0, IMG_HOLDER_WH, IMG_HOLDER_WH, 8);
			image_holder.filters = StaticFilters.grey1pxOutter_GlowA;
			result_holder.addChild(image_holder);
			
			cancel_holder.addChild(new AssetManager.instance.assets.close_x_making_slot());
			cancel_holder.useHandCursor = cancel_holder.buttonMode = true;
			cancel_holder.x = int(IMG_HOLDER_WH - cancel_holder.width/2 - 3);
			cancel_holder.y = int(-cancel_holder.height/2 + 3);
			cancel_holder.addEventListener(MouseEvent.CLICK, onCancelClick, false, 0, true);
			result_holder.addChild(cancel_holder);
						
			qp = new QuantityPicker({
				w: IMG_HOLDER_WH,
				h: 20,
				name: 'qp',
				minus_graphic: new AssetManager.instance.assets.minus_red_small(),
				plus_graphic: new AssetManager.instance.assets.plus_green_small(),
				min_value: 1,
				button_wh: 17,
				button_padd: 1 //needs a smaller padd to fit 9999
			});
			qp.y = IMG_HOLDER_WH + 6;
			qp.addEventListener(TSEvent.CHANGED, onQuantityChange, false, 0, true);
			result_holder.addChild(qp);
			
			TFUtil.prepTF(quantity_tf, false);
			quantity_tf.htmlText = '<p class="local_trade_buy_quantity">Quantity</p>';
			quantity_tf.x = int(qp.width/2 - quantity_tf.width/2);
			quantity_tf.y = int(qp.y + qp.height - 7);
			result_holder.addChild(quantity_tf);
			
			announce_bt = new Button({
				name: 'announce',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			announce_bt.y = qp.y - 1;
			announce_bt.addEventListener(TSEvent.CHANGED, onAnnounceClick, false, 0, true);
			result_holder.addChild(announce_bt);
			
			end_bt = new Button({
				name: 'end',
				label: 'End trade',
				w: 71,
				size: Button.SIZE_TINY,
				type: Button.TYPE_CANCEL
			});
			end_bt.y = qp.y - 1;
			end_bt.addEventListener(TSEvent.CHANGED, onEndClick, false, 0, true);
			//result_holder.addChild(end_bt);
			
			currants_input.hide_save_button = true;
			currants_input.x = IMG_HOLDER_WH + 10;
			currants_input.y = int(IMG_HOLDER_WH - currants_input.height + 1);
			currants_input.addEventListener(TSEvent.CHANGED, onCurrantsChange, false, 0, true);
			result_holder.addChild(currants_input);
			
			result_holder.y = TOP_PADD;
			addChild(result_holder);
			
			//sell stuff
			sell_slot.y = TOP_PADD;
			sell_slot.tf.text = '';
			sell_holder.addChild(sell_slot);
			
			addChild(sell_holder);
			
			is_built = true;
		}
		
		public function show(w:int, is_buy:Boolean):void {
			if(!is_built) buildBase();
			_w = w;
			_is_buy = is_buy;
			
			//hide stuff
			search_holder.visible = is_buy;
			sell_holder.visible = !is_buy;
			result_holder.visible = false;
			current_itemstack_tsid = null;
			current_quantity = 0;
			
			if(is_buy){
				//search
				search_holder.addChild(super_search);
				super_search.show();
				onSearchChange();
			}
			else {
				//subscribe to pack dragging
				PackDisplayManager.instance.addEventListener(TSEvent.DRAG_STARTED, onPackDragStart, false, 0, true);
				PackDisplayManager.instance.addEventListener(TSEvent.DRAG_COMPLETE, onPackDragComplete, false, 0, true);
			}
			
			//results
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			const currants:int = pc && pc.stats ? pc.stats.currants : 0;
			announce_bt.label = 'Announce it!';
			announce_bt.disabled = true;
			currants_input.value = 0;
			currants_input.max_value = is_buy ? currants : 999999999;
			end_bt.visible = false;
			
			title = is_buy ? 'Buying...' : 'Selling...';
			
			visible = true;
			
			jigger();
		}
		
		public function hide():void {
			visible = false;
			dispatchEvent(new TSEvent(TSEvent.CHANGED));
			
			//unsub from pack dragging
			PackDisplayManager.instance.removeEventListener(TSEvent.DRAG_STARTED, onPackDragStart);
			PackDisplayManager.instance.removeEventListener(TSEvent.DRAG_COMPLETE, onPackDragComplete);
			
			if(search_holder.contains(super_search)) search_holder.removeChild(super_search);
		}
		
		public function edit():void {
			visible = true;
			announce_bt.label = 'Update';
			announce_bt.disabled = true;
			end_bt.disabled = false;
			end_bt.visible = true;
			snap_currants = currants;
			snap_quantity = count;
			
			showResult();
			
			jigger();
		}
		
		public function announceResult(success:Boolean):void {
			if(success)	hide();
			announce_bt.disabled = false;
		}
		
		private function jigger():void {
			super_search.width = _w;
			announce_bt.x = int(_w - announce_bt.width);
			end_bt.x = int(announce_bt.x - end_bt.width - 6);
			currants_input.width = int(_w - currants_input.x);
			
			dispatchEvent(new TSEvent(TSEvent.CHANGED));
		}
		
		private function showSell():void {
			//we should have the dragVO kicking around to yank out a reference to use
			if(!dragVO || !dragVO.dragged_itemstack || !dragVO.dragged_itemstack.item) return;
			current_item_tsid = dragVO.dragged_itemstack.class_tsid;
			
			sell_holder.visible = current_item_tsid ? false : true;
			
			showResult();
			
			//set the quantity value
			qp.value = dragVO.dragged_itemstack.count;
			current_quantity = qp.value;
		}
		
		private function onSearchChange(event:TSEvent = null):void {
			current_item_tsid = event && event.data ? (event.data as SuperSearchElementItem).value : null;
			search_holder.visible = current_item_tsid ? false : true;
			
			showResult();
			
			//set the quantity value
			qp.value = 1;
			current_quantity = qp.value;
		}
		
		private function showResult():void {
			result_holder.visible = current_item_tsid ? true : false;
			currants_input.visible = current_item_tsid ? true : false;
			
			if(current_item_tsid){
				const item:Item = TSModelLocator.instance.worldModel.getItemByTsid(current_item_tsid);
				const img_padd:uint = 4;
				if(item){
					//set the new title
					title = (is_buy ? 'Buying ' : 'Selling ')+(item.stackmax > 1 ? item.label_plural : StringUtil.aOrAn(item.label)+' '+item.label);
					
					//throw the image in the holder
					if(image_holder.name != item.tsid){
						while(image_holder.numChildren) image_holder.removeChildAt(0);
						icon = new ItemIconView(item.tsid, IMG_HOLDER_WH - img_padd*2);
						icon.x = icon.y = img_padd;
						image_holder.addChild(icon);
					}
					
					//if we have a stack max of 1, lock the max to 1
					if(is_buy){
						qp.max_value = item.stackmax > 1 ? MakingSlot.MAX_COUNT : 1;
					}
					else {
						//if we are selling, max out proper
						const pc:PC = TSModelLocator.instance.worldModel.pc;
						const has_how_many:int = pc ? pc.hasHowManyItems(current_item_tsid) : 1;
						qp.max_value = Math.min(has_how_many, MakingSlot.MAX_COUNT);
					}						
				}
			}
			
			dispatchEvent(new TSEvent(TSEvent.CHANGED));
		}
		
		private function onAnnounceClick(event:TSEvent):void {
			if(announce_bt.disabled) return;
			announce_bt.disabled = true;
			
			dispatchEvent(new TSEvent(TSEvent.ACTIVITY_HAPPENED));
		}
		
		private function onEndClick(event:TSEvent):void {
			if(end_bt.disabled) return;
			end_bt.disabled = true;
			
			dispatchEvent(new TSEvent(TSEvent.CLOSE));
		}
		
		private function onCancelClick(event:MouseEvent):void {
			//put it back to the first area
			show(_w, is_buy);
		}
		
		private function onPackDragStart(event:TSEvent):void {
			StageBeacon.mouse_move_sig.add(onPackDragMove);
		}
		
		private function onPackDragMove(event:MouseEvent):void {
			if(this.hitTestObject(Cursor.instance.drag_DO)){
				if(dragVO.target != this){
					if(dragVO.target) dragVO.target.unhighlightOnDragOut();
					if(dragVO.dragged_itemstack.slots && 
						TSModelLocator.instance.worldModel.getItemstacksInContainerTsid(dragVO.dragged_itemstack.tsid).length){
						//bag still has stuf in it
						Cursor.instance.showTip('There is still stuff in this!');
						unhighlightOnDragOut();
					}
					else if(!dragVO.dragged_itemstack.item.hasTags(TradeManager.TRADE_TAGS_TO_EXCLUDE)){
						Cursor.instance.showTip('Sell');
						highlightOnDragOver();
					}
					else {
						Cursor.instance.showTip('You can\'t sell this!');
						unhighlightOnDragOut();
					}
					dragVO.target = this;
				}
			} 
			else if(dragVO.target == this){
				dragVO.target = null;
				unhighlightOnDragOut();
				Cursor.instance.hideTip();
			}
			
		}
		
		private function onPackDragComplete(event:TSEvent):void {
			StageBeacon.mouse_move_sig.remove(onPackDragMove);
			if(dragVO.target == this && !dragVO.dragged_itemstack.item.hasTags(TradeManager.TRADE_TAGS_TO_EXCLUDE)) {
				//show the results of the drop
				showSell();
				current_itemstack_tsid = dragVO.dragged_itemstack.tsid;
			}
			unhighlightOnDragOut();
			Cursor.instance.hideTip();
		}
		
		private function onCurrantsChange(event:TSEvent):void {
			announce_bt.disabled = currants_input.value == 0 || (currants == snap_currants && count == snap_quantity);
			current_quantity = count;
		}
		
		private function onQuantityChange(event:TSEvent):void {
			if(!currants) return;
			
			//if we have any currants lets do some math for the player
			//it's not perfect because of the whole numbers, but it's more of an aid
			const unit_price:Number = currants/current_quantity;
			currants_input.value = Math.max(count * unit_price, 1);
		}
		
		public function unhighlightOnDragOut():void {
			if(!result_holder.visible) sell_slot.unhighlight();
		}
		
		public function highlightOnDragOver():void {
			sell_slot.highlight();
		}
		
		private function set title(value:String):void {
			//set the sub text
			var sub_txt:String = '';
			if(result_holder.visible){
				sub_txt = is_buy ? 'Willing to spend on lot' : 'Asking price for lot';
			}
			else if(!result_holder.visible && !is_buy){
				sub_txt = '<br>Drag item here<br>from your pack';
			}
			
			if(sub_txt) sub_txt = '<br><span class="local_trade_buy_sub">'+sub_txt+'</span>';
			 
			//make sure the text doesn't bleed off
			title_tf.htmlText = '<p class="local_trade_buy">'+StringUtil.truncate(value, MAX_CHARS)+sub_txt+'</p>';
			if(is_buy){
				title_tf.x = search_holder.visible ? -4 : IMG_HOLDER_WH + 10;
			}
			else {
				title_tf.x = sell_holder.visible ? int(sell_slot.slot_width + sell_slot.arrow.width - 5) : IMG_HOLDER_WH + 10;
			}
			title_tf.width = int(_w - title_tf.x);
		}
		
		public function get item_tsid():String { return current_item_tsid; }
		public function get itemstack_tsid():String { return current_itemstack_tsid; }
		public function get count():int { return qp.value; }
		public function get currants():int { return currants_input.value; }
		public function get is_buy():Boolean { return _is_buy; }
		
		override public function get height():Number {
			if(visible){
				const result_h:int = announce_bt.y + announce_bt.height + TOP_PADD + 1;
				if(is_buy){
					//+1 are visual tweaks to account for borders
					return search_holder.visible ? super_search.y + super_search.height + 1 : result_h;
				}
				else {
					return sell_holder.visible ? sell_slot.y + sell_slot.slot_height + 1 : result_h;
				}
			}
			return 0;
		}
	}
}