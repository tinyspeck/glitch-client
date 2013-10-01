package com.tinyspeck.engine.data.house
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.util.SortTools;

	public class HouseStyles extends AbstractTSDataEntity
	{
		public var cost:int;
		public var choices:Vector.<HouseStylesChoice> = new Vector.<HouseStylesChoice>();
		
		public function HouseStyles(){
			super('house_styles');
		}
		
		public static function fromAnonymous(object:Object):HouseStyles {
			const styles:HouseStyles = new HouseStyles();
			return updateFromAnonymous(object, styles);
		}
		
		public static function updateFromAnonymous(object:Object, styles:HouseStyles):HouseStyles {
			var j:String;
			var k:String;
			
			for(j in object){
				if(j == 'choices'){
					//parse out the choices
					for(k in object[j]){
						styles.choices.push(HouseStylesChoice.fromAnonymous(object[j][k], k));
					}
				}
				else if(j in styles){
					styles[j] = object[j];
				}
				else {
					resolveError(styles, object, j);
				}
			}
			
			//sort the choices
			SortTools.vectorSortOn(styles.choices, ['tsid'], [Array.CASEINSENSITIVE]);
			
			return styles;
		}
		
		public function getChoiceByTsid(tsid:String):HouseStylesChoice {
			var i:int;
			var total:int = choices.length;
			
			for(i; i < total; i++){
				if(choices[int(i)].tsid == tsid) return choices[int(i)];
			}
			
			return null;
		}
	}
}