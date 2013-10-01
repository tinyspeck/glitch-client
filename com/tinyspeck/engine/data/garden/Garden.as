package com.tinyspeck.engine.data.garden
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;

	public class Garden extends AbstractTSDataEntity
	{
		/******************************************
		 * http://wiki.tinyspeck.com/wiki/Gardens *
		 ******************************************/
		
		public static const TYPE_DEFAULT:String = 'default';
		
		public var label:String;
		public var itemstack_tsid:String;
		public var style:String;
		public var rows:int;
		public var cols:int;
		public var x:int;
		public var y:int;
		public var max_water_time:int;
		public var water_threshold:int;
		public var owner_tsid:String;
		public var owner_tsids:Array;
		public var plots:Vector.<GardenPlot> = new Vector.<GardenPlot>();
		public var type:String;
		public var proto_class:String; //not sure what this is for, but I was tired of seeing it in the console
		
		public function Garden(hashName:String){
			super(hashName);
			itemstack_tsid = hashName;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Garden {
			const world:WorldModel = TSModelLocator.instance.worldModel;
			var garden:Garden = new Garden(hashName);
			var val:*;
			var j:String;
			var count:int;
			var pc:PC;
			
			for(j in object){
				val = object[j];
				if(j == 'plots'){
					garden.plots = GardenPlot.parseMultiple(val);
				}
				else if(j == 'owner'){
					pc = world.getPCByTsid(val.tsid);
					if(pc) {
						pc = PC.updateFromAnonymous(val, pc);
					}
					else {
						pc = PC.fromAnonymous(val, val.tsid);
					}
					
					world.pcs[pc.tsid] = pc;
					
					garden.owner_tsid = val.tsid;
				}
				else if(j in garden){
					garden[j] = val;
				}
				else{
					resolveError(garden,object,j);
				}
			}
			
			if(!garden.style) garden.style = GardenStyle.NONE;
			
			return garden;
		}
		
		public static function updateFromAnonymous(object:Object, garden:Garden):Garden {
			garden = fromAnonymous(object, garden.hashName);
			
			return garden;
		}
	}
}