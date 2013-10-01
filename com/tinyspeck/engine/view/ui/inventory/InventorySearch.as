package com.tinyspeck.engine.view.ui.inventory
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.IPackChange;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.supersearch.SuperSearch;
	import com.tinyspeck.engine.view.ui.supersearch.SuperSearchElementItemstack;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.TextField;

	public class InventorySearch extends SuperSearch implements IPackChange
	{
		public static const HEIGHT:uint = 37;
		
		private static const WIDTH:uint = 282;
		private static const PADD:uint = 7;
		
		private const input_drop:DropShadowFilter = new DropShadowFilter();
		
		private var bg_matrix:Matrix = new Matrix();
		private var local_pt:Point = new Point();
		private var global_pt:Point = new Point();
		
		private var label_tf:TextField = new TextField();
		
		private var bg_color_top:uint = 0xe8eaeb;
		private var bg_color_bottom:uint = 0xe7e9eb;
		
		public function InventorySearch(){
			//since this is JUST for inventory, let's init it now!
			show_images = true;
			init(TYPE_INVENTORY, 3, '', SuperSearch.DIRECTION_UP);
		}
		
		override protected function buildBase():void {
			super.buildBase();
			
			//width isn't dynamic for this bad boy
			_w = WIDTH;
			
			//setup the label
			TFUtil.prepTF(label_tf, false);
			label_tf.htmlText = '<p class="inventory_search_label">Search inventory for:</p>';
			label_tf.x = PADD;
			label_tf.y = int(HEIGHT/2 - label_tf.height/2 + 1);
			addChild(label_tf);
			
			//move the input
			input_holder.x = -PADD;
			input_holder.y = PADD;
			
			input_tf.x = int(label_tf.x + label_tf.width + PADD*4);
			
			//setup the vertical gradient
			bg_matrix.createGradientBox(WIDTH, HEIGHT, Math.PI/2, 0, 0);
			
			//draw the bg
			const cssm:CSSManager = CSSManager.instance;
			bg_color_top = cssm.getUintColorValueFromStyle('inventory_search', 'backgroundTop', bg_color_top);
			bg_color_bottom = cssm.getUintColorValueFromStyle('inventory_search', 'backgroundBottom', bg_color_bottom);
			bg_color_input = cssm.getUintColorValueFromStyle('inventory_search', 'backgroundColorInput', 0xf0f4d6);
			bg_color = bg_color_top;
			
			var g:Graphics = graphics;
			g.beginGradientFill(GradientType.LINEAR, [bg_color_top, bg_color_bottom], [1,1], [0, 255], bg_matrix);
			g.drawRoundRect(0, 0, _w, HEIGHT, _corner_rad*2);
			
			const pointy:DisplayObject = new AssetManager.instance.assets.inventory_search_pointy();
			pointy.x = 4;
			pointy.y = HEIGHT;
			addChild(pointy);
			
			//setup the filters
			input_drop.inner = true;
			input_drop.alpha = .08;
			
			border_glow.color = cssm.getUintColorValueFromStyle('inventory_search', 'borderColor', 0xbbc08f);
			border_glow.blurX = border_glow.blurY = 2;
			border_glow.strength = 12;
			border_glow.alpha = 1;
			
			input_holder.filters = [input_drop, border_glow];
			
			filters = StaticFilters.copyFilterArrayFromObject({alpha:.2, blurX:7, blurY:7, strength:20}, StaticFilters.black_GlowA);
		}
		
		override public function show(and_focus:Boolean = false, input_txt:String = ''):void {
			//add it to the view
			TSFrontController.instance.getMainView().addView(this);
			
			super.show(and_focus, input_txt);
			
			//listen to the changing of elements so we can highlight stuff on the fly
			addEventListener(TSEvent.ACTIVITY_HAPPENED, onElementChanged, false, 0, true);
			
			//when they make a section we're going to hide it and open the context menu
			addEventListener(TSEvent.CHANGED, onElementSelect, false, 0, true);
			
			//make sure if the pack changes we know about it
			PackDisplayManager.instance.registerChangeSubscriber(this);
		}
		
		override public function hide(event:Event = null):void {
			super.hide(event);
			
			removeEventListener(TSEvent.ACTIVITY_HAPPENED, onElementChanged);
			PackDisplayManager.instance.unRegisterChangeSubscriber(this);
			if(parent) parent.removeChild(this);
		}
		
		override protected function onEscape(event:KeyboardEvent = null):void {
			super.onEscape(event);
			hide();
			PackDisplayManager.instance.blurFocusedSlot();
		}		
		
		private function onElementChanged(event:TSEvent):void {
			//If you want the hovering of the mouse to select things, comment out the next line
			//if(!use_keyboard) return;
			
			const element:SuperSearchElementItemstack = event.data as SuperSearchElementItemstack;
			
			if(element){
				const itemstack:Itemstack = model.worldModel.getItemstackByTsid(element.value);
				
				//light it up in the pack
				PackDisplayManager.instance.setFocusedSlot(itemstack.container_tsid, itemstack.slot, true);
			}
			else {
				//shut off any highlighting
				PackDisplayManager.instance.blurFocusedSlot();
			}
		}
		
		private function onElementSelect(event:TSEvent):void {		
			const element:SuperSearchElementItemstack = event.data as SuperSearchElementItemstack;
			
			//hide it no matter what
			hide();
			
			if(element){
				const itemstack:Itemstack = model.worldModel.getItemstackByTsid(element.value);
				
				//light it up in the pack
				PackDisplayManager.instance.setFocusedSlot(itemstack.container_tsid, itemstack.slot, true);
				
				//show the context menu
				TSFrontController.instance.startItemstackMenu(itemstack.tsid);
			}
			
			//make sure to blur any focused slots
			PackDisplayManager.instance.blurFocusedSlot();
		}
		
		public function onPackChange():void {
			if(result_scroller.body.numChildren){
				onInputChange();
			}
		}
		
		override public function hitTestPoint(x:Number, y:Number, shapeFlag:Boolean=false):Boolean {
			//there is someplace where flash is being dumb with masks I think, this gets around it
			global_pt = localToGlobal(local_pt);
			if(!result_content.visible){
				return x >= global_pt.x && x <= global_pt.x + WIDTH && y >= global_pt.y && y <= global_pt.y + HEIGHT;
			}
			else {
				return super.hitTestPoint(x, y, shapeFlag);
			}
		}
	}
}