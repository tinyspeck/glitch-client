package com.tinyspeck.engine.physics.colliders
{
public class ColliderAvatar
{
	/** collision with floors and walls */
	public const footCircle:ColliderCircle = new ColliderCircle();
	
	/** collision with non-permeable ceilings */
	public const headCircle:ColliderCircle = new ColliderCircle();
	
	/** collision with dynamic objects (e.g. itemstacks) */
	// a circle that circumscribes the entire avatar tightly
	public const avatarCircle:ColliderCircle = new ColliderCircle();
	
	public function ColliderAvatar(radius:Number=15) {
		footCircle.radius = radius;
		headCircle.radius = radius;
	}
	
	public function headTouches(colliderLine:ColliderLine):Boolean {
		return false;
	}
	
	public function footTouches(colliderLine:ColliderLine):Boolean {
		return false;
	}
}
}