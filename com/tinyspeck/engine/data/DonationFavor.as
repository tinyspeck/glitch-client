package com.tinyspeck.engine.data
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.giant.GiantFavor;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;

	public class DonationFavor extends AbstractTSDataEntity
	{
		public static const AMOUNT_ROUND:uint = 10; //if the amount goes over this, we round it
		
		public var shrine_tsid:String;
		public var giant_tsid:String;
		public var item_class:String;
		public var item_favor:Number;
		public var single_stack_only:Boolean;
		
		public function DonationFavor(){
			super('donation_favor');
		}
		
		public static function fromAnonymous(object:Object):DonationFavor {
			const donation_favor:DonationFavor = new DonationFavor();
			return updateFromAnonymous(object, donation_favor);
		}
		
		public static function updateFromAnonymous(object:Object, donation_favor:DonationFavor):DonationFavor {
			var k:String;
			
			for(k in object){
				if(k == 'favor' && 'name' in object[k]){
					//update the PC with the latest and greatest
					const pc:PC = TSModelLocator.instance.worldModel.pc;
					if(pc && pc.stats && pc.stats.favor_points){
						var favor:GiantFavor = pc.stats.favor_points.getFavorByName(object[k].name);
						if(favor){
							favor = GiantFavor.updateFromAnonymous(object[k], favor);
							donation_favor.giant_tsid = favor.name;
						}
						else {
							CONFIG::debugging {
								Console.warn('WHAT GIANT ARE YOU PASSING?!!?', object[k].name);
							}
						}
					}
				}
				else if(k == 'item_favor'){
					//see if we need to round it
					donation_favor.item_favor = object[k];
					if(donation_favor.item_favor >= AMOUNT_ROUND){
						donation_favor.item_favor = int(donation_favor.item_favor);
					}
				}
				else if(k in donation_favor){
					donation_favor[k] = object[k];
				}
				else{
					resolveError(donation_favor,object,k);
				}
			}
			
			return donation_favor;
		}
	}
}