package com.tinyspeck.engine.model {
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.rook.RookDamage;
	import com.tinyspeck.engine.data.rook.RookStun;
	import com.tinyspeck.engine.data.rook.RookedStatus;
	import com.tinyspeck.engine.model.signals.AbstractPropertyProvider;
	
	import flash.utils.getTimer;
	
	public class RookModel extends AbstractPropertyProvider {
		public var max_strength:int = 5000;
		
		private var _countdown_first_delay_ms:int = 0;
		private var _countdown_steps_ms:int = 0;
		private var _countdown_last_delay_ms:int = 0;
		private var _fly_side_random_chance:int = 0;
		private var _fly_side_y_inc:int = 100;
		private var _fly_side_random_interv_ms:int = 10000;
		private var _fly_forward_initial_interv_ms:int = 10000;
		private var _fly_forward_later_interv_ms:int = 10000;
		private var _fly_side_sequence_interv_ms:int = 10000;
		private var _heal_interv_ms:int = 10000;
		private var _attack_interv_ms:int = 10000;
		private var _rav_chance_will_repeat_peck:int = 0;
		private var _rav_chance_will_move_offscreen:int = 0;
		private var _rav_chance_will_hop:int = 0;
		private var _rav_chance_will_peck:int = 0;
		private var _rav_chance_will_scratch:int = 0;
		private var _rav_chance_attack_loop_will_do_nothing:int = 100;
		private var _rav_chance_heal_loop_will_do_nothing:int = 100;
		private var _rav_placement_padd:int = 0;
		private var _rav_path_dist_min:int = 0;
		private var _rav_in_use_max:int = 0;
		private var _rav_peck_max:int = 0;
		private var _rav_scratch_max:int = 0;
		private var _rav_max_wh:int = 100;
		private var _rav_walk_pps:int = 100;
		private var _rav_hop_pps:int = 100;
		private var _rav_fly_pps:int = 100;
		private var _rav_min_wh:int = 100;
		private var _rav_peckA:Array = [];
		private var _rav_peck_damage_frame1A:Array = []; // maps which frames of the anims in _rav_peckA cause damage
		private var _rav_peck_damage_frame2A:Array = []; // maps which frames of the anims in _rav_peckA cause damage
		private var _rav_idleA:Array = [];
		private var _rav_hopA:Array = [];
		private var _rav_walk1A:Array = [];
		private var _rav_walk2A:Array = [];
		private var _rav_flyA:Array = [];
		private var _rav_rotateA:Array = [];
		private var _rav_damageA_to_peck_animA:Array = [];
		private var _rav_damageB_to_peck_animA:Array = [];
		private var _rav_damageC_to_peck_animA:Array = [];
		private var _rav_damageD_to_peck_animA:Array = [];
		private var _rav_damageE_to_peck_animA:Array = [];
		private var _rav_damageF_to_peck_animA:Array = [];
		private var _rooked_status:RookedStatus;
		private var _rook_stun:RookStun;
		private var _rook_damage:RookDamage;
		
		private var _rook_fly_side_random_cnt:int;
		private var _rook_fly_side_sequence_cnt:int;
		
		private var _rook_fly_forward_cnt:int;
		private var _min_fly_forward_cnt_for_attack:int = 0;
		
		private var _rook_wing_beat_cnt:int;
		private var _min_wing_beat_cnt_for_attack:int = 0;
		private var _attack_length_ms:int = 0;
		
		public var rook_incident_started_while_i_was_in_this_loc:Boolean;
		private var _rook_incident_is_running:Boolean;
		private var _rook_fly_side_sequence_is_running:Boolean;
		private var _rook_fly_side_random_is_running:Boolean;
		private var _rook_attack_is_running:Boolean;
		private var _rook_wing_beat_is_running:Boolean;
		private var _rook_fly_forward_is_running:Boolean;
		private var _rook_preview_msg_is_running:Boolean;
		
		private var _disable_fly_forward_bool:Boolean;
		
		private var _fly_side_layer_index:int;
		private var _fly_side_direction:int;
		private var _fly_side_middle_layer_index:int;
		private var _fly_side_animation_increment:Number;
		private var _incident_start:int;
		
		public var rav_center_to_beak:int = 215;
		
		public var preview_warning_anncsA:Array =  [
			{
				type: 'vp_canvas',
				uid: 'black_rook',
				canvas: {
					color: '#000000',
					steps: [
						{alpha:1, secs:1},
						{alpha:1, secs:1},
						{alpha:0, secs:1}
					]
				}
			},
			
			{
				uid: "rook_msg",
				type: "vp_overlay",
				duration: 2000,
				delay_ms:500,
				locking: false,
				width: 500,
				x: '50%',
				top_y: '40%',
				click_to_advance: false,
				text: [
					'<p align="center"><span class="nuxp_vog">¡Der Rook iz Coming!</span></p>',
				]
			}
		]
		
		public function RookModel() {
			super();
		}
		
		public function get attack_secs_running():int {
			return ((new Date().getTime()/1000)-rooked_status.start_time);
		}
		
		public function get rook_fly_side_sequence_is_running():Boolean { return _rook_fly_side_sequence_is_running; }
		public function set rook_fly_side_sequence_is_running(value:Boolean):void {
			_rook_fly_side_sequence_is_running = value;
			CONFIG::debugging {
				Console.trackRookValue('is rm.rook_fly_side_sequence_is_running', rook_fly_side_sequence_is_running);
			}
		}
		
		public function get rook_incident_is_running():Boolean { return _rook_incident_is_running; }
		public function set rook_incident_is_running(value:Boolean):void {
			_rook_incident_is_running = value;
			CONFIG::debugging {
				Console.trackRookValue('is rm.rook_incident_is_running', rook_incident_is_running);
			}
		}
		
		public function get rook_fly_side_random_is_running():Boolean { return _rook_fly_side_random_is_running; }
		public function set rook_fly_side_random_is_running(value:Boolean):void {
			_rook_fly_side_random_is_running = value;
			CONFIG::debugging {
				Console.trackRookValue('is rm.rook_fly_side_random_is_running', rook_fly_side_random_is_running);
			}
		}
		
		public function get rook_attack_is_running():Boolean { return _rook_attack_is_running; }
		public function set rook_attack_is_running(value:Boolean):void {
			_rook_attack_is_running = value;
			CONFIG::debugging {
				Console.trackRookValue('is rm.rook_attack_is_running', rook_attack_is_running);
			}
		}
		
		public function get rook_wing_beat_is_running():Boolean { return _rook_wing_beat_is_running; }
		public function set rook_wing_beat_is_running(value:Boolean):void {
			_rook_wing_beat_is_running = value;
			CONFIG::debugging {
				Console.trackRookValue('is rm.rook_wing_beat_is_running', rook_wing_beat_is_running);
			}
		}
		
		public function get rook_preview_msg_is_running():Boolean { return _rook_preview_msg_is_running; }
		public function set rook_preview_msg_is_running(value:Boolean):void {
			_rook_preview_msg_is_running = value;
			CONFIG::debugging {
				Console.trackRookValue('is rm.rook_preview_msg_is_running', rook_preview_msg_is_running);
			}
		}
		
		public function get rook_fly_forward_is_running():Boolean { return _rook_fly_forward_is_running; }
		public function set rook_fly_forward_is_running(value:Boolean):void {
			_rook_fly_forward_is_running = value;
			CONFIG::debugging {
				Console.trackRookValue('is rm.rook_fly_forward_is_running', rook_fly_forward_is_running);
			}
		}
		
		public function get disable_fly_forward_bool():Boolean { return _disable_fly_forward_bool; }
		public function set disable_fly_forward_bool(value:Boolean):void {
			_disable_fly_forward_bool = value;
			CONFIG::debugging {
				Console.trackRookValue('is rm.disable_fly_forward_bool', disable_fly_forward_bool);
			}
		}

		public function get rooked_status():RookedStatus { return _rooked_status; }
		public function set rooked_status(value:RookedStatus):void {
			_rooked_status = value;
			triggerCBPropDirect("rooked_status");
			CONFIG::debugging {
				Console.trackRookValue('rm.rooked_status', _rooked_status);
			}
		}
		
		public function get rook_stun():RookStun { return _rook_stun; }
		public function set rook_stun(value:RookStun):void {
			_rook_stun = value;
			//triggerCBPropDirect("rook_stun");
			CONFIG::debugging {
				Console.trackRookValue('rm.rook_stun', _rook_stun);
			}
		}
		
		public function get rook_damage():RookDamage { return _rook_damage; }
		public function set rook_damage(value:RookDamage):void {
			_rook_damage = value;
			//triggerCBPropDirect("rook_damage");
			CONFIG::debugging {
				Console.trackRookValue('rm.rook_damage', _rook_damage);
			}
		}
		
		public function get client_incident_start():int { return _incident_start; }
		public function set client_incident_start(value:int):void {
			_incident_start = value;
			CONFIG::debugging {
				Console.trackRookValue('cnt rm.incident_start', _incident_start);
			}
		}
		
		public function get rook_fly_side_random_cnt():int { return _rook_fly_side_random_cnt; }
		public function set rook_fly_side_random_cnt(value:int):void {
			_rook_fly_side_random_cnt = value;
			CONFIG::debugging {
				Console.trackRookValue('cnt rm.rook_fly_side_random_cnt', _rook_fly_side_random_cnt +' last at '+((getTimer()-client_incident_start)/1000).toFixed(1)+'s');
			}
		}
		
		public function get rook_fly_side_sequence_cnt():int { return _rook_fly_side_sequence_cnt; }
		public function set rook_fly_side_sequence_cnt(value:int):void {
			_rook_fly_side_sequence_cnt = value;
			CONFIG::debugging {
				Console.trackRookValue('cnt rm.rook_fly_side_sequence_cnt', _rook_fly_side_sequence_cnt +' last at '+((getTimer()-client_incident_start)/1000).toFixed(1)+'s');
			}
		}
		
		public function get rook_fly_forward_cnt():int { return _rook_fly_forward_cnt; }
		public function set rook_fly_forward_cnt(value:int):void {
			_rook_fly_forward_cnt = value;
			CONFIG::debugging {
				Console.trackRookValue('cnt rm.rook_fly_forward_cnt', _rook_fly_forward_cnt +' last at '+((getTimer()-client_incident_start)/1000).toFixed(1)+'s');
			}
		}
		
		public function get rook_wing_beat_cnt():int { return _rook_wing_beat_cnt; }
		public function set rook_wing_beat_cnt(value:int):void {
			_rook_wing_beat_cnt = value;
			CONFIG::debugging {
				Console.trackRookValue('cnt rm.rook_wing_beat_cnt', _rook_wing_beat_cnt +' last at '+((getTimer()-client_incident_start)/1000).toFixed(1)+'s');
			}
		}
		
		public function get countdown_first_delay_ms():int { return _countdown_first_delay_ms; }
		public function set countdown_first_delay_ms(value:int):void {
			_countdown_first_delay_ms = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.countdown_first_delay_ms', _countdown_first_delay_ms);
			}
		}
		
		public function get countdown_steps_ms():int { return _countdown_steps_ms; }
		public function set countdown_steps_ms(value:int):void {
			_countdown_steps_ms = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.countdown_steps_ms', _countdown_steps_ms);
			}
		}
		
		public function get countdown_last_delay_ms():int { return _countdown_last_delay_ms; }
		public function set countdown_last_delay_ms(value:int):void {
			_countdown_last_delay_ms = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.countdown_last_delay_ms', _countdown_last_delay_ms);
			}
		}
		
		public function get fly_side_random_chance():int { return _fly_side_random_chance; }
		public function set fly_side_random_chance(value:int):void {
			_fly_side_random_chance = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.fly_side_random_chance', _fly_side_random_chance);
			}
		}
		
		public function get fly_side_y_inc():int { return _fly_side_y_inc; }
		public function set fly_side_y_inc(value:int):void {
			_fly_side_y_inc = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.fly_side_y_inc', _fly_side_y_inc);
			}
		}
		
		public function get fly_forward_initial_interv_ms():int { return _fly_forward_initial_interv_ms; }
		public function set fly_forward_initial_interv_ms(value:int):void {
			_fly_forward_initial_interv_ms = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.fly_forward_initial_interv_ms', _fly_forward_initial_interv_ms);
			}
		}
		
		public function get fly_forward_later_interv_ms():int { return _fly_forward_later_interv_ms; }
		public function set fly_forward_later_interv_ms(value:int):void {
			_fly_forward_later_interv_ms = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.fly_forward_later_interv_ms', _fly_forward_later_interv_ms);
			}
		}
		
		public function get fly_side_sequence_interv_ms():int { return _fly_side_sequence_interv_ms; }
		public function set fly_side_sequence_interv_ms(value:int):void {
			_fly_side_sequence_interv_ms = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.fly_side_sequence_interv_ms', _fly_side_sequence_interv_ms);
			}
		}
		
		public function get fly_side_random_interv_ms():int { return _fly_side_random_interv_ms; }
		public function set fly_side_random_interv_ms(value:int):void {
			_fly_side_random_interv_ms = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.fly_side_random_interv_ms', _fly_side_random_interv_ms);
			}
		}
		
		public function get heal_interv_ms():int { return _heal_interv_ms; }
		public function set heal_interv_ms(value:int):void {
			_heal_interv_ms = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.heal_interv_ms', _heal_interv_ms);
			}
		}
		
		public function get attack_interv_ms():int { return _attack_interv_ms; }
		public function set attack_interv_ms(value:int):void {
			_attack_interv_ms = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.attack_interv_ms', _attack_interv_ms);
			}
		}
		
		public function get rav_chance_will_repeat_peck():int { return _rav_chance_will_repeat_peck; }
		public function set rav_chance_will_repeat_peck(value:int):void {
			_rav_chance_will_repeat_peck = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_chance_will_repeat_peck', _rav_chance_will_repeat_peck);
			}
		}
		
		public function get rav_chance_will_move_offscreen():int { return _rav_chance_will_move_offscreen; }
		public function set rav_chance_will_move_offscreen(value:int):void {
			_rav_chance_will_move_offscreen = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_chance_will_move_offscreen', _rav_chance_will_move_offscreen);
			}
		}
		
		public function get rav_chance_will_hop():int { return _rav_chance_will_hop; }
		public function set rav_chance_will_hop(value:int):void {
			_rav_chance_will_hop = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_chance_will_hop', _rav_chance_will_hop);
			}
		}

		public function get rav_chance_will_peck():int { return _rav_chance_will_peck; }
		public function set rav_chance_will_peck(value:int):void {
			_rav_chance_will_peck = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_chance_will_peck', _rav_chance_will_peck);
			}
		}

		public function get rav_chance_will_scratch():int { return _rav_chance_will_scratch; }
		public function set rav_chance_will_scratch(value:int):void {
			_rav_chance_will_scratch = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_chance_will_scratch', _rav_chance_will_scratch);
			}
		}
		
		public function get rav_chance_heal_loop_will_do_nothing():int { return _rav_chance_heal_loop_will_do_nothing; }
		public function set rav_chance_heal_loop_will_do_nothing(value:int):void {
			_rav_chance_heal_loop_will_do_nothing = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_chance_heal_loop_will_do_nothing', _rav_chance_heal_loop_will_do_nothing);
			}
		}
		
		public function get rav_chance_attack_loop_will_do_nothing():int { return _rav_chance_attack_loop_will_do_nothing; }
		public function set rav_chance_attack_loop_will_do_nothing(value:int):void {
			_rav_chance_attack_loop_will_do_nothing = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_chance_attack_loop_will_do_nothing', _rav_chance_attack_loop_will_do_nothing);
			}
		}

		public function get rav_placement_padd():int { return _rav_placement_padd; }
		public function set rav_placement_padd(value:int):void {
			_rav_placement_padd = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_placement_padd', _rav_placement_padd);
			}
		}

		public function get rav_path_dist_min():int { return _rav_path_dist_min; }
		public function set rav_path_dist_min(value:int):void {
			_rav_path_dist_min = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_path_dist_min', _rav_path_dist_min);
			}
		}

		public function get rav_in_use_max():int { return _rav_in_use_max; }
		public function set rav_in_use_max(value:int):void {
			_rav_in_use_max = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_in_use_max', _rav_in_use_max);
			}
		}

		public function get rav_peck_max():int { return _rav_peck_max; }
		public function set rav_peck_max(value:int):void {
			_rav_peck_max = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_peck_max', _rav_peck_max);
			}
		}
		
		public function get fly_side_layer_index():int { return _fly_side_layer_index; }
		public function set fly_side_layer_index(value:int):void {
			_fly_side_layer_index = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.fly_side_layer_index', _fly_side_layer_index);
			}
		}
		
		public function get fly_side_direction():int { return _fly_side_direction; }
		public function set fly_side_direction(value:int):void {
			_fly_side_direction = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.fly_side_direction', _fly_side_direction);
			}
		}
		
		public function get fly_side_middle_layer_index():int { return _fly_side_middle_layer_index; }
		public function set fly_side_middle_layer_index(value:int):void {
			_fly_side_middle_layer_index = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.fly_side_middle_layer_index', _fly_side_middle_layer_index);
			}
		}
		
		public function get fly_side_animation_increment():Number { return _fly_side_animation_increment; }
		public function set fly_side_animation_increment(value:Number):void {
			_fly_side_animation_increment = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.fly_side_animation_increment', _fly_side_animation_increment);
			}
		}
		
		public function get min_wing_beat_cnt_for_attack():int { return _min_wing_beat_cnt_for_attack; }
		public function set min_wing_beat_cnt_for_attack(value:int):void {
			_min_wing_beat_cnt_for_attack = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.min_wing_beat_cnt_for_attack', _min_wing_beat_cnt_for_attack);
			}
		}
		
		public function get attack_length_ms():int { return _attack_length_ms; }
		public function set attack_length_ms(value:int):void {
			_attack_length_ms = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.attack_length_ms', _attack_length_ms);
			}
		}
		
		public function get min_fly_forward_cnt_for_attack():int { return _min_fly_forward_cnt_for_attack; }
		public function set min_fly_forward_cnt_for_attack(value:int):void {
			_min_fly_forward_cnt_for_attack = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.min_fly_forward_cnt_for_attack', _min_fly_forward_cnt_for_attack);
			}
		}

		public function get rav_scratch_max():int { return _rav_scratch_max; }
		public function set rav_scratch_max(value:int):void {
			_rav_scratch_max = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_scratch_max', _rav_scratch_max);
			}
		}

		public function get rav_max_wh():int { return _rav_max_wh; }
		public function set rav_max_wh(value:int):void {
			_rav_max_wh = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_max_wh', _rav_max_wh);
			}
		}
		
		public function get rav_hop_pps():int { return _rav_hop_pps; }
		public function set rav_hop_pps(value:int):void {
			_rav_hop_pps = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_hop_pps', _rav_hop_pps);
			}
		}
		
		public function get rav_walk_pps():int { return _rav_walk_pps; }
		public function set rav_walk_pps(value:int):void {
			_rav_walk_pps = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_walk_pps', _rav_walk_pps);
			}
		}
		
		public function get rav_fly_pps():int { return _rav_fly_pps; }
		public function set rav_fly_pps(value:int):void {
			_rav_fly_pps = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_fly_pps', _rav_fly_pps);
			}				
		}

		public function get rav_min_wh():int { return _rav_min_wh; }
		public function set rav_min_wh(value:int):void {
			_rav_min_wh = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_min_wh', _rav_min_wh);
			}
		}
		
		public function get rav_damageA_to_peck_animA():Array { return _rav_damageA_to_peck_animA; }
		public function set rav_damageA_to_peck_animA(value:Array):void {
			_rav_damageA_to_peck_animA = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_damageA_to_peck_animA', _rav_damageA_to_peck_animA);
			}
		}
		
		public function get rav_damageB_to_peck_animA():Array { return _rav_damageB_to_peck_animA; }
		public function set rav_damageB_to_peck_animA(value:Array):void {
			_rav_damageB_to_peck_animA = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_damageB_to_peck_animA', _rav_damageB_to_peck_animA);
			}
		}
		
		public function get rav_damageC_to_peck_animA():Array { return _rav_damageC_to_peck_animA; }
		public function set rav_damageC_to_peck_animA(value:Array):void {
			_rav_damageC_to_peck_animA = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_damageC_to_peck_animA', _rav_damageC_to_peck_animA);
			}
		}
		
		public function get rav_damageD_to_peck_animA():Array { return _rav_damageD_to_peck_animA; }
		public function set rav_damageD_to_peck_animA(value:Array):void {
			_rav_damageD_to_peck_animA = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_damageD_to_peck_animA', _rav_damageD_to_peck_animA);
			}
		}
		
		public function get rav_damageE_to_peck_animA():Array { return _rav_damageE_to_peck_animA; }
		public function set rav_damageE_to_peck_animA(value:Array):void {
			_rav_damageE_to_peck_animA = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_damageE_to_peck_animA', _rav_damageE_to_peck_animA);
			}
		}
		
		public function get rav_damageF_to_peck_animA():Array { return _rav_damageF_to_peck_animA; }
		public function set rav_damageF_to_peck_animA(value:Array):void {
			_rav_damageF_to_peck_animA = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_damageF_to_peck_animA', _rav_damageF_to_peck_animA);
			}
		}
		
		public function get rav_peck_damage_frame2A():Array { return _rav_peck_damage_frame2A; }
		public function set rav_peck_damage_frame2A(value:Array):void {
			_rav_peck_damage_frame2A = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_peck_damage_frame2A', _rav_peck_damage_frame2A);
			}
		}
		
		public function get rav_peck_damage_frame1A():Array { return _rav_peck_damage_frame1A; }
		public function set rav_peck_damage_frame1A(value:Array):void {
			_rav_peck_damage_frame1A = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_peck_damage_frame1A', _rav_peck_damage_frame1A);
			}
		}
		
		public function get rav_peckA():Array { return _rav_peckA; }
		public function set rav_peckA(value:Array):void {
			_rav_peckA = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_peckA', _rav_peckA);
			}
		}

		public function get rav_idleA():Array { return _rav_idleA; }
		public function set rav_idleA(value:Array):void {
			_rav_idleA = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_idleA', _rav_idleA);
			}
		}
		
		public function get rav_walk1A():Array { return _rav_walk1A; }
		public function set rav_walk1A(value:Array):void {
			_rav_walk1A = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_walk1A', _rav_walk1A);
			}
		}
		
		public function get rav_walk2A():Array { return _rav_walk2A; }
		public function set rav_walk2A(value:Array):void {
			_rav_walk2A = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_walk2A', _rav_walk2A);
			}
		}
		
		public function get rav_hopA():Array { return _rav_hopA; }
		public function set rav_hopA(value:Array):void {
			_rav_hopA = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_hopA', _rav_hopA);
			}
		}
		
		public function get rav_flyA():Array { return _rav_flyA; }
		public function set rav_flyA(value:Array):void {
			_rav_flyA = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_flyA', _rav_flyA);
			}
		}

		public function get rav_rotateA():Array { return _rav_rotateA; }
		public function set rav_rotateA(value:Array):void {
			_rav_rotateA = value;
			CONFIG::debugging {
				Console.trackRookValue('rm.rav_rotateA', _rav_rotateA);
			}
		}
	}
}
