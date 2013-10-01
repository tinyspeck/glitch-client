package com.tinyspeck.engine.spritesheet
{
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.filters.BitmapFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import org.osflash.signals.Signal;

	public class SSAbstractSheet
	{
		public const recordingStopped:Signal = new Signal(String);
		
		internal const ss_views:Vector.<ISpriteSheetView> = new Vector.<ISpriteSheetView>();
		
		//crank all the levels to flatten any alpha which gives us the outline for interaction_target
		protected const color_trans:ColorTransform = new ColorTransform(1, 1, 1, 1, 255, 255, 255, 255);
		protected const mat:Matrix = new Matrix();
		
		private const INTERACTION_TARGET_NAME:String = 'interaction_target';
		private const _frameCollections:Vector.<SSFrameCollection> = new Vector.<SSFrameCollection>();
		private const sheets_loadedA:Array = [];
		private const frameCollectionAliases:Dictionary = new Dictionary();
		private const _intTargetBitmaps:Vector.<BitmapData> = new Vector.<BitmapData>();
		
		public var ss_options:SSGenOptions;
		
		internal var source_swf_fn_to_frame_map:Object = {};
		internal var activeFrameCollection:SSFrameCollection;
		
		protected var _name:String;
		protected var lazySnapFunction:Function;
		
		private var _recording:Boolean;
		private var _do_not_clean:Boolean;
		
		public function SSAbstractSheet(name:String, options:SSGenOptions, lazySnapFunction:Function, do_not_clean:Boolean) {
			this.lazySnapFunction = lazySnapFunction;
			ss_options = options;
			_name = name;
			_do_not_clean = do_not_clean;
		}
		
		public function get do_not_clean():Boolean {
			return _do_not_clean;
		}
		
		public function get name():String {
			return _name;
		}
		
		public function clearLoadedSheets():void {
			sheets_loadedA.length = 0;
		}
		
		public function sheetHasLoaded(url:String):void {
			if (sheets_loadedA.indexOf(url) > -1) return;
			sheets_loadedA.push(url);
		}
		
		public function hasLoadedBaseSheet():Boolean {
			if (sheets_loadedA.indexOf(AvatarSSManager.getSheetPngUrl(name, 'base')) > -1) return true;
			return false;
		}
		
		public function startRecord():void {
			//if (_name == 'admin_widget') Console.warn('startRecord '+_name+' '+StringUtil.getCallerCodeLocation());
			if(!_recording){
				_recording = true;
			}else{
				//Console.error("Already recording "+_name);
				BootError.handleError('SSAbstractSheet', new Error("Already recording "+_name), ['spritesheet'], !CONFIG::god);
			}
		}
		
		//TODO here
		public function recordFrame(displayObject:DisplayObject, name:String=null, options:SSGenOptions=null):SSFrame {
			if (!options) options = ss_options;
			var frame:SSFrame;

			if (_recording){
				var interaction_target:DisplayObject = null;
				
				// only do the interaction_target special thing if the scale is 1 for now; if we find we need to do it in other cases
				// then we need to figure out how to scale the interaction targets the same as the rest of the swf when we snap
				if (options.scale == 1) {
					interaction_target = (displayObject) ? MovieClip(displayObject).getChildByName(INTERACTION_TARGET_NAME) : null;
				}

				frame = new SSFrame(this, name, interaction_target);
				activeFrameCollection.addFrame(frame);
			}else{
				throw new Error("Currently not recording "+_name+' '+name);
			}
			
			return frame;
		}
		
		public function lazySnapFrame(displayObject:DisplayObject, frame:SSFrame, options:SSGenOptions = null):SSFrame {
			if (!options) options = ss_options;
			if (_recording) {
				snapFrame(displayObject, frame, options);
				return frame;
			} else {
				throw new Error("Currently not recording "+_name+' '+frame._name);
			}
		}
		
		internal function copyFrame(frame:SSFrame, frame_to_copy:SSFrame):void {
			frame._bmd_index = frame_to_copy._bmd_index;
			frame.originalBounds = frame_to_copy.originalBounds;
			frame.has_bmd = frame_to_copy.has_bmd;
			frame.has_temp_bmd = frame_to_copy.has_temp_bmd;
		}
	
		public function stopRecord():void {
			//if (_name == 'admin_widget') Console.warn('stopRecord '+_name+' '+StringUtil.getCallerCodeLocation());
			if(_recording){
				_recording = false;
				recordingStopped.dispatch(activeFrameCollection.name);
			}else{
				throw new Error("Can't stop, when not recording");
			}
		}
		
		public function getViewBitmap():SSViewBitmap {
			var ssBitmap:SSViewBitmap = new SSViewBitmap(this);
			ss_views.push(ssBitmap);
			return ssBitmap;
		}
		
		public function getViewSprite():SSViewSprite {
			var ssSprite:SSViewSprite = new SSViewSprite(this);
			ss_views.push(ssSprite);
			return ssSprite;
		}
		
		public function removeViewSprite(viewSprite:SSViewSprite):Boolean {
			//Console.error(name+' removeViewSprite '+getTimer())
			var ind:int = ss_views.indexOf(viewSprite)
			if(ind != -1){
				ss_views.splice(ind, 1);
				viewSprite.dispose();
				return true;
			}
			return false;
		}
		
		public function removeViewBitmap(viewBitmap:SSViewBitmap):void {
			//Console.info(name+' removeViewBitmap')
			var ind:int = ss_views.indexOf(viewBitmap);
			if(ind != -1){
				ss_views.splice(ind, 1);
				viewBitmap.dispose();
			}
		}
		
		public function setActiveFrameCollection(name:String):void {
			if(name){
				var fcl:int = _frameCollections.length;
				var frameCollection:SSFrameCollection;
				var found:Boolean = false;
				for(var i:int = 0; i<fcl; i++){
					frameCollection = _frameCollections[int(i)];
					if(frameCollection.name == name){
						found = true;
						activeFrameCollection = frameCollection;
						break;
					}
				}
				if(!found){
					throw new Error("active frame collection not set, no framecollection under that name found");
				}
			}
		}
		
		public function addAliasForFrameCollection(alias:String, ssf:SSFrameCollection):void {
			if (!alias || !ssf) return;
			frameCollectionAliases[alias] = ssf.name;
		}
		
		public function createNewFrameCollection(name:String):SSFrameCollection {
			if(name){
				var ssf:SSFrameCollection = new SSFrameCollection(this, name);
				_frameCollections.push(ssf);
				activeFrameCollection = ssf;
				return ssf;
			}else{
				throw new Error("Invalid name for frame collection");
			}
		}
				
		public function removeFrameCollection(name:String):Boolean {
			var frameCollection:SSFrameCollection;
			var fcl:int = _frameCollections.length;
			for(var i:int = 0; i<fcl; i++){
				frameCollection = _frameCollections[int(i)];
				if(frameCollection.name == name){
					frameCollection.dispose();
					_frameCollections.splice(i, 1);
					return true;
				}
			}
			
			return false;
		}
		
		internal function getFrameCollectionByAlias(alias:String):SSFrameCollection {
			if (!frameCollectionAliases[alias]) return null;
			return getFrameCollectionByName(frameCollectionAliases[alias]);
		}
		
		public function getFrameCollectionByName(name:String):SSFrameCollection {
			var frameCollection:SSFrameCollection;
			var fcl:int = _frameCollections.length;
			//Console.log(111, 'frameCollections.length:'+frameCollections.length+' find:'+name);
			for(var i:int = 0; i<fcl; i++){
				frameCollection = _frameCollections[int(i)];
				//Console.log(111, 'frameCollection.name:'+frameCollection.name+(frameCollection.name == name));
				if(frameCollection.name == name){
					return frameCollection;
					break;
				}
			}
			return null;
		}
		
		internal function getFirstFrameCollection():SSFrameCollection {
			if(_frameCollections && _frameCollections.length){
				return _frameCollections[int(0)];
			}
			return null;
		}
		
		internal function getDisplayObjectRectangle(container:DisplayObjectContainer, processFilters:Boolean):Rectangle {
			var final_rectangle:Rectangle = processDisplayObjectContainer(container, processFilters);
			
			// translate to local
			var local_point:Point = container.globalToLocal(new Point(final_rectangle.x, final_rectangle.y));
			final_rectangle = new Rectangle(local_point.x, local_point.y, final_rectangle.width, final_rectangle.height);
			
			return final_rectangle;
		}
		
		internal function processDisplayObjectContainer(container:DisplayObjectContainer, processFilters:Boolean):Rectangle {
			var result_rectangle:Rectangle = null;
			
			// Process if container exists
			if (container != null) {
				var index:int = 0;
				var displayObject:DisplayObject;
				
				// Process each child DisplayObject
				for(var childIndex:int = 0; childIndex < container.numChildren; childIndex++){
					displayObject = container.getChildAt(childIndex);
					
					//If we are recursing all children, we also get the rectangle of children within these children.
					if (displayObject is DisplayObjectContainer) {
						
						// Let's drill into the structure till we find the deepest DisplayObject
						var displayObject_rectangle:Rectangle = processDisplayObjectContainer(displayObject as DisplayObjectContainer, processFilters);
						
						// Now, stepping out, uniting the result creates a rectangle that surrounds siblings
						if (result_rectangle == null) { 
							result_rectangle = displayObject_rectangle.clone();
						} else {
							result_rectangle = result_rectangle.union(displayObject_rectangle);
						}                        
					}                        
				}
				
				// Get bounds of current container, at this point we're stepping out of the nested DisplayObjects
				var container_rectangle:Rectangle = container.getBounds(container.stage);
				
				if (result_rectangle == null) { 
					result_rectangle = container_rectangle.clone();
				} else {
					result_rectangle = result_rectangle.union(container_rectangle);
				}
				
				// Include all filters if requested and they exist
				if ((processFilters == true) && (container.filters.length > 0)) {
					var filterGenerater_rectangle:Rectangle = new Rectangle(0, 0, result_rectangle.width, result_rectangle.height);
					var bmd:BitmapData = new BitmapData(result_rectangle.width, result_rectangle.height, true, 0x00000000);
					
					var filter_minimumX:Number = 0;
					var filter_minimumY:Number = 0;
					
					var filtersLength:int = container.filters.length;
					for (var filtersIndex:int = 0; filtersIndex < filtersLength; filtersIndex++) {                     
						var filter:BitmapFilter = container.filters[filtersIndex];
						
						var filter_rectangle:Rectangle = bmd.generateFilterRect(filterGenerater_rectangle, filter);
						
						filter_minimumX = filter_minimumX + filter_rectangle.x;
						filter_minimumY = filter_minimumY + filter_rectangle.y;
						
						filterGenerater_rectangle = filter_rectangle.clone();
						filterGenerater_rectangle.x = 0;
						filterGenerater_rectangle.y = 0;
						
						bmd = new BitmapData(filterGenerater_rectangle.width, filterGenerater_rectangle.height, true, 0x00000000);
					}
					
					// Reposition filter_rectangle back to global coordinates
					filter_rectangle.x = result_rectangle.x + filter_minimumX;
					filter_rectangle.y = result_rectangle.y + filter_minimumY;
					
					result_rectangle = filter_rectangle.clone();
				}                
			} else {
				throw new Error("No displayobject was passed as an argument");
			}
			
			return result_rectangle;
		}

		protected function createBoundingRect(displayObject:DisplayObject):Rectangle {
			var rect:Rectangle = displayObject.getBounds(displayObject);
			// this needs to be tested before switching to it, but it should take into account filters applied in the swfs:
			// update 2011/02/16: do &SWF_ss_opaque=1 and look at avatars with the below uncommented to see why it sucks!
			//var rect:Rectangle = getDisplayObjectRectangle(displayObject as DisplayObjectContainer, true);
			
			// make sure these are whole pixel values!
			rect.width = Math.ceil(rect.width);
			rect.height = Math.ceil(rect.height);
			rect.x = Math.floor(rect.x);
			rect.y = Math.floor(rect.y);
			
			return rect;
		}
		
		internal function snapFrame(displayObject:DisplayObject, frame:SSFrame, options:SSGenOptions):void {
			//see if we have an interaction target
			if(frame.interaction_target){
				CONFIG::debugging {
					Console.log(111, 'creating interaction target');
				}
				
				var rect:Rectangle = createBoundingRect(frame.interaction_target);
				mat.identity();
				mat.translate(-rect.x, -rect.y);
				
				var bmp:BitmapData = new BitmapData(
					Math.min(2000, Math.max(1, frame.interaction_target.width)), 
					Math.min(2000, Math.max(1, frame.interaction_target.height)), 
					true, 
					0
				);
				bmp.lock();
				bmp.draw(frame.interaction_target, mat, color_trans, null, null, true);
				bmp.unlock();
				
				frame.int_target_bmd_index = _intTargetBitmaps.push(bmp) -1;
			}
			frame.has_bmd = true;
		}
		
		internal function updateViewBitmapData(bitmap:SSViewBitmap):void {
			//
		}
		
		internal function updateViewSprite(sprite:SSViewSprite):void {
			//
		}
		
		public function getBitmapData(sprite:SSViewSprite):BitmapData {
			return null;
		}
		
		public function getFrame(sprite:SSViewSprite):SSFrame {
			return null;
		}
		
		internal function update():void {
			CONFIG::debugging var str:String = '';
			var ssv:ISpriteSheetUpdateable;
			
			const vl:int = ss_views.length;
			for(var i:int = 0; i<vl; i++){
				CONFIG::debugging {
					str+= getTimer()+' '+i+'\n';
				}
				if (i >= ss_views.length) {
					CONFIG::debugging {
						Console.warn(name+' i:'+i+' >= ss_views.length:'+ss_views.length+' (when we started the loop, ss_views.length was '+vl+') \n'+str);
					}
					break;
				}
				ssv = ss_views[int(i)];
				ssv.update();
			}
		}
		
		internal function dispose():void {
			CONFIG::debugging {
				Console.warn(name+' dispose');
			}
			
			//Dispose of views, frame collections.
			var view:ISpriteSheetView;
			while(ss_views.length){
				view = ss_views.pop();
				view.dispose();
			}
			var intTargetBitmap:BitmapData
			while(_intTargetBitmaps.length){
				intTargetBitmap = _intTargetBitmaps.pop();
				intTargetBitmap.dispose();
			}
			
			var fc:SSFrameCollection;
			while(_frameCollections.length){
				fc = _frameCollections.pop();
				fc.dispose();
			}
			
			activeFrameCollection = null;
		}

		public function get intTargetBitmaps():Vector.<BitmapData> {
			return _intTargetBitmaps;
		}

		public function get frameCollections():Vector.<SSFrameCollection> {
			return _frameCollections;
		}
	}
}