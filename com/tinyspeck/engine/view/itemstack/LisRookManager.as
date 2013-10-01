package com.tinyspeck.engine.view.itemstack {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.TSSprite;
	import com.tinyspeck.engine.port.TSSprite;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;
	
	CONFIG::debugging { import com.tinyspeck.debug.Console; }

	/**
	 * A controller that manages LocationItemstackView rook overlay.
	 */
	public class LisRookManager {
		private const ROOK_ANIMATION_NAME:String = "rooked_halo";
		private const ROOK_OVERLAY_TSID:String = "emotional_bear"
		
		private var _rooked_overlay:TSSprite;
		private var _rooked:Boolean = false;
		private var lisView:LocationItemstackView;
		
		public function LisRookManager(lisView:LocationItemstackView) {
			this.lisView = lisView;
		}
		
		public function rook():void {
			if (_rooked) return;
			_rooked = true;

			if (!_rooked_overlay) {
				createRookOverlay();
			} else {
				presentRookOverlay();
			}
		}
		
		private function presentRookOverlay():void {
			if (!_rooked_overlay.parent) {
				DisplayObjectContainer(lisView).addChild(_rooked_overlay as DisplayObject);
			}
			positionRookedOverlay();
		}
		
		private function fadeInOverlay():void {
			_rooked_overlay.alpha = 0;
			TSTweener.removeTweens(_rooked_overlay);
			TSTweener.addTween(_rooked_overlay, {alpha:1, transition:'linear', time:.6});
		}
		
		private function createRookOverlay():void {
			
			_rooked_overlay = new ItemIconView(ROOK_OVERLAY_TSID, 108, ROOK_ANIMATION_NAME, 'center_bottom');
			var rookIIV:ItemIconView = _rooked_overlay as ItemIconView;
			
			if (!rookIIV.loaded) {
				rookIIV.addEventListener(TSEvent.COMPLETE, onRookOverlayCreated);
			} else {
				onRookOverlayCreated(null);
			}
		}
		
		private function onRookOverlayCreated(e:TSEvent):void {						
			(lisView as DisplayObjectContainer).addChild(_rooked_overlay);
			_rooked_overlay.visible = false;
			presentRookOverlay();
		}
		
		public function unrook():void {
			if (!_rooked) return;
			_rooked = false;
			
			if (_rooked_overlay) {
				if (_rooked_overlay.parent) {
					TSTweener.removeTweens(_rooked_overlay);
					TSTweener.addTween(_rooked_overlay, {alpha:0, transition:'linear', time:.6, onComplete:function():void {
						if (_rooked_overlay.parent) _rooked_overlay.parent.removeChild(_rooked_overlay);
					}});
				}
			}
		}
		
		public function positionRookedOverlay():void {
			if (!_rooked) return;
			if (!_rooked_overlay) return;
			if (!lisView.is_loaded) return;
			if (_rooked_overlay.visible) return;
			
			_rooked_overlay.x = 0;
			var interactionBounds:Rectangle = lisView.interactionBounds;
			_rooked_overlay.y = lisView.interactionBounds.y + 12;
			
			if (!_rooked_overlay.visible) {
				_rooked_overlay.visible = true;
				fadeInOverlay();
			}
		}

		public function dispose():void {

			if (!_rooked_overlay) return;
			unrook();
		}

		public function get rooked_overlay():TSSprite { return _rooked_overlay; }
		public function get rooked():Boolean { return _rooked; }
	}
}