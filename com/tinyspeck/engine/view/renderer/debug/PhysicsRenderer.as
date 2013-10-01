package com.tinyspeck.engine.view.renderer.debug
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.Deco;
	import com.tinyspeck.engine.data.location.Door;
	import com.tinyspeck.engine.data.location.Ladder;
	import com.tinyspeck.engine.data.location.Layer;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.location.MiddleGroundLayer;
	import com.tinyspeck.engine.data.location.SignPost;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.physics.avatar.AvatarPhysicsObject;
	import com.tinyspeck.engine.physics.colliders.ColliderLine;
	import com.tinyspeck.engine.physics.data.PhysicsQuery;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.view.geo.DoorView;
	import com.tinyspeck.engine.view.geo.LadderView;
	import com.tinyspeck.engine.view.geo.SignpostView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.renderer.LayerRenderer;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;

	/**
	 * Activated by pressing Q+E.
	 * 
	 * Z toggles between avatar and viewport queries;
	 */
	// * CONTROL toggles between showing itemstacks and decos.
	public class PhysicsRenderer extends Sprite
	{
		/* singleton boilerplate */
		public static const instance:PhysicsRenderer = new PhysicsRenderer();
		
		private var testSprite:Sprite;
		private var model:TSModelLocator;
		private var drawDecos:Boolean;
		private var drawAvatar:Boolean;
				
		public function PhysicsRenderer()
		{
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			visible = false;
			model = TSModelLocator.instance;
			
			testSprite = new Sprite();
			addChild(testSprite);
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		private function onAddedToStage(event:Event):void
		{
			StageBeacon.key_down_sig.add(onKeyDown);
		}
		
		private function onKeyDown(event:KeyboardEvent):void
		{
			//Responds to "e pressed while q is down";
			if(event.keyCode == Keyboard.E && KeyBeacon.instance.pressed(Keyboard.Q)){
				visible = !visible;
			} else if (event.keyCode == Keyboard.D) {
				// disabling for now, not too useful
				//drawDecos = !drawDecos;
			} else if (event.keyCode == Keyboard.Z) {
				drawAvatar = !drawAvatar;
			}
		}
		
		public function setSize(x:Number, y:Number):void {
			graphics.clear();
			graphics.beginFill(0x666666, 0.5);
			graphics.drawRect(0, 0, x, y);
			graphics.endFill();
			testSprite.x = x/2;
			testSprite.y = y/2;
			scrollRect = new Rectangle(0,0,x,y);
		}
		
		public function onEnterFrame(ms_elapsed:Number):void {
			if (!visible) return;
			
			var tsid:String;
			var physRect:Rectangle;

			const renderer:LocationRenderer = TSFrontController.instance.getMainView().gameRenderer;
			const top_allowance:int = model.physicsModel.location_top_allowance;
			const location:Location = model.worldModel.location;
			const lm:LayoutModel = model.layoutModel;
			const lq:PhysicsQuery = (drawAvatar ? model.physicsModel.lastAvatarQuery : model.physicsModel.lastViewportQuery);
			
			testSprite.scaleX = testSprite.scaleY = (drawAvatar ? 0.5 : 0.2);
			testSprite.scaleX *= lm.loc_vp_scaleX_multiplier;
			testSprite.scaleY *= lm.loc_vp_scaleY_multiplier;
			
			const apo:AvatarPhysicsObject = model.worldModel.pc.apo;
			const curX:Number = lm.loc_cur_x;
			const curY:Number = lm.loc_cur_y;
			
			const g:Graphics = testSprite.graphics;
			g.clear();
			
			// draw location boundaries
			g.lineStyle(0, 0, 0);
			g.beginFill(0xFFFFFF, 0.2);
			g.drawRect(location.l-curX, location.t-curY, location.client::w, location.client::h);
			
			// draw viewport
			const vpW:Number = (lm.loc_vp_w / lm.loc_vp_scale);
			const vpH:Number = (lm.loc_vp_h / lm.loc_vp_scale);
			g.lineStyle(0, 0, 0);
			g.beginFill(0xFFFFFF, 0.3);
			g.drawRect(lm.loc_cur_x - vpW*0.5 - curX, lm.loc_cur_y - vpH*0.5 - curY, vpW, vpH);
			g.endFill();

			if (drawDecos) {
				const layers:Vector.<Layer> = location.layers;
				for each (var layer:Layer in layers) {
					if (layer.is_hidden) continue;
					
					var decos:Vector.<Deco> = layer.decos;
					var layerRenderer:LayerRenderer = renderer.getLayerRendererByTSID(layer.tsid);
					var layerX:int = layerRenderer.x;
					var layerY:int = layerRenderer.y;
					for(var n:int = 0; n<decos.length; n++){
						var deco:Deco = decos[int(n)];
						if(lq.resultDecos.indexOf(deco) != -1){
							g.lineStyle(2,0x008000, 0.5, true);
							g.beginFill(0x00FF00, 0.3);
						}else{
							g.lineStyle(2,0x800000, 0.3, true);
							g.beginFill(0xFF0000, 0.1);
						}
						if(deco.w < 0){
							g.lineStyle(0,0x0000FF,1, true);
						}
						
						var bm:Point;
						if (layer is MiddleGroundLayer) {
							bm = new Point((deco.x-curX), (deco.y-curY));
						} else {
							// account for parallax
							bm = new Point(layerX+(deco.x-curX), layerY+(deco.y-curY));
						}
						
						var tl:Point = new Point((bm.x-deco.w/2), (bm.y-deco.h));
						var tr:Point = new Point((tl.x+deco.w), tl.y);
						var br:Point = new Point(tr.x, bm.y);
						var bl:Point = new Point(tl.x, bm.y);
						
						// apply rotation
						if (deco.r) {
							//todo rotation is about bm not middle, so a circle wont be enough, must be rotated first to get x y
							var r:Number = (deco.r*Math.PI/180);
							tl = MathUtil.rotatePointByRadians(tl, bm, r);
							tr = MathUtil.rotatePointByRadians(tr, bm, r);
							br = MathUtil.rotatePointByRadians(br, bm, r);
							bl = MathUtil.rotatePointByRadians(bl, bm, r);
						}
						
						// draw it
						g.moveTo(tl.x, tl.y);
						g.lineTo(tr.x, tr.y);
						g.lineTo(br.x, br.y);
						g.lineTo(bl.x, bl.y);
					}
				}
			}
			
			if(location.mg){
				var mg:MiddleGroundLayer = location.mg;
				if(mg.client::colliderLines){
					var colliderLines:Vector.<ColliderLine> = mg.client::colliderLines;
					var colliderLine:ColliderLine;
					for(var j:int = 0; j< colliderLines.length; j++){
						colliderLine = colliderLines[int(j)];
						physRect = colliderLine.client::physRect;
						if(physRect){
							if(lq.resultColliderLines.indexOf(colliderLine) != -1){
								g.lineStyle(4, 0x008000, 0.75, true);
							}else{
								g.lineStyle(4, 0x222222, 0.75, true);
							}
							if(physRect.width < 0){
								g.lineStyle(2, 0x0000FF, 1, true);
							}
							if (colliderLine.isInfinite) {
								g.moveTo(
									MathUtil.clamp(location.l, location.r, colliderLine.x1) - curX,
									MathUtil.clamp(location.t - top_allowance, location.b, colliderLine.y1) - curY);
								g.lineTo(
									MathUtil.clamp(location.l, location.r, colliderLine.x2) - curX,
									MathUtil.clamp(location.t - top_allowance, location.b, colliderLine.y2) - curY);
							} else {
								g.moveTo(colliderLine.x1-curX, colliderLine.y1-curY);
								g.lineTo(colliderLine.x2-curX, colliderLine.y2-curY);
								//g.lineStyle(0, 0x666666, 0.6, true);
								//g.drawRect(physRect.x-curX, physRect.y-curY, physRect.width, physRect.height);
							}
						}
					}
				}
				
				var ladders:Vector.<Ladder> = mg.ladders;
				var ladder:Ladder;
				for(var k:int = 0; k< ladders.length; k++){
					ladder = ladders[int(k)];
					physRect = ladder.client::physRect;
					if(physRect){
						var lv:LadderView = renderer.getLadderViewByTsid(ladder.tsid);
						if(apo._interaction_spV.indexOf(lv) != -1){
							// if we're able to interact with it
							g.lineStyle(0, 0x008000, 1, true);
							g.beginFill(0x00FF00, 0.5);
						} else if(lq.resultLadders.indexOf(ladder) != -1){
							// if we thought we might be able to interact with it but actually cannot
							g.lineStyle(0, 0xC69035, 1, true);
							g.beginFill(0xFAB644, 0.5);
						}else{
							g.lineStyle(0, 0x222222, 0.5, true);
							g.beginFill(0x222222, 0.2);
						}
						g.drawRect(physRect.x-curX, physRect.y-curY, physRect.width, physRect.height);
					}
				}
				
				var signPosts:Vector.<SignPost> = mg.signposts;
				var signPost:SignPost;
				for(var l:int = 0; l< signPosts.length; l++){
					signPost = signPosts[int(l)];
					physRect = signPost.client::physRect;
					if(physRect){
						var sv:SignpostView = renderer.getSignpostViewByTsid(signPost.tsid);
						if(apo._interaction_spV.indexOf(sv) != -1){
							// if we're able to interact with it
							g.lineStyle(0, 0x008000, 1, true);
							g.beginFill(0x00FF00, 0.5);
						} else if(lq.resultSignPosts.indexOf(signPost) != -1){
							// if we thought we might be able to interact with it but actually cannot
							g.lineStyle(0, 0xC69035, 1, true);
							g.beginFill(0xFAB644, 0.5);
						}else{
							g.lineStyle(0, 0x222222, 0.5, true);
							g.beginFill(0x222222, 0.2);
						}
						g.drawRect(physRect.x-curX, physRect.y-curY, physRect.width, physRect.height);
					}
				}
				
				var doors:Vector.<Door> = mg.doors;
				var door:Door;
				for(var m:int = 0; m< doors.length; m++){
					door = doors[int(m)];
					physRect = door.client::physRect;
					if(physRect){
						var dv:DoorView = renderer.getDoorViewByTsid(door.tsid);
						if(apo._interaction_spV.indexOf(dv) != -1){
							// if we're able to interact with it
							g.lineStyle(0, 0x008000, 1, true);
							g.beginFill(0x00FF00, 0.5);
						} else if(lq.resultDoors.indexOf(door) != -1){
							// if we thought we might be able to interact with it but actually cannot
							g.lineStyle(0, 0xC69035, 1, true);
							g.beginFill(0xFAB644, 0.5);
						}else{
							g.lineStyle(0, 0x222222, 0.5, true);
							g.beginFill(0x222222, 0.2);
						}
						g.drawRect(physRect.x-curX, physRect.y-curY, physRect.width, physRect.height);
					}
				}
			}

			// draw pcs and itemstacks
			if (!drawDecos) {
				var itemstack:Itemstack;
				for (tsid in model.worldModel.location.itemstack_tsid_list){
					itemstack = (model.worldModel.itemstacks[tsid] as Itemstack);
					if(itemstack && !itemstack.container_tsid && !isNaN(itemstack.client::physRadius)){
						if (drawAvatar) {
							var liv:LocationItemstackView = renderer.getItemstackViewByTsid(itemstack.tsid);
							if(apo._interaction_spV.indexOf(liv) != -1){
								// if we're able to interact with it
								
								// draw the bounding rect
								g.lineStyle(0, 0x222222, 0.5, true);
								g.drawRect((itemstack.x-itemstack.client::physWidth*0.5)-curX, (itemstack.y-itemstack.client::physHeight)-curY, itemstack.client::physWidth, itemstack.client::physHeight);
								
								g.lineStyle(0, 0x008000, 1, true);
								g.beginFill(0x00FF00, 0.5);
							} else if(lq.resultItemstacks.indexOf(itemstack) != -1) {
								// if we thought we might be able to interact with it but actually cannot
								
								// draw the bounding rect
								g.lineStyle(0, 0x222222, 0.5, true);
								g.drawRect((itemstack.x-itemstack.client::physWidth*0.5)-curX, (itemstack.y-itemstack.client::physHeight)-curY, itemstack.client::physWidth, itemstack.client::physHeight);
								
								g.lineStyle(0, 0xC69035, 1, true);
								g.beginFill(0xFAB644, 0.5);
							}else{
								// if there's no chance we can interact with this
								g.lineStyle(0, 0x222222, 0.5, true);
								g.beginFill(0x222222, 0.2);
							}
							// draw the encompassing circle
							g.drawCircle(itemstack.x-curX, (itemstack.y-itemstack.client::physHeight*0.5)-curY, itemstack.client::physRadius);
							g.endFill();
						} else {
							if(lq.resultItemstacks.indexOf(itemstack) != -1){
								g.lineStyle(0, 0x008000, 1, true);
								g.beginFill(0x00FF00, 0.5);
							}else{
								g.lineStyle(0, 0x222222, 0.2, true);
								g.beginFill(0x222222, 0.1);
							}
							// draw the encompassing circle
							g.drawCircle(itemstack.x-curX, (itemstack.y-itemstack.client::physHeight*0.5)-curY, itemstack.client::physRadius);
						}
					}
				}
				
				// draw other pcs
				var pc:PC;
				for (tsid in model.worldModel.location.pc_tsid_list){
					pc = model.worldModel.getPCByTsid(tsid);
					if(pc && !isNaN(pc.client::physRadius)){
						if(lq.resultPCs.indexOf(pc) != -1){
							g.lineStyle(2,0x008000, 1, true);
							g.beginFill(0x00FF00, 0.5);
						}else{
							g.lineStyle(2,0x800000, 0.3, true);
							g.beginFill(0xFF0000, 0.1);
						}
						
						// draw the exact dimensions
						g.drawRect((pc.x-pc.client::physWidth*0.5)-curX, (pc.y-pc.client::physHeight)-curY, pc.client::physWidth, pc.client::physHeight);
						g.endFill();
						
						if(lq.resultPCs.indexOf(pc) != -1){
							g.lineStyle(0, 0, 0, true);
							g.beginFill(0x00FF00, 0.5);
						}else{
							g.lineStyle(0, 0, 0, true);
							g.beginFill(0xFF0000, 0.1);
						}
						
						// draw the encompassing circle
						g.drawCircle(pc.x-curX, (pc.y-pc.client::physHeight*0.5)-curY, pc.client::physRadius);
					}
				}
			}
			
			const queryRect:Rectangle = lq.geometryQuery;

			// draw the query circle
			g.lineStyle(2, 0xD5D5D5, 0.8, true);
			g.beginFill(0xD5D5D5, 0.4);
			g.drawCircle((lq.itemQuery.x - curX), (lq.itemQuery.y - curY), lq.itemQuery.radius);
			g.endFill();
			
			// draw the query rect
			g.lineStyle(2, 0xD5D5D5, 0.8, true);
			g.beginFill(0xD5D5D5, 0.4);
			g.drawRect(queryRect.x-curX, queryRect.y-curY, queryRect.width, queryRect.height);
			g.endFill();
			
			// draw the avatar
			g.lineStyle();
			// head
			g.beginFill(0x0099F6, 1);
			g.drawCircle(apo.collider.headCircle.x-curX, apo.collider.headCircle.y-curY, apo.collider.headCircle.radius);
			g.endFill();
			// foot
			g.beginFill(0x0099F6, 1);
			g.drawCircle(apo.collider.footCircle.x-curX, apo.collider.footCircle.y-curY, apo.collider.footCircle.radius);
			g.endFill();
			// body
			g.beginFill(0x0099F6, 1);
			g.drawRect(apo.collider.headCircle.x-curX-apo.collider.headCircle.radius, apo.collider.headCircle.y-curY, 2*apo.collider.headCircle.radius, apo.collider.footCircle.y-apo.collider.headCircle.y);
			g.endFill();
		}
	}
}