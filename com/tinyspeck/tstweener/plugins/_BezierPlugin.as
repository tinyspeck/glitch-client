package com.tinyspeck.tstweener.plugins
{
import com.greensock.plugins.BezierPlugin;

/**
 * Provides Tweener's _bezier property to TweenMax since TM's builtin
 * is called bezier. This saves translation and special casing.
 */
public final class _BezierPlugin extends BezierPlugin
{
	/** @private **/
	public static const API:Number = 1.0; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
		
	public function _BezierPlugin()
	{
		super();
		this.propName = "_bezier"; //name of the special property that the plugin should intercept/manage
	}
}
}