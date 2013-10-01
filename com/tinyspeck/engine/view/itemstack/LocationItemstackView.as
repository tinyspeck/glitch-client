package com.tinyspeck.engine.view.itemstack {
	
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.itemstack.ItemstackState;
	import com.tinyspeck.engine.data.itemstack.ItemstackStatus;
	import com.tinyspeck.engine.event.IMouseEventSignalRelay;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.net.NetOutgoingItemstackMouseOverVO;
	import com.tinyspeck.engine.net.NetOutgoingItemstackVerbCancelVO;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.port.ActionIndicatorView;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.ConversationManager;
	import com.tinyspeck.engine.port.GardenManager;
	import com.tinyspeck.engine.port.ShrineManager;
	import com.tinyspeck.engine.spritesheet.ItemSSManager;
	import com.tinyspeck.engine.spritesheet.SSAbstractSheet;
	import com.tinyspeck.engine.spritesheet.SSViewSprite;
	import com.tinyspeck.engine.spritesheet.SWFData;
	import com.tinyspeck.engine.util.ContainersUtil;
	import com.tinyspeck.engine.util.DragVO;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.IDragTarget;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.IWorthRenderable;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.gameoverlay.ArbitrarySWFView;
	import com.tinyspeck.engine.view.gameoverlay.ChoicesDialog;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.geo.DoorView;
	import com.tinyspeck.engine.view.renderer.DecoAssetManager;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.garden.GardenView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import org.osflash.signals.ISignal;
	import org.osflash.signals.Signal;
	import org.osflash.signals.natives.NativeSignal;
	
	public class LocationItemstackView extends AbstractItemstackView implements IMouseEventSignalRelay, IDragTarget, ITipProvider, IWorthRenderable {
		public var trophy_case_holder:Sprite;
		public var rooked_overlay_iiv:ItemIconView;
		
		private var lot_deco_holder:Sprite;
		private var mainView:TSMainView;
		private var itemstack_talk_bubble_offest:int;
		private var action_indicator_offset:int;
		
		private var emo_bear_kiss_iiv:DisplayObject;
		private var emo_bear_hug_iiv:DisplayObject;
		private var hit_box:Sprite;
		
		private var use_stage_for_hitbox:Boolean;
		private var _has_mouse:Boolean;
		private var y_above:int;
		private var bob_amt:int;
		private var bob_secs:Number = .47;
		private var _convo_to_run_after_load:Object;
		private var ct_box:Shape;
		private var interaction_target_x_correction:int;
		private var _garden_view:GardenView;
		private var polarity_switched:Boolean;
		
		private var lisRookManager:LisRookManager;
		private var _lisChatBubbleManager:LisChatBubbleManager;
		private var _mouseClicked:NativeSignal;
		
		private var aivManager:AIVManager;
		public var log_this:Boolean;
		
		private var _configuring:Boolean = false; 
		
		private const _loadCompleted_sig:Signal = new Signal(LocationItemstackView);

		public function LocationItemstackView(tsid:String):void {
			super(tsid);
			
			_lisChatBubbleManager = new LisChatBubbleManager(this);
			_lisChatBubbleManager.bubble_updated_sig.add(showHide);
			aivManager = new AIVManager(this, _itemstack);
			_lisChatBubbleManager.AIVs_changed_sig.add(aivManager.showHideAIVs);
			
			lisRookManager = new LisRookManager(this);
			
			_worth_rendering = !model.flashVarModel.limited_rendering;
			this.mainView = TSFrontController.instance.getMainView();
			_animateXY_duration = model.flashVarModel.item_animate_duration;
			
			cacheAsBitmap = (EnvironmentUtil.getUrlArgValue('SWF_cab') == '1'); // RH : if this thing or its children are animated : rotated or scaled, this is a performance hog.
			/*CONFIG::debugging {
				Console.warn('LocationItemstackView.cacheAsBitmap:'+cacheAsBitmap)
			}*/
			
			_construct();
			// street_spirit is being deprecated in favor of street_spirit_*, but we're in transition at the time of writing
			polarity_switched = (_item.tsid == 'street_spirit' || _item.tsid == 'street_spirit_groddle');
			
			_mouseClicked = new NativeSignal(this, MouseEvent.CLICK, MouseEvent);
		}
		
		public function set configuring(value:Boolean):void { _configuring = value; }
		public function get configuring():Boolean { return _configuring; }

		public function get worth_rendering():Boolean {
			return _worth_rendering;
		}
		
		public function set worth_rendering(value:Boolean):void {
			if (_worth_rendering == value) return; // don't do anything if this is not a change
			
			_worth_rendering = value;
			
			load_log+= 'worth_rendering called worth_rendering:'+_worth_rendering+'\n';
			if (_worth_rendering) {
				// move it into place because we have not been moving it while it was !_worth_rendering
				x = _itemstack.x;
				y = _itemstack.y;
				
				// if it was loaded before, then get it going again, else load the ss
				if (ss) {
					changeHandler(true); // this will call showHide() and animate() and all the shit we need
					if (bob_amt) startBob();
				} else {
					if (!loading_started) {
						loading_started = true;
						ItemSSManager.getSSForItemSWFByUrl(used_swf_url, _item, onLoad);
						loadPlaceHolder(Item.TYPE_PLACEHOLDER_THROBBER);
					} else {
						// this is the case when loading just outright failed, so we have no ss. showHide() will show the placeholder
						showHide();
					}
				}
			} else {
				// hide it!
				showHide();
				if (ss && ss_view) {
					// stop it!
					ss_view.stop();
				}
				if (bob_amt) stopBob();
			}
			
			aivManager.showHideAIVs();
		}
		
		override protected function makeMissingPlaceHolder(bm:Bitmap):Bitmap {
			if (_item.placement_rect && placeholder_showing == Item.TYPE_PLACEHOLDER_MISSING) {
				var pwh:int;
				if (_item.placement_rect.width > _item.placement_rect.height) {
					pwh = _item.placement_rect.width;
				} else {
					pwh = _item.placement_rect.height;
				}
				
				bm.width = bm.height = pwh;
				bm.y = _item.placement_rect.y+_item.placement_rect.height;
			}
			return bm;
		}
		
		private function startBob():void {
			if (!bob_amt) return;
			if (TSTweener.isTweening(view_holder)) return;
			doBob(MathUtil.randomInt(0, 10)*.1);
		}
		
		private function doBob(delay:Number=0):void {
			var new_y:int = (view_holder.y<0) ? bob_amt : -bob_amt;
			var time:Number = bob_secs+(MathUtil.randomInt(-1, 1)*.05);
			TSTweener.addTween(view_holder, {y: new_y, time: time, delay:delay, transition: 'easeInOutSine', onComplete:doBob});
		}
		
		private function stopBob():void {
			if (!bob_amt) return;
			if (TSTweener.isTweening(view_holder)) TSTweener.removeTweens(view_holder, 'y');
		}
		
		override protected function _construct():void {
			if (_item.tsid.indexOf('trophycase') > -1) {
				trophy_case_holder = new Sprite();
				trophy_case_holder.name = 'trophy_case_holder';
				addChild(trophy_case_holder);
				
				trophy_case_holder.addEventListener(MouseEvent.MOUSE_OVER, onTrophyOver, false, 0, true);
				trophy_case_holder.addEventListener(MouseEvent.MOUSE_OUT, onTrophyOut, false, 0, true);
				trophy_case_holder.addEventListener(MouseEvent.CLICK, onTrophyClick, false, 0, true);
			}
			
			// the assumption here is that if use_mc is already set to true, then you
			// cannot set it to false (it is set to true in LocationItemstackMCView, for example)
			// if this assumption needs reassement, do it with care and thoughtfullness!
			if (!use_mc) {
				use_mc = CSSManager.instance.getBooleanValueFromStyle('use_mc', _item.tsid);
				
				if (!use_mc && EnvironmentUtil.getUrlArgValue('SWF_use_mc_for').split(',').indexOf(_item.tsid) != -1) {
					use_mc = true;
				}
			}
			
			bob_amt = CSSManager.instance.getNumberValueFromStyle(_item.tsid, 'bob_amt', 0);
			bob_secs = CSSManager.instance.getNumberValueFromStyle(_item.tsid, 'bob_secs', bob_secs);
			y_above = CSSManager.instance.getNumberValueFromStyle(_item.tsid, 'y_above', 0);
			itemstack_talk_bubble_offest = CSSManager.instance.getNumberValueFromStyle('offsets', 'itemstack_talk_bubble');
			
			use_stage_for_hitbox = CSSManager.instance.getBooleanValueFromStyle('use_stage_for_hitbox', _item.tsid);
			// all rocks use stage for hitbox, so when you get moved away from it when mining, you are never too far away to glow
			use_stage_for_hitbox  = use_stage_for_hitbox || _item.tsid.indexOf('rock_') ==  0;
			
			if (CSSManager.instance.getNumberValueFromStyle(_item.tsid, 'hit_box_width', 0) > 0 || use_stage_for_hitbox) {
				hit_box = new Sprite();
				hit_box.buttonMode = true
				hit_box.name = 'hit_box';
				hit_box.mouseEnabled = true;
				addChild(hit_box);
			}
			
			if (CSSManager.instance.getNumberValueFromStyle(_item.tsid, 'hit_box_width', 0) > 0) {
				var hit_box_width:int = CSSManager.instance.getNumberValueFromStyle(_item.tsid, 'hit_box_width', 0);
				var hit_box_height:int = CSSManager.instance.getNumberValueFromStyle(_item.tsid, 'hit_box_height', 0);
				var hit_box_offset_y:int = CSSManager.instance.getNumberValueFromStyle(_item.tsid, 'hit_box_offset_y', 0);
				hit_box.y = hit_box_offset_y;
				drawHitBox(hit_box_width, hit_box_height);
			}
			
			CONFIG::god {
				if (_item.has_ct_box) {
					ct_box = new Shape();
					drawCTBox();
					ct_box.visible = !model.stateModel.hide_CTBoxes;
					addChildAt(ct_box, 0);
				}
			}
			
			//Console.warn(item.tsid+' use_mc:'+use_mc)
			//if this is a garden, let the manager handle it
			if(_item.tsid != GardenManager.GARDEN_CLASS_TSID){
				animate();
			}
			
			// physics needs some default dimensions
			setPhysicsProps();
			
			super._construct();
			
		}
		
		private function drawHitBox(hw:int, hh:int):void {
			if (!hit_box) return;
			var g:Graphics;
			g = hit_box.graphics;
			g.clear();
			g.beginFill(0, hit_target_alpha);
			g.drawRect(-(hw/2), -hh, hw, hh);
			g.endFill();
		}
		
		/** Used for dragging and avatar hit detection */
		override public function get hit_target():DisplayObject {
			return (hit_box ? hit_box : interaction_target);
		}
		
		public function positionActionIndicators(and_adjust_visibility:Boolean=false):void {
			aivManager.positionActionIndicators(and_adjust_visibility);
		}
		
		public function set aivs_hidden_for_overlay(value:Boolean):void {
			aivManager.aivs_hidden_for_overlay = value;
		}

		public function set aivs_hidden_for_proximity(value:Boolean):void {
			aivManager.aivs_hidden_for_proximity = value;
		}
		
		private var stopped_by_mouse:Boolean;
		private var stopped_by_mouse_tim:uint;
		public function set has_mouse(value:Boolean):void {
			if (value == _has_mouse) return;
			
			_has_mouse = value;
			if (stopped_by_mouse_tim) StageBeacon.clearTimeout(stopped_by_mouse_tim);
			if (_has_mouse && aivManager.has_indicators && !stopped_by_mouse && _item.tsid.indexOf('npc') != -1) {
				stopped_by_mouse = true;
				TSFrontController.instance.genericSend(new NetOutgoingItemstackMouseOverVO(tsid));
			} else if (!_has_mouse && stopped_by_mouse) {
				stopped_by_mouse_tim = StageBeacon.setTimeout(function():void {
					// if mouse is still not over it, and it does not have a menu up, let it move again!
					if (!_has_mouse && model.interactionMenuModel.active_tsid != tsid) {
						stopped_by_mouse = false
						TSFrontController.instance.genericSend(
							new NetOutgoingItemstackVerbCancelVO(tsid)
						);
					}
				}, 1000);
			}
			aivManager.showHideAIVs();
		}
		
		// not named has_mouse because you cannot have a public getter and private setter sigh
		public function get has_mouse_focus():Boolean {
			return _has_mouse;
		}

		public function getActionIndicator(index:int = 0):ActionIndicatorView {
			return aivManager.getActionIndicator(index);
		}
		
		public function addActionIndicator(aiv:ActionIndicatorView):Boolean {
			return aivManager.addActionIndicator(aiv);
		}
		public function removeActionIndicator(aiv:ActionIndicatorView, clear_all:Boolean = false):void {
			aivManager.removeActionIndicator(aiv, clear_all);
		}
		
		override public function get disambugate_sort_on():int {
			if (_item.tsid.indexOf('street_spirit') > -1) {
				return 10;
			} else if (_item.tsid.indexOf('npc') == 0 && _item.tsid.indexOf('vendor') > -1) {
				return 20;
			} else if (_item.is_shrine) {
				return 30;
			} else if (_item.tsid.indexOf('trant') == 0) {
				return 40;
			} else if (_item.tsid.indexOf('patch') == 0) {
				return 50;
			} else if (_item.tsid.indexOf('npc') == 0) {
				return 60;
			}
			
			return 100;
		}
		
		public function placeTrophies():void {
			if (!trophy_case_holder) return;
			if (!model.worldModel.location) return;
			addChild(trophy_case_holder); // keep it on top
			var trophy_itemstack:Itemstack;
			var icon_wh:int = 50;
			var case_tsids_A:Array = ContainersUtil.getTsidAForContainerTsid(_itemstack.tsid, model.worldModel.location.itemstack_tsid_list, model.worldModel.itemstacks);
			
			while (trophy_case_holder.numChildren) trophy_case_holder.removeChildAt(0);
			
			if (!case_tsids_A) return;
			for(var i:int = 0; i<case_tsids_A.length; i++){
				trophy_itemstack = model.worldModel.getItemstackByTsid(case_tsids_A[int(i)]);
				var trophy_iiv:ItemIconView = new ItemIconView(trophy_itemstack.class_tsid, icon_wh, 'iconic', 'center');
				trophy_iiv.y = - Math.round(view_holder.height + icon_wh/2 - 7);
				trophy_iiv.x = Math.round((trophy_itemstack.slot * icon_wh) - view_holder.width/2 + icon_wh - 9);
				trophy_iiv.name = case_tsids_A[int(i)]; //give the item the TSID instead of the class_tsid so we can use the NEW api calls
				trophy_iiv.useHandCursor = trophy_iiv.buttonMode = true;
				trophy_case_holder.addChild(trophy_iiv);
			}
		}
		
		private function onTrophyOver(event:MouseEvent):void {
			if (!(event.target is ItemIconView)) return;
			var iiv:ItemIconView = event.target as ItemIconView;
			if(iiv){
				//TODO: Create a function in ItemIconView that just fires back a resized asset instead of scaling
				iiv.scaleX = iiv.scaleY = 1.1;
				iiv.filters = StaticFilters.tsSprite_GlowA;
			}
		}
		
		private function onTrophyOut(event:MouseEvent):void {
			if (!(event.target is ItemIconView)) return;
			var iiv:ItemIconView = event.target as ItemIconView;
			if(iiv){
				iiv.scaleX = iiv.scaleY = 1;
				iiv.filters = null;
			}
		}
		
		private function onTrophyClick(event:MouseEvent):void {
			if (!(event.target is ItemIconView)) return;
			var iiv:ItemIconView = event.target as ItemIconView;
			if(iiv){
				model.stateModel.get_trophy_info_tsid = iiv.name;
			}
		}
		
		public function highlightOnDragOver():void {
			if (view_holder) {
				super.glow();
				
				if(_itemstack.item.is_shrine){
					ShrineManager.instance.handleProgressOnShrine(this, true, DragVO.vo.dragged_itemstack.count);
				}
			}
		}
		
		public function unhighlightOnDragOut():void {
			if (view_holder) {
				super.unglow();
				
				if(_itemstack.item.is_shrine){
					ShrineManager.instance.handleProgressOnShrine(this, false);
				}
			}
		}
		
		private var ignore_gs_move_updates:Boolean;
		public function enableGSMoveUpdates():void {
			ignore_gs_move_updates = false;
			changeHandler(true);
		}
		public function disableGSMoveUpdates():void {
			if (tweening) {
				stopAnimateXY();
			}
			ignore_gs_move_updates = true;
			changeHandler(true);
		}
		
		public function changeHandler(force:Boolean=false):void {
			
			doMouseState();
			
			if (reloadIfNeeded()) {
				return;
			}
			
			animate(force);
			
			if (!ignore_gs_move_updates) {
				if (worth_rendering) {
					animateXY(_itemstack.x, _itemstack.y);
				} else {
					if (tweening) {
						stopAnimateXY();
					}
					x = _itemstack.x;
					y = _itemstack.y;
				}
			}
			
			if (_itemstack.rs > 0) {
				_lisChatBubbleManager.getRidOfBubble();
				lisRookManager.rook();
			} else if (_itemstack.rs == 0) {
				lisRookManager.unrook();
			}
		}
		
		override protected function _addedToStageHandler(e:Event):void {
			super._addedToStageHandler(e);
			try {
				if (_item.has_status) {
					model.worldModel.registerCBProp(statusChangeHandler, "itemstacks", tsid, "status");
				}
			} catch (err:Error) {
				CONFIG::debugging {
					Console.dir(err);
				}
			}
			
			addEventListener(MouseEvent.MOUSE_OVER, _mouseOverHandler);
			addEventListener(MouseEvent.MOUSE_OUT, _mouseOutHandler);
			
			aivManager.buildActionIndicators();
			
			//if this is a garden, let the manager handle it
			if(_item.tsid == GardenManager.GARDEN_CLASS_TSID){
				GardenManager.instance.add([tsid]);
			}
		}
		
		public function addGardenView(gv:GardenView):void {
			_garden_view = GardenView(gv);
			view_holder.addChild(_garden_view);
			TipDisplayManager.instance.unRegisterTipTrigger(hit_target);
			if (ss_view) SSViewSprite(ss_view).visible = false;
			setPhysicsProps();
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(_garden_view) return null;
			if (_item.hasTags('no_tooltip')) return null;
			
			var trophy_item:Item;
			
			// if we're over a trophy, d the special thing
			if (trophy_case_holder) {
				var iiv:ItemIconView;
				for (var i:int;i<trophy_case_holder.numChildren;i++) {
					iiv = trophy_case_holder.getChildAt(i) as ItemIconView;
					
					trophy_item = model.worldModel.getItemByTsid(iiv.tsid);
					if (iiv.hitTestPoint(StageBeacon.stage_mouse_pt.x, StageBeacon.stage_mouse_pt.y)) {
						return {
							txt: trophy_item.label,
							offset_x: iiv.x,
							offset_y: iiv.height + 10
						}
					}
				}
			}
			
			var pt:Point = localToGlobal(
				new Point(
					0,
					Math.round(view_holder.getBounds(this).bottom)
				)
			);
			
			return _itemstack.getLocationTip(pt, tip_target);
		}
		
		public function getRidOfBubble():void {
			_lisChatBubbleManager.getRidOfBubble();
		}
		
		override protected function _deconstruct():void {
			getRidOfBubble();
			removeEventListener(MouseEvent.MOUSE_OVER, _mouseOverHandler);
			removeEventListener(MouseEvent.MOUSE_OUT, _mouseOutHandler);
			
			if (trophy_case_holder) {
				trophy_case_holder.removeEventListener(MouseEvent.MOUSE_OVER, onTrophyOver);
				trophy_case_holder.removeEventListener(MouseEvent.MOUSE_OUT, onTrophyOut);
				trophy_case_holder.removeEventListener(MouseEvent.CLICK, onTrophyClick);
			}
			try {
				if (_item.has_status) {
					model.worldModel.unRegisterCBProp(statusChangeHandler, "itemstacks", tsid, "status");
				}
			} catch(err:Error) {
				CONFIG::debugging {
					Console.error('problem unregistering');
				}
			}
			super._deconstruct();
		}
		
		public function get x_of_int_target():Number {
			return x + interaction_target_x_correction;
		}
		
		override public function get interaction_target():DisplayObject {
			if (_garden_view) return _garden_view;
			
			// This may fuck some things up!:
			if (use_mc && _mc && _mc.interaction_target) return DisplayObject(_mc.interaction_target);
			
			return (view_holder) ? DisplayObject(view_holder) : DisplayObject(this);
		}
		
		override public function glow():void {
			if (!_glowing) {
				super.glow();
				
				//glow the whole garden
				if (_garden_view) {
					if (model.stateModel.info_mode) {
						_garden_view.filters = getGlowFilter();
					} else {
						if (_garden_view.is_owner && !_garden_view.is_tending) _garden_view.glow();
					}

				}
			}
		}
		
		public function bringToFront():void {
			if (mainView) {
				// the false says not to remove the on_furniture prop on the itemstack, needed because we call 
				// bringToFront in the course of dragging furn around, and that can cause on_furniture to get wiped out for
				// the items that are on the furniture
				mainView.gameRenderer.bringItemstackToFront(tsid, false);
				_lisChatBubbleManager.addBubbleWhereItGoes();
			}
		}
		
		public function _statusButtonClickHandler(e:MouseEvent):void {
			if (e.target is Button) {
				if (Button(e.target).disabled) {
					return;
				}
				var verb_tsid:String = e.target.name;
				TSFrontController.instance.doVerb(tsid, verb_tsid);
				
			}
			StageBeacon.stage.focus = StageBeacon.stage;
		}
		
		private function statusChangeHandler(status:ItemstackStatus):void {
			if (model.stateModel.hide_loc_itemstacks) return;
			
			aivManager.buildActionIndicators();
		}
		
		override public function unglow(force:Boolean=false):void {
			if (_glowing || force) { 
				aivManager.aivs_hidden_for_glow = false;
			}
			
			if(_garden_view) {
				_garden_view.filters = null;
				_garden_view.unglow();
			}
			
			super.unglow(force);
		}
		
		private var gety_rect:Rectangle;
		public function getYAboveDisplay():int {
			if (y_above) return y_above+itemstack_talk_bubble_offest;
			
			const px_tolerance:int = 20; //how many pixels need to change before a new action_indicator_offset is set
			
			var view_do:DisplayObject = ss_view as DisplayObject;
			var rect:Rectangle;
			
			if (_garden_view) {
				gety_rect = this.getRect(this);
				gety_rect.top-=35;
			} else if (view_do && view_do.width && view_do.height) { // if we dont check w and h, then when the thing is invisible, as in rocks, the rect is WACKY
				gety_rect = view_do.getRect(this);
			} else {
				gety_rect = this.getRect(this);
			}
			
			if(gety_rect.top - action_indicator_offset > px_tolerance || action_indicator_offset - gety_rect.top > px_tolerance){
				action_indicator_offset = gety_rect.top;
			}

			return action_indicator_offset+itemstack_talk_bubble_offest;
		}
		
		override public function bubbleHandler(msg:Object):void {
			_lisChatBubbleManager.handleBubble(msg);
		}
		
		protected function _mouseOutHandler(e:MouseEvent):void {
			has_mouse = false;
		}
		
		protected function _mouseOverHandler(e:MouseEvent):void {
			if (getTimer() - StageBeacon.last_mouse_move > 1000) return;
			has_mouse = true;
		}
		
		override protected function onLoad(ss:SSAbstractSheet, url:String):void {
			super.onLoad(ss, url);
			if (url != used_swf_url) return;
			if (disposed) return;
			
			// ignore this because it is the initial load of the swf, and we will be recalling to get a unique swf for this instance to use
			if (use_mc && !_mc) {
				return;
			}
			
			var swf_data:SWFData = ItemSSManager.getSWFDataByUrl(used_swf_url);
			
			// not sure if this is good or bad to do!
			if (use_mc && swf_data.is_trant) {
				_mc.cacheAsBitmap = true;
				//Console.warn(item.tsid+' '+tsid+' cacheAsBitmap:'+cacheAsBitmap);
			}
			
			placeTrophies();
			if (_itemstack.rs > 0) {
				_lisChatBubbleManager.getRidOfBubble();
				lisRookManager.rook();
			}
			
			// physics is waiting for the dimensions, which are now ready
			setPhysicsProps();
			
			if (_garden_view && ss_view) SSViewSprite(ss_view).visible = false;
			if (bob_amt) startBob();
			
			_lisChatBubbleManager.repositionChatBubble(new Point(0, getYAboveDisplay()));
			ChoicesDialog.instance.repositionIfShowingConversationForThisLIV(tsid);
			
			if (_convo_to_run_after_load) {
				CONFIG::debugging {
					Console.info('RUNNING DELAYED CONVO FOR LIS_VIEW:'+tsid);
				}
				ConversationManager.instance.start(_convo_to_run_after_load);
				_convo_to_run_after_load = null;
			}
			
			if (use_stage_for_hitbox) {
				drawHitBox(swf_data.mc_w, swf_data.mc_h);
			}
			
			if (model.worldModel.poof_ins[tsid]) {
				if (worth_rendering) {
					poofItIn();
				}
				model.worldModel.poof_ins[tsid] = null;
				delete model.worldModel.poof_ins[tsid];
			}
			
			_loadCompleted_sig.dispatch(this);

			TipDisplayManager.instance.registerTipTrigger(hit_target);
			
			// do this so that clicks on the view_holder will be ignored, since the hitbox is what we want to receive clicks if it exists
			if (hit_box) {
				view_holder.mouseEnabled = false;
				view_holder.mouseChildren = false;
			}
			
			if (_item.isSnappable()) {
				TSFrontController.instance.resnapMiniMap();
			}
		}
		
		private function poofItIn():void {
			view_holder.alpha = 0;
			var annc:Object = {
				type: 'itemstack_overlay',
				itemstack_tsid: tsid,
				duration: 2000,
				swf_url: model.worldModel.poof_ins[tsid],
				place_at_bottom: true
			};
		
			// let's create an asv to make sure we have the annc swf loaded, and to measure some stuff
			var asv:ArbitrarySWFView = new ArbitrarySWFView(
				annc.swf_url,
				0
			);
			
			asv.addEventListener(TSEvent.COMPLETE, function(e:TSEvent):void {
				
				if (asv.mc) {
					// this is the loaded swf stage height
					var swf_h:int = asv.mc.loaderInfo.height;
					
					// this centers the poof on the item
					annc.delta_y = Math.round(swf_h/2 - view_holder.height/2);
				}
				
				// dispose it NOW, so the loaded swf is added back to the pool and can be reused for the annc
				asv.dispose();
				
				model.activityModel.announcements = Announcement.parseMultiple([annc]); // fires trigger when set
				TSTweener.addTween(view_holder, {alpha:1, time:1, delay:.2});
			});
		}
		
		private function calculateInteractionTargetXCorrection():void {
			var int_target:DisplayObject;
			if (use_mc && _mc && _mc.interaction_target) {
				int_target = _mc.interaction_target;
			} else if (ss_view && SSViewSprite(ss_view).interaction_target) {
				int_target = SSViewSprite(ss_view).interaction_target;
			}
			
			if (int_target) {
				var rect:Rectangle = int_target.getBounds(this);
				interaction_target_x_correction = rect.x+(rect.width/2);
			} else {
				interaction_target_x_correction;
			}
		}
		
		CONFIG::god public function showCTBox():void {
			if (ct_box) ct_box.visible = true;
		}
		
		CONFIG::god public function hideCTBox():void {
			if (ct_box) ct_box.visible = false;
		}
		
		CONFIG::god private function drawCTBox():void {
			if (!ct_box) return;
			var itemstack_state:ItemstackState = _itemstack.itemstack_state;
			
			var ct_w:int;
			var ct_h:int;
			
			if (_item.tsid == 'clickable_broadcaster') {
				ct_w = 60;
				ct_h = 60;
			} else if (itemstack_state.config) {
				ct_w = itemstack_state.config.w;
				ct_h = itemstack_state.config.h;
			}
			
			if (!ct_w || !ct_h) return;
			
			var g:Graphics = ct_box.graphics;
			g.clear();
			g.lineStyle(0, 0, 0);
			if (_item.tsid == 'ctgc') {
				g.beginFill(0x0000ff, .5);
			} else {
				g.beginFill(0x00ff00, .5);
			}
			g.drawRect(Math.round(-ct_w/2), -ct_h, ct_w, ct_h);
		}
		
		private function setPhysicsProps():void {
			// at least 100 by 100, until we actually get dimensions from the item defs
			var w:Number = _itemstack.client::physWidth  = Math.max(100, width);
			var h:Number = _itemstack.client::physHeight = Math.max(100, height);
			// for a circle that circumscribes the itemstack from the center,
			// the diameter is the hypotenuse of the triangle formed by the w and h;
			_itemstack.client::physRadius = (0.5 * Math.sqrt(w*w + h*h));
		}
		
		override protected function _positionViewDO():void {
			var view_do:DisplayObject;
			if (use_mc) {
				view_do = _mc as DisplayObject;
			} else {
				view_do = ss_view as DisplayObject;
			}
			
			if (!view_do) {
				if (!placeholder.parent) view_holder.addChild(placeholder);
				placeholder.x = -Math.round(placeholder.width/2);
				placeholder.y = -Math.round(placeholder.height);
				
				showHide();
				return;
			} else if (placeholder.parent) {
				placeholder.parent.removeChild(placeholder);
			}
			
			try {
				view_do.x = -Math.round((ss.ss_options.movieWidth*_itemstack.scale)/2);
				view_do.y = -ss.ss_options.movieHeight*_itemstack.scale;
				view_do.visible = true;
				calculateInteractionTargetXCorrection();
			} catch (err:Error) {
				var err_str:String = _item.tsid+' use_mc:'+use_mc+' view_do:'+view_do+' ss:'+ss+'\n'+load_log;
				if (ss) {
					err_str+= ' ss.ss_options:'+ss.ss_options;
				} else {
					err_str+= ' NO ss?';
				}
				BootError.handleError(err_str, err, null, true);
			}
		}
		
		public function showHide():void {
			// sometimes hidden
			visible = (model.stateModel.hide_loc_itemstacks || !_worth_rendering ? false : _itemstack.itemstack_state.visibility);
			
			// special!
			if (_item.tsid == 'furniture_door' && _itemstack.client::door) {
				visible = visible && model.stateModel.decorator_mode;
				var door_view:DoorView = TSFrontController.instance.getMainView().gameRenderer.getDoorViewByTsid(_itemstack.client::door.tsid);
				if (door_view) door_view.visible = !visible;
			}
			
			if (!view_holder.numChildren) visible = false;
			
			aivManager.showHideAIVs();
			visible ? _lisChatBubbleManager.showChatBubble() : _lisChatBubbleManager.hideChatBubble();
		}
		
		public function adjustForSnapping(show_indicators_and_chat_bubbles:Boolean):void {
			if (lot_deco_holder) {
				lot_deco_holder.alpha = 1;
				
				if (lot_deco_holder.numChildren) {
					var deco:MovieClip = lot_deco_holder.getChildAt(0) as MovieClip;
					if (deco && deco.hasOwnProperty('sign')) deco.sign.visible = false;
				}
				
				if (_ss_view) DisplayObject(_ss_view).visible = false;
			}
			
			if (!show_indicators_and_chat_bubbles) {
				_lisChatBubbleManager.hideChatBubble();
				
				// force hide AIVs
				aivManager.indicators_visible = false;
				aivManager.positionActionIndicators(true);
			}
		}
		
		public function unAdjustForSnapping():void {
			if (lot_deco_holder) {
				lot_deco_holder.alpha = .5;
				
				if (lot_deco_holder.numChildren) {
					var deco:MovieClip = lot_deco_holder.getChildAt(0) as MovieClip;
					if (deco && deco.hasOwnProperty('sign')) deco.sign.visible = true;
				}
				
				if (_ss_view) DisplayObject(_ss_view).visible = true;
			}
			
			_lisChatBubbleManager.showChatBubble();
			
			// reshow AIVs
			aivManager.showHideAIVs();
		}
		
		public function testHitTargetAgainstPoint(x:Number, y:Number):Boolean {
			return hit_target.hitTestPoint(x, y);
		}
		
		private function onTimeLeftTick(e:TimerEvent):void {
			var itemstack_state:ItemstackState = _itemstack.itemstack_state;
			
			if (!itemstack_state.config || !('time_left' in itemstack_state.config)) {
				time_left_timer.stop();
				if (time_left_sp.parent) time_left_sp.parent.removeChild(time_left_sp);
				return;
			}
			
			var since_started:int = (getTimer()-time_left_start)/1000;
			var secs_to_display:int = Math.max(0, Math.round(time_left-since_started));
			
			if (secs_to_display == 0) {
				time_left_timer.stop();
			}
			
			time_left_tf.htmlText = '<p class="time_left">'+StringUtil.formatSecsAsDigitalClock(secs_to_display)+'</p>';
		}
		
		private var time_left_sp:Sprite;
		private var time_left_tf:TextField;
		private var time_left_timer:Timer;
		private var time_left_start:int; // getTimer when we start couting down
		private var time_left:int = -1; // the amount of time the thing counts down from
		private function creatTimeLeftSp():void {
			if (time_left_sp) return;
			
			time_left_sp = new Sprite();
			time_left_sp.cacheAsBitmap = true;
			time_left_sp.name = 'time_left_sp';
			time_left_sp.x = CSSManager.instance.getNumberValueFromStyle(_item.tsid, 'time_left_x', 0);
			time_left_sp.y = CSSManager.instance.getNumberValueFromStyle(_item.tsid, 'time_left_y', 0);
			
			addChild(time_left_sp);
			
			time_left_tf = new TextField();
			time_left_tf.name = 'time_left_tf';
			TFUtil.prepTF(time_left_tf, false);
			time_left_tf.autoSize = TextFieldAutoSize.NONE;
			time_left_tf.width = CSSManager.instance.getNumberValueFromStyle(_item.tsid, 'time_left_w', 100);
			time_left_tf.height = CSSManager.instance.getNumberValueFromStyle(_item.tsid, 'time_left_h', 20);
			time_left_sp.addChild(time_left_tf);
			
			time_left_timer = new Timer(1000);
			time_left_timer.addEventListener(TimerEvent.TIMER, onTimeLeftTick);
		}
		
		public function onAddedToView():void {

		}
		
		override protected function doSpecialConfigStuff():void {
			if (!worth_rendering) return;
			super.doSpecialConfigStuff();
		}
		
		override protected function setupSpecialFrontContainer():void {
			super.setupSpecialFrontContainer();
		}
		
		override protected function setupSpecialBackContainer():void {
			super.setupSpecialBackContainer();
		}
		
		protected function doMouseState():void {
			var treat_like_furn:Boolean = _item.is_furniture || _item.is_special_furniture;
			var should_have_hand:Boolean = _itemstack.is_clickable;
			
			CONFIG::god {
				should_have_hand ||= model.flashVarModel.interact_with_all;
			}
			
			var should_have_tip:Boolean = should_have_hand || treat_like_furn;
			
			// do it!
			buttonMode = should_have_hand;
			mouseChildren = mouseEnabled = should_have_tip;
		}
		
		override protected function animate(force:Boolean = false, at_wh:int = 0):void {
			var itemstack_state:ItemstackState = _itemstack.itemstack_state;
			
			showHide();
			doMouseState();
			
			if (itemstack_state.type == ItemstackState.TYPE_VISIBILITY) {
				// it might have beem stopped because it was not worth_rendering, so start it again
				if (ss_view && itemstack_state.visibility && worth_rendering) ss_view.play();
				return;
			}
			
			if (itemstack_state.type == ItemstackState.TYPE_ANIMATION_NAME) {
				if (itemstack_state.facing_right) {
					_faceRight();
				} else {
					_faceLeft();
				}
			}
			
			if (itemstack_state.furn_config) {
				if (itemstack_state.furn_config.facing_right) {
					_faceRight();
				} else {
					_faceLeft();
				}
			}
			
			CONFIG::god {
				if (_item.has_ct_box) {
					drawCTBox();
				}
			}
			
			if (itemstack_state.config) {
				
				if ('time_left' in itemstack_state.config && itemstack_state.config.time_left != time_left) {
					time_left = itemstack_state.config.time_left; // store this so we know when it has changed
					if (!time_left_sp) creatTimeLeftSp(); // create it if we haven't already
					time_left_timer.start();
					time_left_start = getTimer(); // we'll measure the time passed since this time on every tick of the timer
				}
				
				if (itemstack_state.config.preview_deco) {
					if (!lot_deco_holder) {
						lot_deco_holder = new Sprite();
					}
					
					if (lot_deco_holder.name != itemstack_state.config.deco) {
						while (lot_deco_holder.numChildren) lot_deco_holder.removeChildAt(0);
						lot_deco_holder.name = itemstack_state.config.deco;
						var g:Graphics = lot_deco_holder.graphics;
						
						DecoAssetManager.loadIndividualDeco(itemstack_state.config.deco, function(mc:MovieClip, class_name:String, swfWidth:Number, swfHeight:Number):void {
							if (class_name != lot_deco_holder.name) return;
							g.clear();
							lot_deco_holder.addChild(mc);
							lot_deco_holder.x = -swfWidth/2;
							lot_deco_holder.y = -swfHeight;
							lot_deco_holder.alpha = .5;
						});
						
						// if loadIndividualDeco succeeds, the below drawing will get cleared
						g.clear();
						g.lineStyle(0, 0, 0);
						g.beginFill(0, .5);
						g.drawRect(0, 0, itemstack_state.config.deco_w, itemstack_state.config.deco_h);
						
						lot_deco_holder.x = -lot_deco_holder.width/2;
						lot_deco_holder.y = -lot_deco_holder.height;
						 
						addChildAt(lot_deco_holder, 0);
					}
				}
			}
			
			if (!model.flashVarModel.change_state_when_still || !tweening) { 
				super.animate(force, at_wh);
			}
			
			doSpecialConfigStuff();
			
			lisRookManager.positionRookedOverlay();
			setPhysicsProps();
			calculateInteractionTargetXCorrection();

			// keep it on top!!
			if (time_left_sp) {
				addChild(time_left_sp);
			}
			
		}
		
		override protected function onTweenComplete():void {
			var was_tweening:Boolean = tweening;
			tweening = false;
			if (was_tweening && model.flashVarModel.change_state_when_still && _itemstack.itemstack_state.is_value_dirty) {
				changeHandler();
			}
		}
		
		public function get is_flipped():Boolean {
			return view_holder.scaleX < 0;
		}
		
		private function _faceRight():void {
			if (polarity_switched) {
				view_holder.scaleX = -1;
			} else {
				view_holder.scaleX = 1;
			}
		}
		
		private function _faceLeft():void {
			if (polarity_switched) {
				view_holder.scaleX = 1;
			} else {
				view_holder.scaleX = -1;
			}
		}
		
		override public function dispose():void {
			if (stopped_by_mouse_tim) StageBeacon.clearTimeout(stopped_by_mouse_tim);
			
			if (model.worldModel.poof_ins[tsid]) {
				model.worldModel.poof_ins[tsid] = null;
				delete model.worldModel.poof_ins[tsid];
			}
			
			if (time_left_timer) {
				time_left_timer.stop();
				time_left_timer.removeEventListener(TimerEvent.TIMER, onTimeLeftTick);
			}
			
			lisRookManager.dispose();
			_lisChatBubbleManager.dispose();
			
			if (_garden_view) {
				// any clean up needed for the garden_view
				_garden_view.dispose();
			} 
			
			stopBob();
			
			aivManager.removeActionIndicator(null, true);
			
			if (special_back_holder) SpriteUtil.clean(special_back_holder, true);
			if (special_front_holder) SpriteUtil.clean(special_front_holder, true);
			
			super.dispose();
		}

		public function get garden_view():GardenView { return _garden_view; }

		public function get convo_to_run_after_load():Object { return _convo_to_run_after_load; }
		public function set convo_to_run_after_load(value:Object):void { _convo_to_run_after_load = value; }
		public function get mouseClicked():ISignal { return _mouseClicked; }
		public function get lisChatBubbleManager():LisChatBubbleManager { return _lisChatBubbleManager; }
		public function get loadCompleted_sig():Signal {return _loadCompleted_sig; }
	}
}