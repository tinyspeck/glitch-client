package com.tinyspeck.engine.loader
{
public class SmartLoaderError extends Error
{
	/**
	 * Thrown if you try to access something when there is no active loader,
	 * e.g. you never called load() or you called unloadAndStop().
	 */
	public static const UNLOADED:String = "SmartLoader has already been unloaded";
	
	/** Thrown if you try to reuse a SmartLoader */
	public static const REUSED:String = "SmartLoader is being reused";
	
	public function SmartLoaderError(message:*="", id:*=0) {
		super(message, id);
	}
}
}