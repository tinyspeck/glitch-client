package com.tinyspeck.engine.view.ui.decorate
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.data.house.ConfigOption;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class ConfiggerChoiceElementUI extends Sprite
	{
		private static const DEFAULT_BOTTOM_LINE_HEIGHT:uint = 1;
		private static const DEFAULT_HEIGHT:uint = 38;
		private static const BT_ALPHA:Number = .4;
		private static const BT_RADIUS:Number = 5;
		private static const BT_WH:uint = 27;
		private static const BT_PADD:uint = 6;
		
		private var prev_bt:Button;
		private var next_bt:Button;
		private var flip_bt:Button;
		private var randomize_bt:Button;
		private var namer_bt:Button;
		private var current_option:ConfigOption;
		
		private var label_holder:Sprite = new Sprite();
		private var circle_holder:Sprite = new Sprite();
		private var highlighter:Sprite = new Sprite();
		private var bottom_line:Sprite = new Sprite();
		private var special_holder:Sprite = new Sprite();
		
		private var label_tf:TextField = new TextField();
		
		private var is_built:Boolean;
		
		private var _w:int;
		private var _h:int;
		private var _bottom_line_h:int = DEFAULT_BOTTOM_LINE_HEIGHT;
		
		public function ConfiggerChoiceElementUI(w:int) {
			_w = w;
			_h = DEFAULT_HEIGHT;
		}
		
		public function get option():ConfigOption {
			return current_option;
		}
		
		private function buildBase():void {			
			//mouse over highlighter
			highlighter.alpha = 0;
			addChild(highlighter);
			
			//label holder
			addChild(label_holder);
			
			//bts
			prev_bt = new Button({
				name: 'prev',
				type: Button.TYPE_MINOR,
				size: Button.SIZE_TINY,
				graphic: new AssetManager.instance.assets.solid_arrow(),
				graphic_hover: new AssetManager.instance.assets.solid_arrow_hover(),
				graphic_disabled: new AssetManager.instance.assets.solid_arrow_disabled(),
				graphic_padd_w: 9,
				w: BT_WH,
				h: BT_WH
			});
			prev_bt.setCornerRadius(BT_RADIUS, 0, BT_RADIUS, 0);
			prev_bt.addEventListener(MouseEvent.ROLL_OVER, onButtonHover, false, 0, true);
			prev_bt.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
			addChild(prev_bt);
			
			const arrow:DisplayObject = new AssetManager.instance.assets.solid_arrow();
			const arrow_hover:DisplayObject = new AssetManager.instance.assets.solid_arrow_hover();
			const arrow_disabled:DisplayObject = new AssetManager.instance.assets.solid_arrow_disabled();
			arrow.scaleX = -1;
			arrow_hover.scaleX = -1;
			arrow_disabled.scaleX = -1;
			next_bt = new Button({
				name: 'next',
				type: Button.TYPE_MINOR,
				size: Button.SIZE_TINY,
				graphic: arrow,
				graphic_hover: arrow_hover,
				graphic_disabled: arrow_disabled,
				graphic_padd_w: arrow.width + 9,
				w: BT_WH,
				h: BT_WH
			});
			next_bt.setCornerRadius(0, BT_RADIUS, 0, BT_RADIUS);
			next_bt.addEventListener(MouseEvent.ROLL_OVER, onButtonHover, false, 0, true);
			next_bt.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
			addChild(next_bt);
			
			flip_bt = new Button({
				name: 'flip',
				label: 'Flip',
				value: 'flip',
				graphic: new AssetManager.instance.assets.chassis_flip(),
				graphic_hover: new AssetManager.instance.assets.chassis_flip_hover(),
				graphic_alpha: BT_ALPHA,
				graphic_placement: 'left',
				graphic_padd_l: 8,
				graphic_padd_r: 2,
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR_DIM
			});
			flip_bt.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
			
			randomize_bt = new Button({
				name: 'randomize',
				label: 'Randomize',
				value: 'randomize',
				graphic: new AssetManager.instance.assets.chassis_randomize(),
				graphic_hover: new AssetManager.instance.assets.chassis_randomize_hover(),
				graphic_alpha: BT_ALPHA,
				graphic_placement: 'left',
				graphic_padd_l: 8,
				graphic_padd_r: 2,
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR_DIM
			});
			randomize_bt.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
			special_holder.addChild(randomize_bt);
			addChild(special_holder);
			
			namer_bt = new Button({
				name: 'namer',
				label: 'to be supplied',
				value: 'namer',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR_DIM
			});
			namer_bt.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
			
			//label stuff
			//tf
			TFUtil.prepTF(label_tf, false);
			label_tf.cacheAsBitmap = true; //prevents the dancing when tweening
			label_tf.htmlText = '<p class="chassis_configure_element">placeholder</p>';
			label_tf.mouseEnabled = false;
			label_holder.addChild(label_tf);
			
			//circles
			circle_holder.y = int(label_tf.height + 1);
			label_holder.addChild(circle_holder);
			
			//bottom border
			addChild(bottom_line);
			
			//mouse stuff
			addEventListener(MouseEvent.ROLL_OVER, onRoll, false, 0, true);
			addEventListener(MouseEvent.ROLL_OUT, onRoll, false, 0, true);
			
			is_built = true;
		}
		
		public function show(option:ConfigOption, show_flip:Boolean=false, disable_side:String=null, show_namer:Boolean=false, namer_label:String=''):void {
			if(!is_built) buildBase();
			current_option = option;
			
			//reset
			prev_bt.disabled = disable_side && disable_side == 'prev' ? true : false;
			next_bt.disabled = disable_side && disable_side == 'next' ? true : false;
			prev_bt.alpha = BT_ALPHA;
			next_bt.alpha = BT_ALPHA;
			prev_bt.visible = option != null;
			next_bt.visible = option != null;
			circle_holder.alpha = 0;
			special_holder.visible = option == null;
			_bottom_line_h = DEFAULT_BOTTOM_LINE_HEIGHT;
			
			if (show_namer) {
				namer_bt.label = namer_label || '?????????'
				if (flip_bt.parent) flip_bt.parent.removeChild(flip_bt);
				if (randomize_bt.parent) randomize_bt.parent.removeChild(randomize_bt); 
				if (namer_bt.parent != special_holder) special_holder.addChild(namer_bt);
				namer_bt.x = 0;
				
			} else {
				if (namer_bt.parent) namer_bt.parent.removeChild(namer_bt);
				if (randomize_bt.parent != special_holder) special_holder.addChild(randomize_bt);
				if (show_flip) {
					if (flip_bt.parent != special_holder) special_holder.addChild(flip_bt);
					randomize_bt.x = int(flip_bt.width + 10);
				} else {
					if (flip_bt.parent) flip_bt.parent.removeChild(flip_bt);
					randomize_bt.x = 0;
				}
				
				//special case for when the randomize button was clicked and this was refreshed
				if(randomize_bt.focused){
					onRoll(new MouseEvent(MouseEvent.ROLL_OVER));
				}
			}
			
			//label
			label_tf.htmlText = '<p class="chassis_configure_element">'+(option ? option.label : '')+'</p>';
			
			//set the circles
			setCircles();
			
			//move things
			draw();
		}
		
		public function disableNamerBt():void {
			namer_bt.disabled = true;
		}
		
		public function enableNamerBt():void {
			namer_bt.disabled = false;
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
		}
		
		private function setCircles():void {
			if(!current_option) {
				if(circle_holder.numChildren) SpriteUtil.clean(circle_holder);
				return;
			}
			const total:int = current_option.choices.length;
			const color:uint = 0x8fafbf;
			const radius:Number = 3;
			const padd:int = 3;
			const inactive_alpha:Number = .4;
			
			//make sure we don't have more circles than we do options
			while(circle_holder.numChildren > total) circle_holder.removeChildAt(circle_holder.numChildren-1);
			
			var sp:Sprite;
			var g:Graphics;
			var i:int;
			var next_x:int;
			var next_y:int;
			var break_id:int = total;
			
			//if the amount is going to touch the < > buttons, let's divide it in 2
			const max_w:int = _w - BT_WH*2 - BT_PADD + 2;
			const single_w:int = (total * (radius*2 + padd)) - padd;
			if(single_w > max_w){
				break_id = Math.ceil(total/2);
			}
			
			for(i; i < total; i++){
				//do we have a circle already?
				sp = circle_holder.numChildren > i ? circle_holder.getChildAt(i) as Sprite : null;
				if(!sp){
					sp = new Sprite();
					g = sp.graphics;
					g.beginFill(color);
					g.drawCircle(radius, radius, radius);
					circle_holder.addChild(sp);
				}
				
				if(i == break_id){
					next_x = 0;
					next_y += radius*2 + padd;
				}
				
				sp.x = next_x;
				sp.y = next_y;
				next_x += radius*2 + padd;
				
				//is it the active one?
				sp.alpha = i != current_option.choice_index ? inactive_alpha : 1;
			}
			
			//set the height based on the height our circles are
			_h = circle_holder.y + circle_holder.height + 13;
		}
		
		private function draw():void {
			//mouse over highlighter
			var g:Graphics = highlighter.graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRect(0, 0, _w, _h);
			
			//buttons
			prev_bt.x = int(_w - BT_WH*2 - BT_PADD + 2);
			prev_bt.y = int(center_y - prev_bt.height/2 - 1);
			next_bt.x = int(_w - BT_WH - BT_PADD);
			next_bt.y = prev_bt.y;
			flip_bt.y = int(center_y - flip_bt.height/2 - 1);
			randomize_bt.y = flip_bt.y;
			namer_bt.y = flip_bt.y;
			bottom_line.y = _h-_bottom_line_h;
			
			//center it
			const bigger_w:int = label_tf.width > circle_holder.width ? label_tf.width : circle_holder.width;
			label_tf.x = int(bigger_w/2 - label_tf.width/2);
			circle_holder.x = int(bigger_w/2 - circle_holder.width/2);
			label_holder.x = int(prev_bt.x/2 - bigger_w/2);
			label_holder.y = int(center_y - label_tf.height/2 + 1);
			
			//bottom border
			g = bottom_line.graphics;
			g.clear();
			g.beginFill(0xe4e4e4);
			g.drawRect(0, 0, _w, _bottom_line_h);
			
			//center the flip buttons if they are there
			if(special_holder.visible){
				special_holder.x = int(_w/2 - special_holder.width/2 - 1);
			}
		}
		
		private function onButtonHover(event:MouseEvent):void {
			//just put it to the top of the display list so the border looks proper
			setChildIndex(event.currentTarget as Button, numChildren-1);
		}
		
		private function onButtonClick(event:TSEvent):void {
			const bt:Button = event.data as Button;
			if(bt.disabled) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			const is_prev:Boolean = bt == prev_bt;
			
			if(current_option){
				//move the indices
				current_option.choice_index += is_prev ? -1 : 1;
				
				//make sure we loop back around if we went too far
				if(current_option.choice_index < 0) {
					current_option.choice_index = current_option.choices.length-1;
				} 
				else if (current_option.choice_index >= current_option.choices.length) {
					current_option.choice_index = 0;
				}
				
				dispatchEvent(new TSEvent(TSEvent.CHANGED, current_option));
			}
			else {
				//send off the value				
				dispatchEvent(new TSEvent(TSEvent.CHANGED, bt.value));
			}
			
			//figure out which circle to light up
			setCircles();
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
		}
		
		private function onRoll(event:MouseEvent):void {
			//animate stuff
			const is_over:Boolean = event.type == MouseEvent.ROLL_OVER;
			const label_y:int = center_y - (is_over ? label_holder.height/2 : label_tf.height/2 - 1);
			const ani_time:Number = .2;
			TSTweener.removeTweens([highlighter, label_holder, circle_holder]);
			TSTweener.addTween([highlighter, circle_holder], {alpha:is_over ? 1 : 0, time:ani_time, transition:'linear'});
			
			if(circle_holder.numChildren){
				//animate the ones that have circles
				TSTweener.addTween(label_holder, {y:label_y, time:ani_time});
			}
			
			prev_bt.alpha = is_over ? 1 : BT_ALPHA;
			next_bt.alpha = is_over ? 1 : BT_ALPHA;
		}
		
		public function get center_y():Number {
			return (_h-(_bottom_line_h-1))/2;
		}
		
		override public function get width():Number { return _w; }
		// MUST BE CALLED AFTER show()
		override public function set width(value:Number):void { 
			_w = value;
			draw();
		}
		
		override public function get height():Number { return _h; }
		// MUST BE CALLED AFTER show()
		override public function set height(value:Number):void { 
			_h = value;
			draw();
		}
		
		public function get bottom_line_h():Number { return _bottom_line_h; }
		// MUST BE CALLED AFTER show()
		public function set bottom_line_h(value:Number):void { 
			_bottom_line_h = value;
			_h += _bottom_line_h-DEFAULT_BOTTOM_LINE_HEIGHT;
			draw();
		}
		
		/**
		 * Will enable/disable the "previous" button. MUST BE CALLED AFTER show()
		 * @param value
		 */		
		public function set prev_enabled(value:Boolean):void {
			prev_bt.disabled = !value;
		}
		
		/**
		 * Will enable/disable the "next" button. MUST BE CALLED AFTER show()
		 * @param value
		 */	
		public function set next_enabled(value:Boolean):void {
			next_bt.disabled = !value;
		}
	}
}