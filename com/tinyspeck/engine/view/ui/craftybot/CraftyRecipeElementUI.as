package com.tinyspeck.engine.view.ui.craftybot
{
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.CraftyDialog;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	public class CraftyRecipeElementUI extends Sprite
	{
		private static const HEIGHT:uint = 55;
		private static const ICON_WH:uint = 35;
		private static const PADD:uint = 10;
		
		private var bg_holder:Sprite = new Sprite();
		private var icon_holder:Sprite = new Sprite();
		
		private var name_tf:TextField = new TextField();
		
		private var icon_view:ItemIconView;
		
		private var current_item:String;
		
		private var w:int;
		
		private var is_built:Boolean;
		
		public function CraftyRecipeElementUI(w:int){
			this.w = w;
		}
		
		private function buildBase():void {						
			icon_holder.x = PADD;
			icon_holder.y = int(HEIGHT/2 - ICON_WH/2);
			bg_holder.addChild(icon_holder);
			
			TFUtil.prepTF(name_tf);
			name_tf.x = icon_holder.x + ICON_WH + PADD;
			name_tf.width = w - name_tf.x - PADD;
			bg_holder.addChild(name_tf);
			
			bg_holder.filters = StaticFilters.copyFilterArrayFromObject({color:0xcccccc, alpha:1}, StaticFilters.black_GlowA);
			addChild(bg_holder);
						
			bg_holder.mouseChildren = false;
			bg_holder.useHandCursor = bg_holder.buttonMode = true;
			bg_holder.addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			
			is_built = true;
		}
		
		public function show(item_class:String):void {
			if(!is_built) buildBase();
			current_item = item_class;
			
			//draw bg
			var g:Graphics = bg_holder.graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRoundRect(0, 0, w, HEIGHT, 10);
			
			//place the icon there
			if(icon_holder.name != item_class) {
				SpriteUtil.clean(icon_holder);
				icon_view = new ItemIconView(item_class, ICON_WH);
				icon_holder.addChild(icon_view);
				
				icon_holder.name = item_class;
			}
			
			//do the text stuff
			const item:Item = TSModelLocator.instance.worldModel.getItemByTsid(item_class);
			var name_txt:String = '<p class="crafty_job">';
			if(item){
				name_txt += item.label;
			}
			else {
				name_txt += 'Unknown';
			}
			
			name_txt += '</p>';
			name_tf.htmlText = name_txt;
			name_tf.y = int(HEIGHT/2 - name_tf.height/2);
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
		}
		
		private function onClick(event:MouseEvent):void {
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			//show the details
			CraftyDialog.instance.showDetails(current_item);
		}
	}
}