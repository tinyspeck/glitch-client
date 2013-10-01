package com.tinyspeck.engine.view.ui.making
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.making.Recipe;
	import com.tinyspeck.engine.data.making.RecipeComponent;
	import com.tinyspeck.engine.data.pc.PCSkill;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.data.skill.SkillDetails;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.MakingManager;
	import com.tinyspeck.engine.port.QuantityPicker;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.imagination.ImaginationSkillsUI;
	
	import flash.display.CapsStyle;
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class MakingDetailsUI extends TSSpriteWithModel
	{
		private static const ICON_HOLDER_WH:uint = 148;
		private static const PADD:uint = 20;
		private static const OFFSET_X:uint = 200;
		
		private var qp:QuantityPicker;
		private var make_bt:Button;
		private var info_bt:Button;
		
		private var item_holder:Sprite = new Sprite();
		private var component_holder:Sprite = new Sprite();
		
		private var title_tf:TextField = new TextField();
		private var subtitle_tf:TextField = new TextField();
		private var energy_tf:TextField = new TextField();
		
		private var itemstack_tsids:Array;
		
		private var current_recipe_id:String;
		
		public function MakingDetailsUI(recipe:Recipe, w:int){
			current_recipe_id = recipe.id;
			_w = w;
			
			name = recipe.id;
			
			//build out the item holder
			var g:Graphics = item_holder.graphics;
			g.lineStyle(1, 0xd4d4d4, 1, true, LineScaleMode.NONE, CapsStyle.ROUND);
			g.beginFill(0xffffff);
			g.drawRoundRect(0, 0, ICON_HOLDER_WH, ICON_HOLDER_WH, 14);
			item_holder.x = item_holder.y = PADD;
			addChild(item_holder);
			
			item_holder.addChild(getOutputIcon());
			
			//the info button below the icon
			info_bt = new Button({
				name: 'info',
				label: 'Info',
				label_size: 11,
				label_bold: true,
				label_c: 0x2c7487,
				label_offset: 1,
				value: recipe.outputs[0].item_class,
				draw_alpha: 0,
				graphic: new AssetManager.instance.assets.making_info(),
				graphic_placement: 'left',
				graphic_padd_r: 0
			});
			info_bt.x = PADD + int(item_holder.width/2 - info_bt.width/2);
			info_bt.y = PADD + int(item_holder.height + 10);
			info_bt.addEventListener(TSEvent.CHANGED, onInfoClick, false, 0, true);
			addChild(info_bt);
			
			//setup the title/subtitle
			TFUtil.prepTF(title_tf, false);
			title_tf.x = OFFSET_X;
			title_tf.y = PADD/2;
			addChild(title_tf);
			
			TFUtil.prepTF(subtitle_tf);
			subtitle_tf.x = OFFSET_X;
			subtitle_tf.width = _w - OFFSET_X;
			addChild(subtitle_tf);
			
			//build the qty picker
			qp = new QuantityPicker({
				name: 'qty',
				w: 120,
				h: 34,
				minus_graphic: new AssetManager.instance.assets.minus_red(),
				plus_graphic: new AssetManager.instance.assets.plus_green(),
				max_value: 1,
				min_value: 1,
				button_wh: 20,
				button_padd: 3,
				show_all_option: true
			});
			qp.x = OFFSET_X;
			qp.addEventListener(TSEvent.CHANGED, onQuantityChange, false, 0, true);
			qp.value = 1;
			addChild(qp);
			
			//make button
			make_bt = new Button({
				name: 'make',
				label: 'Make',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			make_bt.h = int(qp.height + 1);
			make_bt.x = int(qp.x + qp.width + 5);
			make_bt.addEventListener(TSEvent.CHANGED, onMakeClick, false, 0, true);
			addChild(make_bt);
			
			//energy tf
			TFUtil.prepTF(energy_tf);
			energy_tf.x = int(make_bt.x + make_bt.width + 10);
			energy_tf.width = _w - energy_tf.x;
			addChild(energy_tf);
			
			//place things
			setTitle();
			showComponents();
			
			component_holder.x = OFFSET_X;
			addChild(component_holder);
			
			g = graphics;
			g.beginFill(0, 0);
			g.drawRect(0, 0, _w, height + PADD);
			
			//listen to stats
			model.worldModel.registerCBProp(setMakeButton, "pc", "stats");
		}
		
		public function refresh(new_recipe:Recipe = null):void {
			if(new_recipe){
				current_recipe_id = new_recipe.id;
				while(item_holder.numChildren) item_holder.removeChildAt(0);
				item_holder.addChild(getOutputIcon());
			} 
			
			setTitle(new_recipe ? true : false);
			refreshTools();
		}
		
		private function setTitle(is_new:Boolean = true):void {
			var txt:String = '<p class="making_details_title">';
			
			qp.visible = false;
			make_bt.visible = false;
			
			//show how many we can make
			const missing_count:int = missingCount();
			if(missing_count == 0){
				var make_total:int = Math.min(recipe.task_limit, makeCount());
				
				qp.visible = true;
				if(is_new) qp.value = 1;
				qp.max_value = make_total;
				
				if (make_total == recipe.task_limit) {
					txt += "You can make "+make_total+" at a time";
				} else {
					txt += "You can make "+(make_total != 1 ? 'up to '+make_total : '1');
				}
				
				make_bt.visible = true;
				setMakeButton();
			}
			//we are missing everything!
			else if(missing_count == recipe.inputs.length){
				txt += "You're missing all of the ingredients!";
			}
			//tell them how many they are missing
			else {
				txt += "You're missing "+(missing_count == 1 ? 'an ingredient' : missing_count + ' ingredients')+"!";
			}
			
			txt += '</p>';
			title_tf.htmlText = txt;
			
			//handle the subtitle
			setSubtitle();
		}
		
		private function setSubtitle():void {
			var txt:String = '<p class="making_details_subtitle">';
			
			if(missingCount() == 0){
				txt += getLeftOvers();
			}
			
			txt += '</p>';
			subtitle_tf.htmlText = txt;
			
			subtitle_tf.y = int(title_tf.y + title_tf.height);
			qp.y = int(subtitle_tf.y + subtitle_tf.height + 10);
			make_bt.y = qp.y - 1;
			energy_tf.y = make_bt.y + int(make_bt.height/2 - energy_tf.height/2);
			energy_tf.visible = make_bt.visible;
			
			component_holder.y = int(qp.visible ? qp.y + qp.height + 17 : title_tf.y + title_tf.height + 10);
		}
		
		public function setMakeButton(pc_stats:PCStats = null):void {
			//stats have changed, make sure they can make what they need to make
			if(!make_bt.visible) return;
			
			const has_enough_energy:Boolean = model.worldModel.pc && model.worldModel.pc.stats 
											  ? model.worldModel.pc.stats.energy.value >= recipe.energy_cost * qp.value 
											  : false;
			
			var tip_txt:String;
			
			if(!has_enough_energy){
				tip_txt = 'You need more energy!';
			}
			else if(!recipe.isInput('fuel_cell')){
				//make sure it doesn't take a fuel_cell and it's not broken
				var i:int;
				var itemstack:Itemstack;
				var is_broken:Boolean = true;
				var item:Item = model.worldModel.getItemByTsid(recipe.tool);
				
				itemstack_tsids = model.worldModel.pc.tsidsOfAllStacksOfItemClass(recipe.tool);
				for(i; i < itemstack_tsids.length; i++){
					itemstack = model.worldModel.getItemstackByTsid(itemstack_tsids[int(i)]);
					if(itemstack && itemstack.tool_state && !itemstack.tool_state.is_broken && (itemstack.tool_state.points_capacity > 0 ? itemstack.tool_state.points_remaining > 0 : true)){
						is_broken = false;
					}
				}
				
				if(is_broken){
					tip_txt = 'You need a working '+(item ? item.label : 'tool')+' to make this';
				}
			}
			else if(recipe.isInput('fuel_cell')){
				//make sure we have enough of them
				const component:RecipeComponent = recipe.getComponentByItemTsid('fuel_cell');
				if(MakingManager.instance.making_info.fuel_remaining < component.count*qp.value){
					tip_txt = 'You need more fuel to make this';
				}
			}
			
			make_bt.disabled = tip_txt ? true : false;
			make_bt.tip = make_bt.disabled ? {txt:tip_txt, pointer:WindowBorder.POINTER_BOTTOM_CENTER} : null;
			
			//update the energy cost
			var energy_txt:String = '<p class="making_details_energy">Uses: ';
			if(!has_enough_energy) energy_txt += '<span class="making_details_warn">';
			energy_txt += StringUtil.formatNumberWithCommas(recipe.energy_cost * qp.value);
			energy_txt += ' energy';
			energy_txt += getFuelCost();
			if(!has_enough_energy) energy_txt += '</span>';
			energy_txt += '</p>';
			energy_tf.htmlText = energy_txt;
		}
		
		private function getLeftOvers():String {
			var txt:String = 'Leftovers: ';
			var i:int;
			var has_amount:Number;
			var has_left:Number;
			var component:RecipeComponent;
			var item:Item;
			var label:String;
			
			//loop through the components and see how many they are trying to make
			for(i; i < recipe.inputs.length; i++){
				component = recipe.inputs[int(i)];
				item = model.worldModel.getItemByTsid(component.item_class);
				
				if(component.item_class != 'fuel_cell'){
					has_amount = model.worldModel.pc.hasHowManyItems(component.item_class, component.consumable);
					has_left = has_amount - (qp.value*component.count);
					label = has_left != 1 
									? (!component.consumable ? item.label_plural : item.consumable_label_plural) 
									: (!component.consumable ? item.label : item.consumable_label_single);
				}
				else {
					has_amount = MakingManager.instance.making_info.fuel_remaining;
					has_left = has_amount - (qp.value*component.count);
					label = has_left != 1 ? 'Units of Fuel' : 'Unit of Fuel';
				}
				
				if(has_left >= 0){
					txt += has_left + '&nbsp;' + label;
				}
				
				if(i < recipe.inputs.length-1 && has_left >= 0) txt += ', ';
			}
			
			return txt;
		}
		
		private function getOutputIcon():ItemIconView {
			var icon_view:ItemIconView = new ItemIconView(recipe.outputs[0].item_class, ICON_HOLDER_WH - 50);
			icon_view.x = int(item_holder.width/2 - icon_view.width/2);
			icon_view.y = int(item_holder.height/2 - icon_view.height/2);
			
			return icon_view;
		}
		
		private function getFuelCost():String {
			var txt:String = '';
			var has_fuel:Boolean = true;
			const component:RecipeComponent = recipe.getComponentByItemTsid('fuel_cell');
			
			if (!component) return txt;
			
			if(MakingManager.instance.making_info.fuel_remaining < component.count*qp.value){
				has_fuel = false;
			}
			
			txt += '<br>\t&nbsp;&nbsp;&nbsp;';
			if(!has_fuel) txt += '<span class="making_details_warn">';
			txt += (component.count*qp.value)+'&nbsp;'+(component.count*qp.value != 1 ? 'units of fuel' : 'unit of fuel');
			if(!has_fuel) txt += '</span>';
			
			return txt;
		}
		
		private function showComponents():void {
			var i:int;
			var next_y:int;
			var component:RecipeComponent;
			var component_ui:MakingComponentUI;
			var unknown_tsids:Array = new Array();
			
			for(i; i < recipe.inputs.length; i++){
				component = recipe.inputs[int(i)];
				if(!MakingRecipeUI.isIgnored(component.item_class)){
					component_ui = new MakingComponentUI(component, _w - OFFSET_X);
					component_ui.y = next_y;
					component_holder.addChild(component_ui);
					
					next_y += component_ui.height - 1;
					
					if(!model.worldModel.getRecipeByOutputClass(component.item_class)){
						unknown_tsids.push(component.item_class);
					}
				}
			}
			
			//send the list of unknown class_tsids to the server to get recipes
			if(unknown_tsids.length){
				MakingManager.instance.recipeRequest(unknown_tsids, refreshTools);
			}
		}
		
		private function refreshTools(nrm:NetResponseMessageVO = null):void {
			//now that we have recipes, we need to get data about the tools that may be required
			var tool_tsids:Array = new Array();
			var component_ui:MakingComponentUI;
			var recipe:Recipe;
			var i:int;
			var item:Item;
			
			for(i; i < component_holder.numChildren; i++){
				component_ui = component_holder.getChildAt(i) as MakingComponentUI;
				recipe = model.worldModel.getRecipeByOutputClass(component_ui.name);
				
				//load the data about the tool if the player has it
				if(recipe && recipe.tool && tool_tsids.indexOf(recipe.tool) == -1){
					item = model.worldModel.getItemByTsid(recipe.tool);
					if(!item) tool_tsids.push(recipe.tool);
				} 
			}
						
			//get updated data of our tools!
			if(tool_tsids.length){
				MakingManager.instance.toolInfoRequest(tool_tsids, refreshSkills);
			}
			else {
				refreshSkills();
			}
		}
		
		private function refreshSkills(pc_skill:PCSkill = null):void {
			var details:SkillDetails;
			var component_ui:MakingComponentUI;
			var recipe:Recipe;
			var i:int;
			var refresh_skills:Boolean;
			
			for(i; i < component_holder.numChildren; i++){
				component_ui = component_holder.getChildAt(i) as MakingComponentUI;
				recipe = model.worldModel.getRecipeByOutputClass(component_ui.name);
				
				//do we know the skill for this tool?
				if(recipe && recipe.skill){
					details = model.worldModel.getSkillDetailsByTsid(recipe.skill);
					if(!details) {
						refresh_skills = true;
						break;
					}
				}
			}
			
			if(refresh_skills){
				ImaginationSkillsUI.instance.getSkillsFromServer(refreshComponents);
				//MakingManager.instance.skillInfoRequest(skill_tsids, refreshComponents);
			}
			else {
				refreshComponents();
			}
		}
		
		private function refreshComponents(nrm:NetResponseMessageVO = null):void {
			var component_ui:MakingComponentUI;
			var recipe:Recipe;
			var i:int;
			
			for(i; i < component_holder.numChildren; i++){
				component_ui = component_holder.getChildAt(i) as MakingComponentUI;
				recipe = model.worldModel.getRecipeByOutputClass(component_ui.name);
				if(recipe) component_ui.refresh();
			}
		}
		
		private function makeCount():int {
			//how many can they make based on everything they have
			var max_amount:int = 999;
			var has_amount:int;
			var i:int;
			var component:RecipeComponent;
			
			for(i; i < recipe.inputs.length; i++){
				component = recipe.inputs[int(i)];
				
				if(!MakingRecipeUI.isIgnored(component.item_class)){
					has_amount = model.worldModel.pc.hasHowManyItems(component.item_class, component.consumable);
					
					if(Math.floor(has_amount/component.count) < max_amount){
						max_amount = has_amount/component.count;
					}
				}
			}
			
			return max_amount;
		}
		
		private function missingCount():int {
			var missing:int;
			var i:int;
			var component:RecipeComponent;
			var has:int;
			
			for(i; i < recipe.inputs.length; i++){
				component = recipe.inputs[int(i)];
				has = model.worldModel.pc.hasHowManyItems(component.item_class, component.consumable);
				if(!MakingRecipeUI.isIgnored(component.item_class) &&  has < component.count) missing++;
			}

			return missing;
		}
		
		private function onQuantityChange(event:TSEvent):void {
			setSubtitle();
			setMakeButton();
		}
		
		private function onInfoClick(event:TSEvent):void {
			TSFrontController.instance.showItemInfo(String(event.data.value));
		}
		
		private function onMakeClick(event:TSEvent):void {
			if(make_bt.disabled) return;
			make_bt.disabled = true;
			
			MakingManager.instance.makeKnownRecipe(name, qp.value);
		}
		
		public function get recipe():Recipe { 
			return model.worldModel.getRecipeById(current_recipe_id);
		}
	}
}