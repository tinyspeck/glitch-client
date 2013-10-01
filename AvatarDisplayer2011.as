package {
	import caurina.transitions.Tweener;
	
	import com.adobe.serialization.json.JSON;
	import com.tinyspeck.bridge.FlashVarModel;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.data.AvatarAnimationDefinitions;
	import com.tinyspeck.core.data.FlashVarData;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.pc.AvatarConfig;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.loader.AvatarConfigRecord;
	import com.tinyspeck.engine.loader.AvatarResourceManager;
	import com.tinyspeck.engine.memory.EnginePools;
	import com.tinyspeck.engine.model.TSEngineConstants;
	import com.tinyspeck.engine.spritesheet.AvatarSSManager;
	import com.tinyspeck.engine.spritesheet.SSAbstractSheet;
	import com.tinyspeck.engine.spritesheet.SSViewSprite;
	import com.tinyspeck.engine.util.DisplayDebug;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.ObjectUtil;
	import com.tinyspeck.engine.util.PNGUtil;
	import com.tinyspeck.engine.view.loadedswfs.AvatarSwf;
	import com.tinyspeck.engine.view.ui.Checkbox;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.external.ExternalInterface;
	import flash.filters.GlowFilter;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	
	[SWF(width='80', height='140', backgroundColor='#cc0000', frameRate='30')]
	public class AvatarDisplayer2011 extends MovieClip {
		Security.allowDomain("*");
		
		[Embed(source="../../TSEngineAssets/src/assets/swfs/spinner.swf")] public var Spinner:Class;
		
		private var ava_swf:AvatarSwf;
		private var snapshot_ava_swf:AvatarSwf;
		private var client_sized_back_ava_swf:AvatarSwf;
		private var client_sized_ava_swf:AvatarSwf;
		private var holder:Sprite = new Sprite();
		private var click_mc:Sprite = new Sprite();
		private var _selected:Boolean = false;
		private var glow_roll:GlowFilter = new GlowFilter();
		private var glow_sel:GlowFilter = new GlowFilter();
		private var ava_config:Object = {};
		private var hiding_body:Boolean = false;
		private var facing_left:Boolean = false;
		private var no_hover:Boolean = false;
		private var pre_selected:Boolean = false;
		private var flashvars:Object;
		private var ava_settings:Object;
		private var ava_article_img_settings:Object;
		private var spinner:MovieClip;
		private var in_article_editor:Boolean;
		private var is_hair_color:Boolean;
		private var new_skin_coloring:Boolean;
		private var show_ss:Boolean;
		private var avatar_url:String;
		private var ss_view:SSViewSprite;
		private var ss:SSAbstractSheet;
		
		public function AvatarDisplayer2011() { 
			// disable yellow tabbing rectangle
			stage.stageFocusRect = false;
			stage.frameRate = TSEngineConstants.TARGET_FRAMERATE;
			
			stage.showDefaultContextMenu = false;
			//stage.scaleMode = StageScaleMode.NO_SCALE;
			//stage.align = StageAlign.TOP_LEFT;
			init();
		}
		
		private function init():void {
			const fvm:FlashVarModel = new FlashVarModel(FlashVarData.createFlashVarData(this));
			StageBeacon.init(stage, fvm);
			EnginePools.init();
			AvatarSSManager.init('');
			
			spinner = new Spinner();
			
			CONFIG::debugging {
				Console.setOutput(Console.FIREBUG, true);
				Console.setPri(EnvironmentUtil.getURLAndQSArgs().args['pri'] || '0');
				//Console.dir(EnvironmentUtil.getURLAndQSArgs())
			}
			
			flashvars = LoaderInfo(root.loaderInfo).parameters;
			avatar_url = flashvars.avatar_url;
			AvatarResourceManager.avatar_url = avatar_url;
			
			show_ss = boolFromFlashvar('show_ss');
			if (!show_ss) show_ss = EnvironmentUtil.getUrlArgValue('SWF_show_ss') == '1';
			
			in_article_editor = boolFromFlashvar('in_article_editor');
			is_hair_color = boolFromFlashvar('is_hair_color');
			new_skin_coloring = boolFromFlashvar('new_skin_coloring');
			
			if (in_article_editor || show_ss) {
				stage.align = StageAlign.TOP_LEFT;
				stage.scaleMode = StageScaleMode.NO_SCALE;
			}
			
			if (flashvars.ava_settings_json) {
				ava_settings = com.adobe.serialization.json.JSON.decode(flashvars.ava_settings_json);
				CONFIG::debugging {
					Console.info('ava_settings: '+typeof ava_settings);
					Console.dir(ava_settings);
				}
			}
			
			if (!ava_settings) {
				CONFIG::debugging {
					Console.error('no ava_settings!');
				}
				return;
			}
			
			AvatarConfig.settings = ava_settings;
			
			//Console.dir(flashvars);
			//Console.info(flashvars.ava_config_json);
			
			if (flashvars.ava_config_json) {
				ava_config = com.adobe.serialization.json.JSON.decode(flashvars.ava_config_json);
				CONFIG::debugging {
					Console.info('ava_config: '+typeof ava_config);
					Console.dir(ava_config);
				}
				if (typeof ava_config != 'object' || !ava_config) ava_config = {};
			}

			if (flashvars.ava_article_img_settings) {
				ava_article_img_settings = com.adobe.serialization.json.JSON.decode(flashvars.ava_article_img_settings);
			}

			// just in case we do not get this, protect from RTEs
			if (typeof ava_article_img_settings != 'object' || !ava_article_img_settings) ava_article_img_settings = {
				scale: 1
			};

			PNGUtil.setAPIUrl(flashvars.api_url, flashvars.api_token);
			
			hideSpinner();
			
			if (EnvironmentUtil.getUrlArgValue('SWF_show_ava_rect') == '1' && in_article_editor) {
				StageBeacon.enter_frame_sig.add(onEnterFrame);
			}

			go();
			
			if (show_ss) {
				loadAvatar(avatar_url, function(ava_loader:Loader):void {
					AvatarSSManager.run(MovieClip(ava_loader.content), afterSSAvaLoad);
				});
			}
			
		}
		
		private function afterSSAvaLoad():void {
			StageBeacon.enter_frame_sig.add(AvatarSSManager.onEnterFrame);
			makeSS();
		}
		
		private function makeSS():void {
			
			var ac:AvatarConfig = AvatarConfig.fromAnonymous(ava_config);
			ss = AvatarSSManager.getSSForAva(ac, '');
			
			if (ss == AvatarSSManager.default_ss) {
				ss = null;
				return;
			} 
			
			setUpSS();
		}
		
		private function onSSReady():void {
			if (flashvars.avatar_ss_ready_callback_name) {
				ExternalInterface.call(flashvars.avatar_ss_ready_callback_name);
			}

			CONFIG::debugging {
				Console.warn('onSSReady');
			}
		}
		
		private function setUpSS():void {
			var was_ss_view:SSViewSprite = ss_view;
			
			ss_view = ss.getViewSprite();
			
			Tweener.addTween(was_ss_view, {alpha:0, transition:'linear', time:.6, onComplete:function():void {
				if (was_ss_view.parent) was_ss_view.parent.removeChild(was_ss_view);
			}});
			
			onSSReady();
			
			var ac:AvatarConfig = AvatarConfig.fromAnonymous(ava_config);
			AvatarSSManager.playSSViewForAva(ac, '', ss_view, ss_view.gotoAndLoop, 0, 'walk2x');
			
			if (in_article_editor) {
				ss_view.x = 162;
				ss_view.y = 40;
			}
			
			addChild(ss_view);
			
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
		
		private function drawBG(c:uint, a:Number):void {
			var g:Graphics = this.graphics;
			g.clear();
			g.lineStyle(0, 0, 0);
			g.beginFill(c, a);
			g.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			g.endFill();
		}
		
		private function loadAvatar(url:String, completeFunc:Function):void {
			CONFIG::debugging {
				Console.log(66, url);
			}
			var ava_loader:Loader = new Loader();
			var loaderContext:LoaderContext = new LoaderContext(false,new ApplicationDomain(ApplicationDomain.currentDomain), null);
			ava_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void{completeFunc(ava_loader)});
			ava_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function():void{});
			ava_loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, function():void{});
			
			ava_loader.load(new URLRequest(url), loaderContext);
		}
		
		private function onEnterFrame(ms_elapsed:int):void {
			drawAvaRect();
		}
		
		private function drawAvaRect():void {
			if (!ava_swf) return;
			if (!ava_swf.parent) return;
			if (ava_swf.parent != holder) return;
			ava_swf.hideHead();
			
			DisplayDebug.drawRects(ava_swf.avatar);
			//var rect:Rectangle = ava_swf.getBounds(holder);
			var g:Graphics = holder.graphics;
			g.clear();
			g.lineStyle(3, 0x00cc00, 1);
			//g.drawRect(rect.x, rect.y, rect.width, rect.height);
		}
		
		private function updateConfigJsonWithArticleExtras(config:Object):Object {
			var ob:Object = ObjectUtil.copyOb(config);
			if (ava_article_img_settings && ava_article_img_settings.img_articles) {
				for (var k:String in ava_article_img_settings.img_articles) {
					ob.articles[k] = ava_article_img_settings.img_articles[k];
				}
			}
			return ob;
		}
		
		private function saveCallback(ok:Boolean, txt:String = ''):void {
			var rsp_json:Object;
			try {
				rsp_json = com.adobe.serialization.json.JSON.decode(txt);
			} catch(err:Error) {
				//return false;
			}
			if (flashvars.save_callback_name) {
				ExternalInterface.call(flashvars.save_callback_name, ok, rsp_json);
			}
		}
		
		public function setFPS(i:int):void {
			stage.frameRate = Math.max(0, Math.min(24, i));
			CONFIG::debugging {
				Console.info('stage.frameRate:'+stage.frameRate);
			}
		}
		
		private var loop_anim:Boolean = false;
		public function setLooping(v:Boolean):void {
			loop_anim = v;
		}
		
		public function playWardrobeAnimation(seq_anim:*):void {
			if (!ava_swf) return;
			ava_swf.playAnimationSeq(seq_anim, afterWardrobeAnimationSeq);
		}
		
		public function afterWardrobeAnimationSeq():void {
			if (!ava_swf) return;
			ava_swf.playAnimation('walk1x', null, 13);
		}
		
		public function gotoFrameNumAndStop(i:int):void {
			if (!ava_swf) return;
			ava_swf.playFrameSeq([int(i)]);
		}
		
		private var current_framesA:Array;
		
		public function playAnimationAndReturnFrames(anim:String):Array {
			var framesA:Array = AvatarAnimationDefinitions.getFramesForAnim(anim);
			if (!ava_swf) return framesA;

			playFrameSeq(framesA);
			
			return framesA;
		}
		
		public function playFrameSeq(framesA:Array):void {
			if (!ava_swf) return;
			current_framesA = framesA;
			ava_swf.playFrameSeq(framesA, afterPlayFrameSeq);
		}
		
		public function afterPlayFrameSeq():void {
			if (!ava_swf) return;
			if (loop_anim && current_framesA.length>1) {
				StageBeacon.waitForNextFrame(ava_swf.playFrameSeq, current_framesA, afterPlayFrameSeq);
			}
		}
		
		public function playAnimationSeq(seq_anim:*):void {
			if (!ava_swf) return;
			
			ava_swf.playAnimationSeq(seq_anim);
			if (client_sized_ava_swf) client_sized_ava_swf.playAnimationSeq(seq_anim);
		}
		
		public function saveArticlePng(method:String = '', id:String='', img_settings:Object=null):void {
			id = id || flashvars.id;
			
			if (img_settings is String) {
				try {
					img_settings = com.adobe.serialization.json.JSON.decode(String(img_settings));
				} catch(err:Error) {
					CONFIG::debugging {
						Console.error('Bad json string: '+img_settings);
					}
				}
			}
			
			img_settings = img_settings || ava_article_img_settings;
			
			PNGUtil.saveArticlePngFromAvatarMc(method, id, snapshot_ava_swf, AvatarConfig.fromAnonymous(updateConfigJsonWithArticleExtras(ava_config)), img_settings, saveCallback);
		}
		
		public function selected(sel:Boolean):Boolean {
			_selected = (sel == true);
			if (_selected) {
				highlight();
			} else {
				unhighlight();
			}
			return _selected;
		}
		
		//private var unused_new_ava_config_json:*;
		public function set_state(new_ava_config_json:*):Boolean {
			if (new_ava_config_json is String) {
				try {
					ava_config = com.adobe.serialization.json.JSON.decode(new_ava_config_json);
				} catch(err:Error) {
					return false;
				}
			} else {
				ava_config = new_ava_config_json;
			}
			
			if (!ava_config) ava_config = {};
			if (typeof ava_config == 'object') {
				//Console.dir((ava_config));
				if (ava_swf) {
					initializeHead();
				}
				return true;
			}
			
			return false;
		}
		
		public function hide_body():void {
			if (ava_swf) ava_swf.hideBody();
			if (client_sized_ava_swf) client_sized_ava_swf.hideBody();
			if (client_sized_back_ava_swf) client_sized_back_ava_swf.hideBody();
			hiding_body = true;
		}
		
		public function show_body():void {
			if (ava_swf) ava_swf.showBody();
			if (client_sized_ava_swf) client_sized_ava_swf.showBody();
			if (client_sized_back_ava_swf) client_sized_back_ava_swf.showBody();
			hiding_body = false;
		}
		
		public function face_left():void {
			if (ava_swf && ava_swf.avatar) ava_swf.avatar.scaleX = -1;
			if (client_sized_ava_swf && client_sized_ava_swf.avatar) client_sized_ava_swf.avatar.scaleX = -1;
			if (client_sized_back_ava_swf && client_sized_back_ava_swf.avatar) client_sized_back_ava_swf.avatar.scaleX = -1;
			facing_left = true;
		}
		
		public function face_right():void {
			if (ava_swf && ava_swf.avatar) ava_swf.avatar.scaleX = 1;
			if (client_sized_ava_swf && client_sized_ava_swf.avatar) client_sized_ava_swf.avatar.scaleX = 1;
			if (client_sized_back_ava_swf && client_sized_back_ava_swf.avatar) client_sized_back_ava_swf.avatar.scaleX = 1;
			facing_left = false;
		}
		
		private function boolFromFlashvar(name:String):Boolean {
			return (flashvars.hasOwnProperty(name) && (flashvars[name] == true || flashvars[name].toString().toLowerCase() == 'true'));
		}
		
		private var ss_timer:int;
		private function articleReadyCallback():void {
			hideSpinner();
			
			if (show_ss) {
				if (ss_timer) {
					StageBeacon.clearTimeout(ss_timer);
				}
				
				// timeout can be immediate if we're doing lazy SS generation
				ss_timer = StageBeacon.setTimeout(makeSS, (AvatarSSManager.lazy_ss ? 0 : 100));
			}
			
			if (flashvars.avatar_swf_ready_callback_name) {
				ExternalInterface.call(flashvars.avatar_swf_ready_callback_name, ava_swf.colors_mc_names_by_slot);
			}
		} 
		
		private var current_ac:AvatarConfig;
		private function initializeHead():void {
			
			if (show_ss && current_ac && ss_view) {
				AvatarSSManager.removeSSViewforAva(current_ac, '', ss_view);
				ss_view = null;
			}
			
			var ac:AvatarConfig = AvatarConfig.fromAnonymous(ava_config);
			var acr:AvatarConfigRecord = AvatarResourceManager.instance.getAvatarConfigRecord(ac, (show_ss) ? AvatarSSManager.ava_swf : ava_swf);
			current_ac = ac;
			//ava_swf.playAnimation('idle0');
			//ava_swf.stopAll();
			ava_swf.playFrameSeq([14]);
			ava_swf.initializeHead(ac);
			
			if (client_sized_ava_swf) {
				client_sized_ava_swf.playFrameSeq([14]);
				client_sized_ava_swf.initializeHead(ac);
			}
			
			if (client_sized_back_ava_swf) {
				client_sized_back_ava_swf.playFrameSeq([1150]);
				client_sized_back_ava_swf.initializeHead(ac);
			}
			
			if (!acr.ready) {
				showSpinner();
				spinner.alpha = 0;
				Tweener.removeTweens(spinner);
				Tweener.addTween(spinner, {alpha:1, time:.6, delay:.3});
				//Console.warn('ac is not ready, can't snap yet');
				
				acr.addCallback(function(ac:AvatarConfig):void {
					if (current_ac.sig == ac.sig) {
						ava_swf.initializeHead(ac);
						if (client_sized_ava_swf) client_sized_ava_swf.initializeHead(ac);
						if (client_sized_back_ava_swf) client_sized_back_ava_swf.initializeHead(ac);
						articleReadyCallback();
					} else {
						; // satisfy compiler
						CONFIG::debugging {
							Console.priwarn(89, ac.sig+' IS NOT '+current_ac.sig);
						}
					}
				});
			} else {
				articleReadyCallback();
			}
		}
		
		private function go():void {
			
			if (in_article_editor && !client_sized_ava_swf) {
				CONFIG::debugging {
					Console.warn('loading client_sized_ava_swf');
				}
				loadAvatar(avatar_url, function(ava_loader:Loader):void {
					client_sized_ava_swf = new AvatarSwf(MovieClip(ava_loader.content), new_skin_coloring);
					client_sized_ava_swf.scaleX = client_sized_ava_swf.scaleY = AvatarSSManager.ss_options.scale;
					client_sized_ava_swf.x = 86;
					client_sized_ava_swf.y = 40;
					holder.addChild(client_sized_ava_swf);
					client_sized_ava_swf.visible = false;
					go();
				});
				return;
			}
			
			if (in_article_editor && !client_sized_back_ava_swf) {
				CONFIG::debugging {
					Console.warn('loading client_sized_back_ava_swf');
				}
				loadAvatar(avatar_url, function(ava_loader:Loader):void {
					client_sized_back_ava_swf = new AvatarSwf(MovieClip(ava_loader.content), new_skin_coloring);
					client_sized_back_ava_swf.scaleX = client_sized_back_ava_swf.scaleY = AvatarSSManager.ss_options.scale;
					client_sized_back_ava_swf.x = 10;
					client_sized_back_ava_swf.y = 40;
					holder.addChild(client_sized_back_ava_swf);
					client_sized_back_ava_swf.visible = false;
					go();
				});
				return;
			}
			
			if (!snapshot_ava_swf) {
				CONFIG::debugging {
					Console.warn('loading snapshot_ava_swf');
				}
				loadAvatar(avatar_url, function(ava_loader:Loader):void {
					snapshot_ava_swf = new AvatarSwf(MovieClip(ava_loader.content), new_skin_coloring);
					go();
				});
				return;
			}
			
			hiding_body = boolFromFlashvar('hide_body');
			facing_left = (flashvars.face == 'left');
			no_hover = boolFromFlashvar('no_hover');
			pre_selected = boolFromFlashvar('pre_selected');
			
			var g:Graphics = click_mc.graphics;
			g.lineStyle(0, 0, 0);
			g.beginFill(0x000000, 0);
			g.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			addChild(click_mc);
			
			glow_roll.color = 0xfcff00;
			glow_roll.blurX = 4;
			glow_roll.blurY = 4;
			glow_roll.strength = 12;
			glow_roll.quality = 4;
			
			glow_sel.color = 0x53e5ff;//0xfcff00;
			glow_sel.blurX = 4;
			glow_sel.blurY = 4;
			glow_sel.strength = 12;
			glow_sel.quality = 4;
			
			holder.name = 'holder';
			holder.x = 0;
			holder.y = 0;
			addChild(holder);
			addChild(click_mc);
			
			if (in_article_editor) {
				var cb:Checkbox = new Checkbox({
					x: 5,
					y: stage.stageHeight,
					checked: false,
					label: 'dark bg',
					name: 'benchmark'
				});
				cb.y = stage.height-5-cb.h;
				cb.filters = StaticFilters.white1px_GlowA;
				addChild(cb);
				cb.addEventListener(TSEvent.CHANGED, function(e:TSEvent):void {
					if (e.data.checked) {
						drawBG(0x33333, 1);
					} else {
						drawBG(0x33333, 0);
					}
				}, false, 0, true);
			}
			
			CONFIG::debugging {
				Console.warn('loading ava_swf');
			}
			
			loadAvatar(avatar_url, function(ava_loader:Loader):void {
				
				if (client_sized_ava_swf) client_sized_ava_swf.visible = true;
				if (client_sized_back_ava_swf) client_sized_back_ava_swf.visible = true;
				ava_swf = new AvatarSwf(MovieClip(ava_loader.content), new_skin_coloring);
				
				if (in_article_editor) {

				} else {
					holder.x = stage.stageWidth/2;
					holder.y = stage.stageHeight/2;
				}
				
				CONFIG::debugging {
					Console.info('animations available: '+AvatarAnimationDefinitions.getSheetedAnimsA());
				}
				
				if (facing_left) {
					face_left();
				} else {
					face_right();
				}
				
				if (hiding_body) {
					hide_body();
				} else {
					show_body();
				}

				if (in_article_editor) {
					ava_swf.scaleX = ava_swf.scaleY = 2.8;
					ava_swf.x = stage.stageWidth-ava_swf.width-100;
					ava_swf.y = 15*ava_swf.scaleX;
					
				} else {
					ava_swf.x = -(80/2);
					ava_swf.y = -67;
				}
				
				holder.addChild(ava_swf);
				
				initializeHead();
				
				click_mc.addEventListener(MouseEvent.CLICK, function(e:Event):void {
					//DisplayDebug.LogCoords(stage, 20);
					if (flashvars.callback_name) ExternalInterface.call(flashvars.callback_name, flashvars.id);
				});
				
				if (!no_hover) {
					click_mc.addEventListener(MouseEvent.MOUSE_OVER, function(e:Event):void {
						if (_selected) {
							
						} else {
							highlight();
						}
					});
					
					click_mc.addEventListener(MouseEvent.MOUSE_OUT, function(e:Event):void {
						if (_selected) {
							
						} else {
							unhighlight();
						}
					});
				}
				
				if (pre_selected || _selected) {
					_selected = true;
					highlight();
				}
				
				ExternalInterface.addCallback('saveArticlePng', saveArticlePng);
				ExternalInterface.addCallback('selected', selected);
				ExternalInterface.addCallback('set_state', set_state);
				ExternalInterface.addCallback('face_right', face_right);
				ExternalInterface.addCallback('face_left', face_left);
				ExternalInterface.addCallback('hide_body', hide_body);
				ExternalInterface.addCallback('show_body', show_body);
				ExternalInterface.addCallback('playAnimationSeq', playAnimationSeq);
				ExternalInterface.addCallback('playAnimationAndReturnFrames', playAnimationAndReturnFrames);
				ExternalInterface.addCallback('playWardrobeAnimation', playWardrobeAnimation);
				ExternalInterface.addCallback('gotoFrameNumAndStop', gotoFrameNumAndStop);
				ExternalInterface.addCallback('playFrameSeq', playFrameSeq);
				ExternalInterface.addCallback('setFPS', setFPS);
				ExternalInterface.addCallback('setLooping', setLooping);
				CONFIG::debugging {
					ExternalInterface.addCallback('giveAnimationPHPReport', giveAnimationPHPReport);
					ExternalInterface.addCallback('giveAnimationReport', giveAnimationReport);
				}
				if (flashvars.avatar_app_ready_callback_name) {
					ExternalInterface.call(flashvars.avatar_app_ready_callback_name);
				}
			});
			
			addChild(spinner);
			
		}
		
		CONFIG::debugging private function giveAnimationPHPReport():String {
			var report:String = AvatarAnimationDefinitions.getPHPReport();
			Console.info(report);
			return report;
		}
		
		CONFIG::debugging private function giveAnimationReport():String {
			var report:String = AvatarAnimationDefinitions.getReport();
			Console.info(report);
			return report;
		}
		
		private function unhighlight():void {
			holder.filters = null;
			holder.scaleX = holder.scaleY = 1;
		}
		
		private function highlight():void {
			if (_selected) {
				holder.filters = [glow_sel];
			} else {
				holder.filters = [glow_roll];
			}
			holder.scaleX = holder.scaleY = 1.1;
			
		}
	}
}
