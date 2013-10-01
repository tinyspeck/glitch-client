package com.tinyspeck.engine.view.ui.making
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.making.Recipe;
	import com.tinyspeck.engine.data.making.RecipeComponent;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.net.NetOutgoingLocalChatVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.MakingManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.ui.Keyboard;

	public class MakingRecipeUI extends TSSpriteWithModel {
		
		private static const TSIDS_TO_IGNORE:Array = new Array('fuel_cell');
		private static const BUTTON_PADD:uint = 10;
		private static const TEXT_PADD:uint = 12;
		private static const ICON_WH:uint = 45;
		private static const MAX_LABEL_CHARS:uint = 45;
		
		private var recipes:Vector.<Recipe>;
		private var try_bt:Button;
				
		public function MakingRecipeUI(recipes:Vector.<Recipe>, w:int){
			this.recipes = recipes;
			_w = w;
						
			refresh();
		}
		
		public function refresh(new_recipes:Vector.<Recipe> = null):void {
			//if anything has changed, go ahead and refresh the buttons
			var i:int;
			var bt:Button;
			var recipe:Recipe;
			var next_x:int;
			var next_y:int;
			var making_label:TextField;
			
			//update the recipes if there are new ones
			if(new_recipes) this.recipes = new_recipes;
			
			//sort the recipes by known/not known
			sortRecipes();
			
			//if we have the try button in place, let's make sure it's first
			if(MakingManager.instance.making_info.can_discover){
				if(!try_bt){
					try_bt = new Button({
						name: 'try',
						value: 'try',
						label: 'Try to make something new',
						label_bold: true,
						size: Button.SIZE_MAKING_RECIPE,
						type: Button.TYPE_MAKING_RECIPE,
						graphic: new AssetManager.instance.assets.empty_making_slot_small(),
						graphic_placement: 'left',
						graphic_padd_l: TEXT_PADD,
						use_hand_cursor_always: true
					});
				}
				addChild(try_bt);
				if(!try_bt.hasEventListener(TSEvent.CHANGED)) try_bt.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
				
				next_x += try_bt.width + BUTTON_PADD;
			}
			else if(try_bt) {
				removeChild(try_bt);
			}
			
			//loop through and put some buttons there
			for(i; i < recipes.length; i++){
				recipe = recipes[int(i)];
				
				bt = getChildByName(recipe.id) as Button;
				
				if(bt){
					bt.disabled = !MakingManager.instance.isRecipeMakeable(recipe);
					making_label = bt.getChildByName('making_label') as TextField;
					making_label.htmlText = buildLabel(recipe.id, false);
					
					//do we need the warning icon?
					if(bt.disabled && !bt.getChildByName('warning')){
						bt.addChild(buildWarningIcon());
					}
					else if(!bt.disabled && bt.getChildByName('warning')){
						bt.removeChild(bt.getChildByName('warning'));
					}
				}
				else {
					bt = buildButton(recipe);
				}
				
				//if it's too big, move it
				if(next_x + bt.width > _w){
					next_x = 0;
					next_y += bt.height + BUTTON_PADD;
				}
				
				bt.x = next_x;
				bt.y = next_y;
				
				next_x += bt.width + BUTTON_PADD;
			}
			
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0, 0);
			g.drawRect(0, 0, _w, height + BUTTON_PADD);
		}
		
		private function buildButton(recipe:Recipe):Button {
			//make the main button
			var bt:Button = new Button({
				name: recipe.id,
				value: recipe.id,
				label: '',
				size: Button.SIZE_MAKING_RECIPE,
				type: Button.TYPE_MAKING_RECIPE,
				graphic: new ItemIconView(recipe.outputs[0].item_class, ICON_WH, 'iconic'),
				graphic_placement: 'left',
				graphic_padd_l: TEXT_PADD,
				use_hand_cursor_always: true,
				disabled: !MakingManager.instance.isRecipeMakeable(recipe)
			});
			bt.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
			bt.addEventListener(MouseEvent.ROLL_OVER, onButtonOver, false, 0, true);
			bt.addEventListener(MouseEvent.ROLL_OUT, onButtonOut, false, 0, true);
			bt.cacheAsBitmap = true;
			
			addChild(bt);
			
			//put a warning icon on the button if they can't make it
			if(!MakingManager.instance.isRecipeMakeable(recipe)) bt.addChild(buildWarningIcon());
			
			//handle the label
			var label_tf:TextField = new TextField();
			TFUtil.prepTF(label_tf);
			label_tf.embedFonts = true;
			label_tf.name = 'making_label';
			label_tf.htmlText = buildLabel(recipe.id, false);
			label_tf.width = bt.width - ICON_WH - TEXT_PADD*3 + 6;
			label_tf.x = ICON_WH + TEXT_PADD*2;
			label_tf.y = int(bt.height/2 - label_tf.height/2);
			bt.addChild(label_tf);
			
			return bt;
		}
		
		private function buildWarningIcon():DisplayObject {
			var warning:DisplayObject = new AssetManager.instance.assets.store_warning();
			warning.x = warning.y = 5;
			warning.alpha = .4;
			warning.name = 'warning';
			
			return warning;
		}
				
		private function buildLabel(recipe_id:String, hover:Boolean):String {
			//loop through the components and make sure we have them
			//if not we need to make the title disabled
			var recipe:Recipe = model.worldModel.getRecipeById(recipe_id);
			var txt:String = '<p class="making_recipe">';
			
			if(MakingManager.instance.isRecipeMakeable(recipe)){
				if(!hover){
					txt += recipe.name;
				}
				else {
					txt += '<span class="making_recipe_hover">'+recipe.name+'</span>';
				}
			}
			//disabled state no matter what
			else {
				txt += '<span class="making_recipe_disabled">'+recipe.name+'</span>';
			}
			
			//component list
			txt += '<font size="5"><br><br></font>'+getComponentsString(recipe);
			
			txt += '</p>';
			
			return txt;
		}
		
		private function getComponentsString(recipe:Recipe):String {
			var i:int;
			var component:RecipeComponent;
			var txt:String = '<span class="making_recipe_components">';
			var item:Item;
			var label:String;
			var char_count:int = recipe.name.length;
			
			//sort the components before displaying them
			SortTools.vectorSortOn(recipe.inputs, ['item_class'], [Array.CASEINSENSITIVE]);
			recipe.inputs.sort(componentsSort);
			
			//loop through and show em
			for(i; i < recipe.inputs.length; i++){
				component = recipe.inputs[int(i)];
				
				if(!isIgnored(component.item_class)){
					item = model.worldModel.getItemByTsid(component.item_class);
					label = component.count != 1 
											? (!component.consumable ? item.label_plural : item.consumable_label_plural) 
											: (!component.consumable ? item.label : item.consumable_label_single); //we don't want to trunc the number
					char_count += label.length;
					
					if(char_count > MAX_LABEL_CHARS) {
						label = '...';
					}
					
					if(model.worldModel.pc.hasHowManyItems(component.item_class, component.consumable) < component.count) {
						txt += '<span class="making_recipe_components_missing">'+component.count+'&nbsp;'+label+'</span>';
					}
					else {
						txt += component.count+'&nbsp;'+label;
					}
					
					if(label == '...') break;
					
					txt += i < recipe.inputs.length-1 ? ', ' : '';
				}
			}
			
			//sometimes we may have a stragling trailing comma
			if(txt.substr(-2, 2) == ', ') txt = txt.substr(0, -2);
			
			txt += '</span>';
			
			return txt;
		}
		
		private function onButtonClick(event:TSEvent):void {
			var bt:Button = event.data as Button;
			
			//if we are god and need the stuff, handle it
			CONFIG::god {
				if(bt.disabled && KeyBeacon.instance.pressed(Keyboard.CONTROL)) {
					TSFrontController.instance.sendLocalChat(new NetOutgoingLocalChatVO('/ingredients '+bt.value));
				}
			}
			
			//let people know that the recipe was clicked was clicked
			dispatchEvent(new TSEvent(TSEvent.CHANGED, bt.value));
			
			//play a pretty sound
			SoundMaster.instance.playSound('CLICK_SUCCESS');
		}
		
		private function onButtonOver(event:MouseEvent):void {
			var bt:Button = event.currentTarget as Button;
			
			if(bt && !bt.disabled){
				var making_label:TextField = bt.getChildByName('making_label') as TextField;
				making_label.htmlText = buildLabel(bt.value, true);
			}
		}
		
		private function onButtonOut(event:MouseEvent):void {
			var bt:Button = event.currentTarget as Button;
			
			if(bt && !bt.disabled){
				var making_label:TextField = bt.getChildByName('making_label') as TextField;
				making_label.htmlText = buildLabel(bt.value, false);
			}
		}
		
		private function sortRecipes():void {
			var makeable:Vector.<Recipe> = new Vector.<Recipe>();
			var un_makeable:Vector.<Recipe> = new Vector.<Recipe>();
			var i:int;
			var recipe:Recipe;
			
			//divide them up
			for(i; i < recipes.length; i++){
				recipe = recipes[int(i)];
				if(MakingManager.instance.isRecipeMakeable(recipe)){
					makeable.push(recipe);
				}
				else {
					un_makeable.push(recipe);
				}
			}
			
			//order each alphabetically
			SortTools.vectorSortOn(makeable, ['name'], [Array.CASEINSENSITIVE]);
			SortTools.vectorSortOn(un_makeable, ['name'], [Array.CASEINSENSITIVE]);
			
			//smoosh it back together
			recipes = makeable.concat(un_makeable);
		}
		
		public function componentsSort(comA:RecipeComponent, comB:RecipeComponent):int {
			var hasA:int = model.worldModel.pc.hasHowManyItems(comA.item_class, comA.consumable);
			var hasB:int = model.worldModel.pc.hasHowManyItems(comB.item_class, comB.consumable);
			
			if(isIgnored(comA.item_class)) return -1;
			if(isIgnored(comB.item_class)) return 1;
			
			if(hasA != hasB){
				return hasA - hasB;
			}
			
			return 0;
		}
		
		public static function isIgnored(item_class:String):Boolean {
			const total:int = TSIDS_TO_IGNORE.length;
			var i:int;
			
			for(i; i < total; i++){
				if(TSIDS_TO_IGNORE[int(i)] == item_class) return true;
			}
			return false;
		}
	}
}