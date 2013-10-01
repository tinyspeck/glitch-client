package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.data.pc.PCSkill;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	
	import flash.events.EventDispatcher;
	import flash.utils.getTimer;

	public class SkillManager extends EventDispatcher
	{
		/**
		 * This is the one-stop-shop for all your skill knowing needs
		 * especially things like how much time is left on a skill
		 * being learned
		 */	
		
		/* singleton boilerplate */
		public static const instance:SkillManager = new SkillManager();
		
		private var world:WorldModel;
		private var current_skill:PCSkill;
		private var timer_interval:int = -1;
		
		private var inited:Boolean;
			
		public function SkillManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function init():void {
			world = TSModelLocator.instance.worldModel;
			
			//listen to changes
			world.registerCBProp(onSkillChange, "pc","skill_training");
			world.registerCBProp(onSkillChange, "pc","skill_training_change");
			world.registerCBProp(onSkillChange, "pc","skill_training_complete");
			
			//check if we are learning anything
			onSkillChange();
			
			inited = true;
		}
		
		private function onSkillChange(pc_skill:PCSkill = null):void {
			//see if we need to start/stop the timer
			current_skill = world.pc.skill_training != null ? world.pc.skill_training : world.pc.skill_unlearning;
			if(current_skill && timer_interval == -1){
				timer_interval = StageBeacon.setInterval(onSkillChange, 1000);
			}
			else if(!current_skill && timer_interval != -1){
				StageBeacon.clearInterval(timer_interval);
				timer_interval = -1;
			}
			
			//let whoever is listening know
			//TODO maybe throw this in TSFC and have register/unregister methods and ditch the triggerCBProp stuff
			dispatchEvent(new TSEvent(TSEvent.CHANGED, skill_remaining_secs));
		}
		
		public function get skill_remaining_secs():int {
			if(current_skill){
				return Math.round(current_skill.time_remaining-((getTimer()-current_skill.local_time_start)/1000));
			}
			return 0;
		}
	}
}