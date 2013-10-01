package com.tinyspeck.engine.view.itemstack
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.CSSManager;
	
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	
	public class ItemstackAnimation extends Sprite
	{
		private static const PACK_RELATED_TYPES:Array  = [Announcement.PACK_TO_PACK, Announcement.PACK_TO_BAG,
														  Announcement.BAG_TO_PACK, Announcement.BAG_TO_BAG];
		private static const STATE_RELATED_TYPES:Array = [Announcement.PACK_TO_FLOOR, Announcement.FAMILIAR_TO_FLOOR,
														  Announcement.PACK_TO_PC, Announcement.FLOOR_TO_BAG]; //when "iconic" isn't used
		
		private var circle:Shape = new Shape();
		private var val_tf:TextField = new TextField();
		private var _circle_perc:Number = 0;
		private var _text_perc:Number = 0;
		private var _icon_perc:Number = 0;
		private var end_circle_size:int = 50;
		private var end_text_size:Number = 24;
		private var txt:String;
		private var glow:GlowFilter = new GlowFilter();
		private var shadow:DropShadowFilter = new DropShadowFilter();
		private var item_icon:ItemIconView;
		private var item_icon_wh:int;
		public var running:Boolean = false;
		
		private var model:TSModelLocator;
		private var itemstack_animation_zenith:int;
		
		public function ItemstackAnimation()
		{
			super();
			model = TSModelLocator.instance;
			init();
		}
		
		private function init():void {
			
			
			itemstack_animation_zenith = CSSManager.instance.getNumberValueFromStyle('offsets', 'itemstack_animation_zenith');
			
			addChild(circle);
			val_tf.selectable = false;
			val_tf.multiline = false;
			val_tf.wordWrap = false;
			val_tf.embedFonts = true;
			val_tf.antiAliasType = AntiAliasType.ADVANCED;
			val_tf.border = false;
			val_tf.styleSheet = CSSManager.instance.styleSheet;
			addChild(val_tf);
			
			glow.color = 0x000000;
			glow.alpha = .7;
			glow.blurX = 2;
			glow.blurY = 2;
			glow.strength = 9;
			glow.quality = 4;
			val_tf.filters = [glow];
			
			shadow.distance = 2;
			shadow.angle = 45;
			shadow.alpha = .8;
			shadow.blurX = 10;
			shadow.blurY = 10;
		}
		
		/*public function end():void {
			TSTweener.removeTweens(this);
			TSTweener.removeTweens(val_tf);
			done();
		}*/
		
		public function cancel():void {
			done();
		}
		
		private function done():void {
			TSTweener.removeTweens(this);
			TSTweener.removeTweens(val_tf);
			running = false;
			if (parent) parent.removeChild(this);
		}
		
		public function get text_perc():Number {
			return _text_perc;
		}
		
		public function set text_perc(perc:Number):void {
			_text_perc = perc;
			val_tf.htmlText = '<p class="itemstack_animation"><font size="'+(int(end_text_size*_text_perc))+'">'+txt+'</font></p>';
			val_tf.width = val_tf.textWidth+4;
			val_tf.height = val_tf.textHeight+4;
			val_tf.x = Math.round((item_icon_wh)*text_perc/2)+4;
			val_tf.y = -val_tf.height/2;
			val_tf.alpha = 1;
		}
		
		public function get icon_perc():Number {
			return _icon_perc;
		}
		
		public function set icon_perc(perc:Number):void {
			_icon_perc = perc;
			text_perc = perc;
			
			// make sure there is something to scale!
			if (item_icon.parent && item_icon.art_w) {
				item_icon.scaleX = item_icon.scaleY = _icon_perc;
			}
		}
		
		public function get circle_perc():Number {
			return _circle_perc;
		}
		
		public function set circle_perc(perc:Number):void {
			_circle_perc = perc;
			var g:Graphics = circle.graphics;
			g.clear();
			g.beginFill(0xffffff, .5);
			g.lineStyle(2, 0xffffff);
			g.drawCircle(0, 0, (end_circle_size/2)*_circle_perc);
		}
		
		private var annc:Announcement;
		private var dest_pt:Point;
		public function go(orig_pt:Point, dest_pt:Point, item_class:String, count:int, type:String, path:String, annc:Announcement):void {
			if (running) return;
			this.dest_pt = dest_pt;
			this.annc = annc;
			var icon_state:String = 'iconic';
			var self:ItemstackAnimation = this;
			
			item_icon_wh = (PACK_RELATED_TYPES.indexOf(type) > -1) ? model.layoutModel.pack_itemicon_wh : 80;
			
			filters = [shadow];
			running = true;
			self.alpha = 1;
			self.scaleX = 1;
			self.scaleY = 1;
			self.x = orig_pt.x;
			self.y = orig_pt.y;
			
			//Console.warn(self.x+' '+self.y);
			
			if(count > 0){
				txt = '+<span class="itemstack_animation_add">'+String(Math.abs(count))+'</span>';
			}else{
				txt = '-<span class="itemstack_animation_subtract">'+String(Math.abs(count))+'</span>';
			}
			
			if(path){
				var chunks:Array = path.split('/');
				var itemstack:Itemstack = model.worldModel.getItemstackByTsid(chunks[chunks.length-1]);
				if (itemstack) { 
					//make sure the icon is in the right state
					if(STATE_RELATED_TYPES.indexOf(type) > -1 && itemstack.itemstack_state.value != 'iconic'){
						icon_state = itemstack.itemstack_state.value || icon_state;
					}
					
					if(itemstack.tool_state && itemstack.tool_state.is_broken){
						if(model.worldModel.pc.itemstack_tsid_list[itemstack.tsid]){
							//going to player pack
							icon_state = 'broken_iconic';
						}
						else{
							//going someplace else
							icon_state = 'broken';
						}
					}
				}
			}
			

			if (!item_icon || item_icon.tsid != item_class || item_icon.wh != item_icon_wh/* || icon_state != 'iconic'*/) {
				if (item_icon) {
					if (item_icon.parent) item_icon.parent.removeChild(item_icon);
					item_icon.dispose();
				}
				item_icon = new ItemIconView(item_class, item_icon_wh, icon_state, 'center');
			} else {
				item_icon.scaleX = item_icon.scaleY = 1;
				item_icon.icon_animate(icon_state, true);
			}

			circle_perc = 0;
			text_perc = 0;
			icon_perc = 0;
			
			addChild(item_icon);
			
			val_tf.visible = true;
			var pt:Point;
			var doneFunc:Function;
			var completeFunc:Function;
			
			var float_y:int; // this is the y the icon will float at briefly mid animation
			
			if (type == Announcement.FLOOR_TO_PC || type == Announcement.PC_TO_FLOOR) {
				TSFrontController.instance.getMainView().gameRenderer.placeOverlayInSCH(self, annc.toString());

				val_tf.visible = false;
				TSTweener.addTween(self, {icon_perc:.5, y:dest_pt.y, x:dest_pt.x, time:.5, transition:'easeOutBack', onComplete:done});
				
			} else if (type == Announcement.FLOOR_TO_BAG) {
				TSFrontController.instance.getMainView().gameRenderer.placeOverlayInSCH(self, annc.toString());
				float_y = y+itemstack_animation_zenith;
				
				doneFunc = function():void {
					val_tf.visible = false;
					TSTweener.addTween(self, {icon_perc:0, y:dest_pt.y, x:dest_pt.x, time:.5, transition:'easeOutBack', onComplete:done});
				}
				
				completeFunc = function():void {
					StageBeacon.setTimeout(doneFunc, 700); // sit there all big for a while
				}
				
				TSTweener.addTween(self, {icon_perc:1, y:float_y, time:1, transition:'easeOutBack', onComplete:completeFunc});
				
			} else if (type == Announcement.FLOOR_TO_PACK || type == Announcement.PC_TO_PACK || type == Announcement.FAMILIAR_TO_PACK) {
				TSFrontController.instance.getMainView().gameRenderer.placeOverlayInSCH(self, annc.toString());

				if (type == Announcement.FAMILIAR_TO_PACK) {
					float_y = model.worldModel.pc.y-130;
				} else {
					float_y = y+itemstack_animation_zenith;
				}
				
				doneFunc = function():void {
					val_tf.visible = false;
					
					// move it to the stage
					try {
						pt = TSFrontController.instance.getMainView().gameRenderer.translateLocationCoordsToGlobal(self.x, self.y);
					} catch (e:Error) {
						BootError.handleError('Error typically here is that middleGroundRenderer is not defined WTF '+type, e, null, !CONFIG::debugging)
					}
					if (pt) {
						self.x = pt.x;
						self.y = pt.y;
						if (self.parent) self.parent.removeChild(self); // not technically nec. but sometimes without it a ghost remains
						StageBeacon.game_parent.addChild(self);
						
						TSTweener.addTween(self, {icon_perc:.5, y:dest_pt.y, x:dest_pt.x, time:.5, transition:'easeOutBack', onComplete:done});
					} else {
						done();
					}
				}
				
				completeFunc = function():void {
					StageBeacon.setTimeout(doneFunc, 700); // sit there all big for a while
				}
				
				TSTweener.addTween(self, {icon_perc:1, y:float_y, time:1, transition:'easeOutBack', onComplete:completeFunc});
				
			} else if (type == Announcement.PACK_TO_PACK || type == Announcement.PACK_TO_BAG || 
					   type == Announcement.BAG_TO_PACK || type == Announcement.BAG_TO_BAG) {
				filters = null;
				icon_perc = 1;
				if (self.parent) self.parent.removeChild(self); // not techinically nec. but sometimes without it a ghost remains
				StageBeacon.game_parent.addChild(self);
				val_tf.visible = false;
				//We should totally make time be factor of how far it has to travel
				var distance:int = Math.abs(Point.distance(new Point(self.x, self.y), dest_pt));
				var time:Number = Math.max(.3, (distance/100)*.1);
				CONFIG::debugging {
					Console.info(time+'secs '+distance+'px');
				}
				TSTweener.addTween(self, {x:dest_pt.x, y:dest_pt.y, time:time, transition:'linear', onComplete:done});
				
			} else if (type == Announcement.PACK_TO_FLOOR || type == Announcement.PACK_TO_PC || type == Announcement.FAMILIAR_TO_FLOOR) {
				StageBeacon.game_parent.addChild(self);
				if (type == Announcement.FAMILIAR_TO_FLOOR) {
					float_y = model.layoutModel.loc_vp_h-130; // this puts it just up off the bottom of the vp
				} else {
					float_y = model.layoutModel.loc_vp_h-60; // this puts it just up off the bottom of the vp
				}
				TSTweener.addTween(self, {icon_perc:1, y:float_y, time:.5, delay: 0, transition:'easeOutBack', onComplete:function():void {
					StageBeacon.setTimeout(finishInSCH, 700); // sit there all big for a while
				}});
			} else {
				CONFIG::debugging {
					Console.warn('unhandled annc type:'+type);
				}
			}
		}
		
		private function finishInSCH():void {
			val_tf.visible = false;
			// move it to the mg of the location
			var pt:Point = TSFrontController.instance.getMainView().gameRenderer.translateGlobalCoordsToLocation(x, y);
			x = pt.x;
			y = pt.y;
			if (parent) parent.removeChild(this); // not techinically nec. but sometimes without it a ghost remains
			TSFrontController.instance.getMainView().gameRenderer.placeOverlayInSCH(this, annc.toString());
			
			TSTweener.addTween(this, {icon_perc:0, y:dest_pt.y, x:dest_pt.x, time:.5, transition:'easeOutBack'});
			TSTweener.addTween(this, {alpha:0, time:.2, delay:.5, transition:'linear', onComplete:done});
		}
	}
}