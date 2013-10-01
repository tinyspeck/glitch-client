package com.tinyspeck.engine.admin.locodeco.tests 
{
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.geom.Point;

import locodeco.util.GrahamScan2;
import locodeco.util.FramerateTracker;


[SWF(width=500, height=500, backgroundColor="#CCCCCC")]
public class ConvexHullTest extends Sprite
{
	private static var points:Vector.<Point> = new Vector.<Point>();

	
	public function ConvexHullTest() {
		addChild(new FramerateTracker());
		
		stage.addEventListener(MouseEvent.CLICK, function ():void {
			points.push(new Point(mouseX, mouseY));
		});
		
		stage.addEventListener(Event.ENTER_FRAME, function():void {
			graphics.clear();
			drawPoints();
			drawHull(GrahamScan2.convexHull(points));
		});
		
		stage.addEventListener(KeyboardEvent.KEY_UP, function ():void {
			graphics.clear();
			points.length = 0;
		});
	}
	
	private function drawHull(hull:Vector.<Point>):void {
		if (hull.length < 2) return;
		
		graphics.lineStyle(0);
		graphics.moveTo(hull[0].x, hull[0].y);
		for (var i:int = 1; i < hull.length; i++) {
			graphics.lineTo(hull[int(i)].x, hull[int(i)].y);
		}
		graphics.lineTo(hull[0].x, hull[0].y);
	}
	
	private function drawPoints():void {
		for each (var p:Point in points) {
			graphics.beginFill(0);
			graphics.drawCircle(p.x, p.y, 2);
			graphics.endFill();
		}
	}
}
}