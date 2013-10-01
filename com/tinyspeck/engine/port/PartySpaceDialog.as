package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.party.PartySpace;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TextEvent;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.text.TextField;

	public class PartySpaceDialog extends BigDialog
	{
		/* singleton boilerplate */
		public static const instance:PartySpaceDialog = new PartySpaceDialog();
		
		private static const IMG_H:uint = 100;
		private static const BUDDY_COUNT:uint = 3; //how many of your buddies (if any) to show in the party goers
		
		private const your_buddies:Vector.<PC> = new Vector.<PC>();
		
		private var energy_bt:Button;
		private var token_bt:Button;
		private var img_loader:Loader = new Loader();
		private var img_req:URLRequest = new URLRequest();
		private var loaderContext:LoaderContext = new LoaderContext(true);
		private var img_glow:GlowFilter = new GlowFilter();
		private var img_shadow:DropShadowFilter = new DropShadowFilter();
		
		private var foot_tf:TextField = new TextField();
		private var no_interest_tf:TSLinkedTextField = new TSLinkedTextField();
		private var location_tf:TextField = new TextField();
		private var summons_tf:TextField = new TextField();
		private var desc_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var all_holder:Sprite = new Sprite();
		private var img_holder:Sprite = new Sprite();
		private var img_mask:Sprite = new Sprite();
		
		private var is_built:Boolean;
		
		public function PartySpaceDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = 473;
			_head_min_h = 60;
			_foot_min_h = 125;
			_draggable = true;
			_base_padd = 20;
			_title_padd_left = _base_padd + 2; //visual tweak
			
			_construct();
		}
		
		private function buildBase():void {
			//buttons
			energy_bt = new Button({
				name:'energy',
				size:Button.SIZE_TINY,
				type:Button.TYPE_MINOR
			});
			energy_bt.addEventListener(TSEvent.CHANGED, onEnergyClick, false, 0, true);
			_foot_sp.addChild(energy_bt);
			
			token_bt = new Button({
				name:'token',
				label:'Yes, use a token',
				size:Button.SIZE_TINY,
				type:Button.TYPE_MINOR
			});
			token_bt.addEventListener(TSEvent.CHANGED, onTokenClick, false, 0, true);
			_foot_sp.addChild(token_bt);
			
			_foot_sp.visible = true;
			
			//tfs
			TFUtil.prepTF(foot_tf, false);
			foot_tf.htmlText = '<p class="party_space_footer">Would you like to open a portal and jump to the party space?</p>';
			foot_tf.x = int(_w - foot_tf.width - _base_padd);
			foot_tf.y = 10;
			_foot_sp.addChild(foot_tf);
			
			TFUtil.prepTF(no_interest_tf, false, {textDecoration:'none'});
			no_interest_tf.htmlText = '<a class="party_space_no_interest" href="event:">Not interested</a>';
			no_interest_tf.addEventListener(TextEvent.LINK, onNoInterestClick, false, 0, true);
			no_interest_tf.x = foot_tf.x;
			_foot_sp.addChild(no_interest_tf);
			
			TFUtil.prepTF(summons_tf, true);
			summons_tf.embedFonts = false;
			summons_tf.width = 400;
			_foot_sp.addChild(summons_tf);
			
			TFUtil.prepTF(location_tf, false);
			all_holder.addChild(location_tf);
			
			
			TFUtil.prepTF(desc_tf);
			desc_tf.embedFonts = false;
			desc_tf.width = _w - _base_padd*2;
			all_holder.addChild(desc_tf);
			
			//img stuff
			var g:Graphics = img_mask.graphics;
			g.beginFill(0);
			g.drawRoundRect(0, 0, _w - _base_padd*2 - _border_w, IMG_H, 6);
			img_holder.mask = img_mask;
			all_holder.addChild(img_mask);
			all_holder.addChild(img_holder);
			img_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImgComplete, false, 0, true);
			img_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onImgError, false, 0, true);
			
			//filters
			img_glow.inner = true;
			img_glow.color = 0xffffff;
			img_glow.blurX = img_glow.blurY = 25;
			img_glow.alpha = .22;
			
			img_shadow.inner = true;
			img_shadow.angle = 90;
			img_shadow.distance = 0;
			img_shadow.blurX = img_shadow.blurY = 2;
			img_shadow.alpha = .7;
			
			img_holder.filters = [img_glow, img_shadow];
			
			all_holder.x = _base_padd;
			all_holder.y = _base_padd - 12;
			_scroller.body.addChild(all_holder);
			
			is_built = true;
		}
		
		override public function start():void {
			if (parent) return;
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			
			const party_space:PartySpace = PartySpaceManager.instance.current_party;
			if(!party_space){
				CONFIG::debugging {
					Console.warn('Missing the current_party from the manager, RUH ROH');
				}
				return;
			}
			
			//title
			_setTitle('A party space is open!');
			
			//energy button value
			energy_bt.label = 'Yes, use '+StringUtil.formatNumberWithCommas(party_space.energy_cost)+' energy';
			
			//show the location
			location_tf.htmlText = '<p class="party_space_loc">Location: <b>'+party_space.location_name+'</b></p>';
			
			//prep the image holder
			img_holder.y = int(location_tf.y + location_tf.height + 5);
			img_mask.y = img_holder.y;
			showImg(party_space.img_url);
			
			//populate the body text
			desc_tf.y = img_mask.y + img_mask.height + 18;
			showBody(party_space);
			
			//listen to stuff
			TeleportationDialog.instance.addEventListener(TSEvent.CHANGED, onTeleportationChange, false, 0, true);
			model.worldModel.registerCBProp(onStatsChanged, "pc", "stats");
			
			super.start();
		}
		
		private function showBody(party_space:PartySpace):void {
			//this will populate the description as well as letting you know which cool kids have joined the party already
			your_buddies.length = 0;
			
			const rsm:RightSideManager = RightSideManager.instance;
			
			var txt:String = party_space.desc;
			var i:int;
			var pc:PC;
			
			if(party_space.pcs.length != 0){
				txt += '<br><br>';
				
				//any of these our buddies?
				for(i = 0; i < party_space.pcs.length; i++){
					pc = party_space.pcs[int(i)];
					if(your_buddies.length < BUDDY_COUNT && model.worldModel.getBuddyByTsid(pc.tsid)){
						your_buddies.push(pc);
					}
				}
				
				//if not at BUDDY_COUNT fill up with any unknowns
				if(your_buddies.length < BUDDY_COUNT){
					for(i = 0; i < party_space.pcs.length; i++){
						pc = party_space.pcs[int(i)];
						if(your_buddies.length < BUDDY_COUNT && your_buddies.indexOf(pc) == -1){
							your_buddies.push(pc);
						}
					}
				}
				
				//format the player names
				for(i = 0; i < your_buddies.length; i++){
					pc = model.worldModel.getPCByTsid(your_buddies[int(i)].tsid) ? model.worldModel.getPCByTsid(your_buddies[int(i)].tsid) : your_buddies[int(i)];
					txt += '<a class="'+rsm.getPCCSSClass(pc.tsid)+'" href="event:'+TSLinkedTextField.LINK_PC+'|'+pc.tsid+'"><b>'+pc.label+'</b></a>' + (i != your_buddies.length-1 ? ', ' : '');
				}
				
				var other_count:int = Math.max(0, party_space.pcs.length - your_buddies.length);
				var other_txt:String = other_count > 0 ? ' and '+other_count+(other_count != 1 ? ' others are ' : ' other is ') : ' are ';
				
				txt += other_txt + 'currently in ' + party_space.location_name + ', partying.';
			}
			
			desc_tf.htmlText = '<p class="party_space_desc">'+txt+'</p>';
		}
		
		private function showImg(url:String):void {
			SpriteUtil.clean(img_holder);
			if(!url) return;
			
			img_req.url = url;
			img_loader.load(img_req, loaderContext);
		}
		
		override protected function _jigger():void {
			super._jigger();
			
			const pc:PC = model.worldModel.pc;
			const party_space:PartySpace = PartySpaceManager.instance.current_party;
			if(!pc || !party_space) return;
			
			//button stuff
			energy_bt.x = _w - energy_bt.width - _base_padd;
			energy_bt.y = foot_tf.y+foot_tf.height+10; //_foot_min_h - energy_bt.height - _base_padd + 4
			token_bt.x = energy_bt.x - token_bt.width - 14;
			token_bt.y = energy_bt.y;
			
			no_interest_tf.y = energy_bt.y + (energy_bt.height/2 - no_interest_tf.height/2);
			
			//can they even use the buttons?
			energy_bt.disabled = !(pc && pc.stats && pc.stats.energy.value >= party_space.energy_cost);
			energy_bt.tip = !energy_bt.disabled ? null : {txt:'You need more energy!', pointer:WindowBorder.POINTER_BOTTOM_CENTER};
			token_bt.disabled = !(pc && pc.teleportation && pc.teleportation.tokens_remaining > 0);
			token_bt.tip = !token_bt.disabled ? null : {txt:'You are out of tokens. Click to get more!', pointer:WindowBorder.POINTER_BOTTOM_CENTER};
			
			var summons_txt:String;
			if (energy_bt.disabled && token_bt.disabled) {
				summons_txt = '<p class="party_space_summons_red">Since you don’t have enough energy and have no tokens, you must '+
								'have someone who’s already in the party summon you.</p>';
			} else {
				summons_txt = '<p class="party_space_summons">(You can also have someone who’s already in the party summon you.)</p>';
			}
			summons_tf.htmlText = summons_txt;
			summons_tf.y = token_bt.y+token_bt.height+10;
			summons_tf.x = Math.round((_w-summons_tf.width)/2);
			
			_body_h = all_holder.y + all_holder.height + _base_padd;
			_scroller.h = _body_h;
			_foot_sp.y = _head_h + _body_h;
			_h = _head_h + _body_h + _foot_h;
			_draw();
			
			//
			_scroller.refreshAfterBodySizeChange();
			//super._jigger();
		}
		
		override public function end(release:Boolean):void {
			if(!parent) return;
			super.end(release);
			
			//stop listening to stuff
			TeleportationDialog.instance.removeEventListener(TSEvent.CHANGED, onTeleportationChange);
			model.worldModel.unRegisterCBProp(onStatsChanged, "pc", "stats");
		}
		
		private function onImgComplete(event:Event):void {
			img_holder.addChild(img_loader);
			_jigger();
		}
		
		private function onImgError(event:IOErrorEvent):void {
			//dump it the console for now
			CONFIG::debugging {
				Console.warn('Error loading the img: '+img_req.url+' Error txt: '+event.text);
			}
		}
		
		private function onEnergyClick(event:TSEvent):void {
			if(energy_bt.disabled) return;
			
			PartySpaceManager.instance.respond(true, false);
		}
		
		private function onTokenClick(event:TSEvent):void {
			if(token_bt.disabled){
				TSFrontController.instance.openTokensPage();
			}
			else {
				PartySpaceManager.instance.respond(false, true);
			}
		}
		
		private function onNoInterestClick(event:TextEvent):void {
			PartySpaceManager.instance.respond(false, false);
			end(true);
		}
		
		private function onStatsChanged(pc_stats:PCStats):void {
			_jigger();
		}
		
		private function onTeleportationChange(event:TSEvent):void {
			_jigger();
		}
		
		override protected function closeFromUserInput(e:Event=null):void {
			PartySpaceManager.instance.respond(false, false);
			super.closeFromUserInput(e);
		}
	}
}