package com.tinyspeck.engine.model
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ScreenViewQueueVO;
	import com.tinyspeck.engine.data.location.Door;
	import com.tinyspeck.engine.data.location.SignPost;
	import com.tinyspeck.engine.data.map.MapPathInfo;
	import com.tinyspeck.engine.model.signals.AbstractPropertyProvider;
	import com.tinyspeck.engine.port.TSSprite;
	import com.tinyspeck.engine.util.BoundedAverageValueTracker;
	import com.tinyspeck.engine.util.GetInfoVO;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.geo.SignpostSignView;
	import com.tinyspeck.engine.view.renderer.RenderMode;
	
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;
	
	public class StateModel extends AbstractPropertyProvider
	{
		public static const DRAG_DIST_REQUIRED:uint = 3;
		
		/** True when we've saved the location in a session, but it hasn't been snapped since the save */
		CONFIG::god public var loc_saved_but_not_snapped:Boolean = false;
		public var open_menu_when_one_click_is_disabled:Boolean = true;
		
		private var _status_bubbles_disabled:Boolean = false;
		private var _all_bubbles_disabled:Boolean = false;

		public function get all_bubbles_disabled():Boolean {
			return _all_bubbles_disabled;
		}

		public function set all_bubbles_disabled(value:Boolean):void {
			_all_bubbles_disabled = value;
		}
		
		private var _location_interactions_disabled:Boolean = false;

		public function get location_interactions_disabled():Boolean {
			return _location_interactions_disabled;
		}

		public function set location_interactions_disabled(value:Boolean):void {
			_location_interactions_disabled = value;
		}

		private var _locodeco_loading:Boolean = false;
		private var _hand_of_god:Boolean = false;
		private var _decorator_mode:Boolean = false;
		public var can_decorate:Boolean = false;
		public var can_cultivate:Boolean = false;
		private var _chassis_mode:Boolean = false;
		private var _info_mode:Boolean = false;
		private var _cult_mode:Boolean = false;
		private var _editing:Boolean = false;
		private var _editing_unsaved:Boolean = false;
		private var _editing_requesting_lock:Boolean = false;
		private var _editing_saving_changes:Boolean = false;
		
		public var newbie_chose_new_avatar:Boolean = false;
		
		public var no_itemstack_bubbles:Boolean = false;
		
		public var seen_deco_disclaimer_dialog_this_session:Boolean = false;
		CONFIG::god public var urquake:Boolean;
		public var in_camera_control_mode:Boolean;
		public const camera_control_pt:Point = new Point();
		
		public var render_mode:RenderMode; // The current mode used to render a location.
		
		/** an override used when editing */
		CONFIG::god public var hide_targets:Boolean = true;
		CONFIG::god public var hide_boxes:Boolean = true;
		CONFIG::god public var hide_CTBoxes:Boolean = true;
		CONFIG::god public var hide_platforms:Boolean = true;
		public var hide_loc_itemstacks:Boolean = false;
		public var hide_pcs:Boolean = false;
		
		CONFIG::god public var is_stamping_itemstacks:Boolean = false;
		
		public var foc_compsV:Vector.<IFocusableComponent> = new Vector.<IFocusableComponent>();
		private var foc_comps_historyV:Vector.<IFocusableComponent> = new Vector.<IFocusableComponent>();
		private var _get_trophy_info_tsid:String; // set when you want a get trophy info dialog to appear
		private var _current_path:MapPathInfo;
		public var get_info_history:Vector.<GetInfoVO> = new Vector.<GetInfoVO>();
		public var interaction_sign:SignpostSignView; // set when a click on a sign of a signpost happens, so when the avtar moves to the post, the correct sign can be activated
		public var about_to_be_focused_component:IFocusableComponent;
		public var avatar_gs_path_pt:Point; // if gs has sent a control event to the client to move the avatar
		public var avatar_gs_path_end_face:String; // orient the avatar in a direction
		public var to_do_when_arriving_at_dest:Object; // str of verb tsid or a NOIVVO to send when you arrive at the path end, if it is an LIV
		public var requires_intersection:Object;
		public var camera_offset_from_edge:Boolean = false; //tells the client to interpret camera_offset_x as being relative to edge of screen, intead of relative to avatar
		public var camera_offset_x:int = 0;
		public var camera_center_pt:Point;
		public var camera_center_pc_tsid:String;
		public var camera_center_itemstack_tsid:String;
		public var camera_hard_dist_limit:int;
		public var use_camera_offset_x:int = 0;
		public var i_see_dead_pixels:Boolean = false;
		public var menus_prohibited:Boolean = false;
		public var fam_dialog_open:Boolean = false;
		public var fam_dialog_conv_is_active:Boolean = false;
		public var fam_dialog_skill_payload_q:Array = [];
		public var fam_dialog_conv_payload_q:Array = [];
		public var overlay_button_with_tip_count:int;
		public var fam_dialog_can_go:Boolean = false; // until this is true, all fam dialogs are queued
		public var screen_view_q:Vector.<ScreenViewQueueVO> = new Vector.<ScreenViewQueueVO>();
		public var screen_view_open:Boolean = false;
		public var screen_view_retry_timer:Timer = new Timer(1000); //if the screen view isn't ready for display, how long before trying again
		public var familiar_retry_timer:Timer = new Timer(1000); //if the familiar was surpressed, how long before trying his conversation again
		public const fps:BoundedAverageValueTracker = new BoundedAverageValueTracker(3);
		CONFIG::god public var renderA:Array = []; // model.flashVarModel.report_rendering
		CONFIG::god public var scriptA:Array = []; // model.flashVarModel.report_rendering
		public var single_interaction_sp:TSSprite;
		public var overlay_urls:Object = {};
		public var overlay_keys:Object = {};
		public var newxp_location_tsids:Object = {};
		public var newxp_location_keys:Object = {};
		public var focus_is_in_input:Boolean;
		public var focused_input:TextField;
		public var loc_pathA:Array = [];
		public var loc_path_signpost:SignPost = null;
		public var loc_path_door:Door = null;
		public var loc_path_next_loc_tsid:String = '';
		public var loc_path_active:Boolean = false; // are we in a location along the path?
		public var loc_path_at_dest:Boolean = false; // are we at the destination?
		public var showing_greeter_conv:Boolean = false;
		public var report_a_jump:Boolean;
		public var in_capture_mode:Boolean; //used when needing to hide the UI to capture the play area
		public var deco_loader_counts:Object = {
			classes_to: 0,
			instances_to: 0,
			individual_to: 0,
			total_to: 0,
			classes_done: 0,
			instances_done: 0,
			individual_done: 0,
			total_done: 0
		};
		
		// these are used to force the client to open to a specific street when the user next opens the map
		public var hub_to_open_map_to:String;
		public var street_to_open_map_to:String;
		
		public function registerFocusableComponent(comp:IFocusableComponent):void {
			if (!isCompRegisteredAsFocusableComponent(comp)) {
				foc_compsV.push(comp);
			}
		}
		
		public function getDecoCountReport():String {
			var A:Array = [];
			for (var k:String in deco_loader_counts) {
				A.push(k+'='+deco_loader_counts[k]);
			}
			
			return A.join(', ');
		}
		
		public function unRegisterFocusableComponent(comp:IFocusableComponent):void {
			if (comp == focused_component) {
				TSFrontController.instance.releaseFocus(comp);
			}

			if (isCompInFocusHistory(comp)) {
				expungeFromFocusHistory(comp);
			}
			
			var i:int = foc_compsV.indexOf(comp);
			if (i>-1) foc_compsV.splice(i, 1);
		}
		
		//A model does not have this type of logic.
		public function set focused_component(comp:IFocusableComponent):void {
			CONFIG::debugging {
				Console.log(99, 'focus '+ getQualifiedClassName(comp));
			}
			
			// remove it from the list wherever it may be
			expungeFromFocusHistory(comp);
			
			// put it at the end of the list
			foc_comps_historyV.push(comp);

			CONFIG::debugging {
				for (var i:int=foc_comps_historyV.length-1;i>-1;i--) {
					Console.log(99, i+' is focused_component:'+(foc_comps_historyV[int(i)] == focused_component)+' '+getQualifiedClassName(foc_comps_historyV[int(i)]));
				}
				Console.trackValue('TSFC focused', StringUtil.getShortClassName(comp)+((comp is DisplayObject) ? ' '+DisplayObject(comp).name : ''));
				Console.trackValue('TSFC fh', foc_comps_historyV);
			}
		}
		
		// This put the comp just above the TSMainView in focus history and
		// only works when there are 2 or more items in history because
		// if there is only 1 you shout just be straight up taking focus
		// (and there can never be 0 because TSMainView is always 0 in history)
		public function addToFocusHistory(comp:IFocusableComponent):Boolean {
			CONFIG::debugging {
				Console.log(99, 'add '+ getQualifiedClassName(comp));
			}
			
			// remove it from the list wherever it may be
			if (isCompInFocusHistory(comp)) {
				CONFIG::debugging {
					Console.error(getQualifiedClassName(comp)+' is already in focus history');
				}
				return false;
			}
			
			if (foc_comps_historyV.length < 2) {
				CONFIG::debugging {
					Console.error('Cannot add '+getQualifiedClassName(comp)+' to focus history because there are only '+foc_comps_historyV.length+' in history');
				}
				return false;
			}
			
			foc_comps_historyV.splice(1, 0, comp);
			
			CONFIG::debugging {
				for (var i:int=foc_comps_historyV.length-1;i>-1;i--) {
					Console.log(99, i+' '+getQualifiedClassName(foc_comps_historyV[int(i)]));
				}
			}
			
			return true;
		}
		
		//A model does not have this type of logic.
		public function expungeFromFocusHistory(comp:IFocusableComponent):void {
			CONFIG::debugging {
				Console.log(99, 'expunge '+ getQualifiedClassName(comp));
			}
			
			// remove it from the stack if it exists.
			var temp:Vector.<IFocusableComponent> = new Vector.<IFocusableComponent>();
			for (var i:int=foc_comps_historyV.length-1;i>-1;i--) {
				if (foc_comps_historyV[int(i)] == comp) continue;
				temp.unshift(foc_comps_historyV[int(i)])
			}
			foc_comps_historyV = temp;
			
			CONFIG::debugging {
				for (i=foc_comps_historyV.length-1;i>-1;i--) {
					Console.log(99, i+' '+getQualifiedClassName(foc_comps_historyV[int(i)]));
				}
			}
		}
		
		public function get focused_component():IFocusableComponent {
			return (foc_comps_historyV.length) ? foc_comps_historyV[foc_comps_historyV.length-1] : null;
		}
		
		public function get prev_focused_component():IFocusableComponent {
			// if there are not 2 items, there is no history, only the current one
			
			if (foc_comps_historyV.length < 2) {
				return null;
			}
			
			// the last one is currently focused, the one before is the previous componenet
			return foc_comps_historyV[foc_comps_historyV.length-2];
		}
		
		public function isCompInFocusHistory(comp:IFocusableComponent):Boolean {
			return foc_comps_historyV.indexOf(comp) > -1;
		}
		
		public function isClassInFocusHistory(cl:Class):Boolean {
			for (var i:int;i<foc_compsV.length;i++) {
				if (foc_compsV[i] is cl) return true;
			}
			return false;
		}
		
		public function isCompRegisteredAsFocusableComponent(comp:IFocusableComponent):Boolean {
			return foc_compsV.indexOf(comp) > -1;
		}
		
		public function addToGetInfoHistory(giVO:GetInfoVO):void {
			//add it to the item history if 
			//a) it's not the last item in the list
			//b) the list is empty
			//c) if it IS in the list, clear everything after it (change if supporting "forward" later)
			
			var index:int = -1;
			var history_giVO:GetInfoVO;
			for (var i:int;i<get_info_history.length;i++) {
				history_giVO = get_info_history[i];
				
				if (history_giVO.item_class && history_giVO.item_class == giVO.item_class) {
					index = i;
					break;
				}

				if (history_giVO.skill_class && history_giVO.skill_class == giVO.skill_class) {
					index = i;
					break;
				}
			}
			
			//slap it at the end
			if(index == -1){
				get_info_history.push(giVO);
			}
			//remove it (and everything after it) from it's spot, and then slap it at the end
			else if(index != get_info_history.length - 1){
				get_info_history.length = index;
				get_info_history.push(giVO);
			}
		}
		
		public function set get_trophy_info_tsid(item_tsid:String):void {
			_get_trophy_info_tsid = item_tsid;
			if (item_tsid) triggerCBPropDirect("get_trophy_info_tsid");
		}
		
		public function get get_trophy_info_tsid():String {
			return _get_trophy_info_tsid;
		}
		
		public function set hand_of_god(enabled:Boolean):void {
			_hand_of_god = enabled;
			triggerCBPropDirect("hand_of_god");
		}
		
		public function get hand_of_god():Boolean {
			return _hand_of_god;
		}
		
		public function set decorator_mode(enabled:Boolean):void {
			_decorator_mode = enabled;
			triggerCBPropDirect("decorator_mode");
		}
		
		public function get decorator_mode():Boolean {
			return _decorator_mode;
		}
		
		public function set cult_mode(enabled:Boolean):void {
			_cult_mode = enabled;
			triggerCBPropDirect("cult_mode");
		}
		
		public function get cult_mode():Boolean {
			return _cult_mode;
		}
		
		public function set chassis_mode(enabled:Boolean):void {
			_chassis_mode = enabled;
			triggerCBPropDirect("chassis_mode");
		}
		
		public function get chassis_mode():Boolean {
			return _chassis_mode;
		}
		
		public function set info_mode(enabled:Boolean):void {
			_info_mode = enabled;
			triggerCBPropDirect("info_mode");
		}
		
		public function get info_mode():Boolean {
			return _info_mode;
		}
		
		public function set editing(edit:Boolean):void {
			_editing = edit;
			triggerCBPropDirect("editing");
		}
		
		public function get editing():Boolean {
			return _editing;
		}
		
		CONFIG::locodeco public function set editing_unsaved(value:Boolean):void {
			_editing_unsaved = value;
			triggerCBPropDirect("editing_unsaved");
		}
		
		CONFIG::locodeco public function get editing_unsaved():Boolean {
			return _editing_unsaved;
		}
		
		CONFIG::locodeco public function get editing_requesting_lock():Boolean {
			return _editing_requesting_lock;
		}
		
		CONFIG::locodeco public function set editing_requesting_lock(value:Boolean):void {
			_editing_requesting_lock = value;
			triggerCBPropDirect("editing_requesting_lock");
		}

		CONFIG::locodeco public function set editing_saving_changes(value:Boolean):void {
			_editing_saving_changes = value;
			triggerCBPropDirect("editing_saving_changes");
		}
		
		CONFIG::locodeco public function get editing_saving_changes():Boolean {
			return _editing_saving_changes;
		}
		
		CONFIG::locodeco public function set locodeco_loading(loading:Boolean):void {
			_locodeco_loading = loading;
			triggerCBPropDirect("locodeco_loading");
		}
		
		CONFIG::locodeco public function get locodeco_loading():Boolean {
			return _locodeco_loading;
		}
		
		public function set tend_verb_status_bubbles_disabled(disabled:Boolean):void {
			_status_bubbles_disabled = disabled;
			triggerCBPropDirect("status_bubbles_disabled");
		}
		
		public function get tend_verb_status_bubbles_disabled():Boolean {
			return _status_bubbles_disabled;
		}
		
		public function get current_path():MapPathInfo { return _current_path; }
		public function set current_path(path_info:MapPathInfo):void {
			_current_path = path_info;
		}
	}
}