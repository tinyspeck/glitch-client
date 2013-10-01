package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.memory.DisposableSprite;
	

	public interface IDisposableSpriteChangeHandler
	{
		function worldDisposableSpriteSubscribedHandler(sp:DisposableSprite):void;
		function worldDisposableSpriteChangeHandler(sp:DisposableSprite):void;
		function worldDisposableSpriteDestroyedHandler(sp:DisposableSprite):void;
	}
}