package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.store.Store;
	import com.tinyspeck.engine.data.store.StoreItem;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingStoreBuyVO;
	import com.tinyspeck.engine.net.NetOutgoingStoreSellCheckVO;
	import com.tinyspeck.engine.net.NetOutgoingStoreSellVO;

	public class StoreManager
	{
		/* singleton boilerplate */
		public static const instance:StoreManager = new StoreManager();
		
		public var legacy_store_ob:Object;
		
		private var store_tsid:String;
		private var _current_store:Store;
		private var model:TSModelLocator;
		private var verb:String;
		
		public function StoreManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			model = TSModelLocator.instance;
		}
		
		public function end():void {
			_current_store = null;
			store_tsid = null;
			verb = null;
		}
		
		public var waiting_on_buy:Boolean;
		public function changed(payload:Object):void {
			// do we even care?
			if (!_current_store) return;
			if (!store_tsid) return;
			if (payload.item_tsid != store_tsid) return;
			
			var store:Store;
			if (payload.store && payload.store.items) {
				store = Store.fromAnonymous(payload.store, payload.item_tsid);
			}
			
			// no more selling?
			if (!store || !store.items || !store.items.length) {
				if (!waiting_on_buy) {
					var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
					cdVO.title = 'Store Closed!'
					cdVO.txt = "This store has closed down, either on the owner's whim, or because of lack of inventory.";
					cdVO.choices = [
						{value: true, label: 'Thanks, I guess'}
					];
					TSFrontController.instance.confirm(cdVO);
				}
				
				StoreDialog.instance.end(true);
				return;
			}
			
			// ok, the store still exists but has changed inventory or prices. We need to do the smart stuff.
			
			var i:int=0;
			var store_item:StoreItem;
			var old_store_item:StoreItem;
			for (i;i<store.items.length;i++) {
				store_item = store.items[i];
				old_store_item = _current_store.getStoreItemByItemClass(store_item.class_tsid);
				if (!old_store_item) {
					;// a new item! We are not yet handling this TODO
					CONFIG::debugging {
						Console.info(store_item.class_tsid+' has been added to the store');
					}
				} else {
					// has it changed?
					if (store_item.cost != old_store_item.cost) {
						// price has changed
						CONFIG::debugging {
							Console.info(store_item.class_tsid+' has changed cost:'+old_store_item.cost+'->'+store_item.cost);
						}
						old_store_item.cost = store_item.cost;
						StoreDialog.instance.onPriceChanged(store_item.class_tsid);
					}
					if (store_item.count != old_store_item.count) {
						// quantity
						CONFIG::debugging {
							Console.info(store_item.class_tsid+' has changed count:'+old_store_item.count+'->'+store_item.count);
						}
						old_store_item.count = store_item.count;
						StoreDialog.instance.onQuantityChanged(store_item.class_tsid);
					}
				}
			}
			
			for (i;i<_current_store.items.length;i++) {
				old_store_item = _current_store.items[i];
				store_item = store.getStoreItemByItemClass(old_store_item.class_tsid);
				if (!store_item) {
					;// an item has been removed! We are not yet handling this  TODO
					CONFIG::debugging {
						Console.info(old_store_item.class_tsid+' has been removed from the store');
					}
				}
			}
			
		}
		
		public function start(payload:Object):void {
			//make sure we have the store TSID
			if(!payload.item_tsid){
				CONFIG::debugging {
					Console.warn('Store missing item_tsid!');
				}
				return;
			}
			else if(!model.worldModel.getItemstackByTsid(payload.item_tsid)){
				CONFIG::debugging {
					Console.warn('store_start was sent, but there is no itemstack with the TSID: '+payload.item_tsid);
				}
				return;
			}
			else if(!payload.verb){
				CONFIG::debugging {
					Console.warn('Store missing a verb!');
				}
				return;
			}
			
			//set the store's TSID
			store_tsid = payload.item_tsid;
			
			//set the store's verb AKA name of store
			verb = payload.verb;
			
			//make sure that we have stuff to sell
			if(payload.store && payload.store.items){
				_current_store = Store.fromAnonymous(payload.store, store_tsid);
				
				//support embeded stores, legacy for now
				if(payload.location_rect){
					legacy_store_ob = model.worldModel.getItemstackByTsid(store_tsid).store_ob = payload;
					
					// store items as itemsA
					var A:Array = legacy_store_ob.store.itemsA = payload.store.items;
					// create a hash
					var Ob:Object = legacy_store_ob.store.items = {};
					// build the hash
					for (var i:int=0;i<A.length;i++) {
						Ob[A[int(i)].class_tsid] = {cost:A[int(i)].cost}
					}
					
					StoreEmbed.instance.startWithTsid(store_tsid);
				}
				//open the dialog
				else {
					StoreDialog.instance.start();
				}
			}
			else {
				CONFIG::debugging {
					Console.warn('There are no items in this store!');
				}
				showError('There is nothing for sale in this store, maybe try another one?');
			}
		}
		
		public function checkItemPrice(itemstack:Itemstack, callback:Function):void {			
			TSFrontController.instance.genericSend(new NetOutgoingStoreSellCheckVO(
				store_tsid,
				verb,
				itemstack.tsid,
				itemstack.class_tsid
			), callback, callback);
		}
		
		public function sellItems(amount:int, class_tsid:String, itemstack_tsid:String, callback:Function):void {
			TSFrontController.instance.genericSend(new NetOutgoingStoreSellVO(
				store_tsid,
				verb,
				itemstack_tsid,
				class_tsid,
				amount
			), callback, callback);
		}
		
		public function buyItems(amount:int, class_tsid:String, price:int, callback:Function):void {			
			TSFrontController.instance.genericSend(new NetOutgoingStoreBuyVO(
				store_tsid,
				verb,
				class_tsid,
				amount,
				price
			), callback, callback);
		}
		
		private function showError(txt:String):void {
			model.activityModel.growl_message = txt;
		}
		
		public function get current_store():Store { return _current_store; }
	}
}