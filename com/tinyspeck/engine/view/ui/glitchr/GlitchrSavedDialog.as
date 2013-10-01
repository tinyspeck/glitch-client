package com.tinyspeck.engine.view.ui.glitchr
{
	import com.quietless.bitmap.BitmapSnapshot;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.net.NetOutgoingShareTrackVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.util.URLUtil;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;

	public class GlitchrSavedDialog extends BigDialog
	{
		/* singleton boilerplate */
		public static const instance:GlitchrSavedDialog = new GlitchrSavedDialog();
		
		private static const PHOTO_W:uint = 120;
		private static const PHOTO_H:uint = 80;
		private static const PHOTO_PADD:uint = 8;
		private static const BOTTOM_H:uint = 82;
		
		private var cancel_bt:Button;
		private var twitter_bt:Button;
		private var facebook_bt:Button;
		private var google_bt:Button;
		private var pinterest_bt:Button;
		
		private var background_holder:Sprite = new Sprite();
		private var button_holder:Sprite = new Sprite();
		private var bottom_holder:Sprite = new Sprite();
		private var photo_bg:Sprite = new Sprite();
		private var photo_holder:Sprite = new Sprite();
		private var photo_mask:Shape = new Shape();
		
		private var photo_bmss:BitmapSnapshot;
		
		private var normal_transform:ColorTransform = new ColorTransform();
		private var white_transform:ColorTransform;
		
		private var save_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var is_built:Boolean;
		
		private var photo_id:String = '';
		private var download_url:String = '';
		private var photo_url:String = '';
		private var short_url:String = '';
		private var caption:String = '';
		
		public function GlitchrSavedDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = 375;
			_draggable = true;
			_head_min_h = 70;
			_body_min_h = 108;
			_foot_min_h = 3;
			_base_padd = 20;
			_body_fill_c = 0xffffff;
			_body_border_c = 0xffffff;
			_construct();
		}
		
		private function buildBase():void {
			//tf
			TFUtil.prepTF(save_tf);
			save_tf.width = _w;
			_scroller.body.addChild(save_tf);
			
			//bts
			cancel_bt = new Button({
				name: 'close',
				label: 'Done',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR,
				w: 100
			});
			cancel_bt.addEventListener(TSEvent.CHANGED, closeFromUserInput, false, 0, true);
			button_holder.addChild(cancel_bt);
			
			button_holder.x = int(_w/2 - button_holder.width/2 - 2);
			button_holder.y = int(_body_min_h - cancel_bt.height - _base_padd);
			_scroller.body.addChild(button_holder);
			
			//bottom part
			const bottom_color:uint = 0xecf1f2;
			const draw_x:int = _w/2 - PHOTO_W/2 - _outer_border_w - _border_w;
			const top_padd:uint = 26;
			var g:Graphics = bottom_holder.graphics;
			g.beginFill(bottom_color);
			g.drawRoundRect(draw_x, 0, PHOTO_W + PHOTO_PADD*2, PHOTO_H, 12);
			g.endFill();
			g.beginFill(bottom_color);
			g.drawRoundRectComplex(0, top_padd, _w - _outer_border_w + _border_w, BOTTOM_H, 0,0, 4,4);
			
			bottom_holder.y = int(button_holder.y + button_holder.height + 20);
			bottom_holder.filters = StaticFilters.copyFilterArrayFromObject({color:0xa3b8bd}, StaticFilters.black_GlowA);
			_scroller.body.addChild(bottom_holder);
			
			//snap holder
			g = photo_bg.graphics;
			g.beginFill(0xffffff);
			g.drawRoundRect(0, 0, PHOTO_W, PHOTO_H, 10);
			photo_bg.x = draw_x + PHOTO_PADD;
			photo_bg.y = PHOTO_PADD;
			photo_bg.filters = StaticFilters.copyFilterArrayFromObject({color:0xa3b8bd}, StaticFilters.black_GlowA);
			bottom_holder.addChild(photo_bg);
			
			g = photo_mask.graphics;
			g.beginFill(0);
			g.drawRoundRect(0, 0, PHOTO_W, PHOTO_H, 10);
			photo_holder.mask = photo_mask;
			photo_bg.addChild(photo_holder);
			photo_bg.addChild(photo_mask);
			
			//buttons
			facebook_bt = createShareButton('facebook');
			facebook_bt.x = int(draw_x - facebook_bt.width - 5);
			facebook_bt.y = top_padd + 8;
			bottom_holder.addChild(facebook_bt);
			
			twitter_bt = createShareButton('twitter', 'Tweet');
			twitter_bt.x = facebook_bt.x;
			twitter_bt.y = int(facebook_bt.y + facebook_bt.height + 4);
			bottom_holder.addChild(twitter_bt);
			
			google_bt = createShareButton('google');
			google_bt.x = photo_bg.x + PHOTO_W + PHOTO_PADD + 3;
			google_bt.y = facebook_bt.y;
			bottom_holder.addChild(google_bt);
			
			pinterest_bt = createShareButton('pinterest', 'Pin It');
			pinterest_bt.x = google_bt.x;
			pinterest_bt.y = int(google_bt.y + google_bt.height + 4);
			bottom_holder.addChild(pinterest_bt);
			
			//transform
			white_transform = ColorUtil.getColorTransform(0xffffff);
			
			//title
			_title_tf.htmlText = '<p class="glitchr_snapshot_title">Snap Saved!</p>';
			
			is_built = true;
		}
		
		public function startWithParameters(photo_id:String, download_url:String, photo_url:String, short_url:String, caption:String, photo_bmss:BitmapSnapshot):void {
			this.photo_id = photo_id;
			this.download_url = download_url;
			this.photo_url = photo_url;
			this.short_url = short_url;
			this.caption = caption;
			this.photo_bmss = photo_bmss;
			start();
		}
		
		override public function start():void {
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			
			//set the save text
			setSaveText();
			
			//set the photo thumbnail
			setThumbnail();
			
			//add the background so we can have a pretty tint
			TSFrontController.instance.getMainView().addView(background_holder);
			refresh();
			
			super.start();
			
			//make sure it doesn't jump around
			const lm:LayoutModel = model.layoutModel;
			x = int(lm.gutter_w + lm.overall_w/2 - _w/2);
			last_x = x;
			last_y = y;
		}
		
		override public function end(release:Boolean):void {
			if (model.stateModel.focus_is_in_input) {
				StageBeacon.stage.focus = StageBeacon.stage;
			}
			super.end(release);
			if(background_holder.parent) background_holder.parent.removeChild(background_holder);
		}
		
		override public function refresh():void {
			super.refresh();
			
			//make sure the tinter is good
			const lm:LayoutModel = model.layoutModel;
			const g:Graphics = background_holder.graphics;
			g.clear();
			g.beginFill(0, GlitchrSnapshotView.BG_ALPHA);
			g.drawRect(0, 0, StageBeacon.stage.width, StageBeacon.stage.height);
		}
		
		private function setSaveText():void {
			//populates the text below the title with proper view/download links
			var save_txt:String = '<p class="glitchr_snapshot_body">';
			save_txt += 'The snap has been saved to <b><a href="event:'+TSLinkedTextField.LINK_GLITCHR_PHOTO_URL+'|snaps/manage/">your snaps</a></b>.<br>';
			save_txt += 'You can <b><a href="event:' + TSLinkedTextField.LINK_EXTERNAL + '|' + download_url + '">download</a></b> it ';
			save_txt +=	'or <b><a href="event:' + TSLinkedTextField.LINK_GLITCHR_PHOTO_URL  + '|' + photo_url + '">view it</a></b> now.';
			save_txt += '</p>';
			
			save_tf.htmlText = save_txt;
		}
		
		private function setThumbnail():void {
			SpriteUtil.clean(photo_holder);
			if(photo_bmss){
				const bm:Bitmap = new Bitmap(photo_bmss.bmd);
				const start_h:int = bm.height;
				bm.smoothing = true;
				
				//let's scale this sucker
				bm.scaleX = bm.scaleY = PHOTO_W/bm.width;
				bm.y = PHOTO_H - bm.height;
				
				if(bm.height < PHOTO_H){
					bm.scaleX = bm.scaleY = PHOTO_H/start_h;
					bm.y = 0;
				}
				
				photo_holder.addChild(bm);
			}
		}
		
		override protected function _jigger():void {
			super._jigger();
			
			//move the title
			_title_tf.y = 20;
			_title_tf.x = int(_w/2 - _title_tf.width/2);
			
			//height is always going to be the same
			_body_h = bottom_holder.y + BOTTOM_H + 25;
			_h = _head_h + _body_h + _foot_h;
			_draw();
		}
		
		override protected function enterKeyHandler(e:KeyboardEvent):void {
			if (model.stateModel.focus_is_in_input) {
				// silently bail
				return;
			}
			
			//close 'er up
			escKeyHandler(e);
		}
		
		private function createShareButton(type:String, label:String = 'Share'):Button {
			const bt_w:uint = 72;
			const bt_h:uint = 26;
			const logo_DO:DisplayObject = new AssetManager.instance.assets['share_'+type]();
			const bt_obj:Object = {
				name: type,
				label: label,
				size: Button.SIZE_TINY,
				type: 'share_'+type,
				graphic: logo_DO,
				graphic_placement: 'left',
				graphic_padd_l: 6,
				graphic_padd_r: 4,
				w: bt_w,
				h: bt_h
			};
				
			//push the graphic down a little bit
			if(type == 'google'){
				bt_obj.graphic_padd_t = 5;
				bt_obj.graphic_padd_l = 2;
			}
			
			const bt:Button = new Button(bt_obj);
			bt.addEventListener(MouseEvent.ROLL_OVER, onShareMouse, false, 0, true);
			bt.addEventListener(MouseEvent.ROLL_OUT, onShareMouse, false, 0, true);
			bt.addEventListener(TSEvent.CHANGED, onShareButtonClick, false, 0, true);
			
			return bt;
		}
		
		private function onShareMouse(event:MouseEvent):void {
			const is_over:Boolean = event && event.type == MouseEvent.ROLL_OVER;
			const bt:Button = event.currentTarget as Button;
			if(bt){
				if(bt.graphic) bt.graphic.transform.colorTransform = is_over ? white_transform : normal_transform;
			}
		}
		
		private function onShareButtonClick(event:TSEvent):void {
			//depending on what we are doing, handle it
			const bt:Button = event.data as Button;
			if(bt == twitter_bt){
				const extra:String = ' '+short_url+' %23glitchsnap';
				
				//make sure we aren't over the allowed chars for the twitters (+2 is for the %23 going to #)
				const text:String = caption ? StringUtil.truncate(caption, 140-extra.length+2) : "Check out my snapshot on Glitch!";
				URLUtil.openTwitter(text+extra);
			}
			else if(bt == facebook_bt){
				URLUtil.openFacebook(short_url);
			}
			else if(bt == google_bt){
				URLUtil.openGooglePlus(short_url);
			}
			else if(bt == pinterest_bt){
				URLUtil.openPinterest(caption || "Check out my snapshot on Glitch!", short_url, download_url);
			}
			
			//tell the server we clicked it
			TSFrontController.instance.genericSend(new NetOutgoingShareTrackVO('snap', bt ? bt.name : 'unknown', short_url));
		}
	}
}