package com.tinyspeck.engine.data.rook
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class RookDamage extends AbstractTSDataEntity
	{
		public var damage:int;
		public var txt:String;
		public var defeated:Boolean;
		
		public function RookDamage(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object):RookDamage {
			var damage:RookDamage = new RookDamage('rook_damage');
			var j:String;
			
			for(j in object){
				if(j in damage){
					damage[j] = object[j];
				}
				else{
					resolveError(damage,object,j);
				}
			}
			
			return damage;
		}
	}
}