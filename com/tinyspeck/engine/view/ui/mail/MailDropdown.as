package com.tinyspeck.engine.view.ui.mail
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSDropdown;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class MailDropdown extends TSDropdown
	{
		public static const BT_WIDTH:uint = 33;
		public static const BT_HEIGHT:uint = 25;
		
		private static const HEIGHT:uint = 30;
		private static const CORNER_RADIUS:Number = 4.5;
		private static const BUTTON_PADD:int = 5;
		private static const BUTTON_LABEL_X:int = 3;
		
		private var arrow_holder:Sprite = new Sprite();
		private var top_line:Sprite = new Sprite();
		
		public function MailDropdown(){
			//set the local vars all at once
			_h = HEIGHT;
			_button_padding = BUTTON_PADD;
			_button_label_x = BUTTON_LABEL_X;
			_corner_radius = CORNER_RADIUS;
			_auto_width = true;
			
			//the button size/type
			bt_size = Button.SIZE_VERB;
			bt_type = Button.TYPE_VERB;
			
			super.buildBase();
			
			//down arrow
			var arrow:DisplayObject = new AssetManager.instance.assets.carrat_large();
			SpriteUtil.setRegistrationPoint(arrow);
			arrow_holder.mouseChildren = arrow_holder.mouseEnabled = false;
			arrow_holder.addChild(arrow);
			arrow_holder.x = int(BT_WIDTH/2) + 1;
			arrow_holder.y = int(BT_HEIGHT/2) + 2;
			arrow_holder.scaleY = -1;
			addChild(arrow_holder);
			
			//top line for when the menu is opened
			var g:Graphics = top_line.graphics;
			g.beginFill(0xffffff);
			g.drawRect(0, 0, BT_WIDTH-_border_width, 1);
			top_line.x = menu_holder.x + _border_width;
			top_line.y = HEIGHT;
			top_line.visible = false;
			addChild(top_line);
		}
		
		override protected function buildMenu():void {
			super.buildMenu();
			
			//give the menu rounded corners on 3 sides
			const menu_h:int = menu_holder.height - 1;
			
			var g:Graphics = menu_holder.graphics;
			g.clear();
			g.lineStyle(_border_width, _border_color);
			g.beginFill(0xffffff);
			g.drawRoundRectComplex(0,0, _w, menu_h, 0, corner_radius, corner_radius, corner_radius);
		}
		
		override protected function toggleMenu():void {
			if (!is_open) buildMenu();
			
			super.toggleMenu();
			
			const menu_y:int = is_open ? _h : -menu_holder.height;
			const tween_type:String = is_open ? 'easeOutCubic' : 'easeInCubic';
			
			//flip the arrow
			TSTweener.removeTweens([arrow_holder, menu_holder]);
			TSTweener.addTween(arrow_holder, {scaleY:is_open ? 1 : -1, time:.2});
			TSTweener.addTween(menu_holder, {y:menu_y, time:.2, transition:tween_type, onComplete:onRollOut});
			
			//show the top line to hide the border
			if(is_open) top_line.visible = true;
		}
		
		override protected function onRollOver(event:MouseEvent=null):void {
			var g:Graphics = graphics;
			g.clear();
			g.lineStyle(border_width, border_color);
			g.beginFill(0xffffff);
			g.drawRoundRectComplex(0,0, BT_WIDTH, is_open ? HEIGHT : BT_HEIGHT, corner_radius, corner_radius, is_open ? 0 : corner_radius, is_open ? 0 : corner_radius);
		}
		
		override protected function onRollOut(event:MouseEvent=null):void {
			if(is_open) return;
			
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0, 0);
			g.drawRoundRectComplex(0,0, BT_WIDTH, BT_HEIGHT, corner_radius, corner_radius, corner_radius, corner_radius);
			
			//hide the line
			top_line.visible = false;
		}
	}
}