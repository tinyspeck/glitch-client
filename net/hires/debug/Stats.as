/**
 * Stats
 * 
 * Released under MIT license:
 * http://www.opensource.org/licenses/mit-license.php
 *
 * How to use:
 * 
 *	addChild(new Stats());
 *	
 *	or
 *	
 *	addChild(new Stats({ bg: 0xffffff });
 **/
package net.hires.debug
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.model.TSEngineConstants;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	
	/** System.privateMemory is apparenly very expensive to call */
	CONFIG const use_pvt_memory:Boolean = false;
	
	public class Stats extends Sprite
	{	
		public static const WIDTH:uint = 220;
		public static const HEIGHT:uint = 140;
		
		private static const GRAPH_RANGES:int = 3;
		private static const GRAPH_BUFFER_PX:int = 3;
		private static const GRAPH_RANGE_PX:int = int((HEIGHT - GRAPH_BUFFER_PX*GRAPH_RANGES - 1) / GRAPH_RANGES);
		
		private const xml:XML =
			<xml>
				<physics_fps/>
				<fps/>
				<pvt_mem/>
				<mem/>
				<free_mem/>
				<ping/>
			</xml>;
		
		private var text:TextField;
		private var style:StyleSheet;
		
		private var frames:uint;
		private var physics_frames:uint;
		private var ms_prev:uint;
		private var mem:uint;
		private var mem_max:uint = 0;
		CONFIG::use_pvt_memory private var pvt_mem_max:uint = 0;
		CONFIG::use_pvt_memory private var pvt_mem:uint;
		private var free_mem:uint;
		
		private var graph:Bitmap;
		private var verticalColumn:Rectangle;
		private var leftColumn:Rectangle;
		private var rightColumn:Rectangle;
		
		private var fps_graph:Number;
		private var physics_fps_graph:Number;
		private var mem_graph:Number;
		CONFIG::use_pvt_memory private var pvt_mem_graph:Number;
		private var free_mem_graph:Number;
		private var ping_graph:Number;
		
		private const theme:Object = {
			bg: 0x0A0A0A,
			base:0x141414,
			midpoint:0x303030,
			physics_fps: 0x3381F4,
			fps: 0xFFFFFF,
			pvt_mem: 0x832FE0,
			mem: 0xFFFFFF,
			free_mem: 0x62C400,
			ping: 0xEEEEEE
		};
		
		public function Stats():void {
			style = new StyleSheet();
			style.setStyle("xml",  {fontSize:'11px', fontFamily:'_sans', leading:'-2px'});
			style.setStyle("physics_fps",  {color: hex2css(theme.physics_fps)});
			style.setStyle("fps",  {color: hex2css(theme.fps), leading:'20px'});
			style.setStyle("pvt_mem",  {color: hex2css(theme.pvt_mem)});
			style.setStyle("mem",  {color: hex2css(theme.mem)});
			style.setStyle("free_mem",  {color: hex2css(theme.free_mem), leading:'20x'});
			style.setStyle("ping", {color: hex2css(theme.ping)});
			
			text = new TextField();
			text.y = 5;
			text.width = WIDTH;
			text.height = HEIGHT - text.y;
			text.styleSheet = style;
			text.condenseWhite = true;
			text.selectable = false;
			text.mouseEnabled = false;
			
			graph = new Bitmap(new BitmapData(WIDTH, HEIGHT, false, theme.bg));
			verticalColumn = new Rectangle((WIDTH - 1), 0, 1, 0);
			leftColumn = new Rectangle(0, 0, WIDTH, HEIGHT);
			rightColumn = new Rectangle(WIDTH - 1, 0, 1, HEIGHT);
			
			graphics.beginFill(theme.bg);
			graphics.drawRect(0, 0, WIDTH, HEIGHT);
			graphics.endFill();
			
			addChild(graph);
			addChild(text);
			
			addEventListener(Event.ADDED_TO_STAGE, init, false, 0, true);
			addEventListener(Event.REMOVED_FROM_STAGE, destroy, false, 0, true);
		}
		
		private function init(e:Event):void {
			StageBeacon.enter_frame_sig.add(onEnterFrame);
			StageBeacon.game_loop_sig.add(onGameLoop);
		}
		
		private function destroy(e:Event):void {
			graphics.clear();
			
			while (numChildren > 0) {
				removeChildAt(0);
			}
			
			graph.bitmapData.dispose();
			StageBeacon.enter_frame_sig.remove(onEnterFrame);
			StageBeacon.game_loop_sig.remove(onGameLoop);
		}
		
		private function onGameLoop(ms_elapsed:int):void {
			ms_prev += ms_elapsed;
			physics_frames++;
			if(ms_prev >= 1000) {
				refresh();
				frames = 0;
				physics_frames = 0;
				// remainders are usually very small
				// and the point is not to accurately fire every second
				// but merely TO fire approximately every second
				//ms_prev -= 1000;
				ms_prev = 0;
			}
		}
		
		private function onEnterFrame(ms_elapsed:int):void {
			frames++;
		}
		
		private function refresh():void {
			graph.bitmapData.scroll(-1, 0);
			graph.bitmapData.fillRect(rightColumn, theme.bg);
			
			var base:int  = GRAPH_BUFFER_PX;
			var peak:int  = base + GRAPH_RANGE_PX;
			
			// separators
			drawLine(base, GRAPH_RANGE_PX, theme.base);
			draw(0.5, base, GRAPH_RANGE_PX, theme.midpoint);
			
			ping_graph = Math.min(1, (TSTweener.getActiveTweenCount() / 20));
			
			draw(ping_graph, base, GRAPH_RANGE_PX, theme.ping);
			
			// next range
			peak += GRAPH_RANGE_PX + GRAPH_BUFFER_PX;
			base += GRAPH_RANGE_PX + GRAPH_BUFFER_PX;
			
			// separators
			drawLine(base, GRAPH_RANGE_PX, theme.base);
			draw(0.5, base, GRAPH_RANGE_PX, theme.midpoint);
			
			// convert bytes to megabytes
			mem         = int(System.totalMemoryNumber * (1/(1024*1024)) + 0.5);
			mem_max     = (mem_max > mem ? mem_max : mem);
			CONFIG::use_pvt_memory {
				pvt_mem     = int(System.privateMemory     * (1/(1024*1024)) + 0.5);
				pvt_mem_max = (pvt_mem_max > pvt_mem ? pvt_mem_max : pvt_mem);
			}
			free_mem    = int(System.freeMemory        * (1/(1024*1024)) + 0.5);
			
			free_mem_graph = Math.min(1, (free_mem / 1024));
			mem_graph      = Math.min(1, (mem      / 1024));
			CONFIG::use_pvt_memory {
				pvt_mem_graph  = Math.min(1, (pvt_mem  / 1024));
			}
			
			//draw(mem_max_graph, base, GRAPH_RANGE_PX, theme.mem_max);
			CONFIG::use_pvt_memory {
				draw(pvt_mem_graph, base, GRAPH_RANGE_PX, theme.pvt_mem);
			}
			draw(free_mem_graph, base, GRAPH_RANGE_PX, theme.free_mem);
			draw(mem_graph, base, GRAPH_RANGE_PX, theme.mem);
			
			// next range
			peak += GRAPH_RANGE_PX + GRAPH_BUFFER_PX;
			base += GRAPH_RANGE_PX + GRAPH_BUFFER_PX;
			
			physics_fps_graph = Math.min(1, (physics_frames / TSEngineConstants.TARGET_PHYSICS_FRAMERATE));
			fps_graph = Math.min(1, (frames / TSEngineConstants.TARGET_PHYSICS_FRAMERATE));
			
			// separators
			drawLine(base, GRAPH_RANGE_PX, theme.base);
			draw(0.5, base, GRAPH_RANGE_PX, theme.midpoint);
			
			draw(physics_fps_graph, base, GRAPH_RANGE_PX, theme.physics_fps);
			draw(fps_graph, base, GRAPH_RANGE_PX, theme.fps);
			
			// clear out bitmap data under the text
			leftColumn.width = text.textWidth + 8;
			graph.bitmapData.fillRect(leftColumn, theme.bg);
			
			xml.physics_fps = "FPS (PHYSICS): " + physics_frames + " / " + TSEngineConstants.TARGET_PHYSICS_FRAMERATE;
			xml.fps         = "FPS (RENDER): " + frames + " / " + stage.frameRate;
			xml.mem         = "MEM (USED): " + Math.round(mem) + " / " + Math.round(mem_max);
			CONFIG::use_pvt_memory {
				xml.pvt_mem     = "MEM (PVT): " + Math.round(pvt_mem) + " / " + Math.round(pvt_mem_max);
			}
			xml.free_mem    = "MEM (FREE): " + Math.round(free_mem);
			xml.ping        = "TWEENS: " + Math.round(TSTweener.getActiveTweenCount());
			text.htmlText = xml;
		}
		
		private function draw(value:Number, base:int, range:int, color:uint):void {
			graph.bitmapData.setPixel((graph.width - 1), (HEIGHT - base - (range * value)), color);
		}
		
		private function drawLine(base:int, range:int, color:uint):void {
			verticalColumn.y = (HEIGHT - base - range);
			verticalColumn.height = range;
			graph.bitmapData.fillRect(verticalColumn, color);
		}
		
		// .. Utils
		
		private static function hex2css(color:int):String {
			return "#" + color.toString(16);
		}
		
		override public function toString():String {
			return ("[" + xml.fps + ", " + xml.physics_fps + ", " + xml.mem + ", " + (CONFIG::use_pvt_memory ? xml.pvt_mem + ", " : '') + xml.free_mem + ", " + xml.ping + "]");
		}
	}
}
