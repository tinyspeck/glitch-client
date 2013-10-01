package com.tinyspeck.engine.view.ui.furniture
{
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.engine.data.house.CultivationsChoice;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CultManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class CultButton extends DisposableSprite {		
		public static const WIDTH:uint = 100;
		private static const HOVER_ALPHA:Number = .3;
		private static const CLICK_ALPHA:Number = .5;
		
		public var iiv:ItemIconView;
		public var iiv_holder:Sprite = new Sprite();
		
		private var choice:CultivationsChoice;
		
		private var name_tf:TextField = new TextField();
		private var cost_tf:TextField = new TextField();
		private var level_tf:TextField = new TextField();
		
		private var subscriber_icon:DisplayObject;
		private var imagination_icon:DisplayObject;
		private var lock_icon:DisplayObject;
		private var highlighter:Sprite = new Sprite();
		
		private var glowA:Array;

		private var icon_padd:uint;
		private var h:uint;
		
		private var facing_left:Boolean;
		private var _disabled:Boolean;
		private var _is_clicked:Boolean;
		
		public function CultButton(h:int, icon_padd:int) {
			this.icon_padd = icon_padd;
			this.h = h;
			
			mouseChildren = false;
			useHandCursor = buttonMode = true;
			
			//highlighter
			var g:Graphics = highlighter.graphics;
			g.beginFill(0xffffff);
			g.drawRect(0, 0, WIDTH-1, h); //-1 saves space for the vertical line
			highlighter.alpha = 0;
			addChild(highlighter);
			
			//filter
			glowA = StaticFilters.copyFilterArrayFromObject({color:0xf5f7f7, blurX:3, blurY:3}, StaticFilters.white3px_GlowA);
			
			//mouse stuff
			addEventListener(MouseEvent.ROLL_OVER, onRoll, false, 0, true);
			addEventListener(MouseEvent.ROLL_OUT, onRoll, false, 0, true);
			addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			
			//liv holder
			addChild(iiv_holder);
			
			//tf
			TFUtil.prepTF(cost_tf, false);
			cost_tf.filters = glowA;
			addChild(cost_tf);
			
			//level_tf
			TFUtil.prepTF(level_tf, false);
			level_tf.filters = StaticFilters.copyFilterArrayFromObject({color:0xf5f7f7}, StaticFilters.white3px_GlowA);
			addChild(level_tf);
			
			//name tf
			TFUtil.prepTF(name_tf);
			name_tf.width = WIDTH;
			name_tf.y = 3;
			addChild(name_tf);
		}
		
		// some custom scales for some items
		private var scale_adjustments:Object = {
			proto_jellisac_mound: .7,
			proto_sparkly_rock: .7,
			proto_dullite_rock: .7,
			proto_barnacle_pod: .6,
			proto_beryl_rock: .7,
			proto_metal_rock: .7,
			proto_firefly_hive: .7
		}
		
		public function show(item_class:String, choice:CultivationsChoice, clicked:Boolean, draw_border:Boolean):void {
			clean();
			this.choice = choice;
			
			//text/icons
			setText();
			var scale:Number = scale_adjustments[choice.class_id] || 1;
			var iiv_w:int = (width - icon_padd*2)*scale;
			
			//item
			iiv = new ItemIconView(item_class, iiv_w, 'iconic', 'center');
			iiv.scaleX = (facing_left) ? -1 : 1; // ChassisUpgradeButton, which extends this class, has facing_left = true, to face the homes in their default orientation
			iiv_holder.addChildAt(iiv, 0);
			iiv.x = int(width/2);
			iiv.y = int(name_tf.y + name_tf.height + ((iiv.h/2)/scale));
			
			//default filter state
			is_clicked = clicked;
			
			//do we draw the border
			var g:Graphics = graphics;
			g.clear();
			if(draw_border){
				g.beginFill(0xc2ccce);
				g.drawRect(WIDTH-1, 0, 1, h);
			}
			
			disabled = !choice.client::will_fit || (choice.imagination_cost && choice.client::need_imagination);
			
			TipDisplayManager.instance.registerTipTrigger(this);
		}
		
		public function hide():void {
			clean();
			if(parent) parent.removeChild(this);
			
			TipDisplayManager.instance.unRegisterTipTrigger(this);
		}
		
		public function setText():void {
			if (!choice) return;
			
			//name
			name_tf.htmlText = '<p class="cult_button"><span class="cult_button_name">'+choice.label+'</span></p>';
			
			//set up the displayed text
			var txt:String = '';
			var span_class:String;
			
			if (choice.min_level) {
				//level lock icon
				if(!lock_icon) {
					lock_icon = new AssetManager.instance.assets.lock_small();
					lock_icon.x = int(width/2 - lock_icon.width/2);
					lock_icon.y = int(h - lock_icon.height);
					addChildAt(lock_icon, getChildIndex(level_tf));
				}
				lock_icon.visible = true;
				
				//set the text
				level_tf.htmlText = '<p class="cult_button"><span class="cult_button_level">L'+choice.min_level+'</span></p>';
				level_tf.x = int(lock_icon.x + lock_icon.width - level_tf.width/2 - 6); //accounts for the transparent glow stuff
				level_tf.y = int(lock_icon.y + lock_icon.height - level_tf.height/2 - 8);
			}
			
			//we need to show the lock?
			const need_level:Boolean = choice.min_level && choice.client::need_level;
			if (lock_icon) lock_icon.visible = need_level;
			level_tf.visible = need_level;
			
			//cost imagination?
			//if they are level locked, don't show the price
			if (imagination_icon) imagination_icon.visible = !need_level;
			cost_tf.visible = !need_level;
			if(!need_level){
				if(choice.imagination_cost){
					span_class = (choice.client::need_imagination) ? 'cult_button_imagination_warn' : 'cult_button_imagination';
					txt = '<span class="'+span_class+'">'+StringUtil.formatNumberWithCommas(choice.imagination_cost)+'</span>';
					
					//imagination icon
					if(!imagination_icon) {
						imagination_icon = new AssetManager.instance.assets.slug_imagination_pos();
						imagination_icon.filters = glowA;
						addChild(imagination_icon);
					}
				}
				if (imagination_icon) imagination_icon.visible = choice.imagination_cost > 0;
				
				//set the text
				cost_tf.htmlText = '<p class="cult_button">'+txt+'</p>';
				cost_tf.x = int(width/2 - cost_tf.width/2 + (imagination_icon && imagination_icon.visible ? imagination_icon.width/2 + 1 : 0));
				cost_tf.y = int(h - cost_tf.height - 2);
				
				//move the imag icon where it needs to go
				if(imagination_icon) {
					imagination_icon.x = int(cost_tf.x - imagination_icon.width + 1);
					imagination_icon.y = int(cost_tf.y + (cost_tf.height/2 - imagination_icon.height/2));
				}
			}
		}
		
		private function onRoll(event:MouseEvent):void {
			if(_is_clicked) return;
			const is_over:Boolean = event.type == MouseEvent.ROLL_OVER;
			highlighter.alpha = is_over ? HOVER_ALPHA : 0;
		}
		
		private function onClick(event:MouseEvent):void {
			if (!iiv || !iiv.loaded || disabled || CultManager.instance.waiting_on_item) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			
			//strong glow
			is_clicked = true;
			
			//let whoever is listening know
			dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
		}
		
		private function clean():void {
			if (iiv) {
				iiv.dispose();
				if (iiv.parent) iiv.parent.removeChild(iiv);
				iiv = null;
			}
		}
		
		override public function dispose():void {
			clean();
		}
		
		public function get cultivation_choice():CultivationsChoice { return choice; }
		
		public function get is_clicked():Boolean { return _is_clicked; }
		
		public function set is_clicked(value:Boolean):void {
			_is_clicked = value;
			highlighter.alpha = value ? CLICK_ALPHA : 0;
		}
		
		public function get disabled():Boolean {
			return _disabled;
		}
		
		public function set disabled(value:Boolean):void 	{
			_disabled = value;
			iiv_holder.alpha = (_disabled) ? .3 : 1;
			if (imagination_icon) imagination_icon.alpha = iiv_holder.alpha;
			if (lock_icon) lock_icon.alpha = iiv_holder.alpha;
			cost_tf.alpha = iiv_holder.alpha;
			level_tf.alpha = iiv_holder.alpha;
			name_tf.alpha = _disabled ? .5 : 1;
		}
		
		override public function get height():Number { return h; }
		override public function get width():Number { return WIDTH; }
	}
}