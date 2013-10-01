package com.tinyspeck.engine.view.ui.supersearch
{
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.StringUtil;
	
	import flash.display.DisplayObject;

	public class SuperSearchElementNoResult extends SuperSearchElement
	{	
		private static const MAX_CHARS:uint = 12;
		
		private var no_results:DisplayObject;
		
		private var current_style:String = 'super_search_no_result';
		
		public function SuperSearchElementNoResult(){
			super(false);
			
			setAppearanceFromCSS(current_style);
		}
		
		public function show(w:int, txt:String):void {			
			_w = w;
			current_name = txt;
			
			setName();
			visible = true;
		}
		
		override protected function setNameText(char_count:uint):void {
			//no results looks a bit different
			var name_txt:String = '<p class="super_search_base"><span class="'+current_style+'">';
			name_txt += 'No results for: “'+StringUtil.encodeHTMLUnsafeChars(StringUtil.truncate(current_name, char_count))+'”';
			name_txt += '<span></p>';
			
			name_tf.htmlText = name_txt;
		}
		
		override protected function draw():void {
			//we want the name TF to be fatter
			super.draw();
			name_tf.width = _w - name_tf.x - TEXT_PADD;
		}
		
		override protected function setImage():void {
			//nothing to do since the image is always the same
		}
		
		public function setAppearanceFromCSS(style_name:String):void {
			current_style = style_name;
			
			//set the bg color
			bg_color = CSSManager.instance.getUintColorValueFromStyle(current_style, 'backgroundColor', 0xe8eaec);
			draw();
		}
		
		override public function set show_images(value:Boolean):void {						
			super.show_images = value;
			
			//place the no results image in there
			if(value && !no_results){
				no_results = new AssetManager.instance.assets.super_search_no_results();
				image_holder.addChild(no_results);
				IMG_WH = no_results.width + IMG_PADD;
			}
			else if(!value){
				//match the default
				IMG_WH = 32;
			}
			
			//redraw
			_h = IMG_WH + IMG_PADD*2;
			if(image_holder) image_holder.y = int(_h/2 - image_holder.height/2);
			draw();
		}
	}
}