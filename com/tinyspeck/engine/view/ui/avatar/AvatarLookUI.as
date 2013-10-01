package com.tinyspeck.engine.view.ui.avatar
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.pc.AvatarLook;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.imagination.ImaginationYourLooksUI;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;

	public class AvatarLookUI extends Sprite implements ITipProvider
	{
		//match the dimentions of the PNG file
		public static const WIDTH:uint = 100;
		public static const HEIGHT:uint = 144;
		
		private const avatar_holder:Sprite = new Sprite();
		private const remove_holder:Sprite = new Sprite();
		private const spinner_holder:Sprite = new Sprite();
		
		private var _current_look:AvatarLook;
		private var remove_bt:Button;
		
		private var outer_stroke:GlowFilter = new GlowFilter();
		private var outer_glow:GlowFilter = new GlowFilter();
		
		private var filtersA:Array;
		
		private var is_built:Boolean;
		private var is_hover:Boolean;
		private var flip_right:Boolean;
		
		public function AvatarLookUI(){}
		
		private function buildBase():void {
			addEventListener(MouseEvent.ROLL_OVER, onMouse, false, 0, true);
			addEventListener(MouseEvent.ROLL_OUT, onMouse, false, 0, true);
			avatar_holder.addEventListener(MouseEvent.CLICK, onAvatarClick, false, 0, true);
			addChild(avatar_holder);
			
			//setup the filters
			outer_stroke.blurX = 2;
			outer_stroke.blurY = 2;
			outer_stroke.strength = 40;
			outer_stroke.quality = 2;
			outer_stroke.color = 0x313131;
			
			outer_glow.quality = 3;
			
			filtersA = [outer_stroke, outer_glow];
			
			//draw a transparent box so things can get the width/height before the assets load
			var g:Graphics = graphics;
			g.beginFill(0,0);
			g.drawRect(0, 0, WIDTH, HEIGHT);
			
			//spinner
			const spinner:DisplayObject = new AssetManager.instance.assets.spinner();
			spinner.transform.colorTransform = ColorUtil.getColorTransform(0xffffff);
			spinner_holder.addChild(spinner);
			spinner_holder.mouseEnabled = spinner_holder.mouseChildren = false;
			
			//remove
			const remove_DO:DisplayObject =  new AssetManager.instance.assets.remove();
			remove_DO.filters = StaticFilters.black1px90Degrees_DropShadowA;
			remove_bt = new Button({
				name: 'remove',
				label: 'Remove',
				label_c: 0xffffff,
				label_size: 12,
				label_offset: 1,
				label_face: 'VAGRoundedBoldEmbed',
				label_alpha: .5,
				focus_label_alpha: 1,
				graphic:remove_DO,
				graphic_placement: 'left',
				graphic_alpha: .5,
				focused_graphic_alpha: 1,
				draw_alpha: 0,
				focus_draw_alpha: .5,
				w: 82,
				h: 26
			});
			remove_bt.y = 10;
			remove_bt.visible = false;
			remove_bt.label_tf.filters = StaticFilters.black1px90Degrees_DropShadowA;
			remove_bt.addEventListener(TSEvent.CHANGED, onRemoveClick, false, 0, true);
			remove_holder.addChild(remove_bt);
			
			remove_holder.y = HEIGHT;
			addChild(remove_holder);
			
			g = remove_holder.graphics;
			g.beginFill(0,0);
			g.drawRect(0, 0, remove_holder.width, remove_holder.height);
			
			is_built = true;
		}
		
		public function show(look:AvatarLook, flip_right:Boolean = false):void {
			if(!is_built) buildBase();
			
			_current_look = look;
			this.flip_right = flip_right;
			onMouse(null);
			
			//load in the outfit if we need to
			if(!current_look.singles_base || avatar_holder.name != current_look.singles_base){
				//place the spinner
				addChild(spinner_holder);
				spinner_holder.x = int(WIDTH/2 - 20 - (flip_right ? 0 : 10));
				spinner_holder.y = int(HEIGHT/2 - 30);
				
				while(avatar_holder.numChildren) avatar_holder.removeChildAt(0);
				avatar_holder.name = 'nuffin';
				if(current_look.singles_base){
					avatar_holder.name = current_look.singles_base;
					AssetManager.instance.loadBitmapFromWeb(current_look.singles_base+'_100.png', onOutfitLoad, 'Avatar Look UI');
				}
			}
			else {
				//same thing? bail.
				if(avatar_holder.numChildren){
					const bm:Bitmap = avatar_holder.getChildAt(0) as Bitmap;
					bm.scaleX = flip_right ? -1 : 1;
					bm.x = flip_right ? bm.width - 11 : 0;
				}
				if(contains(spinner_holder)) removeChild(spinner_holder);
			}
			
			TipDisplayManager.instance.registerTipTrigger(this);
		}
		
		public function hide():void {
			if(parent) {
				parent.removeChild(this);
				TipDisplayManager.instance.unRegisterTipTrigger(this);
			}
		}
		
		private function onOutfitLoad(filename:String, bm:Bitmap):void {
			while(avatar_holder.numChildren) avatar_holder.removeChildAt(0);
			if(bm){
				if(flip_right){
					bm.scaleX = -1;
					bm.x = bm.width - 11;
				}
				avatar_holder.addChild(bm);
			}
			else {
				CONFIG::debugging {
					Console.warn('no bitmap?:'+bm+' filename: '+filename+' holder name: '+avatar_holder.name);
				}
			}
			
			//ditch the spinner
			if(contains(spinner_holder)) removeChild(spinner_holder);
		}
		
		private function onMouse(event:MouseEvent):void {
			if(!is_built) return;
			
			const is_over:Boolean = event && event.type == MouseEvent.ROLL_OVER;
			if(is_over && flip_right) return;
			avatar_holder.buttonMode = avatar_holder.useHandCursor = is_over;
			
			remove_bt.visible = is_over;
			
			outer_stroke.alpha = is_over ? .9 : .5;
			
			outer_glow.blurX = is_over ? 13 : 20;
			outer_glow.blurY = is_over ? 13 : 20;
			outer_glow.color = is_over ? 0x2deeff : 0xffffff;
			outer_glow.alpha = is_over ? .7 : .3;
			
			avatar_holder.filters = filtersA;
		}
		
		private function onAvatarClick(event:MouseEvent):void {
			if(!current_look || current_look.is_current) return;
			
			//go tell the server we want to switch to this look
			ImaginationYourLooksUI.instance.switchOutfit(current_look.outfit_id);
			
			SoundMaster.instance.playSound('CLICK_SUCCESS');
		}
		
		private function onRemoveClick(event:TSEvent):void {
			if(remove_bt.disabled || !current_look) return;
			
			//open the confirmation dialog
			ImaginationYourLooksUI.instance.deleteOutfit(current_look.outfit_id);
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target || flip_right) return null;
			
			return {
				txt: remove_bt && remove_bt.focused ? 'Remove this look' : 'Switch to this look',
				offset_x: -11,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
		
		public function get current_look():AvatarLook { return _current_look; }
		
		override public function get width():Number {
			return WIDTH;
		}
		
		override public function get height():Number {
			return HEIGHT;
		}
	}
}