package com.tinyspeck.engine.port
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.net.NetOutgoingSetPrefsVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Checkbox;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;

	public class PrefsDialog extends BigDialog implements IFocusableComponent {
		
		private const CLOSED_SCALE:Number = .02;
		
		private var foot_sp:Sprite;
		private var body_sp:Sprite;
		private var cbs_sp:Sprite;
		private var _is_open:Boolean;
		private var submit_bt:Button;
		private var prefs_when_opened:Object;
		private var pref_changed:Boolean;
		
		/* singleton boilerplate */
		public static const instance:PrefsDialog = new PrefsDialog();
		
		public function PrefsDialog() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			_body_min_h = 200;
			_w = 450;
			_draggable = true;
			_construct();
		}
		
		override public function start():void {
			if (parent) return;
			if (!canStart(true)) return;
			if (is_open) return;
			var g:Graphics;
			
			if (!body_sp) {
				
				body_sp = new Sprite();
				
				cbs_sp = new Sprite();
				cbs_sp.x = 20;
				cbs_sp.y = 20;
				body_sp.addChild(cbs_sp);
				
				_setGraphicContents(new ItemIconView('pet_rock', 40, 'idle'));
				_setTitle('Preferences');
				_setSubtitle('You can customize a few things about the game.');
				
				foot_sp = new Sprite();
				submit_bt = new Button({
					label: 'Save',
					name: 'submit_bt',
					value: 'submit',
					y: 8,
					size: Button.SIZE_DEFAULT,
					type: Button.TYPE_DEFAULT
				})
				
				submit_bt.addEventListener(MouseEvent.CLICK, onSubmitClick, false, 0, true);
				
				foot_sp.addChild(submit_bt);
				
				submit_bt.x = _w-submit_bt.width-15;
				
				g = foot_sp.graphics;
				g.beginFill(0,0);
				g.drawRect(0,0,20,56); // force height correctly for foot
				_setFootContents(foot_sp);
				
			}
			
			pref_changed = false;
			prefs_when_opened = model.prefsModel.getAnonymous();
			
			SpriteUtil.clean(cbs_sp);
			
			var pref_namesA:Array = model.prefsModel.pref_namesA;
			var god_only_pref_namesA:Array = model.prefsModel.god_only_pref_namesA;
			
			for (var i:int=0;i<pref_namesA.length;i++) {
				var pref_name:String = pref_namesA[i];
				var pref_desc:String = model.prefsModel.getDescForPref(pref_name);
				
				if (god_only_pref_namesA.indexOf(pref_name) > -1) {
					if (CONFIG::god) {
						pref_desc = 'A: '+pref_desc;
					} else {
						continue;
					}
				}
				
				var cb:Checkbox;
				var pref_value:* = model.prefsModel[pref_name];
				var padd:int = 12;
				
				cb = new Checkbox({
					graphic: new AssetManager.instance.assets.cb_unchecked(),
					graphic_checked: new AssetManager.instance.assets.cb_checked(),
					x: padd,
					y: (cb) ? cb.y+cb.height+padd : 0,
					w:18,
					h:18,
					checked: pref_value,
					label: pref_desc,
					name: pref_name,
					label_w: _w-80
				})
				cb.addEventListener(TSEvent.CHANGED, onCbChange, false, 0, true);
				
				cbs_sp.addChild(cb);
			}
			
			g = body_sp.graphics;
			g.beginFill(0,0);
			g.drawRect(0,0,20,cbs_sp.height+(cbs_sp.y*2));
			
			CONFIG::debugging {
				Console.warn(body_sp.height)
			}
			_setBodyContents(body_sp);
			
			super.start();
			
			//animate it open
			tweenOpenClose(true);
		}
		
		private function tweenOpenClose(open:Boolean):void {
			_is_open = open;
			transitioning = true;
			const start_pt:Point = getAnimationStartPoint();
			const final_scale:Number = open ? 1 : CLOSED_SCALE;
			const final_pt:Point = open ? new Point(dest_x, dest_y) : start_pt;
			const transition:String = open ? 'easeInCubic' : 'easeOutCubic';
			
			//set the starting stuff
			if(open) {
				scaleX = scaleY = CLOSED_SCALE;
				x = start_pt.x;
				y = start_pt.y;
			}
			
			TSTweener.removeTweens(this);
			TSTweener.addTween(this, {
				x:final_pt.x, 
				y:final_pt.y, 
				scaleX:final_scale, 
				scaleY:final_scale, 
				time:.3, 
				transition:transition, 
				onComplete:onTweenComplete, 
				onCompleteParams:[open]
			});
			
		}
		
		private function onTweenComplete(open:Boolean):void {
			transitioning = false;
			if(open){
				_scroller.refreshAfterBodySizeChange();
				_place();
			}
			else {
				super.end(true);
				scaleX = scaleY = 1;
			}
		}
		
		private function getAnimationStartPoint():Point {
			//return new Point(model.layoutModel.gutter_w+50, 60);
			return YouDisplayManager.instance.getMoodGaugeCenterPt();
		}
		
		private function resetPrefs():void {
			if (prefs_when_opened) {
				model.prefsModel.updateFromAnonymous(prefs_when_opened);
			}
		}
		
		private function setPrefsFromCbs():void {
			var cb:Checkbox;
			for (var i:int=0;i<cbs_sp.numChildren;i++) {
				cb = cbs_sp.getChildAt(i) as Checkbox;
				if (!cb) return;
				model.prefsModel[cb.name] = cb.checked;
			}
		}
		
		private function saveAndClose():void {
			setPrefsFromCbs();
			TSFrontController.instance.genericSend(new NetOutgoingSetPrefsVO(model.prefsModel.getAnonymous()), onSaved, onNotSaved);
			end(true);
		}
		
		private function onSubmitClick(event:MouseEvent):void {
			saveAndClose()
		}
		
		private function onCbChange(event:TSEvent):void {
			pref_changed = true;
			setPrefsFromCbs();
		}
		
		override protected function closeFromUserInput(e:Event=null):void {
			if (_close_bt.disabled) return;
			end(true);
			StageBeacon.stage.focus = StageBeacon.stage;
			if (pref_changed) {
				resetPrefs();
				showMessage('Preferences not saved');
			}
		}
		
		override protected function startListeningToNavKeys():void {
			super.startListeningToNavKeys();
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.COMMA, commaKeyHandler);
		}
		
		override protected function stopListeningToNavKeys():void {
			super.stopListeningToNavKeys();
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.COMMA, commaKeyHandler);
		}
		
		private function commaKeyHandler(e:KeyboardEvent):void {
			closeFromUserInput();
		}
		
		override protected function enterKeyHandler(e:KeyboardEvent):void {
			saveAndClose();
		}
		
		private function onSaved(nrm:NetResponseMessageVO):void {
			showMessage('Preferences saved');
		}
		
		private function onNotSaved(nrm:NetResponseMessageVO):void {
			showMessage('Preferences not saved');
		}
		
		private function showMessage(msg:String):void {
			model.activityModel.announcements = Announcement.parseMultiple([{
				type: "vp_overlay",
				dismissible: false,
				text: ['<p align="center"><span class="nuxp_big">'+msg+'</span></p>'],
				x: '50%',
				y: '50%',
				width: 350,
				uid: 'prefs_saved',
				bubble_god: true,
				duration: 2000
			}]);
		}
		
		override public function end(release:Boolean):void {
			if (!parent) return;
			//animate it close (onComplete fires the super call to end())
			tweenOpenClose(false);
		}
		
		public function get is_open():Boolean { return _is_open; }
	}
}