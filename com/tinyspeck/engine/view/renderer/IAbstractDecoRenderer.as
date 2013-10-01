package com.tinyspeck.engine.view.renderer
{
	import com.tinyspeck.engine.data.location.AbstractPositionableLocationEntity;
	
	import flash.display.DisplayObject;

	/**
	 * Exists so LocoDeco can find and interrogate objects that can be selected
	 * and moved around.
	 */
	public interface IAbstractDecoRenderer
	{
		function syncRendererWithModel():void;
		function getModel():AbstractPositionableLocationEntity;
		function getRenderer():DisplayObject;
		
		/** Tells the LocationRenderer to draw a highlight around this Deco */
		CONFIG::locodeco function get highlight():Boolean;
		CONFIG::locodeco function set highlight(v:Boolean):void;
	}
}