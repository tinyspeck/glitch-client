package com.tinyspeck.engine.view.ui.craftybot
{
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.CraftyManager;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.SpreadMethod;
	import flash.display.Sprite;
	import flash.events.TextEvent;
	import flash.geom.Matrix;
	import flash.text.TextField;

	public class CraftyFuel extends Sprite
	{
		private static const HEIGHT:uint = 17;
		private static const TF_PADD:uint = 12;
		private static const REFLECTION_PADD:uint = 4;
		private static const COLORS:Array = [0x97c04a, 0xb9d676];
		private static const ALPHAS:Array = [1, 1];
		private static const RATIOS:Array = [0, 255];
		private static const MATRIX:Matrix = new Matrix();
		
		private var label_tf:TSLinkedTextField = new TSLinkedTextField();
		private var amount_tf:TextField = new TextField();
		
		private var bar_holder:Sprite = new Sprite();
		private var reflection:Shape = new Shape();
		private var bubbles_mask:Shape = new Shape();
		private var bubbles:DisplayObject;
		
		private var w:int;
		
		private var is_built:Boolean;
		
		public function CraftyFuel(w:int){
			this.w = w;
		}
		
		private function buildBase():void {
			//bg
			var g:Graphics = graphics;
			g.beginFill(CSSManager.instance.getUintColorValueFromStyle('crafty_fuel', 'backgroundColor', 0xe3e4e4));
			g.drawRect(0, 0, w, HEIGHT);
			
			//bar
			COLORS[0] = CSSManager.instance.getUintColorValueFromStyle('crafty_fuel_pb', 'color1', 0x97c04a);
			COLORS[1] = CSSManager.instance.getUintColorValueFromStyle('crafty_fuel_pb', 'color2', 0xb9d676);
			addChild(bar_holder);
			
			//bubbles
			bubbles = new AssetManager.instance.assets.crafty_bubbles();
			bubbles.mask = bubbles_mask;
			bubbles.x = 5;
			addChild(bubbles);
			addChild(bubbles_mask);
			
			//reflection
			reflection.x = REFLECTION_PADD;
			reflection.y = REFLECTION_PADD;
			g = reflection.graphics;
			g.beginFill(0xffffff, .4);
			g.drawRoundRect(0, 0, w - REFLECTION_PADD*2, 4, 8);
			addChild(reflection);
			
			//tfs
			TFUtil.prepTF(label_tf, false);
			label_tf.htmlText = '<p class="crafty_fuel">Fuel - <a href="#">Add More</a></p>';
			label_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			label_tf.x = TF_PADD;
			label_tf.y = int(HEIGHT/2 - label_tf.height/2);
			label_tf.addEventListener(TextEvent.LINK, onFuelClick, false, 0, true);
			addChild(label_tf);
			
			TFUtil.prepTF(amount_tf, false);
			amount_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			amount_tf.y = label_tf.y;
			addChild(amount_tf);
			
			is_built = true;
		}
		
		public function show():void {
			if(!is_built) buildBase();
			const cm:CraftyManager = CraftyManager.instance;
			
			//set the text amount
			amount_tf.htmlText = '<p class="crafty_fuel">'+cm.fuel_count+'/'+cm.fuel_max+'</p>';
			amount_tf.x = int(w - amount_tf.width - TF_PADD);
			
			//set the fuel text
			var label_txt:String = '<p class="crafty_fuel">';
			label_txt += 'Fuel';
			if(cm.can_refuel){
				label_txt += ' - <a href="event:refuel">Add More</a>';
			}
			label_txt += '</p>';
			label_tf.htmlText = label_txt;
			
			//update the bar width
			const perc:Number = cm.fuel_count/cm.fuel_max;
			const bar_w:int = perc*w;
			MATRIX.createGradientBox(bar_w, HEIGHT/2, Math.PI/2);
			var g:Graphics = bar_holder.graphics;
			g.clear();
			g.beginGradientFill(GradientType.LINEAR, COLORS, ALPHAS, RATIOS, MATRIX, SpreadMethod.REFLECT);
			g.drawRect(0, 0, bar_w, HEIGHT);
			
			g = bubbles_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRect(0, 0, bar_w, HEIGHT);
			
			//get this bubble party started
			handleBubbles(true);
		}
		
		public function hide():void {
			//shut down the bubble party, NARC.
			handleBubbles(false);
		}
		
		private function handleBubbles(is_animating:Boolean):void {
			if(is_animating && !TSTweener.isTweening(bubbles)){
				keepTheBubblePartyGoing();
			}
			else if(!is_animating){
				TSTweener.removeTweens(bubbles);
			}
		}
		
		private function keepTheBubblePartyGoing():void {
			bubbles.y = 0;
			TSTweener.addTween(bubbles, {y:-(HEIGHT-4), time:.5, transition:'linear', onComplete:keepTheBubblePartyGoing});
		}
		
		private function onFuelClick(event:TextEvent):void {
			//refuel this sucker
			CraftyManager.instance.refuel();
			
			//change the text so they don't mash it
			label_tf.htmlText = '<p class="crafty_fuel">Fuel</p>';
		}
		
		override public function get height():Number { return HEIGHT; }
	}
}