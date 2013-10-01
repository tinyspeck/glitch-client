package com.tinyspeck.engine.data.house
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.util.SortTools;

	public class Cultivations extends AbstractTSDataEntity
	{
		public var cost:int;
		public var choices:Vector.<CultivationsChoice> = new Vector.<CultivationsChoice>();
		
		public function Cultivations(){
			super('house_styles');
		}
		
		public static function fromAnonymous(object:Object):Cultivations {
			const cultivations:Cultivations = new Cultivations();
			return updateFromAnonymous(object, cultivations);
		}
		
		public static function updateFromAnonymous(object:Object, cultivations:Cultivations):Cultivations {
			var j:String;
			var k:String;
			
			for(j in object){
				if(j == 'choices'){
					cultivations.choices.length = 0;
					//parse out the choices
					for(k in object[j]){
						cultivations.choices.push(CultivationsChoice.fromAnonymous(object[j][k], k));
					}

				}
				else if(j in cultivations){
					cultivations[j] = object[j];
				}
				else {
					resolveError(cultivations, object, j);
				}
			}
			
			return cultivations;
		}
		
		public function getChoiceByTsid(tsid:String):CultivationsChoice {
			var i:int;
			var total:int = choices.length;
			
			for(i; i < total; i++){
				if(choices[int(i)].tsid == tsid) return choices[int(i)];
			}
			
			return null;
		}
	}
}