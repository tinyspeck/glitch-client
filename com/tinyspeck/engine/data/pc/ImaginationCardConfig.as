package com.tinyspeck.engine.data.pc
{
	public class ImaginationCardConfig extends AbstractPCEntity
	{
		public var bg:String = 'bg_';
		public var pattern:String = 'pattern_';
		public var suit:String = 'suit_';
		public var art:String = 'art_';
		public var icon:String = 'icon_';
		public var item_tsid:String;
		public var hide_front_name:Boolean;
		
		public function ImaginationCardConfig(){
			super('card_config');
		}
		
		public static function fromAnonymous(object:Object):ImaginationCardConfig {
			const config:ImaginationCardConfig = new ImaginationCardConfig();
			var j:String;
			
			for(j in object){
				if(j == 'item_tsid'){
					config.item_tsid = object[j];
				}
				else if(j in config){
					//this adds the config param, and if it's passed in different, we edit this instead of the UI
					config[j] += object[j];
				}
				else {
					resolveError(config, object, j);
				}
			}
			
			return config;
		}
	}
}