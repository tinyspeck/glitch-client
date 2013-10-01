package com.tinyspeck.engine.animatedbitmap {
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	/**
	 * Generates a BitmapAtlas from a MovieClip container.
	 * Handles animations where children are added later on in the timeline (waits for FRAME_CONSTRUCTED).
	 * Optional parameters can be specified with a callback
	 */ 
	public class BitmapAtlasGenerator {
		
		public static const MAX_TEXTURE_WIDTH:uint = 2048;
		public static const MAX_TEXTURE_HEIGHT:uint = 8191;
		
		private static var _instance:BitmapAtlasGenerator;
		
		private const frames:Vector.<AnimatedBitmapFrame> = new Vector.<AnimatedBitmapFrame>();
		private const callbacksByContainer:Dictionary = new Dictionary();
		private const callQueue:Vector.<Object> = new Vector.<Object>();
		
		private var currentContainerMC:DisplayObjectContainer;
		private var currentCallParams:Object;
		
		private var scaleFactorX:Number = 1;
		private var scaleFactorY:Number = 1;
		private var margin:Number = 0;
		private var startingLabel:String;
		private var preserveColor:Boolean;
		
		private var	frameLabelIndex:uint = 1;
		
		private var maxFrameWidth:Number = 0;
		private var maxFrameHeight:Number = 0;
		
		private var containerNumChildren:uint = 0;
		private var containerChildrenDrawn:uint = 0;
		
		// used for frame positioning
		private var curTextureX:Number = 0;
		private var curTextureY:Number = 0;
		private var textureWidth:Number = 0;
		private var curRowHeight:Number = 0;
		
		public function BitmapAtlasGenerator() {
			// Usual way of enforcing singletone will cause error, as TextureAtlas inherits from this class.
			//if (_instance) {
			//	throw new Error("AltasGenerator is a Singleton.  Use .instance instead.");
			//}
			
			if (!_instance) _instance = this;
		}
		
		public function isGeneratingAtlasForContainer(container:DisplayObjectContainer):Boolean {
			return (callbacksByContainer[container] != null);
		}
		
		/** Adds a callback for specified container. */
		public function addCallbackForContainer(container:DisplayObjectContainer, completionCallback:Function, callbackParams:Array = null, errorHandler:Function = null):void {
			if (!callbacksByContainer[container]) {
				throw new Error("Not generating an atlas for specified container.");
			}
			var callbackPair:Object = {callback:completionCallback, params:callbackParams, errorHandler:errorHandler};
			var callbacks:Vector.<Object> = callbacksByContainer[container];
			callbacks.push(callbackPair);
			
		}
		
		/** Generates a BitmapAtlas for the specified MovieClip container.  completionCallback will be called with callbackParams once the atlas is generated. */
		public function fromMovieClipContainer(containerMC:DisplayObjectContainer, completionCallback:Function, callbackParams:Array = null, scaleFactor:Number = 1, 
											   margin:uint=0, startingLabel:String = null, frameIndices:Vector.<int> = null, preserveColor:Boolean = true, errorHandler:Function = null):void {
			
			var callbackPair:Object = {callback:completionCallback, params:callbackParams, errorHandler:errorHandler};
			
			var callbacks:Vector.<Object> = callbacksByContainer[containerMC];
			// if there is no callback, queue up the call and add entry for callback.
			if (callbacks == null) {
				callbacks = new Vector.<Object>();
				callbacksByContainer[containerMC] = callbacks;
				
				var nextCallParams:Object = {containerMC:containerMC, scaleFactor:scaleFactor,
					margin:margin, startingLabel:startingLabel, frameIndices:frameIndices, preserveColor:preserveColor}
				callQueue.push(nextCallParams);
			} 
			callbacks.push(callbackPair);
			
			if (!currentContainerMC) generateNextAtlas();
		}
		
		/** Generate the next atlas in queue */
		private function generateNextAtlas():void {
			currentCallParams = callQueue.shift();
			
			currentContainerMC = currentCallParams.containerMC;
			scaleFactorX = scaleFactorY = currentCallParams.scaleFactor;
			margin = currentCallParams.margin;
			startingLabel = currentCallParams.startingLabel;
			preserveColor = currentCallParams.preserveColor;
			
			if (currentContainerMC is MovieClip) {
				var contMC:MovieClip = MovieClip(currentContainerMC);
				contMC.gotoAndStop(1);
			} 
			
			applyScale(currentContainerMC, scaleFactorX);
			containerNumChildren = currentContainerMC.numChildren;
			
			drawNextContainerChild();
		}
		
		private function drawNextContainerChild():void {
			var containerChild:DisplayObject = currentContainerMC.getChildAt(containerChildrenDrawn);
			var containerChildColorTransform:ColorTransform = containerChild.transform.colorTransform;
			
			if (containerChild is MovieClip) {
				var containerChildMC:MovieClip = MovieClip(containerChild);
				
				if (currentCallParams.frameIndices && currentCallParams.frameIndices.length > containerChildMC.totalFrames) {
					throw new Error("The number of frameIndices must be the same or less than the number of MovieClip frames : " + containerChildMC.totalFrames + " in MC versus " + 
						currentCallParams.frameIndices.length + " in frameIndices.");
				}
				
				if (startingLabel) {
					containerChildMC.gotoAndStop(startingLabel);
					frameLabelIndex = containerChildMC.currentFrame;
				} else {
					containerChildMC.gotoAndStop(1);
				}
				drawFrame(containerChildMC);
			} else {
				buildFrame(containerChild, containerChild.name + "_" + appendIntToString(0, 5), containerChild.name, containerChild.transform.colorTransform);
				onFramesDrawn();
			}			
		}
		
		/** Apply scale to the specified clip and its filters */
		private function applyScale(clip:DisplayObjectContainer, scaleFactor:Number):void {			
			
			for (var i:uint = 0; i < clip.numChildren; i++) {
				var child:DisplayObject = clip.getChildAt(i);
				
				if (scaleFactor != 1) {
					child.scaleX *= scaleFactor;
					child.scaleY *= scaleFactor;
					
					if (child.filters.length > 0) {
						var filters:Array = child.filters;
						var filtersLen:int = child.filters.length;
						var filter:Object;
						
						for (var j:uint = 0; j < filtersLen; j++) {
							filter = filters[j];
							
							if (filter.hasOwnProperty("blurX")) {
								filter.blurX *= scaleFactor;
								filter.blurY *= scaleFactor;
							}
							if (filter.hasOwnProperty("distance")) {
								filter.distance *= scaleFactor;
							}
						}
						child.filters = filters;
					}
				}
			}
		}
		
		private function drawFrame(containerChildMC:MovieClip):void {
			// if we are copying frames from a label, and we have reached the next label, then container child is complete;
			if (startingLabel && containerChildMC.currentFrameLabel != null  && containerChildMC.currentFrameLabel != startingLabel) {
				onFramesDrawn();
				return;
			}
			
			// if children have not been added to the timeline yet, wait for FRAME_CONSTRUCTED event.
			if (containerChildMC.numChildren && containerChildMC.getChildAt(0) == null) {
				containerChildMC.addEventListener(Event.FRAME_CONSTRUCTED, onFrameConstructed, false, 0, true);
				return;
			}
			
			var currentFrame:int = containerChildMC.currentFrame - 1;
			if (startingLabel) {
				currentFrame = currentFrame - (frameLabelIndex - 1);
			}
			var parentFrameIndex:int = getParentIndex(containerChildMC, currentFrame);
			var frame:AnimatedBitmapFrame = buildFrame(containerChildMC, containerChildMC.name + "_" + appendIntToString(containerChildMC.currentFrame - 1, 5), 
				containerChildMC.name, containerChildMC.transform.colorTransform, parentFrameIndex);
			positionFrameOnSheet(frame);
			frames.push(frame);
			
			// if we have reached the final frame, the container child is complete.
			if (containerChildMC.currentFrame == containerChildMC.totalFrames) {
				onFramesDrawn();
				return;
			}
			
			// move to the next frame and draw it.
			containerChildMC.gotoAndStop(containerChildMC.currentFrame + 1);
			drawFrame(containerChildMC);
		}
		
		private function getParentIndex(containerChildMC:MovieClip, frameIndex:uint):int {
			if (!currentCallParams.frameIndices) return -1;
			return currentCallParams.frameIndices[frameIndex];
		}
		
		private function onFrameConstructed(e:Event):void {
			var targetClip:MovieClip = MovieClip(e.target);
			targetClip.removeEventListener(Event.FRAME_CONSTRUCTED, onFrameConstructed);
			drawFrame(targetClip);
		}
		
		private function onFramesDrawn():void {
			containerChildrenDrawn++;
			// if there are more children for the container, keep drawing.
			if (containerChildrenDrawn != containerNumChildren) {
				drawNextContainerChild();
				return;
			}
			
			// build the sheet and call callbacks.
			var sheetBMD:BitmapData = drawAllFramesToSheetBMD();
			if (!sheetBMD) {
				spriteSheetingError();
				return;
			}
			
			var bitmapAtlas:BitmapAtlas = new BitmapAtlas(sheetBMD, frames.concat(), maxFrameWidth, maxFrameHeight, scaleFactorX, scaleFactorY);
			var callbacks:Vector.<Object> = callbacksByContainer[currentContainerMC];
			for each(var callbackPair:Object in callbacks) {
				var callback:Function = callbackPair.callback;
				var callbackParams:Array = callbackPair.params;
				callCallback(callback, callbackParams, bitmapAtlas);
			}
			
			callbacks.length = 0;
			callbacksByContainer[currentContainerMC] = null;
			delete callbacksByContainer[currentContainerMC];
			
			resetDrawing();
			
			if (callQueue.length) {
				generateNextAtlas();
			} else {
				currentContainerMC = null;
			}
		}
		
		private function spriteSheetingError():void {
			resetDrawing();
			
			var callbacks:Vector.<Object> = callbacksByContainer[currentContainerMC];
			for each(var callbackPair:Object in callbacks) {
				var errorHandler:Function = callbackPair.errorHandler;
				if (errorHandler != null) errorHandler();
			}
			
			currentContainerMC = null;
		}
		
		protected function callCallback(callback:Function, callbackParams:Array, bitmapAtlas:BitmapAtlas):void {
			var paramsConcat:Array = [bitmapAtlas];
			if (callbackParams) paramsConcat = paramsConcat.concat(callbackParams);
			callback.apply(null, paramsConcat);
		}
		
		private function resetDrawing():void {
			// undo scale
			applyScale(currentContainerMC, 1/scaleFactorX);
			
			frameLabelIndex = 1;
			frames.length = 0;
			containerChildrenDrawn = 0;
			curTextureX = 0;
			curTextureY = 0;
			textureWidth = 0;
			curRowHeight = 0;
			maxFrameHeight = 0;
			maxFrameWidth = 0;
		}
		
		private function drawAllFramesToSheetBMD():BitmapData {
			var textureHeight:uint = curTextureY + curRowHeight;
			
			if (textureHeight > MAX_TEXTURE_HEIGHT) {
				return null;
			}
			
			var subTexturePoint:Point = new Point();
			var textureBMD:BitmapData = new BitmapData(textureWidth, textureHeight, true, 0);
			var frame:AnimatedBitmapFrame;
			for (var i:uint = 0; i < frames.length; i++) {
				
				// only draw unique frames to the sheet
				frame = frames[i];
				if (frame.parentIndex != -1) continue;
				
				var subTextureBMD:BitmapData = frame.bitmapData;
				subTexturePoint.x = frame.sheetCoordX;
				subTexturePoint.y = frame.sheetCoordY;
				textureBMD.copyPixels(subTextureBMD, subTextureBMD.rect, subTexturePoint);
				
				frame.bitmapData.dispose();
				frame.bitmapData = null;
			}
			
			/* TODO: figure out a way to rescale the sprite sheet if it is too large
			// if texture height exceeds max dimensions, create a shorter bitmap.
			if (textureHeight > MAX_TEXTURE_HEIGHT) {
				var scale:Number = MAX_TEXTURE_HEIGHT / (textureHeight + 1);
				var sourceBitmap:Bitmap = new Bitmap(textureBMD);
				var scaledBitmapData:BitmapData = new BitmapData(textureWidth, textureHeight * scale, true, 0);
				var scaleMat:Matrix = new Matrix();
				scaleMat.scale(1, scale);
				scaledBitmapData.draw(sourceBitmap, scaleMat);
				textureBMD.dispose();
				
				for (var j:uint = 0; j < frames.length; j++) {
					frame = frames[j];
					frame.displayListY *= scale;
					frame.height *= scale;
					frame.sheetCoordY *= scale;
				}
				maxFrameHeight *= scale;
				scaleFactorY = scale;
				return scaledBitmapData;
			}
			*/
			
			return textureBMD;
		}
		
		private function buildFrame(containerChild:DisplayObject, textureName:String, baseName:String, clipColorTransform:ColorTransform, parentFrameIndex:int = -1):AnimatedBitmapFrame {
			
			var bounds:Rectangle = containerChild.getBounds(containerChild.parent);
			bounds.x = Math.floor(bounds.x);
			bounds.y = Math.floor(bounds.y);
			bounds.height = Math.ceil(bounds.height);
			bounds.width = Math.ceil(bounds.width);
			bounds.width = bounds.width > 0 ? bounds.width + margin * 2 : 1;
			bounds.height = bounds.height > 0 ? bounds.height + margin * 2 : 1;
			
			var realBounds:Rectangle = new Rectangle(0, 0, bounds.width, bounds.height);
			if (realBounds.width > maxFrameWidth) maxFrameWidth = realBounds.width;
			if (realBounds.height > maxFrameHeight) maxFrameHeight = realBounds.height;
			
			// Checking filters in case we need to expand the outer bounds
			if (containerChild.filters.length > 0)
			{
				var j:int = 0;
				var clipFilters:Array = containerChild.filters;
				var clipFiltersLength:int = clipFilters.length;
				var tmpBData:BitmapData;
				var filterRect:Rectangle;
				
				tmpBData = new BitmapData(realBounds.width, realBounds.height, false);
				filterRect = tmpBData.generateFilterRect(tmpBData.rect, clipFilters[j]);
				tmpBData.dispose();
				
				while (++j < clipFiltersLength)
				{
					tmpBData = new BitmapData(filterRect.width, filterRect.height, true, 0);
					filterRect = tmpBData.generateFilterRect(tmpBData.rect, clipFilters[j]);
					realBounds = realBounds.union(filterRect);
					tmpBData.dispose();
				}
			}
			
			realBounds.offset(bounds.x, bounds.y);
			realBounds.width = Math.max(realBounds.width, 1);
			realBounds.height = Math.max(realBounds.height, 1);
			
			var bData:BitmapData = new BitmapData(realBounds.width, realBounds.height, true, 0);
			var translationMat:Matrix = containerChild.transform.matrix;
			translationMat.translate(-realBounds.x + margin, -realBounds.y + margin);
			
			var label:String = "";
			var childAsMC:MovieClip = containerChild as MovieClip;
			if (childAsMC) {	
				label = childAsMC.currentFrameLabel || label;
			}
			
			if (parentFrameIndex == -1) {
				bData.draw(containerChild, translationMat, preserveColor ? clipColorTransform : null);
			}
			advanceGrandchildren(containerChild);
			
			var frameX:Number = translationMat.tx - containerChild.x * scaleFactorX;
			var frameY:Number = translationMat.ty - containerChild.y * scaleFactorX;
			var frame:AnimatedBitmapFrame = new AnimatedBitmapFrame(textureName, bData, label, -frameX, -frameY, 0, 0);
			
			if (parentFrameIndex != -1) {
				frame.parentIndex = parentFrameIndex;
			}
			
			return frame;
		}
		
		private function advanceGrandchildren(containerChild:DisplayObject):void {
			var doc:DisplayObjectContainer = containerChild as DisplayObjectContainer;
			if (!doc) {
				return;
			}
			
			for (var i:uint = 0; i < doc.numChildren; i++) {
				var grandchild:MovieClip = doc.getChildAt(i) as MovieClip;
				if (!grandchild) continue;
				
				if (grandchild.currentFrame < grandchild.totalFrames) {
					grandchild.gotoAndStop(grandchild.currentFrame + 1);
				} else {
					grandchild.gotoAndStop(1);
				}
			}
		}		
		
		private function positionFrameOnSheet(frame:AnimatedBitmapFrame):void {
			
			// copy position from parent if frame is not unique
			if (frame.parentIndex != -1) {
				var parentFrame:AnimatedBitmapFrame = frames[frame.parentIndex];
				frame.sheetCoordX = parentFrame.sheetCoordX;
				frame.sheetCoordY = parentFrame.sheetCoordY;
				frame.width = parentFrame.width;
				frame.height = parentFrame.height;
				return;
			}
			
			if (curTextureX + frame.width <= MAX_TEXTURE_WIDTH) {
				frame.sheetCoordX = curTextureX;
				frame.sheetCoordY = curTextureY;
				
				curTextureX += frame.width;
				
				if (curTextureX > textureWidth) textureWidth = curTextureX;
				if (frame.height > curRowHeight) curRowHeight = frame.height;
				
			} else {
				curTextureY += curRowHeight;
				curTextureX = frame.width;
				curRowHeight = frame.height;
				
				frame.sheetCoordX = 0;
				frame.sheetCoordY = curTextureY;
			}
		}	
		
		/** Utility function to prepend zeros to a frame's name so that it is properly orderer. */ 
		private function appendIntToString(num:int, numOfPlaces:int):String {
			var numString:String = num.toString();
			var outString:String = "";
			for (var i:int = 0; i < numOfPlaces - numString.length; i++) {
				outString += "0";
			}
			return outString + numString;
		}
		
		public static function get instance():BitmapAtlasGenerator {
			return _instance ? _instance : new BitmapAtlasGenerator();
		}
	}
}