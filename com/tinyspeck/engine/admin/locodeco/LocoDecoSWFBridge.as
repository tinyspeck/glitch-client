package com.tinyspeck.engine.admin.locodeco {
	import com.flexamphetamine.BuildDecayChronograph;
	import com.tinyspeck.bridge.CartesianMouseEvent;
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.admin.locodeco.components.AbstractControlPoints;
	import com.tinyspeck.engine.admin.locodeco.components.DecoModelDisplayObjectProxy;
	import com.tinyspeck.engine.admin.locodeco.components.LadderControlPoints;
	import com.tinyspeck.engine.admin.locodeco.components.MoveableControlPoints;
	import com.tinyspeck.engine.admin.locodeco.components.MultiControlPoints;
	import com.tinyspeck.engine.admin.locodeco.components.PlatformControlPoints;
	import com.tinyspeck.engine.admin.locodeco.components.ResizeableControlPoints;
	import com.tinyspeck.engine.admin.locodeco.components.WallControlPoints;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.data.location.AbstractPositionableLocationEntity;
	import com.tinyspeck.engine.data.location.Box;
	import com.tinyspeck.engine.data.location.Deco;
	import com.tinyspeck.engine.data.location.Door;
	import com.tinyspeck.engine.data.location.Ladder;
	import com.tinyspeck.engine.data.location.Layer;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.location.MiddleGroundLayer;
	import com.tinyspeck.engine.data.location.PlatformLine;
	import com.tinyspeck.engine.data.location.PlatformLinePoint;
	import com.tinyspeck.engine.data.location.QuarterInfo;
	import com.tinyspeck.engine.data.location.SignPost;
	import com.tinyspeck.engine.data.location.Target;
	import com.tinyspeck.engine.data.location.Tiling;
	import com.tinyspeck.engine.data.location.Wall;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.physics.util.LocationPhysicsHealer;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.util.VectorUtil;
	import com.tinyspeck.engine.view.gameoverlay.LoadingLocationView;
	import com.tinyspeck.engine.view.gameoverlay.maps.MiniMapView;
	import com.tinyspeck.engine.view.renderer.DecoAssetManager;
	import com.tinyspeck.engine.view.renderer.IAbstractDecoRenderer;
	import com.tinyspeck.engine.view.renderer.LayerRenderer;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.Loader;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.TextEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import locodeco.LocoDecoGlobals;
	import locodeco.models.ColorModel;
	import locodeco.models.DecoModel;
	import locodeco.models.DecoModelTypes;
	import locodeco.models.GeoModel;
	import locodeco.models.LayerModel;
	import locodeco.models.PlatformLineModel;
	import locodeco.util.QuadHull;
	import locodeco.util.TSIDGen;
	
	import mx.collections.ArrayList;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.FlexEvent;
	import mx.events.PropertyChangeEvent;
	
	public class LocoDecoSWFBridge extends Loader implements IMoveListener {
		public static const instance:LocoDecoSWFBridge = new LocoDecoSWFBridge();
		
		private static const KEY_REPEAT_DELAY:int       = 250; // ms
		
		public  static const UNDO_REVERT:String         = "location loaded";
		public  static const UNDO_MAP_VISIBILTY:String  = "map visiblity";
		private static const UNDO_GROUND_Y:String       = "ground-y changed";
		private static const UNDO_COMMIT:String         = "deco changes";
		private static const UNDO_GRADIENT:String       = "gradient changed";
		private static const UNDO_PLATFORM_HEAL:String  = "platforms healed";
		private static const UNDO_FILTERS:String        = "layer filters changed";
		private static const UNDO_REMOVE_GEO:String     = "geo removed";
		private static const UNDO_REMOVE_DECO:String    = "deco removed";
		private static const UNDO_REMOVE_LAYER:String   = "layer removed";
		private static const UNDO_GEO_CHANGED:String    = "geo list changed";
		private static const UNDO_DECOS_CHANGED:String  = "deco list changed";
		private static const UNDO_LAYERS:String         = "layer list changed";
		private static const UNDO_LAYER_VISIBLE:String  = "layer visibility changed";
		private static const UNDO_RENAME_DECO:String    = "rename deco";
		private static const UNDO_RENAME_LAYER:String   = "rename layer";
		private static const UNDO_RESIZE_LAYER:String   = "resize layer";
		private static const UNDO_PERMEABILITY:String   = "permeability changed";
		private static const UNDO_PLACEMENT:String      = "placement changed";
		private static const UNDO_STANDALONE:String     = "standalone changed";
		private static const UNDO_SIGN_CSS:String       = "sign css changed";
		private static const UNDO_SIGN_TEXT:String      = "sign text changed";
		
		private static const REGEX_LADDER:RegExp        = /(^ladder_tile_(center_\d\d_|cap_\d_))/;
		private static const REGEX_LADDER_CAP_0:RegExp  = /(^ladder_tile_cap_0_)/;
		private static const REGEX_LADDER_CAP_1:RegExp  = /(^ladder_tile_cap_1_)/;
		private static const REGEX_LADDER_CENTER:RegExp = /(^ladder_tile_center_\d\d_)/;
		
		private var _stage:Stage;
		private var _model:TSModelLocator;
		private var _location:Location;
		private var _gameRenderer:LocationRenderer;
		private var _globals:LocoDecoGlobals;
		private var _keyboard:KeyBeacon;
		private var _controlPoints:MultiControlPoints;
		private var _decoSelector:DecoSelectorDialog;
		
		/** True during onModelLocationChange so handlers don't run */
		private var _locationChanging:Boolean;
		
		/** True once the location has loaded */
		private var _locationLoaded:Boolean;
		
		/** Focus shit */
		private var _swfHasFocus:Boolean;
		
		/** True once init() has been called */
		private var _initialized:Boolean;
		
		/**
		 * Temporarily keeps track of last removed layer, in case it gets
		 * re-added again (in which case it was moved to a new Z order).
		 */
		private var _lastRemovedLayer:Layer;
		private var _lastRemovedDeco:Deco;
		
		private var _lastMouseX:int;
		private var _lastMouseY:int;
		private var _lastHighlightedDeco:DecoModelRenderer;

		/** New decos pending placement (e.g. when you CUT and PASTE) */
		private const _newDecos:Vector.<Deco>
			= new Vector.<Deco>();
		private const _newGeos:Vector.<AbstractPositionableLocationEntity>
			= new Vector.<AbstractPositionableLocationEntity>();
		
		// selection
		/** Queue up a deco to select when the deco finishes rendering */
		private const _pendingSelection:Vector.<DecoModel> = new Vector.<DecoModel>();
		/** When true, a mouse move will be started as soon as selected */
		private var _startMoveOnPendingSelection:Boolean;
		/** When true, a mouse move on the end handle of a platform will be started as soon as selected */
		private var _startEndHandleMoveOnPendingSelection:Boolean;
		/**
		 * Each time something is deselected, check if something changed;
		 * if something did, this becomes true. After last item is deselected,
		 * this will be used to determine whether to push an undo and is reset.
		 */
		private var _changesMadeDuringMultiSelection:Boolean = false;
		/** Hack so that when a new geo or deco are created manually, we know ESCAPE should remove them */
		private var _lastSelectionWasANewModel:Boolean = false;
		
		// keyboard
		/** True when onKeyDown has executed, false when keyUpHandler runs */
		private var _keyDown:Boolean;
		/** When the last keypress actually did something (sometimes after pressed) */
		private var _firstKeyEventAt:Number = NaN;

		// undo
		/** Disables creation of undo points while true */
		private var _disableNewUndos:Boolean = false;
		
		/** While the mouse is down, this specifies whether it originated over the viewport */
		private var _mouseDownOriginatedInViewport:Boolean;
		
		public function LocoDecoSWFBridge() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			// SWF not ready for display
			visible = false;
		}
		
		public function get isInititalized():Boolean {
			return _initialized;
		}
		
		// IMoveListener funcs
		// -----------------------------------------------------------------
		
		public function moveLocationHasChanged():void {
			onModelLocationChange(TSModelLocator.instance.worldModel.location);
		}
		
		public function moveLocationAssetsAreReady():void {
			onModelLocationChange(TSModelLocator.instance.worldModel.location);
		}
		
		public function moveMoveStarted():void {
		
		}
		
		public function moveMoveEnded():void {
		
		}
		
		// -----------------------------------------------------------------
		// END IMoveListener funcs
		
		public function init():void {
			if (_initialized) return;
			_initialized = true;
			
			_model = TSModelLocator.instance;
			_stage = StageBeacon.stage;
			_gameRenderer = TSFrontController.instance.getMainView().gameRenderer;
			_globals = LocoDecoGlobals.instance;
			_keyboard = KeyBeacon.instance;
			_decoSelector = DecoSelectorDialog.instance;
			
			_controlPoints = new MultiControlPoints();
			_controlPoints.stage = _stage;
			_gameRenderer.registerControlPoint(_controlPoints);
			
			// start reporting load progress
			_model.stateModel.locodeco_loading = true;
			LoadingLocationView.instance.fadeIn();
			TSFrontController.instance.startLoadingLocationProgress('Loading LocoDeco...');
			
			// load LD into a child appdomain
			const ldSwfUrl:String = _model.flashVarModel.locodeco_url;
			load(new URLRequest(ldSwfUrl), new LoaderContext(true, new ApplicationDomain(ApplicationDomain.currentDomain)));
			
			CONFIG::debugging {
				Console.log(66, 'loading ' + ldSwfUrl);
			}
			
			//http://troygilbert.com/2009/05/loading-flex-based-swfs-in-as3-only-swfs/
			//http://webcache.googleusercontent.com/search?q=cache:http://richardleggett.co.uk/blog/index.php/2009/04/02/loading-swfs-into-air-1-5-and-loaderinfo
			contentLoaderInfo.addEventListener(Event.COMPLETE, onSWFComplete);
			contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onProgress);
			//contentLoaderInfo.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
			//contentLoaderInfo.addEventListener(Event.INIT, initHandler);
			//contentLoaderInfo.addEventListener(Event.OPEN, openHandler);
			//contentLoaderInfo.addEventListener(Event.UNLOAD, unLoadHandler);
			
			// fix focus issues
			// high priority is critical here -- must be captured before the game
			_stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseFocusDown, false, int.MAX_VALUE);
			
			// prepare disambiguation menu
			DisambiguationDialog.instance.tf.addEventListener(TextEvent.LINK, handleDisambiguationLink);
		}
		
		public function refresh():void {
			_decoSelector.refresh();
			LocoDecoFocusWarning.instance.refresh();
			_globals.sideBarWidth = LocoDecoSideBar.instance.w;
			_globals.sideBarHeight = LocoDecoSideBar.instance.h;
		}
		
		public function loadCurrentLocationModel():void {
			onModelLocationChange(TSModelLocator.instance.worldModel.location);
		}
		
		public function newDecoUnderPoint(className:String, w:int, h:int, x:int, y:int):DecoModel {
			// build a new Deco object; brand new TSID, but the friendly name (usually last TSID) will be identical
			const newDeco:Deco = new Deco(TSIDGen.newTSID(className));
			_newDecos.push(newDeco);
			newDeco.sprite_class = className;
			newDeco.w = w;
			newDeco.h = h;
			
			// decide whether this is animated based on deco groups
			newDeco.animated = DecoAssetManager.isInGroup(className, 'animated');
			
			// find the selected (target) layer
			var lm:LayerModel = _globals.selectedLayer;
			// if there is no selected layer, use the top layer
			if (!lm) lm = _globals.location.layerModels.getItemAt(0) as LayerModel;
			
			// add a deco under mouse, select it, and start a move immediately
			const targetLayer:Layer = _location.getLayerById(lm.tsid);
			const targetPoint:Point = _gameRenderer.translateLayerGlobalToLocal(targetLayer, x, y);
			newDeco.x = targetPoint.x;
			newDeco.y = targetPoint.y;
			
			// default: put on top of current layer
			var idx:int = 0;
			const decos:ArrayList = lm.decos;
			if (_globals.isSingleSelectionADeco) {
				// put above selected deco
				idx = decos.getItemIndex(_globals.selectedDeco);
			}
			
			// track this deco in our model
			_lastSelectionWasANewModel = true;
			const dm:DecoModel = ModelFactory.newDecoModel(newDeco, lm);
			decos.addItemAt(dm, idx);
			// dirtying the renderer will happen by databinding to 'decos'
			
			return dm;
		}
		
