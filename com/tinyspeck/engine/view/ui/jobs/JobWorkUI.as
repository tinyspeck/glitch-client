package com.tinyspeck.engine.view.ui.jobs
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.IStatBurstChange;
	import com.tinyspeck.engine.port.JobManager;
	import com.tinyspeck.engine.port.StatBurst;
	import com.tinyspeck.engine.port.StatBurstController;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.ProgressBar;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.EnergyGauge;
	import com.tinyspeck.engine.view.ui.Slug;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;

	public class JobWorkUI extends TSSpriteWithModel implements IStatBurstChange
	{
		private static const GAUGE_SCALE:Number = 3.5;
		private static const TOOL_X:int = 400;
		private static const TOOL_WH:uint = 140;
		
		private var energy_gauge:EnergyGauge = new EnergyGauge();
		private var progress:ProgressBar = new ProgressBar(162, 30);
		private var stop_bt:Button;
		private var tool_ani:ItemIconView;
		private var energy_slug:Slug;
		private var contribute_item:Item;
		
		private var energy_tf:TextField = new TextField();
		private var units_tf:TextField = new TextField();
		private var used_tf:TextField = new TextField();
		private var complete_title_tf:TextField = new TextField();
		private var complete_units_tf:TextField = new TextField();
		
		private var tool_holder:Sprite = new Sprite();
		
		private var units_current:uint;
		private var units_total:uint;
		private var unit_duration:uint;
		private var unit_energy:uint;
		
		private var tool_class_id:String;
		private var contribute_msg:String;
		
		private var _is_working:Boolean;
		
		public function JobWorkUI(w:int, h:int){
			_w = w;
			_h = h;
			
			//gauge
			energy_gauge.scaleX = energy_gauge.scaleY = GAUGE_SCALE;
			energy_gauge.x = 170;
			energy_gauge.y = 120;
			addChild(energy_gauge);
			
			//setup the tool animator
			tool_holder.x = TOOL_X;
			tool_holder.y = int(TOOL_WH/2 + progress.height);
			addChild(tool_holder);
			
			//progress - units
			TFUtil.prepTF(units_tf, false);
			units_tf.htmlText = '<p class="job_work_progress">Placeholderp</p>';
			units_tf.x = 10;
			units_tf.y = int(progress.height/2 - units_tf.height/2 + 1);
			progress.addChild(units_tf);
			
			//progress - stop bt
			stop_bt = new Button({
				name: 'stop',
				label: 'Stop',
				type: Button.TYPE_MINOR,
				size: Button.SIZE_TINY
			});
			stop_bt.addEventListener(TSEvent.CHANGED, onStopClick, false, 0, true);
			stop_bt.h = int(progress.height + 2);
			stop_bt.x = progress.width + 2;
			stop_bt.y = -1;
			progress.addChild(stop_bt);
			
			//add the progress
			progress.x = int(tool_holder.x - progress.width/2);
			progress.y = int(tool_holder.y + TOOL_WH/2 + 30);
			addChild(progress);
			
			//labels
			TFUtil.prepTF(energy_tf, false);
			energy_tf.htmlText = '<p class="job_work_type">Energy</p>';
			energy_tf.x = int(energy_gauge.x - energy_tf.width/2);
			energy_tf.y = int(energy_gauge.y + energy_gauge.height/2) + 10;
			addChild(energy_tf);
			
			TFUtil.prepTF(used_tf, false);
			used_tf.y = int(energy_tf.y + energy_tf.height);
			addChild(used_tf);
			
			TFUtil.prepTF(complete_title_tf, false);
			complete_title_tf.htmlText = '<p class="job_work_type">Work units</p>';
			complete_title_tf.x = TOOL_X - int(complete_title_tf.width/2);
			complete_title_tf.y = energy_tf.y;
			addChild(complete_title_tf);
			
			TFUtil.prepTF(complete_units_tf, false);
			complete_units_tf.y = int(complete_title_tf.y + complete_title_tf.height);
			addChild(complete_units_tf);
			
			//set the slug
			var reward:Reward = new Reward(Reward.ENERGY);
			reward.type = Reward.ENERGY;
			reward.amount = -5; //this surpresses the 0 amount error
			energy_slug = new Slug(reward);
			
			//make this thing nice and tall
			var g:Graphics = graphics;
			g.beginFill(0,0);
			g.drawRect(0, 0, 3, _h);
		}
		
		public function show(units_total:uint, unit_duration:uint, unit_energy:uint, tool_class_id:String):void {
			if(is_working) return;
			_is_working = true;
			visible = true;
			
			this.units_total = units_total;
			this.unit_duration = unit_duration;
			this.unit_energy = unit_energy;
			this.tool_class_id = tool_class_id;
			units_current = 0;
			complete_title_tf.alpha = 0;
			complete_units_tf.alpha = 0;
			stop_bt.disabled = false;
			
			//listen to metabolic changes
			StatBurstController.instance.registerChangeSubscriber(this);
			
			//make sure gauge is accurate
			energy_gauge.max_value = model.worldModel.pc ? model.worldModel.pc.stats.energy.max : 250;
			energy_gauge.update(model.worldModel.pc ? model.worldModel.pc.stats.energy.value : 0);
			
			//setup the tool animator
			if(tool_ani && tool_ani.mc && tool_ani.mc.hasEventListener(Event.ENTER_FRAME)){
				tool_ani.mc.removeEventListener(Event.ENTER_FRAME, onToolAniEnterFrame);
			}
			SpriteUtil.clean(tool_holder);
			tool_ani = new ItemIconView(tool_class_id, TOOL_WH, 'tool_animation', 'center', true);
			tool_holder.addChild(tool_ani);
			
			//make sure the slug amount is right
			energy_slug.amount = -unit_energy;
			
			//animate the progress straight away
			progress.visible = true;
			progress.update(0);
			progress.updateWithAnimation(unit_duration/1000, 1);
			
			//update stuff
			increment(0);
		}
		
		public function hide():void {
			visible = false;
		}
		
		public function increment(amount:int):void {
			if(!is_working) return;
			
			units_current += amount;
			
			units_tf.htmlText = '<p class="job_work_progress">'+units_current+'/'+units_total+' units complete</p>';
			used_tf.htmlText = '<p class="job_work_value">Used: '+(units_current * unit_energy)+'</p>';
			used_tf.x = int(energy_gauge.x - used_tf.width/2);
			
			if(amount != 0){
				//animate the slug
				energy_slug.x = int(energy_gauge.x - energy_slug.width/2);
				energy_slug.y = int(energy_gauge.y);
				energy_slug.alpha = 1;
				addChildAt(energy_slug, 0);
				
				TSTweener.addTween(energy_slug, {y:int(energy_slug.y - energy_gauge.height/2 - 30), time:.4});
				TSTweener.addTween(energy_slug, {y:int(energy_slug.y - energy_gauge.height/2 - 60), alpha:0, time:.4, delay:1, onComplete:onSlugComplete});
				
				//update the progress
				if(units_current < units_total){
					progress.update(0);
					progress.updateWithAnimation(unit_duration/1000, 1, .3);
				}
				else {
					//if we are done before the server says we are, disable the stop button
					stop_bt.disabled = true;
				}
			}
		}
		
		public function stop():void {
			_is_working = false;
			
			//let's wait for the last frame of the animation and then stop it
			if(tool_ani && tool_ani.mc) tool_ani.mc.addEventListener(Event.ENTER_FRAME, onToolAniEnterFrame, false, 0, true);
			
			progress.visible = false;
			progress.stopTweening();
			
			//setup and tween the done stuff
			complete_units_tf.htmlText = '<p class="job_work_value">'+units_current+'/'+units_total+' complete</p>';
			complete_units_tf.x = TOOL_X - int(complete_units_tf.width/2);
			
			TSTweener.addTween([complete_title_tf, complete_units_tf], {alpha:1, time:.4, transition:'linear'});
			
			//stop listening to metabolic changes
			StatBurstController.instance.unRegisterChangeSubscriber(this);
		}
		
		public function getContributeMsg():String {
			contribute_item = model.worldModel.getItemByTsid(tool_class_id);
			contribute_msg = 'You contributed '+units_current+' work '+(units_current != 1 ? 'units' : 'unit')+
							 ' with your '+(contribute_item ? contribute_item.label : 'thing')+'. Thanks.';
			
			//reset it after getting it
			units_current = 0;
			
			return contribute_msg;
		}
		
		public function onStatBurstChange(stat_burst:StatBurst, value:int):void {
			//create a slug of the change
			if(stat_burst.type == StatBurst.ENERGY){
				energy_gauge.update(model.worldModel.pc.stats.energy.value);
			}
			stat_burst.go(value);
		}
		
		private function onStopClick(event:TSEvent):void {
			if(stop_bt.disabled) return;
			stop_bt.disabled = true;
			progress.update(0, true);
			JobManager.instance.stopWorkFromClient(tool_class_id);
		}
		
		private function onToolAniEnterFrame(event:Event):void {			
			if(tool_ani && tool_ani.mc && tool_ani.mc.currentFrame == 1){
				tool_ani.mc.stop();
				tool_ani.mc.removeEventListener(Event.ENTER_FRAME, onToolAniEnterFrame);
			}
		}
		
		private function onSlugComplete():void {
			if(contains(energy_slug)) removeChild(energy_slug);
		}
		
		public function get is_working():Boolean { return _is_working; }
		public function get did_work():Boolean { return units_current > 0; }
		public function get tool_tsid():String { return tool_class_id; }
	}
}