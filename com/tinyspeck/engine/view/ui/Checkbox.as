package com.tinyspeck.engine.view.ui {
	
	import com.tinyspeck.engine.event.TSEvent;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextFieldAutoSize;
	
	public class Checkbox extends FormElement {
		
		protected var _checked:Boolean;
		protected var _label_w:int;
		protected var _graphic:DisplayObject;
		protected var _graphic_checked:DisplayObject;
		protected var _draw_caret:Boolean;
		protected var _draw_color:uint;
		
		public function Checkbox(init_ob:Object):void {
			super(init_ob);
			_construct();
		}
		
		override protected function _construct():void {
			super._construct();
			
			_draw_caret = (_init_ob.draw_caret == true) ? true : false;
			_draw_color = (_init_ob.draw_color is int) ? _init_ob.draw_color : 0;
			_checked = (_init_ob.checked == true) ? true : false;
			_label_w = (_init_ob.label_w) ? _init_ob.label_w : 0;
			_graphic = (_init_ob.graphic) ? _init_ob.graphic : null;
			_graphic_checked = (_init_ob.graphic_checked) ? _init_ob.graphic_checked : null;
			if (_graphic && _graphic_checked) {
				addChild(_graphic);
				addChild(_graphic_checked);
			}
			
			x = _init_ob.x || 0;
			y = _init_ob.y || 0;
			
			_w = _w || 15;
			_h = _h || 15;
			
			_label_tf.x = _w+3;
			
			if (_label_w) {
				_label_tf.wordWrap = true;
				_label_tf.multiline = true;
				_label_tf.width = _label_w;
			}
			
			_label_tf.autoSize = TextFieldAutoSize.LEFT;
			_label_tf.selectable = false;
			label = _init_ob.label
			addChild(_label_tf);
		}
		
		override protected function _addedToStageHandler(e:Event):void {
			super._addedToStageHandler(e);
		}
		
		override protected function _clickHandler(e:MouseEvent):void {
			checked = !_checked;
			dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
		}
		
		override protected function _draw():void {
			var w:int = _w;
			var h:int = _h;
			
			graphics.clear();
			
			if (_graphic && _graphic_checked) {
				if (checked) {
					_graphic.visible = false;
					_graphic_checked.visible = true;
				} else {
					_graphic.visible = true;
					_graphic_checked.visible = false;
				}
				return;
			}
			
			
			if (_draw_caret) {
				graphics.beginFill(0xffffff, 0);
				graphics.drawRect(0, 0, w, h);
				graphics.beginFill(_draw_color, 1);
				if (checked) {
					// point down
					graphics.moveTo(0,h/4);
					graphics.lineTo(w,h/4);
					graphics.lineTo(w/2,(h/4)*3);
					graphics.lineTo(0,h/4);
				} else {
					// point right
					graphics.moveTo(w/4,0);
					graphics.lineTo(w/4,h);
					graphics.lineTo((w/4)*3,h/2);
					graphics.lineTo(w/4,0);
				}
				
			} else {
				graphics.beginFill(_draw_color, 1);
				graphics.drawRect(0, 0, w, h);
				graphics.beginFill(0xffffff, 1);
				graphics.drawRect(1, 1, w-2, h-2);
				graphics.endFill();
				graphics.lineStyle(0, _draw_color, 1);
				if (checked) {
					graphics.moveTo(0,0);
					graphics.lineTo(w-1,h-1);
					graphics.moveTo(0,h);
					graphics.lineTo(w,0);
				}
			}
			
		}
		
		public function get checked():Boolean {
			return _checked;
		}
		
		public function set checked(check:Boolean):void {
			if (check !== _checked) {
				_checked = check;
				_draw();
			}
		}
	}
}
