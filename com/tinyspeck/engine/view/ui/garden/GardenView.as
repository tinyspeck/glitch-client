package com.tinyspeck.engine.view.ui.garden
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.data.garden.Garden;
	import com.tinyspeck.engine.data.garden.GardenAction;
	import com.tinyspeck.engine.data.garden.GardenPlot;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.port.Cursor;
	import com.tinyspeck.engine.port.GardenManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	public class GardenView extends TSSpriteWithModel implements IFocusableComponent {
		
		private static const BASE_PADD_RIGHT:int = 85; //base column offset
		private static const PLOT_PADD_LEFT:int = 7;
		private static const PLOT_PADD_RIGHT:int = 5;
		private static const PLOT_PADD_TOP:int = -3;
		private static const ANI_TIME:Number = 1.5; //how long it takes to fade in plot changes
		
		private static var plot_details:GardenPlotDetails;
		private static var plot_width:int;
		private static var plot_height:int;
		
		private var plot_holder:Sprite = new Sprite();
		private var action_timer:Timer = new Timer(60000); //how long after an action happens that we let the garden glow
		private var overlay_pt:Point = new Point();
		private var bounds:Rectangle;
		
		private var current_garden:Garden;
		private var current_plots:Vector.<GardenPlotView>;
		private var focused_plot:GardenPlotView;
		
		private var updated_time:int;
		private var secs_since_update:int;
		
		private var has_focus:Boolean;
		private var is_built:Boolean;
		private var _is_owner:Boolean;
		private var _is_tending:Boolean;
		
		public function GardenView(){
			addEventListener(Event.ADDED_TO_STAGE, onStageAdded, false, 0, true);
			
			//listen for when pack drag events complete, so we can clear stuff
			PackDisplayManager.instance.addEventListener(TSEvent.DRAG_COMPLETE, onPackDragComplete, false, 0, true);
			
			//setup the action timer
			action_timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
		}
		
		public function build(garden:Garden):void {
			if(!garden) return;
			
			name = garden.itemstack_tsid;
			tsid = garden.itemstack_tsid;
			current_garden = garden;
			updated_time = getTimer();
			current_plots = new Vector.<GardenPlotView>();
			
			if(!plot_details) {
				plot_details = new GardenPlotDetails();
				plot_details.alpha = 0;
			}
			
			//set the offsets based on scale
			const scale:Number = model.worldModel.getItemstackByTsid(tsid).scale;
			const base_right:int = BASE_PADD_RIGHT * scale;
			const plot_left:int = PLOT_PADD_LEFT * scale;
			const plot_right:int = PLOT_PADD_RIGHT * scale;
			const plot_top:int = PLOT_PADD_TOP * scale;
			
			//let's see if we are allowed to touch it
			setOwners();
			
			var i:int;
			var chunks:Array;
			var style:String;
			var style_cols:int;
			var base:MovieClip;
			var plot_view:GardenPlotView;
			var next_x:int;
			var row:int = garden.rows-1;
			var col:int;
			
			//put down the bed
			chunks = garden.style.split('_');
			style = chunks[0];
			style_cols = chunks.length > 1 ? chunks[1] : 1;
			
			//try to get the base right out of the gate
			base = GardenSWFData.garden_mc.getAssetByName(style+'_'+garden.rows+'_'+garden.cols);
			if(base){
				base.width *= scale;
				base.height *= scale;
				addChild(base);
			}
			else{
				for(i = 0; i < garden.cols/style_cols; i++){
					base = GardenSWFData.garden_mc.getAssetByName(style+'_'+garden.rows+'_'+style_cols);
					if(base){
						base.width *= scale;
						base.height *= scale;
						base.x = next_x;
						next_x += base_right*style_cols;
						addChild(base);
					}
				}
			}
			
			addChild(plot_holder);
			
			//lay out the plots, backwards for nice Z ordering
			for(i = garden.plots.length-1; i >= 0; i--){
				plot_view = new GardenPlotView(garden.plots[int(i)], current_garden.max_water_time-current_garden.water_threshold, garden);
				if(_is_owner){
					plot_view.addEventListener(MouseEvent.ROLL_OVER, onPlotMouseOver, false, 0, true);
					plot_view.addEventListener(MouseEvent.ROLL_OUT, onPlotMouseOut, false, 0, true);
					plot_view.addEventListener(MouseEvent.CLICK, onPlotClick, false, 0, true);
					plot_view.addEventListener(TSEvent.DRAG_COMPLETE, onPlotDrop, false, 0, true);
					
					current_plots.push(plot_view);
				}
				if(!plot_width){
					//plots have the scale applied to them already
					plot_width = plot_view.base_width;
					plot_height = plot_view.base_height;
				}
				
				//get the current col
				col = garden.plots[int(i)].plot_id % garden.cols;
				
				//place the plot in the right spot
				plot_view.x = plot_left + (((plot_width/2+plot_right)*row) + (base_right*col));
				plot_view.y = (plot_height + plot_top) * (garden.rows-1 - row);
				
				plot_holder.addChild(plot_view);
				
				if(col == 0){
					row--;
				}
			}
			
			//place it
			place();
			
			is_built = true;
			
			registerSelfAsFocusableComponent();
			
			//if we happen to be tending at the time of a rebuild, make sure the first plot gets focus
			if(is_tending){
				highlightPlot(GardenPlotView(plot_holder.getChildByName('plot_0')));
			}
			
			/*
			var sp:Sprite = new Sprite();
			var g:Graphics = sp.graphics;
			g.beginFill(0, .5);
			g.drawRect(0, 0, width, height);
			addChild(sp);
			*/
		}
		
		/**
		 * Get the list of our current plots to use with hit testing 
		 * @return the plots!
		 */		
		public function getPlotViews():Vector.<GardenPlotView> {			
			return current_plots;
		}
		
		public function getPointForOverlay(annc:Announcement):Point {			
			overlay_pt.x = 0;
			overlay_pt.y = 0;
			var plot_view:GardenPlotView = plot_holder.getChildByName('plot_'+annc.plot_id) as GardenPlotView;
			
			if(plot_view){
				//different overlays need different offsets so they line up nice with the plot
				//default is the watering_can
				var x_offset:int = 50;
				if(annc.item_class == 'hoe') {
					x_offset = 42;
				}
				else if(annc.item_class == 'guano'){
					x_offset = 25;
				}
				overlay_pt.x = int(parent.parent.x - width/2 - bounds.x + plot_view.x + plot_width/2 + x_offset);
				overlay_pt.y = int(parent.parent.y - height + plot_view.y);
				
				//if this is not flipped, offset the X
				if(!annc.h_flipped) overlay_pt.x -= x_offset*2;
				
				//if this is a hoe, bump the Y a little bit
				if(annc.item_class == 'hoe'){
					overlay_pt.y += 15;
				}
			}
			
			return overlay_pt;
		}
		
		public function update(garden:Garden):void {
			if(!is_built){
				build(garden);
			}
			else {
				//check to see if we have different numbers of plots showing vs. the update (or a differnet style)
				if(current_plots.length != garden.plots.length || current_garden.style != garden.style){
					clean();
					build(garden);
					return;
				}
				
				updated_time = getTimer();
				
				var i:int;
				var plot:GardenPlot;
				var changed_plots:Vector.<GardenPlot> = getChangedPlots(garden.plots);
				var new_plot:GardenPlotView;
				var old_plot:GardenPlotView;
				var new_plots:Array = new Array();
				var old_plots:Array = new Array();
				var old_focused:Boolean = false;
				
				for(i = 0; i < changed_plots.length; i++){
					//build a NEW plot, lay it over the old one and then crossfade
					plot = changed_plots[int(i)];
					old_plot = plot_holder.getChildByName('plot_'+plot.plot_id) as GardenPlotView;

					if(old_plot){
						if(_is_owner){
							old_plot.removeEventListener(MouseEvent.ROLL_OVER, onPlotMouseOver);
							old_plot.removeEventListener(MouseEvent.ROLL_OUT, onPlotMouseOut);
							old_plot.removeEventListener(MouseEvent.CLICK, onPlotClick);
							old_plot.removeEventListener(TSEvent.DRAG_COMPLETE, onPlotDrop);
							
							//run unhighlightPlot on the old plot
							unhighlightPlot(old_plot);
							old_plot.unhighlightOnDragOut();
							
							current_plots.splice(current_plots.indexOf(old_plot), 1);
							
							if(focused_plot == old_plot) old_focused = true;
						}
						
						old_plot.name = 'plot_old_'+plot.plot_id;
						old_plots.push(old_plot);
					} 
					
					new_plot = new GardenPlotView(plot, current_garden.max_water_time-current_garden.water_threshold, garden);
					new_plot.x = old_plot.x;
					new_plot.y = old_plot.y;
					new_plot.alpha = 0;
					if(_is_owner){
						new_plot.addEventListener(MouseEvent.ROLL_OVER, onPlotMouseOver, false, 0, true);
						new_plot.addEventListener(MouseEvent.ROLL_OUT, onPlotMouseOut, false, 0, true);
						new_plot.addEventListener(MouseEvent.CLICK, onPlotClick, false, 0, true);
						new_plot.addEventListener(TSEvent.DRAG_COMPLETE, onPlotDrop, false, 0, true);
						
						current_plots.push(new_plot);
						
						//if this old plot was focused, give it love
						if(old_focused){
							focused_plot = new_plot;
							old_focused = false;
						}
					}
					new_plots.push(new_plot);
					
					plot_holder.addChildAt(new_plot, plot_holder.getChildIndex(old_plot));
				}
				
				//animate the transition
				if(new_plots.length){
					TSTweener.addTween(old_plots, {alpha:0, time:ANI_TIME, transition:'linear', onComplete:removeOldPlots, onCompleteParams:[old_plots]});
					TSTweener.addTween(new_plots, {alpha:1, time:ANI_TIME, transition:'linear'});
				}
				
				//set the current garden to be this new one
				current_garden = garden;
				
				//place it
				place();
				
				//make sure to set the new plot focus
				if(is_tending && focused_plot){
					var plot_view:GardenPlotView = plot_holder.getChildByName('plot_'+focused_plot.plot.plot_id) as GardenPlotView;
					highlightPlot(plot_view);
				}
			}
		}
		
		private function place():void {			
			//set the x/y
			bounds = this.getBounds(this);
			x = -int(width/2 + bounds.x); //make the X be what eric made it before!
			y = -int(height);
			
			/*
			var g:Graphics = this.graphics;
			g.clear();
			g.lineStyle(0, 0, 0);
			g.beginFill(0, 1);
			g.drawRect(bounds.x, bounds.y, bounds.width, bounds.height);
			g.beginFill(0xffffff, 1);
			g.drawRect(bounds.x+(bounds.width/2), bounds.y, bounds.width/2, bounds.height);
			*/
		}
		
		private function removeOldPlots(old_plots:Array):void {
			var i:int;
			
			for(i; i < old_plots.length; i++){
				if(old_plots[int(i)].parent) old_plots[int(i)].parent.removeChild(old_plots[int(i)]);
			}
		}
		
		private function getChangedPlots(new_plots:Vector.<GardenPlot>):Vector.<GardenPlot> {
			//loop through the current plots and 
			var plots:Vector.<GardenPlot> = new Vector.<GardenPlot>();
			var i:int;
			var old_plot:GardenPlot;
			var new_plot:GardenPlot;
			var changed:Boolean;
			var k:String;
			
			for(i; i < new_plots.length; i++){
				old_plot = getPlotById(new_plots[int(i)].plot_id);
				new_plot = new_plots[int(i)];
				changed = false;
				
				//did anything change?
				if(old_plot.class_tsid != new_plot.class_tsid) changed = true;
				if(old_plot.grow_time < new_plot.grow_time) changed = true;
				if(old_plot.harvestable != new_plot.harvestable) changed = true;
				if(old_plot.label != new_plot.label) changed = true;
				if(old_plot.mature_level != new_plot.mature_level) changed = true;
				if(old_plot.max_grow_time != new_plot.max_grow_time) changed = true;
				if(old_plot.fertilized != new_plot.fertilized) changed = true;
				if((old_plot.water_time == 0 && new_plot.water_time > 0) || (old_plot.water_time > 0 && new_plot.water_time == 0)){
					changed = true;
				}
				
				if(changed) plots.push(new_plot);
			}
			
			return plots;
		}
		
		private function getPlotById(plot_id:int):GardenPlot {
			var i:int;
			
			for(i; i < current_garden.plots.length; i++){
				if(current_garden.plots[int(i)].plot_id == plot_id) return current_garden.plots[int(i)];
			}
			
			return null;
		}
		
		private function onPlotMouseOver(event:MouseEvent):void {
			if(!is_owner) return;
			if (getTimer() - StageBeacon.last_mouse_move > 1000) return;
			
			var plot_view:GardenPlotView = event.currentTarget as GardenPlotView;
			highlightPlot(plot_view);
		}
		
		public function highlightPlot(plot_view:GardenPlotView, item_tsid:String = ''):void {
			if(!is_owner) return;
			if(!plot_view) return;
			
			if(focused_plot) focused_plot.unhighlightOnDragOut();
			
			//check to see if the item passed in is even good to go forward with
			if(item_tsid && !GardenManager.instance.isUsableItem(item_tsid, current_garden)){
				return;
			}
			else if(!item_tsid && Cursor.instance.is_dragging){
				//no item and the cursor is dragging, bad scene, bail out
				return;
			}
			
			var plot:GardenPlot = getPlotById(plot_view.plot.plot_id);
			var pt:Point = parent.localToGlobal(new Point(plot_view.x + plot_view.base_width/2 - width/2 - plot_details.width/2, 30));
			
			focused_plot = GardenPlotView(plot_view);
			
			//figure out the elapsed seconds since the plot was updated
			secs_since_update = (getTimer() - updated_time)/1000;
			plot_details.show(plot, secs_since_update, current_garden, item_tsid);
			
			//position the details
			if(pt.x < model.layoutModel.min_gutter_w/2) pt.x =  model.layoutModel.min_gutter_w/2; //make sure it doesn't fall off the left side
			plot_details.x = int(pt.x);
			plot_details.y = int(pt.y);
			
			TSTweener.removeTweens(plot_details);
			TSTweener.addTween(plot_details, {alpha:1, time:.1, transition:'linear'});
			
			//put a glow on the plot
			plot_view.highlightOnDragOver();
			
			//make sure we can see it
			TSFrontController.instance.getMainView().addView(plot_details);
			
			unglow(true);
		}
		
		private function onPlotMouseOut(event:MouseEvent):void {			
			//if(is_tending || Cursor.instance.is_dragging) return;
			
			var plot_view:GardenPlotView = event.currentTarget as GardenPlotView;
			unhighlightPlot(plot_view);
		}
		
		private function unhighlightPlot(plot_view:GardenPlotView):void {			
			if(is_tending || Cursor.instance.is_dragging) return;
			if(!plot_view) return;
			
			//clear out any timers that were running			
			TSTweener.removeTweens(plot_details);
			TSTweener.addTween(plot_details, {alpha:0, time:.3, transition:'linear', delay:.5, onComplete:onDetailsFadeOutTweenComplete});
			
			//remove glow
			plot_view.unhighlightOnDragOut();
		}
		
		private function onPlotClick(event:MouseEvent, plot_view:GardenPlotView = null):void {
			if(!is_owner) return;
			
			//if god wants to do something, let 'em (handled in GardenManager onGardenClick)
			CONFIG::god {
				if(KeyBeacon.instance.pressed(Keyboard.K) || KeyBeacon.instance.pressed(Keyboard.P)) {
					return;
				}
			}
			
			//if they are tending and we aren't focused on this, don't let em do it
			if(is_tending && model.stateModel.focused_component != this){
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
				//if the player can't move, and is not tending, don't let them click
			else if(!is_tending && !(model.stateModel.focused_component is TSMainView)){
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			} 
			
			//get the plot data
			if(event && !plot_view) plot_view = event.currentTarget as GardenPlotView;
			var plot:GardenPlot = getPlotById(plot_view.plot.plot_id);
			var action:String;
			
			//make a click perform the best action
			if(plot.harvestable){
				//see if this player is allowed to take the crops
				if(plot.planter_tsid && plot.planter_tsid != model.worldModel.pc.tsid){
					action = null;
					model.activityModel.activity_message = Activity.createFromCurrentPlayer('Another player planted those seeds, give them time to snag them up!');
				}
				else {
					action = GardenAction.PICK;
				}
			}
			else if(plot.mature_level == 4){
				action = model.worldModel.pc.hasItemsFromList(GardenManager.HOE_TOOLS).length > 0 ? GardenAction.HOE : null;
			}
			else if(plot.mature_level == 5){
				//depleted, can't do a damn thing
				action = null;
			}
			else if(plot.mature_level == 0 && plot.water_time > 0){
				//do fancy stuff for planting seeds
				const seed_list:Array = model.worldModel.getItemTsidsByTags(current_garden.type != Garden.TYPE_DEFAULT ? current_garden.type+'_seed' : 'seed');
				var have_seeds:Array = model.worldModel.pc.hasItemsFromList(seed_list);
				
				if(have_seeds.length){
					TSFrontController.instance.startGardenPlotMenu(current_garden.itemstack_tsid, plot, [GardenAction.PLANT]);
					SoundMaster.instance.playSound('CLICK_SUCCESS');
					return;
				}
				//no seeds, throw something in chat
				else {
					if (parent.parent is LocationItemstackView) {
						var lis_view:LocationItemstackView = parent.parent as LocationItemstackView;
						lis_view.bubbleHandler({txt:'You don\'t have any seeds to plant!'});
					} else {
						model.activityModel.activity_message = Activity.createFromCurrentPlayer('You don\'t have any seeds to plant!');
					}
				}
			}
			else if(doesPlotNeedWater(plot)){
				action = model.worldModel.pc.hasItemsFromList(GardenManager.WATER_TOOLS).length > 0 ? GardenAction.WATER : null;
			}
			else if((plot.mature_level == 1 || plot.mature_level == 2) 
				&& !plot.fertilized 
				&& model.worldModel.pc.hasItemsFromList(GardenManager.FERTILIZER).length > 0 
				&& plot.water_time >= current_garden.max_water_time * GardenManager.FERTILIZE_PERC){
				
				//toss some guano on there
				action = GardenAction.FERTILIZE;
			}
			
			if(action) {
				if (GardenManager.instance.sendAction(current_garden.itemstack_tsid, plot.plot_id, action)) {
					SoundMaster.instance.playSound('CLICK_SUCCESS');
				}
			}
			else {
				SoundMaster.instance.playSound('CLICK_FAILURE');
			}
		}
		
		public function doesPlotNeedWater(plot:GardenPlot):Boolean {
			if(plot.water_time - secs_since_update < current_garden.max_water_time - current_garden.water_threshold) return true;
			return false;
		}
		
		private function onPlotDrop(event:TSEvent):void {
			if(!is_owner) return;
			
			var plot_view:GardenPlotView = event.data as GardenPlotView;
			
			//check to see if we are in tend mode or not, if not, remove the glow on drop
			if(!is_tending) plot_view.unhighlightOnDragOut();
			
			if(plot_view.last_action){
				GardenManager.instance.sendAction(current_garden.itemstack_tsid, plot_view.plot.plot_id, plot_view.last_action, plot_view.last_seed_tsid);
			}
		}
		
		private function hidePlotDetails():void {
			//make sure we can't see it			
			plot_details.hide();
			if(TSFrontController.instance.getMainView().contains(plot_details)){
				TSFrontController.instance.getMainView().removeChild(plot_details);
			}
		}
		
		private function onDetailsFadeOutTweenComplete():void {
			hidePlotDetails();
			//check to see if we are close enough to make it glow
			checkGlow();
		}
		
		private function onStageAdded(event:Event):void {
			checkGlow();
		}
		
		private function onPackDragComplete(event:TSEvent):void {
			if(is_tending) {
				//make sure our slot is back in focus
				if(focused_plot) focused_plot.highlightOnDragOver();
				return;
			}
			
			//clear out any timers that were running			
			TSTweener.removeTweens(plot_details);
			TSTweener.addTween(plot_details, {alpha:0, time:.3, transition:'linear', delay:.5, onComplete:onDetailsFadeOutTweenComplete});
		}
		
		private function onKeyDown(event:KeyboardEvent):void {
			if(!focused_plot) return;
			
			var plot_id:uint = focused_plot.plot.plot_id;
			var legit_key:Boolean = true;
			
			//which way do we go!
			switch(event.keyCode){
				case Keyboard.UP:
				case Keyboard.W:
					//go to the bottom right
					if(plot_id == current_garden.cols*current_garden.rows - current_garden.cols){
						plot_id = current_garden.cols-1;
					}
					//prev col
					else if(plot_id >= (current_garden.cols*current_garden.rows)-current_garden.cols){
						plot_id = (plot_id % current_garden.cols)-1;
					}
					//prev row
					else {
						plot_id += current_garden.cols;
					}
					break;
				case Keyboard.RIGHT:
				case Keyboard.D:
					//go to the top left
					if(plot_id == current_garden.cols-1){
						plot_id = current_garden.cols * (current_garden.rows-1);
					}
					//go to next row
					else if(plot_id % current_garden.cols == current_garden.cols-1){
						plot_id -= current_garden.cols*2-1;
					}
					//shuffle to the right
					else {
						plot_id++;
					}
					break;
				case Keyboard.DOWN:
				case Keyboard.S:
					//go to the top left
					if(plot_id == current_garden.cols-1){
						plot_id = current_garden.cols * (current_garden.rows-1);
					}
					//next col
					else if(plot_id < current_garden.cols){
						//plot_id += current_garden.cols*2+1;
						plot_id = (current_garden.cols*current_garden.rows) - (current_garden.cols-1-(plot_id % current_garden.cols));
					}
					//next row
					else {
						plot_id -= current_garden.cols;
					}
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
					//go to the bottom right
					if(plot_id == current_garden.cols*current_garden.rows - current_garden.cols){
						plot_id = current_garden.cols-1;
					}
					//go to prev row
					else if(plot_id % current_garden.cols == 0){
						plot_id += current_garden.cols*2-1;
					}
					//shuffle to the left
					else {
						plot_id--;
					}
					break;
				case Keyboard.ENTER:
					// perform the action on the next frame to avoid race conditions with ENTER
					StageBeacon.waitForNextFrame(onPlotClick, null, focused_plot);
					TSFrontController.instance.goNotAFK();
					break;
				default:
					legit_key = false;
					break;
			}
			
			//if we have a legit direction key go ahead and do stuff
			if(legit_key && event.keyCode != Keyboard.ENTER){
				TSFrontController.instance.goNotAFK();
				var plot_view:GardenPlotView = plot_holder.getChildByName('plot_'+plot_id) as GardenPlotView;
				highlightPlot(plot_view);
			}
		}
		
		private function onTimerTick(event:TimerEvent):void {
			action_timer.stop();
			checkGlow();
		}
		
		private function setOwners():void {
			//no garden? no one owns it!
			if(!current_garden) {
				_is_owner = false;
				return;
			}
			
			//see if we are the owner
			if(!current_garden.owner_tsid || (current_garden.owner_tsid && current_garden.owner_tsid == model.worldModel.pc.tsid)){
				_is_owner = true;
			}
			
			//see if we are in any of the owners
			if(current_garden.owner_tsids && current_garden.owner_tsids.indexOf(model.worldModel.pc.tsid) != -1){
				_is_owner = true;
			}
		}
		
		override public function get height():Number {
			if(!bounds) return 0
			return bounds.height + bounds.y;
		}
		
		override public function get width():Number {
			if(!bounds) return 0
			return bounds.width;
		}
		
		public function get is_owner():Boolean {
			return _is_owner;
		}
		
		public function get is_tending():Boolean { return _is_tending; }
		public function set is_tending(value:Boolean):void {
			_is_tending = value;
			if(value){
				unglow(true);
				TSFrontController.instance.requestFocus(this);
				
				//set the first plot to glow
				highlightPlot(GardenPlotView(plot_holder.getChildAt(plot_holder.numChildren-1)));
			}
			else {				
				checkGlow();
				TSFrontController.instance.releaseFocus(this);
				
				//clear out any timers that were running			
				TSTweener.removeTweens(plot_details);
				TSTweener.addTween(plot_details, {alpha:0, time:.3, transition:'linear', delay:.5, onComplete:onDetailsFadeOutTweenComplete});
				
				//unglow the plot if it's still glowing
				if(focused_plot){
					focused_plot.unhighlightOnDragOut();
					focused_plot = null;
				}
			}
			
			//kill the action timer
			action_timer.stop();
		}
		
		private function canGlow():Boolean {
			if(parent && parent.parent){
				var pc:PC = model.worldModel.pc;
				var lis_view:LocationItemstackView = parent.parent as LocationItemstackView;
				
				if(pc && lis_view && pc.apo._interaction_spV.indexOf(lis_view) > -1){
					return true;
				}
				
				return false;
			}
			
			return true;
		}
		
		private function checkGlow():void {
			if(canGlow()) glow();
		}
		
		override public function glow():void {
			if(!action_timer.running && is_owner){
				super.glow();
			}
		}
		
		override public function unglow(force:Boolean=false):void {			
			if(!force && !canGlow() && action_timer.running){
				//if we haven't forced it means we've walked away from it, clear the action timer
				action_timer.stop();
				action_timer.reset();
			}
			super.unglow(force);
		}
		
		public function actionUpdate():void {
			action_timer.reset();
			if(!action_timer.running) action_timer.start();
		}
		
		override public function dispose():void {
			PackDisplayManager.instance.removeEventListener(TSEvent.DRAG_COMPLETE, onPackDragComplete);
			action_timer.removeEventListener(TimerEvent.TIMER, onTimerTick);
			removeSelfAsFocusableComponent();
			
			clean();
			super.dispose();
		}
		
		private function clean():void {
			SpriteUtil.clean(plot_holder);
			SpriteUtil.clean(this);
			current_garden = null;
			current_plots = null;
			if (plot_details) {
				hidePlotDetails();
			}
		}
		
		/********************************* 
		 * Stuff for the focus component *
		 *********************************/
		
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function hasFocus():Boolean {
			return has_focus;
		}
		
		public function focus():void {
			CONFIG::debugging {
				Console.log(99, 'focus');
			}
			has_focus = true;
			StageBeacon.key_down_sig.add(onKeyDown);
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur');
			}
			has_focus = false;
			StageBeacon.key_down_sig.remove(onKeyDown);
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return false;
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			
		}
		
		public function registerSelfAsFocusableComponent():void {
			model.stateModel.registerFocusableComponent(this);
		}
		
		public function removeSelfAsFocusableComponent():void {
			model.stateModel.unRegisterFocusableComponent(this);
		}
	}
}