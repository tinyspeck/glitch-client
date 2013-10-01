package com.tinyspeck.engine.admin.locodeco {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.LoadingLocationView;
	import com.tinyspeck.engine.view.gameoverlay.maps.MiniMapView;
	import com.tinyspeck.engine.view.renderer.DecoAssetManager;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Dialog;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.TSScroller;
	import com.tinyspeck.engine.view.ui.TSSlider;
	
	import de.polygonal.core.ObjectPool;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	
	import locodeco.LocoDecoGlobals;
	
	public class DecoSelectorDialog extends Dialog {
		
		/* singleton boilerplate */
		public static const instance:DecoSelectorDialog = new DecoSelectorDialog();
		
		public  static const CATEGORY_ALL:String        = 'ALL';
		public  static const CATEGORY_ANIMS:String      = 'ANIMS';
		public  static const CATEGORY_DOORS:String      = 'DOORS';
		public  static const CATEGORY_SIGNS:String      = 'SIGNS';
		public  static const CATEGORY_LADDERS:String    = 'LADDERS';
		private static const SEPARATOR:String           = '---------------';
		private static const REGEX_DOORS:RegExp         = /(^door_asset_)/;
		private static const REGEX_SIGNS:RegExp         = /(^signpost_asset_)/;
		private static const REGEX_LADDERS:RegExp       = /(^ladder_tile_(center_\d\d_|cap_\d_))/;
		private static const REGEX_LADDER_CENTER:RegExp = /(^ladder_tile_center_\d\d_)/;
		
		private static var DecoHolderPool:ObjectPool;
		
		public var category:String = CATEGORY_ALL;
		
		private const _catScroller:TSScroller = new TSScroller({
			name: 'catScroller',
			bar_wh: 12,
			body_color: 0xFFFFFF,
			body_alpha: 0.1,
			bar_color: 0xFFFFFF,
			bar_alpha: 0.5,
			bar_handle_color: 0x666666,
			bar_handle_min_h: 50,
			scrolltrack_always: true
		});
		private const _decoScroller:TSScroller = new TSScroller({
			name: 'decoScroller',
			bar_wh: 16,
			body_color: 0xFFFFFF,
			body_alpha: 0.1,
			bar_color: 0xFFFFFF,
			bar_alpha: 0.5,
			bar_handle_color: 0x666666,
			bar_handle_min_h: 50,
			use_refresh_timer: false,
			use_children_for_body_h: true,
			scrolltrack_always: true
		});
		private const _categoriesTF:TextField = new TSLinkedTextField();
		private const _statusTF:TextField = new TextField();
		
		private var _location:Location;
		private var _scaleSlider:TSSlider;
		private var _bgColorSlider:TSSlider;
		private var _downCallback:Function;
		private var _upCallback:Function;
		
		/**
		 * Hack for d+clicking a deco, the first d+up heard will be after the
		 * initial d+click to open the dialog; subsequent d presses close it.
		 */ 
		private var _skipFirstDKeyUp:Boolean;
		
		/** A list of DecoHolders that are available for this SWF */
		private const _decos:Vector.<DecoHolder> = new Vector.<DecoHolder>();
		
		/** A strict subset of _decos that are currently in view */
		private const _filteredDecos:Vector.<DecoHolder> = new Vector.<DecoHolder>();
		
		/**
		 * Contains a list of the deco classnames we're waiting on;
		 * it's a hash just so lookup is fast.
		 */
		private var _decosToLoad:Object = {};
		private var _decosLoaded:uint = 0;
		private var _totalDecosToLoad:uint = 0;
		
		
		public function DecoSelectorDialog() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			DecoHolderPool = new ObjectPool(true);
			DecoHolderPool.allocate(DecoHolder, 1500, 500, DecoHolder.reset);
			
			_close_bt_padd_right = 8;
			_close_bt_padd_top = 8;
			_base_padd = 20;
			_w = 330;
			_h = 300;
			bg_c = LocoDecoGlobals.instance.decoSelectorColor;
			bg_c = bg_c<<16 | bg_c<<8 | bg_c;
			bg_alpha = .9;
			no_border = true;
			close_on_editing = false;
			_border_w = 0;
			_construct();
		}
		
		override protected function _construct() : void {
			super._construct();
			
			window_border.corner_rad = 10;
			
			addChild(_catScroller);
			addChild(_decoScroller);
			
			TFUtil.prepTF(_categoriesTF);
			_categoriesTF.wordWrap = false;
			_categoriesTF.addEventListener(TextEvent.LINK, filter);
			_catScroller.body.addChild(_categoriesTF);
			
			TFUtil.prepTF(_statusTF);
			addChild(_statusTF);
			
			_scaleSlider = new TSSlider(TSSlider.HORIZONTAL, this);
			_scaleSlider.backClick = true;
			_scaleSlider.setSliderParams(20, 300, LocoDecoGlobals.instance.decoSelectorZoom);
			_scaleSlider.value = LocoDecoGlobals.instance.decoSelectorZoom;
			_scaleSlider.addEventListener(Event.CHANGE, onSliderChange, false, 0, true);
			
			_bgColorSlider = new TSSlider(TSSlider.HORIZONTAL, this);
			_bgColorSlider.fillLevelColorFrom = 0x000000
			_bgColorSlider.fillLevelColorTo = 0xFFFFFF
			_bgColorSlider.backClick = true;
			_bgColorSlider.setSliderParams(0, 255, LocoDecoGlobals.instance.decoSelectorColor);
			_bgColorSlider.value = LocoDecoGlobals.instance.decoSelectorColor;
			_bgColorSlider.addEventListener(Event.CHANGE, onBGColorSliderChange, false, 0, true);
		}
		
		override protected function makeCloseBt():Button {
			return new Button({
				graphic: new AssetManager.instance.assets['close_x_small_gray'](),
				name: '_close_bt',
				c: bg_c,
				high_c: bg_c,
				disabled_c: bg_c,
				shad_c: bg_c,
				inner_shad_c: 0xcccccc,
				h: 20,
				w: 20,
				disabled_graphic_alpha: .3,
				focus_shadow_distance: 1
			});
		}
		
		/**
		 * @category will open the deco selector to a given category, default; ALL.
		 * @downSelectionCallback will get called when the mouse presses down on a deco
		 * @upSelectionCallback will get called when the mouse releases over a deco
		 * 
		 * The callback function prototype should be:
		 *    function (className:String, w:uint, h:uint, e:MouseEvent):void 
		 */
		public function startWithOptions(category:String = CATEGORY_ALL, downSelectionCallback:Function = null, upSelectionCallback:Function = null):void {
			if (this.category != category) {
				this.category = category;
				filter();
			}
			_downCallback = downSelectionCallback;
			_upCallback = upSelectionCallback;
			start();
		}
		
		override public function start():void {
			if(!canStart(true)) return;
			
			// load decos on demand and when location swf changes
			if (_location != model.worldModel.location) {
				loadDecosForLocation(model.worldModel.location);
				return;
			}

			// invalidate(true) is implied by super.start();
			super.start();
			
			// if D is still pressed while we're starting, skip the keyUp
			// so we don't prematurely dismiss ourselves
			if (KeyBeacon.instance.pressed(Keyboard.D)) _skipFirstDKeyUp = true;
			
			_w = model.layoutModel.loc_vp_w;
			_h = model.layoutModel.loc_vp_h;
			x = _w/2;
			y = _h/2;
			
			transitioning = true;
			scaleX = scaleY = .02;
			const self:DecoSelectorDialog = this;
			TSTweener.removeTweens(self);
			TSTweener.addTween(self, {y:dest_y, x:dest_x, scaleX:1, scaleY:1, time:.2, transition:'easeInCubic', onComplete:function():void{
				self.transitioning = false;
				self._place();
				MiniMapView.instance.hide();
			}});
			
			refresh();
		}
		
		override public function end(release:Boolean):void {
			if (!transitioning) {
				transitioning = true;
				const self:DecoSelectorDialog = this;
				const superEnd:Function = super.end;
				TSTweener.removeTweens(self);
				TSTweener.addTween(self, {y:y+_h/2, x:x+_w/2, scaleX:.02, scaleY:.02, time:.2, transition:'easeOutCubic', onComplete:function():void{
					superEnd(release);
					self.scaleX = self.scaleY = 1;
					self.transitioning = false;
					MiniMapView.instance.show();
				}});
			}
		}
		
		override protected function _place():void {
	        if (parent) {
				// keep it in bounds of the viewport
				dest_x = model.layoutModel.gutter_w;
				dest_y = model.layoutModel.header_h;
				
				if (!transitioning) {
					x = dest_x;
					y = dest_y;
				}
			}
		}
		
		override public function refresh():void {
			super.refresh();
			//                                         [X]
			// |--------------------------| |------------|
			// |                          | | categories |
			// |       deco scroller      | |            |
			// |                          | |            |
			// |--------------------------| |------------|
			// status        [====slider==]
			
			_w = model.layoutModel.loc_vp_w;
			_h = model.layoutModel.loc_vp_h;
			
			_catScroller.x = _w - _categoriesTF.textWidth - _close_bt_padd_right - _catScroller.bar.width;
			_catScroller.y = _close_bt.y + _close_bt.height + 5;
			_catScroller.w = _w - _catScroller.x;
			_catScroller.h = _h - _close_bt.height - 5*_close_bt_padd_top;
			
			_decoScroller.x = _close_bt_padd_right;
			_decoScroller.y = _catScroller.y;
			_decoScroller.w = _catScroller.x - _close_bt_padd_right;
			_decoScroller.h = _h - _close_bt.height - 5*_close_bt_padd_top;
			
			_statusTF.x = _close_bt_padd_right;
			_statusTF.y = _h - _statusTF.textHeight - _close_bt_padd_top;
			_statusTF.width = _w - 2*_close_bt_padd_right;
			
			_scaleSlider.x = _decoScroller.x + _decoScroller.w - _scaleSlider.width;
			_scaleSlider.y = _h - _scaleSlider.height - _close_bt_padd_top;
			
			_bgColorSlider.x = _scaleSlider.x - _bgColorSlider.width - _close_bt_padd_right;
			_bgColorSlider.y = _scaleSlider.y;
			
			layoutDecos();
		}
		
		/** @private */
		public function onDecoHolderMouseDown(dh:DecoHolder, e:MouseEvent):void {
			if (_downCallback != null) _downCallback.call(null, dh.className, dh.w, dh.h, e);
		}
		
		/** @private */
		public function onDecoHolderMouseUp(dh:DecoHolder, e:MouseEvent):void {
			if (_upCallback != null) _upCallback.call(null, dh.className, dh.w, dh.h, e);
		}
		
		override protected function startListeningToNavKeys():void {
			super.startListeningToNavKeys();
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_UP_+Keyboard.D, dKeyUpHandler);
		}
		
		override protected function stopListeningToNavKeys():void {
			super.stopListeningToNavKeys();
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_UP_+Keyboard.D, dKeyUpHandler);
		}
		
		private function onSliderChange(event:Event):void {
			const value:Number = Number((event.currentTarget as TSSlider).value.toFixed(2));
			LocoDecoGlobals.instance.decoSelectorZoom = value;
			refresh();
		}
		
		private function onBGColorSliderChange(event:Event):void {
			const value:uint = uint((event.currentTarget as TSSlider).value);
			LocoDecoGlobals.instance.decoSelectorColor = value;
			window_border.bg_c = value<<16 | value<<8 | value;
		}
		
		private function loadDecosForLocation(location:Location):void {
			_location = location;
			
			// clear out old deco holders
			clearFilter();
			for each (var dh:DecoHolder in _decos) {
				// leave them on the DisplayList, but mark them as being unused
				DecoHolderPool.returnObject(dh);
			}
			_decos.length = 0;
			_decosLoaded = 0;
			_decosToLoad = {};
			_totalDecosToLoad = 0;
			
			// prepare the filterable categories
			var cat:String;
			var cats:Array = [];
			const groups:Vector.<String> = DecoAssetManager.getActiveGroups();
			for each (cat in groups) {
				// animated is special
				if (cat != 'animated') { 
					cats.push(cat);
				}
			}
			cats.sort(Array.CASEINSENSITIVE);
			cats.unshift(SEPARATOR);
			cats.unshift(CATEGORY_LADDERS);
			cats.unshift(CATEGORY_SIGNS);
			cats.unshift(CATEGORY_DOORS);
			cats.unshift(CATEGORY_ANIMS);
			cats.unshift(CATEGORY_ALL);
			
			// display them
			var str:String = '<span class="locodeco_decoselector">';
			for each (cat in cats) {
				if (cat == SEPARATOR) {
					str += SEPARATOR + '<br/>';
				} else {
					str += '[ <a href="event:' + cat + '">' + cat + '</a> ]<br/>';
				}
			}
			str += '</span>';
			_categoriesTF.htmlText = str;
			
			// iterate over all the assets and add them to the scroller
			const classes:Vector.<String> = DecoAssetManager.getActiveClassNames();
			for each (var className:String in classes) {
				if (DecoAssetManager.loadIndividualDeco(className, onMCLoaded)) {
					_decosToLoad[className] = true;
					_totalDecosToLoad++;
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.error(name+' COULD NOT LOAD!')
					}
				}
			}
			
			if (_decosLoaded == _totalDecosToLoad) {
				// if there is nothing to load (impossible, I think)
				filter();
				start();
			} else {
				// otherwise get with the loading
				LoadingLocationView.instance.fadeIn();
				TSFrontController.instance.startLoadingLocationProgress('Loading ' + _totalDecosToLoad + ' decos...');
				TSFrontController.instance.updateLoadingLocationProgress(_decosLoaded/_totalDecosToLoad);
				// hide the map while we're showing the loading screen
				MiniMapView.instance.hide();
				setStatus('Loading ' + (_totalDecosToLoad - _decosLoaded) + ' decos');
			}
			
			refresh();
		}
		
		private function onMCLoaded(mc:MovieClip, className:String, swfWidth:Number, swfHeight:Number):void {
			//Console.info('Loaded: '+class_name+' '+swfWidth+'x'+swfHeight);
			// skip old loads if we're no longer waiting for them
			if (!_decosToLoad[className]) return;
			
			const dh:DecoHolder = DecoHolderPool.borrowObject();
			// if it was freshly allocated, we need to put it in the scroller;
			// if it has a parent, it's a reused DecoHolder
			if (dh.parent == null) {
				_decoScroller.body.addChild(dh);
			}
			dh.init(mc, className, swfWidth, swfHeight);
			
			_decos.push(dh);
			
			delete _decosToLoad[className];
			_decosLoaded++;
			
			setStatus('Loading ' + (_totalDecosToLoad - _decosLoaded) + ' decos');
			TSFrontController.instance.updateLoadingLocationProgress(_decosLoaded/_totalDecosToLoad);
			
			// check if we're all done and ready to start
			if (_decosLoaded == _totalDecosToLoad) {
				// prefer ladder_tile_center to ladder_tile_cap_#
				_decos.sort(function (left:DecoHolder, right:DecoHolder):int {
					if (REGEX_LADDER_CENTER.test(left.className)) {
						if (!REGEX_LADDER_CENTER.test(right.className)) return -1;
					}
					return ((left.className < right.className) ? -1 : 1);
				});
				filter();
				LoadingLocationView.instance.fadeOut();
				start();
			}
		}
		
		private function layoutDecos():void {
			const ZOOM:Number = LocoDecoGlobals.instance.decoSelectorZoom;
			
			var rowHeight:int = 0;
			var runningWidth:int = 5;
			var runningHeight:int = 0;
			for each (var dh:DecoHolder in _filteredDecos) {
				dh.sideLength = ZOOM;
				
				if ((runningWidth + dh.width + 5) <= _decoScroller.scroll_window_w) {
					// new column
					dh.x = runningWidth;
					dh.y = runningHeight;
					rowHeight = Math.max(rowHeight, dh.height);
					runningWidth += 5 + dh.width;
				} else {
					// new row
					runningWidth = 5 + dh.width + 5;
					runningHeight += rowHeight + 5;
					rowHeight = dh.height;
					dh.x = 5;
					dh.y = runningHeight;
				}
			}
			
			_decoScroller.refreshAfterBodySizeChange();
		}
		
		private function filter(e:TextEvent=null):void {
			clearFilter();
			
			if (e) category = e.text;
			
			var dh:DecoHolder;
			var isDoor:Boolean;
			var isAnim:Boolean;
			var isSign:Boolean;
			var isLadder:Boolean;
			var seenTiles:Object = {};
			var tmpName:String;
			for each (dh in _decos) {
				tmpName = dh.className;
				isAnim = DecoAssetManager.isInGroup(tmpName, 'animated');
				isDoor = REGEX_DOORS.test(tmpName);
				isSign = REGEX_SIGNS.test(tmpName);
				isLadder = REGEX_LADDERS.test(tmpName);
				switch (category) {
					case CATEGORY_ALL:
						_filteredDecos.push(dh);
						break;
					case CATEGORY_ANIMS:
						if (isAnim) _filteredDecos.push(dh);
						break;
					case CATEGORY_DOORS:
						if (isDoor) _filteredDecos.push(dh);
						break;
					case CATEGORY_SIGNS:
						if (isSign) _filteredDecos.push(dh);
						break;
					case CATEGORY_LADDERS:
						if (isLadder) {
							// cap_# and center_## prefixes are possible
							// eliminate duplicates:
							tmpName = tmpName.replace(REGEX_LADDERS, '');
							if (seenTiles.hasOwnProperty(tmpName)) continue;
							seenTiles[tmpName] = null;
							_filteredDecos.push(dh);
						}
						break;
					case SEPARATOR:
						break;
					default:
						// search decogroup
						if (DecoAssetManager.isInGroup(tmpName, category)) {
							_filteredDecos.push(dh);
						}
						break;
				}
			}
			
			_filteredDecos.sort(function (left:DecoHolder, right:DecoHolder):int {
				return ((left.className < right.className) ? -1 : 1);
			});
			for each (dh in _filteredDecos) dh.show();
			
			if (_decosLoaded == _totalDecosToLoad) {
				setStatus('Displaying ' + _filteredDecos.length + ' decos');
			}
			refresh();
		}
		
		private function clearFilter():void {
			category = CATEGORY_ALL;
			for each (var dh:DecoHolder in _filteredDecos) dh.hide();
			_filteredDecos.length = 0;
		}
		
		private function setStatus(htmlText:String):void {
			_statusTF.htmlText = '<span class="locodeco_decoselector">' + htmlText + '</span>';
		}
		
		private function dKeyUpHandler(e:KeyboardEvent):void {
			if (_skipFirstDKeyUp) {
				_skipFirstDKeyUp = false;
			} else if (e.keyCode == Keyboard.D) {
				end(true);
			}
		}
	}
}
