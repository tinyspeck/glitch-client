package com.tinyspeck.engine.view.ui.decorate
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.HandOfDecorator;
	import com.tinyspeck.engine.data.decorate.Swatch;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.renderer.DecoAssetManager;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.Dictionary;

	public class SwatchElementUI extends Sprite implements ITipProvider
	{
		private static const WH:uint = 50;
		private static const LOCAL_PT:Point = new Point(WH/2, -2);
		
		private var current_swatch:Swatch;
		
		private var all_holder:Sprite = new Sprite();
		private var swatch_holder:Sprite = new Sprite();
		private var swatch_mask:Sprite = new Sprite();
		private var cost_holder:Sprite = new Sprite();
		
		private var credits_icon:DisplayObject;
		private var subscriber_icon:DisplayObject;
		private var new_icon:DisplayObject;
		
		private var cost_tf:TextField = new TextField();
		
		public var type:String;
		public var has_swatch:Boolean;
		
		private var mouse_move_start_pt:Point = new Point();
		private var tip_pt:Point = new Point();
		private var drag_happened:Boolean;
		private var swatch_mcs:Dictionary = new Dictionary();
		
		public function SwatchElementUI(type:String){
			this.type = type;
			//mouse stuff
			mouseChildren = false;
			useHandCursor = buttonMode = true;
			addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
			
			//the all holder so that the subscriber icon doesn't get filters
			all_holder.filters = StaticFilters.copyFilterArrayFromObject({blurX:2, blurY:2, alpha:.3}, StaticFilters.black3pxInner_GlowA);
			addChild(all_holder);
			
			//swatch stuff
			var g:Graphics = swatch_mask.graphics;
			g.beginFill(0);
			g.drawRoundRect(0, 0, WH, WH, 10);
			all_holder.addChild(swatch_mask);
			
			swatch_holder.mask = swatch_mask;
			all_holder.addChild(swatch_holder);
			
			//cost bar
			credits_icon = new AssetManager.instance.assets.furn_credits_small();
			credits_icon.filters = StaticFilters.white1px_GlowA;
			credits_icon.x = 2;
			credits_icon.y = 3;
			cost_holder.addChild(credits_icon);
			
			TFUtil.prepTF(cost_tf, false);
			//cost_tf.thickness = -125; //makes "Free!" look less assey
			cost_tf.sharpness = 100;
			cost_tf.htmlText = '<p class="swatch_element_cost">Free!</p>';
			cost_tf.filters = StaticFilters.black1px90Degrees_DropShadowA;
			cost_tf.y = int(credits_icon.height/2 - cost_tf.height/2) + 2;
			cost_holder.addChild(cost_tf);
			
			//draw the white/black gradient bars
			g = cost_holder.graphics;
			g.beginGradientFill(GradientType.LINEAR, [0xffffff ,0xffffff], [.5, 0], [100, 200]);
			g.drawRect(0, 0, WH, 1);
			g.beginGradientFill(GradientType.LINEAR, [0 ,0], [.6, 0], [100, 200]);
			g.drawRoundRectComplex(0, 1, WH, credits_icon.height + 4, 0, 0, 5, 5);
			
			cost_holder.y = int(WH - cost_holder.height);
			all_holder.addChild(cost_holder);
			
			//subscriber icon
			subscriber_icon = new AssetManager.instance.assets.furn_subscriber();
			subscriber_icon.x = WH - subscriber_icon.width + 4;
			subscriber_icon.y = -4;
			addChild(subscriber_icon);
			
			//new icon
			new_icon = new AssetManager.instance.assets.furniture_new_badge_small();
			new_icon.x = -2;
			new_icon.y = -3;
			addChild(new_icon);
		}
		
		public function show(swatch:Swatch):void {
			clean();
			
			//swatch stuff			
			current_swatch = swatch;
			
			if (swatch_mcs[swatch.swatch]) {
				has_swatch = true;
				swatch_holder.addChild(swatch_mcs[swatch.swatch]);
			} else {
				//load the deco from the swatch
				has_swatch = DecoAssetManager.loadIndividualDeco(swatch.swatch, onDecoLoaded);
				
				if (!has_swatch) {
					swatch_holder.addChild(new AssetManager.instance.assets.close_swatch());
					CONFIG::debugging {
						Console.warn(swatch.swatch+' for '+swatch.tsid+' not found in location swf');
					}
				}
			}
			
			//handle if it's owned or not
			cost_holder.visible = !swatch.is_owned;
			if(!swatch.is_owned){
				showCost();
			}
			
			//subscriber only?
			subscriber_icon.visible = (!swatch.is_owned && swatch.is_subscriber);
			
			//is this new?
			new_icon.visible = (!swatch.is_owned && swatch.is_new);
			
			//if this is an admin one, dim it a bit
			alpha = !swatch.admin_only ? 1 : .5;
			
			//tooltip party
			TipDisplayManager.instance.registerTipTrigger(this);
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
			
			//party is over
			TipDisplayManager.instance.unRegisterTipTrigger(this);
		}
		
		private function showCost():void {
			//how much does this swatch cost
			credits_icon.visible = current_swatch.cost_credits > 0;
			cost_tf.htmlText = '<p class="swatch_element_cost">'+(current_swatch.cost_credits ? current_swatch.cost_credits : 'Free!')+'</p>';
			cost_tf.x = credits_icon.x + (credits_icon.visible ? credits_icon.width + 1 : 0);
		}
		
		private function clean():void {
			//clean up the bitmap data or whatever stuff of the swatch
			SpriteUtil.clean(swatch_holder);
		}
		
		private function onDecoLoaded(mc:MovieClip, class_name:String, swfWidth:Number, swfHeight:Number):void {
			swatch_mcs[class_name] = mc;
			swatch_holder.addChild(mc);
			mc.loaderInfo.loader.unloadAndStop();
		}
		
		private function onMouseDown(event:MouseEvent):void {
			if (HandOfDecorator.instance.waiting_on_purchase || !has_swatch) {
				SoundMaster.instance.playSound('CLICK_FAILURE')
				return;
			}
			
			StageBeacon.mouse_move_sig.add(onMouseMove);
			StageBeacon.mouse_up_sig.add(onMouseUp);
			
			mouse_move_start_pt.x = StageBeacon.stage.mouseX;
			mouse_move_start_pt.y = StageBeacon.stage.mouseY;
		}
		
		private function onMouseMove(event:MouseEvent):void {
			var dist:Number = Math.abs(Point.distance(mouse_move_start_pt, StageBeacon.stage_mouse_pt));
			if (dist >= 5) {
				drag_happened = true;
				StageBeacon.mouse_move_sig.remove(onMouseMove);
				dispatchEvent(new TSEvent(TSEvent.DRAG_STARTED, this));
			}
		}
		
		private function onMouseUp(event:MouseEvent):void {
			StageBeacon.mouse_up_sig.remove(onMouseUp);
			drag_happened = false;
		}
		
		private function onClick(event:MouseEvent):void {
			if (drag_happened) return;
			
			// remove these listeners because we clicked and are not dragging!
			StageBeacon.mouse_up_sig.remove(onMouseUp);
			StageBeacon.mouse_move_sig.remove(onMouseMove);
			
			if (HandOfDecorator.instance.waiting_on_purchase || !has_swatch) {
				return;
			}
			
			//let whoever is listening know
			dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target) return null;
			
			//return the label
			tip_pt = localToGlobal(LOCAL_PT);
			return {
				txt: swatch.label,
				placement: {
					x: tip_pt.x,
					y: tip_pt.y
				},
			  	pointer: WindowBorder.POINTER_BOTTOM_CENTER 
			}
		}
		
		public function get swatch():Swatch { return current_swatch; }
		override public function get height():Number { return WH; }
		override public function get width():Number { return WH; }
	}
}