////////////////////////////////////////////////////////////////////////////////
//////// FLASH EVENT HANDLERS //////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
		
		private function onProgress(e:ProgressEvent):void {
			TSFrontController.instance.updateLoadingLocationProgress(e.bytesLoaded/e.bytesTotal);
		}
		
		/** Moves stage focus between the game and the SWF */
		private function onMouseFocusDown(e:MouseEvent):void {
			if (contains(e.target as DisplayObject)) {
				// locodeco swf is gaining focus
				if (!_swfHasFocus) {
					_swfHasFocus = true;
					// draw a warning
					LocoDecoFocusWarning.instance.show();
				}
				// game has or is regaining keyboard focus via mouse
			} else if (_swfHasFocus) {
				// restore stage focus to the game
				_swfHasFocus = false;
				_stage.focus = e.target as InteractiveObject;
				LocoDecoFocusWarning.instance.hide();
			}
		}
		
		/** Returns the increment/decrement for rotation and positioning */
		private function getIncrement():int {
			var xcrement:int = LocoDecoConstants.DEFAULT_INCREMENT;
			if (_keyboard.pressed(Keyboard.SHIFT)) {
				xcrement = LocoDecoConstants.SHIFT_INCREMENT;
			} else if (_keyboard.pressed(Keyboard.Z)) {
				xcrement = 1;
			}
			return xcrement;
		}
		
		private function onKeyUp(e:KeyboardEvent):void {
			// ignore key input since a label is getting its text on
			if (_globals.currentlyEditingALabel) return;
			
			// reset repeat delay whenever all the arrow keys are depressed
			if (!_keyboard.anyArrowKeysPressed()) {
				_keyDown = false;
				_firstKeyEventAt = NaN;
			}
			
			const control:Boolean = (e.ctrlKey || _keyboard.pressed(Keyboard.CONTROL));
			switch (e.keyCode) {
			case Keyboard.D:
				if (!control) {
					// normal deco selection for placement
					if (!_decoSelector.hasFocus()) {
						_decoSelector.startWithOptions(DecoSelectorDialog.instance.category,
							function (className:String, w:uint, h:uint, e:MouseEvent):void {
								_decoSelector.end(true);
								// add a deco, place it under mouse, select it, and start a move immediately
								LocoDecoSWFBridge.instance.select(LocoDecoSWFBridge.instance.newDecoUnderPoint(className, w, h, e.stageX, (e.stageY + h/2)), true, true);
							});
					}
				}
				break;
			}
		}
		
		private function onKeyDown(e:KeyboardEvent):void {
			// ignore key input since a label is getting its text on
			if (_globals.currentlyEditingALabel) return;
			
			// key repeat buster
			if (_keyDown) return;
			_keyDown = (e.keyCode != Keyboard.CONTROL) && (e.keyCode != Keyboard.SHIFT) && (e.keyCode != Keyboard.ALTERNATE) && (e.keyCode != Keyboard.COMMAND);
			
			var dm:DecoModel;
			const control:Boolean = (e.ctrlKey || _keyboard.pressed(Keyboard.CONTROL));
			
			switch (e.keyCode) {
			case Keyboard.Z:
				if (control) {
					// undo all deco/geo changes since last selection was made
					// (act like pressing ESCAPE the first if there are changes)
					if (_globals.isSelectionActive) {
						undoUncommittedChanges();
					} else {
						// if there's no selection, go back further:
						popUndo(true);
					}
				}
				break;
			case Keyboard.A:
				if (control) {
					// if shift is down, select across all layers
					selectAll(!e.shiftKey);
				} else {
					if (DisambiguationDialog.instance.hasFocus()) {
						DisambiguationDialog.instance.end(true);
						break;
					}
					
					// show a list of decos under the mouse
					const decosUnderMouse:Vector.<DecoModelRenderer> = getDecosUnderCursor();
					if (decosUnderMouse.length > 0) {
						var htmlTxt:String = '';
						var lastLayerName:String;
						for each (var dmr:DecoModelRenderer in decosUnderMouse) {
							if (lastLayerName != dmr.dm.layer.name) {
								lastLayerName = dmr.dm.layer.name;
								htmlTxt += '<span class="locodeco_disambig_header">' + lastLayerName + '</span><br/>';
							}
							htmlTxt += '<span class="locodeco_disambig"><a href="event:' + dmr.dm.layer.tsid + '#' + dmr.dm.tsid + '">' + dmr.dm.name + '</a></span><br/>';
						}
						DisambiguationDialog.instance.startWithHTMLText(htmlTxt);
					}
				}
				break;
			case Keyboard.D:
				if (control) deselectAll();
				break;
			case Keyboard.X:
				if (control) cut();
				break;
			case Keyboard.C:
				if (control) copy();
				break;
			case Keyboard.V:
				if (control) paste();
				break;
			case Keyboard.DELETE:
			case Keyboard.BACKSPACE:
				// remove all selected decos
				for each (dm in _globals.selectedDecos.concat()) {
					dm.removeFromLayer();
				}
				deselectAll();
				break;
			case Keyboard.ESCAPE:
				// try undoing changes
				if (!undoUncommittedChanges()) {
					// if there are none to undo, deselect everything
					deselectAll();
				}
				break;
			case Keyboard.ENTER:
				// commit is implied in deselectAll if changes occurred
				//pushUndo(UNDO_COMMIT);
				deselectAll();
				break;
			}
		}

		private function onEnterFrame(ms_elapsed:int):void {
			// handle a pending deco selection
			var dm:DecoModel;
			if (_pendingSelection.length == 1) {
				// single pending selections should clear existing selections
				if (select(_pendingSelection[0], true, _startMoveOnPendingSelection, _startEndHandleMoveOnPendingSelection)) {
					_pendingSelection.length = 0;
					_startMoveOnPendingSelection = false;
					_startEndHandleMoveOnPendingSelection = false;
				}
			} else if (_pendingSelection.length) {
				// slice the vector because we're gonna modify it in the loop
				for each (dm in _pendingSelection.slice()) {
					// multiple pending selections should append to existing selections
					if (select(dm, false)) {
						_pendingSelection.splice(_pendingSelection.indexOf(dm), 1);
					}
				}
			}

			const lm:LayoutModel = _model.layoutModel;
			const xcrement:int = getIncrement();
			const inc:int = 5*getIncrement();
			
			var old_x:int;
			var old_y:int;
			var new_x:int;
			var new_y:int;
			
			// if the mouse is dragging across the edges of the VP, scroll it
			if (StageBeacon.mouseIsDown && _mouseDownOriginatedInViewport && _globals.isSelectionActive) {
				var moving:Boolean;
				
				// pan the world
				old_x = new_x = _model.layoutModel.loc_cur_x;
				old_y = new_y = _model.layoutModel.loc_cur_y;
				
				if (StageBeacon.stage_mouse_pt.x >= (lm.gutter_w + lm.loc_vp_w)) {
					// pan right
					new_x += inc;
					moving = true;
				} else if (StageBeacon.stage_mouse_pt.x < lm.gutter_w) {
					// pan left
					new_x -= inc;
					moving = true;
				}
				
				// allow diagonal movement by separating the IF blocks
				if (StageBeacon.stage_mouse_pt.y < lm.header_h) {
					// pan up
					new_y -= inc;
					moving = true;
				} else if (StageBeacon.stage_mouse_pt.y >= (lm.header_h + lm.loc_vp_h)) {
					// pan down
					new_y += inc;
					moving = true;
				}
				
				if (moving) {
					// pan the renderer
					_gameRenderer.moveTo(new_x, new_y);
					// reset the move's start position
					_controlPoints.restartMove();
				}
				return;
			}
			
			// ignore key input since a label is getting its text on
			if (_globals.currentlyEditingALabel) return;
			
			// return if no keys are pressed, or the key repeat interval hasn't elapsed
			if (!_keyDown || (!isNaN(_firstKeyEventAt) && ((getTimer() - _firstKeyEventAt) < KEY_REPEAT_DELAY))) return;
			
			const up:Boolean = _keyboard.pressed(Keyboard.UP);
			const down:Boolean = _keyboard.pressed(Keyboard.DOWN);
			const control:Boolean = _keyboard.pressed(Keyboard.CONTROL);
			const shift:Boolean = _keyboard.pressed(Keyboard.SHIFT);
			
			var repeatableKeyEventOccurred:Boolean;
			if (control) {
				var oldIdx:int;
				var newIdx:int;
				var decos:ArrayList;
				if (up || down) {
					repeatableKeyEventOccurred = true;
					
					// move upwards/downwards in Z order on current layer
					for each (dm in _globals.selectedDecos.concat()) {
						// geo has no z order and can't leave middleground
						if (dm is GeoModel) continue;

						decos = dm.layer.decos;
						oldIdx = decos.getItemIndex(dm);
						if (shift) {
							// ctrl+shift+up/down -- top/bottom
							newIdx = (up ? 0 : decos.length);
							// disallow key repeat
							repeatableKeyEventOccurred = false;
						} else {
							newIdx = oldIdx + (up ? -1 : 1);
						}
						newIdx = Math.max(0, Math.min(decos.length, newIdx));
						if (newIdx != oldIdx) {
							if (decos.length == newIdx) {
								// sometimes this RTEs if we try to add to the end using an index
								decos.addItem(decos.removeItemAt(oldIdx));
							} else {
								decos.addItemAt(decos.removeItemAt(oldIdx), newIdx);
							}
							// reselect deco (databinding deselects it when we move it in the decos/layers lists)
							_pendingSelection.push(dm);
						}
					}
				}
			} else if (_globals.isSelectionActive) {
				for each (dm in _globals.selectedDecos.concat()) {
					// rotate the selected deco(s)
					if (_keyboard.pressed(Keyboard.R)) {
						if (_keyboard.pressed(Keyboard.RIGHT)) {
							dm.r += xcrement;
							repeatableKeyEventOccurred = true;
						} else if (_keyboard.pressed(Keyboard.LEFT)) {
							dm.r -= xcrement;
							repeatableKeyEventOccurred = true;
						}
					} else {
						// move the selected deco(s)
						if (_keyboard.pressed(Keyboard.RIGHT)) {
							dm.x += xcrement;
							repeatableKeyEventOccurred = true;
						} else if (_keyboard.pressed(Keyboard.LEFT)) {
							dm.x -= xcrement;
							repeatableKeyEventOccurred = true;
						}
						
						// allow diagonal movement by separating the IF blocks
						if (up) {
							dm.y -= xcrement;
							repeatableKeyEventOccurred = true;
						} else if (down) {
							dm.y += xcrement;
							repeatableKeyEventOccurred = true;
						}
					}
				}
			} else {
				// pan the world
				new_x = lm.loc_cur_x;
				new_y = lm.loc_cur_y;
				
				if (_keyboard.pressed(Keyboard.RIGHT)) {
					new_x+= inc;
					repeatableKeyEventOccurred = true;
				} else if (_keyboard.pressed(Keyboard.LEFT)) {
					new_x-= inc;
					repeatableKeyEventOccurred = true;
				}
				
				// allow diagonal movement by separating the IF blocks
				if (up) {
					new_y-= inc;
					repeatableKeyEventOccurred = true;
				} else if (down) {
					new_y+= inc;
					repeatableKeyEventOccurred = true;
				}
				
				_gameRenderer.moveTo(new_x, new_y);
			}
			
			// if a valid key was pressed, then we start counting the interval
			if (repeatableKeyEventOccurred && isNaN(_firstKeyEventAt)) _firstKeyEventAt = getTimer();
		}
		
		/** Pans the viewport using a 2D mousewheel */
		private function onMouseWheel(e:CartesianMouseEvent):void {
			if (!_gameRenderer.contains(e.target as DisplayObject)) {
				// however bug [2060]: you may be trying to draw geometry over
				// a location with no gradient, so detect that before giving up
				if ((e.target != TSFrontController.instance.getMainView()) || !_gameRenderer.hitTestPoint(e.stageX, e.stageY)) {
					return;
				}
			}
			
			// Webkit may give you TWO non-zero values as it allows simultaneous scrolling
			const new_x:int = _model.layoutModel.loc_cur_x-int(e.xDelta*10);
			const new_y:int = _model.layoutModel.loc_cur_y-int(e.yDelta*10);
			_gameRenderer.moveTo(new_x, new_y);
		}
		
		private function handleDisambiguationLink(event:TextEvent):void {
			// LAYER_TSID#DECO_TSID
			const link:Array = event.text.split('#');
			const layerTSID:String = link[0];
			const decoTSID:String  = link[1];
			// select it
			select(_globals.location.getDecoModel(decoTSID, layerTSID), !_keyboard.pressed(Keyboard.SHIFT));
			// close dialog
			DisambiguationDialog.instance.end(true);
			// focus is probably on the now hidden field, reset it
			_stage.focus = null;
		}
		
		private function onMouseUp(e:MouseEvent):void {
			// while the mouse was down, we disabled highlighting
			enableHighlighting();
			// and hide the control points
			_controlPoints.visible = true;
			
			var dm:DecoModel;
			
			if (_globals.selectedDecos.length) {
				const movedPlatforms:Vector.<PlatformLineModel> = new Vector.<PlatformLineModel>();
				for each (dm in _globals.selectedDecos.concat()) {
					// a drag might be ending; mark the starting dimensions of all
					// selected decos for future constrain proportions actions
					dm.markCurrentDimensions();
					
					// are any of these platforms? do snapping if they were
					if (dm.type == DecoModelTypes.PLATFORM_LINE_TYPE) movedPlatforms.push(PlatformLineModel(dm));
				}
				
				for each (var plm:PlatformLineModel in movedPlatforms) {
					// snap to other platforms and walls but never to self
					var testPoint:Point = new Point (plm.x1, plm.y1);
					var otherPoint:Point = new Point (plm.x2, plm.y2);
					var snappedPoint:Object = LocationPhysicsHealer.snapPointToPlatformLinesAndWalls(testPoint, plm.is_for_placement, _location.mg.platform_lines, _location.mg.walls);
					if ((snappedPoint != testPoint) && ((snappedPoint.x != otherPoint.x) || (snappedPoint.y != otherPoint.y))) {
						plm.x1 = snappedPoint.x;
						plm.y1 = snappedPoint.y;
					}
					
					testPoint = new Point (plm.x2, plm.y2);
					otherPoint = new Point (plm.x1, plm.y1);
					snappedPoint = LocationPhysicsHealer.snapPointToPlatformLinesAndWalls(testPoint, plm.is_for_placement, _location.mg.platform_lines, _location.mg.walls);
					if ((snappedPoint != testPoint) && ((snappedPoint.x != otherPoint.x) || (snappedPoint.y != otherPoint.y))) {
						plm.x2 = snappedPoint.x;
						plm.y2 = snappedPoint.y;
					}
				}
			}
			
			// D-clicking certain geometry to select decos for them
			if (_globals.isSingleSelectionActive && _keyboard.pressed(Keyboard.D) && !_decoSelector.hasFocus()) {
				dm = _globals.selectedDeco;
				var category:String;
				switch (dm.type) {
					case DecoModelTypes.LADDER_TYPE:
						category = DecoSelectorDialog.CATEGORY_LADDERS;
						break;
					case DecoModelTypes.DOOR_TYPE:
						category = DecoSelectorDialog.CATEGORY_DOORS;
						break;
					case DecoModelTypes.SIGNPOST_TYPE:
						category = DecoSelectorDialog.CATEGORY_SIGNS;
						break;
				}
				
				if (!category) return;
				
				_decoSelector.startWithOptions(category, null,
					function (className:String, w:uint, h:uint, e:MouseEvent):void {
						_decoSelector.end(true);
						
						pushUndo(UNDO_REMOVE_DECO);
						deselect(dm);
						
						// rebuild the geo
						const drc:IAbstractDecoRenderer = _gameRenderer.getAbstractDecoRendererByTsid(dm.tsid, dm.layer.tsid);
						const geo:AbstractPositionableLocationEntity = drc.getModel();
						if ((geo is Door) || (geo is SignPost)) {
							// build a new deco
							const deco:Deco = new Deco(TSIDGen.newTSID(className));
							deco.sprite_class = className;
							deco.w = w;
							deco.h = h;
							if (geo is Door) {
								Door(geo).w = w;
								Door(geo).h = h;
								Door(geo).deco = deco;
							} else {
								SignPost(geo).w = w;
								SignPost(geo).h = h;
								SignPost(geo).deco = deco;
							}
						} else if (geo is Ladder) {
							// unlike doors, ladders require special decos
							if (!REGEX_LADDER.test(className)) return;
							
							const ladder:Ladder = Ladder(geo);
							
							// grab the set identifier
							const setID:String = className.replace(REGEX_LADDER_CENTER, '');
							
							// step over all available assets and gather all of
							// the tiles from this set to build the Tiling obj
							const tilingAMF:Object = {};
							const centerPattern:Vector.<int> = new Vector.<int>();
							const classNames:Vector.<String> = DecoAssetManager.getActiveClassNames();
							tilingAMF.centers = {};
							for (var cname:String in classNames) {
								if (REGEX_LADDER.test(cname)) {
									var dims:Object = DecoAssetManager.getDimensions(cname);
									var obj:Object = {
										w: dims.width,
										h: dims.height,
										sprite_class: cname
									};
									if (cname.replace(REGEX_LADDER_CAP_0, '') == setID) {
										tilingAMF.cap_0 = obj;
									} else if (cname.replace(REGEX_LADDER_CAP_1, '') == setID) {
										tilingAMF.cap_1 = obj;
									} else if (cname.replace(REGEX_LADDER_CENTER, '') == setID) {
										tilingAMF.centers[centerPattern.push(centerPattern.length)-1] = obj;
									}
								}
							}
							
							// randomize tiling
							VectorUtil.shuffle(centerPattern);
							tilingAMF.center_pattern = centerPattern.join();
							
							// replace missing caps
							if (!tilingAMF.hasOwnProperty('cap_0')) {
								tilingAMF.cap_0 = tilingAMF.centers[centerPattern[0]];
							}
							if (!tilingAMF.hasOwnProperty('cap_1')) {
								tilingAMF.cap_1 = tilingAMF.centers[centerPattern[centerPattern.length-1]];
							}
							
							ladder.tiling = Tiling.fromAnonymous(tilingAMF, "tiling");
						}
						
						const AMF:Object = geo.AMF();
						if ((geo is SignPost) && SignPost(geo).client::quarter_info) {
							// quarter_info is not serialized in SignPost.AMF since
							// the GS populates it dynamically, but must be copied in LD
							AMF.quarter_info = SignPost(geo).client::quarter_info.AMF();
						}

						// remove from our layer model and the renderer
						dm.removeFromLayer();
						dm.dispose();
						
						// add the new geo
						const newModel:AbstractPositionableLocationEntity = ModelFactory.newLocationModelFromAMF(dm.type, AMF);
						_newGeos.push(newModel);
						
						// update our model
						// dirtying the renderers will happen via databinding on the ArrayLists below
						dm = ModelFactory.newDecoModelFromLocationModel(newModel, LayerModel.middleground);
						_globals.location.geometryModels.addItem(dm);
						
						// reselect
						select(dm);
					});
			}
		}
		
		private function onMouseDown(e:MouseEvent):void {
			// only allow clicking on the renderer, skip dialogs above it
			if (!_gameRenderer.contains(e.target as DisplayObject)) {
				// however bug [2060]: you may be trying to draw geometry over
				// a location with no gradient, so detect that before giving up
				if ((e.target != TSFrontController.instance.getMainView()) || !_gameRenderer.hitTestPoint(e.stageX, e.stageY)) {
					_mouseDownOriginatedInViewport = false;
					return;
				}
			}
			
			_mouseDownOriginatedInViewport = true;
			
			// start drawing a platform even if you are over a selection
			if (_keyboard.pressed(Keyboard.Q)) {
				_globals.overlayPlatforms = true;
				select(newPlatformLineUnderMouse(), true, false, true);
				return;
			}
			
			// start drawing a wall even if you are over a selection
			if (_keyboard.pressed(Keyboard.W)) {
				_globals.overlayPlatforms = true;
				select(newWallUnderMouse(), true, false, true);
				return;
			}
			
			// start drawing a ladder even if you are over a selection
			if (_keyboard.pressed(Keyboard.E)) {
				_globals.overlayPlatforms = true;
				select(newLadderUnderMouse(), true, false, true);
				return;
			}
			
			// if clicking on a control point you're probably starting a drag
			if (_controlPoints.contains(e.target as DisplayObject)) {
				// except if the shift key is down and you're over the move handle
				// (the invisible draggable area in the middle of a deco) -- then you're deselecting it
				if (!(e.shiftKey && _controlPoints.isMouseOverMoveHandle(e))) return;
			}
			
			const newSelection:DecoModelRenderer = chooseMostLikelyDecoForSelection(getDecosUnderCursor());
			
			// if there isn't a new selection, we have nothing to do here
			if (!newSelection) return;
			
			// if shift-clicking something, and there's an old single selection
			if (_globals.isSingleSelectionActive && e.shiftKey) {
				// if shift-clicking the already-selected deco, deselect
				if (_globals.selectedDeco == newSelection.dm) {
					deselect(_globals.selectedDeco);
					// otherwise shift-clicking a new deco in addition to an old deco
				} else {
					// begin a multiselect by adding this deco
					select(newSelection.dm, false);
				}
			} else if (_globals.isMultiSelectionActive && e.shiftKey) {
				// if we're already in a multiselect and shift is held down;
				// we might be deselecting an existing selection
				if (_globals.isSelected(newSelection.dm)) {
					deselect(newSelection.dm);
				} else {
					// otherwise we're adding a new one to the multiselect
					select(newSelection.dm, false);
				}
			} else {
				// basic single selection; start a move immediately
				select(newSelection.dm, true, true);
			}
		}
		
		private function onMouseMove(e:MouseEvent):void {
			// if the mouse hasn't moved or we're in the middle of a drag, don't highlight anything new
			if (StageBeacon.mouseIsDown || ((_lastMouseX == _stage.mouseX) && (_lastMouseY == _stage.mouseY))) {
				// while mouse is down, temporarily disable highlighting,
				// hide the control points, and clean up our last highlight
				if (!_gameRenderer.disableHighlighting) {
					_controlPoints.visible = false;
					disableHighlighting();
					unhighlightLastHighlight();
				}
				return;
			}
			
			_lastMouseX = _stage.mouseX;
			_lastMouseY = _stage.mouseY;
			
			// if we're not supposed to glow on hover, return
			if (!_globals.overlayHoverGlow) {
				unhighlightLastHighlight();
				return;
			}
			
			// if we're hovering over the map or other UI,
			// remove existing highlights and don't highlight anything new
			if (!_gameRenderer.contains(e.target as DisplayObject)) {
				unhighlightLastHighlight();
				return;
			}
			
			// find the object that you are most likely selecting
			const newHighlight:DecoModelRenderer = chooseMostLikelyDecoForSelection(getDecosUnderCursor());
			
			// if the new highlight is already selected, we're done
			if (newHighlight && _globals.isSelected(newHighlight.dm)) return;
			
			// at this point we can be sure that there is a new highlight
			// and it is not over the existing highlight or selection
			unhighlightLastHighlight();
			
			// draw the new highlight
			if (newHighlight) {
				_lastHighlightedDeco = newHighlight;
				highlight(newHighlight.drc, newHighlight.lr);
				_gameRenderer.useHandCursor = true;
				_gameRenderer.buttonMode = true;
			}
		}
		
		private function onIOError(event:IOErrorEvent):void {
			const str:String = 'Failed to load ' + contentLoaderInfo.url;
			CONFIG::debugging {
				Console.warn(str);
			}
			BootError.addErrorMsg(str, null, ['locodeco']);
		}
		
		private function onSWFComplete(event:Event):void {
			CONFIG::debugging {
				Console.log(66, 'loaded ' + contentLoaderInfo.url);
				Console.warn('onSWFComplete');
			}
			
			// update Buildometer to track LocoDeco.swf
			if (_model.flashVarModel.show_buildtime) {
				const buildometer:BuildDecayChronograph = (StageBeacon.stage.getChildByName('buildometer') as BuildDecayChronograph);
				buildometer.label = "locodeco";
				buildometer.swfBytes = contentLoaderInfo.bytes;
			}

			// handler for LD application complete
			content.loaderInfo.sharedEvents.addEventListener(
				FlexEvent.APPLICATION_COMPLETE, ldApplicationComplete);
		}
		
		private function ldApplicationComplete(e:FlexEvent):void {
			CONFIG::debugging {
				Console.warn('ldApplicationComplete');
			}
			
			// tell loading screen that we're done loading
			_model.stateModel.locodeco_loading = false;
			TSFrontController.instance.updateLoadingLocationProgress(1);
			LoadingLocationView.instance.fadeOut();
			
			// load initial location into models
			loadCurrentLocationModel();
			
			// track non-location globals (e.g. scale)
			_globals.addEventListener(
				PropertyChangeEvent.PROPERTY_CHANGE, onGlobalsPropertyChange);
			
			// track location things
			_globals.location.addEventListener(
				PropertyChangeEvent.PROPERTY_CHANGE, onLocationPropertyChange);
				
			// track the SWF layer, deco, and geo models
			_globals.location.layerModels.addEventListener(
				PropertyChangeEvent.PROPERTY_CHANGE, onLayerModelPropertyChange);
			_globals.location.layerModels.addEventListener(
				PropertyChangeEvent.PROPERTY_CHANGE, onDecoModelPropertyChange);
			_globals.location.geometryModels.addEventListener(
				PropertyChangeEvent.PROPERTY_CHANGE, onDecoModelPropertyChange);
			
			_globals.location.layerModels.addEventListener(
				CollectionEvent.COLLECTION_CHANGE, onLayerModelCollectionChange);
			_globals.multiSelectedDecos.addEventListener(
				CollectionEvent.COLLECTION_CHANGE, onMultiSelectedDecosPropertyChange);
			_globals.location.geometryModels.addEventListener(
				CollectionEvent.COLLECTION_CHANGE, onGeoModelCollectionChange);
			
			// track gradients
			_globals.location.topGradientColor.addEventListener(
				PropertyChangeEvent.PROPERTY_CHANGE, onGradientChange);
			_globals.location.bottomGradientColor.addEventListener(
				PropertyChangeEvent.PROPERTY_CHANGE, onGradientChange);
			
			// onEditingUnsavedChanges gets called when there are new unsaved changes, or no more unsaved changed
			_model.stateModel.registerCBProp(onEditingUnsavedChanges, 'editing_unsaved');
			// onSavingChanges gets called when we are in the middle of saving changes to the server
			_model.stateModel.registerCBProp(onSavingChanges, 'editing_saving_changes');
			
			// track future location updates
			TSFrontController.instance.registerMoveListener(this);
			_model.physicsModel.registerCBProp(onGeometryHealed, "platform_lines_healed");

			// listen for future changes to editing and trigger the first one
			// (don't want to listen before the SWF is ready)
			_model.stateModel.registerCBProp(onEditingChange, 'editing');
			onEditingChange(_model.stateModel.editing);
			
			// ready to display
			refresh();
			visible = true;
		}
		
		/** Gets all databinding changes to LocoDecoGlobals.instance.multiSelectedDecos */
		private function onMultiSelectedDecosPropertyChange(ce:CollectionEvent):void {
			//trace(ce.kind + ": " + ce.oldLocation + " -> " + ce.location);
			//for each (var o:Object in ce.items)
			//	trace('\t', o);
			
			// bail if the location is changing
			if (_locationChanging) return;

			switch (ce.kind) {
				case CollectionEventKind.ADD:
				case CollectionEventKind.REMOVE: {
					// a new selection was added (selected) or removed (deselected)
					const dm:DecoModel = DecoModel(ce.items[0]);
					const drc:IAbstractDecoRenderer = _gameRenderer.getAbstractDecoRendererByTsid(dm.tsid, dm.layer.tsid);
					
					if (ce.kind == CollectionEventKind.ADD) {
						// store an undo point for the escape key
						dm.saveState();
						dm.markCurrentDimensions();

						// select it
						attachControlPointsToDecoRenderer(dm, drc);
						
						// glow selection
						highlight(drc, _gameRenderer.getLayerRendererByTSID(dm.layer.tsid));
					} else {
						// CollectionEventKind.REMOVE
						_changesMadeDuringMultiSelection ||= dm.changesSinceSavedState();
						dm.clearSavedState();
						_controlPoints.unregisterControlPoint(drc);
						unhighlight(drc, _gameRenderer.getLayerRendererByTSID(dm.layer.tsid));
						
						// if there are no more selections and changes were made, commit changes
						if (!_globals.isSelectionActive) {
							if (_changesMadeDuringMultiSelection) pushUndo(UNDO_COMMIT);
							_changesMadeDuringMultiSelection = false;
						}
					}
					break;
				}
			}
		}
		
		/** Gets changes to location state (such as ground-y) */
		private function onLocationPropertyChange(pce:PropertyChangeEvent):void {
			//trace(pce.property + ": " + pce.oldValue + " -> " + pce.newValue);
			switch (pce.property) {
				case 'groundY':
					const tmpGroundY:int = Math.min(_location.b, Math.max(_location.t, int(pce.newValue)));
					if (tmpGroundY != _location.ground_y) {
						pushUndo(UNDO_GROUND_Y);
						_location.ground_y = tmpGroundY;
						_globals.location.groundY = tmpGroundY;
						GroundYView.instance.refresh();
					}
					break;
				}
		}
		
		/** Gets all changes to non-location state (such as scale) */
		private function onGlobalsPropertyChange(pce:PropertyChangeEvent):void {
			//trace(pce.property + ": " + pce.oldValue + " -> " + pce.newValue);
			var deco:DecoModel;
			switch (pce.property) {
				case 'groundYMode':
					// when in ground-y mode, show the overlay
					GroundYView.instance.visible = _globals.groundYMode;
					GroundYView.instance.refresh();
					break;
				case 'toolTips':
					TSFrontController.instance.changeTipsVisibility(LocoDecoGlobals.instance.toolTips, 'LOCODECOSIDEBAR');
					break;
				case 'onlySelectGeos':
					if (_globals.onlySelectGeos) {
						// deselect all selected non-geos
						// (concat() because we may modify the array each iteration)
						for each (deco in _globals.selectedDecos.concat()) {
							if (!(deco is GeoModel)) deselect(deco);
						}
					}
					break;
				case 'overlayInteractionRegion':
					break;
				case 'overlayJumpArc':
					break;
				case 'overlayRuler':
					break;
				case 'overlayPlatforms':
					setGeometryVisibility(DecoModelTypes.WALL_TYPE, Boolean(pce.newValue));
					setGeometryVisibility(DecoModelTypes.PLATFORM_LINE_TYPE, Boolean(pce.newValue));
					showHideInvisibleLadders();
					break;
				case 'overlayPCs':
					if (pce.newValue) {
						_gameRenderer.locationView.middleGroundRenderer.showPCs();
					} else {
						_gameRenderer.locationView.middleGroundRenderer.hidePCs();
					}
					break;
				case 'overlayItemstacks':
					if (pce.newValue) {
						_gameRenderer.locationView.middleGroundRenderer.showItemstacks();
						_gameRenderer.locationView.middleGroundRenderer.showCTBoxesTemporarily();
					} else {
						_gameRenderer.locationView.middleGroundRenderer.hideItemstacks();
						_gameRenderer.locationView.middleGroundRenderer.hideCTBoxesTemporarily();
					}
					break;
				case 'viewportScale':
					TSFrontController.instance.setViewportScale(_globals.viewportScale, 0, false, false, false);
					break;
				case 'viewportWidth':
				case 'viewportHeight':
					TSFrontController.instance.getMainView().layerDimensionsChanged();
					break;
				case 'centerVPOnSelection':
				case 'overlaySelectionGlow': {
					// re-select to enable or disable
					const selectedDecos:Array = _globals.selectedDecos;
					deselectAll();
					for each (deco in selectedDecos) {
						select(deco, false);
					}
					break;
				}
				case 'selectedLayer':
					deselectAll();
					break;
				case 'selectedDeco': {
					// single selection is changing
					const dm:DecoModel = DecoModel(pce.newValue);
					const oldDM:DecoModel = DecoModel(pce.oldValue);
					
					var drc:IAbstractDecoRenderer;
					
					// remove previous selection(s)
					clearMultiSelection();
					if (oldDM) {
						// if there are no more selections and something changed, commit changes
						if (oldDM.changesSinceSavedState()) {
							oldDM.clearSavedState();
							pushUndo(UNDO_COMMIT);
						}
						_lastSelectionWasANewModel = false;
						_controlPoints.clearTargets();
						drc = _gameRenderer.getAbstractDecoRendererByTsid(oldDM.tsid, oldDM.layer.tsid);
						unhighlight(drc, _gameRenderer.getLayerRendererByTSID(oldDM.layer.tsid));
					}
					
					if (dm) {
						// store an undo point for the escape key
						dm.saveState();
						dm.markCurrentDimensions();
					}
					
					if (dm && dm.visible) {
						drc = _gameRenderer.getAbstractDecoRendererByTsid(dm.tsid, dm.layer.tsid);
						
						// make sure the layer of this deco is selected
						_globals.selectedLayer = dm.layer;
						
						// select it
						attachControlPointsToDecoRenderer(dm, drc);
						
						// when selecting a deco from the deco panel, center the viewport over it
						if (_globals.centerVPOnSelection && _globals.selectionSourceIsDecoPanelUglyHack) {
							_gameRenderer.centerViewportOnDisplayObject(dm.tsid, dm.layer.tsid);
						}
						
						// glow selection
						highlight(drc, _gameRenderer.getLayerRendererByTSID(dm.layer.tsid));
					}
					break;
				}
				default:
					break;
			}
		}
		
		private function onGradientChange(e:Event):void {
			const somethingChanged:Boolean = !(_location.hasGradient() &&
				(_location.gradient.top.toUpperCase() == _globals.location.topGradientColor.hex) &&
				(_location.gradient.bottom.toUpperCase() == _globals.location.bottomGradientColor.hex));
			
			if (!_locationChanging && somethingChanged) {
				pushUndo(UNDO_GRADIENT);
				_location.gradient = {
					top:    _globals.location.topGradientColor.hex,
					bottom: _globals.location.bottomGradientColor.hex
				};
				_gameRenderer.gradientDirty = true;
			}
		}
		
		private function onLayerModelCollectionChange(ce:CollectionEvent):void {
			//trace(ce.kind + ": " + ce.oldLocation + " -> " + ce.location);
			//for each (var o:Object in ce.items)
			//	trace(o);
				
			// we have another handler for update events
			if (_locationChanging || (ce.kind == CollectionEventKind.UPDATE)) return;
				
			const changedLayerModel:LayerModel = LayerModel(ce.items[0]);
			const layers:Vector.<Layer> = _location.layers;
			
			var i:int;
			var ll:int;
			var layer:Layer;
			var somethingChanged:Boolean;
			
			// an add, delete, or move is occurring (a move is a delete + add)
			if (ce.kind == CollectionEventKind.REMOVE) {
				// find the associated Layer and remove it
				ll = layers.length;
				for (i=0; i<ll; i++) {
					layer = layers[int(i)];
					if (layer.tsid == changedLayerModel.tsid) {
						pushUndo(UNDO_REMOVE_LAYER);
						// store this in case we re-add it later
						_lastRemovedLayer = layer;
						changedLayerModel.decos.removeEventListener(
							CollectionEvent.COLLECTION_CHANGE, onDecoModelCollectionChange);
						layers.splice(layers.indexOf(layer), 1);
						_gameRenderer.layerModelDirty = true;
						break;
					}
				}
			} else if (ce.kind == CollectionEventKind.ADD) {
				// tenatively pushing an undo that we may pop if nothing changed
				pushUndo(UNDO_LAYERS);
				
				if (_lastRemovedLayer && (_lastRemovedLayer.tsid == changedLayerModel.tsid)) {
					// if we're adding a previously removed layer, it's a move
					layers.push(_lastRemovedLayer);
				} else {
					// otherwise we're creating a new layer
					layer = new Layer(changedLayerModel.tsid);
					layer.setSize(changedLayerModel.width, changedLayerModel.height);
					// will get computed automatically when the renderer updates the layer model
					//layer.z = changedLayerModel.z;
					layers.push(layer);
					somethingChanged = true;
					// select it
					_globals.selectedLayer = changedLayerModel;
				}
				changedLayerModel.decos.addEventListener(
					CollectionEvent.COLLECTION_CHANGE, onDecoModelCollectionChange);
				_lastRemovedLayer = null;
				
				// find the starting Z for the top layer
				// FGa   3 = dist. from top layer to middle ground
				// FGb   2 = FGa - 1
				// FGc   1 = FGa - 2
				// MG    0 = ...
				// BGb  -1
				// BGa  -2
				var nextZ:int = 0;
				for each (lm in _globals.location.layerModels.source) {
					if (lm.isMiddleground) break;
					nextZ++;
				}
				
				// now create a map of tsid -> z
				const map:Object = {};
				for each (var lm:LayerModel in _globals.location.layerModels.source)
					map[lm.tsid] = nextZ--;
				
				// assign new Z orders
				ll = layers.length;
				for (i=0; i<ll; i++) {
					layer = layers[int(i)];
					nextZ = map[layer.tsid];
					if (layer.z != nextZ) somethingChanged = true;
					layer.z = nextZ;
				}
				
				if (somethingChanged) {
					_gameRenderer.layerModelDirty = true;
				} else {
					// if nothing changed, then the undo we pushed is redundant
					popUndo(false);
				}
			}
		}
		
		private function onDecoModelCollectionChange(ce:CollectionEvent):void {
			//trace(ce.kind + ": " + ce.oldLocation + " -> " + ce.location);
			//for each (var o:Object in ce.items)
			//	trace(o);
				
			// we have another handler for update events
			if (_locationChanging || (ce.kind == CollectionEventKind.UPDATE)) return;
			
			const changedDecoModel:DecoModel = DecoModel(ce.items[0]);
			const changedLayerModel:LayerModel = changedDecoModel.layer;
			const decos:Vector.<Deco> = _location.getLayerById(changedLayerModel.tsid).decos;
			const layerRenderer:LayerRenderer = _gameRenderer.getLayerRendererByTSID(changedLayerModel.tsid);
			
			var i:int;
			var dl:int;
			var deco:Deco;
			
			// an add, delete, or move is occurring (a move is a delete + add)
			if (ce.kind == CollectionEventKind.REMOVE) {
				// find the associated Deco and remove it
				dl = decos.length;
				for (i=0; i<dl; i++) {
					deco = decos[int(i)];
					if (deco.tsid == changedDecoModel.tsid) {
						pushUndo(UNDO_REMOVE_DECO);
						deselect(changedDecoModel);
						// store this in case we re-add it later
						_lastRemovedDeco = deco;
						decos.splice(i, 1);
						layerRenderer.decosDirty = true;
						_gameRenderer.decoModelDirty = true;
						break;
					}
				}
			} else if (ce.kind == CollectionEventKind.ADD) {
				var somethingChanged:Boolean;
				
				// tenatively pushing an undo that we may pop if nothing changed
				pushUndo(UNDO_DECOS_CHANGED);
				
				if (_lastRemovedDeco && _lastRemovedDeco.tsid == changedDecoModel.tsid) {
					// if we're adding a previously removed deco, it's a move
					decos.push(_lastRemovedDeco);
					// clear the move operation
					_lastRemovedDeco = null;
				} else if (_newDecos.length > 0) {
					// we're placing new decos
					for each (deco in _newDecos) layerRenderer.layerData.decos.push(deco);
					_newDecos.length = 0;
					somethingChanged = true;
				}
				
				// create a map of tsid -> z
				// Da   3 = length of list
				// Db   2
				// Dc   1
				// Dd   0 = end of list 
				const map:Object = {};
				var nextZ:int = changedLayerModel.decos.length;
				for each (var dm:DecoModel in changedLayerModel.decos.source) {
					map[dm.tsid] = dm.z = --nextZ;
				}
				
				// assign new Z orders
				for each (deco in decos) {
					nextZ = map[deco.tsid];
					if (deco.z != nextZ) somethingChanged = true;
					deco.z = nextZ;
				}
				
				if (somethingChanged) {
					layerRenderer.decosDirty = true;
					_gameRenderer.decoModelDirty = true;
				} else {
					// if nothing changed, then the undo we pushed is redundant
					popUndo(false);
				}
			}
		}
		
		/** Handles DecoModel property updates */
		private function onDecoModelPropertyChange(pce:PropertyChangeEvent):void {
			if (!(pce.source is DecoModel)) return;
			
			// bail if the location is changing
			if (_locationChanging) return;
			
			//trace(pce.property + ": " + pce.oldValue + " -> " + pce.newValue);
			const property:String = String(pce.property);
			const dm:DecoModel = DecoModel(pce.source);
			
			const drc:IAbstractDecoRenderer = _gameRenderer.getAbstractDecoRendererByTsid(dm.tsid, dm.layer.tsid);
			if (!drc) return;
			const DO:DisplayObject = drc.getRenderer();
			const rendererModel:AbstractPositionableLocationEntity = drc.getModel();
			const deco:Deco = (rendererModel as Deco);
            const pl:PlatformLine = (rendererModel as PlatformLine);
			
			// pce.property will look like "1.2.propertyName"
			const newValue:Object = pce.newValue;
			const propertyName:String = property.slice(property.lastIndexOf('.')+1);
			switch (propertyName) {
			case 'animated':
			case 'standalone':
				pushUndo(UNDO_STANDALONE);
				if (deco) {
					deco[propertyName] = Boolean(newValue);
					// 'animated' and 'standalone' affect the Z value of the deco on the layer
					_gameRenderer.decoModelDirty = true;
					_gameRenderer.getLayerRendererByTSID(dm.layer.tsid).decosDirty = true;
					// and it might affect the renderer
					_gameRenderer.dirtyRenderers.push(drc);
				}
				break;
			case 'visible':
				DO.visible = Boolean(newValue);
				if (DO.visible) {
					// I did this originally so that when you made something
					// visible from the DecoPanel, it would get selected;
					// but it's terrible for performance when making all decos
					// visible and invisible. never again.
					//select(dm);
				} else {
					// hidden decos should not be selected
					deselect(dm);
				}
				break;
			case 'name':
				// look for naming collisions
				for each (var lm:LayerModel in _globals.location.layerModels.source) {
					for each (var decoModel:DecoModel in lm.decos.source) {
						if ((decoModel.name == newValue) && (dm != decoModel)) {
							const newName:String = TSIDGen.newTSID(dm.name);
							dm.name = newName;
							
							var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
							cdVO.title = 'Warning!!!'
							cdVO.txt = "There is another deco named '" + newValue + "', so I renamed it to '" + newName + "' for you.";
							cdVO.choices = [
								{value: true, label: 'Thanks, I guess'}
							];
							TSFrontController.instance.confirm(cdVO);
							
							// Flex's databinding when embedded in AS3 tends to be unidirectional,
							// in that we get notifications in LocoDecoSWFBridge, but Flex doesn't
							// generally see Bindable updates if LocoDecoSWFBridge updates a
							// property. So call this to cause Flex to notice something changed and
							// reload the dataProvider.
							loadCurrentLocationModel();
							break;
						}
					}
				}
				
				// update the friendly name
				pushUndo(UNDO_RENAME_DECO);
				rendererModel.name = dm.name;
				break;
			case 'x':
			case 'y':
				if (rendererModel.hasOwnProperty(propertyName)) {
					rendererModel[propertyName] = int(newValue);
					_gameRenderer.dirtyRenderers.push(drc);
				}
				break;
			case 'w':
			case 'h':
			case 'r':
			case 'h_flip':
				if (rendererModel.hasOwnProperty(propertyName)) {
					rendererModel[propertyName] = int(newValue);
					_gameRenderer.dirtyRenderers.push(drc);
				}
				break;
			case 'x1':
			case 'y1':
			case 'x2':
			case 'y2':
				// platforms
				// add the point you're trying to move to the update list
				var connectedPlatformLinePoints:Vector.<PlatformLinePoint> = new Vector.<PlatformLinePoint>();
				switch (propertyName) {
					case 'x1':
					case 'y1':
						connectedPlatformLinePoints.push(pl.start);
						break;
					case 'x2':
					case 'y2':
						connectedPlatformLinePoints.push(pl.end);
						break;
				}
				// dirty the renderer since we're gonna move it
				_gameRenderer.dirtyRenderers.push(drc);

				// if C is pressed, move all connected platforms too
				if (_keyboard.pressed(Keyboard.C)) {
					// find all connected platforms
					var platform_lines:Object = getGeoRendererVector(DecoModelTypes.PLATFORM_LINE_TYPE);
					for each (var otherPL:PlatformLine in platform_lines) {
						if (otherPL == pl) continue;
						switch (propertyName) {
							case 'x1':
							case 'y1':
								if (pl.start.equals(otherPL.start)) {
									connectedPlatformLinePoints.push(otherPL.start);
								} else if (pl.start.equals(otherPL.end)) {
									connectedPlatformLinePoints.push(otherPL.end);
								} else {
									continue;
								}
								break;
							case 'x2':
							case 'y2':
								if (pl.end.equals(otherPL.start)) {
									connectedPlatformLinePoints.push(otherPL.start);
								} else if (pl.end.equals(otherPL.end)) {
									connectedPlatformLinePoints.push(otherPL.end);
								} else {
									continue;
								}
								break;
						}
						// dirty the renderer since we're gonna move it
						_gameRenderer.dirtyRenderers.push(_gameRenderer.getAbstractDecoRendererByTsid(pl.tsid, LayerModel.middleground.tsid));
					}
					updateGeoRendererByDecoModelType(DecoModelTypes.PLATFORM_LINE_TYPE);
					dirtyGeoRendererModelByDecoModelType(DecoModelTypes.PLATFORM_LINE_TYPE);
				}
				
				// now actually update all the points
				for each (var plp:PlatformLinePoint in connectedPlatformLinePoints) {
					trace('moving plp');
					switch (propertyName) {
					case 'x1':
					case 'x2':
						plp.x = int(newValue);
						break;
					case 'y1':
					case 'y2':
						plp.y = int(newValue);
						break;
					}
				}
				break;
			// platform permeability
			case 'platform_pc_perm':
			case 'platform_item_perm':
				pushUndo(UNDO_PERMEABILITY);
				pl[propertyName] = newValue;
				_gameRenderer.dirtyRenderers.push(drc);
				break;
			// platform placement
			case 'is_for_placement':
			case 'placement_invoking_set':
			case 'placement_userdeco_set':
			case 'placement_plane_height':
				if (pl) {
					pushUndo(UNDO_PLACEMENT);
					pl[propertyName] = newValue;
					_gameRenderer.dirtyRenderers.push(drc);
				}
				break;
			// wall permeability
			case 'pc_perm':
			case 'item_perm':
				pushUndo(UNDO_PERMEABILITY);
				rendererModel[propertyName] = newValue;
				_gameRenderer.dirtyRenderers.push(drc);
				break;
			case 'sign_txt':
				if (deco) {
					pushUndo(UNDO_SIGN_TEXT);
					deco.sign_txt = (newValue as String);
					// 'sign_txt' affects the Z value of the deco on the layer
					_gameRenderer.decoModelDirty = true;
					_gameRenderer.getLayerRendererByTSID(dm.layer.tsid).decosDirty = true;
					// and it might affect the renderer
					_gameRenderer.dirtyRenderers.push(drc);
				}
				break;
			case 'sign_css_class':
				if (deco) {
					pushUndo(UNDO_SIGN_CSS);
					deco.sign_css_class = (newValue as String);
					_gameRenderer.dirtyRenderers.push(drc);
				}
				break;
			default:
				break;
			}
		}
		
		/** Gets all changes to LayerModel */
		private function onLayerModelPropertyChange(pce:PropertyChangeEvent):void {
			if (!(pce.source is LayerModel)) return;

			//trace(pce.property + ": " + pce.oldValue + " -> " + pce.newValue);
			
			// pce.property can be of two forms:
			// 1          (wholesale item replacement at index 1)
			// 1.property (property update at index 1)
			const property:String = String(pce.property);
			const dotPosition:int = property.indexOf('.');
			const propertyUpdate:Boolean = (dotPosition > -1);
			
			// bail if we're not updating an item's property or the location is changing
			if (!propertyUpdate || _locationChanging) return;
			
			const lm:LayerModel = LayerModel(pce.source);
			const tsid:String = lm.tsid;
			
			const layer:Layer = _location.getLayerById(tsid);
			
			var gm:GeoModel;
			var dm:DecoModel;
			
			// handle a property update
			const propertyName:String = property.slice(dotPosition+1);
			switch (propertyName) {
			case 'visible':
				// (de)select and change visibility of all decos on this layer
				for each (dm in lm.decos.source) {
					dm.visible = lm.visible;
					deselect(dm);
				}
				
				// change geo visiblity too if middleground
				if (lm.isMiddleground) {
					for each (gm in _globals.location.geometryModels.source) {
						gm.visible = (_globals.overlayPlatforms && lm.visible);
						deselect(gm);
					}
				}
				
				// update the model if not the middleground
				// middleground ignores is_hidden
				if (!lm.isMiddleground) {
					pushUndo(UNDO_LAYER_VISIBLE);
					layer.is_hidden = !lm.visible;
				}
				
				// update the renderer either way
				_gameRenderer.getLayerRendererByTSID(tsid).visible = lm.visible;
				break;
			case 'name':
				// update the friendly name
				pushUndo(UNDO_RENAME_LAYER);
				layer.name = String(pce.newValue);
				break;
			case 'width':
			case 'height': {
				const newVal:int = int(pce.newValue);
				if (propertyName == 'width') {
					if (newVal < _model.layoutModel.min_vp_w) {
						growl("Width must be at least " + _model.layoutModel.min_vp_w + "px!");
						// databinding will call this handler again
						lm.width = _model.layoutModel.min_vp_w;
						// since we're in a property change handler for this
						// property, we can't change it in the handler and
						// expect it to get heard. so force an update later.
						forceLayerModelUpdate();
						return;
					}
					pushUndo(UNDO_RESIZE_LAYER);
					layer.setSize(newVal, layer.h);
				} else {
					if (newVal < _model.layoutModel.min_vp_h) {
						growl("Height must be at least " + _model.layoutModel.min_vp_h + "px!");
						// databinding will call this handler again
						lm.height = _model.layoutModel.min_vp_h;
						// since we're in a property change handler for this
						// property, we can't change it in the handler and
						// expect it to get heard. so force an update later.
						forceLayerModelUpdate();
						return;
					}
					pushUndo(UNDO_RESIZE_LAYER);
					layer.setSize(layer.w, newVal);
				}
				
				// changing the dimensions of the sky requires a redraw
				if (lm == _globals.location.layerModels.getItemAt(_globals.location.layerModels.length-1)) {
					_gameRenderer.layerModelDirty = true;
				}
				
				if (layer is MiddleGroundLayer) {
					_location.l = -(Math.round(layer.w/2));
					_location.r = (layer.w + _location.l);
					_location.t = -(layer.h);
					_location.b = 0;
					_gameRenderer.layerModelDirty = true;
				}
				
				growl("Layer " + layer.name + " dimensions changed to " + layer.w + "x" + layer.h);
				TSFrontController.instance.getMainView().layerDimensionsChanged();
				break;
			}
			case 'blur':
			case 'saturation':
			case 'brightness':
			case 'contrast':
			case 'tintAmount':
				pushUndo(UNDO_FILTERS);
				layer[propertyName] = int(pce.newValue);
				_gameRenderer.getLayerRendererByTSID(layer.tsid).filtersDirty = true;
				_gameRenderer.filtersDirty = true;
				break;
			case 'tintColor':
				pushUndo(UNDO_FILTERS);
				layer[propertyName] = int(ColorModel(pce.newValue).color);
				_gameRenderer.getLayerRendererByTSID(layer.tsid).filtersDirty = true;
				_gameRenderer.filtersDirty = true;
				break;
			default:
				// skip (e.g. locodeco-internal props)
				break;
			}
		}
		
		private function onGeoModelCollectionChange(ce:CollectionEvent):void {
			//trace(ce.kind + ": " + ce.oldLocation + " -> " + ce.location);
			//for each (var o:Object in ce.items)
			//	trace(o);
			
			// we have another handler for update events
			if (_locationChanging || (ce.kind == CollectionEventKind.UPDATE)) return;
			
			const changedGeoModel:DecoModel = DecoModel(ce.items[0]);
			const geos:Object = getGeoRendererVector(changedGeoModel.type);
			
			var i:int;
			var dl:int;
			var geo:AbstractPositionableLocationEntity;
			
			// an add or delete is occurring; moves do not occur with geos
			// as they are always on the middleground and have no Z order
			if (ce.kind == CollectionEventKind.REMOVE) {
				pushUndo(UNDO_REMOVE_GEO);
				
				// find the associated geo renderer and remove it
				dl = geos.length;
				for (i=0; i<dl; i++) {
					geo = geos[int(i)];
					if (geo.tsid == changedGeoModel.tsid) {
						geos.splice(i, 1);
						updateGeoRendererByDecoModelType(changedGeoModel.type);
						_globals.location.geometryModels.source.sortOn('name');
						break;
					}
				}
			} else if (ce.kind == CollectionEventKind.ADD) {
				if (_newGeos.length > 0) {
					pushUndo(UNDO_GEO_CHANGED);
					// we're placing new geos
					for each (geo in _newGeos) geos.push(geo);
					_newGeos.length = 0;
					updateGeoRendererByDecoModelType(changedGeoModel.type);
					_globals.location.geometryModels.source.sortOn('name');
				}
			}
		}
		
		/**
		 * Get the Vector.<AbstractPositionableLocationEntity> from the
		 * middleground. This returns an Object, though, since AS3 doesn't let
		 * you assign it Vectors of dervived classes -- the classes must match,
		 * which is utter bullshit.
		 */
		private function getGeoRendererVector(type:String):Object {
			const mg:MiddleGroundLayer = _model.worldModel.location.mg;
			switch (type) {
				case DecoModelTypes.BOX_TYPE:
					return mg.boxes;
				case DecoModelTypes.DOOR_TYPE:
					return mg.doors;
				case DecoModelTypes.LADDER_TYPE:
					return mg.ladders;
				case DecoModelTypes.PLATFORM_LINE_TYPE:
					return mg.platform_lines;
				case DecoModelTypes.SIGNPOST_TYPE:
					return mg.signposts;
				case DecoModelTypes.TARGET_TYPE:
					return mg.targets;
				case DecoModelTypes.WALL_TYPE:
					return mg.walls;
			}
			return null;
		}
		
		/** Updates the active renderers, doesn't dirty their drawing */
		private function updateGeoRendererByDecoModelType(type:String):void {
			switch (type) {
				case DecoModelTypes.BOX_TYPE:
					_gameRenderer.locationView.middleGroundRenderer.boxModelDirty = true;
					break;
				case DecoModelTypes.DOOR_TYPE:
					_gameRenderer.locationView.middleGroundRenderer.doorModelDirty = true;
					break;
				case DecoModelTypes.LADDER_TYPE:
					_gameRenderer.locationView.middleGroundRenderer.ladderModelDirty = true;
					break;
				case DecoModelTypes.PLATFORM_LINE_TYPE:
					_gameRenderer.locationView.middleGroundRenderer.platformLineModelDirty = true;
					break;
				case DecoModelTypes.SIGNPOST_TYPE:
					_gameRenderer.locationView.middleGroundRenderer.signpostModelDirty = true;
                    break;
				case DecoModelTypes.TARGET_TYPE:
					_gameRenderer.locationView.middleGroundRenderer.targetModelDirty = true;
                    break;
				case DecoModelTypes.WALL_TYPE:
					_gameRenderer.locationView.middleGroundRenderer.wallModelDirty = true;
					break;
			}
		}
		
		/** Dirties the model's in the game renderer for redrawing */
		private function dirtyGeoRendererModelByDecoModelType(type:String):void {
			var drc:IAbstractDecoRenderer;
			for each (var gm:GeoModel in _globals.location.geometryModels.source) {
				if (gm.type == type) {
					drc = _gameRenderer.getAbstractDecoRendererByTsid(gm.tsid, gm.layer.tsid);
					if (drc) _gameRenderer.dirtyRenderers.push(drc);
				}
			}
		}
		
