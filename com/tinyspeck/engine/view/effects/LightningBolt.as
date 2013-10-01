package com.tinyspeck.engine.view.effects
{
import com.tinyspeck.core.beacon.StageBeacon;
import com.tinyspeck.core.memory.DisposableSprite;
import com.tinyspeck.debug.Console;
import com.tinyspeck.engine.control.TSFrontController;
import com.tinyspeck.engine.port.IDisposableSpriteChangeHandler;
import com.tinyspeck.engine.util.MathUtil;
import com.tinyspeck.engine.view.AbstractAvatarView;
import com.tinyspeck.tstweener.TSTweener;

import flash.display.Sprite;
import flash.filters.GlowFilter;

public final class LightningBolt extends Sprite implements IDisposableSpriteChangeHandler
{
	private var x1:int;
	private var y1:int;
	private var x2:int;
	private var y2:int;
	private var x1_delta:int;
	private var x1_delta_relative_to_face:Boolean;
	private var x1_delta_polarity:int = 1;
	private var y1_delta:int;
	private var x2_delta:int;
	private var y2_delta:int;
	private var ds1:DisposableSprite;
	private var ds2:DisposableSprite;
	private var delay:Number;
	private var duration_secs:Number;
	private var fade_in_secs:Number = .2;
	private var fade_out_secs:Number = .8;
	private var animate:Boolean;
	private var bolt_alpha:Number = 1;
	private var bolt_color:uint = 0xffffff;
	public var running:Boolean;
	
	public function LightningBolt() {}
	
	/**
	 * 
	 * Creates a lightening bolt between two DisposableSprite, and follows then as they move
	 * 
	 **/
	public function goWithDisposableSprites(delay:Number, duration_secs:Number, ds1:DisposableSprite, ds2:DisposableSprite, bolt_color:uint=0xffffff, ds1_x_delta:int=0, ds1_x_delta_relative_to_face:Boolean=false, ds1_y_delta:int=0, ds2_x_delta:int=0, ds2_y_delta:int=0):void {
		if (running) {
			CONFIG::debugging {
				Console.error('No going when running!');
			}
			return;
		}
		
		this.ds1 = ds1;
		this.ds2 = ds2;
		
		x1_delta = ds1_x_delta;
		x1_delta_relative_to_face = ds1_x_delta_relative_to_face;
		y1_delta = ds1_y_delta;
		x2_delta = ds2_x_delta;
		y2_delta = ds2_y_delta;
		
		bolt_alpha = 1;
		this.bolt_color = bolt_color;
		
		this.delay = delay;
		this.duration_secs = Math.max(duration_secs, fade_in_secs+fade_out_secs);
		this.animate = animate;
		
		TSFrontController.instance.registerDisposableSpriteChangeSubscriber(this, ds1);
		TSFrontController.instance.registerDisposableSpriteChangeSubscriber(this, ds2);
		
		running = true;
		show();
	}
	
	/**
	 * 
	 * Creates a lightening bolt between points
	 * 
	 **/
	public function go(delay:Number, duration_secs:Number, x1:int, y1:int, x2:int, y2:int, animate:Boolean=true):void {
		if (running) {
			CONFIG::debugging {
				Console.error('No going when running!');
			}
			return;
		}
		
		this.delay = delay;
		this.duration_secs = Math.max(duration_secs, fade_in_secs+fade_out_secs);
		this.x1 = x1;
		this.y1 = y1;
		this.x2 = x2;
		this.y2 = y2;
		this.animate = animate;
		
		running = true;
		show();
		
	}
	
	/**
	 * 
	 * Updates the end points of the lightening bolt
	 * 
	 **/
	public function update(x1:int, y1:int, x2:int, y2:int):void {
		if (!running) return;
		this.x1 = x1;
		this.y1 = y1;
		this.x2 = x2;
		this.y2 = y2;
		if (!animate) drawLightning();
	}
	
	private function show():void {
		// create a filter with a random alpha in the range of [0.3, 0.7]
		filters = [new GlowFilter(bolt_color, (0.3 + Math.random() * 0.4), 8, 8, 3)];
		
		drawLightning();
		
		if (animate) {
			StageBeacon.enter_frame_sig.add(onEnterFrame);
		}
		
		alpha = 0;
		TSTweener.addTween(this, {alpha:1, time:fade_in_secs, delay:delay, transition:'easeInExpo', onComplete:fade});
	}
	
	private function onEnterFrame(ms_elapsed:int):void {
		if (!running) {
			// we shoudl never get here, but just in case...
			StageBeacon.enter_frame_sig.remove(onEnterFrame);
			return;
		}
		
		drawLightning();
	}
	
	private function fade():void {
		TSTweener.addTween(this, {alpha:0, delay:duration_secs-(fade_in_secs+fade_out_secs), time:fade_out_secs, transition:'easeOutExpo', onComplete:reset});
	}
	
	private function reset():void {
		if (parent) parent.removeChild(this);
		StageBeacon.enter_frame_sig.remove(onEnterFrame);
		if (ds1) {
			TSFrontController.instance.unregisterDisposableSpriteChangeSubscriber(this, ds1);
			TSFrontController.instance.unregisterDisposableSpriteChangeSubscriber(this, ds2);
			ds1 = null;
			ds2 = null;
		}
		x1_delta = 0;
		x1_delta_relative_to_face = false;
		x1_delta_polarity = 1;
		y1_delta = 0;
		x2_delta = 0;
		y2_delta = 0;
		bolt_alpha = 1;
		bolt_color = 0xffffff;
		running = false;
	}
	
	private function drawLightning():void {
		
		var local_x1:int = x1+(x1_delta*x1_delta_polarity);
		var local_y1:int = y1+y1_delta;
		var local_x2:int = x2+x2_delta;
		var local_y2:int = y2+y2_delta;
		
		// subjectively, distance in pixels / 4 or 3 looks good for this magic number
		const displacement:Number = (MathUtil.distance(local_x1, local_y1, local_x2, local_y2) / 3);
		
		// draw the bolt
		graphics.clear();
		graphics.lineStyle(2, bolt_color, bolt_alpha);
		drawLightningStep(local_x1, local_y1, local_x2, local_y2, displacement)
	}
	
	private function drawLightningStep(x1:int, y1:int, x2:int, y2:int, displacement:Number):void {
		if (displacement < 1) {
			graphics.moveTo(x1, y1);
			graphics.lineTo(x2, y2);
		} else {
			displacement *= 0.5;
			
			// randomly displace the midpoint
			const xMid:int = (((x2 + x1) * 0.5) + ((Math.random() - 0.5) * displacement));
			const yMid:int = (((y2 + y1) * 0.5) + ((Math.random() - 0.5) * displacement));
			
			// recursively displacement each half of the line
			drawLightningStep(x1, y1, xMid, yMid, displacement);
			drawLightningStep(x2, y2, xMid, yMid, displacement);
		}
	}		
	
	public function worldDisposableSpriteDestroyedHandler(sp:DisposableSprite):void {
		// nothing to do
	}
	
	public function worldDisposableSpriteSubscribedHandler(sp:DisposableSprite):void {
		worldDisposableSpriteChangeHandler(sp);
	}
	
	public function worldDisposableSpriteChangeHandler(sp:DisposableSprite):void {
		if (!sp) return;
		
		if (sp == ds1) {
			if (x1_delta_relative_to_face) {
				if (sp is AbstractAvatarView) {
					const pc_view:AbstractAvatarView = sp as AbstractAvatarView;
					x1_delta_polarity = pc_view.orientation;
				} /*else if (sp is LocationItemstackView) {
					// todo a thing for livs direction facing here
				}*/
			}
			this.x1 = ds1.x;
			this.y1 = ds1.y;
		} else if (sp == ds2) {
			this.x2 = ds2.x;
			this.y2 = ds2.y;
		} else {
			return;
		}
		
		if (!animate) drawLightning();
	}
}
}