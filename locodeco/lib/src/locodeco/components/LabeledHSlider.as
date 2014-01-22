package locodeco.components
{
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;

import mx.controls.Button;
import mx.events.FlexEvent;

import spark.components.HSlider;
import spark.components.Label;

public final class LabeledHSlider extends HSlider
{
	[SkinPart(required="true")]
	public var valueLabelPart:EditableLabel;
	
	[SkinPart(required="true")]
	public var labelPart:Label;
	
	[SkinPart(required="true")]
	public var resetPart:Button;
	
	[Bindable]
	public var resetValue:Number = 0;
	
	private var _label:String = "";
	private var _suffix:String = "";
	
	public function LabeledHSlider() {
		useHandCursor = true;
		buttonMode = true;
		
		addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler, false, 0, true);
		addEventListener(MouseEvent.ROLL_OVER, rollOverHandler, false, 0, true);
		addEventListener(MouseEvent.ROLL_OUT, rollOutHandler, false, 0, true);
	}
	
	public function get suffix():* {
		return _suffix;
	}
	
	public function set suffix(u:*):void {
		_suffix = u;
		if (valueLabelPart)
			valueLabelPart.suffix = u;
	}
	
	public function get label():String {
		return _label;
	}

	public function set label(value:String):void {
		_label = value;
		if (labelPart) labelPart.text = value;
	}
	
	override protected function partAdded(partName:String, instance:Object):void {
		super.partAdded(partName, instance);
		
		if (instance == valueLabelPart) {
			valueLabelPart.addEventListener(FlexEvent.ENTER, labelEnterHandler);
			valueLabelPart.addEventListener(MouseEvent.DOUBLE_CLICK, doubleClickHandler);
			valueLabelPart.suffix = _suffix;
		} else if (instance == resetPart) {
			resetPart.addEventListener(MouseEvent.CLICK, reset);
		} else if (instance == labelPart) {
			// set initial label
			labelPart.text = label;
		}
	}
	
	override protected function partRemoved(partName:String, instance:Object):void {
		super.partRemoved(partName, instance);
		
		if (instance == valueLabelPart) {
			valueLabelPart.removeEventListener(FlexEvent.ENTER, labelEnterHandler);
			valueLabelPart.removeEventListener(MouseEvent.DOUBLE_CLICK, doubleClickHandler);
		} else if (instance == resetPart) {
			resetPart.removeEventListener(MouseEvent.CLICK, reset);
		}
	}
	
	override protected function setValue(value:Number):void {
		value = nearestValidValue(value, snapInterval);
		super.setValue(value);
		valueLabelPart.value = value;
		resetPart.visible = resetPart.includeInLayout = (value != resetValue);
	}
	
	override protected function system_mouseWheelHandler(event:MouseEvent):void {
		// prevent mouse wheel from affect the control if cursor isn't over it
	}
	
	override protected function keyDownHandler(event:KeyboardEvent):void {
		// prevent keyboard from adjusting the slider
	}
	
	private function mouseWheelHandler(event:MouseEvent):void {
		value += event.delta * stepSize;
	}
	
	private function doubleClickHandler(e:MouseEvent):void {
		stage.addEventListener(MouseEvent.CLICK, stageClickHandler);
	}
	
	private function stageClickHandler(e:MouseEvent):void {
		labelEnterHandler(e);
		// clear focus so EditableLabel ends editing
		stage.focus = null;
	}
	
	private function rollOverHandler(e:Event):void {
		focusManager.showFocusIndicator = true;
		setFocus();
	}
	
	private function rollOutHandler(e:Event):void {
		focusManager.showFocusIndicator = false;
		stage.focus = null;
	}
	
	private function labelEnterHandler(e:Event):void {
		setValue(int(valueLabelPart.text));
		stage.removeEventListener(MouseEvent.CLICK, stageClickHandler);
	}
	
	private function reset(e:Event):void {
		value = resetValue;
	}
}
}