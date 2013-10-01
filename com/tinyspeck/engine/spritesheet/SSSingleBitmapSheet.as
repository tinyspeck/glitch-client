package com.tinyspeck.engine.spritesheet
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	public class SSSingleBitmapSheet extends SSAbstractSheet
	{
		private const containerSprite:Sprite = new Sprite();
		
		private var bitmap:BitmapData;
		private var tempBitmaps:Vector.<BitmapData>;
		private var frameBitmapLinks:Dictionary;
		
		public function SSSingleBitmapSheet(name:String, options:SSGenOptions, lazySnapFunction:Function, do_not_clean:Boolean) {
			super(name, options, lazySnapFunction, do_not_clean);
		}
		
		override public function startRecord():void {
			super.startRecord();
			tempBitmaps = new Vector.<BitmapData>();
			frameBitmapLinks = new Dictionary(true);
		}
		
		override public function stopRecord():void {
			super.stopRecord();
			convertToSingle();
			while(tempBitmaps.length){
				BitmapData(tempBitmaps.pop()).dispose();
			}
			frameBitmapLinks = null;
		}
		
		private function convertToSingle():void {
			var sheetPacker:SheetPacker = new SheetPacker(false,false);
			sheetPacker.addBitmaps(tempBitmaps);
			var textures:Vector.<SheetTexture> = sheetPacker.packTextures();
			var ssFrame:SSFrame;
			bitmap = new BitmapData(sheetPacker.width, sheetPacker.height,true,0);
			for(var i:int = 0; i<textures.length; i++){
				var texture:SheetTexture = textures[int(i)];
				mat.translate(texture.x,texture.y);
				ssFrame = frameBitmapLinks[texture.bitmapData];
				ssFrame.sourceRectangle = new Rectangle(texture.x,texture.y,texture.width,texture.height);
				delete frameBitmapLinks[texture.bitmapData];
				bitmap.copyPixels(texture.bitmapData,texture.bitmapData.rect,new Point(texture.x,texture.y));
			}
		}
		
		override internal function snapFrame(displayObject:DisplayObject, frame:SSFrame, options:SSGenOptions):void {
			if (!options) options = ss_options;
			var oldParent:DisplayObjectContainer;
			var oldIndex:int;
			
			var oldFilters:Array = displayObject.filters;
			if(options.filters && options.filters.length){
				displayObject.filters = options.filters;
			}
		
			if(displayObject.parent && !(displayObject.parent is Loader)){
				oldParent = displayObject.parent;
				oldIndex = oldParent.getChildIndex(displayObject);
				oldParent.removeChild(displayObject);
			}else if(displayObject.parent is Loader){
				containerSprite.addChild(displayObject.parent);
			}
			
			containerSprite.addChild(displayObject);
			
			var oldScaleX:Number = displayObject.scaleX;
			var oldScaleY:Number = displayObject.scaleY;
			var oldRotation:Number = displayObject.rotation;
			displayObject.scaleX = options.scale;
			displayObject.scaleY = options.scale;
			displayObject.rotation = options.rotation;
			
			var rect:Rectangle = createBoundingRect(containerSprite);
			var bmp:BitmapData = new BitmapData(rect.width+1,rect.height+1,true,0);
			mat.identity();
			mat.translate(-rect.x,-rect.y);
			bmp.lock();
			bmp.draw(containerSprite,mat,null,null,null,true);
			bmp.unlock();
			frameBitmapLinks[bmp] = frame;
			frame.originalBounds = rect;
			frame._bmd_index = tempBitmaps.push(bmp)-1;
			displayObject.filters = oldFilters;
			
			containerSprite.removeChild(displayObject);
			
			displayObject.rotation = oldRotation;
			displayObject.scaleX = oldScaleX;
			displayObject.scaleY = oldScaleY;
			
			if(oldParent){
				oldParent.addChildAt(displayObject, oldIndex);
			}
			
			super.snapFrame(displayObject, frame, options);
		}
				
		override internal function updateViewBitmapData(viewBitmap:SSViewBitmap):void {
			throw new Error("Single bitmap sheets can't use viewBitmaps");
		}
		
		override internal function updateViewSprite(sprite:SSViewSprite):void {
			var ssFrame:SSFrame = sprite._curr_frame;
			mat.identity();
			mat.translate(-ssFrame.sourceRectangle.x,-ssFrame.sourceRectangle.y);
			sprite.displayShape.graphics.clear();
			sprite.displayShape.graphics.beginBitmapFill(bitmap,mat,false,sprite.smooth);
			sprite.displayShape.graphics.drawRect(0,0,ssFrame.sourceRectangle.width,ssFrame.sourceRectangle.height);
			sprite.displayShape.graphics.endFill();
			sprite.displayShape.x = ssFrame.originalBounds.x;
			sprite.displayShape.y = ssFrame.originalBounds.y;
		}
		
		override internal function dispose():void {
			super.dispose();
		}
	}
}