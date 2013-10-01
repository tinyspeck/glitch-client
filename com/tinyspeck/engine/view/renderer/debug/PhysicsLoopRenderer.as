package com.tinyspeck.engine.view.renderer.debug
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.model.TSModelLocator;
	
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;

	/**
	 * Activated by pressing Q+T.
	 */
	// * CONTROL toggles between showing itemstacks and decos.
	public class PhysicsLoopRenderer extends Sprite
	{
		/* singleton boilerplate */
		public static const instance:PhysicsLoopRenderer = new PhysicsLoopRenderer();
		
		private var shape:Shape = new Shape();
		private var model:TSModelLocator;
		private var w:int;
		private var h:int;
		
		private var perc_of_h_to_use:Number = 1;
		private var perc_of_w_to_use:Number = 1;
				
		public function PhysicsLoopRenderer() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			model = TSModelLocator.instance;
			mouseEnabled = mouseChildren = false;
			visible = false;
			addChild(shape);
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		private function onAddedToStage(event:Event):void {
			StageBeacon.key_down_sig.add(onKeyDown);
		}
		
		private function onKeyDown(event:KeyboardEvent):void {
			//Responds to "e pressed while q is down";
			if(event.keyCode == Keyboard.T && KeyBeacon.instance.pressed(Keyboard.Q)){
				visible = !visible;
			}
		}
		
		public function setSize(w:Number, h:Number):void {
			this.w = w;
			this.h = h;
			graphics.clear();
			graphics.beginFill(0x666666, .4);
			graphics.drawRect(0, 0, w, h);
			graphics.endFill();
		}
		
		public function onEnterFrame(ms_elapsed:Number):void {
			if (!visible) return;
			if (KeyBeacon.instance.pressed(Keyboard.Q)) return;
			
			var g:Graphics = shape.graphics;
			g.clear();
			
			draw(model.physicsModel.physics_time_log, 0xffffff, model.physicsModel.render_time_log, 0xFFE303);
		}
		
		private function draw(A:Array, c:uint, A2:Array, c2:uint):void {
			if (!visible) return;
			if (!A) return;
			if (!A.length) return;
			if (!A2) return;
			if (!A2.length) return;
			
			var g:Graphics = shape.graphics;
			var i:int;
			
			// t = time
			
			var t:int;
			var min_t:int = A[0];
			var max_t:int = A[0];
			
			// find ranges
			
			min_t = Math.min(A[0], A2[0]);
			max_t = Math.max(A[A.length-1], A2[A2.length-1]);
			var delta_t:Number = max_t-min_t;
			
			CONFIG::debugging {
				Console.trackPhysicsValue('  PLRt A', A);
				Console.trackPhysicsValue('  PLRt A2', A2);
				Console.trackPhysicsValue('  PLRt delta_t', delta_t);
				Console.trackPhysicsValue('  PLRt min_t', min_t);
				Console.trackPhysicsValue('  PLRt max_t', max_t);
			}
			
			var this_x:Number;
			var line_start_y:Number;
			var line_h:Number = (h*perc_of_h_to_use)/2;
			
			// first set (game loop)
			line_start_y = ((h-(h*perc_of_h_to_use))/2);
			g.lineStyle(1, c, 1);
			for (i=0;i<A.length;i++) {
				t = A[i];
				
				if (perc_of_w_to_use == 1) {
					this_x = (t-min_t)*(w/delta_t);
				} else {
					this_x = (t-min_t)*((w/delta_t)*perc_of_w_to_use);
					this_x = (w*((1-perc_of_w_to_use)/2))+this_x;
				}
				
				g.moveTo(this_x, line_start_y);
				g.lineTo(this_x, line_start_y+line_h);
			}
			
			// second set (enter frame)
			line_start_y = line_start_y+line_h;
			g.lineStyle(1, c2, 1);
			for (i=0;i<A2.length;i++) {
				t = A2[i];
				
				if (perc_of_w_to_use == 1) {
					this_x = (t-min_t)*(w/delta_t);
				} else {
					this_x = (t-min_t)*((w/delta_t)*perc_of_w_to_use);
					this_x = (w*((1-perc_of_w_to_use)/2))+this_x;
				}
				
				g.moveTo(this_x, line_start_y);
				g.lineTo(this_x, line_start_y+line_h);
			}
			
		}
	}
}