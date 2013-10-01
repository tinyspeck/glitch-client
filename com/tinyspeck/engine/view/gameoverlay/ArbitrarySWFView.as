package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.loader.SmartLoader;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.view.IAnnouncementArtView;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	
	public class ArbitrarySWFView extends TSSpriteWithModel implements IAnnouncementArtView {
		
		private var _wh:int;
		private var state:Object; // convert to some other way to specify state or run funcs on the loaded swf
		public var swf_url:String;
		private var _registration:String;
		private var view_holder:Sprite = new Sprite();
		public var mc:MovieClip;
		private var _draw_box:Boolean = true;
		private var swf_w:int;
		private var swf_h:int;
		private var _loaded:Boolean;
		public var handles_text:Boolean;
		//private var animationStartedCallback:Function;
		//private var animationStartedCallback_just_once:Boolean;
		//private var animationCompleteCallback:Function;
		//private var animationCompleteCallback_just_once:Boolean;
		//private var sequenceCompleteCallback:Function;
		//private var sequenceCompleteCallback_just_once:Boolean;
		
		private var animationStartedCallbackA:Array = [];
		private var animationStartedCallbackSinglesA:Array = [];
		
		private var animationCompleteCallbackA:Array = [];
		private var animationCompleteCallbackSinglesA:Array = [];
		
		private var sequenceCompleteCallbackA:Array = [];
		private var sequenceCompleteCallbackSinglesA:Array = [];
		
		
		/************************************************* 
		 * HEY! some static stuff for pooling swfs used by this class. If we ever want to
		 * smarten this and make it usable for other classes, should be pretty portable.
		 */
		
		private static const mc_pool:Dictionary = new Dictionary();
		private static function getAvailableMCFromPool(asv:ArbitrarySWFView):MovieClip {
			var mc:Object;
			for (mc in mc_pool) {
				if (mc_pool[mc].swf_url == asv.swf_url && mc_pool[mc].available) {
					mc_pool[mc].available = false;
					CONFIG::debugging {
						Console.priinfo(937, 'ArbitrarySWFView is reusing an mc for '+asv.swf_url+' in '+asv.name);
					}
					return mc as MovieClip;
				}
			}
			return null;
		}
		
		private static function addMCToPool(asv:ArbitrarySWFView):void {
			if (!(asv.mc in mc_pool)) {
				mc_pool[asv.mc] = {
					swf_url: asv.swf_url,
					swf_w: asv.swf_w,
					swf_h: asv.swf_h
				}
			}
			
			// make sure we reset some shit!
			asv.mc.filters = null;
			asv.mc.x = asv.mc.y = 0;
			asv.mc.scaleX = asv.mc.scaleY = 1;
			
			mc_pool[asv.mc].available = true;
			CONFIG::debugging {
				Console.priinfo(937, 'ArbitrarySWFView has another mc in it\'s pool for '+asv.swf_url+' from '+asv.name);
			}
		}
		
		/************************************************* 
		 * End of the pooling stuff
		 */
		
		
		public function ArbitrarySWFView(swf_url:String, wh:int=0, state:Object='', registration:String='default', draw_box:Boolean=true, name:String=null) {
			super(name || swf_url);
			//mouseChildren = false;
			_wh = wh;
			this.swf_url = swf_url;
			this.state = state;
			_registration = registration;
			_draw_box = draw_box;
			_construct();
		}
		
		override protected function _construct():void {
			super._construct();
			
			view_holder.name = 'view_holder';
			
			// do this so it can be meeasured with width and height!
			drawBox();
			
			addChild(view_holder);
			
			mc = ArbitrarySWFView.getAvailableMCFromPool(this);
			
			if (mc) {
				//Console.info('REUSING '+swf_url);
				swf_w = mc_pool[mc].swf_w;
				swf_h = mc_pool[mc].swf_h;
				
				// we must do this to make it work asynchly, otherwise the COMPELTE event fires synchly and fucks things up
				StageBeacon.waitForNextFrame(proceedWithMC);
			} else {
				var sl:SmartLoader = new SmartLoader(swf_url);
				sl.complete_sig.add(onLoad);
				sl.error_sig.add(onLoadFail);
				sl.load(new URLRequest(swf_url));
			}
		}
		
		public function get wh():int {
			return _wh;
		}
		
		public function animate(state:Object):void {
			if (!mc) {
				this.state = state;
				return;
			}
			
			if (mc.playAnimation) {
				if (state && typeof state == 'object') {
					if (state is Array) {
						mc.playAnimationSeq(state);
					} else if (state.seq) {
						mc.playAnimationSeq(state.seq, state.loop);
					}
				} else {
					mc.playAnimation(state);
				}
			} else if (mc.start) {// for overlays
				mc.start(state);
			} else if (state != null) {
				; // satisfy compiler
				CONFIG::debugging {
					if (typeof(state) == 'object') {
						Console.warn(swf_url+' disposed:'+disposed+' dont know what to do with this state object:');
						Console.dir(state);
					} else {
						Console.warn(swf_url+' disposed:'+disposed+' dont know what to do with this state: '+state);
					}
				}
			}
		}
		
		private function callAndClean(A:Array, singlesA:Array):void {
			if (!A.length) return;
			var len:uint = A.length;
			var i:uint;
			var singles_index:int;
			var callA:Array = [];
			for (i;i<len;i++) {
				callA.push(A[int(i)]);
				singles_index = singlesA.indexOf(A[int(i)]);
				if (singles_index > -1) {
					singlesA.splice(singles_index, 1);
					A.splice(i, 1);
					// now, to compensate for having removed it:
					i--;
					len--;
				}
			}
			
			for (i=0;i<callA.length;i++) {
				callA[int(i)](this);
			}
			
			//Console.warn('after call', A.length, singlesA.length);
		}
		
		public function removeSequenceCompleteCallback(f:Function):void {
			if (sequenceCompleteCallbackA.indexOf(f) > -1) sequenceCompleteCallbackA.splice(sequenceCompleteCallbackA.indexOf(f), 1);
			if (sequenceCompleteCallbackSinglesA.indexOf(f) > -1) sequenceCompleteCallbackSinglesA.splice(sequenceCompleteCallbackSinglesA.indexOf(f), 1);
			//Console.warn('after remove', sequenceCompleteCallbackA.length, sequenceCompleteCallbackSinglesA.length);
		}
		
		public function addSequenceCompleteCallback(f:Function, just_once:Boolean):void {
			if (f == null) return;
			if (sequenceCompleteCallbackA.indexOf(f) > -1) return;
			sequenceCompleteCallbackA.push(f);
			if (just_once) sequenceCompleteCallbackSinglesA.push(f);
			if (mc) mc.addEventListener('SEQUENCE_COMPLETE', onSequenceComplete); // make sure its is listening
			//Console.warn('after add', sequenceCompleteCallbackA.length, sequenceCompleteCallbackSinglesA.length);
		}
		
		private function onSequenceComplete(e:Event):void {
			callAndClean(sequenceCompleteCallbackA, sequenceCompleteCallbackSinglesA);
		}
		
		public function removeAnimationCompleteCallback(f:Function):void {
			if (animationCompleteCallbackA.indexOf(f) > -1) animationCompleteCallbackA.splice(animationCompleteCallbackA.indexOf(f), 1);
			if (animationCompleteCallbackSinglesA.indexOf(f) > -1) animationCompleteCallbackSinglesA.splice(animationCompleteCallbackSinglesA.indexOf(f), 1);
		}
		
		public function addAnimationCompleteCallback(f:Function, just_once:Boolean):void {
			if (f == null) return;
			if (animationCompleteCallbackA.indexOf(f) > -1) return;
			animationCompleteCallbackA.push(f);
			if (just_once) animationCompleteCallbackSinglesA.push(f);
			if (mc) mc.addEventListener('ANIMATION_COMPLETE', onAnimationComplete); // make sure its is listening
		}
		
		private function onAnimationComplete(e:Event):void {
			callAndClean(animationCompleteCallbackA, animationCompleteCallbackSinglesA);
		}
		
		public function removeAnimationStartedCallback(f:Function):void {
			if (animationStartedCallbackA.indexOf(f) > -1) animationStartedCallbackA.splice(animationStartedCallbackA.indexOf(f), 1);
			if (animationStartedCallbackSinglesA.indexOf(f) > -1) animationStartedCallbackSinglesA.splice(animationStartedCallbackSinglesA.indexOf(f), 1);
		}
		
		public function addAnimationStartedCallback(f:Function, just_once:Boolean):void {
			if (f == null) return;
			if (animationStartedCallbackA.indexOf(f) > -1) return;
			animationStartedCallbackA.push(f);
			if (just_once) animationStartedCallbackSinglesA.push(f);
			if (mc) mc.addEventListener('ANIMATION_STARTING', onAnimationStarted); // make sure its is listening
		}
		
		private function onAnimationStarted(e:Event):void {
			callAndClean(animationStartedCallbackA, animationStartedCallbackSinglesA);
		}
		
		private function onLoadFail(sl:SmartLoader):void {
			// whoever is listening for COMPLETE events needs to check for .mc to make load succeeded (see InWindowAnnouncementOverlay)
			dispatchEvent(new TSEvent(TSEvent.COMPLETE));
		}
		
		private function onLoad(sl:SmartLoader):void {
			mc = sl.content as MovieClip;
			CONFIG::debugging {
				if (Console.priOK('112') || Console.priOK('153')) if (mc.setConsole) mc.setConsole(Console);
			}
			if (mc.itemRun) mc.itemRun();
			swf_w = sl.contentLoaderInfo.width;
			swf_h = sl.contentLoaderInfo.height;
			proceedWithMC();
		}
		
		private function proceedWithMC():void {
			view_holder.addChild(mc);
			if (animationStartedCallbackA.length) mc.addEventListener('ANIMATION_STARTING', onAnimationStarted);
			if (animationCompleteCallbackA.length) mc.addEventListener('ANIMATION_COMPLETE', onAnimationComplete);
			if (sequenceCompleteCallbackA.length) mc.addEventListener('SEQUENCE_COMPLETE', onSequenceComplete);
			
			animate(state);
			
			// give it the styles to use
			if (false && mc.tf && mc.showText && mc.registerFontsFromAssets) {
				//Console.info('AssetManager.instance.assets '+AssetManager.instance.assets);
				/*var assets:* = AssetManager.instance.assets;
				if(assets && assets.fontsA){
					for (var i:int=0;i<assets.fontsA.length;i++) {
						Console.info(assets.fontsA[int(i)]+' '+assets[assets.fontsA[int(i)]])
						//if (assets.fontsA[int(i)]) Font.registerFont(assets[assets.fontsA[int(i)]]);
					}
				}*/
				mc.registerFontsFromAssets(AssetManager.instance.assets);
				TextField(mc.tf).styleSheet = CSSManager.instance.styleSheet;
				handles_text = true;
			} 
			
			scale();
			_loaded = true;

			dispatchEvent(new TSEvent(TSEvent.COMPLETE));
		}
		
		public function showText(text:String):void {
			if (mc.showText) {
				mc.showText(text);
			} 
		}
		
		public function get loaded():Boolean {
			return _loaded;
		}
		
		public function set wh(wh:int):void {
			_wh = wh;
			scale();
		}
		
		private function drawBox():void {
			if (_draw_box) {
				graphics.clear();
				graphics.beginFill(0x00cc00, 0);
				graphics.drawRect(view_holder.x, view_holder.y, _wh, _wh);
			}
		}
		
		private function scale():void {
			drawBox();
			if (!mc) return;
			if (_wh) {
				if (swf_w > swf_h) {
					mc.scaleX = mc.scaleY = _wh/swf_w;
				} else {
					mc.scaleX = mc.scaleY = _wh/swf_h;
				}
			} else {
				_wh = (swf_w > swf_h) ? swf_w : swf_h;
			}
			
			if (_registration == 'center') {
				view_holder.x = -Math.round(_wh/2);
				view_holder.y = -Math.round(_wh/2);
			} else if (_registration == 'center_bottom') {
				view_holder.x = -Math.round(_wh/2);
				view_holder.y = -_wh;
			}
			
			// not sure why this was not here! let's make sure nothing is fucked because of it			
			mc.x = Math.round((_wh/2)-((swf_w/2)*mc.scaleX));

			if (_registration == 'center') {
				mc.y = _wh-(swf_h*mc.scaleX)-Math.round((_wh-(swf_h*mc.scaleX))/2);
			} else {
				mc.y = _wh-(swf_h*mc.scaleX);
			}

			drawBox();
		}
		
		// BIG CHANGE MADE THIS DAY 01/04/12... using swf stage dims for art_w/art_h instead of the measured width
		// if this causes problems with currently used ArbSwfViews, we will probably need to revert and add new getters for getting
		// swf_w*mc.scaleX for use in InWindowAnncOverlay when placing by annc.corner
		// used to be:
		/*
		public function get art_w():Number {
			return view_holder.width;
		}
		
		public function get art_h():Number {
			return view_holder.height;
		}
		*/
		
		public function get art_w():Number {
			if (!mc) return view_holder.width;
			return swf_w*mc.scaleY;
		}
		
		public function get art_h():Number {
			if (!mc) return view_holder.height;
			return swf_h*mc.scaleX;
		}
		
		override protected function _addedToStageHandler(e:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, _addedToStageHandler);
		}
		
		override protected function _draw():void {
			var h:int;
			var w:int;
			var c:Number = 0xffffff;
			
			if (_registration == 'center') {
				h = w = 50;
				graphics.beginFill(c, 1);
				graphics.drawRect(-Math.round(w/2), -Math.round(h/2), w, h);
				
			} else if (_registration == 'center_bottom') {
				h = w = 50;
				graphics.beginFill(c, 1);
				graphics.drawRect(-Math.round(w/2), -h, w, h);
				
			} else if (_wh) {
				c = 0xffff33;
				graphics.beginFill(0xCC0000, 0);
				graphics.drawRect(0, 0, _wh, _wh);
				graphics.beginFill(c);
				graphics.drawCircle(_wh/2, _wh/2, _wh/2);
				
			}
		}
		
		override public function dispose():void {
			if (mc) {
				mc.removeEventListener('ANIMATION_STARTING', onAnimationStarted);
				mc.removeEventListener('ANIMATION_COMPLETE', onAnimationComplete);
				mc.removeEventListener('SEQUENCE_COMPLETE', onSequenceComplete);
				mc.removeEventListener('SEQUENCE_COMPLETE', onSequenceComplete);
				
				// add the loaded swf mc to the pool so it can be reused
				ArbitrarySWFView.addMCToPool(this);

				// we must remove it from the display list else super.dispose() fucks it up, and we want to reuse it
				if (mc.parent) mc.parent.removeChild(mc);
			}
			super.dispose();
		}
		
	}
}