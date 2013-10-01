package com.tinyspeck.engine.view.effects {
import com.tinyspeck.core.beacon.StageBeacon;
import com.tinyspeck.core.memory.DisposableSprite;
import com.tinyspeck.debug.Console;
import com.tinyspeck.engine.control.TSFrontController;
import com.tinyspeck.engine.data.pc.PC;
import com.tinyspeck.engine.model.MoveModel;
import com.tinyspeck.engine.model.TSModelLocator;
import com.tinyspeck.engine.physics.avatar.PhysicsSetting;
import com.tinyspeck.engine.port.IDisposableSpriteChangeHandler;
import com.tinyspeck.engine.util.MathUtil;
import com.tinyspeck.engine.util.SpriteUtil;
import com.tinyspeck.engine.view.AbstractAvatarView;
import com.tinyspeck.tstweener.TSTweener;

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.utils.getTimer;

import org.osflash.signals.Signal;

public final class Missile extends Sprite implements IDisposableSpriteChangeHandler {
	// increment this when you make substantial changes to the speed up algo!!!
	private const ALGO_VERSION:uint = 10;
	
	
	private const PX_PER_SEC_ADD_IN:uint = 40;
	private const PX_PER_SEC_START:uint = 250;
	private const PX_PER_SEC_OVERAGE_START:uint = 190;
	private const SECS_TIL_ACCEL:int = 1;
	private const SECS_TIL_MAX_INCREASE:uint = 300;
	private const MAX_ADD_IN_PER_SEC:uint = 1;
	private const BOB_SECS:Number = .2;
	private const BOB_AMT:uint = 15;
	private const SECS_TIL_COLLISION_DIST_INCREASE:uint = 312;
	private const COLLISION_DIST_MIN:int = 25;
	private const COLLISION_DIST_MAX:int = 50;
	
	private var collision_dist:Number;
	private var door_moves:int;
	private var vx_max:Number;
	private var vy_max:Number;
	private var vy_jump:Number;
	private var jetpack:Boolean;
	
	private var last_now:int;
	private var bad_elapsed:String;
	private var bad_px_per_sec:String;
	
	private var secs_running:int;
	private var x_dest:int;
	private var y_dest:int;
	private var target_x_delta:int;
	private var target_y_delta:int;
	private var target:DisposableSprite;
	private var target_pc:PC;
	private var mood_granted:int;
	private var DO:DisplayObject;
	private var start_time:int;
	private var px_per_sec_max:int;
	private var px_per_sec_overage:int; // this is how much faster than the location's vx_max/vy_max the missile will move
	private var px_per_sec:int;
	private var registered:Boolean;
	private var model:TSModelLocator;
	private var from_tsid:String;
	private var last_target_y:int;
	private var slow_down_amount:Number;
	private var _accelerate:Boolean;
	private var frames:int;
	
	private var min_elapsed:int;
	private var max_elapsed:int;
	
	public function get accelerate():Boolean {
		return _accelerate;
	}

	
	public var running:Boolean;
	public var arrived_sig:Signal = new Signal(Missile, String, DisplayObject, int, int, int, Object);
	
	public function Missile() {
		model = TSModelLocator.instance;
	}
	
	public function launch(accelerate:Boolean, from_tsid:String, mood_granted:int, DO:DisplayObject, x:int, y:int, target:DisposableSprite, target_x_delta:int=0, target_y_delta:int=0):void {
		if (running) {
			CONFIG::debugging {
				Console.error('No going when running!');
			}
			return;
		}
		
		running = true;
		
		frames = 0;
		bad_elapsed = null;
		bad_px_per_sec = null;
		last_now = getTimer();
		min_elapsed = 22222222;
		max_elapsed = -22222222;
		secs_running = 0;
		start_time = getTimer();
		collision_dist = COLLISION_DIST_MIN;
		px_per_sec_overage = PX_PER_SEC_OVERAGE_START;
		px_per_sec = PX_PER_SEC_START;
		door_moves = 0;
		vx_max = 0;
		vy_max = 0;
		vy_jump = 0;
		jetpack = false;
		
		_accelerate = accelerate;
		this.from_tsid = from_tsid;
		this.mood_granted = mood_granted;
		this.DO = DO;
		this.x = x;
		this.y = y;
		this.target = target;
		this.target_x_delta = target_x_delta;
		this.target_y_delta = target_y_delta;
		
		if (target is AbstractAvatarView) {
			target_pc = model.worldModel.getPCByTsid(AbstractAvatarView(target).tsid);
			if (target_pc == model.worldModel.pc) {
				model.physicsModel.registerCBProp(onPcAdjustmentsChange, "pc_adjustments");
				onPcAdjustmentsChange(null);
			}
		} else {
			target_pc = null;
		}
		
		slow_down_amount = 0;
		setMaxPxPerSec();
		
		addChild(DO);
		startBob();
		
		animateTo(target.x+target_x_delta, target.y+target_y_delta);
		
		if (accelerate) {
			StageBeacon.game_loop_sig.add(onGameLoop);
			StageBeacon.enter_frame_sig.add(onFrameEnter);
			model.moveModel.move_was_in_location_sig.add(onInLocatioMove);
		} else {
			registered = true;
			TSFrontController.instance.registerDisposableSpriteChangeSubscriber(this, target);
		}
		
		alpha = 0;
		TSTweener.addTween(this, {alpha:1, time:.1, delay:0, transition:'easeInExpo'});
	}
	
	// let's remember the the top values for these, for logging
	private function onPcAdjustmentsChange(adjustments:Object):void {
		if (target_pc.apo.setting.vx_max > vx_max) vx_max = target_pc.apo.setting.vx_max;
		if (target_pc.apo.setting.vy_max > vy_max) vy_max = target_pc.apo.setting.vy_max;
		if (target_pc.apo.setting.vy_jump < vy_jump) vy_jump = target_pc.apo.setting.vy_jump;
		if (target_pc.apo.setting.jetpack || model.worldModel.pc.apo.base_setting.jetpack) jetpack = true;
		/*
		Console.info('vx_max:'+target_pc.apo.setting.vx_max+' '+vx_max);
		Console.info('vy_max:'+target_pc.apo.setting.vy_max+' '+vy_max);
		Console.info('vy_jump:'+target_pc.apo.setting.vy_jump+' '+vy_jump);
		Console.info('jetpack:'+target_pc.apo.setting.jetpack+' '+jetpack);
		*/
	}
	
	private function onInLocatioMove(move_type:String):void {
		if (!target_pc) return;
		
		// sadly this check means observers wont see the same speed up as the person evading does
		// but we don't yet have a way to know when another player has been moved in location
		if (target_pc != model.worldModel.pc) return;
		
		if (move_type != MoveModel.DOOR_MOVE && move_type != MoveModel.SIGNPOST_MOVE) return;
		
		door_moves++;
		
		// make it faster!
		px_per_sec_overage+= 70;
	}
	
	private function setMaxPxPerSec():void {
		// we use model.worldModel.pc here to get the base_setting, because we know it will have the location physics
		var base_setting:PhysicsSetting = model.worldModel.pc.apo.base_setting;
		
		if (target_pc && target_pc.apo.setting.jetpack) {
			px_per_sec_max = base_setting.vy_max+px_per_sec_overage;
		} else {
			px_per_sec_max = base_setting.vx_max+px_per_sec_overage;
		}
		
		if (secs_running > SECS_TIL_MAX_INCREASE) {
			px_per_sec_max+= (secs_running-SECS_TIL_MAX_INCREASE)*MAX_ADD_IN_PER_SEC;
		}
	}
	
	private function onFrameEnter(ms_elapsed:int):void {
		if (!running) {
			// we should never get here, but just in case...
			StageBeacon.game_loop_sig.remove(onGameLoop);
			StageBeacon.enter_frame_sig.remove(onFrameEnter);
			return;
		}
		
		frames++;
	}
	
	private function onGameLoop(ms_elapsed:int):void {
		if (!running) {
			// we should never get here, but just in case...
			StageBeacon.game_loop_sig.remove(onGameLoop);
			StageBeacon.enter_frame_sig.remove(onFrameEnter);
			return;
		}
		
		if (ms_elapsed < 0 && !bad_elapsed) {
			bad_elapsed = 'ms_elapsed:'+ms_elapsed;
		}
		 
		secs_running = Math.floor(time_running/1000);
		
		setMaxPxPerSec();
		
		if (secs_running > SECS_TIL_COLLISION_DIST_INCREASE && collision_dist < COLLISION_DIST_MAX) {
			collision_dist = COLLISION_DIST_MIN + (secs_running-SECS_TIL_COLLISION_DIST_INCREASE);
			collision_dist = MathUtil.clamp(COLLISION_DIST_MIN, COLLISION_DIST_MAX, collision_dist)
		}
		
		// we use model.worldModel.pc here to get the base_setting, because we know it will have the location physics
		var base_setting:PhysicsSetting = model.worldModel.pc.apo.base_setting;
		
		const perc_of_ideal:Number = ms_elapsed/17;
		
		// if we've been running for SECS_TIL_ACCEL, make it faster
		var add_in:int = 0;
		if (secs_running > SECS_TIL_ACCEL) {
			add_in = (secs_running-SECS_TIL_ACCEL)*PX_PER_SEC_ADD_IN;
		}
		
		//speed it up
		px_per_sec = Math.min(px_per_sec_max, PX_PER_SEC_START + add_in);
		if (px_per_sec < 0 && !bad_px_per_sec) {
			bad_px_per_sec = 'px_per_sec:'+px_per_sec+' px_per_sec_max:'+px_per_sec_max+' add_in:'+add_in+' secs_running:'+secs_running;
		}
		
		// if this is negative the user is moving up
		var y_change:int = (target.y-last_target_y);
		
		var slow_down_increased:int = -1; // and oops, I mark this 1 or 0 wrong below, but I am leaving it for logs consistency
		if (px_per_sec > base_setting.vx_max && y_change < -5) {
			// if jumping up, we can reduce px_per_sec a bit
			slow_down_increased = 0;
			slow_down_amount = Math.min(px_per_sec_overage+10, slow_down_amount+(6*perc_of_ideal));
		} else if (slow_down_amount) {
			// otherwise reduce the slow_down_amount slightly
			slow_down_increased = 1;
			slow_down_amount*= (.97*perc_of_ideal);
		}
		
		px_per_sec = Math.max(px_per_sec-slow_down_amount, PX_PER_SEC_START);
		
		if (px_per_sec < 0 && !bad_px_per_sec) {
			
			/*
			bad_px_per_sec:
			px_per_sec:-134
			slow_down_amount:624.5398710743801
			slow_down_increased:1
			perc_of_ideal:2.9393939393939394
			*/
			
			bad_px_per_sec = 'px_per_sec:'+px_per_sec+' slow_down_amount:'+slow_down_amount+' slow_down_increased:'+slow_down_increased+' perc_of_ideal:'+perc_of_ideal;
		}
		
		last_target_y = target.y;
		
		CONFIG::debugging {
			Console.trackValue('     msl vy_max', base_setting.vy_max);
			Console.trackValue('     msl vx_max', base_setting.vx_max);
			Console.trackValue('     msl px_per_sec_max', px_per_sec_max);
			Console.trackValue('     msl jetpack', (target_pc)?target_pc.apo.setting.jetpack:'?');
			Console.trackValue('     msl ms_elapsed', ms_elapsed);
			Console.trackValue('     msl perc_of_ideal', perc_of_ideal);
			Console.trackValue('     msl px_per_sec', px_per_sec);
			Console.trackValue('     msl y_change', y_change);
			Console.trackValue('     msl slow_down_amount', slow_down_amount);
		}
		
		const to_x:int = target.x+target_x_delta;
		const to_y:int = target.y+target_y_delta;
		
		if (to_x == x_dest && to_y == y_dest) return;
		
		animateTo(to_x, to_y);
	}
	
	private function startBob():void {
		if (!BOB_AMT) return;
		if (TSTweener.isTweening(DO)) return;
		doBob(MathUtil.randomInt(0, 10)*.1);
	}
	
	private function doBob(delay:Number=0):void {
		var new_y:int = (DO.y<0) ? BOB_AMT : -BOB_AMT;
		var time:Number = BOB_SECS+(MathUtil.randomInt(-1, 1)*.05);
		TSTweener.addTween(DO, {y: new_y, time: time, delay:0, transition: 'easeInOutSine', onComplete:doBob});
	}
	
	private function stopBob():void {
		if (!BOB_AMT) return;
		if (TSTweener.isTweening(DO)) TSTweener.removeTweens(DO, 'y');
	}
	
	private function get time_running():int {
		var now:int = getTimer();
		var val:int = now-start_time;
		var elapsed:int = now-last_now;
		if (elapsed < 0 && !bad_elapsed) {
			bad_elapsed = 'elapsed:'+elapsed+' now:'+now+' last_now:'+last_now;
		}
		if (elapsed < min_elapsed) min_elapsed = elapsed;
		if (elapsed > max_elapsed) max_elapsed = elapsed;
		last_now = now;
		return val;
	}
	
	private function hasArrived():void {
		if (accelerate) {
			
			const targ_x:int = (target.x+target_x_delta);
			const targ_y:int = (target.y+target_y_delta);
			const dx:Number = targ_x - this.x;
			const dy:Number = targ_y - this.y;
			const dist:Number = Math.abs(Math.sqrt(dx * dx + dy * dy));

			if (dist > collision_dist) {
				// make sure we keep going
				animateTo(targ_x, targ_y);
				return;				
			}
		}
		
		halt();
		
		var log_data:Object = {
			vx_max:vx_max,
			vy_max:vy_max,
			vy_jump:vy_jump,
			px_per_sec:px_per_sec,
			max_elapsed: max_elapsed,
			min_elapsed: min_elapsed,
			fps: Math.round(frames/Math.round(time_running/1000)),
			jetpack:jetpack?1:0,
			collision_dist:collision_dist
		}
			
		if (bad_elapsed) log_data.bad_elapsed = bad_elapsed;
		if (bad_px_per_sec) log_data.bad_px_per_sec = bad_px_per_sec;
		
		arrived_sig.dispatch(this, from_tsid, target, mood_granted, time_running, ALGO_VERSION, log_data);
		
		TSTweener.addTween(this, {alpha:0, delay:0, time:.5, transition:'easeOutExpo', onComplete:reset});
	}
	
	private function halt():void {
		model.physicsModel.unRegisterCBProp(onPcAdjustmentsChange, "pc_adjustments");
		StageBeacon.game_loop_sig.remove(onGameLoop);
		StageBeacon.enter_frame_sig.remove(onFrameEnter);
		model.moveModel.move_was_in_location_sig.remove(onInLocatioMove);
		TSTweener.removeTweens(this);
		if (registered) {
			registered = false;
			TSFrontController.instance.unregisterDisposableSpriteChangeSubscriber(this, target);
		}
		stopBob();
	}
	
	public function cancel():void {
		reset();
	}
	
	private function reset():void {
		if (parent) parent.removeChild(this);
		halt();
		SpriteUtil.clean(this);
		arrived_sig.removeAll();
		
		target_pc = null
		from_tsid = null;
		mood_granted = 0;
		DO = null;
		target = null;
		target_x_delta = 0;
		target_y_delta = 0;
		running = false;
		start_time = 0;
	}
	
	private function getDuration(x1:int, y1:int, x2:int, y2:int):Number {
		const dx:Number = x1 - x2;
		const dy:Number = y1 - y2;
		const dist:Number = Math.sqrt(dx * dx + dy * dy);
		const duration:Number = Math.abs(dist / px_per_sec);
		return duration;
	}
	
	private function animateTo(x_dest:int, y_dest:int):void {
		this.x_dest = x_dest;
		this.y_dest = y_dest;
		TSTweener.removeTweens(this, 'x', 'y');
		TSTweener.addTween(this, {x:x_dest, y:y_dest, time:getDuration(x, y, x_dest, y_dest), transition:'linear', onComplete:hasArrived});
	}
	
	public function worldDisposableSpriteDestroyedHandler(sp:DisposableSprite):void {
		cancel();
	}
	
	public function worldDisposableSpriteSubscribedHandler(sp:DisposableSprite):void {

	}
	
	public function worldDisposableSpriteChangeHandler(sp:DisposableSprite):void {
		if (!sp) return;
		
		const to_x:int = sp.x+target_x_delta;
		const to_y:int = sp.y+target_y_delta;
		
		if (to_x == x_dest && to_y == y_dest) return;
		
		animateTo(to_x, to_y);
	}
}
}