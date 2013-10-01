package com.tinyspeck.engine.util
{
	import com.adobe.serialization.json.JSON;
	import com.tinyspeck.engine.loader.SmartLoaderError;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.utils.getQualifiedClassName;

	final public class StringUtil
	{
		public static function formatNumber(n:Number, after_dec:int):String {
			if (parseInt(String(n)) != n) return String(n.toFixed(after_dec));
			return String(n);
		}
		
		public static function getJsonStr(ob:Object):String {
			var str:String = ''
			try {
				str = com.adobe.serialization.json.JSON.encode(ob)
			} catch(e:Error) {
				str = '[COULD NOT GET JSON '+e+']';
			}
			
			return str;
		}
		
		public static function truncate(str:String, max:int, start_from_end:Boolean = false):String {
			const trail:String = '...';
			if (!str) return '';
			if (str.length > max){
				if(!start_from_end){
					return str.substr(0, max - trail.length) + trail;
				}
				else {
					return trail + str.substr(-max + trail.length);
				}
			}
			return str;
		}
		
		public static function formatNumberWithCommas(n:Number):String {
			var i:Number = Math.floor(n);
			var diff:Number = Number((n-i).toFixed(3));
			var decimal:String = (diff) ? '.'+diff.toString().replace('0.', '') : '';
			var str:String = Math.abs(i).toString();
			var result:String = '';
			var neg_prefix:String = String(i).substr(0,1);
			
			if(neg_prefix != '-') neg_prefix = '';
			
			while (str.length > 3) {
				var chunk:String = str.substr(-3)
				str = str.substr(0, str.length - 3)
				result = ',' + chunk + result
			}
			if (str.length > 0) result = neg_prefix + str + result + decimal;
			return result
		}
		
		public static function trim(p_string:String):String {
			if (p_string == null) { return ''; }
			return p_string.replace(/^\s+|\s+$/g, '');
		}
		
		public static function linkify(txt:String, class_name:String = ''):String {
			//[SY] Modified version from RegExr to add support for name/value pairs (Rollback changelist ID is 43955)
			const r:RegExp = /((https?:\/\/)|(www\.))([a-zA-Z0-9-\.]*)\b\.[a-z]{2,4}(\.[a-z]{2})?((\/[a-zA-Z0-9-@!:%_\+\.~#?&\/=]*)+)?(\.[a-z]*)?(\\?[a-zA-Z0-9-@!:%_\+\.~#?&\/=]*)?/g;
			txt = txt.replace(/&amp;/gi, '&');
			txt = txt.replace(r, getLink);
			
			function getLink():String {
				//arguments[0] - the URL
				const punc:Array = new Array('?', '!', '.');
				
				var url:String = arguments[0];
				var last_char:String = url.substr(-1, 1);
				var add_last_char:Boolean;
								
				//check if the last character is some puncuation
				if(punc.indexOf(last_char) != -1){
					url = url.substr(0, url.length-2);
					add_last_char = true;
				}
				
				return '<a target="_blank" href="'+(url.indexOf('://') == -1 ? 'http://'+url : url)+'" class="'+class_name+'">'+
					   	url+'</a>'+(!add_last_char ? '' : last_char);
			}
			
			return txt;
		}
		
		/**
		 * Injects class="class_name" to the specified tag 
		 * @param txt
		 * @param html_tag
		 * @param class_name
		 * @return a string with the class_name injected
		 * 
		 */		
		public static function injectClass(txt:String, html_tag:String, class_name:String):String {
			//HINT: if you make the html_tag pipe separated you can apply the same class name to different tags
			
			//check to make class isn't already set
			var chunks:Array = html_tag.split('|');
			var good:Array = new Array();
			var i:int;
			var pattern:RegExp;
			
			for(i; i < chunks.length; i++){
				if(txt.indexOf(chunks[int(i)]+' class="') == -1){
					good.push(chunks[int(i)]);
				}
			}
			
			if(good.length == 0){
				//nothing to do, return the txt
				return txt;
			}
			
			html_tag = good.join('|');
			
			pattern = new RegExp('<('+html_tag+')( (.*?))?>', 'gi');
			txt = txt.replace(pattern, '<$1 class="'+class_name+'"$2>');
			
			return txt;
		}
		
		/**
		 * Useful when wanting to replace a tag with another tag eg. b with span 
		 * @param txt
		 * @param old_html_tag
		 * @param new_html_tag
		 * @param class_name - optional you can specifiy a class name the new tag will tag
		 * @param extra - optional you can specifiy other things to add to the element. ie. color="#00000"
		 * @return a new string with the tags replaced
		 * 
		 */		
		public static function replaceHTMLTag(txt:String, old_html_tag:String, new_html_tag:String, class_name:String = '', extra:String = ''):String {			
			var pattern:RegExp = new RegExp('<('+old_html_tag+')( (.*?))?>', 'gi');
			txt = txt.replace(pattern, '<'+new_html_tag+(class_name != '' ? ' class="'+class_name+'"' : '')+'$2'+(extra != '' ? ' '+extra : '')+'>');
			
			pattern = new RegExp('</('+old_html_tag+')?>', 'gi');
			txt = txt.replace(pattern, '</'+new_html_tag+'>');
			
			return txt;
		}
		
		public static function removeHTMLTag(txt:String, html_tag:String):String {
			var pattern:RegExp = new RegExp('<('+html_tag+')( (.*?))?>', 'gi');
			txt = txt.replace(pattern, '');
			
			pattern = new RegExp('</('+html_tag+')?>', 'gi');
			txt = txt.replace(pattern, '');
			
			return txt;
		}
		
		public static function formatSecsAsDigitalClock(total_secs:int, pad_non_secs:Boolean = true):String {
			if (!total_secs) return pad_non_secs ? '00:00:00' : '0';
			var hours:int = Math.floor(total_secs/(60*60));
			var minutes:int = Math.floor(total_secs/60)-(hours*60);
			var seconds:int = total_secs-(hours*60*60)-(minutes*60);
			
			if(pad_non_secs){
				return padNumber(hours, 2)+':'+padNumber(minutes, 2)+':'+padNumber(seconds, 2);
			}
			else {
				//if we are not padding the hours and minutes, return that jazz here
				var final_str:String = hours > 0 ? hours+':' : '';
				final_str += minutes > 0 ? (hours > 0 ? padNumber(minutes, 2)+':' : minutes+':') : (hours > 0 ? '00:' : '');
				final_str += (final_str ? '' : ':')+padNumber(seconds, 2);
				return final_str;
			}
		}
		
		public static function formatTime(sec:int, display_sec_txt:Boolean = true, use_short_form:Boolean = false, max_to_show:int = 0):String {
			//returns seconds in a readable string ie. 5 mins 30 secs			
			var sec_txt:String = sec % 60 + (!use_short_form ? ((sec % 60 == 1) ? ' sec' : ' secs') : ' sec');
			var mins_left:int = Math.floor(sec / 60) % 60;
			var min_txt:String = (mins_left > 0) ? (mins_left + (!use_short_form ? (mins_left == 1 ? ' min' : ' mins') : ' min')) : '';
			var hours_left:int = Math.floor(sec / 3600) % 24;
			var hour_txt:String = (hours_left > 0) ? (hours_left + (!use_short_form ? (hours_left == 1 ? ' hour' : ' hours') : ' hr')) : '';
			var days_left:int = Math.floor(sec / 86400);
			var day_txt:String = (days_left > 0) ? formatNumberWithCommas(days_left) + ((days_left == 1) ? ' day' : ' days') : '';
			
			if(sec % 60 == 0 || !display_sec_txt) sec_txt = '';
			if(min_txt != '' && sec_txt != '') min_txt += ' ';
			if(hour_txt != '' && (min_txt != '' || sec_txt != '')) hour_txt += ' ';
			if(day_txt != '' && (hour_txt != '' || min_txt != '' || sec_txt != '')) day_txt += ' ';
			
			//if the max_to_show was anything higher than 0, than start triming off the end ones until we reach max_to_show
			if(max_to_show > 0){
				var current_showing:Array = new Array();
				var show_approx:Boolean;
				
				if(day_txt != '') current_showing.push(day_txt);
				if(hour_txt != '') current_showing.push(hour_txt);
				if(min_txt != '') current_showing.push(min_txt);
				if(sec_txt != '') current_showing.push(sec_txt);
				
				while(current_showing.length > max_to_show){
					current_showing.pop();
					show_approx = true;
				}
				
				var output_txt:String = current_showing.join('');
				if(output_txt.substr(-1, 1) == ' ') output_txt = output_txt.substr(0, output_txt.length-1);
				
				//put a ~ there since we are chopping off extra time to make space
				return (show_approx ? '~' : '')+output_txt;
			}
			
			//start triming off some fat if we are way over on time
			if(hours_left > 8 && !display_sec_txt){
				min_txt = sec_txt = '';
				hour_txt = hour_txt.substr(0,-1); //remove space at end
			} 
			if(days_left > 1 && !display_sec_txt) {
				hour_txt = min_txt = sec_txt = '';
				day_txt = day_txt.substr(0,-1); //remove space at end
			}
			
			return day_txt + hour_txt + min_txt + sec_txt;
		}
		
		public static function getTimeFromDate(date:Date, show_seconds:Boolean = true, no_date:Boolean = false, show_year:Boolean = false, short_month_name:Boolean = true):String {
			const month:String = getMonthFromDate(date, short_month_name);
			const day:String = date.date.toString();
			
			var hour:String = date.hours > 12 ? String(date.hours - 12) : date.hours.toString();
			if(hour == '0') hour = '12';
			const min:String = date.minutes < 10 ? '0'+date.minutes : date.minutes.toString();
			const sec:String = date.seconds < 10 ? '0'+date.seconds : date.seconds.toString();
			const am_pm:String = date.hours >= 12 ? 'PM' : 'AM';
			
			const date_str:String = month+' '+day+(show_year ? ', '+date.fullYear : '');
			const time:String = hour+':'+min+(show_seconds ? ':'+sec : '')+am_pm;
			
			return (no_date ? '' : date_str+' ')+time;
		}
		
		public static function getTimeFromUnixTimestamp(ts:int, show_seconds:Boolean, no_date:Boolean, show_year:Boolean = false, short_month_name:Boolean = true):String {
			var txt:String;
			var date:Date = new Date();
			
			//convert the ts to a date object
			date.setTime(ts*1000); //flash does timestamps in ms
			
			//build the time			
			txt = getTimeFromDate(date, show_seconds, no_date, show_year, short_month_name);
			
			return txt;
		}
		
		public static function stripHTML(str:String):String {			
			var pattern:RegExp = /<(.|\n)*?>/g;
			
			return str.replace(pattern, '');
		}
		
		public static function stripDoubleQuotes(str:String):String {
			return str.replace(/"/g,'');
		}
		
		public static function cssHexToUint(str:String):uint {
			// remove preceeding #
			if(str.indexOf('#') == 0) str = str.substring(1);
			
			return uint('0x' + str);
		}
		
		public static function capitalizeFirstLetter(str:String):String {
			if (!str) return str;
			return str.substring(0,1).toUpperCase() + str.substring(1);
		}
		
		public static function unCapitalizeFirstLetter(str:String):String {
			if (!str) return str;
			return str.substring(0,1).toLowerCase() + str.substring(1);
		}
		
		public static function capitalizeWords(str:String):String {
			var string:String = '';
			var words:Array = str.split(' ');
			var first_letter:String;
			var left_over:String;
			
			for(var i:int = 0; i < words.length; i++){
				first_letter = String(words[int(i)].substring(0,1)).toUpperCase();
				left_over = String(words[int(i)].substring(1));
				string += first_letter + left_over;
				if(i < words.length-1) string += ' ';
			}
			
			return string;
		}
		
		public static function aOrAn(str:String):String {
			var fl:String = str.substr(0,1).toLowerCase();
			
			if(fl == 'a' || fl == 'e' || fl == 'i' || fl == 'o' || fl == 'u'){
				return 'an';
			}
			
			return 'a';
		}
		
		public static function underlineLetter(word:String, letter:String):String {
			//we check lower and upper instead of using "i" so we know how to replace it
			var checkUpper:RegExp = new RegExp(letter.toUpperCase());
			var checkLower:RegExp = new RegExp(letter.toLowerCase());
			
			if(word.match(checkUpper)){
				word = word.replace(checkUpper, '<u>'+letter.toUpperCase()+'</u>');
			}
			else {
				word = word.replace(checkLower, '<u>'+letter.toLowerCase()+'</u>');
			}
			
			return word;
		}
		
		public static function crunchNumber(num:Number, decimal_places:int = 1):String {
			//take a number and crunch it down eg. 2000 becomes 2K or 1500 becomes 1.5K or 1234 becomes 1.2K
			var append:String = '';
			var div_by:Number = 1;
			var final_num:Number;
			var final_str:String = formatNumberWithCommas(num);
			
			if(num >= 1000 && num < 1000000){
				append = 'K';
				div_by = 1000;
			}
			else if(num >= 1000000 && num < 1000000000){
				append = 'M';
				div_by = 1000000;
			}
			else if(num >= 1000000000 && num < 1000000000000){
				append = 'B';
				div_by = 1000000000;
			}
			else if(num >= 1000000000000){
				append = 'T';
				div_by = 1000000000000;
			}
			else if(num >= 1000000000000000) {
				return 'That number is just stupid large now, come on!';
			}
			
			final_num = num/div_by;
			
			//check for a decimal
			if(String(final_num).indexOf('.') >= 0){
				//round it to the decimal places
				final_str = final_num.toFixed(decimal_places) + append;
			}
			else if(append != ''){
				final_str = final_num + append;
			}
			
			return final_str;
		}
		
		public static function padString(str:String, len:uint, rightPad:Boolean=false, sym:String=' '):String {
			var newStr:String = "";
			const max:int = Math.max(0, len - str.length);
			for (var i:uint = 0; i < max; i++)
				newStr += sym;
			return (rightPad ? (str + newStr) : (newStr + str));
		}
		
		public static function padNumber(num:int, width:int):String {
			var padd:String = '' + num;
			
			while(padd.length < width){
				padd = '0' + padd;
			}
			
			return padd;
		}
		
		public static function getColonDateInGMT(d:Date):String {
			return d.getUTCFullYear()+':'+padNumber(d.getUTCMonth()+1, 2)+':'+padNumber(d.getUTCDate(), 2)+' '+padNumber(d.getUTCHours(), 2)+':'+padNumber(d.getUTCMinutes(), 2)+':'+padNumber(d.getUTCSeconds(), 2)+':'+padNumber(d.getUTCMilliseconds(), 3);
		}
		
		public static function getUrlDate(d:Date):String {
			return d.getFullYear()+'_'+padNumber(d.getMonth()+1, 2)+'_'+padNumber(d.getDate(), 2)+'-'+padNumber(d.getHours(), 2)+'_'+padNumber(d.getMinutes(), 2)+'_'+padNumber(d.getSeconds(), 2);
		}
		
		/**
		 * Adds the st, nd, rd, or th after the number
		 * @param num
		 * @return String of the new number with the suffix attached
		 */		
		public static function addSuffix(num:int):String {						
			var suffix:Array = ['th','st','nd','rd'];
			var str:String = String(Math.abs(num)); //dont' want no negatives effin' things up
			var last_two:int = parseInt(str.substring(str.length-2, str.length));
			var base_ten:int = Math.abs(num) % 10;
			
			str = String(num);
			str += ((last_two < 11 || last_two > 19) && (base_ten < 4)) ? suffix[base_ten] : suffix[0];
			
			return str;
		}
		
		public static function escapeRegEx(txt:String):String {
			return txt.replace(new RegExp("([{}\(\)\^$&.\*\?\/\+\|\[\\\\]|\])","g"), "\\$1");
		}
		
		public static function escapeQuotes(txt:String):String {
			return txt.replace(new RegExp("('|\")","g"), "\\$1");
		}
		
		public static function encodeHTMLUnsafeChars(txt:String, include_amp_and_quote:Boolean = true):String {
			if(!txt) return '';
			
			const pattern:RegExp = /<|>|&|"/g;
			
			//nothing to see here
			if(txt.match(pattern).length == 0) return txt;
			
			function convert():String {
				//0 - will be < > & "
				var output:String = '';
				
				switch(arguments[0]){
					case '<':
						output = '&lt;';
						break;
					case '>':
						output = '&gt;';
						break;
					case '&':
						output = include_amp_and_quote ? '&amp;' : '';
						break;
					case '"':
						output = include_amp_and_quote ? '&quot;' : '';
						break;
				}
				
				return output;
			}
			
			return txt.replace(pattern, convert);
		}
		
		public static function replaceNewLineWithSomething(txt:String, replace_with:String = ' '):String {
			var pattern:RegExp = /\r|\n/g;
			
			txt = txt.replace(pattern, replace_with);
			
			return txt;
		}
		
		public static function getMonthFromDate(date:Date, use_short_version:Boolean = true):String {
			const SHORT_FORM:Array = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
			const LONG_FORM:Array = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
			
			return use_short_version ? SHORT_FORM[date.month] : LONG_FORM[date.month];
		}
		
		public static function makeURLExternal(txt:String):String {
			var pattern:RegExp = /href="(http.*?)"/g;
			
			return txt.replace(pattern, "href=\"event:external|$1\"");
		}
		
		public static function DOPath(DO:DisplayObject):String {
			if (!DO) return '';
			var path:String = getShortClassName(DO)+'['+DO.name+']';
			var p:DisplayObjectContainer = DO.parent
			while (p) {
				path = getShortClassName(p)+'['+p.name+'] '+path;
				p = p.parent;
			}
			
			return path;
		}
		
		public static function getShortClassName(ob:Object):String {
			if (!ob) return '';
			var class_name:String = getQualifiedClassName(ob);
			return class_name.slice(class_name.lastIndexOf(':')+1);
		}
		
		public static function getCurrentCodeLocation():String {
			return getCurrentStackTrace(1, 1);
		}
		
		public static function getCallerCodeLocation():String {
			return getCurrentStackTrace(2, 1);
		}
		
		public static function getCurrentStackTrace(start_offset:uint, total:int):String {
			return getShorterStackTrace(new Error(), 1+start_offset, total);
		}
		
		public static function getShorterStackTrace(err:Error, start_offset:uint=0, total:int=999):String {
			// don't fuck up SmartLoaderErrors even if they are verbose
			if (err is SmartLoaderError) return err.getStackTrace();
			var we_want_the_error:Boolean = (start_offset == 0);
			var txt:String = err.getStackTrace();
			var str:String = '';
			var stack_line:String;
			var func_name:String;
			var line_num:Number;
			var start_i:int = 0; // assume we want the whole trace, with the first line specifying the error, but then...

			
			// be safe
			if (!txt) {
				if (we_want_the_error) {
					return err.toString();
				} else {
					return 'no_trace_available';
				}
			}

			var A:Array = txt.split('\n');
			
			if (!we_want_the_error) {
				// we're not looking for the error and there is only one line, so we have no trace to offer
				if (A.length<2) {
					return 'no_trace_available'; // we just wanted the trace
				}
			}
			
			// if it is a simple error and we're not looking for the error, adjust 
			if (A[i] == 'Error' && !we_want_the_error) {
				start_i = 1+start_offset;
			}
			
			for (var i:int=start_i;i<A.length && (i-start_i<total);i++) {
				if (i!=start_i) str+= '\n';
				stack_line = A[i];
				stack_line = stack_line.replace(/\t/g, '');
				func_name = stack_line.split('[')[0];
				
				if (func_name.indexOf('at Function/<anonymous>') == 0) {
					// just put the whole thing in there so we get where it was created.
					// TODO: split it up nicely so it does not have full file paths
					str+= stack_line;
				} else if (we_want_the_error && i == 0) {
					// we want this line intact, the actual error, no matter what
					str+= stack_line;
				} else {
					func_name = (func_name.indexOf('com.tinyspeck') != -1) ? 'at '+func_name.split('::')[1] : func_name;
					line_num = parseInt(stack_line.split(':')[stack_line.split(':').length-1]);
					str+= func_name+((isNaN(line_num)) ? '' : ':'+line_num);
				}
				
			}
			
			return str;
	
		}
		
		public static function deepTrace(obj:*, tabDepth:String=''):String {
			var ret:String = '';
			for (var prop:String in obj) {
				ret += (tabDepth + '[' + prop + '] -> ' + obj[prop] + '\n');
				ret += deepTrace(obj[prop], tabDepth + '\t');
			}
			return ((ret.length > 1) ? ret + '\n' : (obj ? '' : 'null\n'));
		}
		
		public static function msToHumanReadableTime(ms:int):String {
			const s:int = Math.floor(ms / 1000);
			const m:int = Math.floor(s / 60);
			const h:int = Math.floor(m / 60);
			const d:int = Math.floor(h / 24);
			return (
				(d ? d + 'd ' : '') +
				(h ? (h % 24) + 'h ' : '') +
				(m ? (m % 60) + 'm ' : '') +
				(s ? (s % 60) + 's' : ''));
		}
		
		public static function nameApostrophe(name:String, keep_name:Boolean = true):String {
			if(!name) return name;
			//return (keep_name ? name : '')+"’"+(name.toLowerCase().substr(-1,1) != 's' ? 's' : '');
			
			//we don't want to be old times
			return (keep_name ? name : '')+"’s";
		}
		
		/**
		 * Checks if the supplied string can't be rendered by the VAG font set 
		 * @param txt
		 * @return false if VAG can't render it
		 */		
		public static function VagCanRender(txt:String):Boolean {
			const pattern:RegExp = /[^\x00-\xff\u017d\u017e\u0152\u0153\u0160\u0161\u0178\u0192\u02c6\u02dc\u2013\u2014\u2018\u2019\u201a\u201c\u201d\u201e\u2020\u2012\u2022\u2026\u2030\u2039\u203a\u20ac\u2122]/;
			return !pattern.test(txt);
		}
		
		// seems like maybe this only works with PC paths?
		public static const LOCAL_PATH_PATTERN:RegExp = /([A-Z]:\\[^\/:\*\?<>\|]+\.\w{2,6})|(\\{2}[^\/:\*\?<>\|]+\.\w{2,6})/g;
		public static function removeLocalPaths(str:String):String {
			return str.replace(LOCAL_PATH_PATTERN, '');
		}
		
		/**
		 * Useful for finding characters to match and then changing the color of them via the <font> tag 
		 * @param full_str
		 * @param str_to_match
		 * @param css_color_class (will be wrapped in <span> tags
		 * @return formatted string
		 */		
		public static function colorCharacters(full_str:String, str_to_match:String, css_color_class:String):String {
			if(!full_str || !str_to_match) return '';
			
			const pattern:RegExp = new RegExp(str_to_match, 'gi');
			
			//nothing to see here
			if(full_str.match(pattern).length == 0) return full_str;
			
			//match it up and wrap it in the font tags
			function match_str():String {
				return '<span class="'+css_color_class+'">'+arguments[0]+'</span>';
			}
			
			return full_str.replace(pattern, match_str);
		}
	}
}