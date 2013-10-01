package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.giant.GiantFavor;
	import com.tinyspeck.engine.data.giant.Giants;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCSkill;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.net.NetOutgoingItemstackVerbVO;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.gameoverlay.ImgMenuView;
	import com.tinyspeck.engine.view.gameoverlay.ProgressBar;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Cloud;
	import com.tinyspeck.engine.view.ui.SkillIcon;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.favor.GiantFavorUI;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	public class ShrineDialog extends BigDialog implements IFocusableComponent {
		
		/* singleton boilerplate */
		public static const instance:ShrineDialog = new ShrineDialog();
		
		private const ICON_WH:uint = 66;
		private const SKILL_ICON_WH:uint = 60;
		private const DEFAULT_W:uint = 500;
		private const FAVOR_W:uint = 615;
		private const DEFAULT_HEAD_H:uint = 165;
		private const FAVOR_HEAD_H:uint = 53;
		private const DEFAULT_BODY_H:uint = 118;
		private const FAVOR_BODY_H:uint = 353;
		
		private var emblem_pb:ProgressBar;
		private var spend_bt:Button;
		private var back_bt:Button;
		private var favor_ui:GiantFavorUI = new GiantFavorUI();
		
		private var skill_icon_holder:Sprite = new Sprite();
		private var head_holder:Sprite = new Sprite();
		private var body_holder:Sprite = new Sprite();
		
		private var favor_icon:DisplayObject = new AssetManager.instance.assets.slug_favor_pos();
		
		private var intro_tf:TSLinkedTextField = new TSLinkedTextField();
		private var emblem_progress_tf:TextField = new TextField();
		private var emblem_aquire_tf:TextField = new TextField();
		private var learn_title_tf:TextField = new TextField();
		private var learn_tf:TSLinkedTextField = new TSLinkedTextField();
		private var learn_note_tf:TextField = new TextField();
		private var favor_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var emblem_item_class:String;
		
		private var _payload:Object;
		
		private var offset_x:int;
		
		private var is_built:Boolean;
		
		public function ShrineDialog() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_draggable = true;
			_w = DEFAULT_W;
			_head_min_h = DEFAULT_HEAD_H;
			_body_min_h = DEFAULT_BODY_H;
			_foot_min_h = 0;
			_base_padd = 20;
			offset_x = _base_padd + ICON_WH + 10;
			_title_padd_left = offset_x;
			
			_construct();
		}
		
		private function buildBase():void {
			const cssm:CSSManager = CSSManager.instance;
			
			//emblem progress bar
			emblem_pb = new ProgressBar(_w - _base_padd - offset_x, 30);
			emblem_pb.x = offset_x;
			emblem_pb.dim_speed = .5;
			emblem_pb.setBarColors(cssm.getUintColorValueFromStyle('shrine_progress_bar', 'topColor'),
				cssm.getUintColorValueFromStyle('shrine_progress_bar', 'bottomColor'),
				cssm.getUintColorValueFromStyle('shrine_progress_bar', 'tipTopColor'),
				cssm.getUintColorValueFromStyle('shrine_progress_bar', 'tipBottomColor'));
			emblem_pb.setFrameColors(cssm.getUintColorValueFromStyle('shrine_progress_bar', 'backgroundColor'),
				cssm.getUintColorValueFromStyle('shrine_progress_bar', 'shadowColor'));
			
			head_holder.addChild(emblem_pb);
			
			//favor icon
			favor_icon.x = 10;
			favor_icon.y = int(emblem_pb.height/2 - favor_icon.height/2);
			emblem_pb.addChild(favor_icon);
			
			//intro tf
			TFUtil.prepTF(intro_tf);
			intro_tf.autoSize = TextFieldAutoSize.NONE;
			intro_tf.width = int(emblem_pb.width);
			head_holder.addChild(intro_tf);
			
			//emblem tf
			TFUtil.prepTF(emblem_progress_tf, false);
			emblem_progress_tf.x = favor_icon.width + 16;
			emblem_progress_tf.filters = StaticFilters.white1px90DegreesShrineDialog_DropShadowA;
			emblem_pb.addChild(emblem_progress_tf);
			
			//emblem aquire
			TFUtil.prepTF(emblem_aquire_tf, false);
			emblem_aquire_tf.htmlText = '<p class="shrine_emblem_status">Emblem!</p>';
			emblem_aquire_tf.x = emblem_pb.width - emblem_aquire_tf.width - 12;
			emblem_aquire_tf.y = int(emblem_pb.height/2 - emblem_aquire_tf.height/2);
			emblem_aquire_tf.filters = StaticFilters.white1px90DegreesShrineDialog_DropShadowA;
			emblem_pb.addChild(emblem_aquire_tf);
			
			//check favor
			TFUtil.prepTF(favor_tf, false);
			favor_tf.x = offset_x;
			favor_tf.htmlText = '<p class="shrine_link"><a class="shrine_link" href="event:view_favor">View your favor with all the Giants</a></p>';
			head_holder.addChild(favor_tf);
			
			//nudge down the list
			favor_ui.x = 10;
			favor_ui.y = 5;
			
			_head_sp.addChild(head_holder);
			
			//learn tf
			TFUtil.prepTF(learn_title_tf, false);
			learn_title_tf.x = offset_x;
			learn_title_tf.y = _base_padd - 6;
			learn_title_tf.htmlText = '<p class="shrine_learn_title">Learn Faster?</p>';
			
			TFUtil.prepTF(learn_tf);
			learn_tf.x = offset_x;
			learn_tf.y = learn_title_tf.y + learn_title_tf.height - 3;
			learn_tf.width = emblem_pb.width;
			
			TFUtil.prepTF(learn_note_tf);
			learn_note_tf.x = offset_x;
			
			body_holder.addChild(learn_title_tf);
			body_holder.addChild(learn_tf);
			body_holder.addChild(learn_note_tf);
			
			//skill icon
			skill_icon_holder.x = _base_padd;
			skill_icon_holder.y = _base_padd - 3;
			body_holder.addChild(skill_icon_holder);
			
			//spend button
			spend_bt = new Button({
				name: 'spend',
				size: Button.SIZE_TINY,
				type: Button.TYPE_DEFAULT
			});
			spend_bt.h = CSSManager.instance.getNumberValueFromStyle('button_'+spend_bt.size+'_double', 'height');
			body_holder.addChild(spend_bt);
			
			_scroller.body.addChild(body_holder);
			
			//back button
			const back_DO:DisplayObject = new AssetManager.instance.assets.back_circle();
			back_bt = new Button({
				label: '',
				name: 'back',
				graphic: back_DO,
				graphic_hover: new AssetManager.instance.assets.back_circle_hover(),
				graphic_disabled: new AssetManager.instance.assets.back_circle_disabled(),
				w: back_DO.width,
				h: back_DO.height,
				draw_alpha: 0
			});
			back_bt.x = -back_DO.width/2 + 1;
			back_bt.y = 12;
			back_bt.addEventListener(TSEvent.CHANGED, onBackClick, false, 0, true);
			
			is_built = true;
		}
		
		override public function start():void {
			if(!is_built) buildBase();
			
			// item classes are misnamed ti instead of tii
			var item_giant_name:String = (_payload.giant_name == 'tii') ? 'ti' : _payload.giant_name;
			emblem_item_class = 'emblem_'+item_giant_name;
			
			if (!model.worldModel.items[emblem_item_class]) {
				BootError.addErrorMsg('unknown giant: '+item_giant_name);
				return;
			}
			
			if (parent){
				update();
				return;
			} 
			
			if(!canStart(true)) return;
			
			//set the title and description			
			_setTitle(giant_name);
			_setGraphicContents(new ItemIconView(emblem_item_class, ICON_WH));
			
			//check if they are learning something already
			update(true);
			
			//handle the favor data
			if(back_bt.parent) back_bt.parent.removeChild(back_bt);
			if(favor_ui.parent) favor_ui.parent.removeChild(favor_ui);
			
			//listeners			
			spend_bt.addEventListener(MouseEvent.CLICK, onSpendClick, false, 0, true);
			intro_tf.addEventListener(TextEvent.LINK, onTFClick, false, 0, true);
			learn_tf.addEventListener(TextEvent.LINK, onTFClick, false, 0, true);
			favor_tf.addEventListener(TextEvent.LINK, onTFClick, false, 0, true);
			
			model.worldModel.registerCBProp(onPCStatChange, "pc", "stats");
			model.worldModel.registerCBProp(onSkillChange, "pc", "skill_training");
			
			//force it to start in the center
			last_x = last_y = 0;
			super.start();
		}
				
		override public function end(release:Boolean):void {
			spend_bt.removeEventListener(MouseEvent.CLICK, onSpendClick);
			intro_tf.removeEventListener(TextEvent.LINK, onTFClick);
			learn_tf.removeEventListener(TextEvent.LINK, onTFClick);
			favor_tf.removeEventListener(TextEvent.LINK, onTFClick);
			
			model.worldModel.unRegisterCBProp(onPCStatChange, "pc", "stats");
			model.worldModel.unRegisterCBProp(onSkillChange, "pc", "skill_training");
			
			emblem_pb.stopTweening();
				
			super.end(release);
		}
		
		public function spend():void {
			//the GS has told us we have spent the points						
			spend_bt.disabled = true;
			learn_tf.htmlText = '<p class="shrine_current">You\'ve done it! You spent that favor!</p>';
		}
		
		public function maybeEnableSpendButton():void {
			if (favor_points > 0 && is_learning && spend_points > 0) {
				spend_bt.disabled = false;
			} else {
				spend_bt.disabled = true;
			}
		}
		
		private function update(is_forced:Boolean = false):void {
			if(!parent && !is_forced) return;
			
			var pc:PC = model.worldModel.pc;
			var url:String;
			var learn_txt:String = '<p class="shrine_current">';
			var sex:String = "he'd";
			var sex_will:String = "he'll";
			
			if(Giants.getSex(giant_name) == Giants.SEX_FEMALE){
				sex = "she'd";
				sex_will = "she'll";
			}
			else if(Giants.getSex(giant_name) == Giants.SEX_NONE){
				sex = "they'd";
				sex_will = "they'll";
			}
			
			intro_tf.htmlText = '<p class="shrine_intro"><b>'+giant_name+'</b> loves you. '+
				'But '+sex+' love you more if you <a class="shrine_link" href="event:donate">donate</a>. '+
				'Gain '+(emblem_cost-favor_points > 0 ? emblem_cost-favor_points : 0)+' more favor points with '+giant_name+' and you\'ll earn a valuable '+
				'<a href="event:'+TSLinkedTextField.LINK_ITEM+'|'+'emblem_'+(_payload.giant_name != 'tii' ? _payload.giant_name : 'ti')+'">'+
				'<b>Emblem of '+giant_name+'</b></a>.</p>';
			intro_tf.height = intro_tf.textHeight + 6;
			
			//set the favor progress
			if(favor_points >= emblem_cost){
				emblem_pb.update(1);
				emblem_pb.startTweening();
			}
			else {
				emblem_pb.update(emblem_perc);
				emblem_pb.stopTweening();
			}
			
			emblem_progress_tf.htmlText = '<p class="shrine_emblem_status">'+favor_points+'/'+emblem_cost+' favor points with '+giant_name+'</p>';
			emblem_progress_tf.y = int(emblem_pb.height/2 - emblem_progress_tf.height/2);
			
			//set button
			if(spend_points > 0){
				spend_bt.label = 'Spend '+spend_points+' favor points';
			}
			else {
				spend_bt.label = 'You can\'t spend points right now';
			}
			
			//skill img if we need to
			if(is_learning && skill_icon_holder.name != pc.skill_training.tsid) loadSkillGraphic(pc.skill_training.tsid);
			
			//normal learning spend
			if(is_learning && spend_points > 0 && favor_points > 0){
				var giant_type:String = 'is the best giant for learning this skill!';
				if(giant_rel == 's') giant_type = 'is the secondary giant for learning this skill.';
				if(giant_rel == 'u') giant_type = 'is not associated with this skill, but '+sex_will+' help you learn it anyway.';
				
				learn_txt += 'Spend your '+spend_points+' favor points with <b>'+giant_name+'</b> to speed up learning '+
						 	 '<b>'+pc.skill_training.name+'</b> by <b>'+StringUtil.formatTime(speed_up)+'.</b>';
				
				learn_note_tf.htmlText = '<p class="shrine_learn_note"><b>Note!</b> '+giant_name+' '+giant_type+'</p>';
				
				skill_icon_holder.name = pc.skill_training.tsid;
			}
			//already accelerated
			else if(is_learning && spend_points == 0 && favor_points > 0){
				learn_txt += 'You\'re already learning as fast as you can!';
				learn_note_tf.htmlText = '';
				
				skill_icon_holder.name = pc.skill_training.tsid;
			}
			//not learning
			else if(!is_learning){
				learn_txt += 'If you were <a class="shrine_link" href="event:learn">learning</a> a new skill, you could '+
							 'use your favor points to learn it faster.';
				learn_note_tf.htmlText = '';
				
				skill_icon_holder.name = 'none';
				loadSkillGraphic('none');
			}
			//learning but has no favor
			else if(is_learning && favor_points == 0){
				learn_txt += 'No favor points?! Did you know that the giants will help you learn faster than normal if you <a class="shrine_link" href="event:donate">donate</a> to their shrines?';
				learn_note_tf.htmlText = '';
			}
			
			learn_tf.htmlText = learn_txt + '</p>';
			
			maybeEnableSpendButton();
			
			_jigger();
		}
		
		private function showFavor():void {
			//show the favor progress bars
			favor_ui.show(_payload.favor);
			_scroller.body.addChild(favor_ui);
			
			//change up the title
			_setTitle('Giant Favor');
			
			addChild(back_bt);
			
			//reset the position so that it shows up in the middle of the screen
			last_x = last_y = 0;
			invalidate(true);
		}
		
		private function onSkillChange(skill_training:PCSkill):void {
			ShrineManager.instance.reload();
		}
		
		private function onPCStatChange(stats:PCStats):void {
			const favor:GiantFavor = stats.favor_points.getFavorByName(_payload.giant_name);
			if(favor.current != favor_points){
				//out of sync, reload
				ShrineManager.instance.reload();
			}
		}
		
		override public function blur():void {
			if (spend_bt) spend_bt.disabled = true;
			super.blur();
		}
		
		override public function focus():void {
			maybeEnableSpendButton();
			super.focus();
		}
		
		override protected function enterKeyHandler(e:KeyboardEvent):void {
			confirmSpend();
		}
		
		private function onSpendClick(event:MouseEvent):void {
			confirmSpend();
		}
		
		private function confirmSpend():void {
			StageBeacon.stage.focus = StageBeacon.stage;
			if(spend_bt.disabled) return;
			
			var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
			cdVO.txt = 'Are you sure you want to spend those favor points?';
			cdVO.choices = [
				{value: false, label: 'No, Cancel!'},
				{value: true, label: 'Yes, Spend!'}
			];
			cdVO.escape_value = false;
			cdVO.item_class = emblem_item_class;
			cdVO.callback =	function(value:*):void {
				if (value === true) {
					spend_bt.disabled = true;
					//send the request to spend off to the server
					ShrineManager.instance.spend();
				}
			}
			
			TSFrontController.instance.confirm(cdVO);
		}
		
		private function onDonateClick(event:TextEvent):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			end(true);
			
			//tell the server we want to donate
			TSFrontController.instance.sendItemstackVerb(
				new NetOutgoingItemstackVerbVO(ShrineManager.instance.shrine_tsid, ShrineManager.instance.donate_verb, 1)
			);
		}
		
		private function onTFClick(event:TextEvent):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			switch(event.text){
				case 'learn':
					ImgMenuView.instance.cloud_to_open = Cloud.TYPE_SKILLS;
					ImgMenuView.instance.show();
					break;
				case 'donate':
					onDonateClick(event);
					break;
				case 'view_favor':
					showFavor();
					break;
			}
		}
		
		private function onBackClick(event:TSEvent):void {
			back_bt.parent.removeChild(back_bt);
			favor_ui.hide();
			
			//reset the title
			_setTitle(giant_name);
			
			//reset the position so that it shows up in the middle of the screen
			last_x = last_y = 0;
			invalidate(true);
		}
		
		private function loadSkillGraphic(tsid:String):void {
			SpriteUtil.clean(skill_icon_holder);
			skill_icon_holder.name = tsid;
			
			var skill_icon:SkillIcon = new SkillIcon(tsid, SkillIcon.SIZE_100);
			skill_icon.width = skill_icon.height = SKILL_ICON_WH;
			skill_icon_holder.addChild(skill_icon);
		}
		
		override protected function _jigger():void {
			const showing_favor:Boolean = favor_ui.parent != null;
			
			//setup some drawing vars
			_w = !showing_favor ? DEFAULT_W : FAVOR_W;
			_title_padd_left = !showing_favor ? offset_x : _base_padd;
			_head_min_h = !showing_favor ? DEFAULT_HEAD_H : FAVOR_HEAD_H;
			_body_min_h = !showing_favor ? DEFAULT_BODY_H : FAVOR_BODY_H;
			_head_graphic.visible = !showing_favor;
			_body_border_c = !showing_favor ? 0xd2d2d2 : 0xffffff;
			_body_fill_c = !showing_favor ? 0xececec : 0xffffff;
			
			super._jigger();
			
			//place the title where it needs to go
			if(!showing_favor){
				_title_tf.y = _base_padd - 4;
			}
			
			//hide elements if we need to
			head_holder.visible = !showing_favor;
			body_holder.visible = !showing_favor;
			
			_head_graphic.x = _base_padd;
			_head_graphic.y = _base_padd;
			
			intro_tf.x = int(_title_tf.x);
			intro_tf.y = int(_title_tf.y + _title_tf.height) + 2;
			
			emblem_pb.y = int(intro_tf.y + intro_tf.height) + 10;
			favor_tf.y = int(emblem_pb.y + emblem_pb.height) + 3;
			
			spend_bt.x = int(_w - spend_bt.width - _base_padd);
			spend_bt.y = int(learn_tf.y + learn_tf.height) + _base_padd/2 - 2;
			
			learn_note_tf.y = spend_bt.y;
			learn_note_tf.width = int(spend_bt.x - offset_x - _base_padd);
			
			_head_h = !showing_favor ? Math.max(_head_min_h, emblem_pb.y + emblem_pb.height + _base_padd) : _head_min_h;
			
			_body_sp.y = _head_h;
			_body_h = !showing_favor ? _scroller.body_h + _base_padd + 13 : _body_min_h;
			
			_scroller.h = _body_h;
			_scroller.w = _w;
						
			_h = _head_h + _body_h + _foot_h;
			
			_draw();
			
			_scroller.refreshAfterBodySizeChange();
		}
		
		public function set payload(object:Object):void {
			_payload = object;
			if (_payload.giant_name == 'ti') _payload.giant_name = 'tii';
		}
		
		private function get spend_points():uint { return _payload.spend_points; }
		private function get favor_points():uint { return _payload.favor_points; }
		private function set favor_points(value:uint):void { _payload.favor_points = value; }
		private function get emblem_perc():Number { return _payload.favor_points / _payload.emblem_cost; }
		private function get emblem_cost():uint { return _payload.emblem_cost; }
		private function get giant_name():String { return Giants.getLabel(_payload.giant_name); }
		private function get speed_up():uint { return _payload.speed_up; }
		private function get giant_rel():String { return _payload.giant_rel; }
		private function get is_learning():Boolean { return _payload.is_learning; }
	}
}