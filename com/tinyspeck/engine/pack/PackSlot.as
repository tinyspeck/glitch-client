package com.tinyspeck.engine.pack
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.InteractionMenuModel;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.ContainersUtil;
	import com.tinyspeck.engine.util.IDragTarget;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.itemstack.PackItemstackView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;


	public class PackSlot extends TSSpriteWithModel implements IDragTarget,ITipProvider {
		private static const CORNER_RADIUS:Number = 5;
		private static const EMPTY_ALPHA:Number = .4;
		
		private static var border_glowA:Array;
		private static var border_glow_openA:Array;
		private static var opener_border_glowA:Array;
		private static var bg_color:uint = 0xffffff;
		private static var bg_color_open:uint = 0x78898a;
		private static var opener_color:uint = 0xf0f5f7;
		private static var opener_color_open:uint = 0x78898a;
		private static var opener_border_color_open:uint = 0x6b7a7b;
		private static var border_color:uint = 0xd1d6d7;
		private static var border_color_open:uint = 0xdb2bfc0;
		
		public var pis_view:PackItemstackView;
		public var slot:int;
		
		private var _is_focused:Boolean = false;
		private var _is_open:Boolean = false;
		private var _is_full:Boolean = false;
		private var _lit:Boolean = false;
		private var holder:Sprite = new Sprite();
		private var full_box:Sprite = new Sprite();
		private var opener:Sprite = new Sprite();
		private var opener_icon:Sprite = new Sprite();
		private var line:Sprite = new Sprite();
		private var empty_box:Sprite = new Sprite();
		private var count_tf:TextField = new TextField();
		
		public function PackSlot(slot:int) {
			this.slot = slot;
			this.name = 'slot'+slot;
			super();
			init();
		}
		
		private function init():void {
			addChild(holder);
			
			drawFullBox();
			
			holder.addChild(full_box);
			holder.addChild(opener);
			opener.buttonMode = opener.useHandCursor = true;
			opener.mouseChildren = false;
			holder.addChild(empty_box);
			holder.addChild(line);
			line.visible = false;
			
			var g:Graphics
			
			TFUtil.prepTF(count_tf, false);
			count_tf.x = 2;
			count_tf.thickness = -50;
			count_tf.sharpness = -50;
			opener.addChild(count_tf);
			opener.addEventListener(MouseEvent.CLICK, onOpenerClick, false, 0, true);
			
			//add the colors/filters
			if(!border_glowA){
				bg_color = CSSManager.instance.getUintColorValueFromStyle('pack_slot', 'backgroundColor', bg_color);
				bg_color_open = CSSManager.instance.getUintColorValueFromStyle('pack_container', 'backgroundColor', bg_color_open);
				opener_color = CSSManager.instance.getUintColorValueFromStyle('pack_slot', 'openerColor', opener_color);
				opener_color_open = CSSManager.instance.getUintColorValueFromStyle('pack_slot', 'openerColorOpen', opener_color_open);
				
				border_color = CSSManager.instance.getUintColorValueFromStyle('pack_slot', 'borderColor', 0xd1d6d7);
				border_color_open = CSSManager.instance.getUintColorValueFromStyle('pack_container', 'borderColor', 0xdb2bfc0);
				opener_border_color_open = CSSManager.instance.getUintColorValueFromStyle('pack_slot', 'openerBorderColorOpen', 0x6b7a7b);
				border_glowA = StaticFilters.copyFilterArrayFromObject({color:border_color, strength:8}, StaticFilters.black_GlowA);
				border_glow_openA = StaticFilters.copyFilterArrayFromObject({color:border_color_open, strength:8}, StaticFilters.black_GlowA);
				opener_border_glowA = StaticFilters.copyFilterArrayFromObject({color:opener_border_color_open, strength:8}, StaticFilters.black_GlowA);
			}
			
			//draw the line to hide the border
			g = line.graphics;
			g.beginFill(bg_color_open);
			g.drawRect(-1, -1, model.layoutModel.pack_slot_w+1, 1);
			
			//draw the empty box
			g = empty_box.graphics;
			g.beginFill(bg_color);
			g.drawRoundRect(0, 0, model.layoutModel.pack_slot_w-1, model.layoutModel.pack_slot_h-1, CORNER_RADIUS*2);
			empty_box.alpha = EMPTY_ALPHA;
			
			//setup the opener icon
			opener.addChild(opener_icon);
			
			//default to not full
			is_full = _is_full;
		}
		
		private function drawFullBox():void {
			const fill_c:uint = _is_open ? bg_color_open : bg_color;
			const opener_fill_c:uint = _is_open ? opener_color_open : opener_color;
			const opener_w:int = model.layoutModel.pack_slot_wide_w-model.layoutModel.pack_slot_w + 2;
			
			var g:Graphics = full_box.graphics;
			g.clear();
			g.beginFill(fill_c);
			g.drawRoundRectComplex(0, 0, 
				model.layoutModel.pack_slot_w-1, model.layoutModel.pack_slot_h-1-(holds_container ? 4 : 0), 
				!_is_open ? CORNER_RADIUS : 0, !_is_open ? CORNER_RADIUS : 0, holds_container ? 0 : CORNER_RADIUS, holds_container ? 0 : CORNER_RADIUS
			);
			
			//draw the opener if we need to
			opener.visible = holds_container;
			opener.y = holds_container ? model.layoutModel.pack_slot_h-8 : 0;
			opener.filters = _is_open ? opener_border_glowA : border_glowA;
			
			//reset the count tf
			count_tf.cacheAsBitmap = false;
			
			//add the border
			full_box.filters = _is_open ? border_glow_openA : border_glowA;
			
			g = opener.graphics;
			g.clear();
			if(holds_container){
				const opener_offset:uint = 33;
				const hit_area_wh:uint = 12;
				const circle_rad:Number = 2.5;
				g.beginFill(opener_fill_c);
				g.drawRoundRectComplex(0, 0, model.layoutModel.pack_slot_w-1, opener_w-1, 0, 0, CORNER_RADIUS, CORNER_RADIUS);
				
				//show the line if we are opening this
				line.visible = _is_open;
				
				//set the opener icon
				g = opener_icon.graphics;
				g.clear();
				g.beginFill(_is_open ? 0xffffff : 0x6d777c);
				g.drawCircle(hit_area_wh/2, hit_area_wh/2, circle_rad);
				opener_icon.x = model.layoutModel.pack_slot_w - hit_area_wh - 2;
				opener_icon.y = int(opener_w/2 - hit_area_wh/2 - .5);
				TipDisplayManager.instance.registerTipTrigger(opener);
				
				//see how many things we've got in this container
				updateContainerCount();
				
				//set the filter
				count_tf.filters = !_is_open ? StaticFilters.white1px90Degrees_DropShadowA : null;
				opener_icon.filters = !_is_open ? StaticFilters.white1px90Degrees_DropShadowA : null;
			}
			else {
				//no need for the tip anymore
				TipDisplayManager.instance.unRegisterTipTrigger(opener);
			}
			
			if (pis_view) {
				if(!pis_view.hasEventListener(TSEvent.CHANGED)){
					pis_view.addEventListener(TSEvent.CHANGED, updateContainerCount, false, 0, true);
				}
				pis_view.x = 6;
				pis_view.y = !holds_container ? 6 : 2;
			}
		}
		
		private function onOpenerClick(event:MouseEvent):void {
			//open the itemstack menu!
			if(pis_view && pis_view.itemstack){
				TSFrontController.instance.startItemstackMenu(pis_view.itemstack.tsid, InteractionMenuModel.TYPE_PACK_IST_VERB_MENU, true);
			}
		}
		
		private function updateContainerCount(event:Event = null):void {
			const As:Object = ContainersUtil.getItemstackTsidAsGroupedByContainer(
				model.worldModel.pc.itemstack_tsid_list, 
				model.worldModel.itemstacks
			);
			const used:int = As[pis_view.itemstack.tsid] ? As[pis_view.itemstack.tsid].length : 0;
			const total:int = pis_view && pis_view.itemstack ? pis_view.itemstack.slots : 0;
			
			var count_txt:String = '<p class="pack_slot">';
			if(_is_open) count_txt += '<span class="pack_slot_open">';
			count_txt += used+'/'+total;
			if(_is_open) count_txt += '</span>';
			count_txt += '</p>';
			
			count_tf.htmlText = count_txt;
		}
		
		public function addStack(pis_view:PackItemstackView):void {
			if (this.pis_view) {
				removeStack();
			}
			this.pis_view = pis_view;
			holder.addChild(pis_view);
			pis_view.y = 6;
			is_full = true;
			drawFullBox();
		}
		
		public function removeStack(and_dispose:Boolean=true):PackItemstackView {
			is_full = false;
			is_open = false;
			empty_box.alpha = EMPTY_ALPHA;
			if (!pis_view) return null;
			if (pis_view.parent) pis_view.parent.removeChild(pis_view);
			if (pis_view.hasEventListener(TSEvent.CHANGED)) {
				pis_view.removeEventListener(TSEvent.CHANGED, updateContainerCount);
			}
			if (and_dispose) {
				pis_view.dispose();
			}
			var was_pis_view:PackItemstackView = pis_view;
			pis_view = null;
			drawFullBox();
			return was_pis_view;
		}
		
		public function unhighlightOnDragOut():void {
			if (!_lit) return;
			_lit = false;
			
			holder.filters = null;
			
			this.is_full = this.is_full;
		}
		
		public function highlightOnDragOver():void {
			if (_lit) return;
			_lit = true;
			full_box.visible = true;
			empty_box.visible = false;
			
			holder.filters = StaticFilters.slot_GlowA;
		}
		
		public function animateEmptyBox(time:Number, is_showing:Boolean):void {
			//this will show the empty box at full opacity, and then animate it to where it needs to go
			empty_box.alpha = is_showing ? EMPTY_ALPHA : 1;
			TSTweener.removeTweens(empty_box);
			TSTweener.addTween(empty_box, {alpha:is_showing ? 1 : EMPTY_ALPHA, time:time, transition:'linear'});
		}
		
		public function get is_full():Boolean {
			return _is_full;
		}
		
		public function get holds_container():Boolean {
			if (pis_view && model.worldModel.getItemstackByTsid(pis_view.tsid).slots) return true;
			return false;
		}
		
		public function set is_full(f:Boolean):void {
			_is_full = f;
			full_box.visible = _is_full;
			empty_box.visible = !_is_full;
		}
		
		public function get is_focused():Boolean {
			return _is_focused;
		}
		
		public function set is_focused(f:Boolean):void {
			_is_focused = f;
			
			if (_is_focused) {
				if (!filters.length) filters = StaticFilters.blue2px_GlowA;
			} else {
				filters = null;
			}
		}
		
		public function get is_open():Boolean {
			return _is_open;
		}
		
		public function set is_open(o:Boolean):void {
			if (_is_open == o) return;
			_is_open = o;
			var animating:Boolean;
			var dest_y:int = _is_open ? -6 : 0;
			if (holder.y != dest_y) {
				animating = true;
				//move the whole holder
				TSTweener.addTween(holder, {y:dest_y, transition:'linear', time:.2, delay:.1, onComplete:drawFullBox}); //fixes any rounding probs
			}
			
			drawFullBox();
			if (animating) {
				count_tf.cacheAsBitmap = true; //prevents it from dancing while tweening
			}
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target) return null;
			return {txt:'Options', offset_y:-2, pointer:WindowBorder.POINTER_BOTTOM_CENTER};
		}
	}
}