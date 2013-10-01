package com.tinyspeck.engine.util {
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingInventoryDragTargetsVO;
	import com.tinyspeck.engine.net.NetOutgoingLocationDragTargets;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.port.Cursor;
	import com.tinyspeck.engine.port.ShrineDonateDialog;
	import com.tinyspeck.engine.port.ShrineManager;
	import com.tinyspeck.engine.view.PCView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.ui.garden.GardenPlotView;

	public class DragVO {
		
		public static const vo:DragVO = new DragVO();
		
		public var target:IDragTarget;
		public var receptive_bag_tsidsA:Array = [];
		public var receptive_bags:Object = {};
		public var receptive_cabinets:Object = {};
		public var receptive_location_itemstacks:Object = {};
		public var receptive_location_items:Object = {};
		public var receptive_inventory_itemstacks:Object = {};
		public var receptive_inventory_items:Object = {};
		public var dragged_itemstack:Itemstack;
		public var proxy_item_class:Item;
		public var drag_tip:String;
		public var can_drop:Boolean;
		public var furniture_offset_y:int;
		
		public function DragVO() {}
		
		public function clear():void {
			target = null;
			receptive_bags = {};
			receptive_cabinets = {};
			receptive_location_itemstacks = {};
			receptive_location_items = {};
			receptive_inventory_itemstacks = {};
			receptive_inventory_items = {};
			dragged_itemstack = null;
			proxy_item_class = null;
			drag_tip = '';
			can_drop = false;
			furniture_offset_y = 0;
		}
		
		public function setReceptiveLocationItemstacksForDrag(after_func:Function=null):void {
			TSFrontController.instance.genericSend(
				new NetOutgoingLocationDragTargets(vo.dragged_itemstack.tsid),
				function(rm:NetResponseMessageVO):void {
					if (rm.success && rm.payload) {
						if (rm.payload.itemstacks) vo.receptive_location_itemstacks = rm.payload.itemstacks;
						if (rm.payload.items) vo.receptive_location_items = rm.payload.items;
						if (rm.payload.cabinets_new) vo.receptive_cabinets = rm.payload.cabinets_new;
						
						vo.can_drop = rm.payload.can_drop;

						// special animation for brush dragging
						if (dragged_itemstack && dragged_itemstack.class_tsid == 'fox_brush' && vo.receptive_location_items['npc_fox']) {
							Cursor.instance.startedDraggingBrushToFox();
						}
						
						//go do shrine things
						getShrineFavorStatus(after_func);
					}
				},
				function(rm:NetResponseMessageVO):void {
					
				}
			);
		}
		
		private function getShrineFavorStatus(after_func:Function=null):void {
			var model:TSModelLocator = TSModelLocator.instance;
			
			if (!vo.receptive_location_itemstacks) return;

			for (var tsid:String in vo.receptive_location_itemstacks) {
				CONFIG::debugging {
					Console.info(tsid);
				}
				var itemstack:Itemstack = model.worldModel.getItemstackByTsid(tsid);
				if (!itemstack) return;
				if (itemstack.item.is_shrine && !ShrineDonateDialog.instance.parent) {
					//go make the request to get the favor
					ShrineManager.instance.favorRequest(tsid, dragged_itemstack.class_tsid, false, after_func);
				}
			}
		}
		
		public function setReceptiveInventoryItemstacksAndBags(after_func:Function):void {
			TSFrontController.instance.genericSend(
				new NetOutgoingInventoryDragTargetsVO(vo.dragged_itemstack.tsid),
				function(rm:NetResponseMessageVO):void {
					if (rm.success && rm.payload) {
						if (rm.payload.itemstacks) vo.receptive_inventory_itemstacks = rm.payload.itemstacks;
						if (rm.payload.items) vo.receptive_inventory_items = rm.payload.items;
						if (rm.payload.bags_new) vo.receptive_bags = rm.payload.bags_new;
						
						if (after_func != null) {
							after_func();
						}
					}
				},
				function(rm:NetResponseMessageVO):void {
					CONFIG::debugging {
						Console.warn('FAIL');
					}
				}
			);
		}
		
		
		
		public function findDragTargetForStack():IDragTarget {
			var game_renderer:LocationRenderer = TSFrontController.instance.getMainView().gameRenderer;
			
			if (!game_renderer.accepting_drags) return null;
			
			var lis_view:LocationItemstackView;
			var plot_view:GardenPlotView;
			var plot_viewsV:Vector.<GardenPlotView>;
			var itemstack:Itemstack;
			var item:Item;
			var pc_view:PCView;
			var i:int;
			
			// because we don't want any of these specific drag targets when decorating!
			// NOT DOING THIS NO MORE SO WE CAN DRAG TO SDBs IN DECO MODE
			/*
			if (model.stateModel.decorator_mode) {
			return null;
			}
			*/
			
			/*CONFIG::debugging {
			Console.trackValue(' LIH.fdt', vo.dragged_itemstack.item.tsid+' g:'+vo.dragged_itemstack.item.giveable);
			}*/
			
			//pcs (uncomment the is_trophy check if myles cannot remove the 'g':'give' in the trophies itemDef in login_start
			if (!TSModelLocator.instance.stateModel.decorator_mode && vo.dragged_itemstack.item.giveable/* && !vo.dragged_itemstack.is_trophy*/) {
				for (i=0;i< game_renderer.pc_viewV.length;i++) {
					pc_view = game_renderer.pc_viewV[int(i)];
					if (pc_view.testHitTargetAgainstNativeDO(Cursor.instance.drag_DO)) {
						return pc_view;
					}
				}
			}
			
			//location itemstacks
			for (i=0;i<game_renderer.lis_viewV.length;i++) {
				lis_view = game_renderer.lis_viewV[int(i)];
				
				// this should never be the case, but just in case...
				if (lis_view.tsid == dragged_itemstack.tsid) {
					continue;
				}
				
				itemstack = lis_view.itemstack
				item = itemstack.item;
				
				// if it has a garden view, hittest the plots
				if (lis_view.garden_view) {
					plot_viewsV = lis_view.garden_view.getPlotViews();
					for (var m:int=0;m<plot_viewsV.length;m++) {
						plot_view = plot_viewsV[m];
						if (plot_view.hitTestObject(Cursor.instance.drag_DO)) {
							//GardenPlotView handles how to handle this
							return plot_view;
						}
					}
					
					// it had a garden view, and dragged thing was not over any plots, so move on to new lis_view
					continue;
				}
				
				var ob:Object = vo.receptive_location_items[item.tsid]; // is it a target by virtue of class?
				if (!ob) ob = vo.receptive_location_itemstacks[itemstack.tsid]; // if not, is it a target by stack tsid?
				
				//if it's a cabinet and is also in our list of receptive things, do it up
				
				if (!ob && vo.receptive_cabinets[itemstack.tsid]){
					ob = vo.receptive_cabinets[itemstack.tsid];
				}
				
				if (!ob) continue; // it is not a target!
				
				if (lis_view.hitTestObject(Cursor.instance.drag_DO)) {
					return lis_view;
				}
			}
			return null;
		}	
		
	}
}