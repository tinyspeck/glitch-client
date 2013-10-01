package com.tinyspeck.engine.view.ui.craftybot
{
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.CraftyManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.TextField;

	public class CraftyFooterUI extends Sprite implements ITipProvider
	{
		public static const HEIGHT:uint = 72;
		
		private static const PADD:uint = 10;
		private static const QUEUE_PADD:uint = 4;
		
		private var crystals:Vector.<CraftyCrystal> = new Vector.<CraftyCrystal>();
		private var fuel:CraftyFuel;
		
		private var crystal_holder:Sprite = new Sprite();
		private var queue_holder:Sprite = new Sprite();
		
		private var queue_tf:TextField = new TextField();
		
		private var tip_local_pt:Point = new Point(0, -3);
		private var tip_global_pt:Point;
		
		private var w:int;
		private var queue_bg_color:uint;
		
		private var is_built:Boolean;
		
		public function CraftyFooterUI(w:int){
			this.w = w;
		}
		
		private function buildBase():void {
			//fuel guage
			fuel = new CraftyFuel(w);
			addChild(fuel);		
			
			crystal_holder.y = fuel.height + 8;
			addChild(crystal_holder);
			
			//color the BG
			var g:Graphics = graphics;
			g.beginFill(CSSManager.instance.getUintColorValueFromStyle('crafty_footer', 'backgroundColor', 0x4e595a));
			g.drawRoundRectComplex(0, 0, w, HEIGHT, 0,0, 3,3);
			g.endFill();
			
			//draw a line below the fuel guage
			g.beginFill(0xa6b0b1);
			g.drawRect(0, fuel.height, w, 1);
			
			//queue tf
			TFUtil.prepTF(queue_tf, false);
			queue_tf.x = QUEUE_PADD+2;
			queue_tf.y = QUEUE_PADD-2;
			queue_holder.addChild(queue_tf);
			addChild(queue_holder);
			
			queue_bg_color = CSSManager.instance.getUintColorValueFromStyle('crafty_footer_queue', 'backgroundColor', 0x363e3f);
			
			is_built = true;
		}
		
		public function show():void {
			if(!is_built) buildBase();
			
			fuel.show();
			setCrystals();
			setQueue();
			
			TipDisplayManager.instance.registerTipTrigger(crystal_holder);
		}
		
		public function hide():void {
			fuel.hide();
			TipDisplayManager.instance.unRegisterTipTrigger(crystal_holder);
		}
		
		private function setCrystals():void {
			const cm:CraftyManager = CraftyManager.instance;
			var i:int;
			var total:uint = crystals.length;
			var crystal:CraftyCrystal;
			var next_x:int;
			
			//reset the pool
			for(i = 0; i < total; i++){
				crystals[int(i)].hide();
			}
			
			total = cm.crystal_max;
			for(i = 0; i < total; i++){
				if(i > crystals.length){
					crystal = crystals[int(i)];
				}
				else {
					crystal = new CraftyCrystal();
					crystals.push(crystal);
				}
				
				crystal.show(i % 2 == 1, cm.crystal_count > i);
				crystal.x = next_x;
				next_x += crystal.width + PADD;
				crystal_holder.addChild(crystal);
			}
			
			//center the holder
			crystal_holder.x = int(w/2 - (next_x-PADD)/2);
			
			//draw a background on the holder
			if(next_x){
				var g:Graphics = crystal_holder.graphics;
				g.clear();
				g.beginFill(0,0);
				g.drawRect(0, 0, next_x-PADD, int(crystal.height));
			}
			
			//make sure the tooltip goes in the right spot, fucking masks effin' things up
			tip_local_pt.x = int((next_x-PADD)/2);
		}
		
		private function setQueue():void {
			const cm:CraftyManager = CraftyManager.instance;
			
			var queue_txt:String = '<p class="crafty_footer">';
			queue_txt += '<span class="crafty_footer_queue">Queue Size: </span>';
			queue_txt += cm.jobs_count+'/'+cm.jobs_max;
			queue_txt += '</p>';
			
			queue_tf.htmlText = queue_txt;
			
			//draw the background
			var g:Graphics = queue_holder.graphics;
			g.clear();
			g.beginFill(queue_bg_color);
			g.drawRoundRectComplex(0, 0, int(queue_tf.x*2 + queue_tf.width), int(queue_tf.y*2 + queue_tf.height), 5,5, 0,0);
			queue_holder.x = int(w/2 - queue_holder.width/2);
			queue_holder.y = HEIGHT - queue_holder.height;
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target) return null;
			
			tip_global_pt = crystal_holder.localToGlobal(tip_local_pt);
			
			return {
				txt: 'Crystals affect Craftybot’s capacity',
				placement:tip_global_pt,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
		
		override public function get height():Number { return HEIGHT; }
	}
}