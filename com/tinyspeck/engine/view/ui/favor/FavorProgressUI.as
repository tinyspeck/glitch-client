package com.tinyspeck.engine.view.ui.favor
{
	import com.tinyspeck.engine.data.giant.GiantFavor;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.port.AssetManager;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.port.GetInfoDialog;
	import com.tinyspeck.engine.port.WindowBorder;
	import com.tinyspeck.engine.util.GetInfoVO;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.ITipProvider;
	import com.tinyspeck.engine.view.gameoverlay.ProgressBar;
	import com.tinyspeck.engine.view.gameoverlay.TipDisplayManager;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.TextField;

	public class FavorProgressUI extends Sprite implements ITipProvider
	{
		private static const DEFAULT_WIDTH:uint = 204;
		private static const DEFAULT_HEIGHT:uint = 36;
		private static const OFFSET_X:uint = 65;
		private static const EMBLEM_WH:uint = 47;
		
		private var current_tf:TextField = new TextField();
		private var max_tf:TextField = new TextField();
		
		private var pb:ProgressBar;
		private var emblem:ItemIconView;
		private var giant_bt:Button;
		private var giant_info:GetInfoVO;
		
		private var pb_local:Point;
		private var pb_global:Point;
		
		private var icon:DisplayObject;
		private var icon_hover:DisplayObject;
		
		private var giant_name:String;
		private var tip_txt:String;
		
		private var is_built:Boolean;
		
		private var pb_w:int;
		private var pb_h:int;
		private var bg_color:uint = 0xdee2e3;
		private var shadow_color:uint = 0xbdc0c1;
		private var bar_top:uint = 0xf1b6c8;
		private var bar_bottom:uint = 0xd794a8;
		private var tip_top:uint = 0xdba5b5;
		private var tip_bottom:uint = 0xcb8c9f;
		private var bar_top_done:uint = 0xfee582;
		private var bar_bottom_done:uint = 0xe8b540;
		private var tip_done:uint = 0xe3cd76;
		
		public function FavorProgressUI(pb_w:uint = FavorProgressUI.DEFAULT_WIDTH, pb_h:uint = FavorProgressUI.DEFAULT_HEIGHT){
			this.pb_w = pb_w;
			this.pb_h = pb_h;
		}
		
		private function buildBase():void {			
			pb = new ProgressBar(pb_w, pb_h);
			pb.x = OFFSET_X;
			pb_local = new Point(pb_w/2, -2);
			addChild(pb);
			
			giant_bt = new Button({
				name: 'giant',
				label_face: 'VAGRoundedBoldEmbed',
				label_c: 0x005c73,
				label_hover_c: 0xd79035,
				label_size: 11,
				graphic_placement: 'top',
				graphic_padd_t: 0,
				graphic_padd_b: -2,
				default_tf_padd_w: 0,
				draw_alpha:0,
				w: OFFSET_X
			});
			giant_bt.addEventListener(TSEvent.CHANGED, onGiantClick, false, 0, true);
			addChild(giant_bt);
			
			TFUtil.prepTF(current_tf, false);
			current_tf.x = 6;
			current_tf.filters = StaticFilters.copyFilterArrayFromObject({alpha:.5}, StaticFilters.white1px90Degrees_DropShadowA);
			pb.addChild(current_tf);
			
			TFUtil.prepTF(max_tf, false);
			pb.addChild(max_tf);
			
			//set the colors
			const cssm:CSSManager = CSSManager.instance;
			bg_color = cssm.getUintColorValueFromStyle('favor_progress_pb', 'backgroundColor', bg_color);
			shadow_color = cssm.getUintColorValueFromStyle('favor_progress_pb', 'shadowColor', shadow_color);
			bar_top = cssm.getUintColorValueFromStyle('favor_progress_pb', 'barTop', bar_top);
			bar_bottom = cssm.getUintColorValueFromStyle('favor_progress_pb', 'barBottom', bar_bottom);
			tip_top = cssm.getUintColorValueFromStyle('favor_progress_pb', 'tipTop', tip_top);
			tip_bottom = cssm.getUintColorValueFromStyle('favor_progress_pb', 'tipBottom', tip_bottom);
			bar_top_done = cssm.getUintColorValueFromStyle('favor_progress_pb', 'barTopDone', bar_top_done);
			bar_bottom_done = cssm.getUintColorValueFromStyle('favor_progress_pb', 'barBottomDone', bar_bottom_done);
			tip_done = cssm.getUintColorValueFromStyle('favor_progress_pb', 'tipDone', tip_done);
			pb.setFrameColors(bg_color, shadow_color);
			
			//setup the info getter
			giant_info = new GetInfoVO(GetInfoVO.TYPE_ITEM);
			
			is_built = true;
		}
		
		public function show(giant_favor:GiantFavor):void {
			if(!is_built) buildBase();
			
			if(giant_name != giant_favor.name){
				//make sure the icon is good
				icon = new AssetManager.instance.assets['giant_'+giant_favor.name]();
				icon_hover = new AssetManager.instance.assets['giant_'+giant_favor.name+'_hover']();
				
				//setup the giant button
				giant_bt.label = giant_favor.label;
				giant_bt.setGraphic(icon);
				giant_bt.setGraphic(icon_hover, true);
				giant_bt.h = giant_bt.height;
				giant_bt.y = int(pb_h/2 - giant_bt.height/2 + 2);
				giant_bt.tip = {txt:'Find the closest Shrine to '+giant_favor.label, pointer:WindowBorder.POINTER_BOTTOM_CENTER};
				
				//add the emblem (item in god is still "ti" so we gotta check that)
				if(emblem && emblem.parent) emblem.parent.removeChild(emblem);
				emblem = new ItemIconView('emblem_' + (giant_favor.name != 'tii' ? giant_favor.name : 'ti'), EMBLEM_WH);
				emblem.x = int(pb.x + pb_w - emblem.width/2);
				emblem.y = int(pb_h/2 - emblem.height/2);
				addChild(emblem);
				
				giant_name = giant_favor.name;
			}
			
			const no_emblem:Boolean = giant_favor.current < giant_favor.max;
			
			//set current and max favor
			max_tf.visible = no_emblem;
			if(no_emblem){
				current_tf.htmlText = '<p class="favor_progress"><span class="favor_progress_current">'+giant_favor.current+'</span></p>';
				max_tf.htmlText = '<p class="favor_progress_max">/'+giant_favor.max+'</p>';
				max_tf.x = int(pb.width - max_tf.width - 3);
				max_tf.y = int(pb.height - max_tf.height);
			}
			else {
				current_tf.htmlText = '<p class="favor_progress_earned">Emblem Earned</p>';
			}
			current_tf.y = int(pb.height/2 - current_tf.height/2 + 1);
			
			//set the progress bar
			const perc:Number = giant_favor.current/giant_favor.max;
			pb.update(perc);
			pb.setBarColors(
				no_emblem ? bar_top : bar_top_done, 
				no_emblem ? bar_bottom : bar_bottom_done, 
				no_emblem ? tip_top : tip_done, 
				no_emblem ? tip_bottom : tip_done
			);
			
			//animate it if we got an emblem
			emblem.visible = !no_emblem;
			if(no_emblem){
				pb.stopTweening();
			}
			else {
				pb.startTweening();
			}
			
			//set the tooltip text
			if(no_emblem){
				const favor_left:int = giant_favor.max - giant_favor.current;
				tip_txt = 'Earn '+favor_left+' more favor '+(favor_left != 1 ? 'points' : 'point')+' with '+giant_favor.label+
						  ' and earn a valuable Emblem!';
			}
			else {
				tip_txt = 'Go to any Shrine to '+giant_favor.label+' to get your Emblem!';
			}
			
			//make sure the tooltips work
			TipDisplayManager.instance.registerTipTrigger(pb);
			
			//set the get info action (old ass ti legacy)
			giant_info.item_class = 'npc_shrine_'+(giant_name != 'tii' ? giant_name : 'ti');
		}
		
		public function hide():void {
			if(parent) parent.removeChild(this);
			TipDisplayManager.instance.unRegisterTipTrigger(pb);
		}
		
		public function getTip(tip_target:DisplayObject = null):Object {
			if(!tip_target) return null;
			
			//show the tip
			pb_global = pb.localToGlobal(pb_local);
			return {
				txt:tip_txt,
				placement:pb_global,
				pointer:WindowBorder.POINTER_BOTTOM_CENTER
			}
		}
		
		private function onGiantClick(event:TSEvent):void {
			//open the info for this giant
			GetInfoDialog.instance.showInfo(giant_info);
		}
		
		override public function get height():Number {
			return pb_h;
		}
		
		override public function get width():Number {
			if(pb){
				return pb.x + pb_w;
			}
			else {
				return super.width;
			}
		}
	}
}