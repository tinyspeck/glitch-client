package com.tinyspeck.engine.view.ui.craftybot
{
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class CraftyJobDetailsHaltedUI extends Sprite
	{
		private static const TF_PADD:uint = 12;
		private static const CORNER_RADIUS:Number = 6;
		
		private var head_holder:Sprite = new Sprite();
		private var body_holder:Sprite = new Sprite();
		
		private var title_tf:TextField = new TextField();
		private var body_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var w:int;
		
		private var is_built:Boolean;
		
		public function CraftyJobDetailsHaltedUI(w:int){
			this.w = w;
		}
		
		public function buildBase():void {
			//tfs
			TFUtil.prepTF(title_tf, false);
			title_tf.htmlText = '<p class="crafty_job_details_halted_title">Job Halted!</p>';
			title_tf.x = TF_PADD;
			title_tf.y = 1;
			head_holder.addChild(title_tf);
			
			TFUtil.prepTF(body_tf);
			body_tf.x = TF_PADD;
			body_tf.y = int(TF_PADD/2);
			body_tf.width = w - TF_PADD*2;
			body_holder.addChild(body_tf);
			
			//holders
			const head_color:uint = 0x9e5454;
			var g:Graphics = head_holder.graphics;
			g.beginFill(head_color);
			g.drawRoundRectComplex(0, 0, w, int(title_tf.height + title_tf.y*2), CORNER_RADIUS,CORNER_RADIUS, 0,0);
			head_holder.filters = StaticFilters.copyFilterArrayFromObject({color:head_color, strength:8}, StaticFilters.black_GlowA);
			addChild(head_holder);
			
			body_holder.y = int(head_holder.height - 1);
			body_holder.filters = StaticFilters.copyFilterArrayFromObject({color:0xcf9e9e, strength:8}, StaticFilters.black_GlowA);
			addChildAt(body_holder, 0);
			
			is_built = true;
		}
		
		public function show(status_txt:String):void {
			if(!is_built) buildBase();
			
			//set the body
			body_tf.htmlText = '<p class="crafty_job_details_halted_body">'+status_txt+'</p>';
			
			//draw the background
			var g:Graphics = body_holder.graphics;
			g.clear();
			g.beginFill(0xf5e2e3);
			g.drawRoundRectComplex(0, 0, w, int(body_tf.height + body_tf.y*2), 0,0, CORNER_RADIUS,CORNER_RADIUS);
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
		}
	}
}