package com.tinyspeck.engine.view.avatar {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.memory.IDisposable;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.ChatBubble;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.view.AbstractAvatarView;
	
	import flash.display.Sprite;
	import flash.geom.Point;

	/**
	 * Manages a chat bubble for an IAbstractAvatarView 
	 */
	public class AvaChatBubbleManager implements IDisposable {
		
		private const SHOW_TIME_PER_WORD_MS:uint = 300;
		private const MIN_SHOW_TIME_MS:uint = 4000;
		private const MAX_SHOW_TIME_MS:uint = 10000;
		
		private var _currentChatBubble:ChatBubble;
		private var model:TSModelLocator;
		private var avatar:AbstractAvatarView;
		private var _bubbleLocked:Boolean = false;
		private var bubbleHideTimer:uint;
		
		public function AvaChatBubbleManager(avatar:AbstractAvatarView) {
			this.avatar = avatar;
			
			model = TSModelLocator.instance;
		}
		
		public function get lock_chat_bubble():Boolean { return _bubbleLocked; }
		public function set lock_chat_bubble(value:Boolean):void {
			if(_bubbleLocked && !value){
				//if we are unlocking, and the bubble is locked, fade it out
				bubbleHideTimer = StageBeacon.setTimeout(hideBubbleTimerHandler, 500);
			}
			
			_bubbleLocked = value;
		}		
		
		/** Show the chat bubble with specified message and additional sprite. Lock it if needed */
		public function showBubble(msg:String, extra_sp:Sprite = null, is_locked:Boolean = false):void {
			//if we are locking this bubble, do nothing
			if(_bubbleLocked) return;
			
			bubbleShow(msg, extra_sp);
			
			var ms:int = Math.min(MAX_SHOW_TIME_MS, MIN_SHOW_TIME_MS+(msg.split(' ').length * SHOW_TIME_PER_WORD_MS));
			if(!is_locked){
				bubbleHideTimer = StageBeacon.setTimeout(hideBubbleTimerHandler, ms);
			}
			
			_bubbleLocked = is_locked;
		}
		
		private function hideBubbleTimerHandler():void {
			if (shouldDelayBubbleHiding()) {
				bubbleHideTimer = StageBeacon.setTimeout(hideBubbleTimerHandler, 500);
			} else {
				_currentChatBubble.hide(doAfterBubbleHide);
			}
		}	
		
		private function shouldDelayBubbleHiding():Boolean {
			if (avatar) {
				if (avatar.hitTestPoint(StageBeacon.stage.mouseX, StageBeacon.stage.mouseY, false)) return true;
				if (avatar.glowing) return true;
			}
			return false;
		}		
		
		/** Update the chat bubble's content */
		public function updateBubbleContent(new_txt:String, new_extra_sp:Sprite = null):void {
			//if we don't have any new text, use the one that's already there
			if (!_currentChatBubble) return;
			if(!new_txt) new_txt = _currentChatBubble.rawMessage;
			bubbleShow(new_txt, new_extra_sp);
		}
		
		/** Hide the bubble. */
		public function hideBubble(right_now:Boolean = false):void {
			if(!right_now){
				_bubbleLocked = false;
			}
			else if(_currentChatBubble){
				_bubbleLocked = false;
				_currentChatBubble.hide(doAfterBubbleHide);
			}
		}
		
		private function doAfterBubbleHide():void {
			TSFrontController.instance.unregisterDisposableSpriteChangeSubscriber(_currentChatBubble);
			if (_currentChatBubble.parent) _currentChatBubble.parent.removeChild(_currentChatBubble);
			_currentChatBubble = null;
			avatar.updateNameField();
		}		
		
		private function bubbleShow(msg:String, extra_sp:Sprite = null):void {
			if (!_currentChatBubble) {
				_currentChatBubble = new ChatBubble();
				_currentChatBubble.name = avatar.tsid;
			}
			
			_currentChatBubble.rawMessage = msg;
			
			var chat_y:int;
			var nativeAvatar:AbstractAvatarView = avatar as AbstractAvatarView;
			if (nativeAvatar && nativeAvatar.colored_sp && nativeAvatar.colored_sp.parent) {
				chat_y = -avatar.h-45;
			} else {
				chat_y = -avatar.h-10;
			}
			var chat_x:int = 0;
			const pc_label:String = model.worldModel.getPCByTsid(avatar.tsid).label;
			const send_msg:String = '<b><font color="'+
								  RightSideManager.instance.getPCColorHex(avatar.tsid)+'">'+
								  pc_label+':</font></b> '+RightSideManager.instance.parseClientLink(msg);
			
			if (_currentChatBubble.parent) {
				_currentChatBubble.parent.removeChild(_currentChatBubble);
			}
			
			if (bubbleHideTimer) { // it must be open
				StageBeacon.clearTimeout(bubbleHideTimer);
				bubbleHideTimer = 0;
			}
			
			TSFrontController.instance.getMainView().gameRenderer.placeOverlayInSCH(_currentChatBubble, 'CBM.bubbleShow '+(avatar?avatar.tsid:'???'));
			
			_currentChatBubble.showing_sig.addOnce(function():void {
				TSFrontController.instance.registerDisposableSpriteChangeSubscriber(_currentChatBubble, avatar);
				_currentChatBubble.worldDisposableSpriteChangeHandler(avatar);
			});
			_currentChatBubble.keep_in_viewport_within_reason = true;
			_currentChatBubble.show(send_msg, new Point(chat_x, chat_y), extra_sp);
			
			avatar.updateNameField();
		}
		
		/** Determine the orientation (scaleX) of the bubble based on the avatar's animation container's scaleX */
		public function orientBubble():void {
			if (!_currentChatBubble) return;
			_currentChatBubble.scaleX = avatar.animationScaleX;
		}		

		public function get currentChatBubble():ChatBubble {
			return _currentChatBubble;
		}
		
		public function dispose():void {
			_currentChatBubble
			if (_currentChatBubble) {
				if (_currentChatBubble.parent) _currentChatBubble.parent.removeChild(_currentChatBubble);
				_currentChatBubble.dispose();
				_bubbleLocked = false;
			}			
		}

	}
}