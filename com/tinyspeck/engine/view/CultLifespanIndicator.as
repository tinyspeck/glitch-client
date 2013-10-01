package com.tinyspeck.engine.view
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.CultManager;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.ProgressBar;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	public class CultLifespanIndicator extends Sprite {
		
		public static const WIDTH:int = 138;
		public static const BASE_HEIGHT:int = 55;
		private var h:int
		public static const PADD_SIDE:int = 9;
		public static const BAR_H:int = 15;
		public static const BAR_W:int = WIDTH-(PADD_SIDE*2);
		
		private static const TF_ALPHA:Number = .8;
		private static const LOW_PERC:Number = .2; //what percentage to we change the bar colors
		
		public var itemstack:Itemstack;
		
		private var nudge_tf:TextField = new TextField();
		private var name_tf:TextField = new TextField();
		private var life_tf:TextField = new TextField();
		
		public var holder:Sprite = new Sprite();
		private var drop_holder:Sprite = new Sprite();
		private var nudge_holder:Sprite = new Sprite();
		
		private var bar:ProgressBar;
		
		private var current_label:String;
		private var current_perc:Number;
		private var top_bar_color:uint;
		private var bottom_bar_color:uint;
		private var top_bar_low_color:uint;
		private var bottom_bar_low_color:uint;
		
		public function CultLifespanIndicator(itemstack:Itemstack):void {
			this.itemstack = itemstack;
			
			build();
		}
		
		private function build():void {
			holder.visible = false; // will be marked true with the lis_view for this thing is loaded
			
			addChild(drop_holder);
			addChild(holder);
			holder.x = -(WIDTH/2);
			
			drop_holder.x = holder.x;
			drop_holder.filters = StaticFilters.copyFilterArrayFromObject({alpha:.15, knockout:true}, StaticFilters.black2px90Degrees_DropShadowA);
			
			//bar colors
			const cssm:CSSManager = CSSManager.instance;
			top_bar_color = cssm.getUintColorValueFromStyle('cult_lifespan_bar', 'topColor', 0x4aa6bf);
			bottom_bar_color = cssm.getUintColorValueFromStyle('cult_lifespan_bar', 'bottomColor', 0x2c92ad);
			top_bar_low_color = cssm.getUintColorValueFromStyle('cult_lifespan_bar', 'topColorLow', 0xbf5b4a);
			bottom_bar_low_color = cssm.getUintColorValueFromStyle('cult_lifespan_bar', 'bottomColorLow', 0xac3d2a);
			
			//progress bar
			bar = new ProgressBar(BAR_W, BAR_H);
			bar.x = PADD_SIDE;
			bar.y = 21; // needs to be placed to sit between the tfs
			bar.corner_size = 4;
			bar.setFrameColors(0, 0, .3, .4);
			holder.addChild(bar);
			
			//tfs
			TFUtil.prepTF(name_tf);
			name_tf.width = WIDTH;
			name_tf.y = 1;
			name_tf.alpha = TF_ALPHA;
			holder.addChild(name_tf);
			
			TFUtil.prepTF(life_tf);
			life_tf.width = WIDTH;
			life_tf.y = int(bar.y + bar.height + 1);
			life_tf.alpha = TF_ALPHA;
			holder.addChild(life_tf);
			
			TFUtil.prepTF(nudge_tf);
			nudge_tf.x = 19;
			nudge_tf.y = 1;
			nudge_tf.alpha = TF_ALPHA;
			nudge_tf.htmlText = '<p class="cult_lifespan"><span class="cult_lifespan">click to move</span></p>';
			nudge_tf.width = 70;
			nudge_tf.mouseEnabled = false;
			nudge_holder.addChild(nudge_tf);
			
			update();
			
			nudge_holder.visible = false;
			nudge_holder.useHandCursor = nudge_holder.buttonMode = true;
			holder.addChild(nudge_holder);
			loadNudgeIcon();
			nudge_holder.addEventListener(MouseEvent.CLICK, onNudgeClick, false, 0, true);
			
			showHideNudgeAffordance();
			showHideLifespan();
			draw();
		}
		
		private function draw():void {
			h = (nudge_holder.visible) ? BASE_HEIGHT+24 : BASE_HEIGHT;
			
			if (bar.visible) {
				nudge_holder.y = BASE_HEIGHT;
			} else {
				var diff:int = 31;
				h-= diff;
				nudge_holder.y = BASE_HEIGHT - diff;
			}
				
			holder.y = drop_holder.y = -(h);
			
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
			
			//draw the click target for nudge_holder
			g = nudge_holder.graphics;
			g.clear();
			g.beginFill(0, 0);
			g.drawRect(0, 0, WIDTH-(nudge_holder.x*2), 23);
		}
		
		private function onNudgeClick(e:MouseEvent):void {
			CultManager.instance.startNudging(itemstack);
		}
		
		public function showHideNudgeAffordance():void {
			nudge_holder.visible = TSModelLocator.instance.worldModel.pc.can_nudge_cultivations;
			draw();
		}
		
		public function showHideLifespan():void {
			bar.visible = life_tf.visible = (itemstack && itemstack.itemstack_state.lifespan_config);
			draw();
		}
		
		private function loadNudgeIcon():void {
			var url:String = TSModelLocator.instance.flashVarModel.root_url+'img/skills/nudgery_1.png';
			AssetManager.instance.loadBitmapFromWeb(url, onNudgeIconLoaded, 'Note background');
		}
		
		private function onNudgeIconLoaded(filename:String, bm:Bitmap):void {
			if(bm){
				bm.smoothing = true;
				bm.width = bm.height = 20;
				nudge_holder.addChild(bm);
				nudge_holder.graphics.clear();
				nudge_holder.x = Math.round((WIDTH-nudge_holder.width)/2);
				draw();
			}
			else if(CONFIG::debugging){
				Console.warn('Icon failed for some reason: filename'+filename+'  bitmap:'+bm);
			}
		}
		
		public function update():void {
			var perc:Number;
			var label:String;
			if (!itemstack || !itemstack.itemstack_state.lifespan_config) {
				perc = 0;
				label = itemstack.getLabel();
			} else {
				perc = itemstack.itemstack_state.lifespan_config.percentage_left;
				label = itemstack.getLabel();
			}
			
			//update the text
			if(current_label != label){
				current_label = label;
				name_tf.htmlText = '<p class="cult_lifespan"><span class="cult_lifespan_name">'+current_label+'</span></p>';
			}
			
			if(current_perc != perc){
				current_perc = perc;
				if (itemstack.item.hasTags('trant')) {
					life_tf.htmlText = '<p class="cult_lifespan">Lifespan: 1 tree</p>';
				} else {
					life_tf.htmlText = '<p class="cult_lifespan">'+Math.ceil(perc*100)+'% lifespan remaining</p>';
				}
				
				//update the perc on the bar
				const bar_top:uint = perc <= LOW_PERC ? top_bar_low_color : top_bar_color;
				const bar_bottom:uint = perc <= LOW_PERC ? bottom_bar_low_color : bottom_bar_color;
				bar.setBarColors(bar_top, bar_bottom, bar_top, bar_bottom);
				bar.update(perc);
			}
		}
		
	}
}
