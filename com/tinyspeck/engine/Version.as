package com.tinyspeck.engine
{
	public class Version
	{
		public static const name:String = "TS_Engine";
		public static const revision:String = CONFIG::svn_revision;
		
		public static function toString():String {
			return name + '_' + revision;
		}
	}
}