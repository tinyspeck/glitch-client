package com.tinyspeck.engine.view.itemstack {
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.FurnitureConfig;
	import com.tinyspeck.engine.data.itemstack.ItemstackState;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.memory.EnginePools;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.spritesheet.ISpriteSheetView;
	import com.tinyspeck.engine.spritesheet.ItemSSManager;
	import com.tinyspeck.engine.spritesheet.SSAbstractSheet;
	import com.tinyspeck.engine.spritesheet.SSAnimationCommand;
	import com.tinyspeck.engine.spritesheet.SWFData;
	import com.tinyspeck.engine.util.DisplayDebug;
	import com.tinyspeck.engine.util.MCUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.IAnnouncementArtView;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Scene;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	public class ItemIconView extends TSSpriteWithModel implements IAnnouncementArtView {
		private var _wh:int;
		private var specified_wh:int;
		private var ss_state:Object;
		private var special_swf_url:String;
		private var _registration:String;
		
		private var _mc:MovieClip;
		private var use_mc:Boolean = false;
		private var dont_animate:Boolean;
		private var _ss:SSAbstractSheet;
		private var _ss_view:ISpriteSheetView;
		private var view_holder:Sprite = new Sprite();
		private var _draw_box:Boolean = true;
		private var _loaded:Boolean;
		private var scale_to_stage:Boolean;
		private var placeholder:Sprite = new Sprite();
		
		public function ItemIconView(tsid:String=null, wh:int=0, raw_state:Object=null, registration:String='default', use_mc:Boolean=false, draw_box:Boolean=true, scale_to_stage:Boolean=false, dont_animate:Boolean=false):void {
			super(tsid);
			mouseChildren = false;
			specified_wh = _wh = wh;
			setSSState(raw_state);
			
			this.use_mc = use_mc;
			this.scale_to_stage = scale_to_stage;
			
			// if it is a class that requires it, override the passed argument
			if (!this.use_mc) this.use_mc = CSSManager.instance.getBooleanValueFromStyle('use_mc', tsid);
			
			this.dont_animate = dont_animate;
			
			_registration = registration;
			_draw_box = draw_box;
			
			view_holder.name = 'view_holder';
			
			placeholder.name = 'placeholder';
			
			_construct();
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
				AssetManager.instance.loadBitmapFromBASE64(Item.TYPE_PLACEHOLDER_THROBBER, Item.LOADING_THROBBER_STR, onPlaceHolderLoad);
			} else if (which_placeholder == Item.TYPE_PLACEHOLDER_MISSING) {
				if (!model.flashVarModel.show_missing_itemstacks) return;
				placeholder_showing = Item.TYPE_PLACEHOLDER_MISSING;
				expected_placeholder_key = tsid+'::'+Item.TYPE_PLACEHOLDER_MISSING;
				TSFrontController.instance.getItemMissingAsset(tsid, onItemMissingAsset);
			} else {
				return;
			}
		}
		
		protected function onItemMissingAsset():void {
			if (placeholder_showing != Item.TYPE_PLACEHOLDER_MISSING) {
				return;
			}
			
			var str:String = model.worldModel.getItemByTsid(tsid).missing_asset;
			var key:String = expected_placeholder_key;
			
			if (!str) {
				expected_placeholder_key = key = Item.TYPE_PLACEHOLDER_MISSING;
				str = Item.MISSING_ASSET_IMG_STR;
			}
			
			if (str) {
				AssetManager.instance.loadBitmapFromBASE64(key, str, onPlaceHolderLoad);
			}
		}
		
		protected function onPlaceHolderLoad(key:String, bm:Bitmap):void {
			if (key != expected_placeholder_key) return;
			SpriteUtil.clean(placeholder);
			placeholder.addChild(bm);
			placeViewDo();
		}
		
		// This new method supports the old method of sending a string value for the raw_state to the constructor or icon_animate(),
		// but it turns it into a hash; this way, we can send raw_state as a hash (instead of a string) that contains config
		// in addition to the state string, when needed.
		// If an ItemstackState is sent as raw_state, it already has a config and is thus just left alone
		private function setSSState(raw_state:Object=null):void {
			ss_state = raw_state;
			
			if (!ss_state) { // default
				ss_state = {
					state: 'iconic',
					config: null
				}
			}
			
			if (typeof raw_state == 'string') { // make it a hash
				ss_state = {
					state: raw_state,
					config: null
				}
			}
			
			if (!(ss_state is ItemstackState) && !ss_state.state) {
				ss_state.state = 'iconic';
			}
			
			// TODO: we need some magic here that will sense when special_swf_url has changed and do
			// what it takes to cause a reloading of the SWF/SS
			var item:Item = model.worldModel.getItemByTsid(tsid);
			var new_special_swf_url:String = (ss_state && ss_state.config is FurnitureConfig) ? FurnitureConfig(ss_state.config).swf_url : null;
			if (!new_special_swf_url) {
				if (ss_state is ItemstackState && ss_state.furn_config) {
					new_special_swf_url = ItemstackState(ss_state).furn_config.swf_url;
				}
			}
			/* NO NEED FOR THIS NOTICE IN THE LOGS ANYMORE I DONT THINK
			if (new_special_swf_url != special_swf_url) {
				; // sigh
				CONFIG::debugging {
					Console.warn('This is where a config swf_url just changed, hmmm');
				}
			}
			*/
			special_swf_url = new_special_swf_url;
		}
		
		public function get s():* {
			if (ss_state is ItemstackState) return ItemstackState(ss_state).value;
			return ss_state.state;
		}
		
		public function get wh():int {
			return specified_wh || _wh;
		}
		
		public function get art_w():Number {
			return view_holder.width;
		}
		
		public function get art_h():Number {
			return view_holder.height;
		}
		
		public function get ss_view():ISpriteSheetView {
			return _ss_view;
		}
		
		private function get swf_url():String {
			return special_swf_url || model.worldModel.getItemByTsid(tsid).asset_swf_v;
		}
		
		override protected function _addedToStageHandler(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, _addedToStageHandler);
		}
		
		override protected function _construct():void {
			super._construct();
			
			drawBox();
			
			addChild(view_holder);
			
			var item:Item = model.worldModel.getItemByTsid(tsid);
			if (!item) {
				; // satisfy compiler
				CONFIG::debugging {
					Console.error(tsid+' is not an item');
				}
			} else {
				const sheet:SSAbstractSheet = ItemSSManager.getSSByUrl(swf_url);
				if (sheet) {
					// available immediately
					onLoad(sheet, swf_url);
				} else {
					// not available yet
					ItemSSManager.getSSForItemSWFByUrl(swf_url, item, onLoad);
				}
				loadPlaceHolder(Item.TYPE_PLACEHOLDER_THROBBER);
			}
		}
		
		private function drawBox():void {
			if (_draw_box) {
				graphics.clear();
				graphics.beginFill(0x00cc00, 0);
				graphics.drawRect(view_holder.x, view_holder.y, wh, wh);
			}
		}
		
		public function get mc():MovieClip {
			if (use_mc) {
				return _mc;
			} else {
				throw new Error('You can\'t get the mc if use_mc is false');
			}
		}
		
		private var ss_for_fresh_mc:SSAbstractSheet;
		private function onLoad(ss:SSAbstractSheet, url:String):void {
			if (!ss) {
				loadPlaceHolder(Item.TYPE_PLACEHOLDER_MISSING);
			} else {
				var item:Item = model.worldModel.getItemByTsid(tsid);
				var view_do:DisplayObject;
				
				if (use_mc) {
					if (!_mc) {
						// we've loaded the ss, so now we can safely call getFreshMCForItem
						// and set the mc to the fresh_mc it returns, and then recall this method
						ss_for_fresh_mc = ss; // we can't set this.ss yet (checking for ss is a way this class sees if it is loaded), but we have to store ss so onFreshMCReady can set it
						var self:ItemIconView = this;
						ItemSSManager.getFreshMCForItemSWFByUrl(swf_url, item, onFreshMCReady);
						return;
					}
					
					this._ss = ss;
					view_do = _mc;
				} else {
					this._ss = ss;
					
					if (true) {
						_ss_view = ss.getViewSprite();
					} else {
						_ss_view = ss.getViewBitmap();
					}
					view_do = _ss_view as DisplayObject;
					
				}
				
				view_holder.addChild(view_do);
				icon_animate(ss_state, true);
			}
			
			_loaded = true;
			dispatchEvent(new TSEvent(TSEvent.COMPLETE));
		}
		
		private var _mc_swf_url:String;
		private function onFreshMCReady(fresh_mc:MovieClip, url:String):void {
			if (_mc) {
				var swf_data:SWFData = ItemSSManager.getSWFDataByUrl(_mc_swf_url);
				if (swf_data) {
					swf_data.addReusableMC(_mc);
				}
			}
			
			_mc_swf_url = url;
			_mc = fresh_mc;
			onLoad(ss_for_fresh_mc, url);
			ss_for_fresh_mc = null;
		}
		
		private function placeViewDo():void {
			//if (tsid == 'apple') Console.warn('placeViewDo 1');
			var view_do:DisplayObject = ((use_mc) ? _mc : _ss_view) as DisplayObject;
			
			var scale_it:Boolean = true;
			
			if (!view_do) {
				if (!placeholder.parent) view_holder.addChild(placeholder);
				view_do = placeholder;
				scale_it = false;
			} else {
				if (placeholder.parent) {
					placeholder.parent.removeChild(placeholder); 
				}
			}
			
			// make sure these are reset, for placement measuring
			view_do.scaleX = view_do.scaleY = 1;
			view_do.x = view_do.y = 0;
			view_holder.x = view_holder.y = 0;
			
			if (specified_wh && scale_it) {
				if (!scale_to_stage || use_mc) {
					if (view_do.width > view_do.height) {
						view_do.scaleX = view_do.scaleY = specified_wh/view_do.width;
					} else {
						view_do.scaleX = view_do.scaleY = specified_wh/view_do.height;
					}
				}
			} else {
				_wh = (view_do.width > view_do.height) ? view_do.width : view_do.height;
			}
			
			var rect:Rectangle = view_do.getBounds(view_holder);
			view_do.x = -rect.x+Math.round((wh-view_do.width)/2);
			
			if (_registration == 'center_bottom' && wh > view_do.height) {
				// still not perfect... does not match up with how the item is positioned as a locItemstack.
				view_do.y = -rect.y+(wh-view_do.height);
			} else {
				view_do.y = -rect.y+Math.round((wh-view_do.height)/2);
			}
			
			// only if this is an item playing tool_animation, apply the known offsets to make the animation be centered more nicely
			if (s == 'tool_animation') {
				view_do.x+= CSSManager.instance.getNumberValueFromStyle(tsid, 'tool_anim_offset_x', 0)*(wh/40);
				view_do.y+= CSSManager.instance.getNumberValueFromStyle(tsid, 'tool_anim_offset_y', 0)*(wh/40);
			}
			
			if (_registration == 'center') {
				view_holder.x = -Math.round(wh/2);
				view_holder.y = -Math.round(wh/2);
			} else if (_registration == 'center_bottom') {
				view_holder.x = -Math.round(wh/2);
				view_holder.y = -wh;
			}
			
			view_do.x = Math.round(view_do.x);
			view_do.y = Math.round(view_do.y);
			
			drawBox();
		}
		
		public function get loaded():Boolean {
			return _loaded;
		}
		
		private var view_and_state_ob:Object = {};
		public function icon_animate(raw_state:Object, reposition:Boolean = false):void {
			if (disposed) return;
			setSSState(raw_state);
			if (_ss) {
				var state:Object;
				var config:Object;
				
				if (ss_state is ItemstackState) {
					state = ItemstackState(ss_state).value;
					config = ItemstackState(ss_state).config_for_swf;
					
					// this is a serious hack, because the masks in the turn animation for street spirits screw up measuring, so let's use another animation when in an iiv
					// also: street_spirit is being deprecated in favor of street_spirit_*, but we're in transition at the time of writing
					if ((tsid == 'street_spirit' || tsid == 'street_spirit_groddle') && ss_state.value == 'turn') {
						state = 'idle_hold';
					}
				} else {
					state = ss_state.state;
					if (ss_state.config is FurnitureConfig) {
						config = FurnitureConfig(ss_state.config).config;
					} else {
						config = ss_state.config;
					}
				}
				
				var item:Item = model.worldModel.getItemByTsid(tsid);
				var swf_data:SWFData = ItemSSManager.getSWFDataByUrl(swf_url);
				
				if (use_mc) {
					
					// for now, we're only doing this when using mc, but we eventually need to do use config for sprite sheets too. UPDATE. I am pretty sure we are now :)
					if (swf_data.is_timeline_animated) {
						if (!config && item.DEFAULT_CONFIG) {
							config = item.DEFAULT_CONFIG;
						}
						if (_mc.hasOwnProperty('initializehead')) {
							_mc.initializehead(config);
						}
					}
					
					var state_str:String = (typeof state == 'object') ? '' : state as String;
					var state_args:Object = (typeof state == 'object') ? state : null;
					
					if (!swf_data.is_timeline_animated && !swf_data.is_trant) {
						
						var scene:Scene = MCUtil.getSceneByName(_mc, state_str);
						if (scene) { // we have that scene in the mc
							CONFIG::debugging {
								Console.log(111, _ss.name+' matched scene state:'+state_str);
							}
							MCUtil.playScene(_mc, state_str);
							
						} else if (String(parseInt(state_str)) == state_str) { // we don't have that numbered scene; try and use highest_count_scene_name
							; // satisfy compiler
							CONFIG::debugging {
								Console.log(111, _ss.name+' using swf_data.highest_count_scene_name:'+swf_data.highest_count_scene_name+' instead of state:'+state_str);
							}
							MCUtil.playScene(_mc, swf_data.highest_count_scene_name);
							
						} else { // use default_scene_name
							
							if (MCUtil.getSceneByName(_mc, ItemSSManager.DEFAULT_SCENE_NAME)) {
								CONFIG::debugging {
									Console.log(111, _ss.name+' using default_scene_name:'+ItemSSManager.DEFAULT_SCENE_NAME+' instead of state:'+state_str);
								}
								MCUtil.playScene(_mc, ItemSSManager.DEFAULT_SCENE_NAME);
								
							} else {
								; // satisfy compiler
								CONFIG::debugging {
									Console.warn('no scene for default_scene_name???');
								}
							}
						}
						
					} else if (swf_data.is_timeline_animated) {
						// TODO - see ItemSSManager.playSSViewForItem and recordState for the relevant code
						ItemSSManager.getViewAndState(state_str, view_and_state_ob);
						var play_anim_str:String = view_and_state_ob.play_anim_str;
						var view_str:String = view_and_state_ob.view_str;
						
						if (_mc.animations.indexOf(play_anim_str) == -1) {
							; // satisfy compiler
							CONFIG::debugging {
								Console.log(111, _mc.animations.join(', ')+' does not contain '+play_anim_str);
							}
						} else {
							if (view_str) {
								CONFIG::debugging {
									Console.log(111, 'calling mc.setOrientation("'+view_str+'")')
								}
								_mc.setOrientation(view_str);
							}
							
							_mc.playAnimation(play_anim_str);
						}
						
					} else if (swf_data.is_trant) {
						if (!state_args) state_args = item.DEFAULT_STATE;
						state_args.seed = ItemSSManager.getSeedForItemSWFByUrl(swf_url, item);
						_mc.setState(state_args);
					}
				} else {
					// get from pool
					var anim_cmd:SSAnimationCommand = EnginePools.SSAnimationCommandPool.borrowObject();
					anim_cmd.state_ob = state;
					anim_cmd.config = config;
					anim_cmd.scale = 1;
					ItemSSManager.playSSViewForItemSWFByUrl(swf_url, item, _ss_view, 1, anim_cmd, (dont_animate) ? ss_view.gotoAndStop : null, wh, scale_to_stage);
					// return to pool
					EnginePools.SSAnimationCommandPool.returnObject(anim_cmd);
				}
				
				//if (ss_view && dont_animate) ss_view.stop();
			}
			if (reposition) placeViewDo()
		}
		
		override public function dispose():void {
			if (_mc && use_mc && tsid) {
				// add the loaded item swf to the pool so it can be reused
				var swf_data:SWFData = ItemSSManager.getSWFDataByUrl(swf_url);
				if (swf_data) {
					swf_data.addReusableMC(_mc);
					
					// we must remove it from the display list else super.dispose() fucks it up, and we want to reuse it
					if (_mc.parent) _mc.parent.removeChild(_mc);
				}
			}
			
			if (_ss_view) { 
				var item:Item = model.worldModel.getItemByTsid(tsid);
				ItemSSManager.removeSSViewforItemSWFByUrl(swf_url, item, _ss_view);
			}
			view_and_state_ob = null;
			_ss_view = null;
			_mc = null;
			_ss = null;
			
			super.dispose();
		}

		public function get ss():SSAbstractSheet {
			return _ss;
		}

		
	}
}