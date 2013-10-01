package com.tinyspeck.engine.view.util
{
	import com.quasimondo.geom.ColorMatrix;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.port.CSSManager;
	import com.tinyspeck.engine.util.ObjectUtil;
	
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	
	public class StaticFilters
	{
		
		private static const white_drop_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const white_drop_DropShadowA:Array = [white_drop_DropShadow];
		{
			white_drop_DropShadow.color = 0xffffff;
			white_drop_DropShadow.distance = 1;
			white_drop_DropShadow.angle = 90;
			white_drop_DropShadow.strength = 1;
			white_drop_DropShadow.alpha = .7;
			white_drop_DropShadow.blurX = 1;
			white_drop_DropShadow.blurY = 1;
		}
		
		private static const greyText_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const greyText_DropShadowA:Array = [greyText_DropShadow];
		{
			greyText_DropShadow.color = 0x7c756e;
			greyText_DropShadow.distance = 2;
			greyText_DropShadow.angle = 0;
			greyText_DropShadow.strength = 4;
			greyText_DropShadow.alpha = 1;
			greyText_DropShadow.blurX = 1;
			greyText_DropShadow.blurY = 1;
		}
		
		private static const anncText_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const anncText_DropShadowA:Array = [anncText_DropShadow];
		{
			anncText_DropShadow.distance = 2;
			anncText_DropShadow.angle = 45;
			anncText_DropShadow.alpha = .7;
			anncText_DropShadow.blurX = 3;
			anncText_DropShadow.blurY = 3;
		}
		
		private static const disconnectScreen_Glow:GlowFilter = new GlowFilter();
		public static const disconnectScreen_GlowA:Array = [disconnectScreen_Glow];
		{
			disconnectScreen_Glow.color = 0xffffff;
			disconnectScreen_Glow.alpha = 1;
			disconnectScreen_Glow.blurX = 2;
			disconnectScreen_Glow.blurY = 2;
			disconnectScreen_Glow.strength = 9;
			disconnectScreen_Glow.quality = 4;
		}
		
		private static const windowBorder_Glow:GlowFilter = new GlowFilter();
		public static const windowBorder_GlowA:Array = [windowBorder_Glow];
		{
			windowBorder_Glow.color = 0x000000;
			windowBorder_Glow.alpha = .37;
			windowBorder_Glow.blurX = 2;
			windowBorder_Glow.blurY = 2;
			windowBorder_Glow.strength = 10;
			windowBorder_Glow.quality = 4;
			windowBorder_Glow.knockout = true;
		}
		
		private static const tsSprite_Glow:GlowFilter = new GlowFilter();
		public static const tsSprite_GlowA:Array = [tsSprite_Glow];
		{
			tsSprite_Glow.color = 0x53e5ff;//0x69bcea;//0xfcff00;
			tsSprite_Glow.alpha = 1;
			tsSprite_Glow.blurX = 15;
			tsSprite_Glow.blurY = 15;
		}
		
		private static const countdown_Glow:GlowFilter = new GlowFilter();
		public static const countdown_GlowA:Array = [countdown_Glow];
		{
			countdown_Glow.color = 0x710007;//0x69bcea;//0xfcff00;
			countdown_Glow.alpha = 1;
			countdown_Glow.blurX = 15;
			countdown_Glow.blurY = 15;
			countdown_Glow.strength = 2;
		}
		
		CONFIG::locodeco public static const ldSelection_Glow:GlowFilter = new GlowFilter();
		CONFIG::locodeco public static const ldSelection_GlowA:Array = [ldSelection_Glow];
		CONFIG::locodeco {
			ldSelection_Glow.color = 0x53e5ff;//0x69bcea;//0xfcff00;
			ldSelection_Glow.alpha = 0.5;
			ldSelection_Glow.blurX = 15;
			ldSelection_Glow.blurY = 15;
		}
		
		private static const tsSpriteKnockout_Glow:GlowFilter = new GlowFilter();
		public static const tsSpriteKnockout_GlowA:Array = [tsSpriteKnockout_Glow];
		{
			tsSpriteKnockout_Glow.color = 0x53e5ff;//0x69bcea;//0xfcff00;
			tsSpriteKnockout_Glow.alpha = 1;
			tsSpriteKnockout_Glow.blurX = 15;
			tsSpriteKnockout_Glow.blurY = 15;
			tsSpriteKnockout_Glow.knockout = true;
		}
		
		private static const decoTarget_Glow:GlowFilter = new GlowFilter();
		public static const decoTarget_GlowA:Array = [decoTarget_Glow];
		{
			decoTarget_Glow.color = 0x53e5ff;//0x69bcea;//0xfcff00;
			decoTarget_Glow.alpha = 1;
			decoTarget_Glow.blurX = 15;
			decoTarget_Glow.blurY = 15;
			decoTarget_Glow.strength = 5;
			decoTarget_Glow.knockout = true;
			decoTarget_Glow.inner = true;
		}
		
		private static const tipDisplayManager_Glow:GlowFilter = new GlowFilter();
		public static const tipDisplayManager_GlowA:Array = [tipDisplayManager_Glow];
		{
			tipDisplayManager_Glow.color = 0xffffff;
			tipDisplayManager_Glow.alpha = 1;
			tipDisplayManager_Glow.blurX = 2;
			tipDisplayManager_Glow.blurY = 2;
			tipDisplayManager_Glow.strength = 9;
			tipDisplayManager_Glow.quality = 4;
		}
		
		private static const prompt_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const prompt_DropShadowA:Array = [prompt_DropShadow];
		{
			prompt_DropShadow.color = 0x333333;
			prompt_DropShadow.distance = 1;
			prompt_DropShadow.angle = 225;
			prompt_DropShadow.strength = 2;
			prompt_DropShadow.alpha = 1;
			prompt_DropShadow.blurX = 0;
			prompt_DropShadow.blurY = 0;
		}
		
		private static const youDisplayManager_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const youDisplayManager_DropShadowA:Array = [youDisplayManager_DropShadow];
		{
			youDisplayManager_DropShadow.color = 0xffffff;
			youDisplayManager_DropShadow.distance = 1;
			youDisplayManager_DropShadow.angle = 45;
			youDisplayManager_DropShadow.strength = 3;
			youDisplayManager_DropShadow.alpha = 1;
			youDisplayManager_DropShadow.blurX = 0;
			youDisplayManager_DropShadow.blurY = 0;
		}
		
		private static const youDisplayManager_Glow:GlowFilter = new GlowFilter();
		public static const youDisplayManager_GlowA:Array = [youDisplayManager_Glow];
		{
			youDisplayManager_Glow.color = 0xffffff;
			youDisplayManager_Glow.alpha = 1;
			youDisplayManager_Glow.blurX = 2;
			youDisplayManager_Glow.blurY = 2;
			youDisplayManager_Glow.strength = 9;
			youDisplayManager_Glow.quality = 4;
		}
		
		private static const hubButton_Glow:GlowFilter = new GlowFilter();
		public static const hubButton_GlowA:Array = [hubButton_Glow];
		{
			hubButton_Glow.color = 0xf6f270;
			hubButton_Glow.alpha = 1;
			hubButton_Glow.blurX = 2;
			hubButton_Glow.blurY = 2;
			hubButton_Glow.strength = 9;
			hubButton_Glow.quality = 4;
		}
		
		private static const slot_Glow:GlowFilter = new GlowFilter();
		public static const slot_GlowA:Array = [slot_Glow];
		{
			slot_Glow.color = 0x53e5ff;//0x69bcea;//0xfcff00;
			slot_Glow.alpha = 1;
			slot_Glow.blurX = 7;
			slot_Glow.blurY = 7;
		}
		
		private static const black_Glow:GlowFilter = new GlowFilter();
		public static const black_GlowA:Array = [black_Glow];
		{
			black_Glow.color = 0x000000;//0x69bcea;//0xfcff00;
			black_Glow.alpha = 1;
			black_Glow.blurX = 3;
			black_Glow.blurY = 3;
		}
		
		private static const loadingTip_Glow:GlowFilter = new GlowFilter();
		public static const loadingTip_GlowA:Array = [loadingTip_Glow];
		{
			loadingTip_Glow.color = 0x000000;
			loadingTip_Glow.alpha = 0.25;
			loadingTip_Glow.blurX = 6;
			loadingTip_Glow.blurY = 6;
			loadingTip_Glow.quality = 4;
		}
		
		private static const loadingTip_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const loadingTip_DropShadowA:Array = [loadingTip_DropShadow];
		{
			loadingTip_DropShadow.color = 0x000000;
			loadingTip_DropShadow.distance = 1;
			loadingTip_DropShadow.angle = 45;
			//loadingTip_DropShadow.strength = 3;
			loadingTip_DropShadow.blurX = 2;
			loadingTip_DropShadow.blurY = 2;
		}
		
		private static const statBurstGlow:GlowFilter = new GlowFilter();
		public static const statBurstGlowA:Array = [statBurstGlow];
		{
			statBurstGlow.color = 0xffffff;
			statBurstGlow.alpha = .9;
			statBurstGlow.blurX = 2;
			statBurstGlow.blurY = 2;
			statBurstGlow.strength = 12;
			statBurstGlow.quality = 4;
		}
		
		private static const white1px90Degrees_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const white1px90Degrees_DropShadowA:Array = [white1px90Degrees_DropShadow];
		{
			white1px90Degrees_DropShadow.color = 0xffffff;
			white1px90Degrees_DropShadow.distance = 1;
			white1px90Degrees_DropShadow.angle = 90;
			white1px90Degrees_DropShadow.strength = 3;
			white1px90Degrees_DropShadow.alpha = .8;
			white1px90Degrees_DropShadow.blurX = 0;
			white1px90Degrees_DropShadow.blurY = 0;
		}
		
		private static const white1px90DegreesShrineDialog_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const white1px90DegreesShrineDialog_DropShadowA:Array = [white1px90DegreesShrineDialog_DropShadow];
		{
			white1px90DegreesShrineDialog_DropShadow.color = 0xffffff;
			white1px90DegreesShrineDialog_DropShadow.distance = 1;
			white1px90DegreesShrineDialog_DropShadow.angle = 90;
			white1px90DegreesShrineDialog_DropShadow.strength = 3;
			white1px90DegreesShrineDialog_DropShadow.alpha = .4;
			white1px90DegreesShrineDialog_DropShadow.blurX = 0;
			white1px90DegreesShrineDialog_DropShadow.blurY = 0;
		}
		
		private static const white1px90DegreesJobDialog_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const white1px90DegreesJobDialog_DropShadowA:Array = [white1px90DegreesJobDialog_DropShadow];
		{
			white1px90DegreesJobDialog_DropShadow.color = 0xffffff;
			white1px90DegreesJobDialog_DropShadow.distance = 1;
			white1px90DegreesJobDialog_DropShadow.angle = 90;
			white1px90DegreesJobDialog_DropShadow.strength = 3;
			white1px90DegreesJobDialog_DropShadow.alpha = .8;
			white1px90DegreesJobDialog_DropShadow.blurX = 0;
			white1px90DegreesJobDialog_DropShadow.blurY = 0;
		}
		
		private static const white4px40AlphaGlow:GlowFilter = new GlowFilter();
		public static const white4px40AlphaGlowA:Array = [white4px40AlphaGlow];
		{
			white4px40AlphaGlow.color = 0xffffff;
			white4px40AlphaGlow.alpha = .4;
			white4px40AlphaGlow.blurX = 6;
			white4px40AlphaGlow.blurY = 6;
			white4px40AlphaGlow.strength = 10;
		}
		
		private static const cloud_glow:GlowFilter = new GlowFilter();
		public static const cloud_glowA:Array = [cloud_glow];
		{
			cloud_glow.color = 0xffffff;
			cloud_glow.alpha = .3;
			cloud_glow.blurX = 10;
			cloud_glow.blurY = 10;
			cloud_glow.strength = 50;
		}
		
		private static const blue2px_Glow:GlowFilter = new GlowFilter();
		public static const blue2px_GlowA:Array = [blue2px_Glow];
		{
			blue2px_Glow.color = 0x53e5ff;
			blue2px_Glow.alpha = 1;
			blue2px_Glow.blurX = 2;
			blue2px_Glow.blurY = 2;
			blue2px_Glow.strength = 9;
			blue2px_Glow.quality = 4;
		}
		
		private static const blue2px40Alpha_Glow:GlowFilter = new GlowFilter();
		public static const blue2px40Alpha_GlowA:Array = [blue2px40Alpha_Glow];
		{
			blue2px40Alpha_Glow.color = 0x53e5ff;
			blue2px40Alpha_Glow.alpha = .4;
			blue2px40Alpha_Glow.blurX = 2;
			blue2px40Alpha_Glow.blurY = 2;
			blue2px40Alpha_Glow.strength = 9;
			blue2px40Alpha_Glow.quality = 4;
		}
		
		private static const red2px_Glow:GlowFilter = new GlowFilter();
		public static const red2px_GlowA:Array = [red2px_Glow];
		{
			red2px_Glow.color = 0xc24c31;
			red2px_Glow.alpha = 1;
			red2px_Glow.blurX = 2;
			red2px_Glow.blurY = 2;
			red2px_Glow.strength = 9;
			red2px_Glow.quality = 4;
		}
		
		private static const polaroidPictureBorder_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const polaroidPictureBorder_DropShadowA:Array = [polaroidPictureBorder_DropShadow];
		{
			polaroidPictureBorder_DropShadow.color = 0x000000;
			polaroidPictureBorder_DropShadow.distance = 1;
			polaroidPictureBorder_DropShadow.angle = 90;
			polaroidPictureBorder_DropShadow.strength = 1;
			polaroidPictureBorder_DropShadow.alpha = .5;
			polaroidPictureBorder_DropShadow.blurX = 1;
			polaroidPictureBorder_DropShadow.blurY = 1;
		}
		
		private static const glitchrPolaroidPicture_Glow:GlowFilter = new GlowFilter();
		public static const glitchrPolaroidPicture_GlowA:Array = [glitchrPolaroidPicture_Glow];
		{
			glitchrPolaroidPicture_Glow.color = 0x000000;
			glitchrPolaroidPicture_Glow.alpha = 0.3;
			glitchrPolaroidPicture_Glow.blurX = 10;
			glitchrPolaroidPicture_Glow.blurY = 10;
			glitchrPolaroidPicture_Glow.strength = 1;
			glitchrPolaroidPicture_Glow.quality = 4;
		}
		
		private static const black2px90Degrees_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const black2px90Degrees_DropShadowA:Array = [black2px90Degrees_DropShadow];
		{
			black2px90Degrees_DropShadow.color = 0x000000;
			black2px90Degrees_DropShadow.distance = 2;
			black2px90Degrees_DropShadow.angle = 90;
			black2px90Degrees_DropShadow.strength = 1;
			black2px90Degrees_DropShadow.alpha = .6;
			black2px90Degrees_DropShadow.blurX = 1;
			black2px90Degrees_DropShadow.blurY = 1;
		}
		
		private static const black1px90DegreesJobDialog_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const black1px90DegreesJobDialog_DropShadowA:Array = [black1px90DegreesJobDialog_DropShadow];
		{
			black1px90DegreesJobDialog_DropShadow.color = 0x000000;
			black1px90DegreesJobDialog_DropShadow.distance = 1;
			black1px90DegreesJobDialog_DropShadow.angle = 90;
			black1px90DegreesJobDialog_DropShadow.strength = 1;
			black1px90DegreesJobDialog_DropShadow.alpha = .1;
			black1px90DegreesJobDialog_DropShadow.blurX = 1;
			black1px90DegreesJobDialog_DropShadow.blurY = 1;
		}
		
		private static const black1px90Degrees_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const black1px90Degrees_DropShadowA:Array = [black1px90Degrees_DropShadow];
		{
			black1px90Degrees_DropShadow.color = 0x000000;
			black1px90Degrees_DropShadow.distance = 1;
			black1px90Degrees_DropShadow.angle = 90;
			black1px90Degrees_DropShadow.strength = 1;
			black1px90Degrees_DropShadow.alpha = .6;
			black1px90Degrees_DropShadow.blurX = 1;
			black1px90Degrees_DropShadow.blurY = 1;
		}
		
		private static const black1px270Degrees_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const black1px270Degrees_DropShadowA:Array = [black1px270Degrees_DropShadow];
		{
			black1px270Degrees_DropShadow.color = 0x000000;
			black1px270Degrees_DropShadow.distance = .6;
			black1px270Degrees_DropShadow.angle = 270;
			black1px270Degrees_DropShadow.strength = 1;
			black1px270Degrees_DropShadow.alpha = .6;
			black1px270Degrees_DropShadow.blurX = 1;
			black1px270Degrees_DropShadow.blurY = 1;
		}
		
		private static const black3px90Degrees_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const black3px90Degrees_DropShadowA:Array = [black3px90Degrees_DropShadow];
		{
			black3px90Degrees_DropShadow.color = 0x000000;
			black3px90Degrees_DropShadow.distance = 3;
			black3px90Degrees_DropShadow.angle = 90;
			black3px90Degrees_DropShadow.strength = 1;
			black3px90Degrees_DropShadow.alpha = .1;
			black3px90Degrees_DropShadow.blurX = 4;
			black3px90Degrees_DropShadow.blurY = 4;
		}
		
		private static const black3px90DegreesInner_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const black3px90DegreesInner_DropShadowA:Array = [black3px90DegreesInner_DropShadow];
		{
			black3px90DegreesInner_DropShadow.color = 0x000000;
			black3px90DegreesInner_DropShadow.distance = 1;
			black3px90DegreesInner_DropShadow.angle = 90;
			black3px90DegreesInner_DropShadow.strength = 1;
			black3px90DegreesInner_DropShadow.quality = 2;
			black3px90DegreesInner_DropShadow.alpha = .2;
			black3px90DegreesInner_DropShadow.blurX = 1;
			black3px90DegreesInner_DropShadow.blurY = 3;
			black3px90DegreesInner_DropShadow.inner = true;
		}
		
		private static const black1px90DegreesInner_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const black1px90DegreesInner_DropShadowA:Array = [black1px90DegreesInner_DropShadow];
		{
			black1px90DegreesInner_DropShadow.color = 0x000000;
			black1px90DegreesInner_DropShadow.distance = 1;
			black1px90DegreesInner_DropShadow.angle = 90;
			black1px90DegreesInner_DropShadow.strength = 1;
			black1px90DegreesInner_DropShadow.quality = 2;
			black1px90DegreesInner_DropShadow.alpha = .6;
			black1px90DegreesInner_DropShadow.blurX = 1;
			black1px90DegreesInner_DropShadow.blurY = 2;
			black1px90DegreesInner_DropShadow.inner = true;
		}
		
		private static const black8px90DegreesInner_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const black8px90DegreesInner_DropShadowA:Array = [black8px90DegreesInner_DropShadow];
		{
			black8px90DegreesInner_DropShadow.color = 0x000000;
			black8px90DegreesInner_DropShadow.distance = 8;
			black8px90DegreesInner_DropShadow.angle = 90;
			black8px90DegreesInner_DropShadow.strength = 1;
			black8px90DegreesInner_DropShadow.alpha = .1;
			black8px90DegreesInner_DropShadow.blurX = 6;
			black8px90DegreesInner_DropShadow.blurY = 6;
			black8px90DegreesInner_DropShadow.inner = true;
		}
		
		private static const black7px90Degrees_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const black7px90Degrees_DropShadowA:Array = [black7px90Degrees_DropShadow];
		{
			black7px90Degrees_DropShadow.color = 0x000000;
			black7px90Degrees_DropShadow.distance = 7;
			black7px90Degrees_DropShadow.angle = 90;
			black7px90Degrees_DropShadow.strength = 1;
			black7px90Degrees_DropShadow.alpha = .1;
			black7px90Degrees_DropShadow.blurX = 4;
			black7px90Degrees_DropShadow.blurY = 4;
		}
		
		private static const black7px0Degrees_DropShadow:DropShadowFilter = new DropShadowFilter();
		public static const black7px0Degrees_DropShadowA:Array = [black7px0Degrees_DropShadow];
		{
			black7px0Degrees_DropShadow.color = 0x000000;
			black7px0Degrees_DropShadow.distance = 1;
			black7px0Degrees_DropShadow.angle = 0;
			black7px0Degrees_DropShadow.strength = 1;
			black7px0Degrees_DropShadow.alpha = .8;
			black7px0Degrees_DropShadow.blurX = 6;
			black7px0Degrees_DropShadow.blurY = 6;
		}
		
		private static const black2px90Degrees_FurnDropShadow:DropShadowFilter = new DropShadowFilter();
		public static const black2px90Degrees_FurnDropShadowA:Array = [black2px90Degrees_FurnDropShadow];
		{
			black2px90Degrees_FurnDropShadow.color = 0x000000;
			black2px90Degrees_FurnDropShadow.distance = 1;
			black2px90Degrees_FurnDropShadow.angle = 90;
			black2px90Degrees_FurnDropShadow.strength = 1;
			black2px90Degrees_FurnDropShadow.alpha = .15;
			black2px90Degrees_FurnDropShadow.blurX = 2;
			black2px90Degrees_FurnDropShadow.blurY = 3;
		}
		
		private static const black3pxInner_Glow:GlowFilter = new GlowFilter();
		public static const black3pxInner_GlowA:Array = [black3pxInner_Glow];
		{
			black3pxInner_Glow.inner = true;
			black3pxInner_Glow.blurX = 3;
			black3pxInner_Glow.blurY = 3;
			black3pxInner_Glow.alpha = .05;
			black3pxInner_Glow.color = 0;
		}
		
		private static const grey1pxOutter_Glow:GlowFilter = new GlowFilter();
		public static const grey1pxOutter_GlowA:Array = [grey1pxOutter_Glow];
		{
			grey1pxOutter_Glow.blurX = 2;
			grey1pxOutter_Glow.blurY = 2;
			grey1pxOutter_Glow.alpha = 1;
			grey1pxOutter_Glow.strength = 10;
			grey1pxOutter_Glow.color = 0xc9cecf;
		}
		
		private static const header_Glow:GlowFilter = new GlowFilter();
		public static const header_GlowA:Array = [header_Glow];
		{
			header_Glow.color = 0xe6ecee;
			header_Glow.alpha = 1;
			header_Glow.blurX = 2;
			header_Glow.blurY = 2;
			header_Glow.strength = 30;
			header_Glow.quality = 3;
		}
		
		private static const chat_left_shadow:DropShadowFilter = new DropShadowFilter();
		public static const chat_left_shadowA:Array = [chat_left_shadow];
		{
			chat_left_shadow.angle = -180;
			chat_left_shadow.alpha = .2;
			chat_left_shadow.blurX = 5;
			chat_left_shadow.blurY = 5;
			chat_left_shadow.distance = 1;
		}
		
		private static const rook_msg:DropShadowFilter = new DropShadowFilter();
		public static const rook_msgA:Array = [rook_msg];
		{
			rook_msg.angle = 90;
			rook_msg.alpha = .5;
			rook_msg.blurX = 2;
			rook_msg.blurY = 2;
			rook_msg.distance = 2;
		}
		
		private static const chat_left_shadow_inner:DropShadowFilter = new DropShadowFilter();
		public static const chat_left_shadow_innerA:Array = [chat_left_shadow_inner];
		{
			chat_left_shadow_inner.inner = true;
			chat_left_shadow_inner.angle = -180;
			chat_left_shadow_inner.alpha = .2;
			chat_left_shadow_inner.blurX = 5;
			chat_left_shadow_inner.blurY = 0;
			chat_left_shadow_inner.distance = 2;
		}
		
		private static const chat_right_shadow:DropShadowFilter = new DropShadowFilter();
		public static const chat_right_shadowA:Array = [chat_right_shadow];
		{
			chat_right_shadow.angle = 0;
			chat_right_shadow.alpha = .2;
			chat_right_shadow.distance = 1;
			chat_right_shadow.blurX = 1;
			chat_right_shadow.blurY = 1;
		}
		
		private static const white1px_Glow:GlowFilter = new GlowFilter();
		public static const white1px_GlowA:Array = [white1px_Glow];
		{
			white1px_Glow.color = 0xffffff;
			white1px_Glow.alpha = 1;
			white1px_Glow.blurX = 2;
			white1px_Glow.blurY = 2;
			white1px_Glow.strength = 8;
		}
		
		private static const white1pxSignpost_Glow:GlowFilter = new GlowFilter();
		public static const white1pxSignpost_GlowA:Array = [white1pxSignpost_Glow];
		{
			white1pxSignpost_Glow.color = 0xffffff;
			white1pxSignpost_Glow.alpha = .4;
			white1pxSignpost_Glow.blurX = 2;
			white1pxSignpost_Glow.blurY = 2;
			white1pxSignpost_Glow.strength = 3;
			white1pxSignpost_Glow.quality = 3;
		}
		
		private static const white3px_Glow:GlowFilter = new GlowFilter();
		public static const white3px_GlowA:Array = [white3px_Glow];
		{
			white3px_Glow.color = 0xffffff;
			white3px_Glow.alpha = 1;
			white3px_Glow.blurX = 4;
			white3px_Glow.blurY = 4;
			white3px_Glow.strength = 12;
		}
		
		private static const dragGrey1px_Glow:GlowFilter = new GlowFilter();
		public static const dragGrey1px_GlowA:Array = [dragGrey1px_Glow];
		{
			dragGrey1px_Glow.color = 0x383f41;
			dragGrey1px_Glow.alpha = 1;
			dragGrey1px_Glow.blurX = 2;
			dragGrey1px_Glow.blurY = 2;
			dragGrey1px_Glow.strength = 12;
		}
		
		private static const white2px40percent_Glow:GlowFilter = new GlowFilter();
		public static const white2px40percent_GlowA:Array = [white2px40percent_Glow];
		{
			white2px40percent_Glow.color = 0xffffff;
			white2px40percent_Glow.alpha = .4;
			white2px40percent_Glow.blurX = 2;
			white2px40percent_Glow.blurY = 2;
			white2px40percent_Glow.strength = 9;
			white2px40percent_Glow.quality = 4;
		}
		
		private static const inputDrop:DropShadowFilter = new DropShadowFilter(2, 90, 0, 0.2, 1, 2, 1, 1, true);
		public static const inputDropA:Array = [inputDrop];
		
		private static const infoColor:ColorMatrix = new ColorMatrix();
		{
			infoColor.colorize(0x03c6fe, 1);
		}
		private static const _infoColor:Array = [];
		// we must use a getter here, because we must put the filter in the A on get for some reason
		public static function get infoColorA():Array {
			_infoColor[0] = infoColor.filter;
			return _infoColor
		}

		private static const infoColorHighlight:ColorMatrix = new ColorMatrix();
		{
			infoColorHighlight.colorize(0xfeb403, 1);
		}
		private static const _infoColorHighlight:Array = [];
		// we must use a getter here, because we must put the filter in the A on get for some reason
		public static function get infoColorHighlightA():Array {
			_infoColorHighlight[0] = infoColorHighlight.filter;
			return _infoColorHighlight
		}
		
		public static function updateFromCSS():void {
			// TODO: pull styles from CSSManager and update the filters below with the CSS rule props
			const bg_color:uint = CSSManager.instance.getUintColorValueFromStyle('main_layout', 'backgroundColor', 0xe6ecee);
			header_Glow.color = bg_color;
		}
		
		/**
		 * This allows you to take a static filter and pass an object to change it slightly 
		 * @param new_props object with the props you want to change ie. {angle:270}
		 * @param filter_array an array with 1 filter in it
		 * @return an array with the new filter
		 */		
		public static function copyFilterArrayFromObject(new_props:Object, filter_array:Array):Array {
			var new_array:Array;
			
			if(filter_array && filter_array.length){
				//we have data, copy that data to an object that we can overrite
				new_array = [];
				var new_filter:*;
				var filter_ob:Object = ObjectUtil.copyOb(filter_array[0]);
				var k:String;
				
				//overrite with new properties
				for(k in new_props){
					if(k in filter_ob){
						filter_ob[k] = new_props[k];
					}
				}
				
				//figure out what kind of filter to make
				if(filter_array[0] is DropShadowFilter){
					new_filter = new DropShadowFilter();
				}
				else if(filter_array[0] is GlowFilter){
					new_filter = new GlowFilter();
				}
				else {
					CONFIG::debugging {
						Console.warn('Unknown filter type: '+ filter_array[0]);
					}
				}
				
				if(new_filter){
				//apply the filter_ob to the new_filter
					for(k in filter_ob){
						if(k in new_filter){
							new_filter[k] = filter_ob[k];
						}
					}
					
					//add the filter
					new_array.push(new_filter);
				}
			}
			
			return new_array;
		}
	}
}