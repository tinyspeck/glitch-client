package com.tinyspeck.engine.view.ui.garden
{
	import com.tinyspeck.engine.data.garden.Garden;
	import com.tinyspeck.engine.data.garden.GardenAction;
	import com.tinyspeck.engine.data.garden.GardenPlot;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.Cursor;
	import com.tinyspeck.engine.port.GardenManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.DragVO;
	import com.tinyspeck.engine.util.IDragTarget;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.MovieClip;

	public class GardenPlotView extends TSSpriteWithModel implements IDragTarget {	
		private static var _base_width:int;
		private static var _base_height:int;

		private var seed_item:Item;
		private var garden:Garden;
		private var dragVO:DragVO = DragVO.vo;
		
		private var _plot:GardenPlot;
		private var _last_action:String;
		private var _last_seed_tsid:String;
		
		private var max_water_time:int;
		
		public function GardenPlotView(plot:GardenPlot, max_water_time:int, garden:Garden){
			this.plot = plot;
			this.max_water_time = max_water_time;
			this.garden = garden;
			name = 'plot_'+plot.plot_id;
			buildPlot();
		}
		
		private function buildPlot():void {
			var base:MovieClip;
			var growing:MovieClip;
			const scale:Number = model.worldModel.getItemstackByTsid(garden.itemstack_tsid).scale;
			
			//is it wet or dry?
			base = GardenSWFData.garden_mc.getAssetByName((plot.water_time > 0 ? 'wet' : 'dry'));
			base.width *= scale;
			base.height *= scale;
			addChild(base);
			if(!_base_width){
				_base_width = base.width;
				_base_height = base.height;
			}
			
			//mature level
			switch(plot.mature_level){
				//seeds
				case 1:
					growing = GardenSWFData.garden_mc.getAssetByName(garden.type+'_seeds');
					if(!growing) growing = GardenSWFData.garden_mc.getAssetByName('seeds');
					break;
				//sprout
				case 2:
					if(!plot.fertilized){
						growing = GardenSWFData.garden_mc.getAssetByName(garden.type+'_'+(plot.water_time > 0 ? 'seedling_wet' : 'seedling_dry'));
						if(!growing) growing = GardenSWFData.garden_mc.getAssetByName((plot.water_time > 0 ? 'seedling_wet' : 'seedling_dry'));
					}
					else {
						growing = GardenSWFData.garden_mc.getAssetByName(garden.type+'_seedling_fertilized');
						if(!growing) growing = GardenSWFData.garden_mc.getAssetByName('seedling_fertilized');
					}
					break;
				//plant!
				case 3:
					growing = GardenSWFData.garden_mc.getAssetByName('garden_'+plot.class_tsid);
					break;
				//dead/harvested/weeds
				case 4:
					growing = GardenSWFData.garden_mc.getAssetByName(garden.type+'_'+(plot.water_time > 0 ? 'harvested_wet' : 'harvested_dry'));
					if(!growing) growing = GardenSWFData.garden_mc.getAssetByName((plot.water_time > 0 ? 'harvested_wet' : 'harvested_dry'));
					break;
				//depleted
				case 5:
					growing = GardenSWFData.garden_mc.getAssetByName(garden.type+'_depleted');
					if(!growing) growing = GardenSWFData.garden_mc.getAssetByName('depleted');
					break;
			}
			
			//if we have some stuff growing, add it!
			if(growing) {
				growing.width *= scale;
				growing.height *= scale;
				addChild(growing);
			}
		}
		
		public function handleDrag(item_tsid:String):void {
			//make sure we are tending before allowing the drag
			var garden_view:GardenView = parent.parent as GardenView;
			if(!garden_view || (garden_view && !garden_view.is_owner)){
				unhighlightOnDragOut();
				Cursor.instance.hideTip();
				return;
			}
			
			//make sure the garden isn't glowing
			garden_view.unglow(true);
			
			//make sure this is the only plot glowing
			garden_view.highlightPlot(this, item_tsid);
			
			//got the garden?
			if(!garden){
				unhighlightOnDragOut();
				Cursor.instance.hideTip();
				return;
			}
			
			/*
			//highlight the right plot (if it's something we can use)
			if(GardenManager.instance.isUsableItem(item_tsid, garden)){
				garden_view.highlightPlot(this, item_tsid);
			}
			else {
				//can't use it? bail out
				unhighlightOnDragOut();
				Cursor.instance.showTip('This doesn\'t work in a garden');
				return;
			}
			*/
			
			//get the item so we can test the tags for seeds
			seed_item = TSModelLocator.instance.worldModel.getItemByTsid(item_tsid);
			
			//can we use this item on this plot?
			if(GardenManager.WATER_TOOLS.indexOf(item_tsid) != -1 && model.worldModel.pc.getItemstackOfWorkingTool(item_tsid)){
				if (garden_view.doesPlotNeedWater(plot)) {
					Cursor.instance.showTip('Water this plot');
				}
				else {
					Cursor.instance.showTip('This plot doesn\'t need more water');
				}
			}
			else if(GardenManager.HOE_TOOLS.indexOf(item_tsid) != -1 && model.worldModel.pc.getItemstackOfWorkingTool(item_tsid)){
				if(plot.mature_level == 4){
					Cursor.instance.showTip('Clear this plot');
				}
				else {
					Cursor.instance.showTip('Nothing to hoe!');
				}
			}
			else if(GardenManager.FERTILIZER.indexOf(item_tsid) != -1){
				if(plot.fertilized){
					Cursor.instance.showTip('This plot doesn\'t need more fertilizer');
				}
				else if(plot.mature_level == 1 || plot.mature_level == 2) {
					if(plot.water_time >= garden.max_water_time * GardenManager.FERTILIZE_PERC){
						Cursor.instance.showTip('Fertilize this plot');
					}
					else {
						Cursor.instance.showTip('You need to water it '+(plot.water_time > 0 ? 'more ' : '')+'first!');
					}
				}
				else {
					Cursor.instance.showTip('You can\'t fertilize this!');
				}
			}
			else if(seed_item && seed_item.hasTags(garden.type != Garden.TYPE_DEFAULT ? garden.type+'_seed' : 'seed')){
				//can take seeds?
				if(plot.mature_level == 0){
					Cursor.instance.showTip('Plant '+seed_item.label_plural);
				}
				else {
					Cursor.instance.showTip('Clear the plot first!');
				}
			}
			else if(GardenManager.REMOVE_ITEMS.indexOf(item_tsid) != -1){
				//they want to nuke this garden
				Cursor.instance.showTip('Remove this entire garden');
			}
			else {
				Cursor.instance.showTip('This can\'t be planted here');
			}
		}
		
		public function handleDrop(item_tsid:String):void {			
			//if we don't have the garden for some reason
			if(!garden){
				_last_action = null;
				_last_seed_tsid = null;
				unhighlightOnDragOut();
				dispatchEvent(new TSEvent(TSEvent.DRAG_COMPLETE, this));
				return;
			}
			
			//get the item so we can have a look at the tags
			seed_item = model.worldModel.getItemByTsid(item_tsid);
			
			if(GardenManager.WATER_TOOLS.indexOf(item_tsid) != -1 
				&& plot.water_time < max_water_time 
				&& model.worldModel.pc.getItemstackOfWorkingTool(item_tsid)){
					_last_action = GardenAction.WATER;
					_last_seed_tsid = null;
			}
			else if(GardenManager.HOE_TOOLS.indexOf(item_tsid) != -1 
				&& plot.mature_level == 4 
				&& model.worldModel.pc.getItemstackOfWorkingTool(item_tsid)){
					_last_action = GardenAction.HOE;
					_last_seed_tsid = null;
			}
			else if(seed_item 
				&& plot.mature_level == 0 
				&& seed_item.hasTags(garden.type != Garden.TYPE_DEFAULT ? garden.type+'_seed' : 'seed')){
					_last_action = GardenAction.PLANT;
					_last_seed_tsid = item_tsid;
			}
			else if((plot.mature_level == 1 || plot.mature_level == 2) 
				&& GardenManager.FERTILIZER.indexOf(item_tsid) != -1 
				&& !plot.fertilized 
				&& plot.water_time >= garden.max_water_time * GardenManager.FERTILIZE_PERC){
					_last_action = GardenAction.FERTILIZE;
					_last_seed_tsid = null;
			}
			else if(GardenManager.REMOVE_ITEMS.indexOf(item_tsid) != -1){
				_last_action = GardenAction.REMOVE;
				_last_seed_tsid = dragVO.dragged_itemstack.tsid; //hijack the seed ID to the itemstack tsid to fire off to the server
			}
			else {
				_last_action = null;
				_last_seed_tsid = null;
				unhighlightOnDragOut();
			}
			
			dispatchEvent(new TSEvent(TSEvent.DRAG_COMPLETE, this));
		}
		
		public function highlightOnDragOver():void {
			filters = StaticFilters.tsSprite_GlowA;
		}
		
		public function unhighlightOnDragOut():void {
			filters = null;
		}
		
		public function get base_width():int { return _base_width; }
		public function get base_height():int { return _base_height; }
		
		public function get plot():GardenPlot { return _plot; }
		public function set plot(value:GardenPlot):void { 
			_plot = value;
			name = 'plot_'+plot.plot_id;
		}
		
		public function get last_action():String { return _last_action; }
		public function get last_seed_tsid():String { return _last_seed_tsid; }
	}
}