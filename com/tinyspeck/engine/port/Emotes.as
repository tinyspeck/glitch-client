package com.tinyspeck.engine.port
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.model.TSModelLocator;

	public class Emotes
	{
		/* singleton boilerplate */
		public static const instance:Emotes = new Emotes();
		
		/*****************************************
		 * Anytime you want the avatar to react to
		 * inputed text, use this class.
		 *****************************************/
		
		public static const AFK:String = 'afk';
		public static const EMOTE_TYPE_HI:String = 'hi';
		
		private static const HAPPY_PATTERN:RegExp = /(\s+|^)(:-?\)|:D|lo[lo]*l|joy|ha[ha]*|he[he]+)(\s+|$)/gi;
		private static const ANGRY_PATTERN:RegExp = /(\s+|^)(>:-?\(|gr+r)(\s+|$)/gi;
		private static const SURPRISE_PATTERN:RegExp = /(\s+|^)(:-\/|:O|:0|O_O|wtf|huh)(\s+|$)/gi;
		
		public function Emotes(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function showAfk(txt:String):String {
			var l_txt:String = txt.toLowerCase();
			
			if(l_txt == AFK || l_txt == '/afk') {
				TSFrontController.instance.toggleAFK();
				// if we typed "afk: to come back from AFK, make that clear
				if (!TSModelLocator.instance.worldModel.pc.afk) return 'Back from '+txt;
			}
			
			return txt;
		}
		
		public function showEmote(txt:String):void {
			var l_txt:String = txt.toLowerCase();
			
			//emotes
			if(txt.match(SURPRISE_PATTERN).length) {
				TSFrontController.instance.playSurprisedAnimation();
			} 
			else if(txt.match(ANGRY_PATTERN).length) {
				TSFrontController.instance.playAngryAnimation();
			} 
			else if(txt.match(HAPPY_PATTERN).length) {
				TSFrontController.instance.playHappyAnimation();
			}else if (txt.toLowerCase() == EMOTE_TYPE_HI){
				TSFrontController.instance.doEmote(EMOTE_TYPE_HI)
			}
		}
	}
}