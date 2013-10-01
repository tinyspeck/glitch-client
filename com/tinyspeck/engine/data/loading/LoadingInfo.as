package com.tinyspeck.engine.data.loading
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.util.StringUtil;

	public class LoadingInfo extends AbstractTSDataEntity
	{
		public static const POL_TYPE_INTERIOR:String = 'interior';
		public static const POL_TYPE_EXTERIOR:String = 'exterior';
		public static const POL_TYPE_TOWER:String = 'tower';
		
		public var to_tsid:String;
		public var street_name:String;
		public var hub_name:String;
		public var loading_img_url:String;
		public var loading_img_w:int;
		public var loading_img_h:int;
		public var top_color:uint = 0x8a9297;
		public var bottom_color:uint = 0x606669;
		public var owner_tsid:String; //used when entering someone's house
		public var pol_type:String; //used for the different screens when moving around a POL
		public var custom_name:String;
		
		public var imagination:Reward;
		public var street_details:LoadingStreetDetails;
		public var upgrade_details:LoadingUpgradeDetails;
		public var neighbors:Array;
		
		public var first_visit:Boolean;
		public var qurazy_here:Boolean;
		public var is_basic:Boolean;
		
		public var last_visit_mins:int;
		public var visit_count:int;
		
		
		public function LoadingInfo(hashName:String){
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object, hashName:String):LoadingInfo {
			const world:WorldModel = TSModelLocator.instance.worldModel;
			var loading_info:LoadingInfo = new LoadingInfo(hashName);
			var val:*;
			var j:String;
			var pc:PC;
			
			for(j in object){
				val = object[j];
				if(j == 'xp'){
					loading_info.imagination = new Reward(j);
					loading_info.imagination.type = Reward.IMAGINATION;
					loading_info.imagination.amount = val;
				}
				else if(j == 'loading_img' && typeof val == 'object'){
					loading_info.loading_img_url = val.url;
					loading_info.loading_img_w = val.w;
					loading_info.loading_img_h = val.h;
				}
				else if(j == 'street_details'){
					loading_info.street_details = LoadingStreetDetails.fromAnonymous(val, j);
				}
				else if(j == 'upgrade_details'){
					loading_info.upgrade_details = LoadingUpgradeDetails.fromAnonymous(val, j);
				}
				else if(j == 'top_color'){
					loading_info.top_color = StringUtil.cssHexToUint(val);
				}
				else if(j == 'bottom_color'){
					loading_info.bottom_color = StringUtil.cssHexToUint(val);
				}
				else if(j == 'owner_info' && val && 'tsid' in val){
					//entering a house
					pc = world.getPCByTsid(val.tsid);
					if(pc){
						pc = PC.updateFromAnonymous(val, pc);
					}
					else {
						pc = PC.fromAnonymous(val, val.tsid);
					}
					world.pcs[pc.tsid] = pc;
					loading_info.owner_tsid = val.tsid;
				}
				else if(j == 'neighbors'){
					//parse the PC hashes
					var k:String;
					
					loading_info.neighbors = [];
					
					for(k in val){
						pc = world.getPCByTsid(k);
						if(pc){
							pc = PC.updateFromAnonymous(val[k], pc);
						}
						else {
							pc = PC.fromAnonymous(val[k], k);
						}
						world.pcs[pc.tsid] = pc;
						
						//add the tsid to the array
						loading_info.neighbors.push(k);
					}
					
					//sort it
					loading_info.neighbors.sort();
				}
				else if(j in loading_info){
					loading_info[j] = val;
				}
				else{
					if (j == 'unlock_details') {
						// not sure what this is for
						//[SY] this is the data for the players who unlocked the street via a job, we don't use it for anything
					} else {
						resolveError(loading_info,object,j);
					}
				}
			}
			
			//loading_info.qurazy_here = loading_info.first_visit = EnvironmentUtil.getUrlArgValue('SWF_qurazy_here') == '1';
			return loading_info;
		}
		
		public static function updateFromAnonymous(object:Object, loading_info:LoadingInfo):LoadingInfo {
			loading_info = fromAnonymous(object, loading_info.hashName);
			
			return loading_info;
		}
	}
}