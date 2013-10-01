package com.tinyspeck.engine.data.location {
	
	import com.tinyspeck.engine.ns.client;
	
	import flash.geom.Rectangle;

	public class SignPost extends AbstractPositionableLocationEntity {
		client var physRect:Rectangle;
		client var quarter_info:QuarterInfo;
		
		public var invisible:Boolean;
		public var hidden:Boolean;
		public var w:Number = 100;
		public var h:Number = 200;
		public var r:Number = 0;
		public var connects:Vector.<LocationConnection>;
		public var deco:Deco;
		public var id:String; //[SY] not sure when/why this was being sent, but it shows up in signpost_change
		
		public function SignPost(hashName:String) {
			super(hashName);
		}
		
		override public function AMF():Object {
			var i:int;
			var ob:Object = super.AMF();
			
			ob.h = h;
			ob.w = w;
			if (r) ob.r = r;
			if (deco) ob.deco = deco.AMF();
			if (id) ob.id = id;
			
			if (connects) {
				ob.connects = {};
				for (i=connects.length-1; i>-1; i--) {
					ob.connects[connects[int(i)].hashName] = connects[int(i)].AMF();
				}
			}
				
			return ob;
		}
		
		public static function parseMultiple(object:Object):Vector.<SignPost> {
			var signPosts:Vector.<SignPost> = new Vector.<SignPost>();
			for(var j:String in object){
				if (!object[j].hasOwnProperty('connects')) continue;
				signPosts.push(fromAnonymous(object[j],j));
			}
			return signPosts;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):SignPost {
			return SignPost.updateFromAnonymous(object, new SignPost(hashName));
		}
		
		public static function updateFromAnonymous(object:Object, signPost:SignPost):SignPost
		{
			for(var j:String in object){
				if(j in signPost){
					if(j == "connects"){
						signPost.connects = LocationConnection.parseMultiple(object[j]);
					}else if(j =="h"){
						if (!isNaN(object[j])) signPost.h = object[j];
					}else if(j == "deco"){
						signPost.deco = Deco.fromAnonymous(object[j], j);
						signPost.deco.is_simple = true;
					}else if(j =="w"){
						if (!isNaN(object[j])) signPost.w = object[j];
					}else{
						signPost[j] = object[j];
					}
				}else if(j == "quarter_info"){
					signPost.client::quarter_info = QuarterInfo.fromAnonymous(object[j], j);
				} else {
					
					/*
					[8:27pm] eric: the extra quarter":"RHH1048S24K1C4R" is a mistake I think?
					[8:27pm] iamcal: nope, it's from the base geometry. because of the way the GS caches transformed geo it's difficult for me to remove
					[8:27pm] iamcal: can you just ignore it?
					[8:27pm] eric: yes
					[8:27pm] iamcal: tyhanks
					*/
					
					var no_warning:Boolean = false;
					if (j == "quarter") no_warning = true; // we want signposts to go back to the server from AMF(), so we do resolveError() with no_warning = true, which will put them in the unexpected hash but not output log warning
					resolveError(signPost, object, j, no_warning);
				}
			}
			
			signPost.hidden = object.hidden && object.hidden == true;
			signPost.invisible = object.invisible && object.invisible == true;
			return signPost;
		}
		
		public function getVisibleConnects():Vector.<LocationConnection> {
			var V:Vector.<LocationConnection> = new Vector.<LocationConnection>();
			var non_hidden_connections_count:int = 0;
			for (var j:int = 0; j < this.connects.length; j++){
				if (this.connects[int(j)].hidden) continue;
				V.push(this.connects[int(j)]);
			}
			return V;
		}
		
		public function getConnectThatLinksToLocTsid(loc_tsid:String):LocationConnection {
			if (connects) {
				for each (var connect:LocationConnection in connects) {
					if (connect.street_tsid == loc_tsid) {
						return connect;
					}
				}
			}
			return null;
		}
	}
}