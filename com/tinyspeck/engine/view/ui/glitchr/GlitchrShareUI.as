package com.tinyspeck.engine.view.ui.glitchr
{
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.TSScroller;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;

	public class GlitchrShareUI extends TSSpriteWithModel
	{
		/**********************************************************
		 * Don't delete this yet, there is some useful code       *
		 * in here that I'd like to port over to the note stuff   *
		 **********************************************************/
		private static const IMG_WH:uint = 40;
		private static const INPUT_MIN_H:uint = 53;
		private static const INPUT_MAX_H:uint = 80;
		private static const OFFSET_X:uint = 50;
		private static const DEFAULT_TXT:String = 'Write something!';
		
		private var avatar_holder:Sprite = new Sprite();
		private var avatar_mask:Sprite = new Sprite();
		private var text_holder:Sprite = new Sprite();
		
		private var text_scroll:TSScroller;
		
		private var outter_glow:GlowFilter = new GlowFilter();
		private var inner_drop:DropShadowFilter = new DropShadowFilter();
		
		private var name_tf:TSLinkedTextField = new TSLinkedTextField();
		private var input_tf:TextField = new TextField();
		
		private var is_built:Boolean;
		
		private var photo_id:String = '';
		private var photo_url:String = '';
		
		public function GlitchrShareUI(w:int){
			_w = w;
		}
		
		private function buildBase():void {
			//avatar
			const image_bg_color:uint = CSSManager.instance.getUintColorValueFromStyle('acl_key_given_element_avatar', 'backgroundColor', 0xe5ebeb);
			var g:Graphics = avatar_holder.graphics;
			g.beginFill(image_bg_color);
			g.drawCircle(IMG_WH/2, IMG_WH/2, IMG_WH/2);
			avatar_holder.mask = avatar_mask;
			avatar_holder.filters = StaticFilters.black3pxInner_GlowA;
			addChild(avatar_holder);
			
			//mask
			g = avatar_mask.graphics;
			g.beginFill(0);
			g.drawCircle(IMG_WH/2, IMG_WH/2, IMG_WH/2);
			addChild(avatar_mask);
			
			//load the stuff
			const pc:PC = model.worldModel.pc;
			if(pc && pc.singles_url){
				AssetManager.instance.loadBitmapFromWeb(pc.singles_url+'_50.png', onHeadshotLoad, 'Glitchr avatar head');
			}
			
			//text scroller
			text_scroll = new TSScroller({
				name: 'text_scroll',
				bar_wh: 12,
				bar_color: 0,
				bar_alpha: .1,
				bar_handle_min_h: 36,
				scrolltrack_always: false,
				maintain_scrolling_at_max_y: true
			});
			text_scroll.setHandleColors(0x75733d, 0x75733d, 0xacab8b);
			text_scroll.listen_to_arrow_keys = true;
			text_scroll.w = _w - OFFSET_X - 4;
			text_scroll.x = 2;
			text_scroll.y = 2;
			text_holder.addChild(text_scroll);
			
			//filters
			inner_drop.color = 0;
			inner_drop.distance = 1;
			inner_drop.angle = 90;
			inner_drop.quality = 1;
			inner_drop.alpha = .15;
			inner_drop.blurX = 2;
			inner_drop.blurY = 6;
			inner_drop.inner = true;
			
			outter_glow.color = 0xc3c38e;
			outter_glow.alpha = 1;
			outter_glow.blurX = 3;
			outter_glow.blurY = 3;
			
			//text
			TFUtil.prepTF(name_tf);
			name_tf.width = _w - OFFSET_X;
			name_tf.htmlText = '<p class="glitchr_snapshot_body">placeholder</p>';
			name_tf.x = OFFSET_X;
			name_tf.y = 5;
			addChild(name_tf);
			
			TFUtil.prepTF(input_tf);
			TFUtil.setTextFormatFromStyle(input_tf, 'glitchr_snapshot_input');
			input_tf.maxChars = 500;
			input_tf.embedFonts = false;
			input_tf.type = TextFieldType.INPUT;
			input_tf.width = text_scroll.w - 12;
			input_tf.mouseEnabled = true;
			input_tf.selectable = true;
			input_tf.addEventListener(Event.CHANGE, onInputChange, false, 0, true);
			input_tf.addEventListener(MouseEvent.CLICK, onInputClick, false, 0, true);
			text_scroll.body.addChild(input_tf);
			
			text_holder.x = OFFSET_X;
			text_holder.filters = [inner_drop, outter_glow];
			addChild(text_holder);
			
			is_built = true;
		}
		
		public function show(photo_id:String, photo_url:String):void {
			if(!is_built) buildBase();
			
			this.photo_id = photo_id;
			this.photo_url = photo_url;
			
			//you probably want this method to be passed some data about the photo, or have this read from the manager
			setNameText();
			
			//reset
			enabled = true;
			
			//place the holder where it needs to go
			text_holder.y = int(name_tf.y + name_tf.height + 5);
			
			//if we don't have any text, make it the default
			text = DEFAULT_TXT;
			onInputChange();
			focusOnInput(true);
		}
		
		public function hide():void {
			//if you were listening to things in show, unlisten here
			if(parent) parent.removeChild(this);
			if(is_built){
				text = DEFAULT_TXT;
				onInputChange();
			}
		}
		
		private function setNameText():void {
			const pc:PC = model.worldModel.pc;
			var name_txt:String = '<p class="glitchr_snapshot_save">';
			name_txt += '<b><a href="event:' + TSLinkedTextField.LINK_PC_EXTERNAL + '|' + pc.tsid + '">'+pc.label+'</a></b> posted a ';
			name_txt += '<b><a href="event:' + TSLinkedTextField.LINK_GLITCHR_PHOTO_URL + '|' + photo_url + '">snapshot</a></b>';
			name_txt += '</p>';
			name_tf.htmlText = name_txt;
		}
		
		private function onInputChange(event:Event = null):void {
			var draw_h:int = Math.min(INPUT_MAX_H, Math.max(input_tf.height, INPUT_MIN_H));
			input_tf.autoSize = input_tf.height <= INPUT_MIN_H - input_tf.y && input_tf.scrollV == 1 ? TextFieldAutoSize.NONE : TextFieldAutoSize.LEFT;
			if(input_tf.height < draw_h - input_tf.y) input_tf.height = draw_h - input_tf.y;
			draw_h = Math.min(INPUT_MAX_H, input_tf.height);
			
			//draw the text box
			var g:Graphics = text_holder.graphics;
			g.clear();
			g.beginFill(0xf4f4cd);
			g.drawRoundRect(0, 0, int(_w - OFFSET_X), draw_h + text_scroll.y*2, 8);
			
			text_scroll.h = draw_h;
			
			//this will make sure the caret is always in view while editing
			text_scroll.updateHandleWithInputText(input_tf);
			text_scroll.refreshAfterBodySizeChange();
			
			dispatchEvent(new TSEvent(TSEvent.CHANGED));
		}
		
		private function onInputClick(event:Event):void {
			//clear the input if it's the default
			if(input_tf.text == DEFAULT_TXT) text = '';
		}
		
		private function onHeadshotLoad(filename:String, bm:Bitmap):void {
			//throw the bitmap in the circle
			bm.scaleX = -1;
			bm.x = bm.width - 11;
			bm.y = -8;
			avatar_holder.addChild(bm);
		}
		
		public function focusOnInput(select_all:Boolean = true):void {
			if (StageBeacon.stage.focus == input_tf) return;
			StageBeacon.stage.focus = input_tf;
			const start:int = (select_all) ? 0 : input_tf.text.length;
			input_tf.setSelection(start, input_tf.text.length);
		}
		
		public function userEnteredText():Boolean {
			return ((StringUtil.trim(input_tf.text).length > 0) && (input_tf.text != DEFAULT_TXT));
		}
		
		public function get text():String { return input_tf.text; }
		public function set text(value:String):void {
			input_tf.text = value;
		}
		
		public function set enabled(value:Boolean):void {
			input_tf.type = value ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
		}
		
		override public function get height():Number {
			if(parent){
				//race conditions and shit make this have to happen. Works good though!
				return text_holder.y + Math.min(input_tf.height + text_scroll.y*2, text_holder.height);
			}
			else {
				return 0;
			}
		}
	}
}