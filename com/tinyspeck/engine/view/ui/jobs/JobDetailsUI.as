package com.tinyspeck.engine.view.ui.jobs
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.job.JobOption;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.requirement.Requirement;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.net.MessageTypes;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.JobManager;
	import com.tinyspeck.engine.port.QuantityPicker;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	
	import flash.display.CapsStyle;
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.events.TextEvent;
	import flash.text.TextField;

	public class JobDetailsUI extends TSSpriteWithModel
	{
		private static const ITEM_WH:uint = 100;
		private static const ITEM_HOLDER_WH:uint = 130;
		private static const ITEM_HOLDER_Y:int = 30;
		private static const DIVIDER_HEIGHT:uint = 266;
		private static const TEXT_WIDTH:uint = 150;
		private static const OPTION_X:int = 170;
		private static const OPTION_HEIGHT:uint = 130;
		private static const POLAROID_OFFSET:int = 85;
			
		private var icon:ItemIconView;
		private var qty_picker:QuantityPicker;
		private var item:Item;
		private var pc:PC;
		private var options:Vector.<JobOption>;
		private var contribute_bt:Button;
		private var current_req:Requirement;
		private var option_elements:Vector.<JobOptionUI> = new Vector.<JobOptionUI>();
		
		private var title_tf:TextField = new TextField();
		private var need_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var details_txt:String;
		
		private var total_items:int;
		private var amount_left:int;
		private var total_options:int;
		
		private var is_currants:Boolean;
		
		public function JobDetailsUI(w:int, h:int){
			_w = w;
			_h = h;
			
			//quantity picker setup
			qty_picker = new QuantityPicker({
				w: ITEM_HOLDER_WH,
				h: 34,
				name: '_quantity_qp',
				minus_graphic: new AssetManager.instance.assets.minus_red(),
				plus_graphic: new AssetManager.instance.assets.plus_green(),
				max_value: 1, // to be changed
				min_value: 1,
				button_wh: 20,
				button_padd: 3,
				show_all_option: true
			});
			addChild(qty_picker);
			
			//title
			TFUtil.prepTF(title_tf, false);
			title_tf.htmlText = '<p class="job_option_title">How many?</p>';
			title_tf.x = ITEM_HOLDER_WH + 32;
			title_tf.y = ITEM_HOLDER_Y + 10;
			addChild(title_tf);
			
			//need tf
			TFUtil.prepTF(need_tf);
			need_tf.embedFonts = false;
			need_tf.width = TEXT_WIDTH;
			need_tf.addEventListener(TextEvent.LINK, onTextLinkClick, false, 0, true);
			addChild(need_tf);
			
			//contribute
			contribute_bt = new Button({
				label: 'Contribute',
				name: 'option0',
				size: Button.SIZE_TINY,
				type: Button.TYPE_DEFAULT,
				label_offset: 1,
				x: title_tf.x
			});
			contribute_bt.h = CSSManager.instance.getNumberValueFromStyle('button_'+contribute_bt.size+'_double', 'height');
			contribute_bt.addEventListener(TSEvent.CHANGED, onContributeClick, false, 0, true);
			addChild(contribute_bt);
			
			visible = false;
		}
		
		public function show(req:Requirement):void {
			if(!req || (req && !req.item_class)){
				CONFIG::debugging {
					Console.warn('No req, or a req without an item class! '+(req ? 'no item class' : 'no req'));
				}
				return;
			}
			
			visible = true;
			current_req = req;
			const item_class:String = getItemClass();
			
			//set the pc
			pc = model.worldModel.pc;
			
			//we working with currants?
			is_currants = item_class == 'money_bag';
			
			//draw the stuff we need to draw
			drawItemHolder();
			
			//setup the quantity picker
			qty_picker.w = !is_currants ? ITEM_HOLDER_WH : ITEM_HOLDER_WH + 20;
			qty_picker.x = int(ITEM_HOLDER_WH/2 - qty_picker.width/2);
			qty_picker.value = 1;
			
			//update everything
			update(req);
		}
		
		private function update(req:Requirement):void {
			if(!req) return;
			current_req = req;
			if(!visible) return;
			const item_class:String = getItemClass();
			
			item = model.worldModel.getItemByTsid(item_class);
			if(!item || !pc){
				CONFIG::debugging {
					Console.warn('WTF no item or pc?! item: '+item+'  pc: '+pc);
				}
				return;
			}
			
			//set the icon
			if(icon && icon.tsid == item_class){
				//nuffin'
			}
			else {
				if(icon && icon.parent) icon.parent.removeChild(icon);
				icon = new ItemIconView(item_class, ITEM_WH);
				icon.x = int(ITEM_HOLDER_WH/2 - icon.w/2);
				icon.y = int(ITEM_HOLDER_Y + (ITEM_HOLDER_WH/2 - icon.h/2));
				addChild(icon);
			}
			
			//setup shop
			total_items = pc.hasHowManyItems(item.tsid);
			amount_left = req.need_num - req.got_num;
			options = JobManager.instance.job_info.options;
			total_options = options.length;
			
			//set the details text
			details_txt = '<p class="job_details_qty">';
			
			if(item.tsid == 'money_bag'){
				details_txt += 'We need <b>'+StringUtil.formatNumberWithCommas(amount_left)+'</b>'+
								' more '+(amount_left == 1 ? 'Currant' : 'Currants')+'. '+
								'You&nbsp;have&nbsp;<b><a href="event:'+Math.min(pc.stats.currants, amount_left)+'">'+
								StringUtil.formatNumberWithCommas(pc.stats.currants)+'</a>'+
								'</b>.';
				
				total_items = pc.stats.currants;
			}
			else if(req.is_work){
				//build the tricky text for work units. Make the need number a link only if they can perform the work
				details_txt += 'We need <b>';
				
				if(!req.disabled) details_txt += '<a href="event:'+amount_left+'">';
					details_txt += StringUtil.formatNumberWithCommas(amount_left);
				if(!req.disabled) details_txt += '</a>';
					details_txt += '</b> more work '+(amount_left == 1 ? 'unit' : 'units')+' using '+
									StringUtil.aOrAn(item.label)+' '+item.label+'. ';
				if(req.disabled) details_txt += '<span class="job_item_disabled">But!&nbsp;'+req.disabled_reason+'</span>';
				
				total_items = amount_left;
			}
			else {
				details_txt += 'We need <b>'+StringUtil.formatNumberWithCommas(amount_left)+'</b>'+
								' more <a href="event:'+TSLinkedTextField.LINK_ITEM+'|'+item.tsid+'">'+
								(amount_left == 1 ? item.label : item.label_plural)+'</a>. ';
				if(total_items > 0){
					details_txt += 'You&nbsp;have&nbsp;<b><a href="event:'+Math.min(total_items, amount_left)+'">'+
									StringUtil.formatNumberWithCommas(total_items)+'</a></b>.';
				}
				else {
					details_txt += '<span class="job_item_disabled">But!&nbsp;You&nbsp;don\'t&nbsp;have&nbsp;any.</span>';
				}
			}
			
			//center the details when we have options
			if(total_options > 1){
				details_txt = '<p align="center">'+details_txt+'</p>';
			}
			
			//set the text
			need_tf.htmlText = details_txt + '</p>';
			
			//make sure the qty picker is accurate
			qty_picker.max_value = Math.min(total_items, amount_left);
			qty_picker.y = ITEM_HOLDER_Y + ITEM_HOLDER_WH + 10;
			
			//do we show the picker?
			if(total_items > 0 && !req.disabled || item.tsid == 'money_bag' && pc.stats.currants > 0){
				qty_picker.visible = true;
				if(total_options > 1) need_tf.y = qty_picker.y + qty_picker.h + 10;
			}
			else{
				qty_picker.visible = false;
				if(total_options > 1) need_tf.y = ITEM_HOLDER_Y + ITEM_HOLDER_WH + 10;
			}
			
			//can we contribute
			contribute_bt.disabled = (total_items > 0 && !current_req.disabled) ? false : true;
			contribute_bt.value = { 
				type: (current_req.is_work ? 'work' : (is_currants ? 'currants' : 'item')),
				class_tsid: item_class,
				option: 0,
				req_id: current_req.id
			};
			
			//do the layout proper
			if(total_options > 1){
				updateOptions();
			}
			else {
				updateSingle();
			}
		}
		
		public function refresh():void {
			//make sure we have the latest version of the req
			if(!visible) return;
			const req:Requirement = JobManager.instance.getReqById(current_req.id);
			update(req);
		}
		
		private function updateSingle():void {
			title_tf.visible = true;
			contribute_bt.visible = true;
			
			need_tf.x = title_tf.x;
			need_tf.y = int(title_tf.y + title_tf.height);
			
			contribute_bt.y = int(need_tf.y + need_tf.height) + 8;
		}
		
		private function updateOptions():void {
			var i:int;
			var element:JobOptionUI;
			var next_y:int = title_tf.y;
			
			//hide any we already have
			for(i = 0; i < option_elements.length; i++){
				element = option_elements[int(i)];
				element.x = 0;
				element.y = 0;
				element.visible = false;
			}
			
			for(i = 0; i < total_options; i++){
				//reuse
				if(option_elements.length > i){
					element = option_elements[int(i)];
				}
				//make new
				else {
					element = new JobOptionUI(_w - OPTION_X - POLAROID_OFFSET);
					element.addEventListener(TSEvent.CHANGED, onContributeClick, false, 0, true);
					option_elements.push(element);
					addChild(element);
				}
				
				element.visible = true;
				element.show(options[int(i)], !contribute_bt.disabled, current_req, is_currants);
				element.x = OPTION_X;
				element.y = next_y;
				
				next_y += Math.max(OPTION_HEIGHT, element.height + 15);
			}
			
			title_tf.visible = false;
			contribute_bt.visible = false;
			
			contribute_bt.y = 0;
			
			need_tf.x = qty_picker.x + int(qty_picker.width/2 - need_tf.width/2);
			need_tf.y = qty_picker.visible ? int(qty_picker.y + qty_picker.height + 5) : int(qty_picker.y);
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
		
		private function drawItemHolder():void {
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0,0);
			g.drawRect(OPTION_X + 30, 0, 1, _h);
			if(!is_currants){
				g.lineStyle(1, 0xbec7c9, 1, true, LineScaleMode.NONE, CapsStyle.ROUND);
				g.beginFill(0xffffff);
				g.drawRoundRect(0, ITEM_HOLDER_Y, ITEM_HOLDER_WH, ITEM_HOLDER_WH, 14);
			}
		}
		
		private function onTextLinkClick(event:TextEvent):void {
			qty_picker.value = int(event.text);
		}
		
		private function onContributeClick(event:TSEvent):void {
			var bt:Button = event.data as Button;
			if(!bt || (bt && bt.disabled)) return;
			if(!pc) return;
			
			//make sure they don't click it more than once
			bt.disabled = true;
			
			if(bt.value.type == 'work'){
				if(pc.stats.energy.value < current_req.energy){
					model.activityModel.growl_message = 'You don\'t have enough energy to continue.';
					return;
				}
				
				JobManager.instance.sendMessageToServer(
					MessageTypes.JOB_CONTRIBUTE_WORK, 
					bt.value.class_tsid, 
					qty_picker.value, 
					bt.value.option,
					current_req.id
				);
			}
			else if(bt.value.type == 'currants'){
				JobManager.instance.sendMessageToServer(
					MessageTypes.JOB_CONTRIBUTE_CURRANTS, 
					null, 
					qty_picker.value, 
					bt.value.option,
					current_req.id
				);
			}
			else {
				JobManager.instance.sendMessageToServer(
					MessageTypes.JOB_CONTRIBUTE_ITEM, 
					bt.value.class_tsid, 
					qty_picker.value, 
					bt.value.option,
					current_req.id
				);
			}
		}
	}
}