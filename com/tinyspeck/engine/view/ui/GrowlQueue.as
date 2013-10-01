package com.tinyspeck.engine.view.ui
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.quest.QuestQueue;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.filters.GlowFilter;
	import flash.utils.Timer;

	public class GrowlQueue extends Sprite implements IRefreshListener, IMoveListener
	{	
		protected var PADD:uint = 10;
		protected var PADD_BOTTOM:uint = 15;
		protected var SHOW_TIME:Number = .2; //animate showing
		protected var HIDE_TIME:Number = .6; //animate hiding
		protected var MAX_STAY_TIME:Number = 4; //how many secs to stay on screen
		protected var MIN_STAY_TIME:Number = .5; //if there is one already on screen, how long to wait before showing the new one
		
		protected var retry_timer:Timer = new Timer(1000);
		
		protected var text_mask:Shape = new Shape();
		
		protected var update_queue:Array = [];
		
		protected var tfs:Vector.<TSLinkedTextField> = new Vector.<TSLinkedTextField>();
		
		protected var tf_filters:Array;
		
		protected var is_moving:Boolean;
		protected var is_built:Boolean;
		
		public function GrowlQueue(){}
		
		protected function buildBase():void {
			const tf_glow:GlowFilter = new GlowFilter();
			tf_glow.color = 0;
			tf_glow.blurX = tf_glow.blurY = 1;
			tf_glow.alpha = .2;
			
			tf_filters = StaticFilters.anncText_DropShadowA.concat(tf_glow);
			
			retry_timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
			TSFrontController.instance.registerMoveListener(this);
			
			mouseEnabled = mouseChildren = false;
			
			mask = text_mask;
			addChild(text_mask);
			
			visible = false;
			is_built = true;
		}
		
		public function show(anything_you_want:*):void {
			if(!is_built) buildBase();
			
			//shove it in the queue and show it right away
			update_queue.push(anything_you_want);
			showNextMessage();
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
			visible = false;
			
			//stop listening
			TSFrontController.instance.unRegisterRefreshListener(this);
			
			//we have any more?
			showNextMessage();
		}
		
		protected function showNextMessage():void {
			//if we are in the middle of a move
			if(is_moving && update_queue.length > 0){
				retry_timer.reset();
				retry_timer.start();
				return;
			}
			
			//nothing? bail out
			if(!update_queue.length) return;
			
			//get the next thing and see what we need to do with it
			handleNextThingInQueue();
			
			//place it where it should go (if we are not in capture mode)
			if(!TSModelLocator.instance.stateModel.in_capture_mode){
				TSFrontController.instance.getMainView().addView(this);
			}
			
			//listen to stuff
			TSFrontController.instance.registerRefreshListener(this);
			
			visible = true;
		}
		
		public function refresh():void {
			if(!TSModelLocator.instance) return;
			
			//place this where it should be
			const lm:LayoutModel = TSModelLocator.instance.layoutModel;
			
			//make sure the TFs that are in view have the right width
			const total:int = tfs.length;
			var i:int;
			var tf:TSLinkedTextField;
			
			for(i; i < total; i++){
				tf = tfs[int(i)];
				if(tf.parent){
					tf.width = lm.loc_vp_w - PADD*2;
					tf.y = int(lm.loc_vp_h - tf.height - PADD_BOTTOM);
				}
			}
			
			drawAndPlace();
		}
		
		protected function drawAndPlace():void {
			if(!TSModelLocator.instance) return;
			
			//place this where it should be
			const lm:LayoutModel = TSModelLocator.instance.layoutModel;
			
			var g:Graphics = text_mask.graphics;
			g.clear();
			g.beginFill(0,.5);
			g.drawRoundRectComplex(0, 0, lm.loc_vp_w, lm.loc_vp_h, lm.loc_vp_elipse_radius, 0, lm.loc_vp_elipse_radius, 0);
		}
		
		protected function handleNextThingInQueue():void {
			//this will get the next element in the queue and figure out how we need to display it
			const lm:LayoutModel = TSModelLocator.instance.layoutModel;
			const next_thing:Object = update_queue.shift();
			var tf:TSLinkedTextField;
			var animation_delay:Number = 0;
			
			//if any TFs are still on the screen, get them suckers off there
			const total:int = tfs.length;
			var i:int;
			for(i; i < total; i++){
				tf = tfs[int(i)];
				if(tf.parent && tf.x == PADD){
					//off you go
					TSTweener.removeTweens(tf);
					tf.alpha = 1;
					TSTweener.addTween(tf, {alpha:0, time:HIDE_TIME, transition:'linear', onComplete:onTFComplete, onCompleteParams:[tf]});
					//TSTweener.addTween(tf, {x:lm.loc_vp_w, time:HIDE_TIME, transition:'easeInCubic'});
					animation_delay = MIN_STAY_TIME;
				}
			}
						
			//get a TF to use
			tf = getTFtoUse();
			tf.htmlText = '<p class="growl_queue">'+StringUtil.injectClass(next_thing.toString(), 'a', 'growl_queue_link')+'</p>';
			//if our text has a link let the mouse do it's stuff, otherwise nope
			mouseEnabled = mouseChildren = (tf.htmlText.indexOf('href=') != -1);
			
			//animate the text
			tf.alpha = 0;
			tf.x = PADD;
			addChild(tf);
			
			TSTweener.addTween(tf, {alpha:1, time:SHOW_TIME, delay:animation_delay, transition:'linear'});
			TSTweener.addTween(tf, {alpha:0, time:HIDE_TIME, delay:MAX_STAY_TIME+animation_delay, transition:'linear', onComplete:onTFComplete, onCompleteParams:[tf]});
			//TSTweener.addTween(tf, {x:lm.loc_vp_w, time:HIDE_TIME, delay:MAX_STAY_TIME+animation_delay, transition:'easeInCubic'});
			
			//sets the TFs
			refresh();
		}
		
		protected function resume():void {
			TSTweener.resumeTweens(this, 'alpha');
			visible = TSTweener.getTweenCount(this) > 0;
		}
		
		protected function getTFtoUse():TSLinkedTextField {
			//loop through the pool and snag the first one that doesn't have a parent
			var i:int;
			var total:int = tfs.length;
			var tf:TSLinkedTextField;
			
			for(i; i < total; i++){
				tf = tfs[int(i)];
				if(!tf.parent) return tf;
			}
			
			//if we are down here it means we gotta make a new one!
			tf = new TSLinkedTextField();
			TFUtil.prepTF(tf);
			tf.filters = tf_filters;
			tfs.push(tf);
			
			return tf;
		}
		
		protected function onTFComplete(tf:TSLinkedTextField):void {
			//tf is done animating, axe it
			if(tf.parent) tf.parent.removeChild(tf);
			
			//see if we have any more TFs visible
			const total:int = tfs.length;
			var i:int;
			var any_visible:Boolean;
			for(i; i < total; i++){
				if(tfs[int(i)].parent){
					any_visible = true;
					break;
				}
			}
			
			if(!any_visible) hide();
		}
		
		protected function onTimerTick(event:TimerEvent):void {
			//see if we can show stuff yet
			if(!is_moving){
				retry_timer.stop();
				
				showNextMessage();
			}
		}
		
		/********************** 
		 * IMoveListener Stuff 
		 **********************/
		public function moveLocationHasChanged():void { }
		public function moveLocationAssetsAreReady():void {}
		public function moveMoveStarted():void {
			TSTweener.pauseTweens(this, 'alpha');
			visible = false;
			is_moving = true;
		}
		
		public function moveMoveEnded():void {
			//short little delay so the loading screen can fade out first
			StageBeacon.setTimeout(resume, 800);
			is_moving = false;
		}
	}
}