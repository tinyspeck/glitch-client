package com.tinyspeck.engine.util
{
	import com.tinyspeck.engine.data.location.AbstractLocationEntity;
	import com.tinyspeck.engine.data.location.Deco;
	import com.tinyspeck.engine.data.location.Layer;
	import com.tinyspeck.engine.data.location.LocationConnection;
	import com.tinyspeck.engine.data.requirement.Requirement;
	import com.tinyspeck.engine.data.reward.Reward;
	
	import flash.display.DisplayObject;

	public class SortTools
	{
		/** SLOW! Assumes all DisplayObjects are on the display list and siblings of each other */
		public static function displayObjectZSort(a:DisplayObject, b:DisplayObject):int {
			if(a.parent.getChildIndex(a) > b.parent.getChildIndex(b)){
				return 1;
			}
			return -1;
		}
		
		public static function layerZSort(layerA:Layer, layerB:Layer):int {
			if(layerA.z > layerB.z){
				return 1;
			}
			return -1;
		}
		
		public static function decoZSort(decoA:Deco, decoB:Deco):int {
			return (decoA.z > decoB.z) ? 1 : -1;
		}
		
		public static function sortByTSID(entityA:AbstractLocationEntity, entityB:AbstractLocationEntity):int
		{
			if(entityA.tsid > entityB.tsid){
				return 1;
			}
			return -1;
		}
		
		public static function vectorSortOn(V:*, fields:Array, options:Array):void {
			var A:Array = [];
			var i:int;
			
			for (i=0;i<V.length;i++) A[int(i)] = V[int(i)];
			A.sortOn(fields, options);
			for (i=0;i<A.length;i++) V[int(i)] = A[int(i)];
		}
		
		public static function shuffleArray(array:Array):Array {
			var shuffled:Array = new Array();
			
			while(array.length > 0){
				var chunk:Array = array.splice(Math.floor(Math.random() * array.length), 1);
				shuffled.push(chunk[0]);
			}
			
			return shuffled;
		}
		
		public static function requirementsSort(reqA:Requirement, reqB:Requirement):int {
			//r1, r2, etc...
			var a:int = int(reqA.hashName.substring(1));
			var b:int = int(reqB.hashName.substring(1));
			
			return a - b;
		}
		
		public static function connectionsSort(conA:LocationConnection, conB:LocationConnection):int {
			//mostly in the format of 1_2, 1_14, etc (col_row)
			var chunksA:Array = conA.button_position.split('_');
			var chunksB:Array = conB.button_position.split('_');
			
			var colA:int = chunksA[0];
			var colB:int = chunksB[0];
			var rowA:int;
			var rowB:int;
			
			//if the column in A is greater than B (or vise versa) than we already know how to spit it out
			if(colA != colB){
				return colA - colB;
			}
			
			if(chunksA[1] && chunksB[1]){
				//we have rows!
				rowA = chunksA[1];
				rowB = chunksB[1];
				
				return rowA - rowB;
			}
			
			return 0;
		}
		
		public static function rewardsSort(rwdA:Reward, rwdB:Reward):int {
			//TODO: SY sort by, xp, energy, mood, currants, favor, items
			if(rwdA.type == Reward.ITEMS) return 1;
			if(rwdA.hashName.indexOf('id') >= 0 && rwdB.hashName.indexOf('id') >= 0) return 1; //LEGACY SUPPORT FOR QUEST DIALOG
			if(rwdA.hashName.indexOf('id') < 0 && rwdB.hashName.indexOf('id') >= 0) return 0; //LEGACY SUPPORT FOR QUEST DIALOG
			
			return -1;
		}
	}
}