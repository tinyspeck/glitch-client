package com.tinyspeck.engine.port {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.skill.SkillDetails;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.net.NetOutgoingSkillsCanLearnVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.AchievementView;
	import com.tinyspeck.engine.view.gameoverlay.ChoicesDialog;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Dialog;
	import com.tinyspeck.engine.view.ui.SkillIcon;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.text.TextField;

	public class FamiliarDialog extends Dialog {
		
		/* singleton boilerplate */
		public static const instance:FamiliarDialog = new FamiliarDialog();
		
		public static const DEFAULT:String = 'DEFAULT';
		public static const SKILL_LEARNED:String = 'SKILL_LEARNED';
		public static const CONVERSATION:String = 'CONVERSATION';
		
		private const MIN_HEIGHT:uint = 220;
		private const WIDTH_WITH_SKILLS:uint = 410;
		private const X_OFFSET:uint = 140;
		
		public var current_panel_name:String;
		
		private var current_panel:Sprite;
		private var learned_panel:Sprite = new Sprite();
		private var learned_png_holder:Sprite = new Sprite();
		private var conv_panel:Sprite = new Sprite();
		private var default_panel:Sprite = new Sprite();
		private var skills_holder:Sprite = new Sprite();
		
		private var learned_header_tf:TextField = new TextField();
		private var learned_title_tf:TextField = new TextField();
		private var learned_desc_tf:TextField = new TextField();
		private var learned_skills_tf:TextField = new TextField();
		private var skills_tf:TextField = new TextField();
		
		private var skill_buttons:Vector.<Button> = new Vector.<Button>();
		private var learn_new_bt:Button;
		private var teleportation_dialog:TeleportationDialog;
		
		private var learned_skill:Object;
		private var header_pt:Point;
		
		private var bt_spacing_x:int = 5;
		private var bt_h:uint;
		private var current_skill_cols:uint = 2;
		
		private var show_next_skills:Boolean = true;
		
		public function FamiliarDialog() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_close_bt_padd_right = 8;
			_close_bt_padd_top = 8;
			_base_padd = 20;
			_w = 360;
			_h = MIN_HEIGHT;
			bg_c = 0x0a181d;
			bg_alpha = .9;
			no_border = true;
			_border_w = 0;
			close_on_editing = false;
			close_on_move = false;
			_construct();
		}
		
		override protected function _construct() : void {
			super._construct();
			buildLearnedPanel();
			teleportation_dialog = TeleportationDialog.instance;
			
			//get a list of available skills the player can learn
			//listen for player things
			AchievementView.instance.addEventListener(TSEvent.COMPLETE, getAvailableSkills, false, 0, true);
			model.worldModel.registerCBProp(getAvailableSkills, "pc", "skill_training_complete");
			
			_w = WIDTH_WITH_SKILLS;
		}
		
		override protected function makeCloseBt():Button {
			return new Button({
				graphic: new AssetManager.instance.assets['close_x_small_gray'](),
				name: '_close_bt',
				c: bg_c,
				high_c: bg_c,
				disabled_c: bg_c,
				shad_c: bg_c,
				inner_shad_c: 0xcccccc,
				h: 22,
				w: 22,
				disabled_graphic_alpha: .3,
				focus_shadow_distance: 1,
				graphic_padd_t: 0
			});
		}
		
		public function get default_panel_visible():Boolean {
			if (!default_panel) return false;
			return default_panel.visible;
		}
		
		public function get skills_holder_visible():Boolean {
			if (!skills_holder) return false;
			return skills_holder.visible;
		}
		
		private function buildLearnedPanel():void {
			learned_panel.addChild(learned_png_holder);
			learned_png_holder.x = _base_padd;
			learned_png_holder.y = _base_padd;
			
			TFUtil.prepTF(learned_header_tf, false);
			learned_header_tf.x = X_OFFSET;
			learned_header_tf.y = _base_padd;
			learned_header_tf.htmlText = '<p class="familiar_learned_header">Woohoo! New skill learned...</p>';
			learned_panel.addChild(learned_header_tf);
			
			TFUtil.prepTF(learned_title_tf);
			learned_title_tf.x = X_OFFSET;
			learned_title_tf.y = learned_header_tf.y+learned_header_tf.height;
			learned_title_tf.width = 330;
			learned_panel.addChild(learned_title_tf);
			
			TFUtil.prepTF(learned_desc_tf);
			learned_desc_tf.x = X_OFFSET;
			learned_desc_tf.width = 330;
			learned_panel.addChild(learned_desc_tf);
			
			TFUtil.prepTF(learned_skills_tf, false);
			learned_panel.addChild(learned_skills_tf);
			
			learned_skills_tf.htmlText = '<p class="familiar_learn_something">Choose a Skill to Learn Next</p>';
			skills_tf.filters = StaticFilters.black1px270Degrees_DropShadowA;
			
			learn_new_bt = new Button({
				label: '<u>View Full Skill Tree</u> <font color="#6d7f7f">(opens in new window)</font>',
				label_c: 0x5c96a3,
				name: 'learn_bt',
				draw_alpha: 0
			});
			learn_new_bt.addEventListener(MouseEvent.CLICK, openSkillsPage, false, 0, true);
			
			learned_panel.addChild(learn_new_bt);
		}
		
		private function buildLearnedSkill():void {
			
			if (model.stateModel.fam_dialog_skill_payload_q.length) {
				learned_skill = model.stateModel.fam_dialog_skill_payload_q.shift();
				//http://dev.glitch.com/img/skills-100/alchemy_1.png
				
				if (learned_skill.sound) {
					SoundMaster.instance.playSound(learned_skill.sound);
				}
				
				if (learned_png_holder.numChildren > 0 && learned_png_holder.getChildAt(0).name == learned_skill.tsid) {
					// we are already showing the correct graphic
				} else {
					while (learned_png_holder.numChildren) learned_png_holder.removeChildAt(0);
					loadSkillGraphic(learned_skill.tsid);
					
					learned_title_tf.htmlText = '<p class="familiar_learned_title">'+learned_skill.name+'</p>';
					
					learned_desc_tf.htmlText = '<p class="familiar_learned_desc">'+learned_skill.learned+'</p>';
					learned_desc_tf.y = int(learned_title_tf.y+learned_title_tf.height);
				}
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.error('model.stateModel.fam_dialog_skill_payload_queue.length '+model.stateModel.fam_dialog_skill_payload_q.length);
				}
			}
		}	
		
		private function loadSkillGraphic(tsid:String):void {
			var url:String = SkillIcon.makeIconUrl(tsid, SkillIcon.SIZE_100)
			CONFIG::debugging {
				Console.log(66, url);
			}
			AssetManager.instance.loadBitmapFromWeb(url, bmLoaded, 'SkillIcon');
		}
		
		private function bmLoaded(filename:String, bm:Bitmap):void {
			if (!bm) {
				CONFIG::debugging {
					Console.warn('Failed to load skill graphic from ' + filename);
				}
				BootError.addErrorMsg('# Failed to load graphic graphic from --> ' + filename, null, ['loader']);
			} else {
				var learned_png:DisplayObject = bm;
				if(learned_png) learned_png_holder.addChild(learned_png);
			}
		}
		
		private function openSkillsPage(e:Event):void {
			TSFrontController.instance.openSkillsPage();
			closeFromUserInput(e);
		}
		
		override protected function closeFromUserInput(e:Event=null):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			if (e is MouseEvent) focus();
			if (_close_bt.disabled) return;
			if (!has_focus) return;
			
			TSFrontController.instance.endFamiliarDialog();
		}
		
		// will never get called unless close_on_move is set to true
		override protected function forcedToEndDueToMoving():void {
			TSFrontController.instance.endFamiliarDialog();
			super.forcedToEndDueToMoving();
		}
		
		// will never get called unless close_on_editing is set to true
		override protected function forcedToEndDueToEditing():void {
			TSFrontController.instance.endFamiliarDialog();
			super.forcedToEndDueToEditing();
		}
		
		override public function end(release:Boolean):void {
			if (release && !transitioning) {
				header_pt = YouDisplayManager.instance.getHeaderCenterPt();
				
				transitioning = true;
				var self:FamiliarDialog = this;
				TSTweener.removeTweens(self);
				TSTweener.addTween(self, {y:header_pt.y, x:header_pt.x, scaleX:.02, scaleY:.02, time:.3, transition:'easeOutCubic', onComplete:function():void{
					self.end(true);
					self.scaleX = self.scaleY = 1;
					self.transitioning = false;
				}});
			} else {
				super.end(release);
			}
		}
		
		public function startWithPanel(panel_name:String):void {
			current_panel_name = panel_name;
			start();
		}
		
		public function addChoicesDialog(cd:ChoicesDialog):void {
			if (cd.parent != conv_panel) conv_panel.addChild(cd);
			reDrawDuringConversation();
		}
		
		override public function start():void {						
			if (current_panel && current_panel.parent) current_panel.parent.removeChild(current_panel);
			
			_close_bt.disabled = false;
			_close_bt.visible = true;
			show_next_skills = true;
			
			if (current_panel_name == DEFAULT) {
				current_panel = default_panel;
				//default panel is just the teleportation stuff for now
				const pc:PC = model.worldModel.pc;
				if(pc.teleportation && pc.teleportation.skill_level > 0){
					teleportation_dialog.visible = true;
					default_panel.visible = false;
				}
				else {
					//nothing for them here
					end(true);
					model.activityModel.activity_message = Activity.createFromCurrentPlayer(
						'You need to learn <a href="event:'+TSLinkedTextField.LINK_SKILL+'|teleportation_1">Teleportation</a> first!'
					);
					SoundMaster.instance.playSound('CLICK_FAILURE');
					return;
				}
			} else if (current_panel_name == CONVERSATION) {
				current_panel = conv_panel;
				_close_bt.disabled = true;
				_close_bt.visible = false;
				_draw();
			} else if (current_panel_name == SKILL_LEARNED) {
				current_panel = learned_panel;
				buildLearnedSkill();
				_draw();
			} else { // bail, because we don't know what panel to use
				CONFIG::debugging {
					Console.error('HOW THE FUCK CAN THIS HAPPEN current_panel_name:'+current_panel_name);
				}
				current_panel_name = null;
				return;
			}
			
			addChild(current_panel);
			
			//can we open this?
			if(!canStart(current_panel_name != CONVERSATION)) return;

			_w = Math.max(model.layoutModel.familiar_dialog_min_w, current_panel.width);
			_h = Math.max(MIN_HEIGHT, current_panel.height);
			
			// invalidate(true) is implied by super.start();
			super.start();
			
			transitioning = true;
			scaleX = scaleY = .02;
			header_pt = YouDisplayManager.instance.getHeaderCenterPt();
			x = header_pt.x;
			y = header_pt.y;
			
			var self:FamiliarDialog = this;
			TSTweener.removeTweens(self);
			TSTweener.addTween(self, {y:dest_y, x:dest_x, scaleX:1, scaleY:1, time:.3, transition:'easeInCubic', onComplete:function():void{
				self.transitioning = false;
				self._place();
			}});

			addChild(_close_bt); // make sure it stays on top
			
			//make sure the teleportation stuff is up to date
			TeleportationDialog.instance.onTeleportationChange();
			
			_jigger();
		}
		
		private function onSkillsCanLearn(nrm:NetResponseMessageVO):void {
			//display the list of available skills
			const MAX_LABEL_LENGTH:uint = 15;
			const BT_WIDTH:uint = 130;
			const BREAK_COUNT:uint = 8; //how many skills before it goes to 3 columns
			
			if(nrm.success && nrm.payload.skills){
				var bt:Button;
				var next_x:uint;
				var next_y:uint;
				var k:String;
				var i:int;
				var skill:SkillDetails;
				var largest_left_button:int;
				var visible_skills:int;
				
				//reset em
				for(i = 0; i < skill_buttons.length; i++){
					bt = skill_buttons[int(i)];
					bt.x = bt.y = 0;
					bt.visible = false;
				}
				
				//count em
				current_skill_cols = model.worldModel.learnable_skills.length > BREAK_COUNT ? 3 : 2;
				
				//show em
				for(i = 0; i < model.worldModel.learnable_skills.length; i++){
					skill = model.worldModel.learnable_skills[int(i)];
					if(!skill.can_learn){
						//we are done here
						visible_skills = i;
						break;
					}
					
					if(skill_buttons.length > i){
						bt = skill_buttons[int(i)];
					}
					else {
						bt = new Button({
							name: 'bt_'+i,
							label_bold: true,
							label_c: 0xffffff,
							label_hover_c: 0xd79035,
							label_size: 11,
							label_offset: 1,
							graphic_placement: 'left',
							draw_alpha: 0
						});
						bt.addEventListener(TSEvent.CHANGED, onSkillClick, false, 0, true);
						skill_buttons.push(bt);
						skills_holder.addChild(bt);
					}
					
					bt.visible = true;
					bt.value = skill.class_tsid;
					bt.setGraphic(new SkillIcon(skill.class_tsid, 20));
					bt.label = StringUtil.truncate(skill.name, current_skill_cols == 3 ? MAX_LABEL_LENGTH : 100);
					
					if(current_skill_cols == 2 && i % current_skill_cols == 0 && bt.width > largest_left_button){
						largest_left_button = bt.width + 10;
					}
					
					//throw a tooltip up if it's going to be trunced
					bt.tip = bt.label_tf.text.indexOf('...') != -1 ? {txt: skill.name} : null;
					bt.y = next_y;
					if(i % current_skill_cols == current_skill_cols-1){
						next_y += bt.height;
					}
				}
				
				//shove the right buttons over
				for(i = 0; i < visible_skills; i++){
					bt = skills_holder.getChildAt(i) as Button;
					if(bt.visible){
						bt.x = (i % current_skill_cols) * (current_skill_cols == 3 ? BT_WIDTH : largest_left_button);
					}
				}
				
				_jigger();
			}
			else {
				CONFIG::debugging {
					Console.warn('There was an error with the skills stuff!');
				}
			}
		}
				
		private function onSkillClick(event:TSEvent):void {
			var bt:Button = event.data as Button;
			if(!bt) return;
			
			//open up the skill dialog
			TSFrontController.instance.showSkillInfo(bt.value);
		}
		
		override protected function _draw():void {
			
			var g:Graphics
			
			if (current_panel_name == CONVERSATION) {
				g = conv_panel.graphics;
				g.clear();
				
				if(conv_panel.numChildren > 0 && conv_panel.getChildAt(0) is ChoicesDialog){
					//draw a line under the graphic
					const cd:ChoicesDialog = conv_panel.getChildAt(0) as ChoicesDialog;
					
					if (cd.choices && !cd.choices.graphic_on_left) {
						
						const offset:int = cd.graphic_holder.y + cd.graphic_holder.height + 8;
						const draw_w:int = conv_panel.width;
						
						g.beginFill(0x49514f, (cd.graphic_holder.height > 0 ? 1 : 0));
						g.drawRect(0, offset, draw_w, 1);
						
						_w = draw_w;
						
						//put the close button where it needs to go
						cd.close_button.x = int(_w - cd.close_button.width - _close_bt_padd_right);
						cd.close_button.y = _close_bt_padd_top;
						
					}
				}
			} else if (current_panel_name == SKILL_LEARNED) {
				g = learned_panel.graphics;
				g.clear();
				g.beginFill(0xffffff, 0);
				g.drawRect(0, 0, learned_desc_tf.x+learned_desc_tf.width+(_base_padd*2), learned_panel.height+(_base_padd*2));
				g.endFill();

				//draw broken lines
				const learned_line_y:int = learned_skills_tf.y + learned_skills_tf.height/2;
				
				g.lineStyle(0, 0x49514f);
				g.moveTo(0, learned_line_y);
				g.lineTo(learned_skills_tf.x - 10, learned_line_y);
				g.moveTo(learned_skills_tf.x + learned_skills_tf.width + 10, learned_line_y);
				g.lineTo(_w, learned_line_y);
			}
			
			//set the corner curve amount
			window_border.corner_rad = 10;
			
			super._draw();
		}
		
		override protected function _place():void {
			dest_x = Math.round((model.layoutModel.loc_vp_w-_w)/2) + model.layoutModel.gutter_w;
			dest_x = Math.max(dest_x, 0);
			dest_y = YouDisplayManager.instance.getHeaderCenterPt().y + 30;
			
			if (!transitioning) {
				x = dest_x;
				y = dest_y;
			}
		}
		
		private function reDrawDuringConversation():void {
			_w = Math.max(model.layoutModel.familiar_dialog_min_w, current_panel.width);
			_h = Math.max(30, current_panel.height);
			invalidate(true);
		}
		
		override protected function _jigger():void {
			var i:int;
			var tf:TSLinkedTextField;
			var tf_offset:int;
			var next_x:int = _base_padd;
			
			//hide the skills by default
			skills_holder.visible = false;
			for(i = 0; i < current_skill_cols; i++){
				tf = getChildByName('skill_'+i) as TSLinkedTextField;
				if(tf) tf.visible = false;
			}
			
			if (current_panel_name == DEFAULT) {
				//with the new width, move things around
				skills_tf.x = int(_w/2 - skills_tf.width/2);
			} else if (current_panel_name == CONVERSATION) {
				
				//
				
			} else if (current_panel_name == SKILL_LEARNED) {
				skills_holder.visible = show_next_skills;
				//place the skills where they are supposed to go
				next_x = X_OFFSET;
				learned_skills_tf.x = int(_w/2 - learned_skills_tf.width/2) + X_OFFSET;
				learned_skills_tf.y = learned_desc_tf.y + learned_desc_tf.height + 10;
				
				learned_panel.addChild(skills_holder);
				skills_holder.x = int(_w/2 - skills_holder.width/2);
				skills_holder.y = int(learned_skills_tf.y + learned_skills_tf.height + 10);
				learn_new_bt.x = int(_w/2 - learn_new_bt.width/2);
				tf_offset = skills_holder.y + skills_holder.height + 15;
				learned_skills_tf.x = int(_w/2 - learned_skills_tf.width/2);
				
				learn_new_bt.y = tf_offset ? tf_offset : learned_desc_tf.y+learned_desc_tf.height+_base_padd;
				
				_h = int(learn_new_bt.y + learn_new_bt.height + 5);
			}
			
			super._jigger();
			_draw();
		}
		
		private function getAvailableSkills(whatever:* = null):void {
			//dump out the current data
			var i:int;
			var bt:Button;
			
			//hide the buttons first
			for(i = 0; i < skills_holder.numChildren; i++){
				bt = skills_holder.getChildAt(i) as Button;
				bt.visible = false;
				bt.removeGraphic();
				bt.x = bt.y = 0;
			}
			
			//go ask the server nicely
			TSFrontController.instance.genericSend(new NetOutgoingSkillsCanLearnVO(), onSkillsCanLearn, onSkillsCanLearn);
		}
	}
}