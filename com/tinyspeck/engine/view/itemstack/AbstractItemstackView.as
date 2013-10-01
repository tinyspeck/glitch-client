package com.tinyspeck.engine.view.itemstack {
	
	import com.tinyspeck.core.memory.IDisposable;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.itemstack.ItemstackState;
	import com.tinyspeck.engine.memory.EnginePools;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.InfoManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.spritesheet.ISpriteSheetView;
	import com.tinyspeck.engine.spritesheet.ItemSSManager;
	import com.tinyspeck.engine.spritesheet.SSAbstractSheet;
	import com.tinyspeck.engine.spritesheet.SSAnimationCommand;
	import com.tinyspeck.engine.spritesheet.SSViewSprite;
	import com.tinyspeck.engine.spritesheet.SWFData;
	import com.tinyspeck.engine.util.MCUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.itemstack.commands.ItemstackCommands;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Scene;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;
	
	// we could come up with a way to get this from the quoin swfs tiles_length prop, but let's just set manually
	CONFIG const QUOIN_FRAME_COUNT = 24;
	
	public class AbstractItemstackView extends TSSpriteWithModel implements IDisposable, ISpecialConfigDisplayer {
		
		protected var uid:int = getTimer();
		protected var _itemstack:Itemstack;
		public function get itemstack():Itemstack {
			return _itemstack;
		}

		protected var _item:Item;
		public function get item():Item {
			return _item;
		}
		
		protected var _ss_state:Object;
		protected var ss:SSAbstractSheet;
		protected var _ss_view:ISpriteSheetView;
		protected var special_back_holder:Sprite
		protected var special_front_holder:Sprite
		protected var view_holder:Sprite = new Sprite();
		protected var placeholder:Sprite = new Sprite();
		protected var use_mc:Boolean = false;
		protected var _mc:MovieClip;
		protected var _worth_rendering:Boolean = true;
		protected var loaded:Boolean;
		protected var loading_started:Boolean;
		protected var used_swf_url:String;
		protected var used_scale:Number;
		
		// this can be used to force this view to use a specific animation state instead of that of the itemstack it represents
		public var ss_state_override:String;
		
		private var view_and_state_ob:Object = {};
		
		public function AbstractItemstackView(tsid:String):void {
			super(tsid);
			_itemstack = model.worldModel.getItemstackByTsid(tsid);
			_item = _itemstack.item;
			used_swf_url = _itemstack.swf_url;
			used_scale = _itemstack.scale;
		}
		
		override protected function _addedToStageHandler(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, _addedToStageHandler);
		}
		
		override protected function _construct():void {
			super._construct();
			
			view_holder.mouseEnabled = false;
			view_holder.name = 'view_holder';
			addChild(view_holder);
			
			placeholder.name = 'placeholder';
			
			if (_worth_rendering) {
				loading_started = true;
				loadPlaceHolder(Item.TYPE_PLACEHOLDER_THROBBER);
				ItemSSManager.getSSForItemSWFByUrl(used_swf_url, _item, onLoad);
			}
		}
		
		protected var placeholder_showing:String;
		protected var expected_placeholder_key:String;
		protected function loadPlaceHolder(which_placeholder:String):void {
			if (placeholder_showing == which_placeholder) {
				return;
			}
			
			if (!model.flashVarModel.show_missing_itemstacks) {
				SpriteUtil.clean(placeholder);
			}
			
			if (which_placeholder == Item.TYPE_PLACEHOLDER_THROBBER) {
				if (!model.flashVarModel.placehold_itemstacks) return;
				
				placeholder_showing = Item.TYPE_PLACEHOLDER_THROBBER;
				expected_placeholder_key = Item.TYPE_PLACEHOLDER_THROBBER;
				TSFrontController.instance.getItemPlacement(_item.tsid, onItemPlacement);
			
			} else if (which_placeholder == Item.TYPE_PLACEHOLDER_MISSING) {
				if (!model.flashVarModel.show_missing_itemstacks) return;
				
				placeholder_showing = Item.TYPE_PLACEHOLDER_MISSING;
				expected_placeholder_key = _item.tsid+'::'+Item.TYPE_PLACEHOLDER_MISSING;
				TSFrontController.instance.getItemMissingAsset(_item.tsid, onItemMissingAsset);
			
			} else {
				return;
			}
		}
		
		protected function onItemPlacement():void {
			if (placeholder_showing != Item.TYPE_PLACEHOLDER_THROBBER) {
				return;
			}
			
			AssetManager.instance.loadBitmapFromBASE64(Item.TYPE_PLACEHOLDER_THROBBER, Item.LOADING_THROBBER_STR, onPlaceHolderLoad);
		}
		
		protected function onItemMissingAsset():void {
			if (placeholder_showing != Item.TYPE_PLACEHOLDER_MISSING) {
				return;
			}
			
			var str:String = _item.missing_asset;
			var key:String = expected_placeholder_key;
			
			if (!str) {
				expected_placeholder_key = key = Item.TYPE_PLACEHOLDER_MISSING;
				str = Item.MISSING_ASSET_IMG_STR;
			}
			
			if (str) {
				AssetManager.instance.loadBitmapFromBASE64(key, str, onPlaceHolderLoad);
			}
		}
		
		protected function makeMissingPlaceHolder(bm:Bitmap):Bitmap {
			return bm;
		}
		
		protected function onPlaceHolderLoad(key:String, bm:Bitmap):void {
			if (key != expected_placeholder_key) return;
			SpriteUtil.clean(placeholder);
			placeholder.addChild(makeMissingPlaceHolder(bm));
			_positionViewDO();
		}
		
		public function get is_shrine():Boolean {
			return (_item.tsid.indexOf('npc_shrine') == 0);
		}
		
		public function get ss_view():ISpriteSheetView {
			return _ss_view;
		}
		
		public function get ss_state():Object {
			return _ss_state;
		}
		
		protected var load_log:String = 'v1\n';
		private var ss_for_fresh_mc:SSAbstractSheet;
		private var _mc_swf_url:String;
		private function onFreshMCReady(fresh_mc:MovieClip, url:String):void {
			load_log+= 'onFreshMCReady called ss_for_fresh_mc:'+ss_for_fresh_mc+'\n';
			if (disposed) {
				var swf_data:SWFData = ItemSSManager.getSWFDataByUrl(url);
				if (swf_data) {
					swf_data.addReusableMC(fresh_mc);
				}
				return;
			}
			
			if (_mc) {
				swf_data = ItemSSManager.getSWFDataByUrl(_mc_swf_url);
				if (swf_data) {
					swf_data.addReusableMC(_mc);
				}
			}
			
			_mc_swf_url = url;
			_mc = fresh_mc;
			onLoad(ss_for_fresh_mc, url);
			ss_for_fresh_mc = null;
		}
		
		protected function onLoad(ss:SSAbstractSheet, url:String):void {
			if (disposed) return;
			if (url != used_swf_url) return;
			removeSS();

			var view_do:DisplayObject;
			
			if (use_mc) {
				if (!_mc) {
					// we've loaded the ss, so now we can safely call getFreshMCForItem
					// and set the mc to the fresh_mc it returns, and then recall this method
					ss_for_fresh_mc = ss; // we can't set this.ss yet (checking for ss is a way this class sees if it is loaded), but we have to store ss so onFreshMCReady can set it
					var self:AbstractItemstackView = this;
					load_log+= 'calling ItemSSManager.getFreshMCForItem ss_for_fresh_mc:'+ss_for_fresh_mc+'\n';
					ItemSSManager.getFreshMCForItemSWFByUrl(used_swf_url, _item, onFreshMCReady);
					return;
				}

				load_log+= 'onLoad called ss:'+ss+'\n';
				this.ss = ss;
				view_do = _mc;
				_mc.scaleX = _mc.scaleY = _itemstack.item.scale;
				
			} else {
				this.ss = ss;
				
				if (!ss) {
					loadPlaceHolder(Item.TYPE_PLACEHOLDER_MISSING)
					onLoadDone();
					return;
				}
				
				_ss_view = ss.getViewSprite();
				
				if (!ss_view) {
					CONFIG::debugging {
						Console.warn('got a ss but not a view');
					}
					// re-call this meth, so this.ss is nulledout and we show the correct thing
					onLoad(null, null);
					return;
				}
				
				view_do = _ss_view as DisplayObject;
				
			}
			
			view_holder.addChild(view_do);
			if (special_front_holder && special_front_holder.parent && special_front_holder.parent == view_holder) {
				view_holder.addChild(special_front_holder);
			}
			view_do.visible = false;
			
			animate(true);
			
			_positionViewDO();
			onLoadDone();
		}
		
		protected function onLoadDone():void {
			loaded = true;
			if (glowing) {
				_glowing = false; // needed so that glow will actually do the work (glow() might have been 
								  // called before, before it was loaded, and therefore not actually cased a glow)
				glow();
			}
			
			//
		}
		
		public function get is_loaded():Boolean{
			return loaded;
		}
		
		protected function animate(force:Boolean = false, at_wh:int = 0):void {
			if (disposed) return;
			
			if (model.flashVarModel.no_quoins && _itemstack.class_tsid == 'quoin') return;
			
			//Console.warn('itemstack.itemstack_state.dirty '+itemstack.itemstack_state.dirty);
			//Console.warn('itemstack.itemstack_state.dirty_config '+itemstack.itemstack_state.dirty_config);
			//Console.warn('itemstack.itemstack_state.dirty_value '+itemstack.itemstack_state.dirty_value);
			
			// it is possible for this to be null, if the initial s for a quoin, for example, is visible:false,
			// because in that case we simply hide the item
			if (!_itemstack.itemstack_state.value) {
				return;
			}
			
			if (!_worth_rendering) {
				// we only want to bail here if we're using the swf or not forcing (force will be true if
				// we just loaded and so we really need to get the ss_view going so we can measure shit
				// properly) but note we will stop the ss_view if !_worth_rendering at the end of this func
				if (use_mc || !force) {
					if (ss_view) ss_view.stop();
					return;
				}
			}
			
			_ss_state = ss_state_override || _itemstack.itemstack_state.value;
			
			if (!ss) return;
			if (!force && !_itemstack.itemstack_state.is_dirty) return;
			if (_itemstack.itemstack_state.furn_config) {
				_itemstack.itemstack_state.furn_config.is_dirty = false;
			}
			
			if (use_mc) {
				animateMC(force, at_wh)
			} else {
				animateSS(force, at_wh)
			}
			
			_itemstack.itemstack_state.is_config_dirty = false;
			_itemstack.itemstack_state.is_value_dirty = false;
			
			if (!_worth_rendering) {
				if (ss_view) ss_view.stop();
			}
		}
		
		private function animateMC(force:Boolean = false, at_wh:int = 0):void {
			var swf_data:SWFData = ItemSSManager.getSWFDataByUrl(used_swf_url);
			
			// assumes that only is_timeline_animated mcs use config
			if (swf_data.is_timeline_animated) {
				if (_itemstack.itemstack_state.config_for_swf && (_itemstack.itemstack_state.is_config_dirty || force)) {
					if (_mc.hasOwnProperty('initializehead')) {
						CONFIG::debugging {
							Console.log(112, ss.name+' calling initializehead:'+_itemstack.itemstack_state.config_for_swf);
						}
						_mc.initializehead(_itemstack.itemstack_state.config_for_swf);
					}
					_itemstack.itemstack_state.is_config_dirty = false;
				}
			}
				
			var state_str:String = (typeof _ss_state == 'object') ? '' : _ss_state as String;
			var state_args:Object = (typeof _ss_state == 'object') ? _ss_state : null;
			
			if (!swf_data.is_timeline_animated && !swf_data.is_trant) {
				
				var scene:Scene = MCUtil.getSceneByName(_mc, state_str);
				if (scene) { // we have that scene in the mc
					CONFIG::debugging {
						Console.log(112, ss.name+' matched scene state:'+state_str);
					}								
					MCUtil.playScene(_mc, state_str);
					
				} else if (String(parseInt(state_str)) == state_str) { // we don't have that numbered scene; try and use highest_count_scene_name
					CONFIG::debugging {
						Console.log(112, ss.name+' using swf_data.highest_count_scene_name:'+swf_data.highest_count_scene_name+' instead of state:'+state_str);
					}								
					MCUtil.playScene(_mc, swf_data.highest_count_scene_name);
					
				} else { // use default_scene_name
					
					if (MCUtil.getSceneByName(_mc, ItemSSManager.DEFAULT_SCENE_NAME)) {
						CONFIG::debugging {
							Console.log(112, ss.name+' using default_scene_name:'+ItemSSManager.DEFAULT_SCENE_NAME+' instead of state:'+state_str);
						}
						MCUtil.playScene(_mc, ItemSSManager.DEFAULT_SCENE_NAME);
						
					} else {
						CONFIG::debugging {
							Console.warn('no scene for default_scene_name???');
						}
						_itemstack.itemstack_state.is_value_dirty = false;
						return;
					}
					
				}
				
			} else if (swf_data.is_timeline_animated) {
				// TODO - see ItemSSManager.playSSViewForItem and recordState for the relevant code
				if (state_str) {
					
					// always the case before street_sprites
					
					ItemSSManager.getViewAndState(state_str, view_and_state_ob);
					var play_anim_str:String = view_and_state_ob.play_anim_str;
					var view_str:String = view_and_state_ob.view_str;
					
					if (_mc.animations.indexOf(play_anim_str) == -1) {
						CONFIG::debugging {
							Console.log(112, ss.name+' '+_mc.animations.join(', ')+' does not contain '+play_anim_str);
						}
						_itemstack.itemstack_state.is_value_dirty = false;
						return;
					}
					
					if (view_str) {
						CONFIG::debugging {
							Console.log(112, ss.name+' calling mc.setOrientation("'+view_str+'")')
						}
						_mc.setOrientation(view_str);
					}
					CONFIG::debugging {
						Console.log(112, ss.name+' playAnimation '+play_anim_str)
					}
					_mc.playAnimation(play_anim_str);
					/*
					var anim:AnimationCommand = new AnimationCommand('sds');
					Console.warn(anim.state_args);
					Console.warn(anim.state_str);
					anim = new AnimationCommand({g:'ff'});
					Console.warn(anim.state_args);
					Console.warn(anim.state_str);*/
					
				} else if (state_args) {
					
					if (state_args.sequence && state_args.sequence is Array) {
						_mc.playAnimationSeq(state_args.sequence, (state_args.loop === true));
					}
					
				}
				
			} else if (swf_data.is_trant) {
				if (!state_args) state_args = _item.DEFAULT_STATE;
				state_args.seed = ItemSSManager.getSeedForItemSWFByUrl(used_swf_url, _item);
				_mc.setState(state_args);
			}
		}
		
		private function animateSS(force:Boolean = false, at_wh:int = 0):void {
			if (!ItemSSManager.checkStateForTrantIsOk(used_swf_url, _itemstack.itemstack_state)) {
				return;
			}
			
			var swf_data:SWFData = ItemSSManager.getSWFDataByUrl(used_swf_url);
			
			var fnum:int = 1;
			
			if (_item.tsid == 'quoin') {
				fnum = 1+Math.floor(Math.random()*CONFIG::QUOIN_FRAME_COUNT);
			}
			
			// get from pool
			var anim_cmd:SSAnimationCommand = EnginePools.SSAnimationCommandPool.borrowObject();
			anim_cmd.state_ob = ((this is LocationItemstackView && _itemstack.itemstack_state.type == ItemstackState.TYPE_DEFAULT) ? _itemstack.count : _ss_state);
			anim_cmd.config = _itemstack.itemstack_state.config_for_swf;
			anim_cmd.scale = _itemstack.scale;
			CONFIG::debugging {
				Console.log(111, _item.tsid+' playSSViewForItem: anim_cmd.state_ob:'+anim_cmd.state_ob);
			}
			ItemSSManager.playSSViewForItemSWFByUrl(used_swf_url, _item, ss_view, fnum, anim_cmd, null, at_wh);
			// return to pool
			EnginePools.SSAnimationCommandPool.returnObject(anim_cmd);
		}
		
		override protected function _deconstruct():void {
			super._deconstruct();
		}
		
		protected function getGlowFilter():Array {
			var filtersA:Array = StaticFilters.tsSprite_GlowA;
			if (model.stateModel.info_mode && this is LocationItemstackView) {
				if (InfoManager.instance.highlighted_view == this) {
					filtersA = StaticFilters.infoColorHighlightA;
				} else {
					filtersA = StaticFilters.infoColorA;
				}
			}
			
			return filtersA;
		}
		
		override public function glow():void {
			if (!_glowing) { 
				_glowing = true;
				if (_itemstack.is_glowey || model.stateModel.info_mode) {
					var filtersA:Array = getGlowFilter();
					
					if (ss_view && ss_view is SSViewSprite) {
						// in most cases we want to gloe the SS, but if there is stuff in the special holders
						// and there is not a cusomt interaction_target for the ss, we want to glow the view_holder
						// which contains the special containers
						if (SSViewSprite(ss_view).interaction_target || (!special_front_holder && !special_back_holder)) {
							SSViewSprite(ss_view).glow(filtersA);
						} else {
							view_holder.filters = filtersA;
						}
					} else /*if (use_mc && _mc)*/ {
						interaction_target.filters = filtersA;
					}
				}
			}
		}
		
		override public function unglow(force:Boolean=false):void {
			if (_glowing) { 
				_glowing = false;
				interaction_target.filters = null;
				if (ss_view && ss_view is SSViewSprite) {
					if (SSViewSprite(ss_view).interaction_target || (!special_front_holder && !special_back_holder)) {
						SSViewSprite(ss_view).unglow();
					} else {
						view_holder.filters = null;
					}
				}
			}
		}
		
		public function bubbleHandler(msg:Object):void {
			
		}
		
		protected function _positionViewDO():void {
			
		}
		
		protected function reloadIfNeeded():Boolean {
			if (used_swf_url != _itemstack.swf_url) {
				/*CONFIG::debugging {
					Console.warn('Holy shit, swf_url is changed for this stack '+tsid+' '+itemstack.swf_url);
				}*/
				reload(_itemstack.swf_url);
				return true;
			}
			if (used_scale != _itemstack.scale) {
				/*CONFIG::debugging {
					Console.warn('Holy shit, scale is changed for this stack '+tsid+' '+itemstack.scale);
				}*/
				reload(_itemstack.swf_url);
				return true;
			}
			
			return false;
		}
		
		private function reload(new_swf_url:String):void {
			/*CONFIG::debugging {
				Console.error('reload');
			}*/
			removeDisplays();
			
			// I think it is ok to rely on this getting called in onLoad
			// leaving this hear can cause a blip while we wait for the
			// reload, that are no so great
			//removeSS();
			
			ss = null;
			_ss_view = null;
			_mc = null;
			loaded = false;
			loading_started = false;
			
			used_swf_url = new_swf_url;
			used_scale = _itemstack.scale;
			if (_worth_rendering) {
				loading_started = true;
				ItemSSManager.getSSForItemSWFByUrl(used_swf_url, _item, onLoad);
			}
		}
		
		private function removeSS():void {
			var view_do:DisplayObject;
			if (ss_view) {
				view_do = ss_view as DisplayObject;
				CONFIG::debugging {
					Console.error('view_do.parent '+view_do);
				}
				if (view_do.parent) {
					view_do.parent.removeChild(view_do);
				}
				ss_view.stop();
			}
		}
		
		private function removeDisplays():void {
			if (_mc && use_mc && _item.tsid) {
				// add the loaded item swf to the pool so it can be reused
				var swf_data:SWFData = ItemSSManager.getSWFDataByUrl(used_swf_url);
				if (swf_data) {
					swf_data.addReusableMC(_mc);
					
					// we must remove it from the display list else super.dispose() fucks it up, and we want to reuse it
					if (_mc.parent && !(_mc.parent is Loader)) _mc.parent.removeChild(_mc);
				}
			}
			
			if (ss_view) { 
				ItemSSManager.removeSSViewforItemSWFByUrl(used_swf_url, _item, ss_view);
			}
			
		}
		
		protected var needs_specials_done_once:Boolean = true;
		protected function doSpecialConfigStuff():void {
			if (!ss_view) return;
			
			if (needs_specials_done_once) {
				// mark all the sconfigs dirty! since this is the first time we are rendering the stack
				// and otherwise we might not see them as dirty and so not render them at all
				_itemstack.itemstack_state.markAllSpecialConfigsDirty();
			}
			
			ItemstackCommands.handleSpecialConfigs(this, _itemstack, ss, used_swf_url);
			needs_specials_done_once = false;
		}
		
		/** 
		 * Removes Special Config's Display Object if it exists in one of the special containers
		 * Returns log string. 
		 */
		public function removeSpecialConfigDO(specialConfigID:String):String {
			var log_str:String;
			CONFIG::debugging {
				if (Console.priOK('740')) log_str = '';
			}
			if (cleanSpecialContainerByName(special_front_holder, specialConfigID)) {
				;//
				CONFIG::debugging {
					if (Console.priOK('740')) log_str+= 'removed front:'+specialConfigID+' ';
				}
			}
			if (cleanSpecialContainerByName(special_back_holder, specialConfigID)) {
				;//
				CONFIG::debugging {
					if (Console.priOK('740')) log_str+= 'removed back:'+specialConfigID+' ';
				}
			}
			
			return log_str;
		}
		
		public function addToSpecialBack(DO:DisplayObject):void {
			setupSpecialBackContainer();
			if (DO) special_back_holder.addChild(DO);
		}
		
		public function addToSpecialFront(DO:DisplayObject):void {
			setupSpecialFrontContainer();
			if (DO) special_front_holder.addChild(DO);
		}
		
		private function cleanSpecialContainerByName(cont:DisplayObjectContainer, do_name:String):Boolean {
			if (cont) {
				var child:DisplayObject = cont.getChildByName(do_name);
				if (child) {
					cont.removeChild(child);
					if (child is ISpriteSheetView) {
						ISpriteSheetView(child).ss.removeViewSprite(child as SSViewSprite);
						return true;
					}
				}
			}
			
			return false;
		}
		
		protected function setupSpecialFrontContainer():void {
			if (!special_front_holder) {
				special_front_holder = new Sprite();
				special_front_holder.name = 'special_front_holder';
				special_front_holder.mouseEnabled = special_front_holder.mouseChildren = false;
				view_holder.addChild(special_front_holder);
			}
		}
		
		protected function setupSpecialBackContainer():void {
			if (!special_back_holder) {
				special_back_holder = new Sprite();
				special_back_holder.name = 'special_back_holder';
				special_back_holder.mouseEnabled = true;
				view_holder.addChildAt(special_back_holder, 0);
			}
		}
		
		override public function dispose():void {
			removeDisplays();
			
			view_and_state_ob = null;
			_ss_view = null;
			_mc = null;
			
			super.dispose();
		}
	}
}