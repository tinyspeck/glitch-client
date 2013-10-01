package com.tinyspeck.engine.view
{
	import com.tinyspeck.engine.data.house.CultivationsChoice;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;
	
	public class CultCarryTip extends Sprite {
		
		public static const WIDTH:int = 140;
		public static const PADD_TOP:int = 1;
		public static const PADD_SIDE:int = 3;
		private static const TF_ALPHA:Number = .8;
		
		private var choice:CultivationsChoice;
		private var tf:TextField = new TextField();
		private var holder:Sprite = new Sprite();
		private var drop_holder:Sprite = new Sprite();
		private var current_label:String;
		public var for_display_above:Boolean = true;
		
		public function CultCarryTip():void {
			build();
		}
		
		private function build():void {
			addChild(holder);
			holder.x = -(WIDTH/2);
			holder.y = 0;
			
			addChild(drop_holder);
			drop_holder.x = holder.x;
			drop_holder.y = holder.y;
			drop_holder.filters = StaticFilters.copyFilterArrayFromObject({alpha:.15, knockout:true}, StaticFilters.black2px90Degrees_DropShadowA);
			
			//tfs
			TFUtil.prepTF(tf, true);
			//tf.embedFonts = false;
			tf.width = WIDTH-(PADD_SIDE*2);
			tf.x = PADD_SIDE;
			tf.y = PADD_TOP;
			tf.alpha = TF_ALPHA;
			holder.addChild(tf);
		}
		
		public function setChoice(choice:CultivationsChoice):void {
			this.choice = choice;
			update();
		}
		
		public function update():void {
			var label:String;
			visible = true;
			if (!choice) {
				label = 'something bad happened';
			} else {
				if (!choice.can_place) {
					label = 'You are currently unable to place this item.';
				} else if (choice.client::need_level) {
					label = 'You need to be level '+choice.min_level+' before you can place this.';
				} else if (choice.client::need_imagination) {
					label = 'You need '+choice.client::need_imagination+' more imagination before you can place this.';
				} else {
					visible = false;
				}
			}
			
			//update the text
			if(current_label == label || !visible) return;
			
			
			current_label = label;
			tf.htmlText = '<p class="cult_carry_tip">'+current_label+'</p>';
			
			var h:int = tf.y+tf.height+PADD_TOP;
			
			//draw the outside
			var g:Graphics = holder.graphics;
			g.clear();
			g.beginFill(0x16191a, .6);
			g.drawRoundRect(0, 0, WIDTH, h, 8);
			
			//object for the shadow to knockout
			g = drop_holder.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRoundRect(0, 0, WIDTH, h, 8);
			
			if (for_display_above) {
				drop_holder.y = holder.y = -h;
			}
		}
	}
}
