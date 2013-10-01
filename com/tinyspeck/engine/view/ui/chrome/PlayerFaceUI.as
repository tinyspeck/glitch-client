package com.tinyspeck.engine.view.ui.chrome
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.data.AvatarAnimationDefinitions;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.pc.AvatarConfig;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.spritesheet.AvatarSSManager;
	import com.tinyspeck.engine.spritesheet.SSViewSprite;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.PlayerFaceRays;
	import com.tinyspeck.engine.view.ui.Rays;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.ColorMatrixFilter;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.text.TextField;

	public class PlayerFaceUI extends TSSpriteWithModel
	{
		private static const WH:uint = 73;
		private static const SCALE:Number = .8; //how much to reduce the ss_options.scale by
		private static const RAYS_ALPHA:Number = .8;
		private static const CROSSFADE_TIME:Number = .2;
		
		private static const gradient_colors:Array = 
			[
				[0x6bcddb, 0xd6f7d2], //90-100%
				[0x64d2ad, 0xdaf5bc], //80-89%
				[0xcac97e, 0xeae8ca], //70-79%
				[0xb0734b, 0xd3a696], //20-69%
				[0x644849, 0x6d5353], //1-19%
				[0x4f4a4a, 0x7c7a7a] //0%
			];
		private static const ava_swf_frame_nums:Array = 
			[
				415, //90-100%
				473, //80-89%
				801, //70-79%
				690, //20-69%
				688, //1-19%
				522 //0%
			];
		private static const mood_matrix:Array = 
			[
				1,0,0,0,0,
				0,1,0,0,0,
				0,0,1,0,0,
				0,0,0,1,0
			];
		private static const low_mood_matrix:Array = 
			[
				.6,.25,.15,0,0,
				.15,.6,.25,0,0,
				.25,.15,.6,0,0,
				0,0,0,1,0
			];
		private static const dead_matrix:Array = 
			[
				.3,.6,.1,0,0,
				.3,.6,.1,0,0,
				.3,.6,.1,0,0,
				0,0,0,1,0
			];
		private static const avatar_filter:ColorMatrixFilter = new ColorMatrixFilter();
		private static const avatar_filterA:Array = [avatar_filter];
		private static const gradient_matrix:Matrix = new Matrix();
		private static const gradient_alphas:Array = [1,1];
		private static const gradient_ratios:Array = [0,255];
		
		private var masker:Sprite = new Sprite();
		private var holder:Sprite = new Sprite();
		private var avatar_holder:Sprite = new Sprite();
		private var stats_holder:Sprite = new Sprite();
		private var rain_holder:Sprite = new Sprite();
		
		private var hashed_outline:DisplayObject;
		
		private var perc_tf:TextField = new TextField();
		private var mood_tf:TextField = new TextField();
		
		private var current_state_index:int = -1;
		private var roll_timeout:uint = 0;
		
		private var inner_glow:GlowFilter = new GlowFilter();
		private var inner_shadow:DropShadowFilter = new DropShadowFilter();
		private var outter_shadow:DropShadowFilter = new DropShadowFilter();
		private var perc_shadow:DropShadowFilter = new DropShadowFilter();
		
		private var ss_view:SSViewSprite;
		private const rays:DisplayObject = new PlayerFaceRays();
		
		private var is_built:Boolean;
		private var is_forced:Boolean;
		
		public function PlayerFaceUI(){}
		
		private function buildBase():void {
			var g:Graphics = masker.graphics;
			g.beginFill(0);
			g.drawCircle(WH/2, WH/2, WH/2);
			addChild(masker);
			
			holder.mask = masker;
			holder.addChild(avatar_holder);
			avatar_holder.x = 10;
			avatar_holder.y = 8;
			addChild(holder);
			
			//add the rays to the holder
			rays.x = -18;
			rays.y = -18;
			rays.alpha = RAYS_ALPHA;
			holder.addChildAt(rays, 0);
			
			//add the rain to the holder
			const rain:MovieClip = new AssetManager.instance.assets.avatar_rain();
			rain_holder.addChild(rain);
			rain_holder.x = -20;
			rain_holder.y = -10;
			holder.addChild(rain_holder);
			
			//filters
			inner_glow.inner = true;
			inner_glow.color = 0;
			inner_glow.alpha = .15;
			inner_glow.blurX = inner_glow.blurY = 2;
			
			inner_shadow.inner = true;
			inner_shadow.angle = 90;
			inner_shadow.alpha = .2;
			inner_shadow.blurX = inner_shadow.blurY = 5;
			inner_shadow.distance = 2;
			
			outter_shadow.color = 0xffffff;
			outter_shadow.angle = 90;
			outter_shadow.alpha = .55;
			outter_shadow.distance = 3;
			outter_shadow.blurX = outter_shadow.blurY = 0;
			
			filters = [inner_glow, inner_shadow, outter_shadow];
			
			//make a vertical grad
			gradient_matrix.createGradientBox(WH, WH, Math.PI/2, 0, 0);
			
			//mouse stuff
			addEventListener(MouseEvent.ROLL_OVER, onRollOver, false, 0, true);
			addEventListener(MouseEvent.ROLL_OUT, onRollOut, false, 0, true);
			useHandCursor = buttonMode = true;
			mouseChildren = false;
			
			//tfs
			perc_shadow.angle = 90;
			perc_shadow.alpha = .4;
			perc_shadow.distance = 1;
			perc_shadow.blurX = perc_shadow.blurY = 2;
			
			TFUtil.prepTF(perc_tf);
			perc_tf.width = WH;
			perc_tf.y = 16;
			perc_tf.filters = [perc_shadow];
			stats_holder.addChild(perc_tf);
			
			TFUtil.prepTF(mood_tf);
			mood_tf.width = WH;
			mood_tf.y = 28;
			mood_tf.alpha = .5;
			stats_holder.addChild(mood_tf);
			
			stats_holder.alpha = 0;
			addChild(stats_holder);
			
			is_built = true;
		}
		
		public function show():void {
			if(!is_built) buildBase();
			updateMoodDisplay();
			addAvatar();
		}
		
		public function addAvatar():void {
			//get the avatar SS
			const pc:PC = model.worldModel.pc;
			if (model.moveModel.moving || !pc) {
				StageBeacon.setTimeout(addAvatar, 1000);
				return;
			}
			
			if (ss_view) {
				ss_view.dispose();
			}
			
			ss_view = AvatarSSManager.getSSForAva(pc.ac, pc.sheet_url, onAvaAssetsRdy).getViewSprite();
			placeNewAvatar();
		}
		
		// this only gets called when the initial call to AvatarSSManager.getSSForAva returned the default ss
		// because the assets were not yet fully loaded, and &SWF_use_default_ava != 1
		private function onAvaAssetsRdy(ac:AvatarConfig):void {
			const pc:PC = model.worldModel.pc;
			
			if (ss_view) {
				ss_view.dispose();
			}
			
			ss_view = AvatarSSManager.getSSForAva(pc.ac, pc.sheet_url).getViewSprite();
			placeNewAvatar();
		}
		
		private function placeNewAvatar():void {
			ss_view.scaleX = ss_view.scaleY = SCALE;
			avatar_holder.addChild(ss_view);
			setAvatarDisplayState();
		}
		
		public function updateMoodDisplay():void {
			const pc:PC = model.worldModel.pc;
			if(!pc || !pc.stats) return;
			
			const mood_perc:Number = pc.stats.mood.value/pc.stats.mood.max;
			
			var state_index:int;
			if(pc.is_dead){
				state_index = 5;
			}
			else if(mood_perc >= .9){
				state_index = 0;
			}
			else if(mood_perc >= .8){
				state_index = 1;
			}
			else if(mood_perc >= .7){
				state_index = 2;
			}
			else if(mood_perc >= .2){
				state_index = 3;
			}
			else {
				state_index = 4;
			}
			
			//if we are at 100% (because of rounding) but we aren't at max, just make it 99%
			var perc_amount:int = Math.ceil(mood_perc*100);
			if(perc_amount == 100 && pc.stats.mood.value < pc.stats.mood.max){
				perc_amount = 99;
			}
			
			//set the mood
			var perc_txt:String = perc_amount+'<span class="player_face_perc">%</span>';
			var mood_txt:String = pc.stats.mood.value+'/'+pc.stats.mood.max;
			if(state_index == 5){
				//they be dead!
				perc_txt = '<span class="player_face_dead">Dead</span>';
				mood_txt = 'That sucks';
			}
			perc_tf.htmlText = '<p class="player_face">'+perc_txt+'</p>';
			mood_txt = '<span class="'+(state_index < 4 ? 'player_face_mood' : 'player_face_mood_low')+'">'+mood_txt+'</span>';
			mood_tf.htmlText = '<p class="player_face">'+mood_txt+'</p>';
			mood_tf.filters = state_index < 4 ? StaticFilters.white1px90Degrees_DropShadowA : null;
			stats_holder.y = state_index != 5 ? -2 : -5;
			
			//show the % for a few secs and then bring it back
			onRollOver();
			if(roll_timeout) StageBeacon.clearTimeout(roll_timeout);
			roll_timeout = StageBeacon.setTimeout(onRollOut, 3000);
			
			//no need to redraw this
			if (current_state_index == state_index) {
				return;
			}
			
			current_state_index = state_index;
			
			//we showing the rays?
			rays.visible = current_state_index < 2;
			
			//how about the rain?
			rain_holder.visible = current_state_index == 4;
			
			//apply a filter to the avatar
			if(current_state_index == 5){
				//dead
				avatar_filter.matrix = dead_matrix;
			}
			else if(current_state_index == 4){
				//low mood
				avatar_filter.matrix = low_mood_matrix;
			}
			else {
				//normal
				avatar_filter.matrix = mood_matrix;
			}
			
			//refresh the filters
			avatar_holder.filters = avatar_filterA;
			
			//figure out the mood so we know how to draw things
			var g:Graphics = holder.graphics;
			g.clear();
			g.beginGradientFill(GradientType.LINEAR, gradient_colors[current_state_index], gradient_alphas, gradient_ratios, gradient_matrix);
			g.drawCircle(WH/2, WH/2, WH/2);
			
			setAvatarDisplayState();
		}
		
		private function setAvatarDisplayState():void {
			if (!ss_view) {
				return;
			}
			
			const pc:PC = model.worldModel.pc;
			if(!pc) return;
			
			if (current_state_index >= ava_swf_frame_nums.length) {
				CONFIG::debugging {
					Console.error('current_state_index:'+current_state_index+' is out of range in ava_swf_frame_nums which is this length:'+ava_swf_frame_nums.length);
				}
				return;
			}
			
			//figure out which frame/label
			var swf_frame_number:int = ava_swf_frame_nums[current_state_index];
			
			var anim:String = AvatarAnimationDefinitions.getAnyAnimThatContainsSWFFrameNum(swf_frame_number);
			if (!anim) {
				CONFIG::debugging {
					Console.error('no anim for swf_frame_number:'+swf_frame_number);
				}
				return;
			}
			
			var anim_frame:int = AvatarAnimationDefinitions.getFramesForAnim(anim).indexOf(swf_frame_number);
			
			CONFIG::debugging {
				Console.info('swf_frame_number:'+swf_frame_number+' anim:'+anim+' anim_frame:'+anim_frame);
			}
			
			AvatarSSManager.playSSViewForAva(pc.ac, pc.sheet_url, ss_view, ss_view.gotoAndStop, anim_frame, anim);
		}
		
		private function onRollOver(event:MouseEvent = null):void {
			if(is_forced) return;
			
			//fade out the avatar and show the energy amount/%
			TSTweener.addTween(avatar_holder, {alpha:.1, time:CROSSFADE_TIME, transition:'linear'});
			TSTweener.addTween(stats_holder, {alpha:1, time:CROSSFADE_TIME, transition:'linear'});
		}
		
		private function onRollOut(event:MouseEvent = null):void {
			if(is_forced) return;
			
			//bring back the avatar
			TSTweener.addTween(avatar_holder, {alpha:1, time:CROSSFADE_TIME, transition:'linear'});
			TSTweener.addTween(stats_holder, {alpha:0, time:CROSSFADE_TIME, transition:'linear'});
			roll_timeout = 0;
		}
		
		public function set force_show_mood(value:Boolean):void {
			if(value) {
				onRollOver();
				is_forced = true;
			}
			else {
				is_forced = false;
				onRollOut();
			}
		}
		
		/**
		 * This will hide everything except a hashed circle where the face should be 
		 * @param value
		 */		
		public function set hide_face(value:Boolean):void {
			useHandCursor = buttonMode = !value;
			mouseEnabled = !value;
			holder.visible = !value;
			stats_holder.visible = !value;
			
			if(value && !hashed_outline){
				//load up the outline
				hashed_outline = new AssetManager.instance.assets.player_face_empty();
				hashed_outline.x = 1;
				hashed_outline.y = 1;
			}
			
			//add the outline if we are hiding stuff
			if(value) {
				addChildAt(hashed_outline, 0);
			}
			else {
				//if we are showing it, let's fade it in all nice
				holder.alpha = 0;
				TSTweener.addTween(holder, {alpha:1, time:.5, transition:'linear',
					onComplete:function():void {
						if(hashed_outline && hashed_outline.parent){
							hashed_outline.parent.removeChild(hashed_outline);
						}
					}
				});
			}
			
		}
		
		override public function get width():Number { return WH; }
		override public function get height():Number { return WH; }
	}
}