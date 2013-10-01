package com.tinyspeck.engine.physics.colliders {
	import com.tinyspeck.engine.data.location.PlatformLine;

	public function colliderLineFromPlatformLine(platformLine:PlatformLine, epsilon:Number = 1):ColliderLine {
			const colliderLine:ColliderLine = new ColliderLine(platformLine.start.x, 
				platformLine.start.y, 
				platformLine.end.x, 
				platformLine.end.y, 
				epsilon);
			
				colliderLine.item_solid_from_top = platformLine.item_solid_from_top;
				colliderLine.item_solid_from_bottom = platformLine.item_solid_from_bottom;
				colliderLine.pc_solid_from_top = platformLine.pc_solid_from_top;
				colliderLine.pc_solid_from_bottom = platformLine.pc_solid_from_bottom;
			
			return colliderLine;
		}

}