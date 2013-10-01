package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.data.reward.Rewards;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Slug;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Scene;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	// http://svn.tinyspeck.com/wiki/Level_up_sequence
	
	public class LevelUpView extends BaseScreenView {
		
		/* singleton boilerplate */
		public static const instance:LevelUpView = new LevelUpView();
		
		private const MAX_WORDS_DISPLAYED:uint = 4; //WORD_POINTS needs to have this many points
		private const WORD_POINTS:Array = new Array(new Point(-60,630), new Point(200,620), new Point(-80,830), new Point(270,850));
		private const OK_BUTTON_Y:int = 415;
		
		private var shelf_holder:Sprite = new Sprite();
		private var slugs_holder:Sprite = new Sprite();
		
		private var level_tf:TextField = new TextField();
		private var level_num_tf:TextField = new TextField();
		
		private var ok_bt:Button;
		private var shelf:DisplayObject = new AssetManager.instance.assets.shelf_level();
		private var badge_holder:Sprite = new Sprite();
		private var scene_index:int;
		private var word_scenes:Array;
		private var rewards:Vector.<Reward>;
		
		private var animating:Boolean;
		
		public function LevelUpView() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		override protected function buildBase():void {
			super.buildBase();
						
			//get color/alpha from CSS
			bg_color = CSSManager.instance.getUintColorValueFromStyle('level_up_bg', 'color', 0xa0b6c5);
			bg_alpha = CSSManager.instance.getNumberValueFromStyle('level_up_bg', 'alpha', .9);
			
			//place the shelf
			shelf_holder.addChild(shelf);
			shelf_holder.addChild(badge_holder);
			
			all_holder.addChild(shelf_holder);
			
			//textfields
			level_tf.selectable = level_num_tf.selectable = false;
			level_tf.embedFonts = level_num_tf.embedFonts = true;
			level_tf.antiAliasType = level_num_tf.antiAliasType = AntiAliasType.ADVANCED;
			level_tf.autoSize = level_num_tf.autoSize = TextFieldAutoSize.LEFT;
			level_tf.styleSheet = level_num_tf.styleSheet = CSSManager.instance.styleSheet;
			level_tf.htmlText = '<p class="level_up">Level</p>';
			
			badge_holder.addChild(level_tf);
			badge_holder.addChild(level_num_tf);
			
			ok_bt = new Button({
				label: 'Sweet sweetness...',
				name: '_done_bt',
				value: 'done',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_DEFAULT
			});
			ok_bt.x = int(shelf.width/2 - ok_bt.width/2);
			ok_bt.y = OK_BUTTON_Y;
			ok_bt.filters = StaticFilters.white4px40AlphaGlowA;
			
			all_holder.addChild(ok_bt);
			
			ok_bt.addEventListener(MouseEvent.CLICK, onOkClick, false, 0, true);
			
			//slugs
			all_holder.addChild(slugs_holder);
			
			//load the badge
			const badge_loader:MovieClip = new AssetManager.instance.assets.level_up_badge();
			badge_loader.addEventListener(Event.COMPLETE, placeBadge, false, 0, true);
			
			//handle the words
			var i:int;
			var words_loader:MovieClip
			for(i; i < MAX_WORDS_DISPLAYED; i++){
				words_loader = new AssetManager.instance.assets.level_up_words();
				words_loader.addEventListener(Event.COMPLETE, placeWords, false, 0, true);
			}
			
			//handle the rays
			loadRays();
			rays.x = -190;
			rays.y = shelf.height - 433;
			
			is_built = true;
		}
		
		private function placeBadge(event:Event):void {
			const badge:MovieClip = Loader(event.target.getChildAt(0)).content as MovieClip;
			
			if(!badge){
				CONFIG::debugging {
					Console.warn('SOMETHING WRONG WITH THE BADGE!');
				}
				return;
			}
			
			//put it in the holder
			badge_holder.addChildAt(badge, 0);
		}
		
		private function placeWords(event:Event):void {
			const word:MovieClip = Loader(event.target.getChildAt(0)).content as MovieClip;
			word.gotoAndStop(1, Scene(word.scenes[0]).name);
			
			shelf_holder.addChild(word);
		}
		
		override protected function onDoneTweenComplete():void {
			super.onDoneTweenComplete();
			shelf_holder.removeChild(rays);
			animating = false;
		}
		
		override protected function draw():void {
			super.draw();
			
			//center the stuff
			all_holder.x = model.layoutModel.gutter_w + int(draw_w/2 - shelf.width/2);
			all_holder.y = int(model.layoutModel.loc_vp_h/2 - shelf.height/2) + 250;
		}
		
		// SHOULD ONLY EVER BE CALLED FROM TSFrontController.instance.tryShowScreenViewFromQ();
		public function show(payload:Object):Boolean {
			if(!super.makeSureBaseIsLoaded()) return false;
			
			var level_num:int = payload.stats.level;
			
			//setup rewards
			rewards = new Vector.<Reward>();
			if(payload.rewards){
				rewards = Rewards.fromAnonymous(payload.rewards);
			}
			
			displaySlugs();
			
			//set up the look on the badge
			level_tf.x = int(badge_holder.width/2 - level_tf.width/2);
			level_tf.y = 35;
			
			level_num_tf.htmlText = '<p class="level_up_num"><font size="20">'+level_num+'</font></p>';
			level_num_tf.scaleX = level_num_tf.scaleY = 7;
			level_num_tf.x = int(badge_holder.width/2 - level_num_tf.width/2);
			level_num_tf.y = int(level_tf.y + level_tf.height) - 45;
			
			//since flash textfields suck so much ass...
			if(level_num < 10) {
				level_num_tf.x -= 3;
			}
			else if(level_num >= 10 && level_num < 20) { 
				level_num_tf.x -= 5;
			}	
			else if(level_num >= 20 && level_num < 30) { 
				level_num_tf.x -= 7;
			}
			else if(level_num >= 30 && level_num < 40) { 
				level_num_tf.x -= 6;
			}
			else if(level_num >= 40 && level_num < 50) { 
				level_num_tf.x -= 8;
			}
			else {
				level_num_tf.x -= 4
			}
			
			//set the stuff
			draw();
			animate();
			
			return tryAndTakeFocus(payload);
		}
		
		override protected function animate():void {
			var final_y:int = 365 - shelf.height;
			var i:int;
			var current:int;
			var mc:MovieClip;
			var child:DisplayObject;
			var slug:Slug;
			var offset:int = 40;
			
			animating = true;
			
			//fade in
			super.animate();
			
			//animate the shelf
			shelf_holder.y = -shelf.height - model.layoutModel.header_h;
			badge_holder.x = int(shelf.width/2 - badge_holder.width/2);
			badge_holder.y = int(shelf.height - badge_holder.height) - 20;
			TSTweener.addTween(shelf_holder, {y:final_y, time:1.5, transition:'easeOutBounce'});
			
			//place the rays behind the shelf
			shelf_holder.addChildAt(rays, 0);
			
			//words
			scene_index = 0;
			word_scenes = null;
			
			for(i = 0; i < shelf_holder.numChildren; i++){
				child = shelf_holder.getChildAt(i);
				if(child != rays && child != shelf && child != badge_holder){
					mc = child as MovieClip;
					if(!word_scenes) word_scenes = SortTools.shuffleArray(mc.scenes);
					
					mc.x = Point(WORD_POINTS[current]).x;
					mc.y = Point(WORD_POINTS[current]).y;
					mc.alpha = 0;
					TSTweener.addTween(mc, {time:0, delay:1.5 + (current * .5), onComplete:nextWord, onCompleteParams:[mc]});
					current++;
				}
			}
			
			//slugs
			for(i = 0; i < slugs_holder.numChildren; i++){
				slug = slugs_holder.getChildAt(i) as Slug;
				final_y = slug.y;
				slug.alpha = 0;
				slug.y += offset;
				TSTweener.addTween(slug, {y:final_y, alpha:1, time:.3, delay:1 + (i * .2), transition:'easeOutBounce'});
			}
			
			//button
			ok_bt.alpha = 0;
			TSTweener.addTween(ok_bt, {alpha:1, time:.5, delay:1.2, transition:'linear'});
		}
		
		private function displaySlugs():void {
			SpriteUtil.clean(slugs_holder);
			
			//throws the slugs in the holder and centers them
			var next_x:int;
			var padd:int = 4;
			var i:int;
			var total:int = rewards.length;
			var slug:Slug;
			
			for(i; i < total; i++){
				if(rewards[int(i)].amount != 0){
					slug = new Slug(rewards[int(i)]);
					slug.x = next_x;
					next_x += int(slug.width + padd);
					slugs_holder.addChild(slug);
				}
			}
			
			//center
			slugs_holder.x = ok_bt.x + int(ok_bt.width/2 - slugs_holder.width/2);
			slugs_holder.y = int(ok_bt.y - slugs_holder.height) - 10;
		}
		
		private function nextWord(mc:MovieClip):void {
			if(animating){				
				//timing vars
				var rotation_min:int = -15;
				var rotation_max:int = 15;
				var scale_min:Number = .5;
				var scale_max:Number = 1;
				var time_min:Number = 1.7;
				var time_max:Number = 2.2;
				var child:MovieClip;
				
				//setting up randoms
				var rotation_start:int = rotation_min + Math.round(Math.random()*(rotation_max-rotation_min));
				var rotation_end:int = rotation_min + Math.round(Math.random()*(rotation_max-rotation_min));
				var scale:Number = scale_min + Math.random()*(scale_max-scale_min);
				var time:Number = time_min + Math.random()*(time_max-time_min);
				
				//make sure we have a good scene
				if(!word_scenes[scene_index]) scene_index = 0;
				
				//set the word
				mc.gotoAndStop(1, Scene(word_scenes[scene_index]).name);
				child = mc.getChildAt(0) as MovieClip;
				child.scaleX = child.scaleY = 0;
				child.rotation = rotation_start;
				
				//animate
				TSTweener.addTween(mc, {alpha:1, time:.5, transition:'linear'});
				TSTweener.addTween(child, {scaleX:scale, scaleY:scale, rotation:rotation_end, time:time, transition:'easeOutElastic', onComplete:nextWord, onCompleteParams:[mc]});
				TSTweener.addTween(mc, {alpha:0, time:.5, delay:time-.5});
				
				scene_index++;
			}
			else {
				TSTweener.removeTweens(mc);
			}
		}
	}
}