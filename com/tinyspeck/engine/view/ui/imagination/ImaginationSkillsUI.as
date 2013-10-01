package com.tinyspeck.engine.view.ui.imagination
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCSkill;
	import com.tinyspeck.engine.data.skill.SkillDetails;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingSkillUnlearnCancelVO;
	import com.tinyspeck.engine.net.NetOutgoingSkillsCanLearnVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.port.SkillManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.ImgMenuView;
	import com.tinyspeck.engine.view.gameoverlay.ProgressBar;
	import com.tinyspeck.engine.view.ui.Cloud;
	import com.tinyspeck.engine.view.ui.SkillIcon;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.TSScroller;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.ui.Keyboard;

	public class ImaginationSkillsUI extends TSSpriteWithModel implements IRefreshListener
	{
		/* singleton boilerplate */
		public static const instance:ImaginationSkillsUI = new ImaginationSkillsUI();
		
		private static const BAR_W:uint = 9;
		private static const SCROLL_MATRIX:Matrix = new Matrix();
		private static const TIME_ALPHA:Number = .8;
		private static const NAME_ALPHA:Number = .7;
		private static const SELECT_ALPHA:Number = .8;
		private static const FADE_HEIGHT:uint = 50;
		private static const GRAD_COLORS:Array = [0,0];
		private static const GRAD_RATIOS:Array = [0,255];
		private static const GRAD_ALPHAS:Array = [0,1];
		private static const PROGRESS_MAX_W:uint = 630;
		private static const PROGRESS_PADD:uint = 50;
		private static const ARROW_W:uint = 17;
		private static const ARROW_H:uint = 25;
		private static const ARROW_PADD:uint = 7;
		private static const TOP_PADD:int = 40;
		private static const BOTTOM_PADD:int = 35;
		private static const MAX_TO_SHOW:int = 11;
		
		private var elements:Vector.<ImaginationSkillElementUI> = new Vector.<ImaginationSkillElementUI>();
		private var scroller:TSScroller;
		private var progress_bar:ProgressBar = new ProgressBar();
		private var cloud:Cloud = new Cloud(Cloud.TYPE_SKILLS_LARGE);
		private var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
		private var current_skill:PCSkill;
		private var details_ui:ImaginationSkillDetailsUI = new ImaginationSkillDetailsUI();
		
		private var scroll_mask:Sprite = new Sprite();
		private var progress_holder:Sprite = new Sprite();
		private var masker:Sprite = new Sprite();
		private var arrows:Sprite = new Sprite();
		private var arrows_mask:Sprite = new Sprite();
		private var element_holder:Sprite = new Sprite();
		private var skills_holder:Sprite = new Sprite();
		private var more_holder:Sprite = new Sprite();
		
		private var title_tf:TextField = new TextField();
		private var time_tf:TextField = new TextField();
		private var name_tf:TSLinkedTextField = new TSLinkedTextField();
		private var select_skill_tf:TextField = new TextField();
		private var cancel_tf:TSLinkedTextField = new TSLinkedTextField();
		private var more_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var draw_timer_int:int = -1;
		
		private var learn_pb_top:uint;
		private var learn_pb_bottom:uint;
		private var learn_pb_tip_top:uint;
		private var learn_pb_tip_bottom:uint;
		private var learn_fast_pb_top:uint;
		private var learn_fast_pb_bottom:uint;
		private var learn_fast_pb_tip_top:uint;
		private var learn_fast_pb_tip_bottom:uint;
		private var unlearn_pb_top:uint;
		private var unlearn_pb_bottom:uint;
		private var unlearn_pb_tip_top:uint;
		private var unlearn_pb_tip_bottom:uint;
		private var more_w:int;
		private var more_h:int = SkillIcon.SIZE_DEFAULT + 14;
		
		private var is_built:Boolean;
		private var _is_hiding:Boolean;
		
		public function ImaginationSkillsUI(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		private function buildBase():void {			
			const cssm:CSSManager = CSSManager.instance;
			
			//progress bar
			progress_bar.width = PROGRESS_MAX_W;
			progress_bar.height = 45;
			progress_bar.update(.5);
			progress_bar.setFrameColors(0xcfd0d0, 0xb6b7b7);
			progress_bar.corner_size = 10;
			progress_bar.filters = StaticFilters.copyFilterArrayFromObject({blurX:8, blurY:8, strength:20, alpha:.2}, StaticFilters.white4px40AlphaGlowA);
			progress_holder.addChild(progress_bar);
			
			//tf
			TFUtil.prepTF(title_tf);
			title_tf.htmlText = '<p class="imagination_skills_title">Skills</p>';
			title_tf.width = progress_bar.width;
			title_tf.filters = StaticFilters.copyFilterArrayFromObject({alpha:.5, distance:2}, StaticFilters.black7px90Degrees_DropShadowA);
			addChild(title_tf);
			
			TFUtil.prepTF(time_tf);
			time_tf.width = progress_bar.width;
			time_tf.y = int(progress_bar.height + 10);
			time_tf.htmlText = '<p class="imagination_skills_time">3 days 15 hours 25 mins 31 secs</p>';
			time_tf.alpha = TIME_ALPHA;
			progress_holder.addChild(time_tf);
			
			TFUtil.prepTF(name_tf, true, {color:cssm.getStringValueFromStyle('imagination_skills_name_link', 'hoverColor', '#545454')});
			name_tf.width = progress_bar.width;
			name_tf.htmlText = '<p class="imagination_skills_name">Learning <b>Mining III</b></p>';
			name_tf.y = int(progress_bar.height/2 - name_tf.height/2 + 1);
			name_tf.alpha = NAME_ALPHA;
			progress_holder.addChild(name_tf);
			
			TFUtil.prepTF(cancel_tf, false, {color:cssm.getStringValueFromStyle('imagination_skills_cancel', 'hoverColor', '#044051')});
			cancel_tf.htmlText = '<p class="imagination_skills_title"><a class="imagination_skills_cancel" href="event:fam_skill_cancel">Cancel</a></p>';
			cancel_tf.filters = StaticFilters.copyFilterArrayFromObject({alpha:.5}, StaticFilters.white1px90Degrees_DropShadowA);
			cancel_tf.y = int(progress_bar.height/2 - cancel_tf.height/2 + 2);
			cancel_tf.addEventListener(TextEvent.LINK, onUnlearningCancelClick, false, 0, true);
			progress_holder.addChild(cancel_tf);
			
			progress_holder.y = int(title_tf.y + title_tf.height + 10);
			skills_holder.addChild(progress_holder);
			
			TFUtil.prepTF(select_skill_tf);
			select_skill_tf.width = progress_bar.width;
			select_skill_tf.htmlText = '<p class="imagination_skills_title"><span class="imagination_skills_select">Select a skill...</span></p>';
			select_skill_tf.y = int(progress_holder.y + progress_bar.height - select_skill_tf.height/2 - 5);
			select_skill_tf.alpha = SELECT_ALPHA;
			skills_holder.addChild(select_skill_tf);
			
			//scroller
			scroller = new TSScroller({
				name: 'scroller',
				bar_wh: BAR_W,
				bar_color: 0xffffff,
				bar_alpha: .3,
				//bar_padd_top: 30,
				//bar_padd_bottom: 30,
				bar_handle_color: 0xffffff,
				bar_handle_stripes_alpha: 0,
				bar_handle_min_h: 50
			});
			scroller.y = int(progress_holder.y + progress_holder.height);
			scroller.h = TSModelLocator.instance.layoutModel.loc_vp_h - scroller.y - 40;
			skills_holder.addChild(scroller);
			
			scroll_mask.cacheAsBitmap = true;
			scroller.addChild(scroll_mask);
			scroller.body_mask = scroll_mask;
			element_holder.y = FADE_HEIGHT - 20;
			scroller.body.addChild(element_holder);
			
			//bg cloud
			cloud.alpha = .5;
			cloud.y = int(title_tf.y + title_tf.height - FADE_HEIGHT);
			addChildAt(cloud, 0);
			
			addChild(skills_holder);
			
			//mask
			mask = masker;
			addChild(masker);
			
			//css values for the progress bar colors
			learn_pb_top = cssm.getUintColorValueFromStyle('imagination_skills_learn_pb', 'topColor', 0xafca2f);
			learn_pb_bottom = cssm.getUintColorValueFromStyle('imagination_skills_learn_pb', 'bottomColor', 0x95b101);
			learn_pb_tip_top = cssm.getUintColorValueFromStyle('imagination_skills_learn_pb', 'tipTopColor', 0x9db52e);
			learn_pb_tip_bottom = cssm.getUintColorValueFromStyle('imagination_skills_learn_pb', 'tipBottomColor', 0x879f08);
			learn_fast_pb_top = cssm.getUintColorValueFromStyle('imagination_skills_fast_pb', 'topColor', 0xf5e242);
			learn_fast_pb_bottom = cssm.getUintColorValueFromStyle('imagination_skills_fast_pb', 'bottomColor', 0xd79305);
			learn_fast_pb_tip_top = cssm.getUintColorValueFromStyle('imagination_skills_fast_pb', 'tipTopColor', 0xb38b00);
			learn_fast_pb_tip_bottom = cssm.getUintColorValueFromStyle('imagination_skills_fast_pb', 'tipBottomColor', 0x9a7802);
			unlearn_pb_top = cssm.getUintColorValueFromStyle('imagination_skills_unlearn_pb', 'topColor', 0x75c1c2);
			unlearn_pb_bottom = cssm.getUintColorValueFromStyle('imagination_skills_unlearn_pb', 'bottomColor', 0x42a5a8);
			unlearn_pb_tip_top = cssm.getUintColorValueFromStyle('imagination_skills_unlearn_pb', 'tipTopColor', 0x4d9899);
			unlearn_pb_tip_bottom = cssm.getUintColorValueFromStyle('imagination_skills_unlearn_pb', 'tipBottomColor', 0x4e989a);
			
			//build the fast arrows
			buildArrows();
			arrows.mask = arrows_mask;
			progress_holder.addChildAt(arrows, progress_holder.getChildIndex(name_tf));
			progress_holder.addChild(arrows_mask);
			
			//cancel unlearning confirmation
			cdVO.escape_value = false;
			cdVO.title = 'Cancel Unlearning?';
			cdVO.choices = [
				{value: true, label: 'Yes, cancel unlearning'},
				{value: false, label: 'Nevermind!'}
			];
			cdVO.escape_value = false;
			cdVO.callback = onUnlearningCancelConfirm;
			
			//more skills
			TFUtil.prepTF(more_tf);
			more_holder.buttonMode = more_holder.useHandCursor = true;
			more_holder.addEventListener(MouseEvent.CLICK, onMoreClick, false, 0, true);
			more_holder.addEventListener(MouseEvent.ROLL_OVER, onMoreMouse, false, 0, true);
			more_holder.addEventListener(MouseEvent.ROLL_OUT, onMoreMouse, false, 0, true);
			more_holder.mouseChildren = false;
			more_holder.addChild(more_tf);
			
			is_built = true;
		}
		
		private function buildArrows():void {
			var next_x:int;
			
			SCROLL_MATRIX.createGradientBox(
				PROGRESS_MAX_W + ARROW_PADD + ARROW_W, 
				ARROW_H, 
				Math.PI/2, //vertical grad
				0, 
				0
			);
			const g:Graphics = arrows.graphics;
			g.beginGradientFill(GradientType.LINEAR, [0xf6e571, 0xedcb35], [1,1], [0,255], SCROLL_MATRIX);
			while(arrows.width < PROGRESS_MAX_W + ARROW_PADD + ARROW_W){
				g.moveTo(next_x, 0);
				g.lineTo(next_x, ARROW_H);
				g.lineTo(next_x + ARROW_W, ARROW_H/2);
				g.lineTo(next_x, 0);
				
				next_x += ARROW_W + ARROW_PADD;
			}
			arrows.y = int(progress_bar.height/2 - ARROW_H/2);
			arrows.cacheAsBitmap = true;
		}
		
		public function show(skills:Vector.<SkillDetails> = null):void {
			if(!is_built) buildBase();
			
			//go ask the server nicely if we don't have any
			arrows.visible = false;
			animateArrows(true);
			if(skills) showSkills(skills);
			
			//reset
			details_ui.hide();
			skills_holder.alpha = 1;
			skills_holder.visible = true;
			scroller.scrollUpToTop();
			_is_hiding = false;
			
			//toss it on the stage
			TSFrontController.instance.getMainView().addView(this, true);
			TSFrontController.instance.registerRefreshListener(this);
			
			//fade in
			alpha = 0;
			TSTweener.addTween(this, {alpha:1, time:.2, transition:'linear'});
			
			//see if we are already learning
			SkillManager.instance.addEventListener(TSEvent.CHANGED, onSkillChange, false, 0, true);
			onSkillChange(); //will also ask the server for the latest if it needs to
			
			//start drawing
			draw_timer_int = StageBeacon.setInterval(draw, 10);
			
			//listen to the shortcut to close it
			KeyBeacon.instance.addEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.S, onKeys, false, 0, true);
			
			refresh();
		}
		
		public function hide():void {
			SkillManager.instance.removeEventListener(TSEvent.CHANGED, onSkillChange);
			
			KeyBeacon.instance.removeEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.S, onKeys);
			
			//fade out
			_is_hiding = true;
			const self:ImaginationSkillsUI = this;
			TSTweener.addTween(this, {alpha:0, time:.2, transition:'linear', 
				onComplete:function():void {
					if(self.parent) self.parent.removeChild(self);
					if(draw_timer_int > 0) StageBeacon.clearInterval(draw_timer_int);
					draw_timer_int = 0;
					TSFrontController.instance.unRegisterRefreshListener(self);
					_is_hiding = false;
				}
			});
		}
		
		public function refresh():void {
			if(!parent) return;
			if(!cloud.is_loaded){
				//refresh until our cloud is loaded (probably never gets called, but to be safe)
				StageBeacon.setTimeout(refresh, 300);
				return;
			}
			const lm:LayoutModel = TSModelLocator.instance.layoutModel;
			const progress_w:int = Math.min(PROGRESS_MAX_W, int(lm.loc_vp_w - PROGRESS_PADD*2));
			
			//scroller
			scroller.wh = {w:progress_w + 20, h:lm.loc_vp_h - scroller.y - TOP_PADD - BOTTOM_PADD};
			const scroll_h:int = Math.min(scroller.h, scroller.body_h);
			
			//set the x/widths
			progress_bar.width = progress_w;
			time_tf.width = progress_w;
			name_tf.width = progress_w;
			progress_holder.x = int(scroller.w/2 - progress_w/2);
			
			title_tf.width = progress_w;
			title_tf.x = progress_holder.x;
			
			select_skill_tf.width = progress_w;
			select_skill_tf.x = progress_holder.x;
			
			cancel_tf.x = int(progress_w - cancel_tf.width - 16);
			
			//center the cloud
			cloud.x = int(progress_holder.x + (progress_w/2 - cloud.width/2));
			
			//draw the mask
			var g:Graphics = masker.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRoundRectComplex(0, 0, lm.loc_vp_w, lm.loc_vp_h, lm.loc_vp_elipse_radius, 0, lm.loc_vp_elipse_radius, 0);
			
			//draw the arrows mask
			drawArrowsMask();
			
			//make sure they all fit in there still
			showSkills(model.worldModel.learnable_skills);
			
			if(details_ui.parent){
				details_ui.refresh();
				details_ui.x = int(scroller.w/2 - details_ui.width/2);
				details_ui.y = Math.max(60, int(lm.loc_vp_h/2 - details_ui.height/2));
			}
			
			x = lm.gutter_w + int(lm.loc_vp_w/2 - scroller.w/2);
			y = lm.header_h + TOP_PADD;
			
			masker.x = -x + lm.gutter_w;
			masker.y = -y + lm.header_h;
		}
		
		public function showSkillDetails(skill_details:SkillDetails):void {
			if(TSTweener.isTweening(details_ui)) return;
			
			//show a nice fancy detail thingie
			details_ui.show(skill_details);
			addChild(details_ui);
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			//cross fade
			const ani_time:Number = .3;
			TSTweener.removeTweens([skills_holder, details_ui]);
			details_ui.alpha = 0;
			TSTweener.addTween(details_ui, {alpha:1, time:ani_time, transition:'linear'});
			TSTweener.addTween(skills_holder, {_autoAlpha:0, time:ani_time, transition:'linear'});
			
			refresh();
		}
		
		public function hideSkillDetails():void {
			const ani_time:Number = .3;
			details_ui.hide(true, ani_time);
			TSTweener.addTween(skills_holder, {_autoAlpha:1, time:ani_time, transition:'linear'});
		}
		
		private function updateSkillTraining():void {
			//decide what to show
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			current_skill = pc.skill_training != null ? pc.skill_training : pc.skill_unlearning;
			
			if(current_skill){
				const secs_left:int = SkillManager.instance.skill_remaining_secs;
				const perc:Number = ((current_skill.total_time-secs_left)/current_skill.total_time);
				progress_bar.update(perc);
				const skill_name:String = '<a class="imagination_skills_name_link" href="event:'+TSLinkedTextField.LINK_SKILL+'|'+current_skill.tsid+'">'+
										  current_skill.name+'</a>';
				
				//set the time text
				var time_txt:String = secs_left > 0 ? StringUtil.formatTime(secs_left) : 'any second now!';
				
				if(pc.skill_training){
					name_tf.htmlText = '<p class="imagination_skills_name">Learning '+skill_name+'</p>';
					progress_bar.direction = ProgressBar.DIRECTION_LEFT_TO_RIGHT;
					
					if(!pc.skill_training.is_accelerated){
						//regular colors
						progress_bar.setBarColors(learn_pb_top, learn_pb_bottom, learn_pb_tip_top, learn_pb_tip_bottom);
						
						if(arrows.visible){
							//stop refreshing
							arrows.visible = false;
							animateArrows(true);
						}
					}
					else {
						//show the super speed
						progress_bar.setBarColors(learn_fast_pb_top, learn_fast_pb_bottom, learn_fast_pb_tip_top, learn_fast_pb_tip_bottom);
						
						//animate if not already
						if(!arrows.visible){
							arrows.visible = true;
							animateArrows(false);
						}
						
						//time needs to wrap in the fast class
						time_txt = '<span class="imagination_skills_time_fast">'+time_txt+'</span>';
						
						//draw the arrow mask
						drawArrowsMask();
					}
				}
				else if(pc.skill_unlearning){
					name_tf.htmlText = '<p class="imagination_skills_name">Unlearning '+skill_name+'</p>';
					progress_bar.direction = ProgressBar.DIRECTION_RIGHT_TO_LEFT;
					progress_bar.setBarColors(unlearn_pb_top, unlearn_pb_bottom, unlearn_pb_tip_top, unlearn_pb_tip_bottom);
				}
				
				//set the time text
				time_tf.htmlText = '<p class="imagination_skills_time">'+time_txt+'</p>';
			}
			else {
				//stop refreshing
				arrows.visible = false;
				animateArrows(true);
			}
			
			select_skill_tf.visible = current_skill == null;
			progress_holder.visible = !select_skill_tf.visible;
			cancel_tf.visible = current_skill == pc.skill_unlearning;
		}
		
		private function draw(event:Event = null):void {
			const draw_w:int = scroller.w - BAR_W;
			const scroll_h:int = scroller.h;
			SCROLL_MATRIX.createGradientBox(
				draw_w, 
				FADE_HEIGHT, 
				Math.PI/2, //vertical grad
				0, 
				0
			);
			
			const g:Graphics = scroll_mask.graphics;
			g.clear();
			GRAD_ALPHAS[0] = 0;
			GRAD_ALPHAS[1] = 1;
			g.beginGradientFill(GradientType.LINEAR, GRAD_COLORS, GRAD_ALPHAS, GRAD_RATIOS, SCROLL_MATRIX);
			g.drawRect(0, 0, draw_w, FADE_HEIGHT);
			
			SCROLL_MATRIX.createGradientBox(
				draw_w, 
				FADE_HEIGHT, 
				Math.PI/2, //vertical grad
				0, 
				scroll_h - FADE_HEIGHT
			);
			
			GRAD_ALPHAS[0] = 1;
			GRAD_ALPHAS[1] = 0;
			g.beginGradientFill(GradientType.LINEAR, GRAD_COLORS, GRAD_ALPHAS, GRAD_RATIOS, SCROLL_MATRIX);
			g.drawRect(0, scroll_h - FADE_HEIGHT, draw_w, FADE_HEIGHT);
			g.beginFill(0);
			g.drawRect(0, FADE_HEIGHT, draw_w, scroll_h - FADE_HEIGHT*2);
		}
		
		private function drawArrowsMask():void {
			const g:Graphics = arrows_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRoundRect(0, 0, progress_bar.bar_w, progress_bar.height, progress_bar.corner_size);
		}
		
		private function animateArrows(is_stop:Boolean):void {
			//handle the animation of the arrows
			if(is_stop){
				TSTweener.removeTweens(arrows);
			}
			else {
				arrows.x = -ARROW_W-ARROW_PADD;
				TSTweener.addTween(arrows, {x:0, time:.4, transition:'linear', onComplete:animateArrows, onCompleteParams:[false]});
			}
		}
		
		public function getSkillsFromServer(callback:Function = null):void {
			if(callback == null) callback = onSkillsCanLearn;
			
			//get the latest and greatest
			TSFrontController.instance.genericSend(new NetOutgoingSkillsCanLearnVO(), callback, callback);
		}
		
		private function showSkills(skills:Vector.<SkillDetails>):void {
			const x_padd:uint = 7;
			const y_padd:uint = 12;
			const max_w:int = ImaginationSkillElementUI.WIDTH*3 + x_padd*2;
			const skill_training:PCSkill = model.worldModel.pc ? model.worldModel.pc.skill_training : null;
			var skill_details:SkillDetails;
			var i:int;
			var total:int = elements.length;
			var element:ImaginationSkillElementUI;
			var g:Graphics;
			var next_x:int;
			var next_y:int;
			var skipped_training_skill:Boolean;
			
			//reset
			if(more_holder.parent) more_holder.parent.removeChild(more_holder);
			for(i = 0; i < total; i++){
				element = elements[int(i)];
				element.x = element.y = 0;
				element.visible = false;
			}
			
			//show them
			total = skills.length;
			for(i = 0; i < total; i++){
				skill_details = skills[int(i)];
				
				//if this is our first unlearnable skill AND we have gone past the max to show, then break out
				if(!skill_details.can_learn && i >= MAX_TO_SHOW){
					break;
				}
				
				//if we are learning this skill, skip it
				if(skill_training && skill_training.tsid == skill_details.class_tsid){
					skipped_training_skill = true;
					continue;
				}
				
				if(elements.length > i){
					element = elements[int(i)];
				}
				else {
					element = new ImaginationSkillElementUI();
					elements.push(element);
					element_holder.addChild(element);
				}
				
				element.show(skill_details);
				element.visible = true;
				
				//we need to reset the X?
				if(next_x + element.width > scroller.w - BAR_W - x_padd){
					next_x = 0;
					next_y += element.height + y_padd;
				}
				
				element.x = next_x;
				element.y = next_y;
				next_x += element.width + x_padd;
			}
			
			//put on the more button if we need it
			if(total && next_y){
				//if the min width is gonna put us over, throw it on a new line
				if(next_x + ImaginationSkillElementUI.WIDTH > scroller.w - BAR_W - x_padd){
					next_x = 0;
					next_y += more_h + y_padd;
				}
				
				more_w = max_w;
				while(next_x + more_w > scroller.w - BAR_W - x_padd){
					//knock it down a peg
					more_w -= ImaginationSkillElementUI.WIDTH + x_padd;
				}
				more_w = Math.max(more_w, ImaginationSkillElementUI.WIDTH);
				
				//if we skipped the current learning skill, take the total down by one
				if(skipped_training_skill) total--;
				
				var more_txt:String = '<p class="imagination_skills_more">';
				more_txt += i < total ? '...And '+(total-i)+' More.' : 'See all skills in';
				more_txt += more_w != ImaginationSkillElementUI.WIDTH ? ' ' : '<br>';
				more_txt += '<span class="imagination_skills_more_link">';
				more_txt +=	i < total ? 'See full skill table' : 'the full skill table'
				more_txt += '</span>';
				more_txt += '</p>';
				more_tf.htmlText = more_txt;
				more_tf.width = more_w;
				more_tf.y = int(more_h/2 - more_tf.height/2);
				onMoreMouse();
				
				more_holder.x = next_x;
				more_holder.y = next_y;
				element_holder.addChild(more_holder);
			}
			
			//place the element holder
			element_holder.x = int(scroller.w/2 - element_holder.width/2);
			
			//add a little padding
			g = element_holder.graphics;
			g.clear();
			g.beginFill(0,0);
			g.drawRect(0, element_holder.height + 15, 10, 10);
			
			scroller.refreshAfterBodySizeChange();
		}
		
		private function onSkillsCanLearn(nrm:NetResponseMessageVO):void {
			//toss the icons on the cloud
			if (nrm.success && is_built) {
				//show them
				showSkills(model.worldModel.learnable_skills);
				scroller.refreshAfterBodySizeChange(true);
				refresh();
			}
		}
		
		private function onSkillChange(event:TSEvent = null):void {
			//do we need to go get new skills?
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			const sk:PCSkill = pc.skill_training != null ? pc.skill_training : pc.skill_unlearning;
			
			if((sk && !current_skill) || (!sk && current_skill) || (!sk && !current_skill)){
				//need a fresh batch
				getSkillsFromServer();
			}
			
			updateSkillTraining();
		}
		
		private function onUnlearningCancelClick(event:TextEvent):void {
			//they clicked the cancel button, confirm this is what they wanted to do
			const skill:PCSkill = TSModelLocator.instance.worldModel.pc.skill_unlearning;
			if(skill){
				cdVO.txt = 'Are you sure you\'d like to cancel unlearning <b>'+skill.name+'</b>? Your unlearning progress will not be saved!';
				TSFrontController.instance.confirm(cdVO);
			}
		}
		
		private function onUnlearningCancelConfirm(value:Boolean):void {
			if(value){
				TSFrontController.instance.genericSend(new NetOutgoingSkillUnlearnCancelVO());
			}
		}
		
		private function onKeys(event:KeyboardEvent):void {
			//close the imagination menu
			ImgMenuView.instance.hide();
		}
		
		private function onMoreMouse(event:MouseEvent = null):void {
			const is_over:Boolean = event && event.type == MouseEvent.ROLL_OVER;
			const g:Graphics = more_holder.graphics;
			g.clear();
			g.beginFill(0, is_over ? ImaginationSkillElementUI.BG_ALPHA_HOVER : ImaginationSkillElementUI.BG_ALPHA_DISABLED);
			g.drawRoundRect(0, 0, more_w, more_h, 10);
		}
		
		private function onMoreClick(event:Event):void {
			//open up the skills page
			TSFrontController.instance.openSkillsPage();
		}
		
		public function get is_showing_details():Boolean {
			return details_ui.parent && !details_ui.is_hiding ? true : false;
		}
		
		public function get is_hiding():Boolean { return _is_hiding; }
	}
}