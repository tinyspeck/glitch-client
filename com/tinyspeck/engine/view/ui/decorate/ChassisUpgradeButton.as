package com.tinyspeck.engine.view.ui.decorate
{
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.ui.furniture.FurnUpgradeButton;
	
	public class ChassisUpgradeButton extends FurnUpgradeButton
	{
		public function ChassisUpgradeButton(wh:int, padd:int){
			facing_left = true;
			super(wh, padd);
		}
		
		override protected function setText():void {
			//if something doesn't cost anything, just axe the text
			super.setText();
			
			//set up the displayed text
			var txt:String = 'Free!';
			
			//make sure the icon is in the right spot
			if(subscriber_icon) {
				const sub_padd:int = 2;
				subscriber_icon.x = int(wh - subscriber_icon.width - sub_padd);
				subscriber_icon.y = sub_padd;
			}
			
			if(current_upgrade.is_owned){
				//if we own this, we don't care how much it costs
				txt = '';
				if(credits_icon) credits_icon.visible = false;
			}
			else if(current_upgrade.credits){
				txt = '<span class="furn_upgrade_button_credits">'+StringUtil.formatNumberWithCommas(current_upgrade.credits)+'</span>';
			}
			
			//set the text
			tf.htmlText = '<p class="furn_upgrade_button">'+txt+'</p>';
			tf.x = int(wh/2 - tf.width/2 + (credits_icon && credits_icon.visible ? credits_icon.width/2 + 1 : 0));
			tf.y = int(wh - tf.height - 2);
			
			//move the credits icon where it needs to go
			if(credits_icon) {
				credits_icon.x = int(tf.x - credits_icon.width + 1);
				credits_icon.y = int(tf.y + (tf.height/2 - credits_icon.height/2) + 1);
			}
		}
	}
}