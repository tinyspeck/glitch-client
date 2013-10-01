package com.tinyspeck.engine.data.decorate
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.model.DecorateModel;
	import com.tinyspeck.engine.model.TSModelLocator;

	public class Swatch extends AbstractTSDataEntity
	{
		public static const TYPE_WALLPAPER:String = 'wallpaper';
		public static const TYPE_FLOOR:String = 'floor';
		public static const TYPE_CEILING:String = 'ceiling';
		
		public var tsid:String;
		public var is_owned:Boolean;
		public var cost_credits:int;
		public var swatch:String;
		public var is_new:Boolean;
		public var is_subscriber:Boolean;
		public var admin_only:Boolean;
		public var label:String;
		public var type:String;
		public var category:String;
		public var sort_order:int;
		public var date_purchased:uint;

		public function Swatch(tsid:String){
			super(tsid);
			this.tsid = tsid;
		}
		
		public static function parseMultiple(object:Object, type:String):Vector.<Swatch> {
			const dm:DecorateModel = TSModelLocator.instance.decorateModel;
			var V:Vector.<Swatch> = new Vector.<Swatch>();
			var j:String;
			var swatch:Swatch;
			
			for(j in object){
				if (!object[j].swatch) {
					continue;
					CONFIG::debugging {
						Console.warn(j+' has no swatch');
					}
				}
				if (object[j].admin_only && !CONFIG::god) {
					continue;
					CONFIG::debugging {
						Console.warn(j+' is admin only');
					}
				}
				swatch = dm.getSwatchByTypeAndTsid(j, type);
				
				if(swatch){
					swatch = updateFromAnonymous(object[j], swatch);
				}
				else {
					swatch = fromAnonymous(object[j], j, type);
				}
				
				V.push(swatch);
			}
			
			return V;
		}
		
		public static function fromAnonymous(object:Object, tsid:String, type:String):Swatch {
			const dm:DecorateModel = TSModelLocator.instance.decorateModel;
			var swatch:Swatch = new Swatch(tsid);
			
			//add it to the world if it's not there yet
			if(!dm.getSwatchByTypeAndTsid(tsid, type)){
				switch(type){
					case Swatch.TYPE_WALLPAPER:
						dm.wallpapers.push(swatch);
						break;
					case Swatch.TYPE_FLOOR:
						dm.floors.push(swatch);
						break;
					case Swatch.TYPE_CEILING:
						dm.ceilings.push(swatch);
						break;
					default:
						CONFIG::debugging {
							Console.warn('Swatch type not known: '+type);
						}
						break;
				}
				
				swatch.type = type;
			}
			return updateFromAnonymous(object, swatch);
		}
		
		public static function updateFromAnonymous(object:Object, swatch:Swatch):Swatch {
			var j:String;
			
			for(j in object){
				if(j in swatch){
					swatch[j] = object[j];
				}
				else {
					resolveError(swatch, object, j);
				}
			}
			
			/*if (swatch.tsid == 'lime_stucco') {
				swatch.is_owned = false;
			}*/
			
			return swatch;
		}
	}
}