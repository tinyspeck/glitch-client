package locodeco.models
{
import flash.events.EventDispatcher;

import mx.events.PropertyChangeEvent;

[Bindable(event="propertyChange")]
public final class ColorModel extends EventDispatcher
{
	private var _color:uint;
	private var _hex:String = "000000";
	
	private var _r:uint;
	private var _g:uint;
	private var _b:uint;
	
	private var _h:uint;
	private var _s:uint;
	private var _v:uint;
	
	private function modelUpdated():void {
		dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, 'r', null, r));
		dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, 'g', null, g));
		dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, 'b', null, b));
		dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, 'h', null, h));
		dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, 's', null, s));
		dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, 'v', null, v));
		dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, 'color', null, color));
		dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, 'hex', null, hex));
	}
	
	public function get color():uint {
		return _color;
	}

	public function set color(value:uint):void {
		_color = value;
		col2hex();
		col2rgb();
		rgb2hsv();
		modelUpdated();
	}

	public function get hex():String {
		return _hex;
	}

	public function set hex(value:String):void {
		_color = uint('0x' + value);
		col2hex();
		col2rgb();
		rgb2hsv();
		modelUpdated();
	}

	public function get r():uint {
		return _r;
	}

	public function set r(value:uint):void {
		_r = value & 0xFF;
		rgb2col();
		col2hex();
		rgb2hsv();
		modelUpdated();
	}

	public function get g():uint {
		return _g;
	}

	public function set g(value:uint):void {
		_g = value & 0xFF;
		rgb2col();
		col2hex();
		rgb2hsv();
		modelUpdated();
	}

	public function get b():uint {
		return _b;
	}

	public function set b(value:uint):void {
		_b = value & 0xFF;
		rgb2col();
		col2hex();
		rgb2hsv();
		modelUpdated();
	}

	public function get h():uint {
		return _h;
	}

	public function set h(value:uint):void {
		_h = value;
		hsv2rgb();
		rgb2col();
		col2hex();
		modelUpdated();
	}

	public function get s():uint {
		return _s;
	}

	public function set s(value:uint):void {
		_s = value;
		hsv2rgb();
		rgb2col();
		col2hex();
		modelUpdated();
	}

	public function get v():uint {
		return _v;
	}

	public function set v(value:uint):void {
		_v = value;
		hsv2rgb();
		rgb2col();
		col2hex();
		modelUpdated();
	}
	
	// hsv2rgb and rgb2hsv based on http://www.actionscript.org/forums/showthread.php3?t=15155 and http://blog.mindfock.com/rgb-to-hexadecimal-to-hsv-conversion-in-as3/
	private function hsv2rgb():void {
		var r:Number = 0;
		var g:Number = 0;
		var b:Number = 0;

		var tempS:Number = _s / 100;
		var tempV:Number = _v / 100;
		
		var hi:int = Math.floor(_h/60) % 6;
		var f:Number = _h/60 - Math.floor(_h/60);
		var p:Number = (tempV * (1 - tempS));
		var q:Number = (tempV * (1 - f * tempS));
		var t:Number = (tempV * (1 - (1 - f) * tempS));
		
		switch(hi){
			case 0: r = tempV; g = t; b = p; break;
			case 1: r = q; g = tempV; b = p; break;
			case 2: r = p; g = tempV; b = t; break;
			case 3: r = p; g = q; b = tempV; break;
			case 4: r = t; g = p; b = tempV; break;
			case 5: r = tempV; g = p; b = q; break;
		}
		
		_r = Math.round(r*255);
		_g = Math.round(g*255);
		_b = Math.round(b*255);
	}
	
	
	private function rgb2hsv():void {
		const r:Number = _r/255;
		const g:Number = _g/255;
		const b:Number = _b/255;
		const x:Number = Math.min(Math.min(r, g), b);
		const val:Number = Math.max(Math.max(r, g), b);
		if (x==val) {
			_h = 0;
			_s = 0;
			_v = Math.round(val*100);
		} else {
			const f:Number = (r == x) ? g-b : ((g == x) ? b-r : r-g);
			const i:Number = (r == x) ? 3 : ((g == x) ? 5 : 1);
			_h = Math.round((i-f/(val-x))*60)%360;
			_s = Math.round(((val-x)/val)*100);
			_v = Math.round(val*100);
		}
	}
	
	private function col2rgb():void {
		_r = (_color & 0xFF0000) >> 16;
		_g = (_color & 0x00FF00) >> 8;
		_b = (_color & 0x0000FF);
	}
	
	private function col2hex():void {
		_hex = ((_color == 0) ? "000000" : _color.toString(16).toUpperCase());
	}
	
	private function rgb2col():void {
		_color = (_r << 16) | (_g << 8) | _b;
	}
}
}