package com.tinyspeck.engine.data.party
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;

	public class PartySpace extends AbstractTSDataEntity
	{
		public var location_name:String;
		public var img_url:String;
		public var desc:String;
		public var energy_cost:uint;
		public var pcs:Vector.<PC> = new Vector.<PC>();
		
		public function PartySpace(){
			super('party_space');
		}
		
		public static function fromAnonymous(object:Object):PartySpace {
			var party:PartySpace = new PartySpace();
			var j:String;
			var i:int;
			
			for(j in object){
				if(j == 'pcs'){
					party.pcs = PC.parseMultiple(object[j]);
					
					//make sure they are in the world
					const world:WorldModel = TSModelLocator.instance.worldModel;
					if(!world) continue;
					
					var pc:PC;
					
					for(i = 0; i < party.pcs.length; i++){
						pc = world.getPCByTsid(party.pcs[int(i)].tsid);
						if(!pc) world.pcs[party.pcs[int(i)].tsid] = party.pcs[int(i)];
					}
				}
				else if(j in party){
					party[j] = object[j];
				}
				else{
					resolveError(party,object,j);
				}
			}
			
			return party;
		}
	}
}