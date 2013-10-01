package com.tinyspeck.debug {
	import com.tinyspeck.engine.control.TSFrontController;
	import com.tinyspeck.engine.control.engine.AnnouncementController;
	import com.tinyspeck.engine.data.client.Announcement;
	import com.tinyspeck.engine.data.pc.PC;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.net.MessageTypes;
	import com.tinyspeck.engine.util.MathUtil;
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	public class FakeFriends {
		/* singleton boilerplate */
		public static const instance:FakeFriends = new FakeFriends();
		
		private var model:TSModelLocator;
		private var limit:int; // set in insertFakesIntoLocation(); 56 is all we have right now in getFakeData
		private var base_offset:int; // how far away from each other should the fakes be, calced in insertFakesIntoLocation
		private var inited:Boolean;
		private var running:Boolean;
		private var timer:Timer;
		
		public function FakeFriends() {
			CONFIG::god {
				if(instance) throw new Error('Singleton');
			}
		}
		
		private function init():void {
			model = TSModelLocator.instance;
			fakePCsV = new Vector.<PC>();
			cleanAndAddFakes();
			timer = new Timer(100);
			timer.addEventListener(TimerEvent.TIMER, onTimer);
			inited = true;
		}
		
		private function onTimer(e:TimerEvent):void {
			if (!inited || !running || !fakePCsV || !fakePCsV.length || !limit) {
				cancel();
				return;
			}
			
			CONFIG::debugging {
				Console.trackPhysicsValue(' FF onGameLoop', 'go '+limit)
			}
			
			var you:PC = model.worldModel.pc;
			var offset:int = (you.s.indexOf('-') == 0) ? -base_offset : base_offset;
			var sent:int = 0;
			var pc:PC;
			var new_x:int;
			var new_y:int;
			var new_s:String;
			
			for (var i:int;i<limit;i++) {
				pc = fakePCsV[i];
				new_x = you.x-((i+1)*offset);
				new_x = MathUtil.clamp(model.worldModel.location.l, model.worldModel.location.r, new_x);
				new_y = you.y;
				new_s = you.s;
				
				if (pc.x != new_x || pc.y != new_y || pc.s != new_s) {
					sent++;
					TSFrontController.instance.simulateIncomingMsg({
						type: MessageTypes.PC_MOVE_XY,
						pc: {
							tsid: pc.tsid,
							x: new_x,
							y: new_y,
							s: new_s
						}
					});
				}
			}
			
			CONFIG::debugging {
				Console.trackPhysicsValue(' FF onGameLoop sent', 'onGameLoop sent '+sent)
			}
		}
		
		private function resetTrackers():void {
			CONFIG::debugging {
				Console.trackPhysicsValue(' FF onGameLoop', 'no');
				Console.trackPhysicsValue(' FF onGameLoop sent', '0');
			}
		}
		
		// called from TSMainView.moveMoveStarted
		public function onMoveStarted():void {
			cancel();
		}
		
		public function cancel():void {
			resetTrackers();
			if (!inited) return;
			
			if (!running) {
				CONFIG::debugging {
					annc('FakeFriends not running');
				}
				return;
			}
			
			CONFIG::debugging {
				annc('FakeFriends cancelled');
			}
			
			var pc:PC;
			for (var i:int;i<limit;i++) {
				pc = fakePCsV[i];
				TSFrontController.instance.simulateIncomingMsg({
					type: MessageTypes.PC_LOGOUT,
					pc: {
						tsid: pc.tsid
					}
				})
			}
			
			timer.stop();
			running = false;
		}
		
		// currently just called from slash command /fake_friends
		public function insertFakesIntoLocation(how_many:int):void {
			if (!inited) {
				init();
			}
			
			if (running) {
				cancel();
			}
			
			if (model.moveModel.moving) {
				CONFIG::debugging {
					Console.error('can\'t insertFakesIntoLocation when moving');
				}
				return;
			}
			
			// how many shall we add?
			limit = Math.min(how_many, fakePCsV.length);
			
			// make sure they are no closer than 15, and no farther than 40, but try to space them out nicely
			// (def no farther from fron to back of train that 1000)
			base_offset = MathUtil.clamp(15, 40, 1000/limit);
			
			var you:PC = model.worldModel.pc;
			var pc:PC;
			var A:Array = [];
			for (var i:int;i<limit;i++) {
				pc = fakePCsV[i];
				pc.x = you.x;
				pc.y = you.y;
				pc.s = you.s;
				pc.location = you.location;
				pc.fake = true;
				model.worldModel.location.pc_tsid_list[pc.tsid] = pc.tsid;
				A.push(pc.tsid);
			}
			
			var requested:String = (how_many == int.MAX_VALUE) ? 'all' : how_many.toString();
			CONFIG::debugging {
				annc('FakeFriends added '+A.length+' fake friends<br>('+requested+' requested)');
			}
			
			model.worldModel.loc_pc_adds = A;
			running = true;
			timer.start();
		}
		
		private function annc(str:String):void {
			AnnouncementController.instance.cancelOverlay('fake_friends_annc');
			model.activityModel.announcements = Announcement.parseMultiple([{
				type: "vp_overlay",
				dismissible: false,
				locking: false,
				click_to_advance: false,
				text: ['<p align="center"><span class="nuxp_big">' + str + '</span></p>'],
				x: '50%',
				y: '50%',
				duration: 1500,
				width: Math.max(model.layoutModel.min_vp_w-100, model.layoutModel.loc_vp_w-200),
				uid: 'fake_friends_annc',
				bubble_god: true,
				allow_in_locodeco: true
			}]);
		}
		
		private function cleanAndAddFakes():void {
			// the data we have in fake_data needs some massaging.
			var fake_data:Object = getFakeData();
			var c:int;
			for each (var fake:Object in fake_data) {
				fake.tsid = 'FAKEFRIEND_'+c;
				fake.label = fake.tsid;
				fake.online = true;
				fake.s = '25';
				fakePCsV[c] = model.worldModel.pcs[fake.tsid] = PC.fromAnonymous(fake, fake.tsid);
				c++;
			}
		}
		
		private var fakePCsV:Vector.<PC>;
		
		private function getFakeData():Object {
			return {
				"PHH14KBC1MR1QFV":{
					"is_guide":false,
					"tsid":"PHH14KBC1MR1QFV",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-07-13/d34e6c99188db6f728f26d13edfa325b_1310596751",
					"label":"stress7",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-07-13/d34e6c99188db6f728f26d13edfa325b_1310602065"
				},
				"PHH15USG1MR1PF5":{
					"is_guide":false,
					"tsid":"PHH15USG1MR1PF5",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/73de2ee136166102e524356bcc24b612_1301008918",
					"label":"stress10",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/73de2ee136166102e524356bcc24b612_1301008912"
				},
				"PM413S8EFAELM":{
					"is_guide":false,
					"tsid":"PM413S8EFAELM",
					"level":15,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-11-09/f547b32c70a6de3c1711e119bc0411a0_1320886179",
					"label":"Stoot",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-11-09/f547b32c70a6de3c1711e119bc0411a0_1320886523"
				},
				"PHH1AKUO34S1BFN":{
					"is_guide":false,
					"tsid":"PHH1AKUO34S1BFN",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/57c369af0f31fec025fb72ad7286c5dd_1301009067",
					"label":"stress29",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/57c369af0f31fec025fb72ad7286c5dd_1301009061"
				},
				"PHH13VA91MR1C22":{
					"is_guide":false,
					"tsid":"PHH13VA91MR1C22",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/f271629333f2aa17a13e6d96981d74b1_1301008890",
					"label":"stress6",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/f271629333f2aa17a13e6d96981d74b1_1301008885"
				},
				"PHH19A1VO3S13LM":{
					"is_guide":false,
					"tsid":"PHH19A1VO3S13LM",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/05c0749ecc2cf2997753ddb03d468bc5_1301009035",
					"label":"stress18",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/05c0749ecc2cf2997753ddb03d468bc5_1301009028"
				},
				"PHH13DEJI3S1S1U":{
					"is_guide":false,
					"tsid":"PHH13DEJI3S1S1U",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/cbca6fa7f9a4e5df6da3357c15eb65e8_1301008971",
					"label":"stress19",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/cbca6fa7f9a4e5df6da3357c15eb65e8_1301008964"
				},
				"PM4101M9F7MGO":{
					"is_guide":false,
					"tsid":"PM4101M9F7MGO",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/2765262852ce6775fa7a497259aecb39_1301008633",
					"label":"Wintermute",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/2765262852ce6775fa7a497259aecb39_1301008629"
				},
				"PMF1TGU3GFD2LPT":{
					"is_guide":false,
					"tsid":"PMF1TGU3GFD2LPT",
					"level":3,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-06-23/d984f471d344604b8bd0dfe661ddb26d_1308867786",
					"label":"jort",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/d984f471d344604b8bd0dfe661ddb26d_1301009116"
				},
				"PM41ESAT9E70N":{
					"is_guide":false,
					"tsid":"PM41ESAT9E70N",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/cd9e0d722e17789dd3e122c3b807f5e1_1301008696",
					"label":"Mony Mony",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/cd9e0d722e17789dd3e122c3b807f5e1_1301008689"
				},
				"PM41BGI7QSUBV":{
					"is_guide":false,
					"tsid":"PM41BGI7QSUBV",
					"level":8,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/2765262852ce6775fa7a497259aecb39_1301008633",
					"label":"UnitZeroOne",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/2765262852ce6775fa7a497259aecb39_1301008629"
				},
				"PHH14NRLJ3S10PH":{
					"is_guide":false,
					"tsid":"PHH14NRLJ3S10PH",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/17639fd6a9feae40f9244207c7b214ee_1301008977",
					"label":"stress25",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/17639fd6a9feae40f9244207c7b214ee_1301008970"
				},
				"PHH117KF2JL1SUV":{
					"is_guide":false,
					"tsid":"PHH117KF2JL1SUV",
					"level":10,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-07-13/4f69b06ccadd61ad2bb990fcb80d6c74_1310596676",
					"label":"kevbob",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-07-13/4f69b06ccadd61ad2bb990fcb80d6c74_1310601600"
				},
				"PM410H7CFPPVQ":{
					"is_guide":false,
					"tsid":"PM410H7CFPPVQ",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/2765262852ce6775fa7a497259aecb39_1301008633",
					"label":"neb",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/2765262852ce6775fa7a497259aecb39_1301008629"
				},
				"PHH101B5SBP1GBG":{
					"is_guide":false,
					"tsid":"PHH101B5SBP1GBG",
					"level":5,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-11-10/750013e88eb370df8ca55879487a7c3d_1320962766",
					"label":"rayn",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-11-10/750013e88eb370df8ca55879487a7c3d_1320962898"
				},
				"PHH16M2OM3S1F5S":{
					"is_guide":false,
					"tsid":"PHH16M2OM3S1F5S",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-07-13/45f8e781b0fd23a4f6cd90ea4d3fb9a4_1310596703",
					"label":"stress20",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-07-13/45f8e781b0fd23a4f6cd90ea4d3fb9a4_1310597362"
				},
				"PM41ABHS3S8QO":{
					"is_guide":false,
					"tsid":"PM41ABHS3S8QO",
					"level":9,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2012-02-17/a51a91ed249df1b2dbc49e9889f353a7_1329551246",
					"label":"kukubee",
					"sheet_url":"http://c2.glitch.bz/avatars/2012-02-17/a51a91ed249df1b2dbc49e9889f353a7_1329551550"
				},
				"PM4158A47Q9H1":{
					"is_guide":false,
					"tsid":"PM4158A47Q9H1",
					"level":3,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/0beeae3603e86d867626975fb64a0c6c_1301008690",
					"label":"Brett Favre",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/0beeae3603e86d867626975fb64a0c6c_1301008684"
				},
				"PHH136T67M61MKK":{
					"is_guide":false,
					"tsid":"PHH136T67M61MKK",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-07-13/becbff0564f95f8d3f70ff2e0a8b7885_1310596630",
					"label":"test for serguei",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-07-13/becbff0564f95f8d3f70ff2e0a8b7885_1310597091"
				},
				"PHH19V59P3S1M0E":{
					"is_guide":false,
					"tsid":"PHH19V59P3S1M0E",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/809ff9df056b5b46049b6c0a87d50374_1301009672",
					"label":"stress26",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/809ff9df056b5b46049b6c0a87d50374_1301009663"
				},
				"PHH12LS31MR1TFT":{
					"is_guide":false,
					"tsid":"PHH12LS31MR1TFT",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-07-13/5da4cf057075dca78e35bf1a731c2470_1310596637",
					"label":"stress5",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-07-13/5da4cf057075dca78e35bf1a731c2470_1310605327"
				},
				"PHH10B0VNN51QCD":{
					"is_guide":false,
					"tsid":"PHH10B0VNN51QCD",
					"level":7,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2012-01-11/d4f56e889636dc6cb74ca43047bb993f_1326295787",
					"label":"Scott <-",
					"sheet_url":"http://c2.glitch.bz/avatars/2012-01-11/d4f56e889636dc6cb74ca43047bb993f_1326295917"
				},
				"PM411SNGHN46D":{
					"is_guide":false,
					"tsid":"PM411SNGHN46D",
					"level":3,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/089b6908c18aa5221b140d33557c4d4e_1301008724",
					"label":"Orlando Furioso",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/089b6908c18aa5221b140d33557c4d4e_1301008716"
				},
				"PM415OG5993HQ":{
					"is_guide":false,
					"tsid":"PM415OG5993HQ",
					"level":5,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/2765262852ce6775fa7a497259aecb39_1301008633",
					"label":"Daniel Burka",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/2765262852ce6775fa7a497259aecb39_1301008629"
				},
				"PHH194UROAC1CHA":{
					"is_guide":false,
					"tsid":"PHH194UROAC1CHA",
					"level":6,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-11-02/63d627a46b688e42e6ec50dfbae37d7c_1320235615",
					"label":"flashpirate",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-11-02/63d627a46b688e42e6ec50dfbae37d7c_1320235754"
				},
				"PMF1IQ5TJCD21AG":{
					"is_guide":false,
					"tsid":"PMF1IQ5TJCD21AG",
					"level":36,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2012-01-16/be327c8d9378f33c15fb90cf16874129_1326762707",
					"label":"Tim",
					"sheet_url":"http://c2.glitch.bz/avatars/2012-01-16/be327c8d9378f33c15fb90cf16874129_1326762854"
				},
				"PM41015AOQGBJ":{
					"is_guide":false,
					"tsid":"PM41015AOQGBJ",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/2765262852ce6775fa7a497259aecb39_1301008631",
					"label":"corey",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/2765262852ce6775fa7a497259aecb39_1301008626"
				},
				"P006":{
					"is_guide":false,
					"tsid":"P006",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/2765262852ce6775fa7a497259aecb39_1301008633",
					"label":"Metacarufasot",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/2765262852ce6775fa7a497259aecb39_1301008629"
				},
				"PHH1BU7854S1CCH":{
					"is_guide":false,
					"tsid":"PHH1BU7854S1CCH",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/64750e5f0211574858eef725cbaac617_1301009073",
					"label":"stress27",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/64750e5f0211574858eef725cbaac617_1301009066"
				},
				"PHH11BCU0MR1L57":{
					"is_guide":false,
					"tsid":"PHH11BCU0MR1L57",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/34f4e34b0d40910116c7aa4cce0ade1b_1301008856",
					"label":"stress4",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/34f4e34b0d40910116c7aa4cce0ade1b_1301008846"
				},
				"PM412BJHEOAJT":{
					"is_guide":false,
					"tsid":"PM412BJHEOAJT",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/40fc9195a7b70d45d3e1d652b85e9b58_1301009346",
					"label":"meomi",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/40fc9195a7b70d45d3e1d652b85e9b58_1301009336"
				},
				"PHH180PQN3S1V81":{
					"is_guide":false,
					"tsid":"PHH180PQN3S1V81",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-07-13/a27b3b44c7f717b767ad1a5a729324b0_1310596691",
					"label":"stress21",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-07-13/a27b3b44c7f717b767ad1a5a729324b0_1310603927"
				},
				"PM414GRG539VD":{
					"is_guide":false,
					"tsid":"PM414GRG539VD",
					"level":28,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-12-21/17913df01dfa822ff8da20b047c1ece1_1324504050",
					"label":"Yodeller of Hechey",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-12-21/17913df01dfa822ff8da20b047c1ece1_1324504279"
				},
				"PM41015CDB1BB":{
					"is_guide":false,
					"tsid":"PM41015CDB1BB",
					"level":5,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/add0a8c9a082e24e881f219dc2b5e7b6_1301008662",
					"label":"RIcky",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/add0a8c9a082e24e881f219dc2b5e7b6_1301008653"
				},
				"PHH101PJ0MR1KCQ":{
					"is_guide":false,
					"tsid":"PHH101PJ0MR1KCQ",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/9eb84c91bba30db42c5024ab90913492_1301009461",
					"label":"stress3",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/9eb84c91bba30db42c5024ab90913492_1301009455"
				},
				"PHH2KEPP8U226FM":{
					"is_guide":false,
					"tsid":"PHH2KEPP8U226FM",
					"level":21,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-11-18/5c3b2a6308a821c09d902e50d6e8cbe9_1321677120",
					"label":"Jade",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-11-18/5c3b2a6308a821c09d902e50d6e8cbe9_1321677267"
				},
				"PM4141A46G40Q":{
					"is_guide":false,
					"tsid":"PM4141A46G40Q",
					"level":2,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/a61295474d7d45246592bdcd89b72e17_1301008667",
					"label":"Joly Moly",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/a61295474d7d45246592bdcd89b72e17_1301008659"
				},
				"PHH159AF1MR1B39":{
					"is_guide":false,
					"tsid":"PHH159AF1MR1B39",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-07-13/ddfb5db332ef965ccda50af9714fb162_1310596772",
					"label":"stress9",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-07-13/ddfb5db332ef965ccda50af9714fb162_1310599246"
				},
				"PM410SK8NCU7H":{
					"is_guide":false,
					"tsid":"PM410SK8NCU7H",
					"level":8,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-07-19/bd18fd811b400fe80ef371d94c9bdb84_1311113027",
					"label":"laloyd",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-07-19/bd18fd811b400fe80ef371d94c9bdb84_1311113112"
				},
				"PHH10MMP0MR1OR5":{
					"is_guide":false,
					"tsid":"PHH10MMP0MR1OR5",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-07-13/985f017854d6e9861283130cea39689c_1310596609",
					"label":"stress2",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-07-13/985f017854d6e9861283130cea39689c_1310604305"
				},
				"PHH17BS7N3S133V":{
					"is_guide":false,
					"tsid":"PHH17BS7N3S133V",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-07-13/e231a04f071dc0992123ac0317142ab9_1310596736",
					"label":"stress22",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-07-13/e231a04f071dc0992123ac0317142ab9_1310597844"
				},
				"PHH142D9J3S1H53":{
					"is_guide":false,
					"tsid":"PHH142D9J3S1H53",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-07-13/7cd1f2f50ec395dac26231bee526669f_1310596650",
					"label":"stress23",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-07-13/7cd1f2f50ec395dac26231bee526669f_1310599583"
				},
				"PHH1B9RC44S1J0U":{
					"is_guide":false,
					"tsid":"PHH1B9RC44S1J0U",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-07-13/147295a23d5a3c38ae70247d5ae6c2b4_1310596543",
					"label":"stress28",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-07-13/147295a23d5a3c38ae70247d5ae6c2b4_1310597668"
				},
				"PHH1CJNL54S15KB":{
					"is_guide":false,
					"tsid":"PHH1CJNL54S15KB",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-07-13/7b6cf949982f405fee24f3c74cfd7400_1310596584",
					"label":"stress30",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-07-13/7b6cf949982f405fee24f3c74cfd7400_1310604913"
				},
				"PHH15CDEL3S1NGN":{
					"is_guide":false,
					"tsid":"PHH15CDEL3S1NGN",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-07-13/8409fda388b517c4ec8b2e53c0a504c4_1310596656",
					"label":"stress16",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-07-13/8409fda388b517c4ec8b2e53c0a504c4_1310603128"
				},
				"PHH18LRFO3S1ELP":{
					"is_guide":false,
					"tsid":"PHH18LRFO3S1ELP",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-07-13/1d0c8646187ba90a5dc02fbbf52a2890_1310596663",
					"label":"stress17",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-07-13/1d0c8646187ba90a5dc02fbbf52a2890_1310597952"
				},
				"PHH13AT61MR15K9":{
					"is_guide":false,
					"tsid":"PHH13AT61MR15K9",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/1f42a9cf12d4868303811efd7af8c40a_1301008889",
					"label":"stress8",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/1f42a9cf12d4868303811efd7af8c40a_1301008883"
				},
				"PHH135E6G012QMB":{
					"is_guide":false,
					"tsid":"PHH135E6G012QMB",
					"level":29,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-06-03/706cc46781eecfc18d3a664cad074687_1307134625",
					"label":"ChrisW",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-06-03/706cc46781eecfc18d3a664cad074687_1307134987"
				},
				"PMF10IAB6972K27":{
					"is_guide":false,
					"tsid":"PMF10IAB6972K27",
					"level":9,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2012-01-13/9a8fcc5e5bbe911185bf2b9d077aa270_1326506333",
					"label":"E-Yon",
					"sheet_url":"http://c2.glitch.bz/avatars/2012-01-13/9a8fcc5e5bbe911185bf2b9d077aa270_1326506655"
				},
				"PMF16FU10M52LOO":{
					"is_guide":false,
					"tsid":"PMF16FU10M52LOO",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-06-23/02f54217418cfd686f2a0d3de7097c3a_1308868177",
					"label":"cal24b",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/02f54217418cfd686f2a0d3de7097c3a_1301009097"
				},
				"PM416KGKTEL94":{
					"is_guide":false,
					"tsid":"PM416KGKTEL94",
					"level":37,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-11-12/a50b958552411b07580c1379abf071ff_1321126375",
					"label":"Myles?",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-11-12/a50b958552411b07580c1379abf071ff_1321126717"
				},
				"PM417IB5BK6LH":{
					"is_guide":false,
					"tsid":"PM417IB5BK6LH",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/2765262852ce6775fa7a497259aecb39_1301008633",
					"label":"egad",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/2765262852ce6775fa7a497259aecb39_1301008629"
				},
				"PHH16193M3S1SNT":{
					"is_guide":false,
					"tsid":"PHH16193M3S1SNT",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/e4ee8d4d85246208d89c9923b3e11337_1301009004",
					"label":"stress24",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/e4ee8d4d85246208d89c9923b3e11337_1301008997"
				},
				"PHH120511MR1FG3":{
					"is_guide":false,
					"tsid":"PHH120511MR1FG3",
					"level":1,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/719c714a7a60a773023e887a083a3a28_1301008854",
					"label":"stress1",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/719c714a7a60a773023e887a083a3a28_1301008849"
				},
				"P005":{
					"is_guide":false,
					"tsid":"P005",
					"level":2,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-03-24/2765262852ce6775fa7a497259aecb39_1301008631",
					"label":"SilentObserver",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-03-24/2765262852ce6775fa7a497259aecb39_1301008626"
				},
				"PM416MSDM0KNV":{
					"is_guide":false,
					"tsid":"PM416MSDM0KNV",
					"level":16,
					"sheet_pending":false,
					"is_admin":false,
					"online":false,
					"singles_url":"http://c2.glitch.bz/avatars/2011-07-13/f9c20aa30034f09506942214fc130794_1310596622",
					"label":"Mr Burka",
					"sheet_url":"http://c2.glitch.bz/avatars/2011-07-13/f9c20aa30034f09506942214fc130794_1310599328"
				}
			}
		}
		
	}
	
}