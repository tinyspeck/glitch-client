package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.control.engine.AnnouncementController;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.view.IAnnouncementArtView;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.EventDispatcher;
	import flash.text.TextLineMetrics;
	import flash.utils.getTimer;

	
	public class InWindowAnnouncementOverlay extends AbstractAnnouncementOverlay implements IRefreshListener {
		
		private var center_in_w:int;
		private var center_in_h:int;
		private var x_centered:Boolean;
		private var y_centered:Boolean;
		private var advance_button_plain:Button;
		private var advance_button_enter:Button;
		private var advance_button_bottom:Button;
		
		public function InWindowAnnouncementOverlay() {
			super();
			init();
		}
		
		override protected function init():void {
			
			advance_button_plain = new Button({
				// use the first of the outputs for the icon
				graphic: new AssetManager.instance.assets.advancer_white(),
				label: '',
				name: 'advance',
				value: 'advance',
				w: advance_button_wh,
				h: advance_button_wh,
				c: 0xffffff,
				shad_c: 0xffffff,
				high_c: 0xffffff,
				draw_alpha: 0 // don't use no_draw because then measuring is wrong, before the graphic loads
			});
			
			advance_button_enter = new Button({
				// use the first of the outputs for the icon
				graphic: new AssetManager.instance.assets.advancer_white_enter(),
				label: '',
				name: 'advance_enter',
				value: 'advance_enter',
				w: advance_button_wh,
				h: advance_button_wh,
				c: 0xffffff,
				shad_c: 0xffffff,
				high_c: 0xffffff,
				draw_alpha: 0 // don't use no_draw because then measuring is wrong, before the graphic loads
			});
			
			//builds the "click anywhere" button
			advance_button_bottom = new Button({
				// use the first of the outputs for the icon
				name: 'advance_bottom',
				value: 'advance_bottom',
				label: 'Click anywhere...',
				graphic: new AssetManager.instance.assets.advancer_triangle(),
				graphic_placement: 'left',
				graphic_padd_t: 3,
				graphic_padd_l: 10,
				graphic_padd_r: 8,
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_GREY_DROP,
				h: 30
			});
			advance_button_bottom.mouseChildren = advance_button_bottom.mouseEnabled = false;
			
			super.init();
		}
		
		override public function go(annc:Announcement):void {
			if (running) {
				AnnouncementController.instance.overlayIsDone(this.annc, this);
				TSFrontController.instance.unRegisterRefreshListener(this);
				return;
			}
			
			super.go(annc);
			
			TSFrontController.instance.registerRefreshListener(this);
			
//			this.changeScale(3.0, 5.0);
			
			var self:InWindowAnnouncementOverlay = this;
			self.alpha = 0;
			self.scaleX = 1;
			self.scaleY = 1;
			art_and_disimisser_container.y = 0;
			art_container.scaleX = 1;
			art_container.scaleY = 1;
			var art_view_wh:int;
			var art_view_do:DisplayObject;
			
			cleanArtView();
			
			// if no size is sent, it will be treated as 100%.
			var perc:Number = 1;
			if (annc.size) {
				if (annc.size.indexOf('%') > -1) {
					perc = parseInt(annc.size)/100;
				} else {
					art_view_wh = parseInt(annc.size);
				}
			} else if (annc.height || annc.width) {
				 art_view_wh = Math.max(annc.height, annc.width);
			}
			
			x_centered = (annc.x == null); // unless we get both x and y, we're centering
			y_centered = (annc.y == null && annc.top_y == null);
			
			var art_view_registration:String = (x_centered) ? 'center' : 'center';
			
			if (annc.item_class) {
				if (!model.worldModel.getItemByTsid(annc.item_class)) {
					CONFIG::debugging {
						Console.error('annc with unrecognized item_class: '+annc.item_class);
					}
					AnnouncementController.instance.overlayIsDone(annc, this);
					return;
				}
			}
			
			var use_mc:Boolean;
			
			var use_state:Object = annc.state;
			if (!annc.is_flv && (annc.state || annc.config)) {
				use_state = {state:annc.state, config:annc.config};
			}
			
			if (annc.type == Announcement.WINDOW_OVERLAY) {
				self.x = 0;
				self.y = 0;
				if (!art_view_wh && !annc.scale_to_stage) art_view_wh = Math.min(StageBeacon.stage.stageHeight, StageBeacon.stage.stageWidth)*perc;
				use_mc = (art_view_wh>200);
				
				if (annc.item_class) {
					_art_view = new ItemIconView(annc.item_class, art_view_wh, use_state, art_view_registration, use_mc, true, true) as IAnnouncementArtView;
				} else if (annc.swf_url) {
					if (annc.is_flv) {
						_art_view = new ArbitraryFLVView(annc.swf_url, art_view_wh, use_state, art_view_registration, annc.loop_count) as IAnnouncementArtView;
						ArbitraryFLVView(_art_view).rotation = annc.rotation;
					} else {
						_art_view = new ArbitrarySWFView(annc.swf_url, art_view_wh, use_state, art_view_registration, true, annc.local_uid) as IAnnouncementArtView;
					}
				}
				
				if (!_art_view && !annc.text) {
					CONFIG::debugging {
						Console.error('annc with no item_class and no swf_url and no flv_url and no text');
					}
					AnnouncementController.instance.overlayIsDone(annc, this);
					return;
				}
				
			} else if (annc.type == Announcement.VP_OVERLAY) {
				self.x = model.layoutModel.gutter_w;
				self.y = model.layoutModel.header_h;
				if (!art_view_wh && !annc.scale_to_stage) art_view_wh = Math.min(model.layoutModel.loc_vp_h, model.layoutModel.loc_vp_w)*perc;
				use_mc = (art_view_wh>200);

				if (annc.item_class) {
					_art_view = new ItemIconView(annc.item_class, art_view_wh, use_state, art_view_registration, use_mc, true, true) as IAnnouncementArtView;
				} else if (annc.swf_url) {
					if (annc.is_flv) {
						_art_view = new ArbitraryFLVView(annc.swf_url, art_view_wh, use_state, art_view_registration, annc.loop_count) as IAnnouncementArtView;
						ArbitraryFLVView(_art_view).rotation = annc.rotation;
					} else {
						_art_view = new ArbitrarySWFView(annc.swf_url, art_view_wh, use_state, art_view_registration, true, annc.local_uid) as IAnnouncementArtView;
					}
				}
				
				if (!_art_view && !annc.text) {
					CONFIG::debugging {
						Console.error('annc with no item_class and no swf_url and no flv_url and no text');
					}
					AnnouncementController.instance.overlayIsDone(annc, this);
					return;
				}
			}
			
			running = true;
			
			if (_art_view) {
				art_view_do = _art_view as DisplayObject;
				if (annc.h_flipped) art_view_do.scaleX = -1;
				art_container.addChild(art_view_do);
			}

			if (!_art_view || _art_view.loaded) {
				allReady();
			} else {
				EventDispatcher(_art_view).addEventListener(TSEvent.COMPLETE, afterArtViewLoad);
			}
			
		}
		
		override protected function done():void {
			super.done();
			
			//unregister this as a refresh listener
			TSFrontController.instance.unRegisterRefreshListener(this);
		}
		
		override protected function afterArtViewLoad(e:TSEvent):void {
			allReady()
		}
		
		override protected function allReady():void {
			if (finishing || !running) return;
			super.allReady();
			if (_art_view) {
				EventDispatcher(_art_view).removeEventListener(TSEvent.COMPLETE, afterArtViewLoad);
				var art_view_do:DisplayObject = _art_view as DisplayObject;
				art_view_do.y = 0;
			}
			
			if (_art_view && _art_view is ArbitrarySWFView && !ArbitrarySWFView(_art_view).mc) {
				// This means the arb swf failed to load! just bail
				CONFIG::debugging {
					Console.error('ArbitrarySWFView COMPLETE, but no mc');
				}
				AnnouncementController.instance.overlayIsDone(annc, this);
				return;
			}
			
			if (!running) return;
			
			refresh();
			
			if (annc.text) {
				if (_art_view && _art_view is ArbitrarySWFView && ArbitrarySWFView(_art_view).handles_text) {
					//ArbitrarySWFView(art_view).mc.tf.parent.removeChild(ArbitrarySWFView(art_view).mc.tf)
					//ArbitrarySWFView(art_view).mc.tf = tf;
				}
				showText();
			}
			annc.client_all_ready = getTimer();
			fadeIn(annc.delay_ms/1000);
		}
		
		private function placeNormally():void {			
			var art_view_do:DisplayObject = _art_view as DisplayObject;
			//if (!art_view) return; //commented this out because it was making text based overlays not work
			
			if (x_centered) { // center it in the available space
				// note that in this case, art_view_registration = 'center'
				art_and_disimisser_container.x = Math.round(center_in_w/2);
			} else { // a position has been specified, use it
				// note that in this case, art_view_registration = 'center' 
				if (annc.x.indexOf('%') > -1) {
					art_and_disimisser_container.x = (parseInt(annc.x)/100)*center_in_w;
				} else {
					if (annc.position_from_center_of_vp) {
						art_and_disimisser_container.x = int((model.layoutModel.loc_vp_w/2) + int(annc.x));
					} else {
						art_and_disimisser_container.x = int(annc.x);
					}
				}
			}
			
			if (y_centered) { // center it in the available space
				// note that in this case, art_view_registration = 'center'
				art_and_disimisser_container.y = Math.round(center_in_h/2);
				
			} else { // a position has been specified, use it
				// note that in this case, art_view_registration = 'center' 
				if (annc.y == null) { //use annc.top_y
					if (annc.top_y.indexOf('%') > -1) {
						art_and_disimisser_container.y = (parseInt(annc.top_y)/100)*center_in_h;
					} else {
						art_and_disimisser_container.y = int(annc.top_y);
					}
					// compensate for the center registration of the art_view
					if (art_view_do) {
						art_view_do.y = (_art_view.art_h/2);
					}
				} else { // use annc.y
					if (annc.y.indexOf('%') > -1) {
						art_and_disimisser_container.y = (parseInt(annc.y)/100)*center_in_h;
					} else {
						if (annc.position_from_center_of_vp) {
							art_and_disimisser_container.y = int((model.layoutModel.loc_vp_h/2) + int(annc.y));
						} else {
							art_and_disimisser_container.y = int(annc.y);
						}
					}
				}
			}
		}
		
		private function placeOverPack():void {
			if(!_art_view){
				CONFIG::debugging {
					Console.warn('No art_view when trying to placeOverPack');
				}
				return;
			}
			var w:int = _art_view.art_w;
			var h:int = _art_view.art_h;
			
			art_and_disimisser_container.x = model.layoutModel.loc_vp_w/2;//0+Math.round(w/2);
			art_and_disimisser_container.y = model.layoutModel.loc_vp_h+Math.round(136/2);
		}
		
		private function placeInCorner():void {
			if(!_art_view){
				CONFIG::debugging {
					Console.warn('No art_view when trying to placeInCorner');
				}
				return;
			}
			var w:int = _art_view.art_w;
			var h:int = _art_view.art_h;
			
			if (annc.corner == 'tl' || annc.corner == 'tr') {
				art_and_disimisser_container.y = Math.round(h/2)+annc.corner_offset_y;
			} else {
				art_and_disimisser_container.y = center_in_h+-Math.round(h/2)+-annc.corner_offset_y;
			}
			
			if (annc.corner == 'tl' || annc.corner == 'bl') {
				art_and_disimisser_container.x = Math.round(w/2)+annc.corner_offset_x;
			} else {
				art_and_disimisser_container.x = center_in_w+-Math.round(w/2)+-annc.corner_offset_x;
			}
		}
		
		public function refresh():void {			
			//make sure our center is known when resizing the browser
			if (annc.type == Announcement.WINDOW_OVERLAY) {
				center_in_w = StageBeacon.stage.stageWidth;
				center_in_h = StageBeacon.stage.stageHeight;
			} else if (annc.type == Announcement.VP_OVERLAY) {
				x = model.layoutModel.gutter_w;
				y = model.layoutModel.header_h;
				
				center_in_w = model.layoutModel.loc_vp_w;
				center_in_h = model.layoutModel.loc_vp_h;
			}
			
			//place it where it needs to go
			if (annc.type == Announcement.VP_OVERLAY && annc.corner && Announcement.allowed_corners.indexOf(annc.corner) != -1) {
				placeInCorner();
			} else if (annc.type == Announcement.VP_OVERLAY && annc.over_pack) {
				placeOverPack();
			} else {
				placeNormally();
			}
			
			//redraw the background if we need to
			const g:Graphics = graphics;
			g.clear();
			if(annc.background_color){
				g.beginFill(ColorUtil.colorStrToNum(annc.background_color), annc.background_alpha);
				g.drawRect(0, 0, center_in_w, center_in_h);
			}
		}
		
		override protected function showText(index:int = 0):void {
			super.showText(index);
			var advance_button_on_right:Boolean = !annc.click_to_advance_bottom;
			
			if (_art_view && _art_view is ArbitrarySWFView && ArbitrarySWFView(_art_view).handles_text) {
				ArbitrarySWFView(_art_view).showText(annc.text[text_index]);
			} else {
				
				tf_container.graphics.clear();
				
				// for measuring
				if (advance_button && advance_button.parent) advance_button.parent.removeChild(advance_button);
				
				var max_tf_w:int = annc.width || 300;
				if (annc.click_to_advance && advance_button_on_right) max_tf_w-= advance_button_margin_left+advance_button_wh;
			
				art_and_disimisser_container.addChild(tf_container);
				
				
				var textFilterA:Array = StaticFilters.anncText_DropShadowA;
				if (annc.text_filter_name && annc.text_filter_name in StaticFilters) {
					textFilterA = StaticFilters[annc.text_filter_name];
				} else if (annc.text_filterA) {
					textFilterA = annc.text_filterA;
				}
				
				tf.filters = annc.show_text_shadow ? textFilterA : null;
				var html:String = annc.text[text_index];
				if (annc.click_to_advance) {
					//var A:Array = html.split('<');
					//A[A.length-2]+= '------';
					//html = A.join('<');
					//Console.info(html)
					////////html+= '<font color="#ffffff">------</font>';
				}
				
				tf.htmlText = html;
				tf.width = max_tf_w;
				//tf.width = Math.min(tf.width, tf.textWidth+6);
				tf.height = tf.textHeight+4;
				if (annc.height) tf.height = Math.max(tf.height, annc.height);
				tf.y = 0;
				
				// good god flash is stupid, but if there is a <p> in the text, numlines is +1
				var extra_line:int = (html.indexOf('<p') > -1) ? 1 : 0;
				
				// THIS IS A FUCKING HACK AND A HALF TO COMPENSATE FOR FLASH MISCALCING TEXTHEIGHT WHEN THE CSS HAS NEG (or positive?) LEADING
				// AND IT ONLY HAS ONE LINE OF TEXT.
				// PLUS A BONUS WTF IS THAT numlines reports 2 when there is only one!, if there is a wrapping <p>
				if (tf.numLines <= 1+extra_line && tf.getLineMetrics(0).leading < 0) tf.height-=tf.getLineMetrics(0).leading;
				
				
				// fit the art to the tf FUCK THIS SHIT
				//art_container.scaleX = art_container.scaleY = 1; // for measuring
				//art_container.scaleX = (tf_container.width+(tf_padd*2))/art_container.width;
				//art_container.scaleY = (tf_container.height+(tf_padd*2))/art_container.height;
				
				if (annc.click_to_advance) {					
					
					if (annc.click_to_advance_show_text) {
						advance_button = advance_button_enter;
					} else if (annc.click_to_advance_bottom) {
						advance_button = advance_button_bottom;
						advance_button_bottom.label = annc.click_to_advance_bottom_text || 'Click anywhere...';
					} else {
						advance_button = advance_button_plain;
					}
					
					advance_button.y = 0;
					
					model.stateModel.overlay_button_with_tip_count++;
					
					tf_container.addChild(advance_button);
					if (annc.click_to_advance_bottom) {
						//center the button to the bottom of the text
						advance_button.x = int(tf.width/2 - advance_button.width/2);
						advance_button.y = int(tf.height + 2 + annc.click_to_advance_bottom_y_offset);
						
					} else if (advance_button_on_right) {
						advance_button.x = tf.width+advance_button_margin_left;
						advance_button.y = Math.max((tf.height-advance_button.h)/2, 0);
						if (tf.height < advance_button_wh) {
							tf.y = Math.round((advance_button_wh-tf.height)/2);
						}
						
					} else {
						
						var shrinking_sauce:Number = .66; // to try and get the advance_button the height of the text from baseline to ascent top
						
						var metrics:TextLineMetrics = tf.getLineMetrics(tf.numLines-(1+extra_line));
						//DisplayDebug.logLineMetrics(metrics);
						advance_button.scaleX = advance_button.scaleY = ((metrics.height-metrics.leading)*shrinking_sauce)/advance_button_wh;
						
						advance_button.x = metrics.x+metrics.width+5;
						advance_button.y = 1 + ((metrics.height-(metrics.height*shrinking_sauce))/2);
						tf_container.graphics.lineStyle(0, 0, 0, true);
						for (var i:int=0;i<tf.numLines-(1+extra_line);i++) {
							//DisplayDebug.logLineMetrics(tf.getLineMetrics(i));
							advance_button.y+=tf.getLineMetrics(i).height
							
							//tf_container.graphics.beginFill(0xffffff, 1);
							//tf_container.graphics.drawRect(0, advance_button.y, 30, tf.getLineMetrics(i).ascent);
							//tf_container.graphics.drawRect(30, advance_button.y+tf.getLineMetrics(i).ascent, 30, tf.getLineMetrics(i).descent);
						}
						tf_container.addChild(advance_button);
					}
				}
				
				tf_container.x = Math.round(art_container.x-(tf_container.width/2));
				
				if (annc.top_y == null) {
					tf_container.y = Math.round(art_container.y-(tf_container.height/2));
				} else {
					tf_container.y = art_container.y;
				}
					
				if (annc.bubble_familiar || annc.bubble_god) {
					var padd:int = 15;
					tf_container.y+= padd; // move it down
					
					tf_container.graphics.lineStyle(0, 0, 0, true);
					tf_container.graphics.beginFill(0x000000, .1);
					tf_container.graphics.beginFill(0x000000, .7);
					tf_container.graphics.drawRoundRect(-padd, -padd, tf_container.width+(padd*2), tf_container.height+(padd*2), 15);
					tf_container.graphics.endFill();
					
					if (annc.bubble_familiar) {
						var point_h:int = 12;
						var point_w:int = 18;
						tf_container.y+= point_h; // move it down some more
						
						tf_container.graphics.beginFill(0x000000, .7);
						tf_container.graphics.moveTo(-padd+(tf_container.width/2), -padd-point_h);
						tf_container.graphics.lineTo(-padd+(tf_container.width/2)+(point_w/2), -padd);
						tf_container.graphics.lineTo(-padd+(tf_container.width/2)-(point_w/2), -padd);
						tf_container.graphics.lineTo(-padd+(tf_container.width/2), -padd-point_h);
						tf_container.graphics.endFill();
					}
				}
				
				//we wants to fades this thang in
				if (annc.text_fade_delay_sec) {
					tf_container.alpha = 0;
					TSTweener.addTween(tf_container, {alpha:1, time:annc.text_fade_sec, delay:annc.text_fade_delay_sec, transition:'linear'});
				}
			}
		}
	}
}