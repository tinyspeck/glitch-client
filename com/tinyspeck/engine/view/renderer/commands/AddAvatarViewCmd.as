package com.tinyspeck.engine.view.renderer.commands
{
	import com.tinyspeck.core.control.ICommand;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.AvatarView;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	
	import flash.display.DisplayObject;
	
	public class AddAvatarViewCmd implements ICommand {
		
		private var locationRenderer:LocationRenderer;
		private var model:TSModelLocator;
		
		public function AddAvatarViewCmd(locationRenderer:LocationRenderer) {
			this.locationRenderer = locationRenderer;

			model = TSModelLocator.instance;
		}
		
		public function execute():void {
			createNativeAvatar();
		}
		
		private function createNativeAvatar():void {
			var avatarView:AvatarView = new AvatarView(model.worldModel.pc.tsid);
			addAvatarView(avatarView);
			
			LocationCommands.applyFiltersToView(model.worldModel.location.mg, avatarView as DisplayObject);
		}
		
		private function addAvatarView(avatarView:AvatarView):void {
			locationRenderer.setAvatarView(avatarView);
			avatarView.updateModel();
			locationRenderer.locationView.middleGroundRenderer.addYourAvatar(avatarView);
		}
	}
}