package com.tinyspeck.engine.admin.locodeco.tests
{
import flash.display.DisplayObject;
import flash.utils.Proxy;
import flash.utils.flash_proxy;

/**
 * This class acts like a DisplayObject, but proxies the getting/setting of
 * width, height, and rotation.
 */
public dynamic class SpriteToControlPointTargetProxy extends Proxy {
	private var _do:DisplayObject;
	
	public function SpriteToControlPointTargetProxy(displayObject:DisplayObject) {
		_do = displayObject;
	}
	
	override flash_proxy function callProperty(methodName:*, ... args):* {
		return _do[methodName].apply(_do, args);
	}
	
	override flash_proxy function getProperty(name:*):* {
		switch (String(name)) {
			case 'w':
				return _do.width;
			case 'h':
				return _do.height;
			case 'r':
				return _do.rotation;
			default:
				return (_do.hasOwnProperty(name) ? _do[name] : null);
		}
	}
		
	override flash_proxy function setProperty(name:*, value:*):void {
		switch (String(name)) {
			case 'w':
				_do.width = value;
				break;
			case 'h':
				_do.height = value;
				break;
			case 'r':
				 _do.rotation = value;
				break;
			default:
				_do[name] = value;
				break;
		}
	}
	
	public function get displayObject():DisplayObject {
		return _do;
	}
}
}
