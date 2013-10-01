package com.tinyspeck.engine.view.ui.making {
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.*;
	import flash.filters.DropShadowFilter;
	import flash.text.*;
	
	public class MakingSlotEmpty extends TSSpriteWithModel {
		
		public var tf:TextField = new TextField();
		public var arrow:DisplayObject;
		
		private var slot:DisplayObject;
		private var slot_lit:Sprite = new Sprite();
		private var lit:Boolean;
		private var is_wide:Boolean;
		
		public function MakingSlotEmpty(is_wide:Boolean = false):void {
			super();

			this.is_wide = is_wide;
			_construct();
		}
		
		override protected function _construct():void {
			super._construct();
			
			slot_lit.visible = false;
			addChild(slot_lit);
			
			slot = new AssetManager.instance.assets['empty_making_slot'+(is_wide ? '_wide' : '')]();
			addChild(slot);
			
			_w = slot.width;
			_h = slot.height;
			
			var g:Graphics = slot_lit.graphics;
			g.beginFill(0xffffff);
			g.lineStyle(1, 0xc8cecf, 1, true, LineScaleMode.NORMAL, CapsStyle.SQUARE);
			g.drawRoundRect(0, 0, _w, _h, 10);
			
			arrow = new AssetManager.instance.assets.making_drag_arrow();
			addChild(arrow);
			
			arrow.x = slot.width - 14;
			arrow.y = int(slot.height/2 - arrow.height/2);
			
			// tf
			TFUtil.prepTF(tf, false);
			tf.htmlText = '<span class="making_slot_empty">Drag ingredients from your pack</span>';
			addChild(tf);
			
			placeTextBelowSlot(false);
		}
		
		public function placeTextBelowSlot(value:Boolean):void {
			if(!value){
				tf.x = arrow.x + arrow.width + 12;
				tf.y = Math.round((slot.height-tf.height)/2)
			}
			else {
				tf.x = int(slot.width/2 - tf.width/2);
				tf.y = int(slot.height + 10);
			}
		}
		
		public function unhighlight():void {
			if (!lit) return;
			arrow.filters = null;
			lit = false;
			
			slot.visible = true;
			slot_lit.visible = false;
			slot_lit.filters = null;
			
			return;
			slot.filters = null;
		}
		
		public function highlight():void {
			if (lit) return;
			lit = true;
			//arrow.filters = StaticFilters.slot_GlowA;
			
			slot.visible = false;
			slot_lit.visible = true;
			slot_lit.filters = StaticFilters.slot_GlowA;
			
			return;
			slot.filters = StaticFilters.slot_GlowA;
			
			return;
			var shadow:DropShadowFilter = new DropShadowFilter();
			shadow.angle = 45;
			var shadow2:DropShadowFilter = new DropShadowFilter();
			shadow2.angle = 225;
			
			shadow.distance = shadow2.distance = 10;
			shadow.strength = shadow2.strength = 2;
			shadow.alpha = shadow2.alpha = 1;
			shadow.blurX = shadow2.blurX = 4;
			shadow.blurY = shadow2.blurY = 4;
			shadow.alpha = shadow2.alpha = 1;
			shadow.color = shadow2.color = 0x69bcea;
			shadow.inner = shadow2.inner = true;
			
			slot.filters = [shadow, shadow2];
		}
		
		public function get slot_width():int { return slot.width }
		public function get slot_height():int { return slot.height }
	}
}