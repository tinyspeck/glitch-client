package com.tinyspeck.engine.view.ui.store
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.furniture.FurnUpgrade;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.data.store.StoreItem;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.ItemInfoUI;
	import com.tinyspeck.engine.port.QuantityPicker;
	import com.tinyspeck.engine.port.StoreDialog;
	import com.tinyspeck.engine.port.StoreManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.util.URLUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.furniture.FurnIcon;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class StoreBuyUI extends Sprite implements ITipProvider
	{
		private const ICON_WH:uint = 100;
		private const INFO_X:int = 160;
		
		private var item_holder:Sprite = new Sprite();
		
		private var buy_bt:Button;
		private var share_bt:Button;
		private var auction_bt:Button;
		private var qp:QuantityPicker;
		private var icon_view:ItemIconView;
		private var item_info_ui:ItemInfoUI;
		private var model:TSModelLocator;
		private var item_url:URLRequest = new URLRequest();
		
		private var furn_upgrades_holder:Sprite = new Sprite();
		private var furn_upgrades_tf:TextField = new TextField();
		private var you_have_tf:TextField = new TextField();
		private var title_tf:TextField = new TextField();
		private var price_tf:TextField = new TextField();
		private var subscriber_icon:DisplayObject = new AssetManager.instance.assets.furn_subscriber();
		
		private var current_cost:int;
		private var current_count:int;
		private var w:int;
		public var is_single_furniture:Boolean;
		
		public function StoreBuyUI(w:int){
			this.w = w;
			model = TSModelLocator.instance;
			init();
		}
		
		private function init():void {
			//the item info ui
			item_info_ui = new ItemInfoUI(w - INFO_X);
			item_info_ui.x = INFO_X;
			item_info_ui.addEventListener(TSEvent.CHANGED, onItemInfoChanged, false, 0, true);
			addChild(item_info_ui);
			
			//item holder stuff
			item_holder.y = 0;
			var g:Graphics = item_holder.graphics;
			g.beginFill(0xdbdbdb);
			g.drawRoundRect(0, 0, 134, 156, 10);
			g.endFill()
			g.beginFill(0xffffff);
			g.drawRoundRect(1, 1, 132, 154, 10);
			g.endFill()
			addChild(item_holder);
			
			TFUtil.prepTF(price_tf);
			price_tf.width = 134;
			item_holder.addChild(price_tf);
			
			//details title
			TFUtil.prepTF(title_tf);
			title_tf.width = w - INFO_X;
			title_tf.x = INFO_X;
			title_tf.y = item_holder.y - 4;
			addChild(title_tf);
			
			//qty picker
			qp = new QuantityPicker({
				w: 130,
				h: 36,
				name: 'qp',
				minus_graphic: new AssetManager.instance.assets.minus_red(),
				plus_graphic: new AssetManager.instance.assets.plus_green(),
				max_value: 1, // to be changed
				min_value: 1,
				button_wh: 20,
				button_padd: 3,
				x: INFO_X,
				show_all_option: true
			});
			qp.addEventListener(TSEvent.CHANGED, onQuantityChange, false, 0, true);
			addChild(qp);
			
			//buy button
			buy_bt = new Button({
				label: 'Buy',
				name: 'details_buy',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			buy_bt.addEventListener(TSEvent.CHANGED, onBuyClick, false, 0, true);
			addChild(buy_bt);
			
			addChild(furn_upgrades_holder);
			
			TFUtil.prepTF(furn_upgrades_tf, true);
			furn_upgrades_tf.width = 245;
			furn_upgrades_tf.y = item_holder.y + item_holder.height + 6;
			addChild(furn_upgrades_tf);
			
			TFUtil.prepTF(you_have_tf, false);
			you_have_tf.autoSize = TextFieldAutoSize.NONE;
			you_have_tf.width = 134;
			you_have_tf.height = 20;
			you_have_tf.x = 0;
			you_have_tf.y = item_holder.y + item_holder.height + 6;
			addChild(you_have_tf);
			you_have_tf.htmlText = '<p class="store_buy_you_have">You have 0 of these</p>';
			
			//share button
			share_bt = new Button({
				name: 'share',
				label: 'Share link',
				label_size: 11,
				label_bold: true,
				label_c: 0x005c73,
				label_hover_c: 0xd79035,
				label_offset: 1,
				text_align: 'left',
				graphic: new AssetManager.instance.assets.encyclopedia_link(),
				graphic_placement: 'left',
				graphic_padd_l: 1,
				draw_alpha: 0,
				tip: {
					txt: 'Opens in a new window',
					pointer: WindowBorder.POINTER_BOTTOM_CENTER
				}
			});
			share_bt.addEventListener(TSEvent.CHANGED, onEncyclopediaClick, false, 0, true);
			addChild(share_bt);
			
			//auction button
			auction_bt = new Button({
				name: 'auction',
				label: 'Find auctions',
				value: -1,
				label_size: 11,
				label_bold: true,
				label_c: 0x005c73,
				label_hover_c: 0xd79035,
				label_offset: 1,
				text_align: 'left',
				graphic: new AssetManager.instance.assets.info_auction(),
				graphic_placement: 'left',
				graphic_padd_l: 3,
				draw_alpha: 0,
				tip: {
					txt: 'Opens in a new window',
					pointer: WindowBorder.POINTER_BOTTOM_CENTER
				}
			});
			auction_bt.addEventListener(TSEvent.CHANGED, onAuctionClick, false, 0, true);
			addChild(auction_bt);
		}
		
		public function preloadItems(items:Vector.<StoreItem>):void {
			var i:int;
			var item_tsids:Array = new Array();
			
			for(i; i < items.length; i++){
				item_tsids.push(items[int(i)].class_tsid);
			}
			
			item_info_ui.preloadItems(item_tsids);
			item_info_ui.addEventListener(TSEvent.COMPLETE, onPreloadComplete, false, 0, true);
		}
		
		private function onPreloadComplete(event:TSEvent):void {
			item_info_ui.removeEventListener(TSEvent.COMPLETE, onPreloadComplete);
			dispatchEvent(new TSEvent(TSEvent.COMPLETE, event.data));
		}
		
		private var _store_item:StoreItem;
		private var _single_stack_tsid:String;

		public function get item_class():String{
			return (_store_item) ? _store_item.class_tsid : null;
		}
		
		private function getHowManyYouHaveString(item_class:String):String {
			var you_have_str:String = 'You have <b>'+model.worldModel.pc.hasHowManyItems(item_class).toString()+'</b> of these.';
			return you_have_str;
		}
		
		public function updateYouHave():void {
			if (!item_class) return;
			you_have_tf.htmlText = '<p class="store_buy_you_have">'+getHowManyYouHaveString(item_class)+'</p>';
		}
		
		public function updateTitle():void {
			if (!item_class) return;
			var item:Item = model.worldModel.getItemByTsid(item_class);
			var count_str:String = '';
			if ((current_count != 0 && current_count != int.MAX_VALUE) || _store_item.total_quantity) {
				count_str+= '<span class="store_buy_count"><br>';
				if (_store_item.total_quantity) {
					var rem:int = _store_item.total_quantity-_store_item.store_sold;
					count_str+= '<b>'+rem+' left</b> of '+_store_item.total_quantity+' for sale';
				} else {
					count_str+= ''+current_count+' for sale';
				}
				
				count_str+= '</span>';
			}
			
			title_tf.htmlText = '<p class="store_buy_title">'+item.label+count_str+'</p>';
		}
		
		public function refigger(store_item:StoreItem):void {
			if (item_class != store_item.class_tsid) return;
			updateYouHave();
			
			if (store_item.cost != current_cost) {
				var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
				cdVO.title = 'Price changed!'
				cdVO.txt = "The price for this item has just now changed, from <b>"+current_cost+"₡</b> to <b>"+store_item.cost+"₡</b>. I thought you would like to know.";
				cdVO.choices = [
					{value: true, label: 'Thanks!'}
				];
				TSFrontController.instance.confirm(cdVO);
			}
			
			
			current_cost = store_item.cost;
			current_count = store_item.count || int.MAX_VALUE;
			updateTitle();
			updateMax(model.worldModel.pc.stats.currants);
			onQuantityChange();
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if (tip_target == item_holder) {
				
				if (_single_stack_tsid) {
					var itemstack:Itemstack = model.worldModel.getItemstackByTsid(_single_stack_tsid);
					return {
						txt: itemstack.label,
						pointer: WindowBorder.POINTER_BOTTOM_CENTER
					}
				} else if (item_class) {
					var item:Item = model.worldModel.getItemByTsid(item_class);
					return {
						txt: item.label,
						pointer: WindowBorder.POINTER_BOTTOM_CENTER
					}
				}
			}
			
			return null;
		}
		
		public function show(single_stack_tsid:String, store_item:StoreItem):void {
			_store_item = store_item;
			var item:Item = model.worldModel.getItemByTsid(item_class);
			if(!item){
				CONFIG::debugging {
					Console.warn('Funky class_tsid passed in: '+item_class);
				}
				return;
			}
			_single_stack_tsid = single_stack_tsid;
			
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(single_stack_tsid);
			
			updateYouHave();
			
			current_cost = _store_item.cost;
			current_count = _store_item.count || int.MAX_VALUE;
			
			//load the icon
			if(icon_view) {
				icon_view.parent.removeChild(icon_view);
				icon_view.dispose();
			}
			
			var state:Object = null;
			if (itemstack) {
				if (is_single_furniture) {
					state = {config:itemstack.itemstack_state.furn_config, state:'iconic'}
				} else {
					state = {config:itemstack.itemstack_state.config, state:'iconic'}
				}
			}

			icon_view = new ItemIconView(item_class, ICON_WH, state);
			icon_view.mouseEnabled = false;
			icon_view.x = int(item_holder.width/2 - ICON_WH/2);
			icon_view.y = 15;
			item_holder.addChild(icon_view);
			item_holder.addChild(subscriber_icon);
			
			
			TipDisplayManager.instance.registerTipTrigger(item_holder);
			
			subscriber_icon.visible = false;
			subscriber_icon.x = item_holder.width-(subscriber_icon.width+5);
			subscriber_icon.y = (icon_view.y+ICON_WH)-(subscriber_icon.height+5);
			
			//set the title
			updateTitle();
			
			
			
			var current_is_paid_upgrade:Boolean;
			var current_is_sub_upgrade:Boolean;
			
			if (is_single_furniture) {
				item_info_ui.visible = false;
				qp.visible = false;
				you_have_tf.visible = false;
				title_tf.visible = false;
				furn_upgrades_tf.visible = true;
				SpriteUtil.clean(furn_upgrades_holder, true);
				furn_upgrades_holder.visible = true;
				
				share_bt.y = item_holder.y + item_holder.height + 6;
				auction_bt.y = share_bt.y + share_bt.height;
				
				buy_bt.x = INFO_X;
				buy_bt.y = item_holder.y;
				
				furn_upgrades_tf.x = INFO_X;
				furn_upgrades_tf.y = buy_bt.y+buy_bt.height+6;
				
				
				var upgradesV:Vector.<FurnUpgrade> = StoreManager.instance.current_store.single_furniture_upgrades;
				var upgrade_count:int;
				var other_paid_upgrade_count:int;
				var other_sub_upgrade_count:int;
				var fi:FurnIcon;
				var fupgrade:FurnUpgrade;
				var cols:int = 4;
				var col:int;
				var row:int;
				var size:int = 58;
				var padd:int = 5;
				if (upgradesV) {
					for (var i:int=0;i<upgradesV.length;i++) {
						fupgrade = upgradesV[i];
						
						// ignore it if it is the one currently showing!
						if (fupgrade.id == itemstack.furn_upgrade_id) {
							if (fupgrade.credits > 0) {
								current_is_paid_upgrade = true;
							}

							if (fupgrade.subscriber_only) {
								subscriber_icon.visible = true;
								current_is_sub_upgrade = true;
							}
							continue;
						}
						
						if (fupgrade.credits > 0) {
							other_paid_upgrade_count++;
						} else if (fupgrade.subscriber_only) {
							other_sub_upgrade_count++;
						} else {
							continue;
						}
						
						fi = new FurnIcon(size, 4);
						col = (upgrade_count % cols);
						row = Math.floor(upgrade_count / cols);
						fi.x = col*(size+padd);
						fi.y = row*(size+padd);
						
						fi.show(itemstack.class_tsid, fupgrade);
						furn_upgrades_holder.addChild(fi);
						
						upgrade_count++;
					}
					
					if (other_paid_upgrade_count) {
						
						// draw a little box to make sure the furn_upgrades_holder has some padding at the bottom
						var g:Graphics = furn_upgrades_holder.graphics;
						g.clear();
						g.beginFill(0, 0);
						g.drawRect(0, 0, 10, fi.y+size+10);
					
					}
				}
				
				var upgradeTxt:Function = function(c:int):String {
					if (c==1) return 'upgrade';
					return 'upgrades';
				}
				
				var upgrades_txt:String;
				if (current_is_sub_upgrade && !current_is_paid_upgrade) {
					/*
					It is currently upgraded with a free but sub-locked upgrade
						Has 1 or more other paid upgrades AND 1 or more free sub-locked upgrades
						- "This item has X paid upgrades, and Y other subscriber-locked upgrades"
						Has 1 or more other paid upgrades but no other free sub-locked upgrades
						- "This item has X paid upgrades"
						Has no other paid upgrades but has 1 or more other free sub-locked upgrades
						- "This item has Y more subscriber-locked upgrades"
						Has no other paid or sub-locked upgrades
						- "This item has no paid upgrades"
					*/
					if (other_sub_upgrade_count && other_paid_upgrade_count) {
						upgrades_txt = 'This item has '+other_paid_upgrade_count+' paid '+upgradeTxt(other_paid_upgrade_count)
							+' and '+other_sub_upgrade_count+' subscriber-locked '+upgradeTxt(other_sub_upgrade_count)+':';
					} else if (other_paid_upgrade_count) {
						upgrades_txt = 'This item has '+other_paid_upgrade_count+' paid '+upgradeTxt(other_paid_upgrade_count)+':';
					} else if (other_sub_upgrade_count) {
						upgrades_txt = 'This item has '+other_sub_upgrade_count+' other subscriber-locked '+upgradeTxt(other_sub_upgrade_count)+':';
					} else {
						upgrades_txt = 'This item has no paid upgrades';
					}
				} else if (current_is_paid_upgrade) {
					/*
					It is currently upgraded with a paid upgrade (sub-locked or not)
						Has 1 or more other paid upgrades AND 1 or more free sub-locked upgrades
						- "This item has X more paid upgrades, and Y subscriber-locked upgrades"
						Has 1 or more other paid upgrades but no other free sub-locked upgrades
						- "This item has X more paid upgrades"
						Has no other paid upgrades but has 1 or more other free sub-locked upgrades
						- "This item has Y subscriber-locked upgrades"
						Has no other paid or sub-locked upgrades
						- "This item has no other paid upgrades"
					*/
					if (other_sub_upgrade_count && other_paid_upgrade_count) {
						upgrades_txt = 'This item has '+other_paid_upgrade_count+' more paid '+upgradeTxt(other_paid_upgrade_count)
							+' and '+other_sub_upgrade_count+' subscriber-locked '+upgradeTxt(other_sub_upgrade_count)+':';
					} else if (other_paid_upgrade_count) {
						upgrades_txt = 'This item has '+other_paid_upgrade_count+' more paid '+upgradeTxt(other_paid_upgrade_count)+':';
					} else if (other_sub_upgrade_count) {
						upgrades_txt = 'This item has '+other_sub_upgrade_count+' subscriber-locked '+upgradeTxt(other_sub_upgrade_count)+':';
					} else {
						upgrades_txt = 'This item has no other paid upgrades';
					}
				} else {
					/*
					It is not currently upgraded or is upgraded with a free and non-sub-locked upgrade
						Has 1 or more other paid upgrades AND 1 or more free sub-locked upgrades
						- "This item has X paid upgrades, and Y subscriber-locked upgrades upgrades"
						Has 1 or more other paid upgrades but no other free sub-locked upgrades
						- "This item has X paid upgrades"
						Has no other paid upgrades but has 1 or more other free sub-locked upgrades
						- "This item has Y subscriber-locked upgrades"
						Has no other paid or sub-locked upgrades
						- "This item has no paid upgrades"
					*/
					if (other_sub_upgrade_count && other_paid_upgrade_count) {
						upgrades_txt = 'This item has '+other_paid_upgrade_count+' paid '+upgradeTxt(other_paid_upgrade_count)
							+' and '+other_sub_upgrade_count+' subscriber-locked '+upgradeTxt(other_sub_upgrade_count)+':';
					} else if (other_paid_upgrade_count) {
						upgrades_txt = 'This item has '+other_paid_upgrade_count+' paid '+upgradeTxt(other_paid_upgrade_count)+':';
					} else if (other_sub_upgrade_count) {
						upgrades_txt = 'This item has '+other_sub_upgrade_count+' subscriber-locked '+upgradeTxt(other_sub_upgrade_count)+':';
					} else {
						upgrades_txt = 'This item has no paid upgrades';
					}
					
				}
				
				furn_upgrades_tf.htmlText = '<p class="store_buy_furn_upgrades">'+upgrades_txt+'</p>';
				
				furn_upgrades_holder.x = INFO_X;
				furn_upgrades_holder.y = furn_upgrades_tf.y+furn_upgrades_tf.height+3;
				
			} else {
				item_info_ui.visible = true;
				qp.visible = true;
				you_have_tf.visible = true;
				title_tf.visible = true;
				furn_upgrades_tf.visible = false;
				furn_upgrades_holder.visible = false;
				
				share_bt.y = you_have_tf.y + you_have_tf.height+2;
				auction_bt.y = share_bt.y + share_bt.height;
				
				buy_bt.x = INFO_X + qp.width + 5;
				qp.y = title_tf.y + title_tf.height;
				buy_bt.y = qp.y - 1;
			}
			
			//hide auctions until you can view them
			auction_bt.visible = false;
			maybeShowAuctionButton();
			
			//show the price
			price_tf.htmlText = '<p class="store_buy_price">Price '+StringUtil.formatNumberWithCommas(current_cost)+'₡</p>';
			price_tf.y = item_holder.height - price_tf.height - 10;
			
			//set the qp
			qp.value = 1;
			
			//force the button to update
			onQuantityChange();
			updateMax(model.worldModel.pc.stats.currants);
			
			//tuck a reference to the _item_class in the buy button
			buy_bt.value = item_class;
			
			//place the info
			item_info_ui.y = buy_bt.y + buy_bt.height + 10;
			
			addChild(item_info_ui);
			item_info_ui.show(item_class, false);
			item_info_ui.showCurrants(false);
			
			//set the url for when the encyclopedia link is clicked
			item_url.url = model.flashVarModel.root_url+'item.php?tsid='+item.tsid;
			
			
			//listen for stat updates (currants)
			model.worldModel.registerCBProp(onStatsChanged, "pc", "stats");
		}
		
		private function maybeShowAuctionButton():void {
			//if this item is good for auctions, let's show it
			if (!item_class) return;
			var item:Item = model.worldModel.getItemByTsid(item_class);
			if (!item) return;
			if (!item.details) return;
			
			if (item.is_auctionable) {
				auction_bt.value = item.details.item_url_part;
				auction_bt.visible = true;
			}
		}
		
		public function hide():void {
			//remove the item info since it'll cause the scroll
			if(contains(item_info_ui)) removeChild(item_info_ui);
			
			//listen for stat updates (currants)
			model.worldModel.unRegisterCBProp(onStatsChanged, "pc", "stats");
		}
		
		private function onItemInfoChanged(event:TSEvent):void {
			maybeShowAuctionButton();
			
			dispatchEvent(new TSEvent(TSEvent.CHANGED, event.data));
		}
		
		private function onQuantityChange(event:TSEvent = null):void {
			if (is_single_furniture) {
				buy_bt.label = 'Buy it for '+StringUtil.formatNumberWithCommas(qp.value*current_cost)+
					'<font size="13">₡</font>';
			} else {
				buy_bt.label = 'Buy: '+StringUtil.formatNumberWithCommas(qp.value)+
					' for '+StringUtil.formatNumberWithCommas(qp.value*current_cost)+
					'<font size="13">₡</font>';
			}
		}
		
		private function onStatsChanged(pc_stats:PCStats):void {
			updateMax(pc_stats.currants);
		}
		
		private function updateMax(currants:int):void {
			// qp.disabled does not seem to actually do anything :l
			if (_store_item.total_quantity && !_store_item.count) {
				qp.max_value = 1;
				qp.disabled = true;
				buy_bt.disabled = true;
				buy_bt.tip = { txt: "We're all out!", pointer: WindowBorder.POINTER_BOTTOM_CENTER }
			} else {
				var max:int = Math.min(Math.floor(currants/current_cost), current_count);
				if(max > 0){
					qp.disabled = false;
					qp.max_value = Math.min(max, model.flashVarModel.max_buy_override ? model.flashVarModel.max_buy_override : 999);
					buy_bt.disabled = false;
					buy_bt.tip = null;
				}
				else {
					qp.disabled = true;
					qp.max_value = 1;
					buy_bt.disabled = true;
					buy_bt.tip = { txt: "You don't have enough currants!", pointer: WindowBorder.POINTER_BOTTOM_CENTER }
				}
			}
		}
		
		private function onEncyclopediaClick(event:TSEvent):void {
			//what happens when we click a link
			navigateToURL(item_url, URLUtil.getTarget("iteminfo"));
		}
		
		private function onAuctionClick(event:TSEvent):void {
			TSFrontController.instance.openAuctionsPage(null, auction_bt.value);
		}
		
		private function onBuyClick(event:TSEvent):void {
			if(buy_bt.disabled) return;
			
			buy_bt.disabled = true;
			
			StoreManager.instance.waiting_on_buy = true;
			StoreManager.instance.buyItems(qp.value, buy_bt.value, current_cost, buyCheck);
		}
		
		private function buyCheck(rm:NetResponseMessageVO):void {
			StoreManager.instance.waiting_on_buy = false;
			buy_bt.disabled = false;
			
			if(rm.success){
				//can they buy more?
				//onStatsChanged(model.worldModel.pc.stats);
				
				//throw them back to the main buy UI
				StoreDialog.instance.buySuccess();
			}
			else {
				StoreDialog.instance.buyFailure((rm.payload.error && rm.payload.error.msg) ? rm.payload.error.msg : null);
				//looks like the server often populates a message already
				//model.activityModel.growl_message = 'Something happened with your purchase. Try again won\'t you?';
			}
		}
	}
}