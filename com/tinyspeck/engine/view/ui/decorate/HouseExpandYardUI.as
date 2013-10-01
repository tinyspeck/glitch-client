package com.tinyspeck.engine.view.ui.decorate
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.data.house.HouseExpandCosts;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Sprite;
	import flash.text.TextField;

	public class HouseExpandYardUI extends Sprite
	{
		private static const IMAGE_H:uint = 150;
		private static const IMAGE_PADD:uint = 4;
		private static const IMAGE_W:uint = 206; //uses this when displaying left AND right
		
		private var image_holder:Sprite = new Sprite();
		
		private var left_image:HouseExpandYardImageUI = new HouseExpandYardImageUI();
		private var right_image:HouseExpandYardImageUI = new HouseExpandYardImageUI();
		
		private var choose_side_tf:TextField = new TextField();
		
		private var is_built:Boolean;
		private var _w:int;
		
		public function HouseExpandYardUI(){}
		
		private function buildBase():void {
			//image stuff
			left_image.addEventListener(TSEvent.CHANGED, onDirectionClick, false, 0, true);
			right_image.addEventListener(TSEvent.CHANGED, onDirectionClick, false, 0, true);
			image_holder.addChild(left_image);
			image_holder.addChild(right_image);
			addChild(image_holder);
			
			//choose text
			TFUtil.prepTF(choose_side_tf);
			choose_side_tf.htmlText = '<p class="house_expand_yard_side"><span class="house_expand_yard_choose">Choose the side you’d like to expand.</span></p>';
			choose_side_tf.width = _w;
			choose_side_tf.y = 10;
			choose_side_tf.filters = StaticFilters.black2px90Degrees_DropShadowA;
			choose_side_tf.mouseEnabled = false;
			addChild(choose_side_tf);
			
			is_built = true;
		}
		
		public function show(w:int, cost_info:HouseExpandCosts):void {
			_w = w;
			if(!is_built) buildBase();
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			const is_external_street:Boolean = pc.home_info.exterior_tsid == TSModelLocator.instance.worldModel.location.tsid;
			const can_afford:Boolean = pc.stats.imagination >= cost_info.img_cost;
			
			// reset!
			left_image.select(false, false);
			right_image.select(false, false);
			
			//figure out which direction buttons to show
			left_image.enabled = true;
			right_image.enabled = true;
			
			//if we are on an external street, make sure we can still upgrade
			if(is_external_street){
				left_image.enabled = cost_info.count_left > 0;
				right_image.enabled = cost_info.count_right > 0;
			}
			else {
				//THERE IS NO LEFT/RIGHT AS OF NOW. THIS WILL NEED TO CHANGE WHEN WE ALLOW THAT
				//CAL WILL PROBABLY SEND THE SAME count_left AND count_right I WOULD ASSUME
				left_image.enabled = cost_info.count > 0;
				right_image.enabled = false;
			}
			
			//show em
			const img_w:int = left_image.enabled && right_image.enabled ? IMAGE_W : _w;
			left_image.visible = left_image.enabled;
			if(left_image.visible) left_image.show(img_w, IMAGE_H, 'left');
			
			right_image.visible = right_image.enabled;
			if(right_image.visible) right_image.show(img_w, IMAGE_H, 'right');
			right_image.x = left_image.visible ? left_image.width + IMAGE_PADD : 0;
			
			//place em
			const holder_w:int = left_image.width + (right_image.visible ? right_image.width + IMAGE_PADD : 0);
			image_holder.x = int(_w/2 - holder_w/2);
			
			//can they afford them?
			//left_image.enabled = can_afford;
			//right_image.enabled = can_afford;
			
			//show the choose text if we can actually make a choice
			choose_side_tf.visible = left_image.enabled && right_image.enabled;
			choose_side_tf.alpha = 1;
			
			//if we are only showing one option, select it after a second (if it's enabled)
			if(!right_image.visible && left_image.enabled){
				left_image.enabled = false;
				moveHolder(left_image, false);
			}
			else if(!left_image.visible && right_image.enabled){
				right_image.enabled = false;
				moveHolder(right_image, false);
			}
			
			visible = true;
		}
		
		public function hide():void {
			visible = false;
		}
		
		private function onDirectionClick(event:TSEvent):void {
			const image:HouseExpandYardImageUI = event.data as HouseExpandYardImageUI;
			if(!image || !image.enabled) return;
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			//move it!
			moveHolder(image);
		}
		
		public function chooseSide(side:String):Boolean {
			if (side == 'right' && right_image.enabled && !right_image.is_selected) {
				//move it!
				moveHolder(right_image);
				SoundMaster.instance.playSound('CLICK_SUCCESS');
				return true;
			} else if (side == 'left' && left_image.enabled && !left_image.is_selected) {
				//move it!
				moveHolder(left_image);
				SoundMaster.instance.playSound('CLICK_SUCCESS');
				return true;
			}
			
			return false;
		}
		
		private function moveHolder(image:HouseExpandYardImageUI, animate:Boolean = true):void {
			if (image.is_selected) return;
			
			//tween the holder where it needs to go
			const holder_w:int = left_image.width + (right_image.visible ? right_image.width + IMAGE_PADD : 0);
			const end_x:int = image == left_image ? _w - holder_w : 0;
			if(image_holder.x == end_x) return;
			
			if(animate){
				//move it!
				TSTweener.addTween(image_holder, {x:end_x, time:HouseExpandYardImageUI.ANIMATION_TIME});
				
				//fade out the choose text
				TSTweener.addTween(choose_side_tf, {alpha:0, time:.2, transition:'linear'});
			}
			else {
				//move it where it needs to go speedy like
				image_holder.x = end_x;
				choose_side_tf.alpha = 0;
			}
			
			//set the proper states on the image holders
			left_image.select(image == left_image, animate);
			right_image.select(image == right_image, animate);
			
			//let whoever is listening know
			dispatchEvent(new TSEvent(TSEvent.CHANGED, image == left_image ? 'left' : 'right'));
		}
		
		public function get selected_side():String {
			if(left_image.is_selected) return 'left';
			if(right_image.is_selected) return 'right';
			return null;
		}
		
		override public function get width():Number { return _w; }
		override public function get height():Number { return IMAGE_H; }
	}
}