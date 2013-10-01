package com.tinyspeck.engine.data.house
{
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;

	public class PlayerSignpost extends AbstractTSDataEntity
	{
		public var tsid:String;
		public var signposts:Vector.<Array> = new Vector.<Array>();
		
		public function PlayerSignpost(pc_tsid:String){
			super(pc_tsid);
			this.tsid = pc_tsid;
		}
		
		public static function fromAnonymous(object:Object, pc_tsid:String):PlayerSignpost {
			const signpost:PlayerSignpost = new PlayerSignpost(pc_tsid);
			return updateFromAnonymous(object, signpost);
		}
		
		public static function updateFromAnonymous(object:Object, signpost:PlayerSignpost):PlayerSignpost {
			const world:WorldModel = TSModelLocator.instance.worldModel;
			var k:String;
			var i:int;
			var j:int;
			var connects:Array;
			var pc_obj:Object;
			var pc:PC;
			
			for(k in object){
				if(k == 'signposts'){
					for(i = 0; i < (object[k] as Array).length; i++){
						connects = [];
						signpost.signposts.push(connects);
						
						for(j = 0; j < (object[k][i] as Array).length; j++){
							//jam the tsids of the players into the array, and add them to the world
							pc_obj = object[k][i][j];
							if('tsid' in pc_obj){
								pc = world.getPCByTsid(pc_obj.tsid);
								if(pc){
									pc = PC.updateFromAnonymous(pc_obj, pc);
								}
								else {
									pc = PC.fromAnonymous(pc_obj, pc_obj.tsid);
									world.pcs[pc.tsid] = pc;
								}
								
								//push the player into the connects
								connects.push(pc.tsid);
							}
						}
					}
				}
				else if(k in signpost){
					signpost[k] = object[k];
				}
				else {
					resolveError(signpost, object, k);
				}
			}
			
			return signpost;
		}
	}
}