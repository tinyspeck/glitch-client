package com.tinyspeck.engine.util {
	import flash.utils.ByteArray;
	
	public class MultiPartByteArray extends ByteArray {
		public var boundary:String = '---------------------------7d76d1b56035e';
		
		public function MultiPartByteArray() {
			this.writeMultiByte('--'+this.boundary+'\r\n', "ascii");
		}
		
		public function addFile(var_name:String, file_name:String, file_data:ByteArray):void {
			var header:String = 'Content-Disposition: form-data; name="'+var_name+'"; filename="'+file_name+'"\r\n'
				+'Content-Type: application/octet-stream\r\n\r\n';
			
			this.writeMultiByte(header, "ascii");
			this.writeBytes(file_data);
			this.writeMultiByte('\r\n--'+this.boundary+'\r\n', "ascii");
		}
		
		public function addVar(var_name:String, var_string:String):void {
			var header:String = 'Content-Disposition: form-data; name="'+var_name+'"\r\n\r\n'
				+var_string+'\r\n'
				+'--'+this.boundary+'\r\n';
			
			this.writeMultiByte(header, "utf-8");
		}
	}
}
