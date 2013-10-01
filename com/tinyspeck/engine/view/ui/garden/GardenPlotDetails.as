package com.tinyspeck.engine.view.ui.garden
{
	import com.tinyspeck.engine.data.garden.Garden;
	import com.tinyspeck.engine.data.garden.GardenPlot;
	import com.tinyspeck.engine.port.GardenManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.ProgressBar;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.text.TextField;

	public class GardenPlotDetails extends TSSpriteWithModel
	{
		private static const WIDTH:uint = 140;
		private static const PADD:uint = 10;
		
		private static var seed_list:Array;
		
		private var label_tf:TextField = new TextField();
		private var tip_tf:TextField = new TextField();
		private var plot_tf:TextField = new TextField();
		
		private var water_level:ProgressBar;
		private var growth_level:ProgressBar;
		
		private var water_perc:int;
		private var growth_perc:int;
		
		public function GardenPlotDetails(){
			mouseEnabled = mouseChildren = false;
			name = 'plot_details';
			
			var next_y:int = PADD - 4;
			
			TFUtil.prepTF(label_tf);
			label_tf.x = PADD;
			label_tf.y = next_y;
			label_tf.width = WIDTH - PADD*2;
			title = 'Placeholderp';
			next_y += label_tf.height - 4;
			addChild(label_tf);
			
			TFUtil.prepTF(tip_tf);
			tip_tf.x = PADD;
			tip_tf.y = next_y;
			tip_tf.width = WIDTH - PADD*2;
			tip_label = 'Placeholderp';
			next_y += tip_tf.height + 4;
			addChild(tip_tf);
			
			water_level = new ProgressBar(WIDTH - PADD*2);
			water_level.setBarColors(0x47a7bd, 0x218ea6, 0x4195a9, 0x248397);
			water_level.x = PADD;
			water_level.y = next_y;
			next_y += water_level.height + 2;
			addChild(water_level);
			
			growth_level = new ProgressBar(WIDTH - PADD*2);
			growth_level.x = PADD;
			growth_level.y = next_y;
			next_y += growth_level.height;
			addChild(growth_level);
			
			TFUtil.prepTF(plot_tf);
			plot_tf.x = PADD - 2;
			plot_tf.y = next_y + 4;
			plot_tf.width = WIDTH - PADD*2 + 4;
			plot_label = 'Placeholderp';
			next_y += plot_tf.height - 2;
			addChild(plot_tf);
			
			filters = StaticFilters.black2px90Degrees_DropShadowA;
		}
		
		public function show(plot:GardenPlot, secs_since_update:int, garden:Garden, item_tsid:String = ''):void {
			var tip_txt:String = '';
			visible = true;
			
			plot_label = plot.label;
			
			water_perc = ((plot.water_time - secs_since_update) / garden.max_water_time)*100;
			growth_perc = ((plot.grow_time - (plot.water_time > 0 ? secs_since_update : 0)) / plot.max_grow_time)*100;
			growth_perc = 100 - growth_perc;
			
			if(plot.water_time > 0){
				setWaterLevel(plot.water_time - secs_since_update, water_perc/100);
			}
			else {
				setWaterLevel(0,0);
			}
			
			//do we have some grow time?
			if(plot.grow_time > 0) {
				setGrowthLevel(plot.grow_time - secs_since_update, growth_perc/100);
			}
			//it's all done growing!
			else if(plot.mature_level == 3){
				setGrowthLevel(0,1);
			}
			//nothing growing
			else {
				setGrowthLevel(0,0);
			}
			
			//set the label
			if(plot.harvestable){
				title = 'Harvest this plot!';
				tip_txt = 'Get them goodies';
				
				//if we passed an item, hide this
				if(item_tsid){
					visible = false;
				}
			}
			else if(plot.mature_level == 4){
				title = 'Clear this plot';
				tip_txt = 'Hoe that mess';
				
				//if we passed in an item, and that item is not a hoe tool, hide this
				if(item_tsid && GardenManager.HOE_TOOLS.indexOf(item_tsid) == -1){
					visible = false;
				}
				
				//if they don't have a working Hoe, then toss a red tip
				if(model.worldModel.pc.hasItemsFromList(GardenManager.HOE_TOOLS).length == 0){
					tip_txt = '<span class="garden_plot_tip_error">You need a Hoe!</span>';
				}
			}
			else if(plot.mature_level == 5){
				title = 'Depleted plot';
				tip_txt = 'Nothing gonna grow';
				
				//if we passed an item, hide this
				if(item_tsid){
					visible = false;
				}
			}
			else if(plot.mature_level == 0 && plot.water_time > 0){
				title = 'Plant some seeds';
				tip_txt = 'Make things grow';
				
				//check to see if they have seeds to plant
				seed_list = model.worldModel.getItemTsidsByTags(garden.type != Garden.TYPE_DEFAULT ? garden.type+'_seed' : 'seed');
				
				//if we passed in an item, and that item is not a seed, hide this
				if(item_tsid && seed_list.indexOf(item_tsid) == -1){
					visible = false;
				}
				
				if(model.worldModel.pc.hasItemsFromList(seed_list).length == 0){
					tip_txt = '<span class="garden_plot_tip_error">You need '+(garden.type != Garden.TYPE_DEFAULT ? garden.type : 'crop')+' seeds!</span>';
				}
			}
			else if(plot.water_time - secs_since_update < garden.max_water_time - garden.water_threshold){
				title = 'Water this plot';
				tip_txt = 'Nourish the soil';
				
				//if we passed in an item, and that item is not a watering can type, hide this
				if(item_tsid && GardenManager.WATER_TOOLS.indexOf(item_tsid) == -1){
					visible = false;
				}
				
				//if they don't have a working Watering Can, then toss a red tip
				if(model.worldModel.pc.hasItemsFromList(GardenManager.WATER_TOOLS).length == 0){
					tip_txt = '<span class="garden_plot_tip_error">Get a Watering Can!</span>';
				}
			}
			else if((plot.mature_level == 1 || plot.mature_level == 2) 
				&& !plot.fertilized 
				&& model.worldModel.pc.hasItemsFromList(GardenManager.FERTILIZER).length > 0
				&& plot.water_time >= garden.max_water_time * GardenManager.FERTILIZE_PERC){
				title = 'Fertilize this plot';
				tip_txt = 'Speed up the growing';
				
				//if we passed in an item, and that item is not fertilizer, hide this
				if(item_tsid && GardenManager.FERTILIZER.indexOf(item_tsid) == -1){
					visible = false;
				}
			}
			else {
				title = 'All good';
				tip_txt = 'Nothing to do';
			}
			
			tip_label = tip_txt;
			
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRoundRect(0, 0, WIDTH, plot_tf.y + plot_tf.height - 2 + PADD, 8);
		}
		
		public function hide():void {
			setWaterLevel(0,0);
			setGrowthLevel(0,0);
		}
		
		private function setWaterLevel(secs_to_complete:int, perc:Number):void {
			water_level.update(perc);
			if(perc > 0) water_level.updateWithAnimation(secs_to_complete, 0);
		}
		
		private function setGrowthLevel(secs_to_complete:int, perc:Number):void {
			growth_level.update(perc);
			if(perc > 0) growth_level.updateWithAnimation(secs_to_complete, 1);
		}
		
		private function set title(txt:String):void {
			label_tf.htmlText = '<p class="garden_plot_title">'+txt+'</p>';
		}
		
		private function set tip_label(txt:String):void {
			tip_tf.htmlText = '<p class="garden_plot_tip">'+txt+'</p>';
		}
		
		private function set plot_label(txt:String):void {
			plot_tf.htmlText = '<p class="garden_plot_label">'+txt+'</p>';
		}
		
		override public function dispose():void {
			//
			super.dispose();
		}
	}
}