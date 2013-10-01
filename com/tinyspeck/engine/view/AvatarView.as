package com.tinyspeck.engine.view {
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.control.engine.AnnouncementController;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.physics.avatar.AvatarPhysicsObject;
	import com.tinyspeck.engine.util.ObjectUtil;
	import com.tinyspeck.engine.view.gameoverlay.ChoicesDialog;
	import com.tinyspeck.engine.view.renderer.debug.PhysicsLoopRenderer;
	import com.tinyspeck.engine.view.renderer.util.AvatarAnimationState;
	import com.tinyspeck.engine.view.ui.Slug;
	
	import flash.utils.getTimer;
	
	public class AvatarView extends AbstractAvatarView {
		private var random_idle_wait_ms:int = 15000;//15000; // wait this many ms before playing a random idle
		private var random_idle_ms:int = 6000; // once played, how long will it last?
		private var random_idle:int = -1;
		private var standing_started_at:Number = -1;
		
		public function AvatarView(tsid:String) {
			super(tsid);
			default_dot_r = 20;
			make_all_sheets = true;
			_show_tf = model.flashVarModel.name_on_avatar;
			
			ss_view_holder.mouseChildren = false;
			ss_view_holder.mouseEnabled = false;
			mouseEnabled = false;
			
			init();
		}
		
		override protected function init():void {
			super.init();
			hit_box.mouseEnabled = false;
			/*var A:Array = [
				[-1889,-28],
				[-1906,-48],
				[-1923,-68],
				[-1937,-84],
				[-1953,-100],
				[-1970,-115],
				[-1987,-129],
				[-2005,-141],
				[-2022,-151],
				[-2039,-159],
				[-2056,-166],
				[-2073,-171],
				[-2090,-174],
				[-2107,-175],
				[-2123,-175],
				[-2139,-173],
				[-2155,-170],
				[-2171,-165],
				[-2187,-158],
				[-2203,-150],
				[-2219,-140],
				[-2235,-129],
				[-2251,-116],
				[-2267,-101],
				[-2283,-85],
				[-2299,-67],
				[-2315,-47],
				[-2331,-28]
			];
			
			var sp:Sprite = new Sprite();
			var g:Graphics = sp.graphics;
			sp.mouseEnabled = false;
			addChild(sp);
			var add_x:int = -A[0][0];
			var add_y:int = -A[0][1];
			
			for (var i:int=0;i<A.length;i++) {
				g.beginFill(0xffffff, 1);
				g.drawCircle(A[int(i)][0]+add_x, A[int(i)][1]+add_y, 3);
				g.endFill();
				g.beginFill(0xffffff, 1);
				g.drawCircle(Math.abs(A[int(i)][0]+add_x), A[int(i)][1]+add_y, 3);
				g.endFill();
			}*/
		}
		
		override public function faceRight():void {
			//Console.info('faceRight')
			_orientation = 1;
			ss_view_holder.scaleX = model.worldModel.pc.reversed ? -1 : 1;
			_chatBubbleManager.orientBubble();
		}
		
		override public function faceLeft():void {
			//Console.error('faceLeft')
			_orientation = -1;
			ss_view_holder.scaleX = model.worldModel.pc.reversed ? 1 : -1;
			_chatBubbleManager.orientBubble();
		}
		
		
		public function get s():String {
			var dir:int = model.worldModel.pc.reversed ? orientation*-1 : orientation;
			var st:String = String(dir * (current_aas+1))+((_stopped) ? '-' : '');
			return st;
		}
		
		override public function changeHandler():void {
			// if it is you and you're not following, ignore.
			if (!model.worldModel.pc.following_pc_tsid) {
				specialChangeHandlers()
			} else {
				super.changeHandler(); // this also calls specialChangeHandlers()
			}
		}
		
		public function updateModel():void {
			var pc:PC = model.worldModel.pc;
			if (!pc) return;
			if (pc.following_pc_tsid) return;
			calcAndSetAvatarViewAnimationState();
			
			if (PhysicsLoopRenderer.instance.visible) model.physicsModel.logLoop(model.physicsModel.render_time_log, getTimer());
			
			if (model.flashVarModel.ava_anim_time) {
				if (tween_ob.x != pc.x || tween_ob.y != pc.y) {
					animateXY(pc.x, pc.y, model.flashVarModel.ava_anim_time);
				}
			} else {
				x = int(pc.x);
				y = int(pc.y);
			}
			
			var apo:AvatarPhysicsObject = pc.apo;
			if (apo) {
				if (apo.movingRight && orientation != 1) {
					faceRight();
				} else if (apo.movingLeft && orientation != -1) {
					faceLeft();
				}
			} else {
				// this should never ever happen WTF
			}
			
			if (model.flashVarModel.use_vec) {
				TSFrontController.instance.maybeSendMoveVec(pc.apo, this.s);
			}
			pc.s = this.s;
		}
		
		public function onOrientationChanged():void {
			changeHandler();
			var apo:AvatarPhysicsObject = model.worldModel.pc.apo;
			if (apo) {
				if (apo.movingRight) {
					faceRight();
				} else if (apo.movingLeft) {
					faceLeft();
				} else {
					if (orientation == 1) {
						faceRight();
					} else {
						faceLeft();
					}
				}
			} else {
				// this should never ever happen WTF
			}
		}
		
		override protected function rook():void {
			if (rooked) return;
			model.activityModel.announcements = Announcement.parseMultiple([{
				type: "vp_overlay",
				dismissible: false,
				locking: true,
				click_to_advance: false,
				text: ['<span class="achievement_description">ROOKED</span>'],
				x: 200,
				y: -3200, // hide it!
				uid: 'fake_locking_annc_for_rooked'
			}]);
			
			super.rook();
		}
		
		override protected function unrook():void {
			if (!rooked) return;
			AnnouncementController.instance.cancelOverlay('fake_locking_annc_for_rooked');
			super.unrook();
		}
		
		private function getStandInForStand():int {
			var pc:PC = model.worldModel.pc;
			
			CONFIG::debugging {
				Console.trackPhysicsValue('AAS', 'doing:'+pc.doing+' emotion:'+pc.emotion+' hit:'+pc.hit);
			}
			
			if (pc.doing) {
				resetIdleTimer();
				return AvatarAnimationState.DO.ID;
			}
			
			if (pc.hit) {
				resetIdleTimer();
				switch (pc.hit) {
					case 'hit2':
						return AvatarAnimationState.HIT2.ID;
					default:
						return AvatarAnimationState.HIT1.ID;
				}
			}
			
			if (model.stateModel.focused_component is ChoicesDialog) {
				return AvatarAnimationState.IDLE4.ID;
			}
			
			if (pc.emotion)  {
				switch (pc.emotion) {
					case PC.HAPPY:
						resetIdleTimer();
						return AvatarAnimationState.HAPPY.ID;
					case PC.ANGRY:
						resetIdleTimer();
						return AvatarAnimationState.ANGRY.ID;
					case PC.SURPRISE:
						resetIdleTimer();
						return AvatarAnimationState.SURPRISE.ID;
				}
			}
			
			if (pc.afk) {
				//resetIdleTimer();
				return AvatarAnimationState.AFK.ID;
			}
			
			if (random_idle != -1) {
				return random_idle;
			}
			
			return AvatarAnimationState.STAND.ID;
		}
		
		private function getStandingMs():int {
			return getTimer()-standing_started_at;
		}
		
		private function resetIdleTimer():void {
			standing_started_at = -1;// reset timer
			random_idle = -1;
		}
		
		private function calcAndSetAvatarViewAnimationState():void {
			var pc:PC = model.worldModel.pc;
			if (pc.following_pc_tsid) return;
			
			// get the aas as indicated by the conditions in apo
			var aas:int = AvatarAnimationState.getAnimationStateFromAPO(pc.apo);

			// if we are standing, let's see if there is an anim we should be using instead of plain stand, and do the idle timer things
			if (aas == AvatarAnimationState.STAND.ID || pc.hit) {
				
				if (standing_started_at == -1) { // record start time
					standing_started_at = getTimer();
				} else if (getStandingMs() > random_idle_wait_ms) { // enough time has passed to at least start showing a random idle
					if (getStandingMs() > random_idle_ms+random_idle_wait_ms) { // the allotted time has passed for this random idle period, reset things
						resetIdleTimer();
					} else if (random_idle == -1) { // none has been set, so choose a random idle
						random_idle = ObjectUtil.randomFromArray(AvatarAnimationState.IDLES_TO_RANDOM);
					}
				}
				
				// now let's override the aas if nec
				aas = getStandInForStand();
				
			} else { // we're not standing
				resetIdleTimer();
			}

			CONFIG::debugging {
				if (aas != current_aas) { 
					Console.trackPhysicsValue('AV anim', AvatarAnimationState.MAP[aas]+' paused:'+AvatarAnimationState.paused);
				}
			}
			
			setAvatarViewAnimationState(AvatarAnimationState.paused, aas);
		}
		
		override public function reloadSSWithNewSheet():void {
			super.reloadSSWithNewSheet();
		}
		
		override public function showHide():void {
			visible = (model.worldModel.location.show_avatar && !model.stateModel.hide_pcs);
		}
		
		public function addSlug(slug:Slug):void {
			addChildAt(slug, 0);
		}
		
		public function removeSlug(slug:Slug):void {
			removeChild(slug);
		}
	}
}