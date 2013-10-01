package com.tinyspeck.engine.data
{
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.util.StringUtil;

	public class SDBItemInfo extends AbstractTSDataEntity
	{
		public var sdb_tsid:String;
		public var qty:Number;
		public var price_per_unit:Number;
		public var owner_label:String;
		public var owner_tsid:String;
		public var location_type:String;
		public var location_tsid:String;
		public var external_street_tsid:String; //home street TSID, used for disabling the button
		public var item_class_tsid:String;
		public var date_updated:uint;
		
		public function SDBItemInfo(sdb_tsid:String){
			super(sdb_tsid);
			this.sdb_tsid = sdb_tsid;
		}
		
		public static function parseMultiple(object:Object):Vector.<SDBItemInfo> {
			const V:Vector.<SDBItemInfo> = new Vector.<SDBItemInfo>();
			var j:String;
			
			for(j in object){
				if('item_class_tsid' in object[j]){
					V.push(fromAnonymous(object[j], j));
				}
			}
			
			//sort by qty and sale price
			SortTools.vectorSortOn(V, ['price_per_unit'], [Array.NUMERIC]);
			
			return V;
		}
		
		public static function fromAnonymous(object:Object, sdb_tsid:String):SDBItemInfo {
			const sdb_item:SDBItemInfo = new SDBItemInfo(sdb_tsid);
			return updateFromAnonymous(object, sdb_item);
		}
		
		public static function updateFromAnonymous(object:Object, sdb_item:SDBItemInfo):SDBItemInfo {			
			var k:String;
			
			for(k in object){
				if(k in sdb_item){
					sdb_item[k] = object[k];
				}
				else {
					resolveError(sdb_item,object,k);
				}
			}
			
			//encode the crazy HTML
			if(sdb_item.owner_label.indexOf('<') != -1 || sdb_item.owner_label.indexOf('>') != -1){
				sdb_item.owner_label = StringUtil.encodeHTMLUnsafeChars(sdb_item.owner_label, false);
			}
			
			return sdb_item;
		}
	}
}