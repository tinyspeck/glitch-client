package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.leaderboard.LeaderboardEntry;
	import com.tinyspeck.engine.data.loading.LoadingInfo;
	import com.tinyspeck.engine.data.loading.LoadingStreetDetails;
	import com.tinyspeck.engine.data.loading.LoadingUpgradeDetails;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.MoveModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.AbstractTSView;
	import com.tinyspeck.engine.view.ui.Slug;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.text.TextField;
	
	public class LoadingLocationView extends AbstractTSView {
		
		/* singleton boilerplate */
		public static const instance:LoadingLocationView = new LoadingLocationView();
		
		private const IMG_H:uint = 160;
		private const PADD_PERC:Number = .10; //how much of the vp width to use for gaps on the left and right
		private const TEXT_PADD:uint = 10; //how much the left/right text is indented
		private const BG_COLORS:Array = [0,0];
		private const BG_ALPHAS:Array = [1,1];
		private const BG_SPREAD:Array = [0,255];
		
		private const progress_bar:TimerBar = new TimerBar();
		private const bg_matrix:Matrix = new Matrix();
		private const pol_ui:LoadingLocationPOLView = new LoadingLocationPOLView();
		
		private const all_holder:Sprite = new Sprite();
		private const img_mask:Sprite = new Sprite();
		private const img_holder:Sprite = new Sprite();
		private const upgrade_badge_holder:Sprite = new Sprite();
		private const right_holder:Sprite = new Sprite();
		private const welcome_holder:Sprite = new Sprite();
		private const leaving_holder:Sprite = new Sprite();
		private const welcome_sm_holder:Sprite = new Sprite();
		private const leaving_sm_holder:Sprite = new Sprite();
		
		private const last_visit_tf:TextField = new TextField();
		private const entering_tf:TextField = new TextField();
		private const street_tf:TextField = new TextField();
		private const hub_tf:TextField = new TextField();
		private const home_tf:TextField = new TextField();
		private const upgrade_tf:TextField = new TextField();
		private const welcome_tf:TextField = new TextField();
		private const welcome_hub_tf:TextField = new TextField();
		private const leaving_tf:TextField = new TextField();
		private const leaving_hub_tf:TextField = new TextField();
		private const welcome_sm_tf:TextField = new TextField();
		private const welcome_hub_sm_tf:TextField = new TextField();
		private const leaving_sm_tf:TextField = new TextField();
		private const leaving_hub_sm_tf:TextField = new TextField();
		private const tf_drop:DropShadowFilter = new DropShadowFilter();
		
		private const img_loader:Loader = new Loader();
		private const img_context:LoaderContext = new LoaderContext(true);
		private const img_req:URLRequest = new URLRequest();
		private const img_glow:GlowFilter = new GlowFilter();
		
		private var model:TSModelLocator;
		private var loading_info:LoadingInfo;
		private var imagination_slug:Slug;
		private var qurazy_quoin:Bitmap;
		
		private var is_built:Boolean;
		private var is_first_load:Boolean = true;
		
		private var details_alpha:Number = .7;
		private var prev_top_color:int = -1;
		private var prev_bottom_color:int = -1;
		
		private var prev_hub_name:String;
		
		private var welcome_rect:Rectangle;
		
		private var welcome_shadowA:Array;
		
		 /******************************************************
		 * http://svn.tinyspeck.com/wiki/Street_Loading_Screen *
		 ******************************************************/
		
		public function LoadingLocationView() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			model = TSModelLocator.instance;
			
			qurazy_quoin = new AssetManager.instance.assets.qurazy_quoin();
		}
		
		private function buildBase():void {
			//welcome to
			welcome_shadowA = StaticFilters.copyFilterArrayFromObject(
				{
					color:0xffffff,
					inner:true,
					blurY:0,
					strength:8,
					alpha:.2
				}, 
				StaticFilters.black7px0Degrees_DropShadowA
			);
			addChild(right_holder);
			
			const text_dropA:Array = StaticFilters.copyFilterArrayFromObject({blurX:2, blurY:2, alpha:.25}, StaticFilters.black3px90Degrees_DropShadowA);
			
			TFUtil.prepTF(welcome_tf, false);
			welcome_tf.htmlText = '<p class="loading_location_leave">Welcome to</p>';
			welcome_tf.alpha = CSSManager.instance.getNumberValueFromStyle('loading_location_leave', 'alpha', .4);
			welcome_holder.addChild(welcome_tf);
			
			TFUtil.prepTF(welcome_sm_tf, false);
			welcome_sm_tf.alpha = welcome_tf.alpha;
			welcome_sm_tf.htmlText = '<p class="loading_location_leave"><span class="loading_location_leave_small">Entering</span></p>';
			welcome_sm_holder.addChild(welcome_sm_tf);
			
			TFUtil.prepTF(welcome_hub_tf, false);
			welcome_hub_tf.y = int(welcome_tf.height - 8);
			welcome_hub_tf.filters = text_dropA;
			welcome_holder.addChild(welcome_hub_tf);
			
			TFUtil.prepTF(welcome_hub_sm_tf, false);
			welcome_hub_sm_tf.x = int(welcome_sm_tf.width);
			welcome_sm_holder.addChild(welcome_hub_sm_tf);
			
			welcome_holder.cacheAsBitmap = true;
			right_holder.addChild(welcome_holder);
			
			welcome_sm_holder.cacheAsBitmap = true;
			right_holder.addChild(welcome_sm_holder);
			
			//leaving
			TFUtil.prepTF(leaving_tf, false);
			leaving_tf.htmlText = '<p class="loading_location_leave">Leaving</p>';
			leaving_tf.alpha = welcome_tf.alpha
			leaving_holder.addChild(leaving_tf);
			
			TFUtil.prepTF(leaving_sm_tf, false);
			leaving_sm_tf.alpha = welcome_tf.alpha
			leaving_sm_tf.htmlText = '<p class="loading_location_leave"><span class="loading_location_leave_small">Leaving</span></p>';
			leaving_sm_holder.addChild(leaving_sm_tf);
			
			TFUtil.prepTF(leaving_hub_tf, false);
			leaving_hub_tf.y = int(leaving_tf.height - 8);
			leaving_hub_tf.filters = text_dropA;
			leaving_holder.addChild(leaving_hub_tf);
			
			TFUtil.prepTF(leaving_hub_sm_tf, false);
			leaving_hub_sm_tf.x = int(leaving_sm_tf.width);
			leaving_sm_holder.addChild(leaving_hub_sm_tf);
			
			leaving_holder.cacheAsBitmap = true;
			addChild(leaving_holder);
			
			leaving_sm_holder.cacheAsBitmap = true;
			addChild(leaving_sm_holder);
			
			tf_drop.angle = 90;
			tf_drop.distance = -1;
			tf_drop.blurX = tf_drop.blurY = 0;
			tf_drop.alpha = .3;
			
			TFUtil.prepTF(last_visit_tf, false);
			TFUtil.prepTF(entering_tf, false);
			TFUtil.prepTF(street_tf, false);
			TFUtil.prepTF(hub_tf, false);
			TFUtil.prepTF(home_tf);
			TFUtil.prepTF(upgrade_tf);
			upgrade_tf.wordWrap = false; //allows width to be dynamic
			
			last_visit_tf.filters = [tf_drop];
			entering_tf.filters = [tf_drop];
			street_tf.filters = text_dropA;
			hub_tf.filters = text_dropA;
			home_tf.filters = [tf_drop];
			upgrade_tf.filters = [tf_drop];
			
			all_holder.addChild(last_visit_tf);
			all_holder.addChild(img_holder);
			all_holder.addChild(img_mask);
			all_holder.addChild(entering_tf);
			all_holder.addChild(street_tf);
			all_holder.addChild(hub_tf);
			all_holder.addChild(home_tf);
			all_holder.addChild(upgrade_tf);
			
			addChild(all_holder);
			
			//enter text doesn't change
			entering_tf.htmlText = '<p class="loading_location_entering">Entering</p>';
			
			details_alpha = CSSManager.instance.getNumberValueFromStyle('loading_location_details', 'alpha', details_alpha);
			home_tf.alpha = upgrade_tf.alpha = details_alpha;
			
			//set the X the left tfs
			entering_tf.x = TEXT_PADD;
			street_tf.x = TEXT_PADD;
			hub_tf.x = TEXT_PADD;
			home_tf.x = TEXT_PADD;
			
			//setup the loader listeners
			img_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoad, false, 0, true);
			img_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onImageError, false, 0, true);
			
			//glow
			img_glow.color = 0xffffff;
			img_glow.blurX = img_glow.blurY = 15;
			img_glow.alpha = .15;
			img_glow.strength = 30;
			
			//pol related ui
			addChild(pol_ui);
			
			//progress bar
			progress_bar.show_perc_in_label = true;
			addChild(progress_bar);
			
			//upgrade badge
			var upgrade_badge:DisplayObject = new AssetManager.instance.assets.upgrade_badge();
			if(upgrade_badge) upgrade_badge_holder.addChild(upgrade_badge);
			all_holder.addChild(upgrade_badge_holder);
			
			is_built = true;
		}
		
		private function showRegular():void {
			var hub_label:String = loading_info.hub_name ? '<p class="loading_location_hub">in '+loading_info.hub_name+'</p>' : '';
			var last_visit_txt:String = '';
			
			//populate the tfs
			street_tf.htmlText = '<p class="loading_location_street">'+(loading_info.street_name ? loading_info.street_name : 'An Unknown Area')+'</p>';
			hub_tf.htmlText = hub_label;
			
			//iMG slug
			if(loading_info.imagination && loading_info.imagination.amount > 0){
				if(!imagination_slug){
					imagination_slug = new Slug(loading_info.imagination);
					imagination_slug.draw_border = false;
					all_holder.addChild(imagination_slug);
				}
				else {
					imagination_slug.amount = loading_info.imagination.amount;
				}
				
				imagination_slug.visible = true;
			}

			all_holder.addChild(qurazy_quoin)
			if (loading_info.qurazy_here) {
				qurazy_quoin.visible = true;
				if (imagination_slug) imagination_slug.visible = false;
			} else {
				qurazy_quoin.visible = false;
			}
			
			//last visit
			if(loading_info.first_visit){
				if (loading_info.qurazy_here) {
					last_visit_txt = '<span class="loading_location_highlight">First time here!</span> <b>Find the Qurazy Quoin:</b>';
				} else {
					last_visit_txt = '<span class="loading_location_highlight">First time here!</span>';
				}
			}
			else if(loading_info.last_visit_mins && !isNaN(loading_info.last_visit_mins)){
				last_visit_txt = 'Last here <b>'+StringUtil.formatTime(loading_info.last_visit_mins*60)+' ago</b>';
				
				//if we have visit counts
				if(loading_info.visit_count && !isNaN(loading_info.visit_count)){
					last_visit_txt += ' &#8212; ';
				}
			}
			
			//show the visit count
			//visit count is 0 based. so first visit = 0, 2nd = 1, etc.
			if(loading_info.visit_count && !isNaN(loading_info.visit_count) && !loading_info.first_visit){
				last_visit_txt += 'this is your '+StringUtil.addSuffix(loading_info.visit_count+1)+' visit';
			}
			
			last_visit_tf.htmlText = '<p class="loading_location_last_visit">'+last_visit_txt+'</p>';
			
			
			//build "home to" stuff
			buildHomeTo(loading_info.street_details);
			
			//build upgrade stuff
			buildUpgrade(loading_info.upgrade_details);
			
			//image stuff
			img_holder.mask = img_mask;
			img_holder.filters = [img_glow];
		}
		
		private function showBasic():void {
			//image stuff
			img_holder.mask = null;
			img_holder.filters = null;
		}
		
		private function showHouse():void {			
			//show the POL related screen
			pol_ui.show(loading_info.owner_tsid, loading_info.pol_type);
		}
		
		public function fadeIn():void {
			if(!model.moveModel.loading_info){
				CONFIG::debugging {
					Console.warn('The moveModel does not contain any loading_info!');
				}
				return;
			} 
			loading_info = model.moveModel.loading_info;
			const is_basic:Boolean = loading_info.is_basic;
			const is_house:Boolean = loading_info.owner_tsid != null;
			
			if(!is_built) buildBase();
			
			//set the visibility of the tfs depending on what mode we are in
			last_visit_tf.visible = !is_basic && !is_house;
			entering_tf.visible = !is_basic && !is_house;
			street_tf.visible = !is_basic && !is_house;
			hub_tf.visible = !is_basic && !is_house;
			home_tf.visible = !is_basic && !is_house;
			upgrade_tf.visible = !is_basic && !is_house;
			
			//hide until we need
			upgrade_badge_holder.visible = false;
			if(imagination_slug) imagination_slug.visible = false;
			qurazy_quoin.visible = false;
			
			//if house stuff, we don't need some things
			img_holder.visible = !is_house;
			pol_ui.visible = is_house;
			
			//set the holder to multiply so that the white bg doesn't suck
			img_holder.blendMode = is_basic ? BlendMode.MULTIPLY : BlendMode.NORMAL;
			
			//which version should we show
			if(is_house){
				showHouse();
			}
			else if(is_basic){
				showBasic();
			} 
			else {
				showRegular();
			}
						
			refresh();
			
			img_mask.visible = !is_basic && !is_house;
			if(!is_house) imageGet(loading_info.loading_img_url);
			
			visible = true;
			TSTweener.addTween(this, {alpha:1, time:.2, transition:'easeInCubic'});
			
			//reset the progress bar
			resetProgress('loading...');
		}
		
		public function fadeOut():void {
			TSTweener.addTween(this, {alpha:0, time:.5, transition:'easeInCubic', onComplete:done});
		}
		
		private function done():void {
			//save the previous values
			if (loading_info) {
				prev_hub_name = loading_info.hub_name;
				prev_top_color = loading_info.top_color;
				prev_bottom_color = loading_info.bottom_color;
			}
			
			//wipe out the location until the next load
			loading_info = null;
			visible = false;
			
			//play a sound
			if(!is_first_load){
				if(model.moveModel.move_type != MoveModel.DOOR_MOVE){
					SoundMaster.instance.playSound('STREET_LOADED');
				}
				else {
					SoundMaster.instance.playSound('DOOR_CLOSE');
				}
			}
			is_first_load = false;
		}
		
		public function refresh():void {
			if(!loading_info) return;
			loading_info = model.moveModel.loading_info; //make sure we have the latest and greatest
			
			bg_matrix.createGradientBox(
				model.layoutModel.loc_vp_w, 
				model.layoutModel.loc_vp_h, 
				Math.PI/2, //vertical grad
				0, 
				0
			);
			const padd_w:int = model.layoutModel.loc_vp_w * PADD_PERC;
			const img_w:int = model.layoutModel.loc_vp_w - padd_w*2;
			const top_color:uint = !loading_info.owner_tsid && !loading_info.is_basic ? loading_info.top_color : 0xffffff;
			const bottom_color:uint = !loading_info.owner_tsid && !loading_info.is_basic ? loading_info.bottom_color : 0xffffff;
			var tf_scale:Number;
			var g:Graphics;
			
			//set the bg colors
			BG_COLORS[0] = top_color;
			BG_COLORS[1] = bottom_color;
			
			//hide the right side unless we need it
			right_holder.visible = false;
			
			//hide the leaving by default
			leaving_holder.visible = false;
			leaving_sm_holder.visible = false;
			
			//do we need to show the split screen?
			if(top_color != 0xffffff){
				if(!prev_hub_name) {
					//no hub, let's record this one, no need for split screen
					prev_hub_name = loading_info.hub_name;
					prev_top_color = top_color;
					prev_bottom_color = bottom_color;
					
					welcome_holder.visible = false;
					welcome_sm_holder.visible = false;
				}
				else if(prev_hub_name != loading_info.hub_name){
					//hub has changed, let's show the split screen
					const buffer:uint = 10;
					const draw_w:int = model.layoutModel.loc_vp_w/2 + buffer; //little overflow buffer
					const curve_w:uint = 8;
					const curve_h:uint = 48;
					const seg_h:Number = curve_h/4;
					const curve_control:uint = 5;
					var next_y:uint;
					
					//draw the right side
					g = right_holder.graphics;
					g.clear();
					g.beginGradientFill(GradientType.LINEAR, BG_COLORS, BG_ALPHAS, BG_SPREAD, bg_matrix);
					
					//draw the curves (have to draw 4 curves for this bad boy, wtb 2 control points for curves)
					while(next_y < model.layoutModel.loc_vp_h){
						g.moveTo(0, next_y);
						g.curveTo(0,next_y+curve_control, -curve_w/2,next_y+seg_h);
						g.curveTo(-curve_w,next_y+seg_h*2-curve_control, -curve_w,next_y+seg_h*2);
						g.curveTo(-curve_w,next_y+seg_h*2+curve_control, -curve_w/2,next_y+seg_h*3);
						g.curveTo(0,next_y+curve_h-curve_control, 0,next_y+seg_h*4);
						
						g.lineTo(draw_w, next_y+curve_h);
						g.lineTo(draw_w, next_y);
						g.lineTo(0, next_y);
						
						next_y += curve_h;
					}
					
					right_holder.x = draw_w - buffer;
					right_holder.visible = true;
					right_holder.filters = (prev_top_color != loading_info.top_color || prev_bottom_color != loading_info.bottom_color) ? welcome_shadowA : null;
					
					//handle the leaving text
					leaving_hub_tf.htmlText = '<p class="loading_location_leave_hub">'+prev_hub_name+'</p>';
					leaving_holder.visible = (prev_hub_name != '' && right_holder.filters.length);
					leaving_hub_sm_tf.htmlText = '<p class="loading_location_leave_hub">' +
						'<span class="loading_location_leave_small">'+prev_hub_name+'</span>' +
						'</p>';
					
					leaving_holder.x = padd_w - 2; //-2 for the TF padding action
					leaving_sm_holder.x = padd_w - 2;
					
					//handle the welcome text
					welcome_hub_tf.htmlText = '<p class="loading_location_leave_hub">'+loading_info.hub_name+'</p>';
					welcome_holder.visible = loading_info.hub_name != '';
					welcome_tf.x = int(welcome_hub_tf.width - welcome_tf.width);
					welcome_rect = welcome_holder.getBounds(welcome_holder);
					
					welcome_hub_sm_tf.htmlText = '<p class="loading_location_leave_hub">' +
						'<span class="loading_location_leave_small">'+loading_info.hub_name+'</span>' +
						'</p>';
					
					welcome_holder.x = int(draw_w - welcome_rect.width - welcome_rect.x - buffer - padd_w + 2); //2 is cause of the flash TF width
					welcome_sm_holder.x = int(draw_w - welcome_sm_holder.width - buffer - padd_w + 2);
					welcome_sm_holder.visible = false;
					
					//set the colors to be the previous ones
					BG_COLORS[0] = prev_top_color;
					BG_COLORS[1] = prev_bottom_color;
				}
			}
			else {
				//clear out previous values
				prev_top_color = -1;
				prev_bottom_color = -1;
				prev_hub_name = null;
			}
			
			//draw the left side
			g = graphics;
			g.clear();
			g.beginGradientFill(GradientType.LINEAR, BG_COLORS, BG_ALPHAS, BG_SPREAD, bg_matrix);
			g.drawRect(0, 0, model.layoutModel.loc_vp_w, model.layoutModel.loc_vp_h);
			
			//handle the progress bar
			progress_bar.width = img_w;
			progress_bar.x = int(model.layoutModel.loc_vp_w/2 - progress_bar.width/2);
			progress_bar.y = model.layoutModel.loc_vp_h - progress_bar.height - 20;
			
			if(loading_info.owner_tsid){
				//center it
				pol_ui.refresh();
			}
			else if(!loading_info.is_basic){
				g = img_holder.graphics;
				g.clear();
				g.beginFill(0x666666);
				g.drawRoundRect(0, 0, img_w, IMG_H, 10);
				
				g = img_mask.graphics;
				g.clear();
				g.beginFill(0);
				g.drawRoundRect(0, 0, img_w, IMG_H, 10);
				
				//if the street name is larger than the img_w then we need to scale it down
				street_tf.scaleX = street_tf.scaleY = 1;
				if(street_tf.width > img_w - TEXT_PADD*2){
					tf_scale = (img_w - TEXT_PADD*2) / street_tf.width;
					street_tf.scaleX = street_tf.scaleY = tf_scale;
				}
				
				//last visit
				last_visit_tf.x = int(img_w - last_visit_tf.width);
				last_visit_tf.y = 0;
				img_holder.y = img_mask.y = int(last_visit_tf.height + 15);
				
				//slug
				if(imagination_slug){
					imagination_slug.x = int(img_w - imagination_slug.width);
					
					//place the last visit tf center with the slug
					if(imagination_slug.visible) last_visit_tf.x = int(imagination_slug.x - last_visit_tf.width);
					last_visit_tf.y = int(imagination_slug.height/2 - last_visit_tf.height/2) + 1;
					
					//img holder
					img_holder.y = img_mask.y = imagination_slug.height + 15;
				}
				
				if (loading_info.qurazy_here) {
					qurazy_quoin.x = int(img_w - qurazy_quoin.width);
					qurazy_quoin.y = 0;
					
					last_visit_tf.x = int(qurazy_quoin.x - last_visit_tf.width);
					last_visit_tf.y = int(qurazy_quoin.height/2 - last_visit_tf.height/2) + 1;
					
					//img holder
					img_holder.y = img_mask.y = qurazy_quoin.height + 15;
				}
				
				//tfs
				entering_tf.y = img_holder.y + IMG_H - 42;
				street_tf.y = int(entering_tf.y + entering_tf.height) - 10;
				hub_tf.y = int(street_tf.y + street_tf.height) - 7;
				home_tf.y = int(hub_tf.y + hub_tf.height) + 10;
				upgrade_tf.x = int(img_w - upgrade_tf.width - TEXT_PADD);
				upgrade_tf.y = home_tf.y;
				
				//setup how wide to make the home to stuff
				home_tf.width = upgrade_tf.text != '' ? upgrade_tf.x - TEXT_PADD*5 : img_w - TEXT_PADD*2;
				
				//if the street was recently upgraded then we need to position stuff a little different
				home_tf.visible = !upgrade_badge_holder.visible;
				if(upgrade_badge_holder.visible){
					home_tf.text = '';
					upgrade_badge_holder.y = home_tf.y + 10;
					upgrade_tf.x = int(upgrade_badge_holder.x + upgrade_badge_holder.width + TEXT_PADD);
					upgrade_tf.y = upgrade_badge_holder.y + int(upgrade_badge_holder.height/2 - upgrade_tf.height/2);
				}
				
				//center it
				all_holder.x = int(model.layoutModel.loc_vp_w/2 - img_w/2);
				all_holder.y = int(model.layoutModel.loc_vp_h/2 - Math.max(home_tf.y + home_tf.height, (upgrade_tf.visible ? upgrade_tf.y + upgrade_tf.height : 2))/2);
				
				//handle the progress bar
				progress_bar.x = all_holder.x;
				
				//if the home to text gets too close to the progress bar, hide the upgrade info
				if(upgrade_tf.text != '' && home_tf.y+home_tf.height > progress_bar.y - 35){
					home_tf.width = img_w - TEXT_PADD*2;
					all_holder.y = int(model.layoutModel.loc_vp_h/2 - (home_tf.y + home_tf.height)/2);
					upgrade_tf.visible = false;
				}
				else {
					upgrade_tf.visible = true;
				}
				
				//if we have home text and it's STILL too high, just hide it as well
				if(home_tf.visible && home_tf.y+home_tf.height > progress_bar.y - 35){
					home_tf.visible = false;
					all_holder.y = int(model.layoutModel.loc_vp_h/2 - (hub_tf.y + hub_tf.height)/2);
				}
				
				//welcome / leaving
				welcome_holder.y = int((all_holder.y +last_visit_tf.y)/2 - welcome_holder.height/2 + 2);
				leaving_holder.y = int((all_holder.y +last_visit_tf.y)/2 - leaving_holder.height/2 + 2);
				
				//if the big ones get too high, let's show the small ones
				if(leaving_holder.y <= 4 && leaving_holder.visible){
					welcome_holder.visible = false;
					welcome_sm_holder.y = int((all_holder.y +last_visit_tf.y)/2 - welcome_sm_holder.height/2 + 3);
					welcome_sm_holder.visible = loading_info.hub_name != '';
					leaving_holder.visible = false;
					leaving_sm_holder.y = int((all_holder.y +last_visit_tf.y)/2 - leaving_sm_holder.height/2 + 3);
					leaving_sm_holder.visible = prev_hub_name != '' && right_holder.filters.length;
				}
			}
			else {
				//center it
				img_holder.y = 0;
				all_holder.x = int(model.layoutModel.loc_vp_w/2 - img_holder.width/2);
				all_holder.y = int(model.layoutModel.loc_vp_h/2 - img_holder.height/2);
			}
		}
		
		public function resetProgress(txt:String = null):void {
			if (txt) Benchmark.addCheck('LoadingLocationView: '+txt);
			progress_bar.end(false);
			if(txt) progress_bar.start(0, txt, 0, true);
		}
		
		public function updateProgress(perc:Number):void {
			progress_bar.manualUpdate(perc, false);//don't fade it out
		}
		
		private function imageGet(img_url:String):void {			
			if(!img_url){
				//this is where we can put a generic image to load, for now a test image
				img_url = model.flashVarModel.root_url+'img/TEST-sample-groddle-loading-street.jpg';
			}
			
			if(img_holder.name != img_url){
				//clean out the old one if it's there
				SpriteUtil.clean(img_holder);
				
				img_holder.alpha = 0;
				
				//setup the URL to load
				img_req.url = img_url;
				img_loader.load(img_req, img_context);
				img_holder.name = img_url;
			}
			//just show the image already there
			else {
				imageShow();
			}
		}
		
		private function imageShow():void {
			if(img_holder && img_holder.numChildren > 0){
				var img:DisplayObject = img_holder.getChildAt(0);
				//imagePanLeft(img); //client processes a lot of data while it loads, this stutters pretty bad
				if(img_holder.alpha == 0) TSTweener.addTween(img_holder, {alpha:1, time:.2, transition:'linear'});
				refresh();
			}
			else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('Could not show the loading image!');
				}
			}
		}
		
		private function imagePanLeft(img:DisplayObject):void {
			if(visible && img){
				img.x = img.y = 0;
				TSTweener.addTween(img, {x:-40, time:3, transition:'linear', onComplete:imagePanRight, onCompleteParams:[img]});
			}
		}
		
		private function imagePanRight(img:DisplayObject):void {
			if(visible && img){
				TSTweener.addTween(img, {x:0, time:3, transition:'linear', onComplete:imagePanLeft, onCompleteParams:[img]});
			}
		}
		
		private function onImageLoad(event:Event):void {
			var img_new:DisplayObject = LoaderInfo(event.target).content;
			img_holder.addChild(img_new);
			img_loader.unload();
			imageShow();
		}
		
		private function onImageError(event:IOErrorEvent):void {
			CONFIG::debugging {
				Console.warn('Error loading image: '+event.text);
			}
		}
		
		private function buildHomeTo(details:LoadingStreetDetails):void {
			var home_txt:String = '';
			var i:int;
			
			var proj_txt:String = '<span class="loading_location_highlight">Active project!</span>';
			
			if (details && ((details.features && details.features.length > 0) || details.active_project)){
				//parse all the details in a bulleted list
				home_txt += '<p class="loading_location_details"><b>Home to:</b>';
				home_txt += '<ul>';
				
				// in this case we have features
				if (details.features && details.features.length > 0) {
					
					for(i = 0; i < details.features.length; i++){
						home_txt += '<li>'+details.features[int(i)]+
							(
								i == 0 && details.active_project 
								? '&nbsp;&nbsp;&nbsp;'+proj_txt 
								: ''
							)+
							'</li>';
					}
					
				// in this case we have no features but we do have an active project
				} else if (details.active_project) {
					
					home_txt += '<li>'+proj_txt+'</li>';
				}
				
				home_txt += '</ul>';
				home_txt += '</p>';
			}
				 
			home_tf.htmlText = home_txt;
		}
		
		private function buildUpgrade(details:LoadingUpgradeDetails):void {
			var indent:String = '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'; //fake indent since we don't want bullets
			var upgrade_txt:String = '';
			var i:int;
			var entry:LeaderboardEntry;
			var pc:PC;
			
			if(details){
				//parse the leaderboard
				if(details.leaderboard && details.leaderboard.entries.length > 0){
					upgrade_txt += '<p class="loading_location_details">';
					if(details.mins > 0){
						upgrade_txt += '<b>Upgraded '+StringUtil.formatTime(details.mins*60, false, false, 2)+' ago.</b> Led by:';
					}
					else {
						upgrade_txt += '<b>Upgrade project led by:</b>';
					}
					
					for(i = 0; i < details.leaderboard.entries.length; i++){
						entry = details.leaderboard.entries[int(i)];
						if(entry && entry.pc_tsid){
							pc = model.worldModel.getPCByTsid(entry.pc_tsid);
							if(pc) upgrade_txt += '<br>'+indent+'<b>'+pc.label+'</b>&nbsp;&nbsp;&nbsp;'+entry.contributions+'%';
						}
					}
					upgrade_txt += '</p>';
				}
				
				//upgraded since last visit?
				upgrade_badge_holder.visible = details.upgrade_since_last_visit;
			}
			
			upgrade_tf.htmlText = upgrade_txt;
		}
	}
}