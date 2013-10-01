package com.tinyspeck.engine.data.location
{
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.physics.colliders.ColliderLine;

	public class MiddleGroundLayer extends Layer
	{
		// fucking flash builder is showing compile errors PhysicsQuadtree line 46 when colliderLines is in namespace client,
		// even though "use namespace client;" is present. Seems to be a compiler bug. Switching colliderLines to public therefore
		client var colliderLines:Vector.<ColliderLine>;
		
		public var platform_lines:Vector.<PlatformLine> = new Vector.<PlatformLine>();
		public var contiguous_platform_line_sets:Vector.<ContiguousPlatformLineSet> = new Vector.<ContiguousPlatformLineSet>();
		public var doors:Vector.<Door> = new Vector.<Door>();
		public var signposts:Vector.<SignPost> = new Vector.<SignPost>();
		public var targets:Vector.<Target> = new Vector.<Target>();
		public var ladders:Vector.<Ladder> = new Vector.<Ladder>();
		public var boxes:Vector.<Box> = new Vector.<Box>();
		public var walls:Vector.<Wall> = new Vector.<Wall>();
		
		public function MiddleGroundLayer(hashName:String) {
			super(hashName);
		}
		
		override public function AMF():Object {
			var ob:Object = super.AMF();
			var i:int;
			
			// never hidden
			delete ob.is_hidden;
			
			if (platform_lines) {
				ob.platform_lines = {};
				for (i=platform_lines.length-1; i>-1; i--) {
					if (platform_lines[int(i)].start && platform_lines[int(i)].end) {
						ob.platform_lines[platform_lines[int(i)].hashName] = platform_lines[int(i)].AMF();
					}
				}
			}
			
			if (doors) {
				ob.doors = {};
				for (i=doors.length-1; i>-1; i--) {
					ob.doors[doors[int(i)].hashName] = doors[int(i)].AMF();
				}
			}
			
			if (signposts) {
				ob.signposts = {};
				for (i=signposts.length-1; i>-1; i--) {
					ob.signposts[signposts[int(i)].hashName] = signposts[int(i)].AMF();
				}
			}
			
			if (targets) {
				ob.targets = {};
				for (i=targets.length-1; i>-1; i--) {
					ob.targets[targets[int(i)].hashName] = targets[int(i)].AMF();
				}
			}
			
			if (ladders) {
				ob.ladders = {};
				for (i=ladders.length-1; i>-1; i--) {
					ob.ladders[ladders[int(i)].hashName] = ladders[int(i)].AMF();
				}
			}
			
			if (boxes) {
				ob.boxes = {};
				for (i=boxes.length-1; i>-1; i--) {
					ob.boxes[boxes[int(i)].hashName] = boxes[int(i)].AMF();
				}
			}
			
			if (walls) {
				ob.walls = {};
				for (i=walls.length-1; i>-1; i--) {
					ob.walls[walls[int(i)].hashName] = walls[int(i)].AMF();
				}
			}
			
			return ob;
		}
		
		public function getWallById(id:String):Wall {
			if (!walls) return null;
			
			var wall:Wall;
			for (var i:int=0;i<walls.length;i++) {
				wall = walls[int(i)];
				if (id == wall.tsid) return wall;
			}
			
			return null;
		}
		
		public function getWallsBySource(source:String):Vector.<Wall> {
			if (!source) return null; // don't bother if empty string source is passed 
			var V:Vector.<Wall>;
			var wall:Wall;
			for (var i:int=0;i<walls.length;i++) {
				wall = walls[int(i)];
				if (source == wall.source) {
					if (!V) V = new Vector.<Wall>();
					V.push(wall);
				}
			}
			
			return V;
		}
		
		public function getPlatformLineById(id:String):PlatformLine {
			var platformLine:PlatformLine;
			for (var i:int=0;i<platform_lines.length;i++) {
				platformLine = platform_lines[int(i)];
				if (id == platformLine.tsid) return platformLine;
			}
			
			return null;
		}
		
		public function getPlatformLinesBySource(source:String):Vector.<PlatformLine> {
			if (!source) return null; // don't bother if empty string source is passed 
			var V:Vector.<PlatformLine>;
			var platformLine:PlatformLine;
			for (var i:int=0;i<platform_lines.length;i++) {
				platformLine = platform_lines[int(i)];
				if (source == platformLine.source) {
					 if (!V) V = new Vector.<PlatformLine>();
					 V.push(platformLine);
				}
			}
			
			return V;
		}
		
		public function getLadderById(id:String):Ladder {
			if (!ladders) return null;
			
			var ladder:Ladder;
			for (var i:int=0;i<ladders.length;i++) {
				ladder = ladders[int(i)];
				if (id == ladder.tsid) return ladder;
			}
			
			return null;
		}
		
		public function getDoorById(id:String):Door {
			if (!doors) return null;
			
			var door:Door;
			for (var i:int=0;i<doors.length;i++) {
				door = doors[int(i)];
				if (id == door.tsid) return door;
			}
			
			return null;
		}
		
		public function getSignpostById(id:String):SignPost {
			if (!signposts) return null;
			
			var signpost:SignPost;
			for (var i:int=0;i<signposts.length;i++) {
				signpost = signposts[int(i)];
				if (id == signpost.tsid) return signpost;
			}
			
			return null;
		}
		
		public function getDoorThatLinksToLocTsid(loc_tsid:String):Door {
			for each (var door:Door in doors) {
				if (door.connect.street_tsid == loc_tsid) return door;
			}
			
			return null;
		}
		
		public function getDoorForItemstackTsid(itemstack_tsid:String):Door {
			for each (var door:Door in doors) {
				if (!door.itemstack_tsid) continue;
				if (door.itemstack_tsid == itemstack_tsid) return door;
			}
			
			return null;
		}
		
		public function getSignpostThatLinksToLocTsid(loc_tsid:String):SignPost {
			for each (var signpost:SignPost in signposts) {
				for each (var connect:LocationConnection in signpost.connects) {
					if (signpost.getConnectThatLinksToLocTsid(loc_tsid) != null) {
						return signpost;
					}
				}
			}
			
			return null;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):MiddleGroundLayer
		{
			var layer:MiddleGroundLayer = new MiddleGroundLayer(hashName);
			for(var j:String in object){
				if(j in layer){
					if(j == "decos"){
						layer.decos = Deco.parseMultiple(object[j]);
					}else if(j == "platform_lines"){
						layer.platform_lines = PlatformLine.parseMultiple(object[j]);
					}else if(j == "doors"){
						layer.doors = Door.parseMultiple(object[j]);
					}else if(j == "signposts"){
						layer.signposts = SignPost.parseMultiple(object[j]);
					}else if(j == "targets"){
						layer.targets = Target.parseMultiple(object[j]);
					}else if(j == "ladders"){
						layer.ladders = Ladder.parseMultiple(object[j]);
					}else if(j == "boxes"){
						layer.boxes = Box.parseMultiple(object[j]);
					}else if(j == "walls"){
						layer.walls = Wall.parseMultiple(object[j]);
					}else{
						layer[j] = object[j];
					}
				}else if (j == 'filters') {
					// ignore, legacy
				}else if (j == 'platforms') {
					// ignore, legacy
				}else{
					resolveError(layer,object,j);
				}
			}
			return layer;
		}
	}
}