////////////////////////////////////////////////////////////////////////////////
//////// ENGINE EVENT HANDLERS /////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * When healing was performed outside LD, update our models and offer
		 * the opportunity to save.
		 */
		private function onGeometryHealed(_:*):void {
			if (_locationLoaded && !_locationChanging) loadCurrentLocationModel();
			// update the active renderers
			updateGeoRendererByDecoModelType(DecoModelTypes.PLATFORM_LINE_TYPE);
			// dirty their representation
			dirtyGeoRendererModelByDecoModelType(DecoModelTypes.PLATFORM_LINE_TYPE);
			// offer the opportunity to save
			growl('platforms healed');
			//TODO this may need to happen BEFORE platlines are healed
			pushUndo(UNDO_PLATFORM_HEAL);
		}
		
		private function onModelLocationChange(location:Location):void {
			// ignore if moving in the same loc or loc isn't ready
			if (!_initialized || !location || !location.isFullyLoaded) {
				return;
			}
			
			// on load, we're selecting geometry by default, don't
			deselectAll();
			
			_locationLoaded = false;
			_locationChanging = true;
			_location = location;
			
			// heal platformlines so we have the opportunity to save changes
			if (LocationPhysicsHealer.fixupPlatformLines(_location, true)) onGeometryHealed(null);
			
			// update ground-y
			if (_location.t <= 0) {
				_globals.location.groundYMax = _location.b;
				_globals.location.groundYMin = _location.t;
			} else {
				_globals.location.groundYMax = _location.t;
				_globals.location.groundYMin = _location.b;
			}
			_globals.location.groundY = _location.ground_y;
			
			// update gradients
			if (_location.hasGradient()) {
				_globals.location.topGradientColor.hex    = _location.gradient.top;
				_globals.location.bottomGradientColor.hex = _location.gradient.bottom;
			}
			
			// clear the layer model and decos
			for each (var lm:LayerModel in _globals.location.layerModels.source) {
				lm.decos.removeEventListener(
					CollectionEvent.COLLECTION_CHANGE, onDecoModelCollectionChange);
				lm.dispose();
			}
			_globals.location.layerModels.removeAll();
			
			// clear the geometry model
			for each (var gm:GeoModel in _globals.location.geometryModels.source) gm.dispose();
			_globals.location.geometryModels.removeAll();
			
			// sync the layer model with the the location's model from the server
			const layers:Vector.<Layer> = location.layers;
			var layer:Layer;
			var i:int = layers.length - 1;
			for(; i>=0; i--){
				layer = layers[int(i)];
				lm = new LayerModel(layer is MiddleGroundLayer);
				lm.visible = !layer.is_hidden;
				lm.decos.addEventListener(
					CollectionEvent.COLLECTION_CHANGE, onDecoModelCollectionChange);
				populateLayerModel(lm, layer);
				_globals.location.layerModels.addItem(lm);
				if (lm.isMiddleground) {
					// load geometry from the middleground
					populateGeoModel(lm, MiddleGroundLayer(layer));
					// select it by default
					_globals.selectedLayer = lm;
				}
			}
			
			_locationChanging = false;
			_locationLoaded = true;
			
			// set an initial undo point
			pushUndo(UNDO_REVERT);
			
			onEditingChange(_model.stateModel.editing);
		}
		
		/** Not active until the LD SWF is loaded and ready */
		private function onEditingChange(editing:Boolean):void {
			if (!_locationLoaded) {
				//
			} else if (editing) {
				deselectAll();
				
				StageBeacon.game_loop_sig.add(onEnterFrame);
				
				// track the mouse for deco selection
				StageBeacon.mouse_up_sig.add(onMouseUp);
				StageBeacon.mouse_down_sig.add(onMouseDown);
				StageBeacon.mouse_move_sig.add(onMouseMove);
				StageBeacon.cartesian_mouse_wheel.add(onMouseWheel);
				
				// keybindings!
				StageBeacon.key_down_sig.add(onKeyDown);
				StageBeacon.key_up_sig.add(onKeyUp);
				
				// hide stuff
				if (!_globals.overlayPCs) _gameRenderer.locationView.middleGroundRenderer.hidePCs();
				if (_globals.overlayItemstacks) {
					_gameRenderer.locationView.middleGroundRenderer.showItemstacks();
					_gameRenderer.locationView.middleGroundRenderer.showCTBoxesTemporarily();
				} else {
					_gameRenderer.locationView.middleGroundRenderer.hideItemstacks();
					_gameRenderer.locationView.middleGroundRenderer.hideCTBoxesTemporarily();
				}
				
				// show/hide stuff
				setGeometryVisibility(DecoModelTypes.WALL_TYPE, _globals.overlayPlatforms);
				setGeometryVisibility(DecoModelTypes.PLATFORM_LINE_TYPE, _globals.overlayPlatforms);
				setGeometryVisibility(DecoModelTypes.TARGET_TYPE, true);
				setGeometryVisibility(DecoModelTypes.BOX_TYPE, true);
				showHideInvisibleLadders();
				
				// show the map
				MiniMapView.instance.show();
			} else {
				// kill it in case it's open
				if (DisambiguationDialog.instance.hasFocus()) DisambiguationDialog.instance.end(true);
				if (_decoSelector.hasFocus()) _decoSelector.end(true);
				
				// reset this just in case we were in this mode
				_globals.groundYMode = false;
				
				StageBeacon.game_loop_sig.remove(onEnterFrame);
				
				// stop tracking mouse
				StageBeacon.mouse_up_sig.remove(onMouseUp);
				StageBeacon.mouse_down_sig.remove(onMouseDown);
				StageBeacon.mouse_move_sig.remove(onMouseMove);
				StageBeacon.cartesian_mouse_wheel.remove(onMouseWheel);
				
				// kill keybindings
				StageBeacon.key_down_sig.remove(onKeyDown);
				StageBeacon.key_up_sig.remove(onKeyUp);

				deselectAll();
				
				// make the middleground visible if it's hidden
				// (to preview how the renderer will render it -- never hidden)
				const mglm:LayerModel = LayerModel.middleground;
				if (!mglm.visible) {
					mglm.visible = true;
					// reset the visibility of all decos
					for each (var dm:DecoModel in mglm.decos.source) {
						dm.visible = true;
					}
				}
				
				// and geo too
				for each (var gm:GeoModel in _globals.location.geometryModels.source) {
					switch (gm.type) {
						case DecoModelTypes.WALL_TYPE:
						case DecoModelTypes.PLATFORM_LINE_TYPE:
							gm.visible = !_model.stateModel.hide_platforms;
							continue;
						case DecoModelTypes.BOX_TYPE:
						case DecoModelTypes.TARGET_TYPE:
							gm.visible = false;
							continue;
						default:
							gm.visible = true;
							continue;
					}
				}
				
				// show/hide stuff
				_gameRenderer.locationView.middleGroundRenderer.showPCs();
				_gameRenderer.locationView.middleGroundRenderer.showItemstacks();
				_gameRenderer.locationView.middleGroundRenderer.maybeShowCTBoxes();
				showHideInvisibleLadders();
				
				// maybe show and reload the map
				TSFrontController.instance.changeMiniMapVisibility();
				TSFrontController.instance.changeHubMapVisibility();
				//TSFrontController.instance.resnapMiniMap();
			}
		}
		
		// called when TSFrontController is saving changes to GS
		private function onSavingChanges(saving:Boolean):void {
			//
		}
		
		private function onEditingUnsavedChanges(unsaved:Boolean):void {
			//
		}
		
