package com.tinyspeck.engine.spritesheet {
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;

	final public class SSFrame {
		internal var sourceRectangle:Rectangle;
		
		/** @private */
		public var originalBounds:Rectangle;

		internal var _bmd_index:int  = -1;
		internal var int_target_bmd_index:int = -1;
		
		internal var _number:int;
		internal var _name:String;
		internal var _spriteSheet:SSAbstractSheet;
		internal var interaction_target:DisplayObject;
		internal var has_bmd:Boolean;
		internal var has_temp_bmd:Boolean = false;
				
		public function SSFrame(spriteSheet:SSAbstractSheet, name:String, int_target:DisplayObject = null) {
			_spriteSheet = spriteSheet;
			_name = name;
			interaction_target = int_target;
		}
		

		public function get bmd_index():int {
			return _bmd_index;
		}

		internal function dispose():void {
			//Console.info(_name+' '+bmd_index);
						
			// we must null out the bitmaps used for this SSFrame. This works because we do not actually delete from the array
			if (_spriteSheet is SSMultiBitmapSheet) {
				var ssmbs:SSMultiBitmapSheet = _spriteSheet as SSMultiBitmapSheet;
				if (ssmbs.bmds && _bmd_index > -1 && _bmd_index < ssmbs.bmds.length) {
					if (ssmbs.bmds[_bmd_index]) {
						if (!has_temp_bmd) ssmbs.bmds[_bmd_index].dispose();
						ssmbs.bmds[_bmd_index] = null;
					}
				}
			}
			
			if (_spriteSheet.intTargetBitmaps && int_target_bmd_index > -1 && int_target_bmd_index < _spriteSheet.intTargetBitmaps.length) {
				if (_spriteSheet.intTargetBitmaps[int_target_bmd_index]) {
					if (!has_temp_bmd) _spriteSheet.intTargetBitmaps[int_target_bmd_index].dispose();
					_spriteSheet.intTargetBitmaps[int_target_bmd_index] = null;
				}
			}
			
			

			_number = 0;
			_name = null;
			_spriteSheet = null;
			interaction_target = null;
			_bmd_index = -1;
			int_target_bmd_index = -1;
		}
	}
}