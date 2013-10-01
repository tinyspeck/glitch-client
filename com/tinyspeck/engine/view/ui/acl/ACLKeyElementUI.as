package com.tinyspeck.engine.view.ui.acl
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.acl.ACLKey;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class ACLKeyElementUI extends TSSpriteWithModel
	{
		protected var HEIGHT:uint = 82;
		protected var PADD:uint = 13;
		protected var AVATAR_RADIUS:uint = 19;
		
		protected var bg_color:uint;
		protected var border_color:uint;
		protected var avatar_bg_color:uint;
		protected var _border_width:int = -1;
		
		protected var current_key:ACLKey;
		
		protected var avatar_holder:Sprite = new Sprite();
		protected var avatar_mask:Sprite = new Sprite();
		protected var body_holder:Sprite = new Sprite();
		
		protected var body_tf:TextField = new TextField();
		
		protected var is_built:Boolean;
		
		public function ACLKeyElementUI(){}
		
		protected function buildBase():void {
			//body
			TFUtil.prepTF(body_tf);
			body_tf.embedFonts = false;
			body_holder.addChild(body_tf);
			body_holder.x = AVATAR_RADIUS*2 + PADD*2;
			addChild(body_holder);
			
			//avatar
			avatar_bg_color = CSSManager.instance.getUintColorValueFromStyle('acl_key_element_avatar', 'backgroundColor', 0xe5ebeb);
			var g:Graphics = avatar_holder.graphics;
			g.clear();
			g.beginFill(avatar_bg_color);
			g.drawCircle(AVATAR_RADIUS, AVATAR_RADIUS, AVATAR_RADIUS);
			avatar_holder.x = PADD;
			avatar_holder.y = int(HEIGHT/2 - avatar_holder.height/2);
			avatar_holder.filters = StaticFilters.black3pxInner_GlowA;
			avatar_holder.mask = avatar_mask;
			addChild(avatar_holder);
			
			g = avatar_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawCircle(AVATAR_RADIUS, AVATAR_RADIUS, AVATAR_RADIUS);
			avatar_mask.x = avatar_holder.x;
			avatar_mask.y = avatar_holder.y;
			addChild(avatar_mask);
			
			is_built = true;
		}
		
		public function show(w:int, key:ACLKey, draw_border:Boolean):void {
			if(!key) return;
			if(!is_built) buildBase();
						
			_w = w;
			
			current_key = key;
			
			//draw the BG
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(bg_color);
			g.drawRect(0, 0, _w, HEIGHT);
			
			if(draw_border){
				g.beginFill(border_color);
				g.drawRect(0, HEIGHT-border_width, _w, border_width);
			}
			
			//avatar
			showAvatar();
			
			//body
			showBody();
			
			visible = true;
		}
		
		public function hide():void {
			visible = false;
		}
		
		protected function showBody():void {
			//this is usually overriden by the child class
		}
		
		protected function showAvatar():void {
			//clean it out
			if(!current_key.pc_tsid || (current_key.pc_tsid && avatar_holder.name != current_key.pc_tsid)){
				while(avatar_holder.numChildren) avatar_holder.removeChildAt(0);
			}
			
			const pc:PC = model.worldModel.getPCByTsid(current_key.pc_tsid);
			if(!pc) return;
			
			if(pc.singles_url){
				avatar_holder.name = pc.tsid;
				AssetManager.instance.loadBitmapFromWeb(pc.singles_url+'_50.png', onHeadshotLoad, 'ACL keys received');
			} 
			else {
				CONFIG::debugging {
					Console.warn(pc.tsid+' does not have a singles_url');
				}
			}
		}
		
		protected function onHeadshotLoad(filename:String, bm:Bitmap):void {
			bm.scaleX = -1;
			bm.x = bm.width - 11;
			bm.y = -8;
			avatar_holder.addChild(bm);
		}
		
		public function get border_width():int { return _border_width; }
		
		override public function get height():Number {
			return HEIGHT;
		}
	}
}