package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.data.client.WordProgress;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.IAnnouncementArtView;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;

	public class WordProgressBar extends Sprite implements IAnnouncementArtView
	{
		private static const FILL_NAME:String = 'fill_mc'; //fill of the word must have this as it's instance name
		private static const SCALE:Number = 1;
		
		private static var word_progress_mc:MovieClip; //only grab one and get assets when we need them
		
		private var cancel_bt:Button;
		
		private var word_holder:Sprite = new Sprite();
		private var current_word:MovieClip;
		private var bg_matrix:Matrix = new Matrix();
		private var current_progress:WordProgress;
		
		private var limit:int;
		private var current_round:int;
		private var animation_speed:Number;
		
		private var is_built:Boolean;
		
		public function WordProgressBar(){
			//load the asset straight away if it's not already loaded
			if(!word_progress_mc){
				const word_progress_loader:MovieClip = new AssetManager.instance.assets.word_progress_bar();
				word_progress_loader.addEventListener(Event.COMPLETE, onAssetLoaded, false, 0, true);
			}
			word_holder.scaleX = word_holder.scaleY = SCALE;
		}
		
		private function buildBase():void {
			//word holder
			addChild(word_holder);
			
			//cancel
			const cancel_DO:DisplayObject = new AssetManager.instance.assets.word_dismisser_cancel();
			cancel_bt = new Button({
				name: 'cancel',
				draw_alpha: 0,
				graphic: cancel_DO,
				graphic_hover: new AssetManager.instance.assets.word_dismisser_cancel_hover(),
				w: cancel_DO.width,
				h: cancel_DO.height
			});
			cancel_bt.addEventListener(TSEvent.CHANGED, onCancelClick, false, 0, true);
			addChild(cancel_bt);
			
			is_built = true;
		}
		
		public function show(annc:Announcement, duration_offset_ms:uint = 0):void {
			if(!is_built) buildBase();
			cancel_bt.visible = annc.dismissible;
			current_progress = annc.word_progress;
			
			//clean out the old word
			SpriteUtil.clean(word_holder);
			
			//this is how we get the type it should be
			if(annc.word_progress){
				//show the proper word
				showWord('progress_'+annc.word_progress.type);
				
				//if we have a word, tween the progress
				if(current_word){
					animateProgress(annc.duration - duration_offset_ms, annc.counter_limit);
				}
			}
			
			//move the close button where it should go
			cancel_bt.x = int(word_holder.width + 3);
			cancel_bt.y = 13;
		}
		
		private function showWord(word:String):void {
			if(word_progress_mc){
				current_word = word_progress_mc.getAssetByName(word);
				if(!current_word){
					current_word = word_progress_mc.getAssetByName('progress_default');
					CONFIG::debugging {
						Console.warn(word+' not found, showing the "doing stuff"');
					}
				}
				word_holder.addChild(current_word);
			}
			else {
				CONFIG::debugging {
					Console.warn('BASE ASSET NOT LOADED!!');
				}
			}
		}
		
		private function animateProgress(duration_ms:int, limit:int = 1):void {
			if(!current_word) return;
			
			this.limit = limit;
			current_round = 1;
			animation_speed = (duration_ms/1000)/limit;
			
			animateNextRound();
		}
		
		private function animateNextRound():void {
			if(current_round <= limit){
				const fill_mc:MovieClip = current_word.getChildByName(FILL_NAME) as MovieClip;
				if(fill_mc){
					//if we have custom colors, handle it
					if(current_progress && (current_progress.gradient_top != -1 || current_progress.gradient_bottom != -1)){
						//clear out the default stuff
						while(fill_mc.numChildren) fill_mc.removeChildAt(0);
						
						//vertical grad
						bg_matrix.createGradientBox(current_word.width, current_word.height, Math.PI/2, 0, 0);
						const g:Graphics = fill_mc.graphics;
						g.clear();
						g.beginGradientFill(
							GradientType.LINEAR, 
							[current_progress.gradient_top, current_progress.gradient_bottom], 
							[1,1], 
							[0,255], 
							bg_matrix
						);
						g.drawRect(0, 0, current_word.width, current_word.height);
					}
					
					//reset the width and then tween it out for how long we need it to
					fill_mc.width = 0;
					TSTweener.addTween(fill_mc, {width:current_word.width, time:animation_speed, transition:'linear', onComplete:animateNextRound});
				}
			}
			
			current_round++;
		}
		
		private function onAssetLoaded(event:Event):void {
			//set our word progress mc
			const word_progress_loader:Loader = MovieClip(event.currentTarget).getChildAt(0) as Loader;
			word_progress_mc = word_progress_loader.content as MovieClip;
			
			//let the listeners know that we are all done loading
			dispatchEvent(new TSEvent(TSEvent.COMPLETE, this));
		}
		
		private function onCancelClick(event:TSEvent):void {
			dispatchEvent(new TSEvent(TSEvent.CLOSE));
		}
		
		/*****************************
		 * IAnnouncementArtView stuff
		 *****************************/
		public function get art_w():Number {
			return word_holder.width;
		}
		
		public function get art_h():Number {
			return word_holder.height;
		}
		
		public function get wh():int {
			//not sure what this is for, but probably won't be called on
			return Math.max(word_holder.width, word_holder.height);
		}
		
		public function get loaded():Boolean {
			return (word_progress_mc ? true : false);
		}
		
		public function dispose():void {
			SpriteUtil.clean(word_holder);
		}
	}
}