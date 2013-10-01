package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.api.APICall;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.BigDialog;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;


	public class TrophyGetInfoDialog extends BigDialog implements IFocusableComponent, ITipProvider
	{
		/* singleton boilerplate */
		public static const instance:TrophyGetInfoDialog = new TrophyGetInfoDialog();
		
		private const ICON_WH:uint = 100;
		private const ICON_POSITION:Point = new Point(296, 32);
		private const ITEMS_PER_ROW:uint = 8;
		private const ITEM_WH:uint = 40;
		
		private var icon_view:ItemIconView;
		private var api_call:APICall = new APICall();
		
		private var body_tf:TextField = new TextField();
		private var items:Sprite = new Sprite();
		private var itemstack_tsid:String;
		private var callback_msg_when_closed:String;
		
		public function TrophyGetInfoDialog()
		{
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = 430;
			_base_padd = 20;
			_head_min_h = 165;
			_body_min_h = 90;
			_foot_min_h = 0;
			_close_bt_padd_right = 10;
			_draggable = true;
			_construct();
		}
		
		public function init():void {
			model.stateModel.registerCBProp(showItemInfo, 'get_trophy_info_tsid');
		}
		
		override protected function _construct() : void {
			super._construct();
			
			// body tf
			TFUtil.prepTF(body_tf);
			body_tf.mouseEnabled = false;
			
			addChild(body_tf);
			addChild(items);
			addChild(_close_bt); //puts close button on the top of the DL
			
			//add the api listeners
			api_call.addEventListener(TSEvent.COMPLETE, onLoadComplete, false, 0, true);
			api_call.addEventListener(TSEvent.ERROR, onLoadError, false, 0, true);
		}
		
		public function showItemInfo(itemstack_tsid:String):void {
			end(true);
			this.itemstack_tsid = itemstack_tsid;
			start();
		}
				
		override public function end(release:Boolean):void {
			//clean stuff up
			var child:DisplayObject;
			
			while(items.numChildren > 0){
				child = items.getChildAt(0);
				TipDisplayManager.instance.unRegisterTipTrigger(child);
				items.removeChild(child);
				child = null;
			}
			
			super.end(release);
		}
		
		public function startFromServer(payload:Object):void {
			if('itemstack_tsid' in payload){
				if (payload.callback_msg_when_closed) {
					callback_msg_when_closed = payload.callback_msg_when_closed;
				}
				
				//set the model so it fires this up
				model.stateModel.get_trophy_info_tsid = payload.itemstack_tsid;
			}
			else {
				CONFIG::debugging {
					Console.warn('Can\'t view a trophy without an itemstack_tsid!');
				}
			}
		}
		
		override public function start():void {			
			if(!canStart(true)) return;
			
			//clean up
			SpriteUtil.clean(_scroller.body);
			
			if (!itemstack_tsid) {
				CONFIG::debugging {
					Console.warn('no item_class')
				}
				return;
			}

			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(itemstack_tsid);
			var item:Item = model.worldModel.getItemByTsid(itemstack.class_tsid);
			if (!item) {
				CONFIG::debugging {
					Console.warn('invalid item_class: '+itemstack_tsid)
				}
				return;
			}
			
			//set the title
			_setTitle('<p class="trophy_get_info_title">'+item.label+'</p>');
			
			// clean up old one.
			if (icon_view) {
				icon_view.parent.removeChild(icon_view);
				icon_view.dispose();
			} 
			
			icon_view = new ItemIconView(item.tsid, ICON_WH);
			icon_view.x = ICON_POSITION.x;
			icon_view.y = ICON_POSITION.y;
			icon_view.mouseEnabled = false;
			addChild(icon_view);
			
			//position the body text
			body_tf.width = ICON_POSITION.x - _base_padd*2;
						
			if(itemstack.trophy_items) {
				setBodyContentsText(itemstack.description, itemstack.date_aquired);
				displayIcons(itemstack.trophy_items);
			} 
			else {
				setBodyContentsText('Loading info...', '');
				api_call.itemstackInfo(model.stateModel.get_trophy_info_tsid);
			}
			
			super.start();
		}
		
		private function onLoadComplete(event:TSEvent):void {
			var itemstack:Itemstack = model.worldModel.getItemstackByTsid(model.stateModel.get_trophy_info_tsid);
			
			//inject the age and description
			if(!itemstack.date_aquired) itemstack.date_aquired = 'Date acquired unknown';
			if(!itemstack.description) itemstack.description = 'No description available';
			
			//show the description and the age
			setBodyContentsText(itemstack.description, itemstack.date_aquired);
			
			//show the collection icons
			displayIcons(itemstack.trophy_items);
		}
		
		private function onLoadError(event:TSEvent):void {
			setBodyContentsText('Hmm, something went kind of wrong, try getting info again if you could.', '');
		}
		
		private function setBodyContentsText(description:String, age:String):void {
			body_tf.htmlText =  '<p class="trophy_get_info_body">'+description+
								'<p class="trophy_get_info_gap"><br></p>'+
								'<span class="trophy_get_info_footer">'+age+'</span>'+
								'</p>';
		}
		
		private function displayIcons(trophy_items:Object):void {
			if(trophy_items){
				//loops through the itemstacks and places them there icons
				var current:int = 0;
				var item_icon:ItemIconView;
				var nextX:int = 0;
				var nextY:int = 0;
				var k:String;
				var index:int = 0;
				var tsid:String;
				
				while(trophy_items[index]){				
					current++;
					item_icon = new ItemIconView(trophy_items[index].class_tsid, ITEM_WH);
					item_icon.x = nextX;
					item_icon.y = nextY;
					nextX += ITEM_WH + 10;
					if(current == ITEMS_PER_ROW){
						current = 0;
						nextX = 0;
						nextY += ITEM_WH + 12;
					} 
					items.addChild(item_icon);
					TipDisplayManager.instance.registerTipTrigger(item_icon);
					
					//check if it has sound and add the little play button
					if(trophy_items[index].sound){
						addPlayButton(item_icon, trophy_items[index].sound);
					}
					
					index++;
				}
				
				items.x = int(_w/2 - items.width/2);
				items.y = _base_padd;
				
				//set the body
				_setBodyContents(items);
			}
			
			_jigger();
		}
		
		private function addPlayButton(item_icon:ItemIconView, sound_location:String):void {			
			var play_button:Sprite = new Sprite();
			play_button.addChild(new AssetManager.instance.assets.item_play_button());
			play_button.x = int(ITEM_WH - play_button.width);
			play_button.y = int(ITEM_WH - play_button.height);
			play_button.name = sound_location; // keep a reference of the sound location
			play_button.visible = false;
			
			//add some mouse action to the icon
			item_icon.buttonMode = item_icon.useHandCursor = true;
			item_icon.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { play_button.visible = true; }, false, 0, true);
			item_icon.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { play_button.visible = false; }, false, 0, true);
			item_icon.addEventListener(MouseEvent.CLICK, playSound, false, 0, true);
			item_icon.addChild(play_button);
		}
		
		private function playSound(event:MouseEvent):void {
			//snag the name of the current target and send it to the sound master
			if(!event.currentTarget.getChildAt(1)) return;
			
			const itemstack:Itemstack = model.worldModel.getItemstackByTsid(model.stateModel.get_trophy_info_tsid);
			if(itemstack && itemstack.trophy_items){
				//stop all the sounds first
				var k:String;
				for(k in itemstack.trophy_items){
					if('sound' in itemstack.trophy_items[k]){
						SoundMaster.instance.stopSound(itemstack.trophy_items[k].sound);
					}
				}
			}
			
			//set it as music so it cuts the ambient off
			SoundMaster.instance.playSound(event.currentTarget.getChildAt(1).name, 0, 0, true);
		}
		
		override protected function _jigger():void {
			super._jigger();
			
			_title_tf.y = _base_padd - 5;
			_close_bt.y = _close_bt_padd_right;
			
			body_tf.x = _title_tf.x;
			body_tf.y = int(_title_tf.y + _title_tf.height) + 4;
			
			if(body_tf.y + body_tf.height > _head_min_h){
				_head_h = int(body_tf.y + body_tf.height + 30);
			}
			
			_body_sp.y = _head_h;
			_body_sp.visible = _scroller.body.numChildren ? true : false;
			_body_h = _scroller.body.numChildren ? Math.max(_body_min_h, _scroller.body.height + _base_padd*2) : 0;
			
			_h = _head_h + _body_h + _foot_h;
			
			_draw();
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			var item_icon:ItemIconView = tip_target as ItemIconView;
			if(!item_icon) return null;
			return {
				txt: model.worldModel.getItemByTsid(item_icon.tsid).label,
					offset_y: -7,
					pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
	}
}