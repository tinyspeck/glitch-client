package com.tinyspeck.engine.view.ui.making
{
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.ProgressBar;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	
	import flash.display.Graphics;
	import flash.text.TextField;

	public class MakingToolAnimator extends TSSpriteWithModel
	{
		private static const BG_ALPHA:Number = .8;
		private static const TOOL_WH:uint = 200;
		private static const TOOL_FRAME:String = 'tool_animation';
		private static const OFFSET_Y:uint = 40;
		
		private var tool_ani:ItemIconView;
		private var progress:ProgressBar;
		
		private var progress_tf:TextField = new TextField();
		
		private var is_built:Boolean;
		
		private var tool_class:String;
		
		private var current:uint;
		private var total:uint;
		private var ani_time:Number;
		
		private var _bg_c:uint = 0xececec;
		
		public function MakingToolAnimator(){}
		
		private function buildBase():void {
			//setup the progress
			progress = new ProgressBar(190, 25);
			progress.setFrameColors(0xd7d7d7, 0xbababa);
			progress.setBorderColor(0xc2c2c2, 1);
			progress.addEventListener(TSEvent.COMPLETE, onProgressComplete, false, 0, true);
			addChild(progress);
			
			//the progress tf
			TFUtil.prepTF(progress_tf);
			progress_tf.htmlText = getProgressText();
			progress_tf.width = progress.width - 2;
			progress_tf.y = int(progress.height/2 - progress_tf.height/2) - 1;
			progress.addChild(progress_tf);
			
			is_built = true;
		}
		
		public function animate(class_tsid:String, time_ms:int, amount:int, is_known:Boolean):void {
			tool_class = class_tsid;
			
			draw();
			
			//figue out how many we need to make
			current = 1;
			total = amount;
			ani_time = (time_ms/1000) / amount;
			
			//setup the progress bar
			if(is_known){
				progress_tf.htmlText = getProgressText();
			}
			else {
				progress_tf.htmlText = '<p class="making_tool_progress">Trying something new</p>';
			}
			
			startAnimating();
		}
		
		private function startAnimating():void {			
			progress.update(0);
			progress.updateWithAnimation(ani_time, 1);
		}
		
		private function draw():void {
			if(!is_built) buildBase();
			
			//draw the bg
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(_bg_c, BG_ALPHA);
			g.drawRect(0, 0, _w, _h);
			
			//get the animation ready to rock
			if(!tool_ani || (tool_ani && tool_ani.tsid != tool_class)){
				if(tool_ani) removeChild(tool_ani);
				tool_ani = new ItemIconView(tool_class, TOOL_WH, TOOL_FRAME);
				addChild(tool_ani);
			}
			
			tool_ani.x = int(_w/2 - TOOL_WH/2);
			tool_ani.y = OFFSET_Y;
			
			//progress bar
			progress.x = int(_w/2 - progress.width/2);
			progress.y = OFFSET_Y + TOOL_WH + 20;
		}
		
		private function onProgressComplete(event:TSEvent):void {
			//if we aren't done let's reset it and do it again!
			if(current < total){
				current++;
				progress_tf.htmlText = getProgressText();
				progress.update(0);
				progress.updateWithAnimation(ani_time, 1);
			}
		}
		
		private function getProgressText():String {
			return '<p class="making_tool_progress">Making '+current+' of '+total+'</p>';
		}
		
		public function setSize(w:int, h:int):void {
			_w = w;
			_h = h;
		}
		
		public function set background_color(value:uint):void {
			_bg_c = value;
		}
	}
}