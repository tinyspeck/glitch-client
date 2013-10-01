package  {
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.model.TSEngineConstants;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.MCUtil;
	
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Scene;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	
	[SWF(width='200', height='200', backgroundColor='#e3e3e3', frameRate='30')]
	public class ItemViewer extends MovieClip {
		Security.allowDomain("*");
		
		[Embed(source="../../TSEngineAssets/src/assets/swfs/spinner.swf")] private var Spinner:Class;
		
		private var item_url:String;
		private var item_swf:MovieClip;
		private var item_swf_w:int;
		private var item_swf_h:int;
		private var holder:Sprite = new Sprite();
		private var flashvars:Object;
		private var spinner:MovieClip;
		
		public function ItemViewer() { 
			// disable yellow tabbing rectangle
			stage.stageFocusRect = false;
			stage.showDefaultContextMenu = false;
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.frameRate = TSEngineConstants.TARGET_FRAMERATE;
			init();
		}
		
		private function init():void {
			flashvars = LoaderInfo(root.loaderInfo).parameters;
			
			//set the stage on the boot status
			//BootError.stage = this.stage;
			
			CONFIG::debugging {
				Console.setOutput(Console.FIREBUG, true);
				Console.setOutput(Console.TRACE, false);
				Console.setPri(EnvironmentUtil.getUrlArgValue('pri') || '0');
			}
			
			//this.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, handleGlobalErrors);
			
			//BootUtil.setUpStage(stage);
			
			spinner = new Spinner();
			
			//API.setPcTsid('ItemViewer');
			//API.setAPIUrl(flashvars.api_url, flashvars.api_token);
			//PNGUtil.setAPIUrl(flashvars.api_url, flashvars.api_token);
			
			item_url = flashvars.item_url;
			last_anim = flashvars.anim || last_anim;
			
			holder.name = 'holder';
			holder.x = 0
			holder.y = 0;
			addChild(holder);
			
			ExternalInterface.addCallback('playAnimation', playAnimation);
			
			addChild(spinner);
			showSpinner();
			
			CONFIG::debugging {
				Console.info('GO');
			}
			
			if (flashvars.ready_callback_name) {
				ExternalInterface.call(flashvars.ready_callback_name);
			}
			
			loadSwf(item_url, function(loader:Loader):void {
				CONFIG::debugging {
					Console.info('loaded '+item_url);
				}
				
				hideSpinner();
				
				item_swf = MovieClip(loader.content);
				
				if (item_swf && item_swf.loaderInfo) {
					item_swf_w = item_swf.loaderInfo.width;
					item_swf_h = item_swf.loaderInfo.height;
					holder.addChild(item_swf);
					
					
					is_trant = (item_swf.hasOwnProperty('setState'));
					is_timeline_animated = (item_swf.hasOwnProperty('animations') && item_swf.hasOwnProperty('animatee') && item_swf.animations.length > 0);
					
					
					playAnimation(last_anim);
				}
				
				CONFIG::debugging {
					Console.warn(item_swf_w+' '+item_swf_h);
				}
			});
			
		}
		
		private var is_trant:Boolean;
		private var is_timeline_animated:Boolean;
		private var last_anim:String = 'iconic';
		
		private function playAnimation(anim:String):void {
			last_anim = anim;
			if (!item_swf) return;
			
			item_swf.stop();
			
			if (!is_trant && !is_timeline_animated) { // normal scene driven asset
				var scene:Scene = MCUtil.getSceneByName(item_swf, anim);
				if (!scene) {
					anim = '1'; // 1 is default
				}
				CONFIG::debugging {
					Console.warn('anim:'+anim);
				}
				item_swf.gotoAndStop(1, anim);
			} else if (is_trant) {
				
			} else if (is_timeline_animated) {
				
				item_swf.animatee.stop();
			}
			
			var rect:Rectangle = item_swf.getBounds(item_swf);
			
			if (rect.height > rect.width) {
				//Console.warn('1 rect.height:'+rect.height+' rect.width:'+rect.width);
				item_swf.scaleX = item_swf.scaleY = stage.stageHeight/rect.height;
			} else {
				//Console.warn('2 rect.height:'+rect.height+' rect.width:'+rect.width);
				item_swf.scaleX = item_swf.scaleY = stage.stageWidth/rect.width;
			}

			// center it
			item_swf.x = (-rect.x*item_swf.scaleX)+Math.round((stage.stageWidth-(rect.width*item_swf.scaleX))/2);
			item_swf.y = (-rect.y*item_swf.scaleX)+Math.round((stage.stageHeight-(rect.height*item_swf.scaleX))/2);
			
			CONFIG::debugging {
				Console.warn(rect.y+' '+item_swf.height);
			}
			
		}
		
		private function hideSpinner():void {
			spinner.visible = false;
			spinner.x = -100;
			spinner.y = -100;
		}
		
		private function showSpinner():void {
			spinner.visible = true;
			spinner.x = Math.round((stage.stageWidth-spinner.width)/2);
			spinner.y = Math.round((stage.stageHeight-spinner.height)/2);
		}
		
		/*private function handleGlobalErrors(e:UncaughtErrorEvent):void {
			if (e.error) {
				if (e.error.getStackTrace) {
					CONFIG::debugging {
						Console.error(e.error.getStackTrace());
					}
				} else {
					CONFIG::debugging {
						Console.error(e.error);
					}
				}
			} else {
				CONFIG::debugging {
					Console.error(e);
				}
			}
			
			try {
				BootError.handleGlobalErrors(e);
			} catch (err:Error) {
				CONFIG::debugging {
					Console.error('error calling BootError.handleGlobalErrors: '+err);
				}
			}
			
		}*/
		
		
		private function loadSwf(url:String, completeFunc:Function):void {
			var loader:Loader = new Loader();
			var loaderContext:LoaderContext = new LoaderContext(false,new ApplicationDomain(ApplicationDomain.currentDomain), null);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void{completeFunc(loader)});
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function():void{});
			loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, function():void{});
			CONFIG::debugging {
				Console.log(66, url);
			}
			loader.load(new URLRequest(url), loaderContext);
		}
		
		// functions for when done saving
		//////////////////////////////////////////////////////////////////////////////////////////////////////////
		
	}
}