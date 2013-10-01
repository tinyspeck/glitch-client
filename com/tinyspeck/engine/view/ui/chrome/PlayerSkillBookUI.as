package com.tinyspeck.engine.view.ui.chrome
{
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCSkill;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.SkillManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.ImgMenuView;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.ui.Cloud;
	import com.tinyspeck.engine.view.ui.imagination.ImaginationSkillsUI;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class PlayerSkillBookUI extends Sprite implements ITipProvider
	{
		private var current_skill:PCSkill;
		
		private var book:DisplayObject;
		
		private var tip_txt:String;
		
		private var is_built:Boolean;
		
		public function PlayerSkillBookUI(){
			//listen to the manager for changes
			SkillManager.instance.addEventListener(TSEvent.CHANGED, onSkillChange, false, 0, true);
		}
		
		private function buildBase():void {
			//setup the asset/progress
			book = new AssetManager.instance.assets.skill_book_small();
			
			//mouse stuff
			useHandCursor = buttonMode = true;
			addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			
			is_built = true;
		}
		
		public function refresh():void {
			//public facing method to force a redraw
			onSkillChange();
		}
		
		private function onSkillChange(event:TSEvent = null):void {
			//all we want to do is refresh the skill training stuff
			if(!is_built) buildBase();
			
			//decide what to show
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			current_skill = pc.skill_training != null ? pc.skill_training : pc.skill_unlearning;
			
			//if we have a skill, make sure we show the book
			if(current_skill && !contains(book)){
				addChild(book);
				TipDisplayManager.instance.registerTipTrigger(this);
			}
			//all gone
			else if(!current_skill && contains(book)){
				removeChild(book);
				TipDisplayManager.instance.unRegisterTipTrigger(this);
			}
			
			//update the ui
			tip_txt = '';
			if(current_skill){
				const secs_left:int = SkillManager.instance.skill_remaining_secs;
				
				//set the time text
				const time_txt:String = secs_left > 0 ? StringUtil.formatTime(secs_left) : 'any second now!';
				
				if(pc.skill_training){
					tip_txt = 'Learning '+current_skill.name;
				}
				else if(pc.skill_unlearning){
					tip_txt = 'Unlearning '+current_skill.name;
				}
				
				//set the tip text to match what buffs look like
				if(tip_txt){
					tip_txt = '<p class="buff_name_tip">'+tip_txt+'</p>'+'<p class="buff_timer_tip">'+time_txt+'</p>';
				}
			}
		}
		
		private function onClick(event:MouseEvent):void {
			//open the skill cloud
			if(!ImaginationSkillsUI.instance.parent){
				ImgMenuView.instance.cloud_to_open = Cloud.TYPE_SKILLS;
				ImgMenuView.instance.show();
			}
			else {
				//hide the menu
				ImgMenuView.instance.hide();
			}
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target || !tip_txt) return null;
			return {
				txt:tip_txt,
				pointer:WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
	}
}