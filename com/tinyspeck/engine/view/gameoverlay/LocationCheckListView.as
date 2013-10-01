package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.control.engine.AnnouncementController;
	import com.tinyspeck.engine.data.location.Deco;
	import com.tinyspeck.engine.data.location.Layer;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.AbstractTSView;
	import com.tinyspeck.engine.view.CheckListItemView;
	import com.tinyspeck.engine.view.CheckListView;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	final public class LocationCheckListView extends AbstractTSView implements IRefreshListener {
		/* singleton boilerplate */
		public static const instance:LocationCheckListView = new LocationCheckListView();

		private var _w:int = 200;
		private var padd:int = 10;
		private var model:TSModelLocator;
		private var holder:Sprite = new Sprite();
		private var clv:CheckListView = new CheckListView(_w-(padd*2));
		private var reusable_pt:Point = new Point();
		
		public function LocationCheckListView():void {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			model = TSModelLocator.instance;
			holder.addChild(clv);
			addChild(holder);
			holder.x = padd;
			holder.y = padd;
			
			//set the position
			x = 10;
			y = 30;
			
			TSFrontController.instance.registerRefreshListener(this);
		}
		
		public function addListItemFromAnnc(txt:String, from_annc_uid:String):void {
			var annc:AbstractAnnouncementOverlay = AnnouncementController.instance.getActiveOverlayByUid(from_annc_uid) as AbstractAnnouncementOverlay;
			if (annc && annc.parent) {
				var first_parent:DisplayObjectContainer = TSFrontController.instance.getMainView().gameRenderer.scrolling_overlay_holder;
				
				var rect:Rectangle = annc.getBounds(first_parent);
				// center it
				reusable_pt.x = rect.x+(rect.width/2);
				reusable_pt.y = rect.y+(rect.height/2);
				
				addListItem(txt, reusable_pt, first_parent);
			} else {
				// bad annc, just do it from center of vp
				addListItemFromVPCenter(txt);
			}
		}
		
		public function addListItemFromDeco(txt:String, deco_name:String):void {
			var ob:Object = model.worldModel.location.getDecoAndLayerByDecoName(deco_name);
			if (ob) {
				var deco:Deco = ob.deco;
				var layer:Layer = ob.layer;
			}
			
			if (deco && layer) {
				var first_parent:DisplayObjectContainer;

				// we're going to stick it in the MG
				first_parent = TSFrontController.instance.getMainView().gameRenderer.getLayerRendererByTSID(model.worldModel.location.mg.tsid);
				reusable_pt = TSFrontController.instance.getMainView().gameRenderer.translateLayerLocalToGlobal(
					layer, 
					deco.x,
					deco.y
				);
				reusable_pt = TSFrontController.instance.getMainView().gameRenderer.translateLayerGlobalToLocal(
					model.worldModel.location.mg, 
					reusable_pt.x,
					reusable_pt.y
				);
				
				// center it
				reusable_pt.y = reusable_pt.y-(deco.h/2);
				
				addListItem(txt, reusable_pt, first_parent);
			} else {
				// bad annc, just do it from center of vp
				addListItemFromVPCenter(txt);
			}
		}

		public function addListItemFromVPCenter(txt:String):void {
			reusable_pt.x = model.layoutModel.gutter_w+Math.round(model.layoutModel.loc_vp_w/2);
			reusable_pt.y = model.layoutModel.header_h+Math.round(model.layoutModel.loc_vp_h/2);
			
			addListItem(txt, reusable_pt, StageBeacon.stage);
		}
		
		private function addListItem(txt:String, from_pt:Point, first_parent:DisplayObjectContainer):void {
			var cliv:CheckListItemView = clv.addListItem(txt);
			
			if (from_pt) {
				cliv.alpha = 0;
				var checkmark_holder:Sprite = new Sprite();
				var checkmarkDO:DisplayObject = cliv.checkmarkDO;
				var eventual_parent:DisplayObjectContainer = StageBeacon.stage;
				var cliv_rect:Rectangle = cliv.getBounds(eventual_parent);
				
				// place the holder where it goes!
				checkmark_holder.x = Math.round(from_pt.x);
				checkmark_holder.y = Math.round(from_pt.y);
				
				// place the checkmark so we can scale the holder and the checkmark center stays in the same place
				checkmarkDO.x = -Math.round(checkmarkDO.width/2);
				checkmarkDO.y = -Math.round(checkmarkDO.height/2);
				
				checkmark_holder.addChild(checkmarkDO);
				first_parent.addChild(checkmark_holder);
				
				var afterBounceIn:Function = function():void {
					// move it to the list
					
					TSTweener.addTween(checkmark_holder, {
						// these coords take into account that we offset the checkmarkDO
						x:cliv_rect.x-checkmarkDO.x,
						y:cliv_rect.y-checkmarkDO.y,
						scaleX:1,
						scaleY:1,
						time:.5,
						delay:2,
						onComplete:afterMove
					});
					
					// this is where we need
					SpriteUtil.reParentAtSameStagePosition(checkmark_holder, eventual_parent)
				}
				
				var afterMove:Function = function():void {
					// fade in the list item
					TSTweener.addTween(cliv, {
						alpha:1,
						time:.5,
						onComplete:afterFade
					});
				}
				
				var afterFade:Function = function():void {
					// place the check back in the list item
					checkmarkDO.x = 0;
					checkmarkDO.y = 0;
					cliv.addChild(checkmarkDO);
				}
				
				TSTweener.addTween(checkmark_holder, {
					scaleX:3,
					scaleY:3,
					time:1.2,
					delay:0,
					transition:'easeOutBounce',
					onComplete:afterBounceIn
				});
			}
			
			draw();
		}
		
		public function clearListItems():void {
			clv.clearListItems();
			draw();
		}
		
		private function draw():void {
			var g:Graphics = graphics;
			g.clear();
			
			if (!height) return;
			
			g.lineStyle(0, 0, 0, true);
			g.beginFill(0x000000, .1);
			g.beginFill(0x000000, .7);
			g.drawRoundRect(0, 0, _w, height+(holder.y*2), 15);
			g.endFill();
		}
		
		public function refresh():void {
			
		}
		
	}
}
