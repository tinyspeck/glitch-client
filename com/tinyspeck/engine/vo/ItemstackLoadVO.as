package com.tinyspeck.engine.vo
{
	import com.tinyspeck.engine.data.item.Item;

	public class ItemstackLoadVO extends ArbitrarySWFLoadVO
	{
		public var item:Item;
		
		public function ItemstackLoadVO(url:String, item:Item) {
			super(url);
			this.item = item;
		}
	}
}