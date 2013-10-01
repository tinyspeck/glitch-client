package com.tinyspeck.engine.view.itemstack {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.data.reward.Rewards;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.ChatBubble;
	import com.tinyspeck.engine.port.SlugAnimator;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.ui.Slug;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import org.osflash.signals.Signal;

	public class LisChatBubbleManager {
		
		public const bubble_updated_sig:Signal = new Signal();
		public const AIVs_changed_sig:Signal = new Signal();
		
		private var lisView:LocationItemstackView;
		private var _chat_bubble:ChatBubble;
		private var model:TSModelLocator;
		private var bubble_hide_timer:uint;
		private var _aivs_hidden_for_bubble:Boolean;
		
		public function LisChatBubbleManager(lisView:LocationItemstackView) {
			this.lisView = lisView;
			model = TSModelLocator.instance;
		}
		
		public function handleBubble(msg:Object):void {
			if (!msg) return;
			
			if (!msg) return;
			if (!msg.txt) return;
			if (!lisView.itemstack) return;
			
			// if this is a temporary overalay and the stack is not in view, ignore it
			// on second thought I do not think this is necessary because if there is no duration,
			// then the bubble will go away anyway in X seconds based on how long the txt is
			// if (!worth_rendering && itemstack.bubble_duration) return;
			
			if (!_chat_bubble) {
				_chat_bubble = new ChatBubble();
			}
			
			// for debug
			//msg.slugs = {mood:-5};//, energy:-10, favor:-5, xp:-10}
			
			var extra_sp:Sprite;
			var afterBubbleReady:Function;
			
			if (msg.rewards) {
				var rewards:Vector.<Reward> = Rewards.fromAnonymous(msg.rewards);
				var slug:Slug;
				var slugs:Vector.<Slug> = new Vector.<Slug>();
				var i:int;
				var next_x:int = 0;
				var next_y:int = 0;
				var padd:int = 4;
				var max_w:int = _chat_bubble.max_w;
				var slug_animator:SlugAnimator = new SlugAnimator();
				
				extra_sp = new Sprite();
				
				for(i; i < rewards.length; i++){
					if (rewards[int(i)].type != Reward.ITEMS && rewards[int(i)].amount != 0) {
						slug = new Slug(rewards[int(i)]);
						slug.x = next_x;
						slug.y = next_y;
						next_x = slug.x+slug.width+padd;
						extra_sp.addChild(slug);
						
						slugs.push(slug);
						
						if (next_x+slug.width > max_w) {
							next_x = 0;
							next_y = extra_sp.height+padd;
						}
					}
				}
				
				slug_animator.start();
				
				// pass this func to bubble() to be run when the bubble is displayed
				afterBubbleReady = function():void {
					for(var i:int = 0; i < slugs.length; i++){
						slugs[int(i)].animate(slug_animator);
					}
				}
			}
			
			bubble(msg.txt, (lisView.itemstack.bubble_duration || 0), extra_sp, afterBubbleReady, msg.offset_x, msg.offset_y, msg.allow_out_of_viewport_top);
		}
		
		private function bubble(msg:String, ms:int=0, extra_sp:Sprite=null, whenReady:Function=null, offset_x:int=0, offset_y:int=0, allow_out_of_viewport_top:Boolean=false):void {
			if (model.stateModel.all_bubbles_disabled) return;
			if (model.stateModel.hide_loc_itemstacks) return;
			
			lisView.bringToFront();
			if (!_chat_bubble) {
				_chat_bubble = new ChatBubble();
			}
			
			var chat_y:int = lisView.getYAboveDisplay();
			
			var send_msg:String = '<p>'+msg+'</p>';
			ms = ms || Math.min(10000, 4000+(msg.split(' ').length*300));
			
			if (DisplayObject(_chat_bubble).parent) {
				DisplayObject(_chat_bubble).parent.removeChild(DisplayObject(_chat_bubble));
			}
			
			TipDisplayManager.instance.unRegisterTipTrigger(lisView.hit_target);
			
			addBubbleWhereItGoes();
			
			_chat_bubble.showing_sig.addOnce(function():void {
				TSFrontController.instance.registerDisposableSpriteChangeSubscriber(_chat_bubble, lisView);
				_chat_bubble.keep_in_viewport_within_reason = true;
				_chat_bubble.allow_out_of_viewport_top = allow_out_of_viewport_top;
				_chat_bubble.worldDisposableSpriteChangeHandler(lisView);
				if (whenReady != null) whenReady();
			});
			var reverse_pointer:Boolean = offset_x < 0;
			_chat_bubble.show(send_msg, new Point(0+offset_x, chat_y+offset_y), extra_sp, 0, reverse_pointer);
			
			StageBeacon.clearTimeout(bubble_hide_timer);
			bubble_hide_timer = StageBeacon.setTimeout(_hideBubbleTimerHandler, ms);
			
			//hide the indicators
			_aivs_hidden_for_bubble = true;
			
			_chat_bubble.visible = lisView.visible;
			bubble_updated_sig.dispatch();
		}	
		
		public function addBubbleWhereItGoes():void {
			if (!_chat_bubble) return;
			
			TSFrontController.instance.getMainView().gameRenderer.placeOverlayInSCH(DisplayObject(_chat_bubble), 'LIV.addBubbleWhereItGoes');
		}	
		
		private function set aivs_hidden_for_bubble(value:Boolean):void {
			if (_aivs_hidden_for_bubble == value) return;
			_aivs_hidden_for_bubble = value;
			AIVs_changed_sig.dispatch();
		}		
		
		private function _hideBubbleTimerHandler():void {
			if (chat_bubble_showing) _chat_bubble.hide(_doAfterChatBubbleHide);
		}
		
		private function _doAfterChatBubbleHide():void {
			TSFrontController.instance.unregisterDisposableSpriteChangeSubscriber(_chat_bubble);
			if (DisplayObject(_chat_bubble).parent) DisplayObject(_chat_bubble).parent.removeChild(DisplayObject(_chat_bubble));
			
			// THIS WAS COMMENTED OUT AND I DO NOT KNOW WHY: (but it keeps tips from working on the damn thing after a bubble is shown)
			// later: hrmmm. maybe because of null ref errors in registerTipTrigger calling DisposableSprite.addEventListener, if the item has been disposed
			// so let's trying making sure it is on stage
			if (lisView.parent) TipDisplayManager.instance.registerTipTrigger(lisView.hit_target);
			
			//bring back the indicators
			_aivs_hidden_for_bubble = false;
		}
		
		public function getRidOfBubble():void {
			StageBeacon.clearTimeout(bubble_hide_timer);
			if (chat_bubble_showing) _chat_bubble.hide(_doAfterChatBubbleHide);
		}		
		
		private function get chat_bubble_showing():Boolean {
			return (_chat_bubble && _chat_bubble.showing);
		}
		
		public function hideChatBubble():void {
			if (_chat_bubble) _chat_bubble.visible = false;
		}
		
		public function repositionChatBubble(newPosition:Point):void {
			if (!chat_bubble_showing) return;
			
			_chat_bubble.positionContainer(newPosition);
		}
		
		public function showChatBubble():void {
			if (_chat_bubble) _chat_bubble.visible = true;
		}

		public function get aivs_hidden_for_bubble():Boolean {
			return _aivs_hidden_for_bubble;
		}
		
		
		public function dispose():void {
			if (_chat_bubble) {
				if (_chat_bubble.parent) _chat_bubble.parent.removeChild(_chat_bubble);
				_chat_bubble.dispose();
			}			
		}

	}
}