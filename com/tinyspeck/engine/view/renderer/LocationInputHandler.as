package com.tinyspeck.engine.view.renderer
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.HandOfDecorator;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.item.Verb;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.StateModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingInventoryMoveVO;
	import com.tinyspeck.engine.net.NetOutgoingItemstackVerbMenuVO;
	import com.tinyspeck.engine.net.NetOutgoingLocalChatVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.pack.FurnitureBagUI;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.port.ActionIndicatorView;
	import com.tinyspeck.engine.port.CultManager;
	import com.tinyspeck.engine.port.Cursor;
	import com.tinyspeck.engine.port.Emotes;
	import com.tinyspeck.engine.port.IChatBubble;
	import com.tinyspeck.engine.port.TSSprite;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.DragVO;
	import com.tinyspeck.engine.util.IDragTarget;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.AbstractAvatarView;
	import com.tinyspeck.engine.view.PCView;
	import com.tinyspeck.engine.view.gameoverlay.AbstractAnnouncementOverlay;
	import com.tinyspeck.engine.view.gameoverlay.CameraMan;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.geo.DoorView;
	import com.tinyspeck.engine.view.geo.LadderView;
	import com.tinyspeck.engine.view.geo.SignpostSignView;
	import com.tinyspeck.engine.view.geo.SignpostView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.ui.garden.GardenPlotView;
	import com.tinyspeck.engine.view.ui.garden.GardenView;
	
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	
	CONFIG::god { import com.tinyspeck.engine.view.gameoverlay.ViewportScaleSliderView; }
	
	
	/** 
	 * Handles keyboard and mouse events dispatched from a specified
	 * LocationRenderer.
	 * 
	 * Dispatches : 
	 * 	TSEvent.DRAG_COMPLETE
	 * 	TSEvent.DRAG_STARTED
	 */ 	
	public class LocationInputHandler extends EventDispatcher{
		public static const CLICK_DELAY:uint = 100; // milliseconds
		public static const instance:LocationInputHandler = new LocationInputHandler();
		
		private const interaction_spritesV:Vector.<TSSprite> = new Vector.<TSSprite>();
		
		private var model:TSModelLocator;
		private var _locationRenderer:LocationRenderer;
		private var _locationView:LocationView;
		private var keyMan:KeyBeacon;
		private var dragVO:DragVO = DragVO.vo;
		
		private var interaction_sprite:TSSprite;
		private var time_started_listening_to_clicks:int; // we use this to make sure we do not register clicks right after a drag happened
		
		// local pool
		private const mouse_down_pt:Point = new Point();
		private var dragged_lis_view:LocationItemstackView;
		
		public function LocationInputHandler() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			this.model = TSModelLocator.instance;
			/*
			this._locationRenderer = _locationRenderer;
			*/
			
			keyMan = KeyBeacon.instance;
			PackDisplayManager.instance.addEventListener(TSEvent.DRAG_COMPLETE, _packDragCompleteHandler);
			PackDisplayManager.instance.addEventListener(TSEvent.DRAG_STARTED, _packDragStartHandler);
			FurnitureBagUI.instance.addEventListener(TSEvent.DRAG_COMPLETE, _furnitureBagDragCompleteHandler);
			FurnitureBagUI.instance.addEventListener(TSEvent.DRAG_STARTED, _furnitureBagDragStartHandler);
		}
		
		public function startListeningForControlEvts():void {
			if (!_locationRenderer) return;
			
			time_started_listening_to_clicks = getTimer();
			
			_locationRenderer.addEventListener(MouseEvent.CLICK, onLocationRendererClicked);
			_locationRenderer.doubleClickEnabled = true;
			_locationRenderer.addEventListener(MouseEvent.DOUBLE_CLICK, _locDblClickHandler);
			_locationRenderer.addEventListener(MouseEvent.MOUSE_DOWN, _locMouseDownHandler);
			
			startListeningForKeyEvts();
			startListeningToLocationView();
		}
		
		public function stopListeningForControlEvts():void {
			if (!_locationRenderer) return;
			
			if (_locationRenderer.locationView && _locationRenderer.locationView.middleGroundRenderer) {
				_locationRenderer.locationView.middleGroundRenderer.unglowAllInteractionSprites();
			}
			
			_locationRenderer.removeEventListener(MouseEvent.CLICK, onLocationRendererClicked);
			_locationRenderer.removeEventListener(MouseEvent.DOUBLE_CLICK, _locDblClickHandler);
			
			if (!(model.stateModel.about_to_be_focused_component is CameraMan)) {
				// this allows dragging to work even in in Camera mode
				_locationRenderer.removeEventListener(MouseEvent.MOUSE_DOWN, _locMouseDownHandler);
			}
			
			stopListeningForKeyEvts();
			stopListeningToLocationView();
		}
		
		private function startListeningForKeyEvts():void {
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, enterKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMBER_1, number1KeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMPAD_1, number1KeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMBER_2, number2KeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMPAD_2, number2KeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMBER_3, number3KeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMPAD_3, number3KeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMBER_4, number4KeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMPAD_4, number4KeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMBER_5, number5KeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMPAD_5, number5KeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.H, number5KeyHandler);
		}
		
		private function stopListeningForKeyEvts():void {
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, enterKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMBER_1, number1KeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMPAD_1, number1KeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMBER_2, number2KeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMPAD_2, number2KeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMBER_3, number3KeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMPAD_3, number3KeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMBER_4, number4KeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMPAD_4, number4KeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMBER_5, number5KeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.NUMPAD_5, number5KeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.H, number5KeyHandler);
		}
		
		private function number1KeyHandler(e:KeyboardEvent):void {
			if (model.stateModel.focus_is_in_input) return;
			TSFrontController.instance.goNotAFK();
			TSFrontController.instance.playSurprisedAnimation();
		}
		
		private function number2KeyHandler(e:KeyboardEvent):void {
			if (model.stateModel.focus_is_in_input) return;
			TSFrontController.instance.goNotAFK();
			TSFrontController.instance.playAngryAnimation();
		}
		
		private function number3KeyHandler(e:KeyboardEvent):void {
			if (model.stateModel.focus_is_in_input) return;
			TSFrontController.instance.goNotAFK();
			TSFrontController.instance.playHappyAnimation();
		}
		
		private function number4KeyHandler(e:KeyboardEvent):void {
			if (model.stateModel.focus_is_in_input) return;
			TSFrontController.instance.toggleAFK();
		}
		
		private function number5KeyHandler(e:KeyboardEvent):void {
			if (model.stateModel.focus_is_in_input) return;
			TSFrontController.instance.goNotAFK();
			TSFrontController.instance.doEmote(Emotes.EMOTE_TYPE_HI);
		}
		
		private function enterKeyHandler(e:KeyboardEvent = null):void {
			CONFIG::perf {
				if (model.flashVarModel.run_automated_tests) return;
			}
			
			if (model.stateModel.focus_is_in_input) return;
			
			// since CultMan does not always take focus, we must listen here for ENTER key
			if (model.stateModel.cult_mode) {
				CultManager.instance.enterKeyHandler(e);
				return;
			}
			
			_beginInteractionAfterEnterKey();
		}
		
		private function _beginInteractionAfterEnterKey():void {
			if (!_locationRenderer.pc.apo.onLadder && _locationRenderer.pc.apo._interaction_spV.length) {
				// null the sign out, in case it was set previously bt the path not completed
				model.stateModel.interaction_sign = null;
				
				// get the ladders out, because the is no point responding to enter key to get on a ladder
				// and also gardens that people don't own
				interaction_spritesV.length = 0;
				
				for each (interaction_sprite in _locationRenderer.pc.apo._interaction_spV) {
					if (!(interaction_sprite is LadderView) 
						&& !(interaction_sprite is LocationItemstackView 
							&& LocationItemstackView(interaction_sprite).garden_view 
							&& !LocationItemstackView(interaction_sprite).garden_view.is_owner
							)
						&& !(interaction_sprite is AbstractAvatarView && model.worldModel.location.no_pc_interactions)
					){
						interaction_spritesV.push(interaction_sprite);
					} 
				}
				
				if (interaction_spritesV.length) {
					if (interaction_spritesV.length == 1) {
						TSFrontController.instance.startInteractionWith(interaction_spritesV[0]);
					} else { // must choose from possible sprites
						TSFrontController.instance.startLocationDisambiguator(interaction_spritesV);
					}
				}
			}
		}
		
		/** Return true if enough time has passed since we started listening for clicks */
		private function clickDelayReached():Boolean {
			var elapsed:int = getTimer()-time_started_listening_to_clicks;
			if (elapsed < CLICK_DELAY) {
				CONFIG::debugging {
					Console.info('ignoring this click because only '+elapsed+'ms  have passed since we started listening (so I am guessing this happened just after a drag)');
				}
				return false;
			}
			return true;
		}
		
		/** Handles clicks on LocationRenderer.  If the target is just the LocationRenderer, simply move. */
		private function onLocationRendererClicked(e:MouseEvent):void {
			// Make sure enough time has passed since we started listening for clicks
			if (!clickDelayReached()) return;
			var element:DisplayObject = e.target as DisplayObject;
			
			CONFIG::god {
				if (model.stateModel.hand_of_god || model.stateModel.editing) return;
			}
			
			// only process movement if an interactive item was not clicked.
			if (e.target == _locationRenderer) {
				TSFrontController.instance.startUserInitiatedPath(_locationRenderer.getMouseXYinMiddleground().clone());
				StageBeacon.stage.focus = StageBeacon.stage;
			}
		}
		
		/** Handles clicks on items within the LocationView */
		private function onLocationViewClicked(clickTarget:DisplayObject):void {
			// Make sure enough time has passed since we started listening for clicks
			if (!clickDelayReached()) return;

			CONFIG::debugging {
				if (clickTarget is DisplayObject) {
					Console.info(StringUtil.DOPath(DisplayObject(clickTarget)));
				}
			}
			
			if (interactWithClickTarget(clickTarget)) {
				if (!(clickTarget is LocationItemstackView) || !LocationItemstackView(clickTarget).item.hasTags('no_click_sound')) {
					SoundMaster.instance.playSound('CLICK_SUCCESS');
				}
				return;
			}

			CONFIG::god {
				if (model.stateModel.hand_of_god || model.stateModel.editing) return;
			}
					
			TSFrontController.instance.startUserInitiatedPath(_locationRenderer.getMouseXYinMiddleground().clone());
			StageBeacon.stage.focus = StageBeacon.stage;
		}		
		
		/** Determines action based on the type of interactive item that was clicked */
		private function interactWithClickTarget(clickTarget:DisplayObject):Boolean {
			
			// click action might result in removal from stage
			if (!clickTarget || !clickTarget.parent) return false;
			
			if (clickTarget is AbstractAnnouncementOverlay) {
				return true;
			}

			if (clickTarget is IChatBubble) {
				return true;
			}

			if ((clickTarget is GardenView) || (clickTarget is GardenPlotView)) {
				return true;
			}

			if (clickTarget is ActionIndicatorView) {
				return true;
			}
			
			var pc_view:PCView = clickTarget as PCView;
			if (pc_view) {
				_moveAvatarToSpriteAndStartInteraction(pc_view);
				return true;
			}
			
			var lis_view:LocationItemstackView = clickTarget as LocationItemstackView;
			if (lis_view) {
				// make sure the LIS's hit_target was clicked.
				var stage:Stage = _locationRenderer.stage;
				if (!lis_view.testHitTargetAgainstPoint(stage.mouseX, stage.mouseY)) {
					return false;
				}
				
				if (!lis_view.itemstack.is_clickable) {
					CONFIG::debugging {
						Console.warn(lis_view.item.tsid+' NOT is_clickable');
					}
					if (!CONFIG::god) {
						return false;
					} else {
						CONFIG::god {
							if (!model.flashVarModel.interact_with_all) {
								return false;
							}
						}
					}
				}
				
				var pc_is_there:Boolean = _locationRenderer.pc.apo._interaction_spV.indexOf(lis_view) > -1;
				if (TSFrontController.instance.tryAOneClickActionOnALIS(lis_view, true, pc_is_there)) {
					return true;
				}
				
				_moveAvatarToSpriteAndStartInteraction(lis_view);
				return true;
			}
			
			if (clickTarget is DoorView) {
				if (CONFIG::god) {
					if (keyMan.pressed(Keyboard.CONTROL) && DoorView(clickTarget).door.is_locked && DoorView(clickTarget).door.key_id) {
						/*
						[12:09pm] eric: I'm trying to see how the int value for door.key_id is turned into a reference to an actual game object.
						[12:09pm] eric: because I want to make it so that in the DEV client you can control click on a locked door to get the key for it.
						[12:10pm] eric: but the client only know the key_id for the door.
						[12:11pm] logbot: mygrant: Players/Inc_items.js line 366
						[12:11pm] eric: O fuck, i saw that inc_items.js but just thought it was for items. forgot how pcs inherit functions from includes.
						[12:11pm] eric: thanks!
						[12:12pm] logbot: mygrant: I don't think you can do it client-side,
						[12:12pm] logbot: mygrant: Will need some js
						[12:13pm] eric: are you sure? is the key_id not a direct reference to the ints in the names of the key items? http://dev.glitch.com/god/search.php?q=key
						[12:14pm] logbot: mygrant: That would work for now, but it's not how the underlying js works.
						*/
						TSFrontController.instance.sendLocalChat(
							new NetOutgoingLocalChatVO('/create item door_key_'+DoorView(clickTarget).door.key_id+' in pack')
						);
					} else {
						_moveAvatarToSpriteAndStartInteraction(DoorView(clickTarget));
					}
				} else {
					_moveAvatarToSpriteAndStartInteraction(DoorView(clickTarget));
				}
				return true;
			}

			if (clickTarget is LadderView) {
				_moveAvatarToSpriteAndStartInteraction(LadderView(clickTarget));
				return true;
			}

			if (clickTarget is SignpostView) {
				//if we are going to edit our signpost, don't move, it will open a dialog
				const signpost_view:SignpostView = clickTarget as SignpostView;
				if(!signpost_view.edit_clicked){
					_moveAvatarToSpriteAndStartInteraction(signpost_view);
				}			
				return true;
			}

			if (clickTarget is SignpostSignView) {
				var ssvElem:SignpostSignView = clickTarget as SignpostSignView;
				_moveAvatarToSpriteAndStartInteraction(ssvElem.signpostView, ssvElem);
				return true;
			}
			
			return false;
		}
		
		private function _locDblClickHandler(e:MouseEvent):void {
			TSFrontController.instance.triggerJump();
			TSFrontController.instance.startUserInitiatedPath(_locationRenderer.getMouseXYinMiddleground().clone());
			StageBeacon.stage.focus = StageBeacon.stage;
		}	
		
		private function _locMouseDownHandler(e:MouseEvent, lisView:LocationItemstackView = null):void {
			var item:Item;
			var itemstack:Itemstack;
			var good:Boolean;
			if (!lisView) {
				var lis_view:LocationItemstackView = _locationRenderer.getMostLikelyItemstackUnderCursor();
			} else {
				lis_view = lisView;
			}
			
			if (lis_view) {
				mouse_down_pt.x = StageBeacon.stage.mouseX;
				mouse_down_pt.y = StageBeacon.stage.mouseY;
				item = lis_view.item;
				itemstack = lis_view.itemstack;
				
				CONFIG::debugging {
					Console.info(item.tsid+' pickupable:'+item.pickupable);
				}
				
				if (item.is_furniture || item.is_special_furniture) {
					good = model.stateModel.can_decorate;
				} else {
					good = item.pickupable;
				}
				
				if (good) {
					dragged_lis_view = lis_view;
					TipDisplayManager.instance.goAway();
					StageBeacon.mouse_move_sig.add(_locMouseMoveHandler);
					StageBeacon.mouse_up_sig.add(_locMouseUpHandler);
				}
			}
		}	
		
		private function _locMouseUpHandler(e:MouseEvent):void {
			if (Cursor.instance.is_dragging) {
				dispatchEvent(new TSEvent(TSEvent.DRAG_COMPLETE));
				Cursor.instance.endDrag();
			}
			
			dragged_lis_view = null;
			
			StageBeacon.mouse_move_sig.remove(_locMouseMoveHandler);
			StageBeacon.mouse_up_sig.remove(_locMouseUpHandler);
		}		
		
		private function _locMouseMoveHandler(e:MouseEvent):void {
			const distance:Number = Point.distance(mouse_down_pt, StageBeacon.stage_mouse_pt);
			
			CONFIG::debugging {
				Console.warn('distance:'+distance)
			}
			
			if (distance >= StateModel.DRAG_DIST_REQUIRED) {
				StageBeacon.mouse_move_sig.remove(_locMouseMoveHandler);
				var itemstack:Itemstack = dragged_lis_view.itemstack;
				
				dragVO.clear();
				dragVO.dragged_itemstack = itemstack;
				dispatchEvent(new TSEvent(TSEvent.DRAG_STARTED, dragVO));
			}
		}
		
		private function _furnitureBagDragStartHandler(e:TSEvent):void {
			dragVO.setReceptiveLocationItemstacksForDrag();
			StageBeacon.mouse_move_sig.add(_furnitureBagDragMoveHandler);
		}
		
		private function _furnitureBagDragMoveHandler(e:MouseEvent):void {
			if (!_locationRenderer.accepting_drags) return;
			var loc:Location = model.worldModel.location;
			var pc:PC = model.worldModel.pc;
			if (_locationRenderer.hitTestObject(Cursor.instance.drag_DO)) {
				var target:IDragTarget = dragVO.findDragTargetForStack();
				if (!target) {
					target = _locationRenderer;
				}
				if (target) {
					var plat_to_drop_on:Boolean;
					if (target == _locationRenderer) {
						if (dragVO.dragged_itemstack.item.is_furniture) {
							var pt:Point = _locationRenderer.getMouseXYinMiddleground().clone();
							// compensate for how the dragged LIV is y centered on the mouse
							pt.y+= dragVO.furniture_offset_y;
							plat_to_drop_on = HandOfDecorator.instance.calculateTargetPlatformLineForFurnitureFromPt(pt);
						} else {
							plat_to_drop_on = (isThereASpecificPlatToDropRegStackOn());
						}
					}
					if (target != dragVO.target || plat_to_drop_on) {
						if (target != dragVO.target) {
							if (dragVO.target) dragVO.target.unhighlightOnDragOut();
							dragVO.target = target; // tuck a reference to the target in the dragVO
							dragVO.target.highlightOnDragOver();
						}
						
						if (dragVO.target == _locationRenderer) {
							if (plat_to_drop_on) {
								if (dragVO.dragged_itemstack.item.is_furniture) {
									Cursor.instance.showTip('Place', true);
								} else {
									Cursor.instance.hideTip();
								}
								Cursor.instance.drag_DO.alpha = 1;
							} else {
								//Cursor.instance.showTip('NO Place');
								if (
									dragVO.dragged_itemstack.class_tsid == 'furniture_door' && 
									loc.tsid != pc.home_info.interior_tsid &&
									pc.home_info.playerIsAtHome()
								) {
									// special tip for when dragging a door into a tower
									Cursor.instance.showTip('<font color="#cc0000">You can\'t place doors in towers, silly!</font>', true);
									Cursor.instance.drag_DO.alpha = 1;
								} else {
									Cursor.instance.hideTip();
									Cursor.instance.drag_DO.alpha = .5;
								}
							}
						} else if (dragVO.target is PCView) {
							if (dragVO.dragged_itemstack.is_soulbound_to_me) {
								Cursor.instance.showTip('<font color="#cc0000">You can\'t give this item away!</font>');
							} else {
								Cursor.instance.showTip('Give');
								Cursor.instance.drag_DO.alpha = 1;
							}
						} else if (dragVO.target is LocationItemstackView) {
							var target_lis_view:LocationItemstackView = dragVO.target as LocationItemstackView;
							HandOfDecorator.instance.LIPisHandlingTheDragNow();
							
							var ob:Object = dragVO.receptive_location_items[target_lis_view.item.tsid];
							if (!ob) ob = dragVO.receptive_location_itemstacks[target_lis_view.tsid];
							
							if (ob) {
								if (ob.disabled) {
									Cursor.instance.showTip('<font color="#cc0000">'+ob.tip+'</font>', true);
								} else {
									Cursor.instance.showTip(ob.tip, true);
								}
							} else {
								Cursor.instance.showTip('huh?', true);
							}	
							Cursor.instance.drag_DO.alpha = 1;
						} else {
							Cursor.instance.hideTip();
							Cursor.instance.drag_DO.alpha = .5;
						}
					}
				} else {
					if (dragVO.target) {
						dragVO.target.unhighlightOnDragOut();
						dragVO.target = null;
						Cursor.instance.hideTip();
						Cursor.instance.drag_DO.alpha = .5;
					}
				}
			} else {
				if (dragVO.target && isTargetOneOfMine(dragVO.target)) {
					dragVO.target.unhighlightOnDragOut();
					dragVO.target = null;
				}
				Cursor.instance.hideTip();
				Cursor.instance.drag_DO.alpha = .5;
				HandOfDecorator.instance.LIPisHandlingTheDragNow();
			}
		}	
		
		private function _furnitureBagDragCompleteHandler(e:TSEvent):void {
			StageBeacon.mouse_move_sig.remove(_furnitureBagDragMoveHandler);
			
			if (dragVO.target) {
				var target_itemstack:Itemstack;
				var target_item:Item;
				var target_lis_view:LocationItemstackView;
				
				if (dragVO.target == _locationRenderer) {
					if (dragVO.dragged_itemstack.item.is_furniture) {
						HandOfDecorator.instance.dropFurnitureFromBagOnTargetPlatform();
					} else {
						var plat_to_drop_on:Boolean = isThereASpecificPlatToDropRegStackOn();
						if (plat_to_drop_on) {
							if (dragVO.dragged_itemstack.item.is_special_furniture) {
								HandOfDecorator.instance.dropFurnitureFromBagOnTargetPlatform();
							} else {
								HandOfDecorator.instance.dropItemFromPackOnTargetPlatform();
							}
						}
					}
				} else if (dragVO.target is LocationItemstackView) {
					target_lis_view = dragVO.target as LocationItemstackView;
					target_itemstack = target_lis_view.itemstack;
					target_item = target_itemstack.item;
					
					var ob:Object = dragVO.receptive_location_items[target_item.tsid];
					if (!ob || ob.disabled) ob = dragVO.receptive_location_itemstacks[target_itemstack.tsid];
					if (ob && !ob.disabled) {
						var verb_tsid:String = ob.verb;
						
						var verb:Verb = target_item.getVerbByTsid(verb_tsid); // we /might/ have it.
						
						// not being optimistic anymore, calling everytime
						if (false && verb && verb.enabled) { 
							TSFrontController.instance.startItemstackMenuWithVerbAndTargetItem(
								target_itemstack, verb, dragVO.dragged_itemstack.item, dragVO.dragged_itemstack, true // true here because we do not have to make any calls to the server
							);
						} else {
							TSFrontController.instance.genericSend(
								new NetOutgoingItemstackVerbMenuVO(target_itemstack.tsid, false, ((dragVO.dragged_itemstack) ? dragVO.dragged_itemstack.tsid : '')),
								function(rm:NetResponseMessageVO):void {
									var verb:Verb = target_item.verbs[verb_tsid]; // conditional_verbs got updated in netcontroller by this msg rsp
									if (rm.success && verb && verb.enabled) { // we have the the Verb now
										TSFrontController.instance.startItemstackMenuWithVerbAndTargetItem(
											target_itemstack, verb, dragVO.dragged_itemstack.item, dragVO.dragged_itemstack, true
										);
									}
								},
								null
							);
						}
					}
					
				} else if (dragVO.target is PCView) {
					if (dragVO.dragged_itemstack.is_soulbound_to_me) {
					} else {
						// this pops up the count menu as if they had already chosen "give" and an itemstack
						TSFrontController.instance.startPcGiveMenuWithItemstack(PCView(dragVO.target).tsid, dragVO.dragged_itemstack, true);
					}
				}
				
				dragVO.target.unhighlightOnDragOut();
				Cursor.instance.hideTip();
			}
		}
		
		private function _packDragStartHandler(e:TSEvent):void {
			if (!_locationRenderer.accepting_drags) return;
			dragVO.setReceptiveLocationItemstacksForDrag(_packDragMoveHandler);
			StageBeacon.mouse_move_sig.add(_packDragMoveHandler);
		}
		
		private function isThereASpecificPlatToDropRegStackOn():Boolean {
			var pt:Point = _locationRenderer.getMouseXYinMiddleground();
			return HandOfDecorator.instance.calculateTargetPlatformLineForRegStackFromPt(pt);
		}
		
		private function _packDragMoveHandler(e:MouseEvent=null):void {
			if (!_locationRenderer.accepting_drags) return;
			if (!Cursor.instance.drag_DO) return;
			if (_locationRenderer.hitTestObject(Cursor.instance.drag_DO)) {
				var target:IDragTarget = dragVO.findDragTargetForStack();
				if (!target && dragVO.dragged_itemstack.item.dropable) {
					target = _locationRenderer;
				}
				if (target) {
					var plat_to_drop_on:Boolean;
					if (target == _locationRenderer) {
						plat_to_drop_on = (dragVO.can_drop && isThereASpecificPlatToDropRegStackOn());
					}
					if (target != dragVO.target || plat_to_drop_on) {
						var target_lis_view:LocationItemstackView;
						if (target is LocationItemstackView) {
							target_lis_view = target as LocationItemstackView;
						}
						
						if (dragVO.target != target) {
							if (dragVO.target) dragVO.target.unhighlightOnDragOut();
							dragVO.target = target; // tuck a reference to the target in the dragVO
							if (target_lis_view && target_lis_view.item.tsid == 'npc_fox') {
								// do not highlight the fox
							} else {
								dragVO.target.highlightOnDragOver();
							}
						}
						
						if (dragVO.target == _locationRenderer && dragVO.can_drop) {
							if (plat_to_drop_on) {
								Cursor.instance.showTip('Place');
							} else {
								Cursor.instance.showTip('Drop at your feet');
							}
						} else if (dragVO.target is PCView) {
							if (dragVO.dragged_itemstack.is_soulbound_to_me) {
								Cursor.instance.showTip('<font color="#cc0000">You can\'t give this item away!</font>');
							} else {
								Cursor.instance.showTip('Give');
								Cursor.instance.drag_DO.alpha = 1;
							}
						} else if (dragVO.target is GardenPlotView) {
							GardenPlotView(dragVO.target).handleDrag(dragVO.dragged_itemstack.class_tsid);
						} else if (dragVO.target is LocationItemstackView) {
							HandOfDecorator.instance.LIPisHandlingTheDragNow();
							
							var ob:Object = dragVO.receptive_location_items[target_lis_view.item.tsid];
							if (!ob) ob = dragVO.receptive_location_itemstacks[target_lis_view.tsid];
							if (!ob) ob = dragVO.receptive_cabinets[target_lis_view.itemstack.tsid];
							
							if (ob) {
								if (ob.disabled) {
									Cursor.instance.showTip('<font color="#cc0000">'+ob.tip+'</font>');
								} else {
									Cursor.instance.showTip(ob.tip);
								}
							} else {
								Cursor.instance.showTip('huh?');
							}	
						} else {
							Cursor.instance.hideTip();
						}
					}
				} else {
					if (dragVO.target) {
						dragVO.target.unhighlightOnDragOut();
						dragVO.target = null;
						Cursor.instance.hideTip();
					}
				}
			} else {
				if (dragVO.target && isTargetOneOfMine(dragVO.target)) {
					dragVO.target.unhighlightOnDragOut();
					dragVO.target = null;
					Cursor.instance.hideTip();
				}
				HandOfDecorator.instance.LIPisHandlingTheDragNow();
			}
		}
		
		private function _packDragCompleteHandler(e:TSEvent):void {
			StageBeacon.mouse_move_sig.remove(_packDragMoveHandler);
			
			if (!_locationRenderer.accepting_drags) {
				if (dragVO && dragVO.target) dragVO.target.unhighlightOnDragOut();
				Cursor.instance.hideTip();
				return;
			}
			
			if (dragVO.target) {
				var target_itemstack:Itemstack;
				var target_item:Item;
				var target_lis_view:LocationItemstackView;
				
				if (dragVO.target == _locationRenderer) {
					
					if (dragVO.can_drop) {
						var plat_to_drop_on:Boolean = (dragVO.target == _locationRenderer) && dragVO.can_drop && isThereASpecificPlatToDropRegStackOn();
						if (plat_to_drop_on) {
							HandOfDecorator.instance.dropItemFromPackOnTargetPlatform();
						} else {
							TSFrontController.instance.genericSend(
								new NetOutgoingItemstackVerbMenuVO(dragVO.dragged_itemstack.tsid),
								function(rm:NetResponseMessageVO):void {
									var verb:Verb = dragVO.dragged_itemstack.item.verbs['drop']; // conditional_verbs got updated in netcontroller by this msg rsp
									if (rm.success && verb && verb.enabled) { // we have the the Verb now
										TSFrontController.instance.startItemstackMenuWithVerb(
											dragVO.dragged_itemstack, verb, true
										);
									}
									/*verb = dragVO.dragged_itemstack.item.verbs['place'];
									if (rm.success && verb && verb.enabled) { // we have the the Verb now
									TSFrontController.instance.startItemstackMenuWithVerb(
									dragVO.dragged_itemstack, verb, true
									);
									}*/
								},
								null
							);
							/*TSFrontController.instance.sendItemstackVerb(
							new NetOutgoingItemstackVerbVO(dragVO.dragged_itemstack.tsid, 'drop', dragVO.dragged_itemstack.count)
							);*/
						}
					} else {
						if (dragVO.dragged_itemstack.class_tsid == 'fox_brush' && dragVO.receptive_location_items['npc_fox']) {
							var fox_array:Array = model.worldModel.getLocationItemstacksAByItemClass('npc_fox');
							var fox_tsid:String = fox_array.length ? fox_array[0].tsid : null;

							// we missed, pass no brush tsid
							TSFrontController.instance.brushFox(fox_tsid, null);
						}
					}
					
				} else if (dragVO.target is LocationItemstackView) {
					target_lis_view = dragVO.target as LocationItemstackView;
					target_itemstack = target_lis_view.itemstack;
					target_item = target_itemstack.item;
					
					//let's check if this is a cabinet first
					var good_cab_target:Boolean
					ob = dragVO.receptive_cabinets[target_itemstack.tsid];
					if (ob && !ob.disabled) good_cab_target = true;
					
					if(good_cab_target){
						TSFrontController.instance.genericSend(
							new NetOutgoingInventoryMoveVO(
								dragVO.dragged_itemstack.tsid,
								dragVO.dragged_itemstack.container_tsid,
								target_lis_view.tsid
							)
						);
						
						dragVO.target.unhighlightOnDragOut();
						Cursor.instance.hideTip();
						return;
					}
					
					var ob:Object = dragVO.receptive_location_items[target_item.tsid];
					if (!ob || ob.disabled) ob = dragVO.receptive_location_itemstacks[target_itemstack.tsid];
					if (ob && !ob.disabled) {
						var verb_tsid:String = ob.verb;
						
						// special case the shit out ofr brushing the fox
						if (verb_tsid == 'brush' && target_item.tsid == 'npc_fox') {
							TSFrontController.instance.brushFox(target_itemstack.tsid, dragVO.dragged_itemstack.tsid);
						} else {
							var verb:Verb = target_item.getVerbByTsid(verb_tsid); // we /might/ have it.
							
							// not being optimistic anymore, calling everytime
							if (false && verb && verb.enabled) { 
								TSFrontController.instance.startItemstackMenuWithVerbAndTargetItem(
									target_itemstack, verb, dragVO.dragged_itemstack.item, dragVO.dragged_itemstack, true // true here because we do not have to make any calls to the server
								);
							} else {
								TSFrontController.instance.genericSend(
									new NetOutgoingItemstackVerbMenuVO(target_itemstack.tsid, false, ((dragVO.dragged_itemstack) ? dragVO.dragged_itemstack.tsid : '')),
									function(rm:NetResponseMessageVO):void {
										var verb:Verb = target_item.verbs[verb_tsid]; // conditional_verbs got updated in netcontroller by this msg rsp
										if (rm.success && verb && verb.enabled) { // we have the the Verb now
											TSFrontController.instance.startItemstackMenuWithVerbAndTargetItem(
												target_itemstack, verb, dragVO.dragged_itemstack.item, dragVO.dragged_itemstack, true
											);
										}
									},
									null
								);
							}
						}
					}
					
				} else if (dragVO.target is PCView) {
					if (dragVO.dragged_itemstack.is_soulbound_to_me) {
					} else {
						// this pops up the count menu as if they had already chosen "give" and an itemstack
						TSFrontController.instance.startPcGiveMenuWithItemstack(PCView(dragVO.target).tsid, dragVO.dragged_itemstack, true);
					}
					
				} else if (dragVO.target is GardenPlotView) {
					//we've dropped something on the plot, let's see if we can use it
					GardenPlotView(dragVO.target).handleDrop(dragVO.dragged_itemstack.class_tsid);
					Cursor.instance.hideTip();
					return;
				}
				
				dragVO.target.unhighlightOnDragOut();
				Cursor.instance.hideTip();
			}
		}		
		
		
		private function isTargetOneOfMine(target:IDragTarget):Boolean {
			return (dragVO.target is LocationItemstackView || dragVO.target is PCView || dragVO.target == _locationRenderer)
		}		
		
		// called ONLY when user has clicked something, from _tryActOnClickedElement
		private function _moveAvatarToSpriteAndStartInteraction(interaction_sprite:DisplayObject, sign:SignpostSignView = null):void {
			// allows us to click on a specific sign of a signpost and have it acted  on when you get to the sign
			model.stateModel.interaction_sign = sign;
			
			// go ahead and start interaction, if the avtar is already over the interaction_sprite
			if (_locationRenderer.pc.apo._interaction_spV.indexOf(interaction_sprite as TSSprite) > -1) {
				TSFrontController.instance.startInteractionWith(interaction_sprite, true);
				return;
			}

			if (interaction_sprite is LocationItemstackView) {
				// test for if we really need to move here
				if (model.flashVarModel.dont_move_for_item_menu) {
					TSFrontController.instance.startInteractionWith(interaction_sprite, true);
					return;
				}
			}

			if (interaction_sprite is PCView && !model.worldModel.getPCByTsid(interaction_sprite.name).fake) {
				if (interaction_sprite.x > model.worldModel.pc.x) {
					_locationRenderer.getAvatarView().faceRight()
				} else if (interaction_sprite.x < model.worldModel.pc.x) {
					_locationRenderer.getAvatarView().faceLeft()
				}
				
				TSFrontController.instance.startInteractionWith(interaction_sprite, true);
				return;
			}

			// otherwise start moving
			TSFrontController.instance.startUserInitiatedPath(interaction_sprite);
		}		
		
		public function set locationRenderer(value:LocationRenderer):void {
			stopListeningForControlEvts();
			
			if (_locationRenderer) {
				_locationRenderer.location_view_changed_sig.remove(onLocationViewChanged);
			}
			
			_locationRenderer = value;
			_locationView = _locationRenderer.locationView;
			_locationRenderer.location_view_changed_sig.add(onLocationViewChanged);
			startListeningForControlEvts();
		}
		
		private function onLocationViewChanged(locationView:LocationView):void {
			if (_locationView) stopListeningToLocationView();
			
			_locationView = locationView;
			startListeningToLocationView();
		}
		
		private function stopListeningToLocationView():void {
			if (!_locationView) return;
			_locationView.clicked.remove(onLocationViewClicked);
			_locationView.mouseDown_sig.remove(onLocationViewMouseDown);
		}
		
		private function startListeningToLocationView():void {
			if (!_locationView) return;
			_locationView.clicked.add(onLocationViewClicked);
			_locationView.mouseDown_sig.add(onLocationViewMouseDown);
		}
		
		private function onLocationViewMouseDown(listView:LocationItemstackView):void {
			_locMouseDownHandler(null, listView);
		}
	}
}