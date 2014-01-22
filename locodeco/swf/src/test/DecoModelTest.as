package test
{
import locodeco.LocoDecoGlobals;
import locodeco.models.DecoModel;

import org.flexunit.asserts.assertEquals;

public class DecoModelTest
{
	[Before]
	public function setUp():void {
		//
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
	public function testRotation():void {
		const dm:DecoModel = new DecoModel(null);
		dm.originalWidth = 0;
		dm.originalHeight = 0;
		assertEquals(0, dm.r);
		dm.r = 90;
		assertEquals(90, dm.r);
		dm.r = -90;
		assertEquals(-90, dm.r);
		dm.r = 360;
		assertEquals(0, dm.r);
		dm.r = -360;
		assertEquals(0, dm.r);
		dm.r = 361;
		assertEquals(1, dm.r);
		dm.r = -361;
		assertEquals(-1, dm.r);
	}
}
}