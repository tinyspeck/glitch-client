package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.storage.Cabinet;
	
	import flash.events.EventDispatcher;

	
	/*
	{
	type:"cabinet_start",
	itemstack_tsid:"I9sdhkj", // the tsid of the cabinet that was opened
	cols: 4,
	rows: 2,
	itemstacks:{
	... // a hash of itemstacks the cabinet contains, looks just like an itemstack hash in location start
	},
	}
	*/
	
	public class CabinetManager extends EventDispatcher
	{
		private var _cabinets:Vector.<Cabinet> = new Vector.<Cabinet>();
		
		/* singleton boilerplate */
		public static const instance:CabinetManager = new CabinetManager();
		
		public function CabinetManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function start(payload:Object):Boolean {			
			if(payload.itemstack_tsid){
				var cabinet:Cabinet = Cabinet.getCabinetByTsid(payload.itemstack_tsid);
				var anonCabinet:Cabinet = Cabinet.fromAnonymous(payload, payload.itemstack_tsid);
				
				if(cabinet != null){
					//update
					var index:int = cabinets.indexOf(cabinet);
					cabinets.splice(index, 1);
					cabinets[index] = anonCabinet;
				}else{
					cabinets.push(anonCabinet);
				}
				
				CabinetDialog.instance.start(anonCabinet);
				
				return true;
			}
			
			CONFIG::debugging {
				Console.warn('start did not get the itemstack_tsid');
			}
			return false;
		}
		
		public function cabinetEndHandler(payload:Object):void {
			if(payload.itemstack_tsid){
				var cabinet:Cabinet = Cabinet.getCabinetByTsid(payload.itemstack_tsid);
				var index:int = cabinets.indexOf(cabinet);
				cabinets.splice(index, 1);
				
				CabinetDialog.instance.end();
				
			}else{
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('cabinetEndHandler did not get the itemstack_tsid');
				}
			}
		}
		
		public function isTsidInCabinets(tsids:Array):Boolean {
			var i:int;
			var total:int = cabinets.length;
			var cabinet:Cabinet;
			var chunks:Array = [];
			
			//only get the bag tsids outta the tsids
			for(i = 0; i < tsids.length; i++){
				chunks.push(String(tsids[int(i)]).split('/')[0]);
			}
			
			//loop through the cases to see if the private or public back are a hit on the chunks
			for(i = 0; i < total; i++){
				cabinet = cabinets[int(i)];
				
				if(chunks.indexOf(cabinet.itemstack_tsid) > -1){
					return true;
				}
			}
			
			return false;
		}
		
		public function get cabinets():Vector.<Cabinet> {
			return _cabinets;
		}
	}
}