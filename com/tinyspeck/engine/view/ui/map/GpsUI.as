package com.tinyspeck.engine.view.ui.map
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.AbstractPositionableLocationEntity;
	import com.tinyspeck.engine.data.location.Hub;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.map.Street;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.net.NetOutgoingGetPathToLocationVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.AvatarView;
	import com.tinyspeck.engine.view.gameoverlay.maps.MiniMapView;
	import com.tinyspeck.engine.view.geo.SignpostView;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	public class GpsUI extends TSSpriteWithModel implements IMoveListener, IRefreshListener
	{
		private static const TOP_PADD:uint = 20; //covers the expand button and some more
		private static const PADD:int = 5;
		private static const GRAPHIC_PADD:int = 4;
		private static const CORNER_RADIUS:Number = 10;
		private static const MIN_H:uint = 42;
		private static const TARGET_PROXIMITY:uint = 150; //how many px before we auto show the hover state
		private static const TIP_PADDING:int = 5;
		
		private var gps_arrow:GpsArrow = new GpsArrow();
		private var avatar_view:AvatarView;
		private var thing:AbstractPositionableLocationEntity;
		
		private var dest_holder:Sprite = new Sprite();
		private var close_holder:Sprite = new Sprite();
		
		private var dest_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private const you_pt:Point = new Point();
		private const thing_pt:Point = new Point();
		
		private var tip_txt:String;
		
		private var is_built:Boolean;
		private var is_off_path:Boolean;
		private var has_arrived:Boolean;
		private var is_hovering:Boolean;
		
		public function GpsUI(){}
		
		private function buildBase():void {
			var g:Graphics;
			
			//indicator
			gps_arrow.addEventListener(MouseEvent.ROLL_OVER, onArrowMouse, false, 0, true);
			gps_arrow.addEventListener(MouseEvent.ROLL_OUT, onArrowMouse, false, 0, true);
			gps_arrow.addEventListener(MouseEvent.CLICK, onArrowClick, false, 0, true);
			gps_arrow.x = int(gps_arrow.width/2 + PADD + 1);
			
			//destination
			TFUtil.prepTF(dest_tf);
			dest_tf.wordWrap = false;
			dest_tf.filters = StaticFilters.copyFilterArrayFromObject({alpha:.7}, StaticFilters.white1px90Degrees_DropShadowA);
			dest_holder.addChild(dest_tf);
			addChild(dest_holder);
			
			//close
			const close_DO:DisplayObject = new AssetManager.instance.assets.close_gps();
			close_holder.addChild(close_DO);
			close_holder.y = PADD;
			close_holder.alpha = .25;
			close_holder.useHandCursor = close_holder.buttonMode = true;
			close_holder.addEventListener(MouseEvent.CLICK, onCloseClick, false, 0, true);
			addChild(close_holder);
			
			is_built = true;
		}
		
		private function onArrowMouse(event:MouseEvent):void {
			if(has_arrived) return;
			is_hovering = event.type == MouseEvent.ROLL_OVER;
			gps_arrow.showState(is_hovering);
		}
		
		private function onArrowClick(event:MouseEvent):void {			
			//we have the next location to go to
			if (model.stateModel.loc_path_next_loc_tsid){
				if (model.stateModel.loc_path_signpost) {
					const sp_view:SignpostView = TSFrontController.instance.getMainView().gameRenderer.getSignpostViewByTsid(model.stateModel.loc_path_signpost.tsid);
					if (sp_view) {
						model.stateModel.interaction_sign = sp_view.getSignThatLinksToLocTsid(model.stateModel.loc_path_next_loc_tsid);
					}
					TSFrontController.instance.startUserInitiatedPath(model.stateModel.loc_path_signpost.tsid);
				} else if (model.stateModel.loc_path_door) {
					TSFrontController.instance.startUserInitiatedPath(model.stateModel.loc_path_door.tsid);
				}
			} else if (model.stateModel.loc_path_at_dest) {
				//close up shop
				onCloseClick(event);
			}
		}
		
		public function show():void {
			if(!is_built) buildBase();
			is_hovering = false;
			
			//show where to go!
			setDestinationText();
			
			draw();
			
			avatar_view = TSFrontController.instance.getMainView().gameRenderer.getAvatarView();			
			if (!avatar_view) {
				;
				CONFIG::debugging {
					Console.error('wtf no avatar_view???');
				}
			}
			
			if (avatar_view) {
				//show this sucker
				gps_arrow.show();
				addChild(gps_arrow);
				updateArrow();
			}
			
			TSFrontController.instance.registerMoveListener(this);
			TSFrontController.instance.registerRefreshListener(this);
		}
		
		public function refresh():void {
			//place this where it should go
			const lm:LayoutModel = model.layoutModel;
			x = int(MiniMapView.instance.w - (close_holder.x + close_holder.width));
			y = lm.loc_vp_h - height;
		}
		
		public function updateArrow():void {			
			if (!parent) return;
			if (!gps_arrow.parent) return;
			
			thing = (model.stateModel.loc_path_signpost || model.stateModel.loc_path_door) as AbstractPositionableLocationEntity;
			if (thing) {
				thing_pt.x = thing.x;
				thing_pt.y = thing.y;
				you_pt.x = avatar_view.x;
				you_pt.y = avatar_view.y;
				
				gps_arrow.rotation = (Math.atan2(thing.y-you_pt.y, thing.x-you_pt.x)*180/Math.PI);
				
				if (Math.abs(Point.distance(you_pt, thing_pt)) < TARGET_PROXIMITY && !is_hovering) { //we're on top of it!
					//force the "close" to show
					gps_arrow.showState(false, false, true);
				} else if(!is_hovering) {
					//hide the tip
					hideTip();
				}
				
				//show the to: and next:
				setDestinationText();
			} else if (model.stateModel.loc_path_at_dest) {
				//we've made it!
				gps_arrow.rotation = 0;
				//gps_hand.scaleY = 1;
				gps_arrow.showState(false, true);
				
				//set the destination text
				setDestinationText('<span class="gps_arrived">You Have Arrived!</span>');
			} else if (is_off_path) {
				//don't show the hand anymore
				gps_arrow.hide();
				hideTip();
			}
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
			TSFrontController.instance.removeMoveListener(this);
			TSFrontController.instance.unRegisterRefreshListener(this);
			gps_arrow.hide();
		}
		
		private function setDestinationText(text_override:String = ''):void {
			const dest_loc:Location = model.worldModel.getLocationByTsid(model.stateModel.loc_pathA[model.stateModel.loc_pathA.length-1]);
			const dest_name:String = (dest_loc) ? dest_loc.label : model.stateModel.loc_pathA[model.stateModel.loc_pathA.length-1];
			
			//destination text
			var dest_txt:String = '<p class="gps_dest">';
			if(!text_override){
				dest_txt += '<span class="gps_dest_label">To: </span>';
				if(dest_loc) dest_txt += '<a href="event:'+TSLinkedTextField.LINK_LOCATION+'|'+dest_loc.hub_id+'#'+dest_loc.tsid+'">';
				dest_txt += dest_name;
				if(dest_loc) dest_txt += '</a>';
				
				//get the next location
				dest_txt += getNextText();
			}
			else {
				dest_txt += text_override;
			}
			dest_txt += '</p>';
			dest_tf.htmlText = dest_txt;
			
			has_arrived = model.stateModel.loc_path_at_dest;
			is_off_path = !model.stateModel.loc_path_active;
			
			draw();
			refresh();
		}
		
		private function draw():void {
			if(!is_built || !parent) return;
			
			dest_tf.x = !is_off_path ? int(gps_arrow.x + gps_arrow.width/2 + PADD) : PADD*2;
			
			//draw the bg
			const box_w:int = dest_tf.x + dest_tf.width + close_holder.width + PADD;
			const box_h:int = Math.max(dest_tf.height+PADD + (PADD-2), MIN_H);
			var g:Graphics = dest_holder.graphics;
			g.clear();
			g.beginFill(model.layoutModel.bg_color);
			g.drawRoundRectComplex(0, 0, box_w, box_h, CORNER_RADIUS, 0, 0, 0);
			g.endFill();
			
			//left curve
			g.beginFill(model.layoutModel.bg_color);
			g.moveTo(-CORNER_RADIUS, box_h);
			g.curveTo(0,box_h, 0,box_h-CORNER_RADIUS);
			g.lineTo(0, box_h);
			g.lineTo(-CORNER_RADIUS, box_h);
			g.endFill();
			
			//right curve
			g.beginFill(model.layoutModel.bg_color);
			g.moveTo(box_w-CORNER_RADIUS, 0);
			g.curveTo(box_w,0, box_w,-CORNER_RADIUS);
			g.lineTo(box_w, 0);
			g.lineTo(box_w-CORNER_RADIUS, 0);
			g.endFill();
			
			//close
			close_holder.x = box_w-close_holder.width;
			
			dest_tf.y = int(box_h/2 - dest_tf.height/2 + 2);
			
			gps_arrow.y = int(box_h/2);
		}
		
		private function getNextText():String {			
			//set our destination text as our next place
			const next_loc:Location = model.worldModel.getLocationByTsid(model.stateModel.loc_path_next_loc_tsid);
			var next_txt:String = '<br><span class="gps_dest_next">';
			if (next_loc) {
				next_txt += 'Next: ';
				
				//set the next place we need to go
				next_txt += '<a href="event:'+TSLinkedTextField.LINK_LOCATION+'|'+next_loc.hub_id+'#'+next_loc.tsid+'">';
				next_txt += next_loc.label;
				next_txt += '</a>';
			} 
			else {
				next_txt += '<span class="gps_off_path">';
				next_txt += '<a href="event:'+TSLinkedTextField.LINK_BACK_TO_WORLD+'">';
				next_txt += 'Return to world';
				next_txt += '</a>';
				next_txt += ' for directions';
				next_txt += '</span>';
			}
			
			next_txt += '</span>';
			
			return next_txt;
		}
		
		private function hideTip(event:MouseEvent = null):void {
			if(is_hovering) return;
			gps_arrow.showState(false);
		}
		
		private function onCloseClick(event:MouseEvent = null):void {
			StageBeacon.stage.focus = StageBeacon.stage;
			TSFrontController.instance.endLocationPath();
			has_arrived = false;
		}
		
		override public function get height():Number {
			return dest_holder.height - CORNER_RADIUS;
		}
		
		////////////////////////////////////////////////////////////////////////////////
		//////// IMoveListener /////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		public function moveLocationHasChanged():void {}
		public function moveLocationAssetsAreReady():void {}
		public function moveMoveEnded():void {
			var safe_to_update:Boolean = true;
			var street:Street;
			const loc:Location = model.worldModel.location;
			const hub:Hub = model.worldModel.getHubByTsid(loc.hub_id);
			if(hub && hub.map_data){
				street = hub.map_data.getStreetByTsid(model.worldModel.location.tsid);
				if((street && street.not_a_destination) || (street && street.invisible_to_outsiders)){
					//we can't update the path
					safe_to_update = false;
				}
			}
			
			//if they have a path, let's add some data to the benchmark
			if(model.stateModel.current_path){
				Benchmark.addCheck(
					'## MAP PATH DATA ##'+
					' mini_map_visible: '+MiniMapView.instance.visible+
					' safe_to_update: '+safe_to_update+
					' no_pathing_out: '+loc.no_pathing_out+
					' is_street_in_path: '+model.stateModel.current_path.getSegmentByTsid(loc.tsid)+
					' full_path:'+model.stateModel.current_path+
					'## MAP PATH DATA END ##'
				);
			}
			
			//if we've moved, and we've left the path, go ask the server for a new one!
			if(model.stateModel.current_path && !loc.no_pathing_out && safe_to_update && !model.stateModel.current_path.getSegmentByTsid(loc.tsid)){
				//check to make sure the mini map is showing
				if(MiniMapView.instance.visible){
					//check to see if the parent street was the destination, if so, don't get map data again
					if(loc.mapInfo && loc.mapInfo.showStreet != model.stateModel.current_path.destination_tsid){
						TSFrontController.instance.genericSend(new NetOutgoingGetPathToLocationVO(model.stateModel.current_path.destination_tsid),
							function(rm:NetResponseMessageVO):void {
								if (!rm.payload.path_info || !rm.payload.path_info.path || rm.payload.path_info.path.length < 2) {
									model.activityModel.growl_message = 'ERROR: path did not contain two elements';
									return;
								}
							},
							function(rm:NetResponseMessageVO):void {					
								var txt:String = 'Creating path failed';
								if (rm.payload.error && rm.payload.error.msg) {
									txt+= ': '+rm.payload.error.msg;
								} else {
									txt+= '.';
								}
								model.activityModel.growl_message = txt;
							}
						);
					}
				}
				else {
					CONFIG::debugging {
						Console.error('Mini map not visible, not updating path!');
					}
				}
			}
		}
		
		public function moveMoveStarted():void {
			//if we are starting to move and we've already got to our destination, tell the server we are done
			if(has_arrived) onCloseClick();
		}
	}
}