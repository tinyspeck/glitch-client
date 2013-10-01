package com.tinyspeck.engine.control.engine
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.debug.API;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.NewxpLogger;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Activity;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.data.client.OverlayMouse;
	import com.tinyspeck.engine.data.client.OverlayOpacity;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.port.CabinetDialog;
	import com.tinyspeck.engine.port.CabinetManager;
	import com.tinyspeck.engine.port.Emotes;
	import com.tinyspeck.engine.port.QuoinAnimation;
	import com.tinyspeck.engine.port.StatBurstController;
	import com.tinyspeck.engine.port.TradeDialog;
	import com.tinyspeck.engine.port.TrophyCaseDialog;
	import com.tinyspeck.engine.port.TrophyCaseManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.view.AbstractAvatarView;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.effects.LightningBolt;
	import com.tinyspeck.engine.view.effects.Missile;
	import com.tinyspeck.engine.view.gameoverlay.AbstractAnnouncementOverlay;
	import com.tinyspeck.engine.view.gameoverlay.InLocationAnnouncementOverlay;
	import com.tinyspeck.engine.view.gameoverlay.InWindowAnnouncementOverlay;
	import com.tinyspeck.engine.view.gameoverlay.LocationCanvasView;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ISpecialConfigDisplayer;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.itemstack.ItemstackAnimation;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.ui.chat.InputField;
	
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.utils.getTimer;
	
	public class AnnouncementController implements IFocusableComponent
	{
		/* singleton boilerplate */
		public static const instance:AnnouncementController = new AnnouncementController();
		
		private var iwov_pool:Vector.<InWindowAnnouncementOverlay> = new Vector.<InWindowAnnouncementOverlay>();
		private var ilov_pool:Vector.<InLocationAnnouncementOverlay> = new Vector.<InLocationAnnouncementOverlay>();
		private var isa_pool:Vector.<ItemstackAnimation> = new Vector.<ItemstackAnimation>();
		private var qa_pool:Vector.<QuoinAnimation> = new Vector.<QuoinAnimation>();
		private var lb_pool:Vector.<LightningBolt> = new Vector.<LightningBolt>();
		
		private var model:TSModelLocator;
		private var has_focus:Boolean;
		private var overlay_locker_count:int = 0;
		private var total_count:int = 0;
		private var gameRenderer:LocationRenderer;
		private var msl_controller:MissileController;
		
		public function AnnouncementController() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function getActiveOverlayByUid(uid:String):Object {
			var i:int;
			var isa:ItemstackAnimation;
			var iwov:InWindowAnnouncementOverlay;
			var ilov:InLocationAnnouncementOverlay;
			
			for (i=0;i<isa_pool.length;i++) {
				isa = ItemstackAnimation(isa_pool[int(i)]);
				if (isa.name == uid) {
					if (isa.running) return isa;
				}
			}
			for (i=0;i<iwov_pool.length;i++) {
				iwov = InWindowAnnouncementOverlay(iwov_pool[int(i)]);
				if (iwov.name == uid) {
					if (iwov.running && !iwov.finishing) return iwov;
				}
			}
			for (i=0;i<ilov_pool.length;i++) {
				ilov = InLocationAnnouncementOverlay(ilov_pool[int(i)]);
				if (ilov.name == uid) {
					if (ilov.running && !ilov.finishing) return ilov;
				}
			}
			
			if (LocationCanvasView.instance.annc && LocationCanvasView.instance.annc.uid == uid) {
				return LocationCanvasView.instance;
			}
			
			return null;
		}
		
		public function setOverlayState(payload:Object):void {
			var ol:Object = getActiveOverlayByUid(payload.uid);
			var aao:AbstractAnnouncementOverlay;
			if (ol is AbstractAnnouncementOverlay) { // does not work with itemstack animation overlays
				aao = ol as AbstractAnnouncementOverlay;
				aao.setArtViewState(payload.state, payload.config, payload.reposition);
				
				//any mouse stuff?
				if(payload.mouse){
					aao.setOverlayMouse(OverlayMouse.fromAnonymous(payload.mouse));
				}
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('can\'t setOverlayState on overlay uid:'+payload.uid+' because it is not an AbstractAnnouncementOverlay');
				}
			}
		}
		
		public function setOverlayScale(payload:Object):void {
			var ol:Object = getActiveOverlayByUid(payload.uid);
			var aao:AbstractAnnouncementOverlay;
			if (ol is AbstractAnnouncementOverlay) {
				aao = ol as AbstractAnnouncementOverlay;
				aao.changeScale(payload.scale, payload.time);
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.warn('can\'t setOverlayScale on overlay uid:'+payload.uid+' because it is not an AbstractAnnouncementOverlay');
				}				
			}
		}
		
		public function setOverlayOpacity(payload:Object):void {
			var ol:Object = getActiveOverlayByUid(payload.uid);
			var aao:AbstractAnnouncementOverlay;
			if (ol is AbstractAnnouncementOverlay) {
				aao = ol as AbstractAnnouncementOverlay;
				aao.setOpacity(OverlayOpacity.fromAnonymous(payload));
			} else {
				CONFIG::debugging {
					Console.warn('can\'t setOverlayOpacity on overlay uid:'+payload.uid+' because it is not an AbstractAnnouncementOverlay');
				}				
			}
		}
		
		public function setOverlayText(payload:Object):void {
			var ol:Object = getActiveOverlayByUid(payload.uid);
			var aao:AbstractAnnouncementOverlay;
			if (ol is AbstractAnnouncementOverlay) {
				aao = ol as AbstractAnnouncementOverlay;
				aao.setText(payload.text as Array);
			} else {
				CONFIG::debugging {
					Console.warn('can\'t setOverlayText on overlay uid:'+payload.uid+' because it is not an AbstractAnnouncementOverlay');
				}				
			}
		}
		
		public function cancelOverlay(uid:String, silently_fail:Boolean=false, fade_out_sec:Number=NaN):void {
			var ol:Object = getActiveOverlayByUid(uid);
			if (!isNaN(fade_out_sec) && ol is AbstractAnnouncementOverlay) {
				var aao:AbstractAnnouncementOverlay = ol as AbstractAnnouncementOverlay;
				CONFIG::debugging {
					Console.warn('overriding annc.fade_out_sec:'+fade_out_sec)
				}
				aao.annc.fade_out_sec = fade_out_sec;
				aao.setFadeOutSec();
			}
			
			if (ol) {
				CONFIG::debugging {
					Console.priinfo(276, 'cancelling overlay for uid:'+uid);
				}
				ol.cancel();
			} else {
				if (!silently_fail) {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('no overlay to cancel for uid:'+uid);
					}
				}
			}
		}
		
		// this is now being called from LR.deconstructLocation(), so let's hope it does not ruin everything
		public function cancelAllOverlaysWeCan():void {
			var i:int;
			var isa:ItemstackAnimation;
			var iwov:InWindowAnnouncementOverlay;
			var ilov:InLocationAnnouncementOverlay;
			
			for (i=0;i<isa_pool.length;i++) {
				isa = ItemstackAnimation(isa_pool[int(i)]);
				if (isa.parent) isa.parent.removeChild(isa);
				if (isa.running) isa.cancel();
			}
			for (i=0;i<iwov_pool.length;i++) {
				iwov = InWindowAnnouncementOverlay(iwov_pool[int(i)]);
				if (iwov.parent) iwov.parent.removeChild(iwov);
				if (iwov.running && !iwov.finishing) iwov.cancel();
			}
			for (i=0;i<ilov_pool.length;i++) {
				ilov = InLocationAnnouncementOverlay(ilov_pool[int(i)]);
				if (ilov.parent) ilov.parent.removeChild(ilov);
				if (ilov.running && !ilov.finishing) ilov.cancel();
			}
			
			if (msl_controller) msl_controller.cancelAllMissiles();
		}
		
		public function hideOverlaysForUserSnap():void {
			for each (var iwov:InWindowAnnouncementOverlay in iwov_pool) {
				if (iwov.running && iwov.annc.hide_in_snaps) iwov.visible = false;
			}
			for each (var ilov:InLocationAnnouncementOverlay in ilov_pool) {
				if (ilov.running && ilov.annc.hide_in_snaps) ilov.visible = false;
			}
		}
		
		public function unHideOverlaysForUserSnap():void {
			for each (var iwov:InWindowAnnouncementOverlay in iwov_pool) {
				if (iwov.running && iwov.annc.hide_in_snaps) iwov.visible = true;
			}
			for each (var ilov:InLocationAnnouncementOverlay in ilov_pool) {
				if (ilov.running && ilov.annc.hide_in_snaps) ilov.visible = true;
			}
		}
		
		public function hideAllOverlays():void {
			for each (var isa:ItemstackAnimation in isa_pool) {
				if (isa.running) isa.visible = false;
			}
			for each (var iwov:InWindowAnnouncementOverlay in iwov_pool) {
				if (iwov.running) iwov.visible = false;
			}
			for each (var ilov:InLocationAnnouncementOverlay in ilov_pool) {
				if (ilov.running) ilov.visible = false;
			}
		}
		
		public function unHideAllOverlays():void {
			for each (var isa:ItemstackAnimation in isa_pool) {
				if (isa.running) isa.visible = true;
			}
			for each (var iwov:InWindowAnnouncementOverlay in iwov_pool) {
				if (iwov.running) iwov.visible = true;
			}
			for each (var ilov:InLocationAnnouncementOverlay in ilov_pool) {
				if (ilov.running) ilov.visible = true;
			}
		}
		
		private function isAlreadyRunning(uid:String):Boolean {
			if (!uid) return false;
			var i:int;
			var isa:ItemstackAnimation;
			var iwov:InWindowAnnouncementOverlay;
			var ilov:InLocationAnnouncementOverlay;
			
			for (i=0;i<isa_pool.length;i++) {
				isa = ItemstackAnimation(isa_pool[int(i)]);
				if (isa.name == uid && isa.running) {
					return true;
				}
			}
			for (i=0;i<iwov_pool.length;i++) {
				iwov = InWindowAnnouncementOverlay(iwov_pool[int(i)]);
				if (iwov.name == uid && iwov.running && !iwov.finishing) {
					return true;
				}
			}
			for (i=0;i<ilov_pool.length;i++) {
				ilov = InLocationAnnouncementOverlay(ilov_pool[int(i)]);
				if (ilov.name == uid && ilov.running && !ilov.finishing) {
					return true;
				}
			}
			
			return false;
		}
		
		public function init():void {
			model = TSModelLocator.instance;
			gameRenderer = TSFrontController.instance.getMainView().gameRenderer;
			registerSelfAsFocusableComponent();
			primeLocationOverlayPool();
			msl_controller = new MissileController(model, gameRenderer);
			model.activityModel.registerCBProp(onNewAnnoucements, "announcements");
		}
		
		private function primeLocationOverlayPool():void {
			// This gets some anncs in their chat bubbles preloaded
			for (var i:int;i<10;i++) {
				var ilov:InLocationAnnouncementOverlay = new InLocationAnnouncementOverlay();
				ilov_pool.push(ilov);
				ilov.cancel();
			}
		}
		
		private function getItemstackAnimation(annc:Announcement):ItemstackAnimation {
			var isa:ItemstackAnimation;
			for (var i:int=0;i<isa_pool.length;i++) {
				if (!isa_pool[int(i)].running) {
					isa = isa_pool[int(i)];
					break;
				}
			}
			
			if (!isa) {
				isa = new ItemstackAnimation();
				isa_pool.push(isa);
			}
			
			isa.name = 'ItemstackAnimation'+String(total_count++);
			if (annc.uid) isa.name = annc.uid;
			return isa;
		}
		
		private function getInWindowOverlay(annc:Announcement):InWindowAnnouncementOverlay {
			var iwov:InWindowAnnouncementOverlay
			for (var i:int=0;i<iwov_pool.length;i++) {
				if (!iwov_pool[int(i)].running) {
					iwov = iwov_pool[int(i)];
					break;
				} 
			}
			
			if (!iwov) {
				iwov = new InWindowAnnouncementOverlay();
				iwov_pool.push(iwov);
			}
			
			iwov.name = 'InWindowAnnouncementOverlay'+String(total_count++);
			if (annc.uid) iwov.name = annc.uid;
			return iwov;
		}
		
		private function getInLocationOverlay(annc:Announcement):InLocationAnnouncementOverlay {
			var ilov:InLocationAnnouncementOverlay;
			for (var i:int=0;i<ilov_pool.length;i++) {
				if (!ilov_pool[int(i)].running) {
					ilov = ilov_pool[int(i)];
					break;
				} 
			}
			
			if (!ilov) {
				ilov = new InLocationAnnouncementOverlay();
				ilov_pool.push(ilov);
			}	
			
			ilov.name = 'InLocationAnnouncementOverlay'+String(total_count++);
			if (annc.uid) ilov.name = annc.uid;
			return ilov;
		}
		
		public function getQuoinAnimation():QuoinAnimation {
			for (var i:int=0;i<qa_pool.length;i++) {
				if (!qa_pool[int(i)].running) return qa_pool[int(i)];
			}
			
			var qa:QuoinAnimation = new QuoinAnimation();
			qa_pool.push(qa);
			return qa;
		}
		
		public function getLightningBolt():LightningBolt {
			for (var i:int=0;i<lb_pool.length;i++) {
				if (!lb_pool[int(i)].running) return lb_pool[int(i)];
			}
			
			var lb:LightningBolt = new LightningBolt();
			lb_pool.push(lb);
			return lb;
		}

		public function demandsFocus():Boolean {
			return false;
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			
		}
		
		public function hasFocus():Boolean {
			return has_focus;
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur')
			}
			has_focus = false;
		}
		
		public function registerSelfAsFocusableComponent():void {
			model.stateModel.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			model.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focus():void {
			CONFIG::debugging {
				Console.log(99, 'focus');
			}
			has_focus = true;
			
			// we should not change focus if it is in an input textfield, else it fucks up 
			// component focussing by keeping FocusEvent.FOCUS_IN from firing for the input
			if (!(StageBeacon.stage.focus is TextField && TextField(StageBeacon.stage.focus).type == TextFieldType.INPUT)) {
				// I'm not 100% sure this is EVER needed, but until we can test 100000 situs without, leaving it in
				StageBeacon.stage.focus = StageBeacon.stage;
			}
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return false;
		}
		
		private function takeFocus(annc:Announcement):void {
			overlay_locker_count++;
			
			CONFIG::debugging {
				Console.trackValue('AC overlay_locker_count', overlay_locker_count);
			}

			if (!has_focus) {
				if (model.stateModel.focused_component is InputField) {
					// in this case we don't really want to steal focus from the input field
					// so we just tuck the annc controller in focus history, to keep focus
					// from falling back to tsmainview
					TSFrontController.instance.putInFocusStack(this);
				} else {
					TSFrontController.instance.requestFocus(this, 'annc:'+annc.toString()+' overlay_locker_count:'+overlay_locker_count+' ');
				}
			}
		}
		
		public function overlayIsDone(annc:Announcement, aao:AbstractAnnouncementOverlay):void {			
			TSFrontController.instance.unregisterDisposableSpriteChangeSubscriber(aao);
			if (annc.locking) overlay_locker_count--;
			if (overlay_locker_count < 0) overlay_locker_count = 0;

			CONFIG::debugging {
				Console.trackValue('AC overlay_locker_count', overlay_locker_count);
			}
			//Console.warn('overlay_locker_count '+overlay_locker_count)
			if (overlay_locker_count == 0) TSFrontController.instance.releaseFocus(this);
			
			if (annc.type == Announcement.ITEMSTACK_OVERLAY) {
				var lis_view:LocationItemstackView = gameRenderer.getItemstackViewByTsid(annc.itemstack_tsid);
				if (lis_view) {
					lis_view.aivs_hidden_for_overlay = false;
				}
			}
			
			if (aao) aao.report('overlayIsDone');
		}
		
		public function reAddItemOrPcOverlayWhereItGoes(uid:String):void {
			var ol:Object = getActiveOverlayByUid(uid);
			var ilov:InLocationAnnouncementOverlay;
			if (!ol || !(ol is InLocationAnnouncementOverlay)) return;
			ilov = ol as InLocationAnnouncementOverlay;
			addItemOrPcOverlayWhereItGoes(ilov, ilov.annc);
		}
		
		public function addLocationOverlayWhereItGoes(ilov:InLocationAnnouncementOverlay, annc:Announcement):InLocationAnnouncementOverlay {
			
			if (annc.at_top) {
				var ilovAsDO:DisplayObject = DisplayObject(ilov);
				if (!ilovAsDO) {
					throw new Error("Only native DisplayObjects can be placed in scrolling overlay holder.");
				}
				gameRenderer.placeOverlayInSCH(ilovAsDO, annc.toString());
			} else if (annc.under_decos) {
				gameRenderer.placeOverlayBelowDecosInMG(ilov, annc.toString());
			}  else if (annc.at_bottom) {
				gameRenderer.placeOverlayAboveDecosInMG(ilov, annc.toString());
			} else {
				gameRenderer.placeOverlayInMG(ilov, annc.toString());
			}
			
			return ilov;
		}
		
		public function addItemOrPcOverlayWhereItGoes(ilov:InLocationAnnouncementOverlay, annc:Announcement):InLocationAnnouncementOverlay {
	 		
			if (annc.type == Announcement.PC_OVERLAY && annc.at_bottom) {
				gameRenderer.placeOverlayBelowAnAvatarInMG(ilov, annc.pc_tsid, annc.toString());
			} else if (annc.in_itemstack && annc.type == Announcement.ITEMSTACK_OVERLAY && annc.itemstack_tsid) {
				
				var special_config_displayer:ISpecialConfigDisplayer;
				if (annc.special_config_displayer) {
					special_config_displayer = annc.special_config_displayer;
				} else {
					var lis_view:LocationItemstackView = gameRenderer.getItemstackViewByTsid(annc.itemstack_tsid);
					if (lis_view) {
						special_config_displayer = lis_view as ISpecialConfigDisplayer;
					}
				}
				
				if (!special_config_displayer) {
					;
					CONFIG::debugging {
						Console.error(annc.local_uid+' WTF no special_config_displayer');
					}
				} else if (annc.under_itemstack) {
					special_config_displayer.addToSpecialBack(ilov as DisplayObject)
				} else {
					special_config_displayer.addToSpecialFront(ilov as DisplayObject)
				}
			} else if (annc.at_top) {
				//place it above everything
				gameRenderer.placeOverlayInSCHTop(DisplayObject(ilov), annc.toString());
			} else if (annc.under_itemstack && annc.type == Announcement.ITEMSTACK_OVERLAY && annc.itemstack_tsid) {
				gameRenderer.placeOverlayBelowAnItemstackInMG(ilov, annc.itemstack_tsid, annc.toString());
			} else if (annc.above_itemstack && annc.type == Announcement.ITEMSTACK_OVERLAY && annc.itemstack_tsid) {
				gameRenderer.placeOverlayAboveAnItemstackInMG(ilov, annc.itemstack_tsid, annc.toString());
			} else {
				if (annc.plot_id == -1){
					//place it above everything except for at_top overlays
					gameRenderer.placeOverlayInSCH(DisplayObject(ilov), annc.toString());
				} else {
					gameRenderer.placeOverlayBelowYourPlayerInMG(ilov, annc.toString());
				}
			}
			
			return ilov;
		}
		
		private function handleInLocationOverlays(annc:Announcement):void {
			var ilov:InLocationAnnouncementOverlay = getInLocationOverlay(annc);
			ilov.go(annc);
			
			var addedILOV:InLocationAnnouncementOverlay;
			
			switch (annc.type) {
				case Announcement.LOCATION_OVERLAY:
					addedILOV = addLocationOverlayWhereItGoes(ilov, annc);
					addedILOV.x = int(annc.x);
					addedILOV.y = int(annc.y); // this might be changed in InLocationAnnouncementOverlay to keep it viewable
					
					if (annc.uid == 'phantom_glitch') {
						Benchmark.addCheck('phantom_glitch at x:'+addedILOV.x+' y:'+addedILOV.y);
					}
					
					if (annc.uid == 'phantom_glitch') {
						Benchmark.addCheck('phantom_glitch parent:'+addedILOV.parent);
					}
					
					break;
				
				case Announcement.ITEMSTACK_OVERLAY:
					var lis_view:LocationItemstackView = gameRenderer.getItemstackViewByTsid(annc.itemstack_tsid);
					
					if (!lis_view) {
						CONFIG::debugging {
							Console.error('unknown itemstack_tsid in ITEMSTACK_OVERLAY annc: '+annc.itemstack_tsid);
						}
						overlayIsDone(annc, null);
						return;
					}
					
					// if this is a temporary overlay and the stack is not in view, ignore it
					if (!lis_view.worth_rendering && annc.duration) {
						overlayIsDone(annc, null);
						return;
					}
					
					lis_view.aivs_hidden_for_overlay = true;
					if(!lis_view.garden_view) annc.plot_id = -1;
					
					addedILOV = addItemOrPcOverlayWhereItGoes(ilov, annc);
					addedILOV.placeByLocationItemstackView(lis_view);
					if (annc.follow && !annc.in_itemstack) {
						TSFrontController.instance.registerDisposableSpriteChangeSubscriber(addedILOV, lis_view);
						addedILOV.worldDisposableSpriteChangeHandler(lis_view);
					}
					
					if (!annc.allow_bubble) lis_view.getRidOfBubble();
					
					break;
				
				case Announcement.PC_OVERLAY:
					var pc_view:AbstractAvatarView;
					if (annc.pc_tsid == model.worldModel.pc.tsid) {
						pc_view = gameRenderer.getAvatarView();
					} else {
						pc_view = gameRenderer.getPcViewByTsid(annc.pc_tsid);
					}
					
					if (!pc_view) {
						CONFIG::debugging {
							Console.error('unknown pc_tsid in PC_OVERLAY annc');
						}
						overlayIsDone(annc, null);
						return;
					}
					
					//pc overlays are never a garden!
					annc.plot_id = -1;
					
					addedILOV = addItemOrPcOverlayWhereItGoes(ilov, annc);
					addedILOV.placeByPcView(pc_view);
					TSFrontController.instance.registerDisposableSpriteChangeSubscriber(addedILOV, pc_view);
					ilov.worldDisposableSpriteChangeHandler(pc_view);
					break;
			}
		}
		
		private function doEmoteHiBonus(annc:Announcement):void {
			var pc_view:AbstractAvatarView;
			var view2:DisposableSprite;			
			
			if (model.worldModel.pc.tsid == annc.pc_tsid) {
				pc_view = gameRenderer.getAvatarView();
			} else {
				pc_view = gameRenderer.getPcViewByTsid(annc.pc_tsid);
			}
			
			if (annc.itemstack_tsid) {
				view2 = gameRenderer.getItemstackViewByTsid(annc.itemstack_tsid);
			} else if (annc.other_pc_tsid) {
				if (model.worldModel.pc.tsid == annc.other_pc_tsid) {
					view2 = gameRenderer.getAvatarView();
				} else {
					view2 = gameRenderer.getPcViewByTsid(annc.other_pc_tsid);
				}
			}
			
			if (!pc_view || !view2) {
				CONFIG::debugging {
					Console.error('WTF no view?');
				}
				return;
			}
			
			var x:int = pc_view.x-((pc_view.x-view2.x)/2);
			var y:int = pc_view.y-((pc_view.y-view2.y)/2);
			var uid:String = getTimer().toString();
			
			var loc_overlay_annc_ob:Object = {
				type: "location_overlay",
				item_class: "hi_overlay",
				duration: 2000,
				center_view:true,
				state: "hi",
				x: x,
				y: y-210,
				config: {variant:annc.variant+'2x'},
				at_top:true,
				uid:uid
			}
			
			model.activityModel.announcements = Announcement.parseMultiple([loc_overlay_annc_ob]);
				
			var ilov:InLocationAnnouncementOverlay = getActiveOverlayByUid(uid) as InLocationAnnouncementOverlay;

			if (!ilov) {
				CONFIG::debugging {
					Console.error('WTF no ilov?');
				}
				return;
			}
			
			var bolt_color:uint = annc.variant_color ? ColorUtil.colorStrToNum(annc.variant_color) : 0xffffff;
			var bolt:LightningBolt;
			
			var delta_y:int = -100;
			
			bolt = getLightningBolt();
			gameRenderer.placeOverlayInSCH(bolt, 'hi emote');
			bolt.goWithDisposableSprites(0, 1.5, pc_view, ilov, bolt_color, 0, true, -100, 0, 20);
			
			bolt = getLightningBolt();
			gameRenderer.placeOverlayInSCH(bolt, 'hi emote');
			bolt.goWithDisposableSprites(0, 1.5, view2, ilov, bolt_color, 0, true, -100, 0, 20);
			
			SoundMaster.instance.playSound('HI_FLOWERS_2X');
			
			if (annc.emote_bonus_mood_granted && annc.emote_bonus_mood_granted[pc_view.tsid]) {
				model.activityModel.announcements = Announcement.parseMultiple([{
					type: "pc_overlay",
					duration: 2000,
					pc_tsid: pc_view.tsid,
					delta_y: -40,
					center_text: true,
					width:300,
					text: ['<p align="center"><span class="nuxp_vog_smallest">+'+annc.emote_bonus_mood_granted[pc_view.tsid]+' mood!</span></p>']
				}]);
			}
			
			if (view2 is AbstractAvatarView) {
				var view2_pc_view:AbstractAvatarView = view2 as AbstractAvatarView;
				if (annc.emote_bonus_mood_granted && annc.emote_bonus_mood_granted[view2_pc_view.tsid]) {
					model.activityModel.announcements = Announcement.parseMultiple([{
						type: "pc_overlay",
						duration: 2000,
						pc_tsid: view2_pc_view.tsid,
						delta_y: -40,
						center_text: true,
						width:300,
						text: ['<p align="center"><span class="nuxp_vog_smallest">+'+annc.emote_bonus_mood_granted[view2_pc_view.tsid]+' mood!</span></p>']
					}]);
				}
			}
			
		}
		
		private function doEmoteHi(annc:Announcement):void {
			var i:int;
			var this_is_the_say_hier:Boolean = (annc.pc_tsid == model.worldModel.pc.tsid);
			var pc_view:AbstractAvatarView;
			var lis_view:LocationItemstackView;
			var shard_pc_view:AbstractAvatarView;
			var shard_lis_view:LocationItemstackView;
			var shard_pc_tsid:String;
			var shard_itemstack_tsid:String;
			var shard_mood_granted:int;
			var delay_shard_ms:int = 900;
			var show_shards:Boolean = true;
			var missile_start_delta_y:int;
			
			var overlay_annc_ob:Object = {
				item_class: "hi_overlay",
				duration: 2000,
				state: "hi",
				delta_x: 0,
				delta_y: annc.delta_y,
				delta_x_relative_to_face:true,
				config: {variant:annc.variant}
			}
				
			if (this_is_the_say_hier) {
				pc_view = gameRenderer.getAvatarView();
			} else {
				if (annc.itemstack_tsid) {
					lis_view = gameRenderer.getItemstackViewByTsid(annc.itemstack_tsid);
					if (!lis_view) {
						return;
					}
				} else {
					pc_view = gameRenderer.getPcViewByTsid(annc.pc_tsid);
					if (!pc_view || !pc_view.worth_rendering) {
						return;
					}
				}
			}
			
			if (pc_view) {
				overlay_annc_ob.type = 'pc_overlay';
				overlay_annc_ob.pc_tsid = annc.pc_tsid;
				// to match up to where the hi overlay is placed above the say hiers head
				missile_start_delta_y = annc.delta_y+-26;
			} else if (lis_view) {
				overlay_annc_ob.itemstack_tsid = annc.itemstack_tsid;
				overlay_annc_ob.type = 'itemstack_overlay';
				// to match up to where the hi overlay is placed above the say hiers head
				missile_start_delta_y = lis_view.getYAboveDisplay()+annc.delta_y+-26;
			} else {
				return;
			}
				
			model.activityModel.announcements = Announcement.parseMultiple([overlay_annc_ob]);
			
			if (!show_shards) return;
			if (!annc.emote_shards || !annc.emote_shards.length) return;
			
			// add in the quoin shard bolts and bursts
				
			if (this_is_the_say_hier) {
				//if (!model.worldModel.pc.emotion) TSFrontController.instance.playHappyAnimation();
				SoundMaster.instance.playSoundAllowMultiples('HI_FLOWERS');
			}
			
			for (i=0;i<annc.emote_shards.length;i++) {
				if (annc.emote_shards[i].pc_tsid) {
					shard_pc_tsid = annc.emote_shards[i].pc_tsid;
					shard_mood_granted = annc.emote_shards[i].mood_granted;
					if (model.worldModel.pc.tsid == shard_pc_tsid) {
						SoundMaster.instance.playSoundAllowMultiples('HI_FLOWERS');
						shard_pc_view = gameRenderer.getAvatarView();
					} else {
						shard_pc_view = gameRenderer.getPcViewByTsid(shard_pc_tsid);
					}
					if (!shard_pc_view) continue;
				} else if (annc.emote_shards[i].itemstack_tsid) {
					shard_itemstack_tsid = annc.emote_shards[i].itemstack_tsid;
					shard_lis_view = gameRenderer.getItemstackViewByTsid(shard_itemstack_tsid);
					if (!shard_lis_view) continue;
				}
				
				var from_tsid:String;
				if (pc_view) {
					from_tsid = pc_view.tsid;
				} else if (lis_view) {
					from_tsid = lis_view.tsid;
				}
				
				StageBeacon.setTimeout(msl_controller.doEmoteHiMissile, delay_shard_ms, annc.accelerate, from_tsid, pc_view||lis_view, missile_start_delta_y, annc.variant, shard_pc_view||shard_lis_view, shard_mood_granted);
			}
		}
		
		private function doQuoinGot(annc:Announcement):void {
			var start_x:int = int(annc.x);
			var start_y:int = int(annc.y)-15;
			var shard_x:int;
			var shard_y:int;
			var last_x:int;
			var last_y:int;
			var txt:String;
			var delta:int;
			var m:int;
			var shard_annc:Announcement;
			var bolt:LightningBolt;
			var this_is_the_quoin_getter:Boolean = annc.pc_tsid == model.worldModel.pc.tsid;
			var small_text_size:int = 16;
			var small_circle_size:int = 34;
			var shard_pc:PC;
			var qa:QuoinAnimation;
			
			// add in the quoin shard bolts and bursts
			if (annc.quoin_shards) {
				// if you got the quoin, show shards
				var show_shards:Boolean = this_is_the_quoin_getter;
				
				if (!show_shards) {
					// if you are one of the shards, show shards
					for (m=0;m<annc.quoin_shards.length;m++) {
						if (annc.quoin_shards[m].pc_tsid == model.worldModel.pc.tsid) {
							show_shards = true;
							break;
						}
					}
				}
				
				if (show_shards) {
					for (m=0;m<annc.quoin_shards.length;m++) {
						shard_annc = Announcement.fromAnonymous(annc.quoin_shards[m]);
						shard_pc = model.worldModel.getPCByTsid(shard_annc.pc_tsid);
						if (shard_pc) {
							shard_x = shard_pc.x;
							shard_y = shard_pc.y-60;
						} else {
							shard_x = int(shard_annc.x);
							shard_y = int(shard_annc.y);
						}
						bolt = getLightningBolt();
						gameRenderer.placeOverlayInSCH(bolt, shard_annc.toString());
						if (qa) {
							bolt.go(.2*(m), 1.5, last_x, last_y, shard_x, shard_y, true);
						} else {
							bolt.go(.2*(m), 1.5, start_x, start_y, shard_x, shard_y, true);
						}
						
						last_x = shard_x;
						last_y = shard_y;
						
						qa = getQuoinAnimation();
						qa.x = shard_x;
						qa.y = shard_y;
						gameRenderer.placeOverlayInSCH(qa, shard_annc.toString());
						
						var delay:Number = .2*(m+1);
						if (shard_annc.pc_tsid == model.worldModel.pc.tsid) {
							delta = shard_annc.delta;
							txt = shard_annc.stat;
							if (shard_annc.stat == 'time') {
								delta = delta*1; //reverse it
								txt = 'seconds';
							}
							qa.go(delay, delta, txt);
						} else {
							qa.go(delay, m+2, '', small_text_size, small_circle_size, true);
						}
					}
				}
			}
			
			qa = getQuoinAnimation();
			qa.x = start_x;
			qa.y = start_y;
			gameRenderer.placeOverlayInSCH(qa, annc.toString());
			if (this_is_the_quoin_getter) {
				// anim for the quoin getter
				txt = annc.stat;
				delta = annc.delta;
				if (annc.stat == 'time') {
					delta = delta*1; //reverse it
					txt = 'seconds';
				}
				qa.go(0, delta, txt);
			} else if (show_shards) {
				qa.go(0, 1, '', small_text_size, small_circle_size, true);
			} else {
				// anim for someone in same loc as the quoin getter
				qa.go();
			}
		}
		
		private function onNewAnnoucements(anncs:Vector.<Announcement>):void {
			var annc:Announcement;
			var iwov:InWindowAnnouncementOverlay;
			var isa:ItemstackAnimation;
			var orig_pt:Point;
			var dest_pt:Point;
			var escrow_tsid:String = model.worldModel.pc ? model.worldModel.pc.escrow_tsid : '';
			var chunks:Array;
			var lis_view:LocationItemstackView;
			
			for (var i:int=0;i<anncs.length;i++) {
				annc = anncs[int(i)];
				
				CONFIG::locodeco {
					if (model.stateModel.editing && !annc.allow_in_locodeco) continue;
				}

				if (annc.text) {
					NewxpLogger.log('annc', 'uid:'+annc.uid+' text:'+annc.text);
				} else if (annc.swf_url) {
					NewxpLogger.log('annc', 'uid:'+annc.uid+' swfkey:'+model.stateModel.overlay_keys[annc.swf_url]);
				} else if (annc.type == Announcement.QUOIN_GOT) {
					NewxpLogger.log('quoin_got', annc.delta+' '+annc.stat);
				}
				
				//Console.info('Announcement type: '+annc.type);
				
				// I BELIEVE THIS IS LEGACY AND UNUSED!!! OVERLAY_STATE is a msg type, not an annc type
				if (annc.type == Announcement.OVERLAY_STATE) {
					; // satisfy compiler
					CONFIG::debugging {
						if (isAlreadyRunning(annc.uid)) {
							Console.info('changing state for annc uid:'+annc.uid);
						} else {
							Console.warn('can\'t change state for annc uid:'+annc.uid+' b/c it is not running');
						}
					}
				} else {
					if (isAlreadyRunning(annc.uid)) {
						CONFIG::debugging {
							Console.priwarn(276, 'annc uid:"'+annc.uid+'" is currently running');
						}
						continue;
					} else if (annc.uid) {
						; // satisfy compiler
						CONFIG::debugging {
							Console.priinfo(276, 'starting annc uid:'+annc.uid);
						}
					}
				}
				
				switch (annc.type) {
					
					case Announcement.LOCATION_OVERLAY:
					case Announcement.ITEMSTACK_OVERLAY:
					case Announcement.PC_OVERLAY:
					case Announcement.VP_OVERLAY:
					case Announcement.WINDOW_OVERLAY:
						if (annc.locking) takeFocus(annc); // comment this out if you want to change things to do the locking at fadein
						model.activityModel.growl_message = annc.msg;
						model.activityModel.activity_message = Activity.createFromCurrentPlayer(annc.msg);
						break;
					default:
						break;
				}
				
				//Console.warn('ANNC TYPE', annc.type);
				switch (annc.type) {
					
					case Announcement.LOCATION_OVERLAY:
					case Announcement.ITEMSTACK_OVERLAY:
					case Announcement.PC_OVERLAY:
						handleInLocationOverlays(annc);
						break;
					
					case Announcement.VP_CANVAS:
						LocationCanvasView.instance.show(annc);
						break;
					
					case Announcement.VP_OVERLAY:
						iwov = getInWindowOverlay(annc);
						if (annc.at_bottom) {
							TSFrontController.instance.getMainView().addView(iwov, true);
						} else {
							TSFrontController.instance.addUnderCursor(iwov);
						}
						iwov.go(annc)
						break;
					case Announcement.WINDOW_OVERLAY:
						iwov = getInWindowOverlay(annc);
						TSFrontController.instance.addUnderCursor(iwov);
						iwov.go(annc)
						break;
					
					case Announcement.PLAY_SOUND:
						//Console.info('GS says play '+annc.sound)
						if (annc.sound) {
							SoundMaster.instance.playSound(annc.sound, (annc.loop_count ? annc.loop_count : 0), (annc.fade ? annc.fade : 0), false, annc.is_exclusive, annc.allow_multiple);
						} else {
							; // satisfy compiler
							CONFIG::debugging {
								Console.warn(annc.type+' missing sound');
							}
						}
						break;
					
					case Announcement.STOP_SOUND:
						if (annc.sound) {
							SoundMaster.instance.stopSound(annc.sound, (annc.fade ? annc.fade : 0));
						} else {
							; // satisfy compiler
							CONFIG::debugging {
								Console.warn(annc.type+' missing sound');
							}
						}
						break;
					
					case Announcement.PLAY_MUSIC:
						if (annc.mp3_url) {
							if (annc.mp3_url.indexOf('.mp3') == -1) {
								; // satisfy compiler
								CONFIG::debugging {
									Console.error(annc.type+' has a bad mp3_url'+annc.mp3_url);
								}
								BootError.handleError(annc.type+' has a bad mp3_url'+annc.mp3_url, new Error('BAD_MP3_URL'), [annc.type, 'announcment'], true);
							} else {
								SoundMaster.instance.playSound(annc.mp3_url, annc.loop_count, annc.fade, true);
							}
						} else {
							; // satisfy compiler
							CONFIG::debugging {
								Console.warn(annc.type+' missing mp3_url');
							}
						}
						break;
					
					case Announcement.STOP_MUSIC:
						if (annc.mp3_url) {
							if (annc.fade && annc.fade > 10) {
								CONFIG::debugging {
									Console.warn('ridiculous fade on an Announcement.STOP_MUSIC:'+annc.fade);
								}
								annc.fade = 1;
							} 
							SoundMaster.instance.stopSound(annc.mp3_url, annc.fade);
						} else {
							; // satisfy compiler
							CONFIG::debugging {
								Console.warn(annc.type+' missing mp3_url');
							}
						}
						break;
					
					case Announcement.STOP_ALL_SOUND_EFFECTS:
						SoundMaster.instance.stopAllSoundEffects(annc.fade);
						break;
					
					case Announcement.STOP_ALL_MUSIC:
						SoundMaster.instance.stopAllMusic(annc.fade);
						break;
						
					case Announcement.NEW_FAMILIAR_MSGS:
						var was:int = model.worldModel.pc.familiar.messages;
						model.worldModel.pc.familiar.messages = annc.num;
						CONFIG::debugging {
							Console.trackValue('PC fam msgs', model.worldModel.pc.familiar.messages);
						}

						if (annc.num > was) {
							TSFrontController.instance.maybeTalkToFamiliar();
						}
						
						break;
					
					case Announcement.XP_STAT:
						CONFIG::debugging {
							Console.warn('SENDING XP_STAT, WHY?!?! USE IMAGINATION_STAT');
						}
						break;
					
					case Announcement.MOOD_STAT:
						if (annc.delay_ms) {
							StageBeacon.setTimeout(StatBurstController.instance.onMoodChange, annc.delay_ms, annc.delta)
						} else {
							StatBurstController.instance.onMoodChange(annc.delta);
						}
						break;
					
					case Announcement.ENERGY_STAT:
						StatBurstController.instance.onEnergyChange(annc.delta);
						
						//if we lost energy, tack that on to the energy burned for the day
						if(annc.delta < 0){
							model.worldModel.pc.stats.energy_spent_today += annc.delta;
							model.worldModel.triggerCBProp(false,false,"pc","stats");
						}
						break;
					
					case Announcement.CURRANTS_STAT:
						StatBurstController.instance.onCurrantsChange(annc.delta);
						break;
					
					case Announcement.IMAGINATION_STAT:
						StatBurstController.instance.onXPChange(annc.delta);
						
						//if we gained iMG, tack it on for the iMG gained for the day
						if(annc.delta > 0){
							model.worldModel.pc.stats.xp_gained_today += annc.delta;
							model.worldModel.pc.stats.imagination_gained_today += annc.delta;
							model.worldModel.triggerCBProp(false,false,"pc","stats");
						}
						break;
					case Announcement.FAVOR_STAT:
					case Announcement.MEDITATION_STAT:
					case Announcement.QUOINS_STAT:
					case Announcement.CREDITS_STAT:
						//doing nothing at the moment
						break;
					
					case Announcement.QUOINS_STAT_MAX:
						//player is allowed to have a different amount for max quoins for the day
						model.worldModel.pc.stats.quoins_today.max = annc.delta;
						model.worldModel.triggerCBProp(false,false,"pc","stats");
						break;
					
					case Announcement.SUBSCRIBER_STAT:
						//the player's subscription status changed
						model.worldModel.pc.stats.is_subscriber = annc.status === true;
						model.worldModel.triggerCBProp(false,false,"pc","stats");
						break;
					
					case Announcement.FAMILIAR_TO_PACK:
						orig_pt = YouDisplayManager.instance.getHeaderCenterPt();
						orig_pt = gameRenderer.translateGlobalCoordsToLocation(orig_pt.x, orig_pt.y);
						if(TrophyCaseDialog.instance.visible && TrophyCaseManager.instance.isTsidInTrophyCases([annc.dest_path])){
							dest_pt = TrophyCaseDialog.instance.translateSlotCenterToGlobal(annc.dest_slot, annc.dest_path);
						} else if(PackDisplayManager.instance.isTsidOwnedByPlayer(annc.dest_path)){
							dest_pt = TSFrontController.instance.translatePackSlotToGlobal(annc.dest_slot, annc.dest_path);
						} else {
							//unknown tsid
							break;
						}
						
						/* 	WE USED TO DO THIS CHECK TO MAKE SURE THAT THE DEST_PATH WAS IN THE PACK, BUT IT IS UNNCEC AS LONG
							AS WE CHECK THE TROPHY CASE FIRST. PLUS, IT BREAKS THINGS IN THE CASE WHERE THE DEST_PATH IS SIMPLY BEING PLACED
						 	IN THE PACK ROOT. MAYBE WE SHOUDL DO THIS IF THE DEST_PATCH CONTAINS A SLASH THOUGH, HMMMM
						
						else if(PackDisplayManager.instance.isTsidInPacks([annc.dest_path])){
							dest_pt = TSFrontController.instance.translatePackSlotToGlobal(annc.dest_slot, annc.dest_path);
						}
						else {
							//no where to go, throw a warn and break out
							Console.warn('Could not find a place to animate to!');
							break;
						}
						*/
						
						isa = getItemstackAnimation(annc);
						isa.go(orig_pt, dest_pt, annc.item_class, annc.count, annc.type, annc.dest_path, annc);
						break;
					
					case Announcement.PACK_TO_PACK:
						//PC OWNED bag or root of pack NOT in a location
						if(TrophyCaseDialog.instance.visible && TrophyCaseManager.instance.isTsidInTrophyCases([annc.orig_path, annc.dest_path])){
							orig_pt = TrophyCaseDialog.instance.translateSlotCenterToGlobal(annc.orig_slot, annc.orig_path);
							dest_pt = TrophyCaseDialog.instance.translateSlotCenterToGlobal(annc.dest_slot, annc.dest_path);
						} else if(TradeDialog.instance.visible && PackDisplayManager.instance.isContainerTsidPrivate(annc.orig_path, annc.dest_path)){
							//if we are removing something from our side, don't animate because it's EXPENSIVE
							if(annc.orig_path.indexOf(escrow_tsid) >= 0 && annc.dest_path.indexOf(escrow_tsid) >= 0) break;

							orig_pt = TradeDialog.instance.translateSlotCenterToGlobal(annc.orig_slot, annc.orig_path);
							dest_pt = TradeDialog.instance.translateSlotCenterToGlobal(annc.dest_slot, annc.dest_path);
						} else if(PackDisplayManager.instance.isTsidOwnedByPlayer(annc.orig_path, true, annc.dest_path)){
							orig_pt = TSFrontController.instance.translatePackSlotToGlobal(annc.orig_slot, annc.orig_path);
							dest_pt = TSFrontController.instance.translatePackSlotToGlobal(annc.dest_slot, annc.dest_path);
						} else {
							//how did we get down here?! the call to isContainerOwnedByPlayer throws a console error
							break;
						}
						isa = getItemstackAnimation(annc);
						isa.go(orig_pt, dest_pt, annc.item_class, -annc.count, annc.type, annc.orig_path, annc);
						break;
					
					case Announcement.BAG_TO_BAG:
						//IN LOCATION BAG
						if(CabinetDialog.instance.visible && CabinetManager.instance.isTsidInCabinets([annc.orig_path, annc.dest_path])){
							orig_pt = CabinetDialog.instance.translateSlotCenterToGlobal(annc.orig_slot);
							dest_pt = CabinetDialog.instance.translateSlotCenterToGlobal(annc.dest_slot);
						} else if(TrophyCaseDialog.instance.visible && TrophyCaseManager.instance.isTsidInTrophyCases([annc.orig_path, annc.dest_path])){
							orig_pt = TrophyCaseDialog.instance.translateSlotCenterToGlobal(annc.orig_slot, annc.orig_path);
							dest_pt = TrophyCaseDialog.instance.translateSlotCenterToGlobal(annc.dest_slot, annc.dest_path);
						} else {
							//how did we get down here?! the call to isContainerOwnedByPlayer throws a console error
							CONFIG::debugging {
								Console.warn('In-location bag that isn\'t a cabinet or trophy case. WTF IS IT?!');
							}
							break;
						}
						
						isa = getItemstackAnimation(annc);
						isa.go(orig_pt, dest_pt, annc.item_class, -annc.count, annc.type, annc.orig_path, annc);
						break;
					
					case Announcement.BAG_TO_PACK:
						CONFIG::debugging {
							Console.warn('BAG_TO_PACK '+annc.orig_path);
						}
						//Moving from IN LOCATION bag to PC bag or root pack
						if(TrophyCaseDialog.instance.visible && TrophyCaseManager.instance.isTsidInTrophyCases([annc.orig_path, annc.dest_path])){
							orig_pt = TrophyCaseDialog.instance.translateSlotCenterToGlobal(annc.orig_slot, annc.orig_path);
							dest_pt = TrophyCaseDialog.instance.translateSlotCenterToGlobal(annc.dest_slot, annc.dest_path);
						} else if(PackDisplayManager.instance.isTsidOwnedByPlayer(annc.dest_path)){
							if (TSFrontController.instance.isStorageUIOpen()) {
								// optimistically I think it is related to cabinet or trophy! Do it normal
								orig_pt = TSFrontController.instance.translateLocationBagSlotToGlobal(annc.orig_slot, annc.orig_path);
							} else {
								// it is a bag in location, like sdb, or butler
								// hacky switch over of annc type! 
								// must get orig_pt in location as we'll move the ItemstackAnimation into location before animating it to its dest
								CONFIG::debugging {
									Console.info('changing annc type from '+annc.type+' to '+ Announcement.FLOOR_TO_PACK);
								}
								annc.type = Announcement.FLOOR_TO_PACK;
								chunks = annc.orig_path.split('/');
								lis_view = gameRenderer.getItemstackViewByTsid(chunks[0]);
								if (lis_view) {
									orig_pt = new Point(lis_view.x, lis_view.y);
								} else {
									orig_pt = new Point(model.worldModel.pc.x, model.worldModel.pc.y);
								}
							}
							dest_pt = TSFrontController.instance.translatePackSlotToGlobal(annc.dest_slot, annc.dest_path);
						} else {
							CONFIG::debugging {
								Console.warn('unknown orig_path '+annc.orig_path);
							}
							break;
						}

						isa = getItemstackAnimation(annc);
						isa.go(orig_pt, dest_pt, annc.item_class, -annc.count, annc.type, annc.orig_path, annc);
						break;
					
					case Announcement.PACK_TO_BAG:
						//Moving from PC bag to IN LOCATION bag
						if(TrophyCaseDialog.instance.visible && TrophyCaseManager.instance.isTsidInTrophyCases([annc.orig_path, annc.dest_path])){
							orig_pt = TrophyCaseDialog.instance.translateSlotCenterToGlobal(annc.orig_slot, annc.orig_path);
							dest_pt = TrophyCaseDialog.instance.translateSlotCenterToGlobal(annc.dest_slot, annc.dest_path);
						} else if(PackDisplayManager.instance.isTsidOwnedByPlayer(annc.dest_path), false){ // we dont want logging if it fails, because it may be an sdb or butler type thing
							orig_pt = TSFrontController.instance.translatePackSlotToGlobal(annc.orig_slot, annc.orig_path);
							dest_pt = TSFrontController.instance.translateLocationBagSlotToGlobal(annc.dest_slot, annc.dest_path);
						} else {
							orig_pt = TSFrontController.instance.translatePackSlotToGlobal(annc.orig_slot, annc.orig_path);
							CONFIG::debugging {
								Console.info('changing annc type from '+annc.type+' to '+ Announcement.PACK_TO_FLOOR);
							}
							annc.type = Announcement.PACK_TO_FLOOR;
							chunks = annc.dest_path.split('/');
							lis_view = gameRenderer.getItemstackViewByTsid(chunks[0]);
							if (lis_view) {
								dest_pt = new Point(lis_view.x, lis_view.y);
							} else {
								CONFIG::debugging {
									Console.error('Container/Bag passed that is NOT owned by the player! and the annc.dest_path is not a lis-view. Better tell Serguei.', annc.dest_path);
								}
								dest_pt = new Point(model.worldModel.pc.x, model.worldModel.pc.y);
							}
							
							//trying to animate a tsid that's no longer owned by the player
							//break;
						}
						
						isa = getItemstackAnimation(annc);
						isa.go(orig_pt, dest_pt, annc.item_class, -annc.count, annc.type, annc.orig_path, annc);
						break;
					
					case Announcement.FLOOR_TO_BAG:
						// we currently assume this is just meant to be animated to the dest bag, not into it.
						// should we want to change that, we'll need to check for open cabinet/trophy case dialogs
					
						orig_pt = new Point(annc.orig_x, annc.orig_y); // leave these in location space
						
						if (annc.dest_path) {
							chunks = annc.dest_path.split('/');
							lis_view = gameRenderer.getItemstackViewByTsid(chunks[0]);
							if (lis_view) {
								dest_pt = new Point(lis_view.x, lis_view.y);
							} else {
								dest_pt = new Point(model.worldModel.pc.x, model.worldModel.pc.y);
							}
						} else {
							dest_pt = new Point(annc.dest_x, annc.dest_y); // leave these in location space
						}
						
						isa = getItemstackAnimation(annc);
						isa.go(orig_pt, dest_pt, annc.item_class, annc.count, annc.type, annc.dest_path, annc);
						break;
					
					case Announcement.FLOOR_TO_PACK:
						//check for a container we have access to
						if(PackDisplayManager.instance.isTsidOwnedByPlayer(annc.dest_path)){
							if (annc.orig_path) {
								chunks = annc.orig_path.split('/');
								lis_view = gameRenderer.getItemstackViewByTsid(chunks[0]);
								if (lis_view) {
									orig_pt = new Point(lis_view.x, lis_view.y);
								} else {
									orig_pt = new Point(annc.orig_x, annc.orig_y); // leave these in location space, as we'll move the ItemstackAnimation into location before animating it to its dest
									//we used to do this
									//orig_pt = new Point(model.worldModel.pc.x, model.worldModel.pc.y);
									//but I think this is smarter
									orig_pt = new Point(annc.orig_x, annc.orig_y); // leave these in location space, as we'll move the ItemstackAnimation into location before animating it to its dest
								}
							} else {
								orig_pt = new Point(annc.orig_x, annc.orig_y); // leave these in location space, as we'll move the ItemstackAnimation into location before animating it to its dest
							}
							
							dest_pt = TSFrontController.instance.translatePackSlotToGlobal(annc.dest_slot, annc.dest_path);
							
							isa = getItemstackAnimation(annc);
							isa.go(orig_pt, dest_pt, annc.item_class, annc.count, annc.type, annc.dest_path, annc);
						}
						break;
					
					case Announcement.PACK_TO_FLOOR:
						//dropping to the floor adds the item to the location
						var item:Item = model.worldModel.getItemByTsid(annc.item_class);
						if (item.is_furniture) {
							CONFIG::debugging {
								Console.error(annc.type+' FOR '+annc.item_class+'????');
							}
							break;
						}
						orig_pt = TSFrontController.instance.translatePackSlotToGlobal(annc.orig_slot, annc.orig_path);
						if (!orig_pt) {
							CONFIG::debugging {
								Console.error('could not get orig_pt for '+annc.orig_slot+' '+annc.orig_path);
							}
							break;
						}
						dest_pt = new Point(annc.dest_x, annc.dest_y); // leave these in location space, as we'll move the ItemstackAnimation into location before animating it to its dest
						isa = getItemstackAnimation(annc);
						isa.go(orig_pt, dest_pt, annc.item_class, -annc.count, annc.type, annc.orig_path, annc);
						break;
					
					case Announcement.FAMILIAR_TO_FLOOR:
						//dropping to the floor adds the item to the location
						orig_pt = YouDisplayManager.instance.getHeaderCenterPt();
						dest_pt = new Point(annc.dest_x, annc.dest_y); // leave these in location space, as we'll move the ItemstackAnimation into location before animating it to its dest
						isa = getItemstackAnimation(annc);
						isa.go(orig_pt, dest_pt, annc.item_class, annc.count, annc.type, annc.orig_path, annc);
						break;
					
					case Announcement.PACK_TO_PC:
						//From your pack to another player's pack
						if(TradeDialog.instance.visible && PackDisplayManager.instance.isContainerTsidPrivate(annc.orig_path)){
							orig_pt = TradeDialog.instance.translateSlotCenterToGlobal(annc.orig_slot, annc.orig_path);
							dest_pt = new Point(annc.dest_x, annc.dest_y);
						} else {
							orig_pt = TSFrontController.instance.translatePackSlotToGlobal(annc.orig_slot, annc.orig_path);
						}
						
						dest_pt = new Point(annc.dest_x, annc.dest_y-50); // leave these in location space, as we'll move the ItemstackAnimation into location before animating it to its dest
						isa = getItemstackAnimation(annc);
						isa.go(orig_pt, dest_pt, annc.item_class, -annc.count, annc.type, annc.orig_path, annc);
						break;
					
					case Announcement.PC_TO_PACK:
						//from another player's pack to your pack
						if(TradeDialog.instance.visible && PackDisplayManager.instance.isContainerTsidPrivate(annc.dest_path)){
							dest_pt = TradeDialog.instance.translateSlotCenterToGlobal(annc.dest_slot, annc.dest_path);
						} else if(PackDisplayManager.instance.isTsidOwnedByPlayer(annc.dest_path)){
							dest_pt = TSFrontController.instance.translatePackSlotToGlobal(annc.dest_slot, annc.dest_path);
						} else {
							//unknown
							break;
						}
						
						orig_pt = new Point(annc.orig_x, annc.orig_y); // leave these in location space, as we'll move the ItemstackAnimation into location before animating it to its dest
						isa = getItemstackAnimation(annc);
						isa.go(orig_pt, dest_pt, annc.item_class, annc.count, annc.type, annc.dest_path, annc);
						break;
					
					case Announcement.PC_TO_FLOOR:
						orig_pt = new Point(annc.orig_x, annc.orig_y);
						dest_pt = new Point(annc.dest_x, annc.dest_y);
						isa = getItemstackAnimation(annc);
						isa.go(orig_pt, dest_pt, annc.item_class, -annc.count, annc.type, null, annc);
						break;
					
					case Announcement.FLOOR_TO_PC:
						orig_pt = new Point(annc.orig_x, annc.orig_y);
						dest_pt = new Point(annc.dest_x, annc.dest_y-50);
						isa = getItemstackAnimation(annc);
						isa.go(orig_pt, dest_pt, annc.item_class, -annc.count, annc.type, null, annc);
						break;
						
						case Announcement.EMOTE:
						if (annc.emote == Emotes.EMOTE_TYPE_HI) {
							doEmoteHi(annc);
						}
						break;
						
					case Announcement.EMOTE_BONUS:
						doEmoteHiBonus(annc);
						break;
						
					case Announcement.QUOIN_GOT:
						doQuoinGot(annc);
						break;
					
					default:
						CONFIG::debugging {
							Console.warn('unknown annc.type:'+annc.type)
						}
						break;
				}

			}
		}
	}
}