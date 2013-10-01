package com.tinyspeck.engine.view.ui.quest
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.data.quest.Quest;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.TFUtil;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class QuestListUI extends TSSpriteWithModel
	{		
		private var elements:Vector.<QuestElementUI> = new Vector.<QuestElementUI>();
		private var dividers:Vector.<Sprite> = new Vector.<Sprite>();
		
		private var no_quests_holder:Sprite = new Sprite();
		private var element_holder:Sprite = new Sprite();
		
		private var border_color:uint = 0xe2e2e2;
		private var border_width:int = 1;
		
		private var is_built:Boolean;
		private var first_build:Boolean;
		
		public function QuestListUI(w:int, h:int){
			_w = w;
			_h = h;
		}
		
		private function buildBase():void {
			//if they have no quests show them a message
			const no_quests:DisplayObject = new AssetManager.instance.assets.no_sign();
			const no_quests_tf:TextField = new TextField();
			
			TFUtil.prepTF(no_quests_tf, false);
			no_quests_tf.htmlText = '<p class="quest_dialog_no_quests">All quests are complete!</p>';
			no_quests_tf.y = int(no_quests.height) + 12;
			
			no_quests_holder.addChild(no_quests_tf);
			
			no_quests.x = int(no_quests_tf.width/2 - no_quests.width/2);
			no_quests_holder.addChild(no_quests);
			
			no_quests_holder.x = int(_w/2 - no_quests_holder.width/2) + 2;
			no_quests_holder.y = int(_h/2 - no_quests_holder.height/2);
			
			addChild(no_quests_holder);
			
			//set the divider color
			border_color = CSSManager.instance.getUintColorValueFromStyle('quest_list', 'borderColor', border_color);
			border_width = CSSManager.instance.getNumberValueFromStyle('quest_list', 'borderWidth', border_width);
			
			//elements
			addChild(element_holder);
			
			is_built = true;
		}
		
		public function show():void {
			if(!is_built) buildBase();
			
			visible = true;
			no_quests_holder.visible = model.worldModel.quests.length ? false : true;
			
			//build out the list of quests
			showQuests();
		}
		
		public function hide():void {
			visible = false;
		}
		
		public function update(quest_id:String = null):void {
			if(!visible) return;
			
			//get the element to update if we need to
			var element:QuestElementUI = quest_id ? getElementByQuestId(quest_id) : null;
			if(element) element.update();
			
			//refresh the elements
			var i:int;
			var total:int = dividers.length;
			var divider:Sprite;
			var next_y:int;
			var g:Graphics;
			
			//clear the dividers
			for(i = 0; i < total; i++){
				divider = dividers[int(i)];
				if(divider.parent) divider.parent.removeChild(divider);
			}
			
			//show the quests
			total = element_holder.numChildren;
			for(i = 0; i < total; i++){
				element = element_holder.getChildAt(i) as QuestElementUI;
				element.y = next_y;
				
				next_y += element.height;
				
				//put a divider on
				if(i < total-1){
					if(dividers.length > i){
						divider = dividers[int(i)];
					}
					else {
						divider = new Sprite();
						g = divider.graphics;
						g.beginFill(border_color);
						g.drawRect(0, 0, _w, border_width);
						dividers.push(divider);
					}
					
					divider.y = int(element.height - border_width);
					element.addChild(divider);
				}
			}
		}
		
		public function getElementByQuestId(quest_id:String):QuestElementUI {
			const total:int = element_holder.numChildren;
			var i:int;
			var element:QuestElementUI;
			
			for(i = 0; i < total; i++){
				element = element_holder.getChildAt(i) as QuestElementUI;
				if(element.name == quest_id) return element;
			}
			
			return null;
		}
		
		private function showQuests():void {
			var i:int;
			var total:int = elements.length;
			var element:QuestElementUI;
			var quest:Quest;
			
			//reset the pool
			for(i = 0; i < total; i++){
				element = elements[int(i)];
				element.hide();
				element.y = 0;
			}
			
			//show the quests
			total = model.worldModel.quests.length;
			for(i = 0; i < total; i++){
				quest = model.worldModel.quests[int(i)];
				
				//if the quest hasn't been accepted yet, don't show it in the list
				if(!quest.accepted && !quest.offer_conversation_active) continue;
				
				if(elements.length > i){
					element = elements[int(i)];
				}
				else {
					element = new QuestElementUI(_w);
					elements.push(element);
				}
				
				//gives a little delay to each one so it doesn't choke building a lot of them
				StageBeacon.setTimeout(showElement, (i*50)+50, element, quest);
				//element.show(quest);
				element_holder.addChild(element);
			}
			
			update();
		}
		
		private function showElement(element:QuestElementUI, quest:Quest):void {
			//show the element and then update the layout
			element.show(quest);
			
			if(element_holder.contains(element) && element_holder.getChildIndex(element) == element_holder.numChildren-1){
				//this is the last one to load, so we can safely highlight the quest now
				first_build = true;
			}
			
			update();
		}
		
		public function get loaded():Boolean {
			//let things know if we've built this once already
			return first_build;
		}
	}
}