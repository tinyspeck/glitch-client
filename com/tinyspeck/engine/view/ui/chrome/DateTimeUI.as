package com.tinyspeck.engine.view.ui.chrome
{
	import com.tinyspeck.engine.port.DateTimeDialog;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.vo.GameTimeVO;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class DateTimeUI extends TSSpriteWithModel implements ITipProvider
	{
		private var date_tf:TextField = new TextField();
		
		private var is_built:Boolean;
		
		public function DateTimeUI(){}
		
		private function buildBase():void {
			TFUtil.prepTF(date_tf);
			date_tf.wordWrap = false; //allows the date to auto-size but be multi-line
			date_tf.mouseEnabled = false;
			addChild(date_tf);
			
			//tip
			TipDisplayManager.instance.registerTipTrigger(this);
			
			//mouse stuff
			useHandCursor = buttonMode = true;
			addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
			
			is_built = true;
		}
		
		/**
		 * Updates the game time 
		 * @param gameTimeVO
		 */		
		public function show(gameTimeVO:GameTimeVO):void {
			if(!is_built) buildBase();
			if(!gameTimeVO || !gameTimeVO.time) return;
			
			date_tf.htmlText = '<p class="game_header_date">'+gameTimeVO.week_day+'<br>'+
				'<span class="game_header_date_time">'+gameTimeVO.time+'&nbsp;'+gameTimeVO.ampm.toLowerCase()+'</span><br>'+
				gameTimeVO.month_day_with_suffix+'&nbsp;of&nbsp;'+gameTimeVO.month;
			
			const g:Graphics = graphics;
			g.clear();
			g.beginFill(0, 0);
			g.drawRect(0, 0, date_tf.width, date_tf.height);
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target) return null;
			
			var txt:String = (model.flashVarModel.hi_viral) ? 'Daily limits and things' : 'Check your daily limits';
			
			return {
				txt: txt,
				pointer: WindowBorder.POINTER_TOP_CENTER,
				offset_y: -2
			}
		}
		
		private function onClick(event:MouseEvent):void {
			//open the dialog
			DateTimeDialog.instance.start();
		}
	}
}