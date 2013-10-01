package  {
	import com.adobe.serialization.json.JSON;
	import com.quietless.bitmap.BitmapSnapshot;
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.data.FlashVarData;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.control.engine.DataLoaderController;
	import com.tinyspeck.engine.control.mapping.ControllerMap;
	import com.tinyspeck.engine.data.pc.ImaginationCard;
	import com.tinyspeck.engine.memory.ClientOnlyPools;
	import com.tinyspeck.engine.memory.EnginePools;
	import com.tinyspeck.engine.model.TSEngineConstants;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.physics.util.LocationPhysicsHealer;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.ui.imagination.ImgCardUI;
	
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.UncaughtErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Security;
	import flash.text.Font;
	
	[SWF(width='200', height='200', backgroundColor='#000000', frameRate='30')]
	public class UpgradeCardViewer extends MovieClip {
		Security.allowDomain("*");
		
		[Embed(source="../../TSEngineAssets/src/assets/swfs/spinner.swf")] private var Spinner:Class;
		[Embed(source="../../TSEngineAssets/src/assets/swfs/imagination_cards.swf")] private var Cards:Class;
		[Embed(source="../../TSEngineAssets/src/assets/fonts/VAGRoundedBold.ttf", fontName="VAGRoundedBoldEmbed")] public var VAGRoundedBold:Class;
		
		private var holder:Sprite = new Sprite();
		private var large_holder:Sprite = new Sprite();
		private var small_holder:Sprite = new Sprite();
		private var flashvars:Object;
		private var spinner:MovieClip;
		private var cards_mc:MovieClip;
		private var model:TSModelLocator;
		private var card:ImaginationCard;
		private var img_large:BitmapSnapshot;
		private var img_small:BitmapSnapshot;
		private var large_card_ui:ImgCardUI;
		private var small_card_ui:ImgCardUI;
		
		public function UpgradeCardViewer() { 
			// disable yellow tabbing rectangle
			stage.stageFocusRect = false;
			stage.showDefaultContextMenu = false;
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.frameRate = TSEngineConstants.TARGET_FRAMERATE;
			Font.registerFont(VAGRoundedBold)
			init();
		}
		
		private function handleGlobalErrors(e:UncaughtErrorEvent):void {
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
		}
		
		private function init():void {			
			CONFIG::debugging {
				Console.setOutput(Console.FIREBUG, true);
				Console.setOutput(Console.TRACE, false);
				Console.setPri(EnvironmentUtil.getUrlArgValue('pri') || '0');
			}
			
			this.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, handleGlobalErrors);
			
			flashvars = LoaderInfo(root.loaderInfo).parameters;
			
			spinner = new Spinner();
			holder.name = 'holder';
			holder.x = 10
			holder.y = 10;
			addChild(holder);
			holder.addChild(large_holder);
			holder.addChild(small_holder);
			addChild(spinner);
			showSpinner();
			
			Console.info(flashvars.card_str);
			var card_ob:Object;
			if (flashvars.card_str) {
				card_ob = JSON.decode(flashvars.card_str);
				CONFIG::debugging {
					Console.info('card_ob: '+typeof card_ob);
					Console.dir(card_ob);
				}
			}
			
			if (!card_ob) {
				CONFIG::debugging {
					Console.error('no card_ob!')
				}
				return;
			}
			
			card = ImaginationCard.fromAnonymous(card_ob, card_ob.id);
			
			CONFIG::debugging {
				Console.info('GO '+card);
			}
			
			model = TSModelLocator.instance;
			model.flashVarModel = new FlashVarModel(FlashVarData.createFlashVarData(this));
			StageBeacon.init(stage, model.flashVarModel);
			EnginePools.init();
			ClientOnlyPools.init();
			var controllerMap:ControllerMap = new ControllerMap();
			controllerMap.dataLoaderController = new DataLoaderController();
			TSFrontController.instance.setControllerMap(controllerMap);
			KeyBeacon.instance.setStage(stage);
			LocationPhysicsHealer.init();
			
			const cards_loader:MovieClip = new Cards();
			cards_loader.addEventListener(Event.COMPLETE, onAssetLoaded, false, 0, true);
		}
		
		private function onAssetLoaded(event:Event):void {
			//set our cards mc
			const cards_loader:Loader = MovieClip(event.currentTarget).getChildAt(0) as Loader;
			cards_mc = cards_loader.content as MovieClip;
			
			var cssLoader:URLLoader = new URLLoader();
			cssLoader.addEventListener(Event.COMPLETE, onCSSLoadComplete);
			cssLoader.load(new URLRequest(flashvars.css_url));
		}
		
		private function onCSSLoadComplete(event:Event):void {
			Console.info(event);
			CSSManager.instance.init(event.target.data);
			showCards();
			
			
			ExternalInterface.addCallback("doChangeCard", onChangeCard);
			ExternalInterface.addCallback("save", save);
			
			ExternalInterface.call(flashvars.load_callback_name);
			hideSpinner();
		}
		
		private function onChangeCard(card_ob:Object):void {
			Console.dir(card_ob);
			if (!card_ob) {
				return;
			}
			card = ImaginationCard.fromAnonymous(card_ob, card_ob.id);
			showCards();
		}
		
		private function showCards():void {
			
			SpriteUtil.clean(large_holder);
			SpriteUtil.clean(small_holder);
			
			var offset_large:int = 6;
			var scale_large:Number = .9;
			var large_w:int = 198;
			var large_h:int = 270;
			if (large_card_ui) {
				large_card_ui.reset(false);
			} else {
				large_card_ui = new ImgCardUI(cards_mc, scale_large, 1.05, false, false, false);
			}
			large_card_ui.show(card);
			large_card_ui.alpha = 1;
			large_card_ui.x = (large_card_ui.width/2)-offset_large;
			large_card_ui.y = (large_card_ui.height/2)-offset_large;
			large_holder.addChild(large_card_ui);
			
			var offset_small:int = int(EnvironmentUtil.getUrlArgValue('offset')) || 2;
			var scale_small:Number =  Number(EnvironmentUtil.getUrlArgValue('scale')) || .25;
			var small_w:int = 55;
			var small_h:int = 75;
			
			// unless we specifically say so, do not use the above values, because we'll send a full size png and let the
			// server size it down
			if (EnvironmentUtil.getUrlArgValue('SWF_make_small_small') != '1') {
				offset_small = offset_large;
				scale_small = scale_large;
				small_w = large_w;
				small_h = large_h;
			}
			
			if (small_card_ui) {
				small_card_ui.reset(false);
			} else {
				small_card_ui = new ImgCardUI(cards_mc, scale_small, 1.05, false, false, false);
			}
			small_card_ui.show(card);
			small_card_ui.hideFrontTextAndSuit();
			small_card_ui.alpha = 1;
			small_card_ui.x = (small_card_ui.width/2)-(offset_small);
			small_card_ui.y = (small_card_ui.height/2)-(offset_small);
			small_holder.addChild(small_card_ui);
			small_holder.x = 220;
			
			img_large = new BitmapSnapshot(large_holder, 'image_large.png', large_w, large_h, null, true);
			var bm_large:Bitmap = new Bitmap(img_large.bmd);
			Console.info(bm_large.width+' '+bm_large.height);
			bm_large.y = 290;
			large_holder.addChild(bm_large);
			
			img_small = new BitmapSnapshot(small_holder, 'image_small.png', small_w, small_h, null, true);
			var bm_small:Bitmap = new Bitmap(img_small.bmd);
			Console.info(bm_small.width+' '+bm_small.height);
			bm_small.x = small_holder.x;
			bm_small.y = bm_large.y;
			large_holder.addChild(bm_small);
		}
		
		private function save():void {
			var api_url:String = 'http://api.dev.glitch.com/';
			img_large.saveOnServerMultiPart(
				'image_large',
				{
					id:card.id
				},
				api_url+'simple/god.upgrades.setImage',
				{
					image_small: img_small.bmd	
				},
				loadingImageParse
			);
		}
		
		private function loadingImageParse(ok:Boolean, txt:String = ''):void {
			try {
				var json:Object = com.adobe.serialization.json.JSON.decode(txt);
				Console.dir(json);
				ExternalInterface.call(flashvars.save_callback_name, json.url_l, json.url_s);
			} 
			catch(err:Error) {
				CONFIG::debugging {
					Console.warn(txt+' NOT JSON');
				}
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
		
	}
}