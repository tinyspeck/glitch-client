package com.tinyspeck.engine.view.ui.chat
{
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;

	public class GroupContacts extends BaseContacts
	{	
		private static const MAX_BEFORE_TOGGLE:uint = 5;
		
		private var toggle_bt:Button;
		
		private var _is_open:Boolean;
		
		public function GroupContacts(groups:Array, w:int){
			super(w, ContactElement.TYPE_GROUP, null, groups);
			
			const arrow_holder:Sprite = new Sprite();
			const arrow:DisplayObject = new AssetManager.instance.assets.contact_arrow();
			//arrow.transform.colorTransform = ColorUtil.getColorTransform(0x548500);
			SpriteUtil.setRegistrationPoint(arrow);
			arrow_holder.addChild(arrow);
			
			//put on the toggle button
			toggle_bt = new Button({
				name: 'toggle',
				label: '',
				label_c: 0x548500,
				label_bold: true,
				label_face: 'Arial',
				label_hover_c: 0xd79035,
				text_align: 'left',
				graphic: arrow_holder,
				graphic_padd_w: 5,
				graphic_padd_t: arrow.height - 1,
				offset_x: 11,
				draw_alpha: 0,
				h: 16,
				w: w
			});
			setToggleLabel();
			toggle_bt.addEventListener(TSEvent.CHANGED, onToggleClick, false, 0, true);
			addChild(toggle_bt);
			
			//the holder for all the contacts
			contacts_holder.visible = groups.length <= MAX_BEFORE_TOGGLE;
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
			var total:uint = groups.length;
			toggle_bt.label = 'Groups ('+(total <= 99 ? total : '99+')+')';
			
			//get the number of ALL the groups (even open active ones) so the toggle button is smarter about things
			total = model.worldModel.getGroupsTsids(false).length;
			toggle_bt.visible = total > MAX_BEFORE_TOGGLE && groups.length ? true : false;
			
			contacts_holder.x = total > MAX_BEFORE_TOGGLE ? 13 : 0;
			contacts_holder.y = total > MAX_BEFORE_TOGGLE ? int(toggle_bt.height) : 0;
			if(total <= MAX_BEFORE_TOGGLE){
				contacts_holder.visible = true;
			}
			else if(!_is_open){
				contacts_holder.visible = false;
			}
			
			dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
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
			if(toggle_bt){
				const visible_height:Number = toggle_bt.height + (_is_open ? contacts_holder.height : 0);
				const total:uint = groups.length;
				if(toggle_bt.visible){
					return visible_height;
				}
				else if(total > 0){
					return contacts_holder.height;
				}
			}				
			
			return 0;
		}
		
		public function get is_open():Boolean { return _is_open; }
	}
}