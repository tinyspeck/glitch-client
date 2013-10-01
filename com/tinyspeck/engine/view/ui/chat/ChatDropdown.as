package com.tinyspeck.engine.view.ui.chat
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.pc.PCParty;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSDropdown;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;

	public class ChatDropdown extends TSDropdown
	{
		public static const BT_WIDTH:uint = 23;
		public static const BT_HEIGHT:uint = 19;
		
		protected static const HEIGHT:uint = 19;
		protected static const CORNER_RADIUS:Number = 4.5;
		protected static const BUTTON_PADD:int = 5;
		protected static const BUTTON_LABEL_X:int = 3;
		
		protected var arrow_holder:Sprite = new Sprite();
		protected var top_line:Sprite = new Sprite();
		
		public function ChatDropdown(){
			//set the local vars all at once
			_h = HEIGHT;
			_button_padding = BUTTON_PADD;
			_button_label_x = BUTTON_LABEL_X;
			_corner_radius = CORNER_RADIUS;
			_auto_width = true;
			
			//the button size/type
			bt_size = Button.SIZE_VERB;
			bt_type = Button.TYPE_VERB;
			
			super.buildBase();
			
			//down arrow
			var arrow:DisplayObject = new AssetManager.instance.assets.back_arrow();
			SpriteUtil.setRegistrationPoint(arrow);
			arrow_holder.mouseChildren = arrow_holder.mouseEnabled = false;
			arrow_holder.addChild(arrow);
			arrow_holder.x = int(BT_WIDTH/2) + 1;
			arrow_holder.y = 10;
			arrow_holder.scaleY = -1;
			addChild(arrow_holder);
			
			//top line for when the menu is opened
			var g:Graphics = top_line.graphics;
			g.beginFill(0xffffff);
			g.drawRect(0, 0, BT_WIDTH-_border_width, 1);
			top_line.x = menu_holder.x + _border_width;
			top_line.y = BT_HEIGHT;
			top_line.visible = false;
			addChild(top_line);
		}
		
		public function init(tsid:String):void {
			this.tsid = tsid;
		}
		
		public function refreshMenu():void {
			cleanArrays();
	
			//addItem('Offer to Trade');
			//addItem('Invite to Game');
			
			// if it is an IM channel with another player
			if (model.worldModel.getPCByTsid(tsid)) {
				addItem('Report Abuse', TSFrontController.instance.startReportAbuseFromChat, tsid);
			}

			// if it is a Party Chat
			if (tsid == ChatArea.NAME_PARTY) {
				var party:PCParty = model.worldModel.party;
				CONFIG::debugging {
					Console.info('party:'+party);
				}
				if (party) {
					CONFIG::debugging {
						Console.info('party.amIInThePartySpace():'+party.amIInThePartySpace());
						Console.info('party.space_tsids:'+party.space_tsids);
					}
					// show this option if there is no party space (disabled), or if there is one but you are not in it
					if (!party.amIInThePartySpace()) {
						addItem({label: 'Join the party space', disabled:(!party.space_tsids.length)}, TSFrontController.instance.joinPartySpace);
					}
				}
			}
			
			addItem('Copy to Clipboard', RightSideManager.instance.chatCopy, tsid);
			if(model.flashVarModel.use_local_trade && tsid == ChatArea.NAME_LOCAL){
				addItem('Make a trade offer', RightSideManager.instance.localTradeStart);
			}
			if(tsid == ChatArea.NAME_LOCAL){
				addItem('Save full snap to your desktop', TSFrontController.instance.saveLocationImgFullSizeWithEverything);
				addItem('Save full snap (no items) ', TSFrontController.instance.saveLocationImgFullSize);
			}
			
			buildMenu();
		}
		
		override protected function buildMenu():void {
			super.buildMenu();
			
			//give the menu rounded corners on 3 sides
			const menu_h:int = menu_holder.height - 1;
			
			var g:Graphics = menu_holder.graphics;
			g.clear();
			g.lineStyle(_border_width, _border_color);
			g.beginFill(0xffffff);
			g.drawRoundRectComplex(0,0, _w, menu_h, 0, corner_radius, corner_radius, corner_radius);
		}
		
		override protected function toggleMenu():void {
			
			if (!is_open) refreshMenu();
			
			super.toggleMenu();
			
			const menu_y:int = is_open ? _h : -menu_holder.height;
			const tween_type:String = is_open ? 'easeOutCubic' : 'easeInCubic';
			
			//visual tweak
			arrow_holder.y = is_open ? 9 : 10;
			
			//flip the arrow
			TSTweener.removeTweens([arrow_holder, menu_holder]);
			TSTweener.addTween(arrow_holder, {scaleY:is_open ? 1 : -1, time:.2});
			TSTweener.addTween(menu_holder, {y:menu_y, time:.2, transition:tween_type, onComplete:onRollOut});
			
			//show the top line to hide the border
			top_line.visible = is_open;
		}
		
		override protected function onRollOver(event:MouseEvent=null):void {
			var g:Graphics = graphics;
			g.clear();
			g.lineStyle(border_width, border_color);
			g.beginFill(0xffffff);
			g.drawRoundRectComplex(0,0, BT_WIDTH, BT_HEIGHT, corner_radius, corner_radius, is_open ? 0 : corner_radius, is_open ? 0 : corner_radius);
		}
		
		override protected function onRollOut(event:MouseEvent=null):void {
			if(is_open) return;
			
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0, 0);
			g.drawRoundRectComplex(0,0, BT_WIDTH, BT_HEIGHT, corner_radius, corner_radius, corner_radius, corner_radius);
		}
	}
}