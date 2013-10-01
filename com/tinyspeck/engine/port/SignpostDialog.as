package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.debug.Benchmark;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.location.LocationConnection;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.geo.SignpostView;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.SignpostSearch;
	import com.tinyspeck.engine.view.ui.supersearch.SuperSearchElementBuddy;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.ui.Keyboard;

	public class SignpostDialog extends BigDialog
	{
		/* singleton boilerplate */
		public static const instance:SignpostDialog = new SignpostDialog();
		
		public static const DEFAULT_TXT:String = 'Click to add a friend';
		
		private static const SIGN_COUNT:uint = 5;
		private static const SIGN_NAME:String = 'sign_';
		private static const BITMAP_NAME:String = 'bitmap_';
		private static const LABEL_DEFAULT_ALPHA:Number = .7;
		private static const HOVER_HEIGHT:uint = 41; //if the assets change for hover state, this needs to change
		
		private var done_bt:Button;
		private var cancel_bt:Button;
		private var signpost_search:SignpostSearch;
		private var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
		
		private var bg_holder:Sprite = new Sprite();
		private var signpost_holder:Sprite = new Sprite();
		private var edit_holder:Sprite = new Sprite();
		private var hover_holder:Sprite = new Sprite();
		private var hover_mask:Sprite = new Sprite();
		private var hover_DO:DisplayObject;
		
		private var instructions_tf:TextField = new TextField();
		private var hover_tf:TextField = new TextField();
		private var sign_tfs:Vector.<TextField> = new Vector.<TextField>();
		
		private var current_sign_id:int;
		private var current_signpost_tsid:String;
		
		private var is_built:Boolean;
		private var is_editing:Boolean;
		private var is_sending:Boolean;
		
		public function SignpostDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_body_border_c = 0xffffff;
			_body_fill_c = 0xffffff;
			_w = 363;
			_draggable = true;
			_base_padd = 20;
			_head_min_h = 64;
			_body_min_h = 292;
			_foot_min_h = 64;
			_construct();
		}
		
		private function buildBase():void {
			_setTitle('Edit your signpost');
			_setGraphicContents(new AssetManager.instance.assets.signpost_friends_icon());
			
			//vertical grad
			const fill_matrix:Matrix = new Matrix();
			fill_matrix.createGradientBox(_w - _border_w*2, _body_min_h, Math.PI/2, 0, 0);
			
			var g:Graphics = bg_holder.graphics;
			g.beginGradientFill(GradientType.LINEAR, [0xb5dfea, 0xdff1f6], [1,1], [0,255], fill_matrix);
			g.drawRect(0, 0, _w - _border_w*2, _body_min_h);
			
			//the top and bottom blue borders
			g.beginFill(0x92bbc6);
			g.drawRect(0, 0, _w - _border_w*2, 1);
			g.beginFill(0xb2dae4);
			g.drawRect(0, _body_min_h - 1, _w - _border_w*2, 1);
			
			//instructions
			TFUtil.prepTF(instructions_tf, false);
			instructions_tf.htmlText = '<p class="signpost_instructions">Add five of your friends to easily get to their streets</p>';
			instructions_tf.x = int(bg_holder.width/2 - instructions_tf.width/2);
			instructions_tf.y = 10;
			bg_holder.addChild(instructions_tf);
			
			//signpost base
			buildSignpost();
			
			//hover thingie
			buildEditHover();
			
			bg_holder.x = _border_w;
			bg_holder.y = _head_min_h;
			addChild(bg_holder);
			
			done_bt = new Button({
				name: 'done',
				label: "Okay, I'm done",
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			done_bt.x = int(_w - done_bt.width - _base_padd);
			done_bt.y = int(_foot_min_h/2 - done_bt.height/2);
			done_bt.addEventListener(TSEvent.CHANGED, closeFromUserInput, false, 0, true);
			_foot_sp.addChild(done_bt);
			_foot_sp.visible = true;
			
			//add a listener for when the mouse leaves the dialog, sometimes the signs get stuck if you're moving really fucking fast
			addEventListener(MouseEvent.ROLL_OUT, onEditOut, false, 0, true);
			
			//confirm
			cdVO.escape_value = false;
			cdVO.choices = [
				{value: true, label: 'Yes'},
				{value: false, label: 'No'}
			];
			cdVO.callback = onConfirmRemove;
			
			is_built = true;
		}
		
		private function buildSignpost():void {
			const signpost_friends_base:DisplayObject = new AssetManager.instance.assets.signpost_friends_base();
			signpost_friends_base.x = int(_w/2 - signpost_friends_base.width/2);
			signpost_friends_base.y = int(_body_min_h - signpost_friends_base.height - 1); //-1 is for the border
			bg_holder.addChild(signpost_friends_base);
			
			signpost_holder.y = signpost_friends_base.y + 16;
			bg_holder.addChild(signpost_holder);
			
			//hit areas for each friend, has to be custom because of nail shadows, rotations, etc.
			var next_y:int;
			var sp:Sprite;
			var tf:TextField;
			var tf_bitmap:Bitmap;
			var i:int;
			var sign_DO:DisplayObject;
			
			//how much to scale the TF before drawing the bitmap, the bitmap will then be 1/scale_factor
			//note in the CSS under signpost_label, the default font-size was 12, should be multiplied by this scale factor
			const scale_factor:Number = 2;
			
			for(i; i < SIGN_COUNT; i++){
				sp = new Sprite();
				sp.name = SIGN_NAME + i;
				sp.useHandCursor = sp.buttonMode = true;
				sp.mouseChildren = false;
				sp.addEventListener(MouseEvent.ROLL_OVER, onSignOver, false, 0, true);
				sp.addEventListener(MouseEvent.CLICK, onSignClick, false, 0, true);
				
				sign_DO = new AssetManager.instance.assets['signpost_friends_'+SIGN_NAME+i]();
				sp.addChild(sign_DO);
				
				//handle the TF
				tf = new TextField();
				TFUtil.prepTF(tf);
				tf.embedFonts = false;
				tf.mouseEnabled = false;
				tf.width = sign_DO.width * scale_factor;
				tf.htmlText = '<p class="signpost_label">'+DEFAULT_TXT+'</p>';
				sign_tfs.push(tf);
				
				tf_bitmap = TFUtil.createBitmap(tf);
				tf_bitmap.scaleX = tf_bitmap.scaleY = 1/scale_factor;
				tf_bitmap.name = BITMAP_NAME + i;
				tf_bitmap.y = int(sp.height/2 - tf_bitmap.height/2);
				tf_bitmap.alpha = LABEL_DEFAULT_ALPHA;
				tf_bitmap.filters = StaticFilters.black1px90Degrees_DropShadowA;
				sp.addChild(tf_bitmap);
				
				//because of the custom rotations
				switch(i){
					case 0:
						tf_bitmap.rotation = -4;
						tf_bitmap.y += 7;
						break;
					case 1:
						tf_bitmap.rotation = 2;
						tf_bitmap.y -= 3;
						sign_DO.x = -7;
						break;
					case 2:
						tf_bitmap.rotation = .5;
						sign_DO.x = 2;
						break;
					case 3:
						tf_bitmap.rotation = -4;
						tf_bitmap.y += 7;
						sign_DO.x = -11;
						next_y -= 3;
						break;
					case 4:
						tf_bitmap.rotation = 2;
						tf_bitmap.y -= 2;
						sign_DO.x = 3;
						break;
				}
				
				sp.y = next_y;
				next_y += sign_DO.height + 3;
				signpost_holder.addChild(sp);
			}
			
			//place it where it needs to go
			signpost_holder.x = int(bg_holder.width/2 - signpost_holder.width/2);
		}
		
		private function buildEditHover():void {
			//sprite sheet
			hover_DO = new AssetManager.instance.assets.signpost_friends_hover();
			hover_holder.addChild(hover_DO);
			hover_holder.useHandCursor = hover_holder.buttonMode = true;
			hover_holder.addEventListener(MouseEvent.CLICK, onEditClick, false, 0, true);
			edit_holder.addChild(hover_holder);
			
			//tf
			TFUtil.prepTF(hover_tf);
			hover_tf.mouseEnabled = false;
			hover_tf.embedFonts = false;
			hover_tf.width = hover_DO.width;
			setHoverText(DEFAULT_TXT);
			hover_tf.y = int(HOVER_HEIGHT/2 - hover_tf.height/2) - 2;
			hover_tf.filters = StaticFilters.black1px90Degrees_DropShadowA;
			edit_holder.addChild(hover_tf);
			
			//draw the mask
			var g:Graphics = hover_mask.graphics;
			g.beginFill(0);
			g.drawRect(0, 0, hover_DO.width, HOVER_HEIGHT);
			
			hover_holder.mask = hover_mask;
			edit_holder.addChild(hover_mask);
			edit_holder.x = int(signpost_holder.width/2 - edit_holder.width/2) - 8; //extra is to match up with the nails
			
			//cancel button
			const cancel_DO:DisplayObject = new AssetManager.instance.assets.signpost_friends_cancel();
			cancel_bt = new Button({
				name: 'cancel',
				graphic: cancel_DO,
				w: cancel_DO.width,
				h: cancel_DO.height,
				draw_alpha:0
			});
			cancel_bt.addEventListener(TSEvent.CHANGED, onCancelClick, false, 0, true);
			cancel_bt.x = int(hover_holder.width - cancel_bt.width - cancel_bt.width/2);
			cancel_bt.y = int(-cancel_bt.height/2) + 2; //visual tweak cause of the shadow
			edit_holder.addChild(cancel_bt);
			
			signpost_holder.addChild(edit_holder);
			
			//super search
			signpost_search = new SignpostSearch();
			signpost_search.x = 26;
			signpost_search.y = -1;
			signpost_search.addEventListener(TSEvent.CHANGED, onFriendSelect, false, 0, true);
			edit_holder.addChild(signpost_search);
			edit_holder.addEventListener(MouseEvent.ROLL_OUT, onEditOut, false, 0, true);
			
			edit_holder.visible = false;
			
			//listen to ESC
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ESCAPE, onEscape, false, 0, true);
		}
		
		override public function start():void {
			throw new Error('Need to startWithSignpostID');
		}
		
		override public function end(release:Boolean):void {
			current_signpost_tsid = null;
			super.end(release);
		}
		
		public function startWithSignpostID(signpost_id:String):void {
			//reset the edit state
			const signpost_view:SignpostView = TSFrontController.instance.getMainView().gameRenderer.getSignpostViewByTsid(signpost_id);
			if(signpost_view) signpost_view.edit_clicked = false;
			
			//if we are clicking the edit button on the same post, no need to reset the UI
			if(current_signpost_tsid == signpost_id) {
				Benchmark.addCheck('already editing signpost '+signpost_id);
				return;
			}
			
			//try and start
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			
			current_signpost_tsid = signpost_id;
			
			//go ahead and show the signs
			showSigns();
			
			super.start();
		}
		
		public function update(is_success:Boolean):void {
			//when the server is done stuff, go ahead and update
			is_sending = false;
			
			if(!parent) return;
			
			if(is_success){				
				//update the signs with the signpost connections
				showSigns();
			}
			else {
				signpost_search.show();
				hover_tf.visible = false;
				cancel_bt.visible = true;
			}
		}
		
		private function showSigns():void {
			//get the signpost view and extract it's data
			const signpost_view:SignpostView = TSFrontController.instance.getMainView().gameRenderer.getSignpostViewByTsid(current_signpost_tsid);
			if(signpost_view){				
				var connect:LocationConnection;
				var i:int;
				var total:int = signpost_view.signpost.connects.length;
				var label:String;
				var buddy_tsids_to_exclude:Array = [];
				
				is_editing = false;
				edit_holder.visible = false;
				resetSigns();
				
				for(i = 0; i < SIGN_COUNT; i++){
					//reset the signs
					setSignText(i);
				}
				
				//give them the labels
				for(i = 0; i < total; i++){
					connect = signpost_view.signpost.connects[int(i)];
					if(connect.hidden) {
						if(!CONFIG::god) {
							//if not god, do not display
							continue;
						}
					}
					
					//get the label
					label = (connect.hidden ? 'A/D HIDDEN: ':'')+(connect.label || 'NULL VALUE');
					
					//set the sign
					setSignText(int(connect.tsid), label);
					
					//exclude this player from the friend search
					buddy_tsids_to_exclude.push(connect.player_tsid);
				}
				
				//make sure the search knows about which ones to exclude
				signpost_search.buddy_tsids_to_exclude = buddy_tsids_to_exclude;
			}
		}
		
		private function resetSigns():void {
			//reset the signs
			var child:DisplayObject;
			var i:int;
			var total:int = signpost_holder.numChildren;
			
			for(i; i < total; i++){
				child = signpost_holder.getChildAt(i);
				if(child.name.indexOf(SIGN_NAME) != -1){
					//show it again
					child.alpha = 1;
					child.visible = true;
				}
			}
		}
		
		private function setSignText(id:uint, txt:String = SignpostDialog.DEFAULT_TXT):void {
			const sp:Sprite = signpost_holder.getChildByName(SIGN_NAME+id) as Sprite;
			if(sp){
				//get the TF
				const tf:TextField = sign_tfs[int(id)];
				var tf_bitmap:Bitmap = sp.getChildByName(BITMAP_NAME+id) as Bitmap;
				if(tf && tf_bitmap){
					txt = StringUtil.replaceNewLineWithSomething(StringUtil.encodeHTMLUnsafeChars(txt), '');
					
					tf.htmlText = '<p class="signpost_label">'+txt+'</p>';
					
					//draw the tf data
					const data:BitmapData = new BitmapData(tf.width, tf.height, true, 0);
					data.draw(tf);
					tf_bitmap.bitmapData = data;
					tf_bitmap.smoothing = true; //gotta set smoothing again for some reason
					
					//if it's not the default, make sure the alpha is 1
					tf_bitmap.alpha = txt != DEFAULT_TXT ? 1 : LABEL_DEFAULT_ALPHA;
				}
			}
		}
		
		private function getSignText(id:uint):String {
			const sp:Sprite = signpost_holder.getChildByName(SIGN_NAME+id) as Sprite;
			if(sp){
				//get the TF
				const tf:TextField = sign_tfs[int(id)];
				if(tf){
					return StringUtil.replaceNewLineWithSomething(StringUtil.encodeHTMLUnsafeChars(tf.text), '');
				}
			}
			
			return DEFAULT_TXT;
		}
		
		private function setHoverText(txt:String):void {
			txt = StringUtil.replaceNewLineWithSomething(txt, '');
			hover_tf.htmlText = '<p class="signpost_label"><span class="signpost_label_hover">'+txt+'</span></p>';
			
			//if it's not the default, make sure the alpha is 1
			hover_tf.alpha = txt != DEFAULT_TXT ? 1 : LABEL_DEFAULT_ALPHA;
		}
		
		override protected function _jigger():void {
			super._jigger();
			
			_title_tf.x = _head_graphic.x + _head_graphic.width + 8;
			
			_head_graphic.y = int(_head_h/2 - _head_graphic.height/2) + 3;
		}
		
		private function onEditOut(event:MouseEvent):void {
			edit_holder.visible = is_editing;
			
			//if we are not editing, make sure to bring back the signs
			if(!is_editing) resetSigns();
		}
		
		private function onSignOver(event:MouseEvent):void {
			if(is_editing || is_sending) return;
			
			resetSigns();
			
			const sp:Sprite = event.currentTarget as Sprite;
			sp.visible = false;
			
			//get the id, if it's even we point to the right, otherwise to the left
			const sp_id:int = int(sp.name.substr(SIGN_NAME.length));
			current_sign_id = sp_id;
			if(sp_id % 2 == 0){
				//point right
				hover_DO.y = 0;
			}
			else {
				//point left, 3 item in the sprite sheet
				hover_DO.y = -HOVER_HEIGHT*2;
			}
			
			hover_tf.visible = true;
			setHoverText(getSignText(sp_id));
			signpost_search.hide();
			edit_holder.visible = true;
			edit_holder.y = sp.y;
			
			//if we have a player name, show the cancel button
			cancel_bt.visible = getSignText(sp_id) != DEFAULT_TXT;
		}
		
		private function onSignClick(event:MouseEvent):void {
			//if we are editing something else go ahead and swap to the new one
			if (is_editing) {
				is_editing = false;
				onSignOver(event);
			} else {
				const sp:Sprite = event.currentTarget as Sprite;
				const sp_id:int = int(sp.name.substr(SIGN_NAME.length));
				current_sign_id = sp_id;
			}
			
			onEditClick(event);
		}
		
		private function onEditClick(event:MouseEvent):void {
			if(is_sending) {
				Benchmark.addCheck('clicked, but we are waiting for a GS response');
				return;
			}
			
			is_editing = true;
			
			const sp:Sprite = signpost_holder.getChildByName(SIGN_NAME+current_sign_id) as Sprite;
			sp.visible = false;
			
			//if it's even we point to the right, otherwise to the left
			if(current_sign_id % 2 == 0){
				//point right
				hover_DO.y = -HOVER_HEIGHT;
			}
			else {
				//point left, 4 item in the sprite sheet
				hover_DO.y = -HOVER_HEIGHT*3;
			}
			
			//show the cancel button
			cancel_bt.visible = true;
			
			//hide the hover text
			hover_tf.visible = false;
			
			//get the super search going
			const hover_txt:String = StringUtil.replaceNewLineWithSomething(hover_tf.text, '');
			signpost_search.default_text = DEFAULT_TXT;
			signpost_search.show(true, hover_txt);
			signpost_search.default_text = hover_txt;
			
			edit_holder.visible = true;
			edit_holder.y = sp.y;
		}
		
		private function onCancelClick(event:TSEvent = null):void {
			//are they sure?!
			if(getSignText(current_sign_id) != DEFAULT_TXT){
				is_editing = true;
				cdVO.txt = 'Are you sure you want to remove '+getSignText(current_sign_id)+' from your signpost?';
				TSFrontController.instance.confirm(cdVO);
			}
			else {
				//cancel the edit
				onEditCancel();
			}
		}
		
		private function onEditCancel(event:Event = null):void {
			//hide the editor
			edit_holder.visible = false;
			
			//no longer editing
			is_editing = false;
			
			resetSigns();
		}
		
		private function onConfirmRemove(value:Boolean):void {
			//what did they want to do?!?!
			if(value){
				//tell the server to axe it
				SignpostManager.instance.removeNeighbor(current_sign_id);
			}
			
			//cancel edit mode
			onEditCancel();
		}
		
		private function onFriendSelect(event:TSEvent):void {
			const element:SuperSearchElementBuddy = event.data as SuperSearchElementBuddy;
			if(!element) return;
			
			const pc:PC = model.worldModel.getPCByTsid(element.value);
			if(!pc) return;
			
			hover_tf.visible = true;
			setHoverText(pc.label);
			
			cancel_bt.visible = false;
			
			//send it off to the server
			is_sending = true;
			SignpostManager.instance.addNeighbor(current_sign_id, element.value);
			
			//hide the search
			signpost_search.hide();
		}
		
		private function onEscape(event:KeyboardEvent):void {
			if(is_editing){
				//if we are editing, kick out of edit mode
				onEditCancel();
			}
		}
		
		public function get signpost_tsid():String { return current_signpost_tsid; }
	}
}