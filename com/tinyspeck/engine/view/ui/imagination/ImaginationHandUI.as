package com.tinyspeck.engine.view.ui.imagination
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.pc.ImaginationCard;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.gameoverlay.ImaginationManager;
	import com.tinyspeck.engine.view.gameoverlay.ImgMenuView;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.text.TextField;

	public class ImaginationHandUI extends Sprite implements IRefreshListener
	{
		/* singleton boilerplate */
		public static const instance:ImaginationHandUI = new ImaginationHandUI();
		
		private static const LEFT_ROTATION:Number = -10;
		private static const RIGHT_ROTATION:Number = 10;
		private static const TOP_OFFSET:int = 20; //used for rotated cards
		private static const CARDS_TO_DEAL:Vector.<ImgCardUI> = new Vector.<ImgCardUI>();
		private static const CARD_TO_DISCARD:Vector.<ImgCardUI> = new Vector.<ImgCardUI>();
		private static const CARD_ANI_TIME:Number = .5;
		private static const CARD_PADD:int = 110;
		private static const CARD_GUIDE_MAX_W:int = 465;
		private static const CARD_GUIDE_SAFE_H:int = 340; //if it goes less than this, we re-jig the redeal button
		private static const TITLE_MIN_X:int = 170; //this is as low as the title can go so it doesn't block the "< Back" button
		private static const TITLE_MAX_Y:int = 15;
		
		private var all_holder:Sprite = new Sprite();
		private var all_masker:Sprite = new Sprite();
		private var card_holder:Sprite = new Sprite();
		private var card_guide:Shape = new Shape();
		
		private var hand_redeal:DisplayObject;
		private var cards_mc:MovieClip;
		
		private var select_tf:TextField = new TextField();
		private var title_tf:TextField = new TextField();
		
		private var redeal:ImaginationRedealUI = new ImaginationRedealUI();
		private var cards:Vector.<ImgCardUI> = new Vector.<ImgCardUI>();
		private var card_rect:Rectangle;
		
		private var current_imagination:int;
		private var current_purchase_id:int = -1;
		
		private var is_built:Boolean;
		private var has_seen_cards:Boolean;
		private var block_purchases:Boolean;
		
		private var showing:Boolean;
		
		public function ImaginationHandUI(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		private function buildBase():void {						
			//prep the card holder
			all_holder.addChild(card_holder);
			all_holder.addChild(card_guide);
			
			redeal.addEventListener(TSEvent.CHANGED, onRedealClick, false, 0, true);
			all_holder.addChild(redeal);
			
			//tf
			TFUtil.prepTF(title_tf, false);
			title_tf.htmlText = '<p class="imagination_hand"><span class="imagination_hand_title">Upgrade</span></p>';
			title_tf.filters = StaticFilters.copyFilterArrayFromObject({alpha:.5, distance:2}, StaticFilters.black7px90Degrees_DropShadowA);
			all_holder.addChild(title_tf);
			
			TFUtil.prepTF(select_tf);
			select_tf.htmlText = '<p class="imagination_hand">Select a card above<br>to learn about the upgrade</p>';
			select_tf.filters = StaticFilters.black2px90Degrees_DropShadowA;
			select_tf.wordWrap = false;
			all_holder.addChild(select_tf);
			
			//the purchase upgrade screen
			//ImaginationPurchaseUpgradeUI.instance.addEventListener(TSEvent.CHANGED, onPurchaseClick, false, 0, true);
			
			//cartoon hand to redeal stuff
			hand_redeal = new AssetManager.instance.assets.hand_redeal();
			
			all_holder.mask = all_masker;
			addChild(all_masker);
			addChild(all_holder);
		}
		
		public function show():void {	
			//build it			
			if(!is_built) buildBase();
			
			//reset
			current_imagination = 0;
			TSModelLocator.instance.worldModel.registerCBProp(onStatsChanged, "pc", "stats");
			TSFrontController.instance.registerRefreshListener(this);
			select_tf.alpha = 1;
			redeal.visible = !ImgMenuView.instance.hide_close;
			title_tf.y = !ImgMenuView.instance.hide_close ? TITLE_MAX_Y : 6;
			block_purchases = false;
			card_holder.alpha = 1;
			card_holder.visible = true;
			
			//fade in
			TSTweener.removeTweens(this);
			alpha = 0;
			TSTweener.addTween(this, {alpha:1, time:.2, transition:'linear'});
			
			//display the current cards
			showCards();	
			showing = true;	
			
			//wait a sec
			//StageBeacon.setTimeout(showPurchase, 2000, TSModelLocator.instance.worldModel.pc.stats.imagination_hand[1]);
		}
		
		public function redealHand():void {
			//new cards came in, go ahead and update them
			if(!parent) return;
			
			//reset the alpha incase we flipped a card
			select_tf.alpha = 1;
			
			//animate them all away and then redeal
			const total:int = card_holder.numChildren;
			var i:int;
			var card_ui:ImgCardUI;
			
			//reset the index
			for(i = 0; i < total; i++){
				card_ui = card_holder.getChildByName('id_'+i) as ImgCardUI;
				card_ui.reset(true);
				card_ui.alpha = 1;
				card_holder.setChildIndex(card_ui, card_ui.card_data.id);
				
				//put it back
				if(card_ui.position != ImgCardUI.POSITION_CENTER){
					TSTweener.addTween(card_ui, {rotation:(card_ui.position == ImgCardUI.POSITION_LEFT ? LEFT_ROTATION : RIGHT_ROTATION), y:TOP_OFFSET, time:.1});
				}
				
				//put the hand on the last card
				if(i == total-1){
					hand_redeal.y = -hand_redeal.height/2;
					hand_redeal.x = hand_redeal.width/2;
					card_ui.addChild(hand_redeal);
				}
			}
			
			//make sure they are in the right position
			for(i = 0; i < total; i++){
				card_ui = card_holder.getChildAt(i) as ImgCardUI;
				setCardPosition(card_ui);
			}
			
			//animate the hand and play a sound
			TSTweener.addTween(hand_redeal, {x:-hand_redeal.width/4, time:.1, transition:'easeInSine', onComplete:onHandAniComplete});
			SoundMaster.instance.playSound('HAND_SWIPE');
			
			CARDS_TO_DEAL.length = 0;
		}
		
		private function onHandAniComplete():void {
			const lm:LayoutModel = TSModelLocator.instance.layoutModel;
			const end_x:int = lm.loc_vp_w/2;
			const end_y:int = lm.loc_vp_h + 100;
			const total:int = card_holder.numChildren;
			const delay_ms:int = 300;
			
			var i:int;
			var card_ui:ImgCardUI;
			
			for(i = 0; i < total; i++){
				card_ui = card_holder.getChildAt(i) as ImgCardUI;
				TSTweener.removeTweens(card_ui);
				TSTweener.addTween(card_ui, {x:0, time:.5});
				TSTweener.addTween(card_ui, {x:end_x, y:end_y, time:.4, delay:.6,
					onStart:SoundMaster.instance.playSound,
					onStartParams:['HAND_PULL_DOWN'],
					onComplete:function(card:ImgCardUI, index:int):void {
						//staggers the redealing so they don't all come in at once
						StageBeacon.setTimeout(function():void {
							setCardPosition(card);
							onDiscardComplete(card, card.x);
						},index*delay_ms);
					},
					onCompleteParams:[card_ui, i]
				});
			}
		}
		
		public function updateHand():void {
			//new cards came in, go ahead and update them
			if(!parent) return;
			
			//figure out which card(s) are new
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			const total:int = card_holder.numChildren;
			var i:int;
			var card_ui:ImgCardUI;
			
			CARDS_TO_DEAL.length = 0;
			
			//TODO build a reflow function because we might have less cards than we had before
			
			if(pc && pc.stats){
				if(pc.stats.imagination_hand){
					//if we purchased a card, remove it
					if(current_purchase_id > -1){
						card_ui = card_holder.getChildByName('id_'+current_purchase_id) as ImgCardUI;
						if(card_ui) CARDS_TO_DEAL.push(card_ui);
						current_purchase_id = -1;
					}
					
					//reset
					for(i; i < total; i++){
						card_ui = card_holder.getChildAt(i) as ImgCardUI;
						card_ui.alpha = 1;
						card_ui.scaleX = card_ui.scaleY = 1;
						card_ui.reset(false);
					}
					
					//discard any that were pushed to CARDS_TO_DEAL
					discardCards(!ImgMenuView.instance.hide_close);
				}
				
				//are we able to redeal?
				redeal.enabled = !pc.stats.imagination_shuffled_today;
				select_tf.alpha = 1;
				refresh();
			}
		}
		
		public function hide():void {
			showing = false;
			TSModelLocator.instance.worldModel.unRegisterCBProp(onStatsChanged, "pc", "stats");
			
			//we might have some tips up, so hide it
			TipDisplayManager.instance.goAway();
			
			//fade out
			TSTweener.removeTweens(this);
			const self:ImaginationHandUI = this;
			TSTweener.addTween(this, {alpha:0, time:!ImgMenuView.instance.hide_close ? .2 : .5, transition:'linear', 
				onComplete:function():void {
					if(parent) parent.removeChild(self);
					TSFrontController.instance.unRegisterRefreshListener(self);
				}
			});
		}
		
		public function refresh():void {
			const lm:LayoutModel = TSModelLocator.instance.layoutModel;
			title_tf.x = Math.max(TITLE_MIN_X, int(lm.loc_vp_w/2 - title_tf.width/2));
			
			select_tf.x = int(lm.loc_vp_w/2 - select_tf.width/2);
			select_tf.y = int(lm.loc_vp_h - select_tf.height - 28);
			select_tf.visible = true;
			
			var g:Graphics = all_masker.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRect(0, 0, lm.overall_w + lm.gutter_w, lm.loc_vp_h);
			
			const draw_w:int = Math.min(CARD_GUIDE_MAX_W, lm.loc_vp_w - CARD_PADD*2);
			const draw_h:int = select_tf.y - (TITLE_MAX_Y + title_tf.height);
			g = card_guide.graphics;
			g.clear();
			g.beginFill(0,0);
			g.drawRect(0, 0, draw_w, draw_h);
			card_guide.x = int(lm.loc_vp_w/2 - card_guide.width/2);
			card_guide.y = int(title_tf.y + title_tf.height - 5);
			
			all_holder.x = lm.gutter_w;
			all_holder.y = lm.header_h;
			all_masker.y = all_holder.y;
			
			//place the cards
			card_holder.x = card_guide.x;
			card_holder.y = int(card_guide.y + card_guide.height/2);
			
			const total:int = card_holder.numChildren;
			var card_ui:ImgCardUI;
			var i:int;
			
			//set the positions
			if(has_seen_cards){
				for(i; i < total; i++){
					card_ui = card_holder.getChildAt(i) as ImgCardUI;
					setCardPosition(card_ui);
				}
			}
			
			//make sure the redeal button is placed smartly
			redeal.x = int(lm.loc_vp_w - redeal.width - 28);
			redeal.y = int(lm.loc_vp_h - redeal.height - 28);
			if(redeal.y <= card_guide.y + CARD_GUIDE_SAFE_H || select_tf.x + select_tf.width >= redeal.x){
				redeal.x = int(lm.loc_vp_w/2 - redeal.width/2);
				redeal.y = int(lm.loc_vp_h - redeal.height - 5);
				if(redeal.visible) select_tf.visible = false;
			}
			
			//make sure the select doesn't look dumb
			if(select_tf.y < card_guide.y + CARD_GUIDE_SAFE_H - 45){
				select_tf.y = int(lm.loc_vp_h - (lm.loc_vp_h - (card_guide.y + CARD_GUIDE_SAFE_H - 45))/2 - select_tf.height/2 - 15);
			}
			
			//if we are running out of space, let's do stuff with the title
			title_tf.alpha = 1;
			if(draw_h < CARD_GUIDE_SAFE_H) title_tf.alpha = draw_h/CARD_GUIDE_SAFE_H;
		}
		
		public function showPurchase(card:ImaginationCard):void {
			//they bought an upgrade, get all fancy!
			const card_ui:ImgCardUI = card_holder.getChildByName('id_'+card.id) as ImgCardUI;
			if(card_ui){
				//zoom it up then show the upgrade
				TSTweener.addTween(card_ui, {
					rotation:20, 
					scaleX:4, 
					scaleY:4, 
					_autoAlpha:0, 
					time:.3, 
					transition:'easeInExpo', 
					onComplete:onPurchaseTweenComplete, 
					onCompleteParams:[card]
				});
				
				current_purchase_id = card.id;
				TipDisplayManager.instance.goAway();
			}
		}
		
		private function onPurchaseTweenComplete(card:ImaginationCard):void {
			//fade out the holder and show the card
			ImaginationPurchaseUpgradeUI.instance.show(card);
			TSTweener.addTween(card_holder, {_autoAlpha:0, time:.2, transition:'linear'});
		}
		
		private function onAssetLoaded(event:Event):void {
			//set our cards mc
			const cards_loader:Loader = MovieClip(event.currentTarget).getChildAt(0) as Loader;
			cards_mc = cards_loader.content as MovieClip;
			showCards();
		}
		
		private function showCards():void {
			if (!cards_mc){
				const cards_loader:MovieClip = new AssetManager.instance.assets.imagination_cards();
				cards_loader.addEventListener(Event.COMPLETE, onAssetLoaded, false, 0, true);
				CONFIG::debugging {
					Console.info('loading imagination_cards')
				}
				
				return;
			}
			
			var i:int;
			var total:int = cards.length;
			var card:ImgCardUI;
			
			//reset pool
			for(i = 0; i < total; i++){
				cards[int(i)].hide();
			}
			
			refresh();
			
			//reset the dealing
			CARDS_TO_DEAL.length = 0;
			
			//display the current ones
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			if(pc && pc.stats){
				if(pc.stats.imagination_hand){
					total = pc.stats.imagination_hand.length;
					for(i = 0; i < total; i++){
						if(cards.length > i){
							card = cards[int(i)];
						}
						else {
							card = new ImgCardUI(cards_mc);
							card.addEventListener(TSEvent.CHANGED, onCardClick, false, 0, true);
							cards.push(card);
							card_holder.addChild(card);
							
							//new card, must mean we gotta deal it in
							CARDS_TO_DEAL.push(card);
						}
						
						card.show(pc.stats.imagination_hand[int(i)]);
						card.alpha = 1;
						card_holder.setChildIndex(card, card_holder.numChildren-1);
					}
				}
				
				//are we able to redeal?
				redeal.enabled = !pc.stats.imagination_shuffled_today;
			}
			
			refresh();
			
			//CARDS_TO_DEAL should have all 3 of our cards on the first time seeing this
			if(!has_seen_cards){
				dealCards(CARDS_TO_DEAL);
			}
		}
		
		private function setCardPosition(card:ImgCardUI):void {
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			const total:int = pc.stats.imagination_hand.length;
			
			if(card.card_data.id == 0 && total > 1){
				card.rotation = card.showing_front ? LEFT_ROTATION : 0;
				card.x = 0;
				card.y = card.showing_front ? TOP_OFFSET : 0;
				card.position = ImgCardUI.POSITION_LEFT;
			}
			else if(card.card_data.id == total-1 && total > 1){
				card.rotation = card.showing_front ? RIGHT_ROTATION : 0;
				card.x = card_guide.width;
				card.y = card.showing_front ? TOP_OFFSET : 0;
				card.position = ImgCardUI.POSITION_RIGHT;
			}
			else {
				card.rotation = 0;
				card.x = int(card_guide.width/2);
				card.y = 0;
				card.position = ImgCardUI.POSITION_CENTER;
			}
		}
		
		private function refreshCards():void {
			var i:int;
			var total:int = cards.length;
			
			for(i = 0; i < total; i++){
				cards[int(i)].refresh();
			}
		}
		
		private function dealCards(cards_to_deal:Vector.<ImgCardUI>):void {
			//animate from off screen to where they already are
			const lm:LayoutModel = TSModelLocator.instance.layoutModel;
			const start_x:int = lm.loc_vp_w/2;
			const start_y:int = lm.loc_vp_h + 100;
			const start_rotation:Number = 90;
			var i:int;
			var total:int = cards_to_deal.length;
			var end_x:int;
			var end_y:int;
			var end_rotation:Number;
			var card:ImgCardUI;
			
			for(i; i < total; i++){
				card = cards_to_deal[int(i)];
				setCardPosition(card);
				end_x = card.x;
				end_y = card.y;
				end_rotation = card.rotation;
				card.x = start_x;
				card.y = start_y;
				card.rotation = start_rotation;
				TSTweener.addTween(card, 
					{
						x:end_x, 
						y:end_y, 
						rotation:end_rotation, 
						time:CARD_ANI_TIME, 
						delay:CARD_ANI_TIME*i,
						onStart:SoundMaster.instance.playSound,
						onStartParams:['CARD_DEAL'+(card.card_data.id+1)],
						onComplete:onDealComplete,
						onCompleteParams:[card, i == total-1]
					}
				);
			}
		}
		
		private function onDealComplete(card:ImgCardUI, is_last:Boolean):void {
			//if this is the last card, clear out the vector
			if(is_last) CARDS_TO_DEAL.length = 0;
			if(!has_seen_cards && is_last) has_seen_cards = true;
		}
		
		private function discardCards(with_delays:Boolean = true):void {
			//there should be something in the CARDS_TO_DEAL vector. Animates it out, then calls dealCards to animate it back in
			const lm:LayoutModel = TSModelLocator.instance.layoutModel;
			const end_x:int = lm.loc_vp_w/2;
			const end_y:int = lm.loc_vp_h + 100;
			const end_rotation:Number = 90;
			var i:int;
			var total:int = CARDS_TO_DEAL.length;
			var card:ImgCardUI;
			var place_x:int;
			
			for(i; i < total; i++){
				card = CARDS_TO_DEAL[int(i)];
				setCardPosition(card);
				place_x = card.x;
				TSTweener.addTween(card, 
					{
						x:end_x, 
						y:end_y, 
						rotation:end_rotation, 
						time:!ImgMenuView.instance.hide_close ? CARD_ANI_TIME : .1, //in newxp, we want this faster
						delay:(with_delays ? CARD_ANI_TIME*i : 0), 
						onComplete:onDiscardComplete,
						onCompleteParams:[card, place_x]
					}
				);
			}
		}
		
		private function onDiscardComplete(card:ImgCardUI, place_x:int):void {
			//once the discard is complete, set the card position to be animated in
			setCardPosition(card);
			card.x = place_x;
			
			//make sure the redeal hand isn't there
			if(hand_redeal.parent) hand_redeal.parent.removeChild(hand_redeal);
			
			//clear out the vector
			CARD_TO_DISCARD.length = 0;
			
			//show the card with the same id as the one we just dumped
			const pc:PC = TSModelLocator.instance.worldModel.pc;
			const card_data:ImaginationCard = pc ? pc.getImaginationCardById(card.card_data.id) : null;
			if(card_data) {
				//deal this fresh new card
				CARD_TO_DISCARD.push(card);
				card.show(card_data);
			}
			dealCards(CARD_TO_DISCARD);
		}
		
		private function onStatsChanged(pc_stats:PCStats):void {
			if(pc_stats.imagination == current_imagination) return;
			current_imagination = pc_stats.imagination;
			
			refreshCards();
		}
		
		private function onCardClick(event:TSEvent):void {
			// not if we are showing the purchase screen
			if (ImaginationPurchaseUpgradeUI.instance.parent) return;
			if (TSTweener.isTweening(this)) return;
			if (block_purchases) return;
			
			const ANIMATION_TIME:Number = .3;
			const card:ImgCardUI = event.data as ImgCardUI;
			
			//if we are showing the front when it's clicked, let's rotate this to 0 while it's flipping
			if(card.showing_front){
				if(card.rotation != 0) TSTweener.addTween(card, {rotation:0, y:0, time:ANIMATION_TIME});
			}
			else if(!card.showing_front && card.position != ImgCardUI.POSITION_CENTER){
				//put it back
				TSTweener.addTween(card, {rotation:(card.position == ImgCardUI.POSITION_LEFT ? LEFT_ROTATION : RIGHT_ROTATION), y:TOP_OFFSET, time:ANIMATION_TIME});
			}
			
			//make sure it's on the top
			card_holder.setChildIndex(card, card_holder.numChildren-1);
			
			//dim and flip over the other cards if they need to be flipped
			var i:int;
			var total:int = card_holder.numChildren;
			var other_card:ImgCardUI;
			var tween_props:Object;
			
			for(i; i < total; i++){
				other_card = card_holder.getChildAt(i) as ImgCardUI;
				tween_props = {time:ANIMATION_TIME};
				if(other_card != card){
					tween_props.alpha = card.showing_front ? .5 : 1;
					if(!other_card.showing_front){
						if(other_card.position != ImgCardUI.POSITION_CENTER){
							tween_props.rotation = other_card.position == ImgCardUI.POSITION_LEFT ? LEFT_ROTATION : RIGHT_ROTATION;
							tween_props.y = TOP_OFFSET;
						}
						other_card.reset(true);
					}
				}
				else {
					tween_props.alpha = 1;
				}
				
				//tween it
				TSTweener.addTween(other_card, tween_props);
			}
			
			//do we need to fade out the select text?
			TSTweener.addTween(select_tf, {alpha:card.showing_front ? .5 : 1, time:ANIMATION_TIME});
		}
		
		private function getSelectedCard():ImgCardUI {
			if (!showing) return null;
			
			var i:int;
			var total:int = card_holder.numChildren;
			var card:ImgCardUI;
			
			for(i; i < total; i++){
				card = card_holder.getChildAt(i) as ImgCardUI;
				if (card.is_buyable) {
					return card;
				}
			}
			
			return null;
		}
		
		public function isCardSelected():Boolean {
			return (getSelectedCard()) ? true : false;
		}
		
		public function buySelectedCard():void {
			var card:ImgCardUI = getSelectedCard();
			if (card) card.buy();
		}
		
		public function unselectSelectedCard():void {
			var card:ImgCardUI = getSelectedCard();
			if (card) card.flip();
		}
		
		private function onRedealClick(event:TSEvent):void {
			//player wants to redeal, let's tell the server!
			ImaginationManager.instance.redeal();
			redeal.enabled = false;
		}
		
		public function closePurchaseScreen():void {
			//they closed the upgrade screen, let's make sure everything still looks ok
			//if we are not showing close options in the iMG menu, we should close it up!
			updateHand();
			if(ImgMenuView.instance.hide_close){
				StageBeacon.setTimeout(ImgMenuView.instance.hide, 1250);
				block_purchases = true;
				select_tf.alpha = 0;
			}

			ImaginationPurchaseUpgradeUI.instance.close();
			TSTweener.addTween(card_holder, {_autoAlpha:1, time:.2, transition:'linear'});
		}
		
		public function get is_blocking_purchases():Boolean { return block_purchases; }
		public function get is_hiding():Boolean { return !showing; }
	}
}