package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.API;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.NewxpLogger;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.house.ConfigOption;
	import com.tinyspeck.engine.data.pc.AvatarConfig;
	import com.tinyspeck.engine.loader.AvatarConfigRecord;
	import com.tinyspeck.engine.loader.AvatarResourceManager;
	import com.tinyspeck.engine.loader.SmartLoader;
	import com.tinyspeck.engine.model.WorldModel;
	import com.tinyspeck.engine.net.NetOutgoingAvatarGetChoicesVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.loadedswfs.AvatarSwf;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.ConfiggerUI;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.text.TextField;
	
	public class NewAvaConfigDialog extends BigDialog implements IFocusableComponent {
		/* singleton boilerplate */
		public static const instance:NewAvaConfigDialog = new NewAvaConfigDialog();
		
		private var wm:WorldModel;
		
		private var body_sp:Sprite;
		private var foot_sp:Sprite;
		private var save_bt:Button;
		
		private var was_config:Object;
		private var changed_config:Object = {articles:{}};
		private var raw_changed_config:Object = {};
		private var has_config_changed:Boolean;
		private var saving:Boolean;
		private var config_options:Vector.<ConfigOption> = new Vector.<ConfigOption>();
		private var ava_loader:SmartLoader;
		private var ava_swf:AvatarSwf;
		private var current_ac:AvatarConfig;
		private var configger_ui:ConfiggerUI;
		
		private var surprise_bt:Sprite = new Sprite();
		private var angry_bt:Sprite = new Sprite();
		private var happy_bt:Sprite = new Sprite();
		private var idle_bt:Sprite = new Sprite();
		private var tf:TextField = new TextField();
		private var ava_bg:Sprite = new Sprite();
		private var ava_bg_mask:Shape = new Shape();
		private var ava_bg_bmp:Bitmap = new AssetManager.instance.assets['wardrobe_background']();
		
		private var anim_btnsA:Array = ['surprise_bt', 'angry_bt', 'happy_bt', 'idle_bt'];
		private var anim_btns_anim_map:Object = {
			surprise_bt: 'surprise',
			angry_bt: 'angry',
			happy_bt: 'happy',
			idle_bt: 'idle3'
		};
		
		public function NewAvaConfigDialog() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			wm = model.worldModel;
			_body_border_c = 0xffffff;
			_close_bt_padd_right = 9;
			_close_bt_padd_top = 9;
			_body_max_h = 500;
			_w = 430;
			_draggable = false;
			_construct();
		}
		
		override protected function _construct() : void {
			super._construct();
			_close_bt.visible = false;
			_close_bt.disabled = true;
		}
		
		public function loadChoices(and_start:Boolean=false):void {
			TSFrontController.instance.genericSend(
				new NetOutgoingAvatarGetChoicesVO(),
				and_start ? onChoicesAndStart : onChoices,
				and_start ? onChoicesAndStart : onChoices
			);
		}
		
		private function onChoicesAndStart(rm:NetResponseMessageVO):void {
			if (rm.success) {
				setInitialConfig();
				start();
			} else {
				
			}
		}
		
		private function onChoices(rm:NetResponseMessageVO):void {
			if (rm.success) {
				setInitialConfig();
			} else {
				
			}
		}
		
		private function setInitialConfig():void {
			config_options = ConfigOption.parseMultiple(ConfigOption.ava_raw_options, config_options);
			
			if (ConfigOption.ava_default_options) {
				var option_names:Array = [];
				var option_values:Array = [];
				for (var k:String in ConfigOption.ava_default_options) {
					option_names.push(k);
					option_values.push(ConfigOption.ava_default_options[k]);
				}
				changeConfigOptions(option_names, option_values);
			} else {
				// since we dont have the swf yet, this will just set a random changed_config
				showRandomConfig();
			}
		}
		
		public function loadAvatar(and_start:Boolean=false):void {
			ava_loader = new SmartLoader('avatar');
			// these are automatically removed on complete or error:
			ava_loader.complete_sig.add(function onAvatarLoadComplete(loader:SmartLoader):void {
				ava_swf = new AvatarSwf(ava_loader.content as MovieClip, false);
				initializeHead(and_start);
			});
			
			var loaderContext:LoaderContext = new LoaderContext(false,new ApplicationDomain(ApplicationDomain.currentDomain), null);
			ava_loader.load(new URLRequest(model.flashVarModel.avatar_url), loaderContext);
		}
		
		private function showRandomConfig():void {
			var random_i:int;
			var option:ConfigOption;
			var option_names:Array = [];
			var option_values:Array = [];
			
			// choose some random options
			for(var i:int=0; i<config_options.length; i++){
				option = config_options[int(i)];
				if (!option.choices || !option.choices.length) continue;
				random_i = MathUtil.randomInt(0, option.choices.length-1);
				option_names.push(option.id);
				option_values.push(option.choices[random_i]);
			}
			
			changeConfigOptions(option_names, option_values);
			if (configger_ui) setConfigChoices();
		}
		
		private function setConfigChoices():Boolean {
			if (!ConfigOption.populateConfigChoicesForAva(config_options, raw_changed_config)) {
				return false;
			}
			
			configger_ui.startWithConfigs(config_options, true, false, false, ConfigOption.ava_option_names_breaks);
			refresh();
			return true;
		}
		
		private function changeConfigOptions(option_names:Array, option_values:Array):void {
			//Console.info('option_names '+option_names);
			//Console.dir(option_values);
			
			NewxpLogger.log('ava_changed');
			
			has_config_changed = true;
			raw_changed_config = {};
			
			var option_name:String;
			var option_value:Object;
			var option_value_hash:Object;
			
			for (var i:int=0;i<option_names.length;i++) {
				if (i > option_values.length-1) break;
				option_name = option_names[i];
				option_value = option_values[i];
				if (!option_value) break;
				
				option_value_hash = ConfigOption.ava_raw_options[option_name][option_value];
				raw_changed_config[option_name] = option_value;
				
				for (var k:String in option_value_hash) {
					if (k == 'articles') {
						for (var a:String in option_value_hash.articles) {
							//Console.info(option_name+' '+k+' '+a+': '+option_value_hash.articles[a]);
							changed_config.articles[a] = option_value_hash.articles[a];
						}
					} else {
						//Console.info(option_name+' '+k+': '+option_value_hash[k]);
						changed_config[k] = option_value_hash[k];
					}
				}
			}
			/*
			CONFIG::debugging {
			Console.dir(changed_config);
			Console.dir(raw_changed_config);
			}
			*/
			if (ava_swf) initializeHead();
		}
		
		private function initializeHead(and_start:Boolean=false):void {
			
			current_ac = AvatarConfig.fromAnonymous(changed_config);
			var acr:AvatarConfigRecord = AvatarResourceManager.instance.getAvatarConfigRecord(current_ac, ava_swf);
			
			if (!acr.ready) {
				acr.addCallback(function(ac:AvatarConfig):void {
					if (current_ac.sig == ac.sig) {
						ava_swf.initializeHead(ac);
						if (and_start) start();
					} else {
						; // satisfy compiler
						CONFIG::debugging {
							Console.priwarn(89, ac.sig+' IS NOT '+current_ac.sig);
						}
					}
				});
			} else {
				ava_swf.initializeHead(current_ac);
				if (and_start) start();
			}
		}
		
		override public function start():void {
			if (parent) return;
			if (!canStart(true)) return;
			
			if (!ConfigOption.ava_raw_options) {
				loadChoices(true);
				return;
			}
			
			if (!ava_swf) {
				loadAvatar(true);
				return;
			}
			
			NewxpLogger.log('starting_ava_picker');
			
			initializeHead();
			
			if (!body_sp) {
				body_sp = new Sprite();
				var g:Graphics = body_sp.graphics;
				g.beginFill(0,0);
				g.drawRect(0,0,20,200);
				
				var ava_bg_x:int = 0;
				var ava_bg_y:int = 1;
				var right_side_w:int = 210;
				var left_side_w:int = _w-right_side_w;
				var buttons_y:int;
				var buttons_padd:int = 9;
				
				ava_bg.x = ava_bg_mask.x = ava_bg_x;
				ava_bg.y = ava_bg_mask.y = ava_bg_y;
				
				body_sp.addChild(ava_bg);
				body_sp.addChild(ava_bg_mask);
				ava_bg.addChild(ava_bg_bmp);
				
				// clone a new one to stretch as far as we need
				var ava_bg_bmp2:Bitmap = new Bitmap(ava_bg_bmp.bitmapData);
				ava_bg_bmp2.x = ava_bg_bmp.width
				ava_bg.addChild(ava_bg_bmp2);
				
				ava_bg_mask.graphics.lineStyle(0, 0, 0);
				ava_bg_mask.graphics.beginFill(0, 1);
				ava_bg_mask.graphics.drawRect(0, 0, left_side_w, ava_bg_bmp.height-9); // 9 px of white on the bottom of the img
				ava_bg.mask = ava_bg_mask;
				
				TFUtil.prepTF(tf, true);
				tf.x = 10;
				tf.width = left_side_w-(tf.x*2);
				body_sp.addChild(tf);
				
				var txt:String = '<p class="new_ava_text">' +
					'These are just some of the ways to customize your look. You\'ll have many more options available later!' +
					'</p>';
				
				tf.htmlText = txt;
				
				AssetManager.instance.loadBitmapFromWeb('vanity_surprised_button.png', function(filename:String, bm:Bitmap):void {
					buttons_y = ava_bg_mask.y+ava_bg_mask.height-(bm.height/2);
					tf.y = buttons_y+45;
					
					surprise_bt.addChild(bm);
					surprise_bt.x = Math.round(left_side_w/2)-(bm.width*2)-(buttons_padd*1.5);
					surprise_bt.y = buttons_y;
					body_sp.addChild(surprise_bt);
					
					AssetManager.instance.loadBitmapFromWeb('vanity_angry_button.png', function(filename:String, bm:Bitmap):void {
						angry_bt.addChild(bm);
						angry_bt.x = Math.round(left_side_w/2)-(bm.width)-(buttons_padd*.5);
						angry_bt.y = buttons_y;
						body_sp.addChild(angry_bt);
					}, 'vanity_angry_button.png');
					
					AssetManager.instance.loadBitmapFromWeb('vanity_happy_button.png', function(filename:String, bm:Bitmap):void {
						happy_bt.addChild(bm);
						happy_bt.x = Math.round(left_side_w/2)+(buttons_padd*.5);
						happy_bt.y = buttons_y;
						body_sp.addChild(happy_bt);
					}, 'vanity_happy_button.png');
					
					AssetManager.instance.loadBitmapFromWeb('vanity_sleepy_button.png', function(filename:String, bm:Bitmap):void {
						idle_bt.addChild(bm);
						idle_bt.x = Math.round(left_side_w/2)+(bm.width)+(buttons_padd*1.5);
						idle_bt.y = buttons_y;
						body_sp.addChild(idle_bt);
					}, 'vanity_sleepy_button.png');
					
				}, 'vanity_surprised_button.png');
				
				var bt:Sprite;
				for (var i:int;i<anim_btnsA.length;i++) {
					bt = this[anim_btnsA[int(i)]] as Sprite;
					bt.useHandCursor = bt.buttonMode = true;
					bt.name = anim_btnsA[int(i)];
					bt.addEventListener(MouseEvent.CLICK, onAnimBtClick);
				}
				
				configger_ui = new ConfiggerUI(right_side_w-5, true);
				configger_ui.x = _w-(right_side_w);
				configger_ui.y = 1;
				configger_ui.change_config_sig.add(changeConfigOptions);
				configger_ui.randomize_sig.add(showRandomConfig);
				body_sp.addChild(configger_ui);
				configger_ui.filters = StaticFilters.chat_left_shadowA;
				
				ava_swf.playFrameSeq([14]);
				body_sp.addChild(ava_swf);
				ava_swf.scaleX = ava_swf.scaleY = 1.7;
				ava_swf.x = 52;
				ava_swf.y = 50;
				
				foot_sp = new Sprite();
				save_bt = new Button({
					name: 'save',
					label: 'Save',
					size: Button.SIZE_TINY,
					type: Button.TYPE_MINOR,
					w: 80
				});
				save_bt.addEventListener(MouseEvent.CLICK, onSaveButtonClick);
				save_bt.x = Math.round(_w + -save_bt.width + -15);
				save_bt.y = 9;
				foot_sp.addChild(save_bt);
				
				g = foot_sp.graphics;
				g.beginFill(0,0);
				g.drawRect(0,0,10,(save_bt.y*2)+2+save_bt.h);
			}
			
			if (!setConfigChoices()) {
				return;
			}
			
			_setGraphicContents(null/*new AssetManager.instance.assets.help_icon_large()*/);
			_setTitle('Customize your look');
			_setSubtitle('');
			_setBodyContents(body_sp);
			_setFootContents(foot_sp);
			
			super.start();
			
			// on top!
			
			save_bt.disabled = false;
		}
		
		private function onAnimBtClick(e:MouseEvent):void {
			var which:String = Sprite(e.target).name;
			var anim:String = anim_btns_anim_map[which];
			ava_swf.playAnimation(anim, function():void {
				ava_swf.playFrameSeq([14]);
			});
		}		
		
		override public function refresh():void {
			super.refresh();
		}
		
		
		private function saveOrClose():void {
			if (saving) {
				return;
			}
			
			if (!has_config_changed) {
				closeAndDiscard();
				return;
			}
			
			saving = save_bt.disabled = true;
			
			CONFIG::debugging {
				Console.dir({getValuesHash:configger_ui.getValuesHash()});
			}
			model.stateModel.newbie_chose_new_avatar = true;
			NewxpLogger.log('ava_saving');
			API.saveNewAvatar(configger_ui.getValuesHash(), onSave);
		}
		
		private function onSheetsReloaded():void {
			TSFrontController.instance.showCheckmark(model.worldModel.pc.x, model.worldModel.pc.y);
			model.stateModel.newbie_chose_new_avatar = false;
		}
		
		private function onSave(ok:Boolean, rsp:Object=null):void {
			NewxpLogger.log('ava_saved');
			saving = save_bt.disabled = false;
			
			if (ok) {
				//maybe here we should show a spinner while we wait for the sheets to reload?
				TSFrontController.instance.getMainView().gameRenderer.getAvatarView().sheets_reloaded_sig.addOnce(onSheetsReloaded);
				end(true);
			} else {
				var txt:String = (rsp && rsp.error) ? rsp.error : 'unspecified';
				TSFrontController.instance.quickConfirm('Hmmm, we failed to save your avatar. The error was "'+txt+'". Try again please.');
				BootError.handleError('Failed to save newbie avatar', new Error('NewAvaConfigDialog error from API:'+txt), ['NewAvaConfigDialog'], true, false);
				//closeAndDiscard();
			}
		}
		
		override protected function enterKeyHandler(e:KeyboardEvent):void {
			saveOrClose();
		}
		
		private function onSaveButtonClick(e:MouseEvent):void {
			saveOrClose();
		}
		
		override protected function closeFromUserInput(e:Event=null):void {
			return;
			
			if (saving) {
				SoundMaster.instance.playSound('CLICK_FAILURE');
				return;
			}
			
			if (has_config_changed) {
				closeAndDiscard();
				return;
			}
			
			super.closeFromUserInput(e);
		}
		
		private function closeAndDiscard():void {
			end(true);
		}
		
		override public function end(release:Boolean):void {
			if (saving) {
				return;
			}
			
			super.end(release);
			
		}
	}
}