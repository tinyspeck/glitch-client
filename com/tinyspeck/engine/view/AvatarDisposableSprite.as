package com.tinyspeck.engine.view
{
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.engine.port.IDisposableSpriteChangeHandler;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	
	import flash.geom.Point;

	public class AvatarDisposableSprite extends TSSpriteWithModel implements IDisposableSpriteChangeHandler
	{
		protected static var avatar_global:Point = new Point();
		protected static var avatar_local:Point = new Point();
		
		public function AvatarDisposableSprite(){
			
		}
		
		public function worldDisposableSpriteSubscribedHandler(sp:DisposableSprite):void {
		}
		
		public function worldDisposableSpriteChangeHandler(sp:DisposableSprite):void {
			if(!sp.parent) return;
			avatar_local.x = sp.x;
			avatar_local.y = sp.y;
			avatar_global = sp.parent.localToGlobal(avatar_local);
		}
		
		public function worldDisposableSpriteDestroyedHandler(sp:DisposableSprite):void {
			
		}
	}
}