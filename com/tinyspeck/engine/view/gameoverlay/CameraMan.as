package com.tinyspeck.engine.view.gameoverlay {
	
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.quietless.bitmap.BitmapSnapshot;
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCBuff;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.StateModel;
	import com.tinyspeck.engine.net.NetOutgoingCameraModeEndedVO;
	import com.tinyspeck.engine.net.NetOutgoingCameraModeStartedVO;
	import com.tinyspeck.engine.physics.avatar.AvatarPhysicsObject;
	import com.tinyspeck.engine.physics.avatar.PhysicsSetting;
	import com.tinyspeck.engine.port.FurnUpgradeDialog;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.BoundedAverageValueTracker;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.geom.GeomUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.PCView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.ui.glitchr.GlitchrSnapshotView;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.KeyboardEvent;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.BlurFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	public class CameraMan extends TSSpriteWithModel implements IFocusableComponent {
		/** How many pixels per second */
		public static const SNAPSHOT_TYPE_USER:String = 'SNAPSHOT_TYPE_USER';
		public static const SNAPSHOT_TYPE_LOADING:String = 'SNAPSHOT_TYPE_LOADING';
		public static const SNAPSHOT_TYPE_NORMAL:String = 'SNAPSHOT_TYPE_NORMAL';
		public static const SNAPSHOT_TYPE_FULL:String = 'SNAPSHOT_TYPE_FULL';
		
		
		/** How many pixels per second */
		public static const CAM_INCREMENT:int = 450;
		
		public var cam_vx_x_adj:int = 0;
		public var waiting_on_save:Boolean;
		public var waiting_on_glitchr:Boolean;
		
		private var is_in_user_mode:Boolean;
		private var has_focus:Boolean;
		private var limit_r:int;
		private var limit_l:int;
		private var limit_b:int;
		private var limit_t:int;
		
		private var stayBuzzedAroundX:int;
		private var stayBuzzedAroundY:int;
		private var last_x_adj:int;
		
		public var center_pt:Point = new Point();
		
		private var averageCenterX:BoundedAverageValueTracker;
		private var averageCenterY:BoundedAverageValueTracker;
		private var averageAdjX:BoundedAverageValueTracker = new BoundedAverageValueTracker(30);
		private var ms_per_loop:BoundedAverageValueTracker;
		
		private var sm:StateModel;
		private var lm:LayoutModel;
		
		private var bss:BitmapSnapshot;
		
		private var last_time:int;
		private var default_dist_limit:int = 30; //about 900 px/sec at 30FPS
		
		private var last_center_pt:Point = new Point(-1000000, -1000000);
		private var elapsed_ms:Number;
		
		/* singleton boilerplate */
		public static const instance:CameraMan = new CameraMan();
		
		public function CameraMan():void {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			ms_per_loop = new BoundedAverageValueTracker(60);
			
			var how_many:int = 10;
			averageCenterX = new BoundedAverageValueTracker(how_many);
			averageCenterY = new BoundedAverageValueTracker(how_many);
			
			sm = model.stateModel;
			lm = model.layoutModel;
			
			registerSelfAsFocusableComponent();
			/*
			CONFIG::god {
				cam_vx_x_adj = 80;
			}
			*/
		}
		
		public function resetCameraCenterAverages():void {
			averageCenterX.reset();
			averageCenterY.reset();
			last_center_pt.x = -1000000;
			last_center_pt.y = -1000000;
		}
		
		public function get y_cam_offset():int {
			var pc:PC = model.worldModel.pc;
			var apo:AvatarPhysicsObject = model.worldModel.pc.apo;
			var offset:int = apo.setting.y_cam_offset;
			
			// special case that we want the home interior offset
			if (model.worldModel.pc.home_info) {
				if (model.worldModel.location.home_type == Location.HOME_TYPE_INTERIOR) {
					// don't change offset if we are in upgrade dialog loc_mode, so things get centered correctly
					if (!model.stateModel.isCompInFocusHistory(FurnUpgradeDialog.instance) || !FurnUpgradeDialog.instance.loc_mode) {
						if (pc.x > 0) {
							offset+= 70;
						}
					}
				}
			}
			
			return  offset*(lm.loc_vp_h/lm.max_vp_h);
		}
		
		public function calcDistLimit():int {
			var dist_limit:int = 0;
			
			if (!(elapsed_ms && elapsed_ms<2000 && last_center_pt.x != -1000000 && last_center_pt.y != -1000000)) {
				// we should not limit camera movement here, but let it snap to place
				return dist_limit;
			}
			
			// We're good!
			
			var multiplier:Number = elapsed_ms/33;
			
			if (sm.in_camera_control_mode) {
				// no limit
			} else if (sm.info_mode) {
				// no limit
			} else if (sm.decorator_mode) {
				// no limit
			} else if (sm.camera_hard_dist_limit) {
				// return now so we do not multiply by multiplier, because this is set with the proper values
				return sm.camera_hard_dist_limit;
			} else {
				if (sm.camera_center_pt) {
					dist_limit = default_dist_limit;
				} else {
					var pc:PC = model.worldModel.pc;
					if (sm.camera_center_itemstack_tsid) {
						dist_limit = default_dist_limit;
					} else if (sm.camera_center_pc_tsid && pc.tsid != sm.camera_center_pc_tsid) {
						dist_limit = default_dist_limit;
					} else {
						// return now so we do not multiply by multiplier twice
						return Math.max(default_dist_limit * multiplier, Math.round(pc.apo.setting.vy_max*(elapsed_ms/1000)));
					}
				}
			}
			
			return dist_limit * multiplier;
		}
		
		public var center_str:String; 
		public var reusable_pt:Point = new Point(); 
		private function calcCenterPt():void {
			var loc:Location = model.worldModel.location;
			if (!loc) return;
			
			var phs:PhysicsSetting = loc.physics_setting;
			if (!phs) return;
			
			var pc:PC = model.worldModel.pc;
			if (!pc) return;
			
			var gameRenderer:LocationRenderer = TSFrontController.instance.getMainView().gameRenderer;
			if (!gameRenderer) return;
			
			var debug_str:String = 'getCenterPt';
			var center_view:DisplayObject;
			elapsed_ms = 0;
			var ms:int = getTimer();
			if (last_time) {
				elapsed_ms = ms-last_time;
			}

			if (elapsed_ms < 0) {
				if (!logged_neg_ms_err) {
					logged_neg_ms_err = true;
					BootError.handleError('ms:'+ms+' last_time:'+last_time+' elapsed_ms:'+elapsed_ms, new Error('elapsed_ms < 0'), ['CamereManNegMS'], true);
				}
				elapsed_ms = 0;
			}

			last_time = ms;
			
			ms_per_loop.push(elapsed_ms);
			CONFIG::debugging {
				Console.trackValue('CM.ms_per_loop', ms_per_loop.averageValue);
			}
			
			var dist_limit:int = calcDistLimit();
			center_str = '';
			
			if (sm.in_camera_control_mode) {
				center_str = 'user control';
				reusable_pt.x = sm.camera_control_pt.x;
				reusable_pt.y = sm.camera_control_pt.y;
				
			} else if (sm.info_mode) {
				center_str = 'info mode control';
				reusable_pt.x = sm.camera_control_pt.x;
				reusable_pt.y = sm.camera_control_pt.y;
				
			} else if (sm.decorator_mode) {
				center_str = 'HOD control';
				reusable_pt.x = sm.camera_control_pt.x;
				reusable_pt.y = sm.camera_control_pt.y;
				
			} else if (sm.camera_center_pt) {
				center_str = 'center_pt';
				reusable_pt.x = sm.camera_center_pt.x + sm.use_camera_offset_x;
				reusable_pt.y = sm.camera_center_pt.y - y_cam_offset;
				
				// This makes things slightly nicer by making sure
				// the pt is never so close to the edges that the
				// scrollrect can't actually scroll there. It may
				// not be efficient though, and we can probably
				// come up with a way to not have to run 
				// setCameraCenterLimits every time.
				setCameraCenterLimits(false);
				boundPt(reusable_pt);
				
			} else {
				if (sm.camera_center_itemstack_tsid) {
					var iiv:LocationItemstackView = gameRenderer.getItemstackViewByTsid(sm.camera_center_itemstack_tsid);
					if (iiv) {
						center_str = 'iiv';
						center_view = iiv;
					} else {
						TSFrontController.instance.resetCameraCenter();
					}
				} else if (sm.camera_center_pc_tsid && pc.tsid != sm.camera_center_pc_tsid) {
					var pcv:PCView = gameRenderer.getPcViewByTsid(sm.camera_center_pc_tsid);
					if (pcv) {
						center_str = 'pcv';
						center_view = pcv;
					} else {
						TSFrontController.instance.resetCameraCenter();
					}
				}
				
				if (center_str) {
					reusable_pt.x = center_view.x;
					reusable_pt.y = center_view.y;
				} else {
					center_str = 'you';
					reusable_pt.x = model.worldModel.pc.x;
					reusable_pt.y = model.worldModel.pc.y;
					center_view = gameRenderer.getAvatarView();
					if (center_view) {
						reusable_pt.x = center_view.x;
						reusable_pt.y = center_view.y;
					}
				}
				
				reusable_pt.x += sm.use_camera_offset_x;
				reusable_pt.y -= y_cam_offset;
				
				debug_str+= ' \ncenter_pt 1:'+reusable_pt;
				
				// This makes things slightly nicer by making sure
				// the pt is never so close to the edges that the
				// scrollrect can't actually scroll there. It may
				// not be efficient though, and we can probably
				// come up with a way to not have to run 
				// setCameraCenterLimits every time.
				setCameraCenterLimits(false);
				boundPt(reusable_pt);
				
				debug_str+= ' \ncenter_pt 2:'+reusable_pt;
				
				// cam_vx_x_adj is 0 by default for now, you can set it to non-zero with "/cam_vx_x_adj X"
				if (cam_vx_x_adj && center_view == gameRenderer.getAvatarView()) {
					var x_adj:int = (pc.apo.vx/phs.vx_max)*cam_vx_x_adj;
					
					var check_vy:Boolean = false;
					
					if (check_vy) {
						if (x_adj == 0 && Math.abs(pc.apo.vy) < 10) {
							x_adj = last_x_adj;
						} else if (Math.abs(pc.apo.vy) < 10 && Math.abs(pc.apo.vx/phs.vx_max) < .9) {
							x_adj = last_x_adj;
						} else if ((x_adj >= 0 && x_adj>last_x_adj) || (x_adj <= 0 && x_adj<last_x_adj)) {
							last_x_adj = x_adj;
						} else {
							x_adj = last_x_adj;
						}
					} else if (false) {
						if (x_adj == 0) {
							x_adj = last_x_adj;
						} else if (Math.abs(pc.apo.vx/phs.vx_max) < .9) {
							if (x_adj > 0) {
								last_x_adj-= 20;
							} else if (x_adj < 0) {
								last_x_adj+= 20;
							}
							x_adj = last_x_adj;
						} else if ((x_adj > 0 && x_adj>last_x_adj) || (x_adj < 0 && x_adj<last_x_adj)) {
							last_x_adj = x_adj;
						} else {
							x_adj = last_x_adj;
						}
					} else {
						if (x_adj == 0) {
							x_adj = last_x_adj;
						} else if (Math.abs(pc.apo.vx/phs.vx_max) < .9) {
							x_adj = last_x_adj;
						} else if ((x_adj > 0 && x_adj>last_x_adj) || (x_adj < 0 && x_adj<last_x_adj)) {
							last_x_adj = x_adj;
						} else {
							x_adj = last_x_adj;
						}
					}
					
					// keep ava on screen!
					if (x_adj > 0) {
						x_adj = Math.min(x_adj, model.layoutModel.loc_vp_w/2.2);
					} else {
						x_adj = Math.max(x_adj, -model.layoutModel.loc_vp_w/2.2);
					}
					averageAdjX.push(x_adj);
					reusable_pt.x+= averageAdjX.averageValue;
				}
			}
			
			CONFIG::debugging {
				Console.trackValue('CM elapsed_ms', elapsed_ms);
				Console.trackValue('CM dist_limit', dist_limit);
				Console.trackValue('CM hard_dist_limit', sm.camera_hard_dist_limit);
				Console.trackValue('CM center on', center_str+' item:'+sm.camera_center_itemstack_tsid+' pc:'+sm.camera_center_pc_tsid+' pt:'+sm.camera_center_pt);
				Console.trackValue('CM y_cam_offset', y_cam_offset);
			}

			if (dist_limit) {
				var dist:int = Math.abs(Point.distance(last_center_pt, reusable_pt));
				if (dist > dist_limit) {
					reusable_pt = GeomUtil.getPtBetweenTwoPts(last_center_pt, reusable_pt, dist_limit);
				}
			}
			
			averageCenterX.push(reusable_pt.x);
			averageCenterY.push(reusable_pt.y);
			
			last_center_pt.x = reusable_pt.x;
			last_center_pt.y = reusable_pt.y;
			
			if (/*model.flashVarModel.new_physics && */model.flashVarModel.tween_camera) {
				if (model.flashVarModel.tween_camera_time) {
					if (reusable_tween_ob.x != reusable_pt.x || reusable_tween_ob.y != reusable_pt.y) {
						reusable_tween_ob.x = reusable_pt.x;
						reusable_tween_ob.y = reusable_pt.y;
						reusable_tween_ob.time = model.flashVarModel.tween_camera_time
						TSTweener.removeTweens(center_pt);
						TSTweener.addTween(center_pt, reusable_tween_ob);
					}
					
				} else {
					center_pt.x = reusable_pt.x;
					center_pt.y = reusable_pt.y;
				}
			} else {
				center_pt.x = averageCenterX.averageValue;
				center_pt.y = averageCenterY.averageValue;
			}
			
			if (isNaN(center_pt.x) || isNaN(center_pt.y)) {
				if (!logged_nan_err) {
					logged_nan_err = true;
					debug_str+= ' \nlast_center_pt:'+last_center_pt;
					debug_str+= ' \naverageCenterX:'+averageCenterX;
					debug_str+= ' \naverageCenterY:'+averageCenterY;
					debug_str+= ' \nms_per_loop:'+ms_per_loop;
					BootError.handleError(debug_str, new Error('averageCenterY||averageCenterX is NaN'), ['CamereManNaN'], true);
					if (!CONFIG::locodeco) {
						TSFrontController.instance.maybeReload(
							'Dang it, you found a bug! It has been logged.'
						);
					}
				}
			}
		}
		
		private var reusable_tween_ob:Object = {transition: 'easeoutquad'};
		
		private var logged_nan_err:Boolean;
		private var logged_neg_ms_err:Boolean;
		
		/**
		 * Only ever call this from TSFC.maybeStartCameraManUsermode(),
		 * and should be ended with TSFC.endCameraManUserMode()
		 */
		public function startUserMode(why:String):Boolean {
			if (!TSFrontController.instance.requestFocus(this, why)) {
				return false;
			}
			
			setCameraCenterLimits(true);
			
			if (is_in_user_mode) {
				boundCameraCameraControlPt();
				CameraManView.instance.update();
			} else {
				TSFrontController.instance.endFamiliarDialog();
				TSFrontController.instance.genericSend(new NetOutgoingCameraModeStartedVO());
				TSFrontController.instance.disableDropToFloor();
				sm.in_camera_control_mode = true;
				sm.camera_control_pt.x = stayBuzzedAroundX = lm.loc_cur_x;
				sm.camera_control_pt.y = stayBuzzedAroundY = lm.loc_cur_y;
				CameraManView.instance.show();
				SoundMaster.instance.playSound('CAMERA_WIND');
			}
			
			is_in_user_mode = true;
			
			return true;
		}
		
		public function setCameraCenterLimits(obey_cam_range:Boolean, min_x:int=int.MIN_VALUE):void {
			var loc:Location = model.worldModel.location;
			var pc:PC = model.worldModel.pc;
			
			limit_r = loc.r-(lm.loc_vp_w/2);
			limit_l = Math.max(min_x, loc.l+(lm.loc_vp_w/2));
			limit_b = loc.b-(lm.loc_vp_h/2);
			limit_t = loc.t+(lm.loc_vp_h/2);
			
			if (obey_cam_range && pc.cam_range > 0) {
				limit_r = Math.min(limit_r, pc.x+pc.cam_range);
				limit_l = Math.max(limit_l, pc.x-pc.cam_range);
				
				// we have to factor in the y_cam_offset that the location renderer uses to keep the avatar towards the bottom of the screen
				var y_cam_offset:int = pc.apo.setting.y_cam_offset*(lm.loc_vp_h/lm.max_vp_h);
				limit_b = Math.min(limit_b, (pc.y - y_cam_offset)+pc.cam_range);
				limit_t = Math.max(limit_t, (pc.y - y_cam_offset)-pc.cam_range);
			}
			
			//Console.warn('limit_r:'+limit_r+' limit_l:'+limit_l+' limit_b:'+limit_b+' limit_t:'+limit_t);
		}
		
		public function endUserMode():void {
			TSFrontController.instance.enableDropToFloor();
			sm.in_camera_control_mode = false;
			TSFrontController.instance.releaseFocus(this);
			if (is_in_user_mode) {
				
				letCameraSnapBackFast();
				
				TSFrontController.instance.genericSend(new NetOutgoingCameraModeEndedVO());
			}
			is_in_user_mode = false;
			CameraManView.instance.hide();
		}
		
		public function letCameraSnapBackFast():void {
			// go back fast, camera! I think it is safe to just leave it 
			// after, as any other camera centering will reset it
			sm.camera_hard_dist_limit = 1000;
		}
		
		public function imposeHardDistLimitByPxPerSecond(px_sec:int):void {
			sm.camera_hard_dist_limit = Math.round((px_sec/1000)*(1000/StageBeacon.stage.frameRate));
		}
		
		public function snap():void {
			var pc:PC = model.worldModel.pc;
			if (!pc.cam_can_snap) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			try {
				SoundMaster.instance.playSound('CAMERA_SHUTTER');
				var bmd:BitmapData = TSFrontController.instance.getMainView().gameRenderer.getSnapshot(
					CameraMan.SNAPSHOT_TYPE_USER,
					0,
					0,
					true,
					true,
					false
				).bitmapData;
				
				// tag everything in the photo NOW so that it matches the content of the photo
				const tags:Object = GlitchrSnapshotView.instance.getTaggingData();
				
				if (isBuzzed()) {
					// add some fake motion blur
					var xBlur:int;
					var yBlur:int;
					
					// emphasize one direction 
					if (Math.random() > 0.5) {
						xBlur = 0;
						yBlur = 64;
					} else {
						xBlur = 64;
						yBlur = 0;
					}
					
					const unblurredBM:Bitmap = new Bitmap(bmd);
					
					const blurredBM:Bitmap = new Bitmap(bmd);
					blurredBM.filters = [new BlurFilter(xBlur, yBlur, BitmapFilterQuality.HIGH)];
					
					const processedBMD:BitmapData = bmd.clone();
					processedBMD.draw(blurredBM);
					processedBMD.draw(unblurredBM, null, new ColorTransform(1, 1, 1, 0.5));
					
					bmd.dispose();
					bmd = processedBMD;
				}

				if (bss) bss.dispose();
				var bssFileName:String =  model.worldModel.location.label.replace(/ /g, '_')+'_'+StringUtil.getUrlDate(new Date())+'.png';
				bss = new BitmapSnapshot(null, bssFileName, 0, 0, bmd);
				
				startWaitingOnGlitchr();
				FlashBulbView.instance.flash(function():void {
					CameraManView.instance.hide();
					GlitchrSnapshotView.instance.start(bss, bssFileName, tags);
				});
				
			} catch(err:Error) {
				// this can happen when hitting ENTER in the browser location field
				CONFIG::debugging {
					Console.error(err);
				}
			}
		}
		
		private function startWaitingOnGlitchr():void {
			waiting_on_save = true;
			waiting_on_glitchr = true;
			CameraManView.instance.hide();
		}
		
		public function stopWaitingOnGlitchr():void {
			waiting_on_save = false;
			waiting_on_glitchr = false;
			CameraManView.instance.show();
			if (bss) {
				bss.dispose();
				bss = null;
			}
		}
		
		private function startWaitingOnSave():void {
			waiting_on_save = true;
			CameraManView.instance.hideButton();
		}
		
		public function onGameLoop(ms_elapsed:int):void {
			if (hasFocus()) {
				const kb:KeyBeacon = KeyBeacon.instance;
				const inc:int = ((CAM_INCREMENT * Math.max(0, model.worldModel.pc.cam_speed_multiplier)) * (ms_elapsed/1000));
				
				var key_down:Boolean = false;
				if (kb.pressed(Keyboard.RIGHT) || kb.pressed(Keyboard.D)) {
					sm.camera_control_pt.x+= inc;
					key_down = true;
				} else if (kb.pressed(Keyboard.LEFT) || kb.pressed(Keyboard.A)) {
					sm.camera_control_pt.x-= inc;
					key_down = true;
				}
				
				if (kb.pressed(Keyboard.DOWN) || kb.pressed(Keyboard.S)) {
					sm.camera_control_pt.y+= inc;
					key_down = true;
				} else if (kb.pressed(Keyboard.UP) || kb.pressed(Keyboard.W)) {
					sm.camera_control_pt.y-= inc;
					key_down = true;
				}
				
				if (isBuzzed()) {
					if (key_down) {
						// when buzzed, we don't want to drift too far off the intended frame
						stayBuzzedAroundX = sm.camera_control_pt.x;
						stayBuzzedAroundY = sm.camera_control_pt.y;
					}
					
					sm.camera_control_pt.x+= MathUtil.randomInt(-inc, inc);
					sm.camera_control_pt.y+= MathUtil.randomInt(-inc, inc);
					sm.camera_control_pt.x = MathUtil.clamp(stayBuzzedAroundX - inc, stayBuzzedAroundX + inc, sm.camera_control_pt.x);
					sm.camera_control_pt.y = MathUtil.clamp(stayBuzzedAroundY - inc, stayBuzzedAroundY + inc, sm.camera_control_pt.y);
				}
				
				if (key_down) {
					TSFrontController.instance.goNotAFK();
					CameraManView.instance.fade();
					boundCameraCameraControlPt();
				} else {
					CameraManView.instance.unfade();
				}
			}
			
			calcCenterPt();
		}
		
		public function boundCameraCameraControlPt():void {
			boundPt(sm.camera_control_pt);
		}
		
		private function boundPt(pt:Point):void {
			pt.x = Math.min(pt.x, limit_r);
			pt.x = Math.max(pt.x, limit_l);
			pt.y = Math.min(pt.y, limit_b);
			pt.y = Math.max(pt.y, limit_t);
		}
		
		private function startListeningForControlEvts():void {
			var kb:KeyBeacon = KeyBeacon.instance;
			
			kb.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onEnterKey);
			kb.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onEscapeKey, false, 0, true);
			kb.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.C, onCKey);
			
			TSFrontController.instance.startListeningToZoomKeys(zoomKeyHandler);
		}
		
		private function stopListeningForControlEvts():void {
			var kb:KeyBeacon = KeyBeacon.instance;
			
			kb.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onEnterKey);
			kb.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onEscapeKey);
			kb.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.C, onCKey);
		
			TSFrontController.instance.stopListeningToZoomKeys(zoomKeyHandler);
		}
		
		private function zoomKeyHandler(e:KeyboardEvent):void {
			// it's important that we don't add shared listeners directly to TSFC
			// because where one class has started listening, another might
			// remove the same listener by accident, so the first class fails
			TSFrontController.instance.zoomKeyHandler(e);
		}
		
		protected function onCKey(e:KeyboardEvent):void {
			CONFIG::perf {
				if (model.flashVarModel.run_automated_tests) return;
			}
			if (waiting_on_save) return;
			TSFrontController.instance.goNotAFK();
			endUserMode();
		}
		
		protected function onEscapeKey(e:KeyboardEvent):void {
			if (waiting_on_save) return;
			TSFrontController.instance.goNotAFK();
			endUserMode();
		}
		
		protected function onEnterKey(e:KeyboardEvent):void {
			if (!StageBeacon.flash_has_focus) return; // wish this worked
			if (waiting_on_save) return;
			snap();
		}
		
		public function hasFocus():Boolean {
			return has_focus;
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			if (has_focus && waiting_on_glitchr) {
				stopWaitingOnGlitchr();
			}
		}
		
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return false;
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur');
			}
			has_focus = false;
			stopListeningForControlEvts();
		}
		
		public function registerSelfAsFocusableComponent():void {
			sm.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			sm.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focus():void {
			if (waiting_on_glitchr) stopWaitingOnGlitchr();
			
			CONFIG::debugging {
				Console.log(99, 'focus');
			}
			has_focus = true;
			startListeningForControlEvts();
		}
		
		private function isBuzzed():Boolean {
			const buffs:Dictionary = model.worldModel.pc.buffs;
			
			const buzzed:PCBuff = buffs['buff_buzzed'];
			var isBuzzed:Boolean = (buzzed && (buzzed.remaining_duration > 0));
			
			const smashed:PCBuff = buffs['buff_smashed'];
			isBuzzed = (isBuzzed || (smashed && (smashed.remaining_duration > 0)));
			
			CONFIG::god {
				const fakeBuzzed:PCBuff = model.worldModel.pc.buffs['buff_fake_buzzed'];
				isBuzzed = (isBuzzed || (fakeBuzzed && (fakeBuzzed.remaining_duration > 0)));
			}
			
			return isBuzzed;
		}
	}
}