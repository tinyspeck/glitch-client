package com.tinyspeck.engine.data.prompt {
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	
	public class Prompt extends AbstractTSDataEntity
	{
		public var uid:String;
		public var timeout:int; // ignored if modal
		public var title:String; // only relevant if modal
		public var txt:String;
		public var icon_buttons:Boolean = false; // ignored if modal
		public var timeout_value:String; // ignored if modal
		public var choices:Array;
		public var is_modal:Boolean;
		public var escape_value:*; // only relevant if modal
		public var displayed:Boolean = false; // client value
		public var not_server:Boolean = false; // client value
		public var sound:String; //play a sound when the prompt shows up
		public var max_w:int; //allows the server to set the width of the modal dialog from the default 450
		public var item_class:String = 'pet_rock';
		
		public function Prompt(hashName:String)
		{
			super(hashName);
		}
		
		public static function fromAnonymous(object:Object):Prompt
		{
			var prompt:Prompt = new Prompt(object.uid);
			//prompt.uid = object.uid;
			
			for(var j:String in object){
				var val:* = object[j];
				if(j in prompt){
					if(j == 'choices'){
						//sometimes this isn't an array, so let's fix that
						if(val is Array == false){
							prompt.choices = new Array();
							for(var k:String in val){
								//shove the choices in the array
								prompt.choices.push(val[k]);
							}
						}else{
							prompt[j] = val;
						}
					}else{
						prompt[j] = val;
					}
				}else{
					resolveError(prompt,object,j);
				}
			}
			return prompt;
		}
	}
}

/*{
	type: 'prompt',
	uid: 'PR90h3k4',
	timeout: 10,
	txt: 'Gene knocked on your door, can he enter your house?',
	icon_buttons: true,
	timeout_value: 'No',
	choices: [{
		value: 'yes',
		label: 'Yes',
	}, {
		value: 'no',
		label: 'No'
	}]
}
*/