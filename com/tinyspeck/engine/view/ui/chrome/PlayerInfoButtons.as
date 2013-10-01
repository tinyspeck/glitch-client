package com.tinyspeck.engine.view.ui.chrome
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.ACLDialog;
	import com.tinyspeck.engine.port.PrefsDialog;
	import com.tinyspeck.engine.view.ui.Button;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.filters.DropShadowFilter;

	public class PlayerInfoButtons extends Sprite
	{
		private static const TOP_PADD:int = 10;
		private static const BOTTOM_PADD:int = 2;
		private static const BT_PADD:uint = 4;
		private static const WIDTH:uint = 105;
		
		private var next_y:int = TOP_PADD;
		
		private var inner_shadow:DropShadowFilter = new DropShadowFilter();
		
		public function PlayerInfoButtons(){
			//define the options for the player menu
			const tsfc:TSFrontController = TSFrontController.instance;
			
			//base
			addItem('Profile', tsfc.openProfilePage);
			addItem('Skills', tsfc.openSkillsPage);
			//addItem('Tokens', tsfc.openProfileTokensPage);
			addItem('Vanity', tsfc.openVanityPage);
			addItem('Wardrobe', tsfc.openWardrobePage);
			
			//groups and friends
			addLine();
			addItem('Groups', tsfc.openGroupsPage);
			addItem('Friends', tsfc.openFriendsPage);
			addItem('Keys', ACLDialog.instance.start);
			
			//forums and auctions
			addLine();
			addItem('Encyclopedia', tsfc.openEncyclopediaPage);
			addItem('Forums', tsfc.openForumsPage);
			addItem('Auctions', tsfc.openAuctionsPage);
			
			//settings and sign out
			addLine();
			addItem('Report Abuse', tsfc.startReportAbuseDialog);
			addItem('Preferences', PrefsDialog.instance.start);
			addItem('Account', tsfc.openSettingsPage);
			addItem('Exit the World', tsfc.openSignOutPage);
			
			//draw the bg
			const g:Graphics = graphics;
			g.beginFill(0xdde5e8);
			g.drawRect(0, 0, WIDTH, int(height + TOP_PADD*2));
			
			//set the filter
			inner_shadow.alpha = .5;
			inner_shadow.distance = 1;
			inner_shadow.blurX = inner_shadow.blurY = 3;
			inner_shadow.color = 0x99b1ba;
			inner_shadow.angle = 120;
			inner_shadow.quality = 3;
			inner_shadow.inner = true;
			filters = [inner_shadow];
		}
		
		private function addItem(label:String, click_function:Function):void {
			const bt:Button = new Button({
				name: 'bt_'+label,
				label: label,
				value: click_function,
				size: Button.SIZE_VERB,
				type: Button.TYPE_VERB,
				offset_x: 5,
				w: WIDTH - BT_PADD*2
			});
			bt.addEventListener(TSEvent.CHANGED, onButtonClick, false, 0, true);
			bt.x = BT_PADD;
			bt.y = next_y;
			next_y += bt.height;
			addChild(bt);
		}
		
		private function addLine():void {
			const sp:Sprite = new Sprite();
			const g:Graphics = sp.graphics;
			g.beginFill(0xc0cfd4);
			g.drawRect(0, 0, WIDTH, 1);
			next_y += BOTTOM_PADD*2;
			sp.y = next_y;
			next_y += sp.height + BOTTOM_PADD;
			addChild(sp);
		}
		
		private function onButtonClick(event:TSEvent):void {
			const bt:Button = event.data as Button;
			if(bt.disabled) return;
			
			//run the function
			if(bt.value is Function) {
				(bt.value as Function).apply();
				
				//let the listeners know what function was just fired
				dispatchEvent(new TSEvent(TSEvent.CHANGED, bt.value));
			}
		}
	}
}