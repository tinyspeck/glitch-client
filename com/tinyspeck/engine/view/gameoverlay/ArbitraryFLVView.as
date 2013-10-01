package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.view.IAnnouncementArtView;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	public class ArbitraryFLVView extends TSSpriteWithModel implements IAnnouncementArtView {
		
		private var _wh:int;
		private var _flv_url:String;
		private var _registration:String;
		private var view_holder:Sprite = new Sprite();
		private var _loop_count:int;
		private var current_loop:int;
		private var _draw_box:Boolean = true;
		private var _loaded:Boolean;
		private var vid:Video;
		private var nc:NetConnection = new NetConnection();
		private var ns:NetStream;
		private var start_time:Number;
		
		public function ArbitraryFLVView(flv_url:String, wh:int=0, start_time:*=0, registration:String = 'default', loop_count:int=0) {
			super(flv_url);
			//mouseChildren = false;
			_wh = wh;
			this._flv_url = flv_url;
			this.start_time = Number(start_time) || 0;
			_registration = registration;
			_loop_count = loop_count;
			current_loop = loop_count;
			_construct();
		}
		
		override protected function _construct():void {
			super._construct();
			
			// do this so it can be meeasured with width and height!
			drawBox();
			
			addChild(view_holder);
			
			nc.addEventListener(NetStatusEvent.NET_STATUS, onNcNetStatus);
			nc.connect(null);
		}
		
		public function playFrom(secs:Number):void {
			start_time = secs;
			if (!_loaded) return;
			CONFIG::debugging {
				Console.log(883, 'seeking to: '+secs);
			}
			vid.visible = false; // NetStream.Seek.Notify will set it to visible again
			current_loop = _loop_count; //reset the loop count
			ns.seek(start_time);
		}
		
		private function onNcNetStatus(e:NetStatusEvent):void {
			CONFIG::debugging {
				Console.log(883, e);
			}
			// TODO, handle the various types of events here instead of just removing
			//nc.removeEventListener(NetStatusEvent.NET_STATUS, onNcNetStatus);
			ns = new NetStream(nc);
			ns.client = {};
			ns.addEventListener(NetStatusEvent.NET_STATUS, onNsNetStatus);
			vid = new Video;
			vid.smoothing = false;
			vid.attachNetStream(ns);
			ns.play(_flv_url);
			ns.seek(start_time);
		}
		
		/*function netStatusHandler( event:NetStatusEvent ) :void
		{
			if(event.info.code == "NetStream.Play.Stop")
				stream.seek(0);
		}*/
		
		public function get flv_url():String {
			return _flv_url;
		}
		
		public function set flv_url(url:String):void {
			if (_flv_url == url) {
				return;
			}
			
			_flv_url = url;
			_loaded = false;

			ns.play(_flv_url);
			ns.seek(start_time);
		}
		
		private function onNsNetStatus(e:NetStatusEvent):void {
			// TODO, handle the various types of events here?
			CONFIG::debugging {
				Console.priinfo(883, e);
				Console.log(883, 'level:'+e.info.level+' code:'+e.info.code);
				for (var k:String in e.info) {
					if (k!= 'level' && k != 'code' && k != 'description') Console.priwarn(883, 'UNEXPECTED PROP ON e.info: '+k+': '+e.info[k]);
				}
			}
			
			if (e.info.level == 'status') {
				if (e.info.code == 'NetStream.Buffer.Full') {
					CONFIG::debugging {
						Console.log(883, vid.videoWidth+' '+vid.videoHeight+' '+_loaded);
					}
					view_holder.addChild(vid);
					var was_loaded:Boolean = _loaded;
					_loaded = true;
					scale();
					if (!was_loaded) dispatchEvent(new TSEvent(TSEvent.COMPLETE));
				} else if (e.info.code == 'NetStream.Seek.Notify') { // a seek is complete
					vid.visible = true;
				} else if (e.info.code == 'NetStream.Play.Stop') { // at end
					if (current_loop) {
						//ns.seek(0);
						ns.play(_flv_url); //play doesn't have as long as a gap it seems
						current_loop--;
					}
				} else {
					;
					CONFIG::debugging {
						Console.priwarn(883, e.info.code);
					}
				}
			} else {
				;
				CONFIG::debugging {
					Console.priwarn(883, e.info.level+' '+e.info.code);
				}
			}
		}
		
		public function get wh():int {
			return _wh;
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
			if (!_loaded) return;
			
			vid.width = vid.videoWidth;
			vid.height = vid.videoHeight;
			
			if (_wh) {
				//Console.warn(_wh+' '+vid.videoWidth+' '+vid.videoHeight+' '+vid.scaleX+' '+vid.scaleY)
				if (vid.videoWidth > vid.videoHeight) {
					vid.height = vid.height*(_wh/vid.width);
					vid.width = _wh;
				} else {
					vid.width = vid.width*(_wh/vid.height);
					vid.height = _wh;
				}
			} else {
				_wh = (vid.videoWidth > vid.videoHeight) ? vid.videoWidth : vid.videoHeight;
			}
			
			//DisplayDebug.LogCoords(this, 10);
			
			if (_registration == 'center') {
				view_holder.x = -Math.round(_wh/2);
				view_holder.y = -Math.round(_wh/2);
			} else if (_registration == 'center_bottom') {
				view_holder.x = -Math.round(_wh/2);
				view_holder.y = -_wh;
			}
			
			if (_registration == 'center') {
				vid.y = _wh-(vid.height)-Math.round((_wh-vid.height)/2);
			} else {
				vid.y = _wh-(vid.height);
			}
			
			vid.x = _wh-(vid.width)-Math.round((_wh-vid.width)/2);
			
			drawBox();
		}
		
		public function get art_w():Number {
			return view_holder.width;
		}
		
		public function get art_h():Number {
			return view_holder.height;
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
				c = 0xffff33
				graphics.beginFill(0xCC0000, 0);
				graphics.drawRect(0, 0, _wh, _wh);
				graphics.beginFill(c);
				graphics.drawCircle(_wh/2, _wh/2, _wh/2);
				
			}
		}
		
		override public function dispose():void {
			if (ns) ns.removeEventListener(NetStatusEvent.NET_STATUS, onNsNetStatus);
			if (nc) nc.removeEventListener(NetStatusEvent.NET_STATUS, onNcNetStatus);
			if (vid) vid.attachNetStream(null);
			vid = null;
			ns = null;
			nc = null;
			super.dispose();
		}
		
	}
}