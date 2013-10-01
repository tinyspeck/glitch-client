package com.tinyspeck.engine.port
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCSkill;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.data.store.Store;
	import com.tinyspeck.engine.data.store.StoreItem;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.store.StoreBuyUI;
	import com.tinyspeck.engine.view.ui.store.StoreSellUI;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.text.TextField;

	public class StoreDialog extends BigDialog
	{
		/* singleton boilerplate */
		public static const instance:StoreDialog = new StoreDialog();
		
		private static const CRUNCH_LENGTH:uint = 1;
		
		private const INFO_X:int = 170;
		
		private var head_mask:Sprite = new Sprite();
		private var buy_holder:Sprite = new Sprite();
		private var sell_holder:Sprite = new Sprite();
		private var info_holder:Sprite = new Sprite();
		private var tab_bottom:Sprite = new Sprite();
		
		private var back_bt:Button;
		private var buy_bt:Button;
		private var buy_ui:StoreBuyUI;
		private var sell_bt:Button;
		private var sell_ui:StoreSellUI;
		
		private var currants_tf:TextField = new TextField();
		private var currants_total_tf:TextField = new TextField();
		
		private var currants_icon:DisplayObject;
		
		private var total_currants:int;
		private var scroll_y:int; //so we can remember where it needs to go when hitting back
		
		private var is_built:Boolean;
		
		public function StoreDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_draggable = true;
			_head_min_h = 67;
			_body_min_h = 310;
			_foot_min_h = 53;
			_w = 587;
			_base_padd = 20;
			_construct();
		}
		
		private function buildBase():void {
			const bt_w:uint = 72;
			
			//buy/sell tabs			
			sell_bt = new Button({
				name: 'sell',
				label: 'Sell',
				type: Button.TYPE_TAB,
				size: Button.SIZE_DEFAULT,
				w: bt_w,
				use_hand_cursor_always: true
			});
			sell_bt.addEventListener(TSEvent.CHANGED, onSellClick, false, 0, true);
			_head_sp.addChild(sell_bt);
			
			buy_bt = new Button({
				name: 'buy',
				label: 'Buy',
				type: Button.TYPE_TAB,
				size: Button.SIZE_DEFAULT,
				w: bt_w,
				use_hand_cursor_always: true
			});
			buy_bt.addEventListener(TSEvent.CHANGED, onBuyClick, false, 0, true);
			_head_sp.addChild(buy_bt);
			
			//mask for top buttons
			_head_sp.addChild(head_mask);
			_head_sp.mask = head_mask;
			
			//add a line under the inactive tab
			var g:Graphics = tab_bottom.graphics;
			g.beginFill(_body_border_c);
			g.drawRect(0, 0, bt_w, 1);
			_body_sp.addChild(tab_bottom);
			
			//sell UI
			sell_ui = new StoreSellUI('light');
			sell_ui.setSize(_w, _body_min_h-10);
			sell_holder.addChild(sell_ui);
			
			//currants
			TFUtil.prepTF(currants_tf, false);
			currants_tf.htmlText = '<p class="store_currants">You have</p>';
			currants_tf.y = int(_foot_min_h/2 - currants_tf.height/2);
			_foot_sp.addChild(currants_tf);
			
			TFUtil.prepTF(currants_total_tf, false);
			currants_total_tf.htmlText = '<p class="store_currants_total">0 currants</p>';
			currants_total_tf.y = int(_foot_min_h/2 - currants_total_tf.height/2);
			_foot_sp.addChild(currants_total_tf);
			
			currants_icon = new AssetManager.instance.assets.store_currants();
			currants_icon.y = int(_foot_min_h/2 - currants_icon.height/2);
			_foot_sp.addChild(currants_icon);
			
			_foot_sp.mouseEnabled = _foot_sp.mouseChildren = false;
			_foot_sp.visible = true;
			
			//item info
			info_holder.x = _w;
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
			back_bt.addEventListener(TSEvent.CHANGED, onBackClick, false, 0, true);
			info_holder.addChild(back_bt);
			
			//buy ui
			buy_ui = new StoreBuyUI(_w - _base_padd*3); //room for the scroll bar if need be
			buy_ui.x = _base_padd;
			buy_ui.addEventListener(TSEvent.CHANGED, onItemInfoChanged, false, 0, true);
			buy_ui.addEventListener(TSEvent.COMPLETE, onPreloadComplete, false, 0, true);
			info_holder.addChild(buy_ui);
			
			//shevling makes the scroller work kindda funky, so we'll turn off the children get the height
			_scroller.use_children_for_body_h = false;
			
			is_built = true;
		}
		
		override public function start():void {
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			
			
			var current_store:Store = StoreManager.instance.current_store;
			
			if(current_store){
				_setTitle('<span class="store_title">'+current_store.name+'</span>');
				
				//build out the shelves
				SpriteUtil.clean(buy_holder);
				buildShelves(current_store.items);
				
				//get more info on all the items in the store
				if(model.worldModel.pc) onSkillChanged(model.worldModel.pc.skill_training);
				
				//does this store support selling?
				if(sell_bt){
					sell_bt.visible = current_store.buy_multiplier > 0;
				}
				if (buy_bt) {
					buy_bt.visible = sell_bt.visible;
				}
			}
			else {
				CONFIG::debugging {
					Console.warn('There is no current_store set in the StoreManager!');
				}
				return;
			}
			
			//listen for stat updates (currants)
			model.worldModel.registerCBProp(onStatsChanged, "pc", "stats");
			
			//listen for skill changes (will change items)
			model.worldModel.registerCBProp(onSkillChanged, "pc", "skill_training_complete");


			if (StoreManager.instance.current_store.is_single_furniture) {
				_w = 450;
				_body_min_h = 240;
			} else {
				_w = 587;
				_body_min_h = 310;
			}
			
			_scroller.w = _w-(_border_w*2)
			
			sell_ui.setSize(_w, _body_min_h-10);
			super.start();
			
			//show the current amount of currants
			if(model.worldModel.pc) setCurrants(model.worldModel.pc.stats.currants);
			
			//start in "buy" mode (after a jigger so the bottom line shows up in the right place
			if(current_store) {
				toggleMode(true);
				if (shouldShowShelves()) {
					buy_ui.y = 48;
					back_bt.visible = true;
				} else {
					buy_ui.y = 20;
					back_bt.visible = false;
				}
			}
			
		}
		
		private function shouldShowShelves():Boolean {
			if (StoreManager.instance.current_store && StoreManager.instance.current_store.items.length != 1) return true;
			return false;
		}
		
		override public function end(release:Boolean):void {
			super.end(release);
			
			last_x = 0;
			last_y = 0;
			
			if (sell_ui) sell_ui.hide();
			
			TSFrontController.instance.enableDropToFloor();
			model.worldModel.unRegisterCBProp(onStatsChanged, "pc", "stats");
			model.worldModel.unRegisterCBProp(onSkillChanged, "pc", "skill_training_complete");
			
			StoreManager.instance.end();
		}
		
		public function checkItemPrice(itemstack:Itemstack):void {
			if(sell_ui) sell_ui.checkItemPrice(itemstack);
		}
		
		private function toggleMode(is_buy:Boolean):void {
			buy_bt.disabled = !is_buy;
			sell_bt.disabled = is_buy;
			
			if(_scroller.body.contains(buy_holder)) _scroller.body.removeChild(buy_holder);
			if(_scroller.body.contains(sell_holder)) _scroller.body.removeChild(sell_holder);
			if(_scroller.body.contains(info_holder)) _scroller.body.removeChild(info_holder);
			
			if(is_buy){
				_scroller.body.addChild(buy_holder);
				
				//position nicely
				buy_holder.x = int(_w/2 - buy_holder.width/2) - (_scroller.body_h > _body_min_h ? 10 : 0);
				info_holder.x = _w;
				
				sell_ui.hide();
				
				const current_store:Store = StoreManager.instance.current_store;
				if (shouldShowShelves()) {
					back_bt.visible = true;
				} else {
					back_bt.visible = false;
					showItem(current_store.single_stack_tsid, current_store.items[0], 0);
				}
			}
			else{
				_scroller.body.addChild(sell_holder);
				sell_ui.show(StoreManager.instance.current_store.tsid);
			}
			
			//make sure we don't toss anything in main_view by accident
			if (is_buy) {
				TSFrontController.instance.enableDropToFloor();
			} else {
				TSFrontController.instance.disableDropToFloor();
			}
			
			//put a little border under the inactive tab
			tab_bottom.x = is_buy ? sell_bt.x : buy_bt.x;
			
			_scroller.refreshAfterBodySizeChange(true);
		}
		
		private function getHowManyYouHaveString(item_class:String):String {
			var you_have_str:String = model.worldModel.pc.hasHowManyItems(item_class).toString();
			if (you_have_str != '0') {
				you_have_str = ' (you have '+you_have_str+')';
			} else {
				you_have_str = '';
			}
			
			return you_have_str;
		}
		
		public function updateBuyBtTips():void {
			if (!buy_holder) return;
			var bt:Button;
			var item:Item;
			for (var i:int=0;i<buy_holder.numChildren;i++) {
				bt = buy_holder.getChildAt(i) as Button;
				if (!bt) continue;
				item = model.worldModel.getItemByTsid(bt.name);
				if (!item) continue;
				bt.tip = {
					txt: item.label+getHowManyYouHaveString(item.tsid),
					pointer: WindowBorder.POINTER_BOTTOM_CENTER	
				}
				
				if (buy_ui && buy_ui.item_class && buy_ui.item_class == item.tsid) {
					buy_ui.updateYouHave();
				}
			}
		}
		
		private function buildShelves(items:Vector.<StoreItem>):void {
			const bt_w:int = 64;
			const bt_h:int = 70;
			const cols:uint = 7;
			const rows:uint =  Math.max(2, Math.ceil(items.length/cols));
			const item_side_padd:int = 20; // how far first item on shelf is from side of shelf
			const item_inner_padd:int = 7; // har far apart items are form on another 
			const item_bott_padd:int = 19; // how far up on the shelf the items sit FROM THE APPARENT BACK OF THE SHELF
			
			const shelf_top_padd:int = 75;
			const shelf_distance:int = 100;
			const shelf_offset:int = 52; //how much from the top of the button to push down
			
			const pc:PC = model.worldModel.pc;
			
			var shelf:DisplayObject;
			var bt:Button;
			var col:int;
			var row:int;
			var i:int;
			var item:Item;
			var item_class:String;
			var current_row:int = -1;
			var label_c:uint;
			var currant_c:String;
			var store_item:StoreItem;
			
			for(i; i < items.length; i++){
				store_item = items[int(i)];
				col = (i % cols);
				row = Math.floor(i / cols);
				item_class = store_item.class_tsid;
				item = model.worldModel.getItemByTsid(item_class);
				label_c = 0x444444;
				currant_c = '#a6a6a6';
				
				var cost_str:String;
				
				if (store_item.total_quantity && store_item.count == 0) {
					// no more in inventory
					cost_str = 'all out!';

					//don't have enough to buy this
					label_c = 0x89181b;
					currant_c = '#89181b';
				} else {
					cost_str = (store_item.cost > 99999) ? StringUtil.crunchNumber(store_item.cost, CRUNCH_LENGTH) : store_item.cost.toString();
					
					if(pc.stats.currants < store_item.cost) {
						//don't have enough to buy this
						label_c = 0x89181b;
						currant_c = '#89181b';
					}
					
					cost_str+= '<font size="11" color="'+currant_c+'">₡</font>';
				}
				
				
				bt = new Button({
					graphic: new ItemIconView(item_class, 40),
					graphic_placement: 'top',
					label_bold: true,
					label_size: 13,
					label_c: label_c,
					graphic_padd_t: 8,
					graphic_padd_b: 4,
					text_align: 'right',
					label: cost_str,
					name: item_class,
					value: store_item,
					x: item_side_padd+(col*(bt_w+item_inner_padd)),
					y: shelf_top_padd+(row*shelf_distance)-bt_h+item_bott_padd,
					w: bt_w,
					h: bt_h,
					c: 0xffffff,
					high_c: 0xffffff,
					shad_c: 0xcecece,
					inner_shad_c: 0x69bcea,
					disabled: false,
					tip: {
						txt: item.label+getHowManyYouHaveString(item_class),
						pointer: WindowBorder.POINTER_BOTTOM_CENTER	
					}
				});
				bt.addEventListener(TSEvent.CHANGED, onItemClick, false, 0, true);
				
				buy_holder.addChild(bt);
				
				//put a shelf on if we need it
				if(current_row != row){
					shelf = new AssetManager.instance.assets.store_shelf_new();
					shelf.y = shelf_top_padd+(row*shelf_distance)-bt_h+item_bott_padd + shelf_offset;
					buy_holder.addChildAt(shelf, 0);
					current_row = row;
				}
			}
		}
		
		private function onItemClick(event:TSEvent):void {
			const current_store:Store = StoreManager.instance.current_store;
			const store_item:StoreItem = Button(event.data).value as StoreItem;
			scroll_y = _scroller.scroll_y;
			showItem(null, store_item, .4);
		}
		
		private var current_buy_item:String;
		private function showItem(single_stack_tsid:String, store_item:StoreItem, time:Number=1):void {
			current_buy_item = store_item.class_tsid;
			//slide the items out of the way and make room for the item details
			TSTweener.addTween(buy_holder, {x:-_w, time:time,
				onComplete:function():void {
					//remove the buy items from the scroller so it can scroll the item details
					_scroller.body.removeChild(buy_holder);
					_scroller.refreshAfterBodySizeChange(true);
				}
			});
			
			buy_ui.is_single_furniture = StoreManager.instance.current_store.is_single_furniture;
			buy_ui.show(single_stack_tsid, store_item);
			
			_scroller.body.addChild(info_holder);
			TSTweener.addTween(info_holder, {x:0, time:time});
			
			//reset the scroller to the top
			_scroller.scrollUpToTop();
		}
		
		private function onBackClick(event:TSEvent = null):void {			
			//bring back the items
			current_buy_item = null;
			_scroller.body.addChild(buy_holder);
			TSTweener.addTween(buy_holder, {x:int(_w/2 - buy_holder.width/2) - (_scroller.body_h > _body_min_h ? 10 : 0), time:.4,
				onComplete:function():void {
					//empty out the info holder
					buy_ui.hide();
					_scroller.refreshAfterBodySizeChange();
				}
			});
			
			TSTweener.addTween(info_holder, {x:_w, time:.4});
			
			//reset the scroller to the top
			_scroller.scrollYToTop(scroll_y);
		}
		
		private function setCurrants(currants:int):void {
			currants_total_tf.htmlText = '<p class="store_currants_total">'+
									 	 StringUtil.formatNumberWithCommas(currants)+(currants != 1 ? ' currants' : ' currant')+
										 '</p>';
			currants_total_tf.x = int(_w - _base_padd - currants_total_tf.width);
			currants_icon.x = int(currants_total_tf.x - currants_icon.width);
			currants_tf.x = int(currants_icon.x - currants_tf.width);
			
			total_currants = currants;
		}
		
		private function onStatsChanged(pc_stats:PCStats):void {
			if(pc_stats.currants == total_currants) return;
			
			setCurrants(pc_stats.currants);
			
			//make sure all the button prices are accurate
			var i:int;
			var child:DisplayObject;
			var bt:Button;
			var label_c:uint;
			var currant_c:String;
			var cost_str:String;
			
			for(i; i < buy_holder.numChildren; i++){
				child = buy_holder.getChildAt(i);
				if(child is Button){
					bt = child as Button;
					label_c = 0x444444;
					currant_c = '#a6a6a6';
					cost_str = (bt.value.cost > 99999) ? StringUtil.crunchNumber(bt.value.cost, CRUNCH_LENGTH) : bt.value.cost.toString();
					if(pc_stats.currants < bt.value.cost) {
						//don't have enough to buy this
						label_c = 0x89181b;
						currant_c = '#89181b';
					}
					bt.label = cost_str+'<font size="11" color="'+currant_c+'">₡</font>';
					bt.label_color = label_c;
					bt.label_color_hover = label_c;
				}
			}
		}
		
		public function maybeUpdateBuyUi(class_tsid:String):Boolean {
			var store_item:StoreItem = StoreManager.instance.current_store.getStoreItemByItemClass(class_tsid);
			if (!store_item) return false;
			if (current_buy_item == store_item.class_tsid) {
				buy_ui.refigger(store_item);
				return true;
			}
			
			return false;
		}
		
		public function onQuantityChanged(class_tsid:String):void {
			maybeUpdateBuyUi(class_tsid);
		}
		
		public function onPriceChanged(class_tsid:String):void {
			maybeUpdateBuyUi(class_tsid);
		}
		
		private function onSkillChanged(pc_skill:PCSkill):void {
			//reload the store items
			buy_ui.preloadItems(StoreManager.instance.current_store.items);
		}
		
		private function onPreloadComplete(event:TSEvent):void {
			//scan the buttons to see if there are anything new to do
			var i:int;
			var child:DisplayObject;
			var bt:Button;
			var warn:DisplayObject;
			var item:Item;
			var rect:Rectangle;
			
			for(i; i < buy_holder.numChildren; i++){
				child = buy_holder.getChildAt(i);
				if(child is Button){
					bt = child as Button;
					item = model.worldModel.getItemByTsid(bt.name);
					if(item && item.details && item.details.warnings.length > 0){
						rect = bt.label_tf.getCharBoundaries(0);
						if(rect){
							warn = new AssetManager.instance.assets.store_warning();
							warn.name = 'warn';
							warn.x = int(bt.label_tf.x + rect.x - warn.width) - 1;
							warn.y = int(bt.label_tf.y + (bt.label_tf.height/2 - warn.height/2));
							bt.addChild(warn);
						}
					}
					else if(bt.getChildByName('warn')){
						warn = bt.getChildByName('warn');
						bt.removeChild(warn);
					}
				}
			} 
		}
		
		private function onItemInfoChanged(event:TSEvent):void {
			_jigger();
		}
		
		private function onBuyClick(event:TSEvent):void {
			if(!buy_bt.disabled) return;
			
			toggleMode(true);
		}
		
		private function onSellClick(event:TSEvent):void {
			if(!sell_bt.disabled) return;
			
			toggleMode(false);
		}
		
		public function buyOver():void {
			if (back_bt.visible) {
				// throw them back to the main product list
				onBackClick();
			} else {
				// close it
				end(true);
			}
		}
		
		public function buySuccess():void {
			buyOver();
		}
		
		public function buyFailure(txt:String):void {
			txt = txt || "Reason unknown.";
			var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
			cdVO.title = 'Well that didn\'t work'
			cdVO.txt = "Your purchase failed :( "+txt;
			cdVO.choices = [
				{value: true, label: 'Thanks, I guess'}
			];
			TSFrontController.instance.confirm(cdVO);
			
			buyOver();
		}
		
		override protected function _jigger():void {
			const current_store:Store = StoreManager.instance.current_store;
			super._jigger();
			_scroller.h = _body_min_h - _divider_h*2;
			
			_body_h = _body_min_h;
			_foot_sp.y = _head_h + _body_h;
			_h = _head_h + _body_h + _foot_h;
			
			//move the tabs
			sell_bt.x = _w - sell_bt.width - 55;
			sell_bt.y = _head_h - buy_bt.height + 5;
			buy_bt.x = current_store && current_store.buy_multiplier != 0 ? sell_bt.x - buy_bt.width - 5 : _w - buy_bt.width - 55;
			buy_bt.y = sell_bt.y;
			
			//redraw the header mask
			var g:Graphics = head_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRect(0, 0, _w, _head_h + _divider_h);
		}
	}
}