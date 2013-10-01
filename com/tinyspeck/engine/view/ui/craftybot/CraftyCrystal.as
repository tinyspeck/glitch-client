package com.tinyspeck.engine.view.ui.craftybot
{
	import com.tinyspeck.engine.port.AssetManager;
	
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;

	public class CraftyCrystal extends Sprite
	{
		private static const STATE_FULL1:uint = 0;
		private static const STATE_FULL2:uint = 1;
		private static const STATE_EMPTY1:uint = 2;
		private static const STATE_EMPTY2:uint = 3;
		private static const CRYSTAL_W:uint = 17;
		private static const CRYSTAL_H:uint = 20;
		private static const GAP_W:uint = 10; //space between crystal spritesheet
		
		private var holder:Sprite = new Sprite();
		private var holder_mask:Shape = new Shape();
		
		private var is_built:Boolean;
		
		public function CraftyCrystal(){}
		
		private function buildBase():void {
			//load the crystals into the holder and mask the holder
			holder.addChild(new AssetManager.instance.assets.crafty_crystal());
			holder.mask = holder_mask;
			addChild(holder);
			
			const g:Graphics = holder_mask.graphics;
			g.beginFill(0);
			g.drawRect(0, 0, CRYSTAL_W, CRYSTAL_H);
			addChild(holder_mask);
			
			is_built = true;	
		}
		
		public function show(use_alt_state:Boolean, is_full:Boolean):void {
			if(!is_built) buildBase();
			
			//move the holder where it needs to go
			var offset:uint = STATE_FULL1;			
			if(is_full && use_alt_state){
				offset = STATE_FULL2;
			}
			else if(!is_full && !use_alt_state){
				offset = STATE_EMPTY1;
			}
			else if(!is_full && use_alt_state){
				offset = STATE_EMPTY2;
			}
			
			holder.x = -(offset*(CRYSTAL_W+GAP_W));
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
		}
		
		override public function get width():Number { return CRYSTAL_W;	}
		override public function get height():Number { return CRYSTAL_H; }
	}
}