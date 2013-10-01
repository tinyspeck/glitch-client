package com.tinyspeck.bridge
{
	import com.adobe.serialization.json.JSON;
	import com.tinyspeck.core.data.FlashVarData;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.model.TSEngineConstants;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.StringUtil;
	
	public class FlashVarModel
	{
		public var flashVarData:FlashVarData;
		
		// urls
		public var assetsUrl:String;
		public var engineUrl:String;
		public var avatar_url:String;
		public var load_progress_swf_url:String;
		public var login_host:String;
		public var token:String;
		public var client_ip:String;
		public var sounds_file:String;
		public var root_url:String;
		public var api_url:String;
		public var api_token:String;
		public var placeholder_sheet_url:String;
		public var pc_sheet_url:String;
		public var auto_reloaded_after_error:Boolean;
		public const extra_loads_urls:Array = [];
		
		// performance testing
		/** When true, will run tests in test_location */
		CONFIG::perf public var run_automated_tests:Boolean;
		CONFIG::perf public var test_chat_filler:Boolean;
		CONFIG::perf public var empty_test_location:String;
		CONFIG::perf public var test_locations:Array;
		CONFIG::perf public var current_trial_name:String;
		
		// logging / debug
		public var newxp_log_step:int;
		public var session_id:String;
		public var disable_bug_reporting:Boolean = false;
		public var priority:String;
		public var log_to_scribe:Boolean;
		public var log_to_firebug:Boolean;
		public var log_to_trace:Boolean;
		public var max_vp_dims:String;
		public var report_rendering:Boolean;
		public var show_benchmark:Boolean;
		public var show_buildtime:Boolean;
		public var avatar_trail_buffer:Boolean = false;
		public var no_bug:Boolean = !CONFIG::god;
		public var sprite_sheet_decos_copypixels:Boolean = false;	// used to test sprite sheeting of animated decos
		public var sprite_sheet_decos_bitmapfill:Boolean = false;	// used to test sprite sheeting of animated decos
		
		// data
		public var pc_tsid:String;
		public var local_pc:String;
		public var player_is_subscriber:Boolean;
		public var player_had_free_sub:Boolean;
		
		// physics
		CONFIG::god public var interact_with_all:Boolean; // force DEV client to not obey itemstack.is_selectable
		CONFIG::debugging public var benchmark_physics_adjustments:Boolean;
		public var use_vec:Boolean;
		public var snap_distance:int = 10;
		public var vp_rect_collision_scale:Number = 1.35;
		public var limited_rendering:Boolean = true;
		public var no_pc_collision:Boolean;
		public var no_item_collision:Boolean;
		public var no_geo_collision:Boolean;
		public var new_physics:Boolean = false;
		public var avg_enter_frame_ms:Boolean = false;
		public var irregular_gl:Boolean = false;
		public var lie_about_gl:Boolean = true;
		public var sleep_ms:Number = 0;
		public var tween_camera:Boolean = false;
		public var tween_camera_time:Number = .3;
		public var ava_anim_time:Number = 0;
		public var run_mv_from_aph:Boolean = false;
		public var run_av_from_aph:Boolean = false;
		
		// renderer
		CONFIG::god public var draw_plats:Boolean;
		public var vp_scale:Number = 1;
		public var fps:int;
		public var no_render_stacks:Boolean;
		public var no_render_pcs:Boolean;
		public var no_render_decos:Boolean;
		public var only_mg:Boolean;
		public var no_quoins:Boolean;
		public var is_home_standalone:Boolean = true;
		public var bitmap_renderer:Boolean = false;
		public var vector_renderer:Boolean = false;
		public var dispose_unused_templates:Boolean = true;
		/** Render locations asynchronously across frames */
		public var async_rendering:Boolean = true;
		/**
		 * How long to render before rendering another frame, in ms.
		 * 
		 * There's a direct correlation with how much we might affect the FPS
		 * from this value. If the value is less than the number of ms/frame
		 * then we are wasting usable time per frame but running at full FPS.
		 * If the value is larger than ms/frame, then we are skipping frames
		 * but working faster, but the game will be less responsive.
		 * 
		 * Example (assuming 10ms of overhead per frame, and 1 second of work):
		 * 1000ms timeslice  =   1 frame  (1010ms @  1 FPS) [0%   increase]
		 *  500ms timeslice  =   2 frames (1020ms @  2 FPS) [2%   increase]
		 *  100ms timeslice  =  10 frames (1100ms @  9 FPS) [10%  increase]
		 *   50ms timeslice  =  20 frames (1200ms @ 17 FPS) [20%  increase]
		 *   23ms timeslice  =  44 frames (1452ms @ 30 FPS) [45%  increase]
		 *   10ms timeslice  = 100 frames (3300ms @ 30 FPS) [230% increase]
		 */
		public var async_timeslice_ms:int = 50;
		/** In the bitmap_renderer, draw using an intermediate bitmap */
		public var use_intermediate_bitmap:Boolean = false;
		/**
         * In the bitmap_renderer, hflip using an intermediate bitmap
         * rather than with a matrix transformation; prevents the game from
         * crashing due to the Devil Pixel in the texture of some Firebog
         * assets when they are hflipped
         */
		public var hflip_hack:Boolean = true;
		/**
		 * Uses an alternate color matrix generating algorithm (that we ended
		 * up liking a lot better):
		 * http://wiki.tinyspeck.com/wiki/Testing_the_New_Filter_Code
		 */
		public var alt_color_matrix:Boolean = true;
		public var multiswf:Boolean = true;
		public var multiswf_cache:Boolean = true;
		public var placement_plat_anim:Boolean;
		CONFIG::god public var debug_placement_plat_anim:Boolean;
		public var no_layer_filters:Boolean = false;
		public var min_zoom:Number = 0;
		public var max_zoom:Number = 1;
		public var zoom_step:Number = 0.05;
		public var auto_zoom_ms:Number = 0.6;
		public var render_fewer_itemstacks:Boolean = false;
		public var render_fewer_itemstacks_distance:uint = 100;
		/** Render itemstack spritesheets asynchronously across frames */
		public var async_spritesheeting:Boolean = false;
		
		// avatars
		public var no_landing:Boolean = false;
		public var ava_settings:Object;
		public var display_ava_path:Boolean;
		public var name_on_avatar:Boolean;
		public var no_avatar_anim:Boolean;
		public var use_default_ava:Boolean;
		CONFIG::perf public var use_default_ava_except_for_player:Boolean;
		
		// layout
		public var colors_from_loc:Boolean;
		public var css_file:String;
		
		// editing
		public var edit_loc:Boolean;
		public var locodeco_url:String;
		public var debug_decorator_mode:Boolean;
		CONFIG::god public var debug_cult:Boolean;
		
		// performance
		public var cleanup_ms:int = 30000;
		/** Whether SWF throttling on deactivation ever occurs */
		public var throttle_swf:Boolean = true;
		/** What FPS to throttle the SWF to when deactivated */
		public var throttle_fps:Number = 1;
		/** In milliseconds, how long after deactivation before we throttle the SWF */
		public var throttle_delay:Number = 120*1000;
		/** Opacity of throttle view */
		public var throttle_opacity:Number = 0.65;
		/** Whether setTimeouts are native Flash or use SetTimeoutController */
		public var use_set_timeout_controller:Boolean = false;
		/** Whether InterruptableWorkers continue on the next frame or possibly sooner */
		public var workers_wait_until_next_frame:Boolean = false;
		public var reload_hourly:Boolean = false;
		/** Whether or not to use custom movement controller for TSSprite */
		public var use_movement_controller:Boolean = true;
		/** Whether PerformanceMonitor is active */
		public var display_performance_tips:Boolean = true;
		public var use_tweenmax:Boolean = false;
		
		// UI
		/** Better support for non-QWERTY keyboards */
		public var alt_keyboard_support:Boolean = true;
		public var use_local_trade:Boolean;
		public var show_click_to_focus:Boolean = false;
		public var more_towers:Boolean = true;
		public var keep_buff_names:Boolean;
		public var use_economy_info:Boolean = true; //Set Oct. 29, 2012
		public var new_loading_screen:Boolean;
		public var run_globometer_backwards:Boolean = true;
		
		// dunno / temp
		public var furniture_placed_normally_on_pl_plats:Boolean;
		public var stack_furn_bag:Boolean = true;
		public var show_tree_str:Boolean = false;
		public var fake_prompts:Boolean;
		public var max_buy_override:int;
		public var player_open_cases:int;
		public var rook_show_damage:Boolean = true;
		public var show_scores:Boolean;
		public var view_api_output:Boolean;
		public var qp_in_im:Boolean = true;
		public var go_in_qp_in_im:Boolean = true;
		public var ok_on_info:Boolean = true;
		public var dont_move_for_item_menu:Boolean = true;
		public var check_for_proximity:Boolean = true;
		public var do_single_interaction_sp_keys:Boolean = false;
		public var use_glitchr_filters:Boolean = true;
		public var item_animate_duration:Number = .35; //location_events get sent every 300 ms, but using .35 allows a little breathing room so the animation is not jerky if there is normal lag that delays the msgs
		public var no_deco_disclaimer:Boolean = true;
		public var change_state_when_still:Boolean = false;
		public var new_furn_up:Boolean = true;
		public var better_focus_handling:Boolean = true;
		public var is_stub_account:Boolean;
		public var has_not_done_intro:Boolean;
		public var needs_todo_leave_gentle_island:Boolean;
		public var no_boot_message:Boolean;
		public var boot_message:String;
		public var boot_message_prefix:String;
		public var placehold_itemstacks:Boolean;
		public var show_missing_itemstacks:Boolean = true;
		public var break_item_asset_loading:Boolean;
		public var preload_sounds:Boolean;
		public var break_item_assets:String;
		public var hi_viral:Boolean = true;
		public var fast_update_hi_counts:Boolean = false;
		
		public function FlashVarModel(flashVarData:FlashVarData) {
			this.flashVarData = flashVarData;
			
			new_loading_screen = get('new_loading_screen') == '1';
			
			var ava_settings_json:String = get('ava_settings_json');
			if (ava_settings_json) {
				ava_settings = com.adobe.serialization.json.JSON.decode(ava_settings_json);
			}
			
			CONFIG::debugging {
				if (!ava_settings) {
					Console.warn('no ava_settings!');
				}
			}
			
			var extra_loads_urls_str:String = get('extra_loads_urls_str');
			if (extra_loads_urls_str) {
				var A:Array = extra_loads_urls_str.split(',');
				for each (var url:String in A) {
					url = StringUtil.trim(url);
					if (url && extra_loads_urls.indexOf(url) == -1) {
						extra_loads_urls.push(url);
					}
				}
			}
			
			player_open_cases = get('player_open_cases', 'Number');
			root_url = get('root_url') || "http://dev.glitch.com/";
			root_url = get('SWF_root_url') || root_url;
			assetsUrl = get('assets_url') || "ERROR";
			engineUrl = get('engine_url') || "ERROR";
			avatar_url = get('avatar_url');
			load_progress_swf_url = get('load_progress_swf_url');
			auto_reloaded_after_error = valueWhenOffByDefault('SWF_auto_reloaded_after_error');
			pc_tsid = get('pc_tsid');
			locodeco_url = (get('locodeco_url') || "ERROR");
			snap_distance = get('SWF_snap_distance', 'Number') || snap_distance;
			
			priority = get('SWF_pri');
			local_pc = get('SWF_local_pc');
			if (!pc_tsid) pc_tsid = local_pc;
			login_host = get('login_host');
			token = get('wittgensteins_mistress');
			client_ip = get('client_ip') || 'unknown' + (CONFIG::localhost ? ' (localhost build)' : '');
			log_to_trace = valueWhenOnByDefault('SWF_trace');
			log_to_firebug = valueWhenOnByDefault('SWF_firebug');
			log_to_scribe = valueWhenOffByDefault('SWF_scribe');
			max_vp_dims = get('SWF_max_vp_dims');
			sounds_file = get('sounds_file');
			sounds_file = get('SWF_sounds_file') || sounds_file;
			no_landing = valueWhenOffByDefault('SWF_no_landing');
			show_tree_str = valueWhenOffByDefault('SWF_show_tree_str');
			furniture_placed_normally_on_pl_plats = valueWhenOffByDefault('SWF_furniture_placed_normally_on_pl_plats');
			stack_furn_bag = valueWhenOnByDefault('SWF_stack_furn_bag');
			colors_from_loc = valueWhenOffByDefault('SWF_colors_from_loc');
			fake_prompts = valueWhenOffByDefault('SWF_fake_prompts');
			edit_loc = valueWhenOffByDefault('SWF_edit_loc');
			is_stub_account = get('is_stub_account', 'Number');
			session_id = get('session_id', 'Number');
			newxp_log_step = get('newxp_log_step', 'Number');
			has_not_done_intro = get('has_not_done_intro', 'Number');
			needs_todo_leave_gentle_island = get('needs_todo_leave_gentle_island', 'Number');
			no_boot_message = valueWhenOffByDefault('no_boot_message');
			boot_message = get('boot_message');
			boot_message_prefix = get('boot_message_prefix');
			css_file = get('css_file');
			api_url = get('api_url');
			api_token = get('api_token');
			display_ava_path = valueWhenOffByDefault('SWF_display_ava_path');
			report_rendering = valueWhenOffByDefault('SWF_report_rendering');
			no_render_stacks = valueWhenOffByDefault('SWF_no_render_stacks');
			no_render_pcs = valueWhenOffByDefault('SWF_no_render_pcs');
			no_render_decos = valueWhenOffByDefault('SWF_no_render_decos');
			fps = get('SWF_fps', 'Number') || TSEngineConstants.TARGET_FRAMERATE;
			name_on_avatar = valueWhenOffByDefault('SWF_name_on_avatar');
			show_benchmark = valueWhenOffByDefault('SWF_show_benchmark');
			only_mg = valueWhenOffByDefault('SWF_only_mg');
			no_avatar_anim = valueWhenOffByDefault('SWF_no_avatar_anim');
			no_quoins = valueWhenOffByDefault('SWF_no_quoins');
			is_home_standalone = valueWhenOnByDefault('SWF_is_home_standalone');
			use_default_ava = valueWhenOffByDefault('SWF_use_default_ava');
			CONFIG::perf {
				use_default_ava_except_for_player = valueWhenOffByDefault('SWF_use_default_ava_except_for_player');
			}
			vp_rect_collision_scale = get('SWF_vp_rect_collision_scale', 'Number') || vp_rect_collision_scale;
			player_is_subscriber = (get('player_is_subscriber') == 'true');
			player_had_free_sub = (get('player_had_free_sub') == 'true');
			placeholder_sheet_url = get('placeholder_sheet_url');
			pc_sheet_url = get('pc_sheet_url');
			max_buy_override = get('SWF_max_buy_override', 'Number');
			show_buildtime = valueWhenOffByDefault('SWF_show_buildtime');
			show_click_to_focus = valueWhenOffByDefault('SWF_show_click_to_focus');
			more_towers = valueWhenOnByDefault('SWF_more_towers');
			show_scores = valueWhenOffByDefault('SWF_show_scores');
			view_api_output = valueWhenOffByDefault('SWF_view_api_output');
			qp_in_im = valueWhenOnByDefault('SWF_qp_in_im');
			go_in_qp_in_im = valueWhenOnByDefault('SWF_go_in_qp_in_im');
			use_local_trade = valueWhenOffByDefault('SWF_use_local_trade');
			use_economy_info = valueWhenOnByDefault('SWF_use_economy_info');
			run_globometer_backwards = valueWhenOnByDefault('SWF_run_globometer_backwards');
			alt_keyboard_support = valueWhenOnByDefault('SWF_alt_keyboard_support');
			use_vec = valueWhenOffByDefault('SWF_use_vec');
			CONFIG::debugging {
				benchmark_physics_adjustments = valueWhenOffByDefault('SWF_benchmark_physics_adjustments');
			}
			debug_decorator_mode = valueWhenOffByDefault('SWF_debug_decorator_mode');
			
			CONFIG::god {
				interact_with_all = valueWhenOffByDefault('SWF_interact_with_all');
				debug_cult = valueWhenOffByDefault('SWF_debug_cult');
				debug_placement_plat_anim = valueWhenOffByDefault('SWF_debug_placement_plat_anim');
			}
			placement_plat_anim = valueWhenOnByDefault('SWF_placement_plat_anim');
			//no_bug = valueWhenOffByDefault('SWF_no_bug');
			ok_on_info = valueWhenOnByDefault('SWF_ok_on_info');
			use_glitchr_filters = valueWhenOnByDefault("SWF_use_glitchr_filters");
			dont_move_for_item_menu = valueWhenOnByDefault('SWF_dont_move_for_item_menu');
			check_for_proximity = valueWhenOnByDefault('SWF_check_for_proximity');
			do_single_interaction_sp_keys = valueWhenOffByDefault('SWF_do_single_interaction_sp_keys');
			item_animate_duration = get('SWF_item_animate_duration', 'Number') || item_animate_duration;
			change_state_when_still = valueWhenOffByDefault('SWF_change_state_when_still');
			new_furn_up = valueWhenOnByDefault('SWF_new_furn_up');
			keep_buff_names = valueWhenOffByDefault('SWF_keep_buff_names');
			placehold_itemstacks = valueWhenOffByDefault('SWF_placehold_itemstacks');
			show_missing_itemstacks = valueWhenOnByDefault('SWF_show_missing_itemstacks');
			break_item_asset_loading = valueWhenOffByDefault('SWF_break_item_asset_loading');
			preload_sounds = valueWhenOffByDefault('SWF_preload_sounds');
			hi_viral = valueWhenOnByDefault('SWF_hi_viral');
			break_item_assets = get('SWF_break_item_assets');
			
			// performance
			cleanup_ms = get('SWF_cleanup_ms', 'Number') || cleanup_ms;
			throttle_swf = valueWhenOnByDefault('SWF_throttle_swf');
			throttle_fps = get('SWF_throttle_fps', 'Number') || throttle_fps;
			throttle_delay = get('SWF_throttle_delay', 'Number') || throttle_delay;
			throttle_opacity = get('SWF_throttle_opacity', 'Number') || throttle_opacity;
			use_set_timeout_controller = valueWhenOffByDefault('SWF_use_set_timeout_controller');
			workers_wait_until_next_frame = valueWhenOffByDefault('SWF_workers_wait_until_next_frame');
			display_performance_tips = valueWhenOnByDefault('SWF_display_performance_tips');

			// physics
			no_pc_collision = valueWhenOffByDefault('SWF_no_pc_collision');
			no_item_collision = valueWhenOffByDefault('SWF_no_item_collision');
			no_geo_collision = valueWhenOffByDefault('SWF_no_geo_collision');
			CONFIG::god {
				draw_plats = valueWhenOffByDefault('SWF_draw_plats');
			}
			
			new_physics = valueWhenOffByDefault('SWF_new_physics');
			avg_enter_frame_ms = valueWhenOffByDefault('SWF_avg_enter_frame_ms');
			irregular_gl = valueWhenOffByDefault('SWF_irregular_gl');
			lie_about_gl = valueWhenOnByDefault('SWF_lie_about_gl');
			sleep_ms = get('SWF_sleep_ms', 'Number') || sleep_ms;
			tween_camera = valueWhenOffByDefault('SWF_tween_camera');
			tween_camera_time = get('SWF_tween_camera_time', 'Number') || tween_camera_time;
			ava_anim_time = get('SWF_ava_anim_time', 'Number') || ava_anim_time;
			run_mv_from_aph = valueWhenOffByDefault('SWF_run_mv_from_aph');
			run_av_from_aph = valueWhenOffByDefault('SWF_run_av_from_aph');
			
			// rendering
			use_intermediate_bitmap = valueWhenOffByDefault('SWF_use_intermediate_bitmap');
			hflip_hack = valueWhenOnByDefault('SWF_hflip_hack');
			async_rendering = valueWhenOnByDefault('SWF_async_rendering');
			async_spritesheeting = valueWhenOffByDefault('SWF_async_spritesheeting');
			async_timeslice_ms = get('SWF_async_timeslice_ms', 'Number') || async_timeslice_ms;
			limited_rendering = valueWhenOnByDefault('SWF_limited_rendering');
			alt_color_matrix = valueWhenOnByDefault('SWF_alt_color_matrix');
			dispose_unused_templates = valueWhenOnByDefault('SWF_dispose_unused_templates');
			multiswf = valueWhenOnByDefault('SWF_multiswf');
			multiswf_cache = valueWhenOnByDefault('SWF_multiswf_cache');
			vp_scale = get('SWF_vp_scale', 'Number') || vp_scale;
			no_layer_filters = valueWhenOffByDefault('SWF_no_layer_filters');
			sprite_sheet_decos_copypixels = valueWhenOffByDefault('SWF_sprite_sheet_decos_copypixels');
			sprite_sheet_decos_bitmapfill = valueWhenOffByDefault('SWF_sprite_sheet_decos_bitmapfill');
			render_fewer_itemstacks = valueWhenOffByDefault('SWF_render_fewer_itemstacks');
			render_fewer_itemstacks_distance = get('SWF_render_fewer_itemstacks_distance', 'Number') || render_fewer_itemstacks_distance;
			
			// zoom
			min_zoom = get('SWF_min_zoom', 'Number') || min_zoom;
			max_zoom = get('SWF_max_zoom', 'Number') || max_zoom;
			zoom_step = get('SWF_zoom_step', 'Number') || zoom_step;
			auto_zoom_ms = get('SWF_auto_zoom_ms', 'Number') || auto_zoom_ms;

			if (!CONFIG::god) {
				// gods should always be able to report bugs
				disable_bug_reporting = valueWhenOffByDefault('SWF_disable_bug_reporting');
			}
			else {
				//turn on things for gods
			}
			
			if (CONFIG::locodeco) {
				// disable no matter what since it's incompatible with locodeco
				bitmap_renderer = false;
				vector_renderer = true;
				
				throttle_swf = false;
			} else {
				vector_renderer = valueWhenOffByDefault('SWF_vector_renderer');
				
				// enabled by default
				bitmap_renderer = valueWhenOnByDefault('SWF_bitmap_renderer');
			}
			
			// FP 11.1 bug redraw region clearing when 2 overlapping layers are moving			
			var versionA:Array = EnvironmentUtil.getFlashVersionArray();
			if ((int(versionA[0]) == 11 && int(versionA[1]) >= 1) || valueWhenOffByDefault('SWF_avatar_trail_buffer')) {
				avatar_trail_buffer = true;
			}
			
			// Requested on 11/22/2011:
			// Temporary flag so that adobe can test out the redraw region clearing bug.
			// TODO: Remove after adobe is satisfied with testing. 
			if (valueWhenOffByDefault('SWF_redraw_clear_bug')) {
				avatar_trail_buffer = false;
			}
			
			//if (get('SWF_use_tweenmax') == '') {
			//	// the url does not set anything, let's choose randomly, if they've done newxp
			//	if (has_not_done_intro) {
			//		use_tweenmax = false;
			//	} else {
			//		use_tweenmax = MathUtil.chance(50);
			//	}
			//} else {
			//	// the url is setting this value
			//	use_tweenmax = valueWhenOffByDefault("SWF_use_tweenmax");
			//}
			use_tweenmax = valueWhenOffByDefault("SWF_use_tweenmax");

			// performance testing (keep this last)
			CONFIG::perf {
				// enabled by default
				run_automated_tests = valueWhenOnByDefault('SWF_run_automated_tests');
				if (run_automated_tests) {
					// set things up for testing
					if (root_url.indexOf('dev.glitch.com') != -1) {
						// dev
						empty_test_location = "LMF6ODL3D9O26LJ";
						test_locations = [
							// hellEmpty
							{tsid:"LMF1M5TBOQO27HV", fake_friends:0},
							// hellFull
							{tsid:"LMF1M47BOQO249R", fake_friends:56},
							// ggwFull
							{tsid:"LMF24DHBFEP28KM", fake_friends:56}
						];
					} else {
						// prod
						empty_test_location = "LHVVJ25RIJS240F";
						test_locations = [
							// hellEmpty
							{tsid:"LHVVP1CUIJS2P37", fake_friends:0},
							// hellFull
							{tsid:"LHV19B54JJS2Q27", fake_friends:56},
							// ggwFull
							{tsid:"LHV1BED5JJS2I77", fake_friends:56}
						];
					}
					
					// baseline trial
					use_default_ava = true;
					use_default_ava_except_for_player = true;
					async_rendering = false;
					limited_rendering = true;
					no_layer_filters = false;
					throttle_swf = false;
					//////////////////////
					
					// deco_spritesheeting trial
					//current_trial_name = "deco_spritesheeting";
					//sprite_sheet_decos = true;
					//////////////////////
					
					// new_chrome_baseline trial
					//current_trial_name = "new_chrome_baseline";
					//use_new_chrome = true;
					//////////////////////
					
					// for home testing
					if (root_url.indexOf('dev.glitch.com') != -1) {
						// dev
						test_locations = [
							// flashpirate's house
							{tsid:"LMF4CF69QEP23NE", fake_friends:0},
							// eric's house
							{tsid:"LPF6HF44SLS2NNU", fake_friends:0},
							// eric's tower
							{tsid:"LPF10F6GJV23MUH", fake_friends:0}
						];
					} else {
						// prod
						test_locations = [
							// jono's house
							{tsid:"LHVAAGSL13V2FAR", fake_friends:0},
							// rascalmom's house
							{tsid:"LHV7GK57J1V2L1P", fake_friends:0},
							// jade's house
							{tsid:"LHV7LDI7J1V2NQ2", fake_friends:0},
							// jade's tower
							{tsid:"LHV5G0A1O543JGH", fake_friends:0},
							// jello's landscaping's tower
							{tsid:"LHV5P3VLA253F44", fake_friends:0}
						];
					}
					
					// home_is_standalone
					//is_home_standalone = true;
					//no_render_stacks = true;
					//no_render_pcs = true;
					//////////////////////
					
					// home_is_not_standalone
					//is_home_standalone = false;
					//no_render_stacks = true;
					//no_render_pcs = true;
					//////////////////////
					
					// chatty_cathy
					is_home_standalone = false;
					no_render_stacks = true;
					no_render_pcs = true;
					test_chat_filler = true;
					//////////////////////
					
					current_trial_name = "chatty_cathy";
				}
			}
		}
		
		public function get(key:String, type:String = 'String'):* {
			return flashVarData.getFlashvar(key, type);
		}
		
		private function valueWhenOffByDefault(paramName:String):Boolean {
			return (get(paramName) == '1');
		}
		
		private function valueWhenOnByDefault(paramName:String):Boolean {
			return (get(paramName) != '0');
		}
	}
}
