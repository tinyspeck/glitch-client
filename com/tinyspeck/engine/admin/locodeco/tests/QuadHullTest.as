package com.tinyspeck.engine.admin.locodeco.tests 
{
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Rectangle;

import locodeco.util.FramerateTracker;
import locodeco.util.QuadHull;


[SWF(width=500, height=500, backgroundColor="#CCCCCC")]
public class QuadHullTest extends Sprite
{
	private static var rects:Vector.<Rectangle> = new Vector.<Rectangle>();
	
	public function QuadHullTest() {
		addChild(new FramerateTracker());
		
		stage.addEventListener(MouseEvent.CLICK, function ():void {
			rects.push(new Rectangle(mouseX, mouseY, 50, 50));
		});
		
		stage.addEventListener(Event.ENTER_FRAME, function():void {
			graphics.clear();
			drawPoints();
			drawHull(QuadHull.quadHull(rects));
		});
		
		stage.addEventListener(KeyboardEvent.KEY_UP, function ():void {
			graphics.clear();
			rects.length = 0;
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
		for each (var r:Rectangle in rects) {
			graphics.beginFill(0);
			graphics.drawRect(r.x, r.y, r.width, r.height);
			graphics.endFill();
		}
	}
}
}