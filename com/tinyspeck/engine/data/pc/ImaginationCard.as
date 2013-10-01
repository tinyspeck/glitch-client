package com.tinyspeck.engine.data.pc
{
	import com.tinyspeck.engine.util.SortTools;

	public class ImaginationCard extends AbstractPCEntity
	{
		public var id:int;
		public var class_tsid:String;
		public var name:String;
		public var desc:String;
		public var cost:int;
		public var config:ImaginationCardConfig;
		
		public function ImaginationCard(id:int){
			super('card_'+id);
			this.id = id;
		}
		
		public static function parseMultiple(object:Object):Vector.<ImaginationCard> {
			var V:Vector.<ImaginationCard> = new Vector.<ImaginationCard>();
			var i:int;
			
			while(object[i] && 'id' in object[i]){
				V.push(fromAnonymous(object[i], object[i].id));
				i++;
			}
			
			SortTools.vectorSortOn(V, ['id'], [Array.NUMERIC]);
			
			return V;
		}
		
		public static function fromAnonymous(object:Object, id:int):ImaginationCard {
			var card:ImaginationCard = new ImaginationCard(id);
			return updateFromAnonymous(object, card);
		}
		
		public static function updateFromAnonymous(object:Object, card:ImaginationCard):ImaginationCard {
			var j:String;
			
			for(j in object){
				if(j == 'config'){
					card.config = ImaginationCardConfig.fromAnonymous(object[j]);
				}
				else if(j in card){
					card[j] = object[j];
				}
				else {
					resolveError(card, object, j);
				}
			}
			
			return card;
		}
	}
}