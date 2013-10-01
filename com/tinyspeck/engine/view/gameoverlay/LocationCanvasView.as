package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.view.AbstractTSView;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	
	public class LocationCanvasView extends AbstractTSView {
		
		/* singleton boilerplate */
		public static const instance:LocationCanvasView = new LocationCanvasView();
		
		public var annc:Announcement;
		
		private var showing:Boolean;
		private var model:TSModelLocator;
		private var all_holder:Sprite = new Sprite();
		
		public function LocationCanvasView() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			mouseChildren = mouseEnabled = false;
			model = TSModelLocator.instance;
			addChild(all_holder);
			refresh();
		}
		
		private function validateAnnc(annc:Announcement):Boolean {
			if (!annc.canvas.steps || !annc.canvas.steps.length) {
				CONFIG::debugging {
					Console.warn('no steps?');
				}
				return false
			}
			
			return true;
		}
		
		private var curr_step_index:int;
		private var loop_from_step_index:int;
		private var loop_to_step_index:int;
		private var loop_reps:int;
		private var loop_count:int;
		private var do_loop:Boolean;
		
		public function show(annc:Announcement):void {
			if (!validateAnnc(annc)) {
				CONFIG::debugging {
					Console.error('bad annc');
				}
				return;
			}
			
			if (this.annc) {
				// figure out how to best cancel a currently running vp_canvas annc!
			}
			
			this.annc = annc;
			showing = true;
			visible = true;
			paint();
			refresh();
			addChild(all_holder);
			all_holder.alpha = 0;
			if(TSTweener.isTweening(all_holder)) TSTweener.removeTweens(all_holder);
			
			curr_step_index = 0;
			loop_count = 1;
			do_loop = annc.canvas.loop;
			loop_reps = 0;
			loop_from_step_index = 0;
			loop_to_step_index = 0;
			
			if (do_loop) {
				loop_reps = (annc.canvas.loop_details) ? annc.canvas.loop_details.reps : 1000000;
				loop_from_step_index = (annc.canvas.loop_details) ? annc.canvas.loop_details.from : 0;
				loop_to_step_index = (annc.canvas.loop_details) ? annc.canvas.loop_details.to : annc.canvas.steps.length-1;
			}
			
			doStep();
		}
		
		private function doStep():void {
			if (!showing) return;
			
			/*CONFIG::debugging {
				Console.info('curr_step_index:'+curr_step_index);
			}*/
			
			var step:Object = annc.canvas.steps[curr_step_index];
			var a:Number = MathUtil.clamp(0, 1, parseFloat(step.alpha));
			TSTweener.addTween(all_holder, {alpha: a, time: step.secs, transition: 'easeInOutSine', onComplete: afterStep});
			
		}
		
		private function afterStep():void {
			if (!showing) return;
			/*
			CONFIG::debugging {
				Console.warn('curr_step_index:'+curr_step_index);
				Console.warn('do_loop:'+do_loop);
				Console.warn('loop_count:'+loop_count);
				Console.warn('loop_reps:'+loop_reps);
				Console.warn('loop_to_step_index:'+loop_to_step_index);
				Console.warn('loop_from_step_index:'+loop_from_step_index);
			}
			*/
			if (do_loop && loop_count<loop_reps) { // we need to worry about looping!
				if (curr_step_index == loop_to_step_index) { // we are at the end of the looped section, go to start of looped section
					loop_count++;
					curr_step_index = loop_from_step_index;
					doStep();
					return;
				}
			}
			
			if (curr_step_index+1 < annc.canvas.steps.length) { //there are more steps
				curr_step_index++;
				doStep();
			} else {
				if (all_holder.alpha == 0) hide();
			}
		}
		
		public function cancel():void {
			hide();
		}
		
		public function hide():void {
			if (!showing) return;
			
			annc = null;
			showing = false;
			visible = false;
			if (all_holder.parent) removeChild(all_holder);
		}
		
		private function paint():void {
			if (!showing) return;
			
			var g:Graphics = all_holder.graphics;
			g.clear();
			g.lineStyle(0, 0, 0);
			g.beginFill(ColorUtil.colorStrToNum(annc.canvas.color), 1);
			g.drawRect(0, 0, 10, 10)
			
		}
		
		public function refresh():void {
			if (!showing) return;
			
			all_holder.width = model.layoutModel.loc_vp_w;
			all_holder.height = model.layoutModel.loc_vp_h;
		}
	}
}