package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.Note;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Dialog;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.TSScroller;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;

	public class NoteDialog extends Dialog implements IFocusableComponent, ITipProvider
	{
		/* singleton boilerplate */
		public static const instance:NoteDialog = new NoteDialog();
		
		private const TEXT_HEIGHT:uint = 217;
		private const WARN_PERC:Number = .05;
		private const HEAD_H:uint = 63;
		private const default_txt:String = 'Write something!';
		
		private var max_body_chars:uint;
		
		private var cancel_bt:Button;
		private var edit_bt:Button;
		private var save_bt:Button;
		private var done_bt:Button;
		private var text_scroll:TSScroller;
		private var graph_paper_fill:BitmapData;
		
		private var title_tf:TextField = new TextField();
		private var body_tf:TSLinkedTextField = new TSLinkedTextField();
		private var chars_left_tf:TextField = new TextField();
		private var author_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var all_holder:Sprite = new Sprite();
		private var text_holder:Sprite = new Sprite();
		private var title_edit_bg:Sprite = new Sprite();
		private var lines_holder:Sprite = new Sprite();
		private var graph_paper:Sprite = new Sprite();
		private var background_holder:Sprite = new Sprite();
		
		private var is_built:Boolean;
		private var is_editing:Boolean;
		private var cancel_closes:Boolean;
		private var can_edit:Boolean;
		
		public function NoteDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_h = 365;
			_base_padd = 20;
			_draggable = true;
			_construct();
		}
		
		private function buildBase():void {			
			//hide the close button on this bad boy
			_close_bt.visible = false;
			
			//background
			background_holder.x = _border_w;
			background_holder.y = HEAD_H + 1;
			all_holder.addChild(background_holder);
			
			//title tf			
			TFUtil.prepTF(title_tf);
			title_tf.multiline = false;
			title_tf.styleSheet = null;
			title_tf.autoSize = TextFieldAutoSize.NONE;
			//title_tf.embedFonts = false;
			//title_tf.defaultTextFormat = CSSManager.instance.getTextFormatFromStyle('note_title_no_embed');
			title_tf.defaultTextFormat = CSSManager.instance.getTextFormatFromStyle('note_title');
			title_tf.text = ' ';
			title_tf.width = _w - _base_padd*3;
			title_tf.height = title_tf.textHeight + 4;
			title_tf.addEventListener(Event.CHANGE, onTitleChange, false, 0, true);
			all_holder.addChild(title_tf);
			
			//build the different views
			buildReadView();
			buildEditView();
			
			//text scroll
			text_scroll = new TSScroller({
				name: 'text_scroll',
				bar_wh: 12,
				bar_color: 0,
				bar_alpha: .1,
				bar_handle_min_h: 36,
				scrolltrack_always: false,
				maintain_scrolling_at_max_y: true
			});
			all_holder.addChild(text_scroll);
			
			//body						
			TFUtil.prepTF(body_tf);
			body_tf.styleSheet = null;
			body_tf.selectable = true;
			//body_tf.embedFonts = false;
			//body_tf.defaultTextFormat = CSSManager.instance.getTextFormatFromStyle('note_body_no_embed');
			body_tf.defaultTextFormat = CSSManager.instance.getTextFormatFromStyle('note_body');
			body_tf.addEventListener(Event.CHANGE, onBodyChange, false, 0, true);
			body_tf.addEventListener(MouseEvent.CLICK, onBodyClick, false, 0, true);
			body_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			text_scroll.body.addChild(body_tf);
			
			//graph paper
			var i:int = 0;
			text_scroll.body.addChildAt(graph_paper, 0);
			graph_paper_fill = new BitmapData(10, 10, true, 0x00FFFFFF);
			graph_paper_fill.lock();
			for(i; i < graph_paper_fill.width; i++){
				graph_paper_fill.setPixel32(graph_paper_fill.width/2 - 1, i, 0x50e7eaeb);
				graph_paper_fill.setPixel32(i, graph_paper_fill.height/2 - 1, 0x50e7eaeb);
			}
			
			graph_paper_fill.unlock();
			
			all_holder.mouseEnabled = false;
			addChild(all_holder);
			
			is_built = true;
		}
		
		private function buildReadView():void {
			var padd_offset:int = -3; //makes the buttons padd better, but let's the edit backgrounds be right
			
			//buttons
			done_bt = new Button({
				name: 'done',
				label: 'Done!',
				type: Button.TYPE_DEFAULT,
				size: Button.SIZE_DEFAULT
			});
			done_bt.x = _w - _base_padd - done_bt.width + padd_offset;
			done_bt.y = _h - _base_padd - done_bt.height + padd_offset;
			done_bt.addEventListener(TSEvent.CHANGED, onDoneClick, false, 0, true);
			all_holder.addChild(done_bt);
			
			edit_bt = new Button({
				name: 'edit',
				label: 'Edit note',
				type: Button.TYPE_MINOR,
				size: Button.SIZE_DEFAULT
			});
			edit_bt.x = done_bt.x - edit_bt.width - _base_padd/2;
			edit_bt.y = done_bt.y;
			edit_bt.addEventListener(TSEvent.CHANGED, onEditClick, false, 0, true);
			all_holder.addChild(edit_bt);
			
			//author
			TFUtil.prepTF(author_tf);
			author_tf.wordWrap = false;
			author_tf.embedFonts = false;
			author_tf.x = _base_padd - padd_offset;
			author_tf.addEventListener(TextEvent.LINK, onAuthorClick, false, 0, true);
			all_holder.addChild(author_tf);
			
			//lines to divide up the body
			var g:Graphics = lines_holder.graphics;
			g.beginFill(0xc3cace);
			g.drawRect(0, HEAD_H, _w - _border_w*2, 1);
			g.drawRect(0, TEXT_HEIGHT + HEAD_H + _base_padd - 6, _w - _border_w*2, 1);
			lines_holder.x = _border_w;
			lines_holder.mouseEnabled = false;
			all_holder.addChild(lines_holder);
		}
		
		private function buildEditView():void {						
			//backgrounds for editing
			var bg_color:uint = CSSManager.instance.getUintColorValueFromStyle('note_body_background', 'backgroundEditColor', 0xf5f5ce);
			var border_color:uint = CSSManager.instance.getUintColorValueFromStyle('note_body_background', 'borderEditColor', 0xc3c38e);
			var g:Graphics = text_holder.graphics;
			g.lineStyle(1, border_color);
			g.beginFill(bg_color);
			g.drawRoundRect(0, 0, _w - _base_padd*2, TEXT_HEIGHT, 10);
			text_holder.x = _base_padd;
			text_holder.y = HEAD_H + 10;
			all_holder.addChild(text_holder);
			
			g = title_edit_bg.graphics;
			g.lineStyle(1, border_color);
			g.beginFill(bg_color);
			g.drawRoundRect(0, 0, _w - _base_padd*2, title_tf.height + 10, 10);
			title_edit_bg.x = _base_padd;
			title_edit_bg.y = _base_padd;
			title_edit_bg.mouseEnabled = false;
			all_holder.addChildAt(title_edit_bg, 0);
			
			//buttons
			save_bt = new Button({
				name: 'save',
				label: 'Save changes',
				type: Button.TYPE_DEFAULT,
				size: Button.SIZE_DEFAULT
			});
			save_bt.x = _w - _base_padd - save_bt.width;
			save_bt.y = done_bt.y;
			save_bt.addEventListener(TSEvent.CHANGED, onSaveClick, false, 0, true);
			all_holder.addChild(save_bt);
			
			cancel_bt = new Button({
				name: 'cancel',
				label: 'Cancel',
				type: Button.TYPE_CANCEL,
				size: Button.SIZE_TINY
			});
			cancel_bt.x = _base_padd;
			cancel_bt.y = save_bt.y;
			cancel_bt.addEventListener(TSEvent.CHANGED, onCancelClick, false, 0, true);
			all_holder.addChild(cancel_bt);
			
			//char count tf
			TFUtil.prepTF(chars_left_tf, false);
			setCharCount();
			chars_left_tf.autoSize = TextFieldAutoSize.RIGHT;
			chars_left_tf.x = int(save_bt.x - chars_left_tf.width - _base_padd/2);
			chars_left_tf.y = int(save_bt.y + (save_bt.height/2 - chars_left_tf.height/2)) + 2;
			all_holder.addChild(chars_left_tf);
		}
		
		override public function start():void {
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			
			var note:Note = NoteManager.instance.current_note;
			
			//set the max chars
			max_body_chars = note.max_chars > 0 ? note.max_chars : 1000;
			
			//set title and body
			title_tf.text = note.title;
			if(note.body && note.body != ''){
				setBodyText(note.body);
			}
			else {
				setBodyText(default_txt);
				
				// make sure the tf is full size
				onBodyChange();
				
				// select all the text
				focusOnInput(true);
				
				//listen for a click to clear out the text
				
			}
			
			//do they own the note?
			if(note.owner_tsid && note.owner_tsid == model.worldModel.pc.tsid){
				can_edit = true;
			}
			else {
				can_edit = false;
			}
			
			//which mode do we start in?
			toggleMode(note.start_in_edit_mode);
			
			// if editing, focus at end
			if (note.start_in_edit_mode) {
				onEditClick();
			}
			
			//what does the cancel button do off the top?
			cancel_closes = note.start_in_edit_mode;
			
			//if there is author data, let's show it!
			setAuthor(note);
			
			//load the background if it's there
			setBackground(NoteManager.instance.current_note.background_url);
			
			//listen to stuff
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.TAB, onTabDown, false, 0, true);
			KeyBeacon.instance.addEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onEnterDown, false, 0, true);
			TipDisplayManager.instance.registerTipTrigger(author_tf);
			
			_jigger();
			
			super.start();
		}
		
		override public function end(release:Boolean):void {
			super.end(release);
			
			//throw it back it regular mode for listeners etc.
			toggleMode(false);
			
			//tell the server we've closed this
			NoteManager.instance.close();
			
			//stop listening to stuff
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.TAB, onTabDown);
			KeyBeacon.instance.removeEventListener(KeyBeacon.KEY_DOWN_+Keyboard.ENTER, onEnterDown);
			TipDisplayManager.instance.unRegisterTipTrigger(author_tf);
		}
		
		private function setAuthor(note:Note):void {			
			if(note.owner_label){
				author_tf.htmlText = '<p class="note_author">'+(!note.signed_by ? 'Written' : 'Signed')+' by <b><a href="event:'+note.owner_tsid+'">'+note.owner_label+'</a></b><br>' +
					'<span class="note_time">'+TSFrontController.instance.getGameTimeFromUnixTimestamp(note.updated)+'</span></p>';
				author_tf.y = done_bt.y + int(done_bt.height/2 - author_tf.height/2);
			}
			//no author, clear it out
			else {
				author_tf.text = '';
			}
		}
		
		public function confirmSave():void {
			//this is called when the server successfully saves the note
			toggleMode(false);
			save_bt.disabled = false;
			cancel_bt.disabled = false;
			
			//update the current note
			NoteManager.instance.current_note.body = body_tf.text;
			NoteManager.instance.current_note.title = title_tf.text;
			
			//update the timestamp
			setAuthor(NoteManager.instance.current_note);
		}
		
		public function errorSave():void {
			//if there was an error saving the note, at least bring back the buttons
			cancel_bt.disabled = false;
			save_bt.disabled = false;
		}
		
		private function toggleMode(is_editing:Boolean):void {
			this.is_editing = is_editing;
			
			edit_bt.visible = (can_edit && !is_editing);
			done_bt.visible = !is_editing;
			
			save_bt.visible = is_editing;
			save_bt.disabled = !is_editing;
			cancel_bt.visible = is_editing;
			cancel_bt.disabled = !is_editing;
			
			lines_holder.visible = !is_editing
			title_edit_bg.visible = is_editing;
			chars_left_tf.visible = is_editing;
			author_tf.visible = !is_editing;
			title_tf.mouseEnabled = is_editing;
			text_holder.visible = is_editing;
			graph_paper.visible = !is_editing && !NoteManager.instance.current_note.background_url;
			
			//change the type of textfield the body is
			body_tf.type = is_editing ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
			title_tf.type = is_editing ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
			title_tf.selectable = is_editing;
			
			//scroller
			var cssm:CSSManager = CSSManager.instance;
			var handle_color:uint = cssm.getUintColorValueFromStyle('note_scroller', 'handleColor', 0x333f43);
			var stripes_color:uint = cssm.getUintColorValueFromStyle('note_scroller', 'stripesColor', 0x858c8e);
			if(is_editing){
				handle_color = cssm.getUintColorValueFromStyle('note_scroller', 'handleEditColor', 0x75733d);
				stripes_color = cssm.getUintColorValueFromStyle('note_scroller', 'stripesEditColor', 0xacab8b);
			}	
			
			//draw the scroller
			text_scroll.setHandleColors(handle_color, handle_color, stripes_color);
			text_scroll.x = text_holder.x + (is_editing ? _base_padd/2 : -_base_padd/2);
			text_scroll.y = text_holder.y + (is_editing ? _base_padd/2 : 2);
			text_scroll.w = _w - (is_editing ? _base_padd*3 : _base_padd + _border_w*2);
			text_scroll.h = TEXT_HEIGHT - (is_editing ? _base_padd : _base_padd/2);
			text_scroll.listen_to_arrow_keys = is_editing;
			text_scroll.refreshAfterBodySizeChange();

			//title
			title_tf.x = _base_padd + (is_editing ? 13 : 0);
			title_tf.y = _base_padd + (is_editing ? 5 : -4);
			title_tf.alpha = is_editing ? .8 : 1;
			
			//body
			body_tf.x = is_editing ? 0 : _base_padd/2;
			body_tf.alpha = is_editing ? .8 : 1;
			body_tf.width = text_scroll.w - body_tf.x - 17; //bar width plus a little padding
			if(!is_editing && body_tf.textHeight < text_scroll.h){
				body_tf.autoSize = TextFieldAutoSize.NONE;
				body_tf.height = text_scroll.h;
			}
			else {
				body_tf.autoSize = TextFieldAutoSize.LEFT;
			}
			
			//graph paper background
			var g:Graphics = graph_paper.graphics;
			g.clear();
			if(!is_editing){
				//show the grid
				g.beginBitmapFill(graph_paper_fill);
				g.drawRect(0, 0, body_tf.width + _base_padd, Math.max(body_tf.height, text_scroll.h));
				
				//scroll to the top if we are just reading
				text_scroll.scrollUpToTop();
			}
			
			//update the remaining chars allowed
			setCharCount();
			
			if(!is_editing) {
				//focus the done button so that they can hit enter to close it
				done_bt.focus();
				
				//make sure the stage is the one focused and not a TF or something
				StageBeacon.stage.focus = StageBeacon.stage;
			}
			else {
				done_bt.blur();
			}
		}
		
		private function setBodyText(txt:String):void {
			//because the TF needs to be used as INPUT we can't use the stylesheet like normal
			body_tf.text = txt;
		}
		
		private function setCharCount():void {
			var chars_left:int = max_body_chars - body_tf.text.length;
			var remaining_class:String = 'note_remaining_chars';
			
			//if we are WARN_PERC or lower of allowed chars, turn the number to the warning color
			if(chars_left / max_body_chars <= WARN_PERC){
				remaining_class = 'note_remaining_warning';
			}
			
			chars_left_tf.htmlText = '<p class="note_remaining">Characters remaining: '+
									 '<span class="'+remaining_class+'">'+StringUtil.formatNumberWithCommas(chars_left)+'</span>'+
									 '</p>';
			
			//if we are in the negative, disabled the save button
			save_bt.disabled = chars_left >= 0 ? false : true;
		}
		
		private function setBackground(url:String):void {
			SpriteUtil.clean(background_holder);
			if(!url) return;
			
			AssetManager.instance.loadBitmapFromWeb(url, onBackgroundLoad, 'Note background');
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target) return null;
			
			//get the real date of the note
			const note:Note = NoteManager.instance.current_note;
			if(!note) return null;
			
			return {
				txt: StringUtil.getTimeFromUnixTimestamp(note.updated, false, false, true, false),
				pointer: WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
		
		private function onBackgroundLoad(filename:String, bm:Bitmap):void {
			background_holder.addChild(bm);
		}
		
		private function onCancelClick(event:TSEvent = null):void {
			if(cancel_bt.disabled) return;
			
			if(cancel_closes){
				onDoneClick(event);
			}
			else {
				//set the body to be the oringinal text
				setBodyText(NoteManager.instance.current_note.body);
				title_tf.text = NoteManager.instance.current_note.title;
				
				toggleMode(false);
			}
		}
		
		private function onEditClick(event:TSEvent = null):void {
			if(!can_edit) return;
			
			toggleMode(true);
			
			//fire the body change to force any sizing we may need
			onBodyChange(event);
			
			//snap the scroller to the bottom and put the carat there
			text_scroll.scrollDownToBottom();
			StageBeacon.waitForNextFrame(focusOnInput, false);
		}
		
		private function onSaveClick(event:TSEvent = null):void {
			if(save_bt.disabled) return;
			
			NoteManager.instance.save(body_tf.text, title_tf.text);
			cancel_bt.disabled = true;
			save_bt.disabled = true;
			
			//if they leave the dialog up, cancel should behave as normal
			cancel_closes = false;
		}
		
		private function onBodyChange(event:Event = null):void {			
			setCharCount();
						
			if(body_tf.height < text_scroll.h && body_tf.maxScrollV <= 1){
				//turn off auto sizing and set the TF height
				body_tf.autoSize = TextFieldAutoSize.NONE;
				body_tf.height = TEXT_HEIGHT - _base_padd - 2;
			}
			else if(body_tf.autoSize != TextFieldAutoSize.LEFT) {
				//auto size as normal
				body_tf.autoSize = TextFieldAutoSize.LEFT;
			}
			
			//this will make sure the caret is always in view while editing
			text_scroll.updateHandleWithInputText(body_tf);
			text_scroll.refreshAfterBodySizeChange();
		}
		
		private function onTitleChange(event:Event = null):void {
			while(title_tf.scrollV > 1){
				title_tf.text = title_tf.text.substr(0, title_tf.text.length-1);
			}
		}
		
		private function onBodyClick(event:Event):void {
			if(is_editing){
				setCharCount();
				//clear the body text
				if (body_tf.text == default_txt) setBodyText('');
				//body_tf.removeEventListener(MouseEvent.CLICK, onBodyClick);
				
				//blur the buttons
				cancel_bt.blur();
				save_bt.blur();
			}
		}
		
		private function onDoneClick(event:TSEvent = null):void {
			end(true);
		}
		
		private function onAuthorClick(event:TextEvent):void {
			//send them to a profile page for that player
			PlayerInfoDialog.instance.startWithTsid(event.text);
		}
		
		private function onTabDown(event:KeyboardEvent):void {
			//cycle through any available things we can tab through
			if(is_editing){
				if(StageBeacon.stage.focus == body_tf){
					//go to the cancel button
					StageBeacon.stage.focus = StageBeacon.stage;
					cancel_bt.focus();
					save_bt.blur();
				}
				else if(StageBeacon.stage.focus == title_tf){
					//go to body
					focusOnInput(false);
					cancel_bt.blur();
					save_bt.blur();
				}
				else if(cancel_bt.focused){
					//go to save
					cancel_bt.blur();
					save_bt.focus();
				}
				else if(save_bt.focused){
					//go to title
					StageBeacon.stage.focus = title_tf;
					title_tf.setSelection(title_tf.text.length, title_tf.text.length);
					cancel_bt.blur();
					save_bt.blur();
				}
			}
			else {
				//make sure we have nothing in focus
				StageBeacon.stage.focus = StageBeacon.stage;
				
				if(edit_bt.focused){
					done_bt.focus();
					edit_bt.blur();
				}
				else if(edit_bt.visible){
					edit_bt.focus();
					done_bt.blur();
				}
				else {
					done_bt.focus();
				}
			}
		}
		
		private function onEnterDown(event:KeyboardEvent):void {
			//if one of the TFs has focus, then bail out
			if(is_editing && (StageBeacon.stage.focus == title_tf || StageBeacon.stage.focus == body_tf)){
				return;
			}
			
			if(done_bt.focused) {
				onDoneClick();
			}
			else if(edit_bt.focused){
				onEditClick();
			}
			else if(cancel_bt.focused){
				onCancelClick();
			}
			else if(save_bt.focused){
				onSaveClick();
			}
		}
		
		public function focusOnInput(select_all:Boolean = true):void {
			if (StageBeacon.stage.focus == body_tf) return;
			StageBeacon.stage.focus = body_tf;
			var start:int = (select_all) ? 0 : body_tf.text.length;
			body_tf.setSelection(start, body_tf.text.length);
		}
	}
}