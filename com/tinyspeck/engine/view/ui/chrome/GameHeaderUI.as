package com.tinyspeck.engine.view.ui.chrome
{
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.port.RightSideView;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.view.gameoverlay.AudioControl;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Hotkeys;
	import com.tinyspeck.engine.vo.GameTimeVO;
	
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.system.Capabilities;

	public class GameHeaderUI extends TSSpriteWithModel implements IRefreshListener
	{		
		CONFIG::god private var god_menu:GodMenu = new GodMenu();
		private var bug_bt:Button;
		private var help_bt:Button;
		private var audio_control:AudioControl = new AudioControl();
		private var date_time:DateTimeUI = new DateTimeUI();
		
		private var is_built:Boolean;
		
		public function GameHeaderUI(){}
		
		private function buildBase():void {
			const head_h:int = model.layoutModel.header_h;
			var tip_txt:String;
			var next_x:int;
			
			//god menu
			CONFIG::god {
				addChild(god_menu);
				god_menu.show();
				god_menu.x = next_x;
				god_menu.y = int(head_h/2 - god_menu.icon.height/2);
				next_x += god_menu.icon.width + 15;
			}
			
			//bug icon
			if(!model.flashVarModel.no_bug) {
				tip_txt = 'Report a bug';
				if(model.flashVarModel.disable_bug_reporting){
					//show a special tip if they can't report bugs
					tip_txt = '<p class="bug_tip">';
					tip_txt += 'Bug reporting is unavailable<br>';
					tip_txt += '<span class="bug_tip_explanation">You\'re using an unsupported web browser or Flash Player (' + Capabilities.version + ')</span>';
					tip_txt += '</p>';
				}
				
				bug_bt = createButton(
					onBugClick,
					new AssetManager.instance.assets.bug_icon(),
					new AssetManager.instance.assets.bug_icon_disabled(),
					'bug',
					tip_txt);
				bug_bt.x = next_x;
				bug_bt.y = int(head_h/2 - bug_bt.height/2);
				if(model.flashVarModel.disable_bug_reporting) bug_bt.disabled = true;
				addChild(bug_bt);
				next_x += bug_bt.width + 7;
			}
			
			//help button
			tip_txt = 'Need help?';
			help_bt = createButton(
				onHelpClick,
				new AssetManager.instance.assets.help_icon(),
				new AssetManager.instance.assets.help_icon_disabled(),
				'help',
				tip_txt);
			addChild(help_bt);
			help_bt.x = next_x;
			help_bt.y = int(head_h/2 - help_bt.height/2);
			next_x += help_bt.width + 6;
			
			//audio controls
			audio_control.init();
			audio_control.x = next_x - 7;
			audio_control.y = int(model.layoutModel.header_h/2 - audio_control.icon.height/2 + 2);
			next_x += audio_control.icon.width + 6;
			addChild(audio_control);
			
			//date/time
			model.timeModel.registerCBProp(onTimeTick, "gameTime");
			onTimeTick(model.timeModel.gameTime);
			date_time.x = next_x;
			date_time.y = int(head_h/2 - date_time.height/2);
			
			addChild(date_time);
			
			//refresh listening
			TSFrontController.instance.registerRefreshListener(this);
			
			is_built = true;
		}
		
		public function show():void {
			if(!is_built) buildBase();
		}
		
		public function refresh():void {
			const lm:LayoutModel = model.layoutModel;
			x = int(lm.overall_w - width/2 - RightSideView.MIN_WIDTH_CLOSED/2);
			
			CONFIG::god {
				//refresh the god menu
				god_menu.refreshMenu();
			}
		}
		
		public function getDateTimeCenterPt():Point {
			return date_time.localToGlobal(new Point(date_time.width/2, date_time.height));
		}
		
		public function getVolumeCenterPt():Point {
			return audio_control.getVolumeIconBasePt();
		}
		
		public function getHelpIconCenterPt():Point {
			return help_bt.localToGlobal(new Point(help_bt.width/2, help_bt.height/2));
		}
		
		private function createButton(callback:Function, normal:DisplayObject, disabled:DisplayObject, name:String, tip:String):Button {
			const btn:Button = new Button({
				w: normal.width,
				h: normal.height,
				name: name,
				draw_alpha: 0,
				graphic: normal,
				graphic_disabled: disabled,
				tip: {
					txt: tip, 
					pointer:WindowBorder.POINTER_TOP_CENTER,
					offset_y: 10
				}
			});
			btn.addEventListener(TSEvent.CHANGED, callback, false, 0, true);
			return btn;
		}
		
		private function onBugClick(event:TSEvent):void {
			if (bug_bt.disabled) return;
			
			//they want to toggle the bug UI
			if(!BootError.is_bug_open){
				TSFrontController.instance.setCameraDeets();
				BootError.openBugReportUI();
			}
			else {
				BootError.closeBugReportUI();
			}
		}
		
		private function onHelpClick(event:TSEvent):void {
			if(help_bt.disabled) return;
			
			//toggle the hotkeys
			Hotkeys.instance.show(true);
		}
		
		private function onTimeTick(gameTimeVO:GameTimeVO):void {
			//update the time and make sure we are centered up
			date_time.show(gameTimeVO);
			refresh();
		}
		
		public function set hide_help(value:Boolean):void {
			//we may need to hide the help options
			if(!is_built) return;
			
			help_bt.tip = {
				txt:value ? 'Not available just yet!' : 'Need help?', 
				pointer:WindowBorder.POINTER_TOP_CENTER,
				offset_y: 10
			};
			help_bt.disabled = value;
		}
	}
}