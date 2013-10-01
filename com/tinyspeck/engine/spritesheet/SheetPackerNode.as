package com.tinyspeck.engine.spritesheet
{
	import flash.geom.Rectangle;

	public class SheetPackerNode
	{
		public static var count:int = 0;
				
		public static const LEAF:int = 0;
		public static const BRANCH:int = 1;
				
		public var ind:int;
		public var texture:SheetTexture;
		
		public var type:int = 0;
		public var childA:SheetPackerNode;
		public var childB:SheetPackerNode;
		
		public var perfect:Boolean;
		public var score:int = 0;
		public var rect:Rectangle;
				
		public function SheetPackerNode(x:int, y:int, width:int, height:int)
		{
			ind = count++;
			this.rect = new Rectangle(x,y,width,height);
		}
		
		public function insert(decoTexture:SheetTexture):Boolean
		{
			if(type != LEAF){
				var success:Boolean = childA.insert(decoTexture);
				if(!success){
					success = childB.insert(decoTexture);
				}
				return success;
			}else{
				if(this.texture != null){
					return false;
				}
				if(!fits(decoTexture)){
					return false;
				}
				if(rect.width == decoTexture.width && rect.height == decoTexture.height){
					this.texture = decoTexture;
					decoTexture.x = rect.x;
					decoTexture.y = rect.y;
					type = LEAF;
					return true;
				}
				
				type = BRANCH;
								
				var dw:int = rect.width - decoTexture.width;
				var dh:int = rect.height - decoTexture.height;
				if(dw > dh){
					//Look over the 1st child.
					childA = new SheetPackerNode(0,0,0,0);
					childB = new SheetPackerNode(0,0,0,0);
					childA.rect.left = rect.left;
					childA.rect.top = rect.top;
					childA.rect.right = rect.left+decoTexture.width;
					childA.rect.bottom = rect.bottom;
					childB.rect.left = rect.left+decoTexture.width;
					childB.rect.top = rect.top;
					childB.rect.right = rect.right;
					childB.rect.bottom = rect.bottom;
				}else{
					childA = new SheetPackerNode(0,0,0,0);
					childB = new SheetPackerNode(0,0,0,0);
					childA.rect.left = rect.left;
					childA.rect.top = rect.top;
					childA.rect.right = rect.right;
					childA.rect.bottom = rect.top+decoTexture.height;
					childB.rect.left = rect.left;
					childB.rect.top = rect.top+decoTexture.height;
					childB.rect.right = rect.right;
					childB.rect.bottom = rect.bottom;
				}
				return childA.insert(decoTexture);
				 
			}
			return false;
		}
				
		public function fits(texture:SheetTexture):Boolean
		{
			if(texture.width<=rect.width && texture.height<=rect.height){
				return true;
			}
			return false;
		}
	}
}