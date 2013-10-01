package com.tinyspeck.engine.view.ui.imagination
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.skill.SkillDetails;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingSkillsCanLearnVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Cloud;
	import com.tinyspeck.engine.view.ui.SkillIcon;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Sprite;

	public class ImgMenuSkills extends ImgMenuElement
	{	
		private static const icon_size:uint = 24;
		private static const icon_padd:int = 4;
		
		private var button_holder:Sprite = new Sprite();
		
		private var skill_buttons:Vector.<Button> = new Vector.<Button>();
		
		private var is_zoom_in:Boolean;
		
		public function ImgMenuSkills(){}
		
		override protected function buildBase():void {
			super.buildBase();
			
			//set the title
			setTitle('Skills');
			
			//set that cloud
			setCloudByType(Cloud.TYPE_SKILLS);
			
			//set sound
			sound_id = 'CLOUD1';
			
			button_holder.filters = StaticFilters.copyFilterArrayFromObject({blurY:4}, StaticFilters.black1px90Degrees_DropShadowA);
			holder.addChild(button_holder);
		}
		
		override public function show():Boolean {
			if(!is_built) buildBase();
			if(!super.show()) return false;
			visible = true;
			
			//go ask the server nicely
			TSFrontController.instance.genericSend(new NetOutgoingSkillsCanLearnVO(), onSkillsCanLearn, onSkillsCanLearn);
			
			return true;
		}
		
		override public function hide():void {
			super.hide();
			ImaginationSkillsUI.instance.hide();
		}
		
		public function zoom(is_in:Boolean):void {
			//depending on what we need to do, handle showing/hide the chooser
			is_zoom_in = is_in;
			//const scale:Number = is_in ? 10 : 1;
			//TSTweener.removeTweens(this);
			
			if(is_in){
				visible = false;
				ImaginationSkillsUI.instance.show();
			}
			else {
				visible = true;
				ImaginationSkillsUI.instance.hide();
			}
			
			//TSTweener.addTween(this, {scaleX:scale, scaleY:scale, time:.3, onUpdate:onZoomUpdate, onComplete:onZoomComplete});
		}
		
		private function onZoomUpdate():void {
			//make sure the cloud stays where it should
			const lm:LayoutModel = TSModelLocator.instance.layoutModel;
			if(is_zoom_in){
				//this is where the skills will scale
			}
		}
		
		private function onZoomComplete():void {
			if(!is_zoom_in){
				visible = true;
			}
		}
		
		private function onSkillsCanLearn(nrm:NetResponseMessageVO):void {
			//not enabled yet
			enabled = false;
			
			//parse the skills and toss the icons on the cloud
			if(nrm.success && nrm.payload.skills){
				var icon:SkillIcon;
				var k:String;
				var skill:SkillDetails;
				var i:int;
				var total:int = skill_buttons.length;
				var bt:Button;
				var next_x:int;
				var next_y:int;
				
				//reset
				for(i = 0; i < total; i++){
					bt = skill_buttons[int(i)];
					bt.x = bt.y = 0;
					bt.visible = false;
				}
				
				total = Math.min(model.worldModel.learnable_skills.length, 5);
				for(i = 0; i < total; i++){
					skill = model.worldModel.learnable_skills[int(i)];
					if(!skill.can_learn) break;
					
					//we need to reset the X?
					if(i > 0 && i % 3 == 0){
						next_x = 0;
						next_y += icon_size + icon_padd;
					}
					
					//scale down the icon to the size we want
					icon = getIcon(skill.class_tsid);
					
					//the button
					bt = getButton();
					bt.visible = true;
					bt.value = skill.class_tsid;
					bt.setGraphic(icon);
					bt.x = next_x;
					bt.y = next_y;
					next_x += icon_size + icon_padd;
				}
				
				//set the sub text
				//see how many we can learn
				total = model.worldModel.learnable_skills.length;
				for(i = 0; i < total; i++){
					skill = model.worldModel.learnable_skills[int(i)];
					if(!skill.can_learn){
						//can't learn this, so it's not "available"
						break;
					}
				}
				setSubText(i + ' available');
				
				//only enable if we can actually learn and are not learning anything now
				const pc:PC = TSModelLocator.instance.worldModel.pc;
				if(model.worldModel.learnable_skills.length > 0 || pc.skill_training || pc.skill_unlearning) enabled = true;
				
				//in the RARE case that this is the last thing you're learning, you still need to be able to click
				//to see your progress
				if(!model.worldModel.learnable_skills.length && (pc.skill_training || pc.skill_unlearning)){
					bt = getButton();
					
					//scale it down
					const icon_tsid:String = pc.skill_training ? pc.skill_training.tsid : pc.skill_unlearning.tsid;
					icon = getIcon(icon_tsid);
					
					bt.visible = true;
					bt.value = icon_tsid;
					bt.setGraphic(icon);
				}
				
				//center the icons on the cloud
				button_holder.x = int(cloud.width/2 - button_holder.width/2 + 5);
				button_holder.y = int(cloud.y + (cloud.height/2 - button_holder.height/2));
			}
		}
		
		private function getButton():Button {
			const total:int = skill_buttons.length;
			var i:int;
			var bt:Button;
			
			for(i; i < total; i++){
				bt = skill_buttons[int(i)];
				if(!bt.visible) return bt;
			}
			
			//make a new one
			bt = new Button({
				name: 'bt_'+total,
				graphic_placement: 'left',
				draw_alpha: 0,
				w: icon_size,
				h: icon_size
			});
			skill_buttons.push(bt);
			button_holder.addChild(bt);
			
			return bt;
		}
		
		private function getIcon(skill_tsid:String):SkillIcon {
			const icon:SkillIcon = new SkillIcon(skill_tsid, SkillIcon.SIZE_DEFAULT);
			icon.width = icon_size;
			icon.height = icon_size;
			
			return icon;
		}
	}
}