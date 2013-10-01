package com.tinyspeck.engine.view.gameoverlay
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingCloseImgMenuVO;
	import com.tinyspeck.engine.net.NetOutgoingLocalChatVO;
	import com.tinyspeck.engine.port.ACLDialog;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.view.AvatarView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Cloud;
	import com.tinyspeck.engine.view.ui.imagination.ImaginationHandUI;
	import com.tinyspeck.engine.view.ui.imagination.ImaginationPurchaseUpgradeUI;
	import com.tinyspeck.engine.view.ui.imagination.ImaginationSkillsUI;
	import com.tinyspeck.engine.view.ui.imagination.ImaginationYourLooksUI;
	import com.tinyspeck.engine.view.ui.imagination.ImgMenuBackToWorld;
	import com.tinyspeck.engine.view.ui.imagination.ImgMenuElement;
	import com.tinyspeck.engine.view.ui.imagination.ImgMenuHome;
	import com.tinyspeck.engine.view.ui.imagination.ImgMenuKeys;
	import com.tinyspeck.engine.view.ui.imagination.ImgMenuQuests;
	import com.tinyspeck.engine.view.ui.imagination.ImgMenuSkills;
	import com.tinyspeck.engine.view.ui.imagination.ImgMenuTeleport;
	import com.tinyspeck.engine.view.ui.imagination.ImgMenuUpgrade;
	import com.tinyspeck.engine.view.ui.imagination.ImgMenuYourLooks;
	import com.tinyspeck.engine.view.ui.map.MapChatArea;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.ui.Keyboard;

	public class ImgMenuView extends BaseSplashScreenView implements IMoveListener
	{
		/* singleton boilerplate */
		public static const instance:ImgMenuView = new ImgMenuView();
		
		private static const BG_MATRIX:Matrix = new Matrix();
		private static const BG_COLORS:Array = [0,0];
		private static const BG_ALPHAS:Array = [.1,.7];
		private static const BG_RATIOS:Array = [50,255];
		private static const TOP_PADD:int = 30;
		
		private var avatar_local:Point = new Point();
		private var avatar_global:Point = new Point();
		private var cloud_local:Point = new Point();
		private var cloud_global:Point = new Point();
		
		private var close_bt:Button;
		private var back_bt:Button;
		private var elements:Vector.<ImgMenuElement> = new Vector.<ImgMenuElement>();
		private var skills:ImgMenuSkills = new ImgMenuSkills();
		private var quests:ImgMenuQuests = new ImgMenuQuests();
		private var upgrade:ImgMenuUpgrade = new ImgMenuUpgrade();
		private var keys:ImgMenuKeys = new ImgMenuKeys();
		private var teleport:ImgMenuTeleport = new ImgMenuTeleport();
		private var home:ImgMenuHome = new ImgMenuHome();
		private var back_to_world:ImgMenuBackToWorld = new ImgMenuBackToWorld();
		private var your_looks:ImgMenuYourLooks = new ImgMenuYourLooks();
		
		private var function_to_call_after_hide_tween_is_complete:Function;
		
		private var current_choice_i:int = -1;
		
		private var _cloud_to_open:String;
		private var _close_payload:Object;
		
		public var hide_close:Boolean;
		private var is_hiding:Boolean;
		
		public function ImgMenuView(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		override protected function buildBase():void {
			super.buildBase();
			
			all_holder.y = TOP_PADD;
			
			//close
			const close_DO:DisplayObject = new AssetManager.instance.assets.iMG_close();
			close_bt = new Button({
				name: 'close',
				graphic: close_DO,
				draw_alpha: 0,
				w: close_DO.width,
				h: close_DO.height
			});
			close_bt.y = 10;
			close_bt.addEventListener(TSEvent.CHANGED, onDoneClick, false, 0, true);
			addChild(close_bt);
			
			//back
			const back_DO:DisplayObject = new AssetManager.instance.assets.iMG_back();
			back_bt = new Button({
				name: 'back',
				label: 'Back',
				label_face: 'VAGRoundedBoldEmbed',
				label_c: 0xffffff,
				label_size: 18,
				graphic: back_DO,
				graphic_placement: 'left',
				graphic_padd_t: 8,
				draw_alpha: 0
			});
			back_bt.x = 108;
			back_bt.y = 20;
			back_bt.addEventListener(TSEvent.CHANGED, showMainMenu, false, 0, true);
			addChild(back_bt);
			
			//elements
			skills.addEventListener(MouseEvent.CLICK, onSkillsClick, false, 0, true);
			quests.addEventListener(MouseEvent.CLICK, onQuestsClick, false, 0, true);
			home.addEventListener(MouseEvent.CLICK, onHomeClick, false, 0, true);
			back_to_world.addEventListener(MouseEvent.CLICK, onBackToWorldClick, false, 0, true);
			upgrade.addEventListener(MouseEvent.CLICK, onUpgradeClick, false, 0, true);
			keys.addEventListener(MouseEvent.CLICK, onKeysClick, false, 0, true);
			teleport.addEventListener(MouseEvent.CLICK, onTeleportClick, false, 0, true);
			your_looks.addEventListener(MouseEvent.CLICK, onYourLooksClick, false, 0, true);
			
			elements.push(skills, quests, upgrade, your_looks, teleport, home, back_to_world);
			
			var i:int;
			var total:int = elements.length;
			var element:ImgMenuElement;
			for(i; i < total; i++){
				element = elements[int(i)];
				element.show(); //builds em out
				element.hide();
				element.addEventListener(MouseEvent.ROLL_OVER, onElementMouse, false, 0, true);
				all_holder.addChildAt(elements[int(i)], 0);
			}
		}
		
		override public function show():Boolean {
			//if we are moving, don't do anything
			if(TSModelLocator.instance.moveModel.moving) return false;
			
			//hide it
			alpha = 0;
			
			//build it			
			if(!is_built) buildBase();
			
			//can we take focus yet?
			if(!tryAndTakeFocus()){
				return false;
			}
			
			//we an't hiding no mo
			is_hiding = false;
			
			//make the skills disabled until it loads in the skills
			//skills.enabled = false;
			
			//if the player is less than level 3, then we disable Your Looks
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			
			CONFIG::debugging {
				Console.info(pc.stats.level);
			}
			your_looks.visible = your_looks.enabled = pc && pc.stats && pc.stats.level >= 3;
			CONFIG::debugging {
				Console.info(your_looks.visible+' '+your_looks.enabled);
			}

			your_looks.setTipText(your_looks.enabled ? '' : 'Not until Level 3!');
			
			//do we need to hide the close button?
			close_bt.visible = !hide_close;
			
			//setup for animation
			draw();
			animate();
			
			//focus the default
			if(!_cloud_to_open && current_choice_i == -1){
				ready_for_input = true;
				focusChoice(0);
				ready_for_input = false;
			}
			
			//if we need to open something by default, let's do that
			if(_cloud_to_open){
				switch(_cloud_to_open){
					case Cloud.TYPE_BACK_TO_WORLD:
						onBackToWorldClick();
						break;
					case Cloud.TYPE_HOME:
						onHomeClick();
						break;
					case Cloud.TYPE_KEYS:
						onKeysClick();
						break;
					case Cloud.TYPE_QUESTS:
						onQuestsClick();
						break;
					case Cloud.TYPE_SKILLS:
					case Cloud.TYPE_SKILLS_LARGE:
						toggleSkillsUI();
						break;
					case Cloud.TYPE_UPGRADES:
						//if we are already showing this, no need to show it again
						if(!ImaginationHandUI.instance.parent){
							onUpgradeClick();
						}
						break;
					case Cloud.TYPE_YOUR_LOOKS:
						onYourLooksClick();
						break;
				}
				_cloud_to_open = null;
			}
			else {
				//toss them on the screen
				showElements();
			}
			
			//play the open sound
			SoundMaster.instance.playSound('IMAGINATION_OPEN');
			
			const model:TSModelLocator = TSModelLocator.instance;
			
			//hide the minimap
			TSFrontController.instance.changeMiniMapVisibility();
			
			//hide the current energy
			YouDisplayManager.instance.toggleEnergyText();
			
			//see if they have teleportation or not
			teleport.enabled = model.worldModel.pc.teleportation && model.worldModel.pc.teleportation.skill_level > 0;
			
			//listen to stuff
			ImaginationHandUI.instance.addEventListener(TSEvent.CLOSE, showElements, false, 0, true);
			ImaginationSkillsUI.instance.addEventListener(TSEvent.CLOSE, showElements, false, 0, true);
			//ACLDialog.instance.addEventListener(TSEvent.CLOSE, showElements, false, 0, true);
			TSFrontController.instance.registerMoveListener(this);
			model.stateModel.registerCBProp(forceHide, "hand_of_god");
			model.stateModel.registerCBProp(forceHide, "decorator_mode");
			model.stateModel.registerCBProp(forceHide, "cult_mode");
			model.stateModel.registerCBProp(forceHide, "chassis_mode");
			
			//let the listeners know we are open!
			dispatchEvent(new TSEvent(TSEvent.STARTED));
			
			return true;
		}
		
		override public function hide():void {
			if(is_hiding) return;
			
			TSTweener.addTween(this, {alpha:0, time:!hide_close ? .3 : 1, transition:'linear', onComplete:onDoneTweenComplete});
			
			ready_for_input = false;
			is_hiding = true;
			
			//hide anything that's up
			hideElements();
			back_bt.visible = false;
			
			//stop listening
			ImaginationHandUI.instance.removeEventListener(TSEvent.CLOSE, showElements);
			ImaginationSkillsUI.instance.removeEventListener(TSEvent.CLOSE, showElements);
			//ACLDialog.instance.removeEventListener(TSEvent.CLOSE, showElements);
			TSFrontController.instance.removeMoveListener(this);
			
			const model:TSModelLocator = TSModelLocator.instance;
			model.stateModel.unRegisterCBProp(forceHide, "hand_of_god");
			model.stateModel.unRegisterCBProp(forceHide, "decorator_mode");
			model.stateModel.unRegisterCBProp(forceHide, "cult_mode");
			model.stateModel.unRegisterCBProp(forceHide, "chassis_mode");
			
			//play the hide sound
			SoundMaster.instance.playSound('IMAGINATION_CLOSE');
			
			//allow the menu to maybe show the next time it's opened
			hide_close = false;
			
			//send off the payload to the server
			if(_close_payload){
				TSFrontController.instance.genericSend(new NetOutgoingCloseImgMenuVO(_close_payload));
				_close_payload = null;
			}
		}
		
		override protected function draw():void {
			super.draw();
			const lm:LayoutModel = TSModelLocator.instance.layoutModel;
			const grad_size:uint = 650;
			const avatar:AvatarView = TSFrontController.instance.getMainView().gameRenderer.getAvatarView();
			if(!avatar || !avatar.parent) return; //bad scene
			avatar_local.x = avatar.x;
			avatar_global = avatar.parent.localToGlobal(avatar_local);
			
			//close
			close_bt.x = int(lm.loc_vp_w - close_bt.width - 10);
			
			//built the bg grad
			BG_MATRIX.createGradientBox(
				grad_size, 
				grad_size, 
				0,
				avatar_global.x - grad_size/2 - lm.gutter_w, //places it over the avatar
				lm.loc_vp_h/2 - 100
			);
			
			var g:Graphics = graphics;
			g.clear();
			
			//if we've got the upgrades or skills up, make sure to just make the BG solid
			const skills_ui:ImaginationSkillsUI = ImaginationSkillsUI.instance;
			const hand_ui:ImaginationHandUI = ImaginationHandUI.instance;
			const looks_ui:ImaginationYourLooksUI = ImaginationYourLooksUI.instance;
			if((skills_ui.parent && !skills_ui.is_hiding) || 
			   (hand_ui.parent && !hand_ui.is_hiding) ||
			   (looks_ui.parent && !looks_ui.is_hiding)){
				//solid
				g.beginFill(0, .7);	
			}
			else {
				//draw with the vingette
				g.beginGradientFill(GradientType.RADIAL, BG_COLORS, BG_ALPHAS, BG_RATIOS, BG_MATRIX);	
			}
			g.drawRoundRectComplex(0, 0, all_mask.width, all_mask.height, lm.loc_vp_elipse_radius, 0, lm.loc_vp_elipse_radius, 0);
			
			//divide up the viewport
			const element_padd:int = Math.min(lm.loc_vp_w/23, 40);
			var i:int;
			var total:int = elements.length;
			var element:ImgMenuElement;
			var next_x:int;
			var next_y:int;
			
			for(i = 0; i < total; i++){
				element = elements[int(i)];
				element.x = next_x;
				element.y = next_y;
				next_x += element.width + element_padd;
				
				if(element == upgrade){
					//top row is done, move on down
					next_x = -45;
					next_y += element.height + 65;
				}
				else if(element == teleport){
					element.y -= 10;
				}
				else if(element == home){
					element.y -= 45;
				}
				else if(element == back_to_world){
					//allows a little underlap
					element.x -= element_padd + 25;
				}
			}
			
			//center
			all_holder.x = int(lm.loc_vp_w/2 - (upgrade.x + upgrade.width)/2);
		}
		
		private function showElements(event:Event = null):void {
			//show them one by one
			var i:int;
			var total:int = elements.length;
			var element:ImgMenuElement;
			
			//for now gonna use a fade until the bouncy thing can be pre-calculated (and it's faster to prototype)
			for(i = 0; i < total; i++){
				element = elements[int(i)];
				TSTweener.removeTweens(element);
				element.alpha = 0;
				element.mouseEnabled = true;
				TSTweener.addTween(element, {alpha:1, time:.2, delay:.1*i, onStart:element.show, transition:'linear'});
			}
			
			back_bt.visible = false;
			
			//make sure we have something to focus
			if(current_choice_i == -1) focusChoice(0);
			
			draw();
		}
		
		private function hideElements(except:ImgMenuElement = null):void {
			//hide things
			var i:int;
			var total:int = elements.length;
			var element:ImgMenuElement;
			
			for(i; i < total; i++){
				element = elements[int(i)];
				if(except && element == except) continue;
				TSTweener.removeTweens(element);
				element.hide();
				element.mouseEnabled = false;
				
				//if we aren't going to auto-open something, fade it out nicely
				if(!_cloud_to_open){
					TSTweener.addTween(element, {alpha:0, time:.3, transition:'linear'});
				}
				else {
					element.alpha = 0;
				}
			}
			
			back_bt.visible = !hide_close;
		}
		
		public function getCloudBasePt(cloud_name:String):Point {
			var element:ImgMenuElement;
			
			switch(cloud_name){
				case Cloud.TYPE_BACK_TO_WORLD:
					element = back_to_world;
					break;
				case Cloud.TYPE_HOME:
					element = home;
					break;
				case Cloud.TYPE_KEYS:
					element = keys;
					break;
				case Cloud.TYPE_QUESTS:
					element = quests;
					break;
				case Cloud.TYPE_SKILLS:
				case Cloud.TYPE_SKILLS_LARGE:
					element = skills;
					break;
				case Cloud.TYPE_UPGRADES:
					element = upgrade;
					break;
				case Cloud.TYPE_YOUR_LOOKS:
					element = your_looks
					break;
			}
			
			if(element){
				//get the base point
				cloud_local.x = element.width/2;
				cloud_local.y = element.cloud_base_y;
				cloud_global = element.localToGlobal(cloud_local);
			}
			else {
				cloud_global.x = 0;
				cloud_global.y = 0;
			}
			
			return cloud_global;
		}
		
		override protected function stopListeningForControlEvts():void {
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.UP, upArrowKeyHandler);
			//KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.W, upArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.RIGHT, rightArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.D, rightArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, rightArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.D, rightArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DOWN, downArrowKeyHandler);
			//KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.S, downArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.LEFT, leftArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.A, leftArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, leftArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.A, leftArrowKeyHandler);
			
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.S, onSkillsClick);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.L, onQuestsClick);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.Q, onQuestsClick);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.U, onUpgradeClick);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.T, onTeleportClick);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.B, onBKey);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.H, onHKey);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.Y, onYourLooksClick);
			
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onEscKey);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.X, onDoneClick);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onEnterKey);
		}
		
		override protected function startListeningForControlEvts():void {
			//if we are hiding the close, dont' listen to anything but esc to hear the quack sound
			if(!hide_close){
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.UP, upArrowKeyHandler, false, 0, true);
				//KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.W, upArrowKeyHandler, false, 0, true);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.RIGHT, rightArrowKeyHandler, false, 0, true);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.D, rightArrowKeyHandler, false, 0, true);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, rightArrowKeyHandler, false, 0, true);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.D, rightArrowKeyHandler, false, 0, true);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DOWN, downArrowKeyHandler, false, 0, true);
				//KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.S, downArrowKeyHandler, false, 0, true);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.LEFT, leftArrowKeyHandler, false, 0, true);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.A, leftArrowKeyHandler, false, 0, true);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, leftArrowKeyHandler, false, 0, true);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.A, leftArrowKeyHandler, false, 0, true);
				
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.S, onSkillsClick, false, 0, true);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.Q, onQuestsClick, false, 0, true);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.L, onQuestsClick, false, 0, true);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.U, onUpgradeClick, false, 0, true);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.T, onTeleportClick, false, 0, true);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.B, onBKey, false, 0, true);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.H, onHKey, false, 0, true);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.Y, onYourLooksClick, false, 0, true);
				
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.X, onDoneClick, false, 0, true);
			}
			
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onEnterKey, false, 0, true);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onEscKey, false, 0, true);
		}
		
		private function downArrowKeyHandler(event:KeyboardEvent):void {
			focusNextChoice();
		}
		
		private function upArrowKeyHandler(event:KeyboardEvent):void {
			focusPrevChoice();
		}
		
		private function rightArrowKeyHandler(event:KeyboardEvent):void {
			focusNextChoice();
		}
		
		private function leftArrowKeyHandler(event:KeyboardEvent):void {
			focusPrevChoice();
		}
		
		private function focusChoice(index:int):void {					
			if(!ready_for_input) return;
			
			const total:int = elements.length;
			var i:int;
			var element:ImgMenuElement;
			
			//unfocus the old ones
			for(i; i < total; i++){
				element = elements[int(i)];
				element.focused = (i == index && element.enabled);
			}
			
			//get the new one
			current_choice_i = index;
			element = getElementAtIndex(current_choice_i);
			
			//if it's enabled, cool, otherwise focus the next choice			
			if(element && !element.enabled){
				focusNextChoice();
			}
		}
		
		private function focusNextChoice():void {
			if (!elements.length) return;
			var element:ImgMenuElement;
			
			if(current_choice_i+1 >= elements.length) {
				element = getElementAtIndex(0);
				if(element && element.enabled){
					focusChoice(0);
				}
				else {
					current_choice_i = 0;
					focusNextChoice();
				}
			}
			else {
				element = getElementAtIndex(current_choice_i+1);
				if(element && element.enabled){
					focusChoice(current_choice_i+1);
				}
				else {
					current_choice_i++;
					focusNextChoice();
				}
			}
		}
		
		private function focusPrevChoice():void {
			if (!elements.length) return;
			var element:ImgMenuElement;
			
			if(current_choice_i-1 < 0) {
				element = getElementAtIndex(elements.length-1);
				if(element && element.enabled){
					focusChoice(elements.length-1);
				}
				else {
					current_choice_i = elements.length-1;
					focusPrevChoice();
				}
			}
			else {
				element = getElementAtIndex(current_choice_i-1);
				if(element && element.enabled){
					focusChoice(current_choice_i-1);
				}
				else {
					current_choice_i--;
					focusPrevChoice();
				}
			}
		}
		
		private function getElementAtIndex(i:int):ImgMenuElement {
			if (i<0 || i>elements.length-1) {
				CONFIG::debugging {
					Console.error('i out of range:'+i+' '+(elements.length-1));
				}
				return null;
			}
			return elements[int(i)];
		}
		
		private function onElementMouse(event:MouseEvent):void {
			//if the element is enabled, set this as the new focused index
			const element:ImgMenuElement = event.currentTarget as ImgMenuElement;
			if(element && element.enabled){
				const index:int = elements.indexOf(element);
				if(index > -1) focusChoice(index);
			}
		}
		
		private function onEnterKey(event:Event = null):void {
			if (ImaginationPurchaseUpgradeUI.instance.parent) {
				ImaginationHandUI.instance.closePurchaseScreen();
			}
			else if (ImaginationHandUI.instance.isCardSelected()) {
				ImaginationHandUI.instance.buySelectedCard();
			}
			else if(!hide_close && current_choice_i > -1 && !back_bt.visible){
				//we should select what we have highlighted
				const element:ImgMenuElement = getElementAtIndex(current_choice_i);
				if(element){
					element.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
				}
			}
		}
		
		private function onEscKey(event:Event = null):void {		
			if (ImaginationHandUI.instance.isCardSelected()) {
				ImaginationHandUI.instance.unselectSelectedCard();
			}
			else if(ImaginationSkillsUI.instance.parent && ImaginationSkillsUI.instance.is_showing_details){
				ImaginationSkillsUI.instance.hideSkillDetails();
			}
			//if we are in a menu, let's go back, otherwise close it	
			else if(back_bt.visible){
				showMainMenu();
			}
			else if(!hide_close){
				onDoneClick();
			}
			else {
				//no can do
				SoundMaster.instance.playSound('CLICK_FAILURE');
			}
		}
		
		private function onBKey(event:Event = null):void {
			if(home.is_home) {
				onHomeClick();
			}
			else {
				onBackToWorldClick();
			}
		}
		
		private function onHKey(event:Event = null):void {
			if(!home.is_home) {
				onHomeClick();
			}
			else {
				onBackToWorldClick();
			}
		}
		
		override protected function onDoneClick(event:Event = null):void {
			hide();
		}
		
		override protected function onDoneTweenComplete():void {
			super.onDoneTweenComplete();
			
			//hide things
			hideElements();
			
			//show the minimap
			TSFrontController.instance.changeMiniMapVisibility();
			
			//show the current energy
			YouDisplayManager.instance.toggleEnergyText();
			
			if (function_to_call_after_hide_tween_is_complete != null) {
				function_to_call_after_hide_tween_is_complete();
				function_to_call_after_hide_tween_is_complete = null;
			}
		}
		
		private function onSkillsClick(event:Event = null):void {
			//we want to zoom the skills up to to the user
			SoundMaster.instance.playSound(skills.enabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(skills.enabled){
				toggleSkillsUI();
			}
		}
		
		private function toggleSkillsUI():void {
			hideElements();
			skills.zoom(true);
			draw();
		}
		
		private function onQuestsClick(event:Event = null):void {
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			//close the menu and open the dialog
			function_to_call_after_hide_tween_is_complete = TSFrontController.instance.toggleQuestsDialog;
			hide();
		}
		
		private function onHomeClick(event:Event = null):void {
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			//see if we are wanting to go home or back to the world
			function_to_call_after_hide_tween_is_complete = function():void {
				TSFrontController.instance.sendLocalChat(new NetOutgoingLocalChatVO(home.is_home ? '/leave' : '/home'));
			};
			hide();
		}
		
		private function onBackToWorldClick(event:Event = null):void {
			SoundMaster.instance.playSound(back_to_world.enabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(back_to_world.enabled){
				function_to_call_after_hide_tween_is_complete = function():void {
					TSFrontController.instance.sendLocalChat(new NetOutgoingLocalChatVO('/leave'));
				};
				hide();
			}
		}
		
		private function onUpgradeClick(event:Event = null):void {
			//if opening this without an event, force it open
			if(!ImaginationHandUI.instance.parent){
				SoundMaster.instance.playSound('CLICK_SUCCESS');
				
				//can't animate this at the moment. Flash renders it like shit even though it's all vector.
				hideElements();
				ImaginationHandUI.instance.show();
				TSFrontController.instance.getMainView().addView(ImaginationHandUI.instance, true);
				draw();
			}
			else {
				//hide the menu
				hide();
			}
		}
		
		private function onKeysClick(event:Event = null):void {
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			//show the keys dialog
			function_to_call_after_hide_tween_is_complete = ACLDialog.instance.start;
			hide();
		}

		private function onTeleportClick(event:Event = null):void {			
			//close the menu and open the dialog
			if(teleport.enabled){
				function_to_call_after_hide_tween_is_complete = function():void {
					RightSideManager.instance.setChatMapTab(MapChatArea.TAB_TELEPORT);
				};
				hide();
			}
			else {
				//the menu makes the click sound already, so only play failure if they can't
				SoundMaster.instance.playSound('CLICK_FAILURE');
			}
		}
		
		private function onYourLooksClick(event:Event = null):void {
			//show the outfits!
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			hideElements();
			ImaginationYourLooksUI.instance.show();
			draw();
		}
		
		private function showMainMenu(event:Event = null):void {
			hideElements(); //kills anything that's up
			showElements();
			SoundMaster.instance.playSound('CLICK_SUCCESS');
		}
		
		private function forceHide(anything:Object):void {
			//if this fired, we need to end things
			hide();
		}
		
		public function set cloud_to_open(cloud_type:String):void { _cloud_to_open = cloud_type; }
		public function set close_payload(anything:Object):void { _close_payload = anything; }
		
		/**********************
		 * IMoveListener Stuff
		 *********************/
		public function moveLocationHasChanged():void {}
		public function moveLocationAssetsAreReady():void {}
		
		public function moveMoveStarted():void {
			//close up shop if we are moving
			hide();
		}
		
		public function moveMoveEnded():void {}
	}
}