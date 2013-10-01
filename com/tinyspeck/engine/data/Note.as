package com.tinyspeck.engine.data
{
	public class Note extends AbstractTSDataEntity
	{
		public var title:String;
		public var body:String;
		public var disabled_reason:String;
		public var start_in_edit_mode:Boolean;
		public var itemstack_tsid:String;
		public var updated:int;
		public var owner_label:String;
		public var owner_tsid:String;
		public var max_chars:int;
		public var can_take:Boolean;
		public var background_url:String;
		public var signed_by:Boolean;
		
		public function Note(hashName:String){
			super(hashName);
			itemstack_tsid = hashName;
		}
		
		public static function parseMultiple(object:Object):Vector.<Note> {
			var notes:Vector.<Note> = new Vector.<Note>();
			var j:String;
			
			for(j in object){
				notes.push(fromAnonymous(object[j],j));
			}
			
			return notes;
		}
		
		public static function fromAnonymous(object:Object, hashName:String):Note {
			var note:Note = new Note(hashName);
			var val:*;
			var j:String;
			
			for(j in object){
				val = object[j];
				if(j == 'pc' && val){
					//just sent the label and tsid
					note.owner_label = val['label'];
					note.owner_tsid = val['tsid'];
				}
				else if(j in note){
					note[j] = val;
				}
				else{
					resolveError(note,object,j);
				}
			}
			
			return note;
		}
		
		public static function updateFromAnonymous(object:Object, note:Note):Note {
			note = fromAnonymous(object, note.hashName);
			
			return note;
		}
	}
}