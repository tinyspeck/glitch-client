package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.house.ConfigOption;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.ui.decorate.ConfiggerChoiceElementUI;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	
	import org.osflash.signals.Signal;

	public class ConfiggerUI extends Sprite {
		public static var CORNER_RAD:Number = 4;
		private static const SCROLL_BAR_WH:uint = 12;
		
		private var elements_holder:Sprite;
		private var all_mask:Sprite;
		private var all_holder:Sprite;
		private var extra_border_sp:Sprite;
		
		private var scroller:TSScroller;
		private const elements:Vector.<ConfiggerChoiceElementUI> = new Vector.<ConfiggerChoiceElementUI>();
		
		private var facing:String;
		
		private var is_built:Boolean;
		private var in_dialog:Boolean;
		
		private var _w:int;
		private var _h:int;
		private var _max_h:int;
		
		// so we don't have a lot of garbage, we'll resuse these on click events to pass values
		private const option_names:Array = new Array(1);
		private const option_values:Array = new Array(1);
		
		public const change_config_sig:Signal = new Signal(Array, Array);
		public const change_direction_sig:Signal = new Signal(String);
		public const randomize_sig:Signal = new Signal();
		public const namer_sig:Signal = new Signal();
		
		public function ConfiggerUI(w:int, in_dialog:Boolean=false) {
			_w = w;
			this.in_dialog = in_dialog;
			CORNER_RAD = in_dialog ? 0 : 4;
		}
		
		private function buildBase():void {
			all_holder = new Sprite();
			if (!in_dialog) {
				all_holder.filters = StaticFilters.black_GlowA;
			}
			addChild(all_holder);
			
			//body
			scroller = new TSScroller({
				name: 'scroller',
				bar_wh: SCROLL_BAR_WH,
				bar_color: 0xecf0f1,
				bar_border_color: 0xd2dadc,
				bar_border_width: 1,
				bar_handle_color: 0xcfdcdd,
				bar_handle_border_color: 0xb0bfc2,
				bar_handle_stripes_alpha: 0,
				bar_handle_min_h: 30,
				scrolltrack_always: false,
				show_arrows: true,
				use_children_for_body_h: true,
				//w: _w - bar_wh //changing for now until I can do smarter things with the scroller
				w: _w
			});
			all_holder.addChild(scroller);
			
			//buttons stuff
			elements_holder = new Sprite();
			scroller.body.addChild(elements_holder);
			
			all_mask = new Sprite();
			all_holder.mask = all_mask;
			addChild(all_mask);
			
			//the left line that needs to go over the black one
			extra_border_sp = new Sprite();
			addChild(extra_border_sp);
						
			is_built = true;
		}
		
		public function end():void {
			clean();
		}
		
		private function clean():void {
			//hide all of the elements
			var i:int;
			var total:int = elements.length;
			
			for(i; i < total; i++){
				elements[int(i)].hide();
			}
		}

		private var config_options:Vector.<ConfigOption> = new Vector.<ConfigOption>();

		public function startWithConfigs(config_options:Vector.<ConfigOption>, facing_right:Boolean, show_flip:Boolean, show_namer:Boolean, breaks:Array=null):void {
			this.config_options = config_options;
			this.facing = (facing_right) ? 'right' : 'left';
			/*
			CONFIG::debugging {
				Console.dir(config_options);
			}
			*/
			if (!config_options) {
				CONFIG::debugging {
					Console.error('wtf');
				}
				return;
			}
			
			//build if it not already
			if(!is_built) buildBase();
			
			//reset any elements we've already had
			clean();
			
			var i:int;
			var total:int = config_options.length;
			var pool_id:int;
			var element:ConfiggerChoiceElementUI;
			var option:ConfigOption;
			var next_y:int;
			
			//handle the options
			for(i; i < total; i++){
				option = config_options[int(i)];
				
				if(elements.length > pool_id){
					element = elements[int(pool_id)];
				}
				else {
					element = new ConfiggerChoiceElementUI(_w);
					element.addEventListener(TSEvent.CHANGED, onElementChange, false, 0, true);
					elements.push(element);
				}
				pool_id++;
				
				element.show(option);
				
				// add extra space after this one?
				if (breaks && breaks.indexOf(i) != -1) {
					var bottom_line_h:int = 4;
					element.bottom_line_h = bottom_line_h;
				}
				
				element.y = next_y;
				elements_holder.addChild(element);
				next_y += element.height;
			}
			
			//toss in the flip
			if(elements.length > pool_id){
				element = elements[int(pool_id)];
			}
			else {
				element = new ConfiggerChoiceElementUI(_w);
				element.addEventListener(TSEvent.CHANGED, onElementChange, false, 0, true);
				elements.push(element);
			}
			pool_id++;
			
			element.show(null, show_flip, (facing == 'left' ? 'prev' : 'next'));
			element.y = next_y;
			elements_holder.addChild(element);
			next_y += element.height;
			
			if (show_namer) {
				//toss in the namer
				if(elements.length > pool_id){
					element = elements[int(pool_id)];
				}
				else {
					element = new ConfiggerChoiceElementUI(_w);
					element.addEventListener(TSEvent.CHANGED, onElementChange, false, 0, true);
					elements.push(element);
				}
				pool_id++;
				namer_element = element;
				
				element.show(null, false, null, true, 'Change your tower\'s name');
				element.y = next_y;
				elements_holder.addChild(element);
				next_y += element.height;
			}
			
			refresh();
		}
		
		private var namer_element:ConfiggerChoiceElementUI;
		
		public function enableNamerBt():void {
			if (namer_element) {
				namer_element.enableNamerBt();
			}
		}
		
		public function getValuesHash():Object {
			var hash:Object = {};
			var i:int;
			var total:int = elements.length;
			var el:ConfiggerChoiceElementUI;
			for(i; i < total; i++){
				el = elements[int(i)];
				if (!el.option) continue;
				hash[el.option.id] = el.option.getCurrentChoiceValue()
			}
			
			return hash;
		}
		
		public function disableNamerBt():void {
			if (namer_element) {
				namer_element.disableNamerBt();
			}
			
		}
		
		public function refresh():void {
			if (!elements_holder) return;
			//set the heights
			_max_h = TSModelLocator.instance.layoutModel.loc_vp_h-10;
			_h = Math.min(elements_holder.height, _max_h);
			scroller.h = _h;
			scroller.refreshAfterBodySizeChange();
			
			//set the widths
			var i:int;
			var total:int = elements.length;
			for(i; i < total; i++){
				elements[int(i)].width = _w - (scroller.body_h <= _h ? 0 : SCROLL_BAR_WH);
			}
			
			//draw like a banshee
			var g:Graphics = all_mask.graphics;
			g.clear();
			
			g.beginFill(0);
			g.drawRoundRectComplex(0, 0, _w, _h, CORNER_RAD, CORNER_RAD, 0, 0);
			
			g = all_holder.graphics;
			g.clear();
			
			
			g.beginFill(0xf5f5f5);
			g.drawRoundRectComplex(0, 0, _w, _h, CORNER_RAD, CORNER_RAD, 0, 0);
			
			if (in_dialog) return;
			
			g = extra_border_sp.graphics;
			g.clear();
			g.beginFill(0xa2bcb9);
			g.drawRect(-1, CORNER_RAD-1, 1, _h-CORNER_RAD+1);
			g.beginFill(0x7c8988); //transitional pixel, anal I know, but it's better!
			g.drawRect(-1, CORNER_RAD-2, 1, 1);
			g.beginFill(0xced3d6); //grey line at bottom
			g.drawRect(0, _h-1, _w, 1);
			g.beginFill(0xdee5eb); //blue colour of the picker module (since this is sitting on top of it)
			g.drawRect(0, _h, _w, 2);
		}
		
		private function onElementChange(event:TSEvent):void {			
			if(event.data && event.data is ConfigOption){
				//regular config change
				const option:ConfigOption = event.data as ConfigOption;
				CONFIG::debugging {
					if (!option.getCurrentChoiceValue()) {
						Console.error('wtf '+option.id+' not in config_options');
						Console.dir(config_options);
					}
				}
				
				option_names[0] = option.id;
				option_values[0] = option.getCurrentChoiceValue();
				change_config_sig.dispatch(option_names, option_values);
			}
			else {
				//change the way it's facing
				if(event.data == 'flip'){
					const new_direction:String = (facing == 'left') ? 'right' : 'left';
					change_direction_sig.dispatch(new_direction);
					facing = new_direction;
				}
				//show a random config
				else if(event.data == 'randomize'){
					randomize_sig.dispatch();
				}
				else if(event.data == 'namer'){
					namer_sig.dispatch();
				}
			}
		}
		
		override public function get height():Number { return _h; }
	}
}