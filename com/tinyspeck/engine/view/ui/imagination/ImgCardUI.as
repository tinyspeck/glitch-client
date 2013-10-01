package com.tinyspeck.engine.view.ui.imagination
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.quasimondo.geom.ColorMatrix;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.pc.ImaginationCard;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.ImaginationManager;
	import com.tinyspeck.engine.view.gameoverlay.ImgMenuView;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.PerspectiveProjection;
	import flash.geom.Point;
	import flash.text.TextField;
	
	public class ImgCardUI extends Sprite implements ITipProvider
	{
		public static const POSITION_LEFT:String = 'left';
		public static const POSITION_CENTER:String = 'center';
		public static const POSITION_RIGHT:String = 'right';
		
		private static const WIDTH:uint = 230; //this is the w/h of the FLA assets. DON'T FUCK WITH THIS!
		private static const HEIGHT:uint = 310;
		private static const BORDER_WIDTH:uint = 5;
		private static const CORNER_RADIUS:uint = 6;
		private static const TEXT_PADD:uint = 18;
		private static const FRONT_TEXT_PADD:uint = 11;
		
		private static var background_color:uint;
		private static var border_color:uint;
		private static var border_alpha:Number;
		private var cards_mc:MovieClip;
		
		public var position:String;
		
		private var all_holder:Sprite = new Sprite();
		private var side_holder:Sprite = new Sprite();
		private var front_holder:Sprite = new Sprite();
		private var front_suit_holder:Sprite = new Sprite();
		private var front_art_holder:Sprite = new Sprite();
		private var front_text_holder:Sprite = new Sprite();
		private var back_holder:Sprite = new Sprite();
		private var back_text_holder:Sprite = new Sprite();
		private var border:Sprite = new Sprite();
		private var masker:Sprite = new Sprite();
		private var art_holder:Sprite = new Sprite();
		
		private var sparkle:MovieClip;
		
		private var back_title_tf:TextField = new TextField();
		private var back_desc_tf:TextField = new TextField();
		private var back_cost_tf:TextField = new TextField();
		private var front_title_tf:TextField = new TextField();
		private var front_cost_tf:TextField = new TextField();
		
		private var buy_bt:Button;
		private var current_card:ImaginationCard;
		private var drop_filter:DropShadowFilter = new DropShadowFilter();
		private var title_dropA:Array;
		private var cost_dropA:Array;
		private var suit_dropA:Array;
		private var color_filterA:Array;
		private var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
		private var do_shadow:Boolean;
		private var is_clickable:Boolean;
		private var show_border:Boolean;
		
		private var local_pt:Point = new Point(0, -HEIGHT/2 + 12);
		private var global_pt:Point;
		
		private var reg_scale:Number = .9;
		private var flip_scale:Number = 1.05;
		
		private var is_built:Boolean;
		
		public function ImgCardUI(cards_mc:MovieClip, reg_scale:Number=NaN, flip_scale:Number=NaN, do_shadow:Boolean=true, is_clickable:Boolean=true, show_border:Boolean=true){
			this.cards_mc = cards_mc;
			if (!isNaN(reg_scale)) this.reg_scale = reg_scale;
			if (!isNaN(flip_scale)) this.flip_scale = flip_scale;
			this.do_shadow = do_shadow;
			this.is_clickable = is_clickable;
			this.show_border = show_border;
			CONFIG::debugging {
				if (!cards_mc) {
					Console.error('NO CARDS MC???');
				}
			}
		}
		
		private function buildBase():void {
			if(isNaN(border_alpha)){
				//set the css if not already set
				const cssm:CSSManager = CSSManager.instance;
				background_color = cssm.getUintColorValueFromStyle('imagination_card', 'backgroundColor', 0xe2e7ea);
				border_color = cssm.getUintColorValueFromStyle('imagination_card', 'borderColor', 0xffffff);
				border_alpha = cssm.getNumberValueFromStyle('imagination_card', 'borderAlpha', .3);
			}
			
			
			if (do_shadow) {
				//make the holder pretty
				drop_filter.angle = 90;
				drop_filter.distance = 4;
				drop_filter.blurX = 13;
				drop_filter.blurY = 9;
				drop_filter.alpha = .6;
				
				all_holder.filters = [drop_filter];
			}
			addChild(all_holder);
			
			//put the perspective on the all_holder so that rotating the Y axis doesn't look retarded
			const perspective:PerspectiveProjection = new PerspectiveProjection();
			perspective.fieldOfView = 60; //how much in your face the card looks, higher number, more in your face
			perspective.projectionCenter = new Point(0, 0);
			all_holder.transform.perspectiveProjection = perspective;
			
			front_holder.name = 'front_holder';
			front_suit_holder.name = 'front_suit_holder';
			
			//add the front/back
			side_holder.addChild(front_holder);
			side_holder.addChild(back_holder);
			back_holder.visible = false;
			back_holder.scaleX = -1;
			back_holder.x = WIDTH*flip_scale;
			
			//draw stuff
			var g:Graphics = side_holder.graphics;
			g.beginFill(background_color, show_border?1:0);
			g.drawRect(0, 0, WIDTH*reg_scale, HEIGHT*reg_scale);
			all_holder.addChild(side_holder);
			
			side_holder.mask = masker;
			side_holder.addChild(masker);
			
			//build the front
			title_dropA = StaticFilters.copyFilterArrayFromObject({alpha:.3}, StaticFilters.black2px90Degrees_DropShadowA);
			suit_dropA = StaticFilters.copyFilterArrayFromObject({alpha:.5, angle:225}, StaticFilters.black2px90Degrees_DropShadowA);
			cost_dropA = StaticFilters.copyFilterArrayFromObject({distance:1.5}, StaticFilters.black1px270Degrees_DropShadowA);
			
			const color_matrix:ColorMatrix = new ColorMatrix();
			color_matrix.colorize(0);
			color_filterA = [color_matrix.filter];
			
			TFUtil.prepTF(front_title_tf);
			front_title_tf.width = WIDTH*reg_scale - TEXT_PADD*2;
			front_title_tf.x = TEXT_PADD;
			front_text_holder.addChild(front_title_tf);
			
			TFUtil.prepTF(front_cost_tf, false);
			front_cost_tf.y = 7;
			front_text_holder.addChild(front_cost_tf);
			
			front_text_holder.x = -int((WIDTH*reg_scale)/2);
			front_text_holder.y = -int((HEIGHT*reg_scale)/2);
			front_text_holder.mouseEnabled = front_text_holder.mouseChildren = false;
			addChild(front_text_holder);
			
			//this alows the alpha to not suck and smoosh the objects together
			art_holder.blendMode = BlendMode.LAYER;
			
			//build the back
			TFUtil.prepTF(back_title_tf);
			back_title_tf.width = WIDTH*flip_scale - TEXT_PADD*2;
			back_title_tf.x = TEXT_PADD;
			back_title_tf.y = TEXT_PADD;
			back_title_tf.filters = StaticFilters.copyFilterArrayFromObject({angle:270}, StaticFilters.white1px90Degrees_DropShadowA);
			back_title_tf.mouseEnabled = false;
			back_text_holder.addChild(back_title_tf);
			
			TFUtil.prepTF(back_desc_tf);
			back_desc_tf.width = back_title_tf.width;
			back_desc_tf.x = TEXT_PADD;
			back_desc_tf.mouseEnabled = false;
			back_text_holder.addChild(back_desc_tf);
			
			buy_bt = new Button({
				name: 'buy',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR,
				w: int((WIDTH*flip_scale) - TEXT_PADD*2)
			});
			buy_bt.x = int((WIDTH*flip_scale)/2 - buy_bt.width/2);
			buy_bt.y = 215;
			buy_bt.mouseEnabled = false;
			buy_bt.filters = buy_bt.filters.concat(StaticFilters.black3px90Degrees_DropShadowA);
			buy_bt.visible = false;
			buy_bt.addEventListener(MouseEvent.MOUSE_OVER, onBuyOver, false, 0, true);
			back_text_holder.addChild(buy_bt);
			
			TFUtil.prepTF(back_cost_tf, false);
			back_cost_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			back_cost_tf.mouseEnabled = false;
			back_text_holder.addChild(back_cost_tf);
			
			back_text_holder.x = -int((WIDTH*flip_scale)/2);
			back_text_holder.y = -int((HEIGHT*flip_scale)/2);
			back_text_holder.mouseEnabled = false;
			addChild(back_text_holder);
			
			//border
			border.visible = show_border;
			border.mouseEnabled = false;
			side_holder.addChild(border);
			
			//confirmation
			cdVO.choices = [
				{value: false, label:'Nevermind'},
				{value: true, label:'Yes, upgrade me!'}			
			];
			cdVO.callback = onConfirm;
			cdVO.escape_value = false;
			
			if (is_clickable) {
				//listen to the mouse
				addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
				useHandCursor = buttonMode = true;
			}
			
			is_built = true;
		}
		
		public function show(card:ImaginationCard):void {
			if(!is_built) buildBase();
			current_card = card;
			
			visible = true;
			
			//reset
			name = 'id_'+card.id;
			reset(false);
			
			onFlipUpdate();
			
			//set the front
			buildFront();
			
			//set the back
			buildBack();
			
			refresh();
			
			//we need to show a tip if we can't afford it
			TipDisplayManager.instance.registerTipTrigger(this);
		}
		
		public function hide():void {
			scaleX = 1;
			scaleY = 1;
			
			TipDisplayManager.instance.unRegisterTipTrigger(this);
		}
		
		public function refresh():void {
			const pc:PC = TSModelLocator.instance && TSModelLocator.instance.worldModel ? TSModelLocator.instance.worldModel.pc : null;
			const can_afford:Boolean = !pc || !pc.stats || pc.stats.imagination >= current_card.cost;
			
			if(buy_bt){
				buy_bt.disabled = !can_afford;
				buy_bt.label = buy_bt.disabled ? 'Need more iMG' : 'Get Upgrade';
				buy_bt.label_y_offset = 2;
			}
			
			if(current_card && current_card.config){
				//see if we can afford this or not
				const is_keepable:Boolean = current_card.config.bg == 'bg_keepable';
				const not_enough_alpha:Number = .5;
				
				//put the filter on the suit/title/cost
				front_suit_holder.filters = !is_keepable && can_afford ? suit_dropA : color_filterA;
				if(is_keepable) front_suit_holder.filters = null;
				front_suit_holder.alpha = can_afford ? 1 : not_enough_alpha;
				
				front_title_tf.filters = !is_keepable && can_afford ? title_dropA : color_filterA;
				front_title_tf.alpha = can_afford ? 1 : not_enough_alpha;
				if(is_keepable) front_title_tf.filters = null;
				
				//set cost
				var cost_label:String = StringUtil.formatNumberWithCommas(current_card.cost)+'i';
				if(!can_afford){
					//not enough, dag
					cost_label = '<span class="imagination_card_front_cost_low">'+cost_label+'</span>';
				}
				
				front_cost_tf.htmlText = '<p class="imagination_card_front_cost">'+cost_label+'</p>';
				front_cost_tf.x = int(WIDTH*reg_scale - front_cost_tf.width - front_cost_tf.y - 5);
				front_cost_tf.filters = !is_keepable && can_afford ? cost_dropA : color_filterA;
				front_cost_tf.alpha = can_afford ? 1 : not_enough_alpha;
				
				//set the icon alpha
				art_holder.alpha = can_afford ? 1 : .3;
				
				//draw the text bg
				var g:Graphics = front_text_holder.graphics;
				g.clear();
				if(!is_keepable){
					//draw this if it's not a keepable card
					g.beginFill(can_afford ? 0 : 0xffffff, .3);
					g.drawRoundRectComplex(
						BORDER_WIDTH, 
						int(front_title_tf.y - FRONT_TEXT_PADD), 
						WIDTH*reg_scale - BORDER_WIDTH*2 + 1, 
						int(front_title_tf.height + FRONT_TEXT_PADD*2 + 2),
						0, 0, CORNER_RADIUS/2, CORNER_RADIUS/2
					);
				}
			}
		}
		
		public function hideFrontTextAndSuit():void {
			front_text_holder.visible = false;
			front_suit_holder.visible = false;
		}
		
		public function reset(animate:Boolean):void {
			const end_rot_y:int = 0;
			const front_alpha:Number = 1;
			const back_alpha:Number = 0;
			
			if(animate && all_holder.rotationY != end_rot_y){
				TSTweener.removeTweens([front_text_holder, back_text_holder]);
				front_text_holder.alpha = 0;
				back_text_holder.alpha = 0;
				const end_scale:Number = showing_front ? flip_scale : reg_scale;
				
				//show the front
				TSTweener.addTween(all_holder, {rotationY:end_rot_y, scaleX:1, scaleY:1, time:.5, transition:'easeOutCubic', onUpdate:onFlipUpdate, onComplete:onFlipComplete});
				
				//play the flip back sound slightly delayed
				SoundMaster.instance.playSound('FLIP_BACK');
			}
			else if(!animate){
				all_holder.rotationY = end_rot_y;
				front_text_holder.alpha = front_alpha;
				back_text_holder.alpha = back_alpha;
				onFlipUpdate();
			}
			
			buy_bt.disabled = true;
			buy_bt.value = null;
			buy_bt.visible = false;
			
			const draw_w:int = WIDTH*reg_scale;
			const draw_h:int = HEIGHT*reg_scale;
			
			//place it in the right spot
			side_holder.x = -int(draw_w/2);
			side_holder.y = -int(draw_h/2);
			
			//draw the mask
			var g:Graphics = masker.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRoundRect(0, 0, draw_w, draw_h, CORNER_RADIUS*2);
			
			//border
			g = border.graphics;
			g.clear();
			g.beginFill(border_color, border_alpha);
			g.drawRect(0, 0, draw_w, draw_h);
			g.drawRoundRect(BORDER_WIDTH, BORDER_WIDTH, draw_w - BORDER_WIDTH*2, draw_h - BORDER_WIDTH*2, CORNER_RADIUS); //draws the cutout
		}
		
		private function buildFront():void {
			//make sure it's cleaned up
			SpriteUtil.clean(front_holder);
			SpriteUtil.clean(front_suit_holder);
			SpriteUtil.clean(front_art_holder);
			SpriteUtil.clean(art_holder);
			
			//construct all the bits
			const bg:MovieClip = cards_mc.getAssetByName(current_card.config.bg);
			const pattern:MovieClip = cards_mc.getAssetByName(current_card.config.pattern);
			const suit:MovieClip = cards_mc.getAssetByName(current_card.config.suit);
			const art:MovieClip = cards_mc.getAssetByName(current_card.config.art);
			const icon:MovieClip = cards_mc.getAssetByName(current_card.config.icon);
			if(bg) front_holder.addChild(bg);
			if(pattern) front_holder.addChild(pattern);
			front_holder.addChild(front_suit_holder);
			if(suit) front_suit_holder.addChild(suit);
			front_holder.addChild(art_holder);
			if(art) art_holder.addChild(art);
			if(icon) art_holder.addChild(icon);
			
			front_holder.scaleX = front_holder.scaleY = reg_scale;
			
			const is_keepable:Boolean = current_card.config.bg == 'bg_keepable';
			
			//if this is a gold card, make sure we add the sparkles
			if(current_card.config.bg == 'bg_gold'){
				if(!sparkle){
					sparkle = cards_mc.getAssetByName('sparkle');
					sparkle.x = -(WIDTH*reg_scale)/2;
					sparkle.y = -(HEIGHT*reg_scale)/2;
				}
				all_holder.addChild(sparkle);
			}
			else if(sparkle && sparkle.parent){
				//get rid of the sparkles
				sparkle.parent.removeChild(sparkle);
			}
			
			//set the text
			var title_txt:String = '<p class="imagination_card_front_title">';
			if(!current_card.config.hide_front_name){
				if(is_keepable) title_txt += '<span class="imagination_card_front_keepable">';
				title_txt += current_card.name;
				if(is_keepable) title_txt += '<span>';
			}
			title_txt += '</p>';
			front_title_tf.htmlText = title_txt;
			front_title_tf.y = int(HEIGHT*reg_scale - BORDER_WIDTH - front_title_tf.height - FRONT_TEXT_PADD);
			if(is_keepable) front_title_tf.y -= 27;
			
			//set cost
			front_cost_tf.visible = !is_keepable && current_card.cost;
		}
		
		private function buildBack():void {
			//throw the back on the cards
			if(!back_holder.getChildByName('bg_back')){
				const bg_back:MovieClip = cards_mc.getAssetByName('bg_back');
				if(bg_back){
					bg_back.name = 'bg_back';
					bg_back.scaleX = bg_back.scaleY = flip_scale;
					back_holder.addChildAt(bg_back, 0);
				}
			}
			
			//clean out the holder except for the BG and add the suit
			SpriteUtil.clean(back_holder, true, 1);
			const suit:MovieClip = cards_mc.getAssetByName(current_card.config.suit+'_back');
			if(suit) {
				back_holder.addChild(suit);
				suit.scaleX = suit.scaleY = flip_scale;
			}
			
			back_title_tf.htmlText = '<p class="imagination_card_back_title">'+current_card.name+'</p>';
			back_desc_tf.y = int(back_title_tf.y + back_title_tf.height + 15);
			back_desc_tf.htmlText = '<p class="imagination_card_back_desc">'+current_card.desc+'</p>';
			back_cost_tf.htmlText = '<p class="imagination_card_back_cost">'+StringUtil.formatNumberWithCommas(current_card.cost)+'i</p>';
			back_cost_tf.x = int(WIDTH*flip_scale - TEXT_PADD - back_cost_tf.width + 4);
			back_cost_tf.y = int(HEIGHT*flip_scale - BORDER_WIDTH - back_cost_tf.height);
		}
		
		public function buy():void {
			SoundMaster.instance.playSound(buy_bt.disabled || showing_front ? 'CLICK_FAILURE' : 'CLICK_SUCCESS');
			
			//make sure the buy button is reset each click	
			if(!buy_bt.disabled){
				buy_bt.value = current_card.class_tsid;
				buy_bt.disabled = true;
				/*
				
				we used to do a confirmation in some cases, but now more
				
				if(!ImgMenuView.instance.hide_close){
					cdVO.txt = 'Are you sure you want to get the <b>'+current_card.name+'</b> upgrade?';
					TSFrontController.instance.confirm(cdVO);
					ImaginationManager.instance.is_confirming = true;
				}
				else {
					//just buy it!
					onConfirm(true);
				}
				
				*/
				
				//instead, we just buy it!
				onConfirm(true);
			}
			else {
				buy_bt.blur();
			}
		}
		
		private function onClick(event:MouseEvent = null):void {
			if(ImaginationManager.instance.is_confirming) return;
			if(TSTweener.isTweening(ImaginationHandUI.instance)) return;
			if(ImaginationHandUI.instance.is_blocking_purchases) return;
			
			if(event && event.target == buy_bt && !showing_front){
				buy();
				return;
			}
			
			flip();
		}
		
		public function flip():void {
			if(ImaginationManager.instance.is_confirming) return;
			if(TSTweener.isTweening(ImaginationHandUI.instance)) return;
			if(ImaginationHandUI.instance.is_blocking_purchases) return;
			
			const draw_w:int = WIDTH*(showing_front ? flip_scale : reg_scale);
			const draw_h:int = HEIGHT*(showing_front ? flip_scale : reg_scale);
			
			//draw the mask
			var g:Graphics = masker.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRoundRect(0, 0, draw_w, draw_h, CORNER_RADIUS*2);
			
			side_holder.x = -int(draw_w/2);
			side_holder.y = -int(draw_h/2);
			
			//set the default buy text
			buy_bt.value = null;
			
			TSTweener.removeTweens([front_text_holder, back_text_holder, all_holder]);
			front_text_holder.alpha = 0;
			back_text_holder.alpha = 0;
			
			//if the front is showing, flip the card			
			TSTweener.addTween(all_holder, {rotationY:(showing_front ? -180 : 0), time:.5, transition:'easeOutCubic', onUpdate:onFlipUpdate, onComplete:onFlipComplete});
			
			//play a sound
			SoundMaster.instance.playSound(showing_front ? 'FLIP_OVER' : 'FLIP_BACK');
			
			//anyone listening?
			dispatchEvent(new TSEvent(TSEvent.CHANGED, this));
		}
		
		private function onFlipUpdate():void {
			//figure out which side to show
			front_holder.visible = showing_front;
			if(sparkle) sparkle.visible = showing_front;
			back_holder.visible = !showing_front;
			
			//redraw the border down here so you don't see it fly out while it spins
			const draw_w:int = WIDTH*(!showing_front ? flip_scale : reg_scale);
			const draw_h:int = HEIGHT*(!showing_front ? flip_scale : reg_scale);
			const g:Graphics = border.graphics;
			g.clear();
			g.beginFill(border_color, border_alpha);
			g.drawRect(0, 0, draw_w, draw_h);
			g.drawRoundRect(BORDER_WIDTH, BORDER_WIDTH, draw_w - BORDER_WIDTH*2, draw_h - BORDER_WIDTH*2, CORNER_RADIUS); //draws the cutout
		}
		
		private function onFlipComplete():void {
			//show the front or back
			TSTweener.removeTweens([front_text_holder, back_text_holder]);
			if(showing_front){
				TSTweener.addTween(front_text_holder, {alpha:1, time:.1, transition:'linear'});
			}
			else {
				TSTweener.addTween(back_text_holder, {alpha:1, time:.1, transition:'linear'});
				refresh();
			}
			
			buy_bt.mouseEnabled = !showing_front;
			buy_bt.visible = !showing_front;
		}
		
		private function onConfirm(value:Boolean):void {
			if(value){
				ImaginationManager.instance.buyUpgrade(current_card);
				buy_bt.disabled = true;
				buy_bt.visible = false;
			}
			else {
				refresh();
			}
			
			ImaginationManager.instance.is_confirming = false;
		}
		
		private function onBuyOver(event:MouseEvent):void {
			//we want the buy button to be active, but not show the disabled hover state
			if(buy_bt.disabled) buy_bt.blur();
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target) return null;
			
			//if they don't have enough iMG, show a tooltip saying so
			const pc:PC = TSModelLocator.instance && TSModelLocator.instance.worldModel ? TSModelLocator.instance.worldModel.pc : null;
			const can_afford:Boolean = pc && pc.stats && pc.stats.imagination >= current_card.cost;
			
			if(can_afford || front_text_holder.alpha == 0) return null;
			
			global_pt = localToGlobal(local_pt);
			
			return {
				txt:'Not enough imagination!',
				placement:global_pt,
				pointer:WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
		
		public function get is_buyable():Boolean {
			if (showing_front) return false;
			if (buy_bt.disabled) return false;
			if (!buy_bt.visible) return false;
			
			return true;
		}
		
		public function get showing_front():Boolean {
			return all_holder.rotationY > -90;
		}
		
		public function get card_data():ImaginationCard { 
			return current_card;
		}
		
		public function get is_ready():Boolean {
			return is_built;
		}
		
		override public function get width():Number {
			return WIDTH * (showing_front ? reg_scale : flip_scale);
		}
		
		override public function get height():Number {
			return HEIGHT * (showing_front ? reg_scale : flip_scale);
		}
	}
}