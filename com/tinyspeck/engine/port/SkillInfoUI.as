package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.skill.SkillDetails;
	import com.tinyspeck.engine.data.skill.SkillGiant;
	import com.tinyspeck.engine.data.skill.SkillRequirement;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.net.NetOutgoingSkillUnlearnCancelVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;

	public class SkillInfoUI extends ItemInfoUI
	{
		private static const TEXT_X:int = 110;
		
		private var learn_bt:Button;
		private var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
				
		private var req_holder:Sprite = new Sprite();
		private var post_req_holder:Sprite = new Sprite();
		private var giant_holder:Sprite = new Sprite();
		
		private var current_skill_tsid:String;
		
		private var is_built:Boolean;
		private var is_skill:Boolean;
		private var dialog:BigDialog
		
		public function SkillInfoUI(w:int, dialog:BigDialog){
			super(w);
			this.dialog = dialog;
		}
		
		private function buildBase():void {
			learn_bt = new Button({
				name: 'learn',
				label: 'Start learning this skill',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_DEFAULT
			});
			learn_bt.addEventListener(TSEvent.CHANGED, onLearnClick, false, 0, true);
			addChild(learn_bt);
			
			buildInfoHolder('req', 'Requirements');
			buildInfoHolder('post_req', 'Needed for');
			buildInfoHolder('giant', 'Giants');
			addChild(req_holder);
			addChild(post_req_holder);
			addChild(giant_holder);
			
			//confirmation
			cdVO.title = 'You\'re already unlearning a skill!';
			cdVO.escape_value = false;
			cdVO.callback = onUnlearnConfirm;
			cdVO.choices = [
				{value:false, label:'Nevermind'},
				{value:true, label:'Yes, stop unlearning'}
			];
			
			is_built = true;
		}
		
		override public function show(class_tsid:String, reload_data:Boolean, routing_class:String=null):void {
			if(!class_tsid) return;
			
			if(!is_built) buildBase();
			
			current_skill_tsid = class_tsid;
			is_skill = true;
			
			api_call.skillsInfo(class_tsid);
			
			//loading
			setBodyText('<p>Loading info...</p>');
			learn_bt.visible = false;
			
			//clean the tips/warnings
			SpriteUtil.clean(warnings_holder);
			SpriteUtil.clean(tips_holder);
			
			//hide the holders
			req_holder.visible = false;
			post_req_holder.visible = false;
			giant_holder.visible = false;
		}
		
		public function dialogEnterKeyHandler(e:KeyboardEvent):void {
			if (!learn_bt.disabled) {
				learnIt();
			} else {
				
			}
		}
		
		override protected function onLoadComplete(event:TSEvent):void {
			dispatchEvent(new TSEvent(TSEvent.COMPLETE, this));
			
			if(is_skill){
				setBody();
			}
			else {
				learn_bt.disabled = false;
			}
		}
		
		private function setBody():void {
			//response is the response from an API call
			var body_txt:String = '<p>Hmm, something went kind of wrong, can\'t seem to find information on this thing.</p>';
			var details:SkillDetails = current_details;
			
			//no response? dump the default text out then
			if(!details){
				setBodyText(body_txt);
				return;
			}
			
			//if info is present populate the body
			if(details.description) body_txt = '<p>'+details.description+'</p>';
			
			//learn bt
			learn_bt.visible = true;
			learn_bt.tip = getLearnTipAndSetButtonState();
			
			//setup any info blocks we may need
			prepInfoBlocks();
			
			//populate the body with the good stuff
			setBodyText(body_txt);
						
			jigger();
		}
		
		private function prepInfoBlocks():void {
			//this will break down reqs and post_reqs into warnings and tips (in that order)
			
			//reqs
			setInfoHolder('req', getInfoText(current_details.reqs));
			
			//post reqs
			setInfoHolder('post_req', getInfoText(current_details.post_reqs));
			
			//giants
			var giants:Vector.<SkillGiant> = current_details.giants;
			var pri_giant:String = 'Primary: ';
			var sec_giant:String = 'Secondary: ';
			var info_txt:String = '';
			var i:int;
			giants = current_details.getGiants(true);
			if(giants.length > 0){
				for(i = 0; i < giants.length; i++){					
					pri_giant += giants[int(i)].giant_name;
					if(i != giants.length-1) pri_giant += ', ';
				}
				
				info_txt += pri_giant;
			}
			
			giants = current_details.getGiants(false);
			if(giants.length > 0){
				if(info_txt != '') info_txt += '<br>';
				
				for(i = 0; i < giants.length; i++){					
					sec_giant += giants[int(i)].giant_name;
					if(i != giants.length-1) sec_giant += ', ';
				}
				
				info_txt += sec_giant;
			}
			setInfoHolder('giant', info_txt);
		}
		
		private function getInfoText(reqs:Vector.<SkillRequirement>):String {
			if(!reqs) return '';
			
			var info_txt:String = '';
			var i:int;
			var req:SkillRequirement;
			const total:uint = reqs.length;
			
			for(i = 0; i < reqs.length; i++){
				req = reqs[int(i)];
				
				//start of the red span
				if(!req.got) info_txt += '<span class="get_info_link_need">';
				
				if(req.type == SkillRequirement.TYPE_SKILL){
					info_txt += '<a href="event:'+TSLinkedTextField.LINK_SKILL+'|'+req.class_tsid+'"'+(!req.got ? ' class="get_info_link_need"' : '')+'>Skill: '+req.name+'</a>';
				}
				else if(req.type == SkillRequirement.TYPE_LEVEL){
					info_txt += 'Level: '+req.level;
				}
				else if(req.type == SkillRequirement.TYPE_QUEST){
					info_txt += 'Quest: '+req.name;
				}
				else if(req.type == SkillRequirement.TYPE_ACHIEVEMENT){
					info_txt += '<a href="event:'+TSLinkedTextField.LINK_EXTERNAL+'|'+req.url+'"'+(!req.got ? ' class="get_info_link_need"' : '')+'>Achievement: '+req.name+'</a>';
				}
				else if(req.type == SkillRequirement.TYPE_UPGRADE){
					info_txt += '<a href="event:'+TSLinkedTextField.LINK_EXTERNAL+'|'+req.url+'"'+(!req.got ? ' class="get_info_link_need"' : '')+'>Upgrade: '+req.name+'</a>';
				}
				
				//close of the red span
				if(!req.got) info_txt += '</span>';
				
				if(i != reqs.length-1) info_txt += '<br>';
			}
			
			return info_txt;
		}
		
		private function jigger():void {									
			//warning stuff
			warnings_holder.y = int(body_tf.y + body_tf.height + 10);
			
			//tips stuff
			tips_holder.y = int(warnings_holder.y + warnings_holder.height + 5);
			
			//holders
			var next_y:int = int(body_tf.y + body_tf.height) + 15;
			req_holder.y = post_req_holder.y = giant_holder.y = next_y;
						
			if(req_holder.visible){
				next_y += req_holder.height + 8;
			}
			
			post_req_holder.y = next_y;
			
			if(post_req_holder.visible){
				next_y += post_req_holder.height + 8;
			}
			
			giant_holder.y = next_y;
			
			if(giant_holder.visible){
				next_y += giant_holder.height + 8;
			}
			
			learn_bt.y = next_y + 10;
			next_y += learn_bt.height + 25;
			
			//make this bad boy a little taller
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0,0);
			g.drawRect(0, 0, w, next_y);
						
			//let the people who are listen know that we've changed
			dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
		}
		
		private function getLearnTipAndSetButtonState():Object {
			var txt:String;
			var details:SkillDetails = current_details;
			learn_bt.disabled = false;
			
			if(details.learning && !details.paused){
				txt = 'You\'re already learning this skill!';
				learn_bt.disabled = true;
			}
			else if(details.got){
				txt = 'You already know this skill!';
				learn_bt.disabled = true;
			}
			else if(details.learning && details.paused){
				txt = 'You\'ve got this skill on pause at the moment.';
			}
			else if(!details.can_learn){
				txt = 'You need to meet the requirements first!';
				learn_bt.disabled = true;
			}
			else if(model.worldModel.location && model.worldModel.location.no_skill_learning){
				// here's we're making a fairly safe assumption that if the iMG menu is turned off
				// the user is in newxp and so shoudl not be able to start leanring skills
				// if it turns out that there are locations where the iMG menu is hidden but we want to enable
				// skill learning, we should switch to using an explicit flag on the location
				// like "no_skill_learning" that is true on newxp location
				// [SY] "no_skill_learning" is now a thing for real!
				txt = 'No skill learning yet. That\'s coming up for you soon!';
				learn_bt.disabled = true;
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
		
		private function onLearnClick(event:TSEvent):void {
			//if they are currently un-learning something, pop up a confirmation
			const pc:PC = model.worldModel.pc;
			if(pc.skill_unlearning){
				var txt:String = 'Are you sure you want to stop unlearning <b>'+pc.skill_unlearning.name+'</b> and start learning <b>'+current_details.name+'</b>?';
				txt += '<br><span class="get_info_link_need">You\'ll lose all your progress on unlearning <b>'+pc.skill_unlearning.name+'</b></span>';
				cdVO.txt = txt;
				TSFrontController.instance.confirm(cdVO);
				learn_bt.disabled = true;
			}
			else {
				//go learn it
				learnIt();
			}
		}
		
		private function onUnlearnConfirm(value:Boolean):void {
			if(value){
				//tell the server we want to stop unlearning and start learning this new skill
				TSFrontController.instance.genericSend(new NetOutgoingSkillUnlearnCancelVO(), onUnlearnReply, onUnlearnReply);
			}
			learn_bt.tip = getLearnTipAndSetButtonState();
		}
		
		private function onUnlearnReply(nrm:NetResponseMessageVO):void {
			//go learn young jedi
			if(nrm.success) learnIt();
		}
		
		private function learnIt():void {
			if(learn_bt.disabled) return;
			
			learn_bt.disabled = true;
			is_skill = false;
			
			//make an API call to start learning
			api_call.skillsLearn(current_skill_tsid);
			
			//close this
			if (dialog is GetInfoDialog) {
				GetInfoDialog.instance.end(true);
				
				// close the window and the familiarDialog, if it looks like we started learning this skill from the familiarDialog
				if (model.stateModel.fam_dialog_open && FamiliarDialog.instance.skills_holder_visible){
					TSFrontController.instance.endFamiliarDialog();
				}
			}
			
			//play a sound
			SoundMaster.instance.playSound('BEGIN_LEARNING_SKILL');
		}
		
		private function buildInfoHolder(type:String, title:String):void {
			var holder:Sprite = getInfoHolder(type);
			var tf:TextField;
			
			if(holder){				
				//setup the tfs
				tf = new TextField();
				TFUtil.prepTF(tf, false);
				tf.embedFonts = false;
				tf.htmlText = '<p class="get_info_body"><span class="get_info_body_heading">'+title+'</span></p>';
				holder.addChild(tf);
				
				tf = new TSLinkedTextField();
				TFUtil.prepTF(tf);
				tf.embedFonts = false;
				tf.htmlText = '<p class="get_info_body">Placeholderp</p>';
				tf.name = 'tf';
				tf.x = TEXT_X;
				tf.width = w - TEXT_X;
				
				holder.addChild(tf);
				
				//hide by default
				holder.visible = false;
			}
			else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('Type not reconized when passed to buildInfoHolder: '+type);
				}
			}
		}
		
		override protected function getInfoHolder(type:String):Sprite {
			return this[type+'_holder'] as Sprite;
		}
		
		override public function preloadItems(item_tsids:Array):void {
			CONFIG::debugging {
				Console.warn('This method is not implemeted for skills!');
			}
		}
		
		public function get current_details():SkillDetails { return model.worldModel.getSkillDetailsByTsid(current_skill_tsid); }
	}
}