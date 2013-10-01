package com.tinyspeck.engine.view.ui.craftybot
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.craftybot.CraftyComponent;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.net.NetOutgoingLocalChatVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.text.TextField;
	import flash.ui.Keyboard;

	public class CraftyComponentUI extends Sprite implements ITipProvider
	{
		private static const ICON_PADD:uint = 2;
		private static const ICON_WH:uint = 15;
		private static const DISABLED_ALPHA:Number = .4;
		
		private var icon_holder:Sprite = new Sprite();
		private var warning_holder:Sprite = new Sprite();
		
		private var task_tf:TextField = new TextField();
		
		private var checkmark_icon:DisplayObject;
		private var warning_icon:DisplayObject;
		
		private var normal_warning:ColorTransform = new ColorTransform();
		private var less_warning:ColorTransform = ColorUtil.getColorTransform(0xb4b4b4);
		
		private var current_component:CraftyComponent;
		
		private var w:int;
		
		private var is_built:Boolean;
		
		public function CraftyComponentUI(w:int){
			this.w = w;
		}
		
		public function buildBase():void {
			//icons
			icon_holder.x = 15;
			addChild(icon_holder);
			
			//tf
			TFUtil.prepTF(task_tf);
			task_tf.y = 3;
			addChild(task_tf);
			
			//checkmark icon
			checkmark_icon = new AssetManager.instance.assets.checkmark_crafty();
			checkmark_icon.y = 3;
			
			//warning icon
			warning_icon = new AssetManager.instance.assets.store_warning();
			warning_icon.y = 3;
			warning_holder.addChild(warning_icon);
			
			//mouse stuff
			CONFIG::god {
				addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			}
			
			is_built = true;
		}
		
		public function show(component:CraftyComponent, force_disable:Boolean):void {
			if(!component) return;
			
			if(!is_built) buildBase();
			current_component = component;
			
			//show any icons we need to show
			setIcons(force_disable);
			
			//set the task text
			setText(force_disable);
			
			//set the BG
			setBackground();
			
			//listen
			TipDisplayManager.instance.registerTipTrigger(warning_holder);
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
			TipDisplayManager.instance.unRegisterTipTrigger(warning_holder);
		}
		
		private function setIcons(force_disable:Boolean):void {
			SpriteUtil.clean(icon_holder);
			
			const total:uint = current_component.item_classes.length;
			const warn_padd:uint = 8;
			var i:int;
			var icon:ItemIconView;
			var next_x:int;
			var chunks:Array;
			
			//reset the alpha
			icon_holder.alpha = !force_disable ? 1 : DISABLED_ALPHA;
			
			//if the task is done, add the checkmark
			if(current_component.status == CraftyComponent.STATUS_COMPLETE){
				icon_holder.addChild(checkmark_icon);
				next_x += checkmark_icon.width + warn_padd;
			}
			else if(checkmark_icon.parent){
				//remove it
				checkmark_icon.parent.removeChild(checkmark_icon);
			}
			
			//we have a warning?
			if(current_component.status == CraftyComponent.STATUS_HALTED){
				icon_holder.addChild(warning_holder);
				warning_icon.transform.colorTransform = normal_warning;
				next_x += warning_icon.width + warn_padd;
			}
			else if(warning_holder.parent){
				//remove it
				warning_holder.parent.removeChild(warning_holder);
			}
			
			for(i; i < total; i++){
				//if the count is 0, that means we can't even make it because of missing components before this
				if(current_component.counts_missing[int(i)] > 0 && !warning_holder.parent && current_component.status != CraftyComponent.STATUS_COMPLETE){
					icon_holder.addChild(warning_holder);
					warning_icon.transform.colorTransform = current_component.can_start ? less_warning : normal_warning;
					next_x += warning_icon.width + 8;
				}
				
				//always show the icon of the first element in the array
				chunks = String(current_component.item_classes[int(i)]).split('|');
				icon = new ItemIconView(chunks[0], ICON_WH);
				icon.x = next_x;
				next_x += ICON_WH + ICON_PADD;
				icon_holder.addChild(icon);
				
				//drop the alpha
				if(current_component.counts_missing[int(i)] == 0 && !current_component.can_start){
					icon_holder.alpha = DISABLED_ALPHA;
				}
			}
			
			//do we have a tool?
			if(current_component.tool_class){
				icon = new ItemIconView(current_component.tool_class, ICON_WH);
				icon.x = next_x;
				next_x += ICON_WH + ICON_PADD;
				icon_holder.addChild(icon);
			}
		}
		
		private function setText(force_disable:Boolean):void {
			const world:WorldModel = TSModelLocator.instance.worldModel;
			const is_missing:Boolean = (current_component.status == CraftyComponent.STATUS_MISSING 
									   || current_component.status == CraftyComponent.STATUS_HALTED)
									   && !current_component.can_start;
			const is_complete:Boolean = current_component.status == CraftyComponent.STATUS_COMPLETE;
			var chunks:Array;
			var item:Item;
			var i:int;
			var count:int;
			var total:uint = current_component.item_classes.length;
			var task_txt:String = '<p class="crafty_component">';
			if(is_missing) {
				task_txt += '<span class="crafty_component_missing">';
			}
			else if(is_complete){
				task_txt += '<span class="crafty_component_complete">';
			}
			
			switch(current_component.type){
				case CraftyComponent.TYPE_FETCH:
					task_txt += 'Fetch ';
					break;
				case CraftyComponent.TYPE_CRAFT:
					task_txt += 'Craft ';
					break;
			}
			
			//reset the alpha
			task_tf.alpha = !force_disable ? 1 : DISABLED_ALPHA;
			
			//loop through all the items
			for(i = 0; i < total; i++){
				chunks = String(current_component.item_classes[int(i)]).split('|');
				item = world.getItemByTsid(chunks[0]);
				count = current_component.counts[int(i)];
				if(item){
					if(count > 1){
						task_txt += '<b>'+StringUtil.formatNumberWithCommas(count)+'</b> ';
					}
					
					if(count > 1 || current_component.status == CraftyComponent.STATUS_COMPLETE){
						task_txt += (count != 1 ? item.label_plural : item.label);
					}
					else if(count == 1){
						task_txt += item.label;
					}
					else {
						//this is when it's disabled, so drop the count
						task_txt += item.label_plural;
					}
					
					if(chunks.length > 1){
						//this means more than 1 tool will work usually
						task_txt += ' of some sort';
					}
					
					if(current_component.counts_missing[int(i)] > 0){
						task_txt += ' <span class="crafty_component_missing_count">';
						task_txt += '(Missing&nbsp;'+StringUtil.formatNumberWithCommas(current_component.counts_missing[int(i)])+')';
						task_txt += '</span>';
					}
				}
				else {
					task_txt += 'something or other';
				}
				
				if(i < total-1) task_txt += ', ';
				
				//drop the alpha
				if(current_component.counts_missing[int(i)] == 0 && !current_component.can_start){
					task_tf.alpha = DISABLED_ALPHA;
				}
			}
			
			if(is_missing || is_complete) task_txt += '</span>';
			task_txt += '</p>';
			task_tf.htmlText = task_txt;
			task_tf.x = int(icon_holder.x + icon_holder.width + 5);
			task_tf.width = w - task_tf.x - 15; //-15 for the scroller
		}
		
		private function setBackground():void {
			var bg_color:int = 0;
			var bg_alpha:Number = 0;
			if(current_component.status == CraftyComponent.STATUS_HALTED){
				bg_color = 0xf4e0da;
				bg_alpha = 1;
			}
			
			const draw_h:uint = task_tf.height + task_tf.y*2;
			const g:Graphics = graphics;
			g.clear();
			g.beginFill(bg_color, bg_alpha);
			g.drawRect(0, 0, w, draw_h);
			
			//move the icons
			icon_holder.y = int(draw_h/2 - ICON_WH/2);
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target || !current_component || !current_component.status_txt) return null;
			
			return {
				txt: current_component.status_txt,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
		
		CONFIG::god {
			private function onClick(event:MouseEvent):void {
				//if we are pressing the control button, let's throw things on the ground
				if(KeyBeacon.instance.pressed(Keyboard.CONTROL) && current_component.type == CraftyComponent.TYPE_FETCH){
					const chunks:Array = String(current_component.item_classes[0]).split('|');
					const count:int = current_component.counts_missing[0];
					if(count){
						TSFrontController.instance.sendLocalChat(
							new NetOutgoingLocalChatVO('/create item '+chunks[0]+' '+count)
						);
					}
				}
			}
		}
	}
}