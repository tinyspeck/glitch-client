package com.tinyspeck.engine.loader
{
import com.tinyspeck.debug.BootError;

import flash.display.Bitmap;
import flash.events.Event;

public class SmartWebBitmapLoader extends SmartLoader
{
	//private static const TL_RECT:Rectangle = new Rectangle(0,0,1,1);
	//private static const TL_POINT:Point = new Point(0,0);
	//private static const TEST_BMD:BitmapData = new BitmapData(1, 1);
	
	public function SmartWebBitmapLoader(name:String) {
		super(name);
	}
	
	override protected function onComplete(event:Event):void {
		var bm:Bitmap;
		
		// here maybe add checking to make sure we can copyPixels from the bmd before proceeding?
		var bmd_broken:Boolean = false;
		var bmd_broken_bcz:String = '';
		
		if (!loader.contentLoaderInfo.childAllowsParent) {
			bmd_broken_bcz+= ' (!loader.contentLoaderInfo.childAllowsParent)';
			bmd_broken = true;
		}
		
		// enable to fake a failure
		//if (retries == 0) {
		//	bmd_broken_bcz+= ' (faking failure)';
		//	bmd_broken = true;
		//}
		
		try {
			bm = Bitmap(loader.content);
		} catch (err:Error) {
			bmd_broken_bcz+= ' could not cast loader.content to Bitmap '+err;
			bmd_broken = true;
		}
		
		if (bm) {
			try {
				bm.bitmapData.getPixel(0, 0);
			} catch (err:Error) {
				BootError.handleError('SWBL.onComplete getPixel test failed, but reloading '+urlRequest.url, err, ['loader'], !CONFIG::god, false);
				bmd_broken_bcz+= ' could not do bm.bitmapData.getPixel(0, 0) '+err;
				bmd_broken = true;
			}
		}
		
		if (bm) {
			try {
				if (bm.width == 1 && bm.height == 1 && !retries) {
					bmd_broken_bcz+= ' we never expect to get a 1x1 bm, so lets try cache bust reloading once (only if !retries)';
					bmd_broken = true;
				}
			} catch (err:Error) {
				BootError.handleError('SWBL.onComplete dimension test failed, but reloading '+urlRequest.url, err, ['loader'], !CONFIG::god, false);
				bmd_broken_bcz+= ' could not access bm.height or bm.width '+err;
				bmd_broken = true;
			}
		}
		
		// disabled: this will succeed if getPixel succeeds
		//if (bm && !bmd_broken) {
		//	try {
		//		TEST_BMD.copyPixels(bm.bitmapData, TL_RECT, TL_POINT);
		//	} catch (err:Error) {
		//		BootError.handleError('SWBL.onComplete copyPixels test failed, but reloading '+urlRequest.url, err, ['loader'], !CONFIG::god, false);
		//		bmd_broken_bcz+= ' could not do test_bmd.copyPixels(bm.bitmapData, new Rectangle(0,0,1,1), new Point(0,0)) '+err;
		//		bmd_broken = true;
		//	}
		//}
		
		// disabled: this creates a lot of garbage and should only fail if the memory cannot be allocated
		//if (bm && !bmd_broken) {
		//	try {
		//		bm.bitmapData.clone();
		//	} catch (err:Error) {
		//		BootError.handleError('SWBL.onComplete clone test failed, but reloading '+urlRequest.url, err, ['loader'], !CONFIG::god, false);
		//		bmd_broken_bcz+= ' could not do bm.bitmapData.clone() '+err;
		//		bmd_broken = true;
		//	}
		//}
		
		if (bmd_broken) {
			maybeRetry(new Event(bmd_broken_bcz));
			return;
		} else {
			var dims:String;
			try {
				dims = bm.width+'x'+bm.height;
			} catch (err:Error) {
				dims = 'could not access bm props '+err;
			}
			
			dims = '['+dims+']';
			
			log(dims);
		}
		
		super.onComplete(event);
	}
}
}