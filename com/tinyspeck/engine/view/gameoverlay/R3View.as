package com.tinyspeck.engine.view.gameoverlay
{
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;

	public class R3View extends BaseScreenView
	{
		/* singleton boilerplate */
		public static const instance:R3View = new R3View();
		
		private var ok_bt:Button;
		
		public function R3View(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		override protected function buildBase():void {
			super.buildBase();
			
			//darker bg
			bg_alpha = .7;
			
			//instructions
			const instructions_holder:Sprite = new Sprite();
			instructions_holder.buttonMode = instructions_holder.buttonMode = true;
			const instructions_DO:DisplayObject = new AssetManager.instance.assets.r3_message_overlay();
			all_holder.addChild(instructions_holder);
			instructions_holder.addChild(instructions_DO);
			
			instructions_holder.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
				navigateToURL(new URLRequest(
					model.flashVarModel.root_url+'forum/general/20792/'
				), '_blank')
			});
			
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
			ok_bt.x = int(instructions_DO.width/2 - ok_bt.width/2);
			ok_bt.y = instructions_DO.height + 20;
			all_holder.addChild(ok_bt);
		}
		
		public function show(payload:Object):Boolean {
			if(!super.makeSureBaseIsLoaded()) return false;
			
			//setup to animate
			draw();
			animate();
			
			return tryAndTakeFocus(payload);
		}
		
		override protected function draw():void {						
			super.draw();
			
			//center
			all_holder.x = int(model.layoutModel.gutter_w + model.layoutModel.loc_vp_w/2 - all_holder.width/2);
			all_holder.y = int(model.layoutModel.loc_vp_h/2 - all_holder.height/2 + 30);
		}
		
		override protected function onDoneTweenComplete():void {
			super.onDoneTweenComplete();
			
			//they saw it, set the local storage
			LocalStorage.instance.setUserData(LocalStorage.SEEN_R3, true);
		}
	}
}