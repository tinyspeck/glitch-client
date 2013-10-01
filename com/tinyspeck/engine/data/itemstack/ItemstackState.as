package com.tinyspeck.engine.data.itemstack
{
	import com.tinyspeck.debug.BootError;
	import com.tinyspeck.debug.Console;
	import com.tinyspeck.engine.data.AbstractTSDataEntity;
	import com.tinyspeck.engine.model.TSModelLocator;
	import com.tinyspeck.engine.util.ObjectUtil;
	
	public class ItemstackState extends AbstractTSDataEntity {
		public static const TYPE_DEFAULT:String = 'TYPE_DEFAULT';
		public static const TYPE_SCENE_NAME:String = 'TYPE_SCENE_NAME';
		public static const TYPE_ARGS:String = 'TYPE_ARGS';
		public static const TYPE_ANIMATION_NAME:String = 'TYPE_ANIMATION_NAME';
		public static const TYPE_VISIBILITY:String = 'TYPE_VISIBILITY';
		
		private var _raw_s_value:*;
		public function set raw_s_value(v:*):void { _raw_s_value = v; }
		
		public var type:String;
		public var scene_name:String;
		public var animation_name:String;
		public var not_selectable:Boolean;
		public var visibility:Boolean = true;
		public var facing_right:Boolean = true;
		public var itemstack_tsid:String;
		public var config_sig:String;
		public var lifespan_config:LifespanConfig
		
		public var is_config_dirty:Boolean;
		public var is_value_dirty:Boolean;
		public function get is_dirty():Boolean { return is_config_dirty || is_value_dirty || (furn_config && furn_config.is_dirty); }
		
		public function ItemstackState(hashName:String) {
			itemstack_tsid = hashName;
			super(hashName);
		}
		
		public function get config_for_swf():Object {
			if (!furn_config || !furn_config.config) return _config;
			return furn_config.config;
		}
		
		private var _config:Object;
		public function get config():Object { return _config; }
		public function set config(ob:Object):void {
			
			// first let's handle custom config props, and remove them from the ob; they are not meant to be part of the config
			// for this itemstack (the config is the stuff we will send to the swf to set it up when building the spritesheets)
			
			if (ob && ob.furniture) {
				setFurnConfig(ob.furniture);
				delete ob.furniture;
			}
			
			if (ob && 'special_display' in ob && ob.special_display) {
				setSpecialConfigs(ob.special_display);
				delete ob.special_display;
			}
			
			if (ob && 'lifespan' in ob && ob.lifespan) {
				if (lifespan_config) {
					lifespan_config = LifespanConfig.updateFromAnonymous(ob.lifespan, lifespan_config);
				} else {
					lifespan_config = LifespanConfig.fromAnonymous(ob.lifespan, '');
				}
				delete ob.lifespan;
			}
			
			//see if we have anything left after handling the custom config objects
			for (var k:String in ob) {
				// if we're here, there was another value! set _config and return;
				_config = ob;
				config_sig = ObjectUtil.makeSignatureForHash(_config);
				return;
			}
			
			// nothing left, no config;
			_config = null;
			config_sig = null;
		}
		
		private var _furn_config:FurnitureConfig;
		public function get furn_config():FurnitureConfig { return _furn_config; }
		public function setFurnConfig(ob:Object):void {
			var was_furn_config:FurnitureConfig = _furn_config;
			var was_furn_config_sig:String = (_furn_config) ? _furn_config.sig : null;
			
			if (ob is FurnitureConfig) {
				_furn_config = ob as FurnitureConfig;
				
				if (_furn_config != was_furn_config) {
					_furn_config.is_dirty = true;
				}
			} else {
				if (_furn_config) {
					_furn_config = FurnitureConfig.resetAndUpdateFromAnonymous(ob, _furn_config);
				} else {
					_furn_config = FurnitureConfig.fromAnonymous(ob, '');
				}
				//_furn_config = FurnitureConfig.fromAnonymous(ob, '');
				
				
				if (!was_furn_config_sig || was_furn_config_sig != _furn_config.sig) {
					_furn_config.is_dirty = true;
				} else {
					CONFIG::debugging {
						Console.info('all these redunnndant configs!');
					}
				}
				
				_furn_config.temp_sig = ObjectUtil.makeSignatureForHash(ob);
				
			}
		}
		
		private var _special_configV:Vector.<SpecialConfig>;
		public function get special_configV():Vector.<SpecialConfig> { return _special_configV; }
		public function get is_any_special_config_dirty():Boolean {
			if (!_special_configV) return false;
			if (!_special_configV.length) return false;
			for each (var sconfig:SpecialConfig in _special_configV) {
				if (sconfig.is_dirty) return true;
			}
			return false;
		}
		private function setSpecialConfigs(special_display:Array):void {
			var i:int;
			var sd_ob:Object;
			
			// clean out any that are not for this player
			if (special_display.length) {
				var clean_special_display:Array = [];
				for (i=0;i<special_display.length;i++) {
					sd_ob = special_display[i];
					if (!sd_ob || (sd_ob.for_pc_tsid && sd_ob.for_pc_tsid != TSModelLocator.instance.worldModel.pc.tsid)) {
						continue;
					}
					clean_special_display.push(sd_ob);
				}
				special_display = clean_special_display
			}
			
			if (special_display.length) {
				if (!_special_configV) _special_configV = new Vector.<SpecialConfig>();
				
				for (i=0;i<special_display.length;i++) {
					var sd:SpecialConfig;
					sd_ob = special_display[i];
					
					// make sure our sigs do not count any members that should not affect rendering with SpecialConfig.sig_exclusions
					var sd_ob_sig:String = ObjectUtil.makeSignatureForHash(sd_ob, SpecialConfig.sig_exclusions);
					var was_sd:SpecialConfig = (i<_special_configV.length) ? _special_configV[i]: null;
					var was_sd_sig:String = (was_sd) ? was_sd.sig : null;
					var was_dirty:Boolean = (was_sd) ? was_sd.is_dirty : true;
					
					if (was_sd) {
						sd = SpecialConfig.resetAndUpdateFromAnonymous(sd_ob, was_sd);
					} else {
						sd = SpecialConfig.fromAnonymous(sd_ob, 'sd_'+i);
					}
					
					sd.sig = sd_ob_sig;
					
					// put in vector
					_special_configV[i] = sd;
					
					if (was_dirty || !was_sd || was_sd_sig != sd_ob_sig) {
						sd.is_dirty = true;
					}
				}
				
				// we expect the length of special_display to remain consistent for the life of the stack.
				// that is how we track them to remove them
				if (_special_configV.length != special_display.length) {
					CONFIG::debugging {
						BootError.handleError('WTF, the special_display Array of '+itemstack_tsid+' has changed in length!', new Error('special_display Array changed'), ['special_display'], false);
					}
					
					// make sure we stop erroring on this
					_special_configV.length = special_display.length;
				}
				
			}
		}
		// we will call this from views, because these must be dirty for those to work correctly on first render
		public function markAllSpecialConfigsDirty():void {
			if (_special_configV) {
				for (var i:int;i<_special_configV.length;i++) {
					_special_configV[i].is_dirty = true;
				}
			}
		}
		// we will call this from views, because these must be dirty for those to work correctly on first render
		public function getSpecialConfigByType(type:String):SpecialConfig {
			if (_special_configV) {
				for (var i:int;i<_special_configV.length;i++) {
					if (_special_configV[i].type == type) return _special_configV[i];
				}
			}
			
			return null;
		}
		
		private function getDefaultStrForStack():String {
			var itemstack:Itemstack = TSModelLocator.instance.worldModel.getItemstackByTsid(itemstack_tsid);
			if (!itemstack || !itemstack_tsid || !TSModelLocator.instance.worldModel.pc || TSModelLocator.instance.worldModel.pc.itemstack_tsid_list[itemstack_tsid]) {
				return 'iconic';
			} else {
				return String(itemstack.count);
			}
		}
		
		public function get state_str():String {
			if (type == TYPE_ARGS) return '';
			return value;
		}
		
		public function get state_args():Object {
			if (type == TYPE_ARGS) return value;
			return null;
		}
		
		public function get value():* {
			switch (type) {
				case TYPE_DEFAULT:
					return getDefaultStrForStack();
					break;
				
				case TYPE_ARGS:
					return _raw_s_value;
					break;
				
				case TYPE_SCENE_NAME:
					return scene_name;
					break;
				
				case TYPE_ANIMATION_NAME:
					return animation_name;
					break;
				
				case TYPE_VISIBILITY:
					return scene_name; // this optimisitcaaly works for quoins
					break;
				
				
				default:
					CONFIG::debugging {
					Console.error('unknown type '+type);
				}
					return null;
			}
		}
	}
}