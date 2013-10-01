package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.house.HouseExpandCosts;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.PCHomeInfo;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.DisplayObject;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;

	public class HouseSignDialog extends BigDialog
	{
		/* singleton boilerplate */
		public static const instance:HouseSignDialog = new HouseSignDialog();
		
		private var expand_bt:Button;
		private var cultivate_bt:Button;
		private var change_style_bt:Button;
		private var change_house_bt:Button;
		private var change_tower_bt:Button;
		private var house_keys_bt:Button;
		
		private var buttonsV:Vector.<Button> = new Vector.<Button>();
		private var current_choice_i:int;
		
		private var is_built:Boolean;
		
		public function HouseSignDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = 200;
			_draggable = true;
			_body_min_h = 250;
			_head_min_h = 50;
			_foot_min_h = 0;
			_base_padd = 20;
			_close_bt_padd_top = 11;
			_close_bt_padd_right = 11;
			
			_construct();
		}
		
		private function buildBase():void {
			//build out the buttons
			expand_bt = buildButton('Expand', onExpandClick);
			_scroller.body.addChild(expand_bt);
			
			change_style_bt = buildButton('Change Style', onChangeStyleClick);
			_scroller.body.addChild(change_style_bt);
			
			cultivate_bt = buildButton('Cultivate Land', onCutivateClick);
			_scroller.body.addChild(cultivate_bt);
			
			change_house_bt = buildButton('Change House', onChangeHouseClick);
			_scroller.body.addChild(change_house_bt);
			
			house_keys_bt = buildButton('House Keys', onHouseKeysClick);
			_scroller.body.addChild(house_keys_bt);
			
			change_tower_bt = buildButton('Change Tower', onChangeTowerClick);
			_scroller.body.addChild(change_tower_bt);
			
			//set the titles
			_setTitle('Your street');
			
			_scroller.body.addEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
			_scroller.body.addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
			
			is_built = true;
		}
		
		override public function start():void {
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			
			//figure out which buttons to show
			showButtons();
			
			super.start();
		}
		
		private function showButtons():void {
			//interior and exterior streets need different options
			const bt_padd:uint = 7;
			const location:Location = model.worldModel.location;
			const home_info:PCHomeInfo = model.worldModel.pc.home_info;
			const is_exterior:Boolean = home_info.exterior_tsid == location.tsid;
			const costs:HouseExpandCosts = HouseManager.instance.house_expand.getCostsByType(HouseExpandCosts.TYPE_YARD);
			var can_expand:Boolean;
			var next_y:int = _base_padd - 2;
			
			//figure out if we can expand where we are
			if(is_exterior && (costs.count_left || costs.count_right)){
				can_expand = true;
			}
			else if(!is_exterior && costs.count){
				can_expand = true;
			}
			
			buttonsV.length = 0;

			//move the buttons
			expand_bt.y = next_y;
			expand_bt.disabled = !can_expand;
			expand_bt.tip = can_expand ? null : {txt:'Your street is already sooo big!', pointer:WindowBorder.POINTER_BOTTOM_CENTER};
			next_y += expand_bt.height + bt_padd;
			buttonsV.push(expand_bt);
			
			change_style_bt.y = next_y;
			next_y += change_style_bt.height + bt_padd;
			buttonsV.push(change_style_bt);
			
			cultivate_bt.y = next_y;
			next_y += cultivate_bt.height + bt_padd;
			buttonsV.push(cultivate_bt);
			
			change_house_bt.visible = is_exterior;
			change_house_bt.y = change_house_bt.visible ? next_y : 0;
			if (change_house_bt.visible) {
				next_y += change_house_bt.height + bt_padd;
				buttonsV.push(change_house_bt);
			}
			
			house_keys_bt.y = house_keys_bt.visible ? next_y : 0;
			if (house_keys_bt.visible) {
				next_y += house_keys_bt.height + bt_padd;
				buttonsV.push(house_keys_bt);
			}
			
			change_tower_bt.visible = false; //model.worldModel.getLocationItemstacksAByItemClass('furniture_tower_chassis').length > 0;
			change_tower_bt.y = change_tower_bt.visible ? next_y : 0;
			if (change_tower_bt.visible) buttonsV.push(change_tower_bt);
			
			_body_min_h = _scroller.body_h + _base_padd;
			
			focusDefaultChoice();
		}
		
		private function buildButton(label:String, click_function:Function):Button {
			const bt_w:uint = _w - _base_padd*2;
			var graphic:DisplayObject;
			var graphic_hover:DisplayObject;
			var graphic_disabled:DisplayObject;
			var image_name:String;
			
			//figure out which graphics to load
			switch(click_function){
				case onExpandClick:
					image_name = 'expand';
					break;
				case onChangeStyleClick:
					image_name = 'style';
					break;
				case onCutivateClick:
					image_name = 'cultivate';
					break;
				case onChangeHouseClick:
					image_name = 'house_exterior';
					break;
				case onChangeTowerClick:
					image_name = 'tower';
					break;
				case onHouseKeysClick:
					image_name = 'house_keys';
					break;
			}
			
			if(image_name){
				graphic = new AssetManager.instance.assets['street_'+image_name];
				graphic_hover = new AssetManager.instance.assets['street_'+image_name+'_hover'];
				graphic_disabled = new AssetManager.instance.assets['street_'+image_name+'_disabled'];
			}
			
			const bt:Button = new Button({
				name: label,
				label :label,
				graphic: graphic,
				graphic_hover: graphic_hover,
				graphic_disabled: graphic_disabled,
				graphic_placement: 'left',
				graphic_padd_l: 12,
				graphic_padd_r: 5,
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR,
				w: bt_w
			});
			bt.x = _base_padd - _border_w;
			
			if(click_function != null){
				bt.addEventListener(TSEvent.CHANGED, click_function, false, 0, true);
			}
			
			return bt;
		}
		
		private function onExpandClick(event:TSEvent):void {
			//open up the expand yard dialog
			if(expand_bt.disabled) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			end(true);
			HouseExpandYardDialog.instance.start();
		}
		
		private function onCutivateClick(event:TSEvent):void {
			if(cultivate_bt.disabled) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			end(true);
			HouseManager.instance.startCultivation();
		}
		
		private function onChangeHouseClick(event:TSEvent):void {
			if(change_house_bt.disabled) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			//open chassis changer
			HouseManager.instance.openChassisChanger('furniture_chassis');
		}
		
		private function onHouseKeysClick(event:TSEvent):void {
			if(house_keys_bt.disabled) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			//open acl dialog
			end(true);
			ACLDialog.instance.start();
		}
		
		private function onChangeTowerClick(event:TSEvent):void {
			if(change_tower_bt.disabled) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			//open chassis changer
			HouseManager.instance.openChassisChanger('furniture_tower_chassis');
		}
		
		private function onChangeStyleClick(event:TSEvent):void {
			if(change_style_bt.disabled) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			//open the styles dialog
			end(true);
			HouseStylesDialog.instance.start();
		}
		
		override protected function downArrowKeyHandler(e:KeyboardEvent):void {
			focusNextChoice();
		}
		
		override protected function upArrowKeyHandler(e:KeyboardEvent):void {
			focusPrevChoice();
		}
		
		override protected function rightArrowKeyHandler(e:KeyboardEvent):void {
			focusNextChoice();
		}
		
		override protected function leftArrowKeyHandler(e:KeyboardEvent):void {
			focusPrevChoice();
		}
		
		override protected function enterKeyHandler(e:KeyboardEvent):void {
			if (!buttonsV.length) return;
			makeChoice();
		}
		
		private function mouseOverHandler(e:MouseEvent):void {
			if (e.target is Button) {
				focusChoice(getIndexOfButton(e.target as Button));
			}
		}
		
		private function mouseOutHandler(e:MouseEvent):void {
			if (e.target is Button) {
				focusChoice(current_choice_i);
			}
		}
		
		private function makeChoice(by_click:Boolean = false):void {
			if (current_choice_i < 0 || current_choice_i > buttonsV.length-1) return;
			onButtonChosen(buttonsV[current_choice_i]);
		}
		
		private function onButtonChosen(bt:Button):void {
			if(bt && !bt.disabled){
				SoundMaster.instance.playSound('CLICK_SUCCESS');
				bt.dispatchEvent(new TSEvent(TSEvent.CHANGED, bt));
			} else {
				SoundMaster.instance.playSound('CLICK_FAILURE');
			}
		}
		
		private function getIndexOfButton(bt:Button):int {
			return buttonsV.indexOf(bt);
		}
		
		private function focusDefaultChoice():void {
			focusChoice(0);
		}
		
		private function getButtonAtIndex(i:int):Button {
			if (i<0 || i>buttonsV.length-1) {
				CONFIG::debugging {
					Console.error('i out of range:'+i+' '+(buttonsV.length-1));
				}
				return null;
			}
			return buttonsV[int(i)];
		}
		
		private function focusChoice(i:int):void {
			//if the current choice is larger than the length, make it the first one
			if(current_choice_i > buttonsV.length-1) current_choice_i = 0;
			
			if (current_choice_i != i) {
				if (current_choice_i != -1) getButtonAtIndex(current_choice_i).blur();
				current_choice_i = i;
			}
			
			if (getButtonAtIndex(i)) {
				getButtonAtIndex(i).focus();
			}
		}
		
		private function focusNextChoice():void {
			if (!buttonsV.length) return;
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			if (current_choice_i+1 >= buttonsV.length) {
				focusChoice(0);
			} else {
				focusChoice(current_choice_i+1);
			}
		}
		
		private function focusPrevChoice():void {
			if (!buttonsV.length) return;
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			if (current_choice_i-1 < 0) {
				focusChoice(buttonsV.length-1);
			} else {
				focusChoice(current_choice_i-1);
			}
		}
		
	}
}