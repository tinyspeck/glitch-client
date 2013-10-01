package com.tinyspeck.engine.view.ui.supersearch
{
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.util.StringUtil;

	public class SuperSearchElementLocation extends SuperSearchElement
	{	
		private static const HEIGHT:uint = 19;
		
		private var current_hub_tsid:String;
		
		public function SuperSearchElementLocation(show_images:Boolean){
			super(show_images);
			_h = HEIGHT;
			
			//this will make a location go as far as it can, don't think we have location super long cept on dev
			name_tf.wordWrap = false;
		}
		
		public function show(w:int, location:Location, str_to_highlight:String = ''):void {
			if(!location) return;
			
			_w = w;
			current_name = location.label;
			current_value = location.tsid;
			current_hub_tsid = location.hub_id;
			current_highlight = str_to_highlight;
			
			draw();
			visible = true;
		}
		
		override protected function setNameText(char_count:uint):void {
			var name_txt:String = '<p class="super_search_location_base">';
			if(is_active) name_txt += '<span class="super_search_active">';
			if(current_value == current_hub_tsid) name_txt += '<span class="super_search_location_hub">';
			if(!current_highlight){
				name_txt += StringUtil.truncate(current_name, char_count);
			}
			else {
				//run it through the colorizer
				name_txt += StringUtil.colorCharacters(StringUtil.truncate(current_name, char_count), current_highlight, highlight_class);
			}
			if(current_value == current_hub_tsid) name_txt += '</span>';
			if(is_active) name_txt += '</span>';
			name_txt += '</p>';
			
			name_tf.htmlText = name_txt;
		}
		
		override protected function draw():void {
			super.draw();
			
			//indent the TF if this is a regular street
			name_tf.x = TEXT_PADD + (current_value != current_hub_tsid ? TEXT_PADD : 0);
			name_tf.width = _w - name_tf.x;
		}
		
		public function get hub_tsid():String { return current_hub_tsid; }
	}
}