////////////////////////////////////////////////////////////////////////////////
//////// SELECTION /////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
		
		private function attachControlPointsToDecoRenderer(dm:DecoModel, drc:IAbstractDecoRenderer):void {
			// choose correct type of control points
			var cp:AbstractControlPoints;
			if (dm.type == DecoModelTypes.TARGET_TYPE) {
				cp = new MoveableControlPoints();
			} else if (dm.type == DecoModelTypes.PLATFORM_LINE_TYPE) {
				cp = new PlatformControlPoints();
			} else if (dm.type == DecoModelTypes.LADDER_TYPE) {
				cp = new LadderControlPoints();
			} else if (dm.type == DecoModelTypes.WALL_TYPE) {
				cp = new WallControlPoints();
			} else {
				cp = new ResizeableControlPoints();
			}
			
			// stage must be set before target
			cp.stage  = _controlPoints.stage;
			cp.target = new DecoModelDisplayObjectProxy(dm, drc.getRenderer())
			
			// attach the control points
			_controlPoints.registerControlPoint(drc, cp);
		}
		
		/**
		 * algorithm: given the decos are assumed to be sorted in Z order,
		 * choose the first geo, followed by deco, in that list if none of the
		 * other decos are currently selected, unless that deco is >=80% as big
		 * as the layer it's on and that layer is not selected.
		 */
		private function chooseMostLikelyDecoForSelection(decos:Vector.<DecoModelRenderer>):DecoModelRenderer {
			var dm:DecoModel;
			var lm:LayerModel;
			var mostLikely:DecoModelRenderer;
			for each (var deco:DecoModelRenderer in decos) {
				dm = deco.dm;
				lm = dm.layer;
				
				if (_globals.isSelected(dm)) {
					// no matter what, a selected deco wins out over any others
					mostLikely = deco;
					break;
				} else if (mostLikely) {
					if (mostLikely.dm is GeoModel) {
						// if a geo is the most likely so far, we're done
					} else if (dm is GeoModel) {
						// if the most likely is a deco but there's a geo at the
						// same spot, select the geo
						mostLikely = deco;
					} else {
						// do nothing, we already selected a candidate
					}
				} else if (((dm.w * dm.h) / (lm.width * lm.height)) >= 0.8) {
					// if the dims of the deco are nearly the size of the layer
					// don't select it unless that layer is explicitely selected
					if (_globals.selectedLayer == dm.layer) {
						mostLikely = deco;
					}
				} else {
					mostLikely = deco;
				}
			}
			return mostLikely;
		}

		/** Find all decos immediately under mouse in sorted Z order */
		private function getDecosUnderCursor():Vector.<DecoModelRenderer> {
			const decos:Vector.<DecoModelRenderer> = new Vector.<DecoModelRenderer>();
			
			// NOTE: Using _stage is suboptimal, but the object list is
			// unreliable and inaccurate (somehow) when using _gameRenderer
			const objs:Array = _stage.getObjectsUnderPoint(StageBeacon.stage_mouse_pt);
			const objsSeen:Dictionary = new Dictionary();
			
			var dmr:DecoModelRenderer;
			var dmrRight:DecoModelRenderer;
			var i:int;
			
			//trace('======');
			var tsid:String;
			var p:DisplayObject;
			var cp:AbstractControlPoints;
			var proxiedDeco:DecoModelDisplayObjectProxy;
			for each (var obj:Object in objs) {
				//trace('1:',obj,obj is IDecoRendererContainer);
				p = (obj as DisplayObject);
				// this is not efficient, but may be the only way to do it
				while (p) {
					// if mouse is over ControlPoints, short circuit to the tracked object
					// (if we see the tracked object again later, it'll already be in objsSeen)
					cp = (p as AbstractControlPoints);
					if (cp) {
						proxiedDeco = (cp.target as DecoModelDisplayObjectProxy);
						if (proxiedDeco) {
							p = proxiedDeco.displayObject;
						}
					}
					
					// skip objects and their parents that we've seen
					// (getObjectsUnderPoint may return multiple children of the same deco)
					if (p in objsSeen) break;
					objsSeen[p] = true;
					//trace('\t',p,p is IDecoRendererContainer);
					
					//TODO this is fragile
					// find a top-level deco in the renderer
					// (Doors CONTAIN ILDOs; we want to find the door)
					if ((p is IAbstractDecoRenderer) && (p.parent is LayerRenderer)) {
						dmr = new DecoModelRenderer();
						dmr.lr = (p.parent as LayerRenderer);
						dmr.drc = (p as IAbstractDecoRenderer);
						tsid = IAbstractDecoRenderer(p).getModel().tsid;
						dmr.dm = _globals.location.getDecoModel(tsid, dmr.lr.tsid);
						if (!dmr.dm) {
							// should never get here, means model is out of sync with renderer
							CONFIG::debugging {
								Console.warn("getDecosUnderCursor: Couldn't find tsid: '" + tsid + "'");
							}
							break;
						}
						
						// skip non-geos when onlySelectGeos is enabled
						if (_globals.onlySelectGeos && !(dmr.dm is GeoModel)) break;
						
						// when C is pressed, restrict to current selected layer(s)
						if (!_keyboard.pressed(Keyboard.C) || (dmr.dm.layer == _globals.selectedLayer)) {
							//trace('\t\t',p);
							// insertion sort on Z depth; geometry is always on top
							
							// geometry is always on top
							if (dmr.dm is GeoModel) {
								// however platlines are always on top of other geo
								if (dmr.dm.type == DecoModelTypes.PLATFORM_LINE_TYPE) {
									decos.unshift(dmr);
								} else {
									// stick other geo below platlines
									// 'i' represents the LEFT of the deco to place the new one at
									for (i=0; i<decos.length; i++) {
										dmrRight = DecoModelRenderer(decos[int(i)]);
										if (dmrRight.dm.type == DecoModelTypes.PLATFORM_LINE_TYPE) {
											continue;
										}
										break;
									}
									decos.splice(i, 0, dmr);
								}
							} else {
								// 'i' represents the LEFT of the deco to place the new one at
								for (i=0; i<decos.length; i++) {
									dmrRight = DecoModelRenderer(decos[int(i)]);
									// if the current deco is on the same layer, then compare Zs
									if (dmr.dm.layer.z == dmrRight.dm.layer.z) {
										if (dmr.dm.z > dmrRight.dm.z) break;
									} else if (dmr.dm.layer.z > dmrRight.dm.layer.z) {
										break;
									}
								}
								decos.splice(i, 0, dmr);
							}
						}
						break;
					}
					p = p.parent;
				}
			}
			return decos;
		}
		
		/**
		 * Returns true when the selection was successful,
		 * and false when it failed but has been queued.
		 */
		public function select(dm:DecoModel, deselectExisting:Boolean = true, startMove:Boolean = false, startEndHandleMove:Boolean = false):Boolean {
			if (deselectExisting) deselectAll();

			// don't select when the layer is hidden or when not allowed,
			// but don't fail it (selection didn't happen ... successfully)
			// since it probably shouldn't be queued for when the layer
			// becomes visible (no workflows would make this make sense)
			if (!dm.layer.visible) return true;
			if (_globals.onlySelectGeos && !(dm is GeoModel)) return true;
			
			// check if it's already selected
			if (_globals.isSelected(dm)) return true;

			// update the locodeco model in case the game's model changed
			const dr:IAbstractDecoRenderer = _gameRenderer.getAbstractDecoRendererByTsid(dm.tsid, dm.layer.tsid);
			if (dr) dm.updateModel(dr.getModel());
			
			// start a new multiselect
			if (_globals.isSingleSelectionActive) {
				const tmp:DecoModel = _globals.selectedDeco;
				_disableNewUndos = true;
				_globals.selectedDeco = null;
				_disableNewUndos = false;
				_globals.multiSelectedDecos.addItem(tmp);
				_globals.multiSelectedDecos.addItem(dm);
				return true;
			}
			
			// add to existing multiselect
			if (_globals.isMultiSelectionActive) {
				// databinding will handle the actual work of selection
				_globals.multiSelectedDecos.addItem(dm);
				return true;
			}
			
			// regular single selection
			// if the ADR exists, select immediately
			// (it may not exist or be loaded, okay because we render a red box)
			if (dr) {
				// important to select the layer first THEN deco on that layer
				// so databinding fills the DecoPanel with decos first
				_globals.selectedLayer = dm.layer;
				_globals.selectedDeco  = dm;
				if (StageBeacon.mouseIsDown) {
					// this will allow you to mouse down on a new deco and start dragging immediately
					if (startMove) _controlPoints.startMove();
					// on platforms and walls, start the mouse dragging the end point
					if (startEndHandleMove) _controlPoints.startEndHandleMove();
				}
				return true;
			} else if (_pendingSelection.indexOf(dm) == -1) {
				// the deco hasn't loaded yet; it will get selected when it finishes rendering
				// (occurs when copy-pasting/adding new decos and *immediately* selecting)
				_pendingSelection.push(dm);
				_startMoveOnPendingSelection = startMove;
				_startEndHandleMoveOnPendingSelection = startEndHandleMove;
			}
			
			return false;
		}

		private function deselect(deco:DecoModel):void {
			if (_globals.isSingleSelectionActive && (deco == _globals.selectedDeco)) {
				_globals.selectedDeco = null;
			} else if (_globals.isMultiSelectionActive) {
				_globals.multiSelectedDecos.removeItem(deco);
			} else if (_pendingSelection.indexOf(deco) != -1) {
				_pendingSelection.splice(_pendingSelection.indexOf(deco), 1);
				_startMoveOnPendingSelection = false;
				_startEndHandleMoveOnPendingSelection = false;
			}
		}
		
		private function selectAll(selectedLayerOnly:Boolean = true):void {
			deselectAll();
			for each (var layer:LayerModel in _globals.location.layerModels.source) {
				if (!selectedLayerOnly || (_globals.selectedLayer == layer)) {
					for each (var deco:DecoModel in layer.decos.source) {
						select(deco, false);
					}
					
					// handle geometry
					if (layer.isMiddleground) {
						for each (var geo:GeoModel in _globals.location.geometryModels.source) {
							select(geo, false);
						}
					}
				}
			}
		}
		
		private function deselectAll():void {
			_pendingSelection.length = 0;
			_startMoveOnPendingSelection = false;
			_startEndHandleMoveOnPendingSelection = false;
			
			// leave the current layer selected
			//_globals.selectedLayer = null;
			_globals.selectedDeco = null;
			clearMultiSelection();
		}
		
		private function clearMultiSelection():void {
			// important to remove each item one at a time because
			// databinding will send a CollectionEvent.REMOVE for each one;
			// otherwise a CollectionEventKind.RESET is sent, which is more
			// complicated to handle in multiSelectedDecosPropertyChangeHandler
			while (_globals.multiSelectedDecos.length) _globals.multiSelectedDecos.removeItemAt(0);
		}
		
