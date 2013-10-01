//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Mark this as a runnable app in FB while you work on it, but please do not commit that change to the project
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

package {
	import com.adobe.serialization.json.JSON;
	import com.quietless.bitmap.BitmapSnapshot;
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.data.FlashVarData;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.control.engine.DataLoaderController;
	import com.tinyspeck.engine.control.mapping.ControllerMap;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.PlatformLine;
	import com.tinyspeck.engine.data.location.Wall;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.memory.ClientOnlyPools;
	import com.tinyspeck.engine.memory.EnginePools;
	import com.tinyspeck.engine.model.TSEngineConstants;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.physics.util.LocationPhysicsHealer;
	import com.tinyspeck.engine.spritesheet.ItemSSManager;
	import com.tinyspeck.engine.spritesheet.SSAbstractSheet;
	import com.tinyspeck.engine.spritesheet.SSFrame;
	import com.tinyspeck.engine.spritesheet.SSFrameCollection;
	import com.tinyspeck.engine.spritesheet.SSMultiBitmapSheet;
	import com.tinyspeck.engine.spritesheet.SSViewSprite;
	import com.tinyspeck.engine.spritesheet.SWFData;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.MCUtil;
	import com.tinyspeck.engine.util.PNGUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.geo.PlatformLineView;
	import com.tinyspeck.engine.view.geo.WallView;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.ui.Checkbox;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Scene;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.Security;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	
	import org.bytearray.gif.encoder.GIFEncoder;
	
	Security.allowDomain('*');
	
	[SWF(width='900', height='600', backgroundColor='#ffffff', frameRate='30')]
	public class GodItemViewer extends MovieClip {
		public function GodItemViewer():void {
			Console.setOutput(Console.FIREBUG, true);
			Console.info('GodItemViewer');
			stage.frameRate = TSEngineConstants.TARGET_FRAMERATE;
			init();
		}
		
		private var flashvars:Object;
		private var generate_png_id:String;
		private var model:TSModelLocator;
		
		// will reference the loaded item swf
		private var mc:MovieClip;
		
		// we draw this to show size of loaded swf
		private var ss_box:Sprite = new Sprite();
		private var swf_size_box:Sprite = new Sprite();
		private var geo_holder:Sprite = new Sprite();
		private var geo_controls:Sprite = new Sprite();
		
		private var item_class:String;
		private var item:Item;
		private var itemstack:Itemstack;
		
		private var god_liv:LocationItemstackView;
		private var generate_iiv:ItemIconView;
		private var geo:Object;
		private var platsV:Vector.<PlatformLine>;
		private var wallsV:Vector.<Wall>;
		
		private var cb:Checkbox;
		private var tf:TextField = new TextField();
		private var perm_tf:TextField = new TextField();
		
		private var plats_to_save:Object;
		private var walls_to_save:Object;
		private var dragged_plv:PlatformLineView;
		private var dragged_wv:WallView;
		private var drag_pt:Point = new Point();
		
		private var dragging_end:Boolean;
		private var dragging_start:Boolean;
		private var dragging_top:Boolean;
		private var dragging_bottom:Boolean;
		private var default_perm_tf_txt:String = '(H-click a plat to change hardness)';
		
		private function init():void {
			Console.info('initing');
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			flashvars = LoaderInfo(root.loaderInfo).parameters;
			generate_png_id = String(flashvars.id);
			
			if (!flashvars.generate) {
				ItemSSManager.double_measure = true;
			}
			
			var url_args:Object = EnvironmentUtil.getURLAndQSArgs().args;
			var fps:int = int(url_args['SWF_fps']);
			if (fps) stage.frameRate = fps;
			
			// minimal set up
			Console.setPri(url_args['pri'] || '');
			Console.info('pri'+url_args['pri']);
			
			//set the stage on the boot status
			this.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, handleGlobalErrors);
			
			model = TSModelLocator.instance;
			model.flashVarModel = new FlashVarModel(FlashVarData.createFlashVarData(this));
			BootError.fvm = model.flashVarModel;
			StageBeacon.init(stage, model.flashVarModel);
			EnginePools.init();
			ClientOnlyPools.init();
			var controllerMap:ControllerMap = new ControllerMap();
			controllerMap.dataLoaderController = new DataLoaderController();
			TSFrontController.instance.setControllerMap(controllerMap);
			KeyBeacon.instance.setStage(stage);
			LocationPhysicsHealer.init();
			// end minimal set up
			
			stage.addChild(swf_size_box);
			stage.addChild(ss_box);
			
			item_class = flashvars.item_class || 'fake_item_class';
			
			// stick records in the model
			item = model.worldModel.items[item_class] = Item.fromAnonymous({
				tsid: item_class,
				asset_swf_v: flashvars.item_url,
				label: item_class
			}, item_class);
			
			itemstack = model.worldModel.itemstacks['fake_stack_id'] = Itemstack.fromAnonymous({
				tsid: 'fake_stack_id',
				x: 0,
				y: 0,
				class_tsid: item_class,
				count:1,
				s:'iconic'
			}, 'fake_stack_id');
			
			if (flashvars.geo_str) {
				geo = com.adobe.serialization.json.JSON.decode(flashvars.geo_str);
				CONFIG::debugging {
					Console.info('geo: '+typeof geo);
					Console.dir(geo);
				}
			}
			
			if (!geo) {
				geo = {};
				CONFIG::debugging {
					Console.info('no geo!')
				}
			}
			
			parseGeo();
			
			Console.warn('item.asset_swf_v '+item.asset_swf_v);
			ItemSSManager.getSSForItemSWFByUrl(item.asset_swf_v, item, onLoad);
			
			ExternalInterface.addCallback("doSwitchScene", onSwitchScene);
			ExternalInterface.addCallback("doSwitchAnimation", onSwitchAnimation);
			ExternalInterface.addCallback("doSwitchConfig", onSwitchConfig);
			ExternalInterface.addCallback("doneSavingGeo", doneSavingGeo);
			ExternalInterface.addCallback("doSaveFurnPng", saveFurnPng);
			
			StageBeacon.enter_frame_sig.add(ItemSSManager.onEnterFrame);
		}
		
		private function handleGlobalErrors(e:UncaughtErrorEvent):void {
			if (e.error) {
				if (e.error.getStackTrace) {
					CONFIG::debugging {
						Console.error(e.error.getStackTrace());
					}
				} else {
					CONFIG::debugging {
						Console.error(e.error);
					}
				}
			} else {
				CONFIG::debugging {
					Console.error(e);
				}
			}
			
			try {
				BootError.handleGlobalErrors(e);
			} catch (err:Error) {
				CONFIG::debugging {
					Console.error('error calling BootError.handleGlobalErrors: '+err);
				}
			}
			
			if (flashvars.generate) {
				if (flashvars.save_fail_callback_name) {
					ExternalInterface.call(flashvars.save_fail_callback_name, 'some error');
				}
			}
		}
		
		private function onSwitchScene(str:String):void {
			//god_liv.animate(str, true);
			Itemstack.updateFromAnonymous({s:str}, itemstack);
			god_liv.changeHandler(true);
			MCUtil.playScene(mc, str);
		}
		
		private function onSwitchAnimation(str:String, make_gif:Boolean=false):void {
			//god_liv.animate(str, true);
			Itemstack.updateFromAnonymous({s:str}, itemstack);
			god_liv.changeHandler(true);
			mc.playAnimation(str);
			
			if (make_gif) saveGif(god_liv.ss_view as SSViewSprite);
		}
		
		private function onSwitchConfig(config:Object):void {
			Console.pridir(111, config);
			
			if (item.tsid.indexOf('trant_') == 0) {
				Itemstack.updateFromAnonymous({s:config}, itemstack);
				if (mc.hasOwnProperty('setState')) mc.setState(config);
			} else {
				Itemstack.updateFromAnonymous({config:config}, itemstack);
				if (mc.hasOwnProperty('initializehead')) mc.initializehead(config);
			}
			
			god_liv.changeHandler(true);
		}
				
		private function saveGif(ss_view:SSViewSprite):void {
			
			
			var ss:SSMultiBitmapSheet = ss_view.ss as SSMultiBitmapSheet;
			
			
			var fc:SSFrameCollection;
			for (var i:int=0;i<ss.frameCollections.length;i++) {
				fc = ss.frameCollections[i];
				Console.warn(fc.name);
			}
			
			var fc_name:String = ss_view.frame_coll_name;
			
			Console.info(fc_name);
			Console.warn(ss.bmds.length);
			
			fc = ss.getFrameCollectionByName(fc_name);
			var bm:Bitmap;
			var bmds:Vector.<BitmapData> = fc.getbmds();
			Console.warn('bmds.length:'+bmds.length);
			var frames:Vector.<SSFrame> = ss.getFramesForCollection(fc_name);
			Console.warn('frames.length:'+frames.length);
			
			
			
			var gif_encoder:GIFEncoder = new GIFEncoder();
			gif_encoder.start();
			gif_encoder.setRepeat((ss_view.will_loop) ? 0 : 1);
			gif_encoder.setDelay (33);
			
			var w:int;
			var h:int;
			var fx:int = 1000;
			var fy:int = 1000;
			var m:int;
			var frame:SSFrame;
			var o_rect:Rectangle;
			var bmd:BitmapData;
			
			for (m=0;m<frames.length;m++) {
				frame = frames[m];
				o_rect = frame.originalBounds;
				
				fx = Math.min(fx, o_rect.x);
				fy = Math.min(fy, o_rect.y);
			}
			
			Console.info('fx:'+fx+' fy:'+fy);
			
			for (m=0;m<frames.length;m++) {
				frame = frames[m];
				o_rect = frame.originalBounds;
				bmd = bmds[m];
				
				var needed_w:int = (o_rect.x-fx)+bmd.width;
				var needed_h:int = (o_rect.y-fy)+bmd.height;
				
				Console.info(o_rect+' b.w:'+bmd.width+' b.h:'+bmd.height+' nw:'+needed_w+' nh:'+needed_h);
				
				w = Math.max(w, needed_w);
				h = Math.max(h, needed_h);
			}
			
			Console.info('w:'+w+' h:'+h);
			
			var next_x:int = 0;
			var next_y:int = 0;
			for (m=0;m<frames.length;m++) {
				frame = frames[m];
				o_rect = frame.originalBounds;
				bmd = new BitmapData(w, h, false, 0xffffff);
				bmd.draw(bmds[m], new Matrix(1, 0, 0, 1, o_rect.x-fx, o_rect.y-fy));
				bm = new Bitmap(bmd);
				stage.addChild(bm);
				bm.x = next_x;
				bm.y = next_y;
				
				if (bm.x + bm.width > stage.stageWidth) {
					next_x = bm.x = 0;
					next_y = bm.y = next_y+bm.height+1;
				} else {
					next_x+= bm.width+1;
				}
				
				gif_encoder.addFrame(bmd);
				
			}
			
			gif_encoder.finish();
			
			var vars:Object = {
				id: generate_png_id
			};
			
			var file_name:String = fc_name.replace(/\:/g, '_').replace(/\[/g, '_').replace(/\]/g, '_').replace(/\,/g, '_');
			
			var img:BitmapSnapshot = new BitmapSnapshot(null, file_name, 0, 0, null, gif_encoder.stream);
			
			img.saveOnServerMultiPart(file_name, vars, '/callbacks/upload_item_gif.php', null, function(ok:Boolean, txt:String):void {
				Console.info(ok, txt);
				
				//if (flashvars.save_callback_name) {
				//	ExternalInterface.call(flashvars.save_callback_name, txt+'');
				//}
			});
		}
		
		private function saveFurnPng():void {
			if (generate_png_id) {
				Console.info('generating png for id '+generate_png_id);
				generate_iiv = new ItemIconView(item_class, 0, 'iconic', 'default', false, true);
				
				var rect:Rectangle = generate_iiv.getBounds(generate_iiv);
				var min_size:int = 140;
				
				if (rect.width < min_size || rect.height < min_size) {
					generate_iiv = new ItemIconView(item_class, min_size, 'iconic', 'default', false, true);
				}
				
				var img:BitmapSnapshot = new BitmapSnapshot(generate_iiv, generate_png_id+'.png');
				
				img.saveOnServerMultiPart('image', {id:generate_png_id}, 'http://api.dev.glitch.com/simple/god.furniture.setImage', null, function(ok:Boolean, txt:String):void {
					Console.info('saved '+txt);
					
					var rsp:Object;
					try {
						rsp = (txt) ? com.adobe.serialization.json.JSON.decode(txt) : {};
					} catch (e:Error) {}
					if (flashvars.save_furn_png_callback_name) {
						ExternalInterface.call(flashvars.save_furn_png_callback_name, rsp.ok, rsp.url);
					}
					Console.dir(rsp);
					
				});
				
			} else {
				Console.warn('no id for generating png')
			}
		}
		
		private function onLoad(ss:SSAbstractSheet, url:String):void {
			var swf_data:SWFData = ItemSSManager.getSWFDataByUrl(item.asset_swf_v);
			if (!swf_data) {
				Console.warn('no swf_data');
				return;
			}
			
			mc = swf_data.mc;
			if (!mc) {
				Console.warn('no swf_data.mc');
				return;
			}
			
			if (mc.hasOwnProperty('itemRun')) mc.itemRun();
			if (mc && mc.scenes) {
				
				if (flashvars.generate) {
					
					var state_to_save:String = 'iconic';
					
					generate_iiv = new ItemIconView(item_class, 40, state_to_save, 'default', false, true);
					stage.addChild(generate_iiv);
					
					if (generate_png_id) {
						Console.info('generating png for id '+generate_png_id)
						
						var img:BitmapSnapshot = new BitmapSnapshot(generate_iiv, generate_png_id+'.png');
						var extra_files:Object;
						
						
						// if it has a broken scene, saved that too!
						var broken_scene:Scene = MCUtil.getSceneByName(mc, 'broken_iconic');
						if (broken_scene) {
							generate_iiv.icon_animate('broken_iconic', true);
							var img_broken:BitmapSnapshot = new BitmapSnapshot(generate_iiv, generate_png_id+'_broken.png');
							
							extra_files= {};
							extra_files[generate_png_id+'_broken'] = img_broken.bmd;
						}
						
						
						
						god_liv = new LocationItemstackView('fake_stack_id');
						god_liv.worth_rendering = true;
						itemstack.x = Math.round(stage.stageWidth/2);
						itemstack.y = Math.round(stage.stageHeight/2);
						god_liv.x = itemstack.x;
						god_liv.y = itemstack.y;
						stage.addChild(god_liv);
						
						var sp:Sprite = new Sprite();
						sp.x = itemstack.x;
						sp.y = itemstack.y;
						stage.addChild(sp);
						
						Itemstack.updateFromAnonymous({s:'1'}, itemstack);
						god_liv.changeHandler(true);
						
						var base64_str:String = PNGUtil.getBase64StringFromBitmap(new Bitmap(img.bmd));
						
						var vars:Object = {
							id: generate_png_id,
							base64_str: base64_str,
							stage_w: swf_data.mc_w,
							stage_h: swf_data.mc_h
						};
						
						var finish:Function = function(lis:LocationItemstackView):void {
							var placement_rect:Rectangle = god_liv.getBounds(god_liv);
							vars.placement_x = Math.round(placement_rect.x);
							vars.placement_y = Math.round(placement_rect.y);
							vars.placement_w = Math.round(placement_rect.width);
							vars.placement_h = Math.round(placement_rect.height);
							/*
							var g:Graphics = sp.graphics;
							g.beginFill(0, .5);
							g.drawRect(placement_rect.x, placement_rect.y, placement_rect.width, placement_rect.height);
							
							var str:String = '';
							for (var k:String in vars) str+= k+':'+vars[k]+'\n';
							ExternalInterface.call('alert', str);
							*/
							img.saveOnServerMultiPart(generate_png_id, vars, '/callbacks/upload_item.php', extra_files, function(ok:Boolean, txt:String):void {
								if (flashvars.save_callback_name) {
									ExternalInterface.call(flashvars.save_callback_name, txt+'');
								}
							});
						};
						
						if (!god_liv.is_loaded) {
							god_liv.loadCompleted_sig.add(finish);
						} else {
							finish()
						}
						
						
					} else {
						Console.warn('no id for generating png')
					}
					
				} else {
					var i:int;
					
					god_liv = new LocationItemstackView('fake_stack_id');
					god_liv.worth_rendering = true;
					god_liv.x = itemstack.x;
					god_liv.y = itemstack.y;
					ss_box.addChild(god_liv);
					
					addControls();
					
					drawGeo();
					
					if (mc.hasOwnProperty('myAnim') && mc.myAnim) {
						Itemstack.updateFromAnonymous({s:mc.myAnim}, itemstack);
						god_liv.changeHandler(true);
						mc.playAnimation(mc.myAnim);
					}
					
					var scene_namesA:Array = [];
					
					for (i=0; i<mc.scenes.length; i++) {
						var scene:Scene = mc.scenes[i];
						scene_namesA.push(scene.name);
					}		
					
					var anim_namesA:Array = [];
					
					if (mc.hasOwnProperty('animations') && mc.animations) {
						//ExternalInterface.call("traceFlash", "got anims - "+mc.animations.length);
						
						for (var j:int=0; j<mc.animations.length; j++) {
							if (mc.orientations.length == 0) {
								//ExternalInterface.call("traceFlash", "adding "+j);
								anim_namesA.push(mc.animations[j])
							} else {
								for (var m:int=0; m<mc.orientations.length; m++) {
									//ExternalInterface.call("traceFlash", "adding "+j+'-'+m);
									anim_namesA.push(mc.animations[j]+'-'+mc.orientations[m])
								}
							}
						}
					} else {
						//ExternalInterface.call("traceFlash", "no anims");
					}
					
					ExternalInterface.call("add_all_animations_and_scenes", scene_namesA, anim_namesA);
					
					if (mc.hasOwnProperty('config_options')) {
						if (item.tsid.indexOf('trant_') == 0) {
							ExternalInterface.call("add_config_options_and_config", mc.config_options, item.DEFAULT_STATE || {});
						} else {
							var default_config:Object = (mc.hasOwnProperty('default_config') && mc.default_config) ? mc.default_config : {};
							ExternalInterface.call("add_config_options_and_config", mc.config_options, item.DEFAULT_CONFIG || default_config);
						}
					}
					
					
					//stage.addChild(swf_size_box);
					swf_size_box.addChild(mc);
					mc.gotoAndStop(1);
					
					swf_size_box.y = Math.max(20, (stage.stageHeight/2)-ss.ss_options.movieHeight);
					swf_size_box.x = ((stage.stageWidth/2)-ss.ss_options.movieWidth)/2;
					
					ss_box.x = (stage.stageWidth*.75);
					ss_box.y = swf_size_box.y+ss.ss_options.movieHeight;
					
					geo_holder.x = ss_box.x;
					geo_holder.y = ss_box.y;
					
					stage.addChild(geo_controls);
					stage.addChild(geo_holder);
					
					swf_size_box.graphics.clear();
					swf_size_box.graphics.lineStyle(0, 0x000000, 0);
					swf_size_box.graphics.beginFill(0x414141, 1);
					swf_size_box.graphics.drawRect(0, 0, ss.ss_options.movieWidth, ss.ss_options.movieHeight);
				}
				
			} else {
				ExternalInterface.call("scenes_failed");
			}
			
		}
		
		private function addControls():void {
			cb = new Checkbox({
				x: 5,
				y: stage.stageHeight,
				checked: true,
				label: 'show geo',
				name: 'geo'
			});
			cb.y = 0;
			cb.x = 0;
			cb.addEventListener(TSEvent.CHANGED, function(e:TSEvent):void {
				if (e.data.checked) {
					geo_holder.visible = true;
				} else {
					geo_holder.visible = false;
				}
			}, false, 0, true);
			geo_controls.addChild(cb);
			
			TFUtil.prepTF(tf, false);
			tf.border = false;
			tf.embedFonts = false;
			tf.htmlText = '<font face="Arial" size="12" color="#000000"> | ' +
				'<font color="#cc0000"><a href="event:revert" class="">revert</a></font> | ' +
				'<font color="#cc0000"><a href="event:remove" class="">remove all</a></font> (k-click to remove just one) | ' +
				'<font color="#cc0000"><a href="event:add_wall" class="">add wall</a></font> | ' +
				'<font color="#cc0000"><a href="event:add_plat" class="">add plat</a></font> | ' +
				'<font color="#cc0000"><a href="event:save" class="">SAVE GEO</a></font>' +
				'</font>';
			tf.addEventListener(TextEvent.LINK, controlsLinkHandler, false, 0, true);
			tf.x = cb.x+cb.width;
			geo_controls.addChild(tf);
			
			TFUtil.prepTF(perm_tf, false);
			perm_tf.border = false;
			perm_tf.embedFonts = false;
			
			perm_tf.htmlText = '<font face="Arial" size="12" color="#000000">'+default_perm_tf_txt+'</font>';
			perm_tf.x = tf.x+tf.width+20;
			geo_controls.addChild(perm_tf);
		}
		
		private function revertToLastSavedGeo():void {
			parseGeo();
			drawGeo();
		}
		
		private function addWall():void {
			wallsV.push(Wall.fromAnonymous(
				{"x":0, "y":-50, "h":50},
				wallsV.length.toString()
			));
			drawGeo();
		}
		
		private function addPlat():void {
			var default_ob:Object = plat_perms_setH[plat_perms_setA[0]];
			platsV.push(PlatformLine.fromAnonymous(
				{"platform_item_perm":default_ob.platform_item_perm,"platform_pc_perm":default_ob.platform_pc_perm,"start":{"x":-30,"y":0},"end":{"x":30,"y":0}},
				platsV.length.toString()
			));
			drawGeo();
		}
		
		private function removeAllPlatsAndWalls():void {
			if (platsV) platsV.length = 0;
			if (wallsV) wallsV.length = 0;
			drawGeo();
		}
		
		private function saveGeoChanges():void {
			var i:int;
			
			if (platsV) {
				var plat:PlatformLine;
				var plv:PlatformLineView;
				for (i=0; i<platsV.length; i++) {
					plat = platsV[i];
					if (!plat) {
						continue;
					}
					if (!plats_to_save) plats_to_save = {};
					plats_to_save[i.toString()] = plat.AMF();
				}
			}
			
			if (wallsV) {
				var wall:Wall;
				var wv:WallView;
				for (i=0; i<wallsV.length; i++) {
					wall = wallsV[i];
					if (!wall) {
						continue;
					}
					if (!walls_to_save) walls_to_save = {};
					walls_to_save[i.toString()] = wall.AMF();
				}
			}
			
			Console.info(StringUtil.getJsonStr(plats_to_save));
			Console.info(StringUtil.getJsonStr(walls_to_save));
			
			geo_controls.visible = false;
			// the JS will call back to doneSavingGeo when done with this:
			ExternalInterface.call("saveGeo", (plats_to_save ? StringUtil.getJsonStr(plats_to_save) : ''), (walls_to_save ? StringUtil.getJsonStr(walls_to_save) : ''));
		}
		
		private function controlsLinkHandler(e:TextEvent):void {
			var which:String = e.text;
			switch(which) {
				case 'add_wall':
					addWall();
					break;
				case 'add_plat':
					addPlat();
					break;
				case 'revert':
					revertToLastSavedGeo();
					break;
				case 'remove':
					removeAllPlatsAndWalls()
					break;
				case 'save':
					saveGeoChanges();
					break;
			}
		}
		
		// JS calls back to this after saving geo
		private function doneSavingGeo(success:Boolean):void {
			if (success) {
				geo.walls = walls_to_save;
				geo.plats = plats_to_save;
				Console.dir(geo);
			}
			
			plats_to_save = null;
			walls_to_save = null;
			
			geo_controls.visible = true;
		}
		
		private function onGeoRollOver(e:MouseEvent):void {
			if (dragged_wv || dragged_plv) return;
			if (e.target is WallView) {
				var wv:WallView = WallView(e.target);
			} else if (e.target is PlatformLineView) {
				var plv:PlatformLineView = PlatformLineView(e.target);
				perm_tf.htmlText = '<font face="Arial" size="12" color="#000000">plat perms:'+findMatchingPlatPermsSet(plv.platformLine)+'</font>';
				geo_holder.addChild(plv);
			}
		}
		
		private function onGeoRollOut(e:MouseEvent):void {
			if (e.target is WallView) {
				var wv:WallView = WallView(e.target);
			} else if (e.target is PlatformLineView) {
				var plv:PlatformLineView = PlatformLineView(e.target);
				perm_tf.htmlText = '<font face="Arial" size="12" color="#000000">'+default_perm_tf_txt+'</font>';
			}
		}
		
		private function onGeoMouseDown(e:MouseEvent):void {
			if (KeyBeacon.instance.pressed(Keyboard.K)) {
				removeGeo(e);
				return;
			}

			if (KeyBeacon.instance.pressed(Keyboard.H)) {
				changePermsOnGeo(e);
				return;
			}
			
			startDraggingGeo(e);
		}
		
		private function removeGeo(e:MouseEvent):void {
			// remove the thing from the model
			var i:int;
			if (e.target is WallView) {
				var wv:WallView = WallView(e.target);
				i = wallsV.indexOf(wv.wall);
				if (i > -1) wallsV.splice(i, 1);
				wv.dispose();
			} else if (e.target is PlatformLineView) {
				var plv:PlatformLineView = PlatformLineView(e.target);
				i = platsV.indexOf(plv.platformLine);
				if (i > -1) platsV.splice(i, 1);
				plv.dispose();
			} else {
				return;
			}
			
			// remove it from the display
			e.target.parent.removeChild(e.target);
		}

		
		
		/*
		0: permeable from either direction
		-1: permeable for objects moving from +inf to -inf
		1: permeable for objects moving from -inf to +inf 
		*/
		private var plat_perms_setA:Array = ['hard_on_top_for_both', 'hard_on_top_only_for_item', 'hard_on_top_only_for_pc'];
		private var plat_perms_setH:Object = {
			'hard_on_top_for_both': {platform_pc_perm:-1, platform_item_perm:-1}, // default, hard on top for both
			'hard_on_top_only_for_item': {platform_pc_perm:0, platform_item_perm:-1}, // hard on top only for item
			'hard_on_top_only_for_pc': {platform_pc_perm:-1, platform_item_perm:0} // hard on top only for player
		}
		
		private function findMatchingPlatPermsSet(pl:PlatformLine):String {
			var plat_perms:Object;
			for (var plat_perms_set:String in plat_perms_setH) {
				plat_perms = plat_perms_setH[plat_perms_set];
				if (plat_perms.platform_pc_perm == pl.platform_pc_perm && plat_perms.platform_item_perm == pl.platform_item_perm) {
					return plat_perms_set;
					break;
				}
			}
			
			return null;
		}
		
		private function changePermsOnGeo(e:MouseEvent):void {
			var k:String;
			var plat_perms:Object;
			var perms_index:int;
			var next_perms_index:int;
			var next_perms:Object;
			var plv:PlatformLineView;
			var wv:WallView;
			var plat_perms_set:String
			
			if (e.target is WallView) {
				wv = WallView(e.target);
				
				/* THIS IS HOW THEY ARE CREATED
				wallsV.push(Wall.fromAnonymous(
				{"x":0, "y":-50, "h":50},
				wallsV.length.toString()
				));
				*/
				
			} else if (e.target is PlatformLineView) {
				plv = PlatformLineView(e.target);
				perms_index = 0;
				
				plat_perms_set = findMatchingPlatPermsSet(plv.platformLine);
				if (plat_perms_set) {
					perms_index = plat_perms_setA.indexOf(plat_perms_set);
				}
				
				next_perms_index = (perms_index >= plat_perms_setA.length-1) ? 0 : perms_index+1;
				next_perms = plat_perms_setH[plat_perms_setA[next_perms_index]];
				
				plv.platformLine.updateFromAnonymous({
					platform_pc_perm: next_perms.platform_pc_perm,
					platform_item_perm: next_perms.platform_item_perm
				});
			} else {
				return;
			}
			
			drawGeo();
		}
		
		private function startDraggingGeo(e:MouseEvent):void {
			var tolerance:int = 5;
			
			if (e.target is WallView) {
				dragged_wv = WallView(e.target);
				dragged_wv.parent.addChild(dragged_wv);
				
				dragging_top = true;
				dragging_bottom = true;
				if (dragged_wv.mouseY > dragged_wv.wall.h-tolerance) {
					dragging_top = false;
				} else if (dragged_wv.mouseY < tolerance) {
					dragging_bottom = false;
				}
			} else if (e.target is PlatformLineView) {
				dragged_plv = PlatformLineView(e.target);
				dragged_plv.parent.addChild(dragged_plv);
				
				dragging_start = true;
				dragging_end = true;
				if (dragged_plv.mouseX > dragged_plv.platformLine.end.x-tolerance) {
					dragging_start = false;
				} else if (dragged_plv.mouseX < dragged_plv.platformLine.start.x+tolerance) {
					dragging_end = false;
				}
			} else {
				return;
			}
			
			drag_pt.x = stage.mouseX;
			drag_pt.y = stage.mouseY;
			
			StageBeacon.mouse_up_sig.add(dropAfterDraggingGeo);
			StageBeacon.mouse_move_sig.add(onGeoMouseMove);
		}
		
		private function onGeoMouseMove(e:MouseEvent):void {
			onGeoDrag();
		}
		
		private function onGeoDrag():void {
			var diff_x:int = stage.mouseX - drag_pt.x;
			var diff_y:int = stage.mouseY - drag_pt.y;
			drag_pt.x = stage.mouseX;
			drag_pt.y = stage.mouseY;
			
			if (dragged_wv) {
				if (dragging_top && dragging_bottom) {
					dragged_wv.wall.x+= diff_x;
					dragged_wv.wall.y+= diff_y;
				} else if (dragging_top) {
					dragged_wv.wall.y+= diff_y;
					dragged_wv.wall.h-= diff_y;
				} else if (dragging_bottom) {
					dragged_wv.wall.h+= diff_y;
				}
				dragged_wv.syncRendererWithModel();
			} else if (dragged_plv) {
				if (dragging_start) {
					dragged_plv.platformLine.start.x+= diff_x;
					dragged_plv.platformLine.start.y+= diff_y;
				}
				if (dragging_end) {
					dragged_plv.platformLine.end.x+= diff_x;
					dragged_plv.platformLine.end.y+= diff_y;
				}
				dragged_plv.syncRendererWithModel();
			}
		}
		
		private function dropAfterDraggingGeo(e:MouseEvent):void {
			StageBeacon.mouse_up_sig.remove(dropAfterDraggingGeo);
			StageBeacon.mouse_move_sig.remove(onGeoMouseMove);
			onGeoDrag();
			
			if (dragged_plv) {
				snapPL(dragged_plv.platformLine);
				dragged_plv.syncRendererWithModel();
			}
			
			// this is not necessary, and we lose the z index changes that might have happened in startDraggingGeo
			//drawGeo();
			
			dragged_wv = null;
			dragged_plv = null;
		}
		
		private function snapPL(pl:PlatformLine):void {
			// snap to other platforms and walls but never to self
			var test_pt:Point = new Point(pl.start.x, pl.start.y);
			var other_pt:Point = new Point(pl.end.x, pl.end.y);
			var snap_pt:Object = LocationPhysicsHealer.snapPointToPlatformLinesAndWalls(test_pt, pl.is_for_placement, platsV, wallsV);
			if ((snap_pt != test_pt) && ((snap_pt.x != other_pt.x) || (snap_pt.y != other_pt.y))) {
				pl.start.x = snap_pt.x;
				pl.start.y = snap_pt.y;
			}
			
			test_pt = new Point(pl.end.x, pl.end.y);
			other_pt = new Point(pl.start.x, pl.start.y);
			snap_pt = LocationPhysicsHealer.snapPointToPlatformLinesAndWalls(test_pt, pl.is_for_placement, platsV, wallsV);
			if ((snap_pt != test_pt) && ((snap_pt.x != other_pt.x) || (snap_pt.y != other_pt.y))) {
				pl.end.x = snap_pt.x;
				pl.end.y = snap_pt.y;
			}
		}
		
		private function parseGeo():void {
			platsV = PlatformLine.parseMultiple(geo.plats);
			wallsV = Wall.parseMultiple(geo.walls);
			Console.info('platsV.length:'+platsV.length+' wallsV.length:'+wallsV.length);
		}
		
		private function drawGeo():void {
			SpriteUtil.clean(geo_holder, true);
			
			var i:int;
			if (platsV) {
				var plat:PlatformLine;
				var plv:PlatformLineView;
				for (i=0; i<platsV.length; i++) {
					plat = platsV[i];
					if (!plat || !plat.start || !plat.end) {
						continue;
					}
					plv = new PlatformLineView(plat);
					plv.addEventListener(MouseEvent.MOUSE_DOWN, onGeoMouseDown);
					plv.addEventListener(MouseEvent.ROLL_OVER, onGeoRollOver);
					plv.addEventListener(MouseEvent.ROLL_OUT, onGeoRollOut);
					geo_holder.addChild(plv);
				}
			}
			if (wallsV) {
				var wall:Wall;
				var wv:WallView;
				for (i=0; i<wallsV.length; i++) {
					wall = wallsV[i];
					if (!wall) {
						continue;
					}
					wv = new WallView(wall, '');
					wv.addEventListener(MouseEvent.MOUSE_DOWN, onGeoMouseDown);
					geo_holder.addChild(wv);
				}
			}
		}
		
	}
}

