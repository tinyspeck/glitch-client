package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.TFUtil;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.GlowFilter;
	import flash.text.TextField;
	import flash.utils.Timer;

	public class Toast extends Sprite
	{
		public static const DIRECTION_UP:String = 'direction_up';
		public static const DIRECTION_DOWN:String = 'direction_down';
		public static const TYPE_DEFAULT:String = '';
		public static const TYPE_WARNING:String = 'warning';
		public static const DEFAULT_OPEN_TIME:Number = 3;
		
		protected var hide_timer:Timer = new Timer(Toast.DEFAULT_OPEN_TIME*1000);
		
		protected var corner_radius:int = 4;
		protected var background_color:uint = 0x333f43;
		protected var background_alpha:Number = .3;
		protected var border_color:uint;
		protected var border_alpha:Number = 0;
		protected var animation_time:Number = .6;
		
		protected var msg_tf:TextField = new TextField();
		
		protected var masker:Sprite = new Sprite();
		protected var filter_holder:Sprite = new Sprite(); //need this because we are masking with a filter 11.0 problem
		protected var holder:Sprite = new Sprite();
		protected var icon_holder:Sprite = new Sprite();
		protected var close_holder:Sprite = new Sprite();
		
		protected var _direction:String;
		protected var _msg:String;
		protected var _type:String;
		
		protected var _w:int;
		protected var _h:int;
		protected var _padding:int = 10;
		
		private var auto_size:Boolean = true;
		
		public function Toast(w:int, type:String = Toast.TYPE_DEFAULT, msg:String = '', direction:String = Toast.DIRECTION_UP){
			_w = w;
			_direction = direction;
			_msg = msg;
			_type = type;
			
			construct();
			draw();
		}
		
		protected function construct():void {
			addChild(masker);
			addChild(filter_holder);
			filter_holder.addChild(holder);
			
			filter_holder.mask = masker;
			
			TFUtil.prepTF(msg_tf, false);
			msg = _msg;
			holder.addChild(msg_tf);
			
			background_color = CSSManager.instance.getUintColorValueFromStyle('toast'+(type ? '_'+type : ''), 'backgroundColor', background_color);
			background_alpha = CSSManager.instance.getNumberValueFromStyle('toast'+(type ? '_'+type : ''), 'alpha', background_alpha);
			
			border_color = CSSManager.instance.getUintColorValueFromStyle('toast'+(type ? '_'+type : ''), 'borderColor', border_color);
			border_alpha = CSSManager.instance.getNumberValueFromStyle('toast'+(type ? '_'+type : ''), 'borderAlpha', border_alpha);
			
			holder.addChild(icon_holder);
			
			//setup the close stuff
			close_holder.useHandCursor = close_holder.buttonMode = true;
			close_holder.addEventListener(MouseEvent.CLICK, onCloseClick, false, 0, true);
			holder.addChild(close_holder);
			
			//handle the warning icon if we are in the warning type
			if(type == TYPE_WARNING){
				const warn_icon:DisplayObject = new AssetManager.instance.assets.warning();
				if(warn_icon) {
					warn_icon.y = -1; //visual tweak
					icon_holder.addChild(warn_icon);
				}
				
				const close_icon:DisplayObject = new AssetManager.instance.assets.close_x_grey();
				if(close_icon){
					close_holder.addChild(close_icon);
				}				
			}
			
			//if we have a border, setup the glow
			if(border_alpha > 0){
				const holder_glow:GlowFilter = new GlowFilter();
				holder_glow.color = border_color;
				holder_glow.alpha = border_alpha;
				holder_glow.inner = true;
				holder_glow.blurX = holder_glow.blurY = 2;
				holder_glow.strength = 10;
				holder.filters = [holder_glow];
			}
			
			//setup the mouse actions
			addEventListener(MouseEvent.ROLL_OVER, onRollOver, false, 0, true);
			addEventListener(MouseEvent.ROLL_OUT, onRollOut, false, 0, true);
			
			//setup the hide timer
			hide_timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
		}
		
		public function show(msg:String = '', open_time:Number = Toast.DEFAULT_OPEN_TIME):void {
			//if we are sending a message to show, go ahead and set that before showing
			if(msg) this.msg = msg;
			
			const end_y:int = _direction == DIRECTION_UP ? -holder.height : (border_alpha ? -2 : 0);
			
			TSTweener.addTween(holder, {y:end_y, time:animation_time, onUpdate:onAnimate});
			
			//start the hide timer
			hide_timer.reset();
			hide_timer.delay = open_time*1000;
			hide_timer.start();
		}
		
		public function hide(delay:Number = Toast.DEFAULT_OPEN_TIME):void {
			const end_y:int = _direction == DIRECTION_UP ? 0 : -holder.height;
			
			TSTweener.addTween(holder, {y:end_y, time:animation_time, delay:delay, onUpdate:onAnimate});
			
			//stop the hide timer
			hide_timer.stop();
		}
		
		protected function onAnimate():void {
			//tell anyone listening that we are animating
			dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
		}
		
		protected function draw(reset_position:Boolean = true):void {
			const top_rad:int = _direction == DIRECTION_UP ? corner_radius : 0;
			const bottom_rad:int = _direction == DIRECTION_UP ? 0 : corner_radius;
			const h:int = auto_size ? msg_tf.height + _padding*2 : _h;
			const icon_padding:int = icon_holder.width ? 7 : 0;
			var g:Graphics = holder.graphics;
			
			g.clear();
			g.beginFill(background_color, background_alpha);
			g.drawRoundRectComplex(0, 0, _w, h, top_rad, top_rad, bottom_rad, bottom_rad);
			
			g = masker.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRect(0, 0, _w, h);
			
			msg_tf.x = int(_w/2 - msg_tf.width/2 - icon_holder.width/2 + icon_padding*2);
			msg_tf.y = int(h/2 - msg_tf.height/2 + (border_alpha ? 1 : 0) + 1);
			
			//icon
			icon_holder.x = int(msg_tf.x - icon_holder.width - icon_padding);
			icon_holder.y = int(h/2 - icon_holder.height/2);
			
			close_holder.x = int(_w - close_holder.width - 12);
			close_holder.y = int(h/2 - close_holder.height/2);
			
			if(reset_position){
				masker.y = _direction == DIRECTION_UP ? -masker.height : 0;
				holder.y = _direction == DIRECTION_UP ? 0 : -holder.height;
			}
		}
		
		public function setBackground(background_color:uint, background_alpha:Number):void {
			this.background_color = background_color;
			this.background_alpha = background_alpha;
			draw();
		}
		
		protected function onCloseClick(event:MouseEvent):void {
			//hide this sucker right away
			hide(0);
		}
		
		protected function onTimerTick(event:TimerEvent):void {
			//hide it
			hide(0);
		}
		
		protected function onRollOver(event:MouseEvent):void {
			//pause the timer
			hide_timer.stop();
		}
		
		protected function onRollOut(event:MouseEvent):void {
			//resume the timer
			hide_timer.start();
		}
		
		public function get direction():String { return _direction; }
		public function set direction(value:String):void {
			_direction = value;
		}
		
		public function get msg():String { return _msg; }
		public function set msg(value:String):void {
			_msg = value;
			msg_tf.multiline = msg_tf.wordWrap = false;
			msg_tf.htmlText = '<p class="toast'+(type ? '_'+type : '')+'_msg">'+_msg+'</p>';
			
			if(msg_tf.width > _w){
				msg_tf.multiline = msg_tf.wordWrap = true;
				msg_tf.width = _w;
			}
			
			draw();
		}
		
		public function get w():int { return _w; }
		public function set w(value:int):void {
			_w = value;
			draw();
		}
		
		public function get h():int { return _h; }
		public function set h(value:int):void {
			_h = value;
			auto_size = false;
			draw();
		}
		
		public function get type():String { return _type; }
		public function set type(value:String):void {
			_type = value;
			draw();
		}
		
		public function get is_open():Boolean { 
			if(direction == DIRECTION_UP){
				return holder.y < 0;
			}
			else {
				return holder.y > -holder.height;
			}
		}
	}
}