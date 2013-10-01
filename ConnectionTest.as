/*
The SWF will load, init the external interface, and then wait for a call to test_connection.
JS should pass a host, port, and token ('connection_test').
JS then waits for callbacks reporting results.

JS will call:
test_connection(host, port, token)                       : test connection to GS
test_lso ('http://www.glitch.com/crossdomain.xml')       : reports whether local shared objects work (test with SWF_fake_bad_lso=1)
test_crossdomain (url)                                   : reports whether we can load the glitch.com crossdomain (test with SWF_fake_bad_crossdomain=1)

SWF will call (in order):
external_interface_result ({ok})                         : called when the SWF establishes a connection to the JS (there should be a JS timeout if this doesn't occur)
socket_policy_result ({waiting,testing,ok,failed,error}) : reports whether we can load the socket policy file (test with SWF_fake_bad_socket_policy=1)
connection_result ({waiting,testing,ok,failed,error})    : reports whether we could establish a socket connection to the GS (test with SWF_fake_bad_connection=1)
login_result ({waiting,testing,ok,failed,error})         : reports whether we could log in to the GS (test with SWF_fake_bad_login=1)
lso_result ({waiting,testing,ok,failed})                 : reports whether local shared objects work (test with SWF_fake_bad_lso=1)
crossdomain_result ({waiting,testing,ok,failed,error})   : reports whether we can load the glitch.com crossdomain (test with SWF_fake_bad_crossdomain=1)

On an unexpected error, SWF will call:
connection_swf_error(desc) : reports runtime errors from the SWF and suppresses Flash dialog

To test firewall port blocking:
>: sudo ipfw add unreach port tcp from any to any 543
>: sudo ipfw delete 100
*/
package {
	import com.tinyspeck.engine.model.TSEngineConstants;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.URLUtil;
	
	import flash.display.Sprite;
	import flash.errors.EOFError;
	import flash.errors.IOError;
	import flash.events.ContextMenuEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TextEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	import flash.net.Socket;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.Security;
	import flash.text.AntiAliasType;
	import flash.text.Font;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.getQualifiedClassName;
	
	[SWF(width="216", height="160", backgroundColor="#FFFFFF", frameRate="30")]
	public class ConnectionTest extends Sprite {
		[Embed(source="assets/VAGRoundedBold.ttf", fontName="BootEmbed", mimeType="application/x-font-truetype", unicodeRange="U+0020-U+007E")]
		public static const BootEmbed:Class;
		
		private static const CSS:String =
			"p       { font-size:16px; color:#383F41; font-family:BootEmbed; }" +
			"a:link  { color:#00a8d2; }" +
			"a:hover { color:#d79035; }" +
			".header { font-size:26px;}" +
			".black  { color:#000000; }" +
			".gray   { color:#383F41; }" +
			".purple { color:#333366; }" +
			".green  { color:#79BD55; }" +
			".yellow { color:#ECBE1F; }" +
			".red    { color:#CB202E; }";

		// status codes
		private static const WAITING:String = 'waiting';
		private static const TESTING:String = 'testing';
		private static const OK:String      = 'ok';
		private static const FAILED:String  = 'failed';
		private static const ERROR:String   = 'error';
		
		// status
		private static const msg_tf:TextField = new TextField();
		private static var _external_interface_status:String;
		private static var _javascript_status:String;
		private static var _lso_status:String;
		private static var _crossdomain_status:String;
		private static var _socket_policy_status:String;
		private static var _connection_status:String;
		private static var _login_status:String;

		// connection testing
		private static var netSocket:Socket;
		private static var expectedMessageSize:Number = NaN;
		private static var socketConnectionAttempts:int;
		private static var token:String;
		private static var host:String;
		private static var port:int;
		
		public function ConnectionTest() {
			stage.frameRate = TSEngineConstants.TARGET_FRAMERATE;
			
			const menu:ContextMenu = new ContextMenu();
			menu.hideBuiltInItems();
			menu.customItems.push(new ContextMenuItem('A connection tester by Tiny Speck', true, true));
			menu.customItems[0].addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function():void{
				navigateToURL(new URLRequest('http://www.tinyspeck.com/'), '_blank');
			});
			contextMenu = menu;
			
			loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onGlobalError);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			// disable yellow tabbing rectangle
			stage.stageFocusRect = false;
			
			// disable tabbing altogether
			stage.tabChildren = false;
			
			initTF();
			
			Security.allowDomain('*');
			Security.allowInsecureDomain('*');
			
			crossdomain_status = WAITING;
			lso_status = WAITING;
			external_interface_status = WAITING;
			reset_connection_test();
			test_external_interface();
			//test_connection('dev-gs1.us-east.ec2.tinyspeck.com', 543, 'connection_test');
		}
		
		protected function onEnterFrame(event:Event):void {
			var html:String = '<p>';
			html += styleText(styleText('Connection Tester<br/>', 'purple'), 'header');
			html += 'external_interface: ' + getStyledStatus(external_interface_status) + '<br/>';
			html += 'javascript: ' + getStyledStatus(javascript_status) + '<br/>';
			html += 'local_shared_object: ' + getStyledStatus(lso_status) + '<br/>';
			html += 'crossdomain: ' + getStyledStatus(crossdomain_status) + '<br/>';
			html += 'socket_policy: ' + getStyledStatus(socket_policy_status) + '<br/>';
			html += 'connection' + (port ? ' ' + port + ')' : '') + ': ' + getStyledStatus(connection_status) + '<br/>';
			html += 'login: ' + getStyledStatus(login_status) + '<br/>';
			html += '</p>';
			msg_tf.htmlText = html;
		}
		
		private static function getStyledStatus(status:String):String {
			switch (status) {
				case WAITING: return styleText('waiting...', 'black');
				case TESTING: return styleText('testing...', 'yellow');
				case OK:      return styleText('ok',         'green');
				case FAILED:  return styleText('failed',     'red');
				case ERROR:   return styleText('error',      'red');
			}
			return null;
		}
		
		private static function reset_connection_test():void {
			socketConnectionAttempts = 0;
			socket_policy_status = WAITING;
			connection_status = WAITING;
			login_status = WAITING;
		}
		
		public static function test_external_interface():void {
			external_interface_status = TESTING;
			javascript_status = WAITING;
			if (!ExternalInterface.available || (EnvironmentUtil.getUrlArgValue('SWF_fake_bad_external_interface') == '1')) {
				external_interface_status = FAILED;
				// do nothing
			} else {
				ExternalInterface.addCallback('test_connection', function(params:Object):void {
					ConnectionTest.test_connection(params.host, params.port, params.token);
				});
				ExternalInterface.addCallback('test_lso', function():void {
					ConnectionTest.test_lso();
				});
				ExternalInterface.addCallback('test_crossdomain', function(url:String):void {
					ConnectionTest.test_crossdomain(url);
				});
				javascript_status = TESTING;
				external_interface_status = OK;
			}
		}
		
		public static function test_connection(host:String, port:int, token:String):void {
			javascript_status = OK;
			
			reset_connection_test();
			
			connection_status = TESTING;
			ConnectionTest.host = host;
			ConnectionTest.port = port;
			ConnectionTest.token = token;
			
			if (EnvironmentUtil.getUrlArgValue('SWF_fake_bad_connection') == '1') {
				ConnectionTest.host = 'fourohfour.glitch.com';
			}
				
			if (EnvironmentUtil.getUrlArgValue('SWF_fake_bad_login') == '1') {
				ConnectionTest.token = 'bad_token';
			}

			if (netSocket) {
				removeSocketListeners();
				netSocket = null;
			}
			
			netSocket = new Socket();
			netSocket.objectEncoding = ObjectEncoding.AMF3;
			netSocket.timeout = 10000;
			netSocket.addEventListener(Event.CONNECT, onSocketConnect);
			netSocket.addEventListener(IOErrorEvent.IO_ERROR, onSocketError);
			netSocket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSocketError);
			netSocket.addEventListener(Event.CLOSE, onSocketClose);
			netSocket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
			
			actually_test_connection();
		}
		
		public static function test_crossdomain(url:String):void {
			crossdomain_status = TESTING;
			if (EnvironmentUtil.getUrlArgValue('SWF_fake_bad_crossdomain') == '1') {
				crossdomain_status = FAILED;
			} else {
				try {
					Security.loadPolicyFile(url);
					crossdomain_status = OK;
				} catch (e:Error) {
					crossdomain_status = ERROR;
				}
			}
		}
		
		public static function test_lso():void {
			lso_status = TESTING;
			try {
				if (EnvironmentUtil.getUrlArgValue('SWF_fake_bad_lso') == '1') {
					lso_status = FAILED;
				} else {
					SharedObject.getLocal('TS_DATA', '/');
					lso_status = OK;
				}
			} catch (e:Error) {
				lso_status = FAILED;
				reportError(e);
			}
		}
		
		public static function actually_test_connection():void {
			socketConnectionAttempts++;
			
			if (socketConnectionAttempts == 1) {
				netSocket.timeout = 10000;
			} else {
				// wait less time the second attempt
				netSocket.timeout = 5000;
			}

			// test policy file
			socket_policy_status = TESTING;
			if (EnvironmentUtil.getUrlArgValue('SWF_fake_bad_socket_policy') == '1') {
				socket_policy_status = FAILED;
			} else {
				try {
					Security.loadPolicyFile('xmlsocket://' + host + ':843');
					socket_policy_status = OK;
				} catch (e:Error) {
					socket_policy_status = ERROR;
					reportError(e);
				}
			}
			
			netSocket.connect(host, port);
		}

		private static function onSocketError(event:ErrorEvent):void {
			if (socketConnectionAttempts < 2) {
				// try again
				actually_test_connection();
			} else {
				removeSocketListeners();
				connection_status = FAILED;
				login_status = FAILED;
			}
		}
		
		private static function onSocketConnect(event:Event):void {
			connection_status = OK;
			login_status = TESTING;
			
			try {
				netSocket.writeObject({
					type: 'login_start',
					msg_id: '1',
					token: token,
					garbage_file: '12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890'
				});
				netSocket.flush();
			} catch(e:Error) {
				login_status = ERROR;
				reportError(e);
			}
		}
		
		private static function onSocketData(event:ProgressEvent):void {
			if (!netSocket.connected) {
				login_status = ERROR;
				return;
			}

			// not enough bytes for the header
			if (netSocket.bytesAvailable < 4) {
				// keep waiting
				return;
			}
			
			if (isNaN(expectedMessageSize)) {
				try {
					expectedMessageSize = netSocket.readInt();
				} catch (eof:EOFError) {
					login_status = ERROR;
					return;
				} catch (ioe:IOError) {
					login_status = ERROR;
					return;
				} catch (e:Error) {
					login_status = ERROR;
					return;
				}
			}
			
			if (expectedMessageSize == 0) {
				login_status = ERROR;
				return;
			}
			
			if (netSocket.bytesAvailable < expectedMessageSize) {
				// keep waiting
				return;
			}
			
			var ob:Object;
			try {
				ob = netSocket.readObject();
				expectedMessageSize = NaN;
			} catch (eof:EOFError) {
				ob = null;
			} catch (ioe:IOError) {
				ob = null;
			} catch (e:Error) {
				ob = null;
			}
			
			if (ob && getQualifiedClassName(ob == 'Object')) {
				if (ob.type && (ob.type == 'server_message')) {
					if (ob.msg == token) {
						login_status = OK;
						return;
					}
				}
				login_status = FAILED;
			} else {
				login_status = ERROR;
			}
		}
		
		private static function onSocketClose(event:Event):void {
			removeSocketListeners();
		}
		
		private static function removeSocketListeners():void {
			if (netSocket) {
				netSocket.removeEventListener(Event.CONNECT, onSocketConnect);
				netSocket.removeEventListener(IOErrorEvent.IO_ERROR, onSocketError);
				netSocket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSocketError);
				netSocket.removeEventListener(Event.CLOSE, onSocketClose);
				netSocket.removeEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
			}
		}
		
		private function initTF():void {
			Font.registerFont(BootEmbed);
			
			const styleSheet:StyleSheet = new StyleSheet();
			styleSheet.parseCSS(CSS);
			
			msg_tf.embedFonts = true;
			msg_tf.styleSheet = styleSheet;
			msg_tf.autoSize = TextFieldAutoSize.LEFT;
			msg_tf.antiAliasType = AntiAliasType.ADVANCED;
			msg_tf.mouseWheelEnabled = false;
			msg_tf.multiline = true;
			
			msg_tf.addEventListener(TextEvent.LINK, onLink);
			
			msg_tf.x = 2;
			msg_tf.y = 2;
			msg_tf.width = width - 4;
			msg_tf.height = height - 4;
			
			addChild(msg_tf);
		}
		
		private static function styleText(html:String, style:String):String {
			return '<span class="' + style + '">' + html + '</span>';
		}
		
		private static function onLink(event:TextEvent):void {
			switch (event.text){
			case 'reload':
				URLUtil.reload();
				break;
			}
		}
		
		// there are "uncaught" exceptions that find their way here
		private static function onGlobalError(e:UncaughtErrorEvent):void {
			// Chrome has this nasty habit of firing:
			//   SecurityError: Error #2000: No active security context.
			// Damned if I know or care why...
			e.preventDefault();
			e.stopImmediatePropagation();
			ExternalInterface.call('connection_swf_error', (e.toString() + ': ' + e.error));
		}
		
		private static function reportError(e:Error):void {
			ExternalInterface.call('connection_swf_error', (e.toString() + ': '));
		}
		
		private static function reportResult(meth:String, result:String):void {
			ExternalInterface.call(meth, result);
		}

		public static function get lso_status():String {
			return _lso_status;
		}

		public static function set lso_status(value:String):void {
			_lso_status = value;
			reportResult('lso_result', value);
		}

		public static function get crossdomain_status():String {
			return _crossdomain_status;
		}

		public static function set crossdomain_status(value:String):void {
			_crossdomain_status = value;
			reportResult('crossdomain_result', value);
		}

		public static function get socket_policy_status():String {
			return _socket_policy_status;
		}

		public static function set socket_policy_status(value:String):void {
			_socket_policy_status = value;
			reportResult('socket_policy_result', value);
		}

		public static function get connection_status():String {
			return _connection_status;
		}

		public static function set connection_status(value:String):void {
			_connection_status = value;
			reportResult('connection_result', value);
		}

		public static function get login_status():String {
			return _login_status;
		}

		public static function set login_status(value:String):void {
			_login_status = value;
			reportResult('login_result', value);
		}

		public static function get external_interface_status():String {
			return _external_interface_status;
		}

		public static function set external_interface_status(value:String):void {
			_external_interface_status = value;
			reportResult('external_interface_result', value);
		}

		public static function get javascript_status():String {
			return _javascript_status;
		}

		public static function set javascript_status(value:String):void {
			_javascript_status = value;
			reportResult('javascript_result', value);
		}
	}
}
