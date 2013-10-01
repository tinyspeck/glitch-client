package com.tinyspeck.engine.view.gameoverlay.maps
{
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.engine.data.map.Street;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	public class MapHubButton extends DisposableSprite {
		private var d:int; // diameter dummy
		private var graphic:Sprite = new Sprite();
		private var circle:Shape = new Shape();
		private var point:Shape = new Shape();
		private var hub_id:String;
		private var loc_tsid:String;
		private var color:String;
		private var label:String;
		private var label_r:Number;
		private var point_r:Number;

		public function MapHubButton(d:int, street:Street) {
			super();
			useHandCursor = buttonMode = true;
			this.d = d;
			
			/*{
				"type"		: "X",
				"x"		: 250,
				"y"		: 20,
				"mote_id"	: "9",
				"hub_id"	: "51",
				"tsid"		: "LIF12PMQ5121D68",
				"hub"		: "Uralia",
				"mote"		: "Ur",
				"color"		: "#ff0000"
			}*/
			
			hub_id = street.hub_id;
			loc_tsid = street.tsid;
			color = street.color || '#cc0000';
			label = street.hub;
			label_r = street.label || 0;
			point_r = street.arrow || 0;
			
			//make sure the color looks right
			if(color.substr(0,1) != '#') color = '#'+color;
			
			init();
		}
		
		private function r_to_direction(r:Number):String {
			if (r >= 315 || r < 45) {
				return 'top';
			} else if (r >= 45 && r < 135) {
				return 'right';
			} else if (r >= 135 && r < 225) {
				return 'bottom';
			} else {
				return 'left';
			}
		}
		
		private function init():void {
			addChild(graphic);
			graphic.addChild(circle);
			graphic.addChild(point);
			point.rotation = point_r;
			point.x = point.y = d/2;
			
			var hub_name_tf:TextField = new TextField;
			hub_name_tf.mouseEnabled = false;
			hub_name_tf.border = false;
			TFUtil.prepTF(hub_name_tf, false);
			hub_name_tf.htmlText = '<span class="hub_map_hub_button_name"><font color="'+color+'">To: '+label+'</font></span>';
			addChild(hub_name_tf);
			
			hub_name_tf.filters = StaticFilters.white3px_GlowA;
			
			var padd_vert:int = 5;
			var padd_horiz:int = 10;
			
			var label_direction:String = r_to_direction(label_r);
			
			if (label_direction == 'top') {
				
				hub_name_tf.x = Math.round((d/2)-(hub_name_tf.width/2));
				hub_name_tf.y = -hub_name_tf.height-padd_vert;
				
			} else if (label_direction == 'right') {
				
				hub_name_tf.x = d+padd_horiz;
				hub_name_tf.y = Math.round((d/2)-(hub_name_tf.height/2))+1; //compensate for flash being a fucking idiot
				
			} else if (label_direction == 'bottom') {
				
				hub_name_tf.x = Math.round((d/2)-(hub_name_tf.width/2));
				hub_name_tf.y = d+padd_vert;
				
			} else { // left
				
				hub_name_tf.x = -hub_name_tf.width-padd_horiz;
				hub_name_tf.y = Math.round((d/2)-(hub_name_tf.height/2))+1; //compensate for flash being a fucking idiot
				
			}
			
			var go_tf:TextField = new TextField;
			TFUtil.prepTF(go_tf, false);
			go_tf.mouseEnabled = false;
			go_tf.border = false;
			go_tf.htmlText = '<span class="hub_map_hub_button_go"><font color="#ffffff">GO</font></span>';
			go_tf.filters = StaticFilters.black1px270Degrees_DropShadowA;
			addChild(go_tf);
			go_tf.x = Math.round((d/2)-(go_tf.width/2));
			go_tf.y = Math.round((d/2)-(go_tf.height/2))+1; //compensate for flash being a fucking idiot
			
			draw();
			unhighlight();
			
			addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
			addEventListener(MouseEvent.ROLL_OVER, overHandler, false, 0, true);
			addEventListener(MouseEvent.ROLL_OUT, outHandler, false, 0, true);
		}
		
		private function overHandler(e:Event):void {
			highlight()
		}
		
		private function outHandler(e:Event):void {
			unhighlight();
		}
		
		private function clickHandler(e:Event):void {
			HubMapDialog.instance.goToHubFromClick(hub_id, loc_tsid, r_to_direction(point_r));
		}
		
		private function draw():void {
			var g:Graphics = circle.graphics;
			g.beginFill(StringUtil.cssHexToUint(color), 1);
			g.drawCircle(d/2, d/2, d/2);
			g.endFill();
			
			g = point.graphics;
			g.beginFill(StringUtil.cssHexToUint(color), 1);
			g.moveTo(-d/2, 0);
			g.lineTo(0, -(d/2)-4); // 4 is the amount the pixels should stick out of the circle
			g.lineTo(d/2, 0);
			g.endFill();
		}
		
		public function highlight():void {
			graphic.filters = StaticFilters.hubButton_GlowA;
		}
		
		public function unhighlight():void {
			graphic.filters = StaticFilters.youDisplayManager_GlowA;
		}
	}
}