package com.tinyspeck.engine.view.ui.craftybot
{
	import com.tinyspeck.engine.data.craftybot.CraftyComponent;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;

	public class CraftyActiveElementUI extends CraftyJobElementUI
	{
		public function CraftyActiveElementUI(w:int){
			super(w);
			
			//throw the glow on the bg
			bg_holder.filters = StaticFilters.copyFilterArrayFromObject({color:0x92804a, strength:4}, StaticFilters.black_GlowA);
		}
		
		override protected function setText():void {
			super.setText();
			
			//handle the status text
			const world:WorldModel = TSModelLocator.instance.worldModel;
			const total:uint = current_job.components.length;
			var i:uint;
			var j:uint;
			var count:uint;
			var component:CraftyComponent;
			var chunks:Array;
			var item:Item;
			var set_status:Boolean;
			var status_txt:String = '<p class="crafty_job_status">';
			
			for(i; i < total; i++){
				//find the active thing, and put it in the status
				component = current_job.components[int(i)];
				if(component.status == CraftyComponent.STATUS_ACTIVE){
					switch(component.type){
						case CraftyComponent.TYPE_FETCH:
							status_txt += 'Fetching ';
							break;
						case CraftyComponent.TYPE_CRAFT:
							status_txt += 'Crafting ';
							break;
					}
					
					//loop through all the items
					for(j = 0; j < component.item_classes.length; j++){
						chunks = String(component.item_classes[int(j)]).split('|');
						item = world.getItemByTsid(chunks[0]);
						count = component.counts[int(j)];
						if(item){
							if(count > 1){
								status_txt += '<b>'+StringUtil.formatNumberWithCommas(count)+'</b> ';
							}
							
							if(count >= 1){
								status_txt += (count != 1 ? item.label_plural : item.label);
							}
							else {
								//this is when it's disabled, so drop the count
								status_txt += item.label_plural;
							}
							
							if(chunks.length > 1){
								//this means more than 1 tool will work usually
								status_txt += ' of some sort';
							}
						}
						else {
							status_txt += 'something or other';
						}
					}
					
					//don't bother looking for any more
					set_status = true;
					break;
				}
			}
			
			//if we don't have a status, let's put one in
			if(current_job.status.is_complete){
				status_txt += '<span class="crafty_component_complete">Job Complete!</span>';
			}
			else if(!set_status){
				status_txt += 'Just hanging out';
			}
			
			status_txt += '</p>';
			status_tf.htmlText = status_txt;			
			status_tf.y = int(name_tf.y + name_tf.height - 4);
			status_tf.width = name_tf.width;
			
			text_holder.y = int(height/2 - text_holder.height/2 - 1);
		}
		
		override protected function setBackground():void {
			//draw the rounded style
			var g:Graphics = bg_holder.graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRoundRect(0, 0, w, height, 10);
		}
		
		override protected function setButtons():void {
			//if we have nothing to take, show the remove button
			if(remove_bt.parent) remove_bt.parent.removeChild(remove_bt);
			if(collect_bt.parent) collect_bt.parent.removeChild(collect_bt);
			
			if(!current_job.done){
				//show the remove button
				remove_bt.x = int(w - remove_bt.width - 10);
				remove_bt.disabled = false;
				addChild(remove_bt);
			}
			else if(current_job.done){
				//show the collect button
				collect_bt.label = 'Collect '+current_job.done;
				collect_bt.x = int(w - collect_bt.width - 10);
				collect_bt.disabled = false;
				addChild(collect_bt);
			}
		}
	}
}