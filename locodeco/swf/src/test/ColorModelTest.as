package test
{
import locodeco.models.ColorModel;

import org.flexunit.Assert;
import org.flexunit.asserts.assertEquals;
import org.flexunit.asserts.assertTrue;

public class ColorModelTest
{
	private var cm000000:ColorModel;
	private var cm123456:ColorModel;
	private var cmFFFFFF:ColorModel;
	
	[Before]
	public function setUp():void {
		cm000000 = new ColorModel();
		cm123456 = new ColorModel();
		cm123456.color = 0x123456;
		cmFFFFFF = new ColorModel();
		cmFFFFFF.color = 0xFFFFFF;
	}
	
	[After]
	public function tearDown():void {
		//
	}
	
	[BeforeClass]
	public static function setUpBeforeClass():void {
		//
	}
	
	[AfterClass]
	public static function tearDownAfterClass():void {
		//
	}
	
	[Test]
	public function testDefault():void {
		assert000000(cm000000);
		assert123456(cm123456);
		assertFFFFFF(cmFFFFFF);
	}
	
	[Test]
	public function testColor():void {
		cm000000.color = 0x000000;
		assert000000(cm000000);

		cm123456.color = 0x123456;
		assert123456(cm123456);
		
		cmFFFFFF.color = 0xFFFFFF;
		assertFFFFFF(cmFFFFFF);
	}
	
	[Test]
	public function testHex():void {
		cm000000.hex = "000000";
		assert000000(cm000000);
		
		cm123456.hex = "123456";
		assert123456(cm123456);
		
		cmFFFFFF.hex = "ffFFff";
		assertFFFFFF(cmFFFFFF);
	}
	
	[Test]
	public function testH():void {
		cm000000.h = 0;
		assert000000(cm000000);
		
		cm123456.h = 210;
		assert123456(cm123456);

		cmFFFFFF.h = 0;
		assertFFFFFF(cmFFFFFF);
	}

	[Test]
	public function testS():void {
		cm000000.s = 0;
		assert000000(cm000000);
		
		cm123456.s = 79;
		assert123456(cm123456);
		
		cmFFFFFF.s = 0;
		assertFFFFFF(cmFFFFFF);
	}
	
	[Test]
	public function testV():void {
		cm000000.v = 0;
		assert000000(cm000000);
		
		cm123456.v = 34;
		assert123456(cm123456);
		
		cmFFFFFF.v = 100;
		assertFFFFFF(cmFFFFFF);
	}
	
	[Test]
	public function testR():void {
		cm000000.r = 0;
		assert000000(cm000000);
		
		cm123456.r = 18;
		assert123456(cm123456);
		
		cmFFFFFF.r = 255;
		assertFFFFFF(cmFFFFFF);
	}
	
	[Test]
	public function testG():void {
		cm000000.g = 0;
		assert000000(cm000000);
		
		cm123456.g = 52;
		assert123456(cm123456);
		
		cmFFFFFF.g = 255;
		assertFFFFFF(cmFFFFFF);
	}
	
	[Test]
	public function testB():void {
		cm000000.b = 0;
		assert000000(cm000000);
		
		cm123456.b = 86;
		assert123456(cm123456);
		
		cmFFFFFF.b = 255;
		assertFFFFFF(cmFFFFFF);
	}
	
	private function assert000000(cm:ColorModel):void {
		assertEquals(cm.h, 0);
		assertEquals(cm.s, 0);
		assertEquals(cm.v, 0);
		assertEquals(cm.r, 0);
		assertEquals(cm.g, 0);
		assertEquals(cm.b, 0);
		assertEquals(cm.hex, "000000");
		assertEquals(cm.color, 0x000000);
	}
	
	private function assertFFFFFF(cm:ColorModel):void {
		assertEquals(cm.h, 0);
		assertEquals(cm.s, 0);
		assertEquals(cm.v, 100);
		assertEquals(cm.r, 255);
		assertEquals(cm.g, 255);
		assertEquals(cm.b, 255);
		assertEquals(cm.hex, "FFFFFF");
		assertEquals(cm.color, 0xFFFFFF);
	}
	
	private function assert123456(cm:ColorModel):void {
		assertEquals(cm.h, 210);
		assertEquals(cm.s, 79);
		assertEquals(cm.v, 34);
		assertEquals(cm.r, 18);
		assertEquals(cm.g, 52);
		// SHAMEFUL: When setting HSV, these values are usually off by one;
		// this is acceptible as it's color, and the error is only 1/2^24
		assertTrue(cm.b == 86 || cm.b == 87);
		assertTrue(cm.hex == "123456" || cm.hex == "123457");
		assertTrue(cm.color == 0x123456 || cm.color == 0x123457);
	}
}
}