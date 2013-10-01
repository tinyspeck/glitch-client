package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.InteractionMenuController;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.item.Verb;
	import com.tinyspeck.engine.data.item.VerbKeyTrigger;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.Door;
	import com.tinyspeck.engine.data.location.SignPost;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.memory.EnginePools;
	import com.tinyspeck.engine.model.InteractionMenuModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.IDisposableSpriteChangeHandler;
	import com.tinyspeck.engine.port.QuantityPickerSpecial;
	import com.tinyspeck.engine.port.TSSprite;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.spritesheet.AvatarSSManager;
	import com.tinyspeck.engine.spritesheet.SSViewSprite;
	import com.tinyspeck.engine.util.DrawUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.PCView;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.geo.DoorView;
	import com.tinyspeck.engine.view.geo.SignpostView;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	
	public class InteractionMenu extends Sprite implements IFocusableComponent, IDisposableSpriteChangeHandler
	{
		private static const POINTER_H:int = 46;
		private static const POINTER_W:int = 35;
		private static const POINTER_OFFSET_X:int = 15;
		private static const POINTER_TIP_RADIUS:int = 10;
		private static const PADD:int = 5;
		private static const CUI_MARGIN:int = 0;
		private static const VERB_MIN_W:int = 140;
		private static const COUNT_MIN_W:int = 240;
		private static const TARGET_ITEM_MIN_W:int = 240;
		private static const CURVE_CONTROL_POINT:Point = new Point(9, 10);
		
		private var key_hash:Object = {};
		
		private var has_focus:Boolean;
		private var model:TSModelLocator;
		private var imm:InteractionMenuModel;
		private var _mainView:TSMainView;
		
		private var verb_holder_sp:Sprite;
		private var verb_cuis_sp:Sprite;
		private var verb_pointer_sp:Sprite;
		private var verb_pointer_highlight_normal_sh:Sprite;
		private var verb_pointer_highlight_inert_sh:Sprite;
		private var verb_info_cui:FormElement;
		
		private var count_holder_sp:Sprite;
		private var count_cuis_sp:Sprite;
		
		private var target_item_holder_sp:Sprite;
		private var target_item_cuis_sp:Sprite;
		
		private var title_tf:TextField = new TextField();
		private var desc_tf:TextField = new TextField();
		private var choiceUIV:Vector.<FormElement> = new Vector.<FormElement>();
		
		private var lis_view:LocationItemstackView;
		private var pc_view:PCView;
		
		
		private var cui_grid_rows:int;
		private var cui_grid_cols:int;
		private var _curr_choice_i:int;
		private var curr_coll_i:int = curr_choice_i % cui_grid_cols;
		private var curr_row_i:int = curr_choice_i / cui_grid_cols;
		
		// maps quantity pickers to choice objects, so we can update the
		//choice object when the qp changed event fires
		private var qp_choice_map:Dictionary;
		private var current_qp:QuantityPickerSpecial;

		private function get curr_choice_i():int {
			return _curr_choice_i;
		}

		private function set curr_choice_i(value:int):void {
			_curr_choice_i = value;
			if (_curr_choice_i == -1) {
				curr_coll_i = -1;
				curr_row_i = -1;
			} else {
				curr_coll_i = curr_choice_i % cui_grid_cols;
				curr_row_i = curr_choice_i / cui_grid_cols;
			}
		}
		
		private var widest_cui_w:int = 0;
		
		public var interaction_tsid:String;
		public var interaction_type:String;
		
		private var background_color:uint = 0xffffff;
		private var background_alpha:Number = .95;
		private var animation_speed:Number = .2;
		private var animation_type:String = 'easeInCubic';
		private var waiting_spinner:MovieClip = new AssetManager.instance.assets.spinner();
		
		/* singleton boilerplate */
		public static const instance:InteractionMenu = new InteractionMenu();

		public function InteractionMenu(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			model = TSModelLocator.instance;
			registerSelfAsFocusableComponent();
			imm = model.interactionMenuModel;
			
			//load values from CSS
			background_color = CSSManager.instance.getUintColorValueFromStyle('context_bg', 'color', background_color);
			background_alpha = CSSManager.instance.getNumberValueFromStyle('context_bg', 'alpha', background_alpha);
			animation_speed = CSSManager.instance.getNumberValueFromStyle('context_bg', 'animationSpeed', animation_speed);
			animation_type = CSSManager.instance.getStringValueFromStyle('context_bg', 'animationType', animation_type);
			
			////////////////////////////////
			
			constructVerbMenuStuff();
			constructCountMenuStuff();
			constructTargetItemMenuStuff();
			constructVerbAndCountTfs();
			
			////////////////////////////////
			
			filters = StaticFilters.black2px90Degrees_DropShadowA;
		}
		
		private function get mainView():TSMainView {
			if (!_mainView) _mainView = TSFrontController.instance.getMainView();
			return _mainView;
		}
		
		private var controller:InteractionMenuController;
		public function setController(controller:InteractionMenuController):void {
			this.controller = controller;
		}
		
		private function constructVerbAndCountTfs():void {
			
			title_tf.embedFonts = true;
			title_tf.multiline = true;
			title_tf.wordWrap = true;
			title_tf.antiAliasType = AntiAliasType.ADVANCED;
			title_tf.styleSheet = CSSManager.instance.styleSheet;
			title_tf.htmlText = '<span class="context_verb_title">Title</span>';
			title_tf.x = PADD;
			title_tf.borderColor = background_color;
			title_tf.border = false;
			title_tf.selectable = false;
			
			desc_tf.embedFonts = true;
			desc_tf.multiline = true;
			desc_tf.wordWrap = true;
			desc_tf.antiAliasType = AntiAliasType.ADVANCED;
			desc_tf.styleSheet = CSSManager.instance.styleSheet;
			desc_tf.htmlText = '<span class="context_verb_desc">Description</span>';
			desc_tf.x = PADD;
			desc_tf.borderColor = background_color;
			desc_tf.border = false;
			desc_tf.selectable = false;
		}
		
		private function constructCountMenuStuff():void {
			count_holder_sp = new Sprite();
			count_cuis_sp = new Sprite();
			count_holder_sp.addChild(count_cuis_sp);
		}
		
		private function constructTargetItemMenuStuff():void {
			target_item_holder_sp = new Sprite();
			target_item_holder_sp.name = 'target_item_holder_sp';
			target_item_cuis_sp = new Sprite();
			target_item_cuis_sp.name = 'target_item_cuis_sp';
			
			target_item_holder_sp.addChild(target_item_cuis_sp);
		}
		
		private function constructVerbMenuStuff():void {
			
			verb_holder_sp = new Sprite();
			verb_cuis_sp = new Sprite();
			verb_holder_sp.addChild(verb_cuis_sp);
			
			verb_pointer_sp = new Sprite();
			verb_pointer_sp.useHandCursor = verb_pointer_sp.buttonMode = true;
			verb_pointer_sp.mouseChildren = false;
			
			// replace this with pngs when you have it, I guess *****************************************************
			// FUCK THAT, LET'S DRAW THIS SHIT BOYEEE!
			
			var g:Graphics = verb_pointer_sp.graphics;
			g.clear();
			g.lineStyle(0, 0, 0);
			g.beginFill(background_color, background_alpha);
			g.moveTo(0, 0);
			g.lineTo(POINTER_W, 0);
			g.curveTo(POINTER_W - CURVE_CONTROL_POINT.x, CURVE_CONTROL_POINT.y, POINTER_W-POINTER_TIP_RADIUS + 1, POINTER_H-POINTER_TIP_RADIUS*2 + 5);
			g.lineTo(POINTER_TIP_RADIUS - 1, POINTER_H-POINTER_TIP_RADIUS*2 + 5);
			g.curveTo(CURVE_CONTROL_POINT.x, CURVE_CONTROL_POINT.y, 0, 0);
			g.endFill();
			
			g.beginFill(background_color, background_alpha);
			DrawUtil.drawArc(g, POINTER_W/2, POINTER_H-POINTER_TIP_RADIUS, -30, 210, POINTER_TIP_RADIUS, 1);
			g.endFill();
			
			verb_pointer_highlight_inert_sh = new Sprite();
			verb_pointer_highlight_inert_sh.x = 3; //x and y makes it so the image is 1 pixel overlaping the button
			verb_pointer_highlight_inert_sh.y = -7; //to give the illusion that the line flows nice
			verb_pointer_highlight_inert_sh.addChild(new AssetManager.instance.assets.int_menu_dis());
			verb_pointer_sp.addChild(verb_pointer_highlight_inert_sh);
			verb_pointer_highlight_inert_sh.visible = false;
			
			verb_pointer_highlight_normal_sh = new Sprite();
			verb_pointer_highlight_normal_sh.x = 3;
			verb_pointer_highlight_normal_sh.y = -7;
			verb_pointer_highlight_normal_sh.addChild(new AssetManager.instance.assets.int_menu_norm());
			verb_pointer_sp.addChild(verb_pointer_highlight_normal_sh);
			verb_pointer_highlight_normal_sh.visible = false;
			
			// end replace ********************************************************************************************
			
			verb_pointer_sp.x = POINTER_OFFSET_X;
			verb_holder_sp.addChild(verb_pointer_sp);
			
			waiting_spinner.scaleX = waiting_spinner.scaleY = .5;
			
			waiting_spinner.x = 5;
			waiting_spinner.y = 5;
			waiting_spinner.visible = false;
			verb_holder_sp.addChild(waiting_spinner);
		}
		
		public function placehold(place_under_cursor:Boolean = false):void {
			CONFIG::debugging {
				Console.log(35, 'placehold '+imm.type);
			}
			switch (imm.type) {
				
				case InteractionMenuModel.TYPE_LOC_IST_VERB_MENU:
				case InteractionMenuModel.TYPE_PACK_IST_VERB_MENU:
				case InteractionMenuModel.TYPE_IST_VERB_COUNT:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM_COUNT:
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK_COUNT:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_LOC_DISAMBIGUATOR:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_PC:
				case InteractionMenuModel.TYPE_LOC_PC_VERB_MENU:
				case InteractionMenuModel.TYPE_LIST_PC_VERB_MENU:
				case InteractionMenuModel.TYPE_LIST_GROUP_VERB_MENU:
				case InteractionMenuModel.TYPE_HUBMAP_STREET_MENU:
				case InteractionMenuModel.TYPE_GARDEN_VERB_MENU:
				case InteractionMenuModel.TYPE_GARDEN_PLANT_SEED:
					
					break;
				default:
					CONFIG::debugging {
						Console.error('unknown interaction_type:'+interaction_type);
					}
					return;
			}
			
			if (model.stateModel.focused_component != this && !TSFrontController.instance.requestFocus(this, imm.type)) {
				CONFIG::debugging {
					Console.warn('could not take focus');
				}
				return;
			}
			
			closed = false;
			
			interaction_tsid = imm.active_tsid;
			interaction_type = imm.type;
			lis_view = (interaction_tsid) ? mainView.gameRenderer.getItemstackViewByTsid(interaction_tsid) : null;
			pc_view = (interaction_tsid) ? mainView.gameRenderer.getPcViewByTsid(interaction_tsid) : null;
			
			clean();
			
			// we're going to always use the verb stuff for this placeholder, no matter what the interaction_type is
			
			verb_pointer_sp.visible = place_under_cursor;
			hideVerbPointerHighlights();
			
			addChild(verb_holder_sp);
			
			title_tf.htmlText = '<span class="context_verb_title"></span>';
			title_tf.y = PADD; // NOTE: WE SET THIS HERE BECAUSE WE DO NOT WANT JIGGER TO DO IT
			desc_tf.htmlText = '<span class="context_verb_desc">       working...</span>';
			waiting_spinner.visible = true;
			verb_holder_sp.addChild(title_tf);
			verb_holder_sp.addChild(desc_tf);
			
			jigger();
			place(place_under_cursor);
			
			mainView.addInteractionMenuToDefaultLocation();
			
			visible = true;
			alpha = 0;
			TSTweener.removeTweens(this);
			TSTweener.addTween(this, {alpha:1, time:.1, delay:0, transition:'linear'});
			keepInBounds();
		}
		
		public function present(title:String, place_under_cursor:Boolean = false):void {
			CONFIG::debugging {
				Console.log(35, 'started '+imm.type+' closed:'+closed);
			}
			
			qp_choice_map = new Dictionary(true);
			current_qp = null;
			
			if (imm.choices.length == 0) {
				model.activityModel.growl_message = 'I have nothing for you!';
				makeNoChoice();
				return;
			}
			
			interaction_tsid = imm.active_tsid;
			interaction_type = imm.type;
			lis_view = (interaction_tsid) ? mainView.gameRenderer.getItemstackViewByTsid(interaction_tsid) : null;
			pc_view = (interaction_tsid) ? mainView.gameRenderer.getPcViewByTsid(interaction_tsid) : null;
			
			var do_place:Boolean = true;
			if (closed) {
				placehold(place_under_cursor);
			} else {
				// in these cases, we do not want to place again, because we want to rely on the placement done
				// in the initial call to placehold() (otherwise, we replace it where the mouse has move to in the time it took for the verbs to come back)
				if (interaction_type == InteractionMenuModel.TYPE_LOC_IST_VERB_MENU) do_place = false; // it was already placed
				if (interaction_type == InteractionMenuModel.TYPE_PACK_IST_VERB_MENU) do_place = false; // it was already placed
				if (interaction_type == InteractionMenuModel.TYPE_GARDEN_VERB_MENU) do_place = false; // it was already placed
			}
			
			clean();
			
			//make sure vag can show this
			const vag_ok:Boolean = StringUtil.VagCanRender(title);
			title_tf.embedFonts = vag_ok;
			if(vag_ok){
				title_tf.htmlText = '<span class="context_verb_title">'+title+'</span>';
			}
			else {
				title_tf.htmlText = '<span class="context_verb_title_no_embed">'+title+'</span>';
			}
			title_tf.visible = true;
			title_tf.x = PADD;
			
			hideVerbPointerHighlights();
			
			switch (interaction_type) {
				case InteractionMenuModel.TYPE_LOC_IST_VERB_MENU:
				case InteractionMenuModel.TYPE_PACK_IST_VERB_MENU:
				case InteractionMenuModel.TYPE_LOC_PC_VERB_MENU:
				case InteractionMenuModel.TYPE_LIST_PC_VERB_MENU:
				case InteractionMenuModel.TYPE_LIST_GROUP_VERB_MENU:
				case InteractionMenuModel.TYPE_HUBMAP_STREET_MENU:
				case InteractionMenuModel.TYPE_GARDEN_VERB_MENU:
					buildVerbCUIs();
					addChild(verb_holder_sp);
					verb_holder_sp.addChild(title_tf);
					title_tf.y = PADD; // NOTE: WE SET THIS HERE BECAUSE WE DO NOT WANT JIGGER TO DO IT
					verb_holder_sp.addChild(desc_tf);
					
					if (getCUIAtIndex(getDefaultChoiceIndex()) && getCUIAtIndex(getDefaultChoiceIndex()).disabled) {
						showVerbPointerHighlightInert();
					} else {
						showVerbPointerHighlightNormal();
					}
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_COUNT:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM_COUNT:
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK_COUNT:
					buildCountCUIs();
					addChild(count_holder_sp);
					count_holder_sp.addChild(title_tf);
					title_tf.htmlText = '<p align="center">'+title_tf.htmlText+'</p>';
					title_tf.y = PADD; // NOTE: WE SET THIS HERE BECAUSE WE DO NOT WANT JIGGER TO DO IT
					count_holder_sp.addChild(desc_tf);
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_PC:
				case InteractionMenuModel.TYPE_LOC_DISAMBIGUATOR:
				case InteractionMenuModel.TYPE_GARDEN_PLANT_SEED:
					buildTargetItemCUIs();
					addChild(target_item_holder_sp);
					target_item_holder_sp.addChild(title_tf);
					title_tf.y = PADD; // NOTE: WE SET THIS HERE BECAUSE WE DO NOT WANT JIGGER TO DO IT
					target_item_holder_sp.addChild(desc_tf);
					
					break;
				
				default:
					CONFIG::debugging {
						Console.error('unknown interaction_type:'+interaction_type);
					}
					return;
			}
			
			
			waiting_spinner.visible = false;
			focusDefaultChoice();
			
			jigger();
			if (do_place) place(place_under_cursor);
			keepInBounds();
			
			addEventListener(MouseEvent.CLICK, clickHandler);
			addEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
			addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
		}
		
		private function showVerbPointerHighlightInert():void {
			verb_pointer_highlight_inert_sh.visible = true;
			verb_pointer_highlight_normal_sh.visible = false;
		}
		
		private function showVerbPointerHighlightNormal():void {
			verb_pointer_highlight_normal_sh.visible = true;
			verb_pointer_highlight_inert_sh.visible = false;
		}
		
		private function hideVerbPointerHighlights():void {
			verb_pointer_highlight_normal_sh.visible = false;
			verb_pointer_highlight_inert_sh.visible = false;
		}
		
		public function buildTargetItemCUIs():void {
			var g:Graphics = target_item_cuis_sp.graphics;
			g.clear();
			g.lineStyle(0, 0, 1);
			
			var target_item_cui:FormElement;
			var A:Array = imm.choices;
			
			var b_wh:int = 50; // need to get this value from cui_count style
			var b_padd:int = 5;
			var icon_wh:int = b_wh-(b_padd*2)
			var line_c:Number = 0xcbe3e9;
			var c:*;
			var cols:int;
			
			if (A.length > 7) {
				cols = cui_grid_cols = Math.max(4, Math.floor(Math.sqrt(A.length))+4);
			} else {
				cols = cui_grid_cols = Math.min(7, A.length);
			}
			
			var rows:int = cui_grid_rows = Math.ceil(A.length/cols);
			var col:int;
			var row:int;
			var label:String = '';
			var cui_name:String = '';
			var icon:DisplayObject;
			var b:Bitmap;
			var rect:Rectangle;
			var bitmapdata:BitmapData;
			
			for (var i:int;i<A.length;i++) {
				col = (i % cols);
				row = Math.floor(i / cols);
				c = A[int(i)];
				
				label = '';
				icon = null;
				cui_name = (c is String) ? 'c' : c.tsid; // this is optimistic; might need to set cui_name in the ifs below
				var s:Object;
				var itemstack:Itemstack;
				
				if (c is String) {
					label = c;
				} else if (c is LocationItemstackView) {
					itemstack = model.worldModel.getItemstackByTsid(c.tsid);
					s = (itemstack.itemstack_state && Item.shouldUseCurrentStateForIconView(itemstack.class_tsid)) ? itemstack.itemstack_state : null;
					icon = new ItemIconView(itemstack.class_tsid, icon_wh, s, 'default', false, true, false, true);
				} else if (c is PCView || c is PC) {
					var pc:PC = (c is PCView) ? model.worldModel.getPCByTsid(c.tsid) : c;
					var ss_view:SSViewSprite = AvatarSSManager.getSSForAva(pc.ac, pc.sheet_url).getViewSprite();
					ss_view.gotoAndStop(13, 'walk1x');
					icon = ss_view;
					/*var g2:Graphics = ss_view.graphics;
					g2.lineStyle(0,0,1)
					g2.drawRect(0,0,icon.width, icon.height)*/
					ss_view.scaleY = .3;
					ss_view.scaleX = ss_view.scaleY;
					
				} else if (c is DoorView || c is SignpostView) {
					var interaction_target:DisplayObject = TSSprite(c).interaction_target;
					
					// each door and signpost config is slightly different
					// so just get an absolute bounding box even though it's a little more expensive
					// (probably only one door or signpost per InteractionMenu)
					rect = SpriteUtil.getVisibleBounds(interaction_target, interaction_target);
					
					var m:Matrix = EnginePools.MatrixPool.borrowObject();
					
					// make sure the origin is the top left corner
					m.translate(-rect.x, -rect.y);
					
					// scale it down to fit
					var scale:Number;
					if (rect.width > rect.height) {
						scale = (icon_wh / rect.width);
					} else {
						scale = (icon_wh / rect.height);
					}
					m.scale(scale, scale);
						
					// center it in the bitmap
					m.translate((icon_wh - rect.width*scale)/2, (icon_wh - rect.height*scale)/2);
					
					// draw it
					bitmapdata =  new BitmapData(icon_wh, icon_wh, true, background_color);
					bitmapdata.draw(interaction_target, m);
					EnginePools.MatrixPool.returnObject(m);
					m = null;
					
					b = new Bitmap(bitmapdata);
					b.smoothing = true;
					
					icon = b;
				} else if (c is Item) {
					label = '';
					icon = new ItemIconView(c.tsid, icon_wh, null, 'default', false, true, false, true);
				} else if (c is Itemstack) {
					label = '';
					itemstack = c as Itemstack;
					s = (itemstack.itemstack_state && Item.shouldUseCurrentStateForIconView(itemstack.class_tsid)) ? itemstack.itemstack_state : null;
					icon = new ItemIconView(c.class_tsid, icon_wh, s, 'default', false, true, false, true);
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.error('wtf');
					}
				}
				
				target_item_cui = new Button({
					label: label,
					graphic: icon,
					graphic_placement: 'center',
					name: cui_name,
					value: i,
					size: Button.SIZE_50,
					type: Button.TYPE_VERB,
					w: b_wh,
					h: b_wh,
					y: row*(b_wh+2),
					x: col*(b_wh+2)
				});
				
				if (label == 'x') target_item_cui.label = '<span class="context_close">x</span>';
				
				target_item_cuis_sp.addChild(target_item_cui);
				choiceUIV.push(target_item_cui);
				
			}
			
			target_item_cuis_sp.x = Math.round((calcWidth()/2)-(target_item_cuis_sp.width/2));
			
			g.lineStyle(0, 0, 0);
			g.beginFill(0xcc0000, 0);
			g.drawRect(0, 0, target_item_cuis_sp.width, b_wh);
			g.endFill();
		}
		
		private function buildCountCUIs():void {
			var g:Graphics = count_cuis_sp.graphics;
			g.clear();
			g.lineStyle(0, 0, 1);
			
			var count_cui:FormElement;
			var A:Array = imm.choices;
			
			var b_h:int = 36; // need to get this value from cui_count style
			var line_c:Number = 0xcbe3e9;
			var label:String;
			var choice:Object;
			var value:int;
			for (var i:int;i<A.length;i++) {
				
				if (i == 0) {
					g.lineStyle(0, line_c, 0);
					g.moveTo(0,0);
					g.lineTo(0, b_h);
				}
				
				choice = A[int(i)];
				
				if (typeof choice == 'object') {
					// it must be special
					label = choice.value+' '+choice.type;
					value = choice.value;
					
					var char_num:int = choice.max_value.toString().length;
					
					count_cui = new QuantityPickerSpecial({
						label: label,
						name: value,
						value: value,
						w: 50 + (char_num*9) + (choice.show_go_option?30:0),
						h: 30,
						minus_graphic: new AssetManager.instance.assets.minus_red(),
						plus_graphic: new AssetManager.instance.assets.plus_green(),
						max_value: choice.max_value,
						min_value: 1,
						button_wh: 20,
						button_padd: 3,
						show_all_option: false,
						outside_border_size: 2,
						outside_border_c: /*0xd79035*/0xe1c38d,
						outside_border_c2: /*0xd79035*/0xf1dcb6, // slightly lighter color than outside_border_c
						input_border_color: 0xd7cec0,
						y: 3,
						x: count_cuis_sp.width+4,
						show_go_option: choice.show_go_option
					});
					
					qp_choice_map[count_cui] = choice;
					current_qp = count_cui as QuantityPickerSpecial;
					count_cui.addEventListener(TSEvent.CHANGED, onQuantityPickerChange, false, 0, true);

				} else {
					// assume it is a number
					label = String(choice)
					value = int(choice);
					
					count_cui = new Button({
						label: label,
						name: value,
						value: value,
						size: Button.SIZE_COUNT,
						type: Button.TYPE_VERB,
						y: 0,
						x: count_cuis_sp.width+2
					});
				}
				
				//set labels after because of the stripping of the HTML
				if (value == 0) count_cui.label = '<span class="context_close">x</span>';
				if (value == 1) count_cui.label = '<span class="context_count_small">Just</span>\r<span class="context_count_large">One</span>';
				if (imm.default_to_one) {
					if (i == 1) count_cui.label = '<span class="context_count_small">All</span>\r<span class="context_count_large">'+label+'</span>';
				} else {
					if (i == 0) count_cui.label = '<span class="context_count_small">All</span>\r<span class="context_count_large">'+label+'</span>';
				}
				
				if (count_cui.width < 30) count_cui.w = 30;
				count_cuis_sp.addChild(count_cui);
				
				if (i==A.length-1) {
					g.lineStyle(0, line_c, 0);
				} else {
					g.lineStyle(0, line_c, 1);
				}
				g.moveTo(count_cui.x+count_cui.width+3, 0);
				g.lineTo(count_cui.x+count_cui.width+3, b_h);
				
				choiceUIV.push(count_cui);
			}
			
			count_cuis_sp.x = Math.round((calcWidth()/2)-(count_cuis_sp.width/2));
			
			g.lineStyle(0, 0, 0);
			g.beginFill(0xcc0000, 0);
			g.drawRect(0, 0, count_cuis_sp.width, b_h);
			g.endFill();
		}
		
		private function onQuantityPickerChange(e:TSEvent):void {
			if (!closed && e && (e.data is QuantityPickerSpecial) && qp_choice_map[e.data]) {
				qp_choice_map[e.data].value = QuantityPickerSpecial(e.data).value;
				updateAfterCUIFocus();
			}
		}
		
		public function calcWidth():int {
			switch (interaction_type) {
				case InteractionMenuModel.TYPE_LOC_IST_VERB_MENU:
				case InteractionMenuModel.TYPE_PACK_IST_VERB_MENU:
				case InteractionMenuModel.TYPE_LOC_PC_VERB_MENU:
				case InteractionMenuModel.TYPE_LIST_PC_VERB_MENU:
				case InteractionMenuModel.TYPE_LIST_GROUP_VERB_MENU:
				case InteractionMenuModel.TYPE_HUBMAP_STREET_MENU:
				case InteractionMenuModel.TYPE_GARDEN_VERB_MENU:
					if (choiceUIV.length > 1) { // just in case we get no verbs, but only have the info special verb, make sure we have > 1
						return widest_cui_w+(PADD*2)
					} else {
						return VERB_MIN_W;
					}
				case InteractionMenuModel.TYPE_IST_VERB_COUNT:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM_COUNT:
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK_COUNT:
					if (choiceUIV.length) {
						return Math.max(COUNT_MIN_W, count_cuis_sp.width+(PADD*2));
					} else {
						return COUNT_MIN_W;
					}
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_PC:
				case InteractionMenuModel.TYPE_LOC_DISAMBIGUATOR:
				case InteractionMenuModel.TYPE_GARDEN_PLANT_SEED:
					if (choiceUIV.length) {
						return Math.max(TARGET_ITEM_MIN_W, target_item_cuis_sp.width+(PADD*2));
					} else {
						return TARGET_ITEM_MIN_W;
					}
				default:
					CONFIG::debugging {
						Console.error('unknown interaction_type:'+interaction_type);
					}
					return 0;
			}
		}
		
		public function goAway():void {
			if (closed) return;
			makeNoChoice();
		}
		
		public function buildVerbCUIs():void {
			var verb_cui:FormElement;
			var verb:Verb;
			var A:Array = imm.choices;
			var verb_cui_count:int;
			var default_verb:Verb;
			var item:Item;
			var vkt:VerbKeyTrigger;
			var key_code:uint;
			var prefix:String;
			for (var i:int;i<A.length;i++) {
				key_code = 0;
				vkt = null;
				if (A[int(i)] is Verb) {
					prefix = '';
					verb = A[int(i)];
					item = model.worldModel.getItemByItemstackId(imm.active_tsid);
					
					if (imm.type == InteractionMenuModel.TYPE_LOC_IST_VERB_MENU || imm.type == InteractionMenuModel.TYPE_GARDEN_VERB_MENU) {
						vkt = item.getLocVerbKeyTriggerByVerbTsid(verb.tsid);
					} else if (imm.type == InteractionMenuModel.TYPE_PACK_IST_VERB_MENU) {
						vkt = item.getPackVerbKeyTriggerByVerbTsid(verb.tsid);
					}
					
					if (verb.tsid == Item.CLIENT_INFO) {
						verb_cui = createInfoCUI(verb.tsid, true);
						verb_cui.y = 0;
						verb_cui.x = 0;
						
						verb_holder_sp.addChild(verb_cui);
						verb_info_cui = verb_cui;
					} else {
						
						if (verb.sort_on<50) {
							prefix = 'A:';
						}
						
						verb_cui = new Button({
							label: prefix+StringUtil.capitalizeFirstLetter(verb.label),
							name: verb.tsid,
							value: verb.tsid,
							size: Button.SIZE_VERB,
							type: Button.TYPE_VERB,
							disabled: !verb.enabled,
							text_align: 'left',
							label_offset: 1
						});
						if(vkt){
							//underline the shortcut key
							verb_cui.label = prefix+StringUtil.underlineLetter(StringUtil.capitalizeFirstLetter(verb.label), vkt.key_str);
						}
						
						verb_cui.x = PADD;
						verb_cui.y = (verb_cui_count*(verb_cui.height+CUI_MARGIN));
						verb_cuis_sp.addChild(verb_cui);
						verb_cui_count++;
					}
					
					choiceUIV.push(verb_cui);
					
					if (vkt) {
						setCUIIndexForKeyCode(choiceUIV.length-1, vkt.key_code);
					}
					
				} else if (A[int(i)] is Object) {
					var ob:Object = A[int(i)];
					
					if ([InteractionMenuModel.VERB_SPECIAL_PC_INFO, InteractionMenuModel.VERB_SPECIAL_LOCATION_INFO].indexOf(ob.value) != -1) {
						verb_cui = createInfoCUI(ob.value, false);
						verb_cui.y = 0;
						verb_cui.x = 0;
						
						verb_holder_sp.addChild(verb_cui);
						verb_info_cui = verb_cui;
						
					} else {
						verb_cui = new Button({
							label: StringUtil.capitalizeFirstLetter(ob.label),
							name: ob.value,
							value: ob.value,
							size: Button.SIZE_VERB,
							type: Button.TYPE_VERB,
							disabled: ob.disabled,
							text_align: 'left'
						});
						
						verb_cui.x = PADD;
						verb_cui.y = (verb_cui_count*(verb_cui.height+CUI_MARGIN));
						verb_cuis_sp.addChild(verb_cui);
						verb_cui_count++;
					}
					choiceUIV.push(verb_cui);
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('unknown value in imm.interaction_menu_choices:'+A[int(i)]);
					}
				}
				
				// is this the widest yet? ignore the verb_info_cui
				if (verb_cui && verb_cui != verb_info_cui && widest_cui_w < verb_cui.width) widest_cui_w = verb_cui.width;
			}
			
			// make them all the widest size
			for (i=0;i<choiceUIV.length;i++) {
				verb_cui = getCUIAtIndex(i);
				if (verb_cui == verb_info_cui) continue; // ignore the verb_info_cui, as it is placed special
				if (verb_cui.width < widest_cui_w) verb_cui.w = widest_cui_w;
			}
		}
		
		private function createInfoCUI(bt_value:*, has_key_trigger:Boolean):FormElement {
			var bt:Button = new Button({
				label: '', //set it after so it can have HTML
				name: bt_value,
				value: bt_value,
				size: Button.SIZE_MICRO_NO_SHADOW,
				type: Button.TYPE_MINOR_BORDER
			});
			if (has_key_trigger) {
				bt.label = '<u>I</u>nfo';
			} else {
				bt.label = 'Info';
			}
			
			return bt;
		}
		
		private function clean():void {
			if (verb_holder_sp.parent) verb_holder_sp.parent.removeChild(verb_holder_sp);
			if (count_holder_sp.parent) count_holder_sp.parent.removeChild(count_holder_sp);
			if (target_item_holder_sp.parent) target_item_holder_sp.parent.removeChild(target_item_holder_sp);
			
			SpriteUtil.clean(count_cuis_sp, true);
			SpriteUtil.clean(verb_cuis_sp, true);
			SpriteUtil.clean(target_item_cuis_sp, true);
			
			if (verb_info_cui && verb_info_cui.parent) verb_info_cui.parent.removeChild(verb_info_cui);
			choiceUIV.length = 0;
			curr_choice_i = -1;
			widest_cui_w = VERB_MIN_W-(PADD*2);
			key_hash = {}
		}
		
		private function jigger():void {
			title_tf.height = title_tf.textHeight+4;
			title_tf.width = calcWidth()-(PADD*2);
			
			desc_tf.height = desc_tf.textHeight+4;
			desc_tf.width = calcWidth()-(PADD*2);
			desc_tf.y = title_tf.y+title_tf.height-3;//+PADD;
			
			switch (interaction_type) {
				case InteractionMenuModel.TYPE_LOC_IST_VERB_MENU:
				case InteractionMenuModel.TYPE_PACK_IST_VERB_MENU:
				case InteractionMenuModel.TYPE_LOC_PC_VERB_MENU:
				case InteractionMenuModel.TYPE_LIST_PC_VERB_MENU:
				case InteractionMenuModel.TYPE_LIST_GROUP_VERB_MENU:
				case InteractionMenuModel.TYPE_HUBMAP_STREET_MENU:
				case InteractionMenuModel.TYPE_GARDEN_VERB_MENU:
					verb_cuis_sp.y = Math.round(desc_tf.y+desc_tf.height+PADD);
					verb_pointer_sp.y = Math.round(verb_cuis_sp.y+verb_cuis_sp.height+(PADD*2))-3; //gives equal padding all around
					
					if (verb_info_cui) verb_info_cui.y = 0; // for measuring
					draw();
					
					verb_holder_sp.x = Math.round(-POINTER_OFFSET_X-(POINTER_W/2));
					verb_holder_sp.y = Math.round(POINTER_TIP_RADIUS-verb_pointer_sp.y-POINTER_H);
					
					if (verb_info_cui){
						verb_info_cui.y = -Math.round(verb_info_cui.height/2);
						verb_info_cui.x = Math.round(calcWidth()-verb_info_cui.width-5);
					}
					
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_COUNT:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM_COUNT:
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK_COUNT:
					count_cuis_sp.y = Math.round(desc_tf.y+desc_tf.height+PADD);
					
					draw();
					
					count_holder_sp.x = -Math.round(calcWidth()/2);
					count_holder_sp.y = Math.round(-count_holder_sp.height);
					
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_PC:
				case InteractionMenuModel.TYPE_LOC_DISAMBIGUATOR:
				case InteractionMenuModel.TYPE_GARDEN_PLANT_SEED:
					target_item_cuis_sp.y = Math.round(desc_tf.y+desc_tf.height+PADD);
					
					draw();
					
					target_item_holder_sp.x = -Math.round(calcWidth()/2);
					target_item_holder_sp.y = Math.round(-target_item_holder_sp.height);
					
					break;
				
				default:
					CONFIG::debugging {
						Console.error('unknown interaction_type:'+interaction_type);
					}
					return;
			}
		}
		
		private function draw():void {
			var g:Graphics;
			switch (interaction_type) {
				case InteractionMenuModel.TYPE_LOC_IST_VERB_MENU:
				case InteractionMenuModel.TYPE_PACK_IST_VERB_MENU:
				case InteractionMenuModel.TYPE_LOC_PC_VERB_MENU:
				case InteractionMenuModel.TYPE_LIST_PC_VERB_MENU:
				case InteractionMenuModel.TYPE_LIST_GROUP_VERB_MENU:
				case InteractionMenuModel.TYPE_HUBMAP_STREET_MENU:
				case InteractionMenuModel.TYPE_GARDEN_VERB_MENU:
					g = verb_holder_sp.graphics;
					g.clear();
					g.lineStyle(0, 0, 0);
					g.beginFill(background_color, background_alpha);
					g.drawRoundRect(0, 0, calcWidth(), verb_pointer_sp.y, 10);
					g.endFill();
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_COUNT:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM_COUNT:
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK_COUNT:
					g = count_holder_sp.graphics;
					g.clear();
					g.lineStyle(0, 0, 0);
					g.beginFill(background_color, background_alpha);
					g.drawRoundRect(0, 0, calcWidth(), count_holder_sp.height+(PADD*2), 10);
					g.endFill();
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_PC:
				case InteractionMenuModel.TYPE_LOC_DISAMBIGUATOR:
				case InteractionMenuModel.TYPE_GARDEN_PLANT_SEED:
					g = target_item_holder_sp.graphics;
					g.clear();
					g.lineStyle(0, 0, 0);
					g.beginFill(background_color, background_alpha);
					g.drawRoundRect(0, 0, calcWidth(), target_item_holder_sp.height+(PADD*2), 10);
					g.endFill();
					break;
				
				default:
					CONFIG::debugging {
						Console.error('unknown interaction_type:'+interaction_type);
					}
					return;
			}
			/*
			g = graphics;
			g.clear()
			g.beginFill(0xffffff);
			g.drawCircle(0,0,100);
			g.endFill();*/
		}
		
		public function worldDisposableSpriteSubscribedHandler(sp:DisposableSprite):void {
		}
		
		public function worldDisposableSpriteDestroyedHandler(sp:DisposableSprite):void {
			// the disp sp your were registered with has been destroyed
			goAway();
		}
		
		public function worldDisposableSpriteChangeHandler(sp:DisposableSprite):void {
			if ((interaction_type == InteractionMenuModel.TYPE_LOC_IST_VERB_MENU || interaction_type == InteractionMenuModel.TYPE_GARDEN_VERB_MENU) && lis_view) {
				//good
			} else if (interaction_type == InteractionMenuModel.TYPE_LOC_PC_VERB_MENU && pc_view) {
				//good
			} else {
				return;
			}
			
			if (sp is LocationItemstackView) {
				place_pt = mainView.gameRenderer.translateLocationCoordsToGlobal(LocationItemstackView(sp).x_of_int_target, sp.y);
			} else {
				place_pt = mainView.gameRenderer.translateLocationCoordsToGlobal(sp.x, sp.y);
			}
			
			x = place_pt.x; //sp.x-model.layoutModel.scroll_rect.x+model.layoutModel.gutter_w;
			y = place_pt.y; //sp.y-model.layoutModel.scroll_rect.y;
			keepInBounds();
		}
		
		private function keepInBounds():void {
			var rect:Rectangle = this.getRect(StageBeacon.stage);
			
			rect.y-= 5; // keep it 5 or more pixels from top of stage
			if (rect.y < 0) y-= rect.y;
			
			rect.x-= 5;
			if (rect.x < 0) x-= rect.x;
		}
		
		private var place_pt:Point = new Point();
		private function place(place_under_cursor:Boolean = false):void {
			place_pt = StageBeacon.stage_mouse_pt.clone();
			
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(interaction_tsid);
			
			switch (interaction_type) {
				case InteractionMenuModel.TYPE_LOC_IST_VERB_MENU:
				case InteractionMenuModel.TYPE_GARDEN_VERB_MENU:
					//setTimeout(function():void{
					//	itemstack.itemstack_state.not_selectable = true;
					//}, 2000);
					if (!place_under_cursor && lis_view) {
						place_pt = mainView.gameRenderer.translateLocationCoordsToGlobal(lis_view.x_of_int_target, lis_view.y);
						
						TSFrontController.instance.registerDisposableSpriteChangeSubscriber(this, lis_view);
					}
					break;
				case InteractionMenuModel.TYPE_LIST_PC_VERB_MENU:
				case InteractionMenuModel.TYPE_LIST_GROUP_VERB_MENU:
				case InteractionMenuModel.TYPE_HUBMAP_STREET_MENU:
					break;
				
				case InteractionMenuModel.TYPE_LOC_PC_VERB_MENU:
					if (!place_under_cursor && pc_view) {
						place_pt = mainView.gameRenderer.translateLocationCoordsToGlobal(pc_view.x, pc_view.y);
						
						// this is dumb, as it allows for the pc to move the menu with it
						//	TSFrontController.instance.registerDisposableSpriteChangeSubscriber(this, pc_view);
					}
					break;
				
				case InteractionMenuModel.TYPE_PACK_IST_VERB_MENU:
					if (!place_under_cursor) {
						place_pt = TSFrontController.instance.translatePackSlotToGlobal(itemstack.slot, itemstack.path_tsid);
					}
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_COUNT:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM_COUNT:
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK_COUNT:
					if (place_under_cursor) {
						var default_cui:FormElement = (choiceUIV.length) ? getCUIAtIndex(getDefaultChoiceIndex()) : null;
						
						var offset_x:int = Math.round(calcWidth()/2);
						var offset_y:int = 0;
						
						if (default_cui) {
							var rect:Rectangle = default_cui.getRect(this);
							offset_x = -(rect.x+Math.round(rect.width/2)); // in the middle of the button horizontally
							offset_y = -(rect.y+(rect.height-3)); // 3 pixels up from bottom of button
						}
						
						place_pt.x+= offset_x;
						place_pt.y+= offset_y;
						//Console.warn('A '+place_pt);
						
					} else if (lis_view) { // we might be working with a PACK_ITEMSTACK, so we have to test this exsists
						place_pt = mainView.gameRenderer.translateLocationCoordsToGlobal(lis_view.x_of_int_target, lis_view.y);
					} else if (pc_view) { // this shoudl be true only when TYPE_PC_VERB_TARGET_ITEMSTACK_COUNT
						place_pt = mainView.gameRenderer.translateLocationCoordsToGlobal(pc_view.x, pc_view.y);
					} else if (itemstack) {
						place_pt = TSFrontController.instance.translatePackSlotToGlobal(itemstack.slot, itemstack.path_tsid);
					} else {
						// leave it where it was
						place_pt.x = x;
						place_pt.y = y;
					}
					
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_PC:
				case InteractionMenuModel.TYPE_LOC_DISAMBIGUATOR:
				case InteractionMenuModel.TYPE_GARDEN_PLANT_SEED:
					// place it in center of viewport
					place_pt.x = model.layoutModel.gutter_w+Math.round(model.layoutModel.loc_vp_w/2);
					place_pt.y = model.layoutModel.header_h+Math.round(model.layoutModel.loc_vp_h/2)+Math.round(height/2);
					break;
				
				default:
					CONFIG::debugging {
						Console.error('unknown interaction_type:'+interaction_type);
					}
					makeNoChoice();
					return;
			}
			x = place_pt.x;
			y = place_pt.y;
			
			//keep it on screen if it went off
			const right_buffer:uint = 15; //how many px the pointy must have on the right side
			const max_x:int = StageBeacon.stage.stageWidth - model.layoutModel.min_gutter_w;
			
			//pointy thing
			var pt:Point = verb_holder_sp.localToGlobal(new Point(verb_holder_sp.width, 0));
			if(pt.x > max_x){
				x -= (pt.x - max_x);
				verb_pointer_sp.x = StageBeacon.stage_mouse_pt.x - x + POINTER_W/2 - 1;
				if(verb_pointer_sp.x + POINTER_W > calcWidth() - right_buffer){
					verb_pointer_sp.x = calcWidth() - right_buffer - POINTER_W;
				}
			}
			else {
				verb_pointer_sp.x = POINTER_OFFSET_X;
			}
			
			//number chooser
			pt = count_holder_sp.localToGlobal(new Point(count_holder_sp.width, 0));
			if(pt.x > max_x){
				x -= pt.x - max_x - model.layoutModel.min_gutter_w;
			}
			
			//dis-embig
			pt = target_item_holder_sp.localToGlobal(new Point(target_item_holder_sp.width, 0));
			if(pt.x > max_x){
				x -= pt.x - max_x - model.layoutModel.min_gutter_w;
			}
		}
		
		private function getDefaultChoiceIndex():int {
			switch (interaction_type) {
				case InteractionMenuModel.TYPE_LOC_IST_VERB_MENU:
				case InteractionMenuModel.TYPE_PACK_IST_VERB_MENU:
				case InteractionMenuModel.TYPE_LOC_PC_VERB_MENU:
				case InteractionMenuModel.TYPE_LIST_PC_VERB_MENU:
				case InteractionMenuModel.TYPE_LIST_GROUP_VERB_MENU:
				case InteractionMenuModel.TYPE_HUBMAP_STREET_MENU:
				case InteractionMenuModel.TYPE_GARDEN_VERB_MENU:
					return imm.choices.length-1;
				case InteractionMenuModel.TYPE_IST_VERB_COUNT:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM_COUNT:
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK_COUNT:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_PC:
				case InteractionMenuModel.TYPE_LOC_DISAMBIGUATOR:
				case InteractionMenuModel.TYPE_GARDEN_PLANT_SEED:
					return imm.choices.length ? 0 : -1;
				default:
					CONFIG::debugging {
						Console.error('unknown interaction_type:'+interaction_type);
					}
					return -1;
			}
		}
		
		private function getIndexOfCUI(cui:FormElement):int {
			return choiceUIV.indexOf(cui);
		}
		
		private function getCUIAtIndex(i:int):FormElement {
			if (i<0 || i>choiceUIV.length-1) {
				CONFIG::debugging {
					Console.error('i out of range:'+i+' '+(choiceUIV.length-1));
				}
				return null;
			}
			return choiceUIV[int(i)];
		}
		
		private function getCUICount():uint {
			return choiceUIV.length;
		}
		
		private function makeChoice(by_click:Boolean = false):void {
			
			if (!imm.choices) {
				throw new Error('imm.choices is null; interaction_type:'+interaction_type);
				return;
			}
			
			if (!imm.choices.length) {
				throw new Error('imm.choices has no length; interaction_type:'+interaction_type);
				return;
			}
			
			var choice_value:* = imm.choices[curr_choice_i];
			
			if (choice_value == undefined) {
				throw new Error('choice_value is undefined; interaction_type:'+interaction_type+' curr_choice_i:'+curr_choice_i);
				return;
			}
			
			switch (interaction_type) {
				case InteractionMenuModel.TYPE_LOC_IST_VERB_MENU:
				case InteractionMenuModel.TYPE_PACK_IST_VERB_MENU:
					if (choice_value is Verb) {
						if (!Verb(choice_value).enabled) {
							SoundMaster.instance.playSound('CLICK_FAILURE');
							return;
						}
					}
					
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					controller.handleItemstackVerbMenuChoice(curr_choice_i, by_click);
					break;
				
				case InteractionMenuModel.TYPE_LOC_PC_VERB_MENU:
				case InteractionMenuModel.TYPE_LIST_PC_VERB_MENU:
					if (!(choice_value is String)) {
						if (choice_value.disabled) {
							SoundMaster.instance.playSound('CLICK_FAILURE');
							return;
						}
					}
					
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					controller.handlePCVerbChoice(curr_choice_i, by_click);
					break;
				
				case InteractionMenuModel.TYPE_HUBMAP_STREET_MENU:
					if (!(choice_value is String)) {
						if (choice_value.disabled) {
							SoundMaster.instance.playSound('CLICK_FAILURE');
							return;
						}
					}
					
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					controller.handleLocationMenuChoice(curr_choice_i, by_click);
					break;
				
				case InteractionMenuModel.TYPE_GARDEN_VERB_MENU:
					if (choice_value is Verb) {
						if (!Verb(choice_value).enabled) {
							SoundMaster.instance.playSound('CLICK_FAILURE');
							return;
						}
					}
					
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					controller.handleGardenMenuChoice(curr_choice_i, by_click);
					break;
				
				case InteractionMenuModel.TYPE_GARDEN_PLANT_SEED:
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					controller.handleGardenPlantSeedChoice(curr_choice_i, by_click);
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_COUNT:
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					controller.handleItemstackVerbCountChoice(curr_choice_i, by_click);
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM_COUNT:
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					controller.handleItemstackVerbTargetItemCountChoice(curr_choice_i, by_click);
					break;
				
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK_COUNT:
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					controller.handlePCVerbTargetItemstackCountChoice(curr_choice_i, by_click);
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM:
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					controller.handleItemstackVerbTargetItemChoice(curr_choice_i, by_click);
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEMSTACK:
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					controller.handleItemstackVerbTargetItemStackChoice(curr_choice_i, by_click);
					break;
				
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK:
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					controller.handlePCVerbTargetItemstackChoice(curr_choice_i, by_click);
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_PC:
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					controller.handleItemstackVerbTargetPCChoice(curr_choice_i, by_click);
					break;
				
				case InteractionMenuModel.TYPE_LOC_DISAMBIGUATOR:
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					controller.handleDisambiguatorChoice(curr_choice_i, by_click);
					break;
				
				case InteractionMenuModel.TYPE_LIST_GROUP_VERB_MENU:
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					controller.handleGroupVerbChoice(curr_choice_i, by_click);
					break;
				
				default:
					CONFIG::debugging {
						Console.error('unknown interaction_type:'+interaction_type);
					}
					return;
			}
		}
		
		private function makeNoChoice():void {
			switch (interaction_type) {
				case InteractionMenuModel.TYPE_LOC_IST_VERB_MENU:
				case InteractionMenuModel.TYPE_PACK_IST_VERB_MENU:
					controller.handleItemstackVerbMenuChoice();
					break;
				
				case InteractionMenuModel.TYPE_LOC_PC_VERB_MENU:
				case InteractionMenuModel.TYPE_LIST_PC_VERB_MENU:
					controller.handlePCVerbChoice();
					break;
				
				case InteractionMenuModel.TYPE_HUBMAP_STREET_MENU:
					controller.handleLocationMenuChoice();
					break;
				
				case InteractionMenuModel.TYPE_GARDEN_VERB_MENU:
					controller.handleGardenMenuChoice();
					break;
				
				case InteractionMenuModel.TYPE_GARDEN_PLANT_SEED:
					controller.handleGardenPlantSeedChoice();
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_COUNT:
					controller.handleItemstackVerbCountChoice();
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM_COUNT:
					controller.handleItemstackVerbTargetItemCountChoice();
					break;
				
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK_COUNT:
					controller.handlePCVerbTargetItemstackCountChoice();
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM:
					controller.handleItemstackVerbTargetItemChoice();
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEMSTACK:
					controller.handleItemstackVerbTargetItemStackChoice();
					break;
				
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK:
					controller.handlePCVerbTargetItemstackChoice();
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_PC:
					controller.handleItemstackVerbTargetPCChoice();
					break;
				
				case InteractionMenuModel.TYPE_LOC_DISAMBIGUATOR:
					controller.handleDisambiguatorChoice();
					break;
				
				case InteractionMenuModel.TYPE_LIST_GROUP_VERB_MENU:
					controller.handleGroupVerbChoice();
					break;
				
				default:
					CONFIG::debugging {
						Console.error('unknown interaction_type:'+interaction_type);
					}
					return;
			}
		}
		
		private var closed:Boolean = true;
		public function close():void {
			CONFIG::debugging {
				Console.log(35, 'close');
			}
			closed = true;
			if (pc_view) TSFrontController.instance.unregisterDisposableSpriteChangeSubscriber(this, pc_view);
			if (lis_view) TSFrontController.instance.unregisterDisposableSpriteChangeSubscriber(this, lis_view);
			
			TSFrontController.instance.releaseFocus(this);
			
			var self:InteractionMenu = this;
			TSTweener.removeTweens(self);
			TSTweener.addTween(self, {alpha:0, time:.1, delay:0, transition:'linear', onComplete:function():void {
				if (self.parent) self.parent.removeChild(self);
				self.clean();
				self.visible = false;
			}});

			removeEventListener(MouseEvent.CLICK, clickHandler);
			removeEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
			removeEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
		}
		
		private function areCUIsInAGrid():Boolean {
			switch (interaction_type) {
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_PC:
				case InteractionMenuModel.TYPE_LOC_DISAMBIGUATOR:
				case InteractionMenuModel.TYPE_GARDEN_PLANT_SEED:
					return true;
			}
			
			return false;
		}
		
		private function areCUIsVertical():Boolean {
			switch (interaction_type) {
				case InteractionMenuModel.TYPE_IST_VERB_COUNT:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM_COUNT:
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK_COUNT:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_PC:
				case InteractionMenuModel.TYPE_LOC_DISAMBIGUATOR:
				case InteractionMenuModel.TYPE_GARDEN_PLANT_SEED:
					return false;
			}
			
			return true;
		}
		
		//------------------------------------------------------------
		// IFocusableComponent methods
		
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return true;
		}
		
		public function hasFocus():Boolean {
			return has_focus;
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur');
			}
			has_focus = false;
			stopListeningToInput();
			TSFrontController.instance.changeTipsVisibility(true, 'INTERACTION_MENU');
		}
		
		public function registerSelfAsFocusableComponent():void {
			model.stateModel.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			model.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focus():void {
			CONFIG::debugging {
				Console.log(99, 'focus');
			}
			has_focus = true;
			startListeningToInput();
			
			TSFrontController.instance.changeTipsVisibility(false, 'INTERACTION_MENU');
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			//if we had an interaction menu up and the focus changes, we need to make the menu go away
			if(was_focused_comp == this) close();
		}
		
		// END IFocusableComponent methods
		//------------------------------------------------------------
		
		//------------------------------------------------------------
		// INPUT HANDLER METHODS
		
		private function startListeningToInput():void {
			startListeningToNavKeys();
		}
		
		private function stopListeningToInput():void {
			stopListeningToNavKeys();
		}
		
		private function startListeningToNavKeys():void {
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.UP, upArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.W, upArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.DOWN, downArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.S, downArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.UP, upArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.W, upArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DOWN, downArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.S, downArrowKeyHandler);
			
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.RIGHT, rightArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.D, rightArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.LEFT, leftArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.A, leftArrowKeyHandler);
			
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, rightArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.D, rightArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, leftArrowKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.A, leftArrowKeyHandler);
			
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, escKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, enterKeyHandler);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_, allKeyHandler);
		}
		
		private function stopListeningToNavKeys():void {
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.UP, upArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.W, upArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.DOWN, downArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.S, downArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.UP, upArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.W, upArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DOWN, downArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.S, downArrowKeyHandler);
			
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.RIGHT, rightArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.D, rightArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.LEFT, leftArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_REPEAT_+Keyboard.A, leftArrowKeyHandler);
			
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, rightArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.D, rightArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, leftArrowKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.A, leftArrowKeyHandler);
			
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, escKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, enterKeyHandler);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_, allKeyHandler);
		}
		
		private function allKeyHandler(e:KeyboardEvent):void {
			var i:int = getCUIIndexForKeyCode(e.keyCode);
			//Console.warn(e.keyCode+'-->'+i+' '+CUIsV.length);
			if (i > -1 && i < choiceUIV.length) {
				focusChoice(i);
				makeChoice();
				return;
			}
			
			// is it a number and is there a qp that is not the current foccussed cui?
			if (KeyBeacon.instance.isNumberKeyCode(e.keyCode)) {
				var cui:FormElement = getCUIAtIndex(curr_choice_i);
				if (cui && cui != current_qp) {
					i = getIndexOfCUI(current_qp);
					if (i > -1) {
						focusChoice(i, false); // this gets all button in correct state and is needed, even though we focusAndCursorAtEnd later
						current_qp.value = parseInt(KeyBeacon.code_to_rep_map[e.keyCode]);
						current_qp.focusAndCursorAtEnd();
					}
				}
			}
		}
		
		private function escKeyHandler(e:KeyboardEvent):void {
			makeNoChoice();
		}
		
		private function upArrowKeyHandler(e:KeyboardEvent):void {
			if (areCUIsInAGrid() && cui_grid_rows > 1) {
				// move up in the grid!
				focusUpChoice();
			} else if (areCUIsVertical()) {
				focusPrevChoice();
			} else {
				var cui:FormElement = getCUIAtIndex(curr_choice_i);
				if (cui is QuantityPickerSpecial) {
					QuantityPickerSpecial(cui).incrementValue();
				}
			}
			
		}
		
		private function downArrowKeyHandler(e:KeyboardEvent):void {
			if (areCUIsInAGrid() && cui_grid_rows > 1) {
				focusDownChoice();
			} else if (areCUIsVertical()) {
				focusNextChoice();
			} else {
				var cui:FormElement = getCUIAtIndex(curr_choice_i);
				if (cui is QuantityPickerSpecial) {
					QuantityPickerSpecial(cui).decrementValue();
				}
			}
		}
		
		private function rightArrowKeyHandler(e:KeyboardEvent):void {
			if (areCUIsVertical()) {
				makeNoChoice();
			} else {
				focusNextChoice();
			}
		}
		
		private function leftArrowKeyHandler(e:KeyboardEvent):void {
			if (areCUIsVertical()) {
				makeNoChoice();
			} else {
				focusPrevChoice();
			}
		}
		
		private function enterKeyHandler(e:KeyboardEvent):void {
			if (!choiceUIV.length) return;
			makeChoice();
		}
		
		private function mouseOverHandler(e:Event):void {
			var i:int = -1;
			if (e.target is DisplayObject && DisplayObject(e.target).parent is QuantityPickerSpecial) {
				i = getIndexOfCUI(DisplayObject(e.target).parent as FormElement);
			} else if (e.target is FormElement) {
				i = getIndexOfCUI(e.target as FormElement);
			}
			
			if (i != -1) {
				focusChoice(i);
			} else {
				//Console.warn(/*StringUtil.DOPath(e.target as DisplayObject)*/DisplayDebug.LogCoords(DisplayObject(e.target).parent, 2));
			}
		}
		
		private function clickHandler(e:Event):void {
			// accounn for a click on the quanty picker and dont change focus
			if (!(e.target is TextField) || TextField(e.target).type != TextFieldType.INPUT) {
				StageBeacon.stage.focus = StageBeacon.stage;
			}
			
			if (e.target is Button && DisplayObject(e.target).parent is QuantityPickerSpecial && Button(e.target).name == '_go_bt') {
				focusChoice(getIndexOfCUI(current_qp));
				makeChoice(true);
			} else if (e.target is Button && !(DisplayObject(e.target).parent is QuantityPickerSpecial)) {
				focusChoice(getIndexOfCUI(e.target as FormElement));
				makeChoice(true);
			} else if (e.target == verb_pointer_sp) {
				if (choiceUIV.length) { // make sure we have buttons first (it may be waiting on a response from the GS and in "placehold" state)
					focusChoice(getDefaultChoiceIndex());
					makeChoice(true);
				}
			}
		}
		
		private function mouseOutHandler(e:Event):void {
			if (e.target is FormElement) {
				if (false) { // need to decide on how we want to let this class now if it should fall back to the default on mouseout
					focusDefaultChoice();
				} else {
					focusChoice(curr_choice_i);
				}
			}
		}
		
		private function getCUIIndexForKeyCode(key_code:uint):int {
			if (key_hash.hasOwnProperty('key_'+key_code)) return key_hash['key_'+key_code];
			return -1;
		}
		
		private function setCUIIndexForKeyCode(i:int, key_code:uint):void {
			key_hash['key_'+key_code] = i;
		}
		
		// END INPUT HANDLER METHODS
		//------------------------------------------------------------
		
		//------------------------------------------------------------
		// CHOICE BUTTON FOCUS METHODS
		
		private function focusDefaultChoice():void {
			focusChoice(getDefaultChoiceIndex());
		}
		
		private function focusChoice(i:int, and_select_all:Boolean=true):void {
			if (curr_choice_i != i) {
				if (curr_choice_i != -1) getCUIAtIndex(curr_choice_i).blur();
				curr_choice_i = i;
			}
			
			if (getCUIAtIndex(i)) {
				var cui:FormElement = getCUIAtIndex(i)
				if (and_select_all && cui is QuantityPickerSpecial) {
					QuantityPickerSpecial(cui).focusAndSelectAll();
				} else {
					cui.focus();
				}
				updateAfterCUIFocus();
			}
		}
		
		private function updateAfterCUIFocus():void {
			use namespace client;
			var desc:String = '';
			var css_class:String = '';
			var c:Object = imm.choices[curr_choice_i];
			var pc:PC;
			var itemstack:Itemstack;
			var verb:Verb;
			
			switch (interaction_type) {
				case InteractionMenuModel.TYPE_LOC_IST_VERB_MENU:
				case InteractionMenuModel.TYPE_PACK_IST_VERB_MENU:
				case InteractionMenuModel.TYPE_LOC_PC_VERB_MENU:
				case InteractionMenuModel.TYPE_LIST_PC_VERB_MENU:
				case InteractionMenuModel.TYPE_LIST_GROUP_VERB_MENU:
				case InteractionMenuModel.TYPE_HUBMAP_STREET_MENU:
				case InteractionMenuModel.TYPE_GARDEN_VERB_MENU:
					if (curr_choice_i != getDefaultChoiceIndex() && verb_pointer_sp.visible && !TSTweener.isTweening(verb_pointer_sp)) {
						verb_pointer_highlight_inert_sh.visible = false;
						verb_pointer_highlight_normal_sh.visible = false;
						TSTweener.addTween(verb_pointer_sp, {scaleY:0, time:animation_speed, transition:animation_type, 
							onComplete:function():void {
								verb_pointer_sp.visible = false;
								verb_pointer_sp.scaleY = 1;
							}
						});
					}
					
					desc = 'no verb tooltip yet';
					css_class = 'context_verb_desc';
					
					const special_types:Array = [
						InteractionMenuModel.TYPE_LOC_PC_VERB_MENU, 
						InteractionMenuModel.TYPE_LIST_PC_VERB_MENU, 
						InteractionMenuModel.TYPE_LIST_GROUP_VERB_MENU, 
						InteractionMenuModel.TYPE_HUBMAP_STREET_MENU
					];
					
					if (special_types.indexOf(interaction_type) != -1) {
						desc = c.tooltip || c.label;
						
						if (c.disabled) {
							desc = c.disabled_reason;
							css_class = 'context_verb_desc_disabled';
						}
						
					} else {
						
						if (c is Verb) {
							verb = c as Verb;
							if (verb.tooltip) desc = verb.tooltip;
							if (!verb.enabled) {
								css_class = 'context_verb_desc_disabled';
							}
						}
					}
					
					desc_tf.htmlText = '<span class="'+css_class+'">'+StringUtil.capitalizeFirstLetter(desc)+'</span>';
					
					// don't jigger for SPECIAL_INFO, as it is placed at the top and it could cause weird jumpiness.
					// Not jiggering means WE MUST KEEP THE INFO DESC TO ONE LINE
					if (
						(!(c is Verb) && c.value != InteractionMenuModel.VERB_SPECIAL_PC_INFO && c.value != InteractionMenuModel.VERB_SPECIAL_LOCATION_INFO)
						|| 
						((c is Verb) && Verb(c).tsid != Item.CLIENT_INFO)
					) jigger();
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_COUNT:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM_COUNT:
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK_COUNT:
					var value:int;
					if (typeof c == 'object' && c) {
						value = c.value;
					} else {
						value = int(c);
					}
					
					if (interaction_type == InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK_COUNT) {
						if (value == 0) {
							css_class = 'context_verb_desc_disabled';
							desc = 'Don\'t give any...';
						} else {
							css_class = 'context_verb_desc';
							desc = 'Give '+value;
						}
						
						desc_tf.htmlText = '<span class="'+css_class+'">'+desc+'</span>';
					} else {
						if (value == 0) {
							css_class = 'context_verb_desc_disabled';
							desc = 'Don\'t '+imm.chosen_verb.label+' any...';
						} else {
							css_class = 'context_verb_desc';
							/*imm.chosen_verb.effects = {
							"what":-30,
							"you":10
							};*/
							var effects_str:String = '';
							if (imm.chosen_verb && imm.chosen_verb.effects) {
								verb = imm.chosen_verb;
								var val:Number;
								var val_str:String;
								var eff_str:String;
								for (var k:String in verb.effects) {
									val = verb.effects[k];
									eff_str = k;
									if (eff_str.indexOf('_cost') > 0) {
										eff_str = eff_str.split('_')[0];
										val = -Math.abs(val);
									}
									if (val == 0) continue;
									val_str = (val > 1) ? '+'+(val*value) : String(val*value);
									if (effects_str) effects_str+= ', ';
									effects_str+= val_str+' '+eff_str;
								}
							}
							
							if (effects_str) {
								desc = StringUtil.capitalizeFirstLetter(effects_str);
							} else {
								desc = StringUtil.capitalizeFirstLetter(imm.chosen_verb.label)+' '+value;
							}
						}
						desc_tf.htmlText = '<p align="center"><span class="'+css_class+'">'+desc+'</span></p>';
					}
					
					jigger();
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEM:
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_PC_VERB_TARGET_ITEMSTACK:
				case InteractionMenuModel.TYPE_GARDEN_PLANT_SEED:
					var item:Item;
					if (c is String) {
						if (c == 'x') {
							css_class = 'context_verb_desc_disabled';
							desc = 'Cancel...';
						} else {
							desc = 'no tip...';
						}
					} else if (c is Item) {
						css_class = 'context_verb_desc';
						item = c as Item;
						verb = imm.chosen_verb;
						var loc_count:int = model.worldModel.location.hasHowManyItems(item.tsid);
						var inv_count:int = model.worldModel.pc.hasHowManyItems(item.tsid);
						desc = item.label+' (';
						if (verb && verb.include_target_items_from_location) {
							if (!inv_count && loc_count) {
								desc+= 'there are '+loc_count+' in location';
							} else {
								desc+= 'you have '+inv_count;
								if (loc_count) desc+= ', and there are '+loc_count+' in location';
							}
						} else {
							desc+= 'you have '+inv_count;
						}
						desc+= ')';
					} else if (c is Itemstack) {
						css_class = 'context_verb_desc';
						itemstack = c as Itemstack;
						desc = itemstack.label+' ('+itemstack.count+')';
					} else {
						; // satisfy compiler
						CONFIG::debugging {
							Console.error('wtf');
						}
					}
					desc_tf.htmlText = '<span class="'+css_class+'">'+desc+'</span>';
					jigger();
					break;
				
				case InteractionMenuModel.TYPE_IST_VERB_TARGET_PC:
					if (c is String) {
						if (c == 'x') {
							css_class = 'context_verb_desc_disabled';
							desc = 'Cancel...';
						} else {
							desc = 'no tip...';
						}
					} else if (c is PC) {
						css_class = 'context_verb_desc';
						pc = c as PC;
						desc = pc.label;
					} else {
						; // satisfy compiler
						CONFIG::debugging {
							Console.error('wtf');
						}
					}
					desc_tf.htmlText = '<span class="'+css_class+'">'+desc+'</span>';
					jigger();
					break;
				
				case InteractionMenuModel.TYPE_LOC_DISAMBIGUATOR:
					
					css_class = 'context_verb_desc';
					desc = (c is String) ? '' : c.name; // this is optimistic; might need to set desc in the ifs below
					
					if (c is String) {
						if (c == 'x') {
							css_class = 'context_verb_desc_disabled';
							desc = 'Cancel...';
						} else {
							desc = 'no tip...';
						}
					} else if (c is LocationItemstackView) {
						itemstack = model.worldModel.getItemstackByTsid(c.tsid);
						desc = itemstack.label+' ('+itemstack.count+')';
					} else if (c is PCView) {
						pc = model.worldModel.getPCByTsid(c.tsid);
						desc = pc.label;
					/*} else if (c is LadderView) { // this shoudl now never happen, because we do not allow Ladders in these menus
						desc = 'Ladder';*/
					} else if (c is DoorView) {
						desc = 'Door';
						var door:Door = model.worldModel.location.mg.getDoorById(c.tsid);
						if (door && door.connect) {
							desc+= ' to '+door.connect.label
						}
					} else if (c is SignpostView) {
						desc = 'Signpost';
						var signpost:SignPost = model.worldModel.location.mg.getSignpostById(c.tsid);
						if (signpost && signpost.quarter_info) {
							desc+= ' to '+signpost.quarter_info.label+' quarter locations';
						} else if (signpost && signpost.connects && signpost.connects.length) {
							desc+= ' to';
							for (var m:int;m<signpost.connects.length;m++) {
								if (m>0) desc+=' ,';
								desc+= ' '+signpost.connects[m].label;
							}
						}
					}
					
					desc_tf.htmlText = '<span class="'+css_class+'">'+desc+'</span>';
					jigger();
					
					break;
				
				default:
					CONFIG::debugging {
						Console.error('unknown interaction_type:'+interaction_type);
					}
					return;
			}
			keepInBounds();
		}
		
		private function focusNextChoice():void {
			if (!choiceUIV.length) return;
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			if (curr_choice_i+1 >= getCUICount()) {
				focusChoice(0);
			} else {
				focusChoice(curr_choice_i+1);
			}
		}
		
		private function focusPrevChoice():void {
			if (!choiceUIV.length) return;
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			if (curr_choice_i-1 < 0) {
				focusChoice(getCUICount()-1);
			} else {
				focusChoice(curr_choice_i-1);
			}
		}
		
		private function focusLeftChoice():void {
			if (!choiceUIV.length) return;
			var goto_i:int;
			
			if (curr_coll_i == 0) {
				goto_i = Math.min(choiceUIV.length-1, curr_choice_i + cui_grid_cols-1);
				if (goto_i == curr_choice_i) return; // can happen if there is only one in the last row
			} else {
				goto_i = curr_choice_i-1;
			}
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			focusChoice(goto_i);
		}
		
		private function focusRightChoice():void {
			if (!choiceUIV.length) return;
			var goto_i:int;
			
			if (curr_coll_i == cui_grid_cols-1) {
				goto_i = Math.max(0, curr_choice_i - (cui_grid_cols-1));
			} else {
				goto_i = curr_choice_i+1;
				if (goto_i > choiceUIV.length-1) {
					goto_i = (cui_grid_cols*(cui_grid_rows-1)); // the first one in your current row
					if (goto_i == curr_choice_i) return; // can happen if there is only one in the last row
				}
			}
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			focusChoice(goto_i);
		}
		
		private function focusUpChoice():void {
			if (!choiceUIV.length) return;
			var goto_i:int;
			
			if (curr_row_i == 0) {
				goto_i = ((cui_grid_rows-1)*cui_grid_cols)+curr_coll_i;
				if (goto_i > choiceUIV.length-1) {
					goto_i-=  cui_grid_cols;
					if (goto_i == curr_choice_i) return; // can happen if there is only one in the last row
				}
			} else {
				goto_i = curr_choice_i - cui_grid_cols;
			}
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			focusChoice(goto_i);
		}
		
		private function focusDownChoice():void {
			if (!choiceUIV.length) return;
			var goto_i:int;
			
			if (curr_row_i == cui_grid_rows-1) {
				goto_i = curr_coll_i;
			} else {
				goto_i = curr_choice_i + cui_grid_cols;
				if (goto_i > choiceUIV.length-1) {
					goto_i = curr_coll_i;
					if (goto_i == curr_choice_i) return; // can happen if there is only one in the last row
				}
			}
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			focusChoice(goto_i);
		}
		
		// END CHOICE BUTTON FOCUS METHODS
		//------------------------------------------------------------
		
	}
}