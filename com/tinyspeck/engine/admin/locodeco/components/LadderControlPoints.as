package com.tinyspeck.engine.admin.locodeco.components
{
public class LadderControlPoints extends ResizeableControlPoints
{
	public function LadderControlPoints() {
		super();
		removeChild(getChildByName(LEFT_TOP));
		removeChild(getChildByName(RIGHT_TOP));
		removeChild(getChildByName(RIGHT_MIDDLE));
		removeChild(getChildByName(LEFT_MIDDLE));
		removeChild(getChildByName(RIGHT_BOTTOM));
		removeChild(getChildByName(LEFT_BOTTOM));
	}
	
	public function startEndHandleMove():void {
		startResizeFromHandleName(MIDDLE_BOTTOM);
	}
}
}