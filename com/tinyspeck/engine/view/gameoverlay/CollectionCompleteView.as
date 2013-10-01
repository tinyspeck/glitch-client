package com.tinyspeck.engine.view.gameoverlay {
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.data.reward.Rewards;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Slug;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	// http://svn.tinyspeck.com/wiki/Level_up_sequence
	
	public class CollectionCompleteView extends BaseScreenView {
		
		/* singleton boilerplate */
		public static const instance:CollectionCompleteView = new CollectionCompleteView();
		
		private const MIN_RIGHT_W:uint = 380;
		private const MARGIN_RIGHT_TOP:int = 50;
		private const TROPHY_WH:uint = 300;
		private const ITEMS_PER_ROW:uint = 5;
		private const ITEM_WH:uint = 40;
		
		private var trophy_tsid:String;
		
		private var left_holder:Sprite = new Sprite();
		private var right_holder:Sprite = new Sprite();
		private var trophy_holder:Sprite = new Sprite();
		private var items_holder:Sprite = new Sprite();
		private var slugs_holder:Sprite = new Sprite();
		
		private var earned_tf:TextField = new TextField();
		private var name_tf:TextField = new TextField();
		private var desc_tf:TextField = new TextField();
		
		private var ok_bt:Button;
		private var shelf:DisplayObject = new AssetManager.instance.assets.shelf_trophy();
		
		private var rewards:Vector.<Reward>;
		private var trophy:ItemIconView;
		
		private var is_trophy_loading:Boolean;
		
		public function CollectionCompleteView() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		override protected function buildBase():void {
			super.buildBase();
			
			all_holder.addChild(left_holder);
			all_holder.addChild(right_holder);
						
			//get color/alpha from CSS
			bg_color = CSSManager.instance.getUintColorValueFromStyle('collection_complete_bg', 'color', 0xdad78f);
			bg_alpha = CSSManager.instance.getNumberValueFromStyle('collection_complete_bg', 'alpha', .9);
			
			//place the shelf on stage
			left_holder.addChild(shelf);
			left_holder.addChild(trophy_holder);
			
			//position the right side holder
			right_holder.y = MARGIN_RIGHT_TOP;

			//textfields
			earned_tf.selectable = name_tf.selectable = desc_tf.selectable = false;
			earned_tf.embedFonts = name_tf.embedFonts = desc_tf.embedFonts = true;
			earned_tf.antiAliasType = name_tf.antiAliasType = desc_tf.antiAliasType = AntiAliasType.ADVANCED;
			earned_tf.autoSize = name_tf.autoSize = desc_tf.autoSize = TextFieldAutoSize.LEFT;
			earned_tf.styleSheet = name_tf.styleSheet = desc_tf.styleSheet = CSSManager.instance.styleSheet;
			earned_tf.filters = name_tf.filters = desc_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			desc_tf.wordWrap = true;
			
			earned_tf.htmlText = '<p class="collection_complete_earned">You earned a sweet trophy!</p>';
			name_tf.y = int(earned_tf.height);
						
			right_holder.addChild(earned_tf);
			right_holder.addChild(name_tf);
			right_holder.addChild(desc_tf);
			
			//button
			ok_bt = new Button({
				label: 'Alllllright!',
				name: 'ok_bt',
				value: 'done',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_DEFAULT
			})
			right_holder.addChild(ok_bt);
						
			ok_bt.addEventListener(MouseEvent.CLICK, onOkClick, false, 0, true);
			ok_bt.filters = StaticFilters.white4px40AlphaGlowA;
			
			//items and slugs
			right_holder.addChild(items_holder);
			right_holder.addChild(slugs_holder);
			
			//handle the rays
			loadRays();
		}
		
		private function loadTrophy():void {
			//put the trophy on the shelf
			SpriteUtil.clean(trophy_holder);
			trophy = new ItemIconView(trophy_tsid, TROPHY_WH);
			trophy_holder.addChild(trophy);
			trophy_holder.x = int(shelf.width/2 - trophy_holder.width/2);
			trophy_holder.y = shelf.height - TROPHY_WH - 40; //40 from bottom to where the trophy sits
			
			is_trophy_loading = true;
		}
		
		override protected function draw():void {
			super.draw();
			
			left_holder.scaleX = left_holder.scaleY = 1;
			left_holder.y = 388 - left_holder.height;
			
			right_holder.x = int(left_holder.width - 10); //overlaps slightly
			
			if (rays.parent) rays.parent.removeChild(rays);
			
			if (all_holder.width > draw_w-20) {
				var left_w_max:int = (draw_w-20) + 10 - right_holder.width;
				left_holder.width = left_w_max;
				left_holder.scaleY = left_holder.scaleX;
				left_holder.y = 388 - left_holder.height;
				right_holder.x = int(left_holder.width - 10); //overlaps slightly
			}
			
			//place the rays behind the shelf
			all_holder.addChildAt(rays, 0);
			
			rays.x = -233;
			var rect:Rectangle = left_holder.getBounds(left_holder.parent);
			rays.x = left_holder.x+ (rect.width/2) - 414;
			rays.y = left_holder.y + rect.height - 280 - Math.max(50, left_holder.scaleY*250) ;
			
			//center the stuff
			all_holder.x = model.layoutModel.gutter_w + int(draw_w/2 - (shelf.width + right_holder.width)/2);
			all_holder.x = Math.max(all_holder.x, 20);
			all_holder.y = int(model.layoutModel.loc_vp_h/2 - shelf.height/2) + 300;
		}
		
		// SHOULD ONLY EVER BE CALLED FROM TSFrontController.instance.tryShowScreenViewFromQ();
		public function show(payload:Object):Boolean {
			if(!super.makeSureBaseIsLoaded()) return false;
			
			//make sure we have the right trophy loaded
			if(trophy_tsid == payload.trophy.class_tsid) {
				if(trophy && !trophy.loaded && !is_trophy_loading) {
					loadTrophy();
					return false;
				} else if(trophy && trophy.loaded){
					is_trophy_loading = false;
				}
			} else {
				trophy_tsid = payload.trophy.class_tsid;
				loadTrophy();
				return false;
			}
			
			//handle the rewards
			var reward_txt:String = '';
			rewards = new Vector.<Reward>(); //clear it
			
			if(payload.rewards){
				rewards = Rewards.fromAnonymous(payload.rewards);
				reward_txt = Rewards.convertToString(rewards)
			}
			
			//add the text
			name_tf.htmlText = '<p class="collection_complete_name">'+payload.name+'</p>';
			desc_tf.htmlText = '<p class="collection_complete_desc">'+payload.status_text+
							   (reward_txt != '' ? ' You get '+reward_txt : '')+ 
							   ' You\'ll find it in your furniture bag.</p>';
						
			//setup the right side
			var g:Graphics = right_holder.graphics;
			g.beginFill(0, 0);
			g.drawRect(0, 0, Math.max(MIN_RIGHT_W, int(name_tf.width)), 5);
			desc_tf.width = 10;
			
			earned_tf.x = int(right_holder.width/2 - earned_tf.width/2);
			name_tf.x = int(right_holder.width/2 - name_tf.width/2);
			
			desc_tf.y = int(name_tf.y + name_tf.height);
			desc_tf.width = right_holder.width;
			
			displaySlugs();
			
			ok_bt.x = int(right_holder.width/2 - ok_bt.width/2);
			ok_bt.y = int(slugs_holder.y + slugs_holder.height) + 20;
			
			items_holder.y = int(ok_bt.y + ok_bt.height) + 25;
			displayIcons(payload.trophy_items);
			
			//set the stuff
			draw();
			animate();
						
			return tryAndTakeFocus(payload);
		}
		
		override protected function animate():void {
			var i:int;
			var slug:Slug;
			var item_icon:ItemIconView;
			var tf:TextField;
			var texts:Vector.<TextField> = new Vector.<TextField>();
			var final_y:int = 388 - left_holder.height;
			var offset:int = 40;
			
			//fade in
			super.animate();
			
			//remove any active tweens
			TSTweener.removeTweens([left_holder]);
			
			//shelf
			left_holder.y = -shelf.height - model.layoutModel.header_h;
			TSTweener.addTween(left_holder, {y:final_y, time:1.5, transition:'easeOutBounce'});
			
			//place the rays behind the shelf
			all_holder.addChildAt(rays, 0);
			
			//textfields
			texts.push(earned_tf, name_tf, desc_tf);
			for(i = 0; i < texts.length; i++){
				tf = texts[int(i)];
				final_y = tf.y;
				tf.alpha = 0;
				tf.y += offset;
				
				TSTweener.addTween(tf, {alpha:1, y:final_y, time:.4, delay:.7 + (i*.2), transition:'easeOutBounce'});
			}
			
			//slugs
			for(i = 0; i < slugs_holder.numChildren; i++){
				slug = slugs_holder.getChildAt(i) as Slug;
				final_y = slug.y;
				slug.alpha = 0;
				slug.y += offset;
				TSTweener.addTween(slug, {y:final_y, alpha:1, time:.3, delay:1 + (i * .2), transition:'easeOutBounce'});
			}
			
			//item icons
			for(i = 0; i < items_holder.numChildren; i++){
				item_icon = items_holder.getChildAt(i) as ItemIconView;
				final_y = item_icon.y;
				item_icon.alpha = 0;
				item_icon.y += offset;
				TSTweener.addTween(item_icon, {y:final_y, alpha:1, time:.3, delay:2 + (i * .2), transition:'easeOutBounce'});
			}
			
			//ok button
			final_y = ok_bt.y;
			ok_bt.alpha = 0;
			ok_bt.y += offset;
			TSTweener.addTween(ok_bt, {y:final_y, alpha:1, time:.4, delay:1.3, transition:'easeOutBounce'});
		}
		
		private function displaySlugs():void {			
			//throws the slugs in the holder and centers them
			var next_x:int;
			var padd:int = 4;
			var i:int;
			var total:int = rewards.length;
			var slug:Slug;
			
			SpriteUtil.clean(slugs_holder);
			
			for(i; i < total; i++){
				if(rewards[int(i)].amount != 0){
					slug = new Slug(rewards[int(i)]);
					slug.x = next_x;
					next_x += int(slug.width + padd);
					slugs_holder.addChild(slug);
				}
			}
			
			//center
			slugs_holder.x = int(right_holder.width/2 - slugs_holder.width/2);
			slugs_holder.y = int(desc_tf.y + desc_tf.height) + 10;
		}
		
		private function displayIcons(trophy_items:Object):void {						
			//loops through the itemstacks and places them there icons
			var current:int = 0;
			var item_icon:ItemIconView;
			var nextX:int = 0;
			var nextY:int = 0;
			var k:String;
			var index:int = 0;
			var rows:int = 0;
			var tsid:String;
			var padding:int = 12;
			var checkmark:DisplayObject;
			
			SpriteUtil.clean(items_holder);
			
			while(trophy_items[index]){				
				current++;
				item_icon = new ItemIconView(trophy_items[index].class_tsid, ITEM_WH);
				item_icon.x = nextX;
				item_icon.y = nextY;
				nextX += ITEM_WH + padding;
				if(current == ITEMS_PER_ROW){
					current = 0;
					nextX = 0;
					nextY += ITEM_WH + padding;
					rows++;
				} 
				items_holder.addChild(item_icon);
				//TipDisplayManager.instance.registerTipTrigger(item_icon);
				
				//add the checkmark
				checkmark = new AssetManager.instance.assets.collection_check();
				checkmark.x = int(ITEM_WH - checkmark.width) + 2;
				checkmark.y = int(ITEM_WH - checkmark.height/2);
				item_icon.addChild(checkmark);
				
				//check if it has sound and add the little play button
				if(trophy_items[index].sound){
					addPlayButton(item_icon, trophy_items[index].sound);
				}
				
				index++;
			}
			
			//center the ones that are remaining
			if(rows > 0){
				var remaining_width:int = (index % ITEMS_PER_ROW) * (ITEM_WH + padding) - padding;
				current = 0;
				for(var i:int = rows * ITEMS_PER_ROW; i < index; i++){
					item_icon = items_holder.getChildAt(i) as ItemIconView;
					item_icon.x = int(items_holder.width/2 - remaining_width/2) + (current * (ITEM_WH + padding));
					current++;
				}
			}
						
			items_holder.x = int(right_holder.width/2 - items_holder.width/2);
		}
		
		private function addPlayButton(item_icon:ItemIconView, sound_location:String):void {			
			var play_button:Sprite = new Sprite();
			play_button.addChild(new AssetManager.instance.assets.item_play_button());
			play_button.x = int(ITEM_WH - play_button.width);
			play_button.y = int(ITEM_WH - play_button.height);
			play_button.name = sound_location; // keep a reference of the sound location
			play_button.visible = false;
			
			//add some mouse action to the icon
			item_icon.buttonMode = item_icon.useHandCursor = true;
			item_icon.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { play_button.visible = true; }, false, 0, true);
			item_icon.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { play_button.visible = false; }, false, 0, true);
			item_icon.addEventListener(MouseEvent.CLICK, playSound, false, 0, true);
			item_icon.addChild(play_button);
		}
		
		private function playSound(event:MouseEvent):void {
			//snag the name of the current target and send it to the sound master
			if(!event.currentTarget.getChildAt(2)) return;
			
			SoundMaster.instance.playSound(event.currentTarget.getChildAt(2).name);
		}
	}
}