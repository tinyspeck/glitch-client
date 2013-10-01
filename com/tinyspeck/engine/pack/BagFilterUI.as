package com.tinyspeck.engine.pack
{
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class BagFilterUI extends Sprite
	{
		protected static const BT_UNDERLINE:String = 'bt_underline';
		
		protected var button_holder:Sprite = new Sprite();
		protected var button_A:Array = [];
		
		protected var line_color:uint;
		
		protected var current_active:String;
		
		public function BagFilterUI(){
			addChild(button_holder);
			line_color = CSSManager.instance.getUintColorValueFromStyle('button_pack_filter_label', 'color', 0x78898a);
		}
		
		public function setActive(category:String):void {
			var bt:Button;
			var i:int;
			var total:int = button_holder.numChildren;
			
			current_active = category;
			
			for(i; i < total; i++){
				bt = button_holder.getChildAt(i) as Button;
				setButtonLook(bt);
			}
		}
		
		public function addItem(category:String):void {
			var bt:Button = button_holder.getChildByName(category) as Button;
			
			if(!bt){
				bt = new Button({
					name: category,
					label: category,
					size: Button.SIZE_MICRO,
					type: Button.TYPE_PACK_FILTER,
					value: 1,
					offset_x: 7,
					h: 19
				});
				bt.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
				bt.addEventListener(MouseEvent.ROLL_OVER, onButtonMouse, false, 0, true);
				bt.addEventListener(MouseEvent.ROLL_OUT, onButtonMouse, false, 0, true);
				button_holder.addChild(bt);
				
				//add a line for the hover stuff
				const bt_line:Sprite = new Sprite();
				bt_line.name = BT_UNDERLINE;
				bt_line.filters = StaticFilters.white1px90Degrees_DropShadowA;
				bt_line.x = bt.label_tf.x + 2;
				bt_line.y = bt.height - 3;
				bt.addChild(bt_line);
				bt_line.visible = false;
			}
			else {
				bt.value++;
			}
			
			setButtonLabel(category);
			reflow();
		}
		
		public function removeItem(category:String):void {
			var bt:Button = button_holder.getChildByName(category) as Button;
			if(bt){
				bt.value--;
				if(bt.value == 0){
					button_holder.removeChild(bt);
					
					//if that was the last one, load the "all" category
					dispatchEvent(new TSEvent(TSEvent.CHANGED, BagUI.CATEGORY_ALL));
				}
				setButtonLabel(category);
				reflow();
			}
		}
		
		protected function setButtonLabel(category:String):void {
			const bt:Button = button_holder.getChildByName(category) as Button;
			if(!bt) return;
			
			//make sure it looks good!
			setButtonLook(bt);
		}
		
		protected function setButtonLook(bt:Button):void {
			//what should they look like?!
			bt.disabled = bt.name == current_active;
			bt.filters = bt.name == current_active ? StaticFilters.white1px90Degrees_DropShadowA.concat(StaticFilters.black3px90DegreesInner_DropShadowA) : null;
			
			//see if they need to show the underline
			const bt_line:Sprite = bt.getChildByName(BT_UNDERLINE) as Sprite;
			if(bt_line){
				//draw the line
				var g:Graphics = bt_line.graphics;
				g.clear();
				g.beginFill(line_color);
				g.drawRect(0, 0, int(bt.label_tf.width - 2), 1);
				
				//hide it if need be
				if(bt.disabled) bt_line.visible = false;
			}
		}
		
		protected function reflow():void {
			var bt:Button;
			var i:int;
			var total:int = button_holder.numChildren;
			var next_x:int;
			
			// put the buttons in an array we can sort
			button_A.length = 0;
			for(i=0; i < total; i++){
				button_A.push(button_holder.getChildAt(i))
			}
			// sort by name
			button_A.sortOn(['name'], [Array.CASEINSENSITIVE]);
			
			for(i=0; i < total; i++){
				bt = button_A[i] as Button;
				bt.x = next_x;
				next_x += bt.width + 2;
			}
		}
		
		protected function onButtonClick(event:TSEvent):void {
			const bt:Button = event.data;
			if(bt.disabled) return;
			
			dispatchEvent(new TSEvent(TSEvent.CHANGED, bt.name));
		}
		
		protected function onButtonMouse(event:MouseEvent):void {
			const bt:Button = event.currentTarget as Button;
			if(bt.disabled) return;
			const bt_line:Sprite = bt.getChildByName(BT_UNDERLINE) as Sprite;
			if(bt_line) bt_line.visible = event.type == MouseEvent.ROLL_OVER;
		}
	}
}