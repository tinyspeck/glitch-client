package com.tinyspeck.engine.model {
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.engine.model.signals.AbstractPropertyProvider;
	import com.tinyspeck.engine.physics.avatar.PhysicsSettables;
	import com.tinyspeck.engine.physics.data.PhysicsQuadtree;
	import com.tinyspeck.engine.physics.data.PhysicsQuery;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.StringUtil;
	
	import flash.geom.Rectangle;
	
	public class PhysicsModel extends AbstractPropertyProvider {
		public var physics_start_time:int;
		public var settables:PhysicsSettables;
		public var physicsQuadtree:PhysicsQuadtree;
		
		/** The immediate area around the avatar */
		public var lastAvatarQuery:PhysicsQuery;
		/** The area just beyond the current viewport */
		public var lastViewportQuery:PhysicsQuery;
		
		public var bounds:Rectangle;
		public var anim_state_land_limit_perc:Number = .3;
		public var anim_state_close_limit_perc:Number = .3;
		public var anim_state_close_limit_max:Number = 0;
		public const path_end_allowance:int = 20;
		public const gs_path_end_allowance:int = 10;
		public const triple_jump_allowance_ms:uint = 500;
		public var triple_jump_multiplier_overide:Number = 0; // set to non zero to test triple jump multiplier effects
		public var wall_jump_multiplier_x:Number = .4;
		public var wall_jump_multiplier_y:Number = 1.1;
		
		// location_breathing_allowance gives some breathing room to the mainNode rect in the quad tree, so that things
		// (doors, ladders, etc) slightly out of bounds will still be in the rect; the value is the amount to increase the width and height by
		public var location_breathing_allowance:int = 220;
		
		// how close to a stack do we have to be to do a verb
		public var required_verb_proximity:int = 200;
		
		// we want the avatar to be able to go off screen above location
		public var location_top_allowance:int = 110;
		
		private var _ignore_pc_adjustments:Boolean;
		public function get ignore_pc_adjustments():Boolean { return _ignore_pc_adjustments; }
		public function set ignore_pc_adjustments(value:Boolean):void {
			_ignore_pc_adjustments = value;
			triggerCBPropDirect("ignore_pc_adjustments");
		}
		
		private var _pc_adjustments:Object;
		public function get pc_adjustments():Object { return _pc_adjustments; }
		public function set pc_adjustments(value:Object):void {
			CONFIG::debugging {
				if (TSModelLocator.instance.flashVarModel.benchmark_physics_adjustments) {
					Benchmark.addCheck('PhysicsModel.pc_adjustments:\n' +
						'\tWAS:\n' + StringUtil.deepTrace(_pc_adjustments) +
						'\tNOW:\n' + StringUtil.deepTrace(value));
				}
			}
			_pc_adjustments = value;
			triggerCBPropDirect("pc_adjustments");
		}
		
		public function PhysicsModel() {
			settables = new PhysicsSettables();
			physicsQuadtree = new PhysicsQuadtree();
			
			anim_state_land_limit_perc = CSSManager.instance.getNumberValueFromStyle('physics', 'anim_state_land_limit_perc', anim_state_land_limit_perc);
			anim_state_close_limit_perc = CSSManager.instance.getNumberValueFromStyle('physics', 'anim_state_close_limit_perc', anim_state_close_limit_perc);
			anim_state_close_limit_max = CSSManager.instance.getNumberValueFromStyle('physics', 'anim_state_close_limit_max', anim_state_close_limit_max);
		}
		
		// these are used by PhysicsLoopRenderer:
		public var physics_time_log:Array = [];
		public var render_time_log:Array = [];
		// amount of ms to hold in log arrays:
		private var log_limit:int = 1500; 
		public function logLoop(logA:Array, newTime:int):void {
			while (logA.length > 1 && logA[logA.length-1]-logA[0] > log_limit) logA.shift();
			logA.push(newTime);
		}
	}
}