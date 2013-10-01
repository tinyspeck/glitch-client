package com.tinyspeck.engine.spritesheet
{
	import flash.display.BitmapData;
	
	public class SheetPacker
	{
		private var onePixelBorder:Boolean;
		private var powerOfTwo:Boolean;
		
		private var textureIndex:int;
		private var textureCount:int;
		private var textures:Vector.<SheetTexture>;
		
		public var width:int = 0;
		public var height:int = 0;
		
		public var firstNode:SheetPackerNode;
		public var useWidth:Boolean = false;
		public var largestWidth:Number = 0;
		public var largestHeight:Number = 0;
		
		public function SheetPacker(onePixelBorder:Boolean, powerOfTwo:Boolean)
		{
			this.onePixelBorder = onePixelBorder;
			this.powerOfTwo = powerOfTwo;
		}
		
		public function addBitmaps(bitmaps:Vector.<BitmapData>):void
		{
			var sheetTexture:SheetTexture;
			var bitmapData:BitmapData;
			textureCount = bitmaps.length;
			textures = new Vector.<SheetTexture>();
			
			for(textureIndex = 0; textureIndex<textureCount; textureIndex++)
			{
				bitmapData = bitmaps[int(textureIndex)];
				sheetTexture = new SheetTexture(bitmapData);
				textures.push(sheetTexture);
				largestWidth = Math.max(sheetTexture.width, largestWidth);
				largestHeight = Math.max(sheetTexture.height, largestHeight);
			}
			
			var widthCount:int = 0;
			var heightCount:int = 0;
			for(var i:int = 0; i<textures.length; i++){
				sheetTexture = textures[int(i)];
				if(sheetTexture.width < largestWidth){
					widthCount++;
				}
				if(sheetTexture.height < largestHeight){
					heightCount++;
				}
			}
			if(heightCount > widthCount){
				useWidth = false;
			}else{
				useWidth = true;
			}
		}
		
		public function packTextures():Vector.<SheetTexture>
		{
			width = 0;
			height = 0;
			
			if(useWidth){
				textures = textures.sort(sortByWidth);
				firstNode = new SheetPackerNode(0,0,largestWidth*2,4095);
			}else{
				textures = textures.sort(sortByHeight);
				firstNode = new SheetPackerNode(0,0,4095,largestHeight*2);
			}
			var texture:SheetTexture;
			for(var i:int =0; i<textures.length; i++){
				texture = textures[int(i)];
				firstNode.insert(texture);
				width = Math.max(texture.x+texture.width, width);
				height = Math.max(texture.y+texture.height, height);
			}
			return textures;
		}
		
		private function sortByWidth(a:SheetTexture, b:SheetTexture):int
		{
			if(a.width > b.width){
				return -1;
			}
			return 1;
		}
		
		private function sortByHeight(a:SheetTexture, b:SheetTexture):int
		{
			if(a.height > b.height){
				return -1;
			}
			return 1;
		}
	}	
}