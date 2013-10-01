package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.ProgressBar;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;
	import flash.text.TextField;

	public class DailyProgress extends Sprite
	{
		private const ICON_BUFFER:int = 12;
		
		private var title_tf:TextField = new TextField();
		private var current_tf:TextField = new TextField();
		private var total_tf:TextField = new TextField();
		
		private var pb:ProgressBar;
		
		private var _icon:DisplayObject;
		
		private var _current_value:int;
		private var _max_value:int;
		
		public function DailyProgress(progress_w:int, progress_h:int, icon:DisplayObject = null, title:String = '&nbsp;'){
			TFUtil.prepTF(title_tf, false);
			TFUtil.prepTF(current_tf, false);
			TFUtil.prepTF(total_tf, false);
			
			pb = new ProgressBar(progress_w, progress_h);
			pb.setFrameColors(0xc3cace, 0xaab0b3);
			pb.addChild(current_tf);
			pb.addChild(total_tf);
			addChild(pb);
			
			//filters for the TFs
			var drop:DropShadowFilter = new DropShadowFilter();
			drop.color = 0xffffff;
			drop.distance = 1;
			drop.angle = 90;
			drop.strength = 3;
			drop.alpha = .3;
			drop.blurX = drop.blurY = 0;
			
			current_tf.filters = [drop];
			total_tf.filters = [drop];
			
			//check for title
			this.title = title;
			addChild(title_tf);
			
			//check for an icon
			if(icon) this.icon = icon;
		}
		
		public function update(new_value:Number, txt_after_value:String):void {
			if(_max_value == 0 && _max_value < new_value){
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('max_value is 0 and the new_value is larger than that... This right to you?');
				}
			}
			
			_current_value = new_value;
			
			//show the current text
			current_tf.htmlText = '<p class="daily_pb_current">'+_current_value+' '+txt_after_value+'</p>';
			current_tf.x = 10;
			current_tf.y = int(pb.height/2 - current_tf.height/2);
			
			//calculate the remaing amount
			var remaining:int = _max_value - _current_value;
			total_tf.htmlText = '<p class="daily_pb_remaining">'+remaining+' remaining</p>';
			total_tf.x = pb.width - total_tf.width - 10;
			total_tf.y = int(pb.height/2 - total_tf.height/2);
			
			//update the progress bar
			pb.update(_current_value/_max_value);
		}
		
		public function get icon():DisplayObject { return _icon; }
		public function set icon(value:DisplayObject):void {
			if(value){
				if(_icon) removeChild(_icon);
				
				_icon = value;
				title_tf.x = _icon.width + ICON_BUFFER;
				pb.x = _icon.width + ICON_BUFFER;
				
				icon.y = int(height/2 - icon.height/2) + 4;
				
				addChild(_icon);
			} 
		}
		
		public function set title(value:String):void {
			title_tf.htmlText = '<p class="daily_pb_title">'+value+'</p>';
			pb.y = title_tf.height;
		}
		
		public function get current_value():int { return _current_value; }
		
		public function get max_value():int { return _max_value; }
		public function set max_value(value:int):void {
			_max_value = value;
		}
	}
}