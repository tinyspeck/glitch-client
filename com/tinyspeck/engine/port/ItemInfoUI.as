package com.tinyspeck.engine.port {
	
	import com.tinyspeck.debug.API;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.api.APICall;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.item.ItemDetails;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;

	public class ItemInfoUI extends Sprite
	{
		protected const INFO_PADD:uint = 6;
		
		private var currants_holder:Sprite = new Sprite();
		private var pack_slot_holder:Sprite = new Sprite();
		private var durable_holder:Sprite = new Sprite();
		private var grow_time_holder:Sprite = new Sprite();
		private var scroll_padder:Shape = new Shape();
		protected var warnings_holder:Sprite = new Sprite();
		protected var tips_holder:Sprite = new Sprite();
		
		protected var model:TSModelLocator;
		protected var api_call:APICall = new APICall();
		
		protected var current_item_tsid:String;
		
		protected var body_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var show_currants:Boolean = true;
		private var is_built:Boolean;
		private var is_showing:Boolean;
		public var routing_location:Location;
		public var retrieved_routing:Boolean;
		
		protected var w:int;
		
		public function ItemInfoUI(w:int){
			model = TSModelLocator.instance;
			this.w = w;
			init();
		}
		
		private function init():void {
			// body tf
			TFUtil.prepTF(body_tf);
			body_tf.embedFonts = false;
			body_tf.width = w;
			addChild(body_tf);
			
			//warning/tip messages
			addChild(warnings_holder);
			addChild(tips_holder);
			
			//listeners
			api_call.addEventListener(TSEvent.COMPLETE, onLoadComplete, false, 0, true);
			api_call.addEventListener(TSEvent.ERROR, onLoadError, false, 0, true);
			//api_call.trace_output = true;
			
			var g:Graphics = scroll_padder.graphics;
			g.beginFill(0,0);
			g.drawRect(0, 0, 10, 10);
			addChild(scroll_padder);
		}
		
		private function buildBase():void {
			//place the holders for currants, slot and durability
			buildInfoHolder('currants');
			buildInfoHolder('pack_slot');
			buildInfoHolder('durable');
			buildInfoHolder('grow_time');
			addChild(currants_holder);
			addChild(pack_slot_holder);
			addChild(durable_holder);
			addChild(grow_time_holder);
			
			is_built = true;
		}
		
		public function preloadItems(item_tsids:Array):void {
			if(!item_tsids){
				CONFIG::debugging {
					Console.warn('Missing item_tsids!');
				}
				return;
			}
			
			is_showing = false;
			
			//clear out the old details
			var i:int;
			var item:Item;
			
			for(i; i < item_tsids.length; i++){
				item = model.worldModel.getItemByTsid(item_tsids[int(i)]);
				if(item) item.details = null;
			}
			
			api_call.itemsInfo(item_tsids);
		}
		
		private var routing_class:String;
		public function show(class_tsid:String, reload_data:Boolean, routing_class:String=null):void {
			var item:Item = model.worldModel.getItemByTsid(class_tsid);
			if(!item){
				CONFIG::debugging {
					Console.warn('Could not find item: '+class_tsid);
				}
				return;
			}
			
			routing_location = null;
			retrieved_routing = false;
			
			this.routing_class = routing_class;
			current_item_tsid = class_tsid;
			is_showing = true;
			
			if(!is_built) buildBase();
			
			//hide the holders
			currants_holder.visible = false;
			pack_slot_holder.visible = false;
			durable_holder.visible = false;
			grow_time_holder.visible = false;
			show_currants = false;
			
			SpriteUtil.clean(warnings_holder);
			SpriteUtil.clean(tips_holder);
			
			//if we don't need to request the data again, just show the body!
			if(!reload_data && item.details){
				setBody();
				return;
			}
			
			api_call.itemsInfo([class_tsid]);
			
			//loading
			setBodyText('<p>Loading info...</p>');
		}
		
		
		
		private function onFindNearestItem(success:Boolean, rsp:Object):void {
			if (rsp.routing_class && rsp.routing_class == routing_class) {
				retrieved_routing = true;
				if (rsp.street) {
					var loc:Location = model.worldModel.locations[rsp.street.street_tsid];
					routing_location = loc;
				}
				jigger();
			}
		}
		
		protected function onLoadComplete(event:TSEvent):void {
			dispatchEvent(new TSEvent(TSEvent.COMPLETE, this));
						
			if(is_showing){
				var item:Item = model.worldModel.getItemByTsid(current_item_tsid);
				if (item) setBody();
			}
		}
		
		protected function onLoadError(event:TSEvent):void {
			setBodyText('<p>Hmm, something went kind of wrong, can\'t seem to find information on this thing.</p>');
		}
		
		protected function setBodyText(txt:String):void {
			txt = StringUtil.injectClass(txt, 'p', 'get_info_body');
			body_tf.htmlText = '<p class="get_info">'+txt+'</p>';
		}
		
		private function setBody():void {
			var item:Item = model.worldModel.getItemByTsid(current_item_tsid);
			var item_details:ItemDetails = item.details;
			
			//response is the response from an API call
			var body_txt:String = '<p>Hmm, something went kind of wrong, can\'t seem to find information on this thing.</p>';
			
			//no response? dump the default text out then
			if(!item_details){
				setBodyText(body_txt);
				return;
			}
			
			//if info is present populate the body
			if(item_details.info) body_txt = item_details.info;
			
			//populate the body with the good stuff
			setBodyText(body_txt);
			
			//populate the warnings
			SpriteUtil.clean(warnings_holder);
			if(item_details.warnings.length > 0){
				buildInfoBlocks(item_details.warnings, true);
			}
			
			//populate the tips
			SpriteUtil.clean(tips_holder);
			if(item_details.tips.length > 0){
				buildInfoBlocks(item_details.tips, false);
			}	
			
			//check for currants, slots and durability
			if(item_details.base_cost && item_details.base_cost > 0){
				setInfoHolder('currants', 'Worth about <b>'+item_details.base_cost+' '+(item_details.base_cost != 1 ? 'currants' : 'currant')+'</b>');
				show_currants = true;
			}
			else if(!item_details.base_cost && item_details.max_stack > 0) {
				setInfoHolder('currants', 'Vendors will not buy this item');
				show_currants = true;
			}
			
			if(item_details.max_stack){
				setInfoHolder('pack_slot', 'Fits '+(item_details.max_stack == 1 ? '<b>only one</b>' : 'up to <b>'+item_details.max_stack+'</b>')+' in a backpack slot');
			}
			
			if(item_details.tool_wear){
				setInfoHolder('durable', 'Durable for around <b>'+item_details.tool_wear+'</b> units of wear');
			}
			
			if(item_details.grow_time){
				setInfoHolder('grow_time', 'Takes around <b>'+StringUtil.formatTime(item_details.grow_time)+'</b> to fully grow');
			}

			if (routing_class) {
				API.findNearestItem(routing_class, onFindNearestItem);
			} else {
				CONFIG::debugging {
					Console.info('NO ROUTING CLASS, and that\'s ok');
				}
			}
			
			jigger();
		}
				
		private function jigger():void {						
			//warning stuff
			warnings_holder.y = int(body_tf.y + body_tf.height + 10);
			
			//tips stuff
			tips_holder.y = int(warnings_holder.y + warnings_holder.height + 5);
			
			//holders
			var next_y:int = int(body_tf.y + body_tf.height) + 15;
			if(warnings_holder.numChildren > 0 || tips_holder.numChildren > 0){
				next_y = int(tips_holder.y + tips_holder.height) + 15;
			}
			currants_holder.x = pack_slot_holder.x = durable_holder.x = grow_time_holder.x = 5;
			currants_holder.y = pack_slot_holder.y = durable_holder.y = grow_time_holder.y = next_y;
			
			currants_holder.visible = show_currants;
			
			if(currants_holder.visible && pack_slot_holder.visible){
				next_y += currants_holder.height + 8;
			}
			
			pack_slot_holder.y = next_y;
			
			if(pack_slot_holder.visible && (durable_holder.visible || grow_time_holder.visible)){
				next_y += pack_slot_holder.height + 8;
			}
			
			durable_holder.y = next_y;
			
			if(durable_holder.visible && grow_time_holder.visible){
				next_y += durable_holder.height + 8;
			}
			
			grow_time_holder.y = next_y;
			
			if(durable_holder.visible && grow_time_holder.visible){
				next_y += grow_time_holder.height + 8;
			}
			
			//make this bad boy a little taller
			scroll_padder.y = grow_time_holder.y + grow_time_holder.height;
			
			//let the people who are listen know that we've changed
			dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
		}
		
		private function buildInfoHolder(type:String):void {
			var holder:Sprite = getInfoHolder(type);
			var icon:DisplayObject;
			var tf:TSLinkedTextField;
						
			if(holder){
				icon = new AssetManager.instance.assets['item_info_'+type]();
				if(icon){
					holder.addChild(icon);
					
					//setup the tf
					tf = new TSLinkedTextField();
					TFUtil.prepTF(tf, false);
					tf.embedFonts = false;
					tf.htmlText = '<p class="get_info_body">Placeholderp</p>';
					tf.name = 'tf';
					tf.x = icon.width + 6;
					tf.y = int(icon.height/2 - tf.height/2);
					
					holder.addChild(tf);
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('Not able to find the asset item_info_'+type);
					}
				}
				
				//hide by default
				holder.visible = false;
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('Type not reconized when passed to buildInfoHolder: '+type);
				}
			}
		}
		
		protected function setInfoHolder(type:String, txt:String):void {
			var holder:Sprite = getInfoHolder(type);
			
			if(holder){
				if(!txt) return;
				
				var tf:TSLinkedTextField = holder.getChildByName('tf') as TSLinkedTextField;
				
				if(tf){
					tf.htmlText = '<p class="get_info_body">'+txt+'</p>';
					
					holder.visible = true;
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('Could not find tf on '+type+'_holder');
					}
				}
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('Could not find holder to show: '+type+'_holder');
				}
			}
		}
		
		protected function getInfoHolder(type:String):Sprite {
			return this[type+'_holder'] as Sprite;
		}
		
		protected function buildInfoBlocks(infos:Vector.<String>, is_warning:Boolean):void {
			var g:Graphics;
			var next_y:int;
			var i:int;
			
			var tf:TSLinkedTextField;
			var tf_style:String = is_warning ? 'get_info_warning' : 'get_info_tip';
			var tf_link_style:String = is_warning ? 'get_info_link_warn' : 'get_info_link_tip';
			
			var holder:Sprite;
			var info_holder:Sprite = is_warning ? warnings_holder : tips_holder;
			var holder_color:uint = is_warning ? 0x89181b : 0xdfdabd;
			
			var icon:DisplayObject;
			var icon_name:String = is_warning ? 'info_warn' : 'info_tip';
			var icon_x:int = is_warning ? 9 : 11;
			var info_txt:String;
			
			for(i; i < infos.length; i++){
				icon = new AssetManager.instance.assets[icon_name]();
				icon.x = icon_x;
				icon.y = INFO_PADD + 1;
				
				//if any of the warnings/tips have an external URL in them, make sure we add event:external|URL_HERE
				info_txt = StringUtil.makeURLExternal(infos[int(i)]);
				
				tf = new TSLinkedTextField();
				TFUtil.prepTF(tf);
				tf.embedFonts = false;
				tf.x = 32;
				tf.y = INFO_PADD - 1;
				tf.width = w - INFO_PADD*2 - tf.x;
				tf.htmlText = '<p class="'+tf_style+'">'+StringUtil.injectClass(info_txt, 'a', tf_link_style)+'</p>';
				
				holder = new Sprite();
				g = holder.graphics;
				g.clear();
				g.beginFill(holder_color);
				g.drawRoundRect(0, 0, w, int(tf.height + INFO_PADD*2), 10);
				
				holder.addChild(icon);
				holder.addChild(tf);
				holder.y = next_y;
				
				next_y += holder.height + 5;
				
				info_holder.addChild(holder);
			}
		}
		
		public function showCurrants(value:Boolean):void {
			//force the visibility of the currants holder
			show_currants = value;
			jigger();
		}
	}
}