package com.tinyspeck.engine.view.geo
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.memory.IDisposable;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.location.AbstractPositionableLocationEntity;
	import com.tinyspeck.engine.data.location.LocationConnection;
	import com.tinyspeck.engine.data.location.QuarterInfo;
	import com.tinyspeck.engine.data.location.SignPost;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.MoveModel;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.SignpostDialog;
	import com.tinyspeck.engine.port.TSSpriteWithModel;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.renderer.DecoAssetManager;
	import com.tinyspeck.engine.view.renderer.DecoRenderer;
	import com.tinyspeck.engine.view.renderer.IAbstractDecoRenderer;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	
	import org.osflash.signals.Signal;
	
	public class SignpostView extends TSSpriteWithModel implements IFocusableComponent, IAbstractDecoRenderer, IDisposable {
		public const renderCompleted_sig:Signal = new Signal(SignpostView);
		public const holder:Sprite = new Sprite();
		public const deco_holder:Sprite = new Sprite();
		
		private var _loc_tsid:String;
		
		private var _signpost:SignPost;
		private var _edit_clicked:Boolean;
		
		private var _renderCompleted:Boolean = false;
		private var _deco_renderer:DecoRenderer;
		private var shadow:DisplayObject;
		private var post:DisplayObject;
		private var has_focus:Boolean = false;
		private var signs:Vector.<SignpostSignView> = new Vector.<SignpostSignView>();
		private var selected_index:int = -1;
		private var _decoAsset:MovieClip;
		private var _edit_bt:Button;
		private var _number:String;
		
		public function SignpostView(signpost:SignPost, loc_tsid:String):void {
			super(signpost.tsid);
			_signpost = signpost;
			_loc_tsid = loc_tsid;
			
			registerSelfAsFocusableComponent();
			_construct();
			cacheAsBitmap = true;
			deco_holder.name = 'deco_holder';
			deco_holder.mouseEnabled = false;
			deco_holder.mouseChildren = false;
		}
		
		override public function get disambugate_sort_on():int {
			return 80;
		}
		
		override protected function _addedToStageHandler(e:Event):void {
			super._addedToStageHandler(e);
			
			render();
			
			holder.scaleX = holder.scaleY = .8;
			holder.addEventListener(MouseEvent.MOUSE_OVER, overHandler);
			holder.addEventListener(MouseEvent.MOUSE_OUT, outHandler);
		}
		
		public function getSignThatLinksToLocTsid(loc_tsid:String):SignpostSignView {
			for (var i:int;i<signs.length;i++) {
				if (_signpost.connects[int(i)].street_tsid == loc_tsid) return signs[int(i)];
			}
			return null;
		}
		
		private function showNumber(number:String):void {
			CONFIG::debugging var str:String = 'number:' +number+' decoAsset:'+_decoAsset;
			if (_decoAsset && _decoAsset.showNumber && _decoAsset.loaderInfo) {
				CONFIG::debugging {
					Console.log(451, 'setting # for '+str);
				}
				_number = number;
				_decoAsset.showNumber(_number);
			} else {
				; // satisfy compiler
				CONFIG::debugging {
					Console.log(451, 'NOT setting # for '+str);
				}
			}
		}
		
		override public function get interaction_target():DisplayObject {
			return (_decoAsset && _decoAsset.interaction_target) ? DisplayObject(_decoAsset.interaction_target) : DisplayObject(this);
		}
		
		private function onDecoAssetLoad(mc:MovieClip, class_name:String, swfWidth:Number, swfHeight:Number):void {
			_decoAsset = mc;
			render();
			TSFrontController.instance.resnapMiniMap();
		}
				
		private function onEditClick(event:TSEvent = null):void {
			TSFrontController.instance.releaseFocus(this);
			_edit_clicked = true;
			SignpostDialog.instance.startWithSignpostID(_signpost.tsid);
		}
		
		public function render():void {
			x = _signpost.x;
			y = _signpost.y;
			
			rotation = _signpost.r;
			
			var visible_connects:Vector.<LocationConnection> = _signpost.getVisibleConnects();
			
			if (_signpost.hidden || _signpost.invisible || (visible_connects.length == 0 && !CONFIG::god && !model.worldModel.location.is_home)) {
				// this keeps it hidden
				if (holder.parent) holder.parent.removeChild(holder);
				if (deco_holder.parent) deco_holder.parent.removeChild(deco_holder);
				
				_renderCompleted = true;
				renderCompleted_sig.dispatch(this);
				return;
			}
			
			addChild(holder);
			addChild(deco_holder);
			
			// in case this is a rerender
			signs.length = 0;
			SpriteUtil.clean(holder);
			SpriteUtil.clean(deco_holder);
			
			var ssv:SignpostSignView;
			
			// check for quarter_info and a deco, and if all good, use deco_holder to show the deco and bail on the rest, which is all about normal signposts
			var info:QuarterInfo = _signpost.client::quarter_info;
			if (info && _signpost.deco) {
				if (!_decoAsset) _decoAsset = DecoAssetManager.getInstance(_signpost.deco);
				
				if (_decoAsset) {
					_deco_renderer = new DecoRenderer();
					_deco_renderer.init(_signpost.deco, _decoAsset);
					deco_holder.addChild(_deco_renderer);
					if (info.style == 'apartment') {
						showNumber(String(info.row) == '0' ? 'L' : String(info.row));
					}
					_renderCompleted = true;
					renderCompleted_sig.dispatch(this);
					return;
				} else if (DecoAssetManager.loadIndividualDeco(_signpost.deco.sprite_class, onDecoAssetLoad)) {
					// we're loading the asset now!
					return;
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.warn('Deco '+_signpost.deco.sprite_class+' not found');
					}
				}
			}
			
			shadow = holder.addChild(new AssetManager.instance.assets.signpost_shadow());
			shadow.x = Math.round(-shadow.width/2);
			shadow.y = -shadow.height+9;
			
			post = holder.addChild(new AssetManager.instance.assets.signpost_post());
			post.x = Math.round(-post.width/2);
			post.y = -post.height;
			
			if (info) {
				CONFIG::debugging {
					Console.dir(info);
				}
				// here add the sign and the grid
				if (info.style == 'normal') {
					var sqa:Bitmap = new AssetManager.instance.assets.signpost_quarter_arm();
					sqa.height = 85;
					ssv = makeSign(
						'QUARTER',
						false,
						info.label,
						sqa,
						150
					);
					
					var grid:Bitmap = new AssetManager.instance.assets.signpost_quarter_grid();
					ssv.addChild(grid);
					grid.smoothing = true;
					
					// scale it to the smallest scale of the sign
					if (sqa.scaleX < sqa.scaleY) {
						grid.scaleX = grid.scaleY = sqa.scaleX;
					} else {
						grid.scaleX = grid.scaleY = sqa.scaleY;
					}
					// center it
					grid.x = sqa.x+Math.round((sqa.width-grid.width)/2);
					grid.y = sqa.y+Math.round((sqa.height-grid.height)/2);
					ssv.y = -post.height+50;
				}
				
				_renderCompleted = true;
				renderCompleted_sig.dispatch(this);
				return;
			}
			
			// add signs to post
			var visible_i:int = -1;
			var connect:LocationConnection;
			for (var i:int=0; i<_signpost.connects.length; i++) { // important! we must itrrate over all connects, not just the visible ones, because we use the index of all connects when selecting a sign
				connect = _signpost.connects[int(i)];
				if (connect.hidden) {
					if (!CONFIG::god) {
						// if not god, do not display
						continue;
					}
					
				}
				visible_i++;
				var label:String = (connect.hidden?'A/D HIDDEN: ':'')+(connect.label || 'NULL VALUE')
				ssv = makeSign(
					String(i),// we give the connects index as the name, not the visible index
					Boolean(visible_i%2),
					label,
					new AssetManager.instance.assets.signpost_arm()
				);
				ssv.alpha = (connect.hidden) ? .4 : 1;
				ssv.y = -post.height+(visible_i*25)+25;
				signs.push(ssv);
			}
			
			//add the edit button just above the base
			const pc:PC = model.worldModel ? model.worldModel.pc : null;
			if(pc && pc.home_info && _loc_tsid == pc.home_info.exterior_tsid){
				_edit_bt = new Button({
					name: 'edit',
					label: 'Edit',
					label_c: 0xffffff,
					label_size: 13,
					label_bold: true,
					label_offset: 1,
					c: 0x463626,
					focused_c: 0x634f3b,
					high_c: 0x6b5b4c,
					shad_c: 0x322618,
					w: 45
				});
				_edit_bt.x = int(-_edit_bt.width/2);
				_edit_bt.y = int(-_edit_bt.height - 35);
				_edit_bt.addEventListener(TSEvent.CHANGED, onEditClick, false, 0, true);
				_edit_bt.visible = false;
				holder.addChild(_edit_bt);
				holder.addEventListener(MouseEvent.ROLL_OVER, onHolderOver, false, 0, true);
				holder.addEventListener(MouseEvent.ROLL_OUT, onHolderOut, false, 0, true);
			}
			
			_renderCompleted = true;
			renderCompleted_sig.dispatch(this);
		}
		
		private function onHolderOver(event:MouseEvent):void {
			if(!_edit_bt) return;
			_edit_bt.visible = true;
		}
		
		private function onHolderOut(event:MouseEvent):void {
			if(!_edit_bt || has_focus) return;
			_edit_bt.visible = false;
		}
		
		public function makeSign(name:String, left_side:Boolean, label:String, arm:Bitmap, min_w:int = -9999):SignpostSignView {
			const arm_offset_x:int = 2;
			const arm_padd_x:int = 8;
			const arm_rot:Number = 5.5;
			const ssv:SignpostSignView = new SignpostSignView(this);
			ssv.name = name; // we give the connects index as the name, not the visible index
			
			// so we can get from the sign the proper connnection from the connects V
			ssv.mouseChildren = false;
			ssv.useHandCursor = true;
			holder.addChild(ssv);
			
			arm.smoothing = true;
			arm.y = Math.round(-arm.height/2);
			ssv.addChild(arm);
			
			const tf:TextField = createSignTextField(label, min_w, this.name);
			const tf_bitmap:Bitmap = textFieldToBitmap(tf);
			if(!tf_bitmap) return ssv;
			
			arm.width = Math.max(min_w, tf_bitmap.width + (2*arm_padd_x));
			
			//place it and add it to the signpost
			tf_bitmap.y = int(-tf_bitmap.height/2 - 1);
			tf_bitmap.x = int((arm.width-tf_bitmap.width)/2);
			ssv.addChild(tf_bitmap);
			
			//apply the position/rotation
			if (left_side) {
				arm.scaleX = -arm.scaleX;
				tf_bitmap.x = -tf_bitmap.x - tf_bitmap.width;
				ssv.x = -arm_offset_x;
				ssv.rotation = arm_rot;
			} else {
				ssv.x = arm_offset_x;
				ssv.rotation = -arm_rot;
			}
			
			return ssv;
		}
		
		public static function createSignTextField(label:String, min_w:int, name:String):TextField {
			//get the font size so we can apply our scale to it
			const font_size:Number = CSSManager.instance.getNumberValueFromStyle('signpost', 'fontSize', 14);
			const scale:Number = 2.8;
			
			const tf:TextField = new TextField();
			TFUtil.prepTF(tf, name == 'QUARTER');
			tf.embedFonts = false;
			tf.htmlText = '<p class="signpost"><font size="'+(font_size*scale)+'">'+StringUtil.encodeHTMLUnsafeChars(label)+'</font></span>'; 
			tf.height = tf.textHeight + 4;
			tf.filters = StaticFilters.white1pxSignpost_GlowA;
			if(name == 'QUARTER'){
				tf.width = min_w * scale;
			}
			
			return tf;
		}
		
		public static function textFieldToBitmap(tf:TextField):Bitmap {
			const scale:Number = 2.8;
			
			//make a bitmap out of the TF
			const tf_bitmap:Bitmap = TFUtil.createBitmap(tf);
			if (tf_bitmap) {
				tf_bitmap.scaleX = tf_bitmap.scaleY = 1/scale;
			}
			
			return tf_bitmap;
		}
		
		public function focusProperSign():void {			
			//var tf:TextField;
			for (var i:int=0;i<signs.length;i++) {
				//tf = signs[int(i)].getChildByName('tf') as TextField;
				//if (!tf) continue;
				if (i == selected_index) {
					signs[int(i)].filters = StaticFilters.tsSprite_GlowA;
					//tf.border = true;
				} else {
					signs[int(i)].filters = null;
					//tf.border = false;
				}
			}
			
			//handle the edit button
			if(_edit_bt && has_focus){
				_edit_bt.visible = true;
				_edit_bt.filters = selected_index < 0 || selected_index > signs.length-1 ? StaticFilters.tsSprite_GlowA : null;
			}
		}
		
		public function tryFocus():void {
			//if there are no signs and we can't edit it, just bail out
			if(!signs.length){
				TSFrontController.instance.endFamiliarDialog();
				model.stateModel.interaction_sign = null;
				
				//if we can edit, let's edit!
				if(_edit_bt) onEditClick();
				return;
			}
			
			if (!TSFrontController.instance.requestFocus(this)) {
				CONFIG::debugging {
					Console.warn('could not take focus');
				}
				return;
			}

			if (signs.length == 1 && !_edit_bt) { 
				selected_index = 0;
				focusProperSign();
				go();
			} else if (model.stateModel.interaction_sign) {
				for (var i:int=0;i<signs.length;i++) {
					if (model.stateModel.interaction_sign == signs[int(i)]) {
						selected_index = i;
						focusProperSign();
						go();
						break;
					} 
				}
			}
			
			
			TSFrontController.instance.endFamiliarDialog();
		
			model.stateModel.interaction_sign = null;
		}
		
		public function demandsFocus():Boolean {
			return false;
		}
		
		public function get stops_avatar_on_focus():Boolean {
			return true;
		}
		
		public function hasFocus():Boolean {
			return has_focus;
		}
		
		public function registerSelfAsFocusableComponent():void {
			model.stateModel.registerFocusableComponent(this as IFocusableComponent);
		}
		
		public function removeSelfAsFocusableComponent():void {
			model.stateModel.unRegisterFocusableComponent(this as IFocusableComponent);
		}
		
		public function focus():void {
			CONFIG::debugging {
				Console.log(99, 'focus');
			}
			if (!has_focus) {
				has_focus = true;
				selected_index = 0;
				filters = null;
				holder.scaleX = holder.scaleY = 1;
				focusProperSign();
				
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, escapeHandler);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, escapeHandler);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, escapeHandler);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.UP, upHandler);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DOWN, downHandler);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, enterHandler);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.S, downHandler);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.W, upHandler);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.D, escapeHandler);
				KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.A, escapeHandler);
				holder.addEventListener(MouseEvent.CLICK, clickHandler);
			}
		}
		
		public function focusChanged(focused_comp:IFocusableComponent, was_focused_comp:IFocusableComponent):void {
			
		}
		
		public function blur():void {
			CONFIG::debugging {
				Console.log(99, 'blur');
			}
			if (has_focus) {
				has_focus = false;
				if (_glowing) {
					_glowing = false; // to force it to reaply the glow
					glow();
				}
				holder.scaleX = holder.scaleY = .8;
				
				selected_index = -1;
				focusProperSign();
				
				if(_edit_bt){
					_edit_bt.visible = false;
					_edit_bt.filters = null;
				}
				
				KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, escapeHandler);
				KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.RIGHT, escapeHandler);
				KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.LEFT, escapeHandler);
				KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.UP, upHandler);
				KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.DOWN, downHandler);
				KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, enterHandler);
				KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.S, downHandler);
				KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.W, upHandler);
				KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.D, escapeHandler);
				KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.A, escapeHandler);
				holder.removeEventListener(MouseEvent.CLICK, clickHandler);
			}
		}
		
		private function overHandler(e:MouseEvent):void {
			var index:int = signs.indexOf(e.target as SignpostSignView);
			if (index == -1) return;
			selected_index = index;
			focusProperSign();
		}
		
		private function outHandler(e:MouseEvent):void {
			if (hasFocus()) return;
			var index:int = signs.indexOf(e.target as SignpostSignView);
			if (index == -1) return;
			selected_index = -1;
			focusProperSign();
		}
		
		private function clickHandler(e:MouseEvent):void {
			var index:int = signs.indexOf(e.target as SignpostSignView);
			if (index == -1) return;
			selected_index = index;
			focusProperSign();
			go();
		}
		
		private function enterHandler(e:Event):void {
			go();
		}
		
		// I think this is not actually used
		public function chooseAndGo(i:int):void {
			selected_index = i;
			goToConnectionBySelectedIndex();
		}
		
		private function goToConnectionBySelectedIndex():void {
			if (selected_index < 0 || selected_index > signs.length -1) {
				if(_edit_bt){
					//we are out of the range with the edit button there, that means we mashed it!
					onEditClick();
				}
				else {
					CONFIG::debugging {
						Console.error('out of range selected_index '+selected_index);
					}
				}
				return;
			}
			
			var connects_index:int = int(signs[selected_index].name);
			var connect:LocationConnection = _signpost.connects[connects_index];
			if (!connect) {
				CONFIG::debugging {
					Console.error('connect could not be found from selected_index '+selected_index);
				}
				return;
			}
			
			if (CONFIG::god) {
				// no need to check if hidden in this case
			} else if (connect.hidden) {
				CONFIG::debugging {
					Console.warn('connect is hidden '+selected_index);
				}
				return;
			}
			
			//Console.warn(selected_index+' '+connects_index+' '+connect.street_tsid)
			//return
			
			TSFrontController.instance.startLocationMove(
				false,
				MoveModel.SIGNPOST_MOVE,
				tsid,
				connect.street_tsid,
				connect.hashName
			);
		}
		
		private function go():void {
			goToConnectionBySelectedIndex();
			TSFrontController.instance.releaseFocus(this);
		}
		
		private function escapeHandler(e:Event):void {
			TSFrontController.instance.releaseFocus(this);
		}
		
		private function downHandler(e:Event):void {
			selected_index++;
			if (selected_index > signs.length-1 && !_edit_bt) {
				selected_index = 0;
			}
			else if(_edit_bt && selected_index > signs.length){
				selected_index = 0;
			}
			focusProperSign();
		}
		
		private function upHandler(e:Event):void {
			selected_index--;
			if (selected_index < 0 && !_edit_bt) {
				selected_index = signs.length-1;
			}
			else if(_edit_bt && selected_index < -1){
				selected_index = signs.length-1;
			}
			focusProperSign();
		}
		
		override public function glow():void {
			if (!_glowing) {
				_glowing = true;
				if (!has_focus) interaction_target.filters = StaticFilters.tsSprite_GlowA;
			}
		}
		
		override public function unglow(force:Boolean=false):void {
			if (_glowing) {
				_glowing = false;
				interaction_target.filters = null;
			} 
		}
		
		public function loadModel():void {
			render();
		}
		
		/** from IDecoRendererContainer */
		CONFIG::locodeco private var _highlight:Boolean;
		CONFIG::locodeco public function get highlight():Boolean { return _highlight; }
		CONFIG::locodeco public function set highlight(value:Boolean):void { _highlight = value; }
		
		/** from IDecoRendererContainer */
		public function syncRendererWithModel():void {
			x = _signpost.x;
			y = _signpost.y;
			rotation = _signpost.r;
		}
		
		/** from IDecoRendererContainer */
		public function getModel():AbstractPositionableLocationEntity {
			return _signpost;
		}
		
		/** from IDecoRendererContainer */
		public function getRenderer():DisplayObject {
			return this;
		}
		
		override public function dispose():void {
			cacheAsBitmap = false;
			if (_deco_renderer) _deco_renderer.dispose();
			_deco_renderer = null;
			_decoAsset = null;
			_edit_bt = null;
			super.dispose();
		}

		public function get signpost():SignPost {
			return _signpost;
		}

		public function set signpost(value:SignPost):void {
			_signpost = value;
		}

		public function get edit_clicked():Boolean {
			return _edit_clicked;
		}

		public function set edit_clicked(value:Boolean):void {
			_edit_clicked = value;
		}
	}
}

