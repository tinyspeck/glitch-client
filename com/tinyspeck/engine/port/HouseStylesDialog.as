package com.tinyspeck.engine.port
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.house.HouseStyles;
	import com.tinyspeck.engine.data.house.HouseStylesChoice;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.LightBox;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.decorate.HouseStylesChoiceUI;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class HouseStylesDialog extends BigDialog
	{
		/* singleton boilerplate */
		public static const instance:HouseStylesDialog = new HouseStylesDialog();
		
		private var padder:Sprite = new Sprite();
		private var lightbox_extra_sp:Sprite = new Sprite();
		
		private var change_bt:Button;
		private var cancel_bt:Button;
		private var lightbox_buttons:Vector.<Button> = new Vector.<Button>();
		private var choice_elements:Vector.<HouseStylesChoiceUI> = new Vector.<HouseStylesChoiceUI>();
		private var current_element:HouseStylesChoiceUI;
		private var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
		
		private var subscriber_tf:TextField = new TextField();
		private var lightbox_subscriber_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var is_built:Boolean;
		
		public function HouseStylesDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = 366;
			_draggable = true;
			_base_padd = 20;
			_body_min_h = 140;
			_body_max_h = 320;
			_head_min_h = 55;
			_foot_min_h = 5;
			//_body_fill_c = 0xffffff;
			//_body_border_c = 0xffffff;
			_close_bt_padd_top = 13;
			_close_bt_padd_right = 9;
			_construct();
		}
		
		private function buildBase():void {
			//build the buttons for the light box stuff
			change_bt = new Button({
				name: 'change',
				label: 'Change',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			change_bt.addEventListener(TSEvent.CHANGED, onChangeClick, false, 0, true);
			
			cancel_bt = new Button({
				name: 'cancel',
				label: 'Cancel',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			cancel_bt.addEventListener(TSEvent.CHANGED, onCancelClick, false, 0, true);
			
			lightbox_buttons.push(change_bt, cancel_bt);
			
			var sub_txt:String = '<p class="house_styles_sub">';
			sub_txt += '<span class="house_styles_sub_title">';
			sub_txt += 'That item is only available to subscribers<br>';
			sub_txt += '</span>';
			sub_txt += 'Dang — you don’t have a subscription! There are so many good things that can be had with a subscription, like this thing.';
			sub_txt += '<br><br>Good news! During beta, there are crazy good deals on subscriptions. ';
			sub_txt += 'Support Glitch and <a class="house_styles_sub_link" href="event:'+TSLinkedTextField.LINK_SUBSCRIBE+'">subscribe now!</a>';
			sub_txt += '</p>';
			
			TFUtil.prepTF(lightbox_subscriber_tf, true, {textDecoration:'none', color:'#e5e5e5'});
			lightbox_subscriber_tf.cacheAsBitmap = true;
			lightbox_subscriber_tf.width = 550;
			lightbox_subscriber_tf.htmlText = sub_txt;
			lightbox_extra_sp.addChild(lightbox_subscriber_tf);
			
			//tfs			
			TFUtil.prepTF(subscriber_tf, false);
			subscriber_tf.htmlText = '<p class="house_styles">The following styles are only available to subscribers:</p>';
			subscriber_tf.x = int(_w/2 - subscriber_tf.width/2 - _base_padd/2);
			subscriber_tf.mouseEnabled = false;
			subscriber_tf.cacheAsBitmap = true; //prevents the text from dancing on scroll
			_scroller.body.addChild(subscriber_tf);
			
			//padder for below the images
			var g:Graphics = padder.graphics;
			g.beginFill(0,0);
			g.drawRect(0, 0, 1, _base_padd/2);
			_scroller.body.addChild(padder);
			
			//set up the confirm
			cdVO.callback = onConfirm;
			cdVO.choices = [
				{value: false, label: 'Nevermind'},
				{value: true, label: 'Yes. Change it!'}
			];
			
			is_built = true;
		}
		
		override public function start():void {
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			
			//reset
			subscriber_tf.visible = false;
			change_bt.disabled = true;
			change_bt.label = 'Change';
			change_bt.show_spinner = false;
			current_element = null;
			
			//reset the pool
			resetPool();
			
			//go ask the server for the upgrade data
			HouseManager.instance.requestStyleChoicesFromServer();
			_scroller.scrollUpToTop();
			
			//listen to stat changes
			model.worldModel.registerCBProp(updateChangeButton, "pc", "stats");
			
			//set proper titles
			const pc:PC = model.worldModel.pc;
			const is_external_street:Boolean = pc.home_info.exterior_tsid == model.worldModel.location.tsid;
			_setTitle('Change your '+(is_external_street ? 'street' : 'yard')+' style');
			cdVO.title = 'Change your '+(is_external_street ? 'street' : 'yard')+' style?';
			
			super.start();
		}
		
		override public function end(release:Boolean):void {
			super.end(release);
			model.worldModel.unRegisterCBProp(updateChangeButton, "pc", "stats");
			resetPool();
		}
		
		public function update():void {
			const house_styles:HouseStyles = HouseManager.instance.house_styles;
			if(house_styles){				
				//build out our choices
				const padd:int = 10;
				var i:int;
				var total:int = house_styles.choices.length;
				var element:HouseStylesChoiceUI;
				var choice:HouseStylesChoice;
				var next_x:int = _base_padd;
				var next_y:int = _base_padd;
				
				resetPool();
				
				//sort the choices depending on our current sub status
				const pc:PC = model.worldModel.pc;
				const is_sub:Boolean = pc.stats ? pc.stats.is_subscriber : false;
				
				SortTools.vectorSortOn(
					house_styles.choices, 
					['is_current', 'is_subscriber', 'tsid'], 
					[Array.DESCENDING, (is_sub ? Array.DESCENDING : Array.CASEINSENSITIVE), Array.CASEINSENSITIVE]
				);
				
				subscriber_tf.visible = false;
				subscriber_tf.y = 0;
				
				//build em out
				for(i = 0; i < total; i++){
					choice = house_styles.choices[int(i)];
					
					if(i > choice_elements.length){
						element = choice_elements[int(i)];
					}
					else {
						element = new HouseStylesChoiceUI();
						element.addEventListener(MouseEvent.CLICK, onElementClick, false, 0, true);
						choice_elements.push(element);
					}
					element.show(choice);
					
					//where should it go?
					if(next_x + element.width > _w){
						next_x = _base_padd;
						next_y += element.height + padd;
					}
					
					//if we are not a subscriber and we hit the subscriber only stuff, throw on the text
					if(!is_sub && choice.is_subscriber && !subscriber_tf.visible){
						if(next_x != _base_padd) next_y += element.height + padd;
						subscriber_tf.visible = true;
						subscriber_tf.y = next_y;
						next_y += subscriber_tf.height + padd;
						next_x = _base_padd;
					}
					
					element.x = next_x;
					element.y = next_y;
					
					next_x += element.width + padd;
					_scroller.body.addChild(element);
					
					//set our current element
					if(choice.is_current) current_element = element;
				}
				
				//set the padder
				padder.y = next_x != _base_padd ? next_y + element.height + padd : next_y;
				
				invalidate();
			}
		}
		
		private function resetPool():void {
			var i:int;
			var total:int = choice_elements.length;
			var element:HouseStylesChoiceUI;
			for(i; i < total; i++){
				element = choice_elements[int(i)];
				element.hide();
			}
		}
		
		private function updateChangeButton(pc_stats:PCStats = null):void {
			if(!current_element) return;
			const pc:PC = model.worldModel.pc;
			const imagination:int = pc && pc.stats ? pc.stats.imagination : 0;
			const is_sub:Boolean = pc && pc.stats ? pc.stats.is_subscriber : false;
			const house_styles:HouseStyles = HouseManager.instance.house_styles;
			
			change_bt.disabled = current_element.choice.is_current || imagination < house_styles.cost || (current_element.choice.is_subscriber && !is_sub);
			change_bt.label = current_element.choice.is_current ? 'Change' : 'Change for '+StringUtil.formatNumberWithCommas(house_styles.cost)+'i';
			var tip_txt:String;
			if(change_bt.disabled){
				if(imagination < house_styles.cost){
					tip_txt = 'You need more imagination';
				}
				else if(current_element.choice.is_subscriber && !is_sub){
					tip_txt = 'You need to be a subscriber';
				}
			}
			
			change_bt.tip = tip_txt ? { txt:tip_txt, pointer:WindowBorder.POINTER_BOTTOM_CENTER} : null;
		}
		
		private function onElementClick(event:MouseEvent):void {
			//get the choice data from the clicked element
			const element:HouseStylesChoiceUI = event.currentTarget as HouseStylesChoiceUI;
			current_element = element;
			
			//make sure we are able to purchase the change
			updateChangeButton();
			
			//if this was a subscriber only thing, open the dialog
			const pc:PC = model.worldModel.pc;
			const is_sub:Boolean = pc && pc.stats ? pc.stats.is_subscriber : false;
			
			//show the light box
			if(!current_element.choice.is_current){
				LightBox.instance.show(
					current_element.choice.main_image, 
					current_element.choice.label, 
					lightbox_buttons, 
					current_element.choice.is_subscriber && !is_sub ? lightbox_extra_sp : null
				);
				SoundMaster.instance.playSound('CLICK_SUCCESS');
			}
			
			//make sure the others are not selected
			var i:int;
			var total:int = choice_elements.length;
			var other_element:HouseStylesChoiceUI;
			for(i; i < total; i++){
				other_element = choice_elements[int(i)];
				other_element.selected = other_element == element;
			}
		}
		
		private function onChangeClick(event:TSEvent):void {
			SoundMaster.instance.playSound(!change_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(change_bt.disabled) return;
			change_bt.disabled = true;
			
			const pc:PC = model.worldModel.pc;
			const is_external_street:Boolean = pc.home_info.exterior_tsid == model.worldModel.location.tsid;
			
			//setup the text and then call the confirm
			cdVO.txt = 'Are you sure you want to change your street style for <b>'+StringUtil.formatNumberWithCommas(HouseManager.instance.house_styles.cost)+'i</b>?';
			
			TSFrontController.instance.confirm(cdVO);
		}
		
		private function onConfirm(is_yes:Boolean):void {
			if(is_yes){
				//send it off to the server
				change_bt.show_spinner = true;
				HouseManager.instance.sendStyleChange(current_element.choice.tsid);
			}
			else {
				//just update the button again
				updateChangeButton();
			}
		}
		
		private function onCancelClick(event:TSEvent):void {
			SoundMaster.instance.playSound(!cancel_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(cancel_bt.disabled) return;
			
			//close the light box
			LightBox.instance.hide();
		}
	}
}