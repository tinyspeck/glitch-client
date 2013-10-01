package com.tinyspeck.bridge
{
	import com.tinyspeck.core.control.IController;
	
	import flash.display.MovieClip;

	public interface IMainEngineController extends IController {
		function setFlashVarModel(flashVarModel:FlashVarModel):void;
		function setAvatar(avatar:MovieClip):void;
		function setPrefsModel(pm:PrefsModel):void;
		function runAndConnect():void;
		function connect():void;
	}
}