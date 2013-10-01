package com.tinyspeck.engine.port
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCTeleportationTarget;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Slug;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.utils.Timer;

	public class TeleportationDialog extends Sprite
	{	
		private const MAX_TARGETS:uint = 3; //how many teleportation targets can we have?
		private const DIALOG_W:uint = RightSideView.MIN_WIDTH_CLOSED - 9;
		private const MAX_CHARS:uint = 23;
		
		private var confirm_bt:Button;
		private var confirm_cancel_bt:Button;
		private var energy_slug:Slug;
		private var model:TSModelLocator;
		
		private var all_holder:Sprite = new Sprite();
		private var confirm_holder:Sprite = new Sprite();
		
		private var status_tf:TextField = new TextField();
		private var confirm_title_tf:TextField = new TextField();
		private var confirm_body_tf:TextField = new TextField();
		
		private var checkmark:MovieClip = new AssetManager.instance.assets.checkmark();
		
		private var timer:Timer = new Timer(1000);
		
		private var is_built:Boolean;
		
		private var _cooldown_left:int;
		
		/* singleton boilerplate */
		public static const instance:TeleportationDialog = new TeleportationDialog();

		public function TeleportationDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			model = TSModelLocator.instance;
						
			//hide
			visible = false;
		}
		
		private function buildBase():void {
			var next_y:int;
			
			//status text
			TFUtil.prepTF(status_tf, false);
			all_holder.addChild(status_tf);
			
			//we have a MAX of 3 teleportation targets
			var pc:PC = model.worldModel.pc;
			if(pc && pc.teleportation){
				var i:int;
				var targets:Vector.<PCTeleportationTarget> = pc.teleportation.targets;
				var bt:Button;
				var disabled_alpha:Number = CSSManager.instance.getNumberValueFromStyle('button_teleport_new_label', 'alphaDisabled', .3);
				
				for(i; i < MAX_TARGETS; i++){
					//create the edit button
					bt = new Button({
						name: 'edit'+i,
						label_size: 13,
						graphic_placement: 'left',
						graphic_padd_l: 8,
						graphics_padd_r: 5,
						disabled_graphic_alpha: disabled_alpha,
						value: i+1, //teleport_id starts from 1
						size: Button.SIZE_DEFAULT,
						type: Button.TYPE_MINOR,
						y: next_y
					});
					bt.label_y_offset = 2;
					bt.addEventListener(TSEvent.CHANGED, onTeleportSetClick, false, 0, true);
					all_holder.addChild(bt);
					
					//create the go button
					const teleport_icon:DisplayObject = new AssetManager.instance.assets.teleport_icon();
					bt = new Button({
						name: 'go'+i,
						label_size: 13,
						graphic: teleport_icon,
						graphic_placement: 'left',
						graphic_padd_l: 8,
						graphics_padd_r: 5,
						disabled_graphic_alpha: disabled_alpha,
						value: i+1, //teleport_id starts from 1
						size: Button.SIZE_DEFAULT,
						type: Button.TYPE_TELEPORT,
						w: DIALOG_W - 69,
						y: next_y
					});
					bt.addEventListener(TSEvent.CHANGED, onTeleportGoClick, false, 0, true);
					all_holder.addChild(bt);
					
					next_y += bt.height + 5;
				}
				
				//build out the confirmation pane
				TFUtil.prepTF(confirm_title_tf, false);
				confirm_title_tf.htmlText = '<p class="teleportation_confirm_title">New Teleport Point?</p>';
				confirm_title_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
				confirm_holder.addChild(confirm_title_tf);
				
				TFUtil.prepTF(confirm_body_tf);
				confirm_body_tf.width = DIALOG_W;
				confirm_body_tf.y = int(confirm_title_tf.height + 3);
				confirm_body_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
				confirm_holder.addChild(confirm_body_tf);
				
				confirm_bt = new Button({
					name: 'confirm_location',
					label: 'Save this point',
					size: Button.SIZE_DEFAULT,
					type: Button.TYPE_MINOR,
					w: DIALOG_W-89
				});
				confirm_bt.addEventListener(TSEvent.CHANGED, onConfirmClick, false, 0, true);
				confirm_holder.addChild(confirm_bt);
				
				confirm_cancel_bt = new Button({
					name: 'cancel',
					label: 'Cancel',
					size: Button.SIZE_DEFAULT,
					type: Button.TYPE_MINOR,
					x: int(confirm_bt.width + 6),
					w: 78
				});
				confirm_cancel_bt.addEventListener(TSEvent.CHANGED, onConfirmCancelClick, false, 0, true);
				confirm_holder.addChild(confirm_cancel_bt);
				confirm_holder.visible = false;
				addChild(confirm_holder);
				
				is_built = true;
				
				//set the status text
				status_tf.y = next_y + 5;
				
				//lay them where they should go
				refreshButtons();
			}
			else {
				CONFIG::debugging {
					Console.warn('Uhhh, no PC?!');
				}
			}
			
			//checkmark
			checkmark.visible = false;
			all_holder.addChild(checkmark);
			
			addChild(all_holder);
		}
		
		public function onTeleportationChange():void {
			var pc:PC = model.worldModel.pc;
			if(!pc || (pc && !pc.teleportation)) return;
			if(!is_built) buildBase();
			
			//let things know things changed
			dispatchEvent(new TSEvent(TSEvent.CHANGED));
			
			//update the labels/buttons
			refreshButtons();
		}
		
		public function onLocationSet():void {
			if(!is_built) buildBase();
			
			refreshButtons();
			//throw a little checkmark and animate it all fancy
			checkmark.visible = true;
			checkmark.scaleX = checkmark.scaleY = 0;
			TSTweener.addTween(checkmark, {scaleX:5, scaleY:5, time:.3, onUpdate:adjustCheckmark });
			TSTweener.addTween(checkmark, {scaleX:0, scaleY:0, time:.3, delay:.5, onUpdate:adjustCheckmark, 
				onComplete:function():void { 
					checkmark.visible = false;
				} 
			});
			TSTweener.addTween(checkmark, {delay:.6, onComplete:TSFrontController.instance.endFamiliarDialog});
		}
		
		private function adjustCheckmark():void {
			//get the button this was in relation to
			var bt:Button = all_holder.getChildByName('go'+int(confirm_bt.value-1)) as Button;
			if(bt){
				checkmark.x = int(bt.x + (bt.w - checkmark.width)/2);
				checkmark.y = int(bt.y + (bt.height - checkmark.height)/2);
			}
		}
		
		private function setStatusText(txt:String, display_energy_icon:Boolean = false):void {
			if(!txt){
				CONFIG::debugging {
					Console.warn('No txt when setting status?!');
				}
				return;
			}
			
			status_tf.htmlText = '<p class="teleportation_status">'+txt+'</p>';
			
			var slug_padd:int = 10;
			
			//energy slug
			if(display_energy_icon && !energy_slug){
				//var last_char:Rectangle = status_tf.getCharBoundaries(txt.length-1);
				//if(!last_char) last_char = new Rectangle(0,0,0,0);
				var reward:Reward = new Reward(Slug.ENERGY);
				reward.type = Slug.ENERGY;
				reward.amount = model.worldModel.pc && model.worldModel.pc.teleportation ? -model.worldModel.pc.teleportation.energy_cost : 0;
				energy_slug = new Slug(reward);
				energy_slug.draw_border = false;
				energy_slug.y = int(status_tf.y + (energy_slug.height/2 - status_tf.height/2)) - 3;
				
				all_holder.addChild(energy_slug);
			}
			
			//move the tf if we need to
			status_tf.x = (DIALOG_W - status_tf.width)/2 - (display_energy_icon ? int(energy_slug.width/2 + slug_padd) : 0);
			
			//handle the slug
			if(energy_slug) {
				energy_slug.x = display_energy_icon ? int(status_tf.x + status_tf.width + slug_padd) : 0;
				energy_slug.visible = display_energy_icon;
				energy_slug.amount = model.worldModel.pc && model.worldModel.pc.teleportation ? -model.worldModel.pc.teleportation.energy_cost : 0;
			}
		}
		
		private function onCooldownTick(event:TimerEvent = null):void {
			setStatusText('Teleportation available again in ' + StringUtil.formatTime(_cooldown_left));
			
			//kill the timer
			if(_cooldown_left <= 0){				
				timer.stop();
				timer.removeEventListener(TimerEvent.TIMER, onCooldownTick);
				
				onTeleportationChange();
				dispatchEvent(new TSEvent(TSEvent.COMPLETE));
				return;
			}
			
			_cooldown_left--;
		}
		
		private function refreshButtons():void {
			var pc:PC = model.worldModel.pc;
			if(pc && pc.teleportation){
				if(!is_built) buildBase();
				
				var i:int;
				var targets:Vector.<PCTeleportationTarget> = pc.teleportation.targets;
				var is_edit:Boolean;
				var bt:Button;
				var tip_txt:String;
				
				for(i; i < MAX_TARGETS; i++){
					is_edit = targets.length > i && targets[int(i)].tsid;
					
					//get the edit button
					bt = all_holder.getChildByName('edit'+i) as Button;
					if(bt){
						if(!bt.graphic && !is_edit){
							const teleport_icon:DisplayObject = new AssetManager.instance.assets.teleport_icon();
							bt.setGraphic(teleport_icon);
						}
						else if(is_edit){
							bt.removeGraphic();
						}
						bt.label = is_edit ? 'Edit' : 'Set this location as Teleport Point'
						bt.w = is_edit ? 55 : DIALOG_W-11;
						bt.x = is_edit ? DIALOG_W-66 : 0;
						bt.disabled = false;
						bt.tip = null;
						bt.setSizeAndType(Button.SIZE_DEFAULT, is_edit ? Button.TYPE_MINOR : Button.TYPE_TELEPORT);
						bt.label_y_offset = 2;
						
						//if they don't have the skill, let's go ahead and disable the button
						if(i+1 > targets.length){
							bt.disabled = true;
							bt.label = 'Unlock with Teleportation '+(i == 1 ? 'II' : 'III');
						}
						
						if (!bt.disabled && !pc.teleportation.can_set_target) {
							bt.disabled = true;
							bt.tip = {txt:'Your current location cannot be set as a Teleportation Point', pointer:WindowBorder.POINTER_BOTTOM_CENTER};
						}
					}
					
					//get the go button
					bt = all_holder.getChildByName('go'+i) as Button;
					if(bt){
						bt.visible = is_edit;
						if(is_edit){
							bt.label = StringUtil.truncate(targets[int(i)].label, MAX_CHARS);
							
							//check to see if they are in the location that the target is
							bt.disabled = model.worldModel.location.tsid == targets[int(i)].tsid;
							if(bt.disabled){
								tip_txt = 'You are already here!';
							}
							else if(bt.label_tf.text.indexOf('...') != -1){
								tip_txt = targets[int(i)].label;
							}
							else {
								tip_txt = null;
							}
							
							//check for teleportation cooldown
							if(cooldown_left){
								bt.disabled = true;
								tip_txt = null;
							}
							
							bt.tip = tip_txt ? {txt:tip_txt, pointer:WindowBorder.POINTER_BOTTOM_CENTER} : null;
						}
					}
				}
				
				if(_cooldown_left > 0){
					//update the countdown if we have one
					onCooldownTick();
				}
				else {
					//the default text with the energy_cost
					setStatusText('Cost to teleport:', true);
				}
			}
			else {
				CONFIG::debugging {
					Console.warn('Uhhh, no PC?!');
				}
			}
		}
		
		private function onTeleportGoClick(event:TSEvent):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			var bt:Button = event.data as Button;
			if(bt.disabled || model.moveModel.moving) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			//go teleport
			TeleportationManager.instance.clientGo(bt.value);
			
			//disable all the buttons
			var i:int;
			for(i; i < MAX_TARGETS; i++){
				bt = all_holder.getChildByName('go'+i) as Button;
				if(bt) bt.disabled = true;
			}
		}
		
		private function onTeleportSetClick(event:TSEvent):void {
			const bt:Button = event.data as Button;
			if(bt.disabled || model.moveModel.moving) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			//bring up the confirmation dialog
			const loc:Location = model.worldModel.location;
			if(loc){
				//set the value for the confirm button
				confirm_bt.value = bt.value;
				var confirm_txt:String = '<p class="teleportation_confirm_body">';
				confirm_txt += 'Make a teleport point to <b>'+(loc.label ? loc.label : 'your current position')+'</b>? '+
							   'When you teleport, you\'ll arrive here.';
				confirm_txt += '</p>';
				
				confirm_body_tf.htmlText = confirm_txt;
				confirm_bt.y = confirm_cancel_bt.y = int(confirm_body_tf.y + confirm_body_tf.height + 20);
				all_holder.visible = false;
				confirm_holder.visible = true;
			}
		}
		
		private function onConfirmClick(event:TSEvent):void {
			var bt:Button = event.data as Button;
			if(bt.disabled || model.moveModel.moving) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			StageBeacon.stage.focus = StageBeacon.stage;
			TeleportationManager.instance.clientSet(bt.value);
			
			all_holder.visible = true;
			confirm_holder.visible = false;
		}
		
		private function onConfirmCancelClick(event:TSEvent):void {
			all_holder.visible = true;
			confirm_holder.visible = false;
			SoundMaster.instance.playSound('CLICK_SUCCESS');
		}
		
		public function get cooldown_left():int { return _cooldown_left; }
		public function set cooldown_left(value:int):void { 
			if(!is_built) buildBase();
			_cooldown_left = value;
			
			//start the countdown timer
			if(!timer.running && _cooldown_left > 0){
				timer.addEventListener(TimerEvent.TIMER, onCooldownTick, false, 0, true);
				timer.start();
			}
			
			//tell whoever is listening that we are good to teleport again
			if(value == 0) dispatchEvent(new TSEvent(TSEvent.COMPLETE));
			
			//refresh the buttons
			refreshButtons();
		}
		
		override public function set visible(value:Boolean):void {
			//anytime we change visibility hide the confirm and show the all_holder
			super.visible = value;
			all_holder.visible = true;
			confirm_holder.visible = false;
		}
	}
}