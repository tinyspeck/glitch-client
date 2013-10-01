//
// (BSD License) 100% Open Source see http://en.wikipedia.org/wiki/BSD_licenses
//
// Copyright (c) 2009, Martin Heidegger
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of the Martin Heidegger nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

package at.leichtgewicht.draw 
{
	import flash.display.Graphics;
	import flash.geom.Point;
	
	/**
	 * Util to draw bezier curves for a circle.
	 * 
	 * @author Martin Heidegger
	 * @version 1.0
	 */
	public class BezierCurve 
	{
		// Interal helper for a zero offset ( default value )
		private static const ZERO_OFFSET: Point = new Point( 0, 0 );
		
		/**
		 * Draws a bezier curve in a given graphics object.
		 * 
		 * @param graphics <code>Graphics</code> object to draw into.
		 * @param radius radius of the curve
		 * @param size size of the curve from 0(no curve) to 2*Math.PI(full circle)
		 * @param startAngle start angle of the curve in rad from 0 to 2*Math.PI
		 * @param accuracy accuracy of the curve
		 * @param offset offset of the bezier curve as point
		 * @param clockWise true if the curve should be drawed clock-wise, else false
		 */
		public static function draw( graphics: Graphics, radius: Number, size: Number, startAngle: Number, accuracy: int, offset: Point = null, clockWise: Boolean = true ): void
		{
			if( null == offset )
			{
				offset = ZERO_OFFSET;
			}
			
			if( !clockWise )
			{
				size = 0-size;
				startAngle = startAngle-size;
			}
			
			var span: Number = size / 2 / accuracy;
			var controlRadius: Number = radius / Math.cos( span );
			
			var controlAngle: Number = startAngle;
			var anchorAngle: Number = controlAngle;
			
			for( var i: int = 0; i < accuracy; ++i )
			{
				controlAngle = anchorAngle + span;
				anchorAngle += span * 2;
				graphics.curveTo( offset.x + Math.cos( controlAngle ) * controlRadius, offset.y + Math.sin( controlAngle ) * controlRadius, offset.x + Math.cos( anchorAngle ) * radius, offset.y + Math.sin( anchorAngle ) * radius );
			}
		}
	}
}
