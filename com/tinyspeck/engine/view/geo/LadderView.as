package com.tinyspeck.engine.view.geo {
	import com.tinyspeck.engine.data.location.Ladder;
	
	import flash.display.BlendMode;
	
	CONFIG::locodeco { import locodeco.LocoDecoGlobals; }
	import com.tinyspeck.engine.view.renderer.IAbstractDecoRenderer;
	
	public class LadderView extends SurfaceView implements IAbstractDecoRenderer {
		public var ladder:Ladder;
		
		public function LadderView(ladder:Ladder, loc_tsid:String):void {
			super(ladder, loc_tsid);
			this.ladder = ladder;
			
			_orient = 'vert';
			_graphics.blendMode = BlendMode.INVERT;
		}
		
		override public function get disambugate_sort_on():int {
			return 70;
		}
		
		override protected function _getVerticalMin():int {
			return -(ladder.h);
		}
		
		override protected function _getVerticalMax():int {
			return 0;
		}
		
		/** from IDecoRendererContainer */
		override public function syncRendererWithModel():void {
			super.syncRendererWithModel();
			
			_graphics.graphics.clear();
			// invisible fill unless editing
			_graphics.graphics.beginFill(0x000000, 0);
			CONFIG::god {
				if (_center.numChildren == 0) {
					if (!model.stateModel.editing && !model.stateModel.hide_platforms) {
						_graphics.graphics.beginFill(0x000000, 0.2);
					}
					CONFIG::locodeco {
						if ((model.stateModel.editing && LocoDecoGlobals.instance.overlayPlatforms)) {
							_graphics.graphics.beginFill(0x000000, 0.2);
						}
					}
				}
			}
			_graphics.graphics.drawRect(0, 0, _width, -_height);
			_graphics.graphics.drawRect(-30, 0, _width+30*2, -_height);
		}
	}
}
