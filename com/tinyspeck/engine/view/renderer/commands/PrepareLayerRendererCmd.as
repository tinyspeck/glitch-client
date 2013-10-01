package com.tinyspeck.engine.view.renderer.commands
{
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.core.control.ICommand;
	import com.tinyspeck.engine.data.location.Box;
	import com.tinyspeck.engine.data.location.Door;
	import com.tinyspeck.engine.data.location.Ladder;
	import com.tinyspeck.engine.data.location.MiddleGroundLayer;
	import com.tinyspeck.engine.data.location.PlatformLine;
	import com.tinyspeck.engine.data.location.SignPost;
	import com.tinyspeck.engine.data.location.Target;
	import com.tinyspeck.engine.data.location.Wall;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.view.geo.BoxView;
	import com.tinyspeck.engine.view.geo.DoorView;
	import com.tinyspeck.engine.view.geo.LadderView;
	import com.tinyspeck.engine.view.geo.SignpostView;
	import com.tinyspeck.engine.view.geo.TargetView;
	import com.tinyspeck.engine.view.renderer.LayerRenderer;
	import com.tinyspeck.engine.view.renderer.MiddleGroundRenderer;
	
	CONFIG::god { import com.tinyspeck.engine.view.geo.PlatformLineView; }
	CONFIG::god { import com.tinyspeck.engine.view.geo.WallView; }
	
	/** 
	 * This Command 'prepares' a LayerRenderer by creating different sprite types 
	 * and adding them to the specified LayerRenderer.  
	 */ 
	public class PrepareLayerRendererCmd implements ICommand {
		
		private var layerRenderer:LayerRenderer;
		
		private var model:TSModelLocator;
		private var flashVarModel:FlashVarModel;
		private var worldModel:WorldModel;
		
		public function PrepareLayerRendererCmd(layerRenderer:LayerRenderer) {
			this.layerRenderer = layerRenderer;
			
			model = TSModelLocator.instance;
			flashVarModel = model.flashVarModel;
			worldModel = model.worldModel;
		}
		
		public function execute():void {
			prepareLayerRenderer(layerRenderer);
		}
		
		private function prepareLayerRenderer(layerRenderer:LayerRenderer):void {
			if(layerRenderer.layerData is MiddleGroundLayer) {
				createGeometryElementsForMG(MiddleGroundRenderer(layerRenderer));
			} else {
				layerRenderer.mouseEnabled = false;
				layerRenderer.mouseChildren = false;
			}
		}
		
		private function createGeometryElementsForMG(layerRenderer:MiddleGroundRenderer):void {
			const layer:MiddleGroundLayer = (layerRenderer.layerData as MiddleGroundLayer);
			createLaddersForMG(layerRenderer, layer.ladders);
			createDoorsForMG(layerRenderer, layer.doors);
			createSignpostsForMG(layerRenderer, layer.signposts);
			CONFIG::god {
				createPlatformLinesForMG(layerRenderer, layer.platform_lines);
				createWallsForMG(layerRenderer, layer.walls);
				createTargetsForMG(layerRenderer, layer.targets);
				createBoxesForMG(layerRenderer, layer.boxes);
				if (!model.stateModel.hide_platforms) {
					layerRenderer.showPlatformLinesEtc();
				}
			}
		}
		
		private function createSignpostsForMG(layerRenderer:MiddleGroundRenderer, vec:Vector.<SignPost>):void {
			const loc_tsid:String = worldModel.location.tsid;
			const mg:MiddleGroundLayer = worldModel.location.mg;
			
			var renderer:SignpostView;
			var signpost:SignPost;
			for (var i:int=0; i<vec.length; i++) {
				signpost = vec[int(i)];
				renderer = new SignpostView(signpost, loc_tsid);
				
				/*
				//FOR TESTING DIRTY CHANGES on SIGNPOSTS ON LEFTMOST SIGNPOST IN OBAIX MAINSTREET ON DEV 
				var non_hidden_connections_count:int = 0;
				for (var m:int=0; m<signpost.connects.length; m++) {
				if (signpost.connects[m].hidden) continue;
				non_hidden_connections_count++;
				}
				
				if (non_hidden_connections_count == 2 && !ts) {
				var ts:SignPost = signpost;
				ts.connects[0].hidden = true;
				ts.connects[1].hidden = true;
				
				setTimeout(function():void {
				ts.connects[0].hidden = false;
				TSFrontController.instance.refreshSignPostInAllViews(ts);
				}, 10000)
				setTimeout(function():void {
				ts.connects[1].hidden = false;
				TSFrontController.instance.refreshSignPostInAllViews(ts);
				}, 20000)
				} */
				
				LocationCommands.applyFiltersToView(mg, renderer);
				layerRenderer.addSignPostView(renderer, signpost);
			}
		}
		
		CONFIG::god private function createPlatformLinesForMG(layerRenderer:MiddleGroundRenderer, vec:Vector.<PlatformLine>):void {
			var renderer:PlatformLineView;
			var platformLine:PlatformLine;
			for (var i:int=0; i<vec.length; i++) {
				platformLine = vec[int(i)];
				
				renderer = new PlatformLineView(platformLine);
				renderer.visible = !model.stateModel.hide_platforms;
				
				layerRenderer.addPlatformLineView(renderer);
			}
		}
		
		CONFIG::god private function createTargetsForMG(layerRenderer:MiddleGroundRenderer, vec:Vector.<Target>):void {
			var renderer:TargetView;
			var target:Target;
			for (var i:int=0; i<vec.length; i++) {
				target = vec[int(i)];
				renderer = new TargetView(target);
				if (model.stateModel.hide_targets) renderer.visible = false;
				
				layerRenderer.addTargetView(renderer);
			}
		}
		
		CONFIG::god private function createBoxesForMG(layerRenderer:MiddleGroundRenderer, vec:Vector.<Box>):void {
			var renderer:BoxView;
			var box:Box;
			for (var i:int=0; i<vec.length; i++) {
				box = vec[int(i)];
				renderer = new BoxView(box);
				if (model.stateModel.hide_boxes) renderer.visible = false;
				layerRenderer.addBoxView(renderer);
			}
		}
		
		CONFIG::god private function createWallsForMG(layerRenderer:MiddleGroundRenderer, vec:Vector.<Wall>):void {
			const loc_tsid:String = worldModel.location.tsid;
			const mg:MiddleGroundLayer = worldModel.location.mg;
			
			var renderer:WallView;
			var wall:Wall;
			for (var i:int=0; i<vec.length; i++) {
				wall = vec[int(i)];
				renderer = new WallView(wall, loc_tsid);
				LocationCommands.applyFiltersToView(mg, renderer);
				renderer.visible = !model.stateModel.hide_platforms;
				layerRenderer.addWallView(renderer);
			}
		}
		
		private function createLaddersForMG(layerRenderer:MiddleGroundRenderer, vec:Vector.<Ladder>):void {
			const loc_tsid:String = worldModel.location.tsid;
			const mg:MiddleGroundLayer = worldModel.location.mg;
			
			var renderer:LadderView;
			var ladder:Ladder;
			for (var i:int=0; i<vec.length; i++) {
				ladder = vec[int(i)];
				
				renderer = new LadderView(ladder, loc_tsid);
				LocationCommands.applyFiltersToView(mg, renderer);
				
				layerRenderer.addLadderView(renderer, ladder);
			}
		}
		
		private function createDoorsForMG(layerRenderer:MiddleGroundRenderer, vec:Vector.<Door>):void {
			const loc_tsid:String = worldModel.location.tsid;
			const mg:MiddleGroundLayer = worldModel.location.mg;
			
			var renderer:DoorView;
			var door:Door;
			for (var i:int=0; i<vec.length; i++) {
				door = vec[int(i)];
				renderer = new DoorView(door, loc_tsid);
				/*
				// for testing what happens door_change messages come in
				if (door.tsid == 'door_1') {
				var door_to_change:Door = door;
				door.connect.hidden = true;
				setTimeout(function():void {
				door_to_change.connect.hidden = false;
				TSFrontController.instance.refreshDoorInAllViews(door_to_change);
				}, 10000)
				}*/
				
				LocationCommands.applyFiltersToView(mg, renderer);
				layerRenderer.addDoorView(renderer, door);
			}
		}
	}
}