package com.tinyspeck.debug {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.util.StringUtil;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;

	public class Benchmark {		
		private static const WIN_W:uint = 600;
		private static const WIN_H:uint = 350;
		private static const WIN_PADD:uint = 20;
		private static const TEXT_GAP:String = '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
		private static const HEADING_TXT:String = 'TIME (ms)\tDESCRIPTION\n---------\t-----------';
		
		private static var window:Sprite;
		private static var tf:TextField;
		private static var links_tf:TextField;
		private static var heading_tf:TextField;
		
		private static var is_inited:Boolean;
		private static var q_pressed:Boolean;
		private static var o_pressed:Boolean;
		private static var i_pressed:Boolean;
		private static var s_pressed:Boolean;
		private static var recordsA:Array = [];
		private static var section_start_ms_map:Object = {};
		private static var section_start_frame_map:Object = {};
		private static var curr_section_id:String = '';
		private static var pc_tsid:String;
		private static var stage_frame_num:int;
		
		// please don't change these string values, so we have consistency in the client error reports
		public static const SECTION_BOOT:String = 'BOOT';
		public static const SECTION_MOVE_STARTING:String = 'MOVE STARTING';
		public static const SECTION_MOVE_OVER:String = 'MOVE OVER';
		public static const SECTION_ADDING_PACK_STACKS:String = 'ADDING PACK STACKS';
		public static const SECTION_ENGINE_STARTING:String = 'ENGINE STARTING';
		public static const SECTION_DECOS_LOADING:String = 'DECOS LOADING';
		
		public function Benchmark() {
			throw new Error('This is a static class, start it with init()');
		}
		
		private static function onEnterFrame(ms_elapsed:int):void {
			stage_frame_num++;
		}
		
		public static function init(pc_tsid:String):void {
			if (is_inited) return;
			
			StageBeacon.enter_frame_sig.add(onEnterFrame);
			
			is_inited = true;
			Benchmark.pc_tsid = pc_tsid;
			
			StageBeacon.key_down_sig.add(onKeyDown);
			StageBeacon.key_up_sig.add(onKeyUp);
			startSection(SECTION_BOOT);
		}
		
		private static function onKeyDown(e:KeyboardEvent):void {
			if (e.keyCode == Keyboard.O && o_pressed) return;
			if (e.keyCode == Keyboard.Q && q_pressed) return;
			if (e.keyCode == Keyboard.I && i_pressed) return;
			if (e.keyCode == Keyboard.S && s_pressed) return;
			
			if (e.keyCode == Keyboard.O) o_pressed = true;
			if (e.keyCode == Keyboard.Q) q_pressed = true;
			if (e.keyCode == Keyboard.I) i_pressed = true;
			if (e.keyCode == Keyboard.S) s_pressed = true;
			if (q_pressed && o_pressed) display(!isVisible());
			if (q_pressed && i_pressed) toClipBoard();
			if (q_pressed && s_pressed) TIMtoClipBoard();
		}
		
		private static function onKeyUp(e:KeyboardEvent):void {
			if (e.keyCode == Keyboard.O) o_pressed = false;
			if (e.keyCode == Keyboard.Q) q_pressed = false;
			if (e.keyCode == Keyboard.I) i_pressed = false;
			if (e.keyCode == Keyboard.S) s_pressed = false;
		}
		
		private static function checkSectionName(section:String):Boolean {
			var var_name:String = 'SECTION_'+section.replace(/ /g, '_');
			if (!(var_name in Benchmark)) {
				CONFIG::debugging {
					Console.error('You are using this wrong at '+StringUtil.getCallerCodeLocation()+'. '+var_name+' is not a member of Benchmark');
				}
				return false;
			}
			
			return true;
		}
		
		public static function startSection(section:String):void {
			if (!checkSectionName(section)) return;
			
			if (is_inited) {
				var line:String = '';
				var was_curr_section_id:String = curr_section_id;
				if (was_curr_section_id) {
					line = '------------------------\n';
				}
				section_start_ms_map[section] = getTimer();
				section_start_frame_map[section] = stage_frame_num;
				//frame[section] = stage.getChildAt(0).;
				curr_section_id = section;
				addRecord('\nSTARTING SECTION:'+section+'');
				addRecord(line+section);
				if (was_curr_section_id) {
					addSectionTime(was_curr_section_id, true);
				}
			}
		}
		
		public static function addCheck(anything:*):void {
			if (is_inited) {
				addRecord(StringUtil.padNumber(getTimer()-section_start_ms_map[curr_section_id], 5)+':\t\t'+anything.toString());
			}
		}
		
		private static var outstandingMsgsCallback:Function;
		public static function addOutstandingMsgsCallback(func:Function):void {
			outstandingMsgsCallback = func;
		}
		
		public static function addSnippetCallback(func:Function):void {
			snippetCallback = func;
		}
		
		public static function addRecord(txt:String):void {
			if (is_inited) {
				if (isVisible()) {
					// we can add to the tf
					StageBeacon.stage.addChild(window); //make sure that it's on the top
					addLine(txt);
				} else {
					// store it in the array
					CONFIG::debugging {
						Console.log(323, txt);
					}
					recordsA.push(txt);
				}
			}
		}
		
		private static var snippetCallback:Function;
		public static function addSectionTime(section:String, log_snippet:Boolean=false):void {
			if (!checkSectionName(section)) return;
			
			var snippet:String = '';
			if (!section_start_ms_map.hasOwnProperty(section)) {
				// this happens if you call addSectionTime with a section before you call startSection with that section
				addCheck('ERROR! SECTION:'+section+' HAS NOT BEEN DECLARED; addSectionTime called from '+StringUtil.getCallerCodeLocation());
			} else {
				var secs:Number = (getTimer()-section_start_ms_map[section])/1000;
				var frames:int = stage_frame_num-section_start_frame_map[section];
				addCheck('SINCE "'+section+'":\n================================ '+(secs).toFixed(2)+'S '+(frames)+'F '+(frames/secs).toFixed(2)+'FPS');
				CONFIG::god {
					if (log_snippet) snippet = 'ADMIN: "'+curr_section_id+'"<br>'+(secs).toFixed(2)+'S '+(frames)+'F '+(frames/secs).toFixed(2)+'FPS';
				}
			}
			secs = getTimer()/1000;
			addCheck('TOTAL:\n================================ '+(secs).toFixed(2)+'S '+stage_frame_num+'F '+(stage_frame_num/secs).toFixed(2)+'FPS');
			CONFIG::god {
				if (log_snippet) {
					snippet+= '<br>'+(secs).toFixed(2)+'S '+stage_frame_num+'F '+(stage_frame_num/secs).toFixed(2)+'FPS';
					if (snippetCallback != null) {
						snippetCallback(snippet);
					}
				}
			}
		}
		
		public static function display(make_visible:Boolean):void {
			if (make_visible) {
				if (!window) buildWindow();
				if (!window.visible) {
					addCheck('NOW SHOWING BENCHMARK');
					// dump anything we have stored in the array into the window
					while (recordsA.length) addLine(recordsA.shift());
				} 
				window.visible = true;
			} else {
				if (isVisible()) addCheck('NOW HIDING BENCHMARK');
				if (window) window.visible = false;
			}
		}
		
		public static function isVisible():Boolean {
			return (window && window.visible);
		}
		
		private static function addLine(txt:String):void {
			tf.appendText(txt+'\n');
			
			//set it to the max scroll
			tf.scrollV = tf.maxScrollV;
		}
		
		private static function buildWindow():void {
			window = new Sprite();
			window.visible = false
			
			var format:TextFormat = new TextFormat('Arial', 10);
			
			heading_tf = new TextField();
			heading_tf.defaultTextFormat = format;
			heading_tf.autoSize = TextFieldAutoSize.LEFT;
			heading_tf.multiline = true;
			heading_tf.x = WIN_PADD;
			heading_tf.y = WIN_PADD;
			heading_tf.text = HEADING_TXT;
			
			window.addChild(heading_tf);
			
			tf = new TextField();
			tf.defaultTextFormat = format;
			tf.multiline = true;
			tf.wordWrap = true;
			tf.x = WIN_PADD;
			tf.y = heading_tf.y + heading_tf.height;
			tf.width = WIN_W - WIN_PADD*2;
			tf.height = WIN_H - WIN_PADD*2;
			window.addChild(tf);
			
			var g:Graphics = window.graphics;
			g.beginFill(0xff0000, .6);
			g.drawRoundRect(0, 0, WIN_W, WIN_H + heading_tf.height, 10);
			g.beginFill(0xffffff, .9);
			g.drawRect(WIN_PADD, WIN_PADD, WIN_W - WIN_PADD*2, WIN_H - WIN_PADD*2 + heading_tf.height);
			
			//format for the text links
			format.color = 0xffffff;
			format.size = 12;
			
			links_tf = new TextField();
			links_tf.defaultTextFormat = format;
			links_tf.autoSize = TextFieldAutoSize.LEFT;
			links_tf.htmlText = '<a href="event:copy"><b>Copy to clipboard & Close</b></a>'+TEXT_GAP+'|'+TEXT_GAP+
								'<a href="event:clear">Clear</a>'+TEXT_GAP+'|'+TEXT_GAP+
								'<a href="event:reset">Reset timer</a>'+TEXT_GAP+TEXT_GAP+TEXT_GAP+
								'<a href="event:close">Close</a>';
			links_tf.x = WIN_PADD;
			links_tf.y = tf.y + tf.height;
			links_tf.addEventListener(TextEvent.LINK, onLinkClick, false, 0, true);
			
			window.addChild(links_tf);
			
			StageBeacon.stage.addChild(window);
			
			//allow it to be dragged around
			window.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
			
		}
		
		private static function onMouseDown(event:MouseEvent):void {
			if (event.target is TextField) return;
			window.startDrag();
			window.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false, 0, true);
			window.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
		}
		
		private static function onMouseMove(event:MouseEvent):void {
			event.updateAfterEvent();
		}
		
		private static function onMouseUp(event:MouseEvent):void {
			window.stopDrag();
			window.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			window.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		public static function getShortLog():String {
			var A:Array = [];
			var move_sections_num:int;
			
			for (var i:int=recordsA.length-1;i>-1;i--) {
				A.unshift(recordsA[int(i)]);
				if (recordsA[int(i)].indexOf('\nSTARTING SECTION:MOVE STARTING') == 0) {
					move_sections_num++;
					if (move_sections_num == 3) { // only include a max of three moves
						A.unshift('\n----- only including the THREE MOST RECENT MOVES in this report -----');
						break;
					}
				}
			}
			
			if (outstandingMsgsCallback != null) A.push('\nOUTSTANDING MESSAGES:\n--------------------------------\n'+outstandingMsgsCallback())
			return getLog(A);
		}
		
		public static function getLog(A:Array):String {
			var txt:String = HEADING_TXT+'\n';
			if (window) {
				txt+= tf.text;
			}
			txt+= A.join('\n');
			return txt;
		}
		
		private static function toClipBoard():void {
			addCheck('BENCHMARK COPIED')
			System.setClipboard(getLog(recordsA));
		}
		
		private static function TIMtoClipBoard():void {
			System.setClipboard(Tim.reports.join('\n'));
		}
		
		private static function onLinkClick(event:TextEvent):void {
			switch(event.text) {
				case 'copy':
					toClipBoard();
					display(false);
					break;
				case 'clear':
					tf.text = '';
					section_start_ms_map[SECTION_BOOT] = getTimer();
					recordsA.length = 0;
					break;
				case 'reset':
					startSection('MANUAL RESET');
					addCheck('RESET');
					break;
				case 'close':
					display(false);
					break;
			}
		}
	}
}