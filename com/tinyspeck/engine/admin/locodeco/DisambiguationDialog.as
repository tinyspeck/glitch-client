package com.tinyspeck.engine.admin.locodeco {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Dialog;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	
	public class DisambiguationDialog extends Dialog {
		public static const instance:DisambiguationDialog = new DisambiguationDialog();
		
		public const tf:TextField = new TSLinkedTextField();
		
		private var _startMousePoint:Point;
		
		
		public function DisambiguationDialog() {
			_close_bt_padd_right = 8;
			_close_bt_padd_top = 8;
			_base_padd = 20;
			_w = 330;
			_h = 300;
			bg_c = 0x0a181d;
			bg_alpha = .9;
			no_border = true;
			close_on_editing = false;
			_border_w = 0;
			_construct();
			addEventListener(MouseEvent.ROLL_OUT, onRollOut, false, 0, true);
		}
		
		override protected function _construct() : void {
			super._construct();
			
			window_border.corner_rad = 10;
			
			TFUtil.prepTF(tf);
			tf.x = _close_bt_padd_right;
			tf.y = _close_bt_padd_top;
			// wordWrap screws up text measurement
			tf.wordWrap = false;
			addChild(tf);
		}
		
		override protected function makeCloseBt():Button {
			return new Button({
				graphic: new AssetManager.instance.assets['close_x_small_gray'](),
				name: '_close_bt',
				c: bg_c,
				high_c: bg_c,
				disabled_c: bg_c,
				shad_c: bg_c,
				inner_shad_c: 0xcccccc,
				h: 20,
				w: 20,
				disabled_graphic_alpha: .3,
				focus_shadow_distance: 1
			});
		}
		
		public function startWithHTMLText(htmlTxt:String):void {
			tf.htmlText = htmlTxt;
			start();
		}
		
		override public function start():void {
			if(!canStart(true)) return;
			
			// | 8px *****TEXTFIELD***** 8px [X] 8px |
			_w = (tf.textWidth + 3*_close_bt_padd_right) + _close_bt.w;
			_h = tf.textHeight + 2*_close_bt_padd_top;
			
			// invalidate(true) is implied by super.start();
			super.start();
			
			transitioning = true;
			scaleX = scaleY = .02;
			_startMousePoint = parent.globalToLocal(StageBeacon.stage_mouse_pt);
			x = _startMousePoint.x;
			y = _startMousePoint.y;
			const self:DisambiguationDialog = this;
			TSTweener.removeTweens(self);
			TSTweener.addTween(self, {y:dest_y, x:dest_x, scaleX:1, scaleY:1, time:.2, transition:'easeInCubic', onComplete:function():void{
				self.transitioning = false;
				self._place();
			}});
			
			addChild(_close_bt); // make sure it stays on top
		}
		
		override public function end(release:Boolean):void {
			if (!transitioning) {
				transitioning = true;
				const self:DisambiguationDialog = this;
				const superEnd:Function = super.end;
				TSTweener.removeTweens(self);
				TSTweener.addTween(self, {y:_startMousePoint.y, x:_startMousePoint.x, scaleX:.02, scaleY:.02, time:.2, transition:'easeOutCubic', onComplete:function():void{
					superEnd(release);
					self.scaleX = self.scaleY = 1;
					self.transitioning = false;
				}});
			}
		}
		
		override protected function _place():void {
			if (parent) {
				// keep it in bounds of the viewport
				const pt:Point = parent.globalToLocal(StageBeacon.stage_mouse_pt);
				dest_x = pt.x - _w/2;
				dest_x = Math.min(Math.max(dest_x, 0), model.layoutModel.loc_vp_w-_w);
				dest_y = pt.y - _h/2;
				dest_y = Math.min(Math.max(dest_y, 0), model.layoutModel.loc_vp_h-_h);
				
				if (!transitioning) {
					x = dest_x;
					y = dest_y;
				}
			}
		}
		
		private function onRollOut(e:MouseEvent):void {
			DisambiguationDialog.instance.end(true);
		}
	}
}