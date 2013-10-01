package com.tinyspeck.engine.view.renderer.debug
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.util.MathUtil;
	
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;

	/**
	 * Activated by pressing Q+R.
	 */
	// * CONTROL toggles between showing itemstacks and decos.
	public class PhysicsMovementRenderer extends Sprite
	{
		/* singleton boilerplate */
		public static const instance:PhysicsMovementRenderer = new PhysicsMovementRenderer();
		
		private var model:TSModelLocator;
		private var shape:Shape = new Shape();
		private var w:int;
		private var h:int;
		
		private var perc_of_h_to_use:Number = .9;
		private var perc_of_w_to_use:Number = .92;
		
		private var x_index:int = 0;
		private var y_index:int = 1;
		private var t_index:int = 2;
		private var vx_index:int = 3;
		private var pxsec_from_nvx_index:int = 4;
		private var pxsec_from_diff_index:int = 5;
		private var nvx_index:int = 6;
		private var diffx_index:int = 7;
		private var ms_index:int = 8;
		private var smoothA:Array = [];
				
		public function PhysicsMovementRenderer() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			mouseEnabled = mouseChildren = false;
			visible = false;
			model = TSModelLocator.instance;
			addChild(shape);
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		private function makeSmoothA():void {
			smoothA.length = 0;
			// create a proof of concept array with a perfect line
			var i:int;
			var rand:Number;
			var x_per:int = 10;
			var y_per:int = 5;
			var t_per:int = 100;
			while (i<100) {
				rand = MathUtil.randomInt(-4, 4);
				rand = 1-(rand*.01);
				smoothA.push([
					(i*x_per)*rand,		//x
					(i*y_per)*rand,		//y
					(i*t_per)*rand]		//timestamp
				);
				i++;
			}			
		}
		
		private function onAddedToStage(event:Event):void
		{
			StageBeacon.key_down_sig.add(onKeyDown);
		}
		
		private function onKeyDown(event:KeyboardEvent):void
		{
			//Responds to "e pressed while q is down";
			if(event.keyCode == Keyboard.R && KeyBeacon.instance.pressed(Keyboard.Q)){
				visible = !visible;
			}
		}
		
		public function setSize(w:Number, h:Number):void {
			this.w = w;
			this.h = h;
			graphics.clear();
			graphics.beginFill(0x666666, 0);
			graphics.drawRect(0, 0, w, h);
			graphics.endFill();
		}
		
		public function onEnterFrame(ms_elapsed:Number):void {
			if (!visible) return;
			
			var g:Graphics = shape.graphics;
			g.clear();
			
			if (false) {
				makeSmoothA();
				draw(smoothA, 0x000000, x_index);
			}
			
			if (!model.worldModel.pc) return;
			draw(model.worldModel.pc.path, 0xffffff, x_index, false, true);
			//draw(model.worldModel.pc.path, 0xFFE303, y_index);
			//draw(model.worldModel.pc.path, 0xCC0000, vx_index, true, false, 20);
			draw(model.worldModel.pc.path, 0xFF9912, pxsec_from_diff_index, true);
			//draw(model.worldModel.pc.path, 0xFFE303, pxsec_from_nvx_index, true, false, -20);
			draw(model.worldModel.pc.path, 0xFF9912, diffx_index, true);
			//draw(model.worldModel.pc.path, 0xFFE303, nvx_index, true, false, -20);
			draw(model.worldModel.pc.path, 0xFfffff, ms_index, true, false, -80);
		}
		
		private function draw(A:Array, c:uint, p_index:int, abs:Boolean=false, draw_lines:Boolean=false, y_offset:int=0):void {
			if (!visible) return;
			if (!A) return;
			if (!A.length) return;
			if (p_index >= A[0].length) return;
			
			var g:Graphics = shape.graphics;
			var i:int;
			
			// p = position
			// t = time
			
			var p:Number;
			var t:Number;
			
			var min_p:Number = A[0][p_index];
			var max_p:Number = A[A.length-1][p_index];
			
			var min_t:Number = A[0][t_index];
			var max_t:Number = A[A.length-1][t_index];
			
			// find ranges
			for (i=0;i<A.length;i++) {
				p = A[i][p_index];
				t = A[i][t_index];
				if (p < min_p) min_p = p;
				if (p > max_p) max_p = p;
				if (t < min_t) min_t = t;
				if (t > max_t) max_t = t;
			}
			
			var delta_t:Number = max_t-min_t;
			var delta_p:Number = max_p-min_p;
			
			CONFIG::debugging {
				Console.trackPhysicsValue('  PMRt delta_t', delta_t);
				Console.trackPhysicsValue('  PMRt min_t', min_t);
				Console.trackPhysicsValue('  PMRt max_t', max_t);
				Console.trackPhysicsValue('  PMRp delta_p', delta_p);
				Console.trackPhysicsValue('  PMRp min_p', min_p);
				Console.trackPhysicsValue('  PMRp max_p', max_p);
			}
			
			var this_x:Number;
			var this_y:Number;
			
			if (draw_lines) {
				g.lineStyle(0, 0xffffff, .2);
				for (i=0;i<A.length;i++) {
					t = A[i][t_index];
					
					if (perc_of_w_to_use == 1) {
						this_x = (t-min_t)*(w/delta_t);
					} else {
						this_x = (t-min_t)*((w/delta_t)*perc_of_w_to_use);
						this_x = (w*((1-perc_of_w_to_use)/2))+this_x;
					}
					
					var line_start_y:int = (h-(h*perc_of_h_to_use))/2;
					g.moveTo(this_x, line_start_y);
					g.lineTo(this_x, line_start_y+(perc_of_h_to_use*h));
				}
			}
			
			g.lineStyle(0, c, .5);
			for (i=0;i<A.length;i++) {
				p = A[i][p_index];
				t = A[i][t_index];
				
				if (perc_of_w_to_use == 1) {
					this_x = (t-min_t)*(w/delta_t);
				} else {
					this_x = (t-min_t)*((w/delta_t)*perc_of_w_to_use);
					this_x = (w*((1-perc_of_w_to_use)/2))+this_x;
				}
				
				if (abs) {
					if (perc_of_h_to_use == 1) {
						this_y = h-Math.abs(p);
					} else {
						this_y = (h-(h*((1-perc_of_h_to_use)/2)))-Math.abs(p);
					}
				} else {
					if (perc_of_h_to_use == 1) {
						this_y = (p-min_p)*(h/(delta_p||1));
					} else {
						this_y = (p-min_p)*((h/(delta_p||1))*perc_of_h_to_use);
						this_y = (h*((1-perc_of_h_to_use)/2))+this_y;
					}
				}
				
				this_y+= y_offset;
				
				if (i) {
					g.lineTo(this_x, this_y);
				}
				
				g.beginFill(c, 1);
				g.drawCircle(this_x, this_y, 1.5);
				g.endFill();
				
				g.moveTo(this_x, this_y);
				
			}
		}
	}
}