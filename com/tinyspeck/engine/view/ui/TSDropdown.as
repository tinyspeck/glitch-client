package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.SpriteUtil;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	public class TSDropdown extends TSSpriteWithModel
	{
		protected static const BREAK_STRING:String = '~!@BREAK@!~'; //used when the dropdown needs a line between items
		
		protected var menu_holder:Sprite = new Sprite();
		protected var menu_mask:Sprite = new Sprite();
		
		protected var lines:Vector.<Sprite> = new Vector.<Sprite>();
		protected var buttons:Vector.<Button> = new Vector.<Button>();
		protected var bt_objects:Array = [];
		protected var bt_funcs:Vector.<Function> = new Vector.<Function>();
		protected var bt_funcs_params:Vector.<Object> = new Vector.<Object>();
		protected var bt_size:String;
		protected var bt_type:String;
		protected var bt_max_w:int;
		
		protected var is_open:Boolean;
		protected var is_built:Boolean;
		
		//protected var _w:int; //the width of the whole menu
		//protected var _h:int; //the height of the button that opens the menu (so it knows where to place itself)
		protected var _border_width:int = 1;
		protected var _border_color:uint = 0xcfdbdf;
		protected var _button_padding:int;
		protected var _button_label_x:int;
		protected var _corner_radius:Number = 4.5;
		protected var _auto_width:Boolean;
		
		public function TSDropdown(){
			//put some defaults in there
			bt_size = Button.SIZE_VERB;
			bt_type = Button.TYPE_VERB;
		}
		
		protected function buildBase():void {
			//build the outline and mask
			onRollOut();
			
			addEventListener(MouseEvent.ROLL_OVER, onRollOver, false, 0, true);
			addEventListener(MouseEvent.ROLL_OUT, onRollOut, false, 0, true);
			addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			
			//menu
			addChild(menu_mask);
			addChild(menu_holder);
			menu_holder.mask = menu_mask;
			
			//mouse stuff
			useHandCursor = buttonMode = true;
			
			is_built = true;
		}
		
		public function cleanArrays():void {
			bt_objects.length = 0;
			bt_funcs.length = 0;
			bt_funcs_params.length = 0;
		}
		
		public function addItem(ob:Object, func:Function = null, ...func_params:Array):void {
			// we use to just pass label strings as the first arg (and we still can) but now you can
			// also pass an anonymous object that specifies the label and if the option is disabled.
			// TODO: make it a classed object, and have it include the func and params as members
			// so we do not need to maintain 3 arrays
			
			// let's convert simple strings to objects
			if (ob is String) {
				ob = {
					label: ob,
					disabled: false
				}
			}
			
			bt_objects.push(ob);
			if(ob.label != BREAK_STRING){
				bt_funcs.push(func);
				bt_funcs_params.push(func_params.length ? func_params : null);
			}
		}
		
		protected function buildMenu():void {
			var i:int;
			var bt:Button;
			var line_break:Sprite;
			var g:Graphics;
			var next_y:int = _button_padding;
			var bt_index:int;
			var line_index:int;
			const line_break_height:uint = 1;
			
			//reset the pools
			for(i = 0; i < lines.length; i++){
				line_break = lines[int(i)];
				line_break.x = line_break.y = 0;
				line_break.visible = false;
			}
			
			// clean it out so auto sizing works correctly when rebuilding
			if (_auto_width) {
				buttons.length = 0;
				SpriteUtil.clean(menu_holder);
			}
			
			for(i = 0; i < buttons.length; i++){
				bt = buttons[int(i)];
				bt.x = bt.y = 0;
				bt.visible = false;
			}
			
			var label:String;
			var disabled:Boolean;
			
			//throw on the buttons and lines
			for(i = 0; i < bt_objects.length; i++){
				label = bt_objects[int(i)].label;
				disabled = bt_objects[int(i)].disabled === true;
				
				if(label != BREAK_STRING){
					if(buttons.length > bt_index){
						bt = buttons[int(bt_index)];
						bt.visible = true;
						bt.disabled = disabled;
					}
					else {
						bt = new Button({
							name: 'bt'+bt_index,
							size: bt_size,
							type: bt_type,
							text_align: 'left',
							label_offset: 2,
							disabled: disabled,
							offset_x: _button_label_x //name_tf.x - BUTTON_PADD -- if/when icons come into play
						});
						bt.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
						buttons.push(bt);
						menu_holder.addChild(bt);
					}
					
					bt.label = label;
					bt.value = bt_funcs[bt_index];
					bt.x = _button_padding;
					bt.y = next_y;
					
					//handle the width of the button if we are not auto-sizing
					if(!auto_width) {
						bt.w = _w - _button_padding*2;
					}
					else if(bt.width > bt_max_w){
						bt_max_w = bt.width + _button_label_x;
					}
					
					next_y += bt.height;
					
					bt_index++;
				}
				else {
					if(lines.length > line_index){
						line_break = lines[int(line_index)];
						line_break.visible = true;
					}
					else {
						line_break = new Sprite();
						lines.push(line_break);
					}
					
					g = line_break.graphics;
					g.beginFill(_border_color);
					g.drawRect(0, 0, _w - _button_padding*2, line_break_height);
					line_break.x = _button_padding;
					line_break.y = _button_padding + next_y + line_break_height;
					menu_holder.addChild(line_break);

					next_y += _button_padding*2 + line_break_height;
					
					line_index++;
				}
			}
			
			//if we are auto-sizing, make sure things get the proper width
			if(auto_width){
				_w = bt_max_w + button_padding*2;
				bt_index = 0;
				line_index = 0;
				
				for(i = 0; i < bt_objects.length; i++){
					label = bt_objects[int(i)].label;
					if(label != BREAK_STRING){
						bt = buttons[int(bt_index)];
						bt.w = bt_max_w;
						bt_index++;
					}
					else {
						line_break = lines[int(line_index)];
						g = line_break.graphics;
						g.beginFill(_border_color);
						g.drawRect(0, 0, _w - _button_padding*2, line_break_height);
						line_index++;
					}
				}
			}
			
			//draw the menu bg
			g = menu_holder.graphics;
			g.clear();
			g.lineStyle(_border_width, _border_color);
			g.beginFill(0xffffff);
			g.drawRoundRectComplex(0,0, _w, next_y + _button_padding, 0, 0, _corner_radius, _corner_radius);
			
			//where should this go?
			menu_holder.y = is_open ? _h : -menu_holder.height;
			
			//draw the mask
			menu_mask.x = menu_holder.x;
			g = menu_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRect(0,_h, _w + _border_width*2, menu_holder.height);
		}
		
		protected function toggleMenu():void {
			is_open = !is_open;
			
			const menu_y:int = is_open ? _h : -menu_holder.height;
			const tween_type:String = is_open ? 'easeOutCubic' : 'easeInCubic';
			
			if(is_open){
				StageBeacon.stage.addEventListener(MouseEvent.CLICK, onStageClick, false, 0, true);
				onRollOver(); //we want this to draw instantly
			}
			else {
				StageBeacon.stage.removeEventListener(MouseEvent.CLICK, onStageClick, false);
			}
			
			//animate
			TSTweener.removeTweens(menu_holder);
			TSTweener.addTween(menu_holder, {y:menu_y, time:.2, transition:tween_type, onComplete:onRollOver});
		}
		
		protected function onRollOver(event:MouseEvent = null):void {
			//do roll over things
		}
		
		protected function onRollOut(event:MouseEvent = null):void {
			//do roll out things
			if(is_open) return;
		}
		
		protected function onClick(event:MouseEvent):void {			
			//toggle the menu
			if(event.target is Button == false){
				toggleMenu();
			}
		}
		
		protected function onButtonClick(event:TSEvent):void {
			var bt:Button = event.data as Button;
			if(!bt) return;
			if(bt.disabled) return;
			
			const bt_index:int = buttons.indexOf(bt);
			const bt_params:Object = bt_index >= 0 ? bt_funcs_params[int(bt_index)] : null;
						
			//close menu
			toggleMenu();
			
			//set the roll out
			onRollOut();
			
			//run the function
			if(bt.value is Function){
				if(!bt_params){
					(bt.value as Function).apply();
				}
				else {
					//send off the goods
					(bt.value as Function).apply(null, bt_params);
				}
			}
		}
		
		protected function onStageClick(event:MouseEvent):void {
			var p:DisplayObjectContainer = event.target as DisplayObjectContainer;
			
			// see if the click is on a child of this and ignore it if so
			while (p) {
				if (p == this) {
					return;
				}
				p = p.parent;
			}
			
			toggleMenu();
			//set the roll out
			onRollOut();
		}
		
		public function getBasePt():Point {
			var pt:Point = localToGlobal(new Point(_w/2, _h));
			
			return pt;
		}
		
		override public function get w():int { return _w; }
		public function set w(value:int):void {
			_w = value;
			buildMenu();
		}
		
		override public function get h():int { return _h; }
		public function set h(value:int):void {
			_h = value;
			buildMenu();
		}
		
		public function get border_width():int { return _border_width; }
		public function set border_width(value:int):void {
			_border_width = value;
			buildMenu();
		}
		
		public function get border_color():uint { return _border_color; }
		public function set border_color(value:uint):void {
			_border_color = value;
			buildMenu();
		}
		
		public function get button_padding():uint { return _button_padding; }
		public function set button_padding(value:uint):void {
			_button_padding = value;
			buildMenu();
		}
		
		public function get button_label_x():uint { return _button_label_x; }
		public function set button_label_x(value:uint):void {
			_button_label_x = value;
			buildMenu();
		}
		
		public function get corner_radius():Number { return _corner_radius; }
		public function set corner_radius(value:Number):void {
			_corner_radius = value;
			buildMenu();
		}
		
		public function get auto_width():Boolean { return _auto_width; }
		public function set auto_width(value:Boolean):void {
			_auto_width = value;
			buildMenu();
		}
	}
}