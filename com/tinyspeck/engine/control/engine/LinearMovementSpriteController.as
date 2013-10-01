package com.tinyspeck.engine.control.engine {
	import com.tinyspeck.core.beacon.StageBeacon;
	
	import flash.display.Sprite;
	
	/**
	 * Controller which performs linear movement of a sprite from its current
	 * position to a specified destination.
	 */
	public class LinearMovementSpriteController {
		
		private var sprite:Sprite;
		private var destination_x:Number;
		private var destination_y:Number;
		private var x_direction:Number;
		private var y_direction:Number;
		private var duration_ms:Number;
		private var move_time_elapsed_ms:int = 0;
		
		private var onCompleteHandler:Function;
		
		public function LinearMovementSpriteController(sprite:Sprite) {
			this.sprite = sprite;
		}
		
		/**
		 * Start moving the Sprite.
		 * 
		 * @param desination_x The x coord of the destination.
		 * @param destination_y The y coord of the destination.
		 * @param duration_sec The movement's duration in seconds
		 * @param completeHandler Optional function to call upon completion. 
		 */
		public function startMovement(destination_x:Number, destination_y:Number, duration_sec:Number, completeHandler:Function = null):void {
			
			// determine new destination
			this.destination_x = destination_x;
			this.destination_y = destination_y;
			
			duration_ms = duration_sec * 1000;	// movement duration in milliseconds
			move_time_elapsed_ms = 0;
			
			// determine the direction vector
			x_direction = destination_x - sprite.x;
			y_direction = destination_y - sprite.y;
			
			onCompleteHandler = completeHandler;
			
			StageBeacon.enter_frame_sig.add(onMovementTick);
		}
		
		private function onMovementTick(ms_elapsed:int):void {
			
			move_time_elapsed_ms += ms_elapsed;
			
			// if the animation duration has been reached, finish the movement.
			if (move_time_elapsed_ms >= duration_ms) {
				sprite.x = destination_x;
				sprite.y = destination_y;
				stop();
				if (onCompleteHandler != null) onCompleteHandler();
				return;
			}
			
			// advance movement
			var time_ratio:Number = ms_elapsed/duration_ms;
			sprite.x += x_direction * time_ratio;
			sprite.y += y_direction * time_ratio;
		}
		
		public function stop():void {
			StageBeacon.enter_frame_sig.remove(onMovementTick);
		}
	}
}