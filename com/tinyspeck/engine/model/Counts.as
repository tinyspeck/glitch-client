package com.tinyspeck.engine.model {
	
	public class Counts {
		CONFIG::debugging public static const net_msg_rsp_counts:Object = {};
		CONFIG::debugging public static const net_msg_evt_counts:Object = {};
		CONFIG::debugging public static const net_msg_req_counts:Object = {};
		
		CONFIG::debugging public static var net_msg_req_count:int = 0;
		CONFIG::debugging public static var net_msg_evt_count:int = 0;
		CONFIG::debugging public static var net_msg_rsp_count:int = 0;
		
		CONFIG::debugging public static function report(str:String = ''):String {
			str+= 'net_msg_evt_count:'+net_msg_evt_count+'\n';
			str+= 'net_msg_req_count:'+net_msg_req_count+'\n';
			str+= 'net_msg_rsp_count:'+net_msg_rsp_count+'\n';
			var k:String;
			
			for (k in net_msg_evt_counts) {
				str+= 'evt '+k+':'+net_msg_evt_counts[k]+'\n';
			}
			
			for (k in net_msg_req_counts) {
				str+= 'req '+k+':'+net_msg_req_counts[k]+'\n';
			}
			
			for (k in net_msg_rsp_counts) {
				str+= 'rsp '+k+':'+net_msg_rsp_counts[k]+'\n';
			}
			
			return str;
		}
	}
}