package com.tinyspeck.engine.view.ui.map {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	
	public class GpsArrow extends Sprite implements ITipProvider {		
		private static const RADIUS:Number = 13;
		
		private var gps_assets:MovieClip;
		private var arrow:MovieClip;
		
		private var arrow_holder:Sprite = new Sprite();
		private var complete_holder:Sprite = new Sprite();
		
		private var is_built:Boolean;
		
		public function GpsArrow() {}
		
		private function build():void {		
			buttonMode = useHandCursor = true;
			mouseChildren = false;
			
			gps_assets = new AssetManager.instance.assets.gps_assets();
			gps_assets.addEventListener(Event.COMPLETE, onLoaded, false, 0, true);
			
			const bg_matrix:Matrix = new Matrix();
			bg_matrix.createGradientBox(
				RADIUS*2, 
				RADIUS*2, 
				Math.PI/2,
				0, 
				-RADIUS/2
			);
			
			var g:Graphics = arrow_holder.graphics;
			g.beginGradientFill(GradientType.LINEAR, [0xfafbfb,0xd3dde0], [1,1], [0,255], bg_matrix);
			g.drawCircle(0,0, RADIUS);
			arrow_holder.visible = false;
			addChild(arrow_holder);
			
			arrow_holder.filters = StaticFilters.copyFilterArrayFromObject({color:0x90b8ba}, StaticFilters.black_GlowA);
			
			g = complete_holder.graphics;
			g.beginFill(TSModelLocator.instance.layoutModel.bg_color);
			g.drawCircle(0,0, RADIUS);
			complete_holder.visible = false;
			addChild(complete_holder);
			
			complete_holder.filters = StaticFilters.copyFilterArrayFromObject({color:0x88a407}, StaticFilters.black_GlowA);
			
			is_built = true;
		}
		
		public function show():void {
			if (!is_built) build();
			TipDisplayManager.instance.registerTipTrigger(this);
		}
		
		public function hide():void {
			if (parent) parent.removeChild(this);
			TipDisplayManager.instance.unRegisterTipTrigger(this);
		}
		
		public function showState(is_hover:Boolean, is_complete:Boolean = false, is_close:Boolean = false):void {
			if(arrow) {
				var label:String = is_hover ? 'over' : 'out';
				if(is_close) label = 'close';
				if(is_complete) label = 'complete';
				arrow_holder.visible = !is_complete;
				complete_holder.visible = is_complete;
				arrow.gotoAndStop(label);
				arrow.visible = true;
			}
			else {
				//try again real soon
				StageBeacon.setTimeout(showState, 300, is_hover, is_complete);
			}
		}
		
		private function onLoaded(event:Event):void {
			gps_assets = Loader(event.target.getChildAt(0)).content as MovieClip;
			
			arrow = gps_assets ? gps_assets.getAssetByName('arrow') : null;
			if(arrow) {
				arrow.visible = false;
				addChild(arrow);
			}
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target || complete_holder.visible) return null;
			return {
				txt: 'Click to be auto-walked',
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
		
		override public function set rotation(value:Number):void {
			//we only want the arrow to rotate
			if(arrow) {
				arrow.rotation = value;
			}
			else {
				StageBeacon.waitForNextFrame(function():void {
					//arrow hasn't loaded yet, try again real fast
					rotation = value;
				});
			}
		}
		
		override public function get width():Number {
			return RADIUS*2;
		}
	}
}