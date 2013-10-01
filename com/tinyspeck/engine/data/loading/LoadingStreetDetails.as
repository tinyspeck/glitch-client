package com.tinyspeck.engine.data.loading
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class LoadingStreetDetails extends AbstractTSDataEntity
	{
		public var active_project:Boolean;
		public var features:Vector.<String> = new Vector.<String>();
		
		public function LoadingStreetDetails(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):LoadingStreetDetails {
			var street_details:LoadingStreetDetails = new LoadingStreetDetails(hashName);
			var val:*;
			var j:String;
			var count:int;
			
			for(j in object){
				val = object[j];
				if(j == 'features'){
					count = 0;
					while(val && val[count]){
						street_details.features.push(val[count]);
						count++;
					}
				}
				else if(j in street_details){
					street_details[j] = val;
				}
				else{
					resolveError(street_details,object,j);
				}
			}
			
			return street_details;
		}
		
		public static function updateFromAnonymous(object:Object, street_details:LoadingStreetDetails):LoadingStreetDetails {
			street_details = fromAnonymous(object, street_details.hashName);
			
			return street_details;
		}
	}
}