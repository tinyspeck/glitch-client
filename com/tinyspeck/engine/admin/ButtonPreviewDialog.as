package com.tinyspeck.engine.admin
{
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSScroller;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;

	public class ButtonPreviewDialog extends BigDialog
	{
		/* singleton boilerplate */
		public static const instance:ButtonPreviewDialog = new ButtonPreviewDialog();
		
		private static const SCROLL_H:uint = 150;
		
		private var size_scroll:TSScroller;
		private var type_scroll:TSScroller;
		private var bt_white:Button;
		private var bt_black:Button;
		
		private var preview_holder:Sprite = new Sprite();
		
		private var size_tf:TextField = new TextField();
		private var type_tf:TextField = new TextField();
		private var current_tf:TextField = new TextField();
		
		private var current_size:String = Button.SIZE_DEFAULT;
		private var current_type:String = Button.TYPE_DEFAULT;
		
		private var is_built:Boolean;
		
		public function ButtonPreviewDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = 500;
			_draggable = true;
			_base_padd = 20;
			_close_bt_padd_top = 10;
			_close_bt_padd_right = 10;
			_body_fill_c = 0xffffff;
			_body_border_c = 0xffffff;
			_construct();
		}
		
		private function buildBase():void {
			//slap the title in there
			_setTitle('Button Styles Preview');
			
			//size
			size_scroll = new TSScroller({
				name: 'size_scroll',
				w: _w/2 - _base_padd*2,
				h: SCROLL_H
			});
			size_scroll.x = _base_padd;
			size_scroll.y = _base_padd;
			_scroller.body.addChild(size_scroll);
			
			//type
			type_scroll = new TSScroller({
				name: 'type_scroll',
				w: _w/2 - _base_padd*2,
				h: SCROLL_H
			});
			type_scroll.x = _w - _base_padd - type_scroll.width;
			type_scroll.y = _base_padd;
			_scroller.body.addChild(type_scroll);
			
			//headers
			TFUtil.prepTF(size_tf, false);
			size_tf.x = size_scroll.x;
			size_tf.htmlText = '<p>Size</p>';
			_scroller.body.addChild(size_tf);
			
			TFUtil.prepTF(type_tf, false);
			type_tf.x = type_scroll.x;
			type_tf.htmlText = '<p>Type</p>';
			_scroller.body.addChild(type_tf);
			
			const styles:Array = CSSManager.instance.styleSheet.styleNames.concat();
			styles.sort(Array.CASEINSENSITIVE);
			
			const total:int = styles.length;
			var i:int;
			var style_name:String;
			var label:String;
			var bt:Button;
			var next_y_type:int;
			var next_y_size:int;
			
			for(i; i < total; i++){
				style_name = styles[int(i)];
				if(style_name.indexOf('.button_') == 0){
					label = style_name.substr(8); //8 == ".button_"
					
					//button style, now see if it's a TYPE or a SIZE
					if(style_name.indexOf('_label') != -1){
						//axe the _label from the end
						label = label.substr(0, -6);
						
						//TYPE
						bt = new Button({
							name: style_name,
							label: label,
							value: label,
							size: Button.SIZE_TINY,
							type: Button.TYPE_DEFAULT,
							w: 100
						});
						bt.addEventListener(TSEvent.CHANGED, onTypeClick, false, 0, true);
						bt.y = next_y_type;
						next_y_type += bt.height
						type_scroll.body.addChild(bt);
					}
					else {
						//SIZE
						bt = new Button({
							name: style_name,
							label: label,
							value: label,
							size: Button.SIZE_TINY,
							type: Button.TYPE_DEFAULT,
							w: 100
						});
						bt.addEventListener(TSEvent.CHANGED, onSizeClick, false, 0, true);
						bt.y = next_y_size;
						next_y_size += bt.height
						size_scroll.body.addChild(bt);
					}
				}
			}
			
			size_scroll.refreshAfterBodySizeChange();
			type_scroll.refreshAfterBodySizeChange();
			
			//preview buttons
			preview_holder.y = int(size_scroll.y + SCROLL_H + 20);
			_scroller.body.addChild(preview_holder);
			
			//current text
			TFUtil.prepTF(current_tf, false);
			_scroller.body.addChild(current_tf);
			
			is_built = true;
		}
		
		override public function start():void {
			if(!is_built) buildBase();
			drawButtons();
			
			super.start();
		}
		
		private function drawButtons():void {
			SpriteUtil.clean(preview_holder);
			const draw_h:uint = 150;
			const g:Graphics = preview_holder.graphics;
			g.beginFill(0);
			g.drawRect(_w/2, 0, _w/2, draw_h);
			
			bt_white = new Button({
				name: 'bt_white',
				label: 'Sample',
				size: current_size,
				type: current_type
			});
			bt_white.x = int(_w/4 - bt_white.width/2);
			bt_white.y = int(draw_h/2 - bt_white.height/2);
			preview_holder.addChild(bt_white);
			
			bt_black = new Button({
				name: 'bt_black',
				label: 'Sample',
				size: current_size,
				type: current_type
			});
			bt_black.x = int(_w - _w/4 - bt_black.width/2);
			bt_black.y = int(draw_h/2 - bt_black.height/2);
			preview_holder.addChild(bt_black);
			
			current_tf.htmlText = '<p>Current Size: <b>'+current_size+'</b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Current Type: <b>'+current_type+'</b></p>';
			current_tf.x = _w/2 - current_tf.width/2;
			current_tf.y = int(preview_holder.y + preview_holder.height + 10);
		}
		
		private function onSizeClick(event:TSEvent):void {
			const bt:Button = event.data as Button;
			current_size = bt.value;
			drawButtons();
		}
		
		private function onTypeClick(event:TSEvent):void {
			const bt:Button = event.data as Button;
			current_type = bt.value;
			drawButtons();
		}
	}
}