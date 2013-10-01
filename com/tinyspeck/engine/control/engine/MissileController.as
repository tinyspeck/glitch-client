package com.tinyspeck.engine.control.engine {
	import com.tinyspeck.core.memory.DisposableSprite;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.data.location.Location;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingHiEmoteMissileHitVO;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.view.AbstractAvatarView;
	import com.tinyspeck.engine.view.effects.Missile;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.renderer.LocationRenderer;
	
	import flash.display.DisplayObject;

	public class MissileController {
		
		private var model:TSModelLocator;
		private var gameRenderer:LocationRenderer;
		private var msl_pool:Vector.<Missile> = new Vector.<Missile>();
		
		public function MissileController(model:TSModelLocator, gameRenderer:LocationRenderer) {
			this.model = model;
			this.gameRenderer = gameRenderer;
		}
		
		public function cancelAllMissiles():void {
			for (var i:int=0;i<msl_pool.length;i++) {
				if (msl_pool[int(i)].running) {
					msl_pool[int(i)].cancel();
				}
			}
		}
		
		private function getMissile():Missile {
			for (var i:int=0;i<msl_pool.length;i++) {
				if (!msl_pool[int(i)].running) return msl_pool[int(i)];
			}
			
			var msl:Missile = new Missile();
			msl_pool.push(msl);
			return msl;
		}
		
		public function doEmoteHiMissile(accelerate:Boolean, from_tsid:String, from_view:DisplayObject, delta_y:int, variant:String, target:DisposableSprite, shard_pc_mood_granted:int):void {
			if (model.moveModel.moving) {
				return;
			}
			
			var msl:Missile = getMissile();
			var iiv:ItemIconView = new ItemIconView('hi_overlay', 0, {state:'1', config:{variant:variant}}, 'center');
			
			gameRenderer.placeOverlayInSCH(msl, 'hi emote');
			msl.launch(
				accelerate,
				from_tsid,
				shard_pc_mood_granted,
				iiv,
				from_view.x,
				from_view.y+delta_y,
				target,
				0,
				-60 // this is around the chest, where the missle should be aimed
			);
			msl.arrived_sig.addOnce(doMissilehit);
		}
		
		private function doMissilehit(msl:Missile, from_tsid:String, target:DisplayObject, shard_pc_mood_granted:int, time:int, version:int, log_data:Object):void {
			var target_pc_view:AbstractAvatarView;
			
			if (target is AbstractAvatarView) {
				target_pc_view = target as AbstractAvatarView;
				if (!target_pc_view.worth_rendering) return;
				
				if (shard_pc_mood_granted) {
					model.activityModel.announcements = Announcement.parseMultiple([{
						type: "pc_overlay",
						duration: 2000,
						pc_tsid: target_pc_view.tsid,
						delta_y: -40,
						center_text: true,
						text: ['<p align="center"><span class="nuxp_vog_smallest">+'+shard_pc_mood_granted+' mood</span></p>']
					}]);
				}
				
				if (target_pc_view.tsid == model.worldModel.pc.tsid) {
					CONFIG::debugging {
						Console.info(time);
					}
					
					if (msl.accelerate) {
						var loc:Location = model.worldModel.location;
						TSFrontController.instance.genericSend(
							new NetOutgoingHiEmoteMissileHitVO(Math.round(time/1000), from_tsid, loc.tsid, loc.instance_template_tsid, version, log_data)
						);
					}
					
					SoundMaster.instance.playSoundAllowMultiples('HI_FLOWERS_HIT');
				}
				
			}
		} 
	}
}