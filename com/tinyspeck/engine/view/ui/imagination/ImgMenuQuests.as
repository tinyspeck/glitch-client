package com.tinyspeck.engine.view.ui.imagination
{
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.QuestManager;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Cloud;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class ImgMenuQuests extends ImgMenuElement
	{	
		private static const COUNT_PADD:uint = 2;
		
		private var quest_book:DisplayObject;
		private var count_holder:Sprite = new Sprite();
		
		private var count_tf:TextField = new TextField();
		
		private var count_color:uint = 0xb9371e;
		
		public function ImgMenuQuests(){}
		
		override protected function buildBase():void {
			super.buildBase();
			
			//set the title
			setTitle('Quests');
			
			//set that cloud
			setCloudByType(Cloud.TYPE_QUESTS);
			
			//set sound
			sound_id = 'CLOUD2';
			
			//the book
			quest_book = new AssetManager.instance.assets.quest_book();
			quest_book.x = int(cloud.width/2 - quest_book.width/2);
			quest_book.y = int(cloud.y + (cloud.height/2 - quest_book.height/2) - 8);
			holder.addChild(quest_book);
			
			//counter
			count_color = CSSManager.instance.getUintColorValueFromStyle('imagination_menu_quests', 'backgroundColor', count_color);
			TFUtil.prepTF(count_tf, false);
			count_tf.x = 2;
			count_tf.y = -2;
			count_holder.addChild(count_tf);
			addChild(count_holder);
		}
		
		override public function show():Boolean {
			if(!is_built) buildBase();
			if(!super.show()) return false;
			
			//do we have any new quests?
			const total:int = QuestManager.instance.getUnacceptedQuests().length;
			count_holder.visible = total > 0;
			if(total > 0){
				count_tf.htmlText = '<p class="imagination_menu_quests">'+total+'</p>';
				
				var g:Graphics = count_holder.graphics;
				g.clear();
				g.beginFill(count_color);
				g.drawRoundRect(0, 0, count_tf.width + COUNT_PADD*2 +1, count_tf.height-3, count_tf.height-3);
				
				count_holder.x = int(quest_book.width - count_holder.width - 4);
				count_holder.y = int(quest_book.y - count_holder.height/2 + 4);
			}
			
			return true;
		}
	}
}