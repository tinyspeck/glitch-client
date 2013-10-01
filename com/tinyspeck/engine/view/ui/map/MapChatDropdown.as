package com.tinyspeck.engine.view.ui.map
{
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.view.gameoverlay.maps.HubMapDialog;
	import com.tinyspeck.engine.view.ui.chat.ChatDropdown;
	
	public class MapChatDropdown extends ChatDropdown
	{
		public function MapChatDropdown(){}
		
		override public function refreshMenu():void {
			cleanArrays();
			
			const loc:Location = model.worldModel.location;
			
			addItem({label:'Open large version', disabled:(loc && loc.no_hubmap)}, HubMapDialog.instance.start);
			addItem({label:'Open world map', disabled:(loc && loc.no_world_map)}, HubMapDialog.instance.startWithWorldMap);
			addItem((MapChatArea.center_star ? '• ' : '')+'Try to keep me in center', onCenterToggle);
			
			buildMenu();
		}
		
		private function onCenterToggle():void {
			//change and save
			MapChatArea.center_star = !MapChatArea.center_star;
			refreshMenu();
			
			LocalStorage.instance.setUserData(LocalStorage.MAP_CENTERED, MapChatArea.center_star);
		}
	}
}