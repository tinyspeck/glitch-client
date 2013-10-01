package com.tinyspeck.engine.view.ui {
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	
	import flash.display.*;
	import flash.events.*;
	import flash.filters.BevelFilter;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	
	public class Button extends FormElement implements ITipProvider {
		
		public static const SIZE_DEFAULT:String = 'default';
		public static const SIZE_TINY:String = 'tiny';
		public static const SIZE_MICRO:String = 'micro';
		public static const SIZE_MICRO_NO_SHADOW:String = 'micro_no_shadow';
		public static const SIZE_VERB:String = 'verb';
		public static const SIZE_COUNT:String = 'count';
		public static const SIZE_50:String = '50';
		public static const SIZE_FAMILIAR:String = 'familiar';
		public static const SIZE_CONVERSATION:String = 'conversation';
		public static const SIZE_ELEVATOR_GRODDLE:String = 'elevator_groddle';
		public static const SIZE_QTY_MAX:String = 'qty_max';
		public static const SIZE_QTY_GO:String = 'qty_go';
		public static const SIZE_CHAT:String = 'chat';
		public static const SIZE_CIRCLE:String = 'circle';
		public static const SIZE_MAKING_RECIPE:String = 'making_recipe';
		public static const SIZE_TRANSIT_LINE:String = 'transit_line';
		public static const SIZE_PACK_TAB:String = 'pack_tab';
		public static const SIZE_GLITCHR:String = 'glitchr';
		
		public static const TYPE_VERB:String = 'verb';
		public static const TYPE_DEFAULT:String = 'default';
		public static const TYPE_MINOR:String = 'minor';
		public static const TYPE_MINOR_BORDER:String = 'minor_border';
		public static const TYPE_MINOR_INVIS:String = 'minor_invis';
		public static const TYPE_MINOR_DIM:String = 'minor_dim';
		public static const TYPE_ALT:String = 'alt';
		public static const TYPE_DARK:String = 'dark';
		public static const TYPE_DISABLED:String = 'disabled';
		public static const TYPE_LEFT:String = 'left';
		public static const TYPE_MIDDLE:String = 'middle';
		public static const TYPE_RIGHT:String = 'right';
		public static const TYPE_SINGLE:String = 'single';
		public static const TYPE_BACK:String = 'back';
		public static const TYPE_FAMILIAR:String = 'familiar';
		public static const TYPE_TELEPORT:String = 'teleport';
		public static const TYPE_TELEPORT_NEW:String = 'teleport_new';
		public static const TYPE_QTY:String = 'qty';
		public static const TYPE_QTY_GO:String = 'qty_go';
		public static const TYPE_QUARTER:String = 'quarter';
		public static const TYPE_QUARTER_DISABLED:String = 'quarter_disabled';
		public static const TYPE_ELEVATOR_GRODDLE:String = 'elevator_groddle';
		public static const TYPE_CANCEL:String = 'cancel';
		public static const TYPE_TAB:String = 'tab';
		public static const TYPE_INPUT_ACCEPT:String = 'input_accept';
		public static const TYPE_CHAT_ACTIVE:String = 'chat_active';
		public static const TYPE_MAKING_RECIPE:String = 'making_recipe';
		public static const TYPE_SEARCH_RESULT:String = 'search_result';
		public static const TYPE_TRANSIT_LINE:String = 'transit_line';
		public static const TYPE_BROWN:String = 'brown';
		public static const TYPE_ACL_TAB:String = 'acl_tab';
		public static const TYPE_SWATCH_PANEL:String = 'swatch_panel';
		public static const TYPE_PACK_TAB:String = 'pack_tab';
		public static const TYPE_PACK_FILTER:String = 'pack_filter';
		public static const TYPE_PACK_SCROLL:String = 'pack_scroll';
		public static const TYPE_DECORATE:String = 'decorate';
		public static const TYPE_GLITCHR:String = 'glitchr';
		public static const TYPE_GREY_DROP:String = 'grey_drop';
		public static const TYPE_TWITTER:String = 'twitter';
		public static const TYPE_FACEBOOK:String = 'facebook';
		public static const TYPE_CREATE_ACCOUNT:String = 'create_account';
		public static const TYPE_INFO_TAB:String = 'info_tab';
		
		protected var _graphic_padd_t:int = 4;
		protected var _graphic_padd_b:int = 4;
		protected var _graphic_padd_l:int = 4;
		protected var _graphic_padd_r:int = 4;
		protected var _default_tf_padd_w:int = 4;
		protected var _focus_shadow_distance:int = 3;
		protected var _padd_w:int = 10; // for when _w and _h are not specified
		protected var _padd_h:int = 2; // for when _w and _h are not specified
		protected var _pressed:Boolean = false;
		protected var _no_border:Boolean = false;
		protected var _corner_rad_tl:int = 0;
		protected var _corner_rad_tr:int = 0;
		protected var _corner_rad_bl:int = 0;
		protected var _corner_rad_br:int = 0;
		protected var _inner_shad_c:Number;
		protected var _outer_shadow:Object = new Object();
		protected var _graphic:DisplayObject;
		protected var _graphic_disabled:DisplayObject;
		protected var _graphic_disabled_hover:DisplayObject;
		protected var _graphic_hover:DisplayObject;
		protected var _shape:Shape = new Shape();
		protected var _tip:Object;
		protected var _text_align:String = 'center';
		protected var _disabled_graphic_alpha:Number = 1;
		protected var _focused_graphic_alpha:Number = 1;
		protected var _graphic_alpha:Number = 1;
		protected var _draw_alpha:Number = 1;
		protected var _disabled_draw_alpha:Number = 1;
		protected var _disabled_focus_draw_alpha:Number = 1;
		protected var _focus_draw_alpha:Number = 1;
		protected var _label_alpha:Number = 1;
		protected var _label_shadow:Object = new Object();
		protected var _label_glow:Object = new Object();
		protected var _border_glow:Object = new Object();
		protected var _focus_label_alpha:Number = 1;
		protected var _disabled_label_alpha:Number = 1;
		protected var _disabled_label_hover_alpha:Number = 1;
		protected var _draw_from_css:Boolean = false;
		protected var _show_disabled_pattern:Boolean = false;
		protected var _label_offset:int;
		protected var _is_circle:Boolean;
		protected var bevel:BevelFilter;
		protected var bevel_holder:Sprite = new Sprite();
		protected var shadow:DropShadowFilter = new DropShadowFilter();
		protected var shadow2:DropShadowFilter = new DropShadowFilter();
		protected var label_glow:GlowFilter = new GlowFilter();
		protected var border_glow:GlowFilter = new GlowFilter();
		
		private var disabled_shape:Shape = new Shape();
		private var border_drawn:Boolean = false;
		private var _size:String;
		private var _type:String;
		private var _disabled_pattern:BitmapData;
		private var waiting_spinner:Sprite = new Sprite();
		
		public function Button(init_ob:Object):void {
			super(init_ob);
			
			mouseChildren = false;
			waiting_spinner.visible = false;
			
			_construct();
			
			//force a redraw to avoid the text from "jumping" on hover
			focus();
			blur();
		}
		
		override protected function _construct():void {
			x = _init_ob.x || 0;
			y = _init_ob.y || 0;
			if (_init_ob.hasOwnProperty('graphic_alpha')) _graphic_alpha = _init_ob.graphic_alpha;
			if (_init_ob.hasOwnProperty('focused_graphic_alpha')) _focused_graphic_alpha = _init_ob.focused_graphic_alpha;
			if (_init_ob.hasOwnProperty('disabled_graphic_alpha')) _disabled_graphic_alpha = _init_ob.disabled_graphic_alpha;
			if (_init_ob.hasOwnProperty('inner_shad_c')) _inner_shad_c = _init_ob.inner_shad_c;
			if (_init_ob.hasOwnProperty('text_align')) _text_align = _init_ob.text_align;
			
			if (_init_ob.hasOwnProperty('draw_alpha')) _draw_alpha = _focus_draw_alpha = _disabled_draw_alpha = _disabled_focus_draw_alpha = _init_ob.draw_alpha;
			if (_init_ob.hasOwnProperty('focus_draw_alpha')) _focus_draw_alpha = _init_ob.focus_draw_alpha;
			if (_init_ob.hasOwnProperty('disabled_draw_alpha')) _disabled_draw_alpha = _disabled_label_alpha = _disabled_label_hover_alpha = _init_ob.disabled_draw_alpha;
			if (_init_ob.hasOwnProperty('disabled_focus_draw_alpha')) _disabled_focus_draw_alpha = _init_ob.disabled_focus_draw_alpha;
			
			if (_init_ob.hasOwnProperty('focus_shadow_distance')) _focus_shadow_distance = _init_ob.focus_shadow_distance;
			if (_init_ob.hasOwnProperty('no_border')) _no_border = _init_ob.no_border;
			
			if (_init_ob.hasOwnProperty('label_alpha')) _label_alpha = _focus_label_alpha = _init_ob.label_alpha;
			if (_init_ob.hasOwnProperty('focus_label_alpha')) _focus_label_alpha = _init_ob.focus_label_alpha;
			if (_init_ob.hasOwnProperty('disabled_label_alpha')) _disabled_label_alpha = _disabled_label_hover_alpha = _init_ob.disabled_label_alpha;
			if (_init_ob.hasOwnProperty('disabled_label_hover_alpha')) _disabled_label_hover_alpha = _init_ob.disabled_label_hover_alpha;
			if (_init_ob.hasOwnProperty('corner_radius')) _corner_rad_tl = _corner_rad_tr = _corner_rad_bl = _corner_rad_br = parseFloat(_init_ob.corner_radius);
			if (_init_ob.hasOwnProperty('show_disabled_pattern')) _show_disabled_pattern = _init_ob.show_disabled_pattern;
			if (_init_ob.hasOwnProperty('label_offset')) _label_offset = _init_ob.label_offset;
			if (_init_ob.hasOwnProperty('default_tf_padd_w')) _default_tf_padd_w = _init_ob.default_tf_padd_w;
			if (_init_ob.hasOwnProperty('offset_x')) _offset_x = _init_ob.offset_x;
			if (_init_ob.hasOwnProperty('disabled_pattern') && _init_ob.disabled_pattern is BitmapData) {
				_disabled_pattern = _init_ob.disabled_pattern;
				_show_disabled_pattern = true;
			}
			
			if (_init_ob.hasOwnProperty('tip') && _init_ob.tip) {
				_tip = _init_ob.tip;
				TipDisplayManager.instance.registerTipTrigger(this);
			}
			
			if(_init_ob.hasOwnProperty('show_bevel') && Boolean(_init_ob.show_bevel)){
				//show a bevel on the button
				bevel = new BevelFilter();
				bevel.highlightColor = _init_ob.hasOwnProperty('bevel_highlight_c') ? _init_ob.bevel_highlight_c : 0xffffff;
				bevel.highlightAlpha = _init_ob.hasOwnProperty('bevel_highlight_a') ? _init_ob.bevel_highlight_a : .5;
				bevel.shadowColor = _init_ob.hasOwnProperty('bevel_shadow_c') ? _init_ob.bevel_shadow_c : 0x000000;
				bevel.shadowAlpha = _init_ob.hasOwnProperty('bevel_shadow_a') ? _init_ob.bevel_shadow_a : .5;
				bevel.angle = _init_ob.hasOwnProperty('bevel_angle') ? _init_ob.bevel_angle : 90;
				bevel.blurX = bevel.blurY = _init_ob.hasOwnProperty('bevel_blur') ? _init_ob.bevel_blur : 0;
				bevel.distance = _init_ob.hasOwnProperty('bevel_distance') ? _init_ob.bevel_distance : 2;
				bevel.knockout = true;
				
				bevel_holder.filters = [bevel];
			}
			
			super._construct();
			
			addChild(_shape);
						
			TFUtil.prepTF(_label_tf);
			
			_graphic_padd_l = (_init_ob.hasOwnProperty('graphic_padd_w')) ? _init_ob.graphic_padd_w : _graphic_padd_l;
			_graphic_padd_l = (_init_ob.hasOwnProperty('graphic_padd_l')) ? _init_ob.graphic_padd_l : _graphic_padd_l;
			_graphic_padd_r = (_init_ob.hasOwnProperty('graphic_padd_r')) ? _init_ob.graphic_padd_r : _graphic_padd_l;
			_graphic_padd_t = (_init_ob.hasOwnProperty('graphic_padd_t')) ? _init_ob.graphic_padd_t : _graphic_padd_t;
			_graphic_padd_b = (_init_ob.hasOwnProperty('graphic_padd_b')) ? _init_ob.graphic_padd_b : _graphic_padd_b;
			
			if (_init_ob.graphic && _init_ob.graphic is DisplayObject) {
				_graphic = _init_ob.graphic;
				addChild(_graphic);
				_graphic.visible = false;
				
				// if it has not loaded, listen for complete event and position it then
				if (_graphic.width == 0 && _graphic.height == 0) {
					_graphic.addEventListener(TSEvent.COMPLETE, _graphicLoadHandler, false, 0, true);
				} else {
					if (_graphic.hasOwnProperty('addEventListener')) _graphic.addEventListener(Event.COMPLETE, _graphicLoadHandler, false, 0, true);
					_placeGraphic();
				}
			}
			
			if (_init_ob.graphic_disabled && _init_ob.graphic_disabled is DisplayObject) {
				_graphic_disabled = _init_ob.graphic_disabled;
				addChild(_graphic_disabled);
				_graphic_disabled.visible = false;
				
				// if it has not loaded, listen for complete event and position it then
				if (_graphic_disabled.width == 0 && _graphic_disabled.height == 0) {
					_graphic_disabled.addEventListener(TSEvent.COMPLETE, _graphic_disabledLoadHandler);
				} else {
					if (_graphic_disabled.hasOwnProperty('addEventListener')) _graphic_disabled.addEventListener(Event.COMPLETE, _graphic_disabledLoadHandler, false, 0, true);
					_placeGraphic_disabled();
				}
			}
			
			if (_init_ob.graphic_disabled_hover && _init_ob.graphic_disabled_hover is DisplayObject) {
				_graphic_disabled_hover = _init_ob.graphic_disabled_hover;
				addChild(_graphic_disabled_hover);
				_graphic_disabled_hover.visible = false;
				
				// if it has not loaded, listen for complete event and position it then
				if (_graphic_disabled_hover.width == 0 && _graphic_disabled_hover.height == 0) {
					_graphic_disabled_hover.addEventListener(TSEvent.COMPLETE, _graphic_disabled_hoverLoadHandler);
				} else {
					if (_graphic_disabled_hover.hasOwnProperty('addEventListener')) _graphic_disabled_hover.addEventListener(Event.COMPLETE, _graphic_disabled_hoverLoadHandler, false, 0, true);
					_placeGraphic_disabled_hover();
				}
			}
			
			if (_init_ob.graphic_hover && _init_ob.graphic_hover is DisplayObject) {
				_graphic_hover = _init_ob.graphic_hover;
				addChild(_graphic_hover);
				_graphic_hover.visible = false;
				
				// if it has not loaded, listen for complete event and position it then
				if (_graphic_hover.width == 0 && _graphic_hover.height == 0) {
					_graphic_hover.addEventListener(TSEvent.COMPLETE, _graphic_hoverLoadHandler);
				} else {
					if (_graphic_hover.hasOwnProperty('addEventListener')) _graphic_hover.addEventListener(Event.COMPLETE, _graphic_hoverLoadHandler, false, 0, true);
					_placeGraphic_hover();
				}
			}
			
			label = _init_ob.label || '';
			if (_init_ob.label) addChild(_label_tf);
			
			if (_init_ob.hasOwnProperty('size') || _init_ob.hasOwnProperty('type')) setSizeAndType(_init_ob.size, _init_ob.type);
			
			//do we need to show the disabled pattern over the button?
			if(_show_disabled_pattern){
				if(!_disabled_pattern) createDisabledPattern();
				addChild(disabled_shape);
			}
			
			//setup the bevel holder
			bevel_holder.mouseEnabled = false;
			bevel_holder.visible = bevel ? true : false;
			addChild(bevel_holder);
		}
		
		override protected function _deconstruct():void {
			TipDisplayManager.instance.unRegisterTipTrigger(this);
			super._deconstruct();
		}
		
		private function _graphicLoadHandler(e:Event):void {
			_placeGraphic();
			label = _init_ob.label || '';
		}
		
		private function _graphic_disabledLoadHandler(e:Event):void {
			_placeGraphic_disabled();
			label = _init_ob.label || '';
		}
		
		private function _graphic_disabled_hoverLoadHandler(e:Event):void {
			_placeGraphic_disabled_hover();
			label = _init_ob.label || '';
		}
		
		private function _graphic_hoverLoadHandler(e:Event):void {
			_placeGraphic_hover();
			label = _init_ob.label || '';
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			return _tip;
		}
		
		private function _placeGraphic():void {
			if(!_graphic) return;
			
			var w:int = _w > 0 ? _w : width;
			var h:int = _h > 0 ? _h : height;
			
			if (_init_ob.graphic_placement == 'left') {
				_graphic.y = _init_ob.hasOwnProperty('graphic_padd_t') ? _graphic_padd_t : Math.round((h-_graphic.height)/2);
				_graphic.x = _graphic_padd_l;
			} 
			else if (_init_ob.graphic_placement == 'top') {
				_graphic.y = _graphic_padd_t;
				_graphic.x = _init_ob.hasOwnProperty('graphic_padd_w') || _init_ob.hasOwnProperty('graphic_padd_l') ? _graphic_padd_l : Math.floor((w-_graphic.width)/2);
			} 
			else if (_init_ob.graphic_placement == 'center') {
				//Console.warn(_w+'x'+_h+' '+_graphic.width+'x'+_graphic.height)
				_graphic.x = Math.floor((w-_graphic.width)/2);
				_graphic.y = Math.floor((h-_graphic.height)/2);
			}
			else if (_init_ob.graphic_placement == 'right') {
				_graphic.y = _init_ob.hasOwnProperty('graphic_padd_t') ? _graphic_padd_t : Math.round((h-_graphic.height)/2);
				_graphic.x = int(w-_graphic.width-_graphic_padd_r);
			}
			else {
				_graphic.x = _init_ob.hasOwnProperty('graphic_padd_w') ? _graphic_padd_l : Math.floor((w-_graphic.width)/2);
				_graphic.y = _init_ob.hasOwnProperty('graphic_padd_t') ? _graphic_padd_t : Math.round((h-_graphic.height)/2);
			}
		}
		
		private function _placeGraphic_disabled():void {
			if(!_graphic_disabled) return;
			
			var w:int = _w > 0 ? _w : width;
			var h:int = _h > 0 ? _h : height;
			
			if (_init_ob.graphic_placement == 'left') {
				_graphic_disabled.y = _init_ob.hasOwnProperty('graphic_padd_t') ? _graphic_padd_t : Math.round((h-_graphic_disabled.height)/2);
				_graphic_disabled.x = _graphic_padd_l;
			} 
			else if (_init_ob.graphic_placement == 'top') {
				_graphic_disabled.y = _graphic_padd_t;
				_graphic_disabled.x = _init_ob.hasOwnProperty('graphic_padd_w') || _init_ob.hasOwnProperty('graphic_padd_l') ? _graphic_padd_l : Math.floor((w-_graphic_disabled.width)/2);
			}
			else if (_init_ob.graphic_placement == 'center') {
				//Console.warn(_w+'x'+_h+' '+_graphic.width+'x'+_graphic.height)
				_graphic_disabled.x = Math.floor((w-_graphic_disabled.width)/2);
				_graphic_disabled.y = Math.floor((h-_graphic_disabled.height)/2);
			}
			else if (_init_ob.graphic_placement == 'right') {
				_graphic_disabled.y = _init_ob.hasOwnProperty('graphic_padd_t') ? _graphic_padd_t : Math.round((h-_graphic_disabled.height)/2);
				_graphic_disabled.x = int(w-_graphic_disabled.width-_graphic_padd_r);
			}
			else {
				_graphic_disabled.x = _init_ob.hasOwnProperty('graphic_padd_w') ? _graphic_padd_l : Math.floor((w-_graphic_disabled.width)/2);
				_graphic_disabled.y = _init_ob.hasOwnProperty('graphic_padd_t') ? _graphic_padd_t : Math.round((h-_graphic_disabled.height)/2);
			}
		}
		
		private function _placeGraphic_disabled_hover():void {
			if(!_graphic_disabled_hover) return;
			
			var w:int = _w > 0 ? _w : width;
			var h:int = _h > 0 ? _h : height;
			
			if (_init_ob.graphic_placement == 'left') {
				_graphic_disabled_hover.y = _init_ob.hasOwnProperty('graphic_padd_t') ? _graphic_padd_t : Math.round((h-_graphic_disabled_hover.height)/2);
				_graphic_disabled_hover.x = _graphic_padd_l;
			} 
			else if (_init_ob.graphic_placement == 'top') {
				_graphic_disabled_hover.y = _graphic_padd_t;
				_graphic_disabled_hover.x = _init_ob.hasOwnProperty('graphic_padd_w') || _init_ob.hasOwnProperty('graphic_padd_l') ? _graphic_padd_l : Math.floor((w-_graphic_disabled_hover.width)/2);
			}
			else if (_init_ob.graphic_placement == 'center') {
				//Console.warn(_w+'x'+_h+' '+_graphic.width+'x'+_graphic.height)
				_graphic_disabled_hover.x = Math.floor((w-_graphic_disabled_hover.width)/2);
				_graphic_disabled_hover.y = Math.floor((h-_graphic_disabled_hover.height)/2);
			}
			else if (_init_ob.graphic_placement == 'right') {
				_graphic_disabled_hover.y = _init_ob.hasOwnProperty('graphic_padd_t') ? _graphic_padd_t : Math.round((h-_graphic_disabled_hover.height)/2);
				_graphic_disabled_hover.x = int(w-_graphic_disabled_hover.width-_graphic_padd_r);
			}
			else {
				_graphic_disabled_hover.x = _init_ob.hasOwnProperty('graphic_padd_w') ? _graphic_padd_l : Math.floor((w-_graphic_disabled_hover.width)/2);
				_graphic_disabled_hover.y = _init_ob.hasOwnProperty('graphic_padd_t') ? _graphic_padd_t : Math.round((h-_graphic_disabled_hover.height)/2);
			}
		}
		
		private function _placeGraphic_hover():void {
			if(!_graphic_hover) return;
			
			var w:int = _w > 0 ? _w : width;
			var h:int = _h > 0 ? _h : height;
			
			if (_init_ob.graphic_placement == 'left') {
				_graphic_hover.y = _init_ob.hasOwnProperty('graphic_padd_t') ? _graphic_padd_t : Math.round((h-_graphic_hover.height)/2);
				_graphic_hover.x = _graphic_padd_l;
			} 
			else if (_init_ob.graphic_placement == 'top') {
				_graphic_hover.y = _graphic_padd_t;
				_graphic_hover.x = _init_ob.hasOwnProperty('graphic_padd_w') || _init_ob.hasOwnProperty('graphic_padd_l') ? _graphic_padd_l : Math.floor((w-_graphic_hover.width)/2);
			}
			else if (_init_ob.graphic_placement == 'center') {
				//Console.warn(_w+'x'+_h+' '+_graphic.width+'x'+_graphic.height)
				_graphic_hover.x = Math.floor((w-_graphic_hover.width)/2);
				_graphic_hover.y = Math.floor((h-_graphic_hover.height)/2);
			}
			else if (_init_ob.graphic_placement == 'right') {
				_graphic_hover.y = _init_ob.hasOwnProperty('graphic_padd_t') ? _graphic_padd_t : Math.round((h-_graphic_hover.height)/2);
				_graphic_hover.x = int(w-_graphic_hover.width-_graphic_padd_r);
			}
			else {
				_graphic_hover.x = _init_ob.hasOwnProperty('graphic_padd_w') ? _graphic_padd_l : Math.floor((w-_graphic_hover.width)/2);
				_graphic_hover.y = _init_ob.hasOwnProperty('graphic_padd_t') ? _graphic_padd_t : Math.round((h-_graphic_hover.height)/2);
			}
		}
		
		override protected function _addedToStageHandler(e:Event):void {
			super._addedToStageHandler(e);
		}
		
		override protected function _clickHandler(e:MouseEvent):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
		}
		
		public override function blur():void {
			super.blur();
			_draw();
		}
		
		public override function focus():void {
			super.focus();
			_draw();
		}
		
		public function press():void {
			_focused = true; // hrmm. this might cause trouble when progrmatically pressing (vs a mouse press)
			_pressed = true;
			_draw();
		}
		
		public function release():void {
			_pressed = false;
			_draw();
		}
		
		override protected function _downHandler(e:MouseEvent):void {
			super._downHandler(e);
			press();
			_pressed = true;
			_draw();
		}
		
		override protected function _upHandler(e:MouseEvent):void {
			super._upHandler(e);
			release();
		}
		
		public function set tip(t:Object):void {
			_tip = t;
			if (_tip) {
				TipDisplayManager.instance.registerTipTrigger(this);
			} else {
				TipDisplayManager.instance.unRegisterTipTrigger(this);
			}
		}
		
		public function get tip():Object {
			return _tip;
		}
		
		public function set color(c:Number):void {
			_c = c;
			_draw();
		}
		
		public override function set label(lab:String):void {			
			_init_ob.label = lab;
			if (!_label_tf.parent && lab) addChild(_label_tf);
			if (!lab && _label_tf.parent) removeChild(_label_tf)
			//put the string in the tf
			populateLabel();
			
			//make a default big-ass width so text can't wrap easy
			//_label_tf.width = 1000;
			_label_tf.multiline = _label_tf.wordWrap = false;
			var avail_w:int = _w-(_default_tf_padd_w);
			
			if (_w && _label_tf.x + _label_tf.width > avail_w) {
				// subtract the graphic size from the available width is needed
				if (_init_ob.graphic_placement == 'left' && _graphic && _graphic.parent) {
					avail_w-= _graphic.x+_graphic.width+_graphic_padd_l;
				} 
				else if (_init_ob.graphic_placement == 'top' && _graphic && _graphic.parent) {
					avail_w-= _default_tf_padd_w;
				} 
				else {
					avail_w-= _default_tf_padd_w;
				}
				//if (name == '8') Console.warn('and then  '+avail_w)
				_label_tf.multiline = _label_tf.wordWrap = true;
				_label_tf.width = avail_w;
			} 
			else {
				//if (name == '8') Console.warn('or  '+_label_tf.textWidth)
				//_label_tf.width = _label_tf.textWidth+10; // this used to be 6, and now it has to be 10, or else it forces a wrap? (after embedded fonts)
				//if (name == '8') Console.warn('dubke or  '+_label_tf.textWidth)
			}
						
			//Console.warn('label: '+lab+' w:'+_label_tf.width+' _w:'+_w+' '+_label_tf.htmlText)
			//_label_tf.height = _label_tf.textHeight+4;
			_draw();
		}
		
		private function populateLabel():void {
			var text:String = (_label_bold) ? '<b>'+_init_ob.label+'</b>' : _init_ob.label;
			var c:String = (_disabled) ? '#'+ColorUtil.colorNumToStr(_label_disabled_c) : '#'+ColorUtil.colorNumToStr(_label_c);
			
			_label_tf.embedFonts = _label_face.indexOf('Embed') > -1 || _label_face.indexOf('PF Ronda Seven') > -1;
			// do not center the text if we are left aligning to a graphic
			if (_init_ob.graphic_placement == 'left' && _graphic && _graphic.parent) {
				_label_tf.htmlText = '<p><font face="'+_label_face+'" size="'+_label_size+'" color="'+c+'">'+text+'</font></p>';
			} 
			else if (_init_ob.graphic_placement == 'top' && _graphic && _graphic.parent) {
				_label_tf.htmlText = '<p align="'+_text_align+'"><font face="'+_label_face+'" size="'+_label_size+'" color="'+c+'">'+text+'</font></p>';
			} 
			else {
				_label_tf.htmlText = '<p align="'+_text_align+'"><font face="'+_label_face+'" size="'+_label_size+'" color="'+c+'">'+text+'</font></p>';
			}
			
			//Console.warn(_label_tf.htmlText);
		}
		
		override protected function _draw():void {
			// this used ot at least make the button as big as the textfield plus padd, but no more. NOW we obey w/h always, though the text can go out of bounds
			//var w:int = Math.max(_label_tf.width+(_padd_w*2), _w);
			//var h:int = Math.max(_label_tf.height+(_padd_h*2), _h);
			var w:int = (!isNaN(_w) && _w) ? _w : _label_tf.width+(_padd_w*2);
			var h:int = (!isNaN(_h) && _h) ? _h : _label_tf.height+(_padd_h*2);
						
			if (_focused && _graphic_disabled_hover){
				if (!is_spinning) _graphic_disabled_hover.visible = true;
				_graphic_disabled_hover.alpha = _disabled_graphic_alpha;
				_placeGraphic_disabled_hover();
				if (_graphic_hover) _graphic_hover.visible = false;
				if (_graphic_disabled) _graphic_disabled.visible = false;
				if (_graphic) _graphic.visible = false;
			}
			else if (_disabled) {
				if (_graphic_disabled) {
					if (!is_spinning) _graphic_disabled.visible = true;
					_graphic_disabled.alpha = _disabled_graphic_alpha;
					_placeGraphic_disabled();
					if (_graphic) _graphic.visible = false;
					if (_graphic_hover) _graphic_hover.visible = false;
					if (_graphic_disabled_hover) _graphic_disabled_hover.visible = false;
				} 
				else {
					if (_graphic) {
						if (!is_spinning) _graphic.visible = true;
						_graphic.alpha = _disabled_graphic_alpha;
						_placeGraphic();
					}
				}
			} 
			else if (_focused && _graphic_hover) {
				if (!is_spinning) _graphic_hover.visible = true;
				_graphic_hover.alpha = _focused_graphic_alpha;
				_placeGraphic_hover();
				if (_graphic_disabled) _graphic_disabled.visible = false;
				if (_graphic) _graphic.visible = false;
				if (_graphic_disabled_hover) _graphic_disabled_hover.visible = false;
			} else {
				if (_graphic) {
					if (!is_spinning) _graphic.visible = true;
					_graphic.alpha = _focused ? _focused_graphic_alpha : _graphic_alpha;
					_placeGraphic();
				}
				if (_graphic_disabled) _graphic_disabled.visible = false;
				if (_graphic_hover) _graphic_hover.visible = false;
				if (_graphic_disabled_hover) _graphic_disabled_hover.visible = false;
			}
			
			_label_tf.alpha = _focused 
								? (_disabled ? _disabled_label_hover_alpha : _focus_label_alpha)
								: (_disabled ? _disabled_label_alpha : _label_alpha);
			
			_label_tf.y = int(h/2 - _label_tf.height/2) + _label_offset;
			
			// place it next to the graphic if needed, or, center it
			if (_init_ob.graphic_placement == 'left' && _graphic && _graphic.parent) { 
				_label_tf.x = Math.round(_graphic.x+_graphic.width+_graphic_padd_r);
				
				//if our label goes beyond the width of the button, we need to give it some padding
				if(_label_tf.x + _label_tf.width > w){
					w = _label_tf.x + _label_tf.width + _graphic_padd_l;
				}
			} 
			else if (_init_ob.graphic_placement == 'top' && _graphic && _graphic.parent) { 
				_label_tf.x = Math.round((w - _label_tf.width)/2);
				_label_tf.y = _graphic.y + _graphic.height + _graphic_padd_b + _label_offset;
			}
			else if (_init_ob.hasOwnProperty('offset_x')){
				_label_tf.x = _offset_x;
			}
			else if (_init_ob.hasOwnProperty('text_align') && _text_align == 'left'){
				_label_tf.x = _padd_w;
			}
			else {
				_label_tf.x = Math.round((w - _label_tf.width)/2);
			}
						
			//if (name == 'walk1x') DisplayDebug.LogCoords(this, 20);
			var g:Graphics = _shape.graphics;
			g.clear();
			
			if (_init_ob.no_draw === true) return;
			
			var colors:Array = (_focused 
								? (_disabled ? [_disabled_focused_c, _disabled_focused_c2] : [_focused_c, _focused_c2]) 
								: (_disabled ? [_disabled_c, _disabled_c2] : [_c, _c2]));
			var alphas:Array = (_focused 
								? (_disabled ? [_disabled_focus_draw_alpha, _disabled_focus_draw_alpha] : [_focus_draw_alpha, _focus_draw_alpha]) 
								: (_disabled ? [_disabled_draw_alpha, _disabled_draw_alpha] : [_draw_alpha, _draw_alpha]));
				
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(w, h, Math.PI/2, 0, 0);
			
			var border_alpha:Number = _focused 
									  ? (_disabled ? _disabled_focused_border_alpha : _focus_border_alpha)
									  : (_disabled ? _disabled_border_alpha : _border_alpha);
			border_drawn = false;
			if(!_no_border && _border_width > 0){
				g.lineStyle(
					_border_width, 
					_focused 
					? (_disabled ? _disabled_focus_border_c : _focus_border_c)
					: (_disabled ? _disabled_border_c : _border_c),
					border_alpha,
					true, 
					LineScaleMode.NONE, 
					CapsStyle.SQUARE
				);
				border_drawn = true;
			}
			
			g.beginGradientFill(GradientType.LINEAR, colors, alphas, [0, 255], matrix);
			if(!_is_circle){
				g.drawRoundRectComplex(1, 1, w-2, h-2, _corner_rad_tl, _corner_rad_tr, _corner_rad_bl, _corner_rad_br);
			}
			else {
				g.drawCircle(int(w/2), int(w/2), int(w/2));
			}
			
			if(bevel){
				bevel_holder.x = bevel_holder.y = _border_width*2;
				g = bevel_holder.graphics;
				g.clear();
				g.beginFill(0);
				g.drawRoundRectComplex(0, 0, w-_border_width*3, h-_border_width*3, _corner_rad_tl, _corner_rad_tr, _corner_rad_bl, _corner_rad_br);
				
				//put it back
				g = _shape.graphics;
			}			

			if(_show_disabled_pattern && _disabled) {
				disabled_shape.visible = true;
				if(!_disabled_pattern) createDisabledPattern();
				
				g = disabled_shape.graphics;
				g.clear();
				g.beginBitmapFill(_disabled_pattern);
				g.drawRoundRectComplex(1, 1, w-2, h-2, _corner_rad_tl, _corner_rad_tr, _corner_rad_bl, _corner_rad_br);
				
				//put it back
				g = _shape.graphics;
			}
			else if(_show_disabled_pattern && !_disabled){
				disabled_shape.visible = false;
			}
						
			if(!_draw_from_css){	
				var t_l_c:Number = (!_disabled && _pressed) ? _shad_c : _high_c;
				//if (_pressed && !isNaN(_inner_shad_c)) t_l_c = _inner_shad_c;
				
				var b_r_c:Number = (!_disabled && _pressed) ? _high_c : _shad_c;
				
				if (!_no_border && !border_drawn) {
					g.beginFill(t_l_c, (_disabled ? _disabled_draw_alpha : (_focused ? _focus_draw_alpha : _draw_alpha)));
					g.drawRect(2, 0, w-4, 1);// top line
					g.drawRect(0, 2, 1, h-4);// left line
					g.drawRect(1, 1, 1, 1);// top left corner
					
					g.beginFill(b_r_c, (_disabled ? _disabled_draw_alpha : (_focused ? _focus_draw_alpha : _draw_alpha)));
					g.drawRect(2, h-1, w-4, 1);// bott line
					g.drawRect(w-1, 2, 1, h-4);// right line
					g.drawRect(w-2, h-2, 1, 1);// bott right corner
				}
				
				if (!_disabled && (_pressed || _focused) && !isNaN(_inner_shad_c)) {
					shadow.angle = 45;
					shadow2.angle = 225;
					shadow.distance = shadow2.distance = _focus_shadow_distance;
					shadow.alpha = shadow2.alpha = 1;
					shadow.blurX = shadow2.blurX = 4;
					shadow.blurY = shadow2.blurY = 4;
					shadow.alpha = shadow2.alpha = (_pressed) ? .5 : 1;
					shadow.color = shadow2.color = (_disabled) ? 0x989898 : _inner_shad_c;
					shadow.inner = shadow2.inner = true;
									
					_shape.filters = [shadow, shadow2];
				} 
				else {
					_shape.filters = null;
				}
			}
			else {
				//draw it from the setSizeAndType return values
				shadow.angle = 90;
				shadow.color = 0x000000;
				shadow.alpha = _outer_shadow.alpha;
				shadow.distance = _outer_shadow.offset;
				shadow.blurX = shadow.blurY = _outer_shadow.blur;
				
				_shape.filters = [shadow];
				
				//handle the text shadows
				shadow.blurX = shadow.blurY = 0;
				if(_label_shadow.color != null && !_focused){
					shadow.color = _label_shadow.color;
					shadow.alpha = _label_shadow.alpha;
					shadow.distance = _label_shadow.offset;
					
					_label_tf.filters = [shadow];
				}
				else if(_label_shadow.color == null && !_focused){
					_label_tf.filters = null;
				}
				
				//handle the hover shadow
				if(_label_shadow.color_hover != null){
					shadow.color = _disabled ? _label_shadow.color_disabled : _label_shadow.color_hover;
					shadow.alpha = _disabled ? _label_shadow.alpha_disabled : _label_shadow.alpha_hover;
					shadow.distance = _disabled ? _label_shadow.offset_disabled : _label_shadow.offset_hover;
					
					_label_tf.filters = [shadow];
				}
				
				//handle the glow
				if(_label_glow.color != null){
					label_glow.color = _label_glow.color;
					if(_label_glow.hasOwnProperty('alpha')) label_glow.alpha = _label_glow.alpha;
					if(_label_glow.hasOwnProperty('strength')) label_glow.strength = _label_glow.strength;
					if(_label_glow.hasOwnProperty('blur')) label_glow.blurX = label_glow.blurY = _label_glow.blur;
					if(_label_tf.filters.length && _label_tf.filters.indexOf(label_glow) == -1){
						_label_tf.filters.push(label_glow);
					}
					else {
						_label_tf.filters = [label_glow];
					}
				}
				
				//handle the border glow
				if(_border_glow.color != null){
					border_glow.color = _border_glow.color;
					if(_border_glow.hasOwnProperty('alpha')) border_glow.alpha = _border_glow.alpha;
					if(_border_glow.hasOwnProperty('strength')) border_glow.strength = _border_glow.strength;
					if(_border_glow.hasOwnProperty('blur')) border_glow.blurX = border_glow.blurY = _border_glow.blur;
					if(filters.length && filters.indexOf(border_glow) == -1){
						filters.push(border_glow);
					}
					else {
						filters = [border_glow];
					}
				}
			}
			
			//re-do the label with the hover/normal color
			_label_c = (_focused) ? _label_hover_c : _label_normal_c;
			_label_disabled_c = (_focused) ? _label_disabled_hover_c : _label_disabled_normal_c;
			
			populateLabel();
		}
		
		public function setSizeAndType(buttonSize:String, buttonType:String):void {
			var css:Object;
			
			if(buttonSize){
				css = CSSManager.instance.getStyle('.button_'+buttonSize);
				if(css.height) _h = parseFloat(css.height);
				if(css.width) _w = parseFloat(css.width);
				if(css.fontSize) _label_size = parseFloat(css.fontSize);
				if(css.cornerRadius) _corner_rad_tl = _corner_rad_tr = _corner_rad_bl = _corner_rad_br = parseFloat(css.cornerRadius);
				if(css.paddingLr) _padd_w = parseFloat(css.paddingLr);
				if(css.fontWeight && css.fontWeight == 'bold') _label_bold = true;
				if(css.fontFamily) _label_face = StringUtil.stripDoubleQuotes(css.fontFamily);
				
				// maybe this breaks shit?? But I need a way to use the styles as defined in the css, but override the face and size
				
				if (_init_ob.label_face) {
					_label_face = _init_ob.label_face;
				}
				
				if (_init_ob.label_size) {
					_label_size = _init_ob.label_size;
				}
				
				(css.shadowOffset) ? _outer_shadow.offset = parseFloat(css.shadowOffset) : _outer_shadow.offset = 1;
				(css.shadowAlpha) ? _outer_shadow.alpha = css.shadowAlpha : _outer_shadow.alpha = .3;
				(css.shadowBlur) ? _outer_shadow.blur = css.shadowBlur : _outer_shadow.blur = 0;
				if(css.isCircle) {
					_is_circle = true;
					_h = _w;
				}
				
				_size = buttonSize;
			}
						
			if(buttonType){
				css = CSSManager.instance.getStyle('.button_'+buttonType+'_label');
				if(css.color) _label_c = _label_normal_c = _label_hover_c = _label_disabled_c = _label_disabled_normal_c = _label_disabled_hover_c = StringUtil.cssHexToUint(css.color);
				if(css.colorHover) _label_hover_c = StringUtil.cssHexToUint(css.colorHover);
				if(css.colorDisabled) _label_disabled_c = _label_disabled_normal_c = _label_disabled_hover_c = StringUtil.cssHexToUint(css.colorDisabled);
				if(css.colorDisabledHover) _label_disabled_hover_c = StringUtil.cssHexToUint(css.colorDisabledHover);
				if(css.alpha) _label_alpha = _focus_label_alpha = _disabled_label_alpha = _disabled_label_hover_alpha = parseFloat(css.alpha);
				if(css.alphaHover) _focus_label_alpha = parseFloat(css.alphaHover);
				if(css.alphaDisabled) _disabled_label_alpha = _disabled_label_hover_alpha = parseFloat(css.alphaDisabled);
				if(css.alphaDisabledHover) _disabled_label_hover_alpha = parseFloat(css.alphaDisabledHover);
				if(css.backgroundColor) _c = _c2 = _focused_c = _focused_c2 = _disabled_c = _disabled_c2 = _disabled_focused_c = _disabled_focused_c2 = StringUtil.cssHexToUint(css.backgroundColor);
				if(css.backgroundColor2) _c2 = _focused_c2 = _disabled_c2 = _disabled_focused_c2 = StringUtil.cssHexToUint(css.backgroundColor2);
				if(css.backgroundColorHover) _focused_c = _focused_c2 = StringUtil.cssHexToUint(css.backgroundColorHover);
				if(css.backgroundColorHover2) _focused_c2 = StringUtil.cssHexToUint(css.backgroundColorHover2);
				if(css.backgroundColorDisabled) _disabled_c = _disabled_c2 = _disabled_focused_c = _disabled_focused_c2 = StringUtil.cssHexToUint(css.backgroundColorDisabled);
				if(css.backgroundColorDisabled2) _disabled_c2 = _disabled_focused_c2 = StringUtil.cssHexToUint(css.backgroundColorDisabled2);
				if(css.backgroundColorDisabledHover) _disabled_focused_c = _disabled_focused_c2 = StringUtil.cssHexToUint(css.backgroundColorDisabledHover);
				if(css.backgroundColorDisabledHover2) _disabled_focused_c2 = StringUtil.cssHexToUint(css.backgroundColorDisabledHover2);
				if(css.backgroundAlpha) _draw_alpha = _focus_draw_alpha = _disabled_draw_alpha = _disabled_focus_draw_alpha = parseFloat(css.backgroundAlpha);
				if(css.backgroundAlphaHover) _focus_draw_alpha = parseFloat(css.backgroundAlphaHover);
				if(css.backgroundAlphaDisabled) _disabled_draw_alpha = _disabled_focus_draw_alpha = parseFloat(css.backgroundAlphaDisabled);
				if(css.backgroundAlphaDisabledHover) _disabled_focus_draw_alpha = parseFloat(css.backgroundAlphaDisabledHover);
				if(css.paddingLr) _padd_w = parseFloat(css.paddingLr);
				if(css.fontWeight && css.fontWeight == 'bold') _label_bold = true;
				if(css.shadowColor) _label_shadow.color = _label_shadow.color_hover = _label_shadow.color_disabled = StringUtil.cssHexToUint(css.shadowColor);
				if(css.shadowAlpha) _label_shadow.alpha = _label_shadow.alpha_hover = _label_shadow.alpha_disabled = parseFloat(css.shadowAlpha);
				if(css.shadowOffset) _label_shadow.offset = _label_shadow.offset_hover = _label_shadow.offset_disabled = parseFloat(css.shadowOffset);
				if(css.shadowColorHover) _label_shadow.color_hover = StringUtil.cssHexToUint(css.shadowColorHover);
				if(css.shadowAlphaHover) _label_shadow.alpha_hover = css.shadowAlphaHover;
				if(css.shadowOffsetHover) _label_shadow.offset_hover = parseFloat(css.shadowOffsetHover);
				if(css.shadowColorDisabled) _label_shadow.color_disabled = StringUtil.cssHexToUint(css.shadowColorDisabled);
				if(css.shadowAlphaDisabled) _label_shadow.alpha_disabled = css.shadowAlphaDisabled;
				if(css.shadowOffsetDisabled) _label_shadow.offset_disabled = parseFloat(css.shadowOffsetDisabled);
				if(css.glowColor) _label_glow.color = StringUtil.cssHexToUint(css.glowColor);
				if(css.glowAlpha) _label_glow.alpha = parseFloat(css.glowAlpha);
				if(css.glowBlur) _label_glow.blur = parseFloat(css.glowBlur);
				if(css.glowStrength) _label_glow.strength = parseFloat(css.glowStrength);
				if(css.cornerRadius) _corner_rad_tl = _corner_rad_tr = _corner_rad_bl = _corner_rad_br = parseFloat(css.cornerRadius);
				if(css.cornerRadiusTl) _corner_rad_tl = parseFloat(css.cornerRadiusTl);
				if(css.cornerRadiusTr) _corner_rad_tr = parseFloat(css.cornerRadiusTr);
				if(css.cornerRadiusBl) _corner_rad_bl = parseFloat(css.cornerRadiusBl);
				if(css.cornerRadiusBr) _corner_rad_br = parseFloat(css.cornerRadiusBr);
				if(css.borderWidth) _border_width = parseFloat(css.borderWidth);
				if(css.borderColor) _border_c = _focus_border_c = _disabled_border_c = _disabled_focus_border_c = StringUtil.cssHexToUint(css.borderColor);
				if(css.borderColorHover) _focus_border_c = StringUtil.cssHexToUint(css.borderColorHover);
				if(css.borderColorDisabled) _disabled_border_c = _disabled_focus_border_c = StringUtil.cssHexToUint(css.borderColorDisabled);
				if(css.borderColorDisabledHover) _disabled_focus_border_c = StringUtil.cssHexToUint(css.borderColorDisabledHover);
				if(css.borderAlpha) _border_alpha = _focus_border_alpha = _disabled_border_alpha = parseFloat(css.borderAlpha);
				if(css.borderAlphaHover) _focus_border_alpha = _disabled_focused_border_alpha = parseFloat(css.borderAlphaHover);
				if(css.borderAlphaDisabled) _disabled_border_alpha = _disabled_focused_border_alpha = parseFloat(css.borderAlphaDisabled);
				if(css.borderAlphaDisabledHover) _disabled_focused_border_alpha = parseFloat(css.borderAlphaDisabledHover);
				if(css.borderGlowColor) _border_glow.color = StringUtil.cssHexToUint(css.borderGlowColor);
				if(css.borderGlowAlpha) _border_glow.alpha = parseFloat(css.borderGlowAlpha);
				if(css.borderGlowBlur) _border_glow.blur = parseFloat(css.borderGlowBlur);
				if(css.borderGlowStrength) _border_glow.strength = parseFloat(css.borderGlowStrength);
				if(css.offset) _label_offset = parseFloat(css.offset);
				if(css.showBevel){
					//setup the bevel
					bevel = new BevelFilter();
					bevel.highlightColor = css.hasOwnProperty('bevelHighlightColor') ? StringUtil.cssHexToUint(css.bevelHighlightColor) : 0xffffff;
					bevel.highlightAlpha = css.hasOwnProperty('bevelHighlightAlpha') ? parseFloat(css.bevelHighlightAlpha) : .8;
					bevel.shadowColor = css.hasOwnProperty('bevelShadowColor') ? StringUtil.cssHexToUint(css.bevelShadowColor) : 0x000000;
					bevel.shadowAlpha = css.hasOwnProperty('bevelShadowAlpha') ? parseFloat(css.bevelShadowAlpha) : .8;
					bevel.angle = css.hasOwnProperty('bevelAngle') ? parseFloat(css.bevelAngle) : 90;
					bevel.blurX = bevel.blurY = css.hasOwnProperty('bevelBlur') ? parseFloat(css.bevelBlur) : 0;
					bevel.distance = css.hasOwnProperty('bevelDistance') ? parseFloat(css.bevelDistance) : 2;
					bevel.knockout = true;
					
					bevel_holder.filters = [bevel];
					bevel_holder.visible = true;
				}
				
				_type = buttonType;
			}
			
			_draw_from_css = true;
			
			//place the graphic if it's there
			if(_graphic) _placeGraphic();
			
			//allow CSS overrides
			if(_init_ob.hasOwnProperty('w')) _w = _init_ob.w;
			if(_init_ob.hasOwnProperty('h')) _h = _init_ob.h;
			
			label = StringUtil.stripHTML(_label_tf.htmlText);
		}
		
		private function createDisabledPattern():void {
			//white lines at 20%
			_disabled_pattern = new BitmapData(3, 3, true, 0x00FFFFFF);
			_disabled_pattern.lock();
			_disabled_pattern.setPixel32(1, 0, 0x20FFFFFF);
			_disabled_pattern.setPixel32(2, 0, 0x20FFFFFF);
			_disabled_pattern.setPixel32(0, 1, 0x20FFFFFF);
			_disabled_pattern.setPixel32(2, 1, 0x20FFFFFF);
			_disabled_pattern.setPixel32(0, 2, 0x20FFFFFF);
			_disabled_pattern.setPixel32(1, 2, 0x20FFFFFF);
			_disabled_pattern.unlock();
		}
		
		public function get size():String {
			return _size;
		}
		
		public function set size(buttonSize:String):void {
			setSizeAndType(buttonSize, null);
		}
		
		public function get type():String {
			return _type;
		}
		
		public function set type(buttonType:String):void {
			setSizeAndType(null, buttonType);
		}
		
		public function get graphic():DisplayObject {
			return _graphic;
		}
		
		public function get graphic_disabled():DisplayObject {
			return _graphic_disabled;
		}
		
		public function setGraphic(value:DisplayObject, is_hover:Boolean = false, is_disabled:Boolean = false):void {
			if(!value) return;
			
			var place_func:Function = _placeGraphic;
			
			//if we already have one, make sure we remove it first
			removeGraphic(is_hover, is_disabled);
			
			if(!is_hover && !is_disabled){
				_graphic = value;
			}
			
			if(is_hover && !is_disabled){
				place_func = _placeGraphic_hover;
				_graphic_hover = value;
			}
			
			if(is_disabled && !is_hover){
				place_func = _placeGraphic_disabled;
				_graphic_disabled = value;
			}
			
			if(is_hover && is_disabled){
				place_func = _placeGraphic_disabled_hover;
				_graphic_disabled_hover = value;
			} 
			
			if(value && contains(value)) removeChild(value);
			addChild(value);
			place_func();
			_draw();
		}
		
		public function removeGraphic(is_hover:Boolean = false, is_disabled:Boolean = false):void {
			if(!is_hover && !is_disabled && _graphic){
				_graphic.parent.removeChild(_graphic);
				_graphic = null;
			}
			
			if(is_hover && !is_disabled && _graphic_hover){
				_graphic_hover.parent.removeChild(_graphic_hover);
				_graphic_hover = null;
			}
			
			if(is_disabled && !is_hover && _graphic_disabled){
				_graphic_disabled.parent.removeChild(_graphic_disabled);
				_graphic_disabled = null;
			}
			
			if(is_hover && is_disabled && _graphic_disabled_hover){
				_graphic_disabled_hover.parent.removeChild(_graphic_disabled_hover);
				_graphic_disabled_hover = null;
			}
		}
		
		public function set disabled_pattern(value:BitmapData):void {
			if(value){
				_show_disabled_pattern = true;
				_disabled_pattern = value;
			}
			else {
				_show_disabled_pattern = false;
			}
			_draw();
		}
		
		override public function set label_color(value:uint):void {
			super.label_color = value;
			populateLabel();
		}
		
		override public function set label_color_disabled(value:uint):void {
			_label_disabled_normal_c = value;
			super.label_color_disabled = value;
			populateLabel();
		}
		
		public function set label_y_offset(value:int):void {
			_label_offset = value;
			populateLabel();
			_draw();
		}
		
		public function set background_alpha(value:Number):void {
			_draw_alpha = value;
			_draw();
		}
		
		public function set show_spinner(value:Boolean):void {
			waiting_spinner.visible = value;
			if(_label_tf) _label_tf.visible = !value;
			if(_graphic) _graphic.visible = !value;
			if(_graphic_hover) _graphic_hover.visible = !value;
			if(_graphic_disabled) _graphic_disabled.visible = !value;
			
			//add or remove the spinner
			if(value){
				addChild(waiting_spinner);
				//if we haven't loaded the spinner yet, do that, otherwise just place it
				if (!waiting_spinner.numChildren){
					const spinner_mc:MovieClip = new AssetManager.instance.assets.spinner() as MovieClip;
					spinner_mc.addEventListener(Event.COMPLETE, onSpinnerLoad, false, 0, true);
					spinner_mc.scaleX = spinner_mc.scaleY = .4;
					waiting_spinner.addChild(spinner_mc);
				}
				else {
					onSpinnerLoad();
				}
			}
			else if(waiting_spinner.parent) {
				waiting_spinner.parent.removeChild(waiting_spinner);
			}
		}
		
		private function onSpinnerLoad(event:Event = null):void {
			//the +2 are visual tweaks since we hardcode the scale to .4
			waiting_spinner.x = int(w/2 - waiting_spinner.width/2) + 2;
			waiting_spinner.y = int(h/2 - waiting_spinner.height/2) + 2;
		}
		
		public function get is_spinning():Boolean {
			return waiting_spinner.visible;
		}
		
		public function setCornerRadius(tl:Number, tr:Number, bl:Number, br:Number):void {
			_corner_rad_tl = tl;
			_corner_rad_tr = tr;
			_corner_rad_bl = bl;
			_corner_rad_br = br;
			
			_draw();
		}
	}
}