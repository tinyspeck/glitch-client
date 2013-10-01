package com.tinyspeck.engine.port {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.IWorthRenderable;
	import com.tinyspeck.engine.view.gameoverlay.maps.MiniMapView;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.chat.ContactList;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextFieldAutoSize;
	
	import org.osflash.signals.Signal;
	
	public class ChatBubble extends TSSpriteWithModel implements IChatBubble, IDisposableSpriteChangeHandler {
		private static const MIN_WIDTH:uint = 50;
		private static const MAX_WIDTH:uint = 276;
		
		private var afterAssetLoad:Function = null;
		private var extra_sp:Sprite;
		private var chat_tf:TSLinkedTextField = new TSLinkedTextField();
		private var _talk_bubble_pointer:DisplayObject;
		private var talk_bubble_body:DisplayObject;
		private var _showing:Boolean;
		private var all_container:Sprite = new Sprite();
		private var bubble_container:Sprite = new Sprite();
		private var chat_tf_container:Sprite = new Sprite();
		private var talk_bubble_body_is_loaded:Boolean;
		private var talk_bubble_pointer_is_loaded:Boolean;
		private var _keep_in_viewport:Boolean;
		private var _keep_in_viewport_within_reason:Boolean;
		private var _allow_out_of_viewport_top:Boolean;
		private var fade_ms:int;
		private var placed_y:int;
		private var placed_x:int;
		private var _offset_x:int;  //allows the bubble to be set to off-center
		private var _max_w:int = -1;  //-1 means use the static default
		private var check_worth_renderable:IWorthRenderable;
		private var _rawMessage:String;
		public var showing_sig:Signal = new Signal();
		
		public function ChatBubble(fade_ms:int = 100):void {
			super();
			this.fade_ms = fade_ms;
			buttonMode = false;
			useHandCursor = false;
			mouseEnabled = true;
			mouseChildren = true;
			
			_construct();
		}
		
		private static var reported_event_listening:Boolean;
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false) : void {
			if (type == Event.COMPLETE) {
				if (reported_event_listening) return;
				reported_event_listening = true;
				BootError.handleError('Someone is trying to listen to '+type+' events on ChatBubble', new Error('EVENT_LISTENING_CONSIDERED_HARMFUL'), ['signal_conversion'], true);
				
			} else {
				super.addEventListener(type, listener, useCapture, priority, useWeakReference);
			}
			
		}
		
		public function worldDisposableSpriteSubscribedHandler(sp:DisposableSprite):void {
			if (sp is IWorthRenderable) {
				check_worth_renderable = sp as IWorthRenderable;
			}
		}
		
		public function worldDisposableSpriteDestroyedHandler(sp:DisposableSprite):void {
			// the disp sp your were registered with has been destroyed
			// we don't need to do anything, as the lis_view or pc_view that contains this takes care of it
			check_worth_renderable = null;
		}
		
		public function worldDisposableSpriteChangeHandler(sp:DisposableSprite):void {
			x = placed_x+sp.x;
			y = placed_y+sp.y;
			
			keepInBounds();
		}
		
		private var reusable_rect:Rectangle;
		public function keepInBounds():void {
			// lets not do this if we're following an IWorthRenderable and it is !worth_rendering
			if (check_worth_renderable && !check_worth_renderable.worth_rendering) {
				return;
			}
			
			var lm:LayoutModel = model.layoutModel;
			
			// should we keep it visible by restricting how high it can go?
			if (!allow_out_of_viewport_top) {
				reusable_rect = this.getRect(StageBeacon.stage);
				reusable_rect.y-= (25+lm.header_h); // keep it 25 or more pixels from top of stage
				if (reusable_rect.y < 0) {
					if (keep_in_viewport && !keep_in_viewport_within_reason) {
						y-= reusable_rect.y;
					} else { // only limit it for things that are not adjuested below
						y-= Math.max(-120, reusable_rect.y); // the Math.max(-120 makes it so that they do not appear UNDER pcs that are way above you, out of view
					}
				}
			}
			
			var account_for_map:Boolean;
			var test_y:Number;
			
			//if we need to keep this in the viewport, make it so!
			if (keep_in_viewport) {
				if (MiniMapView.instance.visible) {
					// if we collide with the map
					test_y = MiniMapView.instance.getBounds(StageBeacon.stage).y + MiniMapView.instance.h + 10;
					if (getBounds(StageBeacon.stage).y < test_y) {
						account_for_map = true;
					}
				}
				
				_talk_bubble_pointer.x = _talk_bubble_pointer_placed_x;
				_talk_bubble_pointer.scaleX = 1;
				
				reusable_rect = getBounds(this);
				var pt:Point = localToGlobal(new Point(0,0));
				var min_x:int = lm.gutter_w+10;
				var max_x:int = lm.loc_vp_w + lm.gutter_w - ContactList.BUTTON_W;
				
				if (account_for_map) {
					max_x-= MiniMapView.instance.w+10;
				}

				
				var offset_x:int = reusable_rect.x + reusable_rect.width;
				var max_y:int = lm.header_h + lm.loc_vp_h;
				
				if (!keep_in_viewport_within_reason && pt.y - reusable_rect.height > max_y){
					y -= pt.y - reusable_rect.height - max_y;
				}
				
				var adj_x:int;
				if (pt.x + offset_x > max_x){
					adj_x = (pt.x + offset_x) - max_x;
				} else if (pt.x + reusable_rect.x < min_x){
					adj_x = (pt.x + reusable_rect.x) - min_x;
				}
				
				if (adj_x && keep_in_viewport_within_reason) {
					var adj_x_limit:int = 100;
					if (adj_x>0) { // right side of screen
						if (account_for_map) {
							// this is not perfect, but the algo for making it better id beyond me
							adj_x_limit = 300;
						}
						adj_x = Math.min(adj_x, adj_x_limit);
					} else {
						adj_x = Math.max(adj_x, -adj_x_limit);
					}
				}
				
				if (adj_x) {
					x -= adj_x;
					reusable_rect = bubble_container.getRect(bubble_container);
					var min_x_pointer:int = -((reusable_rect.width/2)-10);
					var max_x_pointer:int = (reusable_rect.width/2)-(10+_talk_bubble_pointer_w);
					if (scaleX < 0) {
						_talk_bubble_pointer.x-= adj_x;
					} else {
						_talk_bubble_pointer.x+= adj_x;
					}
					
					// constrain
					_talk_bubble_pointer.x = Math.max(_talk_bubble_pointer.x, min_x_pointer);
					
					// if we're at the right edge,
					if (_talk_bubble_pointer.x >= max_x_pointer) {
						// flip the pointer if it is pretty far away
						if (_talk_bubble_pointer.x > max_x_pointer+1 || _reverse_pointer) {
							_talk_bubble_pointer.scaleX = -1;
							_talk_bubble_pointer.x = max_x_pointer+_talk_bubble_pointer_w; // because we flipped it, add in the pointer width too
						} else {
							_talk_bubble_pointer.x = max_x_pointer;
						}
					} else if (_reverse_pointer) {
						_talk_bubble_pointer.scaleX = -1;
						_talk_bubble_pointer.x+= _talk_bubble_pointer_w
					}
				} else if (_reverse_pointer) {
					_talk_bubble_pointer.scaleX = -1;
					_talk_bubble_pointer.x+= _talk_bubble_pointer_w
					
				}
			}
		}
		
		override protected function _construct():void {
			super._construct();
			
			addChild(all_container);
			all_container.addChild(bubble_container);
			bubble_container.visible = false;
			
			TFUtil.prepTF(chat_tf);
			
			alpha = 0;
			
			// because this gets created in god_item_viewer (sigh) were AssetManager.instance[X] does not exist, try and catch
			try {
				_talk_bubble_pointer = new AssetManager.instance.assets.talk_bubble_point();
				_talk_bubble_pointer.addEventListener(Event.COMPLETE, function(e:Event):void {
					_talk_bubble_pointer = (Loader(e.target.getChildAt(0)).content as MovieClip);
					_talk_bubble_pointer.removeEventListener(Event.COMPLETE, arguments.callee);
					talk_bubble_pointer_is_loaded = true;
					if (afterAssetLoad != null) afterAssetLoad();
				});
				
				talk_bubble_body = new AssetManager.instance.assets.talk_bubble_body();
				talk_bubble_body.addEventListener(Event.COMPLETE, function(e:Event):void {
					talk_bubble_body.removeEventListener(Event.COMPLETE, arguments.callee);
					talk_bubble_body = (Loader(e.target.getChildAt(0)).content as MovieClip);
					talk_bubble_body_is_loaded = true;
					if (afterAssetLoad != null) afterAssetLoad();
				});
			} catch(err:Error) {
				_talk_bubble_pointer = new Sprite();
				talk_bubble_body = new Sprite();
				if (afterAssetLoad != null) afterAssetLoad();
			}
			
			var shadow:DropShadowFilter = new DropShadowFilter();
			shadow.distance = 2;
			shadow.angle = 90;
			shadow.alpha = .9;
			shadow.blurX = 4;
			shadow.blurY = 4;
			bubble_container.filters = [shadow];
			
			all_container.name = 'all_container';
			bubble_container.name = 'bubble_container';
			_talk_bubble_pointer.name = 'talk_bubble_pointer';
			talk_bubble_body.name = 'talk_bubble_body';
			chat_tf_container.name = 'chat_tf_container';
		}
		
		public function hide(callback_when_done:Function = null):void {
			afterAssetLoad = null;
			TSTweener.removeTweens(this);
			_showing = false;
			TSTweener.addTween(this, {alpha:0, time:fade_ms/1000, transition:'linear', onComplete: function():void {
				if (callback_when_done != null) callback_when_done();
			}});
		}
		
		public function get showing():Boolean {
			return _showing;
		}
		
		override public function set scaleX(value:Number):void {
			super.scaleX = value;
			chat_tf_container.scaleX = (scaleX < 0) ? -1 : 1;
		}
		
		private var _talk_bubble_pointer_placed_x:int;
		private var _talk_bubble_pointer_w:int = 25;
		private var _reverse_pointer:Boolean;
		public var is_convo:Boolean;
		public function show(msg:String, pt:Point=null, extra_sp:Sprite=null, force_tf_width:int=0, reverse_pointer:Boolean=false):void {
			_showing = true;
			
			// if talk_bubble_body is not loaded, let's wait until it is.
			if (!talk_bubble_body_is_loaded || !talk_bubble_pointer_is_loaded) {
				afterAssetLoad = function():void {
					show(msg, pt, extra_sp, force_tf_width, reverse_pointer);
				}
				return;
			}
			
			_reverse_pointer = reverse_pointer;
			
			afterAssetLoad = null;
			
			while (bubble_container.numChildren) bubble_container.removeChildAt(0);
			while (chat_tf_container.numChildren) chat_tf_container.removeChildAt(0);
			
			bubble_container.visible = false;
			var base_padd:int = 7;
			var padd:int;
			
			// reset!
			x = 0;
			y = 0;
			all_container.x = 0;
			all_container.y = 0;
			
			bubble_container.visible = true;
			bubble_container.addChild(chat_tf_container);
			chat_tf_container.addChild(chat_tf);
			this.extra_sp = extra_sp;
			
			if(msg.substr(0,2) != '<p') msg = '<p>'+msg+'</p>';
			
			//reset the tf so it can extend out
			chat_tf.autoSize = TextFieldAutoSize.LEFT;
			chat_tf.wordWrap = false;
			chat_tf.embedFonts = is_convo;
			chat_tf.htmlText = StringUtil.injectClass(msg, 'p', is_convo ? 'chat_bubble_convo' : 'chat_bubble');
			//take a snapshot of the width when it's nice and pretty
			const txt_w:int = chat_tf.width + 6;
			
			//lock the size right where it is, prevents links from dancing
			chat_tf.autoSize = TextFieldAutoSize.NONE;
			chat_tf.width = txt_w;
						
			//if we have a forced width or the current tf is too wide, set the width
			if(force_tf_width || chat_tf.width > max_w){
				chat_tf.wordWrap = true;
				chat_tf.width = force_tf_width ? force_tf_width : max_w;
			}
			
			//if we have a sprite to show, extend the TF to be as wide as the sprite if too small
			if(extra_sp && chat_tf.width < extra_sp.width){
				chat_tf.wordWrap = true;
				chat_tf.width = extra_sp.width;
			}
			
			//check to make sure we at least meet the min
			if(chat_tf.width < MIN_WIDTH){
				chat_tf.wordWrap = true;
				chat_tf.width = MIN_WIDTH;
			}
			
			//do the height stuff
			chat_tf.height = Math.max(20, chat_tf.textHeight + 6);
			
			if (pt) all_container.x = pt.x;
			chat_tf.x = -Math.round(chat_tf.width/2) + _offset_x;
			
			bubble_container.addChild(talk_bubble_body);
			bubble_container.addChild(chat_tf_container);
			
			padd = base_padd + Math.min(12, chat_tf.height*.065); // grow padding as the tf gets taller
			
			var tbh:Number;
			
			if (extra_sp) {
				chat_tf_container.addChild(extra_sp);
				extra_sp.y = chat_tf.y + chat_tf.height + base_padd;
				extra_sp.x = chat_tf.x + int(chat_tf.width/2 - extra_sp.width/2);
				
				tbh = extra_sp.y+extra_sp.height+(padd*2);
			} else {
				tbh = chat_tf.height+(padd*2);
			}
			
			talk_bubble_body.scale9Grid = new Rectangle(25, 25,  201-50, 114-54); //201, 114;
			
			talk_bubble_body.x = chat_tf.x-padd;
			talk_bubble_body.y = -padd;
			talk_bubble_body.width = chat_tf.width+(padd*2);
			talk_bubble_body.height = tbh;
			
			// reset this shit (it can be flipped when keeping it in bounds)
			_talk_bubble_pointer.scaleX = 1;
			
			_talk_bubble_pointer_placed_x = _talk_bubble_pointer.x = 0;
			
			_talk_bubble_pointer.y = talk_bubble_body.y+talk_bubble_body.height-9; // 9 compensates for the extra height of the point
			bubble_container.addChildAt(_talk_bubble_pointer, 0);
			
			positionContainer(pt);
			
			TSTweener.removeTweens(this);
			if (alpha != 1) TSTweener.addTween(this, {alpha:1, time:fade_ms/1000, transition:'linear'});
			
			placed_y = y;
			placed_x = x;
			keepInBounds();
			showing_sig.dispatch();
			
			//if (parent) DisplayDebug.LogCoords(parent, 30);
		}
		
		public function positionContainer(pt:Point=null):void {
			if (pt) {
				if (extra_sp) {
					all_container.y = pt.y - extra_sp.height-chat_tf.height-25;
				} else {
					all_container.y = pt.y - chat_tf.height-20;
				}
			} else {
				// this makes it so that it is x centered and y 0 is at its bottom
				all_container.y = -all_container.height;
			}
		}
		
		public function get bubble_pointer():DisplayObject { return _talk_bubble_pointer; }
		
		public function get keep_in_viewport():Boolean { return _keep_in_viewport; }	
		public function set keep_in_viewport(value:Boolean):void {
			_keep_in_viewport_within_reason = false;
			_keep_in_viewport = value;
			keepInBounds();
		}
		
		public function get keep_in_viewport_within_reason():Boolean { return _keep_in_viewport_within_reason; }	
		public function set keep_in_viewport_within_reason(value:Boolean):void {
			_keep_in_viewport = value
			_keep_in_viewport_within_reason = value;
			keepInBounds();
		}
		
		public function get allow_out_of_viewport_top():Boolean { return _allow_out_of_viewport_top; }	
		public function set allow_out_of_viewport_top(value:Boolean):void {
			_allow_out_of_viewport_top = value;
			keepInBounds();
		}
		
		public function set offset_x(value:int):void { _offset_x = value; }
		
		public function get max_w():uint { return _max_w == -1 ? MAX_WIDTH : _max_w; }
		public function set max_w(value:uint):void { _max_w = value; }
		
		override public function set name(value:String):void {
			super.name = value;
			if(chat_tf) chat_tf.name = value;
		}

		public function get rawMessage():String { 
			return _rawMessage;
		}

		public function set rawMessage(value:String):void { 
			_rawMessage = value;
		}
	}
}