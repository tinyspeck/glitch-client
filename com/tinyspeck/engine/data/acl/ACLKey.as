package com.tinyspeck.engine.data.acl
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;

	public class ACLKey extends AbstractTSDataEntity
	{
		public var received:uint;
		public var pc_tsid:String;
		public var location_tsid:String;
		
		public function ACLKey(pc_tsid:String){
			super(pc_tsid);
			this.pc_tsid = pc_tsid;
		}
		
		public static function parseMultiple(keys:Object):Vector.<ACLKey> {
			const V:Vector.<ACLKey> = new Vector.<ACLKey>();
			var j:String;
			
			for(j in keys){
				if('pc' in keys[j] && 'tsid' in keys[j].pc){
					V.push(fromAnonymous(keys[j], keys[j].pc.tsid));
				}
			}
			
			return V;
		}
		
		public static function fromAnonymous(object:Object, pc_tsid:String):ACLKey {
			var key:ACLKey = new ACLKey(pc_tsid);
			return updateFromAnonymous(object, key);
		}
		
		public static function updateFromAnonymous(object:Object, key:ACLKey):ACLKey {
			const world:WorldModel = TSModelLocator.instance.worldModel;
			if(!world) return key;
			
			var k:String;
			var val:*;
			
			for(k in object){
				val = object[k];
				
				if(k == 'pc' && val){
					//let the world know
					var pc:PC = world.getPCByTsid(val.tsid);
					if(!pc){
						pc = PC.fromAnonymous(val, val.tsid);
					}
					else {
						pc = PC.updateFromAnonymous(val, pc);
					}
					
					key.pc_tsid = pc.tsid;
					
					world.pcs[pc.tsid] = pc;
				}
				else if(k == 'location' && val && 'street_tsid' in val){
					//toss it in the world
					var location:Location = world.getLocationByTsid(val.street_tsid);
					if(!location){
						location = Location.fromAnonymousLocationStub(val);
					}
					location.is_pol = true;
					if('pol_img_150' in val){
						location.pol_img_150 = val.pol_img_150;
					}
					
					key.location_tsid = location.tsid;
					
					world.locations[location.tsid] = location;
				}
				else if(k in key){
					key[k] = val;
				}
				else {
					resolveError(key,object,k);
				}
			}
			
			return key;
		}
	}
}