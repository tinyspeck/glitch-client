package com.tinyspeck.engine.view.renderer
{
	import com.tinyspeck.engine.util.StringUtil;
	
	/**
	 * A RenderMode represents a way to render a Location (and possibly more
	 * in the future).  The layers of a location (decos) are built based upon the
	 * render mode being used.
	 */ 
	public class RenderMode {
		public static const VECTOR:RenderMode = new RenderMode("Vector", false);
		public static const BITMAP:RenderMode = new RenderMode("Bitmap", true);
		
		private var _name:String;
		private var _usesBitmaps:Boolean;
		private var _bitmapSegmentDimension:uint;
		
		public function RenderMode(name:String, usesBitmaps:Boolean, bitmapSegmentDimension:uint = 0, usesStage3D:Boolean = false, contextRenderMode:String = "auto") {
			_name = name;
			_usesBitmaps = usesBitmaps;
			_bitmapSegmentDimension = bitmapSegmentDimension;
		}
		
		public static function getRenderModeByName(name:String):RenderMode {
			switch (StringUtil.capitalizeFirstLetter(name.toLowerCase())) {
				case VECTOR.name: return VECTOR;
				case BITMAP.name: return BITMAP;
				default: return null;
			}
			return null;
		}
		
		public function get name():String {
			return _name;
		}

		public function get usesBitmaps():Boolean {
			return _usesBitmaps;
		}
		
		public function get bitmapSegmentDimension():uint {
			return _bitmapSegmentDimension;
		}		
	}
}