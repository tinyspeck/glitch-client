/**
* EdgeFinder by Sakri Rosenstrom & Mario Klingemann. 
* Feb 18, 2009
*  
* http://www.sakri.net
* http://www.quasimondo.com
* 
* Copyright (c) 2009 Mario Klingemann, Sakri Rosenstrom
* 
* Permission is hereby granted, free of charge, to any person
* obtaining a copy of this software and associated documentation
* files (the "Software"), to deal in the Software without
* restriction, including without limitation the rights to use,
* copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the
* Software is furnished to do so, subject to the following
* conditions:
* 
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
* OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
* HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
* OTHER DEALINGS IN THE SOFTWARE.
**/

package com.quasimondo.BitmapData
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class EdgeFinder
	{
		
		public static function getFirstNonTransparentPixel( bmd:BitmapData ):Point
		{
			var hit_rect:Rectangle=new Rectangle(0,0,bmd.width,1);
			var p:Point = new Point();
			for( hit_rect.y = 0; hit_rect.y < bmd.height; hit_rect.y++ )
			{
				if( bmd.hitTest( p, 0x01, hit_rect) )
				{
					var hit_bmd:BitmapData=new BitmapData( bmd.width, 1, true, 0 );
					hit_bmd.copyPixels( bmd, hit_rect, p );
					return hit_rect.topLeft.add( hit_bmd.getColorBoundsRect(0xFF000000, 0, false).topLeft );
				}
			}
			return null;
		}
	}
}