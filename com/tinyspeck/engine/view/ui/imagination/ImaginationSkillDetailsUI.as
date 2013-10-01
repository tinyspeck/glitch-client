package com.tinyspeck.engine.view.ui.imagination
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.api.APICall;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCSkill;
	import com.tinyspeck.engine.data.skill.SkillDetails;
	import com.tinyspeck.engine.data.skill.SkillGiant;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.SkillIcon;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class ImaginationSkillDetailsUI extends Sprite
	{
		private static const TEXT_X:uint = 160;
		private static const ICON_WH:uint = 128;
		private static const TEXT_MAX_W:uint = 450;
		
		private var text_holder:Sprite = new Sprite();
		private var left_holder:Sprite = new Sprite();
		private var time_holder:Sprite = new Sprite();
		
		private var name_tf:TextField = new TextField();
		private var body_tf:TextField = new TextField();
		private var giant_body_tf:TextField = new TextField();
		private var time_tf:TextField = new TextField();
		
		private var current_details:SkillDetails;
		private var back_bt:Button;
		private var learn_bt:Button;
		private var skill_icon:SkillIcon;
		private var api_call:APICall;
		private var cdVO:ConfirmationDialogVO;
		
		private var text_shadowA:Array;
		
		private var is_built:Boolean;
		private var _is_hiding:Boolean;
		
		public function ImaginationSkillDetailsUI(){}
		
		private function buildBase():void {
			text_shadowA = StaticFilters.copyFilterArrayFromObject({alpha:.35}, StaticFilters.black3px90Degrees_DropShadowA);
			
			//left side
			time_holder.filters = StaticFilters.copyFilterArrayFromObject(
				{alpha:1, inner:true, blurX:0, blurY:3, knockout:true}, 
				StaticFilters.black3px90Degrees_DropShadowA);
			left_holder.addChild(time_holder);
			
			TFUtil.prepTF(time_tf);
			time_tf.y = 6;
			time_tf.width = ICON_WH;
			time_tf.cacheAsBitmap = true; //stops the jiggles
			left_holder.addChild(time_tf);
			
			const arrow_DO:DisplayObject = new AssetManager.instance.assets.white_arrow();
			const arrow_holder:Sprite = new Sprite();
			SpriteUtil.setRegistrationPoint(arrow_DO);
			arrow_holder.addChild(arrow_DO);
			arrow_holder.rotation = 180;
			
			back_bt = new Button({
				name: 'back',
				label: 'Back to Skills',
				label_c: 0xffffff,
				label_face: 'VAGRoundedBoldEmbed',
				label_size: 16,
				text_align: 'left',
				graphic: arrow_holder,
				graphic_placement: 'left',
				graphic_padd_t: 13,
				draw_alpha: 0
			});
			back_bt.x = 8;
			back_bt.y = 4;
			back_bt.filters = text_shadowA;
			back_bt.addEventListener(TSEvent.CHANGED, onBackClick, false, 0, true);
			left_holder.addChild(back_bt);
			
			addChild(left_holder);
			
			//tfs
			TFUtil.prepTF(name_tf, false);
			text_holder.addChild(name_tf);
			
			TFUtil.prepTF(body_tf);
			text_holder.addChild(body_tf);
			
			TFUtil.prepTF(giant_body_tf);
			text_holder.addChild(giant_body_tf);
			
			learn_bt = new Button({
				name: 'learn',
				label: 'Start learning this skill',
				type: Button.TYPE_DEFAULT,
				size: Button.SIZE_DEFAULT
			});
			learn_bt.addEventListener(TSEvent.CHANGED, onLearnClick, false, 0, true);
			text_holder.addChild(learn_bt);
			
			text_holder.x = TEXT_X;
			text_holder.filters = text_shadowA;
			addChild(text_holder);
			
			//api call for learning the skill
			api_call = new APICall();
			api_call.addEventListener(TSEvent.COMPLETE, onAPIComplete, false, 0, true);
			api_call.addEventListener(TSEvent.ERROR, onAPIError, false, 0, true);
			
			is_built = true;
		}
		
		public function show(details:SkillDetails):void {
			if(!details) {
				CONFIG::debugging {
					Console.warn('Y U NO PASS DETAILS?!??!');
				}
				return;
			}
			
			if(!is_built) buildBase();
			current_details = details;
			back_bt.disabled = false;
			_is_hiding = false;
			
			setIcon();
			setText();
			setLearnButton();
			
			refresh();
		}
		
		public function hide(and_fade:Boolean = false, fade_time:Number = .3):void {
			if(and_fade){
				_is_hiding = true;
				TSTweener.addTween(this, {alpha:0, time:fade_time, transition:'linear', onComplete:onHideComplete});
			}
			else {
				onHideComplete();
			}
		}
		
		public function refresh():void {			
			const lm:LayoutModel = TSModelLocator.instance.layoutModel;
			const max_tf_w:int = Math.min(TEXT_MAX_W, lm.loc_vp_w - TEXT_X - 45);
			
			body_tf.y = int(name_tf.height);
			body_tf.width = max_tf_w;
			giant_body_tf.y = int(body_tf.y + body_tf.height + 11);
			giant_body_tf.width = max_tf_w;
			learn_bt.y = int(giant_body_tf.y + giant_body_tf.height + 15);
			
			//x = int(lm.loc_vp_w/2 - width/2);
		}
		
		private function setIcon():void {
			//handle all the left side things here
			if(skill_icon && skill_icon.name == current_details.class_tsid){
				//nuffin'
			}
			else {
				//kill it and make a new one
				if(skill_icon && skill_icon.parent) skill_icon.parent.removeChild(skill_icon);
				skill_icon = new SkillIcon(current_details.class_tsid, ICON_WH);
				skill_icon.y = 40;
				skill_icon.filters = text_shadowA;
				left_holder.addChild(skill_icon);
			}
			
			//set the time
			const time_padd:uint = 6;
			const time_y:int = skill_icon.y + ICON_WH + 10;
			time_tf.htmlText = '<p class="imagination_skill_details_time">'+StringUtil.formatTime(current_details.seconds, true, true, 2) +
							   '<br><span class="imagination_skill_details">To Learn</span></p>';
			time_tf.y = time_y + time_padd;
			var g:Graphics = time_holder.graphics;
			g.clear();
			g.beginFill(0, .25);
			g.drawRoundRect(0, 0, ICON_WH, int(time_padd*2 + time_tf.height), 10);
			time_holder.y = time_y;
		}
		
		private function setLearnButton():void {
			if(!is_built || !current_details) return;
			
			const loc:Location = TSModelLocator.instance.worldModel.location;
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			const skill_training:PCSkill = pc ? pc.skill_training : null;
			var txt:String;
			var label_txt:String = 'Start learning this skill';
			learn_bt.disabled = false;
			learn_bt.value = null;
			
			if(current_details.learning && !current_details.paused){
				txt = 'You\'re already learning this skill!';
				learn_bt.disabled = true;
			}
			else if(current_details.got){
				//defensive check, should never have this state
				txt = 'You already know this skill!';
				learn_bt.disabled = true;
			}
			else if(skill_training){
				//they are already learning something, let them know they will be pausing it (or even losing the speed)
				label_txt = 'Switch to '+(current_details.learning && current_details.paused ? 'resume' : 'start')+' learning this instead';
				if(skill_training.is_accelerated){
					txt = 'You\'re learning at an accelerated rate.<br>Switching to start this skill will lose that speed!';
					learn_bt.value = skill_training.name;
				}
				else {
					txt = 'Your progress on '+skill_training.name+' will be paused';
				}
			}
			else if(current_details.learning && current_details.paused){
				txt = 'You\'ve got this skill on pause at the moment';
				label_txt = 'Resume learning this skill';
			}
			else if(!current_details.can_learn){
				//defensive check, should never have this state
				txt = 'You need to meet the requirements first!';
				learn_bt.disabled = true;
			}
			
			//set the tip/label
			learn_bt.tip = txt ? {txt:txt, pointer:WindowBorder.POINTER_BOTTOM_CENTER} : null;
			learn_bt.label = label_txt;
		}
		
		private function setText():void {
			name_tf.htmlText = '<p class="imagination_skill_details"><span class="imagination_skill_details_name">'+current_details.name+'</span></p>';
			body_tf.htmlText = '<p class="imagination_skill_details">'+current_details.description+'</p>';
			
			//giants
			var giants:Vector.<SkillGiant>;
			var pri_giant:String = '';
			var sec_giant:String = '';
			var body_txt:String = '<p class="imagination_skill_details"><span class="imagination_skill_details_giant">Giant Affiliation: </span>';
			var i:int;
			giants = current_details.getGiants(true);
			if(giants.length > 0){
				for(i = 0; i < giants.length; i++){					
					pri_giant += giants[int(i)].giant_name+'&nbsp;(Primary)';
					if(i != giants.length-1) pri_giant += ', ';
				}
				
				body_txt += pri_giant;
			}
			
			giants = current_details.getGiants(false);
			if(giants.length > 0){
				if(pri_giant != '') body_txt += ', ';
				
				for(i = 0; i < giants.length; i++){					
					sec_giant += giants[int(i)].giant_name+'&nbsp;(Secondary)';
					if(i != giants.length-1) sec_giant += ', ';
				}
				
				body_txt += sec_giant;
			}
			
			body_txt += '</p>';
			giant_body_tf.htmlText = body_txt;
		}
		
		private function onHideComplete():void {
			if(parent) parent.removeChild(this);
			_is_hiding = false;
		}
		
		private function onBackClick(event:TSEvent):void {
			if(back_bt.disabled) return;
			back_bt.disabled = true;
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			ImaginationSkillsUI.instance.hideSkillDetails();
		}
		
		private function onLearnClick(event:TSEvent):void {
			SoundMaster.instance.playSound(!learn_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(learn_bt.disabled) return;
			learn_bt.disabled = true;
			
			//tell the api we want to start learning the skill
			if(!learn_bt.value){
				onLearnConfirm(true);
			}
			else {
				//toss up a confirmation dialog so they know
				if(!cdVO){
					cdVO = new ConfirmationDialogVO();
					cdVO.callback = onLearnConfirm;
					cdVO.choices = [
						{value:true, label:'Yup, start learning!'},
						{value:false, label:'No, nevermind'}
					];
					cdVO.escape_value = false;
					cdVO.title = 'Stop your accelerated learning?';
				}
				cdVO.txt = 'Are you sure you want to pause learning <b>'+learn_bt.value+'</b>? You will lose your accelerated learning speed if you do.';
				TSFrontController.instance.confirm(cdVO);
			}
		}
		
		private function onLearnConfirm(start_learning:Boolean):void {
			if(start_learning) {
				api_call.skillsLearn(current_details.class_tsid);
			}
			else {
				setLearnButton();
			}
		}
		
		private function onAPIComplete(event:TSEvent):void {
			//api call is done, go ahead and bring back the skills
			ImaginationSkillsUI.instance.hideSkillDetails();
		}
		
		private function onAPIError(event:TSEvent):void {
			//just reset the button
			SoundMaster.instance.playSound('CLICK_FAILURE');
			setLearnButton();
		}
		
		public function get is_hiding():Boolean { return _is_hiding; }
	}
}