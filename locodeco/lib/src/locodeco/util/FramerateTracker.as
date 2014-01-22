package locodeco.util 
{

import flash.display.Sprite;
import flash.events.Event;
import flash.text.TextField;
import flash.utils.getTimer;

public class FramerateTracker extends Sprite
{
	
	// vars
	private var time:int;
	private var prevTime:int = 0;
	private var fps:int;
	private var fps_txt:TextField;
	
	// constructor
	public function FramerateTracker()
	{
		
		//
		fps_txt = new TextField();
		addChild(fps_txt);
		
		//
		addEventListener(Event.ENTER_FRAME, getFps);
		
	}
	
	// methods
	private function getFps(e:Event):void
	{
		
		//
		time = getTimer();
		fps = 1000 / (time - prevTime);
		
		//
		fps_txt.text = "fps: " + fps;
		
		//
		prevTime = getTimer();
		
		
		
	}
	
	
	
} // end class

} // end package 