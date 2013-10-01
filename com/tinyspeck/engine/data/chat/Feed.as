package com.tinyspeck.engine.data.chat
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class Feed extends AbstractTSDataEntity
	{
		public var items:Vector.<FeedItem> = new Vector.<FeedItem>();
		public var requests_pending:Boolean;
		public var has_more:Boolean;
		public var last:String;
		
		public function Feed(){
			super('status_feed');
		}
		
		public static function fromAnonymous(object:Object):Feed {
			var feed:Feed = new Feed();
			
			return updateFromAnonymous(object, feed);
		}
		
		public static function updateFromAnonymous(object:Object, feed:Feed):Feed {
			var j:String;
			
			for(j in object){
				if(j == 'items'){
					feed.items = FeedItem.parseMultiple(object[j]);
				}
				else if(j in feed){	
					feed[j] = object[j];
				}
				else{
					resolveError(feed,object,j);
				}
			}
			
			return feed;
		}
	}
}