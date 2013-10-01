package com.tinyspeck.bridge {
	import com.tinyspeck.debug.Console;
	
	public class PrefsModel {
		public var int_menu_more_quantity_buttons:Boolean;
		public var int_menu_default_to_one:Boolean;
		public var do_oneclick_pickup:Boolean = true;
		public var do_stat_count_animations:Boolean = true;
		public var do_power_saving_mode:Boolean = true;
		public var up_key_is_enter:Boolean = false;
		
		private const _pref_namesA:Array = [
			'int_menu_more_quantity_buttons',
			'int_menu_default_to_one',
			'do_oneclick_pickup',
			'do_stat_count_animations',
			'do_power_saving_mode',
			'up_key_is_enter'
		]
		
		public function get pref_namesA():Array {
			return _pref_namesA;
		}
		
		// add an item already in _pref_namesA to this array in order to keep it from appearing in non DEV clients
		private const _god_only_pref_namesA:Array = [
			
		]
		
		public function get god_only_pref_namesA():Array {
			return _god_only_pref_namesA;
		}

		private const pref_descriptions:Object = {
			int_menu_more_quantity_buttons: 'Show extra options in quantity pickers ("How many?" menus).',
			int_menu_default_to_one: 'Make "Just one" the default option in all quantity pickers ("How many?" menus).',
			do_oneclick_pickup: 'Pick up items off the ground with a single click, when possible.',
			do_stat_count_animations: 'Show "count up" and "count down" animations when your iMG, energy and currants change.',
			do_power_saving_mode: 'Go into power saving mode after a period of inactivity.',
			up_key_is_enter: 'UP arrow and W keys work like the ENTER key to activate an item.'
		}
		
		public function getAnonymous():Object {
			return {
				int_menu_more_quantity_buttons: int_menu_more_quantity_buttons,
				int_menu_default_to_one: int_menu_default_to_one,
				do_oneclick_pickup: do_oneclick_pickup,
				do_stat_count_animations: do_stat_count_animations,
				do_power_saving_mode: do_power_saving_mode,
				up_key_is_enter: up_key_is_enter
			}
		}
		
		public function getDescForPref(pref_name:String):String {
			if (!(pref_name in this)) {
				return 'unknown pref:'+pref_name;
			}
			if (!(pref_name in pref_descriptions)) {
				return 'no description for pref:'+pref_name;
			}
			
			return pref_descriptions[pref_name];
		}
		
		public function updateFromAnonymous(object:Object):void {
			for (var j:String in object) {
				if (j in this) {
					this[j] = object[j];
					CONFIG::debugging {
						Console.info('PREF '+j+' set to '+this[j]);
					}
				} else {
					CONFIG::debugging {
						Console.error('bad pref: '+j);
					}
				}
			}
		}
	}
}