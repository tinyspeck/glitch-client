package com.tinyspeck.engine.view.ui.making
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.making.Recipe;
	import com.tinyspeck.engine.data.making.RecipeComponent;
	import com.tinyspeck.engine.data.skill.SkillDetails;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.net.NetOutgoingLocalChatVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.MakingDialog;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.ui.Keyboard;

	public class MakingComponentUI extends TSSpriteWithModel
	{
		private static const HEIGHT:uint = 51;
		private static const ICON_WH:uint = 30;
		private static const ICON_X:uint = 22;
		private static const MAX_LABEL_CHARS:uint = 25;
		private static const MAX_LABEL_CHARS_MISSING:uint = 20;
		
		private var icon_view:ItemIconView;
		private var tool_icon:ItemIconView;
		private var name_bt:Button;
		private var make_bt:Button;
		
		private var warning:DisplayObject;
		private var info:DisplayObject;
		
		private var have_tf:TextField = new TextField();
		private var tool_tf:TSLinkedTextField;
		
		private var _component:RecipeComponent;
		
		public function MakingComponentUI(component:RecipeComponent, w:int){
			_w = w;
			_component = component;
			
			name = component.item_class;
			
			//build the name button
			var item:Item = model.worldModel.getItemByTsid(component.item_class);
			var label:String;
			
			if(item){				
				label = component.count+' '+(component.count != 1 
					? (!component.consumable ? item.label_plural : item.consumable_label_plural) 
					: (!component.consumable ? item.label : item.consumable_label_single));
				
				name_bt = new Button({
					name: 'name',
					label: label,
					value: component.item_class,
					label_c: 0x005c73,
					label_bold: true,
					text_align: 'left',
					draw_alpha:0,
					offset_x:0,
					h: 14,
					x: ICON_X + ICON_WH + 10,
					y: 10
				});
				name_bt.addEventListener(TSEvent.CHANGED, onNameClick, false, 0, true);
				name_bt.addEventListener(MouseEvent.ROLL_OVER, onNameOver, false, 0, true);
				name_bt.addEventListener(MouseEvent.ROLL_OUT, onNameOut, false, 0, true);
				addChild(name_bt);
				
				//put the info graphic on there
				info = new AssetManager.instance.assets.making_info_small();
				info.x = int(name_bt.label_tf.x + name_bt.label_tf.width + 5);
				info.y = 2;
				onNameOut();
				name_bt.addChild(info);
				
				//how many do YOU have
				TFUtil.prepTF(have_tf, false);
				have_tf.htmlText = getHasString();
				have_tf.x = name_bt.x;
				have_tf.y = int(name_bt.y + name_bt.height) - 2;
				addChild(have_tf);
				
				refresh();
			}
			else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('BAD SHIT! This item was not found in the world model: '+component.item_class);
				}
			}
		}
		
		private function buildInfo():void {
			if(icon_view) icon_view.dispose();
			
			icon_view = new ItemIconView(component.item_class, ICON_WH);
			icon_view.x = ICON_X;
			icon_view.y = int(HEIGHT/2 - ICON_WH/2);
			addChild(icon_view);
			
			//show the warning icon if we need to
			if(!hasEnough() && !warning){
				addChild(buildWarningIcon());
			}
			else if(hasEnough() && warning){
				removeChild(warning);
				warning = null;
			}
		}
		
		private function buildWarningIcon():DisplayObject {
			warning = new AssetManager.instance.assets.store_warning();
			warning.x = 2;
			warning.y = int(HEIGHT/2 - warning.height/2);
			warning.alpha = .4;
			warning.name = 'warning';
			
			return warning;
		}
		
		private function getHasString():String {
			var has:int = model.worldModel.pc.hasHowManyItems(component.item_class, component.consumable);
			var txt:String = '<p class="making_component">';
			
			if(has < component.count){
				txt += '<span class="making_component_missing">';
				
				if(has == 0){
					txt += 'You don\'t have any!';
				}
				else {
					txt += 'You only have '+has+'!';
				}
				
				txt += '</span>';
			}
			else {
				txt += 'You have '+has;
			}
			
			txt += '</p>';
				
			return txt;
		}
		
		public function refresh():void {
			var recipe:Recipe = model.worldModel.getRecipeByOutputClass(name);
			var item:Item = model.worldModel.getItemByTsid(name);
			var label:String;
						
			//update the count
			have_tf.htmlText = getHasString();
			drawLines();
			buildInfo();
			
			//if this thing can be made somehow, add some more data
			if(recipe && recipe.tool){
				if(!tool_icon){
					tool_icon = new ItemIconView(recipe.tool, ICON_WH);
					tool_icon.x = _w - ICON_WH - 10;
					tool_icon.y = int(HEIGHT/2 - ICON_WH/2);
					addChild(tool_icon);
				}
				
				if(!tool_tf){
					tool_tf = new TSLinkedTextField();
					TFUtil.prepTF(tool_tf);
					tool_tf.width = 120;
					tool_tf.x = tool_icon.x - tool_tf.width - 3;
					addChild(tool_tf);
				}
				
				tool_tf.htmlText = getToolString(recipe);
				if(make_bt) make_bt.visible = !tool_tf.htmlText;
				
				//adjust the name button if the tool_tf has words
				if(item){
					label = component.count+' '+(component.count != 1 
						? (!component.consumable ? item.label_plural : item.consumable_label_plural) 
						: (!component.consumable ? item.label : item.consumable_label_single));
					
					//set the button label
					name_bt.label = StringUtil.truncate(label, tool_tf.htmlText ? MAX_LABEL_CHARS_MISSING : MAX_LABEL_CHARS);
					if(info) info.x = int(name_bt.label_tf.width);
				}
				
				if(tool_tf.htmlText){
					tool_tf.y = int(HEIGHT/2 - tool_tf.height/2);
				}
				else {
					//put the make button there
					if(!make_bt){
						make_bt = new Button({
							name: 'make',
							value: recipe.id,
							size: Button.SIZE_TINY,
							type: Button.TYPE_MINOR_INVIS
						});
						make_bt.addEventListener(TSEvent.CHANGED, onMakeClick, false, 0, true);
						addChild(make_bt);
					}
					make_bt.label = model.worldModel.pc.hasHowManyItems(component.item_class) == 0 ? 'Make' : 'Make More';
					make_bt.x = int(tool_icon.x - make_bt.width) - 3;
					make_bt.y = int(HEIGHT/2 - make_bt.height/2) - 1;
				}
			}
		}
		
		private function getToolString(recipe:Recipe):String {
			var tool_tsid:String = recipe.tool;
			var txt:String = '<p class="making_component"><span class="making_component_tool">';
			var bail_txt:String;
			var has_tool:int = model.worldModel.pc.hasHowManyItems(tool_tsid);
			var item:Item = model.worldModel.getItemByTsid(tool_tsid);
			var recipe_skill_details:SkillDetails = model.worldModel.getSkillDetailsByTsid(recipe.skill);
			var itemstack:Itemstack;
			var itemstack_tsids:Array;
			var i:int;
			var is_broken:Boolean = true;
			
			if(has_tool){
				//are any of them NOT broken?
				itemstack_tsids = model.worldModel.pc.tsidsOfAllStacksOfItemClass(tool_tsid);
				for(i; i < itemstack_tsids.length; i++){
					itemstack = model.worldModel.getItemstackByTsid(itemstack_tsids[int(i)]);
					if(itemstack && itemstack.tool_state && !itemstack.tool_state.is_broken && (itemstack.tool_state.points_capacity > 0 ? itemstack.tool_state.points_remaining > 0 : true)){
						is_broken = false;
						continue; // EC, I added this continue because without it is_broken can get set to true again by another one
					}
				}
				
				//is it broken?
				if(is_broken){
					bail_txt = 'You need a working '+item.label+' to make this';
				}
				//server says they can't do it, let's find out why!
				else if(recipe.disabled_reason){
					bail_txt = recipe.disabled_reason;
				}
				//do they have the skill
				else if(recipe_skill_details && model.worldModel.isSkillLearnable(recipe_skill_details.class_tsid)){
					//check the learnable skills, if it is learnable, it means they don't have the skill to do it
					bail_txt = 'You need <a href="event:'+TSLinkedTextField.LINK_SKILL+'|'+recipe_skill_details.class_tsid+'">'+recipe_skill_details.name+'</a> to make this';
				}
				//if it's discoverable and they haven't discovered it yet
				else if(recipe.discoverable && !recipe.can_make){
					bail_txt = 'You haven\'t <a href="event:'+TSLinkedTextField.LINK_RECIPE+'|try">discovered</a> this yet!';
				}
				//do they know the recipe
				else if(!recipe.discoverable && !recipe.can_make){
					bail_txt = 'You don\'t know how to make this';
				}
			}
			else {
				var tool_txt:String = 'You need ';
				
				//special case for construction and woodmaker tools
				if(item.tsid == 'construction_tool' || item.tsid == 'woodworker'){
					tool_txt = 'Use ';
				}
				tool_txt += StringUtil.aOrAn(item.label)+' <a href="event:'+TSLinkedTextField.LINK_ITEM+'|'+item.tsid+'">'+item.label+'</a>';
				bail_txt = tool_txt+' to make '+(model.worldModel.pc.hasHowManyItems(name) > 0 ? 'more of ' : '')+'this';
			}			
			
			//got a reason to bail?
			if(bail_txt){
				txt += bail_txt + '</span></p>';
				return txt;
			}
			//no? then we don't need to show anything
			else {
				return '';
			}
		}
		
		private function hasEnough():Boolean {
			var has:int = model.worldModel.pc.hasHowManyItems(component.item_class, component.consumable);
			if(has >= component.count) return true;
			
			return false;
		}
		
		private function drawLines():void {
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0xcfb0b0, hasEnough() ? 0 : 1);
			g.drawRect(0, 0, _w, 1);
			g.drawRect(0, HEIGHT-1, _w, 1);
		}
		
		private function onNameOver(event:MouseEvent):void {
			info.alpha = 1;
		}
		
		private function onNameOut(event:MouseEvent = null):void {
			info.alpha = .25;
		}
		
		private function onNameClick(event:TSEvent):void {
			//if we are a god and are ctrl clicking, throw the contents in the pack
			CONFIG::god {
				if(KeyBeacon.instance.pressed(Keyboard.CONTROL)) {
					TSFrontController.instance.sendLocalChat(
						new NetOutgoingLocalChatVO('/create item '+component.item_class+' '+(!component.consumable ? component.count : 1)+' in pack')
					);
					return;
				}
			}
			
			//open the get info window
			TSFrontController.instance.showItemInfo(String(event.data.value));
		}
		
		private function onMakeClick(event:TSEvent):void {
			//this will open a sub-creation screen
			MakingDialog.instance.startWithRecipeId(Button(event.data).value as String);
		}
		
		public function get component():RecipeComponent { return _component; }
	}
}