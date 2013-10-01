package com.tinyspeck.engine.port
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.model.LayoutModel;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.view.AvatarView;
	import com.tinyspeck.engine.view.TSMainView;
	import com.tinyspeck.engine.view.gameoverlay.YouDisplayManager;
	import com.tinyspeck.engine.view.ui.Slug;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;

	public class SlugAnimator implements IStatBurstChange
	{		
		private var slugs:Vector.<Slug> = new Vector.<Slug>();
		private var stat_bursts:Vector.<StatBurst> = new Vector.<StatBurst>();
		private var main_view:TSMainView;
		private var is_animating:Boolean;
		private var on_burst_change:Function;
		
		public function SlugAnimator(){
			main_view = TSFrontController.instance.getMainView();
		}
		
		public function start(on_burst_change:Function = null):void {
			this.on_burst_change = on_burst_change;

			StatBurstController.instance.registerChangeSubscriber(this);
		}
		
		public function end():void {
			StatBurstController.instance.unRegisterChangeSubscriber(this);
		}
		
		public function onStatBurstChange(stat_burst:StatBurst, value:int):void {
			if(StatBurstController.instance.paused) return;
			
			if(on_burst_change != null){
				var reward:Reward = new Reward(stat_burst.type);
				reward.type = stat_burst.type;
				reward.amount = value;
				var slug:Slug = new Slug(reward);
				on_burst_change(slug);
			}

			stat_bursts.push(stat_burst);
		}
		
		public function add(slug:Slug, is_queued:Boolean):void {			
			if(is_queued){				
				if(is_animating){
					slugs.push(slug);
				}
				else {
					animate(slug, .4); //give a little delay to the first one
				}
			}
			else {
				animate(slug);
			}
		}
		
		private function animate(slug:Slug, start_delay:Number = 0):void {
			//no sense in adding something to animate if it has nowhere to animate to
			if(!YouDisplayManager.instance.visible){
				if(slugs.length > 0) {
					animate(slugs.shift());
				}
				else {
					is_animating = false;
					if(on_burst_change == null) end();
				}
				
				return;
			}
			
			var pos_or_neg:String = (slug.amount > 0) ? 'pos' : 'neg';
			var str:String = (slug.amount > 0 ? '+' : '-') + Math.abs(slug.amount);
			var layoutModel:LayoutModel = TSModelLocator.instance.layoutModel;
			var start_point:Point = slug.getTextCenterPt();
			var stat_burst:StatBurst;
			var end_point:Point;
			var tf_holder:Sprite = new Sprite();
			var tf:TextField = new TextField();
			prepTextField(tf);
			
			is_animating = true;
			slug.dim_text = true;
			
			//this makes it so scaling happens from the center
			tf.htmlText = '<p class="slug"><span class="slug_'+slug.type+'_'+pos_or_neg+'">'+str+'</span></p>';
			tf.x = - int(tf.width/2);
			tf.y = - int(tf.height/2);
			
			tf_holder.x = start_point.x + 2;
			tf_holder.y = start_point.y;
			tf_holder.addChild(tf);
			
			main_view.addView(tf_holder);
			
			//where to go
			switch(slug.type){
				case Slug.XP:
					end_point = YouDisplayManager.instance.getImaginationCenterPt();
					break;
				case Slug.CURRANTS:
					end_point = YouDisplayManager.instance.getCurrantsCenterPt();
					break;
				case Slug.MOOD:
					end_point = YouDisplayManager.instance.getMoodGaugeCenterPt();
					break;
				case Slug.ENERGY:
					end_point = YouDisplayManager.instance.getEnergyGaugeCenterPt();
					break;
				case Slug.IMAGINATION:
					// this is close enough, but maybe at some point we add a way to get the iMG button center
					end_point = YouDisplayManager.instance.getEnergyGaugeCenterPt();
					break;
				default:
					//when in doubt, animate it to the avatar
					var avatar:AvatarView = main_view.gameRenderer.getAvatarView();
					end_point = avatar.localToGlobal(new Point(0,-avatar.height/2));
					break;
			}
			
			//animate it
			TSTweener.addTween(tf_holder, {scaleX:3, scaleY:3, time:.4, delay:start_delay});
			TSTweener.addTween(tf_holder, {scaleX:.4, scaleY:.4, x:end_point.x, y:end_point.y, delay:.5 + start_delay, time:.3, 
				onComplete:function():void {
					if(main_view.contains(tf_holder)){
						main_view.removeChild(tf_holder);
					}
					slug.dim_text = false;
					stat_burst = getBurstByType(slug.type);
					if(stat_burst) {
						stat_burst.go(slug.amount);
						stat_bursts.splice(stat_bursts.indexOf(stat_burst), 1);
					}
					if(slugs.length > 0) {
						animate(slugs.shift());
					}
					else {
						is_animating = false;
						if(on_burst_change == null) end();
					}
				}
			});
		}
		
		private function getBurstByType(type:String):StatBurst {
			var i:int;
			var sb:StatBurst;
			var total:int = stat_bursts.length;
			
			for(i; i < total; i++){
				if(stat_bursts[int(i)].type == type) return stat_bursts[int(i)];
			}
			
			return null;
		}
		
		private function prepTextField(tf:TextField):void {
			tf.embedFonts = true;
			tf.selectable = false;
			tf.styleSheet = CSSManager.instance.styleSheet;
			tf.autoSize = TextFieldAutoSize.CENTER;
			tf.antiAliasType = AntiAliasType.ADVANCED;
			tf.filters = StaticFilters.youDisplayManager_GlowA;
		}
	}
}