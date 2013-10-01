package com.tinyspeck.engine.model {
	import com.tinyspeck.engine.model.signals.AbstractPropertyProvider;
	import com.tinyspeck.engine.port.CSSManager;

	public class LayoutModel extends AbstractPropertyProvider {
		//setup some defaults that can be overwritten by CSS
		public var min_gutter_w:int = 20;
		public var min_header_h:int = 40;
		public var min_vp_w:int = 500;
		public var min_vp_h:int = 400;
		// these may change when editing in locodeco
		public var max_vp_w:int = 1000;
		public var max_vp_h:int = 600;
		// these will never change and hold the original CSS values
		CONFIG::god public var max_vp_w_css:int;
		CONFIG::god public var max_vp_h_css:int;
		public var loc_vp_elipse_radius:int = 6;
		public var right_col_w:int = 300;
		public var bg_color:uint = 0xe6ecee;
		
		/** Represents the CENTER of the viewport in MG coordinates */
		public var loc_cur_x:int;
		/** Represents the CENTER of the viewport in MG coordinates */
		public var loc_cur_y:int;
		public var loc_vp_w:int;
		public var loc_vp_h:int;
		public var loc_vp_rect_collision_scale:Number;
		public var gutter_w:int;
		public var header_h:int;
		public var header_bt_x:int; //when putting buttons in the header, this is where they can be placed
		public var overall_w:int;
		public var pack_itemicon_wh:int = 40;
		public var pack_slot_h:int = 53;
		public var pack_slot_w:int = 51;
		public var pack_slot_wide_w:int = 68;
		public var pack_is_wide:Boolean = true;
		public var familiar_dialog_min_w:int = 330;
		public var buff_view_width:int = 160;
		
		public static const ORIENTATION_DEFAULT:String = 'reset';
		public static const ORIENTATION_VFLIP:String   = 'vflip';
		public static const ORIENTATION_HFLIP:String   = 'hflip';
		public static const ORIENTATION_XFLIP:String   = 'xflip';
		
		private var _loc_vp_orientation:String = ORIENTATION_DEFAULT;
		private var _loc_vp_scale:Number = 1.0;
		private var _loc_vp_scaleX_multiplier:Number = 1.0;
		private var _loc_vp_scaleY_multiplier:Number = 1.0;
		
		public function get loc_vp_orientation():String {
			return _loc_vp_orientation;
		}

		public function set loc_vp_orientation(value:String):void {
			_loc_vp_orientation = value;
			
			// must recompute the loc_vp_scale as it has side-effects
			loc_vp_scale = _loc_vp_scale;
		}

		/** Target scale set by user or GS */
		public function get loc_vp_scale():Number {
			return _loc_vp_scale;
		}

		public function set loc_vp_scale(value:Number):void {
			_loc_vp_scale = value;
			_loc_vp_scaleX_multiplier = 1;
			_loc_vp_scaleY_multiplier = 1;
			switch (loc_vp_orientation) {
				case LayoutModel.ORIENTATION_HFLIP:
					_loc_vp_scaleX_multiplier = -1;
					break;
				case LayoutModel.ORIENTATION_VFLIP:
					_loc_vp_scaleY_multiplier = -1;
					break;
				case LayoutModel.ORIENTATION_XFLIP:
					_loc_vp_scaleX_multiplier = -1;
					_loc_vp_scaleY_multiplier = -1;
					break;
					break;
			}
		}

		/** Either 1 or -1 -- specifies whether that viewport direction should be flipped */
		public function get loc_vp_scaleX_multiplier():Number {
			return _loc_vp_scaleX_multiplier;
		}
		
		/** Either 1 or -1 -- specifies whether that viewport direction should be flipped */
		public function get loc_vp_scaleY_multiplier():Number {
			return _loc_vp_scaleY_multiplier;
		}
		
		public var min_loc_vp_scale:Number = 1.0;
		public var max_loc_vp_scale:Number = 1.0;
		
		public function LayoutModel() {
			//set the values from CSS
			var cssm:CSSManager = CSSManager.instance;
			
			bg_color = cssm.getUintColorValueFromStyle('main_layout', 'backgroundColor', bg_color);
			min_vp_w = cssm.getNumberValueFromStyle('main_layout', 'minViewportWidth', min_vp_w);
			min_vp_h = cssm.getNumberValueFromStyle('main_layout', 'minViewportHeight', min_vp_h);
			max_vp_w = cssm.getNumberValueFromStyle('main_layout', 'maxViewportWidth', max_vp_w);
			max_vp_h = cssm.getNumberValueFromStyle('main_layout', 'maxViewportHeight', max_vp_h);
			CONFIG::god {
				max_vp_w_css = max_vp_w;
				max_vp_h_css = max_vp_h;
			}
			loc_vp_elipse_radius = cssm.getNumberValueFromStyle('main_layout', 'viewportCornerRadius', loc_vp_elipse_radius);
			min_header_h = cssm.getNumberValueFromStyle('main_layout', 'minHeaderHeight', min_header_h);
			min_gutter_w = cssm.getNumberValueFromStyle('main_layout', 'minGutterWidth', min_gutter_w);
			right_col_w = cssm.getNumberValueFromStyle('main_layout', 'rightColWidth', right_col_w);
		}
	}
}