////////////////////////////////////////////////////////////////////////////////
//////// CUT COPY PASTE ////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
		
		private function cut(e:Event = null):void {
			copy();
			// (concat() because we may modify the array each iteration)
			for each (var dm:DecoModel in _globals.selectedDecos.concat()) {
				if (dm is GeoModel) {
					_globals.location.geometryModels.removeItem(dm);
				} else {
					dm.removeFromLayer();
				}
			}
		}
		
		private function copy(e:Event = null):void {
			if (_globals.isSelectionActive) {
				const copyBuffer:Vector.<Object> = new Vector.<Object>();
				var decoAMF:Object;
				var drc:IAbstractDecoRenderer;
				
				// sort the decos by Z depth so decos are pasted correctly
				// (the buffer is in order of shift-clicking decos, not Z order)
				_globals.selectedDecos.sort(function (left:DecoModel, right:DecoModel):Number {
					// the list is composed of both geometry and decos
					if (left is GeoModel) {
						if (right is GeoModel) {
							// lexicographic ordering
							return (left.tsid < right.tsid) ? -1 : 1;
						} else {
							// left is geo, right is deco; geos come after decos
							return 1;
						}
					} else if (right is GeoModel) {
						// left is deco, right is geo; geos come after decos
						return -1;
					} else if (left.layer.z == right.layer.z) {
						if (left.z > right.z) {
							return -1;
						} else {
							return 1;
						}
					} else if (left.layer.z > right.layer.z) {
						return -1;
					} else {
						return 1;
					}
				});

				for each (var dm:DecoModel in _globals.selectedDecos.concat()) {
					drc = _gameRenderer.getAbstractDecoRendererByTsid(dm.tsid, dm.layer.tsid);
					decoAMF = drc.getModel().AMF();
					if (dm.type == DecoModelTypes.SIGNPOST_TYPE) {
						// quarter_info is not serialized in SignPost.AMF since
						// the GS populates it dynamically, but must be copied in LD
						var qi:QuarterInfo = SignPost(drc.getModel()).client::quarter_info;
						if (qi) decoAMF.quarter_info = qi;
					}
					// temporary properties for pasting purposes:
					decoAMF.__layerTSID = dm.layer.tsid;
					decoAMF.__modelType = dm.type;
					copyBuffer.push(decoAMF);
				}
				LocalStorage.instance.setGlobalData(LocalStorage.LOCODECO_CLIPBOARD, copyBuffer, false);
			}
		}
		
		private function paste(e:Event = null):void {
			const copyBuffer:Vector.<Object> = (LocalStorage.instance.getGlobalData(LocalStorage.LOCODECO_CLIPBOARD) as Vector.<Object>);
			if (copyBuffer && copyBuffer.length) {
				var decoAMF:Object;
				
				// determine which layer we're pasting to based on the selected
				// layer primarily, falling back on the first deco's layer TSID
				var lm:LayerModel = _globals.selectedLayer;
				if (!lm) {
					// if there is no selected layer, use the layer from the deco buffer
					lm = _globals.location.getLayerModel(copyBuffer[0].__layerTSID);
					// if the original layer has been removed, we can't do anything more
					if (!lm) return;
				}
				
				const selectedLayerDecos:ArrayList = lm.decos;
				const selectedLayer:Layer = _location.getLayerById(lm.tsid);
				const mgLayer:MiddleGroundLayer = _model.worldModel.location.mg;
				
				// default: put on top of all decos on current layer
				// if there's an existing selection on the same layer,
				// put it above that
				var targetLayerIndex:int = 0;
				if (_globals.isSingleSelectionADeco && (_globals.selectedDeco.layer == lm)) {
					// put above selected deco
					targetLayerIndex = selectedLayerDecos.getItemIndex(_globals.selectedDeco);
				}
				
				// clear the selection; we'll be selecting all pasted decos
				deselectAll();
				
				var globalPoint:Point;
				var originatingLayer:Layer;
				
				// find the centroid of of the quad hull of all the decos
				// (i.e. the middle point of all the decos)
				// this will be used for pasting relative to the screen center
				const globalCentroid:Point = new Point();
				const rects:Vector.<Rectangle> = new Vector.<Rectangle>();
				for each (decoAMF in copyBuffer) {
					originatingLayer = _location.getLayerById(decoAMF.__layerTSID);
					if (!originatingLayer) originatingLayer = _location.getLayerById(lm.tsid);
					// translate the deco's coordinates to global coordinates to account for parallax
					// since you may have selected decos across on multiple layers;
					// platformlines don't have x and y, use the start point
					if (decoAMF.__modelType == DecoModelTypes.PLATFORM_LINE_TYPE) {
						// create a rectangle out of the start/end points
						var leftX:int   = ((decoAMF.start.x < decoAMF.end.x) ? decoAMF.start.x : decoAMF.end.x);
						var rightX:int  = ((decoAMF.start.x < decoAMF.end.x) ? decoAMF.end.x   : decoAMF.start.x);
						var topY:int    = ((decoAMF.start.y < decoAMF.end.y) ? decoAMF.start.y : decoAMF.end.y);
						var bottomY:int = ((decoAMF.start.y < decoAMF.end.y) ? decoAMF.end.y   : decoAMF.start.y);
						var w:int = Math.min(1, (rightX - leftX));
						var h:int = Math.min(1, (bottomY - topY));
						globalPoint = _gameRenderer.translateLayerLocalToGlobal(originatingLayer, leftX, topY);
						rects.push(new Rectangle(globalPoint.x, globalPoint.y, w, h));
					} else {
						globalPoint = _gameRenderer.translateLayerLocalToGlobal(originatingLayer, decoAMF.x, decoAMF.y);
						// shift the top-left registration to bottom-middle
						rects.push(new Rectangle(globalPoint.x - decoAMF.w/2, globalPoint.y - decoAMF.h, decoAMF.w, decoAMF.h));
					}
				}
				
				// average all the points in the hull to find the centroid
				const rectHull:Rectangle = QuadHull.rectHull(rects);
				globalCentroid.x = rectHull.x + Math.round(rectHull.width  / 2);
				globalCentroid.y = rectHull.y + Math.round(rectHull.height / 2);
				
				var delta:Point;
				var dm:DecoModel;
				var isDeco:Boolean;
				var newModel:AbstractPositionableLocationEntity;
				for each (decoAMF in copyBuffer) {
					newModel = ModelFactory.newLocationModelFromAMF(decoAMF.__modelType, decoAMF);
					isDeco = (newModel is Deco);
					if (isDeco) {
						_newDecos.push(newModel);
					} else {
						_newGeos.push(newModel);
					}
					
					// determine paste location relative to target layer
					var localPoint:Point;
					originatingLayer = _location.getLayerById(decoAMF.__layerTSID);
					if (!originatingLayer) originatingLayer = _location.getLayerById(lm.tsid);
					if (_keyboard.pressed(Keyboard.SHIFT)) {
						// default pastes at the original location
						globalPoint = _gameRenderer.translateLayerLocalToGlobal(originatingLayer, newModel.x, newModel.y);
						if (isDeco) {
							localPoint = _gameRenderer.translateLayerGlobalToLocal(selectedLayer, globalPoint.x, globalPoint.y);
						} else {
							localPoint = _gameRenderer.translateLayerGlobalToLocal(mgLayer, globalPoint.x, globalPoint.y);
						}
					} else {
						// center all the decos in the viewport relative to their original positions
						// put the original deco's coordinates into global space
						globalPoint = _gameRenderer.translateLayerLocalToGlobal(originatingLayer, newModel.x, newModel.y);
						// put the location center into global coordinates
						delta = _gameRenderer.translateLocationCoordsToGlobal(_model.layoutModel.loc_cur_x, _model.layoutModel.loc_cur_y);
						// now everything is in global space
						// offset the center by the centroid to get a delta
						delta.x -= globalCentroid.x;
						delta.y -= globalCentroid.y;
						// now add the delta to the original location
						globalPoint.x += delta.x;
						globalPoint.y += delta.y;
						// and convert it back to local coordinates on the new layer
						if (isDeco) {
							localPoint = _gameRenderer.translateLayerGlobalToLocal(selectedLayer, globalPoint.x, globalPoint.y);
						} else {
							localPoint = _gameRenderer.translateLayerGlobalToLocal(mgLayer, globalPoint.x, globalPoint.y);
						}
					}
					if (decoAMF.__modelType == DecoModelTypes.PLATFORM_LINE_TYPE) {
						// PlatformLines don't have x and y, update the start/end
						var pl:PlatformLine = PlatformLine(newModel);
						const deltaX:Number = (localPoint.x - pl.start.x);
						const deltaY:Number = (localPoint.y - pl.start.y);
						pl.start.x = localPoint.x;
						pl.start.y = localPoint.y;
						pl.end.x   += deltaX;
						pl.end.y   += deltaY;
					} else {
						newModel.x = localPoint.x;
						newModel.y = localPoint.y;
					}
					
					// update our model
					// dirtying the renderers will happen via databinding on the ArrayLists below
					if (isDeco) {
						dm = ModelFactory.newDecoModelFromLocationModel(newModel, lm);
						selectedLayerDecos.addItemAt(dm, targetLayerIndex);
						// increment this in case there are more decos to place
						targetLayerIndex++;
					} else {
						// geometry
						dm = ModelFactory.newDecoModelFromLocationModel(newModel, LayerModel.middleground);
						_globals.location.geometryModels.addItem(dm);
					}
					
					// add the pasted objects to a selection
					select(dm, false);
				}
			}
		}
		
