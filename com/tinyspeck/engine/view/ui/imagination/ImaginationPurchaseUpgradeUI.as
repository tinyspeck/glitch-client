package com.tinyspeck.engine.view.ui.imagination
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.pc.ImaginationCard;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingImaginationPurchaseConfirmedVO;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.IRefreshListener;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.MathUtil;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.SkillIcon;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;

	public class ImaginationPurchaseUpgradeUI extends Sprite implements IRefreshListener
	{	
		/* singleton boilerplate */
		public static const instance:ImaginationPurchaseUpgradeUI = new ImaginationPurchaseUpgradeUI();
		
		private static const TEXT_PADD:uint = 40;
		private static const ITEM_WH:uint = 90;
		private static const BT_LABELS:Array = [
			'Super!',
			'Great News',
			'Exciting!',
			'Wonderful!',
			'Stellar',
			'Superb',
			'Lovely',
			'Amazing!',
			'Golly',
			'Gawsh!',
			'Awesome!',
			'Neat',
			'Fresh!',
			'Sweet!',
			'Tight!',
			'Aiight',
			'Awww Yeah!',
			'Splendid',
			'Spectacular',
			'Indubitably',
			'Sublime',
			'Miraculous!',
			'Fantabulous',
			'Stupendulous!',
			'Gramazing',
			'Superific!',
			'Awesomazing',
			'Awesomezors',
			'Magnilliant',
			'Awesome Sauce',
			'Ridonkulous!',
			'Cray Cray',
			'Splentaculous!',
			'Brill!',
			'coolcoolcool',
			'Seriously?',
			'Me Gusta!',
			'Not Bad!',
			'Fuuuuuhhhhh!',
			'OMG!',
			'No way!',
			'Wow!',
			'Brilliant.',
			'Thanks!',
			'I can haz upgrade.',
			'True Story!',
			'You don’t say?',
			'WAT?!',
			'Kowabunga!',
			'Hot Damn!',
			'Yeah you did',
			'Well I’ll be ...',
			'Groovy baby!',
			'Oh you!',
			'Huzzah!',
			'Niiiiiice!',
			'Thanks, Kump!',
			'Great scott!',
			'Hot cherries!',
			'Bump it!',
			'Like A Boss!',
			'Impossibru!',
			'Yowza!',
			'I say!',
			'Tut Tut!',
			'Glorious!',
			'Rad!',
			'Inconceivable!',
			'S(iiiii)ick!',
			'Unbelievable!',
			'That’s hot',
			'Wicked!',
			'Tiiriffic',
			'Crazy',
			'Win!',
			'Holy Moly!',
			'Sugoi!'
		];
		
		private static var cards_mc:MovieClip;
		
		private var bg:Sprite = new Sprite();
		private var all_holder:Sprite = new Sprite();
		private var item_holder:Sprite = new Sprite();
		private var art_holder:Sprite = new Sprite();
		
		private var got_it_tf:TextField = new TextField();
		private var title_tf:TextField = new TextField();
		private var body_tf:TextField = new TextField();
		private var item_tf:TextField = new TextField();
		
		private var skill_icon:SkillIcon;
		private var current_card:ImaginationCard;
		private var close_bt:Button;
		private var item_icon:ItemIconView;
		private var drop_filterA:Array;
		private var art_filterA:Array;
		
		private var cloud_data:BitmapData;
		
		private var bt_label_index:int = -1;
		
		private var is_built:Boolean;
		
		public function ImaginationPurchaseUpgradeUI(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		private function buildBase():void {
			//load the asset straight away if it's not already loaded
			if(!cards_mc){
				const cards_loader:MovieClip = new AssetManager.instance.assets.imagination_cards();
				cards_loader.addEventListener(Event.COMPLETE, onAssetLoaded, false, 0, true);
			}
			
			//reapeating clouds
			const clouds_DO:DisplayObject = new AssetManager.instance.assets.repeating_clouds();
			if (cloud_data) cloud_data.dispose();
			cloud_data = new BitmapData(clouds_DO.width, clouds_DO.height);
			cloud_data.draw(clouds_DO);
			addChild(bg);
			
			//will hold the card art
			drop_filterA = StaticFilters.copyFilterArrayFromObject({alpha:.2, distance:4}, StaticFilters.black3px90Degrees_DropShadowA);
			const glow_filterA:Array = StaticFilters.copyFilterArrayFromObject({alpha:.75, blurX:125, blurY:125, strength:2}, StaticFilters.white4px40AlphaGlowA);
			art_filterA = drop_filterA.concat(glow_filterA);
			all_holder.addChild(art_holder);
			
			//tfs
			TFUtil.prepTF(got_it_tf, false);
			got_it_tf.htmlText = '<p class="imagination_purchase_upgrade"><span class="imagination_purchase_upgrade_got">Got it!</span></p>';
			got_it_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			got_it_tf.x = -int(got_it_tf.width/2);
			all_holder.addChild(got_it_tf);
			
			TFUtil.prepTF(title_tf);
			title_tf.y = int(got_it_tf.height - 8);
			title_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			all_holder.addChild(title_tf);
			
			TFUtil.prepTF(body_tf);
			body_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			all_holder.addChild(body_tf);
			
			TFUtil.prepTF(item_tf, false);
			item_tf.htmlText = '<p class="imagination_purchase_upgrade"><span class="imagination_purchase_upgrade_item">And also:</span></p>';
			item_tf.y = int(ITEM_WH/2 - item_tf.height/2);
			item_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			item_holder.addChild(item_tf);
			all_holder.addChild(item_holder);
			
			//close bt
			close_bt = new Button({
				name: 'close',
				label: 'Cool beans',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR
			});
			close_bt.addEventListener(TSEvent.CHANGED, onCloseClick, false, 0, true);
			all_holder.addChild(close_bt);
			
			addChild(all_holder);
			
			is_built = true;
		}
		
		public function show(card:ImaginationCard):void {
			if(!is_built) buildBase();
			current_card = card;
			
			alpha = 0;
			TSTweener.removeTweens(this);
			TSTweener.addTween(this, {alpha:1, time:.2, transition:'linear'});
			
			//set the title / body
			title_tf.htmlText = '<p class="imagination_purchase_upgrade"><span class="imagination_purchase_upgrade_title">'+card.name+'</span></p>';
			body_tf.htmlText = '<p class="imagination_purchase_upgrade"><span class="imagination_purchase_upgrade_body">'+card.desc+'</span></p>';
			
			SpriteUtil.clean(art_holder);
			setArt();
			setItem();
			setCloseButton();
			
			//play a sound to celebrate
			SoundMaster.instance.playSound('YOU_WIN');
			
			//add to the viewport and listen for refreshes
			TSFrontController.instance.getMainView().addView(this, true);
			TSFrontController.instance.registerRefreshListener(this);
			refresh();
		}
		
		public function hide():void {
			TSTweener.removeTweens(this);
			var self:ImaginationPurchaseUpgradeUI = this;
			TSTweener.addTween(this, {alpha:0, time:.2, transition:'linear',
				onComplete:function():void {
					if(self.parent) self.parent.removeChild(self);
					TSFrontController.instance.unRegisterRefreshListener(self);
				}
			});
		}
		
		public function refresh():void {
			if(!is_built || !parent || !current_card) return;
			const lm:LayoutModel = TSModelLocator.instance.layoutModel;
			const is_keepable:Boolean = current_card.config.bg == 'bg_keepable';
			var g:Graphics = bg.graphics;
			g.clear();
			if(!is_keepable){
				g.beginBitmapFill(cloud_data);
			}
			else {
				//keepable card, draw the background as white
				g.beginFill(0xffffff);
			}
			g.drawRoundRectComplex(0, 0, lm.loc_vp_w, lm.loc_vp_h, lm.loc_vp_elipse_radius/2, 0, lm.loc_vp_elipse_radius/2, 0);
			
			//make sure the text is good
			const text_w:int = lm.loc_vp_w - TEXT_PADD*2;
			title_tf.width = text_w;
			title_tf.x = -int(title_tf.width/2);
			
			art_holder.y = int(title_tf.y + title_tf.height - (!is_keepable ? 65 : 35));
			if(is_keepable && current_card.config.hide_front_name){
				//art is probably lower since there is nothing on the front, let's nudge it up
				art_holder.y -= 20;
			}
			
			body_tf.width = text_w - TEXT_PADD*2; //MOAR PADDING
			body_tf.x = -int(body_tf.width/2);
			body_tf.y = int(title_tf.y + title_tf.height + (!is_keepable ? 155 : 190));
			
			item_holder.y = int(body_tf.y + body_tf.height + 5);
			
			close_bt.y = item_holder.y + (item_holder.visible ? item_holder.height : 0) + 10;
			
			all_holder.x = int(lm.loc_vp_w/2);
			all_holder.y = int(lm.loc_vp_h/2 - (close_bt.y + close_bt.height)/2);
			
			y = lm.header_h;
			x = lm.gutter_w;
		}
		
		private function setArt():void {
			if(!cards_mc){
				//no cards yet, try again real soon
				StageBeacon.waitForNextFrame(setArt);
				return;
			}
			
			//get the art out of the card
			const is_keepable:Boolean = current_card.config.bg == 'bg_keepable';
			const art:MovieClip = cards_mc.getAssetByName(current_card.config.art);
			if(art) art_holder.addChild(art);
			art_holder.x = -int(art_holder.width/2);
			art_holder.filters = !is_keepable ? art_filterA : null;
			
			refresh();
		}
		
		private function setItem():void {
			SpriteUtil.clean(item_holder, true, 1);
			const has_item:Boolean = current_card.config && current_card.config.item_tsid && current_card.config.bg != 'bg_keepable';
			
			//add the item to the holder
			if(has_item){
				item_icon = new ItemIconView(current_card.config.item_tsid, ITEM_WH);
				item_icon.x = int(item_tf.width + 15);
				item_icon.filters = drop_filterA;
				item_holder.addChild(item_icon);
			}
			item_holder.visible = has_item;
			item_holder.x = -int(item_holder.width/2);
		}
		
		private function setCloseButton():void {
			//this will pick a random string for the close button
			if(bt_label_index == -1){
				bt_label_index = MathUtil.randomInt(0, BT_LABELS.length-1);
			}
			else {
				//move the index forward
				bt_label_index++;
				if(bt_label_index == BT_LABELS.length) bt_label_index = 0;
			}
			
			close_bt.label = BT_LABELS[int(bt_label_index)];
			close_bt.x = -int(close_bt.width/2);
		}
		
		private function onCloseClick(event:TSEvent):void {
			SoundMaster.instance.playSound('CLICK_SUCCESS');
			ImaginationHandUI.instance.closePurchaseScreen();
		}
		
		// only to be called from ImaginationHandUI.instance.closePurchaseScreen
		public function close():void {
			//hide this
			hide();
			
			// tell the GS we are done!
			TSFrontController.instance.genericSend(new NetOutgoingImaginationPurchaseConfirmedVO(current_card ? current_card.class_tsid : null));
		}
		
		private function onAssetLoaded(event:Event):void {
			//set our cards mc
			const cards_loader:Loader = MovieClip(event.currentTarget).getChildAt(0) as Loader;
			cards_mc = cards_loader.content as MovieClip;
		}
	}
}