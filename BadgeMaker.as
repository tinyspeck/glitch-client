package  {
	
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.data.FlashVarData;
	import com.tinyspeck.debug.API;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.PNGUtil;
	
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	
	[SWF(width='900', height='900', backgroundColor='#c3c3c3', frameRate='120')]
	public class BadgeMaker extends MovieClip {
		Security.allowDomain("*");
		
		[Embed(source="../../TSEngineAssets/src/assets/swfs/spinner.swf")]
		private var Spinner:Class;
		
		private var holder:Sprite = new Sprite();
		private var flashvars:Object;
		private var spinner:MovieClip;
		
		public function BadgeMaker() { 
			// disable yellow tabbing rectangle
			stage.stageFocusRect = false;
			stage.showDefaultContextMenu = false;
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			init();
		}

		private function init():void {
			flashvars = LoaderInfo(root.loaderInfo).parameters;
			
			const fvm:FlashVarModel = new FlashVarModel(FlashVarData.createFlashVarData(this));
			StageBeacon.init(stage, fvm);
			
			CONFIG::debugging {
				Console.setOutput(Console.FIREBUG, true);
				Console.setOutput(Console.TRACE, false);
				Console.setPri(EnvironmentUtil.getUrlArgValue('pri') || '0');
			}

			this.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, handleGlobalErrors);
			
			spinner = new Spinner();
			
			API.setPcTsid('BadgeMaker');
			API.setAPIUrl(flashvars.api_url, flashvars.api_token);
			PNGUtil.setAPIUrl(flashvars.api_url, flashvars.api_token);
			
			
			holder.name = 'holder';
			holder.x = 0
			holder.y = 0;
			addChild(holder);
			
			ExternalInterface.addCallback('makeBadge', makeBadge);
			
			addChild(spinner);
			
			CONFIG::debugging {
				Console.info('GO');
			}
			
			if (flashvars.ready_callback_name) {
				ExternalInterface.call(flashvars.ready_callback_name);
			}
		}
		
		private function makeBadge(swf_url:String, class_tsid:String, callback_name:String):void {
			while (holder.numChildren) holder.removeChildAt(0);
			showSpinner();
			
			CONFIG::debugging {
				Console.info('makeBadge');
			}
			var swf:MovieClip;
			loadSwf(swf_url, function(loader:Loader):void {
				CONFIG::debugging {
					Console.info('loaded '+swf_url);
				}
				
				swf = MovieClip(loader.content);
				
				var next_x:int = 0;
				
				var A:Array = PNGUtil.saveBadgePngsFromMc(swf, class_tsid, function(ok:Boolean, txt:String):void {
					if (callback_name) {
						ExternalInterface.call(callback_name, ok, txt);
					}
				});
				
				hideSpinner();
				var bm:Bitmap;
				for (var i:int=0;i<A.length;i++) {
					bm = A[int(i)];
					bm.x = next_x;
					next_x = bm.width;
					holder.addChild(bm);
				}
			});
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
		
		private function handleGlobalErrors(e:UncaughtErrorEvent):void {
			CONFIG::debugging {
				if (e.error) {
					if (e.error.getStackTrace) {
						Console.error(e.error.getStackTrace());
					} else {
						Console.error(e.error);
					}
				} else {
					Console.error(e);
				}
			}
			
			try {
				BootError.handleGlobalErrors(e);
			} catch (err:Error) {
				; // satisfy compiler
				CONFIG::debugging {
					Console.error('error calling BootError.handleGlobalErrors: '+err);
				}
			}
		}
		
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