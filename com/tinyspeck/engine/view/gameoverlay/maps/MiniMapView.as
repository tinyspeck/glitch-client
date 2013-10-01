package com.tinyspeck.engine.view.gameoverlay.maps {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.admin.locodeco.LocoDecoSWFBridge;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.ContiguousPlatformLineSet;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.location.LocationConnection;
	import com.tinyspeck.engine.data.location.PlatformLine;
	import com.tinyspeck.engine.data.location.QuarterInfo;
	import com.tinyspeck.engine.data.location.SignPost;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.util.geom.Range;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocPcAddDelConsumer;
	import com.tinyspeck.engine.view.renderer.interfaces.ILocPcUpdateConsumer;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Checkbox;
	import com.tinyspeck.engine.view.ui.map.GpsUI;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.Timer;
	
	CONFIG::god { import flash.ui.Mouse; }
	CONFIG::god { import flash.ui.MouseCursor; }
	
	public class MiniMapView extends TSSpriteWithModel implements IMoveListener, ILocPcAddDelConsumer, ILocPcUpdateConsumer, ITipProvider {
		/* singleton boilerplate */
		public static const instance:MiniMapView = new MiniMapView();
		public static const MAX_ALLOWABLE_MAP_WIDTH:int = 160;
		
		private static const MAX_CONTRACTED_H:int = 70;
		private static const MAP_PADD:uint = 3;
		
		/** The value is irrelevent, we only check the key for existence */
		private static const ITEMS_TO_TRACK:Object = {'npc_rube':true};
		
		/**
		 * How many pixels should bleed outside the map container on each side.
		 * Used to allow signposts and pc overlays to show up outside the map.
		 * Bleed occurs on left, right, and top.
		 */
		private static const MAP_CONTAINER_BLEED:int = 20;
		private static const MAP_EXPAND_BUTTON_W:uint = 30;
		private static const MAP_EXPAND_BUTTON_H:uint = 10;
		
		private var worldModel:WorldModel;
		private var location:Location;

		private var _gameRenderer:LocationRenderer;
		
		//defaults
		private var YOU_DOT_RADIUS:int = 4;
		private var YOU_DOT_COLOR:uint = 0xEE0000;
		private var YOU_DOT_STROKE_COLOR:uint = 0xFFFFFF;
		private var YOU_DOT_STROKE_WIDTH:uint = 2;
		private var OTHER_DOT_RADIUS:int = 4;
		private var OTHER_DOT_COLOR:uint = 0xFFFFFF;
		private var OTHER_DOT_STROKE_COLOR:uint = 0x000000;
		private var OTHER_DOT_STROKE_WIDTH:uint = 2;
		private var ITEM_DOT_COLOR:uint = 0xf8992a;
		private var MAP_BG_COLOR:uint = 0xFFFFFF;
		private var MAP_BG_ALPHA:Number = .85;
		
		/** for TSTweener */
		public var contracted_map_container_h:int;
		public var map_container_h:int;
		
		// related to expanding the map
		private const rollOverTimer:Timer = new Timer(2000, 1);
		private var map_expanded:Boolean = false;
		private var map_is_tweening:Boolean = false;
		private var map_expand_holder:Sprite = new Sprite();
		private var map_expand_bt:Sprite = new Sprite();
		private var bg_holder:Sprite = new Sprite();
		
		private const fog_tf:TextField = new TextField();
		private const map_container_scrollrect:Rectangle = new Rectangle();
		private const map_container_sp:Sprite = new Sprite();
		private const map_sp:Sprite = new Sprite();
		private const map_signposts_sp:Sprite = new Sprite();
		private const map_pcs_sp:Sprite = new Sprite();
		private const map_itemstacks_sp:Sprite = new Sprite();
		private const map_you_sp:Sprite = new Sprite();
		private const map_invoke_plats_sh:Shape = new Shape();
		private const map_mask:Shape = new Shape();
		private const map_invoke_plats_sh_mask:Shape = new Shape();
		
		private var inited:Boolean = false;
		private var current_bitmap:Bitmap;
		private var map_h:int;
		private var map_bg_css:Object;
		private var map_other_css:Object;
		
		private var last_pc_x:int;
		private var last_pc_y:int;
		
		private var gps_ui:GpsUI;
		
		CONFIG::god private const viewport_proxy:Sprite = _makeViewportProxy();
		
		CONFIG::locodeco private const visible_cb:Checkbox = new Checkbox({
			label: 'visible',
			name: 'mapVisible'
		});
		
		CONFIG::locodeco private const fog_cb:Checkbox = new Checkbox({
			label: 'fog',
			name: 'mapFog'
		});
		
		CONFIG::locodeco private const reload_bt:Button = new Button({
			label: 'refresh',
			name: 'refreshMap',
			h: 18,
			tip: { txt: "Refresh the map on demand (not necessary to do before saves)", pointer: WindowBorder.POINTER_BOTTOM_CENTER }
		});
		
		CONFIG::god private const xy_holder:Sprite = new Sprite();
		CONFIG::god private const x_tf:TextField = new TextField();
		CONFIG::god private const y_tf:TextField = new TextField();
		CONFIG::god private var drag_delta_x:Number;
		CONFIG::god private var drag_delta_y:Number;
		CONFIG::god private var editing_x:Number = NaN;
		CONFIG::god private var editing_y:Number = NaN;
		
		public function MiniMapView():void {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function init():void {
			inited = true;
			worldModel = model.worldModel;
			location = worldModel.location;
			_gameRenderer = TSFrontController.instance.getMainView().gameRenderer;
			//the constructor needs to know the _w of this thing
			//if width is going to change then the items in the _construct method that require a width
			//should be moved to a jigger() on refresh()
			_w = MAX_ALLOWABLE_MAP_WIDTH;
			_construct();
			TSFrontController.instance.registerMoveListener(this);
			CONFIG::god {
				model.stateModel.registerCBProp(onEditingChangeHandler, 'editing');
				model.stateModel.registerCBProp(onEditingChangeHandler, 'hand_of_god');
			}
		}
		
		override public function get w():int {
			return _w > 0 ? _w : MAX_ALLOWABLE_MAP_WIDTH;
		}
		
		override public function get h():int {
			// this.height includes some stuff which is invisible
			// (thanks to our use of scrollRects and MAP_CONTAINER_BLEED),
			// so it's inaccurate and fluctuates a lot; therefore we calculate
			// height more deterministically, quickly, hack-ily:
			return _h + MAP_EXPAND_BUTTON_H;
		}
		
		override protected function _construct():void {
			super._construct();
			
			var g:Graphics;
			
			//put the bg in there
			addChild(bg_holder);
			
			map_container_sp.addChild(map_sp);
			map_sp.useHandCursor = map_sp.buttonMode = true;
			map_sp.name = '_map_sp';
			map_sp.mask = map_mask;
			
			CONFIG::god {
				// allow panning around the game world
				map_sp.addEventListener(MouseEvent.MOUSE_DOWN, _mapMouseDownHandler, false, 0, true);
				map_sp.addEventListener(MouseEvent.MOUSE_OVER, _showHandMouseOverHandler, false, 0, true);
				map_sp.addEventListener(MouseEvent.MOUSE_OUT,  _hideHandMouseOutHandler,  false, 0, true);
				map_container_sp.addChild(viewport_proxy);
				
				// xy position tracking
				StageBeacon.mouse_move_sig.add(_xyPositionUpdate);
				TFUtil.prepTF(x_tf);
				TFUtil.prepTF(y_tf);
				xy_holder.addChild(x_tf);
				xy_holder.addChild(y_tf);
				addChild(xy_holder);
				
				// allow dragging the map view around
				xy_holder.addEventListener(MouseEvent.MOUSE_UP,   _xyMouseUpHandler,         false, 0, true);
				xy_holder.addEventListener(MouseEvent.MOUSE_DOWN, _xyMouseDownHandler,       false, 0, true);
				xy_holder.addEventListener(MouseEvent.MOUSE_OVER, _showHandMouseOverHandler, false, 0, true);
				xy_holder.addEventListener(MouseEvent.MOUSE_OUT,  _hideHandMouseOutHandler,  false, 0, true);
				
				CONFIG::locodeco {
					visible_cb.addEventListener(TSEvent.CHANGED, function():void {
						TSFrontController.instance.pushUndo(LocoDecoSWFBridge.UNDO_MAP_VISIBILTY);
						location.no_map = !visible_cb.checked;
					});
					addChild(visible_cb);
					
					fog_cb.addEventListener(TSEvent.CHANGED, function():void {
						TSFrontController.instance.pushUndo(LocoDecoSWFBridge.UNDO_MAP_VISIBILTY);
						location.fog_map = fog_cb.checked;
					});
					addChild(fog_cb);
					
					reload_bt.addEventListener(TSEvent.CHANGED, function():void {
						TSFrontController.instance.resnapMiniMap();
					});
					addChild(reload_bt);
				}
			}
			
			//set the values from the css
			const cssm:CSSManager = CSSManager.instance;
			MAP_BG_COLOR = cssm.getUintColorValueFromStyle('mini_map_bg', 'color', MAP_BG_COLOR);
			MAP_BG_ALPHA = cssm.getNumberValueFromStyle('mini_map_bg', 'alpha', MAP_BG_ALPHA);
			
			//when creating other player dots
			OTHER_DOT_COLOR = cssm.getUintColorValueFromStyle('mini_map_other', 'color', OTHER_DOT_COLOR);
			OTHER_DOT_STROKE_COLOR = cssm.getUintColorValueFromStyle('mini_map_other', 'strokeColor', OTHER_DOT_STROKE_COLOR);
			OTHER_DOT_STROKE_WIDTH = cssm.getNumberValueFromStyle('mini_map_other', 'strokeWidth', OTHER_DOT_STROKE_WIDTH);
			OTHER_DOT_RADIUS = cssm.getNumberValueFromStyle('mini_map_other', 'circleSize', OTHER_DOT_RADIUS) + OTHER_DOT_STROKE_WIDTH/2;

			map_container_sp.addChild(map_pcs_sp);
			map_container_sp.addChild(map_itemstacks_sp);
			map_container_sp.addChild(map_signposts_sp);
			map_container_sp.addChild(map_you_sp);
			map_container_sp.addChild(map_invoke_plats_sh);
			map_invoke_plats_sh.mask = map_invoke_plats_sh_mask;
			addChild(map_container_sp);
			addChild(map_mask);
			addChild(map_invoke_plats_sh_mask);
			map_container_sp.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, false, 0, true);
			
			// handle 2 second rollovers
			map_container_sp.addEventListener(MouseEvent.ROLL_OVER, onRollOver, false, 0, true);
			rollOverTimer.addEventListener(TimerEvent.TIMER_COMPLETE, expandContractMap, false, 0 , true);
			map_container_sp.addEventListener(MouseEvent.ROLL_OUT, onRollOut, false, 0, true);
			
			// expand button
			const arrow:DisplayObject = new AssetManager.instance.assets.map_expand_arrow();
			SpriteUtil.setRegistrationPoint(arrow);
			map_expand_holder.addChild(arrow);
			map_expand_holder.x = MAP_EXPAND_BUTTON_W/2;
			map_expand_holder.y = MAP_EXPAND_BUTTON_H/2 - 1;
			map_expand_bt.addChild(map_expand_holder);
			map_expand_bt.mouseChildren = false;
			map_expand_bt.useHandCursor = map_expand_bt.buttonMode = true;
			map_expand_bt.addEventListener(MouseEvent.CLICK, expandContractMap, false, 0, true);
			map_expand_bt.filters = StaticFilters.copyFilterArrayFromObject({distance:1, alpha:.2, blurY:2}, StaticFilters.black2px90Degrees_DropShadowA);
			g = map_expand_bt.graphics;
			g.beginFill(model.layoutModel.bg_color);
			bg_holder.addChild(map_expand_bt);
			g.drawRoundRectComplex(0, 0, MAP_EXPAND_BUTTON_W, MAP_EXPAND_BUTTON_H, 0, 0, 4, 4);
			g.endFill();
			
			// fog tf
			TFUtil.prepTF(fog_tf, false);
			fog_tf.alpha = 0.9;
			fog_tf.htmlText = '<span class="mini_map_fog">No map: You\'re on your own</span>';
			fog_tf.visible = false;
			addChild(fog_tf);
			
			//GPS
			gps_ui = new GpsUI();
			
			addYou();
		}
		
		public function addGraphic(b:Bitmap):void {
			// cleanup
			last_pc_x = int.MAX_VALUE;
			last_pc_y = int.MAX_VALUE;
			while (map_sp.numChildren) map_sp.removeChildAt(0);
			while (map_signposts_sp.numChildren) removeSignpost(map_signposts_sp.getChildAt(0));
			while (map_itemstacks_sp.numChildren) removeItemstack(map_itemstacks_sp.getChildAt(0));
			while (map_pcs_sp.numChildren) removePC(map_pcs_sp.getChildAt(0));
			
			// throw away old bitmap
			if (current_bitmap && (current_bitmap != b)) current_bitmap.bitmapData.dispose();
			
			// add and size the bitmap
			var perc:Number;
			current_bitmap = b;
			if (b) {
				_w = MAX_ALLOWABLE_MAP_WIDTH;
				perc = (_w / b.width);
				map_h = b.height*perc;
				_w = b.width*perc;
			} else {
				_w = MAX_ALLOWABLE_MAP_WIDTH;
				perc = (_w / model.worldModel.location.mg.w);
				map_h = model.worldModel.location.mg.h*perc;
				_w = model.worldModel.location.mg.w*perc;
			}
			
			if (!b || location.fog_map && !model.stateModel.editing && !model.stateModel.hand_of_god) {
				const blackdrop:Sprite = new Sprite();
				blackdrop.graphics.beginFill(0, 0.7);
				blackdrop.graphics.drawRect(0, 0, _w, map_h);
				map_sp.addChild(blackdrop);
				fog_tf.visible = true;
			} else {
				b.width = _w;
				b.height = map_h;
				map_sp.addChild(b);
				fog_tf.visible = false;
			}
			
			for (var i:int=0;i<location.mg.signposts.length;i++) {
				maybeAddSignpost(location.mg.signposts[int(i)]);
			}
			
			for (tsid in location.pc_tsid_list) {
				addPC(tsid);
			}
			
			// determine contracted size of the map
			if (shouldShowMapExpand()) {
				contracted_map_container_h = MAX_CONTRACTED_H + MAP_EXPAND_BUTTON_H;
			} else {
				contracted_map_container_h = map_h;
			}
			
			// set initial size of map container
			// (the map might already be expanded when the graphic is updated)
			map_container_h = (map_expanded ? map_h : contracted_map_container_h);
			
			resizeMapContainer();
		}
		
		private function resizeMapContainer():void {
			// bleed off left and right
			map_container_sp.x = -MAP_CONTAINER_BLEED;
			map_container_scrollrect.x = -MAP_CONTAINER_BLEED;
			map_container_scrollrect.width = _w + (2*MAP_CONTAINER_BLEED);
			// bleed off top
			map_container_sp.y = -MAP_CONTAINER_BLEED;
			// updates map_container_scrollrect.y to be around PC
			updateYou();
			map_container_scrollrect.height = map_container_h + MAP_CONTAINER_BLEED;
			// set scrollRect
			map_container_sp.scrollRect = map_container_scrollrect;
			showHideIcons();
			
			_h = map_container_h;
			
			map_expand_bt.x = Math.round((_w - MAP_EXPAND_BUTTON_W)/2);
			map_expand_bt.y = _h + 3;
			
			CONFIG::god {
				if (model.stateModel.hand_of_god) {
					_h += xy_holder.height + 2;
				}
				
				CONFIG::locodeco {
					if (model.stateModel.editing) {
						_h += xy_holder.height + 2 + visible_cb.height + 2 + reload_bt.height + 2;
					}
				}
			}
			
			refresh();
		}
		
		public function maybeAddSignpost(signpost:SignPost):void {
			// make sure signpost has visible connections
			if (signpost.hidden) return;
			if (signpost.invisible) return;
			const visible_connects:Vector.<LocationConnection> = signpost.getVisibleConnects();
			if (visible_connects.length == 0 && ! location.is_home) {
				return;
			} else if (signpost.client::quarter_info && signpost.client::quarter_info.style != QuarterInfo.STYLE_NORMAL) {
				return;
			}
			
			const sp_sp:Sprite = new Sprite();
			sp_sp.addChild(new AssetManager.instance.assets.teensy_signpost());
			sp_sp.name = signpost.tsid;
			sp_sp.useHandCursor = sp_sp.buttonMode = true;
			sp_sp.filters = StaticFilters.youDisplayManager_GlowA;
			sp_sp.addEventListener(MouseEvent.ROLL_OVER, onSignpostOver, false, 0, true);
			sp_sp.addEventListener(MouseEvent.ROLL_OUT, onSignpostOut, false, 0, true);
			
			map_signposts_sp.addChild(sp_sp);
			placeThingAt(sp_sp, signpost.x, signpost.y);
			TipDisplayManager.instance.registerTipTrigger(sp_sp);
		}
		
		private function onRollOver(e:*):void {
			if (!map_is_tweening && !map_expanded) rollOverTimer.start();
		}
		
		private function onRollOut(e:*):void {
			rollOverTimer.reset();
		}
		
		private function mouseUpHandler(e:MouseEvent):void {
			const x:int = location.l+((map_sp.mouseX/_w)*location.mg.w);
			const y:int = location.t+((map_sp.mouseY/map_h)*location.mg.h);
			
			CONFIG::god {
				StageBeacon.mouse_up_sig.remove(mouseUpHandler);
				StageBeacon.mouse_move_sig.remove(_mapDragHandler);
				
				// when editing, clicking should pan the view
				if (model.stateModel.editing || model.stateModel.hand_of_god) {
					_gameRenderer.moveTo(x,y);
					return;
				}
			}
			
			//can't use the click to move feature if the main view isn't in focus
			if(model.stateModel.focused_component is TSMainView == false) return;
			
			if (e.target.name.indexOf('signpost') == 0) {
				TSFrontController.instance.startUserInitiatedPath(e.target.name);
			} else if (e.target.name.indexOf('P') == 0 && e.target is Sprite) {
				if (e.target.name != worldModel.pc.tsid) {
					TSFrontController.instance.startUserInitiatedPath(e.target.name);
				}
			} else if (e.target.name.indexOf('I') == 0 && e.target is Sprite) {
				TSFrontController.instance.startUserInitiatedPath(e.target.name);
			} else {
				//TODO PERF Remove new point here.
				TSFrontController.instance.startUserInitiatedPath(new Point(x, y));
			}
		}
		
		private function expandContractMap(event:*):void {
			if (shouldShowMapExpand()) {
				TSTweener.removeTweens(this);
				if (map_expanded) {
					TSTweener.addTween(this, {
						map_container_h: contracted_map_container_h,
						time: 0.4,
						transition: 'easeInCubic',
						onStart: startContractTween,
						onUpdate: resizeMapContainer,
						onComplete: endContractTween
					});
				} else {
					TSTweener.addTween(this, {
						map_container_h: map_h,
						time: 0.4,
						transition: 'easeOutCubic',
						onStart: startExpandTween,
						onUpdate: resizeMapContainer,
						onComplete: endExpandTween
					});
				}
			}
		}
		
		private function startExpandTween():void {
			map_is_tweening = true;
		}
		
		private function endExpandTween():void {
			map_is_tweening = false;
			map_expanded = true;
			addEventListener(MouseEvent.ROLL_OUT, expandContractMap);
			map_expand_holder.rotation = 180;
		}
		
		private function startContractTween():void {
			map_is_tweening = true;
		}
		
		private function endContractTween():void {
			map_is_tweening = false;
			map_expanded = false;
			refreshLocPath();
			removeEventListener(MouseEvent.ROLL_OUT, expandContractMap);
			map_expand_holder.rotation = 0;
		}
		
		private function onSignpostOver(event:MouseEvent):void {
			event.currentTarget.filters = StaticFilters.blue2px_GlowA;
		}
		
		private function onSignpostOut(event:MouseEvent):void {
			event.currentTarget.filters = StaticFilters.youDisplayManager_GlowA;
		}
		
		private function placeThingAt(thing:DisplayObject, x:int, y:int):void {
			//TODO PERF skip if things last xy hasn't changed
			// PERF: "int(... + 0.5)" is a faster way of rounding
			thing.x = (translateX(x) - int(thing.width*0.5));
			
			// EC: I do not understand why if we do not do this max() that when the translateY(y)==0 the dot disappers!
			thing.y = Math.max(
				(1 - int(thing.height + 0.5)),
				(translateY(y) - int(thing.height + 0.5)));
			
			// hide if above the top of the map_container_sp (an iterative version of showHideIcons()):
			// adjust for vertical bleed, since we want to know what is in the unbled rect
			const top:int = (map_container_scrollrect.top + MAP_CONTAINER_BLEED);
			// adjust icon.y to be the bottom y, not the top
			thing.visible = (top < (thing.y + thing.height));
		}
		
		private function translateX(x:int):int {
			return int(((x-location.l)/location.mg.w)*_w + 0.5);
		}
		
		private function translateY(y:int):int {
			return int(((y-location.t)/location.mg.h)*map_h + 0.5);
		}
		
		public function drawRangesFromCPLS(cpls:ContiguousPlatformLineSet, less:int=0):void {
			// this code is basically the same as in CPLCV.draw, so it woudl probably be ideal
			// to refactor things so this routine has a single home. at some point.
			
			var g:Graphics = map_invoke_plats_sh.graphics;
			var i:int;
			var m:int;
			var pl:PlatformLine;
			var range:Range;
			var range_draw_start_x:int;
			var range_draw_end_x:int;
			
			// now draw white for the extent of the valid ranges
			// This is what we will want to show to users
			for (i=0;i<cpls.platform_lines.length;i++) {
				pl = cpls.platform_lines[i];
				
				for (m=0;m<cpls.valid_ranges.length;m++) {
					range = cpls.valid_ranges[m].clone();
					range.x1+= less;
					range.x2-= less;
					
					// does this range start in this pl's x range
					if (range.x1>=pl.start.x && range.x1<=pl.end.x) {
						range_draw_start_x = range.x1;
						range_draw_end_x = Math.min(pl.end.x, range.x2);
					}
						// does this range end in this pl's x range
					else if (range.x2>=pl.start.x && range.x2<=pl.end.x) {
						range_draw_start_x = Math.max(pl.start.x, range.x1);
						range_draw_end_x = range.x2;
					}
						// does this range cover this whole pl
					else if (range.x1<=pl.start.x && range.x2>=pl.end.x) {
						range_draw_start_x = pl.start.x;
						range_draw_end_x = pl.end.x;
					}
						// this pl and this range do not overlap
					else {
						continue;
					}
					
					g.lineStyle(2, 0xffffff, 1);
					g.moveTo(translateX(range_draw_start_x), translateY(pl.yIntersection(range_draw_start_x)));
					g.lineTo(translateX(range_draw_end_x), translateY(pl.yIntersection(range_draw_end_x)));
				}
			}
		}
		
		public function clearRangesFromCPLSes():void {
			map_invoke_plats_sh.graphics.clear();
		}
		
		private function colorPC(dot:Sprite, pc:PC):void {
			const g:Graphics = dot.graphics;
			g.clear();
			
			var c:uint = (pc.color_group) ? ColorUtil.getDotColor(pc.color_group) : OTHER_DOT_COLOR;
			// if there is game text, make stroke same as fill
			var stroke_c:uint = (pc.game_text) ? c : OTHER_DOT_STROKE_COLOR;
			// if there is game text, make the dot a little bigger
			var r:int = (pc.game_text) ? OTHER_DOT_RADIUS+2 : OTHER_DOT_RADIUS;
			
			g.lineStyle(OTHER_DOT_STROKE_WIDTH, stroke_c, 1);
			g.beginFill(c);
			g.drawCircle(r+OTHER_DOT_STROKE_WIDTH, r+OTHER_DOT_STROKE_WIDTH, r);
			g.endFill();
			
			var dot_tf:TextField;
			if (pc.game_text) {
				// create a text field if it doesn't exist
				if (dot.numChildren == 0) {
					dot_tf = new TextField();
					dot_tf.name = 'dot_tf';
					dot_tf.autoSize = TextFieldAutoSize.CENTER;
					dot_tf.visible = false;
					TFUtil.prepTF(dot_tf, false);
					dot.addChild(dot_tf);
				} else {
					dot_tf = (dot.getChildAt(0) as TextField);
				}
				dot_tf.htmlText = '<font face="HelveticaEmbed" size="8" color="#ffffff">'+pc.game_text+'</font>';
				dot_tf.visible = true;
				// PERF: "int(... + 0.5)" is a faster way of rounding
				dot_tf.x = -int(dot_tf.width*0.5 + 0.5)  + r + OTHER_DOT_STROKE_WIDTH - 1;
				dot_tf.y = -int(dot_tf.height*0.5 + 0.5) + r + OTHER_DOT_STROKE_WIDTH - 0;
			} else {
				// if there is a text field, hide it
				if (dot.numChildren == 1) {
					dot_tf = (dot.getChildAt(0) as TextField);
					dot_tf.visible = false;
				}
			}
		}
		
		public function onLocPcAdds(tsids:Array):void {
			for each (var tsid:String in tsids) {
				addPC(tsid);
			}
		}
		
		private function addYou():void {
			const g:Graphics = map_you_sp.graphics;
			g.clear();
			g.lineStyle(YOU_DOT_STROKE_WIDTH, YOU_DOT_STROKE_COLOR);
			g.beginFill(0);
			g.drawCircle(YOU_DOT_RADIUS+YOU_DOT_STROKE_WIDTH, YOU_DOT_RADIUS+YOU_DOT_STROKE_WIDTH, YOU_DOT_RADIUS);
			
			map_you_sp.filters = [new GlowFilter(0xFFD616, 0.55, 7, 7, 4, 1)];
			map_you_sp.cacheAsBitmap = true;
			
			map_you_sp.mouseEnabled = map_you_sp.mouseChildren = false;
			TipDisplayManager.instance.registerTipTrigger(map_you_sp);
			
			updateYou();
		}
		
		private function addPC(tsid:String):Sprite {
			if (tsid == worldModel.pc.tsid) return null;
			
			var pc:PC = worldModel.getPCByTsid(tsid);
			if (!pc || !pc.online) return null;
			
			var pc_sp:Sprite = (map_pcs_sp.getChildByName(tsid) as Sprite);
			if (!pc_sp) {
				pc_sp = new Sprite();
				map_pcs_sp.addChild(pc_sp);
				colorPC(pc_sp, pc);
			}
			
			pc_sp.name = tsid;
			pc_sp.useHandCursor = true;
			pc_sp.buttonMode = true;
			TipDisplayManager.instance.registerTipTrigger(pc_sp);
			
			placeThingAt(pc_sp, pc.x, pc.y);
			
			return pc_sp;
		}
		
		public function onLocPcDels(tsids:Array):void {
			var pc_sp:Sprite;
			for each (var tsid:String in tsids) {
				if (tsid == worldModel.pc.tsid) continue;
				pc_sp = (map_pcs_sp.getChildByName(tsid) as Sprite);
				if (pc_sp) removePC(pc_sp);
			}
		}
		
		public function onEnterFrame(ms_elapsed:int):void {
			if (inited && visible) {
				const pc:PC = worldModel.pc;
				// PERF: only update if we've moved
				if ((last_pc_x != pc.x) || (last_pc_y != pc.y)) {
					last_pc_x = pc.x;
					last_pc_y = pc.y;
					updateYou();
				}
			}
		}
		
		private function updateGPS():void {
			gps_ui.updateArrow();
		}
		
		private function updateYou():void {
			const pc:PC = worldModel.pc;
			
			updateGPS();
			
			// center the map on the PC
			if (map_is_tweening) {
				// pin bottom of map to bottom of container so it looks
				// like you are (un)rolling a classroom map
				// (but keep the PC visible at all times, even when scrolling up)
				map_container_scrollrect.y = Math.max(0, Math.min((map_you_sp.y - MAX_CONTRACTED_H/2), (map_h - map_container_h))) - MAP_CONTAINER_BLEED;
			} else {
				map_container_scrollrect.y = Math.max(0, Math.min((map_sp.height - map_container_h), (map_you_sp.y - map_container_h/2))) - MAP_CONTAINER_BLEED;
			}
			map_container_sp.scrollRect = map_container_scrollrect;
			showHideIcons();
			
			placeThingAt(map_you_sp, pc.x, pc.y);
		}
		
		/** Set icon visibility based on whether they're below the top of the map_container_sp */
		private function showHideIcons():void {
			// adjust for vertical bleed, since we want to know what is in the unbled rect
			const top:int = (map_container_scrollrect.top + MAP_CONTAINER_BLEED);
			
			var i:int;
			var icon:DisplayObject;
			
			for (i=map_signposts_sp.numChildren-1; i>=0; --i) {
				icon = map_signposts_sp.getChildAt(i);
				icon.visible = (top < (icon.y + icon.height));
			}
			
			for (i=map_itemstacks_sp.numChildren-1; i>=0; --i) {
				icon = map_itemstacks_sp.getChildAt(i);
				icon.visible = (top < (icon.y + icon.height));
			}
			
			for (i=map_pcs_sp.numChildren-1; i>=0; --i) {
				icon = map_pcs_sp.getChildAt(i);
				icon.visible = (top < (icon.y + icon.height));
			}
		}
		
		public function showHideGPS(is_hide:Boolean):void {
			//if we need to force hide/show the gps, this is where we do it
			if(gps_ui && gps_ui.parent){
				const end_alpha:Number = is_hide ? 0 : 1;
				TSTweener.removeTweens(gps_ui);
				TSTweener.addTween(gps_ui, {alpha:end_alpha, time:is_hide ? .1 : .2, transition:'linear'});
			}
		}
		
		public function onLocPcUpdates(tsids:Array):void {
			var pc:PC;
			var pc_sp:Sprite;
			for each (var tsid:String in tsids) {
				if (tsid == worldModel.pc.tsid) continue;
				
				pc = worldModel.getPCByTsid(tsid);
				if (!pc || !pc.online) continue;
				
				pc_sp = (map_pcs_sp.getChildByName(pc.tsid) as Sprite);
				
				if (!pc_sp) {
					pc_sp = addPC(tsid);
					if (!pc_sp) continue;
				}
				
				// make sure it has changed before re drawing
				if(pc.last_game_flag_sig != pc.game_flag_sig) {
					//TODO how often does this run?
					colorPC(pc_sp, pc);
				}
				
				placeThingAt(pc_sp, pc.x, pc.y);
			}
		}
		
		private function removePC(dot:DisplayObject):void {
			map_pcs_sp.removeChild(dot);
			TipDisplayManager.instance.unRegisterTipTrigger(dot);
		}
		
		private function removeSignpost(dot:DisplayObject):void {
			map_signposts_sp.removeChild(dot);
			TipDisplayManager.instance.unRegisterTipTrigger(dot);
		}
		
		private function removeItemstack(dot:DisplayObject):void {
			map_itemstacks_sp.removeChild(dot);
			TipDisplayManager.instance.unRegisterTipTrigger(dot);
		}
		
		public function onLocItemstackAdds(tsids:Array):void {
			var itemstack:Itemstack;
			var itemstack_sp:Sprite;
			var g:Graphics;
			
			for each (var tsid:String in tsids) {
				itemstack = worldModel.getItemstackByTsid(tsid);
				
				// if we aren't tracking this item, skip it
				if(!itemstack || !mapTracksItemByTsid(itemstack.item.tsid)) continue;
				
				itemstack_sp = new Sprite();
				itemstack_sp.useHandCursor = true;
				itemstack_sp.buttonMode = true;
				itemstack_sp.name = tsid;
				
				g = itemstack_sp.graphics;
				g.lineStyle(OTHER_DOT_STROKE_WIDTH, OTHER_DOT_STROKE_COLOR, 1);
				g.beginFill(ITEM_DOT_COLOR);
				g.drawCircle(OTHER_DOT_RADIUS+OTHER_DOT_STROKE_WIDTH, OTHER_DOT_RADIUS+OTHER_DOT_STROKE_WIDTH, OTHER_DOT_RADIUS);
				
				map_itemstacks_sp.addChild(itemstack_sp);
				placeThingAt(itemstack_sp, itemstack.x, itemstack.y);
				TipDisplayManager.instance.registerTipTrigger(itemstack_sp);
			}
		}
		
		public function onLocItemstackUpdates(tsids:Array):void {
			var itemstack:Itemstack;
			var itemstack_sp:DisplayObject;
			
			for each (var tsid:String in tsids) {
				itemstack = worldModel.getItemstackByTsid(tsid);
				
				// if we aren't tracking this item, skip it
				if(!itemstack || !mapTracksItemByTsid(itemstack.item.tsid)) continue;
				
				itemstack_sp = map_itemstacks_sp.getChildByName(tsid) as Sprite;
				if (itemstack_sp) {
					placeThingAt(itemstack_sp, itemstack.x, itemstack.y);
				} else {
					onLocItemstackAdds([tsid]);
				}
			}
		}
		
		public function onLocItemstackDels(tsids:Array):void {
			var dot:DisplayObject;
			var itemstack:Itemstack;
			for each (var tsid:String in tsids) {
				itemstack = worldModel.getItemstackByTsid(tsid);
				
				// if we aren't tracking this item, skip it
				if(!itemstack || !mapTracksItemByTsid(itemstack.item.tsid)) continue;
	
				dot = map_itemstacks_sp.getChildByName(tsid);
				if (dot) {
					removeItemstack(dot);
				}
			}
		}
		
		private function mapTracksItemByTsid(class_tsid:String):Boolean {
			return (class_tsid in ITEMS_TO_TRACK);
		}
		
		public function refreshLocPath():void {
			gps_ui.hide();
			
			//show the gps if we have a path
			if (model.stateModel.loc_pathA.length && !model.stateModel.editing && !model.stateModel.hand_of_god){
				addChildAt(gps_ui, 0);
				gps_ui.show();
			}
		}
		
		public function show():void {
			// a bit of a hack, but if we are displayed and don't have anything
			// in the map_sp, we need addGraphic to be called
			if (map_sp.numChildren == 0) {
				// since we need to show NOW, add a temporarily fogged map
				addGraphic(null);
				// and ask for a better one to be made
				TSFrontController.instance.resnapMiniMap();
			}
			visible = true;
			refreshLocPath();
		}
		
		public function hide():void {
			visible = false;
		}
		
		public function refresh():void {
			if (!inited) return;
			// if the computed map width changes from viewport resizing, rebuild the minimap
			if (current_bitmap && (_w != MAX_ALLOWABLE_MAP_WIDTH)) {
				addGraphic(current_bitmap);
				// addGraphic will call refresh()
				refreshLocPath();
			} else {
				_draw();
				place();
			}
		}
		
		private function place():void {
			// let you pan the map around for convenience
			CONFIG::god {
				if ((model.stateModel.editing || model.stateModel.hand_of_god) && !isNaN(editing_x) && !isNaN(editing_y)) {
					// keep it in the viewport
					x = Math.min(Math.max(editing_x, 0), model.layoutModel.loc_vp_w - _w);
					y = Math.min(Math.max(editing_y, 0), model.layoutModel.loc_vp_h - _h);
					return;
				}
			}
			
			x = model.layoutModel.loc_vp_w - _w;
			y = 0;
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if (!tip_target) return null;
			
			var tip:String = '';
			
			const signpost:SignPost = location.mg.getSignpostById(tip_target.name);
			if (signpost) {
				const info:QuarterInfo = signpost.client::quarter_info;
				if (info) {
					if (info.style == QuarterInfo.STYLE_NORMAL) {
						tip = info.label;
					} else {
						tip = info.style;
					}
				} else {
					var visible_connects:Vector.<LocationConnection> = signpost.getVisibleConnects();
					if (visible_connects.length == 0) return null;
					for(var j:int = 0; j < visible_connects.length; j++){
						tip += visible_connects[int(j)].label + ((j+1 < visible_connects.length) ? '\n' : '');
					}
				}
			} else if (worldModel.getPCByTsid(tip_target.name)){
				//this is a player (not you), show the label
				if(tip_target.name == worldModel.pc.tsid) return null;
				tip = worldModel.getPCByTsid(tip_target.name).label;
			} else if (worldModel.getItemstackByTsid(tip_target.name)){
				//this is an item, show the label
				tip = worldModel.getItemstackByTsid(tip_target.name).label;
			} else {
				return null;
			}
			
			var street_count:int = tip_target.name.match(/\n/gi).length + 1;
			var offset:int = (street_count < 3) ? -7 : 25;
			var pointer:String = (street_count < 3) ? WindowBorder.POINTER_BOTTOM_CENTER : WindowBorder.POINTER_TOP_CENTER;
			
			//TODO make all the tips show at the same Y no matter where the post is
			offset = 15;
			pointer = WindowBorder.POINTER_TOP_CENTER;
			
			return {
				txt: tip,
				offset_y: offset,
				pointer: pointer
			};
		}
		
		override protected function _draw():void {
			if (!inited) return;
			
			const lm:LayoutModel = model.layoutModel;
			
			var g:Graphics = bg_holder.graphics;
			g.clear();
			if (model.stateModel.editing || model.stateModel.hand_of_god) {
				g.beginFill(MAP_BG_COLOR, MAP_BG_ALPHA);
				g.drawRoundRect(0, 0, _w, _h, 8);
			} else {
				const curve_radius:Number = 10;
				const curve_w:uint = 14;
				const curve_h:uint = 10;
				const draw_w:int = _w;
				const draw_h:int = _h + MAP_PADD;
				
				g.beginFill(lm.bg_color);
				g.drawRoundRectComplex(-MAP_PADD, 0, draw_w + MAP_PADD, draw_h, 0, 0, curve_radius, 0);
				g.endFill();
				
				//left curve
				g.beginFill(lm.bg_color);
				g.moveTo(-MAP_PADD-curve_w, -1);//-1 is a visual tweak cause of the curve's anti-aliasing
				g.lineTo(-MAP_PADD, -1);
				g.lineTo(-MAP_PADD, curve_h);
				g.curveTo(-MAP_PADD,-1, -MAP_PADD-curve_w,-1);
				g.endFill();
				
				//bottom curve
				g.beginFill(lm.bg_color);
				g.moveTo(draw_w-curve_w, draw_h-1); //-1 is a visual tweak cause of the curve's anti-aliasing
				g.lineTo(draw_w, draw_h-1);
				g.lineTo(draw_w, draw_h+curve_h);
				g.curveTo(draw_w,draw_h-1, draw_w-curve_w, draw_h-1);
				g.endFill();
			}
			
			CONFIG::god {
				if (model.stateModel.editing || model.stateModel.hand_of_god) {
					const wd2:int = Math.round(_w/2);
					const pad:int = 2;
					
					// xy position bg
					x_tf.x = pad;
					x_tf.width = -pad + wd2 + -pad;
					y_tf.x = x_tf.x + x_tf.width + 2*pad;
					y_tf.width = x_tf.width;
					xy_holder.x = 0;
					xy_holder.y = map_container_h+1;
					
					// bg
					g = xy_holder.graphics;
					g.clear();
					g.beginFill(0, 0.04);
					g.drawRoundRect(2, 0, _w-2, 18, 10);
					g.lineStyle(0, 0xC6D2D7, 1, true);
					g.moveTo(wd2, 0);
					g.lineTo(wd2, 18);
					
					CONFIG::locodeco {
						visible_cb.x = Math.round((wd2 - visible_cb.w)/2);
						visible_cb.y = xy_holder.y + xy_holder.height + pad;
						fog_cb.x = wd2 + Math.round((wd2 - fog_cb.w)/2);
						fog_cb.y = visible_cb.y;
						reload_bt.x = 3;
						reload_bt.y = visible_cb.y + visible_cb.height;
						reload_bt.w = _w - 2*pad;
					}
				}
			}
			
			g = map_mask.graphics;
			g.clear();
			g.beginFill(0xffffff);
			if (model.stateModel.editing || model.stateModel.hand_of_god) {
				g.drawRoundRect(2, 2, _w-4, map_container_h-1, 6);
			} else {
				//draw it flush with the viewport
				g.drawRoundRect(0, 0, _w-2, map_container_h, 16);
			}
			
			g = map_invoke_plats_sh_mask.graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRoundRect(2, 2, _w-4, map_container_h-1, 6);
			
			// draw the viewport in the minimap
			CONFIG::god {
				// hide stuff while editing
				const editing:Boolean  = model.stateModel.editing;
				const hog:Boolean      = model.stateModel.hand_of_god;
				map_pcs_sp.visible        = !editing && !hog;
				map_itemstacks_sp.visible = !editing && !hog;
				map_signposts_sp.visible  = !editing && !hog;
				map_you_sp.visible        = !editing && !hog;
				viewport_proxy.visible    =  editing || hog;
				xy_holder.visible         =  editing || hog;
				CONFIG::locodeco {
					reload_bt.visible     =  editing;
					visible_cb.visible    =  editing;
					fog_cb.visible        =  editing;
				}
				
				g = viewport_proxy.graphics;
				g.clear();
				if (editing || hog) {
					CONFIG::locodeco {
						fog_cb.checked = location.fog_map;
						visible_cb.checked = !location.no_map;
					}
					
					const ratio:Number = _w/location.mg.w;
					g.lineStyle(0, 0, 0.5, true);
					g.beginFill(0xFFFFFF, 0.15);
					g.drawRoundRect(0, 0, lm.loc_vp_w/lm.loc_vp_scale*ratio, lm.loc_vp_h/lm.loc_vp_scale*ratio, 6);
					
					// magic numbers account for round rect above and line styles
					const tmpX:int = Math.round(((lm.loc_cur_x - location.l) / location.mg.w) * _w - (viewport_proxy.width/2));
					const tmpY:int = Math.round(((lm.loc_cur_y - location.t) / location.mg.h) * map_container_h - (viewport_proxy.height/2));
					viewport_proxy.x = Math.max(2, Math.min(_w - viewport_proxy.width - 3, tmpX));
					viewport_proxy.y = Math.max(2, Math.min(map_container_h - viewport_proxy.height - 1, tmpY));
				}
			}
			
			// align top center
			fog_tf.x = (_w - 4 - fog_tf.textWidth)/2;
			fog_tf.y = 1;
			
			// expander
			map_expand_bt.visible = shouldShowMapExpand();
		}
		
		private function shouldShowMapExpand():Boolean {
			// allows for at least 14 pixels of growth when the map is expanded
			// so we don't only expand a few pixels near edge conditions
			return ((map_h > MAX_CONTRACTED_H + 14) && !model.stateModel.editing && !model.stateModel.hand_of_god);
		}
		
		////////////////////////////////////////////////////////////////////////
		// EDITING STUFF ///////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////
		
		CONFIG::god private function _mapDragHandler(e:MouseEvent):void {
			// when editing, dragging should pan the view
			if ((model.stateModel.editing || model.stateModel.hand_of_god) && e.buttonDown) {
				const x:int = location.l+((map_sp.mouseX/_w)*location.mg.w);
				const y:int = location.t+((map_sp.mouseY/map_container_h)*location.mg.h);
				_gameRenderer.moveTo(x,y);
			}
		}
		
		CONFIG::god private function _showHandMouseOverHandler(e:*):void {
			if (model.stateModel.editing || model.stateModel.hand_of_god) {
				Mouse.cursor = MouseCursor.HAND;
			}
		}
		
		CONFIG::god private function _hideHandMouseOutHandler(e:*):void {
			Mouse.cursor = MouseCursor.AUTO;
		}
		
		CONFIG::god private function _mapMouseDownHandler(e:*):void {
			StageBeacon.mouse_up_sig.add(mouseUpHandler);
			StageBeacon.mouse_move_sig.add(_mapDragHandler);
		}
		
		CONFIG::god private function _xyMouseDownHandler(e:MouseEvent):void {
			const globalPt:Point = stage.localToGlobal(StageBeacon.stage_mouse_pt);
			const miniMapPt:Point = globalToLocal(globalPt);
			drag_delta_x = miniMapPt.x;
			drag_delta_y = miniMapPt.y;
			StageBeacon.mouse_move_sig.add(_xyDragHandler);
			StageBeacon.mouse_up_sig.add(_xyMouseUpHandler);
		}

		CONFIG::god private function _xyDragHandler(e:MouseEvent):void {
			const globalPt:Point = stage.localToGlobal(StageBeacon.stage_mouse_pt);
			const parentPt:Point = parent.globalToLocal(globalPt);
			editing_x = parentPt.x - drag_delta_x;
			editing_y = parentPt.y - drag_delta_y;
			place();
		}
		
		CONFIG::god private function _xyMouseUpHandler(e:*):void {
			StageBeacon.mouse_move_sig.remove(_xyDragHandler);
			StageBeacon.mouse_up_sig.remove(_xyMouseUpHandler);
		}
		
		CONFIG::god private function _xyPositionUpdate(e:MouseEvent):void {
			x_tf.htmlText = '<p class="game_header_date">X: <span class="game_header_date_time">'+_gameRenderer.getMouseXinMiddleground()+'</span></p>';
			y_tf.htmlText = '<p class="game_header_date">Y: <span class="game_header_date_time">'+_gameRenderer.getMouseYinMiddleground()+'</span></p>';
			refresh();
		}
		
		CONFIG::god private function _makeViewportProxy():Sprite {
			const vp:Sprite = new Sprite();
			vp.mouseEnabled = vp.mouseChildren = false;
			vp.name = 'viewport';
			return vp;
		}
		
		CONFIG::god private function onEditingChangeHandler(editing:Boolean):void {
			// when editing, don't contract the map
			map_container_h = ((model.stateModel.editing || model.stateModel.hand_of_god) ? map_h : Math.min(MAX_CONTRACTED_H, map_h));
			if (current_bitmap) {
				addGraphic(current_bitmap);
			}
			refreshLocPath();
			resizeMapContainer();
		}
		
		////////////////////////////////////////////////////////////////////////////////
		//////// IMOVELISTENER /////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		public function moveLocationHasChanged():void {
			//
		}
		
		public function moveLocationAssetsAreReady():void {
			//
		}
		
		public function moveMoveStarted():void {
			//
		}
		
		public function moveMoveEnded():void {
			location = worldModel.location;
		}
	}
}
