package com.tinyspeck.engine.view.renderer.commands
{
	import com.tinyspeck.engine.data.location.Layer;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.view.AvatarView;
	import com.tinyspeck.engine.view.renderer.DecoRenderer;
	import com.tinyspeck.engine.view.renderer.LargeBitmap;
	import com.tinyspeck.engine.view.renderer.LayerRenderer;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.renderer.RenderMode;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;

	public class LocationCommands
	{		
		private static const drawDecoInLargeBitmapCmd:DrawDecoInLargeBitmapCmd = new DrawDecoInLargeBitmapCmd();
		
		public static function buildLocationView(location:Location, avatarView:AvatarView, pc:PC,  
									locationRenderer:LocationRenderer, controlPointHolder:Sprite):void {
			new BuildLocationViewCmd(location, avatarView, pc, locationRenderer, controlPointHolder).execute();
		}
		
		public static function prepareLayerRenderer(layerRenderer:LayerRenderer):void {
			new PrepareLayerRendererCmd(layerRenderer).execute();
		}
		
		public static function applyFiltersToView(layer:Layer, view:DisplayObject, disableHighlighting:Boolean = false):void {
			new ApplyLayerFiltersToViewCmd(layer, view, disableHighlighting).execute();
		}
		
		public static function setupRenderMode():void {
			new SetupRenderModeCmd().execute();
		}
		
		public static function changeRenderMode(newRenderMode:RenderMode):void {
			new ChangeRenderModeCmd(newRenderMode).execute();
		}
		
		/** Rebuild the location using a fancy load screen */
		public static function rebuildLocation():void {
			new RebuildLocationCmd().execute();
		}
		
		/** Rebuilds layers without a fancy load screen */
		public static function rebuildLayersQuickly(layers:Vector.<Layer>, locationRenderer:LocationRenderer):void {
			new RebuildLocationViewLayersCmd(layers, locationRenderer).execute();
		}
		
		public static function fallBackRenderMode(forceRenderMode:RenderMode = null):void {
			new FallbackRenderModeCmd(forceRenderMode).execute();
		}
		
		public static function drawDecoInLargeBitmap(decoRenderer:DecoRenderer, largeBitmap:LargeBitmap, useMiddleGroundOffsets:Boolean):void {
			drawDecoInLargeBitmapCmd.decoRenderer = decoRenderer;
			drawDecoInLargeBitmapCmd.largeBitmap = largeBitmap;
			drawDecoInLargeBitmapCmd.useMiddleGroundOffsets = useMiddleGroundOffsets;
			drawDecoInLargeBitmapCmd.execute();
		}
		
		public static function addAvatarView(locationRenderer:LocationRenderer):void {
			new AddAvatarViewCmd(locationRenderer).execute();
		}
	}
}