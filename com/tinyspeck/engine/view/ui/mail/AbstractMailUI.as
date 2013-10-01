package com.tinyspeck.engine.view.ui.mail
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.pack.FurnitureBagUI;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.port.CurrencyInput;
	import com.tinyspeck.engine.port.Cursor;
	import com.tinyspeck.engine.port.IPackChange;
	import com.tinyspeck.engine.port.MailManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.DragVO;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class AbstractMailUI extends TSSpriteWithModel implements IPackChange
	{
		public static const RESTRICTED_ITEMS:Array = ['hogtied_piggy'];
		protected var dragVO:DragVO = DragVO.vo;
		protected var drag_good:Boolean;
		protected var cost_tf:TextField = new TextField();
		public var send_bt:Button;
		protected var currants_qp:CurrencyInput = new CurrencyInput();
		protected var cost_to_send:int;
		
		public function AbstractMailUI(w:int){
			_w = w;
		}
		
		protected function listenToThings():void {
			//listen to the pack
			PackDisplayManager.instance.addEventListener(TSEvent.DRAG_COMPLETE, onPackDragComplete, false, 0, true);
			PackDisplayManager.instance.addEventListener(TSEvent.DRAG_STARTED, onPackDragStart, false, 0, true);
			FurnitureBagUI.instance.addEventListener(TSEvent.DRAG_COMPLETE, onPackDragComplete, false, 0, true);
			FurnitureBagUI.instance.addEventListener(TSEvent.DRAG_STARTED, onPackDragStart, false, 0, true);
			
			//listen for stat updates (currants)
			model.worldModel.registerCBProp(onStatsChanged, "pc", "stats");
			
			//listen for cost requests
			MailManager.instance.addEventListener(TSEvent.CHANGED, onMailChange, false, 0, true);
		}
		
		protected function dontListenToThings():void {
			
			//stop listening
			PackDisplayManager.instance.unRegisterChangeSubscriber(this);
			PackDisplayManager.instance.removeEventListener(TSEvent.DRAG_STARTED, onPackDragStart);
			PackDisplayManager.instance.removeEventListener(TSEvent.DRAG_COMPLETE, onPackDragComplete);
			FurnitureBagUI.instance.removeEventListener(TSEvent.DRAG_COMPLETE, onPackDragComplete);
			FurnitureBagUI.instance.removeEventListener(TSEvent.DRAG_STARTED, onPackDragStart);
			model.worldModel.unRegisterCBProp(onStatsChanged, "pc", "stats");
			MailManager.instance.removeEventListener(TSEvent.CHANGED, onMailChange);
		}
		
		protected function isDroppable():Boolean {
			if(dragVO.dragged_itemstack.item.hasTags(['no_mail'])){
				//they are trying to drop an item that can't be mailed
				Cursor.instance.showTip('You can\'t mail this');
			}
			
			if (dragVO.dragged_itemstack.item.hasTags('no_mail') || dragVO.dragged_itemstack.is_soulbound_to_me){
				Cursor.instance.showTip('<font color="#cc0000">You can\'t mail this</font>');
				return false;
			}
			
			if (dragVO.dragged_itemstack.slots && model.worldModel.getItemstacksInContainerTsid(dragVO.dragged_itemstack.tsid).length){
				Cursor.instance.showTip('<font color="#cc0000">You can\'t mail a bug unless it is empty</font>');
			}
			
			return true;
		}
		
		protected function onPackDragStart(event:TSEvent):void {
			//some items are not allowed!
			if(RESTRICTED_ITEMS.indexOf(dragVO.dragged_itemstack.class_tsid) != -1) return;
			
			StageBeacon.mouse_move_sig.add(onPackDragMove);
			drag_good = false;
		}
		
		public function onPackChange():void {
			
		}
		
		protected function onPackDragMove(event:MouseEvent):void {
			
		}
		
		protected function onPackDragComplete(event:TSEvent):void {
			
		}
		
		protected function onStatsChanged(pc_stats:PCStats):void {
			
		}
		
		protected function updateSendButton():void {
			
		}
		
		private function onMailChange(event:TSEvent):void {
			//update the Send button
			updateSendButton();
			
			//update the cost
			updateCost();
		}
		
		protected function updateCost():void {
			const stats:PCStats = model.worldModel.pc ? model.worldModel.pc.stats : null;
			
			//get the cost to send stuff
			cost_to_send = MailManager.instance.cost_to_send;
			
			var cost_txt:String = '<p class="mail_reply_cost">Cost to send: <b>';
			if(stats && stats.currants < cost_to_send) cost_txt += '<span class="mail_reply_error">';
			cost_txt += StringUtil.formatNumberWithCommas(cost_to_send)+' '+(cost_to_send != 1 ? 'currants' : 'currant');
			if(stats && stats.currants < cost_to_send) cost_txt += '</span>';
			cost_txt += '</b></p>';
			cost_tf.htmlText = cost_txt;
			cost_tf.x = int(send_bt.x + send_bt.width - cost_tf.width + 4);
			
			//set the max
			if(stats && stats.currants){
				currants_qp.max_value = Math.min(999999999, stats.currants);
			}
			else {
				currants_qp.max_value = 999999999;
			}
		}
	}
}
