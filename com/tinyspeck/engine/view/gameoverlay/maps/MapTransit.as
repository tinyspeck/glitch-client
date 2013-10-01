package com.tinyspeck.engine.view.gameoverlay.maps
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.data.transit.Transit;
	import com.tinyspeck.engine.data.transit.TransitLine;
	import com.tinyspeck.engine.data.transit.TransitLocation;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.TransitManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class MapTransit extends MapBase
	{	
		private static const BT_OUT_ALPHA:Number = .8; //when the button is in the OUT state, what it's alpha is
		
		private var transit_tsid:String;
		
		private var button_holder:Sprite = new Sprite();
		
		private var next_stop_tf:TextField = new TextField();
		
		public function MapTransit(transit_tsid:String, you_view_holder:Sprite){
			super();
			name = transit_tsid;
			this.transit_tsid = transit_tsid;
			this.you_view_holder = you_view_holder;
		}
		
		override protected function construct():void {
			super.construct();
			
			addChild(button_holder);
			
			TFUtil.prepTF(next_stop_tf);
			next_stop_tf.wordWrap = false;
			addChild(next_stop_tf);
		}
		
		public function get transit():Transit {
			if(!transit_tsid) return null;
			
			return model.worldModel.getTransitByTsid(transit_tsid);
		}
		
		public function build(transit_line:TransitLine):void {			
			if(transit){
				var i:int;
				var line:TransitLine;
				var bt:Button;
				var bt_label_c:uint;
				var next_x:int;
				var bt_graphic:Sprite;
				var g:Graphics;
				
				//make sure we snag the star
				if(you_view_holder) addChild(you_view_holder);
				
				for(i; i < transit.lines.length; i++){
					line = transit.lines[int(i)];
					
					//build out the button
					if(!button_holder.getChildByName(line.tsid)){
						bt_label_c = CSSManager.instance.getUintColorValueFromStyle('transit_'+transit.tsid+'_'+line.tsid, 'color', 0xdf6747);
						
						//add the line to the button
						bt_graphic = new Sprite();
						g = bt_graphic.graphics;
						g.beginFill(bt_label_c);
						g.drawRect(0, 3, int(CSSManager.instance.getNumberValueFromStyle('button_transit_line', 'width', 80) - 16), 2);
						
						bt = new Button({
							name: line.tsid,
							label: line.name,
							size: Button.SIZE_TRANSIT_LINE,
							type: Button.TYPE_TRANSIT_LINE,
							graphic: bt_graphic,
							x: next_x,
							y: -6
						});
						
						bt.label_color = bt_label_c;
						bt.label_color_hover = bt_label_c;
						bt.label_color_disabled = bt_label_c;
						bt.addEventListener(TSEvent.CHANGED, onLineClick, false, 0, true);
						bt.addEventListener(MouseEvent.ROLL_OVER, onLineOver, false, 0, true);
						bt.addEventListener(MouseEvent.ROLL_OUT, onLineOut, false, 0, true);
						next_x += bt.width + 5;
						button_holder.addChild(bt);
					}
				}
				
				//place the buttons in the right spot
				button_holder.x = int(HubMapDialog.MAP_W - button_holder.width - 40);
				next_stop_tf.y = int(button_holder.height + 310);
				
				//default color
				if(transit.lines.length){
					switchLines(transit_line ? transit_line : transit.lines[0]);
				}
			}
		}
		
		private function onLineOver(event:MouseEvent):void {
			var bt:Button = event.currentTarget as Button;
			bt.alpha = 1;
		}
		
		private function onLineOut(event:MouseEvent):void {
			var bt:Button = event.currentTarget as Button;
			if(bt.disabled) return;
			
			bt.alpha = BT_OUT_ALPHA;
		}
		
		private function onLineClick(event:TSEvent):void {
			var bt:Button = event.data as Button;
			if(bt.disabled) return;
			
			//if we are riding the transit, they can't switch the lines!
			if(TransitManager.instance.current_status && TransitManager.instance.current_status.tsid == transit.tsid){
				return;
			}
			
			var line:TransitLine = transit.getLineByTsid(bt.name);
			//check to make sure we are still here and color the circle if we need to
			if(line) switchLines(line);
		}
		
		private function switchLines(line:TransitLine):void {
			//if it's a different bg, make sure we load that
			if(line.bg && line.bg != image_url){
				SpriteUtil.clean(map_bg_container);
				SpriteUtil.clean(map_fg_container);
				image_url = line.bg;
				image_fg_url = line.fg;
				image_req.url = image_url;
				image_loader.load(image_req, context);
			}
			//if the FG is the only thing that has changed, load it
			else if(line.fg && line.fg != image_fg_url){
				SpriteUtil.clean(map_fg_container);
				image_fg_url = line.fg;
				image_req.url = image_fg_url;
				image_loader.load(image_req, context);
			}
			//we're good
			else {
				StageBeacon.waitForNextFrame(allReady);
			}
			
			//set the line buttons up properly
			var i:int;
			var bt:Button;
			
			for(i; i < button_holder.numChildren; i++){
				bt = button_holder.getChildAt(i) as Button;
				bt.y = bt.name == line.tsid ? -2 : -6;
				bt.filters = bt.name == line.tsid ? 
							 StaticFilters.black7px90Degrees_DropShadowA : 
							 StaticFilters.black8px90DegreesInner_DropShadowA.concat(StaticFilters.black3px90Degrees_DropShadowA);
				bt.disabled = bt.name == line.tsid;
				bt.alpha = bt.name == line.tsid ? 1 : BT_OUT_ALPHA;
				bt.tip = null;
			}
			
			//place the star where it needs to go
			setPlayerLocation(line, model.worldModel.location.tsid);
		}
		
		public function setPlayerLocation(transit_line:TransitLine, tsid:String):void {
			//clear the station text
			next_stop_tf.text = '';
			
			if(you_view_holder){			
				var location:TransitLocation;
				
				//default
				you_view_holder.filters = null;
				
				//we may be riding the line already, let's see!
				if(TransitManager.instance.current_location_tsid){
					location = transit_line.getLocationByTsid(TransitManager.instance.current_location_tsid);
				}
				//are we in a location that is on this line?
				else {
					location = transit_line.getLocationByTsid(tsid);
				}
				
				you_view_holder.visible = false;
				
				if(location){
					//color the hole under the star
					var g:Graphics = you_view_holder.graphics;
					g.clear();
					g.beginFill(CSSManager.instance.getUintColorValueFromStyle('transit_'+transit.tsid+'_'+transit_line.tsid, 'color', 0xdf6747));
					g.drawCircle(0,0,8);
					you_view_holder.x = location.x;
					you_view_holder.y = location.y;
					you_view_holder.visible = true;
										
					//show the next location if we are on the transit
					if(TransitManager.instance.current_location_tsid){
						location = transit_line.getNextLocationByTsid(TransitManager.instance.current_location_tsid);
						
						//add tips to the other lines saying why they can't click it
						var i:int;
						var bt:Button;
						
						for(i; i < button_holder.numChildren; i++){
							bt = button_holder.getChildAt(i) as Button;
							bt.tip = !bt.disabled ? {txt:"You're on the "+transit_line.name, pointer:WindowBorder.POINTER_BOTTOM_CENTER} : null;
						}
						
						//if we are moving, greyscale the star
						you_view_holder.filters = TransitManager.instance.current_status.is_moving ? [ColorUtil.getGreyScaleFilter()] : null;
					}
					else {
						location = transit_line.getNextLocationByTsid(tsid);
					}
					
					if(location){
						var font_color:String = CSSManager.instance.getStringValueFromStyle('transit_'+transit.tsid+'_'+transit_line.tsid, 'color', '#df6747');
						next_stop_tf.text = '<p class="transit_map"><font color="'+font_color+'">' +
							'<span class="transit_map_next">Next stop:</span><br>' +
							location.name+'</font></p>';
						next_stop_tf.x = button_holder.x + (button_holder.width - next_stop_tf.width)/2 - 17;
					}
				}
			}
		}
		
		public function get player_on_transit():Boolean {
			if(you_view_holder && you_view_holder.visible) return true;
			
			return false;
		}
	}
}