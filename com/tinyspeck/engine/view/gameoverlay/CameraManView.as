package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.quasimondo.geom.ColorMatrix;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.AbstractTSView;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	public class CameraManView extends AbstractTSView implements ITipProvider {
		/* singleton boilerplate */
		public static const instance:CameraManView = new CameraManView();
		
		private var spinner:MovieClip;
		
		private var fading:Boolean;
		private var showing:Boolean;
		private var has_moved:Boolean;
		private var is_hovering:Boolean;
		private var model:TSModelLocator;
		private var top_holder:Sprite = new Sprite();
		private var bottom_holder:Sprite = new Sprite();
		private var tf_holder:Sprite = new Sprite();
		private var icon_holder:Sprite = new Sprite();
		private var icon_strikethrough:Sprite = new Sprite();
		private var big_tf:TextField = new TextField();
		private var small_tf:TextField = new TextField();
		private var skill_tips_tf:TextField = new TSLinkedTextField();
		private var icon_bt:Button;
		private var faded_alpha:Number = .1;
		private var unfaded_alpha:Number = .3;
		private var strikethrough_color:uint = 0xdf1010;
		
		public var cam_disabled_reason:String = '';
		public var cam_skills_msg:String = '';
		
		public function CameraManView() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			mouseEnabled = false;
			model = TSModelLocator.instance;
			addChild(top_holder);
			addChild(bottom_holder);
			
			TFUtil.prepTF(big_tf, false);
			big_tf.multiline = true; //this gives us autosize and multiline
			big_tf.filters = StaticFilters.loadingTip_DropShadowA;
			big_tf.htmlText = '<span class="camera_man_big">camera&nbsp;mode<br>enabled</span>';
			
			icon_holder.buttonMode = icon_holder.mouseEnabled = true;
			icon_holder.x = int(big_tf.x+big_tf.width+20);
			icon_holder.y = 10;
			TipDisplayManager.instance.registerTipTrigger(icon_holder);
			
			spinner = new AssetManager.instance.assets.spinner();
			spinner.visible = false;
			spinner.x = icon_holder.x-20;
			spinner.y = icon_holder.y;
			spinner.scaleX = spinner.scaleY = 1.3;
			spinner.mouseChildren = false;
			var cm:ColorMatrix = new com.quasimondo.geom.ColorMatrix();
			cm.adjustContrast(1);
			cm.adjustBrightness(100);
			cm.colorize(0xFFFFFF);
			spinner.filters = [cm.filter].concat(StaticFilters.loadingTip_DropShadowA);
			top_holder.addChild(spinner);
			TipDisplayManager.instance.registerTipTrigger(spinner);
			
			TFUtil.prepTF(small_tf, false);
			small_tf.multiline = true; //this gives us autosize and multiline
			small_tf.filters = StaticFilters.loadingTip_DropShadowA;
			small_tf.y = 70;
			
			top_holder.addChild(tf_holder);
			tf_holder.addChild(big_tf);
			tf_holder.addChild(small_tf);
			top_holder.addChild(icon_holder);
			
			icon_bt = new Button({
				name: 'recenter',
				graphic: new AssetManager.instance.assets['camera_icon_with_text'](),
				graphic_disabled: new AssetManager.instance.assets['camera_icon_with_text'](),
				graphic_hover: new AssetManager.instance.assets['camera_icon_with_text'](),
				w: 74,
				h: 53,
				no_draw: true
			});
			
			icon_holder.addChild(icon_bt);
			icon_bt.addEventListener(TSEvent.CHANGED, onIconClick, false, 0, true);
			icon_bt.addEventListener(MouseEvent.ROLL_OVER, onIconRollover, false, 0, true);
			icon_bt.addEventListener(MouseEvent.ROLL_OUT, onIconRollOut, false, 0, true);
			
			//build the strikethrough
			strikethrough_color = CSSManager.instance.getUintColorValueFromStyle('camera_man_strikethrough', 'color', strikethrough_color);
			
			icon_strikethrough.mouseEnabled = false;
			var g:Graphics = icon_strikethrough.graphics;
			g.beginFill(strikethrough_color);
			g.drawRect(0, 0, int(icon_bt.width + 10), 4);
			icon_strikethrough.y = int(icon_bt.height - 5);
			icon_strikethrough.rotation = -33;
			icon_strikethrough.visible = false;
			icon_holder.addChild(icon_strikethrough);
			
			TFUtil.prepTF(skill_tips_tf, false, {color:'#ffffff', textDecoration:'underline'});
			skill_tips_tf.multiline = true; //this gives us autosize and multiline
			skill_tips_tf.filters = StaticFilters.loadingTip_DropShadowA;
			bottom_holder.addChild(skill_tips_tf);
			
			hide();
		}
		
		public function getTip(tip_target:DisplayObject=null):Object {
			if(!tip_target) return null;
			
			if (tip_target == icon_holder) {
				return {
					txt: (model.worldModel.pc.cam_can_snap) ? 'Click to take a photo!' : cam_disabled_reason,
					pointer: WindowBorder.POINTER_BOTTOM_CENTER
				}	
			} else if (tip_target == spinner) {
				return {
					txt: 'Saving your photo!',
					pointer: WindowBorder.POINTER_BOTTOM_CENTER
				}	
			}
			
			return null;
		}
		
		public function onIconClick(e:TSEvent):void {
			if (CameraMan.instance.waiting_on_save) {
				return;
			}
			CameraMan.instance.snap();
		}
		
		public function onIconRollover(e:MouseEvent):void {
			TSTweener.removeTweens(icon_holder);
			icon_holder.alpha = 1;
			is_hovering = true;
		}
		
		public function onIconRollOut(e:MouseEvent):void {
			if (fading) {
				TSTweener.removeTweens(icon_holder);
				icon_holder.alpha = faded_alpha;
			}
			
			is_hovering = false;
		}
		
		public function fade():void {
			if (fading) return;
			has_moved = true;
			fading = true;
			TSTweener.removeTweens([tf_holder, icon_holder]);
			TSTweener.addTween([tf_holder, icon_holder], {alpha:faded_alpha, time:1});
		}
		
		public function unfade():void {
			if (is_hovering) return;
			fading = false;
			TSTweener.removeTweens([tf_holder, icon_holder]);
			TSTweener.addTween([tf_holder, icon_holder], {alpha:(!has_moved ? 1 : unfaded_alpha), time:1});
		}
		
		public function update():void {
			if (!model.worldModel.pc) return;
			
			var enter_Str:String = (model.worldModel.pc.cam_can_snap) ? ', press "ENTER" to snap' : '';
			
			if (CameraMan.instance.waiting_on_save) {
				small_tf.htmlText = '<p class="camera_man_small">Hang on, I\'m saving your photo right now!<br>'+
					'<span class="camera_man_smaller">&nbsp;</span></p>';
			} else {
				small_tf.htmlText = '<p class="camera_man_small">Use arrow keys to move'+enter_Str+'<br>'+
					'<span class="camera_man_smaller">Press "C" or "ESC" to exit</span></p>';
			}
			
			skill_tips_tf.htmlText = '<p class="camera_man_smaller">'+StringUtil.injectClass(cam_skills_msg, 'a', 'camera_man_link')+'</span></p>';

			icon_strikethrough.visible = !model.worldModel.pc.cam_can_snap;
			refresh();
		}
		
		public function show():void {
			showing = true;
			visible = true;
			has_moved = false;
			
			tf_holder.alpha = icon_holder.alpha = faded_alpha;
			update();
			
			unfade();
			
			addChild(top_holder);
			addChild(bottom_holder);
			refresh();
		}
		
		public function hideButton():void {
			icon_holder.visible = false;
			spinner.visible = true;
			update();
		}
		
		public function showButton():void {
			icon_holder.visible = true;
			spinner.visible = false;
			update();
		}
		
		public function cancel():void {
			hide();
		}
		
		public function hide():void {
			showing = false;
			visible = false;
			if (top_holder.parent) removeChild(top_holder);
			if (bottom_holder.parent) removeChild(bottom_holder);
		}
		
		public function refresh():void {
			if (!showing) return;
			
			small_tf.x = Math.round((top_holder.width-small_tf.width)/2);
			
			// hardcode width, so it does not vary when the small_tf width changes
			top_holder.x = Math.round((model.layoutModel.loc_vp_w-290)/2);
			top_holder.y = Math.round((model.layoutModel.loc_vp_h-top_holder.height)/2);
			
			bottom_holder.x = Math.round((model.layoutModel.loc_vp_w-bottom_holder.width)/2);
			bottom_holder.y = Math.round((model.layoutModel.loc_vp_h-bottom_holder.height)-6);
		}
	}
}