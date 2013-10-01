package com.tinyspeck.vanity {
	
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.view.loadedswfs.AvatarSwf;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	public class VanityMirror extends Sprite {
		
		private var w:int;
		private var frame_bm:Bitmap;
		private var ava_swf:AvatarSwf;
		private var resetCallBackFunction:Function;
		private var saveCallBackFunction:Function;
		private var animationCallBackFunction:Function;
		private var surprise_bt:Sprite = new Sprite();
		private var angry_bt:Sprite = new Sprite();
		private var happy_bt:Sprite = new Sprite();
		private var idle_bt:Sprite = new Sprite();
		private var reset_bt:Sprite = new Sprite();
		private var mirror_bg:Sprite = new Sprite();
		private var save_bt:Button;
		
		private var anim_btnsA:Array = ['surprise_bt', 'angry_bt', 'happy_bt', 'idle_bt'];
		private var anim_btns_anim_map:Object = {
			surprise_bt: 'surprise',
			angry_bt: 'angry',
			happy_bt: 'happy',
			idle_bt: 'idle3'
		};
		
		public function VanityMirror(ava_swf:AvatarSwf, resetCallBackFunction:Function, saveCallBackFunction:Function, animationCallBackFunction:Function) {
			super();
			this.ava_swf = ava_swf;
			this.resetCallBackFunction = resetCallBackFunction;
			this.saveCallBackFunction = saveCallBackFunction;
			this.animationCallBackFunction = animationCallBackFunction;
		}
		
		public function init():void {
			w = VanityModel.mirror_column_w;
			
			ava_swf.scaleX = ava_swf.scaleY = VanityModel.mirror_ava_scale;
			ava_swf.scaleX = -ava_swf.scaleX;
			ava_swf.x = VanityModel.mirror_ava_x;
			ava_swf.y = VanityModel.mirror_frame_y+VanityModel.mirror_ava_y;
			
			addChild(mirror_bg);
			addChild(ava_swf);
			
			var bm:Bitmap;
			
			bm = AssetManager.instance.getLoadedBitmap(VanityModel.imgs_to_loadH['vanity_mirror_tall_bg.png']);
			mirror_bg.addChild(bm);
			/*
			bm.visible = false;
			var g:Graphics = mirror_bg.graphics;
			g.beginFill(0, 1);
			g.drawRect(0,0,bm.width, bm.height);
			*/
			bm = AssetManager.instance.getLoadedBitmap(VanityModel.imgs_to_loadH['vanity_mirror_tall.png']);
			frame_bm = bm;
			frame_bm.x = Math.round((w-frame_bm.width+4)/2);
			frame_bm.y = VanityModel.mirror_frame_y;
			addChild(frame_bm);
			
			mirror_bg.x = frame_bm.x+VanityModel.mirror_bg_x;
			mirror_bg.y = frame_bm.y+VanityModel.mirror_bg_y;
			
			bm = AssetManager.instance.getLoadedBitmap(VanityModel.imgs_to_loadH['vanity_reset_button.png']);
			reset_bt.buttonMode = reset_bt.useHandCursor = true;
			reset_bt.x = Math.round((w-bm.width)/2)+4;
			reset_bt.y = VanityModel.mirror_frame_y + frame_bm.height - bm.height - 6;
			reset_bt.addEventListener(MouseEvent.CLICK, onResetClick);
			reset_bt.addChild(bm);
			
			bm = AssetManager.instance.getLoadedBitmap(VanityModel.imgs_to_loadH['vanity_test_pointer.png']);
			bm.x = VanityModel.mirror_test_x;
			bm.y = VanityModel.mirror_test_y;
			addChild(bm);
			
			
			/*
			Keyboard.NUMBER_1, // huh emotion
			Keyboard.NUMBER_2, // grrr emotion
			Keyboard.NUMBER_3, // joy emotion
			*/
			
			bm = AssetManager.instance.getLoadedBitmap(VanityModel.imgs_to_loadH['vanity_surprised_button.png']);
			surprise_bt.addChild(bm);
			surprise_bt.x = Math.round(w/2)-(bm.width*2)-(VanityModel.mirror_emo_button_y_padd*1.5);
			surprise_bt.y = VanityModel.mirror_emo_button_y;
			addChild(surprise_bt);
			
			bm = AssetManager.instance.getLoadedBitmap(VanityModel.imgs_to_loadH['vanity_angry_button.png']);
			angry_bt.addChild(bm);
			angry_bt.x = Math.round(w/2)-(bm.width)-(VanityModel.mirror_emo_button_y_padd*.5);
			angry_bt.y = VanityModel.mirror_emo_button_y;
			addChild(angry_bt);
			
			bm = AssetManager.instance.getLoadedBitmap(VanityModel.imgs_to_loadH['vanity_happy_button.png']);
			happy_bt.addChild(bm);
			happy_bt.x = Math.round(w/2)+(VanityModel.mirror_emo_button_y_padd*.5);
			happy_bt.y = VanityModel.mirror_emo_button_y;
			addChild(happy_bt);
			
			bm = AssetManager.instance.getLoadedBitmap(VanityModel.imgs_to_loadH['vanity_sleepy_button.png']);
			idle_bt.addChild(bm);
			idle_bt.x = Math.round(w/2)+(bm.width)+(VanityModel.mirror_emo_button_y_padd*1.5);
			idle_bt.y = VanityModel.mirror_emo_button_y;
			addChild(idle_bt);
			
			save_bt = new Button({
				label_face:'Arial',
				label_size: VanityModel.button_font_size,
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR,
				name: 'save',
				label: 'Save Changes',
				w: 144,
				h: 34
			});
			
			save_bt.x = Math.round((w-save_bt.width)/2);
			save_bt.y = VanityModel.mirror_frame_y + frame_bm.height+10;
			
			//save_bt.x = VanityModel.ui_w - save_bt.width - 10 - this.x;
			//save_bt.y = stage.stageHeight - save_bt.height - 60 - this.y;
			
			addChild(save_bt);
			
			save_bt.addEventListener(TSEvent.CHANGED, onSaveClick, false, 0, true);
			
			var bt:Sprite;
			for (var i:int;i<anim_btnsA.length;i++) {
				bt = this[anim_btnsA[int(i)]] as Sprite;
				bt.useHandCursor = bt.buttonMode = true;
				bt.name = anim_btnsA[int(i)];
				bt.addEventListener(MouseEvent.CLICK, onAnimBtClick);
			}
			addChild(reset_bt);
		}
		
		private function onAnimBtClick(e:MouseEvent):void {
			var which:String = Sprite(e.target).name;
			var anim:String = anim_btns_anim_map[which];
			if (CONFIG::god && EnvironmentUtil.getUrlArgValue('SWF_hat_and_hair_all') == '1' && which == 'surprise_bt') {
				anim = 'climb';
			}
			if (animationCallBackFunction != null) animationCallBackFunction(anim);
		}
		
		private function onSaveClick(event:Event):void {
			var bt:Button = event.target as Button;
			if(bt.disabled) return;
			saveCallBackFunction();
		}
		
		private function onResetClick(event:Event):void {
			resetCallBackFunction();
		}
	}
}