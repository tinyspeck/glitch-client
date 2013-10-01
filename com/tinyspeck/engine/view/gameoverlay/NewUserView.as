package com.tinyspeck.engine.view.gameoverlay
{
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;

	public class NewUserView extends BaseScreenView
	{
		/* singleton boilerplate */
		public static const instance:NewUserView = new NewUserView();
		
		private var ok_bt:Button;
		
		public function NewUserView(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		override protected function buildBase():void {
			super.buildBase();
			
			//darker bg
			bg_alpha = .7;
			
			//instructions
			const instructions_DO:DisplayObject = new AssetManager.instance.assets.newuser_img_menu();
			all_holder.addChild(instructions_DO);
			
			//button
			ok_bt = new Button({
				label: 'Got it. Thanks!',
				name: 'ok_bt',
				value: 'ok',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_DEFAULT
			});
			ok_bt.addEventListener(TSEvent.CHANGED, onOkClick, false, 0, true);
			ok_bt.filters = StaticFilters.white4px40AlphaGlowA;
			ok_bt.x = int(instructions_DO.width/2 - ok_bt.width/2 + 32);
			ok_bt.y = instructions_DO.height + 20;
			all_holder.addChild(ok_bt);
		}
		
		public function show(payload:Object):Boolean {
			if(!super.makeSureBaseIsLoaded()) return false;
			
			if (payload && payload.and_more) {
				ok_bt.label = 'And another thing...';
			} else {
				ok_bt.label = 'Got it. Thanks!';
			}
			
			//setup to animate
			draw();
			animate();
			
			return tryAndTakeFocus(payload);
		}
		
		override protected function draw():void {						
			super.draw();
			
			//center
			all_holder.x = int(model.layoutModel.gutter_w + model.layoutModel.loc_vp_w/2 - all_holder.width/2 - 30);
			all_holder.y = int(model.layoutModel.loc_vp_h/2 - all_holder.height/2 + 30);
		}
		
		override protected function onDoneTweenComplete():void {
			super.onDoneTweenComplete();
			
			//they saw it, set the local storage
			LocalStorage.instance.setUserData(LocalStorage.SEEN_NEW_USER_MENU, true);
		}
	}
}