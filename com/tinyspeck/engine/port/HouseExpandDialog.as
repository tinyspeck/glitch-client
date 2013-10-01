package com.tinyspeck.engine.port
{
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.data.client.ConfirmationDialogVO;
	import com.tinyspeck.engine.data.house.HouseExpand;
	import com.tinyspeck.engine.data.house.HouseExpandCosts;
	import com.tinyspeck.engine.data.house.HouseExpandReq;
	import com.tinyspeck.engine.data.item.Item;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.event.TSEvent;
	import com.tinyspeck.engine.net.NetResponseMessageVO;
	import com.tinyspeck.engine.pack.PackDisplayManager;
	import com.tinyspeck.engine.sound.SoundMaster;
	import com.tinyspeck.engine.util.SpriteUtil;
	import com.tinyspeck.engine.util.StringUtil;
	import com.tinyspeck.engine.util.TFUtil;
	import com.tinyspeck.engine.view.itemstack.ItemIconView;
	import com.tinyspeck.engine.view.ui.Button;
	import com.tinyspeck.engine.view.ui.Dialog;
	import com.tinyspeck.engine.view.ui.TSLinkedTextField;
	import com.tinyspeck.engine.view.ui.decorate.HouseExpandReqUI;
	import com.tinyspeck.engine.view.util.StaticFilters;
	
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;

	public class HouseExpandDialog extends Dialog implements IPackChange
	{
		/* singleton boilerplate */
		public static const instance:HouseExpandDialog = new HouseExpandDialog();
		
		private static const REQ_PADD:int = 80; //L+R padding
		private static const WORK_ICON_WH:uint = 40;
		private static const DOOR_ICON_WH:uint = 42;
		private static const TOP_OFFSET:uint = 100;
		private static const MAX_COLS:uint = 3;
		
		private var title_tf:TextField = new TextField();
		private var count_tf:TSLinkedTextField = new TSLinkedTextField();
		private var work_tf:TextField = new TextField();
		private var work_item_tf:TSLinkedTextField = new TSLinkedTextField();
		private var start_project_tf:TSLinkedTextField = new TSLinkedTextField();
		private var unexpand_tf:TSLinkedTextField = new TSLinkedTextField();
		
		private var req_holder:Sprite = new Sprite();
		private var work_holder:Sprite = new Sprite();
		private var work_icon_holder:Sprite = new Sprite();
		private var start_project_holder:Sprite = new Sprite();
		private var unexpand_holder:Sprite = new Sprite();
		
		private var expand_bt:Button;
		private var ok_bt:Button;
		private var unexpand_no_bt:Button;
		private var unexpand_yes_bt:Button;
		private var expand_reqs:Vector.<HouseExpandReqUI> = new Vector.<HouseExpandReqUI>();
		private var cdVO:ConfirmationDialogVO = new ConfirmationDialogVO();
		
		private var current_type:String;
		
		private var is_built:Boolean;
		
		public function HouseExpandDialog(){
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
			
			_w = 424;
			_h = 260;
			_draggable = true;
			_base_padd = 20;
			_close_bt_padd_top = 7;
			_close_bt_padd_right = 9;
			_construct();
		}
		
		override protected function _place():void {
			//move to the top of the viewport
			last_x = int(model.layoutModel.overall_w/2 - _w/2);
			last_y = TOP_OFFSET;
			
			if (last_y+_h+10 > StageBeacon.stage.stageHeight) {
				last_y = Math.max(10, StageBeacon.stage.stageHeight-(_h+10));
			}
			
			super._place();
		}
		
		private function buildBase():void {
			//tfs
			TFUtil.prepTF(title_tf);
			title_tf.width = _w - 2;
			title_tf.y = 27;
			title_tf.mouseEnabled = false;
			title_tf.htmlText = '<p class="house_expand_title">placeholder</p>';
			addChild(title_tf);
			
			TFUtil.prepTF(count_tf);
			count_tf.width = _w - 2;
			addChild(count_tf);
			
			//bt
			expand_bt = new Button({
				name: 'expand',
				label: 'Use these items to expand your house',
				type: Button.TYPE_MINOR,
				size: Button.SIZE_DEFAULT,
				h: 31
			});
			expand_bt.addEventListener(TSEvent.CHANGED, onExpandClick, false, 0, true);
			expand_bt.x = int(_w/2 - expand_bt.width/2);
			addChild(expand_bt);
			
			ok_bt = new Button({
				name: 'okay',
				label: 'Okay',
				type: Button.TYPE_MINOR,
				size: Button.SIZE_DEFAULT
			});
			ok_bt.x = int(_w - ok_bt.width - _base_padd);
			ok_bt.addEventListener(TSEvent.CHANGED, closeFromUserInput, false, 0, true);
			addChild(ok_bt);
			
			//reqs
			req_holder.y = int(title_tf.y + title_tf.height + 15);
			addChild(req_holder);
			
			//work
			TFUtil.prepTF(work_tf, false);
			work_tf.htmlText = '<p class="house_expand_work">placeholder</p>';
			work_tf.y = int(WORK_ICON_WH/2 - work_tf.height/2);
			work_tf.mouseEnabled = false;
			work_holder.addChild(work_tf);
			
			TFUtil.prepTF(work_item_tf, false);
			work_item_tf.htmlText = '<p class="house_expand_work">placeholder</p>';
			work_item_tf.y = int(WORK_ICON_WH/2 - work_item_tf.height/2);
			work_holder.addChild(work_item_tf);
			
			work_icon_holder.useHandCursor = work_icon_holder.buttonMode = true;
			work_icon_holder.mouseChildren = false;
			work_icon_holder.addEventListener(MouseEvent.CLICK, onWorkIconClick, false, 0, true);
			work_holder.addChild(work_icon_holder);
			addChild(work_holder);
			
			//start project
			var g:Graphics = start_project_holder.graphics;
			g.beginFill(0xe8efef);
			g.drawRoundRect(0, 0, 370, 67, 10);
			start_project_holder.x = int(_w/2 - start_project_holder.width/2);
			start_project_holder.mouseEnabled = false;
			addChild(start_project_holder);
				
			door_iiv.x = door_padd;
			door_iiv.y = int(start_project_holder.height/2 - door_iiv.height/2);
			door_iiv.mouseEnabled = false;
			start_project_holder.addChild(door_iiv);
			
			TFUtil.prepTF(start_project_tf);
			start_project_tf.width = start_project_holder.width - (door_iiv.x + door_iiv.width) - door_padd*2;
			// start_project_tf.x will get changed in update()
			start_project_tf.x = int(door_iiv.x + door_iiv.width - door_padd);
			start_project_tf.filters = StaticFilters.white1px90Degrees_DropShadowA;
			start_project_holder.addChild(start_project_tf);
			
			//unexpand
			const bt_w:uint = 116;
			TFUtil.prepTF(unexpand_tf);
			unexpand_tf.width = _w - _base_padd*2;
			unexpand_tf.x = _base_padd;
			unexpand_holder.addChild(unexpand_tf);
			
			unexpand_no_bt = new Button({
				name: 'unexpand_no',
				label: 'No, nevermind',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR,
				w: bt_w
			});
			unexpand_no_bt.x = int(_w/2 - bt_w - 5);
			unexpand_no_bt.addEventListener(TSEvent.CHANGED, onNoClick, false, 0, true);
			unexpand_holder.addChild(unexpand_no_bt);
			
			unexpand_yes_bt = new Button({
				name: 'unexpand_yes',
				label: 'Un-expand it',
				size: Button.SIZE_DEFAULT,
				type: Button.TYPE_MINOR,
				w: bt_w
			});
			unexpand_yes_bt.x = int(_w/2 + 5);
			unexpand_yes_bt.addEventListener(TSEvent.CHANGED, onUnexpandClick, false, 0, true);
			unexpand_holder.addChild(unexpand_yes_bt);
			
			unexpand_holder.y = int(title_tf.y + title_tf.height + 8);
			addChild(unexpand_holder);
			
			cdVO.escape_value = false;
			cdVO.title = 'Un-expand your house?';
			cdVO.txt = 'Are you sure you want to un-expand? Your stuff will automatically move over, don\'t worry.';
			cdVO.callback = onUnexpandConfirm;
			cdVO.choices = [
				{value: false, label: 'Nevermind'},
				{value: true, label: 'Yes. Un-expand it!'}
			];
			
			is_built = true;
		}
		
		public function prime():void {
			door_iiv;// makes sure we load this asset
		}
		
		private var _door_iiv:ItemIconView;
		private function get door_iiv():ItemIconView {
			if (!_door_iiv) _door_iiv = new ItemIconView('furniture_door', DOOR_ICON_WH);
			return _door_iiv;
		}
		
		private const door_padd:int = 3;
		
		public function startWithType(type:String):void {
			if(!canStart(true)) return;
			if(!is_built) buildBase();
			current_type = type;
			
			//reset
			ok_bt.visible = false;
			expand_bt.visible = false;
			expand_bt.show_spinner = false;
			SpriteUtil.clean(req_holder);
			count_tf.text = '';
			work_holder.visible = false;
			start_project_holder.visible = false;
			unexpand_holder.visible = false;
			
			//re-enable the buttons
			unexpand_no_bt.disabled = false;
			unexpand_yes_bt.disabled = false;
			unexpand_no_bt.show_spinner = false;
			unexpand_yes_bt.show_spinner = false;
			
			//set the title
			var title_txt:String = 'The next expansion will cost:';
			if(type == HouseExpandCosts.TYPE_FLOOR){
				title_txt = 'To add another floor, you’ll need:';
			}
			else if(type == HouseExpandCosts.TYPE_UNEXPAND){
				title_txt = 'Un-expand your house';
			}
			
			title_tf.htmlText = '<p class="house_expand_title">'+title_txt+'</p>';
			
			super.start();
			
			//listen to the pack
			PackDisplayManager.instance.registerChangeSubscriber(this);
			
			//go get the costs
			HouseManager.instance.requestExpandCostsFromServer();
		}
		
		override public function end(release:Boolean):void {
			super.end(release);
			
			//stop listening
			PackDisplayManager.instance.unRegisterChangeSubscriber(this);
		}
		
		private function isHome():Boolean {
			const pc:PC = model.worldModel.pc;
			if (pc.home_info.interior_tsid == model.worldModel.location.tsid) {
				return true;
			}
			return false;
		}
		
		public function update():void {
			if(!parent) return;
			
			//this is called when the server sends over new stuff
			const house_expand:HouseExpand = HouseManager.instance.house_expand;
			if(house_expand){
				//check real quick to see if we are maxed out
				const cost:HouseExpandCosts = house_expand.getCostsByType(current_type);
				const maxed_out:Boolean = cost && cost.count > 0 ? false : true;
				const tower_job_started:Boolean = !isHome() && cost && cost.locked ? true : false;
				
				//set the count text
				setCountText(house_expand);
				
				if(!maxed_out && !tower_job_started){
					const padd:int = 15;
					
					//set the reqs
					setReqs(house_expand);
					
					//set the proper height
					_h = req_holder.y + req_holder.height + count_tf.height + padd*2;
					
					if(current_type == HouseExpandCosts.TYPE_WALL) {
						_h += expand_bt.height + padd;
						expand_bt.visible = true;
					}
					else if(current_type == HouseExpandCosts.TYPE_FLOOR){
						_h += work_holder.height + padd;
						_h += start_project_holder.height + padd;
						start_project_holder.visible = true;
						
						const pc:PC = model.worldModel.pc;
						var start_txt:String;
						if (isHome()) {
							door_iiv.visible = true;
							start_project_tf.x = int(door_iiv.x + door_iiv.width - door_padd);
							//see if they have enough doors
							const has_how_many:int = pc.hasHowManyItems('furniture_door');
							start_txt = '<p class="house_expand_start">';
							start_txt += 'To start the project, drag a <a href="event:'+TSLinkedTextField.LINK_ITEM+'|furniture_door">door</a> onto a wall';
							if(!has_how_many) start_txt += '<br><span class="house_expand_start_missing">(You\'ll need to find yourself a door first)<span>';
							start_txt += '</p>';
						} else {
							start_txt = '<p class="house_expand_start">';
							door_iiv.visible = false;
							start_project_tf.x = int(door_iiv.x+((door_iiv.width - door_padd)/2));
							//if (cost.locked) {
							//	start_txt += 'Head to the top floor of your tower to work on the expansion job!';
							//} else {
								start_txt += '<a href="event:'+TSLinkedTextField.LINK_ADD_TOWER_FLOOR+'">Click here to get going!</a>';
							//}
							start_txt += '</p>';
						}
						
						
						start_project_tf.htmlText = start_txt;
						start_project_tf.y = int(start_project_holder.height/2 - start_project_tf.height/2);
					}
					else if(current_type == HouseExpandCosts.TYPE_UNEXPAND){
						unexpand_holder.visible = true;
						var unexpand_txt:String = '<p class="house_expand_unexpand">';
						unexpand_txt += 'Un-expanding will remove one expansion from the right side of your house, making your house narrower by one wall segment.';
						unexpand_txt += '<br><br>You’ll be refunded the following materials:<br>';
						
						//this adds a liiitle bit of padding cause the css hated me
						unexpand_txt += '<font size="4">&nbsp;<br></font>';
						
						//build out the list of stuff you get back
						unexpand_txt += '<span class="house_expand_unexpand_mats">';
						const total:uint = cost.items.length;
						var i:int;
						var req:HouseExpandReq;
						var label:String;
						var item:Item;
						
						for(i; i < total; i++){
							req = cost.items[int(i)];
							item = model.worldModel.getItemByTsid(req.class_tsid);
							label = '<b>'+req.count+'&nbsp;<a href="event:'+TSLinkedTextField.LINK_ITEM+'|'+req.class_tsid+'">'+
								   (req.count != 1 ? item.label_plural : item.label)+
								   '</a></b>';
							if(i == total-2){
								label += ' and&nbsp;';
							}
							else if(i < total-1){
								label += '<b>,</b> ';
							}
							unexpand_txt += label;
						}
						unexpand_txt += '</span>';
						unexpand_txt += '</p>';
						
						unexpand_tf.htmlText = unexpand_txt;
						
						//place the buttons
						unexpand_no_bt.y = int(unexpand_tf.height + 17);
						unexpand_yes_bt.y = unexpand_no_bt.y;
						
						//make sure we can do this
						unexpand_yes_bt.disabled = cost.locked;
						unexpand_yes_bt.tip = !cost.locked ? null : {txt:'You need to finish up your floor project first!', pointer:WindowBorder.POINTER_BOTTOM_CENTER};
						
						_h += unexpand_holder.height;
					}
				}
				else {
					var title_txt:String;
					
					if (tower_job_started) {
						title_txt = 'Your tower is under construction';
						
						//shrink this bad boy
						_h = 160;
					} else {
						//set the title
						const what:String = isHome() ? 'house' : 'tower';
						
						title_txt = 'Your '+what+' is already sooo wide!';
						if(current_type == HouseExpandCosts.TYPE_FLOOR){
							title_txt = 'Your '+what+' is already sooo tall!';
						}
						else if(current_type == HouseExpandCosts.TYPE_UNEXPAND){
							title_txt = 'Your '+what+' is already sooo small!';
						}
						
						//shrink this bad boy
						_h = 150;
					}
					
					
					title_tf.htmlText = '<p class="house_expand_title">'+title_txt+'</p>';
				}
				
				invalidate(true);
				
				//move things around
				count_tf.y = !maxed_out && !tower_job_started ? int(_h - count_tf.height - padd) : int(title_tf.y + title_tf.height);
				expand_bt.y = int(count_tf.y - expand_bt.height - padd);
				work_holder.y = int(req_holder.y + req_holder.height + padd);
				start_project_holder.y = int(work_holder.y + work_holder.height + padd);
				
				//ok button
				ok_bt.visible = maxed_out || tower_job_started;
				ok_bt.y = int(_h - ok_bt.height - _base_padd);
			}
		}
		
		override public function start():void {
			BootError.addErrorMsg('Gotta use startWithType()!!');
		}
		
		private function setCountText(house_expand:HouseExpand):void {
			if(!house_expand) return;
			count_tf.multiline = false;
			var cost:HouseExpandCosts;
			var count_txt:String = '<p class="house_expand_count">';
			if(current_type == HouseExpandCosts.TYPE_WALL){
				cost = house_expand.getCostsByType(HouseExpandCosts.TYPE_WALL);
				if(cost && cost.count){
					count_txt += 'This building can be expanded <b>'+cost.count+'</b> more '+(cost.count != 1 ? 'times' : 'time')+'.';
				}
				else {
					count_txt += '<span class="house_expand_count_low">This building can’t be expanded anymore.</span>';
				}
				
				//check if we can un-expand
				cost = house_expand.getCostsByType(HouseExpandCosts.TYPE_UNEXPAND);
				if(cost && cost.count){
					count_tf.multiline = true;
					count_txt += '<br><br>You can also un-expand your house.';
				}
			}
			else if(current_type == HouseExpandCosts.TYPE_FLOOR){
				cost = house_expand.getCostsByType(HouseExpandCosts.TYPE_FLOOR);
				const tower_job_started:Boolean = !isHome() && cost && cost.locked ? true : false;
				if (isHome() || !tower_job_started) {
					if(cost && cost.count){
						count_txt += 'This building can have <b>'+cost.count+'</b> more '+(cost.count != 1 ? 'floors' : 'floor')+' added.';
					}
					else {
						count_txt += '<span class="house_expand_count_low">This building can’t have any more floors added.</span>';
					}					
				} else {
					count_tf.multiline = true;
					count_txt = '<p class="house_expand_tower_in_progress">';
					count_txt += 'Head to the top floor of your tower to work on<br>the expansion that\'s already in progress.';
					count_txt += '</p>';
				}
			}
			else if(current_type == HouseExpandCosts.TYPE_UNEXPAND){
				cost = house_expand.getCostsByType(HouseExpandCosts.TYPE_UNEXPAND);
				if(cost && cost.count){
					count_tf.multiline = true;
					count_txt += 'This building can be un-expanded <b>'+cost.count+'</b>'+(cost.count != 1 ? ' more times.' : ' more time.');
					count_txt += '<br>When you un-expand, furniture and items will be automatically moved over.';
				}
				else {
					count_txt += '<span class="house_expand_count_low">This building can’t be un-expanded.</span>';
				}
			}
			
			count_txt += '</p>';
			count_tf.htmlText = count_txt;
		}
		
		private function setReqs(house_expand:HouseExpand):void {
			if(!house_expand) return;
			SpriteUtil.clean(req_holder);
			var cost:HouseExpandCosts;
			
			if(current_type == HouseExpandCosts.TYPE_WALL){
				cost = house_expand.getCostsByType(HouseExpandCosts.TYPE_WALL);
			}
			else if(current_type == HouseExpandCosts.TYPE_FLOOR){
				cost = house_expand.getCostsByType(HouseExpandCosts.TYPE_FLOOR);
			}
			else if(current_type == HouseExpandCosts.TYPE_UNEXPAND){
				//nuffin' to do
				return;
			}
			
			if(cost){
				//build out the item UI
				const reqs:Vector.<HouseExpandReq> = cost.items;
				const padd:uint = 20;
				const cols:uint = Math.min(reqs.length, MAX_COLS);
				const gap:uint = _w / (cols+1) + padd/2;
				var i:int;
				var total:int = reqs.length;
				var next_x:int;
				var next_y:int;
				var element_w:int;
				var expand_req:HouseExpandReqUI;
				var can_expand:Boolean = true;
				
				//since we've emptied the sprite, no need to clear the pool
				for(i = 0; i < total; i++){
					if(i > expand_reqs.length){
						expand_req = expand_reqs[i];
					}
					else {
						expand_req = new HouseExpandReqUI();
						expand_reqs.push(expand_req);
					}
					
					expand_req.show(reqs[int(i)], current_type);
					if(i > 0 && i % cols == 0){
						//new row
						next_x = 0;
						next_y += expand_req.height + padd;
					}
					
					expand_req.x = int(next_x - expand_req.width/2);
					expand_req.y = next_y;
					next_x += gap;
					req_holder.addChild(expand_req);
					
					//can they still expand?
					if(can_expand){
						can_expand = expand_req.has_material;
					}
				}
				
				//center it
				req_holder.x = gap - padd;
				
				//is there work?
				total = cost.work.length;
				work_holder.visible = total > 0;
				
				if(total){
					//there should only be one thing in here for now, if not the UI will need to be tweaked
					const req:HouseExpandReq = cost.work[0];
					const item:Item = model.worldModel.getItemByTsid(req.class_tsid);
					var work_txt:String = '<p class="house_expand_work">';
					work_txt += 'and '+req.count+' work '+(req.count != 1 ? 'units' : 'unit')+' with '+StringUtil.aOrAn(item.label);
					work_txt += '</p>';
					
					work_tf.htmlText = work_txt;
					
					//icon
					SpriteUtil.clean(work_icon_holder);
					const iiv:ItemIconView = new ItemIconView(item.tsid, WORK_ICON_WH);
					work_icon_holder.addChild(iiv);
					work_icon_holder.x = int(work_tf.width + 6);
					work_icon_holder.name = item.tsid; //used for click handling
					
					//item link
					work_item_tf.htmlText = '<p class="house_expand_work"><a href="event:'+TSLinkedTextField.LINK_ITEM+'|'+item.tsid+'">'+item.label+'</a></p>';
					work_item_tf.x = work_icon_holder.x + WORK_ICON_WH + 3;
					
					//center it up
					work_holder.x = int(_w/2 - work_holder.width/2);
				}
				
				//set the button
				var expand_tip:Object = {pointer:WindowBorder.POINTER_BOTTOM_CENTER};
				if(!can_expand){
					expand_tip.txt = 'You need the materials first!';
				}
				else if(cost.locked){
					expand_tip.txt = 'You need to finish up your floor project first!';
				}
				
				expand_bt.disabled = !can_expand || cost.locked;
				expand_bt.tip = !expand_bt.disabled ? null : expand_tip;
				expand_bt.show_spinner = false;
			}
			else {
				CONFIG::debugging {
					Console.warn('Trying to setReqs and got a funky type (or type was null): '+current_type);
				}
			}
		}
		
		private function onExpandClick(event:TSEvent):void {
			SoundMaster.instance.playSound(!expand_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(expand_bt.disabled) return;
			
			//tell the server we wanna expand!
			expand_bt.disabled = true;
			expand_bt.show_spinner = true;
			HouseManager.instance.sendWallExpand();
		}
		
		private function onWorkIconClick(event:MouseEvent):void {
			//open up the info dialog
			TSFrontController.instance.showSkillInfo(work_icon_holder.name);
		}
		
		private function onUnexpandClick(event:TSEvent):void {
			SoundMaster.instance.playSound(!unexpand_yes_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(unexpand_yes_bt.disabled) return;
			
			//confirm that the player wants to do this
			TSFrontController.instance.confirm(cdVO);
			unexpand_no_bt.disabled = true;
			unexpand_yes_bt.disabled = true;
		}
		
		private function onNoClick(event:TSEvent):void {
			//we just want to close this
			SoundMaster.instance.playSound(!unexpand_no_bt.disabled ? 'CLICK_SUCCESS' : 'CLICK_FAILURE');
			if(unexpand_no_bt.disabled) return;
			
			end(true);
		}
		
		private function onUnexpandConfirm(value:Boolean):void {
			//do it
			if(value){
				HouseManager.instance.sendWallUnexpand();
				unexpand_no_bt.show_spinner = true;
				unexpand_yes_bt.show_spinner = true;
			}
			else {
				//re-enable the buttons
				unexpand_no_bt.disabled = false;
				unexpand_yes_bt.disabled = false;
				unexpand_no_bt.show_spinner = false;
				unexpand_yes_bt.show_spinner = false;
			}
		}
		
		public function onPackChange():void {
			//update things
			update();
		}
	}
}