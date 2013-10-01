package com.tinyspeck.engine.view.gameoverlay
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.sound.SoundManager;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.ui.Checkbox;
	import com.tinyspeck.engine.view.ui.TSSlider;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	public class AudioControl extends Sprite implements ITipProvider, IRefreshListener
	{
		private const HOLDER_WIDTH:int = 80;
		private const HOLDER_HEIGHT:int = 175;
		private const HOLDER_ANIMATION_TIME:Number = .3;
		
		private var audio_control_icon:DisplayObject;
		private var audio_control_icon_mask:Sprite;
		private var audio_control_holder:Sprite;
		private var audio_control_holder_mask:Sprite;
		
		private var sfx_icon:DisplayObject;
		private var sfx_icon_holder:Sprite;
		private var music_icon:DisplayObject;
		private var music_icon_holder:Sprite;
		private var mute_panel:Sprite;
		
		private var sfx_slider:TSSlider;
		private var music_slider:TSSlider;
		private var mute_cb:Checkbox;
		
		private var icon_loc_pt:Point = new Point();
		private var zero_pt:Point = new Point();
		
		private var sfx_positive:Number;
		private var music_positive:Number;
		
		private var open_timer:Timer = new Timer(300); //stay open a little bit after the mouse leaves in case they come back
		private var is_open:Boolean = false;
		
		private var model:TSModelLocator;
		
		public function AudioControl(){}
		
		public function init():void {
			model = TSModelLocator.instance;
			
			//icon
			audio_control_icon = new AssetManager.instance.assets.audio_control_icon();
			addChild(audio_control_icon);
			
			//icon mask
			audio_control_icon_mask = new Sprite();
			audio_control_icon_mask.graphics.beginFill(0x000000);
			audio_control_icon_mask.graphics.drawRect(0, 0, 34, 34);
			audio_control_icon_mask.useHandCursor = audio_control_icon_mask.buttonMode = true;
			audio_control_icon_mask.addEventListener(MouseEvent.ROLL_OVER, onRollOver, false, 0, true);
			audio_control_icon_mask.addEventListener(MouseEvent.ROLL_OUT, onRollOut, false, 0, true);
			audio_control_icon_mask.addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			audio_control_icon_mask.x = int(audio_control_icon.width/2 - audio_control_icon_mask.width/2);
			TipDisplayManager.instance.registerTipTrigger(audio_control_icon_mask);
			
			audio_control_icon.mask = audio_control_icon_mask;
			addChild(audio_control_icon_mask);
			
			//background
			audio_control_holder = new Sprite();
			audio_control_holder.graphics.beginFill(model.layoutModel.bg_color);
			audio_control_holder.graphics.drawRoundRect(0, 0, HOLDER_WIDTH, HOLDER_HEIGHT, 10);
			audio_control_holder.y = audio_control_icon_mask.y + audio_control_icon_mask.height + 1;
			
			StageBeacon.game_parent.addChild(audio_control_holder);
			
			//background mask
			audio_control_holder_mask = new Sprite();
			audio_control_holder_mask.graphics.beginFill(0x000000, .5);
			audio_control_holder_mask.graphics.drawRect(0, 0, audio_control_holder.width, audio_control_holder.height - 5);
			audio_control_holder_mask.y = audio_control_holder.y + 5;
			
			audio_control_holder.mask = audio_control_holder_mask;
			StageBeacon.game_parent.addChild(audio_control_holder_mask);
			audio_control_holder.y = audio_control_icon_mask.y + audio_control_icon_mask.height - audio_control_holder.height;
			
			//volume sliders
			constructSliders();
			
			//sfx icon
			sfx_icon = new AssetManager.instance.assets.audio_sfx();
			sfx_icon.x = int(sfx_slider.x + sfx_slider.width/2 - sfx_icon.width/2);
			sfx_icon.y = sfx_slider.y + sfx_slider.height + 10;
			audio_control_holder.addChild(sfx_icon);
			
			//sfx clicker
			sfx_icon_holder = new Sprite();
			sfx_icon_holder.graphics.beginFill(0x000000, 0);
			sfx_icon_holder.graphics.drawRect(sfx_icon.x - 5, sfx_icon.y - 5, sfx_icon.width + 10, sfx_icon.height + 10);
			sfx_icon_holder.addEventListener(MouseEvent.CLICK, toggleSlider, false, 0, true);
			sfx_icon_holder.buttonMode = sfx_icon_holder.useHandCursor = true;
			audio_control_holder.addChild(sfx_icon_holder);
			
			//music icon
			music_icon = new AssetManager.instance.assets.audio_music();
			music_icon.x = int(music_slider.x + music_slider.width/2 - music_icon.width/2);
			music_icon.y = music_slider.y + music_slider.height + 10;
			audio_control_holder.addChild(music_icon);
			
			//music clicker
			music_icon_holder = new Sprite();
			music_icon_holder.graphics.beginFill(0x000000, 0);
			music_icon_holder.graphics.drawRect(music_icon.x - 5, music_icon.y - 5, music_icon.width + 10, music_icon.height + 10);
			music_icon_holder.addEventListener(MouseEvent.CLICK, toggleSlider, false, 0, true);
			music_icon_holder.buttonMode = music_icon_holder.useHandCursor = true;
			audio_control_holder.addChild(music_icon_holder);
			
			mute_panel = new Sprite();
			mute_panel.x = 14;
			mute_panel.y = HOLDER_HEIGHT-24;
			
			mute_cb = new Checkbox({
				graphic: new AssetManager.instance.assets.cb_unchecked(),
				graphic_checked: new AssetManager.instance.assets.cb_checked(),
				x: 0,
				y: 0,
				w:18,
				h:18,
				checked: LocalStorage.instance.getUserData(LocalStorage.IS_SOUND_MUTED),
				label: 'Mute',
				name: 'mute_cb'
			});
			mute_cb.addEventListener(TSEvent.CHANGED, onMuteToggle, false, 0, true);
			
			//if we are already muted, make sure the icon is proper
			if(mute_cb.checked){
				audio_control_icon.y  = - audio_control_icon_mask.height*3;
			}
			
			mute_panel.addChild(mute_cb);
			audio_control_holder.addChild(mute_panel);
			
			//place things where they need to go
			TSFrontController.instance.registerRefreshListener(this);
			refresh();
		}
		
		public function refresh():void {
			icon_loc_pt = audio_control_icon.localToGlobal(zero_pt);
			audio_control_holder.x = int(audio_control_icon.width/2 - audio_control_holder.width/2 + icon_loc_pt.x);
			audio_control_holder_mask.x = audio_control_holder.x;
		}
		
		private function onClick(event:Event):void {
			/* Toggle to mute code
			SoundMaster.instance.isSoundMuted = !SoundMaster.instance.isSoundMuted;
			updateSliders();
			updateIcon();
			*/
			
			var sfx_volume:Number = Number(sfx_slider.value.toFixed(2));
			var music_volume:Number = Number(music_slider.value.toFixed(2));
			var newY:int = model.layoutModel.header_h - 5;
			var trans:String = 'easeOutCubic';
			audio_control_holder_mask.y = newY + 5;
			
			//toggle the audio controls
			if(is_open){ 
				newY = audio_control_icon_mask.y + audio_control_icon_mask.height - audio_control_holder.height
				trans = 'easeInCubic';
				StageBeacon.mouse_click_sig.remove(checkClick);
				StageBeacon.key_down_sig.remove(onClick);
				StageBeacon.mouse_leave_sig.remove(onClick);
				
				onHolderOver(event);
				
				//save the audio levels to the local storage
				SoundMaster.instance.saveAudioLevels(sfx_volume, music_volume);
			}else{
				StageBeacon.mouse_click_sig.add(checkClick);
				StageBeacon.key_down_sig.add(onClick);
				StageBeacon.mouse_leave_sig.add(onClick);
			}
			
			//animate it
			TSTweener.addTween(audio_control_holder, {y:newY, time:HOLDER_ANIMATION_TIME, transition:trans});
			
			is_open = !is_open;
		}
		
		private function checkClick(event:MouseEvent):void {
			//if they clicked anywhere other than the audio control, hide it
			var points:Array = StageBeacon.game_parent.getObjectsUnderPoint(new Point(event.stageX, event.stageY));
			if(points.indexOf(audio_control_holder) == -1){
				//if it wasn't on the icon itself, send the event to fold it away
				if(points.indexOf(audio_control_icon_mask) == -1) onClick(event);
			} 
		}
		
		private function updateIcon():void {
			var sfx_volume:Number = Number(sfx_slider.value.toFixed(2));
			var music_volume:Number = Number(music_slider.value.toFixed(2));
			//var avg_volume:int = (sfx_volume*100 + music_volume*100)/2; //if we ever want the icon to be an average vs. just the highest one
			var avg_volume:int = sfx_volume*100;
			if(music_volume*100 > avg_volume) avg_volume = music_volume*100;
			
			if(avg_volume >= 65){
				audio_control_icon.y  = 0;
			}else if(avg_volume < 65 && avg_volume >= 33){
				audio_control_icon.y  = - audio_control_icon_mask.height;
			}else if(avg_volume < 33 && avg_volume > 0){
				audio_control_icon.y  = - audio_control_icon_mask.height*2;
			}else{
				audio_control_icon.y  = - audio_control_icon_mask.height*3;
			}
			
			CONFIG::debugging {
				Console.trackValue("AC Average", avg_volume);
			}
		}
		
		private function constructSliders():void {
			var sfx_volume:Number = SoundMaster.instance.sfx_volume;
			var music_volume:Number = SoundMaster.instance.music_volume;
			
			sfx_positive = (sfx_volume == 0) ? SoundManager.DEFAULT_SFX_VOLUME : sfx_volume;
			music_positive = (music_volume == 0) ? SoundManager.DEFAULT_MUSIC_VOLUME : music_volume;
			
			//sfx
			sfx_slider = new TSSlider(TSSlider.VERTICAL, audio_control_holder, 18, 15);
			sfx_slider.backClick = true;
			sfx_slider.setSliderParams(0, 1, sfx_volume);
			sfx_slider.addEventListener(Event.CHANGE, onSliderChange, false, 0, true);
			
			//music
			music_slider = new TSSlider(TSSlider.VERTICAL, audio_control_holder, 51, 15);
			music_slider.backClick = true;
			music_slider.setSliderParams(0, 1, music_volume);
			music_slider.addEventListener(Event.CHANGE, onSliderChange, false, 0, true);
			
			updateIcon();
		}
		
		private function onSliderChange(event:Event):void {
			var slider:TSSlider = event.currentTarget as TSSlider;
			var value:Number = Number(slider.value.toFixed(2));
			
			if(slider == sfx_slider){
				SoundMaster.instance.sfx_volume = value;
			}else{
				SoundMaster.instance.music_volume = value;
			}
			
			//calculate the overall volume for the audio icon
			updateIcon();
			
			//uncheck the mute
			if(mute_cb.checked) mute_cb.checked = false;
		}
		
		private function toggleSlider(event:MouseEvent):void {
			var volume:Number;
			
			if(event.currentTarget == sfx_icon_holder){
				volume = sfx_slider.value;
				
				if(volume > 0 && !isNaN(volume)) sfx_positive = volume;
				(volume == 0) ? sfx_slider.value = sfx_positive : sfx_slider.value = 0;
				
				SoundMaster.instance.sfx_volume = sfx_slider.value;
			}else{
				volume = music_slider.value;
				
				if(volume > 0 && !isNaN(volume)) music_positive = volume;
				(volume == 0) ? music_slider.value = music_positive : music_slider.value = 0;
								
				SoundMaster.instance.music_volume = music_slider.value;
			}
			
			updateIcon();
		}
		
		private function updateSliders():void {
			var isMuted:Boolean = SoundMaster.instance.isSoundMuted;
			var sfx_volume:Number = Number(sfx_slider.value.toFixed(2));
			var music_volume:Number = Number(music_slider.value.toFixed(2));
			
			//if the sliders are anything above 0 we need to remember them for the session for any fancy mute toggling
			if(sfx_volume > 0 && !isNaN(sfx_volume)) sfx_positive = sfx_volume;
			if(music_volume > 0 && !isNaN(music_volume)) music_positive = music_volume;
			
			if(isMuted){
				sfx_volume = 0;
				music_volume = 0;
			}else{
				sfx_volume = sfx_positive;
				music_volume = music_positive;
			}
			
			if(isNaN(sfx_volume)) sfx_volume = SoundManager.DEFAULT_SFX_VOLUME;
			if(isNaN(music_volume)) music_volume = SoundManager.DEFAULT_MUSIC_VOLUME;
			
			sfx_slider.value = sfx_volume;
			music_slider.value = music_volume;
			
			SoundMaster.instance.sfx_volume = sfx_volume;
			SoundMaster.instance.music_volume = music_volume;
		}
		
		private function onRollOver(event:MouseEvent):void {			
			if(open_timer.running){
				open_timer.stop();
				open_timer.removeEventListener(TimerEvent.TIMER, onTimer);
			}
		}
		
		private function onRollOut(event:MouseEvent):void {
			//delay the closing of the menu
			if(!is_open) return;
			
			if(!open_timer.hasEventListener(TimerEvent.TIMER)){
				open_timer.addEventListener(TimerEvent.TIMER, onTimer, false, 0, true);
			}
			open_timer.start();
			audio_control_holder.addEventListener(MouseEvent.ROLL_OVER, onHolderOver, false, 0, true);
			audio_control_holder.addEventListener(MouseEvent.ROLL_OUT, onHolderOut, false, 0, true);
		}
				
		private function onHolderOver(event:Event):void {
			open_timer.stop();
			open_timer.removeEventListener(TimerEvent.TIMER, onTimer);
		}
		
		private function onHolderOut(event:MouseEvent):void {
			open_timer.start();
			open_timer.addEventListener(TimerEvent.TIMER, onTimer, false, 0, true);
		}
		
		private function onTimer(event:TimerEvent):void {
			onClick(event);
			open_timer.stop();
			open_timer.reset();
			open_timer.removeEventListener(TimerEvent.TIMER, onTimer);
			
			//once it's closed, save the data if it's new
			var sfx_volume:Number = Number(sfx_slider.value.toFixed(2));
			var music_volume:Number = Number(music_slider.value.toFixed(2));
			
			if(SoundMaster.instance.sfx_volume != sfx_volume || SoundMaster.instance.music_volume != music_volume){
				//save the audio levels to the local storage
				SoundMaster.instance.saveAudioLevels(sfx_volume, music_volume);
			}
		}
		
		private function onMuteToggle(event:TSEvent):void {
			SoundMaster.instance.muteAllSounds(mute_cb.checked);
			
			//update the icon
			if(mute_cb.checked){
				audio_control_icon.y  = - audio_control_icon_mask.height*3;
			}
			else {
				updateIcon();
			}
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target || is_open) return null;
			
			return {
				txt: '<p class="audio_control_tip">Change volume<br>'+
					 '<span class="audio_control_tip_percs">Effects: '+int(sfx_slider.value * 100)+'%   Music: '+int(music_slider.value * 100)+'%</span></p>',
				pointer: WindowBorder.POINTER_TOP_CENTER,
				offset_y: 1
			}
		}
		
		public function getVolumeIconBasePt():Point {
			return audio_control_icon_mask.localToGlobal(new Point(audio_control_icon_mask.width/2, audio_control_icon_mask.height));
		}
		
		public function get icon():Sprite {
			return audio_control_icon_mask;
		}
	}
}