// the basic interface that would be needed for a Logger class to sit in front of Console.
// package ts {
// 	
// 	public class Logger {
// 		public static function setPri(...rest):void {}
// 		public static function deepTrace(...rest):void {}
// 		public static function log(...rest):void {}
// 		public static function warn(...rest):void {}
// 		public static function dir(...rest):void {}
// 		public static function pridir(...rest):void {}
// 		public static function info(...rest):void {}
// 		public static function error(...rest):void {}
// 	}
// 
// }
package com.tinyspeck.debug {
	import com.adobe.serialization.json.JSON;
	import com.tinyspeck.engine.util.StringUtil;
	
	import flash.external.ExternalInterface;
	import flash.system.Capabilities;

	/**
	 * Firebug adds a global variable named "console" to all web pages loaded in Firefox. 
	 * This object contains many methods that allow you to write to the Firebug console to expose information that is flowing through your scripts.
	 * */
	public class Console {
		public static const SCRIBE:String = 'SCRIBE';
		public static const FIREBUG:String = 'FIREBUG';
		public static const TRACE:String = 'TRACE';

		CONFIG::debugging private static var paused:Boolean = false;
		CONFIG::debugging private static var to_scribe:Boolean = false;
		CONFIG::debugging private static var to_firebug:Boolean = false;
		CONFIG::debugging private static var to_trace:Boolean = true;
		CONFIG::debugging private static var pri:String;
		CONFIG::debugging private static var priArray:Array;
		CONFIG::debugging private static var console_name_prefix:String = 'com.tinyspeck.debug::Console';
		CONFIG::debugging private static var ns_prefix:String = 'com.tinyspeck';
		CONFIG::debugging private static var pc_tsid:String = '';
		CONFIG::debugging private static var pc_label:String = '';
		CONFIG::debugging private static var app_version:String = '';
		CONFIG::debugging private static var session_id:String = '';
		
		CONFIG::debugging public static function setOutput(output:String, do_output:Boolean = true):void {
			if (output == FIREBUG) {
				info('Console '+output+' output:'+do_output);
				Console.to_firebug = do_output;
			}
			if (output == TRACE) {
				Console.to_trace = true; // so we can log this
				info('Console '+output+' output:'+do_output);
				Console.to_trace = do_output;
			}
			if (output == SCRIBE) {
				info('Console '+output+' output:'+do_output);
				Console.to_scribe = do_output;
			}
		}
		
		CONFIG::debugging public static function setSessionId(session_id:String):void {
			Console.session_id = session_id;
		}
		
		CONFIG::debugging public static function setPcTsid(pc_tsid:String):void {
			Console.pc_tsid = pc_tsid;
		}
		
		CONFIG::debugging public static function setPcLabel(pc_label:String):void {
			Console.pc_label = pc_label;
		}
		
		CONFIG::debugging public static function setAppVersion(app_version:String):void {
			Console.app_version = app_version;
		}
		
		CONFIG::debugging public static function pause():void {
			Console.paused = true;
		}
		
		CONFIG::debugging public static function resume():void {
			Console.paused = false;
		}
		
		CONFIG::debugging public static function setPri(pri:String):void {
			Console.pri = pri;
			Console.priArray = pri.split(',');
		}
		
		CONFIG::debugging public static function trackValue(key:String, ...values):void {
			GeneralValueTracker.instance.log(key, values);
		}
		
		CONFIG::debugging public static function removeTrackedValue(key:String):void {
			GeneralValueTracker.instance.remove(key);
		}
		
		CONFIG::debugging public static function trackPhysicsValue(key:String, ...values):void {
			PhysicsValueTracker.instance.log(key, values);
		}
		
		CONFIG::debugging public static function removePhysicsTrackedValue(key:String):void {
			PhysicsValueTracker.instance.remove(key);
		}
		
		CONFIG::debugging public static function trackRookValue(key:String, ...values):void {
			RookValueTracker.instance.log(key, values);
		}
		
		CONFIG::debugging public static function removeRookTrackedValue(key:String):void {
			RookValueTracker.instance.remove(key);
		}
		
		CONFIG::debugging private static function deepTrace(obj:*, level:int=0): void {
			var tabs:String = "";
			for (var i:int = 0; i < level; i++) {
				tabs += "  ";
			};
			
			for (var prop:String in obj){
				if(to_trace == true){
					trace(tabs + "\"" + prop + "\":" + obj[prop]);
				}
				deepTrace(obj[prop], level + 1);
			}
		}

		CONFIG::debugging public static function priOK(pri:String):Boolean {
			if (!priArray) return true;
			
			if (pri == '0') return true;
			if (priArray.indexOf('all') != -1) return true;
			if (priArray.indexOf(pri) == -1) return false;
			return true;
		}
		
		CONFIG::debugging private static function functionName():String {
			var func:String = '';
			var loc:String = '';
			
			var s:String = new Error().getStackTrace();
			if (!s) return 'no_trace_available';
			var A:Array = s.split('\n');
			//at com.tinyspeck.control::BootController/bootStrap()[/Users/eric/Documents/workspace/clientNew/src/com/tinyspeck/control/BootController.as:50]
			var d:int = 1; // start at second line, because the first contains just "Error at"
			var temp_line:String;
			while(d==1 || temp_line.indexOf(console_name_prefix) > -1) {
				temp_line = A[d];
				d++;
			}
			
			var i:int = temp_line.indexOf('at ');
			var line:String = temp_line.substr(i+3);
			var line_parts:Array = line.split('()');
			func = line_parts[0]+'()';
			func = func.split('/')[func.split('/').length-1];
			loc = line_parts[1].substr(line_parts[1].lastIndexOf('/')+1).replace(']', '');
			
			if (func.indexOf(ns_prefix) > -1) func = func.split('::')[1];

			return loc+' '+func;
		}
		
		/**
		 * Writes a message to the console. 
		 * You may pass as many arguments as you'd like, and they will be
		 * joined together in a space-delimited line.
		 * */
		CONFIG::debugging public static function log(pri:*, ...rest):void{
			pri = pri.toString();
			if (pri && !priOK(pri)) return;
			sendWpri('log', pri, rest);
		}
		
		CONFIG::debugging public static function pridir(pri:*, object:Object, and_show_string:Boolean = false):void {
			pri = pri.toString();
			if (!priOK(pri)) return;
			Console.dir(object, and_show_string, pri);
		}
		/**
		 * 	Prints an interactive listing of all properties of the object. 
		 * 	This looks identical to the view that you would see in the DOM tab.
		 * */
		CONFIG::debugging public static function dir(object:Object, and_show_string:Boolean = false, pri:String = ''):void {
			if (!object) {
				send('warn', 'null object passed to Console.dir');
				return;
			}
			if (and_show_string || to_scribe) {
				var txt:String = StringUtil.getJsonStr(object);
				if (and_show_string) sendWpri('log', pri, 'JSON: '+txt);
				if (to_scribe) scribe('MSG '+pri+' '+txt);
			}
			sendWpri("dir", pri, object);
		}
		/**
		 * Writes a message to the console with the visual "warning" icon and 
		 * color coding and a hyperlink to the line where it was called.
		 * */
		CONFIG::debugging public static function warn(...rest):void{
			send("warn", rest);
		}
		
		CONFIG::debugging public static function priwarn(pri:*, ...rest):void {
			pri = pri.toString();
			if (!priOK(pri)) return;
			
			Console.warn(rest);
		}
		/**
		 * Writes a message to the console with the visual "info" icon and 
		 * color coding and a hyperlink to the line where it was called.
		 * */
		CONFIG::debugging public static function info(...rest):void{
			send("info",rest);
		}
		
		CONFIG::debugging public static function priinfo(pri:*, ...rest):void {
			pri = pri.toString();
			if (!priOK(pri)) return;
			
			Console.info(rest);
		}
		/**
		 * Writes a message to the console with the visual "error" icon and
		 * color coding and a hyperlink to the line where it was called.
		 * */
		CONFIG::debugging public static function error(...rest):void{
			var s:String = '';
			try {
				//s = new Error().getStackTrace();
				s = StringUtil.getShorterStackTrace(new Error())
			} catch(err:Error) {
				
			}
			s = s || 'no_trace_available';
			send("error",rest);
			send("log", 'STACK TRACE: '+s);
		}
		/**
		 * Tests that an expression is true. 
		 * If not, it will write a message to the console and throw an exception.
		 * */
		CONFIG::debugging public static function assert(...rest):void{
			send("assert",rest);
		}
		/**
		 * 	Prints the XML source tree of an HTML or XML element. 
		 * 	This looks identical to the view that you would see in the HTML tab. 
		 * 	You can click on any node to inspect it in the HTML tab.
		 * */
		CONFIG::debugging public static function dirxml(object:XML):void{
			send("dirxml", [object]);
		}
		/**
		 * Prints an interactive stack trace of JavaScript execution at the 
		 * point where it is called.
		 * The stack trace details the functions on the stack, as well as the values
		 * that were passed as arguments to each function. You can click each function 
		 * to take you to its source in the Script tab, and click each argument value
		 * to inspect it in the DOM or HTML tabs.
		 * */
		CONFIG::debugging public static function strace():void{
			send("trace");
		}
		/**
		 * Writes a message to the console and opens a nested block to indent all future messages sent to the console. 
		 * Call console.groupEnd() to close the block.
		 * */
		CONFIG::debugging public static function group(...rest):void{
			send("group", rest);
		}
		/**
		 * Closes the most recently opened block created by a call to console.group.
		 * */
		CONFIG::debugging public static function groupEnd():void{
			send("groupEnd", []);
		}
		/**
		 * Creates a new timer under the given name. 
		 * Call console.timeEnd(name) with the same name to stop the timer and print the time elapsed..
		 * */
		CONFIG::debugging public static function time(name:String):void{
			send("time", [name]);
		}
		/**
		 * Stops a timer created by a call to console.time(name) and writes the time elapsed.
		 * */
		CONFIG::debugging public static function timeEnd(name:String):void{
			send("timeEnd", [name]);
		}
		/**
		 * Turns on the JavaScript profiler. 
		 * The optional argument title would contain the text to be printed in the header of the profile report.
		 * */
		CONFIG::debugging public static function profile(title:String):void{
			send("profile", [title]);
		}
		/**
		 * Turns off the JavaScript profiler and prints its report.
		 * */
		CONFIG::debugging public static function profileEnd():void{
			send("profileEnd", []);
		}
		/**
		 * Writes the number of times that the line of code where count was called was executed.
		 * The optional argument title will print a message in addition to the number of the count.
		 * */
		CONFIG::debugging public static function count(name:String=null):void{
			send("count", name ? [name] : []);
		}
		/**
		 * makes the call to console
		 * */
		CONFIG::debugging private static function sendWpri(level:String, pri:String = '', ...rest):void{
			var f:String;
			if (CONFIG::debugging) { 
				if (Console.paused) return;
				f = functionName();
				if (level == 'dir') {
					if (to_trace == true) {
						trace(to_trace);
						trace('Showing tree '+rest.length+' ---> '+f+' '+StringUtil.getColonDateInGMT(new Date()));
						deepTrace(rest);
					}
					if (to_firebug) {
						var msg_type:String = (rest[0] && 'type' in rest[0]) ? ' for type:'+rest[0].type : '';
						if (rest[0] && ' uid' in rest[0]) msg_type+= 'uid:'+rest[0].uid
						ExternalInterface.call("console.log", pri+' '+StringUtil.getColonDateInGMT(new Date())+' '+f+' >>> Showing tree'+msg_type+'');
						try {ExternalInterface.call("console.dir", rest[0]);} catch(e:SecurityError) {error('call to console.dir failed')};
					}
				} else {
					//rest.push(f);
					if (to_trace == true){
						trace(level.toUpperCase()+' '+pri+' '+f+' >>> '+rest[0]);
					} 
					if (to_scribe == true){
						scribe(level.toUpperCase()+' '+pri+' '+f+' >>> '+rest[0]);
					} 
					try {
						if (to_firebug) {
							ExternalInterface.call("console."+level, ((level == 'info' || level == 'warn')?'\n':'')+pri+' '+StringUtil.getColonDateInGMT(new Date())+' '+f+' >>> '+rest[0]);
						}
					} catch(e:SecurityError) {}
				}
			} else {
				if (to_scribe == true){
					f = functionName();
					scribe(level.toUpperCase()+' '+pri+' '+f+' >>> '+rest[0]);
				}
			}
		}

		CONFIG::debugging private static function send(level:String,...rest):void{
			var f:String;
			if (CONFIG::debugging) {
				if (Console.paused) return;
				f = functionName();
				if (level == 'dir') {
					if (to_trace == true){
						deepTrace(rest);
					} 
					if (to_firebug) {
						try {
							ExternalInterface.call("console.dir", rest[0]);
						} catch(e:SecurityError) {
							error('call to console.dir failed')
						};
					}
				} else {
					//rest.push(f);
					if (to_trace == true){
						trace(level.toUpperCase()+' '+rest[0]+' ---> '+f+' '+StringUtil.getColonDateInGMT(new Date()));
					}
					if (to_scribe == true){
						scribe(level.toUpperCase()+' '+rest[0]+' ---> '+f+' '+StringUtil.getColonDateInGMT(new Date()));
					} 
					try {
						if (to_firebug) {
							// the crazy escaping of rest[0] is because http://lcamtuf.blogspot.com/2011/03/other-reason-to-beware-of.html
							//ExternalInterface.call("console."+level, ((level == 'info' || level == 'warn')?'\n':'')+StringUtil.getColonDateInGMT(new Date())+' '+f+' >>> '+String(rest[0]).replace(/\\/g, '\\\\'));
							ExternalInterface.call("console."+level, StringUtil.escapeRegEx(((level == 'info' || level == 'warn')?'\n':'')+StringUtil.getColonDateInGMT(new Date())+' '+f+' >>> '+rest[0]));
						}
					} catch(e:SecurityError) {}
				}
			} else {
				if (to_scribe == true){
					f = functionName();
					scribe(level.toUpperCase()+' '+rest[0]+' ---> '+f+' '+StringUtil.getColonDateInGMT(new Date()));
				}
			}
		}
		
		CONFIG::debugging public static function scribe(txt:String):void {
			try {
				API.scribe(new Date().getTime()+' '+session_id+'::'+pc_tsid+((pc_label?' "'+pc_label+'"':''))+' ver:'+app_version+'\n'+ExternalInterface.call('window.navigator.userAgent.toString')+' '+Capabilities.version+((Capabilities.isDebugger)?' DEBUG':'')+' '+txt);
			} catch (err:Error) {
				
			}
		}
	}
}