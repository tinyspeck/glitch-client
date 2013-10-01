package com.tinyspeck.engine.port
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.group.Group;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.job.JobBucket;
	import com.tinyspeck.engine.data.job.JobInfo;
	import com.tinyspeck.engine.data.job.JobOption;
	import com.tinyspeck.engine.data.job.JobPhase;
	import com.tinyspeck.engine.data.leaderboard.Leaderboard;
	import com.tinyspeck.engine.data.pc.PCSkill;
	import com.tinyspeck.engine.data.requirement.Requirement;
	import com.tinyspeck.engine.data.reward.Reward;
	import com.tinyspeck.engine.data.reward.Rewards;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.IFocusableComponent;
	import com.tinyspeck.engine.view.gameoverlay.ProgressBar;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.Toast;
	import com.tinyspeck.engine.view.ui.jobs.JobBucketUI;
	import com.tinyspeck.engine.view.ui.jobs.JobDetailsUI;
	import com.tinyspeck.engine.view.ui.jobs.JobIntroUI;
	import com.tinyspeck.engine.view.ui.jobs.JobPhaseUI;
	import com.tinyspeck.engine.view.ui.jobs.JobRequirementsUI;
	import com.tinyspeck.engine.view.ui.jobs.JobWorkUI;
	import com.tinyspeck.engine.view.ui.leaderboard.LeaderboardUI;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.utils.Timer;

	public class JobDialog extends BigDialog implements IFocusableComponent, IPackChange {
		
		/* singleton boilerplate */
		public static const instance:JobDialog = new JobDialog();
		
		private const HOLDER_GAP:int = 40;
		private const ANIMATION_SPEED:Number = .5;
		private const POLAROID_SIZE:uint = 108;
		
		private var pb:ProgressBar;
		private var back_bt:Button;
		private var leaderboard_bt:Button;
		private var toast:Toast;
		private var job_intro:JobIntroUI;
		private var job_phase:JobPhaseUI;
		private var job_details:JobDetailsUI;
		private var job_work:JobWorkUI;
		private var job_buckets:Vector.<JobBucketUI> = new Vector.<JobBucketUI>();
		private var leaderboard_ui:LeaderboardUI;
		private var timeout_timer:Timer = new Timer(1000);
		
		private var pb_amount:TextField = new TextField();
		private var rewards_title:TextField = new TextField();
		private var rewards_body:TextField = new TextField();
		private var timeout_tf:TextField = new TextField();
		private var complete_tf:TextField = new TextField();
		private var claimed_tf:TSLinkedTextField = new TSLinkedTextField();
		private var bottom_msg_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var all_holder:Sprite = new Sprite();
		private var req_holder:Sprite = new Sprite();
		private var pb_holder:Sprite = new Sprite();
		private var footer_holder:Sprite = new Sprite();
		private var complete_holder:Sprite = new Sprite();
		private var body_mask:Sprite = new Sprite();
		
		private var polaroids:Array = new Array();
		
		private var pb_bar_top:uint = 0x94c6da;
		private var pb_bar_bottom:uint = 0x76a8bc;
		private var pb_tip_top:uint = 0x80aaba;
		private var pb_tip_bottom:uint = 0x6892a2;
		private var current_timeout:uint;
		
		private var is_built:Boolean;
		private var is_blocking_familiar_convos:Boolean;
		
		private var _spirit_id:String;
		private var _job_id:String;
		
		public function JobDialog() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_draggable = true;
			_w = 584;
			_head_min_h = 70;
			_body_min_h = 300;
			_foot_min_h = 0;
			_base_padd = 20;
			
			visible = false;
			
			_construct();
		}
		
		private function buildBase():void {
			var cssm:CSSManager = CSSManager.instance;
			
			//progress bar holder
			var g:Graphics = pb_holder.graphics;
			var pb_rad:int = 5;
			var holder_width:int = _w - 66;
			var holder_height:int = 26;
			
			g.beginFill(bg_c);
			g.drawRoundRectComplex(pb_rad, 0, holder_width, holder_height, 0, 0, pb_rad, pb_rad);
			g.beginFill(bg_c); //left hook
			g.moveTo(0,0);
			g.curveTo(pb_rad,0, pb_rad,pb_rad);
			g.lineTo(pb_rad,0);
			g.endFill();
			g.beginFill(bg_c); //right hook
			g.moveTo(holder_width+pb_rad*2,0);
			g.curveTo(holder_width+pb_rad,0, holder_width+pb_rad,pb_rad);
			g.lineTo(holder_width+pb_rad,0);
			g.endFill();
			
			//throw the holder on
			addChild(all_holder);
			
			pb_holder.x = int(_w/2 - pb_holder.width/2);
			pb_holder.filters = StaticFilters.black1px90DegreesJobDialog_DropShadowA;
			pb_holder.mouseEnabled = false;
			addChild(pb_holder);
			
			//progress bar
			var pb_padding:int = 12;
			var pb_border_width:int = 2;
			pb_bar_top = cssm.getUintColorValueFromStyle('job_progress_bar', 'topColor', pb_bar_top);
			pb_bar_bottom = cssm.getUintColorValueFromStyle('job_progress_bar', 'bottomColor', pb_bar_bottom);
			pb_tip_top = cssm.getUintColorValueFromStyle('job_progress_bar', 'tipTopColor', pb_tip_top);
			pb_tip_bottom = cssm.getUintColorValueFromStyle('job_progress_bar', 'tipBottomColor', pb_tip_bottom);
			pb = new ProgressBar(pb_holder.width - pb_padding*2 - pb_rad*2 - pb_border_width*2, 24);
			pb.mouseEnabled = false;
			pb.setFrameColors(0xd8dada, 0x828383);
			pb.setBorderColor(0xd6d6d6, pb_border_width);
			pb.setBarColors(pb_bar_top, pb_bar_bottom, pb_tip_top, pb_tip_bottom);
			pb.x = pb_padding + pb_rad + pb_border_width;
			pb.y = int(pb_holder.height - pb.height - pb_padding + pb_border_width/2);
			
			TFUtil.prepTF(pb_amount, false);
			pb_amount.htmlText = '<p class="job_progress_amount">0% complete</p>';
			pb_amount.x = 8;
			pb_amount.y = int(pb.height/2 - pb_amount.height/2);
			pb.addChild(pb_amount);
			pb_holder.addChild(pb);
			
			//phases
			job_phase = new JobPhaseUI(pb.width - pb.border_width*2);
			job_phase.x = pb.x;
			job_phase.y = pb.y;
			pb_holder.addChild(job_phase);
			
			//button holder
			all_holder.addChild(req_holder);
			
			//leaderboard button
			var bt_gfx:DisplayObject = new AssetManager.instance.assets.job_leaderboard();
			leaderboard_bt = new Button({
				graphic: bt_gfx,
				name: 'leaderboard',
				w: bt_gfx.width,
				h: bt_gfx.height,
				x: _w - _base_padd - bt_gfx.width,
				draw_alpha: 0,
				disabled_graphic_alpha: .3
			});
			leaderboard_bt.addEventListener(TSEvent.CHANGED, onLeaderboardClick, false, 0, true);
			footer_holder.addChild(leaderboard_bt);
			
			leaderboard_ui = new LeaderboardUI(_w - _base_padd*2);
			leaderboard_ui.x = _base_padd;
			all_holder.addChild(leaderboard_ui);
			
			//create the faux footer so that we can do masking magic
			TFUtil.prepTF(rewards_title, false);
			rewards_title.htmlText = '<p class="job_rewards_title">Rewards</p>';
			rewards_title.x = _base_padd;
			rewards_title.y = _base_padd - 4;
			
			TFUtil.prepTF(rewards_body);
			rewards_body.x = rewards_title.x + rewards_title.width + _base_padd;
			rewards_body.y = _base_padd - 4;
			rewards_body.width = _w - rewards_body.x - _base_padd - leaderboard_bt.w - 5;
			
			footer_holder.addChild(rewards_title);
			footer_holder.addChild(rewards_body);
			all_holder.addChild(footer_holder);
			
			//optional bottom message
			TFUtil.prepTF(bottom_msg_tf);
			bottom_msg_tf.x = _base_padd;
			bottom_msg_tf.width = _w - _base_padd*2;
			footer_holder.addChild(bottom_msg_tf);
			
			//mask
			all_holder.mask = body_mask;
			addChild(body_mask);
			
			//back button
			var back_DO:DisplayObject = new AssetManager.instance.assets.back_circle();
			
			back_bt = new Button({
				label: '',
				name: 'back',
				graphic: back_DO,
				graphic_hover: new AssetManager.instance.assets.back_circle_hover(),
				graphic_disabled: new AssetManager.instance.assets.back_circle_disabled(),
				w: back_DO.width,
				h: back_DO.height,
				draw_alpha: 0
			});
			back_bt.x = -back_DO.width/2 + 1;
			back_bt.y = 12;
			addChild(back_bt);
			back_bt.addEventListener(TSEvent.CHANGED, onBackClick, false, 0, true);
			
			//toast
			toast = new Toast(_w - _base_padd*2);
			toast.x = _base_padd;
			_scroller.body.addChild(toast);
			
			//complete holder stuff
			TFUtil.prepTF(complete_tf);
			complete_tf.wordWrap = false;
			complete_tf.name = 'complete_tf';
			complete_tf.filters = StaticFilters.youDisplayManager_GlowA;
			complete_holder.addChild(complete_tf);
			addChild(complete_holder);
			
			//intro
			job_intro = new JobIntroUI(_w - _border_w*2, 10, _base_padd); //set real height in _draw()
			job_intro.addEventListener(TSEvent.CLOSE, hideIntro, false, 0, true);
			job_intro.addEventListener(TSEvent.CHANGED, onClaimClick, false, 0, true);
			job_intro.addEventListener(TSEvent.ACTIVITY_HAPPENED, onCustomNameClick, false, 0, true);
			addChild(job_intro);
			
			//details
			job_details = new JobDetailsUI(_w - (_base_padd + 10)*2, _body_min_h);
			job_details.x = _base_padd + 10;
			all_holder.addChild(job_details);
			
			//work
			job_work = new JobWorkUI(_w - (_base_padd + 10)*2, _body_min_h);
			all_holder.addChild(job_work);
			
			//setup the timer
			timeout_timer.addEventListener(TimerEvent.TIMER, onTimerTick, false, 0, true);
			
			//timeout stuff
			TFUtil.prepTF(claimed_tf, false);
			claimed_tf.x = _base_padd;
			claimed_tf.htmlText = '<p class="job_claimed">Placeholderp</p>';
			footer_holder.addChild(claimed_tf);
			
			TFUtil.prepTF(timeout_tf, false);
			timeout_tf.x = _base_padd;
			timeout_tf.htmlText = '<p class="job_duration">Placeholderp</p>';
			footer_holder.addChild(timeout_tf);
			
			is_built = true;
		}
		
		override public function start():void {			
			var job_info:JobInfo = JobManager.instance.job_info;
			
			if(!job_info){
				CONFIG::debugging {
					Console.warn('Uhhh, no job_info? No good!');
				}
				return;
			}
			
			//if it's open already and we got a start message fire it off for an update
			//this will happen when the client is requesting updated job data since there isn't a formal message
			if(visible) {
				update(job_info);
				return;
			}
			
			//if it's closed
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			leaderboard_ui.visible = false;
			back_bt.visible = false;
			
			//show the proper progress
			pb.visible = false;
			job_phase.hide();
			job_work.hide();
			
			if(job_info.phases.length == 1){
				pb.visible = true;
			}
			else {
				//show the phase UI for multi-phase jobs
				job_phase.show(false);
			}
			
			//set the rewards
			showRewards(job_info);
			
			//set progress percent
			updateProgress(job_info.perc);
			
			//handle the timer and title
			showTimerAndTitle(job_info);
			
			//if the player has yet to contribute, then we need to show the intro screen
			//if(!job_info.has_contributed) showIntro();
			complete_holder.visible = job_info.complete;
			
			var show_intro:Boolean = !job_info.complete && job_info.type != JobInfo.TYPE_ADD_FLOOR && job_info.type != JobInfo.TYPE_RESTORE;
			
			if(show_intro){
				showIntro();
			}
			else {
				showBuckets(job_info.buckets);
				if(job_info.complete) showComplete();
				job_intro.hide();
			}
			
			_jigger();
			
			//reset
			all_holder.y = _head_h + HOLDER_GAP;
			leaderboard_bt.disabled = false;
			
			//special stuff for other job types
			leaderboard_bt.visible = true;
			bottom_msg_tf.visible = false;
			if(job_info.type == JobInfo.TYPE_ADD_FLOOR || job_info.type == JobInfo.TYPE_RESTORE){
				leaderboard_bt.visible = false;
				
				//show the optional messsage
				bottom_msg_tf.htmlText = '<p class="job_bottom_msg">'+job_info.desc+'</p>';
				bottom_msg_tf.visible = true;
			}
			
			super.start();
			
			//listen for pack updates
			PackDisplayManager.instance.registerChangeSubscriber(this);
			
			//listen for skill updates
			model.worldModel.registerCBProp(onSkillChange, "pc", "skill_training");
			
			//listen for when groups are added/removed
			RightSideManager.instance.addEventListener(TSEvent.GROUPS_CHANGED, onGroupsChanged, false, 0, true);
			
			//make this bad boy visible
			visible = true;
		}
		
		public function update(job_info:JobInfo):void {
			//don't bother updating the dialog if it's not on screen
			if(!visible) return;
			
			//handle the timer and title
			showTimerAndTitle(job_info);
			
			//if this is a group hall and it expired, we show the intro again
			if(job_info.type == JobInfo.TYPE_GROUP_HALL && !job_info.owner_tsid){
				showIntro();
			}
			else if(job_intro.visible){
				job_intro.show();
			}
			else {
				if(!job_info.complete && job_info.time_until_available > 0){
					//we are getting the next phase for some reason, cock block that shit
					CONFIG::debugging {
						Console.warn('Got the next phase of a job, ignoring it!', job_info.complete, job_info.time_until_available);
					}
					return;
				}
				else {
					//set progress percent
					updateProgress(job_info.perc);
					updateBuckets(job_info.buckets);
					job_details.refresh();
				}
			}
			
			//is the job done?
			model.stateModel.fam_dialog_can_go = !job_info.complete;
			complete_holder.visible = false;
			if(job_info.complete && !job_work.is_working){
				showComplete();
			}
		}
		
		public function claimStatus(is_success:Boolean):void { 
			if(is_success){
				//if we've claimed the job, let's ask for the custom name
				if(JobManager.instance.job_info.type == JobInfo.TYPE_GROUP_HALL){
					job_intro.showCustomName();
				}
				//sometimes jobs don't need a name, but need to be claimed by someone
				else {
					hideIntro();
				}
			 } 
		}
		
		public function customNameStatus(is_success:Boolean):void { 
			//if we've named the job, go ahead and hide the intro
			if(is_success){
				hideIntro();
			}
			//reset the custom name
			else if(JobManager.instance.job_info.type != JobInfo.TYPE_GROUP_HALL){
				job_intro.showCustomName();
			}
		}
		
		public function setWork(work_payload:Object):void {
			back_bt.visible = false;
			job_details.visible = false;
			
			job_work.show(work_payload.units, work_payload.unit_duration, work_payload.unit_energy, work_payload.tool_class_id);
			job_work.y = -(body_mask.height*2);
			
			TSTweener.addTween(all_holder, {y:body_mask.height*2 + HOLDER_GAP + _head_h, time:ANIMATION_SPEED});
			
			//see if there are any polaroids
			hideAllPolaroids();
		}
		
		public function stopWork():void {			
			if(!visible) return;
			if(job_work.is_working) job_work.stop();
			
			//update before we go back
			update(JobManager.instance.job_info);
			
			if(!JobManager.instance.job_info.complete){
				JobManager.instance.maybeRequestJobInfo(true, true);
			}
			
			//set a 2 second timeout before auto going back
			StageBeacon.setTimeout(onBackClick, 2000);
		}
		
		public function updateRequirement(class_tsid:String, amount:int, is_work:Boolean):void {
			if(job_work.is_working && is_work) {
				job_work.increment(amount);
				return;
			}
			
			//hide polaroids if we have them
			hideAllPolaroids();
			
			//if not a work type animate back and show the toast
			if(parent && !is_work){
				//player gave something to the cause, animate something nice for them				
				onBackClick(null, animateDonation, [class_tsid, amount]);
			}
		}
		
		private function showTimerAndTitle(job_info:JobInfo):void {
			//if this job has a timeout on it, let's make sure we show it
			if(job_info.timeout){
				checkTimeout(job_info);
			}
			else if(claimed_tf.visible){
				claimed_tf.visible = false;
				timeout_tf.visible = false;
				if(timeout_timer.running) timeout_timer.stop();
			}
			
			//if we have a custom name, let's make sure the title is setup for it
			if(job_info.custom_name){
				if(_title_tf.text.indexOf(job_info.title+' for '+job_info.custom_name) == -1){
					_setTitle(job_info.title+' for '+job_info.custom_name);
				} 
			}
			else if(_title_tf.text.indexOf(job_info.title) == -1){
				_setTitle(job_info.title);
			}
		}
		
		private function checkTimeout(job_info:JobInfo):void {
			//when a job has a timeout, let's make sure we show who has it and such
			var client_ts:uint = TSFrontController.instance.getCurrentGameTimeInUnixTimestamp();
						
			if(current_timeout != job_info.timeout - client_ts){
				current_timeout = job_info.timeout - client_ts;
				timeout_timer.reset();
				
				if(!timeout_timer.running){
					timeout_timer.start();
					onTimerTick();
				}
			}
			else if(job_info.timeout - client_ts <= 0){
				current_timeout = 0;
				timeout_timer.stop();
			}
			
			timeout_tf.visible = current_timeout > 0;
			claimed_tf.visible = current_timeout > 0;
		}
		
		private function animateDonation(class_tsid:String, amount:int):void {
			var item:Item = model.worldModel.getItemByTsid(class_tsid);
			var item_label:String = amount != 1 ? item.label_plural : item.label;
			if(class_tsid == 'money_bag') item_label = amount != 1 ? 'Currants' : 'Currant';
			
			toast.show('You contributed '+amount+' '+item_label+'. Thanks.');
		}
		
		private function animatePolaroids(showing:Boolean, is_details:Boolean = false, remove:Boolean = false):void {
			//find the polaroids!
			var polaroid:PolaroidPicture;
			var i:int;
			var job_options:Vector.<JobOption> = JobManager.instance.job_info.options;
			var next_y:int = is_details ? 60 : 0;
			var label:String;
			
			//clear it out
			polaroids.length = 0;
			
			//show the polaroids
			if(job_options.length > 1){				
				for(i = 0; i < job_options.length; i++){
					//show the polaroid
					polaroid = getChildByName('polaroid_small'+i) as PolaroidPicture;
					label = job_options[int(i)].name ? job_options[int(i)].name : 'No Title?!';
					
					if(!polaroid){
						polaroid = new PolaroidPicture(POLAROID_SIZE, POLAROID_SIZE, label);
						polaroid.name = 'polaroid_small'+i;
						addChild(polaroid);
					}
					else {
						polaroid.label = label;
					}
					
					polaroid.x = _w - (is_details ? 15 : 35);
					polaroid.y = int(_head_h + next_y + polaroid.height/2);
					
					if(job_options[int(i)].image && showing) polaroid.setPictureURL(job_options[int(i)].image);
					
					polaroids.push(polaroid);
					
					next_y += polaroid.height;
				}
			}
			
			if(polaroids.length){
				TSTweener.removeTweens(polaroids);
				
				if(showing){
					TSTweener.addTween(polaroids, {scaleX:1, scaleY:1, alpha:1, time:.5});
					for(i = 0; i < polaroids.length; i++){
						TSTweener.addTween(polaroids[int(i)], {scaleX:0, scaleY:0, alpha:0, rotation:(i == 0 ? -30 : 30)});
						
						TSTweener.addTween(polaroids[int(i)], 
							{
								rotation:(i == 0 ? 8 : -8), 
								time:.6
							}
						);
					}
				}
				else {
					TSTweener.addTween(polaroids, {alpha:0, time:.3, delay:.3, transition:'easeInBack'});
					
					for(i = 0; i < polaroids.length; i++){
						TSTweener.addTween(polaroids[int(i)], 
							{
								scaleX:0, 
								scaleY:0,
								rotation:(i == 0 ? -30 : 30), 
								time:.6, 
								transition:'easeInBack', 
								onComplete:removePolaroid, 
								onCompleteParams:[remove, polaroids[int(i)]]
							}
						);
					}
				}
			}
		}
		
		private function removePolaroid(remove:Boolean, pic:PolaroidPicture):void {
			if(remove){
				if(pic.parent) pic.parent.removeChild(pic);
				pic = null;
			}
		}
		
		private function hideAllPolaroids():void {
			var i:int;
			var child:DisplayObject;
			
			for(i; i < numChildren; i++){
				child = getChildAt(i);
				if(child is PolaroidPicture && child.alpha > 0){
					polaroids.push(child);
				}
			}
			
			if(polaroids.length > 0) animatePolaroids(false, !job_intro.visible);
		}
				
		override public function end(release:Boolean):void {			
			visible = false;
			
			//if we are working, tell the server that we have stopped!
			if(job_work.is_working){
				job_work.stop();
				JobManager.instance.stopWorkFromClient(job_work.tool_tsid);
			}
			if (parent) parent.removeChild(this);
			if (release) TSFrontController.instance.releaseFocus(this);
			
			super.end(release);
			
			if (is_blocking_familiar_convos) TSFrontController.instance.unBlockFamiliarConvos();
			
			//do some cleanup
			if(job_intro.y == 0) hideIntro();
			if(complete_holder) complete_holder.rotation = 0;
			PackDisplayManager.instance.unRegisterChangeSubscriber(this);
			model.worldModel.unRegisterCBProp(onSkillChange, "pc", "skill_training");
			hideAllPolaroids();
			is_blocking_familiar_convos = false;
			current_timeout = 0;
			RightSideManager.instance.removeEventListener(TSEvent.GROUPS_CHANGED, onGroupsChanged);
		}
		
		private function updateProgress(percent:Number):void {
			if(JobManager.instance.job_info.phases.length > 1){
				job_phase.updateProgress(percent);
			}
			else {
				pb.update(percent);
				pb_amount.htmlText = '<p class="job_progress_amount">'+(percent != 0 && percent != 1 ? (percent*100).toFixed(1) : (percent*100))+'% complete</p>';
			}
		}
		
		private function showBuckets(buckets:Vector.<JobBucket>):void {
			//show the requirements/rewards
			var i:int;
			var total:int = buckets.length;
			var job_bucket:JobBucketUI;
			var holder:Sprite;
			var next_y:int;
			
			//make all the current buckets invisible
			for(i = 0; i < job_buckets.length; i++){
				job_bucket = job_buckets[int(i)];
				job_bucket.visible = false;
				job_bucket.y = 0;
			}
			
			for(i = 0; i < total; i++){
				//check if we have one in the pool we can repurpose
				if(job_buckets.length > i){
					job_bucket = job_buckets[int(i)];
				}
				//new one
				else {
					job_bucket = new JobBucketUI();
					job_buckets.push(job_bucket);
					req_holder.addChild(job_bucket);
				}
				
				job_bucket.show(buckets[int(i)]);
				job_bucket.y = next_y;
				
				next_y += JobRequirementsUI.BUTTON_HEIGHT + 40;
			}	
		}
		
		private function updateBuckets(buckets:Vector.<JobBucket>):void {
			//loop through the buckets and update them
			var i:int;
			var total:int = buckets.length;
			var job_bucket:JobBucketUI;
			
			for(i; i < total; i++){
				if(job_buckets.length > i){
					job_bucket = job_buckets[int(i)];
					job_bucket.show(buckets[int(i)]);
				}
			}
		}
		
		private function showRewards(job_info:JobInfo):void {			
			//if this job is a group hall, let's hide the rewards until the UI gets fixed
			if(job_info && ((job_info.claim_reqs && job_info.claim_reqs.length > 0) || job_info.type == JobInfo.TYPE_RESTORE)){
				rewards_title.visible = rewards_body.visible = false;
				return;
			} 
			
			var rewards:Vector.<Reward> = job_info.rewards;
			var rewards_txt:String = '<b>All contributors</b> will split: ';
						
			//the rewards
			rewards_txt += Rewards.convertToString(rewards) + '<br><br>';
			
			//Top performers
			if(job_info.performance_percent > 0){
				rewards_txt += '<b>The top '+job_info.performance_percent+'% of players</b> will also split: ';
			}
			else if(job_info.performance_cutoff > 0){
				rewards_txt += '<b>The top '+(job_info.performance_cutoff != 1 ? job_info.performance_cutoff + ' players' : 'player')+'</b> will also get: ';
			}
			
			rewards = job_info.performance_rewards;
			rewards_txt += Rewards.convertToString(rewards);
			
			rewards_body.htmlText ='<p class="job_rewards_body">' + rewards_txt + '</p>';
			
			rewards_title.visible = (job_info.rewards && job_info.rewards.length) || (job_info.performance_rewards && job_info.performance_rewards.length);
			rewards_body.visible = rewards_title.visible;
			
			job_intro.setRewardText(rewards_txt);
		}
		
		private function onBackClick(event:TSEvent = null, complete_function:Function = null, complete_params:Array = null):void {
			var animation_time:Number = .5;
			back_bt.disabled = true;
			back_bt.visible = false;
			
			TSTweener.removeTweens(all_holder);
			TSTweener.addTween(all_holder, {y:_head_h + HOLDER_GAP, time:animation_time, 
				onComplete:function():void {
					back_bt.disabled = false;
					
					//if we had some work done, let's animate it
					if(job_work.did_work){
						toast.show(job_work.getContributeMsg());
					}
				}
			});
			
			//see if there are any polaroids
			hideAllPolaroids();
			
			if(complete_function != null){ 
				TSTweener.addTween(all_holder, {onComplete:complete_function, onCompleteParams:complete_params, delay:animation_time});
			}
		}
		
		private function onLeaderboardClick(event:TSEvent):void {
			//send a request to the GS to get the leaderboard data
			if(leaderboard_bt.disabled) return;
			
			JobManager.instance.getLeaderboard();
			leaderboard_bt.disabled = true;
		}
		
		public function onPackChange():void {
			//ask the server for updated job info as we may have lost/aquired an item
			if(job_work.is_working) return;
			if(!visible) return;
			if(job_intro.visible) job_intro.show();
			JobManager.instance.maybeRequestJobInfo();
		}
		
		private function onSkillChange(skill_training:PCSkill):void {
			//ask the server for updated job info as we may have gained a skill needed
			if(job_work.is_working) return;
			if(!visible) return;
			JobManager.instance.maybeRequestJobInfo();
		}
		
		private function onClaimClick(event:TSEvent = null):void {
			//confirm they want to claim the job
			TSFrontController.instance.confirm(
				new ConfirmationDialogVO(
					function(value:*):void {
						if(value !== false) {
							JobManager.instance.claim(value is String ? value : '');
						}
					},
					'Would you like to claim this project? I\'ll go ahead and give you '+StringUtil.formatTime(JobManager.instance.job_info.duration*60)+
					' to finish it up. Can you hack it?',
					[
						{value: (event && event.data is Button ? event.data.value : true), label: 'Yes, I can!'},
						{value: false, label: 'Never mind'},						
					],
					false
				)
			);
		}
		
		private function onTimerTick(event:TimerEvent = null):void {
			//let whoever needs to know about the timer know
			current_timeout--;
			dispatchEvent(new TSEvent(TSEvent.TIMER_TICK, current_timeout));
			
			if(!JobManager.instance.job_info) return;
			
			//if the claim name has changed
			/*
			if(JobManager.instance.job_info.owner_tsid != model.worldModel.pc.tsid && claimed_tf.text != 'Claimed by '+JobManager.instance.job_info.owner_tsid){
				claimed_tf.htmlText = '<p class="job_claimed">Claimed by ' +
					'<a href="event:'+TSLinkedTextField.LINK_PC+'|'+JobManager.instance.job_info.owner_tsid+'">'+JobManager.instance.job_info.owner_label+'</a>' +
					'</p>';
			}
			else if(claimed_tf.text != 'Claimed by you!'){
				claimed_tf.htmlText = '<p class="job_claimed">Claimed by <b>you!</b></p>';
			}
			*/
			/** TODO SY, MAKE THIS NOT SET HTML EACH SECOND **/
			const job_info:JobInfo = JobManager.instance.job_info;
			const group:Group = job_info.group_tsid ? model.worldModel.getGroupByTsid(job_info.group_tsid) : null;
			
			if(job_info.owner_label){				
				//claimed by you?
				if(!group && job_info.owner_tsid == model.worldModel.pc.tsid){
					claimed_tf.htmlText = '<p class="job_claimed">Claimed by <b>you!</b></p>';
				}
				else {
					//claimed by a group or another player
					var claim_tsid:String = group ? group.tsid : job_info.owner_tsid;
					var claim_label:String = group ? group.label : job_info.owner_label;
					
					claimed_tf.htmlText = '<p class="job_claimed">Claimed by ' +
						'<a href="event:'+(group ? TSLinkedTextField.LINK_GROUP : TSLinkedTextField.LINK_PC)+'|'+claim_tsid+'">'+claim_label+'</a>' +
						'</p>';
				}
			}
			
			//is there time left?
			if(current_timeout < 60 && current_timeout > 0){
				timeout_tf.htmlText = '<p class="job_duration">Time left: <span class="job_item_disabled">Less than a minute!</span></p>';
			}
			else if(current_timeout > 0) {
				timeout_tf.htmlText = '<p class="job_duration">Time left: '+StringUtil.formatTime(current_timeout)+'</p>';
			}
			else {
				timeout_tf.text = '';
				timeout_tf.visible = false;
				claimed_tf.visible = false;
				current_timeout = 0;
				timeout_timer.stop();
				
				//reset the title
				_setTitle(job_info.title);
			}
		}
		
		private function onCustomNameClick(event:TSEvent):void {
			//confirm they want this name
			TSFrontController.instance.confirm(
				new ConfirmationDialogVO(
					function(value:*):void {
						if(value !== false) {
							//send of the custom name request to the server
							JobManager.instance.createCustomName(String(event.data));
						}
						else {
							job_intro.showCustomName();
						}
					},
					'Your Organization will be known as "'+event.data+'". This sound good to you?',
					[
						{value: true, label: 'Yes, so good!'},
						{value: false, label: 'Never mind'},						
					],
					false
				)
			);
		}
		
		private function onGroupsChanged(event:TSEvent):void {
			//check to see what kind of job this is... if it's a group hall
			//and we are no longer a member of the group, show the intro again
			var job_info:JobInfo = JobManager.instance.job_info;
			if(!job_info || (job_info && job_info.type != JobInfo.TYPE_GROUP_HALL)) return;
			if(!job_info.group_tsid) return;
			
			//ok we have a group and the job is a group hall. Is the player a member of the group?
			var group:Group = model.worldModel.getGroupByTsid(job_info.group_tsid);
			if((!group || (group && !group.is_member)) && !job_intro.visible){
				showIntro();
			}
		}
		
		override protected function enterKeyHandler(e:KeyboardEvent):void {
			if(job_intro.visible) {
				if(job_intro.can_close){
					hideIntro();
				}
				else if(job_intro.showing_custom_name && job_intro.custom_name != ''){
					//send it off to the server
					onCustomNameClick(new TSEvent(TSEvent.ACTIVITY_HAPPENED, job_intro.custom_name));
				}
				else if(job_intro.can_claim){
					//must want to claim
					onClaimClick();
				}
				else if(job_intro.group_tsid){
					TSFrontController.instance.openGroupsPage(null, job_intro.group_tsid);
				}
			}
			super.enterKeyHandler(e);
		}
		
		private function showIntro(event:TSEvent = null):void {			
			TSTweener.removeTweens(job_intro);
			
			var job_options:Vector.<JobOption> = JobManager.instance.job_info.options;
			var polaroid:PolaroidPicture;
			var i:int;
			var next_y:int;
			
			_jigger();
			
			//set up the UI
			job_intro.x = _border_w;
			job_intro.y = _head_sp.y + _title_tf.y + _title_tf.height + 5;
			job_intro.show();
			
			//Animate with a rotation and scale
			animatePolaroids(true);
			
			pb_holder.alpha = 0;
			
			//place the choice arrows
			if(polaroids.length > 0){
				polaroid = polaroids[0];
				job_intro.choice_arrows.x = int(polaroid.x - polaroid.width/2 - job_intro.choice_arrows.width - 20);
				job_intro.choice_arrows.y = polaroid.y - job_intro.y + 15;
			}
			
			job_intro.choice_arrows.visible = (!job_intro.map_bg.visible && polaroids.length > 0);
		}
		
		private function hideIntro(event:Event = null):void {
			if(!job_intro.visible) return;
			
			var job_info:JobInfo = JobManager.instance.job_info;
			
			if (!job_info) return;
			
			//place the stuff behind the intro
			showBuckets(job_info.buckets);
			
			//hide the polaroid(s)
			hideAllPolaroids();
			
			TSTweener.addTween(pb_holder, {alpha:1, time:.3, transition:'linear'});
			TSTweener.addTween(job_intro, {alpha:0, time:.3, transition:'linear',
				onComplete:function():void {
					job_intro.hide();
					job_intro.alpha = 1;
				}
			});
			
			_jigger();
		}
		
		private function showComplete():void {			
			is_blocking_familiar_convos = true;
			if(complete_holder.visible) return;
			complete_holder.visible = true;
			
			const phases:Vector.<JobPhase> = JobManager.instance.job_info.phases;
			const is_project_complete:Boolean = phases[phases.length-1].is_complete;
			const complete_txt:String = '<p class="job_complete">' + (!is_project_complete ? 'PHASE<br>COMPLETE' : 'PROJECT<br>COMPLETE')+'</p>';
			const can_tween:Boolean = complete_tf.htmlText != complete_txt || !is_project_complete;
			
			complete_holder.x = int(_w/2);
			complete_holder.y = int(_h/2) - 25;
			complete_tf.htmlText = complete_txt;
			complete_tf.x = int(-complete_tf.width/2);
			complete_tf.y = int(-complete_tf.height/2);
			
			complete_holder.scaleX = complete_holder.scaleY = 0;
			if(can_tween){
				TSTweener.addTween(complete_holder, {scaleX:1, scaleY:1, rotation:715, time:1});
			}
			else {
				complete_holder.scaleX = complete_holder.scaleY = 1;
				complete_holder.rotation = 715;
			}
			
			//disable the leaderboard until the last phase
			leaderboard_bt.disabled = !is_project_complete;
			
			//auto close the window if it's not on it's last phase
			if(!is_project_complete){
				StageBeacon.setTimeout(end, 10000, true);
			}
		}
		
		private function hideComplete():void {
			//useful if clicking leaderboard button after the job is done
			SpriteUtil.clean(complete_holder);
		}
		
		public function showLeaderboard(leaderboard:Leaderboard):void {						
			back_bt.visible = true;
			job_details.visible = false;
			
			leaderboard_ui.visible = true;
			leaderboard_ui.y = -body_mask.height;
			leaderboard_ui.show(leaderboard);
			
			TSTweener.removeTweens(all_holder);
			TSTweener.addTween(all_holder, {y:body_mask.height + HOLDER_GAP + _head_h, time:ANIMATION_SPEED});
			
			leaderboard_bt.disabled = false;
			
			//if the job is complete, hide the "complete" graphics
			hideComplete();
		}
		
		public function showDetails(req_id:String):void {
			var req:Requirement = JobManager.instance.getReqById(req_id);
			if(!req){
				CONFIG::debugging {
					Console.warn('Can not find a req with id: '+req_id);
				}
				return;
			}
			
			//reset and animate
			back_bt.visible = true;
			leaderboard_ui.visible = false;
			job_details.visible = true;
			job_details.show(req);
			job_details.x = int(_w/2 - job_details.width/2);
			job_details.y = -body_mask.height;
			
			TSTweener.removeTweens(all_holder);
			TSTweener.addTween(all_holder, {y:body_mask.height + HOLDER_GAP + _head_h, time:ANIMATION_SPEED});
			
			//if we have some options, go ahead and animate the polaroids
			if(JobManager.instance.job_info.options.length > 1){
				animatePolaroids(true, true);
			}
			
			//if the toast is still open, hide it
			if(toast.is_open) toast.hide(0);
		}
		
		override protected function _draw():void {
			super._draw();
						
			//faux footer
			var g:Graphics = footer_holder.graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.drawRect(0, 0, _w, Math.max(int(rewards_body.height + _base_padd*2 - 4), leaderboard_bt.height + 50));
			g.beginFill(_body_border_c);
			g.drawRect(0, 0, _w, 1);
			
			//mask
			g = body_mask.graphics;
			g.clear();
			g.beginFill(0);
			g.drawRoundRectComplex(_border_w, 1, _w - _border_w*2, _body_h-_border_w-1-HOLDER_GAP, 0, 0, window_border.corner_rad/2, window_border.corner_rad/2);
			
			//set the job intro height here, because in showIntro it doesn't like it
			if(job_intro.visible) job_intro.h = body_mask.height + HOLDER_GAP + 10;
		}
		
		override protected function _jigger():void {
			super._jigger();
			
			_title_tf.x = _base_padd;
			_title_tf.y = 15;
			_subtitle_tf.y = _title_tf.y + _title_tf.height - 4;
			
			_head_h = (_subtitle_tf.visible ? _subtitle_tf.y + _subtitle_tf.height : _title_tf.y + _title_tf.height) + _base_padd;
			
			pb_holder.y = _head_h;
						
			footer_holder.y = Math.max(int(req_holder.height + HOLDER_GAP + 100), _body_min_h) - footer_holder.height;
			toast.y = footer_holder.y + HOLDER_GAP - 6;
			
			claimed_tf.y = int(footer_holder.height/2 - (claimed_tf.height + timeout_tf.height)/2) - 4;
			timeout_tf.y = int(claimed_tf.y + claimed_tf.height);
						
			_body_h = footer_holder.y + footer_holder.height + 30;
			
			body_mask.y = _head_h + HOLDER_GAP;
			
			_scroller.h = _body_h;
						
			_h = _head_h + _body_h + _foot_h;
			
			_draw();
			
			leaderboard_bt.y = int(footer_holder.height/2 - leaderboard_bt.height/2) - 6;
			
			//set the optional footer message
			if(bottom_msg_tf.visible){
				bottom_msg_tf.y = int(footer_holder.height/2 - bottom_msg_tf.height/2 - 4);
			}
			
			_scroller.refreshAfterBodySizeChange();
			
			req_holder.x = int(_w/2 - req_holder.width/2);
		}
		
		public function get spirit_id():String { return _spirit_id; }
		public function set spirit_id(value:String):void { _spirit_id = value; }
		
		public function get job_id():String { return _job_id; }
		public function set job_id(value:String):void { _job_id = value; }
	}
}