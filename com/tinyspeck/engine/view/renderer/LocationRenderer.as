package com.tinyspeck.engine.view.renderer {
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.admin.locodeco.components.IControlPoints;
	import com.tinyspeck.engine.control.HandOfDecorator;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.control.engine.AnnouncementController;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.Door;
	import com.tinyspeck.engine.data.location.Layer;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.location.MiddleGroundLayer;
	import com.tinyspeck.engine.data.location.PlatformLine;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.physics.data.PhysicsQuery;
	import com.tinyspeck.engine.spritesheet.SSViewSprite;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.IDragTarget;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.AvatarView;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.PCView;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.gameoverlay.CameraMan;
	import com.tinyspeck.engine.view.gameoverlay.GrowlView;
	import com.tinyspeck.engine.view.gameoverlay.InLocationOverlay;
	import com.tinyspeck.engine.view.geo.DoorView;
	import com.tinyspeck.engine.view.geo.LadderView;
	import com.tinyspeck.engine.view.geo.SignpostView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.renderer.commands.LocationCommands;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocItemstackAddDelConsumer;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocItemstackUpdateConsumer;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocPcAddDelConsumer;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocPcUpdateConsumer;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import org.osflash.signals.Signal;
	
	CONFIG::god { import com.tinyspeck.engine.admin.locodeco.components.MultiControlPoints; }
	CONFIG::god { import com.tinyspeck.engine.data.location.Box; }
	CONFIG::god { import com.tinyspeck.engine.data.location.Target; }
	CONFIG::god { import com.tinyspeck.engine.view.gameoverlay.maps.MiniMapView; }
	CONFIG::god { import com.tinyspeck.engine.view.geo.BoxView; }
	CONFIG::god { import com.tinyspeck.engine.view.geo.PlatformLineView; }
	CONFIG::god { import com.tinyspeck.engine.view.geo.TargetView; }
	CONFIG::god { import com.tinyspeck.engine.view.geo.WallView; }
	CONFIG::locodeco { import com.tinyspeck.engine.data.location.AbstractPositionableLocationEntity; }
	CONFIG::locodeco { import com.tinyspeck.engine.data.location.Wall; }
	CONFIG::locodeco { import locodeco.LocoDecoGlobals; }
	
	CONFIG const LOC_VP_RECT_COLLISION_SCALE_FOR_SNAPPING:int = 100;

	final public class LocationRenderer extends DisposableSprite implements IDragTarget, ITipProvider, ILocItemstackAddDelConsumer, ILocPcAddDelConsumer, ILocPcUpdateConsumer, ILocItemstackUpdateConsumer {
		public static const READYING_TEXT:String = 'reticulating splines...';
		
		public const location_view_changed_sig:Signal = new Signal(LocationView);
		public const lis_view_worth_rendering_sig:Signal = new Signal(LocationItemstackView);
		public const pc_view_worth_rendering_sig:Signal = new Signal(PCView);
		
		CONFIG::locodeco public var disableHighlighting:Boolean;
		
		/** Optimized to only re-render AbstractLayerRenderers that are dirty */
		CONFIG::locodeco public var decoModelDirty:Boolean;
		CONFIG::locodeco public var layerModelDirty:Boolean;
		
		/** Optimized to only re-render AbstractLayerRenderers that are dirty */
		CONFIG::locodeco public var filtersDirty:Boolean;
		CONFIG::locodeco public var gradientDirty:Boolean;
		
		CONFIG::locodeco public const dirtyRenderers:Vector.<IAbstractDecoRenderer> = new Vector.<IAbstractDecoRenderer>();
		public const dirtySignpostViews:Vector.<SignpostView> = new Vector.<SignpostView>();
		public const dirtyDoorViews:Vector.<DoorView> = new Vector.<DoorView>();
		
		public var scrolling_overlay_holder:Sprite;
		private var scrolling_overlay_top:Sprite;
		public var accepting_drags:Boolean = true;
		
		private const controlPoints:Vector.<IControlPoints> = new Vector.<IControlPoints>();
		private const control_points_holder:Sprite = new Sprite();
		
		private var paused:Boolean;
		private var camDriftX:int;
		private var camDriftY:int;
		
		private var _pc:PC;
		private var mainView:TSMainView;
		private var avatarView:AvatarView;
		private var model:TSModelLocator;
		private var worldModel:WorldModel;
		private var layoutModel:LayoutModel;
		private var flashVarModel:FlashVarModel;
		
		private var reusable_rect:Rectangle;
		private var reusable_pt:Point = new Point();
		
		/** Contains the last modified copy of the viewport's scrollRect */
		private const cachedScrollRect:Rectangle = new Rectangle();
		
		// local pool
		private const localToGlobalPoint:Point = new Point();
		
		private var _locationView:LocationView;
		
		public function LocationRenderer(mainView:TSMainView) {
			name = 'lr_'+getTimer();
			this.mainView = mainView;
			
			model = TSModelLocator.instance;
			worldModel = model.worldModel;
			layoutModel = model.layoutModel;
			flashVarModel = model.flashVarModel;
			
			// set initial vp_scale
			layoutModel.loc_vp_scale = flashVarModel.vp_scale;
			
			//Shouldn't be necessary here.
			worldModel.registerCBProp(onLocalPC, "pc");
			
			// eric has proven that cAB improves rendering
			// even if all the layers are already bitmapped
			// though it increases memory usage (by nature)
			cacheAsBitmap = (EnvironmentUtil.getUrlArgValue('SWF_loc_no_cab') != '1');
			CONFIG::debugging {
				Console.warn('LocationRenderer.cacheAsBitmap:'+cacheAsBitmap)
			}
			
			model.activityModel.registerCBProp(drawpolyHandler, "poly_to_draw");
			model.activityModel.registerCBProp(drawdotsHandler, "dots_to_draw");
			
			scrolling_overlay_holder = new Sprite();
			scrolling_overlay_holder.mouseEnabled = false;
			scrolling_overlay_holder.name = 'scrolling_overlay_holder';
			scrolling_overlay_top = new Sprite();
			scrolling_overlay_top.mouseEnabled = false;
			scrolling_overlay_top.name = 'scrolling_overlay_top';
			scrolling_overlay_holder.addChild(scrolling_overlay_top);
			
			CONFIG::perf {
				if (model.flashVarModel.run_automated_tests) {
					mouseEnabled = false;
					mouseChildren = false;
				}
			}
		}
		
		/**
		 * This is the value that we should set our scrollRect's width to, such
		 * that, after scaleX is applied, the viewport will have the correct
		 * desired width.
		 */
		private function get prescaled_vp_w():int {
			// enlarge the desired width by the scale so that when it's scaled
			// it returns to the same value
			return layoutModel.loc_vp_w / layoutModel.loc_vp_scale;
		}
		
		/**
		 * This is the value that we should set our scrollRect's height to, such
		 * that, after scaleY is applied, the viewport will have the correct
		 * desired height.
		 */ 
		private function get prescaled_vp_h():int {
			// enlarge the desired height by the scale so that when it's scaled
			// it returns to the same value
			return layoutModel.loc_vp_h / layoutModel.loc_vp_scale;
		}
		
		public function onEnterFrame(ms_elapsed:int):void {			
			if (!visible) return;
			
			CONFIG::god {
				// when buzzed or having an urquake, we're going to cause the parallax to drift
				if (model.stateModel.urquake) {
					const inc:int = 15;
					// don't drift too far off the intended frame
					camDriftX += MathUtil.randomInt(-inc, inc);
					camDriftY += MathUtil.randomInt(-inc, inc);
					camDriftX = MathUtil.clamp(-inc, inc, camDriftX);
					camDriftY = MathUtil.clamp(-inc, inc, camDriftY);
					dirty = true;
				} else if (camDriftX || camDriftY) {
					//when the shaking is over, we need to return to center
					camDriftX = 0;
					camDriftY = 0;
					dirty = true;
				}
			}
			
			if (!model.flashVarModel.run_av_from_aph) {
				if (this.avatarView) {
					this.avatarView.updateModel();
				}
			}

			scrollAndRender();
			
			// update control point positions
			// if there is a selection, the model may have moved
			CONFIG::god {
				for each (var controlPoint:IControlPoints in controlPoints) {
					controlPoint.redraw();
				}
			}
		}
		
		/*CONFIG::debugging */private var debug_str:String = '';
		
		private function scrollAndRender():void {
			const loc:Location = worldModel.location;
			if (!loc || !loc.physics_setting || !_locationView) return;
			
			if (model.stateModel.editing) {
				; // FU
				//CONFIG::debugging {
					debug_str = 'B:sm.editing';
				//}
				// don't override position
			} else if (HandOfDecorator.instance.inhibits_scroll) {
				; // FU
				//CONFIG::debugging {
					debug_str = 'B:HOD.inhibits_scroll '+HandOfDecorator.instance.inhibits_scroll;
				//}
				// don't override position
			} else if (model.stateModel.hand_of_god) {
				; // FU
				//CONFIG::debugging {
					debug_str = 'B:sm.hand_of_god';
				//}
			} else if (avatarView) {
				//CONFIG::debugging {
					debug_str = 'GOOOOO!';
				//}
				
				moveTo(CameraMan.instance.center_pt.x, CameraMan.instance.center_pt.y);
				debug_str+= ' pt:'+CameraMan.instance.center_pt;
			} else {
				//CONFIG::debugging {
					debug_str = 'WEIRD!';
				//}
				
				// perc mouse has moved across viewport.
				var perc_x:Number = stage.mouseX/layoutModel.loc_vp_w;
				var perc_y:Number = stage.mouseY/layoutModel.loc_vp_h;
				
				// makes sure mouse is over viewport
				if (perc_x <= 1 || perc_y >= 1) {
					// that same percentage across the location's coordinate space
					var loc_x:int = (perc_x*(loc.client::w))+loc.l;
					var loc_y:int = (perc_y*(loc.client::h))+loc.t;
					
					moveTo(loc_x, loc_y);
				}
			}
			
			BootError.scroll_details = 'LR.scrollAndRender '+debug_str;
			CONFIG::debugging {
				Console.trackValue(' LR.scrollAndRender', debug_str);
			}
			
			if (flashVarModel.limited_rendering) limitRenderingOfPcsAndStacks();
			render();
		}
		
		//		 _                     _ _               
		//		| |                   | | |              
		//		| |__   __ _ _ __   __| | | ___ _ __ ___ 
		//		| '_ \ / _` | '_ \ / _` | |/ _ \ '__/ __|
		//		| | | | (_| | | | | (_| | |  __/ |  \__ \
		//		|_| |_|\__,_|_| |_|\__,_|_|\___|_|  |___/
		
		private function onLocalPC(pc:PC):void {
			this._pc = pc;
			if (_locationView) {
				mgr.pc = pc;
			}
		}
		
		private function drawdotsHandler(payload:Object):void {
			var coordsA:* = payload.coords;
			var overlay:Shape = getSergOverlay();
			var g:Graphics = overlay.graphics;
			var c:uint = (payload.color) ? ColorUtil.colorStrToNum(payload.color) : 0x000000;
			var size:uint = (payload.size) ? parseInt(payload.size) : 14;
			
			if (payload.clear) {
				g.clear();
			}
			
			if (!coordsA || !coordsA.length) {
				return
			}
			
			var dot_x:Number;
			var dot_y:Number;
			for (var i:int=0;i<coordsA.length; i++) {
				dot_x = coordsA[int(i)][0];
				dot_y = coordsA[int(i)][1]+(i%2?-size:size);
				
				g.beginFill(c, 1);
				g.drawCircle(dot_x, dot_y, size/2);
				g.endFill();
				if (i==0) {
					g.beginFill(c, 1);
				} else {
					g.beginFill(0xfcff00, 1);
				}
				
				g.drawCircle(dot_x, dot_y, (size/2)-1);
				g.endFill();
			}
		}
		
		private function drawpolyHandler(payload:Object):void {
			var coordsA:* = payload.coords;
			var overlay:Shape = getSergOverlay();
			var g:Graphics = overlay.graphics;
			var c:uint = (payload.color) ? ColorUtil.colorStrToNum(payload.color) : 0x000000;
			var size:uint = (payload.size) ? parseInt(payload.size) : 8;
			
			if (payload.clear) {
				g.clear();
			}
			
			if (!coordsA || !coordsA.length) {
				return
			}
			
			g.lineStyle(size, c, 1);
			for (var i:int=0;i<coordsA.length; i++) {
				if (i==0) {
					g.moveTo(coordsA[int(i)][0], coordsA[int(i)][1]);
				} else {
					g.lineTo(coordsA[int(i)][0], coordsA[int(i)][1]);
				}
			}
			
			g.lineStyle(size-1, 0xfcff00, 1);
			for (i=0;i<coordsA.length; i++) {
				if (i==0) {
					g.moveTo(coordsA[int(i)][0], coordsA[int(i)][1]);
				} else {
					g.lineTo(coordsA[int(i)][0], coordsA[int(i)][1]);
				}
			}
		}
		
		//		 _                 _   _             
		//		| |               | | (_)            
		//		| | ___   ___ __ _| |_ _  ___  _ __  
		//		| |/ _ \ / __/ _` | __| |/ _ \| '_ \ 
		//		| | (_) | (_| (_| | |_| | (_) | | | |
		//		|_|\___/ \___\__,_|\__|_|\___/|_| |_|
		
		public function updateLocation():void {
			CONFIG::debugging {
				Console.log(79, 'updateLocation');
			}
			Benchmark.addCheck('LocationRenderer.updateLocation instances_ready:'+DecoAssetManager.isLocationReady());
			
			if (DecoAssetManager.isLocationReady()) {
				CONFIG::debugging {
					Console.log(945, 'updateLocation instances_ready:true');
					Console.log(79, 'mainView.locationBuilt()');
				}
				
				// update loading screen
				TSFrontController.instance.startLoadingLocationProgress(READYING_TEXT);
				TSFrontController.instance.updateLoadingLocationProgress(0);
				
				// then delay the rest until the next frame so we can render
				const locationRenderer:LocationRenderer = this;
				StageBeacon.waitForNextFrame(function():void {
					// Deconstruction of location has been moved into LocationView. Both
					// deconstruction of dynamic and static elements happens in one pass
					// as was also required in previous implementation.
					if (_locationView) {
						_locationView.dispose();
						locationView = null;
					}
					
					dirty = true;
					LocationCommands.buildLocationView(worldModel.location, avatarView, _pc, locationRenderer, control_points_holder);
				});
			}
		}
		
		/** we can make this smarter, but for now we do this when changing item_scale of location with physics sliders */
		public function bruteForceReloadLIVs(item_class:String=''):void {
			const loc:Location = worldModel.location;
			const itemstacks:Dictionary = worldModel.itemstacks;
			
			var k:String;
			var itemstack:Itemstack;
			var lis_view:LocationItemstackView;
			
			if (!flashVarModel.no_render_stacks) {
				// get all itemstacks location
				for (k in loc.itemstack_tsid_list) {
					itemstack = (itemstacks[k] as Itemstack);
					
					if (!itemstack) {
						CONFIG::debugging {
							Console.warn('deleted itemstack should not be in list');
						}
						continue;
					}
					
					if (item_class && itemstack.class_tsid != item_class) {
						continue;
					}
					
					// ignore those in bags, such as a cabinet or trophy case
					if (itemstack.container_tsid) continue;
					
					if (itemstack.count == 0) {
						CONFIG::debugging {
							Console.warn('itemstack with 0 count should not be in list');
						}
						continue;
					}
					
					if (itemstack.item.is_hidden) {
						if (!CONFIG::god) {
							continue;
						}
					}
					
					lis_view = getItemstackViewByTsid(itemstack.tsid);
					if (lis_view) {
						lis_view.changeHandler();
					}
				}
			}
		}
		
		
		/** Place all dynamic stuff (pc, items) in place */
		public function updateDynamic():void {
			const loc:Location = worldModel.location;
			const itemstacks:Dictionary = worldModel.itemstacks;
			
			var i:int;
			var k:String;
			var pc:PC;
			var pc_view:PCView;
			var itemstack:Itemstack;
			var lis_view:LocationItemstackView;
			var itemstackA:Array = worldModel.getItemstacksASortedByZ(loc.itemstack_tsid_list);
			
			if (!flashVarModel.no_render_stacks) {
				for (i=0;i<itemstackA.length;i++) {
					itemstack = itemstackA[i];
					
					// ignore those in bags, such as a cabinet or trophy case
					if (itemstack.container_tsid) continue;
					
					if (itemstack.count == 0) {
						CONFIG::debugging {
							Console.warn('itemstack with 0 count should not be in list');
						}
						continue;
					}
					
					
					if (itemstack.item.is_hidden) {
						if (!CONFIG::god) {
							continue;
						}
					}
					
					lis_view = getItemstackViewByTsid(itemstack.tsid);
					if (lis_view) {
						lis_view.changeHandler();
					} else {
						lis_view = mgr.createLocationItemstackView(itemstack);
						placeItemstackInMG(lis_view);
					}
				}
			}
			
			if (!flashVarModel.no_render_pcs) {
				for (k in loc.pc_tsid_list) {
					pc = worldModel.getPCByTsid(k);
					
					// ignore deleted pcs
					if (!pc) {
						CONFIG::debugging {
							Console.warn('deleted pc should not be in list');
						}
						continue;
					}
					
					// ignore own pc
					if (pc == worldModel.pc) continue;
					
					// ignore offline pcs
					if (pc.online == false) {
						CONFIG::debugging {
							Console.warn('pc with online == false should MAYBE not be in list');
						}
						continue;
					}
					
					CONFIG::perf {
						if (model.flashVarModel.run_automated_tests) {
							// ignore other players during testing
							if (!pc.fake) continue;
						}
					}
					
					pc_view = mgr.getOtherAvatar(pc);
					if (pc_view) {
						pc_view.changeHandler();
					} else {
						mgr.addOtherAvatar(pc);
					}
				}
			}
			
			CameraMan.instance.resetCameraCenterAverages();
			
			// if the avatar doesn't exist, create it
			if (!avatarView) {
				LocationCommands.addAvatarView(this);
			} else {
				// otherwise move it to the front and apply new filters.
				avatarView.updateModel();
				mgr.addYourAvatar(avatarView);
				
				if (avatarView is DisplayObject) {
					LocationCommands.applyFiltersToView(worldModel.location.mg, avatarView as DisplayObject);
				}
			}
			
			// we need to do all the below immediatley after creating views! otherwise messaging can come to client
			// (before these functions run on their normal timers) referencing the pcs and items, and if the views
			// are not worth  rendering, nothing will happen (e.g. itemstack_bubble msgs) 
			scrollAndRender(); // scroll the viewport to the correct place so the query is correct
			TSFrontController.instance.triggerPhysicsViewportQuery(); // find what is worth_rendering
			limitRenderingOfPcsAndStacks(); // make things worth_rendering
			
			// test!
			CONFIG::god {
				var stack_str:String;
				for (k in loc.itemstack_tsid_list) {
					itemstack = (itemstacks[k] as Itemstack);
					stack_str = itemstack.tsid+' '+itemstack.class_tsid
					lis_view = getItemstackViewByTsid(itemstack.tsid);
					
					if (!lis_view) {
						//Console.warn(stack_str+' not has view');
					} else if (!lis_view.worth_rendering) {
						//Console.warn(stack_str+' not worth rendering');
					} else {
						//Console.info(stack_str+' is worth rendering');
					}
					
					/*TSFrontController.instance.simulateIncomingMsg({
					"itemstack_tsid":itemstack.tsid,
					"type":MessageTypes.ITEMSTACK_BUBBLE,
					"msg":"YAY! Like, totally revived from my gnarly rooking, thanks to <b>Silly Hats Only</b>.",
					"offset_x":0,
					"ts":"2011:6:29 18:2:15",
					"offset_y":22,
					"duration":10500
					});*/
				}
			}
		}
		
		public function getSnapshot(type:String = null, w:int=640, h:int=0, hide_hidden_doors:Boolean=true, includeAlmostEverything:Boolean=false, includeGeometry:Boolean=false):Bitmap {
			type = type || CameraMan.SNAPSHOT_TYPE_NORMAL;
			
			const mg:MiddleGroundLayer = worldModel.location.mg;
			const loc:Location = worldModel.location;
			
			// original rect
			const lastScrollRect:Rectangle = scrollRect;
			
			const oldX:int = layoutModel.loc_cur_x;
			const oldY:int = layoutModel.loc_cur_y;
			
			var overlay:Shape = getSergOverlay();
			overlay.visible = false;
			mgr.unglowAllInteractionSprites();
			
			var i:int;
			
			// move to center if not a user snap (users snap just show the viewport)
			if (type != CameraMan.SNAPSHOT_TYPE_USER) {
				moveTo(loc.l+((loc.client::w)/2), loc.b);
				render();
			}
			
			const doors_hiddenV:Vector.<DoorView> = new Vector.<DoorView>();
			const doors_adjustedV:Vector.<DoorView> = new Vector.<DoorView>();
			const signposts_hiddenV:Vector.<SignpostView> = new Vector.<SignpostView>();
			
			if (type == CameraMan.SNAPSHOT_TYPE_USER) {
				AnnouncementController.instance.hideOverlaysForUserSnap();
			}
			
			if (!includeAlmostEverything) {
				// hide all the pcs and itemstacks
				mgr.hidePCsTemporarily();
				mgr.hideItemstacksTemporarily();
				
				AnnouncementController.instance.hideAllOverlays();
				
				// hide all overlays and shit we place in the MG
				if (mgr) {
					mgr.hideVisibleNonItemstacks();
				}
			}
			
			CONFIG::god {
				var controlPoint:IControlPoints;
				for each (controlPoint in controlPoints) {
					controlPoint.displayObject.visible = false;
				}
				
				if (!includeGeometry) {
					CONFIG::locodeco {
						// hide "hidden" signposts and doors for the snap
						for (i=0;i<mgr.signpostViews.length;i++) {
							if (mgr.signpostViews[int(i)].signpost.getVisibleConnects().length == 0 && 
								mgr.signpostViews[int(i)].visible) {
								mgr.signpostViews[int(i)].visible = false;
								signposts_hiddenV.push(mgr.signpostViews[int(i)]);
							}
						}
						for (i=0;i<mgr.doorViews.length;i++) {
							if ((!mgr.doorViews[int(i)].door.connect || mgr.doorViews[int(i)].door.connect.hidden) 
								&& mgr.doorViews[int(i)].visible) {
								if (hide_hidden_doors) {
									mgr.doorViews[int(i)].visible = false;
									doors_hiddenV.push(mgr.doorViews[int(i)]);
								} else {
									mgr.doorViews[int(i)].adjustForSnapping();
									doors_adjustedV.push(mgr.doorViews[int(i)]);
								}
							}
						}
					}
					
					mgr.hidePlatformLinesEtcTemporarily();
					mgr.hideBoxesTemporarily();
					mgr.hideTargetsTemporarily();
					mgr.hideCTBoxesTemporarily();
				}
			}

			// show snappable items that are not within view so we can snap them
			// (if they are not yet loaded, setting them to worth_rendering will
			// cause them to load, after which they will request another resnap)
			const snappableItemsThatArentWorthRendering:Vector.<LocationItemstackView> = new Vector.<LocationItemstackView>();
			for each (var liv:LocationItemstackView in mgr.locationItemStackViews) {
				if (!liv.worth_rendering && liv.item.isSnappable()) {
					snappableItemsThatArentWorthRendering.push(liv);
					liv.worth_rendering = true;
				}
			}
			
			// hide things that shouldn't be in the snap
			adjustItemstacksForSnapping(includeAlmostEverything);
			
			scrollRect = new Rectangle(loc.l, loc.t, mg.w, mg.h);
			
			if (type != CameraMan.SNAPSHOT_TYPE_USER) {
				// make all Layers same size as MG
				var L:LayerRenderer;
				for (i=0; i<_locationView.layerRenderers.length; i++) {
					L = _locationView.layerRenderers[int(i)];
					if (L.name == 'middleground') continue;
					
					L.x = loc.l;
					L.scaleX = (mg.w/loc.getLayerById(L.name).w);
					
					L.y = loc.t;
					L.scaleY = (mg.h/loc.getLayerById(L.name).h);
				}
			}
			
			var bitmapdata:BitmapData;
			var b:Bitmap;
			var tx:Number = 0; //top
			var ty:Number = 0; //top
			var sx:Number; //scale
			var sy:Number; //scale
			var bw:int; //bitmap
			var bh:int; //bitmap
			
			if (type == CameraMan.SNAPSHOT_TYPE_USER) {
				
				tx = loc.l-lastScrollRect.x;
				ty = loc.t-lastScrollRect.y;
				sx = 1;
				sy = 1;
				bw = layoutModel.loc_vp_w;
				bh = layoutModel.loc_vp_h;
			} else if (type == CameraMan.SNAPSHOT_TYPE_LOADING) {
				if (w/h > loc.client::w/loc.client::h) {
					// base ratio on width
					sx = w/mg.w;
					sy = sx;
					
					// draw Bottom only THE OLD WAY!!!
					//ty = -((mg.h*sy)-h);
					
					// draw Middle only
					ty = -((mg.h*sy)-h)/2;
				} else {
					// base ratio on height
					sy = h/mg.h;
					sx = sy;
					
					// draw center only
					tx = -(((mg.w*sx)-w)/2);
				}
				
				bw = w;
				bh = h;
			} else {
				sx = w/mg.w;
				if (!h) {
					sy = sx;
				} else {
					sy = h/mg.h;
				}
				
				bw = Math.ceil(scrollRect.width*sx);
				bh = Math.ceil(scrollRect.height*sy);
				
				// stay withing Flash's BitmapData limitation
				// so it is is <= MAX_PIXELS pixels and <=8191px in each dimension
				const ratio:Number = (bw / bh);
				if (((bw*bh) > LargeBitmap.MAX_PIXELS) || (bw > LargeBitmap.MAX_DIMENSION) || (bh > LargeBitmap.MAX_DIMENSION)) {
					// check width
					if (bw > LargeBitmap.MAX_DIMENSION) {
						GrowlView.instance.addNormalNotification('bw too large:' + bw);
						bw = LargeBitmap.MAX_DIMENSION;
						bh = Math.floor(bw / ratio);
					}
					// check height
					if (bh > LargeBitmap.MAX_DIMENSION) {
						GrowlView.instance.addNormalNotification('bh too large:' + bh);
						bh = LargeBitmap.MAX_DIMENSION;
						bw = Math.floor(bh * ratio);
					}
					// check pixel count
					if ((bw*bh) > LargeBitmap.MAX_PIXELS) {
						GrowlView.instance.addNormalNotification('too many pixels!');
						// scale the larger dimension to fit
						if (bw > bh) {
							bw = Math.floor(Math.sqrt(LargeBitmap.MAX_PIXELS * ratio));
							bh = Math.floor(bw / ratio);
						} else {
							bh = Math.floor(Math.sqrt(LargeBitmap.MAX_PIXELS / ratio));
							bw = Math.floor(bh * ratio);
						}
					}
					w = bw;
					h = bh;
					sx = w/mg.w;
					sy = h/mg.h;
					CONFIG::god {
						GrowlView.instance.addNormalNotification("Resizing the image to " + bw + 'x' + bh + ', because Flash sucks. Sorry.');
					}
				}
			}
			
			var m:Matrix = new Matrix(sx, 0, 0, sy);
			m.tx = tx;
			m.ty = ty;
			
			const useDigitalZoom:Boolean = false;
			if (type == CameraMan.SNAPSHOT_TYPE_USER) {
				if (useDigitalZoom && (layoutModel.loc_vp_scale != 1.0)) {
					// blow it up by the scale
					var tmpBD:BitmapData = new BitmapData(bw/layoutModel.loc_vp_scale, bh/layoutModel.loc_vp_scale);
					tmpBD.draw(this, m, null, null, null, true);
					
					// then scale down with bilinear interpolation for smoothing
					bitmapdata = new BitmapData(bw, bh);
					m.identity();
					
					// multiply desired scale by loc_vp_scaleX_multiplier and loc_vp_scaleY_multiplier to reflect viewport orientation
					m.scale(layoutModel.loc_vp_scale * layoutModel.loc_vp_scaleX_multiplier, layoutModel.loc_vp_scale * layoutModel.loc_vp_scaleY_multiplier);
					bitmapdata.draw(tmpBD, m, null, null, null, true);
					tmpBD.dispose();
					
					//// scale with nearest-neighbor interpolation
					//m.scale(layoutModel.loc_vp_scale, layoutModel.loc_vp_scale);
					//bitmapdata.draw(this, m);
				} else {
					bitmapdata = new BitmapData(bw/layoutModel.loc_vp_scale, bh/layoutModel.loc_vp_scale);
					
					// set scale to loc_vp_scaleX_multiplier and loc_vp_scaleY_multiplier to reflect viewport orientation
					m.scale(layoutModel.loc_vp_scaleX_multiplier, layoutModel.loc_vp_scaleY_multiplier);
					bitmapdata.draw(this, m, null, null, null, true);
				}
			} else {
				bitmapdata = new BitmapData(bw, bh);
				bitmapdata.draw(this, m, null, null, null, true);
			}
			b = new Bitmap(bitmapdata);
			
			// NOW undo all the things we did to get the bitmap
			overlay.visible = true;
			
			if (type != CameraMan.SNAPSHOT_TYPE_USER) {
				for (i=0; i<_locationView.layerRenderers.length; i++) {
					L = _locationView.layerRenderers[int(i)];
					if (L is MiddleGroundLayer) continue;
					L.scaleX = L.scaleY = 1;
				}
			}
			
			if (!includeAlmostEverything) {
				// make all the pcs and itemstacks we hide above visible again
				mgr.maybeShowPCs();
				mgr.maybeShowItemstacks();
				
				AnnouncementController.instance.unHideAllOverlays();
				
				// now unhide hide all overlays and shit we place in the MG
				if (mgr) {
					mgr.showVisibleNonItemStacks();
				}
			}
			
			if (type == CameraMan.SNAPSHOT_TYPE_USER) {
				AnnouncementController.instance.unHideOverlaysForUserSnap();
			}
			
			CONFIG::god {
				for each (controlPoint in controlPoints) {
					controlPoint.displayObject.visible = true;
				}
				
				if (!includeGeometry) {
					CONFIG::locodeco {
						// make those "hidden" signposts and doors visible again
						for (i=0;i<signposts_hiddenV.length;i++) signposts_hiddenV[int(i)].visible = true;
						for (i=0;i<doors_hiddenV.length;i++) doors_hiddenV[int(i)].visible = true;
						for (i=0;i<doors_adjustedV.length;i++) doors_adjustedV[int(i)].unAdjustForSnapping();
					}
					
					mgr.maybeShowPlatformLinesEtc();
					mgr.maybeShowBoxes();
					mgr.maybeShowTargets();
					mgr.maybeShowCTBoxes();
				}
			}
			
			// re-hide snappable items that should not be shown
			for each (liv in snappableItemsThatArentWorthRendering) {
				liv.worth_rendering = false;
			}
			snappableItemsThatArentWorthRendering.length = 0;
			
			unAdjustItemstacksForSnapping(includeAlmostEverything);
			
			// reset it
			scrollRect = lastScrollRect;
			
			// move back
			// NOTE: WE CANNOT RISK NOT DOING THIS, EVER! Because if we called moveTo above
			// to change the camera, that can totally mess up worth_rendering calculations
			// if we don't set it back
			moveTo(oldX, oldY);
			
			// re-render, cuz we probably made a mess of things
			dirty = true;
			render();
			
			return b;
		}
		
		// this'll just call showHide() on the itemstack views, which are smart about when they should be shown
		public function showHideItemstacks():void {
			mgr.toggleVisibility(lis_viewV);
		}
		
		private function adjustItemstacksForSnapping(snapAllItemstacks:Boolean=false):void {
			model.stateModel.hide_loc_itemstacks = true;
			for each (var liv:LocationItemstackView in mgr.locationItemStackViews) {
				if (liv.item.isSnappable() || (snapAllItemstacks && !liv.item.is_hidden)) {
					liv.adjustForSnapping(snapAllItemstacks);
				} else {
					liv.showHide();
				}
			}
		}
		
		private function unAdjustItemstacksForSnapping(snapAllItemstacks:Boolean=false):void {
			model.stateModel.hide_loc_itemstacks = false;
			for each (var liv:LocationItemstackView in mgr.locationItemStackViews) {
				if (liv.item.isSnappable() || (snapAllItemstacks && !liv.item.is_hidden)) {
					liv.unAdjustForSnapping();
				} else {
					liv.showHide();
				}
			}
		}
		
		// we should really be doing with with lockers, so it can be done by more than one part of the code safely
		public function disableItemstackBubbles():void {
			model.stateModel.all_bubbles_disabled = true;
			for each (var liv:LocationItemstackView in mgr.locationItemStackViews) {
				liv.getRidOfBubble();
			}
		}
		
		public function enableItemstackBubbles():void {
			model.stateModel.all_bubbles_disabled = false;
		}
		
		public function getPcViewsWorthRendering():Vector.<PCView> {
			var V:Vector.<PCView> = new Vector.<PCView>();
			for each (var pcview:PCView in mgr.pcViews) {
				if (pcview.worth_rendering) V.push(pcview);
			}
			
			return V;
		}
		
		public function getLIVsWorthRendering():Vector.<LocationItemstackView> {
			var V:Vector.<LocationItemstackView> = new Vector.<LocationItemstackView>();
			for each (var liv:LocationItemstackView in mgr.locationItemStackViews) {
				if (liv.worth_rendering) V.push(liv);
			}
			
			return V;
		}
		
		public function refresh():void {
			dirty = true;
			moveTo(layoutModel.loc_cur_x, layoutModel.loc_cur_y);
			render(); // less than ideal, but fixes horrible jerkiness
		}
		
		public function setAvatarView(avatarView:AvatarView):void {
			this.avatarView = avatarView;
			if (_locationView) {
				mgr.avatarView = avatarView;
			}
		}
		
		public function getAvatarView():AvatarView {
			return avatarView;
		}
		
		public function getItemstackViewByTsid(tsid:String):LocationItemstackView {
			if (!mgr) return null;
			return mgr.getLocationItemStackView(tsid);
		}
		
		public function getDoorViewByTsid(tsid:String):DoorView {
			for each (var renderer:DoorView in mgr.doorViews) {
				if (tsid == renderer.tsid) return renderer;
			}
			return null;
		}
		
		CONFIG::god public function getPlatformLineViewByTsid(tsid:String):PlatformLineView {
				for each (var renderer:PlatformLineView in mgr.platformLineViews) {
					if (tsid == renderer.tsid) return renderer;
				}
			return null;
		}
		
		CONFIG::god public function getWallViewByTsid(tsid:String):WallView {
				for each (var renderer:WallView in mgr.wallViews) {
					if (tsid == renderer.tsid) return renderer;
				}
			return null;
		}
		
		public function getPcViewByTsid(tsid:String):PCView {
			if (!_locationView) return null;
			return mgr.getOtherAvatar(worldModel.getPCByTsid(tsid));
		}
		
		public function getSignpostViewByTsid(tsid:String):SignpostView {
			for each (var renderer:SignpostView in mgr.signpostViews) {
				if (tsid == renderer.tsid) return renderer;
			}
			return null;
		}
		
		public function getLadderViewByTsid(tsid:String):LadderView {
			for each (var renderer:LadderView in mgr.ladderViews) {
				if (tsid == renderer.tsid) return renderer;
			}
			return null;
		}
		
		/** Uses the unchangeable tsid automatically set by LocoDeco */
		public function getDecoRendererByTsid(tsid:String):DecoRenderer {
			for each (var layerRenderer:LayerRenderer in _locationView.layerRenderers) {
				var decoRenderers:Vector.<DecoRenderer> = layerRenderer.decoRenderers;
				for (var i:int = 0; i < decoRenderers.length; i++) {
					var decoRenderer:DecoRenderer = decoRenderers[i];
					if (decoRenderer && decoRenderer.deco.tsid == tsid) {
						return decoRenderer;
					}
				}
			}
			return null;
		}
		
		/** Uses the name property that can be set in LocoDeco */
		public function getDecoRendererByName(name:String):DecoRenderer {
			for each (var layerRenderer:LayerRenderer in _locationView.layerRenderers) {
				var decoRenderers:Vector.<DecoRenderer> = layerRenderer.decoRenderers;
				for (var i:int = 0; i < decoRenderers.length; i++) {
					var decoRenderer:DecoRenderer = decoRenderers[i];
					if (decoRenderer && decoRenderer.deco.name == name) {
						return decoRenderer;
					}
				}
			}
			return null;
		}
		
		/** Returns DoorViews, DecoRenderers, etc. */
		CONFIG::locodeco public function getAbstractDecoRendererByTsid(decoTSID:String, layerTSID:String):IAbstractDecoRenderer {
			const alr:LayerRenderer = getLayerRendererByTSID(layerTSID);
			return alr ? (alr.getChildByName(decoTSID) as IAbstractDecoRenderer) : null;
		}
		
		//		                    _           _             
		//		                   | |         (_)            
		//		 _ __ ___ _ __   __| | ___ _ __ _ _ __   __ _ 
		//		| '__/ _ \ '_ \ / _` |/ _ \ '__| | '_ \ / _` |
		//		| | |  __/ | | | (_| |  __/ |  | | | | | (_| |
		//		|_|  \___|_| |_|\__,_|\___|_|  |_|_| |_|\__, |
		//		                                         __/ |
		//		                                        |___/ 
		
		public function pause():void {
			paused = true;
		}
		
		public function resume():void {
			paused = false;
		}
		
		private function render():void {
			if (paused || !_locationView) return;
			
			mgr.updateGeos();
			
			CONFIG::locodeco {
				if (layerModelDirty) {
					layerModelDirty = false;
					// recompute parallax in case new layers were added
					dirty = true;
					updateLayerRenderers();
				}
				
				if (decoModelDirty) {
					decoModelDirty = false;
					for each (var layerRenderer:LayerRenderer in _locationView.layerRenderers) {
						// for each dirty layer, refresh the renderers
						if (layerRenderer.decosDirty) {
							layerRenderer.decosDirty = false;
							layerRenderer.updateDecosForLayer();
						}
					}
				}
				
				if (gradientDirty) {
					gradientDirty = false;
					_locationView.fastUpdateGradient();
				}
				
				if (filtersDirty) {
					filtersDirty = false;
					_locationView.updateFilters(disableHighlighting);
				}
				
				// decos and geometry go through here
				while (dirtyRenderers.length) {
					dirtyRenderers.pop().syncRendererWithModel();
				}
			}
			
			while (dirtySignpostViews.length) {
				SignpostView(dirtySignpostViews.pop()).loadModel();
			}
			
			while (dirtyDoorViews.length) {
				DoorView(dirtyDoorViews.pop()).loadModel();
			}
			
			if (!dirty) return;
			if (!_locationView || !mgr) return;
			if (!worldModel.location) return;
			
			scaleX = layoutModel.loc_vp_scale*layoutModel.loc_vp_scaleX_multiplier;
			scaleY = layoutModel.loc_vp_scale*layoutModel.loc_vp_scaleY_multiplier;
			
			recomputeParallax();
			
			//Console.trackValue('AAAAAAA', scrolling_rect.x+' '+scrolling_rect.y);
			dirty = false;
		}
		
		public function recomputeParallax():void {
			const loc:Location = worldModel.location;
			if (!loc) return;
			
			// min and max here represent the min and max coords that can be
			// centered on when playing the game (e.g. not in edit mode) 
			var min_x:int = loc.l;
			var max_x:int = (loc.r - prescaled_vp_w);
			var rect_x:int = layoutModel.loc_cur_x + camDriftX - (prescaled_vp_w * 0.5);
			rect_x = ((max_x < rect_x) ? max_x : rect_x);
			rect_x = ((loc.l > rect_x) ? loc.l : rect_x);
			
			var min_y:int = loc.t;
			var max_y:int = (loc.b - prescaled_vp_h);
			var rect_y:int = layoutModel.loc_cur_y + camDriftY - (prescaled_vp_h * 0.5);
			rect_y = ((max_y < rect_y) ? max_y : rect_y);
			rect_y = ((loc.t > rect_y) ? loc.t : rect_y);
			
			// set up the view pane
			cachedScrollRect.x = rect_x + ((layoutModel.loc_vp_scaleX_multiplier < 0) ? prescaled_vp_w : 0);
			cachedScrollRect.y = rect_y + ((layoutModel.loc_vp_scaleY_multiplier < 0) ? prescaled_vp_h : 0);
			cachedScrollRect.width  = prescaled_vp_w * layoutModel.loc_vp_scaleX_multiplier;
			cachedScrollRect.height = prescaled_vp_h * layoutModel.loc_vp_scaleY_multiplier;
			scrollRect = cachedScrollRect;
			CONFIG::debugging {
				Console.trackValue(' LR.scrollRect', scrollRect);
			}
			
			// debug to fill the background with a key color
			//graphics.clear();
			//graphics.beginFill(0xff0000);
			//graphics.drawRect(scrollRect.left, scrollRect.top, scrollRect.width, scrollRect.height);
			
			// handle parallax
			var perc_x:Number = ((rect_x - min_x) / (max_x - min_x));
			var perc_y:Number = ((rect_y - min_y) / (max_y - min_y));
			if (isNaN(perc_x)) perc_x = 1;
			if (isNaN(perc_y)) perc_y = 1;
			
			var layer:Layer;
			var layer_x:Number;
			var layer_y:Number;
			for each(var layerRenderer:LayerRenderer in _locationView.layerRenderers) {
				layer = layerRenderer.layerData;
				if (!(layer is MiddleGroundLayer)) {
					layer_x = Math.floor(perc_x * (prescaled_vp_w - layer.w));
					layer_y = Math.floor(perc_y * (prescaled_vp_h - layer.h));
					layerRenderer.setPosition(layer_x, layer_y, rect_x, rect_y);
				}
			}
		}
		
		private function setLivViewWorthRendering(lis_view:LocationItemstackView, wr:Boolean):void {
			if (lis_view.worth_rendering == wr) return;
			lis_view.worth_rendering = wr;
			lis_view_worth_rendering_sig.dispatch(lis_view);
		}
		
		private function setPCViewWorthRendering(pc_view:PCView, wr:Boolean):void {
			if (pc_view.worth_rendering == wr) return;
			pc_view.worth_rendering = wr;
			pc_view_worth_rendering_sig.dispatch(pc_view);
		}

		private var lastPCsWorthRendering:Object = {};
		private var lastTSIDsWorthRendering:Object = {};
		private function limitRenderingOfPcsAndStacks():void {
			if (!mgr || !worldModel.location) return;
			
			// for posterity
//			private const stackWithAIVsShowingByItem:Dictionary = new Dictionary(true);
			// we have turned off showing action indicators unless you mouseover a stack, so we don't need to run this
//			const proximity_tolerance:int = 1; // remember that we're not getting sqrt in distance calc (for dist_sq_from_pc), so we should use a value here of same scale
//			for (var key:String in stackWithAIVsShowingByItem) delete stackWithAIVsShowingByItem[key];
//			if (false) {
//				// should it have action indicators? the setter checks the previous value
//				if (lis_view.worth_rendering) {
//					aiv_stack = stackWithAIVsShowingByItem[itemstack.class_tsid] as Itemstack;
//					aiv_lis_view = (aiv_stack) ? getItemstackViewByTsid(aiv_stack.tsid) : null;
//					
//					if (!aiv_stack || lis_view.has_mouse_focus) {
//						if (aiv_lis_view) aiv_lis_view.aivs_hidden_for_proximity = true;
//						stackWithAIVsShowingByItem[itemstack.class_tsid] = itemstack;
//						lis_view.aivs_hidden_for_proximity = false;
//					} else if (itemstack.dist_sq_from_pc < aiv_stack.dist_sq_from_pc-proximity_tolerance && (!aiv_lis_view || !aiv_lis_view.has_mouse_focus) && (!aiv_lis_view.hasEnabledAIVS() || lis_view.hasEnabledAIVS())) {
//						aiv_lis_view.aivs_hidden_for_proximity = true;
//						stackWithAIVsShowingByItem[itemstack.class_tsid] = itemstack;
//						lis_view.aivs_hidden_for_proximity = false;
//					} else {
//						lis_view.aivs_hidden_for_proximity = true;
//					}
//				} else {
//					lis_view.aivs_hidden_for_proximity = true;
//				}
//			}
			
			const lastPhysicsQuery:PhysicsQuery = model.physicsModel.lastViewportQuery;
			const nextPCsWorthRendering:Object = {};
			const nextTSIDsWorthRendering:Object = {};

			/////////////////// SWF_render_fewer_itemstacks ////////////////////
			CONFIG::god {
				//const lm:LayoutModel = model.layoutModel;
				//const loc_w:int = Math.ceil(lm.loc_vp_w / lm.loc_vp_scale);
				//const loc_h:int = Math.ceil(lm.loc_vp_h / lm.loc_vp_scale);
				
				const mg_w:int = model.worldModel.location.mg.w;
				const mg_h:int = model.worldModel.location.mg.h;
				
				// add these offsets to a coordinate to give it a top-left origin
				const offset_x:int = -(model.worldModel.location.l);
				const offset_y:int = -(model.worldModel.location.t);
				
				const CELL_W:int = 200;
				const cols:int = Math.ceil(mg_w / CELL_W);
				const rows:int = Math.ceil(mg_h / CELL_W);
				const cells:Vector.<Object> = new Vector.<Object>(cols*rows);
				//const vpRect:Rectangle = new Rectangle((lm.loc_cur_x - Math.floor(loc_w/2)), (lm.loc_cur_y - loc_h)), loc_w, loc_h);
				
				var out_of_bounds:int = 0;
				var skipped:int = 0;
				var total:int = 0;
			}
			////////////////////////////////////////////////////////////////////
			
			var tsid:String;
			var itemstack:Itemstack;
			var lis_view:LocationItemstackView;
			
			const overrideItemstacksWorthRendering:Boolean = (model.stateModel.hand_of_god || model.stateModel.decorator_mode);
			if (overrideItemstacksWorthRendering) {
				const itemstacks:Dictionary = worldModel.itemstacks;
				const itemstack_tsids:Dictionary = worldModel.location.itemstack_tsid_list;
				for (tsid in itemstack_tsids) {
					itemstack = (itemstacks[tsid] as Itemstack);
					if (itemstack && !itemstack.container_tsid && !isNaN(itemstack.client::physRadius)) {
						lis_view = getItemstackViewByTsid(tsid);
						if (lis_view) {
							setLivViewWorthRendering(lis_view, true);
							
							// mark
							nextTSIDsWorthRendering[tsid] = lis_view;
						}
					}
				}
			} else {
				for each (itemstack in lastPhysicsQuery.resultItemstacks) {
					// these are already true given the itemstack came from resultItemstacks:
					//if (itemstack && !itemstack.container_tsid && !isNaN(itemstack.client::physRadius)) {
					
					tsid = itemstack.tsid;
					
					lis_view = getItemstackViewByTsid(tsid);
					if (!lis_view) continue;
					
					if (model.flashVarModel.render_fewer_itemstacks) {
						; // satisfy compiler
						CONFIG::god {
							var isWorthRendering:Boolean = true;
						
							//TODO even if worth_rendering is false, you should be able to select a stack and see the others in the cell
							//TODO skip containers and furniture
							total++;
							var cell_x:int = Math.floor((itemstack.x + offset_x) / CELL_W);
							var cell_y:int = Math.floor((itemstack.y + offset_y) / CELL_W);
							if ((cell_x < 0) || (cell_y < 0) || (cell_x >= cols) || (cell_y >= rows)) {
								out_of_bounds++;
								isWorthRendering = false;
							} else {
								var cell_i:int = cols*cell_y + cell_x;
								var cell:Object = cells[cell_i];
								if (cell) {
									if (cell[itemstack.class_tsid]) {
										skipped++;
										isWorthRendering = false;
									} else {
										cell[itemstack.class_tsid] = true;
									}
								} else {
									cells[cell_i] = cell = {};
									cell[itemstack.class_tsid] = true;
								}
							}
							
							if (isWorthRendering) {
								setLivViewWorthRendering(lis_view, true);
								
								// mark
								nextTSIDsWorthRendering[tsid] = lis_view;
							}
						}
					} else {
						setLivViewWorthRendering(lis_view, true);
						
						// mark
						nextTSIDsWorthRendering[tsid] = lis_view;
					}
				}
				
				// sweep
				for (tsid in lastTSIDsWorthRendering) {
					if (!nextTSIDsWorthRendering[tsid]) {
						lis_view = lastTSIDsWorthRendering[tsid];
						setLivViewWorthRendering(lis_view, false);
					}
				}
			}
			
			CONFIG::debugging {
				CONFIG::god {
					Console.log('7', '>>> out_of_bounds='+out_of_bounds, 'skipped='+skipped, 'total='+total); //, 'lq.resultItemstacks='+lq.resultItemstacks.length);
				}
			}
			
			var pc:PC;
			var pc_view:PCView;
			for each (pc in lastPhysicsQuery.resultPCs) {
				tsid = pc.tsid;
				
				pc_view = getPcViewByTsid(tsid);
				if (!pc_view) continue;
				
				setPCViewWorthRendering(pc_view, true);
				
				// mark
				nextPCsWorthRendering[tsid] = pc_view;
			}
			
			// sweep
			for (tsid in lastPCsWorthRendering) {
				if (!nextPCsWorthRendering[tsid]) {
					pc_view = lastPCsWorthRendering[tsid];
					setPCViewWorthRendering(pc_view, false);
				}
			}

			// swap these for the next frame
			lastTSIDsWorthRendering = nextTSIDsWorthRendering;
			lastPCsWorthRendering = nextPCsWorthRendering;
		}
		
		CONFIG::locodeco private function updateLayerRenderers():void {
			const location:Location = worldModel.location;
			const layers:Vector.<Layer> = location.layers;
			
			var i:int;
			var layerRenderer:LayerRenderer;
			
			// re-sort, cuz Z might have changed
			layers.sort(SortTools.layerZSort);
			
			// remove all layer renderers and store in a tsid -> lr map
			var map:Object = {};
			while (_locationView.layerRenderers.length) {
				layerRenderer = LayerRenderer(_locationView.layerRenderers.pop());
				removeChild(layerRenderer);
				map[layerRenderer.tsid] = layerRenderer;
			}
			
			// re-add layer renderers that are still in use to display list
			// some might have been added too
			var layer:Layer;
			const ll:int = layers.length;
			for(i=0; i<ll; i++) {
				layer = layers[int(i)];
				layerRenderer = map[layer.tsid];
				
				// create new layer renderer for new layers
				if (!layerRenderer) {
					layerRenderer = new LayerRenderer(layer, false);
					LocationCommands.prepareLayerRenderer(layerRenderer);
				}
				
				// clear any existing sky
				layerRenderer.graphics.clear();
				
				// put it at the correct location
				addChildAt(layerRenderer, i);
				_locationView.layerRenderers.push(layerRenderer);
			}
			
			// draw sky
			_locationView.fastUpdateGradient();
			
			// keep these on top
			addChild(scrolling_overlay_holder);
			CONFIG::god {
				addChild(control_points_holder);
			}
		}
		
		private function placeItemstackInMG(lis:LocationItemstackView, remove_from_furn:Boolean=true):void {
			var itemstack:Itemstack = lis.itemstack;
			var pl:PlatformLine = worldModel.location.getPlatformForStack(itemstack, false, remove_from_furn);
			/*
			CONFIG::debugging {
			Console.error(itemstack.class_tsid+' ADDED z:'+lis.itemstack.z+' is_furniture:'+lis.item.is_furniture);
			}
			*/
			if (lis.item.is_furniture) {
				if (!pl) {
					/*CONFIG::debugging {
					Console.warn(itemstack.class_tsid+' not on a pl?');
					}*/
					// this should never happen but place the fucker anyway
					
					// ACTUALLY, it is happening right now for furn placed in the wall plane.
					// so, TODO: we need to be smarter in location.getPlatformForStack and check wall
					// planes, not just the wall plat lines. But for now....
					if (lis.item.tsid == 'furniture_chassis' || lis.item.tsid == 'furniture_tower_chassis') {
						mgr.addChassisItem(lis);
					} else {
						mgr.addWallFurnitureItem(lis);
					}
				} else {
					/*CONFIG::debugging {
					Console.info(itemstack.class_tsid+' on a plat userdeco_set:'+pl.placement_userdeco_set);
					}*/
					if (pl.placement_userdeco_set == 'wall') {
						mgr.addWallFurnitureItem(lis);
					} else if (pl.placement_userdeco_set == 'rug') {
						mgr.addRugFurnitureItem(lis);
					} else if (pl.placement_userdeco_set == 'bookshelf') {
						if (lis.item.tsid == 'furniture_door') {
							mgr.addChassisItem(lis);
						} else {
							mgr.addBookshelfFurnitureItem(lis);
						}
					} else if (pl.placement_userdeco_set == 'chair') {
						mgr.addChairFurnitureItem(lis);
					} else if (pl.placement_userdeco_set == 'front') {
						mgr.addForegroundFurnitureItem(lis);
					} else if (pl.placement_userdeco_set == 'ceiling') {
						// we may at some point want to create a new marker and function for ceiling items, but for now it works fine to put them with foreground furn
						mgr.addForegroundFurnitureItem(lis); // maybe addChairFurnitureItem is better?
					} else {
						CONFIG::debugging {
							Console.error('unknown placement_userdeco_set!!!');
						}
						mgr.addChairFurnitureItem(lis);
					}
				}
				
				// find all the stacks on platforms on this furniture
				var pl_lis_viewsV:Vector.<LocationItemstackView> = worldModel.location.getItemstackViewsOnThisFurniture(lis);
				if (pl_lis_viewsV && pl_lis_viewsV.length) {
					for each (var top_lis_view:LocationItemstackView in pl_lis_viewsV) {
						//Console.info(top_lis_view.item.tsid+' now on '+lis.item.tsid);
						top_lis_view.itemstack.on_furniture = lis.tsid;
						mgr.addItemJustAboveOtherItem(top_lis_view, lis);
					}
				}/* else {
				Console.error('nothing on '+lis.item.tsid)
				}*/
				
				//if (mgr is MiddleGroundRenderer) DisplayDebug.LogCoords(MiddleGroundRenderer(mgr), 1);
			} else {
				if (remove_from_furn) itemstack.on_furniture = null;
				if (pl && pl.source) {
					var source_itemstack:Itemstack = worldModel.getItemstackByTsid(pl.source);
					var source_lis:LocationItemstackView = getItemstackViewByTsid(pl.source);
					if (source_lis) {
						//Console.info(lis.item.tsid+' place on '+source_lis.item.tsid)
						mgr.addItemJustAboveOtherItem(lis, source_lis);
						itemstack.on_furniture = pl.source;
						return;
					} else {
						// the source_lis has not been added to display list yet...
						// so just place it normally for now, and when it is added, it will do some magic to
						// place all he stacks on any of its platforms properly
						//Console.warn(lis.item.tsid+' needs to wait for '+pl.source)
					}
				}
				
				if (lis.item.in_background === true) {
					mgr.addBackgroundItem(lis);
				} else if (lis.item.in_foreground === true) {
					mgr.addForegroundItem(lis);
				} else if (lis.item.in_foremostground === true) {
					mgr.addForemostGroundItem(lis);
				} else {
					mgr.addNormalItem(lis);
				}
			}
			
			lis.onAddedToView();
		}
		
		public function placeOverlayAboveDecosInMG(DO:DisplayObject, why:String):void {
			CONFIG::debugging {
				// This is EC logging some stuff about where we parent overlays and stuff. Please leave alone!
				if (Console.priOK('63')) {
					logPlacement(StringUtil.getCurrentCodeLocation()+' '+StringUtil.getCallerCodeLocation()+' why:'+(why || 'NO REASON?'));
				}
			}
			mgr.placeOverlayAboveDecos(DO);
		}
		
		public function placeOverlayBelowDecosInMG(DO:DisplayObject, why:String):void {
			CONFIG::debugging {
				// This is EC logging some stuff about where we parent overlays and stuff. Please leave alone!
				if (Console.priOK('63')) {
					logPlacement(StringUtil.getCurrentCodeLocation()+' '+StringUtil.getCallerCodeLocation()+' why:'+(why || 'NO REASON?'));
				}
			}
			mgr.placeOverlayBelowDecos(DO);
		}
		
		public function placeOverlayInMG(DO:DisplayObject, why:String):void {
			CONFIG::debugging {
				// This is EC logging some stuff about where we parent overlays and stuff. Please leave alone!
				if (Console.priOK('63')) {
					logPlacement(StringUtil.getCurrentCodeLocation()+' '+StringUtil.getCallerCodeLocation()+' why:'+(why || 'NO REASON?'));
				}
			}
			mgr.placeOverlay(DO);
		}
		
		public function placeOverlayBelowYourPlayerInMG(overlayBelSerg:DisplayObject, why:String):void {
			CONFIG::debugging {
				// This is EC logging some stuff about where we parent overlays and stuff. Please leave alone!
				if (Console.priOK('63')) {
					logPlacement(StringUtil.getCurrentCodeLocation()+' '+StringUtil.getCallerCodeLocation()+' why:'+(why || 'NO REASON?'));
				}
			}
			mgr.placeOverlayBelowYourPlayer(overlayBelSerg);
		}
		
		public function placeOverlayBelowAnItemstackInMG(overlay:DisplayObject, itemstack_tsid:String, why:String):void {
			CONFIG::debugging {
				// This is EC logging some stuff about where we parent overlays and stuff. Please leave alone!
				if (Console.priOK('63')) {
					logPlacement(StringUtil.getCurrentCodeLocation()+' '+StringUtil.getCallerCodeLocation()+' why:'+(why || 'NO REASON?'));
				}
			}
			mgr.placeOverlayBelowAnItemstack(overlay, itemstack_tsid);
		}
		
		public function placeOverlayAboveAnItemstackInMG(overlay:DisplayObject, itemstack_tsid:String, why:String):void {
			CONFIG::debugging {
				// This is EC logging some stuff about where we parent overlays and stuff. Please leave alone!
				if (Console.priOK('63')) {
					logPlacement(StringUtil.getCurrentCodeLocation()+' '+StringUtil.getCallerCodeLocation()+' why:'+(why || 'NO REASON?'));
				}
			}
			mgr.placeOverlayAboveAnItemstack(overlay, itemstack_tsid);
		}
		
		public function placeOverlayBelowAnAvatarInMG(DO:DisplayObject, pc_tsid:String, why:String):void {
			CONFIG::debugging {
				// This is EC logging some stuff about where we parent overlays and stuff. Please leave alone!
				if (Console.priOK('63')) {
					logPlacement(StringUtil.getCurrentCodeLocation()+' '+StringUtil.getCallerCodeLocation()+' why:'+(why || 'NO REASON?'));
				}
			}
			if (DO.parent) DO.parent.removeChild(DO);
			if (mgr) {
				if (pc_tsid == worldModel.pc.tsid && avatarView) {
					mgr.placeOverlayBelowYourPlayer(DO);
					return;
				} else {
					var pcView:PCView = mgr.getOtherAvatar(worldModel.getPCByTsid(pc_tsid));
					mgr.placeOverlayBelowOtherAvatar(DO, pcView);
					return;
				}
				
				CONFIG::debugging {
					Console.warn('NO pc_view FOR '+pc_tsid);
				}
			}	
		}
		
		public function placeOverlayInLayer(layer:Layer, inLocationOverlay:InLocationOverlay, why:String):Boolean {
			if (!_locationView) return false;
			
			CONFIG::debugging {
				// This is EC logging some stuff about where we parent overlays and stuff. Please leave alone!
				if (Console.priOK('63')) {
					logPlacement(StringUtil.getCurrentCodeLocation()+' '+StringUtil.getCallerCodeLocation()+' why:'+(why || 'NO REASON?'));
				}
			}
			var renderer:LayerRenderer = _locationView.getLayerRendererByTsid(layer.tsid) as LayerRenderer;
			if (renderer) {
				renderer.placeInLocationOverlay(inLocationOverlay);
				return true;
			}
			return false;
		}
		
		public function placeOverlayInSCH(DO:DisplayObject, why:String):void {
			/*
			CONFIG::debugging {
			// This is EC logging some stuff about where we parent overlays and stuff. Please leave alone!
			if (Console.priOK('63')) {
			logPlacement(StringUtil.getCurrentCodeLocation()+' '+StringUtil.getCallerCodeLocation()+' why:'+(why || 'NO REASON?'), true);
			}
			}
			*/
			if (DO.parent) DO.parent.removeChild(DO);
			if (scrolling_overlay_holder) {
				scrolling_overlay_holder.addChildAt(DO, scrolling_overlay_holder.getChildIndex(scrolling_overlay_top));
			}
		}
		
		public function placeOverlayInSCHTop(DO:DisplayObject, why:String):void {
			/*
			CONFIG::debugging {
			// This is EC logging some stuff about where we parent overlays and stuff. Please leave alone!
			if (Console.priOK('63')) {
			logPlacement(StringUtil.getCurrentCodeLocation()+' '+StringUtil.getCallerCodeLocation()+' why:'+(why || 'NO REASON?'), true);
			}
			}
			*/
			if (DO.parent) DO.parent.removeChild(DO);
			if (scrolling_overlay_holder) {
				scrolling_overlay_holder.addChild(DO);
			}
		}
		
		private var placement_log:Dictionary;
		private function logPlacement(why:String, ok:Boolean=false):void {
			CONFIG::debugging {
				// This is EC logging some stuff about where we parent overlays and stuff. Please leave alone!
				if (Console.priOK('63')) {
					if (!placement_log) placement_log = new Dictionary();
					
					if (ok) {
						/*
						if (!placement_log[why]) placement_log[why] = 0;
						placement_log[why]++;
						Console.info('#'+placement_log[why]+' of: '+why);
						*/
					} else {
						
						if (!placement_log[why]) placement_log[why] = 0;
						placement_log[why]++;
						Console.warn( '#'+placement_log[why]+' of: '+why);
					}
				}
			}
		}
		
		public function registerControlPoint(controlPoint:IControlPoints):void {
			control_points_holder.addChild(controlPoint.displayObject);
			controlPoints.push(controlPoint);
		}
		
		public function unregisterControlPoint(controlPoint:IControlPoints):void {
			control_points_holder.removeChild(controlPoint.displayObject);
			controlPoints.splice(controlPoints.indexOf(controlPoint), 1);
		}
		
		//		       _   _ _ _ _   _           
		//		      | | (_) (_) | (_)          
		//		 _   _| |_ _| |_| |_ _  ___  ___ 
		//		| | | | __| | | | __| |/ _ \/ __|
		//		| |_| | |_| | | | |_| |  __/\__ \
		//		 \__,_|\__|_|_|_|\__|_|\___||___/
		
		private function getSergOverlay():Shape {
			var overlay:Shape = mgr.sergOverlay;
			
			if (!overlay) {
				overlay = new Shape();
				overlay.name = 'serg_overlay';
				mgr.sergOverlay = overlay;
			}
			
			return overlay;
		}
		
		public function bringItemstackToFront(tsid:String, remove_from_furn:Boolean=true):void {
			var lis_view:LocationItemstackView = getItemstackViewByTsid(tsid);
			if (lis_view) {
				placeItemstackInMG(lis_view, remove_from_furn);
			}
		}
		
		private const mgrMousePoint:Point = new Point();
		/** Clone the return value if you intend to modify it */
		public function getMouseXYinMiddleground():Point {
			if (mgr) {
				mgrMousePoint.x = mgr.mouseX;
				mgrMousePoint.y = mgr.mouseY;
			} else {
				mgrMousePoint.x = NaN;
				mgrMousePoint.y = NaN;
			}
			return mgrMousePoint;
		}
		
		public function getMouseXinMiddleground():Number {
			return (mgr ? mgr.mouseX : NaN);
		}
		
		public function getMouseYinMiddleground():Number {
			return (mgr ? mgr.mouseY : NaN);
		}
		
		public function translateLocationCoordsToGlobal(x:int, y:int):Point {
			localToGlobalPoint.x = x;
			localToGlobalPoint.y = y;
			return mgr.localToGlobal(localToGlobalPoint);
		}
		
		public function translateGlobalCoordsToLocation(x:int, y:int):Point {
			localToGlobalPoint.x = x;
			localToGlobalPoint.y = y;
			return mgr.globalToLocal(localToGlobalPoint);
		}
		
		public function translateLayerLocalToGlobal(layer:Layer, x:int, y:int):Point {
			var renderer:LayerRenderer = getLayerRendererByTSID(layer.tsid);
			if (renderer) {
				return renderer.localToGlobal(new Point(x, y));
			} else {
				CONFIG::debugging {
					Console.warn('Unable to find layer, returning 0,0');
				}
				return new Point(0,0);
			}
		}
		
		public function translateLayerGlobalToLocal(layer:Layer, x:int, y:int):Point {
			if (!_locationView) return new Point();
			
			var renderer:LayerRenderer = _locationView.getLayerRendererByTsid(layer.tsid);
			if (renderer) {
				return renderer.globalToLocal(new Point(x, y));
			} else {
				CONFIG::debugging {
					Console.warn('Unable to find layer, returning 0,0');
				}
				return new Point(0,0);
			}
		}
		
		public function isPtInVisibleArea(pt:Point):Boolean {
			return scrollRect.containsPoint(pt);
		}
		
		public function moveTo(x:int, y:int):void {
			// try to sanitize coordinates first
			const loc:Location = worldModel.location;
			if (loc) {
				//TODO could cache these values for performance
				const min_x:int = loc.l+(prescaled_vp_w/2);
				const max_x:int = loc.r-(prescaled_vp_w/2);
				
				const min_y:int = loc.t+(prescaled_vp_h/2);
				const max_y:int = loc.b-(prescaled_vp_h/2);
				
				x = Math.min(max_x, Math.max(min_x, x));
				y = Math.min(max_y, Math.max(min_y, y));
				
				//var g:Graphics = mg_serg_end_marker.graphics;
				//g.clear();
				//g.beginFill(0xffffff, .8);
				//g.drawRect(min_x, min_y, max_x-min_x, max_y-min_y);
				//g.beginFill(0xffffff, 1);
				//g.drawCircle(new_x, new_y, 20);
				//trace(min_x+' '+max_x+' '+(max_x-min_x)+' '+new_x)
			}
			
			if ((x != layoutModel.loc_cur_x) || (y != layoutModel.loc_cur_y)) {
				layoutModel.loc_cur_x = x;
				layoutModel.loc_cur_y = y;
				dirty = true;
				CONFIG::god {
					// so locodeco/hog can draw the current viewport in the map
					MiniMapView.instance.refresh();
				}
			}
		}
		
		public function getLayerRendererByTSID(tsid:String):LayerRenderer {
			return getChildByName(tsid) as LayerRenderer;
		}
		
		CONFIG::locodeco public function centerViewportOnDisplayObject(decoTSID:String, layerTSID:String):void {
			const drc:IAbstractDecoRenderer = getAbstractDecoRendererByTsid(decoTSID, layerTSID);
			const DO:DisplayObject = drc.getRenderer();
			const DOModel:AbstractPositionableLocationEntity = drc.getModel();
			const layerRenderer:LayerRenderer = LayerRenderer(DO.parent);
			const layer:Layer = layerRenderer.layerData;
			
			var oldPt:Point;
			var newPt:Point;
			if (layer is MiddleGroundLayer) {
				// walls and platforms need special love 
				if (DOModel is Wall) {
					// walls y is at the top and not the bottom
					newPt = new Point(DOModel.x, DOModel.y+Wall(DOModel).h/2);
				} else if (DOModel is PlatformLine) {
					// x and y of PLVs return the left side not the center
					const pl:PlatformLine = PlatformLineView(DO).platformLine;
					newPt = new Point(pl.start.x + (pl.end.x - pl.start.x)/2, pl.start.y + (pl.end.y - pl.start.y)/2);
				} else {
					oldPt = DO.localToGlobal(new Point(0, -DO.height/2));
					newPt = globalToLocal(oldPt);
				}
			} else {
				//TODO this isn't perfect, it's never just over the center
				const loc:Location = worldModel.location;
				const ratio_w:Number = loc.mg.w / layer.w;
				const ratio_h:Number = loc.mg.h / layer.h;
				// using local/globalToGlobal/Local takes rotation, etc., into account too
				oldPt = DO.localToGlobal(new Point(0, -DO.height/2));
				newPt = layerRenderer.globalToLocal(oldPt);
				newPt = new Point(((newPt.x*ratio_w)+loc.l), ((newPt.y*ratio_h)+loc.t));
			}
			moveTo(newPt.x, newPt.y);
		}
		
		public function getMostLikelyPCUnderCursor():PCView {
			return getMostLikelyPCFromList(getPCsUnderCursor());
		}
		
		public function getMostLikelyPCFromList(pc_viewsV:Vector.<PCView>, offset_point:Point=null):PCView {
			// todo eventually make this work like getMostLikelyItemstackFromList, but for now,
			// just return the first in the list
			if (!pc_viewsV || !pc_viewsV.length) return null;
			return pc_viewsV[0];
		}
		
		public function getMostLikelyItemstackUnderCursor():LocationItemstackView {
			return getMostLikelyItemstackFromList(getItemstacksUnderCursor());
		}
		
		public function getMostLikelyItemstackFromList(lis_viewsV:Vector.<LocationItemstackView>, offset_point:Point=null):LocationItemstackView {
			var lis_view:LocationItemstackView;
			var bmd:BitmapData;
			var multiplier:int;
			
			// stuff for testing in a box around where the pixel is
			var extra:int = 1; // how many pixels out from reusable_pt do we want to test
			var min_x:int;
			var min_y:int;
			var max_x:int;
			var max_y:int;
			var tx:int;
			var ty:int
			var clr:int;
			var minimum_alpha:int; // of 255
			
			CONFIG::debugging {
				Console.trackValue(' LR mouse lis_viewsV', lis_viewsV.length);
			}
			
			// last item in the vector is above previous items
			for (var i:int=lis_viewsV.length-1; i != -1; --i) {
				lis_view = lis_viewsV[i];
				
				// if furniture and there is more than one item under mouse, make sure the pixel is pretty damn opaque; otherwise, just not invisible
				minimum_alpha = (lis_viewsV.length > 1 && (lis_view.item.is_furniture || lis_view.item.is_special_furniture)) ? 200 : 10; // of 255
				
				// test if mouse pt is is over visible pixel of the lis_view before returning it.
				if (lis_view.ss_view && lis_view is LocationItemstackView && lis_view.ss_view is SSViewSprite) {
					
					// todo: experiment with using lis_view.ss_view.ss.getFrame(lis_view.ss_view as SSViewSprite).originalBounds instead of
					// SSViewSprite(lis_view.ss_view).getBounds(lis_view as LocationItemstackView)
					// which would free us from needing (lis_view as LocationItemstackView) if GPULIV could return the SS frame and bitmap
					// for it's current frame
					
					// we need this so we can translate mouse coords to coords relative to the bitmap it is displaying
					reusable_rect = SSViewSprite(lis_view.ss_view).getBounds(DisplayObject(lis_view));
					
					// account for that it can be flipped
					if (lis_view.is_flipped) {
						reusable_rect.x = -(reusable_rect.width+reusable_rect.x);
						multiplier = -1;
					} else {
						multiplier = 1;
					}
					
					var dist_x:int = (offset_point) ? StageBeacon.stage_mouse_pt.x - offset_point.x : 0;
					var dist_y:int = (offset_point) ? StageBeacon.stage_mouse_pt.y - offset_point.y : 0;
					var start_x:int = lis_view.mouseX-dist_x;
					var start_y:int = lis_view.mouseY-dist_y;
					
					reusable_pt.x = int((start_x*multiplier)-reusable_rect.x);
					reusable_pt.y = int(start_y-reusable_rect.y);
					
					// get the bitmap it is currently displaying
					bmd = lis_view.ss_view.ss.getBitmapData(lis_view.ss_view as SSViewSprite);
					
					// now let's test a box that is (extra*2+1) x (extra*2+1) centered around the mouse pt
					min_x = Math.max(0, reusable_pt.x-extra);
					min_y = Math.max(0, reusable_pt.y-extra);
					max_x = Math.min(bmd.width-1, reusable_pt.x+extra);
					max_y = Math.min(bmd.height-1, reusable_pt.y+extra);
					
					CONFIG::debugging {
						Console.trackValue(' LR reusable_rect', reusable_rect);
						Console.trackValue(' LR mouse test', 'min:'+min_x+','+min_y+' max:'+max_x+','+max_y+' pt:'+reusable_pt);
						Console.trackValue(' LR StageBeacon.stage_mouse_pt', StageBeacon.stage_mouse_pt);
						Console.trackValue(' LR offset_point', offset_point);
					}
					
					for (tx=min_x;tx<=max_x;tx++) {
						for (ty=min_y;ty<=max_y;ty++) {
							clr = bmd.getPixel32(tx, ty);
							/*
							CONFIG::god {
							Console.trackValue(' clr', ColorUtil.getAlpha(clr)+' tx:'+tx+' ty:'+ty);
							}
							*/					
							if (ColorUtil.getAlpha(clr) > minimum_alpha) {
								return lis_view;
							}
						}
					}
				} else {
					// must be a lis_view using the mc, so assume lis_viewsV would only contain it
					// if the mouse was over a visible portion of the stack
					return lis_view;
				}
			}
			
			return null;
		}
		
		
		/** Find all itemstacks immediately under mouse in sorted Z order */
		public function getItemstacksUnderCursor():Vector.<LocationItemstackView> {
			const V:Vector.<LocationItemstackView> = new Vector.<LocationItemstackView>();
			
			// NOTE: Using stage is suboptimal, but the object list returned is
			// somehow missing items when using gameRenderer.getObjectsUnderPoint
			const objs:Array = StageBeacon.stage.getObjectsUnderPoint(StageBeacon.stage_mouse_pt);
			const objsSeen:Dictionary = new Dictionary();
			
			var p:DisplayObject;
			for each (var obj:Object in objs) {
				p = (obj as DisplayObject);
				// this is not efficient, but may be the only way to do it
				while (p) {
					// skip objects and their parents that we've seen
					// (getObjectsUnderPoint may return multiple children of the same itemstack)
					if (p in objsSeen) break;
					if (!(p is LocationItemstackView)) {
						// EC: never mark LIV's as seen, else if the first descendent 
						// inspected fails this test, none will be able to pass.
						objsSeen[p] = true;
					}
					
					if ((p is LocationItemstackView) && (p.parent is LayerRenderer)) {
						// make sure we are clicking on the hit_box, if there is one, and not some invisble part of it
						if (LocationItemstackView(p).hit_target in objsSeen) {
							V.push(LocationItemstackView(p));
							break;
						}
					}
					p = p.parent;
				}
			}
			
			// sort on z depth
			if (V.length > 1) {
				V.sort(SortTools.displayObjectZSort);
			}
			
			return V;
		}
		
		/** Find all itemstacks immediately under mouse in sorted Z order */
		public function getPCsUnderCursor():Vector.<PCView> {
			const V:Vector.<PCView> = new Vector.<PCView>();
			
			// NOTE: Using stage is suboptimal, but the object list returned is
			// somehow missing items when using gameRenderer.getObjectsUnderPoint
			const objs:Array = StageBeacon.stage.getObjectsUnderPoint(StageBeacon.stage_mouse_pt);
			const objsSeen:Dictionary = new Dictionary();
			
			var p:DisplayObject;
			for each (var obj:Object in objs) {
				p = (obj as DisplayObject);
				// this is not efficient, but may be the only way to do it
				while (p) {
					// skip objects and their parents that we've seen
					// (getObjectsUnderPoint may return multiple children of the same itemstack)
					if (p in objsSeen) break;
					if (!(p is PCView)) {
						// EC: never mark PCView's as seen, else if the first descendent 
						// inspected fails this test, none will be able to pass.
						objsSeen[p] = true;
					}
					
					if ((p is PCView) && (p.parent is LayerRenderer)) {
						// make sure we are clicking on the hit_box, if there is one, and not some invisble part of it
						if (PCView(p).hit_target in objsSeen) {
							V.push(PCView(p));
							break;
						}
					}
					p = p.parent;
				}
			}
			
			// sort on z depth
			if (V.length > 1) {
				V.sort(SortTools.displayObjectZSort);
			}
			
			return V;
		}
		
		//		 _       _             __                    
		//		(_)     | |           / _|                   
		//		 _ _ __ | |_ ___ _ __| |_ __ _  ___ ___  ___ 
		//		| | '_ \| __/ _ \ '__|  _/ _` |/ __/ _ \/ __|
		//		| | | | | ||  __/ |  | || (_| | (_|  __/\__ \
		//		|_|_| |_|\__\___|_|  |_| \__,_|\___\___||___/
		
		// from ITipProvider
		public function getTip(tip_target:DisplayObject = null):Object {
			if (tip_target is PCView) {
				const pc:PC = worldModel.getPCByTsid(tip_target.name);
				return {
					txt: pc.label + (pc.level) ? ' ('+pc.level+')' : ''
				}
			}
			
			var is_child_of_door:Boolean;
			var potential_door:DisplayObject = tip_target;
			while (!(potential_door is Layer)) {
				if (potential_door is DoorView) {
					is_child_of_door = true;
					break;
				}
				potential_door = potential_door.parent;
			}
			
			if (is_child_of_door) {
				const door_sp:DoorView = potential_door as DoorView;
				const door:Door = door_sp.door;
				const hidden_str:String = ((!door.connect || (door.connect && door.connect.hidden)) && CONFIG::god) ? ' (A/D HIDDEN)' : '';
				if (door.owner_label && door.owner_tsid) {
					var txt:String = door.connect.label;
					const owner:PC = model.worldModel.getPCByTsid(door.owner_tsid);
					if (!owner || door.connect.label.indexOf(owner.label) == -1) {
						txt+= '<br>Owned by '+door.owner_label;
					}
					return {
						txt: '<span class="location_renderer_tip">'+txt+hidden_str+'</span>'
					}
				} else {
					return {
						txt: door.connect.label+hidden_str
					}
				}
			}
			
//			if (tip_target is LocationItemstackView) {
//				var itemstackView:LocationItemstackView = tip_target as LocationItemstackView;
//				return itemstackView.getTip();
//				var itemstack:Itemstack = worldModel.itemstacks[itemstackView.name];
//				var item:Item = worldModel.getItemByItemstackId(itemstackView.name);
//				var tsid_str:String = '';
//				CONFIG::god {
//					tsid_str = ' '+itemstack.tsid;
//				}
//				
//				return {
//					txt: ((itemstack.count>1) ? itemstack.count+'&nbsp;'+item.label_plural : itemstackView.getLabel())+tsid_str
//				}
//			}
//			
//			if (tip_target is SignpostView) {
//				var signpost_sp:SignpostView = tip_target as SignpostView;
//				var txt:String = '';
//				var signpost:SignPost = signpost_sp.getSignpost();
//				
//				for (var i:int=0; i<signpost.connects.length; i++) {
//					if (i != 0) txt+= '<br>' 
//					txt+= signpost.connects[int(i)].label || 'connects missing label';
//				}
//				
//				return {
//					txt: ''+txt+'',
//					offset_y: 20
//				}
			
			if (!tip_target) return null;
			
			return {
				txt: tip_target.name
			}
		}
		
		// from IDragTarget
		public function highlightOnDragOver():void {
			//alpha = .2;
		}
		
		// from IDragTarget
		public function unhighlightOnDragOut():void {
			//alpha = 1;
		}
		
		// from ILocItemstackAddDelConsumer
		public function onLocItemstackAdds(tsids:Array):void {
			if (flashVarModel.no_render_stacks) return;
			
			if (!mgr) {
				CONFIG::debugging {
					Console.warn('middleGroundRenderer is null! Really should not be getting these when between *start and *end msgs, but change needes to happen on the GS');
				}
				return;
			}
			
			const itemstacks:Dictionary = worldModel.itemstacks;
			
			var i:int;
			var itemstack:Itemstack;
			var lis_view:LocationItemstackView;
			
			for (i=0;i<tsids.length;i++) {
				itemstack = (itemstacks[tsids[int(i)]] as Itemstack);
				
				if (!itemstack) {
					CONFIG::debugging {
						Console.warn('itemstack not exists');
					}
					continue;
				}
				
				if (itemstack.container_tsid) {
					// if it has a container do not place it in location
					continue;
				}
				
				lis_view = getItemstackViewByTsid(itemstack.tsid);
				
				if (lis_view) {
					CONFIG::debugging {
						Console.warn('lis_view already exists');
					}
					lis_view.changeHandler();
					continue;
				}
				
				if (itemstack.item.is_hidden) {
					if (CONFIG::god) {
						; // satisfy compiler
						CONFIG::debugging {
							Console.warn('adding hidden itemstack');
						}
					} else {
						continue;
					}
				}
				
				lis_view = mgr.createLocationItemstackView(itemstack);
				placeItemstackInMG(lis_view);
				
			}
		}
		
		// from ILocItemstackAddDelConsumer
		public function onLocItemstackDels(tsids:Array):void {
			if (flashVarModel.no_render_stacks) return;
			
			if (!mgr) {
				CONFIG::debugging {
					Console.warn('middleGroundRenderer is null! Really should not be getting these when between *start and *end msgs, but change needes to happen on the GS');
				}
				return;
			}
			
			const itemstacks:Dictionary = worldModel.itemstacks;
			
			var itemstack:Itemstack;
			for (var i:int=0;i<tsids.length;i++) {
				itemstack = (itemstacks[tsids[int(i)]] as Itemstack);
				if (itemstack && !itemstack.container_tsid) {
					// if it has a container ignore it
					mgr.destroyLocationItemstackView(itemstack);
				}
			}
		}
		
		// from ILocItemstackUpdateConsumer
		public function onLocItemstackUpdates(tsids:Array):void {
			if (flashVarModel.no_render_stacks) return;
			
			if (!mgr) {
				CONFIG::debugging {
					Console.warn('middleGroundRenderer is null! Really should not be getting these when between *start and *end msgs, but change needes to happen on the GS');
				}
				return;
			}
			
			var i:int;
			var lis_view:LocationItemstackView;
			var itemstack:Itemstack;
			var itemstackA:Array = worldModel.getItemstacksASortedByZ(tsids);
			var need_to_redepth_loc_stacks:Boolean;
			
			for (i=0;i<itemstackA.length;i++) {
				itemstack = itemstackA[i];
				
				// furn is the only thing that obeys z right now
				if (itemstack.item.is_furniture) {
					need_to_redepth_loc_stacks = true;
				}
				
				lis_view = getItemstackViewByTsid(itemstack.tsid);
				if (lis_view) {
					lis_view.changeHandler();
					// if need_to_reorder_furniture then we're going to re place all stacks below, so skip that step here
					if (itemstack.on_furniture && !need_to_redepth_loc_stacks) {
						placeItemstackInMG(lis_view);
					}
				}
			}
			
			// re place all stacks! brute force, sure. works? yeah!
			if (need_to_redepth_loc_stacks) {
				var furn_itemstackA:Array = model.worldModel.getLocationItemstacksA();
				furn_itemstackA.sortOn(['z'], [Array.NUMERIC]);
				for (i=0;i<furn_itemstackA.length;i++) {
					itemstack = furn_itemstackA[i];
					lis_view = getItemstackViewByTsid(itemstack.tsid);
					if (lis_view) {
						placeItemstackInMG(lis_view);
					}
				}
			}
		}
		
		// from ILocPcAddDelConsumer
		public function onLocPcAdds(tsids:Array):void {
			if (flashVarModel.no_render_pcs) return;
			
			if (!mgr) {
				CONFIG::debugging {
					Console.warn('middleGroundRenderer is null! Really should not be getting these when between *start and *end msgs, but change needes to happen on the GS');
				}
				return;
			}
			
			var i:int;
			var pc:PC;
			var pc_view:PCView;
			
			for (i=0;i<tsids.length;i++) {
				pc = worldModel.getPCByTsid(tsids[int(i)]);
				
				// ignore self
				if (pc == worldModel.pc) continue;
				
				CONFIG::perf {
					// skip non fake PCs
					if (model.flashVarModel.run_automated_tests && !pc.fake) continue;
				}
				
				pc_view = mgr.getOtherAvatar(pc);
				
				if (pc_view) {
					CONFIG::debugging {
						Console.warn('pc_view already exists');
					}
					pc_view.changeHandler();
					continue;
				}
				
				if (!pc) {
					CONFIG::debugging {
						Console.warn('pc not exists');
					}
					continue;
				}
				
				mgr.addOtherAvatar(pc);
			}
		}
		
		// from ILocPcAddDelConsumer
		public function onLocPcDels(tsids:Array):void {
			if (flashVarModel.no_render_pcs) return;
			
			if (!mgr) {
				CONFIG::debugging {
					Console.warn('middleGroundRenderer is null! Really should not be getting these when between *start and *end msgs, but change needes to happen on the GS');
				}
				return;
			}
			
			var pc:PC;
			for (var i:int=0;i<tsids.length;i++) {
				pc = worldModel.getPCByTsid(tsids[int(i)]);
				if (pc) mgr.removeOtherAvatar(pc);
			}
		}
		
		// from ILocPcUpdateConsumer
		public function onLocPcUpdates(tsids:Array):void {
			if (flashVarModel.no_render_pcs) return;
			
			if (!mgr) {
				CONFIG::debugging {
					Console.warn('middleGroundRenderer is null! Really should not be getting these when between *start and *end msgs, but change needes to happen on the GS');
				}
				return;
			}
			
			var i:int;
			var pc:PC;
			var pc_view:PCView;
			
			for (i=0;i<tsids.length;i++) {
				pc = worldModel.getPCByTsid(tsids[int(i)]);
				
				if (!pc) {
					CONFIG::debugging {
						Console.warn('PC not exists');
					}
					continue;
				}
				
				if (pc == worldModel.pc) {
					// check if following first?
					if (avatarView) {
						avatarView.changeHandler();
					} else {
						CONFIG::debugging {
							Console.warn('avatarView not exists. WTF?!');
						}
					}
				} else {
					pc_view = mgr.getOtherAvatar(pc);
					if (pc_view) pc_view.changeHandler();
					
					CONFIG::debugging {
						if (!pc_view) Console.warn('pc_view not exists');
					}
				}
			}
		}
		
		public function get pc_viewV():Vector.<PCView> { return _locationView.middleGroundRenderer.pcViews; }
		public function get lis_viewV():Vector.<LocationItemstackView> { return _locationView.middleGroundRenderer.locationItemStackViews; }
		public function get pc():PC { return _pc; }
		
		public function get locationView():LocationView { return _locationView; }
		public function set locationView(value:LocationView):void { 
			_locationView = value;
			location_view_changed_sig.dispatch(_locationView);
		}
		
		private function get mgr():MiddleGroundRenderer {
			return (_locationView ? _locationView._middleGroundRenderer : null);
		}
	}
}
