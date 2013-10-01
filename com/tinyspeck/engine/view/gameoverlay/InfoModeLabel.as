package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.InfoManager;
	import com.tinyspeck.engine.port.TSSprite;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.PCView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	public class InfoModeLabel extends Sprite {
		private static const MAX_WIDTH:uint = 200;
		private static const HOLDER_ALPHA:Number = .8;
		private static const HOLDER_ALPHA_HOVER:Number = .9;
		private static const TEXT_PADD:uint = 2;
		private static const NUB_W:uint = 15;
		private static const NUB_H:uint = 13;
		
		private var holder:Sprite;
		public var view:TSSprite;
		
		private var icon:DisplayObject;
		private var icon_hover:DisplayObject;
		
		private var tf:TextField;
		
		private var current_label:String;
		
		private var is_built:Boolean;
		private var is_highlit:Boolean = true; // so the first call to unhighlight, in build(), works
		
		public function InfoModeLabel() {
			super();
		}
		
		private function build():void {
			//holder
			holder = new Sprite();
			buttonMode = useHandCursor = true;
			mouseChildren = false;
			holder.filters = StaticFilters.copyFilterArrayFromObject({quality:3, alpha:.3, strength:3, blurX:4, blurY:4}, StaticFilters.black_GlowA);
			addChild(holder);
			
			//tf
			tf = new TextField();
			TFUtil.prepTF(tf, true);
			tf.embedFonts = false;
			holder.addChild(tf);
			
			//icons
			icon = new AssetManager.instance.assets.get_info();
			icon.x = -icon.width/2;
			holder.addChild(icon);
			
			icon_hover = new AssetManager.instance.assets.get_info_hover();
			icon_hover.x = icon.x;
			holder.addChild(icon_hover);
			
			addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			
			is_built = true;
		}
		
		public function show(view:TSSprite):void {
			if (this.view == view) {
				return;
			}
			
			this.view = view;
			if (!is_built) build();
			
			tf.width = 200;
			if (view is LocationItemstackView) {
				current_label = LocationItemstackView(view).itemstack.getLabel();
			} else if (view is PCView) {
				const pc:PC = TSModelLocator.instance.worldModel.getPCByTsid(view.tsid);
				current_label = pc.label;
			}
			
			//set the text
			is_highlit = true;
			unhighlight();
			
			tf.width = tf.textWidth+6;
			
			//  keep it centered and all above the bottom
			tf.x = -Math.round(tf.width/2);
			tf.y = -Math.round(tf.height+TEXT_PADD/2);
			icon.y = -(tf.height)-icon.height-2;
			icon_hover.y = icon.y;
			draw();
			
			TSFrontController.instance.getMainView().gameRenderer.placeOverlayInSCH(this, 'InfoModeLabel.show item:'+view.tsid);
		}
		
		private function draw():void {
			const w:int = tf.width+TEXT_PADD*4;
			const h:int = tf.height+TEXT_PADD;
			const g:Graphics = holder.graphics;
			g.clear();
			g.beginFill(0xffffff);
			
			g.drawRoundRect(-w/2, -h, w, h, 12);
			g.endFill();
			g.beginFill(0xffffff);
			g.drawRoundRectComplex(-NUB_W/2, -h-NUB_H, NUB_W, NUB_H, 9,9,0,0);
		}
		
		public function get tsid():String {
			if (!view) return null;
			return view.tsid;
		}
		
		public function reset():void {
			view = null;
			if (parent) parent.removeChild(this);
			unhighlight();
		}
		
		public function hightlight():void {
			if (is_highlit) return;
			is_highlit = true;
			holder.alpha = HOLDER_ALPHA_HOVER;
			setText();
			setIcon();
			
			if (parent) {
				parent.addChild(this);
			}
		}
		
		public function unhighlight():void {
			if (!is_highlit) return;
			is_highlit = false;
			holder.alpha = HOLDER_ALPHA;
			setText();
			setIcon();
		}
		
		private function setText():void {
			if(!current_label) return;
			
			var txt:String = '<p class="info_mode">';
			if(is_highlit) txt += '<span class="info_mode_hover">';
			txt += current_label;
			if(is_highlit) txt += '</span>';
			txt += '</p>';
			
			tf.htmlText = txt;
		}
		
		private function setIcon():void {
			if(!icon) return;
			
			icon.visible = !is_highlit;
			icon_hover.visible = is_highlit;
		}
		
		private function onMouseOver(e:MouseEvent):void {
			if (!view) return;
			InfoManager.instance.onInfoLabelMouseOver(view);
		}
		
		private function onMouseOut(e:MouseEvent):void {
			if (!view) return;
			InfoManager.instance.onInfoLabelMouseOut(view);
		}
	}
}