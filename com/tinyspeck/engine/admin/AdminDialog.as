package com.tinyspeck.engine.admin {
	import com.bit101.components.HSlider;
	import com.quietless.bitmap.BitmapSnapshot;
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.data.AvatarAnimationDefinitions;
	import com.tinyspeck.debug.AdminDialogPhysicsPanel;
	import com.tinyspeck.debug.AdminDialogRookPanel;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.GeneralValueTracker;
	import com.tinyspeck.debug.PhysicsValueTracker;
	import com.tinyspeck.debug.RookValueTracker;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.LocalStorage;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.pc.AvatarConfig;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSEngineConstants;
	import com.tinyspeck.engine.net.NetOutgoingItemstackCreateVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.spritesheet.AvatarSSManager;
	import com.tinyspeck.engine.spritesheet.SSMultiBitmapSheet;
	import com.tinyspeck.engine.spritesheet.SSViewSprite;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.loadedswfs.AvatarSwf;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Checkbox;
	import com.tinyspeck.tstweener.TSTweener;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	
	public class AdminDialog extends BigDialog implements IFocusableComponent, ITipProvider {
		
		/* singleton boilerplate */
		public static const instance:AdminDialog = new AdminDialog();
		
		public const rook_panel:AdminDialogRookPanel = new AdminDialogRookPanel();
		private const content_sp:Sprite = new Sprite;
		private const _item_drag_sp:Sprite = new Sprite();
		private const _form:Sprite = new Sprite();
		private const physics_panel:AdminDialogPhysicsPanel = new AdminDialogPhysicsPanel();
		
		private var current_section:String = 'debug';
		private var items_sp:Sprite;
		private var tools_sp:Sprite;
		private var ss_sp:Sprite;
		private var physics_sp:Sprite;
		private var rook_sp:Sprite;
		private var debug_sp:Sprite;
		
		public function AdminDialog() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = 380;
			_body_max_h = 550;
			_body_min_h = 550;
			_draggable = true;
			close_on_move = false;
			close_on_editing = false;
			_construct();
		}
		
		override protected function _construct():void {
			super._construct();
			_subtitle_tf.addEventListener(TextEvent.LINK, subtitleTfLinkHandler);
			current_section = LocalStorage.instance.getUserData(LocalStorage.ADMIN_DIALOG_SECTION);
			
			// this is a click target, so when stamp dragging, there is always at least this to click on
			_item_drag_sp.graphics.beginFill(0xCC0000, 0);
			_item_drag_sp.graphics.drawRect(-50, -50, 100, 100);
		}
		
		public function subtitleTfLinkHandler(e:TextEvent):void {
			//Console.warn(e.text)
			var which:String = e.text;
			
			switch(which){
				case 'items':
				case 'tools':
				case 'ss':
				case 'physics':
				case 'rook':
					current_section = which;
					break;
				default:
					current_section = 'debug';
					break;
			}
			
			showCorrectSection();
		}
		
		private function constructPhysicsStuff():void {
			physics_sp = new Sprite();
			physics_sp.x = 10;
			physics_sp.y = 4;
			content_sp.addChild(physics_sp);
			
			physics_panel.init(physics_sp);
		}
		
		private function constructRookStuff():void {
			rook_sp = new Sprite();
			rook_sp.x = 10;
			rook_sp.y = 10;
			content_sp.addChild(rook_sp);
			
			rook_panel.init(rook_sp);
		}
		
		//-------------------------------------------------------------------------------------
		//-------------------------------------------------------------------------------------
		//-------------------------------------------------------------------------------------
		//-------------------------------------------------------------------------------------
		
		private var ss_view:SSViewSprite;
		private var ss:SSMultiBitmapSheet;
		private var full_bm:Bitmap;
		private var ava_swf:AvatarSwf;
		private function constructSSStuff():void {
			var pc:PC = model.worldModel.pc;
			ss_sp = new Sprite();
			content_sp.addChild(ss_sp);
			
			
			CONFIG::debugging {
				var short_report_bt:Button = new Button({
					label: 'Shrt Rprt',
					name: 'short_report_bt',
					x: 5,
					y: 5,
					w: 75
				});
				
				short_report_bt.addEventListener(MouseEvent.CLICK, function():void {
					var report:String = AvatarAnimationDefinitions.getReport(true);
					System.setClipboard(report);
					model.activityModel.growl_message = 'The short report has been put in your clipboard';
					Console.info(report);
				});
				ss_sp.addChild(short_report_bt);
				
				var report_bt:Button = new Button({
					label: 'Report',
					name: 'report_bt',
					x: 85,
					y: 5,
					w: 75
				});
				
				report_bt.addEventListener(MouseEvent.CLICK, function():void {
					var report:String = AvatarAnimationDefinitions.getReport();
					System.setClipboard(report);
					model.activityModel.growl_message = 'The report has been put in your clipboard';
					Console.info(report);
				});
				ss_sp.addChild(report_bt);
				
				var report_php_bt:Button = new Button({
					label: 'PHP',
					name: 'report_php_bt',
					x: 165,
					y: 5,
					w: 75
				});
				
				report_php_bt.addEventListener(MouseEvent.CLICK, function():void {
					var report:String = AvatarAnimationDefinitions.getPHPReport();
					System.setClipboard(report);
					model.activityModel.growl_message = 'The PHP has been put in your clipboard';
					Console.info(report);
				});
				ss_sp.addChild(report_php_bt);
			}
			
			
			var cycle_bt:Button = new Button({
				label: 'Cycle',
				name: 'cycle_bt',
				x: 245,
				y: 5,
				w: 75
			});
			
			cycle_bt.addEventListener(MouseEvent.CLICK, function():void {
				try {
					ava_swf = (model.flashVarModel.use_default_ava) ? AvatarSSManager.ava_swf : model.worldModel.pc.ac.acr.ava_swf;
				} catch(err:Error) {
					// this can happen if we're loading sheet pngs
				}
				var anims:Array = AvatarAnimationDefinitions.getSheetedAnimsA();
				
				AvatarSSManager.playSSViewSequenceForAva(model.worldModel.pc.ac, model.worldModel.pc.sheet_url, ss_view, ss_view.gotoAndPlaySequence, anims);
				
			});
			ss_sp.addChild(cycle_bt);
			
			var bt:Button;
			for each (var sheet:String in AvatarAnimationDefinitions.sheetsA) {
				bt = new Button({
					label: sheet,
					name: sheet,
					x: 5,
					y: 5 + ((bt) ? bt.y+bt.h : 30)
				});
				
				
				bt.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					makeSheetBitmap(e.target.name);
				});
				ss_sp.addChild(bt);
			}
			
			ss = AvatarSSManager.getSSForAva(pc.ac, pc.sheet_url, onAvaAssetsRdy) as SSMultiBitmapSheet;
			ss_view = ss.getViewSprite();
			positionAvatar();
		}
		
		private function makeSheetBitmap(sheet:String):void {
			// remove the last bm we showed
			if (full_bm && full_bm.parent) full_bm.parent.removeChild(full_bm);
			
			try {
				var full_bmd:BitmapData = AvatarSSManager.makeSheetBitmap(ss, sheet);
			} catch (err:Error) {
				CONFIG::debugging {
					Console.warn(err);
				}
				
				model.activityModel.growl_message = err.toString();
				model.activityModel.growl_message = 'Failed to create sheet. Did you hit the cycle button first?';
				return;
			}
			
			// add the bm to the stage
			full_bm = new Bitmap(full_bmd);
			full_bm.smoothing = true;
			full_bm.width = Math.min(full_bm.width, stage.stageWidth);
			full_bm.scaleY = full_bm.scaleX;
			full_bm.x = full_bm.y = 0;
			TSFrontController.instance.addUnderCursor(full_bm);
			
			// prompt for save to desktop
			var who:String = (model.flashVarModel.use_default_ava) ? 'default' : model.worldModel.pc.tsid;
			var file_name:String;
			var url:String;
			
			if (model.flashVarModel.use_default_ava) {
				url = model.flashVarModel.placeholder_sheet_url;
			} else {
				url = model.worldModel.pc.sheet_url;
			}
			url = url.replace('http://', '');
			url = url.replace(/\//g, '_');
			url = url.replace(/\./g, '_');
			
			who+= '_'+url;
			
			file_name = who+'_scale';
			file_name+= (EnvironmentUtil.getUrlArgValue('SWF_ava_scale')) ? EnvironmentUtil.getUrlArgValue('SWF_ava_scale') : '1';
			file_name+= '__'+sheet+'.png';
			
			var img:BitmapSnapshot = new BitmapSnapshot(null, file_name, 0, 0, full_bmd);
			img.saveToDesktop();
		}

		// this only gets called when the initial call to AvatarSSManager.getSSForAva returned the default ss
		// because the assets were not yet fully loaded, and &SWF_use_default_ava != 1
		private function onAvaAssetsRdy(ac:AvatarConfig):void {
			var pc:PC = model.worldModel.pc;
			AvatarSSManager.removeSSViewforDefaultSS(ss_view);
			ss_view.dispose();
			ss = AvatarSSManager.getSSForAva(pc.ac, pc.sheet_url) as SSMultiBitmapSheet;
			ss_view = ss.getViewSprite();
			
			positionAvatar();
		}
		
		private function positionAvatar():void {
			// pots a registration dot in thethe bottom left of the swf
			//ava_swf.graphics.lineStyle(0, 0, 0);
			//ava_swf.graphics.beginFill(0, 1);
			//ava_swf.graphics.drawRect(0, 127-2, 2, 2)l 127 is the height of the avatar2011swf stage
			AvatarSSManager.playSSViewForAva(model.worldModel.pc.ac, model.worldModel.pc.sheet_url, ss_view, ss_view.gotoAndStop, 1, 'hit1');
			ss_sp.addChild(ss_view);
			ss_view.x = 150;
			ss_view.y = 100;
		}
		
		//-------------------------------------------------------------------------------------
		//-------------------------------------------------------------------------------------
		//-------------------------------------------------------------------------------------
		//-------------------------------------------------------------------------------------
		
		private function constructToolsStuff():void {
			tools_sp = new Sprite();
			content_sp.addChild(tools_sp);
			
			var FPSchanger:Sprite = new Sprite();
			var slider:HSlider = new HSlider(FPSchanger, 10, 10, function(e:Event):void {
				var slider:HSlider = HSlider(e.currentTarget);
				StageBeacon.stage.frameRate = Math.ceil(slider.value);
				model.flashVarModel.fps = StageBeacon.stage.frameRate;
			});
			slider.height = 15;
			slider.width = 120;
			slider.minimum = 1;
			slider.maximum = 90;
			slider.value = StageBeacon.stage.frameRate;
			slider.backClick = true;
			
			tools_sp.addChild(FPSchanger);
			tools_sp.addChild(_form);
			
			_form.y = slider.y+25;
			
			var i:int;
			
			//show the option to toggle the benchmark window right away
			var cb:Checkbox = new Checkbox({
				x: 5,
				y: 0,
				checked: Benchmark.isVisible(),
				label: 'show benchmark window',
				name: 'benchmark'
			});
			cb.addEventListener(TSEvent.CHANGED, onBenchmarkClick, false, 0, true);
			_form.addChild(cb);
			
			var k:String;
			
			var allowed_pri:String = model.flashVarModel.priority;
			var A:Array = allowed_pri.split(',');
			
			var pri_mapA:Array = [];
			for (k in TSEngineConstants.pri_map) pri_mapA.push({key:k, label:TSEngineConstants.pri_map[k]});
			pri_mapA.sortOn('label', [Array.CASEINSENSITIVE]);
			
			for (i=0;i<pri_mapA.length; i++) {
				k = pri_mapA[int(i)].key;
				cb = new Checkbox({
					x: 5,
					y: (cb) ? cb.y+20 : 0,
					checked: (A.indexOf(k) > -1),
					label: TSEngineConstants.pri_map[k]+' ('+k+')',
					name: TSEngineConstants.pri_map[k]
				});
				
				_form.addChild(cb);
			}
			
			var bool_arg_mapA:Array = [];
			for (k in TSEngineConstants.bool_arg_map) bool_arg_mapA.push({key:k, label:TSEngineConstants.bool_arg_map[k]});
			bool_arg_mapA.sortOn('label', [Array.CASEINSENSITIVE]);
			
			for (i=0;i<bool_arg_mapA.length; i++) {
				k = bool_arg_mapA[int(i)].key;
				cb = new Checkbox({
					x: 5,
					y: (cb) ? cb.y+20+(i==0?10:0) : 0,
					checked: (model.flashVarModel.get(k, 'String') == '1'),
					label: TSEngineConstants.bool_arg_map[k],
					name: k
				});
				
				_form.addChild(cb);
			}
			
			var reload_bt:Button = new Button({
				label: 'reload',
				name: 'reload',
				x: 5,
				y: (cb) ? cb.y+20 : 0,
				w: 90
			});
			
			reload_bt.addEventListener(MouseEvent.CLICK, _reloadNewUrl);
			
			_form.addChild(reload_bt);
			
			CONFIG::debugging {
				cb = new Checkbox({
					x: 5,
					y: reload_bt.y+30,
					checked: false,
					label: 'pause logging',
					name: 'pl'
				});
				
				cb.addEventListener(TSEvent.CHANGED, _toggleLogging);
				_form.addChild(cb);
			}
		}
		
		private function constructItemsStuff():void {
			items_sp = new Sprite();
			items_sp.graphics.clear();
			items_sp.graphics.beginFill(0xf0f0f0, 0);
			items_sp.graphics.drawRect(0, 0, 200, 120);
			content_sp.addChild(items_sp);
			
			var drag_panel:Sprite = new Sprite();
			drag_panel.y = 10;
			
			//handle quoins
			var quoin_icon_wh:int = 50; // this is the size of quoins
			var quoin_types:Array = ['quoin_xp', 'quoin_mood', 'quoin_energy', 'quoin_currants', 'quoin_mystery', 'quoin_favor', 'quoin_time'];
			var quoin:Sprite;
			
			for(var i:int = 0; i < quoin_types.length; i++){
				quoin = new Sprite();
				
				quoin.name = quoin_types[int(i)];
				quoin.x = quoin_icon_wh * i;
				quoin.addChild(new ItemIconView('quoin', quoin_icon_wh, String(i+1)));
				drag_panel.addChild(quoin);
				
				TipDisplayManager.instance.registerTipTrigger(quoin);
			}			
			
			var item_icon_wh:int = 57; // this is the size of icons
			
			var A:Array = [
				'spawner', 'npc_chicken', 'npc_piggy', 'npc_butterfly',
				'patch', 'patch_dark', '',
				'trant_bean', 'trant_egg', 'trant_gas',
				'trant_bubble', 'trant_spice', 'trant_fruit',
				'rock_beryl_1', 'rock_beryl_2', 'rock_beryl_3',
				'rock_dullite_1', 'rock_dullite_2', 'rock_dullite_3',
				'rock_sparkly_1', 'rock_sparkly_2', 'rock_sparkly_3',
				'rock_metal_1', 'rock_metal_2', 'rock_metal_3',
				'peat_1', 'peat_2', 'peat_3', 'mortar_barnacle', 'jellisac',
				'street_spirit_groddle', 'street_spirit_zutto', 'street_spirit_firebog',
				'broken_sign'
			];
			
			var cols:int = 6;
			var col:int;
			var row:int;
			
			var sp:Sprite;
			var s:*;
			var item:Item;
			for (i=0;i<A.length; i++) {
				col = (i % cols);
				row = Math.floor(i / cols);
				if (A[int(i)] == '') continue;
				item = model.worldModel.getItemByTsid(A[int(i)]);
				s = '1';
				sp = new Sprite();
				sp.name = A[int(i)];
				sp.x = item_icon_wh*col;
				sp.y = (item_icon_wh*row)+item_icon_wh;
				sp.addChild(new ItemIconView(A[int(i)], item_icon_wh, s));
				drag_panel.addChild(sp);
				TipDisplayManager.instance.registerTipTrigger(sp);
			}
			
			drag_panel.graphics.clear();
			drag_panel.graphics.beginFill(0xf0f0f0, 0);
			drag_panel.graphics.drawRect(0, 0, 200, item_icon_wh*(row+1));
			
			items_sp.addChild(drag_panel);
			drag_panel.addEventListener(MouseEvent.MOUSE_DOWN, _dragPanelMouseDownHandler);
			drag_panel.addEventListener(MouseEvent.CLICK, _dragPanelClickHandler);
			
			A = model.worldModel.getSortedItems();
			var bt:Button;
			
			for (i=0;i<A.length; i++) {
				if (A[int(i)].tags && A[int(i)].tags.indexOf('deleted') != -1) continue;
				bt = new Button({
					//graphic: new ItemIcon(A[int(i)].tsid, 23, '1'),
					graphic_placement: 'left',
					label: A[int(i)].label+'\r('+A[int(i)].tsid+')',
					name: A[int(i)].tsid,
					value: A[int(i)].tsid,
					x: 5,
					y: (bt) ? bt.y+bt.height+1 : drag_panel.y+drag_panel.height+10,
					w: 180,
					h: 43,
					c: 0xffffff,
					high_c: 0xcecece,
					shad_c: 0xcecece,
					inner_shad_c: 0x69bcea,
					label_size: 10
				});
				items_sp.addChild(bt);
				bt.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					var item:Item = model.worldModel.getItemByTsid(e.target.value);
					if (false && item.is_hidden) {
						
						TSFrontController.instance.genericSend(
							new NetOutgoingItemstackCreateVO(item.tsid, model.worldModel.pc.x, model.worldModel.pc.y)
						);
						
						model.activityModel.growl_message = 'Hidden items must be placed at your feet.';
						
					} else if (KeyBeacon.instance.pressed(Keyboard.F)) {
						_placeItemAtFeet(e.target.value);
					} else {
						startStampDraggingItem(e.target.value, 0, '1');
					}
				});
			}
			
			A = AssetManager.instance.assets.soundsA;
			for (i=0;i<A.length;i++) {
				bt = new Button({
					label: 'sound: '+A[int(i)],
					name: A[int(i)],
					value: A[int(i)],
					x: 5,
					y: (bt) ? bt.y+bt.height+1 : 36,
					w: 180,
					/*c: 0xffffff,
					high_c: 0xffffff,
					shad_c: 0xcecece,*/
					inner_shad_c: 0x69bcea,
					label_size: 10
				});
				items_sp.addChild(bt);
				bt.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					//Console.warn(e.target.value);
					SoundMaster.instance.playSound(e.target.value, 0);
				});
			}
		}
		
		private function constructDebugStuff():void {
			debug_sp = new Sprite();
			content_sp.addChild(debug_sp);
			
			var clear_bt:Button = new Button({
				label: 'Clear Console',
				name: 'clear_bt',
				x: 5,
				y: 5,
				w: 100
			});
			
			clear_bt.addEventListener(MouseEvent.CLICK, function():void {
				GeneralValueTracker.instance.removeAll();
			});
			debug_sp.addChild(clear_bt);
			
			var flush_so_bt:Button = new Button({
				label: 'Flush SO',
				name: 'flush_so_bt',
				x: clear_bt.x+clear_bt.w+5,
				y: 5,
				w: 70
			});
			
			flush_so_bt.addEventListener(MouseEvent.CLICK, function():void {
				LocalStorage.instance.flushIt(0, 'flush_so_bt');
			});
			debug_sp.addChild(flush_so_bt);

			var tf_debug:TextField = new TextField();
			tf_debug.defaultTextFormat = new TextFormat('Arial');
			tf_debug.x = clear_bt.x;
			tf_debug.y = clear_bt.y + clear_bt.height + 5;
			tf_debug.autoSize = TextFieldAutoSize.LEFT;
			tf_debug.multiline = true;
			debug_sp.addChild(tf_debug);
			
			//let the debug class know about the text field
			GeneralValueTracker.instance.value_tf = tf_debug;
		}
		
		CONFIG::debugging private function _toggleLogging(e:TSEvent):void {
			if (e.data.checked) {
				Console.pause();
			} else {
				Console.resume();
			}
		}
		
		private function onBenchmarkClick(event:TSEvent):void {
			Benchmark.display(event.data.checked);
		}
		
		private function _reloadNewUrl(e:MouseEvent):void {
			var stuff:Object = EnvironmentUtil.getURLAndQSArgs();
			
			var url:String = stuff.url+'?';
			var k:String;
			
			// first build the QS from what exists already in the url, except those that we set with cb options
			for (k in stuff.args) {
				if (TSEngineConstants.bool_arg_map[k]) continue;
				if (k == 'pri') continue;
				
				url+= k+'='+stuff.args[k]+'&';
			}
			
			// now go through and and params from the bool cbs;
			for (k in TSEngineConstants.bool_arg_map) {
				var value:String;
				
				if (Checkbox(_form.getChildByName(k)).checked) {
					value = '1';
				} else {
					continue;
				}
				
				url+= k+'='+value+'&';
			}
			
			// now add in the logging pri
			var priA:Array = [];
			for (k in TSEngineConstants.pri_map) {
				if (Checkbox(_form.getChildByName(TSEngineConstants.pri_map[k])).checked) priA.push(k);
			}
			if (priA.length) url+= 'pri='+priA.join(',')+'&';
			
			navigateToURL(new URLRequest(url), '_self');
		}
		
		// used by _startStampDraggingItem and _startNormalDraggingItem
		private function _startDraggingItem(item_class:String = 'orange', wh:int = 400, s:* = '1'):void {
			//Console.warn('_startDraggingItem '+item_class+' '+wh+' '+s);
			
			while (_item_drag_sp.numChildren) _item_drag_sp.removeChildAt(0);
			var item_icon:ItemIconView = new ItemIconView(item_class, wh, s, 'center_bottom');
			
			_item_drag_sp.x = StageBeacon.stage.mouseX;
			_item_drag_sp.y = StageBeacon.stage.mouseY;
			_item_drag_sp.addChild(item_icon);
			_item_drag_sp.startDrag();
			
			TSFrontController.instance.addUnderCursor(_item_drag_sp);
		}
		
		public function startStampDraggingItem(item_class:String = 'orange', wh:int = 400, s:* = '1'):void {
			model.stateModel.is_stamping_itemstacks = true;
			
			_startDraggingItem(item_class, wh, s);
			
			// low priority so HoG and TSMV.superSearch get the escape event first
			// so they both decide to not close until we're done stamping
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, _stampDraggingEscapeKeyHandler, false, -1);
			_item_drag_sp.addEventListener(MouseEvent.CLICK, _stampDraggingClickHandler);
			model.activityModel.growl_message = 'Hit the ESCAPE key to stop stamping items.';
		}
		
		public function startNormalDraggingItem(item_class:String = 'orange', wh:int = 400, s:* = '1'):void {
			_startDraggingItem(item_class, wh, s);
			StageBeacon.mouse_up_sig.add(_normalDraggingMouseUpHandler);
		}
		
		private function _stopDraggingItem():void {
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, _stampDraggingEscapeKeyHandler);
			_item_drag_sp.removeEventListener(MouseEvent.CLICK, _stampDraggingClickHandler);
			StageBeacon.mouse_up_sig.remove(_normalDraggingMouseUpHandler);
			_item_drag_sp.stopDrag();
			if (_item_drag_sp.parent) _item_drag_sp.parent.removeChild(_item_drag_sp);
		}
		
		private function _stampDraggingEscapeKeyHandler(e:Event):void {
			model.stateModel.is_stamping_itemstacks = false;
			_stopDraggingItem();
		}
		
		private function _stampDraggingClickHandler(e:Event):void {
			_placeDraggedItem();
		}
		
		private function _normalDraggingMouseUpHandler(e:Event):void {
			_stopDraggingItem();
			_placeDraggedItem();
		}
		
		private function _placeItemAtFeet(tsid:String):void {
			TSFrontController.instance.genericSend(
				new NetOutgoingItemstackCreateVO(tsid, model.worldModel.pc.x, model.worldModel.pc.y)
			);
		}
		
		private function _placeDraggedItem():void {
			if (_item_drag_sp.numChildren == 0) return;
			if (!(_item_drag_sp.getChildAt(0) is ItemIconView)) return;
			var item_icon:ItemIconView = ItemIconView(_item_drag_sp.getChildAt(0));
			
			var pt:Point = TSFrontController.instance.getMainView().gameRenderer.getMouseXYinMiddleground();
			var place_pt:Point;
			var good:Boolean = TSFrontController.instance.getMainView().gameRenderer.isPtInVisibleArea(pt);
			
			//Console.warn(pt+' '+good)
			
			if (good) {
				var item_ob:Item = model.worldModel.getItemByTsid(item_icon.tsid);
				
				if (item_ob.obey_physics) {
					// this checks pc perms, not item perms, but is good enough for now.
					//rect:Rectangle, ob:Object = null, find_soft_ceils:Boolean = false
					//var ob:Object = EngineProxy.instance.engine.hubDisplayManager.findClosePlatformsAndWallsToRect(new Rectangle(pt.x-20, pt.y, 40, 1), null, true);
					
					//var pwSet:PlatformWallSet = PlatformWallColisionDetector.findClosePlatformsAndWallsToRect(null, model.worldModel.location, new Rectangle(pt.x-20, pt.y, 40, 1), true);
					//Console.dir(pwSet);
					//if (pwSet.platform_floor) {
					//	place_pt = new Point(pt.x, pwSet.platform_floor.y);
					//	model.activityModel.growl_message = 'Placing on platform below drop point.';
					//} else if (pwSet.platform_ceil) {
					//	place_pt = new Point(pt.x, pwSet.platform_ceil.y);
					//	model.activityModel.growl_message = 'Placing on platform above drop point.';
					//} else {
					place_pt = new Point(model.worldModel.pc.x, model.worldModel.pc.y);
					model.activityModel.growl_message = 'Item obeys physics, so must be on platform, but could not find a platform below or above, so put it next to you.';
					//}
				} else {
					place_pt = pt;
				}
				var props:*;
				
				if (item_icon.tsid == 'quoin') {
					var map:Object = {
						'1': 'xp',
						'2': 'mood',
						'3': 'energy',
						'4': 'currants',
						'5': 'mystery',
						'6': 'favor',
						'7': 'time'
					};
					props = {
						type: map[item_icon.s]
					};
				}
				
				TSFrontController.instance.genericSend(
					new NetOutgoingItemstackCreateVO(item_icon.tsid, place_pt.x, place_pt.y, props)
				);
			}
			
		}
		
		private function _dragPanelMouseDownHandler(e:MouseEvent):void {
			if (KeyBeacon.instance.pressed(Keyboard.CONTROL)) return;
			var element:* = e.target;
			//Console.warn(getQualifiedClassName(element)+' '+element.name);
			
			if (element is ItemIconView) {
				startNormalDraggingItem(element.tsid, 0, element.s);
			}
		}
		
		private function _dragPanelClickHandler(e:MouseEvent):void {
			if (!KeyBeacon.instance.pressed(Keyboard.CONTROL) && !KeyBeacon.instance.pressed(Keyboard.ALTERNATE)) return;
			var element:* = e.target;
			//Console.warn(getQualifiedClassName(element)+' '+element.name);
			
			if (element is ItemIconView) {
				startStampDraggingItem(element.tsid, 0, element.s);
			}
		}
		
		private function showCorrectSection():void {
			if (rook_sp) {
				rook_sp.visible = false;
				rook_sp.scaleY = 0;
			}
			if (physics_sp) {
				physics_sp.visible = false;
				physics_sp.scaleY = 0;
			}
			if (tools_sp) {
				tools_sp.visible = false;
				tools_sp.scaleY = 0;
			}
			if (ss_sp) {
				ss_sp.visible = false;
				ss_sp.scaleY = 0;
			}
			if (items_sp) {
				items_sp.visible = false;
				items_sp.scaleY = 0;
			}
			if (debug_sp) {
				debug_sp.visible = false;
				debug_sp.scaleY = 0;
			}
			
			LocalStorage.instance.setUserData(LocalStorage.ADMIN_DIALOG_SECTION, current_section);
			
			switch(current_section){
				case 'items':
					if (!items_sp) constructItemsStuff();
					items_sp.visible = true;
					items_sp.scaleY = 1;
					GeneralValueTracker.instance.shown = false;
					PhysicsValueTracker.instance.shown = false;
					RookValueTracker.instance.shown = false;
					break;
				case 'tools':
					if (!tools_sp) constructToolsStuff();
					tools_sp.visible = true;
					tools_sp.scaleY = 1;
					GeneralValueTracker.instance.shown = false;
					PhysicsValueTracker.instance.shown = false;
					RookValueTracker.instance.shown = false;
					break;
				case 'ss':
					if (!ss_sp) constructSSStuff();
					ss_sp.visible = true;
					ss_sp.scaleY = 1;
					GeneralValueTracker.instance.shown = false;
					PhysicsValueTracker.instance.shown = false;
					RookValueTracker.instance.shown = false;
					break;
				case 'physics':
					if (!physics_sp) constructPhysicsStuff();
					physics_sp.visible = true;
					physics_sp.scaleY = 1;
					GeneralValueTracker.instance.shown = false;
					PhysicsValueTracker.instance.shown = true;
					RookValueTracker.instance.shown = false;
					break;
				case 'rook':
					if (!rook_sp) constructRookStuff();
					rook_sp.visible = true;
					rook_sp.scaleY = 1;
					GeneralValueTracker.instance.shown = false;
					PhysicsValueTracker.instance.shown = false;
					RookValueTracker.instance.shown = true;
					break;
				default:
					if (!debug_sp) constructDebugStuff();
					debug_sp.visible = true;
					debug_sp.scaleY = 1;
					GeneralValueTracker.instance.shown = true;
					PhysicsValueTracker.instance.shown = false;
					RookValueTracker.instance.shown = false;
					break;
			}
			
			_scroller.refreshAfterBodySizeChange(true);
		}
		
		override public function start():void {
			super.start();
			
			/* THIS DOES NOT TAKE FOCUS
			if (!TSFrontController.instance.requestFocus(this)) {
			Console.warn('could not take focus');
			return;
			}*/
			
			if (!content_sp.parent) {
				_setGraphicContents(new ItemIconView('admin_widget', 40));
				_setTitle('Admin Tools');
				_setSubtitle(
					'<a href="event:debug">Debug</a> | <a href="event:tools">Tools</a> | <a href="event:items">Items</a> | <a href="event:physics">Physics</a> | <a href="event:ss">SS</a> | <a href="event:rook">Rook</a>'
				);
				showCorrectSection();
				_setBodyContents(content_sp);
				_setFootContents(null);
				onInvalidate();
			}
			
			transitioning = true;
			_place();
			scaleX = scaleY = .02;
			x = model.layoutModel.overall_w+model.layoutModel.gutter_w-30;
			y = 20;
			var self:AdminDialog = this;
			TSTweener.removeTweens(self);
			TSTweener.addTween(self, {y:dest_y, x:dest_x, scaleX:1, scaleY:1, time:.3, transition:'easeInCubic', onComplete:function():void{
				self.transitioning = false;
				self._place();
			}});
			refresh();
			
			LocalStorage.instance.setUserData(LocalStorage.IS_OPEN_ADMIN_DIALOG, true, true);
		}
				
		override protected function _place():void {
			
			if (last_x || last_y) {
				dest_x = last_x;
				dest_y = last_y;
			} else {
				dest_x = StageBeacon.stage.stageWidth-_w-10;//model.layoutModel.gutter_w + Math.round((model.layoutModel.loc_vp_w-_w)/2);
				dest_x = Math.max(dest_x, 0);
				dest_y = model.layoutModel.header_h;
				dest_y = Math.max(dest_y, 0);
			}
			
			if (!transitioning) {
				x = dest_x;
				y = dest_y;
			}
		}
			
		override public function end(release:Boolean):void {
			if (release && !transitioning) {
				transitioning = true;
				var self:AdminDialog = this;
				TSTweener.removeTweens(self);
				TSTweener.addTween(self, {y:20, x:model.layoutModel.overall_w+model.layoutModel.gutter_w-30, scaleX:.02, scaleY:.02, time:.3, transition:'easeOutCubic', onComplete:function():void{
					self.end(true);
					self.scaleX = self.scaleY = 1;
					self.transitioning = false;
				}});
			} else {
				super.end(release);
			}
			LocalStorage.instance.setUserData(LocalStorage.IS_OPEN_ADMIN_DIALOG, false, true);
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target) return null;
			
			var txt:String = '';
			
			if(current_section == 'items' && items_sp){
				//get a tool tip for the thing you're mousing over
				var item:Item = model.worldModel.getItemByTsid(tip_target.name);
				if(item){
					txt = item.label;
				}
				//not an item, just use the name instead
				else {
					txt = tip_target.name;
				}
			}
			
			return {
				txt: txt,
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			};
		}
	}
}