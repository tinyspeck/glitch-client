package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.giant.Giants;
	import com.tinyspeck.engine.data.itemstack.FurnitureConfig;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.SlugAnimator;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;

	public class Slug extends Sprite implements ITipProvider
	{
		public static const XP:String = 'xp';
		public static const CURRANTS:String = 'currants';
		public static const ENERGY:String = 'energy';
		public static const MOOD:String = 'mood';
		public static const FAVOR:String = 'favor';
		public static const ITEMS:String = 'items';
		public static const IMAGINATION:String = 'imagination';
		
		private static const DEFAULT_DELAY:uint = 3;
		
		private static const HEIGHT:uint = 21;
		private static const ICON_HEIGHT:uint = 17;
		private static const CORNER_RADIUS:uint = 12;
		private static const ENERGY_CORNER_RADIUS:uint = 4;
		private static const TEXT_ICON_PADDING:int = 2;
		private static const DIM_ALPHA:Number = .5;
		
		//layout
		private static const left_padding:int = 3;
		private var right_padding:int = 0;
		
		//bg colors
		private static var energy_pos_bg_color:uint = 0xc1d76e;
		private static var mood_pos_bg_color:uint = 0xc1d76e;
		private static var xp_pos_bg_color:uint = 0xc7dce0;
		private static var currants_pos_bg_color:uint = 0xd4c6a3;
		private static var favor_pos_bg_color:uint = 0xebccd6;
		private static var items_pos_bg_color:uint = 0xd3d3d3;
		private static var imagination_pos_bg_color:uint = 0xccaedb;
		
		private static var energy_neg_bg_color:uint = 0xefc6c1;
		private static var mood_neg_bg_color:uint = 0xefc6c1;
		private static var xp_neg_bg_color:uint = 0xc7dce0;
		private static var currants_neg_bg_color:uint = 0xd4c6a3;
		private static var favor_neg_bg_color:uint = 0xebccd6;
		private static var items_neg_bg_color:uint = 0xd3d3d3;
		private static var imagination_neg_bg_color:uint = 0xccaedb;
		
		//border
		private static var border_color:uint = 0xFFFFFF;
		private static var border_width:uint = 2;
		
		private static var is_inited:Boolean;
		
		private var pos_neg_tf:TextField = new TextField();
		private var tf:TextField = new TextField();
		private var icon:DisplayObject;
		
		private var _type:String;
		private var _amount:int;
		private var _class_tsid:String;
		private var _item_config:Object;
		private var _item_is_broken:Boolean;
		private var _tip_text:String;
		private var _draw_border:Boolean = true;
		private var _draw_background:Boolean = true;
		private var _reward:Reward;
		
		private var show_number:Boolean;
		
		public function Slug(reward:Reward, show_number:Boolean = true) {
			if(!reward) {
				CONFIG::debugging {
					Console.warn('Trying to create a slug without passing it a reward is bad. If you are setting type/amount in the setter you\'ll need to set' +
								 ' a reward as well if you plan on using favor or items');
				}
				return;
			}
			
			if(reward.type == Reward.DROP_TABLE){
				CONFIG::debugging {
					Console.warn('Drop tables do not get a slug!');
				}
				return;
			}
			
			_reward = reward;
			if (_reward && _reward.favor && _reward.favor.giant == 'ti') _reward.favor.giant = 'tii';
			
			_type = reward.type;
			_amount = reward.amount;
			
			this.show_number = show_number;
			
			if(reward.item) {
				_class_tsid = reward.item.class_tsid;
				_item_config = reward.item.config;
				_item_is_broken = reward.item.is_broken;
			}
			
			if(amount != 0){
				if(!is_inited) init();
				construct();
				draw();
			}else{
				CONFIG::debugging {
					Console.warn('Attempt to create a '+_type+' slug with a 0 amount!');
				}
			}
		}
		
		public function animate(animator:SlugAnimator, is_queued:Boolean = true):void {
			animator.add(this, is_queued);
		}
		
		private function draw(type_changed:Boolean = false):void {
			var pos_or_neg:String = (_amount > 0) ? 'pos' : 'neg';
			var str_num:String = StringUtil.formatNumberWithCommas(Math.abs(_amount));
			var gap:int;
			
			//new icon if we need it
			if(type_changed){
				if (icon) removeChild(icon);
				icon = getIcon(_type, pos_or_neg);
				if (icon) addChild(icon);
			}
			
			//if no icon at this point, it's bad and we should not draw the slug
			if(!icon) {
				CONFIG::debugging {
					Console.warn('There is no icon for this type of slug, check that reward is set: '+ (reward ? reward.type+': '+reward.amount : 'REWARD NULL!'));
				}
				return;
			}
			
			//if we are an item type, then add a couple of extra pixels to the right
			if(_type == Slug.ITEMS) right_padding = 2;
			
			//set the gap
			gap = (HEIGHT - icon.height)/2;
			
			//set the tf contents
			if(show_number){
				pos_neg_tf.htmlText = '<p class="slug"><span class="slug_'+_type+'_'+pos_or_neg+'">'+((_amount > 0) ? '+':'-')+'</span></p>';
				tf.htmlText = '<p class="slug"><span class="slug_'+_type+'_'+pos_or_neg+'">'+str_num+'</span></p>';
				tf.x = int(pos_neg_tf.width) + 1;
				tf.y = Math.ceil((HEIGHT - tf.height)/2) + 1;
				
				pos_neg_tf.y = tf.y - 1;
			}
			
			//move the icon
			icon.x = show_number ? int(tf.x + tf.width) + TEXT_ICON_PADDING : 0;
			icon.y = int(gap);
			
			//draw the bg
			var right_radius:int = _type == Slug.ENERGY ? ENERGY_CORNER_RADIUS : CORNER_RADIUS;
			var g:Graphics = graphics;
			g.clear();
			
			if(_draw_background){
				if(_draw_border) g.lineStyle(border_width, border_color);
				g.beginFill(getBgColor());
				g.drawRoundRectComplex(0, 0, int(icon.x + icon.width + gap)+right_padding, HEIGHT,
									   CORNER_RADIUS, right_radius, CORNER_RADIUS, right_radius);
			}
			
			//set the tip text
			_tip_text = StringUtil.formatNumberWithCommas(_amount) + ' ' + _type;
			
			if(_reward){
				if(_reward.type == Reward.FAVOR){
					//the tool tip needs to have the giant data
					_tip_text += ' with ' + Giants.getLabel(_reward.favor.giant);
				}
				else if(_reward.type == Reward.ITEMS){
					//items are a different bag, put the label out, if no label then say Item(s)
					_tip_text = _amount + ' ' + (_reward.item.label ? _reward.item.label : (_amount != 1 ? 'Items' : 'Item'));
				}
			}
		}
		
		private function construct():void {
			//setup the tfs
			if(show_number){
				TFUtil.prepTF(tf, false);
				TFUtil.prepTF(pos_neg_tf, false);
				tf.filters = pos_neg_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
				
				pos_neg_tf.x = left_padding;
				
				addChild(pos_neg_tf);
				addChild(tf);
			}
			
			//setup the icon
			var pos_or_neg:String = (_amount > 0) ? 'pos' : 'neg';
			icon = getIcon(_type, pos_or_neg);
			if (icon) addChild(icon);
			
			//do the tooltip thang
			TipDisplayManager.instance.registerTipTrigger(this);
			addEventListener(Event.REMOVED, onStageRemove, false, 0, true);
		}
		
		private function getIcon(type:String, pos_or_neg:String):DisplayObject {
			if (AssetManager.instance.assets.hasOwnProperty('slug_'+type+'_'+pos_or_neg)) {
				return new AssetManager.instance.assets['slug_'+type+'_'+pos_or_neg];
			}
			
			if(type == ITEMS && _class_tsid){
				if(class_tsid == 'null') return null; //And also slap Myles
				var furn_config:FurnitureConfig = (_item_config && _item_config.furniture) ? FurnitureConfig.fromAnonymous(_item_config.furniture, '') : null;
				var icon_state:String = (_item_is_broken) ? 'broken_iconic' : 'iconic';
				var iiv:ItemIconView = new ItemIconView(_class_tsid, ICON_HEIGHT, {state:icon_state, config:furn_config});
				return iiv;
			}
			
			if (pos_or_neg == 'pos' && AssetManager.instance.assets.hasOwnProperty('slug_'+type+'_pos')) {
				return new AssetManager.instance.assets['slug_'+type+'_pos'];
			}
			
			if (pos_or_neg == 'neg' && AssetManager.instance.assets.hasOwnProperty('slug_'+type+'_neg')) {
				return new AssetManager.instance.assets['slug_'+type+'_neg'];
			}
			
			return null;
		}
		
		private function getBgColor():uint {
			//instead of getting the CSS each time, let's do it this way
			var pos:Boolean = _amount > 0;
			
			switch(_type){
				case XP:
					return pos ? xp_pos_bg_color : xp_neg_bg_color;
					break;
				case CURRANTS:
					return pos ? currants_pos_bg_color : currants_neg_bg_color;
					break;
				case ENERGY:
					return pos ? energy_pos_bg_color : energy_neg_bg_color;
					break;
				case MOOD:
					return pos ? mood_pos_bg_color : mood_neg_bg_color;
					break;
				case FAVOR:
					return pos ? favor_pos_bg_color : favor_neg_bg_color;
					break;
				case IMAGINATION:
					return pos ? imagination_pos_bg_color : imagination_neg_bg_color;
					break;
				case ITEMS:
				default:
					return pos ? items_pos_bg_color : items_neg_bg_color;
					break;
			}
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {						
			if(!_tip_text) return null;
			
			return {
				txt: _tip_text,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
		
		private function onStageRemove(event:Event):void {
			//it's gone, tell the tip manager we are no more
			TipDisplayManager.instance.unRegisterTipTrigger(this);
		}
		
		private function init():void {
			//populate the CSS values
			var css:CSSManager = CSSManager.instance;
			
			xp_pos_bg_color = xp_neg_bg_color = css.getUintColorValueFromStyle('slug_xp_pos', 'backgroundColor', xp_pos_bg_color);
			currants_pos_bg_color = currants_neg_bg_color = css.getUintColorValueFromStyle('slug_currants_pos', 'backgroundColor', currants_pos_bg_color);
			energy_pos_bg_color = css.getUintColorValueFromStyle('slug_energy_pos', 'backgroundColor', energy_pos_bg_color);
			mood_pos_bg_color = css.getUintColorValueFromStyle('slug_mood_pos', 'backgroundColor', mood_pos_bg_color);
			energy_neg_bg_color = css.getUintColorValueFromStyle('slug_energy_neg', 'backgroundColor', energy_neg_bg_color);
			mood_neg_bg_color = css.getUintColorValueFromStyle('slug_mood_neg', 'backgroundColor', mood_neg_bg_color);
			favor_pos_bg_color = favor_neg_bg_color = css.getUintColorValueFromStyle('slug_favor_pos', 'backgroundColor', favor_pos_bg_color);
			items_pos_bg_color = items_neg_bg_color = css.getUintColorValueFromStyle('slug_items_pos', 'backgroundColor', items_pos_bg_color);
			imagination_pos_bg_color = imagination_neg_bg_color = css.getUintColorValueFromStyle('slug_imagination_pos', 'backgroundColor', imagination_pos_bg_color);
			
			border_color = css.getUintColorValueFromStyle('slug', 'borderColor', border_color);
			border_width = css.getNumberValueFromStyle('slug', 'borderWidth', border_width);
			
			is_inited = true;
		}
		
		public function get type():String { return _type; }
		public function set type(value:String):void {
			if(_type == value) return;
			
			_type = value;
			draw(true);
		}
		
		public function get amount():int { return _amount; }
		public function set amount(value:int):void {
			if(_amount == value) return;
			
			_amount = value;
			draw();
		}
		
		public function get class_tsid():String { return _class_tsid; }
		public function set class_tsid(value:String):void {
			_class_tsid = value;
			draw();
		}
		
		public function set draw_background(value:Boolean):void {
			if(_draw_background == value) return;
			
			_draw_background = value;
			draw();
		}
		
		public function set draw_border(value:Boolean):void {
			if(_draw_border == value) return;
			
			_draw_border = value;
			draw();
		}
		
		public function set dim_text(value:Boolean):void {
			var new_alpha:Number = DIM_ALPHA;
			if(!value) new_alpha = 1;
			
			tf.alpha = new_alpha;
			pos_neg_tf.alpha = new_alpha;
		}
		
		public function get tip_text():String { return _tip_text; }
		public function set tip_text(str:String):void {
			if(str) _tip_text = str;
		}
		
		public function get reward():Reward { return _reward; }
		
		public function getTextCenterPt():Point {
			var rect:Rectangle = pos_neg_tf.getBounds(pos_neg_tf).union(tf.getBounds(tf));
			
			return localToGlobal(new Point((tf.x + tf.width - left_padding)/2, rect.height/2));
		}
	}
}