package com.tinyspeck.engine.admin.locodeco.tests 
{
import com.tinyspeck.engine.admin.locodeco.components.AbstractControlPoints;
import com.tinyspeck.engine.admin.locodeco.components.MultiControlPoints;
import com.tinyspeck.engine.admin.locodeco.components.ResizeableControlPoints;

import flash.display.GradientType;
import flash.display.Sprite;
import flash.geom.Matrix;

[SWF(width="500", height="500", backgroundColor="#888888")]
public class MultipleControlPointsTest extends Sprite
{
	private var transformer:MultiControlPoints;
	
	public function MultipleControlPointsTest()
	{
		const objCenter:Sprite = new Sprite();
		objCenter.graphics.beginFill(0xFFFF00);
		objCenter.graphics.drawCircle(0, 0, 5);
		
		const obj:Sprite = new Sprite();
		addChild(obj);
		obj.graphics.beginFill(0xFFFFFF);
		obj.alpha = 0.75;
		obj.graphics.drawCircle(0, 0, 100);
		obj.addChild(objCenter);
		obj.x = 150;
		obj.y = 150;
		
		const objCenter2:Sprite = new Sprite();
		objCenter2.graphics.beginFill(0xFFFF00);
		objCenter2.graphics.drawCircle(0, 0, 5);
		
		const obj2:Sprite = new Sprite();
		addChild(obj2);
		obj2.graphics.beginFill(0xFFFFFF);
		obj2.alpha = 0.75;
		obj2.graphics.drawRect(0, 0, 100, 100);
		obj2.addChild(objCenter2);
		obj2.x = 300;
		obj2.y = 200;
		
		const M:Matrix = new Matrix();
		M.createGradientBox(500, 500, Math.PI/2);
		graphics.beginGradientFill(GradientType.LINEAR, [0xFFFF, 0], [1,1], [0,180], M);
		graphics.drawRect(0, 0, 500, 500);

		transformer = new MultiControlPoints();
		transformer.stage = stage;
		
		const objCP:AbstractControlPoints = new ResizeableControlPoints();
		objCP.stage = stage;
		objCP.target = new SpriteToControlPointTargetProxy(obj);
		transformer.registerControlPoint(obj, objCP);
		
		const objCP2:AbstractControlPoints = new ResizeableControlPoints();
		objCP2.stage = stage;
		objCP2.target = new SpriteToControlPointTargetProxy(obj2);
		transformer.registerControlPoint(obj2, objCP2);
		
		addChild(transformer);
	}
}
}