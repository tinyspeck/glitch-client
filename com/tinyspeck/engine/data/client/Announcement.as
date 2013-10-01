package com.tinyspeck.engine.data.client{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.quest.AbstractQuestEntity;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.data.reward.Rewards;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.itemstack.ISpecialConfigDisplayer;
	
	import flash.utils.getTimer;

	public class Announcement  extends AbstractQuestEntity {
		
		//{"count":1,"orig_y":-65,"type":"floor_to_pack","dest_slot":1,"item_class":"apple","dest_path":"IM4188QBH17F9","orig_x":102}
		
		public static const WINDOW_OVERLAY:String = 'window_overlay';
		public static const VP_OVERLAY:String = 'vp_overlay';
		public static const VP_CANVAS:String = 'vp_canvas';
		public static const LOCATION_OVERLAY:String = 'location_overlay';
		public static const PC_OVERLAY:String = 'pc_overlay';
		public static const ITEMSTACK_OVERLAY:String = 'itemstack_overlay';
		public static const FAMILIAR_TO_PACK:String = 'familiar_to_pack';
		public static const FAMILIAR_TO_FLOOR:String = 'familiar_to_floor';
		public static const FLOOR_TO_PACK:String = 'floor_to_pack';
		public static const FLOOR_TO_BAG:String = 'floor_to_bag';
		public static const PACK_TO_PACK:String = 'pack_to_pack';
		public static const PACK_TO_BAG:String = 'pack_to_bag';
		public static const BAG_TO_PACK:String = 'bag_to_pack';
		public static const BAG_TO_BAG:String = 'bag_to_bag';
		public static const PACK_TO_FLOOR:String = 'pack_to_floor';
		public static const PACK_TO_PC:String = 'pack_to_pc';
		public static const PC_TO_PACK:String = 'pc_to_pack';
		public static const FLOOR_TO_PC:String = 'floor_to_pc';
		public static const PC_TO_FLOOR:String = 'pc_to_floor';
		public static const XP_STAT:String = 'xp_stat';
		public static const MOOD_STAT:String = 'mood_stat';
		public static const ENERGY_STAT:String = 'energy_stat';
		public static const CURRANTS_STAT:String = 'currants_stat';
		public static const FAVOR_STAT:String = 'favor_stat';
		public static const IMAGINATION_STAT:String = 'imagination_stat';
		public static const QUOINS_STAT:String = 'quoins_stat';
		public static const QUOINS_STAT_MAX:String = 'quoins_stat_max';
		public static const MEDITATION_STAT:String = 'meditation_stat';
		public static const CREDITS_STAT:String = 'credits_stat';
		public static const SUBSCRIBER_STAT:String = 'subscriber_stat';
		public static const QUOIN_GOT:String = 'quoin_got';
		public static const EMOTE:String = 'emote';
		public static const EMOTE_BONUS:String = 'emote_bonus';
		public static const NEW_FAMILIAR_MSGS:String = "new_familiar_msgs";
		public static const PLAY_SOUND:String = "play_sound";
		public static const STOP_SOUND:String = "stop_sound";
		public static const PLAY_MUSIC:String = "play_music";
		public static const STOP_MUSIC:String = "stop_music";
		public static const STOP_ALL_SOUND_EFFECTS:String = "stop_all_sound_effects";
		public static const STOP_ALL_MUSIC:String = "stop_all_music";
		public static const QUEST_REQ_STATE:String = "quest_req_state";
		public static const QUEST_COMPLETED:String = "quest_completed";
		public static const OVERLAY_STATE:String = "overlay_state";
		public static var annc_counter:int;
		
		public var special_config_displayer:ISpecialConfigDisplayer;
		
		public var type:String;
		public var local_uid:String; // used for keeping track of unique anncs
		public var giant:String; // used by Announcement.FAVOR_STAT anncs
		public var duration:int; // used for the overlays
		public var size:String; // used for the overlays: "250" || "100%" ... 250 would fit the swf in a 250 box, 100% would fill the window (both always maintain aspect ratio)
		public var dismissible:Boolean; // if true, a tbd affordance for ending the overlay early will be provided to the user
		public var dismiss_payload:Object;	// if dismissible==true and dismiss_payload is a simple object, a msg of type "overlay_dismissed" will
											// be sent to the GS when the overlay is dismissed, and that message will contain the dismiss_payload
											// object as the value of its payload property.
		public var progress_flip:Boolean //if true the pointy will be drawn above the bar
		public var done_payload:Object; // if this is a simple object, a msg of type "overlay_done" will
										// be sent to the GS when the overlay is done (dismiised by user or not), and that message will contain the done_payload
										// object as the value of its payload property.
		public var done_anncs:Array; // an array of anncs to be run when this annc is done
		public var done_cancel_uids:Array; // an array if annc uids to be cancelled when this annc is over
		public var click_to_advance:Boolean; // if the annc has a text array, this inidicates if clicking steps through the array
		public var no_spacebar_advance:Boolean; // ignored in all cases now, as spacebar is never an advancer
		public var click_to_advance_hubmap_triggered:Boolean = false; // if opening the hubmap shoudl cause a click advance
		public var click_to_advance_hubmap_closed_triggered:Boolean = false; // if closing the hubmap shoudl cause a click advance
		public var click_to_advance_show_text:Boolean; // show the advnace button with text prompt?
		public var click_to_advance_bottom:Boolean; // show the advance button on the bottom?
		public var click_to_advance_bottom_text:String; // custom button label. Defaults to "Click anywhere..."
		public var click_to_advance_bottom_y_offset:int; // if the button Y value needs to be pushed around
		public var delay_ms:int; // how long to wait before starting the annc
		public var locking:Boolean; // if true, user loses control of avatar for the duration
		public var counter_limit:int = 1; // how many times the dismisable bar is able to run (ie. don't close it after one start)
		
		public var state:Object;// corresponds to a scene or animation in the swf, or anything that the start method on an overlay swf wants to handle
		public var config:Object;// used to set config on an configabble item swf
		
		public var count:int; // used for for item animations
		public var item_class:String;
		public var swf_url:String; // if the swf is any old swf, not an item swf, specify with swf_url
		public var is_flv:Boolean; // if the swf_url is actually video, pass is_flv:true in the annc
		public var bubble:Boolean; // used for inlocation overlays
		public var bubble_talk:Boolean; // used for inlocation overlays
		public var bubble_placard:Boolean; // used for inlocation overlays
		public var bubble_price_tag:Boolean; // used for inlocation overlays
		public var bubble_familiar:Boolean; // used for inlocation overlays
		public var bubble_god:Boolean; // used for inlocation overlays
		public var allow_in_locodeco:Boolean; // announcements are generally not allowed in locodeco
		
		// used for item animations
		public var orig_x:int;
		public var orig_y:int;
		public var orig_slot:int;
		public var orig_path:String;
		
		public var dest_x:int;
		public var dest_y:int;
		public var dest_slot:int;
		public var dest_path:String;
		
		// used for the overlays
		public var tf_delta_x:int;
		public var tf_delta_y:int;
		public var width:int;
		public var height:int;
		public var delta_x:int;
		public var delta_x_relative_to_face:Boolean;
		public var delta_y:int;
		public var place_at_bottom:Boolean;
		public var itemstack_tsid:String;
		public var msg:String;
		public var uid:String;
		public var text:Array;
		public var chat_text:Array;
		public var follow:Boolean;
		public var animate_to_top:Boolean;
		public var animate_to_buffs:Boolean;
		public var and_burst:Boolean; // only used when animate_to_buffs:true
		public var and_burst_value:int; // only used when animate_to_buffs:true
		public var and_burst_text:String; // only used when animate_to_buffs:true
		public var at_bottom:Boolean; // adds the LOCATION_OVERLAY below all dynamic stuff in MG or the or PC_OVERLAY under the avatar
									  // OR adds a VP_OVERLAY beneath all dialogs and shit
		public var under_decos:Boolean; // adds the LOCATION_OVERLAY below all decos MG
		public var at_top:Boolean; // adds the PC_OVERLAY or ITEMSTACK_OVERLAY above all overlays with at_top false; adds LOCATION_OVERLAY in SCH
		public var under_itemstack:Boolean; // adds the ITEMSTACK_OVERLAY just under the stack specified by the annc with itemstack_tsid
		public var above_itemstack:Boolean; // adds the ITEMSTACK_OVERLAY just above the stack specified by the annc with itemstack_tsid
		public var in_itemstack:Boolean; // adds the ITEMSTACK_OVERLAY as a child of the ILIV
		public var center_view:Boolean; // when specifiying an item_class, this put the center of the itemIconView at the coords of the overlay (instead of the bottom of the itemIconView)
		public var center_text:Boolean; // when specifiying text, this put the center of the text field at the y
		public var dont_keep_in_bounds:Boolean;
		public var rewards:Vector.<Reward>;
		public var overlay_opacity:OverlayOpacity = new OverlayOpacity();
		public var use_drop_shadow:Boolean;
		public var fade_in_sec:Number = .2;
		public var fade_out_sec:Number = .4;
		public var text_fade_delay_sec:Number = 0; //how long do we wait to fade in the text
		public var text_fade_sec:Number = 0; //how long for the text to fade in
		public var background_color:String;
		public var background_alpha:Number = 1;
		public var rotation:int = 0;
		
		// If the overlay specifics an item_class, not a swf or flv, this governs if the scaling is done by item swf stage area (or, the default display area of the firest frame of the state passed)
		// If the overlay does not specify a size or width or height, then scale_to_stage:true will leave the thing displayed at it's native size
		public var scale_to_stage:Boolean;
		
		public var text_filter_name:String;
		public var text_filterA:Array;
		
		public var overlay_mouse:OverlayMouse;
		public var show_text_shadow:Boolean = true;
		public var word_progress:WordProgress; //used for word based progress bars
		
		//used for stat and quoin anncments
		public var delta:int;
		public var quoin_shards:Array;
		
		// used for emote anncs of emote type 'hi'
		public var emote_shards:Array;
		public var accelerate:Boolean;
		// used for emotes
		public var variant:String;
		public var variant_color:String;
		public var emote:String;
		
		public var allow_bubble:Boolean; // if true on an itemstack_overlay, we will not call liv.getRidOfBubble() 
		
		public var position_from_center_of_vp:Boolean;
		
		// used for quoin animation anncments and overlays
		public var x:String;
		public var y:String;
		public var top_y:String;
		public var pc_tsid:String;
		
		// used for emotes
		public var other_pc_tsid:String;
		public var emote_bonus_mood_granted:Object;
		
		// used for quoin animation anncments
		public var stat:String;
		
		// used for new_familiar_msgs
		public var num:int;
		
		
		public var sync_sound:String;
		
		// used for play_sound/stop_sound:
		public var sound:String;
		public var is_exclusive:Boolean;
		public var allow_multiple:Boolean;
		
		// used for play_music/stop_music:
		public var mp3_url:String;
		public var fade:Number = 0;
		public var loop_count:Number = 0; // also for flvs
		
		// used for quest announcements
		public var quest_id:String;
		public var req_id:String;
		public var status:Object;
		public var completed:Boolean;
		
		public var client_received:int = getTimer();
		public var client_all_ready:int;
		public var client_faded_in:int;
		public var client_finished:int;
		public var client_done:int;
		
		public var canvas:Object; // an object that defines how the LCV should be drawn; only for VP_CANVAS anncs
		
		// only for vp_overlay announces
		public var corner:String; // allowed values are in allowed_corners
		public var corner_offset_x:int;
		public var corner_offset_y:int;
		public static var allowed_corners:Array = ['tl', 'tr', 'br', 'bl'];
		// end only for vp_overlay announces
		
		public var over_pack:Boolean;
		
		//used for gardens
		public var plot_id:int = -1;
		
		public var h_flipped:Boolean = false;
		public var hide_in_snaps:Boolean = false;

		public function Announcement(hashName:String)
		{
			super(hashName);
		}
		
		public static function parseMultiple(A:Array):Vector.<Announcement> {
			var V:Vector.<Announcement> = new Vector.<Announcement>;
			for(var i:int=0;i<A.length;i++){
				V[int(i)] = fromAnonymous(A[int(i)]);
				CONFIG::debugging {
					if (Console.priOK('276')) {
						try {
							Console.dir(A[int(i)], TSModelLocator.instance.flashVarModel.show_tree_str);
						} catch(err:Error) {
							Console.warn(err);
						}
					} else if (Console.priOK('898') && A[int(i)].type && A[int(i)].type.indexOf('_overlay') != -1) {
						try {
							Console.dir(A[int(i)], TSModelLocator.instance.flashVarModel.show_tree_str);
						} catch(err:Error) {
							Console.warn(err);
						}
					}
				}
			}
			return V;
		}
		
		public static function fromAnonymous(object:Object):Announcement {
			// add in a special truly unique id for tracking these bitches
			object.local_uid = (annc_counter++)+'_annc'+((object.uid) ? '_UID:'+object.uid : '');
			var annc:Announcement = new Announcement('nun');
			
			// location overlays need a different default for dont_keep_in_bounds!
			if (object.type == Announcement.LOCATION_OVERLAY) {
				annc.dont_keep_in_bounds = true;
			}
			
			for(var i:String in object){
				if(i == 'state'){
					if (String(object[i]).indexOf('-') == 0) {
						annc.state = String(object[i]).substr(1);
						annc.h_flipped = true;
					} else {
						annc[i] = object[i];
					}
				}else if(i == 'rewards'){
					annc.rewards = Rewards.fromAnonymous(object[i]);
				}else if(i == 'mouse'){
					annc.overlay_mouse = OverlayMouse.fromAnonymous(object[i]);
				}else if(i == 'opacity'){
					if(isNaN(object[i])){
						annc.overlay_opacity = OverlayOpacity.fromAnonymous(object[i]);
					}
					else {
						annc.overlay_opacity.opacity = annc.overlay_opacity.opacity_end = object[i];
					}
				}else if(i == 'word_progress'){
					annc.word_progress = WordProgress.fromAnonymous(object[i]);
				}else if(i in annc){
					annc[i] = object[i];
				}else{
					resolveError(annc,object,i);
					//Console.warn('unknown prop of Announcement:'+i);
				}
			}
			
			/*if (annc.uid == 'orb_attack_P001') {
				annc.delta_y = -113;
				annc.swf_url = 'http://c2.glitch.bz/overlays%2F2011-07-26%2F1311711260_1617.swf';
			}*/
			
			//Console.info('Announcement type: '+annc.type);
			return annc;
		}
		
		public function toString():String {
			var str:String = "[Announcement type:"+type;
			
			//str += ", ";
			//str += "local_uid:" + String(local_uid);
			
			if (uid) { 
				str += ", ";
				str += "uid:" + String(uid);
			}
			
			if (pc_tsid) { 
				str += ", ";
				str += "pc_tsid:" + String(pc_tsid);
			}
			
			if (itemstack_tsid) { 
				str += ", ";
				str += "itemstack_tsid:" + String(itemstack_tsid);
				
				var item:Item = TSModelLocator.instance.worldModel.getItemByItemstackId(itemstack_tsid);
				if (item) {
					str += " (" + item.tsid + ")";
				}
				
			}
			
			if (item_class) { 
				str += ", ";
				str += "item_class:" + String(item_class);
			}
			
			if (swf_url) { 
				str += ", ";
				str += "swf_url:" + String(swf_url);
			}
			
			if (text) { 
				str += ", ";
				str += "text:" + String(text);
			}
			
			str += "]";
			return str;
		}
	}
}
/*
// Animations as announcements 
{
	changes: {...}
	announcements: [
		{
			type: "floor_to_pack",
			orig_x: 0,
			orig_y: 1000,
			dest_path: "PATH/TO/SLOT/",
			dest_slot: "2",
			count: 1,
			item_class: "apple"
		},
		
		{
			type: "floor_to_pack",
			orig_x: 0,
			orig_y: 1000,
			dest_path: "PATH/TO/SlOT/",
			dest_slot: "3",
			count: 2,
			item_class: "apple"
		},
		
		{
			type: "pack_to_pack",
			orig_path: "PATH/TO/SlOT/",
			orig_slot: "1",
			dest_path: "PATH/TO/SlOT/",
			dest_slot: "4",
			count: 2,
			item_class: "banana"
		},
		
		{
			type: "pack_to_floor",
			orig_path: "PATH/TO/SlOT/",
			orig_slot: "3",
			dest_x: 0,
			dest_y: 1000,
			count: 8,
			item_class: "orange"
		}
	]
}
*/