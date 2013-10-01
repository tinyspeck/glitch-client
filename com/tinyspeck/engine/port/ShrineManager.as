package com.tinyspeck.engine.port
{
	import com.tinyspeck.tstweener.TSTweener;
	
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.DonationFavor;
	import com.tinyspeck.engine.data.giant.GiantFavor;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.NetOutgoingItemstackVerbVO;
	import com.tinyspeck.engine.net.NetOutgoingShrineFavorRequestVO;
	import com.tinyspeck.engine.net.NetOutgoingShrineSpendVO;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.view.itemstack.LocationItemstackView;
	import com.tinyspeck.engine.view.ui.FavorProgressBar;
	import com.tinyspeck.engine.view.util.StaticFilters;

	/*
	{
		"type":shrine_start
		"speed_up":0 -- in seconds how much faster things will speed up
		"is_learning":false
		"spend_points":0 -- how many you CAN spend (if learning is true and points are zero, it means you've maxed out your speed learning)
		"itemstack_tsid":IHH10UHGJ1D15VM
		"favor_points":67
		"emblem_cost":1000
		"giant_name":Alph
		"giant_rel":p, s, u -- primary, secondary, unrelated
	}
	*/
	
	public class ShrineManager
	{
		/* singleton boilerplate */
		public static const instance:ShrineManager = new ShrineManager();
		
		public var donate_verb:String = 'donate_to'; //this may change someday, who knows...
		
		private var after_request_func:Function; //dragVO sets this
		
		private var progress_bar:FavorProgressBar;
		private var _shrine_tsid:String;
		private var _donation_favor:DonationFavor;
		
		private var open_favor_dialog:Boolean;
		private var loading_request:Boolean;
		
		public function ShrineManager(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		public function start(payload:Object):void {			
			if(payload.error){
				showError(payload.error.msg);
				CONFIG::debugging {
					Console.warn('shrine start failed!');
				}
				return;
			}
			
			if(payload.itemstack_tsid){
				_shrine_tsid = payload.itemstack_tsid;
				
				ShrineDialog.instance.payload = payload;
				ShrineDialog.instance.start();
			}else{
				showError('shrine lacking data!');
				CONFIG::debugging {
					Console.warn('The shrine manager did not receive a TSID!');
				}
			}
		}
		
		public function spend():void {
			TSFrontController.instance.genericSend(new NetOutgoingShrineSpendVO(_shrine_tsid), spendHandler, spendHandler);
		}
		
		private function spendHandler(nrm:NetResponseMessageVO):void {
			if (nrm.success) {
				//spend was good, update the UI
				ShrineDialog.instance.spend();
			} else {
				//ruh roh
				ShrineDialog.instance.maybeEnableSpendButton();
				if (nrm.payload.error){
					showError(nrm.payload.error.msg);
				}
				CONFIG::debugging {
					Console.warn('shrine spend failed!');
				}
			}
		}
		
		public function donate(amount:int):void {
			//send the donate verb off to the server
			const verbVO:NetOutgoingItemstackVerbVO = new NetOutgoingItemstackVerbVO(
				_donation_favor.shrine_tsid, 
				donate_verb, 
				1
			);
			verbVO.target_item_class = _donation_favor.item_class;
			verbVO.target_item_class_count = amount;
			TSFrontController.instance.sendItemstackVerb(verbVO, onDonate, onDonate);
		}
		
		private function onDonate(nrm:NetResponseMessageVO):void {
			//close the dialog if it's open
			if(ShrineDonateDialog.instance.parent) {
				ShrineDonateDialog.instance.end(true);
			}
			
			//if there was an error
			if(nrm.payload.error){
				showError(nrm.payload.error.msg);
			}
		}
		
		public function reload():void {
			TSFrontController.instance.sendItemstackVerb(
				new NetOutgoingItemstackVerbVO(_shrine_tsid, 'check_favor', 1)
			);
		}
		
		public function favorRequest(shrine_tsid:String, item_class:String, show_dialog:Boolean, after_func:Function = null):void {
			//go ask the server for more data
			after_request_func = after_func;
			if(shrine_tsid && item_class){
				_donation_favor = DonationFavor.fromAnonymous({shrine_tsid:shrine_tsid, item_class:item_class});
				open_favor_dialog = show_dialog;
				loading_request = true;
				TSFrontController.instance.genericSend(new NetOutgoingShrineFavorRequestVO(shrine_tsid, item_class), onRequest, onRequest);
			}
		}
		
		private function onRequest(nrm:NetResponseMessageVO):void {
			loading_request = false;
			
			if(nrm.success){
				//we've got some more info, see if we are showing the progress bar, or the entire dialog
				_donation_favor = DonationFavor.updateFromAnonymous(nrm.payload, _donation_favor);
				if(open_favor_dialog){
					ShrineDonateDialog.instance.start();
				}
				else {
					if(!progress_bar){
						progress_bar = new FavorProgressBar(254, 36);
						progress_bar.filters = StaticFilters.copyFilterArrayFromObject(
							{alpha:.4, blurX:8, blurY:8, strength:20}, 
							StaticFilters.black_GlowA
						);
					}
				}
			}
			
			if(after_request_func != null) after_request_func();
		}
		
		public function handleProgressOnShrine(lis_view:LocationItemstackView, is_showing:Boolean, itemstack_count:int = 1):void {
			//this will toss the progress bar on the shrine
			if(!progress_bar){
				//try again real fast
				StageBeacon.waitForNextFrame(handleProgressOnShrine, lis_view, is_showing, itemstack_count);
				return;
			}
			
			//axe it from view
			if(!is_showing){
				hideProgressBar();
			}
			else {
				progress_bar.alpha = 0;
				
				//see if we are done loading yet
				if(loading_request){
					StageBeacon.waitForNextFrame(handleProgressOnShrine, lis_view, is_showing, itemstack_count);
					return;
				}
				
				//make sure the donation favor is up to date with the shrine we are over
				_donation_favor.shrine_tsid = lis_view.itemstack.tsid;
				_donation_favor.giant_tsid = lis_view.item.tsid.substr(lis_view.item.tsid.lastIndexOf('_')+1);
				
				const favor:GiantFavor = TSModelLocator.instance.worldModel.pc.stats.favor_points.getFavorByName(donation_favor.giant_tsid);
				if(favor){
					//place it where it needs to go
					progress_bar.setCurrentAndMax(favor.current, favor.max);
					progress_bar.x = int(lis_view.x - progress_bar.width/2);
					progress_bar.y = int(lis_view.y - lis_view.height - progress_bar.height - 20);
					
					//how much is this stack worth
					progress_bar.setDonationChange(donation_favor.item_favor * itemstack_count);
					
					TSFrontController.instance.getMainView().gameRenderer.placeOverlayInSCH(progress_bar, 'progress bar on top of a shrine');
					TSTweener.removeTweens(progress_bar);
					TSTweener.addTween(progress_bar, {alpha:1, time:.2, transition:'linear'});
				}
			}
		}
		
		public function hideProgressBar():void {
			if(progress_bar && progress_bar.parent){
				TSTweener.removeTweens(progress_bar);
				TSTweener.addTween(progress_bar, 
					{
						alpha:0, 
						time:.2, 
						transition:'linear', 
						onComplete:function():void {
							progress_bar.parent.removeChild(progress_bar);
						}
					}
				);
			}
		}
		
		private function showError(txt:String):void {
			TSModelLocator.instance.activityModel.growl_message = txt;
		}
		
		public function get shrine_tsid():String { return _shrine_tsid; }
		public function get donation_favor():DonationFavor { return _donation_favor; }
	}
}