package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Point;

	public class AvatarFaceUI extends Sprite implements ITipProvider
	{
		public static const RADIUS:uint = 20;
		
		private const holder:Sprite = new Sprite();
		private const masker:Sprite = new Sprite();
		private const spinner_holder:Sprite = new Sprite();
		
		private const local_pt:Point = new Point(RADIUS, -3); //-3 gives a little breathing room
		
		private var global_pt:Point = new Point();
		
		private var current_tsid:String;
		
		private var is_built:Boolean;
		
		public function AvatarFaceUI(pc_tsid:String = ''){
			if(pc_tsid) show(pc_tsid);
		}
		
		private function buildBase():void {
			const bg_color:uint = CSSManager.instance.getUintColorValueFromStyle('avatar_face', 'backgroundColor', 0xe5ebeb);
			
			setBackground(bg_color);
			holder.mask = masker;
			
			var g:Graphics = masker.graphics;
			g.beginFill(0);
			g.drawCircle(RADIUS, RADIUS, RADIUS);
			
			addChild(holder);
			addChild(masker);
			
			//spinner
			const spinner:DisplayObject = new AssetManager.instance.assets.spinner();
			spinner.scaleX = spinner.scaleY = .8;
			spinner_holder.addChild(spinner);
			spinner_holder.x = 4.5;
			spinner_holder.y = 4.5;
			
			is_built = true;
		}
		
		public function show(pc_tsid:String, show_tooltip:Boolean = false):void {
			if(!is_built) buildBase();
			addChild(spinner_holder);
			
			current_tsid = pc_tsid;
			if(show_tooltip) TipDisplayManager.instance.registerTipTrigger(this);
			
			const pc:PC = TSModelLocator.instance.worldModel.getPCByTsid(pc_tsid);
			if(pc && pc.singles_url){
				//same image? bail out
				if(holder.name == pc.singles_url) {
					if(holder.numChildren) removeChild(spinner_holder);
					return;
				}
				
				while(holder.numChildren) holder.removeChildAt(0);
				holder.name = pc.singles_url;
				AssetManager.instance.loadBitmapFromWeb(pc.singles_url+'_50.png', onHeadshotLoad, 'Avatar Face UI');
			}
		}
		
		public function hide():void {
			if(parent) {
				parent.removeChild(this);
				TipDisplayManager.instance.unRegisterTipTrigger(this);
			}
		}
		
		private function onHeadshotLoad(filename:String, bm:Bitmap):void {
			//clean it one more time for race condition fun times			
			while(holder.numChildren) holder.removeChildAt(0);
			if(bm){
				bm.scaleX = -1;
				bm.x = bm.width - 11;
				bm.y = -8;
				holder.addChild(bm);
			}
			else {
				CONFIG::debugging {
					Console.warn('no bitmap?:'+bm+' filename: '+filename+' holder name: '+holder.name);
				}
			}
			
			if(contains(spinner_holder)) removeChild(spinner_holder);
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target || !current_tsid) return null;
			const pc:PC = TSModelLocator.instance.worldModel.getPCByTsid(current_tsid);
			if(pc && masker.hitTestPoint(StageBeacon.stage.mouseX, StageBeacon.stage.mouseY)){
				//where this at?
				global_pt = localToGlobal(local_pt);
				return {
					txt: pc.label,
					placement: global_pt,
					pointer: WindowBorder.POINTER_BOTTOM_CENTER
				}
			}
			return null;
		}
		
		public function setBackground(bg_color:uint, bg_alpha:Number = 1):void {
			var g:Graphics = holder.graphics;
			g.clear();
			g.beginFill(bg_color, bg_alpha);
			g.drawCircle(RADIUS, RADIUS, RADIUS);
		}
		
		override public function get width():Number {
			return RADIUS*2;
		}
		
		override public function get height():Number {
			return RADIUS*2;
		}
	}
}