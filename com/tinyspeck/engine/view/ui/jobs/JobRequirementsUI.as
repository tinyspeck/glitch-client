package com.tinyspeck.engine.view.ui.jobs
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.requirement.Requirement;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.net.MessageTypes;
	import com.tinyspeck.engine.net.NetOutgoingLocalChatVO;
	import com.tinyspeck.engine.port.JobDialog;
	import com.tinyspeck.engine.port.JobManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.text.TextField;
	import flash.ui.Keyboard;

	public class JobRequirementsUI extends TSSpriteWithModel
	{
		public static const BUTTON_HEIGHT:uint = 70;
		public static const Y_OFFSET:uint = 18;
		
		private static const BUTTON_WIDTH:uint = 63;
		private static const BUTTON_ICON_WH:uint = 36;
		
		private var title_tf:TextField = new TextField();
		
		private var current_req:Requirement;
		private var bt:Button;
		
		private var item_tip:Item;
		private var str_tip:String;
		private var label_tip:String;
			
		public function JobRequirementsUI(){
			TFUtil.prepTF(title_tf, false);
			title_tf.htmlText = '<p class="job_holder_title">Placeholderp</p>';
			addChild(title_tf);
		}
		
		public function show(req:Requirement, is_active:Boolean):void {
			current_req = req;
			const item_class:String = getItemClass();
			
			if(item_class && !model.worldModel.getItemByTsid(item_class)) {
				BootError.handleError('A job requirement has a bad item_class: '+item_class, new Error('Bad Item Class'), null, !CONFIG::god);
				return;
			}
			
			if(!bt){
				bt = new Button({
					graphic_placement: 'top',
					name: 'req',
					graphic_padd_t: 10,
					default_tf_padd_w: 2,
					c: 0xffffff,
					disabled_c: 0xffffff,
					disabled_graphic_alpha: .5,
					disabled_draw_alpha: .5,
					default_tf_padd_w: 0,
					high_c: 0xffffff,
					shad_c: 0xa3a3a3,
					inner_shad_c: 0x69bcea,
					y: Y_OFFSET
				});
				addChild(bt);
			}
			
			//set the button values
			if(bt.graphic && bt.graphic.name != item_class){
				bt.removeGraphic();
				bt.setGraphic(new ItemIconView(item_class, BUTTON_ICON_WH));
			}
			else if(!bt.graphic){
				bt.setGraphic(new ItemIconView(item_class, BUTTON_ICON_WH));
			}
			
			bt.label = getButtonLabel(is_active);
			bt.tip = getButtonTip(is_active);
			bt.disabled = !(is_active && !req.completed);
			bt.name = req.id;
			bt.value = req.id;
			bt.w = item_class != 'money_bag' ? BUTTON_WIDTH : BUTTON_WIDTH + BUTTON_WIDTH/2;
			bt.h = int(bt.label_tf.y + bt.label_tf.height) + 2;
			bt.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
			
			//set the title up
			title_tf.alpha = is_active && !req.completed ? 1 : .5;
			title_tf.htmlText = getTitle();
			title_tf.x = int(bt.x + (bt.w/2 - title_tf.width/2));
			
			visible = true;
		}
		
		private function onButtonClick(event:TSEvent):void {
			if(!bt) return;
			
			if(model.stateModel.menus_prohibited || bt.disabled) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			//major WTF, but let's be defensive
			if(!current_req || !bt.value) {
				BootError.handleError('A button with value:'+bt.value+' has no req on the job??', new Error('Unknown Job Req'), null, !CONFIG::debugging);
				return;
			}
			
			//if we are god, let's do some MAGIC
			if (CONFIG::god) {
				if (KeyBeacon.instance.pressed(Keyboard.CONTROL)) {
					var is_currants:Boolean = current_req.item_class == 'money_bag';
					const item_class:String = getItemClass();
					
					if (item_class) {
						if (is_currants) {
							TSFrontController.instance.sendLocalChat(
								new NetOutgoingLocalChatVO('/cash '+current_req.need_num)
							);
						} else {
							if (current_req.is_work) {
								JobManager.instance.sendMessageToServer(
									MessageTypes.JOB_APPLY_WORK, 
									item_class, 
									33, 
									0, // I dunno how we should do this if there is more than one option
									current_req.id
								);
								if(!JobManager.instance.job_info.complete){
									JobManager.instance.maybeRequestJobInfo(true, true);
								}
							} else {
								var c:int = (current_req.is_work) ? 1 : current_req.need_num;
								TSFrontController.instance.sendLocalChat(
									new NetOutgoingLocalChatVO('/create item '+item_class+' '+c+' in pack')
								);
							}
						}
						return;
					}
				}
			}
			
			//show the details
			JobDialog.instance.showDetails(bt.value);
		}
		
		public function getTitle():String {
			var title:String = current_req.completed ? 'Collected' : 'Collect';
			
			if(current_req.verb) {
				title = current_req.completed ? current_req.verb.past_tense : current_req.verb.name;
			}
			
			return '<p class="job_holder_title">'+StringUtil.capitalizeFirstLetter(title)+'</p>';
		}
		
		private function getButtonLabel(is_active:Boolean):String {
			const pc:PC = model.worldModel.pc;
			const item_class:String = getItemClass();
			const total_items:int = pc.hasHowManyItems(item_class);
			const need_num:String = StringUtil.crunchNumber(current_req.need_num);
			const got_num:String = StringUtil.crunchNumber(current_req.got_num);
			var str:String = '<p class="job_item">';
			
			if(item_class == 'money_bag'){
				str += (pc.stats.currants > 0 || !is_active ? '' : '<span class="job_item_disabled">') + 
					'<span class="job_item_got">' + got_num + 
					'</span>&nbsp;of&nbsp;' + need_num + 
					(pc.stats.currants > 0 || !is_active ? '' : '</span>');
			}
			else {
				str += ((total_items == 0 || current_req.disabled) && !current_req.completed && is_active ? '<span class="job_item_disabled">' : '') +
					'<span class="job_item_got">' + got_num + 
					'</span> of&nbsp;' + need_num + 
					((total_items == 0 || current_req.disabled) && !current_req.completed && is_active ? '</span>' : '');
			}
			
			str += '</p>';
			
			return str;
		}
		
		private function getItemClass():String {
			//if our requirement has multiple classes, return the first one the player has
			var item_class:String = current_req.item_class;
			
			if(current_req.item_classes){
				const pc:PC = model.worldModel.pc;
				const total:int = current_req.item_classes.length;
				var i:int;
				var has_how_many:int;
				var check_item_tsid:String;
				
				for(i; i < total; i++){
					check_item_tsid = current_req.item_classes[int(i)];
					has_how_many = pc.hasHowManyItems(check_item_tsid);
					if(has_how_many > 0){
						if(!current_req.is_work){
							item_class = check_item_tsid;
							break;
						}
						else {
							//find a working version of the tool
							if(pc.getItemstackOfWorkingTool(check_item_tsid)){
								item_class = check_item_tsid;
								break;
							}
						}
					}
				}
			}
			
			return item_class;
		}
		
		private function getButtonTip(is_active:Boolean):Object {
			if(!current_req){
				CONFIG::debugging {
					Console.warn('No req?! This is bad and should never happen, but it did');
				}
				return null;
			}
			
			const item_class:String = getItemClass();
			
			if(!item_class) return null;
			
			item_tip = model.worldModel.getItemByTsid(item_class);
			label_tip = (item_class != 'money_bag' ? item_tip.label : 'Currant');
			
			if(current_req.need_num != 1 && !current_req.is_work) label_tip = (item_class != 'money_bag' ? item_tip.label_plural : 'Currants');
			
			if(is_active || current_req.completed){
				str_tip = !current_req.completed 
					? current_req.desc 
					: 'Done! '+current_req.need_num+' '+(current_req.is_work 
						? 'work units with '+StringUtil.aOrAn(label_tip)+' '+label_tip 
						: label_tip);
			}
			else {
				if(is_active && current_req.disabled_reason && current_req.disabled_reason != ''){
					str_tip = current_req.disabled_reason;
				}
				else {
					str_tip = 'Finish the requirements to the left first!';
				}
			}
			
			return {
				txt: str_tip,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			};
		}
		
		override public function get width():Number {
			if(bt) return bt.width;
			
			return 0;
		}
	}
}