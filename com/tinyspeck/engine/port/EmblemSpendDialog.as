package com.tinyspeck.engine.port
{
	import com.tinyspeck.engine.data.Emblem;
	import com.tinyspeck.engine.data.giant.Giants;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.pc.PCSkill;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.SkillIcon;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;

	public class EmblemSpendDialog extends BigDialog implements IPackChange
	{
		/* singleton boilerplate */
		public static const instance:EmblemSpendDialog = new EmblemSpendDialog();
		
		private const OFFSET_X:uint = 100;
		private const TIP_WIDTH:uint = 240;
		private const EMBLEM_WH:uint = 60;
		
		private var body_tf:TSLinkedTextField = new TSLinkedTextField();
		private var tip_tf:TSLinkedTextField = new TSLinkedTextField();
		private var yes_bt:Button;
		private var no_bt:Button;
		private var emblem_icon:ItemIconView;
		private var skill_icon:SkillIcon;
		
		private var icon_holder:Sprite = new Sprite();
		private var arrow:DisplayObject;
		
		private var is_built:Boolean;
		
		public function EmblemSpendDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_body_border_c = 0xffffff;
			_body_fill_c = 0xffffff;
			_close_bt_padd_right = 10;
			_close_bt_padd_top = 10;
			_base_padd = 20;
			_head_min_h = 35;
			_body_min_h = 100;
			_foot_min_h = 0;
			_w = 498;
			_title_padd_left = OFFSET_X;
			
			_construct();
		}
		
		private function buildBase():void {
			//body text
			TFUtil.prepTF(body_tf);
			body_tf.embedFonts = false;
			body_tf.width = _w - OFFSET_X - _base_padd*2;
			body_tf.x = OFFSET_X;
			_scroller.body.addChild(body_tf);
			
			//tip text
			TFUtil.prepTF(tip_tf);
			tip_tf.embedFonts = false;
			tip_tf.width = TIP_WIDTH;
			tip_tf.x = OFFSET_X;
			_scroller.body.addChild(tip_tf);
			
			//buttons
			yes_bt = new Button({
				name: 'yes',
				label: 'Yes',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			yes_bt.addEventListener(TSEvent.CHANGED, onYesClick, false, 0, true);
			_scroller.body.addChild(yes_bt);
			
			no_bt = new Button({
				name: 'no',
				label: 'No',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			no_bt.addEventListener(TSEvent.CHANGED, closeFromUserInput, false, 0, true);
			_scroller.body.addChild(no_bt);
			
			//icon holder and arrow
			icon_holder.x = _base_padd;
			icon_holder.y = _base_padd;
			addChild(icon_holder);
			
			arrow = new AssetManager.instance.assets.emblem_arrow();
			arrow.x = _base_padd + _border_w;
			arrow.y = 60 + _border_w;
			addChild(arrow);
			
			is_built = true;
		}
		
		override public function start():void {
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			
			_setTitle('Please Confirm!');
			
			//set the body/tip text and buttons
			setBody();
			
			//listen to stuff
			model.worldModel.registerCBProp(setBody, "pc", "skill_training");
			PackDisplayManager.instance.registerChangeSubscriber(this);
			
			super.start();
		}
		
		override public function end(release:Boolean):void {
			super.end(release);
			
			//stop listening to stuff
			model.worldModel.unRegisterCBProp(setBody, "pc", "skill_training");
			PackDisplayManager.instance.unRegisterChangeSubscriber(this);
		}
		
		override protected function _jigger():void {
			super._jigger();
			
			//nudge the title down a lil bit
			_title_tf.y = int(_head_h - _title_tf.height);
			
			tip_tf.y = int(body_tf.y + body_tf.height + 8);
			no_bt.x = int(_w - no_bt.width - _base_padd - 2);
			no_bt.y = int(tip_tf.y + tip_tf.height - no_bt.height + 3);
			yes_bt.x = int(no_bt.x - yes_bt.width - 10);
			yes_bt.y = no_bt.y;
			
			_body_h = yes_bt.y + yes_bt.height + _base_padd;
			_scroller.h = _body_h;
			_h = _head_h + _body_h + _foot_h;
			
			_draw();
		}
		
		private function setBody(skill_training:PCSkill = null):void {
			const emblem:Emblem = EmblemManager.instance.current_emblem;
			const itemstack:Itemstack = emblem ? model.worldModel.getItemstackByTsid(emblem.itemstack_tsid) : null;
			const skill_name:String = model.worldModel.pc && model.worldModel.pc.skill_training ? model.worldModel.pc.skill_training.name : null;
			const has_count:int = itemstack ? model.worldModel.pc.hasHowManyItems(itemstack.class_tsid) : 0;
			const ui_visible:Boolean = emblem && skill_name && has_count ? true : false;
			const giant_name:String = itemstack ? (itemstack.class_tsid.substr(7) != 'ti' ? Giants.getLabel(itemstack.class_tsid.substr(7)) : 'Tii') : null; //7 removes "emblem_"
			
			var txt:String = '<p class="emblem_spend">';
			var tip_txt:String = '<p class="emblem_spend_tip">';
			
			//should we show the yes/no buttons?
			yes_bt.visible = no_bt.visible = ui_visible;
			no_bt.label = 'No';
			
			arrow.visible = ui_visible;
			icon_holder.visible = ui_visible;
			
			if(emblem && skill_name && has_count){
				const speed_up:String = StringUtil.formatTime(emblem.speed_up).split(' ').join('&nbsp;');
				
				txt += 'Are you sure you want to spend this <b>Emblem of '+giant_name+'</b> to reduce the learning time of <b>'+skill_name+'</b> by <b>'+speed_up+'</b>';
				
				//set the tip text
				tip_txt += '<b>Note!</b> ';
				
				if(emblem.is_primary){
					tip_txt += giant_name+' is the giant most closely affiliated with this skill, so spending their emblem here offers top-class speed-learning!';
				}
				else if(emblem.is_secondary){
					tip_txt += giant_name+' is affiliated with this skill (but not as closely as another giant), so spending their emblem will speed up learning a substantial amount';
				}
				else {
					tip_txt += giant_name+' is not affiliated with this skill, so spending their Emblem won\'t speed up learning as much.';
				}
			}
			else if(!skill_name || (emblem && !has_count)){
				//they are not learning anything, but still have the dialog up
				if(!skill_name){
					txt += 'Silly goose, you need to be learning a skill to be able to spend your emblem!';
				}
				else {
					//they lost the emblem while the dialog was open
					txt += 'Hmm, where did that <b>Emblem of '+giant_name+'</b> go?! Well you can\'t spend that which you don\'t have...';
				}
				
				no_bt.visible = true;
				no_bt.label = 'Close';
			}
			else {
				txt += 'Hmm, something went funky. Try spending your emblem again.';
			}
			
			txt += '</p>';
			tip_txt += '</p>';
			
			body_tf.htmlText = txt;
			tip_tf.htmlText = tip_txt;
			
			//set the icons
			setIcons();
			
			//adjust
			_jigger();
		}
		
		private function setIcons():void {
			const emblem:Emblem = EmblemManager.instance.current_emblem;
			if(!emblem) return;
			
			const skill_tsid:String = model.worldModel.pc && model.worldModel.pc.skill_training ? model.worldModel.pc.skill_training.tsid : 'none';
			const itemstack:Itemstack = model.worldModel.getItemstackByTsid(emblem.itemstack_tsid);
			if(!itemstack) return;
			
			//emblem icon
			if(!emblem_icon || (emblem_icon && emblem_icon.tsid != itemstack.class_tsid)){
				//if we have one already, crush it
				if(emblem_icon && emblem_icon.parent) {
					emblem_icon.parent.removeChild(emblem_icon);
				}
				
				//make a new one
				emblem_icon = new ItemIconView(itemstack.class_tsid, EMBLEM_WH);
				icon_holder.addChild(emblem_icon);
			}
			
			//skill icon
			if(!skill_icon || (skill_icon && skill_icon.name != skill_tsid)){
				if(skill_icon && skill_icon.parent) {
					skill_icon.parent.removeChild(skill_icon);
				}
				
				//make a new one
				skill_icon = new SkillIcon(skill_tsid);
				skill_icon.x = 10;
				skill_icon.y = EMBLEM_WH + 8;
				icon_holder.addChild(skill_icon);
			}
		}
		
		private function onYesClick(event:TSEvent):void {
			if(yes_bt.disabled) return;
			
			EmblemManager.instance.spend();
			end(true);
		}
		
		public function onPackChange():void {
			//make sure we still have an emblem
			setBody();
		}
	}
}