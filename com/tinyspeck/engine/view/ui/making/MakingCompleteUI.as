package com.tinyspeck.engine.view.ui.making
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.making.Recipe;
	import com.tinyspeck.engine.data.making.RecipeComponent;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSEngineConstants;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Slug;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.TextField;

	public class MakingCompleteUI extends TSSpriteWithModel
	{
		private static const ICON_WH:uint = 140;
		private static const OFFSET_X:uint = 190;
		private static const ICON_PT:Point = new Point(25, 45);
		private static const SLOT_WH:uint = 52;
		
		private var icon_view:ItemIconView;
		private var info_bt:Button;
		
		private var nice_tf:TextField = new TextField();
		private var made_tf:TextField = new TextField();
		private var used_tf:TextField = new TextField();
		private var extra_tf:TextField = new TextField();
		private var xp_warn_tf:TextField = new TextField();
		
		private var slugs_holder:Sprite = new Sprite();
		private var used_holder:Sprite = new Sprite();
		private var xp_warn_holder:Sprite = new Sprite();
		
		private var is_built:Boolean;
		
		public function MakingCompleteUI(w:int){
			_w = w;
		}
		
		private function buildBase():void {
			TFUtil.prepTF(nice_tf, false);
			nice_tf.htmlText = '<p class="making_complete_nice">Nice</p>';
			nice_tf.x = OFFSET_X;
			nice_tf.y = 10;
			addChild(nice_tf);
			
			TFUtil.prepTF(made_tf);
			made_tf.width = _w - OFFSET_X;
			made_tf.x = OFFSET_X;
			made_tf.y = int(nice_tf.y + nice_tf.height) - 15;
			addChild(made_tf);
			
			//the info button below the icon
			info_bt = new Button({
				name: 'info',
				label: 'Info',
				label_size: 11,
				label_bold: true,
				label_c: 0x2c7487,
				label_offset: 1,
				draw_alpha: 0,
				graphic: new AssetManager.instance.assets.making_info(),
				graphic_placement: 'left',
				graphic_padd_r: 0
			});
			info_bt.x = ICON_PT.x + int(ICON_WH/2 - info_bt.width/2);
			info_bt.y = ICON_PT.y + ICON_WH + 37;
			info_bt.addEventListener(TSEvent.CHANGED, onInfoClick, false, 0, true);
			addChild(info_bt);
			
			slugs_holder.x = OFFSET_X;
			addChild(slugs_holder);
						
			TFUtil.prepTF(used_tf, false);
			used_tf.htmlText = '<p class="making_complete_used">You used</p>';
			used_tf.x = OFFSET_X;
			addChild(used_tf);
			
			used_holder.x = OFFSET_X;
			addChild(used_holder);
			
			TFUtil.prepTF(xp_warn_tf, false);
			xp_warn_tf.htmlText = '<p class="making_complete_xp_warn">You have received all possible iMG from making these today</p>';
			xp_warn_holder.addChild(xp_warn_tf);
			xp_warn_holder.x = OFFSET_X;
			addChild(xp_warn_holder);
			
			TFUtil.prepTF(extra_tf);
			extra_tf.x = OFFSET_X;
			extra_tf.width = _w - OFFSET_X - 20;
			addChild(extra_tf);
			
			is_built = true;
		}
		
		public function show(recipe_id:String, amount:int, rewards:Vector.<Reward>, is_known:Boolean, over_xp_limit:Boolean, extra_msg:String = ''):void {
			var recipe:Recipe = model.worldModel.getRecipeById(recipe_id);
			
			if(recipe){
				if(!is_built) buildBase();
				
				if(icon_view) icon_view.dispose();
				icon_view = new ItemIconView(recipe.outputs[0].item_class, ICON_WH);
				icon_view.x = ICON_PT.x;
				icon_view.y = ICON_PT.y;
				addChild(icon_view);
				
				info_bt.value = recipe.outputs[0].item_class;
				
				//show them what they made
				if(is_known){
					made_tf.htmlText = '<p class="making_complete_made">'+getOutputText(recipe, amount)+'</p>';
				}
				else {
					made_tf.htmlText = '<p class="making_complete_made">You discovered '+recipe.name+'!</p>';
				}
				
				//slugs
				getSlugs(rewards);
				
				//have they hit the daily XP max?
				xp_warn_holder.visible = over_xp_limit && (model.worldModel.pc && model.worldModel.pc.level < TSEngineConstants.MAX_LEVEL);
				xp_warn_holder.y = int(slugs_holder.y + (slugs_holder.numChildren ? slugs_holder.height + 15 : -4));
				
				//how much was used
				getUsed(recipe, amount);
				
				//show the extra message if we have it
				extra_tf.y = extra_msg != '' ? int(used_holder.y + used_holder.height + 12) : 0;
				extra_tf.htmlText = '<p class="making_complete_extra">'+extra_msg+'</p>';
				
				//draw out the BG
				drawBG();
			}
		}
		
		private function getOutputText(recipe:Recipe, amount:int):String {
			var item:Item;
			var txt:String = 'You made ';
			var component:RecipeComponent;
			var i:int;
			var total_amount:int;
			
			//go through the outputs and multiply the amount to the amount output
			for(i; i < recipe.outputs.length; i++){
				component = recipe.outputs[int(i)];
				item = model.worldModel.getItemByTsid(component.item_class);
				if(item){
					total_amount = component.count * amount;
					txt += total_amount+'&nbsp;'+(total_amount != 1 ? item.label_plural : item.label);
					
					if(i < recipe.outputs.length-1) txt += ', ';
					if(recipe.outputs.length > 1 && i == recipe.outputs.length-2) txt += 'and ';
				}
			}
			
			txt += '!';
			
			return txt;
		}
		
		private function getSlugs(rewards:Vector.<Reward>):void {
			SpriteUtil.clean(slugs_holder);
			
			//throws the slugs in the holder and centers them
			const padd:int = 8;
			var next_x:int;
			var i:int;
			var total:int = rewards.length;
			var slug:Slug;
			
			for(i; i < total; i++){
				if(rewards[int(i)].amount != 0){
					slug = new Slug(rewards[int(i)]);
					slug.draw_border = false;
					slug.x = next_x;
					next_x += int(slug.width + padd);
					slugs_holder.addChild(slug);
				}
			}
			
			slugs_holder.y = int(made_tf.y + made_tf.height) + 15;
		}
		
		private function getUsed(recipe:Recipe, amount:int):void {
			SpriteUtil.clean(used_holder);
			
			const padd:uint = 7;
			var i:int;
			var slot:MakingSlot;
			var component:RecipeComponent;
			var item:Item;
			var remain_tf:TextField;
			var next_x:int = 2;
			var next_y:int;
			var has:int;
			var final_amount:int;
			
			//loop through the inputs to see how many we used
			for(i; i < recipe.inputs.length; i++){
				component = recipe.inputs[int(i)];
				item = model.worldModel.getItemByTsid(component.item_class);
				final_amount = component.count * amount;
				has = model.worldModel.pc.hasHowManyItems(component.item_class, component.consumable);
				
				if(item){
					slot = new MakingSlot(SLOT_WH, SLOT_WH);
					slot.update(component.item_class, final_amount, false, true);
					slot.qty_picker.y = 0;
					slot.item_label = final_amount != 1 ? item.label_plural : item.label;
					slot.close_button.visible = false;
					
					if(used_holder.x + next_x + slot.width > _w){
						next_x = 2;
						next_y += slot.height + 20;
					}
					
					slot.x = next_x;
					slot.y = next_y;
					used_holder.addChild(slot);
					
					next_x += slot.width + padd;
					
					if(has){
						remain_tf = new TextField();
						TFUtil.prepTF(remain_tf);
						remain_tf.width = slot.width - 2;
						remain_tf.y = SLOT_WH + 2;
						remain_tf.htmlText = '<p class="making_complete_remain">'+has+' '+(has != 1 ? 'remain' : 'remains')+'</p>';
						slot.addChild(remain_tf);
					}
				}
			}
			
			used_tf.y = !xp_warn_holder.visible ? int(slugs_holder.y + slugs_holder.height + 20) : int(xp_warn_holder.y + xp_warn_holder.height + 10);
			used_holder.y = int(used_tf.y + used_tf.height) + 5;
		}
		
		private function drawBG():void {
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0, 0);
			g.drawRect(0, 0, _w, height + 20);
		}
		
		private function onInfoClick(event:TSEvent):void {
			TSFrontController.instance.showItemInfo(String(event.data.value));
		}
	}
}