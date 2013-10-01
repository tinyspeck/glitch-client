package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.LocationConnection;
	import com.tinyspeck.engine.data.location.QuarterInfo;
	import com.tinyspeck.engine.data.location.SignPost;
	import com.tinyspeck.engine.model.MoveModel;
	import com.tinyspeck.engine.net.NetOutgoingTowerSetFloorNameVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.ButtonGrid;
	import com.tinyspeck.engine.view.ui.Dialog;
	import com.tinyspeck.engine.view.ui.ElevatorLabelUI;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.text.TextField;
	
	public class LocationSelectorDialog extends Dialog implements IFocusableComponent
	{
		/* singleton boilerplate */
		public static const instance:LocationSelectorDialog = new LocationSelectorDialog();
		
		private const ELEVATOR_PANEL_MIN_W:uint = 380;
		private const SHOW_DESTINATION:Boolean = true;
		private const ARROWS_WRAP:Boolean = false;
		
		private var buttons_holder:Sprite = new Sprite();
		private var bg_holder:Sprite = new Sprite();
		private var elevator_holder:Sprite = new Sprite();
		private var elevator_border:Sprite = new Sprite();
		private var elevator_blockers:Sprite = new Sprite();
		private var labels_holder:Sprite = new Sprite();
		
		private var title_tf:TextField = new TextField();
		private var brand_name_tf:TextField = new TextField();
		
		private var style:String;
		
		private var exit_bt:Button;
		private var signpost:SignPost;
		private var button_grid:ButtonGrid;
		private var buttonsV:Vector.<Button> = new Vector.<Button>();
		private var labelsV:Vector.<ElevatorLabelUI> = new Vector.<ElevatorLabelUI>();
		private var bg_pattern:BitmapData;
		
		private var current_choice_i:int;
		
		private var is_built:Boolean;
		private var is_saving_label:Boolean;
		
		public function LocationSelectorDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = ELEVATOR_PANEL_MIN_W;
			_draggable = false;
			_base_padd = 35;
			_outer_border_w = 8;
			_border_color = 0xffffff;
			_border_alpha = .6;
			bg_c = 0x282d30;
			
			_construct();
		}
		
		private function buildBase():void {
			//hide the skiny border by default
			window_border.setBorderColor(0,0);
			
			//build the quaters panel
			buildQuaterPanel();
			
			//build the elevator stuff
			buildElevatorPanel();
			
			//setup the buttons holder mouse events			
			buttons_holder.addEventListener(MouseEvent.CLICK, clickHandler);
			buttons_holder.addEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
			buttons_holder.addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
			
			window_border.addChild(buttons_holder);
			
			is_built = true;
		}
		
		private function buildQuaterPanel():void {
			//background image stuff
			var quarter_bg:DisplayObject = new AssetManager.instance.assets.quarter_bg();
			
			bg_pattern = new BitmapData(quarter_bg.width, quarter_bg.height);
			bg_pattern.draw(quarter_bg);
			
			window_border.addChild(bg_holder);
			
			//title TF
			var drop:DropShadowFilter = new DropShadowFilter();
			drop.color = 0xffffff;
			drop.distance = 1;
			drop.angle = 90;
			drop.alpha = .4;
			drop.blurX = drop.blurY = 0;
						
			TFUtil.prepTF(title_tf, false);
			title_tf.filters = [drop];
			title_tf.alpha = CSSManager.instance.getNumberValueFromStyle('location_selector_title', 'alpha', .8);
			window_border.addChild(title_tf);
		}
		
		private function buildElevatorPanel():void {
			var glow_in:GlowFilter = new GlowFilter();
			var glow_out:GlowFilter = new GlowFilter();
			var drop:DropShadowFilter = new DropShadowFilter();
			
			//main holder for all the elevator assets
			window_border.addChild(elevator_holder);
			
			//setup the rounded border around the buttons
			glow_in.color = 0;
			glow_in.alpha = .2;
			glow_in.blurX = glow_in.blurY = 2;
			glow_in.inner = true;
			
			glow_out.color = 0xFFFFFF;
			glow_out.alpha = .1;
			glow_out.blurX = glow_out.blurY = 2;
			
			elevator_border.filters = [glow_in, glow_out];
			elevator_holder.addChild(elevator_border);
			
			//this allows you to draw things over the border
			elevator_holder.addChild(elevator_blockers);
			
			//elevator brand name TF
			drop.color = 0xffffff;
			drop.distance = 1;
			drop.angle = 90;
			drop.alpha = .3;
			drop.blurX = drop.blurY = 0;
			
			TFUtil.prepTF(brand_name_tf, false);
			brand_name_tf.htmlText = '<p class="location_selector_ele_name">Vator Corp</p>';
			brand_name_tf.alpha = CSSManager.instance.getNumberValueFromStyle('location_selector_ele_name', 'alpha', .6);
			brand_name_tf.filters = [drop];
			elevator_holder.addChild(brand_name_tf);
			
			//add the labels if we are so inclined
			elevator_holder.addChild(labels_holder);
		}
		
		override protected function makeCloseBt():Button {
			return new Button({
				graphic: new AssetManager.instance.assets['close_x_small_gray'](),
				name: '_close_bt',
				h: 20,
				w: 20,
				draw_alpha: 0
			});
		}
		
		public function startWithSignpost(signpost:SignPost):Boolean {
			if (!signpost) return false;
			this.signpost = signpost;
			
			start();
			
			return true;
		}
		
		override public function start():void {
			if(!canStart(true)) return;
			
			if(!signpost){
				CONFIG::debugging {
					Console.warn('Need a valid signpost!');
				}
				return;
			}
			
			if(!is_built) buildBase();
			
			exit_bt = null;
			
			style = signpost.client::quarter_info.style;
			
			//reset
			buttonsV.length = 0;
			current_choice_i = -1;
			SpriteUtil.clean(buttons_holder);
			is_saving_label = false;
			
			//sort the connections
			if(signpost.connects){
				signpost.connects.sort(SortTools.connectionsSort);
			}
			
			_jigger();
			
			//display the right UI
			if(style == QuarterInfo.STYLE_APARTMENT) {
				showElevator();
			} 
			else if(style == QuarterInfo.STYLE_NORMAL){
				showQuarters();
			}
			else {
				setTitle('Where to?');
				CONFIG::debugging {
					Console.warn('Unreconized style: '+style);
				}
			}
			
			TSFrontController.instance.endFamiliarDialog();
			
			super.start();
		}
		
		override public function end(release:Boolean):void {
			if (parent) parent.removeChild(this);
			if (release) TSFrontController.instance.releaseFocus(this);
			
			super.end(release);
		}
		
		public function showFloorEditor(connect_id:String):void {
			//loop through them and make sure the others are disabled
			const total:int = labels_holder.numChildren;
			var label_ui:ElevatorLabelUI;
			var i:int;
			
			for(i; i < total; i++){
				label_ui = labels_holder.getChildAt(i) as ElevatorLabelUI;
				
				//close the UI if this isn't the one we are editing
				if(label_ui.id != connect_id) label_ui.onCloseClick();
			}
		}
		
		public function setFloorName(connect_id:String, new_label:String):void {
			if(connect_id && new_label){
				is_saving_label = true;
				TSFrontController.instance.genericSend(new NetOutgoingTowerSetFloorNameVO(connect_id, new_label), onSetFloorName, onSetFloorName);
			}
		}
		
		private function onSetFloorName(nrm:NetResponseMessageVO):void {
			//refresh the elevator buttons by getting the signpost again
			if(signpost){				
				//start it up
				startWithSignpost(model.worldModel.location.mg.getSignpostById(signpost.hashName));
			}
			
			is_saving_label = false;
		}
		
		override public function blur():void {
			if (has_focus) {
				//StageBeacon.waitForNextFrame(end, true);
			}
			super.blur();
		}
		
		private function showElevator():void {			
			const bt_type:String = Button.TYPE_ELEVATOR_GRODDLE;
			const bt_size:String = Button.SIZE_ELEVATOR_GRODDLE;
			const total:int = signpost.connects.length;
			const max_row:int = total > 10 ? Math.min(Math.floor(total/2), 10) : 10; //helps in the times where there isn't a lot of floors, but more than 10
			const info:QuarterInfo = signpost.client::quarter_info;
			const h_padding:int = 4;
			const v_padding:int = 0;
			var i:int;
			var bt:Button;
			var bt_data:Object;			
			var next_x:int;
			var next_y:int;
			var connect:LocationConnection;
			var label_ui:ElevatorLabelUI;
			var bt_disabled:Boolean;
			var cur_row:int = 1;
			var label_pool:int;
			
			setTitle('');
			
			if(!parent) SoundMaster.instance.playSound('ELEVATOR_OPENS');
			
			//reset the label pool
			for(i = 0; i < labelsV.length; i++){
				labelsV[int(i)].hide();
			}
							
			for(i = 0; i < total; i++) {
				connect = signpost.connects[int(i)];
				
				bt_disabled = (connect.button_position == 'exit' && info.row == 0 && info.col == 0) || 
					          (connect.button_position == info.col+'_'+info.row);
				bt = null; //clear this out every loop
				
				bt_data = {
					name: connect.button_position,
					label: connect.button_position == 'exit' ? 'Lobby' : connect.button_position.split('_')[1],
					value: i,
					x: next_x,
					y: next_y,
					type: bt_type,
					size: bt_size,
					graphic: new AssetManager.instance.assets.elevator_normal(),
					graphic_disabled: new AssetManager.instance.assets.elevator_disabled(),
					graphic_hover: new AssetManager.instance.assets.elevator_hover(),
					tip: (false) ? {txt: connect.label, pointer: WindowBorder.POINTER_BOTTOM_CENTER} : null,
					disabled: bt_disabled
				}
				
				if(!connect.hidden){
					bt = new Button(bt_data);
				}
				else {
					//show hidden places for admins
					CONFIG::god {
						bt_data.type = Button.TYPE_DARK;
						bt = new Button(bt_data);
					}
				}
				
				if(bt){
					var default_label:String = 'Lobby';
					if (bt.name == 'exit') {
						exit_bt = bt; //save this to add it to end of buttonsV, and to reference when needed using arrow keys
					} else {
						buttonsV.push(bt);
						default_label = StringUtil.addSuffix(connect.button_position.split('_')[1])+' Floor';
					}
					
					//place the label there
					if(labelsV.length > label_pool){
						label_ui = labelsV[int(label_pool)];
					}
					else {
						//make a new one
						label_ui = new ElevatorLabelUI();
						labelsV.push(label_ui);
					}
					
					label_ui.width = _w - labels_holder.x - _base_padd*2 - elevator_border.x*2;
					label_ui.show(connect.hashName, default_label, connect.custom_label);
					label_ui.enabled = model.worldModel.pc.home_info.playerIsAtHome();
					labels_holder.addChild(label_ui);
					label_pool++;
											
					buttons_holder.addChild(bt);
					next_y -= bt.h + v_padding;
					if(cur_row == max_row){
						cur_row = 0;
						next_x += bt.w + h_padding;
						next_y = 0;
					}
					cur_row++;
				}
			}
			
			if (exit_bt) buttonsV.push(exit_bt);
			
			//after they are in position, shift them down so they aren't in negative Y space
			const bt_offset:int = buttons_holder.height - (bt ? bt.h - v_padding : 0);
			for(i = 0; i < buttons_holder.numChildren; i++){
				bt = buttons_holder.getChildAt(i) as Button;
				bt.y += bt_offset;
				
				//place the label as well
				label_ui = labels_holder.getChildAt(i) as ElevatorLabelUI;
				label_ui.y = int(bt.y + (bt.height/2 - label_ui.height/2));
			}
						
			focusDefaultChoice();
		}
		
		private function showQuarters():void {						
			var i:int;
			var total:int = signpost.connects.length;
			var bt:Button;
			var bt_data:Object;
			var bt_type:String = Button.TYPE_QUARTER;
			var bt_size:String = Button.SIZE_DEFAULT;
			var bt_label:String;
			var connect:LocationConnection;
			var bt_disabled:Boolean;
			var info:QuarterInfo = signpost.client::quarter_info;
			
			//show a grid version of the quarters
			setTitle(info.label);
				
			for(i = 0; i < total; i++) {
				connect = signpost.connects[int(i)];
				
				bt_disabled = (connect.button_position == 'exit' && info.row == 0 && info.col == 0) || (connect.button_position == info.col+'_'+info.row);
				bt = null; //clear this out every loop
				bt_label = connect.button_position != 'exit' ? String(parseInt(connect.label.split(',')[1])) : 'Exit to '+connect.label;
				bt_data = {
					name: connect.button_position,
					label: bt_label,
					value: i,
					type: bt_type,
					size: bt_size,
					disabled: bt_disabled
				}
				
				if(!connect.hidden){
					bt = new Button(bt_data);
				}
				else {
					//show hidden places for admins
					CONFIG::god {
						bt_data.type = Button.TYPE_DARK;
						bt = new Button(bt_data);
					}
				}
				
				if(bt){
					if (bt.name == 'exit') {
						exit_bt = bt; //save this to add it to end of buttonsV, and to reference when needed using arrow keys
					} else {
						buttonsV.push(bt);
					}
				}
			}
			
			if (exit_bt) buttonsV.push(exit_bt);
			
			//build the button grid
			var init_ob:Object = {
				buttonsV: buttonsV,
				rows: info.rows,
				cols: info.cols,
				current_row: info.row,
				current_col: info.col,
				min_button_w: 65,
				min_button_h: 39,
				max_button_w: 100,
				max_button_h: 62,
				h_padding: 12,
				v_padding: 8,
				max_w: 690,
				max_h: 422,
				show_disabled_pattern: true,
				disabled_pattern: createDisabledPattern()
			}
				
			if(!button_grid){
				button_grid = new ButtonGrid(init_ob);
			}
			else {
				button_grid.init_ob = init_ob;
			}
			buttons_holder.addChild(button_grid);
			
			//create the exit button
			if(exit_bt){
				exit_bt.y = button_grid.height + init_ob.v_padding + 2;
				exit_bt.w = int(button_grid.width) + 2;
				exit_bt.h = init_ob.min_button_h;
				buttons_holder.addChild(exit_bt);
			}
			
			focusDefaultChoice();
		}
		
		private function setTitle(txt:String):void {
			title_tf.htmlText = '<p class="location_selector_title">'+txt+'</p>';
		}
		
		override protected function _jigger():void {
			title_tf.x = _base_padd;
			title_tf.y = _base_padd - 10;
			
			buttons_holder.y = int(title_tf.y + title_tf.height + 5);
						
			_w = Math.max(buttons_holder.width, title_tf.x + title_tf.width + _close_bt.width + _base_padd, ELEVATOR_PANEL_MIN_W) + _base_padd*2;
			_h = buttons_holder.y + buttons_holder.height + _base_padd;
						
			if(style == QuarterInfo.STYLE_APARTMENT){
				//the buttons are always in the same place now
				buttons_holder.x = 46;
			}
			else {
				buttons_holder.x = int(_w/2 - buttons_holder.width/2);
			}
			elevator_border.x = int(_base_padd/2) + 4;
			elevator_border.y = int(_base_padd/2) + 4;
			
			labels_holder.x = int(buttons_holder.x + buttons_holder.width + elevator_border.x + _base_padd/2);
			labels_holder.y = int(buttons_holder.y); 
			
			super._jigger();
			
			var g:Graphics;
			if(bg_pattern && style == QuarterInfo.STYLE_NORMAL){
				g = bg_holder.graphics;
				g.clear();
				g.beginBitmapFill(bg_pattern);
				g.drawRoundRect(0, 0, _w, _h, window_border.corner_rad*2);
				bg_holder.visible = true;
				elevator_holder.visible = false;
			}
			else {
				//draw the outter border
				g = elevator_border.graphics;
				g.clear();
				g.beginFill(bg_c);
				g.drawRoundRect(0, 0, _w-_base_padd - 8, _h-_base_padd - 8, window_border.corner_rad*2);
				
				//the vertical line to the right of the buttons
				g.drawRect(int(buttons_holder.x + buttons_holder.width + 4), 10, 1, _h-_base_padd - 28);
				
				//position the brand name
				brand_name_tf.x = int(_w/2 - brand_name_tf.width/2);
				brand_name_tf.y = int(elevator_border.y + elevator_border.height - brand_name_tf.height/2);
				
				//draw "blockers" to hide the lines behind the brand and the X button
				g = elevator_blockers.graphics;
				g.clear();
				g.beginFill(bg_c);
				g.drawRect(brand_name_tf.x - 8, brand_name_tf.y, brand_name_tf.width + 16, brand_name_tf.height);
				g.beginFill(bg_c);
				g.drawRect(_close_bt.x - 10, _close_bt.y, _close_bt.width + 10, _close_bt.height + 10);
				
				bg_holder.visible = false;
				elevator_holder.visible = true;
			}
			
			//center the title
			title_tf.x = int(_w/2 - title_tf.width/2);
		}
		
		private function getDefaultChoiceIndex():int {
			return buttonsV.length-1; //last
		}
		
		override protected function upArrowKeyHandler(e:KeyboardEvent):void {
			if (style == QuarterInfo.STYLE_APARTMENT){
				focusPrevChoice();
			} else if (style == QuarterInfo.STYLE_NORMAL){
				focusUpChoice();
			}
			
		}
		
		override protected function rightArrowKeyHandler(e:KeyboardEvent):void {
			if (style == QuarterInfo.STYLE_APARTMENT){
				focusNextChoice();
			} else if (style == QuarterInfo.STYLE_NORMAL){
				focusRightChoice();
			}
			
		}
		
		override protected function downArrowKeyHandler(e:KeyboardEvent):void {
			if (style == QuarterInfo.STYLE_APARTMENT){
				focusNextChoice();
			} else if (style == QuarterInfo.STYLE_NORMAL){
				focusDownChoice();
			}
		}
		
		override protected function leftArrowKeyHandler(e:KeyboardEvent):void {
			if (style == QuarterInfo.STYLE_APARTMENT){
				focusPrevChoice();
			} else if(style == QuarterInfo.STYLE_NORMAL){
				focusLeftChoice();
			}
		}
		
		
		override protected function enterKeyHandler(e:KeyboardEvent):void {
			if (!buttonsV.length) return;
			makeChoice();
		}
		
		private function mouseOverHandler(e:Event):void {
			if (e.target is Button) {
				focusChoice(getIndexOfButton(e.target as Button));
			}
		}
		
		private function mouseOutHandler(e:Event):void {
			if (e.target is Button) {
				focusChoice(current_choice_i);
			}
		}
		
		private function clickHandler(e:Event):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			if (e.target is Button) {
				focusChoice(getIndexOfButton(e.target as Button));
				makeChoice(true);
			}
		}
		
		private function makeChoice(by_click:Boolean = false):void {
			if (current_choice_i < 0 || current_choice_i > buttonsV.length-1) return;
			if(is_saving_label){
				//can't go anywhere yet
				SoundMaster.instance.playSound('CLICK_FAILURE');
			}
			else {
				onButtonChosen(buttonsV[current_choice_i]);
			}
		}
		
		private function onButtonChosen(bt:Button):void {
			if(bt && !bt.disabled){
				//tell the server we want to go!
				var connect:LocationConnection = signpost.connects[bt.value];
				if(!connect){
					CONFIG::debugging {
						Console.error('connect could not be found from bt.value: '+bt.value);
					}
					//SoundMaster.instance.playSound('CLICK_FAILURE');
					return;
				}
				
				if(style == QuarterInfo.STYLE_APARTMENT){
					SoundMaster.instance.playSound('CHOOSE_LEVEL');
				}
				else {
					SoundMaster.instance.playSound('CLICK_SUCCESS');
				}
				
				TSFrontController.instance.startLocationMove(
					false,
					MoveModel.SIGNPOST_MOVE,
					signpost.tsid,
					connect.street_tsid,
					connect.hashName
				);
				
				end(true);
			} else {
				
				SoundMaster.instance.playSound('CLICK_FAILURE');
			}
		}
		
		private function getIndexOfButton(bt:Button):int {
			return buttonsV.indexOf(bt);
		}
		
		private function getButtonAtIndex(i:int):Button {
			if (i<0 || i>buttonsV.length-1) {
				//Console.error('i out of range:'+i+' '+(buttonsV.length-1));
				return null;
			}
			return buttonsV[int(i)];
		}
		
		private function getButtonAtColRow(col:int, row:int):Button {
			for (var i:int;i<buttonsV.length;i++) {
				if (buttonsV[int(i)].name == (col+'_'+row)) return buttonsV[int(i)];
			}
			return null;
		}
		
		private function getButtonAboveButton(bt:Button):Button {
			var i:int;
			var bt2:Button;
			var info:QuarterInfo = signpost.client::quarter_info;
			
			// special case for exit button
			if (bt.name == 'exit') {
				// get the last button on the last row
				for (i=info.cols;i>0;i--) {
					bt2 = getButtonAtColRow(i, info.rows);
					if (bt2) return bt2;
				}
				return null;
			}
			
			var A:Array = bt.name.split('_');
			var col:int = A[0];
			var row:int = A[1];
			i = row-1;
			while (i != row) {
				if (i == 0) {
					if (ARROWS_WRAP) {
						i = info.rows;
					} else {
						return null;
					}
				}
				bt2 = getButtonAtColRow(col, i);
				if (bt2) return bt2;
				i--;
			}
			
			return null;
		}
		
		private function getButtonToRightOfButton(bt:Button):Button {
			if (bt.name == 'exit') {
				return null;
			}
			
			var bt2:Button;
			var A:Array = bt.name.split('_');
			var col:int = A[0];
			var row:int = A[1];
			var i:int = col+1;
			var info:QuarterInfo = signpost.client::quarter_info;
			while (i != col) {
				if (i > info.cols) {
					if (ARROWS_WRAP) {
						i = 1;
					} else {
						return null;
					}
				}
				bt2 = getButtonAtColRow(i, row);
				if (bt2) return bt2;
				i++;
			}
			
			return null;
		}
		
		private function getButtonBelowButton(bt:Button):Button {
			if (bt.name == 'exit') {
				return null;
			}
			
			var bt2:Button;
			var A:Array = bt.name.split('_');
			var col:int = A[0];
			var row:int = A[1];
			var i:int = row+1;
			var info:QuarterInfo = signpost.client::quarter_info;
			while (i != row) {
				if (i > info.rows) {
					if (ARROWS_WRAP) {
						i = 1;
					} else {
						// special case for last row
						if (row == info.rows) {
							if (exit_bt) return exit_bt;
						}
						return null;
					}
				}
				bt2 = getButtonAtColRow(col, i);
				if (bt2) return bt2;
				i++;
			}
			
			return null;
		}
		
		private function getButtonToLeftOfButton(bt:Button):Button {
			if (bt.name == 'exit') {
				return null;
			}
			
			var bt2:Button;
			var A:Array = bt.name.split('_');
			var col:int = A[0];
			var row:int = A[1];
			var i:int = col-1;
			var info:QuarterInfo = signpost.client::quarter_info;
			while (i != col) {
				if (i == 0) {
					if (ARROWS_WRAP) {
						i = info.cols;
					} else {
						return null;
					}
				}
				bt2 = getButtonAtColRow(i, row);
				if (bt2) return bt2;
				i--;
			}
			
			return null;
		}
		
		//------------------------------------------------------------
		// CHOICE BUTTON FOCUS METHODS
		
		private function focusDefaultChoice():void {
			focusChoice(getDefaultChoiceIndex());
		}
		
		private function focusChoice(i:int):void {
			var bt:Button;
			if (current_choice_i != i) {
				if (current_choice_i != -1) {
					bt = getButtonAtIndex(current_choice_i);
					if (bt) bt.blur();
				}
				current_choice_i = i;
			}
			
			if (getButtonAtIndex(i)) {
				bt = getButtonAtIndex(i);
				if (bt) bt.focus();
				updateAfterButtonFocus();
			}
		}
		
		private function updateAfterButtonFocus():void {
			
		}
		
		private function focusChoiceByFunction(btGetter:Function):Boolean {
			var bt:Button = getButtonAtIndex(current_choice_i);
			if (!bt) return false;
			
			var bt2:Button = btGetter(bt);
			if (bt2) {
				SoundMaster.instance.playSound('CLICK_SUCCESS');
				focusChoice(buttonsV.indexOf(bt2));
				return true;
			}
			
			return false;
		}
		
		private function focusUpChoice():void {
			if (!button_grid) return;
			if (!buttonsV.length) return;
			
			focusChoiceByFunction(getButtonAboveButton);
		}
		
		private function focusRightChoice():void {
			if (!button_grid) return;
			if (!buttonsV.length) return;
			
			focusChoiceByFunction(getButtonToRightOfButton);
		}
		
		private function focusDownChoice():void {
			if (!button_grid) return;
			if (!buttonsV.length) return;
			
			focusChoiceByFunction(getButtonBelowButton);
		}
		
		private function focusLeftChoice():void {
			if (!button_grid) return;
			if (!buttonsV.length) return;
			
			focusChoiceByFunction(getButtonToLeftOfButton);
		}
		
		private function focusNextChoice():void {
			if (!buttonsV.length) return;
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			if (current_choice_i-1 < 0) {
				focusChoice(buttonsV.length-1);
			} else {
				focusChoice(current_choice_i-1);
			}
		}
		
		private function focusPrevChoice():void {
			if (!buttonsV.length) return;
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			if (current_choice_i+1 >= buttonsV.length) {
				focusChoice(0);
			} else {
				focusChoice(current_choice_i+1);
			}
		}
		
		// END CHOICE BUTTON FOCUS METHODS
		//------------------------------------------------------------
		
		private function createDisabledPattern():BitmapData {
			//black lines, 45 degress, 2px fat, 60% alpha
			var bd:BitmapData = new BitmapData(6, 6, true, 0);
			var c:uint = 0x60000000;
			
			bd.lock();
			bd.setPixel32(0, 0, c);
			bd.setPixel32(1, 0, c);
			bd.setPixel32(2, 0, c);
			bd.setPixel32(0, 1, c);
			bd.setPixel32(1, 1, c);
			bd.setPixel32(5, 1, c);
			bd.setPixel32(0, 2, c);
			bd.setPixel32(4, 2, c);
			bd.setPixel32(5, 2, c);
			bd.setPixel32(3, 3, c);
			bd.setPixel32(4, 3, c);
			bd.setPixel32(5, 3, c);
			bd.setPixel32(2, 4, c);
			bd.setPixel32(3, 4, c);
			bd.setPixel32(4, 4, c);
			bd.setPixel32(1, 5, c);
			bd.setPixel32(2, 5, c);
			bd.setPixel32(3, 5, c);
			bd.unlock();
			
			return bd;
		}
	}
}