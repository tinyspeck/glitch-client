package com.tinyspeck.engine.control.engine {
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.Door;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.spritesheet.ItemSSManager;
	import com.tinyspeck.engine.spritesheet.SSAbstractSheet;
	import com.tinyspeck.engine.spritesheet.SWFData;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.geom.GeomUtil;
	import com.tinyspeck.engine.view.geo.DoorView;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocItemstackAddDelConsumer;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocItemstackUpdateConsumer;
	import com.tinyspeck.engine.view.ui.DoorIcon;
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	public class FancyDoor implements ILocItemstackUpdateConsumer, ILocItemstackAddDelConsumer {
		/* singleton boilerplate */
		public static const instance:FancyDoor = new FancyDoor();
		
		private var model:TSModelLocator;
		private var wm:WorldModel;
		
		public function FancyDoor() {
			// maybe not safe to assume this ctor will not get called b4 the model is built, but works for now!
			model = TSModelLocator.instance;
			wm = model.worldModel;
		}
		
		private var pc_door_iconsH:Dictionary = new Dictionary();
		
		private function getDoorIcon(pc:PC, itemstack_tsid:String):DoorIcon {
			var key:String = pc.tsid+'_'+itemstack_tsid;
			 if (!pc_door_iconsH[key]) {
				 pc_door_iconsH[key] = new DoorIcon(pc);
			 }
			 
			 return pc_door_iconsH[key];
		}
		
		private function fancyUpDoor(itemstack_tsid:String):void {
			/*
			CONFIG::god {
				Console.error('w');
			}
			*/
			if (model.moveModel.moving) {
				return;
			}
			
			var door:Door = wm.location.mg.getDoorForItemstackTsid(itemstack_tsid);
			if (!door) {
				CONFIG::debugging {
					Console.info('no door with itemstack_tsid:'+itemstack_tsid);
				}
				return;
			}
			
			var pc:PC = model.worldModel.getPCByTsid(door.owner_tsid);
			if (!pc) {
				CONFIG::debugging {
					Console.error('no pc with door.owner_tsid:'+door.owner_tsid);
				}
				return;
			}
			
			var itemstack:Itemstack = wm.getItemstackByTsid(door.itemstack_tsid);
			if (!itemstack) {
				CONFIG::debugging {
					Console.error('no stack with door.itemstack_tsid:'+door.itemstack_tsid);
				}
				return;
			}
			
			var doorView:DoorView = TSFrontController.instance.getMainView().gameRenderer.getDoorViewByTsid(door.tsid);
			if (!doorView) {
				CONFIG::debugging {
					Console.error('no doorView for '+door.tsid);
				}
				return;
			}
			
			var swf_data:SWFData = ItemSSManager.getSWFDataByUrl(itemstack.swf_url);
			if (!swf_data || !swf_data.mc) {
				ItemSSManager.getSSForItemSWFByUrl(itemstack.swf_url, itemstack.item, function(ss:SSAbstractSheet, url:String):void {
					// maybe need to check here that we got swf_data.mc?
					if (ss) {
						fancyUpDoor(itemstack_tsid);
					} else {
						// we can't because the fucker failed somehow
					}
				});
				/*CONFIG::debugging {
					Console.info('requesting item swf');
				}*/
				return;
			}
			
			var asset_name:String;
			
			if (!itemstack.itemstack_state.config_for_swf) {
				CONFIG::debugging {
					Console.error('no itemstack_state.config_for_swf for '+itemstack.tsid);
				}
				asset_name = 'door_up';
			} else if (itemstack.item.tsid == 'furniture_tower_chassis') {
				asset_name = 'door_'+itemstack.itemstack_state.config_for_swf['floor_ground'];
			} else {
				asset_name = itemstack.itemstack_state.config_for_swf['door'];
			}
			
			//Console.error('asset_name '+asset_name);
			
			var door_mc:MovieClip = swf_data.mc.getAssetByName(asset_name) as MovieClip;
			if (!door_mc) {
				CONFIG::debugging {
					Console.error(asset_name+' not in mc library '+itemstack.tsid+' '+itemstack.itemstack_state.config_for_swf+' '+itemstack.swf_url);
					Console.dir(itemstack.itemstack_state.config_for_swf);
				}
				return;
			}
			
			try {
				var door_container:MovieClip;
				var is_mc_flipped:Boolean;
				if (itemstack.item.tsid == 'furniture_chassis') {
					door.client::hide_unless_highlighting = true;
					door_container = swf_data.mc.maincontainer_mc.house_mc.doorContainer_mc;
					is_mc_flipped = SpriteUtil.isDOFlippedHorizontally(swf_data.mc.maincontainer_mc);
				} else if (itemstack.item.tsid == 'furniture_tower_chassis') {
					door.client::hide_unless_highlighting = true;
					door_container = swf_data.mc.maincontainer_mc.door_container_mc;
					is_mc_flipped = SpriteUtil.isDOFlippedHorizontally(swf_data.mc.maincontainer_mc);
				} else if (itemstack.item.tsid == 'furniture_door') {
					door_container = swf_data.mc.maincontainer_mc.doorContainer_mc;
				}
			} catch(err:Error) {
				CONFIG::debugging {
					Console.error(err.toString());
				}
			}
			
			if (!door_container) {
				CONFIG::debugging {
					Console.error('no door_container');
				}
				return;
			}
			
			itemstack.client::door = door;
			
			var flip_it_right:Boolean = itemstack.itemstack_state.furn_config.facing_right;
			
			// we must do this to make sure the door asset we add to the doorView is the
			// same size as it would have appeared if placed in door_container
			door_mc.scaleX = door_container.scaleX;
			door_mc.scaleY = door_container.scaleY;
			/*
			CONFIG::god {
				Console.info(door_mc.scaleX+' scale '+door_mc.scaleY);
			}
			*/
			
			var door_icon:DoorIcon;
			if (WorldModel.ITEM_CLASSES_WITH_DOOR_ICONS.indexOf(itemstack.item.tsid) > -1) {
				
				// mark everything invisible, then we'll mark the icon visible later
				for (var i:int=0;i<door_mc.numChildren;i++) {
					door_mc.getChildAt(i).visible = false;
				}
				
				door_icon = getDoorIcon(pc, itemstack_tsid);
				door_icon.show();
				
				if (door_mc.icon_point) {
					door_mc.icon_point.scaleX = (flip_it_right) ? 1 : -1;
					door_mc.icon_point.visible = true;
					door_mc.icon_point.addChild(door_icon);
					door_icon.x = -DoorIcon.SIZE/2;
					door_icon.y = -DoorIcon.SIZE/2;
				} else {
					// this is legacy and we are here because the door asset in the chassis lib does not have an icon_point
					CONFIG::debugging {
						Console.warn(asset_name+' has no icon_point');
					}
					door_mc.addChild(door_icon);
					door_icon.x = 0;(door_mc.width/2)-(DoorIcon.SIZE/2);
					door_icon.y = 0;(door_mc.height/2)-(DoorIcon.SIZE/2);
				}
			}
			
			// add the asset to the doorView
			doorView.addItemDoor(door_mc);
			
			// complexer than I'd like, but it positions the doorView in location to be where the door would appear:
			//first, calc the top left corner of the itemstack_stack view (which is analogous to 0,0 in the item mc
			var door_x:int = 0;
			var door_y:int = 0;
			
			if (flip_it_right) {
				door_x-= (swf_data.mc_w/2);
			} else {
				door_x+= (swf_data.mc_w/2);
			}
			door_y-= swf_data.mc_h;
			/*
			CONFIG::god {
				Console.info('swf_data.mc_w '+swf_data.mc_w+' swf_data.mc_h '+swf_data.mc_h+' door_y:'+door_y);
			}
			*/
			// now add in the location of the door_container in the mc stage coordinates
			var pt:Point = SpriteUtil.findCoordsOfChildInAncestor(
				door_container,
				swf_data.mc
			);
			
			if (flip_it_right) {
				door_x+= pt.x;
			} else {
				door_x-= pt.x;
			}
			door_y+= pt.y;
			/*
			CONFIG::god {
				Console.info('pt '+pt+' door_y:'+door_y);
			}
			*/
			// now compensate for the fact that the doorView has 0,0 in bottom center
			const bounds:Rectangle = GeomUtil.roundRectValues(door_mc.getBounds(door_mc));
			if ((flip_it_right && !is_mc_flipped) || (!flip_it_right && is_mc_flipped)) {
				door_x+= Math.round(bounds.width/2)+bounds.x;
			} else {
				door_x-= Math.round(bounds.width/2)+bounds.x;
			}
			door_y+= bounds.height+bounds.y;
			/*
			CONFIG::god {
				Console.info('bounds '+bounds+' door_y:'+door_y);
			}
			*/
			door.h_flip = (!flip_it_right && !is_mc_flipped || flip_it_right && is_mc_flipped);
			
			itemstack.client::door_offset_x = door_x;//-20;
			itemstack.client::door_offset_y = door_y;//-20;
			
			door_x = itemstack.client::door_offset_x+itemstack.x;
			door_y = itemstack.client::door_offset_y+itemstack.y;
			/*
			CONFIG::god {
				Console.info('itemstack.x '+itemstack.x+' itemstack.y '+itemstack.y+' door_y:'+door_y);
			}
			*/
			
			door.x = door_x;
			door.y = door_y;
			
			// and set the dims correctly!
			door.w = bounds.width;
			door.h = bounds.height;
			
			// make it happen, including updating the quadtree
			TSFrontController.instance.refreshDoorInAllViews(door);
		}
		
		public function placeDoor(itemstack:Itemstack):void {
			if (itemstack.client::door) {
				itemstack.client::door.x = itemstack.x+itemstack.client::door_offset_x;
				itemstack.client::door.y = itemstack.y+itemstack.client::door_offset_y;
				TSFrontController.instance.refreshDoorInAllViews(itemstack.client::door);
			}
		}
		
		private function checkForStacks(tsids:Array):void {
			var i:int;
			var tsid:String;
			var itemstack:Itemstack;
			
			for (i=0;i<tsids.length;i++) {
				tsid = tsids[int(i)];
				itemstack = model.worldModel.getItemstackByTsid(tsid);
				if (WorldModel.ITEM_CLASSES_WITH_DOORS.indexOf(itemstack.class_tsid) > -1) {
					if (itemstack.itemstack_state.furn_config.is_dirty) {
						fancyUpDoor(itemstack.tsid);
					} else if (itemstack.client::door) {
						placeDoor(itemstack);
					}
				}
			}
		}
		
		// instead of becoming an IMoveListener, we just depened on TSMainView to call this for us
		public function onMoveEnded():void {
			const itemstacks:Dictionary = wm.itemstacks;
			
			const A:Array = [];
			var k:String;
			for (k in itemstacks) {
				A.push(k);
			}
			
			checkForStacks(A);
		}
		
		
		////////////////////////////////////////////////////////////////////////////////
		//////// ILocItemstackAddDelConsumer ///////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		public function onLocItemstackAdds(tsids:Array):void {
			checkForStacks(tsids);
		}
		
		public function onLocItemstackDels(tsids:Array):void {

		}
		
		////////////////////////////////////////////////////////////////////////////////
		//////// ILocItemstackUpdateConsumer ///////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		public function onLocItemstackUpdates(tsids:Array):void {
			checkForStacks(tsids);
		}
	}
}