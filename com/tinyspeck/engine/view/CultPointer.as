package com.tinyspeck.engine.view
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.quasimondo.geom.ColorMatrix;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;
	
	public class CultPointer extends Sprite {
		
		public static const DIRECTION_LEFT:String = 'left';
		public static const DIRECTION_RIGHT:String = 'right';
		public static const WIDTH:int = 120;
		public static const PADD_TOP:int = 2;
		public static const PADD_SIDE:int = 3;
		private static const TF_ALPHA:Number = .8;
		
		private var tf:TextField = new TextField();
		private var holder:Sprite = new Sprite();
		private var drop_holder:Sprite = new Sprite();
		private var arrow_sp:Sprite = new Sprite();
		private var direction:String;
		private var _showing:Boolean;
		
		public function CultPointer(direction:String):void {
			this.direction = direction;
			build();
		}
		
		private function build():void {
			mouseChildren = mouseEnabled = false;
			alpha = 0;
			addChild(holder);
			holder.x = 0;
			holder.y = 0;
			
			addChild(drop_holder);
			drop_holder.x = holder.x;
			drop_holder.y = holder.y;
			drop_holder.filters = StaticFilters.copyFilterArrayFromObject({alpha:.15, knockout:true}, StaticFilters.black2px90Degrees_DropShadowA);
			
			
			holder.addChild(arrow_sp);
			AssetManager.instance.loadBitmapFromWeb('public/next.png', onWWWimgBitmapLoaded, 'CultPointer');
			
			// tf
			TFUtil.prepTF(tf, true);
			tf.alpha = TF_ALPHA;
			
			//if (direction == DIRECTION_LEFT) {
				tf.htmlText = '<p class="cult_pointer">Can be placed over this way</p>';
			//} else {
			//	tf.htmlText = '<p class="cult_pointer">Look to the right</p>';
			//}
			
			holder.addChild(tf);
		}
		
		private function onWWWimgBitmapLoaded(filename:String, bm:Bitmap):void {
			if (bm) {
				var cm:ColorMatrix = new com.quasimondo.geom.ColorMatrix();
				cm.adjustContrast(1);
				cm.adjustBrightness(100);
				cm.colorize(0xFFFFFF);
				
				bm.filters = [cm.filter];
				arrow_sp.addChild(bm);
				
				tf.width = WIDTH+(-PADD_SIDE*3)+(-bm.width);
				tf.y = PADD_TOP;
				arrow_sp.y = PADD_TOP+1;
				
				if (direction == DIRECTION_LEFT) {
					bm.scaleX = -1;
					bm.x = bm.width;
					tf.x = bm.width+PADD_SIDE;
					arrow_sp.x = PADD_SIDE;
				} else {
					tf.x = PADD_SIDE;
					arrow_sp.x = WIDTH+(-bm.width)+(-PADD_SIDE);
				}
				
				draw();
			}
		}
		
		public function get showing():Boolean {
			return _showing;
		}
		
		public function set showing(value:Boolean):void {
			if (_showing == value) return;
			_showing = value;
			
			TSTweener.removeTweens(this);
			var a:Number = (_showing) ? 1 : 0;
			TSTweener.addTween(this, {alpha:a, time:.4, transition:'linear'});
		}
		
		private function draw():void {
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
		}
	}
}
