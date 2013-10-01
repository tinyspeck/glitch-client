package com.tinyspeck.engine.admin.locodeco {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.view.IFocusableComponent;
	
	import locodeco.LocoDecoGlobals;

	public class LocoDecoSideBar extends TSSpriteWithModel implements IFocusableComponent {
		/* singleton boilerplate */
		public static const instance:LocoDecoSideBar = new LocoDecoSideBar();
		
		private static const swf:LocoDecoSWFBridge = LocoDecoSWFBridge.instance;
		private var has_focus:Boolean = false;
		
		public function LocoDecoSideBar() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		override public function get w():int {
			return _w;
		}
		
		override public function get h():int {
			return _h;
		}
		
		public function init():void {
			registerSelfAsFocusableComponent();
			
			// editingChangeHandler gets called when edit mode changes e.g. when the started editing button is pushed initially
			model.stateModel.registerCBProp(editingChangeHandler, 'editing');
			
			swf.x = 5;
			swf.y = 0;
			addChild(swf);
			refresh();
		}
		
		public function refresh():void {
			x = model.layoutModel.loc_vp_w;
			
			_w = model.layoutModel.right_col_w;
			_h = StageBeacon.stage.stageHeight - model.layoutModel.header_h;
			
			if (swf.isInititalized) {
				swf.refresh();
			}
		}
		
		private function editingChangeHandler(editing:Boolean):void {
			if (editing && !swf.isInititalized) swf.init();
			if (editing) {
				TSFrontController.instance.requestFocus(this);
			} else {
				TSFrontController.instance.releaseFocus(this);
			}
		}
		
		// IFocusableComponent stuff ---------------------------------------------------
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function hasFocus():Boolean {
			return has_focus;
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur');
			}
			TSFrontController.instance.changeTipsVisibility(true, 'LOCODECOSIDEBAR');
			has_focus = false;
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
			TSFrontController.instance.changeTipsVisibility(LocoDecoGlobals.instance.toolTips, 'LOCODECOSIDEBAR');
			has_focus = true;
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			//
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return false;
		}
		
		// END IFocusableComponent stuff ---------------------------------------------------
	}
}
