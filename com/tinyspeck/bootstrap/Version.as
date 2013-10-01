package com.tinyspeck.bootstrap
{
	public class Version
	{
		public static const name:String = "TS_BootStrap";
		public static const revision:String = CONFIG::svn_revision;
		
		public static function toString():String {
			return name + '_' + revision;
		}
	}
}