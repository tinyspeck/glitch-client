package com.tinyspeck.engine.view.ui.imagination
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.skill.SkillDetails;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.SkillIcon;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class ImaginationSkillElementUI extends Sprite
	{
		public static const WIDTH:uint = 205;
		public static const BG_ALPHA:Number = .4;
		public static const BG_ALPHA_HOVER:Number = .6;
		public static const BG_ALPHA_DISABLED:Number = .2;
		
		private static const TITLE_ALPHA:Number = .8;
		private static const TIME_ALPHA:Number = .5;
		private static const ICON_DISABLED_ALPHA:Number = .7;
		private static const MAX_CHARS:uint = 22;
		private static const PADD:uint = 7;
		
		private static var glow_filterA:Array;
		private static var color_filterA:Array;
		
		private var icon_holder:Sprite = new Sprite();
		private var hit_area:Sprite = new Sprite();
		private var name_holder:Sprite = new Sprite();
		
		private var title_tf:TextField = new TextField();
		private var time_tf:TextField = new TextField();
		
		private var lock_icon:DisplayObject;
		
		private var icon:SkillIcon;
		private var current_details:SkillDetails;
		
		private var is_built:Boolean;
		
		public function ImaginationSkillElementUI(){}
		
		private function buildBase():void {
			//hit area for mouse stuff
			var g:Graphics = hit_area.graphics;
			g.beginFill(0);
			g.drawRoundRect(0, 0, WIDTH, SkillIcon.SIZE_DEFAULT + PADD*2, 10);
			hit_area.alpha = BG_ALPHA;
			addChild(hit_area);
			
			//icons
			icon_holder.x = icon_holder.y = PADD;
			addChild(icon_holder);
			
			//tfs
			TFUtil.prepTF(title_tf, false);
			title_tf.htmlText = '<p class="imagination_skill_element">placeholder</p>';
			name_holder.addChild(title_tf);
			
			TFUtil.prepTF(time_tf, false);
			time_tf.y = int(title_tf.y + title_tf.height - 4);
			time_tf.htmlText = '<p class="imagination_skill_element">200 badillion days</p>';
			name_holder.addChild(time_tf);
			
			name_holder.x = int(icon_holder.x + SkillIcon.SIZE_DEFAULT + PADD);
			name_holder.y = int(icon_holder.y + (SkillIcon.SIZE_DEFAULT/2 - name_holder.height/2) + 1);
			addChild(name_holder);
			
			//mouse stuff
			addEventListener(MouseEvent.ROLL_OVER, onRoll, false, 0, true);
			addEventListener(MouseEvent.ROLL_OUT, onRoll, false, 0, true);
			addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			
			useHandCursor = buttonMode = true;
			mouseChildren = false;
			
			//filters
			if(!glow_filterA){
				glow_filterA = StaticFilters.copyFilterArrayFromObject({blurX:5, blurY:5, strength:3, alpha:.9}, StaticFilters.blue2px_GlowA);
				color_filterA = [ColorUtil.getGreyScaleFilter()];
			}
			
			is_built = true;
		}
		
		public function show(skill_details:SkillDetails):void {
			if(!is_built) buildBase();
			current_details = skill_details;
			
			//stale icon?
			if(icon_holder.name != skill_details.class_tsid){
				SpriteUtil.clean(icon_holder);
				icon = new SkillIcon(skill_details.class_tsid);
				icon_holder.addChild(icon);
				icon_holder.name = skill_details.class_tsid;
			}
			
			//DEBUG
			if(!skill_details.seconds){
				skill_details.seconds = 12345;
			}
			
			//set the values
			setText();
			
			//show the text
			onRoll();
		}
		
		private function setText():void {
			//show the skill text
			var title_txt:String = StringUtil.truncate(current_details.name, MAX_CHARS);
			var time_txt:String = StringUtil.formatTime(current_details.seconds, true, true, 2);
			
			//if we can't learn this skill, say so!
			if(!current_details.can_learn){
				time_txt = 'Can\'t learn';
				if(!lock_icon){
					lock_icon = new AssetManager.instance.assets.lock_small();
					lock_icon.x = icon_holder.x + SkillIcon.SIZE_DEFAULT - lock_icon.width + 4;
					lock_icon.y = icon_holder.y + SkillIcon.SIZE_DEFAULT - lock_icon.height + 7;
				}
				addChild(lock_icon);
			}
			else if(lock_icon && lock_icon.parent){
				//make sure we're not showing the lock
				lock_icon.parent.removeChild(lock_icon);
			}
			
			title_tf.htmlText = '<p class="imagination_skill_element">'+title_txt+'</p>';
			time_tf.htmlText = '<p class="imagination_skill_element">'+time_txt+'</p>';
		}
		
		private function onRoll(event:MouseEvent = null):void {
			const is_over:Boolean = event && event.type == MouseEvent.ROLL_OVER;
			var title_alpha:Number = is_over ? 1 : TITLE_ALPHA;
			var time_alpha:Number = is_over ? 1 : TIME_ALPHA;
			var bg_alpha:Number = is_over ? BG_ALPHA_HOVER : BG_ALPHA;
			icon_holder.filters = is_over ? glow_filterA : null;
			icon_holder.alpha = 1;
			
			//if we can't learn this skill, then some values are different
			if(!current_details.can_learn){
				title_alpha = TIME_ALPHA;
				time_alpha = is_over ? TITLE_ALPHA : TIME_ALPHA;
				bg_alpha = is_over ? BG_ALPHA_HOVER : BG_ALPHA_DISABLED;
				icon_holder.filters = color_filterA;
				icon_holder.alpha = is_over ? 1 : ICON_DISABLED_ALPHA;
			}
			
			title_tf.alpha = title_alpha;
			time_tf.alpha = time_alpha;
			hit_area.alpha = bg_alpha;
		}
		
		private function onClick(event:MouseEvent):void {
			//show the skill info dialog if we can't learn this, otherwise show the details in the cloud
			if(current_details && current_details.can_learn){
				ImaginationSkillsUI.instance.showSkillDetails(current_details);
			}
			else {
				TSFrontController.instance.showSkillInfo(icon_holder.name);
				SoundMaster.instance.playSound('CLICK_SUCCESS');
			}
		}
	}
}