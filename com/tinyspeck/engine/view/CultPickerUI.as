package com.tinyspeck.engine.view
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.data.house.CultivationsChoice;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CultManager;
	import com.tinyspeck.engine.port.HouseManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.ConfiggerUI;
	import com.tinyspeck.engine.view.ui.TSScrollPager;
	import com.tinyspeck.engine.view.ui.furniture.CultButton;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.TextField;
	
	public class CultPickerUI extends TSSpriteWithModel implements ITipProvider {
		private static const ICON_PADD:uint = 15;
		private static const PAGER_H:uint = 104;
		private static const PAGER_PADD:uint = 8;
		
		private var chooser_holder:Sprite = new Sprite();
		private var info_holder:Sprite = new Sprite();
		private var imagination_holder:Sprite = new Sprite();
		private var scroll_pager:TSScrollPager;
		private var buttons:Vector.<CultButton> = new Vector.<CultButton>();
		
		private var choose_tf:TextField = new TextField();
		private var you_have_tf:TextField = new TextField();
		private var imagination_tf:TextField = new TextField();
		
		private var width_of_config_ui:int;
		
		public function CultPickerUI() {}
		
		public function init():void {
			width_of_config_ui = CultManager.WIDTH_OF_CONFIG_UI;
			
			//style chooser
			scroll_pager = new TSScrollPager(PAGER_H);
			scroll_pager.x = width_of_config_ui + PAGER_PADD;
			scroll_pager.y = PAGER_PADD;
			scroll_pager.setContent(chooser_holder);
			addChild(scroll_pager);
			
			//info/message thing
			//draw
			var g:Graphics = info_holder.graphics;
			g.beginFill(0xdfe6ec);
			g.drawRoundRect(0, PAGER_PADD + 1, width_of_config_ui, PAGER_H - 2, ConfiggerUI.CORNER_RAD*2);
			info_holder.filters = StaticFilters.copyFilterArrayFromObject({color:0xa2bcb9}, StaticFilters.black_GlowA);
			addChild(info_holder);
			
			//choose item
			TFUtil.prepTF(choose_tf);
			choose_tf.width = width_of_config_ui;
			choose_tf.htmlText = '<p class="chassis_picker">Choose an item to see<br>where you can add it<br>on your street.</p>';
			choose_tf.y = PAGER_PADD + 10;
			info_holder.addChild(choose_tf);
			
			//iMG stuff
			TFUtil.prepTF(you_have_tf, false);
			you_have_tf.htmlText = '<p class="furn_upgrade_credits">You have</p>';
			imagination_holder.addChild(you_have_tf);
			
			const img_icon:DisplayObject = new AssetManager.instance.assets.img_icon();
			img_icon.x = int(you_have_tf.width + 4);
			img_icon.filters = StaticFilters.white3px_GlowA;
			imagination_holder.addChild(img_icon);
			
			TFUtil.prepTF(imagination_tf, false);
			imagination_tf.x = int(img_icon.x + img_icon.width + 2);
			imagination_holder.addChild(imagination_tf);
			imagination_holder.y = int(choose_tf.y + choose_tf.height + 12);
			info_holder.addChild(imagination_holder);
		}
		
		public function start():Boolean {
			TSTweener.removeTweens(this);
			alpha = 0;
			TSTweener.addTween(this, {_autoAlpha:1, time:.5, transition:'linear'});
			
			//reset the content
			scroll_pager.refresh(true);
			
			//hide the contents until they are loaded
			//chooser_holder.visible = false;
			
			setOptions();
			
			model.worldModel.registerCBProp(onStatsChanged, "pc", "stats");
			onStatsChanged();
			
			return true;
		}
		
		private var tip:Object = {
			min_w: 114,
			min_h: 43,
			placement: {},
			pointer: WindowBorder.POINTER_BOTTOM_CENTER
		}
		
		public function getTip(tip_target:DisplayObject=null):Object {
			var pt:Point;
			var htmlText:String;
			var color:Number;
			
			if (!(tip_target is CultButton)) {
				return null;
			}
			
			var cub:CultButton = tip_target as CultButton;
			var choice:CultivationsChoice = cub.cultivation_choice;
			
			if (!choice) {
				return null;
			}
			
			htmlText = '';
			
			if (CultManager.instance.waiting_on_item) {
				htmlText+= 'Relax! We\'re working on something...';
			} else if (!choice.can_place) {
				htmlText+= 'You are currently unable to place this item.';
			} else if (!choice.client::need_level && !choice.client::need_imagination && choice.client::will_fit) {
				htmlText+= 'Click to place this item in location!';
				color = 0xe7f0db
			} else {
				if (choice.client::need_level) {
					htmlText+= 'You need to be level '+choice.min_level+'';
				} else if (choice.client::need_imagination) {
					htmlText+= (htmlText ? '<br>' : '') + 'You need '+(choice.client::need_imagination)+' more imagination';
				}
				
				if (!choice.client::will_fit){
					htmlText+= (htmlText ? '<br>Plus, y' : 'Y') + 'ou need more yard space';
				}
			}
			
			htmlText = '<p align="center">'+htmlText+'</p>';
			
			pt = tip_target.localToGlobal(new Point(0,0));
			pt.x+= cub.width/2;
			pt.y-= 4;
			
			tip.txt = htmlText;
			tip.color = color;
			tip.placement.x = pt.x;
			tip.placement.y = pt.y;
			
			return tip;
		}
		
		private function setOptions():void {		
			const choices:Vector.<CultivationsChoice> = HouseManager.instance.cultivations.choices;
			var i:int;
			var total:int = choices.length;
			var cub:CultButton;
			var next_x:int;
			var g:Graphics;
			
			resetButtonPool();
			
			//sort by level, then cost
			SortTools.vectorSortOn(choices, ['min_level', 'imagination_cost'], [Array.NUMERIC, Array.NUMERIC]);
			
			for (i = 0; i < total; i++) {				
				if(buttons.length > i){
					cub = buttons[int(i)];
					cub.is_clicked = false;
				}
				else {
					cub = new CultButton(PAGER_H, ICON_PADD);
					cub.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
					buttons.push(cub);
				}
				
				cub.x = next_x;
				next_x += cub.width;
				
				// just a wee delay to make loading smoother, especially when the furn is large
				StageBeacon.setTimeout(cub.show, 100*(i+1), choices[int(i)].class_id, choices[int(i)], cub.is_clicked, i < total-1);
				
				chooser_holder.addChild(cub);
			}
			
			//show the stuff
			chooser_holder.visible = true;
			
			//set the element width of the pager
			if(!scroll_pager.element_width && cub){
				scroll_pager.element_width = cub.width;
			}
			
			//refresh the scroller
			scroll_pager.refresh();
		}
		
		private function onButtonClick(event:TSEvent):void {
			const cub:CultButton = event.data as CultButton;
			const option:CultivationsChoice = cub.cultivation_choice;
			if (!cub.disabled && option && !CultManager.instance.waiting_on_item) {
				setChoice(option);
			}
		}
		
		public function setChoice(option:CultivationsChoice):void {
			//reset the other buttons
			var i:int;
			var total:int = buttons.length;
			var button:CultButton;
			
			for(i; i < total; i++){
				button = buttons[int(i)];
				if (!button.cultivation_choice) continue;
				button.is_clicked = (button.cultivation_choice == option);
			}
			
			// DO SOMETHING
			if (option) {
				CultManager.instance.startCultivate(option);
			}
		}
		
		public function refresh():void {
			//called from ChassisManager
			const lm:LayoutModel = model.layoutModel;
			scroll_pager.width = (lm.pack_is_wide ? lm.overall_w : lm.loc_vp_w) - scroll_pager.x;
		}
		
		public function updateButtons():void {
			var i:int;
			var total:int = buttons.length;
			var button:CultButton;
			var choice:CultivationsChoice;
			
			for(i; i < total; i++){
				button = buttons[int(i)];
				choice = button.cultivation_choice;
				button.setText();
				button.disabled = (choice && (!choice.can_place || !choice.client::will_fit || (choice.imagination_cost && choice.client::need_imagination)));
			}
		}
		
		private function resetButtonPool():void {
			//reset the pool
			var i:int;
			var total:int = buttons.length;
			
			for(i; i < total; i++){
				buttons[int(i)].hide();
			}
		}
		
		private function clean():void {
			resetButtonPool();
		}
		
		public function end():void {
			clean();
			
			TSTweener.removeTweens(this);
			TSTweener.addTween(this, {_autoAlpha:0, time:.5, transition:'linear'});
			model.worldModel.unRegisterCBProp(onStatsChanged, "pc", "stats");
		}
		
		private function onStatsChanged(pc_stats:PCStats = null):void {
			const pc:PC = model.worldModel.pc;
			if(pc){
				imagination_tf.htmlText = '<p class="furn_upgrade_credits">'+StringUtil.formatNumberWithCommas(pc.stats.imagination)+'</p>';
				imagination_holder.x = int(width_of_config_ui/2 - imagination_holder.width/2);
				updateButtons();
			}
		}
	}
}