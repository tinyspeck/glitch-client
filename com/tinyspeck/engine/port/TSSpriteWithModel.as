package com.tinyspeck.engine.port {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.control.engine.LinearMovementSpriteController;
	import com.tinyspeck.engine.model.TSModelLocator;
	
	public class TSSpriteWithModel extends TSSprite {
		protected var model:TSModelLocator;
		
		// Jote:9/21/2012
		// Trying to reduce overhead from Tweener by using a controller
		protected var use_movement_controller:Boolean = false;
		protected var movement_controller:LinearMovementSpriteController;
		
		public function TSSpriteWithModel(tsid:String = null):void {
			model = TSModelLocator.instance;
			super(tsid);

			// Jote:9/21/2012
			// Testing out use of a dedicated controller in an attemp to reduce overhead from Tweener
			use_movement_controller = model.flashVarModel.use_movement_controller;
			
		}
		
		protected var tweening:Boolean;
		protected var tween_ob:Object = {transition:'linear', onComplete:onTweenComplete};
		protected function animateXY(c_x:Number, c_y:Number, duration:Number = 0):void {
			if (duration < 0) duration = .0001;
			
			//if (c_x == undefined || c_x == null) c_x = x;
			//if (c_y == undefined || c_y == null) c_y = y;
			
			if (no_animate_xy) {
				x = c_x;
				y = c_y;
				return;
			}
			
			if (!tweening && c_x == x && c_y == y) {
				return;
			}
			
			tweening = true;
			
			if (use_movement_controller) {
				if (!movement_controller) {
					// ideally we would get this from a pool
					movement_controller = new LinearMovementSpriteController(this);
				}
				movement_controller.startMovement(c_x, c_y, (duration || _animateXY_duration), onTweenComplete);
				return;
			}
			
			tween_ob.time = duration || _animateXY_duration;
			tween_ob.onComplete = onTweenComplete;
			tween_ob.transition = 'linear';
			tween_ob.x = c_x;
			tween_ob.y = c_y;
			
			TSTweener.addTween(this, tween_ob);
		}
		
		protected function stopAnimateXY():void {
			if (movement_controller) {
				movement_controller.stop();
			} else {
				TSTweener.removeTweens(this);
			}
			tweening = false;
		}
		
		protected function onTweenComplete():void {
			tweening = false;
		}
		
		override public function dispose():void {
			/*if (_animateXY_tween) {
			_animateXY_tween.end();
			_animateXY_tween = null;
			}*/
			
			if (use_movement_controller) {
				if (movement_controller) {
					movement_controller.stop();
					// ideally we would return this to a pool now
					movement_controller = null;
				}
			} else { 
				TSTweener.removeTweens(this);
			}
			
			super.dispose();
		}
	}
}