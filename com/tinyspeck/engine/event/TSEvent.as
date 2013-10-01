package com.tinyspeck.engine.event {
	
	import flash.events.Event;
	
	public class TSEvent extends Event {
		
		// FOR PORT' ebentually this will all go away
		
		public static const STAT_CHANGE_HAPPENED:String = 'TS_STAT_CHANGE_HAPPENED';
		public static const ACTIVITY_HAPPENED:String = 'TS_ACTIVITY_HAPPENED';
		public static const QUEST_OFFERED:String = 'TS_QUEST_OFFERED';
		public static const QUEST_UPDATED:String = 'TS_QUEST_UPDATED';
		public static const QUEST_COMPLETE:String = 'TS_QUEST_COMPLETE';
		public static const BUDDY_ADDED:String = 'TS_BUDDY_ADDED';
		public static const BUDDY_REMOVED:String = 'TS_BUDDY_REMOVED';
		public static const BUDDY_ONLINE:String = 'TS_BUDDY_ONLINE';
		public static const BUDDY_OFFLINE:String = 'TS_BUDDY_OFFLINE';
		public static const CHANGED:String = 'TS_CHANGED';
		public static const SOCKET_UNEXPECTEDLY_CLOSED:String = 'TS_SOCKET_UNEXPECTEDLY_CLOSED';
		public static const SOCKET_SUCCESSFULLY_CLOSED:String = 'TS_SOCKET_SUCCESSFULLY_CLOSED';
		public static const DRAG_STARTED:String = 'TS_DRAG_STARTED';
		public static const DRAG_COMPLETE:String = 'TS_DRAG_COMPLETE';
		public static const STARTED:String = 'TS_STARTED';
		public static const COMPLETE:String = 'TS_COMPLETE';
		public static const SOCKET_RSP_MSG_ID_:String = 'TS_SOCKET_RSP_MSG_ID_';
		public static const SOCKET_RSP_TYPE_:String = 'TS_SOCKET_RSP_TYPE_';
		public static const SOCKET_EVT_TYPE_:String = 'TS_SOCKET_EVT_TYPE_';
		public static const YOU_MOVED_IN_LOCATION:String = 'TS_YOU_MOVED_IN_LOCATION';
		public static const PC_STATS_CHANGED_:String = 'TS_PC_STATS_CHANGED_';
		public static const PC_A_STAT_CHANGED_:String = 'TS_PC_A_STAT_CHANGED_';
		public static const LOCATION_GAINED_A_PC_:String = 'TS_LOCATION_GAINED_A_PC_';
		public static const LOCATION_LOST_A_PC_:String = 'TS_LOCATION_LOST_A_PC_';
		public static const ITEMSTACK_HAS_BUBBLE_:String = 'TS_ITEMSTACK_HAS_BUBBLE_';
		public static const CONTAINER_GAINED_AN_ITEMSTACK_:String = 'TS_CONTAINER_GAINED_AN_ITEMSTACK_';
		public static const CONTAINER_LOST_AN_ITEMSTACK_:String = 'TS_CONTAINER_LOST_AN_ITEMSTACK_';
		public static const CONTAINERS_ITEMSTACK_CHANGED_:String = 'TS_CONTAINERS_ITEMSTACK_CHANGED_';
		public static const MSG_SENT:String = 'TS_MSG_SENT';
		public static const MSG_RECEIVED:String = 'TS_MSG_RECEIVED';
		public static const IM_RECEIVED_:String = 'TS_IM_RECEIVED_';
		public static const GLOBAL_CHAT_RECEIVED:String = 'TS_GLOBAL_CHAT_RECEIVED';
		public static const LOCAL_CHAT_RECEIVED:String = 'TS_LOCAL_CHAT_RECEIVED';
		public static const PARTY_CHAT_RECEIVED:String = 'TS_PARTY_CHAT_RECEIVED';
		public static const PC_LOCAL_CHAT_RECEIVED_:String = 'TS_PC_LOCAL_CHAT_RECEIVED_';
		public static const GROUP_CHAT_RECEIVED_:String = 'TS_GROUP_CHAT_RECEIVED_';
		public static const FOCUS_IN:String = 'TS_FOCUS_IN';
		public static const FOCUS_OUT:String = 'TS_FOCUS_OUT';
		public static const QUANTITY_CHANGE:String = 'TS_QUANTITY_CHANGE';
		public static const CLOSE:String = 'TS_CLOSE';
		public static const MOVED:String = 'TS_MOVED';
		public static const TOGGLE:String = 'TS_TOGGLE';
		public static const CHAT_STARTED:String = 'TS_CHAT_STARTED';
		public static const CHAT_UPDATED:String = 'TS_CHAT_UPDATED';
		public static const CHAT_ENDED:String = 'TS_CHAT_ENDED';
		public static const ERROR:String = 'TS_ERROR';
		public static const SOUND_COMPLETE:String = 'TS_SOUND_COMPLETE';
		public static const TIMER_TICK:String = 'TS_TIMER_TICK';
		public static const GROUPS_CHANGED:String = 'TS_GROUPS_CHANGED';
		public static const FEED_UPDATED:String = 'TS_FEED_UPDATED';
		public static const ACTION_REQUEST_CANCEL:String = 'TS_ACTION_REQUEST_CANCEL';
		
		// END FOR PORT
				
		public static const LOCATION_BUILT:String = 'TS_STREET_BUILT';
		
		private var _data:*;
		
		public function TSEvent(type:String, data:* = null, bubbles:Boolean = false, cancelable:Boolean = false) {
			super(type, bubbles, cancelable);
			_data = data;
		}

		public function get data():*{
			return _data;
		}
		
	}
}