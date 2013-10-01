package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.spritesheet.AnimationSequenceCommand;
	import com.tinyspeck.engine.view.gameoverlay.ArbitrarySWFView;
	
	import flash.display.*;
	
	public class RookScratchDamageView extends TSSpriteWithModel {
		
		private var asv:ArbitrarySWFView;
		public var wh:int;
		
		private var callBack:Function = null;
		public var heal_cnt:int = -1;
		
		public function RookScratchDamageView(wh:int):void {
			super();
			this.wh = wh;
			_construct();
			mouseEnabled = mouseChildren = false;
		}
		
		/*
		animations = ['empty', 'scratchAttack', 'scratchFX', 'scratchFXHeal1', 'scratchFXHeal2', 'scratchFXHeal3', 'scratchFXHeal4', 'peckFX0', 'peckFX1a', 'peckFX1b', 'peckFX1c', 'peckFX1d', 'peckFX2a', 'peckFX2b', 'peckFX2c', 'peckFX2d', 'peckFX2e', 'peckFX2f', 'peckFX2g', 'peckFX2h', 'peckFX3a', 'peckFX3b', 'peckFX3c', 'peckFX3d'];
		*/
		
		override protected function _construct():void {
			
			if (!model.stateModel.overlay_urls['rook_attack_fx_test']) {
				CONFIG::debugging {
					Console.error("model.stateModel.overlay_urls['rook_attack_fx_test'] not exists");
				}
				return;
			}
			
			asv = new ArbitrarySWFView(
				model.stateModel.overlay_urls['rook_attack_fx_test'],
				wh,
				'empty',
				'center',
				false
			);
			
			asv.addEventListener(TSEvent.COMPLETE, onASVload);
			
			addChild(asv);
		}
		
		private function onASVload(e:TSEvent):void {
			dispatchEvent(new TSEvent(TSEvent.COMPLETE));
			if (mc.setConsole) mc.setConsole(null);
			asv.removeEventListener(TSEvent.COMPLETE, onASVload);
		}
		
		public function animate(asc:AnimationSequenceCommand, callBack:Function):void {
			if (this.callBack != null) asv.removeSequenceCompleteCallback(this.callBack);
			
			this.callBack = callBack;
			if (this.callBack != null) asv.addSequenceCompleteCallback(onSequenceComplete, true);
			
			asv.animate({seq:asc.A, loop:asc.loop});
		}
		
		public function onSequenceComplete(asv:ArbitrarySWFView):void {
			if (this.callBack != null) this.callBack(this);
		}
		
		public function get mc():MovieClip {
			return asv.mc;
		}
		
		public function get loaded():Boolean {
			return asv.loaded;
		}

		override public function get r():Number {
			return asv.rotation;
		}

		public function set r(value:Number):void{
			asv.rotation = value;
		}

		
	}
}