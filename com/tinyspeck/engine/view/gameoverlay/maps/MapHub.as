package com.tinyspeck.engine.view.gameoverlay.maps {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.Hub;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.location.LocationConnection;
	import com.tinyspeck.engine.data.location.SignPost;
	import com.tinyspeck.engine.data.map.MapData;
	import com.tinyspeck.engine.data.map.MapPathSegment;
	import com.tinyspeck.engine.data.map.Street;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.DrawUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.Bitmap;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	
	public class MapHub extends MapBase {
		public static var STREET:String = 'S';
		public static var STREET_LOCKED:String = 'SL';
		public static var HUB_CONNECTION:String = 'X';
		
		private static var path_color:int = -1;
		
		private var hub_id:String;
		private var highlight_street_tsid:String;
		
		private var sp_spA:Array = [];
		private var path_tsids:Array = [];
		private var current_segments:Vector.<MapPathSegment> = new Vector.<MapPathSegment>();
		private var search_street:MapStreet;
		private var your_street:MapStreet;
		
		private var map_lines_container:Sprite = new Sprite(); // holds only the lines themselves;
		private var map_other_container:Sprite = new Sprite(); // holds icons, etc
		private var map_labels_container:Sprite = new Sprite(); // holds street labels
		private var map_path_container:Sprite = new Sprite(); // holds the path
		private var dest_marker:Sprite = new Sprite(); //shows a marker for the final destination
		private var search_street_holder:Sprite = new Sprite();
		private var you_view_zoom:Sprite = new Sprite(); //when you want to have a star that zooms into the normal one
		
		private var search_street_tf:TextField = new TextField(); //when searching and flashing the location, show this zooming to the right spot
		
		private var flash_search_street:Boolean;
		private var show_go_buttons:Boolean;
		
		public function MapHub(hub_id:String, you_view_holder:Sprite) {
			super();
			this.name = this.hub_id = hub_id;
			this.you_view_holder = you_view_holder;
			blendMode = BlendMode.LAYER;
			
			//if this is the first time loading it, make sure we get the path color
			if(path_color == -1){
				path_color = CSSManager.instance.getUintColorValueFromStyle('hub_map_path_color', 'color', 0xf0f258);
			}
		}
		
		override protected function construct():void {
			super.construct();
			
			this.addChild(map_bg_container);
			
			map_lines_container.x = 0;
			map_lines_container.y = 0;
			this.addChild(map_lines_container);
			
			map_path_container.mouseEnabled = false;
			map_path_container.mouseChildren = false;
			map_path_container.x = map_lines_container.x;
			map_path_container.y = map_lines_container.y;
			this.addChild(map_path_container);
			
			var marker:DisplayObject = new AssetManager.instance.assets.path_marker();
			marker.x = -marker.width/2;
			marker.y = -marker.height;
			dest_marker.mouseEnabled = false;
			dest_marker.mouseChildren = false;
			dest_marker.addChild(marker);
			
			map_fg_container.mouseEnabled = false;
			this.addChild(map_fg_container);
			
			map_other_container.x = map_lines_container.x;
			map_other_container.y = map_lines_container.y;
			this.addChild(map_other_container);
			
			map_labels_container.mouseChildren = false;
			map_labels_container.mouseEnabled = false;
			map_labels_container.x = map_lines_container.x;
			map_labels_container.y = map_lines_container.y;
			this.addChild(map_labels_container);
			
			map_lines_container.addEventListener(MouseEvent.MOUSE_OVER, onMapLinesMouseOver);
			map_lines_container.addEventListener(MouseEvent.MOUSE_OUT, onMapLinesMouseOut);
			map_lines_container.addEventListener(MouseEvent.CLICK, onMapLinesMouseClick);
			
			//setup the search zoom flashing stuff
			TFUtil.prepTF(search_street_tf, false);
			search_street_tf.filters = StaticFilters.white3px_GlowA;
			search_street_holder.visible = false;
			search_street_holder.addChild(search_street_tf);
			addChild(search_street_holder);
			
			//the you view star as well
			HubMapDialog.instance.buildYouView(you_view_zoom);
			you_view_zoom.x = HubMapDialog.MAP_W/2;
			you_view_zoom.y = HubMapDialog.MAP_H/2;
			addChild(you_view_zoom);
		}
		
		private function onMapLinesMouseOver(e:MouseEvent):void {
			const map_street:MapStreet = (e.target as MapStreet);
			if (map_street) {
				map_street.parent.swapChildren(map_street, map_street.parent.getChildAt(map_street.parent.numChildren-1));
				var DO:DisplayObject = map_labels_container.getChildByName(map_street.name);
				if(DO) map_labels_container.setChildIndex(DO, map_labels_container.numChildren-1);
				
				map_street.highlight();
			}
		}
		
		private function onMapLinesMouseOut(e:MouseEvent):void {
			const map_street:MapStreet = (e.target as MapStreet);
			if (map_street) {
				map_street.unhighlight();
			}
		}
		
		private function onMapLinesMouseClick(e:MouseEvent):void {
			const map_street:MapStreet = (e.target as MapStreet);
			if (map_street) {
				//reset the css
				if(map_street.street.tsid != model.worldModel.location.tsid){
					map_street.css_class = 'hub_map_street_other_new';
					map_street.css_hover_class = 'hub_map_street_other_hover';
				}
				CONFIG::debugging {
					Console.warn('show menu for street '+map_street.street.tsid, map_street.street.name, hub.tsid, hub.label);
				}
				TSFrontController.instance.startLocationMenuFromHubMap(map_street.street, hub.tsid);
			}
		}
		
		private function get hub():Hub {
			return model.worldModel.hubs[hub_id];
		}
		
		public function hideAllButGraphics():void {
			map_lines_container.visible = false;
			map_other_container.visible = false;
			map_labels_container.visible = false;
			map_path_container.visible = false;
			dest_marker.visible = false;
		}
		
		public function unHideAllButGraphics():void {
			map_lines_container.visible = true;
			map_other_container.visible = true;
			map_labels_container.visible = true;
			map_path_container.visible = true;
			dest_marker.visible = true;
		}
		
		public function build(highlight_street_tsid:String = '', flash_loc:Boolean = false, show_go_buttons:Boolean = true):void {
			for (var i:int;i<sp_spA.length;i++) {
				TipDisplayManager.instance.unRegisterTipTrigger(sp_spA[int(i)]);
			}
			
			flash_search_street = flash_loc;
			this.highlight_street_tsid = highlight_street_tsid;
			
			SpriteUtil.clean(map_lines_container);
			SpriteUtil.clean(map_labels_container);
			SpriteUtil.clean(map_other_container);
			SpriteUtil.clean(map_path_container);
			sp_spA.length = 0;
			
			for (var k:Object in tipsH) delete tipsH[k];
			
			this.show_go_buttons = show_go_buttons;
			drawMapFromMapData();
			updateLocPath();
		}
		
		public function updateLocPath():void {
			var map_data:MapData = hub.map_data;
			var i:int;
			var segment:MapPathSegment;
			var street:Street;
			var seg_index:int;
			var dest_loc:Location;
						
			if(model.stateModel.current_path){
				dest_loc = model.worldModel.getLocationByTsid(model.stateModel.current_path.destination_tsid);
				path_tsids.length = 0;
				current_segments.length = 0;
				
				//go through the current hub and see if we have any points in it
				if(map_data && map_data.streets.length){
					
					for(i = 0; i < map_data.streets.length; i++){
						street = map_data.streets[int(i)];
						if(street.type == STREET && model.stateModel.current_path.getSegmentByTsid(street.tsid)){
							path_tsids.push(street.tsid);
						}
					}
					
					//get the points in order
					segment = model.stateModel.current_path.getSegmentByTsid(model.worldModel.location.tsid);
					seg_index = model.stateModel.current_path.segments.indexOf(segment);
					
					//we might be off the grid, let's see if the parent street is in there
					if(seg_index == -1){
						segment = model.stateModel.current_path.getSegmentByTsid(model.worldModel.location.mapInfo.showStreet);
						seg_index = model.stateModel.current_path.segments.indexOf(segment);
					}
					
					if(seg_index >= 0){
						for(i = seg_index; i < model.stateModel.current_path.segments.length; i++){
							segment = model.stateModel.current_path.segments[int(i)];
							if(path_tsids.indexOf(segment.tsid) != -1){
								current_segments.push(segment);
							}
						}
					}
					
					//have any segments?
					if(current_segments.length){
						if(dest_loc.hub_id == hub.tsid) {
							map_other_container.addChild(dest_marker);
						}
						else if(dest_marker.parent){
							map_other_container.removeChild(dest_marker);
						}
						
						//only draw the path if they can path out
						street = map_data.getStreetByTsid(current_segments[0].tsid);
						if(street && !street.invisible_to_outsiders && !street.not_a_destination){
							drawSegmentPath(current_segments);
						}
					}
				}
			}
			else {
				//no more path, clear it out!
				SpriteUtil.clean(map_path_container);
				if(dest_marker.parent) dest_marker.parent.removeChild(dest_marker);
			}
		}
		
		private function drawSegmentPath(segments:Vector.<MapPathSegment>):void {
			const LINE_BUFFER:uint = 20;
			var i:int;
			var j:int;
			var seg_index:int;
			var map_street:MapStreet;
			var next_street:MapStreet;
			var pt:Point;
			var current_point:Point;
			var location:Location;
			var map_hub_bt:MapHubButton;
			var map_hub_bts:Vector.<MapHubButton>;
			var hit_map_hub_bt:Boolean;
			var all_segements:Vector.<MapPathSegment> = model.stateModel.current_path.segments;
			var last_street:String = all_segements[all_segements.length-1].tsid;
			var g:Graphics = map_path_container.graphics;
			g.clear();
			g.lineStyle(6, path_color);
			
			for(i; i < segments.length; i++){
				map_street = map_lines_container.getChildByName(segments[int(i)].tsid) as MapStreet;
				if(i < segments.length-1) next_street = map_lines_container.getChildByName(segments[i+1].tsid) as MapStreet;
				if(!map_street) continue;
								
				location = model.worldModel.getLocationByTsid(segments[int(i)].tsid);
				
				//where we are standing
				if(i == 0 && location && location.tsid == model.worldModel.location.tsid){
					pt = map_street.localToGlobal(new Point(model.stateModel.current_path.you_pt.x, 0));
					pt = map_path_container.globalToLocal(pt);
					g.moveTo(pt.x, pt.y);
					current_point = pt;
				}
				//first street, but we are not in this hub (or in a place off the map)
				else if(i == 0){
					location = model.worldModel.location;
					seg_index = all_segements.indexOf(segments[int(i)]);
										
					if(seg_index > 0){
						location = model.worldModel.getLocationByTsid(all_segements[seg_index-1].tsid);
						if(location){
							map_hub_bts = getMapHubButtons(location.hub_id);
							
							//does this street link to another hub?
							if(map_hub_bts.length){
								for(j = 0; j < map_hub_bts.length; j++){
									map_hub_bt = map_hub_bts[int(j)];
									pt = map_street.localToGlobal(new Point(-map_street.street_width/2, 0));
									
									//boom, headshot
									if(map_hub_bt.hitTestPoint(pt.x, pt.y)){
										hit_map_hub_bt = true;
										break;
									}
									//missed, let's try the other side
									else {
										pt = map_street.localToGlobal(new Point(map_street.street_width/2, 0));
										//gotcha
										if(map_hub_bt.hitTestPoint(pt.x, pt.y)){
											hit_map_hub_bt = true;
											break;
										}
									}
								}
								
								//must be one of those shitty streets that don't start from a button
								if(!hit_map_hub_bt){
									if(segments[int(i)].from < 50){
										pt = map_street.localToGlobal(new Point(-map_street.street_width/2, 0));
									}
									else {
										pt = map_street.localToGlobal(new Point(map_street.street_width/2, 0));
									}
								}
							}
							//we must be off the map, so just start on the street where our dude is
							else {
								pt = map_street.localToGlobal(new Point(model.stateModel.current_path.you_pt.x, 0));
							}
						}
						//we must be off the map, so just start on the street where our dude is
						else {
							pt = map_street.localToGlobal(new Point(model.stateModel.current_path.you_pt.x, 0));
						}
					}
					//we are off the map, start from the parent street
					else if(location.mapInfo && location.mapInfo.showStreet) {
						map_street = map_lines_container.getChildByName(location.mapInfo.showStreet) as MapStreet;
						if(map_street) pt = map_street.localToGlobal(new Point(model.stateModel.current_path.you_pt.x, 0));
					}
					
					if(pt){
						pt = map_path_container.globalToLocal(pt);
						g.moveTo(pt.x, pt.y);
						current_point = pt;
					}
				}
				
				//if we don't have a current point then something messed up
				if(!current_point){
					var path_tsids:Array = new Array();
					for(j = 0; j < all_segements.length; j++){
						path_tsids.push(all_segements[int(j)].tsid);
					}
					
					if(model.worldModel.location.mapInfo && model.worldModel.location.mapInfo.showStreet){
						path_tsids.push(' SHOWSTREET (PARENT) TSID: '+model.worldModel.location.mapInfo.showStreet);
					}
					
					BootError.handleError('Current location: '+model.worldModel.location.tsid+' PATH TSIDS: '+path_tsids, new Error("Unexpected path segment position"), null, true);
					CONFIG::debugging {
						Console.warn('Bad first position data', 'Current location: '+model.worldModel.location.tsid+' PATH TSIDS: '+path_tsids);
					}
					continue;
				}
				
				//clear out the point incase our intersection fails
				pt = null;
				if(next_street){
					pt = DrawUtil.pointIntersection(
						map_street.localToGlobal(new Point(-map_street.street_width/2-LINE_BUFFER, 0)),
						map_street.localToGlobal(new Point(map_street.street_width/2+LINE_BUFFER, 0)),
						next_street.localToGlobal(new Point(-next_street.street_width/2-LINE_BUFFER, 0)),
						next_street.localToGlobal(new Point(next_street.street_width/2+LINE_BUFFER, 0))
					);
				}
				
				//we got a point, let's draw it!
				if(pt) {
					pt = map_path_container.globalToLocal(pt);
					g.lineTo(pt.x, pt.y);
					current_point = pt;
				}
				else {
					//this is the final destination
					if(map_street.name == last_street){
						//see if the current point is closer to the start or the end
						pt = map_street.localToGlobal(new Point(-map_street.street_width/2, 0));
						pt.x += LINE_BUFFER;
						
						pt = DrawUtil.pointIntersection(
							map_path_container.localToGlobal(current_point),
							pt,
							map_street.localToGlobal(new Point(-map_street.street_width/2-LINE_BUFFER, 0)),
							map_street.localToGlobal(new Point(map_street.street_width/2+LINE_BUFFER, 0))
						);
						
						if(pt){
							pt = map_path_container.globalToLocal(pt);
							g.lineTo(pt.x, pt.y);
						}
						
						pt = map_street.localToGlobal(new Point(0,0));
						pt = map_path_container.globalToLocal(pt);
						//dest_marker.rotation = map_street.rotation;
						dest_marker.x = pt.x;
						dest_marker.y = pt.y;
						
						g.lineTo(pt.x, pt.y);
						current_point = pt;
					}
					//if there is a street on this map that we can't intersect, let's just go to the start/end of the street
					else if(next_street){
						//so we got here, but this isn't the last street AND it couldn't touch a GO button. Jesus.
						if(i == segments.length-1){
							//use the exact "to" percent
							pt = map_street.localToGlobal(new Point(-map_street.street_width/2 + map_street.street_width*(segments[int(i)].to/100), 0));
							pt = map_path_container.globalToLocal(pt);
							
							g.lineTo(pt.x, pt.y);
							current_point = pt;
						}
						else {
							//borrowing current_point so that we don't have to make a NEW point
							if(segments[int(i)].to > 50){
								current_point = map_street.localToGlobal(new Point(map_street.street_width/2, 0));
								pt = next_street.localToGlobal(new Point(-next_street.street_width/2, 0));
							}
							else {
								current_point = map_street.localToGlobal(new Point(-map_street.street_width/2, 0));
								pt = next_street.localToGlobal(new Point(next_street.street_width/2, 0));
							}
							
							current_point = map_path_container.globalToLocal(current_point);
							pt = map_path_container.globalToLocal(pt);
							
							g.lineTo(current_point.x, current_point.y);
							g.lineTo(pt.x, pt.y);
							current_point = pt;
						}
					}
					//we have to probably go to another hub
					else {						
						//if it's > 50% to the destination than we draw to the end
						if(segments[int(i)].to > 50){
							pt = map_street.localToGlobal(new Point(map_street.street_width/2, 0));
						}
						//draw it to the start
						else {
							pt = map_street.localToGlobal(new Point(-map_street.street_width/2, 0));
						}
						
						pt = map_path_container.globalToLocal(pt);
						
						g.lineTo(pt.x, pt.y);
						current_point = pt;
					}
				}	
			}
		}
		
		public function getYourStreet():MapStreet {
			//where is the star at
			return your_street;
		}
		
		override public function getTip(tip_target:DisplayObject = null):Object {
			if (!tip_target) return null;
			
			var tip:String = '';
			var signpost:SignPost = model.worldModel.location.mg.getSignpostById(tip_target.name);
			if (signpost) {
				
				var visible_connects:Vector.<LocationConnection> = signpost.getVisibleConnects();
				if (visible_connects.length == 0) return null;
				tip = 'Signpost to:\r';
				for(var j:int = 0; j < visible_connects.length; j++){
					tip += ''+visible_connects[int(j)].label + ((j+1 < visible_connects.length) ? '\n' : '');
				}
			} else if (tip_target is Sprite) {
				tip = tipsH[tip_target];
				if (!tip) return null;
			} else {
				return null;
			}
			
			return {
				txt: tip,
				offset_y: -7,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
		
		private function drawMapFromMapData():void {
			if (!hub || (hub && !hub.map_data)) {
				CONFIG::debugging {
					Console.warn('We have no map data!');
				}
				BootError.handleError('HUB MISSING map_data: '+hub_id+ ' STREET: '+model.worldModel.location.tsid, new Error('Missing hub map_data'));
				return;
			}
			
			const map_data:MapData = hub.map_data;
			
			var bg_url:String = map_data.bg;
			var i:int;
			var map_street:MapStreet;
			var street:Street;
			var DO:DisplayObject;
			
			if (model.flashVarModel.local_pc == 'P001') {
				//bg_url+='?'+new Date().getTime();
			}
			
			if (bg_url != image_url) {	
				SpriteUtil.clean(map_bg_container);
				SpriteUtil.clean(map_fg_container);
				image_req.url = bg_url;
				image_loader.load(image_req, context);
				image_fg_url = map_data.fg;
			} else {
				// we're good
				StageBeacon.waitForNextFrame(allReady);
			}
			
			// reset this only if this is the hub for the current location
			// because if it is someother hub, it shoudl not change current_street
			if (hub_id == model.worldModel.location.hub_id) {
				HubMapDialog.instance.current_street = null;
			}
			
			//hide the search street animation stuff
			search_street_holder.visible = false;
			search_street = null;
			you_view_zoom.visible = false;
			your_street = null;
			
			//draw the map stuff
			for(i = 0; i < map_data.streets.length; i++){
				street = map_data.streets[int(i)];
				if(street.tsid == model.worldModel.location.tsid && !street.visited){
					//we are here damn it!
					street.visited = true;
				}
								
				if(street.type == STREET || street.type == STREET_LOCKED){
					map_street = drawStreet(street);
					if(map_street && street.tsid == highlight_street_tsid && flash_search_street){
						search_street = map_street;
					}
				}
				else if(street.type == HUB_CONNECTION){
					drawXObj(street);
				}
			}
			
			//make sure your current street is on top of the Z
			map_street = map_lines_container.getChildByName(model.worldModel.location.tsid) as MapStreet;
			
			//are we off the grid?
			if(!map_street && model.worldModel.location.mapInfo && model.worldModel.location.mapInfo.showStreet){
				map_street = map_lines_container.getChildByName(model.worldModel.location.mapInfo.showStreet) as MapStreet;
			}
			
			if(map_street) {
				//lines
				map_lines_container.setChildIndex(map_street, map_lines_container.numChildren-1);
				
				//label
				DO = map_labels_container.getChildByName(map_street.name);
				if(DO) map_labels_container.setChildIndex(DO, map_labels_container.numChildren-1);
				
				//if we don't have to flash the street make sure we animate the star when the map is loaded back
				if(!flash_search_street){
					your_street = map_street;
				}
			}
		}
		
		private function drawXObj(street:Street):void {
			var hub:Hub = model.worldModel.getHubByTsid(street.hub_id);
			if (!hub) {
				hub = model.worldModel.hubs[street.hub_id] = new Hub(street.hub_id);
				hub.label = street.hub;
			}
			
			var bt_size:int = 32;
			var map_hub_bt:MapHubButton = new MapHubButton(bt_size, street);
			map_hub_bt.x = street.x-(bt_size/2);
			map_hub_bt.y = street.y-(bt_size/2);
			map_hub_bt.visible = show_go_buttons;
			
			//give it a unique name
			map_hub_bt.name = 'map_hub_bt_'+street.hub_id+'_'+getMapHubButtons(street.hub_id).length;
			
			map_other_container.addChild(map_hub_bt);
		}
		
		public function changeSignpostVisibility(signpost:SignPost):void {
			var visible_connects:Vector.<LocationConnection> = signpost.getVisibleConnects();
			for (var i:int;i<sp_spA.length;i++) {
				if (sp_spA[int(i)].name == signpost.tsid) {
					sp_spA[int(i)].visible = (visible_connects.length > 0);
					if (!sp_spA[int(i)].visible) {
						TipDisplayManager.instance.unRegisterTipTrigger(sp_spA[int(i)]);
					} else {
						TipDisplayManager.instance.registerTipTrigger(sp_spA[int(i)]);
					}
					break;
				} 
			}
		}
		
		private const tipsH:Dictionary = new Dictionary(true);
		
		private function drawStreet(street:Street):MapStreet {
			var loc:Location = model.worldModel.location;
			var highlight_it:Boolean = (street['tsid'] == loc.tsid || (loc.mapInfo.showStreet && street.tsid == loc.mapInfo.showStreet));
			
			if (street.invisible_to_outsiders && !highlight_it) {
				return null;
			}
			
			var map_street:MapStreet;
			var label:Sprite;
			var tf:TextField;
			var pt1:Point;
			var pt2:Point;
			//Console.info(hub);
			var distance:Number;
			var xdiff:Number;
			var ydiff:Number;
			var angle:Number;
			var ratioW:Number = HubMapDialog.MAP_W/HubMapDialog.MAP_ACTUAL_W;
			var ratioH:Number = HubMapDialog.MAP_H/HubMapDialog.MAP_ACTUAL_H;
			
			pt1 = new Point(street['x1']*ratioW, street['y1']*ratioH);
			pt2 = new Point(street['x2']*ratioW, street['y2']*ratioH);
			
			xdiff = pt2.x - pt1.x;
			ydiff = pt2.y - pt1.y;
			
			distance = Point.distance(pt1, pt2);
			street.scaled_distance = distance; // add this in to the object
			street.rotation = Math.atan2(ydiff, xdiff)*180/Math.PI;
			
			tf = new TextField();
			TFUtil.prepTF(tf, false);
			
			map_street =  new MapStreet(street, tf);
			map_street.x = pt1.x+(xdiff/2);
			map_street.y = pt1.y+(ydiff/2);
			
			label =  new Sprite();
			label.name = street.tsid;
			label.x = map_street.x;
			label.y = map_street.y;
			
			var sp:Sprite;
			var icon:Bitmap;
			
			if (street.store) {
				icon = new AssetManager.instance.assets['map_icon_shop']();
				icon.blendMode = BlendMode.MULTIPLY;
				icon.smoothing = true;
				icon.x = 2;
				icon.y = 10;
				
				sp = new Sprite();
				sp.name = street.store;
				sp.x = map_street.x;
				sp.y = map_street.y;
				sp.addChild(icon);
				
				tipsH[sp] = StringUtil.capitalizeFirstLetter(street.store)+' Vendor';
				TipDisplayManager.instance.registerTipTrigger(sp);
				
				sp.addEventListener(MouseEvent.ROLL_OVER, otherMouseOverHandler, false, 0, true);
				sp.addEventListener(MouseEvent.ROLL_OUT, otherMouseOutHandler, false, 0, true);
				sp.filters = StaticFilters.white2px40percent_GlowA;
				sp.rotation = street.rotation;
				map_other_container.addChild(sp);
			}

			if (street.shrine) {
				icon = new AssetManager.instance.assets['map_icon_shrine']();
				icon.blendMode = BlendMode.MULTIPLY;
				icon.smoothing = true;
				icon.x = -2 - icon.width;
				icon.y = 10;

				sp = new Sprite();
				sp.name = street.shrine;
				sp.x = map_street.x;
				sp.y = map_street.y;
				sp.addChild(icon);
				
				tipsH[sp] = 'Shrine to '+StringUtil.capitalizeFirstLetter(street.shrine);
				TipDisplayManager.instance.registerTipTrigger(sp);

				sp.addEventListener(MouseEvent.ROLL_OVER, otherMouseOverHandler, false, 0, true);
				sp.addEventListener(MouseEvent.ROLL_OUT, otherMouseOutHandler, false, 0, true);
				sp.filters = StaticFilters.white2px40percent_GlowA;
				sp.rotation = street.rotation;
				map_other_container.addChild(sp);
			}
			
			if (street.has_subway) {
				icon = new AssetManager.instance.assets['map_icon_subway']();
				//icon.blendMode = BlendMode.MULTIPLY;
				icon.smoothing = true;
				icon.x = int(-icon.width/2);
				//TODO not fucking hardcode TSIDs for icon placement offset *sigh*
				if(street.tsid == 'LIF10HE4JTU1S7P'){
					icon.x += 20; //jed tower
				}
				else if(street.tsid == 'LLI3272LOTD1B1F'){
					icon.x += 40; //groddle junction
				}
				icon.y = -30;
				
				sp = new Sprite();
				sp.name = street.tsid+'_subway';
				sp.x = map_street.x;
				sp.y = map_street.y;
				sp.addChild(icon);
				
				tipsH[sp] = 'Subway Station';
				TipDisplayManager.instance.registerTipTrigger(sp);
				
				sp.addEventListener(MouseEvent.ROLL_OVER, otherMouseOverHandler, false, 0, true);
				sp.addEventListener(MouseEvent.ROLL_OUT, otherMouseOutHandler, false, 0, true);
				//sp.filters = StaticFilters.white2px40percent_GlowA;
				sp.rotation = street.rotation;
				map_other_container.addChild(sp);
			}
			
			if (highlight_it) {
				HubMapDialog.instance.current_street = street;
				
				map_street.css_class = 'hub_map_street_current_new';
				map_street.css_hover_class = 'hub_map_street_current_hover';
				map_street.is_current = true;
				
				//put the star with the label so it can be awesome with Z ordering
				label.addChild(you_view_holder);
				label.addChild(tf);
			} else {
				map_street.css_class = 'hub_map_street_other_new';
				map_street.css_hover_class = 'hub_map_street_other_hover';
				map_street.is_current = false;
				label.addChild(tf);
			}
			
			map_street.unhighlight();
			map_street.alpha = 1;
			map_street.rotation = street.rotation;
			map_lines_container.addChild(map_street);
			
			label.rotation = map_street.rotation;
			map_labels_container.addChild(label);
			
			return map_street;
		}
		
		public function animateSearchOrYou(delay:Number = 0):void {
			if(!search_street && !your_street) return;
			
			const holder:Sprite = search_street ? search_street_holder : you_view_zoom;
			const street:MapStreet = search_street ? search_street : your_street;
			
			if(search_street){
				search_street_tf.htmlText = '<p class="hub_map_street_alert">'+search_street.street.name+'</p>';
				SpriteUtil.setRegistrationPoint(search_street_tf);
			}
			
			if(holder && street){
				holder.scaleX = holder.scaleY = 2;
				holder.visible = true;
				holder.alpha = 0;
				holder.rotation = 0;
				holder.x = HubMapDialog.MAP_W/2;
				holder.y = HubMapDialog.MAP_H/2;
				
				TSTweener.removeTweens(holder);
				TSTweener.addTween(holder, {
					alpha:1,
					scaleX:3,
					scaleY:3,
					time:.3,
					delay:delay
				});
				TSTweener.addTween(holder, {
					x:street == your_street ? getYourPt().x : street.x, 
					y:street == your_street ? getYourPt().y : street.y,
					scaleX:1, 
					scaleY:1, 
					rotation:street.street.rotation, 
					time:.6, 
					delay:.6 + delay,
					transition:'easeOutBounce',
					onComplete:onAnimationComplete
				});
			}
		}
		
		private function onAnimationComplete():void {
			if(search_street){
				search_street_holder.visible = false;
				search_street.alert();
			}
			else if(your_street){
				you_view_zoom.visible = false;
			}
		}
		
		private function getMapHubButtons(hub_id:String):Vector.<MapHubButton> {
			var bts:Vector.<MapHubButton> = new Vector.<MapHubButton>();
			var bt:MapHubButton;
			var child:DisplayObject;
			var i:int;
			
			//loop through the button holder and snag all the buttons with the hub_id
			for(i; i < map_other_container.numChildren; i++){
				child = map_other_container.getChildAt(i);
				if(child is MapHubButton && child.name.indexOf('map_hub_bt_'+hub_id+'_') != -1){
					bts.push(MapHubButton(child));
				}
			}
			
			return bts;
		}
		
		private function otherMouseOverHandler(e:Event):void {
			if(DisplayObject(e.target).name.indexOf('subway') == -1){
				DisplayObject(e.target).filters = StaticFilters.youDisplayManager_GlowA;
			}
		}
		
		private function otherMouseOutHandler(e:Event):void {
			if(DisplayObject(e.target).name.indexOf('subway') == -1){
				DisplayObject(e.target).filters = StaticFilters.white2px40percent_GlowA;
			}
		}
	}
}