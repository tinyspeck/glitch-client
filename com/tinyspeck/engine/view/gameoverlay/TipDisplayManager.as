package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.getTimer;
		
	public class TipDisplayManager extends Sprite {
		
		/* singleton boilerplate */
		public static const instance:TipDisplayManager = new TipDisplayManager();
		
		//defaults
		private var BG_COLOR:uint = 0xf8f6b4;
		private var BG_ALPHA:Number = 1;
		private var MAX_WIDTH:int = 300;
		private var TEXT_PADDING:int = 10;
		private var POINTER_WIDTH:int = 14;
		
		private var tf:TextField = new TextField();
		
		private var shadow:DropShadowFilter = new DropShadowFilter();
		
		private var tip_css:Object;
		private var _triggersA:Array = [];
		private var _current_tip_target:DisplayObject;
		private var global_pt:Point = new Point();
		private var container_pt:Point = new Point();
		
		private var container:Sprite = new Sprite();
		private var pointer:Sprite = new Sprite();
		
		public var paused:Boolean = false;
		
		public function TipDisplayManager():void {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			addChild(container);
			container.addChild(pointer);
			
			// we lost this addMouseMoveHandler in a refactor on 2011/01/31 when removing model dependancies from this class. I think maybe it is not needed because
			// _mouseMoveHandler is also called in onGameLoop; if we find it is needed, we should remove model dependancies from StageBeacon
			// well fuck; turns out this works fine for client, but not other apps liek Vanity, which need the moueMove thing
			//StageBeacon.instance.addMouseMoveHandler(_mouseMoveHandler, this);
			
			StageBeacon.mouse_move_sig.add(_mouseMoveHandler);
						
			mouseChildren = false;
			mouseEnabled = false;
			
			//pointer
			container.addChild(pointer);
			
			//css stuff
			tip_css = CSSManager.instance.styleSheet.getStyle('.tip_bg');
			if(tip_css.color) BG_COLOR = StringUtil.cssHexToUint(tip_css.color);
			if(tip_css.alpha) BG_ALPHA = tip_css.alpha
			if(tip_css.maxWidth) MAX_WIDTH = tip_css.maxWidth;
			if(tip_css.padding) TEXT_PADDING = tip_css.padding;
			if(tip_css.pointerWidth) POINTER_WIDTH = tip_css.pointerWidth;
			
			//setup the tf
			tf.multiline = true;
			tf.wordWrap = false;
			tf.embedFonts = true;
			tf.antiAliasType = AntiAliasType.ADVANCED;
			tf.styleSheet = CSSManager.instance.styleSheet;
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.x = TEXT_PADDING;
			tf.y = TEXT_PADDING - 2; // <3 flash textfields
			container.addChild(tf);
			
			//check the alpha prop
			var tf_alpha:String = CSSManager.instance.styleSheet.getStyle('.tip_default').alpha;
			if(tf_alpha) tf.alpha = Number(tf_alpha);
			
			//shadows
			shadow.angle = 90;
			shadow.alpha = .5;
			shadow.color = 0x000000;
			shadow.distance = 2;
			shadow.blurX = 0;
			shadow.blurY = 0;
			
			container.filters = [shadow];
			visible = false;
		}
		
		public function onEnterFrame(ms_elapsed:int):void {
			if (!_current_tip_target) return;
			_mouseMoveHandler();
		}
		
		public function registerTipTrigger(tip_target:DisplayObject):void {
			if (!tip_target) return;
			if (_triggersA.indexOf(tip_target) == -1) {
				_triggersA.push(tip_target);
				DisplayObject(tip_target).addEventListener(MouseEvent.MOUSE_OVER, _overHandler);
			}
		}
		
		public function unRegisterTipTrigger(tip_target:DisplayObject):void {
			if (!tip_target) return;
			var i:int = _triggersA.indexOf(tip_target);
			if (i > -1) {
				_triggersA.splice(i, 1);
			}
			
			if (_current_tip_target == tip_target) {
				_stop();
			}
			
			DisplayObject(tip_target).removeEventListener(MouseEvent.MOUSE_OVER, _overHandler);
		}
		
		public function isTipTriggerRegistered(tip_target:DisplayObject):Boolean {
			return (_triggersA.indexOf(tip_target) == -1) ? false : true;
		}
		
		private var rect:Rectangle;
		private var mouse_xy:Point = new Point;
		private function _mouseMoveHandler(e:MouseEvent = null):void {
			if (!_current_tip_target) return;
			if (!stage) return;
			
			mouse_xy.x = stage.mouseX;
			mouse_xy.y = stage.mouseY;
			//This will generate many rects. Better just precalc the rect where we can.
			rect = DisplayObject(_current_tip_target).getBounds(stage);
			
			/*var cos:Array = [[rect.x, rect.y], [rect.right, rect.y], [rect.right, rect.bottom], [rect.left, rect.bottom], [rect.x, rect.y]];
			drawpolyHandler({
				coords: cos,
				size: 4,
				color: 'ffffff',
				clear: true
			});*/
			
			if (!rect.containsPoint(mouse_xy)) {
				_stop();
			} else {
				_draw();
				_place();
			}
			
		}
		
		private function drawpolyHandler(payload:Object):void {
			var coordsA:* = payload.coords;
			var g:Graphics = graphics;
			var c:uint = (payload.color) ? ColorUtil.colorStrToNum(payload.color) : 0x000000;
			var size:uint = (payload.size) ? parseInt(payload.size) : 8;
			
			if (payload.clear) {
				g.clear();
			}
			
			if (!coordsA || !coordsA.length) {
				return
			}
			
			g.lineStyle(size, c, 1);
			for (var i:int=0;i<coordsA.length; i++) {
				if (i==0) {
					g.moveTo(coordsA[int(i)][0], coordsA[int(i)][1]);
				} else {
					g.lineTo(coordsA[int(i)][0], coordsA[int(i)][1]);
				}
			}
			
			g.lineStyle(size-1, 0xfcff00, 1);
			for (i=0;i<coordsA.length; i++) {
				if (i==0) {
					g.moveTo(coordsA[int(i)][0], coordsA[int(i)][1]);
				} else {
					g.lineTo(coordsA[int(i)][0], coordsA[int(i)][1]);
				}
			}
		}
		
		public function pause():void {
			paused = true;
			goAway();
		}
		
		public function resume():void {
			paused = false;
		}
		
		public function goAway():void {
			_stop();
		}
		
		private function _stop(event:Event = null):void {
			visible = false;
			_current_tip_target = null;
		}
		
		private function _showTipForTarget(tip_target:DisplayObject):void {
			//Console.warn('_showTipForTarget');
			_current_tip_target = tip_target;
						
			if (_draw()) {
				_place();
				visible = true;
			}
		}
		
		private function _getTipProviderForTarget(tip_target:DisplayObject):ITipProvider {
			var potential_tip_provider:DisplayObject = tip_target;
			
			while (!(potential_tip_provider is ITipProvider) && potential_tip_provider.parent) {
				potential_tip_provider = potential_tip_provider.parent;
			}
			
			if (potential_tip_provider is ITipProvider) {
				return ITipProvider(potential_tip_provider);
			} else {
				//Console.error('Could not find ITipProvider from tip_target');
				return null;
			}
		}
		
		private function _overHandler(e:*):void {
			// check for StageBeacon.instance.last_mouse_move in case this is running in vanity or some place where StageBeacon.instance.init is not called
			if (StageBeacon.last_mouse_move && (getTimer() - StageBeacon.last_mouse_move) > 1000) return;
			if (paused) return;
			if (!stage) return;
			if(!e.currentTarget) return;
			_showTipForTarget(e.currentTarget);
		}
		
		protected function _draw():Boolean {
			
			//graphics.clear();
			//graphics.lineStyle(0, 0xcc0000, 0); // set alpha to 1 to see outline of the rect checked for mouseout
			
			if (_current_tip_target) {
				var tip_provider:ITipProvider = _getTipProviderForTarget(_current_tip_target);
				if (!tip_provider) return false;
				
				var tip:Object = tip_provider.getTip(_current_tip_target);
				if (!tip) {
					visible = false; //we don't want to clear the _current_tip_target because that will snap it back to the last good tip
					//_stop(); //if shit breaks throw this back
					return false;
				}
				
				drawTipToContainer(tip);
			}
			
			return true;
		}
		
		public function drawTipToContainer(tip:Object):void {
			if (!tip || paused) return;
			
			if (!visible) visible = true; 
			
			//set the text
			const vag_ok:Boolean = StringUtil.VagCanRender(tip.txt);
			tf.wordWrap = false;
			if (tip.no_embed != true && vag_ok) {
				tf.embedFonts = true;
				tf.htmlText = '<p class="tip_default">' + tip.txt + '</p>';
			} else {
				tf.embedFonts = false;
				tf.htmlText = '<p class="tip_default_no_embed">' + tip.txt + '</p>';
			}
			
			if (tf.width > MAX_WIDTH) {
				tf.width = MAX_WIDTH;
				tf.wordWrap = true;
			}
			
			//hold them in vars so we don't have to keep calling the tf
			const draw_w:int = tf.width + TEXT_PADDING*2;
			const draw_h:int = (tf.height + TEXT_PADDING*2) - 4;// -4 because flash textfields...
			
			//draw the bg
			var g:Graphics = container.graphics;
			g.clear();
			g.beginFill(tip.color || BG_COLOR, BG_ALPHA);
			g.drawRoundRect(0, 0, draw_w, draw_h, 8);
			
			//handle pointy thing
			g = pointer.graphics;
			g.clear();
			
			if(tip.pointer){
				g.beginFill(tip.color || BG_COLOR, BG_ALPHA);
				
				//special case for top left
				pointer.x = tip.pointer != WindowBorder.POINTER_LEFT_TOP ? int(draw_w/2) : 10;
				
				g.moveTo(-POINTER_WIDTH/2, 0);
				if(tip.pointer == WindowBorder.POINTER_TOP_CENTER || tip.pointer == WindowBorder.POINTER_LEFT_TOP){
					g.lineTo(0, -POINTER_WIDTH/2);
					pointer.y = 0;
				}
				else if(tip.pointer == WindowBorder.POINTER_BOTTOM_CENTER){
					g.lineTo(0, POINTER_WIDTH/2);
					pointer.y = draw_h;
				}
				g.lineTo(POINTER_WIDTH/2, 0);
				g.endFill();
			}			
		}
		
		public function updatePositionFromTipCoords(tip:Object):void {
			if (!tip || paused) return;
			
			x = tip.placement.x;
			
			container.x = int(-container.width/2);
			container.y = tip.placement.y - (tip.pointer == WindowBorder.POINTER_BOTTOM_CENTER ? container.height : 0);
		}
		
		protected function _place():void {
			if (_current_tip_target) {
				var tip_provider:ITipProvider = _getTipProviderForTarget(_current_tip_target);
				if (!tip_provider) return;
				if (!stage) return;
				
				var tip:Object = tip_provider.getTip(_current_tip_target);
				if (!tip) {
					visible = false; //we don't want to clear the _current_tip_target because that will snap it back to the last good tip
					//_stop(); //if shit breaks throw this back
					return;
				}
				
				//make sure that if we leave the stage, that it stops the tooltip, otherwise the game loop keeps going
				StageBeacon.mouse_leave_sig.addOnce(_stop);
				
				x = 0; //reset position
				
				//put it on the top
				if(parent) parent.setChildIndex(this, parent.numChildren-1);
				
				if (tip.placement) { // then we've been passed a specific x,y for the tip
					//center the tooltip to whatever X/Y we were given
					/*
					if(tip.pointer == WindowBorder.POINTER_BOTTOM_CENTER || tip.pointer == WindowBorder.POINTER_TOP_CENTER){
						x = tip.placement.x;
						
						container.x = int(-container.width/2);
					}
					else {
						container.x = tip.placement.x;
					}
					*/
					updatePositionFromTipCoords(tip);
					
				} else { // place the tip smartly
					
					rect = DisplayObject(_current_tip_target).getBounds(stage);
					
					// adjust for scaled up/down vanity due to browser zoom
					if (root) {
						rect.top*= 1/root.scaleX;
						rect.bottom*= 1/root.scaleX;
						rect.left*= 1/root.scaleX;
						rect.right*= 1/root.scaleX;
					}
					
					if (tip.offset_y) {
						// if offset_y is less than zero, than assume it means place the whole tf above the target, plus the negative offset
						// otherwise place tf at offset_y
						
						if (tip.offset_y < 0 && tip.pointer != WindowBorder.POINTER_TOP_CENTER) {
							container.y = rect.y-container.height+tip.offset_y;
						} else {
							container.y = rect.y+tip.offset_y;
							if(tip.pointer == WindowBorder.POINTER_TOP_CENTER){
								container.y = rect.y + rect.height + POINTER_WIDTH/2 + tip.offset_y;
							}
						}
					} else {
						if(tip.pointer == WindowBorder.POINTER_TOP_CENTER){
							container.y = rect.y + rect.height + POINTER_WIDTH/2;
						}
						else {
							container.y = rect.y-container.height-5;
						}
					}
					
					container.y = Math.round(container.y);
					container.x = Math.round(rect.x+(rect.width/2)-(container.width/2));
					
					if (tip.offset_x) {
						container.x+= tip.offset_x
					}
				}
				
				//make sure that it's still visible on the stage
				if(container.y < 2) container.y = 2;
				
				//not too far left or right
				global_pt = container.localToGlobal(container_pt);
				if(global_pt.x < 0) {
					container.x -= global_pt.x;
					pointer.x += global_pt.x;
				}
				else if(global_pt.x + container.width > stage.stageWidth){
					container.x += stage.stageWidth - (global_pt.x + container.width);
					pointer.x -= stage.stageWidth - (global_pt.x + container.width);
				}
			}
		}
	}
}