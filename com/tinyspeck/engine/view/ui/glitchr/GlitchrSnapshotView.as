package com.tinyspeck.engine.view.ui.glitchr {
	import com.quasimondo.geom.ColorMatrix;
	import com.quietless.bitmap.BitmapSnapshot;
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.API;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.memory.EnginePools;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.physics.data.PhysicsQuery;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.TSSprite;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.AbstractAvatarView;
	import com.tinyspeck.engine.view.AbstractTSView;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.InputFieldSubmit;
	import com.tinyspeck.engine.view.ui.glitchr.filters.GlitchrFiltersView;
	import com.tinyspeck.engine.view.util.StaticFilters;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.PixelSnapping;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	
	public class GlitchrSnapshotView extends AbstractTSView implements IFocusableComponent {
		public static const BG_ALPHA:Number = .6;
		
		private static const POLAROID_ROTATION_START:Number = -4;
		private static const POLAROID_ROTATION_END:Number = -2;
		private static const INPUT_H:uint = 64;
		private static const INPUT_PADD:uint = 20;
		private static const FILTERS_PADD_RATIO:Number = 5/6;
		private static const LOCAL_NO_PUBLISH:String = 'glitchr_no_publish';
		
		/* singleton boilerplate */
		public static const instance:GlitchrSnapshotView = new GlitchrSnapshotView();
		
		private var model:TSModelLocator;
		private var has_focus:Boolean;
		private var waiting_on_save:Boolean;
		private var spinner:MovieClip;
		private var bss:BitmapSnapshot;
		private var bss_tags:Object;
		private var bssFileName:String = "";
		private var snap_loc_tsid:String;
		private const input_submit:InputFieldSubmit = new InputFieldSubmit();
		
		private const button_holder:Sprite = new Sprite();
		private var discard_holder:Sprite;
		private var save_bt:Button;
		private var download_holder:Sprite;
		private var publish_holder:Sprite;
		private var close_bt:Sprite;
		
		private var publish_enabled:DisplayObject;
		private var publish_disabled:DisplayObject;
		
		public function GlitchrSnapshotView() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			model = TSModelLocator.instance;

			// spinner
			spinner = new AssetManager.instance.assets.spinner();
			spinner.mouseChildren = false;
			var cm:ColorMatrix = new com.quasimondo.geom.ColorMatrix();
			cm.adjustContrast(1);
			cm.adjustBrightness(100);
			cm.colorize(0xFFFFFF);
			spinner.filters = [cm.filter].concat(StaticFilters.loadingTip_DropShadowA);

			// save button
			save_bt = new Button({
				label: 'Save snap',
				name: 'save_bt',
				size: Button.SIZE_GLITCHR,
				type: Button.TYPE_GLITCHR
			});
			SpriteUtil.setRegistrationPoint(save_bt);
			save_bt.addEventListener(MouseEvent.CLICK, onSaveClick, false, 0, true);
			button_holder.addChild(save_bt);
			
			const option_padd:int = 28;
			
			// download button
			download_holder = createButtonHolder(new AssetManager.instance.assets.glitchr_download(), 'download snap');
			download_holder.addEventListener(MouseEvent.CLICK, onDownloadClick, false, 0, true);
			download_holder.x = int(save_bt.x + save_bt.width + option_padd);
			button_holder.addChild(download_holder);
			
			// discard button
			discard_holder = createButtonHolder(new AssetManager.instance.assets.glitchr_discard(), 'discard');
			discard_holder.addEventListener(MouseEvent.CLICK, onDiscardClick, false, 0, true);
			discard_holder.x = int(download_holder.x + download_holder.width + option_padd);
			discard_holder.y = 1;
			button_holder.addChild(discard_holder);
			
			// publish button
			publish_holder = createButtonHolder(null, 'publish snap');
			publish_enabled = new AssetManager.instance.assets.glitchr_publish();
			publish_disabled = new AssetManager.instance.assets.glitchr_publish_disabled();
			publish_enabled.x = int(publish_holder.width + 7);
			publish_enabled.y = int(-publish_enabled.height/2 + 1);
			publish_disabled.x = publish_enabled.x;
			publish_disabled.y = publish_enabled.y;
			publish_holder.addChild(publish_disabled);
			publish_holder.addChild(publish_enabled);
			publish_holder.addEventListener(MouseEvent.CLICK, onPublishClick, false, 0, true);
			publish_holder.x = int(save_bt.x - publish_holder.width - option_padd);
			button_holder.addChild(publish_holder);

			// top-level stuff
			GlitchroidSnapshot.instance.addEventListener(TSEvent.CHANGED, onCaptionClick, false, 0, true);
			addChild(GlitchroidSnapshot.instance);
			addChild(button_holder);
			
			// close button
			close_bt = new Sprite();
			close_bt.addChild(new AssetManager.instance.assets.glitchroid_close());
			SpriteUtil.setRegistrationPoint(close_bt.getChildAt(0));
			close_bt.buttonMode = true;
			close_bt.useHandCursor = true;
			close_bt.addEventListener(MouseEvent.CLICK, onDiscardClick, false, 0, true);
			addChild(close_bt);
			
			//input thingie
			input_submit.x = INPUT_PADD;
			input_submit.maxChars = 500;
			input_submit.height = INPUT_H;
			input_submit.addEventListener(TSEvent.CHANGED, onCaptionSubmit, false, 0, true);
			
			registerSelfAsFocusableComponent();
			visible = false;
		}
		
		public function start(bss:BitmapSnapshot, bssFileName:String, bssTags:Object):void {
			if (!TSFrontController.instance.requestFocus(this)) return;
			
			this.bss = bss;
			this.bssFileName = bssFileName;
			this.bss_tags = bssTags;
			snap_loc_tsid = model.worldModel.location.tsid;
			save_bt.disabled = true;
			save_bt.show_spinner = false;
			close_bt.visible = false;
			button_holder.visible = false;
			
			//set the publish checkbox
			const no_publish:Boolean = LocalStorage.instance.getUserData(LOCAL_NO_PUBLISH) === true;
			publish_enabled.visible = !no_publish;
			publish_disabled.visible = !publish_enabled.visible;
			
			visible = true;
			refresh();

			// twist the polaroid into place
			const polaroid:GlitchroidSnapshot = GlitchroidSnapshot.instance;
			polaroid.clearPicture();
			polaroid.rotation = POLAROID_ROTATION_START;
			TSTweener.addTween(polaroid, {rotation:POLAROID_ROTATION_END, time:(0.75 + 0.5)});
			
			// fade in the background
			alpha = 0;
			TSTweener.addTween(this, {alpha:1, time:0.75,
				onComplete:function():void {
					// render the polaroid after a short delay
					StageBeacon.setTimeout(function():void {
						// it's possible ESC was pressed during the tween
						// and the snapshot has been disposed
						if (bss && bss.bmd) {
							var polaroidBitmap:Bitmap = new Bitmap(bss.bmd, PixelSnapping.AUTO, true);
							polaroid.setPicture(polaroidBitmap);
							save_bt.disabled = false;
							close_bt.visible = true;
							button_holder.visible = true;
							
							if (model.flashVarModel.use_glitchr_filters && model.worldModel.pc.cam_filters.length) {
								polaroid.setFiltersView(new GlitchrFiltersView(polaroidBitmap, polaroid.w * FILTERS_PADD_RATIO, model.worldModel.pc.cam_filters));
							}
						}
					}, 150);
				}
			});
		}
		
		public function end():void {
			if (waiting_on_save) {
				return;
			}
			
			input_submit.hide();
			
			const self:GlitchrSnapshotView = this;
			// fade out the background
			TSTweener.addTween(this, {alpha:0, time:0.25,
				onComplete:function():void {
					visible = false;
					TSFrontController.instance.releaseFocus(self);
				}
			});
		}
		
		public function refresh():void {
			if (!visible) return;
			
			// background tint
			graphics.clear();
			graphics.beginFill(0x000000, BG_ALPHA);
			graphics.drawRect(0, 0, StageBeacon.stage.stageWidth, StageBeacon.stage.stageHeight);

			// center in the client area
			const polaroid:GlitchroidSnapshot = GlitchroidSnapshot.instance;
			polaroid.x = model.layoutModel.gutter_w + model.layoutModel.overall_w/2;
			polaroid.y = (model.layoutModel.header_h + model.layoutModel.loc_vp_h + PackDisplayManager.instance.h)/2;

			// size the polaroid
			if (bss && bss.bmd) {
				const maxPolaroidWidth:uint = model.layoutModel.overall_w;
				const maxPolaroidHeight:uint = model.layoutModel.header_h + model.layoutModel.loc_vp_h + PackDisplayManager.instance.h - button_holder.height;
				polaroid.setSize(bss.bmd.width, bss.bmd.height, maxPolaroidWidth, maxPolaroidHeight);
			}

			// close button
			var unrotatedPolaroidCorner:Point = EnginePools.PointPool.borrowObject();
			unrotatedPolaroidCorner.x = (polaroid.x + polaroid.w/2 - 2);
			unrotatedPolaroidCorner.y = (polaroid.y - polaroid.h/2 + 2);
			
			var polaroidCenter:Point = EnginePools.PointPool.borrowObject();
			polaroidCenter.x = polaroid.x;
			polaroidCenter.y = polaroid.y;
			
			// position the close button on the top right of the rotated polaroid
			// (important to not rotate the image -- it gets messed up -- so we need
			//  to do maths to get the unrotated close button into position)
			const p:Point = MathUtil.rotatePointByDegrees(unrotatedPolaroidCorner, polaroidCenter, POLAROID_ROTATION_END);
			close_bt.x = p.x;
			close_bt.y = p.y;
			
			EnginePools.PointPool.returnObject(unrotatedPolaroidCorner);
			EnginePools.PointPool.returnObject(polaroidCenter);
			
			// spinner
			spinner.x = polaroid.x - (spinner.width/2);
			spinner.y = polaroid.y - (spinner.height/2);
			
			// button holder
			button_holder.x = polaroid.x;
			button_holder.y = polaroid.y + polaroid.h/2 + 42;
			
			//input thingie
			input_submit.width = polaroid.w - INPUT_PADD*2;
			input_submit.x = int(polaroid.x - input_submit.width/2 + 10);
			input_submit.y = int(polaroid.y + polaroid.h/2 - input_submit.height - 10);
		}
		
		public function save():void {
			if (!waiting_on_save && bss && bss.bmd) {
				// disable save UI while we wait
				save_bt.disabled = true;
				save_bt.show_spinner = true;
				waiting_on_save = true;
				addChild(spinner);
				
				//if the input is still showing, take the text and set it as the caption
				if(input_submit.parent){
					GlitchroidSnapshot.instance.caption = input_submit.text;
					input_submit.hide();
				}
				
				const loc_center_x:int = model.layoutModel.loc_cur_x;
				const loc_center_y:int = model.layoutModel.loc_cur_y;
				const caption:String = GlitchroidSnapshot.instance.caption;
				
				if (model.flashVarModel.use_glitchr_filters && model.worldModel.pc.cam_filters.length) {
					var filteredOutputBMD:BitmapData = GlitchroidSnapshot.instance.getFiltererdBMD();
					bss = new BitmapSnapshot(null, bssFileName, 0, 0, filteredOutputBMD);
				}
				
				// tag it and bag it
				var filterTSID:String = "";
				if (model.flashVarModel.use_glitchr_filters && model.worldModel.pc.cam_filters.length) {
					filterTSID = GlitchroidSnapshot.instance.filtersView.getSelectedGlitchrFilter().tsid;
				}
				API.saveCameraSnap(bss, snap_loc_tsid, loc_center_x, loc_center_y, bss_tags, caption, filterTSID, stopWaitingOnSave);
			}
		}
		
		/**
		 * Returns an Object of the following template:
		 * { players: [
		 *   { 'tsid' : 'TSID',
		 *     'x'    : 123,
		 *     'y'    : -123
		 *   }, ...
		 *   ],
		 *   items: [
		 *   { 'tsid'       : 'IMF176R7BBH2A26',
		 *     'class_tsid' : 'npc_piggy',
		 *     'label'      : 'Clive The Pig',
		 *     'x'          : 312,
		 *     'y'          : -1024
		 *   }, ...
		 *   ],
		 * }
		 */
		public function getTaggingData():Object {
			const obj:Object = {
				players: [],
				items: []
			};
			
			const lm:LayoutModel = model.layoutModel;
			const renderer:LocationRenderer = TSFrontController.instance.getMainView().gameRenderer;
			const query:PhysicsQuery = model.physicsModel.lastViewportQuery;
			
			var pc:PC;
			var item:Itemstack;
			var thing:TSSprite;
			var testRect:Rectangle;
			
			var borrowedViewportRect:Rectangle = EnginePools.RectanglePool.borrowObject();

			// set up a model of the viewport to do collision tests against
			borrowedViewportRect.width  = (lm.loc_vp_w / lm.loc_vp_scale);
			borrowedViewportRect.height = (lm.loc_vp_h / lm.loc_vp_scale);
			borrowedViewportRect.x = lm.loc_cur_x - Math.round(borrowedViewportRect.width/2);
			borrowedViewportRect.y = lm.loc_cur_y - Math.round(borrowedViewportRect.height/2);
			
			// create a list of PCs and items that are close to the viewport
			const things:Vector.<TSSprite> = new Vector.<TSSprite>();
			for each (pc in query.resultPCs) {
				thing = renderer.getPcViewByTsid(pc.tsid);
				if (thing) things.push(thing);
			}
			for each (item in query.resultItemstacks) {
				thing = renderer.getItemstackViewByTsid(item.tsid);
				if (thing) things.push(thing);
			}
			// and add our PC, as it's not part of the resultPCs query
			things.push(renderer.getAvatarView());
			
			// as the viewportQuery is a bit larger than the actual viewport,
			// re-check which PCs are strictly intersecting the viewport
			for each (thing in things) {
				testRect = null;
				
				if (thing is DisplayObject) {
					testRect = SpriteUtil.getVisibleBounds(DisplayObject(thing), renderer);
				}
				
				if (!testRect) {
					// fallback... it could give us overly large dimensions for
					// items like street spirits
					if (thing.hit_target) {
						testRect = thing.hit_target.getRect(renderer);
					} else {
						testRect = thing.interactionBounds;
					}
				}
				
				if (thing is AbstractAvatarView) {
					pc = model.worldModel.getPCByTsid(thing.tsid);
					if (borrowedViewportRect.intersects(testRect)) {
						CONFIG::debugging {
							trace('Glitchr: COLLISION', pc.label, thing.tsid, testRect);
						}
						(obj.players as Array).push({
							tsid: thing.tsid,
							// adjust the coordinates relative to the viewport
							x: Math.round(testRect.x - borrowedViewportRect.x),
							y: Math.round(testRect.y - borrowedViewportRect.y),
							w: Math.round(testRect.width),
							h: Math.round(testRect.height)
						});
					}
				} else {
					item = model.worldModel.itemstacks[thing.tsid];
					if (borrowedViewportRect.intersects(testRect)) {
						CONFIG::debugging {
							trace('Glitchr: COLLISION', item.label, thing.tsid, testRect);
						}
						(obj.items as Array).push({
							tsid: thing.tsid,
							label: item.label,
							class_tsid: item.class_tsid,
							// adjust the coordinates relative to the viewport
							x: Math.round(testRect.x - borrowedViewportRect.x),
							y: Math.round(testRect.y - borrowedViewportRect.y),
							w: Math.round(testRect.width),
							h: Math.round(testRect.height)
						});
					}
				}
			}
			
			// return to pool
			EnginePools.RectanglePool.returnObject(borrowedViewportRect);
			
			return obj;
		}
		
		private function stopWaitingOnSave(ok:Boolean, rsp:Object):void {
			spinner.parent.removeChild(spinner);
			waiting_on_save = false;
			save_bt.disabled = false;
			save_bt.show_spinner = false;
			
			if (ok) {
				//publish it if we are supposed to
				if(publish_enabled.visible){
					API.postPhotoStatus(rsp.photo_id, GlitchroidSnapshot.instance.caption);
				}
				
				end();
				TSFrontController.instance.endCameraManUserMode();
				const short_url:String = 'short_url' in rsp ? rsp.short_url : '';
				GlitchrSavedDialog.instance.startWithParameters(
					rsp.photo_id, 
					rsp.filename, 
					rsp.url, 
					short_url, 
					GlitchroidSnapshot.instance.caption,
					bss
				);
			} else {
				var CDVO:ConfirmationDialogVO;
				CDVO = new ConfirmationDialogVO(null, (rsp ? "An error (" + rsp.error + ") occurred." : "An unknown error occurred.") + "\n\nSorry!", [{value: false, label: 'Ugh!'}], false);
				CDVO.title = 'Error';
				TSFrontController.instance.confirm(CDVO);
			}
		}
		
		private function createButtonHolder(icon:DisplayObject, label:String):Sprite {
			const defaultAlpha:Number = CSSManager.instance.getNumberValueFromStyle('glitchr_text_links', 'alpha', 0.8);
			
			const holder:Sprite = new Sprite();
			holder.buttonMode = true;
			holder.useHandCursor = true;
			holder.alpha = defaultAlpha;
			
			holder.addEventListener(MouseEvent.ROLL_OVER, function():void {
				holder.alpha = 1;
			});
			
			holder.addEventListener(MouseEvent.ROLL_OUT, function():void {
				holder.alpha = defaultAlpha;
			});
			
			if(icon){
				holder.addChild(icon);
				icon.y = -(icon.height/2);
			}
			
			const tf:TextField = new TextField();
			TFUtil.prepTF(tf, false);
			tf.mouseEnabled = false;
			tf.htmlText = '<span class="glitchr_text_links">' + label + '</span>';
			tf.x = icon ? icon.width + 2 : 0;
			tf.y = int(-(tf.height/2) - (label != 'discard' ? 1 : 2));
			tf.filters = StaticFilters.copyFilterArrayFromObject({blurX:2, blurY:2, alpha:.75}, StaticFilters.black2px90Degrees_DropShadowA);
			holder.addChild(tf);
			
			return holder;
		}
		
		////////////////////////////////////////////////////////////////////////////////
		//////// FOCUS /////////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		public function hasFocus():Boolean {
			return has_focus;
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			//
		}
		
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return false;
		}
		
		public function blur():void {
			has_focus = false;
			stopListeningForControlEvts();
		}
		
		public function registerSelfAsFocusableComponent():void {
			model.stateModel.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			model.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focus():void {
			has_focus = true;
			startListeningForControlEvts();
		}
		
		////////////////////////////////////////////////////////////////////////////////
		//////// Handlers //////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////
		
		private function startListeningForControlEvts():void {
			// keybindings!
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onEscapeKey);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onEnterKey);
		}
		
		private function stopListeningForControlEvts():void {
			// kill keybindings
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onEscapeKey);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onEnterKey);
		}
		
		private function onEnterKey(event:Event):void {
			if (waiting_on_save || save_bt.disabled) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
			} else {
				SoundMaster.instance.playSound('CLICK_SUCCESS');
				save();
			}
		}
		
		private function onEscapeKey(event:Event):void {
			if (waiting_on_save) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
			} else {
				SoundMaster.instance.playSound('CLICK_SUCCESS');
				end();
			}
		}
		
		private function onSaveClick(e:MouseEvent):void {
			if (waiting_on_save || save_bt.disabled) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
			} else {
				SoundMaster.instance.playSound('CLICK_SUCCESS');
				save();
			}
		}
		
		private function onDownloadClick(event:MouseEvent):void {
			if (!bss) return;
			
			if (model.flashVarModel.use_glitchr_filters && model.worldModel.pc.cam_filters.length) {
				var filteredOutputBMD:BitmapData = GlitchroidSnapshot.instance.getFiltererdBMD();
				bss = new BitmapSnapshot(null, bssFileName, 0, 0, filteredOutputBMD);
			}
			bss.saveToDesktop();
		}
		
		private function onDiscardClick(event:MouseEvent):void {
			if (waiting_on_save) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
			} else {
				SoundMaster.instance.playSound('CLICK_SUCCESS');
				end();
			}
		}
		
		private function onPublishClick(event:MouseEvent):void {
			//just toggle the publish button state
			publish_enabled.visible = !publish_enabled.visible;
			publish_disabled.visible = !publish_enabled.visible;
			
			//set this in local storeage so it remembers it
			LocalStorage.instance.setUserData(LOCAL_NO_PUBLISH, publish_disabled.visible);
		}
		
		private function onCaptionClick(event:TSEvent):void {
			//pop open the rename dialog
			const polaroid:GlitchroidSnapshot = event.data as GlitchroidSnapshot;
			
			//input submitter
			input_submit.show(polaroid.caption)
			addChild(input_submit);
			refresh();
		}
		
		private function onCaptionSubmit(event:TSEvent):void {
			//take the text and make it a bitmap
			GlitchroidSnapshot.instance.caption = event.data as String;
			input_submit.hide();
		}
		
		private function onCaptionClose():void {
			//do nothing
		}
	}
}