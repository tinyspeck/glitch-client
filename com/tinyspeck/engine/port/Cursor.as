package com.tinyspeck.engine.port {
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.SimplePanel;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.utils.getQualifiedClassName;
	
	public class Cursor extends Sprite implements IFocusableComponent {
		/* singleton boilerplate */
		public static const instance:Cursor = new Cursor();
		
		public var is_dragging:Boolean = false;
		public var drag_DO:DisplayObject;
		
		private var model:TSModelLocator;
		private var simple_panel:SimplePanel = new SimplePanel();
		
		public function Cursor():void {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			mouseChildren = false;
			mouseEnabled = false;
			simple_panel.max_w = 300;
		}
		
		public function init():void {
			model = TSModelLocator.instance;
			registerSelfAsFocusableComponent();
			StageBeacon.stage.addChild(this);
			x = StageBeacon.stage.mouseX;
			y = StageBeacon.stage.mouseY;
			
			var self:Cursor = this;
			StageBeacon.mouse_move_sig.add(onMouseMove);
		}
		
		private function onMouseMove(e:MouseEvent):void {
			x = e.stageX;
			y = e.stageY;
		}
		
		public function showTip(txt:String, center_it:Boolean=false):void {
			if (!txt) {
				hideTip();
				return;
			}
			simple_panel.fillText(txt);
			/*simple_panel.x = -Math.round(simple_panel.width/2);
			simple_panel.y = -simple_panel.height;
			if (drag_DO.parent == this) {
				simple_panel.y-= Math.round((drag_DO.height/2)+10);
			}*/
			
			if (center_it) {
				if (drag_DO.parent == this) {
					// center this on the center of the drag_DO
					var rect:Rectangle = drag_DO.getBounds(this);
					simple_panel.x = Math.round(rect.x+(rect.width/2)-(simple_panel.width/2));
					simple_panel.y = Math.round(rect.y+(rect.height/2)-(simple_panel.height/2));
				} else {
					simple_panel.x = -Math.round(simple_panel.width/2);
					simple_panel.y = -Math.round(simple_panel.height/2);
				}
			} else {
				simple_panel.x = 0;
				simple_panel.y = -Math.round(simple_panel.height/2);
				if (drag_DO.parent == this) {
					simple_panel.x+= Math.round((drag_DO.width/2)+10);
				}
			}
			
			addChild(simple_panel);
		}
		
		public function hideTip():void {
			if (simple_panel.parent) simple_panel.parent.removeChild(simple_panel);
		}
		
		private var cancelFunc:Function;
		public function startDragWith(DO:DisplayObject, no_take_focus:Boolean=false, cancelFunc:Function=null):void {
			endDrag();
			this.cancelFunc = cancelFunc;
			is_dragging = true;
			Mouse.hide();
			addChild(DO);
			this.drag_DO = DO;
			if (!no_take_focus && !TSFrontController.instance.requestFocus(this, getQualifiedClassName(DO))) {
				/*; // satisfy compiler
				CONFIG::debugging {
					Console.warn('could not take focus');
				}*/
			}
			TSFrontController.instance.changeTipsVisibility(false, 'cursor_drag');
			mouseEnabled = true;
		}
		
		public function endDrag():void {
			if (!is_dragging) {
				return;
			}
			
			this.cancelFunc = null;
			
			StageBeacon.clearTimeout(fox_bush_tim);
			
			is_dragging = false;
			if (drag_DO && drag_DO.parent) {
				drag_DO.parent.removeChild(drag_DO);
			}
			drag_DO = null;
			Mouse.show();
			TSFrontController.instance.releaseFocus(this);
			TSFrontController.instance.changeTipsVisibility(true, 'cursor_drag');
			mouseEnabled = false;
		}
		
		public function hasFocus():Boolean {
			return false;
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			
		}
		
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur');
			}
		}
		
		public function registerSelfAsFocusableComponent():void {
			model.stateModel.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			model.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focus():void {
			CONFIG::debugging {
				Console.log(99, 'focus');
			}
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return false;
		}
		
		private var fox_bush_tim:uint;
		public function startedDraggingBrushToFox():void {
			if (!drag_DO) return;
			if (!(drag_DO is ItemIconView)) return;
			var iiv:ItemIconView = drag_DO as ItemIconView;
			
			iiv.icon_animate('waiting');
			
			fox_bush_tim = StageBeacon.setTimeout(function():void {
				iiv.icon_animate('anxious');
				fox_bush_tim = StageBeacon.setTimeout(function():void {
					iiv.icon_animate('panic');
					fox_bush_tim = StageBeacon.setTimeout(function():void {
						if (cancelFunc != null) cancelFunc();
					}, 2000);
				}, 2000);
			}, 4000);
		}
	}
}