package unused
{
import flash.events.IEventDispatcher;

import mx.collections.ArrayList;
import mx.events.CollectionEvent;
import mx.events.CollectionEventKind;

/** An ArrayList that allows any single item to force a collection reset */
public final class ResettableArrayList extends ArrayList
{
	public function ResettableArrayList(source:Array=null) {
		super(source);
	}
	
	override protected function startTrackUpdates(item:Object):void
	{
		super.startTrackUpdates(item);
		if (item && (item is IEventDispatcher))
			IEventDispatcher(item).addEventListener(
				CollectionEvent.COLLECTION_CHANGE, dispatchEvent, false, 0, true);
	}
	
	override protected function stopTrackUpdates(item:Object):void
	{
		super.stopTrackUpdates(item);
		if (item && item is IEventDispatcher)
			IEventDispatcher(item).removeEventListener(
				CollectionEvent.COLLECTION_CHANGE, dispatchEvent);    
	}
	
	public static function getResetEvent():CollectionEvent
	{
		return new CollectionEvent(CollectionEvent.COLLECTION_CHANGE,
			false, false, CollectionEventKind.RESET)
	}
}
}