package
{
	import asunit.core.TextCore;
	import asunit.printers.FlashBuilderPrinter;
	
	import com.tinyspeck.engine.EngineAllTests;
	
	import flash.display.Sprite;

	[SWF(width='1000', height='800', backgroundColor='#333333', frameRate='30')]
	public class EngineAllTestsRunner extends Sprite {
		private var core:TextCore;

		public function EngineAllTestsRunner() {
			core = new TextCore();
			core.textPrinter.hideLocalPaths = true;
			// Uncomment to send test results to the FlexUnit Results panel in Flash Builder.
			// Disabled by default because an exception is thrown if the panel isn't open.
			//core.addListener(new FlashBuilderPrinter());
			core.start(EngineAllTests, null, this);
		}
	}
}

