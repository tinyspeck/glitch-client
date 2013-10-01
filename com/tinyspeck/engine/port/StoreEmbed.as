package com.tinyspeck.engine.port {
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.store.StoreBuyUI;
	import com.tinyspeck.engine.view.ui.store.StoreSellUI;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	public class StoreEmbed extends TSSpriteWithModel implements IFocusableComponent {
		
		/* singleton boilerplate */
		public static const instance:StoreEmbed = new StoreEmbed();
		
		private var _frame:Sprite = new Sprite();
		
		private var sell_ui:StoreSellUI;
		private var buy_ui:StoreBuyUI;
		private var location_renderer:LocationRenderer;
		
		private var frame_color:Number = 0x939393;
		private var frame_border_width:int = 2;
		
		private var _store_item_tsid:String;
		
		public function StoreEmbed():void {
			/*************************************************
			 * [SY] Gutted this class until 
			 * a) we need it
			 * b) I take the guts of the dialog window out
			 * so that the dialog and this class can use the
			 * same classes
			 *************************************************/
			
			
			
			
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = 420;
			_construct();
		}
		
		public function init(gameRenderer:LocationRenderer):void {
			location_renderer = gameRenderer;
			registerSelfAsFocusableComponent();
		}
		
		protected function _place():void {
			x = Math.round((model.layoutModel.loc_vp_w-width)/2);
			x = Math.max(x, 0);
			y = Math.round((model.layoutModel.loc_vp_h-height)/2);
			y = Math.max(y, 0);
			y = Math.min(y, 180);
		}
		
		override protected function _construct():void {
			super._construct();
			
			buy_ui = new StoreBuyUI(_w);
			sell_ui = new StoreSellUI('dark');
		}
		
		// since this is in location, this will be called by click handler on location
		public function clickHandler(e:MouseEvent):void {
			if (e.target is Button && Button(e.target).parent == buy_ui) {
				var bt:Button = e.target as Button;
				
				//TODO this needs to talk to buy_ui in it's show() method
				
				// kind of a hack to keep the tips from obscuring menus
				TipDisplayManager.instance.goAway();
			}
			
			StageBeacon.stage.focus = StageBeacon.stage;
		}
		
		public function end():void {
			if (parent) parent.removeChild(this);
			if (buy_ui) buy_ui.hide();
			if (sell_ui) sell_ui.hide();
		}
		
		public function startWithTsid(store_item_tsid:String):void {
			CONFIG::debugging {
				Console.warn('************* THIS IS A PLACEHOLDER, ALERT AN AS3 DEV THAT YOU NEED THIS *****************');
				BootError.handleError('Embedded stores are not hooked up!', new Error('Embedded store error'));
			}
			
			_store_item_tsid = store_item_tsid;
			end();
			
			const store_ob:Object = model.worldModel.getItemstackByTsid(_store_item_tsid).store_ob;
			
			if (!store_ob) {
				CONFIG::debugging {
					Console.warn('no store_ob');
				}
				return;
			}
			
			if (!store_ob.location_rect) {
				CONFIG::debugging {
					Console.warn('no store_ob,location_rect');
				}
				return;
			}
			
			_w = int(store_ob.location_rect.w)+(frame_border_width*2);
			_h = int(store_ob.location_rect.h)+(frame_border_width*2);
			x = store_ob.location_rect.x;
			y = store_ob.location_rect.y;
			
			var g:Graphics = _frame.graphics;
			g.lineStyle(0, frame_color, 0);
			g.beginFill(frame_color);
			g.drawRect(0, 0, _w, _h);
			g.endFill();
			
			if (!location_renderer) {
				CONFIG::debugging {
					Console.warn('no _renderer');
				}
				return;
			}
			
			location_renderer.locationView.middleGroundRenderer.addStoreEmbed(this);
			
			//_store_shelving.build(_h, _w, _store_item_tsid);
			//_scroller.wh = {w:_w-(_frame_border*2),h:_h-(_frame_border*2)};
			
			sell_ui.setSize(store_ob.location_rect.w, store_ob.location_rect.h);
		}
		
		public function checkItemPrice(itemstack:Itemstack):void {
			if(sell_ui) sell_ui.checkItemPrice(itemstack);
		}
		
		/**********************************
		 * IFocusableComponent stuff
		 *********************************/
		
		public function hasFocus():Boolean {
			return false;
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			
		}
		
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return false;
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur');
			}
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
		}
	}
}