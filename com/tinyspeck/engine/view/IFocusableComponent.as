package com.tinyspeck.engine.view
{
	public interface IFocusableComponent
	{
		function demandsFocus():Boolean;
		function hasFocus():Boolean;
		function focus():void;
		function blur():void;
		function get stops_avatar_on_focus():Boolean;
		function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void;
		function registerSelfAsFocusableComponent():void;
		function removeSelfAsFocusableComponent():void;
	}
}


/*

public function demandsFocus():Boolean {
	return false;
}

public function hasFocus():Boolean {
	return has_focus;
}

public function focus():void {
	Console.log(99, 'focus');
	has_focus = true;
	startListeningForControlEvts();
}

public function blur():void {
	Console.log(99, 'blur');
	has_focus = false;
	stopListeningForControlEvts();
}

public function get stops_avatar_on_focus():Boolean {
	return false;
}

public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
	
}

public function registerSelfAsFocusableComponent():void {
	model.stateModel.registerFocusableComponent(this as IFocusableComponent);
}

public function removeSelfAsFocusableComponent():void {
	model.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
}
*/