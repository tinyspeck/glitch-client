package com.tinyspeck.engine.port
{
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.Note;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.noticeboard.NoticeListElement;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.filters.BevelFilter;
	import flash.filters.BitmapFilterType;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;

	public class NoticeBoardDialog extends BigDialog implements IPackChange
	{
		/* singleton boilerplate */
		public static const instance:NoticeBoardDialog = new NoticeBoardDialog();
		
		private static const MAX_CHARS:uint = 90;
		private static const FRAME_WIDTH:uint = 16;
		
		private var frame_holder:Sprite = new Sprite();
		private var top_bar:Sprite = new Sprite();
		
		private var add_bt:Button;
		private var cork_bg:Bitmap;
		private var frame_bg:Bitmap;
		private var header_bg:DisplayObject;
		
		private var is_built:Boolean;
		
		public function NoticeBoardDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = 515;
			//_body_border_c = 0xffffff;
			_body_fill_c = 0xffffff;
			_draggable = true;
			_head_min_h = 84;
			_body_min_h = 200;
			_body_max_h = 300;
			_foot_max_h = 52;
			_base_padd = 20;
			_scroller_bar_alpha = 0;
			_scroller_bar_wh = 13;
			_title_padd_left = 50;
			_close_bt_padd_right = 40;
			_close_bt_padd_top = 28;
			_outer_border_w = 0;
			
			visible = false;
			
			_construct();
		}
		
		private function buildBase():void {
			//add note button stuff
			var bt_bg:DisplayObject = new AssetManager.instance.assets.notice_add_note_bg();
			bt_bg.x = int(_w - bt_bg.width - _base_padd);
			bt_bg.y = int(_foot_min_h/2 - bt_bg.height/2) - 1;
			_foot_sp.addChild(bt_bg);
			
			add_bt = new Button({
				name: 'add_note',
				label: 'Add Note',
				type: Button.TYPE_DEFAULT,
				size: Button.SIZE_TINY
			});
			add_bt.x = int(_w - add_bt.width - 34);
			add_bt.y = int(_foot_min_h/2 - add_bt.height/2);
			add_bt.addEventListener(TSEvent.CHANGED, onAddClick, false, 0, true);
			_foot_sp.addChild(add_bt);
			
			//get our textures
			cork_bg = new AssetManager.instance.assets.notice_board_bg();
			frame_bg = new AssetManager.instance.assets.notice_frame_bg();
			
			//add the frame
			var bevel:BevelFilter = new BevelFilter();
			bevel.type = BitmapFilterType.INNER;
			bevel.distance = 1;
			bevel.blurX = 3;
			bevel.blurY = 3;
			bevel.strength = 100;
			bevel.highlightAlpha = .3;
			bevel.shadowAlpha = .4;
			
			var drop:DropShadowFilter = new DropShadowFilter();
			drop.angle = 90;
			drop.alpha = .2;
			drop.distance = 6;
			drop.blurX = 0;
			drop.blurY = 8;
			
			frame_holder.mouseEnabled = frame_holder.mouseChildren = false;
			frame_holder.filters = [bevel, drop];
			addChildAt(frame_holder, getChildIndex(window_border)+1);
			
			//header
			header_bg = new AssetManager.instance.assets.notice_board_header_bg();
			header_bg.x = 17;
			header_bg.y = 13;
			addChildAt(header_bg, getChildIndex(frame_holder));
			
			//top bar for shadows
			var bevel_bar:BevelFilter = new BevelFilter();
			bevel_bar.type = BitmapFilterType.INNER;
			bevel_bar.distance = 1;
			bevel_bar.blurX = 3;
			bevel_bar.blurY = 3;
			bevel_bar.strength = 100;
			bevel_bar.highlightAlpha = .3;
			bevel_bar.shadowAlpha = .4;
			bevel_bar.angle = 90;
			
			top_bar.mouseEnabled = top_bar.mouseChildren = false;
			top_bar.x = FRAME_WIDTH - 2;
			top_bar.y =_head_min_h - 8;
			top_bar.filters = [bevel_bar, drop];
			addChild(top_bar);
			
			_close_bt.background_alpha = 0;
			
			is_built = true;
		}
		
		override public function start():void {
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			if(visible) end(false);
			
			visible = true;
			
			_setTitle('Notice Board');
			
			//listen for pack changes
			PackDisplayManager.instance.registerChangeSubscriber(this);
			
			super.start();
		}
		
		public function update():void {
			if(!visible) return;
			
			var notes:Vector.<Note> = NoticeBoardManager.instance.notes;
			var title_txt:String = 'Notice Board';
			
						
			//how many do we have?
			if(notes.length > 0){
				title_txt += ' - '+notes.length+' '+(notes.length != 1 ? 'Notices' : 'Notice');
			}
			_setTitle(title_txt);
			
			//can we add a note?
			onPackChange();
			
			//throw the notes in the scroller
			showElements(notes);
			
			_jigger();
		}
		
		override protected function _jigger():void {
			super._jigger();
			
			_foot_h = _foot_sp.visible ? _foot_max_h : _foot_min_h;
			
			//_body_h += _base_padd;
			_scroller.h = _body_h - _divider_h*2 - 1;
			_scroller.y = 7;
			
			_foot_sp.y = _head_h + _body_h + _base_padd + 3;
			
			_h = _head_h + _body_h + _base_padd;
			
			//fill in the scroller body properly
			/*
			var g:Graphics = _scroller.body.graphics;
			g.clear();
			g.beginBitmapFill(cork_bg.bitmapData);
			g.drawRect(0, 0, _scroller.w, _scroller.body_h+_base_padd/2);
			*/
			
			_draw();
		}
		
		override protected function _draw():void {
			super._draw();
			
			var mat:Matrix = new Matrix();
			var g:Graphics = window_border.graphics;
			g.beginBitmapFill(cork_bg.bitmapData);
			g.drawRoundRect(_border_w, _border_w, window_border.width, window_border.height, 4);
			
			//frame
			g = frame_holder.graphics;
			g.clear();
			
			//top
			g.beginBitmapFill(frame_bg.bitmapData, mat);
			g.moveTo(0, 0);
			g.lineTo(_w, 0);
			g.lineTo(_w - FRAME_WIDTH, FRAME_WIDTH);
			g.lineTo(FRAME_WIDTH, FRAME_WIDTH);
			g.lineTo(0, 0);
			g.endFill();
			
			//right
			mat.rotate(1.57079633);
			g.beginBitmapFill(frame_bg.bitmapData, mat);
			g.moveTo(_w, 0);
			g.lineTo(_w, _h);
			g.lineTo(_w - FRAME_WIDTH, _h - FRAME_WIDTH);
			g.lineTo(_w - FRAME_WIDTH, FRAME_WIDTH);
			g.lineTo(_w, 0);
			g.endFill();
			
			//bottom
			mat.rotate(1.57079633);
			g.beginBitmapFill(frame_bg.bitmapData, mat);
			g.moveTo(FRAME_WIDTH, _h - FRAME_WIDTH);
			g.lineTo(_w - FRAME_WIDTH, _h - FRAME_WIDTH);
			g.lineTo(_w, _h);
			g.lineTo(0, _h);
			g.lineTo(FRAME_WIDTH, _h - FRAME_WIDTH);
			g.endFill();
			
			//left
			mat.rotate(1.57079633);
			g.beginBitmapFill(frame_bg.bitmapData, mat);
			g.moveTo(0, 0);
			g.lineTo(FRAME_WIDTH, FRAME_WIDTH);
			g.lineTo(FRAME_WIDTH, _h - FRAME_WIDTH);
			g.lineTo(0, _h);
			g.lineTo(0, 0);
			g.endFill();
			
			//bar below header
			var bar_top:int = _head_min_h - 7;
			g = top_bar.graphics;
			g.beginBitmapFill(frame_bg.bitmapData);
			g.drawRect(0, 0, _w - FRAME_WIDTH*2 + 4, FRAME_WIDTH);  //4 is for the -2 offset to overlap the bevel
			/*
			g.moveTo(0, bar_top);
			g.lineTo(_w, bar_top);
			g.lineTo(_w, bar_top + FRAME_WIDTH);
			g.lineTo(0, bar_top + FRAME_WIDTH);
			g.lineTo(0, bar_top);
			g.endFill();
			*/
		}
		
		override public function end(release:Boolean):void {
			super.end(release);
			
			visible = false;
			
			//stop listening for pack changes
			PackDisplayManager.instance.unRegisterChangeSubscriber(this);
		}
		
		private function showElements(notes:Vector.<Note>):void {	
			var i:int;
			var element:NoticeListElement;
			var note:Note;
			var next_y:int = 5;
			var update_txt:String;
			var title_count:uint;
			var color_index:int;
			
			//reset and make invis
			for(i = 0; i < _scroller.body.numChildren; i++){
				element = _scroller.body.getChildAt(i) as NoticeListElement;
				element.y = 0;
				element.visible = false;
			}
			
			//place em in the scroller
			for(i = 0; i < notes.length; i++){
				note = notes[int(i)];
				element = _scroller.body.getChildByName('element_'+i) as NoticeListElement;
				if(!element){
					element = new NoticeListElement(_w - 50);
					element.name = 'element_'+i;
					element.x = _base_padd + 2;
					element.filters = StaticFilters.black1px90Degrees_DropShadowA;
					_scroller.body.addChild(element);
				}
				
				//make sure we can see it!
				element.visible = true;
				
				//set the TSID for messaging
				element.tsid = note.itemstack_tsid;
				
				//set the body
				if(!note.title) note.title = 'No title';
				title_count = note.title.length;
				element.body = '<b>'+note.title+'</b>'+(note.body ? '&nbsp;•&nbsp;' : '')+
							   '<span class="notice_element_body">'+StringUtil.truncate(StringUtil.replaceNewLineWithSomething(note.body), MAX_CHARS-title_count)+'</span>';
				
				//set the author and time
				update_txt = '';
				if(note.owner_tsid){
					update_txt += 'Written by <b><a href="event:'+TSLinkedTextField.LINK_PLAYER_INFO+'|'+note.owner_tsid+'" ' +
								  'class="'+RightSideManager.instance.getPCCSSClass(note.owner_tsid)+'">'+note.owner_label+'</a></b>';
				}
				if(note.updated){
					update_txt += (update_txt != '' ? '&nbsp;•&nbsp;' : '')+TSFrontController.instance.getGameTimeFromUnixTimestamp(note.updated);
				}
				element.author = update_txt;
				
				//can this note be taken/read?
				element.can_take = note.can_take;
				element.can_read = note.body ? true : false;
				
				//set the push pin color
				element.pin_color = NoticeListElement.PIN_COLORS[color_index];
				color_index++;
				if(color_index == NoticeListElement.PIN_COLORS.length){
					color_index = 0;
				}
				
				element.y = next_y;
				next_y += element.height + 3;
			}
		}
		
		public function onPackChange():void {
			if(!visible) return;
			
			//see if we have any notes to post
			var pc:PC = model.worldModel.pc;
			
			if(pc){
				_foot_sp.visible = NoticeBoardManager.instance.notes.length < NoticeBoardManager.instance.max_notes;
				add_bt.disabled = !(pc.hasHowManyItems('note') > 0);
				add_bt.tip = add_bt.disabled ? {txt:'You don\'t have any notes to post!'} : null;
			}
			else {
				_foot_sp.visible = false;
			}
		}
		
		private function onAddClick(event:TSEvent):void {
			if(add_bt.disabled) return;
			
			NoticeBoardManager.instance.addNote();
		}
	}
}