package com.tinyspeck.engine.view.ui.map
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.Hub;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.maps.HubMapDialog;
	import com.tinyspeck.engine.view.gameoverlay.maps.MiniMapView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class CurrentLocationUI extends TSSpriteWithModel
	{
		private static const MAX_CHARS:uint = 30;
		
		private var label_tf:TextField = new TextField();
		private var name_tf:TextField = new TextField();
		
		private var icon_holder:Sprite = new Sprite();
		private var name_holder:Sprite = new Sprite();
		private var map_icon:DisplayObject;
		private var map_icon_hover:DisplayObject;
		
		private var is_built:Boolean;
		
		public function CurrentLocationUI(){}
		
		private function buildBase():void {
			//icons
			map_icon = new AssetManager.instance.assets.map_icon();
			icon_holder.addChild(map_icon);
			map_icon_hover = new AssetManager.instance.assets.map_icon_hover();
			icon_holder.addChild(map_icon_hover);
			map_icon_hover.visible = false;
			icon_holder.y = 2;
			addChild(icon_holder);
			
			//tfs
			TFUtil.prepTF(label_tf, false);
			//label_tf.x = icon_holder.width + 5;
			label_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			name_holder.addChild(label_tf);
			
			TFUtil.prepTF(name_tf, false);
			//name_tf.x = label_tf.x;
			name_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			name_holder.addChild(name_tf);
			addChild(name_holder);
			
			//mouse stuff
			mouseChildren = false;
			addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			addEventListener(MouseEvent.ROLL_OVER, onMouse, false, 0, true);
			addEventListener(MouseEvent.ROLL_OUT, onMouse, false, 0, true);
			
			is_built = true;
		}
		
		public function show():void {
			if(!is_built) buildBase();
			
			//if we don't have a location, let's clear things out and bail
			if(!model.worldModel.location){
				label_tf.text = '';
				name_tf.text = '';
				return;
			}
			
			//clickable?
			mouseEnabled = useHandCursor = buttonMode = canOpenMap();
			icon_holder.visible = mouseEnabled;
			
			//can VAG render the current location?
			const vag_ok:Boolean = StringUtil.VagCanRender(model.worldModel.location.label);
			
			//label
			label_tf.embedFonts = vag_ok;
			var label_txt:String = '<p class="current_location">';
			if(!vag_ok) label_txt += '<font face="Arial">';
			label_txt += '<span class="current_location_label">Current location:</span>';
			if(!vag_ok) label_txt += '</font>';
			label_txt += '</p>';
			label_tf.htmlText = label_txt;
			
			//name
			name_tf.embedFonts = vag_ok;
			var tf_txt:String = '<p class="current_location">';
			if(!vag_ok) tf_txt += '<font face="Arial">';
			tf_txt += StringUtil.truncate(model.worldModel.location.label, MAX_CHARS);
			if(!vag_ok) tf_txt += '</font>';
			tf_txt += '</p>';
			
			name_tf.htmlText = tf_txt;
			
			//is the name too big?
			const draw_w:int = MiniMapView.instance.w + (icon_holder.visible ? icon_holder.width + 5: 0);
			name_tf.scaleX = name_tf.scaleY = 1;
			if(name_tf.width > MiniMapView.instance.w){
				name_tf.scaleX = name_tf.scaleY = MiniMapView.instance.w/name_tf.width;
			}
			name_tf.y = int(label_tf.height - 2);
			
			//draw the hit area
			var g:Graphics = name_holder.graphics;
			g.clear();
			g.beginFill(0,0);
			g.drawRect(icon_holder.visible ? -icon_holder.width : 0, 0, draw_w, name_tf.y + name_tf.height);
			
			name_holder.x = icon_holder.visible ? icon_holder.width + 5 : 0
		}
		
		private function canOpenMap():Boolean {
			//checks if we can even open the map
			if (!model.worldModel.location.show_hubmap) return false;
			if (model.stateModel.editing || model.stateModel.hand_of_god) return false;
			if (!model.worldModel.location.mapInfo) return false;
			
			const hub:Hub = model.worldModel.hubs[model.worldModel.location.mapInfo.hub_id];
			return (hub && hub.map_data);
		}
		
		private function onClick(event:MouseEvent):void {
			//check one more time to be safe
			if(!canOpenMap()) return;
			
			// if we have a specific place to open to, do that
			if (!HubMapDialog.instance.parent && model.stateModel.hub_to_open_map_to) {
				HubMapDialog.instance.start();
				HubMapDialog.instance.goToHubFromClick(model.stateModel.hub_to_open_map_to, model.stateModel.street_to_open_map_to, '', true);
				model.stateModel.hub_to_open_map_to = null;
				model.stateModel.street_to_open_map_to = null;
			} else {
				TSFrontController.instance.toggleHubMapDialog();
			}
		}
		
		private function onMouse(event:MouseEvent):void {
			const is_over:Boolean = event.type == MouseEvent.ROLL_OVER;
			map_icon.visible = !is_over;
			map_icon_hover.visible = is_over;
		}
		
		override public function get width():Number {
			return MiniMapView.instance.w + (icon_holder.visible ? name_holder.x : 0);
		}
	}
}