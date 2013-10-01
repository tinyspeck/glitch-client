package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.rook.RookHeadAnimationState;
	import com.tinyspeck.engine.data.rook.RookedStatus;
	import com.tinyspeck.engine.model.RookModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.RookManager;
	import com.tinyspeck.engine.util.DrawUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.text.TextField;
	import flash.utils.Timer;

	public class RookIncidentHeaderView extends Sprite
	{		
		/* singleton boilerplate */
		public static const instance:RookIncidentHeaderView = new RookIncidentHeaderView();
		
		private const FULL_ANIMATION_TIME:Number = 2.5; //how long from 0% - 100% in secs.
		private const UPDATE_ANIMATION_TIME:Number = 1.5; //anytime updates come in, how long it takes to animate
		private const HEALTH_Y:Number = 39.5;
		private const HEALTH_RADIUS:Number = 33.5;
		private const MSG_Y:uint = 30; //how far from the top to start the msg text
		private const MSG_WIDTH:uint = 216;
		
		private var health_percent_set_at:Number;
		private var stun_percent_set_at:Number;
		private var stars_y:int;
		
		private var main_view:TSMainView;
		private var rm:RookModel;
		private var model:TSModelLocator;
		private var ydm:YouDisplayManager;
		private var stars_timer:Timer = new Timer(100); //how fast to animate the stars
		private var stun_glow:GlowFilter = new GlowFilter();
		private var damage_glow:GlowFilter = new GlowFilter();
		
		private var stars_bg:DisplayObject;
		private var stars_holder:Sprite = new Sprite();
		private var stars_mask:Sprite = new Sprite();
		private var health_holder:Sprite = new Sprite();
		private var health_mask:Sprite = new Sprite();
		private var health_juice:Sprite = new Sprite();
		private var health_juice_bg:Sprite = new Sprite();
		private var health_juice_mask:Sprite = new Sprite();
		private var health_juice_bg_mask:Sprite = new Sprite();
		private var health_top:Sprite = new Sprite();
		private var msg_holder:Sprite = new Sprite();
		private var msg_mask:Sprite = new Sprite();
		
		private var stun_tfs:Vector.<TextField> = new Vector.<TextField>();
		private var msg_tf:TextField = new TextField();
		
		private var current_phase:String;
		
		private var is_built:Boolean;
				
		public function RookIncidentHeaderView(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			main_view = TSFrontController.instance.getMainView();
			model = TSModelLocator.instance;
			rm = model.rookModel;
			ydm = YouDisplayManager.instance;
			
			visible = false;
		}
		
		private function buildBase():void {			
			//setup the stars
			stars_bg = new AssetManager.instance.assets.rook_star_bg();
			var g:Graphics = stars_mask.graphics;
			if(stars_bg){
				stars_bg.x = int(-stars_bg.width/2);
				addChildAt(stars_bg, 0);
				
				//draw the mask and put on the stars
				g.beginFill(0,0);
				g.drawRect(0, 0, stars_bg.width, stars_bg.height);
				stars_mask.x = stars_bg.x;
				addChild(stars_mask);
				
				var stars:DisplayObject = new AssetManager.instance.assets.rook_star_stars();
				if(stars){
					stars_holder.mouseEnabled = stars_holder.mouseChildren = false;
					stars_holder.addChild(stars);
					stars_holder.mask = stars_mask;
					stars_holder.x = stars_bg.x;
					addChild(stars_holder);
				}
				
				stars_timer.addEventListener(TimerEvent.TIMER, onStarTick, false, 0, true);
				
				//setup the health bar
				g = health_holder.graphics;
				g.beginFill(model.layoutModel.bg_color);
				g.drawCircle(HEALTH_RADIUS, HEALTH_Y, HEALTH_RADIUS);
				health_holder.x = -health_holder.width/2;
				health_holder.mask = health_mask;
				addChildAt(health_holder, 0);
				
				//juice bg
				g = health_juice_bg.graphics;
				g.beginFill(0xc2c8ca);
				DrawUtil.drawArc(g, 0, 0, 0, 180, HEALTH_RADIUS-2, 1);
				health_juice_bg.x = HEALTH_RADIUS-2;
				health_juice_bg.y = model.layoutModel.header_h;
				health_juice_bg.mask = health_juice_bg_mask;
				health_holder.addChild(health_juice_bg);
				
				//drop shadow for juice bg
				var drop:DropShadowFilter = new DropShadowFilter();
				drop.inner = true;
				drop.angle = 90;
				drop.blurX = 0;
				drop.blurY = 3;
				drop.alpha = .2;
				drop.distance = 2;
				health_juice_bg.filters = [drop];
				
				//juice
				g = health_juice.graphics;
				g.beginFill(0xbd152d);
				DrawUtil.drawArc(g, 0, 0, 0, 180, HEALTH_RADIUS-2, 1);
				health_juice.x = HEALTH_RADIUS-2;
				health_juice.y = model.layoutModel.header_h;
				health_juice.mask = health_juice_mask;
				health_holder.addChild(health_juice);
				
				//masks
				g = health_juice_mask.graphics;
				g.beginFill(0);
				DrawUtil.drawArc(g, HEALTH_RADIUS-1, HEALTH_Y, 0, 180, HEALTH_RADIUS-2, 1);
				health_holder.addChild(health_juice_mask);
				
				g = health_juice_bg_mask.graphics;
				g.beginFill(0);
				DrawUtil.drawArc(g, HEALTH_RADIUS-1, HEALTH_Y, 0, 180, HEALTH_RADIUS-2, 1);
				health_holder.addChild(health_juice_bg_mask);
				
				g = health_mask.graphics;
				g.beginFill(0);
				g.drawRect(0, 0, stars_bg.width, stars_bg.height);
				health_mask.x = health_holder.x;
				health_mask.y = stars_bg.height;
				addChild(health_mask);
				
				//put the top on the health
				g = health_top.graphics;
				g.beginFill(model.layoutModel.bg_color);
				g.drawCircle(HEALTH_RADIUS-4.5, HEALTH_Y-2.5, HEALTH_RADIUS-7.5);
				health_holder.addChild(health_top);
				
				//msg holder
				TFUtil.prepTF(msg_tf);
				msg_tf.width = MSG_WIDTH - 20;
				msg_tf.x = 10;
				msg_tf.y = MSG_Y;
				msg_tf.filters = StaticFilters.white3px_GlowA;
				msg_holder.addChild(msg_tf);
				msg_holder.x = int(-MSG_WIDTH/2);
				msg_holder.mask = msg_mask;
				addChild(msg_holder);
				msg_holder.filters = StaticFilters.rook_msgA;
				
				//msg mask
				msg_mask.x = msg_holder.x;
				msg_mask.y = model.layoutModel.header_h;
				addChild(msg_mask);
			}
			
			//listen to the timer prop on the rook manager
			//RookManager.instance.addEventListener(TSEvent.TIMER_TICK, onTimerTick, false, 0, true);
			
			//set the text glow
			stun_glow.blurX = stun_glow.blurY = 4;
			stun_glow.strength = 12;
			stun_glow.color = CSSManager.instance.getUintColorValueFromStyle('rook_attack_stun', 'borderColor', 0x2d4043);
			
			damage_glow.blurX = damage_glow.blurY = 4;
			damage_glow.strength = 12;
			damage_glow.color = CSSManager.instance.getUintColorValueFromStyle('rook_attack_damage', 'borderColor', 0x333333);
			
			is_built = true;
		}
		
		public function start():void {
			if(!is_built) buildBase();
			
			removeAllTweens();
			
			alpha = 1;
			if(rook_head) rook_head.visible = false;
			
			//set the current phase
			current_phase = rm.rooked_status.phase;
			
			//only show the rad stuff in the epicentre
			if(rm.rooked_status.epicentre){
				TSFrontController.instance.changeTeleportDialogVisibility();
				
				//position and size things
				if(rook_head) rook_head.visible = true;
				
				//reset the stuff
				stun_percent_set_at = 0;
				health_percent_set_at = 1;
								
				if(rm.rooked_status.phase == RookedStatus.PHASE_BUILD_UP){
					RookManager.instance.animateRookHead(RookHeadAnimationState.IDLE);
										
					updateStun(1, false);
					updateHealth(0, false);
					
					if(rm.rook_incident_started_while_i_was_in_this_loc){					
						//animate the health juice
						if(rm.rooked_status.health == rm.rooked_status.max_health){
							health_holder.y = -30;
							TSTweener.addTween(health_holder, {y:0, time:.6});
						}
					}
					
					//stun
					if(rm.rooked_status.stun > 0){
						updateStun(rm.rooked_status.stun/rm.rooked_status.max_stun, false);
					}
					else {
						updateStun(0, rm.rook_incident_started_while_i_was_in_this_loc);
					}
					
					//health
					if(rm.rooked_status.health < rm.rooked_status.max_health){
						updateHealth(rm.rooked_status.health/rm.rooked_status.max_health, false);
					}
					else {
						updateHealth(1, rm.rook_incident_started_while_i_was_in_this_loc);
					}
				}
				else if(rm.rooked_status.phase == RookedStatus.PHASE_ANGRY){
					//if the state has changed, play angry if this wasn't a damaging hit
					if(stun_percent_set_at == rm.rooked_status.stun/rm.rooked_status.max_stun){
						RookManager.instance.animateRookHead(RookHeadAnimationState.TAUNT, true);
					}
					
					//stun
					if(rm.rooked_status.stun > 0){
						updateStun(rm.rooked_status.stun/rm.rooked_status.max_stun, false);
					}
					else {
						updateStun(0, rm.rook_incident_started_while_i_was_in_this_loc);
					}
					
					//health
					if(health_percent_set_at != rm.rooked_status.health/rm.rooked_status.max_health){
						updateHealth(rm.rooked_status.health/rm.rooked_status.max_health, false);
					}
					
				}
				else if(rm.rooked_status.phase == RookedStatus.PHASE_STUNNED){
					RookManager.instance.animateRookHead(RookHeadAnimationState.STUNNED, true);
					
					updateHealth(rm.rooked_status.health/rm.rooked_status.max_health, rm.rook_incident_started_while_i_was_in_this_loc);
					
					//max em out
					updateStun(1, false);
				}
			}
			
			//any text?
			if(rm.rooked_status.txt){
				addPriorityMsg(rm.rooked_status.txt);
			}
			
			main_view.addView(this);
			refresh();
		}
		
		public function update():void {
			if(!visible) return;
						
			//if we've changed phases, reset stuff
			if(current_phase != rm.rooked_status.phase){
				start();
				return;
			} else {
				// phase has not changed, but maybe angry_state has, so let's make sure the animations get updated
				RookManager.instance.tickleRookHead();
			}
		}
		
		public function stun():void {
			if(!visible) return;
			
			//if we haven't stunned him yet, go ahead and animate the progress
			if(!rm.rook_stun.stunned){
				if(rm.rook_stun.successful){
					var perc:Number = rm.rooked_status.stun/rm.rooked_status.max_stun;
					
					//show the stun text
					createStunText();
					if(model.flashVarModel.rook_show_damage){
						createDamageText(rm.rook_stun.damage, true);
					}
					
					//show the hit animation after a quick sec
					StageBeacon.setTimeout(RookManager.instance.animateRookHead, 500, RookHeadAnimationState.HIT, true);
					
					//update the stars after he shakes it off
					StageBeacon.setTimeout(updateStun, 1500, Number(perc.toFixed(2)));
				}
				else {
					// show the taunt animation
					RookManager.instance.animateRookHead(RookHeadAnimationState.TAUNT, true);
				}
			}
			//he's stunned, throw the progress to max
			else {
				updateStun(1);
				RookManager.instance.animateRookHead(RookHeadAnimationState.STUNNED, true);
			}
			
			//if there is a message, show it
			if(rm.rook_stun.txt){
				if(!model.flashVarModel.rook_show_damage){
					addPriorityMsg(rm.rook_stun.txt);
				}
			}
		}
		
		public function damage():void {
			if(!visible) return;
			
			//if he's not yet defeated, animate
			if(!rm.rook_damage.defeated){
				
				//show the hit
				RookManager.instance.animateRookHead(RookHeadAnimationState.HIT, true);
				if(model.flashVarModel.rook_show_damage){
					createDamageText(rm.rook_damage.damage, false);
				}
				
			}
			//he's toast, let the server call the end
			else {
				//setTimeout(end, 2000);
				RookManager.instance.animateRookHead(RookHeadAnimationState.DEAD, true);
			}
			
			//update health after
			var perc:Number = rm.rooked_status.health/rm.rooked_status.max_health;
			StageBeacon.setTimeout(updateHealth, 700, Number(perc.toFixed(2)));
			
			//if there is a message, show it
			if(rm.rook_damage.txt){
				if(!model.flashVarModel.rook_show_damage){
					addPriorityMsg(rm.rook_damage.txt);
				}
			}
		}
		
		public function addNormalMsg(txt:String):void {
			if (displaying_msg) {
				msgs_normalA.push(txt);
			} else {
				displayMsg(txt);
			}
		}
		
		private function addPriorityMsg(txt:String):void {
			if (displaying_msg) {
				msgs_priorityA.push(txt);
			} else {
				displayMsg(txt, 2);
			}
		}
		
		private var msgs_normalA:Array = [];
		private var msgs_priorityA:Array = [];
		private var displaying_msg:Boolean;
		private function displayMsg(txt:String, tween_delay:uint=0):void {
			displaying_msg = true;
			//animate a msg to show up under the rook's head
			msg_tf.htmlText = '<p class="rook_attack_msg">'+txt+'</p>';
			
			//draw the bg
			var g:Graphics = msg_holder.graphics;
			g.clear();
			g.beginFill(0xe6ecee, 1);
			g.drawRect(0, 0, MSG_WIDTH, 30);
			g.endFill();
			g.beginFill(model.layoutModel.bg_color, 1);
			g.drawRoundRect(0, 0, MSG_WIDTH, int(MSG_Y + msg_tf.height + 10), 6);
			
			//draw the mask
			g = msg_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRect(0, 0, MSG_WIDTH, msg_holder.height);
			
			//animate it
			if(TSTweener.isTweening(msg_holder)){
				TSTweener.removeTweens(msg_holder);
				tween_delay = 0;
			}
			else {
				msg_holder.y = model.layoutModel.header_h - msg_holder.height;
			}
			
			//animate it down
			TSTweener.addTween(msg_holder, {y:model.layoutModel.header_h, time:.5, delay:tween_delay});
			
			//set a delay to tween it away
			TSTweener.addTween(msg_holder, {delay:5+tween_delay, y:-msg_holder.height, time:.8, onComplete: afterMsgDisplay});
		}
		
		private function afterMsgDisplay():void {
			displaying_msg = false;
			checkForMoreMsgs();
		}
		
		private function checkForMoreMsgs():void {
			if (displaying_msg) return;
			if (msgs_priorityA.length) {
				displayMsg(msgs_priorityA.shift());
			} else if (msgs_normalA.length) {
				displayMsg(msgs_normalA.shift());
			}
		}
		
		private function removeAllTweens():void {
			TSTweener.removeTweens(this);
			current_phase = null;
			
			//empty out the TF container
			while(stun_tfs.length){
				stun_tfs[0] = null;
				stun_tfs.shift();
			}
		}
		
		private function updateHealth(perc:Number, animate:Boolean = true):void {
			//check if there is anything to do!
			if (isNaN(perc)) {
				CONFIG::debugging {
					Console.error('updateHealth passed a bad perc:'+perc)
				}
				return;
			}
			perc = Math.max(perc, 0);
			if(perc == health_percent_set_at) return;
			var full_animation:Boolean = health_percent_set_at == 0 && perc == 1;
			health_percent_set_at = perc;
			
			//set the rotation of the juice based on the percent, 0% = 180, 100% = 0
			var final_rotation:Number = (-180 * perc) + 180;
						
			if(!animate){
				CONFIG::debugging {
					Console.info('set final_rotation:'+health_juice.rotation+'->'+final_rotation)
				}
				health_juice.rotation = final_rotation;
			}
			else {
				//flashy flashy if it's taking damage
				if(!full_animation){
					var i:int;
					for(i; i < 6; i++){
						TSTweener.addTween(health_juice, { alpha:0, time:.1, delay:.1*(i*2), transition:'linear' });
						TSTweener.addTween(health_juice, { alpha:1, time:.1, delay:.1*(i*2+1), transition:'linear' });
					}
				}
				CONFIG::debugging {
					Console.info('animate final_rotation:'+health_juice.rotation+'->'+final_rotation)
				}
				TSTweener.addTween(health_juice, {rotation:final_rotation, time:full_animation ? FULL_ANIMATION_TIME : UPDATE_ANIMATION_TIME, transition:'linear'});
			}
		}
		
		private function updateStun(perc:Number, animate:Boolean = true):void {
			if(!stars_holder.numChildren || !stars_bg) return;
						
			//check if there is anything to do!
			perc = Math.min(perc, 1);
			if(perc == stun_percent_set_at) return;
			stun_percent_set_at = perc;
			
			//always show the single star as a base and then figure out the percent based on frame count
			const AVAIL_FRAMES:uint = (stars_holder.height/stars_bg.height);
			stars_y = -(stars_bg.height * Math.floor(AVAIL_FRAMES*perc)) + stars_bg.height;
			
			//make sure that if the stun percent is > 0, that we at least show the first star
			if(stun_percent_set_at > 0){
				stars_y = Math.min(0, stars_y);
			}
			
			//move the spritesheet if we need to
			if(!animate){
				stars_holder.y = stars_y;
			}
			else {
				//if we are moving up, flash the final count then animate it
				const FLASH_COUNT:uint = 5;
				var i:int;
				for(i; i < FLASH_COUNT; i++){
					TSTweener.addTween(stars_holder, { alpha:0, time:.1, delay:.1*(i*2), transition:'linear' });
					TSTweener.addTween(stars_holder, { alpha:1, time:.1, delay:.1*(i*2+1), transition:'linear' });
				}
				
				//after it flashes, animate from 0 to it's new spot
				StageBeacon.setTimeout(moveStars, 100*(FLASH_COUNT*2));
			}
		}
		
		private function moveStars():void {
			stars_holder.y = stars_bg.height;
			
			stars_timer.reset();
			stars_timer.stop();
			StageBeacon.setTimeout(stars_timer.start, 500);
		}
		
		private function createStunText():void {
			if(!rook_head || (rook_head && !rook_head.parent)) return;
			
			//not reusing a textfield in the event lots of stuns come in, it'll look more bad ass
			var i:int;
			var total:int = stun_tfs.length;
			var tf:TextField;
			
			//find one in the pool that isn't showing
			for(i; i < total; i++){
				if(stun_tfs[int(i)].alpha == 0){
					tf = stun_tfs[int(i)];
					break;
				}
			}
			
			//no tf? better whip one up
			if(!tf){
				tf = new TextField();
				TFUtil.prepTF(tf, false);
				
				stun_tfs.push(tf);
			}
			
			//animate it
			tf.alpha = 1;
			tf.htmlText = '<p class="rook_attack_stun">STUN!</p>';
			tf.filters = [stun_glow];
			tf.x = rook_head.x - tf.width/2 - 2;
			tf.y = rook_head.y - 17;
			/* //fade in the text
			tf.alpha = .01;
			TSTweener.addTween(tf, {alpha:1, time:.1, transition:'linear'});
			*/
			TSTweener.addTween(tf, {y:-35, alpha:0, time:.5, delay:.5,
				onComplete:function():void {
					//remove the tf
					if(rook_head.parent.contains(tf)) rook_head.parent.removeChild(tf);
				}
			});
			rook_head.parent.addChild(tf);
		}
		
		private function createDamageText(amount:int, is_stun:Boolean):void {
			if(!rook_head || (rook_head && !rook_head.parent)) return;
			
			//not reusing a textfield in the event lots of stuns come in, it'll look more bad ass
			var i:int;
			var total:int = stun_tfs.length;
			var tf:TextField;
			
			//find one in the pool that isn't showing
			for(i; i < total; i++){
				if(stun_tfs[int(i)].alpha == 0){
					tf = stun_tfs[int(i)];
					break;
				}
			}
			
			//no tf? better whip one up
			if(!tf){				
				tf = new TextField();
				TFUtil.prepTF(tf, false);
				
				stun_tfs.push(tf);
			}
			
			//animate it
			tf.alpha = 1;
			tf.htmlText = '<p class="rook_attack_damage"><span class="rook_attack_damage_'+(is_stun ? 'stun' : 'health')+'">'+amount+'</span></p>';
			tf.filters = [damage_glow];
			tf.x = rook_head.x - tf.width/2 - 2;
			tf.y = rook_head.y + 10;
			/* //fade in the text
			tf.alpha = .01;
			TSTweener.addTween(tf, {alpha:1, time:.1, transition:'linear'});
			*/
			TSTweener.addTween(tf, {y:rook_head.y + 35, alpha:0, time:.5, delay:(is_stun ? .4 : .6), 
				onComplete:function():void {
					//remove the tf
					if(rook_head.parent.contains(tf)) rook_head.parent.removeChild(tf);
				}
			});
			rook_head.parent.addChild(tf);
		}
		
		public function end():void {
			const self:RookIncidentHeaderView = this;
			TSTweener.addTween(this, { alpha:0, time:.5, transition:'linear',
				onComplete:function():void {
					self.visible = false;
					CONFIG::debugging {
						Console.warn('removeTweens')
					}
					removeAllTweens();
					RookManager.instance.animateRookHead(RookHeadAnimationState.IDLE, true);
					if(rook_head) rook_head.visible = false;
				}
			});
		}
		
		public function refresh():void {
			visible = rook_head ? rook_head.visible : false;
			if(!visible) return;
			
			x = Math.round(ydm.getHeaderCenterPt().x);
			
			//set the rook head
			if(rook_head && rook_head.parent){
				rook_head.x = x;
				rook_head.y = 45;
			}
		}
		
		public function get rook_head():DisplayObject { return RookManager.instance.getRookHead(); }
		
		/* Axed the timer feature
		private function onTimerTick(event:TSEvent):void {
			//show the time left
			if(event.data > 0){
				phase_time_tf.htmlText = '<p class="rook_attack_phase_time">'+
										(event.data < 60 ? '<span class="rook_attack_warn">' : '')+
										StringUtil.formatTime(event.data)+
										(event.data < 60 ? '</span>' : '')+
										'</p>';
			}
			
			phase_time_tf.visible = event.data > 0;
		}
		*/
		
		private function onStarTick(event:TimerEvent):void {
			//see which way we need to go
			if(stars_holder.y < stars_y){
				stars_holder.y += stars_bg.height;
			}
			else if(stars_holder.y > stars_y){
				stars_holder.y -= stars_bg.height;
			}
			else {
				stars_timer.stop();
			}
		}
	}
}