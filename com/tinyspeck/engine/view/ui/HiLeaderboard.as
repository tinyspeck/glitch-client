package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.net.NetOutgoingGetHiEmoteLeaderBoardVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.text.TextField;
	
	import org.osflash.signals.Signal;

	public class HiLeaderboard extends Sprite {
		public static const shadow_filter:Array = StaticFilters.black1px90Degrees_DropShadowA;
		
		private const your_icon_wh:int = 30;
		private const your_circle_padd:int = 6;
		private const your_circle_r:int = (your_icon_wh/2)+your_circle_padd;
		private const nones_apart:int = 50;
		private const els_holder:Sprite = new Sprite();
		private const nones_holder:Sprite = new Sprite();
		private const nones_holder_mask:Shape = new Shape();
		private const title_tf:TextField = new TextField();
		private const instruct_tf:TextField = new TextField();
		private const your_variant_tf:TextField = new TextField();
		private const your_variant_holder:Sprite = new Sprite();
		private const winner_variant_tf:TextField = new TextField();
		private const winner_variant_holder:Sprite = new Sprite();
		private const desc_tf:TextField = new TextField();
		private const show_animated_nones:Boolean = false;
		private const els:Vector.<HiLeaderboardElement> = new Vector.<HiLeaderboardElement>();
		private var nones_index:int = 0;
		private var model:TSModelLocator;
		private var wm:WorldModel;
		private var last_variant:String;
		private var last_winner:String;
		private var last_top_infector_pc:PC;
		private var interv:int;
		private var toggler_cb:Checkbox;
		private var white_question_mark:Bitmap;
		
		public var refresh_sig:Signal = new Signal();
		
		public function HiLeaderboard(model:TSModelLocator){
			this.model = model;
			wm = model.worldModel;
			build();
		}
		
		public function opened():void {
			onLeaderBoardChanged(wm.hi_emote_leaderboard);
			onPCVariantChanged();
			onVariantWinnerChanged();
			
			wm.hi_emote_leaderboard_sig.add(onLeaderBoardChanged);
			wm.hi_emote_variant_sig.add(onPCVariantChanged);
			wm.hi_emote_winner_sig.add(onVariantWinnerChanged);
			
			poll();
			showHideNonesHolder(true);
		}
		
		public function closed():void {
			wm.hi_emote_leaderboard_sig.remove(onLeaderBoardChanged);
			wm.hi_emote_variant_sig.remove(onPCVariantChanged);
			wm.hi_emote_winner_sig.remove(onVariantWinnerChanged);
			StageBeacon.clearInterval(interv);
			interv = 0;
		}
		
		private function poll():void {
			TSFrontController.instance.genericSend(new NetOutgoingGetHiEmoteLeaderBoardVO());
		}
		
		private function onVariantWinnerChanged():void {
			refresh();
		}
		
		private function onPCVariantChanged():void {
			refresh();
		}
		
		private function onLeaderBoardChanged(leaderboard:Object):void {
			if (!leaderboard) return;
			
			CONFIG::debugging {
				Console.info(leaderboard);
				Console.dir(leaderboard);
			}
			
			var count:int;
			var el:HiLeaderboardElement;
			for each (el in els) {
				count = leaderboard[el.variant] || 0;
				if (el.count != count) {
					if (el.count != -1) {
						el.highlight();
					}
					el.count = count;
				}
			}
			
			
			if (interv) StageBeacon.clearInterval(interv);
			interv = StageBeacon.setInterval(poll, (model.flashVarModel.fast_update_hi_counts) ? 1000 : 60000);
			
			refresh();	
		}
		
		private function build():void {
			TFUtil.prepTF(title_tf, false);
			addChild(title_tf);
			title_tf.x = 51;
			title_tf.htmlText = '<p class="daily_pb_title">Hi sign leaderboard</p>';
			
			addChild(your_variant_holder);
			TFUtil.prepTF(your_variant_tf, false);
			your_variant_tf.x = title_tf.x;
			your_variant_tf.y = 20;
			addChild(your_variant_tf);
			
			TFUtil.prepTF(desc_tf, true);
			desc_tf.visible = false;
			desc_tf.y = 50;
			desc_tf.width = 425;
			addChild(desc_tf);
			desc_tf.htmlText = '<p class="date_time_sub_title">You can say a quick hi to people in Glitch by hitting the "<b>H</b>" key or the "<b>5</b>" key.' +
				' Every game day in Glitch, you\'ll get a new "hi" sign. You can get one randomly assigned by saying hi before anyone says hi' +
				' to you. If someone says hi to you first, you get their "hi" sign.' +
				'<br><br>' +
				'The leaderboard below shows how many people have each sign today.</p>';
			
			TFUtil.prepTF(instruct_tf, false);
			addChild(instruct_tf);
			instruct_tf.htmlText = '<p class="date_time_sub_title">Press "<b>H</b>" or "<b>5</b>" to say hi!</p>';
			instruct_tf.x = desc_tf.width-instruct_tf.width;
			instruct_tf.y = title_tf.y+1;
			
			toggler_cb = new Checkbox({
				x: 0,
				y: instruct_tf.y+instruct_tf.height,
				w:14,
				h:14,
				checked: false,
				label: '<font color="#027b94">Show more info</b>',
				name: 'info',
				label_bold: true,
				draw_caret:true,
				draw_color:0x027b94
			})
			toggler_cb.addEventListener(TSEvent.CHANGED, onCbChange, false, 0, true);
			toggler_cb.x = desc_tf.width-toggler_cb.width
			addChild(toggler_cb);
			
			addChild(winner_variant_holder);
			TFUtil.prepTF(winner_variant_tf, false);
			winner_variant_tf.height = 20;
			winner_variant_tf.width = desc_tf.width;
			addChild(winner_variant_tf);
			
			addChild(els_holder);
			var el:HiLeaderboardElement;
			var none_iiv:ItemIconView;
			for each (var variant:String in wm.hi_emote_variants) {
				el = new HiLeaderboardElement(variant, wm.hi_emote_variants_name_map[variant]);
				els.push(el);
				els_holder.addChild(el);
				none_iiv = new ItemIconView('hi_overlay', your_icon_wh, {state:'1', config:{variant:variant}}, 'default');
				none_iiv.filters = shadow_filter;
				none_iiv.x = nones_holder.numChildren*nones_apart;
				none_iiv.alpha = .5;
				nones_holder.addChild(none_iiv);
			}
			nones_holder.x = nones_holder.y = your_circle_padd;
			nones_holder.mask = nones_holder_mask;
			addChild(nones_holder);
			
			var g:Graphics = nones_holder_mask.graphics;
			g.beginFill(0, 1);
			g.drawCircle(your_circle_r, your_circle_r, your_circle_r);
			g.endFill();
			
			addChild(nones_holder_mask);
			
			var self:HiLeaderboard = this;
			AssetManager.instance.loadBitmapFromBASE64('white_question_mark', AssetManager.white_question_mark, function(key:String, bm:Bitmap):void {
				white_question_mark = bm;
				white_question_mark.filters = shadow_filter;
				self.addChild(white_question_mark);
				white_question_mark.x = 14;
				white_question_mark.y = 7;
				white_question_mark.alpha = .5;
				white_question_mark.visible = !wm.pc.hi_emote_variant;
			});/*
			
			CONFIG::god {
				el = new HiLeaderBoardElement('dongs', 'Dongs');
				els.push(el);
				els_holder.addChild(el);
			}*/
		}
		
		private function showHideNonesHolder(immediate:Boolean=false):void {
			TSTweener.removeTweens(nones_holder);
			nones_holder.visible = false;
			if (white_question_mark) white_question_mark.visible = false;
			
			if (wm.pc.hi_emote_variant) {
				return;
			}
			if (white_question_mark) white_question_mark.visible = true;
			if (show_animated_nones) nones_holder.visible = true;
			var prev_nones_index:int = nones_index;
			while (Math.abs(prev_nones_index-nones_index) < 2) nones_index = MathUtil.randomInt(0,10);
			var dest_x:int = (your_circle_padd-(nones_apart*nones_index));
			if (immediate) {
				nones_holder.x = dest_x;
				showHideNonesHolder(false);
			} else {
				if (show_animated_nones) TSTweener.addTween(nones_holder, {delay:1, time:.5, x:dest_x, onComplete:showHideNonesHolder});
			}
		}
		
		private function onCbChange(event:TSEvent):void {
			desc_tf.visible = toggler_cb.checked;
			refresh();
		}
		
		private function refresh():void {
			var el:HiLeaderboardElement;
			var else_inner_padd:int = 3;
			var els_padd:int = 11;
			var next_y:int = els_padd;
			var next_x:int = els_padd;
			var col_w:int = 145;
			
			
			var win_icon_wh:int = 22;
			var win_circle_padd:int = 4;
			var win_circle_r:int = (win_icon_wh/2)+win_circle_padd;
			
			var bg_color:uint = 0xf3f3f3;			
			
			SortTools.vectorSortOn(els, ['count', 'variant'], [Array.NUMERIC | Array.DESCENDING, Array.CASEINSENSITIVE]);
			
			for (var i:int=0;i<els.length;i++) {
				el = els[i];
				el.x = next_x;
				el.y = next_y;
				
				if (i == 3) {
					next_y = els_padd;
					next_x = els_padd+col_w;
				} else if (i == 7) {
					next_y = els_padd;
					next_x = els_padd+(col_w*2);
				} else {
					next_y+= el.height+else_inner_padd;
				}
			}
			
			els_holder.y = desc_tf.y;
			if (desc_tf.visible) {
				els_holder.y+= desc_tf.height+10;
			}
			
			var g:Graphics = els_holder.graphics;
			g.clear();
			g.beginFill(bg_color, 1);
			g.drawRoundRect(0, 0, desc_tf.width, els_holder.height+(2*els_padd), 10);
			g.endFill();
			
			your_variant_tf.width = desc_tf.width - your_variant_tf.x;
			your_variant_holder.y = 0;
			
			var variant:String = wm.pc.hi_emote_variant;
			if (!last_variant || last_variant != variant) {
				showHideNonesHolder();
				SpriteUtil.clean(your_variant_holder);
				last_variant = variant;
				
				g = your_variant_holder.graphics;
				g.clear();
				g.beginFill(bg_color, 1);
				g.drawCircle(your_circle_r, your_circle_r, your_circle_r);
				g.endFill();
				
				if (variant) {
					var your_iiv:ItemIconView = new ItemIconView('hi_overlay', your_icon_wh, {state:'1', config:{variant:variant}}, 'default');
					your_iiv.filters = shadow_filter;
					your_iiv.x = your_iiv.y = your_circle_padd;
					your_variant_holder.addChild(your_iiv);
					your_variant_tf.htmlText = '<p class="date_time_sub_title">Your daily hi sign: <b>'+wm.hi_emote_variants_name_map[variant]+'</b></p>';	
				} else {
					your_variant_tf.htmlText = '<p class="date_time_sub_title">You don\'t have a daily hi sign yet!</p>';
				}
			} else if (!variant) {
				if (!nones_holder.visible) showHideNonesHolder();
			}
			
			var top_infector_str:String = '';
			var top_infector_pc:PC = wm.getPCByTsid(wm.yesterdays_hi_emote_top_infector_tsid);
			if (top_infector_pc) {
				winner_variant_tf.x = 0;
				top_infector_str = 'Top spreader: <b>'+StringUtil.truncate(top_infector_pc.label, 30)+'</b> ' +
					'('+wm.yesterdays_hi_emote_top_infector_count+' '+wm.yesterdays_hi_emote_top_infector_variant+')';
			} else {
				top_infector_str = '<b>'+wm.hi_emote_variants_name_map[wm.yesterdays_hi_emote_variant_winner]+'</b>';
				winner_variant_tf.x = 110; 
			}
			
			winner_variant_tf.y = els_holder.y+els_holder.height+12;
			winner_variant_holder.x = winner_variant_tf.x+72;
			winner_variant_holder.y = winner_variant_tf.y-5;
			
			var winner:String = wm.yesterdays_hi_emote_variant_winner;
			if ((!last_winner || winner != last_winner) || (!last_top_infector_pc || top_infector_pc != last_top_infector_pc)) {
				SpriteUtil.clean(winner_variant_holder);
				last_winner = winner;
				last_top_infector_pc = top_infector_pc
				
				g = winner_variant_holder.graphics;
				g.clear();
				g.beginFill(bg_color, 1);
				g.drawCircle(win_circle_r, win_circle_r, win_circle_r);
				g.endFill();
				
				if (winner) {
					var winner_iiv:ItemIconView = new ItemIconView('hi_overlay', win_icon_wh, {state:'1', config:{variant:winner}}, 'default');
					winner_iiv.filters = shadow_filter;
					winner_iiv.x = winner_iiv.y = win_circle_padd;
					winner_variant_holder.addChild(winner_iiv);
					winner_variant_tf.htmlText = '<p class="date_time_sub_title">Yesterday:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'+top_infector_str+'</p>';	
					winner_variant_holder.visible = true;
				} else {
					winner_variant_tf.htmlText = '<p class="date_time_sub_title">There was no winner yesterday!</p>';
					winner_variant_holder.visible = false;
				}
			}
			
			refresh_sig.dispatch();
			
		}
	}
}