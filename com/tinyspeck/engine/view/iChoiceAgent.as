
package com.tinyspeck.engine.view { 
	
	public interface iChoiceAgent {
		
		function validateChoice(choice_data:Object):Boolean;
		function handleChoice(choice_data:Object):void;
		
	} 
	
}