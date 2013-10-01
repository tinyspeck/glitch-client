package com.tinyspeck.engine.control.engine {
	
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.core.control.IController;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.Door;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.location.MiddleGroundLayer;
	import com.tinyspeck.engine.data.location.PlatformLine;
	import com.tinyspeck.engine.data.location.Wall;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.PhysicsModel;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.physics.avatar.AvatarPhysicsHandler;
	import com.tinyspeck.engine.physics.avatar.AvatarPhysicsObject;
	import com.tinyspeck.engine.physics.avatar.PhysicsParameter;
	import com.tinyspeck.engine.physics.avatar.PhysicsSetting;
	import com.tinyspeck.engine.physics.data.PhysicsQuery;
	import com.tinyspeck.engine.physics.util.LocationPhysicsHealer;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.PCView;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.renderer.MiddleGroundRenderer;
	
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	CONFIG::god { import com.tinyspeck.engine.view.geo.PlatformLineView; }
	CONFIG::god { import com.tinyspeck.engine.view.geo.WallView; }

/*
	OVERVIEW OF HOW THE CLIENT TREATS PHYSIC SETTINGS
	
	Client loads location data from GS in move_start msgs:
	- gets all preset settings
	- gets either
	   - a setting for the location
	   - or clones normal preset setting as the setting for the location
	   - or barfs becasue there was no normal setting
	- updates the location setting with any url params (this updates the setting itself, as if it had loaded from the GS that way)
	- clones the location setting to the pc.apo
	
	In the admin panel:
	- clicking a setting button loads that setting up in the form and applies it to the pc.apo
	- making any adjustments with the sliders updates the pc.apo
	- clicking save 
	- gets the pc.apo.setting and sends it to the GS as the new physic setting for the location and
	- updates the local location setting with the values from the pc.apo
	- reselects the location button
*/
	final public class PhysicsController extends AbstractController implements IMoveListener, IController {
		private var isCheckingForInteractionSprites:Boolean = false;
		private var isStarted:Boolean = false;
		private var physicsModel:PhysicsModel;
		private var worldModel:WorldModel;
		private var flashVarModel:FlashVarModel;
		private var layoutModel:LayoutModel;
		
		private var dynamicObjects:Vector.<AvatarPhysicsObject>;
		private var avatarPhysicsHandler:AvatarPhysicsHandler;
		
		private var currentLocation:Location;
		private var currentPC:PC;
					
		public function PhysicsController() {
			worldModel = model.worldModel;
			layoutModel = model.layoutModel;
			physicsModel = model.physicsModel;
			flashVarModel = model.flashVarModel;
			
			layoutModel.loc_vp_rect_collision_scale = flashVarModel.vp_rect_collision_scale;
			
			dynamicObjects = new Vector.<AvatarPhysicsObject>();
			
			avatarPhysicsHandler = new AvatarPhysicsHandler();
			physicsModel.lastViewportQuery = new PhysicsQuery();
			physicsModel.lastViewportQuery.doPCs = true;
			physicsModel.lastViewportQuery.doItemstacks = true;
			
			TSFrontController.instance.registerMoveListener(this);
			physicsModel.registerCBProp(onPcAdjustmentsChange, "pc_adjustments");
			physicsModel.registerCBProp(onPcAdjustmentsChange, "ignore_pc_adjustments");
		}
		
		public function start():void {
			isStarted = true;
			isCheckingForInteractionSprites = true;
		}
		
		public function stopCheckingForInteractionSprites():void {
			isCheckingForInteractionSprites = false;
		}
		
		public function stop():void {
			if (worldModel.pc && worldModel.pc.apo) {
				worldModel.pc.apo.triggerResetVelocity = true;
			}
			isStarted = false;
		}
		
		// IMoveListener funcs
		// -----------------------------------------------------------------
		
		public function moveLocationHasChanged():void {
			CONFIG::debugging {
				if (model.flashVarModel.benchmark_physics_adjustments) {
					Benchmark.addCheck('PhysicsController.moveLocationHasChanged');
				}
			}
			currentLocation = null;
		}

		public function moveLocationAssetsAreReady():void {
			setUpGeoPhysicsForLocation();
		}
		
		public function moveMoveStarted():void {
			// we used to do this in moveLocationAssetsAreReady, but that failed
			// when the teleport move was to reload the current location (so in_location != true,
			// which causes a rebuild, but moveLocationAssetsAreReady does not get called)
			
			CONFIG::debugging {
				if (model.flashVarModel.benchmark_physics_adjustments) {
					Benchmark.addCheck('PhysicsController.moveMoveStarted');
				}
			}
			
			currentLocation = worldModel.location;
			
			//clear this out!
			if (model.worldModel.pc) {
				model.worldModel.pc.apo._interaction_spV.length = 0;
			}
			
			setUpPCPhysicsForLocation();
		}
		
		public function moveMoveEnded():void {
		
		}
		
		// -----------------------------------------------------------------
		// END IMoveListener funcs
		
		CONFIG::locodeco public function healGeometry():void {
			// do an extended fixup where we bring plat endpoints into loc bounds
			if (LocationPhysicsHealer.fixupPlatformLines(currentLocation, true)) {
				physicsModel.triggerCBPropDirect("platform_lines_healed");
			}
		}
		
		public function setUpGeoPhysicsForLocation():void {
			// do a basic fixup where we swap the start and end if they are reversed
			LocationPhysicsHealer.fixupPlatformLines(currentLocation)
			LocationPhysicsHealer.generatePhysicsLines(currentLocation);
			if(physicsModel.physicsQuadtree) {
				physicsModel.physicsQuadtree.setLocation(currentLocation);
			}
		}
		
		private function setUpPCPhysicsForLocation():void {
			CONFIG::debugging {
				if (model.flashVarModel.benchmark_physics_adjustments) {
					Benchmark.addCheck('PhysicsController.setUpPCPhysicsForLocation');
				}
				Console.priinfo(539, 'setUpPCPhysicsForLocation');
			}
			
			var pc:PC = model.worldModel.pc;
			var params:Vector.<PhysicsParameter> = physicsModel.settables.parametersV;
			var setting:PhysicsSetting;
			
			if(currentPC && currentPC.apo){
				dynamicObjects.length = 0;
				//removeDynamicsPhysicsObject(currentPC.apo);
			}
			
			currentPC = pc;
			
			if (pc) {
				// this is a dumb way to do this, but for now...
				pc.apo.extra_vx = int(EnvironmentUtil.getUrlArgValue('SWF_extra')) || 0;
				setting = physicsModel.settables.getSettingByName(model.worldModel.location.tsid);
				
				var name:String;
				var type:String
				
				// the below actually changes the AvatarPhysicsSettings, because we do not clone it above
				const url_args:Object = EnvironmentUtil.getURLAndQSArgs().args;
				
				// catch an old param name for pc_scale
				if ('SWF_ava_display_scale' in url_args) {
					url_args['pc_scale'] = url_args['SWF_ava_display_scale'];
				}
				
				const ll:int = params.length;
				for (var i:int=ll-1; i>=0; --i) {
					name = params[int(i)].name;
					type = params[int(i)].type;
					CONFIG::debugging {
						Console.log(539, name+' DEFAULT: '+setting[name]);
					}
					
					if (name in url_args && !isNaN(parseFloat(url_args[name]))) {
						setting[name] = parseFloat(url_args[name]);
						CONFIG::debugging {
							Console.log(539, name+' CHANGED BY URL PARAM TO '+setting[name]);
						}
					}
					// to catch any old SWF_jetpack=1
					if ('SWF_'+name in url_args && !isNaN(parseFloat(url_args['SWF_'+name]))) {
						setting[name] = parseFloat(url_args['SWF_'+name]);
						CONFIG::debugging {
							Console.log(539, name+' CHANGED BY SWF URL PARAM TO '+setting[name]);
						}
					}
					
					if (name == '') {
						setting[name] = parseFloat(url_args['SWF_'+name]);
					}
					
					if (type == PhysicsParameter.TYPE_INT) {
						setting[name] = Math.round(setting[name]);
					}
				}
				
				// now clone it and assign
				model.worldModel.location.physics_setting = setting.clone();
				
				// apply any overrides and set it
				setPcPhysics(pc, setting.clone(), null);
				
				addDynamicPhysicsObject(pc.apo);
			}
		}
		
		public function addOtherPCAPOs():void {
			var pc:PC;
			const pcs:Dictionary = worldModel.pcs;
			const pc_tsid_list:Dictionary = model.worldModel.location.pc_tsid_list;
			for (var tsid:String in pc_tsid_list) {
				pc = (pcs[tsid] as PC);
				
				if (!model.worldModel.location && ! model.worldModel.location.physics_setting) {
					continue
				}
				
				pc.apo.setting = model.worldModel.location.physics_setting.clone();
				
				if (pc.physics_adjustments) {
					var setting:PhysicsSetting = physicsModel.settables.getSettingByName(pc.apo.setting.name);
					if (setting) {
						setPcPhysics(pc, setting.clone(), pc.physics_adjustments);
						pc.physics_adjustments = null;
					} else {
						CONFIG::debugging {
							Console.error('no setting?');
						}
					}
				}
				
				if (model.flashVarModel.use_vec) {
					addDynamicPhysicsObject(pc.apo);
				}
			}
		}
		
		private function onPcAdjustmentsChange(adjustments:Object):void {
			CONFIG::debugging {
				if (model.flashVarModel.benchmark_physics_adjustments) {
					Benchmark.addCheck('PhysicsController.onPcAdjustmentsChange:\n' +
						'\tadjustments:\n' + StringUtil.deepTrace(adjustments) +
						'\tcurrentPC.apo:\n' + (currentPC && currentPC.apo ? currentPC.apo.setting.toString() : 'null'));
				}
			}
			if (currentPC && currentPC.apo) {
				setPcPhysics(currentPC, physicsModel.settables.getSettingByName(currentPC.apo.setting.name).clone(), model.physicsModel.pc_adjustments);
			}
		}
		
		public function setPcPhysics(pc:PC, loc_setting_clone:PhysicsSetting, adjustments:Object):void {
			CONFIG::debugging {
				if (model.flashVarModel.benchmark_physics_adjustments) {
					Benchmark.addCheck('PhysicsController.setPcPhysics:\n' +
						loc_setting_clone.toString());
				}
				Console.priinfo(539, 'setPcPhysics');
			}
			const parametersV:Vector.<PhysicsParameter> = physicsModel.settables.parametersV;
			
			// set this as the pcs setting
			pc.apo.base_setting = loc_setting_clone.clone();
			pc.apo.setting = loc_setting_clone;
			
			var name:String;
			var type:String;

			// this has problems related to how it interacts with a player zoom setting
			// it currently overrides user setting, and then the user can override it again
			// not sure what the solution is right now
			/*if (pc == model.worldModel.pc) {
				if (adjustments && 'viewport_scale' in adjustments) {
					TSFrontController.instance.setViewportScale(adjustments['viewport_scale'], 0);
					delete adjustments['viewport_scale'];
				}
			}*/
			
			// go over settables and make adjustments
			for (var i:int=parametersV.length-1; i>=0; --i) {
				name = parametersV[int(i)].name;
				type = parametersV[int(i)].type;
				CONFIG::debugging var was:* = loc_setting_clone[name];
				
				if (!model.worldModel.location.no_physics_adjustments && !physicsModel.ignore_pc_adjustments && adjustments && name in adjustments) {
					if (type == PhysicsParameter.TYPE_BOOL) {
						// THIS IS ONLY JETPACK AS OF NOW
						
						// Only set it to true by an adjustment
						// which lets it remain the location default
						// if the adjustemnt value is false. This
						// means we have no way of turning off Boolean
						// setting in a location when they are set
						// to true for a location; if we ever need to
						// do that, we could start sending no_jetpack
						// instead of jetpack. We can go ahead and
						// delete it if is false
						if (Boolean(adjustments[name]) === true) {
							loc_setting_clone[name] = Boolean(adjustments[name]);
						} else {
							delete adjustments[name];
						}
					} else {
						loc_setting_clone[name] = loc_setting_clone[name]*parseFloat(adjustments[name]);
						if (type == PhysicsParameter.TYPE_INT) {
							loc_setting_clone[name] = Math.round(loc_setting_clone[name]);
						}
						
					}
					CONFIG::debugging {
						if (pc == model.worldModel.pc) {
							if (was != loc_setting_clone[name]) {
								Console.trackPhysicsValue(' '+name, 'ADJUSTED: '+ loc_setting_clone[name]+' (was:'+was+')');
							} else {
								Console.trackPhysicsValue(' '+name, 'not adj: '+loc_setting_clone[name]);
							}
						}
					}
					//Console.warn(name+' CHANGED BY adjustments PARAM TO '+setting[name]);
				} else {
					if (pc == model.worldModel.pc) {
						; // satisfy compiler
						CONFIG::debugging {
							Console.trackPhysicsValue(' '+name, 'not adj: '+loc_setting_clone[name]);
						}
					}
				}
			}
			
			if (pc == model.worldModel.pc && TSFrontController.instance.getMainView().gameRenderer.getAvatarView()) {
				TSFrontController.instance.getMainView().gameRenderer.getAvatarView().rescale();
			}
		
			// No need for this, here since we are not dynamically updating other pc apu physics settings here
			if (pc != model.worldModel.pc && TSFrontController.instance.getMainView().gameRenderer.locationView && TSFrontController.instance.getMainView().gameRenderer.locationView.middleGroundRenderer) {
				//TSFrontController.instance.getMainView().gameRenderer.locationView.middleGroundRenderer.rescalePCs();
			}

			if (pc != model.worldModel.pc) {
				if (TSFrontController.instance.getMainView().gameRenderer.locationView) {
					var pc_view:PCView = TSFrontController.instance.getMainView().gameRenderer.getPcViewByTsid(pc.tsid);
					if (pc_view) {
						pc_view.rescale();
					}
					//TSFrontController.instance.getMainView().gameRenderer.locationView.middleGroundRenderer.rescalePCs();
				}
			}
			
			
		}
		
		/**
		 * Adds new walls and platform lines.
		 * 
		 * Takes an Object of the following format: {
		 *   walls: {...},
		 *   platform_lines: {...},
		 *   doors: {...}
		 * }
		 */
		public function addGeo(geo:Object):void {
			const walls:Object = geo.walls;
			const platform_lines:Object = geo.platform_lines;
			const doors:Object = geo.doors;
			
			const mg:MiddleGroundLayer = model.worldModel.location.mg;
			const gameRenderer:LocationRenderer = TSFrontController.instance.getMainView().gameRenderer;
			const mgr:MiddleGroundRenderer = gameRenderer.locationView.middleGroundRenderer;
			
			var tsid:String;
			
			// walls
			var wall:Wall;
			for (tsid in walls) {
				// create model
				wall = Wall.fromAnonymous(walls[tsid], tsid);
				wall.client::geo_was_updated = true;
				// add model 
				mg.walls.push(wall);
				CONFIG::god {
					// dirty view
					mgr.wallModelDirty = true;
				}
			}
			
			var platformLine:PlatformLine;
			for (tsid in platform_lines) {
				// create model
				platformLine = PlatformLine.fromAnonymous(platform_lines[tsid], tsid);
				platformLine.client::geo_was_updated = true;
				// add model 
				mg.platform_lines.push(platformLine);
				CONFIG::god {
					// dirty view
					mgr.platformLineModelDirty = true;
				}
			}

			if (doors) {
				var door:Door;
				for (tsid in doors) {
					CONFIG::debugging {
						Console.dir(doors[tsid]);
					}
					// create model
					door = Door.fromAnonymous(doors[tsid], tsid);
					// add model 
					mg.doors.push(door);
					mgr.doorModelDirty = true;
				}
			}
			
			// rebuild physics model
			setUpGeoPhysicsForLocation();
		}
		
		// right now this just takes a door assuming it has already been changed. If we want to do the whole
		 // updateFromAnon with an object, we can use updateGeo below, after updating it to handle anon door objects
		public function onDoorModified(door:Object):void {
			door.client::physRect = null; // this will cause it to get recreated correctly by PhysicsQuadtree.insertDoor
			setUpGeoPhysicsForLocation();
		}
		
		/**
		 * Updates any properties on walls and platform lines.
		 * 
		 * Takes an Object of the following format: {
		 *   walls: {...},
		 *   platform_lines: {...}
		 * }
		 */
		public function updateGeo(geo:Object):void {
			const walls:Object = geo.walls;
			const platform_lines:Object = geo.platform_lines;
			
			const mg:MiddleGroundLayer = model.worldModel.location.mg;
			const gameRenderer:LocationRenderer = TSFrontController.instance.getMainView().gameRenderer;
			
			var tsid:String;
			
			// walls
			var wall:Wall;
			CONFIG::god var wallView:WallView;
			for (tsid in walls) {
				// get model
				wall = mg.getWallById(tsid);
				if (wall) {
					// update model
					wall.client::geo_was_updated = true;
					wall.updateFromAnonymous(walls[tsid]);
					CONFIG::god {
						// update view
						wallView = gameRenderer.getWallViewByTsid(tsid);
						if (wallView) wallView.syncRendererWithModel();
					}
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.error('missing wall tsid during geo_update: ' + tsid);
					}
				}
			}
			
			// platform_lines
			var platformLine:PlatformLine;
			CONFIG::god var platformLineView:PlatformLineView;
			for (tsid in platform_lines) {
				// get model
				platformLine = mg.getPlatformLineById(tsid);
				if (platformLine) {
					// update model
					platformLine.client::geo_was_updated = true;
					platformLine.updateFromAnonymous(platform_lines[tsid]);
					CONFIG::god {
						// update view
						platformLineView = gameRenderer.getPlatformLineViewByTsid(tsid);
						if (platformLineView) platformLineView.syncRendererWithModel();
					}
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.error('missing plat tsid during geo_update: ' + tsid);
					}
				}
			}
			
			// rebuild physics model
			// PERF: if we start moving things in realtime we'll need to do a
			// fast update of the quadtree instead of a full rebuild
			setUpGeoPhysicsForLocation();
		}
		
		/**
		 * Removes existing walls and platform lines.
		 * 
		 * Takes an Object of the following format: {
		 *   walls: [tsid, ...],
		 *   platform_lines: [tsid, ...]
		 * }
		 */
		public function removeGeo(geo:Object):void {
			const walls:Object = geo.walls;
			const platform_lines:Object = geo.platform_lines;
			
			const mg:MiddleGroundLayer = model.worldModel.location.mg;
			const gameRenderer:LocationRenderer = TSFrontController.instance.getMainView().gameRenderer;
			CONFIG::god const mgr:MiddleGroundRenderer = gameRenderer.locationView.middleGroundRenderer;
			
			var tsid:String;
			
			// walls
			var wall:Wall;
			for each (tsid in walls) {
				// get model
				wall = mg.getWallById(tsid);
				if (wall) {
					// remove model 
					mg.walls.splice(mg.walls.indexOf(wall), 1);
					CONFIG::god {
						// dirty view
						mgr.wallModelDirty = true;
					}
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.error('missing wall tsid during geo_remove: ' + tsid);
					}
				}
			}

			// platform_lines
			var platformLine:PlatformLine;
			for each (tsid in platform_lines) {
				// get model
				platformLine = mg.getPlatformLineById(tsid);
				if (platformLine) {
					// remove model
					mg.platform_lines.splice(mg.platform_lines.indexOf(platformLine), 1);
					CONFIG::god {
						// dirty view
						mgr.platformLineModelDirty = true;
					}
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.error('missing plat tsid during geo_remove: ' + tsid);
					}
				}
			}
			
			// rebuild physics model
			setUpGeoPhysicsForLocation();
		}
		
		/**
		 * This add  dynamic physics objects (things which are controlled by physics).
		 */
		private function addDynamicPhysicsObject(dynamicPhysicsObject:AvatarPhysicsObject):void {
			const ind:int = dynamicObjects.indexOf(dynamicPhysicsObject);
			if(ind == -1){
				dynamicObjects.push(dynamicPhysicsObject);
			}
		}
		
		private function removeDynamicsPhysicsObject(dynamicPhysicsObject:AvatarPhysicsObject):void {
			const ind:int = dynamicObjects.indexOf(dynamicPhysicsObject);
			if(ind != -1){
				dynamicObjects.splice(ind,1);
			}
		}
		
		public function doViewportQuery():void {
			// need some checking here to make sure we are good to go first?
			physicsModel.lastViewportQuery = doViewportCollisionTests(physicsModel.lastViewportQuery);
		}
		
		public function onGameLoop(ms_elapsed:int):void {
			const gameRenderer:LocationRenderer = TSFrontController.instance.getMainView().gameRenderer;
			if (!currentLocation) return;
			
			physicsModel.physics_start_time = getTimer();
			
			// this needs to run doViewportCollisionTests even if !isStarted, because isStarted==false when 
			// menus are up, etc, but we still want know what items/pcs are in viewport even then
			doViewportQuery();
			
			if (isStarted) {
				// do avatar collision queries
				var dpo:AvatarPhysicsObject;
				var apo:AvatarPhysicsObject;
				var query:PhysicsQuery;
				CONFIG::debugging {
					Console.trackPhysicsValue('PCont dynamicObjects.length', dynamicObjects.length);
				}
				
				for(var i:int=dynamicObjects.length-1; i>=0; --i){
					dpo = dynamicObjects[int(i)];
					apo = (dpo as AvatarPhysicsObject);
					if (apo) {
						if(apo.is_self) {
							avatarPhysicsHandler.applyPhysicsToSelf(apo, ms_elapsed, currentLocation);
							
							query = avatarPhysicsHandler.lastQuery;
							query.itemQuery.copyFrom(apo.collider.avatarCircle);
							query.doPCs = !flashVarModel.no_pc_collision;
							query.doItemstacks = !flashVarModel.no_item_collision;
							query = queryPCsByVector(query, physicsModel.lastViewportQuery.resultPCs);
							query = queryItemstacksByVector(query, physicsModel.lastViewportQuery.resultItemstacks);
							physicsModel.lastAvatarQuery = query;
							
							if (isCheckingForInteractionSprites) {
								gameRenderer.locationView.middleGroundRenderer._findInteractionSprites(apo);
							}
						} else {
							avatarPhysicsHandler.applyPhysicsToOther(apo, ms_elapsed, currentLocation);
						}
					}
				}
			}
		}
		
		private function queryItemstacksByDictionary(query:PhysicsQuery, itemstack_tsid_list:Dictionary):PhysicsQuery {
			if (!query.doItemstacks) return query;
			
			const x:Number = query.itemQuery.x;
			const y:Number = query.itemQuery.y;
			const queryRadius:Number = query.itemQuery.radius;
			
			const itemstacks:Dictionary = model.worldModel.itemstacks;
			
			var itemstack:Itemstack;
			var thing1:Number;
			var thing2:Number;
			var itemstackRadius:Number;
			// get all itemstacks in root of location
			// (not in bags, such as a cabinet or trophy case)
			for (var tsid:String in itemstack_tsid_list) {
				itemstack = (itemstacks[tsid] as Itemstack);
				itemstackRadius = itemstack.client::physRadius;
				if(itemstack && !itemstack.container_tsid && !isNaN(itemstackRadius)){
					// check whether the two circles (avatar and item) intersect
					thing1 = ((x - itemstack.x)*(x - itemstack.x) + (y - (itemstack.y - itemstack.client::physHeight*0.5))*(y - (itemstack.y - itemstack.client::physHeight*0.5)));
					thing2 = ((queryRadius + itemstackRadius) * (queryRadius + itemstackRadius));
					
					if (thing1 < thing2) {
						query.resultItemstacks.push(itemstack);
					}
				}
			}
			
			return query;
		}
		
		private function queryPCsByDictionary(query:PhysicsQuery, pc_tsid_list:Dictionary):PhysicsQuery {
			if (!query.doPCs) return query;
			
			const x:Number = query.itemQuery.x;
			const y:Number = query.itemQuery.y;
			const queryRadius:Number = query.itemQuery.radius;
			
			const pcs:Dictionary = worldModel.pcs;
			
			var pc:PC;
			var pcRadius:Number;
			for (var tsid:String in pc_tsid_list) {
				pc = (pcs[tsid] as PC);
				pcRadius = pc.client::physRadius;
				if(pc && !isNaN(pcRadius)){
					// check whether the two circles (avatar and pc) intersect
					if (((x - pc.x)*(x - pc.x) + (y - (pc.y - pc.client::physHeight*0.5))*(y - (pc.y - pc.client::physHeight*0.5))) < ((queryRadius + pcRadius) * (queryRadius + pcRadius))) {
						query.resultPCs.push(pc);
					}
				}
			}
			
			return query;
		}
		
		private function queryItemstacksByVector(query:PhysicsQuery, itemstacks:Vector.<Itemstack>=null):PhysicsQuery {
			if (!query.doItemstacks) return query;
			
			const x:Number = query.itemQuery.x;
			const y:Number = query.itemQuery.y;
			const queryRadius:Number = query.itemQuery.radius;
						
			var itemstack:Itemstack;
			var thing1:Number;
			var thing2:Number;
			var itemstackRadius:Number;
			for (var i:int=itemstacks.length-1; i>=0; --i) {
				itemstack = itemstacks[int(i)];
				itemstackRadius = itemstack.client::physRadius;
				if (!itemstack.container_tsid && !isNaN(itemstackRadius)){
					// check whether the two circles (avatar and item) intersect
					
					thing1 = ((x - itemstack.x)*(x - itemstack.x) + (y - (itemstack.y - itemstack.client::physHeight*0.5))*(y - (itemstack.y - itemstack.client::physHeight*0.5)));
					thing2 = ((queryRadius + itemstackRadius) * (queryRadius + itemstackRadius));
					
					if (thing1 < thing2) {
						query.resultItemstacks.push(itemstack);
					}
				}
			}
			
			return query;
		}
		
		/** Queries only PCs in physicsModel.lastViewportQuery, so run that first */
		private function queryPCsByVector(query:PhysicsQuery, pcs:Vector.<PC>):PhysicsQuery {
			if (!query.doPCs) return query;
			
			const x:Number = query.itemQuery.x;
			const y:Number = query.itemQuery.y;
			const queryRadius:Number = query.itemQuery.radius;
			
			var pc:PC;
			var pcRadius:Number;
			for (var i:int=pcs.length-1; i>=0; --i) {
				pc = pcs[int(i)];
				pcRadius = pc.client::physRadius;
				if (!isNaN(pcRadius)){
					// check whether the two circles (avatar and pc) intersect
					if (((x - pc.x)*(x - pc.x) + (y - (pc.y - pc.client::physHeight*0.5))*(y - (pc.y - pc.client::physHeight*0.5))) < ((queryRadius + pcRadius) * (queryRadius + pcRadius))) {
						query.resultPCs.push(pc);
					}
				}
			}
			
			return query;
		}
		
		private function doViewportCollisionTests(query:PhysicsQuery):PhysicsQuery {
			if (!currentLocation) return query;
			if (!flashVarModel.limited_rendering) return query;
			
			const rect:Rectangle = query.geometryQuery;
			
			// enlarge or shrink the viewport by the viewport scale and an extra scale factor
			const vpW:Number = (layoutModel.loc_vp_w / layoutModel.loc_vp_scale) * layoutModel.loc_vp_rect_collision_scale;
			const vpH:Number = (layoutModel.loc_vp_h / layoutModel.loc_vp_scale) * layoutModel.loc_vp_rect_collision_scale;
			
			// follow the viewport's location
			var xToUse:Number = (layoutModel.loc_cur_x - (vpW * 0.5));
			var yToUse:Number = (layoutModel.loc_cur_y - (vpH * 0.5));
			
			// keep the rect from leaving the window when the viewport
			// is at the edges (l/r/t/b) of the location
			xToUse = Math.min(Math.max(xToUse, currentLocation.l), (currentLocation.r - vpW));
			yToUse = Math.min(Math.max(yToUse, currentLocation.t), (currentLocation.b - vpH));
			
			// position the query rect
			rect.x = xToUse;
			rect.y = yToUse;
			
			// center the query circle on the query rect
			query.itemQuery.x = xToUse + (vpW * 0.5);
			query.itemQuery.y = yToUse + (vpH * 0.5);

			// only update the query circle radius when dimensions changed
			if ((rect.width != vpW) || (rect.height != vpH)) {
				// Math.sqrt is expensive!
				query.itemQuery.radius = (0.5 * Math.sqrt(vpW*vpW+vpH*vpH));
				rect.width = vpW;
				rect.height = vpH;
			}
			
			// do the viewport collision queries
			query.doItemstacks = !flashVarModel.no_render_stacks;
			query.doPCs = !flashVarModel.no_render_pcs;
			query.reset();
			query = queryPCsByDictionary(query, currentLocation.pc_tsid_list);
			return queryItemstacksByDictionary(query, currentLocation.itemstack_tsid_list);
		}
	}
}