package com.tinyspeck.engine.view.ui.jobs
{
	import com.tinyspeck.engine.data.job.JobOption;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.requirement.Requirement;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.Sprite;
	import flash.text.TextField;

	public class JobOptionUI extends Sprite
	{
		private static const PADD:int = 8;
		
		private var contribute_bt:Button;
		
		private var title_tf:TextField = new TextField();
		private var body_tf:TextField = new TextField();
		
		public function JobOptionUI(w:int){
			TFUtil.prepTF(title_tf);
			title_tf.width = w;
			addChild(title_tf);
			
			TFUtil.prepTF(body_tf);
			body_tf.width = w;
			addChild(body_tf);
			
			contribute_bt = new Button({
				label: 'Contribute + Vote',
				name: 'option',
				size: Button.SIZE_TINY,
				type: Button.TYPE_DEFAULT,
				label_offset: 1
			});
			contribute_bt.h = CSSManager.instance.getNumberValueFromStyle('button_'+contribute_bt.size+'_double', 'height');
			contribute_bt.addEventListener(TSEvent.CHANGED, onContributeClick, false, 0, true);
			addChild(contribute_bt);
		}
		
		public function show(option:JobOption, is_enabled:Boolean, req:Requirement, is_currants:Boolean):void {			
			title_tf.htmlText = '<p class="job_option_title">'+(option.name ? option.name : 'No Title?!')+'&nbsp;&nbsp;'+
								'<span class="job_option_percent">'+(option.perc*100).toFixed(1)+'% of votes</span></p>';
			body_tf.htmlText = '<p class="job_option_body">'+(option.desc ? option.desc : 'Bacon bacon bacon bacon')+'</p>';
			body_tf.y = int(title_tf.height + PADD);
			
			contribute_bt.y = int(body_tf.y + body_tf.height + PADD);
			contribute_bt.disabled = !is_enabled;
			contribute_bt.value = {
				type: (req.is_work ? 'work' : (is_currants ? 'currants' : 'item')),
				class_tsid: getItemClass(req),
				option: option.hashName,
				req_id: req.id
			}
		}
		
		private function getItemClass(req:Requirement):String {
			//if our requirement has multiple classes, return the first one the player has
			var item_class:String = req.item_class;
			
			if(req.item_classes){
				const pc:PC = TSModelLocator.instance.worldModel.pc;
				const total:int = req.item_classes.length;
				var i:int;
				var has_how_many:int;
				var check_item_tsid:String;
				
				for(i; i < total; i++){
					check_item_tsid = req.item_classes[int(i)];
					has_how_many = pc.hasHowManyItems(check_item_tsid);
					if(has_how_many > 0){
						if(!req.is_work){
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
		
		private function onContributeClick(event:TSEvent):void {
			if(contribute_bt.disabled) return;
			
			//let the details know we clicked it
			dispatchEvent(new TSEvent(TSEvent.CHANGED, contribute_bt));
		}
	}
}