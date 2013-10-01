package com.tinyspeck.engine.data.storage
{	
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.CabinetManager;
	
	import flash.utils.Dictionary;

	public class Cabinet extends AbstractTSDataEntity
	{
		public var itemstack_tsid:String;
		public var cols:uint;
		public var rows:uint;
		public var rows_display:uint; //how many do you see at one time. Used to set the scroll rect
		public var itemstack_tsid_list:Dictionary = new Dictionary();
		
		public function Cabinet(hashName:String)
		{
			super(hashName);
		}
		
		public static function parseMultiple(object:Object):Vector.<Cabinet>
		{		
			var cabinets:Vector.<Cabinet> = CabinetManager.instance.cabinets;
			var cabinet:Cabinet;
			
			for(var j:String in object){
				cabinet = getCabinetByTsid(j);
				if(!cabinet){
					cabinets.push(fromAnonymous(object[j],j));
				}else{
					cabinets[cabinets.indexOf(cabinet)] = updateFromAnonymous(object[j], cabinet);
				}
			}
			return cabinets;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Cabinet
		{
			var model:TSModelLocator = TSModelLocator.instance;
			var cabinet:Cabinet = new Cabinet(hashName);
			var val:*;
			var k:String;
			var itemstack:Itemstack;
			
			for(var j:String in object){
				val = object[j];
				if(j == 'itemstacks'){
					for(k in val) {
						itemstack = model.worldModel.getItemstackByTsid(k);
						if(itemstack){
							model.worldModel.itemstacks[k] = Itemstack.updateFromAnonymous(val[k], itemstack);
						}
						else {
							if (!Item.confirmValidClass(val[k].class_tsid, k)) {
								continue;
							}
							model.worldModel.itemstacks[k] = Itemstack.fromAnonymous(val[k], k);
						}
						cabinet.itemstack_tsid_list[k] = k;
					}
				}else if(j in cabinet){
					cabinet[j] = val;
				}else{
					resolveError(cabinet,object,j);
				}
			}
			return cabinet;
		}
		
		public static function updateFromAnonymous(object:Object, cabinet:Cabinet):Cabinet 
		{
			cabinet = fromAnonymous(object, cabinet.hashName);
			
			return cabinet;
		}
		
		public static function getCabinetByTsid(tsid:String):Cabinet 
		{
			var cabinet:Cabinet;
			var i:int = 0;
			var cabinets:Vector.<Cabinet> = CabinetManager.instance.cabinets;
			var total:int = cabinets.length;
			
			for(i; i < total; i++){
				cabinet = cabinets[int(i)];
				if(cabinet.itemstack_tsid == tsid){
					return cabinet;
				}
			}
			
			return null;
		}
	}
}