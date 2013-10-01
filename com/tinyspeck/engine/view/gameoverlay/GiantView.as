package com.tinyspeck.engine.view.gameoverlay
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.giant.Giants;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.text.TextField;
	import flash.utils.getTimer;

	public class GiantView extends BaseScreenView
	{
		/* singleton boilerplate */
		public static const instance:GiantView = new GiantView();
		
		private static const TEXT_OFFSET:int = 20; //how much left to go based on the FLV width
		private static const TEXT_PADD:int = 20; //how much padding on the right before it starts to auto size the body
		private static const MAX_BODY_W:uint = 350;
		private static const MAX_TIP_BODY_W:uint = 500;
		private static const MAX_WAIT_MS:uint = 10000;
		private static const NO_VIDEO_W:uint = 170; //width if the flv isn't loaded
		private static const DEFAULT_LOOP_COUNT:uint = 999;
		private static const DEFAULT_ALPHA:Number = .75;
		private static const DEFAULT_TIP_TITLE_ALPHA:Number = .65;
		private static const DEFAULT_TIP_BODY_ALPHA:Number = 1;
		private static const DEFAULT_TIP_TITLE:String = 'Donation Tip:';
		private static const DEFAULT_SOUND:String = 'GONG_GIANTS';
		
		private var text_holder:Sprite = new Sprite();
		private var text_mask:Sprite = new Sprite();
		private var giant_holder:Sprite = new Sprite();
		private var donation_holder:Sprite = new Sprite();
		private var tip_holder:Sprite = new Sprite();
		
		private var name_tf:TextField = new TextField();
		private var sex_tf:TextField = new TextField();
		private var giant_of_tf:TSLinkedTextField = new TSLinkedTextField();
		private var body_tf:TextField = new TextField();
		private var donation_tf:TextField = new TextField();
		private var donation_name_tf:TextField = new TextField();
		private var tip_title_tf:TextField = new TextField();
		private var tip_body_tf:TSLinkedTextField = new TSLinkedTextField();
		private var no_video_tf:TextField = new TextField();
		
		private var flv:ArbitraryFLVView;
		private var ok_bt:Button;
		
		private var text_holder_w:int; //used to take a snapshot at the full scale
		private var wait_time:int;
		
		private var is_side_shifting:Boolean;
		private var is_waiting_for_flv:Boolean;
		private var start_with_tip:Boolean;
		
		public function GiantView(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		override protected function buildBase():void {
			super.buildBase();
			
			const text_shadowA:Array = StaticFilters.copyFilterArrayFromObject({alpha:.35}, StaticFilters.black3px90Degrees_DropShadowA);
			
			TFUtil.prepTF(name_tf, false);
			name_tf.htmlText = '<p class="giant_name">placeholder</p>';
			name_tf.filters = text_shadowA
			text_holder.addChild(name_tf);
			
			TFUtil.prepTF(sex_tf, false);
			sex_tf.htmlText = '<p class="giant_name"><span class="giant_sex">(f.)</span></p>';
			sex_tf.alpha = CSSManager.instance.getNumberValueFromStyle('giant_sex', 'alpha', .5);
			sex_tf.y = int(name_tf.height/2 - sex_tf.height/2 + 2);
			sex_tf.filters = text_shadowA;
			text_holder.addChild(sex_tf);
			
			TFUtil.prepTF(giant_of_tf);
			giant_of_tf.y = int(name_tf.height);
			giant_of_tf.filters = text_shadowA;
			giant_of_tf.alpha = CSSManager.instance.getNumberValueFromStyle('giant_body', 'alpha', .9);
			text_holder.addChild(giant_of_tf);
			
			TFUtil.prepTF(body_tf);
			body_tf.filters = text_shadowA;
			body_tf.alpha = giant_of_tf.alpha;
			text_holder.addChild(body_tf);
			
			//mask
			var g:Graphics = text_mask.graphics;
			g.beginFill(0);
			g.drawRect(0, 0, 1, 1);
			text_holder.mask = text_mask;
			giant_holder.addChild(text_holder);
			giant_holder.addChild(text_mask);
			all_holder.addChild(giant_holder);
			
			//builds the "click anywhere" button
			ok_bt = new Button({
				name: 'ok',
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
			ok_bt.mouseEnabled = false;
			all_holder.addChild(ok_bt);
			
			addEventListener(MouseEvent.CLICK, onOkClick, false, 0, true);
			
			//donation
			TFUtil.prepTF(donation_tf, false);
			donation_tf.htmlText = '<p class="giant_name"><span class="giant_donation">A donation to...</span></p>';
			donation_tf.alpha = CSSManager.instance.getNumberValueFromStyle('giant_donation', 'alpha', .5);
			donation_tf.filters = text_shadowA;
			donation_holder.addChild(donation_tf);
			
			TFUtil.prepTF(donation_name_tf, false);
			donation_name_tf.y = int(donation_tf.height - 13);
			donation_name_tf.filters = text_shadowA;
			donation_holder.addChild(donation_name_tf);
			
			donation_holder.cacheAsBitmap = true;
			all_holder.addChild(donation_holder);
			
			//donation tip
			TFUtil.prepTF(tip_title_tf, false);
			tip_title_tf.htmlText = '<p class="giant_name"><span class="giant_tip">'+DEFAULT_TIP_TITLE+'</span></p>';
			tip_title_tf.filters = text_shadowA;
			tip_holder.addChild(tip_title_tf);
			
			TFUtil.prepTF(tip_body_tf, true, {color:CSSManager.instance.getStringValueFromStyle('giant_tip_link', 'colorHover', '#ffbf63')});
			tip_body_tf.y = int(tip_title_tf.height);
			tip_body_tf.filters = text_shadowA;
			tip_body_tf.addEventListener(TextEvent.LINK, onTextLink, false, 0, true);
			tip_holder.addChild(tip_body_tf);
			
			tip_holder.cacheAsBitmap = true;
			all_holder.addChild(tip_holder);
			
			//if the video fails to load we show some text
			TFUtil.prepTF(no_video_tf);
			no_video_tf.width = NO_VIDEO_W;
			no_video_tf.htmlText = '<p class="giant_no_video">there was a cool video to show here, but it seems like our connection is not good enough to show it</p>';
			no_video_tf.x = int(-no_video_tf.width/2);
			no_video_tf.y = int(-no_video_tf.height/2);
			no_video_tf.alpha = CSSManager.instance.getNumberValueFromStyle('giant_no_video', 'alpha', .3);
			giant_holder.addChild(no_video_tf);
			
			//set our fade in time a little longer than default
			fade_in_secs = .8;
		}
		
		// SHOULD ONLY EVER BE CALLED FROM TSFrontController.instance.tryShowScreenViewFromQ();
		public function show(payload:Object):Boolean {
			if(!super.makeSureBaseIsLoaded()) return false;
			
			//load the flv
			if('flv_url' in payload){
				if(flv && flv.flv_url == payload.flv_url){
					//remove from the stage until we need it
					if(flv.parent) flv.parent.removeChild(flv);
				}
				else if(!flv){
					const loop_count:uint = 'loop_count' in payload ? payload.loop_count : DEFAULT_LOOP_COUNT;
					flv = new ArbitraryFLVView(payload.flv_url, 0, 0, 'center', loop_count);
				}
			}
			else {
				if(flv) flv.dispose();
				CONFIG::debugging {
					Console.warn('Giant view without a flv_url. Not good!!!');
				}
			}
			
			//are we jumping right to the tip?
			start_with_tip = 'start_with_tip' in payload && payload.start_with_tip === true;
			
			//set the sound
			if(!('sound' in payload)) payload.sound = DEFAULT_SOUND;
			
			//set the bg alpha/color (defaults to .5/black if not passed)
			bg_color = 'bg_color' in payload ? StringUtil.cssHexToUint(payload.bg_color) : Giants.getBgColor(payload.tsid);
			bg_alpha = 'bg_alpha' in payload ? payload.bg_alpha : DEFAULT_ALPHA;
			
			//populate the text
			setText(payload);
			
			//reset
			giant_holder.scaleX = giant_holder.scaleY = 1;
			text_mask.width = text_mask.height = 1;
			ok_bt.alpha = 0;
			tip_holder.visible = false;
			is_waiting_for_flv = false;
			no_video_tf.visible = false;
			
			//setup to animate
			draw();
			
			//set the full scale width
			text_holder_w = text_holder.width;
			
			animate();
			
			//place it
			text_holder.y = int(-text_holder.height/2 - 15);
			text_mask.y = text_holder.y;
			
			return tryAndTakeFocus(payload);
		}
		
		private function setText(payload:Object):void {
			name_tf.htmlText = '<p class="giant_name">'+Giants.getLabel(payload.tsid)+(start_with_tip ? ' says...' : '')+'</p>';
			
			var giant_sex:String = Giants.getSex(payload.tsid) == Giants.SEX_MALE ? '(m.)' : '(f.)';
			if(Giants.getSex(payload.tsid) == Giants.SEX_NONE && !start_with_tip) {
				giant_sex = '(n/a)';
			}
			else if(start_with_tip){
				//axing the sex when just showing a tip
				giant_sex = '';
			}
			sex_tf.htmlText = '<p class="giant_name"><span class="giant_sex">'+giant_sex+'</span></p>';
			sex_tf.x = int(name_tf.width + 12);
			
			var traits_txt:String = '<p class="giant">';
			if(!start_with_tip){
				const traits:Array = String(payload.personality).split(',');
				const total:uint = traits.length;
				var i:int;
				
				traits_txt += 'Giant of '+payload.giant_of+'<br>';
				for(i; i < total; i++){
					if(i < total-1){
						traits_txt += traits[int(i)] + (total > 2 ? ', ' : ' ');
					}
					else {
						traits_txt += total > 1 ? 'and' : '';
						traits_txt += traits[int(i)];
					}
				}
			}
			else {
				//just show the tip text right in the trait area
				traits_txt += StringUtil.injectClass(payload.tip_body, 'a', 'giant_tip_link');
			}
			
			traits_txt += '</p>';
			
			giant_of_tf.htmlText = traits_txt;
			
			var body_txt:String = '<p class="giant"><span class="giant_body">';
			if(!start_with_tip){
				body_txt += payload.desc;
				body_txt += ' Adherents are known as "'+payload.followers+'".';
			}
			body_txt += '</span></p>';
			
			body_tf.htmlText = body_txt;
			
			//donation name
			donation_name_tf.htmlText = '<p class="giant_name"><span class="giant_donation_name">'+Giants.getLabel(payload.tsid)+'</span></p>';
			const max_text_w:int = Math.max(donation_name_tf.width, donation_tf.width);
			donation_tf.x = int(max_text_w/2 - donation_tf.width/2);
			donation_name_tf.x = int(max_text_w/2 - donation_name_tf.width/2);
			
			//donation tip
			tip_title_tf.alpha = 'tip_title_alpha' in payload ? payload.tip_title_alpha as Number : DEFAULT_TIP_TITLE_ALPHA;
			tip_title_tf.htmlText = '<p class="giant_name"><span class="giant_tip">'+
				('tip_title' in payload ? payload.tip_title as String : DEFAULT_TIP_TITLE)+
				'</span></p>';
			tip_body_tf.htmlText = '<p class="giant_name"><span class="giant_tip_body">'+
				StringUtil.injectClass(payload.tip_body, 'a', 'giant_tip_link')+
				'</span></p>';
		}
		
		override protected function draw():void {
			super.draw();
			
			const art_w:int = flv && flv.art_w ? flv.art_w : no_video_tf.width;
			const lm:LayoutModel = model.layoutModel;
			const max_text_w:int = Math.min(lm.loc_vp_w - text_holder.x - art_w/2 - TEXT_PADD, MAX_BODY_W);
			
			//make sure the text fits
			giant_of_tf.width = max_text_w;
			body_tf.y = int(giant_of_tf.y + giant_of_tf.height + 15);
			body_tf.width = max_text_w;
			
			//move the button
			ok_bt.x = int(lm.loc_vp_w/2 - ok_bt.width/2);
			ok_bt.y = int(lm.loc_vp_h - ok_bt.height - 30);
			
			//keep the giant centered
			giant_holder.x = int(is_side_shifting ? lm.loc_vp_w/2 - (text_holder.x + text_holder.width - art_w/2)/2 : lm.loc_vp_w/2);
			giant_holder.y = int(lm.loc_vp_h/2);
			
			//keep donation to... centered
			const max_donation_w:int = lm.loc_vp_w - TEXT_PADD*2;
			donation_holder.scaleX = donation_holder.scaleY = 1;
			if(donation_holder.width > max_donation_w){
				const donation_scale:Number = max_donation_w/donation_holder.width;
				donation_holder.scaleX = donation_holder.scaleY = donation_scale;
			}
			donation_holder.x = int(lm.loc_vp_w/2 - donation_holder.width/2);
			donation_holder.y = int(lm.loc_vp_h/2 - donation_holder.height/2);
			
			//make sure the tip is centered
			tip_body_tf.width = Math.min(MAX_TIP_BODY_W, lm.loc_vp_w - TEXT_PADD*4);
			tip_title_tf.x = int(tip_body_tf.width/2 - tip_title_tf.width/2);
			tip_holder.x = int(lm.loc_vp_w/2 - tip_holder.width/2);
			tip_holder.y = int(lm.loc_vp_h/2 - tip_holder.height/2);
			
			all_holder.x = lm.gutter_w;
			all_holder.y = lm.header_h;
		}
		
		override protected function animate():void {
			super.animate();
			
			//show the donation to message while the video loads
			TSTweener.removeTweens(donation_holder);
			donation_holder.alpha = 0;
			if(!start_with_tip){
				//only show the donation screen if we aren't starting with a tip
				TSTweener.addTween(donation_holder, {alpha:1, time:1.3, delay:fade_in_secs/2, transition:'linear'});
			}
			StageBeacon.setTimeout(onDonateTweenComplete, !start_with_tip ? 3000 : fade_in_secs); //little pause before showing the giant
		}
		
		private function onDonateTweenComplete():void {
			//check to make sure the FLV is all loaded up
			if(flv && flv.loaded){
				giant_holder.addChild(flv);
				flv.playFrom(0);
			}
			else if(is_waiting_for_flv){
				//looks like we are waiting, has it been the max yet?
				if(getTimer() - wait_time >= MAX_WAIT_MS){
					//aww man, can't see the video
					no_video_tf.visible = true;
					
					//maybe if it ever does load, we can pop'r in
					if(flv) flv.addEventListener(TSEvent.COMPLETE, onFLVComplete, false, 0, true);
				}
				else {
					//keep on trying!
					StageBeacon.setTimeout(onDonateTweenComplete, 100);
					return;
				}
			}
			else {
				StageBeacon.setTimeout(onDonateTweenComplete, 100);
				if(!is_waiting_for_flv){
					//looks like we are waiting, let's only allow a certain amount of time to load it
					is_waiting_for_flv = true;
					wait_time = getTimer();
				}
				return;
			}
			
			const art_w:int = flv && flv.art_w ? flv.art_w : no_video_tf.width;
			
			//place the text and do a draw call before the tween
			text_holder.x = int(art_w/2 + TEXT_OFFSET);
			text_mask.x = text_holder.x;
			draw();
			
			//fade out the donation to stuff
			TSTweener.addTween(donation_holder, {alpha:0, time:1.3, transition:'linear'});
			
			TSTweener.removeTweens(giant_holder);
			giant_holder.scaleX = giant_holder.scaleY = .2;
			giant_holder.alpha = 0;
			giant_holder.x = model.layoutModel.loc_vp_w/2;
			is_side_shifting = false;
			
			const ani_time:Number = 3;
			const ani_delay:Number = .4;
			
			TSTweener.addTween(giant_holder, 
				{
					scaleX:1, 
					scaleY:1, 
					time:ani_time,
					delay:ani_delay,
					transition:'easeOutBack',
					onStart:function():void {
						//bring up the alpha
						giant_holder.alpha = .2;
					},
					onUpdate:onTweenUpdate, 
					onComplete:onTweenComplete
				}
			);
			
			//we want the alpha on a different transition
			TSTweener.addTween(giant_holder, {alpha:1, time:ani_time, delay:ani_delay, transition:'easeInSine'});
		}
		
		private function onTweenUpdate():void {
			//keep this sucker in the center
			const lm:LayoutModel = model.layoutModel;
			giant_holder.x = int(lm.loc_vp_w/2);
			giant_holder.y = int(lm.loc_vp_h/2);
		}
		
		private function onTweenComplete():void {
			//slide it over to the side
			const art_w:int = flv && flv.art_w ? flv.art_w : no_video_tf.width;
			const lm:LayoutModel = model.layoutModel;
			const end_x:int = lm.loc_vp_w/2 - (text_holder.x + text_holder_w - art_w/2)/2;
			TSTweener.addTween(giant_holder, 
				{
					x:end_x, 
					time:1.5, 
					delay:3, 
					transition:'easeOutQuart',
					onStart:function():void {
						is_side_shifting = true;
					},
					onComplete:animateText
				}
			);
		}
		
		private function animateText():void {
			TSTweener.removeTweens(text_mask);
			
			text_mask.width = text_holder_w;
			
			//reveal the text in a fancy mask
			TSTweener.addTween(text_mask, {height:text_holder.height*2, time:2, transition:'linear', onComplete:onAnimateTextComplete});
		}
		
		private function onAnimateTextComplete():void {
			ready_for_input = true;
			
			//bring in the ok_bt
			TSTweener.addTween(ok_bt, {alpha:1, time:.5, transition:'linear'});
		}
		
		override protected function onAnimateComplete():void {
			//this blocks the ready_for_input
		}
		
		private function onTextLink(event:TextEvent):void {
			//this is just here to close this if they click on a link
			onOkClick(event);
		}
		
		override protected function onDoneTweenComplete():void {
			super.onDoneTweenComplete();
			
			//if we have an flv, go ahead and dispose of it
			if(flv) {
				flv.removeEventListener(TSEvent.COMPLETE, onFLVComplete);
				flv.dispose();
			}
			flv = null;
		}
		
		override protected function onOkClick(event:Event):void {
			//show the donation tip or close it up
			if(!ready_for_input) return;
			
			if(tip_holder.visible || start_with_tip){
				//do the regular close
				super.onOkClick(event);
			}
			else {
				const ani_time:Number = .3;
				TSTweener.addTween(giant_holder, {alpha:0, time:ani_time, transition:'linear'});
				tip_holder.visible = true;
				tip_holder.alpha = 0;
				TSTweener.addTween(tip_holder, {alpha:1, time:ani_time, transition:'linear'});
			}
		}
		
		private function onFLVComplete(event:TSEvent):void {
			//the video actually loaded!
			giant_holder.addChild(flv);
			flv.playFrom(0);
			no_video_tf.visible = false;
			draw();
		}
	}
}