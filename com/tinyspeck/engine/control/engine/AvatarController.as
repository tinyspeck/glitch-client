package com.tinyspeck.engine.control.engine {
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.control.IController;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.NewxpLogger;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.Ladder;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.net.NetOutgoingFollowEndVO;
	import com.tinyspeck.engine.physics.avatar.AvatarPhysicsObject;
	import com.tinyspeck.engine.port.CultManager;
	import com.tinyspeck.engine.port.TSSprite;
	import com.tinyspeck.engine.view.PCView;
	import com.tinyspeck.engine.view.gameoverlay.CameraMan;
	import com.tinyspeck.engine.view.geo.DoorView;
	import com.tinyspeck.engine.view.geo.LadderView;
	import com.tinyspeck.engine.view.geo.SignpostView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.ui.ChatGodDebug;
	
	import flash.display.InteractiveObject;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;
		
	public class AvatarController extends AbstractController implements IController {
		public var is_started:Boolean;
		
		// AFK is 120 seconds
		private static const AFK_TIMEOUT:int = 120*1000;
		
		private const keyBeacon:KeyBeacon = KeyBeacon.instance;
		
		private var apo:AvatarPhysicsObject;
		private var afkTimer:int;
		
		// SWF_auto_zoom related
		CONFIG::god private var activityEventFired:Boolean = false;
		CONFIG::god private var sedentaryEventFired:Boolean = false;
		CONFIG::god private var lastActivityTime:int = 0;
		CONFIG::god private var earliestZoomInTime:int = 0;
		CONFIG::god private var earliestZoomOutTime:int = 0;
		CONFIG::god private var wasMoving:Boolean = false;
		CONFIG::god private var wasAccelerating:Boolean = false;
		
		public function AvatarController() {
			model.netModel.registerCBProp(onDisconnected, "disconnected_msg");
			model.stateModel.registerCBProp(onCultMode, "cult_mode");

			// afk stuff
			TSFrontController.instance.afk_sig.add(onAFKChanging);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_, allKeyHandler);
			StageBeacon.mouse_click_sig.add(allClickHandler);
		}
		
		private function onDisconnected(msg:String):void {
			stop('AC.onDisconnected');
		}
		
		private function onCultMode(enabled:Boolean):void {
			// make avatar 50% opaque when in cult mode
			TSFrontController.instance.getMainView().gameRenderer.getAvatarView().alpha = (enabled ? 0.5 : 1);
		}
		
		override public function run():void {
			afkTimer = getTimer();
		}
		
		public function start(deets:String):void {
			Benchmark.addCheck('AC.start is_started:'+is_started+ ' deets:'+deets);
			if (is_started) return;
			is_started = true;
			apo = model.worldModel.pc.apo;
			startListeningForControlEvts();
		}
		
		public function stop(deets:String):void {
			if (!is_started) return;
			is_started = false;
			Benchmark.addCheck('AC.stop '+deets);
			stopListeningForControlEvts();
		}
		
		private function startListeningForControlEvts():void {
			keyBeacon.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DOWN, onDownKey);
			keyBeacon.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.UP, onUpKey);
			keyBeacon.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, onRightKey);
			keyBeacon.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, onLeftKey);
			keyBeacon.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.SPACE, onSpaceKey);
			
			// WASD
			keyBeacon.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.S, onDownKey);
			keyBeacon.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.W, onUpKey);
			keyBeacon.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.D, onRightKey);
			keyBeacon.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.A, onLeftKey);
			
			if (apo) apo.ignore_keys = false;
		}
		
		private function stopListeningForControlEvts():void {
			keyBeacon.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DOWN, onDownKey);
			keyBeacon.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.UP, onUpKey);
			keyBeacon.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, onRightKey);
			keyBeacon.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, onLeftKey);
			keyBeacon.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.SPACE, onSpaceKey);
			
			// WASD
			keyBeacon.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.S, onDownKey);
			keyBeacon.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.W, onUpKey);
			keyBeacon.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.D, onRightKey);
			keyBeacon.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.A, onLeftKey);
			
			if (apo) apo.ignore_keys = true;
		}
		
		public function endPath(keep_pathing_until_you_intersect:Boolean=false):void { 
			if (!apo) {
				/*CONFIG::debugging {
					Console.error('WTF no apo?');
				}*/
				return;
			}
			if (apo.path_destination && apo.path_destination_pt) {
				CONFIG::debugging {
					Console.log(44, 'endPath apo.path_destination_pt:'+apo.path_destination_pt+' apo.path_destination:'+apo.path_destination);
				}
				
				// need to check it is an interactionSprite here
				
				// _findInteractionSprites seems unnec, and causes problems when PhysicController's isCheckingForInteractionSprites is false
				// (because in that case we do not want to check for interaction sprotes, which triggers glows and trant tending UI etc)
				//TSFrontController.instance.getMainView().gameRenderer._findInteractionSprites();
				CONFIG::debugging {
					Console.log(44, 'endPath apo._interaction_spV.indexOf(apo.path_destination):'+apo._interaction_spV.indexOf(apo.path_destination as TSSprite));
				}
				
				var objs:Vector.<LocationItemstackView>;
				var by_click:Boolean;
				
				objs = TSFrontController.instance.getMainView().gameRenderer.getItemstacksUnderCursor();
				by_click = objs.indexOf(apo.path_destination as LocationItemstackView) != -1;
				
				AnnouncementController.instance.cancelOverlay('get_closer', true);
				
				if (apo._interaction_spV.indexOf(apo.path_destination as TSSprite) != -1 || (apo.path_destination is LocationItemstackView && LocationItemstackView(apo.path_destination).itemstack.is_clickable)) {
					if (!('chat_bubble_type' in apo.path_destination)) { // I wish I knew what this check was for, but chat_bubble_type is nowhere else in client code
						if (apo.path_destination.visible && apo.path_destination.interactionTargetIsVisible()) {
							if (model.stateModel.to_do_when_arriving_at_dest && apo.path_destination is LocationItemstackView) {
								TSFrontController.instance.doVerbOrActionAfterPath(LocationItemstackView(apo.path_destination).tsid, model.stateModel.to_do_when_arriving_at_dest);
								model.stateModel.to_do_when_arriving_at_dest = null;
								keep_pathing_until_you_intersect = false;
							} else {
								TSFrontController.instance.startInteractionWith(TSSprite(apo.path_destination), by_click);
								keep_pathing_until_you_intersect = false;
							}
						} else {
							; // satisfy compiler
							CONFIG::god {
								if (model.flashVarModel.interact_with_all) {
									TSFrontController.instance.startInteractionWith(TSSprite(apo.path_destination), by_click);
									keep_pathing_until_you_intersect = false;
								}
							}
						}
					} else {
						TSFrontController.instance.startInteractionWith(TSSprite(apo.path_destination), by_click);
					}
				} else {
					if (apo.path_destination is LocationItemstackView) {
						if (apo.path_destination.tsid) {
							var itemstack:Itemstack = model.worldModel.getItemstackByTsid(apo.path_destination.tsid);
							if (itemstack) {
								// we use this for nudgery
								if (model.stateModel.to_do_when_arriving_at_dest is Function && apo.path_destination is LocationItemstackView) {
									TSFrontController.instance.doVerbOrActionAfterPath(LocationItemstackView(apo.path_destination).tsid, model.stateModel.to_do_when_arriving_at_dest);
									model.stateModel.to_do_when_arriving_at_dest = null;
									keep_pathing_until_you_intersect = false;
								} else if (model.stateModel.can_decorate || itemstack.item.is_interactable_furniture) {
									TSFrontController.instance.startInteractionWith(TSSprite(apo.path_destination), by_click);
									keep_pathing_until_you_intersect = false;
								}
							}
						}
					} else if (apo.path_destination is DoorView) {
						if (Math.abs(model.worldModel.pc.y-apo.path_destination.y) < 300) {
							TSFrontController.instance.startInteractionWith(TSSprite(apo.path_destination), by_click);
							keep_pathing_until_you_intersect = false;
						}
					}
					
					if (keep_pathing_until_you_intersect) {
						var was_path_destination_pt_x:int = apo.path_destination_pt.x;
						beginPath(apo.path_destination, model.stateModel.to_do_when_arriving_at_dest);
						// make sure we're actually going to move again!
						if (apo.path_destination_pt.x == was_path_destination_pt_x) {
							endPath();
						}
						return;
					}
				}
			}
			
			const was_on_path:Boolean = apo.onPath;
			apo.onPath = false;
			if (apo.path_destination != null && apo.path_destination_pt != null) {
				apo.path_destination = null;
				apo.path_destination_pt = null;
			}
			
			if (was_on_path) {
				apo.triggerReduceVelocity = true;
				TSFrontController.instance.onAvatarPathEnded('AC.endPath');
			}
		}
		
		/**
		 * TODO : Move path initiation to view, move pathing to controller.
		 */
		public function beginPath(destination:Object, verb_or_action:Object=null, requires_intersection:Boolean=true, max_offset:int=0, auto:Boolean=false):void {
			model.stateModel.to_do_when_arriving_at_dest = verb_or_action;
			model.stateModel.requires_intersection = requires_intersection;
				
			endPath();
			if (!apo) {
				/*CONFIG::debugging {
					Console.error('WTF no apo?');
				}*/
				return;
			}
			apo.onPath = true;
			apo.path_destination = destination;
			var dest_x:int;
			var pc:PC = model.worldModel.pc;
			max_offset = (!requires_intersection && max_offset) ? max_offset : 70;
			var offset:int;
			if (destination is LocationItemstackView) {
				var liv:LocationItemstackView = destination as LocationItemstackView;
				offset = Math.min((Math.abs(pc.x-liv.x_of_int_target)*.5), max_offset); // lessens the offset the closer you are
				dest_x = (pc.x < liv.x_of_int_target) ? liv.x_of_int_target-offset : liv.x_of_int_target+offset;
				apo.path_destination_pt = new Point(dest_x, destination.y);
				CONFIG::debugging {
					Console.info('_beginPath to '+getQualifiedClassName(destination)+' :'+apo.path_destination_pt+' liv.x_of_int_target:'+liv.x_of_int_target+' liv.x:'+liv.x);
				}
			} else if (destination is PCView) {
				offset = Math.min((Math.abs(pc.x-destination.x)*.5), max_offset); // lessens the offset the closer you are
				dest_x = (pc.x < destination.x) ? destination.x-offset : destination.x+offset;
				apo.path_destination_pt = new Point(dest_x, destination.y);
				CONFIG::debugging {
					Console.log(44, '_beginPath to '+getQualifiedClassName(destination)+' :'+apo.path_destination_pt);
				}
			} else if (destination is DoorView) {
				apo.path_destination_pt = new Point(destination.x, destination.y);
				try {
					var door_view:DoorView = destination as DoorView;
					// handle if the interaction_target is not in the center (alakol houses)
					if (door_view.interaction_target != destination) {
						CONFIG::debugging {
							Console.log(44, 'door_view.interaction_target != destination so I am trying to find the point where the door is actually');
						}
						var bounds_rect:Rectangle = door_view.interactionBounds;
						apo.path_destination_pt.x+= bounds_rect.x+(bounds_rect.width/2)
					}
				} catch (err:Error) {
					CONFIG::debugging {
						Console.warn('error trying to adjust apo.path_destination_pt on a DorrView');
					}
				}
				CONFIG::debugging {
					Console.log(44, '_beginPath to Door:'+apo.path_destination_pt);
				}
			} else if (destination is LadderView) {
				apo.path_destination_pt = new Point(destination.x, destination.y);
				CONFIG::debugging {
					Console.log(44, '_beginPath to Ladder:'+apo.path_destination_pt);
				}
			} else if (destination is SignpostView) {
				apo.path_destination_pt = new Point(destination.x, destination.y);
				CONFIG::debugging {
					Console.log(44, '_beginPath to Signpost:'+apo.path_destination_pt);
				}
			} else if (destination is Point) {
				apo.path_destination_pt = destination as Point;
				CONFIG::debugging {
					Console.log(44, '_beginPath to pt:'+apo.path_destination_pt);
				}
			} else if (destination is String) {
				const renderer:LocationRenderer = TSFrontController.instance.getMainView().gameRenderer;
				var beginAt:Object = renderer.getSignpostViewByTsid(destination as String);
				beginAt = beginAt ? beginAt : renderer.getDoorViewByTsid(destination as String);
				beginAt = beginAt ? beginAt : renderer.getPcViewByTsid(destination as String);
				if (beginAt) beginPath(beginAt);
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.log(44, '_beginPath Failed: unrecognized model.moveModel.path_destination:'+getQualifiedClassName(destination));
				}
			}
			
			if (!apo.path_destination_pt) {
				apo.onPath = false;
				CONFIG::debugging {
					Console.warn('wtf, no path_destination_pt');
				}
				return;
			}
			
			getOffLadder();
			beingActive();
			
			CONFIG::god { 
				if (auto) {
					CameraMan.instance.letCameraSnapBackFast();
					model.worldModel.pc.x = apo.path_destination_pt.x;
					model.worldModel.pc.y = apo.path_destination_pt.y;
					endPath();
				}
			}
		}

		/** Callback when TSFC overrides AFK status */
		private function onAFKChanging(goingAFK:Boolean):void {
			if (goingAFK) {
				stopAFKTimer();
			} else {
				restartAFKTimer();
			}
		}
		
		private function restartAFKTimer():void {
			afkTimer = getTimer();
		}
		
		private function stopAFKTimer():void {
			afkTimer = int.MAX_VALUE;
		}
		
		private function beingActive():void {
			// stop being AFK just in case we are AFK
			TSFrontController.instance.goNotAFK();
		}
		
		private function allClickHandler(e:MouseEvent):void {
			restartAFKTimer();
		}
		
		private function allKeyHandler(e:KeyboardEvent):void {
			restartAFKTimer();
		}
				
		private function onRightKey(e:Event):void {
			if (shouldIgnoreKeyPress()) return;
			onRightOrLeftKey(apo.vx<=0);
		}
		
		private function onLeftKey(e:Event):void {
			if (shouldIgnoreKeyPress()) return;
			onRightOrLeftKey(apo.vx>=0);
		}
		
		private function onRightOrLeftKey(reset:Boolean):void {
			beingActive();
			_endFollowing();
			// if we were moving in the other direction reset some shit
			endPath();
			if (reset) {
				// default location friction_floor is 4.3; we assume if it is less than 3, then it is icy, so do not reset velocity
				if (apo.setting.friction_floor < 3) {
					apo.triggerResetVelocityXPerc = true;
				} else {
					apo.triggerResetVelocityX = true;
				}
			}
			if (apo.onLadder) {
				getOffLadder();
			}
		}
		
		public function onSpaceKey(e:Event = null):void {
			if (model.stateModel.cult_mode && CultManager.instance.carrying) return;
			if (shouldIgnoreKeyPress()) return;
			beingActive();
			_endFollowing();
			endPath();
			if (apo.onLadder) {
				getOffLadder();
			}

			// we want to measure time when the key is pressed, not in 
			// functions run in game loops so we can measure time correctly
			apo.triggerJump_time = getTimer();

			apo.triggerJump = true;
			
			// ChatGodDebug.instance.parse('/missile butler', '');
			
			NewxpLogger.log('jump');
		}
		
		private function shouldIgnoreKeyPress():Boolean {
			CONFIG::perf {
				if (model.flashVarModel.run_automated_tests) return true;
			}
			
			const focusObject:InteractiveObject = StageBeacon.stage.focus;
			return (focusObject && (focusObject is TextField) && (TextField(focusObject).type == TextFieldType.INPUT));
		}
		
		private function onDownKey(e:Event):void {
			if (shouldIgnoreKeyPress()) return;
			beingActive();
			_endFollowing();
			endPath();
			_beginInteractionAfterDownKey();
		}
		
		private function _endFollowing():void {
			if (model.worldModel.pc.following_pc_tsid) {
				TSFrontController.instance.sendFollowEnd(new NetOutgoingFollowEndVO());
			}
		}
		
		private function _beginInteractionAfterDownKey():void {
			if (!apo.onLadder && apo._interaction_spV.length) {
				// if over a ladder, get on it
				for each (var sprite:TSSprite in apo._interaction_spV) {
					if (sprite is LadderView) {
						getOnLadder(model.worldModel.location.mg.getLadderById(sprite.tsid));
						break;
					}
				}
			}
		}
		
		private function onUpKey(e:Event):void {
			if (shouldIgnoreKeyPress()) return;
			beingActive();
			_endFollowing();
			endPath();
			_beginInteractionAfterUpKey();
		}
		
		private function _beginInteractionAfterUpKey():void {
			if (apo.onLadder) return;
			if (!apo._interaction_spV.length) return;

			var all_interaction_sps_are_PCs:Boolean = true; // if we find any that are not PCs, then this will be set to false
			
			const interaction_spA:Vector.<TSSprite> = apo._interaction_spV;
			for (var i:int=interaction_spA.length-1; i>=0; --i) {
				if (!(interaction_spA[int(i)] is PCView)) all_interaction_sps_are_PCs = false;
				
				// just choose the ladder (uncomment for signpost or door) if there is one
				if (interaction_spA[int(i)] is LadderView/* || interaction_spA[int(i)] is SignpostView || interaction_spA[int(i)] is DoorView*/) {
					TSFrontController.instance.startInteractionWith(TSSprite(apo._interaction_spV[int(i)]));
					return;
				}
			}
			
			if (!model.prefsModel.up_key_is_enter) return;
			
			// if this location has a geo flag to prevent up key from doing menus, obey it!
			if (model.worldModel.location && model.worldModel.location.no_up_arrow_for_menus) return;
			
			// if they are all pcs, don't open the menu! (so that games work better)
			if (all_interaction_sps_are_PCs) return;
			
			if (apo._interaction_spV.length == 1) {
				TSFrontController.instance.startInteractionWith(apo._interaction_spV[0]);
			} else { // must choose from possible sprites
				TSFrontController.instance.startLocationDisambiguator(apo._interaction_spV);
			}
		}
		
		public function getOnLadder(ladder:Ladder):void {
			apo.triggerGetOnLadder = true;
			apo.targetLadder = ladder;
		}
		
		public function getOffLadder():void {
			if (apo && apo.onLadder) apo.triggerGetOffLadder = true;
		}
		
		public function onGameLoop(ms_elapsed:int):void {
			const currentTimer:int = getTimer();
			if ((currentTimer - afkTimer) > AFK_TIMEOUT) {
				TSFrontController.instance.goAFK();
				stopAFKTimer();
			}
			
			if (apo && apo.onPath) {
				if (apo.path_destination_pt && apo.path_destination) {
					const pc:PC = model.worldModel.pc;
					const allowance:int = (
						model.stateModel.avatar_gs_path_pt
						? model.physicsModel.gs_path_end_allowance
						: model.physicsModel.path_end_allowance
					);
				 	if ((apo.path_destination_pt.x > pc.x-allowance) && (apo.path_destination_pt.x < pc.x+allowance)) {
						const keep_pathing_until_you_intersect:Boolean = model.stateModel.requires_intersection && apo.path_destination is LocationItemstackView;
				 		endPath(keep_pathing_until_you_intersect);
						CONFIG::debugging {
							Console.trackPhysicsValue(' AC.onGameLoop path check', 'ENDED');
						}
					 } else {
						 CONFIG::debugging {
							 Console.trackPhysicsValue(' AC.onGameLoop path check', 'dx:'+apo.path_destination_pt.x+' pcx'+pc.x+' a'+allowance);
						 }
					 }
			 	}
			}
		}
	}
}