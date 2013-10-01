package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.api.APICall;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.ShortUrlType;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.data.reward.Rewards;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.loader.SmartLoader;
	import com.tinyspeck.engine.net.NetOutgoingShareTrackVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.ChatBubble;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.util.URLUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Slug;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.text.TextField;
	
	// http://svn.tinyspeck.com/wiki/Level_up_sequence
	
	public class AchievementView extends BaseScreenView {
		
		/* singleton boilerplate */
		public static const instance:AchievementView = new AchievementView();
		
		private const DESCRIPTION_WIDTH:uint = 640;
		private const FAMILIAR_WH:uint = 68; //85
		private const BADGE_WH:uint = 165; //204
		private const FAM_END_Y:uint = 96; //120
		
		private var badge_final_y:int;
		
		private var fam_local_pt:Point;
		private var fam_global_pt:Point;
		
		private var title_bm:Bitmap = new Bitmap();
		private var title_bm_data:BitmapData;
		
		private var badge_url:String;
		private var badge_tsid:String;
		
		private var badge_holder:Sprite = new Sprite();
		private var fam_shadow:Sprite = new Sprite();
		private var badge_shadow:Sprite = new Sprite();
		private var slugs_holder:Sprite = new Sprite();
		private var button_holder:Sprite = new Sprite();
		private var title_holder:Sprite = new Sprite();
		
		private var title_tf:TextField = new TextField();
		private var desc_tf:TextField = new TextField();
		
		private var ok_bt:Button;
		private var twitter_bt:Button;
		private var facebook_bt:Button;
		private var fam_icon:ItemIconView;
		private var chat_bubble:ChatBubble;
		private var fam_shadow_blur:BlurFilter = new BlurFilter();
		private var badge_shadow_blur:BlurFilter = new BlurFilter();
		private var rewards:Vector.<Reward>;
		private var api_call:APICall;
		
		private var is_badge_loaded:Boolean;
		private var is_badge_loading:Boolean;
		
		private var status_text:String;
		private var short_url:String;
		
		public function AchievementView() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		override protected function buildBase():void {
			super.buildBase();
			
			all_holder.addChild(badge_holder);
						
			bg_color = CSSManager.instance.getUintColorValueFromStyle('achievement_bg', 'color', 0xa7c39c);
			bg_alpha = CSSManager.instance.getNumberValueFromStyle('achievement_bg', 'alpha', .9);
			
			//TFs
			TFUtil.prepTF(title_tf, false);
			title_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			all_holder.addChild(title_holder);
			
			TFUtil.prepTF(desc_tf);
			desc_tf.width = DESCRIPTION_WIDTH;
			desc_tf.filters = StaticFilters.black2px90Degrees_DropShadowA;
			all_holder.addChild(desc_tf);
			
			//slugs
			all_holder.addChild(slugs_holder);
			
			//ok buttons
			ok_bt = new Button({
				label: 'OK, Good!',
				name: 'ok_bt',
				value: 'ok',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_DEFAULT
			})
			ok_bt.addEventListener(MouseEvent.CLICK, onOkClick, false, 0, true);
			ok_bt.filters = StaticFilters.white4px40AlphaGlowA;
			all_holder.addChild(ok_bt);
			
			
			//share buttons
			const bt_w:int = 125;
			facebook_bt = new Button({
				name: 'facebook',
				label: 'Share this',
				graphic: new AssetManager.instance.assets.facebook(),
				graphic_padd_l: 19,
				graphic_padd_t: 7,
				graphic_padd_r: 7,
				graphic_placement: 'left',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_FACEBOOK,
				w: bt_w
			});
			facebook_bt.addEventListener(TSEvent.CHANGED, onShareButtonClick, false, 0, true);
			button_holder.addChild(facebook_bt);
			
			twitter_bt = new Button({
				name: 'twitter',
				label: 'Tweet this',
				graphic: new AssetManager.instance.assets.twitter(),
				graphic_padd_l: 15,
				graphic_padd_r: 5,
				graphic_placement: 'left',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_TWITTER,
				w: bt_w
			});
			twitter_bt.addEventListener(TSEvent.CHANGED, onShareButtonClick, false, 0, true);
			twitter_bt.x = facebook_bt.width + 10;
			button_holder.addChild(twitter_bt);
			
			button_holder.filters = StaticFilters.white4px40AlphaGlowA;
			
			//fam icon
			fam_icon = new ItemIconView('pet_rock', FAMILIAR_WH, 'idle');
			fam_icon.x = 180;
			fam_icon.y = FAM_END_Y;
			fam_local_pt = new Point(FAMILIAR_WH - 20, 10); //so we know where to place the chat bubble
			all_holder.addChild(fam_icon);
			
			//familar shadow
			var g:Graphics = fam_shadow.graphics;
			g.beginFill(0, .8);
			g.drawEllipse(0, 0, FAMILIAR_WH/2, 10);
			fam_shadow.x = fam_icon.x + (FAMILIAR_WH/2 - fam_shadow.width/2);
			fam_shadow.y = fam_icon.y + FAMILIAR_WH - fam_shadow.height;
			all_holder.addChildAt(fam_shadow, all_holder.getChildIndex(fam_icon));
			
			chat_bubble = new ChatBubble();
			chat_bubble.offset_x = 100;
			chat_bubble.max_w = 300;
			
			//handle the rays
			loadRays();
			rays.x = -330;
			rays.y = -210;
			
			//api stuff
			api_call = new APICall();
			api_call.addEventListener(TSEvent.COMPLETE, onAPIComplete, false, 0, true);
		}
		
		private function loadBadge():void {
			is_badge_loaded = false;
			is_badge_loading = true;
			if (badge_url != 'none'){
				var delay_ms:int = 0; // make this a big number to test for any badness
				
				var sl:SmartLoader = new SmartLoader(badge_url);
				sl.complete_sig.add(onBadgeLoadFromNet);
				sl.error_sig.add(onBadgeLoadFromNetFail);
				StageBeacon.setTimeout(sl.load, delay_ms, new URLRequest(badge_url));
			} else {
				var badge_default:MovieClip = new AssetManager.instance.assets.achievement_badge();
				badge_default.addEventListener(Event.COMPLETE, onBadgeLoadedFromAssets, false, 0, true);
			}
		}
		
		private function onBadgeLoadFromNetFail(sl:SmartLoader):void {
			badge_url = 'none';
			loadBadge();
		}
		
		private function onBadgeLoadFromNet(sl:SmartLoader):void {
			if (sl.start_url != badge_url) {
				// I supposed this can happen if you get a second achieve before the first has loaded the asset?
				Benchmark.addCheck('AV.onBadgeLoadFromNet was waiting for '+badge_url+' but got '+sl.start_url != badge_url);
			} else {
				var badge_swf:MovieClip = sl.content as MovieClip;
				if (!badge_swf) {
					onBadgeLoadFromNetFail(sl);
				} else {
					placeBadge(badge_swf);
				}
			}
		}
		
		private function onBadgeLoadedFromAssets(event:Event):void {
			//get the badge
			var badge:DisplayObject = Loader(event.target.getChildAt(0)).content as MovieClip;
			placeBadge(badge);
		}
		
		private function placeBadge(badge:DisplayObject):void {
			if(badge){
				badge.width = badge.height = BADGE_WH;
				SpriteUtil.clean(badge_holder);
				badge_holder.addChildAt(badge, 0);
				
				//badge shadow
				var g:Graphics = badge_shadow.graphics;
				g.clear();
				g.beginFill(0, .8);
				g.drawEllipse(0, 0, badge.width/2, 15);
				badge_shadow.x = badge.width/2 - badge_shadow.width/2;
				badge_shadow.y = badge.height - badge_shadow.height/2;
				all_holder.addChildAt(badge_shadow, all_holder.getChildIndex(badge_holder));
				
				is_badge_loaded = true;
			}
			else {
				CONFIG::debugging {
					Console.warn('SOMETHING WRONG WITH THE BADGE!');
				}
			}
			
			is_badge_loading = false;
		}
		
		override protected function draw():void {						
			super.draw();
			
			//scale the title if it's too big
			const max_w:int = draw_w - 60;
			title_holder.scaleX = title_holder.scaleY = 1;
			if(title_holder.width > max_w){
				title_holder.scaleX = title_holder.scaleY = max_w / title_holder.width;
			}
			
			title_holder.x = badge_holder.x + int(badge_holder.width/2 - title_holder.width/2);
			
			var next_y:int = title_holder.y + title_holder.height + 10;
			
			//center
			slugs_holder.x = title_holder.x + int(title_holder.width/2 - slugs_holder.width/2);
			slugs_holder.y = next_y;
			next_y += slugs_holder.height + 15;
			
			//showing the share stuff?
			if(button_holder.parent){
				button_holder.y = next_y;
				next_y += twitter_bt.height + 20;
			}
			
			ok_bt.y = next_y;
			
			//move the graphics
			all_holder.x = model.layoutModel.gutter_w + int(draw_w/2 - badge_holder.width/2);
			all_holder.y = int(model.layoutModel.loc_vp_h/2 - (next_y+ok_bt.height)/2 + 48);
		}
		
		override protected function done():void {			
			TSTweener.addTween(chat_bubble, {alpha:0, time:.1, transition:'linear'});
			super.done();
		}
		
		override protected function onDoneTweenComplete():void {
			super.onDoneTweenComplete();
			
			//kill any running tweens
			TSTweener.removeTweens([badge_holder, fam_icon, title_holder, desc_tf, ok_bt]);
			
			chat_bubble.show('');
			chat_bubble.hide();
			if(chat_bubble.parent) chat_bubble.parent.removeChild(chat_bubble);
			
			//changeFamiliarVisibility knows to show familiar stuff if needed when this is off the stage
			TSFrontController.instance.changeTeleportDialogVisibility();
		}
		
		/*{
			type: 'achievement_complete',
			tsid: id,
			name: achievement.name,
			desc: achievement.desc,
			status_text: status,
			rewards: {
				recipes: { 
					0: null
				},
				xp: 0,
				mood: 0,
				energy: 0,
				currants: 0
			}
		}
		*/
		
		// SHOULD ONLY EVER BE CALLED FROM TSFrontController.instance.tryShowScreenViewFromQ();
		public function show(payload:Object):Boolean {
			if(!super.makeSureBaseIsLoaded()) return false;
			
			//make sure we've got the right badge loaded
			if (badge_tsid == payload.tsid) {
				if (!is_badge_loaded) {
					if (!is_badge_loading) {
						loadBadge();
					}
					return false;
				}
			} else {
				badge_tsid = payload.tsid;
				badge_url = payload.swf_url || 'none';
				loadBadge();
				return false;
			}
			
			status_text = payload.status_text;
						
			desc_tf.htmlText = '<p class="achievement_description">'+payload.desc+'</p>';
			desc_tf.x = badge_holder.x + int(badge_holder.width/2 - desc_tf.width/2);
			desc_tf.y = int(badge_holder.height) + 10;
			
			title_tf.htmlText = '<p class="achievement_title">'+payload.name+'</p>';
			title_holder.y = int(desc_tf.y + desc_tf.height) - 5;
			setTitleText();
			
			//clear the rewards
			rewards = new Vector.<Reward>();
			if(payload.rewards) rewards = Rewards.fromAnonymous(payload.rewards);
			displaySlugs();

			ok_bt.x = badge_holder.x + int(badge_holder.width/2 - ok_bt.width/2);
			
			//do we show the share buttons?
			twitter_bt.visible = false;
			facebook_bt.visible = false;
			
			if('is_shareworthy' in payload && Boolean(payload.is_shareworthy)){
				all_holder.addChild(button_holder);
			}
			else if(button_holder.parent){
				button_holder.parent.removeChild(button_holder);
			}
			button_holder.x = badge_holder.x + int(badge_holder.width/2 - button_holder.width/2);
			
			//go ask the API for a short URL
			if('url' in payload) api_call.clientGetShortUrl(ShortUrlType.ACHIEVEMENT, payload.url);
			
			//setup to animate
			draw();
			animate();
			
			return tryAndTakeFocus(payload);
		}
		
		override public function refresh():void {
			if(!is_built) return;
			
			super.refresh();
			
			//place the chat bubble where it needs to go
			if(fam_icon && chat_bubble.parent){
				fam_global_pt = fam_icon.localToGlobal(fam_local_pt);
				chat_bubble.x = fam_global_pt.x;
				chat_bubble.y = fam_global_pt.y;
			}
		}
		
		private function displaySlugs():void {
			SpriteUtil.clean(slugs_holder);
			
			//throws the slugs in the holder and centers them
			var next_x:int;
			var padd:int = 4;
			var i:int;
			var total:int = rewards.length;
			var slug:Slug;
			var recipe_count:int;
			
			for(i; i < total; i++){
				if(rewards[int(i)].amount != 0){
					if(rewards[int(i)].type != Reward.RECIPES){
						slug = new Slug(rewards[int(i)]);
						slug.x = next_x;
						next_x += int(slug.width + padd);
						slugs_holder.addChild(slug);
					}
					else {
						recipe_count++;
					}
				}
			}
			
			//if we have any recipes
			if(recipe_count){
				var tf:TextField = new TextField();
				TFUtil.prepTF(tf, false);
				tf.htmlText = '<p class="achievement_recipe">+'+recipe_count+' new '+(recipe_count != 1 ? 'recipes' : 'recipe')+'!</p>';
				tf.x = next_x;
				tf.y = int(slugs_holder.height/2 - tf.height/2);
				tf.filters = StaticFilters.black1px90Degrees_DropShadowA;
				slugs_holder.addChild(tf);
			}
		}
		
		override protected function animate():void {
			var i:int;
			var DO:DisplayObject;
			var final_y:int;
			var offset:int = 40;
			
			//fade in
			super.animate();
			
			//kill any running tweens
			TSTweener.removeTweens([badge_holder, fam_icon, title_holder, desc_tf, ok_bt, button_holder]);
			
			// changeFamiliarVisibility knows to hide familiar stuff when this is on the stage
			TSFrontController.instance.changeTeleportDialogVisibility();
			
			//badge
			badge_shadow.visible = false;
			badge_final_y = badge_holder.y;
			badge_holder.y = -all_holder.y - badge_holder.height*2;
			
			TSTweener.addTween(badge_holder, {y:badge_final_y, time:.7, transition:'easeOutBounce',
				onStart:function():void {
					badge_shadow.visible = true;
					
					//update the blur
					onBadgeUpdate();
				},
				onUpdate:onBadgeUpdate
			});

			//familiar	
			fam_shadow.visible = false;
			if(fam_icon){				
				fam_icon.y = -all_holder.y - fam_icon.height*2;
				
				TSTweener.addTween(fam_icon, {y:FAM_END_Y, time:1, delay:1, transition:'easeOutBounce',
					onStart:function():void {
						fam_shadow.visible = true;
						//update the shadow blur
						onFamiliarUpdate();
					},
					onUpdate:onFamiliarUpdate,
					onComplete:onFamiliarAnimationComplete
				});
			}
			
			//tfs			
			final_y = desc_tf.y;
			desc_tf.y += offset;
			desc_tf.alpha = 0;
			TSTweener.addTween(desc_tf, {alpha:1, y:final_y, time:.4, delay:.7, transition:'easeOutBounce'});
			
			final_y = title_holder.y;
			title_holder.y += offset;
			title_holder.alpha = 0;
			TSTweener.addTween(title_holder, {alpha:1, y:final_y, time:.4, delay:1, transition:'easeOutBounce'});
			
			//slugs
			for(i = 0; i < slugs_holder.numChildren; i++){
				DO = slugs_holder.getChildAt(i);
				final_y = DO.y;
				DO.alpha = 0;
				DO.y += offset;
				TSTweener.addTween(DO, {y:final_y, alpha:1, time:.3, delay:1.3 + (i * .2), transition:'easeOutBounce'});
			}
			
			//share buttons maybe
			if(button_holder.parent){
				final_y = button_holder.y;
				button_holder.alpha = 0;
				button_holder.y += offset;
				TSTweener.addTween(button_holder, {y:final_y, alpha:1, time:.4, delay:1.5, transition:'easeOutBounce'});
			}
			
			//ok button
			final_y = ok_bt.y;
			ok_bt.alpha = 0;
			ok_bt.y += offset;
			TSTweener.addTween(ok_bt, {y:final_y, alpha:1, time:.4, delay:1.5, transition:'easeOutBounce', 
				onComplete:function():void {
					is_badge_loaded = false; //reset for next time
					dispatchEvent(new TSEvent(TSEvent.COMPLETE));
				}
			});
		}
		
		private function setTitleText():void {
			//we draw this as a bitmap because scaling the text dances too damn much
			SpriteUtil.clean(title_holder);
			title_bm_data = new BitmapData(title_tf.width, title_tf.height, true, 0);
			title_bm_data.draw(title_tf);
			title_bm.bitmapData = title_bm_data;
			title_bm.smoothing = true;
			title_holder.addChild(title_bm);
		}
		
		private function onBadgeUpdate():void {
			var badge_gap:int = badge_final_y - badge_holder.y;
			
			badge_shadow_blur.blurX = 90 + badge_gap/10;
			badge_shadow_blur.blurY = 15 + badge_gap/10;
			
			badge_shadow.filters = [badge_shadow_blur];
		}
		
		private function onFamiliarUpdate():void {
			var fam_gap:int = FAM_END_Y - fam_icon.y;
			fam_shadow_blur.blurX = 25 + fam_gap/10;
			fam_shadow_blur.blurY = 15 + fam_gap/10;
			
			fam_shadow.filters = [fam_shadow_blur];
		}
		
		private function onFamiliarAnimationComplete():void {			
			TSTweener.addTween(fam_icon, {delay:.4, 
				onComplete:function():void {
					chat_bubble.show('<b>New Achievement!</b>'+(status_text ? '<br>'+status_text : ''));
					TSFrontController.instance.getMainView().addView(chat_bubble);
					refresh();
				}
			});
		}
		
		private function onShareButtonClick(event:TSEvent):void {
			//depending on what we are doing, handle it
			const bt:Button = event.data as Button;
			if(bt == twitter_bt){
				const extra:String = ' '+short_url+' %23glitchbadge';
				
				//make sure we aren't over the allowed chars for the twitters (+2 is for the %23 going to #)
				const text:String = StringUtil.truncate('I just got the '+title_tf.text+' badge!', 140-extra.length+2);
				
				URLUtil.openTwitter(text+extra);
			}
			else if(bt == facebook_bt){
				URLUtil.openFacebook(short_url);
			}
			
			//tell the server we clicked it
			TSFrontController.instance.genericSend(new NetOutgoingShareTrackVO('achievement', bt ? bt.name : 'unknown', short_url));
		}
		
		private function onAPIComplete(event:TSEvent):void {
			//show the share buttons			
			if(event && event.data && 'url' in event.data){
				short_url = event.data.url;
				twitter_bt.visible = true;
				facebook_bt.visible = true;
			}
		}
	}
}