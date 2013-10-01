package com.tinyspeck.engine.view.ui.quest
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.quest.Quest;
	import com.tinyspeck.engine.data.requirement.Requirement;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.port.QuestManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.maps.MiniMapView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSScroller;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;

	public class QuestTracker extends Sprite implements IRefreshListener, IMoveListener
	{
		/* singleton boilerplate */
		public static const instance:QuestTracker = new QuestTracker();
		
		private var top_holder:Sprite = new Sprite();
		private var bottom_holder:Sprite = new Sprite();
		
		private var tfs:Vector.<TextField> = new Vector.<TextField>();
		
		private var scroller:TSScroller;
		private var model:TSModelLocator;
		private var pin_bt:Button;
		private var current_reqs:Vector.<Requirement>;
		
		private var bottom_rect:Rectangle = new Rectangle();
		
		private var w:int;
		private var last_x:int;
		private var last_y:int;
		private var last_scroll_h:int;
		
		private var is_built:Boolean;
		private var visible_before_move:Boolean;
		private var is_pinned:Boolean = true;
		
		public function QuestTracker(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		private function buildBase():void {
			w = MiniMapView.MAX_ALLOWABLE_MAP_WIDTH;
			model = TSModelLocator.instance;
			
			var g:Graphics = top_holder.graphics;
			g.beginFill(0, .3);
			g.drawRect(0, 0, w, 12);
			top_holder.addEventListener(MouseEvent.MOUSE_DOWN, onTopMouseDown, false, 0, true);
			top_holder.visible = false;
			addChild(top_holder);
			
			const bt_wh:int = top_holder.height - 4;
			pin_bt = new Button({
				name: 'pin',
				w: bt_wh,
				h: bt_wh,
				tip: {
					txt:'Unpin',
					pointer:WindowBorder.POINTER_BOTTOM_CENTER
				}
			});
			pin_bt.x = int(w - pin_bt.width - 4);
			pin_bt.y = 2;
			pin_bt.addEventListener(TSEvent.CHANGED, togglePin, false, 0, true);
			addChild(pin_bt);
			
			scroller = new TSScroller({
				name: 'tracker',
				bar_wh: 6,
				bar_color: 0xecf0f1,
				bar_border_color: 0xd2dadc,
				bar_border_width: 1,
				bar_alpha: 0,
				bar_handle_color: 0xcfdcdd,
				bar_handle_border_color: 0xb0bfc2,
				bar_handle_stripes_alpha: 0,
				bar_handle_min_h: 10,
				use_refresh_timer: false,
				allow_clickthrough: true
			});
			scroller.w = w;
			scroller.y = top_holder.height;
			addChild(scroller);
			
			g = bottom_holder.graphics;
			g.beginFill(0, .3);
			g.drawRect(0, 0, w, 4);
			bottom_holder.addEventListener(MouseEvent.MOUSE_DOWN, onBottomMouseDown, false, 0, true);
			bottom_holder.visible = false;
			addChild(bottom_holder);
			
			//set the top of the rect to be scroller min height
			bottom_rect.y = scroller.y + 15;
			
			//let's clicks pass through
			mouseEnabled = false;
			
			is_built = true;
		}
		
		public function show():void {
			if(!is_built) buildBase();
			
			//add it to view
			TSFrontController.instance.getMainView().addView(this);
			
			//get the quests that are on this street
			TSFrontController.instance.registerMoveListener(this);
			showQuests();
			
			//refresh
			TSFrontController.instance.registerRefreshListener(this);
			refresh();
			
			//listen to updates
			QuestManager.instance.addEventListener(TSEvent.QUEST_UPDATED, onQuestUpdate, false, 0, true);
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
			
			TSFrontController.instance.unRegisterRefreshListener(this);
			TSFrontController.instance.removeMoveListener(this);
			
			QuestManager.instance.removeEventListener(TSEvent.QUEST_UPDATED, onQuestUpdate);
		}
		
		public function refresh():void {
			if(!model) return;
			
			const lm:LayoutModel = model.layoutModel;
			if(is_pinned){
				//put it under the mini map and above the contact list expand button
				y = MiniMapView.instance.y + MiniMapView.instance.h + lm.header_h;
				x = lm.gutter_w + lm.loc_vp_w - w;
				scroller.h = lm.loc_vp_h/2 - y - 10;
			}
			else {
				//make sure this sucker isn't too big
				scroller.h = !last_scroll_h ? 200 : last_scroll_h;
			}
			bottom_holder.y = int(scroller.y + scroller.height);
		}
		
		private function showQuests():void {
			const tf_padd:int = 3;
			var total:int = tfs.length;
			var req:Requirement;
			var tf:TextField;
			var i:int;
			var next_y:int;
			
			//reset the pool
			for(i = 0; i < total; i++){
				tf = tfs[int(i)];
				if(tf.parent) tf.parent.removeChild(tf);
			}
			
			//places the reqs where they should be
			current_reqs = model.worldModel.getQuestReqsOnStreet();
			total = current_reqs.length;
			for(i = 0; i < total; i++){
				req = current_reqs[int(i)];
				
				if(tfs.length > i){
					tf = tfs[int(i)];
				}
				else {
					tf = new TextField();
					TFUtil.prepTF(tf);
					tf.width = w - 10;
					tf.filters = StaticFilters.copyFilterArrayFromObject(
						{blurX:2, blurY:2, alpha:.5}, 
						StaticFilters.black_GlowA
					).concat(StaticFilters.black1px90Degrees_DropShadowA);
					tf.mouseEnabled = false;
					tf.alpha = .9;
					tfs.push(tf);
				}
				
				tf.y = next_y;
				tf.name = req.id;
				scroller.body.addChild(tf);
				
				updateReq(req);
				next_y += tf.height + tf_padd;
			}
		}
		
		private function updateReq(req:Requirement):void {
			//ghetto for now (should do something to catch the eye when changed or completed, maybe)
			const tf:TextField = scroller.body.getChildByName(req.id) as TextField;
			if(tf){
				var txt:String = req.desc;
				if(req.is_count && req.need_num > 1){
					txt += ' ('+req.got_num+'/'+req.need_num+')';
				}
				tf.htmlText = '<p class="quest_tracker">'+txt+'</p>';
			}
		}
		
		private function togglePin(event:Event = null):void {
			is_pinned = !is_pinned;
			
			//don't want them to resize if it's pinned
			bottom_holder.visible = !is_pinned;
			top_holder.visible = !is_pinned;
			
			//update the pin tip
			pin_bt.tip = {
				txt: is_pinned ? 'Unpin' : 'Pin',
				pointer:WindowBorder.POINTER_BOTTOM_CENTER
			}
			
			refresh();
		}
		
		private function onQuestUpdate(event:TSEvent):void {
			const quest:Quest = event.data as Quest;
			if(!quest) return;
			
			//do we care about this quest?
			const total:int = quest.reqs.length;
			var i:int;
			var j:int;
			var req:Requirement;
			
			for(i = 0; i < total; i++){
				req = quest.reqs[int(i)];
				for(j = 0; j < current_reqs.length; j++){
					//match up?
					if(req.id == current_reqs[int(j)].id){
						//update it
						updateReq(req);
					}
				}
			}
		}
		
		private function onTopMouseDown(event:MouseEvent):void {
			startDrag();
			StageBeacon.mouse_up_sig.add(onTopEndDrag);
			StageBeacon.mouse_move_sig.add(onDrag);
		}
		
		private function onDrag(event:MouseEvent):void {
			//checkBounds();
			last_x = x;
			last_y = y;
		}
		
		private function onTopEndDrag(event:MouseEvent):void {	
			stopDrag();
			StageBeacon.mouse_up_sig.remove(onTopEndDrag);
			StageBeacon.mouse_move_sig.remove(onDrag);
		}
		
		private function onBottomMouseDown(event:MouseEvent):void {
			//set the bounds
			bottom_rect.height = 500;
			
			bottom_holder.startDrag(false, bottom_rect);
			StageBeacon.mouse_up_sig.add(onBottomEndDrag);
			StageBeacon.mouse_move_sig.add(onResize);
		}
		
		private function onResize(event:MouseEvent):void {
			//set the scroller size
			last_scroll_h = bottom_holder.y - scroller.y;
			scroller.h = last_scroll_h;
		}
		
		private function onBottomEndDrag(event:MouseEvent):void {
			bottom_holder.stopDrag();
			StageBeacon.mouse_up_sig.remove(onBottomEndDrag);
			StageBeacon.mouse_move_sig.remove(onResize);
		}
		
		////////////////////////////////////////////////////////////////////////////////
		//////// IMoveListener /////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		public function moveLocationHasChanged():void {}
		public function moveLocationAssetsAreReady():void {}
		
		public function moveMoveStarted():void {
			//hide this
			if(parent) {
				visible_before_move = true;
				parent.removeChild(this);
			}
		}
		
		public function moveMoveEnded():void {
			//if we need to show this again
			if(visible_before_move){
				//add it to view
				TSFrontController.instance.getMainView().addView(this);
				x = last_x;
				y = last_y;
				
				//update the stuff that's on the street
				showQuests();
				
				refresh();
			}
		}
	}
}