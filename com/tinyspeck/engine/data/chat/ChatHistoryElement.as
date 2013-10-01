package com.tinyspeck.engine.data.chat
{
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.ui.chat.ChatElement;

	public class ChatHistoryElement
	{
		private static const CHUNK_DIVIDER:String = '^*&BREAK&*^';
		
		public var tsid:String;
		public var text:String;
		public var type:String;
		public var unix_timestamp:uint;
		public var is_admin:Boolean;
		public var is_guide:Boolean;
		public var label:String;
		
		/*********************************************
		 * Mapping for the chunks 
		 * NB: when adding new ones make sure they are 
		 * the same values as found in PC.as
		 * 0 - PC TSID
		 * 1 - text
		 * 2 - type (normal, activity, request, etc)
		 * 3 - unix timestamp
		 * 4 - if they're an admin
		 * 5 - PC label
		 * 6 - if they're a guide
		 *********************************************/
		
		public function ChatHistoryElement(){}
		
		public static function fromHistoryArray(str:String):ChatHistoryElement {
			var history:ChatHistoryElement = new ChatHistoryElement();
			var chunks:Array = str.split(CHUNK_DIVIDER);
			
			if(chunks.length > 0) history.tsid = chunks[0];
			if(chunks.length > 1) history.text = chunks[1];
			if(chunks.length > 2) history.type = chunks[2];
			if(chunks.length > 3) history.unix_timestamp = uint(chunks[3]);
			if(chunks.length > 4) history.is_admin = chunks[4] == 'true';
			if(chunks.length > 5) history.label = chunks[5];
			if(chunks.length > 6) history.is_guide = chunks[6] == 'true';
						
			return history;
		}
		
		public static function toHistoryArray(element:ChatElement):String {
			if(!element || (element && !element.pc_tsid)) return null;
						
			var pc:PC = TSModelLocator.instance.worldModel.getPCByTsid(element.pc_tsid);
			var str:String = 
				element.pc_tsid+CHUNK_DIVIDER+
				element.text+CHUNK_DIVIDER+
				element.type+CHUNK_DIVIDER+
				element.unix_timestamp+CHUNK_DIVIDER+
				(pc ? pc.is_admin : false)+CHUNK_DIVIDER+
				(pc ? pc.label : '')+CHUNK_DIVIDER+
				(pc ? pc.is_guide : false);
			
			return str;
		}
	}
}