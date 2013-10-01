package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.data.house.HouseExpand;
	import com.tinyspeck.engine.data.house.HouseExpandCosts;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.decorate.HouseExpandYardUI;
	
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;

	public class HouseExpandYardDialog extends BigDialog
	{
		/* singleton boilerplate */
		public static const instance:HouseExpandYardDialog = new HouseExpandYardDialog();
		
		private static const TYPE_YARD:String = 'yard';
		
		private var expand_ui:HouseExpandYardUI = new HouseExpandYardUI();
		private var expand_bt:Button;
		private var current_costs:HouseExpandCosts;
		
		private var cost_tf:TextField = new TextField();
		private var cost_i_tf:TextField = new TextField();
		private var expand_count_tf:TextField = new TextField();
		
		private var current_direction:String;
		
		private var is_built:Boolean;
		
		public function HouseExpandYardDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = 420;
			_base_padd = 20;
			_draggable = true;
			_head_min_h = 55;
			_body_min_h = 230;
			_foot_min_h = 0;
			_close_bt_padd_top = 14;
			_construct();
		}
		
		private function buildBase():void {
			//expander
			expand_ui.x = _base_padd;
			expand_ui.y = _base_padd;
			expand_ui.addEventListener(TSEvent.CHANGED, onExpandChange, false, 0, true);
			_scroller.body.addChild(expand_ui);
			
			//tfs
			TFUtil.prepTF(cost_tf, false);
			cost_tf.x = _base_padd;
			cost_tf.y = int(expand_ui.y + expand_ui.height + 15);
			_scroller.body.addChild(cost_tf);
			
			TFUtil.prepTF(cost_i_tf, false);
			cost_i_tf.y = cost_tf.y - 2;
			cost_i_tf.htmlText = '<p class="house_expand_yard_cost"><span class="house_expand_yard_i">i</span></p>';
			_scroller.body.addChild(cost_i_tf);
			
			TFUtil.prepTF(expand_count_tf);
			expand_count_tf.x = _base_padd;
			_scroller.body.addChild(expand_count_tf);
			
			//expand
			expand_bt = new Button({
				name: 'expand',
				label: 'Expand',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			expand_bt.addEventListener(TSEvent.CHANGED, onExpandClick, false, 0, true);
			_scroller.body.addChild(expand_bt);
			
			is_built = true;
		}
		
		override public function start():void {
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			
			//reset
			expand_bt.disabled = true;
			expand_bt.show_spinner = false;
			
			//listen to stats
			model.worldModel.registerCBProp(onStatsChanged, "pc", "stats");
			
			super.start();
			
			//hide this until we have our data
			visible = false;
			
			//go get the costs
			HouseManager.instance.requestExpandCostsFromServer();
		}
		
		override public function end(release:Boolean):void {
			super.end(release);
			
			//no more listen
			model.worldModel.unRegisterCBProp(onStatsChanged, "pc", "stats");
		}
		
		public function update():void {
			if(!parent) return;
			
			const home_expand:HouseExpand = HouseManager.instance.house_expand;
			current_costs = home_expand.getCostsByType(TYPE_YARD);
			
			//show the expander
			expand_ui.show(_w - _base_padd*2 - _border_w, home_expand.getCostsByType(TYPE_YARD));
			
			//show the costs
			showCosts();
			
			//show it
			visible = true;
		}
		
		private function showCosts():void {
			const pc:PC = model.worldModel.pc;
			const is_external_street:Boolean = pc.home_info.exterior_tsid == model.worldModel.location.tsid;
			const loc_type:String = is_external_street ? 'street' : 'yard';
			
			//set the title in here since we are checking for the word street/yard
			_setTitle('Expand your '+loc_type);
						
			//show the count and costs
			var cost_txt:String = '<p class="house_expand_yard_cost">';
			var expand_txt:String = '<p class="house_expand_yard_count">';
			var label_txt:String = 'Expand for '+StringUtil.formatNumberWithCommas(current_costs.img_cost)+'i';
			if(current_costs.count){
				cost_txt += 'This expansion will cost '+StringUtil.formatNumberWithCommas(current_costs.img_cost);
				expand_txt += 'This '+loc_type+' can be expanded <b>'+current_costs.count+'</b> more '+(current_costs.count != 1 ? 'times' : 'time');
			}
			else if(is_external_street && (current_costs.count_left || current_costs.count_right)){
				cost_txt += 'This expansion will cost '+StringUtil.formatNumberWithCommas(current_costs.img_cost);
				expand_txt += 'This '+loc_type+' can be expanded ';
				if(current_costs.count_left) expand_txt += '<b>'+current_costs.count_left+'</b> more '+(current_costs.count_left != 1 ? 'times' : 'time')+' to the left';
				if(current_costs.count_left && current_costs.count_right) expand_txt += '<br>and ';
				if(current_costs.count_right) expand_txt += '<b>'+current_costs.count_right+'</b> more '+(current_costs.count_right != 1 ? 'times' : 'time')+' to the right';
			}
			else {
				expand_txt += 'This '+loc_type+' can’t be expanded anymore';
				
				//since this can't be expanded, just make the label generic
				label_txt = 'Expand';
			}
			
			cost_txt += '</p>';
			expand_txt += '</p>';
			
			//set the text
			cost_tf.htmlText = cost_txt;
			expand_count_tf.htmlText = expand_txt;
			
			//update the button
			expand_bt.label = label_txt;
			expand_bt.x = int(_w - expand_bt.width - _base_padd);
			
			//move the tfs
			expand_count_tf.y = int(cost_tf.y + cost_tf.height - 4);
			expand_count_tf.width = int(expand_bt.x - expand_count_tf.x - 5);
			cost_i_tf.x = int(cost_tf.x + cost_tf.width - 3);
			
			//one more button update since the TFs moved
			expand_bt.y = int((cost_tf.y + expand_count_tf.y + expand_count_tf.height)/2 - expand_bt.height/2);
			
			_jigger();
		}
		
		override protected function _jigger():void {
			super._jigger();
			
			//body height needs to be tweaked
			_body_h = Math.max(_body_min_h, expand_count_tf.y + expand_count_tf.height + _base_padd);
			_h = _head_h + _body_h + _foot_h;
			_scroller.h = _body_h;
			_scroller.refreshAfterBodySizeChange();
			
			_draw();
		}
		
		private function onExpandClick(event:Event = null):void {
			SoundMaster.instance.playSound(!expand_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(expand_bt.disabled) return;
			
			expand_bt.disabled = true;
			expand_bt.show_spinner = true;
			
			//off to the server you go!		
			HouseManager.instance.sendYardExpand(current_direction);
		}
		
		private function onExpandChange(event:TSEvent):void {
			//any time the expand ui changes, this is fired
			onStatsChanged();
			
			//set the current direction
			current_direction = event.data as String;
		}
		
		private function onStatsChanged(pc_stats:PCStats = null):void {
			if(!current_costs) return;
			
			const pc:PC = model.worldModel.pc;
			const can_afford:Boolean = pc.stats.imagination >= current_costs.img_cost;
			
			//can we afford this?!
			if(!expand_bt.is_spinning){
				expand_bt.disabled = !can_afford || !expand_ui.selected_side;
				expand_bt.tip = !can_afford ? {txt:'You need more imagination', pointer:WindowBorder.POINTER_BOTTOM_CENTER} : null;
			}
		}
		
		override protected function rightArrowKeyHandler(e:KeyboardEvent):void {
			expand_ui.chooseSide('right');
		}
		
		override protected function leftArrowKeyHandler(e:KeyboardEvent):void {
			expand_ui.chooseSide('left');
		}
		
		override protected function enterKeyHandler(e:KeyboardEvent):void {
			onExpandClick();
		}
	}
}