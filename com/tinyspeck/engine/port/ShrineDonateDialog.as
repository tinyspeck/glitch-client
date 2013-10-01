package com.tinyspeck.engine.port
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.DonationFavor;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.giant.GiantFavor;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.data.pc.PCStats;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.BigDialog;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.FavorProgressBar;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;
	
	public class ShrineDonateDialog extends BigDialog implements IPackChange
	{
		/* singleton boilerplate */
		public static const instance:ShrineDonateDialog = new ShrineDonateDialog();
		
		private static const HOLDER_WH:uint = 132;
		private static const ICON_WH:uint = 100;
		private static const INFO_X:uint = 175;
		private static const HIGH_OVERFLOW:uint = 30; //how much over the donation do we show the red vs. yellow warning
		
		private var item_holder:Sprite = new Sprite();
		private var right_holder:Sprite = new Sprite();
		private var more_holder:Sprite = new Sprite();
		
		private var donate_tf:TextField = new TextField();
		private var favor_tf:TextField = new TextField();
		private var foot_favor_tf:TextField = new TextField();
		private var foot_total_tf:TextField = new TextField();
		private var more_favor_tf:TextField = new TextField();
		
		private var icon_view:ItemIconView;
		private var qp:QuantityPicker;
		private var donate_bt:Button;
		private var pb:FavorProgressBar;
		
		private var cdVO:ConfirmationDialogVO;
		
		private var ehsp_count:int;
		private var fhsp_count:int;
		
		private var is_built:Boolean;
		
		public function ShrineDonateDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = 500;
			_head_min_h = 50;
			_body_min_h = 175;
			_foot_min_h = 90;
			_base_padd = 20;
			_close_bt_padd_top = 11;
			_draggable = true;
			
			_construct();
		}
		
		private function buildBase():void {
			//item holder
			var g:Graphics = item_holder.graphics;
			g.beginFill(0xffffff);
			g.drawRoundRect(1, 1, HOLDER_WH, HOLDER_WH, 10);
			item_holder.x = item_holder.y = _base_padd;
			item_holder.filters = StaticFilters.copyFilterArrayFromObject({color:0xaccbd3}, StaticFilters.black_GlowA); 
			_scroller.body.addChild(item_holder);
			
			//right side
			TFUtil.prepTF(donate_tf);
			donate_tf.width = _w - INFO_X;
			right_holder.addChild(donate_tf);
			
			TFUtil.prepTF(favor_tf, false);
			right_holder.addChild(favor_tf);
			
			//qty picker
			qp = new QuantityPicker({
				w: 130,
				h: 36,
				name: 'qp',
				minus_graphic: new AssetManager.instance.assets.minus_red(),
				plus_graphic: new AssetManager.instance.assets.plus_green(),
				max_value: 1, // to be changed
				min_value: 1,
				button_wh: 20,
				button_padd: 3,
				show_all_option: true
			});
			qp.addEventListener(TSEvent.CHANGED, onQuantityChange, false, 0, true);
			right_holder.addChild(qp);
			
			//donate bt
			donate_bt = new Button({
				label: 'Donate',
				name: 'donate_bt',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR,
				w: 120
			});
			donate_bt.x = int(qp.width + 5);
			donate_bt.addEventListener(TSEvent.CHANGED, onDonateClick, false, 0, true);
			right_holder.addChild(donate_bt);
			
			right_holder.x = INFO_X;
			right_holder.y = _base_padd;
			_scroller.body.addChild(right_holder);
			
			//overflow/donated too much
			const warning_DO:DisplayObject = new AssetManager.instance.assets.buff_bang_white();
			warning_DO.filters = [ColorUtil.getInvertColors()];
			warning_DO.alpha = .5;
			warning_DO.x = 8;
			warning_DO.y = 6;
			more_holder.addChild(warning_DO);
			
			TFUtil.prepTF(more_favor_tf);
			more_favor_tf.x = int(warning_DO.x + warning_DO.width + 3);
			more_favor_tf.y = 5;
			more_favor_tf.width = _w - INFO_X - _base_padd - more_favor_tf.x - 2;
			more_holder.addChild(more_favor_tf);
			more_holder.filters = StaticFilters.copyFilterArrayFromObject({inner:true, alpha:.2}, StaticFilters.black_GlowA);
			right_holder.addChild(more_holder);
			
			//footer stuff
			_foot_sp.visible = true;
			_foot_sp.mouseEnabled = _foot_sp.mouseChildren = false;
			
			TFUtil.prepTF(foot_favor_tf, false);
			foot_favor_tf.x = _base_padd;
			foot_favor_tf.y = _base_padd - 10;
			foot_favor_tf.htmlText = '<p class="shrine_donate_footer">placeholder</p>';
			_foot_sp.addChild(foot_favor_tf);
			
			TFUtil.prepTF(foot_total_tf, false);
			foot_total_tf.y = foot_favor_tf.y + 2;
			_foot_sp.addChild(foot_total_tf);
			
			//progress bar
			pb = new FavorProgressBar(_w - _base_padd*2, 36);
			pb.x = _base_padd;
			pb.y = int(foot_favor_tf.y + foot_favor_tf.height + 3);
			_foot_sp.addChild(pb);
			
			is_built = true;
		}
		
		override public function start():void {
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			
			const donation_favor:DonationFavor = ShrineManager.instance.donation_favor;
			if(!donation_favor){
				CONFIG::debugging {
					Console.warn('Missing the donation_favor, bad scene!!');
				}
				return;
			}
			
			const item:Item = model.worldModel.getItemByTsid(donation_favor.item_class);
			if(!item){
				CONFIG::debugging {
					Console.warn('No clue what this item is! '+donation_favor.item_class);
				}
				return;
			}
			
			//set the title of what we are donating to
			_setTitle('Donate what to '+giant_favor.label+'?');
			
			//load the icon
			if(icon_view) {
				icon_view.parent.removeChild(icon_view);
				icon_view.dispose();
			}
			icon_view = new ItemIconView(donation_favor.item_class, ICON_WH);
			icon_view.x = icon_view.y = int(HOLDER_WH/2 - ICON_WH/2);
			item_holder.addChild(icon_view);
			
			//set donate text
			donate_tf.htmlText = '<p class="shrine_donate">Donate '+(!donation_favor.single_stack_only ? item.label_plural : item.label)+'</p>';
			qp.y = int(donate_tf.height + 6);
			donate_bt.y = qp.y - 1;
			donate_bt.disabled = false;
			
			//favor text
			var favor_txt:String = '<p class="shrine_donate_favor">';
			if(donation_favor.item_favor){
				favor_txt += 'Grants <b>'+StringUtil.formatNumberWithCommas(donation_favor.item_favor)+' favor</b> each';
			}
			else {
				favor_txt += giant_favor.label+' will give you <b>no favor</b> for this';
			}
			favor_txt += '</p>';
			favor_tf.htmlText = favor_txt;
			favor_tf.y = int(donate_bt.y + donate_bt.height + 8);
			
			//we need to set our powder counts
			ehsp_count = model.worldModel.pc.hasHowManyItems('extremely_hallowed_shrine_powder', true);
			fhsp_count = model.worldModel.pc.hasHowManyItems('fairly_hallowed_shrine_powder', true);
			
			//refresh things
			model.worldModel.registerCBProp(onStatsChanged, "pc", "stats");
			onStatsChanged(model.worldModel.pc.stats);
			PackDisplayManager.instance.registerChangeSubscriber(this);
			onPackChange();
			
			//pre-populate it with as much as it would take to max it out
			tryToFillFavor();
			
			//make sure we aren't showing the progress bar over the shrine any more
			ShrineManager.instance.hideProgressBar();
			
			super.start();
		}
		
		override public function end(release:Boolean):void {
			super.end(release);
			PackDisplayManager.instance.unRegisterChangeSubscriber(this);
			model.worldModel.unRegisterCBProp(onStatsChanged, "pc", "stats");
			
			//make sure we aren't showing the progress bar over the shrine any more
			ShrineManager.instance.hideProgressBar();
		}
		
		private function tryToFillFavor():void {
			const donation_favor:DonationFavor = ShrineManager.instance.donation_favor;
			if(!donation_favor) return;
			
			const pc:PC = model.worldModel.pc;
			const how_many:int = pc ? pc.hasHowManyItems(donation_favor.item_class) : 0;
			
			//set the amount
			if(donation_favor.item_favor) {
				var amount:int = Math.min(
					how_many, 
					Math.floor((giant_favor.max-giant_favor.current)/donation_favor.item_favor),
					Math.floor((giant_favor.max_daily_favor-giant_favor.cur_daily_favor)/donation_favor.item_favor)
				);
			}
			else {
				//it's not worth anything, so just set the qp to 1
				amount = 1;
			}
			
			//set the value
			qp.value = amount;
		}
		
		public function onPackChange():void {
			//make sure the max value for the qp is right
			const donation_favor:DonationFavor = ShrineManager.instance.donation_favor;
			if(!donation_favor) return;
			
			const pc:PC = model.worldModel.pc;
			const how_many:int = pc ? pc.hasHowManyItems(donation_favor.item_class) : 0;
			
			//check our powder counts, if they have changed we need to go ask the server for updated info
			const current_ehsp_count:int = pc.hasHowManyItems('extremely_hallowed_shrine_powder', true);
			const current_fhsp_count:int = pc.hasHowManyItems('fairly_hallowed_shrine_powder', true);
			if(current_ehsp_count != ehsp_count || current_fhsp_count != fhsp_count){
				//get that updated info
				ShrineManager.instance.favorRequest(donation_favor.shrine_tsid, donation_favor.item_class, true);
				return;
			}

			//set the max
			qp.max_value = Math.min(how_many, 9999);
			donate_bt.disabled = how_many == 0;
			
			//update the total
			var total_txt:String = '<p class="shrine_donate_footer_total">';
			total_txt += 'You have '+StringUtil.formatNumberWithCommas(how_many);
			total_txt += '</p>';
			foot_total_tf.htmlText = total_txt;
			foot_total_tf.x = int(_w - foot_total_tf.width - _base_padd);
			
			//update the label
			onQuantityChange();
		}
		
		private function onStatsChanged(pc_stats:PCStats = null):void {
			//update the quantity (which takes care of the progress bar)
			onQuantityChange();
		}
		
		private function onQuantityChange(event:TSEvent = null):void {
			//update the label on the donate button
			const amount:int = qp.value as int;
			donate_bt.label = 'Donate '+amount;
			
			//make sure the pb is up to date
			const donation_favor:DonationFavor = ShrineManager.instance.donation_favor;
			if(!donation_favor || !giant_favor) return;
			
			//set the amount
			const item:Item = model.worldModel.getItemByTsid(donation_favor.item_class);
			if(!item) return;
			
			var favor_txt:String = '<p class="shrine_donate_footer">';
			favor_txt += 'Favor for '+StringUtil.formatNumberWithCommas(amount)+' <b>'+(amount != 1 ? item.label_plural : item.label)+'</b>';
			favor_txt += '</p>';
			foot_favor_tf.htmlText = favor_txt;
			
			//this might put us over the daily limit... let's find out
			const total_amount:Number = amount * donation_favor.item_favor;
			const donation_amount:Number = Math.min(total_amount, giant_favor.max_daily_favor - giant_favor.cur_daily_favor);
			const favor_perc:Number = (total_amount + giant_favor.current) / giant_favor.max;
			
			//set the pb params
			pb.setCurrentAndMax(giant_favor.current, giant_favor.max);
			pb.setDonationChange(total_amount, amount > 1 && donation_favor.single_stack_only);
			
			//set up the warnings if we have any
			more_holder.visible = favor_perc > 1 || donation_amount < total_amount;
			more_holder.y = more_holder.visible ? int(favor_tf.y + favor_tf.height + 11) : 0;
			if(more_holder.visible){
				//figure out which version of the holder to show
				const overflow:Number = (total_amount + giant_favor.current) - giant_favor.max;
				var overflow_str:String = StringUtil.formatNumberWithCommas(overflow);
				if(overflow_str.indexOf('.') != -1){
					//let's trim it down
					overflow_str = StringUtil.formatNumberWithCommas(Number(overflow.toFixed(1)));
				}
				
				const is_way_over:Boolean = overflow > HIGH_OVERFLOW || total_amount - donation_amount > HIGH_OVERFLOW;
				
				var more_txt:String = '<p class="shrine_donate_more">';
				if(is_way_over) more_txt += '<span class="shrine_donate_more_high">';
				if(overflow > 0) {
					more_txt += 'This will spend <b>'+overflow_str+' favor</b> more than needed';
				}
				else if(donation_amount < total_amount){
					//we are here because of the daily donation max
					more_txt += 'This is <b>'+StringUtil.formatNumberWithCommas(total_amount - donation_amount)+' favor</b> over your daily limit';
				}
				if(is_way_over) more_txt += '</span>';
				more_txt += '</p>';
				more_favor_tf.htmlText = more_txt;
				
				var g:Graphics = more_holder.graphics;
				g.clear();
				g.beginFill(!is_way_over ? 0xf1e9c6 : 0x8e2824);
				g.drawRoundRect(0, 0, _w - INFO_X - _base_padd, int(more_favor_tf.height + more_favor_tf.y*2), 10);
			}
		}
		
		private function onDonateClick(event:TSEvent):void {
			SoundMaster.instance.playSound(!donate_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(donate_bt.disabled) return;
			
			const donation_favor:DonationFavor = ShrineManager.instance.donation_favor;
			if(!donation_favor) return;
			
			donate_bt.disabled = true;
			
			//check to see if they are going to be donating a ton of points over
			const total_amount:Number = (qp.value as int) * donation_favor.item_favor;
			const donation_amount:Number = Math.min(total_amount, giant_favor.max_daily_favor - giant_favor.cur_daily_favor);
			const overflow:Number = (total_amount + giant_favor.current) - giant_favor.max;
			const is_way_over:Boolean = overflow > HIGH_OVERFLOW || total_amount - donation_amount > HIGH_OVERFLOW;
			if(is_way_over){
				//we need to confirm they want to do this
				if(!cdVO){
					cdVO = new ConfirmationDialogVO();
					cdVO.title = 'Are you sure?';
					cdVO.escape_value = false;
					cdVO.choices = [
						{value:true, label:'Yes, please donate!'},
						{value:false, label:'Nevermind'}
					];
					cdVO.callback = onDonateConfirm;
				}
				
				var overflow_str:String = StringUtil.formatNumberWithCommas(overflow);
				if(overflow_str.indexOf('.') != -1){
					//let's trim it down
					overflow_str = StringUtil.formatNumberWithCommas(Number(overflow.toFixed(1)));
				}
				
				var confirm_txt:String = 'This will use <b>'+overflow_str+' more favor points</b> than what is needed for this emblem.';
				
				if(donation_amount < total_amount){
					//we are here because of the daily donation max
					overflow_str = StringUtil.formatNumberWithCommas(total_amount - donation_amount);
					if(overflow_str.indexOf('.') != -1){
						//let's trim it down
						overflow_str = StringUtil.formatNumberWithCommas(Number((total_amount - donation_amount).toFixed(1)));
					}
					
					confirm_txt = 'This is <b>'+overflow_str+' favor points</b> over your daily limit.';
				}
				
				confirm_txt += ' Are you sure you want to make this donation?<br>(You won\'t get those points back!)';
				
				cdVO.txt = confirm_txt;
				
				//ask the player if they want to waste a bunch of favor like a dummy
				TSFrontController.instance.confirm(cdVO);
			}
			else {
				onDonateConfirm(true);
			}
		}
		
		private function onDonateConfirm(is_donate:Boolean):void {
			if(is_donate){
				//fire it off to the server
				ShrineManager.instance.donate(qp.value as int);
			}
			else {
				donate_bt.disabled = false;
			}
		}
		
		private function get giant_favor():GiantFavor {
			const donation_favor:DonationFavor = ShrineManager.instance.donation_favor;
			if(!donation_favor) return null;
			
			return model.worldModel.pc.stats.favor_points.getFavorByName(donation_favor.giant_tsid);
		}
	}
}