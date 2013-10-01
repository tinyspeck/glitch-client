package com.tinyspeck.engine.view.ui.decorate
{
	import com.tinyspeck.engine.data.house.HouseStylesChoice;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	public class HouseStylesChoiceUI extends Sprite implements ITipProvider
	{
		private static const IMG_H:uint = 100;
		private static const IMG_W:uint = 150;
		private static const LOCAL_PT:Point = new Point(IMG_W/2, -2);
		
		private var img_holder:Sprite = new Sprite();
		private var img_mask:Sprite = new Sprite();
		private var icon:DisplayObject;
		
		private var img_url:String;
		
		private var inner_glowA:Array;
		private var inner_glowBlueA:Array;
		private var inner_glowBlueHoverA:Array;
		private var tip_pt:Point = new Point();
		
		private var current_choice:HouseStylesChoice;
		
		private var is_built:Boolean;
		private var _selected:Boolean;
		
		public function HouseStylesChoiceUI(){}
		
		private function buildBase():void {
			var g:Graphics = img_mask.graphics;
			g.beginFill(0);
			g.drawRoundRect(0, 0, IMG_W, IMG_H, 8);
			img_holder.mask = img_mask;
			addChild(img_holder);
			addChild(img_mask);
			
			//filters
			inner_glowA = StaticFilters.copyFilterArrayFromObject({alpha:.7, blurX:2, blurY:2},StaticFilters.black3pxInner_GlowA);
			inner_glowBlueA = StaticFilters.copyFilterArrayFromObject({inner:true}, StaticFilters.blue2px_GlowA);
			inner_glowBlueHoverA = StaticFilters.copyFilterArrayFromObject({inner:true}, StaticFilters.blue2px40Alpha_GlowA);
			
			//mouse stuff
			mouseChildren = false;
			useHandCursor = buttonMode = true;
			addEventListener(MouseEvent.ROLL_OVER, onRoll, false, 0, true);
			addEventListener(MouseEvent.ROLL_OUT, onRoll, false, 0, true);
			
			icon = new AssetManager.instance.assets.furn_subscriber();
			icon.x = IMG_W - icon.width - 2;
			icon.y = IMG_H - icon.height - 2;
			addChild(icon);
			
			is_built = true;
		}
		
		public function show(style_choice:HouseStylesChoice):void {
			if(!is_built) buildBase();
			
			current_choice = style_choice;
			
			//load the image
			if(img_url != style_choice.image){
				img_url = style_choice.image;
				SpriteUtil.clean(img_holder);
				AssetManager.instance.loadBitmapFromWeb(img_url, onImageLoad, 'iMG Menu');
			}
			
			//show the default filter
			selected = current_choice.is_current;
			
			//we showing the icon?
			icon.visible = current_choice.is_subscriber;
			
			//tooltip party
			TipDisplayManager.instance.registerTipTrigger(this);
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
			
			//party is over
			TipDisplayManager.instance.unRegisterTipTrigger(this);
		}
		
		protected function onImageLoad(filename:String, bm:Bitmap):void {
			//add the image to the holder
			const scale:Number = IMG_H/bm.height;
			bm.smoothing = true;
			bm.scaleX = bm.scaleY = scale;
			bm.x = int(IMG_W/2 - bm.width/2);
			
			img_holder.addChild(bm);
		}
		
		protected function onRoll(event:MouseEvent):void {
			if(selected) return;
			
			const is_over:Boolean = event.type == MouseEvent.ROLL_OVER;
			filters = is_over ? inner_glowBlueHoverA : inner_glowA;
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target) return null;
			
			//return the label
			tip_pt = localToGlobal(LOCAL_PT);
			return {
				txt: choice.label,
				placement: {
					x: tip_pt.x,
					y: tip_pt.y
				},
				pointer: WindowBorder.POINTER_BOTTOM_CENTER 
			}
		}
		
		override public function get width():Number { return IMG_W; }
		override public function get height():Number { return IMG_H; }
		
		public function get choice():HouseStylesChoice { return current_choice; }
		
		public function get selected():Boolean { return _selected; }
		public function set selected(value:Boolean):void {
			_selected = value;
			
			filters = value ? inner_glowBlueA: inner_glowA;
		}
	}
}