package com.tinyspeck.engine.data.chat
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;

	public class FeedItem extends AbstractTSDataEntity
	{
		public static const TYPE_STATUS:String = 'status';
		public static const TYPE_STATUS_REPLY:String = 'status_reply';
		public static const TYPE_PHOTO:String = 'photo';
		
		public var id:String;
		public var type:String;
		public var when:uint;
		public var who_tsid:String;
		public var who_name:String;
		public var txt:String;
		public var replies:uint;
		public var likes:uint;
		public var full_in_reply_to:FeedItem;
		public var in_reply_to:FeedItem;
		public var full_replies:Vector.<FeedItem>;
		public var photo_id:String;
		public var url:String;
		public var secret:String;
		public var thumb_url:String;
		
		public function FeedItem(id:String){
			super(id);
			this.id = id;
		}
		
		public static function parseMultiple(status_updates:Object):Vector.<FeedItem> {
			var V:Vector.<FeedItem> = new Vector.<FeedItem>;
			var j:String;
			
			for(j in status_updates){
				V.push(fromAnonymous(status_updates[j], j));
			}
			
			return V;
		}
		
		public static function fromAnonymous(object:Object, id:String):FeedItem {
			var item:FeedItem = new FeedItem(id);
			
			return updateFromAnonymous(object, item);
		}
		
		public static function updateFromAnonymous(object:Object, item:FeedItem):FeedItem {
			var j:String;
						
			for(j in object){
				if(j == 'full_in_reply_to' && object[j] && 'id' in object[j]){
					item.full_in_reply_to = fromAnonymous(object[j], object[j].id);
				}
				else if(j == 'in_reply_to' && object[j] && 'id' in object[j]){
					item.in_reply_to = fromAnonymous(object[j], object[j].id);
				}
				else if(j == 'who_tsid' && 'who_name' in object){
					const world:WorldModel = TSModelLocator.instance.worldModel;
					const sheet_url:String = 'who_urls' in object && 'sheets' in object.who_urls ? object.who_urls.sheets : null;
					const singles_url:String = 'who_urls' in object && 'singles' in object.who_urls ? object.who_urls.singles : null;
					
					if(!world) continue;
					
					var pc:PC = world.getPCByTsid(object.who_tsid);
					
					//if they are not in the world yet, add them in
					if(!pc){
						pc = new PC(object.who_tsid);
						pc.tsid = object.who_tsid;
						pc.label = object.who_name;
						pc.sheet_url = sheet_url;
						pc.singles_url = singles_url;
						world.pcs[pc.tsid] = pc;
					}
					
					if (pc && sheet_url){
						pc.sheet_url = sheet_url;
					}
					
					if (pc && singles_url){
						pc.singles_url = singles_url;
					}
					
					item.who_tsid = object[j];
				}
				else if(j == 'full_replies'){
					item.full_replies = parseMultiple(object[j]);
				}
				else if(j == 'images' && object[j] && 'tinythumb' in object[j]){
					item.thumb_url = object[j].tinythumb;
				}
				else if(j == 'who_urls' || j == 'avatar_urls' || j == 'id'){
					//storing the string in the PC model, so just skip this
					//aka use this area to skip shit
				}
				else if(j in item){	
					item[j] = object[j];
				}
				else {
					resolveError(item,object,j);
				}
			}
			
			//sometimes the API returns fucked up shit in it's results that differs from other calls
			if('id' in object) item.id = object.id;
			if(item.id.indexOf('-') == -1){
				if('id' in object && 'id' in object.id && 'player_id' in object.id){
					item.id = object.id.player_id+'-'+object.id.id;
				}
			}
			
			return item;
		}
	}
}