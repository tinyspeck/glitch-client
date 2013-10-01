package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ActionRequest;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.FurnitureConfig;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.net.NetOutgoingTradeAcceptVO;
	import com.tinyspeck.engine.net.NetOutgoingTradeAddItemVO;
	import com.tinyspeck.engine.net.NetOutgoingTradeCancelVO;
	import com.tinyspeck.engine.net.NetOutgoingTradeChangeItemVO;
	import com.tinyspeck.engine.net.NetOutgoingTradeCurrantsVO;
	import com.tinyspeck.engine.net.NetOutgoingTradeRemoveItemVO;
	import com.tinyspeck.engine.net.NetOutgoingTradeUnlockVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.chat.ChatArea;
	import com.tinyspeck.engine.view.ui.chat.ChatElement;
	import com.tinyspeck.engine.view.ui.chat.InputField;

	/*
	{
	type: 'trade_start',
	tsid: 'PM001'
	}
	*/
	
	public class TradeManager
	{	/* singleton boilerplate */
		public static const instance:TradeManager = new TradeManager();
		
		public static const TRADE_TAGS_TO_EXCLUDE:Array = ['no_trade'];
		
		public var player_tsid:String;
		public var item_tsid:String;
		public var itemstack_tsid:String;
		public var item_count:int;
		public var currants:int;
		
		private var current_itemstack_tsid:String;
		private var current_itemstack_tsids:Array;
		private var current_add_count:int;
		private var current_got_count:int;
		private var current_total_count:int;
		
		public function TradeManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			//listen to the trade dialog for any chat happenings
			TradeDialog.instance.addEventListener(TSEvent.MSG_SENT, onChatSend, false, 0, true);
		}
		
		public function start(payload:Object):Boolean {			
			if(payload.error){
				showError(payload.error.msg);
				CONFIG::debugging {
					Console.warn('trade start failed!');
				}
				return false;
			}
			
			//set the player tsid
			if (payload.tsid) player_tsid = payload.tsid;
						
			if(player_tsid){
				if(TradeDialog.instance.parent) TradeDialog.instance.end(true);
				TradeDialog.instance.start();
				
				//if we have a single itestack to add, do that
				if(itemstack_tsid && TSModelLocator.instance.worldModel.getItemstackByTsid(itemstack_tsid).count == item_count){
					clientAddItem(itemstack_tsid, item_count);
				}
				//add multiple items
				else if(item_tsid){
					const pc:PC = TSModelLocator.instance.worldModel.pc;
					if(pc) clientAddMultipleItems(pc.getItemstackTsidsFromNeeded(item_tsid, item_count, TradeDialog.MAX_TRADE_SLOTS), item_count);
				}
				
				//null out the item/count now that we've started
				item_tsid = null;
				itemstack_tsid = null;
				item_count = 0;
				currants = 0;
				
				return true;
			}

			CONFIG::debugging {
				Console.warn('start missing player tsid');
			}
			return false;
		}
		
		/************ 
		 * ADD ITEM *
		 ************/
		public function serverAddItem(payload:Object):void {
			if(payload.error){
				showError(payload.error.msg);
				CONFIG::debugging {
					Console.warn('server add item went horribly wrong for some reason');
				}
				return;
			}
			
			if(payload.tsid){
				//other player is putting an item in the window
				var furn_config:FurnitureConfig = (payload.config && payload.config.furniture) ? FurnitureConfig.fromAnonymous(payload.config.furniture, '') : null
				TradeDialog.instance.addItem(
					'right',
					payload.itemstack_class,
					payload.amount,
					payload.slot,
					payload.label,
					payload.tool_state,
					furn_config
				);
			}
		}
		
		public function clientAddItem(itemstack_tsid:String, count:int):void {
			current_itemstack_tsid = itemstack_tsid;
			current_add_count = count;
			TSFrontController.instance.genericSend(new NetOutgoingTradeAddItemVO(player_tsid, itemstack_tsid, count), onAddItem, onAddItem);
		}
		
		private function onAddItem(nrm:NetResponseMessageVO):void {
			//unlock if we had an error
			if(nrm.payload.error){
				TradeDialog.instance.unlockSide('left', false);
				CONFIG::debugging {
					Console.warn('client add item went horribly wrong for some reason');
				}
				return;
			}
			
			//add the info to the chat window
			if(current_itemstack_tsid){
				const itemstack:Itemstack = TSModelLocator.instance.worldModel.getItemstackByTsid(current_itemstack_tsid);
				const item:Item = itemstack ? TSModelLocator.instance.worldModel.getItemByTsid(itemstack.class_tsid) : null;
				if(itemstack && item){
					TradeDialog.instance.addItem(
						'left',
						itemstack.class_tsid,
						current_add_count,
						itemstack.slot,
						itemstack.count != 1 ? item.label_plural : item.label,
						itemstack.tool_state
					);
				}
			}
			
			//got any more?
			addNextItem();
		}
		
		public function clientAddMultipleItems(itemstack_tsids:Array, total_count:int):void {
			if(!itemstack_tsids) return;
			current_total_count = total_count;
			current_got_count = 0;
			
			//start off the action to add items
			current_itemstack_tsids = itemstack_tsids;
			addNextItem();
		}
		
		private function addNextItem():void {
			//if we have more to add, go do it!
			if(current_itemstack_tsids && current_itemstack_tsids.length && current_got_count < current_total_count){
				const itemstack:Itemstack = TSModelLocator.instance.worldModel.getItemstackByTsid(current_itemstack_tsids.shift());
				
				//add it
				clientAddItem(itemstack.tsid, Math.min(itemstack.count, current_total_count-current_got_count));
				current_got_count += itemstack.count;
			}
		}
		
		/*************** 
		 * CHANGE ITEM *
		 ***************/
		public function serverChangeItem(payload:Object):void {
			if(payload.error){
				showError(payload.error.msg);
				CONFIG::debugging {
					Console.warn('server change item went horribly wrong for some reason');
				}
				return;
			}
			
			if(payload.tsid){
				//other player is changing an item in the window
				TradeDialog.instance.changeItem('right', payload.itemstack_class, payload.amount, payload.slot, payload.label);
			}
		}
		
		public function clientChangeItem(itemstack_tsid:String, count:int):void {
			current_itemstack_tsid = itemstack_tsid;
			TSFrontController.instance.genericSend(new NetOutgoingTradeChangeItemVO(player_tsid, itemstack_tsid, count), onChangeItem, onChangeItem);
		}
		
		private function onChangeItem(nrm:NetResponseMessageVO):void {
			//client changes items instantly to avoid hang times, so this is only here to report errors
			if(nrm.payload.error){
				TradeDialog.instance.unlockSide('left', false);
				CONFIG::debugging {
					Console.warn('client change item went horribly wrong for some reason');
				}
				return;
			}
			
			//add the info to the chat window
			if(current_itemstack_tsid){
				const itemstack:Itemstack = TSModelLocator.instance.worldModel.getItemstackByTsid(current_itemstack_tsid);
				const item:Item = itemstack ? TSModelLocator.instance.worldModel.getItemByTsid(itemstack.class_tsid) : null;
				if(itemstack && item){
					TradeDialog.instance.changeItem('left', itemstack.class_tsid, itemstack.count, itemstack.slot, itemstack.count != 1 ? item.label_plural : item.label);
				}
			}
		}
		
		/*************** 
		 * REMOVE ITEM *
		 ***************/
		public function serverRemoveItem(payload:Object):void {
			if(payload.error){
				showError(payload.error.msg);
				CONFIG::debugging {
					Console.warn('server remove item went horribly wrong for some reason');
				}
				return;
			}
			
			if(payload.tsid){
				//other player is removing an item in the window
				TradeDialog.instance.removeItem('right', payload.itemstack_class, payload.amount, payload.slot, payload.label);
			}
		}
		
		public function clientRemoveItem(itemstack_tsid:String, count:int):void {
			current_itemstack_tsid = itemstack_tsid;
			TSFrontController.instance.genericSend(new NetOutgoingTradeRemoveItemVO(player_tsid, itemstack_tsid, count), onRemoveItem, onRemoveItem);
		}
		
		private function onRemoveItem(nrm:NetResponseMessageVO):void {
			//removes the item and unlocks if there was an error
			if(nrm.payload.error){
				TradeDialog.instance.unlockSide('left', false);
				CONFIG::debugging {
					Console.warn('client remove item went horribly wrong for some reason');
				}
				return;
			}
			
			//add the info to the chat window
			if(current_itemstack_tsid){
				const itemstack:Itemstack = TSModelLocator.instance.worldModel.getItemstackByTsid(current_itemstack_tsid);
				const item:Item = itemstack ? TSModelLocator.instance.worldModel.getItemByTsid(itemstack.class_tsid) : null;
				if(itemstack && item){
					TradeDialog.instance.removeItem('left', itemstack.class_tsid, itemstack.count, itemstack.slot, itemstack.count != 1 ? item.label_plural : item.label);
				}
			}
		}
		
		/************ 
		 * CURRANTS *
		 ************/
		public function serverCurrants(payload:Object):void {
			if(payload.error){
				CONFIG::debugging {
					showError(payload.error.msg);
					Console.warn('server currants went horribly wrong for some reason');
				}
				return;
			}
			
			if(payload.tsid){
				//other player is giving currants
				TradeDialog.instance.currants('right', payload.amount);
				return;
			}
		}
		
		public function clientCurrants(amount:int):void {
			TSFrontController.instance.genericSend(new NetOutgoingTradeCurrantsVO(player_tsid, amount), onCurrants, onCurrants);
		}
		
		private function onCurrants(nrm:NetResponseMessageVO):void {
			if(nrm.payload.error){
				TradeDialog.instance.currants('left', 0);
				CONFIG::debugging {
					Console.warn('client currants went horribly wrong for some reason');
				}
				return;
			}
			
			//re-enable the stuff
			TradeDialog.instance.offer_bt.disabled = false;
			TradeDialog.instance.currants('left', -1); //-1 means everything is kosher
		}
		
		/********** 
		 * CANCEL *
		 **********/
		public function serverCancel(payload:Object):void {
			if(payload.error){
				showError(payload.error.msg);
				CONFIG::debugging {
					Console.warn('server cancel went horribly wrong for some reason');
				}
				return;
			}
			
			player_tsid = null;
			
			if(payload.tsid){
				//other player canceled
				TradeDialog.instance.end(true);
			}
		}
		
		public function clientCancel():void {
			TSFrontController.instance.genericSend(new NetOutgoingTradeCancelVO(player_tsid), onCancel, onCancel);
		}
		
		private function onCancel(nrm:NetResponseMessageVO):void {
			if(nrm.payload.error){
				TradeDialog.instance.unlockSide('left', false);
				CONFIG::debugging {
					Console.warn('client cancel went horribly wrong for some reason');
				}
				return;
			}
			
			player_tsid = null;
			
			TradeDialog.instance.end(true);
		}
		
		/********** 
		 * ACCEPT *
		 **********/
		public function serverAccept(payload:Object):void {
			if(payload.error){
				showError(payload.error.msg);
				CONFIG::debugging {
					Console.warn('server accept went horribly wrong for some reason');
				}
				return;
			}
			
			if(payload.tsid){
				//other player has proposed a trade
				TradeDialog.instance.lockSide('right');
				return;
			}
		}
		
		public function clientAccept():void {
			TSFrontController.instance.genericSend(new NetOutgoingTradeAcceptVO(player_tsid), onAccept, onAccept);
		}
		
		private function onAccept(nrm:NetResponseMessageVO):void {
			if(nrm.payload.error){
				TradeDialog.instance.unlockSide('left', false);
				CONFIG::debugging {
					Console.warn('client accept went horribly wrong for some reason');
				}
				return;
			}
			
			TradeDialog.instance.offer_bt.disabled = false;
			
			//lock our side
			TradeDialog.instance.lockSide('left');
		}
		
		/********** 
		 * UNLOCK *
		 **********/
		public function serverUnlock(payload:Object):void {
			//the server wants to unlock the other person trading
			if(payload.error){
				showError(payload.error.msg);
				CONFIG::debugging {
					Console.warn('server unlock went horribly wrong for some reason');
				}
				return;
			}
			
			//unlock the right side of the trade window
			if(payload.tsid){
				TradeDialog.instance.unlockSide('right');
			}
		}
		
		public function clientUnlock():void {
			//send the request to the server for an unlock
			TSFrontController.instance.genericSend(new NetOutgoingTradeUnlockVO(player_tsid), onUnlock, onUnlock);
		}
		
		private function onUnlock(nrm:NetResponseMessageVO):void {
			if(nrm.payload.error){
				TradeDialog.instance.unlockSide('left', false);
				CONFIG::debugging {
					Console.warn('client unlocking went horribly wrong for some reason');
				}
				return;
			}
			
			//unlock our side
			TradeDialog.instance.unlockSide('left');
		}
		
		/************ 
		 * COMPLETE *
		 ************/
		public function serverComplete(payload:Object):void {			
			//tell the dialog to be complete
			TradeDialog.instance.complete();
		}
		
		/******** 
		 * CHAT *
		 ********/
		private function onChatSend(event:TSEvent):void {
			if(!player_tsid) return;
			
			const input_field:InputField = event.data as InputField;
			
			//send this off to the server
			RightSideManager.instance.sendToServer(player_tsid, input_field.text, false);
			input_field.text = '';
		}
		
		/**********************************************
		 * LOCAL TRADE
		 * tsid when is_buy is true is the class_tsid, 
		 * otherwise it's an itemstack_tsid
		 **********************************************/
		public function localAnnounce(is_buy:Boolean, tsid:String, count:int, currants:int, callback_function:Function):void {
			const world:WorldModel = TSModelLocator.instance.worldModel;
			if(!world) return;
			
			//see if anyone is around to hear this
			if(world.areYouAloneInLocation()){
				showError('Wait until there\'s someone around to hear your offer before you make it!');
				const nrm:NetResponseMessageVO = new NetResponseMessageVO();
				nrm.success = false;
				callback_function(nrm);
				return;
			}
			
			//build a broadcast
			const item:Item = is_buy ? world.getItemByTsid(tsid) : world.getItemByItemstackId(tsid);
			const itemstack:Itemstack = is_buy ? null : world.getItemstackByTsid(tsid);
			
			if(world.pc && item){
				const label:String = count != 1 ? count+' '+item.label_plural : item.label;
				var extra_label:String = '';
				if(itemstack && itemstack.tool_state && itemstack.tool_state.points_capacity > 0) {
					extra_label = '&nbsp;('+itemstack.tool_state.points_remaining+'/'+itemstack.tool_state.points_capacity+')';
				}
				const value:String = createTradeLink(item.tsid, count, is_buy ? -1 : currants, is_buy ? currants : -1);
				const txt:String = 'wants to '+(is_buy ? 'buy' : 'sell')+
								   (count == 1 ? ' '+StringUtil.aOrAn(item.label) : '')+
								   ' <b>'+label+extra_label+'</b>'+
								   (currants ? ' for <b>'+CurrencyInput.CURRANCY_SYMBOL+StringUtil.formatNumberWithCommas(currants)+'</b>' : '')+
								   '.';
				const client_link:String = RightSideManager.instance.createClientLink(txt, label, TSLinkedTextField.LINK_ITEM+'|'+item.tsid+'|'+label);
				
				ActionRequestManager.instance.create(world.pc.tsid, TSLinkedTextField.LINK_TRADE, value, client_link, callback_function);
			}
		}
		
		public function localUpdate(is_cancel:Boolean):void {
			//we are either editing or canceling the local trade, so handle that
			if(is_cancel){					
				//server needs to know
				const value:String = RightSideManager.instance.request_event_tsid;
				if(value){
					//empty out any vars we've saved
					item_tsid = null;
					itemstack_tsid = null;
					item_count = 0;
					currants = 0;
					
					//send it off to the server
					ActionRequestManager.instance.cancel(
						ActionRequest.fromAnonymous({
							event_type:TSLinkedTextField.LINK_TRADE, 
							event_tsid:value
						})
					);
				}
			}
			else {
				const chat_area:ChatArea = RightSideManager.instance.right_view.getChatArea(ChatArea.NAME_LOCAL);
				if(chat_area){
					//edit mode
					chat_area.localTradeEdit();
				}
			}			
		}
		
		/*********************************
		 * CREATE / PARSE COMPOUND LINKS *
		 *********************************/
		public function createTradeLink(item_class_tsid:String, item_count:int, sell_currants:int = 0, buy_currants:int = 0):String {
			return item_class_tsid+'#'+item_count+'#'+sell_currants+'#'+buy_currants;
		}
		
		public function parseTradeLink(str:String):Boolean {
			//[0] - item_class_tsid
			//[1] - count
			//[2] - sell_currants (displays -1 when in buy mode)
			//[3] - buy_currants (displays -1 when in sell mode)
			//[4] - action request uid
			const chunks:Array = str.split('#');
			
			//if we have any chunks, set them for the dialog
			if(chunks.length){					
				const pc:PC = TSModelLocator.instance.worldModel.pc;
				const pc_currants:int = pc && pc.stats ? pc.stats.currants : 0;
				
				//let's make sure they have enough before going on
				if(chunks[3] >= 0){
					const has_how_many:int = pc ? pc.hasHowManyItems(chunks[0]) : 0;
					if(!has_how_many){
						showError('You don\'t have that item to trade!');
						return false;
					}
					
					//set them up for when the dialog starts
					item_tsid = chunks[0];
					item_count = chunks[1];
					currants = 0;
				}
				
				//make sure they have enough currants if someone is selling
				if(chunks[2] >= 0){
					if(pc_currants < chunks[2]){
						showError('You don\'t have enough currants!');
						return false;
					}
					
					currants = chunks[2];
				}
			}
			
			return true;
		}
		
		/******** 
		 * MISC *
		 ********/
		
		private function showError(txt:String):void {
			TSModelLocator.instance.activityModel.growl_message = txt;
			TSModelLocator.instance.activityModel.activity_message = Activity.fromAnonymous({txt: txt});
			TradeDialog.instance.addChatElement(WorldModel.NO_ONE, txt, ChatElement.TYPE_ACTIVITY);
		}
	}
}