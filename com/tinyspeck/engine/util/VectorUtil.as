package com.tinyspeck.engine.util
{
	public class VectorUtil
	{
		public static function shuffle(vector:Object):void {
		    for (var i:String in vector) {
				swap(vector, int(i), MathUtil.randomInt(int(i), vector.length-1));
			}
		}
		
		private static function swap(vector:Object, a:uint, b:uint):void {
		    var temp:Object = vector[a];
		    vector[a] = vector[b];
		    vector[b] = temp;
		}
		
		// really for an Array, but I am sticking it in here for now! Would work with Vectors without out too much work
		public static function unique(A:Array):Array {
			var r:Array = [];
			o:for(var i:int = 0, n:int = A.length; i < n; i++) {
				for(var x:int = 0, y:int = r.length; x < y; x++)  {
					if(r[int(x)]==A[int(i)]) continue o;
				}
				r[r.length] = A[int(i)];
			}
			return r;
		}
	}
}