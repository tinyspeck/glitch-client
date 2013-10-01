package com.tinyspeck.core.data {
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.VectorUtil;
	
	import flash.geom.Rectangle;
	
	public class AvatarAnimationDefinitions {
		public static var frame_offset_y:int = 0 // populated by init, the is an allowance to make sure the bottoms of shoes get captures in the bmd
		public static var frame_w:int = 0; // populated by init
		public static var frame_h:int = 0; // populated by init
		private static var max_frame_cols:int = 39; // adjusted for scale in init
		private static var fn_to_sheet_map:Object = {}; // populated by init
		private static var anims_in_sheetsA:Array = []; // populated by init
		
		private static var inited:Boolean = false;
		
		public static function init(scale:Number):void {
			if (inited) return;
			inited = true;
			max_frame_cols = max_frame_cols/scale;
			
			frame_h = Math.round(198*scale);
			frame_w = Math.round(198*scale);
			frame_offset_y = Math.round(-10*scale);
			
			var def:Object;
			var sheetH:Object;
			var sheet:String;
			var anim:String;
			var fn:int;
			var i:int;
			var framesA:Array;
			
			for each (sheet in sheetsA) {
				sheetH = sheets[sheet];
				for each (anim in sheetH.anims) {
					def = defs[anim];
					def.sheet = sheet;
					def.sheets_requiredA.push(sheet);
					sheetH.framesA = sheetH.framesA.concat(getFramesForAnim(anim, false));
					anims_in_sheetsA.push(anim);
				}
				sheetH.framesA = VectorUtil.unique(sheetH.framesA);
				
				if (sheet != 'base') {
					// remove any frames in base from the other ones
					for (i=0;i<sheets['base'].framesA.length;i++) {
						fn = sheets['base'].framesA[int(i)];
						if (sheetH.framesA.indexOf(fn)>-1) sheetH.framesA.splice(sheetH.framesA.indexOf(fn), 1);
					}
				}
				
				// make sure it is sorted
				sheetH.framesA.sort(Array.NUMERIC);
				
				// build map for frames nums in swf to the sheet that holds them
				for (i=0;i<sheetH.framesA.length;i++) {
					fn_to_sheet_map[sheetH.framesA[int(i)]] = sheet;
				}
				
				var num_squares:int = sheetH.framesA.length;
				// calculate the best number of cols
				sheetH.cols = Math.ceil(num_squares/Math.ceil(num_squares/max_frame_cols));
				sheetH.rows = Math.ceil(sheetH.framesA.length/sheetH.cols);
				
			}
			
			// calculate which sheets are required for which animations
			for (anim in defs) {
				def = defs[anim];
				framesA = getFramesForAnim(anim, false);
				for (i=0;i<framesA.length;i++) {
					sheet = fn_to_sheet_map[framesA[int(i)]];
					if (def.sheets_requiredA.indexOf(sheet) == -1) {
						def.sheets_requiredA.push(sheet);
					}
				}
				def.sheets_requiredA.sort();
			}
			
		}
		
		public static function getStandInFrameForAnim(anim:String):uint {
			CONFIG::debugging {
				if (!inited) Console.error('NOT INITED');
			}
			
			if (defs && defs[anim] && defs[anim].standin_frame) {
				return defs[anim].standin_frame as uint;
			}
			
			return 0;
		}
		
		public static function getAnyAnimThatContainsSWFFrameNum(fn:int):String {
			CONFIG::debugging {
				if (!inited) Console.error('NOT INITED');
			}
			
			var def:Object;
			var anim:String
			for (anim in defs) {
				if (getFramesForAnim(anim, false).indexOf(fn) != -1) {
					return anim;
				}
			}
			
			return null;
		}
		
		public static function getFramesForAnim(anim:String, copy:Boolean=true):Array {
			CONFIG::debugging {
				if (!inited) Console.error('NOT INITED');
			}
			
			if (EnvironmentUtil.getUrlArgValue('SWF_fake_ss_frames') == '1') return [1, 13, 1];
			var frames_name:String = 'framesA';
			
			if (defs && defs[anim]) {
				if (defs[anim][frames_name] && defs[anim][frames_name].length) {
					return (copy) ? defs[anim][frames_name].concat() : defs[anim][frames_name];
				}
			}
			
			return [1];
		}
		
		public static function getSheetedAnimsA():Array {
			CONFIG::debugging {
				if (!inited) Console.error('NOT INITED');
			}
			return anims_in_sheetsA;
		}
		
		private static function getTotalFramesInUse():Array {
			var allA:Array = [];
			var def:Object;
			var anim:String
			for (anim in defs) {
				def = defs[anim];
				allA = allA.concat(getFramesForAnim(anim, false));
			}
			return allA;
		}
		
		public static function getSheetForSwfFrameNum(fn:int):String {
			CONFIG::debugging {
				if (!inited) Console.error('NOT INITED');
			}
			return fn_to_sheet_map[fn];
		}
		
		public static function getRectangleForSwfFrameNum(fn:int, f_w:int=0, f_h:int=0):Rectangle {
			CONFIG::debugging {
				if (!inited) Console.error('NOT INITED');
			}
			
			if (!f_w) f_w = frame_w;
			if (!f_h) f_h = frame_h;
			
			var rect:Rectangle = new Rectangle(0, 0, f_w, f_h);
			var sheet:String = fn_to_sheet_map[fn];
			var sheetH:Object = sheets[sheet];
			
			var framesA:Array = getFramesForSheet(sheet);
			var i:int = framesA.indexOf(fn);
			
			var cols:int = getColsForSheet(sheet);
			var rows:int =  Math.ceil(framesA.length/cols);
			
			var col:int = (i % cols);
			var row:int = Math.floor(i / cols);
			
			rect.x = col*f_w;
			rect.y = row*f_h;
			
			return rect;
		}
		
		CONFIG::debugging public static function getPHPReport():String {
			/*$anim = array(
				'sheets' => array(
					'base' => array(
						'cols'		=> 15,
						'rows'		=> 1,
						'frames'	=> array(103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 489, 490, 801),
					),
					'jump' => array(
						'cols'		=> 33,
						'rows'		=> 1,
						'frames'	=> array(192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224),
					),
				),
				'anims' => array(
					'jump'	=> array(192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203),
					'climb' => array(1145, 1146, 1147, 1148, 1149, 1150, 1151, 1152, 1153, 1154, 1155, 1156, 1157, 1158, 1159, 1160, 1161, 1162, 1163),
				),
			)*/
			
			
			
			if (!inited) Console.error('NOT INITED');
			
			var usage:Object = getFrameUsage();
			var strA:Array = [];
			strA.push('$anim = array(');
			
			var fnH:Object;
			var fn:int;
			var i:int;
			var m:int;
			var sheetH:Object;
			var sheet:String;
			var def:Object;
			var anim:String;
			var framesA:Array;
			
			strA.push("	'sheets' => array(");
			for each (sheet in sheetsA) {
				sheetH = sheets[sheet];
				strA.push("		'"+sheet+"' => array(");
				strA.push("			'cols'		=> "+sheetH.cols+",");
				strA.push("			'rows'		=> "+sheetH.rows+",");
				strA.push("			'frames'	=> array("+sheetH.framesA.join(', ')+"),");
				strA.push("		),");
			}
			
			strA.push("	),");
			
			strA.push("	'anims' => array(");
			
			var animsA:Array = [];
			for (anim in defs) {
				animsA.push(anim);
			}
			animsA.sort();
			
			for (i=0;i<animsA.length;i++) {
				anim = animsA[i];
				def = defs[anim];
				if (def.sheet) {
					framesA = getFramesForAnim(anim);
					strA.push("		'"+anim+"' => array("+framesA.join(', ')+"),");
				}
			}
			
			strA.push("	),");
			
			strA.push(')');
			return strA.join('\n');
		}
		
		CONFIG::debugging public static function getReport(short:Boolean=false):String {
			if (!inited) Console.error('NOT INITED');
			
			var usage:Object = getFrameUsage();
			var strA:Array = [];
			strA.push('ANIMATION REPORT\n-----------------');
			strA.push('total frame cnt: '+usage.totalFramesA.length);
			strA.push('unique frame cnt: '+usage.uniqueFramesA.length);
			strA.push('frames reused in multiple anims cnt: '+usage.reusedByOtherAnimsFramesA.length);
			strA.push('frames reused cnt: '+usage.reusedFramesA.length);
			strA.push('anims in sheets: '+getSheetedAnimsA().join(', '));
			
			var fnH:Object;
			var fn:int;
			var i:int;
			var m:int;
			var sheetH:Object;
			var sheet:String;
			var def:Object;
			var anim:String;
			var framesA:Array;
			var unique_framesA:Array;
			
			strA.push('\n spritesheets png files:');
			for each (sheet in sheetsA) {
				sheetH = sheets[sheet];
				strA.push('    '+sheet);
				strA.push('          frame cnt:'+sheetH.framesA.length);
				strA.push('          anims:'+sheetH.anims.join(', '));
				strA.push('          frames:'+sheetH.framesA.join(', '));
				strA.push('          cols:'+sheetH.cols);
				strA.push('          rows:'+sheetH.rows);
			}
			
			if (!short) {
				strA.push('\nframes reused in multiple anims: '+usage.reusedByOtherAnimsFramesA.length);
				for (i=0;i<usage.reusedByOtherAnimsFramesA.length;i++) {
					fn = usage.reusedByOtherAnimsFramesA[int(i)];
					fnH = usage.fnsH[fn];
					strA.push('    '+fn+' used in '+fnH.animsA.join(', ')+' a total of '+fnH.use_count+' times');
				}
			}
			
			strA.push('\nanims:');
			
			var animsA:Array = [];
			for (anim in defs) {
				animsA.push(anim);
			}
			animsA.sort();
			
			var total_unique_frames:int;
			var total_notunique_count:int;
			
			for (i=0;i<animsA.length;i++) {
				anim = animsA[i];
				def = defs[anim];
				strA.push('    '+anim);
				if (def.sheet) { 
					strA.push('        in png: '+def.sheet);
					strA.push('        required pngs: '+def.sheets_requiredA.join(', ')+'');
					framesA = getFramesForAnim(anim);
					total_notunique_count+= framesA.length;
					unique_framesA = [];
					var tempA:Array = [];
					for (m=0;m<framesA.length;m++) {
						fn = framesA[int(m)];
						if (unique_framesA.indexOf(fn) == -1) {
							unique_framesA.push(fn);
						}
						tempA.push('            '+fn+' in:'+fn_to_sheet_map[fn]+' at:'+getRectangleForSwfFrameNum(fn));
					}
					total_unique_frames+= unique_framesA.length;
					strA.push('        unique frames: ('+unique_framesA.length+') '+unique_framesA);
					strA.push('        frames: ('+framesA.length+')');
					if (short) {
						strA.push('            '+framesA);
					} else {
						strA = strA.concat(tempA);
					}
				} else {
					strA.push('        NOT IN A SHEET');
				}
			}
			
			
			strA.push('\ntotal_unique:'+total_unique_frames+' total:'+total_notunique_count+' savings %:'+((total_notunique_count-total_unique_frames)/total_notunique_count));
			
			if (!short) {
				strA.push('\nanim data for API:');
				
				for (i=0;i<animsA.length;i++) {
					anim = animsA[i];
					def = defs[anim];
					if (def.sheet) { 
						strA.push('    '+anim);
						strA.push('        required sheets: '+def.sheets_requiredA.join(', ')+'');
						strA.push('        frames:');
						
						framesA = getFramesForAnim(anim);
						for (m=0;m<framesA.length;m++) {
							fn = framesA[int(m)];
							strA.push('            '+fn_to_sheet_map[fn]+':'+sheets[fn_to_sheet_map[fn]].framesA.indexOf(fn));
						}
					} else {
						
					}
				}
				
				strA.push('\nall reused frames: '+usage.reusedFramesA.length);
				for (i=0;i<usage.reusedFramesA.length;i++) {
					fn = usage.reusedFramesA[int(i)];
					fnH = usage.fnsH[fn];
					strA.push('    '+fn+' used in '+fnH.animsA.join(', ')+' a total of '+fnH.use_count+' times');
				}
			}
			
			return strA.join('\n');
		}
		
		public static function getColsForSheet(sheet:String):int {
			CONFIG::debugging {
				if (!inited) Console.error('NOT INITED');
			}
			return sheets[sheet].cols;
		}
		
		public static function getRowsForSheet(sheet:String):int {
			CONFIG::debugging {
				if (!inited) Console.error('NOT INITED');
			}
			return sheets[sheet].rows;
			
			//var cols:int = sheets[sheet].cols;
			//return Math.ceil(sheets[sheet].framesA.length/cols);
		}
		
		public static function getFramesForSheet(sheet:String):Array {
			CONFIG::debugging {
				if (!inited) Console.error('NOT INITED');
			}
			return sheets[sheet].framesA;
		}
		
		public static function getAnimsForSheet(sheet:String):Array {
			CONFIG::debugging {
				if (!inited) Console.error('NOT INITED');
			}
			return sheets[sheet].anims;
		}
		
		public static const emotion_animsA:Array = ['happy', 'surprise', 'angry'];
		public static const sheetsA:Array = ['base', 'jump', 'climb', 'angry', 'surprise', 'happy', 'idle1', 'idle2', 'idle3', 'idle4','idleSleepy'];
		private static var sheets:Object = {
			'base': {
				anims: ['walk1x', 'walk2x', 'walk3x', 'idle0', 'hit1', 'hit2'],
				framesA: [], // gets populated by init
				cols: 0, // gets populated by init
				rows: 0 // gets populated by init
			},
			'jump': {
				anims: ['jumpOver_lift', 'jumpOver_fall', 'jumpOver_land', 'jumpOver_test_sequence'],
				framesA: [], // gets populated by init
				cols: 0, // gets populated by init
				rows: 0 // gets populated by init
			},
			'climb': {
				anims: ['climb'],
				framesA: [], // gets populated by init
				cols: 0, // gets populated by init
				rows: 0 // gets populated by init
			},
			'angry': {
				anims: ['angry'],
				framesA: [], // gets populated by init
				cols: 0, // gets populated by init
				rows: 0 // gets populated by init
			},
			'surprise': {
				anims: ['surprise'],
				framesA: [], // gets populated by init
				cols: 0, // gets populated by init
				rows: 0 // gets populated by init
			},
			'happy': {
				anims: ['happy'],
				framesA: [], // gets populated by init
				cols: 0, // gets populated by init
				rows: 0 // gets populated by init
			},
			'idle1': {
				anims: ['idle1'],
				framesA: [], // gets populated by init
				cols: 0, // gets populated by init
				rows: 0 // gets populated by init
			},
			'idle2': {
				anims: ['idle2'],
				framesA: [], // gets populated by init
				cols: 0, // gets populated by init
				rows: 0 // gets populated by init
			},
			'idle3': {
				anims: ['idle3'],
				framesA: [], // gets populated by init
				cols: 0, // gets populated by init
				rows: 0 // gets populated by init
			},
			'idle4': {
				anims: ['idle4'],
				framesA: [], // gets populated by init
				cols: 0, // gets populated by init
				rows: 0 // gets populated by init
			},
			'idleSleepy': {
				anims: ['idleSleepyStart', 'idleSleepyLoop', 'idleSleepyEnd'],
				framesA: [], // gets populated by init
				cols: 0, // gets populated by init
				rows: 0 // gets populated by init
			}
		}
		
		private static var defs:Object = {
			'walk1x': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				framesA: [103, 103, 104, 105,105, 106, 107, 107, 108, 109,109, 110, 111,111, 112, 113,113, 114]
			},
			
			'walk2x': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				framesA: [103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114]
			},
			
			'walk3x': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				framesA: [103, 105, 107, 109, 111, 113, 104, 106, 108, 110, 112, 114]
			},
			
			'jumpUp_lift': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				standin_frame: 107, // must be in base sheet!
				standin: 'jumpOver_lift',
				framesA: [158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170]
			},
			
			'jumpUp_fall': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				standin_frame: 107, // must be in base sheet!
				framesA: [171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182]
			},
			
			'jumpUp_land': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				standin_frame: 107, // must be in base sheet!
				framesA: [183, 184, 185, 186, 187, 188, 189, 190, 191]
			},
			
			'jumpOver_lift': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				standin_frame: 107, // must be in base sheet!
				framesA: [192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203]
			},
			
			'jumpOver_test_sequence': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				standin_frame: 107, // must be in base sheet!
				framesA: [192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224]
			},
			
			'jumpOver_fall': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				standin_frame: 107, // must be in base sheet!
				framesA: [204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 214, 214, 214, 214, 214, 214, 214, 213, 213, 213, 213, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214, 213, 213, 213, 213, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214, 213, 213, 213, 213, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214, 213, 213, 213, 213, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214, 213, 213, 213, 213, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214, 213, 213, 213, 213, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214, 213, 213, 213, 213, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214, 213, 213, 213, 213, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214, 213, 213, 213, 213, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214, 213, 213, 213, 213, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214, 213, 213, 213, 213, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214, 213, 213, 213, 213, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214, 213, 213, 213, 213, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214, 213, 213, 213, 213, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214, 213, 213, 213, 213, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214, 213, 213, 213, 213, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214, 213, 213, 213, 213, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214, 213, 213, 213, 213, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214, 213, 213, 213, 213, 212, 212, 212, 212, 213, 213, 213, 213, 214, 214, 214, 214]
			},
			
			'jumpOver_land': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				standin_frame: 107, // must be in base sheet!
				framesA: [215, 216, 217, 218, 219, 220, 221, 222, 223, 224]
			},
			
			'surprise': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				standin_frame: 801, // must be in base sheet!
				framesA: [225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 236, 235, 236, 237, 236, 235, 236, 237, 236, 235, 236, 237, 236, 235, 236, 237, 236, 235, 236, 237, 236, 235, 236, 237, 236, 235, 236, 237, 287, 288, 289, 290, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 291, 292, 293, 294, 225]
			},
			
			'happy': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				standin_frame: 801, // must be in base sheet!
				framesA: [405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 417, 416, 415, 416, 417, 418, 417, 416, 415, 416, 417, 418, 417, 416, 415, 416, 417, 418, 417, 416, 415, 416, 417, 418, 417, 416, 415, 416, 417, 418, 417, 416, 415, 416, 417, 418, 417, 416, 415, 416, 417, 418, 417, 416, 415, 416, 417, 418, 472, 473, 474, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 475, 476, 477, 478, 405]
			},
			
			'hit1': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				framesA: [489]
			},
			
			'hit2': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				framesA: [490]
			},
			
			'idleSleepyStart': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				standin_frame: 801, // must be in base sheet!
				framesA: [801, 801, 494, 494, 495, 496, 496, 498, 499, 500, 501, 502, 503, 505, 507, 509, 511, 513, 514, 542, 541, 540, 539, 538, 537, 536, 535, 534, 533, 532, 531, 530, 529, 528, 527, 526, 525, 524, 523, 522, 521]
			},
			
			'idleSleepyEnd': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				standin_frame: 801, // must be in base sheet!
				framesA: [521, 522, 523, 524, 525, 526, 527, 528, 529, 530, 531, 532, 533, 534, 535, 536, 537, 538, 539, 540, 541, 542, 514, 513, 511, 509, 507, 505, 503, 502, 501, 500, 499, 498, 496, 496, 495, 494, 494, 801, 801]
			},
			
			'idleSleepyLoop': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				standin_frame: 801, // must be in base sheet!
				framesA: [521, 522, 523, 524, 525, 526, 527, 528, 529, 530, 531, 532, 533, 534, 535, 536, 537, 538, 539, 540, 541, 542, 543, 544, 545, 546, 547, 546, 545, 544, 543, 542, 541, 540, 539, 538, 537, 536, 535, 534, 533, 532, 531, 530, 529, 528, 527, 526, 525, 524, 523, 522, 521, 522, 523, 524, 525, 526, 527, 528, 529, 530, 531, 532, 533, 534, 535, 536, 537, 538, 539, 540, 541, 542, 543, 544, 545, 546, 547, 546, 545, 544, 543, 542, 541, 540, 539, 538, 537, 536, 535, 534, 533, 532, 531, 530, 529, 528, 527, 526, 525, 524, 523, 522, 521]
			},
			
			'angry': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				standin_frame: 801, // must be in base sheet!
				framesA: [625, 626, 627, 628, 629, 630, 631, 632, 633, 634, 635, 636, 637, 636, 635, 636, 637, 636, 635, 636, 637, 636, 635, 636, 637, 636, 635, 636, 637, 636, 635, 636, 637, 636, 635, 636, 637, 636, 635, 636, 637, 636, 635, 688, 689, 690, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 691, 692, 693, 694, 625]
			},
			
			'idle0': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				framesA: [801]
			},
			
			'idle1': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				standin_frame: 801, // must be in base sheet!
				framesA: [801, 806, 807, 808, 809, 810, 811, 812, 813, 814, 815, 816, 817, 818, 819, 820, 821, 820, 819, 818, 817, 816, 815, 816, 817, 818, 819, 820, 821, 820, 819, 818, 817, 816, 815, 814, 813, 812, 811, 810, 809, 808, 807, 806, 801]
			},
			
			'idle2': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				standin_frame: 801, // must be in base sheet!
				framesA: [801, 852, 853, 854, 855, 856, 857, 858, 859, 860, 861, 861, 861, 860, 859, 858, 857, 856, 855, 854, 853, 852, 874, 875, 876, 877, 878, 879, 880, 881, 882, 883, 884, 885, 886, 887, 888, 889, 890, 891, 892, 852, 853, 854, 855, 856, 857, 858, 859, 860, 861, 861, 861, 860, 859, 858, 857, 856, 855, 854, 853, 852, 801, 914, 915, 916, 917, 918, 919, 920, 921, 922, 923, 924, 925, 926, 927, 928, 929, 930, 931, 932, 933, 934, 935, 936, 937, 938, 939, 940, 941, 801, 801, 801]
			},
			
			'idle3': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				standin_frame: 801, // must be in base sheet!
				framesA: [801, 946, 947, 948, 949, 950, 951, 952, 953, 954, 955, 956, 957, 958, 959, 960, 961, 961, 961, 961, 961, 961, 961, 961, 961, 961, 961, 961, 961, 974, 975, 976, 977, 978, 979, 980, 981, 982, 983, 984, 985, 986, 987, 988, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 989, 1030, 1031, 1032, 1033, 1034, 1035, 1036, 1037, 1038, 1039, 1040, 1041, 1042, 1043, 1044, 1045, 1046, 1047, 801]
			},
			
			'idle4': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				standin_frame: 801, // must be in base sheet!
				framesA: [1049, 1050, 1051, 1052, 1053, 1054, 1055, 1056, 1057, 1058, 1059, 1060, 1061, 1062, 1063, 1064, 1065, 1066, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1067, 1093, 1094, 1095, 1096, 1097, 1098, 1099, 1100, 1101, 1102, 1103, 1103, 1103, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, 1114, 1115, 1116, 1117, 1118, 1119, 1120, 1121, 1122, 1123, 1124, 1125, 1126, 1049, 1049, 1049, 1049, 1049, 1049, 1049, 1049, 1049, 1049, 1049, 1049, 1049, 1049, 1049, 1049, 1049, 1049]
			},
			
			'climb': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				standin_frame: 0, // must be in base sheet! We use 0 here so ti falls back to placeholder instead of showing a frame from the side view
				framesA: [1145, 1146, 1147, 1148, 1149, 1150, 1151, 1152, 1153, 1154, 1155, 1156, 1157, 1158, 1159, 1160, 1161, 1162, 1163]
			},
			
			'do': {
				sheet:'', // gets populated by init
				sheets_requiredA: [], // gets populated by init
				standin_frame: 801, // must be in base sheet!
				framesA: [1164, 1165, 1166, 1167, 1168, 1169, 1170, 1171, 1172, 1173, 1174, 1175, 1176, 1177, 1178, 1179, 1180, 1181, 1182, 1183, 1184, 1185, 1186, 1187, 1188, 1189, 1190, 1191, 1192, 1193, 1194, 1195, 1196, 1197, 1198, 1199, 1200, 1201, 1202, 1203, 1204, 1205, 1206, 1207, 1208, 1209, 1210, 1211, 1212, 1213, 1214, 1215, 1216, 1217, 1218, 1219, 1220, 1221, 1222, 1223, 1224, 1225, 1226, 1227, 1228, 1229, 1230, 1231, 1232, 1233]
			}
		};
		
		private static function getFrameUsage():Object {
			var totalFramesA:Array = getTotalFramesInUse();
			var uniqueFramesA:Array = VectorUtil.unique(totalFramesA);
			var fnsH:Object = {};
			var reusedFramesA:Array = [];
			var reusedByOtherAnimsFramesA:Array = [];
			
			
			var fnH:Object;
			var def:Object;
			var anim:String;
			var anim_framesA:Array;
			var fn:int;
			var i:int;
			var m:int;
			for (i=0;i<uniqueFramesA.length;i++) {
				fn = uniqueFramesA[int(i)];
				fnH = fnsH[fn] = {
					use_count: 0,
					animsA: [], // an array of anim names using this frame
					animsH: {
						// here will will put keys for the animations using this frame, with values being the number of times it is used
					}
				};
				
				for (anim in defs) {
					anim_framesA = getFramesForAnim(anim, false);
					if (anim_framesA.indexOf(fn) > -1) {
						fnH.animsA.push(anim);
						fnH.animsH[anim] = {
							indexA: [] // the indexes in this animation's framesA where this fn appears
						};
						for (m=0;m<anim_framesA.length;m++) {
							if (anim_framesA[m] == fn) {
								fnH.animsH[anim].indexA.push(m);
								fnH.use_count++;
								
								// add it to the reusedFramesA if we should!
								if (fnH.use_count > 1) {
									if (reusedFramesA.indexOf(fn) == -1) reusedFramesA.push(fn);
									
								};
								// add it to the reusedByOtherAnimsFramesA if we should!
								if (fnH.animsA.length > 1) {
									if (reusedByOtherAnimsFramesA.indexOf(fn) == -1) reusedByOtherAnimsFramesA.push(fn);
								};
							};
						};
					};
				};
				
				fnH.animsA.sort();
			};
			
			uniqueFramesA.sort(Array.NUMERIC);
			totalFramesA.sort(Array.NUMERIC);
			reusedFramesA.sort(Array.NUMERIC);
			reusedByOtherAnimsFramesA.sort(Array.NUMERIC);
			var usage:Object = {
				totalFramesA: totalFramesA,
				uniqueFramesA: uniqueFramesA,
				reusedFramesA: reusedFramesA,
				reusedByOtherAnimsFramesA: reusedByOtherAnimsFramesA,
				fnsH: fnsH
			};
			
			
			return usage;
		}
	}
}