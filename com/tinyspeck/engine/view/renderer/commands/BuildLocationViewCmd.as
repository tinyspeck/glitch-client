package com.tinyspeck.engine.view.renderer.commands
{
	import com.tinyspeck.core.control.ICommand;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.view.AvatarView;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.renderer.LocationViewBuilder;
	
	import flash.display.Sprite;
	
	public class BuildLocationViewCmd implements ICommand {
		private var location:Location;
		private var avatarView:AvatarView;
		private var pc:PC;
		private var locationRenderer:LocationRenderer;
		private var controlPointsHolder:Sprite;
		private var onComplete:Function;
		
		private var mainView:TSMainView;
		
		public function BuildLocationViewCmd(location:Location, avatarView:AvatarView, pc:PC, 
											 locationRenderer:LocationRenderer, controlPointHolder:Sprite) {
			this.location = location;
			this.avatarView = avatarView;
			this.pc = pc;
			this.locationRenderer = locationRenderer;
			this.controlPointsHolder = controlPointHolder;
			
			mainView = TSFrontController.instance.getMainView();
		}
		
		public function execute():void {
			var locationViewBuilder:LocationViewBuilder = new LocationViewBuilder(locationRenderer, mainView, controlPointsHolder);
			locationViewBuilder.buildLocationView(location, avatarView, pc);
		}
	}
}