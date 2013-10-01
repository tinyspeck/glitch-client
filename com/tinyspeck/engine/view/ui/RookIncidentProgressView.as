package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.RookModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.gameoverlay.ProgressBar;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.Sprite;
	import flash.filters.BlurFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.getTimer;

	public class RookIncidentProgressView extends Sprite
	{		
		/* singleton boilerplate */
		public static const instance:RookIncidentProgressView = new RookIncidentProgressView();
				
		private const MAX_WIDTH:uint = 350;
		private const TOP_OFFSET:int = 10;
		private const TEXT_ANIMATION_TIME:Number = 2; //how fast the "Rook" and "Attack" text comes on the screen
		private const FULL_ANIMATION_TIME:Number = 3; //how long from 0% - 100% in secs.
		private const UPDATE_ANIMATION_TIME:Number = 3; //anytime updates come in, how long it takes to animate
		private const THROB_ANIMATION_TIME:Number = .8; //the speed at which the rook and attack words scale up and down
		
		private var normal_text_sz:int = 27;
		private var big_text_sz:int = 27;
		
		private var pb_h:uint = 29;
		private var pb_border_w:uint = 2;
		private var strength_pb_bar_c:uint = 0xa594a1;
		private var strength_pb_border_c:uint = 0xffffff;
		private var vuln_pb_bar_c:uint = 0xa594a1;
		private var vuln_pb_border_c:uint = 0xffffff;
		private var pb_x:int;
		private var pb_y:int; //save resources not using POINT
		private var text_large_scale:Number = 1.5;
		
		private var main_view:TSMainView;
		private var layout:LayoutModel;
		private var rm:RookModel;
		private var model:TSModelLocator;
		private var ydm:YouDisplayManager;
		
		private var strength_pb:ProgressBar;
		private var strength_tf:TextField = new TextField();
		private var vuln_pb:ProgressBar;
		private var vuln_tf:TextField = new TextField();
		
		private var top_sp:Sprite = new Sprite();
		private var bottom_sp:Sprite = new Sprite();
		private var top_value_sp:Sprite = new Sprite();
		private var bottom_value_sp:Sprite = new Sprite();
		private var top_value_tf:TextField = new TextField();
		private var bottom_value_tf:TextField = new TextField();
		private var top_tf:TextField = new TextField();
		private var bottom_tf:TextField = new TextField();
		private var very_bottom_tf:TextField = new TextField();
		
		private var progress_blur:BlurFilter = new BlurFilter();
		
		private var has_started:Boolean;
		
		public function RookIncidentProgressView(){
			
			/*****************************************************************
			 * Note: This class is only used for testing the old way of doing
			 * the rook progress stuff.
			 * If you want the current version, @see RookIncidentHeaderView
			 *****************************************************************/
			
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			main_view = TSFrontController.instance.getMainView();
			model = TSModelLocator.instance;
			layout = model.layoutModel;
			rm = model.rookModel;
			ydm = YouDisplayManager.instance;
			
			var css:CSSManager = CSSManager.instance;
			strength_pb_border_c = css.getUintColorValueFromStyle('rook_attack_progress', 'strengthBorderColor', strength_pb_border_c);
			strength_pb_bar_c = css.getUintColorValueFromStyle('rook_attack_progress', 'strengthBarColor', strength_pb_bar_c);
			vuln_pb_border_c = css.getUintColorValueFromStyle('rook_attack_progress', 'vulnBorderColor', vuln_pb_border_c);
			vuln_pb_bar_c = css.getUintColorValueFromStyle('rook_attack_progress', 'vulnBarColor', vuln_pb_bar_c);
			pb_h = css.getNumberValueFromStyle('rook_attack_progress', 'height', pb_h);
			pb_border_w = css.getNumberValueFromStyle('rook_attack_progress', 'borderWidth', pb_border_w);
			text_large_scale = css.getNumberValueFromStyle('rook_attack_text', 'bigScale', text_large_scale);
			
			big_text_sz = normal_text_sz*text_large_scale;
			
			prepTextField(top_tf);
			top_tf.htmlText = '<p class="rook_attack_text">temp</p>';
			
			top_tf.filters = StaticFilters.youDisplayManager_GlowA;
			top_sp.addChild(top_tf);
			
			prepTextField(top_value_tf);
			top_value_tf.htmlText = '<p class="rook_attack_text">temp</p>';
			top_value_tf.filters = StaticFilters.youDisplayManager_GlowA;
			
			top_sp.addChild(top_value_sp);
			addChild(top_sp);
			
			prepTextField(bottom_tf);
			bottom_tf.htmlText = '<p class="rook_attack_text">temp</p>';
			bottom_tf.filters = StaticFilters.youDisplayManager_GlowA;
			bottom_sp.addChild(bottom_tf);
			
			prepTextField(bottom_value_tf);
			bottom_value_tf.htmlText = '<p class="rook_attack_text">temp</p>';
			bottom_value_tf.filters = StaticFilters.youDisplayManager_GlowA;
			
			bottom_sp.addChild(bottom_value_sp);
			addChild(bottom_sp);
			
			strength_pb = new ProgressBar(100, pb_h); //width changes dynamically depending on client size
			strength_pb.setBarColors(strength_pb_bar_c, strength_pb_bar_c, strength_pb_bar_c, strength_pb_bar_c);
			strength_pb.setBorderColor(strength_pb_border_c, pb_border_w);
			strength_pb.setFrameColors(strength_pb_border_c, strength_pb_border_c);
			strength_pb.change_speed = UPDATE_ANIMATION_TIME;
			addChild(strength_pb);
			
			prepTextField(strength_tf);
			strength_tf.htmlText = '<p class="rook_attack_strength">Attack strength</p>';
			strength_tf.x = 10;
			strength_tf.y = Math.round(strength_pb.height/2 - strength_tf.height/2) - 1;
			strength_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			strength_pb.addChild(strength_tf);
			
			vuln_pb = new ProgressBar(100, pb_h); //width changes dynamically depending on client size
			vuln_pb.setBarColors(vuln_pb_bar_c, vuln_pb_bar_c, vuln_pb_bar_c, vuln_pb_bar_c);
			vuln_pb.setBorderColor(vuln_pb_border_c, pb_border_w);
			vuln_pb.setFrameColors(vuln_pb_border_c, vuln_pb_border_c);
			vuln_pb.change_speed = UPDATE_ANIMATION_TIME;
			addChild(vuln_pb);
			
			prepTextField(vuln_tf);
			vuln_tf.htmlText = '<p class="rook_attack_strength">TEMP</p>';
			vuln_tf.x = 10;
			vuln_tf.y = Math.round(vuln_pb.height/2 - vuln_tf.height/2) - 1;
			vuln_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			vuln_pb.addChild(vuln_tf);
			
			very_bottom_tf.visible = true;
			prepTextField(very_bottom_tf);
			very_bottom_tf.htmlText = '<p class="rook_attack_text_smaller_red"></p>';
			very_bottom_tf.filters = StaticFilters.youDisplayManager_GlowA;
			addChild(very_bottom_tf);
			
			y = Math.round(TOP_OFFSET + top_tf.height/2);
			
			visible = false;
		}
		
		public function setTopAndBottomText(top_txt:String, bottom_txt:String, very_bottom_txt:String = '', top_value_txt:String = '', bottom_value_txt:String = '', glow:Boolean = false):void {
			top_tf.htmlText = '<p class="rook_attack_text">'+top_txt+'</p>';
			bottom_tf.htmlText = '<p class="rook_attack_text">'+bottom_txt+'</p>';
			very_bottom_tf.htmlText = '<p class="rook_attack_text_smaller_red">'+(very_bottom_txt || '')+'</p>';
			very_bottom_tf.x = -very_bottom_tf.width/2;
			
			if (top_value_txt) {
				top_value_tf.htmlText = '<p class="rook_attack_text">'+top_value_txt+' </p>';
				top_value_sp.addChild(top_value_tf);
			} else {
				if (top_value_tf.parent) top_value_tf.parent.removeChild(top_value_tf);
			}
			
			if (bottom_value_txt) {
				bottom_value_tf.htmlText = '<p class="rook_attack_text">'+bottom_value_txt+' </p>';
				bottom_value_sp.addChild(bottom_value_tf);
			} else {
				if (bottom_value_tf.parent) bottom_value_tf.parent.removeChild(bottom_value_tf);
			}
			
			positionTopAndBottomTxt();
			
			TSTweener.removeTweens(top_value_sp);
			
			if (glow) {
				top_value_sp.filters = StaticFilters.countdown_GlowA;
				bottom_value_sp.filters = StaticFilters.countdown_GlowA;
				
				var ms:int = rm.countdown_steps_ms*.8; // 80% of the time this will be displayed seems good
				var secs:Number = ms/1000;
				var start:Number = getTimer();
				
				// tween down the strength of the filter
				TSTweener.addTween(top_value_sp, {
					time:secs,
					onUpdate:function():void {
						var f:GlowFilter = top_value_sp.filters[0];
						var elapsed_ms:int = getTimer()-start;
						f.strength = 2*((ms-elapsed_ms)/ms); // 2 is the starting strength of the filter
						top_value_sp.filters = [f];
						bottom_value_sp.filters = [f];
						
					},
					onComplete:function():void {
						top_value_sp.filters = null;
						bottom_value_sp.filters = null;
					}
				});
				
			} else {
				top_value_sp.filters = null;
				bottom_value_sp.filters = null;
			}
			
		}
		
		public function wingBeatStarting():void {
			setTopAndBottomText(
				'<span class="rook_attack_text_red">Wing</span>',
				'<span class="rook_attack_text_red">Beat!</span>'
			);
		}
		
		private function refreshText():void {
			if (rm.rooked_status.vulnerability) {
				setTopAndBottomText(
					rm.rooked_status.messaging.top_txt,
					rm.rooked_status.messaging.bottom_txt
				);
				strength_pb.visible = false;
				
				if (!vuln_pb.visible) {
					var left_ms:int = rm.rooked_status.vulnerability_ms-(new Date().getTime()-rm.rooked_status.vulnerability_start_ms);
					vuln_pb.update(left_ms/rm.rooked_status.vulnerability_ms);
					vuln_pb.updateWithAnimation(left_ms/1000, 0);
				}
				
				vuln_pb.visible = true;
				vuln_tf.htmlText = '<p class="rook_attack_strength">'+rm.rooked_status.messaging.bottom_txt_alt+'</p>';
				
			} else {
				setTopAndBottomText(
					rm.rooked_status.messaging.top_txt,
					rm.rooked_status.messaging.bottom_txt,
					rm.rooked_status.messaging.bottom_txt_alt
				);
				strength_pb.visible = true;
				vuln_pb.visible = false;
			}
		}
		
		private var trigger_countdown:Boolean = false;
		private var counting_down:Boolean = false;
		private var countdown_interv:uint = 0;
		private function countDownDamageResults():void {
			if (countdown_interv) StageBeacon.clearInterval(countdown_interv);
			counting_down = true;
			
			strength_pb.visible = true;
			vuln_pb.visible = false;
			
			var top_txt:String = rm.rooked_status.countdown.top_txt;
			var bottom_txt:String = rm.rooked_status.countdown.bottom_txt;
			var bottom_txt_alt:String = rm.rooked_status.countdown.bottom_txt_alt;
			var valuesA:Array = rm.rooked_status.countdown.values;
			valuesA.unshift(0); // add this to the beginning so when first shown it reads zero
			
			// delete it! we only want to act on it once
			rm.rooked_status.countdown = null;
			
			var steps:int = valuesA.length;
			var step:int = 0;
			
			// this will update the top and bottom text during the countdown
			var countdown:Function = function():void {
				step++;
				if (step > steps) {
					StageBeacon.clearInterval(countdown_interv);
					countdown_interv = 0;
					
					// wait for some seconds to end this
					StageBeacon.setTimeout(function():void {
						counting_down = false;
						refreshText();
						startPulsing();
					}, rm.countdown_last_delay_ms);
					
				} else {
					var last:Boolean = (steps-step == 0);
					var first:Boolean = (step == 1);
					setTopAndBottomText(
						(last) ? '<span class="rook_attack_text_smaller">Vulnerability complete!</span>' : top_txt,//+': '+(steps-step),
						bottom_txt,//+': '+valuesA[step-1],,
						bottom_txt_alt,
						(last) ? '' : String(steps-step),
						valuesA[step-1],
						(!first) // glow on all but the first
					);
					
					if (last) { // animate the attack strength change now!
						updateStrength();
					}
					
				}
			}
				
			countdown();
			StageBeacon.setTimeout(function():void {
				countdown_interv = StageBeacon.setInterval(countdown, rm.countdown_steps_ms);
			}, rm.countdown_first_delay_ms);
		}
		
		public function start():void {
			removeAllTweens();
			
			var strength_percent:Number = rm.rooked_status.strength/rm.max_strength;
			
			top_sp.y = 0;
			bottom_sp.y = 0;
			
			top_tf.scaleY = top_tf.scaleX = 1;
			bottom_tf.scaleY = bottom_tf.scaleX = text_large_scale;
			
			refreshText();
			
			alpha = 1;
			visible = true;
			has_started = false;

			TSFrontController.instance.changeTeleportDialogVisibility();
			
			pb_x = -strength_pb.width/2;
			pb_y = bottom_tf.y + bottom_tf.height+10;
			
			strength_pb.x = pb_x;
			strength_pb.y = pb_y;
			
			vuln_pb.x = pb_x;
			vuln_pb.y = pb_y;
			
			refresh();
			
			animateIn((rm.rook_incident_started_while_i_was_in_this_loc) ? TEXT_ANIMATION_TIME : 0);
			
			//animate the strength progress bar from zero to strength_percent
			strength_pb.update(0);
			strength_pb.dim_speed = .5;
			strength_pb.startTweening();
			
			vuln_pb.update(1);
			
			updateStrength((rm.rook_incident_started_while_i_was_in_this_loc) ? TEXT_ANIMATION_TIME*2 - .2 : 0); //*2 is because of the first 2 words
			
			main_view.addView(this);
		}
		
		private function removeAllTweens():void {
			TSTweener.removeTweens(this);
			TSTweener.removeTweens(top_sp);
			TSTweener.removeTweens(bottom_sp);
			TSTweener.removeTweens(top_value_sp);
			TSTweener.removeTweens(bottom_value_sp);
			TSTweener.removeTweens(top_tf);
			TSTweener.removeTweens(bottom_tf);
			TSTweener.removeTweens(strength_pb);
			TSTweener.removeTweens(vuln_pb);
		}
		
		public function update():void {
			
			if (!visible) {
				return;
			}
			
			if (counting_down || trigger_countdown) {
				return;
			}
			
			if (rm.rooked_status.countdown != null) {
				if (pulsing) {
					trigger_countdown = true; // when the top_text gets fully small, trigger_countdown will cause the countdown to play					
				} else {
					countDownDamageResults();
				}
				return;
			}
			
			if (!animating_in) {
				refreshText();
			}
			
			updateStrength();
		}
		
		private var strength_percent_set_at:Number = -1;
		private function updateStrength(delay:Number = 0):void {
			
			if (strength_percent == strength_percent_set_at && has_started) {
				// no need to do anything
				return;
			}
			
			var animation_time:Number = UPDATE_ANIMATION_TIME;
			var strength_percent:Number = rm.rooked_status.strength/rm.max_strength;
			
			if (!has_started) {
				animation_time = FULL_ANIMATION_TIME * strength_percent; //animate at a speed that makes sense the first time
				has_started = true;
				strength_pb.updateWithAnimation(animation_time, strength_percent, delay);
			} else {
				strength_pb.update(strength_percent, true);
				animation_time += strength_pb.change_delay;
			}

			strength_percent_set_at = strength_percent;
			
			TSTweener.addTween(strength_pb, {time:animation_time, delay:delay, transition:'linear', 
				onUpdate:function():void {
					//shake the progress bar as it updates
					strength_pb.x = MathUtil.randomInt(1, 3) + pb_x;
					strength_pb.y = MathUtil.randomInt(1, 3) + pb_y;
					progress_blur.blurX = strength_pb.x - 2 - pb_x;
					progress_blur.blurY = strength_pb.y - 2 - pb_y;
					strength_pb.filters = [progress_blur];
				},
				onComplete:function():void {
					strength_pb.x = pb_x;
					strength_pb.y = pb_y;
					progress_blur.blurX = progress_blur.blurY = 0;
					strength_pb.filters = [progress_blur];
					
					if (strength_percent == 0) end();
				}
			});
		}
		
		public function end():void {
			const self:RookIncidentProgressView = this;
			TSTweener.addTween(this, { alpha:0, time:.5, transition:'linear',
				onComplete:function():void {
					self.visible = false;
					TSFrontController.instance.changeTeleportDialogVisibility();
					strength_pb.stopTweening();
					vuln_pb.stopTweening();
					CONFIG::debugging {
						Console.warn('removeTweens')
					}
					removeAllTweens();
				}
			});
		}
		
		private var animating_in:Boolean;
		private function animateIn(animation_time:Number):void {
			// start the tf all big, and scale them down; when done, start pulsing
			animating_in = true;
			if (animation_time > 0) {
				top_tf.scaleX = top_tf.scaleY = 20;
				bottom_tf.scaleX = bottom_tf.scaleY = 20;
			}
			top_tf.x = -Math.round(top_sp.width/2);
			top_sp.alpha = 0;
			
			bottom_tf.x = -Math.round(bottom_sp.width/2);
			bottom_sp.alpha = 0;
			
			strength_pb.alpha = 0;
			
			strength_pb.visible = true;
			vuln_pb.visible = false;
			
			TSTweener.addTween(top_tf, {scaleX:1, scaleY:1, time:animation_time, transition:'easeOutBounce',
				onUpdate:function():void {
					top_value_tf.scaleX = top_value_tf.scaleY = top_tf.scaleX;
					correct(top_tf);
					correct(top_value_tf);
					top_tf.x = -Math.round(top_sp.width/2);
				}
			});

			TSTweener.addTween(bottom_tf, {scaleX:text_large_scale, scaleY:text_large_scale, time:animation_time, delay:animation_time - .2, transition:'easeOutBounce',
				onUpdate:function():void {
					bottom_value_tf.scaleX = bottom_value_tf.scaleY = bottom_tf.scaleX;
					correct(bottom_tf);
					correct(bottom_value_tf);
					bottom_tf.x = -Math.round(bottom_sp.width/2);
				},
				onComplete:function():void {
					animating_in = false;
					update();
					startPulsing()
				}
			});
			
			TSTweener.addTween(top_sp, {alpha:1, time:animation_time, transition:'linear'});
			TSTweener.addTween(bottom_sp, {alpha:1, time:animation_time, delay:Math.max(0, animation_time - .2), transition:'linear'});
			TSTweener.addTween(strength_pb, {alpha:1, time:Math.min(animation_time, .7), delay:Math.max(0, animation_time*2 - .2), transition:'linear'});
		}
		
		private function correct(tf:TextField):void {
			tf.width = Math.round(tf.width);
			tf.height = Math.round(tf.height);
		}
		
		private var pulsing:Boolean;
		private function startPulsing():void {
			pulsing = true;
			pulseUpTopText();
		}
		
		private function pulseUpTopText():void {
			
			if (trigger_countdown) {
				countDownDamageResults();
				trigger_countdown = false;
				pulsing = false;
				return; // this halts the pulsing, and it will only get resumed when startPulsing is called again
			}
			
			if (rm.rooked_status.vulnerability) {
				pulsing = false;
				return; // this halts the pulsing, and it will only get resumed when startPulsing is called again
			}
			
			TSTweener.addTween(top_tf, { scaleX:text_large_scale, scaleY:text_large_scale, time:THROB_ANIMATION_TIME, delay:THROB_ANIMATION_TIME/2, transition:'easeOutQuad'});
			TSTweener.addTween(bottom_tf, {
				scaleX:1, scaleY:1,
				time:THROB_ANIMATION_TIME,
				delay:THROB_ANIMATION_TIME/2,
				onUpdate:function():void {
					top_value_tf.scaleX = top_value_tf.scaleY = top_tf.scaleX;
					bottom_value_tf.scaleX = bottom_value_tf.scaleY = bottom_tf.scaleX;
					correct(top_tf);
					correct(top_value_tf);
					correct(bottom_tf);
					correct(bottom_value_tf);
					positionTopAndBottomTxt();
				},
				onComplete:pulseUpBottomText,
				transition:'easeOutQuad'}
			);
		}
		
		private function pulseUpBottomText():void {
			
			TSTweener.addTween(bottom_tf, { scaleX:text_large_scale, scaleY:text_large_scale, time:THROB_ANIMATION_TIME, delay:THROB_ANIMATION_TIME/2, transition:'easeOutQuad'});
			TSTweener.addTween(top_tf, { 
				scaleX:1, scaleY:1,
				time:THROB_ANIMATION_TIME,
				delay:THROB_ANIMATION_TIME/2,
				onUpdate:function():void {
					top_value_tf.scaleX = top_value_tf.scaleY = top_tf.scaleX;
					bottom_value_tf.scaleX = bottom_value_tf.scaleY = bottom_tf.scaleX;
					correct(top_tf);
					correct(top_value_tf);
					correct(bottom_tf);
					correct(bottom_value_tf);
					positionTopAndBottomTxt();
				},
				onComplete:pulseUpTopText,
				transition:'easeOutQuad'}
			);
		}
		
		private function positionTopAndBottomTxt():void {
			
			if (top_value_tf.parent) {
				top_tf.x = top_value_tf.x+top_value_tf.width; //in place so we can measure width
				top_value_tf.x = -Math.round(top_sp.width/2); // place by measuring width
				top_tf.x = top_value_tf.x+top_value_tf.width; // replace
			} else {
				top_tf.x = -Math.round(top_sp.width/2);
			}
			
			if (bottom_value_tf.parent) {
				bottom_tf.x = bottom_value_tf.x+bottom_value_tf.width;
				bottom_value_tf.x = -Math.round(bottom_sp.width/2);
				bottom_tf.x = bottom_value_tf.x+bottom_value_tf.width;
			} else {
				bottom_tf.x = -Math.round(bottom_sp.width/2);
			}
			
			top_sp.y = -Math.round(top_sp.height/2);
			bottom_sp.y = -Math.round(bottom_sp.height/2) + 35;
		}
		
		public function refresh():void {
			if(!visible) return;
			
			var start_point:Point = ydm.getHeaderCenterPt();
			x = Math.round(start_point.x);
			
			var max_left:int = ydm.getImaginationCenterPt().x;
			var max_right:int = model.layoutModel.header_bt_x;
			
			strength_pb.width = Math.min(MAX_WIDTH, (max_right - max_left - 20));
			vuln_pb.width = strength_pb.width;
						
			pb_x = -strength_pb.width/2;
			strength_pb.x = pb_x;
			vuln_pb.x = pb_x;
			
			very_bottom_tf.y = pb_y+strength_pb.height+5;
			very_bottom_tf.x = -very_bottom_tf.width/2;
		}
		
		private function prepTextField(tf:TextField):void {
			
			tf.embedFonts = true;
			tf.selectable = false;
			tf.border = false;
			tf.styleSheet = CSSManager.instance.styleSheet;
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.antiAliasType = AntiAliasType.ADVANCED;
		}
	}
}