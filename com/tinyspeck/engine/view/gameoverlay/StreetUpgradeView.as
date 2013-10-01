package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Rays;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.text.TextField;
		
	public class StreetUpgradeView extends BaseScreenView {
		/* singleton boilerplate */
		public static const instance:StreetUpgradeView = new StreetUpgradeView();
		
		private var badge_holder:Sprite = new Sprite();
		
		private var title_tf:TextField = new TextField();
		private var body_tf:TextField = new TextField();
		
		private var ok_bt:Button;
		
		public function StreetUpgradeView() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		override protected function buildBase():void {
			super.buildBase();
			
			//get color/alpha from CSS
			bg_color = CSSManager.instance.getUintColorValueFromStyle('street_upgrade_bg', 'color', 0xaaa78e);
			bg_alpha = CSSManager.instance.getNumberValueFromStyle('street_upgrade_bg', 'alpha', .9);
			
			//filters
			const title_drop:DropShadowFilter = new DropShadowFilter();
			title_drop.angle = 90;
			title_drop.distance = -1;
			title_drop.blurX = title_drop.blurY = 0;
			title_drop.alpha = .3;
			
			const body_drop:DropShadowFilter = new DropShadowFilter();
			body_drop.color = 0xffffff;
			body_drop.distance = 1;
			body_drop.angle = 90;
			body_drop.strength = 3;
			body_drop.alpha = .3;
			body_drop.blurX = body_drop.blurY = 0;

			//textfields
			TFUtil.prepTF(title_tf, false);
			TFUtil.prepTF(body_tf);
			
			all_holder.addChild(title_tf);
			all_holder.addChild(body_tf);

			title_tf.htmlText = '<p class="street_upgrade_title">Street Upgrade!</p>';
			title_tf.x = -title_tf.width/2;
			title_tf.filters = [title_drop];
			
			body_tf.width = int(title_tf.width);
			body_tf.x = int(-body_tf.width/2);
			body_tf.filters = [body_drop];
			
			ok_bt = new Button({
				label: 'Fantastic!',
				name: '_done_bt',
				value: 'done',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_DEFAULT
			});
			ok_bt.filters = StaticFilters.white4px40AlphaGlowA;
			ok_bt.x = int(-ok_bt.width/2);
			ok_bt.addEventListener(MouseEvent.CLICK, onOkClick, false, 0, true);
			
			all_holder.addChild(ok_bt);
			
			//upgrade badge
			var badge:DisplayObject = new AssetManager.instance.assets.upgrade_badge();
			if(badge) {
				SpriteUtil.setRegistrationPoint(badge);
				badge_holder.addChild(badge);
			}
			all_holder.addChild(badge_holder);
			
			//handle the rays
			loadRays(Rays.SCENE_THIN_SLOW, .5);
			rays.x = -137;
			rays.y = int(badge_holder.height/2) - 150;
		}

		override protected function draw():void {
			super.draw();
			
			//position
			title_tf.y = int(badge_holder.height/2);
			body_tf.y = int(title_tf.y + title_tf.height);
			ok_bt.y = int(body_tf.y + body_tf.height + 20);
			
			//center the stuff
			all_holder.x = model.layoutModel.gutter_w + int(draw_w/2);
			all_holder.y = int(model.layoutModel.loc_vp_h/2 - (ok_bt.y + ok_bt.height)/2 + badge_holder.height/2);
		}
		
		// SHOULD ONLY EVER BE CALLED FROM TSFrontController.instance.tryShowScreenViewFromQ();
		public function show(payload:Object):Boolean {
			if(!super.makeSureBaseIsLoaded()) return false;
			
			//text
			body_tf.htmlText = '<p class="street_upgrade_txt">This street, <span class="street_upgrade_txt_strong">'+model.worldModel.location.label+'</span>'+
							   ', was just upgraded thanks to lovely people like you who contributed to <span class="street_upgrade_txt_strong">a project</span> here.'+
							   '<br><br><span class="street_upgrade_txt_strong">Give us a second to reload the street</span> '+
							   'and then stroll about and peruse the <span class="street_upgrade_txt_strong">improvements!</span></p>';
			
			//prep the animation
			draw();
			animate();
			
			return tryAndTakeFocus(payload);
		}
		
		override protected function animate():void {
			var i:int;
			var tf:TextField;
			var texts:Vector.<TextField> = new Vector.<TextField>();
			var final_y:int;
			var offset:int = 40;
			
			//fade in
			super.animate();
			
			//badge
			badge_holder.alpha = 0;
			badge_holder.scaleX = badge_holder.scaleY = 1.2;
			TSTweener.addTween(badge_holder, {scaleX:1, scaleY:1, alpha:1, time:.7, transition:'easeOutBounce'});
			
			//tfs
			texts.push(title_tf, body_tf);
			for(i = 0; i < texts.length; i++){
				tf = texts[int(i)];
				final_y = tf.y;
				tf.alpha = 0;
				tf.y += offset;
				
				TSTweener.addTween(tf, {alpha:1, y:final_y, time:.4, delay:.7 + (i*.2), transition:'easeOutBounce'});
			}
			
			//ok button
			final_y = ok_bt.y;
			ok_bt.alpha = 0;
			ok_bt.y += offset;
			TSTweener.addTween(ok_bt, {y:final_y, alpha:1, time:.4, delay:1.3, transition:'easeOutBounce', 
				onComplete:function():void {
					ready_for_input = true;
				}
			});
		}
	}
}