package com.tinyspeck.engine.data
{
	public class Emblem extends AbstractTSDataEntity
	{
		public var itemstack_tsid:String;
		public var speed_up:uint;
		public var is_primary:Boolean;
		public var is_secondary:Boolean;
		
		public function Emblem(itemstack_tsid:String){
			super(itemstack_tsid);
			this.itemstack_tsid = itemstack_tsid;
		}
		
		public static function fromAnonymous(object:Object):Emblem {
			var emblem:Emblem = new Emblem(object.itemstack_tsid);
			var j:String;
			
			for(j in object){
				if(j in emblem){
					emblem[j] = object[j];
				}
				else{
					resolveError(emblem,object,j);
				}
			}
			
			return emblem;
		}
	}
}