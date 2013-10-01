package com.tinyspeck.engine.view.gameoverlay
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.loader.SmartLoader;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.pack.FurnitureBagUI;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.pack.PackTabberUI;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CultManager;
	import com.tinyspeck.engine.port.IMoveListener;
	import com.tinyspeck.engine.port.RightSideManager;
	import com.tinyspeck.engine.port.RightSideView;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.gameoverlay.maps.MiniMapView;
	import com.tinyspeck.engine.view.ui.Cloud;
	import com.tinyspeck.engine.view.ui.chat.ChatArea;
	import com.tinyspeck.engine.vo.ArbitrarySWFLoadVO;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.utils.Timer;

	public class UICalloutView extends Sprite implements IMoveListener
	{
		/* singleton boilerplate */
		public static const instance:UICalloutView = new UICalloutView();
		
		/**
		 * http://svn.tinyspeck.com/wiki/SpecUICallout#Available_Sections 
		 */		
		public static const CHARACTER:String = 'character';
		public static const LEVEL:String = 'level';
		public static const XP:String = 'xp';
		public static const ENERGY:String = 'energy';
		public static const MOOD:String = 'mood';
		public static const CURRANTS:String = 'currants';
		public static const MINI_MAP:String = 'mini_map';
		public static const ICON_MAP:String = 'icon_map';
		public static const BUFFS:String = 'buffs';
		public static const CHAT_FRIENDS:String = 'chat_friends';
		public static const CHAT_HELP:String = 'chat_help';
		public static const CHAT_LOCAL:String = 'chat_local';
		public static const CHAT_PARTY:String = 'chat_party';
		public static const CHAT_ACTIVE:String = 'chat_active';
		public static const BACKPACK:String = 'backpack';
		public static const CLOCK:String = 'clock';
		public static const VOLUME_CONTROL:String = 'volume_control';
		public static const EAT:String = 'eat';
		public static const DRINK:String = 'drink';
		public static const TOOLBAR_CLOSE:String = 'toolbar_close';
		public static const DECORATE:String = 'decorate';
		public static const CULTIVATE:String = 'cultivate';
		public static const RESOURCE:String = 'resource';
		public static const FURNITURE:String = 'furniture';
		public static const FURNITURE_TAB:String = 'furniture_tab';
		public static const SWATCH_OPEN:String = 'swatch_open';
		public static const SWATCH_DRAG:String = 'swatch_drag';
		public static const IMAGINATION_MENU:String = 'imagination_menu';
		public static const GO_HOME:String = 'go_home';
		public static const CONTACTS:String = 'contacts';
		public static const LIVE_HELP:String = 'live_help';
		public static const QUESTS:String = 'quests';
		public static const UPGRADES:String = 'upgrades';
		public static const READY_TO_SAVE:String = 'ready_to_save';
		
		private var section:String;
		
		private var scale:Number;
		private var display_time:Number;
		private var slot_id:int;
		private var offset_x:int;
		private var offset_y:int;
		private var final_x:int;
		private var final_y:int;
		private var final_rotation:int;
		
		private var end_point:Point = new Point();
		
		private var holder:Sprite = new Sprite();
		private var asset:DisplayObject;
		
		private var vo:ArbitrarySWFLoadVO;
		private var main_view:TSMainView;
		private var layoutModel:LayoutModel;
		private var ydm:YouDisplayManager;
		private var rsv:RightSideView;
		
		private var display_timer:Timer = new Timer(5000);
		
		private var is_hiding:Boolean;
		private var is_built:Boolean;
		
		public function UICalloutView() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		private function buildBase():void {
			main_view = TSFrontController.instance.getMainView();
			layoutModel = TSModelLocator.instance.layoutModel;
			ydm = YouDisplayManager.instance;
			rsv = RightSideManager.instance.right_view;
			
			mouseEnabled = mouseChildren = false;
			addChild(holder);
			
			visible = false;
			alpha = 0;
			
			is_built = true;
		}
		
		// SHOULD ONLY EVER BE CALLED FROM TSFrontController.instance.tryShowScreenViewFromQ();
		//not true anymore, there are times in newxp where the rock isn't on screen, so these need to be there!
		public function show(payload:Object):Boolean {
			if(payload.section){
				if(!is_built) buildBase();
				
				scale = (payload.scale ? payload.scale : 1);
				section = payload.section;
				slot_id = 'slot_id' in payload ? payload.slot_id : 0;
				display_time = (payload.hasOwnProperty('display_time') ? payload.display_time : 5000);
				offset_x = 'offset_x' in payload ? payload.offset_x : 0;
				offset_y = 'offset_y' in payload ? payload.offset_y : 0;
				
				display_timer.addEventListener(TimerEvent.TIMER, hide, false, 0, true);
				
				SpriteUtil.clean(holder);
				
				if('swf_url' in payload){
					var sl:SmartLoader = new SmartLoader(payload.swf_url);
					sl.complete_sig.add(prepSWF);
					sl.load(new URLRequest(payload.swf_url));
				}
				else {
					//clear it out
					if(asset && asset.parent) asset.parent.removeChild(asset);
					asset = null;
					
					try {
						//try and get the asset
						asset = new AssetManager.instance.assets['callout_'+section];
						holder.addChild(asset);
					}
					catch(error:Error) {
						CONFIG::debugging {
							Console.warn('MISSING ASSET FOR SECTION: '+section+'. Should be "callout_xxxxxx"');
						}
						return false;
					}
					
					//place it where it needs to go
					place();
				}
				
				//listen to move events
				TSFrontController.instance.registerMoveListener(this);
				
				return true;
			}
			else {
				CONFIG::debugging {
					Console.warn('Should probably pass a section name to callout to');
				}
				return false;
			}
		}
		
		public function hide(event:TimerEvent = null):void {
			TSTweener.addTween(this, {alpha:0, time:1, transition:'linear', onComplete:cleanUp});
			display_timer.stop();
			is_hiding = true;
		}
		
		private function cleanUp():void {
			TSFrontController.instance.screenViewClosed();
			TSFrontController.instance.removeMoveListener(this);
			if (this.parent) this.parent.removeChild(this);
			
			display_timer.removeEventListener(TimerEvent.TIMER, hide);
			visible = false;
			section = null;
		}
		
		private function prepSWF(sl:SmartLoader):void {						
			asset = sl.content as MovieClip;
			if (!asset) {
				return;
			}
			holder.addChild(asset);
			
			place();
		}		
		
		private function place():void {		
			visible = true;
			is_hiding = false;
			
			if(asset is MovieClip){
				asset.scaleX = asset.scaleY = scale;
				
				//get the child and reset the playhead
				if(MovieClip(asset).getChildAt(0)){
					MovieClip(MovieClip(asset).getChildAt(0)).gotoAndPlay(1);
				}
				else {
					MovieClip(asset).gotoAndPlay(1);
				}
				
				//give this thing center reg point
				SpriteUtil.setRegistrationPoint(asset);
			}
			else if(!asset){
				CONFIG::debugging {
					Console.warn('Where is the asset?! Not good.');
				}
				hide();
				return;
			}
			
			//set the timer
			display_timer.reset();
			display_timer.delay = display_time;
			if(display_time > 0) display_timer.start();
						
			refresh();
			
			main_view.addView(this);
			
			//fade'r in
			TSTweener.addTween(this, {alpha:1, time:.3, transition:'linear'});
		}
		
		public function refresh():void {
			if(visible && asset){				
				//reset
				final_x = 0;
				final_y = 0;
				final_rotation = 0;
				
				/**
				 * Points back from YDM don't take into account the gutter and header
				 * since the things that call those methods are relative to YDM.
				 **/
				switch(section){
					case CHARACTER:
					case LEVEL:
						end_point = ydm.getFaceBasePt();
						end_point.x -= layoutModel.gutter_w;
						end_point.y -= layoutModel.header_h - 35;
						break;
					case XP:
						end_point = ydm.getImaginationCenterPt();
						end_point.x -= layoutModel.gutter_w;
						end_point.y -= layoutModel.header_h - 35;
						break;
					case ENERGY:
						end_point = ydm.getEnergyGaugeCenterPt();
						end_point.x -= layoutModel.gutter_w;
						end_point.y -= layoutModel.header_h - 25;
						if(!(asset is MovieClip)){
							//this is the png
							end_point.x -= 70;
							end_point.y -= 2;
						}
						break;
					case MOOD:
						end_point = ydm.getMoodGaugeCenterPt();
						// these two correct for the fact that EC corrected getMoodGaugeCenterPt to return the actual center of the gauge
						end_point.x -= 35;
						end_point.y -= 35;
						
						end_point.x -= layoutModel.gutter_w;
						end_point.y -= layoutModel.header_h - 25;
						if(!(asset is MovieClip)){
							//this is the mood png
							end_point.x += ydm.player_info_w - 70;
							end_point.y -= holder.height - 5;
						}
						break;
					case CURRANTS:
						end_point = ydm.getCurrantsCenterPt();
						end_point.x -= layoutModel.gutter_w - 80;
						end_point.y -= layoutModel.header_h + 65;
						if(!(asset is MovieClip)){
							//this is the png
							end_point.x -= 135;
							end_point.y -= 40;
						}
						else {
							//roate the arrow
							final_rotation = -90;
						}
						break;
					case MINI_MAP:
						end_point.x = MiniMapView.instance.x-holder.width + 20;
						end_point.y = MiniMapView.instance.y + MiniMapView.instance.h - 10;
						break;
					case ICON_MAP:
						end_point.x = MiniMapView.instance.x - holder.width - 13;
						end_point.y = -layoutModel.header_h + 20;
						break;
					case BUFFS:
						end_point.x = BuffViewManager.instance.x - 10;
						end_point.y = BuffViewManager.instance.y + 11;
						final_rotation = 90;
						break;
					case CHAT_FRIENDS:
						end_point = rsv.getContactsPt(false);
						final_rotation = 90;
						break;
					case CHAT_ACTIVE:
						end_point = rsv.getContactsPt(true);
						final_rotation = 90;
						break;
					case CHAT_HELP:
						end_point = rsv.getChatAreaPt(ChatArea.NAME_GLOBAL);
						final_rotation = 90;
						break;
					case CHAT_LOCAL:
						end_point = rsv.getChatAreaPt(ChatArea.NAME_LOCAL);
						final_rotation = 90;
						break;
					case CHAT_PARTY:
						end_point = rsv.getChatAreaPt(ChatArea.NAME_PARTY);
						final_rotation = 90;
						break;
					case BACKPACK:
						end_point.x = PackDisplayManager.instance.x + 30;
						end_point.y = PackDisplayManager.instance.y;
						final_rotation = 180;
						break;
					case CLOCK:
						end_point = ydm.getTimeBasePt();
						end_point.x -= layoutModel.gutter_w;
						end_point.y -= layoutModel.header_h;
						break;
					case VOLUME_CONTROL:
						end_point = ydm.getVolumeControlBasePt();
						end_point.x -= layoutModel.gutter_w;
						end_point.y -= layoutModel.header_h;
						break;
					case EAT:
					case DRINK:
						//this should also come packed with a slot id, if not it assumes 0
						end_point = PackDisplayManager.instance.translateSlotCenterToGlobal(slot_id, '');
						end_point.x -= layoutModel.gutter_w;
						end_point.y -= layoutModel.header_h + PackDisplayManager.instance.h + holder.height;
						break;
					case TOOLBAR_CLOSE:
						end_point = ydm.getToolbarCloseButtonBasePt();
						end_point.x -= layoutModel.gutter_w + holder.width - 5;
						end_point.y -= layoutModel.header_h + 30;
						break;
					case DECORATE:
						end_point = ydm.getDecorateButtonBasePt();
						end_point.x -= layoutModel.gutter_w + holder.width - 10;
						end_point.y -= layoutModel.header_h + 20;
						break;
					case CULTIVATE:
						end_point = ydm.getDecorateButtonBasePt();
						end_point.x -= layoutModel.gutter_w;
						end_point.y -= layoutModel.header_h + 18;
						break;
					case SWATCH_OPEN:
						end_point = ydm.getPackTabberCenterPt(PackTabberUI.TAB_WALL);
						end_point.x -= layoutModel.gutter_w + holder.width/2 - 50;
						end_point.y -= layoutModel.header_h + holder.height + 65;
						break;
					case SWATCH_DRAG:
						end_point.x = 10;
						end_point.y = layoutModel.loc_vp_h - layoutModel.header_h - holder.height + 35;
						break;
					case FURNITURE_TAB:
						end_point = ydm.getPackTabberCenterPt(PackTabberUI.TAB_FURNITURE);
						end_point.x -= layoutModel.gutter_w;
						end_point.y -= layoutModel.header_h + holder.height + 40;
						break;
					case FURNITURE:
						end_point.x = FurnitureBagUI.instance.x + 65;
						end_point.y = FurnitureBagUI.instance.y - layoutModel.header_h - holder.height + layoutModel.loc_vp_h + 25;
						break;
					case RESOURCE:
						end_point = CultManager.instance.getPickerPt();
						end_point.x -= layoutModel.gutter_w;
						end_point.y -= layoutModel.header_h + holder.height + 30;
						break;
					case IMAGINATION_MENU:
						end_point = ydm.getImaginationButtonBasePt();
						end_point.x -= layoutModel.gutter_w;
						end_point.y -= layoutModel.header_h + 18;
						break;
					case GO_HOME:
						end_point = ImgMenuView.instance.getCloudBasePt(Cloud.TYPE_HOME);
						end_point.x -= layoutModel.gutter_w + holder.width - 10;
						end_point.y -= layoutModel.header_h + 20;
						break;
					case CONTACTS:
						end_point = rsv.getToggleButtonPt();
						end_point.x -= layoutModel.gutter_w + holder.width + 10;
						end_point.y -= layoutModel.header_h + 30;
						break;
					case LIVE_HELP:
						end_point = rsv.getContactPt(ChatArea.NAME_HELP);
						end_point.x -= layoutModel.gutter_w + holder.width;
						end_point.y -= layoutModel.header_h + 56;
						break;
					case QUESTS:
						end_point = ydm.getImaginationButtonBasePt();
						end_point.x -= layoutModel.gutter_w - 35;
						end_point.y -= layoutModel.header_h + holder.height - 14;
						break;
					case UPGRADES:
						end_point = ImgMenuView.instance.getCloudBasePt(Cloud.TYPE_UPGRADES);
						end_point.x -= layoutModel.gutter_w + 10;
						end_point.y -= layoutModel.header_h + 10;
						break;
					case READY_TO_SAVE:
						end_point = rsv.getCreateAccountPt();
						end_point.x -= layoutModel.gutter_w + holder.width + 10;
						end_point.y -= layoutModel.header_h + 25;
						break;
					default:
						CONFIG::debugging {
							Console.warn('The "'+section+'" section was not reconized, so we are throwing the holder way off screen.');
						}
						end_point.x = -500;
						end_point.y = -500;
						break;
				}
				
				//offset the asset to take into account the rotation
				if(final_rotation == 90){
					end_point.x -= asset.width/2;
					end_point.y -= asset.height/2;
				}
				else if(final_rotation == 180){
					end_point.y -= asset.height;
				}
				
				final_x = int(end_point.x + layoutModel.gutter_w + offset_x);
				final_y = int(end_point.y + layoutModel.header_h + asset.height/2 + offset_y);

				x = final_x;
				y = final_y;
				rotation = final_rotation;
			}
		}
		
		public function get current_section():String { return section; }
		
		/*****************
		 * IMoveListener *
		 *****************/
		public function moveLocationHasChanged():void {}
		public function moveLocationAssetsAreReady():void {}
		public function moveMoveEnded():void {}
		public function moveMoveStarted():void {
			//if we are still showing this, axe it
			alpha = 0;
			display_timer.stop();
			cleanUp();
		}		
	}
}