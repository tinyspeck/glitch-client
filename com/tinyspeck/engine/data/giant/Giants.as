package com.tinyspeck.engine.data.giant
{
	import com.tinyspeck.debug.BootError;

	public class Giants
	{
		public static const SEX_MALE:String = 'male';
		public static const SEX_FEMALE:String = 'female';
		public static const SEX_NONE:String = 'none';
				
		private static const GIANT_DATA:Object = {
													alph: {
														sex: SEX_MALE,
														label: 'Alph',
														bg_color: 0x455637
													},
													humbaba: {
														sex: SEX_FEMALE,
														label: 'Humbaba',
														bg_color: 0x5f434a
													},
													cosma: {
														sex: SEX_FEMALE,
														label: 'Cosma',
														bg_color: 0x3a475d
													},
													spriggan: {
														sex: SEX_MALE,
														label: 'Spriggan',
														bg_color: 0x44241c
													},
													grendaline: {
														sex: SEX_FEMALE,
														label: 'Grendaline',
														bg_color: 0x053634
													},
													zille: {
														sex: SEX_FEMALE,
														label: 'Zille',
														bg_color: 0x4e3e18
													},
													mab: {
														sex: SEX_FEMALE,
														label: 'Mab',
														bg_color: 0x4d5f43
													},
													tii: {
														sex: SEX_NONE,
														label: 'Tii',
														bg_color: 0x2e3548
													},
													lem: {
														sex: SEX_MALE,
														label: 'Lem',
														bg_color: 0x476d57
													},
													pot: {
														sex: SEX_MALE,
														label: 'Pot',
														bg_color: 0x32606e
													},
													friendly: {
														sex: SEX_MALE,
														label: 'Friendly',
														bg_color: 0x010b1c
													},
													all: {
														sex: SEX_NONE,
														label: 'all of the Giants'
													}
												};
			
		public static function getSex(name:String):String {
			if(isGiant(name)) return String(GIANT_DATA[name.toLowerCase()].sex);
			
			return null;
		}
		
		public static function getLabel(name:String):String {
			if(isGiant(name)) return String(GIANT_DATA[name.toLowerCase()].label);
			
			return null;
		}
		
		public static function getBgColor(name:String):uint {
			if(isGiant(name)) return uint(GIANT_DATA[name.toLowerCase()].bg_color) || 0;
			
			return 0;
		}
		
		public static function isGiant(name:String):Boolean {
			if (name == 'ti') {
				BootError.handleError('ti where expected tii', new Error('Unknown Giant'), null, !CONFIG::debugging);
			}
			return GIANT_DATA.hasOwnProperty(name.toLowerCase());
		}
	}
}