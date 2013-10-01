package com.tinyspeck.engine.view.ui.acl
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.ACLManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.Sprite;

	public class ACLKeyReceivedElementUI extends ACLKeyElementUI
	{	
		private static const HOUSE_W:uint = 75;
		private static const MAX_LOC_LABEL:uint = 25;
		
		private var house_holder:Sprite = new Sprite();
		
		private var visit_bt:Button;
				
		public function ACLKeyReceivedElementUI(){}
		
		override protected function buildBase():void {
			//make sure the height is right
			HEIGHT = 55;
			
			//set the stuff from css
			const cssm:CSSManager = CSSManager.instance;
			bg_color = cssm.getUintColorValueFromStyle('acl_key_received_element', 'backgroundColor', 0xffffff);
			border_color = cssm.getUintColorValueFromStyle('acl_key_received_element', 'borderColor', 0xdcdcdc);
			_border_width = cssm.getNumberValueFromStyle('acl_key_received_element', 'borderWidth', 1);
			
			//visit
			visit_bt = new Button({
				name: 'visit',
				label: 'Visit',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			visit_bt.y = int(HEIGHT/2 - visit_bt.height/2 - border_width);
			visit_bt.addEventListener(TSEvent.CHANGED, onVisitClick, false, 0, true);
			addChild(visit_bt);
			
			super.buildBase();
		}

		override protected function showBody():void {
			if(!current_key.pc_tsid || !current_key.location_tsid) return;
			
			const pc:PC = model.worldModel.getPCByTsid(current_key.pc_tsid);
			if(!pc) return;
			
			const location:Location = model.worldModel.getLocationByTsid(current_key.location_tsid);
			if(!location) return;
			
			//set the visit button
			visit_bt.x = int(_w - visit_bt.width - PADD);
			
			const received_secs:int = TSFrontController.instance.getCurrentGameTimeInUnixTimestamp() - current_key.received;
			const received_str:String = StringUtil.formatTime(received_secs, false);
			
			var body_txt:String = '<p class="acl_key_received_element">';
			body_txt += pc.label+'<br>';
			body_txt += '<span class="acl_key_given_element_received">';
			body_txt += 'Gave you a key '+(received_secs >= 43200 ? received_str : 'not long')+' ago';
			body_txt += '</span>';
			body_txt += '</p>';
			
			body_tf.htmlText = body_txt;
			
			//set visit
			body_tf.width = int(visit_bt.x - body_holder.x - PADD);
			visit_bt.disabled = location == model.worldModel.location;
			visit_bt.tip = visit_bt.disabled ? {txt:'You are already here!', pointer:WindowBorder.POINTER_BOTTOM_CENTER} : null;
			
			//center it
			body_holder.y = int(HEIGHT/2 - body_holder.height/2);
		}
		
		private function onVisitClick(event:TSEvent):void {
			SoundMaster.instance.playSound(!visit_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(visit_bt.disabled) return;
			
			//tell the server we wanna do this
			ACLManager.instance.visitPlayer(current_key.pc_tsid);
		}
	}
}