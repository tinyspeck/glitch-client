package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.Note;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingItemstackVerbVO;
	import com.tinyspeck.engine.net.NetOutgoingNoticeBoardActionVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.util.SortTools;

	public class NoticeBoardManager
	{
		/* singleton boilerplate */
		public static const instance:NoticeBoardManager = new NoticeBoardManager();
		
		private var itemstack_tsid:String;
		private var _max_notes:uint;
		private var _notes:Vector.<Note>;
		
		public function NoticeBoardManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function start(payload:Object):void {
			if(payload.itemstack_tsid){
				itemstack_tsid = payload.itemstack_tsid;
				NoticeBoardDialog.instance.start();
			}
			else {
				CONFIG::debugging {
					Console.warn('Start without an itemstack_tsid!');
				}
			}
		}
		
		public function status(payload:Object):void {
			if(payload.itemstack_tsid){
				itemstack_tsid = payload.itemstack_tsid;
				_max_notes = payload.max_notes;
				
				//parse the notes
				_notes = Note.parseMultiple(payload.notes);
				SortTools.vectorSortOn(_notes, ['updated'], [Array.DESCENDING]);
				
				//tuck a reference of the note in the world if it's not there already
				/*
				var i:int;
				var itemstack:Itemstack;
				
				for(i; i < _notes.length; i++){
					itemstack = TSModelLocator.instance.worldModel.getItemstackByTsid(_notes[int(i)].itemstack_tsid);
					if(!itemstack){
						itemstack = new Itemstack(_notes[int(i)].itemstack_tsid);
						itemstack.class_tsid = 'note';
						itemstack.label = _notes[int(i)].title;
						TSModelLocator.instance.worldModel.itemstacks[_notes[int(i)].itemstack_tsid] = itemstack;
					}
				}
				*/
				
				NoticeBoardDialog.instance.update();
			}
			else {
				CONFIG::debugging {
					Console.warn('Status without an itemstack_tsid!');
				}
			}
		}
		
		public function read(note_tsid:String):void {
			if(note_tsid){
				TSFrontController.instance.genericSend(new NetOutgoingNoticeBoardActionVO(itemstack_tsid, note_tsid, 'read'), onRead, onRead);
			}
		}
		
		private function onRead(nrm:NetResponseMessageVO):void {
			if(!nrm.success){
				showError('Could not read that note!');
			}
		}
		
		public function take(note_tsid:String):void {
			if(note_tsid){
				TSFrontController.instance.genericSend(new NetOutgoingNoticeBoardActionVO(itemstack_tsid, note_tsid, 'take'), onTake, onTake);
			}
		}
		
		private function onTake(nrm:NetResponseMessageVO):void {
			if(!nrm.success){
				showError('Could not take that note!');
			}
		}
		
		public function addNote():void {
			//this is a shortcut method that calls the 'add_note' verb on the notice board
			if(itemstack_tsid){
				TSFrontController.instance.sendItemstackVerb(new NetOutgoingItemstackVerbVO(itemstack_tsid, 'add_note', 1), onAdd, onAdd);
			}
		}
		
		private function onAdd(nrm:NetResponseMessageVO):void {
			if(!nrm.success){
				showError('Could not add that note!');
			}
		}
		
		private function showError(txt:String):void {
			TSModelLocator.instance.activityModel.activity_message = Activity.createFromCurrentPlayer(txt);
		}
		
		public function get max_notes():uint { return _max_notes; }
		public function get notes():Vector.<Note> { return _notes; }
	}
}