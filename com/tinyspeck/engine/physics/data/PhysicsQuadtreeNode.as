package com.tinyspeck.engine.physics.data
{
	import com.tinyspeck.engine.data.location.Door;
	import com.tinyspeck.engine.data.location.Ladder;
	import com.tinyspeck.engine.data.location.SignPost;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.physics.colliders.ColliderLine;
	
	import flash.geom.Rectangle;
	
	CONFIG const MAX_ITEMS = 16;

	public class PhysicsQuadtreeNode
	{
		public var colliderLines:Vector.<ColliderLine>;
		public var ladders:Vector.<Ladder>;
		public var signPosts:Vector.<SignPost>;
		public var doors:Vector.<Door>;
		
		public var tree:PhysicsQuadtree;
		public var rect:Rectangle;
		
		public var tlNode:PhysicsQuadtreeNode;
		public var trNode:PhysicsQuadtreeNode;
		public var blNode:PhysicsQuadtreeNode;
		public var brNode:PhysicsQuadtreeNode;
		
		public var hasChildren:Boolean = false;
		
		public function PhysicsQuadtreeNode(x:Number, y:Number, width:Number, height:Number, tree:PhysicsQuadtree)
		{
			init();
			rect = new Rectangle(x,y,width,height);
			this.tree = tree;
		}
		
		private function init():void
		{
			colliderLines = new Vector.<ColliderLine>();
			ladders = new Vector.<Ladder>();
			signPosts = new Vector.<SignPost>();
			doors = new Vector.<Door>();
		}
		
		public function setSize(width:Number, height:Number):void
		{
			rect.width = width;
			rect.height = height;
		}
		
		public function setPosition(x:Number, y:Number):void
		{
			rect.x = x;
			rect.y = y;
		}
		
		public function insertDoor(door:Door):void
		{
			if(rect.containsRect(door.client::physRect)){
				doors.push(door);
			}
		}
		
		public function insertSignPost(signPost:SignPost):void
		{
			if(rect.containsRect(signPost.client::physRect)){
				signPosts.push(signPost);
			}
		}
		
		public function insertLadder(ladder:Ladder):void
		{
			if(rect.containsRect(ladder.client::physRect)){
				ladders.push(ladder);
			}
		}
		
		public function insertColliderLine(colliderLine:ColliderLine):void
		{
			if(rect.containsRect(colliderLine.client::physRect)){
				colliderLines.push(colliderLine);
			}
		}
		
		public function subdivide():void
		{
			if(numItems > CONFIG::MAX_ITEMS){
				buildChildren();
				distributeChildren();
				trNode.subdivide();
				tlNode.subdivide();
				blNode.subdivide();
				brNode.subdivide();
			}
		}
		
		protected function buildChildren():void
		{
			if(!hasChildren){
				var hw:Number = rect.width/2;
				var hh:Number = rect.height/2;
				var rx:Number = rect.x;
				var ry:Number = rect.y;

				tlNode = new PhysicsQuadtreeNode(rx,ry,hw,hh,tree);
				trNode = new PhysicsQuadtreeNode(rx+hw,ry,hw,hh,tree);
				blNode = new PhysicsQuadtreeNode(rx,ry+hh,hw,hh,tree);
				brNode = new PhysicsQuadtreeNode(rx+hw,ry+hh,hw,hh,tree);
				hasChildren = true;
			}
		}
		
		protected function distributeChildren():void
		{
			distributeColliderLines();
			distributeLadders();
			distributeSignPosts();
			distributeDoors();
		}
				
		private function distributeColliderLines():void
		{
			var colliderLine:ColliderLine;
			var keepColliderLines:Vector.<ColliderLine> = new Vector.<ColliderLine>();
			var length:int = colliderLines.length;
			for(var i:int = 0; i<length; i++){
				colliderLine = colliderLines[int(i)];
				if(tlNode.rect.containsRect(colliderLine.client::physRect)){
					tlNode.insertColliderLine(colliderLine);
				}else if(trNode.rect.containsRect(colliderLine.client::physRect)){
					trNode.insertColliderLine(colliderLine);
				}else if(blNode.rect.containsRect(colliderLine.client::physRect)){
					blNode.insertColliderLine(colliderLine);
				}else if(brNode.rect.containsRect(colliderLine.client::physRect)){
					brNode.insertColliderLine(colliderLine);
				}else{
					keepColliderLines.push(colliderLine);
				}
			}
			colliderLines = keepColliderLines;
		}
		
		private function distributeLadders():void
		{
			var ladder:Ladder;
			var keepLadders:Vector.<Ladder> = new Vector.<Ladder>();
			for(var i:int = 0; i<ladders.length; i++){
				ladder = ladders[int(i)];
				if(tlNode.rect.containsRect(ladder.client::physRect)){
					tlNode.insertLadder(ladder);
				}else if(trNode.rect.containsRect(ladder.client::physRect)){
					trNode.insertLadder(ladder);
				}else if(blNode.rect.containsRect(ladder.client::physRect)){
					blNode.insertLadder(ladder);
				}else if(brNode.rect.containsRect(ladder.client::physRect)){
					brNode.insertLadder(ladder);
				}else{
					keepLadders.push(ladder);
				}
			}
			ladders = keepLadders;
		}
		
		private function distributeSignPosts():void
		{
			var signPost:SignPost;
			var keepSignPosts:Vector.<SignPost> = new Vector.<SignPost>();
			for(var i:int = 0; i<signPosts.length; i++){
				signPost = signPosts[int(i)];
				if(tlNode.rect.containsRect(signPost.client::physRect)){
					tlNode.insertSignPost(signPost);
				}else if(trNode.rect.containsRect(signPost.client::physRect)){
					trNode.insertSignPost(signPost);
				}else if(blNode.rect.containsRect(signPost.client::physRect)){
					blNode.insertSignPost(signPost);
				}else if(brNode.rect.containsRect(signPost.client::physRect)){
					brNode.insertSignPost(signPost);
				}else{
					keepSignPosts.push(signPost);
				}
			}
			signPosts = keepSignPosts;
		}
		
		private function distributeDoors():void
		{
			var door:Door;
			var keepDoors:Vector.<Door> = new Vector.<Door>();
			for(var i:int = 0; i<doors.length; i++){
				door = doors[int(i)];
				if(tlNode.rect.containsRect(door.client::physRect)){
					tlNode.insertDoor(door);
				}else if(trNode.rect.containsRect(door.client::physRect)){
					trNode.insertDoor(door);
				}else if(blNode.rect.containsRect(door.client::physRect)){
					blNode.insertDoor(door);
				}else if(brNode.rect.containsRect(door.client::physRect)){
					brNode.insertDoor(door);
				}else{
					keepDoors.push(door);
				}
			}
			doors = keepDoors;
		}
		
		public function get numItems():int
		{
			//TODO PERF make this a tracked value rather than this expensive summation
			return colliderLines.length + ladders.length + signPosts.length + doors.length;
		}
	}
}