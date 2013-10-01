package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.Note;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingNoteCloseVO;
	import com.tinyspeck.engine.net.NetOutgoingNoteSaveVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;

	public class NoteManager
	{
		
		/* singleton boilerplate */
		public static const instance:NoteManager = new NoteManager();
		
		private var _current_note:Note;
		
		public function NoteManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function start(payload:Object):void {
			_current_note = Note.fromAnonymous(payload, payload.itemstack_tsid);
			
			//open the dialog
			NoteDialog.instance.start();
		}
		
		public function save(body_text:String, title_text:String):void {
			if(body_text != null){
				TSFrontController.instance.genericSend(
					new NetOutgoingNoteSaveVO(
						_current_note.itemstack_tsid,
						body_text,
						title_text
					),
					checkSave,
					checkSave
				);
			}
		}
		
		private function checkSave(nrm:NetResponseMessageVO):void {
			if(!nrm.success && nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('Error saving the note!');
				}
				NoteDialog.instance.errorSave();
				return;
			}
			
			//update the note author details
			_current_note.updated = TSFrontController.instance.getCurrentGameTimeInUnixTimestamp();
			
			var pc:PC = TSModelLocator.instance.worldModel.pc;
			if(pc){
				_current_note.owner_label = pc.label;
				_current_note.owner_tsid = pc.tsid;
			}
			
			NoteDialog.instance.confirmSave();
		}
		
		public function close():void {
			//tell the 
			if(current_note && current_note.itemstack_tsid){
				TSFrontController.instance.genericSend(new NetOutgoingNoteCloseVO(current_note.itemstack_tsid), onClose, onClose);
			}
		}
		
		private function onClose(nrm:NetResponseMessageVO):void {
			if(!nrm.success && nrm.payload.error){
				showError(nrm.payload.error.msg);
				CONFIG::debugging {
					Console.warn('Error closing the note!');
				}
			}
		}
		
		private function showError(txt:String):void {
			//TSModelLocator.instance.activityModel.growl_message = txt;
			TSModelLocator.instance.activityModel.activity_message = Activity.createFromCurrentPlayer(txt);
		}
		
		public function get current_note():Note { return _current_note; }
	}
}