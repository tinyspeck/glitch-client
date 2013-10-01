package
{
	import asunit.core.FlexUnitCICore;
	import asunit.core.TextCore;
	
	import com.tinyspeck.engine.EngineAllTests;
	
	import flash.display.Sprite;
	import flash.events.Event;

	[SWF(width='1000', height='800', backgroundColor='#333333', frameRate='30')]
	public class EngineAllTestsCIRunner extends Sprite {
		private var core:TextCore;

		public function EngineAllTestsCIRunner() {
			core = new FlexUnitCICore();
			core.start(EngineAllTests, null, this);
		}
	}
}

