package com.tinyspeck.engine.physics.data
{
	import com.tinyspeck.engine.data.location.Center;
	import com.tinyspeck.engine.data.location.Door;
	import com.tinyspeck.engine.data.location.Ladder;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.location.SignPost;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.physics.colliders.ColliderLine;
	
	import flash.geom.Rectangle;

	public class PhysicsQuadtree
	{
		public var mainNode:PhysicsQuadtreeNode;
		
		private var location:Location;
		
		public function PhysicsQuadtree() {
			init();
		}
		
		private function init():void {
			mainNode = new PhysicsQuadtreeNode(0,0,0,0, this);
		}
		
		public function queryRect(query:PhysicsQuery):PhysicsQuery
		{
			if (query.doColliderLines || query.doDoors || query.doLadders || query.doSignPosts) {
				query = (mainNode.rect.intersects(query.geometryQuery) ? queryRectDeep(mainNode,query) : query);
			}
			return query;
		}
		
		//This will clear the current quadtree and fill it with the location.
		public function setLocation(location:Location):void
		{
			reset();
			
			var rect_allowance:int = TSModelLocator.instance.physicsModel.location_breathing_allowance;
			
			if(location){
				this.location = location;
				setPosition(location.l-(rect_allowance/2), location.t-(rect_allowance/2));
				setSize(location.client::w+rect_allowance, location.client::h+rect_allowance);
				if(location.mg){
					insertColliderLines(location.mg.client::colliderLines);
					insertSignPosts(location.mg.signposts);
					insertLadders(location.mg.ladders);
					insertDoors(location.mg.doors);
				}
				build();
			}
		}
		
		private function insertColliderLines(lines:Vector.<ColliderLine>):void
		{
			for(var i:int=lines.length-1; i>=0; --i){
				insertColliderLine(lines[int(i)]);
			}
		}
		
		private function insertDoors(doors:Vector.<Door>):void
		{
			for(var i:int=doors.length-1; i>=0; --i){
				insertDoor(doors[int(i)]);
			}
		}
		
		private function insertSignPosts(signPosts:Vector.<SignPost>):void
		{
			for(var i:int=signPosts.length-1; i>=0; --i){
				insertSignPost(signPosts[int(i)]);
			}
		}
		
		//TODO optimize these loops
		private function insertLadders(ladders:Vector.<Ladder>):void
		{
			for(var i:int=ladders.length-1; i>=0; --i){
				insertLadder(ladders[int(i)]);
			}
		}
		
		private function reset():void
		{
			mainNode = new PhysicsQuadtreeNode(0,0,0,0, this);
		}
		
		private function setSize(w:Number, h:Number):void
		{
			mainNode.setSize(w,h);
		}
		
		private function setPosition(x:Number, y:Number):void
		{
			mainNode.setPosition(x,y);
		}
		
		private function insertDoor(door:Door):void
		{
			if(!door.client::physRect){
				var plRect:Rectangle = new Rectangle();
				door.w = door.w > 0 ? door.w : 50;
				plRect.x = door.x-(door.w/2);
				plRect.y = door.y-door.h;
				plRect.width = door.w// > 0 ? ladder.w : 2;
				plRect.height = door.h;//> 0 ? ladder.h : 2;
				door.client::physRect = plRect;
			}
			mainNode.insertDoor(door);
		}
		
		private function insertSignPost(signPost:SignPost):void
		{
			if(!signPost.client::physRect){
				var plRect:Rectangle = new Rectangle();
				// signposts cannot have their own decos right now
				// signPost.w = signPost.w > 0 ? signPost.w : signPost.deco.w;
                //TODO: Y U assign param to itself?
                signPost.w = signPost.w;
				plRect.x = signPost.x-(signPost.w/2);
				plRect.y = signPost.y-signPost.h;
				plRect.width = signPost.w// > 0 ? ladder.w : 2;
				plRect.height = signPost.h;//> 0 ? ladder.h : 2;
				signPost.client::physRect = plRect;
			}
			mainNode.insertSignPost(signPost);
		}
		
		private function insertLadder(ladder:Ladder):void
		{
			if(!ladder.client::physRect){
				var plRect:Rectangle = new Rectangle();
				//TODO : Move this to healing.
				if(ladder.w <= 0){
					if(ladder.tiling){
						if(ladder.tiling.centers && ladder.tiling.centers[0]){
							ladder.w = ladder.tiling.centers[0].w;
						}else if(ladder.tiling.cap_0){
							ladder.w = ladder.tiling.cap_0.w;
						}
					}else{
						ladder.w = 50;
					}
				}
				plRect.x = ladder.x-(ladder.w/2);
				plRect.y = ladder.y-ladder.h;
				plRect.width = ladder.w// > 0 ? ladder.w : 2;
				plRect.height = ladder.h;//> 0 ? ladder.h : 2;
				ladder.client::physRect = plRect;
			}
			mainNode.insertLadder(ladder);
		}
			
		private function insertColliderLine(line:ColliderLine):void
		{
			if(!line.client::physRect){
				var plRect:Rectangle = new Rectangle();
				var startY:int;
				var endY:int;
				var startX:int;
				var endX:int;
				
				startX = line.x1;
				endX = line.x2;
				
				if(line.y1 < line.y2){
					startY = line.y1;
					endY = line.y2;
				}else{
					startY = line.y2;
					endY = line.y1;
				}
				
				endX = Math.min(location.r,endX);
				startX = Math.max(location.l,startX);
				plRect.x = startX;
				plRect.y = startY;
				plRect.width = endX-startX;
				plRect.height = endY-startY;
				if(plRect.height < 1){
					plRect.height = 1;
				}
				if(plRect.width < 1){
					plRect.width = 1;
				}
				line.client::physRect = plRect;
			}
			mainNode.insertColliderLine(line);
		}
		
		private function build():void
		{
			mainNode.subdivide();
		}
		
		private function queryRectDeep(node:PhysicsQuadtreeNode, query:PhysicsQuery):PhysicsQuery
		{
			var i:int;
			
			const intersects:Function = query.geometryQuery.intersects;

			if (node.numItems > 0) {
				if(query.doColliderLines){
					const colliderLines:Vector.<ColliderLine> = node.colliderLines;
					for(i=colliderLines.length-1; i>=0; --i){
						if(intersects(colliderLines[int(i)].client::physRect)){
							query.resultColliderLines.push(colliderLines[int(i)]);
						}
					}
				}
				
				if(query.doLadders){
					const ladders:Vector.<Ladder> = node.ladders;
					for(i=ladders.length-1; i>=0; --i){
						if(intersects(ladders[int(i)].client::physRect)){
							query.resultLadders.push(ladders[int(i)]);
						}
					}
				}
				
				if(query.doSignPosts){
					const signPosts:Vector.<SignPost> = node.signPosts;
					for(i=signPosts.length-1; i>=0; --i){
						if(intersects(signPosts[int(i)].client::physRect)){
							query.resultSignPosts.push(signPosts[int(i)]);
						}
					}
				}
				
				if(query.doDoors){
					const doors:Vector.<Door> = node.doors;
					for(i=doors.length-1; i>=0; --i){
						if(intersects(doors[int(i)].client::physRect)){
							query.resultDoors.push(doors[int(i)]);
						}
					}
				}
			}
			
			if(node.hasChildren){
				if(node.trNode && intersects(node.trNode.rect)){
					query = queryRectDeep(node.trNode,query);
				}
				if(node.tlNode && intersects(node.tlNode.rect)){
					query = queryRectDeep(node.tlNode,query);
				}
				if(node.brNode && intersects(node.brNode.rect)){
					query = queryRectDeep(node.brNode,query);
				}
				if(node.blNode && intersects(node.blNode.rect)){
					query = queryRectDeep(node.blNode,query);
				}
			}
			
			return query;
		}
	}
}