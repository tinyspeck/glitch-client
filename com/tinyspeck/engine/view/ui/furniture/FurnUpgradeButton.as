package com.tinyspeck.engine.view.ui.furniture
{
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.engine.data.furniture.FurnUpgrade;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class FurnUpgradeButton extends DisposableSprite implements ITipProvider {		
		public var iiv:ItemIconView;
		public var iiv_holder:Sprite = new Sprite();
		
		protected var current_upgrade:FurnUpgrade;
		protected var tf:TextField = new TextField();
		
		protected var subscriber_icon:DisplayObject;
		protected var credits_icon:DisplayObject;
		protected var new_icon:DisplayObject;
		
		protected var wh:int;
		protected var padd:uint;
		protected var facing_left:Boolean;
		
		private var _is_clicked:Boolean;
		
		public function FurnUpgradeButton(wh:int, padd:int) {
			this.wh = wh;
			this.padd = padd;
			
			mouseChildren = false;
			useHandCursor = buttonMode = true;
			
			var g:Graphics = graphics;
			g.beginFill(0xffffff);
			g.drawRoundRect(0, 0, wh, wh, 10);
			
			//mouse stuff
			addEventListener(MouseEvent.ROLL_OVER, onRollOver, false, 0, true);
			addEventListener(MouseEvent.ROLL_OUT, onRollOut, false, 0, true);
			addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			
			//tf
			TFUtil.prepTF(tf, false);
			addChild(tf);
			addChild(iiv_holder);
		}
		
		public function show(item_class:String, upgrade:FurnUpgrade, clicked:Boolean):void {
			clean();
			current_upgrade = upgrade;
			
			//text/icons
			setText();
			
			//item
			iiv = new ItemIconView(item_class, wh - padd*2, {config:upgrade.furniture, state:'iconic'}, 'center'/*, false, true*/);
			iiv.scaleX = (facing_left) ? -1 : 1; // ChassisUpgradeButton, which extends this class, has facing_left = true, to face the homes in their default orientation
			iiv_holder.addChildAt(iiv, 0);
			iiv.x = int(wh/2);
			iiv.y = int(wh/2 - (tf.text ? 5 : 0)); //gives a little padding to the text at the bottom
			
			//default filter state
			is_clicked = clicked;
			
			//tooltip party
			TipDisplayManager.instance.registerTipTrigger(this);
		}
		
		public function hide():void {
			clean();
			if(parent) parent.removeChild(this);
		}
		
		protected function setText():void {
			//set up the displayed text
			var txt:String = 'Free for everyone';
			
			//subscriber only?
			if(current_upgrade.subscriber_only){
				txt = 'Free for subscribers';
				if(!subscriber_icon) {
					subscriber_icon = new AssetManager.instance.assets.furn_subscriber();
					subscriber_icon.x = int(wh - subscriber_icon.width - padd/2);
					subscriber_icon.y = int(wh - subscriber_icon.height - padd);
					addChild(subscriber_icon);
				}
			}
			if(subscriber_icon) subscriber_icon.visible = current_upgrade.subscriber_only;
			
			//cost credits?
			if(current_upgrade.credits){
				txt = '<span class="furn_upgrade_button_credits">'+StringUtil.formatNumberWithCommas(current_upgrade.credits)+' '+
					  (current_upgrade.credits != 1 ? 'credits' : 'credit')+'</span>';
				if(!credits_icon) {
					credits_icon = new AssetManager.instance.assets.furn_credits_small();
					addChild(credits_icon);
				}
			}
			if(credits_icon) credits_icon.visible = current_upgrade.credits > 0;
			
			//is new?!
			if(current_upgrade.is_new && !new_icon){
				new_icon = new AssetManager.instance.assets.furniture_new_badge();
				new_icon.x = 2;
				new_icon.y = 1;
				addChild(new_icon);
			}
			if(new_icon) new_icon.visible = current_upgrade.is_new;
			
			//if we already own this, but we only care about that if it actually costs anything
			if(current_upgrade.is_owned && current_upgrade.credits){
				//set the text
				txt = 'You own this';
				if(subscriber_icon) subscriber_icon.visible = false;
				if(credits_icon) credits_icon.visible = false;
			}
			
			//set the text
			tf.htmlText = '<p class="furn_upgrade_button">'+txt+'</p>';
			tf.x = int(wh/2 - tf.width/2 + (credits_icon && credits_icon.visible ? credits_icon.width/2 + 1 : 0));
			tf.y = int(wh - tf.height - 2);
			
			//move the credits icon where it needs to go
			if(credits_icon) {
				credits_icon.x = int(tf.x - credits_icon.width + 1);
				credits_icon.y = int(tf.y + (tf.height/2 - credits_icon.height/2) + 1);
			}
		}
		
		private function onRollOver(event:MouseEvent):void {
			//slight glow
			if(_is_clicked) return;
			filters = StaticFilters.blue2px40Alpha_GlowA;
		}
		
		private function onRollOut(event:MouseEvent = null):void {
			//default filters
			if(_is_clicked) return;
			filters = StaticFilters.black2px90Degrees_FurnDropShadowA;
		}
		
		private function onClick(event:MouseEvent):void {
			if (!iiv || !iiv.loaded) {
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
			
			TipDisplayManager.instance.unRegisterTipTrigger(this);
		}
		
		override public function dispose():void {
			clean();
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target || !current_upgrade) return null;
			
			//what is the name of this thing?!
			return {
				txt: current_upgrade.label,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
		
		public function get furn_upgrade():FurnUpgrade { return current_upgrade; }
		
		public function get is_clicked():Boolean { return _is_clicked; }
		
		public function set is_clicked(value:Boolean):void {
			_is_clicked = value;
			if(value){
				filters = StaticFilters.blue2px_GlowA;
			} else {
				//no longer clicked, set it back to the default filters
				onRollOut();
			}
		}
		
		override public function get height():Number { return wh; }
		override public function get width():Number { return wh; }
	}
}