package com.tinyspeck.engine.pack {
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.StateModel;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.port.Cursor;
	import com.tinyspeck.engine.port.MailDialog;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.port.TSSprite;
	import com.tinyspeck.engine.port.TradeDialog;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.DragVO;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.itemstack.FurnitureBagItemstackView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.chat.ChatArea;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;

	public class FurnitureBagUI extends BagUI {
		
		/* singleton boilerplate */
		public static const instance:FurnitureBagUI = new FurnitureBagUI();
		
		private const FBIV_SIZE:int = 70; // this size makes sure that exactly one row is visible at the smallest window size
		
		private var dragged_fbis_view:FurnitureBagItemstackView;
		
		public function FurnitureBagUI() {			
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		override protected function buildBase():void {			
			//filter buttons (using a special one that handles furniture)
			bag_filter = new FurnitureBagFilterUI();
			
			//mouse stuff
			this.addEventListener(MouseEvent.CLICK, _clickHandler, false, 0, true);
			this.addEventListener(MouseEvent.MOUSE_DOWN, _mouseDownHandler, false, 0, true);
			
			//build out the rest
			super.buildBase();
			
			//populate the furniture
			var itemstack:Itemstack;
			for (var tsid:String in model.worldModel.pc.itemstack_tsid_list) {
				itemstack = model.worldModel.getItemstackByTsid(tsid);
				
				if (!itemstack) {
					CONFIG::debugging {
						Console.error(tsid +' not an itemstack??');
					}
					continue;
				}
				
				if (itemstack.container_tsid == model.worldModel.pc.furniture_bag_tsid) {
					addFurnitureItemstack(itemstack);
				}
			}
			
			//tell the scroller how big things are
			scroll_pager.element_width = FBIV_SIZE + BUTTON_PADD;
		}
		
		override protected function buildPanes():void {
			const panesA:Array = model.decorateModel.furniture_panesA;
			
			var id:String;
			var pane_sp:Sprite;
			var i:int;
			
			for(i; i < panesA.length; i++) {
				id = panesA[i].id;
				pane_sp = new Sprite();
				pane_sp.name = id;
				content_panes[id] = pane_sp;
			}
		}
		
		override protected function reflowPane(pane_sp:Sprite):void {
			if (!pane_sp) return;

			var i:int;
			var total:int = pane_sp.numChildren;
			var last_fbis_view:FurnitureBagItemstackView;
			var fbis_view:FurnitureBagItemstackView;
			var next_x:int;
			var itemstack:Itemstack;
			var A:Array = [];
			
			for (i=0; i < total; i++) {
				fbis_view = pane_sp.getChildAt(i) as FurnitureBagItemstackView;
				A.push(fbis_view.itemstack);
			}
			
			// sort!
			A.sortOn(
				['class_tsid', 'furn_upgrade_id', 'is_soulbound_to_me', 'furn_stacking_sig', 'furn_facing_right'],
				[Array.CASEINSENSITIVE, Array.NUMERIC | Array.DESCENDING, Array.NUMERIC | Array.DESCENDING, Array.DESCENDING, Array.NUMERIC]
			);
			
			var same_count:int; // the number that we have stacked on top of each other, reset to 1 when we come to a new thing
			for (i=0; i < total; i++) {
				itemstack = A[i];
				fbis_view = pane_sp.getChildByName(itemstack.tsid) as FurnitureBagItemstackView;
				fbis_view.visible = true;
				
				if (last_fbis_view && canStack(last_fbis_view.itemstack, fbis_view.itemstack)) {
					// same thing as the last one, so make the last one not visible and increment same_count
					same_count++;
					fbis_view.x = last_fbis_view.x;
					last_fbis_view.visible = false;
				} else {
					// new
					same_count = 1;
					fbis_view.x = next_x;
					next_x += FBIV_SIZE + BUTTON_PADD;
				}

				if (model.flashVarModel.stack_furn_bag) {
					fbis_view.updateUpgradeCount();
					fbis_view.setDisplayCount(same_count);
				} else {
					fbis_view.setDisplayCount(1);
				}
				last_fbis_view = fbis_view;
			}
			
			//place the regular stuff
			super.reflowPane(pane_sp);
		}
		
		private function canStack(last_stack:Itemstack, stack:Itemstack):Boolean {
			if (!model.flashVarModel.stack_furn_bag) return false;
			if (last_stack.furn_upgrade_id != '0') return false;
			if (last_stack.is_soulbound_to_me != stack.is_soulbound_to_me) return false;
			if (last_stack.class_tsid != stack.class_tsid) return false;
			
			if (true) { // this allows no stacking of anything but unupgraded things
				if (last_stack.itemstack_state.furn_config && last_stack.itemstack_state.furn_config.upgrade_ids && last_stack.itemstack_state.furn_config.upgrade_ids.length) return false;
				if (stack.itemstack_state.furn_config && stack.itemstack_state.furn_config.upgrade_ids && stack.itemstack_state.furn_config.upgrade_ids.length) return false;
			} else { // this allows stacking as long as the upgrade_ids are the same and furn_upgrade_id == '0'
				if (last_stack.furn_stacking_sig != stack.furn_stacking_sig) return false;
			}
			
			return true;
		}
		
		private function addFurnitureItemstack(itemstack:Itemstack):void {
			var item:Item = model.worldModel.getItemByTsid(itemstack.class_tsid);
			var fbis_view:FurnitureBagItemstackView;
			
			var panesA:Array = model.decorateModel.furniture_panesA;
			var id:String;
			var item_classesA:Array;
			var item_prefixesA:Array;
			var pane_to_add_to_idsA:Array = [CATEGORY_ALL];
			var bt:Button;
			
			// see what panes this item type goes in
			for (var i:int=0;i<panesA.length;i++) {
				id = panesA[i].id;
				item_classesA = panesA[i].items;
				if (item_classesA.indexOf(item.tsid) != -1) {
					pane_to_add_to_idsA.push(id);
				}
				
				item_prefixesA = panesA[i].item_prefixes;
				if (item_prefixesA) {
					for each (var prefix:String in item_prefixesA) {
						if (item.tsid.indexOf(prefix) == 0) {
							pane_to_add_to_idsA.push(id);
							break;
						}
					}
				}
			}
			
			/*CONFIG::debugging {
				Console.warn(item.tsid+' pane_to_add_to_idsA:'+pane_to_add_to_idsA);
			}*/
			var pane_sp:Sprite;
			for (i=0;i<pane_to_add_to_idsA.length;i++) {
				pane_sp = getPaneById(pane_to_add_to_idsA[i]);
				if (!pane_sp) {
					CONFIG::debugging {
						Console.warn('WTF no '+pane_to_add_to_idsA[i]);
					}
					continue;
				}
				
				fbis_view = pane_sp.getChildByName(itemstack.tsid) as FurnitureBagItemstackView;
				
				if (fbis_view) continue;
				
				fbis_view = new FurnitureBagItemstackView(itemstack.tsid, FBIV_SIZE);
				fbis_view.filters = StaticFilters.black2px90Degrees_FurnDropShadowA;
				pane_sp.addChild(fbis_view);
				if (pane_sp == current_pane_sp) reflowPane(pane_sp);
				bag_filter.addItem(pane_sp.name);
			}
		}
		
		private function removeFurnitureItemstack(itemstack:Itemstack):void {
			var item:Item = model.worldModel.getItemByTsid(itemstack.class_tsid);
			var fbis_view:FurnitureBagItemstackView;
			var pane_sp:Sprite;
			
			// go over each content pane and find and remove any views for it
			for (var id:String in content_panes) {
				pane_sp = getPaneById(id);
				if (!pane_sp) continue;
				fbis_view = pane_sp.getChildByName(itemstack.tsid) as FurnitureBagItemstackView;
				if (fbis_view) {
					pane_sp.removeChild(fbis_view);
					fbis_view.dispose();
					reflowPane(pane_sp);
					bag_filter.removeItem(pane_sp.name);
				} else {
					
				}
			}
		}
		
		private var mouse_down_pt:Point;
		private function _mouseDownHandler(e:MouseEvent):void {
			TSFrontController.instance.goNotAFK();
			if (model.stateModel.menus_prohibited) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			var element:DisplayObject = (e.target as DisplayObject);
			
			while (element != this) {
				if (element is FurnitureBagItemstackView) {
					var fbis_view:FurnitureBagItemstackView = element as FurnitureBagItemstackView;
					TipDisplayManager.instance.goAway();
					
					mouse_down_pt = new Point(StageBeacon.stage.mouseX, StageBeacon.stage.mouseY);
					dragged_fbis_view = fbis_view;
					
					StageBeacon.mouse_move_sig.add(_mouseMoveHandler);
					StageBeacon.mouse_up_sig.add(_mouseUpHandler);
					
					break;
				}
				
				element = element.parent;
			}
			
			StageBeacon.stage.focus = StageBeacon.stage;
		}
		
		private function _mouseUpHandler(e:MouseEvent):void {
			if (dragged_fbis_view) dragged_fbis_view.alpha = 1;
			
			if (Cursor.instance.is_dragging) {
				dispatchEvent(new TSEvent(TSEvent.DRAG_COMPLETE));
				Cursor.instance.endDrag();
			}
			
			dragged_fbis_view = null;
			
			StageBeacon.mouse_move_sig.remove(_mouseMoveHandler);
			StageBeacon.mouse_up_sig.remove(_mouseUpHandler);
		}
		
		private function _mouseMoveHandler(e:MouseEvent):void {
			var distance:Number = Point.distance(mouse_down_pt, StageBeacon.stage_mouse_pt);
			
			//Console.warn('distance:'+distance)
			
			if (distance> StateModel.DRAG_DIST_REQUIRED) {
				startDraggingAFBIView(dragged_fbis_view);
			}
		}
		
		private var dragVO:DragVO = DragVO.vo;
		private function startDraggingAFBIView(fbis_view:FurnitureBagItemstackView):void {
			// make sure we set these, in case we started the dragging from somewhere other than _mouseMoveHandler (like invoke dragging)
			dragged_fbis_view = fbis_view;
			StageBeacon.mouse_up_sig.add(_mouseUpHandler);
			
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(dragged_fbis_view.tsid);
			var sp:Sprite = new Sprite();
			
			// if we're in the interiror POL location, go ahead and start dragging a location itemestack
			if (model.stateModel.can_decorate && !TradeDialog.instance.parent && !MailDialog.instance.parent) {
				var temp_lis_view:LocationItemstackView = new LocationItemstackView(fbis_view.tsid);
				temp_lis_view.worth_rendering = true;
				temp_lis_view.disableGSMoveUpdates();
				temp_lis_view.x = 0;
				temp_lis_view.y = 0;
				
				/*
				//If we want to reenable this, we need to do a smart placement with getBounds, because ceiling lamps
				if (temp_lis_view.is_loaded) {
					temp_lis_view.y = temp_lis_view.height/2;
				} else {
					temp_lis_view.addEventListener(TSEvent.COMPLETE, function(e:TSEvent):void {
						temp_lis_view.y = temp_lis_view.height/2;
						dragVO.furniture_offset_y = temp_lis_view.y;
						temp_lis_view.removeEventListener(TSEvent.COMPLETE, arguments.callee);
					});
				}
				*/
				
				Cursor.instance.startDragWith(temp_lis_view);
			} else { // we're not in a decorable location, just drag a fbis_view
				var temp_fbis_view:FurnitureBagItemstackView = new FurnitureBagItemstackView(fbis_view.tsid, FBIV_SIZE);
				temp_fbis_view.x = -FBIV_SIZE/2;
				temp_fbis_view.y = -FBIV_SIZE/2;
				sp.addChild(temp_fbis_view);
				
				Cursor.instance.startDragWith(sp);
			}
			
			StageBeacon.mouse_move_sig.remove(_mouseMoveHandler);
			dragVO.clear();
			if (temp_lis_view) {
				dragVO.furniture_offset_y = temp_lis_view.y;
			}
			dragVO.dragged_itemstack = itemstack;
			dragged_fbis_view.alpha = .5;
			dispatchEvent(new TSEvent(TSEvent.DRAG_STARTED, dragVO));
		}
		
		private function _clickHandler(e:MouseEvent):void {
			if (model.stateModel.menus_prohibited) {
				return;
			}
			
			var element:DisplayObject = e.target as DisplayObject;
			var focus_stage:Boolean = true;
			
			while (element != this) {
				if (element is FurnitureBagItemstackView) {
					var fbis_view:FurnitureBagItemstackView = element as FurnitureBagItemstackView;
					
					var itemstack:Itemstack = model.worldModel.getItemstackByTsid(fbis_view.tsid);
					
					if(KeyBeacon.instance.pressed(Keyboard.CONTROL)) {
						//link the item in chat
						var chat_area:ChatArea = RightSideManager.instance.right_view.getChatToFocus();
						var item:Item = model.worldModel.getItemByTsid(itemstack.class_tsid);
						chat_area.input_field.setLinkText(item.label, TSLinkedTextField.LINK_ITEM+'|'+item.tsid);
						chat_area.focus();
						focus_stage = false;
					} else if (CONFIG::god) {
						; // satisfy compiler
						CONFIG::god {
							if (KeyBeacon.instance.pressed(Keyboard.K)) {
								TSFrontController.instance.doVerb(FurnitureBagItemstackView(element).tsid, Item.CLIENT_DESTROY);
							} else if (KeyBeacon.instance.pressed(Keyboard.P)) {
								TSFrontController.instance.doVerb(FurnitureBagItemstackView(element).tsid, Item.CLIENT_EDIT_PROPS);
							} else {
								TSFrontController.instance.startInteractionWith(TSSprite(element), true);
							}
						}
					} else {
						TSFrontController.instance.startInteractionWith(TSSprite(element), true);
					}
					
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					break;
				}
				
				element = element.parent;
			}
			
			if(focus_stage) StageBeacon.stage.focus = StageBeacon.stage;
		}
		
		override public function onPcItemstackAdds(tsids:Array):void {
			if (!is_built) return;
			var tsid:String;
			var itemstack:Itemstack;
			for (var i:int=0;i<tsids.length;i++) {
				tsid = tsids[i];
				itemstack = model.worldModel.getItemstackByTsid(tsids[i]);
				
				if (!itemstack) {
					CONFIG::debugging {
						Console.error(tsid +' not an itemstack??');
					}
					continue;
				}
				
				// this may have been areplaced door, moved from location, so
				// let's make sure it does not have a door!
				if (itemstack.client::door) {
					itemstack.client::door = null;
				}
				
				if (itemstack.container_tsid == model.worldModel.pc.furniture_bag_tsid) {
					CONFIG::debugging {
						Console.info('CREATE A '+itemstack.class_tsid+' for '+tsid);
					}
					
					// go go go
					addFurnitureItemstack(itemstack);
				}
			}
		}
		
		override public function onPcItemstackDels(tsids:Array):void {
			if (!is_built) return;
			var tsid:String;
			var itemstack:Itemstack;
			for (var i:int=0;i<tsids.length;i++) {
				tsid = tsids[i];
				itemstack = model.worldModel.getItemstackByTsid(tsids[i]);
				
				if (!itemstack) {
					CONFIG::debugging {
						Console.error(tsid +' not an itemstack??');
					}
					continue;
				}
				
				if (itemstack.container_tsid == model.worldModel.pc.furniture_bag_tsid) {
					CONFIG::debugging {
						Console.info('DELETE A '+itemstack.class_tsid+' for '+tsid);
					}
					
					// go go go
					removeFurnitureItemstack(itemstack);
				}
			}
			
		}
		
		// THIS JUST RETURNS THE FIRST ONE. NEEDS REDOING WHEN THE WHOLE UI IS REDONE
		public function getItemstackViewByTsid(stack_tsid:String):FurnitureBagItemstackView {
			// go over each content pane return the first view
			var fbis_view:FurnitureBagItemstackView;
			var pane_sp:Sprite;
			for (var id:String in content_panes) {
				pane_sp = getPaneById(id);
				if (!pane_sp) continue;
				fbis_view = pane_sp.getChildByName(stack_tsid) as FurnitureBagItemstackView;
				if (fbis_view) {
					return fbis_view;
				}
			}
			
			return null;
		}
		
		override public function onPcItemstackUpdates(tsids:Array):void {
			if (!is_built) return;
			var tsid:String;
			var itemstack:Itemstack;
			var item:Item;
			for (var i:int=0;i<tsids.length;i++) {
				tsid = tsids[i];
				itemstack = model.worldModel.getItemstackByTsid(tsids[i]);
				
				if (!itemstack) {
					CONFIG::debugging {
						Console.error(tsid +' not an itemstack??');
					}
					continue;
				}
				
				if (itemstack.container_tsid == model.worldModel.pc.furniture_bag_tsid) {
					item = model.worldModel.getItemByTsid(itemstack.class_tsid);
					CONFIG::debugging {
						Console.info('UPDATE A '+item.tsid+' for '+tsid);
					}
					
					var fbis_view:FurnitureBagItemstackView;
					var pane_sp:Sprite;
					
					// go over each content pane and find and update any views for it
					for (var id:String in content_panes) {
						pane_sp = getPaneById(id);
						if (!pane_sp) continue;
						fbis_view = pane_sp.getChildByName(itemstack.tsid) as FurnitureBagItemstackView;
						if (fbis_view) {
							fbis_view.changeHandler();
						} else {
							addFurnitureItemstack(itemstack);
						}
					}
					
				} else {
					removeFurnitureItemstack(itemstack);
				}
			}
		}
	}
}