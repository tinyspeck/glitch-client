package com.tinyspeck.engine.data.garden
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;

	public class GardenPlot extends AbstractTSDataEntity
	{
		public var label:String;
		public var class_tsid:String;
		public var plot_id:int;
		public var water_time:int;
		public var grow_time:int;
		public var max_grow_time:int;
		public var mature_level:int;
		public var harvestable:Boolean;
		public var fertilized:Boolean;
		public var planter_tsid:String;
		
		public function GardenPlot(plot_id:int){
			super(plot_id.toString());
			this.plot_id = plot_id;
		}
		
		public static function parseMultiple(object:Object):Vector.<GardenPlot> {
			var plots:Vector.<GardenPlot> = new Vector.<GardenPlot>();
			var plot:GardenPlot;
			var k:String;
			
			for(k in object){
				plot = fromAnonymous(object[k], int(k));
				plots.push(plot);
			}
			
			return plots;
		}
		
		public static function fromAnonymous(object:Object, plot_id:int):GardenPlot {
			var plot:GardenPlot = new GardenPlot(plot_id);
			var val:*;
			var j:String;
			
			for(j in object){
				val = object[j];
				if(j in plot){
					plot[j] = val;
				}
				else{
					resolveError(plot,object,j);
				}
			}
			
			return plot;
		}
		
		public static function updateFromAnonymous(object:Object, plot:GardenPlot):GardenPlot {
			plot = fromAnonymous(object, int(plot.hashName));
			
			return plot;
		}
	}
}