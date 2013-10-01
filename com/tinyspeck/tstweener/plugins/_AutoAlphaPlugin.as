package com.tinyspeck.tstweener.plugins
{
import com.greensock.plugins.AutoAlphaPlugin;

/**
 * Provides Tweener's _autoAlpha property to TweenMax since TM's builtin
 * is called autoAlpha. This saves translation and special casing.
 */
public final class _AutoAlphaPlugin extends AutoAlphaPlugin
{
	/** @private **/
	public static const API:Number = 1.0; //If the API/Framework for plugins changes in the future, this number helps determine compatibility
	
	public function _AutoAlphaPlugin()
	{
		super();
		this.propName = "_autoAlpha";
	}
}
}