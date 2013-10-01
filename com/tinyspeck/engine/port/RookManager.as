package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.control.engine.AnimationSequenceController;
	import com.tinyspeck.engine.control.engine.AnnouncementController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.data.location.Layer;
	import com.tinyspeck.engine.data.location.MiddleGroundLayer;
	import com.tinyspeck.engine.data.rook.RookHeadAnimationState;
	import com.tinyspeck.engine.data.rook.RookedStatus;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.loader.SmartLoader;
	import com.tinyspeck.engine.model.RookModel;
	import com.tinyspeck.engine.model.TSEngineConstants;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.spritesheet.AnimationSequenceCommand;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.ObjectUtil;
	import com.tinyspeck.engine.util.geom.GeomUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.gameoverlay.ArbitraryFLVView;
	import com.tinyspeck.engine.view.gameoverlay.InLocationOverlay;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.RookIncidentHeaderView;
	import com.tinyspeck.engine.view.ui.RookIncidentProgressView;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.filters.BlurFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.getTimer;

	CONFIG::god { import com.tinyspeck.engine.admin.AdminDialog; }

	public class RookManager extends EventDispatcher implements IFocusableComponent {
		/* singleton boilerplate */
		public static const instance:RookManager = new RookManager();
		
		private const ASSETS:Array = new Array('rook_flock', 'rook_fly_side', 'rook_fly_forward', 'rook_fly_up', 'sonic_boom');
		
		private const MIN_SIDE_SCALE:Number = .025;
		private const MAX_SIDE_SCALE:Number = .3;
		private const LEFT_RIGHT_BUFFER:uint = 130;
		private const START_ANIMATION_TIME:uint = 12;
		private const END_ANIMATION_TIME:uint = 3;
		
		private var model:TSModelLocator;
		private var rm:RookModel;
		private var main_view:TSMainView;
		private var loading_index:int;
		private var asset_loader:MovieClip;
		private var loaded:Boolean;
		private var loading:Boolean;
		private var phase_timer:Timer = new Timer(1000);
		
		private var start_incident_after_load:Boolean;
		private var ravV:Vector.<RookAttackView> = new Vector.<RookAttackView>();
		private var rpdvV:Vector.<RookPeckDamageView> = new Vector.<RookPeckDamageView>();
		private var rsdvV:Vector.<RookScratchDamageView> = new Vector.<RookScratchDamageView>();
		private var rav_to_rdv:Dictionary = new Dictionary(); // to map rdvs to ravs when moving to attack existing rdvs
		private var rdv_to_rav:Dictionary = new Dictionary(); // to map rdvs to ravs when moving to attack existing rdvs
		private var flock:MovieClip;
		private var fly_side:InLocationOverlay;
		private var fly_up:MovieClip;
		private var fly_forward:MovieClip;
		private var sonic_boom:MovieClip;
		private var fly_forward_holder:Sprite = new Sprite();
		private var rook_head_iiv:ItemIconView;
		private var rook_head_ascntlr:AnimationSequenceController = new AnimationSequenceController(RookHeadAnimationState.IDLE_ASC);
		
		private var attack_interv:uint;
		private var attack_tim:uint;
		private var heal_interv:uint;
		private var fly_side_random_interv:uint;
		private var fly_side_sequence_interv:uint;
		private var fly_forward_interv:uint;
		private var current_phase_time:int;
		
		private var attack_container:Sprite;
		private var damage_container:Sprite;
		
		public function RookManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			main_view = TSFrontController.instance.getMainView();
			attack_container = main_view.rook_attack_container;
			damage_container = main_view.rook_damage_container;
			//rook_attack_container.visible = false;
			
			model = TSModelLocator.instance;
			rm = model.rookModel;
			rm.registerCBProp(onRookedStatusChanged, "rooked_status");
			
		}
		
		public function init():void {
			registerSelfAsFocusableComponent();
			
			// update the model with values from CSS, hee
			
			var cssm:CSSManager = CSSManager.instance;
			var style_name:String = 'rook_attack';
			var style:Object = cssm.getStyle(style_name);
			for (var k:String in style) {
				if (rm.hasOwnProperty(k)) {
					if (k.substr(k.length-1, 1) == 'A') {
						rm[k] = cssm.getArrayValueFromStyle(style_name, k, rm[k]);
					} else if (k.substr(k.length-5, 5) == '_bool') {
						rm[k] = cssm.getBooleanValueFromStyle(style_name, k, rm[k]);
					} else {
						rm[k] = cssm.getNumberValueFromStyle(style_name, k, rm[k]);
					}
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn(k+' from '+style_name+' has no analog on rm');
					}
				}
			}
			
			CONFIG::god {
				AdminDialog.instance.rook_panel.input_tf.text = rm.rav_damageB_to_peck_animA.join(', ');
				model.stateModel.registerCBProp(editingChangedHandler, 'editing');
			}
			
			showPts();
			
			if (heal_interv) StageBeacon.clearInterval(heal_interv);
			heal_interv = StageBeacon.setInterval(onHealLoop, rm.heal_interv_ms);

			// let's just go ahead and load up rook assets for the preview
			//startLoading();
		}

		CONFIG::god private function editingChangedHandler(editing:Boolean):void {
			if (rm.rooked_status.rooked) {
				if (editing) {
					stopIncident(true);
				} else {
					startIncident();
				}
			}
		}
		
		private var debug_sh:Shape;
		public function addDebugSh(debug_sh:Shape):void {
			this.debug_sh = debug_sh;
		}
		
		private var drawn_debug_at:String;
		private function drawDebug():void {
			if (!debug_sh) return;
			
			var offset:int = 60;
			var w:int = 340-(offset*2);
			var rat:Number = w/StageBeacon.stage.stageWidth;
			var h:int = rat*StageBeacon.stage.stageHeight;
			
			var g:Graphics = debug_sh.graphics;
			
			if (drawn_debug_at != w+'x'+h) {
				drawn_debug_at = w+'x'+h;
				g.clear();
				
				g.beginFill(0x999999, 1);
				g.drawRect(0, 0, w+(offset*2), h+offset*2);
				
				g.beginFill(0, 1);
				g.drawRect(offset, offset, w, h);
			}
			
			var rx:int;
			var ry:int;
			for (var i:int;i<ravV.length;i++) {
				rx = offset+(ravV[int(i)].x*(w/StageBeacon.stage.stageWidth));
				ry = offset+(ravV[int(i)].y*(h/StageBeacon.stage.stageHeight));
				g.beginFill(0xffffff, 1);
				g.drawCircle(rx, ry, 2);
				g.endFill();
			}
			
			if (fly_side && fly_side.parent) {
				var pt:Point = fly_side.localToGlobal(new Point())
				rx = offset+(pt.x*(w/StageBeacon.stage.stageWidth));
				ry = offset+(pt.y*(h/StageBeacon.stage.stageHeight));
				g.beginFill(0xcc0000, 1);
				g.drawCircle(rx, ry, 2);
				g.endFill();
			}
		}
		
		public function showPts():void {
			// if you want to visualize the pts
			if (EnvironmentUtil.getUrlArgValue('SWF_show_rook_pts') == '1') {
				var g:Graphics = attack_container.graphics
				g.clear();
				var i:int;
				var pt:Point;
				while (i <1000) {
					i++;
					pt = getNewBeakPt();
					g.beginFill(0xcc0000,10);
					g.drawCircle(pt.x, pt.y, 10);
					g.endFill();
				}
				
				i=0;
				while (i <1000) {
					i++;
					pt = getOnscreenPtforRav();
					g.beginFill(0x00cc00,10);
					g.drawCircle(pt.x, pt.y, 10);
					g.endFill();
				}
				
				i=0;
				var str:String = '';
				while (i <100) {
					i++;
					str+= MathUtil.randomInt(1,4).toString();
					
				}
				CONFIG::debugging {
					Console.warn(str)
				}
				
				/*
				i=0;
				while (i <1000) {
				i++;
				var c:int = MathUtil.randomInt(1,100);
				if (c<2 || c>99) Console.warn(c);
				}*/
				
			}
		}
		
		// ---------------------------------------------------------------------------------------------------------------------------------------
		// LOADING
		// ---------------------------------------------------------------------------------------------------------------------------------------
		
		private function loadAsset(index:int):void {
			loading = true;
			var url:String = model.stateModel.overlay_urls[ASSETS[index]];
			var sl:SmartLoader = new SmartLoader(url);
			sl.complete_sig.add(nextAsset);
			sl.error_sig.add(nextAsset);
			sl.load(new URLRequest(url));
		}
		
		private var sonic_boom_swf_w:int;
		private var sonic_boom_swf_h:int;
		private var fly_up_swf_w:int;
		private var fly_up_swf_h:int;
		private function nextAsset(sl:SmartLoader):void {
			var asset:MovieClip = sl.content as MovieClip;
			
			CONFIG::debugging {
				Console.log(666, 'loaded '+ASSETS[loading_index]+' '+sl.bytesTotal/1024);
			}
			
			if (ASSETS[loading_index] == 'rook_flock') {
				flock = MovieClip(asset);
				flock.blendMode = BlendMode.LAYER;
			} else if (ASSETS[loading_index] == 'rook_fly_up') {
				fly_up = MovieClip(asset);
				fly_up.blendMode = BlendMode.LAYER;
				fly_up_swf_w = sl.contentLoaderInfo.width;
				fly_up_swf_h = sl.contentLoaderInfo.height;
			} else if (ASSETS[loading_index] == 'rook_fly_side') {
				setupFlySideOverlay(MovieClip(asset));
			} else if (ASSETS[loading_index] == 'sonic_boom') {
				sonic_boom = MovieClip(asset);
				sonic_boom.blendMode = BlendMode.LAYER;
				sonic_boom_swf_w = sl.contentLoaderInfo.width;
				sonic_boom_swf_h = sl.contentLoaderInfo.height;
			} else if (ASSETS[loading_index] == 'rook_fly_forward') {
				fly_forward = MovieClip(asset);
				fly_forward_holder.blendMode = BlendMode.LAYER;
				fly_forward.cacheAsBitmap = EnvironmentUtil.getUrlArgValue('SWF_no_rook_cab') != '1';
				
				fly_forward_holder.addChild(fly_forward);
				//var g:Graphics = fly_forward_holder.graphics;
				//g.beginFill(0, 1);
				//g.drawCircle(0,0,300)
				var rect:Rectangle = fly_forward.getRect(fly_forward);
				fly_forward.x = -(rect.width/2)-rect.x;
				fly_forward.y = -(rect.height/2)-rect.y;
			}
			
			
			loading_index++;
			
			if(loading_index < ASSETS.length) {
				loadAsset(loading_index);
			}else{
				CONFIG::debugging {
					Console.trackRookValue('loaded', true);
				}
				//all done
				loaded = true;
				asset_loader = null;
				if (start_incident_after_load) {
					startIncident();
				} 
			} 
		}
		
		private function setupFlySideOverlay(asset:MovieClip):void {
			asset.blendMode = BlendMode.LAYER;
			asset.cacheAsBitmap = EnvironmentUtil.getUrlArgValue('SWF_no_rook_cab') != '1';
			fly_side = new InLocationOverlay(asset);
		}
		
		// ---------------------------------------------------------------------------------------------------------------------------------------
		// INCIDENT MANAGEMENT
		// ---------------------------------------------------------------------------------------------------------------------------------------
		/*
		When fly_forward starts
		- scatter attack rooks CHECK
		- prohibit any new fly_sides (sequence or other wise) CHECK
		
		
		When fly_forward ends
		- start up attack rooks again CHECK
		- allow fly sides CHECK
		
		
		When wing_beat starts
		- scatter attack rooks CHECK
		- cancel fly_forward if running CHECK
		- prohibit any new fly_forward CHECK
		- prohibit any new fly_sides (sequence or other wise) CHECK
		
		
		When wing_beat ends
		- start up attack rooks again  CHECK
		- allow fly sides CHECK
		- allow fly forwards CHECK
		- no more fly forward happens within 15 seconds or so.
		
		QUESTION: what is the last section of a fly side_sequence?
		QUESTION: how often do full flysides happen?
		
		
		*/
		
		// ths gets called when move_start comes on with a rooked_status, or when a location_rooked_status msg comes in 
		private function onRookedStatusChanged(rooked_status:RookedStatus):void {
			
			// ignore it in this case, we will do the stuff we have to in onMovement
			if (model.moveModel.moving) {
				CONFIG::debugging {
					Console.log(666, 'ignoring onRookedStatusChanged because we are moving');
				}
				return;
			}

			CONFIG::debugging {
				Console.log(666, 'onRookedStatusChanged rooked:'+rooked_status.rooked)
			}
			
			//do we have a timer?
			/*
			current_phase_time = rooked_status.timer;
			if(current_phase_time){
				phase_timer.reset();
				if(!phase_timer.running) phase_timer.start();
				
				dispatchEvent(new TSEvent(TSEvent.TIMER_TICK, current_phase_time));
			}
			else {
				phase_timer.stop();
			}
			*/
			
			if (rooked_status.rooked == false) {
				// rooked status has changed in this location to false
				
				// make sure that strength is 0;
				rooked_status.strength = 0;
				onCurrentLocGetsUnRooked();
				
			} else {
				if (rm.rook_incident_is_running) {
					if (rm.rooked_status.countdown) {
						scatterRAVs(); // scatter them so we can see the countdown that will be displayed by RookIncidentProgressView when there is a countdown on rooked_status
					}
					
					RookIncidentHeaderView.instance.update();
				} else {
					onCurrentLocGetsRooked();
				}
				
			}
		}
		
		public function stun():void {
			//only for the people in the epicentre
			if(rm.rooked_status.epicentre){
				RookIncidentHeaderView.instance.stun();
			}
			//if there is text with it, go ahead and show that in chat?
			else if(rm.rook_stun.txt){
				model.activityModel.activity_message = Activity.fromAnonymous({pc_tsid:WorldModel.NO_ONE, txt:rm.rook_stun.txt});
			}
		}
		
		public function damage():void {
			//only for the people in the epicentre
			if(rm.rooked_status.epicentre){
				RookIncidentHeaderView.instance.damage();
			}
				//if there is text with it, go ahead and show that in chat?
			else if(rm.rook_damage.txt){
				model.activityModel.activity_message = Activity.fromAnonymous({pc_tsid:WorldModel.NO_ONE, txt:rm.rook_damage.txt});
			}
		}
		
		public function text(txt:String):void {
			//only for the people in the epicentre
			//if(rm.rooked_status.epicentre){
				RookIncidentHeaderView.instance.addNormalMsg(txt);
			//}
		}
		
		private function onTimerTick(event:TimerEvent = null):void {
			current_phase_time--;
			
			if(current_phase_time <= 0){
				phase_timer.stop();
				current_phase_time = 0;
			}
			
			dispatchEvent(new TSEvent(TSEvent.TIMER_TICK, current_phase_time));
			
			//if the timer is toast, go ahead and hide the progress
			if(current_phase_time == 0){
				RookIncidentHeaderView.instance.end();
			}
		}
		
		// TSMainview calls this for us
		public function onMovement(moving:Boolean):void {
			if (model.moveModel.move_failed) return;
			
			if (moving) {
				CONFIG::debugging {
					Console.log(666, 'a move started, rooked:'+rm.rooked_status.rooked);
				}
				
				if (rm.rook_incident_is_running) { // TODO test here if we are actually showing rook stuff
					onExitingALocThatIsRooked();
				}
				
			} else {
				CONFIG::debugging {
					Console.log(666, 'a move ended, ooked:'+rm.rooked_status.rooked);
				}
				// we are entering a location
				
				if (rm.rooked_status.rooked) {
					onEnteringALocThatIsRooked();
				}
				
			}
		}
		
		private function onExitingALocThatIsRooked():void {
			CONFIG::debugging {
				Console.log(666, 'onExitingALocThatIsRooked');
			}
			stopIncident(true); // true makes sure the RookIncidentProgressView goes away without animating down
		}
		
		private function onCurrentLocGetsUnRooked():void {
			CONFIG::debugging {
				Console.log(666, 'onCurrentLocGetsUnRooked');
			}
			stopIncident();
		}
		
		private function onEnteringALocThatIsRooked():void {
			CONFIG::debugging {
				Console.log(666, 'onEnteringALocThatIsRooked');
			}
			rm.rook_incident_started_while_i_was_in_this_loc = false;
			startIncident();
		}
		
		private function onCurrentLocGetsRooked():void {
			CONFIG::debugging {
				Console.log(666, 'onCurrentLocGetsRooked');
			}
			rm.rook_incident_started_while_i_was_in_this_loc = true;
			startIncident();
		}
		
		private function stopIncident(force:Boolean = false):void {
			if (!rm.rook_incident_is_running) return;
			
			//reset stuff back to normal
			if(rook_head_iiv && rook_head_iiv.parent) rook_head_iiv.parent.removeChild(rook_head_iiv);
			TSFrontController.instance.changeTeleportDialogVisibility();
			RookIncidentHeaderView.instance.end();

			CONFIG::debugging {
				Console.priwarn(666, 'rook incident ending');
			}
			
			rm.rook_incident_is_running = false;
			start_incident_after_load = false;
			
			if (start_tim) StageBeacon.clearTimeout(start_tim);
			if (fly_side_random_interv) StageBeacon.clearInterval(fly_side_random_interv);
			if (fly_side_sequence_interv) StageBeacon.clearInterval(fly_side_sequence_interv);
			if (fly_forward_interv) StageBeacon.clearInterval(fly_forward_interv);
			
			stopRookPreviewMessage();
			stopAttack();
			stopFlySideSeq();
			stopFlyForward();
			stopWingBeat();
		}
		
		private var start_tim:uint;
		private function startLoading():void {
			
			rook_head_iiv = new ItemIconView('rook_head', 70, 'idle1', 'center', true);
			rook_head_iiv.y = -1000;// so it is not visible until RookIncidentProgressViewNEW.refresh places it
			rook_head_iiv.addEventListener(TSEvent.COMPLETE, afterRookHeadIIVLoad, false, 0, true);
			
			loading_index = 0;
			loadAsset(loading_index);
			CONFIG::debugging {
				Console.priwarn(666, 'loading');
			}
			
		}
		
		private function afterRookHeadIIVLoad(e:TSEvent):void {
			rook_head_ascntlr.setMC(rook_head_iiv.mc);
			rook_head_ascntlr.sequenceCompleteCallback = rookHeadSeqCallback;
			main_view.addView(rook_head_iiv);
		}
		
		private function startIncident():void {
			if (rm.rook_incident_is_running) return;
			
			//Console.error('wtf');
			start_incident_after_load = true;
			if (!loaded) {
				if (!loading) {
					startLoading();
				}
				return;
			}
			
			RookIncidentHeaderView.instance.start();
			
			CONFIG::debugging {
				Console.priwarn(666, 'rook incident starting');
			}
			rm.client_incident_start = getTimer();
			CONFIG::debugging {
				Console.trackRookValue('incident duration (in client)', 0+'s');
			}
			
			rm.rook_incident_is_running = true;
			
			// these are necessary
			rm.rook_fly_forward_cnt = 0;
			rm.rook_wing_beat_cnt = 0;
			rm.rook_fly_side_sequence_cnt = 0;
			rm.rook_fly_side_random_cnt = 0;
			
			// these are mainly for logging
			rm.rook_attack_is_running = false;
			rm.rook_fly_forward_is_running = false;
			rm.rook_fly_side_random_is_running = false;
			rm.rook_fly_side_sequence_is_running = false;
			rm.rook_wing_beat_is_running = false;
			rm.rook_preview_msg_is_running = false;
			
			// this timeout gives the renderer time to get itself updated
			start_tim = StageBeacon.setTimeout(function():void {
				if (!rm.rook_incident_is_running) return;
				rm.fly_side_middle_layer_index = model.worldModel.location.layers.indexOf(model.worldModel.location.mg);
				rm.fly_side_animation_increment = (START_ANIMATION_TIME - END_ANIMATION_TIME) / rm.fly_side_middle_layer_index;
				
				CONFIG::debugging {
					Console.warn('flySide MAX_SIDE_SCALE '+MAX_SIDE_SCALE);
					Console.warn('flySide MIN_SIDE_SCALE '+MIN_SIDE_SCALE);
					Console.warn('flySide START_ANIMATION_TIME '+START_ANIMATION_TIME);
					Console.warn('flySide END_ANIMATION_TIME '+END_ANIMATION_TIME);
					Console.warn('flySide rm.fly_side_middle_layer_index '+rm.fly_side_middle_layer_index);
					Console.warn('flySide rm.fly_side_animation_increment '+rm.fly_side_animation_increment);
				}
				
				//startFlock();
				startFlySideSeq();
				
				if (fly_side_sequence_interv) StageBeacon.clearInterval(fly_side_sequence_interv);
				fly_side_sequence_interv = StageBeacon.setInterval(startFlySideSeq, rm.fly_side_sequence_interv_ms);
				
				if (fly_forward_interv) StageBeacon.clearInterval(fly_forward_interv);
				fly_forward_interv = StageBeacon.setInterval(startFlyForward, rm.fly_forward_initial_interv_ms);
				
				if (fly_side_random_interv) StageBeacon.clearInterval(fly_side_random_interv);
				fly_side_random_interv = StageBeacon.setInterval(doRandomFlySide, rm.fly_side_random_interv_ms);
				
				StageBeacon.enter_frame_sig.add(onEnterFrame);
			}, 1000);
		}
		
		private var fc:int;
		private function onEnterFrame(ms_elapsed:int):void {
			if (!rm.rook_incident_is_running) return;
			
			if (debug_sh) drawDebug();
			
			//if (flock && flock.parent) placeFlock();
			
			if (rm.rook_attack_is_running) checkRAVCollisions();
			
			fc++;
			CONFIG::debugging {
				Console.trackRookValue('incident duration (in client)', ((getTimer()-rm.client_incident_start)/1000).toFixed(1)+'s ('+fc+')');
			}
			if (fc == TSEngineConstants.TARGET_FRAMERATE) {
				fc = 0;
				onceASecond(); // roughly, depending on frame rate of course
			}
		}
		
		private function onceASecond():void {
			if (!rm.rook_incident_is_running) return;
			CONFIG::debugging {
				Console.trackRookValue('onceASecond last at', ((getTimer()-rm.client_incident_start)/1000).toFixed(1)+'s');
			}
			
			// this bit is ok no matter what, because startAttack just starts the onAttackLoop
			// and onAttackLoop checks the conditions to make sure it should do something
			if (!rm.rook_attack_is_running) {
				if ((rm.rook_fly_forward_cnt >= rm.min_fly_forward_cnt_for_attack || rm.disable_fly_forward_bool) && rm.rook_wing_beat_cnt >= rm.min_wing_beat_cnt_for_attack) {
					CONFIG::debugging {
						Console.log(666, 'starting attack');
					}
					startAttack();
				}
			}
		}
		
		/**
		* CONTROL THE HEAD WHERE THE FAMILIAR USUALLY IS
		* See: RookHeadAnimationState for available options
		**/
		
		public function tickleRookHead(play_now:Boolean = false):void {
			animateRookHead(rook_head_state, play_now);
			
			// if it's currently idle and there is an angry state, go ahead and play it now
			if (waiting_on_asc && waiting_on_asc.name.indexOf('IDLE') == 0) {
				if (rm.rooked_status.angry_state) {
					rookHeadSeqCallback(rook_head_ascntlr, waiting_on_asc);
				}
			}
		}
		
		private var rook_head_state:String = RookHeadAnimationState.IDLE;
		public function animateRookHead(state:String, play_now:Boolean = false):void {
			if(rook_head_iiv && !main_view.contains(rook_head_iiv)){
				main_view.addView(rook_head_iiv);
			}
			
			var asc:AnimationSequenceCommand;
			var after_state:String;
			
			//Console.info(rook_head_state+' -> '+state+' play_now:'+play_now);
			
			switch (state) {
				case RookHeadAnimationState.IDLE:
					
					rook_head_state = RookHeadAnimationState.IDLE;
					return;
				
				case RookHeadAnimationState.TAUNT:
					after_state = RookHeadAnimationState.IDLE;
					asc = RookHeadAnimationState.TAUNT_ASC;
					break;
				
				case RookHeadAnimationState.STUNNED:
					
					after_state = RookHeadAnimationState.STUNNED;
					
					switch (rook_head_state) {
						case RookHeadAnimationState.STUNNED:
							asc = RookHeadAnimationState.STUNNED_HIT_STUNNED_ASC;
							break;
						
						default:
							asc = RookHeadAnimationState.HIT_STUNNED_ASC;
							break;
					}
					
					break;
				
				case RookHeadAnimationState.DEAD:
					
					after_state = RookHeadAnimationState.DEAD;
					
					switch (rook_head_state) {
						case RookHeadAnimationState.DEAD:
							return;
						
						default:
							asc = RookHeadAnimationState.HIT_DEAD_ASC;
							break;
					}
					
					break;
				
				case RookHeadAnimationState.HIT:
					
					switch (rook_head_state) {
						case RookHeadAnimationState.IDLE:
							asc = RookHeadAnimationState.HIT_IDLE_ASC;
							after_state = RookHeadAnimationState.IDLE;
							break;
						
						case RookHeadAnimationState.STUNNED:
							asc = RookHeadAnimationState.STUNNED_HIT_STUNNED_ASC;
							after_state = RookHeadAnimationState.STUNNED;
							break;
						
						case RookHeadAnimationState.DEAD:
							asc = RookHeadAnimationState.HIT_DEAD_ASC;
							after_state = RookHeadAnimationState.DEAD;
							break;
						
						default:
							CONFIG::debugging {
								Console.error('don\'t know what to do with state:'+state+' while rook_head_state='+rook_head_state);
							}
							return;
					}

					break;
				
				default:
					CONFIG::debugging {
						Console.error('don\'t know what to do with state:'+state);
					}
					return;
			}
			
			//tell it to do stuff
			//Console.info(asc.A+' '+after_state);
			if (play_now){
				rook_head_ascntlr.playImmediately(asc);
			} else {
				rook_head_ascntlr.playAfterCurrentLabel(asc);
			}
			waiting_on_asc = asc;
			rook_head_state = after_state;
		}
		
		private var waiting_on_asc:AnimationSequenceCommand;
		private function rookHeadSeqCallback(ascntlr:AnimationSequenceController, done_asc:AnimationSequenceCommand):void {
			if (waiting_on_asc && waiting_on_asc != done_asc) {
				return;
			}
			//Console.info('done_asc: '+done_asc.A);
			//Console.info('rook_head_state:'+rook_head_state+' rm.rooked_status.angry_state:'+rm.rooked_status.angry_state)
			
			var asc:AnimationSequenceCommand;
			switch (rook_head_state) {
				case RookHeadAnimationState.DEAD:
					if (done_asc == RookHeadAnimationState.DEAD_ASC) {
						//return;
					}
					asc = RookHeadAnimationState.DEAD_ASC;
					break;
				
				case RookHeadAnimationState.STUNNED:
					asc = RookHeadAnimationState.STUNNED_ASC;
					break;
				
				case RookHeadAnimationState.IDLE:
					switch (rm.rooked_status.angry_state) {
						case 'angry1':
							asc = RookHeadAnimationState.IDLE_ANGRY1_ASC;
							break;
						
						case 'angry2':
							asc = RookHeadAnimationState.IDLE_ANGRY2_ASC;
							break;
						
						case 'angry3':
							asc = RookHeadAnimationState.IDLE_ANGRY3_ASC;
							break;
						
						default:
							asc = RookHeadAnimationState.IDLE_ASC;
							break;
					}
					
					break;
				
				default:
					CONFIG::debugging {
						Console.error('don\'t know what to do with rook_head_state:'+rook_head_state+'');
					}
					return;
			}
			
			waiting_on_asc = asc;
			rook_head_ascntlr.playImmediately(asc);
		}
		
		public function getRookHead():DisplayObject {
			return rook_head_iiv as DisplayObject;
		}
		
		// ---------------------------------------------------------------------------------------------------------------------------------------
		// FLOCK
		// ---------------------------------------------------------------------------------------------------------------------------------------
		
		public function stopFlock():void {
			CONFIG::debugging {
				Console.log(666, 'stopFlock');
			}
			TSTweener.removeTweens(flock);
			
			var self:RookManager = this;
			TSTweener.addTween(flock, {alpha:0, time:1, transition:'easeInExpo', onComplete:function():void{
				TSTweener.removeTweens(flock);
				if (flock.parent && !(flock.parent is Loader)) flock.parent.removeChild(flock);
			}});
		}
		
		private function placeFlock():void {
			var flock_pt:Point = getFlockPt();
			flock.x = flock_pt.x - 220; // 220 is half the flock width
			flock.y = flock_pt.y;
		}
		
		private function placeFlyForward():void {
			var fly_forward_pt:Point = getFlyForwardPt();
			fly_forward_holder.x = fly_forward_pt.x;//-(fly_forward.width/2);
			fly_forward_holder.y = fly_forward_pt.y;//-(fly_forward.height/2);
		}
		
		private var ff_pt:Point = new Point(); // don't get this directly, use getFlyForwardPt
		private function getFlyForwardPt():Point {
			ff_pt.x = model.layoutModel.gutter_w+(model.layoutModel.loc_vp_w/2);
			ff_pt.y = model.layoutModel.header_h+(model.layoutModel.loc_vp_h/2);
			return ff_pt;
		}
		
		private var f_pt:Point = new Point(); // don't get this directly, use getFlockPt
		private function getFlockPt():Point {
			f_pt = getGlobalFlockPt();
			const layers:Vector.<Layer> = model.worldModel.location.layers;
			
			var firstNonHiddenLayerIndex:int = 0;
			while (layers[firstNonHiddenLayerIndex].is_hidden) {
				firstNonHiddenLayerIndex++;
			}
			
			var flock_pt:Point = main_view.gameRenderer.translateLayerGlobalToLocal(layers[firstNonHiddenLayerIndex], f_pt.x, f_pt.y);
			return flock_pt;
		}
		private var gf_pt:Point = new Point(); // don't get this directly, use getGlobalFlockPt
		private function getGlobalFlockPt():Point {
			gf_pt.x = model.layoutModel.gutter_w+(model.layoutModel.loc_vp_w/2);
			gf_pt.y = model.layoutModel.header_h+140;
			
			return gf_pt;
		}
		
		/** NO LONGER USED */
		/*
		private function startFlock():void {
			if (model.worldModel.location.rookable_type == 1) return; // no flock
			CONFIG::debugging {
				Console.log(666, 'startFlock called and go!');
			}
			
			flock.play();
			flock.alpha = 0;
			placeFlock();
			
			const layers:Vector.<Layer> = model.worldModel.location.layers;
			
			var firstNonHiddenLayerIndex:int = 0;
			while (layers[firstNonHiddenLayerIndex].is_hidden) {
				firstNonHiddenLayerIndex++;
			}
			
//			main_view.gameRenderer.placeOverlayInLayer(layers[firstNonHiddenLayerIndex], flock, 'RM.startFlock');
			
			TSTweener.removeTweens(flock);
			TSTweener.addTween(flock, {alpha:1, time:1, transition:'easeInExpo'});
		}
		*/
		
		// ---------------------------------------------------------------------------------------------------------------------------------------
		// FLY SIDE SEQUENCE
		// ---------------------------------------------------------------------------------------------------------------------------------------
		
		private function flySideSeqEnded(success:Boolean = true):void {
			CONFIG::debugging {
				Console.log(666, 'flySideSeqEnded');
			}
			if (success) rm.rook_fly_side_sequence_cnt++;
			if (fly_side.parent) fly_side.parent.removeChild(fly_side);
			TSTweener.removeTweens(fly_side);
			rm.rook_fly_side_sequence_is_running = false;
		}
		
		private function stopFlySideSeq():void {
			CONFIG::debugging {
				Console.log(666, 'stopFlySideSeq');
			}
			if (!rm.rook_fly_side_sequence_is_running) return;
			flySideSeqEnded(false);
		}
		
		public function startFlySideSeqTEST():void {
			if (!rm.rook_incident_is_running) {
				return;
			}
			
			if (!rm.rook_fly_side_sequence_is_running) {
				startFlySideSeq();
			} else {
				stopFlySideSeq();
			}
		}
		
		private var fly_side_seq_count:int;
		private function startFlySideSeq():void {
			CONFIG::debugging {
				Console.log(666, 'startFlySideSeq called');
			}
			if (rm.rook_fly_forward_is_running) {
				reason();
				return;
			}
			if (rm.rook_wing_beat_is_running) {
				reason();
				return;
			}
			if (rm.rook_fly_side_sequence_is_running) {
				reason();
				return;
			}
			if (rm.rook_fly_side_random_is_running) {
				reason();
				return;
			}
			if (rm.fly_side_middle_layer_index < 2) {
				// in this case, there are not enough layers behind the mg, so just do a random flySide
				doRandomFlySide();
				return;
			}

			CONFIG::debugging {
				Console.log(666, 'startFlySideSeq go!');
			}

			rm.rook_fly_side_sequence_is_running = true;
			rm.fly_side_direction = MathUtil.chance(50) ? -1 : 1;
			rm.fly_side_layer_index = 0;
			fly_side_seq_count = 1;
			var time:Number = START_ANIMATION_TIME;
			
			var delay:Number = 3;
			var layer:Layer = model.worldModel.location.layers[rm.fly_side_layer_index];
			var flock_pt:Point = getFlockPt();
			
			fly_side.x = flock_pt.x;
			fly_side.y = flock_pt.y;
			fly_side.scaleY = MIN_SIDE_SCALE;
			fly_side.scaleX = fly_side.scaleY*-rm.fly_side_direction;
			fly_side.play();
			fly_side.alpha = 0;
			
			main_view.gameRenderer.placeOverlayInLayer(layer, fly_side, 'RM.startFlySideSeq');
			
			//to fly him right
			var fly_side_end_x:int = fly_side.x + model.layoutModel.loc_vp_w/2 + LEFT_RIGHT_BUFFER;
			
			//swap if flying left
			if (rm.fly_side_direction == -1) {
				fly_side_end_x = fly_side.x - (model.layoutModel.loc_vp_w/2 + LEFT_RIGHT_BUFFER);
			}
			
			var fly_side_end_y:int = fly_side.y+(rm.fly_side_y_inc*fly_side_seq_count);
			
			var alpha_ob:Object = {alpha:1, time:3, delay:delay, transition:'easeInQuint'};
			var xy_ob:Object = {x:fly_side_end_x, y:fly_side_end_y, time:time, delay:delay, transition:'linear'};
			var alpha2_ob:Object = {alpha:0, time:.3, delay:time+delay, onComplete:doNextFlySideInSeq};
			
			TSTweener.addTween(fly_side, alpha_ob);
			TSTweener.addTween(fly_side, xy_ob);
			TSTweener.addTween(fly_side, alpha2_ob);
		}
		
		private function isItAfterWingBeatInPreview():Boolean {
			if (!rm.rooked_status.rooked) return false;
			if (rm.attack_secs_running > (rm.rooked_status.preview_duration_secs-(5*60))) return true;
			return false;
		}
		
		private function afterRandomFlySide():void {
			rm.rook_fly_side_random_is_running = false;
			rm.rook_fly_side_random_cnt++;
			TSTweener.removeTweens(fly_side);
			if (fly_side.parent) fly_side.parent.removeChild(fly_side);
			
		}
		
		private function stopRookPreviewMessage():void {
			if (!rm.rook_incident_is_running) {
				return;
			}
			if (rm.rook_preview_msg_is_running) {
				AnnouncementController.instance.cancelOverlay('black_rook');
				AnnouncementController.instance.cancelOverlay('rook_msg');
			}
			rm.rook_preview_msg_is_running = false;
		}
		
		private function doRookPreviewMessage():void {
			stopRookPreviewMessage()
			rm.rook_preview_msg_is_running = true;
			model.activityModel.announcements = Announcement.parseMultiple(model.rookModel.preview_warning_anncsA);
			StageBeacon.setTimeout(stopRookPreviewMessage, 3000);
		}
		
		private function doRandomFlySide():void {
			if (rm.rook_fly_side_random_is_running) {
				return;
			}
			CONFIG::debugging {
				Console.log(666, 'doRandomFlySide called');
			}
			if (rm.rook_fly_forward_is_running) {
				reason();
				return;
			}
			if (rm.rook_wing_beat_is_running) {
				reason();
				return;
			}
			if (rm.rook_fly_side_sequence_is_running) {
				reason();
				return;
			}
			
			if (!MathUtil.chance(rm.fly_side_random_chance)) return;
			
			CONFIG::debugging {
				Console.log(666, 'doRandomFlySide go!');
			}
			
			rm.rook_fly_side_random_is_running = true;
			
			var bottom_possible_layer_index:int = 0;
			if (model.worldModel.location.rookable_type == 1) { // no flock
				// make sure it is not the backmost layer, and not above rm.fly_side_middle_layer_index
				bottom_possible_layer_index = Math.min(1, rm.fly_side_middle_layer_index);
			}
				
			var layer:Layer = model.worldModel.location.layers[MathUtil.randomInt(bottom_possible_layer_index, rm.fly_side_middle_layer_index)];
			rm.fly_side_direction = (MathUtil.chance(50) ? -1 : 1);
			doFlySide(layer, afterRandomFlySide);
		}
		
		private function doNextFlySideInSeq():void {
			TSTweener.removeTweens(fly_side);
			if (fly_side.parent) fly_side.parent.removeChild(fly_side);
			if (!rm.rook_incident_is_running) return;
			fly_side_seq_count++;
			rm.fly_side_layer_index++; // up one layer
			
			var layer:Layer = model.worldModel.location.layers[rm.fly_side_layer_index];
			var nextFunc:Function
			if (layer is MiddleGroundLayer){
				nextFunc = flySideSeqEnded;
			} else {
				nextFunc = doNextFlySideInSeq;
			}
			
			rm.fly_side_direction *= -1;
			doFlySide(layer, nextFunc);
		}
		
		private function doFlySide(layer:Layer, nextFunc:Function):void {
			if (!fly_side) return;
			
			var amount:Number = model.worldModel.location.layers.indexOf(layer)/rm.fly_side_middle_layer_index;
			if (isNaN(amount)) amount = 1;
			var time:Number = (START_ANIMATION_TIME+((END_ANIMATION_TIME-START_ANIMATION_TIME)*amount))
			var g_flock_pt:Point = getGlobalFlockPt();
			var start_y:int = g_flock_pt.y;
			var end_y:int = start_y+rm.fly_side_y_inc;

			CONFIG::debugging {
				Console.log(666, 'doFlySide '+layer.name+' index:'+model.worldModel.location.layers.indexOf(layer)+' amt:'+amount+' dir:'+rm.fly_side_direction+' tim:'+time+' s_y:'+start_y+' e_y:'+start_y);
			}
			
			var start_pt:Point;
			var end_pt:Point;
			
			if (rm.fly_side_direction == 1) {
				start_pt = main_view.gameRenderer.translateLayerGlobalToLocal(
					layer, 
					model.layoutModel.gutter_w - LEFT_RIGHT_BUFFER, 
					start_y
				);
				end_pt = main_view.gameRenderer.translateLayerGlobalToLocal(
					layer, 
					model.layoutModel.gutter_w + model.layoutModel.loc_vp_w + LEFT_RIGHT_BUFFER*4, 
					end_y
				);
			}
			else{
				//flip the start and end points
				start_pt = main_view.gameRenderer.translateLayerGlobalToLocal(
					layer, 
					model.layoutModel.gutter_w + model.layoutModel.loc_vp_w + LEFT_RIGHT_BUFFER, 
					start_y
				);
				end_pt = main_view.gameRenderer.translateLayerGlobalToLocal(
					layer, 
					model.layoutModel.gutter_w - LEFT_RIGHT_BUFFER*4, 
					end_y
				);
			}
			
			main_view.gameRenderer.placeOverlayInLayer(layer, fly_side, 'RM.doFlySide');
			
			fly_side.scaleX = (MIN_SIDE_SCALE+((MAX_SIDE_SCALE-MIN_SIDE_SCALE)*amount)) * -rm.fly_side_direction
			fly_side.scaleY = Math.abs(fly_side.scaleX);
			fly_side.x = start_pt.x;
			fly_side.y = start_pt.y;
			fly_side.alpha = 1;
			CONFIG::debugging {
				Console.log(666, 'doFlySide '+start_pt+' '+end_pt);
			}
			TSTweener.addTween(fly_side, {x:end_pt.x, y:end_pt.y, time:time, transition:'linear'});
			TSTweener.addTween(fly_side, {alpha:0, time:.3, delay:time, onComplete:nextFunc});
		}
		
		// ---------------------------------------------------------------------------------------------------------------------------------------
		// FLY FORWARD
		// ---------------------------------------------------------------------------------------------------------------------------------------
		
		private function reason():void {
			CONFIG::debugging {
				Console.priwarn(666,
					'rm.rook_fly_forward_is_running:'+rm.rook_fly_forward_is_running
					+ ' rm.rook_wing_beat_is_running:'+rm.rook_wing_beat_is_running
					+ ' rm.rook_fly_side_sequence_is_running:'+rm.rook_fly_side_sequence_is_running
					+ ' rm.rook_fly_side_random_is_running:'+rm.rook_fly_side_random_is_running
					+ ' rm.rook_fly_forward_is_running:'+rm.rook_fly_forward_is_running
					+ ' rm.fly_side_middle_layer_index:'+rm.fly_side_middle_layer_index
				);
			}
		}
		
		public function startFlyFowardTEST():void {
			if (!rm.rook_incident_is_running) {
				rm.rook_incident_is_running = true;
				StageBeacon.enter_frame_sig.add(onEnterFrame);
			}
			rm.disable_fly_forward_bool = false;
			if (rm.rook_fly_forward_is_running) {
				stopFlyForward();
			} else {
				startFlyForward();
			}
		}
		
		private function startFlyForward():void {
			if (rm.disable_fly_forward_bool) return;
			CONFIG::debugging {
				Console.log(666, 'startFlyForward called');
			}
			if (rm.rook_fly_forward_is_running) {
				reason();
				return;
			}
			if (rm.rook_wing_beat_is_running) {
				reason();
				return;
			}
			//if (rm.rook_fly_side_sequence_is_running) return reason();
			CONFIG::debugging {
				Console.log(666, 'startFlyForward go!');
			}
			
			rm.rook_fly_forward_is_running = true;
			damage_container.addChild(fly_forward_holder);
			var rect:Rectangle = fly_forward.getBounds(fly_forward);
			fly_forward.x = -(rect.width/2)-rect.x;
			fly_forward.y = -(rect.height/2)-rect.y;
			fly_forward_holder.alpha = 0;
			fly_forward_holder.scaleX = fly_forward_holder.scaleY = .2;
			
			placeFlyForward();
			fly_forward.gotoAndPlay(1);
			
			var time:int = 3;
			
			scatterRAVs();
			
			TSTweener.addTween(fly_forward_holder, {alpha:1, time:1, transition:'easeInQuad',
				onComplete:function():void {
					TSTweener.addTween(fly_forward_holder, {scaleX:2.5, scaleY:2.5, time:time, transition:'easeInQuad',
						onComplete:flyForwardEnded,
						onUpdate: function():void {
							if (fly_forward_holder.scaleX > 1 && fly_forward_holder.parent != attack_container) {
								attack_container.addChild(fly_forward_holder);
								
								damage_container.addChild(sonic_boom);
								sonic_boom.alpha = 1;
								sonic_boom.x = fly_forward_holder.x - (sonic_boom_swf_w/2);
								sonic_boom.y = fly_forward_holder.y - (sonic_boom_swf_h/2);
								MovieClip(sonic_boom.getChildAt(0)).gotoAndPlay(2);
								
								TSTweener.addTween(sonic_boom, {alpha:0, time:2, delay:0});
							} 
						}
					});
					
					var time2:Number = 1.4;
					TSTweener.addTween(fly_forward, {y:300, delay:time-time2, time:time2, transition:'easeInQuart'});
				}
			});
		}
		
		private function flyForwardEnded(success:Boolean = true):void {
			if (success) rm.rook_fly_forward_cnt++;
			CONFIG::debugging {
				Console.log(666, 'flyForwardEnded called rm.rook_fly_forward_cnt:'+rm.rook_fly_forward_cnt);
			}
			
			if (rm.rook_fly_forward_cnt >= 3) {
				// it should happen less frequently now that it has happened 3 times
				if (fly_forward_interv) StageBeacon.clearInterval(fly_forward_interv);
				fly_forward_interv = StageBeacon.setInterval(startFlyForward, rm.fly_forward_later_interv_ms);
			}
			
			if (fly_forward_holder.parent) fly_forward_holder.parent.removeChild(fly_forward_holder);
			if (sonic_boom.parent) sonic_boom.parent.removeChild(sonic_boom);
			TSTweener.removeTweens(sonic_boom);
			TSTweener.removeTweens(fly_forward);
			TSTweener.removeTweens(fly_forward_holder);
			rm.rook_fly_forward_is_running = false;
		}
		
		private function stopFlyForward():void {
			CONFIG::debugging {
				Console.log(666, 'stopFlyForward');
			}
			if (!rm.rook_fly_forward_is_running) return;
			
			if (sonic_boom.parent) sonic_boom.parent.removeChild(sonic_boom);
			
			TSTweener.addTween(fly_forward_holder, {alpha:0, time:2, transition:'linear',
				onComplete: function():void {
					flyForwardEnded(false);
				}
			});
		}
		
		// ---------------------------------------------------------------------------------------------------------------------------------------
		// ATTACK
		// ---------------------------------------------------------------------------------------------------------------------------------------
		
		private var fly_up_afv:ArbitraryFLVView;
		private var fly_up_flv_key:String = '';//'rook_fly_up_flv'; //rook_fly_up_fractal_flv
		private var wing_beat_start:int;
		private var done_smashed:Boolean;
		public function startWingBeat(proceed:Boolean = false):void {
			CONFIG::debugging {
				Console.log(666, 'startWingBeat called');
			}
			if (!rm.rook_incident_is_running) {
				CONFIG::debugging {
					Console.error('startWingBeat called, but rm.rook_incident_is_running:'+rm.rook_incident_is_running);
				}
				return;
			}
			if (rm.rook_wing_beat_is_running) {
				reason();
				return;
			}
			
			if (!proceed) {
				scatterRAVs();
				stopFlyForward();
				StageBeacon.setTimeout(startWingBeat, 2000, true);
				return;
			}
			
			//this will update the old style UI element
			RookIncidentProgressView.instance.wingBeatStarting();

			CONFIG::debugging {
				Console.log(666, 'startWingBeat go!');
			}
			rm.rook_wing_beat_is_running = true;
			
			
			done_smashed = false;
			
			//TSFrontController.instance.requestFocus(this);
			
			var doSwf:Function = function():void {
				//////////////////////////////////////////////
				//main_view.gameRenderer.visible = false;
				wing_beat_start = getTimer();
				fly_up.animatee.addEventListener(Event.ENTER_FRAME, checkWingBeat, false, 0, true);
				//main_view.main_container.visible = false;
				fly_up.visible = false; // set to true in checkWingBeat
				fly_up.animatee.cacheAsBitmap = EnvironmentUtil.getUrlArgValue('SWF_no_rook_cab') != '1';
				attack_container.addChild(fly_up);
				fly_up.scaleX = fly_up.scaleY = .8;
				//////////////////////////////////////////////
			}
			
			if (!fly_up_flv_key) {
				doSwf();
				placeWingBeat(); // places fly up corrctly
				TSFrontController.instance.playSurprisedAnimation();
				
			} else {
				
				fly_up.visible = false;
				
				var vid_wh:int;
				if (fly_up_flv_key == 'rook_fly_up_flv') {
					vid_wh = 500;
				} else if (fly_up_flv_key == 'rook_fly_up_fractal_flv') {
					vid_wh = Math.max(StageBeacon.stage.stageWidth, StageBeacon.stage.stageHeight);
				}
				
				if (!fly_up_afv) {
					fly_up_afv = new ArbitraryFLVView(model.stateModel.overlay_urls[fly_up_flv_key], vid_wh, 0, 'center');
					fly_up_afv.addEventListener(TSEvent.COMPLETE, function():void {
						fly_up_afv.removeEventListener(TSEvent.COMPLETE, arguments.callee);
						doSwf()
						placeWingBeat(); // places fly up corrctly
						TSFrontController.instance.playSurprisedAnimation();
					});
					
				} else {
					fly_up_afv.playFrom(0);
					doSwf()
					placeWingBeat(); // places fly up corrctly
					TSFrontController.instance.playSurprisedAnimation();
					
				}
				
				attack_container.addChild(fly_up_afv);

			}
			
		}
		
		public function startWingBeatTEST():void {
			if (!rm.rook_incident_is_running) {
				rm.rook_incident_is_running = true;
				StageBeacon.enter_frame_sig.add(onEnterFrame);
			}
			if (rm.rook_wing_beat_is_running) {
				stopWingBeat();
			} else {
				startWingBeat();
			}
		}
		
		private function wingBeatEnded(success:Boolean = true):void {
			
			TSFrontController.instance.releaseFocus(this);
			//main_view.main_container.visible = true;
			if (success) rm.rook_wing_beat_cnt++;
			if (fly_up_afv && fly_up_afv.parent) fly_up_afv.parent.removeChild(fly_up_afv);
			if (fly_up && fly_up.parent) fly_up.parent.removeChild(fly_up);
			if (fly_up) fly_up.animatee.removeEventListener(Event.ENTER_FRAME, checkWingBeat);
			main_view.gameRenderer.visible = true;
			rm.rook_wing_beat_is_running = false;
			
			// if we have not yet done a fly_forward, do one now
			if (success && rm.rook_fly_forward_cnt < 1) {
				startFlyForward();
			}
		}
		
		private function stopWingBeat():void {
			if (!rm.rook_wing_beat_is_running) return;
			wingBeatEnded(false);
		}
		
		private function placeWingBeat():void {
			if (fly_up && fly_up.parent) {
				fly_up.x = model.layoutModel.gutter_w+(model.layoutModel.loc_vp_w/2) - ((fly_up_swf_w*fly_up.scaleX)/2);
				fly_up.y = model.layoutModel.header_h+(model.layoutModel.loc_vp_h/2) - ((fly_up_swf_h*fly_up.scaleY)/2);
			}
			if (fly_up_afv && fly_up_afv.parent) {
				if (fly_up_flv_key == 'rook_fly_up_flv') {
					fly_up_afv.x = model.layoutModel.gutter_w+(model.layoutModel.loc_vp_w/2);
					fly_up_afv.y = model.layoutModel.header_h+(model.layoutModel.loc_vp_h/2);
				} else if (fly_up_flv_key == 'rook_fly_up_fractal_flv') {
					fly_up_afv.x = (StageBeacon.stage.stageWidth/2);
					fly_up_afv.y = (StageBeacon.stage.stageHeight/2);
				}
			}
		}
		
		private function screenShake(event:Event = null):void {
			done_smashed = true;
			var blur:BlurFilter = new BlurFilter();
			
			main_view.x -= Math.floor(Math.random() * (60-30)) + 30;
			main_view.y -= Math.floor(Math.random() * (40-30)) + 30;
			main_view.filters = [blur];
			
			TSTweener.removeTweens(main_view);
			TSTweener.addTween(main_view, {x:0, y:0, time:.3, transition:'easeOutElastic', 
				onUpdate:function():void {
					blur.blurX = blur.blurY = - main_view.y;
					main_view.filters = [blur];
				},
				onComplete:function():void {
					main_view.filters = null;
				}
			});
		}
		
		private function checkWingBeat(event:Event):void {
			// let's manually advance this sucker so its performance hit does not slow it down
			var time:int = getTimer()-wing_beat_start;
			var how_many_frames:int = (time/1000) * StageBeacon.stage.frameRate;
			
			fly_up.visible = true;
			
			if (time >= 3200 && !done_smashed) {
				screenShake();
			}
			if (how_many_frames >= fly_up.animatee.totalFrames) {
				fly_up.animatee.removeEventListener(Event.ENTER_FRAME, checkWingBeat);
				wingBeatEnded();
			} else {
				MovieClip(fly_up.animatee).gotoAndPlay(how_many_frames);
			}
		}
		
		// ---------------------------------------------------------------------------------------------------------------------------------------
		// ATTACK
		// ---------------------------------------------------------------------------------------------------------------------------------------

		private function startAttack():void {
			CONFIG::debugging {
				Console.log(666, 'startAttack called');
			}
			if (rm.rook_attack_is_running) {
				reason();
				return;
			}
			CONFIG::debugging {
				Console.log(666, 'startAttack go!');
			}
			rm.rook_attack_is_running = true;
			if (attack_interv) StageBeacon.clearInterval(attack_interv);
			attack_interv = StageBeacon.setInterval(onAttackLoop, rm.attack_interv_ms);
			
			if (attack_tim) StageBeacon.clearTimeout(attack_tim);
			attack_tim = StageBeacon.setTimeout(stopAttack, rm.attack_length_ms);
			onAttackLoop();
		}
		
		public function startAttackTEST():void {
			// since we're forcing it, do this to make sure the attack can happen
			rm.rook_fly_forward_cnt = rm.rav_in_use_max;
			rm.rook_wing_beat_cnt = rm.rav_in_use_max;
			if (!rm.rook_incident_is_running) {
				rm.rook_incident_is_running = true;
				StageBeacon.enter_frame_sig.add(onEnterFrame);
			}
			
			if (!rm.rook_attack_is_running) {
				startAttack();
			} else {
				stopAttack();
			}
		}
		
		private function stopAttack():void {
			if (attack_interv) StageBeacon.clearInterval(attack_interv);
			if (attack_tim) StageBeacon.clearTimeout(attack_tim);
			if (!rm.rook_attack_is_running) return;
			rm.rook_wing_beat_cnt = 0; // this makes it so that an attack can not start until the next wing beat
			for (var i:int;i<ravV.length;i++) {
				clearRDVForRAV(ravV[int(i)]);
				
				// should maybe check here if the rav is doing a scratch attack, and treat differently (because when scratchign the movement is in the timeline animation itself)
				if (ravV[int(i)].attack_state == RookAttackView.SCRATCHING) {
					// let's move the rav to where he is being displayed right now before moving offscreen
					var rect:Rectangle = ravV[int(i)].getRect(ravV[int(i)].parent);
					ravV[int(i)].x = rect.x;
					ravV[int(i)].y = rect.y;
				}
				
				moveRAVOffscreen(ravV[int(i)], onRAVAtOffscreenPtAfterAttackEnded);
			}
			removeUnReadyRSDVs();
			rm.rook_attack_is_running = false;
		}
		
		private function scatterRAVs():void {
			CONFIG::debugging {
				Console.log(666, 'scatterRAVs called');
			}
			for (var i:int;i<ravV.length;i++) {
				if (ravV[int(i)].attack_state == RookAttackView.SCATTERED) continue;
				CONFIG::debugging {
					Console.log(666, 'scatterRAVs scattered '+i);
				}
				clearRDVForRAV(ravV[int(i)]);
				moveRAVOffscreen(ravV[int(i)], onRAVAtOffscreenPtAfterScatter);
			}
			
			// let's also kill any scratch damages that have not compeleted their initital scratch (which likely means that the rav doing the scratchign just got scattered)
			
			removeUnReadyRSDVs();
		}
		
		
		private var unreadyRsdvV:Vector.<RookScratchDamageView> = new Vector.<RookScratchDamageView>();
		private function removeUnReadyRSDVs():void {
			unreadyRsdvV.length = 0;
			for (i=0;i<rsdvV.length;i++) {
				// heal_cnt is -1 by default, we set it to 0, when it is rdy to be healed
				if (rsdvV[int(i)].heal_cnt == -1) unreadyRsdvV.push(rsdvV[int(i)]);
			}
			
			for (var i:int;i<unreadyRsdvV.length;i++) {
				if (rsdvV.indexOf(unreadyRsdvV[int(i)]) > -1) rsdvV.splice(rsdvV.indexOf(unreadyRsdvV[int(i)]), 1);
				unreadyRsdvV[int(i)].parent.removeChild(unreadyRsdvV[int(i)]);
				unreadyRsdvV[int(i)].dispose();
			}
		}
		
		private var damagedIdleRPDVA:Array = [];
		private var readyRsdvV:Vector.<RookScratchDamageView> = new Vector.<RookScratchDamageView>();
		private var heal_anim_seqA:Array = [];

		private function onHealLoop():void {
			if (MathUtil.chance(rm.rav_chance_heal_loop_will_do_nothing)) { // chance we will do nothing
				return;
			}
			
			var i:int;
			
			damagedIdleRPDVA.length = 0;
			for (i=0;i<rpdvV.length;i++) {
				if (!rdv_to_rav[rpdvV[int(i)]]) {
					if (rpdvV[int(i)].peck_cnt > 0) damagedIdleRPDVA.push(rpdvV[int(i)]);
				}
			}
			
			/*var stillDamagedRpdvA:Array = getIdleRPDVA().filter(function(m:*, i:int, A:Array):Boolean {
				return (m.peck_cnt > 0);
			});*/
			
			
			readyRsdvV.length = 0;
			for (i=0;i<rsdvV.length;i++) {
				// heal_cnt is -1 by default, we set it to 0, when it is rdy to be healed
				if (rsdvV[int(i)].heal_cnt > -1) readyRsdvV.push(rsdvV[int(i)]);
			}
			
			/*
			var readyRsdvV:Vector.<RookScratchDamageView> = rsdvV.filter(function(m:RookScratchDamageView, i:int, V:Vector.<RookScratchDamageView>):Boolean {
				return (m.heal_cnt > -1); // it is -1 by default, we set it to 0, when it is rdy to be healed
			});*/
			
			var rnd:int = MathUtil.randomInt(0,1);
			
			// we only want to heal one thing below. If one of the arrays is empty, then we know we can do a heal in the other array;
			// if neither are empty, we do a peck heal if rnd = 0, and a scratch heal if rnd = 1
			
			if (damagedIdleRPDVA.length && (readyRsdvV.length == 0 || rnd == 0)) {
				var rpdv:RookPeckDamageView = damagedIdleRPDVA[MathUtil.randomInt(0, damagedIdleRPDVA.length-1)];
				var f:int = 2;
				var curr:String = rpdv.damage_id+(rpdv.peck_cnt)+':';
				var prev:String = ((rpdv.peck_cnt == 1) ? 'empty' : rpdv.damage_id+(rpdv.peck_cnt-1))+':';
				heal_anim_seqA.length = 0;
				//var A:Array = [
					heal_anim_seqA.push(prev+3);
					heal_anim_seqA.push(curr+3);
					heal_anim_seqA.push(prev+2);
					heal_anim_seqA.push(curr+2);
					heal_anim_seqA.push(prev+1);
					heal_anim_seqA.push(curr+1);
					heal_anim_seqA.push(prev+1);
				//];
				
				rpdv.peck_cnt--;
				
				if (rpdv.peck_cnt > 0) {
					rpdv.animate(new AnimationSequenceCommand(heal_anim_seqA, false), null);
				} else {
					rpdvV.splice(rpdvV.indexOf(rpdv), 1);
					rpdv.animate(new AnimationSequenceCommand(heal_anim_seqA, false), function(rpdv:RookPeckDamageView):void {
						rpdv.parent.removeChild(rpdv);
						rpdv.dispose();
					});
				}
			}
			
			if (readyRsdvV.length && (damagedIdleRPDVA.length == 0 || rnd == 1)) {
				var rsdv:RookScratchDamageView = readyRsdvV[MathUtil.randomInt(0, readyRsdvV.length-1)];
				rsdv.heal_cnt++;
				rsdv.animate(new AnimationSequenceCommand(['scratchFXHeal'+rsdv.heal_cnt], false), function():void {
					if (rsdv.heal_cnt == 4) {
						if (rsdvV.indexOf(rsdv) > -1) rsdvV.splice(rsdvV.indexOf(rsdv), 1);
						rsdv.parent.removeChild(rsdv);
						rsdv.dispose();
					} 
				});
			}
		}
		
		private function onAttackLoop():void {
			CONFIG::debugging {
				Console.log(666, 'onAttackLoop called');
			}
			if (rm.rook_fly_forward_is_running) {
				reason();
				return;
			}
			if (rm.rook_wing_beat_is_running) {
				reason();
				return;
			}
			//if (rm.rook_fly_side_sequence_is_running) return; we don't need this I don't think
			
			if (MathUtil.chance(rm.rav_chance_attack_loop_will_do_nothing)) { // chance we will do nothing
				return;
			}
			CONFIG::debugging {
				Console.log(666, 'onAttackLoop go');
			}
			
			var allowed_cnt:int = Math.min(rm.rav_in_use_max, Math.max(1, rm.rook_fly_forward_cnt));
			if (false) { 
				// TODO: if the client reloaded or we rentered a loc that is rooked, we should make allowed_cnt the allowed_cnt it was when last in loc
			}
			if (ravV.length < allowed_cnt) {
				// make a new one!
				var rav:RookAttackView = getNewRAV(getOffscreenPtForRav(), 0, 0);
				if (!rav.loaded) {
					rav.addEventListener(TSEvent.COMPLETE, function():void {
						onRAVAtOffscreenPt(rav);
					});
				} else {
					onRAVAtOffscreenPt(rav);
				}
			}
			
			// get any scattered ones back into the mix
			for (var i:int;i<ravV.length;i++) {
				//if (i >= allowed_cnt) break;
				if (ravV[int(i)].attack_state == RookAttackView.SCATTERED) {
					; // satisfy compiler
					CONFIG::debugging {
						Console.log(666, 'sending scattered RAV back in');
					}
					onRAVAtOffscreenPt(ravV[int(i)]);
					ravV[int(i)].visible = true;
				} 
			}
		}
		
		private function getNewRAV(pt:Point, wh:int, r:Number):RookAttackView {
			var rav:RookAttackView;
			rav = new RookAttackView(wh || MathUtil.randomInt(rm.rav_min_wh, rm.rav_max_wh));
			rav.x = pt.x;
			rav.y = pt.y;
			rav.r = r;
			attack_container.addChild(rav);
			rav.visible = true;
			ravV.push(rav);
			
			//Console.warn('new rav '+rav.x+':'+rav.y+' rotation:'+rav.r+' wh:'+rav.wh);
			return rav;
		}
		
		private function getNewRPDV(pt:Point, wh:int, r:Number):RookPeckDamageView {
			var rpdv:RookPeckDamageView;
			rpdv = new RookPeckDamageView(wh);
			
			var rnd:int = MathUtil.randomInt(1, 6);
			if (rnd == 1) {
				rpdv.damage_to_peck_animA = rm.rav_damageA_to_peck_animA;
				rpdv.damage_id = 'peckFXA';
			} else if (rnd == 2) {
				rpdv.damage_to_peck_animA = rm.rav_damageB_to_peck_animA;
				rpdv.damage_id = 'peckFXB';
			} else if (rnd == 3) {
				rpdv.damage_to_peck_animA = rm.rav_damageC_to_peck_animA;
				rpdv.damage_id = 'peckFXC';
			} else if (rnd == 4) {
				rpdv.damage_to_peck_animA = rm.rav_damageD_to_peck_animA;
				rpdv.damage_id = 'peckFXD';
			} else if (rnd == 5) {
				rpdv.damage_to_peck_animA = rm.rav_damageE_to_peck_animA;
				rpdv.damage_id = 'peckFXE';
			} else if (rnd == 6) {
				rpdv.damage_to_peck_animA = rm.rav_damageF_to_peck_animA;
				rpdv.damage_id = 'peckFXF';
			}
			
			rpdv.x = pt.x;
			rpdv.y = pt.y;
			rpdv.r = r;
			damage_container.addChild(rpdv);
			rpdv.visible = false;
			rpdvV.push(rpdv);
			
			//Console.warn('new rpdv '+rpdv.x+':'+rpdv.y+' rotation:'+rpdv.r+' wh:'+rpdv.wh);
			return rpdv;
		}
		
		private function getNewRSDV(pt:Point, wh:int, r:Number):RookScratchDamageView {
			var rsdv:RookScratchDamageView;
			rsdv = new RookScratchDamageView(wh);
			
			rsdv.x = pt.x;
			rsdv.y = pt.y;
			rsdv.r = r;
			damage_container.addChild(rsdv);
			rsdv.visible = true;
			rsdvV.push(rsdv);
			
			//Console.warn('new rsdv '+rsdv.x+':'+rsdv.y+' rotation:'+rsdv.r+' wh:'+rsdv.wh);
			return rsdv;
		}
		
		private function checkRAVCollisions():void {
			//return;
			if (ravV.length > 1) {
				var i:int = 0;
				var j:int = 0;
				var cnt:int = ravV.length;
				var rav1:RookAttackView;
				var rav2:RookAttackView;
				for (i;i<cnt;i++)  {
					rav1 = ravV[int(i)];
					if (!rav1.mc) continue;
					for (j=i+1;j<cnt;j++) {
						rav2 = ravV[int(j)];
						if (!rav2.mc) continue;
						if (rav1.hit_target.hitTestObject(rav2.hit_target)) {
							
							if (rav1.attack_state == RookAttackView.MOVING_OFFSCREEN || rav2.attack_state == RookAttackView.MOVING_OFFSCREEN) {
								// we can ignore, becuase one is already moving offscreen
								
							} else {
								if (rav1.attack_state == RookAttackView.AT_ATTACK_PNT && rav2.attack_state == RookAttackView.AT_ATTACK_PNT) {
									// hopefully this never happens
									
								} else if (rav1.attack_state == RookAttackView.AT_ATTACK_PNT) {
									clearRDVForRAV(rav2);
									moveRAVOffscreen(rav2, onRAVAtOffscreenPt);
									
								} else if (rav2.attack_state == RookAttackView.AT_ATTACK_PNT) {
									clearRDVForRAV(rav1);
									moveRAVOffscreen(rav1, onRAVAtOffscreenPt);
									
								} else { // neither are at attack pt
									if (rav_to_rdv[rav1]) { // 1 is moving to attack pt
										clearRDVForRAV(rav2);
										moveRAVOffscreen(rav2, onRAVAtOffscreenPt);
										
									} else if (rav_to_rdv[rav2]) { // 2 is moving to attack pt
										clearRDVForRAV(rav1);
										moveRAVOffscreen(rav1, onRAVAtOffscreenPt);
										
									} else { // neither moving to attack pt
										moveRAVOffscreen(rav1, onRAVAtOffscreenPt);
										
									}
								}
							}
						}
					}
				}
			}
		}
		
		private function clearRDVForRAV(rav:RookAttackView):void {
			var rdv:*;
			if (rav_to_rdv[rav]) {
				// make sure we do not rememeber this no mores
				rdv = rav_to_rdv[rav];
				rav_to_rdv[rav] = null;
				delete rav_to_rdv[rav];
				rdv_to_rav[rdv] = null;
				delete rdv_to_rav[rdv];
			}
		}
		
		// -----------------------------------------------------------------------------------------------------
		// attack pt getters
		// -----------------------------------------------------------------------------------------------------
		
		// returns a pt where the rook should end up
		private function getOffscreenPtForRav():Point {
			var pt:Point = new Point(0, 0);
			
			// reject any pts that are in this rect, which is slightly bigger than screen size
			var rect:Rectangle = new Rectangle(
				-rm.rav_placement_padd*5,
				-rm.rav_placement_padd*5,
				StageBeacon.stage.stageWidth+(rm.rav_placement_padd*5),
				StageBeacon.stage.stageHeight+(rm.rav_placement_padd*5)
			);
			
			var cnt:int = 1;
			while (rect.containsPoint(pt)) {
				pt.x = MathUtil.randomInt(-rm.rav_placement_padd*6, StageBeacon.stage.stageWidth+(rm.rav_placement_padd*6));
				pt.y = MathUtil.randomInt(-rm.rav_placement_padd*6, StageBeacon.stage.stageHeight+(rm.rav_placement_padd*6));
				cnt++;
			}
			
			//Console.log(666, cnt);
			return pt;
		}
		
		// returns a pt where the rook should end up
		private function getOnscreenPtforRav():Point {
			return new Point(
				MathUtil.randomInt(rm.rav_placement_padd, StageBeacon.stage.stageWidth-rm.rav_placement_padd),
				MathUtil.randomInt(rm.rav_placement_padd, StageBeacon.stage.stageHeight-rm.rav_placement_padd)
			);
		}
		
		// returns a pt where the rook should end up
		private function getScratchPt():Point {
			return getOnscreenPtforRav();
		}
		
		// returns a pt where the PECK will be, not the rook
		private function getNewBeakPt():Point {
			var pt:Point = new Point(0, 0);

			// reject any pts that are in this rect, which is the center of the screen
			var ok_side:int = 200; // how far in from the edges of the viewport is ok?
			var rect:Rectangle = new Rectangle(
				model.layoutModel.gutter_w+ok_side,
				ok_side,
				model.layoutModel.loc_vp_w-(ok_side*2),
				StageBeacon.stage.stageHeight
			);
			
			var cnt:int = 1;
			while (rect.containsPoint(pt) || pt.x==0 && pt.y==0) {
				// try a point above the pack, but not at the very screen edge
				pt.x = MathUtil.randomInt(50, StageBeacon.stage.stageWidth-(50));
				pt.y = MathUtil.randomInt(50, model.layoutModel.header_h+model.layoutModel.loc_vp_h-(50));
				cnt++;
			}
			
			//Console.log(666, cnt);
			return pt;
		}
		
		// -----------------------------------------------------------------------------------------------------
		// attack movement starters
		// -----------------------------------------------------------------------------------------------------
		
		/*
		animations = ['scratchAttack', 'walk', 'hop', 'creepy1', 'creepy2', 'standStill', 'idle', 'peck1', 'peck2', 'peck3', 'peck4', 'peck5', 'peck6'];
		*/
		
		private function moveRAVOnscreen(rav:RookAttackView, from_offscreen:Boolean):void {
			attack_container.addChild(rav);
			//Console.warn('moveRAVOnscreen');
			var start_pt:Point = new Point(rav.x, rav.y);
			var end_pt:Point = getOnscreenPtforRav();
			var moveA:Array = (from_offscreen) ? rm.rav_flyA : ObjectUtil.randomFromArray([rm.rav_walk1A, rm.rav_walk2A]);
			var endA:Array = (from_offscreen) ? ['shortFlyDown', ObjectUtil.randomFromArray(rm.rav_idleA)] : [ObjectUtil.randomFromArray(rm.rav_idleA)];
			var pps:int = (from_offscreen) ? rm.rav_fly_pps : rm.rav_walk_pps;
			
			
			// if we're using rm.rav_walk1A then sometimes do the hop
			if ((moveA == rm.rav_walk1A || moveA == rm.rav_walk2A) && MathUtil.chance(rm.rav_chance_will_hop)) {
				moveA = rm.rav_hopA;
				pps = rm.rav_hop_pps;
			}
			
			while (Point.distance(start_pt, end_pt) < rm.rav_path_dist_min) {
				end_pt = getOnscreenPtforRav();
			}

			//Console.warn('moveA:'+moveA)
			rav.attack_state = RookAttackView.MOVING_ONSCREEN;
			rav.animateTo(
				end_pt,
				pps,
				new AnimationSequenceCommand(moveA.concat(), true),
				new AnimationSequenceCommand(endA.concat(), false),
				onRAVAtOnscreenPt
			);
			//Console.warn('animateTo sent');
		}
		
		private function moveRAVToPeck(rav:RookAttackView):Boolean {
			//Console.warn('moveRAVToPeck');
			var g:Graphics = attack_container.graphics
			g.clear();
			
			var rav_pt:Point = new Point(rav.x, rav.y);
			var beak_pt:Point = getNewBeakPt(); // the point at which the actual peck fx should appear, which is not the same as the x,y of the rpdv
			var attack_pt:Point;
			var desired_distance_from_beak_pt:Number;
			var rpdv:RookPeckDamageView;
			
			while (Point.distance(beak_pt, rav_pt) < rm.rav_path_dist_min) {
				beak_pt = getNewBeakPt();
			}
			
			for (var i:int;i<rpdvV.length;i++) {
				if (Point.distance(rpdvV[int(i)].beak_pt, beak_pt) < 300) {
					rpdv = rpdvV[int(i)];
					break;
				}				
			}
			
			if (rpdv) { // we have an rpdv that is not a target already
				if (rdv_to_rav[rpdv]) {
					// that point was close to a rpdv, but that rpdv is already a target
					return false;
				} 
				
				rav_to_rdv[rav] = rpdv;
				rdv_to_rav[rpdv] = rav;
				attack_pt = rpdv.attack_pt;
				
			} else {
				desired_distance_from_beak_pt = rm.rav_center_to_beak*rav.mc.scaleX;
				// find the pt in between where the peck shoudl appear and where the rav is that places the rav correctly to pack at the beak_pt
				attack_pt = GeomUtil.getPtBetweenTwoPts(beak_pt, rav_pt, desired_distance_from_beak_pt);
				
				//  create the fucker now
				rpdv = getNewRPDV(attack_pt, rav.wh, 0);
				rav_to_rdv[rav] = rpdv;
				rdv_to_rav[rpdv] = rav;
				rpdv.attack_pt = attack_pt;
				rpdv.beak_pt = beak_pt;
				
			}
			
			if (EnvironmentUtil.getUrlArgValue('SWF_show_rook_pts') == '1') {
				if (beak_pt) {
					g.beginFill(0xcc0000,10);
					g.drawCircle(beak_pt.x, beak_pt.y, 10);
					g.endFill();
				}
				
				g.beginFill(0x00cc00,10);
				g.drawCircle(attack_pt.x, attack_pt.y, 10);
				g.endFill();
				
				g.beginFill(0x0000cc,10);
				g.drawCircle(rav_pt.x, rav_pt.y, 10);
				g.endFill();
			}
			
			var moveA:Array = ObjectUtil.randomFromArray([rm.rav_walk1A, rm.rav_walk2A]);
			var pps:int = rm.rav_walk_pps;
			
			// sometimes do the hop
			if (MathUtil.chance(rm.rav_chance_will_hop)) {
				moveA = rm.rav_hopA;
				pps = rm.rav_hop_pps;
			}
			
			rav.attack_state = RookAttackView.MOVING_ONSCREEN;
			rav.animateTo(
				attack_pt,
				pps,
				new AnimationSequenceCommand(moveA.concat(), true),
				new AnimationSequenceCommand([ObjectUtil.randomFromArray(rm.rav_idleA).concat()], false),
				onRAVAtPeckPt
			);
			
			return true;
		}
		
		private function moveRAVToScratch(rav:RookAttackView, rsdv:RookScratchDamageView):void {
			
			rav.attack_state = RookAttackView.SCRATCHING;
			
			if (!rsdv.loaded) {
				rsdv.addEventListener(TSEvent.COMPLETE, function():void {
					moveRAVToScratch(rav, rsdv);
				});
				return;
			}
			
			var end_pt:Point = getScratchPt();
			
			rsdv.animate(new AnimationSequenceCommand(['scratchAttack'], false), function():void {
				rsdv.heal_cnt = 0; // this marks it as ready to be healed
			});
			rsdv.x = end_pt.y;
			rsdv.y = end_pt.y;
			
			//rav.animate('scratchAttack', null);
			rav.animate(new AnimationSequenceCommand(['scratchAttack'], false), onRAVAtScratchPt);
			rav.x = end_pt.y;
			rav.y = end_pt.y;
		}
		
		private function moveRAVOffscreen(rav:RookAttackView, afterFunc:Function):void {
			attack_container.addChild(rav);
			var end_pt:Point = getOffscreenPtForRav();
			
			//Console.warn(end_pt);
			rav.attack_state = RookAttackView.MOVING_OFFSCREEN;
			rav.animateTo(
				end_pt,
				rm.rav_fly_pps,
				new AnimationSequenceCommand(rm.rav_flyA.concat(), false),
				null,
				afterFunc
			);
		}
		
		// -----------------------------------------------------------------------------------------------------
		// attack movement end handlers
		// -----------------------------------------------------------------------------------------------------
		
		
		private function onRAVAtOffscreenPt(rav:RookAttackView):void {
			
			//moveRAVOffscreen(rav, onRAVAtOffscreenPt);
			//return;
			
			//Console.warn('onRAVAtOffscreenPt');
			if (rsdvV.length < rm.rav_scratch_max && MathUtil.chance(rm.rav_chance_will_scratch)) { // chance he will do scratch now, if not too much damagae is already showing
				var rsdv:RookScratchDamageView = getNewRSDV(new Point(0,0), rav.wh, rav.r);
				moveRAVToScratch(rav, rsdv);
			} else if (MathUtil.chance(rm.rav_chance_will_peck) && moveRAVToPeck(rav)) { // chance he will do peck now
				//
			} else {
				moveRAVOnscreen(rav, true);
			}
		}
		
		private function onRAVAtOffscreenPtAfterAttackEnded(rav:RookAttackView):void {
			if (ravV.indexOf(rav) > -1) ravV.splice(ravV.indexOf(rav), 1);
			if (rav.parent) rav.parent.removeChild(rav);
			rav.dispose();
			//Console.warn('ravV.length:'+ravV.length);
		}
		
		private function onRAVAtOffscreenPtAfterScatter(rav:RookAttackView):void {
			rav.attack_state = RookAttackView.SCATTERED; // this marks them as scattered, and they should stay there until
														 //attackLoop runs again and conditions are right to let them move again
			rav.visible = false;
			CONFIG::debugging {
				Console.log(666, 'onRAVAtOffscreenPtAfterScatter');
				//Console.warn('ravV.length:'+ravV.length);
			}
		}
		
		private function onRAVAtOnscreenPt(rav:RookAttackView):void {
			//Console.warn('onRAVAtOnscreenPt')
			if (MathUtil.chance(rm.rav_chance_will_peck) && moveRAVToPeck(rav)) { // chance he will do peck now
				//
			} else if (MathUtil.chance(rm.rav_chance_will_move_offscreen)) { // chance he will do go offscreen now.
				moveRAVOffscreen(rav, onRAVAtOffscreenPt);
			} else {
				moveRAVOnscreen(rav, false);
			}
		}
		
		private function onRAVAtScratchPt(rav:RookAttackView):void {
			moveRAVOffscreen(rav, onRAVAtOffscreenPt);
		}
		
		private function onRAVAtPeckPt(rav:RookAttackView, rpdv:RookPeckDamageView = null):void {
			if (!rpdv) {
				rpdv = rav_to_rdv[rav];
			}
			
			if (!rpdv) {
				CONFIG::debugging {
					Console.error('NO RPDV!!');
				}
				return;
			}
			
			if (!rpdv.loaded) {
				rpdv.addEventListener(TSEvent.COMPLETE, function():void {
					onRAVAtPeckPt(rav, rpdv);
				});
				return;
			}
			
			rav.attack_state = RookAttackView.AT_ATTACK_PNT;
			
			if (!rpdv.visible) { // it was created when we started this rav move, but not yet made visible and oriented
				rpdv.visible = true;
				rpdv.r = rav.r;
			} else {
				if (rav.r != rpdv.r) { // rotate rav to match existing rpdv
					TSTweener.addTween(rav, {r:rpdv.r, time:.5, onComplete:null});
					rav.animate(new AnimationSequenceCommand([ObjectUtil.randomFromArray(rm.rav_rotateA)], false), function():void {
						onRAVAtPeckPt(rav, rpdv);
					})
					return;
				}
			}
			
			// which damage?
			var damage_id:String = rpdv.damage_id;//'peckFXB';
			var damage_to_peck_animA:Array = rpdv.damage_to_peck_animA;
			var peck_anim:String;
			
			if (rpdv.peck_cnt < damage_to_peck_animA.length) { // we're going to do some new damage
				
				rpdv.peck_cnt++;
				
				// get the correct peck animation for the given damage
				peck_anim = damage_to_peck_animA[rpdv.peck_cnt-1];
				var peck_index:int = rm.rav_peckA.indexOf(peck_anim);
				//Console.warn(peck_anim+' of '+rm.rav_peckA);
				
				// build the damage anim string
				var damage_anim:String = damage_id+rpdv.peck_cnt; // peckFXB+[1-8]
				
				// the anim we want to hold on, for X frames
				var hold_anim:String = rpdv.mc.animatee.currentFrameLabel;
				//Console.warn('rpdv.mc.animatee.currentFrameLabel '+rpdv.mc.animatee.currentFrameLabel)
				
				var hold_cnt:int;
				// how many frames do we hold it for
				if (peck_anim.indexOf('scratch') > -1) { // if it is a scratch, wait until the second damage frame
					hold_cnt = rm.rav_peck_damage_frame2A[peck_index];
				} else {
					hold_cnt = rm.rav_peck_damage_frame1A[peck_index];
				}
				
				//Console.warn('AAAA damage_anim:'+ damage_anim+' hold_anim:'+hold_anim+':'+hold_cnt);
				rpdv.animate(new AnimationSequenceCommand([hold_anim+':'+hold_cnt, damage_anim], false), null);
				
			} else { // no new damage, use a random peck
				
				peck_anim = ObjectUtil.randomFromArray(damage_to_peck_animA);
				
			}
			
			// have the rav peck
			var peck_seqA:Array = [peck_anim];
			
			if (MathUtil.chance(25)){
				peck_seqA.push(ObjectUtil.randomFromArray(rm.rav_idleA));
			}
			/*
			if (MathUtil.chance(25)){
				peck_seqA.push(ObjectUtil.randomFromArray(rm.rav_idleA));
			} 
			*/
			rav.animate(new AnimationSequenceCommand(peck_seqA, false), onRavPeckAnimationSeqComplete);
		}
		
		private function onRavPeckAnimationSeqComplete(rav:RookAttackView):void {
			
			var rpdv:RookPeckDamageView = rav_to_rdv[rav];
			
			if (!rpdv) {
				CONFIG::debugging {
					Console.error('NO RPDV!!');
				}
				return;
			}
			
			var damage_to_peck_animA:Array = rpdv.damage_to_peck_animA;
			
			// need a better way to know how many anims there are
			if (rpdv.peck_cnt < damage_to_peck_animA.length && MathUtil.chance(rm.rav_chance_will_repeat_peck)) {
				onRAVAtPeckPt(rav, rpdv);
				
			} else {
				clearRDVForRAV(rav);
				moveRAVOffscreen(rav, onRAVAtOffscreenPt)
				
			}
		}
				
		private var has_focus:Boolean;
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function hasFocus():Boolean {
			return has_focus;
		}
		
		public function focus():void {
			CONFIG::debugging {
				Console.log(99, 'focus');
			}
			has_focus = true;
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur');
			}
			has_focus = false;
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return true;
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			
		}
		
		public function registerSelfAsFocusableComponent():void {
			model.stateModel.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			model.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
	}
}
