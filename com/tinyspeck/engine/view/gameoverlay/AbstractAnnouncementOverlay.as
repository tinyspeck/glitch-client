package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.NewxpLogger;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.control.engine.AnnouncementController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.data.client.OverlayMouse;
	import com.tinyspeck.engine.data.client.OverlayOpacity;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingOverlayClickVO;
	import com.tinyspeck.engine.net.NetOutgoingOverlayDismissedVO;
	import com.tinyspeck.engine.net.NetOutgoingOverlayDoneVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.port.HouseManager;
	import com.tinyspeck.engine.port.IChatBubble;
	import com.tinyspeck.engine.port.IDisposableSpriteChangeHandler;
	import com.tinyspeck.engine.port.QuoinAnimation;
	import com.tinyspeck.engine.port.SlugAnimator;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.AbstractAvatarView;
	import com.tinyspeck.engine.view.IAnnouncementArtView;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.maps.HubMapDialog;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Slug;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.WordProgressBar;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	
	public class AbstractAnnouncementOverlay extends DisposableSprite implements IDisposableSpriteChangeHandler, ITipProvider {
		
		protected var _art_view:IAnnouncementArtView;
		protected var tf_container:Sprite = new Sprite();
		protected var art_container:Sprite = new Sprite();
		private var _finishing:Boolean = false;
		private var _running:Boolean = false;
		private var _annc:Announcement;
		protected var model:TSModelLocator;
		protected var art_and_disimisser_container:Sprite = new Sprite();
		protected var dismisser:DismissableBar = new DismissableBar();
		protected var word_progress_bar:WordProgressBar = new WordProgressBar();
		protected var bubble_thought_do:MovieClip;
		protected var bubble_placard_do:Sprite;
		protected var chat_bubble:IChatBubble;
		protected var tf:TSLinkedTextField = new TSLinkedTextField();
		protected var text_index:int = 0;
		protected var tf_padd:int = 15;
		protected var fade_in_sec:Number;
		protected var fade_out_sec:Number;
		protected var advance_button:Button;
		protected var advance_button_wh:int = 70;
		protected var advance_button_margin_left:int = 10;
		protected var slug_animator:SlugAnimator = new SlugAnimator();
		protected var tip_text:String;
		protected var tip_pt:Point = new Point();
		protected var tip_ob:Object = { pointer: WindowBorder.POINTER_BOTTOM_CENTER };
		protected var waiting_on_click_payload_rsp:Boolean;
		protected var aao_uid:String;
		public static var aao_count:int;
		
		public function AbstractAnnouncementOverlay() {
			super();
			aao_uid = 'AAO_'+(aao_count++)
			model = TSModelLocator.instance;
		}
		
		protected function init():void {
			art_container.name = 'art_container';
			art_and_disimisser_container.name = 'art_and_disimisser_container';
			tf_container.name = 'tf_container';
			
			addChild(art_and_disimisser_container);
			art_and_disimisser_container.addChild(art_container);
			
			TFUtil.prepTF(tf);
			tf_container.addChild(tf);
			
			//listen for the close click on the word dismisser
			word_progress_bar.addEventListener(TSEvent.CLOSE, dismiss, false, 0, true);
		}
		
		public function specialBenchmarklog(txt:String):void {
			if (_annc && _annc.uid && _annc.uid.indexOf('subway_window') == 0) {
				Benchmark.addCheck('AOL.specialBenchmarklog '+_annc.uid+' '+txt);
			}
		}
		
		public function worldDisposableSpriteSubscribedHandler(sp:DisposableSprite):void {
		}
		
		public function worldDisposableSpriteDestroyedHandler(sp:DisposableSprite):void {
		}
		
		public function worldDisposableSpriteChangeHandler(sp:DisposableSprite):void {
		}
		
		public function placeByLocationItemstackView(lis_view:LocationItemstackView):void {
		}
		
		public function placeByPcView(pc_view:AbstractAvatarView):void {
		}
		
		protected function showText(index:int = 0):void {
			text_index = index;
			if (annc.chat_text && text_index < annc.chat_text.length) {
				model.activityModel.activity_message = Activity.createFromCurrentPlayer(annc.chat_text[text_index]);
			}
		}
		
		protected function showDismisser():void {
			return;
		}
		
		protected function showWordProgress():void {
			
		}
		
		protected function showBubble():void {
			return;
		}
		
		protected function onMetabolicChange(slug:Slug):void {
			
		}
		
		public function cancel():void {
			finish();
		}
		
		protected function dismiss(event:Event = null):void {
			if (!_annc.dismissible) return;
			
			finish();
			
			if (_annc.dismiss_payload) {
				TSFrontController.instance.genericSend(new NetOutgoingOverlayDismissedVO(_annc.dismiss_payload));
			}
		}
		
		public function changeScale(newScale:Number, in_time:Number):void {
			var art_view_do:DisplayObject = this._art_view as DisplayObject;
			
			TSTweener.addTween(art_view_do, {scaleX: newScale, scaleY: newScale, time:in_time, transition:'easeOutBack'});
		}
		
		protected function cleanArtView():void {
			var art_view_do:DisplayObject = _art_view as DisplayObject;
			if (art_view_do) {
				if (art_view_do.parent) art_view_do.parent.removeChild(art_view_do);
				_art_view.dispose();
			}
			_art_view = null;
		}
		
		protected function done():void {
			if (_annc) {
				_annc.client_done = getTimer();
			}
			//Console.warn(annc.locking)
			TSTweener.removeTweens(dismisser);
			TSTweener.removeTweens(this);
			_finishing = false;
			_running = false;
			text_index = 0;
			if (parent) parent.removeChild(this);
			if (bubble_placard_do && bubble_placard_do.parent) bubble_placard_do.parent.removeChild(bubble_placard_do);
			if (bubble_thought_do && bubble_thought_do.parent) bubble_thought_do.parent.removeChild(bubble_thought_do);
			if (chat_bubble && DisplayObject(chat_bubble).parent) DisplayObject(chat_bubble).parent.removeChild(DisplayObject(chat_bubble));
			if (advance_button && advance_button.parent) advance_button.parent.removeChild(advance_button);
			if (tf_container.parent) tf_container.parent.removeChild(tf_container);
			if (dismisser.parent || word_progress_bar.parent) {
				slug_animator.end();
				if (dismisser.parent) dismisser.parent.removeChild(dismisser);
				if (word_progress_bar.parent) word_progress_bar.parent.removeChild(word_progress_bar);
			}
			
			cleanArtView();
			
			if (_annc) {
				AnnouncementController.instance.overlayIsDone(_annc, this);
				
				if (_annc.uid == 'phantom_glitch') {
					Benchmark.addCheck('phantom_glitch done');
				}
				
				CONFIG::debugging {
					if (Console.priOK('435')) {
						
						var str:String = 'done\n';
						str+= 'annc: '+						_annc.type+' '+_annc.local_uid+' '+_annc.item_class+'\n';
						str+= 'duration: '+					(_annc.duration)+'\n';
						str+= 'delay_ms: '+					(_annc.delay_ms)+'\n';
						str+= 'fade_in_sec: '+				(fade_in_sec)+'\n';
						str+= 'fade_out_sec: '+				(fade_out_sec)+'\n';
						str+= 'from client_received: '+		((_annc.client_done-_annc.client_received)/1000)+'\n';
						str+= 'from client_all_ready: '+	((_annc.client_done-_annc.client_all_ready)/1000)+'\n';
						str+= 'from client_faded_in: '+		((_annc.client_done-_annc.client_faded_in)/1000)+'\n';
						str+= 'from client_finished: '+		((_annc.client_done-_annc.client_finished)/1000)+'\n';
						
						report(str);
					} else {
						report('done');
					}
				}
			}
			
			if (!CONFIG::debugging) {
				report('done');
			}
		}
		
		public function report(str:String):void {
			CONFIG::debugging {
				if (_annc) Console.priinfo(435, 'ANNC REPORT: aao_uid:'+aao_uid+' name:'+name+' annc.local_uid:'+((_annc)? _annc.local_uid : 'NO_ANNC')+' '+str);
			}
		}
		
		public function setFadeOutSec():void {
			fade_out_sec = annc.fade_out_sec;
		}
		
		public function go(annc:Announcement):void {
			// by default, do this. Then in allReady we can make it enabled if needed
			mouseEnabled = false;
			mouseChildren = false;
			
			this._annc = annc;
			report('go');
			fade_in_sec = annc.fade_in_sec;
			setFadeOutSec();
			if (annc.duration) {
				fade_in_sec = Math.min(fade_in_sec, (annc.duration/3)/1000);
				fade_out_sec = Math.min(fade_out_sec, (annc.duration/3)/1000);
			}
			
			//does this have any mouse stuff?
			art_container.buttonMode = art_container.useHandCursor = false;
			tip_text = null;
			waiting_on_click_payload_rsp = false;
			setOverlayMouse(annc.overlay_mouse);
			
			//handle the opacity
			setOpacity(annc.overlay_opacity);
			
			//do we want a drop shadow on it?
			filters = !annc.use_drop_shadow ? null : StaticFilters.loadingTip_DropShadowA;
		}
		
		protected function afterArtViewLoad(e:TSEvent):void {
			return;
		}
		
		protected function allReady():void {
			if (_finishing || !_running) return;
			// if this annc is not dismissible, and is not otherwise specified as clickable, make it invisible to the mouse
			
			if (!_annc.dismissible && !_annc.click_to_advance && (!_annc.overlay_mouse || !_annc.overlay_mouse.is_clickable)) {
				mouseEnabled = false;
				mouseChildren = false;
			} else {
				mouseEnabled = true;
				mouseChildren = true;
			}
			
			return;
		}
		
		protected function hasMultipleTexts():Boolean {
			if (_annc.text && _annc.text.length > 1) return true;
			return false;
		}
		
		private function advance(e:Event=null):void {
			if (!_annc) {
				CONFIG::debugging {
					Console.error('no annc?');
				}
				return;
			}
			if (!_annc.text) {
				CONFIG::debugging {
					Console.error('no annc.text?');
				}
				return;
			}
			
			if (canAdvance()) {
				showText(text_index+1);
			} else {
				finish(0);
			}
		}
		
		private function canAdvance():Boolean {
			if (!_annc.text || _annc.text.length < 1 || text_index == _annc.text.length-1) {
				return false;
			}
			
			return true;
		}
		
		private function onClick(e:Event):void {
			advance();
			StageBeacon.stage.focus = StageBeacon.stage;
		}
		
		protected function artClickFeedback():void {
			if(waiting_on_click_payload_rsp) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			if(!_annc.overlay_mouse.allow_multiple_clicks) {
				// Switch off hand cursor and unregister tooltip
				art_container.buttonMode = art_container.useHandCursor = false;
				TipDisplayManager.instance.unRegisterTipTrigger(this);
				
				//remove the listener
				if(art_container.hasEventListener(MouseEvent.CLICK)){
					art_container.removeEventListener(MouseEvent.CLICK, onArtClick);
				}
			}
		}
		
		protected function onArtClick(event:Event):void {
			if(!_annc.overlay_mouse) return;
			
			this.artClickFeedback();
			
			if (!_annc.overlay_mouse.click_payload) {
				if (_annc.overlay_mouse.click_client_action) {
					if (_annc.overlay_mouse.click_client_action.type == OverlayMouse.TYPE_CHANGE_TOWER) {
						//open chassis changer
						HouseManager.instance.openChassisChanger('furniture_tower_chassis');
					}
				}
				
				if(_annc.overlay_mouse.dismiss_on_click){
					finish();
				}
				return;
			}
			
			//this will pass the click_payload and uid off tothe server to do stuff
			waiting_on_click_payload_rsp = true;
			TSFrontController.instance.genericSend(
				new NetOutgoingOverlayClickVO(_annc.uid, _annc.overlay_mouse.click_payload), 
				onArtClickResponse, 
				onArtClickResponse
			);
			
			var payload_str:String;
			try {
				payload_str = StringUtil.getJsonStr(_annc.overlay_mouse.click_payload);
			} catch (err:Error) {
				payload_str = _annc.overlay_mouse.click_payload.toString();
			}
			
			NewxpLogger.log('overlay_click_sent_'+_annc.uid, _annc.uid+' '+payload_str);
		}
		
		protected function onArtClickResponse(nrm:NetResponseMessageVO):void {
			if(!_annc.overlay_mouse) return;
			
			//if this was a success and we need to dismiss it after it's clicked, go ahead and do that
			if(nrm.success && _annc.overlay_mouse.dismiss_on_click){
				finish();
				return;
			}
			
			//clear out the click param
			if(_annc.overlay_mouse.dismiss_on_click || _annc.overlay_mouse.allow_multiple_clicks) {
				waiting_on_click_payload_rsp = false;
			}
			
			//add the listener back if it's not there
			if(!nrm.success || _annc.overlay_mouse.allow_multiple_clicks){
				setOverlayMouse(_annc.overlay_mouse);
			}
		}
		
		public function setArtViewState(state:Object, config:Object, reposition:Boolean):void {
			_annc.state = state;
			_annc.config = config;
			if (true) {
				showArtViewState(reposition)
			}
		}
		
		public function setOverlayMouse(overlay_mouse:OverlayMouse):void {
			if(!overlay_mouse) return;
			
			//show da finger
			art_container.buttonMode = art_container.useHandCursor = overlay_mouse.is_clickable;
			
			//tool tip
			if(overlay_mouse.txt){
				tip_text = overlay_mouse.txt;
				TipDisplayManager.instance.registerTipTrigger(this);
			}
			else if(TipDisplayManager.instance.isTipTriggerRegistered(this)){
				TipDisplayManager.instance.unRegisterTipTrigger(this);
			}
			
			//mouse listener
			if(overlay_mouse.is_clickable && !art_container.hasEventListener(MouseEvent.CLICK)){
				waiting_on_click_payload_rsp = false;
				art_container.addEventListener(MouseEvent.CLICK, onArtClick, false, 0, true);
			}
		}
		
		public function setOpacity(overlay_opacity:OverlayOpacity):void {
			if (!overlay_opacity) return;
			
			//set the opacity
			TSTweener.addTween(this, {alpha:overlay_opacity.opacity, time:overlay_opacity.opacity_ms/1000, transition:'linear'});
			
			// because that woudl be stupid
			if (overlay_opacity.opacity_end == -1) return;
			
			if(overlay_opacity.opacity_end != overlay_opacity.opacity){
				//if we want to delay and fade all at once
				TSTweener.addTween(this, {
					alpha:overlay_opacity.opacity_end, 
					time:overlay_opacity.opacity_end_ms/1000, 
					delay:overlay_opacity.opacity_ms/1000 + overlay_opacity.opacity_end_delay_ms/1000,
					transition:'linear'
				});
			}
		}
		
		public function setText(txt:Array):void {
			text_index = 0;
			_annc.text = txt;
			showText(text_index);
		}
		
		private function showArtViewState(reposition:Boolean = false):void {
			if (_art_view) {
				if (_art_view is ArbitrarySWFView) {
					var art_view_ASWF:ArbitrarySWFView = _art_view as ArbitrarySWFView;
					if (art_view_ASWF.mc && art_view_ASWF.mc.hasOwnProperty('start')) {
						art_view_ASWF.mc.start(_annc.state);
					}
				} else if (_art_view is ItemIconView) {
					var art_view_IIV:ItemIconView = _art_view as ItemIconView;
					if (_annc.state || _annc.config) {
						art_view_IIV.icon_animate({state:_annc.state, config:_annc.config}, reposition);
					}
				} else if (_art_view is ArbitraryFLVView) {
					var art_view_AFLV:ArbitraryFLVView = _art_view as ArbitraryFLVView;
					art_view_AFLV.playFrom(0);
				}
			}
		}
		
		protected function onFadeInStart():void {
			report('fadeIn onStart');
			showArtViewState();
		};
		
		protected function onFadeInComplete():void {
			report('fadeIn onComplete');
			//if (annc.locking) AnnouncementController.instance.takeFocus(); // instead we're locking at annc start regardless of when fadein happnes
			
			_annc.client_faded_in = getTimer();
			
			if (_annc.sync_sound) {
				SoundMaster.instance.playSound(_annc.sync_sound, (_annc.loop_count ? _annc.loop_count : 0), (_annc.fade ? _annc.fade : 0), false, _annc.is_exclusive, _annc.allow_multiple);
			}
			
			if (_annc.text && _annc.click_to_advance_hubmap_triggered) {
				HubMapDialog.instance.addEventListener(TSEvent.STARTED, advance);
			}
			
			if (_annc.text && _annc.click_to_advance_hubmap_closed_triggered) {
				HubMapDialog.instance.addEventListener(TSEvent.CLOSE, advance);
			}
			
			if (_annc.locking && _annc.overlay_mouse && _annc.overlay_mouse.dismiss_on_click && _annc.overlay_mouse.is_clickable) {
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onArtClick);
			}
			
			if (_annc.text && _annc.click_to_advance) {
				
				addEventListener(MouseEvent.CLICK, onClick);
				if (_annc.click_to_advance_hubmap_triggered && !HubMapDialog.instance.hasEventListener(TSEvent.STARTED)) {
					HubMapDialog.instance.addEventListener(TSEvent.STARTED, advance);
				}
				if (_annc.locking) {
					TSFrontController.instance.getMainView().gameRenderer.addEventListener(MouseEvent.CLICK, onClick);
					KeyBeacon.instance.addEventListener(KeyBeacon.HIGH_PRIO_KEY_DOWN, allKeyHandler);
				}
				
			} else if (_annc.animate_to_top) {
				
				if (_annc.duration === 0) {
					animateToTop()
				} else {
					animateToTop((_annc.duration/1000)-(fade_in_sec*2))
				}
				
			} else if (_annc.animate_to_buffs) {
				
				if (_annc.duration === 0) {
					animateToBuffs()
				} else {
					animateToBuffs((_annc.duration/1000)-(fade_in_sec*2))
				}
				
			} else if (_annc.duration === 0) {
				
			} else {
				
				finish((_annc.duration/1000)-(fade_in_sec*2));
				
			}
		};
		
		protected function fadeIn(delay:Number = 0):void {
			report('fadeIn');
			if (fade_in_sec) {
				TSTweener.addTween(this, {
					alpha:_annc.overlay_opacity.opacity,
					time:fade_in_sec,
					delay:delay,
					transition:'easeOutBack',
					onStart:onFadeInStart, 
					onComplete:onFadeInComplete
				});
			} else {
				onFadeInStart();
				alpha = _annc.overlay_opacity.opacity;
				onFadeInComplete();
			}
		}
		
		private function animateToTop(delay:int = 0):void {
			var self:AbstractAnnouncementOverlay = this as AbstractAnnouncementOverlay;
			
			TSTweener.addTween(self, {time:delay, onComplete:function():void {
				TSFrontController.instance.unregisterDisposableSpriteChangeSubscriber(self);
				var pt:Point = self.parent.localToGlobal(new Point(self.x, self.y));
				if (self.parent) self.parent.removeChild(self);
				TSFrontController.instance.addUnderCursor(self);
				self.x = pt.x;
				self.y = pt.y;
				var dest_pt:Point = YouDisplayManager.instance.getHeaderCenterPt();
				/*dest_pt.x+= model.layoutModel.gutter_w;
				dest_pt.y+= model.layoutModel.header_h;*/
				dest_pt.y+= (self._art_view.wh/2);  // assumes it is a bottom_center regsitered thing, and that we want it's center to go to the dest_pt
				TSTweener.addTween(self, {x:dest_pt.x, y:dest_pt.y, time:1, onComplete:function():void {
					self.finish();
				}})
			}});
		}
		
		private function animateToBuffs(delay:int = 0):void {
			var self:AbstractAnnouncementOverlay = this as AbstractAnnouncementOverlay;
			var final_scale:Number = .2;
			
			TSTweener.addTween(self, {time:delay, onComplete:function():void {
				TSFrontController.instance.unregisterDisposableSpriteChangeSubscriber(self);
				var pt:Point = self.parent.localToGlobal(new Point(self.x, self.y));
				if (self.parent) self.parent.removeChild(self);
				TSFrontController.instance.addUnderCursor(self);
				self.x = pt.x;
				self.y = pt.y;
				var dest_pt:Point = new Point();
				dest_pt.x = BuffViewManager.instance.x;
				dest_pt.y = BuffViewManager.instance.y;
				dest_pt = BuffViewManager.instance.parent.localToGlobal(dest_pt);
				//dest_pt.y+= (self.art_view.wh/2);  // assumes it is a bottom_center regsitered thing, and that we want it's center to go to the dest_pt
				TSTweener.addTween(self, {scaleY:final_scale, scaleX:final_scale, x:dest_pt.x, y:dest_pt.y, time:1, onComplete:function():void {
					self.finish();
					if (!self.parent) return;
					if (!_annc.and_burst) return;
					if (!_annc.and_burst_text) return;
					var qa:QuoinAnimation = AnnouncementController.instance.getQuoinAnimation();
					qa.x = self.x;
					qa.y = self.y;
					self.parent.addChild(qa);
					qa.go(0, _annc.and_burst_value, _annc.and_burst_text);
				}})
			}});
		}
		
		private function allKeyHandler(e:KeyboardEvent):void {
			if (!(model.stateModel.focused_component is AnnouncementController)) {
				return;
			}
			
			if (KeyBeacon.instance.anyWASDorArrowKeysPressed()) {
				return;
			}
			
			if (e.keyCode == Keyboard.SPACE) {
				return
			}

			advance();
			StageBeacon.stage.focus = StageBeacon.stage;
		}
		/*
		private function advanceKeyHandler(e:Event):void {
			if (model.stateModel.focused_component is AnnouncementController) {
				advance();
				StageBeacon.stage.focus = StageBeacon.stage;
			}
		}
		*/
		private function markAsFinishing():void {
			_finishing = true;
			name = 'FINSIHING_'+name;
			if (finish_delay) {
				report('finish tween starting delay:'+finish_delay+' time:'+fade_out_sec);
			}
		}
		
		private var finish_delay:Number
		private function onFadeOutStart():void {
			if (finish_delay) {
				markAsFinishing();
			}
		
			TSFrontController.instance.getMainView().gameRenderer.removeEventListener(MouseEvent.CLICK, onClick);
			HubMapDialog.instance.removeEventListener(TSEvent.STARTED, advance);
			HubMapDialog.instance.removeEventListener(TSEvent.CLOSE, advance);
			removeEventListener(MouseEvent.CLICK, onClick);
			/*
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, advanceKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.SPACE, advanceKeyHandler);
			*/
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onArtClick);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.SPACE, onArtClick);
			KeyBeacon.instance.removeEventListener(KeyBeacon.HIGH_PRIO_KEY_DOWN, allKeyHandler);
			
			if (_annc && _annc.done_payload) {
				TSFrontController.instance.genericSend(new NetOutgoingOverlayDoneVO(_annc.done_payload));
			}
			
			if (_annc && _annc.done_cancel_uids) {
				for (var i:int = 0;i<_annc.done_cancel_uids.length;i++) {
					if (_annc.done_cancel_uids[int(i)] == _annc.uid) continue;
					AnnouncementController.instance.cancelOverlay(_annc.done_cancel_uids[int(i)]);
				}
			}
			
			if (_annc && _annc.done_anncs) {
				model.activityModel.announcements = Announcement.parseMultiple(_annc.done_anncs);
			}
		}
		
		private function onFadeOutComplete():void {
			report('finish tween complete');
			if (_annc) {
				_annc.client_finished = getTimer();
			}
			done();
		}
		
		protected function finish(delay:Number = 0):void {
			report('finish');
			finish_delay = delay;
			
			// I THINK: this is a little problematic and should maybe be rethought, because finish is called
			// right after fadein (with a delay) in some cases. So maybe removeTweens should be done after the delay?
			TSTweener.removeTweens(this);
				
			if (fade_out_sec || finish_delay) {
				if (!finish_delay) {
					markAsFinishing();
				}
				
				TSTweener.addTween(this, {
					alpha:0,
					time:fade_out_sec,
					delay:delay,
					transition:'easeOutBack',
					onStart:onFadeOutStart,
					onComplete:onFadeOutComplete
				});
			} else {
				onFadeOutStart();
				alpha = 0;
				onFadeOutComplete();
			}
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target || !tip_text) return null;
			if(!parent) return null;
			
			//check if we have a tip delta, if so use that, otherwise just use a regular tip
			tip_ob.placement = null;
			if(_annc.overlay_mouse && _annc.overlay_mouse.txt_delta_y){
				tip_pt.x = x;
				tip_pt.y = y;
				tip_pt = parent.localToGlobal(tip_pt);
				
				//set the placement
				tip_ob.placement = {
					x: tip_pt.x, 
						y: tip_pt.y + _annc.overlay_mouse.txt_delta_y
				};
			}
			
			//set the text
			tip_ob.txt = tip_text;
			
			return tip_ob;
		}

		public function get annc():Announcement { return _annc; }
		public function set annc(value:Announcement):void { _annc = value; }
		public function get running():Boolean { return _running; }
		public function set running(value:Boolean):void { _running = value; }
		public function get finishing():Boolean { return _finishing; }
		public function set finishing(value:Boolean):void { _finishing = value; }
		public function get art_view():IAnnouncementArtView { return _art_view; }
		
		override public function dispose():void {
			// DO NOTHING! These are pooled!
		}
	}
}