package com.tinyspeck.engine.port
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.spritesheet.AnimationSequenceCommand;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.geom.GeomUtil;
	import com.tinyspeck.engine.view.gameoverlay.ArbitrarySWFView;
	
	import flash.display.*;
	import flash.filters.DropShadowFilter;
	import flash.geom.*;
	
	public class RookAttackView extends TSSpriteWithModel {
		
		public static const SCRATCHING:String = 'SCRATCHING';
		public static const SCATTERED:String = 'SCATTERED';
		public static const MOVING_OFFSCREEN:String = 'MOVING_OFFSCREEN';
		public static const MOVING_ONSCREEN:String = 'MOVING_ONSCREEN';
		public static const AT_ATTACK_PNT:String = 'AT_ATTACK_PNT';
		
		private var asv:ArbitrarySWFView;
		public var wh:int;
		private var callBack:Function = null;
		public var attack_state:String = null;
		public var hit_box:Sprite = new Sprite;
		
		public function RookAttackView(wh:int):void {
			super();
			this.wh = wh;
			_construct();
			mouseEnabled = mouseChildren = false;
		}
		
		override protected function _construct():void {
			
			if (!model.stateModel.overlay_urls['rook_attack_test']) {
				CONFIG::debugging {
					Console.error("model.stateModel.overlay_urls['rook_attack_test'] not exists");
				}
				return;
			}
			
			asv = new ArbitrarySWFView(
				model.stateModel.overlay_urls['rook_attack_test'],
				wh,
				'standStill',
				'center',
				false
			);
			
			asv.addEventListener(TSEvent.COMPLETE, onASVload);
			
			addChild(asv);
			addChild(hit_box);
			hit_box.visible = false;
		}
		
		private function onASVload(e:TSEvent):void {
			dispatchEvent(new TSEvent(TSEvent.COMPLETE));
			asv.removeEventListener(TSEvent.COMPLETE, onASVload);
			//asv.mc.visible = false;
			//DisplayDebug.LogCoords(asv.mc, 5);
			
			//if (mc.setConsole) mc.setConsole(null);
			
			var filt:DropShadowFilter = new DropShadowFilter();
			var ccsm:CSSManager = CSSManager.instance;
			
			filt.distance = ccsm.getNumberValueFromStyle('rav_shadow', 'distance', 2);
			filt.angle = ccsm.getNumberValueFromStyle('rav_shadow', 'angle', 45);
			filt.alpha = ccsm.getNumberValueFromStyle('rav_shadow', 'alpha', 1);
			filt.blurX = ccsm.getNumberValueFromStyle('rav_shadow', 'blurX', 4);
			filt.blurY = ccsm.getNumberValueFromStyle('rav_shadow', 'blurY', 4);
			
			mc.body.filters = [filt];
			
			addChild(hit_box);
			var w:int = 200;
			var h:int = 100;
			var g:Graphics = hit_box.graphics;
			g.beginFill(0xffffff, 1);
			g.drawEllipse(-(w/2), -(h/2), w, h);
			g.endFill();
			
			//this.cacheAsBitmap = EnvironmentUtil.getUrlArgValue('SWF_no_rook_cab') != '1';
			mc.animatee.cacheAsBitmap = EnvironmentUtil.getUrlArgValue('SWF_no_rook_cab') != '1';
		}
		
		override public function get hit_target():DisplayObject {
			return DisplayObject(hit_box);
		}
		
		/*
		animations = ['scratchAttack', 'walk', 'hop', 'creepy1', 'creepy2', 'standStill', 'idle', 'peck1', 'peck2', 'peck3', 'peck4', 'peck5', 'peck6'];
		*/
		
		public function animateTo(ptB:Point, pps:int, asc:AnimationSequenceCommand, done_asc:AnimationSequenceCommand = null, callBack:Function = null):void {
			//this.callBack = (callBack == null) ? null : callBack;

			var self:RookAttackView = this;
			var ptA:Point = new Point(self.x, self.y);
			
			var diff_x:int = ptB.x - self.x;
			var diff_y:int = ptB.y - self.y;
			
			var last_x:Number = self.x;
			var last_y:Number = self.y;
			
			var dist:Number = Point.distance(ptA, ptB);
			var time:Number = dist/pps
			//Console.warn('dist:'+dist+' time:'+time);
			
			var tween_ob:Object = {
				x:ptB.x,
				y:ptB.y,
				time: time,
				transition:"linear",
				onUpdate: function():void {
					// keep it facing the correct direction
					self.r = Math.atan2(self.y-last_y, self.x-last_x)*180/Math.PI;
					last_x = self.x;
					last_y = self.y;
				},
				onComplete: function():void {
					TSTweener.removeTweens(self);
					if (done_asc) {
						//Console.warn('complete 1');
						// put it in the state specified by the done_asc arg and wait for it to complete before calling back
						self.animate(done_asc, callBack);
					} else {
						//Console.warn('complete 2');
						// call back immediately
						if (callBack != null) callBack(self);
					}
				}
			};
			
			// add curve control pts
			var rat:Number = 1/3; // 1/3 means we want the ctrlPts at 1/3 and 2/3 of the line from ptA to ptB (roughly; it really depeneds on angle also)
			var angle:Number = 15*(dist/1000);
			if (MathUtil.chance(50)) angle*= -1; // to make the curves run alternately either way
			var ctrlPt1:Point = GeomUtil.getTrianglePtCFromPtsABAndDistAtoCAndAngleAtoC(ptA, ptB, dist*rat, angle);
			var ctrlPt2:Point = GeomUtil.getTrianglePtCFromPtsABAndDistAtoCAndAngleAtoC(ptB, ptA, dist*rat, angle);
			tween_ob._bezier = [{x:ctrlPt1.x, y:ctrlPt1.y}, {x:ctrlPt2.x, y:ctrlPt2.y} ];
			
			//Console.dir(tween_ob)
			TSTweener.removeTweens(self);
			TSTweener.addTween(self, tween_ob);
		
			animate(asc, null);
		}
		
		public function halt():void {
			TSTweener.removeTweens(this);
			asv.mc.stopAll();
		}
		
		public function animate(asc:AnimationSequenceCommand, callBack:Function):void {
			if (this.callBack != null) asv.removeSequenceCompleteCallback(this.callBack);
			
			this.callBack = callBack;
			if (this.callBack != null) asv.addSequenceCompleteCallback(onSequenceComplete, true);
			
			asv.animate({seq:asc.A, loop:asc.loop});
		}
		
		public function onSequenceComplete(asv:ArbitrarySWFView):void {
			//Console.warn('onSequenceComplete');
			if (this.callBack != null) this.callBack(this);
		}
		
		public function get mc():MovieClip {
			return asv.mc;
		}
		
		public function get loaded():Boolean {
			return asv.loaded;
		}
		
		override public function get r():Number {
			return asv.rotation;
		}
		
		public function set r(value:Number):void{
			asv.rotation = value;
			hit_box.rotation = value;
		}
		
		public function addSequenceCompleteCallback(f:Function, just_once:Boolean):void {
			asv.addSequenceCompleteCallback(f, just_once);
		}
		
		public function addAnimationCompleteCallback(f:Function, just_once:Boolean):void {
			asv.addAnimationCompleteCallback(f, just_once);
		}
		
		public function addAnimationStartedCallback(f:Function, just_once:Boolean):void {
			asv.addAnimationStartedCallback(f, just_once);
		}
		
	}
}