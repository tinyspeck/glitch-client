package com.tinyspeck.engine.data.house
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class HouseStylesChoice extends AbstractTSDataEntity
	{
		public var tsid:String;
		public var image:String;
		public var main_image:String;
		public var loading_image:String;
		public var is_subscriber:Boolean;
		public var label:String;
		public var is_current:Boolean;
		public var admin_only:Boolean;
		
		public function HouseStylesChoice(tsid:String){
			super(tsid);
			this.tsid = tsid;
		}
		
		public static function fromAnonymous(object:Object, tsid:String):HouseStylesChoice {
			const choice:HouseStylesChoice = new HouseStylesChoice(tsid);
			return updateFromAnonymous(object, choice);
		}
		
		public static function updateFromAnonymous(object:Object, choice:HouseStylesChoice):HouseStylesChoice {
			var j:String;
			
			for(j in object){
				if(j in choice){
					choice[j] = object[j];
				}
				else {
					resolveError(choice, object, j);
				}
			}
			
			return choice;
		}
	}
}