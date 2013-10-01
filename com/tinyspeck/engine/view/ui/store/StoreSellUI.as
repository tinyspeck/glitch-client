package com.tinyspeck.engine.view.ui.store {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.Cursor;
	import com.tinyspeck.engine.port.IPackChange;
	import com.tinyspeck.engine.port.QuantityPicker;
	import com.tinyspeck.engine.port.StoreManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.DragVO;
	import com.tinyspeck.engine.util.IDragTarget;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.CapsStyle;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.text.TextField;
	
	public class StoreSellUI extends TSSpriteWithModel implements IDragTarget, IPackChange {
		
		private const ICON_WH:uint = 100;
		private const OFFSET_X:uint = 80;
		
		private var slot:DisplayObject;
		private var slot_lit:DisplayObject;
		private var arrow:DisplayObject;
		
		private var dragVO:DragVO = DragVO.vo;
		private var quantity_qp:QuantityPicker;
		private var back_bt:Button;
		private var sell_bt:Button;
		private var sell_icon:ItemIconView;
		
		private var title_tf:TextField = new TextField();
		private var tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var item_holder:Sprite = new Sprite();
		private var all_holder:Sprite = new Sprite(); //used for when the quantity picker is up
		
		private var qty:int = 1;
		private var cost:Number = 1;
		private var multiplier:Number = 0;
		private var multiplier_upgrade_name:String;
		
		private var sell_item_class:String;
		private var sell_item_tsid:String; // I don't want to have to use this! want to be able seel by lass not by stack
		private var which:String;
		private var store_sell_style:String;
		
		private var single_stack_only:Boolean;
		private var is_built:Boolean;
		
		public function StoreSellUI(which:String) {
			super();
			this.which = which;
			visible = false;
		}
		
		private function buildBase():void {
			var g:Graphics = item_holder.graphics;
			g.lineStyle(1, 0xdbdbdb, 1, true, LineScaleMode.NONE, CapsStyle.ROUND);
			g.beginFill(0xffffff);
			g.drawRoundRect(0, 0, ICON_WH + 20, ICON_WH + 20, 14);
			all_holder.addChild(item_holder);
			
			if (which == 'dark') {
				store_sell_style = 'store_sell_dark_NEW';
				slot = new AssetManager.instance.assets.empty_making_slot_white();
			} else {
				store_sell_style = 'store_sell_light_NEW';
				slot = new AssetManager.instance.assets.empty_making_slot();
			}			
			addChild(slot);
			
			slot_lit = new AssetManager.instance.assets.filled_making_slot();
			addChild(slot_lit);
			
			arrow = new AssetManager.instance.assets.making_drag_arrow();
			addChild(arrow);
			
			//title tf
			TFUtil.prepTF(title_tf);
			all_holder.addChild(title_tf);
			
			//body tf
			TFUtil.prepTF(tf);
			tf.addEventListener(TextEvent.LINK, showPrompt, false, 0, true);
			addChild(tf);
			
			//buttons
			sell_bt = new Button({
				label: 'Sell',
				name: 'sell',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			sell_bt.visible = false;
			all_holder.addChild(sell_bt);
			
			var arrow_holder:Sprite = new Sprite();
			var arrowDO:DisplayObject = new AssetManager.instance.assets.back_arrow();
			SpriteUtil.setRegistrationPoint(arrowDO);
			arrow_holder.rotation = -90;
			arrow_holder.addChild(arrowDO);
			back_bt = new Button({
				label: 'Back',
				name: 'back',
				graphic: arrow_holder,
				graphic_padd_w: 0,
				graphic_padd_t: 9,
				x: 25,
				y: 15,
				size: Button.SIZE_MICRO,
				type: Button.TYPE_BACK
			});
			back_bt.addEventListener(TSEvent.CHANGED, showPrompt, false, 0, true);
			addChild(back_bt);
			
			quantity_qp = new QuantityPicker({
				w: 135,
				h: 36,
				name: '_quantity_qp',
				minus_graphic: new AssetManager.instance.assets.minus_red(),
				plus_graphic: new AssetManager.instance.assets.plus_green(),
				max_value: 1, // to be changed
				min_value: 1,
				button_wh: 20,
				button_padd: 3,
				show_all_option: true
			});
			quantity_qp.visible = false;
			all_holder.addChild(quantity_qp);
			
			all_holder.x = OFFSET_X;
			addChild(all_holder);
			
			is_built = true;
		}
		
		public function setSize(w:int, h:int):void {
			if(!is_built) buildBase();
			
			_w = w;
			_h = h;
			
			const g:Graphics = graphics;
			g.clear();
			g.lineStyle(0, 0, 0);
			g.beginFill(0, 0);
			g.drawRect(0, 0, _w, _h);
			g.endFill();
			
			//move the drop slots where they need to go
			slot_lit.x = slot.x = int((_w-slot.width)/2);
			slot_lit.y = slot.y = int((_h-slot.height)/2)-25;
			arrow.x = slot.x+53;
			arrow.y = slot.y+14;
		}
		
		public function checkItemPrice(itemstack:Itemstack):void {
			// we don't want no stinking bags
			if (itemstack.slots) return;
			if(!is_built) buildBase();
			
			qty = 1;
			sell_bt.visible = false;
			quantity_qp.visible = false;
			
			sell_item_class = itemstack.class_tsid;
			sell_item_tsid = itemstack.tsid;

			showWaiting();
			StoreManager.instance.checkItemPrice(itemstack, onStoreCheck);
		}
		
		public function onStoreCheck(rm:NetResponseMessageVO):void {
			single_stack_only = false;
			if (rm.success) {
				cost = rm.payload.cost;
				multiplier = rm.payload.multiplier || 0;
				multiplier_upgrade_name = rm.payload.upgrade_name || 'iMG';
				if(rm.payload.hasOwnProperty('single_stack_only')) single_stack_only = rm.payload.single_stack_only;
				showForm();
			} else {
				tf.htmlText = '<p class="'+store_sell_style+'">This store has zero interest in buying this from you. <a href="event:x">Want to try something else?</a></p>';
				placeTfBesideSlot();
				sell_item_class = null;
				sell_item_tsid = null;
			}
		}
		
		public function show(store_item_tsid:String):void {
			if(!is_built) buildBase();
            //TODO: Y U assign param to itself?
			store_item_tsid = store_item_tsid;
			visible = true;
			showPrompt();
		}
		
		public function hide():void {
			visible = false;
			if (quantity_qp) quantity_qp.removeEventListener(TSEvent.CHANGED, onQuantityChange);
			if (sell_bt) sell_bt.removeEventListener(TSEvent.CHANGED, onSellClick);
			showPrompt();
		}
		
		private function placeTfBesideSlot():void {
			//add the tf to the all holder and put it to the right of the item image
			all_holder.addChild(tf);
			tf.width = 290;
			tf.width = tf.textWidth + 6;
			
			title_tf.width = 260;
			title_tf.x = item_holder.x + item_holder.width + 20;
			title_tf.y = item_holder.y + 0;
			
			tf.x = title_tf.x;
			tf.y = title_tf.y + title_tf.height;
			
			all_holder.visible = true;
		}
		
		private function showPrompt(event:Event = null):void {
			sell_item_class = '';
			sell_item_tsid = '';
			item_holder.visible = false;
			slot.visible = arrow.visible = true;
			slot_lit.visible = false;
			back_bt.visible = false;
			
			if (sell_icon) sell_icon.visible = false;
			sell_bt.visible = false;
			quantity_qp.visible = false;
			
			//put the tf under the slot and center it
			addChild(tf);
			tf.htmlText = '<p class="'+store_sell_style+'"><span class="store_sell_drag">Drag an item from your pack.</span></p>';
			tf.width = _w;
			tf.width = tf.textWidth + 6;
			tf.y = slot.y + slot.height + 20;
			tf.x = int(_w/2 - tf.width/2);
			
			all_holder.visible = false;
			
			//if visible listen to the pack
			if(visible){
				PackDisplayManager.instance.addEventListener(TSEvent.DRAG_COMPLETE, onPackDragComplete);
				PackDisplayManager.instance.addEventListener(TSEvent.DRAG_STARTED, onPackDragStart);
				PackDisplayManager.instance.registerChangeSubscriber(this);
			}
			else {
				PackDisplayManager.instance.removeEventListener(TSEvent.DRAG_COMPLETE, onPackDragComplete);
				PackDisplayManager.instance.removeEventListener(TSEvent.DRAG_STARTED, onPackDragStart);
				PackDisplayManager.instance.unRegisterChangeSubscriber(this);
			}
		}
		
		private function showWaiting():void {
			slot.visible = slot_lit.visible = arrow.visible = false;
			item_holder.visible = true;
			back_bt.visible = true;
			
			title_tf.htmlText = '<p class="store_sell_title">'+model.worldModel.getItemByTsid(sell_item_class).label+'</p>';
			tf.htmlText = '<p class="'+store_sell_style+'">Calculating value...</p>';
			placeTfBesideSlot();
			
			sell_bt.visible = false;
			quantity_qp.visible = false;
			
			if (!sell_icon || sell_icon.name != sell_item_class) {
				if (sell_icon && sell_icon.parent) sell_icon.parent.removeChild(sell_icon);
				sell_icon = new ItemIconView(sell_item_class, ICON_WH);
			}
			sell_icon.name = sell_item_class;
			
			item_holder.addChild(sell_icon);
			sell_icon.visible = true;
			sell_icon.x = int(item_holder.width/2 - ICON_WH/2);
			sell_icon.y = int(item_holder.height/2 - ICON_WH/2);
			
			//place it
			all_holder.y = int(_h/2 - all_holder.height/2);
			
			//don't allow them to drag anything NEW to the sell dialog
			PackDisplayManager.instance.removeEventListener(TSEvent.DRAG_COMPLETE, onPackDragComplete);
			PackDisplayManager.instance.removeEventListener(TSEvent.DRAG_STARTED, onPackDragStart);
		}
		
		private function updateSellText():void {
			var max:int = model.worldModel.pc.hasHowManyItems(sell_item_class);
			
			var base:int = Math.round(qty*cost);
			var total:int = getYourTotal();
			var bonus:int = total-base;
			
			tf.htmlText = '<p class="'+store_sell_style+'">Will pay '+cost+(cost != 1 ? ' currants' : ' currant')+' each.'+
				(!single_stack_only ? ' You have '+max+'.' : '')+
				(bonus ? ' <b>Your "'+multiplier_upgrade_name+'" upgrade gets you an extra '+(bonus==1?'currant':bonus+' currants')+'!</b>' : '')+
				'</p>';
				
			placeTfBesideSlot();
			
			quantity_qp.x = tf.x;
			quantity_qp.y = tf.y + 53;
			sell_bt.x = quantity_qp.x + quantity_qp.width + 5;
			sell_bt.y = quantity_qp.y - 1;
		}
		
		private function showForm():void {
			var max:int = model.worldModel.pc.hasHowManyItems(sell_item_class);
						
			showWaiting();
			slot.visible = false;
			slot_lit.visible = false;
			item_holder.visible = true;
			
			updateSellText();
			
			quantity_qp.visible = true;
			
			sell_bt.visible = true;
			sell_bt.disabled = false;
			
			// here set state of buttons
			quantity_qp.max_value = (!single_stack_only ? Math.min(max, 9999) : 1);
			quantity_qp.value = qty;
			quantity_qp.addEventListener(TSEvent.CHANGED, onQuantityChange, false, 0, true);
			sell_bt.addEventListener(TSEvent.CHANGED, onSellClick, false, 0, true);
			updateButtonLabel();
			
			//place it
			all_holder.y = int(_h/2 - all_holder.height/2);
		}
		
		private function sellCheck(rm:NetResponseMessageVO):void {			
			if(rm.success){
				//if they have >= 9999 of this item, let them sell more, otherwise clear out the thing
				var max:int = model.worldModel.pc.hasHowManyItems(sell_item_class);
				
				if(max >= 9999 && !single_stack_only){
					qty = 9999;
					showForm();
				}
				else {
					showPrompt();
				}
			}
			else {
				tf.htmlText = '<p class="'+store_sell_style+'">Looks like something went wrong. <a href="event:x">Want to try again?</a></p>';
				placeTfBesideSlot();
			}
		}
		
		private function onSellClick(event:TSEvent):void {
			if(sell_bt.disabled) return;
			sell_bt.disabled = true;
			
			StoreManager.instance.sellItems(qty, sell_item_class, sell_item_tsid, sellCheck);
		}
		
		private function onQuantityChange(e:TSEvent):void {
			qty = quantity_qp.value;
			updateButtonLabel();
			updateSellText();
		}
		
		public function onPackChange():void {
			//make sure we have the right quantity still
			if(sell_item_class && model.worldModel.pc.hasHowManyItems(sell_item_class)) {
				showForm();
			}
			else {
				showPrompt();
			}
		}
		
		private function getYourTotal():Number {
			var base:Number = qty*cost;
			return Math.round(base+(multiplier*base));
		}
		
		private function updateButtonLabel():void {
			var base:Number = qty*cost;
			sell_bt.label = 'Sell: '+StringUtil.formatNumberWithCommas(qty)+
							' for '+StringUtil.formatNumberWithCommas(getYourTotal())+
							'<font size="13">₡</font>';
		}
		
		private function onPackDragStart(e:TSEvent):void {
			// we don't want no stinking bags
			if (dragVO.dragged_itemstack.slots) return;
			
			StageBeacon.mouse_move_sig.add(onPackDragMove);
		}
		
		private function onPackDragMove(e:MouseEvent):void {
			if (this.hitTestObject(Cursor.instance.drag_DO)) {
				if (dragVO.target != this) {
					if (dragVO.target) dragVO.target.unhighlightOnDragOut();
					Cursor.instance.showTip('Sell');
					highlightOnDragOver();
					dragVO.target = this;
				}
			} else {
				if (dragVO.target == this) {
					dragVO.target = null;
					unhighlightOnDragOut();
					Cursor.instance.hideTip();
				}
			}
		}
		
		private function onPackDragComplete(e:TSEvent):void {
			StageBeacon.mouse_move_sig.remove(onPackDragMove);
			if (dragVO.target == this) {
				checkItemPrice(dragVO.dragged_itemstack);
			}
			unhighlightOnDragOut();
			Cursor.instance.hideTip();
		}
		
		public function unhighlightOnDragOut():void {
			slot_lit.filters = null;
			if (sell_item_class) {
				
			} else {
				slot_lit.visible = false;
				slot.visible = true;
			}
		}
		
		public function highlightOnDragOver():void {
			slot.visible = false;
			slot_lit.visible = true;
			if (!slot_lit.filters.length) slot_lit.filters = StaticFilters.slot_GlowA;
		}
	}
}