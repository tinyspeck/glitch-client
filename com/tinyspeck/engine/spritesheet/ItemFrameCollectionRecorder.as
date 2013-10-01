package com.tinyspeck.engine.spritesheet {

	
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.Tim;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.MCUtil;
	import com.tinyspeck.engine.util.ObjectUtil;
	
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Scene;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	CONFIG::debugging import com.tinyspeck.debug.Console;
	CONFIG::debugging import com.tinyspeck.engine.util.StringUtil;
	CONFIG::debugging import com.tinyspeck.debug.BootError;
	

	public class ItemFrameCollectionRecorder {
		
		public static const instance:ItemFrameCollectionRecorder = new ItemFrameCollectionRecorder();
		
		private const requestsByKey:Object = {};
		private const uniqueRequests:Vector.<FrameCollectionByURLRequest> = new Vector.<FrameCollectionByURLRequest>();
		
		private var drawing:Boolean = false;
		private var currentRequest:FrameCollectionByURLRequest;
		
		public function ItemFrameCollectionRecorder() {
			if (instance) {
				throw new Error("FrameCollectionRecorder is a Singleton, use '.instance' isntead.");
			}
		}
		
		public function getFrameCollectionForItemSWFByUrl(fcByURLRequest:FrameCollectionByURLRequest):void {
			
			var key:String = fcByURLRequest.key;
			
			if (drawing) {
				Benchmark.addCheck("Frame Collection recording request never completed! Details on failed request: item.tsid = " 
					+ currentRequest.item.tsid + ", key = " + currentRequest.key + ", swf url: " + currentRequest.url + ", anim_cmd.state_str: " + currentRequest.anim_cmd.state_str + ".\n "+
					"Forcing completion...");
				
				completeCurrentRequest();
			}
			
			var requests:Vector.<FrameCollectionByURLRequest> = requestsByKey[key];
			if (!requests) {
				// this is the first request for the given key, so queue is up to be processed
				requests = new Vector.<FrameCollectionByURLRequest>();
				requestsByKey[key] = requests;
				
				uniqueRequests.push(fcByURLRequest);
				requests.push(fcByURLRequest);
			} else {
				// otherwise a request is already being processed for the given key, so just queue this one up to be
				// called as part of a batch.
				requests.push(fcByURLRequest);
				return;
			}
			
			if (!drawing) drawNextRequest();
		}
		
		private function drawNextRequest():void {
			if (!uniqueRequests.length) {
				drawing = false;
				return;
			}
			drawing = true;
			currentRequest = uniqueRequests.shift();
			
			var key:String = currentRequest.key;
			var config_sig:String = currentRequest.config_sig;
			var swf_data:SWFData = currentRequest.swf_data;
			var url:String = currentRequest.url;
			var item:Item = currentRequest.item;
			var ss:SSAbstractSheet = currentRequest.ss;
			var anim_cmd:SSAnimationCommand = currentRequest.anim_cmd;
			var at_wh:int = currentRequest.at_wh;
			var scale_to_stage:Boolean = currentRequest.scale_to_stage;
			var ssCollection:SSCollection = currentRequest.ssCollection;
			var view_and_state_ob:Object = currentRequest.view_and_state_ob;
			
			// see if there are any pre-defined frame indices for the animation (for re-using unique frames in animations)
			var frameIndices:Vector.<int> = getUniqueFrameIndicesForAnim(item, anim_cmd);
			
			var mcFinishedLoading:Boolean = (swf_data.mc.numChildren > 0) && (swf_data.mc.getChildAt(0) != null);
			if (!mcFinishedLoading) {
				Benchmark.addCheck("swf_data.mc for SSFC request has not completed loading! : numChildren = " + swf_data.mc.numChildren/* + ", child at index 0 = " + swf_data.mc.getChildAt(0)*/);
			}
			
			// try and record it
			if (!swf_data.is_trant && !swf_data.is_timeline_animated) { 
				// normal scene driven asset
				Benchmark.addCheck("Recording SCENE BASED FrameCollection for item.tsid: " + item.tsid + ", key: " + key + ", url: " + url + ", anim_cmd.state_str: " + anim_cmd.state_str);
				recordSceneBasedAsset(key, item, ss, anim_cmd, at_wh, scale_to_stage, swf_data, frameIndices, ssCollection, view_and_state_ob);
			} else if (swf_data.is_trant) {
				// trant
				Benchmark.addCheck("Recording TRANT BASED FrameCollection for item.tsid: " + item.tsid + ", key: " + key + ", url: " + url + ", anim_cmd.state_str: " + anim_cmd.state_str);
				recordTrantBasedAsset(key, url, item, ss, anim_cmd, at_wh, scale_to_stage, swf_data, frameIndices, ssCollection, view_and_state_ob);	
			} else if (swf_data.is_timeline_animated) {
				// timeline based
				Benchmark.addCheck("Recording TIMELINE BASED FrameCollection for item.tsid: " + item.tsid + ", key: " + key + ", url: " + url + ", anim_cmd.state_str: " + anim_cmd.state_str);
				recordTimelineBasedAsset(key, config_sig, item, ss, anim_cmd, at_wh, scale_to_stage, swf_data, frameIndices, ssCollection, view_and_state_ob);
			} else {
				Benchmark.addCheck("Unknown type for SWFData with item.tsid: " + item.tsid + ", key: " + key + ", url: " + url + ", anim_cmd.state_str: " + anim_cmd.state_str + ".  Unable to record Frame Collection.");
			}
		}
		
		/** Gets any unique frame indices that may be defined in CSSManager */
		private function getUniqueFrameIndicesForAnim(item:Item, anim_cmd:SSAnimationCommand):Vector.<int> {
			var className:String = item.tsid;
			var stateName:String = anim_cmd.state_str.replace("-", "_"); // replace invalid css characters.
			
			var indicesArray:Array = CSSManager.instance.getArrayValueFromStyle(className, stateName);
			var frameIndices:Vector.<int>;
			if (indicesArray && indicesArray.length) {
				frameIndices = Vector.<int>(indicesArray);
			}
			
			return frameIndices;
		}
		
		private function completeCurrentRequest():void {
			
			// if an alias was used, save it
			if (currentRequest.usedAlias && currentRequest.ssFrameCollection) {
				currentRequest.ss.addAliasForFrameCollection(currentRequest.key, currentRequest.ssFrameCollection);
			}
			
			// may not be any requests if an alias was used.
			var requests:Vector.<FrameCollectionByURLRequest> = requestsByKey[currentRequest.key];
			if (requests) {
				for each(var request:FrameCollectionByURLRequest in requests) {
					request.ssFrameCollection = currentRequest.ssFrameCollection;
					
					if (request.onCompleteHandler != null) {
						request.onCompleteHandler(request);
					}
				}
				requestsByKey[currentRequest.key] = null;
				delete requestsByKey[currentRequest.key];
			}
			
			Benchmark.addCheck("onComplete handlers called for SSFC Request with item.tsid: " + currentRequest.item.tsid + ", key: " + currentRequest.key + ", url: " + currentRequest.url);
			drawNextRequest();
		}
		
		private function recordSceneBasedAsset(key:String, item:Item, ss:SSAbstractSheet, anim_cmd:SSAnimationCommand, at_wh:int, 
													  scale_to_stage:Boolean, swf_data:SWFData, frameIndices:Vector.<int>, ssCollection:SSCollection, view_and_state_ob:Object):void {
			
			var ssfc:SSFrameCollection;
			var alias_key:String;
			var alias_state:String;
			
			CONFIG::debugging {
				Console.log(111, ss.name+' try to record key:'+key+' (normal)');
			}
			
			var scene:Scene = MCUtil.getSceneByName(swf_data.mc, anim_cmd.state_str);
			if (scene) { // we have that scene in the mc, record it
				CONFIG::debugging {						
					Console.log(111, ss.name+' matched scene state:'+anim_cmd.state_str);
				}
				ssfc = recordState(key, ss, swf_data, anim_cmd, item, at_wh, scale_to_stage, frameIndices, ssCollection, view_and_state_ob);
				// TODO: return?
				
			} else if (String(parseInt(anim_cmd.state_str)) == anim_cmd.state_str) { // we don't have that numbered scene; try and record highest_count_scene_name
				CONFIG::debugging {
					Console.log(111, ss.name+' using swf_data.highest_count_scene_name:'+swf_data.highest_count_scene_name+' instead of state:'+anim_cmd.state_str);
				}
				alias_state = swf_data.highest_count_scene_name;
				alias_key = item.tsid+':'+alias_state+':'+at_wh+':'+String(scale_to_stage)+':'+String(anim_cmd.scale);
				ssfc = ss.getFrameCollectionByName(alias_key);
				currentRequest.usedAlias = true;
				if (!ssfc) {
					anim_cmd.state_ob = alias_state;
					ssfc = recordState(alias_key, ss, swf_data, anim_cmd, item, at_wh, scale_to_stage, frameIndices, ssCollection, view_and_state_ob);
					// TODO: return;
					// return;
				}
				
			} else { // use default_scene_name
				
				if (MCUtil.getSceneByName(swf_data.mc, ItemSSManager.DEFAULT_SCENE_NAME)) {
					CONFIG::debugging {
						Console.log(111, ss.name+' using default_scene_name:'+ ItemSSManager.DEFAULT_SCENE_NAME+' instead of anim_cmd.state_str:'+anim_cmd.state_str);
					}
					alias_state = ItemSSManager.DEFAULT_SCENE_NAME;
					alias_key = item.tsid+':'+alias_state+':'+at_wh+':'+String(scale_to_stage)+':'+String(anim_cmd.scale);
					ssfc = ss.getFrameCollectionByName(alias_key);
					currentRequest.usedAlias = true;
					if (!ssfc) {
						anim_cmd.state_ob = alias_state;
						ssfc = recordState(alias_key, ss, swf_data, anim_cmd, item, at_wh, scale_to_stage, frameIndices, ssCollection, view_and_state_ob);
						//TODO: return;
						//return;
					}
				} else {
					CONFIG::debugging {
						Console.warn('no scene for default_scene_name??? could not record '+anim_cmd.state_str);
					}
					Benchmark.addCheck("Failed to record SSFC for item.tsid: " + item.tsid + ".  Could not find DEFAULT_SCENE_NAME: " 
						+ ItemSSManager.DEFAULT_SCENE_NAME + ".  anim_cmd.state_str: " + anim_cmd.state_str);
					return;
				}
			}
			
			// if we were able to fetch the frame collection without recording, call all handlers and move on 
			// to the next request.
			if (ssfc) {
				currentRequest.ssFrameCollection = ssfc;
				completeCurrentRequest();
			} else {
				CONFIG::debugging {
					BootError.handleError("Could not generate Scene based SSFC for item tsid: " + item.tsid + ", key: " + key, new Error("Sprite sheeting error"), null, true);
				}
				completeCurrentRequest();
			}
		}
		
		private function recordTrantBasedAsset(key:String, url:String, item:Item, ss:SSAbstractSheet, anim_cmd:SSAnimationCommand, at_wh:int, 
													  scale_to_stage:Boolean, swf_data:SWFData, frameIndices:Vector.<int>, ssCollection:SSCollection, view_and_state_ob:Object):void {
			var ssfc:SSFrameCollection;
			var alias_key:String;
			
			CONFIG::debugging {
				Console.log(111, ss.name+' try to record key:'+key+' (trant)');
			}
			
			Benchmark.addCheck("Initial attempt at recording TRANT based asset");
			ssfc = recordState(key, ss, swf_data, anim_cmd, item, at_wh, scale_to_stage, frameIndices, ssCollection, view_and_state_ob);
			
			// we might not have gotten an ssfc if there was no state_args, like
			// when building an icon view of a trant, so make a default one
			if (!ssfc) {
				anim_cmd.state_ob = item.DEFAULT_STATE;
				anim_cmd.state_args.seed = ItemSSManager.getSeedForItemSWFByUrl(url, item);
				alias_key+= ObjectUtil.makeSignatureForHash(anim_cmd.state_args);
				alias_key+= ':'+at_wh+':'+String(scale_to_stage)+':'+String(anim_cmd.scale);
				currentRequest.usedAlias = true;
				
				Benchmark.addCheck("Attempt to get TRANT based asset SSFC by existing alias: " + alias_key);
				ssfc = ss.getFrameCollectionByName(alias_key);
				if (!ssfc) {
					Benchmark.addCheck("Attempting to record TRANT based asset with alias_key: " + alias_key);
					ssfc = recordState(alias_key, ss, swf_data, anim_cmd, item, at_wh, scale_to_stage, frameIndices, ssCollection, view_and_state_ob);
					// TODO: return;
				}
			}
			
			Benchmark.addCheck("TRANT SSFC after recording attempts: " + ssfc);
			
			// if we were able to fetch the frame collection without recording, call all handlers and move on 
			// to the next request.
			if (ssfc) {
				currentRequest.ssFrameCollection = ssfc;
				Benchmark.addCheck("TRANT SSFC successfully generated, completing request.");
				completeCurrentRequest();
			} else {
				CONFIG::debugging {
					BootError.handleError("Could not generate Trant based SSFC for item tsid: " + item.tsid + ", key: " + key, new Error("Sprite sheeting error"), null, true);
				}
				completeCurrentRequest();
			}
		}
		
		private function recordTimelineBasedAsset(key:String, config_sig:String, item:Item, ss:SSAbstractSheet, anim_cmd:SSAnimationCommand, at_wh:int, 
														 scale_to_stage:Boolean, swf_data:SWFData, frameIndices:Vector.<int>, ssCollection:SSCollection, view_and_state_ob:Object):void {
			var ssfc:SSFrameCollection;
			var alias_key:String;
			var alias_state:String;
			
			CONFIG::debugging {
				Console.log(111, ss.name+' try to record key:'+key+' (timeline)');
			}
			
			ssfc = recordState(key, ss, swf_data, anim_cmd, item, at_wh, scale_to_stage, frameIndices, ssCollection, view_and_state_ob);
			// TODO: any way to make this asynch?
			
			if (!ssfc) {
				if (item.tsid == 'npc_butterfly') {
					alias_state = 'rest-angle2';
				} else {
					var A:Array = ['pause', 'idle_stand', 'idle_hold', 'assembled', 'stand', 'look_screen', 'talk', 'walk', 'rest', swf_data.mc.animations[0]];
					for (var i:int=0;i<A.length;i++) {
						if (swf_data.mc.animations.indexOf(A[int(i)]) > -1) {
							alias_state = A[int(i)];
							break;
						}
					}
				}
				
				alias_key = alias_state+':'+at_wh+':'+String(scale_to_stage)+':'+String(anim_cmd.scale);
				alias_key = item.tsid+':'+config_sig+alias_key;
				ssfc = ss.getFrameCollectionByName(alias_key);
				currentRequest.usedAlias = true;
				if (!ssfc) {
					anim_cmd.state_ob = alias_state;
					ssfc = recordState(alias_key, ss, swf_data, anim_cmd, item, at_wh, scale_to_stage, frameIndices, ssCollection, view_and_state_ob);
					// TODO: return;
					//return;
				}
			}
			
			// if we were able to fetch the frame collection without recording, call all handlers and move on 
			// to the next request.
			if (ssfc) {
				currentRequest.ssFrameCollection = ssfc;
				completeCurrentRequest();
			} else {
				CONFIG::debugging {
					BootError.handleError("Could not generate Timeline based SSFC for item tsid: " + item.tsid + ", key: " + key, new Error("Sprite sheeting error"), null, true);
				}
				completeCurrentRequest();
			}
		}
		
		private static function recordState(key:String, ss:SSAbstractSheet, swf_data:SWFData, anim_cmd:SSAnimationCommand, item:Item, at_wh:int, 
											scale_to_stage:Boolean, frameIndices:Vector.<int>, ssCollection:SSCollection, view_and_state_ob:Object):SSFrameCollection
		{
			
			CONFIG::debugging {
				Console.log(111, 'start '+key)
			}
			
			var start_ts:int;
			var ssfc:SSFrameCollection;
			var fns:Array = [];
			var rect:Rectangle;
			var mc:MovieClip = swf_data.mc;
			var frame:SSFrame;
			var log_rect_size:int;
			var log_rect_str:String = '';
			Benchmark.addCheck("Properties initialized");
			
			ss.ss_options.transparent = (EnvironmentUtil.getUrlArgValue('SWF_ss_opaque') != '1');
			ss.ss_options.scale = anim_cmd.scale;// make sure this is anim_cmd.scale by default! may get changed depending on at_wh and scale_to_stage args
			
			if (at_wh && scale_to_stage) {
				ss.ss_options.scale = (swf_data.mc_w>swf_data.mc_h) ? at_wh/swf_data.mc_w : at_wh/swf_data.mc_h;
			}
			Benchmark.addCheck("Transparency and scale set.");
			
			Tim.stamp(222, 'start Item recordState '+key);
			
			// !at_wh means it is being made fullsize, for the location
			var hide_door:Boolean = !at_wh
				&& WorldModel.ITEM_CLASSES_WITH_DOORS.indexOf(item.tsid) > -1
				&& WorldModel.ITEM_CLASSES_WITH_DOOR_ICONS.indexOf(item.tsid) == -1
			
			// hide the door, because we will be positioning a door over them (we may want to do this in the FLA AS, not sure yet)
			// and we probably for sure do not want to do this in the god item viewer. And let's only do this when at_wh=0 (so not an icon, most likely)
			if (hide_door) {
				try {
					swf_data.mc.maincontainer_mc.house_mc.doorContainer_mc.visible = false;
				} catch(err:Error) {}
				try {
					swf_data.mc.doorContainer_mc.alpha = .5;
				} catch(err:Error) {}
				try {
					swf_data.mc.maincontainer_mc.door_container_mc.visible = false;
				} catch(err:Error) {}
			}
			Benchmark.addCheck("Doors hidden.");
			
			var scene:Scene = MCUtil.getSceneByName(mc, anim_cmd.state_str);
			Benchmark.addCheck("Scene fetched.");
			if (scene && !swf_data.is_timeline_animated) { // we have a scene for this state
				CONFIG::debugging {
					Console.log(111, ss.name+' recording '+anim_cmd.state_str+' (as '+key+') numFrames:'+scene.numFrames);
				}
				
				//Console.info('created '+key+' for '+ss.name);
				ssfc = ss.createNewFrameCollection(key);
				ss.setActiveFrameCollection(key);
				start_ts = getTimer();
				ss.startRecord();
				
				// record each frame
				for(var i:int = 1; i<=scene.numFrames; i++){
					fns.push(i);
					mc.gotoAndStop(i, anim_cmd.state_str);
					
					CONFIG::debugging {
						if (mc.currentScene.name != anim_cmd.state_str) {
							Console.warn('WTF mc.currentScene.name:'+mc.currentScene.name+' anim_cmd.state_str:'+anim_cmd.state_str+' MCUtil.getSceneByName(mc, anim_cmd.state_str).name:'+MCUtil.getSceneByName(mc, anim_cmd.state_str).name);
						}
					}
					
					// determine Sprite Sheet scale from first frame's dimensions.
					if (i==1 && !scale_to_stage) {
						if (at_wh) {
							rect = mc.getBounds(mc);
							ss.ss_options.scale = (rect.width>rect.height) ? at_wh/rect.width : at_wh/rect.height;
						}
					}
					
					// call per frame function if it is defined
					if (mc.hasOwnProperty('ssPerFrame') && mc.ssPerFrame is Function) {
						try {
							mc.ssPerFrame(i);
						} catch(err:Error) {
							; // satisfy compiler
							CONFIG::debugging {
								Console.warn('error calling ssPerFrame');
							}
						}
					}
					
					// record the frame
					frame = ss.recordFrame(mc, key, ss.ss_options);
					ss.snapFrame(mc, frame, ss.ss_options);
					
					if (frame.sourceRectangle) {
						log_rect_size+= (frame.sourceRectangle.height*frame.sourceRectangle.width);
						Tim.stamp(222, 'recordFrame #'+fns.length+' rect:'+frame.sourceRectangle+' '+(frame.sourceRectangle.height*frame.sourceRectangle.width)+'px');
					} else {
						Tim.stamp(222, 'recordFrame #'+fns.length);
					}
				}
				
				if (log_rect_size) {
					log_rect_str = ' (pixels:'+log_rect_size+')';
				}
				
				ss.stopRecord();
				CONFIG::debugging {
					Console.trackValue('Z ISSM '+swf_data.item.label+' '+key, StringUtil.formatNumber((getTimer()-start_ts), 2)+ 'ms');
				}
				ssCollection.figureDefaultActionForFrameCollection(anim_cmd.state_str, ssfc, mc);
				
				CONFIG::debugging {
					Console.log(111, 'recorded '+anim_cmd.state_str+' (as '+key+') fns:'+fns.join(', ')+' scale:'+ss.ss_options.scale);
				}
				
			} else if (swf_data.is_trant) {
				if (!anim_cmd.state_args) {
					// this can happen if we're making an icon of a trant. This will return null,
					// and that will trigger this func to be re-called with the default state_args for the trant
					Benchmark.addCheck("No state args, ssfc will be null.");
				} else {
					Benchmark.addCheck("Try to set state. mc.setState: " + mc.setState + " state args: " + anim_cmd.state_args);
					mc.setState(anim_cmd.state_args);
					Benchmark.addCheck("State set.");
					
					if (at_wh && !scale_to_stage) {
						rect = mc.getBounds(mc);
						ss.ss_options.scale = (rect.width>rect.height) ? at_wh/rect.width : at_wh/rect.height;
					}
					Benchmark.addCheck("Scale set.");
					//Console.info('created '+key+' for '+ss.name);
					ssfc = ss.createNewFrameCollection(key);
					Benchmark.addCheck("Created fresh SSFC." );
					ss.setActiveFrameCollection(key);
					start_ts = getTimer();
					ss.startRecord();
					Benchmark.addCheck("Record started.");
					frame = ss.recordFrame(mc, key);
					Benchmark.addCheck("Frame recorded.");
					ss.snapFrame(mc, frame, ss.ss_options)
					Benchmark.addCheck("Frame snapped.");
					if (frame.sourceRectangle) {
						log_rect_size = (frame.sourceRectangle.height*frame.sourceRectangle.width);
						Tim.stamp(222, 'recordFrame single frame rect:'+frame.sourceRectangle+' '+(frame.sourceRectangle.height*frame.sourceRectangle.width)+'px');
					} else {
						Tim.stamp(222, 'recordFrame single frame');
					}
					ss.stopRecord();
					Benchmark.addCheck("Record stopped.");
					CONFIG::debugging {
						Console.trackValue('Z ISSM '+swf_data.item.label+' '+key, StringUtil.formatNumber((getTimer()-start_ts), 2)+ 'ms');
					}
					ssCollection.figureDefaultActionForFrameCollection(anim_cmd.state_str, ssfc, mc);
					Benchmark.addCheck("Default action determined.");
					mc.stop();
					Benchmark.addCheck("MC stopped.");
				}
				
			} else if (swf_data.is_timeline_animated) {
				
				ItemSSManager.getViewAndState(anim_cmd.state_str, view_and_state_ob);
				var play_anim_str:String = view_and_state_ob.play_anim_str;
				var view_str:String = view_and_state_ob.view_str;
				
				if (mc.animations.indexOf(play_anim_str) == -1) {
					; // satisfy compiler
					CONFIG::debugging {
						Console.log(111, mc.animations.join(', ')+' does not contain '+play_anim_str);
					}
					Benchmark.addCheck("No animation for timeline based asset.  play_anim_str: " + play_anim_str + ".  Available animations: " + mc.animations.join(', '));
				} else {
					
					//Console.info('created '+key+' for '+ss.name);
					ssfc = ss.createNewFrameCollection(key);
					ss.setActiveFrameCollection(key);
					if (view_str) {
						CONFIG::debugging {
							Console.log(111, 'calling mc.setOrientation("'+view_str+'")')
						}
						Benchmark.addCheck("Set timline based orientation");
						mc.setOrientation(view_str);
					}
					
					; // satisfy compiler
					CONFIG::debugging {
						if (Console.priOK('112') || Console.priOK('153')) if (mc.hasOwnProperty('setConsole')) mc.setConsole(Console);
					}
					
					if (mc.hasOwnProperty('initializehead')) {
						if (anim_cmd.config) { // check here for the passed in config for a specific itemstack
							mc.initializehead(anim_cmd.config);
						} else if (swf_data.item.DEFAULT_CONFIG) {
							mc.initializehead(swf_data.item.DEFAULT_CONFIG);
						}
					}
					
					Benchmark.addCheck("Play timeline based animation.");
					mc.playAnimation(play_anim_str);
					
					start_ts = getTimer();
					ss.startRecord();
					
					var fn:int = 0;
					var next_fn:int = 1;
					; // satisfy compiler
					CONFIG::debugging {
						Console.log(111, 'currently at label '+mc.animatee.currentLabel+' before starting to record '+play_anim_str);
					}
					while (mc.animatee.currentLabel == play_anim_str && fn < next_fn){
						fn = mc.animatee.currentFrame;
						fns.push(fn);
						
						if (fns.length==1 && !scale_to_stage) {
							if (at_wh) {
								rect = mc.getBounds(mc);
								ss.ss_options.scale = (rect.width>rect.height) ? at_wh/rect.width : at_wh/rect.height;
							}
						}
						
						frame = ss.recordFrame(mc, key);
						
						var curFrameIndex:uint = fns.length - 1;
						addFrameToSpriteSheet(frame, curFrameIndex, ss, mc, frameIndices, swf_data.item.label+':'+play_anim_str);
						
						if (frame.sourceRectangle) {
							log_rect_size+= (frame.sourceRectangle.height*frame.sourceRectangle.width);
							Tim.stamp(222, 'recordFrame #'+fns.length+' rect:'+frame.sourceRectangle+' '+(frame.sourceRectangle.height*frame.sourceRectangle.width)+'px');
						} else {
							Tim.stamp(222, 'recordFrame #'+fns.length);
						}
						
						mc.animatee.nextFrame();
						
						if (mc.hasOwnProperty('animated_mcs') && mc.animated_mcs is Array) {
							for (i=0;i<mc.animated_mcs.length;i++) {
								if (mc[mc.animated_mcs[int(i)]]) mc[mc.animated_mcs[int(i)]].nextFrame();
							}
						} 
						
						next_fn = mc.animatee.currentFrame;
						CONFIG::debugging {
							if (mc.animatee.currentLabel != play_anim_str) {
								Console.log(111, 'hit frame label '+mc.animatee.currentLabel+' while recording '+play_anim_str+' fn:'+fn+' next_fn:'+next_fn);
							}
						}
						//trace(fn+' '+mc.animatee.currentLabel+' '+next_fn)
					}
					
					CONFIG::debugging {
						//Console.log(111, 'recorded '+state+' (as '+key+') '+fns.join(', '));
						Console.log(111, 'recorded '+anim_cmd.state_str+' (as '+key+') fns:'+fns.join(', ')+' scale:'+ss.ss_options.scale);
					}
					
					mc.stop();
					mc.animatee.stop();
					ss.stopRecord();
					CONFIG::debugging {
						Console.trackValue('Z ISSM '+swf_data.item.label+' '+key, StringUtil.formatNumber((getTimer()-start_ts), 2)+ 'ms');
					}
					ssCollection.figureDefaultActionForFrameCollection(anim_cmd.state_str, ssfc, mc);
					
					if (fns.length == 0) {
						ss.removeFrameCollection(key);
						CONFIG::debugging {
							Console.log(111, 'huh, no frames? mc.animatee.currentLabel:'+mc.animatee.currentLabel+' ')
						}
					}
				}
			} else {
				// never get here
				CONFIG::god {
					throw new Error('Considering the following, how did we get here?'+
						' anim_cmd.state_str:'+anim_cmd.state_str+
						' scene:'+scene+
						' swf_data.is_trant:'+swf_data.is_trant+
						' anim_cmd.state_args:'+anim_cmd.state_args+
						' swf_data.is_timeline_animated:'+swf_data.is_timeline_animated
					);
				}
			}
			
			// unhide the door
			if (hide_door) {
				try {
					swf_data.mc.maincontainer_mc.house_mc.doorContainer_mc.visible = true;
				} catch(err:Error) {}
				try {
					swf_data.mc.doorContainer_mc.alpha = 1;
				} catch(err:Error) {}
				try {
					swf_data.mc.maincontainer_mc.door_container_mc.visible = true;
				} catch(err:Error) {}
			}
			
			Tim.report(222, 'Item recordState '+key+' (frames:'+fns.length+')'+log_rect_str, true);
			
			return ssfc;
		}	
		
		/** 
		 * Adds a frame to a sprite sheet.  Determines if the frame should be copied from an original, or if a fresh version should be drawn.
		 * Unique frames are identified by a -1 in frameIndices.
		 * Duplicates are identified by any int > -1 in frameIndices.
		 * 
		 * Example : 	An animation consisting of 5 frames where frames 0 and 2 are unique would provide frameIndices like so:
		 * 				[-1, 0, -1, 2, 2] 
		 */
		private static function addFrameToSpriteSheet(frame:SSFrame, frameIndex:uint, ss:SSAbstractSheet, sourceMC:MovieClip, frameIndices:Vector.<int>, debug_str:String):void {
			// if the current frame is not unique, copy it
			if (frameIndices) {
				// if frameIndices[frameIndex] is larger than the number of frames in the collection, the CSS definition may be out of date.
				if (frameIndices.length > frameIndex && frameIndices[frameIndex] < ss.activeFrameCollection.frames.length) {
					if (frameIndices[frameIndex] != -1) {
						
						// Although the pixel data may be the same, it may have a different offset. So get the offset unique to the current frame.
						ss.snapFrame(sourceMC, frame, ss.ss_options);
						var frameBounds:Rectangle = frame.originalBounds;
						var frameBMD:BitmapData = (ss as SSMultiBitmapSheet).bmds.splice(frame._bmd_index, 1)[0];
						frameBMD.dispose();
						
						var originalFrameIndex:int = frameIndices[frameIndex];
						var originalFrame:SSFrame = ss.activeFrameCollection.frames[originalFrameIndex];
						ss.copyFrame(frame, originalFrame);
						frame.originalBounds = frameBounds;  // apply the actual offsets.
						
						return;
					}
				} else {
					CONFIG::debugging {
						if (frameIndices.length <= frameIndex) {
							Console.warn(debug_str+' - '+frameIndex+' is out of bounds ('+frameIndices.length+'), which likely means that the dupe frames css rule is out of date with the FLA');
						} else if (frameIndices[frameIndex] < ss.activeFrameCollection.frames.length) {
							Console.warn(debug_str+' - '+' Animation has fewer frames than specified by unique frame indices, which likely means that the dupe frames css rule is out of date with the FLA');
						}
					}
				}
			}
			
			// otherwise draw a fresh frame
			ss.snapFrame(sourceMC, frame, ss.ss_options);
		}		
		
		
	}
}