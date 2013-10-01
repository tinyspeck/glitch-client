package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.Achievement;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.data.reward.Rewards;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.AvatarView;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.AchievementIcon;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.EnergyGauge;
	import com.tinyspeck.engine.view.ui.SkillIcon;
	import com.tinyspeck.engine.view.ui.Slug;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.utils.Timer;
	
	// http://svn.tinyspeck.com/wiki/SpecNewDay
	
	public class NewDayView extends BaseScreenView implements ITipProvider {
		
		/* singleton boilerplate */
		public static const instance:NewDayView = new NewDayView();
		
		private const REFILL_PADD:int = 75;
		private const GAUGE_SCALE_BASE:Number = 2.5;
		private var gauge_scale_adjusted:Number;
		private const ANIMATION_SPEED:int = 25;
		private const STEP_AMOUNT:int = 55;
		private const MESSAGES:Array = new Array('The day sure is glorious!', 
												 'Alright, refreshed!', 
												 '<b>*deep sniff*</b> now that smells like progress!', 
												 'Alright world, time to take you on!',
												 'Another day, another dollar... er, currant?',
												 'Each day will be better than the last. This one especially.',
												 'I\'d like mornings better if they started later.',
												 'What a morning!? What cannot be accomplished on such a splendid day?',
												 'It\'s the dawn of a new age. A great era. An epoch!',
												 'A clear dawn sharpens my senses. Today will be a great day.');
		
		private var energy_gauge:EnergyGauge = new EnergyGauge();
		
		private var element_holder:Sprite = new Sprite();
		private var sun_grad:Sprite = new Sprite();
		private var mountains_holder:Sprite = new Sprite();
		
		private var date_tf:TextField = new TextField();
		private var title_tf:TextField = new TextField();
		private var refill_tf:TextField = new TextField();
		private var yesterday_tf:TextField = new TextField();
		
		private var bg_matrix:Matrix = new Matrix();
		
		private var ok_bt:Button;
		private var increment_timer:Timer = new Timer(1000);
		
		private var stats_today:Vector.<Reward>;
		private var shuffled_msgs:Array;
		
		private var max_energy:Number;
		private var current_energy:Number;
		private var granted_energy:Number;
		private var tick_amount:Number;
		private var current_msg_index:int;
		
		public function NewDayView() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		override protected function buildBase():void {			
			super.buildBase();
			
			//textfields
			TFUtil.prepTF(date_tf, false);
			TFUtil.prepTF(title_tf, false);
			TFUtil.prepTF(refill_tf, false);
			TFUtil.prepTF(yesterday_tf, false);
			
			title_tf.htmlText = '<p class="new_day_title">A NEW DAY</p>';
			refill_tf.htmlText = '<p class="new_day_refill">Complete energy refill</p>';
			
			date_tf.filters = StaticFilters.white_drop_DropShadowA;
			title_tf.filters = StaticFilters.black2px90Degrees_DropShadowA;
			refill_tf.filters = StaticFilters.white_drop_DropShadowA;
			yesterday_tf.filters = StaticFilters.white_drop_DropShadowA;
						
			all_holder.addChild(date_tf);
			all_holder.addChild(title_tf);
			all_holder.addChild(refill_tf);
			all_holder.addChild(yesterday_tf);
			all_holder.addChild(element_holder);
			
			//button			
			ok_bt = new Button({
				label: 'Onwards and upwards!',
				name: 'ok_bt',
				value: 'done',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_DEFAULT
			})
			all_holder.addChild(ok_bt);
			
			ok_bt.addEventListener(MouseEvent.CLICK, onOkClick, false, 0, true);
			ok_bt.filters = StaticFilters.white4px40AlphaGlowA;
			
			//energy gauge
			const energy_drop:DropShadowFilter = new DropShadowFilter();
			energy_drop.distance = 0;
			energy_drop.color = 0;
			energy_drop.alpha = .7;
			energy_drop.blurX = energy_drop.blurY = 9;
			energy_drop.strength = 1;
			energy_drop.angle = 0;
			
			energy_gauge.filters = [energy_drop];
			all_holder.addChild(energy_gauge);
			
			//handle the rays
			loadRays();
			
			//build the sunshine
			const sun_rad:int = 500;
			const matrix:Matrix = new Matrix();
			matrix.createGradientBox(
				sun_rad*2, 
				sun_rad*2, 
				0, 
				-sun_rad, 
				-sun_rad
			);
			const g:Graphics = sun_grad.graphics;
			g.beginGradientFill(GradientType.RADIAL, [0xfffcc7, 0xe9d252, 0xe9d252], [1, .4, 0], [40, 100, 255], matrix);
			g.drawCircle(0, 0, sun_rad);
			
			addChildAt(sun_grad, 0);
			
			//put on the mountain
			const mountains:DisplayObject = new AssetManager.instance.assets.new_day_mountains();
			mountains_holder.addChild(mountains);
			addChildAt(mountains_holder, getChildIndex(all_holder));
			
			//shuffle the messages
			shuffled_msgs = SortTools.shuffleArray(MESSAGES);
		}
		
		override protected function draw():void {
			const colors:Array = [0xaab3c6, 0xa896b1];
			const alphas:Array = [.95, .95];
			const draw_h:int = model.layoutModel.loc_vp_h;
			bg_matrix.createGradientBox(
				draw_w, 
				draw_h, 
				Math.PI/2, //vertical grad
				0, 
				0
			);
						
			var g:Graphics = graphics;
			g.clear();
			g.beginGradientFill(GradientType.LINEAR, colors, alphas, [0, 255], bg_matrix);
			g.drawRoundRect(model.layoutModel.gutter_w, model.layoutModel.header_h,
				draw_w, draw_h, 
				model.layoutModel.loc_vp_elipse_radius*2);
			
			//mask
			g = all_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRoundRect(model.layoutModel.gutter_w, model.layoutModel.header_h, 
				draw_w, draw_h, 
				model.layoutModel.loc_vp_elipse_radius*2);
			
			if(!ready_for_input){
				//if we are animating, kill the tweens
				TSTweener.removeTweens(sun_grad);
				TSTweener.removeTweens(rays);
				rays.alpha = 1;
			}
			
			//move the sun
			sun_grad.x = int(model.layoutModel.gutter_w + draw_w/2);
			sun_grad.y = model.layoutModel.header_h + draw_h;
			
			//move the rays
			rays.x = sun_grad.x - 410;
			rays.y = sun_grad.y - 293;
			
			//move mountains *flex*
			mountains_holder.x = model.layoutModel.gutter_w + int(draw_w/2 - mountains_holder.width/2);
			mountains_holder.y = model.layoutModel.header_h + draw_h - int(mountains_holder.height);
			
			//center the stuff
			all_holder.x = model.layoutModel.gutter_w + int(draw_w/2);
			all_holder.y = model.layoutModel.header_h + int(draw_h/2 - all_holder.height/2);
		}
		
		override protected function onDoneTweenComplete():void {
			super.onDoneTweenComplete();
			
			if(increment_timer.running){
				increment_timer.stop();
				increment_timer.removeEventListener(TimerEvent.TIMER, onTimerTick);
			}
			
			//put a bubble above the avatar giving out some stats for the day
			showChatBubble();
			
			//stop tooltippin'
			var i:int;
			for(i = 0; i < element_holder.numChildren; i++){
				TipDisplayManager.instance.unRegisterTipTrigger(element_holder.getChildAt(i));
			}
			
			SpriteUtil.clean(element_holder);
		}
		
		private function showChatBubble():void {
			const bubble_max_w:uint = 240;
			var i:int;
			var extra_sp:Sprite = new Sprite();
			var slug:Slug;
			var next_x:int = 0;
			var next_y:int = 0;
			var padd:int = 4;
			var msg:String = shuffled_msgs[current_msg_index];
			var avatar:AvatarView = TSFrontController.instance.getMainView().gameRenderer.getAvatarView();
			
			for(i; i < stats_today.length; i++){
				if (stats_today[int(i)].type != Reward.ITEMS && stats_today[int(i)].amount > 0) {
					slug = new Slug(stats_today[int(i)]);
					slug.x = next_x;
					slug.y = next_y;
					next_x = slug.x+slug.width+padd;
					extra_sp.addChild(slug);
					
					if (next_x+slug.width > bubble_max_w) {
						next_x = 0;
						next_y = extra_sp.height+padd;
					}
				}
			}
			
			avatar.chatBubbleManager.showBubble(msg, extra_sp);
			
			current_msg_index = (current_msg_index < shuffled_msgs.length-1 ? current_msg_index+1 : 0);
		}
		
		// SHOULD ONLY EVER BE CALLED FROM TSFrontController.instance.tryShowScreenViewFromQ();
		public function show(payload:Object):Boolean {
			if(!super.makeSureBaseIsLoaded()) return false;
						
			stats_today = Rewards.fromAnonymous(payload.stats_today);
			var energy:Reward = Rewards.getRewardByType(stats_today, Reward.ENERGY);
			const stats_yesterday:Vector.<Reward> = Rewards.fromAnonymous(payload.stats_yesterday);
			const imagination:Reward = Rewards.getRewardByType(stats_yesterday, Reward.IMAGINATION);
			
			max_energy = model.worldModel.pc.stats.energy.max;
			granted_energy = energy ? energy.amount : 0;
			current_energy = max_energy - granted_energy;
			
			// be sure the time is up-to-date to the second so that we don't see
			// the wrong day (e.g. from 11:59:59 instead of 12:00:00);
			TSFrontController.instance.forceUpdateGameTimeVO();
			date_tf.htmlText = '<p class="new_day_date">'+model.timeModel.gameTime.string_day_month+'</p>';
			
			const max_w:int = draw_w - model.layoutModel.gutter_w - 40;
			title_tf.scaleX = title_tf.scaleY = 1;
			if(title_tf.width > max_w){
				var tf_scale:Number = max_w / title_tf.width;
				title_tf.scaleX = title_tf.scaleY = tf_scale;
			}
			//position stuff
			date_tf.x = int(-date_tf.width/2);
			title_tf.x = int(-title_tf.width/2);
			title_tf.y = date_tf.height - 15; //if the text size changes this fucks up as per Flash TF woes
			refill_tf.x = title_tf.x + REFILL_PADD;
			refill_tf.y = int(title_tf.y + title_tf.height - 15);
			
			gauge_scale_adjusted = title_tf.scaleX*GAUGE_SCALE_BASE;
			energy_gauge.scaleX = energy_gauge.scaleY = gauge_scale_adjusted;
			
			//gauge
			energy_gauge.x = int(refill_tf.x + refill_tf.width + energy_gauge.width/2 + 15);
			energy_gauge.y = refill_tf.y + 10;
			energy_gauge.value = current_energy;
			
			//yesterday stats
			energy = Rewards.getRewardByType(stats_yesterday, Reward.ENERGY);
			
			var yesterday_txt:String = '<p class="new_day_yesterday">Yesterday, you gained ';
				yesterday_txt += imagination ? '<span class="new_day_gained">'+StringUtil.formatNumberWithCommas(imagination.amount)+' imagination</span>': '';
				yesterday_txt += ' and spent <span class="new_day_spent">'+(energy ? StringUtil.formatNumberWithCommas(Math.abs(energy.amount)) : 0)+' energy</span>';
				yesterday_txt += (payload.new_level ? ' &#8212; and reached <span class="new_day_gained">Level '+payload.new_level+'</span>' : '')+'</p>';
			yesterday_tf.htmlText = yesterday_txt;
			yesterday_tf.x = int(-yesterday_tf.width/2);
			yesterday_tf.y = int(energy_gauge.y + energy_gauge.height/2 + 25);
			
			//build the list of stuff that you did
			buildElements(payload);
			element_holder.x = int(-element_holder.width/2);
			element_holder.y = int(yesterday_tf.y + yesterday_tf.height + 15);
			
			ok_bt.x = int(-ok_bt.width/2);
			ok_bt.y = element_holder.y + element_holder.height + 20;
			
			//setup to animate
			draw();
			animate();
						
			return tryAndTakeFocus(payload);
		}
		
		private function buildElements(payload:Object):void {
			var max_graphics:uint = 2;
			var graphic_wh:uint = 40;
			var padd:int = 5;
			var i:int;
			var names:Array;
			var tsids:Array;
			var graphics_array:Array;
			var next_x:int;
			var graphic_holder:Sprite;
			var element:Sprite;
			var achievement:Achievement;
			
			SpriteUtil.clean(element_holder);
			
			//skills
			if(payload.new_skills){
				names = new Array();
				graphics_array = new Array();
				i = 0;
				while(payload.new_skills[int(i)]){
					names.push(payload.new_skills[int(i)].name);
					if(i < max_graphics) graphics_array.push(new SkillIcon(payload.new_skills[int(i)].tsid));
					i++;
				}
				
				//build skills
				if(i > 0) {
					element = new Sprite();
					element = buildElementHolder(i+'&nbsp;new<br>'+(i > 1 ? 'skills' : 'skill'), graphics_array, names);
					element.x = next_x;
					next_x += element.width + padd;
					
					element_holder.addChild(element);
				}
			}
			
			//collections
			if(payload.complete_collections){			
				names = new Array();
				graphics_array = new Array();
				i = 0;
				while(payload.complete_collections[int(i)]){
					names.push(payload.complete_collections[int(i)].name);
					if(i < max_graphics) graphics_array.push(new ItemIconView(payload.complete_collections[int(i)].tsid, graphic_wh));
					i++;
				}
				
				//build collections
				if(i > 0) {
					element = new Sprite();
					element = buildElementHolder(i+'&nbsp;'+(i != 1 ? 'collections' : 'collection')+'<br>complete', graphics_array, names);
					element.x = next_x;
					next_x += element.width + padd;
					
					element_holder.addChild(element);
				}
			}
			
			//badges
			if(payload.new_badges){
				names = new Array();
				graphics_array = new Array();
				i = 0;
				while(payload.new_badges[int(i)]){
					//add them into the world
					achievement = model.worldModel.getAchievementByTsid(payload.new_badges[int(i)].tsid);
					if(!achievement){
						achievement = Achievement.fromAnonymous(payload.new_badges[int(i)], payload.new_badges[int(i)].tsid);
						model.worldModel.achievements[payload.new_badges[int(i)].tsid] = achievement;
					}
					
					names.push(achievement.name);
					if(i < max_graphics) graphics_array.push(new AchievementIcon(achievement.tsid, graphic_wh, AchievementIcon.TYPE_PNG));
					i++;
				}
				
				//build badges
				if(i > 0) {
					element = new Sprite();
					element = buildElementHolder(i+'&nbsp;new<br>'+(i != 1 ? 'badges' : 'badge'), graphics_array, names);
					element.x = next_x;
					next_x += element.width + padd;
					
					element_holder.addChild(element);
				}
			}
			
			//quests
			if(payload.complete_quests){
				names = new Array();
				i = 0;
				while(payload.complete_quests[int(i)]){
					names.push(payload.complete_quests[int(i)].name);
					i++;
				}
				
				//build quests
				if(i > 0) {
					//add quest icon and count
					graphic_holder = new Sprite();
					graphic_holder.addChild(new AssetManager.instance.assets.familiar_dialog_quests());
					
					var quest_count:Sprite = new Sprite();
					var g:Graphics = quest_count.graphics;
					g.beginFill(0x9a3c3b);
					g.drawCircle(0, 0, 8);
					quest_count.x = graphic_holder.width - 8;
					quest_count.y = 12;
					
					var tf:TextField = new TextField();
					TFUtil.prepTF(tf, false);
					tf.htmlText = '<p class="new_day_quest_count">'+i+'</p>';
					tf.x = int(-tf.width/2) - 1;
					tf.y = int(-tf.height/2);
					quest_count.addChild(tf);
					
					graphic_holder.addChild(quest_count);
					
					element = new Sprite();
					element = buildElementHolder(i+'&nbsp;'+(i != 1 ? 'quests' : 'quest')+'<br>finished', [graphic_holder], names);
					element.x = next_x;
					
					element_holder.addChild(element);
				}
			}
		}
		
		private function buildElementHolder(txt:String, graphics_array:Array, names_array:Array):Sprite {
			var padd:int = 10;
			var graphic_padd:int = 8;
			var h:uint = 60;
			var ds:DropShadowFilter = new DropShadowFilter();
			var sp:Sprite = new Sprite();
			var g:Graphics = sp.graphics;
			var tf:TextField = new TextField();
			var i:int;
			var next_x:int = padd;
			var graphic:DisplayObject;
			
			//drop shadow
			ds.angle = 270;
			ds.distance = 1;
			ds.blurX = ds.blurY = 1;
			ds.alpha = .5;
			
			//text
			TFUtil.prepTF(tf, false);
			tf.multiline = true;
			tf.htmlText = '<p class="new_day_element">'+txt+'</p>';
			tf.filters = [ds];
			tf.x = next_x;
			tf.y = int(h/2 - tf.height/2);
			next_x += int(tf.width + padd);
			
			sp.addChild(tf);
			
			//place the images
			if(graphics_array){
				for(i; i < graphics_array.length; i++){
					graphic = graphics_array[int(i)];
					graphic.x = next_x;
					graphic.y = int(h/2 - graphic.height/2);
					next_x += graphic.width + (i < graphics_array.length - 1 ? graphic_padd : padd);
					
					sp.addChild(graphic);
				}
			}
			
			//draw the box
			g.clear();
			g.beginFill(0, .15);
			g.drawRoundRect(0, 0, next_x, h, 8);
			
			//name the sprite the same as the names array for tooltippin'
			sp.name = names_array.join(', ');
			
			//let tooltips happen
			TipDisplayManager.instance.registerTipTrigger(sp);
			
			return sp;
		}
		
		override protected function animate():void {
			var i:int;
			var tf:TextField;
			var sp:Sprite;
			var texts:Vector.<TextField> = new Vector.<TextField>();
			var final_y:int = 388;
			var offset:int = 40;
			
			//fade in
			super.animate();
			
			//sun
			final_y = sun_grad.y;
			sun_grad.y += 350;
			TSTweener.addTween(sun_grad, {y:final_y, time:1.5, transition:'linear'});
			
			//rays
			addChildAt(rays, 0);
			rays.alpha = 0;
			TSTweener.removeTweens(rays);
			TSTweener.addTween(rays, {alpha:1, time:.8, delay:1.5, transition:'linear'});
			
			//textfields
			texts.push(date_tf, title_tf, refill_tf, yesterday_tf);
			for(i = 0; i < texts.length; i++){
				tf = texts[int(i)];
				final_y = tf.y;
				tf.alpha = 0;
				tf.y += offset;
				
				TSTweener.addTween(tf, {alpha:1, y:final_y, time:.4, delay:.7 + (i*.2), transition:'easeOutBounce'});
			}
			
			for(i = 0; i < element_holder.numChildren; i++){
				sp = element_holder.getChildAt(i) as Sprite;
				sp.alpha = 0;
				
				TSTweener.addTween(sp, {alpha:1, time:.5, delay:1.7 + (i*.2), transition:'linear'});
			}
			
			energy_gauge.scaleX = energy_gauge.scaleY = 0;
			TSTweener.addTween(energy_gauge, {scaleX:gauge_scale_adjusted, scaleY:gauge_scale_adjusted, time:.4, delay:1, transition:'easeOutBounce'});
			
			//how fast should it increment
			tick_amount = Math.max(1, int(granted_energy/STEP_AMOUNT));
						
			//energy number increments
			increment_timer.delay = 2000;
			increment_timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
			increment_timer.start();
			
			//ok button
			final_y = ok_bt.y;
			ok_bt.alpha = 0;
			ok_bt.y += offset;
			TSTweener.addTween(ok_bt, {y:final_y, alpha:1, time:.4, delay:1.3, transition:'easeOutBounce'});
		}
		
		private function onTimerTick(event:TimerEvent):void {		
			if(current_energy < max_energy){
				increment_timer.delay = ANIMATION_SPEED;
				current_energy += tick_amount;
				if(current_energy > max_energy) current_energy = max_energy;
				energy_gauge.value = current_energy;
			}
			else {
				increment_timer.stop();
				if(increment_timer.hasEventListener(TimerEvent.TIMER)){
					increment_timer.removeEventListener(TimerEvent.TIMER, onTimerTick);
				}
			}
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			return {
				txt: tip_target.name,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
			
			return null;
		}
	}
}