package com.tinyspeck.engine.view.ui.chat
{
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;

	public class OfflineContacts extends BaseContacts
	{
		private var toggle_bt:Button;
				
		private var _is_open:Boolean;
		
		public function OfflineContacts(offline_contacts:Array, w:int){
			super(w, ContactElement.TYPE_OFFLINE, offline_contacts);
			
			var arrow_holder:Sprite = new Sprite();
			var arrow:DisplayObject = new AssetManager.instance.assets.contact_arrow();
			SpriteUtil.setRegistrationPoint(arrow);
			arrow_holder.addChild(arrow);
			
			//put on the toggle button
			toggle_bt = new Button({
				name: 'toggle',
				label: '',
				label_c: 0x999999,
				label_hover_c: 0xd79035,
				label_face: 'Arial',
				text_align: 'left',
				graphic: arrow_holder,
				graphic_padd_w: 5,
				graphic_padd_t: arrow.height - 2,
				offset_x: 11,
				draw_alpha: 0,
				h: 16,
				w: w
			});
			setToggleLabel();
			toggle_bt.addEventListener(TSEvent.CHANGED, onToggleClick, false, 0, true);
			addChild(toggle_bt);
			
			//the holder for all the contacts
			contacts_holder.y = int(toggle_bt.height);
			contacts_holder.visible = false;
		}
		
		override public function addContact(pc_tsid:String, group_tsid:String = null):void {
			super.addContact(pc_tsid, group_tsid);
			
			//update the label
			setToggleLabel();
		}
		
		override public function removeContact(tsid:String):void {
			super.removeContact(tsid);
			
			//update the label
			setToggleLabel();
		}
		
		private function setToggleLabel():void {
			//if the label state is about to change, let things know
			if((toggle_bt.visible && contacts.length == 0) || (!toggle_bt.visible && contacts.length > 0)){
				dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
			}
			
			toggle_bt.label = 'Offline contacts ('+(contacts.length <= 99 ? contacts.length : '99+')+')';
			toggle_bt.visible = contacts.length > 0 ? true : false;
		}
		
		public function toggle(force_open:Boolean = false):void {
			if(force_open && _is_open) return;
			
			_is_open = !_is_open;
			if(force_open) _is_open = true;
			
			toggle_bt.graphic.rotation = is_open ? 90 : 0;
			contacts_holder.visible = is_open;
			
			dispatchEvent(new TSEvent(TSEvent.TOGGLE, this));
		}
		
		private function onToggleClick(event:TSEvent):void {
			toggle();
		}
		
		override public function get height():Number {
			return toggle_bt.visible ? toggle_bt.height + (_is_open ? contacts_holder.height : 0) : 0;
		}
		
		public function get is_open():Boolean { return _is_open; }
	}
}