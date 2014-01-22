package locodeco.models
{
import flash.events.Event;
import flash.events.EventDispatcher;

import locodeco.LocoDecoGlobals;
import locodeco.util.MathUtil;

import mx.collections.ArrayList;
import mx.events.PropertyChangeEvent;

[Bindable]
public final class LayerModel extends EventDispatcher
{
	/** Tracks all layers, but not in any particular order */
	private static const _allLayers:Array = [];
	private static var _middleground:LayerModel;
	private static var _updateDisplayOnly:Boolean;
	
	/** visible controls is_hidden on the client's Layer model */
	public var visible:Boolean = true;
	public var suffix:String = '%';
	public var decos:ArrayList = new ArrayList(); // Array of DecoModels
	
	public var name:String;
	public var tsid:String;
	public var isMiddleground:Boolean;
	
	// filters
	public var saturation:int;
	public var brightness:int;
	public var contrast:int;
	public var blur:int;
	public var tintAmount:int;
	public var tintColor:ColorModel = new ColorModel();
	
	private var _width:int;
	private var _height:int;
	private var _displayWidth:Number;
	private var _displayHeight:Number;
	
	public function LayerModel(isMiddleGround:Boolean = false) {
		// track this layer
		_allLayers.push(this);
		
		if (isMiddleGround) {
			if (_middleground) throw new Error("Only one middleground allowed");
			_middleground = this;
			suffix = 'px';
			this.isMiddleground = isMiddleGround;
		}
		
		tintColor.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, tintColorPropertyChanged);
		decos.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, redispatchEvent);
	}
	
	public static function get middleground():LayerModel {
		return _middleground;
	}

	public function get z():int {
		// z is calculated dynamically because 'z' is implicitly stored in the ArrayList
		const _list:ArrayList = LocoDecoGlobals.instance.location.layerModels;
		return _list.getItemIndex(_middleground) - _list.getItemIndex(this);
	}
	
	/**
	 * Changing the dimensions on the middleground affects the dimensions of
	 * all the other layers.
	 */
	private static function middlegroundChanged():void {
		var lm:LayerModel;
		for each (lm in _allLayers) {
			if (lm.isMiddleground) continue;
			if (false) {
				//TODO if changing the mg dims, change other layers proportionally
				// LayerItemRenderer should have a middleground state which
				// expands it vertically to include a checkbox to control this
				//lm.width = 100;
			} else {
				// just the mg dims are changing,
				// the displayWidth/Height need to be updated since they are
				// relative to the mg dims

				// don't want changing the displayWidth to modify
				// the actual width when just updating the mg
				_updateDisplayOnly = true;
				
				//databinding will take care of redundant changes
				lm.displayWidth  = lm.width*100/_middleground.width;
				lm.displayHeight = lm.height*100/_middleground.height;
				
				_updateDisplayOnly = false;
			}
		}
	}

	public function get width():int {
		return _width;
	}
	
	public function set width(value:int):void {
		_width = value;
		if (_middleground) {
			if (isMiddleground) {
				displayWidth = value;
				middlegroundChanged();
			} else {
				displayWidth = value*100/_middleground.width;
			}
		}
	}
	
	public function get displayWidth():Number {
		return MathUtil.roundForDisplayPercentages(_displayWidth);
	}

	public function set displayWidth(w:Number):void {
		_displayWidth = w;
		if (isMiddleground) {
			width = _displayWidth;
			middlegroundChanged();
		} else if (!_updateDisplayOnly) {
			width = Math.round(_displayWidth*_middleground.width/100);
		}
	}

	public function get height():int {
		return _height;
	}
	
	public function set height(value:int):void {
		_height = value;
		if (_middleground) {
			if (isMiddleground) {
				displayHeight = value;
				middlegroundChanged();
			} else {
				displayHeight = value*100/_middleground.height;
			}
		}
	}
	
	public function get displayHeight():Number {
		return MathUtil.roundForDisplayPercentages(_displayHeight);
	}
	
	public function set displayHeight(h:Number):void {
		_displayHeight = h;
		if (isMiddleground) {
			height = _displayHeight;
			middlegroundChanged();
		} else if (!_updateDisplayOnly) {
			height = Math.round(_displayHeight*_middleground.height/100);
		}
	}
	
	public function dispose():void {
		tintColor.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, tintColorPropertyChanged);
		decos.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, redispatchEvent);
		
		for each (var dm:DecoModel in decos) dm.dispose();
		decos.removeAll();
		
		_allLayers.splice(_allLayers.indexOf(this), 1);
		
		if (isMiddleground) _middleground = null;
	}
	
	private function tintColorPropertyChanged(e:Event):void {
		dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, 'tintColor', tintColor, tintColor));
	}
	
	private function redispatchEvent(e:Event):void {
		dispatchEvent(e);
	}
	
	override public function toString():String {
		return "LayerModel{name:" + name + ", tsid:" + tsid + ", width:" + width
			+ ", height:" + height + ", visible:" + visible
			+ ", isMiddleground:" + isMiddleground
			+ "}";
	}
}
}