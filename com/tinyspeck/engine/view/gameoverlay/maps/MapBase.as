package com.tinyspeck.engine.view.gameoverlay.maps
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.ITipProvider;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;

	public class MapBase extends Sprite implements ITipProvider
	{
		protected var you_view_holder:Sprite;
		protected var map_bg_container:Sprite = new Sprite();
		protected var map_fg_container:Sprite = new Sprite();
		
		protected var image_req:URLRequest = new URLRequest();
		protected var image_loader:Loader = new Loader();
		protected var context:LoaderContext = new LoaderContext(true);
		protected var model:TSModelLocator;
		
		protected var image_url:String;
		protected var image_fg_url:String;
		
		public function MapBase(){
			model = TSModelLocator.instance;
			cacheAsBitmap = true;
			
			construct();
		}
		
		protected function construct():void {
			//setup the image loader
			image_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageComplete, false, 0, true);
			image_loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError, false, 0, true);
			image_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onError, false, 0, true);
			
			//add the bg/fg containers
			addChild(map_bg_container);
			
			map_bg_container.mouseEnabled = false;
			map_fg_container.mouseEnabled = false;
			addChild(map_fg_container);
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if (!tip_target) return null;
			
			//default stuff here?
			return null;
		}
		
		public function getYourPt():Point {
			var pt:Point = new Point(0,0);
			if(you_view_holder && you_view_holder.parent){
				pt = you_view_holder.parent.localToGlobal(new Point(you_view_holder.x, you_view_holder.y));
				pt = globalToLocal(pt);
			}
			
			return pt;
		}
		
		protected function onImageComplete(event:Event):void {			
			var DO:DisplayObject = image_loader.contentLoaderInfo.content;
			
			if(DO){
				DO.width = HubMapDialog.MAP_W;
				DO.height = HubMapDialog.MAP_H;
				
				//add to the foreground
				if(image_loader.contentLoaderInfo.url == image_fg_url){
					map_fg_container.addChild(DO);
				}
					//otherwise add to the bg and load the fg
				else {
					image_url = image_loader.contentLoaderInfo.url;
					map_bg_container.addChild(DO);
					
					if(image_fg_url){
						image_req.url = image_fg_url;
						image_loader.load(image_req, context);
						return; //otherwise allReady is called, but it ain't all ready!
					}
				}				
			} else {
				CONFIG::debugging {
					Console.error('Something bad happened onImageComplete');
				}
			}
			allReady();
		}
		
		protected function allReady():void {
			dispatchEvent(new TSEvent(TSEvent.COMPLETE, this));
		}
		
		private function onError(event:Event):void {
			//throw errors to the console
			CONFIG::debugging {
				Console.warn('loader error: ' + event.toString());
			}
		}
	}
}