package com.tinyspeck.engine.view.ui.acl
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.acl.ACL;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.port.ACLManager;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.supersearch.SuperSearch;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.TextEvent;
	import flash.text.TextField;

	public class ACLCreateKeyUI extends Sprite
	{
		private static const PADD:uint = 27;
		private static const AVATAR_RADIUS:uint = 20;
		
		private const buddy_tsids_to_exclude:Array = new Array();
		
		private var super_search:SuperSearch = new SuperSearch();
		
		private var choose_tf:TextField = new TextField();
		private var roomate_tf:TextField = new TextField();
		private var success_tf:TextField = new TextField();
		private var success_name_tf:TextField = new TextField();
		private var undo_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var search_holder:Sprite = new Sprite();
		private var roomate_holder:Sprite = new Sprite();
		private var success_holder:Sprite = new Sprite();
		private var avatar_holder:Sprite = new Sprite();
		private var avatar_mask:Sprite = new Sprite();
		private var undo_holder:Sprite = new Sprite();
		
		private var is_undoing:Boolean;
		
		private var _w:int;
		private var _h:int;
		
		public function ACLCreateKeyUI(w:int, h:int){
			_w = w;
			_h = h;
			
			//bg
			var bg_color:uint = CSSManager.instance.getUintColorValueFromStyle('acl_create_key', 'backgroundColor', 0xfafafa);
			var g:Graphics = graphics;
			g.beginFill(bg_color);
			g.drawRect(0, 0, _w, _h);
			
			//tf
			TFUtil.prepTF(choose_tf, false);
			choose_tf.htmlText = '<p class="acl_create_key_choose">Choose a friend you\'d like to give a key to:</p>';
			choose_tf.x = -2;
			search_holder.addChild(choose_tf);
			
			//super search
			super_search.init(SuperSearch.TYPE_BUDDIES);
			super_search.y = int(choose_tf.y + choose_tf.height + 10);
			super_search.width = _w - PADD*2;
			super_search.height = 30;
			super_search.show_images = true;
			super_search.addEventListener(TSEvent.CHANGED, onSearchChange, false, 0, true);
			search_holder.addChild(super_search);
			
			//roomate
			const txt_padd:uint = 12;
			TFUtil.prepTF(roomate_tf);
			roomate_tf.width = _w - PADD*2 - txt_padd*2;
			roomate_tf.x = txt_padd;
			roomate_tf.y = txt_padd - 2;
			roomate_tf.htmlText = '<p class="acl_create_key_roomate">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b>Roommate alert!</b><br>' +
								  'Your friend will have access to everything in your house, including your crops and cabinet.</p>';
			roomate_holder.addChild(roomate_tf);
			
			const tip_DO:DisplayObject = new AssetManager.instance.assets.info_tip();
			tip_DO.x = txt_padd - 1;
			tip_DO.y = txt_padd - 2;
			roomate_holder.addChild(tip_DO);
			
			const roomate_bg_color:uint = CSSManager.instance.getUintColorValueFromStyle('acl_create_key_roomate', 'backgroundColor', 0xe4d9ba);
			g = roomate_holder.graphics;
			g.beginFill(roomate_bg_color);
			g.drawRoundRect(0, 0, _w - PADD*2, int(roomate_tf.y + roomate_tf.height + txt_padd), 8);
			roomate_holder.y = int(super_search.y + super_search.height + 30);
			search_holder.addChildAt(roomate_holder, 0);
			
			search_holder.x = PADD;
			search_holder.y = PADD;
			addChild(search_holder);
			
			//success stuff
			TFUtil.prepTF(success_tf, false);
			success_tf.htmlText = '<p class="acl_create_key_success">Success!</p>';
			success_tf.x = -2;
			success_tf.y = -10;
			success_holder.addChild(success_tf);
			
			//avatar holder
			const avatar_bg_color:uint = CSSManager.instance.getUintColorValueFromStyle('acl_key_given_element_avatar', 'backgroundColor', 0xe5ebeb);
			g = avatar_holder.graphics;
			g.beginFill(avatar_bg_color);
			g.drawCircle(AVATAR_RADIUS, AVATAR_RADIUS, AVATAR_RADIUS);
			avatar_holder.y = int(success_tf.y + success_tf.height - 2);
			avatar_holder.mask = avatar_mask;
			avatar_holder.filters = StaticFilters.black3pxInner_GlowA;
			success_holder.addChild(avatar_holder);
			
			//mask
			g = avatar_mask.graphics;
			g.beginFill(0);
			g.drawCircle(AVATAR_RADIUS, AVATAR_RADIUS, AVATAR_RADIUS);
			avatar_mask.x = avatar_holder.x;
			avatar_mask.y = avatar_holder.y;
			success_holder.addChild(avatar_mask);
			
			//name
			TFUtil.prepTF(success_name_tf);
			success_name_tf.embedFonts = false;
			success_name_tf.x = int(avatar_holder.x + avatar_holder.width + 6);
			success_name_tf.y = int(success_tf.y + success_tf.height - 2);
			success_name_tf.width = int(_w - success_name_tf.x - PADD);
			success_holder.addChild(success_name_tf);
			
			//undo
			TFUtil.prepTF(undo_tf);
			undo_tf.htmlText = '<p class="acl_create_key_undo">Having second thoughts? <b><a href="event:acl_undo">Undo</a></b></p>';
			undo_tf.embedFonts = false;
			undo_tf.width = _w - PADD*2;
			undo_tf.y = 2;
			undo_tf.addEventListener(TextEvent.LINK, onUndoClick, false, 0, true);
			undo_holder.addChild(undo_tf);
			
			var undo_bg:uint = CSSManager.instance.getUintColorValueFromStyle('acl_create_key_undo', 'backgroundColor', 0xffffff);
			var undo_border:uint = CSSManager.instance.getUintColorValueFromStyle('acl_create_key_undo', 'borderColor', 0xf3f3f3);
			g = undo_holder.graphics;
			g.lineStyle(1, undo_border);
			g.beginFill(undo_bg);
			g.drawRoundRect(0, 0, _w - PADD*2, int(undo_tf.height + 4), 8);
			success_holder.addChild(undo_holder);
			
			success_holder.x = PADD;
			success_holder.y = PADD;
			addChild(success_holder);
		}
		
		public function show():void {
			scaleX = scaleY = 1;
			
			//build a list of tsids to exclude from the search (keys we've already given out)
			buddy_tsids_to_exclude.length = 0;
			const acl:ACL = ACLManager.instance.acl;
			var i:int;
			var total:int = acl ? acl.keys_given.length : 0;
			
			for(i; i < total; i++){
				buddy_tsids_to_exclude.push(acl.keys_given[int(i)].pc_tsid);
			}
			
			super_search.buddy_tsids_to_exclude = buddy_tsids_to_exclude;
			super_search.show();
			search_holder.visible = true;
			success_holder.visible = false;
			is_undoing = false;
			
			visible = true;
		}
		
		public function hide():void {
			visible = false;
			
			scaleX = scaleY = .05;
		}
		
		public function showSuccess():void {
			if(!selected_pc_tsid) return;
			const pc:PC = TSModelLocator.instance.worldModel.getPCByTsid(selected_pc_tsid);
			if(!pc) return;
			
			search_holder.visible = false;
			success_holder.visible = true;
			
			//set the headshot
			while(avatar_holder.numChildren) avatar_holder.removeChildAt(0);
			if(pc.singles_url) AssetManager.instance.loadBitmapFromWeb(pc.singles_url+'_50.png', onHeadshotLoad, 'ACL create key');
			
			//set the name/avatar tf
			var name_txt:String = '<p class="acl_create_key_success_name">';
			name_txt += pc.label+'<br>';
			name_txt += '<span class="acl_create_key_success_name_sub">was just sent a key to your house!</span>';
			name_txt += '</p>';
			success_name_tf.htmlText = name_txt;
			
			undo_holder.y = int(success_name_tf.y + success_name_tf.height + 20);
		}
		
		private function onSearchChange(event:TSEvent):void {
			//either they selected or removed a friend
			dispatchEvent(new TSEvent(TSEvent.CHANGED, event.data));
		}
		
		private function onUndoClick(event:TextEvent):void {
			if(is_undoing || !selected_pc_tsid) return;
			is_undoing = true;
			
			//close this view and let the dialog go back to viewing keys
			dispatchEvent(new TSEvent(TSEvent.CLOSE));
			
			//revoke the key from the player
			ACLManager.instance.changeAccess(selected_pc_tsid, false);
		}
		
		private function onHeadshotLoad(filename:String, bm:Bitmap):void {
			while(avatar_holder.numChildren) avatar_holder.removeChildAt(0);
			const pc:PC = TSModelLocator.instance.worldModel.getPCByTsid(selected_pc_tsid);
			if(!pc || (pc && !pc.singles_url)) return;
			
			if(bm && filename == pc.singles_url+'_50.png'){
				bm.scaleX = -1;
				bm.x = bm.width - 11;
				bm.y = -8;
				avatar_holder.addChild(bm);
			}
			else {
				CONFIG::debugging {
					Console.warn('file name not synced--> bm:'+bm+' filename: '+filename+' pc.singles_url+_50.png: '+pc.singles_url+'_50.png');
				}
			}
		}
		
		public function get selected_pc_tsid():String { return super_search.value; }
	}
}