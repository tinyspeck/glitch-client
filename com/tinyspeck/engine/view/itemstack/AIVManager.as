package com.tinyspeck.engine.view.itemstack {
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingItemstackVerbMenuVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.port.ActionIndicatorView;
	import com.tinyspeck.engine.port.ItemstackActionIndicatorView;
	import com.tinyspeck.engine.port.JobActionIndicatorView;
	import com.tinyspeck.engine.view.TSMainView;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.utils.getTimer;

	public class AIVManager {
		
		private var aivs_mouse_catcher:Sprite;
		private var itemstack:Itemstack;
		private var model:TSModelLocator;
		private var lis:LocationItemstackView;
		private var iaivV:Vector.<ActionIndicatorView> = new Vector.<ActionIndicatorView>();
		private var show_aivs_tim:uint;
		private var has_job_indicator:Boolean;
		private var aivs_hidden_for_overlay_locker_count:int;
		private var _aivs_hidden_for_glow:Boolean;
		private var _indicators_visible:Boolean = false;
		private var iaiv_out_timer:uint;
		private var iaiv_over_timer:uint;
		private var action_clicked_verb:String;
		
		public function AIVManager(lis:LocationItemstackView, itemstack:Itemstack) {
			this.itemstack = itemstack;
			this.lis = lis;
			model = TSModelLocator.instance;
		}
		
		public function buildActionIndicators():void {
			if(!itemstack.status) return;
			//Console.error('where '+tsid)
			
			var stack_indicator:ItemstackActionIndicatorView;
			var key:String;
			var verb_state:Object;
			var available_verbs:Array = new Array();
			var i:int;
			
			for(key in itemstack.status.verb_states) {
				// make sure it is enabled
				if (!itemstack.status.verb_states[key] || !itemstack.status.verb_states[key].enabled) continue;
				
				// EC: I am not sure why we do not show hug/kiss
				if(key != 'hug' && key != 'kiss') {
					available_verbs.push(key);
				} 
			}
			
			if(available_verbs.length > 0){
				//sort by alpha
				available_verbs.sort();
			}
			else {
				removeActionIndicator(null, true);
			}
			
			//make sure we don't have crap we don't need
			for(i = iaivV.length-1; i >= 0; i--){
				stack_indicator = iaivV[int(i)] as ItemstackActionIndicatorView;
				if(available_verbs.indexOf(stack_indicator.type) == -1){
					removeActionIndicator(stack_indicator);
				}
			}
			
			var max:int = Math.min(available_verbs.length, 1);
			//build/reuse the indicators
			for(i = 0; i < max; i++){
				verb_state = itemstack.status.verb_states[available_verbs[int(i)]];
				
				stack_indicator = getActionIndicatorByType(available_verbs[int(i)]) as ItemstackActionIndicatorView;
				
				if(!stack_indicator){
					stack_indicator = getActionIndicator(i) as ItemstackActionIndicatorView;
					
					//if we only have one verb, reuse the the one that's already there
					if(stack_indicator && max == 1){
						if(stack_indicator.type != available_verbs[int(i)]){
							stack_indicator.type = available_verbs[int(i)];
							if(verb_state.item_class && stack_indicator.icon_class != verb_state.item_class){
								stack_indicator.icon_class = verb_state.item_class;
							}
							else {
								stack_indicator.icon = stack_indicator.getIcon();
							}
						}
					}
						//make sure we make a new one
					else {
						stack_indicator = null;
					}
				}
				
				if(!stack_indicator){
					stack_indicator = new ItemstackActionIndicatorView(lis.tsid, verb_state.item_class ? verb_state.item_class : available_verbs[int(i)]);
					stack_indicator.visible = false;
					stack_indicator.type = available_verbs[int(i)];
					stack_indicator.addEventListener(MouseEvent.CLICK, onActionIndicatorClick, false, 0, true);
					stack_indicator.addEventListener(MouseEvent.MOUSE_OVER, _mouseOverHandler, false, 0, true);
					stack_indicator.addEventListener(MouseEvent.MOUSE_OUT, _mouseOutHandler, false, 0, true);
					iaivV.push(stack_indicator);
				}
				
				stack_indicator.enabled = (verb_state.enabled === true);
				stack_indicator.warning = (verb_state.warning === true);
				stack_indicator.tip_text = stack_indicator.enabled ? '' : verb_state.disabled_reason;
			}
			
			showHideAIVs();
		}
		
		private function onActionIndicatorClick(event:MouseEvent):void {
			var stack_indicator:ItemstackActionIndicatorView = event.currentTarget as ItemstackActionIndicatorView;
			if(!stack_indicator.enabled) return;
			action_clicked_verb = stack_indicator.type;
			
			//if this item has conditional verbs, go ask the server what to do first
			if(itemstack.item && itemstack.item.hasConditionalVerbs){
				TSFrontController.instance.genericSend(new NetOutgoingItemstackVerbMenuVO(lis.tsid), onVerbsReceived, onVerbsReceived);
			}
			else {
				TSFrontController.instance.doVerb(lis.tsid, action_clicked_verb);
			}
		}
		
		protected function _mouseOutHandler(e:MouseEvent):void {
			StageBeacon.clearTimeout(iaiv_over_timer);
			StageBeacon.clearTimeout(iaiv_out_timer);
			iaiv_out_timer = StageBeacon.setTimeout(toggleActionIndicatorsGlow, 500, false);
			//toggleActionIndicatorsGlow(false);
			
			lis.has_mouse = true;
		}
		
		protected function _mouseOverHandler(e:MouseEvent):void {
			if (!(e.target is ItemstackActionIndicatorView)) return;

			StageBeacon.clearTimeout(iaiv_out_timer);
			if (getTimer() - StageBeacon.last_mouse_move > 1000) return;
			
			StageBeacon.clearTimeout(iaiv_over_timer);
			iaiv_over_timer = StageBeacon.setTimeout(toggleActionIndicatorsGlow, 600, true);
			
			lis.has_mouse = true;
		}		
		
		private function onVerbsReceived(nrm:NetResponseMessageVO):void {
			if(nrm.success){
				// Netcontroller processes these responses too, and updates the verbs on the item, so we can check below for the verb we want
				
				//are we allowed to do this verb? If so fire it off!
				if(itemstack.item.verbs[action_clicked_verb]){
					TSFrontController.instance.doVerb(lis.tsid, action_clicked_verb);
				} else {
					;
					CONFIG::debugging {
						Console.warn(action_clicked_verb+' not found in verbs for '+lis.tsid);
					}
				}
			}
		}		
		
		public function removeActionIndicator(aiv:ActionIndicatorView, clear_all:Boolean = false):void {
			if(!clear_all){
				if(iaivV.indexOf(aiv) != -1){
					if (aiv is JobActionIndicatorView) {
						has_job_indicator = false;
					}
					iaivV.splice(iaivV.indexOf(aiv), 1);
					aiv.dispose();
					aiv = null;
					
					return;
				}
				
				return;
			}
			else {
				var i:int;
				
				for(i; i < iaivV.length; i++){
					iaivV[int(i)].dispose();
				}
				
				iaivV.length = 0;
				
				has_job_indicator = false;
				
				return;
			}
		}	
		
		public function getActionIndicator(index:int = 0):ActionIndicatorView {
			if(iaivV.length-1 >= index) return iaivV[index];
			
			return null;
		}
		
		public function getActionIndicatorByType(type:String):ActionIndicatorView {
			var i:int;
			var aiv:ActionIndicatorView;
			
			for(i; i < iaivV.length; i++){
				aiv = iaivV[int(i)];
				if(aiv.type == type) return aiv;
			}
			
			return null;
		}
		
		public function showHideAIVs():void {
			if (!has_indicators) return;
			
			var show:Boolean = true;
			
			if (model.stateModel.tend_verb_status_bubbles_disabled) show = false;
			if (aivs_hidden_for_overlay_locker_count > 0) show = false;
			if (!lis.has_mouse_focus && _aivs_hidden_for_proximity && !has_job_indicator) show = false;
			if (_aivs_hidden_for_glow) show = false;
			if (lis.lisChatBubbleManager.aivs_hidden_for_bubble) show = false;
			if (!lis.worth_rendering) show = false;
			if (!(model.stateModel.focused_component is TSMainView)) show = false;
			if (!lis.visible) show = false;
			if (model.rookModel.rooked_status.rooked) show = false;
			
			if (_indicators_visible == show) return;
			
			_indicators_visible = show;
			
			if (show_aivs_tim) StageBeacon.clearTimeout(show_aivs_tim);
			show_aivs_tim = StageBeacon.setTimeout(positionActionIndicators, 10, true);
		}
		
		public function get has_indicators():Boolean {	
			if (!iaivV) return false;
			if (!iaivV.length) return false;
			return true;
		}
		
		private var _aivs_hidden_for_proximity:Boolean = true;
		public function set aivs_hidden_for_proximity(value:Boolean):void {
			_aivs_hidden_for_proximity = value;
			showHideAIVs();
		}		
		
		public function set aivs_hidden_for_glow(value:Boolean):void {
			if (_aivs_hidden_for_glow == value) return;
			_aivs_hidden_for_glow = value;
			showHideAIVs();
		}
		
		public function positionActionIndicators(and_adjust_visibility:Boolean=false):void {
			if(!has_indicators) return;
			
			//get the current indicators, and center them
			var iaiv:ActionIndicatorView;
			var iaiv_total_width:int;
			var i:int;
			var next_x:int;
			var has_multiple:Boolean = iaivV.length > 1 ? true : false;
			
			for(i; i < iaivV.length; i++){
				iaiv = iaivV[int(i)];
				if(has_multiple && iaiv.glowing){
					if(i == 0){
						iaiv.pointy_direction = 'right';
					}
					else if(i == iaivV.length - 1){
						iaiv.pointy_direction = 'left';
					}
				}
				else {
					iaiv.pointy_direction = '';
				}
				iaiv_total_width += iaiv.w; // .w is a calulated width that gives a truer display width taking into account the masked parts
			}
			
			next_x = Math.round(lis.x_of_int_target - iaiv_total_width/2);
			
			var fix:int = has_multiple && iaiv.pointy_direction ? 5 : 0;
			
			for(i = 0; i < iaivV.length; i++){
				iaiv = iaivV[int(i)];
				iaiv.x = next_x+fix;
				iaiv.y = lis.y + lis.getYAboveDisplay() - iaiv.height;
				if (and_adjust_visibility) iaiv.visible = _indicators_visible;
				next_x += iaiv.width + (iaiv.glowing ? 0 : 5);
			}
			
			if (!aivs_mouse_catcher) {
				aivs_mouse_catcher = new Sprite();
				var g:Graphics = aivs_mouse_catcher.graphics;
				g.beginFill(0xffffff, 0);
				g.drawRect(-50, 0, 100, 10);
				(lis as LocationItemstackView).addChildAt(aivs_mouse_catcher, 0);
			}
			
			if (_indicators_visible && !aivs_mouse_catcher.visible) {
				aivs_mouse_catcher.visible = true;
				aivs_mouse_catcher.y = lis.getYAboveDisplay()-30;
				aivs_mouse_catcher.height = -aivs_mouse_catcher.y;
			} else if (!_indicators_visible && aivs_mouse_catcher.visible) {
				aivs_mouse_catcher.visible = false;
			}
		}	
		
		public function set aivs_hidden_for_overlay(value:Boolean):void {
			if (value) {
				aivs_hidden_for_overlay_locker_count++;
			} else {
				aivs_hidden_for_overlay_locker_count--;
			}
			showHideAIVs();
		}
		
		public function addActionIndicator(aiv:ActionIndicatorView):Boolean {
			if (aiv is JobActionIndicatorView) {
				has_job_indicator = true;
			}
			if(iaivV.indexOf(aiv) == -1){
				iaivV.push(aiv);
				return true;
			}
			else {
				return false;
			}
		}
		
		public function toggleActionIndicatorsGlow(is_glow:Boolean):void {			
			if (!has_indicators) return;
			StageBeacon.clearTimeout(iaiv_out_timer);
			StageBeacon.clearTimeout(iaiv_over_timer);
			
			var i:int;
			var iaiv:ItemstackActionIndicatorView;
			
			for (i; i < iaivV.length; i++){
				iaiv = iaivV[int(i)] as ItemstackActionIndicatorView;
				if(!iaiv) continue;
				iaiv.glowing = is_glow;
			}
			
			positionActionIndicators();
		}		

		public function get indicators_visible():Boolean { return _indicators_visible; }
		public function set indicators_visible(value:Boolean):void {_indicators_visible = value;}
	}
}