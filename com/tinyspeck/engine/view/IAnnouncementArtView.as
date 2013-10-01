package com.tinyspeck.engine.view
{
	public interface IAnnouncementArtView
	{
		function get art_w():Number;
		function get art_h():Number;
		function get wh():int;
		function get loaded():Boolean;
		function dispose():void;
	}
}