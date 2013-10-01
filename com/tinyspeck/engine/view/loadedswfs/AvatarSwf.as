package com.tinyspeck.engine.view.loadedswfs {
	
	import com.quasimondo.geom.ColorMatrix;
	import com.tinyspeck.bootstrap.BootUtil;
	import com.tinyspeck.core.beacon.StageBeacon;
	import com.tinyspeck.core.data.AvatarAnimationDefinitions;
	import com.tinyspeck.core.data.AvatarSwfParticulars;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.debug.Tim;
	import com.tinyspeck.engine.data.pc.AvatarConfig;
	import com.tinyspeck.engine.data.pc.AvatarConfigArticle;
	import com.tinyspeck.engine.data.pc.AvatarConfigColor;
	import com.tinyspeck.engine.loader.AvatarConfigRecord;
	import com.tinyspeck.engine.loader.AvatarResourceManager;
	import com.tinyspeck.engine.util.ColorUtil;
	import com.tinyspeck.engine.util.EnvironmentUtil;
	import com.tinyspeck.engine.util.MCUtil;
	
	import flash.display.BlendMode;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.system.ApplicationDomain;
	import flash.utils.getQualifiedClassName;
	
	public class AvatarSwf extends MovieClip {
		
		// these consts are for building asset names
		public static const SHIRTTORSO:String = 'shirtTorso';
		public static const SLEEVEUPPERCLOSE:String = 'sleeveUpperClose';
		public static const SLEEVELOWERCLOSE:String = 'sleeveLowerClose';
		public static const SLEEVEUPPEROFFSIDE:String = 'sleeveUpperOffside';
		public static const SLEEVELOWEROFFSIDE:String = 'sleeveLowerOffside';
		
		public static const COATCLOSE:String = 'coatClose';
		public static const COATOFFSIDE:String = 'coatOffside';
		public static const COATSLEEVEUPPERCLOSE:String = 'coatSleeveUpperClose';
		public static const COATSLEEVELOWERCLOSE:String = 'coatSleeveLowerClose';
		public static const COATSLEEVEUPPEROFFSIDE:String = 'coatSleeveUpperOffside';
		public static const COATSLEEVELOWEROFFSIDE:String = 'coatSleeveLowerOffside';
		
		public static const SIDETAIL:String = 'sideTail';
		public static const PANTSTOP:String = 'pantsTop';
		public static const PANTSLEGUPPERCLOSE:String = 'pantsLegUpperClose';
		public static const PANTSLEGLOWERCLOSE:String = 'pantsLegLowerClose';
		public static const PANTSLEGUPPEROFFSIDE:String = 'pantsLegUpperOffside';
		public static const PANTSLEGLOWEROFFSIDE:String = 'pantsLegLowerOffside';
		public static const PANTSFOOTCLOSE:String = 'pantsFootClose';
		public static const PANTSFOOTOFFSIDE:String = 'pantsFootOffside';
		public static const DRESS:String = 'dress';
		public static const DRESSOFFSIDE:String = 'dressOffside';
		public static const DRESSSLEEVEUPPERCLOSE:String = 'dressSleeveUpperClose';
		public static const DRESSSLEEVELOWERCLOSE:String = 'dressSleeveLowerClose';
		public static const DRESSSLEEVEUPPEROFFSIDE:String = 'dressSleeveUpperOffside';
		public static const DRESSSLEEVELOWEROFFSIDE:String = 'dressSleeveLowerOffside';
		public static const SKIRT:String = 'skirt';
		public static const SOCKCLOSE:String = 'sockClose';
		public static const SOCKOFFSIDE:String = 'sockOffside';
		public static const SHOECLOSE:String = 'shoeClose';
		public static const SHOEOFFSIDE:String = 'shoeOffside';
		public static const SHOETOECLOSE:String = 'shoeToeClose';
		public static const SHOETOEOFFSIDE:String = 'shoeToeOffside';
		public static const SHOEUPPERCLOSE:String = 'shoeUpperClose';
		public static const SHOEUPPEROFFSIDE:String = 'shoeUpperOffside';
		
		public static const BOOTUPPEROFFSIDE:String = 'bootUpperOffside';
		public static const BOOTUPPERCLOSE:String = 'bootUpperClose';
		
		public static const GLOVECLOSE:String = 'gloveClose';
		public static const GLOVEOFFSIDE:String = 'gloveOffside';
		
		public static const GLOVESLEEVEUPPERCLOSE:String = 'gloveSleeveUpperClose';
		public static const GLOVESLEEVELOWERCLOSE:String = 'gloveSleeveLowerClose';
		public static const GLOVESLEEVEUPPEROFFSIDE:String = 'gloveSleeveUpperOffside';
		public static const GLOVESLEEVELOWEROFFSIDE:String = 'gloveSleeveLowerOffside';
		
		public static const RING:String = 'ring';
		public static const NECKLACE:String = 'necklace';
		public static const BACKNECKLACE:String = 'backNecklace';
		public static const CAPE:String = 'cape';
		public static const CAPETIE:String = 'capeTie';
		public static const BACKCAPE:String = 'backCape';
		public static const BRACELETCLOSE:String = 'braceletClose';
		public static const BACKBRACELETRIGHT:String = 'backBraceletRight';
		public static const SIDENOSE:String = 'sideNose';
		public static const SIDEEARCLOSE:String = 'sideEarClose';
		public static const SIDEHAIR:String = 'sideHair';
		public static const SIDEHAIRCLOSE:String = 'sideHairClose';
		public static const SIDEHAIROFFSIDE:String = 'sideHairOffside';
		public static const SIDEHAT:String = 'sideHat';
		public static const SIDEHEADDRESSOFFSIDE:String = 'sideHeaddressOffside';
		public static const SIDEHEADDRESSCLOSE:String = 'sideHeaddressClose';
		public static const SIDEEYECLOSE:String = 'sideEyeClose';
		public static const SIDEMOUTH:String = 'sideMouth';
		public static const SIDEEYEOFFSIDE:String = 'sideEyeOffside';
		
		public static const BACKSHIRTTORSO:String = 'backShirtTorso';
		public static const BACKSLEEVEUPPERLEFT:String = 'backSleeveUpperLeft';
		public static const BACKSLEEVELOWERLEFT:String = 'backSleeveLowerLeft';
		public static const BACKSLEEVEUPPERRIGHT:String = 'backSleeveUpperRight';
		public static const BACKSLEEVELOWERRIGHT:String = 'backSleeveLowerRight';
		
		public static const SIDESHOULDEROFFSIDE:String = 'sideShoulderOffside';
		public static const SIDESHOULDERCLOSEMIDDLE:String = 'sideShoulderCloseMiddle';
		public static const SIDESHOULDERCLOSE:String = 'sideShoulderClose';
		
		public static const BACKCOAT:String = 'backCoat';
		public static const BACKCOATOFFSIDE:String = 'backCoatOffside';
		public static const BACKCOATSLEEVEUPPERLEFT:String = 'backCoatSleeveUpperLeft';
		public static const BACKCOATSLEEVELOWERLEFT:String = 'backCoatSleeveLowerLeft';
		public static const BACKCOATSLEEVEUPPERRIGHT:String = 'backCoatSleeveUpperRight';
		public static const BACKCOATSLEEVELOWERRIGHT:String = 'backCoatSleeveLowerRight';
		
		public static const BACKTAIL:String = 'backTail';
		public static const BACKPANTSTOP:String = 'backPantsTop';
		public static const BACKPANTSLEGUPPERLEFT:String = 'backPantsLegUpperLeft';
		public static const BACKPANTSLEGLOWERLEFT:String = 'backPantsLegLowerLeft';
		public static const BACKPANTSLEGUPPERRIGHT:String = 'backPantsLegUpperRight';
		public static const BACKPANTSLEGLOWERRIGHT:String = 'backPantsLegLowerRight';
		public static const BACKPANTSFOOTRIGHT:String = 'backPantsFootRight';
		public static const BACKPANTSFOOTLEFT:String = 'backPantsFootLeft';
		
		public static const BACKDRESS:String = 'backDress';
		public static const BACKDRESSOFFSIDE:String = 'backDressOffside';
		public static const BACKDRESSSLEEVEUPPERLEFT:String = 'backDressSleeveUpperLeft';
		public static const BACKDRESSSLEEVELOWERLEFT:String = 'backDressSleeveLowerLeft';
		public static const BACKDRESSSLEEVEUPPERRIGHT:String = 'backDressSleeveUpperRight';
		public static const BACKDRESSSLEEVELOWERRIGHT:String = 'backDressSleeveLowerRight';
		public static const BACKSKIRT:String = 'backSkirt';
		
		public static const BACKSHOELEFT:String = 'backShoeLeft';
		public static const BACKSHOERIGHT:String = 'backShoeRight';
		public static const BACKSHOEUPPERRIGHTLEFT:String = 'backShoeUpperRight';
		public static const BACKSHOEUPPERLEFT:String = 'backShoeUpperLeft';
		
		public static const BACKBOOTUPPERLEFT:String = 'backBootUpperLeft';
		public static const BACKBOOTUPPERRIGHT:String = 'backBootUpperRight';
		
		public static const BACKGLOVERIGHT:String = 'backGloveRight';
		public static const BACKGLOVELEFT:String = 'backGloveLeft';
		public static const BACKGLOVESLEEVEUPPERLEFT:String = 'backGloveSleeveUpperLeft';
		public static const BACKGLOVESLEEVELOWERLEFT:String = 'backGloveSleeveLowerLeft';
		public static const BACKGLOVESLEEVEUPPERRIGHT:String = 'backGloveSleeveUpperRight';
		public static const BACKGLOVESLEEVELOWERRIGHT:String = 'backGloveSleeveLowerRight';
		
		public static const BACKHAIR:String = 'backHair';
		public static const BACKHAT:String = 'backHat';
		public static const BACKEARS:String = 'backEars';
		
		public var sanimations:Array = [];
		private var arm:AvatarResourceManager = AvatarResourceManager.instance;
		
		// below are for referncing the assets in use which are placed into the containers, only the ones which we will animate or allow custom placement/sizing
		private var eye_close:MovieClip;
		private var eye_offside:MovieClip;
		private var hat:MovieClip;
		private var side_hair:MovieClip;
		private var side_hair_close:MovieClip;
		private var side_hair_offside:MovieClip;
		private var back_hair:MovieClip;
		private var mouth:MovieClip;
		private var nose:MovieClip;
		private var ear_close:MovieClip;
		private var back_ears:MovieClip;
		
		// below are the skin clips
		private var skull:MovieClip;
		private var torso:MovieClip;
		private var arm_upper_close:MovieClip;
		private var arm_upper_offside:MovieClip;
		private var arm_lower_close:MovieClip;
		private var arm_lower_offside:MovieClip;
		private var hand_close:MovieClip;
		private var hand_offside:MovieClip;
		private var leg_upper_close:MovieClip;
		private var leg_upper_offside:MovieClip;
		private var leg_lower_close:MovieClip;
		private var leg_lower_offside:MovieClip;
		private var foot_close:MovieClip;
		private var foot_offside:MovieClip;
		private var back_skull:MovieClip;
		private var back_torso:MovieClip;
		private var back_arm_upper_left:MovieClip;
		private var back_arm_upper_right:MovieClip;
		private var back_arm_lower_left:MovieClip;
		private var back_arm_lower_right:MovieClip;
		private var back_hand_left:MovieClip;
		private var back_hand_right:MovieClip;
		private var back_leg_upper_left:MovieClip;
		private var back_leg_upper_right:MovieClip;
		private var back_leg_lower_left:MovieClip;
		private var back_leg_lower_right:MovieClip;
		private var back_foot_left:MovieClip;
		private var back_foot_right:MovieClip;
		//		private var ear_close:MovieClip;
		//		private var back_ears:MovieClip;
		
		private var base_skin_mcsA:Array = [
			'skull',
			'torso',
			'arm_upper_close',
			'arm_upper_offside',
			'arm_lower_close',
			'arm_lower_offside',
			'hand_close',
			'hand_offside',
			'leg_upper_close',
			'leg_upper_offside',
			'leg_lower_close',
			'leg_lower_offside',
			'foot_close',
			'foot_offside',
			'back_skull',
			'back_torso',
			'back_arm_upper_left',
			'back_arm_upper_right',
			'back_arm_lower_left',
			'back_arm_lower_right',
			'back_hand_left',
			'back_hand_right',
			'back_leg_upper_left',
			'back_leg_upper_right',
			'back_leg_lower_left',
			'back_leg_lower_right',
			'back_foot_left',
			'back_foot_right'/*,
			'ear_close', // these 
			'back_ears'
			*/
		];
		
		// this array needs to correspond to the above
		private var skin_class_namesA:Array = [
			'sideSkull',
			'sideTorso',
			'sideArmUpperClose',
			'sideArmUpperOffside',
			'sideArmLowerClose',
			'sideArmLowerOffside',
			'sideHandClose',
			'sideHandOffside',
			'sideLegUpperClose',
			'sideLegUpperOffside',
			'sideLegLowerClose',
			'sideLegLowerOffside',
			'sideFootClose',
			'sideFootOffside',
			'backHead',
			'backTorso',
			'backArmUpperLeft',
			'backArmUpperRight',
			'backArmLowerLeft',
			'backArmLowerRight',
			'backHandLeft',
			'backHandRight',
			'backLegUpperLeft',
			'backLegUpperRight',
			'backLegLowerLeft',
			'backLegLowerRight',
			'backFootLeft',
			'backFootRight'
		]
		
		// below are the clips we use to provide color
		private var skull_color:MovieClip;
		private var torso_color:MovieClip;
		private var arm_upper_close_color:MovieClip;
		private var arm_upper_offside_color:MovieClip;
		private var arm_lower_close_color:MovieClip;
		private var arm_lower_offside_color:MovieClip;
		private var hand_close_color:MovieClip;
		private var hand_offside_color:MovieClip;
		private var leg_upper_close_color:MovieClip;
		private var leg_upper_offside_color:MovieClip;
		private var leg_lower_close_color:MovieClip;
		private var leg_lower_offside_color:MovieClip;
		private var foot_close_color:MovieClip;
		private var foot_offside_color:MovieClip;
		private var back_skull_color:MovieClip;
		private var back_torso_color:MovieClip;
		private var back_arm_upper_left_color:MovieClip;
		private var back_arm_upper_right_color:MovieClip;
		private var back_arm_lower_left_color:MovieClip;
		private var back_arm_lower_right_color:MovieClip;
		private var back_hand_left_color:MovieClip;
		private var back_hand_right_color:MovieClip;
		private var back_leg_upper_left_color:MovieClip;
		private var back_leg_upper_right_color:MovieClip;
		private var back_leg_lower_left_color:MovieClip;
		private var back_leg_lower_right_color:MovieClip;
		private var back_foot_left_color:MovieClip;
		private var back_foot_right_color:MovieClip;
		private var ear_close_color:MovieClip;
		private var back_ears_color:MovieClip;
		
		private var skin_color_mcsA:Array = [
			'skull_color',
			'torso_color',
			'arm_upper_close_color',
			'arm_upper_offside_color',
			'arm_lower_close_color',
			'arm_lower_offside_color',
			'hand_close_color',
			'hand_offside_color',
			'leg_upper_close_color',
			'leg_upper_offside_color',
			'leg_lower_close_color',
			'leg_lower_offside_color',
			'foot_close_color',
			'foot_offside_color',
			'back_skull_color',
			'back_torso_color',
			'back_arm_upper_left_color',
			'back_arm_upper_right_color',
			'back_arm_lower_left_color',
			'back_arm_lower_right_color',
			'back_hand_left_color',
			'back_hand_right_color',
			'back_leg_upper_left_color',
			'back_leg_upper_right_color',
			'back_leg_lower_left_color',
			'back_leg_lower_right_color',
			'back_foot_left_color',
			'back_foot_right_color',
			'ear_close_color',
			'back_ears_color'
		];
		
		private var colorable_skin_mcsA:Array = base_skin_mcsA.concat([
			'ear_close',
			'back_ears'
		]);
		
		private var new_hair_color_mcsA:Array = [
			'side_hair',
			'side_hair_close',
			'side_hair_offside',
			'back_hair'
		];
		
		// below are the masks we use for the face
		private var mouth_mask:MovieClip;
		private var eye_close_mask:MovieClip;
		private var eye_offside_mask:MovieClip;
		
		// below are the masks we use for the pants (for boots)
		private var pants_leg_lower_offside_mask:Sprite = new Sprite();
		private var pants_leg_lower_close_mask:Sprite = new Sprite();
		private var back_pants_leg_lower_left_mask:Sprite = new Sprite();
		private var back_pants_leg_lower_right_mask:Sprite = new Sprite();
		
		private var side_hair_mask:MovieClip;
		private var side_hair_close_mask:MovieClip;
		private var side_hair_offside_mask:MovieClip;
		private var back_hair_mask:MovieClip;
		
		// below are for storing the initial positions of the face parts
		private var mouth_y:Number;
		private var nose_y:Number;
		private var ear_close_y:Number;
		private var eye_close_x:Number;
		private var eye_offside_x:Number;
		private var eye_close_y:Number;
		private var eye_offside_y:Number;
		
		private var all_stopped:Boolean;
		private var current_ac:AvatarConfig
		private var frameSeqDoneCallBack:Function;
		public var current_anim:String = '';
		
		// for the conversion
		public var avatar:MovieClip
		public var swf:MovieClip;
		private var app_domain:ApplicationDomain;
		private var new_skin_coloring:Boolean;
		
		
		public function AvatarSwf(swf:MovieClip, new_skin_coloring:Boolean) {
			this.swf = swf;
			this.new_skin_coloring = new_skin_coloring;
			app_domain = BootUtil.ava_app_domain;
			//Console.warn('BootUtil.ava_app_domain is '+app_domain)
			if (!app_domain) {
				app_domain = swf.loaderInfo.applicationDomain;// this is null when loading the avatar swf into client into the current domain, so
				//Console.warn('swf.loaderInfo.applicationDomain is '+app_domain)
			}
			if (!app_domain) {
				app_domain = ApplicationDomain.currentDomain;
				//Console.warn('ApplicationDomain.currentDomain is '+app_domain)
			}
			
			addChild(swf);
			//Security.allowDomain('*');
			initAvatar();
			//Console.setPri('0' );
		}
		
		private var hair_blend_mode:String;
		private var skin_blend_mode:String;
		private var hair_color_10_blend_mode:String;
		private var article_color_10_blend_mode:String;
		private function initAvatar():void {
			//BootError.stage = stage; WTF WAS THIS FOR????????? it borks BootError in client
			
			hair_blend_mode = BlendMode.OVERLAY;
			skin_blend_mode = BlendMode.HARDLIGHT;
			if (EnvironmentUtil.getUrlArgValue('SWF_skin_blend_mode') && EnvironmentUtil.getUrlArgValue('SWF_skin_blend_mode') in BlendMode) {
				skin_blend_mode = BlendMode[EnvironmentUtil.getUrlArgValue('SWF_skin_blend_mode')];
			}
			
			hair_color_10_blend_mode = BlendMode.NORMAL;
			article_color_10_blend_mode = BlendMode.NORMAL;
			
			if (EnvironmentUtil.getUrlArgValue('SWF_hair_color_10_blend_mode') && EnvironmentUtil.getUrlArgValue('SWF_hair_color_10_blend_mode') in BlendMode) {
				hair_color_10_blend_mode = BlendMode[EnvironmentUtil.getUrlArgValue('SWF_hair_color_10_blend_mode')];
			}
			
			if (EnvironmentUtil.getUrlArgValue('SWF_article_color_10_blend_mode') && EnvironmentUtil.getUrlArgValue('SWF_article_color_10_blend_mode') in BlendMode) {
				article_color_10_blend_mode = BlendMode[EnvironmentUtil.getUrlArgValue('SWF_article_color_10_blend_mode')];
			}
			
			avatar = swf.avatarContainer_mc;
			
			setSkinParts();
			
			// do masking for pants
			
			var makePantsMask:Function = function(g:Graphics):void {
				g.beginFill(0,1);
				g.drawRect(-7, -10, 14, 14);
				g.endFill();
			}
			
			if (EnvironmentUtil.getUrlArgValue('SWF_mask_pants') != '0') {
				back_pants_leg_lower_left_mask.visible = false;
				back_pants_leg_lower_right_mask.visible = false;
				pants_leg_lower_close_mask.visible = false;
				pants_leg_lower_offside_mask.visible = false;
			}
				
			makePantsMask(back_pants_leg_lower_left_mask.graphics);
			makePantsMask(back_pants_leg_lower_right_mask.graphics);
			makePantsMask(pants_leg_lower_close_mask.graphics);
			makePantsMask(pants_leg_lower_offside_mask.graphics);
			
			leg_lower_offside.parent.addChild(pants_leg_lower_offside_mask);
			leg_lower_close.parent.addChild(pants_leg_lower_close_mask);
			back_leg_lower_left.parent.addChild(back_pants_leg_lower_left_mask);
			back_leg_lower_right.parent.addChild(back_pants_leg_lower_right_mask);
			
			// do masking for face
			mouth_mask = getSymbolClassInstance('sideSkull');
			mouth_mask.visible = false;
			mouth_mask.name = 'mouth_mask';
			mouth_mask.x = skull.x;
			mouth_mask.y = skull.y;
			skull.parent.addChild(mouth_mask);
			
			eye_close_mask = getSymbolClassInstance('sideSkull');
			eye_close_mask.visible = false;
			eye_close_mask.name = 'eye_close_mask';
			eye_close_mask.x = skull.x;
			eye_close_mask.y = skull.y;
			skull.parent.addChild(eye_close_mask);
			
			eye_offside_mask = getSymbolClassInstance('sideSkull');
			eye_offside_mask.visible = false;
			eye_offside_mask.name = 'eye_offside_mask';
			eye_offside_mask.x = skull.x;
			eye_offside_mask.y = skull.y;
			skull.parent.addChild(eye_offside_mask);
			
			mouth_y = avatar.sideHeadContainer_mc.sideMouthContainer_mc.y;
			nose_y = avatar.sideHeadContainer_mc.sideNoseContainer_mc.y;
			ear_close_y = avatar.sideHeadContainer_mc.sideEarCloseContainer_mc.y;
			eye_close_x = avatar.sideHeadContainer_mc.sideEyeCloseContainer_mc.x;
			eye_offside_x = avatar.sideHeadContainer_mc.sideEyeOffsideContainer_mc.x;
			eye_close_y = avatar.sideHeadContainer_mc.sideEyeCloseContainer_mc.y;
			eye_offside_y = avatar.sideHeadContainer_mc.sideEyeOffsideContainer_mc.y;
			
			// for now
			var temp:String = 'http://c2.glitch.bz/clothing/base/1294351698.swf';
			//var temp1:String = 'http://localhost:81/ts/swf/package1.swf?'+new Date().getTime();
			//var temp2:String = 'http://localhost:81/ts/swf/package2.swf?'+new Date().getTime();
			var ac:AvatarConfig = AvatarConfig.fromAnonymous({
				"nose_scale"		: "1.002",
				"nose_height"		: "-0.03",
				
				"ears_height"		: "0",
				"ears_scale"		: "1.002",
				
				"eye_dist"		: "-1",
				"eye_height"		: "1.03",
				"eye_scale"		: "1",
				
				"mouth_scale"		: "1.002",
				"mouth_height"		: "0",
				
				"skin_tint_color"	: "D4C159",
				
				"hair_tint_color"	: "0",
				
				"articles": {
					nose: {
						package_swf_url: temp,
						article_class_name: 'none'
					},
					
					ears: {
						package_swf_url: temp,
						article_class_name: 'none'
					},
					
					eyes: {
						package_swf_url: temp,
						article_class_name: 'eyes_01'
					},
					
					mouth: {
						package_swf_url: temp,
						article_class_name: 'none'
					},
					
					hair: {
						package_swf_url: temp,
						article_class_name: 'none'
					},
					
					necklace: {
						package_swf_url: temp,
						article_class_name: 'none'
					},
					
					ring: {
						package_swf_url: temp,
						article_class_name: 'none'
					},
					
					gloves: {
						package_swf_url: temp,
						article_class_name: 'none'
					},
					
					bracelet: {
						package_swf_url: temp,
						article_class_name: 'none'
					},
					
					hat: {
						package_swf_url: temp,
						article_class_name: 'none'
					},
					
					dress: {
						package_swf_url: temp,
						article_class_name: 'none'
					},
					
					shoes: {
						package_swf_url: temp,
						article_class_name: 'none'
					},
					
					pants: {
						package_swf_url: temp,
						article_class_name: 'none'
					},
					
					skirt: {
						package_swf_url: temp,
						article_class_name: 'none'
					},
					
					shirt: {
						package_swf_url: temp,
						article_class_name: '20101130',
						colors: {
							color_1: {
								tintColor: 'cc0000', // hex
								brightness: 100, // [-100:100], 100 default
								saturation: 100, // [-100:100], 100 default
								contrast: 100, // [-100:100], 100 default
								tintAmount: 100 // [0 - 100], 0 default
							},
							color_2: {
								tintColor: '00cc00',
								brightness: 200,
								saturation: 100,
								contrast: 100,
								tintAmount: 100
							},
							color_3: {
								tintColor: '0000cc',
								brightness: 200,
								saturation: 100,
								contrast: 100,
								tintAmount: 100
							}
						}
					}
				}
				
				
			});
			
			//initializeHead(ac);
			//hideBody();
			//hideHead();
			/*
			setTimeout(function():void {
			switchSkinVisibility(false);
			addSpecialSkinParts('1');
			}, 3000);
			setTimeout(function():void {
			addSpecialSkinParts('2');
			}, 4000);
			setTimeout(function():void {
			switchSkinVisibility(true);
			removeSpecialSkinParts();
			}, 6000);
			*/
			//switchSkinVisibility(false);
			//addSpecialSkinParts('2');
			
		}
		
		public function showPlaceholderSkin():void {
			switchSkinVisibility(false);
			addSpecialSkinParts('3');
		}
		
		public function hidePlaceholderSkin():void {
			switchSkinVisibility(true);
			removeSpecialSkinParts();
		}
		
		private var special_skinsA:Array = [];
		private function addSpecialSkinParts(id:String):void {
			removeSpecialSkinParts();
			var C:Class;
			var p:MovieClip;
			var class_name:String;
			
			for (var i:int;i<base_skin_mcsA.length;i++) {
				p = this[base_skin_mcsA[int(i)]];
				if (p && p.parent) {
					class_name = skin_class_namesA[int(i)]+id;
					
					C = getSymbolClass(class_name);
					if (C) special_skinsA.push(p.parent.addChild(new C()));
				}
			}
		}
		
		private function getSymbolClassInstance(class_name:String):MovieClip {
			return new(getSymbolClass(class_name) as Class)();
		}
		
		private function getSymbolClass(class_name:String):Class {
			if (app_domain && app_domain.hasDefinition(class_name)) {
				var C:Class = app_domain.getDefinition(class_name) as Class;
				if (C) {
					return C;
				}
			}
			
			CONFIG::debugging {
				Console.warn(class_name+' not exists in app_domain; using '+((swf.loaderInfo.applicationDomain)?'swf.loaderInfo.applicationDomain':'ApplicationDomain.currentDomain'));
			}
			return MovieClip;
		}
		
		private function removeSpecialSkinParts():void {
			for (var i:int;i<special_skinsA.length;i++) {
				if (special_skinsA[int(i)] && special_skinsA[int(i)].parent) special_skinsA[int(i)].parent.removeChild(special_skinsA[int(i)]);
			}
			special_skinsA.length = 0;
		}
		
		public function showHead():void {
			// hides only skull, not eyes etc.
			switchBodyPartVisibility(avatar.sideHeadContainer_mc.sideSkullContainer_mc, true);
			switchBodyPartVisibility(avatar.backHeadContainer_mc.backHead_mc, true);
		}
		
		public function hideHead():void {
			// hides only skull, not eyes etc.
			switchBodyPartVisibility(avatar.sideHeadContainer_mc.sideSkullContainer_mc, false);
			switchBodyPartVisibility(avatar.backHeadContainer_mc.backHead_mc, false);
			//if (avatar.backHeadContainer_mc.parent) avatar.backHeadContainer_mc.parent.removeChild(avatar.backHeadContainer_mc);
			//if (avatar.sideHeadContainer_mc.parent) avatar.sideHeadContainer_mc.parent.removeChild(avatar.sideHeadContainer_mc);
		}
		
		public function hideArms():void {
			switchBodyPartVisibility(avatar.sideArmUpperCloseContainer_mc, false);
			switchBodyPartVisibility(avatar.sideArmUpperOffsideContainer_mc, false);
			switchBodyPartVisibility(avatar.sideArmLowerCloseContainer_mc, false);
			switchBodyPartVisibility(avatar.sideArmLowerOffsideContainer_mc, false);
			switchBodyPartVisibility(avatar.sideHandCloseContainer_mc, false);
			switchBodyPartVisibility(avatar.sideHandOffsideContainer_mc, false);
		}
		
		public function showArms():void {
			switchBodyPartVisibility(avatar.sideArmUpperCloseContainer_mc, true);
			switchBodyPartVisibility(avatar.sideArmUpperOffsideContainer_mc, true);
			switchBodyPartVisibility(avatar.sideArmLowerCloseContainer_mc, true);
			switchBodyPartVisibility(avatar.sideArmLowerOffsideContainer_mc, true);
			switchBodyPartVisibility(avatar.sideHandCloseContainer_mc, true);
			switchBodyPartVisibility(avatar.sideHandOffsideContainer_mc, true);
		}
		
		public function showAllHead():void {
			// hides all face things
			switchBodyPartVisibility(avatar.sideHeadContainer_mc, true);
			switchBodyPartVisibility(avatar.backHeadContainer_mc, true);
		}
		
		public function hideAllHead():void {
			// hides all face things
			switchBodyPartVisibility(avatar.sideHeadContainer_mc, false);
			switchBodyPartVisibility(avatar.backHeadContainer_mc, false);
		}
		
		public function showBody():void {
			switchBodyVisibility(true);
		}
		
		public function hideBody():void {
			switchBodyVisibility(false);
		}
		
		private function switchBodyPartVisibility(part:MovieClip, v:Boolean):void {
			//return;
			part.visible = v;
		}
		
		private function switchBodyVisibility(v:Boolean):void {
			//return;
			if (v) {
				showAllHead();
			} else {
				hideAllHead();
			}
			
			avatar.sideTorsoContainer_mc.visible = v;
			avatar.sideArmUpperCloseContainer_mc.visible = v;
			avatar.sideArmUpperOffsideContainer_mc.visible = v;
			avatar.sideArmLowerCloseContainer_mc.visible = v;
			avatar.sideArmLowerOffsideContainer_mc.visible = v;
			avatar.sideHandCloseContainer_mc.visible = v;
			avatar.sideHandOffsideContainer_mc.visible = v;
			avatar.sideLegUpperCloseContainer_mc.visible = v;
			avatar.sideLegUpperOffsideContainer_mc.visible = v;
			avatar.sideLegLowerCloseContainer_mc.visible = v;
			avatar.sideLegLowerOffsideContainer_mc.visible = v;
			avatar.sideFootCloseContainer_mc.visible = v;
			avatar.sideFootOffsideContainer_mc.visible = v;
			avatar.backTorsoContainer_mc.visible = v;
			avatar.backArmUpperLeftContainer_mc.visible = v;
			avatar.backArmUpperRightContainer_mc.visible = v;
			avatar.backArmLowerLeftContainer_mc.visible = v;
			avatar.backArmLowerRightContainer_mc.visible = v;
			avatar.backHandLeftContainer_mc.visible = v;
			avatar.backHandRightContainer_mc.visible = v;
			avatar.backLegUpperLeftContainer_mc.visible = v;
			avatar.backLegUpperRightContainer_mc.visible = v;
			avatar.backLegLowerLeftNakedContainer_mc.visible = v;
			avatar.backLegLowerRightNakedContainer_mc.visible = v;
			avatar.backFootLeftContainer_mc.visible = v;
			avatar.backFootRightContainer_mc.visible = v;
		}
		
		public var colors_mc_names_by_slot:Object;
		
		// misnamed for legacy sake (it does the whole body, not just the head)
		public function initializeHead(ac:AvatarConfig):void {
			
			if (current_ac && current_ac.sig == ac.sig) {
				return;
			}
			
			current_ac = ac;
			
			colors_mc_names_by_slot = {};
			
			var acr:AvatarConfigRecord = arm.getAvatarConfigRecord(ac, null);
			//Tim.stamp('arm.getAvatarConfigRecord');
			
			if (!acr.ready) {
				current_ac = null;
				// maybe we should rmeove all clothes and face parts here?
			} else {
				addEyes(ac.getArticleByType('eyes'));
				//addHat(ac.getArticleByType('hat'));
				//addHair(ac.getArticleByType('hair'));
				addMouth(ac.getArticleByType('mouth'));
				addEars(ac.getArticleByType('ears'));
				addNose(ac.getArticleByType('nose'));
				addPants(ac.getArticleByType('pants'));
				
				addShirt(null);
				addCoat(null);
				
				if (ac.getArticleByType('coat') && ac.getArticleByType('coat').article_class_name != 'none') {
					addShirt(ac.getArticleByType('shirt'));
					addCoat(ac.getArticleByType('coat'));
				} else {
					addCoat(ac.getArticleByType('coat'));
					addShirt(ac.getArticleByType('shirt'));
				}
			
				// hide or show shirt and dress sleeve containers
				var sleeve_vis:Boolean = !AvatarSwfParticulars.coatHidesAllOtherSleeves(ac.getArticleByType('coat'));
				AvatarSwfParticulars.shirt_and_dress_sleeve_containersA.forEach(function(name:String, ...a):void {
					if (avatar[name]) {
						avatar[name].visible = sleeve_vis;
					} else {
						CONFIG::debugging {
							Console.warn(name+' not found on avatar');
						}
					}
				});
				
				addDress(null);
				addSkirt(null);
				
				// skirt must be exclusive of dress
				if (ac.getArticleByType('skirt') && ac.getArticleByType('skirt').article_class_name != 'none') {
					addSkirt(ac.getArticleByType('skirt'));
				} else {
					addDress(ac.getArticleByType('dress'));
				}
				
				if (AvatarSwfParticulars.hatCanBeWornWithHair(ac.getArticleByType('hat'), ac.getArticleByType('hair'))) {
					addHat(ac.getArticleByType('hat'));
					addHair(ac.getArticleByType('hair'));
				} else {
					// hat must be exclusive of hair
					if (ac.getArticleByType('hat') && ac.getArticleByType('hat').article_class_name != 'none') {
						addHair(null);
						addHat(ac.getArticleByType('hat'));
					} else {
						addHat(null);
						addHair(ac.getArticleByType('hair'));
					}
				}
				
				addShoes(ac.getArticleByType('shoes'));
				
				addCape(ac.getArticleByType('cape'));
				addGlove(ac.getArticleByType('gloves'));
				addRing(ac.getArticleByType('ring'));
				addNecklace(ac.getArticleByType('necklace'));
				addBracelet(ac.getArticleByType('bracelet'));
				
				if (all_stopped) {
					gotoFrameNumAndStop(avatar.currentFrame);
				} else {
					gotoFrameNumAndPlay(avatar.currentFrame);
				}/*
				
				if (ac.pc_tsid == 'P001') {
					switchSkinVisibility(false);
				}*/
				
			}
			//Tim.stamp('all the adds');
			
			
			if (side_hair_mask && side_hair_mask.parent) side_hair_mask.parent.removeChild(side_hair_mask);
			if (side_hair_close_mask && side_hair_close_mask.parent) side_hair_close_mask.parent.removeChild(side_hair_close_mask);
			if (side_hair_offside_mask && side_hair_offside_mask.parent) side_hair_offside_mask.parent.removeChild(side_hair_offside_mask);
			if (back_hair_mask && back_hair_mask.parent) back_hair_mask.parent.removeChild(back_hair_mask);
			if (side_hair && hat && AvatarSwfParticulars.hatCanBeWornWithHair(ac.getArticleByType('hat'), ac.getArticleByType('hair'))) {
				
				side_hair_mask = arm.getArticlePartMC(ac.getArticleByType('hat'), SIDEHAT+'HairMask');
				if (side_hair_mask) {
					avatar.sideHeadContainer_mc.sideHatContainer_mc.addChild(side_hair_mask);
					if (EnvironmentUtil.getUrlArgValue('SWF_hat_and_hair_mask_show') != '1') side_hair.mask = side_hair_mask;
					
					side_hair_close_mask = arm.getArticlePartMC(ac.getArticleByType('hat'), SIDEHAT+'HairMask');
					if (side_hair_close) {
						avatar.sideHeadContainer_mc.sideHatContainer_mc.addChild(side_hair_close_mask);
						if (EnvironmentUtil.getUrlArgValue('SWF_hat_and_hair_mask_show') != '1') side_hair_close.mask = side_hair_close_mask;
					}
					
					side_hair_offside_mask = arm.getArticlePartMC(ac.getArticleByType('hat'), SIDEHAT+'HairMask');
					if (side_hair_offside) {
						avatar.sideHeadContainer_mc.sideHatContainer_mc.addChild(side_hair_offside_mask);
						if (EnvironmentUtil.getUrlArgValue('SWF_hat_and_hair_mask_show') != '1') side_hair_offside.mask = side_hair_offside_mask;
					}
					
				} else {
					;
					CONFIG::debugging {
						Console.warn('no '+SIDEHAT+'HairMask')
					}
				}
				
				back_hair_mask = arm.getArticlePartMC(ac.getArticleByType('hat'), BACKHAT+'HairMask');
				if (back_hair_mask) {
					avatar.backHatContainer_mc.addChild(back_hair_mask);
					if (EnvironmentUtil.getUrlArgValue('SWF_hat_and_hair_mask_show') != '1') back_hair.mask = back_hair_mask;
				} else {
					;
					CONFIG::debugging {
						Console.warn('no '+BACKHAT+'HairMask')
					}
				}
			}
			
			// end articles that need loading
			
			// start applying colors to skin/hair and do facial feature placement customizations
			CONFIG::debugging {
				Console.log(467, 'new_skin_coloring '+new_skin_coloring);
			}
			
			if (new_skin_coloring && ac.skin_colors) {
				
				if (ac.skin_colors && ac.skin_colors['color_1']) {
					addColorToSkin(getColorFilterForArticelColor(ac.skin_colors['color_1']));
				} else {
					addColorToSkin(null);
				}
				
				if (ac.skin_colors && ac.skin_colors['color_10']) {
					addShadowToSkin(getColorFilterForArticelColor(ac.skin_colors['color_10']));
				} else {
					addShadowToSkin(null);
				}
				
				if (ac.skin_colors && ac.skin_colors['color_2']) {
					addTextureToSkin(getColorFilterForArticelColor(ac.skin_colors['color_2']));
				} else {
					addTextureToSkin(null);
				}
				
				if (EnvironmentUtil.getUrlArgValue('SWF_overlay_skin_copy') == '1') {
					makeColorMcsForBody();
				}
				
			} else {
				
				makeColorMcsForBody();
				
				CONFIG::debugging {
					Console.log(467, 'addColorTransformToSkinColorParts '+ac.skin_tint_color);
				}
				if (ac.skin_tint_color > 0) {
					addColorTransformToSkinColorParts(ColorUtil.getColorTransform(ac.skin_tint_color));
				}
			}
			
			if (ac.hair_colors && ac.hair_colors['color_1']) {
				if (side_hair && ac.hair_colors && ac.hair_colors['color_1']) {
					addColorToHair(getColorFilterForArticelColor(ac.hair_colors['color_1']));
				} else {
					addColorToHair(null);
				}
				
				if (side_hair && ac.hair_colors && ac.hair_colors['color_10']) {
					addShadowToHair(getColorFilterForArticelColor(ac.hair_colors['color_10']));
				} else {
					addShadowToHair(null);
				}
			}
			//Tim.stamp('Coloring');
			
			if (eye_close) {//('eye_scale')) {
				eye_close.scaleX = eye_close.scaleY = Number(ac.eye_scale)
			}
			if (eye_offside) {//('eye_scale')) {
				eye_offside.scaleX = eye_offside.scaleY = Number(ac.eye_scale);
			}
			if (nose) {//('nose_scale')) {
				nose.scaleX = nose.scaleY = Number(ac.nose_scale);
			}
			if (mouth) {//('mouth_scale')) {
				mouth.scaleX = mouth.scaleY = Number(ac.mouth_scale);
			}
			if (ear_close) {//('ears_scale')) {
				ear_close.scaleX = ear_close.scaleY = Number(ac.ears_scale);
				if (ear_close_color) ear_close_color.scaleX = ear_close_color.scaleY = Number(ac.ears_scale);
			}
			if (back_ears) {//('ears_scale')) {
				back_ears.scaleX = back_ears.scaleY = Number(ac.ears_scale);
				if (back_ears_color) back_ears_color.scaleX = back_ears_color.scaleY = Number(ac.ears_scale);
			}

			var shc_mc:MovieClip = avatar.sideHeadContainer_mc;
			
			shc_mc.sideMouthContainer_mc.y = mouth_y+int(ac.mouth_height);
			shc_mc.sideMouthContainer_mc.y = mouth_y+ int(ac.mouth_height);
			shc_mc.sideNoseContainer_mc.y = nose_y+int(ac.nose_height);
			shc_mc.sideEarCloseContainer_mc.y = ear_close_y+int(ac.ears_height);
			shc_mc.sideEyeCloseContainer_mc.x = eye_close_x-int(ac.eye_dist);
			shc_mc.sideEyeOffsideContainer_mc.x = eye_offside_x+int(ac.eye_dist);
			shc_mc.sideEyeCloseContainer_mc.y = eye_close_y+int(ac.eye_height);
			shc_mc.sideEyeOffsideContainer_mc.y = eye_offside_y+int(ac.eye_height);
			//Tim.stamp('POsitioning');
			
		}
		
		/* -----------------------------------------------------------------------------------------------------------------
		START COLORING METHODS --------------------------------------------------------------------------------------------- */
		
		private function addColorTransformToSkinColorParts(ct:ColorTransform):void {
			for (var i:int;i<skin_color_mcsA.length;i++) {
				if (this[skin_color_mcsA[int(i)]]) this[skin_color_mcsA[int(i)]].transform.colorTransform = ct;
				if (this[skin_color_mcsA[int(i)]]) this[skin_color_mcsA[int(i)]].x = parseInt(EnvironmentUtil.getUrlArgValue('skin_temp_x')) || 0;
			}
		}
		
		private function addColorToSkin(filtersA:Array):void {
			for (var i:int;i<colorable_skin_mcsA.length;i++) {
				if (this[colorable_skin_mcsA[int(i)]]) this[colorable_skin_mcsA[int(i)]].filters = filtersA;
			}
		}
		
		private function addShadowToSkin(filtersA:Array):void {
			var c:int = 0;
			for (var i:int;i<colorable_skin_mcsA.length;i++) {
				if (this[colorable_skin_mcsA[int(i)]] && this[colorable_skin_mcsA[int(i)]]['color_10']) {
					//Console.warn(this[colorable_skin_mcsA[int(i)]]+' '+this[colorable_skin_mcsA[int(i)]]['color_10'])
					this[colorable_skin_mcsA[int(i)]]['color_10'].filters = filtersA;
					c++;
				}
			}
			//Console.warn('skin shadow did '+c)
		}
		
		private function addTextureToSkin(filtersA:Array):void {
			var c:int = 0;
			for (var i:int;i<colorable_skin_mcsA.length;i++) {
				if (this[colorable_skin_mcsA[int(i)]] && this[colorable_skin_mcsA[int(i)]]['color_2']) {
					//Console.warn(this[colorable_skin_mcsA[int(i)]]+' '+this[colorable_skin_mcsA[int(i)]]['color_10'])
					this[colorable_skin_mcsA[int(i)]]['color_2'].filters = filtersA;
					c++
				}
			}
			//Console.warn('skin texture did '+c)
		}
		
		private function addColorToHair(filtersA:Array):void {
			for (var i:int;i<new_hair_color_mcsA.length;i++) {
				if (this[new_hair_color_mcsA[int(i)]] && this[new_hair_color_mcsA[int(i)]]['color_1']) {
					this[new_hair_color_mcsA[int(i)]]['color_1'].filters = filtersA;
				}
			}
		}
		
		private function addShadowToHair(filtersA:Array):void {
			for (var i:int;i<new_hair_color_mcsA.length;i++) {
				if (this[new_hair_color_mcsA[int(i)]] && this[new_hair_color_mcsA[int(i)]]['color_10']) {
					//Console.warn(this[new_hair_color_mcsA[int(i)]]+' '+this[new_hair_color_mcsA[int(i)]]['color_10'])
					//this[new_hair_color_mcsA[int(i)]]['color_10'].visible = false;
					if (hair_color_10_blend_mode) {
						this[new_hair_color_mcsA[int(i)]]['color_10'].blendMode = hair_color_10_blend_mode;
					}
					if (EnvironmentUtil.getUrlArgValue('SWF_color_10_scale')) {
						this[new_hair_color_mcsA[int(i)]]['color_10'].scaleX = this[new_hair_color_mcsA[int(i)]]['color_10'].scaleY = parseFloat(EnvironmentUtil.getUrlArgValue('SWF_color_10_scale'));
					}
					this[new_hair_color_mcsA[int(i)]]['color_10'].filters = filtersA;
				}
			}
		}
		
		private function switchSkinVisibility(v:Boolean):void {
			for (var i:int;i<base_skin_mcsA.length;i++) {
				var p:MovieClip = this[base_skin_mcsA[int(i)]];
				if (p) {
					p.visible = v;
					if (base_skin_mcsA[int(i)] == 'skull') {
						//trace(DisplayDebug.LogCoords(p.parent, 20));
					}
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						trace(base_skin_mcsA[int(i)]+ 'not exists');
					}
				}
			}
			
			for (i=0;i<skin_color_mcsA.length;i++) {
				if (this[skin_color_mcsA[int(i)]]) this[skin_color_mcsA[int(i)]].visible = v;
			}
		}
		
		private function makeColorMcsForBody():void {
			// color for the skull
			skull_color = makeColorMCForSkin(getSymbolClassInstance('sideSkull'), 'sideHeadContainer_mc', 'sideSkullContainer_mc', 'sideSkull_mc');
			// color for the torso
			torso_color = makeColorMCForSkin(getSymbolClassInstance('sideTorso'), 'sideTorsoContainer_mc', 'sideTorso_mc');
			// color for upper arms
			arm_upper_close_color = makeColorMCForSkin(getSymbolClassInstance('sideArmUpperClose'), 'sideArmUpperCloseContainer_mc', 'sideArmUpperClose_mc');
			arm_upper_offside_color = makeColorMCForSkin(getSymbolClassInstance('sideArmUpperOffside'), 'sideArmUpperOffsideContainer_mc', 'sideArmUpperOffside_mc');
			// color for lower harms
			arm_lower_close_color = makeColorMCForSkin(getSymbolClassInstance('sideArmLowerClose'), 'sideArmLowerCloseContainer_mc', 'sideArmLowerClose_mc');
			arm_lower_offside_color = makeColorMCForSkin(getSymbolClassInstance('sideArmLowerOffside'), 'sideArmLowerOffsideContainer_mc', 'sideArmLowerOffside_mc');
			// color for hands
			hand_close_color = makeColorMCForSkin(getSymbolClassInstance('sideHandClose'), 'sideHandCloseContainer_mc', 'sideHandClose_mc');
			hand_offside_color = makeColorMCForSkin(getSymbolClassInstance('sideHandOffside'), 'sideHandOffsideContainer_mc', 'sideHandOffside_mc');
			// color for upper legs
			leg_upper_close_color = makeColorMCForSkin(getSymbolClassInstance('sideLegUpperClose'), 'sideLegUpperCloseContainer_mc', 'sideLegUpperClose_mc');
			leg_upper_offside_color = makeColorMCForSkin(getSymbolClassInstance('sideLegUpperOffside'), 'sideLegUpperOffsideContainer_mc', 'sideLegUpperOffside_mc');
			// color for lower legs
			leg_lower_close_color = makeColorMCForSkin(getSymbolClassInstance('sideLegLowerClose'), 'sideLegLowerCloseContainer_mc', 'sideLegLowerClose_mc');
			leg_lower_offside_color = makeColorMCForSkin(getSymbolClassInstance('sideLegLowerOffside'), 'sideLegLowerOffsideContainer_mc', 'sideLegLowerOffside_mc');
			// color for feet
			foot_close_color = makeColorMCForSkin(getSymbolClassInstance('sideFootClose'), 'sideFootCloseContainer_mc', 'sideFootClose_mc');
			foot_offside_color = makeColorMCForSkin(getSymbolClassInstance('sideFootOffside'), 'sideFootOffsideContainer_mc', 'sideFootOffside_mc');
			// color for the skull
			back_skull_color = makeColorMCForSkin(getSymbolClassInstance('backHead'), 'backHeadContainer_mc', 'backHead_mc');
			// color for the torso
			back_torso_color = makeColorMCForSkin(getSymbolClassInstance('backTorso'), 'backTorsoContainer_mc', 'backTorso_mc');
			// color for upper arms
			back_arm_upper_left_color = makeColorMCForSkin(getSymbolClassInstance('backArmUpperLeft'), 'backArmUpperLeftContainer_mc', 'backArmUpperLeft_mc');
			back_arm_upper_right_color = makeColorMCForSkin(getSymbolClassInstance('backArmUpperRight'), 'backArmUpperRightContainer_mc', 'backArmUpperRight_mc');
			// color for lower harms
			back_arm_lower_left_color = makeColorMCForSkin(getSymbolClassInstance('backArmLowerLeft'), 'backArmLowerLeftContainer_mc', 'backArmLowerLeft_mc');
			back_arm_lower_right_color = makeColorMCForSkin(getSymbolClassInstance('backArmLowerRight'), 'backArmLowerRightContainer_mc', 'backArmLowerRight_mc');
			// color for hands
			back_hand_left_color = makeColorMCForSkin(getSymbolClassInstance('backHandLeft'), 'backHandLeftContainer_mc', 'backHandLeft_mc');
			back_hand_right_color = makeColorMCForSkin(getSymbolClassInstance('backHandRight'), 'backHandRightContainer_mc', 'backHandRight_mc');
			// color for upper legs
			back_leg_upper_left_color = makeColorMCForSkin(getSymbolClassInstance('backLegUpperLeft'), 'backLegUpperLeftContainer_mc', 'backLegUpperLeft_mc');
			back_leg_upper_right_color = makeColorMCForSkin(getSymbolClassInstance('backLegUpperRight'), 'backLegUpperRightContainer_mc', 'backLegUpperRight_mc');
			// color for lower legs
			back_leg_lower_left_color = makeColorMCForSkin(getSymbolClassInstance('backLegLowerLeft'), 'backLegLowerLeftNakedContainer_mc', 'backLegLowerLeft_mc');
			back_leg_lower_right_color = makeColorMCForSkin(getSymbolClassInstance('backLegLowerRight'), 'backLegLowerRightNakedContainer_mc', 'backLegLowerRight_mc');
			// color for feet
			back_foot_left_color = makeColorMCForSkin(getSymbolClassInstance('backFootLeft'), 'backFootLeftContainer_mc', 'backFootLeft_mc');
			back_foot_right_color = makeColorMCForSkin(getSymbolClassInstance('backFootRight'), 'backFootRightContainer_mc', 'backFootRight_mc');
		}
		
		private function setSkinParts():void {
			// skull
			skull = getSkinPart('sideHeadContainer_mc', 'sideSkullContainer_mc', 'sideSkull_mc');
			// torso
			torso = getSkinPart('sideTorsoContainer_mc', 'sideTorso_mc');
			// upper arms
			arm_upper_close = getSkinPart('sideArmUpperCloseContainer_mc', 'sideArmUpperClose_mc');
			arm_upper_offside = getSkinPart('sideArmUpperOffsideContainer_mc', 'sideArmUpperOffside_mc');
			// lower harms
			arm_lower_close = getSkinPart('sideArmLowerCloseContainer_mc', 'sideArmLowerClose_mc');
			arm_lower_offside = getSkinPart('sideArmLowerOffsideContainer_mc', 'sideArmLowerOffside_mc');
			// hands
			hand_close = getSkinPart('sideHandCloseContainer_mc', 'sideHandClose_mc');
			hand_offside = getSkinPart('sideHandOffsideContainer_mc', 'sideHandOffside_mc');
			// upper legs
			leg_upper_close = getSkinPart('sideLegUpperCloseContainer_mc', 'sideLegUpperClose_mc');
			leg_upper_offside = getSkinPart('sideLegUpperOffsideContainer_mc', 'sideLegUpperOffside_mc');
			// lower legs
			leg_lower_close = getSkinPart('sideLegLowerCloseContainer_mc', 'sideLegLowerClose_mc');
			leg_lower_offside = getSkinPart('sideLegLowerOffsideContainer_mc', 'sideLegLowerOffside_mc');
			// feet
			foot_close = getSkinPart('sideFootCloseContainer_mc', 'sideFootClose_mc');
			foot_offside = getSkinPart('sideFootOffsideContainer_mc', 'sideFootOffside_mc');
			// skull
			back_skull = getSkinPart('backHeadContainer_mc', 'backHead_mc');
			// torso
			back_torso = getSkinPart('backTorsoContainer_mc', 'backTorso_mc');
			// upper arms
			back_arm_upper_left = getSkinPart('backArmUpperLeftContainer_mc', 'backArmUpperLeft_mc');
			back_arm_upper_right = getSkinPart('backArmUpperRightContainer_mc', 'backArmUpperRight_mc');
			// lower harms
			back_arm_lower_left = getSkinPart('backArmLowerLeftContainer_mc', 'backArmLowerLeft_mc');
			back_arm_lower_right = getSkinPart('backArmLowerRightContainer_mc', 'backArmLowerRight_mc');
			// hands
			back_hand_left = getSkinPart('backHandLeftContainer_mc', 'backHandLeft_mc');
			back_hand_right = getSkinPart('backHandRightContainer_mc', 'backHandRight_mc');
			// upper legs
			back_leg_upper_left = getSkinPart('backLegUpperLeftContainer_mc', 'backLegUpperLeft_mc');
			back_leg_upper_right = getSkinPart('backLegUpperRightContainer_mc', 'backLegUpperRight_mc');
			// lower legs
			back_leg_lower_left = getSkinPart('backLegLowerLeftNakedContainer_mc', 'backLegLowerLeft_mc');
			back_leg_lower_right = getSkinPart('backLegLowerRightNakedContainer_mc', 'backLegLowerRight_mc');
			// feet
			back_foot_left = getSkinPart('backFootLeftContainer_mc', 'backFootLeft_mc');
			back_foot_right = getSkinPart('backFootRightContainer_mc', 'backFootRight_mc');
		}
		
		private function makeColorMCForSkin(color_mc:MovieClip, ... path):MovieClip {
			color_mc.name = getQualifiedClassName(color_mc)+'_color';
			var p:MovieClip = avatar;
			
			// make sure the whole path exists before doing anything
			for (var i:int;i<path.length;i++) {
				p = p[path[int(i)]];
				if (!p) {
					CONFIG::debugging {
						Console.warn(path[int(i)]+' not exists');
					}
					return null;
				}
			}
			
			// we do this check because we have to call makeColorMcsForBody on every initializeHead,
			// in order to get the back containers, which are fucked somehow, but we don't want to add extra color mcs
			if (p.parent.getChildByName(color_mc.name)) {
				//Console.warn('already has '+getQualifiedClassName(color_mc))
				return p.parent.getChildByName(color_mc.name) as MovieClip;
			}
			
			color_mc.blendMode = skin_blend_mode;
			//if (color_mc['color_1']) color_mc['color_1'].visible = false;
			//if (color_mc['color_2']) color_mc['color_2'].visible = false;
			if (EnvironmentUtil.getUrlArgValue('SWF_offset_copy')) color_mc.x = int(EnvironmentUtil.getUrlArgValue('SWF_offset_copy'));
			p.parent.addChild(color_mc);
			
			return color_mc;
		}
		
		private function getSkinPart(... path):MovieClip {
			var p:MovieClip = avatar;
			
			// make sure the whole path exists before doing anything
			for (var i:int;i<path.length;i++) {
				p = p[path[int(i)]];
				if (!p) {
					CONFIG::debugging {
						Console.warn(path[int(i)]+' not exists');
					}
					return null;
				}
			}
			
			return p;
		}
		
		
		private function getColorFiltersForArticle(aca:AvatarConfigArticle):Object {
			if (!aca) return null;
			if (!aca.colors) return null;
			var H:Object = {};
			for (var k:String in aca.colors) {
				H[k] = getColorFilterForArticelColor(aca.colors[k])
			}
			return H;
		}
		
		
		private function getColorFilterForArticelColor(acc:AvatarConfigColor):Array {
			/*			color_1: {
			tintColor: 'cc0000', // hex
			brightness: 100, // [-100:100], 100 default
			saturation: 100, // [-100:100], 100 default
			contrast: 100, // [-100:100], 100 default
			tintAmount: 100 // [0 - 100], 0 default
			},
			*/
			var cm:com.quasimondo.geom.ColorMatrix = new com.quasimondo.geom.ColorMatrix();
			cm.colorize(acc.tintColor, (acc.tintAmount) ? acc.tintAmount/100 : 0);
			cm.adjustContrast((acc.contrast) ? acc.contrast/100 : 0);
			cm.adjustSaturation(((acc.saturation) ? acc.saturation/100 : 0)+1);
			cm.adjustBrightness((acc.brightness) ? acc.brightness : 0);
			cm.setAlpha((acc.alpha > -1) ? acc.alpha/100 : 100);
			return [cm.filter];
		}
		
		private function maybeColorIt(mc:MovieClip, name:String, filtersA:Array):Boolean {
			if (!mc) return false;
			if (!mc[name]) return false;
			if (name == 'color_10' && article_color_10_blend_mode) {
				mc[name].blendMode = article_color_10_blend_mode;
			}
			//info('coloring '+name)
			mc[name].filters = filtersA;
			return true;
		}
		
		/* END COLORING METHODS ---------------------------------------------------------------------------------------------
		------------------------------------------------------------------------------------------------------------------------------- */
		
		
		/* -----------------------------------------------------------------------------------------------------------------
		START ANIMATION METHODS --------------------------------------------------------------------------------------------- */
		
		/*****************************************************************************
		 * 	  To a single movement with the Avatar container the following time 
		 * 	  frames must be referenced:    
		 * 
		 * 	  -   main movement container - avatarContainer_mc 
		 *    
		 *    
		 * 	  -   Mouth    
		 *    -   Eyes containers: 
		 * 					@ Close eye
		 * 					@ Offside eye	
		 * 		ActionTypes:  (see samples above for implemenation)   
		 * 					A) walk1x
		 * 					b) walk2x
		 * 					c) ignore
		 * 					d) ignore2
		 * 					e) jumpUp
		 * 					f) jumpOver
		 * 					g) surprise
		 * 					h) happy
		 * 					i) angry
		 * 					j) idle1,idle2,idle3 idle4
		 * 					k) climb 
		 * 		***  NOTE:  only the avatarContainer_mc has a climb animation    ***
		 * 		***  don't reference the eyes or mouth animations for climb      ***
		 * 					l) do			
		 * 
		 *****************************************************************************/
		
		private function gotoFrameNumAndStop(num:int):void {
			CONFIG::debugging {
				Console.log(333, num);
			}
			Tim.stamp(222, 'start gotoFrameNumAndStop');
			var log:String = String(avatar.currentFrame+'->'+num);
			if (num == avatar.currentFrame+1) {
				avatar.nextFrame();
				Tim.stamp(222, 'nextFrame '+log);
				MCUtil.recursiveGotoAndStopChildrenOnly(avatar, num);
				Tim.stamp(222, 'MCUtil.recursiveGotoAndStopChildrenOnly');
			} else {
				MCUtil.recursiveGotoAndStop(avatar, num);
				Tim.stamp(222, 'MCUtil.recursiveGotoAndStop ------------------- '+log);
			}
			
			if (do_correct_hair) correctHair(num);
			
			current_anim = '';
			all_stopped = true;
		}
		
		private function gotoFrameNumAndPlay(num:int):void {
			CONFIG::debugging {
				Console.log(333, num);
			}
			Tim.stamp(222, 'start gotoFrameNumAndPlay');
			var log:String = String(avatar.currentFrame+'->'+num);
			if (num == avatar.currentFrame+1) {
				avatar.nextFrame();
				Tim.stamp(222, 'nextFrame '+log);
				MCUtil.recursiveGotoAndPlayChildrenOnly(avatar, num);
				Tim.stamp(222, 'MCUtil.recursiveGotoAndPlayChildrenOnly');
			} else {
				MCUtil.recursiveGotoAndPlay(avatar, num);
				Tim.stamp(222, 'MCUtil.recursiveGotoAndPlay ------------------- '+log);
			}
			
			if (do_correct_hair) correctHair(num);
		}
		
		private function stopAll():void {
			CONFIG::debugging {
				Console.log(333, 'avatar stop');
			}
			MCUtil.recursiveStop(avatar);
			all_stopped = true;
		}
		
		public var do_correct_hair:Boolean;
		private function correctHair(num:int):void {
			if (!do_correct_hair) return;
			if (side_hair) MCUtil.recursiveGotoAndStop(side_hair, 801);
			if (side_hair_close) MCUtil.recursiveGotoAndStop(side_hair_close, 801);
			if (side_hair_offside) MCUtil.recursiveGotoAndStop(side_hair_offside, 801);
			if (back_hair) MCUtil.recursiveGotoAndStop(back_hair, 801);
		}
		
		public function playAnimation(anim:String, callBack:Function = null, special_anim_stop_index:int=-1):void {
			if (AvatarAnimationDefinitions.getSheetedAnimsA().indexOf(anim) > -1) {
				var framesA:Array = AvatarAnimationDefinitions.getFramesForAnim(anim);
				
				if (special_anim_stop_index > -1 && special_anim_stop_index < framesA.length-1) {
					framesA.length = special_anim_stop_index+1;
				}
				
				playFrameSeq(framesA, callBack);
			}
		}
		
		public function playAnimationSeq(seq_anim:*, callBack:Function = null):void {
			var seq_animA:Array = [];
			var A:Array = (seq_anim is String) ? seq_anim.split(',') : (seq_anim is Array) ? seq_anim : [];
			for (var i:int;i<A.length;i++) {
				if (AvatarAnimationDefinitions.getSheetedAnimsA().indexOf(A[int(i)]) > -1) {
					seq_animA.push(A[int(i)]);
				} else {
					; // satisfy compiler
					CONFIG::debugging {
						Console.error(A[int(i)]+' not recognized')
					}
				}
			}
			
			CONFIG::debugging {
				Console.log(333, 'of '+seq_anim+' actually playing '+seq_animA);
			}
			
			var framesA:Array = [];
			for (i=0;i<seq_animA.length;i++) {
				framesA = framesA.concat(AvatarAnimationDefinitions.getFramesForAnim(seq_animA[int(i)]));
			}
			playFrameSeq(framesA, callBack);
		}
		
		
		private var seq_framesA:Array = [];
		public function playFrameSeq(framesA:Array, callBack:Function = null):void {
			
			if (!framesA) {
				CONFIG::debugging {
					Console.error('WTF NOT framesA');
				}
				return;
			}
			
			seq_framesA.length = 0;
			
			for (var i:int;i<framesA.length;i++) {
				if (framesA[int(i)]>0 && framesA[int(i)]<=avatar.totalFrames) {
					seq_framesA.push(framesA[int(i)]);
				} else {
					CONFIG::debugging {
						; // satisfy compiler
						Console.warn(framesA[int(i)]+' not recognized');
					}
				}
			}
			
			CONFIG::debugging {
				Console.log(333, 'of '+framesA+' actually playing '+seq_framesA);
			}
			
			if (callBack != null) {
				frameSeqDoneCallBack = callBack;
			} else {
				frameSeqDoneCallBack = null;
			}
			
			playNextInFrameSeqA();
			
			if (add_listener) {
				add_listener = false;
				StageBeacon.enter_frame_sig.add(onEnterFrame);
			}
		}
		
		private var add_listener:Boolean = true;
		private function onEnterFrame(ms_elapsed:int):void {
			playNextInFrameSeqA();
		}
		
		private function playNextInFrameSeqA():void {
			if (seq_framesA.length) {
				//Console.warn('afterPlayAnimationSeq doing '+seq_framesA[0]);
				gotoFrameNumAndStop(seq_framesA.shift());
				
			} else {
				add_listener = true;
				StageBeacon.enter_frame_sig.remove(onEnterFrame); // for now just remove listener
				
				if (frameSeqDoneCallBack != null) {
					frameSeqDoneCallBack();
					frameSeqDoneCallBack = null
				}
			}
		}
		
		/* END ANIMATION METHODS ---------------------------------------------------------------------------------------------
		------------------------------------------------------------------------------------------------------------------------------- */
		
		/* -----------------------------------------------------------------------------------------------------------------
		START GENERAL ASSET ADDING METHODS --------------------------------------------------------------------------------------------- */
		
		private function removeArticlePartFromContainer(p:MovieClip, container_name:String):void {
			var container:MovieClip = p[container_name];
			if (!container) {
				CONFIG::debugging {
					Console.warn(container_name+' is null while trying to remove article part')
				}
				return;
			}
			while (container.numChildren) container.removeChildAt(0);
		}
		
		private function addOrRemove(part_class_name:String, aca:AvatarConfigArticle, p:MovieClip, container_name:String, colorFiltersH:Object = null):MovieClip {
			if (!aca || !aca.article_class_name || aca.article_class_name == 'none') {
				removeArticlePartFromContainer(p, container_name);
				return null;
			}
			
			return addArticlePartToContainer(part_class_name, aca, p, container_name, colorFiltersH);
		}
		
		private function addArticlePartToContainer(part_class_name:String, aca:AvatarConfigArticle, p:MovieClip, container_name:String, colorFiltersH:Object = null):MovieClip {
			var container:MovieClip = p[container_name];
			var article_part:MovieClip = arm.getArticlePartMC(aca, part_class_name);
			
			CONFIG::debugging {
				Console.log(89, part_class_name+' '+article_part);
			}
			
			if (!article_part) article_part = new MovieClip();
			if (container) {
				removeArticlePartFromContainer(p, container_name);
			} else {
				CONFIG::debugging {
					Console.warn(container_name+' is null while trying to add '+name);
				}
				return article_part;
			}
			
			if (aca) {
				// let's look for all the color_X children this thing has!
				if (colors_mc_names_by_slot) {
					if (!colors_mc_names_by_slot[aca.type]) colors_mc_names_by_slot[aca.type] = [];
					var A:Array = colors_mc_names_by_slot[aca.type];
					
					// 20 colors. the php only does 15 right now, but we send 20 if they exist
					for (var i:int=1;i<21;i++) {
						var color_name:String = 'color_'+i;
						if (A.indexOf(color_name) != -1) continue; // we already know about this color_X for this slot
						if (article_part[color_name]) {
							A.push(color_name);
						}
					}
				}
				
				//apply masks
				if (part_class_name.toLowerCase().indexOf('eyeclose')>-1) {
					article_part.mask = eye_close_mask;
				} else if (part_class_name.toLowerCase().indexOf('eyeoffside')>-1) {
					article_part.mask = eye_offside_mask;
				} else if (part_class_name.toLowerCase().indexOf('mouth')>-1) {
					article_part.mask = mouth_mask;
				}
			} else {
				//trace('no aca for '+part_class_name)
			}
			
			container.addChildAt(article_part, 0);
			
			if (colorFiltersH) {
				for (var k:String in colorFiltersH) {
					if (maybeColorIt(article_part, k, colorFiltersH[k])) {
						; // satisfy compiler
						CONFIG::debugging {
							Console.log(89, part_class_name+' colored with '+k);
						}
					} else {
						; // satisfy compiler
						CONFIG::debugging {
							Console.priwarn(89, part_class_name+' NOT colored with '+k);
						}
					}
				}
			}
			
			return article_part;
		}
		
		/* END GENERAL ASSET ADDING METHODS ---------------------------------------------------------------------------------------------
		------------------------------------------------------------------------------------------------------------------------------- */
		
		/* -----------------------------------------------------------------------------------------------------------------
		START SPECIFIC ASSET ADDING METHODS --------------------------------------------------------------------------------------------- */
		
		// FIRST CLOTHES
		
		private function addShirt(aca:AvatarConfigArticle):void {
			var colorFiltersH:Object = getColorFiltersForArticle(aca);
			
			addOrRemove(SHIRTTORSO, aca, avatar, 'sideShirtContainer_mc', colorFiltersH);
			addOrRemove(BACKSHIRTTORSO, aca, avatar, 'backShirtContainer_mc', colorFiltersH);
			addOrRemove(SLEEVEUPPERCLOSE, aca, avatar, 'sideShirtSleeveUpperCloseContainer_mc', colorFiltersH);
			addOrRemove(BACKSLEEVEUPPERLEFT, aca, avatar, 'backSleeveUpperLeftContainer_mc', colorFiltersH);
			addOrRemove(SLEEVELOWERCLOSE, aca, avatar, 'sideShirtSleeveLowerCloseContainer_mc', colorFiltersH);
			addOrRemove(BACKSLEEVELOWERLEFT, aca, avatar, 'backSleeveLowerLeftContainer_mc', colorFiltersH);
			addOrRemove(SLEEVEUPPEROFFSIDE, aca, avatar, 'sideShirtSleeveUpperOffsideContainer_mc', colorFiltersH);
			addOrRemove(BACKSLEEVEUPPERRIGHT, aca, avatar, 'backSleeveUpperRightContainer_mc', colorFiltersH);
			addOrRemove(SLEEVELOWEROFFSIDE, aca, avatar, 'sideShirtSleeveLowerOffsideContainer_mc', colorFiltersH);
			addOrRemove(BACKSLEEVELOWERRIGHT, aca, avatar, 'backSleeveLowerRightContainer_mc', colorFiltersH);
		}
		
		private function addDress(aca:AvatarConfigArticle):void {
			var colorFiltersH:Object = getColorFiltersForArticle(aca);
			
			addOrRemove(BACKDRESS, aca, avatar, 'backDressContainer_mc', colorFiltersH);
			
			addOrRemove(BACKDRESSOFFSIDE, aca, avatar, 'backDressOffsideContainer_mc', colorFiltersH);
			addOrRemove(DRESS, aca, avatar, 'sideDressContainer_mc', colorFiltersH);
			
			addOrRemove(DRESSOFFSIDE, aca, avatar, 'sideDressOffsideContainer_mc', colorFiltersH);
			
			addOrRemove(DRESSSLEEVEUPPERCLOSE, aca, avatar, 'sideDressSleeveUpperCloseContainer_mc', colorFiltersH);
			addOrRemove(BACKDRESSSLEEVEUPPERLEFT, aca, avatar, 'backDressSleeveUpperLeftContainer_mc', colorFiltersH);
			addOrRemove(DRESSSLEEVEUPPEROFFSIDE, aca, avatar, 'sideDressSleeveUpperOffsideContainer_mc', colorFiltersH);
			addOrRemove(BACKDRESSSLEEVEUPPERRIGHT, aca, avatar, 'backDressSleeveUpperRightContainer_mc', colorFiltersH);
			
			
			addOrRemove(DRESSSLEEVELOWERCLOSE, aca, avatar, 'sideDressSleeveLowerCloseContainer_mc', colorFiltersH);
			addOrRemove(BACKDRESSSLEEVELOWERLEFT, aca, avatar, 'backDressSleeveLowerLeftContainer_mc', colorFiltersH);
			addOrRemove(DRESSSLEEVELOWEROFFSIDE, aca, avatar, 'sideDressSleeveLowerOffsideContainer_mc', colorFiltersH);
			addOrRemove(BACKDRESSSLEEVELOWERRIGHT, aca, avatar, 'backDressSleeveLowerRightContainer_mc', colorFiltersH);
			
			
			
			
//			sideDressSleeveLowerCloseContainer
	//		sideDressSleeveLowerOffsideContainer
		//	backDressSleeveLowerRightContainer
			//backDressSleeveLowerLeftContainer
			
			/*
			backDressSleeveUpperRightContainer added (over shirt sleeve container)
			backDressSleeveUpperLeftContainer added (over shirt sleeve container)
			sideDressSleeveUpperCloseContainer
			sideDressSleeveUpperOffsideContainer*/
		}
		
		private function addCape(aca:AvatarConfigArticle):void {
			var colorFiltersH:Object = getColorFiltersForArticle(aca);
			
			addOrRemove(CAPETIE, aca, avatar, 'sideCapeTieContainer_mc', colorFiltersH);
			
			addOrRemove(BACKCAPE, aca, avatar, 'backCapeContainer_mc', colorFiltersH);
			
			addOrRemove(CAPE, aca, avatar, 'sideCapeContainer_mc', colorFiltersH);
		}
		
		private function addSkirt(aca:AvatarConfigArticle):void {
			var colorFiltersH:Object = getColorFiltersForArticle(aca);
			
			addOrRemove(BACKSKIRT, aca, avatar, 'backSkirtContainer_mc', colorFiltersH);
			
			addOrRemove(SKIRT, aca, avatar, 'sideSkirtContainer_mc', colorFiltersH);
		}

		private function addCoat(aca:AvatarConfigArticle):void {
			var colorFiltersH:Object = getColorFiltersForArticle(aca);
			
			addOrRemove(COATCLOSE, aca, avatar, 'sideCoatCloseContainer_mc', colorFiltersH);
			addOrRemove(COATOFFSIDE, aca, avatar, 'sideCoatOffsideContainer_mc', colorFiltersH);

			addOrRemove(BACKCOAT, aca, avatar, 'backCoatContianer_mc', colorFiltersH);
			
			addOrRemove(BACKCOATOFFSIDE, aca, avatar, 'backCoatOffsideContainer_mc', colorFiltersH);
			
			addOrRemove(COATSLEEVEUPPERCLOSE, aca, avatar, 'sideCoatSleeveUpperCloseContainer_mc', colorFiltersH);
			addOrRemove(BACKCOATSLEEVEUPPERLEFT, aca, avatar, 'backCoatSleeveUpperLeftContainer_mc', colorFiltersH);
			addOrRemove(COATSLEEVELOWERCLOSE, aca, avatar, 'sideCoatSleeveLowerCloseContainer_mc', colorFiltersH);
			addOrRemove(BACKCOATSLEEVELOWERLEFT, aca, avatar, 'backCoatSleeveLowerLeftContainer_mc', colorFiltersH);
			addOrRemove(COATSLEEVEUPPEROFFSIDE, aca, avatar, 'sideCoatSleeveUpperOffsideContainer_mc', colorFiltersH);
			addOrRemove(BACKCOATSLEEVEUPPERRIGHT, aca, avatar, 'backCoatSleeveUpperRightContainer_mc', colorFiltersH);
			addOrRemove(COATSLEEVELOWEROFFSIDE, aca, avatar, 'sideCoatSleeveLowerOffsideContainer_mc', colorFiltersH);
			addOrRemove(BACKCOATSLEEVELOWERRIGHT, aca, avatar, 'backCoatSleeveLowerRightContainer_mc', colorFiltersH);
			
			addOrRemove(SIDESHOULDEROFFSIDE, aca, avatar, 'sideShoulderOffsideContainer_mc', colorFiltersH);
			addOrRemove(SIDESHOULDERCLOSEMIDDLE, aca, avatar, 'sideShoulderCloseMiddleContainer_mc', colorFiltersH);
			addOrRemove(SIDESHOULDERCLOSE, aca, avatar, 'sideShoulderCloseContainer_mc', colorFiltersH);
		}
		
		private function addPants(aca:AvatarConfigArticle):void {
			var colorFiltersH:Object = getColorFiltersForArticle(aca);
			
			addOrRemove(SIDETAIL, aca, avatar, 'sideTailContainer_mc', colorFiltersH);
			addOrRemove(BACKTAIL, aca, avatar, 'backTailContainer_mc', colorFiltersH);
			addOrRemove(PANTSTOP, aca, avatar, 'sidePantsBottomContainer_mc', colorFiltersH);
			addOrRemove(BACKPANTSTOP, aca, avatar, 'backPantsBottomContainer_mc', colorFiltersH);
			addOrRemove(PANTSLEGUPPERCLOSE, aca, avatar, 'sidePantsUpperCloseContainer_mc', colorFiltersH);
			addOrRemove(BACKPANTSLEGUPPERLEFT, aca, avatar, 'backPantsUpperLeftContainer_mc', colorFiltersH);
			addOrRemove(PANTSLEGLOWERCLOSE, aca, avatar, 'sidePantsLowerCloseContainer_mc', colorFiltersH);
			addOrRemove(BACKPANTSLEGLOWERLEFT, aca, avatar, 'backPantsLowerLeftContainer_mc', colorFiltersH);
			addOrRemove(PANTSLEGUPPEROFFSIDE, aca, avatar, 'sidePantsUpperOffsideContainer_mc', colorFiltersH);
			addOrRemove(BACKPANTSLEGUPPERRIGHT, aca, avatar, 'backPantsUpperRightContainer_mc', colorFiltersH);
			addOrRemove(PANTSLEGLOWEROFFSIDE, aca, avatar, 'sidePantsLowerOffsideContainer_mc', colorFiltersH);
			addOrRemove(BACKPANTSLEGLOWERRIGHT, aca, avatar, 'backPantsLowerRightContainer_mc', colorFiltersH);
			
			addOrRemove(PANTSFOOTCLOSE, aca, avatar, 'sidePantsFootCloseContainer_mc', colorFiltersH);
			addOrRemove(PANTSFOOTOFFSIDE, aca, avatar, 'sidePantsFootOffsideContainer_mc', colorFiltersH);
			addOrRemove(BACKPANTSFOOTRIGHT, aca, avatar, 'backPantsFootRightContainer_mc', colorFiltersH);
			addOrRemove(BACKPANTSFOOTLEFT, aca, avatar, 'backPantsFootLeftContainer_mc', colorFiltersH);
		}
		
		
		private function addShoes(aca:AvatarConfigArticle):void {
			var colorFiltersH:Object = getColorFiltersForArticle(aca);
			
			var is_boot:Boolean = aca && (aca.article_class_name.toLowerCase().indexOf('boot') > -1 || aca.article_class_name.toLowerCase().indexOf('ball') > -1);
			
			// oops, 'ball' above catches ballet shoes
			if (aca && aca.article_class_name.toLowerCase().indexOf('ballet') > -1) is_boot = false;
			
			removeArticlePartFromContainer(avatar, 'sideShoeCloseContainer_mc');
			removeArticlePartFromContainer(avatar, 'sideShoeOffsideContainer_mc');
			removeArticlePartFromContainer(avatar, 'sideToeCloseContainer_mc');
			removeArticlePartFromContainer(avatar, 'sideToeOffsideContainer_mc');
			removeArticlePartFromContainer(avatar, 'backShoeRightContainer_mc');
			removeArticlePartFromContainer(avatar, 'backShoeLeftContainer_mc');
			removeArticlePartFromContainer(avatar, 'sideShoeUpperCloseContainer_mc');
			removeArticlePartFromContainer(avatar, 'sideShoeUpperOffsideContainer_mc');
			removeArticlePartFromContainer(avatar, 'backShoeUpperRightContainer_mc');
			removeArticlePartFromContainer(avatar, 'backShoeUpperLeftContainer_mc');
			
			removeArticlePartFromContainer(avatar, 'sideBootFootCloseContainer_mc');
			removeArticlePartFromContainer(avatar, 'sideBootFootOffsideContainer_mc');
			removeArticlePartFromContainer(avatar, 'backBootFootRightContainer_mc');
			removeArticlePartFromContainer(avatar, 'backBootFootLeftContainer_mc');
			removeArticlePartFromContainer(avatar, 'sideBootUpperOffsideContainer_mc');
			removeArticlePartFromContainer(avatar, 'sideBootUpperCloseContainer_mc');
			removeArticlePartFromContainer(avatar, 'backBootUpperLeftContainer_mc');
			removeArticlePartFromContainer(avatar, 'backBootUpperRightContainer_mc');
			
			avatar.sidePantsLowerCloseContainer_mc.mask = null;
			avatar.sidePantsLowerOffsideContainer_mc.mask = null;
			avatar.backPantsLowerLeftContainer_mc.mask = null;
			avatar.backPantsLowerRightContainer_mc.mask = null;
			
			if (is_boot) {
				
				addOrRemove(SHOECLOSE, aca, avatar, 'sideBootFootCloseContainer_mc', colorFiltersH);
				addOrRemove(SHOEOFFSIDE, aca, avatar, 'sideBootFootOffsideContainer_mc', colorFiltersH);
				addOrRemove(BACKSHOERIGHT, aca, avatar, 'backBootFootRightContainer_mc', colorFiltersH);
				addOrRemove(BACKSHOELEFT, aca, avatar, 'backBootFootLeftContainer_mc', colorFiltersH);
				
				addOrRemove(BOOTUPPEROFFSIDE, aca, avatar, 'sideBootUpperOffsideContainer_mc', colorFiltersH);
				addOrRemove(BOOTUPPERCLOSE, aca, avatar, 'sideBootUpperCloseContainer_mc', colorFiltersH);
				addOrRemove(BACKBOOTUPPERLEFT, aca, avatar, 'backBootUpperLeftContainer_mc', colorFiltersH);
				addOrRemove(BACKBOOTUPPERRIGHT, aca, avatar, 'backBootUpperRightContainer_mc', colorFiltersH);
			} else {
				
				addOrRemove(SHOECLOSE, aca, avatar, 'sideShoeCloseContainer_mc', colorFiltersH);
				addOrRemove(SHOEOFFSIDE, aca, avatar, 'sideShoeOffsideContainer_mc', colorFiltersH);
				addOrRemove(SHOETOECLOSE, aca, avatar, 'sideToeCloseContainer_mc', colorFiltersH);
				addOrRemove(SHOETOEOFFSIDE, aca, avatar, 'sideToeOffsideContainer_mc', colorFiltersH);
				addOrRemove(BACKSHOERIGHT, aca, avatar, 'backShoeRightContainer_mc', colorFiltersH);
				addOrRemove(BACKSHOELEFT, aca, avatar, 'backShoeLeftContainer_mc', colorFiltersH);
				addOrRemove(SHOEUPPERCLOSE, aca, avatar, 'sideShoeUpperCloseContainer_mc', colorFiltersH);
				addOrRemove(SHOEUPPEROFFSIDE, aca, avatar, 'sideShoeUpperOffsideContainer_mc', colorFiltersH);
				addOrRemove(BACKSHOEUPPERRIGHTLEFT, aca, avatar, 'backShoeUpperRightContainer_mc', colorFiltersH);
				addOrRemove(BACKSHOEUPPERLEFT, aca, avatar, 'backShoeUpperLeftContainer_mc', colorFiltersH);
			}
			
			if (is_boot && EnvironmentUtil.getUrlArgValue('SWF_mask_pants') != '0') {
				avatar.sidePantsLowerCloseContainer_mc.mask = pants_leg_lower_close_mask;
				avatar.sidePantsLowerOffsideContainer_mc.mask = pants_leg_lower_offside_mask;
				avatar.backPantsLowerLeftContainer_mc.mask = back_pants_leg_lower_left_mask;
				avatar.backPantsLowerRightContainer_mc.mask = back_pants_leg_lower_right_mask;
			}
		}
		
		/*
		
		bracelet, gloves, necklace and boots
		
		sideBootUpperOffsideContainer_mc
		sideBootUpperCloseContainer_mc
		backBootUpperLeftContainer_mc
		backBootUpperRightContainer_mc
		
		new avatar containers (layers) added to the FLA, 3/24/2011
		
		sideGloveSleeveUpperCloseContainer
		sideGloveSleeveLowerCloseContainer
		
		sideGloveSleeveUpperOffsideContainer
		sideGloveSleeveLowerOffsideContainer
		
		
		backGloveSleeveUpperLeftContainer
		backGloveSleeveLowerLeftContainer
		
		backGloveSleeveUpperRightContainer
		backGloveSleeveLowerRightContainer

		
		
		backGloveRightContainer_mc
		backGloveLeftContainer_mc
		
		backNecklaceContainer (added below)
		*/
		
		private function addGlove(aca:AvatarConfigArticle):void {
			var colorFiltersH:Object = getColorFiltersForArticle(aca);
			
			addOrRemove(GLOVECLOSE, aca, avatar, 'sideGloveCloseContainer_mc', colorFiltersH);
			addOrRemove(GLOVEOFFSIDE, aca, avatar, 'sideGloveOffsideContainer_mc', colorFiltersH);
			addOrRemove(GLOVESLEEVEUPPERCLOSE, aca, avatar, 'sideGloveSleeveUpperCloseContainer_mc', colorFiltersH);
			addOrRemove(GLOVESLEEVELOWERCLOSE, aca, avatar, 'sideGloveSleeveLowerCloseContainer_mc', colorFiltersH);
			addOrRemove(GLOVESLEEVEUPPEROFFSIDE, aca, avatar, 'sideGloveSleeveUpperOffsideContainer', colorFiltersH);
			addOrRemove(GLOVESLEEVELOWEROFFSIDE, aca, avatar, 'sideGloveSleeveLowerOffsideContainer_mc', colorFiltersH);
			
			addOrRemove(BACKGLOVERIGHT, aca, avatar, 'backGloveRightContainer_mc', colorFiltersH);
			addOrRemove(BACKGLOVELEFT, aca, avatar, 'backGloveLeftContainer_mc', colorFiltersH);
			addOrRemove(BACKGLOVESLEEVEUPPERLEFT, aca, avatar, 'backGloveSleeveUpperLeftContainer_mc', colorFiltersH);
			addOrRemove(BACKGLOVESLEEVELOWERLEFT, aca, avatar, 'backGloveSleeveLowerLeftContainer_mc', colorFiltersH);
			addOrRemove(BACKGLOVESLEEVEUPPERRIGHT, aca, avatar, 'backGloveSleeveUpperRightContainer_mc', colorFiltersH);
			addOrRemove(BACKGLOVESLEEVELOWERRIGHT, aca, avatar, 'backGloveSleeveLowerRightContainer_mc', colorFiltersH);
		}
		
		private function addSocks(aca:AvatarConfigArticle):void {
			var colorFiltersH:Object = getColorFiltersForArticle(aca);
			
			addOrRemove(SOCKCLOSE, aca, avatar, 'sideSockCloseContainer_mc', colorFiltersH);
			addOrRemove(SOCKOFFSIDE, aca, avatar, 'sideSockOffsideContainer_mc', colorFiltersH);
		}	
		
		private function addRing(aca:AvatarConfigArticle):void {
			var colorFiltersH:Object = getColorFiltersForArticle(aca);
			
			addOrRemove(RING, aca, avatar, 'sideRingCloseContainer_mc', colorFiltersH);
		}
		
		private function addNecklace(aca:AvatarConfigArticle):void {
			var colorFiltersH:Object = getColorFiltersForArticle(aca);
			
			addOrRemove(NECKLACE, aca, avatar, 'sideNecklaceContainer_mc', colorFiltersH);
			addOrRemove(BACKNECKLACE, aca, avatar, 'backNecklaceContainer_mc', colorFiltersH);
		}
		private function addBracelet(aca:AvatarConfigArticle):void {
			var colorFiltersH:Object = getColorFiltersForArticle(aca);
			
			addOrRemove(BRACELETCLOSE, aca, avatar, 'sideBraceletCloseContainer_mc', colorFiltersH);
			addOrRemove(BACKBRACELETRIGHT, aca, avatar, 'backBraceletRightContainer_mc', colorFiltersH);
		}
		
		private function addHat(aca:AvatarConfigArticle):void {
			var colorFiltersH:Object = getColorFiltersForArticle(aca);
			
			addOrRemove(BACKHAT, aca, avatar, 'backHatContainer_mc', colorFiltersH);
			
			var new_hat:MovieClip = addArticlePartToContainer(SIDEHAT, aca, avatar.sideHeadContainer_mc, 'sideHatContainer_mc', colorFiltersH);
			if (new_hat) {
				hat = new_hat;
			}
			
			addOrRemove(SIDEHEADDRESSOFFSIDE, aca, avatar, 'sideHeaddressOffsideContainer_mc', colorFiltersH);
			
			addOrRemove(SIDEHEADDRESSCLOSE, aca, avatar, 'sideHeaddressCloseContainer_mc', colorFiltersH);
			/*
			avatar['sideHeaddressOffsideContainer_mc'].y-= 30;
			avatar['sideHeaddressOffsideContainer_mc'].x-= 30;
			
			Console.warn('sideHeaddressCloseContainer_mc: '+StringUtil.DOPath(avatar['sideHeaddressCloseContainer_mc']));
			Console.warn('sideHeaddressOffsideContainer_mc: '+StringUtil.DOPath(avatar['sideHeaddressOffsideContainer_mc']));*/
		}
		
		// SECOND BODY PARTS
		
		private function addEyes(aca:AvatarConfigArticle):void {
			var new_eye_close:MovieClip = addArticlePartToContainer(SIDEEYECLOSE, aca, avatar.sideHeadContainer_mc, 'sideEyeCloseContainer_mc');
			if (new_eye_close) eye_close = new_eye_close;
			
			var new_eye_offside:MovieClip = addArticlePartToContainer(SIDEEYEOFFSIDE, aca, avatar.sideHeadContainer_mc, 'sideEyeOffsideContainer_mc');
			if (new_eye_offside) eye_offside = new_eye_offside;
		}
		
		private function addEars(aca:AvatarConfigArticle):void {
			var new_ear:MovieClip = addOrRemove(SIDEEARCLOSE, aca, avatar.sideHeadContainer_mc, 'sideEarCloseContainer_mc');
			ear_close = new_ear
			if (new_ear) {
				if (!new_skin_coloring || EnvironmentUtil.getUrlArgValue('SWF_overlay_skin_copy') == '1') {
					if (arm.articlePartExists(aca, SIDEEARCLOSE) && avatar.sideHeadContainer_mc.sideEarCloseContainer_mc) {
						ear_close_color = avatar.sideHeadContainer_mc.sideEarCloseContainer_mc.addChild(arm.getArticlePartMC(aca, SIDEEARCLOSE)) as MovieClip;
						ear_close_color.blendMode = skin_blend_mode;
					}
				}
			}
			
			var new_back_ears:MovieClip = addOrRemove(BACKEARS, aca, avatar, 'backEarsContainer_mc');
			back_ears = new_back_ears;
			if (new_back_ears) {
				if (!new_skin_coloring || EnvironmentUtil.getUrlArgValue('SWF_overlay_skin_copy') == '1') {
					if (arm.articlePartExists(aca, BACKEARS) && avatar.backEarsContainer_mc) {
						back_ears_color = avatar.backEarsContainer_mc.addChild(arm.getArticlePartMC(aca, BACKEARS)) as MovieClip;
						back_ears_color.blendMode = skin_blend_mode;
					}
				}
			}
		}
		
		private function addNose(aca:AvatarConfigArticle):void {
			nose = addOrRemove(SIDENOSE, aca, avatar.sideHeadContainer_mc, 'sideNoseContainer_mc');
		}
		
		private function addHair(aca:AvatarConfigArticle):void {
			
			var new_back_hair:MovieClip = addArticlePartToContainer(BACKHAIR, aca, avatar, 'backHairContainer_mc');
			if (new_back_hair) {
				back_hair = new_back_hair;
			}
			
			var new_side_hair:MovieClip = addArticlePartToContainer(SIDEHAIR, aca, avatar.sideHeadContainer_mc, 'sideHairContainer_mc');
			if (new_side_hair) {
				side_hair = new_side_hair;
				back_hair = new_back_hair;
			}
			
			var new_side_hair_close:MovieClip = addArticlePartToContainer(SIDEHAIRCLOSE, aca, avatar, 'sideHairCloseContainer_mc');
			if (new_side_hair_close) {
				side_hair_close = new_side_hair_close;
			}
			
			var new_side_hair_offside:MovieClip = addArticlePartToContainer(SIDEHAIROFFSIDE, aca, avatar, 'sideHairOffsideContainer_mc');
			if (new_side_hair_offside) {
				side_hair_offside = new_side_hair_offside;
			}
			
			//DisplayDebug.LogCoords(avatar, 3);
		}
		
		private function addMouth(aca:AvatarConfigArticle):void {
			var new_mouth:MovieClip = addArticlePartToContainer(SIDEMOUTH, aca, avatar.sideHeadContainer_mc, 'sideMouthContainer_mc');
			if (new_mouth) mouth = new_mouth;
		}
		
	}
}
