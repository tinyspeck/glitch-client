package com.tinyspeck.engine.spritesheet
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	
	import flash.display.MovieClip;
	import flash.display.Scene;
	import flash.utils.Dictionary;

	/**
		SSCollection has a bunch of SS
		each SS has a bunch of FrameCollections
		each SS can have any number of ss_views
	*/
	public class SSCollection
	{
		//Stores references to the sprite sheets.
		private var spriteSheets:Vector.<SSAbstractSheet>;
		private var spriteSheetHash:Dictionary;
				
		public function SSCollection() {
			spriteSheets = new Vector.<SSAbstractSheet>();
			spriteSheetHash = new Dictionary();
			
			StageBeacon.setInterval(cleanup, (EnvironmentUtil.getUrlArgValue('SWF_cleanup_ms')) ? int(EnvironmentUtil.getUrlArgValue('SWF_cleanup_ms')) : 30000);
		}
		
		public function memReport():String {
			var str:String = '\nSSCollection memReport\n+--------------------------------------------------\n';
			var ss:SSAbstractSheet;
			var ssfc:SSFrameCollection;
			var view:ISpriteSheetView;
			str+= 'spriteSheets.length:'+spriteSheets.length+'\n';
			ss_loop: for (var i:int=0;i<spriteSheets.length;i++) {
				ss = spriteSheets[int(i)];
				str+= 'ss '+ss.name+'---------\n';
				if (ss is SSMultiBitmapSheet) str+= '     bmds.length '+SSMultiBitmapSheet(ss).bmds.length+'\n';
				//Console.info('------------------------- '+ss._name+' ss.ss_views.length:'+ss.ss_views.length)
				
				for (var fn:String in ss.source_swf_fn_to_frame_map) {
					str+= '      fn '+fn+' '+ss.source_swf_fn_to_frame_map[fn]+' '+SSFrame(ss.source_swf_fn_to_frame_map[fn]).has_bmd+'\n';
				}
				// clean up this map, since we're now removing all frameCollections at this point
				var m:int;
				str+= '      ss.frameCollections.length:'+ss.frameCollections.length+'\n';
				fc_loop: for (m=0;m<ss.frameCollections.length;m++) {
					ssfc = ss.frameCollections[m];
					str+= '            '+ssfc.name+'\n';
				}
			}
			
			return str;
		}
		
		public function cleanup():void {
			var ss:SSAbstractSheet;
			var ssfc:SSFrameCollection;
			var view:ISpriteSheetView;
			//Console.info('------------------------------------- spriteSheets.length:'+spriteSheets.length)
			// loop over all ss in the collection (so, all item or avatar sss)
			ss_loop: for (var i:int=0;i<spriteSheets.length;i++) {
				ss = spriteSheets[int(i)];
				//Console.info('------------------------- '+ss._name+' ss.ss_views.length:'+ss.ss_views.length)
				
				if (ss.do_not_clean) continue ss_loop;
				if (ss.ss_views.length) continue ss_loop;
				
				// clean up this map, since we're now removing all frameCollections at this point
				ss.source_swf_fn_to_frame_map = {};
				var m:int;
				fc_loop: for (m=0;m<ss.frameCollections.length;m++) {
					ssfc = ss.frameCollections[m];
					//Console.info(ss._name+' discarding unused:"'+ssfc.name+'" because there are no ss_views');
					
					if (ss.removeFrameCollection(ssfc.name)) {
						m--;
					}
					
				}
				ss.clearLoadedSheets();
				if (ss is SSMultiBitmapSheet) SSMultiBitmapSheet(ss).bmds.length = 0;
			}
		}
		
		public function getSpriteSheet(name:String):SSAbstractSheet {
			return spriteSheetHash[name];
		}
						
		public function createNewSpriteSheet(name:String, options:SSGenOptions, lazySnapFunction:Function, do_not_clean:Boolean):SSAbstractSheet
		{
			if (name && name != "") {
				if (spriteSheetHash[name] != null) {
					throw new Error("A spritesheet under this name already exists");
				} else {
					if (options.type == SSGenOptions.TYPE_SINGLE_BITMAP) {
						var sssb:SSSingleBitmapSheet = new SSSingleBitmapSheet(name, options, lazySnapFunction, do_not_clean);
						spriteSheetHash[name] = sssb;
						spriteSheets.push(sssb);
						return sssb;
					} else if(options.type == SSGenOptions.TYPE_MULTIPLE_BITMAPS) {
						var ssmb:SSMultiBitmapSheet = new SSMultiBitmapSheet(name, options, lazySnapFunction, do_not_clean);
						spriteSheetHash[name] = ssmb;
						spriteSheets.push(ssmb);
						return ssmb;
					} else {
						throw new Error("Undefined spritesheet type");
						return null;
					}
				}
			}
			return null;
		}
		
		// decides what the default action for a given frame collection should be, based on length of collection and loopers array of the source mc
		// we pass in name instead of using ssfc.name because ssfc.name is not always the same as as the keys in loops_from and loopers (see ItemSSManager)
		public function figureDefaultActionForFrameCollection(name:String, ssfc:SSFrameCollection, mc:MovieClip):void {
			if (mc.hasOwnProperty('loopers') && mc.loopers is Array && mc.loopers.indexOf(name) > -1) {
				ssfc.default_action = SSFrameCollection.GOTOANDLOOP;
			} else if (ssfc.frames.length < 2) {
				ssfc.default_action = SSFrameCollection.GOTOANDSTOP;
			} else {
				if (name == 'tool_animation') { // special case, so we do not have to edit all tool FLAs to include tool_animation in loopers
					ssfc.default_action = SSFrameCollection.GOTOANDLOOP;
				} else {
					ssfc.default_action = SSFrameCollection.GOTOANDPLAY;
				}
			}
			
			if (mc.hasOwnProperty('loop_froms') && mc.loop_froms && mc.loop_froms[name] is int) {
				ssfc.loops_from = mc.loop_froms[name];
			}
		}
	
		public function createSpriteSheetFrom(name:String, options:SSGenOptions, mc:MovieClip, lazySnapFunction:Function, do_not_clean:Boolean):SSAbstractSheet
		{
			CONFIG::debugging {
				Console.log(111, name);
			}
			var ss:SSAbstractSheet = createNewSpriteSheet(name, options, lazySnapFunction, do_not_clean);
			if(ss){
				var scene:Scene;
				var scenes:Array = mc.scenes;
				var scenesLength:int = scenes.length;
				ss.startRecord();
				for(var i:int = 0; i<scenesLength; i++){
					scene = scenes[int(i)];
					CONFIG::debugging {
						Console.log(111, name+' '+scene.name+' numFrames:'+scene.numFrames);
					}
					var ssfc:SSFrameCollection = ss.createNewFrameCollection(scene.name);
					ss.setActiveFrameCollection(scene.name);
					
					var fns:Array = [];
					for(var j:int = 1; j<=scene.numFrames; j++){
						fns.push(j)
						mc.gotoAndStop(j,scene.name);
						if (mc.hasOwnProperty('ssPerFrame') && mc.ssPerFrame is Function) {
							try {
								mc.ssPerFrame(j);
							} catch(err:Error) {
								//Console.warn('error calling ssPerFrame');
							}

						}
						if(mc.currentFrameLabel){
							ss.recordFrame(mc,mc.currentFrameLabel,options);
						}else{
							ss.recordFrame(mc,null,options);
						}
					}
					
					figureDefaultActionForFrameCollection(ssfc.name, ssfc, mc);

					CONFIG::debugging {
						Console.log(111, 'recorded '+scene.name+' '+fns.join(', '));
					}
				}
				ss.stopRecord();
			}
			mc.stop();
			return ss;
		}
		
		public function removeSpriteSheet(name:String):void {
			if(name && name != ""){
				if(spriteSheetHash[name] == null){
					throw new Error("Can't dispose non-existent spritesheet");
				}else{
					var sheet:SSAbstractSheet = spriteSheetHash[name];
					sheet.dispose();
					spriteSheetHash[name] = null;
					delete spriteSheetHash[name];
					var ind:int = spriteSheets.indexOf(sheet,0);
					if(ind != -1){
						spriteSheets.splice(ind,1);
					}
				}
			}
		}
								
		public function removeAll():void {
			var spriteSheet:SSAbstractSheet;
			while(spriteSheets.length){
				spriteSheet = spriteSheets.pop();
				spriteSheet.dispose();
			}
		}
		
		/** Currently no more than a synonym for removeAll() */
		public function dispose():void {
			removeAll();
		}
		
		public function update():void {
			for each (var spriteSheet:SSAbstractSheet in spriteSheets) {
				spriteSheet.update();
			}
		}
	}
}