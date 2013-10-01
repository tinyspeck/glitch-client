package com.tinyspeck.engine.view.ui.craftybot
{
	import com.tinyspeck.engine.data.craftybot.CraftyJob;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.CraftyManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.CandyCane;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class CraftyJobDetailsCompleteUI extends Sprite
	{
		private static const TF_PADD:uint = 5;
		
		private var candy_cane:CandyCane;
		
		private var made_tf:TextField = new TextField();
		
		private var collect_bt:Button;
		private var current_job:CraftyJob;
		
		private var w:int;
		
		private var is_built:Boolean;
		
		public function CraftyJobDetailsCompleteUI(w:int){
			this.w = w;
		}
		
		private function buildBase():void {			
			//tf
			TFUtil.prepTF(made_tf);
			made_tf.x = TF_PADD;
			made_tf.y = TF_PADD;
			made_tf.width = w - TF_PADD*2;
			made_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			addChild(made_tf);
			
			//bt
			collect_bt = new Button({
				name: 'collect',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_DEFAULT
			});
			collect_bt.addEventListener(TSEvent.CHANGED, onCollectClick, false, 0, true);
			addChild(collect_bt);
			
			//candy cane
			candy_cane = new CandyCane(w, 10, 27, .3, .6); //10 is just placeholder height, it's dynamic
			addChildAt(candy_cane, 0);
			
			is_built = true;
		}
		
		public function show(job:CraftyJob):void {
			if(!is_built) buildBase();
			if(!job) return;
			current_job = job;
			
			//reset
			collect_bt.disabled = false;
			
			//set the text/button
			setText();
			
			//do the background stuff
			setBackground();
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
			if(is_built){
				candy_cane.animate(false);
			}
		}
		
		private function setText():void {
			const item:Item = TSModelLocator.instance.worldModel.getItemByTsid(current_job.item_class);
			if(!item) return;
			
			const label:String = current_job.done+' '+(current_job.done != 1 ? item.label_plural : item.label);
			
			var made_txt:String = '<p class="crafty_job_details_complete_made">';
			if(current_job.done < current_job.total){
				made_txt += 'I\'ve crafted <b>'+label+'</b> so far'
			}
			else {
				made_txt += 'I\'ve made all of the <b>'+item.label_plural+'</b>';
			}
			made_txt += '</p>';
			made_tf.htmlText = made_txt;
			
			//set the button
			collect_bt.label = 'Collect '+label;
			collect_bt.x = int(w/2 - collect_bt.width/2);
			collect_bt.y = int(made_tf.y + made_tf.height + 2);
		}
		
		private function setBackground():void {
			const draw_h:uint = collect_bt.y + collect_bt.height + TF_PADD + 3;
			
			//background
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0xe1ebc4);
			g.drawRect(0, 0, w, draw_h);
			g.beginFill(0xc2d997);
			g.drawRect(0, 0, w, 1); //top border
			
			//make the candy cane
			candy_cane.height = draw_h;
			candy_cane.animate(true);
		}
		
		private function onCollectClick(event:TSEvent):void {
			SoundMaster.instance.playSound(!collect_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(collect_bt.disabled) return;
			collect_bt.disabled = true;
			
			//tell the server we want it
			CraftyManager.instance.removeJob(current_job.item_class, current_job.done);
		}
	}
}