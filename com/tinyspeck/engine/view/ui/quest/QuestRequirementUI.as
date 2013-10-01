package com.tinyspeck.engine.view.ui.quest
{
	import com.tinyspeck.engine.data.requirement.Requirement;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class QuestRequirementUI extends Sprite implements ITipProvider
	{
		public static const ICON_SIZE:int = 23;
		public static const ICON_PADDING:int = 5;
		private static const COMPLETE_ALPHA:Number = .5;
		private static const GREYSCALE_FILTER:Array = [ColorUtil.getGreyScaleFilter()];
		
		private var current_req:Requirement;
		private var req_icon:ItemIconView;
		
		private var icon_holder:Sprite = new Sprite();
		private var default_icon:DisplayObject;
		private var complete_icon:DisplayObject;
		
		private var tf:TextField = new TextField();
		
		private var _w:int;
		
		public function QuestRequirementUI(){
			TFUtil.prepTF(tf, false);
			tf.x = ICON_PADDING + ICON_SIZE + 3;
			addChild(tf);
			
			//icon holder
			icon_holder.x = icon_holder.y = ICON_PADDING;
			addChild(icon_holder);
			
			//complete icon
			complete_icon = new AssetManager.instance.assets.quest_requirement_complete();
			complete_icon.y = ICON_SIZE + ICON_PADDING*2 - complete_icon.height + 2;
			addChild(complete_icon);
			
			//setup the mouse
			mouseChildren = false;
		}
		
		public function show(req:Requirement):void {
			current_req = req;
			
			//show the icons
			setIcons();
			
			//show the text
			setText();
			
			//draw the bg
			draw();
			
			TipDisplayManager.instance.registerTipTrigger(this);
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
			TipDisplayManager.instance.unRegisterTipTrigger(this);
		}
		
		private function setIcons():void {
			SpriteUtil.clean(icon_holder);
			
			//put the task/item icon there
			if(current_req.item_class){
				req_icon = new ItemIconView(current_req.item_class, ICON_SIZE);
				icon_holder.addChild(req_icon);
			}
			else {
				if(!default_icon) default_icon = new AssetManager.instance.assets.quest_requirement();
				icon_holder.addChild(default_icon);
			}
			
			//is the requirement complete?
			complete_icon.visible = current_req.completed;
			icon_holder.filters = current_req.completed ? GREYSCALE_FILTER : null;
		}
		
		private function setText():void {
			var req_txt:String = '';
			
			if(current_req.is_count){
				//show the 0/3 text
				req_txt = '<span class="quest_dialog_requirements">'+
						  '<span class="quest_dialog_requirements_got">'+current_req.got_num+'</span>/'+
						  '<span class="quest_dialog_requirements_need">'+current_req.need_num+'</span>'+
						  '</span>';
			}
			else {
				//no count means different style of text
				req_txt = '<span class="quest_dialog_requirements_task'+(current_req.completed ? '_complete' : '')+'">'+current_req.desc+'</span>';
			}
			
			tf.htmlText = req_txt;
			tf.alpha = !current_req.completed ? 1 : COMPLETE_ALPHA;
			tf.y = int(ICON_SIZE/2 - tf.height/2) + ICON_PADDING + (current_req.is_count ? 1 : 0);
		}
		
		private function draw():void {
			_w = tf.x + tf.width + ICON_PADDING*2;
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0xdbdbdb, current_req.completed ? .6 : 0);
			g.drawRoundRect(0, 0, _w, height, 12);
			
			//move the completed icon to where it needs to go
			complete_icon.x = int(_w - complete_icon.width + 2);
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target || !current_req || !current_req.is_count) return null;
			
			return {
				txt: current_req.desc,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
		
		override public function get width():Number { return _w; }
		override public function get height():Number { return ICON_SIZE + ICON_PADDING*2; }
	}
}