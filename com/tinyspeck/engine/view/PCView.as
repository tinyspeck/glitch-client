package com.tinyspeck.engine.view {
	import com.tinyspeck.core.memory.IDisposable;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.ns.client;
	import com.tinyspeck.engine.port.InfoManager;
	import com.tinyspeck.engine.spritesheet.AvatarSSManager;
	import com.tinyspeck.engine.util.IDragTarget;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	public class PCView extends AbstractAvatarView implements IWorthRenderable, IDisposable, IDragTarget {
		
		public function PCView(tsid:String) {
			super(tsid);
			_worth_rendering = !model.flashVarModel.limited_rendering;
			init();
		}
		
		override protected function init():void {
			super.init();
			setPhysicsProps();
		}
		
		override public function rescale():void {
			if (!ss) return;
			if (!ss_view) return;
			super.rescale();
			setPhysicsProps();
		}
		
		private function setPhysicsProps():void {
			const pc:PC = model.worldModel.getPCByTsid(tsid);
			// physics is waiting for the dimensions, which are constant
			pc.client::physWidth = w;
			pc.client::physHeight = h;
			// for a circle that circumscribes the avatar from the center,
			// the diameter is the hypotenuse of the triangle formed by the width and height;
			pc.client::physRadius = (0.5 * Math.sqrt(pc.client::physWidth*pc.client::physWidth + pc.client::physHeight*pc.client::physHeight));
		}
		
		override public function set worth_rendering(value:Boolean):void {
			if (_worth_rendering == value) return;
			_worth_rendering = value;
			
			const pc:PC = model.worldModel.getPCByTsid(tsid);
			
			if (_worth_rendering) {
				// move it into place because we have not been moving it while it was !_worth_rendering
				x = pc.x;
				y = pc.y;
				
				// if it was loaded before, then get it going again, else load the ss
				if (ss) {
					changeHandler(); // this will call showHide() and _animateAndOrientFromS() and all the shit we need
				} else {
					ss = AvatarSSManager.getSSForAva(pc.ac, pc.sheet_url, null, make_all_sheets);
					setUpSS();
					current_aas = 0; // to force _animateAndOrientFromS to work
					_animateAndOrientFromS(pc.s);
				}
			} else {
				// hide it!
				showHide();
				if (ss && ss_view) {
					ss_view.stop();
					_stopped = true;
				}
			}
		}
		
		override public function get disambugate_sort_on():int {
			return 110;
		}
		
		override public function showHide():void {
			visible = (!model.stateModel.hide_pcs && _worth_rendering);
		}
		
		override public function glow():void {
			if (model.stateModel.info_mode) {
				_glowing = true;
				if (InfoManager.instance.highlighted_view == this) {
					interaction_target.filters = StaticFilters.infoColorHighlightA;
				} else {
					interaction_target.filters = StaticFilters.infoColorA;
				}
				return;
			}
			
			if(!model.worldModel.location.no_pc_interactions){
				super.glow();
			}
		}
		
		public function highlightOnDragOver():void {
			if (ss_view_holder) {
				ss_view_holder.filters = StaticFilters.tsSprite_GlowA;
			}
		}
		
		public function unhighlightOnDragOut():void {
			if (ss_view_holder) {
				ss_view_holder.filters = null;
			}
		}
	}
}