////////////////////////////////////////////////////////////////////////////////
//////// UTILITIES /////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
		
		/** Sets all geometry elements' visiblity of a certain DecoModelType */
		private function setGeometryVisibility(decoModelType:String, visible:Boolean):void {
			for each (var gm:GeoModel in _globals.location.geometryModels.source) {
				if (gm.type == decoModelType) {
					// make sure databinding ALWAYS fires
					if (gm.visible == visible) gm.visible = !gm.visible;
					gm.visible = visible;
					if (!visible) deselect(gm);
				}
			}
		}
		
		private function enableHighlighting():void {
			_gameRenderer.disableHighlighting = false;
			var lr:LayerRenderer;
			for each (var lm:LayerModel in _globals.location.layerModels.source) {
				// it's possible our model will be out of sync until the next render
				if ((lr = _gameRenderer.getLayerRendererByTSID(lm.tsid))) lr.filtersDirty = true;
			}
			_gameRenderer.filtersDirty = true;
		}
		
		private function disableHighlighting():void {
			_gameRenderer.disableHighlighting = true;
			var lr:LayerRenderer;
			for each (var lm:LayerModel in _globals.location.layerModels.source) {
				// it's possible our model will be out of sync until the next render
				if ((lr = _gameRenderer.getLayerRendererByTSID(lm.tsid))) lr.filtersDirty = true;
			}
			_gameRenderer.filtersDirty = true;
		}
		
		private function highlight(dr:IAbstractDecoRenderer, lr:LayerRenderer):void {
			if (_globals.overlaySelectionGlow && !dr.highlight) {
				dr.highlight = true;
				lr.filtersDirty = true;
				_gameRenderer.filtersDirty = true;
			}
		}
		
		private function unhighlight(dr:IAbstractDecoRenderer, lr:LayerRenderer):void {
			// the dr might have been deleted
			if (dr && dr.highlight) {
				dr.highlight = false;
				lr.filtersDirty = true;
				_gameRenderer.filtersDirty = true;
			}
		}
		
		private function unhighlightLastHighlight():void {
			if (_lastHighlightedDeco) {
				_gameRenderer.useHandCursor = false;
				_gameRenderer.buttonMode = false;
				// remove the last highlight if:
				// * we're not supposed to glow the selection
				// * we are supposed to glow the selection AND
				//   the last highlight is currently selected
				//   (it will get removed when deselected)
				if (!_globals.overlaySelectionGlow || !_globals.isSelected(_lastHighlightedDeco.dm)) {
					unhighlight(_lastHighlightedDeco.drc, _lastHighlightedDeco.lr);
					_lastHighlightedDeco = null;
				}
			}
		}
		
		private function growl(txt:String):void {
			_model.activityModel.growl_message = txt;
		}
		
		private function pushUndo(type:String):void {
			if (!_disableNewUndos) TSFrontController.instance.pushUndo(type);
		}
		
		private function popUndo(loadUndo:Boolean):void {
			TSFrontController.instance.popUndo(loadUndo);
		}
		
		/** Tells the layer model and UI to refresh everything */
		private function forceLayerModelUpdate():void {
			var event:CollectionEvent = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE);
			event.kind = CollectionEventKind.RESET;
			_globals.location.layerModels.dispatchEvent(event);
		}
		
		private function populateLayerModel(layerModel:LayerModel, layer:Layer):void {
			// boring shit!
			layerModel.tsid = layer.tsid;
			layerModel.name = layer.name;
			layerModel.width = layer.w;
			layerModel.height = layer.h;
			
			// filters!
			layerModel.blur = layer.blur;
			layerModel.contrast = layer.contrast;
			layerModel.brightness = layer.brightness;
			layerModel.saturation = layer.saturation;
			layerModel.tintAmount = layer.tintAmount;
			layerModel.tintColor.color = layer.tintColor;
			
			// decos!
			const decos:ArrayList = layerModel.decos;
			var dm:DecoModel;
			for each (var deco:Deco in layer.decos) {
				dm = ModelFactory.newDecoModel(deco, layerModel);
				dm.visible = layerModel.visible;
				decos.addItem(dm);
			}
			// reverse the sorting of layer.decos to be FRONT/TOP to BACK/BOTTOM
			decos.source.sortOn('z', Array.DESCENDING | Array.NUMERIC);
		}
		
		private function populateGeoModel(mglm:LayerModel, mg:MiddleGroundLayer):void {
			const geos:ArrayList = _globals.location.geometryModels;
			
			var gm:GeoModel;
			
			// boxes
			for each (var box:Box in mg.boxes) {
				gm = ModelFactory.newBoxModel(box, mglm);
				geos.addItem(gm);
			}
			
			// doors
			for each (var door:Door in mg.doors) {
				geos.addItem(ModelFactory.newDoorModel(door, mglm));
			}
			
			// ladders
			for each (var ladder:Ladder in mg.ladders) {
				gm = ModelFactory.newLadderModel(ladder, mglm);
				gm.visible = _globals.overlayPlatforms;
				geos.addItem(gm);
			}
			
			// platformlines
			for each (var platformLine:PlatformLine in mg.platform_lines) {
				gm = ModelFactory.newPlatformLineModel(platformLine, mglm);
				gm.visible = _globals.overlayPlatforms;
				geos.addItem(gm);
			}
			
			// signposts
			for each (var signpost:SignPost in mg.signposts) {
				geos.addItem(ModelFactory.newSignpostModel(signpost, mglm));
			}
			
			// targets
			for each (var target:Target in mg.targets) {
				gm = ModelFactory.newTargetModel(target, mglm);
				geos.addItem(gm);
			}
			
			// walls
			for each (var wall:Wall in mg.walls) {
				gm = ModelFactory.newWallModel(wall, mglm);
				gm.visible = _globals.overlayPlatforms;
				geos.addItem(gm);
			}
			
			geos.source.sortOn('name');
		}
		
		private function newPlatformLineUnderMouse():GeoModel {
			const is_for_placement:Boolean = _keyboard.pressed(Keyboard.SHIFT);
			
			// try to snap the start point to other platforms
			const pt:Point = _gameRenderer.getMouseXYinMiddleground();
			const snappedPoint:Object = LocationPhysicsHealer.snapPointToPlatformLinesAndWalls(pt, is_for_placement, _location.mg.platform_lines, _location.mg.walls);
			const pl:PlatformLine = PlatformLine(ModelFactory.newLocationModelFromAMF(
				DecoModelTypes.PLATFORM_LINE_TYPE,
				{
					start: {
						x: snappedPoint.x,
						y: snappedPoint.y
					},
					end: {
						x: pt.x,
						y: pt.y
					}
				}));
			
			if (is_for_placement) {
				pl.is_for_placement = true;
				pl.placement_invoking_set = 'all';
				// if there were a default userdeco set, we'd do it here
				pl.placement_userdeco_set = null;
				// soft as a baby's bottom
				pl.platform_pc_perm = 0;
				pl.platform_item_perm = 0;
			} else {
				// hard on top, soft on the bottom (floor)
				// unless CONTROL is pressed, in which case a roof
				pl.platform_pc_perm = (_keyboard.pressed(Keyboard.CONTROL) ? 1 : -1);
				pl.platform_item_perm = (_keyboard.pressed(Keyboard.CONTROL) ? 1 : -1);
			}
			
			// queue it for adding to the renderer
			_newGeos.push(pl);
			
			// build a local model for it
			_lastSelectionWasANewModel = true;
			const gm:GeoModel = GeoModel(ModelFactory.newDecoModelFromLocationModel(pl, LayerModel.middleground));
			// databinding will take care of dirtying the renderer
			_globals.location.geometryModels.addItem(gm);
			
			return gm;
		}
		
		private function newWallUnderMouse():GeoModel {
			const w:Wall = Wall(ModelFactory.newLocationModelFromAMF(
				DecoModelTypes.WALL_TYPE,
				{
					x: _gameRenderer.getMouseXinMiddleground(),
					y: _gameRenderer.getMouseYinMiddleground(),
					h: 0,
					// hard on left, hard on the right
					pc_perm: null,
					item_perm: null
				}));
			// queue it for adding to the renderer
			_newGeos.push(w);
			
			// build a local model for it
			_lastSelectionWasANewModel = true;
			const gm:GeoModel = ModelFactory.newWallModel(w, LayerModel.middleground);
			// databinding will take care of dirtying the renderer
			_globals.location.geometryModels.addItem(gm);
			
			return gm;
		}
		
		private function newLadderUnderMouse():GeoModel {
			const l:Ladder = Ladder(ModelFactory.newLocationModelFromAMF(
				DecoModelTypes.LADDER_TYPE,
				{
					x: _gameRenderer.getMouseXinMiddleground(),
					y: _gameRenderer.getMouseYinMiddleground(),
					h: 0
				}));
			// queue it for adding to the renderer
			_newGeos.push(l);
			
			// build a local model for it
			_lastSelectionWasANewModel = true;
			const gm:GeoModel = ModelFactory.newLadderModel(l, LayerModel.middleground);
			// databinding will take care of dirtying the renderer
			_globals.location.geometryModels.addItem(gm);
			
			return gm;
		}
		
		/**
		 * Ladders with decos are always visible; invisible ladders are drawn
		 * when editing via IDecoRendererContainer.reloadModel().
		 * You don't want to modify visible since they must always be visible.
		 */
		private function showHideInvisibleLadders():void {
			for each (var gm:GeoModel in _globals.location.geometryModels.source) {
				if (gm.type == DecoModelTypes.LADDER_TYPE) {
					var ladderRenderer:IAbstractDecoRenderer = _gameRenderer.getAbstractDecoRendererByTsid(gm.tsid, gm.layer.tsid);
					if (ladderRenderer) {
						ladderRenderer.syncRendererWithModel();
					}
				}
			}
		}
		
		/** Returns whether any changes were undone */
		private function undoUncommittedChanges():Boolean {
			// pressing escape just after creating a new object should remove it
			if (_globals.isSingleSelectionActive && _lastSelectionWasANewModel) {
				_disableNewUndos = true;
				_globals.selectedDeco.removeFromLayer();
				_globals.selectedDeco = null;
				_disableNewUndos = false;
				return true;
			}
			
			var changes:Boolean = false;
			
			// undo all deco/geo changes since last selection was made
			for each (var dm:DecoModel in _globals.selectedDecos.concat()) {
				if (dm.changesSinceSavedState()) {
					changes = true;
					dm.loadSavedState();
				}
			}
			
			return changes;
		}
	}
}

import com.tinyspeck.engine.view.renderer.IAbstractDecoRenderer;
import com.tinyspeck.engine.view.renderer.LayerRenderer;

import locodeco.models.DecoModel;

class DecoModelRenderer {
	public var dm:DecoModel;
	public var drc:IAbstractDecoRenderer;
	public var lr:LayerRenderer;
}
