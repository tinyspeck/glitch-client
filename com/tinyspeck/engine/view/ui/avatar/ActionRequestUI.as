package com.tinyspeck.engine.view.ui.avatar
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.client.ActionRequest;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.port.ActionRequestManager;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.TradeManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.utils.Timer;

	public class ActionRequestUI extends TSSpriteWithModel
	{
		private static const BT_PADD:uint = 5;
		
		private var timer:Timer;
		private var current_request:ActionRequest;
		
		private var spinner:MovieClip;
		private var button_holder:Sprite;
		
		private var tf:TextField;
		
		private var current_secs_left:uint;
		
		private var is_built:Boolean;
		private var show_spinner:Boolean;
		
		public function ActionRequestUI(){}
		
		private function buildBase():void {
			//tf
			tf = new TextField();
			TFUtil.prepTF(tf, false);
			tf.embedFonts = false;
			addChild(tf);
			
			//button holder
			button_holder = new Sprite();
			addChild(button_holder);
			
			//setup the waiting spinner
			const waiting_spinner:MovieClip = new AssetManager.instance.assets.spinner();
			waiting_spinner.addEventListener(Event.COMPLETE, onSpinnerComplete, false, 0, true);
			
			is_built = true;
		}
		
		public function show(request:ActionRequest):void {
			if(!is_built) buildBase();
			
			const is_you:Boolean = request.player_tsid == model.worldModel.pc.tsid ? true : false;
			
			current_request = request;
			name = request.uid || 'action_request';
			resetUI();
			setSpinner(false);
			
			//set up buttons and timers depending on the event type
			switch(request.event_type){
				case TSLinkedTextField.LINK_TRADE:
					//buttons
					addButton(is_you ? 'End trade' : 'Start negotation', is_you ? Button.TYPE_CANCEL : Button.TYPE_MINOR);
					if(is_you) {
						//add the timer and button only if it's you
						addButton('Edit', Button.TYPE_MINOR);
						setSpinner(true);
						setTimer(request.timeout_secs);
					}
					break;
				
				case TSLinkedTextField.LINK_GAME_ACCEPT:
				case TSLinkedTextField.LINK_QUEST_ACCEPT:
					addButton(is_you ? 'Cancel' : 'Accept', is_you ? Button.TYPE_CANCEL : Button.TYPE_MINOR);
					setSpinner(true);
					setText(request.need ? request.got+'/'+request.need+' joined' : 'waiting...');
					break;
				
				default:
					addButton(is_you ? 'Cancel' : 'Accept', is_you ? Button.TYPE_CANCEL : Button.TYPE_MINOR);
					setSpinner(true);
					setText(request.need ? request.got+'/'+request.need : 'waiting...');
					break;
			}
			
			visible = true;
		}
		
		public function hide():void {
			visible = false;
			
			//kill the timer
			if(timer){
				timer.stop();
				timer.removeEventListener(TimerEvent.TIMER, onTimerTick);
				timer = null;
			}
		}
		
		private function addButton(label:String, type:String):void {
			var i:int;
			var total:int = button_holder.numChildren;
			var bt:Button;
						
			//find one to use
			for(i; i < total; i++){
				if(!button_holder.getChildAt(i).visible) {
					bt = button_holder.getChildAt(i) as Button;
					break;
				}
			}
			
			//make a new one if we don't have one yet
			if(!bt){
				bt = new Button({
					name: 'bt_'+total
				});
				bt.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
				button_holder.addChild(bt);
			}
			
			//set the look
			bt.visible = true;
			bt.disabled = current_request.has_accepted;
			if(!bt.disabled) bt.disabled = ActionRequestManager.instance.hasRespondedToRequestUid(current_request.uid);
			bt.setSizeAndType(Button.SIZE_TINY, type);
			bt.label = label;
			bt.x = bt.name != 'bt_0' ? int(button_holder.width + BT_PADD) : 0;
		}
		
		private function resetUI():void {
			//allows us to resuse buttons!
			var i:int;
			var total:int = button_holder.numChildren;
			var bt:Button;
			
			for(i; i < total; i++){
				bt = button_holder.getChildAt(i) as Button;
				bt.label = '';
				bt.x = 0;
				bt.visible = false;
			}
			
			//let's reset the text too
			tf.text = '';
			tf.x = 0;
		}
		
		private function setText(txt:String):void {
			if(!txt) txt = '';
			tf.htmlText = '<p class="action_request_wait">'+txt+'</p>';
			tf.y = int(button_holder.height/2 - tf.height/2);
			tf.x = int(button_holder.width + (show_spinner ? 35 : 5));
		}
		
		private function setTimer(total_secs:uint):void {
			if(!total_secs) return;
			
			//create the timer and start'r up
			if(!timer){
				timer = new Timer(1000);
				timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
			}
			timer.reset();
			timer.start();
			
			current_secs_left = total_secs;
			onTimerTick();
		}
		
		private function setSpinner(is_visible:Boolean):void {
			//show the spinner
			if(spinner) {
				spinner.visible = is_visible;
				spinner.x = is_visible ? button_holder.width + 10 : 0;
			}
			
			show_spinner = is_visible;
		}
		
		private function onButtonClick(event:TSEvent):void {
			const bt:Button = event.data as Button;
			if(!bt || bt.disabled || !current_request) return;
			bt.disabled = true;
			const is_you:Boolean = current_request.player_tsid == model.worldModel.pc.tsid ? true : false;
			
			if(bt.type == Button.TYPE_CANCEL){
				//tell the server we are canceling this bad boy
				ActionRequestManager.instance.cancel(current_request, onCancel);
			}
			else if(!is_you){
				//if this is a trade, make sure they are able to make the trade
				if(current_request.event_type == TSLinkedTextField.LINK_TRADE && !TradeManager.instance.parseTradeLink(current_request.event_tsid)){
					bt.disabled = false;
					return;
				}
				
				//send the reply off to the server
				ActionRequestManager.instance.reply(current_request);
			}
			
			if(is_you) {
				//this is our own button(s)
				if(current_request.event_type == TSLinkedTextField.LINK_TRADE){
					//always disable the cancel button
					bt.disabled = bt.type == Button.TYPE_CANCEL;
					TradeManager.instance.localUpdate(bt.type == Button.TYPE_CANCEL);
				}
			}
			
			//let the manager know about this
			if(bt.type == Button.TYPE_CANCEL){
				ActionRequestManager.instance.removeRequestUid(current_request.uid);
			}
			else {
				ActionRequestManager.instance.addRequestUid(current_request.uid);
			}
		}
		
		private function onCancel(nrm:NetResponseMessageVO):void {
			if(nrm.success){
				hide();
				dispatchEvent(new TSEvent(TSEvent.CLOSE, this));
			}
			else if(!nrm.success && nrm.payload.error.msg) {
				showError(nrm.payload.error.msg);
			}
		}
		
		private function onTimerTick(event:TimerEvent = null):void {
			current_secs_left--;
			
			if(current_secs_left <= 0){
				//stop the timer and clear the text
				timer.stop();
				setText('');
				if(spinner) spinner.visible = false;
				
				//tell the server we are canceling this bad boy
				if(current_request.event_type == RightSideManager.instance.request_event_type && current_request.event_tsid == RightSideManager.instance.request_event_tsid){
					switch(current_request.event_type){
						case TSLinkedTextField.LINK_TRADE:
							//let the trade manager handle the cancel
							TradeManager.instance.localUpdate(true);
							break;
						default:
							//fire off the cancel
							ActionRequestManager.instance.cancel(current_request, onCancel);
							break;
					}
				}
				
				//disable all the buttons
				var i:int;
				var total:int = button_holder.numChildren;
				var bt:Button;
				
				for(i; i < total; i++){
					bt = button_holder.getChildAt(i) as Button;
					bt.disabled = true;
				}
				
				return;
			}
			
			const time_left:String = StringUtil.formatSecsAsDigitalClock(current_secs_left, false);
			
			switch(current_request.event_type){
				case TSLinkedTextField.LINK_TRADE:
					setText(time_left+' left');
					break;
			}
		}
		
		private function onSpinnerComplete(event:Event):void {
			spinner = event.currentTarget as MovieClip;
			spinner.scaleX = spinner.scaleY = .6;
			spinner.y = 2;
			addChild(spinner);
			
			setSpinner(show_spinner);
		}
		
		private function showError(txt:String):void {
			if(txt && model){
				model.activityModel.activity_message = Activity.fromAnonymous({txt: 'Uh oh: '+txt});
				SoundMaster.instance.playSound('CLICK_FAILURE');
				CONFIG::debugging {
					Console.warn('ActionUI Error');
				}
			}
		}
		
		override public function dispose():void {
			super.dispose();
			SpriteUtil.clean(button_holder);
			SpriteUtil.clean(this);
			if(timer) {
				timer.removeEventListener(TimerEvent.TIMER, onTimerTick);
				timer = null;
			}
			tf = null;
			spinner = null;
			current_request = null;
			button_holder = null;
			is_built = false;
		}
	}
}