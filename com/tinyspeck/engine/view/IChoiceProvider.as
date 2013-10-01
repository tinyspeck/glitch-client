package com.tinyspeck.engine.view { 
	
	public interface IChoiceProvider {
		
		function getChoices(which:String = null, base_choice:Object = null, extra_controls:* = null, extra_choicesH:Object = null):Object;
		function choiceStarting():void;
		function choiceEnding():void;
		
	} 
	
}