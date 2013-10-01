package com.tinyspeck.engine.view.ui.craftybot
{
	import com.tinyspeck.engine.data.craftybot.CraftyJob;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CraftyDialog;
	import com.tinyspeck.engine.port.CraftyManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.text.TextField;

	public class CraftyJobElementUI extends Sprite
	{
		private static const MIN_HEIGHT:uint = 58;
		private static const ICON_WH:uint = 35;
		private static const PADD:uint = 5;
		private static const TF_PADD:uint = 10;		
		private static const MISSING_ALPHA:Number = .6;
		
		protected var bg_holder:Sprite = new Sprite();
		private var icon_holder:Sprite = new Sprite();
		protected var text_holder:Sprite = new Sprite();
		
		private var warning_icon:DisplayObject;
		private var normal_warning:ColorTransform = new ColorTransform();
		private var less_warning:ColorTransform = ColorUtil.getColorTransform(0xb4b4b4);
		
		protected var name_tf:TextField = new TextField();
		protected var status_tf:TextField = new TextField();
		
		protected var current_job:CraftyJob;
		private var icon_view:ItemIconView;
		protected var remove_bt:Button;
		protected var collect_bt:Button;
		
		private var tip_txt:String;
		
		protected var w:int;
		
		private var is_built:Boolean;
		
		public function CraftyJobElementUI(w:int){
			this.w = w;
		}
		
		private function buildBase():void {			
			//bg
			bg_holder.useHandCursor = bg_holder.buttonMode = true;
			bg_holder.addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			addChild(bg_holder);
			
			//icon
			icon_holder.x = PADD+15;
			icon_holder.mouseEnabled = icon_holder.mouseChildren = false;
			addChild(icon_holder);
			
			//warning icon
			warning_icon = new AssetManager.instance.assets.store_warning();
			warning_icon.x = warning_icon.y = 6;
			addChild(warning_icon);
			
			//tfs
			TFUtil.prepTF(name_tf);
			name_tf.x = icon_holder.x + ICON_WH + PADD*2;
			text_holder.addChild(name_tf);
			
			TFUtil.prepTF(status_tf);
			status_tf.x = name_tf.x;
			text_holder.addChild(status_tf);
			
			text_holder.mouseEnabled = text_holder.mouseChildren = false;
			addChild(text_holder);
			
			//buttons
			const remove_DO:DisplayObject = new AssetManager.instance.assets.mail_trash();
			remove_DO.filters = [ColorUtil.getGreyScaleFilter()];
			remove_bt = new Button({
				name: 'remove',
				graphic: remove_DO,
				draw_alpha: 0,
				w: remove_DO.width + 9,
				h: remove_DO.height + 9,
				tip: {txt:'Remove job', pointer:WindowBorder.POINTER_BOTTOM_CENTER }
			});
			remove_bt.addEventListener(TSEvent.CHANGED, onRemoveClick, false, 0, true);
			
			collect_bt = new Button({
				name: 'collect',
				label: 'Collect 5',
				size: Button.SIZE_TINY,
				type: Button.TYPE_DEFAULT
			});
			collect_bt.addEventListener(TSEvent.CHANGED, onCollectClick, false, 0, true);
			
			is_built = true;
		}
		
		public function show(job:CraftyJob):void {
			if(!job) return;
			if(!is_built) buildBase();
			current_job = job;
			
			//see what our actions are
			setButtons();
			
			//do the text stuff
			setText();
			
			//draw the BG depending on active/complete
			setBackground();
			
			//place the icon there
			setIcon();
			
			//make sure the buttons are in the right spot
			collect_bt.y = int(height/2 - collect_bt.height/2 - 1);
			remove_bt.y = int(height/2 - remove_bt.height/2);
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
		}
		
		protected function setBackground():void {
			var bg_color:uint = 0xf5f5f5; //missing something
			var border_color:uint = 0xcccccc;
			if(current_job.status.is_active){
				bg_color = 0xffffff;
			}
			else if(current_job.status.is_complete){
				bg_color = 0xffffff;
				border_color = 0xb2c68b;
			}
			else if(current_job.status.is_missing){
				bg_color = 0xe7d2d2;
			}
			
			var g:Graphics = bg_holder.graphics;
			g.clear();
			g.beginFill(bg_color);
			g.drawRect(0, 0, w, height);
			g.endFill();
			g.beginFill(border_color);
			g.drawRect(0, height-1, w, 1);
		}
		
		private function setIcon():void {
			//handle the exclimation mark
			warning_icon.visible = current_job.craftable_count < current_job.total && !current_job.status.is_complete;
			warning_icon.transform.colorTransform = current_job.craftable_count == 0 ? normal_warning : less_warning;
			
			//drop the alpha if we are missing lots
			icon_holder.alpha = current_job.craftable_count == 0 && !current_job.status.is_complete ? MISSING_ALPHA : 1;
			icon_holder.y = int(height/2 - ICON_WH/2 - 1);
			
			if(icon_holder.name == current_job.item_class) return;
			
			SpriteUtil.clean(icon_holder);
			icon_view = new ItemIconView(current_job.item_class, ICON_WH);
			icon_holder.addChild(icon_view);
			
			icon_holder.name = current_job.item_class;
		}
		
		protected function setText():void {
			//set the name
			const item:Item = TSModelLocator.instance.worldModel.getItemByTsid(current_job.item_class);
			var name_txt:String = '<p class="crafty_job">';
			if(current_job.status.is_complete) name_txt += '<span class="crafty_job_status_complete">';
			name_txt += '<b>'+current_job.done+'/'+current_job.total+'</b> ';
			
			if(item){
				name_txt += current_job.total > 1 ? item.label_plural : item.label;
			}
			else {
				name_txt += 'Unknown';
			}
			
			if(current_job.status.is_complete) name_txt += '</span>';
			name_txt += '</p>';
			name_tf.htmlText = name_txt;
			name_tf.width = int((collect_bt.parent ? collect_bt.x : remove_bt.x) - name_tf.x - 5);
			
			//set the status
			var set_status:Boolean;
			var status_txt:String = '<p class="crafty_job_status">';
			
			if(current_job.status.is_complete){
				status_txt += '<span class="crafty_job_status_complete">Job Complete!</span>';
				set_status = true;
			}
			else if(current_job.status.is_halted){
				status_txt += '<span class="crafty_job_status_missing">Job Halted!</span>';
				set_status = true;
			}
			else if(current_job.craftable_count == 0 && !current_job.status.is_complete){
				status_txt += '<span class="crafty_job_status_missing">Missing Ingredient(s)</span>';
				set_status = true;
			}
			
			status_txt += '</p>';
			status_tf.htmlText = status_txt;
			status_tf.y = set_status ? int(name_tf.y + name_tf.height - 4) : 0;
			status_tf.width = name_tf.width;
			
			text_holder.y = int(height/2 - text_holder.height/2 - 1);
		}
		
		protected function setButtons():void {
			//if we have nothing to take, show the remove button
			if(remove_bt.parent) remove_bt.parent.removeChild(remove_bt);
			if(collect_bt.parent) collect_bt.parent.removeChild(collect_bt);
			
			if(!current_job.done){
				//show the remove button
				remove_bt.x = int(w - remove_bt.width - 25);
				remove_bt.disabled = false;
				addChild(remove_bt);
			}
			else if(current_job.done){
				//show the collect button
				collect_bt.label = 'Collect '+current_job.done;
				collect_bt.x = int(w - collect_bt.width - 25);
				collect_bt.disabled = false;
				addChild(collect_bt);
			}
		}
		
		private function onClick(event:MouseEvent):void {
			if(!current_job) return;
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			CraftyDialog.instance.showDetails(current_job.item_class);
		}
		
		private function onRemoveClick(event:TSEvent):void {
			SoundMaster.instance.playSound(!remove_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(remove_bt.disabled) return;
			remove_bt.disabled = true;
			
			//tell the server we want to axe the job
			CraftyManager.instance.removeJob(current_job.item_class, current_job.total);
		}
		
		private function onCollectClick(event:TSEvent):void {
			SoundMaster.instance.playSound(!collect_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(collect_bt.disabled) return;
			collect_bt.disabled = true;
			
			//collect what is done
			CraftyManager.instance.removeJob(current_job.item_class, current_job.done);
		}
		
		override public function get height():Number {
			return Math.max(MIN_HEIGHT, int(text_holder.height + TF_PADD*2));
		}
	}
}