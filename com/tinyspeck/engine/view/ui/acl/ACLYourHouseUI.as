package com.tinyspeck.engine.view.ui.acl
{
	import com.tinyspeck.engine.data.acl.ACL;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.ACLManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.Graphics;
	import flash.text.TextField;

	public class ACLYourHouseUI extends TSSpriteWithModel
	{
		private static const HOLDER_W:uint = 89;
		private static const HOLDER_H:uint = 72;
		private static const PADD:uint = 12;
		
		private var create_bt:Button;
		private var keys_given_ui:ACLKeysGivenUI;
				
		private var your_house_tf:TextField = new TextField();
				
		private var is_built:Boolean;
		
		public function ACLYourHouseUI(w:int){
			_w = w;
		}
		
		private function buildBase():void {
			//bg
			var g:Graphics = graphics;
			g.beginFill(0xfafafa);
			g.drawRect(0, 0, _w, HOLDER_H + PADD*2);
			
			//tf
			TFUtil.prepTF(your_house_tf);
			your_house_tf.y = 20;
			your_house_tf.width = _w;
			your_house_tf.htmlText = '<p class="acl_your_house_give">Want to let your friends come and go as they please?</p>';
			
			addChild(your_house_tf);
			
			//button
			create_bt = new Button({
				name: 'create',
				label: 'Give out a key',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			create_bt.x = int(_w/2 - create_bt.width/2);
			create_bt.y = int(your_house_tf.y + your_house_tf.height + 5);
			create_bt.addEventListener(TSEvent.CHANGED, onCreateClick, false, 0, true);
			addChild(create_bt);
			
			//keys given
			keys_given_ui = new ACLKeysGivenUI(_w);
			keys_given_ui.y = HOLDER_H + PADD*2;
			addChild(keys_given_ui);
			
			is_built = true;
			
			hide();
		}
		
		public function show():void {
			const pc:PC = model.worldModel.pc;
			if(!pc) return;
			
			//figure out which TSID we are using
			const pc_home_tsid:String = !pc.pol_tsid && pc.home_info ? pc.home_info.interior_tsid : pc.pol_tsid;
			if(!pc_home_tsid) return;
			if(!is_built) buildBase();
			
			scaleX = scaleY = 1;
			
			//update the data
			update();
			
			visible = true;
		}
		
		public function hide():void {
			visible = false;
			scaleX = scaleY = .05;
		}
		
		private function update():void {
			if(!is_built) buildBase();
			
			//show the keys you've given out
			const acl:ACL = ACLManager.instance.acl;
			keys_given_ui.show(acl ? acl.keys_given : null);
		}
		
		private function onCreateClick(event:TSEvent):void {
			if(create_bt.disabled) return;
			
			dispatchEvent(new TSEvent(TSEvent.CHANGED));
		}
		
		override public function get height():Number {
			return keys_given_ui ? (keys_given_ui.y + keys_given_ui.height) * scaleY : 0;
		}
	}
}