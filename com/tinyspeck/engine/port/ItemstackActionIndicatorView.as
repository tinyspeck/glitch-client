package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;

	public class ItemstackActionIndicatorView extends ActionIndicatorView
	{	
		private static const RADIUS:uint = 13;
		private static const IMG_ICONS:Array = new Array('pet', 'water', 'feed', 'massage');
		private const pointy_y:uint = RADIUS*2 - 1;
		
		private const icon_mask:Sprite = new Sprite();
		
		public function ItemstackActionIndicatorView(itemstack_tsid:String, type:String){
			blendMode = BlendMode.LAYER;
			pointy_width = 6;
			_type = type;
			super(itemstack_tsid, type);
		}
		
		override protected function init():void {
			//define classes for tfs
			msg_tf_css_class = 'itemstack_action';
			
			//setup the icon
			icon = getIcon();
			var icon_w:int = (icon is ItemIconView) ? ItemIconView(icon).wh : icon.width;
			var icon_h:int = (icon is ItemIconView) ? ItemIconView(icon).wh : icon.height;
			icon.x = int(RADIUS-icon_w/2);
			icon.y = int(RADIUS-icon_h/2);
			
			main_holder.addChild(icon_mask);
			var mask_wh:int = (RADIUS*2)-4;
			icon_mask.x = int(RADIUS-mask_wh/2);
			icon_mask.y = int(RADIUS-mask_wh/2);
			var g:Graphics = icon_mask.graphics;
			g.beginFill(0xff0000, 1);
			g.drawCircle(mask_wh/2, mask_wh/2, mask_wh/2);
			
			icon.mask = icon_mask;
			
			useHandCursor = buttonMode = true;
			mouseChildren = false;
			
			super.init();
			
		}
		
		private var calced_w:int;
		private var calced_h:int;
		override public function get w():int {
			if (calced_w) return calced_w;
			if (icon.parent) {
				icon.parent.removeChild(icon);
				calced_w = width;
				main_holder.addChild(icon);
			} else {
				calced_w = width;
			}
			return calced_w;
		}
		
		override public function get h():int {
			if (calced_h) return calced_h;
			if (icon.parent) {
				icon.parent.removeChild(icon);
				calced_h = height;
				main_holder.addChild(icon);
			} else {
				calced_h = height;
			}
			return calced_h;
		}
		
		override protected function draw():void {
			if (!_icon) {
				CONFIG::debugging {
					Console.error('everything is fucked');
				}
				return;
			}
			
			calced_w = 0; // this woll force a remeasuring taking into account masks
			calced_h = 0; // this woll force a remeasuring taking into account masks
			
			var w:int = RADIUS*2;
			var g:Graphics = main_holder.graphics;
			g.clear();
			g.beginFill(0xffffff);
			
			//position the tf if it's there
			if(msg_tf.text){
				msg_tf.x = icon_mask.x + icon_mask.width + 4;
				msg_tf.y = int(ICON_WH/2 - msg_tf.height/2) + padding/2;
				w = msg_tf.x + msg_tf.width + padding;
				
				g.drawRoundRect(0, 0, w, RADIUS*2, RADIUS*2);
			}
			else {
				g.drawCircle(RADIUS, RADIUS, RADIUS);
			}
			
			
			main_holder.x = 0;
			var offset_x:int = (pointy_direction == 'left' || pointy_direction == 'right') ? 5: 0;
			
			g = graphics;
			g.clear();
			g.beginFill(0xffffff);
			if(pointy_direction == 'left'){
				//shove the main holder over
				main_holder.x = pointy_width-6+offset_x;
				
				g.moveTo(offset_x+pointy_width-5, RADIUS - pointy_width/2);
				g.lineTo(offset_x+0, RADIUS);
				g.lineTo(offset_x+pointy_width-5, RADIUS + pointy_width/2);
				
				g.endFill();
				
				g.beginFill(0, 0);
				g.drawRect(0, 0, w, h);
			}
			else if(pointy_direction == 'right'){
				
				g.moveTo(main_holder.width-1, RADIUS - pointy_width/2);
				g.lineTo(main_holder.width-1 + pointy_width-5, RADIUS);
				g.lineTo(main_holder.width-1, RADIUS + pointy_width/2);
				g.endFill();
				
				g.beginFill(0, 0);
				g.drawRect(0, 0, width, height);
			}
			else {
				g.moveTo(w/2 - pointy_width/2, pointy_y);
				g.lineTo(w/2, pointy_y + pointy_width/2);
				g.lineTo(w/2 + pointy_width/2, pointy_y);
				g.endFill();
			}
		}
		
		public function getIcon():DisplayObject {
			if(IMG_ICONS.indexOf(type) >= 0){
				return new AssetManager.instance.assets['action_'+type]();
			}
			else if (TSModelLocator.instance.worldModel.getItemByTsid(type)) {
				return new ItemIconView(type, ICON_WH*2);
			} else {
				CONFIG::debugging {
					Console.error('unrecognized icon type:'+type+' for item '+TSModelLocator.instance.worldModel.getItemByItemstackId(itemstack_tsid).tsid);
				}
				return new AssetManager.instance.assets['close_x_making_slot']();
			}
		}
		
		private function getText():String {
			var msg_txt:String = enabled ? '' : '<span class="itemstack_action_disabled">';
			msg_txt += StringUtil.capitalizeFirstLetter(type) + '?';
			msg_txt += enabled ? '' : '</span>';
			
			return msg_txt;
		}
		
		private var last_x:int;
		private var last_y:int;
		override public function worldDisposableSpriteChangeHandler(sp:DisposableSprite):void {
			//the lis_view should handle where to place it			
			
			if(!lis_view) return;
			if (!visible) return;
			if (lis_view.x == last_x && lis_view.y == last_y) return;
			
			last_x = lis_view.x;
			last_y = lis_view.y;
			
			lis_view.positionActionIndicators();
		}
		
		override public function set enabled(value:Boolean):void {
			//if we are already the same state as before, don't bother changing things
			if(enabled != value){
				super.enabled = value;
				
				//change the icon color
				if(icon){
					icon.filters = value ? [] : [ColorUtil.getGreyScaleFilter()];
					icon.alpha = value ? 1 : .7;
				}
				
				if(glowing) msg = getText();
			}
		}
		
		override public function set glowing(do_glow:Boolean):void {
			if(glowing != do_glow){
				//filters = (!warning ? (!do_glow ? StaticFilters.black2px90Degrees_DropShadowA : StaticFilters.blue2px_GlowA) : StaticFilters.red2px_GlowA);
				if(do_glow){
					main_holder.addChild(msg_tf);
					msg = getText();
				}
				else {
					if (msg_tf.parent) msg_tf.parent.removeChild(msg_tf);
					msg_tf.text = '';
					pointy_direction = '';
				}
			}
			
			super.glowing = do_glow;
		}
		
		override public function set warning(value:Boolean):void {
			if(warning != value){
				filters = (!value ? (!glowing ? StaticFilters.black2px90Degrees_DropShadowA : StaticFilters.blue2px_GlowA) : StaticFilters.red2px_GlowA);
			}
			
			super.warning = value;
		}
	}
}