package com.tinyspeck.engine.port
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.TeleportationScript;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.location.Hub;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCTeleportation;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;

	public class TeleportationScriptDialog extends BigDialog implements ITipProvider
	{
		/* singleton boilerplate */
		public static const instance:TeleportationScriptDialog = new TeleportationScriptDialog();
		
		private const DISABLED_ALPHA:Number = .5;
		private const NOTE_HEIGHT:uint = 80;
		private const NOTE_MAX_CHARS:uint = 180;
		private const NOTE_DEFAULT_TEXT:String = 'Write something!';
		private const ICON_WIDTH:uint = 81;
		private const ICON_HEIGHT:uint = 107;
		
		private var use_bt:Button;
		private var create_bt:Button;
		private var add_note_bt:Button;
		private var cancel_bt:Button;
		private var energy_bt:Button;
		
		private var description_tf:TSLinkedTextField = new TSLinkedTextField();
		private var created_tf:TSLinkedTextField = new TSLinkedTextField();
		private var note_tf:TSLinkedTextField = new TSLinkedTextField();
		private var note_input_tf:TextField = new TextField();
		private var token_count_tf:TextField = new TextField();
		
		private var all_holder:Sprite = new Sprite();
		private var icon_holder:Sprite = new Sprite();
		
		private var icon_unimbued:DisplayObject;
		private var icon_imbued:DisplayObject;
		private var icon_unimbued_buymore:DisplayObject;
		private var icon_unimbued_coststoken:DisplayObject;
		private var icon_unimbued_noskill:DisplayObject;
		
		private var token_count:int;
		
		private var is_built:Boolean;
		
		public function TeleportationScriptDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_head_min_h = 60;
			_body_min_h = 100;
			_foot_min_h = 60;
			_base_padd = 20;
			_body_border_c = 0xffffff;
			_body_fill_c = 0xffffff;
			_draggable = true;
			_construct();
		}
		
		private function buildBase():void {
			is_built = true;
			
			//the all holder
			var g:Graphics = all_holder.graphics;
			g.clear();
			g.beginFill(_body_fill_c);
			g.drawRect(0, 0, _w - _base_padd, NOTE_HEIGHT + _base_padd);
			_scroller.addChild(all_holder);
			
			//buttons
			create_bt = new Button({
				name: 'create',
				label: 'Create Script',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			create_bt.x = int(_w - create_bt.width - _base_padd);
			create_bt.addEventListener(TSEvent.CHANGED, onCreateClick, false, 0, true);
			_foot_sp.addChild(create_bt);
			
			add_note_bt = new Button({
				name: 'add_note',
				label: 'Add a custom note',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR,
				y: 10
			});
			add_note_bt.x = int(_w - add_note_bt.width - _base_padd - 5);
			add_note_bt.addEventListener(TSEvent.CHANGED, onAddNoteClick, false, 0, true);
			all_holder.addChild(add_note_bt);
			
			cancel_bt = new Button({
				name: 'cancel',
				label: 'Cancel',
				size: Button.SIZE_TINY,
				type: Button.TYPE_CANCEL,
				x: _base_padd
			});
			cancel_bt.addEventListener(TSEvent.CHANGED, onCancelClick, false, 0, true);
			_foot_sp.addChild(cancel_bt);
			
			use_bt = new Button({
				name: 'use',
				label: 'Teleport Now',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			use_bt.addEventListener(TSEvent.CHANGED, onUseClick, false, 0, true);
			all_holder.addChild(use_bt);
			
			energy_bt = new Button({
				name: 'energy',
				label: 'Spend Energy',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR,
				x: _base_padd
			});
			energy_bt.addEventListener(TSEvent.CHANGED, onEnergyClick, false, 0, true);
			all_holder.addChild(energy_bt);
			
			_foot_sp.visible = true;
			
			//note tf
			TFUtil.prepTF(note_input_tf, false);
			TFUtil.setTextFormatFromStyle(note_input_tf, 'note_body');
			note_input_tf.wordWrap = true;
			note_input_tf.selectable = true;
			note_input_tf.type = TextFieldType.INPUT;
			note_input_tf.autoSize = TextFieldAutoSize.NONE;
			note_input_tf.width = _w - _base_padd*4;
			note_input_tf.height = NOTE_HEIGHT - 10;
			note_input_tf.x = _base_padd*2 - 4;
			note_input_tf.y = _base_padd;
			note_input_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			note_input_tf.maxChars = NOTE_MAX_CHARS;
			note_input_tf.addEventListener(MouseEvent.CLICK, onNoteClick, false, 0, true);
			_scroller.body.addChildAt(note_input_tf, 0);
			resetNote();
			
			//draw the note BG
			var bg_color:uint = CSSManager.instance.getUintColorValueFromStyle('note_body_background', 'backgroundEditColor', 0xf5f5ce);
			var border_color:uint = CSSManager.instance.getUintColorValueFromStyle('note_body_background', 'borderEditColor', 0xc3c38e);
			g = _scroller.body.graphics;
			g.clear();
			g.lineStyle(1, border_color);
			g.beginFill(bg_color);
			g.drawRoundRect(_base_padd, 10, _w - _base_padd*2 - 2, NOTE_HEIGHT, 10);
			
			//note when reading
			TFUtil.prepTF(note_tf);
			note_tf.width = _w - _base_padd*2;
			note_tf.x = _base_padd;
			note_tf.y = 10;
			all_holder.addChild(note_tf);
			
			//description
			TFUtil.prepTF(description_tf);
			description_tf.embedFonts = false;
			description_tf.x = _base_padd;
			description_tf.width = 300;
			all_holder.addChild(description_tf);
			
			//remaining tokens
			TFUtil.prepTF(token_count_tf);
			token_count_tf.width = ICON_WIDTH;
			all_holder.addChild(token_count_tf);
			
			//created by
			TFUtil.prepTF(created_tf, false);
			created_tf.embedFonts = false;
			created_tf.x = _base_padd;
			all_holder.addChild(created_tf);
			
			//imbued icon
			icon_unimbued = new AssetManager.instance.assets.teleportation_token_unimbued();
			icon_imbued = new AssetManager.instance.assets.teleportation_token_imbued();
			icon_unimbued_buymore = new AssetManager.instance.assets.teleportation_token_unimbued_buymore();
			icon_unimbued_coststoken = new AssetManager.instance.assets.teleportation_token_unimbued_coststoken();
			icon_unimbued_noskill = new AssetManager.instance.assets.teleportation_token_unimbued_noskill();
			
			if(icon_unimbued){
				icon_holder.x = int(add_note_bt.x + (add_note_bt.width-icon_unimbued.width)/2);
				icon_holder.addEventListener(MouseEvent.CLICK, onImbueClick, false, 0, true);
				all_holder.addChild(icon_holder);
			}
			else {
				CONFIG::debugging {
					Console.warn('Missing the unimbued icon at least');
				}
				
				is_built = false;
			}
		}
		
		override public function start():void {
			var script:TeleportationScript = TeleportationScriptManager.instance.current_script;
			if(!TeleportationScriptManager.instance.current_script){
				CONFIG::debugging {
					Console.warn('There is no current script to work with!');
				}
				return;
			}
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			if(parent) end(false);
			
			//reset
			all_holder.y = 0;
			resetNote();
									
			//are we creating or using?
			toggleMode(TeleportationScriptManager.instance.current_script);
			
			//setup stuff
			TipDisplayManager.instance.registerTipTrigger(icon_holder);
			TeleportationDialog.instance.addEventListener(TSEvent.COMPLETE, update, false, 0, true);
			TeleportationDialog.instance.addEventListener(TSEvent.CHANGED, update, false, 0, true);
			
			super.start();
		}
		
		override public function end(release:Boolean):void {
			super.end(release);
			
			//un-setup stuff
			TipDisplayManager.instance.unRegisterTipTrigger(icon_holder);
			TeleportationDialog.instance.removeEventListener(TSEvent.COMPLETE, update);
			TeleportationDialog.instance.removeEventListener(TSEvent.CHANGED, update);
		}
		
		public function createFail():void {
			create_bt.disabled = false;
			SoundMaster.instance.playSound('CLICK_FAILURE');
		}
		
		public function useFail():void {
			update();
			SoundMaster.instance.playSound('CLICK_FAILURE');
		}
		
		public function imbueSuccess():void {
			TeleportationScriptManager.instance.current_script.is_imbued = true;
			update();
			token_count_tf.visible = false;
			
			//disable the buttons and close the dialog
			use_bt.disabled = true;
			energy_bt.disabled = true;
			StageBeacon.setTimeout(end, 1000, true);
		}
		
		public function imbueFail():void {
			SoundMaster.instance.playSound('CLICK_FAILURE');
		}
		
		private function toggleMode(script:TeleportationScript):void {
			//set the title
			if(script.start_in_edit_mode){
				_setTitle('<span class="teleportation_script_title">Create a Teleportation Script which will take the user ' +
						  'to your exact current location in the world</span>');
			}
			else {
				_setTitle('<span class="teleportation_script_title_read">A Teleportation Script</span>');
			}
			
			//update UI elements
			update();
			
			//toggle the buttons
			create_bt.disabled = !script.start_in_edit_mode;
			create_bt.visible = script.start_in_edit_mode;
			cancel_bt.visible = script.start_in_edit_mode;
			use_bt.visible = !script.start_in_edit_mode;
			add_note_bt.visible = script.start_in_edit_mode;
			
			//if in read mode, is there a note?
			note_tf.visible = !script.start_in_edit_mode;
			if(!script.start_in_edit_mode && script.body){
				note_tf.htmlText = '<p class="teleportation_script_note">'+script.body+'</p>';
			}
			else {
				note_tf.text = '';
			}
			icon_holder.y = script.start_in_edit_mode ? int(add_note_bt.y + add_note_bt.height + 20) : int(note_tf.y + note_tf.height + 10);
			
			//token count
			token_count_tf.x = icon_holder.x;
			token_count_tf.y = icon_holder.useHandCursor ? int(icon_holder.y + icon_holder.height + 5) : 0;
			token_count_tf.visible = icon_holder.useHandCursor;
			
			//set the description
			var location_label:String = script.start_in_edit_mode ? 'this spot' : 'some place';
			var hub_label:String;
			var hub:Hub;
			var loc:Location = model.worldModel.location;
			
			//creating
			if(script.start_in_edit_mode && loc && loc.hub_id){
				location_label = loc.label;
				if(!loc.is_pol) location_label = '<a href="event:'+TSLinkedTextField.LINK_LOCATION+'|'+loc.hub_id+'#'+loc.tsid+'">'+loc.label+'</a>';
				hub = model.worldModel.getHubByTsid(loc.hub_id);
				if(hub && !loc.is_pol){
					hub_label = '<a href="event:'+TSLinkedTextField.LINK_LOCATION+'|'+hub.tsid+'">'+hub.label+'</a>';
				}
			}
			//reading
			else if(!script.start_in_edit_mode && script.destination){
				loc = model.worldModel.getLocationByTsid(script.destination);
				if(loc && loc.hub_id){
					location_label = loc.label;
					if(!loc.is_pol) location_label = '<a href="event:'+TSLinkedTextField.LINK_LOCATION+'|'+loc.hub_id+'#'+loc.tsid+'">'+loc.label+'</a>';
					hub = model.worldModel.getHubByTsid(loc.hub_id);
					if(hub && !loc.is_pol){
						hub_label = '<a href="event:'+TSLinkedTextField.LINK_LOCATION+'|'+hub.tsid+'">'+hub.label+'</a>';
					}
				}
			}
			
			description_tf.htmlText = '<p class="teleportation_script_description">This script will teleport whosoever uses it to '+
									  location_label+(hub_label ? ' in&nbsp;'+hub_label : '');
			description_tf.y = int(icon_holder.y + (icon_holder.height/2 - description_tf.height/2));
			
			//put the created by
			created_tf.y = int(description_tf.y + description_tf.height + 8);
			
			//move the use button to where it needs to go
			use_bt.y = script.start_in_edit_mode ? 0 : int(created_tf.y + created_tf.height + 20);
			energy_bt.y = use_bt.y;
		}
		
		private function update(event:Event = null):void {			
			//bunch of rules when the use button can be used.
			var script:TeleportationScript = TeleportationScriptManager.instance.current_script;
			var tip_txt:String;
			var energy_txt:String;
			var pc:PC = model.worldModel.pc;
			var teleportation:PCTeleportation = pc ? pc.teleportation : null;
			var skill_level:int = teleportation ? pc.teleportation.skill_level : 0;
			token_count = teleportation ? teleportation.tokens_remaining : 0;
			var energy_needed:int = teleportation ? teleportation.energy_cost : 999999;
			var energy_has:int = pc && pc.stats && pc.stats.energy ? pc.stats.energy.value : 0;
			var can_teleport_now:Boolean;
			var is_confirm:Boolean;
			
			/** DEBUGGING
			token_count = 0;
			skill_level = 0;
			energy_has = 1000;
			//TeleportationDialog.instance.cooldown_left = 0;
			//**/
			
			use_bt.disabled = true;
			energy_bt.visible = false;
			energy_bt.disabled = false;
			
			//clean the icon
			SpriteUtil.clean(icon_holder);
			icon_holder.alpha = 1;
									
			//make sure the author is known
			setAuthor(script);
			
			//set the token count
			token_count_tf.htmlText = '<p class="teleportation_script_count">Tokens left: '+StringUtil.formatNumberWithCommas(token_count)+'</p>';
			
			if(script){
				use_bt.disabled = false;
				icon_holder.useHandCursor = icon_holder.buttonMode = true;
				can_teleport_now = script.is_imbued;
				
				//if we are editing
				if(script.start_in_edit_mode){
					if(token_count){
						if(icon_unimbued) icon_holder.addChild(icon_unimbued);
					}
					else {
						if(icon_unimbued_buymore) icon_holder.addChild(icon_unimbued_buymore);
					}
					return;
				}
				
				//if it's not imbued, figure out what image to show/disable the button
				if(!script.is_imbued){
					//on cooldown
					if(TeleportationDialog.instance.cooldown_left > 0){
						use_bt.disabled = true;
						tip_txt = 'Teleportation cooldown active. No teleporting!';
					}
					//same street
					else if(script.destination && model.worldModel.location && model.worldModel.location.tsid == script.destination){
						use_bt.disabled = true;
						tip_txt = 'This script goes somewhere on the street you\'re already on!';
					}
					//no skill
					else if(skill_level == 0){
						if(token_count){
							tip_txt = 'This script was not imbued. Use a token instead?';
							is_confirm = true;
						}
						else {
							use_bt.disabled = true;
							tip_txt = 'This script was not imbued and you are all out of teleportation tokens.';
						}
					}
					//not enough energy
					else if(energy_has < energy_needed){
						if(token_count){
							tip_txt = 'You do not have enough energy to teleport ('+StringUtil.formatNumberWithCommas(energy_needed)+'&nbsp;required). Use a token instead?';
							is_confirm = true;
						}
						else {
							use_bt.disabled = true;
							tip_txt = 'You do not have enough energy to teleport ('+StringUtil.formatNumberWithCommas(energy_needed)+'&nbsp;required) and you are all out of teleportation tokens.';
						}
					}
					//no tokens
					else if(token_count == 0){
						use_bt.disabled = true;
						tip_txt = 'This script was not imbued and you are all out of teleportation tokens.';
					}
					
					//add the graphics to imbue
					if(token_count){
						if(icon_unimbued) icon_holder.addChild(icon_unimbued);
					}
					/*
					//no skill - doesn't apply anymore
					else if(skill_level == 0){						
						if(icon_unimbued_noskill) icon_holder.addChild(icon_unimbued_noskill);
					}
					*/
					//offer them the chance to buy
					else {
						if(icon_unimbued_buymore) icon_holder.addChild(icon_unimbued_buymore);
					}
					
					//set up the energy button if they have skills and not able to teleport
					if(skill_level && !can_teleport_now){
						energy_bt.visible = true;
						energy_bt.label = 'Spend '+energy_needed+' energy to teleport';
						
						if(TeleportationDialog.instance.cooldown_left > 0){
							energy_bt.disabled = true;
							energy_txt = 'Teleportation cooldown active. No teleporting!';
						}
						//same street
						else if(script.destination && model.worldModel.location && model.worldModel.location.tsid == script.destination){
							energy_bt.disabled = true;
							energy_txt = 'This script goes somewhere on the street you\'re already on!';
						}
						else if(energy_has < energy_needed){
							energy_bt.disabled = true;
							energy_txt = 'You do not have enough energy to teleport ('+StringUtil.formatNumberWithCommas(energy_needed)+'&nbsp;required).';
						}
					}
				}
				else {
					icon_holder.useHandCursor = icon_holder.buttonMode = false;
					if(icon_imbued) icon_holder.addChild(icon_imbued);
					
					//make sure to disable if we are cooldown
					if(TeleportationDialog.instance.cooldown_left > 0){
						use_bt.disabled = true;
						tip_txt = 'Teleportation cooldown active. No teleporting!';
					}
					//same street
					else if(script.destination && model.worldModel.location && model.worldModel.location.tsid == script.destination){
						use_bt.disabled = true;
						tip_txt = 'This script goes somewhere on the street you\'re already on!';
					}
				}
				
				//set the buttons
				use_bt.setSizeAndType(energy_bt.visible ? Button.SIZE_TINY : Button.SIZE_DEFAULT, Button.TYPE_MINOR);
				use_bt.label = can_teleport_now ? 'Teleport Now' : 'Use a Token';
				use_bt.x = energy_bt.visible ? int(energy_bt.x + energy_bt.width + 15) : int(_w/2 - use_bt.width/2);
				use_bt.value = !can_teleport_now ? 'confirm_token' : '';
				
				_jigger();
			}
			
			//if for some reason there is nothing in the holder, draw an empty box instead
			//this makes sure things still line up properly
			if(icon_holder.numChildren == 0){
				var g:Graphics = icon_holder.graphics;
				g.beginFill(0,0);
				g.drawRect(0, 0, ICON_WIDTH, ICON_HEIGHT);
				
				BootError.handleError('WTF, no icon?! '+
					icon_unimbued+', '+
					icon_imbued+', '+
					icon_unimbued_buymore+', '+
					icon_unimbued_coststoken+', '+
					icon_unimbued_noskill+', '+
					'skill '+skill_level+', '+
					'token count '+token_count+', '+
					'Eng has:Eng need '+energy_has+':'+energy_needed+', '+
					'Cooldown '+TeleportationDialog.instance.cooldown_left+
					'Script? '+script+
					'WHERE?! '+(script && script.destination ? script.destination : 'No destination?!'), 
					new Error('Icon not showing up in teleportation dialog'), null, true
				);
			}
			
			//set the tip if there is one
			use_bt.tip = tip_txt ? { txt:tip_txt, pointer:WindowBorder.POINTER_BOTTOM_CENTER } : null;
			energy_bt.tip = energy_txt ? { txt:energy_txt, pointer:WindowBorder.POINTER_BOTTOM_CENTER } : null;
		}
		
		private function setAuthor(script:TeleportationScript):void {
			//check to make sure we have a script, otherwise empty it out
			if(!script){
				created_tf.text = '';
				created_tf.visible = false;
				created_tf.y = 0;
				return;
			}
			
			//if we have a script, but the tsid is blank, that means it's from the system
			var txt:String = 'Created by ';
			
			if(script.owner_tsid && script.owner_label){
				txt += '<a href="event:'+TSLinkedTextField.LINK_PLAYER_INFO+'|'+script.owner_tsid+'">'+script.owner_label+'</a>';
			}
			else {
				txt += 'The game itself';
			}
			
			created_tf.visible = !script.start_in_edit_mode;
			created_tf.htmlText = '<p class="teleportation_script_created">'+txt+'</p>';
		}
		
		override protected function _jigger():void {
			super._jigger();
			
			_title_tf.y = _base_padd;
			
			_body_h = Math.max(_body_min_h, all_holder.y + all_holder.height + _base_padd);
			_foot_h = use_bt.visible ? 0 : _foot_h;
			_h = _head_h + _body_h + _foot_h;
			_foot_sp.y = _head_h + _body_h;
			
			_draw();
		}
		
		private function onCreateClick(event:TSEvent):void {
			if(create_bt.disabled) return;
			create_bt.disabled = true;
			
			//tell the server we wanna make it!
			TeleportationScriptManager.instance.createScript(icon_holder.contains(icon_imbued), note_input_tf.text != NOTE_DEFAULT_TEXT ? note_input_tf.text : '');
		}
		
		private function onUseClick(event:TSEvent):void {
			if(use_bt.disabled) return;
			use_bt.disabled = true;

			//if they need to confirm it, ask em to
			if(use_bt.value == 'confirm_token'){
				confirmToken();
			}
			else {
				TeleportationScriptManager.instance.useScript(false);
			}
		}
		
		private function onAddNoteClick(event:TSEvent):void {
			//hide the button
			add_note_bt.visible = false;
			
			//notch up everything that's visible
			var i:int;
			var child:DisplayObject;
			
			for(i; i < all_holder.numChildren; i++){
				child = all_holder.getChildAt(i);
				if(child.visible) child.y -= int(add_note_bt.height);
			}
						
			//animate
			TSTweener.removeTweens(all_holder);
			TSTweener.addTween(all_holder, {y:NOTE_HEIGHT + 12, time:.3, onUpdate:_jigger, onComplete:focusOnInput});
		}
		
		private function onCancelClick(event:TSEvent):void {
			end(true);
		}
		
		private function onImbueClick(event:MouseEvent):void {
			//let's see if we can imbue this bad boy
			if(!icon_holder.useHandCursor) return;
			
			//if we are in read mode, we need to confirm with the player that they want to do this
			if(use_bt.visible && icon_holder.contains(icon_unimbued)){
				confirmImbue();
				return;
			}
			
			//if the imbue is already in there, go ahead and take it out
			if(icon_holder.contains(icon_imbued)){
				icon_holder.removeChild(icon_imbued);
				icon_holder.addChild(icon_unimbued);
			}
			else if(icon_holder.contains(icon_unimbued)){
				icon_holder.removeChild(icon_unimbued);
				icon_holder.addChild(icon_imbued);
			}
			else if(icon_holder.contains(icon_unimbued_buymore)){
				//open the token page
				TSFrontController.instance.openTokensPage();
			}
		}
		
		private function onNoteClick(event:MouseEvent):void {
			//if they clicked the TF and it's the default text, empty it out
			if(note_input_tf.text == NOTE_DEFAULT_TEXT){
				note_input_tf.text = '';
			}
		}
		
		private function onEnergyClick(event:TSEvent):void {
			if(energy_bt.disabled) return;
			
			//just use it
			TeleportationScriptManager.instance.useScript(false);
		}
		
		private function resetNote():void {
			note_input_tf.text = NOTE_DEFAULT_TEXT;
		}
		
		private function confirmImbue():void {
			TSFrontController.instance.confirm(
				new ConfirmationDialogVO(
					function(value:*):void {
						if(value !== false) {
							TeleportationScriptManager.instance.imbueScript();
							//imbueSuccess();
						}
						else {
							update();
						}
					},
					'Are you sure you want to imbue this script with a teleportation token (it cannot be undone)?<font size="2"><br><br></font>You have '+token_count+' remaining.',
					[
						{value: true, label: 'Yes, please'},
						{value: false, label: 'No, thank you'}
					],
					false
				)
			);
		}
		
		private function confirmToken():void {
			const teleportation:PCTeleportation = model.worldModel.pc ? model.worldModel.pc.teleportation : null;
			if(!teleportation) return;
			
			const txt:String = 'Did you want to spend a token to teleport to this location?<br>You have have '+
								StringUtil.formatNumberWithCommas(teleportation.tokens_remaining)+' '+(teleportation.tokens_remaining != 1 ? 'tokens' : 'token')+' remaining.';
			
			TSFrontController.instance.confirm(
				new ConfirmationDialogVO(
					function(value:*):void {
						if(value !== false) {
							TeleportationScriptManager.instance.useScript(true);
						}
						else {
							update();
						}
					},
					txt,
					[
						{value: true, label: 'Yes, please'},
						{value: false, label: 'No, thank you'}
					],
					false
				)
			);
		}
		
		public function focusOnInput(select_all:Boolean = true):void {
			if (StageBeacon.stage.focus == note_input_tf) return;
			StageBeacon.stage.focus = note_input_tf;
			var start:int = (select_all) ? 0 : note_input_tf.text.length;
			note_input_tf.setSelection(start, note_input_tf.text.length);
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target) return null;
			
			var txt:String;
			
			if(tip_target == icon_holder){
				if(icon_unimbued && icon_holder.contains(icon_unimbued)){
					txt = 'Click to imbue this with a Teleportation Token (you have '+token_count+' remaining)';
					if(icon_holder.alpha == DISABLED_ALPHA){
						txt = 'You need a Teleportation Token to imbue this';
					}
				}
				else if(icon_imbued && icon_holder.contains(icon_imbued)){
					txt = 'This script has been imbued with a Teleportation Token for free travel!';
				}
				else if(icon_unimbued_noskill && icon_holder.contains(icon_unimbued_noskill)){
					txt = 'You will need Teleportation I to use this';
				}
				else if(icon_unimbued_coststoken && icon_holder.contains(icon_unimbued_coststoken)){
					txt = 'This script requires a Teleportation Token to use';
				}
				else if(icon_unimbued_buymore && icon_holder.contains(icon_unimbued_buymore)){
					txt = 'This script requires a Teleportation Token to use, but you need to buy more!';
				}
			}
			
			if(txt){
				return {
					txt: txt,
					pointer: WindowBorder.POINTER_BOTTOM_CENTER
				}
			}
			else {
				return null;
			}
		}
	}
}