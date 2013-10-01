package com.tinyspeck.engine.view.ui.imagination
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.KeyBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.api.APICall;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.pc.AvatarLook;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.ImgMenuView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.avatar.AvatarLookUI;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.utils.Timer;

	public class ImaginationYourLooksUI extends Sprite implements IRefreshListener
	{
		/* singleton boilerplate */
		public static const instance:ImaginationYourLooksUI = new ImaginationYourLooksUI();
		
		private static const TOP_PADD:uint = 20;
		private static const AVATAR_PADD:uint = 15;
		private static const TITLE_MIN_X:int = 170;
		private static const MASK_DRAW_BUFFER:uint = 30;
		private static const MASK_Y_BUFFER:int = -25;
		private static const MASK_DRAW_H:uint = AvatarLookUI.HEIGHT + 80;
		private static const MASK_PADD:uint = 15;
		private static const MASK_MATRIX:Matrix = new Matrix();
		private static const GRAD_COLORS:Array = [0,0];
		private static const GRAD_RATIOS:Array = [0,255];
		private static const GRAD_ALPHAS:Array = [0,1];
		private static const MAX_OUTFITS:uint = 37;
		
		private var api_call:APICall = new APICall();
		private var looks:Vector.<AvatarLookUI> = new Vector.<AvatarLookUI>();
		private var ok_bt:Button;
		private var left_scroll:Button;
		private var right_scroll:Button;
		private var cdVO:ConfirmationDialogVO;
		private var switching_look_ui:AvatarLookUI = new AvatarLookUI();
		
		private var draw_timer:Timer = new Timer(10); //gets around cacheAsBitmap sucking balls
		
		private var title_tf:TextField = new TextField();
		private var total_tf:TextField = new TextField();
		private var current_tf:TextField = new TextField();
		private var switching_tf:TextField = new TextField();
		
		private var all_holder:Sprite = new Sprite();
		private var current_holder:Sprite = new Sprite();
		private var previous_holder:Sprite = new Sprite();
		private var outfit_holder:Sprite = new Sprite();
		private var outfit_mask:Sprite = new Sprite();
		private var switch_look_holder:Sprite = new Sprite();
		private var delete_outfit_holder:Sprite = new Sprite();
		
		private var delete_outfit_id:String;
		
		private var current_page:int = 1;
		private var total_pages:int;
		private var per_page:int = MAX_OUTFITS; //once the client does a better job at managing the the outfits, this can go back to 10
		private var total_outfits:int;
		private var current_outfit:int; //used for the scrolling
		private var outfit_x:int;
		
		private var is_built:Boolean;
		private var _is_hiding:Boolean;
		
		public function ImaginationYourLooksUI(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		private function buildBase():void {
			const title_filterA:Array = StaticFilters.copyFilterArrayFromObject({alpha:.5, distance:2}, StaticFilters.black7px90Degrees_DropShadowA);
			
			TFUtil.prepTF(title_tf, false);
			title_tf.htmlText = '<p class="imagination_your_looks"><span class="imagination_your_looks_title">Your looks</span></p>';
			title_tf.filters = title_filterA;
			title_tf.y = TOP_PADD;
			addChild(title_tf);
			
			TFUtil.prepTF(total_tf);
			total_tf.wordWrap = false;
			total_tf.y = int(title_tf.y + title_tf.height - 8);
			total_tf.filters = StaticFilters.copyFilterArrayFromObject({alpha:.3}, StaticFilters.black2px90Degrees_DropShadowA);
			addChild(total_tf);
			
			TFUtil.prepTF(current_tf, false);
			current_tf.htmlText = '<p class="imagination_your_looks">Your current look</p>';
			current_tf.y = int(AvatarLookUI.HEIGHT + 5);
			current_tf.filters = StaticFilters.copyFilterArrayFromObject({alpha:.3}, StaticFilters.black2px90Degrees_DropShadowA);
			current_holder.addChild(current_tf);
			all_holder.addChild(current_holder);
			
			//previous
			var arrow_holder:Sprite = new Sprite();
			var arrow_DO:DisplayObject = new AssetManager.instance.assets.white_arrow_large();
			arrow_DO.scaleX = -1;
			arrow_DO.x = arrow_DO.width;
			arrow_holder.addChild(arrow_DO);
			left_scroll = new Button({
				name: 'left',
				graphic: arrow_holder,
				disabled_graphic_alpha: .4,
				w: arrow_DO.width,
				h: arrow_DO.height,
				draw_alpha: 0
			});
			left_scroll.y = int(AvatarLookUI.HEIGHT/2 - left_scroll.height/2 + 10);
			left_scroll.filters = title_filterA;
			left_scroll.addEventListener(TSEvent.CHANGED, onScrollClick, false, 0, true);
			previous_holder.addChild(left_scroll);
			
			arrow_DO = new AssetManager.instance.assets.white_arrow_large();
			right_scroll = new Button({
				name: 'right',
				graphic: arrow_DO,
				disabled_graphic_alpha: .4,
				w: arrow_DO.width,
				h: arrow_DO.height,
				draw_alpha: 0
			});
			right_scroll.y = left_scroll.y;
			right_scroll.filters = title_filterA;
			right_scroll.addEventListener(TSEvent.CHANGED, onScrollClick, false, 0, true);
			previous_holder.addChild(right_scroll);
			
			outfit_x = left_scroll.width + 20;
			outfit_holder.mask = outfit_mask;
			outfit_holder.cacheAsBitmap = true;
			outfit_mask.x = outfit_x + MASK_PADD;
			outfit_mask.cacheAsBitmap = true;
			previous_holder.addChild(outfit_holder);
			previous_holder.addChild(outfit_mask);
			
			previous_holder.x = int(current_holder.width + 15);
			all_holder.addChild(previous_holder);
			
			//setup the draw timer
			draw_timer.addEventListener(TimerEvent.TIMER, draw, false, 0, true);
			
			//build out the switch look UI
			TFUtil.prepTF(switching_tf);
			switching_tf.wordWrap = false;
			switching_tf.htmlText = '<p class="imagination_your_looks">' +
				'<span class="imagination_your_looks_switch">Okay! Switching to this look...</span><br>' +
				'<span class="imagination_your_looks_moment">This will just take a moment</span>' +
				'</p>';
			switching_tf.y = AvatarLookUI.HEIGHT + 15;
			switching_tf.filters = title_filterA;
			switch_look_holder.addChild(switching_tf);
			
			ok_bt = new Button({
				name: 'ok',
				label: 'OK',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			ok_bt.addEventListener(TSEvent.CHANGED, onOkClick, false, 0, true);
			
			switching_look_ui.x = int(switching_tf.width/2 - switching_look_ui.width/2);
			switch_look_holder.addChild(switching_look_ui);
			
			//confirmation dialog
			cdVO = new ConfirmationDialogVO();
			cdVO.title = 'Remove this look from your history?';
			cdVO.txt = 'If you remove this look, you will no longer be able to instantly switch to it. Are you sure you want to remove it?';
			cdVO.choices = [
				{value:false, label:'No, never mind'},
				{value:true, label:'Yes, remove it'}
			];
			cdVO.escape_value = false;
			cdVO.max_w = 475;
			cdVO.graphic = delete_outfit_holder;
			cdVO.callback = onDeleteConfirm;
			
			delete_outfit_holder.x = -25;
			delete_outfit_holder.y = -25;
			
			//handle the api
			api_call.addEventListener(TSEvent.COMPLETE, onAPIComplete, false, 0, true);
			//api_call.trace_output = true;
			
			addChild(all_holder);
			
			is_built = true;
		}

		public function show():void {
			if(!is_built) buildBase();
			
			//toss it on the stage
			TSFrontController.instance.getMainView().addView(this, true);
			TSFrontController.instance.registerRefreshListener(this);
			
			//reset
			all_holder.visible = true;
			total_tf.visible = true;
			title_tf.alpha = 1;
			left_scroll.disabled = true;
			left_scroll.visible = false;
			right_scroll.disabled = false;
			right_scroll.visible = false;
			current_outfit = 0;
			current_page = 1;
			current_tf.visible = false;
			_is_hiding = false;
			if(switch_look_holder.parent) switch_look_holder.parent.removeChild(switch_look_holder);
			if(ok_bt.parent) ok_bt.parent.removeChild(ok_bt);
			
			//reset the pool
			const total:int = looks.length;
			var i:int;
			for(i = 0; i < total; i++){
				looks[int(i)].hide();
			}
			
			//fade in
			alpha = 0;
			TSTweener.removeTweens(this);
			TSTweener.addTween(this, {alpha:1, time:.2, transition:'linear'});
			
			loadHistory();
			
			//start drawing
			draw_timer.start();
			
			//listen to the shortcut to close it
			KeyBeacon.instance.addEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.L, onKeys, false, 0, true);
			
			refresh();
		}
		
		public function hide():void {
			KeyBeacon.instance.removeEventListener(KeyBeacon.SHIFT_PLUS_+KeyBeacon.KEY_DOWN_+Keyboard.L, onKeys);
			
			//fade out
			_is_hiding = true;
			const self:ImaginationYourLooksUI = this;
			TSTweener.addTween(this, {alpha:0, time:.2, transition:'linear', 
				onComplete:function():void {
					TSFrontController.instance.unRegisterRefreshListener(self);
					if(self.parent) self.parent.removeChild(self);
					draw_timer.stop();
					_is_hiding = false;
				}
			});
			
			//might want some sort of smart culling thing here so the client doesn't hold on to lots of outfits
		}
		
		public function refresh():void {
			if(!is_built) return;
			
			const lm:LayoutModel = TSModelLocator.instance.layoutModel;
			
			title_tf.x = Math.max(TITLE_MIN_X, int(lm.loc_vp_w/2 - title_tf.width/2));
			total_tf.x = int(lm.loc_vp_w/2 - total_tf.width/2);
			
			switch_look_holder.x = int(lm.loc_vp_w/2 - switch_look_holder.width/2);
			switch_look_holder.y = int(lm.loc_vp_h/2 - switch_look_holder.height/2 + 30);
			
			//set up where the right arrow goes
			const min_x:int = outfit_holder.width + outfit_x;
			right_scroll.x = int(Math.min(min_x, lm.loc_vp_w - right_scroll.width - outfit_x - previous_holder.x - 10));
			left_scroll.visible = right_scroll.x != min_x;
			right_scroll.visible = left_scroll.visible;
			
			//draw the mask
			draw();
			
			if(total_outfits > 1){
				all_holder.x = int(lm.loc_vp_w/2 - right_scroll.x/2 - previous_holder.x/2 - 20);
			}
			else {
				//so rone-ree
				all_holder.x = int(lm.loc_vp_w/2 - current_holder.width/2);
			}
			
			all_holder.y = int(lm.loc_vp_h/2 - AvatarLookUI.HEIGHT/2);
			
			//make sure things still look alright
			checkScroll(false);
			
			x = lm.gutter_w;
			y = lm.header_h;
		}
		
		public function loadHistory():void {
			//tells the api to go get the stuff
			api_call.avatarGetHistory(current_page, per_page);
		}
		
		public function switchOutfit(outfit_id:String):void {			
			//show this look
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			if(pc && pc.previous_looks){
				const look:AvatarLook = pc.getLookById(outfit_id);
				switching_look_ui.show(look, true);
				
				//set our singles_url to be this
				pc.singles_url = look.singles_base;
			}
			
			//put the ok button there
			ok_bt.x = int(switching_tf.width/2 - ok_bt.width/2);
			ok_bt.y = int(switching_tf.y + switching_tf.height + 10);
			switch_look_holder.addChild(ok_bt);
			
			all_holder.visible = false;
			total_tf.visible = false;
			title_tf.alpha = .5;
			addChild(switch_look_holder);
			
			//use the api to switch the outfit!
			api_call.avatarSwitchOutfit(outfit_id);
			
			refresh();
		}
		
		public function deleteOutfit(outfit_id:String):void {
			//use the api to delete the outfit!
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			const look:AvatarLook = pc.getLookById(outfit_id);
			SpriteUtil.clean(delete_outfit_holder);
			if(look){
				//load the avatar up
				AssetManager.instance.loadBitmapFromWeb(look.singles_base+'_100.png', onAvatarLoad, 'Avatar Your Looks Delete UI');
				
				delete_outfit_id = outfit_id;
				TSFrontController.instance.confirm(cdVO);
			}
		}
		
		private function draw(event:Event = null):void {
			const scroll_visible:Boolean = right_scroll.visible;
			const draw_w:int = scroll_visible ? right_scroll.x - outfit_x - MASK_PADD*2 : Math.max(outfit_holder.width, AvatarLookUI.WIDTH);
			const mask_fade_w:uint = scroll_visible ? 50 : 5;
			const g:Graphics = outfit_mask.graphics;
			g.clear();
			
			//left grad
			GRAD_ALPHAS[0] = 0;
			GRAD_ALPHAS[1] = 1;
			MASK_MATRIX.createGradientBox(mask_fade_w, MASK_DRAW_H, 0, -MASK_DRAW_BUFFER);
			g.beginGradientFill(GradientType.LINEAR, GRAD_COLORS, GRAD_ALPHAS, GRAD_RATIOS, MASK_MATRIX);
			g.drawRect(-MASK_DRAW_BUFFER, MASK_Y_BUFFER, mask_fade_w, MASK_DRAW_H);
			
			//center
			g.beginFill(0);
			g.drawRect(mask_fade_w-MASK_DRAW_BUFFER, MASK_Y_BUFFER, draw_w-mask_fade_w*2+MASK_DRAW_BUFFER, MASK_DRAW_H);
			
			//right grad
			GRAD_ALPHAS[0] = 1;
			GRAD_ALPHAS[1] = 0;
			MASK_MATRIX.createGradientBox(mask_fade_w, MASK_DRAW_H, 0, draw_w-mask_fade_w);
			g.beginGradientFill(GradientType.LINEAR, GRAD_COLORS, GRAD_ALPHAS, GRAD_RATIOS, MASK_MATRIX);
			g.drawRect(draw_w-mask_fade_w, MASK_Y_BUFFER, mask_fade_w, MASK_DRAW_H);
		}
		
		private function checkScroll(animate:Boolean = true):void {
			if(current_outfit < 0) current_outfit = 0;
			left_scroll.disabled = current_outfit == 0;
			right_scroll.disabled = false;
			
			//we shift this over by 1 outfit at a time
			var end_x:int = outfit_x - (current_outfit * (AvatarLookUI.WIDTH+AVATAR_PADD));
			
			//if we've gone past where we have outfits, see if we can load more, otherwise set the end_x so it's stuck to the right
			if(end_x + outfit_holder.width < outfit_mask.width){
				right_scroll.disabled = true;
				
				/*
				//is there more on the server?
				if(current_page < total_pages){
					current_page++;
					loadHistory();
				}
				else {
					//place it where it needs to go
					end_x = outfit_x + outfit_mask.width - outfit_holder.width - 30;
				}
				*/
				
				//place it where it needs to go
				end_x = outfit_x + outfit_mask.width - outfit_holder.width - 30;
			}
			
			if(animate){
				TSTweener.addTween(outfit_holder, {x:end_x, time:.2});
			}
			else {
				outfit_holder.x = end_x;
			}
		}
		
		private function onAPIComplete(event:TSEvent):void {
			//let's show the goods
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			
			//if we've deleted an item, go ahead and refresh it
			if('delete_outfit_id' in event.data) {
				loadHistory();
				return;
			}
			if(!pc || !pc.previous_looks || !parent || (!('total' in event.data))) return;
			
			//if we are parsing the history, we get some more data about how many we have
			total_outfits = Math.min(event.data.total, MAX_OUTFITS);
			current_page = event.data.page;
			total_pages = event.data.pages;
			per_page = event.data.per_page;
			
			var total:int = looks.length;
			var i:int;
			var next_x:int;
			var pool_id:int;
			var look_ui:AvatarLookUI;
			var look:AvatarLook;
			
			//reset the pool
			for(i = 0; i < total; i++){
				looks[int(i)].hide();
			}
			
			total = pc.previous_looks.length;
			for(i = 0; i < total; i++){
				//nothing to load, just go get the next one
				look = pc.previous_looks[int(i)];
				if(!look.singles_base && !look.is_current) continue;
				
				if(pool_id < looks.length){
					look_ui = looks[int(pool_id)];
				}
				else {
					look_ui = new AvatarLookUI();
					looks.push(look_ui);
				}
				pool_id++;
				
				look_ui.show(look, look.is_current);
				if(!look.is_current){
					look_ui.x = next_x;
					next_x += look_ui.width + AVATAR_PADD;
					outfit_holder.addChild(look_ui);
				}
				else {
					//place it in the current holder
					current_tf.visible = true;
					look_ui.x = int(current_holder.width/2 - look_ui.width/2);
					current_holder.addChild(look_ui);
				}
			}
			
			//set the total outfits
			var total_txt:String = '<p class="imagination_your_looks">';
			if(total_outfits > 1){
				total_outfits--;
				total_txt += 'You have '+StringUtil.formatNumberWithCommas(total_outfits)+' '+(total_outfits != 1 ? 'looks' : 'look');
				total_txt += ' from your past that you can quickly switch to';
			}
			else {
				total_txt += 'All we have on file is your current look, so no switching!';
				
				//throw the ok button on it
				if(!switch_look_holder.parent){
					ok_bt.x = int(current_tf.width/2 - ok_bt.width/2);
					ok_bt.y = int(current_tf.y + current_tf.height + 8);
					current_holder.addChild(ok_bt);
				}
			}
			
			//5 min reminder
			total_txt += '<br><p class="imagination_your_looks_min">';
			total_txt += 'Any look you keep for more than 5 minutes is auto-saved.';
			total_txt += '<br>You can permanently remove any you don\'t like.';
			total_txt += '</p>';
			
			total_txt += '</p>';
			total_tf.htmlText = total_txt;
			
			//move things where they should go
			refresh();
		}
		
		private function onOkClick(event:Event = null):void {
			ImgMenuView.instance.hide();
			
			//fade out
			const self:ImaginationYourLooksUI = this;
			TSTweener.addTween(this, {alpha:0, time:.2, transition:'linear', 
				onComplete:function():void {
					if(self.parent) self.parent.removeChild(self);
				}
			});
		}
		
		private function onScrollClick(event:TSEvent):void {
			const bt:Button = event.data as Button;
			if(bt.disabled) return;
			
			current_outfit += bt == left_scroll ? -1 : 1;
			checkScroll();
		}
		
		private function onAvatarLoad(filename:String, bm:Bitmap):void {
			//just in case
			while(delete_outfit_holder.numChildren) delete_outfit_holder.removeChildAt(0);
			if(bm){
				bm.scaleX = -1;
				bm.x = bm.width - 11;
				delete_outfit_holder.addChild(bm);
			}
			else {
				CONFIG::debugging {
					Console.warn('no bitmap?:'+bm+' filename: '+filename);
				}
			}
		}
		
		private function onDeleteConfirm(value:Boolean):void {
			if(value){
				//use the api to delete it
				api_call.avatarDeleteOutfit(delete_outfit_id);
				delete_outfit_id = null;
			}
		}
		
		private function onKeys(event:KeyboardEvent):void {
			//close the imagination menu
			ImgMenuView.instance.hide();
		}
		
		public function get is_hiding():Boolean { return _is_hiding; }
	}
}