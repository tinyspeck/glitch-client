package com.tinyspeck.engine.view.ui.chrome {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.StateModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.URLUtil;
	import com.tinyspeck.engine.view.AbstractTSView;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.renderer.RenderMode;
	import com.tinyspeck.engine.view.renderer.commands.LocationCommands;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Checkbox;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	public class GodButtonView extends AbstractTSView implements ITipProvider {
		/* singleton boilerplate */
		public static const instance:GodButtonView = new GodButtonView();
		
		private const renderer_vector_icon_holder:Sprite = new Sprite();
		private const renderer_bitmap_icon_holder:Sprite = new Sprite();
		private const geo_icon_holder:Sprite = new Sprite();
		private const show_platlines_icon_holder:Sprite = new Sprite();
		private const hide_platlines_icon_holder:Sprite = new Sprite();
		private const stop_hand_of_god_icon_holder:Sprite = new Sprite();
		private const start_hand_of_god_icon_holder:Sprite = new Sprite();
		private const start_edit_icon_holder:Sprite = new Sprite();
		CONFIG::locodeco private const stop_edit_icon_holder:Sprite = new Sprite();
		CONFIG::locodeco private const save_icon_holder:Sprite = new Sprite();
		CONFIG::locodeco private const revert_icon_holder:Sprite = new Sprite();
		CONFIG::locodeco private const help_locodeco_icon_holder:Sprite = new Sprite();

		private var pin_cb:Checkbox;
		private var renderer_vector_bt:Button;
		private var renderer_bitmap_bt:Button;
		private var geo_bt:Button;
		private var show_platlines_bt:Button;
		private var hide_platlines_bt:Button;
		private var stop_hand_of_god_bt:Button;
		private var start_hand_of_god_bt:Button;
		private var start_edit_bt:Button;
		CONFIG::locodeco private var stop_edit_bt:Button;
		CONFIG::locodeco private var save_bt:Button;
		CONFIG::locodeco private var revert_bt:Button;
		
		private const availableRenderers:Vector.<RenderMode> = new Vector.<RenderMode>();
		
		private const drag_holder:Sprite = new Sprite();
		private var drag_delta_x:Number;
		private var drag_delta_y:Number;
		private var editing_x:Number = NaN;
		private var editing_y:Number = NaN;
		
		private var mouseIsHovering:Boolean;
		
		public function GodButtonView() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			buttonMode    = false;
			useHandCursor = false;
			mouseEnabled  = true;
			mouseChildren = true;
			cacheAsBitmap = true;
			
			const model:TSModelLocator = TSModelLocator.instance;
			model.stateModel.registerCBProp(refresh, 'hand_of_god');
			model.stateModel.registerCBProp(refresh, 'render_mode');
			
			CONFIG::locodeco {
				model.worldModel.registerCBProp(refresh, 'location');
				model.stateModel.registerCBProp(refresh, 'editing');
				model.stateModel.registerCBProp(refresh, 'editing_unsaved');
				model.stateModel.registerCBProp(refresh, 'editing_saving_changes');
				model.stateModel.registerCBProp(refresh, 'editing_requesting_lock');
			}
			
			pin_cb = new Checkbox({
				graphic: new AssetManager.instance.assets.god_unpinned(),
				graphic_checked: new AssetManager.instance.assets.god_pinned(),
				checked: LocalStorage.instance.getUserData(LocalStorage.GOD_BUTTONS_PINNED),
				label: '',
				name: 'pin_cb'
			});
			TipDisplayManager.instance.registerTipTrigger(pin_cb);
			pin_cb.addEventListener(TSEvent.CHANGED, function():void{
				LocalStorage.instance.setUserData(LocalStorage.GOD_BUTTONS_PINNED, pin_cb.checked, true);
				refresh();
			});
			addChild(pin_cb);
			
			resetAlpha();
			
			const self:Object = this;
			addEventListener(MouseEvent.MOUSE_OVER, function():void {
				mouseIsHovering = true;
				TSTweener.addTween(self, {
					alpha: 1,
					time: 0.2,
					transition: 'easeInCubic',
					onStart: refresh,
					onComplete: refresh
				});
			});
			
			addEventListener(MouseEvent.MOUSE_OUT, function():void {
				mouseIsHovering = false;
				if (!pinned) {
					TSTweener.addTween(self, {
						alpha: 0.4,
						time: 0.2,
						transition: 'easeOutCubic',
						onStart: refresh,
						onComplete: refresh
					});
				}
			});
			
			// allow dragging the map view around
			drag_holder.addChild(new AssetManager.instance.assets.god_thumb());
			addChild(drag_holder);
			drag_holder.addEventListener(MouseEvent.MOUSE_DOWN, onDragMouseDown, false, 0, true);
			drag_holder.addEventListener(MouseEvent.MOUSE_OVER, function():void {
				Mouse.cursor = MouseCursor.HAND;
			});
			drag_holder.addEventListener(MouseEvent.MOUSE_OUT, function():void {
				Mouse.cursor = MouseCursor.AUTO;
			});
			
			//vector renderer icon
			renderer_vector_bt = createButton(
				switchRenderer,
				new AssetManager.instance.assets.renderer_vector_normal(),
				new AssetManager.instance.assets.renderer_vector_disabled(),
				'vector_normal',
				'Using vector renderer');
			renderer_vector_icon_holder.addChild(renderer_vector_bt);
			addChild(renderer_vector_icon_holder);
			availableRenderers.push(RenderMode.VECTOR);
			
			//bitmap renderer icon
			renderer_bitmap_bt = createButton(
				switchRenderer,
				new AssetManager.instance.assets.renderer_bitmap_normal(),
				new AssetManager.instance.assets.renderer_bitmap_disabled(),
				'bitmap_normal',
				'Using bitmap renderer');
			renderer_bitmap_icon_holder.addChild(renderer_bitmap_bt);
			addChild(renderer_bitmap_icon_holder);
			availableRenderers.push(RenderMode.BITMAP);
			
			//geo icon
			geo_bt = createButton(
				TSFrontController.instance.openGeoForLocation,
				new AssetManager.instance.assets.geo_normal(),
				new AssetManager.instance.assets.geo_disabled(),
				'geo',
				'Open the geo page for this location');
			geo_icon_holder.addChild(geo_bt);
			addChild(geo_icon_holder);
			
			//show platlines icon
			show_platlines_bt = createButton(
				onShowPlatlinesClick,
				new AssetManager.instance.assets.plat_lines_off(),
				new AssetManager.instance.assets.plat_lines_disabled(),
				'platlines on',
				'Show geometry');
			show_platlines_icon_holder.addChild(show_platlines_bt);
			addChild(show_platlines_icon_holder);
			
			//hide platlines icon
			hide_platlines_bt = createButton(
				onHidePlatlinesClick,
				new AssetManager.instance.assets.plat_lines_on(),
				new AssetManager.instance.assets.plat_lines_disabled(),
				'platlines off',
				'Hide geometry');
			hide_platlines_icon_holder.addChild(hide_platlines_bt);
			addChild(hide_platlines_icon_holder);
			
			//start hand of god icon
			start_hand_of_god_bt = createButton(
				onStartHandOfGodClick,
				new AssetManager.instance.assets.hand_of_god_off(),
				new AssetManager.instance.assets.hand_of_god_disabled(),
				'start hand of god',
				'Start editing itemstacks');
			start_hand_of_god_icon_holder.addChild(start_hand_of_god_bt);
			addChild(start_hand_of_god_icon_holder);
			
			//stop hand of god icon
			stop_hand_of_god_bt = createButton(
				onStopHandOfGodClick,
				new AssetManager.instance.assets.hand_of_god_on(),
				new AssetManager.instance.assets.hand_of_god_disabled(),
				'stop hand of god',
				'Stop editing itemstacks');
			stop_hand_of_god_icon_holder.addChild(stop_hand_of_god_bt);
			addChild(stop_hand_of_god_icon_holder);
			
			CONFIG::locodeco {
				//help icon
				var help_locodeco_bt:Button = createButton(
					onHelpLocodecoClick,
					new AssetManager.instance.assets.help_locodeco(),
					null,
					'locodeco help',
					'LocoDeco Tips/Help');
				help_locodeco_icon_holder.addChild(help_locodeco_bt);
				addChild(help_locodeco_icon_holder);
			}
			
			//start editing icon
			start_edit_bt = createButton(
				onStartEditClick,
				new AssetManager.instance.assets.edit_off(),
				new AssetManager.instance.assets.edit_disabled(),
				'start editing',
				'Start editing location');
			start_edit_icon_holder.addChild(start_edit_bt);
			addChild(start_edit_icon_holder);
			
			CONFIG::locodeco {
				//stop editing icon
				stop_edit_bt = createButton(
					onStopEditClick,
					new AssetManager.instance.assets.edit_on(),
					new AssetManager.instance.assets.edit_disabled(),
					'stop editing',
					'Stop editing location');
				stop_edit_icon_holder.addChild(stop_edit_bt);
				addChild(stop_edit_icon_holder);
				
				//revert icon
				revert_bt = createButton(
					onRevertClick,
					new AssetManager.instance.assets.revert_normal(),
					new AssetManager.instance.assets.revert_disabled(),
					'revert',
					'Revert location changes to last saved');
				revert_icon_holder.addChild(revert_bt);
				addChild(revert_icon_holder);
				
				//save icon
				save_bt = createButton(
					onSaveClick,
					new AssetManager.instance.assets.save_normal(),
					new AssetManager.instance.assets.save_disabled(),
					'save',
					'Save location');
				save_icon_holder.addChild(save_bt);
				addChild(save_icon_holder);
			}
			
			refresh();
		}
		
		private function resetAlpha():void {
			if (!mouseIsHovering) {
				alpha = (pinned ? 1 : 0.4);
			}
		}
		
		public function get pinned():Boolean {
			return (pin_cb.checked || TSModelLocator.instance.stateModel.editing || TSModelLocator.instance.stateModel.hand_of_god);
		}

		public function refresh(_:* = null):void {
			const state:StateModel = TSModelLocator.instance.stateModel;
			const location:Location = TSModelLocator.instance.worldModel.location;
			const locationReady:Boolean = (location && location.isFullyLoaded);

			const spacer:int = 3;
			var nextY:int = spacer;
			var nextX:int = 0;

			resetAlpha();
			
			filters = ((pinned || mouseIsHovering) ? [] : [ColorUtil.getGreyScaleFilter()]);
			
			if (state.editing || state.hand_of_god) {
				drag_holder.visible = true;
				pin_cb.visible = false;
			} else {
				drag_holder.visible = false;
				pin_cb.visible = true;
			}
			
			graphics.clear();
			const r:Rectangle = getRect(null);
			r.height = 24;
			if (pinned || mouseIsHovering) {
				graphics.beginFill(0xE8ECEE);
				graphics.drawRoundRect(-2*spacer, -2*spacer, r.width+2*spacer, r.height+4*spacer, 10);
			}
			
			if ((state.editing || state.hand_of_god) && !isNaN(editing_x) && !isNaN(editing_y)) {
				x = editing_x;
				y = editing_y;
			} else {
				// top-center the buttons
				x = (TSModelLocator.instance.layoutModel.loc_vp_w - r.width+4*spacer) / 2;
				y = 0;
			}
			
			// keep it in the viewport
			x = Math.min(Math.max(x, 0), TSModelLocator.instance.layoutModel.loc_vp_w - width);
			y = Math.min(Math.max(y, 0), TSModelLocator.instance.layoutModel.loc_vp_h - height);
			
			drag_holder.x = (r.width - drag_holder.width)/2;
			drag_holder.y = (r.height + drag_holder.height/2);
			
			// editing
			start_edit_icon_holder.x = nextX;
			start_edit_icon_holder.y = nextY;
			nextX += start_edit_icon_holder.width;
			nextX += spacer;
			nextX += spacer;
			
			start_edit_bt.disabled = show_platlines_bt.disabled;

			CONFIG::locodeco {
				stop_edit_icon_holder.x = start_edit_icon_holder.x;
				stop_edit_icon_holder.y = start_edit_icon_holder.y;
				// done above
				//nextX += stop_edit_icon_holder.width;
				//nextX += spacer;
				
				save_icon_holder.x = nextX;
				save_icon_holder.y = nextY;
				nextX += save_icon_holder.width;
				
				revert_icon_holder.x = nextX;
				revert_icon_holder.y = nextY;
				nextX += revert_icon_holder.width;
				nextX += spacer;
				nextX += spacer;
				
				help_locodeco_icon_holder.x = nextX;
				help_locodeco_icon_holder.y = nextY;
				nextX += help_locodeco_icon_holder.width;
				nextX += spacer;
				nextX += spacer;

				// visibility
				stop_edit_icon_holder.visible = true;
				start_edit_icon_holder.visible = true;

				// ability
				save_bt.disabled   = !state.editing_unsaved;
				revert_bt.disabled = !state.editing_unsaved;
				
				if (!locationReady) {
					start_edit_bt.disabled = true;
					stop_edit_icon_holder.visible = false;
					save_bt.disabled = true;
					revert_bt.disabled = true;
				} else if (state.locodeco_loading || state.editing_requesting_lock || state.editing_saving_changes) {
					stop_edit_icon_holder.visible = false;
					save_bt.disabled = true;
					revert_bt.disabled = true;
					stop_edit_bt.disabled = true;
					start_edit_bt.disabled = true;
				} else if (state.editing) {
					stop_edit_bt.disabled = false;
					start_edit_icon_holder.visible = false;
				} else if (state.hand_of_god) {
					start_edit_bt.disabled = true;
					start_edit_icon_holder.visible = true;
					stop_edit_icon_holder.visible = false;
				} else {
					start_edit_bt.disabled = false;
					start_edit_icon_holder.visible = true;
					stop_edit_icon_holder.visible = false;
				}
			}
			
			// draw a separator
			nextX += spacer;
			if (pinned || mouseIsHovering) {
				graphics.lineStyle(0, 0xC6D2D7, 1, true);
				graphics.moveTo(nextX, nextY+2*spacer);
				graphics.lineTo(nextX, nextY+r.height-2*spacer);
			}
			nextX += spacer;
			nextX += spacer;
			
			// hand of god
			stop_hand_of_god_icon_holder.x = nextX;
			stop_hand_of_god_icon_holder.y = nextY;
			
			start_hand_of_god_icon_holder.x = nextX;
			start_hand_of_god_icon_holder.y = nextY;
			
			nextX += stop_hand_of_god_icon_holder.width;
			nextX += spacer;
			
			stop_hand_of_god_icon_holder.visible  =  state.hand_of_god;
			start_hand_of_god_icon_holder.visible = !state.hand_of_god;
			
			start_hand_of_god_bt.disabled = show_platlines_bt.disabled;
			stop_hand_of_god_bt.disabled  = show_platlines_bt.disabled;
			
			// platlines
			hide_platlines_icon_holder.x = nextX;
			hide_platlines_icon_holder.y = nextY;
			
			show_platlines_icon_holder.x = nextX;
			show_platlines_icon_holder.y = nextY;
			
			nextX += hide_platlines_icon_holder.width;
			nextX += spacer;
			
			hide_platlines_icon_holder.visible = !state.hide_platforms;
			show_platlines_icon_holder.visible =  state.hide_platforms;
			
			show_platlines_bt.disabled = state.editing || !locationReady;
			hide_platlines_bt.disabled = show_platlines_bt.disabled;
			
			// geo
			geo_icon_holder.x = nextX;
			geo_icon_holder.y = nextY;
			geo_bt.disabled = !locationReady;
			
			nextX += geo_icon_holder.width;
			nextX += spacer;
			
			// draw a separator
			nextX += spacer;
			if (pinned || mouseIsHovering) {
				graphics.lineStyle(0, 0xC6D2D7, 1, true);
				graphics.moveTo(nextX, nextY+2*spacer);
				graphics.lineTo(nextX, nextY+r.height-2*spacer);
			}
			nextX += spacer;
			nextX += spacer;
			nextX += spacer;
			
			// renderer
			renderer_vector_icon_holder.x = nextX;
			renderer_vector_icon_holder.y = nextY;
			renderer_vector_bt.disabled = (TSModelLocator.instance.moveModel.rebuilding_location || (!locationReady) || CONFIG::locodeco);
			renderer_vector_icon_holder.visible = (state.render_mode == RenderMode.VECTOR);
			
			renderer_bitmap_icon_holder.x = nextX;
			renderer_bitmap_icon_holder.y = nextY;
			renderer_bitmap_bt.disabled = renderer_vector_bt.disabled;
			renderer_bitmap_icon_holder.visible = (state.render_mode == RenderMode.BITMAP);
			
			nextX += renderer_vector_icon_holder.width;
			nextX += spacer;
			
			// draw a separator
			nextX += spacer;
			nextX += spacer;
			if (pinned || mouseIsHovering) {
				graphics.lineStyle(0, 0xC6D2D7, 1, true);
				graphics.moveTo(nextX, nextY+2*spacer);
				graphics.lineTo(nextX, nextY+r.height-2*spacer);
			}
			nextX += spacer;
			
			pin_cb.x = nextX;
			pin_cb.y = nextY;
			
			drag_holder.x = nextX;
			drag_holder.y = nextY;
		}
		
		CONFIG::locodeco private function onHelpLocodecoClick(event:TSEvent):void {
			const url:String = "https://docs.google.com/leaf?id=175-y2qjNWHFxxWZApSF4Pw0mtwn0OpHQ9VIJe_hJeis";
			navigateToURL(new URLRequest(url), URLUtil.getTarget('ldhelp'));
		}
		
		CONFIG::locodeco private function onSaveClick(event:TSEvent):void {
			if (!save_bt.disabled) TSFrontController.instance.saveLocoDecoChanges();
		}
		
		CONFIG::locodeco private function onRevertClick(event:TSEvent):void {
			if (!revert_bt.disabled) TSFrontController.instance.revertLocoDecoChanges();
		}
		
		private function onStartEditClick(event:TSEvent):void {
			if (CONFIG::locodeco) {
				if (!start_edit_bt.disabled) {
					TSFrontController.instance.startEditMode();
				}
			} else {
				 const cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
				 cdVO.callback = function(value:*):void {
					 if (value == true) {
						 // redirect to LOCODEV client
						 var argsA:Array = [];
						 var URLAndQSArgs:Object = EnvironmentUtil.getURLAndQSArgs();
						 var url:String = URLAndQSArgs.url+'?';
						 for (var k:String in URLAndQSArgs.args) {
							 if (k == 'SWF_which') continue;
							 if (k == 'SWF_edit_loc') continue;
							 argsA.push(k+'='+URLAndQSArgs.args[k])
						 }
						 url+= argsA.sort().join('&')+'&SWF_which=LOCODEV&SWF_edit_loc=1';
						 navigateToURL(new URLRequest(url), '_self');
					 }
				 }
				 cdVO.txt = "You'll have to reload the LOCODEV client, savvy?";
				 cdVO.choices = [
					 {value: true,  label: 'Savvy!'},
					 {value: false, label: 'Nay-vermind...'}
				 ];
				 cdVO.escape_value = false;
				 TSFrontController.instance.confirm(cdVO);
			}
			refresh();
		}
		
		CONFIG::locodeco private function onStopEditClick(event:TSEvent):void {
			if (!stop_edit_bt.disabled) TSFrontController.instance.stopEditMode();
			refresh();
		}
		
		private function onShowPlatlinesClick(event:TSEvent):void {
			if (!show_platlines_bt.disabled) TSFrontController.instance.showPlatformLinesEtc();
			refresh();
		}
		
		private function onHidePlatlinesClick(event:TSEvent):void {
			if (!hide_platlines_bt.disabled) TSFrontController.instance.hidePlatformLinesEtc();
			refresh();
		}
		
		private function onStartHandOfGodClick(event:TSEvent):void {
			if (!start_hand_of_god_bt.disabled) TSFrontController.instance.startHandOfGodMode();
			refresh();
		}
		
		private function onStopHandOfGodClick(event:TSEvent):void {
			if (!stop_hand_of_god_bt.disabled) TSFrontController.instance.stopHandOfGodMode();
			refresh();
		}
		
		public function switchRenderer(event:TSEvent = null):void {
			if (renderer_vector_bt.disabled) return;
			
			const currentRendererIndex:int = availableRenderers.indexOf(TSModelLocator.instance.stateModel.render_mode);
			if (currentRendererIndex == -1) throw new Error("Unrecognized RenderMode");
			
			const nextRendererIndex:int = ((currentRendererIndex + 1) % availableRenderers.length);
			LocationCommands.changeRenderMode(availableRenderers[nextRendererIndex]);
			
			refresh();
		}
		
		private function createButton(callback:Function, normal:DisplayObject, disabled:DisplayObject, name:String, tip:String):Button {
			const btn:Button = new Button({
				label: '',
				w: normal.width,
				h: normal.height,
				name: name,
				draw_alpha: 0,
				graphic: normal,
				graphic_disabled: disabled,
				tip: {
					txt: tip, 
					pointer:WindowBorder.POINTER_TOP_CENTER,
					offset_y: 10
				}
			});
			btn.addEventListener(TSEvent.CHANGED, callback, false, 0, true);
			return btn;
		}
		
		public function getTip(tip_target:DisplayObject=null):Object {
			return {
				txt: (pinned ? "Don't keep visible" : "Keep visible"),
				pointer: WindowBorder.POINTER_TOP_CENTER
			}
		}
		
		private function onDragMouseDown(e:MouseEvent):void {
			const globalPt:Point = stage.localToGlobal(StageBeacon.stage_mouse_pt);
			const miniMapPt:Point = globalToLocal(globalPt);
			drag_delta_x = miniMapPt.x;
			drag_delta_y = miniMapPt.y;
			StageBeacon.mouse_move_sig.add(onDragMouseMove);
			StageBeacon.mouse_up_sig.add(onDragMouseUp);
		}

		private function onDragMouseMove(e:MouseEvent):void {
			const globalPt:Point = stage.localToGlobal(StageBeacon.stage_mouse_pt);
			const parentPt:Point = parent.globalToLocal(globalPt);
			editing_x = parentPt.x - drag_delta_x;
			editing_y = parentPt.y - drag_delta_y;
			refresh();
		}
		
		private function onDragMouseUp(e:*):void {
			StageBeacon.mouse_move_sig.remove(onDragMouseMove);
			StageBeacon.mouse_up_sig.remove(onDragMouseUp);
		}
	}
}
