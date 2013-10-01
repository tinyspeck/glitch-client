package com.tinyspeck.engine.view.ui.craftybot
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.data.craftybot.CraftyComponent;
	import com.tinyspeck.engine.data.craftybot.CraftyJob;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CraftyDialog;
	import com.tinyspeck.engine.port.CraftyManager;
	import com.tinyspeck.engine.port.QuantityPicker;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.CandyCane;
	import com.tinyspeck.engine.view.ui.TSScroller;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;

	public class CraftyJobDetailsUI extends Sprite
	{
		private static const HEADER_H:uint = 68;
		private static const HEADER_EDIT_H:uint = 80;
		private static const STATUS_H:uint = 22;
		private static const PADD:uint = 15;
		private static const TEXT_PADD:uint = 17;
		private static const HALTED_PADD:uint = 25;
		private static const MAX_QUANTITY:uint = 999;
		
		private var header_holder:Sprite = new Sprite();
		private var status_holder:Sprite = new Sprite();
		private var padder:Shape = new Shape();
		
		private var qty_tf:TextField = new TextField();
		private var status_tf:TextField = new TextField();
		private var fuel_tf:TextField = new TextField();
		private var complete_tf:TextField = new TextField();
		private var count_tf:TextField = new TextField();
		
		private var edit_rect:Rectangle;
		private var greyscale_filterA:Array = [ColorUtil.getGreyScaleFilter()];
		private var play_icon:DisplayObject;
		private var play_icon_hover:DisplayObject;
		private var pause_icon:DisplayObject;
		private var pause_icon_hover:DisplayObject;
		
		private var icon_view:ItemIconView;
		private var qp:QuantityPicker;
		private var add_bt:Button;
		private var remove_bt:Button;
		private var edit_bt:Button;
		private var pause_bt:Button;
		private var components:Vector.<CraftyComponentUI> = new Vector.<CraftyComponentUI>();
		private var scroller:TSScroller;
		private var complete_ui:CraftyJobDetailsCompleteUI;
		private var halted_ui:CraftyJobDetailsHaltedUI;
		private var candy_cane:CandyCane;
		
		private var current_item:String;
		
		private var pause_tip:Object;
		private var add_tip:Object;
		
		private var is_built:Boolean;
		
		private var w:int;
		private var scroller_y:int;
		
		public function CraftyJobDetailsUI(w:int){
			this.w = w;
		}
		
		private function buildBase():void {			
			//head
			addChild(header_holder);
			
			//status
			addChild(status_holder);
			
			TFUtil.prepTF(status_tf, false);
			status_tf.htmlText = '<p class="crafty_job_details_status">PLACEHOLDER</p>';
			status_tf.x = TEXT_PADD;
			status_tf.y = int(STATUS_H/2 - status_tf.height/2 + 1);
			status_holder.addChild(status_tf);
			
			//complete
			TFUtil.prepTF(complete_tf, false);
			complete_tf.htmlText = '<p class="crafty_job_details_complete">Job Complete!</p>';
			complete_tf.x = int(w/2 - complete_tf.width/2);
			complete_tf.y = int(HEADER_H/2 - complete_tf.height/2);
			complete_tf.filters = StaticFilters.copyFilterArrayFromObject({distance:2, alpha:1}, StaticFilters.white1px90Degrees_DropShadowA);
			complete_tf.cacheAsBitmap = true;
			header_holder.addChild(complete_tf);
			
			//complete footer
			complete_ui = new CraftyJobDetailsCompleteUI(w);
			
			//quantity
			qp = new QuantityPicker({
				w: 83,
				h: 33,
				name: 'qp',
				minus_graphic: new AssetManager.instance.assets.minus_red(),
				plus_graphic: new AssetManager.instance.assets.plus_green(),
				max_value: MAX_QUANTITY,
				min_value: 1,
				button_wh: 20,
				button_padd: 3,
				show_all_option: false
			});
			qp.visible = false;
			qp.x = TEXT_PADD;
			qp.y = TEXT_PADD;
			qp.addEventListener(TSEvent.CHANGED, onQuantityChange, false, 0, true);
			header_holder.addChild(qp);
			
			//fuel
			TFUtil.prepTF(fuel_tf, false);
			fuel_tf.x = TEXT_PADD;
			fuel_tf.y = int(qp.y + qp.height + 1);
			header_holder.addChild(fuel_tf);
			
			//count
			TFUtil.prepTF(count_tf);
			count_tf.wordWrap = false;
			count_tf.x = TEXT_PADD;
			header_holder.addChild(count_tf);
			
			//buttons
			add_bt = new Button({
				name: 'add',
				label: '+ Add to Queue',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR,
				h: qp.height+1
			});
			add_bt.addEventListener(TSEvent.CHANGED, onAddClick, false, 0, true);
			add_bt.x = int(w - add_bt.width - TEXT_PADD);
			add_bt.y = TEXT_PADD-1;
			header_holder.addChild(add_bt);
			
			//tooltip for when it's disabled
			add_tip = {txt:'Your Craftybot\'s queue is full!', pointer:WindowBorder.POINTER_BOTTOM_CENTER};
			
			const pause_wh:uint = 45;
			pause_bt = new Button({
				name: 'pause',
				size: Button.SIZE_CIRCLE,
				type: Button.TYPE_DEFAULT,
				w: pause_wh,
				h: pause_wh
			});
			pause_bt.x = int(w - pause_wh - TEXT_PADD + 4);
			pause_bt.addEventListener(TSEvent.CHANGED, onPauseClick, false, 0, true);
			header_holder.addChild(pause_bt);
			
			//setup the icons for the pause button
			play_icon = new AssetManager.instance.assets.play_icon();
			play_icon_hover = new AssetManager.instance.assets.play_icon_hover();
			pause_icon = new AssetManager.instance.assets.pause_icon();
			pause_icon_hover = new AssetManager.instance.assets.pause_icon_hover();
			pause_tip = {txt:'Pause', pointer:WindowBorder.POINTER_BOTTOM_CENTER};
			
			const remove_DO:DisplayObject = new AssetManager.instance.assets.mail_trash_red();
			remove_bt = new Button({
				name: 'remove',
				graphic: remove_DO,
				graphic_hover: new AssetManager.instance.assets.mail_trash_read_hover(),
				graphic_padd_w: 7,
				size: Button.SIZE_TINY,
				type: Button.TYPE_CANCEL,
				w: remove_DO.width + 13,
				h: remove_DO.height + 13
			});
			remove_bt.tip = {txt:'Remove', pointer:WindowBorder.POINTER_BOTTOM_CENTER};
			remove_bt.x = int(pause_bt.x - remove_bt.width - 10);
			remove_bt.addEventListener(TSEvent.CHANGED, onRemoveClick, false, 0, true);
			header_holder.addChild(remove_bt);
			
			const edit_DO:DisplayObject = new AssetManager.instance.assets.edit_icon();
			edit_bt = new Button({
				name: 'edit',
				graphic: edit_DO,
				graphic_hover: new AssetManager.instance.assets.edit_icon_hover(),
				draw_alpha: 0,
				w: edit_DO.width,
				h: edit_DO.height
			});
			edit_bt.tip = {txt:'Edit', pointer:WindowBorder.POINTER_BOTTOM_CENTER};
			edit_bt.addEventListener(TSEvent.CHANGED, onEditClick, false, 0, true);
			header_holder.addChild(edit_bt);
			
			//components
			scroller = new TSScroller({
				name: '_scroller',
				bar_wh: 16,
				bar_alpha: 1,
				w: w,
				bar_handle_min_h: 50,
				body_color: 0x00cc00,
				body_alpha: 0,
				use_children_for_body_h: true
			});
			addChild(scroller);
			
			//halted
			halted_ui = new CraftyJobDetailsHaltedUI(w - HALTED_PADD*2);
			halted_ui.x = HALTED_PADD;
			
			//padder
			var g:Graphics = padder.graphics;
			g.beginFill(0,0);
			g.drawRect(0, 0, 1, 10);
			scroller.body.addChild(padder);
			
			//candy cane to move behind the active element
			candy_cane = new CandyCane(w, 10, 14, .25, .4, 0xffffff, 0xe2e6e7);
			
			is_built = true;
		}
		
		public function show(item_class:String):void {
			if(!is_built) buildBase();
			
			scroller_y = 0;
			current_item = item_class;
			const cm:CraftyManager = CraftyManager.instance;
			
			//set the qp default
			const job:CraftyJob = cm.getJobByItem(current_item);
			if(job){
				toggleLock(job.status.is_locked);
				togglePause(job.status.is_paused);
			}
			else {
				qp.value = 1;
			}
			
			//get more info about it if we need to
			if(job == null && (!cm.job_cost_req || cm.job_cost_req.item_class != item_class)){
				cm.costCheck(item_class, 1);
			}
			
			//make sure all is good
			refresh();
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
			
			if(!is_built) return;
			complete_ui.hide();
			halted_ui.hide();
		}
		
		public function toggleLock(is_locked:Boolean, and_refresh:Boolean = true):void {
			const cm:CraftyManager = CraftyManager.instance;
			const job:CraftyJob = cm.getJobByItem(current_item);
			
			qp.min_value = job ? Math.max(job.done, 1) : 1;
			qp.max_value = Math.min(cm.jobs_max-cm.jobs_count+(job ? job.total : 0), MAX_QUANTITY);
			
			if(!qp.visible){
				//set the default value
				qp.value = job ? Math.max(job.total, 1) : 1;
			}
			
			qp.visible = is_locked;
			fuel_tf.visible = is_locked;
			
			//if we are showing the qp, let's let a click that isn't on it, submit the value
			if(is_locked && job){
				StageBeacon.mouse_click_sig.add(onStageClick);
			}
			
			if(and_refresh) refresh();
		}
		
		public function togglePause(is_pause:Boolean):void {
			pause_bt.value = !is_pause;
			pause_bt.disabled = false;
			
			//set the type
			pause_bt.type = is_pause ? Button.TYPE_DEFAULT : Button.TYPE_MINOR;
			
			//set the right graphics
			pause_bt.setGraphic(is_pause ? play_icon : pause_icon, false);
			pause_bt.setGraphic(is_pause ? play_icon_hover : pause_icon_hover, true);
			
			//set the tooltip
			pause_tip.txt = is_pause ? 'Resume' : 'Pause';
			pause_bt.tip = pause_tip;
		}
		
		public function refresh():void {
			if(!is_built) return;
			
			const cm:CraftyManager = CraftyManager.instance;
			const job:CraftyJob = cm.getJobByItem(current_item);
			
			//should we show the qp out of the gate?
			if(!job && cm.job_cost_req && cm.job_cost_req.item_class == current_item){
				toggleLock(true, false);
			}
			
			//set the status
			setStatus();
			
			//set the components
			setComponents();
			
			//toggle button states
			add_bt.visible = job == null;
			add_bt.disabled = cm.jobs_count == cm.jobs_max;
			add_bt.tip = add_bt.disabled ? add_tip : null;
			pause_bt.visible = job && !job.status.is_complete;
			remove_bt.visible = pause_bt.visible;
			
			const scroll_y:int = int(status_holder.y + status_holder.height);
			var scroll_h:int = CraftyDialog.BODY_H - scroll_y - 2;
			
			//is the job done?
			if(job && (job.status.is_complete || job.done > 0)){
				complete_ui.show(job);
				scroll_h -= complete_ui.height;
				complete_ui.y = scroll_y + scroll_h;
				addChild(complete_ui);
			}
			else if(complete_ui.parent){
				complete_ui.hide();
			}
			
			//move stuff
			scroller.y = scroll_y;
			scroller.h = scroll_h;
			
			//draw the BG
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRect(0, scroll_y, w, scroll_h);
		}
		
		private function setStatus():void {
			const job:CraftyJob = CraftyManager.instance.getJobByItem(current_item);
			var bg_color:uint = 0x4e595a;
			var top_color:uint = 0x465051;
			var bottom_color:uint = 0x6c7f80;
			var g:Graphics = status_holder.graphics;
			
			//if the job is halted, we color it different
			if(job && job.status.is_halted && !job.status.is_complete){
				bg_color = 0x933536;
				top_color = 0x843030;
				bottom_color = 0xc14444;
			}
			
			g.clear();
			g.beginFill(bg_color);
			g.drawRect(0, 0, w, STATUS_H);
			g.beginFill(top_color); //top bar
			g.drawRect(0, 0, w, 2);
			g.beginFill(bottom_color); //bottom bar
			g.drawRect(0, STATUS_H-1, w, 1);
			
			//set the text
			var status_txt:String = '<p class="crafty_job_details_status">';
			if(job){
				//put whatever is in the txt param of the status
				status_txt += String(job.status.txt || 'Confabulating thingies').toUpperCase();
			}
			else {
				//we must be checking the cost
				status_txt += String('To make '+(qp.value > 1 ? 'these' : 'this')+' I\'ll need to...').toUpperCase();
			}
			status_txt += '</p>';
			status_tf.htmlText = status_txt;
			
			//draw the header
			const draw_h:uint = qp.visible ? HEADER_EDIT_H : HEADER_H;
			g = header_holder.graphics;
			g.beginFill(job && job.status.is_complete ? 0xeff4d8 : 0xebebeb);
			g.drawRect(0, 0, w, draw_h);
			g.beginFill(0xcccccc);
			g.drawRect(0, draw_h-1, w, 1);
			status_holder.y = draw_h;
			
			//show the complete text
			complete_tf.visible = job && job.status.is_complete;
			
			//how many do we have going?
			count_tf.visible = job && !job.status.is_complete && !job.status.is_locked;
			edit_bt.visible = count_tf.visible;
			if(count_tf.visible){
				var count_txt:String = '<p class="crafty_job_details_count">';
				count_txt += '<span class="crafty_job_details_count_done">';
				if(job && job.status.is_halted) count_txt += '<span class="crafty_job_details_count_halted">';
				count_txt += (job.total-job.done);
				if(job && job.status.is_halted) count_txt += '</span>';
				count_txt += '</span>';
				count_txt += '<span class="crafty_job_details_count_total">/'+job.total+'</span>';
				count_txt += '<br>Remaining';
				count_txt += '</p>';
				count_tf.htmlText = count_txt;
				count_tf.y = int(draw_h/2 - count_tf.height/2 - 2);
				
				//move the edit button to where it has to go
				edit_rect = count_tf.getCharBoundaries(count_tf.text.indexOf('Remaining')-2);
				if(edit_rect){
					edit_bt.x = int(count_tf.x + edit_rect.x + edit_rect.width + 8);
				}
				else {
					//just throw it to the right of the entire tf
					edit_bt.x = int(count_tf.x + count_tf.width + 5);
				}
				
				edit_bt.y = int(count_tf.y + 17);
			}
			
			//place action buttons
			pause_bt.y = int(draw_h/2 - pause_bt.height/2);
			remove_bt.y = int(draw_h/2 - remove_bt.height/2);
		}
		
		private function setComponents():void {			
			var total:uint = components.length;
			var i:int;
			var component:CraftyComponent;
			var component_ui:CraftyComponentUI;
			var next_y:int = PADD - 4;
			var is_halted:Boolean;
			var showing_candy_cane:Boolean;
			
			//reset pool
			for(i = 0; i < total; i++){
				components[int(i)].hide();
			}
			
			//get the job and show the goods
			const job:CraftyJob = CraftyManager.instance.job_cost_req || CraftyManager.instance.getJobByItem(current_item);
			if(!job) return;
			
			//set the fuel if we need to
			if(qp.visible){
				var fuel_txt:String = '<p class="crafty_job_details_fuel">';
				fuel_txt += 'Uses: '+job.fuel_cost+' Fuel';
				fuel_txt += '</p>';
				fuel_tf.htmlText = fuel_txt;
			}
			
			//get current scroll spot
			scroller_y = scroller.scroll_y;
			
			//reset halted
			halted_ui.hide();
			
			//show em
			total = job.components.length;
			for(i = 0; i < total; i++){
				component = job.components[int(i)];				
				if(i > total){
					component_ui = components[int(i)];
				}
				else {
					component_ui = new CraftyComponentUI(w);
					components.push(component_ui);
				}
				
				component_ui.show(component, is_halted);
				component_ui.y = next_y;
				
				//set the scroll y to this if it's the active one
				if(component.status == CraftyComponent.STATUS_ACTIVE){
					scroller_y = next_y;
					
					//show the candy cane
					showing_candy_cane = true;
					candy_cane.height = component_ui.height;
					if(candy_cane.parent){
						//animate it to the new place
						TSTweener.removeTweens(candy_cane);
						TSTweener.addTween(candy_cane, {y:next_y, time:.4});
					}
					else {
						//add it to the body
						scroller.body.addChild(candy_cane);
						candy_cane.y = next_y;
					}
				}
				
				next_y += component_ui.height;
				scroller.body.addChild(component_ui);
				
				//make sure the next one knows if we are halted or not
				if(component.status == CraftyComponent.STATUS_HALTED){
					is_halted = true;
					
					//build the halted ui
					halted_ui.show(component.status_txt);
				}
			}			
			
			//place the halted message after everything if we need to
			if(is_halted){
				halted_ui.y = next_y + 10;
				next_y += halted_ui.height + 10;
				scroller.body.addChild(halted_ui);
			}
			
			//little padding to the bottom
			padder.y = next_y;
			
			//hide the candy cane if we need to
			candy_cane.animate(showing_candy_cane);
			if(!showing_candy_cane && candy_cane.parent){
				candy_cane.parent.removeChild(candy_cane);
			}
			
			//put the scroller where it should go
			//scroller.scrollYToTop(scroller_y);
		}
		
		private function onQuantityChange(event:TSEvent = null):void {
			//get the cost of this sucker
			if(qp.visible){
				CraftyManager.instance.costCheck(current_item, qp.value);
			}
		}
		
		private function onStageClick(event:MouseEvent):void {
			//if we didn't hit the QP, then release the lock on this
			if(!qp.contains(event.target as DisplayObject)){
				CraftyManager.instance.lockJob(false, current_item);
				StageBeacon.mouse_click_sig.remove(onStageClick);
				
				//axe the price check
				CraftyManager.instance.job_cost_req = null;
				
				//figure out if we need to change the job's total
				const job:CraftyJob = CraftyManager.instance.getJobByItem(current_item);
				if(job && job.total > qp.value){
					//remove
					CraftyManager.instance.removeJob(current_item, job.total - qp.value);
				}
				else {
					//need to add
					CraftyManager.instance.addJob(current_item, qp.value);
				}
			}
		}
		
		private function onAddClick(event:TSEvent):void {
			SoundMaster.instance.playSound(!add_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(add_bt.disabled) return;
			add_bt.disabled = true;
			
			//let's add/change!
			CraftyManager.instance.addJob(current_item, qp.value);
		}
		
		private function onRemoveClick(event:TSEvent):void {
			SoundMaster.instance.playSound(!remove_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			const job:CraftyJob = CraftyManager.instance.getJobByItem(current_item);
			if(remove_bt.disabled || !job) return;
			
			//let's remove stuff
			CraftyManager.instance.removeJob(current_item, job.total);
		}
		
		private function onEditClick(event:TSEvent):void {
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			//tell the server we are locking this job so we can make changes
			CraftyManager.instance.lockJob(true, current_item);
		}
		
		private function onPauseClick(event:TSEvent):void {
			SoundMaster.instance.playSound(!pause_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(pause_bt.disabled) return;
			pause_bt.disabled = true;
			
			//tell the server we are pausing/resuming
			CraftyManager.instance.pauseJob(pause_bt.value === true, current_item);
		}
		
		public function get item_class():String { return current_item; }
	}
}