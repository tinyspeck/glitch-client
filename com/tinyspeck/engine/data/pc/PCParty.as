package com.tinyspeck.engine.data.pc {
	import com.tinyspeck.engine.model.TSModelLocator;
	
	public class PCParty extends AbstractPCEntity
	{
		public var tsid:String;
		public var member_tsids:Array;
		public var space_tsids:Array = [];
		
		public function PCParty(hashName:String)
		{
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):PCParty
		{
			var party:PCParty = new PCParty(hashName);
			party.member_tsids = [];
			party.tsid = hashName; // this will eb the tsd of the pc playing

			for(var j:String in object){
				var val:* = object[j];
				if(j == 'members'){
					for (var k:String in val) {
						if (party.member_tsids.indexOf(k) > -1) continue;
						if (k == party.tsid) continue; //don't add yourself
						party.member_tsids.push(k);
					}
					
				}else if(j in party){
					party[j] = val;
				}else{
					resolveError(party,object,j);
				}
			}
			return party;
		}
		
		public function amIInThePartySpace():Boolean {
			if (!space_tsids) return false;
			if (!space_tsids.length) return false;
			if (space_tsids.indexOf(TSModelLocator.instance.worldModel.location.tsid) > -1) return true;
			return false;
		}
	}
}
