package com.tinyspeck.engine.view.geo
{
	import com.tinyspeck.core.memory.IDisposable;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.AbstractPositionableLocationEntity;
	import com.tinyspeck.engine.data.location.Door;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.geom.GeomUtil;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.renderer.DecoAssetManager;
	import com.tinyspeck.engine.view.renderer.DecoRenderer;
	import com.tinyspeck.engine.view.renderer.IAbstractDecoRenderer;
	import com.tinyspeck.engine.view.ui.DoorIcon;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	public class DoorView extends TSSpriteWithModel implements IDisposable, IAbstractDecoRenderer{
		public const deco_holder:Sprite = new Sprite();
		
		private var _door:Door;
		private var _loc_tsid:String;
		
		private const _undeco:Sprite = new Sprite();
		
		private var _deco_renderer:DecoRenderer;
		private var _decoAsset:MovieClip;
		private var _item_door_asset:MovieClip;
		
		public function DoorView(door:Door, loc_tsid:String):void {
			super(door.tsid);
			this._door = door;
			this._loc_tsid = loc_tsid;
			cacheAsBitmap = true;
			deco_holder.name = 'deco_holder';
			deco_holder.mouseEnabled = false;
			deco_holder.mouseChildren = false;
		}
		
		override public function get disambugate_sort_on():int {
			return 90;
		}
		
		private function hideSign():void {
			if (_decoAsset && _decoAsset.hasOwnProperty('sign')) _decoAsset.sign.visible = false;
		}
		
		private function showSign():void {
			if (_decoAsset && _decoAsset.hasOwnProperty('sign')) _decoAsset.sign.visible = true;
		}
		
		private function hideLock():void {
			if (_decoAsset && _decoAsset.hasOwnProperty('hideLock')) _decoAsset.hideLock();
		}
		
		private function showLock(key_id:int):void {
			CONFIG::debugging {
				if (!_decoAsset) {
					Console.warn(_door.deco.sprite_class+' locked doorView has no asset')
				} else if (!_decoAsset.hasOwnProperty('showLock')) {
					Console.warn(_door.deco.sprite_class+' locked doorView has asset with no showLock() method')
				} else {
					Console.info(_door.deco.sprite_class+' locked doorView called showLock()')
				}
			}
			if (_decoAsset && _decoAsset.hasOwnProperty('showLock')) _decoAsset.showLock(key_id);
		}
		
		public function relock():void {
			CONFIG::debugging {
				if (!_decoAsset) {
					Console.warn(_door.deco.sprite_class+' locked doorView has no asset')
				} else if (!_decoAsset.hasOwnProperty('relock')) {
					Console.warn(_door.deco.sprite_class+' locked doorView has asset with no relock() method')
				} else {
					Console.info(_door.deco.sprite_class+' locked doorView called relock()')
				}
			}
			if (_decoAsset && _decoAsset.hasOwnProperty('relock')) _decoAsset.relock();
		}
		
		public function unlock():Boolean {
			if (_door.is_locked && _decoAsset && _decoAsset.hasOwnProperty('unlock')) {
				_decoAsset.unlock();
				return true;
			}
			return false;
		}
		
		private function showNumber(house_number:String):void {
			CONFIG::debugging const str:String = 'house_number:' + house_number + ' decoAsset:'+_decoAsset;
			if (_decoAsset && _decoAsset.showNumber && _decoAsset.loaderInfo) {
				CONFIG::debugging {
					Console.log(451, 'setting # for '+str);
				}
				_decoAsset.showNumber(house_number);
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.log(451, 'NOT setting # for '+str);
				}
			}
		}
		
		override public function get interaction_target():DisplayObject {
			if (_door.itemstack_tsid && _item_door_asset) return _item_door_asset;
			
			if (_decoAsset && _decoAsset.interaction_target) return DisplayObject(_decoAsset.interaction_target);
			
			return DisplayObject(this);
		}
		
		override public function glow():void {
			if (!_glowing) {
				_glowing = true;
				if (_item_door_asset && _door.client::hide_unless_highlighting) {
					_item_door_asset.alpha = 1;
					
					//update the door icon if we have one
					const icon_point:MovieClip = _item_door_asset.getChildByName('icon_point') as MovieClip;
					if(icon_point && icon_point.numChildren){
						const door_icon:DoorIcon = icon_point.getChildAt(0) as DoorIcon;
						if(door_icon) door_icon.show();
					}
					else {
						//check if any of the children are a door icon, and if so, update it
						const total:int = _item_door_asset.numChildren;
						var i:int;
						var child:DisplayObject;
						for(i; i < total; i++){
							child = _item_door_asset.getChildAt(i);
							if(child is DoorIcon){
								//update
								(child as DoorIcon).show();
							}
						}
					}
				}
				interaction_target.filters = StaticFilters.tsSprite_GlowA;
				
			}
		}
		
		override public function unglow(force:Boolean=false):void {
			if (_glowing) {
				_glowing = false;
				if (_item_door_asset && _door.client::hide_unless_highlighting) {
					_item_door_asset.alpha = (EnvironmentUtil.getUrlArgValue('SWF_always_door_icon') == '1') ? 1 : 0;
				}
				interaction_target.filters = null;
			}
		}
		
		// called when added to stage
		override protected function _draw():void {
			if (_door.deco) {
				_decoAsset = DecoAssetManager.getInstance(_door.deco);
				if (_decoAsset) {
					// we're all good
				} else if (DecoAssetManager.loadIndividualDeco(_door.deco.sprite_class, onDecoAssetLoad)) {
					// we're loading the asset now!
					return;
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('Deco '+_door.deco.sprite_class+' not found');
					}
				}
			}
			render();
		}
		
		private function onDecoAssetLoad(mc:MovieClip, class_name:String, swfWidth:Number, swfHeight:Number):void {
			_decoAsset = mc;
			render();
			TSFrontController.instance.resnapMiniMap();
		}
		
		public function adjustForSnapping():void {
			deco_holder.alpha = 1;
			_undeco.alpha = 1;
		}
		
		public function unAdjustForSnapping():void {
			render();
		}
		
		public function loadModel():void {
			render();
		}
		
		private function render():void {
			if (disposed) {
				CONFIG::debugging {
					Console.error('Why getting rendered after being disposed? After disposal we should not be doing anything with this.');
				}
				return;
			}
			
			// in case it is a rerender
			deco_holder.alpha = 1;
			_undeco.alpha = 1;
			
			if (_door && _door.connect && _door.connect.hidden) {
				if (CONFIG::god) {
					deco_holder.alpha = .2;
					_undeco.alpha = .2;
				} else {
					// this keeps it hidden
					if (deco_holder.parent) deco_holder.parent.removeChild(deco_holder);
					if (_undeco.parent) _undeco.parent.removeChild(_undeco);
					return;
				}
			}
			
			if (_door.deco && _decoAsset) {
				_deco_renderer = new DecoRenderer();
				_deco_renderer.init(_door.deco, _decoAsset);
				deco_holder.addChild(_deco_renderer);
				addChild(deco_holder);
				
				if (_door.for_sale) {
					showSign();
				} else {
					hideSign();
				}
				
				if (_door.house_number) {
					showNumber(_door.house_number);
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.log(451, 'no house_number for door '+_door.tsid);
					}
				}
				
				if (_door.is_locked && _door.key_id) {
					showLock(_door.key_id);
				} else {
					hideLock();
				}
			} else if (_door.itemstack_tsid && _item_door_asset) {
				if (_decoAsset && _decoAsset.parent) _decoAsset.parent.removeChild(_decoAsset);
				if (_undeco.parent) _undeco.parent.removeChild(_undeco);
				addChild(deco_holder);
				deco_holder.addChild(_item_door_asset);
			} else {
				addChild(_undeco);
			}
			
			if (_door.connect && _door.connect.street_tsid != _loc_tsid) {
				TipDisplayManager.instance.registerTipTrigger(this.interaction_target);
			} else if (CONFIG::god) {
				TipDisplayManager.instance.registerTipTrigger(this.interaction_target);
			}
			
			syncRendererWithModel();
		}
		
		public function addItemDoor(mc:MovieClip):void {
			if (_item_door_asset && _item_door_asset.parent) {
				_item_door_asset.parent.removeChild(_item_door_asset);
			}
			_item_door_asset = mc;
		}
		
		override public function dispose():void {
			cacheAsBitmap = false;
			if (_deco_renderer) _deco_renderer.dispose();
			_deco_renderer = null;
			_decoAsset = null;
			TipDisplayManager.instance.unRegisterTipTrigger(this.interaction_target);
			super.dispose();
		}

		/** from IDecoRendererContainer */
		CONFIG::locodeco private var _highlight:Boolean;
		CONFIG::locodeco public function get highlight():Boolean { return _highlight; }
		CONFIG::locodeco public function set highlight(value:Boolean):void { _highlight = value; }
		
		/** from IDecoRendererContainer */
		public function syncRendererWithModel():void {
			x = _door.x;
			y = _door.y;
			rotation = _door.r;
			
			if (_door.deco && _decoAsset) {
				_door.deco.w = _door.w;
				_door.deco.h = _door.h;
				_door.deco.h_flip = _door.h_flip;
				_deco_renderer.syncRendererWithModel();
			} else if (_door.itemstack_tsid) {
				if (_item_door_asset) {
					if (_door.client::hide_unless_highlighting) {
						// positioned in fancyDoor
						_item_door_asset.alpha = (glowing || EnvironmentUtil.getUrlArgValue('SWF_always_door_icon') == '1') ? 1 : 0;
					}
					
					const bounds:Rectangle = GeomUtil.roundRectValues(_item_door_asset.getBounds(_item_door_asset));
					if (_door.h_flip) {
						_item_door_asset.scaleX = -1 * Math.abs(_item_door_asset.scaleX);
						_item_door_asset.x = bounds.x+(Math.round(_door.w/2));
					} else {
						_item_door_asset.scaleX = 1 * Math.abs(_item_door_asset.scaleX);
						_item_door_asset.x = -bounds.x-(Math.round(_door.w/2));
					}
					_item_door_asset.y = -bounds.y-(_door.h);
				}
				
				deco_holder.graphics.clear();
				deco_holder.graphics.beginFill(0x00ff00, EnvironmentUtil.getUrlArgValue('SWF_show_door_asset_size') == '1' ? .5 : 0);
				deco_holder.graphics.drawRect(-((_door.w+0)/2), -_door.h, _door.w+0, _door.h);
				
			} else {
				_undeco.graphics.clear();
				_undeco.graphics.beginFill(0x000000, .5);
				_undeco.graphics.drawRect(-(_door.w/2), -_door.h, _door.w, _door.h);
			}
			
		}
		
		/** from IDecoRendererContainer */
		public function getModel():AbstractPositionableLocationEntity {
			return _door;
		}
		
		/** from IDecoRendererContainer */
		public function getRenderer():DisplayObject {
			return this;
		}

		public function get door():Door {
			return _door;
		}

		public function set door(value:Door):void {
			_door = value;
		}

		public function get decoAsset():MovieClip { 
			return _decoAsset;
		}

		public function get item_door_asset():MovieClip {
			return _item_door_asset;
		}

		public function get loc_tsid():String {
			return _loc_tsid;
		}

		public function get deco_renderer():DecoRenderer {
			return _deco_renderer;
		}
	}
}
