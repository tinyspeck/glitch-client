package com.tinyspeck.engine.view.ui.craftybot
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.data.craftybot.CraftyComponent;
	import com.tinyspeck.engine.data.craftybot.CraftyJob;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.CandyCane;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.text.TextField;

	public class CraftyProgress extends Sprite
	{
		private static const HEIGHT:uint = 20;
		private static const FADED_ALPHA:Number = .4;
		private static const LIGHT_SPEED:Number = 400;
		private static const LIGHT_TOTAL:uint = 5;
		
		private var title_tf:TextField = new TextField();
		
		private var lights_left:Sprite = new Sprite();
		private var lights_right:Sprite = new Sprite();
		
		private var current_job:CraftyJob;
		private var candy_cane:CandyCane;
		
		private var on_filtersA:Array;
		private var off_filtersA:Array;
		
		private var w:int;
		private var perc:Number;
		private var progress_interval:int = -1;
		private var light_index:int = -1;
		
		private var is_built:Boolean;
		private var complete_style:Boolean;
		
		public function CraftyProgress(w:int, complete_style:Boolean){
			this.w = w;
			this.complete_style = complete_style;
		}
		
		private function buildBase():void {
			//bg
			const bg_color:uint = CSSManager.instance.getUintColorValueFromStyle('crafty_progress', 'backgroundColor', 0x9e9453);
			const border_color:uint = CSSManager.instance.getUintColorValueFromStyle('crafty_progress', 'borderColor', 0x645e34);
			var g:Graphics = graphics;
			g.lineStyle(1, border_color);
			g.beginFill(bg_color);
			g.drawRect(0, 0, w, HEIGHT);
			filters = StaticFilters.copyFilterArrayFromObject({alpha:.4, distance:2}, StaticFilters.black3px90DegreesInner_DropShadowA);
			
			//tf
			TFUtil.prepTF(title_tf, false);
			title_tf.htmlText = '<p class="crafty_progress">'+(complete_style ? 'JOB COMPLETE' : 'IN PROGRESS')+'</p>';
			title_tf.x = int(w/2 - title_tf.width/2);
			title_tf.y = int(HEIGHT/2 - title_tf.height/2 + 2);
			addChild(title_tf);
			
			//filters
			const drop_top:DropShadowFilter = new DropShadowFilter();
			drop_top.angle = 90;
			drop_top.inner = true;
			drop_top.alpha = .5;
			drop_top.distance = 1;
			drop_top.blurX = drop_top.blurY = 3;
			
			const drop_bottom:DropShadowFilter = new DropShadowFilter();
			drop_bottom.color = 0xffffff;
			drop_bottom.angle = 90;
			drop_bottom.distance = 1;
			drop_bottom.blurX = drop_bottom.blurY = 1;
			drop_bottom.alpha = .4;
			
			off_filtersA = [drop_top, drop_bottom];
			
			const glow:GlowFilter = new GlowFilter();
			glow.color = 0xffffff;
			glow.blurX = glow.blurY = 5;
			glow.quality = 3;
			glow.alpha = 1;
			
			on_filtersA = [glow];
			
			//lights
			const light_padd:uint = 16;
			buildLights(lights_left);
			lights_left.x = light_padd;
			lights_left.y = int(HEIGHT/2 - lights_left.height/2 + 1);
			addChild(lights_left);
			
			buildLights(lights_right);
			lights_right.x = int(w - lights_right.width - light_padd);
			lights_right.y = int(HEIGHT/2 - lights_left.height/2 + 1);
			addChild(lights_right);
			
			//candy cane
			candy_cane = new CandyCane(w, HEIGHT, 13);
			addChildAt(candy_cane, 0);
			
			is_built = true;
		}
		
		private function buildLights(holder:Sprite):void {
			const wh:uint = 7;
			const gap:uint = 15;
			var i:uint;
			var light:Shape;
			var next_x:uint;
			var g:Graphics;
			
			for(i; i < LIGHT_TOTAL; i++){
				light = new Shape();
				light.x = next_x;
				light.name = 'off_'+(holder == lights_left ? i : LIGHT_TOTAL-1-i);
				light.filters = off_filtersA;
				g = light.graphics;
				g.beginFill(0x6e673b);
				g.drawCircle(wh/2, wh/2, wh/2);
				holder.addChild(light);
				
				light = new Shape();
				light.x = next_x;
				light.name = 'on_'+(holder == lights_left ? i : LIGHT_TOTAL-1-i);
				light.filters = on_filtersA;
				g = light.graphics;
				g.beginFill(0xffffff);
				g.drawCircle(wh/2, wh/2, wh/2);
				holder.addChild(light);
				
				next_x += wh + gap;
			}
		}
		
		public function show(job:CraftyJob):void {
			if(!is_built) buildBase();
			current_job = job;
			
			//figure out how far done we are
			const total:uint = job.components.length;
			var i:uint;
			var done_count:uint = 0;
			
			for(i; i < total; i++){
				if(job.components[int(i)].status == CraftyComponent.STATUS_COMPLETE){
					done_count++;
				}
				else {
					//no need to keep looping
					break;
				}
			}
			
			perc = done_count/total;
			
			//style the text
			setText();			
			
			//start the interval if we need to
			if(!complete_style && progress_interval == -1 && perc < 1){
				light_index = 0;
				progress_interval = StageBeacon.setInterval(nextLight, LIGHT_SPEED);
			}
			else if(!complete_style && progress_interval != -1 && perc == 1){
				//stop the lights
				StageBeacon.clearInterval(progress_interval);
				progress_interval = -1;
			}
			
			//handle the complete stuff if we need to
			if(complete_style) {
				setCompleteLights();
			}
			else {
				nextLight();
			}
		}
		
		public function hide():void {
			if(progress_interval >= 0) StageBeacon.clearInterval(progress_interval);
			progress_interval = -1;
			if(is_built){
				candy_cane.animate(false);
			}
		}
		
		private function setText():void {
			var title_txt:String = '<p class="crafty_progress">';
			
			if(complete_style && perc < 1 || !complete_style && perc == 1){
				title_txt += '<span class="crafty_progress_incomplete">';
			}
			
			if(complete_style){
				//handle how "JOB COMPLETE" should look
				title_tf.filters = perc < 1 ? StaticFilters.white1px90Degrees_DropShadowA : StaticFilters.black1px90Degrees_DropShadowA;
				title_tf.alpha = perc < 1 ? FADED_ALPHA : 1;
				title_txt += 'JOB COMPLETE';
				candy_cane.animate(perc < 1);
			}
			else {
				//handle how "IN PROGRESS" should look
				title_tf.filters = perc == 1 ? StaticFilters.white1px90Degrees_DropShadowA : StaticFilters.black1px90Degrees_DropShadowA;
				title_tf.alpha = perc == 1 ? FADED_ALPHA : 1;
				title_txt += 'IN PROGRESS';
				candy_cane.animate(perc != 1);
			}
			
			if(complete_style && perc < 1 || !complete_style && perc == 1){
				title_txt += '</span>';
			}
			title_txt += '</p>';
			
			title_tf.htmlText = title_txt;
		}
		
		private function nextLight():void {
			if(light_index >= LIGHT_TOTAL){
				light_index = 0;
			}
			
			var i:uint;
			var light:Shape;
			
			//figure out which light to light up
			for(i; i < LIGHT_TOTAL; i++){
				light = lights_left.getChildByName('off_'+i) as Shape;
				light.visible = i != light_index;
				light = lights_left.getChildByName('on_'+i) as Shape;
				light.visible = i == light_index;
				
				light = lights_right.getChildByName('off_'+(LIGHT_TOTAL-1-i)) as Shape;
				light.visible = (LIGHT_TOTAL-1-i) != light_index;
				light = lights_right.getChildByName('on_'+(LIGHT_TOTAL-1-i)) as Shape;
				light.visible = (LIGHT_TOTAL-1-i) == light_index;
			}
			
			light_index++;
		}
		
		private function setCompleteLights():void {
			//get the index
			light_index = Math.ceil(perc*LIGHT_TOTAL);
			
			var i:uint;
			var light:Shape;
			
			//figure out which light to light up
			for(i; i < LIGHT_TOTAL; i++){
				light = lights_left.getChildByName('off_'+i) as Shape;
				light.visible = i >= light_index;
				light = lights_left.getChildByName('on_'+i) as Shape;
				light.visible = i < light_index;
				
				light = lights_right.getChildByName('off_'+(LIGHT_TOTAL-1-i)) as Shape;
				light.visible = (LIGHT_TOTAL-1-i) >= light_index;
				light = lights_right.getChildByName('on_'+(LIGHT_TOTAL-1-i)) as Shape;
				light.visible = (LIGHT_TOTAL-1-i) < light_index;
			}
		}
		
		override public function get height():Number {
			return HEIGHT;
		}
	}
}