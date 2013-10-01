package com.tinyspeck.engine.view.ui.supersearch
{
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.view.ui.AvatarFaceUI;
	import com.tinyspeck.engine.view.util.StaticFilters;

	public class SuperSearchElementBuddy extends SuperSearchElement
	{			
		private var avatar_face:AvatarFaceUI;
		
		public function SuperSearchElementBuddy(show_images:Boolean){
			super(show_images);
			
			//draw the avatar holder
			if(show_images){
				avatar_face = new AvatarFaceUI();
				avatar_face.y = int(_h/2 - avatar_face.height/2);
				avatar_face.x = 5;
				avatar_face.filters = StaticFilters.black3pxInner_GlowA;
				addChild(avatar_face);
			}
		}
		
		public function show(w:int, pc:PC, str_to_highlight:String = ''):void {
			if(!pc) return;
			
			_w = w;
			current_name = pc.label;
			current_value = pc.tsid;
			current_highlight = str_to_highlight;
			
			draw();
			visible = true;
		}
		
		override protected function setImage():void {
			avatar_face.show(current_value);
		}
	}
}