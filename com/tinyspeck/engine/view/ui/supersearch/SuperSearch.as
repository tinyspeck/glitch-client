package com.tinyspeck.engine.view.ui.supersearch
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.Hub;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.making.Recipe;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSScroller;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;

	public class SuperSearch extends TSSpriteWithModel implements IFocusableComponent
	{
		public static const TYPE_BUDDIES:String = 'type_buddies';
		public static const TYPE_ITEMS:String = 'type_items';
		public static const TYPE_ANYTHING:String = 'type_anything';
		public static const TYPE_INVENTORY:String = 'type_inventory';
		public static const TYPE_LOCATIONS:String = 'type_locations';
		public static const TYPE_RECIPES:String = 'type_recipes';
		public static const DIRECTION_DOWN:String = 'direction_down';
		public static const DIRECTION_UP:String = 'direction_up';
		
		protected static const INPUT_PADD:uint = 10;
		protected static const SCROLL_BAR_W:uint = 12;
		protected static const DEFAULT_WIDTH:uint = 250;
		
		protected var dividers:Vector.<Sprite> = new Vector.<Sprite>();
		protected var buddy_elements:Vector.<SuperSearchElementBuddy>;
		protected var item_elements:Vector.<SuperSearchElementItem>;
		protected var inventory_elements:Vector.<SuperSearchElementItemstack>;
		protected var location_elements:Vector.<SuperSearchElementLocation>;
		protected var recipe_elements:Vector.<SuperSearchElementRecipe>;
		protected var result_scroller:TSScroller;
		protected var no_result_element:SuperSearchElementNoResult = new SuperSearchElementNoResult();
		
		protected var input_tf:TextField = new TextField();
		
		protected var input_holder:Sprite = new Sprite();   //apply filters to this
		protected var input_content:Sprite = new Sprite();
		protected var input_mask:Sprite = new Sprite();
		protected var result_holder:Sprite = new Sprite();  //apply filters to this
		protected var result_content:Sprite = new Sprite();
		protected var result_mask:Sprite = new Sprite();
		
		protected var border_glow:GlowFilter = new GlowFilter();
				
		protected var bg_color:uint;
		protected var bg_color_input:uint;
		protected var bg_color_input_blur:uint;
		protected var bg_color_input_alpha:Number = 1;
		protected var border_color:uint;
		protected var border_width:int;
		protected var border_alpha:Number = 1;
		protected var unfocused_alpha:Number;
		protected var vert_arrow_repeat_cnt:int;
		protected var current_child_index:int;
		protected var displayed_before_scroll:int;
		protected var next_y:int;
		protected var min_chars_before_search:uint; //changed in set type()
		
		protected var default_txt:String;
		
		protected var has_focus:Boolean;
		protected var is_built:Boolean;
		protected var use_keyboard:Boolean;
		
		protected var _type:String;
		protected var _corner_rad:Number = 4;
		protected var _show_images:Boolean;
		protected var _buddy_tsids_to_exclude:Array;
		protected var _item_tags_to_exclude:Array;
		protected var _direction:String;
		protected var _is_in_encyc:Boolean;
		
		public function SuperSearch(){
			//let the state model know who we are
			model.stateModel.registerFocusableComponent(this);
		}
		
		protected function buildBase():void {			
			//input
			TFUtil.prepTF(input_tf);
			input_tf.embedFonts = false;
			input_tf.multiline = false;
			input_tf.mouseEnabled = input_tf.selectable = true;
			input_tf.type = TextFieldType.INPUT;
			input_tf.x = INPUT_PADD;
			input_tf.addEventListener(FocusEvent.FOCUS_IN, onInputFocus, false, 0, true);
			input_tf.addEventListener(FocusEvent.FOCUS_OUT, onInputBlur, false, 0, true);
			input_tf.addEventListener(Event.CHANGE, onInputChange, false, 0, true);
			input_content.addChild(input_tf);
			input_content.mask = input_mask;
			
			input_holder.addChild(input_mask);
			input_holder.addChild(input_content);
			addChild(input_holder); //fuck you flash 11.0
			
			//results
			result_scroller = new TSScroller({
				name: 'results',
				bar_wh: SCROLL_BAR_W,
				bar_handle_min_h: 36,
				use_children_for_body_h: true,
				bar_color: 0xecf0f1,
				bar_border_color: 0xd2dadc,
				bar_border_width: 1,
				bar_handle_color: 0xcfdcdd,
				bar_handle_border_color: 0xb0bfc2,
				bar_handle_stripes_alpha: 0,
				show_arrows: true
			});
			result_content.addChild(result_scroller);
			result_content.mask = result_mask;
			result_content.visible = false;
			
			result_holder.addChild(result_mask);
			result_holder.addChild(result_content);
			addChild(result_holder); //fuck you flash 11.0
			
			_w = _w || DEFAULT_WIDTH;
			
			is_built = true;
			
			//load the default style
			setAppearanceFromCSS('super_search');
			
			//load the default style for no results
			no_result_element.setAppearanceFromCSS('super_search_no_result');
			
			//hide it
			hide();
		}
		
		public function init(type:String, displayed_before_scroll:uint = 3, custom_default_txt:String = '', direction:String = SuperSearch.DIRECTION_DOWN):void {
			if(!is_built) buildBase();
			
			this.type = type;
			this.displayed_before_scroll = displayed_before_scroll;
			this.direction = direction;
			
			//setup defaults
			default_txt = 'Search';
			switch(type){
				case TYPE_BUDDIES:
					default_txt = 'Start typing your friend’s name';
					buddy_elements = new Vector.<SuperSearchElementBuddy>();
					break;
				case TYPE_ITEMS:
					default_txt = 'Start typing an item name';
					item_elements = new Vector.<SuperSearchElementItem>();
					break;
				case TYPE_INVENTORY:
					inventory_elements = new Vector.<SuperSearchElementItemstack>();
					break;
				case TYPE_LOCATIONS:
					location_elements = new Vector.<SuperSearchElementLocation>();
					break;
				case TYPE_RECIPES:
					recipe_elements = new Vector.<SuperSearchElementRecipe>();
					break;
				case TYPE_ANYTHING:
				default:
					buddy_elements = new Vector.<SuperSearchElementBuddy>();
					item_elements = new Vector.<SuperSearchElementItem>();
					inventory_elements = new Vector.<SuperSearchElementItemstack>();
					location_elements = new Vector.<SuperSearchElementLocation>();
					recipe_elements = new Vector.<SuperSearchElementRecipe>();
					break;
			}
			
			//put a custom default message in there
			if(custom_default_txt) {
				default_txt = custom_default_txt;
			}
			
			//set the input to have the default text
			input_tf.text = default_txt;
			input_tf.alpha = unfocused_alpha;
			
			draw();
		}
		
		public function show(and_focus:Boolean = false, input_txt:String = ''):void {
			if(!type){
				CONFIG::debugging {
					Console.warn('You need to init() first cowboy!');
				}
				return;
			}
			
			//show it!
			visible = true;
			
			const element:SuperSearchElement = getSelectedElement();
			if(element){
				input_content.removeChild(element);
				draw();
			}
			
			clearDividers();
			
			input_tf.text = !input_txt ? default_txt : input_txt;
			input_tf.alpha = unfocused_alpha;
			
			if(!and_focus){
				onInputChange();
			}
			else {
				onInputFocus();
				
				//this gets around the issue where if this was called with a key (like shift+F it won't put the "F" in the input field)
				input_tf.text = input_txt == default_txt ? '' : input_txt;
				StageBeacon.waitForNextFrame(function():void {
					input_tf.text = !input_tf.text ? '' : input_txt;
					input_tf.setSelection(0, input_tf.text.length);
					onInputChange();
				});
			}
		}
		
		public function hide(event:Event = null):void {
			input_tf.text = '';
			onInputChange();
			blurInput();
			
			visible = false;
			
			dispatchEvent(new TSEvent(TSEvent.CLOSE, this));
		}
		
		protected function draw():void {
			if(!is_built) buildBase();
						
			input_tf.width = _w - input_tf.x - INPUT_PADD;
			input_tf.y = int(_h/2 - input_tf.height/2);
			
			const element:SuperSearchElement = getSelectedElement();
			const input_height:int = element ? element.height : _h;
			const result_height:int = result_scroller.y + result_scroller.h + (direction == DIRECTION_DOWN ? 0 : _corner_rad*2);
						
			//input
			var g:Graphics = input_content.graphics;
			g.clear();
			g.beginFill(has_focus ? bg_color_input : bg_color_input_blur, bg_color_input_alpha);
			g.drawRect(input_tf.x - INPUT_PADD, 0, input_tf.width + INPUT_PADD*2, input_height);
			
			g = input_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRoundRect(input_tf.x - INPUT_PADD, 0, input_tf.width + INPUT_PADD*2, input_height, _corner_rad*2);
			
			//results
			g = result_content.graphics;
			g.clear();
			g.beginFill(bg_color);
			g.drawRect(0, 0, _w, result_height);
			g.beginFill(border_color, border_alpha);
			g.drawRect(0, _corner_rad, _w, border_width);
			
			g = result_mask.graphics;
			g.clear();
			g.beginFill(0);
			if(direction == DIRECTION_DOWN){
				g.drawRoundRectComplex(0, 0, _w, result_height, 0, 0, _corner_rad, _corner_rad);
			}
			else {
				g.drawRoundRectComplex(0, 0, _w, result_height, _corner_rad, _corner_rad, 0, 0);
			}
			
			//if the scroller needs adjusting, do it
			if(result_scroller.w != _w)	result_scroller.w = _w;
			if(direction == DIRECTION_DOWN && result_content.y != _h - _corner_rad){
				result_content.y = result_mask.y = _h - _corner_rad;
			}
		}
		
		public function setAppearanceFromCSS(style_name:String):void {
			const cssm:CSSManager = CSSManager.instance;
			bg_color = cssm.getUintColorValueFromStyle(style_name, 'backgroundColor', 0xffffff);
			border_color = cssm.getUintColorValueFromStyle(style_name, 'borderColor', 0x96c3d8);
			border_width = cssm.getNumberValueFromStyle(style_name, 'borderWidth', 0);
			border_alpha = cssm.getNumberValueFromStyle(style_name, 'borderAlpha', border_alpha);
			unfocused_alpha = cssm.getNumberValueFromStyle(style_name, 'unfocusedAlpha', .3);
			bg_color_input = cssm.getUintColorValueFromStyle(style_name, 'backgroundColorInput', bg_color);
			bg_color_input_blur = cssm.getUintColorValueFromStyle(style_name, 'backgroundColorInputBlur', bg_color_input);
			bg_color_input_alpha = cssm.getUintColorValueFromStyle(style_name, 'backgroundColorInputAlpha', bg_color_input_alpha);
			
			//input text
			TFUtil.setTextFormatFromStyle(input_tf, style_name);
			input_tf.text = 'placeholder';
			_h = input_tf.height + 4;
			
			//handle the border glow
			if(border_width){
				border_glow.color = cssm.getUintColorValueFromStyle(style_name, 'glowColor', border_color);
				border_glow.blurX = border_glow.blurY = border_width+1;
				border_glow.strength = 12;
				border_glow.alpha = border_alpha;
			}
			filters = border_width ? [border_glow] : null;
			
			draw();
		}
		
		protected function onInputFocus(event:FocusEvent = null):void {
			if(!has_focus) {
				if(!TSFrontController.instance.requestFocus(this, 'input name: '+name)) {
					CONFIG::debugging {
						Console.warn('could not take focus');
					}
					// you cannot blur an input during the hanlder for its focusing
					StageBeacon.waitForNextFrame(blurInput);
				}
			}
			//onRollOver();
			dispatchEvent(new TSEvent(TSEvent.FOCUS_IN, this));
			
			//the input is ready to rock
			input_tf.alpha = 1;
			if(input_tf.text == default_txt) {
				input_tf.text = '';
			}
			else if(input_tf.text != ''){
				onInputChange();
			}
		}
		
		/**
		 * @param event
		 * @see InputField onInputBlur
		 */		
		protected function onInputBlur(event:FocusEvent):void {
			if(has_focus) {
				if(event.relatedObject && event.relatedObject is Button) {
					StageBeacon.mouse_up_sig.add(onStageMouseUp);
				} 
				else {
					TSFrontController.instance.releaseFocus(this, 'onInputBlur()');
				}
				dispatchEvent(new TSEvent(TSEvent.FOCUS_OUT, this));
			}
			//onRollOut();
			
			//reset the input if there is nothing in it
			if(input_tf.text == '') {
				input_tf.alpha = unfocused_alpha;
				input_tf.text = default_txt;
			}
		}
		
		protected function onInputChange(event:Event = null):void {			
			const input_txt:String = input_tf.text;
			
			//clear out the current dividers
			clearDividers();
			
			//clear out the no results
			if(no_result_element.parent) no_result_element.parent.removeChild(no_result_element);
			
			if(input_txt != '' && input_txt != default_txt && input_txt.length >= min_chars_before_search){				
				//clear out the current index
				current_child_index = -1;
				
				//reset the Y position
				next_y = 0;
				
				//figure out where/what we need to search
				switch(type){
					case TYPE_BUDDIES:
						searchBuddies(input_txt);
						break;
					case TYPE_ITEMS:
						searchItems(input_txt);
						break;
					case TYPE_RECIPES:
						searchRecipes(input_txt);
						break;
					case TYPE_INVENTORY:
						searchInventory(input_txt);
						break;
					case TYPE_LOCATIONS:
						searchLocations(input_txt);
						break;
					case TYPE_ANYTHING:
					default:
						searchBuddies(input_txt);
						searchItems(input_txt);
						searchInventory(input_txt);
						searchLocations(input_txt);
						break;
				}
				
				//if we don't have any results, let's say that
				const total:int = result_scroller.body.numChildren;
				if(!total){
					result_scroller.body.addChild(no_result_element);
					no_result_element.show(_w, input_txt);
					next_y += no_result_element.height;
				}
				
				//put on the dividers
				placeDividers();
				
				//if we have results, show em
				result_content.visible = true;
				current_child_index = no_result_element.parent ? -1 : 0;
				
				if(direction == DIRECTION_UP){
					result_content.y = result_mask.y = -result_scroller.h;
				}
				
				setActiveElement();
			}
			else {
				//if we are showing results, hide them
				current_child_index = -1;
				result_content.visible = false;
			}
			
			if(current_child_index == -1){
				//if we don't have anything, make sure that anyone listening knows
				dispatchEvent(new TSEvent(TSEvent.ACTIVITY_HAPPENED, null));
			}
			
			//refresh the scroller
			result_scroller.refreshAfterBodySizeChange(true);
			
			//turn on keyboard
			use_keyboard = true;
			
			//listen for when the mouse moves to shut off the key board
			StageBeacon.mouse_move_sig.add(onMouseMove);
		}
		
		protected function onStageMouseUp(event:MouseEvent):void {
			StageBeacon.mouse_up_sig.remove(onStageMouseUp);
			TSFrontController.instance.releaseFocus(this, 'mouse up');
		}
		
		protected function arrowHandler(event:KeyboardEvent):void {
			use_keyboard = true;
			
			//check for the up/down arrow
			if(event.type == KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.UP || event.type == KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.DOWN){
				if(vert_arrow_repeat_cnt % 5 == 0) { // only act on every 5th event
					changeSelection(event.type == KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.DOWN);
				}
				vert_arrow_repeat_cnt++;
				return;
			}
			
			if(event.type == KeyBeacon.KEY_UP_+Keyboard.UP || event.type == KeyBeacon.KEY_UP_+Keyboard.DOWN) {
				focusOnInput();
				vert_arrow_repeat_cnt = 0;
				return;
			}
			
			if(event.type == KeyBeacon.KEY_DOWN_+Keyboard.UP || event.type == KeyBeacon.KEY_DOWN_+Keyboard.DOWN) {
				focusOnInput();
				changeSelection(event.type == KeyBeacon.KEY_DOWN_+Keyboard.DOWN);
			}
		}
		
		protected function changeSelection(is_next:Boolean):void {
			var i:int;
			var total:int = result_scroller.body.numChildren;
			var changed:Boolean;
			
			if(is_next && current_child_index < total-1){
				current_child_index++;
				changed = true;
			}
			else if(!is_next && current_child_index > 0 && total){
				current_child_index--;
				changed = true;
			}
			
			//set the active one
			if(changed){
				setActiveElement();
				
				//move the scroller so the active one is at the top
				const new_scroll_y:int = Math.min(result_scroller.body.getChildAt(current_child_index).y, result_scroller.max_scroll_y - border_width);
				result_scroller.scrollYToTop(new_scroll_y);
			}
		}
		
		protected function makeSelection():void {
			if(current_child_index == -1) return;
			const element:SuperSearchElement = result_scroller.body.getChildAt(current_child_index) as SuperSearchElement;
			
			if(element){
				//remove the element from the scroller and add it to the input holder
				element.y = 0;
				element.is_active = false;
				element.show_close_bt = true;
				element.width = _w;
				element.highlight_text = null;
				input_content.addChild(element);
				result_content.visible = false;
				clearDividers();
				draw();
				
				//pass the element on to the listeners
				dispatchEvent(new TSEvent(TSEvent.CHANGED, element));
			}
		}
		
		protected function setActiveElement():void {
			if(current_child_index == -1) return;
			
			var i:int;
			var element:SuperSearchElement;
			const total:int = result_scroller.body.numChildren;
			
			for(i; i < total; i++){
				element = result_scroller.body.getChildAt(i) as SuperSearchElement;
				element.is_active = i == current_child_index;
				
				if(i == current_child_index){
					//let the listeners know that something happened
					dispatchEvent(new TSEvent(TSEvent.ACTIVITY_HAPPENED, element));
				}
			}
		}
		
		public function getSelectedElement():SuperSearchElement {
			var i:int;
			var total:int = input_content.numChildren;
			var child:DisplayObject;
			
			for(i; i < total; i++){
				child = input_content.getChildAt(i);
				if(child is SuperSearchElement){
					return child as SuperSearchElement;
				}
			}
			
			return null;
		}
		
		protected function clearDividers():void {
			var i:int;
			var total:int = dividers.length;
			var divider:Sprite;
			
			for(i = 0; i < total; i++){
				divider = dividers[int(i)];
				if(divider.parent) divider.parent.removeChild(divider);
			}
		}
		
		protected function placeDividers():void {
			var total:int = result_scroller.body.numChildren;
			var i:int;
			var element:SuperSearchElement;
			var divider:Sprite;
			var g:Graphics;
			
			for(i = 0; i < total; i++){
				element = result_scroller.body.getChildAt(i) as SuperSearchElement;
				
				if(i < total-1){
					if(dividers.length > i){
						divider = dividers[int(i)];
					}
					else {
						divider = new Sprite();
						dividers.push(divider);
					}
					
					g = divider.graphics;
					g.clear();
					g.beginFill(border_color, border_alpha);
					g.drawRect(0, 0, _w, border_width);
					divider.y = element.height - border_width;
					element.addChild(divider);
				}
			}
			
			//set the scroller height
			if(element){
				const new_height:int = Math.min(next_y, element.height * displayed_before_scroll - (total > displayed_before_scroll ? border_width : 0));
				if(result_scroller.h != new_height){
					result_scroller.h = new_height;
					draw();
				}
			}
			
			//if we are going UP make sure that we add a divider to the bottom of the scroller to make it look pretty
			if(direction == DIRECTION_UP && total){
				if(dividers.length > i){
					divider = dividers[int(i)];
				}
				else {
					divider = new Sprite();
					dividers.push(divider);
				}
				
				g = divider.graphics;
				g.beginFill(border_color, border_alpha);
				g.drawRect(0, 0, _w, border_width);
				divider.y = 0;
				addChild(divider);
			}
		}
		
		protected function onKeyDown(event:KeyboardEvent):void {			
			//if they mashed enter, let's make the selection
			if(event.keyCode == Keyboard.ENTER && !getSelectedElement()){
				makeSelection();
			}
		}
		
		protected function onEscape(event:KeyboardEvent = null):void {
			//if we have a selected element, remove that, if not, blur the input
			const element:SuperSearchElement = getSelectedElement();
						
			if(element){
				//remove the element and show the search from where it was before
				input_content.removeChild(element);
				draw();
				
				//little hack for speedy focus changing when clicking with a mouse
				if(StageBeacon.stage.focus != input_tf){
					StageBeacon.waitForNextFrame(focusOnInput);
				}

				StageBeacon.waitForNextFrame(onInputChange);
				
				//let the listeners know we've changed something
				dispatchEvent(new TSEvent(TSEvent.CHANGED));
			}
			else {
				//hide scroller and drop focus
				result_content.visible = false;
				blurInput();
				clearDividers();
			}
		}
		
		protected function onElementClick(event:MouseEvent):void {
			const element:SuperSearchElement = event.currentTarget as SuperSearchElement;
			if(result_scroller.body.contains(element)){
				current_child_index = result_scroller.body.getChildIndex(element);
				makeSelection();
			}
		}
		
		protected function onElementOver(event:MouseEvent):void {
			if(use_keyboard) return;
			
			const element:SuperSearchElement = event.currentTarget as SuperSearchElement;
			if(result_scroller.body.contains(element)){
				current_child_index = result_scroller.body.getChildIndex(element);
				setActiveElement();
			}
		}
		
		protected function onElementClose(event:TSEvent):void {
			//does the same thing as the ESC key does
			onEscape();
		}
		
		protected function onMouseMove(event:MouseEvent):void {
			use_keyboard = false;
			StageBeacon.mouse_move_sig.remove(onMouseMove);
		}
		
		protected function prepElement(element:SuperSearchElement):void {
			element.addEventListener(MouseEvent.CLICK, onElementClick, false, 0, true);
			element.addEventListener(MouseEvent.ROLL_OVER, onElementOver, false, 0, true);
			element.addEventListener(TSEvent.CLOSE, onElementClose, false, 0, true);
		}
		
		/*******************************************************
		 * Search Methods
		 * TODO make a general method that these can use instead
		 * of basically copying and pasting most of it
		 ******************************************************/
		protected function searchBuddies(txt:String):void {
			const pcs:Vector.<PC> = model.worldModel.searchBuddies(txt, _buddy_tsids_to_exclude);
			var i:int;
			var total:int = buddy_elements.length;
			var element:SuperSearchElementBuddy;
			
			//reset the pool
			for(i = 0; i < total; i++){
				element = buddy_elements[int(i)];
				element.y = 0;
				element.hide();
				if(element.parent) element.parent.removeChild(element);
			}
			
			//show the results
			total = pcs.length;
			for(i = 0; i < total; i++){
				if(buddy_elements.length > i){
					element = buddy_elements[int(i)];
				}
				else {
					element = new SuperSearchElementBuddy(show_images);
					prepElement(element);
					buddy_elements.push(element);
				}
				
				result_scroller.body.addChild(element);
				element.show(_w - (total > displayed_before_scroll ? SCROLL_BAR_W: 0), pcs[int(i)], txt);
				element.y = next_y;
				next_y += element.height;
			}
		}
		
		protected function searchItems(txt:String):void {
			const items:Vector.<Item> = model.worldModel.searchItems(txt, _item_tags_to_exclude, _is_in_encyc);
			var i:int;
			var total:int = item_elements.length;
			var element:SuperSearchElementItem;
			
			//reset the pool
			for(i = 0; i < total; i++){
				element = item_elements[int(i)];
				element.y = 0;
				element.hide();
				if(element.parent) element.parent.removeChild(element);
			}
			
			//show the results
			total = items.length;
			for(i = 0; i < total; i++){
				if(item_elements.length > i){
					element = item_elements[int(i)];
				}
				else {
					element = new SuperSearchElementItem(show_images);
					prepElement(element);
					item_elements.push(element);
				}
				
				result_scroller.body.addChild(element);
				element.show(_w - (total > displayed_before_scroll ? SCROLL_BAR_W: 0), items[int(i)], '', txt);
				element.y = next_y;
				next_y += element.height;
			}
		}
		
		protected function searchRecipes(txt:String):void {
			const recipes:Vector.<Recipe> = model.worldModel.searchRecipes(txt, true, true);
			var i:int;
			var total:int = recipe_elements.length;
			var element:SuperSearchElementRecipe;
			
			//reset the pool
			for(i = 0; i < total; i++){
				element = recipe_elements[int(i)];
				element.y = 0;
				element.hide();
				if(element.parent) element.parent.removeChild(element);
			}
			
			//show the results
			total = recipes.length;
			for(i = 0; i < total; i++){
				if(recipe_elements.length > i){
					element = recipe_elements[int(i)];
				}
				else {
					element = new SuperSearchElementRecipe(show_images);
					prepElement(element);
					recipe_elements.push(element);
				}
				
				result_scroller.body.addChild(element);
				element.show(_w - (total > displayed_before_scroll ? SCROLL_BAR_W: 0), recipes[int(i)], txt);
				element.y = next_y;
				next_y += element.height;
			}
		}
		
		protected function searchInventory(txt:String):void {
			const pc:PC = model.worldModel.pc;
			if(!pc) return;
			const itemstacks:Vector.<Itemstack> = model.worldModel.searchItemstacks(txt, pc.itemstack_tsid_list);
			var i:int;
			var total:int = inventory_elements.length;
			var element:SuperSearchElementItemstack;
			var itemstack:Itemstack;
			var container_itemstack:Itemstack;
			var sub_label:String;
			var last_itemstack_tsid:String;
			var last_item_class:String;
			var last_container_tsid:String;
			var last_pool_id:uint;
			var stack_count:uint;
			
			//reset the pool
			for(i = 0; i < total; i++){
				element = inventory_elements[int(i)];
				element.y = 0;
				element.hide();
				if(element.parent) element.parent.removeChild(element);
			}
			
			//show the results
			total = itemstacks.length;
			
			//group itemstacks by the container
			for(i = 0; i < total; i++){
				itemstack = itemstacks[int(i)];
				
				//if the container is the escrow bag (or furniture bag), bail out
				if(itemstack.container_tsid == pc.escrow_tsid || itemstack.container_tsid == pc.furniture_bag_tsid) continue;
				
				//see if this was the same as the previous one, if it was a bag make those seperate no matter what
				if(itemstack.class_tsid == last_item_class && itemstack.container_tsid == last_container_tsid && !itemstack.slots){
					stack_count += itemstack.count;
					
					//update the sub label
					if(element){
						sub_label = String(stack_count);
						if(itemstack.container_tsid && model.worldModel.getItemstackByTsid(itemstack.container_tsid)){
							sub_label += ' in '+model.worldModel.getItemstackByTsid(itemstack.container_tsid).label
						}
						else {
							sub_label += ' total';
						}
						
						element.sub_label = sub_label;
					}
					
					continue;
				}
				
				last_item_class = itemstack.class_tsid;
				last_container_tsid = itemstack.container_tsid;
				stack_count = itemstack.count;
				
				//go get one
				if(inventory_elements.length > last_pool_id){
					element = inventory_elements[int(last_pool_id)];
				}
				else {
					element = new SuperSearchElementItemstack(show_images);
					prepElement(element);
					inventory_elements.push(element);
				}
				
				last_pool_id++;
				
				//set the sub label
				sub_label = String(stack_count);
				if(itemstack.container_tsid){
					container_itemstack = model.worldModel.getItemstackByTsid(itemstack.container_tsid);
					sub_label += ' in ' + (container_itemstack ? container_itemstack.label : 'your pack');
				}
				else {
					sub_label += ' total';
				}
				
				result_scroller.body.addChild(element);
				element.show(_w - (last_pool_id > displayed_before_scroll ? SCROLL_BAR_W: 0), itemstacks[int(i)], sub_label, txt);
				element.y = next_y;
				next_y += element.height;
			}
		}
		
		protected function searchLocations(txt:String):void {
			const locations:Vector.<Location> = model.worldModel.searchLocations(txt);
			var i:int;
			var total:int = location_elements.length;
			var element:SuperSearchElementLocation;
			var pool_count:uint;
			var location:Location;
			var hub:Hub;
			var last_hub_id:String;
			
			//reset the pool
			for(i = 0; i < total; i++){
				element = location_elements[int(i)];
				element.y = 0;
				element.hide();
				if(element.parent) element.parent.removeChild(element);
			}
			
			//show the results
			total = locations.length;
			for(i = 0; i < total; i++){
				location = locations[int(i)];
				
				//if we have a new hub we need to make sure we show it
				if(location.hub_id != last_hub_id){
					//we have a new hub, make sure to show it
					hub = model.worldModel.getHubByTsid(location.hub_id);
					if(hub){
						last_hub_id = hub.tsid;
						
						//get an element out of the pool
						if(location_elements.length > pool_count){
							element = location_elements[int(pool_count)];
						}
						else {
							element = new SuperSearchElementLocation(show_images);
							prepElement(element);
							location_elements.push(element);
						}
						pool_count++;
						
						//make a location that has the hub data in it
						location = new Location(hub.tsid);
						location.hub_id = hub.tsid;
						location.label = hub.label;
						
						result_scroller.body.addChild(element);
						element.show(_w - (total > displayed_before_scroll ? SCROLL_BAR_W: 0), location, txt);
						element.y = next_y;
						next_y += element.height;
					}
				}
				
				//we put this here because hub labels that are in the search results are Location injected with the same tsid and hub_id
				//this allows us to be able to show a hub name in the search results
				location = locations[int(i)];
				if(hub && location.tsid != hub.tsid){
					//get an element out of the pool
					if(location_elements.length > pool_count){
						element = location_elements[int(pool_count)];
					}
					else {
						element = new SuperSearchElementLocation(show_images);
						prepElement(element);
						location_elements.push(element);
					}
					pool_count++;
					
					result_scroller.body.addChild(element);
					element.show(_w - (total > displayed_before_scroll ? SCROLL_BAR_W: 0), location, txt);
					element.y = next_y;
					next_y += element.height;
				}
			}
		}
		
		/*******************************************************
		 * getters / setters
		 ******************************************************/
		public function get type():String { return _type; }
		public function set type(value:String):void {
			_type = value;
			
			//set up the min char amounts based on the type
			switch(value){
				case TYPE_ITEMS:
				case TYPE_INVENTORY:
				case TYPE_LOCATIONS:
				case TYPE_ANYTHING:
				default:
					min_chars_before_search = 2;
					break;
				case TYPE_BUDDIES:
					min_chars_before_search = 1;
					break;
			}
		}
		
		override public function get width():Number { return _w; }
		override public function set width(value:Number):void {
			_w = value;
			draw();
		}
		
		override public function get height():Number { return _h; }
		override public function set height(value:Number):void {
			_h = value;
			draw();
		}
		
		public function set corner_rad(value:Number):void {
			_corner_rad = value;
			draw();
		}
		
		public function get show_images():Boolean { return _show_images; }
		public function set show_images(value:Boolean):void {
			_show_images = value;
			
			no_result_element.show_images = value;
			
			draw();
		}
		
		public function set default_text(value:String):void {
			default_txt = value;
		}
		
		/**
		 * When type is buddies, you can use this to exclude tsids from the results 
		 * @param value (array of pc tsids)
		 */		
		public function set buddy_tsids_to_exclude(value:Array):void {
			_buddy_tsids_to_exclude = value;
		}
		
		/**
		 * When type is items, you can use this to exclude certain tags from the results 
		 * @param value (array of tags)
		 */		
		public function set item_tags_to_exclude(value:Array):void {
			_item_tags_to_exclude = value;
		}
		
		/**
		 * This should always return a string, most likely the TSID of whatever is being searched 
		 * @return TSID
		 */		
		public function get value():String {
			const element:SuperSearchElement = getSelectedElement();
			
			return element ? element.value : null;
		}
		
		public function get direction():String { return _direction; }
		public function set direction(value:String):void {
			_direction = value;
			
			if(value == DIRECTION_DOWN){
				setChildIndex(result_holder, numChildren-1);
				result_content.y = result_mask.y = _h - _corner_rad;
				result_scroller.y = _corner_rad + border_width;
			}
			else {
				setChildIndex(result_holder, 0);
				result_scroller.y = 0;
			}
		}
		
		/********************************************************
		 * IFocusableComponent stuff
		 *******************************************************/
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return false;
		}
		
		public function hasFocus():Boolean {
			return has_focus;
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur '+this.name);
			}
			has_focus = false;
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, arrowHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, arrowHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.UP, arrowHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.DOWN, arrowHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.UP, arrowHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DOWN, arrowHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_UP_+Keyboard.UP, arrowHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_UP_+Keyboard.DOWN, arrowHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onEscape);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_, onKeyDown);
			blurInput();
			//filters = [inner_drop];
		}
		
		public function focus():void {
			CONFIG::debugging {
				Console.log(99, 'focus '+this.name);
			}
			has_focus = true;
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, arrowHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, arrowHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.UP, arrowHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.DOWN, arrowHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.UP, arrowHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DOWN, arrowHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_UP_+Keyboard.UP, arrowHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_UP_+Keyboard.DOWN, arrowHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onEscape);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_, onKeyDown);
			focusOnInput();
			//filters = null;
		}
		
		public function registerSelfAsFocusableComponent():void {
			model.stateModel.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			model.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focusOnInput():void {
			if (!visible){
				//we are trying to get focus while invisible... don't let it happen!
				StageBeacon.stage.focus = StageBeacon.stage;
				if (has_focus) TSFrontController.instance.releaseFocus(this, 'focusOnInput()');
				return;
			}
			
			if (StageBeacon.stage.focus != input_tf) {
				StageBeacon.stage.focus = input_tf;
			}
			input_tf.setSelection(input_tf.text.length, input_tf.text.length);
			//onRollOver();
			
			// Do this just to make sure it actually fires, in case the component focus changing code 
			// somehow keeps the FocusEvent.FOCUS_IN event from calling onInputFocus
			if (model.stateModel.focused_component != this) {
				onInputFocus();
			}
		}
		
		public function blurInput():void {
			if(StageBeacon.stage.focus != input_tf) return;
			StageBeacon.stage.focus = StageBeacon.stage;
			if (has_focus) TSFrontController.instance.releaseFocus(this, 'blurInput()');
			//onRollOut();
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			
		}
	}
}