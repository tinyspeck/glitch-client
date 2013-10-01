package com.tinyspeck.engine.view.ui.acl
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.ACLManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.ui.Button;

	public class ACLKeyGivenElementUI extends ACLKeyElementUI
	{		
		private static var confirm_vo:ConfirmationDialogVO;
		
		private var revoke_bt:Button;
		
		public function ACLKeyGivenElementUI(){}
		
		override protected function buildBase():void {
			//set the vars if they are different than the default
			HEIGHT = 55;
			
			//set the stuff from css
			const cssm:CSSManager = CSSManager.instance;
			bg_color = cssm.getUintColorValueFromStyle('acl_key_given_element', 'backgroundColor', 0xffffff);
			border_color = cssm.getUintColorValueFromStyle('acl_key_given_element', 'borderColor', 0xdcdcdc);
			_border_width = cssm.getNumberValueFromStyle('acl_key_given_element', 'borderWidth', 1);
			
			//revoke
			revoke_bt = new Button({
				name: 'revoke',
				label: 'Revoke key',
				size: Button.SIZE_TINY,
				type: Button.TYPE_MINOR
			});
			revoke_bt.y = int(HEIGHT/2 - revoke_bt.height/2 - border_width);
			revoke_bt.addEventListener(TSEvent.CHANGED, onRevokeClick, false, 0, true);
			addChild(revoke_bt);
			
			//revoke confirm
			if(!confirm_vo){
				confirm_vo = new ConfirmationDialogVO(
					null,
					'',
					[
						{value: true, label: 'Yes'},
						{value: false, label: 'No'}
					],
					false
				)
			}
			
			super.buildBase();
		}
		
		override protected function showBody():void {
			if(!current_key.pc_tsid) return;
			
			const pc:PC = model.worldModel.getPCByTsid(current_key.pc_tsid);
			if(!pc) return;
			
			//revoke
			revoke_bt.disabled = false;
			revoke_bt.x = _w - revoke_bt.width - PADD;
			
			const received_secs:int = TSFrontController.instance.getCurrentGameTimeInUnixTimestamp() - current_key.received;
			const received_str:String = StringUtil.formatTime(received_secs, false);
			
			var body_txt:String = '<p class="acl_key_given_element">';
			body_txt += pc.label+'<br>';
			body_txt += '<span class="acl_key_given_element_received">Given a key '+(received_secs >= 43200 ? received_str : 'not long')+' ago</span>';
			body_txt += '</p>';
			
			body_tf.htmlText = body_txt;
			body_tf.width = int(revoke_bt.x - body_holder.x);
			body_tf.y = int(HEIGHT/2 - body_tf.height/2);
		}
		
		private function onRevokeClick(event:TSEvent):void {
			SoundMaster.instance.playSound(!revoke_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(revoke_bt.disabled) return;
			
			const pc:PC = model.worldModel.getPCByTsid(current_key.pc_tsid);
			
			//toss up the confirmation dialog asking if they want to revoke
			confirm_vo.txt = "Are you sure you want to revoke <b>"+StringUtil.nameApostrophe(pc.label)+"</b> access to your house? " +
							 "If they're currently in your house, they'll be kicked out.";
			confirm_vo.callback = onRevokeConfirm;
			TSFrontController.instance.confirm(confirm_vo);
		}
		
		private function onRevokeConfirm(is_revoke:Boolean):void {
			revoke_bt.disabled = is_revoke;
			
			if(is_revoke){
				//tell the server to revoke the key
				ACLManager.instance.changeAccess(current_key.pc_tsid, false);
			}
		}
	}
}