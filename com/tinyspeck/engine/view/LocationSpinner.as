package com.tinyspeck.engine.view
{
	import com.quasimondo.geom.ColorMatrix;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.text.TextField;
	
	public class LocationSpinner extends Sprite {
		
		public static const WIDTH:int = 120;
		public static const PADD_TOP:int = 1;
		public static const PADD_SIDE:int = 3;
		private static const TF_ALPHA:Number = .8;
		
		private var tf:TextField = new TextField();
		private var holder:Sprite = new Sprite();
		private var drop_holder:Sprite = new Sprite();
		private var current_label:String;
		private const spinner_mc:MovieClip = new AssetManager.instance.assets.spinner() as MovieClip;
		
		public function LocationSpinner():void {
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
			
			// spinner!
			holder.addChild(spinner_mc);
			var cm:ColorMatrix = new com.quasimondo.geom.ColorMatrix();
			cm.adjustContrast(1);
			cm.adjustBrightness(100);
			cm.colorize(0xFFFFFF);
			spinner_mc.filters = [cm.filter].concat(StaticFilters.loadingTip_DropShadowA);
			spinner_mc.x = (WIDTH/2)-(spinner_mc.width/2);
			spinner_mc.y = PADD_TOP;
			
			// tf
			TFUtil.prepTF(tf, true);
			//tf.embedFonts = false;
			tf.width = WIDTH-(PADD_SIDE*2);
			tf.x = PADD_SIDE;
			tf.y = spinner_mc.y+spinner_mc.height+5;
			tf.alpha = TF_ALPHA;
			holder.addChild(tf);
		}
		
		public function setLabel(label:String):void {
			
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
			
			drop_holder.y = holder.y = -h;
		}
	}
}
