package com.tinyspeck.engine.port {
	public interface IMoveListener {
		function moveLocationHasChanged():void;
		function moveLocationAssetsAreReady():void;
		function moveMoveStarted():void;
		function moveMoveEnded():void;
	}
}