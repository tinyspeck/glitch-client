package com.tinyspeck.engine.data.house
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class HouseExpand extends AbstractTSDataEntity
	{
		public var costs:Vector.<HouseExpandCosts> = new Vector.<HouseExpandCosts>();
		public var sign_tsid:String;
		
		public function HouseExpand(){
			super('house_expand');
		}
		
		public static function fromAnonymous(object:Object):HouseExpand {
			const expand:HouseExpand = new HouseExpand();
			return updateFromAnonymous(object, expand);
		}
		
		public static function updateFromAnonymous(object:Object, expand:HouseExpand):HouseExpand {
			var j:String;
			var k:String;
			
			for(j in object){
				if(j == 'costs'){
					//parse out the costs
					for(k in object[j]){
						expand.costs.push(HouseExpandCosts.fromAnonymous(object[j][k], k));
					}
				}
				else if(j in expand){
					expand[j] = object[j];
				}
				else {
					resolveError(expand, object, j);
				}
			}
			
			return expand;
		}
		
		public function getCostsByType(type:String):HouseExpandCosts {
			var i:int;
			var total:int = costs.length;
			
			for(i; i < total; i++){
				if(costs[int(i)].hashName == type) return costs[int(i)];
			}
			
			return null;
		}
	}
}