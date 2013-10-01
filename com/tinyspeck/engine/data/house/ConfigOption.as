package com.tinyspeck.engine.data.house
{
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.itemstack.Itemstack;
	import com.tinyspeck.engine.spritesheet.ItemSSManager;
	import com.tinyspeck.engine.spritesheet.SWFData;
	import com.tinyspeck.engine.util.ObjectUtil;
	import com.tinyspeck.engine.util.SortTools;
	import com.tinyspeck.engine.util.StringUtil;

	public class ConfigOption
	{
		public static var ava_option_names_sort:Array;
		public static var ava_option_names:Object;
		public static var ava_raw_options:Object;
		public static var ava_default_options:Object;
		public static var ava_option_names_breaks:Array;
		
		public var id:String;
		public var sort_index:int;
		public var label:String;
		public var choices:Array;
		public var choice_index:int;
		
		public function ConfigOption(id:String):void {
			this.id = id;
		}
		
		public function setChoiceIndex(value:Object):void {
			if (value is String) {
				choice_index = choices.indexOf(value);
			} else {
				var sig:String = ObjectUtil.makeSignatureForHash(value);
				for (var i:int=0;i<choices.length;i++) {
					if (sig == ObjectUtil.makeSignatureForHash(choices[i])) {
						choice_index = i;
						return;
					}
				}
				
			}
		}
		
		public function getCurrentChoiceValue():Object {
			if(choice_index >= 0){
				return choices[choice_index];
			}
			return null;
		}
		
		/**
		 * Applies any labels that have been set, if no label it uses the id 
		 * @param object
		 * @param options
		 */		
		public static function applyLabels(object:Object, options:Vector.<ConfigOption>):void {
			var i:int;
			var total:int = options.length;
			var option:ConfigOption;
			
			//loop through and apply any labels
			for(i; i < total; i++){
				option = options[int(i)];
				option.label = object && option.id in object ? object[option.id] : StringUtil.capitalizeWords(option.id);
			}
		}
		
		/**
		 * Applies any sorts 
		 * @param A
		 * @param options
		 */		
		public static function applySorts(A:Array, options:Vector.<ConfigOption>):void {
			var i:int;
			var total:int = options.length;
			var option:ConfigOption;
			
			//loop through and apply any labels
			for(i; i < total; i++){
				option = options[int(i)];
				option.sort_index = A.indexOf(option.id);
				CONFIG::debugging {
					Console.info(option.id+' '+option.sort_index);
				}
			}
		}
		
		public static function parseMultiple(object:Object, V:Vector.<ConfigOption>=null):Vector.<ConfigOption> {
			V = V || new Vector.<ConfigOption>();
			var option:ConfigOption;
			var k:String;
			var m:String;
			
			for(k in object){
				option = new ConfigOption(k);
				if (object[k] is Array) {
					option.choices = object[k];
				} else {
					option.choices = [];
					for (m in object[k]) {
						// this puts the key as a string as the value
						option.choices.push(m);
						// this would put the object itself as the value
						//option.choices.push(object[k][m]);
					}
				}
				V.push(option);
			}
			
			return V;
		}
		
		public static function populateConfigChoicesForItemstack(itemstack:Itemstack, config_optionsV:Vector.<ConfigOption>, current_config:Object):Boolean {
			const swf_data:SWFData = itemstack && itemstack.swf_url ? ItemSSManager.getSWFDataByUrl(itemstack.swf_url) : null;
			
			config_optionsV.length = 0;
			var option:ConfigOption;
			var excludeA:Array;
			
			if (swf_data && swf_data.mc && swf_data.mc.hasOwnProperty('user_config_exclusions') && swf_data.mc.user_config_exclusions && swf_data.mc.user_config_exclusions is Array) {
				excludeA = swf_data.mc.user_config_exclusions.concat();
			}
			
			// hard code this until we find a better way to do this shit
			if (itemstack.class_tsid == 'furniture_tower_chassis') {
				
				var required_extra_floors_for_deco_side:int = 1;
				
				if (current_config.required_extra_floors_for_deco_side) {
					required_extra_floors_for_deco_side = current_config.required_extra_floors_for_deco_side;
				}
				
				// not enough extra floors? get rid of deco_side
				if (!current_config.extra_floors || int(current_config.extra_floors) < required_extra_floors_for_deco_side) {
					if (!excludeA) excludeA = [];
					excludeA.push('deco_side');
				}
			}
			
			/*
			CONFIG::debugging {
			Console.info(swf_data.mc.user_config_exclusions+' '+excludeA);
			}
			
			CONFIG::debugging {
			Console.dir(current_config);
			}
			*/
			if (swf_data && swf_data.mc && swf_data.mc.hasOwnProperty('config_options') && swf_data.mc.config_options) {
				var swf_options:Object = ObjectUtil.copyOb(swf_data.mc.config_options);
				
				// anything the user should not be able to change?
				if (excludeA && excludeA.length) {
					for (var k:String in swf_options) {
						if (excludeA.indexOf(k) != -1) {
							delete swf_options[k];
						}
					}
				}
				
				config_optionsV = parseMultiple(swf_options, config_optionsV);
			} else {
				CONFIG::debugging {
					Console.warn('??? itemstack: '+itemstack);
				}
				return false;
			}
			
			//get the labels of the config options
			if(swf_data.mc.hasOwnProperty('config_option_names') && swf_data.mc.config_option_names) {
				applyLabels(ObjectUtil.copyOb(swf_data.mc.config_option_names), config_optionsV);
			}
			else {
				//no names?! Ah well, just use the ids then
				applyLabels(null, config_optionsV);
			}
			
			if(swf_data.mc.hasOwnProperty('config_option_names_sort') && swf_data.mc.config_option_names_sort is Array) {
				applySorts(swf_data.mc.config_option_names_sort, config_optionsV);
			}
			
			//order the options by sort_index, label
			SortTools.vectorSortOn(config_optionsV, ['sort_index', 'label'], [Array.NUMERIC, Array.CASEINSENSITIVE]);
			
			current_config = ObjectUtil.copyOb(current_config) || {};
			
			//loop through the options and set the option's current index
			var i:int;
			var total:int = config_optionsV.length;
			
			for(i; i < total; i++){
				option = config_optionsV[int(i)];
				option.setChoiceIndex(current_config[option.id]);
				if(option.choice_index == -1){
					CONFIG::debugging {
						Console.warn('wtf '+option.id+':'+current_config[option.id]+' not in choices:'+option.choices);
					}
					option.choice_index = 0;
				}
			}
			
			return true;
		}
		
		public static function populateConfigChoicesForAva(config_optionsV:Vector.<ConfigOption>, current_config:Object):Boolean {
			
			config_optionsV.length = 0;
			var option:ConfigOption;
			
			
			/*
			CONFIG::debugging {
			Console.info(swf_data.mc.user_config_exclusions+' '+excludeA);
			}
			
			CONFIG::debugging {
			Console.dir(current_config);
			}
			*/
			if (ava_raw_options) {
				var swf_options:Object = ObjectUtil.copyOb(ava_raw_options);
				
				// anything the user should not be able to change?
				config_optionsV = parseMultiple(swf_options, config_optionsV);
			} else {
				CONFIG::debugging {
					Console.warn('??? ava_raw_options: '+ava_raw_options);
				}
				return false;
			}
			
			//get the labels of the config options
			if(ava_option_names) {
				applyLabels(ObjectUtil.copyOb(ava_option_names), config_optionsV);
			}
			else {
				//no names?! Ah well, just use the ids then
				applyLabels(null, config_optionsV);
			}
			
			if(ava_option_names_sort is Array) {
				applySorts(ava_option_names_sort, config_optionsV);
			}
			
			//order the options by sort_index, label
			SortTools.vectorSortOn(config_optionsV, ['sort_index', 'label'], [Array.NUMERIC, Array.CASEINSENSITIVE]);
			
			current_config = ObjectUtil.copyOb(current_config) || {};
			
			//loop through the options and set the option's current index
			var i:int;
			var total:int = config_optionsV.length;
			
			for(i; i < total; i++){
				option = config_optionsV[int(i)];
				option.setChoiceIndex(current_config[option.id]);
				if(option.choice_index == -1){
					CONFIG::debugging {
						Console.warn('wtf '+option.id+':'+current_config[option.id]+' not in choices:'+option.choices);
					}
					option.choice_index = 0;
				}
			}
			
			return true;
		}
	}
}