package com.tinyspeck.engine.pack
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.IDragTarget;
	import com.tinyspeck.engine.view.renderer.interfaces.IPcItemstackAddDelConsumer;
	import com.tinyspeck.engine.view.renderer.interfaces.IPcItemstackUpdateConsumer;
	import com.tinyspeck.engine.view.ui.TSScrollPager;
	
	import flash.display.Sprite;
	import flash.utils.Dictionary;

	public class BagUI extends TSSpriteWithModel implements IPcItemstackAddDelConsumer, IPcItemstackUpdateConsumer, IDragTarget
	{
		public static const CATEGORY_ALL:String = 'All';
		public static const CATEGORY_OTHER:String = 'Other'; //used when no category is set
		
		protected static const HOLDER_H:uint = 80; //how high the pager is, probably don't want to touch this!!
		protected static const TOP_OFFSET:int = 13;
		
		protected var BUTTON_PADD:int = 5;
		
		protected var bag_filter:BagFilterUI = new BagFilterUI();
		protected var scroll_pager:TSScrollPager;
		
		protected var button_content:Sprite = new Sprite();
		protected var current_pane_sp:Sprite;
		
		protected var content_panes:Dictionary = new Dictionary();
		
		protected var is_built:Boolean;
		
		public function BagUI(){
			visible = false;
		}
		
		protected function buildBase():void {			
			//build out the content panes
			buildPanes();
			
			//make the content be at the proper padding
			button_content.x = button_content.y = BUTTON_PADD;
			
			//position it
			bag_filter.y = HOLDER_H + 10;
			bag_filter.addEventListener(TSEvent.CHANGED, onFilterClick, false, 0, true);
			addChild(bag_filter);
			
			//the scroller
			scroll_pager = new TSScrollPager(HOLDER_H);
			addChild(scroll_pager);
			
			is_built = true;
		}
		
		protected function buildPanes():void {
			//this will probably be overriden on a bag by bag basis
		}
		
		public function show():void {
			if(!is_built) buildBase();
			if(!current_pane_sp) activatePane(CATEGORY_ALL);
			
			refresh();
			
			//juuust make sure it's showing
			visible = true;
		}
		
		public function activatePane(id:String):void {
			const pane_sp:Sprite = getPaneById(id);
			if (!pane_sp) return;
			if (pane_sp == current_pane_sp) return;
			
			if (current_pane_sp) {
				if (button_content.getChildAt(0) == current_pane_sp) {
					button_content.removeChild(current_pane_sp);
				}
			}
			
			button_content.addChild(pane_sp);
			scroll_pager.setContent(button_content);
			current_pane_sp = pane_sp;
			bag_filter.setActive(id);
			reflowPane(pane_sp);
		}
		
		protected function reflowPane(pane_sp:Sprite):void {
			if (!pane_sp) return;
			
			//refresh the scroller
			scroll_pager.refresh();
		}
		
		public function refresh():void {
			if(!is_built) return;
			
			y = TOP_OFFSET;
			const lm:LayoutModel = model.layoutModel;
			const holder_w:int = lm.gutter_w + (lm.pack_is_wide ? lm.overall_w : lm.loc_vp_w) - PackDisplayManager.instance.x;
			
			scroll_pager.width = holder_w;
			
			reflowPane(current_pane_sp);
		}
		
		protected function getPaneById(id:String):Sprite {
			return content_panes[id] as Sprite;
		}
		
		protected function onFilterClick(event:TSEvent):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			activatePane(event.data);
		}
		
		/** AddDelConsumer **/
		public function onPcItemstackAdds(tsids:Array):void {}
		public function onPcItemstackDels(tsids:Array):void {}
		
		/** UpdateConsumer **/
		public function onPcItemstackUpdates(tsids:Array):void {}
		
		/** IDragTarget **/
		public function unhighlightOnDragOut():void {}
		public function highlightOnDragOver():void {}
	}
}