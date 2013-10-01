package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.pc.PCSkill;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.DailyProgress;
	import com.tinyspeck.engine.view.ui.Dialog;
	import com.tinyspeck.engine.view.ui.HiLeaderboard;
	import com.tinyspeck.engine.vo.GameTimeVO;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.TextField;

	public class DateTimeDialog extends Dialog
	{
		/* singleton boilerplate */
		public static const instance:DateTimeDialog = new DateTimeDialog();
		
		private var title_tf:TextField = new TextField();
		private var sub_title_tf:TextField = new TextField();
		private var today_tf:TextField = new TextField();
		
		private var quoin_progress:DailyProgress;
		private var meditation_progress:DailyProgress;
		private var calendar_bt:Button;
		
		private var all_holder:Sprite = new Sprite();
		private var quoin_holder:Sprite = new Sprite();
		private var meditation_holder:Sprite = new Sprite();
		private var hi_holder:Sprite = new Sprite();
		private var hi_leaderboard:HiLeaderboard;
		private var today_holder:Sprite = new Sprite();
		
		private var is_built:Boolean;
		
		public function DateTimeDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_draggable = true;
			_base_padd = 20;
			_construct();
		}
		
		private function buildBase():void {
			var g:Graphics;
			
			//title
			TFUtil.prepTF(title_tf, false);
			title_tf.x = _base_padd;
			title_tf.y = _base_padd + 8;
			title_tf.htmlText = '<p class="date_time_title">&nbsp;</p>';
			title_tf.mouseEnabled = false;
			all_holder.addChild(title_tf);
			
			//sub-title
			TFUtil.prepTF(sub_title_tf, false);
			sub_title_tf.x = _base_padd;
			sub_title_tf.y = title_tf.y + title_tf.height - 4;
			sub_title_tf.htmlText = '<p class="date_time_sub_title">&nbsp;</p>';
			sub_title_tf.mouseEnabled = false;
			all_holder.addChild(sub_title_tf);
			
			//quoins
			const quoin_icon:DisplayObject = new AssetManager.instance.assets.daily_coin_icon();
			quoin_progress = new DailyProgress(354, 24, quoin_icon);
			quoin_progress.x = 14;
			quoin_progress.y = 14;
			quoin_holder.addChild(quoin_progress);
			quoin_holder.x = _base_padd;
			quoin_holder.mouseEnabled = quoin_holder.mouseChildren = false;
			g = quoin_holder.graphics;
			g.beginFill(0xc3cace);
			g.drawRect(0, 0, _w - _base_padd*2, 1);
			all_holder.addChild(quoin_holder);
			
			//meditation
			const meditation_icon:DisplayObject = new ItemIconView('focusing_orb', 40);
			meditation_progress = new DailyProgress(354, 24, meditation_icon);
			meditation_progress.x = 21;
			meditation_progress.y = 14;
			meditation_holder.addChild(meditation_progress);
			meditation_holder.x = _base_padd;
			meditation_holder.mouseEnabled = meditation_holder.mouseChildren = false;
			g = meditation_holder.graphics;
			g.beginFill(0xc3cace);
			g.drawRect(0, 0, _w - _base_padd*2, 1);

			hi_leaderboard = new HiLeaderboard(model);
			hi_leaderboard.refresh_sig.add(reflow);
			hi_leaderboard.x = 21;
			hi_leaderboard.y = 14;
			
			hi_holder.x = _base_padd;
			hi_holder.addChild(hi_leaderboard);
			g = hi_holder.graphics;
			g.beginFill(0xc3cace);
			g.drawRect(0, 0, _w - _base_padd*2, 1);
			
			if (model.flashVarModel.hi_viral) {
				all_holder.addChild(hi_holder);
			} else {
				all_holder.addChild(meditation_holder);
			}
			
			//today
			TFUtil.prepTF(today_tf, false);
			today_tf.x = 18;
			today_tf.y = 14;
			today_tf.mouseEnabled = false;
			today_holder.addChild(today_tf);
			today_holder.x = _base_padd;
			today_holder.mouseEnabled = today_holder.mouseChildren = false;
			g = today_holder.graphics;
			g.beginFill(0xc3cace);
			g.drawRect(0, 0, _w - _base_padd*2, 1);
			all_holder.addChild(today_holder);
			
			//calendar			
			calendar_bt = new Button({
				name: 'calendar',
				label: 'Calendar',
				c: 0xffffff,
				graphic: new AssetManager.instance.assets.daily_calendar_icon(),
				graphic_placement: 'top',
				graphic_padd_l: 25,
				graphic_padd_t: 6,
				border_width: 1,
				border_c: 0xc3d8de,
				focus_border_c: 0xefc692,
				label_size: 11,
				label_bold: true,
				label_c: 0x005c73,
				label_hover_c: 0xd79035,
				label_offset: -2,
				corner_radius: 4,
				w: 80,
				h: 60,
				x: _w - 80 - 50,
				y: _base_padd,
				tip: {
					txt: 'Opens in a new window',
					pointer: WindowBorder.POINTER_BOTTOM_CENTER,
					offset_y: -7
				}
			});
			all_holder.addChild(calendar_bt);
			calendar_bt.addEventListener(TSEvent.CHANGED, TSFrontController.instance.openCalendarPage, false, 0, true);
			
			//let the hand icon show through things that don't need to worry about the mouse
			all_holder.mouseEnabled = false;
			addChild(all_holder);
			
			is_built = true;
		}
		
		override public function start():void {
			if(!canStart(false)) return;
			
			//we have a pc?		
			if(!model.worldModel.pc){
				CONFIG::debugging {
					Console.warn('PC data not loaded yet!');
				}
				return;
			}
			
			if(!is_built) buildBase();
			
			//listen for changes
			model.timeModel.registerCBProp(onTimeTick, "gameTime");
			model.worldModel.registerCBProp(onStatsChanged, "pc", "stats");
			model.worldModel.registerCBProp(onSkillsChanged, "pc", "skill_training_complete");
			
			hi_leaderboard.opened();
			
			//set the date up right away
			onTimeTick(model.timeModel.gameTime);
			
			//populate the stats right away
			onStatsChanged(model.worldModel.pc.stats);
			
			super.start();
			
			//place it near the clock
			var pt:Point = YouDisplayManager.instance.getTimeBasePt();
			x = int(pt.x + model.layoutModel.gutter_w - _w/2);
			if(x + _w > StageBeacon.stage.stageWidth){
				//if this sucker goes past where we can see then we need to bring'r back
				x = int(StageBeacon.stage.stageWidth - _w - _base_padd);
			}
			y = int(pt.y + model.layoutModel.header_h -15);
			
			//make sure esc does stuff
			startListeningToNavKeys();
		}
		
		override public function refresh():void {
			//we dont' want this snapping to the center, so just make sure 
			//it doesn't go out of reach
			checkBounds();
		}
		
		override public function end(release:Boolean):void {
			//kill listeners
			model.timeModel.unRegisterCBProp(onTimeTick, "gameTime");
			model.worldModel.unRegisterCBProp(onStatsChanged, "pc", "stats");
			model.worldModel.unRegisterCBProp(onSkillsChanged, "pc", "skill_training_complete");
			
			hi_leaderboard.closed();
			
			stopListeningToNavKeys();
			
			super.end(release);
		}
		
		private function onTimeTick(gameTime:GameTimeVO):void {
			title_tf.htmlText = '<p class="date_time_title">'+gameTime.time+gameTime.ampm.toLowerCase()+' '+gameTime.string_day_month+'</p>';
			sub_title_tf.htmlText = '<p class="date_time_sub_title">'+gameTime.real_time_until_new_day+' of real-world time until the New Game Day</p>';
		}
		
		private function onSkillsChanged(pc_skill:PCSkill):void {
			//stats may have changed, just fire the stats method
			if(model.worldModel.pc) onStatsChanged(model.worldModel.pc.stats);
		}
		
		private function onStatsChanged(pc_stats:PCStats):void {
			//quoins
			quoin_holder.visible = Boolean(pc_stats.quoins_today);
			if(pc_stats.quoins_today){
				var coin_current:int = pc_stats.quoins_today.value;
				var coin_max:int = pc_stats.quoins_today.max;
				quoin_progress.title = 'Daily quoin limit: '+coin_max;
				quoin_progress.max_value = coin_max;
				quoin_progress.update(coin_current, (coin_current != 1 ? 'quoins' : 'quoin') + ' grabbed today');
			}
			
			//meditation
			meditation_holder.visible = (pc_stats.meditation_today && pc_stats.meditation_today.max > 0);
			if(pc_stats.meditation_today){
				var meditation_current:int = pc_stats.meditation_today.value;
				var meditation_max:int = pc_stats.meditation_today.max;
				meditation_progress.title = 'Daily max energy via meditation: '+meditation_max;
				meditation_progress.max_value = meditation_max;
				meditation_progress.update(meditation_current, 'energy gained today with meditation');
			}
			
			//today stats (energy burned / xp gained
			var energy_spent:String = StringUtil.formatNumberWithCommas(Math.abs(pc_stats.energy_spent_today));
			var img_gained:String = StringUtil.formatNumberWithCommas(pc_stats.imagination_gained_today);
			today_tf.htmlText = '<p class="date_time_today">Today:   '+
								'<span class="date_time_energy"><b>'+energy_spent+' energy</b> spent   </span>'+
								'<span class="date_time_img"><b>'+img_gained+' imagination</b> gained</span></p>';
			
			reflow();
		}
		
		private function reflow():void {
			//if things go away or show up, we need to move things around
			var y_gap:int = 13;
			var next_y:int = sub_title_tf.y + sub_title_tf.height + y_gap*2;
			
			if(quoin_holder.visible){
				quoin_holder.y = next_y;
				next_y += quoin_holder.height + y_gap;
			}
			
			if(meditation_holder.visible && meditation_holder.parent){
				meditation_holder.y = next_y;
				next_y += meditation_holder.height + y_gap + 2; //icon/border offset
			}
			
			if(hi_holder.visible && hi_holder.parent){
				hi_holder.y = next_y;
				next_y += hi_holder.height + y_gap + 2; //icon/border offset
			}
			
			today_holder.y = next_y;
			next_y += today_holder.height + y_gap;
			
			_h = next_y + 4; //4 gives it a little bit of love on the bottom
			
			_jigger();
			_draw();
		}
	}
}