package com.tinyspeck.engine.data.mail
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class MailItem extends AbstractTSDataEntity
	{
		public var class_tsid:String;
		public var count:uint;
		public var config:Object;
		public var is_broken:Boolean;
		public var points_capacity:int;
		public var points_remaining:int;
		
		public function MailItem(class_tsid:String){
			super(class_tsid);
			this.class_tsid = class_tsid;
		}
		
		public static function fromAnonymous(object:Object, class_tsid:String):MailItem {
			var item:MailItem = new MailItem(class_tsid);
			var k:String;
			
			for(k in object){
				if(k in item){
					item[k] = object[k];
				}
				else {
					resolveError(item,object,k);
				}
			}
			
			return item;
		}
	}
}