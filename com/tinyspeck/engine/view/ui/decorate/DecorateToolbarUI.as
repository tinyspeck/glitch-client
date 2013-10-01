package com.tinyspeck.engine.view.ui.decorate
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.control.HandOfDecorator;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.house.HouseExpandCosts;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.FurnUpgradeDialog;
	import com.tinyspeck.engine.port.HouseExpandDialog;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.port.JobActionIndicatorView;
	import com.tinyspeck.engine.port.JobManager;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;

	public class DecorateToolbarUI extends Sprite implements IRefreshListener
	{
		public static const FADE_OUT_MS:Number = 200;
		
		private static const BUTTON_PADD:uint = 5;
		private static const things_to_listen_to:Vector.<Sprite> = new Vector.<Sprite>();
		
		private var all_holder:Sprite = new Sprite();
		
		private var title_tf:TextField = new TextField();
		private var esc_tf:TextField = new TextField();
		
		private var close_local_pt:Point;
		private var close_global_pt:Point;
		
		private var expand_wall_bt:Button;
		private var unexpand_wall_bt:Button;
		private var expand_floor_bt:Button;
		private var close_bt:Button;
		private var model:TSModelLocator;
		
		public function DecorateToolbarUI(){	
			model = TSModelLocator.instance;
			//tfs
			TFUtil.prepTF(title_tf, false);
			title_tf.htmlText = '<p class="decorate_toolbar">You are in Decoration Mode</p>';
			title_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			all_holder.addChild(title_tf);
			
			TFUtil.prepTF(esc_tf, false);
			esc_tf.htmlText = '<p class="decorate_toolbar"><span class="decorate_toolbar_esc">Use arrow keys to scroll • Press esc to exit</span></p>';
			esc_tf.x = int(title_tf.width - esc_tf.width);
			esc_tf.y = int(title_tf.height - 6);
			esc_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			all_holder.addChild(esc_tf);
			
			addChild(all_holder);
			
			//build out any nav buttons
			buildButtons();
			
			//setup the things we need to listen to
			things_to_listen_to.push(FurnUpgradeDialog.instance, HouseExpandDialog.instance);
			
			visible = false;
		}
		
		private var gap:int = 4;
		private function buildButtons():void {
			const bt_w:uint = 68;
			const bt_h:uint = model.layoutModel.header_h - 5;
			const bt_y:int = -2;
			var next_x:int = all_holder.width + 10;
			
			expand_wall_bt = new Button({
				name: 'expand_wall',
				label: 'Expand',
				graphic: new AssetManager.instance.assets.expand_wall(),
				graphic_placement: 'top',
				graphic_padd_t: 6,
				graphic_padd_b: -4,
				graphic_padd_l: 17,
				graphic_alpha: .7,
				focused_graphic_alpha: .9,
				size: Button.SIZE_TINY,
				type: Button.TYPE_DECORATE,
				w: bt_w,
				h: bt_h
			});
			expand_wall_bt.x = next_x;
			expand_wall_bt.y = bt_y;
			next_x += bt_w + gap;
			expand_wall_bt.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
			all_holder.addChild(expand_wall_bt);
			
			unexpand_wall_bt = new Button({
				name: 'unexpand_wall',
				label: 'Un-expand',
				graphic: new AssetManager.instance.assets.unexpand_wall(),
				graphic_placement: 'top',
				graphic_padd_t: 6,
				graphic_padd_b: -4,
				graphic_padd_l: 17,
				graphic_alpha: .7,
				focused_graphic_alpha: .9,
				size: Button.SIZE_TINY,
				type: Button.TYPE_DECORATE,
				w: bt_w,
				h: bt_h
			});
			unexpand_wall_bt.x = next_x;
			unexpand_wall_bt.y = bt_y;
			next_x += bt_w + gap;
			unexpand_wall_bt.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
			all_holder.addChild(unexpand_wall_bt);
			
			expand_floor_bt = new Button({
				name: 'expand_floor',
				label: 'Add floor',
				graphic: new AssetManager.instance.assets.expand_floor(),
				graphic_placement: 'top',
				graphic_padd_t: 6,
				graphic_padd_b: -4,
				graphic_padd_l: 17,
				graphic_alpha: .7,
				focused_graphic_alpha: .9,
				size: Button.SIZE_TINY,
				type: Button.TYPE_DECORATE,
				w: bt_w,
				h: bt_h
			});
			expand_floor_bt.x = next_x;
			expand_floor_bt.y = bt_y;
			next_x += bt_w + gap;
			expand_floor_bt.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
			all_holder.addChild(expand_floor_bt);
			
			//close button
			const close_DO:DisplayObject = new AssetManager.instance.assets.decorate_close();
			close_bt = new Button({
				name: 'close',
				graphic: close_DO,
				graphic_padd_w: 9,
				graphic_padd_t: 9,
				size: Button.SIZE_TINY,
				type: Button.TYPE_DECORATE,
				w: 28,
				h: 27
			});
			close_bt.y = int(bt_h/2 - close_bt.height/2);
			close_bt.addEventListener(TSEvent.CHANGED, onCloseClick, false, 0, true);
			close_local_pt = new Point(int(close_bt.width/2), int(close_bt.height));
			addChild(close_bt);
		}
		
		public function showHideButtons():void {
			var loc:Location = model.worldModel.location;
			var pc:PC = model.worldModel.pc;
			
			var show_swatches:Boolean = !loc.no_swatches_button;
			var show_add_floor:Boolean = !loc.no_expand_buttons;
			var show_expand:Boolean = !loc.no_expand_buttons && (pc.home_info.interior_tsid == loc.tsid);
			
			if (show_add_floor) {
				if (!expand_floor_bt.visible) {
					expand_floor_bt.visible = true;
				}
			} else {
				if (expand_floor_bt.visible) {
					expand_floor_bt.visible = false;
				}
			}
			
			if (show_expand) {
				if (!expand_wall_bt.visible) {
					expand_wall_bt.visible = true;
					if(unexpand_wall_bt) unexpand_wall_bt.visible = true;
				}
				if (!unexpand_wall_bt) {
					expand_floor_bt.x = expand_wall_bt.x + expand_wall_bt.width + gap + 1;
				} else {
					expand_floor_bt.x = unexpand_wall_bt.x + unexpand_wall_bt.width + gap + 1;
				}
			} else {
				if (expand_wall_bt.visible) {
					expand_wall_bt.visible = false;
					if(unexpand_wall_bt) unexpand_wall_bt.visible = false;
				}
				
				expand_floor_bt.x = expand_wall_bt.x;
			}
		}
		
		public function show():void {
			TSTweener.removeTweens(this);
			visible = true;
			TSFrontController.instance.registerRefreshListener(this);
			refresh();
			alpha = 1;
			close_bt.disabled = false;
			
			//listen to the dialogs that we control
			setListeners(true);
			
			//make sure the esc text is hiding
			esc_tf.alpha = 0;
			
			//bounce in the text
			all_holder.y = -all_holder.height - 10;
			const end_y:int = model.layoutModel.header_h/2 - all_holder.height/2;
			TSTweener.addTween(all_holder, {y:end_y, time:.7, transition:'easeOutBounce', onComplete:onBounceComplete});
			
			showHideButtons();
		}
		
		/**
		 * Should only be called via YDM's hideDecorateToolbar()
		 */		
		public function hide():void {
			TSFrontController.instance.unRegisterRefreshListener(this);
			
			//stop listening
			setListeners(false);
			
			//fade it out
			TSTweener.addTween(this, {alpha:0, time:FADE_OUT_MS/1000, transition:'linear', onComplete:onHideComplete});
		}
		
		public function refresh():void {
			close_bt.x = int(model.layoutModel.header_bt_x - close_bt.width);
			
			//center it
			all_holder.x = int(close_bt.x/2 - all_holder.width/2);
		}
		
		public function getCloseButtonBasePt():Point {
			close_global_pt = close_bt.localToGlobal(close_local_pt);
			return close_global_pt;
		}
		
		private function setListeners(is_add:Boolean):void {
			//we care about when things have started/ended
			var i:int;
			var total:int = things_to_listen_to.length;
			var sp:Sprite;
			
			for(i; i < total; i++){
				sp = things_to_listen_to[int(i)];
				if(is_add){
					sp.addEventListener(TSEvent.STARTED, onThingsToListenToChanged, false, 0, true);
					sp.addEventListener(TSEvent.CLOSE, onThingsToListenToChanged, false, 0, true);
				}
				else {
					sp.removeEventListener(TSEvent.STARTED, onThingsToListenToChanged);
					sp.removeEventListener(TSEvent.CLOSE, onThingsToListenToChanged);
				}
			}
		}
		
		private function onThingsToListenToChanged(event:TSEvent):void {
			//check to see if anything has a parent, if so, fade out the "press ESC" text
			//but since "end" dispatches FIRST then removes the child, we can't... So work around time!
			
			var i:int;
			var total:int = things_to_listen_to.length;
			var hide_esc:Boolean;
			var sp:Sprite;
			
			//if something has started no matter what we hide it
			if(event.type == TSEvent.STARTED){
				hide_esc = true;
			}
			else {
				//if we are closing, we gotta do some extra magic
				for(i; i < total; i++){
					sp = things_to_listen_to[int(i)];
					if(sp.parent && sp != event.data){
						//still have something up, keep hiding the esc
						hide_esc = true;
						break;
					}
				}
			}
			
			//animate it all pretty like
			TSTweener.addTween(esc_tf, {alpha:hide_esc ? 0 : 1, time:.2, delay:.1, transition:'linear'});
		}
		
		private function onBounceComplete():void {
			TSTweener.addTween(esc_tf, {alpha:1, time:.2, transition:'linear'});
		}
		
		private function onCloseClick(event:TSEvent):void {
			if(close_bt.disabled) return;
			
			if (HandOfDecorator.instance.promptForSaveIfPreviewingSwatch(true)) {
				return;
			}
			
			close_bt.disabled = true;
			
			//closed the toolbar, shut down the decorator
			TSFrontController.instance.stopDecoratorMode();
		}
		
		private function onButtonClick(event:TSEvent):void {
			//all button clicks that trigger an element should go through this
			const bt:Button = event.data as Button;
			if(bt.disabled) return;
			
			if(bt == expand_wall_bt){
				HouseExpandDialog.instance.startWithType(HouseExpandCosts.TYPE_WALL);
			}
			else if(bt == expand_floor_bt){
				// see if there is a furn_door with a job first!
				var itemstack:Itemstack;
				var door_array:Array = model.worldModel.getLocationItemstacksAByItemClass('furniture_door');
				for (var i:int=0;i<door_array.length;i++) {
					itemstack = door_array[i];
					var jaiv:JobActionIndicatorView = JobManager.instance.getIndicator(itemstack.tsid);
					if (jaiv) {
						jaiv.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
						return;
					}
				}
				
				HouseExpandDialog.instance.startWithType(HouseExpandCosts.TYPE_FLOOR);
			}
			else if(bt == unexpand_wall_bt){
				HouseExpandDialog.instance.startWithType(HouseExpandCosts.TYPE_UNEXPAND);
			}
		}
		
		private function onHideComplete():void {			
			visible = false;
		}
	}
}