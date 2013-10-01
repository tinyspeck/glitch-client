package com.tinyspeck.engine.admin.locodeco.components
{
import flash.display.DisplayObject;
import flash.utils.Proxy;
import flash.utils.flash_proxy;

import locodeco.models.DecoModel;

/**
 * This class acts like a DisplayObject, but proxies the setting of
 * x, y, width, height, and rotation to go to the DecoModel instead.
 */
public dynamic class DecoModelDisplayObjectProxy extends Proxy {
	private var _dm:DecoModel;
	private var _do:DisplayObject;
	
	public function DecoModelDisplayObjectProxy(decoModel:DecoModel, displayObject:DisplayObject) {
		_dm = decoModel;
		_do = displayObject;
	}
	
	override flash_proxy function callProperty(methodName:*, ... args):* {
		return _do[methodName].apply(_do, args);
	}
	
	override flash_proxy function getProperty(name:*):* {
		return (_dm.hasOwnProperty(name) ? _dm : _do)[name];
	}
		
	override flash_proxy function setProperty(name:*, value:*):void {
		var last:Number;
		switch (String(name)) {
			case 'x':
			case 'y':
			case 'w':
			case 'h':
			case 'r':
			case 'x1':
			case 'y1':
			case 'x2':
			case 'y2':
			case 'placement_plane_height':
				if (_dm.hasOwnProperty(String(name))) {
					last = _dm[String(name)];
					// setting these may be expensive, so this perf opt is important
					if (int(last) != int(value)) {
						_dm[String(name)] = int(value);
					}
				}
				break;
			// don't allow any other properties to be set
			//default:
			//	_do[name] = value;
			//	break;
		}
	}
	
	public function get decoModel():DecoModel {
		return _dm;
	}
	
	public function get displayObject():DisplayObject {
		return _do;
	}
}
}
