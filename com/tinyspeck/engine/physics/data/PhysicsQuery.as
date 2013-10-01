package com.tinyspeck.engine.physics.data
{
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.Deco;
	import com.tinyspeck.engine.data.location.Door;
	import com.tinyspeck.engine.data.location.Ladder;
	import com.tinyspeck.engine.data.location.SignPost;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.physics.colliders.ColliderCircle;
	import com.tinyspeck.engine.physics.colliders.ColliderLine;
	
	import flash.geom.Rectangle;

	public class PhysicsQuery
	{
		public const geometryQuery:Rectangle = new Rectangle();
		public const itemQuery:ColliderCircle = new ColliderCircle();
		
		public var doColliderLines:Boolean = false;
		public var doLadders:Boolean = false;
		public var doSignPosts:Boolean = false;
		public var doDoors:Boolean = false;
		public var doDecos:Boolean = false;
		public var doItemstacks:Boolean = false;
		public var doPCs:Boolean = false;
		
		public const resultColliderLines:Vector.<ColliderLine> = new Vector.<ColliderLine>();
		public const resultDoors:Vector.<Door> = new Vector.<Door>;
		public const resultLadders:Vector.<Ladder> = new Vector.<Ladder>;
		public const resultSignPosts:Vector.<SignPost> = new Vector.<SignPost>;
		public const resultDecos:Vector.<Deco> = new Vector.<Deco>;
		public const resultItemstacks:Vector.<Itemstack> = new Vector.<Itemstack>;
		public const resultPCs:Vector.<PC> = new Vector.<PC>;
		
		public function PhysicsQuery() {
			//
		}
		
		public function reset():void {
			resultColliderLines.length = 0;
			resultDoors.length = 0;
			resultLadders.length = 0;
			resultSignPosts.length = 0;
			resultDecos.length = 0;
			resultItemstacks.length = 0;
			resultPCs.length = 0;
		}
	}
}