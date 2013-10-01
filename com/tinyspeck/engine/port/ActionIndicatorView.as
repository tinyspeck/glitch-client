package com.tinyspeck.engine.port
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class ActionIndicatorView extends DisposableSprite implements IDisposableSpriteChangeHandler, ITipProvider
	{
		protected static var ICON_WH:uint = 18;
		
		protected var pointy_width:uint = 10;
		protected var padding:uint = 7;
		protected var percent_padding:uint = 2;
		protected var progress_color:uint = 0x055c73;
		protected var progress_alpha:Number = .37;
		
		protected var msg_tf:TextField = new TextField();
		protected var alt_msg_tf:TextField = new TextField();
		
		protected var _icon:DisplayObject;
		protected var percent_progress:Sprite = new Sprite();
		protected var percent_mask:Sprite = new Sprite();
		protected var main_holder:Sprite = new Sprite();
		protected var alt_holder:Sprite = new Sprite();
		
		protected var _percent:Number = 0;
		protected var _msg:String;
		protected var _alt_msg:String;
		protected var _back_msg:String;
		protected var _type:String;
		protected var itemstack_tsid:String;
		protected var alt_msg_tf_css_class:String;
		protected var msg_tf_css_class:String;
		protected var _pointy_direction:String;
		protected var _tip_text:String;
		protected var _icon_class:String;
		
		protected var lis_view:LocationItemstackView;
		
		protected var is_flipping:Boolean;
		protected var _enabled:Boolean = true;
		protected var _glowing:Boolean;
		protected var _warning:Boolean;
		
		public function ActionIndicatorView(itemstack_tsid:String, type:String = ''){
			_type = type;
			name = itemstack_tsid;
			this.itemstack_tsid = itemstack_tsid;
			
			init();
		}
		
		protected function init():void {
			
			lis_view = TSFrontController.instance.getMainView().gameRenderer.getItemstackViewByTsid(itemstack_tsid);
			
			// define classes for tfs if not defined by extender
			if (!msg_tf_css_class) msg_tf_css_class = 'ai_msg';
			if (!alt_msg_tf_css_class) alt_msg_tf_css_class = 'ai_alt_msg';
			
			// this is a placeholder, need to have a better generic action indicator
			if (!_icon) _icon = new AssetManager.instance.assets['quest_requirement']();
			
			//useHandCursor = buttonMode = true;
			//mouseChildren = false;
			
			addChild(main_holder);
			addChild(alt_holder);
			
			alt_holder.alpha = 0;

			//percent progress bar holder
			percent_mask.x = percent_mask.y = percent_padding;
			main_holder.addChild(percent_mask);
			
			percent_progress.x = percent_progress.y = percent_padding;
			percent_progress.mask = percent_mask;
			main_holder.addChild(percent_progress);
			
			//setup the icon if defined by extender

			if (_icon) {
				main_holder.addChild(_icon);
			}
			
			//tfs
			prepTextField(msg_tf);
			main_holder.addChild(msg_tf);
			
			prepTextField(alt_msg_tf);
			alt_holder.addChild(alt_msg_tf);
			
			draw();
			place();
			
			filters = StaticFilters.black2px90Degrees_DropShadowA;
		}
						
		protected function flipNext():void {
			var show_main:Boolean = main_holder.alpha == 0 ? true : false;
			var ani_time:Number = .5;
			var hold_time:Number = 3;
			
			TSTweener.addTween(main_holder, { alpha:show_main ? 1 : 0, time:ani_time, delay:hold_time, transition:'linear'});
			TSTweener.addTween(alt_holder, { alpha:show_main ? 0 : 1, time:ani_time, delay:hold_time, transition:'linear'});
			
			TSTweener.addTween(main_holder, { alpha:show_main ? 1 : 0, time:ani_time, delay:hold_time+ani_time, transition:'linear'});
			TSTweener.addTween(alt_holder, { alpha:show_main ? 0 : 1, time:ani_time, delay:hold_time+ani_time, transition:'linear', onComplete:flipNext});
		}		
		
		protected function draw():void {
			if (!_icon) {
				CONFIG::debugging {
					Console.error('everything is fucked');
				}
				
				return;
			}
			
			var icon_height:int = (_icon is ItemIconView) ? ItemIconView(_icon).wh : _icon.height;
			var icon_width:int = (_icon is ItemIconView) ? ItemIconView(_icon).wh : _icon.width;
			
			_icon.x = padding*2;
			_icon.y = padding;
			msg_tf.x = _icon.x + icon_width + padding;
			
			var w:int = Math.max(msg_tf.x + msg_tf.width + padding*2, alt_msg_tf.x + alt_msg_tf.width + padding*2);
			var h:int = icon_height + padding*2 - 1;
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRoundRect(-w/2, 0, w, h, h);
			g.endFill();
			
			g.beginFill(0xffffff);
			g.moveTo(-pointy_width/2, h);
			g.lineTo(0, h + pointy_width/2);
			g.lineTo(pointy_width/2, h);
			g.endFill();
			
			if(_msg){ 
				msg_tf.y = int(h/2 - msg_tf.height/2) + 1;
				_icon.x = padding*2;
			}
			else {
				_icon.x = int(icon_width/2) + 1;
			}
			
			main_holder.x = int(-w/2);
			alt_holder.x = int(-alt_holder.width/2);
			alt_msg_tf.y = int(h/2 - alt_msg_tf.height/2) + 1;
			
			drawPerc();
		}
		
		protected function drawPerc():void {
			var g:Graphics = percent_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRoundRect(0, 0, width - percent_padding*2, height - percent_padding*2 - pointy_width/2, height - percent_padding*2 - pointy_width/2);
			
			var seg_width:Number = percent_mask.width / 100;
						
			g = percent_progress.graphics;
			g.clear();
			g.beginFill(progress_color, progress_alpha);
			g.drawRect(0, 0, seg_width * (_percent*100), percent_mask.height);
		}
		
		protected function place():void {
			TSFrontController.instance.getMainView().gameRenderer.placeOverlayInSCH(this, 'AIV.drawPerc item:'+(lis_view?lis_view.item.tsid:'??'));
			TSFrontController.instance.registerDisposableSpriteChangeSubscriber(this, lis_view);
		}
		
		public function worldDisposableSpriteSubscribedHandler(sp:DisposableSprite):void {
		}
		
		public function worldDisposableSpriteDestroyedHandler(sp:DisposableSprite):void {
			// the disp sp your were registered with has been destroyed
			// Here you shoudl do clean up, remove form stage, remove tweens, event listeners etc
			dispose();
		}
		
		public function worldDisposableSpriteChangeHandler(sp:DisposableSprite):void {
			x = int(lis_view.x_of_int_target);
			y = int(lis_view.y + lis_view.getYAboveDisplay()-height);
		}
		
		public function stopFlipping(show_front:Boolean = true):void {
			is_flipping = false;
			TSTweener.removeTweens([main_holder, alt_holder]);
			
			if(show_front){
				main_holder.alpha = 1;
				alt_holder.alpha = 0;
			}
			else {
				main_holder.alpha = 0;
				alt_holder.alpha = 1;
			}
		}
		
		protected function prepTextField(tf:TextField):void {
			tf.embedFonts = true;
			tf.multiline = true;
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.styleSheet = CSSManager.instance.styleSheet;
			tf.antiAliasType = AntiAliasType.ADVANCED;
			tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
		}
		
		override public function dispose():void {
			stopFlipping();
			
			TSFrontController.instance.unregisterDisposableSpriteChangeSubscriber(this, lis_view);
			//while(numChildren > 0) removeChildAt(0);
			SpriteUtil.clean(this.main_holder);
			SpriteUtil.clean(this.alt_holder);
			SpriteUtil.clean(this);
			msg_tf = null;
			_icon = null;
			lis_view = null;
			percent_progress = null;
			percent_mask = null;
			if(parent) parent.removeChild(this);
			super.dispose();
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!_tip_text || !tip_target) return null;
			
			return {
				txt: _tip_text,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
		
		public function get msg():String { return _msg; }
		public function set msg(str:String):void { 
			if(!str || !msg_tf) return;
			_msg = str;
			
			msg_tf.htmlText = '<p class="'+msg_tf_css_class+'">' + _msg + '</p>';
			
			draw();
		}
		
		public function get alt_msg():String { return _alt_msg; }
		public function set alt_msg(str:String):void { 
			_alt_msg = str;
			
			if(!_alt_msg){
				stopFlipping(true);
				alt_msg_tf.htmlText = '';
				return;
			}
									
			alt_msg_tf.htmlText = '<p class="'+msg_tf_css_class+'">' + _alt_msg + '</p>';
			
			draw();
			
			if(!is_flipping && _alt_msg){
				is_flipping = true;
				flipNext();
			}
		}
		
		public function get type():String { return _type; }
		public function set type(str:String):void {
			_type = str;
			draw();
		}
		
		public function get icon():DisplayObject { return _icon; }
		public function set icon(DO:DisplayObject):void {
			if (_icon) {
				if (_icon is ItemIconView) {
					ItemIconView(_icon).dispose();
				}
				if (_icon.parent) _icon.parent.removeChild(_icon);
			}
			_icon = DO;
			if (_icon) main_holder.addChild(_icon);
			draw();
		}
		
		public function get percent():Number { return _percent; }
		public function set percent(value:Number):void {
			value = Math.min(1, value);
			value = Math.max(0, value);
			_percent = value;
			draw();
		}
		
		public function get enabled():Boolean { return _enabled; }
		public function set enabled(value:Boolean):void {
			_enabled = value;
		}
		
		public function get pointy_direction():String { return _pointy_direction; }
		public function set pointy_direction(direction:String):void {
			_pointy_direction = direction;
			draw();
		}
		
		public function get tip_text():String { return _tip_text; }
		public function set tip_text(value:String):void {
			_tip_text = value;
			if(value) {
				TipDisplayManager.instance.registerTipTrigger(this);
			}
			else {
				TipDisplayManager.instance.unRegisterTipTrigger(this);
			}
		}
		
		public function get icon_class():String { return _icon_class; }
		public function set icon_class(class_tsid:String):void {
			if(!class_tsid) return;
			_icon_class = class_tsid;
			
			icon = new ItemIconView(class_tsid, ICON_WH);
			draw();
		}
		
		public function get glowing():Boolean { return _glowing; }
		public function set glowing(do_glow:Boolean):void {
			_glowing = do_glow;
		}
		
		public function get warning():Boolean { return _warning; }
		public function set warning(value:Boolean):void {
			_warning = value;
		}
		
		public function get w():int {
			return width;
		}
		
		public function get h():int {
			return height;
		}
	}
}