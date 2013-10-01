package com.tinyspeck.engine.view.ui.chrome
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.QuestManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.BuffViewManager;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.Timer;

	public class PlayerInfoUI extends Sprite
	{
		public static const DISPLAY_SECS:Number = 1.5; //how long when stats change does the change show for
		public static const TIMER_DELAY:Number = 25; //how fast the number timers run in miliseconds
		
		private static const CURVE_W:uint = 102;
		private static const CURVE_H:uint = 85;
		private static const MAX_NAME_CHARS:uint = 11;
		private static const SCOOP_H:uint = 15;
		private static const FOOTER_H:uint = 13;
		private static const ANIMATION_TIME:Number = .3;
		private static const ENERGY_ALPHA:Number = .3;
		private static const ENERGY_HOVER_ALPHA:Number = 1;
		
		private var energy_bar:EnergyBar = new EnergyBar();
		private var player_face:PlayerFaceUI = new PlayerFaceUI();
		private var imagination_bt:ImaginationButton = new ImaginationButton();
		private var player_stats:PlayerStatsUI = new PlayerStatsUI();
		private var buttons:PlayerInfoButtons = new PlayerInfoButtons();
		private var skill_book:PlayerSkillBookUI = new PlayerSkillBookUI();
		private var lm:LayoutModel;
		
		private var all_holder:Sprite = new Sprite();
		private var bg_holder:Sprite = new Sprite();
		private var iMG_amount_holder:Sprite = new Sprite();
		private var stats_holder:Sprite = new Sprite();
		private var buttons_mask:Sprite = new Sprite();
		private var mask_ref:Sprite = new Sprite(); //used by the mask to get height values
		private var energy_amount_holder:Sprite = new Sprite();
		private var name_holder:Sprite = new Sprite();
		
		private var energy_bolt:DisplayObject;
		private var watch_energy:DisplayObject;
		private var imagination_no_menu:DisplayObject; //used in newxp
		
		private var name_tf:TextField = new TextField();
		private var iMG_tf:TextField = new TextField();
		private var iMG_i_tf:TextField = new TextField();
		private var energy_tf:TextField = new TextField();
		
		private var current_stats:Object = {};
		private var name_glowA:Array;
		private var energy_timer:Timer = new Timer(TIMER_DELAY);
		private var imagination_timer:Timer = new Timer(TIMER_DELAY);
		
		private var displayed_energy:int;
		private var steps_energy:int;
		private var displayed_imagination:int;
		private var steps_imagination:int; //when animating, how many chunks do we step in
		
		private var energy_pt:Point;
		private var mood_pt:Point;
		private var imagination_pt:Point;
		private var imagination_bt_local_pt:Point;
		private var imagination_bt_global_pt:Point;
		
		private var is_built:Boolean;
		private var is_energy_zoomed:Boolean;
		private var is_energy_loaded:Boolean;
		private var is_img_loaded:Boolean;
		private var is_currants_loaded:Boolean;
		private var has_seen_imagination:Boolean;
		private var _is_open:Boolean;
		
		public function PlayerInfoUI(){}
		
		private function buildBase():void {
			lm = TSModelLocator.instance.layoutModel;
			
			//name
			TFUtil.prepTF(name_tf, false);
			name_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			name_holder.addChild(name_tf);
			name_holder.y = 3;
			name_holder.addEventListener(MouseEvent.CLICK, toggleMenu, false, 0, true);
			name_holder.addEventListener(MouseEvent.ROLL_OVER, onNameMouse, false, 0, true);
			name_holder.addEventListener(MouseEvent.ROLL_OUT, onNameMouse, false, 0, true);
			name_holder.mouseChildren = false;
			name_holder.buttonMode = name_holder.useHandCursor = true;
			all_holder.addChild(name_holder);
			
			name_glowA = StaticFilters.copyFilterArrayFromObject({color:0xebc696}, StaticFilters.black_GlowA);
			
			//draw the bg
			var scoop_w:int = 17;
			const start_y:int = lm.header_h + CURVE_H;
			const left_buffer:int = -20; //how much to add to the left to cover up the menu
			const overdraw:uint = 80; //how much to "overdraw" so the animation doesn't look dumb when it bounces
			const overdraw_buffer:int = -8;
			
			var g:Graphics = bg_holder.graphics;
			g.beginFill(lm.bg_color);
			g.lineTo(left_buffer, 0);
			g.lineTo(left_buffer, start_y);
			g.lineTo(overdraw_buffer, start_y + overdraw); //this extends the line for our bounce in animation
			g.lineTo(0, start_y);
			g.curveTo(0,start_y-SCOOP_H, scoop_w, start_y-SCOOP_H); //bottom scoop
			scoop_w = 13;
			g.curveTo(CURVE_W-scoop_w*2,start_y-scoop_w, CURVE_W-scoop_w,lm.header_h+SCOOP_H); //big curve
			g.curveTo(CURVE_W-scoop_w+2,lm.header_h+4, CURVE_W,lm.header_h); //top scoop
			g.lineTo(CURVE_W + overdraw, lm.header_h + overdraw_buffer);
			g.lineTo(CURVE_W, 0);
			g.endFill();
			all_holder.addChildAt(bg_holder, 0);
			
			//face
			player_face.x = -7;
			player_face.y = lm.header_h - 24;
			player_face.addEventListener(MouseEvent.CLICK, toggleMenu, false, 0, true);
			all_holder.addChild(player_face);
			
			//imagination cloud button thing
			imagination_bt.x = int(player_face.x + player_face.width - 2);
			imagination_bt.y = 4;
			imagination_bt_local_pt = new Point(imagination_bt.width - 30, imagination_bt.height);
			all_holder.addChild(imagination_bt);
			
			//imagination amount
			TFUtil.prepTF(iMG_tf, false);
			iMG_amount_holder.addChild(iMG_tf);
			
			//imagination "i" thing
			TFUtil.prepTF(iMG_i_tf, false);
			iMG_amount_holder.addChild(iMG_i_tf);
			
			iMG_amount_holder.x = int(imagination_bt.x + imagination_bt.width + 3);
			iMG_amount_holder.filters = StaticFilters.white1px90Degrees_DropShadowA;
			all_holder.addChild(iMG_amount_holder);
			
			//bolt
			energy_bolt = new AssetManager.instance.assets.energy_bolt();
			energy_bolt.x = -1;
			energy_bolt.y = start_y - energy_bolt.height - SCOOP_H - 5;
			all_holder.addChild(energy_bolt);
			
			//energy bar
			energy_bar.x = energy_bolt.x + energy_bolt.width - 1;
			energy_bar.y = lm.header_h + 2;
			energy_bar.addEventListener(MouseEvent.ROLL_OVER, onEnergyMouse, false, 0, true);
			energy_bar.addEventListener(MouseEvent.ROLL_OUT, onEnergyMouse, false, 0, true);
			all_holder.addChild(energy_bar);
			
			//energy amount
			TFUtil.prepTF(energy_tf);
			energy_tf.wordWrap = false;
			energy_tf.filters = StaticFilters.black1px90Degrees_DropShadowA;
			energy_amount_holder.addChild(energy_tf);
			energy_amount_holder.x = CURVE_W - 6;
			energy_amount_holder.y = lm.header_h + 3;
			energy_amount_holder.alpha = ENERGY_ALPHA;
			energy_amount_holder.addEventListener(MouseEvent.ROLL_OVER, onEnergyMouse, false, 0, true);
			energy_amount_holder.addEventListener(MouseEvent.ROLL_OUT, onEnergyMouse, false, 0, true);
			all_holder.addChild(energy_amount_holder);
			
			//skill book
			skill_book.x = player_face.x - 8;
			skill_book.y = int(player_face.y + player_face.height - 17);
			all_holder.addChild(skill_book);
			
			//timers
			energy_timer.addEventListener(TimerEvent.TIMER, onEnergyTimerTick, false, 0, true);
			imagination_timer.addEventListener(TimerEvent.TIMER, onImaginationTimerTick, false, 0, true);
			
			//stats
			stats_holder.x = player_face.x;
			
			player_stats.x = -10;
			player_stats.y = CURVE_H - SCOOP_H - 10;
			stats_holder.addChild(player_stats);
			
			//options/buttons
			buttons_mask.x = int(stats_holder.x + CURVE_W - buttons.width + 1);
			buttons_mask.y = int(player_stats.y + player_stats.height + 7);
			stats_holder.addChild(buttons_mask);
			
			buttons.mask = buttons_mask;
			buttons.x = buttons_mask.x;
			buttons.y = buttons_mask.y;
			stats_holder.addChild(buttons);
			
			g = mask_ref.graphics;
			g.beginFill(0);
			g.drawRect(0, 0, 1, 1);
			
			stats_holder.y = int(lm.header_h + SCOOP_H - stats_holder.height);
			all_holder.addChildAt(stats_holder, 0);
			
			addChild(all_holder);
			
			//set the mood/energy points
			mood_pt = new Point(player_face.x+35, player_face.y + 40);
			energy_pt = new Point();
			imagination_pt = new Point();
			
			is_built = true;
		}
		
		public function updatePCName():void {
			onNameMouse();
		}
		
		public function show():void {
			if(!is_built) buildBase();
			
			player_face.show();
			
			//setup the name
			onNameMouse();
			
			//update the quest count
			quest_count = QuestManager.instance.getUnacceptedQuests().length;
		}
		
		public function addAvatar():void {
			// add a new duder
			player_face.addAvatar();
		}
		
		public function updateMoodDisplay():void {
			//tell the face to update
			player_face.updateMoodDisplay();
		}
		
		public function toggleMenu(event:Event = null):void {
			if(!is_built) show();
			
			//if we can't see the iMG menu yet, don't let them click
			const loc:Location = TSModelLocator.instance.worldModel ? TSModelLocator.instance.worldModel.location : null;
			if(loc && loc.no_imagination){
				//play the fail sound hopefully as a cue that they might be able to click later
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			const mask_closed_h:uint = 15;
			const open_y:int = lm.header_h + SCOOP_H;
			const total_closed_h:uint = buttons_mask.y + mask_closed_h + FOOTER_H;
			
			_is_open = stats_holder.y < open_y;
			
			if(is_open){
				//tween it in
				mask_ref.height = mask_closed_h;
				TSTweener.addTween(mask_ref, {height:int(buttons.height), time:ANIMATION_TIME, onUpdate:onMaskUpdate});
				TSTweener.addTween(stats_holder, {y:open_y, time:ANIMATION_TIME, onUpdate:onHolderUpdate});
				onMaskUpdate();
				
				//listen to stage clicks
				StageBeacon.stage.addEventListener(MouseEvent.CLICK, onStageClick, false, 0, true);
				
				//put it on top
				if(parent) parent.setChildIndex(this, parent.numChildren-1);
			}
			else {
				//tween it out
				TSTweener.addTween(mask_ref, {height:mask_closed_h, time:ANIMATION_TIME, onUpdate:onMaskUpdate});
				TSTweener.addTween(stats_holder, {y:open_y - total_closed_h, time:ANIMATION_TIME, onUpdate:onHolderUpdate});
				onHolderUpdate();
				
				//no more listening
				StageBeacon.stage.removeEventListener(MouseEvent.CLICK, onStageClick);
			}
			
			//should we force the mood to show?
			player_face.force_show_mood = is_open;
			
			//if we are open, bring up the energy
			TSTweener.addTween(energy_amount_holder, {alpha:is_open ? ENERGY_HOVER_ALPHA : ENERGY_ALPHA, time:.1, transition:'linear'});
		}
		
		public function set energy(value:Number):void {			
			if(pc_stats) {
				//set the max
				if(isStatCurrent('energy', value) && isStatCurrent('energy_max', pc_stats.energy.max)) return;
				energy_bar.max_value = pc_stats.energy.max;
				player_stats.energy_max = pc_stats.energy.max;
			}
			energy_bar.setValue(value);
			player_stats.energy = value;
			
			//first load?
			if(is_energy_loaded && TSModelLocator.instance.prefsModel.do_stat_count_animations){
				TSTweener.removeTweens(energy_amount_holder);
				
				//take the current energy value and update it
				const change_amount:uint = Math.abs(value-displayed_energy);
				
				//go up by 1 unless the change_amount is nuts
				steps_energy = getStepAmount(change_amount);
				
				energy_timer.reset();
				energy_timer.start();
				onEnergyTimerTick();
										
			}
			else {
				displayed_energy = value;
				setEnergyText(false);
				is_energy_loaded = true;
			}
			
			// do this even if !TSModelLocator.instance.prefsModel.do_stat_count_animations
			if(is_energy_loaded) {
				//show it at full opacity for a few secs then bring it back down
				TSTweener.addTween(energy_amount_holder, {alpha:ENERGY_HOVER_ALPHA, time:.1, transition:'linear'});
			}
		}
		
		public function set mood(value:Number):void {			
			if(pc_stats) {
				//set the max
				if(isStatCurrent('mood', value) && isStatCurrent('mood_max', pc_stats.mood.max)) return;
				player_stats.mood_max = pc_stats.mood.max;
			}
			player_stats.mood = value;
			updateMoodDisplay();
		}
		
		public function set imagination(value:Number):void {
			if(isStatCurrent('imagination', value)) return;
			
			//get how much imagination they need until the next level
			if(pc_stats){
				const amount_left:Number = (pc_stats.xp.nxt - pc_stats.xp.base) - (pc_stats.xp.total - pc_stats.xp.base);
				player_stats.imagination_next = amount_left;
			}
			
			if(is_img_loaded && TSModelLocator.instance.prefsModel.do_stat_count_animations){
				TSTweener.removeTweens(iMG_amount_holder);
				
				//what changed?
				const change_amount:uint = Math.abs(value-displayed_imagination);
				
				//go up by 1 unless the change_amount is nuts
				steps_imagination = getStepAmount(change_amount);
				
				imagination_timer.reset();
				imagination_timer.start();
				onImaginationTimerTick();
			}
			else {
				displayed_imagination = value;
				setImaginationText(false);
				is_img_loaded = true;
			}
			
			//if we have more than 0, ever, then they've seen the imagination stat
			if(value > 0){
				has_seen_imagination = true;
			}
			
			//check to see if this is the first time ever they are getting imagination
			const loc:Location = TSModelLocator.instance.worldModel.location;
			if(loc && loc.no_imagination){
				showImaginationNoMenu();
			}
			else if(imagination_no_menu && imagination_no_menu.alpha == 0 && value && !TSTweener.isTweening(iMG_amount_holder)){
				iMG_amount_holder.visible = true;
				iMG_amount_holder.alpha = 0;
				TSTweener.addTween([iMG_amount_holder, imagination_no_menu], {alpha:1, time:.3, transition:'linear'});
			}
		}
		
		public function set level(value:Number):void {
			if(isStatCurrent('level', value)) return;
			player_stats.level = value;
			
			//get how much imagination they need until the next level
			if(pc_stats){
				const amount_left:Number = (pc_stats.xp.nxt - pc_stats.xp.base) - (pc_stats.xp.total - pc_stats.xp.base);
				player_stats.imagination_next = amount_left;
			}
		}
		
		public function set currants(value:Number):void {
			if(isStatCurrent('currants', value)) return;
			
			//update the stats for when they are in there
			player_stats.currants = value;
			
			//check for the first load
			if(is_currants_loaded){				
				//animate the currants
				YouDisplayManager.instance.updateCurrants();
			}
			else {
				//don't animate, just show
				YouDisplayManager.instance.updateCurrants(false);
				is_currants_loaded = true;
			}
		}
		
		public function set quest_count(value:Number):void {
			//update the imagination button
			imagination_bt.updateCount(value);
		}
		
		public function get energy_center_pt():Point {
			//where the stat bursts fire from
			energy_pt.x = energy_amount_holder.x + energy_amount_holder.width/2 + 8;
			energy_pt.y = energy_amount_holder.y + energy_amount_holder.height/2 - 8;
			return localToGlobal(energy_pt);
		}
		
		public function get energy_w():Number {
			return energy_amount_holder.x + energy_amount_holder.width + 3;
		}
		
		public function set energy_amount_visible(value:Boolean):void {
			energy_amount_holder.visible = value;
		}
		
		public function set hide_energy(value:Boolean):void {
			if (all_holder.visible == !value) {
				return;
			}
			
			//if we are showing this, let's animate it pretty
			all_holder.visible = !value;
			all_holder.x = all_holder.y = 0;
			
			//axe the watch your energy if it's still around
			if(value && watch_energy && watch_energy.parent){
				watch_energy.parent.removeChild(watch_energy);
			}
			
			if(!value){
				//set the starting spot
				all_holder.x = -CURVE_W+20;
				all_holder.y = -CURVE_H+20;
				
				//setup some animation vars
				const ani_time:Number = .5;
				const callout_ani_time:Number = .8;
				const callout_delay:Number = 4;
				
				//make sure we know our current energy
				const current_energy:uint = TSModelLocator.instance.worldModel.pc.stats.energy.value;
				energy_bar.setValue(0, false);
				energy = 0;
				steps_energy = 999999; //makes it happen in 1 step
				
				//hide the things that need to fade in
				player_face.alpha = 0;
				energy_bar.alpha = 0;
				energy_bolt.alpha = 0;
				energy_amount_holder.visible = false;
				iMG_amount_holder.alpha = !imagination_no_menu ? 0 : 1;
				imagination_bt.alpha = 0;
				all_holder.scaleX = all_holder.scaleY = 1.4;
				
				//fuck yah anon methods! Let's dance.
				TSTweener.addTween(all_holder, {x:0, y:0, scaleX:1, scaleY:1, time:ani_time, transition:'easeOutBack',
					onComplete:function():void {
						//bring in the face and bar
						TSTweener.addTween([player_face, energy_bar, energy_bolt], {alpha:1, time:ani_time, transition:'linear',
							onComplete:function():void {
								//bring in the amount and callout
								if(!watch_energy){
									watch_energy = new AssetManager.instance.assets.callout_energy();
									watch_energy.x = CURVE_W - 40;
									watch_energy.y = int(CURVE_H - watch_energy.height/2 + lm.header_h);
								}
								watch_energy.alpha = 0;
								all_holder.addChild(watch_energy);
								
								//fade it in
								TSTweener.addTween(watch_energy, {alpha:1, time:callout_ani_time, transition:'linear',
									onComplete:function():void {
										//make things look like normal again
										energy_amount_holder.visible = true;
										energy = current_energy;
										TSTweener.addTween([iMG_amount_holder, imagination_bt], {alpha:1, time:ani_time, transition:'linear'});
									}
								});
								TSTweener.addTween(watch_energy, {alpha:0, time:callout_ani_time, delay:callout_delay, transition:'linear',
									onComplete:function():void {
										//remove it
										if(watch_energy.parent) watch_energy.parent.removeChild(watch_energy);
									}
								});
							}
						});
					},
					onUpdate:function():void {
						//if we are showing the imagination_no_menu we need to animate it too
						if(imagination_no_menu){
							imagination_no_menu.x = int(all_holder.x + CURVE_W - 3);
							iMG_amount_holder.x = int(imagination_no_menu.x + imagination_no_menu.width + 3);
						}
					}
				});
			}
			else {
				//we are hiding it, that means NOTHING is there, let's setup the imagination_no_menu
				showImaginationNoMenu();
			}
		}
		
		public function get mood_center_pt():Point {
			//where the stat bursts fire from
			return localToGlobal(mood_pt);
		}
		
		public function set hide_mood(value:Boolean):void {
			if (name_holder.visible == !value) {
				return;
			}
			
			//do we need to hide the face?
			player_face.hide_face = value;
			name_holder.visible = !value;
		}
		
		public function get player_face_pt():Point {
			return player_face.localToGlobal(new Point(player_face.w/2, player_face.height));
		}
		
		public function get imagination_center_pt():Point {
			//where the stat bursts fire from
			imagination_pt.x = iMG_amount_holder.x + iMG_amount_holder.width;
			imagination_pt.y = iMG_amount_holder.y + iMG_amount_holder.height/2;
			return localToGlobal(imagination_pt);
		}
		
		public function set hide_imagination(value:Boolean):void {
			if (imagination_bt.visible == !value) {
				return;
			}
			
			//hide the things
			const current_imagination:uint = TSModelLocator.instance.worldModel.pc.stats.imagination;
			iMG_amount_holder.visible = !value || imagination_no_menu != null;
			imagination_bt.visible = !value;
			
			//fade it in
			if(!value){
				iMG_amount_holder.alpha = 0;
				imagination_bt.alpha = 0;
				
				iMG_amount_holder.x = int(imagination_bt.x + imagination_bt.width + 3);
				all_holder.addChild(iMG_amount_holder);
				
				TSTweener.addTween([iMG_amount_holder, imagination_bt], {alpha:1, time:.5, transition:'linear'});
				
				//axe the no_menu if it's around
				if(imagination_no_menu){
					if(imagination_no_menu.parent) imagination_no_menu.parent.removeChild(imagination_no_menu);
					imagination_no_menu = null;
				}
			}
			else {
				showImaginationNoMenu();
			}
		}
		
		public function set hide_imagination_amount(is_hide:Boolean):void {
			const current_imagination:uint = TSModelLocator.instance.worldModel.pc.stats.imagination;
			const loc:Location = TSModelLocator.instance.worldModel.location;
			const end_alpha:Number = !is_hide && ((current_imagination > 0 && loc.no_imagination) || has_seen_imagination) ? 1 : 0
			TSTweener.removeTweens(iMG_amount_holder);
			TSTweener.addTween(iMG_amount_holder, {_autoAlpha:end_alpha, time:.1, transition:'linear'});
		}
		
		private function showImaginationNoMenu():void {
			if(!imagination_no_menu){
				imagination_no_menu = new AssetManager.instance.assets.imagination_no_menu();
				addChild(imagination_no_menu);
			}
			
			imagination_no_menu.x = all_holder.visible ? int(all_holder.x + CURVE_W - 3) : 0;
			imagination_no_menu.y = int(TSModelLocator.instance.layoutModel.header_h/2 - imagination_no_menu.height/2);
			
			iMG_amount_holder.x = int(imagination_no_menu.x + imagination_no_menu.width + 3);
			addChild(iMG_amount_holder);
			
			//see if we can even show this yet
			const current_imagination:uint = TSModelLocator.instance.worldModel.pc.stats.imagination;
			iMG_amount_holder.visible = (current_imagination > 0 && TSModelLocator.instance.worldModel.location.no_imagination) || has_seen_imagination;
			iMG_amount_holder.alpha = iMG_amount_holder.visible ? 1 : 0;
			imagination_no_menu.alpha = iMG_amount_holder.alpha;
		}
		
		public function getImaginationButtonBasePt():Point {
			return imagination_bt.localToGlobal(imagination_bt_local_pt);
		}
		
		public function get is_open():Boolean { return _is_open; }
		
		private function onMaskUpdate():void {
			//draw the mask as it opens
			const corner_rad:Number = 7;
			const draw_h:int = mask_ref.height;
			const draw_x:int = buttons.x - 5;
			
			var g:Graphics = buttons_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRoundRectComplex(0, 0, int(buttons.width), draw_h, corner_rad, 0, corner_rad, 0);

			g = stats_holder.graphics;
			g.clear();
			g.beginFill(lm.bg_color);
			g.drawRoundRectComplex(draw_x, 0, int(CURVE_W + stats_holder.x + 1 - draw_x), int(buttons_mask.y + buttons_mask.height + FOOTER_H), 0, 0, 0, corner_rad);
		}
		
		private function onHolderUpdate():void {
			//swap the bg and stats when the stats holder is low enough
			const bg_index:int = all_holder.getChildIndex(bg_holder);
			const stats_index:int = all_holder.getChildIndex(stats_holder);
			
			//-2 is a slight visual tweak
			if(stats_holder.y >= lm.header_h - 2 && stats_index < bg_index){
				all_holder.setChildIndex(stats_holder, bg_index);
			}
			else if(stats_holder.y < lm.header_h && bg_index < stats_index){
				all_holder.setChildIndex(bg_holder, stats_index);
			}
		}
		
		private function onStageClick(event:MouseEvent):void {
			//if the menu is open, close it
			if(stats_holder.y == lm.header_h + SCOOP_H){
				toggleMenu();
			}
		}
		
		private function onEnergyMouse(event:MouseEvent):void {
			if(_is_open || is_energy_zoomed) return;
			
			//bring up the alpha so it can be read
			const is_over:Boolean = event.type == MouseEvent.ROLL_OVER;
			TSTweener.addTween(energy_amount_holder, {alpha:is_over ? ENERGY_HOVER_ALPHA : ENERGY_ALPHA, time:.1, transition:'linear'});
		}
		
		private function onNameMouse(event:MouseEvent = null):void {
			//draw a border maybe
			const is_over:Boolean = event && event.type == MouseEvent.ROLL_OVER;
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			if(!pc) return;
			
			//make sure we can render the name in VAG
			name_tf.htmlText = '<p class="player_info_name">'+pc.label+'</p>';
			var name_txt:String = StringUtil.truncate(name_tf.text, MAX_NAME_CHARS);
			const vag_ok:Boolean = StringUtil.VagCanRender(name_txt);
			
			//now that we checked to see if we can render it, let's encode the html unsafe stuff
			name_txt = StringUtil.encodeHTMLUnsafeChars(name_txt);
			
			if(is_over) name_txt = '<span class="player_info_name_hover">'+name_txt+'</span>';
			if(!vag_ok){
				//use arial instead :(
				name_txt = '<font face="Arial">'+name_txt+'</font>';
			}
			name_tf.embedFonts = vag_ok;
			name_tf.htmlText = '<p class="player_info_name">'+name_txt+'</p>';
			
			//draw the hit area
			const buffer_w:uint = 4;
			var g:Graphics = name_holder.graphics;
			g.clear();
			g.beginFill(lm.bg_color);
			g.drawRoundRect(-buffer_w, 0, int(name_tf.width + buffer_w*2 + 1), int(name_tf.height), 6);
				
			name_holder.x = int(player_face.x + (player_face.width/2 - name_holder.width/2));
			name_holder.filters = is_over ? name_glowA : null;
		}
		
		private function onEnergyTimerTick(event:TimerEvent = null):void {
			//as long as the displayed energy isn't what's current, we keep this party going!
			const current_energy:int = current_stats['energy'];
			if(displayed_energy != current_energy){
				if(displayed_energy < current_energy){
					displayed_energy += steps_energy;
					if(displayed_energy > current_energy) displayed_energy = current_energy;
				}
				else {
					displayed_energy -= steps_energy;
					if(displayed_energy < current_energy) displayed_energy = current_energy;
				}
			}
			else {
				energy_timer.stop();
				TSTweener.addTween(energy_amount_holder, {alpha:ENERGY_ALPHA, time:.1, delay:DISPLAY_SECS-.5, transition:'linear', onComplete:setEnergyText, onCompleteParams:[false]});
			}
						
			setEnergyText(true);
		}
		
		private function setEnergyText(is_zoom:Boolean):void {
			var energy_txt:String = '<span class="player_info_energy_change">'+displayed_energy+'</span>';
			if(!is_zoom) {
				//make sure the displayed energy is what it's supposed to be
				displayed_energy = current_stats['energy'];
				energy_txt = displayed_energy.toString();
			}
			
			//update the text
			energy_tf.htmlText = '<p class="player_info_energy">' +
				'<span class="player_info_energy_current">'+energy_txt+'</span>/'+energy_bar.max_value+
				'<br>Energy</p>';
			
			//draw the hit area
			const g:Graphics = energy_amount_holder.graphics;
			g.clear();
			g.beginFill(0,0);
			g.drawRect(0, 0, energy_tf.width, energy_tf.height);
			
			//update the buffs
			BuffViewManager.instance.refresh();
			
			is_energy_zoomed = is_zoom;
		}
		
		private function onImaginationTimerTick(event:TimerEvent = null):void {
			//same as energy
			const current_imagination:int = current_stats['imagination'];
			if(displayed_imagination != current_imagination){
				if(displayed_imagination < current_imagination){
					displayed_imagination += steps_imagination;
					if(displayed_imagination > current_imagination) displayed_imagination = current_imagination;
				}
				else {
					displayed_imagination -= steps_imagination;
					if(displayed_imagination < current_imagination) displayed_imagination = current_imagination;
				}
				
				setImaginationText(true);
			}
			else {
				imagination_timer.stop();
				
				//little delay before restoring it
				StageBeacon.setTimeout(setImaginationText, (DISPLAY_SECS-.5)*1000, false);
			}
		}
		
		private function setImaginationText(is_zoom:Boolean):void {			
			var img_txt:String = '<span class="player_info_iMG_zoom">'+StringUtil.formatNumberWithCommas(displayed_imagination)+'</span>';
			var img_i_txt:String = '<span class="player_info_i_zoom">i</span>';
			if(!is_zoom){
				//if we are not zooming, make sure we have the current amount
				displayed_imagination = current_stats['imagination'];
				img_txt = StringUtil.formatNumberWithCommas(displayed_imagination);
				img_i_txt = 'i';
			}
			
			//update the text
			iMG_tf.htmlText = '<p class="player_info_iMG">'+img_txt+'</p>';
			iMG_i_tf.htmlText = '<p class="player_info_iMG"><span class="player_info_i">'+img_i_txt+'</span></p>';
			iMG_i_tf.x = iMG_tf.width - 2;
			iMG_amount_holder.y = int(lm.header_h/2 - iMG_amount_holder.height/2 + 3);
		}
		
		private function getStepAmount(change_amount:Number):int {
			//this will make sure that when animating the changes, it always completes in a good time
			return Math.max(Math.ceil((change_amount*TIMER_DELAY)/(DISPLAY_SECS*1000)), 1);
		}
		
		private function isStatCurrent(stat:String, value:Number):Boolean {
			//check our current stats object to see if the values match
			if(stat in current_stats && current_stats[stat] == value){
				return true;
			}
			
			//let's make it current
			current_stats[stat] = value;
			
			return false;
		}
		
		private function get pc_stats():PCStats {
			//short cut to get the stats
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			if(pc && pc.stats) return pc.stats;
			return null;
		}
	}
}