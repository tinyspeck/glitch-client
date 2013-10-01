package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.util.SpriteUtil;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;

	public class ButtonGrid extends Sprite
	{		
		private var buttonsV:Vector.<Button>;
				
		//setup some defaults
		private var max_w:uint;
		private var max_h:uint;
		private var rows:uint;
		private var cols:uint;
		private var current_row:int;
		private var current_col:int;
		private var min_button_w:uint = 65;
		private var min_button_h:uint = 39;
		private var max_button_w:uint = 136;
		private var max_button_h:uint = 84;
		private var h_padding:int = 12;
		private var v_padding:int = 8;
		
		private var disabled_type:String;
		private var disabled_pattern:BitmapData;
		private var show_disabled_pattern:Boolean;
		
		public function ButtonGrid(init_ob:Object = null){
			if(init_ob){
				init(init_ob);
			}
			else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('Created ButtonGrid without an init_ob, make sure you set an init_ob when you want to use it!');
				}
			}
		}
		
		private function init(init_ob:Object):void {
			if(!init_ob){
				CONFIG::debugging {
					Console.warn('init_ob was null');
				}
				return;
			}
			//error out if we have to
			if(init_ob.rows == 0 || init_ob.cols == 0){
				CONFIG::debugging {
					Console.warn('Missing rows or columns');
				}
				return;
			}
			
			//make sure we have the basics
			if(init_ob.hasOwnProperty('buttonsV') && init_ob.buttonsV is Vector.<Button>){
				buttonsV = init_ob.buttonsV;
			} else {
				CONFIG::debugging {
					Console.warn('missing buttonsV. Fix it!');
				}
				return;
			}
			
			//setup the goodness kids go for
			rows = init_ob.rows;
			cols = init_ob.cols;
			current_row = init_ob.current_row;
			current_col = init_ob.current_col;
			h_padding = init_ob.hasOwnProperty('h_padding') ? init_ob.h_padding : h_padding;
			v_padding = init_ob.hasOwnProperty('v_padding') ? init_ob.v_padding : v_padding;
			min_button_w = init_ob.hasOwnProperty('min_button_w') ? init_ob.min_button_w : min_button_w;
			min_button_h = init_ob.hasOwnProperty('min_button_h') ? init_ob.min_button_h : min_button_h;
			max_button_w = init_ob.hasOwnProperty('max_button_w') ? init_ob.max_button_w : max_button_w;
			max_button_h = init_ob.hasOwnProperty('max_button_h') ? init_ob.max_button_h : max_button_h;
			max_w = init_ob.hasOwnProperty('max_w') ? init_ob.max_w : ((max_button_w + h_padding) * cols) - h_padding;
			max_h = init_ob.hasOwnProperty('max_h') ? init_ob.max_h : ((max_button_h + v_padding) * rows) - v_padding;
			disabled_type = init_ob.hasOwnProperty('disabled_type') ? init_ob.disabled_type : Button.TYPE_QUARTER_DISABLED;
			disabled_pattern = init_ob.hasOwnProperty('disabled_pattern') ? init_ob.disabled_pattern : null;
			show_disabled_pattern = init_ob.hasOwnProperty('show_disabled_pattern') ? init_ob.show_disabled_pattern : false;
			
			draw();
		}
		
		private function draw():void {
			SpriteUtil.clean(this);
			
			//figure out the size we are making the buttons
			var bt:Button;
			var bt_w:int = Math.max(Math.min((max_w / cols) - h_padding, max_button_w), min_button_w);
			var bt_h:int = Math.max(Math.min((max_h / rows) - v_padding, max_button_h), min_button_h);
			var i:int;
			var cur_row:int = 1;
			var cur_col:int = 1;
			
			for(i = 1; i <= rows * cols; i++){
				//place them where they need to go				
				bt = getButton(cur_col, cur_row);
				if(bt){
					bt.x = (cur_col-1) * (bt_w + h_padding);
					bt.y = (cur_row-1) * (bt_h + v_padding);
					bt.w = bt_w;
					bt.h = bt_h;
					addChild(bt);
				}
				
				cur_row++;
				if(cur_row == rows+1){
					cur_row = 1;
					cur_col++;
				}
			}
		}
		
		private function getButton(col:int, row:int):Button {
			var i:int;
			var bt:Button;
						
			for(i = 0; i < buttonsV.length; i++){
				bt = buttonsV[int(i)];
				if(bt.name == col+'_'+row) return bt;
			}
			
			//if we made it down here we have to send back an empty disabled button
			if(buttonsV.length > 0){
				bt = new Button({
					name: col+'_'+row,
					value: '',
					size: Button.SIZE_DEFAULT, //used to set the corners since the w/h is set in draw
					type: disabled_type,
					disabled: true,
					show_disabled_pattern: show_disabled_pattern,
					disabled_pattern: disabled_pattern
				});
			}
			
			return bt;
		}
		
		public function setRowsAndCols(rows:int, cols:int):void {
			if(rows && cols){
				this.rows = rows;
				this.cols = cols;
				
				draw();
			}
		}
		
		public function setCurrentColAndRow(col:int, row:int):void {
			this.current_row = row;
			this.current_col = col;
			
			draw();
		}
		
		public function setButtonDimensions(min_w:int, min_h:int, max_w:int, max_h:int):void {
			min_button_w = min_w;
			min_button_h = min_h;
			max_button_w = max_w;
			max_button_h = max_h;
			
			draw();
		}
		
		public function set init_ob(value:Object):void {
			if(value){
				init(value);
			}
		}
	}
}