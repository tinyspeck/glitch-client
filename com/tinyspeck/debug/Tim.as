package com.tinyspeck.debug {
	import com.tinyspeck.engine.util.EnvironmentUtil;
	
	import flash.utils.getTimer;
	
	public class Tim {
		
		public function Tim() {
		 	//	
		}
		
		public static var reports:Array = [];
		private static var m:Object;
		private static var oks:Array;
		
		public static function init():void {
			m = {};
			oks = EnvironmentUtil.getUrlArgValue('tims').split(',');
		}
		
		public static function wIsOk(w:String):Boolean {
			if (w == 'all') return true;
			if (oks && oks.indexOf(w) > -1) return true;
			return false;
		}
		
		public static function stamp(pw:*, str:String):void {
			if (!m) init();
			
			var w:String = String(pw) || 'all';
			
			if (!wIsOk(w)) return;
			
			if (!m[w]) {
				m[w] = {
					t: [],
					s: []
				}
			}
			
			m[w].t.push(getTimer());
			m[w].s.push(str);
		}
		
		public static function report(pw:*, title:String, full:Boolean = true):void {
			if (!m) init();
			
			var w:String = String(pw) || 'all';
			
			if (!m[w]) return;
			
			var t:Array = m[w].t;
			var s:Array = m[w].s;
			
			if (!t.length) {
				CONFIG::debugging {
					Console.warn('Could not report');
				}
				return;
			}
			
			reports.push('\n'+line+'\n'+buildReport(title, w, full));
			CONFIG::debugging {
				Console.priinfo(222, reports[reports.length-1]);
			}
			Benchmark.addCheck('TIM REPORT: '+buildReport(title, w, false));
			
			t.length = 0;
			s.length = 0;
			
		}
		
		public static function format(ms:int):String {
			return (ms/1000).toFixed(3);
		}
		
		
		private static var running_total:Number = 0;
		private static var line:String = '----------------------------------------';
		private static function buildReport(title:String, w:String, full:Boolean = true):String {
			
			var t:Array = m[w].t;
			var s:Array = m[w].s;
			
			var total:int = t[t.length-1]-t[0];
			running_total+= total;
			var str:String = w+' '+title+' '+format(total)+' secs '+(full?'TOTAL ':'')+'('+format(total/(t.length-1))+' avg) running_total:'+format(running_total);
			
			if (full) {
				str+= '\n'+line
				for (var i:int;i<t.length;i++) {
					str+= '\n';
					if (i) {
						str+= format(t[int(i)]-t[i-1])+' for '+s[int(i)];
					} else {
						str+= format(0)+' '+s[int(i)];
					}
				}
			}
			
			return str;
		}
	}
}