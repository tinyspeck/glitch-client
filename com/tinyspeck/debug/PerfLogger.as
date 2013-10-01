package com.tinyspeck.debug {
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	
	import flash.system.System;
	import flash.utils.getTimer;

	CONFIG const REPORTS_PER_MINUTE:int = 12;
	CONFIG const LOG_FREQUENCY_MS:int = (60 * 1000 / CONFIG::REPORTS_PER_MINUTE);
	CONFIG const FPS_SAMPLES_PER_REPORT:int = (60 / CONFIG::REPORTS_PER_MINUTE);
	
	public class PerfLogger {
		// these vars are used to avoid dependencies on the TSModelLocator
		public static var logged_in:Boolean;
		public static var retries:uint = 0;
		
		private static const frames_values:Vector.<uint> = new Vector.<uint>(CONFIG::FPS_SAMPLES_PER_REPORT, true);
		private static var next_frames_values_index:uint = 0;
		private static var frames:uint = 0;
		private static var physics_frames:uint = 0;
		private static var ms_prev:uint = 0;
		
		private static var last_sent_ms:uint;
		private static var bytes_loaded:Number = 0;
		private static var secs_spent_loading:Number = 0;
		private static var total_bytes_loaded:Number = 0;
		private static var total_secs_spent_loading:Number = 0;
		private static var io_errors:uint = 0;
		private static var l500_errors:uint = 0;
		private static var long_loads:uint = 0;
		private static var no_content_errors:uint = 0;
		
		private static var running:Boolean;
		
		private static var flashVarModel:FlashVarModel;
		
		public static function init(flashVarModel:FlashVarModel):void {
			PerfLogger.flashVarModel = flashVarModel;
			
			StageBeacon.game_loop_sig.add(onGameLoop);
			StageBeacon.enter_frame_sig.add(onEnterFrame);
		}
		
		private static function onGameLoop(ms_elapsed:int):void {
			ms_prev += ms_elapsed;
			physics_frames++;
			if(ms_prev >= 1000) {
				frames_values[next_frames_values_index++] = frames;
				if (next_frames_values_index == CONFIG::FPS_SAMPLES_PER_REPORT) {
					maybeLogPerformance()
					next_frames_values_index = 0;
				}
				// remainders are usually very small
				// and the point is not to accurately fire every second
				// but merely TO fire approximately every second
				//ms_prev -= 1000;
				ms_prev = 0;
			}
		}
		
		private static function onEnterFrame(ms_elapsed:int):void {
			frames++;
		}
		
		public static function startLogging():void {
			resetStats();
			running = true;
		}
		
		public static function stopLogging():void {
			running = false;
		}
		
		public static function addIOError(url:String):void {
			io_errors++;
		}
		
		public static function addLongLoad(url:String):void {
			long_loads++;
		}
		
		public static function add500Error(url:String):void {
			l500_errors++;
		}
		
		public static function addNoContentError(url:String):void {
			no_content_errors++;
		}
		
		public static function addRetry(url:String):void {
			retries++;
		}
		
		public static function addBytesLoadedData(bytes:Number, secs:Number, title:String=''):void {
			// We're only going to use things that 1) are big enough and 2) take long enough to load.
			// This is an attempt to weed out loads from browser cache
			
			var kps:Number = (bytes/1024)/secs;
			
			total_bytes_loaded+= bytes;
			total_secs_spent_loading+= secs;
			
			if (bytes < 50*1024) { // less than 50kb, throw it away
				CONFIG::debugging {
					Console.priwarn(267, 'too small '+(bytes/1024)+' in '+secs+' '+kps+'kps '+title);
				}
				return;
			}
			
			if (secs < .26) { // loaded too quickly throw it away
				CONFIG::debugging {
					Console.priwarn(267, 'too quick '+(bytes/1024)+' in '+secs+' '+kps+'kps '+title);
				}
				return;
			}
			
			CONFIG::debugging {
				Console.trackValue(' PL.total_bytes_loaded', total_bytes_loaded);
				Console.trackValue(' PL.total_secs_spent_loading', total_secs_spent_loading);
				Console.trackValue(' PL.mbps', (total_bytes_loaded/131072)/total_secs_spent_loading);
			}
			
			bytes_loaded+= bytes;
			secs_spent_loading+= secs;
			
			CONFIG::debugging {
				Console.priinfo(267, 'just right '+(bytes/1024)+' in '+secs+' '+kps+'kps '+title);
			}
		}
		
		private static function maybeLogPerformance():void {
			if (running && logged_in && !CONFIG::god) {
				const secs:Number = ((getTimer() - last_sent_ms) / 1000);
				const fps:Number = (frames / secs);
				const physics_fps:Number = (physics_frames / secs);
				const bps:Number = (bytes_loaded ? (bytes_loaded / secs_spent_loading) : 0);
				const log_to_bucket_and_normal:Boolean = true;

				// frames_values contains the summed frame counts for each recorded second
				// e.g. [20, 40, 60, 80, 100] for a constant 20fps
				const sum:Number = frames_values[CONFIG::FPS_SAMPLES_PER_REPORT-1];
				const avg:Number = sum / CONFIG::FPS_SAMPLES_PER_REPORT;
				
				// now convert the data to the actual frames elapsed each second:
				var i:uint = CONFIG::FPS_SAMPLES_PER_REPORT;
				while (--i) {
					frames_values[i] -= frames_values[i-1];
				}
				// now we have [20, 20, 20, 20, 20]
				
				var variance:Number = 0;
				for each (var val:Number in frames_values) {
					variance += (val - avg)*(val - avg);
				}
				variance /= CONFIG::FPS_SAMPLES_PER_REPORT;
				const fps_std_dev:Number = Math.sqrt(variance);
				
				var bucket:String;
				
				API.logPerformance(
					fps,
					fps_std_dev,
					physics_fps,
					System.totalMemoryNumber,
					bps,
					retries,
					StageBeacon.isActivelyPlaying(),
					io_errors,
					l500_errors,
					long_loads,
					no_content_errors,
					bucket,
					log_to_bucket_and_normal
				);
			}
			
			resetStats();
		}
		
		private static function resetStats():void {
			ms_prev = 0;
			last_sent_ms = getTimer();
			frames = 0;
			next_frames_values_index = 0;
			physics_frames = 0;
			retries = 0;
			secs_spent_loading = 0;
			bytes_loaded = 0;
			io_errors = 0;
			l500_errors = 0;
			long_loads = 0;
			no_content_errors = 0;
		}
	}
}
