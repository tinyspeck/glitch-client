package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.control.engine.AnnouncementController;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.data.item.Verb;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.net.NetOutgoingItemstackVerbMenuVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.ChatBubble;
	import com.tinyspeck.engine.view.AbstractAvatarView;
	import com.tinyspeck.engine.view.AvatarView;
	import com.tinyspeck.engine.view.IAnnouncementArtView;
	import com.tinyspeck.engine.view.IWorthRenderable;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.ui.Slug;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import org.osflash.signals.Signal;
	
	public class InLocationAnnouncementOverlay extends AbstractAnnouncementOverlay {
		
		// Jote 7/31/2012: Testing removal of art_view_loaded_sig.  Should only use allReady_sig from now on
		//public const art_view_loaded_sig:Signal = new Signal(IAnnouncementArtView);
		
		public const allReady_sig:Signal = new Signal(InLocationAnnouncementOverlay);
		
		private var bubble_thought_do_ready:Boolean = false;
		private var check_worth_renderable:IWorthRenderable;
		
		public function InLocationAnnouncementOverlay() {
			super();
			tf_padd = 0; // to do, don't use this in this class
			init();
		}		
		
		override public function worldDisposableSpriteDestroyedHandler(sp:DisposableSprite):void {
			// the disp sp your were registered with has been destroyed
			cancel();
			check_worth_renderable = null;
		}
		
		override public function worldDisposableSpriteSubscribedHandler(sp:DisposableSprite):void {
			if (sp is IWorthRenderable) {
				check_worth_renderable = sp as IWorthRenderable;
			}
		}
		
		override public function worldDisposableSpriteChangeHandler(sp:DisposableSprite):void {
			if (sp is LocationItemstackView) {
				placeByLocationItemstackView(sp as LocationItemstackView);
			} else if (sp is AbstractAvatarView) {
				placeByPcView(sp as AbstractAvatarView);
			}
		}
		
		override public function placeByLocationItemstackView(lis_view:LocationItemstackView):void {
			
			visible = lis_view.worth_rendering;
			
			if (!visible) return;
			
			var base_x:int;
			var base_y:int;
			
			if (annc.in_itemstack) {
				base_x = 0; // we need to implement lis_view.x_of_int_target to get the x
				base_y = 0;
			} else {
				base_x = lis_view.x_of_int_target;
				base_y = lis_view.y;
			}
			
			if (annc.plot_id == -1) {
				
				var delta_x:int = annc.delta_x;
				
				if (annc.delta_x_relative_to_face && lis_view.is_flipped) {
					delta_x*= -1;
				}
				
				x = base_x+delta_x;
				y = base_y+annc.delta_y;
				if (!annc.place_at_bottom) {
					y+= lis_view.getYAboveDisplay();
				}
			} else if(lis_view.garden_view) {
				//put the overlay over the plot
				
				var pt:Point = lis_view.garden_view.getPointForOverlay(annc);
				x = pt.x;
				y = pt.y;
			}
			
			keepInBounds();
		}
		
		override public function placeByPcView(pc_view:AbstractAvatarView):void {
			visible = pc_view.worth_rendering;
			
			if (!visible) return;
			
			var delta_x:int = annc.delta_x;
			
			if (annc.delta_x_relative_to_face) {
				delta_x*= pc_view.orientation;
			}
			
			x = pc_view.x+delta_x;
			y = pc_view.y+annc.delta_y;
			
			keepInBounds();
		}
		
		private function keepInBounds():void {
			if (annc.dont_keep_in_bounds) return;
			if (annc.in_itemstack) return;
			// lets not do this if we're following an IWorthRenderable and it is !worth_rendering
			if (check_worth_renderable && !check_worth_renderable.worth_rendering) {
				return;
			}
			
			const rect:Rectangle = this.getRect(StageBeacon.stage);
			rect.y-= (5+model.layoutModel.header_h); // keep it 5 or more pixels from top of stage
			if (rect.y < 0) {
				if (annc.type == Announcement.ITEMSTACK_OVERLAY || annc.type == Announcement.PC_OVERLAY) {
					y-= Math.max(-120, rect.y); // the Math.max(-120 makes it so that they do not appear UNDER pcs and stacks that are way above you, out of view
				} else {
					y-= rect.y;
				}
			}
			
			if (annc.uid == 'phantom_glitch') {
				Benchmark.addCheck('phantom_glitch at x:'+x+' y:'+y);
			}
		}
		
		override protected function init():void {
			bubble_thought_do = new AssetManager.instance.assets.overlay_bubble();
			bubble_thought_do.addEventListener(Event.COMPLETE, afterBubbleLoad);
			
			chat_bubble = new ChatBubble(0);
			
			super.init();
		}
		
		override public function changeScale(newScale:Number, in_time:Number):void {
			/* Currently, we do not scale text */
			if(annc.text) {
				super.changeScale(newScale, in_time);
			} else {			
				var art_view_do:DisplayObject = this._art_view as DisplayObject;
				var scale_change:Number = newScale/art_view_do.scaleY;
				var base_height:Number = 0;
				var new_y_pos:Number = 0;
				
				if(annc.progress_flip) {
					base_height = dismisser.y - dismisser.height - 5;
					new_y_pos = base_height*scale_change+dismisser.height+5;
				} else {
					base_height = dismisser.y + dismisser.height + 5;
					new_y_pos = base_height*scale_change-dismisser.height-5;
				}
				
				TSTweener.addTween(dismisser, {y: new_y_pos, time:in_time, transition:'easeOutBack'});
				super.changeScale(newScale, in_time);
			}
		}
		
		override protected function showDismisser():void {
			if (annc.dismissible) {
				
				//let's see if we need to listen to metabolic changes
				if(annc.counter_limit > 1){
					slug_animator.start(onMetabolicChange);
				}
			}
		}
		
		override protected function showWordProgress():void {
			art_and_disimisser_container.addChild(word_progress_bar);
			word_progress_bar.show(annc, fade_in_sec*1000);
			word_progress_bar.x = -word_progress_bar.width/2;
		}
		
		override protected function onMetabolicChange(slug:Slug):void {
			super.onMetabolicChange(slug);
			
			//place the slug and animate it
			var avatar:AvatarView = TSFrontController.instance.getMainView().gameRenderer.getAvatarView();
			slug.x = int(-avatar.w/2);
			slug.y = int(-avatar.h - slug.height);
			avatar.addSlug(slug);
			
			slug.y += 30;
			TSTweener.addTween(slug, {y:slug.y - 30, time:.4, onComplete:slug.animate, onCompleteParams:[slug_animator]});
			TSTweener.addTween(slug, {y:slug.y - 60, alpha:0, time:.4, delay:2, 
				onComplete:function():void {
					avatar.removeSlug(slug);
				}
			});
		}
		
		override protected function showBubble():void {
			if (annc.bubble_talk) {
				
				addChildAt(DisplayObject(chat_bubble), 0);
				
				//if the chat bubble has rewards, let's show them
				var extra_sp:Sprite;
				if(annc.rewards){
					var i:int;
					var slug:Slug;
					var next_x:int;
					var next_y:int;
					var padd:int = 4;
					extra_sp = new Sprite();
					
					for(i; i < annc.rewards.length; i++){
						if (annc.rewards[int(i)].type != Reward.ITEMS && annc.rewards[int(i)].amount != 0) {
							slug = new Slug(annc.rewards[int(i)]);
							slug.x = next_x;
							slug.y = next_y;
							next_x = slug.x+slug.width+padd;
							extra_sp.addChild(slug);
							
							if (next_x+slug.width > annc.width) {
								next_x = 0;
								next_y = extra_sp.height+padd;
							}
						}
					}
				}
				
				chat_bubble.show(annc.text[text_index], null, extra_sp, annc.width || 0);
				
				// remove the tf_container, we're not using it
				if (tf_container.parent) tf_container.parent.removeChild(tf_container);
				
			} else if (annc.bubble || annc.bubble_placard || annc.bubble_price_tag) {
				
				var h_to_size_to:int = (annc.text) ? tf_container.height : Math.max(_art_view.art_h, _art_view.art_w)+10;
				var w_to_size_to:int = (annc.text) ? tf_container.width : Math.max(_art_view.art_h, _art_view.art_w)+10;
				
				var bubble_h:int;
				var bubble_w:int;
				
				var bubble_padd:int;
				var bubble_space:int;
				
				if (annc.bubble_placard || annc.bubble_price_tag) {
					if (!bubble_placard_do) {
						bubble_placard_do = new Sprite();
						bubble_placard_do.filters = StaticFilters.anncText_DropShadowA;
					}
					
					bubble_padd = 5;
					bubble_w = w_to_size_to+(bubble_padd*2);
					bubble_h = h_to_size_to;
					
					var g:Graphics = bubble_placard_do.graphics;
					g.clear();
					if (annc.bubble_placard) {
						var offset:int = 2;
						g.beginFill(0xffffff, 1);
						g.moveTo(offset, 0);
						g.lineTo(bubble_w-offset, 0);
						g.lineTo(bubble_w, bubble_h);
						g.lineTo(0, bubble_h);
						g.lineTo(offset, 0);
						g.endFill();
					} else if (annc.bubble_price_tag) {
						var point_w:int = 6;
						g.beginFill(0xffffff, 1);
						g.moveTo(point_w, 0);
						g.lineTo(bubble_w, 0);
						g.lineTo(bubble_w, bubble_h);
						g.lineTo(point_w, bubble_h);
						g.lineTo(0, bubble_h*.75);
						g.lineTo(0, bubble_h*.25);
						g.lineTo(point_w, 0);
						g.endFill();
						
						g.beginFill(0x666666, 1);
						g.drawCircle(4, bubble_h/2, 1);
						g.endFill();
						
						
					}
					
					bubble_placard_do.x = -bubble_w/2;
					bubble_placard_do.y = -(bubble_h);
					
					addChildAt(bubble_placard_do, 0);
					bubble_placard_do.x = -bubble_w/2;
					bubble_placard_do.y = -(bubble_h);
					
				} else {
					//Console.info(h_to_size_to+' '+w_to_size_to)
					
					// these values are used to calc how much we should scale the bubble. they correspond to roughly how much space is avaialable
					// to place something in the center of the unscaled bubble swf
					bubble_padd = 15;
					bubble_space = 50;
					
					bubble_h = (h_to_size_to+((h_to_size_to/bubble_space)*(bubble_padd*2)))*1.3; // the 1.3 accounts for the tail at bottom of bubble
					bubble_w = w_to_size_to+((w_to_size_to/bubble_space)*(bubble_padd*2));
					
					bubble_thought_do.width = bubble_w;
					bubble_thought_do.height = bubble_h;
					
					addChildAt(bubble_thought_do, 0);
					bubble_thought_do.x = -bubble_w/2;
					bubble_thought_do.y = -(bubble_h);
					
					// you may be tempted here to use art_view.wh instead of art_h, but don't;
					// if there is any overlay not getting placed in the bubble properly, make sure
					// it is sized to stage and or that all visible content measured in .height
					// is at 0,0 on the swf stage.
					var h_to_place_with:int = (annc.text) ? tf_container.height : _art_view.art_h;
					
					// move the icon and dismisser so it is centered in the bubble area of the bubble
					art_and_disimisser_container.y = Math.round(
						(-bubble_h)+(h_to_place_with)+(((bubble_h*.7)-h_to_place_with)/2) // the .7 accounts for the tail at the bottom of the bubble
					);
				}
				
				tf_container.y = art_and_disimisser_container.y-tf_container.height;
				
			}
		}
		
		override protected function showText(index:int = 0):void {
			super.showText(index);
			addChild(tf_container);
			tf.htmlText = annc.text[text_index];
			
			//if this is the simple panel class, then we don't embed fonts
			tf.embedFonts = tf.htmlText.indexOf('class="simple_panel"') == -1;
			
			//tf.border = true
			tf.width = (annc.width) ? annc.width : 200;
			if (!annc.width) tf.width = Math.min(tf.width, tf.textWidth+6);
			
			tf.height = (annc.height) ? annc.height : 200;
			tf.height = Math.min(tf.height, tf.textHeight+4);
			
			var textFilterA:Array = StaticFilters.anncText_DropShadowA;
			if (annc.text_filter_name && annc.text_filter_name in StaticFilters) {
				textFilterA = StaticFilters[annc.text_filter_name];
			} else if (annc.text_filterA) {
				textFilterA = annc.text_filterA;
			}
			
			// here's hoping this does not fuck anythign up 20110624
			tf.filters = annc.show_text_shadow ? textFilterA : null;
			
			var g:Graphics = tf_container.graphics;
			g.clear();
			g.beginFill(0xe3e3e3, 0);
			g.drawRect(0, 0, (annc.width) ? annc.width : tf.width, (annc.height) ? annc.height : tf.height);
			g.endFill();
			
			tf.x = Math.round((tf_container.width-tf.width)/2);
			tf.y = Math.round((tf_container.height-tf.height)/2)
			
			tf_container.x = -Math.round(tf_container.width/2);
			
			if (annc.center_text) {
				tf_container.y = Math.round(-tf_container.height/2);
			} else {
				tf_container.y = -tf_container.height;
			}
			
			if (annc.tf_delta_x) tf_container.x+=annc.tf_delta_x;
			if (annc.tf_delta_y) tf_container.y+=annc.tf_delta_y;
			
			if (annc.bubble || annc.bubble_talk || annc.bubble_placard || annc.bubble_price_tag) showBubble();
			
			if (annc.click_to_advance) {
				
			}
			
		}
		
		override public function go(annc:Announcement):void {
			if (running) {
				AnnouncementController.instance.overlayIsDone(this.annc, this);
				return;
			}
			
			scaleX = 1;
			
			super.go(annc);
			
			
			alpha = 0;
			
			// make sure these get reset! because these ILAOs are reused!!!
			visible = true;
			scaleX = 1;
			scaleY = 1;
			art_and_disimisser_container.y = 0;
			art_container.scaleX = 1;
			art_container.scaleY = 1;
			
			var art_view_wh:int = Math.max(annc.height, annc.width);
			var art_view_do:DisplayObject;
			
			cleanArtView();
			
			if (annc.item_class) {
				if (!model.worldModel.getItemByTsid(annc.item_class)) {
					CONFIG::debugging {
						Console.error('annc with unrecognized item_class: '+annc.item_class);
					}
					AnnouncementController.instance.overlayIsDone(annc, this);
					return;
				}
				var use_mc:Boolean = (art_view_wh>200);
				var registration:String = (annc.center_view) ? 'center' : 'center_bottom';
				_art_view = new ItemIconView(annc.item_class, art_view_wh, {state:annc.state, config:annc.config}, registration, use_mc, true, annc.scale_to_stage) as IAnnouncementArtView;
			} else if (annc.word_progress) {
				_art_view = word_progress_bar;
			}  else if (annc.swf_url) {
				if (annc.is_flv) {
					_art_view = new ArbitraryFLVView(annc.swf_url, art_view_wh, annc.state, 'center_bottom', annc.loop_count) as IAnnouncementArtView;
					ArbitraryFLVView(_art_view).rotation = annc.rotation;
				} else {
					_art_view = new ArbitrarySWFView(annc.swf_url, art_view_wh, annc.state, 'center_bottom', true, annc.local_uid) as IAnnouncementArtView;
				}
			}
			
			if (!_art_view && !annc.text) {
				CONFIG::debugging {
					Console.error('annc with no item_class and no swf_url and no text');
				}
				AnnouncementController.instance.overlayIsDone(annc, this);
				return;
			}
			
			running = true;
			
			if (annc.in_itemstack) {
				this.scaleX = (annc.h_flipped) ? -1 : 1;
			}
			
			if (_art_view) {
				art_view_do = _art_view as DisplayObject;
				if (annc.h_flipped && !annc.in_itemstack) art_view_do.scaleX = -1;
				art_container.addChild(art_view_do);
				
				// Jote 7/31/2012: testing removal
				//art_view_loaded_sig.dispatch(_art_view);
			}
			
			if (!_art_view || _art_view.loaded) {
				if (bubble_thought_do_ready) {
					allReady();
				}
				// Jote 7/31/2012: testing removal
				//if (_art_view) art_view_loaded_sig.dispatch(_art_view);
			} else {
				EventDispatcher(_art_view).addEventListener(TSEvent.COMPLETE, afterArtViewLoad);
			}
		}
		
		override protected function afterArtViewLoad(e:TSEvent):void {
			if (bubble_thought_do_ready) {
				allReady();
			}
			
			// Jote 7/31/2012: testing removal
			//art_view_loaded_sig.dispatch(_art_view);
		}
		
		private function afterBubbleLoad(e:Event):void {
			bubble_thought_do_ready = true;
			if (!_art_view || _art_view.loaded) {
				allReady();
			}
		}
		
		override protected function allReady():void {
			if (finishing || !running) return;
			super.allReady();
			report('allReady');
			if (_art_view) EventDispatcher(_art_view).removeEventListener(TSEvent.COMPLETE, afterArtViewLoad);
			
			if (_art_view && _art_view is ArbitrarySWFView && !ArbitrarySWFView(_art_view).mc) {
				// This means the arb swf failed to load! just bail
				CONFIG::debugging {
					Console.error('ArbitrarySWFView COMPLETE, but no mc');
				}
				report('ArbitrarySWFView COMPLETE, but no mc')
				AnnouncementController.instance.overlayIsDone(annc, this);
				return;
			}
			
			
			if (!running) return;
			
			if (annc.text) showText();
			if (!hasMultipleTexts()) {
				if(annc.word_progress){
					showWordProgress();
				}
				else if(annc.dismissible){
					showDismisser(); // disimissible only works when there are no multiple texts
				}
			}
			if (!annc.text && (annc.bubble || annc.bubble_talk || annc.bubble_placard || annc.bubble_price_tag)) showBubble(); // we'll take care of this in showText
			
			alpha = 0;
			
			///////////////////////////////////////////////////////
			
			annc.client_all_ready = getTimer();
			// now fade in
			fadeIn(annc.delay_ms/1000);
			keepInBounds();
			
			allReady_sig.dispatch(this);
		}
		
		override protected function onArtClick(event:Event):void {
			if(annc.overlay_mouse && annc.overlay_mouse.click_verb) {
				if(annc.itemstack_tsid) {
					artClickFeedback();
					
					waiting_on_click_payload_rsp = true;
					TSFrontController.instance.genericSend(
						new NetOutgoingItemstackVerbMenuVO(annc.itemstack_tsid),
						onArtClickResponse,
						onArtClickResponse
					);
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.error('Clickable overlay tried to invoke verb on null object');
					}		
				}
			} else {
				super.onArtClick(event);
			}
		}
		
		override protected function onArtClickResponse(nrm:NetResponseMessageVO):void {
			if(annc.overlay_mouse && annc.overlay_mouse.click_verb) {
				if (nrm.success) {
					var itemstack:Itemstack = model.worldModel.getItemstackByTsid(annc.itemstack_tsid);
					if(itemstack && itemstack.item) {
						var verb:Verb = itemstack.item.verbs[annc.overlay_mouse.click_verb];
						if(verb && verb.enabled) {
							TSFrontController.instance.startItemstackMenuWithVerb(itemstack, verb, false);
						}
					}
				}
			} else {
				super.onArtClickResponse(nrm);
			}
		}
	}
}