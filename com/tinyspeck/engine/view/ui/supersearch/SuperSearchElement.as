package com.tinyspeck.engine.view.ui.supersearch
{
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class SuperSearchElement extends Sprite
	{
		protected static const PH_STRING:String = '~!@ph@!~';
		
		protected var MAX_CHARS:uint = 26;
		protected var TEXT_PADD:uint = 10;
		protected var IMG_WH:uint = 40;
		protected var IMG_PADD:uint = 5;
		
		protected var image_holder:Sprite;
		protected var close_holder:Sprite = new Sprite();
		
		protected var name_tf:TextField = new TextField();
		protected var sub_tf:TextField;
		
		protected var current_name:String;
		protected var current_value:String;
		protected var current_sub_label:String;
		protected var current_highlight:String;
		protected var highlight_class:String;
		
		protected var bg_color:uint;
		protected var active_bg_color:uint;
		protected var image_bg_color:int = -1;
		protected var image_border_color:int = -1;
		
		protected var _w:int = 500; //just a larger number to measure the TF before it's width get's set (prevents pre-truncating)
		protected var _h:int;
		
		protected var _is_active:Boolean;
		protected var _show_images:Boolean;
		
		public function SuperSearchElement(show_images:Boolean){
			//tf
			TFUtil.prepTF(name_tf);
			name_tf.embedFonts = false;
			name_tf.autoSize = TextFieldAutoSize.NONE;
			addChild(name_tf);
			
			//images
			this.show_images = show_images;
			
			//colors
			bg_color = CSSManager.instance.getUintColorValueFromStyle('super_search_base', 'backgroundColor', 0xffffff);
			active_bg_color = CSSManager.instance.getUintColorValueFromStyle('super_search_active', 'backgroundColor', 0xe9eff1);
			highlight_class = 'super_search_highlight';
			
			//close X
			const close_x:DisplayObject = new AssetManager.instance.assets.close_x_grey();
			close_holder.useHandCursor = close_holder.buttonMode = true;
			close_holder.addEventListener(MouseEvent.CLICK, onCancelClick, false, 0, true);
			close_holder.addChild(close_x);
			
			hide();
		}
		
		public function hide():void {
			visible = false;
			show_close_bt = false;
		}
		
		protected function draw():void {
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(is_active ? active_bg_color : bg_color);
			g.drawRect(0, 0, _w, _h);
			
			close_holder.x = int(_w - close_holder.width - (_h - close_holder.height)/2);
			close_holder.y = int(_h/2 - close_holder.height/2);
			
			name_tf.x = show_images ? IMG_WH + TEXT_PADD*2 : TEXT_PADD;
			name_tf.width = (close_holder.visible ? close_holder.x : _w - 5) - name_tf.x;
		}
		
		protected function setName():void {
			var char_count:int = current_name.length;
			setNameText(char_count);
			draw();
			
			//this is too big! Let's shrink it down until it fits
			while(name_tf.numLines > 2 && current_name != PH_STRING){
				char_count--;
				setNameText(char_count);
			}
			
			//reset the height
			name_tf.height = name_tf.textHeight + 6;
			name_tf.y = int(_h/2 - name_tf.height/2 - (current_sub_label ? 6 : 0));
			
			//show the sub text if we got it
			if(current_sub_label) sub_label = current_sub_label;
		}
		
		protected function setNameText(char_count:uint):void {
			var name_txt:String = '<p class="super_search_base">';
			if(is_active) name_txt += '<span class="super_search_active">';
			if(!current_highlight){
				name_txt += StringUtil.truncate(current_name, char_count);
			}
			else {
				//run it through the colorizer
				name_txt += StringUtil.colorCharacters(StringUtil.truncate(current_name, char_count), current_highlight, highlight_class);
			}
			if(is_active) name_txt += '</span>';
			name_txt += '</p>';
			
			name_tf.htmlText = name_txt;
		}
		
		protected function setImage():void {
			//base doesn't do anything, if showing images, those that extend should override
			//this is a nice warning square that you should override ;)
			const g:Graphics = image_holder.graphics;
			g.clear();
			g.beginFill(0xff00ff);
			g.drawRect(0, 0, IMG_WH, IMG_WH);
			
			image_holder.y = int(_h/2 - IMG_WH/2);
		}
		
		protected function onCancelClick(event:MouseEvent):void {
			show_close_bt = false;
			dispatchEvent(new TSEvent(TSEvent.CLOSE, this));
		}
		
		public function set sub_label(value:String):void {
			//set the current sub label
			current_sub_label = value;
			
			//clean up if there is no sub label
			if(!current_sub_label) {	
				if(sub_tf && contains(sub_tf)){
					removeChild(sub_tf);
					sub_tf = null;
				}
				return;
			}
			
			//build it if we don't have it
			if(!sub_tf){
				sub_tf = new TextField();
				TFUtil.prepTF(sub_tf);
				sub_tf.embedFonts = false;
				addChild(sub_tf);
			}
			
			//populate the text
			sub_tf.htmlText = '<p class="super_search_sub_label">'+current_sub_label+'</p>';
			sub_tf.x = name_tf.x;
			sub_tf.y = int(name_tf.y + name_tf.height - 6);
			sub_tf.width = name_tf.width;
		}
		
		override public function get height():Number {
			return _h;
		}
		
		override public function set width(value:Number):void {
			_w = value;
			draw();
		}
		
		public function get is_active():Boolean { return _is_active; }
		public function set is_active(value:Boolean):void {
			_is_active = value;
			setName();
			if(_show_images) setImage();
			draw();
		}
		
		public function set show_close_bt(value:Boolean):void {
			close_holder.visible = value;
			if(value) addChildAt(close_holder, numChildren-1);
		}
		
		public function get show_images():Boolean { return _show_images; }
		public function set show_images(value:Boolean):void {
			_show_images = value;
			if(value && !image_holder){
				image_holder = new Sprite();
				image_holder.x = TEXT_PADD;
				addChild(image_holder);
			}
			else if(!value && image_holder){
				SpriteUtil.clean(image_holder);
				removeChild(image_holder);
				image_holder = null;
			}
			
			//set the height (account for the border if we have one)
			_h = IMG_WH + IMG_PADD*2 + (image_border_color != -1 ? 1 : 0);
			if(!value){
				current_name = PH_STRING;
				setName();
				_h = int(name_tf.height + TEXT_PADD*2);
				current_name = '';
				setName();
			}
		}
		
		public function set highlight_text(value:String):void {
			current_highlight = value;
			setName();
		}
		
		public function get value():String { return current_value; }
	}
}