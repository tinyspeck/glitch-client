package locodeco.models
{
import flash.events.Event;
import flash.events.EventDispatcher;

import locodeco.util.MathUtil;

import mx.events.PropertyChangeEvent;

public class DecoModel extends EventDispatcher
{
	/** The minimum size a deco can be */
	public static const MIN_DIMS:Number = 5;
	
	[Bindable] public var layer:LayerModel;
	[Bindable] public var visible:Boolean = true;
	
	[Bindable] public var name:String;
	[Bindable] public var tsid:String;
	[Bindable] public var sign_txt:String;
	[Bindable] public var sign_css_class:String;
	[Bindable] public var z:Number;
	
	[Bindable] public var animated:Boolean;
	[Bindable] public var standalone:Boolean;
	[Bindable] public var h_flip:Boolean;
	//TODO [Bindable] public var v_flip:Boolean; // not in use but seems to be sent in some locations
	//TODO [Bindable] public var behavior:String;
	
	private var _animatable:Boolean;

	private var _markW:int;
	private var _markH:int;
	
	private var _x:Number;
	private var _y:Number;
	private var _originalWidth:int;
	private var _originalHeight:int;
	private var _w:int;
	private var _h:int;
	private var _percentWidth:Number = 100;
	private var _percentHeight:Number = 100;
	private var _r:int = 0;
	
	private var _oldR:int;
	private var _oldPercentWidth:int;
	private var _oldOriginalWidth:int;
	private var _oldWidth:int;
	private var _oldPercentHeight:int;
	private var _oldOriginalHeight:int;
	private var _oldHeight:int;
	
	private var _savedState:Object;
	
	public function DecoModel(layer:LayerModel, animatable:Boolean = false) {
		this.layer = layer;
		this._animatable = animatable;
	}
	
	public function updateModel(deco:Object):void {
		originalWidth  = deco.w;
		originalHeight = deco.h;
		tsid = deco.tsid;
		name = deco.name;
		x = deco.x;
		y = deco.y;
		z = deco.z;
		r = deco.r;
		h_flip = deco.h_flip;
		animated = deco.animated;
		standalone = deco.standalone;
		sign_txt = deco.sign_txt;
		sign_css_class = deco.sign_css_class;
	}
	
	public function get animatable():Boolean {
		return _animatable;
	}

	/**
	 * Stores a clone of the DecoModel in the returned object for saveState();
	 * override it and keep adding to the super's Object.
	 */
	public function getState():Object {
		const ob:Object = _savedState = {};
		ob.x = x;
		ob.y = y;
		ob.w = w;
		ob.h = h;
		ob.r = r;
		ob.h_flip = h_flip;
		ob.animated = animated;
		ob.standalone = standalone;
		ob.sign_txt = sign_txt;
		ob.sign_css_class = sign_css_class;
		return ob;
	}
	
	/** Saves the result of getState() */
	final public function saveState():void {
		_savedState = getState();
	}
	
	/** Loads the last saved state */
	final public function loadSavedState():void {
		for (var key:String in _savedState) {
			this[key] = _savedState[key];
		}
	}
	
	/** Loads the last saved state */
	final public function changesSinceSavedState():Boolean {
		for (var key:String in _savedState) {
			if (this[key] != _savedState[key]) return true;
		}
		return false;
	}
	
	/** Simply clears the last saved state */
	public function clearSavedState():void {
		_savedState = null;
	}
	
	[Bindable]
	public function get x():Number {
		return _x;
	}

	public function set x(value:Number):void {
		_x = value;
	}
	
	[Bindable]
	public function get y():Number {
		return _y;
	}
	
	public function set y(value:Number):void {
		_y = value;
	}

	public function get type():String {
		return DecoModelTypes.DECO_TYPE;
	}
	
	public function dispose():void {
		layer = null;
	}
	
	public function removeFromLayer():void {
		if (layer) layer.decos.removeItem(this);
	}
	
	[Bindable(event='propertyChange')]
	public function get originalWidth():int {
		return _originalWidth;
	}
	
	public function set originalWidth(value:int):void {
		if (value < 0) value = 0;
		
		_oldOriginalWidth = _originalWidth;
		_oldPercentWidth = _percentWidth;
		_oldWidth = _w;
		_originalWidth = value;
		_w = value;
		_percentWidth = 100;
		
		modelUpdated();
	}
	
	[Bindable(event='propertyChange')]
	public function get w():int {
		return _w;
	}
	
	public function set w(value:int):void {
		if (value < 0) value = 0;
		
		_oldPercentWidth = _percentWidth;
		_oldWidth = _w;
		_w = value;
		_percentWidth = (_originalWidth > 0) ? _w*100/_originalWidth : 0;
		
		modelUpdated();
	}
	
	[Bindable(event='propertyChange')]
	public function get percentWidth():Number {
		return MathUtil.roundForDisplayPercentages(_percentWidth);
	}
	
	public function set percentWidth(w:Number):void {
		if (w < 0) w = 0;
		
		_oldPercentWidth = _percentWidth;
		_oldWidth = _w;
		_percentWidth = w;
		_w = Math.round(_percentWidth*_originalWidth/100);
		
		modelUpdated();
	}
	
	[Bindable(event='propertyChange')]
	public function get originalHeight():int {
		return _originalHeight;
	}
	
	public function set originalHeight(value:int):void {
		if (value < 0) value = 0;
		
		_oldOriginalHeight = _originalHeight;
		_oldPercentHeight = _percentHeight;
		_oldHeight = _h;
		
		_originalHeight = value;
		_h = value;
		_percentHeight = 100;
		
		modelUpdated();
	}
	
	[Bindable(event='propertyChange')]
	public function get h():int {
		return _h;
	}
	
	public function set h(value:int):void {
		if (value < 0) value = 0;
		
		_oldPercentHeight = _percentHeight;
		_oldHeight = _h;
		_h = value;
		_percentHeight = (_originalHeight > 0) ? _h*100/_originalHeight : 0;
		
		modelUpdated();
	}
	
	[Bindable(event='propertyChange')]
	public function get percentHeight():Number {
		return MathUtil.roundForDisplayPercentages(_percentHeight);
	}
	
	public function set percentHeight(h:Number):void {
		if (h < 0) h = 0;
		
		_oldPercentHeight = _percentHeight;
		_oldHeight = _h;
		_percentHeight = h;
		_h = Math.round(_percentHeight*_originalHeight/100);
		
		modelUpdated();
	}
	
	[Bindable(event='propertyChange')]
	public function get r():int {
		return _r;
	}
	
	public function set r(value:int):void {
		_oldR = _r;
		if (value < 0) {
			_r = value % -360;
		} else {
			_r = value % 360;
		}
		modelUpdated();
	}
	
	private function modelUpdated():void {
		const events:Array = [];
		
		if (_oldR != _r) {
			events.push(PropertyChangeEvent.createUpdateEvent(
				this, 'r', _oldR, _r));
			_oldR = _r;
		}
		
		if (_oldOriginalHeight != _originalHeight) {
			events.push(PropertyChangeEvent.createUpdateEvent(
				this, 'originalHeight', _oldOriginalHeight, _originalHeight));
			_oldOriginalHeight = _originalHeight;
		}
		
		if (_oldPercentHeight != _percentHeight) {
			events.push(PropertyChangeEvent.createUpdateEvent(
				this, 'percentHeight', _oldPercentHeight, _percentHeight));
			_oldPercentHeight = _percentHeight;
		}
		
		if (_oldHeight != _h) {
			events.push(PropertyChangeEvent.createUpdateEvent(
				this, 'h', _oldHeight, _h));
			_oldHeight = _h;
		}
		
		if (_oldOriginalWidth != _originalWidth) {
			events.push(PropertyChangeEvent.createUpdateEvent(
				this, 'originalWidth', _oldOriginalWidth, _originalWidth));
			_oldOriginalWidth = _originalWidth;
		}
		
		if (_oldPercentWidth != _percentWidth) {
			events.push(PropertyChangeEvent.createUpdateEvent(
				this, 'percentWidth', _oldPercentWidth, _percentWidth));
			_oldPercentWidth = _percentWidth;
		}
		
		if (_oldWidth != _w) {
			events.push(PropertyChangeEvent.createUpdateEvent(
				this, 'w', _oldWidth, _w));
			_oldWidth = _w;
		}
		
		for each (var e:Event in events) {
			dispatchEvent(e);
		}
	}
	
	/** Call this before constraining dimensions to set the aspect ratio */
	public function markCurrentDimensions():void {
		_markW = w;
		_markH = h;
	}
	
	/** This will constrain the width against the last marked height */
	public function constrainWidth():void {
		w = Math.round(_markW * (h / _markH));
	}
	
	/** This will constrain the height against the last marked width */
	public function constrainHeight():void {
		h = Math.round(_markH * (w / _markW));
	}
	
	override public function toString():String {
		return "DecoModel{name:" + name + ", tsid:" + tsid
			+ ", x:" + x + ", y:" + y + ", width:" + w + ", height:" + h
			+ ", r:" + r + ", hflip:" + h_flip + ", visible:" + visible
			+ "}";
	}
}
}